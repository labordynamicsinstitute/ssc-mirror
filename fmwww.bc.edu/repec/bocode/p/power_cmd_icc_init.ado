*! 1.0.0 Ariel Linden 02July2023

// initializer
program power_cmd_icc_init, sclass
	version 11.0
	sreturn clear
	sreturn local pss_argnames "icc0 icc1"
	sreturn local pss_hyp_lhs "icc0"
	sreturn local pss_hyp_rhs "icc1"
	sreturn local pss_numopts "icc0 icc1 n nr power"
	sreturn local pss_title " for one-way random-effects intraclass correlation"
	sreturn local pss_colnames "alpha power nr icc0 icc1 delta"
	sreturn local pss_samples "twosample"
end
