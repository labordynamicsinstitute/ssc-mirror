*! 3.0.0 Ariel Linden 12Jan2026 // replaced prais with praisk
*! 2.0.0 Ariel Linden 12Jan2026 // added prais option; added performance measures
*! 1.0.0 Ariel Linden 11Jun2025

program power_cmd_single_itsa_init, sclass
        version 11

		syntax, [ level praisk perf Rho2(string) Rho3(string) * ]
		
		sreturn clear

		*--------------------------------------------------------------
		* Build the dynamic parts of colnames, collabels, and numopts
		* based on which optional rhos were specified
		*--------------------------------------------------------------
		local rho_cols  ""
		local rho_labs  ""
		local rho_opts  ""
		if "`rho2'" != "" {
			local rho_cols "`rho_cols' rho2"
			local rho_labs `"`rho_labs' "Rho2""'
			local rho_opts "`rho_opts' Rho2"
		}
		if "`rho3'" != "" {
			local rho_cols "`rho_cols' rho3"
			local rho_labs `"`rho_labs' "Rho3""'
			local rho_opts "`rho_opts' Rho3"
		}

		*--------------------------------------------------------------
		* Assemble full colnames, collabels, numopts strings
		*--------------------------------------------------------------
		local base_cols "trperiod intercept pretrend posttrend step rho1`rho_cols' reps"
		local base_labs `""Trperiod" "Intercept" "Pretrend" "Posttrend" "Step" "Rho1"`rho_labs' "Reps""'
		local base_opts "alpha n TRPeriod INTercept PREtrend STep POSTtrend Rho1`rho_opts' sd reps"

		if "`perf'" == "" {
			sreturn local pss_colnames "`base_cols'"
			sreturn local pss_collabels `"`base_labs'"'
			sreturn local pss_numopts  "`base_opts'"
		}
		else {
			sreturn local pss_colnames "`base_cols' bias rmse coverage se"
			sreturn local pss_collabels `"`base_labs' "bias" "rmse" "coverage" "se" "'
			sreturn local pss_numopts  "`base_opts'"
		}
		
		if "`praisk'" == "" {
			sreturn local pss_title " for a single-group interrupted time series analysis: GLM with Newey-West std. errs."
		}		
		else {		
			sreturn local pss_title " for a single-group interrupted time series analysis: Prais-Winsten regression"
		}		
		
		if "`level'" == "" {
			sreturn local pss_subtitle "(Difference in pre- and post-trends)"
		}
		else {
			sreturn local pss_subtitle "(change in level vs counterfactual)"			
		}

end
