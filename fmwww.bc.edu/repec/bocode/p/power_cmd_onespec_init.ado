*! 1.0.0 Ariel Linden 28Jul2022

// initializer
program power_cmd_onespec_init, sclass
	version 11.0
	sreturn clear
	sreturn local pss_argnames "spec0 spec1"
	sreturn local pss_hyp_lhs "spec0"
	sreturn local pss_hyp_rhs "spec1"
	sreturn local pss_numopts "prev n1 n0"
	sreturn local pss_colnames "N1 N0 prev spec0 spec1 delta"
	sreturn local pss_samples "twosample"
end