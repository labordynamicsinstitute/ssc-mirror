*! 3.0.0 Ariel Linden 12Mar2026		// replaced praisk for prais.
									// this version now allows for multiple levels of rho()
*! 2.0.0 Ariel Linden 12Jan2026 	// added prais option; added performance measures
*! 1.0.0 Ariel Linden 11Jun2025

program define power_sim_multi_itsa, rclass
        version 11

    syntax , n(integer) 		/// number of periods
			CINTercept(real) 	/// starting level - controls
			CPOSTtrend(real) 	/// post-intervention trend - controls
			TINTercept(real) 	/// starting level - treated
			TPOSTtrend(real) 	/// post-intervention trend - treated		
			CRho1(string)		/// lag 1 AR coefficient - controls (required by itsadgp2)
			TRho1(string)		/// lag 1 AR coefficient - treated  (required by itsadgp2)
			[ TRPeriod(string)	/// the treatment period when the intervention begins
			CONTCnt(int 1)		/// count of controls
			CPREtrend(real 0)	/// baseline trend - controls
			CSTep(real 0) 		/// post-intervention change in level - controls			
			CSD(real 1)			/// standard deviation for variability of time series - controls
			CRho2(string)		/// lag 2 AR coefficient - controls
			CRho3(string)		/// lag 3 AR coefficient - controls
			TPREtrend(real 0)	/// baseline trend - treated
			TSTep(real 0) 		/// post-intervention change in level - treated			
			TSD(real 1)			/// standard deviation for variability of time series - treated
			TRho2(string)		/// lag 2 AR coefficient - treated
			TRho3(string)		/// lag 3 AR coefficient - treated
			Alpha(real 0.05)	/// alpha level			
			LEVel				/// level change
			SEED(string)		/// set seed
			PRAISK				/// specify that a praisk model be used with available options
			* ]					//  additional options passed through to itsa2


			// validate rho inputs for controls
			if "`crho2'" != "" & "`crho1'" == "" {
				di as err "crho2() requires crho1() to also be specified"
				exit(198)
			}
			if "`crho3'" != "" & "`crho2'" == "" {
				di as err "crho3() requires crho1() and crho2() to also be specified"
				exit(198)
			}

			// validate rho inputs for treated
			if "`trho2'" != "" & "`trho1'" == "" {
				di as err "trho2() requires trho1() to also be specified"
				exit(198)
			}
			if "`trho3'" != "" & "`trho2'" == "" {
				di as err "trho3() requires trho1() and trho2() to also be specified"
				exit(198)
			}

			// build rho option strings to pass to itsadgp2
			local c_rho_opts "rho1(`crho1')"
			if "`crho2'" != ""  local c_rho_opts "`c_rho_opts' rho2(`crho2')"
			if "`crho3'" != ""  local c_rho_opts "`c_rho_opts' rho3(`crho3')"

			local t_rho_opts "rho1(`trho1')"
			if "`trho2'" != ""  local t_rho_opts "`t_rho_opts' rho2(`trho2')"
			if "`trho3'" != ""  local t_rho_opts "`t_rho_opts' rho3(`trho3')"

			// determine AR order for each group from the number of rhos specified,
			// then set lag to the maximum across both groups
			local c_lag = 1
			if "`crho2'" != ""  local c_lag = 2
			if "`crho3'" != ""  local c_lag = 3

			local t_lag = 1
			if "`trho2'" != ""  local t_lag = 2
			if "`trho3'" != ""  local t_lag = 3

			local lag = max(`c_lag', `t_lag')

			// default trperiod to midpoint if not specified
			if "`trperiod'" == "" {
				local trperiod = ceil(`n' / 2)
			}
			
			if "`seed'" != "" {
				set seed `seed'
			}
			
			// generate treated dataset
			itsadgp, ntime(`n') trperiod(`trperiod') intercept(`tintercept') pretrend(`tpretrend') posttrend(`tposttrend') step(`tstep') sd(`tsd') `t_rho_opts' seed(`seed')
			gen z = 1
			gen id = 1

			tempfile dgp1
			save `dgp1', replace

			// generate control datasets
			local contmax = `contcnt' + 1
			forvalues i = 2/`contmax' {
				itsadgp2, ntime(`n') trperiod(`trperiod') intercept(`cintercept') pretrend(`cpretrend') posttrend(`cposttrend') step(`cstep') sd(`csd') `c_rho_opts'
				gen z = 0	
				gen id = `i'
				
				tempfile dgp`i'
				save `dgp`i'', replace
			}
				
			use `dgp1', replace	
			forvalues i = 2/`contmax' { 
				append using "`dgp`i''"
			}

			tsset id t

			
			************************		
			* performance measures *
			************************
			if "`praisk'" == "" {
				itsa y , treat(1) trperiod(`trperiod') lag(`lag') `options'
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
				itsa y , treat(1) trperiod(`trperiod') praisk lag(`lag') `options'
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
					lincom _z_x_t`trperiod', df(`e(df)') level(`lev')
				}
				else {
					lincom _z_x_t`trperiod', level(`lev')
				}
				// for bias
				return scalar coef = r(estimate)
				local true = (`tposttrend' - `tpretrend') - (`cposttrend' - `cpretrend')
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
					lincom _z_x`trperiod', df(`e(df)') level(`lev')
				}
				else {
					lincom _z_x`trperiod', level(`lev')
				}				
				// for bias
				return scalar coef = r(estimate)				
				local true = (`tstep' - `cstep')
				// for coverage
				return scalar cov = `true' > r(lb) & `true' < r(ub)
				// power
				return scalar reject = (r(p)<`alpha')
				// se 
				return scalar se = r(se)				
			}

end
