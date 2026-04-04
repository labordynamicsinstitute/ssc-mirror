*! 3.0.0 Ariel Linden 12Mar2026		// replaced praisk for prais.
									// this version now allows for multiple levels of rho()
*! 2.0.0 Ariel Linden 12Jan2026 	// added prais option; added performance measures
*! 1.0.0 Ariel Linden 11Jun2025


program define power_cmd_single_itsa, rclass
        version 11

    syntax , n(integer) 		/// number of periods
			INTercept(real) 	/// starting level
			POSTtrend(real) 	/// post-intervention trend
			Rho1(string)		/// lag 1 AR coefficient (required)
			[ TRPeriod(string)	/// the treatment period when the intervention begins
			PREtrend(real 0)	/// baseline trend
			STep(real 0) 		/// post-intervention change in level			
			sd(real 1) 			/// standard deviation for randomness of time series
			alpha(real 0.05)	/// alpha level
			Rho2(string)		/// lag 2 AR coefficient
			Rho3(string)		/// lag 3 AR coefficient
			LEVel				/// specify level change and not trend change
			NOIsily				/// show the simulation dots
			REPs(integer 100)	/// number of repetitions
			seed(string) 		/// seed
			PERF				/// performance measures will get passed on to output table
			PRAISK				/// specify a praisk model
			* ]					// additional options passed through to power_sim_single_itsa2

			preserve
			
			if "`noisily'" == "" {
				local quietly quietly
			}
			
			if "`trperiod'" == "" {
				local trperiod = ceil(`n' / 2)
			}
			
			// initial seed
			if "`seed'" != "" {
				set seed `seed'
			}
			local inis `=c(seed)'

			// build optional rho strings to pass to power_sim_single_itsa2
			local rho_opts "rho1(`rho1')"
			if "`rho2'" != ""  local rho_opts "`rho_opts' rho2(`rho2')"
			if "`rho3'" != ""  local rho_opts "`rho_opts' rho3(`rho3')"

			if "`perf'" == "" {
				`quietly' simulate reject=r(reject), reps(`reps') seed(`seed'): power_sim_single_itsa, ///
					n(`n') intercept(`intercept') pretrend(`pretrend') ///
					posttrend(`posttrend') step(`step') trperiod(`trperiod') sd(`sd') ///
					`rho_opts' alpha(`alpha') `level' `praisk' `options'
			}
			else {
				`quietly' simulate reject=r(reject) coef=r(coef) rmse=r(rmse) cov=r(cov) se=r(se), reps(`reps') seed(`seed'): power_sim_single_itsa, ///
					n(`n') intercept(`intercept') pretrend(`pretrend') ///
					posttrend(`posttrend') step(`step') trperiod(`trperiod') sd(`sd') ///
					`rho_opts' alpha(`alpha') `level' `praisk' `options'
			}
			
    
			************************
			* performance measures *
			************************
			summarize reject, meanonly
			return scalar power = r(mean)
			
			if "`perf'" != "" {
				summarize rmse, meanonly
				return scalar rmse = r(mean)
			
				summarize cov, meanonly
				return scalar coverage = r(mean)
			
				summarize se, meanonly
				return scalar se = r(mean)			

				summarize coef, meanonly
				if "`level'" == "" {
					local true = (`posttrend' - `pretrend')
				}
				else {
					local true = `step'
				}
				return scalar bias = (( r(mean) - `true') / `true') * 100
			}

			// return results
			return scalar N = `n'
			return scalar trperiod = `trperiod'			
			return scalar alpha = `alpha'
			return scalar intercept = `intercept'
			return scalar pretrend = `pretrend'
			return scalar step = `step'
			return scalar posttrend = `posttrend'
			return scalar sd = `sd'
			return scalar rho1 = `rho1'
			if "`rho2'" != ""  return scalar rho2 = `rho2'
			if "`rho3'" != ""  return scalar rho3 = `rho3'
			return scalar reps = `reps'
			
			restore

end
