*! 3.0.0 Ariel Linden 12Mar2026		// replaced praisk for prais.
									// this version now allows for multiple levels of rho()
*! 2.0.0 Ariel Linden 12Jan2026 	// added prais option; added performance measures
*! 1.0.0 Ariel Linden 11Jun2025

program define power_sim_single_itsa, rclass
        version 11

    syntax , n(integer) 		/// number of periods
			INTercept(real) 	/// starting level
			POSTtrend(real) 	/// post-intervention trend
			Rho1(string)		/// lag 1 AR coefficient (required by itsadgp)
			[ TRPeriod(string)	/// the treatment period when the intervention begins
			PREtrend(real 0)	/// baseline trend
			STep(real 0) 		/// post-intervention change in level			
			sd(real 1)			/// standard deviation for randomness of time series
			Alpha(real 0.05)	/// alpha level
			Rho2(string)		/// lag 2 AR coefficient
			Rho3(string)		/// lag 3 AR coefficient
			LEVel				/// level or trend change
			SEED(string)		/// set seed
			PRAISK				/// specify that a praisk model be used with available options
			* ]					//  additional options passed through to itsa


			// validate rho inputs
			if "`rho2'" != "" & "`rho1'" == "" {
				di as err "rho2() requires rho1() to also be specified"
				exit(198)
			}
			if "`rho3'" != "" & "`rho2'" == "" {
				di as err "rho3() requires rho1() and rho2() to also be specified"
				exit(198)
			}

			// build rho option string to pass to itsadgp
			local rho_opts "rho1(`rho1')"
			if "`rho2'" != ""  local rho_opts "`rho_opts' rho2(`rho2')"
			if "`rho3'" != ""  local rho_opts "`rho_opts' rho3(`rho3')"

			// determine lag from number of rhos specified
			local lag = 1
			if "`rho2'" != ""  local lag = 2
			if "`rho3'" != ""  local lag = 3

			// default trperiod to midpoint if not specified
			if "`trperiod'" == "" {
				local trperiod = ceil(`n' / 2)
			}

			if "`seed'" != "" {
				set seed `seed'
			}

			// generate dataset
			itsadgp, ntime(`n') intercept(`intercept') pretrend(`pretrend') posttrend(`posttrend') step(`step') trperiod(`trperiod') sd(`sd') `rho_opts'

			tsset t			

			************************		
			* performance measures *
			************************
			if "`praisk'" == "" {
				itsa y , single trperiod(`trperiod') lag(`lag') `options'
				// for RMSE 
				tempvar fit errsq 
				qui predict `fit' if e(sample)
				qui gen double `errsq' = (`e(depvar)' - `fit')^2  
				su `errsq', meanonly
				tempname rmse 
				scalar `rmse' = sqrt(r(sum) / e(df)) 
				// for rmse
				return scalar rmse = `rmse'				
			}			
			else {
				itsa y , single trperiod(`trperiod') praisk lag(`lag') `options'
				// for RMSE 
				tempvar fit errsq 
				qui predict `fit' if e(sample)
				qui gen double `errsq' = (`e(depvar)' - `fit')^2  
				su `errsq', meanonly
				tempname rmse 
				scalar `rmse' = sqrt(r(sum) / e(df_r)) 
				// for rmse
				return scalar rmse = `rmse'					
			}			
			
			* get the level for coverage. Default is 95% 
			local lev = 100 - (`alpha' * 100)
			
			* trend
			if "`level'" == "" {
				if "`praisk'" == "" {
					lincom _x_t`trperiod', df(`e(df)') level(`lev')
				}
				else {
					lincom _x_t`trperiod', level(`lev')
				}
				// for bias
				return scalar coef = r(estimate)
				local true = (`posttrend' - `pretrend')
				// for coverage
				return scalar cov = `true' > r(lb) & `true' < r(ub)
				// power
				return scalar reject = (r(p)<`alpha')
				// se 
				return scalar se = r(se)
			}
			* level
			else {
				if "`praisk'" == "" {
					lincom _x`trperiod', df(`e(df)') level(`lev')
				}
				else {
					lincom _x`trperiod', level(`lev')
				}				
				// for bias
				return scalar coef = r(estimate)				
				local true = `step'
				// for coverage
				return scalar cov = `true' > r(lb) & `true' < r(ub)
				// power
				return scalar reject = (r(p)<`alpha')
				// se 
				return scalar se = r(se)				
			}			

end
