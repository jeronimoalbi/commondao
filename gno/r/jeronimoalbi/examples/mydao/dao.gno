package mydao

import "gno.land/p/nt/commondao"

var myDAO = commondao.New(
	commondao.WithSlug("mydao"),
	commondao.WithName("MyDAO"),
	commondao.WithMember("g1hy6zry03hg5d8le9s2w4fxme6236hkgd928dun"),
	commondao.WithMember("g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"),
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
