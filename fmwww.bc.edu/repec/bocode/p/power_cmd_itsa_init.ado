capture program drop power_cmd_itsa_init
program power_cmd_itsa_init, sclass
        version 11

		syntax, [  level * ]
		
		sreturn clear
		sreturn local pss_title " for a single-group interrupted time series analysis"
		sreturn local pss_colnames "trperiod intercept pretrend posttrend step acorr"
		sreturn local pss_collabels `""Tr-period" "Intercept" "Pre-trend" "Post-trend" "Step" "Rho""'
		sreturn local pss_numopts  "alpha n trperiod intercept pretrend step posttrend acorr"

		if "`level'" == "" {
			sreturn local pss_subtitle "                  (Difference in pre- and post-trends)"
		}
		else {
			sreturn local pss_subtitle "                  (change in level vs counterfactual)"			
		}
end
