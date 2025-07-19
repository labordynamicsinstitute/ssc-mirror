*! 1.0.0 Ariel Linden 11Jun2025

capture program drop power_cmd_multi_itsa_init
program power_cmd_multi_itsa_init, sclass
        version 11

		syntax, [  level * ]
		
		sreturn clear
		sreturn local pss_title " for a multiple-group interrupted time series analysis"
		sreturn local pss_colnames "trperiod tintercept tpretrend tposttrend tstep tacorr cintercept cpretrend cposttrend cstep cacorr reps"
		sreturn local pss_collabels `""Trperiod" "Tintercept" "Tpretrend" "Tposttrend" "Tstep" "Trho" "Cintercept" "Cpretrend" "Cposttrend" "Cstep" "Crho" "Reps" "'
		sreturn local pss_numopts  "alpha n trperiod tintercept tpretrend tstep tposttrend tacorr cintercept cpretrend cstep cposttrend cacorr reps"
	
		if "`level'" == "" {
			sreturn local pss_subtitle "         (Difference in differences of pre- and post-trends)"
		}
		else {
			sreturn local pss_subtitle "   (difference in differences of change in level vs counterfactual)"			
		}
	
end
