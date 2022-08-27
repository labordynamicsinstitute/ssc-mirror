*! 1.0.0 Ariel Linden 05Aug2022

// initializer
program power_cmd_pairspec_init, sclass
	version 11.0
	sreturn clear
	sreturn local pss_argnames "spec1 spec2"
	sreturn local pss_hyp_lhs "spec1"
	sreturn local pss_hyp_rhs "spec2"
	sreturn local pss_numopts "prev n1 n0"
	sreturn local pss_colnames "N1 N0 prev spec1 spec2 delta"
	sreturn local pss_samples "twosample"
end