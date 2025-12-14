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

func renderProposal(id uint64) string {
	var (
		output strings.Builder
		p      = mustGetProposal(id)
	)

	// Use the proposal title and ID as title
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
