*! 1.0.0 Ariel Linden 20Sep2023

// initializer
program power_cmd_concord_init, sclass 
	version 11.0

	syntax, [ corr(real 0) * ]  // asterisk captures all other options
	sreturn clear
	sreturn local pss_argnames "concord0 concord1"
	sreturn local pss_hyp_lhs "concord1"
	sreturn local pss_hyp_rhs "concord0"
	sreturn local pss_numopts "n alpha power"
	sreturn local pss_colnames "concord0 concord1 delta"
	sreturn local pss_samples "twosample"
	sreturn local pss_title " for Lin's concordance statistic"

end
