*! 1.0.0 Ariel Linden 11Jun2025

capture program drop power_cmd_single_itsa_init
program power_cmd_single_itsa_init, sclass
        version 11

		syntax, [  level * ]
		
		sreturn clear
		sreturn local pss_title " for a single-group interrupted time series analysis"
		sreturn local pss_colnames "trperiod intercept pretrend posttrend step acorr reps"
		sreturn local pss_collabels `""Trperiod" "Intercept" "Pretrend" "Posttrend" "Step" "Rho" "Reps""'
		sreturn local pss_numopts  "alpha n trperiod intercept pretrend step posttrend acorr reps"

		if "`level'" == "" {
			sreturn local pss_subtitle "                  (Difference in pre- and post-trends)"
		}
		else {
			sreturn local pss_subtitle "                  (change in level vs counterfactual)"			
		}
end
