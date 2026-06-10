*! 1.0.0 Ariel Linden 02Jun2026
//  prediction program for -xtpraisk-: supports xb, residuals, stdp, and ue (AR innovation residuals)

program define xtpraisk_p
	version 14

	local myopts "XB Residuals UE STDp"

	_pred_se "`myopts'" `0'
	if `s(done)' exit
	local vtyp  `s(typ)'
	local varn  `s(varn)'
	local 0     `"`s(rest)'"'

	syntax [if] [in] [, `myopts']

	// count options; default to xb
	local nopt = ("`xb'"!="") + ("`residuals'"!="") + ///
	             ("`ue'"!="") + ("`stdp'"!="")
	if `nopt' == 0 local xb "xb"
	if `nopt' > 1 {
		di as err "only one predict option may be specified"
		exit 198
	}

	// sample marker
	marksample touse, novarlist

	// xb: fitted values x'b
	if "`xb'" != "" {
		_predict `vtyp' `varn' if `touse', xb
		label variable `varn' "Fitted values"
		exit
	}

	// stdp: SE of linear prediction
	if "`stdp'" != "" {
		_predict `vtyp' `varn' if `touse', stdp
		label variable `varn' "S.E. of linear prediction"
		exit
	}

	// residuals: u = y - x'b
	if "`residuals'" != "" {
		local yvar "`e(depvar)'"
		tempvar xbhat
		quietly _predict double `xbhat' if `touse', xb
		generate `vtyp' `varn' = `yvar' - `xbhat' if `touse'
		label variable `varn' "Residuals"
		exit
	}

	// ue: AR innovation residuals
	// requires panel tsset so that L. operator respects panel boundaries
	if "`ue'" != "" {
		local yvar    "`e(depvar)'"
		local panelvar "`e(panelvar)'"
		local timevar  "`e(timevar)'"
		if "`timevar'" == "" {
			di as err "ue requires tsset time variable"
			exit 198
		}

		// ensure data are sorted correctly for lag operator
		quietly tsset `panelvar' `timevar'

		// AR order
		if !missing(e(p_lag)) local p_lag = e(p_lag)
		else                  local p_lag = colsof(e(rho))

		tempvar xbhat u
		quietly _predict double `xbhat' if `touse', xb
		quietly generate double `u' = `yvar' - `xbhat' if `touse'

		// start with u, subtract rho_j * L^j.u for each lag
		generate `vtyp' `varn' = `u' if `touse'
		forvalues j = 1/`p_lag' {
			local rhoj = el(e(rho), 1, `j')
			quietly replace `varn' = `varn' - `rhoj' * L`j'.`u' ///
				if `touse' & !missing(L`j'.`u')
		}
		// set missing where any required lag is unavailable
		// (first p obs of each panel, and any within-panel gap boundaries)
		forvalues j = 1/`p_lag' {
			quietly replace `varn' = . if `touse' & missing(L`j'.`u')
		}

		label variable `varn' "AR(`p_lag') innovation residuals"
		exit
	}
end
