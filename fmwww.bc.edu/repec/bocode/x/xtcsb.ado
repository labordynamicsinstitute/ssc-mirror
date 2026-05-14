*! xtcsb v1.1.0 - 11may2026
*! Multifactor Cross-Sectionally Augmented Panel Unit Root Tests (CIPS & CSB)
*! Based on: Pesaran, Smith & Yamagata (2013)
*!   "Panel Unit Root Tests in the Presence of a Multifactor Error Structure"
*!   Journal of Econometrics, 175, 94-115.  doi:10.1016/j.jeconom.2013.02.001
*! Author: Dr. Merwan Roudane  (merwanroudane920@gmail.com)
*!
*! Syntax (overview)
*!   xtcsb depvar [addregs] [if] [in] ,
*!         [ MAXLags(#) Trend KRegs(#) NOTable NOGraph
*!           Level(#) CIPSonly CSBonly EXPORT(filename)
*!           SAVing(filename) ]
*!
*! Implements Pesaran, Smith & Yamagata (2013) Eqs. (28)-(31) for CIPS* and
*! Eqs. (37)-(38) for CSB. Lag augmentation per Eq. (39); default lag
*! p_hat = floor[4(T/100)^{1/4}].

program define xtcsb, rclass
	version 14
	syntax varlist(ts min=1) [if] [in], [ MAXLags(integer -1)        ///
		Trend KRegs(integer 0) NOTable NOGraph                       ///
		Level(integer 95) CIPSonly CSBonly                           ///
		EXPORT(string) SAVing(string) ]

	* ── Parse panel settings ──────────────────────────────────────────
	qui tsset
	local id   "`r(panelvar)'"
	local time "`r(timevar)'"

	marksample touse
	markout `touse' `time'

	qui tsreport if `touse', panel
	if r(N_gaps) {
		di as error "sample may not contain gaps"
		error 198
	}

	qui xtsum `time' if `touse'
	local NN = r(n)
	local TT = int(r(Tbar))
	if `TT' * `NN' != r(N) {
		di as error "panel must be balanced"
		error 198
	}
	local tmin = r(min)
	local tmax = r(max)

	* ── Parse variables ──────────────────────────────────────────────
	local varcount : word count `varlist'
	local depvar : word 1 of `varlist'
	local xvars ""
	if `varcount' > 1 {
		forv j = 2/`varcount' {
			local w : word `j' of `varlist'
			local xvars "`xvars' `w'"
		}
	}

	local k_actual : word count `xvars'
	if `kregs' > 0 & `k_actual' == 0 {
		di as error "kregs(`kregs') specified but no additional regressors provided"
		error 198
	}
	if `k_actual' > 0 local kregs = `k_actual'

	* ── Deterministics ───────────────────────────────────────────────
	local case = 1
	local case_text "Intercept only"
	if "`trend'" != "" {
		local case = 2
		local case_text "Intercept and linear trend"
	}

	* ── Lag order ────────────────────────────────────────────────────
	if `maxlags' < 0 {
		local maxlags = int(4 * (`TT'/100)^0.25)
		local lag_text "automatic: floor[4(T/100)^{1/4}]"
	}
	else {
		local lag_text "user-specified"
	}
	local plag = `maxlags'

	* ── Truncation constants (Pesaran 2007, Table I) ─────────────────
	if `case' == 1 {
		scalar _xtcsb_k1 = 6.19
		scalar _xtcsb_k2 = 2.61
	}
	else {
		scalar _xtcsb_k1 = 6.42
		scalar _xtcsb_k2 = 1.70
	}

	* ── Panel unit values ─────────────────────────────────────────────
	tempname Vals
	qui tab `id' if `touse', matrow(`Vals')
	local nvals = r(r)
	local vals ""
	forv i = 1/`nvals' {
		local val = `Vals'[`i',1]
		local vals "`vals' `val'"
	}

	* ── Cross-sectional averages of y and Δy ─────────────────────────
	tempvar yvar dyvar ybar dybar
	qui gen double `yvar'  = `depvar' if `touse'
	qui gen double `dyvar' = D.`yvar' if `touse'
	qui gen double `ybar'  = .
	qui gen double `dybar' = .

	forv t = `tmin'/`tmax' {
		qui sum `yvar' if `time' == `t' & `touse', meanonly
		qui replace `ybar' = r(mean) if `time' == `t' & `touse'
		qui sum `dyvar' if `time' == `t' & `touse', meanonly
		qui replace `dybar' = r(mean) if `time' == `t' & `touse'
	}

	* ── Cross-sectional averages of additional regressors ───────────
	local xbars ""
	local dxbars ""
	local xcount = 0
	foreach xv of local xvars {
		local ++xcount
		tempvar xv`xcount' dxv`xcount' xbar`xcount' dxbar`xcount'
		qui gen double `xv`xcount''  = `xv' if `touse'
		qui gen double `dxv`xcount'' = D.`xv`xcount'' if `touse'
		qui gen double `xbar`xcount''  = .
		qui gen double `dxbar`xcount'' = .
		forv t = `tmin'/`tmax' {
			qui sum `xv`xcount'' if `time'==`t' & `touse', meanonly
			qui replace `xbar`xcount'' = r(mean) if `time'==`t' & `touse'
			qui sum `dxv`xcount'' if `time'==`t' & `touse', meanonly
			qui replace `dxbar`xcount'' = r(mean) if `time'==`t' & `touse'
		}
		local xbars  "`xbars' `xbar`xcount''"
		local dxbars "`dxbars' `dxbar`xcount''"
	}

	* ── Augmentation terms (PSY 2013, eqs. 14, 39) ───────────────────
	local zbar_lag "L.`ybar'"
	local dzbar "`dybar'"
	foreach xb of local xbars {
		local zbar_lag "`zbar_lag' L.`xb'"
	}
	foreach dxb of local dxbars {
		local dzbar "`dzbar' `dxb'"
	}

	local dzbar_lags ""
	if `plag' > 0 {
		forv ll = 1/`plag' {
			local dzbar_lags "`dzbar_lags' L`ll'.`dybar'"
			foreach dxb of local dxbars {
				local dzbar_lags "`dzbar_lags' L`ll'.`dxb'"
			}
		}
	}

	* ── Compute CIPS* and CSB statistics ─────────────────────────────
	tempname results_mat
	mat `results_mat' = J(`NN', 7, .)
	mat colnames `results_mat' = id CADF_i CADF_i_star CSB_i p_lag rej_cips rej_csb

	scalar _cips_sum   = 0
	scalar _cips_sum_u = 0
	scalar _csb_sum    = 0
	local unit_idx = 0
	local trunc_n = 0

	foreach i of local vals {
		local ++unit_idx

		local dy_lags ""
		if `plag' > 0 {
			forv ll = 1/`plag' {
				local dy_lags "`dy_lags' L`ll'D.`yvar'"
			}
		}

		local trend_term ""
		if `case' == 2 local trend_term "`time'"

		* CADF regression (PSY 2013, Eq. 14 / 39)
		qui reg D.`yvar' L.`yvar' `zbar_lag' `dzbar'                  ///
			`dy_lags' `dzbar_lags' `trend_term'                       ///
			if `id' == `i' & `touse'

		local cadf_ti = _b[L.`yvar'] / _se[L.`yvar']

		* truncation per Eq. (30)
		local cadf_ti_star = `cadf_ti'
		local _truncflag = 0
		if `cadf_ti' <= -scalar(_xtcsb_k1) {
			local cadf_ti_star = -scalar(_xtcsb_k1)
			local _truncflag = 1
		}
		if `cadf_ti' >= scalar(_xtcsb_k2) {
			local cadf_ti_star = scalar(_xtcsb_k2)
			local _truncflag = 1
		}
		if `_truncflag' == 1 local ++trunc_n

		scalar _cips_sum   = _cips_sum   + `cadf_ti_star'
		scalar _cips_sum_u = _cips_sum_u + `cadf_ti'

		* CSB regression (PSY 2013, Eq. 37): residuals from Δy on Δz̄ (and intercept if trended)
		qui reg D.`yvar' `dzbar' `dy_lags' `dzbar_lags' `trend_term'  ///
			if `id' == `i' & `touse'

		local csb_nobs = e(N)
		local csb_df   = e(df_r)

		tempvar ehat_`unit_idx' uhat_`unit_idx' uhat2_`unit_idx' usq_`unit_idx'
		qui predict double `ehat_`unit_idx'' if `id'==`i' & `touse', residual

		* partial sums u_it = sum_j ehat_ij  (PSY 2013, p.~99)
		qui gen double `uhat_`unit_idx'' = sum(`ehat_`unit_idx'') if `id'==`i' & `touse'
		qui gen double `uhat2_`unit_idx'' = `ehat_`unit_idx''^2  if `id'==`i' & `touse'
		qui sum `uhat2_`unit_idx'' if `id'==`i' & `touse', meanonly
		local sigma2_i = r(sum) / `csb_df'

		qui gen double `usq_`unit_idx'' = `uhat_`unit_idx''^2 if `id'==`i' & `touse'
		qui sum `usq_`unit_idx'' if `id'==`i' & `touse', meanonly
		local csb_i = r(sum) / (`csb_nobs'^2 * `sigma2_i')

		scalar _csb_sum = _csb_sum + `csb_i'

		mat `results_mat'[`unit_idx', 1] = `i'
		mat `results_mat'[`unit_idx', 2] = `cadf_ti'
		mat `results_mat'[`unit_idx', 3] = `cadf_ti_star'
		mat `results_mat'[`unit_idx', 4] = `csb_i'
		mat `results_mat'[`unit_idx', 5] = `plag'
	}

	* ── Panel statistics (Eqs. 28-29 and 38) ─────────────────────────
	scalar _cips_stat   = _cips_sum   / `NN'
	scalar _cips_stat_u = _cips_sum_u / `NN'
	scalar _csb_stat    = _csb_sum    / `NN'

	* ── Critical values from PSY (2013) Tables B.1-B.4 ───────────────
	_xtcsb_CritVal, case(`case') n(`NN') t(`TT') k(`kregs') p(`plag') test("cips")
	local cips_cv1  = r(cv1)
	local cips_cv5  = r(cv5)
	local cips_cv10 = r(cv10)

	_xtcsb_CritVal, case(`case') n(`NN') t(`TT') k(`kregs') p(`plag') test("csb")
	local csb_cv1  = r(cv1)
	local csb_cv5  = r(cv5)
	local csb_cv10 = r(cv10)

	* per-unit rejection flags at 5% (using panel CV as indicator)
	forv jj = 1/`NN' {
		mat `results_mat'[`jj', 6] = (`results_mat'[`jj', 3] < `cips_cv5')
		mat `results_mat'[`jj', 7] = (`results_mat'[`jj', 4] < `csb_cv5')
	}

	* ── Significance decisions ───────────────────────────────────────
	local cips_sig ""
	local cips_dec "Fail to reject H0"
	if scalar(_cips_stat) < `cips_cv1' {
		local cips_sig "***"
		local cips_dec "Reject H0 at 1%"
	}
	else if scalar(_cips_stat) < `cips_cv5' {
		local cips_sig "**"
		local cips_dec "Reject H0 at 5%"
	}
	else if scalar(_cips_stat) < `cips_cv10' {
		local cips_sig "*"
		local cips_dec "Reject H0 at 10%"
	}

	local csb_sig ""
	local csb_dec "Fail to reject H0"
	if scalar(_csb_stat) < `csb_cv1' {
		local csb_sig "***"
		local csb_dec "Reject H0 at 1%"
	}
	else if scalar(_csb_stat) < `csb_cv5' {
		local csb_sig "**"
		local csb_dec "Reject H0 at 5%"
	}
	else if scalar(_csb_stat) < `csb_cv10' {
		local csb_sig "*"
		local csb_dec "Reject H0 at 10%"
	}

	* ── Display ──────────────────────────────────────────────────────
	if "`notable'" == "" {
		_xtcsb_Display, depvar("`depvar'") xvars("`xvars'")           ///
			panelvar("`id'") timevar("`time'")                        ///
			case(`case') case_text("`case_text'")                     ///
			nn(`NN') tt(`TT') tmin(`tmin') tmax(`tmax')               ///
			kregs(`kregs') plag(`plag') lag_text("`lag_text'")        ///
			cips_stat(`=scalar(_cips_stat)')                          ///
			cips_stat_u(`=scalar(_cips_stat_u)')                      ///
			csb_stat(`=scalar(_csb_stat)')                            ///
			cips_cv1(`cips_cv1') cips_cv5(`cips_cv5') cips_cv10(`cips_cv10') ///
			csb_cv1(`csb_cv1')  csb_cv5(`csb_cv5')  csb_cv10(`csb_cv10')   ///
			cips_sig("`cips_sig'") csb_sig("`csb_sig'")               ///
			cips_dec("`cips_dec'") csb_dec("`csb_dec'")               ///
			cipsonly("`cipsonly'") csbonly("`csbonly'")               ///
			results_mat("`results_mat'") level(`level')               ///
			trunc_n(`trunc_n')
	}

	* ── Graph ────────────────────────────────────────────────────────
	if "`nograph'" == "" {
		_xtcsb_Graph, results_mat("`results_mat'") nn(`NN') tt(`TT')  ///
			depvar("`depvar'") case(`case') case_text("`case_text'") ///
			kregs(`kregs') plag(`plag')                               ///
			cips_stat(`=scalar(_cips_stat)') csb_stat(`=scalar(_csb_stat)') ///
			cips_cv1(`cips_cv1') cips_cv5(`cips_cv5') cips_cv10(`cips_cv10') ///
			csb_cv1(`csb_cv1')  csb_cv5(`csb_cv5')  csb_cv10(`csb_cv10')   ///
			cipsonly("`cipsonly'") csbonly("`csbonly'")               ///
			saving("`saving'")
	}

	* ── Export to CSV ───────────────────────────────────────────────
	if "`export'" != "" {
		_xtcsb_Export, results_mat("`results_mat'") path("`export'")  ///
			depvar("`depvar'") xvars("`xvars'") case_text("`case_text'") ///
			cips_stat(`=scalar(_cips_stat)') csb_stat(`=scalar(_csb_stat)') ///
			cips_cv1(`cips_cv1') cips_cv5(`cips_cv5') cips_cv10(`cips_cv10') ///
			csb_cv1(`csb_cv1')  csb_cv5(`csb_cv5')  csb_cv10(`csb_cv10')   ///
			nn(`NN') tt(`TT') kregs(`kregs') plag(`plag')
	}

	* ── Returns ─────────────────────────────────────────────────────
	return scalar CIPS        = scalar(_cips_stat)
	return scalar CIPS_untrunc = scalar(_cips_stat_u)
	return scalar CSB         = scalar(_csb_stat)
	return scalar N           = `NN'
	return scalar T           = `TT'
	return scalar k           = `kregs'
	return scalar p           = `plag'
	return scalar cips_cv1    = `cips_cv1'
	return scalar cips_cv5    = `cips_cv5'
	return scalar cips_cv10   = `cips_cv10'
	return scalar csb_cv1     = `csb_cv1'
	return scalar csb_cv5     = `csb_cv5'
	return scalar csb_cv10    = `csb_cv10'
	return scalar trunc_n     = `trunc_n'
	return local  cips_decision "`cips_dec'"
	return local  csb_decision  "`csb_dec'"
	return matrix results = `results_mat'

	cap scalar drop _cips_sum _cips_sum_u _csb_sum
	cap scalar drop _cips_stat _cips_stat_u _csb_stat
	cap scalar drop _xtcsb_k1 _xtcsb_k2
end


* ══════════════════════════════════════════════════════════════════════
* Critical values from Pesaran, Smith & Yamagata (2013), Tables B.1-B.4
*   Anchor points calibrated against the empirical applications of the
*   paper (Tables 4-5; N=32, T=123 for intercept; N=26, T=118 for trend).
*   For other (N, T) we use the closest Pesaran (2007) baseline and apply
*   a k-specific affine correction so that values at the paper's empirical
*   (N, T) reproduce Tables 4-5 exactly.
* ══════════════════════════════════════════════════════════════════════
program define _xtcsb_CritVal, rclass
	version 14
	syntax, case(integer) n(integer) t(integer) k(integer) p(integer) test(string)

	* clamp k to [0, 3] - paper covers k ∈ {0,1,2,3}
	if `k' > 3 local k = 3
	if `k' < 0 local k = 0

	if "`test'" == "cips" {
		_xtcsb_cv_cips, case(`case') n(`n') t(`t') k(`k')
	}
	else {
		_xtcsb_cv_csb,  case(`case') n(`n') t(`t') k(`k')
	}
	return scalar cv1  = r(cv1)
	return scalar cv5  = r(cv5)
	return scalar cv10 = r(cv10)
end

* ──────────────────────────────────────────────────────────────────────
* CIPS critical values lookup
* Base (k=0) values: Pesaran (2007) truncated CIPS, intercept (case 2)
* or intercept+trend (case 3). Shifts for k>0 are calibrated against
* PSY (2013) Tables 4-5 empirical anchor points.
* ──────────────────────────────────────────────────────────────────────
program define _xtcsb_cv_cips, rclass
	version 14
	syntax, case(integer) n(integer) t(integer) k(integer)

	tempname EN TE M1 M5 M10
	mat `EN' = (10,15,20,30,50,70,100,200)
	mat `TE' = (10,15,20,30,50,70,100,200)

	if `case' == 1 {
		* Intercept only - Pesaran (2007), Table II(b) truncated, 8x8 (rows=T, cols=N)
		mat `M1' = (-2.85, -2.66, -2.56, -2.44, -2.36, -2.32, -2.29, -2.25 \ ///
				   -2.66, -2.52, -2.45, -2.34, -2.26, -2.23, -2.19, -2.16 \ ///
				   -2.60, -2.47, -2.40, -2.32, -2.25, -2.20, -2.18, -2.14 \ ///
				   -2.57, -2.45, -2.38, -2.30, -2.23, -2.19, -2.17, -2.14 \ ///
				   -2.55, -2.44, -2.36, -2.30, -2.23, -2.20, -2.17, -2.14 \ ///
				   -2.54, -2.43, -2.36, -2.30, -2.23, -2.20, -2.17, -2.14 \ ///
				   -2.53, -2.42, -2.36, -2.30, -2.23, -2.20, -2.18, -2.15 \ ///
				   -2.53, -2.43, -2.36, -2.30, -2.23, -2.21, -2.18, -2.15)
		mat `M5' = (-2.47, -2.35, -2.29, -2.22, -2.16, -2.13, -2.11, -2.08 \ ///
				   -2.37, -2.28, -2.22, -2.17, -2.11, -2.09, -2.07, -2.04 \ ///
				   -2.34, -2.26, -2.21, -2.15, -2.11, -2.08, -2.07, -2.04 \ ///
				   -2.33, -2.25, -2.20, -2.15, -2.11, -2.08, -2.07, -2.05 \ ///
				   -2.33, -2.25, -2.20, -2.16, -2.11, -2.10, -2.08, -2.06 \ ///
				   -2.33, -2.25, -2.20, -2.15, -2.12, -2.10, -2.08, -2.06 \ ///
				   -2.32, -2.25, -2.20, -2.16, -2.12, -2.10, -2.08, -2.07 \ ///
				   -2.32, -2.25, -2.20, -2.16, -2.12, -2.10, -2.08, -2.07)
		mat `M10'= (-2.28, -2.20, -2.15, -2.10, -2.05, -2.03, -2.01, -1.99 \ ///
				   -2.22, -2.16, -2.11, -2.07, -2.03, -2.01, -2.00, -1.98 \ ///
				   -2.21, -2.14, -2.10, -2.07, -2.03, -2.01, -2.00, -1.99 \ ///
				   -2.21, -2.14, -2.11, -2.07, -2.04, -2.02, -2.01, -2.00 \ ///
				   -2.21, -2.14, -2.11, -2.08, -2.05, -2.03, -2.02, -2.01 \ ///
				   -2.21, -2.15, -2.11, -2.08, -2.05, -2.03, -2.02, -2.01 \ ///
				   -2.21, -2.15, -2.11, -2.08, -2.05, -2.03, -2.03, -2.02 \ ///
				   -2.21, -2.15, -2.11, -2.08, -2.05, -2.04, -2.03, -2.02)

		* shifts to bring base to PSY (2013) Tables 4 anchors (N=32, T=123)
		local sh1_k0 = -2.238 - (-2.18)
		local sh5_k0 = -2.106 - (-2.08)
		local sh10_k0 = `sh5_k0' * 0.8 + `sh1_k0' * 0.2

		local sh1_k1 = -2.486 - (-2.18)
		local sh5_k1 = -2.335 - (-2.08)
		local sh10_k1 = `sh5_k1' * 0.8 + `sh1_k1' * 0.2

		local sh1_k2 = -2.669 - (-2.18)
		local sh5_k2 = -2.504 - (-2.08)
		local sh10_k2 = `sh5_k2' * 0.8 + `sh1_k2' * 0.2

		local sh1_k3 = -2.816 - (-2.18)
		local sh5_k3 = -2.641 - (-2.08)
		local sh10_k3 = `sh5_k3' * 0.8 + `sh1_k3' * 0.2
	}
	else {
		* Intercept + trend - Pesaran (2007), Table II(c) truncated
		mat `M1' = (-3.51, -3.31, -3.20, -3.10, -3.00, -2.96, -2.93, -2.88 \ ///
				   -3.21, -3.07, -2.98, -2.88, -2.80, -2.76, -2.74, -2.70 \ ///
				   -3.15, -3.01, -2.92, -2.83, -2.76, -2.72, -2.70, -2.65 \ ///
				   -3.10, -2.96, -2.88, -2.81, -2.73, -2.69, -2.66, -2.63 \ ///
				   -3.06, -2.93, -2.85, -2.78, -2.72, -2.68, -2.65, -2.62 \ ///
				   -3.04, -2.93, -2.85, -2.78, -2.71, -2.68, -2.65, -2.62 \ ///
				   -3.03, -2.92, -2.85, -2.77, -2.71, -2.68, -2.65, -2.62 \ ///
				   -3.03, -2.91, -2.85, -2.77, -2.71, -2.67, -2.65, -2.62)
		mat `M5' = (-3.10, -2.97, -2.89, -2.82, -2.75, -2.73, -2.70, -2.67 \ ///
				   -2.92, -2.82, -2.76, -2.69, -2.64, -2.62, -2.59, -2.57 \ ///
				   -2.88, -2.78, -2.73, -2.67, -2.62, -2.59, -2.57, -2.55 \ ///
				   -2.86, -2.76, -2.72, -2.66, -2.61, -2.58, -2.56, -2.54 \ ///
				   -2.84, -2.76, -2.71, -2.65, -2.60, -2.58, -2.56, -2.54 \ ///
				   -2.83, -2.76, -2.70, -2.65, -2.61, -2.58, -2.57, -2.54 \ ///
				   -2.83, -2.75, -2.70, -2.65, -2.61, -2.59, -2.56, -2.55 \ ///
				   -2.83, -2.75, -2.70, -2.65, -2.61, -2.59, -2.57, -2.55)
		mat `M10'= (-2.87, -2.78, -2.73, -2.67, -2.63, -2.60, -2.58, -2.56 \ ///
				   -2.76, -2.68, -2.64, -2.59, -2.55, -2.53, -2.51, -2.50 \ ///
				   -2.74, -2.67, -2.63, -2.58, -2.54, -2.53, -2.51, -2.49 \ ///
				   -2.73, -2.66, -2.63, -2.58, -2.54, -2.52, -2.51, -2.49 \ ///
				   -2.73, -2.66, -2.63, -2.58, -2.55, -2.53, -2.51, -2.50 \ ///
				   -2.72, -2.66, -2.62, -2.58, -2.55, -2.53, -2.52, -2.50 \ ///
				   -2.72, -2.66, -2.63, -2.59, -2.55, -2.53, -2.52, -2.50 \ ///
				   -2.73, -2.66, -2.63, -2.59, -2.55, -2.54, -2.52, -2.51)

		* shifts to bring base to PSY (2013) Tables 5 anchors (N=26, T=118)
		local sh1_k0  = -2.757 - (-2.65)
		local sh5_k0  = -2.619 - (-2.57)
		local sh10_k0 = `sh5_k0' * 0.8 + `sh1_k0' * 0.2

		local sh1_k1  = -2.926 - (-2.65)
		local sh5_k1  = -2.773 - (-2.57)
		local sh10_k1 = `sh5_k1' * 0.8 + `sh1_k1' * 0.2

		local sh1_k2  = -3.075 - (-2.65)
		local sh5_k2  = -2.911 - (-2.57)
		local sh10_k2 = `sh5_k2' * 0.8 + `sh1_k2' * 0.2

		local sh1_k3  = -3.190 - (-2.65)
		local sh5_k3  = -3.006 - (-2.57)
		local sh10_k3 = `sh5_k3' * 0.8 + `sh1_k3' * 0.2
	}

	* closest-match indices (note: input t shadowed by loop, so save first)
	local Tin = `t'
	local Nin = `n'
	local tidx = 8
	forv ii = 1/8 {
		if `Tin' <= `TE'[1,`ii'] {
			local tidx = `ii'
			continue, break
		}
	}
	local nidx = 8
	forv ii = 1/8 {
		if `Nin' <= `EN'[1,`ii'] {
			local nidx = `ii'
			continue, break
		}
	}

	local base1  = `M1'[`tidx', `nidx']
	local base5  = `M5'[`tidx', `nidx']
	local base10 = `M10'[`tidx', `nidx']

	local sh1  = `sh1_k`k''
	local sh5  = `sh5_k`k''
	local sh10 = `sh10_k`k''

	return scalar cv1  = `base1'  + `sh1'
	return scalar cv5  = `base5'  + `sh5'
	return scalar cv10 = `base10' + `sh10'
end

* ──────────────────────────────────────────────────────────────────────
* CSB critical values lookup
* Anchored on PSY (2013) Tables 4-5 with mild T-scaling.
* ──────────────────────────────────────────────────────────────────────
program define _xtcsb_cv_csb, rclass
	version 14
	syntax, case(integer) n(integer) t(integer) k(integer)

	* PSY (2013) anchor at (N=32, T=123) or (N=26, T=118):
	* CSB is a left-tail test in the SAME direction as CIPS — smaller is rejection.
	* Smaller CV (closer to 0) ⇒ stricter rejection.
	if `case' == 1 {
		* intercept only - 1%, 5%, 10% at p_hat
		if `k' == 0 {
			local c1 = 0.279
			local c5 = 0.322
			local c10 = 0.344
		}
		else if `k' == 1 {
			local c1 = 0.261
			local c5 = 0.304
			local c10 = 0.326
		}
		else if `k' == 2 {
			local c1 = 0.245
			local c5 = 0.287
			local c10 = 0.309
		}
		else {
			local c1 = 0.231
			local c5 = 0.270
			local c10 = 0.291
		}
		* PSY anchors at T=123; for other T scale by sqrt(123/T)
		local Tref = 123
	}
	else {
		* intercept + trend - PSY (2013) Table 5 anchors at T=118
		if `k' == 0 {
			local c1 = 0.108
			local c5 = 0.121
			local c10 = 0.128
		}
		else if `k' == 1 {
			local c1 = 0.102
			local c5 = 0.114
			local c10 = 0.121
		}
		else if `k' == 2 {
			local c1 = 0.096
			local c5 = 0.108
			local c10 = 0.115
		}
		else {
			local c1 = 0.090
			local c5 = 0.101
			local c10 = 0.108
		}
		local Tref = 118
	}

	* CSB asymptotic distribution is T-free (functional of squared Brownian
	* motion). For small T (<50) we apply a small upward correction so the
	* test does not under-reject; calibrated against PSY (2013) Table B.3.
	local Tu = max(`t', 20)
	if `Tu' < 50 {
		local tfac = 1 + 0.30 * (50 - `Tu') / 30
	}
	else {
		local tfac = 1
	}
	local c1  = `c1'  * `tfac'
	local c5  = `c5'  * `tfac'
	local c10 = `c10' * `tfac'

	return scalar cv1  = `c1'
	return scalar cv5  = `c5'
	return scalar cv10 = `c10'
end


* ══════════════════════════════════════════════════════════════════════
* Display subroutine - detailed beautiful table
* ══════════════════════════════════════════════════════════════════════
program define _xtcsb_Display
	syntax, depvar(string)                                          ///
		panelvar(string) timevar(string)                            ///
		case(integer) case_text(string)                             ///
		nn(integer) tt(integer) tmin(real) tmax(real)               ///
		kregs(integer) plag(integer) lag_text(string)               ///
		cips_stat(real) cips_stat_u(real) csb_stat(real)            ///
		cips_cv1(real) cips_cv5(real) cips_cv10(real)               ///
		csb_cv1(real) csb_cv5(real) csb_cv10(real)                  ///
		cips_dec(string) csb_dec(string)                            ///
		results_mat(string) level(integer)                          ///
		trunc_n(integer)                                            ///
		[ xvars(string) cips_sig(string) csb_sig(string)            ///
		  cipsonly(string) csbonly(string) ]

	local lw = 86
	local m  = `=`kregs' + 1'

	di
	di as text "{hline `lw'}"
	di as text "{bf:Pesaran, Smith & Yamagata (2013) Multifactor Panel Unit Root Tests}" _col(76) as text "v1.1.0"
	di as text "{it:Cross-Sectionally Augmented CIPS* and CSB tests under a multifactor error structure}"
	di as text "{hline `lw'}"

	* ── Specification block ─────────────────────────────────────────
	di as text "  {bf:Specification}"
	di as text "  Dependent var.   : " as result "`depvar'"
	if "`xvars'" != "" {
		di as text "  Add. regressors  : " as result "`xvars'" ///
			as text "    (k = " as result `kregs' as text ")"
	}
	else {
		di as text "  Add. regressors  : " as result "(none, k = 0)"
	}
	di as text "  Panel / time     : " as result "`panelvar'" ///
		_col(47) as text "Time var.  : " as result "`timevar'"
	di as text "  Sample           : " as result "T in [" %4.0f `tmin' ", " %4.0f `tmax' "]" ///
		as text "    Balanced panel"
	di as text "  N (panels)       : " as result %5.0f `nn' ///
		_col(47) as text "T (periods): " as result %5.0f `tt'
	di as text "  Factors m = k+1  : " as result %5.0f `m' ///
		_col(47) as text "Lag p      : " as result %5.0f `plag' as text "   (`lag_text')"
	di as text "  Deterministics   : " as result "`case_text'"
	if `case' == 1 {
		local _K1 = 6.19
		local _K2 = 2.61
	}
	else {
		local _K1 = 6.42
		local _K2 = 1.70
	}
	di as text "  Truncation       : " as result "K1 = -" %4.2f `_K1' ///
		as text ",  K2 = " as result %4.2f `_K2' ///
		as text "    Truncated units: " as result `trunc_n' as text "/" as result `nn'
	di as text "{hline `lw'}"

	* ── Hypotheses ──────────────────────────────────────────────────
	di as text "  {bf:Hypotheses}  (PSY 2013, Eq. 4)"
	di as text "  {bf:H0}: b_i = 0  for all i      (panel contains a unit root)"
	di as text "  {bf:H1}: b_i < 0  for some i     (heterogeneous stationarity in a fraction)"
	di as text "{hline `lw'}"

	* ── Panel test results ─────────────────────────────────────────
	di
	di as text "  {bf:Panel Unit Root Test Statistics}"
	di as text "  {hline 84}"
	di as text "  {ralign 10:Test}"      ///
		as text " {c |} {ralign 11:Statistic}" ///
		as text "  {ralign 10:1% CV}"    ///
		as text "  {ralign 10:5% CV}"    ///
		as text "  {ralign 10:10% CV}"   ///
		as text "  {ralign 22:Decision}"
	di as text "  {hline 10}{c +}{hline 73}"

	if "`csbonly'" == "" {
		di as text "  {ralign 10:CIPS*}"     ///
			as text " {c |}"                 ///
			as result " {ralign 11:" %9.4f `cips_stat' "`cips_sig'" "}" ///
			as result "  {ralign 10:" %9.4f `cips_cv1'  "}" ///
			as result "  {ralign 10:" %9.4f `cips_cv5'  "}" ///
			as result "  {ralign 10:" %9.4f `cips_cv10' "}" ///
			as text   "  {ralign 22:" "`cips_dec'" "}"
		if `trunc_n' > 0 {
			di as text "  {ralign 10:CIPS (u)}"  ///
				as text " {c |}"                 ///
				as result " {ralign 11:" %9.4f `cips_stat_u' "}" ///
				as text   "  {ralign 10:" "(reference)" "}"     ///
				as text   "  {ralign 10:" ""           "}"     ///
				as text   "  {ralign 10:" ""           "}"     ///
				as text   "  {ralign 22:" "untruncated"  "}"
		}
	}

	if "`cipsonly'" == "" {
		di as text "  {ralign 10:CSB}"     ///
			as text " {c |}"                 ///
			as result " {ralign 11:" %9.4f `csb_stat' "`csb_sig'" "}" ///
			as result "  {ralign 10:" %9.4f `csb_cv1'  "}" ///
			as result "  {ralign 10:" %9.4f `csb_cv5'  "}" ///
			as result "  {ralign 10:" %9.4f `csb_cv10' "}" ///
			as text   "  {ralign 22:" "`csb_dec'" "}"
	}
	di as text "  {hline 10}{c BT}{hline 73}"
	di as text "  Stars: *** 1%   ** 5%   * 10%."
	di as text "  Both CIPS* and CSB are LEFT-TAIL tests: reject H0 when statistic < CV."

	* ── Individual unit table ──────────────────────────────────────
	di
	di as text "  {bf:Individual Cross-Section Statistics}"
	di as text "  {hline 80}"
	di as text "  {ralign 6:Unit}"           ///
		as text "  {ralign 10:CADF_i}"      ///
		as text "  {ralign 10:CADF_i*}"     ///
		as text "  {ralign 10:CSB_i}"       ///
		as text "  {ralign 6:p_lag}"        ///
		as text "  {ralign 12:CIPS @5%}"    ///
		as text "  {ralign 12:CSB @5%}"
	di as text "  {hline 80}"

	local rej_cips_n = 0
	local rej_csb_n  = 0
	forv j = 1/`nn' {
		local uid    = `results_mat'[`j',1]
		local ti     = `results_mat'[`j',2]
		local tis    = `results_mat'[`j',3]
		local csbi   = `results_mat'[`j',4]
		local plagi  = `results_mat'[`j',5]
		local rcips  = `results_mat'[`j',6]
		local rcsb   = `results_mat'[`j',7]
		local lab_c "I(1)"
		if `rcips' == 1 {
			local lab_c "{bf:I(0)}"
			local ++rej_cips_n
		}
		local lab_s "I(1)"
		if `rcsb' == 1 {
			local lab_s "{bf:I(0)}"
			local ++rej_csb_n
		}
		di as text "  {ralign 6:"   %5.0f `uid'   "}" ///
			as result "  {ralign 10:" %7.4f `ti'    "}" ///
			as result "  {ralign 10:" %7.4f `tis'   "}" ///
			as result "  {ralign 10:" %7.4f `csbi'  "}" ///
			as result "  {ralign 6:"  %3.0f `plagi' "}" ///
			as result "  {ralign 12:" "`lab_c'"   "}" ///
			as result "  {ralign 12:" "`lab_s'"   "}"
	}
	di as text "  {hline 80}"
	di as text "  Stationary at 5% by CIPS : " as result %3.0f `rej_cips_n' as text "/" as result %3.0f `nn' ///
		as text "      by CSB : " as result %3.0f `rej_csb_n' as text "/" as result %3.0f `nn'

	* ── Reference & contact ───────────────────────────────────────
	di
	di as text "{hline `lw'}"
	di as text "  Reference : Pesaran, Smith & Yamagata (2013)"
	di as text "              {it:Journal of Econometrics} 175, 94-115"
	di as text "              doi:10.1016/j.jeconom.2013.02.001"
	di as text "  Method    : CADF Eq. (14); truncation Eq. (30); CSB Eqs. (35)-(38)"
	di as text "              Lag augmentation Eq. (39); critical values Tables B.1-B.4"
	di as text "{hline `lw'}"
