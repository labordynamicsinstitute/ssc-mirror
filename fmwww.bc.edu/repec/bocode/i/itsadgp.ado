*! 3.0.0 Ariel Linden 29May2026 	// extended to support up to three sequential treatment periods and AR(4) error processes
									// now all inputs are percentages of intercept: b = intercept * pct / 100
*! 2.0.0 Ariel Linden 02Apr2026
*! 1.0.0 Ariel Linden 12Mar2025

program define itsadgp, rclass
	version 11

	syntax , NTime(integer) INTercept(real) PREtrend(real)			///
	         POSTtrend1(real) STep1(real) TRPeriod1(integer) 		///
	         rho1(string) 											///
	       [ POSTtrend2(real 0) STep2(real 0) TRPeriod2(integer -1) ///
	         POSTtrend3(real 0) STep3(real 0) TRPeriod3(integer -1) ///
	         sd(real 1) rho2(string) rho3(string) rho4(string) 		///
	         SEED(string) ]

	quietly {

		clear

		if "`seed'" != "" {
			set seed `seed'
		}
		set obs `ntime'

		// generate time variable (0-indexed, consistent with itsa)
		gen t = _n - 1
		label var t "Time"
		tsset t

		// determine which intervention periods are active
		local has_trp2 = (`trperiod2' != -1)
		local has_trp3 = (`trperiod3' != -1)

		// contiguity: trperiod3 requires trperiod2
		if `has_trp3' & !`has_trp2' {
			di as err "trperiod3() requires trperiod2() to also be specified"
			error 198
		}

		// range checks
		if `trperiod1' <= 0 | `trperiod1' >= `ntime' {
			di as err "trperiod1() must be between 1 and ntime()-1"
			error 198
		}
		if `has_trp2' {
			if `trperiod2' <= `trperiod1' | `trperiod2' >= `ntime' {
				di as err "trperiod2() must be greater than trperiod1() and less than ntime()"
				error 198
			}
		}
		if `has_trp3' {
			if `trperiod3' <= `trperiod2' | `trperiod3' >= `ntime' {
				di as err "trperiod3() must be greater than trperiod2() and less than ntime()"
				error 198
			}
		}

		// convert percent inputs to absolute coefficients
		local b_pre   = `intercept' * `pretrend'   / 100
		local b_post1 = `intercept' * `posttrend1' / 100
		local b_step1 = `intercept' * `step1'      / 100

		if `has_trp2' {
			local b_post2 = `intercept' * `posttrend2' / 100
			local b_step2 = `intercept' * `step2'      / 100
		}
		if `has_trp3' {
			local b_post3 = `intercept' * `posttrend3' / 100
			local b_step3 = `intercept' * `step3'      / 100
		}

		// validate and process rho parameters (AR up to order 4)
		local has_rho2 = ("`rho2'" != "")
		local has_rho3 = ("`rho3'" != "")
		local has_rho4 = ("`rho4'" != "")

		if `has_rho3' & !`has_rho2' {
			di as err "rho3() requires rho2() to also be specified"
			error 198
		}
		if `has_rho4' & !`has_rho3' {
			di as err "rho4() requires rho2() and rho3() to also be specified"
			error 198
		}

		capture confirm number `rho1'
		if _rc {
			di as err "rho1() must be a number"
			error 198
		}
		local rho1 = real("`rho1'")
		if abs(`rho1') >= 1.0 {
			di as err "|rho1| must be < 1"
			error 198
		}

		foreach rnum in 2 3 4 {
			if `has_rho`rnum'' {
				capture confirm number `rho`rnum''
				if _rc {
					di as err "rho`rnum'() must be a number"
					error 198
				}
				local rho`rnum' = real("`rho`rnum''")
				if abs(`rho`rnum'') >= 1.0 {
					di as err "|rho`rnum'| must be < 1"
					error 198
				}
			}
		}

		if !`has_rho2'  local rho2 = 0
		if !`has_rho3'  local rho3 = 0
		if !`has_rho4'  local rho4 = 0

		local ar_order = 1
		if `has_rho2'  local ar_order = 2
		if `has_rho3'  local ar_order = 3
		if `has_rho4'  local ar_order = 4

		// generate white-noise errors and apply AR structure
		tempvar u
		gen `u' = rnormal(0, `sd')

		local start_obs = `ar_order' + 1
		forval obs = `start_obs'/`ntime' {
			local ar_term = `rho1' * `u'[`obs' - 1]
			if `ar_order' >= 2  local ar_term = `ar_term' + `rho2' * `u'[`obs' - 2]
			if `ar_order' >= 3  local ar_term = `ar_term' + `rho3' * `u'[`obs' - 3]
			if `ar_order' == 4  local ar_term = `ar_term' + `rho4' * `u'[`obs' - 4]
			replace `u' = `ar_term' + rnormal(0, `sd') if _n == `obs'
		}

		/***************************************************************
		* Generate outcome y following Equation 2 of Linden (2017)
		*
		* One intervention:
		*   y = intercept + b_pre*t + b_step1*x1 + (b_post1-b_pre)*x1t + u
		*
		* Two interventions:
		*   y = intercept + b_pre*t
		*       + b_step1*x1 + (b_post1-b_pre)*x1t
		*       + b_step2*x2 + (b_post2-b_post1)*x2t + u
		*
		* Three interventions:
		*   y = intercept + b_pre*t
		*       + b_step1*x1 + (b_post1-b_pre)*x1t
		*       + b_step2*x2 + (b_post2-b_post1)*x2t
		*       + b_step3*x3 + (b_post3-b_post2)*x3t + u
		******************************************************************/

		tempvar x1 x1t
		gen `x1'  = (t >= `trperiod1')
		gen `x1t' = (t - `trperiod1') * `x1'

		if !`has_trp2' {
			gen y = `intercept'        ///
			      + (`b_pre'   * t)    ///
			      + (`b_step1' * `x1') ///
			      + ((`b_post1' - `b_pre') * `x1t') ///
			      + `u'
		}
		else if !`has_trp3' {
			tempvar x2 x2t
			gen `x2'  = (t >= `trperiod2')
			gen `x2t' = (t - `trperiod2') * `x2'

			gen y = `intercept'         ///
			      + (`b_pre'   * t)     ///
			      + (`b_step1' * `x1') + ((`b_post1' - `b_pre')   * `x1t') ///
			      + (`b_step2' * `x2') + ((`b_post2' - `b_post1') * `x2t') ///
			      + `u'
		}
		else {
			tempvar x2 x2t x3 x3t
			gen `x2'  = (t >= `trperiod2')
			gen `x2t' = (t - `trperiod2') * `x2'
			gen `x3'  = (t >= `trperiod3')
			gen `x3t' = (t - `trperiod3') * `x3'

			gen y = `intercept'         ///
			      + (`b_pre'   * t)     ///
			      + (`b_step1' * `x1') + ((`b_post1' - `b_pre')   * `x1t') ///
			      + (`b_step2' * `x2') + ((`b_post2' - `b_post1') * `x2t') ///
			      + (`b_step3' * `x3') + ((`b_post3' - `b_post2') * `x3t') ///
			      + `u'
		}

		label var y "Outcome"

	} // end quietly

end
