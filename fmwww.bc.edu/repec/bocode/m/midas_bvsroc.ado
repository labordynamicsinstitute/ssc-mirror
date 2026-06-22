*! version 2.1  16jun2026
*! Bivariate SROC plots for diagnostic test accuracy meta-analysis
capture program drop midas_bvsroc

program define midas_bvsroc, rclass byable(recall) sortpreserve
	version 13
	
	syntax [if] [in], [Level(cilevel) Weighted CEllipse PEllipse CRegion ///
		PRegion CONFcolor(string asis) PREDcolor(string asis) ///
		SUMMcolor(string asis) POINTopts(string asis) SUMMopts(string asis) MEan Data LABELdata LGnd LGNPos(integer 6) AREA *]

	// Check that previous estimation was from midas package
	capture assert e(package) == "midas"
	if _rc != 0 {
		di as error "Last estimation command was not a midas subcommand"
		di as error "Please run midas mle, qrsim, mh, hmc, or inla first"
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
		qui svmat varrslist, names(col)
		
		// Check for mutually exclusive options
		if !missing("`pregion'") & !missing("`pellipse'") {
			di as error "pregion and pellipse are mutually exclusive"
			exit 198
		}

		if !missing("`cregion'") & !missing("`cellipse'") {
			di as error "cregion and cellipse are mutually exclusive"
			exit 198
		}

		// Validate level
		if `level' < 10 | `level' > 99 {
			di as error "level() must be between 10 and 99"
			exit 198
		}

		// Generate study ID if labeling requested
		if !missing("`labeldata'") {
			tempvar pid
			gen `pid' = _n
		}
		
		global alph = (100 - `level') / 200
		local numobs = _N

		// Determine confidence interval type based on estimation method
		if e(cmd) == "midas_inla" | e(cmd) == "midas_mh" | e(cmd) == "midas_hmc" {
			local midaconf "(95% CrI)"
		}
		else if e(cmd) == "midas_mle" | e(cmd) == "midas_qrsim" {
			local midaconf "(95% CI)"
		}

		// Calculate study-specific sensitivity with CI
		tempvar sens sensvar sensse senslo senshi
		gen __midas_dis = tp + fn
		midas cii __midas_dis tp, p(`sens') lowerci(`senslo') ///
			upperci(`senshi') cimethod(`cimethod') level(`level')
		gen double `sensse' = (`senshi' - `senslo') / (2 * invnormal(0.975))
		gen double `sensvar' = invnormal(0.975) * `sensse'

		// Calculate study-specific specificity with CI
		tempvar spec specvar specse speclo spechi
		gen __midas_ndis = tn + fp
		midas cii __midas_ndis tn, p(`spec') lowerci(`speclo') ///
			upperci(`spechi') cimethod(`cimethod') level(`level')
		gen double `specse' = (`spechi' - `speclo') / (2 * invnormal(0.975))
		gen double `specvar' = invnormal(0.975) * `specse'

		// Extract covariance parameters
		tempname VV
		mat `VV' = e(V)
		local cov01 = `VV'[1,2]
		local covar = `VV'[3,4]

		// Extract summary sensitivity and specificity
		if e(cmd) == "midas_mle" | e(cmd) == "midas_qrsim" {
			tempname bsroc Vsroc coefmat
			mat `bsroc' = e(bsum)
			mat `Vsroc' = e(Vsum)
			_coef_table, bmatrix(`bsroc') vmatrix(`Vsroc')
			mat `coefmat' = r(table)'
			local mtpr = `coefmat'[1,1]
			local mtprse = `coefmat'[1,2]
			local mtprlo = `coefmat'[1,5]
			local mtprhi = `coefmat'[1,6]
			local mtnr = `coefmat'[2,1]
			local mtnrse = `coefmat'[2,2]
			local mtnrlo = `coefmat'[2,5]
			local mtnrhi = `coefmat'[2,6]
		}
		else if e(cmd) == "midas_inla" | e(cmd) == "midas_mh" | e(cmd) == "midas_hmc" {
			tempvar sen spe
			if e(cmd) == "midas_mh" {
				local _mf = e(midas_filename)
				clear
				qui use "`_mf'", clear
			}
			else {
				mat data = e(midas_sim_data)
				qui svmat data, names(col)
			}
			gen double `sen' = invlogit(logitsen)
			gen double `spe' = invlogit(logitspe)
			midas sumstats `sen' `spe'
			local mtpr = r(mn1)
			local mtprse = r(se1)
			local mtprlo = r(lb1)
			local mtprhi = r(ub1)
			local mtnr = r(mn2)
			local mtnrse = r(se2)
			local mtnrlo = r(lb2)
			local mtnrhi = r(ub2)
		}

		// Extract model parameters
		tempname bcoef Vcoef coef2
		mat `bcoef' = e(b)
		mat `Vcoef' = e(V)
		_coef_table, bmatrix(`bcoef') vmatrix(`Vcoef')
		mat `coef2' = r(table)'
		local sp = `coef2'[2,1]
		local spse = `coef2'[2,2]
		local splo = `coef2'[2,5]
		local sphi = `coef2'[2,6]
		local sn = `coef2'[1,1]
		local snlo = `coef2'[1,5]
		local snhi = `coef2'[1,6]
		local snse = `coef2'[2,2]
		local reffs1 = `coef2'[3,1]
		local reffs1lo = `coef2'[3,5]
		local reffs1hi = `coef2'[3,6]
		local reffs2 = `coef2'[4,1]
		local reffs2lo = `coef2'[4,5]
		local reffs2hi = `coef2'[4,6]

		// Calculate correlation and prediction parameters
		local rhoci = `cov01' / (`snse' * `spse')
		local pred1se = sqrt(`reffs2' + `snse'^2)
		local pred2se = sqrt(`reffs1' + `spse'^2)
		local rhopred = (`covar' + `cov01') / (`pred1se' * `pred2se')
		
		// Generate points for ellipses/regions
		tempvar CPI
		local NP = 1000
		range `CPI' 0 `=2 * c(pi)' `NP'
		local kci = sqrt(2 * invF(2, `numobs' - 2, `level'/100))

		// Initialize legend counter
		local li 1

		// Generate prediction region/ellipse coordinates
		tempvar PB1 PB2 PBsn PBsp
		gen `PB2' = `sp' + `pred2se' * `kci' * cos(`CPI')
		gen `PB1' = `sn' + `pred1se' * `kci' * cos(`CPI' + acos(`rhopred'))
		qui gen `PBsn' = invlogit(`PB1')
		qui gen `PBsp' = invlogit(`PB2')
		
		// Calculate area if requested
		if !missing("`area'") {
			polyarea `PBsp' `PBsn'
			local apr = r(area)
		}

		// Generate confidence region/ellipse coordinates
		tempvar CB1 CB2 CBsens CBspec
		qui gen `CB2' = `sp' + `spse' * `kci' * cos(`CPI')
		qui gen `CB1' = `sn' + `snse' * `kci' * cos(`CPI' + acos(`rhoci'))
		qui gen `CBsens' = invlogit(`CB1')
		qui gen `CBspec' = invlogit(`CB2')
		
		// Calculate area ratio if requested
		if !missing("`area'") {
			polyarea `CBspec' `CBsens'
			local acr = r(area)
			return scalar area_ratio = (`apr' - `acr') / `apr'
			return scalar pred_area = `apr'
			return scalar conf_area = `acr'
		}

		// Build plot components
		
		// Prediction region/ellipse
		if !missing("`pregion'") & missing("`pellipse'") {
			if missing("`predcolor'") {
				local fshade "fcolor(green%30) lcolor(green) nodropbase recast(area)"
			}
			else {
				local fshade "fcolor(`predcolor') lcolor(`predcolor') nodropbase recast(area)"
			}
			local pregion `"(line `PBsn' `PBsp', `fshade')"'
			local legend `"`legend' label(`li' "`level'% Prediction Region")"'
			local order "`order' `li'"
			local ++li
		}
		else if missing("`pregion'") & !missing("`pellipse'") {
			local clpcw2 "clpat(shortdash) clc(green) clw(medium)"
			local pellipse `"(line `PBsn' `PBsp', `clpcw2')"'
			local legend `"`legend' label(`li' "`level'% Prediction Ellipse")"'
			local order "`order' `li'"
			local ++li
		}

		// Confidence region/ellipse
		if !missing("`cregion'") & missing("`cellipse'") {
			if missing("`confcolor'") {
				local hshade "fcolor(blue%30) lcolor(blue) nodropbase recast(area)"
			}
			else {
				local hshade "fcolor(`confcolor') lcolor(`confcolor') nodropbase recast(area)"
			}
			local cregion `"(line `CBsens' `CBspec', `hshade')"'
			local legend `"`legend' label(`li' "`level'% Confidence Region")"'
			local order "`order' `li'"
			local ++li
		}
		else if missing("`cregion'") & !missing("`cellipse'") {
			local clpcw1 "clpat(dot) clc(blue) clw(medium)"
			local cellipse `"(line `CBsens' `CBspec', `clpcw1')"'
			local legend `"`legend' label(`li' "`level'% Confidence Ellipse")"'
			local order "`order' `li'"
			local ++li
		}

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
			local order "`order' `li'"
			local ++li
			if !missing("`labeldata'") {
				local ++li
			}
		}
		else if (!missing("`data'") & missing("`weighted'")) {
			local _ptopts = cond(!missing("`pointopts'"), "`pointopts'", "mlw(medthin) mlc(black) mfc(gs12) msize(*1.5) ms(O)")
			local observed `"(scatter `sens' `spec', sort `_ptopts')"'
			if !missing("`labeldata'") {
				local observed `"`observed' (scatter `sens' `spec', ms(i) mlabp(0) mlabel(`pid') mlabs(*.5) mlabc(black))"'
			}
			local legend `"`legend' label(`li' "Observed data")"'
			local order "`order' `li'"
			local ++li
			if !missing("`labeldata'") {
				local ++li
			}
		}

		// Summary operating point
		if !missing("`mean'") {
			if missing("`summcolor'") {
				local summ "black"
			}
			else {
				local summ "`summcolor'"
			}
			local snnote: di "SENS = " %3.2f `mtpr' " [" %3.2f `mtprlo' " - " %3.2f `mtprhi' "]"
			local spnote: di "SPEC = " %3.2f `mtnr' " [" %3.2f `mtnrlo' " - " %3.2f `mtnrhi' "]"
			local _smopts = cond(!missing("`summopts'"), "`summopts'", "ms(D) msize(*1.4) mcolor(`summ')")
			local summ `"(scatteri `mtpr' `mtnr', `_smopts')"'
			local legend `"`legend' label(`li' "Summary Operating Point" "`snnote'" "`spnote'")"'
			local order "`order' `li'"
			local ++li
			
			// Store summary point
			return scalar summ_sens = `mtpr'
			return scalar summ_spec = `mtnr'
			return scalar summ_sens_lb = `mtprlo'
			return scalar summ_sens_ub = `mtprhi'
			return scalar summ_spec_lb = `mtnrlo'
			return scalar summ_spec_ub = `mtnrhi'
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
		nois twoway `pregion' `pellipse' `cregion' `cellipse' `observed' `summ', 
			`lgnd'
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
	
	// Display summary if mean requested
	if !missing("`mean'") {
		di as text _n "Summary Operating Point"
		di as text "{hline 60}"
		di as text "Sensitivity" _col(30) as result %6.4f `mtpr' _col(45) "`midaconf'" _col(55) "(" %6.4f `mtprlo' ", " %6.4f `mtprhi' ")"
		di as text "Specificity" _col(30) as result %6.4f `mtnr' _col(45) "`midaconf'" _col(55) "(" %6.4f `mtnrlo' ", " %6.4f `mtnrhi' ")"
		di as text "{hline 60}"
	}
	
	if !missing("`area'") {
		* Compute indices
		local aratio = (`apr' - `acr')/`apr'
		local overlap_coef = `acr' / `apr'
		local hai = `apr' - `acr'
		local lar = ln(`apr' / `acr')
		local cohen_d = 2 * (sqrt(`apr') - sqrt(`acr')) / (sqrt(`apr') + sqrt(`acr'))
		
		di as text _n "Region Areas and Heterogeneity Indices"
		di as text "{hline 66}"
		di as text "Prediction region area (APR)" _col(42) as result %10.6f `apr'
		di as text "Confidence region area (ACR)" _col(42) as result %10.6f `acr'
		di as text "{hline 66}"
		di as text "Overlap Coefficient (ACR/APR)" _col(42) as result %10.4f `overlap_coef'
		di as text "  " as text "{it:(1 = identical regions; smaller = more heterogeneity)}"
		di as text "Heterogeneity Area Index (APR-ACR)" _col(42) as result %10.6f `hai'
		di as text "  " as text "{it:(absolute excess area due to between-study variability)}"
		di as text "Log Area Ratio  ln(APR/ACR)" _col(42) as result %10.4f `lar'
		di as text "  " as text "{it:(0 = no excess heterogeneity; larger = more spread)}"
		di as text "Standardized Area Difference" _col(42) as result %10.4f `cohen_d'
		di as text "  " as text "{it:(Cohen's d analog on sqrt-area scale)}"
		di as text "{hline 66}"
		di as text ""
		
		* Traffic-light interpretation based on LAR
		if `lar' > 2.5 {
			di as text "  Assessment: {err:HIGH} heterogeneity (LAR > 2.5)"
			di as text "  Prediction region is " as result %3.1f exp(`lar') ///
				as text "x larger than confidence region."
			di as text "  The summary point may not represent individual settings well."
		}
		else if `lar' > 1.5 {
			di as text "  Assessment: {result:MODERATE} heterogeneity (1.5 < LAR < 2.5)"
			di as text "  Prediction region is " as result %3.1f exp(`lar') ///
				as text "x larger than confidence region."
			di as text "  Consider subgroup or meta-regression analysis."
		}
		else {
			di as text "  Assessment: {txt:LOW} heterogeneity (LAR < 1.5)"
			di as text "  Prediction region is " as result %3.1f exp(`lar') ///
				as text "x larger than confidence region."
			di as text "  Summary point is a reliable representation of test accuracy."
		}
		di as text "{hline 66}"
		
		return scalar pred_area      = `apr'
		return scalar conf_area      = `acr'
		return scalar overlap_coef   = `overlap_coef'
		return scalar het_area_index = `hai'
		return scalar log_area_ratio = `lar'
		return scalar std_area_diff  = `cohen_d'
		return scalar area_ratio     = `aratio'
	}
end

// Helper program to calculate polygon area
capture program drop polyarea
program polyarea, rclass
	version 8
	syntax varlist(min=2 max=2 numeric) [in]

	tokenize `varlist'
	args x y

	marksample touse, novarlist
	qui count if `touse' & (missing(`x') | missing(`y'))
	if r(N) {
		di as err "missing values in data"
		exit 198
	}

	tempvar order area
	preserve
	gen long `order' = _n
	su `order' if `touse', meanonly

	qui gen `area' = `touse' * ///
		(`x'[_n + 1] - `x') * (`y'[_n + 1] + `y') / 2
	qui replace `area' = ///
		(`x'[`r(min)'] - `x') * (`y'[`r(min)'] + `y') / 2 in `r(max)'
	su `area', meanonly

	return scalar area = abs(r(sum))
	restore
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

