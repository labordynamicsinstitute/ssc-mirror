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
			LEVel ]				//  level or trend change
   
			if "`trperiod'" == "" {
				local trperiod = ceil(`n' / 2)
			}
   
			itsadgp, ntime(`n') intercept(`intercept') pretrend(`pretrend') posttrend(`posttrend') step(`step') trperiod(`trperiod') sd(`sd') rho(`acorr') 
			
			itsa y, single trperiod(`trperiod') posttrend lag(1)

			// choose the desired outcome - change in level or change in trend
			if "`level'" == "" {
				test _x_t`trperiod'				
			}
			else {
				test _x`trperiod'
			}	
			return scalar reject = (r(p)<`alpha') 


end