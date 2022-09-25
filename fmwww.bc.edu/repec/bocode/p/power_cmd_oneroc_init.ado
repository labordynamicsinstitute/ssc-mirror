*! 1.0.0 Ariel Linden 21Jun2022

// initializer
program power_cmd_oneroc_init, sclass
	version 11.0
	sreturn clear
	sreturn local pss_argnames "auc0 auc1"
	sreturn local pss_hyp_lhs "auc0"
	sreturn local pss_hyp_rhs "auc1"
	sreturn local pss_numopts "kappa n1 n0"
	sreturn local pss_colnames "N1 N0 kappa auc0 auc1 delta"
	sreturn local pss_samples "twosample"
end
