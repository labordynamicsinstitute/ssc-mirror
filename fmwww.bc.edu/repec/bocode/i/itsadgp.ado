*! 1.0.0 Ariel Linden 28Dec2024

program define itsadgp, rclass
	version 11

    syntax , NTime(integer) INTercept(real) PREtrend(real) POSTtrend(real) STep(real) ///
             TRPeriod(integer)  ///
			[ sd(real 1) rho(numlist) SEED(string) ]			 

		quietly {

			clear

			if "`seed'" != "" {
				set seed `seed'
			}
			set obs `ntime'
	
			* Generate time variable
			gen t = _n-1
			label var t "Time"
			sum t, meanonly
			local maxtime = r(max)

			* tsset data
			tsset t
	
			* gen random error
			tempvar u
			gen `u' = rnormal(0,`sd')	

			* get count of values specified in rho
			local rhocnt : word count `rho'
	
			* if one or more rhos are specified
			if `rhocnt' > 0 {
				forval i = 1/`rhocnt' {
					local e "`:word `i' of `rho''" 
					if abs(`e') >= 1.0 {
						di as err " |rho| must be < 1"
						error 198
					}
					else {
						local err `e' * `u'[_n-`i']
						local bag `bag' `err' +
					}	
				}
				local bag `bag' rnormal(0,`sd')

				local rhocnt1 = `rhocnt' + 1	
				forval tt = `rhocnt1'/`maxtime' {	
					replace `u' = `bag' if t == `tt'
				}	
			} // end if rho is specified

			// Create the time series variables
			tempvar x xt
			gen `x' = t >= `trperiod' 	
			gen `xt' = (t - `trperiod') * `x'
	
			// Generate y variable with autocorrelated errors
			gen y = `intercept' + (`pretrend' * t) + (`step' *  `x')  + ((`posttrend' - `pretrend') * `xt') + `u'			
			label var y "Outcome"
	
		} // end quietly	
			
end