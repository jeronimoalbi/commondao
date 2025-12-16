## Overview

This second part of the "Write a DAO Smart Contract" tutorial will explore how to add and remove
members by using a different type of proposal. It continues where the first part left off.

## What You'll Learn

- What an executable proposal is
- How to create an executable proposal that updates DAO members
- How to write a minimal public function to execute proposals

## What You'll Need

- To have read the [first part] of this tutorial
- Understanding of [Gno language](https://docs.gno.land/)
- Knowledge on how to deploy realms and packages using [Gno Playground] or [gnokey]
- Knowledge on how to interact with realms using [Gno Connect] or [gnokey]

## Executable Proposals

It's useful to be able to change the members of the DAO by adding new members or removing existing
ones. One way to support this is though the implementation of a new type of proposal that when
approved would make the necessary changes to the DAO. This type of proposal is called executable.

The steps needed to change DAO members using this new proposal type start by creating a new
proposal to modify the DAO members, then voting on it and waiting until the voting deadline is met.
Once that happens, the proposal could be executed at any time to effectively modify the members.

The [gno.land/p/nt/commondao] package allows defining executable proposal types by implementing
the following interface:

```go
type Executable interface {
    // Execute executes the proposal
    Execute(realm) error
}
```

### Executable Proposal Definition

Proposal definitions that implement the `Execute()` method are able to modify the state after the
proposal is approved and executed when the voting deadline is met.

Let's define a new proposal strategy that adds or removes DAO members after it's approval by creating
a `proposal_members.gno` file:

```go
package mydao

import (
    "errors"
    "strings"
    "time"

    "gno.land/p/nt/commondao"
)

type modifyMembersDefinition struct {
    newMembers, removeMembers []address
}

func (p modifyMembersDefinition) Title() string             { return "Modify Members" }
func (modifyMembersDefinition) VotingPeriod() time.Duration { return time.Hour * 24 * 7 }

func (p modifyMembersDefinition) Body() string {
    var b strings.Builder

    // When there are new members add a section title and list the members to add
    if len(p.newMembers) > 0 {
        b.WriteString("## New Members\n")
    }

    for _, m := range p.newMembers {
        b.WriteString("- " + m.String() + "\n")
    }

    // When there are members to remove add a section title and list the members to remove
    if len(p.removeMembers) > 0 {
        b.WriteString("## Remove Members\n")
    }

    for _, m := range p.removeMembers {
        b.WriteString("- " + m.String() + "\n")
    }

    // Return the Markdown that renders the body of the proposal
    return b.String()
}

func (modifyMembersDefinition) Tally(ctx commondao.VotingContext) (bool, error) {
    // Check if a quorum of 2/3s has been met
    if !commondao.IsQuorumReached(commondao.QuorumTwoThirds, ctx.VotingRecord, ctx.Members) {
        return false, commondao.ErrNoQuorum
    }

    // Tally votes by a super majority of 2/3s
    c, success := commondao.SelectChoiceBySuperMajority(ctx.VotingRecord, ctx.Members.Size())
    if success {
        return c == commondao.ChoiceYes, nil
    }
    return false, nil
}

func (p modifyMembersDefinition) Execute(realm) error {
    // Add each one of the new members to the DAO
    for _, m := range p.newMembers {
        if !myDAO.Members().Add(m) {
            return errors.New("address is already a member: " + m.String())
        }
    }

    // Remove each one of the members to remove from the DAO
    for _, m := range p.removeMembers {
        if !myDAO.Members().Remove(m) {
            return errors.New("address not found: " + m.String())
        }
    }
    return nil
}
```

> It's important to mention that you might want to change the voting period to a smaller time frame
> if you intend to try or demo the proposal.

Pay special attention to the `Execute()` method, which will be called after the proposal passes.
The other proposal definition methods were already explained in the [first part] of the tutorial.

## Public Realm Functions

The next step is to define a new public realm function to allow the creation of member modification
proposals and a second public function to be able to execute proposals once the voting deadline
is met.

### Create Modify DAO Member Proposal

Firts, a helper function to parse one or more addresses from a string into actual addresses is
required to be able to call the function using simple data types, for example when calling it
using [Gno Connect].

To do so define a `mustParseStringToAddresses()` function at the end of the `public.gno` file:

```go
// mustParseStringToAddresses parses a mulitiline text of addresses into a list.
func mustParseStringToAddresses(s string) []address {
    if s == "" {
        return nil
    }

    var members []address
    for _, raw := range strings.Split(s, "\n") {
        // Remove empty leading and trailing spaces
        raw = strings.TrimSpace(raw)
        if raw == "" {
	    continue
        }

        // Cast the string into an address and make sure address has the right format
        addr := address(raw)
        if !addr.IsValid() {
	    panic("invalid address: " + addr.String())
        }

	// Add current address to the list of addresses
        members = append(members, addr)
    }
    return members
}
```

To allow DAO members to create new _modify members_ proposals, define a
`CreateModifyMembersProposal()` function at the end of the `public.gno` file:

````go
// CreateModifyMembersProposal creates a proposal to modify DAO members.
//
// Arguments:
// - newMembers: List of member addresses to add to the DAO
// - removeMembers: List of member addresses to remove from the DAO
//
// A list of members must be newline separated list of addresses,
// where each line must contain an address, for example:
// ```
// g187982000zsc493znqt828s90cmp6hcp2erhu6m
// g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5
// ```
func CreateModifyMembersProposal(_ realm, newMembers, removeMembers string) uint64 {
    // Check that the original caller is a member of the DAO
    caller := runtime.OriginCaller()
    assertIsMember(caller)

    // Make sure that at least a member would be added or removed
    membersAdd := mustParseStringToAddresses(newMembers)
    membersRemove := mustParseStringToAddresses(removeMembers)
    if len(membersAdd) == 0 && len(membersAdd) == 0 {
        panic("members are required")
    }

    // Create a new proposal that uses the general definition
    p, err := myDAO.Propose(caller, modifyMembersDefinition{
        membersAdd,
        membersRemove,
    })
    if err != nil {
        panic(err)
    }

    return uint64(p.ID())
}
````

This function receives one or more member addresses that should be added or removed from the DAO
after the proposal is approved, when proposal is executed.

### Create a Public Realm Function to Execute Proposals

To allow executing proposals define an `Execute()` function at the end of the `public.gno` file:

```go
// Execute executes active proposals.
func Execute(_ realm, proposalID uint64) string {
    caller := runtime.OriginCaller()
    assertIsMember(caller)

    p := mustGetProposal(proposalID)
    err := myDAO.Execute(p.ID())
    if err != nil {
        panic(err)
    }

    return "Proposal executed successfully"
}
```

The `Execute()` function should be called for any type of proposals, executable or non executable,
to update the proposal state to reflect the outcome of the votes once the voting deadline is met.

## What's Next

Now you can add or remove DAO members by following these steps:

- Deploy your DAO realm to **gno.land**
- Create a new member modification proposal by calling `CreateModifyMembersProposal()`
- Vote _YES_ on the new proposal using the current DAO member accounts
- Once the voting deadline is met execute the proposal by calling `Execute()`
- Check the list of DAO members in your DAO **gno.land** realm view

From here, you can explore extending the tutorial examples with different use cases. For example,
you could improve validation. The [gno.land/p/nt/commondao] package has support for proposal
validation by implementing the `Validator` interface in the proposal definitions.

Other things to explore could be using different tallying methods to count the votes, or even
creating a tree based DAO, which is also supported by [gno.land/p/nt/commondao].

[first part]: https://gno.land/r/jeronimoalbi/blog:posts/write-a-dao-smart-contract-part-1
[gno.land/p/nt/commondao]: https://gno.land/p/nt/commondao/
[Gno Connect]: https://gno.studio/connect/
[Gno Playground]: https://play.gno.land/
[gnokey]: https://docs.gno.land/users/interact-with-gnokey/
