*! 1.0.0 Ariel Linden 27Sep2022

// initializer
program power_cmd_tworoc_init, sclass 
	version 11.0

	syntax, [ corr(real 0) * ]  // asterisk captures all other options
	sreturn clear
	sreturn local pss_argnames "auc0 auc1 auc2"
	sreturn local pss_hyp_lhs "auc1"
	sreturn local pss_hyp_rhs "auc2"
	sreturn local pss_numopts "ratio corr n1 n0"
	sreturn local pss_colnames "N1 N0 ratio auc0 auc1 auc2 delta corr"
	sreturn local pss_samples "twosample"
	if (`corr' == 0) {
		sreturn local pss_title " for an independent two-sample ROC analysis"
	}
	else {
		sreturn local pss_title " for a paired two-sample ROC analysis"
	}
end
