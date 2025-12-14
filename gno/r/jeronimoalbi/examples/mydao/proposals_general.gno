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
func (generalDefinition) VotingPeriod() time.Duration { return time.Hour }

func (generalDefinition) Tally(ctx commondao.VotingContext) (bool, error) {
	if !commondao.IsQuorumReached(commondao.QuorumTwoThirds, ctx.VotingRecord, ctx.Members) {
		return false, commondao.ErrNoQuorum
	}

	c, success := commondao.SelectChoiceBySuperMajority(ctx.VotingRecord, ctx.Members.Size())
	if success {
		return c == commondao.ChoiceYes, nil
	}
	return false, nil
}
