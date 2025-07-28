*! 1.1.0 Ariel Linden 24Jul2025
*! 1.0.0 Ariel Linden 11Jun2025

capture program drop power_sim_multi_itsa
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
			LEVel ]				//  level or trend change
   
			if "`trperiod'" == "" {
				local trperiod = ceil(`n' / 2)
			}
   
			// first dataset is for treated unit
			itsadgp, ntime(`n') trperiod(`trperiod') intercept(`tintercept') pretrend(`tpretrend') posttrend(`tposttrend') step(`tstep') sd(`tsd') rho(`tacorr')
			gen z = 1
			gen id = 1

			tempfile dgp1
			save `dgp1', replace

			// controls dataset
			forvalues i = 2/`contcnt' {
				itsadgp, ntime(`n') trperiod(`trperiod') intercept(`cintercept') pretrend(`cpretrend') posttrend(`cposttrend') step(`cstep') sd(`csd') rho(`cacorr')
				gen z = 0	
				gen id = `i' 
				
				tempfile dgp`i'
				save `dgp`i'', replace
			}
				
			use `dgp1', replace	
				forvalues i = 2/`contcnt' { 
				append using "`dgp`i''"
			}

			tsset id t
			
			itsa y , treat(1) trperiod(`trperiod') lag(1)
			test _z_x_t`trperiod' 
			
			// choose the desired outcome - change in level or change in trend
			if "`level'" == "" {
				test _z_x_t`trperiod'			
			}
			else {
				test _z_x`trperiod'
			}	
			return scalar reject = (r(p)<`alpha') 
			

end