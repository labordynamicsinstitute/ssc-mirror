*! 2.0.0 Ariel Linden 02Apr2026	// this now breaks out the rho() into separate options
*! 1.0.0 Ariel Linden 12Mar2025

program define itsadgp, rclass
	version 11

    syntax , NTime(integer) INTercept(real) PREtrend(real) POSTtrend(real) STep(real) ///
             TRPeriod(integer) rho1(string) ///
			[ sd(real 1) rho2(string) rho3(string) SEED(string) ]			 

		quietly {

			clear

			if "`seed'" != "" {
				set seed `seed'
			}
			set obs `ntime'
	
			// generate time variable
			gen t = _n - 1
			label var t "Time"
			sum t, meanonly
			local maxtime = r(max)

			// tsset data
			tsset t

			local has_rho2 = ("`rho2'" != "")
			local has_rho3 = ("`rho3'" != "")

			// validate that rho(s) are numeric
			capture confirm number `rho1'
			if _rc {
				di as err "rho1() must be a number"
				error 198
			}
			local rho1 = real("`rho1'")

			foreach rnum in 2 3 {
				if `has_rho`rnum'' {
					capture confirm number `rho`rnum''
					if _rc {
						di as err "rho`rnum'() must be a number"
						error 198
					}
					local rho`rnum' = real("`rho`rnum''")
				}
			}

			// contiguity check: rho3 requires rho2
			if (`has_rho3' & !`has_rho2') {
				di as err "rho3() requires rho2() to also be specified"
				error 198
			}

			// set unspecified rhos to 0 for use in the AR loop
			if !`has_rho2'  local rho2 = 0
			if !`has_rho3'  local rho3 = 0

			// |rho| < 1 check
			if abs(`rho1') >= 1.0 {
				di as err "|rho1| must be < 1"
				error 198
			}
			if `has_rho2' & abs(`rho2') >= 1.0 {
				di as err "|rho2| must be < 1"
				error 198
			}
			if `has_rho3' & abs(`rho3') >= 1.0 {
				di as err "|rho3| must be < 1"
				error 198
			}

			// AR order is the highest rho explicitly provided
			local ar_order = 1
			if `has_rho2'  local ar_order = 2
			if `has_rho3'  local ar_order = 3

			// generate base white-noise errors
			tempvar u
			gen `u' = rnormal(0, `sd')	

			// apply AR structure row-by-row
			if `ar_order' > 0 {
				local start_obs = `ar_order' + 1
				forval obs = `start_obs'/`ntime' {
					local ar_term = `rho1' * `u'[`obs' - 1]
					if `ar_order' >= 2  local ar_term = `ar_term' + `rho2' * `u'[`obs' - 2]
					if `ar_order' == 3  local ar_term = `ar_term' + `rho3' * `u'[`obs' - 3]
					replace `u' = `ar_term' + rnormal(0, `sd') if _n == `obs'
				}
			}

			// create the time series variables
			tempvar x xt
			gen `x'  = t >= `trperiod'
			gen `xt' = (t - `trperiod') * `x'
	
			// generate y variable with autocorrelated errors
			gen y = `intercept' + (`pretrend' * t) + (`step' * `x') ///
			        + ((`posttrend' - `pretrend') * `xt') + `u'
			label var y "Outcome"
	
		} // end quietly	
			
end
