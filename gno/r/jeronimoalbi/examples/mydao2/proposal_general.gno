package mydao2

import (
	"time"

	"gno.land/p/nt/commondao"
)

type generalDefinition struct {
	title, description string
}

func (p generalDefinition) Title() string             { return p.title }
func (p generalDefinition) Body() string              { return p.description }
func (generalDefinition) VotingPeriod() time.Duration { return time.Hour }

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
