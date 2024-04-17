*! 1.0.0 Ariel Linden 13Apr2024
// the le Cessie - van Houwelingen - Copas - Hosmer unweighted sum of squares (USUS) test for global goodness of fit (GOF)

capture program drop usos
program define usos, rclass
version 11.0

        syntax
		
		if "`e(cmd)'" != "logit" & "`e(cmd)'" != "logistic" {
			di as err "the prior estimation model was not {bf:logit} or {bf:logistic}"
			exit 301
		}
		if "`e(wtype)'" != "" {
			di as err "{bf:weights} not allowed. Re-estimate model without weights"
			exit 101
		}
		

		quietly {
			preserve
			keep if e(sample)
			marksample touse
			keep if `touse'
			local N = "`e(N)'"

			local y = "`e(depvar)'"
			
			// tempvars and tempnames
			tempvar p sse1 wt d one resid res_wt res2
			tempname sse ev sd z pval estimate

			// parse x variables used previously in estimation model (thanks to Andrew Musau)
			local xlist= ustrregexra(ustrregexra("`e(cmdline)'", "(\b`e(cmd)'\b|\b`=word("`e(cmdline)'", 2)'\b)", ""), "^(.+?)(\bif\b|\bin\b|\,)(.*)", "$1")				
			predict `p', pr
			gen `sse1' = (`y' - `p')^2
			sum `sse1'
			* sum of squared errors
			scalar `sse' = r(sum)	
				
			gen `wt' = `p' * (1 - `p')
			sum `wt'
				
			* expected value
			scalar `ev' = r(sum)
				
			gen `d' = 1 - 2 * `p'
			gen `one' = 1
				
			regress `d' `xlist' `one' [pw = `wt'], nocons
			predict `resid' , res
			gen `res_wt' = `resid' * sqrt(`wt')
			gen `res2' = `res_wt'^2
			sum `res2'
			* std dev
			scalar `sd' = sqrt(r(sum)) 
			* Z value
			scalar `z' = (`sse' - `ev') / `sd'
			* P value
			scalar `pval' = 2 * normal(- abs(`z'))
			scalar `estimate' = `sse' - `ev'
				
		} // end quietly
		
		// Display header
		di _newline
		di as text "USOS goodness-of-fit test after logistic model"
		
		local len = strlen("`N'")
		local headcnt = 70 - `len' - 16
		di as text _newline %`headcnt's "Number of obs = " %`len'.0fc `N'
		
		// display results table
		#delim ;
		di in smcl in gr "{hline 13}{c TT}{hline 40}"
		_newline "             {c |}"
		" Estimate*"   // SSE - EV //
		_col(28) "Std. dev."
		_col(42) "z"
		_col(49) "P>|z|"
		_newline
		in gr in smcl "{hline 13}{c +}{hline 40}"
		_newline
		_col(1) %12s "`y'"
		_col(14) "{c |}" in ye
		_col(15) %9.0g `estimate'
		_col(27) %9.0g `sd'
		_col(36) %8.2f `z'
		_col(49) %5.3f `pval'
		_newline
		in gr in smcl "{hline 13}{c BT}{hline 40}"
		;
		#delim cr
		di as text "* (unweighted sum of squared errors - expected value)"
		
		// return list
		return scalar estimate = `estimate'
		return scalar sse = `sse'	
		return scalar ev = `ev'		
		return scalar sd = `sd'	
		return scalar z = `z'	
		return scalar p = `pval'
		
				
end
