## Overview

This two parts tutorial explores one way to create a non-token based DAO that allows the creation
of general proposals, also known as text proposals, where the initial set of DAO members are
defined within the realm source code. The second part of this tutorial will explore how to add and
remove members by using a different type of proposal.

Tutorial uses the pure [gno.land/p/nt/commondao] package to define the DAO and the different types
or proposals. This package already define for us the types and features needed to create single or
tree based DAOs.

The final DAO implementation aims to be as simple as possible to give you a example or starting
point to help you build your own DAO.

While going though the tutorial try to find the places that you could improve or where you could
extend the DAO functionality with features that would be useful for your use case.

## What You'll Learn

- How to create a simple DAO
- How to create a general proposal
- How to write minimal public functions to create general proposals and vote

## What You'll Need

- Understanding of [Gno language](https://docs.gno.land/)
- Access and familiarity with [Gno Playground]
- [Adena wallet](https://www.adena.app/) installed in your browser
- **Three accounts** created in Adena wallet
- Knowledge on how to deploy realms and packages using [Gno Playground] or [gnokey]
- Knowledge on how to interact with realms using [Gno Connect] or [gnokey]

## The DAO

Lets start by creating the DAO and its members. The number of DAO members is not fixed, one could
use any number of initial members depending on the implementation but for the tutorial we must add
three initial members to be able to tally votes on proposals by absolute majority, passing proposals
where 51% or more members vote "yes".

To create the DAO open [Gno Playground] and create a new `dao.gno` file:

```go
package mydao

import "gno.land/p/nt/commondao"

var myDAO = commondao.New(
    commondao.WithSlug("mydao"),
    commondao.WithName("MyDAO"),
    // TODO: Replace these three addresses with you account addresses
    commondao.WithMember("g1lyzcpa7duh69lk04nahxup484xrz4k6k2nqdun"),
    commondao.WithMember("g125t352u4pmdrr57emc4pe04y40sknr5ztng5mt"),
    commondao.WithMember("g1zzc479zj8taxd5e4g5mydg4rkpmujg7uflrj8p"),
)

// mustGetProposal returns a proposal or panics if it doesn't exist
func mustGetProposal(id uint64) *commondao.Proposal {
    // Try to get it from the list of active proposals
    p := myDAO.ActiveProposals().Get(id)
    if p == nil {
        panic("proposal not found")
    }

    return p
}

// assertIsMember asserts that an address belongs to a DAO member
func assertIsMember(addr address) {
    if !myDAO.Members().Has(addr) {
        panic("caller is not a DAO member")
    }
}
```

> Gno Playground always creates an example `package.gno` file. This file **must** be deleted
> after creating the `dao.gno` file.

> Also it's recommended that you save your code using Gno Playground's save as draft feature when
> files are created or modified to avoid loosing your changes.

The DAO is created with `mydao` as identifier and "MyDAO" as name.

You should change the member addresses in the example Gno code by the three initial account
addresses that you defined in your Adena wallet, otherwise you won't be able to create proposals in
your DAO and vote on them.

## Views

Gno.land realms optionally support rendering views by defining a public realm function called
"Render". Using this feature we can render any number of different views. For the tutorial we
are going to render two views, one to display DAO information and another to display information
for specific proposals.

The `Render(path string) string` function receives a single argument called `path` which is a
string containing a path that we will use to render Markdown for the DAO or a proposal.

By default when there is no path we will render the DAO, otherwise we will expect the path to be a
number which will be used as proposal ID.

Define the `Render()` function by creating a `render.gno` file:

```go
package mydao

import (
    "strconv"
    "strings"

    "gno.land/p/nt/commondao"
)

// Render returns the Markdown for the corresponding view path.
func Render(path string) string {
    // When the path is empty render the DAO view
    if path == "" {
        return renderDAO()
    }

    // Otherwise the path must contain a number with a proposal ID
    proposalID, err := strconv.ParseUint(path, 10, 64)
    if err != nil {
        panic("invalid proposal ID")
    }

    return renderProposal(proposalID)
}
```

Two private render function are also defined to simplify the `Render()` function and make it easier
to read. Each one of these two functions will focus either on the DAO view or the proposal view.

### DAO View

As mentioned before, this is the function that is called by default when visiting your realm in the
[gno.land] website.

For example if yout DAO realm is deployed under `gno.land/r/jeronimoalbi/examples/mydao` path,
calling `https://gno.land/r/jeronimoalbi/examples/mydao` would render the DAO view.

To implement the DAO view add the `renderDAO()` function at the end of the `render.gno` file:

```go
func renderDAO() string {
    var output strings.Builder

    // Use the DAO name as title
    output.WriteString("# " + myDAO.Name() + "\n")

    // Add the list of DAO member addresses
    output.WriteString("## Members\n")
    myDAO.Members().IterateByOffset(0, myDAO.Members().Size(), func(member address) bool {
        output.WriteString("- " + member.String() + "\n")
        return false
    })

    return output.String()
}
```

This and the `renderProposal()` functions use the `strings` package from the Gno standard library to
generate the required Markdown for each of the views. Using the `strings.Builder` type we can write
strings multiple times and get the concatenation as output by calling the `String()` method on it.

### Proposal View

Rendering this view requires a render path to be specified when visiting your realm in the
[gno.land] website.

For example if your DAO realm is deployed under `gno.land/r/jeronimoalbi/examples/mydao` path,
calling `https://gno.land/r/jeronimoalbi/examples/mydao:1` would render the view for the proposal
with ID 1.

> Notice that the render path is written after the colon ":" and for this tutorial it is expected to
> be a number which is used to find a proposal by ID.

To implement the proposal view add the `renderProposal()` function at the end of the `render.gno` file:

```go
func renderProposal(id uint64) string {
    var (
        output strings.Builder
        p      = mustGetProposal(id)
    )

    // Use proposal's title and ID as title
    output.WriteString("# Proposal #" + strconv.FormatUint(p.ID(), 10) + ": " + p.Definition().Title() + "\n")

    // Add important proposal values
    output.WriteString("- Created: " + p.CreatedAt().UTC().Format("2006-01-02 15:04 MST") + "\n")
    output.WriteString("- Proposer: " + p.Creator().String() + "\n")
    output.WriteString("- Status: " + string(p.Status()) + "\n")
    output.WriteString("\n" + p.Definition().Body() + "\n")

    // Add the number of votes for each one of the voted choices
    output.WriteString("\n## Votes\n")
    record := p.VotingRecord()
    if record.Size() == 0 {
        output.WriteString("Proposal has no votes\n")
    } else {
        record.IterateVotesCount(func(c commondao.VoteChoice, voteCount int) bool {
            output.WriteString("- " + string(c) + ": " + strconv.Itoa(voteCount) + "\n")
            return false
        })
    }

    return output.String()
}
```

This function is a bit more complex than the DAO one but it follows the same idea, it generates
Markdown containing the most important and minimal imformation for a proposal.

## General Proposal Definition

The [gno.land/p/nt/commondao] package allows the definition of different proposal types though the
implementation of proposal definitions.

The following is the minimal interface that has to be implemented to create a new proposal type:

```go
type ProposalDefinition interface {
    // Title returns the proposal title.
    Title() string

    // Body returns proposal's body.
    // It usually contains description or values that are specific to the proposal,
    // like a description of the proposal's motivation or the list of values that
    // would be applied when the proposal is approved.
    Body() string

    // VotingPeriod returns the period where votes are allowed after proposal creation.
    // It is used to calculate the voting deadline from the proposal's creationd date.
    VotingPeriod() time.Duration

    // Tally counts the number of votes and verifies if proposal passes.
    // It receives a voting context containing a readonly record with the votes
    // that has been submitted for the proposal and also the list of DAO members.
    Tally(VotingContext) (passes bool, _ error)
}
```

The `VotingContext` type contains the voting record where submitted votes are stored and the
list of DAO members. The voting context must be used to tally the votes, but it can also be
used to check quorum for example.

To define a general proposal definition create a `proposal_general.gno` file:

```go
package mydao

import (
    "time"

    "gno.land/p/nt/commondao"
)

type generalDefinition struct {
    title, description string
}

func (p generalDefinition) Title() string             { return p.title }
func (p generalDefinition) Body() string              { return p.description }
func (generalDefinition) VotingPeriod() time.Duration { return time.Hour * 24 * 4 }

func (generalDefinition) Tally(ctx commondao.VotingContext) (bool, error) {
    // Check if a quorum of 50% has been met
    if !commondao.IsQuorumReached(commondao.QuorumHalf, ctx.VotingRecord, ctx.Members) {
        return false, commondao.ErrNoQuorum
    }

    // Tally votes by absolute majority, which requires 51% votes
    c, success := commondao.SelectChoiceByAbsoluteMajority(ctx.VotingRecord, ctx.Members.Size())
    if success {
        return c == commondao.ChoiceYes, nil
    }
    return false, nil
}
```

> It's important to mention that you might want to change the voting period to a smaller time frame
> if you intend to try or demo a general proposal.

Pay special attention to the `Tally()` method which is the one used by the proposals to count the
votes and decide on a winner choice. Votes can be counted using different rules. For the general
proposal votes are counted by absolute majority which includes voting abstentions when calculating
the required percentage for a voting choice to win.

> Here you could implement a different way for tallying votes.

## Public Realm Functions

Until now the only public realm function that was defined is the `Render()`, so the next step is to
define the rest of the public function that the DAO realm must expose so users can create general
proposal and vote on them.

### Create General Proposal

To allow DAO members to create new general proposals define a `CreateGeneralProposal()` function by
creating a `public.gno` file:

```go
package mydao

import (
    "chain/runtime"
    "strings"

    "gno.land/p/nt/commondao"
)

// CreateGeneralProposal creates a general proposal.
//
// Arguments:
// - title: A title for the proposal
// - description: A description for the proposal
func CreateGeneralProposal(_ realm, title, description string) uint64 {
    // Proposal description and title are required
    assertTitleIsNotEmpty(title)
    assertDescriptionIsNotEmpty(description)

    // Check that the original caller is a member of the DAO
    caller := runtime.OriginCaller()
    assertIsMember(caller)

    // Create a new proposal that uses the general definition
    p, err := myDAO.Propose(caller, generalDefinition{
        title,
        description,
    })
    if err != nil {
        panic(err)
    }

    return uint64(p.ID())
}
```

### Vote

To allow DAO members to vote on any type of proposal define a `Vote()` function at the end of the
`public.gno` file:

```go
// Vote allows voting on proposals.
//
// Arguments:
// - proposalID: ID of the proposal where the vote must be submitted
// - vote: A string with choice to vote
func Vote(_ realm, proposalID uint64, vote string) string {
    // Check that the original caller is a member of the DAO
    caller := runtime.OriginCaller()
    assertIsMember(caller)
    
    p := mustGetProposal(proposalID)
    choice := commondao.VoteChoice(vote)
    err := myDAO.Vote(caller, p.ID(), choice, "")
    if err != nil {
        // When the voted choice is invalid use a custom error message to display valid choices
        if err == commondao.ErrInvalidVoteChoice {
            var choices []string
            for _, c := range p.VoteChoices() {
                choices = append(choices, string(c))
            }

            panic("invalid vote choice, valid choices: " + strings.Join(choices, ", "))
        }

        panic(err)
    }

    return "Vote submitted sucessfully"
}
```

## What's Next

Now you are ready to continue with the part 2 of the tutorial to learn how to define a new type of
proposal to add and remove DAO members.

[gno.land]: https://gno.land
[gno.land/p/nt/commondao]: https://gno.land/p/nt/commondao/
[Gno Playground]: https://play.gno.land/
[Gno Connect]: https://gno.studio/connect/
[gnokey]: https://docs.gno.land/users/interact-with-gnokey/
