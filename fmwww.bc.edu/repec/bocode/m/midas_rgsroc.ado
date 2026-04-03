*! version 2.0  28nov2025
*! Regression-based SROC plots for diagnostic test accuracy meta-analysis
capture program drop midas_rgsroc

program define midas_rgsroc, rclass byable(recall) sortpreserve
	version 16
	
	syntax [if] [in], [Level(cilevel) Weighted Data CBounds CRegion ///
		PBounds PRegion CRColor(string asis) PRColor(string asis) ///
		LABELdata LGnd LGNPos(integer 6) CURVEopts(string asis) POINTopts(string asis) *]

	// Check that previous estimation was from midas package
	capture assert e(package) == "midas"
	if _rc != 0 {
		di as error "Last estimation command was not a midas subcommand"
		di as error "Please run midas mle, qrsim, mh, hmc, or inla first"
		error 301
	}
	
	// Check required estimation results exist
	capture confirm matrix e(bhsroc)
	if _rc != 0 {
		di as error "Required SROC estimation results not found"
		di as error "Please run a midas estimation command that produces SROC results"
		error 301
	}
	
	qui {
		preserve
		clear
		mat varrslist = e(varlist)
		
		// Normalize column names — may be tempvar names after bayesparallel
		local nc = colsof(varrslist)
		if `nc' >= 4 {
			mat colnames varrslist = tp fp fn tn
		}
		svmat varrslist, names(col)
	}

	qui count
	local NN = r(N)

	// Validate mutually exclusive options
	if !missing("`pbounds'") & !missing("`pregion'") {
		di as error "pbounds and pregion are mutually exclusive"
		exit 198
	}

	if !missing("`cbounds'") & !missing("`cregion'") {
		di as error "cbounds and cregion are mutually exclusive"
		exit 198
	}

	// Validate level
	if `level' < 10 | `level' > 99 {
		di as error "level() must be between 10 and 99"
		exit 198
	}

	qui {
		// Generate study ID if labeling requested
		if !missing("`labeldata'") {
			tempvar pid
			gen `pid' = _n
		}
		
		global alph = (100 - `level') / 200

		// Calculate study-specific sensitivity and specificity
		tempvar sens spec FPR          
		gen double `sens' = tp / (tp + fn)  
		gen double `spec' = tn / (tn + fp)      

		tempname bsroc Vsroc

		// Extract model-based SROC parameters
		tempname bhsroc Vhsroc hsrocmat
		mat `bhsroc' = e(bhsroc)
		mat `Vhsroc' = e(Vhsroc)
		_coef_table, bmatrix(`bhsroc') vmatrix(`Vhsroc')
		mat `hsrocmat' = r(table)'
		
		local mbeta = `hsrocmat'[3,1]
		local malpha = `hsrocmat'[1,1]
		local mbetalo = `hsrocmat'[3,5]  
		local malphalo = `hsrocmat'[1,5]
		local mbetahi = `hsrocmat'[3,6]
		local malphahi = `hsrocmat'[1,6]
		
		// Calculate prediction bounds
		local t = invttail(e(N) - 2, 0.5 - `level'/200)
		local malphapredlo = `malpha' - `t' * sqrt(`hsrocmat'[1,2]^2 + `bhsroc'[1,4])
		local malphapredhi = `malpha' + `t' * sqrt(`hsrocmat'[1,2]^2 + `bhsroc'[1,4])

		// Initialize legend counter
		local li 1

		// Generate SROC curves
		local NP = 10000
		tempvar x curve curvelo curvehi pcurvehi pcurvelo
		qui range `x' 0 1 `NP'

		// Main SROC curve
		qui gen double `curve' = ///
			invlogit(`malpha' * (exp(-0.5 * `mbeta')) - exp(-`mbeta') * (logit(`x')))
		
		// Confidence bounds
		qui gen double `curvelo' = ///
			invlogit(`malphalo' * (exp(-0.5 * `mbeta')) - exp(-`mbeta') * (logit(`x')))
		qui gen double `curvehi' = ///
			invlogit(`malphahi' * (exp(-0.5 * `mbeta')) - exp(-`mbeta') * (logit(`x')))
		
		// Prediction bounds
		qui gen double `pcurvelo' = ///
			invlogit(`malphapredlo' * (exp(-0.5 * `mbeta')) - exp(-`mbeta') * (logit(`x')))
		qui gen double `pcurvehi' = ///
			invlogit(`malphapredhi' * (exp(-0.5 * `mbeta')) - exp(-`mbeta') * (logit(`x')))
		
		// Fix boundary values
		foreach var in curvelo curvehi pcurvelo pcurvehi {
			qui replace ``var'' = 0 if `x' == 1
			qui replace ``var'' = 1 if `x' == 0
		}

		// Calculate AUC (Area Under the Curve)
		qui integ `curve' `x'
		local AUC = r(integral)
		return scalar AUC = `AUC'
		
		qui integ `curvelo' `x'
		local AUClo = r(integral)
		return scalar AUClo = `AUClo'
		
		qui integ `curvehi' `x'
		local AUChi = r(integral)
		return scalar AUChi = `AUChi'

		local note: di "AUC = " %3.2f `AUC' " [" %3.2f `AUClo' "-" %3.2f `AUChi' "]"

		// Build plot components based on options
		
		// Prediction bounds/region
		if !missing("`pbounds'") {
			local spbounds `"(rline `pcurvehi' `pcurvelo' `x', sort lpattern(longdash) lcolor(green) lwidth(medium))"'
			local pnote: di "SROC prediction bounds"
			local legend `"`legend' label(`li' "`pnote'")"'
			local order "`order' `li++'"
		}
		else if !missing("`pregion'") {
			if !missing("`prcolor'") {
				local spbounds `"(rarea `pcurvehi' `pcurvelo' `x', sort lpattern(solid) fcolor(`prcolor') lcolor(`prcolor') lwidth(medium))"'
			}
			else {
				local spbounds `"(rarea `pcurvehi' `pcurvelo' `x', sort lpattern(solid) fcolor(green%30) lcolor(green) lwidth(medium))"'
			}
			local pnote: di "SROC prediction region"
			local legend `"`legend' label(`li' "`pnote'")"'
			local order "`order' `li++'"
		}

		// Confidence bounds/region
		if !missing("`cbounds'") {
			local scbounds `"(rline `curvehi' `curvelo' `x', sort lpattern(longdash) lcolor(blue) lwidth(medium))"'
			local cnote: di "SROC confidence bounds"
			local legend `"`legend' label(`li' "`cnote'")"'
			local order "`order' `li++'"
		}
		else if !missing("`cregion'") {
			if !missing("`crcolor'") {
				local scbounds `"(rarea `curvehi' `curvelo' `x', sort lpattern(solid) fcolor(`crcolor') lcolor(`crcolor') lwidth(medium))"'
			}
			else {
				local scbounds `"(rarea `curvehi' `curvelo' `x', sort lpattern(solid) fcolor(blue%30) lcolor(blue) lwidth(medium))"'
			}
			local cnote: di "SROC confidence region"
			local legend `"`legend' label(`li' "`cnote'")"'
			local order "`order' `li++'"
		}
		
		// Main SROC curve (always shown)
		local _copts = cond(!missing("`curveopts'"), "`curveopts'", "lpat(solid) lc(black) lwidth(thick)")
		local scurve `"(line `curve' `x', `_copts')"'
		local snote: di "SROC curve"
		local legend `"`legend' label(`li' "`snote'" "`note'")"'
		local order "`order' `li++'"

		// Observed data points
		if (!missing("`data'") & !missing("`weighted'")) {
			tempvar wgted _senwgt _spewgt
			_midas_getwgts, senwgt(`_senwgt') spewgt(`_spewgt') bivwgt(`wgted')
			local _ptopts = cond(!missing("`pointopts'"), "`pointopts'", "mlw(medthin) mlc(black) mfc(gs12) msize(*1.0) ms(O)")
			local observed `"(scatter `sens' `spec' [aw=`wgted'], sort `_ptopts')"'
			if !missing("`labeldata'") {
				local observed `"`observed' (scatter `sens' `spec', ms(i) mlabp(0) mlabel(`pid') mlabs(*.5) mlabc(black))"'
			}
			local legend `"`legend' label(`li' "Weighted observed data")"'
			local order "`order' `li++'"
		}
		else if (!missing("`data'") & missing("`weighted'")) {
			local _ptopts = cond(!missing("`pointopts'"), "`pointopts'", "mlw(medthin) mlc(black) mfc(gs12) msize(*1.5) ms(O)")
			local observed `"(scatter `sens' `spec', sort `_ptopts')"'
			if !missing("`labeldata'") {
				local observed `"`observed' (scatter `sens' `spec', ms(i) mlabp(0) mlabel(`pid') mlabs(*.5) mlabc(black))"'
			}
			local legend `"`legend' label(`li' "Observed data")"'
			local order "`order' `li++'"
		}

		// Configure legend
		if !missing("`lgnd'") {
			local lgnd `"legend(order(`order') pos(`lgnpos') row(2) size(*.50) symxsize(4) forcesize rowgap(1) region(lcolor(black)) `legend')"'
		}
		else {
			local lgnd "legend(off)"
		}

		// Create the plot
		#delimit;
		nois twoway `spbounds' `scbounds' `scurve' `observed', `lgnd'
			xsc(reverse) ysc(range(0 1))  
			xla(0(0.1)1, nogrid format(%3.1f))
			yla(0(0.1)1, nogrid angle(horizontal) format(%3.1f)) 
			xti("Specificity") yti("Sensitivity")  
			aspect(1) 
			graphregion(margin(medium))
			`options';
		#delimit cr
		
		restore
	}
	
	// Display AUC results
	di as text _n "Summary ROC Analysis"
	di as text "{hline 50}"
	di as text "AUC" _col(30) as result %6.4f `AUC'
	di as text "`level'% Confidence Interval" _col(30) as result "(" %6.4f `AUClo' ", " %6.4f `AUChi' ")"
	di as text "{hline 50}"
end

// Standardized weight extraction from e(studywgts)
capture program drop _midas_getwgts
program define _midas_getwgts
    version 16
    syntax, SENwgt(string) SPEwgt(string) BIVwgt(string)
    capture confirm matrix e(studywgts)
    if _rc {
        qui gen double `senwgt' = 100 / _N
        qui gen double `spewgt' = 100 / _N
        qui gen double `bivwgt' = 100 / _N
        exit
    }
    tempname wgtmat
    mat `wgtmat' = e(studywgts)
    local ncol = colsof(`wgtmat')
    local nrow = rowsof(`wgtmat')
    if `ncol' < 3 {
        qui gen double `senwgt' = 100 / _N
        qui gen double `spewgt' = 100 / _N
        qui gen double `bivwgt' = 100 / _N
        exit
    }
    qui gen double `senwgt' = .
    qui gen double `spewgt' = .
    qui gen double `bivwgt' = .
    local maxrow = min(`nrow', _N)
    forvalues i = 1/`maxrow' {
        qui replace `senwgt' = `wgtmat'[`i', 1] in `i'
        qui replace `spewgt' = `wgtmat'[`i', 2] in `i'
        qui replace `bivwgt' = `wgtmat'[`i', 3] in `i'
    }
end

