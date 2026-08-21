*! 1.0.0 Ariel Linden 18Aug2026

capture program drop power_cmd_onemean_rtm_init
program define power_cmd_onemean_rtm_init, sclass
	version 11
	sreturn clear

	// allow numlist (multiple values) in these method-specific options
	sreturn local pss_numopts "MU SD CORR CUToff DIFF DELTA SD1 DROPout"

	// additional supported columns
	sreturn local pss_colnames "mu sd corr cutoff diff sd1 dropout z lambda RTM pctRTM Nenroll"

	// show ALL registered columns in the default table
	sreturn local pss_collabels `""mu" "sd" "corr" "cutoff" "diff" "sd1" "dropout" "z" "lambda(z)" "RTM" "pct RTM" "N enroll""'

	// effect-size parameter
	sreturn local pss_delta "delta"
	sreturn local pss_target "delta"
	sreturn local pss_targetlabel "RTM-adjusted effect size (delta)"

	// generic hypothesis statement
	sreturn local pss_hyp_lhs "mean change"
	sreturn local pss_hyp_rhs "RTM-expected change"

	sreturn local pss_titletest "for RTM-adjusted one-mean test"
end
