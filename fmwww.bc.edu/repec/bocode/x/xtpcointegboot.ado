*! xtpcointegboot.ado — Bootstrap Panel Cointegration Test
*! Implements: Westerlund & Edgerton (2007, Economics Letters)
*! "A panel bootstrap cointegration test"
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 2.0.0 — 26 March 2026
*!
*! Based on original GAUSS code (cointboot.src) by Joakim Westerlund

program define xtpcointegboot, rclass
  version 14.0

  * ---- Load engine ----
  capture findfile _xtpcointegboot_engine.ado
  if _rc {
    di in red "required file _xtpcointegboot_engine.ado not found"
    exit 601
  }
  qui run "`r(fn)'"

  syntax varlist(min=2 ts) [if] [in], [            ///
    MODel(string)                                    ///
    ESTImator(string)                                ///
    LAGS(integer -1)                                 ///
    NBoot(integer 399)                               ///
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
  if "`model'" == "" local model "constant"
  local model_str = lower("`model'")

  if "`model_str'" == "constant" | "`model_str'" == "1" {
    local mod = 1
    local model_label "Constant"
  }
  else if "`model_str'" == "trend" | "`model_str'" == "2" {
    local mod = 2
    local model_label "Constant + Trend"
  }
  else {
    di in red "invalid model(`model'). Choose: constant, trend"
    exit 198
  }

  * ---- Estimator ----
  if "`estimator'" == "" local estimator "yw"
  local est_str = lower("`estimator'")
  if "`est_str'" == "ols" | "`est_str'" == "1" {
    local est = 1
    local est_label "OLS"
  }
  else if "`est_str'" == "yw" | "`est_str'" == "yulewalker" | "`est_str'" == "2" {
    local est = 2
    local est_label "Yule-Walker"
  }
  else {
    di in red "invalid estimator(`estimator'). Choose: ols, yw"
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

  if `lags' < 0 {
    local lags = int(4 * (`T'/100)^(2/9))
  }

  * ====================================================================
  * BUILD DATA MATRICES
  * ====================================================================

  tempname y_mat x_mat
  matrix `y_mat' = J(`T', `N', 0)
  matrix `x_mat' = J(`T', `N'*`nxvars', 0)

  local unit_idx = 0
  foreach i of local panels {
    local unit_idx = `unit_idx' + 1
    local row = 0
    forvalues t = `Tmin'/`Tmax' {
      local row = `row' + 1
      qui summ `depvar' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
      if r(N) > 0 {
        matrix `y_mat'[`row', `unit_idx'] = r(mean)
      }

      local xv_idx = 0
      foreach xv of local indepvars {
        local xv_idx = `xv_idx' + 1
        local col = `nxvars'*(`unit_idx'-1) + `xv_idx'
        qui summ `xv' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
        if r(N) > 0 {
          matrix `x_mat'[`row', `col'] = r(mean)
        }
      }
    }
  }

  * ====================================================================
  * COMPUTE: get moments first, then call Mata for everything
  * ====================================================================

  _boot_moments `mod' `nxvars'
  local mu = r(mu)
  local vr = r(vr)

  di in gr "  Computing bootstrap distribution (`nboot' replications)..."

  * Call Mata engine (moments are passed via r())
  _boot_run `y_mat' `x_mat' `mod' `est' `nboot' `lags' `mu' `vr'
  
  tempname boot_dist indiv_lm
  matrix `boot_dist' = r(bootdist)
  
  * Retrieve results stored by Mata
  matrix `indiv_lm' = __indiv_lm
  local lmn = __lmn
  capture matrix drop __indiv_lm
  capture scalar drop __lmn

  * Count how many bootstrap values <= lmn
  local n_below = 0
  forvalues j = 1/`nboot' {
    if `boot_dist'[`j', 1] <= `lmn' {
      local n_below = `n_below' + 1
    }
  }
  local boot_pval = 1 - `n_below' / `nboot'

  * Asymptotic p-value (GAUSS: cdfnc(lmn) = right tail)
  local asym_pval = 1 - normal(`lmn')

  * ====================================================================
  * DISPLAY HEADER
  * ====================================================================

  di
  di in smcl in gr "{hline 78}"
  di in smcl in gr "{bf:Bootstrap Panel Cointegration Test}"
  di in smcl in gr "{hline 78}"
  di
  di in gr "  Dep. variable:   " in ye "`depvar'"
  di in gr "  Indep. variable: " in ye "`indepvars'"
  di in gr "  Model:           " in ye "`model_label'"
  di in gr "  Estimator:       " in ye "`est_label'"
  di in gr "  Panels (N):      " in ye "`N'"
  di in gr "  Time periods (T):" in ye " `T'"
  di in gr "  Lags (p):        " in ye "`lags'"
  di in gr "  Bootstrap reps:  " in ye "`nboot'"
  di

  * ====================================================================
  * PANEL TEST RESULTS TABLE
  * ====================================================================

  di in smcl in gr "{hline 78}"
  di in gr "  H0: All units are cointegrated"
  di in gr "  H1: At least some units are not cointegrated"
  di in smcl in gr "{hline 78}"
  di
  di in smcl in gr " {hline 62}"
  di in gr _col(5) "Statistic" ///
    _col(20) "LM Value" ///
    _col(35) "Bootstrap p" ///
    _col(50) "Asymptotic p"
  di in smcl in gr " {hline 62}"
  di in gr _col(5) "{bf:LM+}" ///
    _col(17) in ye "{bf:" %10.4f `lmn' "}" ///
    _col(34) in ye "{bf:" %8.4f `boot_pval' "}" ///
    _col(49) in ye %8.4f `asym_pval'
  di in smcl in gr " {hline 62}"
  di
  di in gr "  Adjustment moments (K=`nxvars'):"
  di in gr "    E[LM+]:   " in ye %10.5f `mu'
  di in gr "    Var[LM+]: " in ye %10.5f `vr'
  di

  * ---- Decision ----
  di in smcl in gr " {hline 62}"
  di in gr _col(5) "" ///
    _col(20) "Decision" ///
    _col(50) "Significance"
  di in smcl in gr " {hline 62}"

  * Bootstrap decision
  di in gr _col(5) "Bootstrap:" _c
  if `boot_pval' < 0.01 {
    di in ye _col(20) "{bf:Reject H0}" _col(50) "***  (1% level)"
  }
  else if `boot_pval' < 0.05 {
    di in ye _col(20) "{bf:Reject H0}" _col(50) "**   (5% level)"
  }
  else if `boot_pval' < 0.10 {
    di in ye _col(20) "{bf:Reject H0}" _col(50) "*    (10% level)"
  }
  else {
    di in gr _col(20) "Fail to reject H0" _col(50) "n.s."
  }

  * Asymptotic decision
  di in gr _col(5) "Asymptotic:" _c
  if `asym_pval' < 0.01 {
    di in ye _col(20) "{bf:Reject H0}" _col(50) "***  (1% level)"
  }
  else if `asym_pval' < 0.05 {
    di in ye _col(20) "{bf:Reject H0}" _col(50) "**   (5% level)"
  }
  else if `asym_pval' < 0.10 {
    di in ye _col(20) "{bf:Reject H0}" _col(50) "*    (10% level)"
  }
  else {
    di in gr _col(20) "Fail to reject H0" _col(50) "n.s."
  }

  di in smcl in gr " {hline 62}"
  di in gr "  Large positive values indicate rejection (right tail)"
  di in smcl in gr "{hline 78}"
  di

  * ====================================================================
  * INDIVIDUAL LM TABLE
  * ====================================================================

  di in smcl in gr "{hline 78}"
  di in gr "{bf:Individual LM Statistics}"
  di in smcl in gr "{hline 78}"
  di
  di in smcl in gr " {hline 30}"
  di in gr _col(5) "Panel" _col(20) "LM"
  di in smcl in gr " {hline 30}"

  local unit_idx = 0
  foreach i of local panels {
    local unit_idx = `unit_idx' + 1
    di in gr _col(5) %12s "`i'" ///
      _col(18) in ye %10.5f `indiv_lm'[`unit_idx', 1]
  }

  di in smcl in gr " {hline 30}"
  di

  * ====================================================================
  * GRAPH (optional)
  * ====================================================================

  if "`graph'" != "" {
    preserve
    clear

    qui set obs `nboot'
    qui gen boot_val = .
    forvalues j = 1/`nboot' {
      qui replace boot_val = `boot_dist'[`j', 1] in `j'
    }

    local lmn_fmt : di %6.3f `lmn'

    twoway (histogram boot_val, fcolor(navy%40) lcolor(navy%60) ///
      bin(50) fraction) ///
      (scatteri 0 `lmn' .15 `lmn', recast(line) lcolor(cranberry) ///
      lwidth(thick) lpattern(solid)), ///
      title("{bf:Bootstrap Distribution of LM+ Test}", size(medlarge)) ///
      subtitle("`model_label' — `nboot' replications", size(small) color(gs6)) ///
      xtitle("LM+ statistic") ytitle("Density") ///
      legend(order(1 "Bootstrap" 2 "Sample LM+ = `lmn_fmt'") ///
        ring(0) position(2) size(small)) ///
      graphregion(color(white)) plotregion(color(white)) ///
      scheme(s2color) ///
      name(xtpcointegboot_dist, replace)

    capture qui graph export "xtpcointegboot_dist.png", ///
      name(xtpcointegboot_dist) replace width(1200)

    restore
  }

  * ====================================================================
  * STORED RESULTS
  * ====================================================================

  return scalar lm = `lmn'
  return scalar boot_pval = `boot_pval'
  return scalar asym_pval = `asym_pval'
  return scalar mu = `mu'
  return scalar vr = `vr'
  return scalar N = `N'
  return scalar T = `T'
  return scalar K = `nxvars'
  return scalar lags = `lags'
  return scalar nboot = `nboot'

  return matrix indiv_lm = `indiv_lm'

  return local model "`model_label'"
  return local estimator "`est_label'"
  return local depvar "`depvar'"
  return local indepvars "`indepvars'"

end
