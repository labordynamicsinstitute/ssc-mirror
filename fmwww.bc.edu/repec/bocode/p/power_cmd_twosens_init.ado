*! 1.0.0 Ariel Linden 28Jul2022

// initializer
program power_cmd_twosens_init, sclass
	version 11.0
	sreturn clear
	sreturn local pss_argnames "sens1 sens2"
	sreturn local pss_hyp_lhs "sens1"
	sreturn local pss_hyp_rhs "sens2"
	sreturn local pss_numopts "prev n1 n0 fraction1 fraction2"
	sreturn local pss_colnames "N1 N0 prev sens1 sens2 delta"
	sreturn local pss_samples "twosample"
end