*! 2.0.0 Ariel Linden 12Jan2026 // added prais option; added performance measures
*! 1.2.0 Ariel Linden 22Dec2025 // fixed numopts to ensure that abbrev input names work
*! 1.1.0 Ariel Linden 24Jul2025
*! 1.0.0 Ariel Linden 11Jun2025

program power_cmd_multi_itsa_init, sclass
        version 11

		syntax, [  level prais perf * ]
		
		sreturn clear
		
		if "`perf'" != "" {
			sreturn local pss_colnames "contcnt trperiod tintercept tpretrend tposttrend tstep tacorr cintercept cpretrend cposttrend cstep cacorr reps bias rmse coverage se"
			sreturn local pss_collabels `""N_Cont" "Tr_period" "T_int" "T_pre" "T_post" "T_step" "T_ac" "C_int" "C_pre" "C_post" "C_step" "C_ac" "Reps" "bias" "rmse" "coverage" "se" "'
			sreturn local pss_numopts  "alpha n CONTcnt TRPeriod TINTercept TPREtrend TSTep TPOSTtrend TACorr TSD CINTercept CPREtrend CSTep CPOSTtrend CACorr CSD reps"
		}
		
		else {
			sreturn local pss_colnames "contcnt trperiod tintercept tpretrend tposttrend tstep tacorr cintercept cpretrend cposttrend cstep cacorr reps"
			sreturn local pss_collabels `""N_Cont" "Tr_period" "T_int" "T_pre" "T_post" "T_step" "T_ac" "C_int" "C_pre" "C_post" "C_step" "C_ac" "Reps" "'
			sreturn local pss_numopts  "alpha n CONTcnt TRPeriod TINTercept TPREtrend TSTep TPOSTtrend TACorr TSD CINTercept CPREtrend CSTep CPOSTtrend CACorr CSD reps"			
		}
		
		if "`prais'" == "" {
			sreturn local pss_title " for a multiple-group interrupted time series analysis: GLM with Newey-West std. errs."
		}		
		else {		
			sreturn local pss_title " for a multiple-group interrupted time series analysis: Prais-Winsten regression"
		}			
		
		
		if "`level'" == "" {
			sreturn local pss_subtitle "(Difference in differences of pre- and post-trends)"
		}
		else {
			sreturn local pss_subtitle "(difference in differences of change in level vs counterfactual)"			
		}
		
		
	
end