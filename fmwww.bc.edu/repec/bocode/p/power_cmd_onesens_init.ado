*! 1.0.0 Ariel Linden 28Jul2022

// initializer
program power_cmd_onesens_init, sclass
	version 11.0
	sreturn clear
	sreturn local pss_argnames "sens0 sens1"
	sreturn local pss_hyp_lhs "sens0"
	sreturn local pss_hyp_rhs "sens1"
	sreturn local pss_numopts "prev n1 n0"
	sreturn local pss_colnames "N1 N0 prev sens0 sens1 delta"
	sreturn local pss_samples "twosample"
end