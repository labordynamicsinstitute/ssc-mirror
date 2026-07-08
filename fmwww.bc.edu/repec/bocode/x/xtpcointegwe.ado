*! xtpcointegwe.ado — Panel Cointegration Test with Breaks & Common Factors
*! Implements: Westerlund & Edgerton (2008, Oxford Bull. Econ. Stat.)
*! "A Simple Test for Cointegration in Dependent Panels with Structural Breaks"
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.2 — 07 July 2026 (fix N>T conformability + factor ordering)
*!
*! Based on original GAUSS code (pd_coint_wedgerton.src) by Joakim Westerlund
*! Department of Economics, Lund University

program define xtpcointegwe, rclass
  version 14.0

  * ---- Load engine ----
  capture findfile _xtpcointegwe_engine.ado
  if _rc {
    di in red "required file _xtpcointegwe_engine.ado not found"
    di in red "install it alongside xtpcointegwe.ado"
    exit 601
  }
  qui run "`r(fn)'"

  syntax varlist(min=2 ts) [if] [in], [            ///
    MODel(string)                                    ///
    LAGS(integer -1)                                 ///
    BANDwidth(integer -1)                            ///
    TRIM(real 0.10)                                  ///
    MAXFactors(integer 5)                            ///
    GRaph                                            ///
  ]

  * ---- Panel check ----
  qui xtset
  local ivar = r(panelvar)
  local tvar = r(timevar)

  if "`ivar'" == "" | "`tvar'" == "" {
    di in red "panel data not set; use {bf:xtset} first"
    exit 459
  }

  * ---- Parse variables ----
  gettoken depvar indepvars : varlist
  local nxvars : word count `indepvars'
  if `nxvars' == 0 {
    di in red "at least one independent variable required"
    exit 198
  }

  * ---- Model specification ----
  if "`model'" == "" local model "nobreak"
  local model_str = lower("`model'")

  if "`model_str'" == "nobreak" | "`model_str'" == "0" {
    local mod = 0
    local model_label "No structural break"
  }
  else if "`model_str'" == "levelshift" | "`model_str'" == "1" {
    local mod = 1
    local model_label "Level shift"
  }
  else if "`model_str'" == "regimeshift" | "`model_str'" == "2" {
    local mod = 2
    local model_label "Regime shift"
  }
  else {
    di in red "invalid model(`model'). Choose: nobreak, levelshift, regimeshift"
    exit 198
  }

  * ---- Validation ----
  if `trim' <= 0 | `trim' >= 0.5 {
    di in red "trim() must be between 0 and 0.5"
    exit 198
  }
  if `maxfactors' < 0 {
    di in red "maxfactors() must be non-negative"
    exit 198
  }

  * ---- Mark sample ----
  marksample touse
  markout `touse' `varlist'

  * ---- Panel dimensions ----
  qui levelsof `ivar' if `touse', local(panels)
  local N : word count `panels'

  qui summ `tvar' if `touse'
  local Tmin = r(min)
  local Tmax = r(max)
  local T = `Tmax' - `Tmin' + 1

  * ---- Default lags/bandwidth ----
  if `lags' < 0 {
    local lags = int(4 * (`T'/100)^(2/9))
  }
  if `bandwidth' < 0 {
    local bandwidth = int(4 * (`T'/100)^(2/9))
  }

  * ====================================================================
  * BUILD DATA MATRICES: y (T x N), x (T x N)
  * ====================================================================

  tempname y_mat x_mat
  matrix `y_mat' = J(`T', `N', 0)
  matrix `x_mat' = J(`T', `N', 0)

  local unit_idx = 0
  foreach i of local panels {
    local unit_idx = `unit_idx' + 1

    local row = 0
    forvalues t = `Tmin'/`Tmax' {
      local row = `row' + 1
      qui summ `depvar' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
      if r(N) > 0 matrix `y_mat'[`row', `unit_idx'] = r(mean)

      * Using first independent variable (K=1 for simplicity matching GAUSS)
      local xv : word 1 of `indepvars'
      qui summ `xv' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
      if r(N) > 0 matrix `x_mat'[`row', `unit_idx'] = r(mean)
    }
  }

  * ====================================================================
  * STEP 1: FIND BREAK DATES (if model > 0)
  * ====================================================================

  tempname breaks_mat
  if `mod' > 0 {
    _we_find_breaks `y_mat' `x_mat' `trim' `mod' `N'
    matrix `breaks_mat' = r(breaks)
  }
  else {
    matrix `breaks_mat' = J(`N', 1, 0)
  }

  * ====================================================================
  * STEP 2: COMPUTE PANEL TEST WITH DEFACTORING
  * ====================================================================

  _we_compute_test `y_mat' `x_mat' `breaks_mat' `lags' `bandwidth' `mod' `maxfactors'

  local zt = r(zt)
  local za = r(za)
  local nf = r(nfactors)

  * p-values (left tail of normal — reject for large negative)
  local pval_zt = normal(`zt')
  local pval_za = normal(`za')

  * ====================================================================
  * DISPLAY HEADER
  * ====================================================================

  di
  di in smcl in gr "{hline 78}"
  di in smcl in gr "{bf:Panel Cointegration Test with Structural Breaks & Common Factors}"
  di in smcl in gr "{hline 78}"
  di
  di in gr "  Dep. variable:   " in ye "`depvar'"
  di in gr "  Indep. variable: " in ye "`indepvars'"
  di in gr "  Model:           " in ye "`model_label'"
  di in gr "  Panels (N):      " in ye "`N'"
  di in gr "  Time periods (T):" in ye " `T'"
  di in gr "  ADF lags (p):    " in ye "`lags'"
  di in gr "  Bandwidth (q):   " in ye "`bandwidth'"
  di in gr "  Max factors:     " in ye "`maxfactors'"
  di in gr "  Factors detected:" in ye " `nf'"
  di in gr "  Trimming:        " in ye "`trim'"
  di

  * ====================================================================
  * PANEL TEST RESULTS TABLE
  * ====================================================================

  di in smcl in gr "{hline 78}"
  di in gr "  H0: No cointegration (all units are spurious)"
  di in gr "  H1: At least some units are cointegrated"
  di in smcl in gr "{hline 78}"
  di
  di in smcl in gr " {hline 62}"
  di in gr _col(5) "Statistic" ///
    _col(25) "Value" ///
    _col(40) "p-value" ///
    _col(55) "Decision"
  di in smcl in gr " {hline 62}"

  * PD Tau
  di in gr _col(5) "{bf:PD Tau}" ///
    _col(21) in ye "{bf:" %10.4f `zt' "}" ///
    _col(37) in ye "{bf:" %8.4f `pval_zt' "}" ///
    _col(53) _c
  if `pval_zt' < 0.01 {
    di in ye "{bf:Reject ***}"
  }
  else if `pval_zt' < 0.05 {
    di in ye "{bf:Reject **}"
  }
  else if `pval_zt' < 0.10 {
    di in ye "{bf:Reject *}"
  }
  else {
    di in gr "Fail to reject"
  }

  * PD Phi
  di in gr _col(5) "{bf:PD Phi}" ///
    _col(21) in ye "{bf:" %10.4f `za' "}" ///
    _col(37) in ye "{bf:" %8.4f `pval_za' "}" ///
    _col(53) _c
  if `pval_za' < 0.01 {
    di in ye "{bf:Reject ***}"
  }
  else if `pval_za' < 0.05 {
    di in ye "{bf:Reject **}"
  }
  else if `pval_za' < 0.10 {
    di in ye "{bf:Reject *}"
  }
  else {
    di in gr "Fail to reject"
  }

  di in smcl in gr " {hline 62}"
  di in gr "  Critical values: -2.326 (1%), -1.645 (5%), -1.282 (10%)"
  di in gr "  Reject H0 for large negative values (left tail of N(0,1))"
  di

  * ====================================================================
  * BREAK DATES TABLE (if model > 0)
  * ====================================================================

  if `mod' > 0 {
    di in smcl in gr "{hline 78}"
    di in gr "{bf:Estimated Structural Break Dates}"
    di in smcl in gr "{hline 78}"
    di
    di in smcl in gr " {hline 40}"
    di in gr _col(5) "Panel" _col(20) "Break Date" _col(35) "Fraction"
    di in smcl in gr " {hline 40}"

    local unit_idx = 0
    foreach i of local panels {
      local unit_idx = `unit_idx' + 1
      local br_i = `breaks_mat'[`unit_idx', 1]
      local br_time = `br_i' + `Tmin' - 1
      local br_frac = `br_i' / `T'

      di in gr _col(5) %12s "`i'" ///
        _col(22) in ye "`br_time'" ///
        _col(35) in ye %6.3f `br_frac'
    }

    di in smcl in gr " {hline 40}"
    di
  }

  * ====================================================================
  * CONCLUSION
  * ====================================================================

  di in smcl in gr "{hline 78}"
  local min_pval = min(`pval_zt', `pval_za')
  if `min_pval' < 0.01 {
    di in gr "  {bf:Conclusion:} " ///
      in ye "Strong evidence of cointegration (reject H0 at 1% level)"
  }
  else if `min_pval' < 0.05 {
    di in gr "  {bf:Conclusion:} " ///
      in ye "Evidence of cointegration (reject H0 at 5% level)"
  }
  else if `min_pval' < 0.10 {
    di in gr "  {bf:Conclusion:} " ///
      in ye "Weak evidence of cointegration (reject H0 at 10% level)"
  }
  else {
    di in gr "  {bf:Conclusion:} " ///
      in ye "No evidence of cointegration (fail to reject H0)"
  }
  di in smcl in gr "{hline 78}"
  di

  * ====================================================================
  * GRAPH (optional)
  * ====================================================================

  if "`graph'" != "" & `mod' > 0 {
    * Build individual panel graphs with break lines
    local glist ""
    local unit_idx = 0
    foreach i of local panels {
      local unit_idx = `unit_idx' + 1
      local br_i = `breaks_mat'[`unit_idx', 1]
      local br_time = `br_i' + `Tmin' - 1

      local gname "_we_g`unit_idx'"
      twoway (line `depvar' `tvar' if `ivar' == `i' & `touse', ///
        lcolor(navy) lwidth(medthin)) ///
        (scatteri 0 `br_time' 0 `br_time', recast(line) ///
          lcolor(cranberry) lwidth(medthick) lpattern(dash) ///
          yaxis(1)), ///
        title("Panel `i'", size(small)) ///
        subtitle("Break: `br_time'", size(vsmall) color(gs6)) ///
        xtitle("") ytitle("") ///
        legend(off) ///
        graphregion(color(white)) plotregion(color(white)) ///
        xline(`br_time', lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
        nodraw ///
        name(`gname', replace)

      local glist "`glist' `gname'"
    }

    * Combine all panels
    graph combine `glist', ///
      title("{bf:Structural Break Detection}", size(medlarge)) ///
      subtitle("`model_label' — `depvar' vs `tvar'", ///
        size(small) color(gs6)) ///
      note("Dashed red lines indicate estimated break dates", ///
        size(vsmall)) ///
      graphregion(color(white)) ///
      cols(2) iscale(0.5) ///
      name(xtpcointegwe_breaks, replace)

    capture qui graph export "xtpcointegwe_breaks.png", ///
      name(xtpcointegwe_breaks) replace width(1400)

    * Drop individual graphs
    foreach g of local glist {
      capture graph drop `g'
    }
  }

  * ====================================================================
  * STORED RESULTS
  * ====================================================================

  return scalar zt = `zt'
  return scalar za = `za'
  return scalar pval_zt = `pval_zt'
  return scalar pval_za = `pval_za'
  return scalar N = `N'
  return scalar T = `T'
  return scalar nfactors = `nf'
  return scalar lags = `lags'
  return scalar bandwidth = `bandwidth'

  return matrix breaks = `breaks_mat'

  return local model "`model_label'"
  return local depvar "`depvar'"
  return local indepvars "`indepvars'"

end
