*! emc package v. 0.1.3
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*  2020-01-29	v0.1.2	In production
*  2019-11-14	v0.1.0	Created
/*
cls
capture drop _*
capture program drop rcspc
capture mata mata drop rcspc_splines()
capture mata mata drop rcspc_pct_knots()
capture mata mata drop rcspc_is_zero_one()
*/
* TODO: Add knots as option - for comparing splines from different datasets
* TODO: Add fp options and possibly fp estimation
program define rcspc, rclass	// restricted cubic spline curve
	version 12

	if `c(version)' >= 13 set prefix rcspc

	sreturn clear
	_prefix_clear

	capture _on_colon_parse `0'
	
	local 0 `s(before)'
	syntax , /*
		*/at(numlist min=1 sort) /*
		*/REFerence(numlist max=1) /* 
		*/[ /*
			*/Pctknots(numlist min=3 max=10 >0 <100 sort) /*
			*/Nknots(integer 4) /*
			*/Keepcubicsplines /*
			*/INCludereference /*
			*/Eform /*
			*/rcspcnames(namelist min=4 max=4) /*
			*/CIlimits(numlist max=1 >50 <100) /*
			*/GRaph /*
			*/ *	/* Twoway graph options
		*/]
	
	mata: rcspc_pct_knots("`pctknots'", "`nknots'")
	if "`cilimits'" == "" local cilimits 95
	local graph_opt `options'
	
	_prefix_command rcspc: `s(after)'

	local ifinwgt `"`r(if)' `r(in)' `r(wgt)'"'
	local cmd `s(cmdname)'
	local opt `s(options)'
	local 0 `s(anything)'
	if inlist("`cmd'", "stcox") {
		syntax varlist(min=1 numeric fv)
		tokenize "`varlist'"
		local outcome ""
		local exposure `1'
		local adjustments = subinstr("`varlist'", "`1'", "",.)
	}
	else {
		syntax varlist(min=2 numeric fv)
		tokenize "`varlist'"
		if inlist("`cmd'", "logit", "logistic", "clogit") mata: rcspc_is_zero_one("`1'")
		local outcome `1'
		local exposure `2'
		local adjustments = subinstr("`varlist'", "`1' `2'", "",.)
	}

	local command `cmd' `outcome' __`exposure'? `adjustments' `ifinwgt', `opt'
	
	
	****************************************************************************
	*** Calculations ***********************************************************
	****************************************************************************
	
	mata: rcspc_splines( ///
		`"`command'"', ///
		"`exposure'", ///
		"`pctknots'", ///
		"`at'", ///
		`reference', ///
		"`includereference'" != "", ///
		"`rcspcnames'", ///
		"`keepcubicsplines'" != "", ///
		"`eform'" != "", ///
		`cilimits' ///
		)

	return add
	

	****************************************************************************
	*** Graph and data *********************************************************
	****************************************************************************
	tokenize `rcspcnames'
	if ( "`graph_opt'" != "" | "`graph'" != "" ) {
		local xtitle "`:variable label `exposure''"
		if "`eform'" != "" local ytitle "Exponentiated contrast and 95% CI"
		else local ytitle "Contrast and 95% CI"
		if "`xtitle'" == "" local xtitle "`exposure'"
		_get_gropts , graphopts(`graph_opt') gettwoway
		local gr_cmd `"twoway (line `4' `3' `2' `1', lcolor(black black black) lpattern(- - solid)), legend(off) xtitle(`"`xtitle'"') ytitle(`"`ytitle'"') `s(twowayopts)'"'
		`gr_cmd'
		return local graph_cmd `"`gr_cmd'"'
	}
end


********************************************************************************
*** MATA ***********************************************************************
********************************************************************************
mata:
	//mata set matastrict on
	//mata set matalnum on

	void rcspc_pct_knots(string scalar pctknots, string scalar nknots)
	{
		real scalar nk
		string vector nknots_conversion
	
		if ( pctknots == "" ) {
			if ( (nk = strtoreal(nknots) - 2) < 6 ) {
				nknots_conversion =	"10 50 90",
									"5 35 65 95",
									"5 27.5 50 72.5 95",
									"5 23 41 59 77 95",
									"2.5 `=18+1/3' `=34+1/6' 50 `=65+5/6' `=81+2/3' 97.5"
				st_local("pctknots", nknots_conversion[nk])
			} else {
				_error("nknots must be an integer between 3 and 7")
			}
		}
	}
	
	void rcspc_splines(
		string scalar stata_command,
		string scalar exposure,
		string scalar pctknots,
		string scalar str_at_values,
		real scalar reference,
		real scalar includereference,
		string scalar rcspcnames,
		real scalar keepcubicsplines,
		real scalar eform,
		real scalar cilimits
		)
	{
		real scalar rc, C
		real rowvector slct
		real colvector v_exposure, v_pctknots, betas, at_values
		real matrix knots, cubic, regressors, covariance, pr_ci
		string rowvector names
		class nhb_mc_splines scalar sp
		class nhb_mt_labelmatrix scalar lblm

		v_exposure = st_data(., exposure)
		v_pctknots = strtoreal(tokens(pctknots))'
		at_values = strtoreal(tokens(str_at_values))'

		knots = nhb_mc_percentiles(v_exposure, v_pctknots)
		sp.add_knots(knots[.,2]')
		if ( includereference ) at_values = uniqrows(sort(at_values \ reference, 1))
		regressors = sp.restricted_cubic(at_values) :- sp.restricted_cubic(reference)
		cubic = sp.restricted_cubic(v_exposure)
		C = cols(cubic)
		names = exposure :+ strofreal((1..C))
		nhb_sae_addvars("__" :+ names, cubic)

		st_eclear()
		rc = nhb_sae_logstatacode(stata_command, /*showcode*/0, /*addquietly*/1)
		betas = st_matrix("e(b)")'
		covariance = st_matrix("e(V)")
		st_rclear()

		st_global("r(command)", stata_command)
	
		lblm.values(knots[.,2])
		lblm.row_equations(exposure)
		lblm.row_names(knots[., 1])
		lblm.column_names("knots")
		lblm.to_matrix("r(knots)")

		lblm.clear()
		lblm.values(regressors)
		lblm.column_names(names')
		lblm.row_equations(exposure)
		lblm.to_matrix("r(regressors)")
		if ( !rc ) {
			if ( !keepcubicsplines ) st_dropvar(tokens(nhb_msa_unab(sprintf("__%s*", exposure))))
			slct = 1::(cols(regressors))
			pr_ci = nhb_mc_predictions(regressors, betas[slct], covariance[slct, slct], cilimits / 200 + 0.5)
			if ( eform ) pr_ci = exp(pr_ci)

			lblm.clear()
			lblm.values(pr_ci)
			lblm.column_equations(("", sprintf("%2.0f%% CI", cilimits))')
			lblm.row_names(strofreal(at_values))
			lblm.column_names(("Contrast", "Lower CI", "Upper CI")')
			lblm.to_matrix("r(predictions)")
			lblm.print("", 3)
			
			if ( rcspcnames != "" ) names = tokens(rcspcnames)
			else names = ("__" + exposure) :+ ("", "_contrast", "_lb", "_ub") 
			nhb_sae_addvars(names, (at_values, pr_ci))
			st_global("r(rcspcnames)", invtokens(names))
			st_local("rcspcnames", invtokens(names))	// format estimated variables
		}
	}
end
