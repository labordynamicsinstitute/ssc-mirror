*! 2.0.0 Ariel Linden 12Jan2026 // added prais option; added performance measures
*! 1.0.0 Ariel Linden 11Jun2025

capture program drop power_sim_single_itsa
program define power_sim_single_itsa, rclass
        version 11

    syntax , n(integer) 		/// number of periods
			INTercept(real) 	/// starting level
			POSTtrend(real) 	/// post-intervention trend
			[ TRPeriod(string)	/// the treatment period when the intervention begins
			PREtrend(real 0)	/// baseline trend
			STep(real 0) 		/// post-intervention change in level			
			sd(real 1)			/// standard deviation for randomness of time series
			Alpha(real 0.05)	/// alpha level
			acorr(real 0)		/// autocorrelation (rho)
			LEVel				///  level or trend change
			SEED(string)		/// set seed
			PRAIS * ]			//	specify that a prais model be used with available options
   
			if "`trperiod'" == "" {
				local trperiod = ceil(`n' / 2)
			}
   
			itsadgp, ntime(`n') intercept(`intercept') pretrend(`pretrend') posttrend(`posttrend') step(`step') trperiod(`trperiod') sd(`sd') rho(`acorr') 
			
			tsset t			
			
			************************		
			* performance measures *
			************************
			if "`prais'" == "" {
				itsa y , single trperiod(`trperiod') lag(1)
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
				itsa y , single trperiod(`trperiod') prais `options'
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
				if "`prais'" == "" {
					lincom _x`trperiod', df(`e(df)') level(`lev')
				}
				else {
					lincom _x`trperiod', level(`lev')
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