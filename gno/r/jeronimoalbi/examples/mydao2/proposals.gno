package mydao2

import "gno.land/p/nt/commondao"

// proposals stores all DAO proposals
var proposals []*commondao.Proposal

// mustGetProposal returns a proposal or panics if it doesn't exist
func mustGetProposal(id uint64) *commondao.Proposal {
	for _, p := range proposals {
		if p.ID() == id {
			return p
		}
	}

	panic("proposal not found")
}
