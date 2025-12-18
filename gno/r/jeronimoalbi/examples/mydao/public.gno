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
