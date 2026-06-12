*! 1.0.0 Ariel Linden 10Jun2026

program define poissark_p
	version 14

	// claim xb, n, ir as ours so _pred_se doesn't intercept xb
	local myopts "N IR XB"

	_pred_se "`myopts'" `0'
	if `s(done)' {
		// stdp, cooksd, hat, etc. handled by _pred_se
		exit
	}
	local vtyp `s(typ)'
	local varn `s(varn)'
	local 0    `"`s(rest)'"'

	syntax [if] [in] [, `myopts' noOFFset]

	marksample touse, novarlist

	// retrieve offset/exposure variable names stored by poissark
	local offvar "`e(offset_var)'"
	local expvar "`e(exposure)'"

	// raw linear prediction (no offset)
	tempvar xbraw
	quietly _predict double `xbraw' if `touse', xb

	// count specified options
	local nopt = ("`n'"!="") + ("`ir'"!="") + ("`xb'"!="")
	if `nopt' > 1 {
		di as err "only one statistic may be specified"
		exit 198
	}

	// default is n
	if `nopt' == 0 {
		di in smcl in gr ///
			"(option {bf:n} assumed; predicted number of events)"
		local n "n"
	}

	// ----------------------------------------------------------------
	// xb: linear prediction
	//   xb + offset       if offset() and no nooffset
	//   xb + ln(exposure) if exposure() and no nooffset
	//   xb                if neither, or nooffset
	// ----------------------------------------------------------------
	if "`xb'" != "" {
		if "`nooffset'" != "" | ("`offvar'" == "" & "`expvar'" == "") {
			generate `vtyp' `varn' = `xbraw' if `touse'
			label var `varn' "Linear prediction"
		}
		else if "`expvar'" != "" {
			generate `vtyp' `varn' = `xbraw' + log(`expvar') if `touse'
			label var `varn' "Linear prediction"
		}
		else {
			generate `vtyp' `varn' = `xbraw' + `offvar' if `touse'
			label var `varn' "Linear prediction"
		}
		exit
	}

	// ----------------------------------------------------------------
	// n: predicted number of events
	//   exp(xb + offset)    if offset()
	//   exp(xb) * exposure  if exposure()
	//   exp(xb)             if neither
	//   exp(xb)             if nooffset
	// ----------------------------------------------------------------
	if "`n'" != "" {
		if "`nooffset'" != "" | ("`offvar'" == "" & "`expvar'" == "") {
			generate `vtyp' `varn' = exp(`xbraw') if `touse'
		}
		else if "`expvar'" != "" {
			generate `vtyp' `varn' = exp(`xbraw') * `expvar' if `touse'
		}
		else {
			generate `vtyp' `varn' = exp(`xbraw' + `offvar') if `touse'
		}
		label var `varn' "Predicted number of events"
		exit
	}

	// ----------------------------------------------------------------
	// ir: incidence rate = exp(xb), always ignores offset/exposure
	// ----------------------------------------------------------------
	if "`ir'" != "" {
		generate `vtyp' `varn' = exp(`xbraw') if `touse'
		label var `varn' "Predicted incidence rate"
		exit
	}

	error 198
end
