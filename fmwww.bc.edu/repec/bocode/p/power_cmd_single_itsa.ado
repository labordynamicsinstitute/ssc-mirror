*! 1.0.0 Ariel Linden 11Jun2025

capture program drop power_cmd_single_itsa
program define power_cmd_single_itsa, rclass
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
			REPs(integer 100)	///
			seed(string) ]		//  number of repetitions       

			preserve
			
			if "`noisily'" == "" {
				local quietly quietly
			}
			
			if "`trperiod'" == "" {
				local trperiod = ceil(`n' / 2)
			}
			
			// Initial seed
			if "`seed'"!="" {
				set seed `seed'
			}
			local inis `=c(seed)'			
			
			`quietly' simulate reject=r(reject), reps(`reps') seed(`seed'): power_sim_single_itsa, n(`n') intercept(`intercept') pretrend(`pretrend') ///
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
			return scalar reps= `reps'
			
			restore
			

end