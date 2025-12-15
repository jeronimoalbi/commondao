package mydao

import "gno.land/p/nt/commondao"

var myDAO = commondao.New(
	commondao.WithSlug("mydao"),
	commondao.WithName("MyDAO"),
	commondao.WithMember("g1lyzcpa7duh69lk04nahxup484xrz4k6k2nqdun"),
	commondao.WithMember("g125t352u4pmdrr57emc4pe04y40sknr5ztng5mt"),
	commondao.WithMember("g1zzc479zj8taxd5e4g5mydg4rkpmujg7uflrj8p"),
)

// mustGetProposal returns a proposal or panics if it doesn't exist
func mustGetProposal(id uint64) *commondao.Proposal {
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
