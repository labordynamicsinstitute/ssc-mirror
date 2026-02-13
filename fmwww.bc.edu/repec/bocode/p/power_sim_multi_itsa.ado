*! 2.0.0 Ariel Linden 12Jan2026 // added prais option; added performance measures
*! 1.1.0 Ariel Linden 24Jul2025
*! 1.0.0 Ariel Linden 11Jun2025

program define power_sim_multi_itsa, rclass
        version 11

    syntax , n(integer) 		/// number of periods
			CINTercept(real) 	/// starting level - controls
			CPOSTtrend(real) 	/// post-intervention trend - controls
			TINTercept(real) 	/// starting level - treated
			TPOSTtrend(real) 	/// post-intervention trend	- treated		
			[ TRPeriod(string)	/// the treatment period when the intervention begins
			CONTCnt(int 1)		/// count of controls
			CPREtrend(real 0)	/// baseline trend - controls
			CSTep(real 0) 		/// post-intervention change in level - controls			
			CSD(real 1)			/// standard deviation for variability of time series - controls
			CACorr(real 0)		/// autocorrelation (rho) - controls
			TPREtrend(real 0)	/// baseline trend - treated
			TSTep(real 0) 		/// post-intervention change in level - treated			
			TSD(real 1)			/// standard deviation for variability of time series - treated
			TACorr(real 0)		/// autocorrelation (rho) - treated
			Alpha(real 0.05)	/// alpha level			
			LEVel				/// level change
			SEED(string)		/// set seed
			PRAIS * ]			//	specify that a prais model be used with available options
   
			if "`trperiod'" == "" {
				local trperiod = ceil(`n' / 2)
			}
			
			if "`seed'" != "" {
				set seed `seed'
			}
			
			// first dataset is for treated unit
			itsadgp, ntime(`n') trperiod(`trperiod') intercept(`tintercept') pretrend(`tpretrend') posttrend(`tposttrend') step(`tstep') sd(`tsd') rho(`tacorr') seed(`seed')
			gen z = 1
			gen id = 1

			tempfile dgp1
			save `dgp1', replace

			// controls dataset
			local contmax = `contcnt' + 1
			forvalues i = 2/`contmax' {
				itsadgp, ntime(`n') trperiod(`trperiod') intercept(`cintercept') pretrend(`cpretrend') posttrend(`cposttrend') step(`cstep') sd(`csd') rho(`cacorr')
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
			if "`prais'" == "" {
				itsa y , treat(1) trperiod(`trperiod') lag(1)
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
				itsa y , treat(1) trperiod(`trperiod') prais `options'
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
				if "`prais'" == "" {
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
				if "`prais'" == "" {
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