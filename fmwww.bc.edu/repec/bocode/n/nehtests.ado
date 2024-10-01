*! nehtests v2.0.0
*! 16 September 2024
*! Alfonso Sanchez-Penalver

/*******************************************************************************
* This program presents the tests of joint significance from the estimations.  *
* of nehurdle. It is only distributed with the command nehurdle and will only. *
* work after an estimation using nehurdle. This program runs no test itself,   *
* all the tests were run during nehurlde estimation, and stored in e(). Since. *
* everything  is already stored in e(), this program doesn't store any values, *
* only displays them.														   *
*******************************************************************************/

capture program drop nehtests
program define nehtests
	if "`e(cmd)'" != "nehurdle" {
		di as error "{bf:nehtests} only works after {bf:nehurdle} estimations."
		exit 198
	}
	// Checking if the tests yielded a statistic
	if "`e(chi2)'" == "." 														///
		local ov_txt "{help j_robustsingular##|_new:Wald chi2(`e(df_m)')}"
	else 																		///
		local ov_txt "Wald chi2({bf:`e(df_m)'})"
	di as txt "{hline 59}"
	di as txt _col(3) "`e(title)' test(s) of joint significance"
	di as txt "{hline 59}"
	// Tobit and truncated poisson are different than the other two
	if "`e(cmd_opt)'" == "tobit" {
		// Ok so if we have heteroskedasticity we have three, if not just the overall
		// So the overall is always on its own.
		if "`e(het)'" != "" {
			// Value and Value hetero
			if "`e(val_chi2)'" == "." 											///
				local va_txt "{help j_robustsingular##|_new:Wald chi2(`e(val_df)')}"
			else 																///
				local va_txt "Wald chi2({bf:`e(val_df)'})"
			if "`e(het_chi2)'" == "." 												///
				local se_txt "{help j_robustsingular##|_new:Wald chi2(`e(het_df)')}"
			else 																	///
				local se_txt "Wald chi2({bf:`e(het_df)'})"
			di as txt _col(3) "Value Equation" _col(32) "Value Std. Dev."
			di as txt _col(3) _dup(26) "-" _col(32) _dup(26) "-"
			di as txt _col(3) "`va_txt'" _col(17) "= " _col(20) as result %9.2f	///
				e(val_chi2) as txt _col(32) "`se_txt'" _col(46) "= " _col(49)	///
				as result %9.2f e(het_chi2)
			di as txt _col(3) "Prob > chi2" _col(17) "= " _col(20) as result	///
				%9.4f e(val_p) as txt _col(32) "Prob > chi2" _col(46) "= "		///
				_col(49) as result %9.4f e(het_p)
			di as txt _col(3) _dup(26) "-" _col(32) _dup(26) "-"
			di ""
		}
		di as txt _col(3) "Overall"
		di as txt _col(3) _dup(24) "-"
		di as txt _col(3) "`ov_txt'" _col(17) "= " _col(20) as result %7.2f e(chi2)
		di as txt _col(3) "Prob > chi2" _col(17) "= " _col(20) as result %7.4f e(p)
		di as txt _col(3) _dup(24) "-"
	}
	else if "`e(cmd_opt)'" == "truncp" {
		// Here we have selection and value, no variance. But we can have selection
		// hetero. So if selection hetero we have 4 (including overall), if not 3.
		// So we always have selection and value in the first row, and if we have
		// selection hetero, we have two in the second row, if not just the overall.
		if "`e(sel_chi2)'" == "." 												///
			local se_txt "{help j_robustsingular##|_new:Wald chi2(`e(sel_df)')}"
		else 																	///
			local se_txt "Wald chi2({bf:`e(sel_df)'})"
		if "`e(val_chi2)'" == "." 												///
			local va_txt "{help j_robustsingular##|_new:Wald chi2(`e(val_df)')}"
		else 																	///
			local va_txt "Wald chi2({bf:`e(val_df)'})"
		di as txt _col(3) "Selection Equation" _col(32) "Value Equation"
		di as txt _col(3) _dup(26) "-" _col(32) _dup(26) "-"
		di as txt _col(3) "`se_txt'" _col(17) "= " _col(20) as result %9.2f		///
			e(sel_chi2) as txt _col(32) "`va_txt'" _col(46) "= " _col(49) as	///
			result %9.2f e(val_chi2)
		di as txt _col(3) "Prob > chi2" _col(17) "= " _col(20) as result %9.4f	///
			e(sel_p) as txt _col(32) "Prob > chi2" _col(46) "= " _col(49) as	///
			result %9.4f e(val_p)
		di as txt _col(3) _dup(26) "-" _col(32) _dup(26) "-"
		di ""
		
		if "`e(selhet)'" != "" {
				if "`e(selhet_chi2)'" == "." 											///
				local se_txt "{help j_robustsingular##|_new:Wald chi2(`e(selhet_df)')}"
			else 																///
				local se_txt "Wald chi2({bf:`e(selhet_df)'})"
			di as txt _col(3) "Selection Std. Dev." _col(32) "Overall"
			di as txt _col(3) _dup(26) "-" _col(32) _dup(26) "-"
			di as txt _col(3) "`se_txt'" _col(17) "= " _col(20) as result %9.2f		///
				e(selhet_chi2) as txt _col(32) "`ov_txt'" _col(46) "= " _col(49) as	///
				result %9.2f e(chi2)
			di as txt _col(3) "Prob > chi2" _col(17) "= " _col(20) as result %9.4f	///
				e(selhet_p) as txt _col(32) "Prob > chi2" _col(46) "= " _col(49) as	///
				result %9.4f e(p)
			di as txt _col(3) _dup(26) "-" _col(32) _dup(26) "-"
			di ""
		}
		else {
			// Overall
			di as txt _col(3) "Overall"
			di as txt _col(3) _dup(24) "-"
			di as txt _col(3) "`ov_txt'" _col(17) "= " _col(20) as result %7.2f e(chi2)
			di as txt _col(3) "Prob > chi2" _col(17) "= " _col(20) as result %7.4f e(p)
			di as txt _col(3) _dup(24) "-"
		}
	}
	else {
		// Normal hurdles, tobit type 2 and truncated negative binomials all have
		// at least selection and value.
		if "`e(sel_chi2)'" == "." 												///
			local se_txt "{help j_robustsingular##|_new:Wald chi2(`e(sel_df)')}"
		else 																	///
			local se_txt "Wald chi2({bf:`e(sel_df)'})"
		if "`e(val_chi2)'" == "." 												///
			local va_txt "{help j_robustsingular##|_new:Wald chi2(`e(val_df)')}"
		else 																	///
			local va_txt "Wald chi2({bf:`e(val_df)'})"
		di as txt _col(3) "Selection Equation" _col(32) "Value Equation"
		di as txt _col(3) _dup(26) "-" _col(32) _dup(26) "-"
		di as txt _col(3) "`se_txt'" _col(17) "= " _col(20) as result %9.2f		///
			e(sel_chi2) as txt _col(32) "`va_txt'" _col(46) "= " _col(49) as	///
			result %9.2f e(val_chi2)
		di as txt _col(3) "Prob > chi2" _col(17) "= " _col(20) as result %9.4f	///
			e(sel_p) as txt _col(32) "Prob > chi2" _col(46) "= " _col(49) as	///
			result %9.4f e(val_p)
		di as txt _col(3) _dup(26) "-" _col(32) _dup(26) "-"
		di ""
		
		if "`e(cmd_opt)'" == "truncnb1" | "`e(cmd_opt)'" == "truncnb2"			///
			local svtitle "Dispersion (lnalpha)"
		else local svtitle "Value Std. Dev."
		
		// Now we can have heteroskedasticity equations or not, and we always
		// have the overall test
		if "`e(het)'" != "" &  "`e(selhet)'" != "" {
			// Both Heteroskedasticities
			if "`e(het_chi2)'" == "." 											///
				local va_txt "{help j_robustsingular##|_new:Wald chi2(`e(het_df)')}"
			else 																///
				local va_txt "Wald chi2({bf:`e(het_df)'})"
			if "`e(selhet_chi2)'" == "." 											///
				local se_txt "{help j_robustsingular##|_new:Wald chi2(`e(selhet_df)')}"
			else 																///
				local se_txt "Wald chi2({bf:`e(selhet_df)'})"
			di as txt _col(3) "Selection Std. Dev." _col(32) "`svtitle'"
			di as txt _col(3) _dup(26) "-" _col(32) _dup(26) "-"
			di as txt _col(3) "`se_txt'" _col(17) "= " _col(20) as result %9.2f		///
				e(selhet_chi2) as txt _col(32) "`va_txt'" _col(46) "= " _col(49) as	///
				result %9.2f e(het_chi2)
			di as txt _col(3) "Prob > chi2" _col(17) "= " _col(20) as result %9.4f	///
				e(selhet_p) as txt _col(32) "Prob > chi2" _col(46) "= " _col(49) as	///
				result %9.4f e(het_p)
			di as txt _col(3) _dup(26) "-" _col(32) _dup(26) "-"
			di ""
			// Overall
			di as txt _col(3) "Overall"
			di as txt _col(3) _dup(24) "-"
			di as txt _col(3) "`ov_txt'" _col(17) "= " _col(20) as result %7.2f e(chi2)
			di as txt _col(3) "Prob > chi2" _col(17) "= " _col(20) as result %7.4f e(p)
			di as txt _col(3) _dup(24) "-"
		}
		else if "`e(het)'" != "" {
			// Only value heteroskedasticity and overall
			if "`e(het_chi2)'" == "." 											///
				local va_txt "{help j_robustsingular##|_new:Wald chi2(`e(het_df)')}"
			else 																///
				local va_txt "Wald chi2({bf:`e(het_df)'})"
			di as txt _col(3) "`svtitle'" _col(32) "Overall"
			di as txt _col(3) _dup(26) "-" _col(32) _dup(26) "-"
			di as txt _col(3) "`va_txt'" _col(17) "= " _col(20) as result %9.2f	///
				e(het_chi2) as txt _col(32) "`ov_txt'" _col(46) "= " _col(49)	///
				as result %9.2f e(chi2)
			di as txt _col(3) "Prob > chi2" _col(17) "= " _col(20) as result	///
				%9.4f e(het_p) as txt _col(32) "Prob > chi2" _col(46) "= "		///
				_col(49) as result %9.4f e(p)
			di as txt _col(3) _dup(26) "-" _col(32) _dup(26) "-"
		}
		else if "`e(selhet)'" != "" {
			// Only selection heteroskedasticity and overall
			if "`e(het_chi2)'" == "." 											///
				local va_txt "{help j_robustsingular##|_new:Wald chi2(`e(selhet_df)')}"
			else 																///
				local va_txt "Wald chi2({bf:`e(selhet_df)'})"
			di as txt _col(3) "Selection Std. Dev." _col(32) "Overall"
			di as txt _col(3) _dup(26) "-" _col(32) _dup(26) "-"
			di as txt _col(3) "`va_txt'" _col(17) "= " _col(20) as result %9.2f	///
				e(selhet_chi2) as txt _col(32) "`ov_txt'" _col(46) "= "			///
				_col(49) as result %9.2f e(chi2)
			di as txt _col(3) "Prob > chi2" _col(17) "= " _col(20) as result	///
				%9.4f e(selhet_p) as txt _col(32) "Prob > chi2" _col(46) "= "	///
				_col(49) as result %9.4f e(p)
			di as txt _col(3) _dup(26) "-" _col(32) _dup(26) "-"
		}
		else {
			// Only overall
			di as txt _col(3) "Overall"
			di as txt _col(3) _dup(24) "-"
			di as txt _col(3) "`ov_txt'" _col(17) "= " _col(20) as result %7.2f	///
				e(chi2)
			di as txt _col(3) "Prob > chi2" _col(17) "= " _col(20) as result	///
				%7.4f e(p)
			di as txt _col(3) _dup(24) "-"
		}
	}
	di as txt "{hline 59}"
end
// Version 1.0.0 did tests for normal hurdles, tobit and type 2 tobit
// Version 2.0.0 added the truncated poisson and truncated negative binomial hurdles
