*! 3.0.0 Ariel Linden 12Mar2026		// replaced praisk for prais.
									// this version now allows for multiple levels of rho()
*! 2.0.0 Ariel Linden 12Jan2026 	// added prais option; added performance measures
*! 1.0.0 Ariel Linden 11Jun2025

program define power_cmd_multi_itsa, rclass
        version 11

    syntax , n(integer) 		/// number of periods
			CINTercept(real) 	/// starting level - controls
			CPOSTtrend(real) 	/// post-intervention trend - controls
			TINTercept(real) 	/// starting level - treated
			TPOSTtrend(real) 	/// post-intervention trend - treated		
			CRho1(string)		/// lag 1 AR coefficient - controls (required)
			TRho1(string)		/// lag 1 AR coefficient - treated  (required)
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
			LEVel				/// specify level change and not trend change
			NOIsily				/// show the simulation dots
			reps(integer 100)	/// number of repetitions 
			seed(string) 		/// seed
			PERF				/// performance measures will get passed on to output table
			PRAISK				/// specify a praisk model
			* ]					// additional options passed through to power_sim_multi_itsa2
			
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

			// build optional rho strings to pass to power_sim_multi_itsa2
			local c_rho_opts "crho1(`crho1')"
			if "`crho2'" != ""  local c_rho_opts "`c_rho_opts' crho2(`crho2')"
			if "`crho3'" != ""  local c_rho_opts "`c_rho_opts' crho3(`crho3')"

			local t_rho_opts "trho1(`trho1')"
			if "`trho2'" != ""  local t_rho_opts "`t_rho_opts' trho2(`trho2')"
			if "`trho3'" != ""  local t_rho_opts "`t_rho_opts' trho3(`trho3')"

			if "`perf'" != "" {
				`quietly' simulate reject=r(reject) coef=r(coef) rmse=r(rmse) cov=r(cov) se=r(se), reps(`reps') seed(`seed') : power_sim_multi_itsa, ///
					n(`n') contcnt(`contcnt') ///
					tintercept(`tintercept') cintercept(`cintercept') ///
					tpretrend(`tpretrend') cpretrend(`cpretrend') ///
					tposttrend(`tposttrend') cposttrend(`cposttrend') ///
					tstep(`tstep') cstep(`cstep') ///
					tsd(`tsd') csd(`csd') ///
					`t_rho_opts' `c_rho_opts' ///
					trperiod(`trperiod') alpha(`alpha') `level' `praisk' `options'
			}
			else {
				`quietly' simulate reject=r(reject), reps(`reps') seed(`seed') : power_sim_multi_itsa, ///
					n(`n') contcnt(`contcnt') ///
					tintercept(`tintercept') cintercept(`cintercept') ///
					tpretrend(`tpretrend') cpretrend(`cpretrend') ///
					tposttrend(`tposttrend') cposttrend(`cposttrend') ///
					tstep(`tstep') cstep(`cstep') ///
					tsd(`tsd') csd(`csd') ///
					`t_rho_opts' `c_rho_opts' ///
					trperiod(`trperiod') alpha(`alpha') `level' `praisk' `options'
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
					local true = (`tposttrend' - `tpretrend') - (`cposttrend' - `cpretrend')
				}
				else {
					local true = (`tstep' - `cstep') 
				}
				return scalar bias = (( r(mean) - `true') / `true') * 100
			}

			// return results
			return scalar N = `n'
			return scalar contcnt = `contcnt'
			return scalar trperiod = `trperiod'			
			return scalar alpha = `alpha'
			return scalar tintercept = `tintercept'
			return scalar tpretrend = `tpretrend'
			return scalar tstep = `tstep'
			return scalar tposttrend = `tposttrend'
			return scalar tsd = `tsd'
			return scalar trho1 = `trho1'
			if "`trho2'" != ""  return scalar trho2 = `trho2'
			if "`trho3'" != ""  return scalar trho3 = `trho3'
			return scalar cintercept = `cintercept'
			return scalar cpretrend = `cpretrend'
			return scalar cstep = `cstep'
			return scalar cposttrend = `cposttrend'
			return scalar csd = `csd'
			return scalar crho1 = `crho1'
			if "`crho2'" != ""  return scalar crho2 = `crho2'
			if "`crho3'" != ""  return scalar crho3 = `crho3'
			return scalar reps = `reps'
			
			restore

end
