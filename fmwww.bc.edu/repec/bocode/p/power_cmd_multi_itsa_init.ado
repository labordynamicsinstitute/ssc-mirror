*! 3.0.0 Ariel Linden 12Mar2026		// replaced praisk for prais.
									// this version now allows for multiple levels of rho()
*! 2.0.0 Ariel Linden 12Jan2026 	// added prais option; added performance measures
*! 1.0.0 Ariel Linden 11Jun2025


program power_cmd_multi_itsa_init, sclass
        version 11

		syntax, [ level praisk perf TRho2(string) TRho3(string) CRho2(string) CRho3(string) * ]
		
		sreturn clear

		*--------------------------------------------------------------
		* Build the dynamic parts of colnames, collabels, and numopts
		* based on which optional rhos were specified
		*--------------------------------------------------------------

		* treated rho columns (inserted after trho1)
		local t_rho_cols  ""
		local t_rho_labs  ""
		local t_rho_opts  ""
		if "`trho2'" != "" {
			local t_rho_cols "`t_rho_cols' trho2"
			local t_rho_labs `"`t_rho_labs' "T_rho2""'
			local t_rho_opts "`t_rho_opts' Trho2"
		}
		if "`trho3'" != "" {
			local t_rho_cols "`t_rho_cols' trho3"
			local t_rho_labs `"`t_rho_labs' "T_rho3""'
			local t_rho_opts "`t_rho_opts' Trho3"
		}

		* control rho columns (inserted after crho1)
		local c_rho_cols  ""
		local c_rho_labs  ""
		local c_rho_opts  ""
		if "`crho2'" != "" {
			local c_rho_cols "`c_rho_cols' crho2"
			local c_rho_labs `"`c_rho_labs' "C_rho2""'
			local c_rho_opts "`c_rho_opts' Crho2"
		}
		if "`crho3'" != "" {
			local c_rho_cols "`c_rho_cols' crho3"
			local c_rho_labs `"`c_rho_labs' "C_rho3""'
			local c_rho_opts "`c_rho_opts' Crho3"
		}

		*--------------------------------------------------------------
		* Assemble full colnames, collabels, numopts strings
		*--------------------------------------------------------------
		local base_cols  "contcnt trperiod tintercept tpretrend tposttrend tstep trho1`t_rho_cols' cintercept cpretrend cposttrend cstep crho1`c_rho_cols' reps"
		local base_labs  `""N_Cont" "Tr_period" "T_int" "T_pre" "T_post" "T_step" "T_rho1"`t_rho_labs' "C_int" "C_pre" "C_post" "C_step" "C_rho1"`c_rho_labs' "Reps" "'
		local base_opts  "alpha n CONTcnt TRPeriod TINTercept TPREtrend TSTep TPOSTtrend Trho1`t_rho_opts' TSD CINTercept CPREtrend CSTep CPOSTtrend Crho1`c_rho_opts' CSD reps"

		if "`perf'" != "" {
			sreturn local pss_colnames "`base_cols' bias rmse coverage se"
			sreturn local pss_collabels `"`base_labs' "bias" "rmse" "coverage" "se" "'
			sreturn local pss_numopts  "`base_opts'"
		}
		else {
			sreturn local pss_colnames "`base_cols'"
			sreturn local pss_collabels `"`base_labs'"'
			sreturn local pss_numopts  "`base_opts'"
		}
		
		if "`praisk'" == "" {
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