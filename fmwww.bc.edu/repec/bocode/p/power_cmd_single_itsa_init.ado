*! 2.0.0 Ariel Linden 12Jan2026 // added prais option; added performance measures
*! 1.0.0 Ariel Linden 11Jun2025

capture program drop power_cmd_single_itsa_init
program power_cmd_single_itsa_init, sclass
        version 11

		syntax, [  level prais perf * ]
		
		sreturn clear
		
		if "`perf'" == "" {
			sreturn local pss_colnames "trperiod intercept pretrend posttrend step acorr reps"
			sreturn local pss_collabels `""Trperiod" "Intercept" "Pretrend" "Posttrend" "Step" "Rho" "Reps""'
			sreturn local pss_numopts  "alpha n TRPperiod INTercept PREtrend STep POSTtrend acorr reps"
		}
		else {
			sreturn local pss_colnames "trperiod intercept pretrend posttrend step acorr reps bias rmse coverage se"
			sreturn local pss_collabels `""Trperiod" "Intercept" "Pretrend" "Posttrend" "Step" "Rho" "Reps" "bias" "rmse" "coverage" "se" "'
			sreturn local pss_numopts  "alpha n TRPperiod INTercept PREtrend STep POSTtrend acorr reps"		
		}
		
		if "`prais'" == "" {
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

		
