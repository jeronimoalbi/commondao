package mydao2

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

// assertTitleIsNotEmpty asserts that a title string is not empty.
func assertTitleIsNotEmpty(title string) {
	if strings.TrimSpace(title) == "" {
		panic("title should not be empty")
	}
}

// assertDescriptionIsNotEmpty asserts that a description string is not empty.
func assertDescriptionIsNotEmpty(desc string) {
	if strings.TrimSpace(desc) == "" {
		panic("description should not be empty")
	}
}

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
