capture program drop power_cmd_itsa
program define power_cmd_itsa, rclass
        version 11

    syntax , n(integer) 		/// number of periods
			INTercept(real) 	/// starting level
			POSTtrend(real) 	/// post-intervention trend
			[ TRPeriod(string)	/// the treatment period when the intervention begins
			PREtrend(real 0)	/// baseline trend
			STep(real 0) 		/// post-intervention change in level			
			sd(real 1) 			/// standard deviation for randomness of time series
			alpha(real 0.05)	/// alpha level
			acorr(real 0)		/// autocorrelation
			LEVel				/// specify level change and not trend change
			NOIsily				/// show the simulations dots
			reps(integer 100) ]	//  number of repetitions      

			preserve
			
			if "`noisily'" == "" {
				local quietly quietly
			}
			
			if "`trperiod'" == "" {
				local trperiod = ceil(`n' / 2)
			}
			
			`quietly' simulate reject=r(reject), reps(`reps'): power_sim_itsa, n(`n') intercept(`intercept') pretrend(`pretrend') ///
				posttrend(`posttrend') step(`step') trperiod(`trperiod') sd(`sd') acorr(`acorr') alpha(`alpha') `level'
    
			summarize reject, meanonly

			// return results
			return scalar power = r(mean)
			return scalar N = `n'
			return scalar trperiod = `trperiod'			
			return scalar alpha = `alpha'
			return scalar intercept = `intercept'
			return scalar pretrend = `pretrend'
			return scalar step = `step'
			return scalar posttrend = `posttrend'
			return scalar sd = `sd'		
			return scalar acorr = `acorr'	
			restore
			

end