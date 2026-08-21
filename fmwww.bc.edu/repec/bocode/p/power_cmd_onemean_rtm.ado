*! 1.0.0 Ariel Linden 18Aug2026

capture program drop power_cmd_onemean_rtm
program define power_cmd_onemean_rtm, rclass
	version 11

	// trailing "*" absorbs any option power's framework passes through
	// that we don't explicitly declare (confirmed necessary in practice)
	syntax , ///
		MU(real) SD(real) CORR(real) CUToff(real) ///
		[ ///
		DIFF(real -999) ///
		DELTA(real -999) ///
		n(real -1) ///
		Power(real -1) ///
		Beta(real -1) ///
		SELect(string) ///
		Alpha(real 0.05) ///
		ONESided ///
		SD1(real -999) ///
		DROPout(real 0) ///
		* ///
		]

	// power() or beta()?
	if `power' != -1 & `beta' != -1 {
		di as error "specify only one of power() or beta()"
		exit 198
	}
	if `beta' != -1 {
		local power = 1 - `beta'
	}

	// diff() or delta()?
	if `diff' != -999 & `delta' != -999 {
		di as error "specify only one of diff() or delta()"
		exit 198
	}
	if `delta' != -999 & abs(`delta') < 1e-8 {
		di as error "delta() cannot be exactly zero (no effect to power)"
		exit 198
	}

	// determine which mode we're in based on what's missing
	local have_diff  = (`diff'  != -999)
	local have_delta = (`delta' != -999)
	local have_effect = `have_diff' | `have_delta'
	local have_n     = (`n'     != -1)
	local have_power = (`power' != -1)

	// capture the user's raw delta() input NOW
	local delta_input = `delta'

	if `have_effect' + `have_n' + `have_power' < 2 {
		di as error "at least two of diff()/delta(), n(), and power()/beta() must be specified"
		exit 198
	}
	if `have_effect' & `have_n' & `have_power' {
		di as error "specify at most two of diff()/delta(), n(), and power()/beta() -- the third is what's being solved for"
		exit 198
	}

	if "`select'" == "" local select "above"
	local select = lower("`select'")
	if !inlist("`select'", "above", "below") {
		di as error "select() must be either above or below"
		exit 198
	}
	if `sd' <= 0 {
		di as error "sd() must be positive"
		exit 198
	}
	if `corr' < -1 | `corr' > 1 {
		di as error "corr() must be in [-1,1]"
		exit 198
	}
	if `dropout' < 0 | `dropout' >= 1 {
		di as error "dropout() must be in [0,1)"
		exit 198
	}
	if `have_n' & `n' <= 0 {
		di as error "n() must be positive"
		exit 198
	}
	if `have_power' & (`power' <= 0 | `power' >= 1) {
		di as error "power() must be in (0,1)"
		exit 198
	}

	// sd1 defaults to sd (equal-variance case)
	if `sd1' == -999 local sd1 = `sd'
	if `sd1' <= 0 {
		di as error "sd1() must be positive"
		exit 198
	}

	tempname z lambda RTM sigmaD zalpha zbeta pctRTM Nenroll deltaS RTMcoef tailfactor

	// RTM magnitude
	scalar `z'       = abs(`cutoff' - `mu') / `sd'
	scalar `lambda'  = normalden(`z') / (1 - normal(`z'))
	scalar `RTMcoef' = `sd' - `corr'*`sd1'
	scalar `RTM'     = `RTMcoef' * `lambda'
	if `RTM' < 0 {
		di as txt "Note: RTM is negative given these sd/sd1/corr values --" ///
			" this combination implies the selected group is expected to" ///
			" diverge further from, not regress toward, the population mean."
	}

	// var(D|S)
	scalar `tailfactor' = 1 + `z'*`lambda' - `lambda'^2
	scalar `sigmaD' = sqrt( (`RTMcoef')^2 * `tailfactor' + (`sd1')^2*(1-`corr'^2) )

	if "`onesided'" == "onesided" {
		scalar `zalpha' = invnormal(1 - `alpha')
	}
	else {
		scalar `zalpha' = invnormal(1 - `alpha'/2)
	}

	if `have_effect' {
		if `have_delta' {
			// delta specified directly: this IS the RTM-adjusted effect
			// size (signed -- may be negative, see note below); diff is
			// derived for reporting/display only
			scalar `deltaS' = `delta_input'
			local diff = `delta_input' + `RTM'
		}
		else {
			// diff specified: subtract RTM to get the (signed) effect size
			scalar `deltaS' = `diff' - `RTM'
			if abs(`deltaS') < 1e-8 {
				di as error "diff() equals the change expected from RTM alone (diff - RTM = 0);" ///
					" no effect remains to power"
				exit 498
			}
		}
		if `deltaS' < 0 {
			di as txt "Note: the effect being powered is negative (diff/delta is smaller than" ///
				" what RTM alone predicts) -- this is a genuine, detectable effect OPPOSING" ///
				" the RTM-driven direction, not a design failure. Power below is for detecting" ///
				" |delta| under a two-sided test; specify onesided if only same-direction" ///
				" improvement over RTM is of scientific interest."
		}
	}

	tempname power_out N_out eta

	if `have_effect' & `have_n' {
		// solve for power
		scalar `eta' = sqrt(`n') * `deltaS' / `sigmaD'
		if "`onesided'" == "onesided" {
			// exact for one-sided (single rejection region); unchanged
			scalar `power_out' = normal(`eta' - `zalpha')
		}
		else {
			// exact two-sided normal-test power
			scalar `power_out' = (1 - normal(`zalpha' - `eta')) + normal(-`zalpha' - `eta')
		}
		scalar `N_out' = `n'
	}
	else if `have_effect' & `have_power' {
		// solve for N
		scalar `zbeta' = invnormal(`power')
		scalar `N_out' = ceil( (`sigmaD'^2) * (`zalpha'+`zbeta')^2 / (`deltaS'^2) )
		// report EXACT achieved two-sided power at the rounded integer N
		scalar `eta' = sqrt(`N_out') * `deltaS' / `sigmaD'
		if "`onesided'" == "onesided" {
			scalar `power_out' = normal(`eta' - `zalpha')
		}
		else {
			scalar `power_out' = (1 - normal(`zalpha' - `eta')) + normal(-`zalpha' - `eta')
		}
	}
	else {
		// solve for diff/delta
		scalar `zbeta' = invnormal(`power')
		tempname delta_needed
		scalar `delta_needed' = `sigmaD' * (`zalpha'+`zbeta') / sqrt(`n')
		scalar `deltaS' = `delta_needed'
		local diff = `delta_needed' + `RTM'
		scalar `power_out' = `power'
		scalar `N_out' = `n'
	}

	scalar `pctRTM'  = 100 * `RTM' / `diff'
	scalar `Nenroll' = ceil(`N_out' / (1 - `dropout'))

	// power's common results
	return scalar power = `power_out'
	return scalar N     = `N_out'
	return scalar alpha = `alpha'

	// method-specific inputs/outputs
	return scalar mu      = `mu'
	return scalar sd      = `sd'
	return scalar corr    = `corr'
	return scalar cutoff  = `cutoff'
	return scalar diff    = `diff'
	return scalar sd1     = `sd1'
	return scalar dropout = `dropout'

	// derived quantities
	return scalar z       = `z'
	return scalar lambda  = `lambda'
	return scalar RTM     = `RTM'
	return scalar delta   = `deltaS'
	return scalar sigmaD  = `sigmaD'
	return scalar pctRTM  = `pctRTM'
	return scalar Nenroll = `Nenroll'

	return local select "`select'"
end
