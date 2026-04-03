*! midas_hsruc v1.0.0 — Hierarchical Summary Relative Utility Curve Analysis
*! Derives clinical utility metrics from bivariate DTA meta-analysis estimates
*! Requires: prior execution of midas mle, midas mh, midas hmc, or midas inla
*!
*! Author: Ben Adarkwa Dwamena, MD
*! University of Michigan / BennyBeauBooks Publishers
*! Date: March 2026
*!
*! References:
*!   Reitsma JB et al. (2005). JCEM 26:982-989.
*!   Rutter CM, Gatsonis CA (2001). Stat Med 20:2865-2884.
*!   Vickers AJ, Elkin EB (2006). Med Decis Making 26:565-574.
*!   Baker SG et al. (2009). Med Decis Making 29:247-256.
*!   Katki HA (2019). Stat Med 38:2943-2955.
*!   Katki HA, Bebu I (2021). JRSS-A 184:887-903.

capture program drop midas_hsruc
program define midas_hsruc, eclass
	version 16.0

	syntax [, PREValence(real -1) ///
		THResholds(numlist >0 <1 ascending) ///
		NPoints(integer 99) ///
		MRS NBGain INB ALLmetrics ///
		SCREENcost(real 0) TREATcost(real 0) LYG(real 1) ///
		OPTimal ///
		PREDiction ///
		Level(cilevel) ///
		noGRAPH SAVing(string) ///
		NOTable ]

	* ======================================================================
	* CHECK PRIOR ESTIMATION
	* ======================================================================
	
	capture confirm scalar e(N)
	if _rc {
		di as error "No estimation results found."
		di as error "Run a MIDAS estimation command first (midas mle, midas mh, midas hmc, or midas inla)"
		exit 301
	}

	local nstudies = e(N)
	
	* ======================================================================
	* EXTRACT PARAMETERS — scan column names in e(b) and e(bsum)
	* ======================================================================

	local Se  = .
	local Sp  = .
	local DOR = .
	local LRp = .
	local LRn = .
	local mu1 = .
	local mu2 = .
	local tau1sq = .
	local tau2sq = .
	local covar  = .
	local rho = 0

	* --- Extract from e(b): logitsen, logitspe, varlogitsen, varlogitspe, corrlogits ---
	capture matrix _hsruc_b = e(b)
	if _rc == 0 {
		local bnames : colnames _hsruc_b
		local ncb = colsof(_hsruc_b)
		forvalues j = 1/`ncb' {
			local cname : word `j' of `bnames'
			if "`cname'" == "logitsen"    local mu1    = _hsruc_b[1,`j']
			if "`cname'" == "logitspe"    local mu2    = _hsruc_b[1,`j']
			if "`cname'" == "varlogitsen" local tau1sq = _hsruc_b[1,`j']
			if "`cname'" == "varlogitspe" local tau2sq = _hsruc_b[1,`j']
			if "`cname'" == "covlogits"   local covar  = _hsruc_b[1,`j']
			if "`cname'" == "corrlogits"  local rho    = _hsruc_b[1,`j']
			if "`cname'" == "covvars"     local covar  = _hsruc_b[1,`j']
			if "`cname'" == "corrvars"    local rho    = _hsruc_b[1,`j']
		}
		matrix drop _hsruc_b
	}

	* --- Extract from e(bsum): Sens, Spec, DOR, LRP, LRN ---
	capture matrix _hsruc_s = e(bsum)
	if _rc == 0 {
		local snames : colnames _hsruc_s
		local ncs = colsof(_hsruc_s)
		forvalues j = 1/`ncs' {
			local cname : word `j' of `snames'
			if "`cname'" == "Sens"        local Se  = _hsruc_s[1,`j']
			if "`cname'" == "Se"          local Se  = _hsruc_s[1,`j']
			if "`cname'" == "Sensitivity" local Se  = _hsruc_s[1,`j']
			if "`cname'" == "Spec"        local Sp  = _hsruc_s[1,`j']
			if "`cname'" == "Sp"          local Sp  = _hsruc_s[1,`j']
			if "`cname'" == "Specificity" local Sp  = _hsruc_s[1,`j']
			if "`cname'" == "DOR"         local DOR = _hsruc_s[1,`j']
			if "`cname'" == "LRP"         local LRp = _hsruc_s[1,`j']
			if "`cname'" == "LRN"         local LRn = _hsruc_s[1,`j']
		}
		matrix drop _hsruc_s
	}

	* --- Fallback: try e() scalars ---
	if `Se' == .  capture local Se  = e(Se)
	if `Sp' == .  capture local Sp  = e(Sp)
	if `DOR' == . capture local DOR = e(DOR)
	if `LRp' == . capture local LRp = e(LRp)
	if `LRn' == . capture local LRn = e(LRn)

	* --- Fallback: derive from logits ---
	if `Se' == . & `mu1' != . {
		local Se = invlogit(`mu1')
	}
	if `Sp' == . & `mu2' != . {
		local Sp = invlogit(`mu2')
	}
	if `LRp' == . & `Se' != . & `Sp' != . & `Sp' < 1 {
		local LRp = `Se' / (1 - `Sp')
	}
	if `LRn' == . & `Se' != . & `Sp' != . & `Sp' > 0 {
		local LRn = (1 - `Se') / `Sp'
	}
	if `DOR' == . & `LRp' != . & `LRn' != . & `LRn' > 0 {
		local DOR = `LRp' / `LRn'
	}

	* --- Validate ---
	if `Se' == . | `Sp' == . {
		di as error "Could not extract Se and Sp from estimation results."
		di as error "Run:  matrix list e(bsum)   and:  matrix list e(b)"
		di as error "and report the column names."
		exit 301
	}
	if `mu1' == . | `mu2' == . {
		di as error "Could not extract logit parameters (mu1, mu2) from e(b)."
		di as error "Run:  matrix list e(b)   and report column names."
		exit 301
	}

	local tau1 = sqrt(max(`tau1sq', 0))
	local tau2 = sqrt(max(`tau2sq', 0))

	* ======================================================================
	* PREVALENCE
	* ======================================================================

	if `prevalence' < 0 {
		capture local prevalence = e(prev)
		if _rc | `prevalence' <= 0 | `prevalence' >= 1 {
			di as error "prevalence() required: specify a value between 0 and 1"
			exit 198
		}
	}
	if `prevalence' <= 0 | `prevalence' >= 1 {
		di as error "prevalence() must be between 0 and 1"
		exit 198
	}

	* ======================================================================
	* THRESHOLD GRID
	* ======================================================================

	if "`thresholds'" == "" {
		local thresholds ""
		forvalues i = 1/`npoints' {
			local pt = `i' / (`npoints' + 1)
			local thresholds "`thresholds' `pt'"
		}
	}
	local npt : word count `thresholds'

	if "`allmetrics'" != "" {
		local mrs     "mrs"
		local nbgain  "nbgain"
		local inb     "inb"
		local optimal "optimal"
	}

	* ======================================================================
	* HSROC TRANSFORMATION
	* ======================================================================

	local alpha = `mu1' + `mu2'
	local theta = `mu1' - `mu2'
	local beta  = (`tau1sq' - `tau2sq') / (`tau1sq' + `tau2sq' + 0.0001)
	local s2alpha = `tau1sq' + `tau2sq' + 2*`rho'*`tau1'*`tau2'
	local s2theta = `tau1sq' + `tau2sq' - 2*`rho'*`tau1'*`tau2'

	* ======================================================================
	* HEADER
	* ======================================================================

	di _n as text "{hline 78}"
	di as text "HSRUC: Hierarchical Summary Relative Utility Curve Analysis v1.0"
	di as text "{hline 78}"
	di as text "  Studies:        " as result `nstudies'
	di as text "  Prevalence:     " as result %6.4f `prevalence'
	di as text "  Summary Se:     " as result %6.4f `Se'
	di as text "  Summary Sp:     " as result %6.4f `Sp'
	di as text "  Summary LR+:    " as result %6.2f `LRp'
	di as text "  Summary LR-:    " as result %6.4f `LRn'
	di as text "  Summary DOR:    " as result %6.2f `DOR'
	di as text "{hline 78}"
	di as text "  HSROC alpha:    " as result %6.4f `alpha' ///
		as text "  (accuracy = log DOR)"
	di as text "  HSROC theta:    " as result %6.4f `theta' ///
		as text "  (threshold)"
	di as text "  HSROC beta:     " as result %6.4f `beta' ///
		as text "  (asymmetry)"
	di as text "  s2(alpha):      " as result %6.4f `s2alpha'
	di as text "  s2(theta):      " as result %6.4f `s2theta'
	di as text "{hline 78}"

	* ======================================================================
	* COMPUTE UTILITY METRICS
	* ======================================================================

	preserve
	clear
	qui set obs `npt'

	qui gen double pt      = .
	qui gen double w       = .
	qui gen double nb      = .
	qui gen double nb_all  = .
	qui gen double ru      = .
	qui gen double snb     = .
	qui gen double nbgain_v = .
	qui gen double nnt     = .
	qui gen double mrs_v   = .
	qui gen double inb_v   = .
	qui gen double se_pt   = .
	qui gen double sp_pt   = .

	local pi = `prevalence'
	local i = 0
	foreach pval of numlist `thresholds' {
		local i = `i' + 1
		qui replace pt = `pval' in `i'

		local wt = `pval' / (1 - `pval')
		qui replace w = `wt' in `i'

		local se_t = `Se'
		local sp_t = `Sp'
		qui replace se_pt = `se_t' in `i'
		qui replace sp_pt = `sp_t' in `i'

		* Net benefit (Vickers & Elkin 2006)
		local nb_val = `se_t' * `pi' - (1 - `sp_t') * (1 - `pi') * `wt'
		qui replace nb = `nb_val' in `i'

		* NB treat-all
		local nb_all_val = `pi' - (1 - `pi') * `wt'
		qui replace nb_all = `nb_all_val' in `i'

		* Relative utility (Baker et al. 2009)
		local ru_val = `nb_val' / `pi'
		qui replace ru = `ru_val' in `i'

		* Standardised net benefit
		qui replace snb = `ru_val' in `i'

		* NB gain over treat-all
		local nbgain_val = `nb_val' - max(`nb_all_val', 0)
		qui replace nbgain_v = `nbgain_val' in `i'

		* NNT
		if `nb_val' > 0 {
			qui replace nnt = 1 / `nb_val' in `i'
		}

		* Mean risk stratification (Katki 2019)
		local mrs_val = `pi' * `se_t' * (1 - `pval') + (1 - `pi') * `sp_t' * `pval'
		qui replace mrs_v = `mrs_val' in `i'

		* Incremental net benefit (Katki & Bebu 2021)
		if `treatcost' > 0 {
			local inb_val = `nb_val' * `lyg' - `screencost' / `treatcost'
			qui replace inb_v = `inb_val' in `i'
		}
	}

	* ======================================================================
	* WAU-HSRUC (trapezoidal integration)
	* ======================================================================

	qui gen double _dpt = .
	qui gen double _mid = .
	forvalues i = 2/`npt' {
		local im1 = `i' - 1
		qui replace _dpt = pt[`i'] - pt[`im1'] in `i'
		qui replace _mid = (ru[`i'] + ru[`im1']) / 2 in `i'
	}
	qui gen double _contrib = _dpt * _mid
	qui su _contrib, meanonly
	local wau_hsruc = r(sum)

	qui replace _contrib = _dpt * ((nb[_n] + nb[_n-1]) / 2) if _n > 1
	qui su _contrib if nb > 0, meanonly
	local auc_nb = r(sum)

	* Optimal threshold
	qui su nb, meanonly
	local max_nb = r(max)
	qui su pt if abs(nb - `max_nb') < 1e-10, meanonly
	local opt_pt = r(mean)

	qui su pt if nb > 0, meanonly
	local pt_low  = r(min)
	local pt_high = r(max)

	qui su pt if nb > 0 & nb > nb_all, meanonly
	local useful_low  = r(min)
	local useful_high = r(max)

	* Youden
	local youden = `Se' + `Sp' - 1

	* ======================================================================
	* PREDICTION INTERVALS
	* ======================================================================

	if "`prediction'" != "" {
		local pred_se_lo = invlogit(`mu1' - 1.96*`tau1')
		local pred_se_hi = invlogit(`mu1' + 1.96*`tau1')
		local pred_sp_lo = invlogit(`mu2' - 1.96*`tau2')
		local pred_sp_hi = invlogit(`mu2' + 1.96*`tau2')

		local w_opt = `opt_pt' / (1 - `opt_pt')
		local nb_best  = `pred_se_hi' * `pi' - (1 - `pred_sp_hi') * (1 - `pi') * `w_opt'
		local nb_worst = `pred_se_lo' * `pi' - (1 - `pred_sp_lo') * (1 - `pi') * `w_opt'

		di _n as text "{hline 78}"
		di as text "PREDICTION INTERVALS (95%)"
		di as text "{hline 78}"
		di as text "  Prediction Se:  " as result %6.4f `pred_se_lo' ///
			as text " to " as result %6.4f `pred_se_hi'
		di as text "  Prediction Sp:  " as result %6.4f `pred_sp_lo' ///
			as text " to " as result %6.4f `pred_sp_hi'
		di as text "  NB at pt=" as result %4.2f `opt_pt' ///
			as text ":  " as result %7.4f `nb_worst' ///
			as text " to " as result %7.4f `nb_best'
		di as text "{hline 78}"
	}

	* ======================================================================
	* DISPLAY TABLE
	* ======================================================================

	if "`notable'" == "" {

		di _n as text "{hline 78}"
		di as text "SUMMARY UTILITY METRICS"
		di as text "{hline 78}"
		di as text "  Youden index (J):           " as result %6.4f `youden'
		di as text "  WAU-HSRUC:                  " as result %6.4f `wau_hsruc'
		di as text "  Optimal threshold:          " as result %6.4f `opt_pt'
		di as text "  Max net benefit:            " as result %7.4f `max_nb'
		di as text "  Test useful range:          " as result %6.4f `useful_low' ///
			as text " to " as result %6.4f `useful_high'
		di as text "{hline 78}"

		di _n as text "{hline 78}"
		di as text "  pt" _col(12) "NB" _col(22) "NB(all)" ///
			_col(34) "RU" _col(44) "sNB" _col(54) "NNT" ///
			_col(62) "MRS" _col(70) "INB"
		di as text "{hline 78}"

		foreach show in 0.05 0.10 0.15 0.20 0.25 0.30 0.40 0.50 0.60 0.70 0.80 {
			qui gen double _dist = abs(pt - `show')
			qui su _dist, meanonly
			local mindist = r(min)
			qui su pt if abs(_dist - `mindist') < 1e-10, meanonly
			local row_pt = r(mean)
			drop _dist

			qui su nb if abs(pt - `row_pt') < 1e-10, meanonly
			local r_nb = r(mean)
			qui su nb_all if abs(pt - `row_pt') < 1e-10, meanonly
			local r_nba = r(mean)
			qui su ru if abs(pt - `row_pt') < 1e-10, meanonly
			local r_ru = r(mean)
			qui su snb if abs(pt - `row_pt') < 1e-10, meanonly
			local r_snb = r(mean)
			qui su nnt if abs(pt - `row_pt') < 1e-10, meanonly
			local r_nnt = r(mean)
			qui su mrs_v if abs(pt - `row_pt') < 1e-10, meanonly
			local r_mrs = r(mean)
			qui su inb_v if abs(pt - `row_pt') < 1e-10, meanonly
			local r_inb = r(mean)

			local nnt_str = cond(`r_nnt' < . & `r_nnt' > 0, ///
				string(`r_nnt', "%6.1f"), "    .")
			local inb_str = cond(`r_inb' < ., ///
				string(`r_inb', "%7.4f"), "      .")

			di as result %6.2f `show' _col(10) ///
				as result %8.4f `r_nb' _col(20) ///
				as result %8.4f `r_nba' _col(32) ///
				as result %6.4f `r_ru' _col(42) ///
				as result %6.4f `r_snb' _col(52) ///
				as text "`nnt_str'" _col(62) ///
				as result %6.4f `r_mrs' _col(70) ///
				as text "`inb_str'"
		}
		di as text "{hline 78}"
	}

	* ======================================================================
	* GRAPHS
	* ======================================================================

	if "`graph'" == "" {

		* Panel 1: Decision Curve
		local tw1 `"(line nb pt, lcolor(navy) lwidth(medthick))"'
		local tw1 `"`tw1' (line nb_all pt, lcolor(cranberry) lpattern(dash))"'
		local tw1 `"`tw1', yline(0, lcolor(gs10) lpattern(dot))"'
		local tw1 `"`tw1' xtitle("Threshold probability") ytitle("Net benefit")"'
		local tw1 `"`tw1' legend(order(1 "Test strategy" 2 "Treat all") size(small) rows(1))"'
		local tw1 `"`tw1' title("Decision Curve", size(medium))"'
		local tw1 `"`tw1' name(_hsruc_dca, replace)"'
		qui twoway `tw1'

		* Panel 2: Relative Utility
		local tw2 `"(line ru pt, lcolor(forest_green) lwidth(medthick))"'
		local tw2 `"`tw2', yline(0, lcolor(gs10) lpattern(dot))"'
		local tw2 `"`tw2' yline(1, lcolor(gs10) lpattern(dot))"'
		local tw2 `"`tw2' xtitle("Threshold probability") ytitle("Relative utility")"'
		local tw2 `"`tw2' title("HSRUC", size(medium))"'
		local tw2 `"`tw2' note("WAU = `=string(`wau_hsruc', "%5.3f")'", size(vsmall))"'
		local tw2 `"`tw2' name(_hsruc_ru, replace)"'
		qui twoway `tw2'

		* Panel 3: NB Gain
		local tw3 `"(line nbgain_v pt, lcolor(dkorange) lwidth(medthick))"'
		local tw3 `"`tw3', yline(0, lcolor(gs10) lpattern(dot))"'
		local tw3 `"`tw3' xtitle("Threshold probability") ytitle("NB gain")"'
		local tw3 `"`tw3' title("Net Benefit Gain", size(medium))"'
		local tw3 `"`tw3' name(_hsruc_nbg, replace)"'
		qui twoway `tw3'

		* Panel 4: NNT
		local tw4 `"(line nnt pt if nnt < 200 & nnt > 0, lcolor(purple) lwidth(medthick))"'
		local tw4 `"`tw4', xtitle("Threshold probability") ytitle("NNT")"'
		local tw4 `"`tw4' title("Number Needed to Test", size(medium))"'
		local tw4 `"`tw4' name(_hsruc_nnt, replace)"'
		qui twoway `tw4'

		* Combine
		qui graph combine _hsruc_dca _hsruc_ru _hsruc_nbg _hsruc_nnt, ///
			rows(2) cols(2) ///
			title("HSRUC: Clinical Utility at Prevalence = `=string(`prevalence', "%5.3f")'") ///
			note("Bivariate model: Se=`=string(`Se', "%4.2f")' Sp=`=string(`Sp', "%4.2f")' LR+=`=string(`LRp', "%4.1f")' LR-=`=string(`LRn', "%4.3f")'", size(vsmall)) ///
			name(hsruc_combined, replace)

		capture graph drop _hsruc_dca _hsruc_ru _hsruc_nbg _hsruc_nnt
	}

	* ======================================================================
	* SAVE UTILITY DATA
	* ======================================================================

	if "`saving'" != "" {
		keep pt w nb nb_all ru snb nbgain_v nnt mrs_v inb_v se_pt sp_pt
		label var pt       "Threshold probability"
		label var w        "Odds weight pt/(1-pt)"
		label var nb       "Net benefit"
		label var nb_all   "NB treat-all"
		label var ru       "Relative utility"
		label var snb      "Standardised net benefit"
		label var nbgain_v "NB gain over treat-all"
		label var nnt      "Number needed to test"
		label var mrs_v    "Mean risk stratification"
		label var inb_v    "Incremental net benefit"
		label var se_pt    "Sensitivity"
		label var sp_pt    "Specificity"
		save "`saving'", replace
		di _n as text "Utility curve data saved to " as result "`saving'"
	}

	restore

	* ======================================================================
	* STORE e() RESULTS
	* ======================================================================

	ereturn clear
	ereturn scalar N          = `nstudies'
	ereturn scalar prevalence = `prevalence'
	ereturn scalar Se         = `Se'
	ereturn scalar Sp         = `Sp'
	ereturn scalar LRp        = `LRp'
	ereturn scalar LRn        = `LRn'
	ereturn scalar DOR        = `DOR'
	ereturn scalar youden     = `youden'
	ereturn scalar alpha      = `alpha'
	ereturn scalar theta      = `theta'
	ereturn scalar beta       = `beta'
	ereturn scalar s2alpha    = `s2alpha'
	ereturn scalar s2theta    = `s2theta'
	ereturn scalar wau_hsruc  = `wau_hsruc'
	ereturn scalar auc_nb     = `auc_nb'
	ereturn scalar opt_pt     = `opt_pt'
	ereturn scalar max_nb     = `max_nb'
	ereturn scalar pt_low     = `pt_low'
	ereturn scalar pt_high    = `pt_high'
	ereturn scalar useful_low = `useful_low'
	ereturn scalar useful_high = `useful_high'

	if "`prediction'" != "" {
		ereturn scalar pred_se_lo = `pred_se_lo'
		ereturn scalar pred_se_hi = `pred_se_hi'
		ereturn scalar pred_sp_lo = `pred_sp_lo'
		ereturn scalar pred_sp_hi = `pred_sp_hi'
		ereturn scalar nb_best    = `nb_best'
		ereturn scalar nb_worst   = `nb_worst'
	}

	ereturn local cmd   "midas_hsruc"
	ereturn local title "Hierarchical Summary Relative Utility Curve Analysis"

	di _n as text "{hline 78}"
	di as text "HSRUC analysis complete."
	di as text "  WAU-HSRUC = " as result %6.4f `wau_hsruc' ///
		as text "  (1.0 = perfect, 0.0 = useless)"
	di as text "  Test useful for pt in [" as result %5.3f `useful_low' ///
		as text ", " as result %5.3f `useful_high' as text "]"
	di as text "{hline 78}"
end
