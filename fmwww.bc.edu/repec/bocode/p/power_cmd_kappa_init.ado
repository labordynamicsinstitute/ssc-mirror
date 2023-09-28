*! 1.0.0 Ariel Linden 20Sep2023

// initializer
program power_cmd_kappa_init, sclass 
	version 11.0

	syntax, [ corr(real 0) * ]  // asterisk captures all other options
	sreturn clear
	sreturn local pss_argnames "kappa0 kappa1"
	sreturn local pss_hyp_lhs "kappa0"
	sreturn local pss_hyp_rhs "kappa1"
	sreturn local pss_numopts "n alpha power"
	sreturn local pss_colnames "kappa0 kappa1 delta"
	sreturn local pss_samples "twosample"
	sreturn local pss_title " for a two-rater kappa statistic"

end
