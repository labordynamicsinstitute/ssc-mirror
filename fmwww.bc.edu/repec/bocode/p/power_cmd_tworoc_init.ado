*! 1.0.0 Ariel Linden 27Sep2022

// initializer
program power_cmd_tworoc_init, sclass
	version 11.0
	sreturn clear
	sreturn local pss_argnames "auc0 auc1 auc2"
	sreturn local pss_hyp_lhs "auc1"
	sreturn local pss_hyp_rhs "auc2"
	sreturn local pss_numopts "ratio corr n1 n0"
	sreturn local pss_colnames "N1 N0 ratio auc0 auc1 auc2 delta corr"
	sreturn local pss_samples "twosample"
end