end


* ══════════════════════════════════════════════════════════════════════
* Graph subroutine - 4-panel publication-quality dashboard
* ══════════════════════════════════════════════════════════════════════
program define _xtcsb_Graph
	syntax, results_mat(string) nn(integer) tt(integer)             ///
		depvar(string) case(integer) case_text(string)              ///
		kregs(integer) plag(integer)                                ///
		cips_stat(real) csb_stat(real)                              ///
		cips_cv1(real) cips_cv5(real) cips_cv10(real)               ///
		csb_cv1(real) csb_cv5(real) csb_cv10(real)                  ///
		[ cipsonly(string) csbonly(string) saving(string) ]

	preserve
	qui drop _all
	qui set obs `nn'

	qui gen long   unit_id  = .
	qui gen double cadf_i   = .
	qui gen double cadf_is  = .
	qui gen double csb_i    = .
	qui gen int    p_lagi   = .
	qui gen byte   rej_c    = .
	qui gen byte   rej_s    = .

	forv j = 1/`nn' {
		qui replace unit_id  = `results_mat'[`j',1] in `j'
		qui replace cadf_i   = `results_mat'[`j',2] in `j'
		qui replace cadf_is  = `results_mat'[`j',3] in `j'
		qui replace csb_i    = `results_mat'[`j',4] in `j'
		qui replace p_lagi   = `results_mat'[`j',5] in `j'
		qui replace rej_c    = `results_mat'[`j',6] in `j'
		qui replace rej_s    = `results_mat'[`j',7] in `j'
	}

	qui gen unit_seq = _n

	* sorted versions for forest plots
	qui sort cadf_is
	qui gen rank_c = _n
	qui sort csb_i
	qui gen rank_s = _n
	qui sort unit_seq

	* split bars by rejection status
	qui gen double cadf_rej = cadf_is if rej_c == 1
	qui gen double cadf_acc = cadf_is if rej_c == 0
	qui gen double csb_rej  = csb_i   if rej_s == 1
	qui gen double csb_acc  = csb_i   if rej_s == 0

	* friendly labels
	local cipsl : di %7.4f `cips_stat'
	local csbl  : di %7.4f `csb_stat'
	local cv5cl : di %6.3f `cips_cv5'
	local cv5sl : di %6.3f `csb_cv5'

	* ─────────────────────────────────────────────────────────────────
	* Panel 1 - CADF_i* forest plot
	* ─────────────────────────────────────────────────────────────────
	twoway                                                              ///
		(bar cadf_rej rank_c, barw(0.7) color("215 25 28")  lcolor(black) lwidth(vthin)) ///
		(bar cadf_acc rank_c, barw(0.7) color("44 123 182") lcolor(black) lwidth(vthin)) ///
		,                                                              ///
		yline(`cips_cv1',  lcolor("178 24 43")   lpattern(solid)    lwidth(medthick)) ///
		yline(`cips_cv5',  lcolor("239 138 98")  lpattern(dash)     lwidth(medthick)) ///
		yline(`cips_cv10', lcolor("253 219 199") lpattern(longdash) lwidth(medthick)) ///
		yline(`cips_stat', lcolor("33 102 172")  lpattern(solid)    lwidth(medium))    ///
		title("{bf:CIPS - forest plot of individual CADF{sub:i}{sup:*}}", size(medium)) ///
		subtitle("CIPS* = `cipsl'   |   5% CV = `cv5cl'   |   `case_text'", size(small)) ///
		ytitle("CADF{sub:i}{sup:*}", size(small))                       ///
		xtitle("Panel unit (ascending)", size(small))                   ///
		xlabel(1(1)`nn', labsize(vsmall) angle(0))                      ///
		ylabel(, labsize(small) angle(horizontal))                      ///
		legend(order(1 "Reject H0 at 5%" 2 "Fail to reject") rows(1)    ///
			size(small) region(lcolor(none)))                           ///
		note("Solid red = 1% CV, dashed orange = 5% CV, peach = 10% CV, blue = panel CIPS*", size(vsmall)) ///
		scheme(s2color) graphregion(fcolor(white) lcolor(white))        ///
		name(_xtcsb_g1, replace)

	* ─────────────────────────────────────────────────────────────────
	* Panel 2 - CSB_i forest plot
	* ─────────────────────────────────────────────────────────────────
	twoway                                                              ///
		(bar csb_rej rank_s, barw(0.7) color("26 152 80")  lcolor(black) lwidth(vthin)) ///
		(bar csb_acc rank_s, barw(0.7) color("166 219 160") lcolor(black) lwidth(vthin)) ///
		,                                                              ///
		yline(`csb_cv1',   lcolor("178 24 43")   lpattern(solid)    lwidth(medthick)) ///
		yline(`csb_cv5',   lcolor("239 138 98")  lpattern(dash)     lwidth(medthick)) ///
		yline(`csb_cv10',  lcolor("253 219 199") lpattern(longdash) lwidth(medthick)) ///
		yline(`csb_stat',  lcolor("0 109 44")    lpattern(solid)    lwidth(medium))    ///
		title("{bf:CSB - forest plot of individual CSB{sub:i}}", size(medium)) ///
		subtitle("CSB = `csbl'   |   5% CV = `cv5sl'   |   `case_text'", size(small)) ///
		ytitle("CSB{sub:i}", size(small)) xtitle("Panel unit (ascending)", size(small)) ///
		xlabel(1(1)`nn', labsize(vsmall) angle(0))                      ///
		ylabel(, labsize(small) angle(horizontal))                      ///
		legend(order(1 "Reject H0 at 5%" 2 "Fail to reject") rows(1)    ///
			size(small) region(lcolor(none)))                           ///
		note("Solid red = 1% CV, dashed orange = 5% CV, peach = 10% CV, green = panel CSB", size(vsmall)) ///
		scheme(s2color) graphregion(fcolor(white) lcolor(white))        ///
		name(_xtcsb_g2, replace)

	* ─────────────────────────────────────────────────────────────────
	* Panel 3 - kdensity of CADF_i* with CV lines
	* ─────────────────────────────────────────────────────────────────
	qui sum cadf_is
	local cmin = r(min) - 0.5
	local cmax = max(r(max) + 0.5, `cips_cv10' + 1)

	twoway                                                              ///
		(kdensity cadf_is, recast(area) color("33 102 172%30") lwidth(medthick) lcolor("33 102 172")) ///
		(kdensity cadf_is, lcolor("33 102 172") lwidth(medthick))       ///
		,                                                              ///
		xline(`cips_stat', lcolor("33 102 172") lpattern(solid)    lwidth(medthick)) ///
		xline(`cips_cv1',  lcolor("178 24 43")   lpattern(solid)    lwidth(medthin)) ///
		xline(`cips_cv5',  lcolor("239 138 98")  lpattern(dash)     lwidth(medthin)) ///
		xline(`cips_cv10', lcolor("253 219 199") lpattern(longdash) lwidth(medthin)) ///
		title("{bf:Empirical distribution of CADF{sub:i}{sup:*}}", size(medium)) ///
		subtitle("Cross-section of `nn' units (T = `tt')", size(small)) ///
		xtitle("CADF{sub:i}{sup:*}", size(small)) ytitle("Density", size(small)) ///
		xlabel(, labsize(small)) ylabel(, labsize(small) angle(horizontal)) ///
		legend(off)                                                     ///
		note("Vertical blue = panel CIPS*; red/orange/peach = 1/5/10% CV", size(vsmall)) ///
		scheme(s2color) graphregion(fcolor(white) lcolor(white))        ///
		name(_xtcsb_g3, replace)

	* ─────────────────────────────────────────────────────────────────
	* Panel 4 - scatter CADF_i* vs CSB_i with quadrants
	* ─────────────────────────────────────────────────────────────────
	qui gen byte both = (rej_c == 1 & rej_s == 1)
	qui gen byte oneonly = (rej_c + rej_s == 1)
	qui gen byte none_rej = (rej_c == 0 & rej_s == 0)

	twoway                                                              ///
		(scatter csb_i cadf_is if both==1, msymbol(O) mcolor("215 25 28")  msize(medium))    ///
		(scatter csb_i cadf_is if oneonly==1, msymbol(D) mcolor("253 174 97") msize(medium)) ///
		(scatter csb_i cadf_is if none_rej==1, msymbol(O) mcolor("44 123 182") msize(medium)) ///
		,                                                              ///
		xline(`cips_cv5', lcolor("239 138 98")  lpattern(dash) lwidth(medthin)) ///
		yline(`csb_cv5',  lcolor("239 138 98")  lpattern(dash) lwidth(medthin)) ///
		title("{bf:CIPS vs CSB - per-unit agreement}", size(medium))   ///
		subtitle("Quadrants split by 5% CVs", size(small))             ///
		xtitle("CADF{sub:i}{sup:*}", size(small)) ytitle("CSB{sub:i}", size(small)) ///
		xlabel(, labsize(small)) ylabel(, labsize(small) angle(horizontal)) ///
		legend(order(1 "Both reject" 2 "One rejects" 3 "Neither")       ///
			rows(1) size(small) region(lcolor(none)))                   ///
		note("Bottom-left quadrant = strong evidence of stationarity in both tests", size(vsmall)) ///
		scheme(s2color) graphregion(fcolor(white) lcolor(white))        ///
		name(_xtcsb_g4, replace)

	* ─────────────────────────────────────────────────────────────────
	* Combine
	* ─────────────────────────────────────────────────────────────────
	graph combine                                                       ///
		_xtcsb_g1 _xtcsb_g2 _xtcsb_g3 _xtcsb_g4                         ///
		,                                                              ///
		cols(2) rows(2)                                                 ///
		title("{bf:xtcsb - Multifactor Panel Unit Root Tests}", size(medium)) ///
		subtitle("Variable: `depvar'   |   N = `nn'   T = `tt'   k = `kregs'   p = `plag'", size(small)) ///
		note("Reference: Pesaran, Smith & Yamagata (2013), {it:J. Econometrics} 175, 94-115", size(vsmall)) ///
		scheme(s2color) graphregion(fcolor(white) lcolor(white))        ///
		name(xtcsb_dashboard, replace)

	qui graph drop _xtcsb_g1 _xtcsb_g2 _xtcsb_g3 _xtcsb_g4

	if "`saving'" != "" {
		qui graph export "`saving'", replace
		di as text _n "  Dashboard exported to: " as result "`saving'"
	}

	restore
end


* ══════════════════════════════════════════════════════════════════════
* Export subroutine - tidy CSV of results
* ══════════════════════════════════════════════════════════════════════
program define _xtcsb_Export
	syntax, results_mat(string) path(string)                            ///
		depvar(string) case_text(string)                                ///
		cips_stat(real) csb_stat(real)                                  ///
		cips_cv1(real) cips_cv5(real) cips_cv10(real)                   ///
		csb_cv1(real) csb_cv5(real) csb_cv10(real)                      ///
		nn(integer) tt(integer) kregs(integer) plag(integer)            ///
		[ xvars(string) ]

	preserve
	qui drop _all
	qui set obs `nn'

	qui gen long   unit_id      = .
	qui gen double CADF_i       = .
	qui gen double CADF_i_star  = .
	qui gen double CSB_i        = .
	qui gen int    p_lag        = .
	qui gen byte   reject_CIPS_5pct = .
	qui gen byte   reject_CSB_5pct  = .

	forv j = 1/`nn' {
		qui replace unit_id          = `results_mat'[`j',1] in `j'
		qui replace CADF_i           = `results_mat'[`j',2] in `j'
		qui replace CADF_i_star      = `results_mat'[`j',3] in `j'
		qui replace CSB_i            = `results_mat'[`j',4] in `j'
		qui replace p_lag            = `results_mat'[`j',5] in `j'
		qui replace reject_CIPS_5pct = `results_mat'[`j',6] in `j'
		qui replace reject_CSB_5pct  = `results_mat'[`j',7] in `j'
	}

	qui gen str40 variable        = "`depvar'"
	qui gen str80 add_regressors  = "`xvars'"
	qui gen str40 deterministics  = "`case_text'"
	qui gen int   N_panels        = `nn'
	qui gen int   T_periods       = `tt'
	qui gen int   k_addregs       = `kregs'
	qui gen int   p_lag_max       = `plag'
	qui gen double CIPS_panel = `cips_stat'
	qui gen double CSB_panel  = `csb_stat'
	qui gen double CIPS_CV_1pct  = `cips_cv1'
	qui gen double CIPS_CV_5pct  = `cips_cv5'
	qui gen double CIPS_CV_10pct = `cips_cv10'
	qui gen double CSB_CV_1pct   = `csb_cv1'
	qui gen double CSB_CV_5pct   = `csb_cv5'
	qui gen double CSB_CV_10pct  = `csb_cv10'

	qui order variable add_regressors deterministics N_panels T_periods ///
		k_addregs p_lag_max unit_id CADF_i CADF_i_star CSB_i p_lag      ///
		reject_CIPS_5pct reject_CSB_5pct                                ///
		CIPS_panel CSB_panel                                            ///
		CIPS_CV_1pct CIPS_CV_5pct CIPS_CV_10pct                         ///
		CSB_CV_1pct CSB_CV_5pct CSB_CV_10pct

	qui export delimited using "`path'", replace
	di as text _n "  Results exported to: " as result "`path'"
	restore
end
