package mydao2

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
func (modifyMembersDefinition) VotingPeriod() time.Duration { return time.Hour }

func (p modifyMembersDefinition) Body() string {
	var b strings.Builder

	if len(p.newMembers) > 0 {
		b.WriteString("## New Members\n")
	}

	for _, m := range p.newMembers {
		b.WriteString("- " + m.String() + "\n")
	}

	if len(p.removeMembers) > 0 {
		b.WriteString("## Remove Members\n")
	}

	for _, m := range p.removeMembers {
		b.WriteString("- " + m.String() + "\n")
	}

	return b.String()
}

func (modifyMembersDefinition) Tally(ctx commondao.VotingContext) (bool, error) {
	if !commondao.IsQuorumReached(commondao.QuorumTwoThirds, ctx.VotingRecord, ctx.Members) {
		return false, commondao.ErrNoQuorum
	}

	c, success := commondao.SelectChoiceBySuperMajority(ctx.VotingRecord, ctx.Members.Size())
	if success {
		return c == commondao.ChoiceYes, nil
	}
	return false, nil
}

func (p modifyMembersDefinition) Execute(realm) error {
	for _, m := range p.newMembers {
		if !myDAO.Members().Add(m) {
			return errors.New("address is already a member: " + m.String())
		}
	}

	for _, m := range p.removeMembers {
		if !myDAO.Members().Remove(m) {
			return errors.New("address not found: " + m.String())
		}
	}
	return nil
}
