*! xtpkpss.ado — Panel KPSS Stationarity Test with Structural Breaks
*! Implements: Carrion-i-Silvestre, del Barrio-Castro & López-Bazo (2005)
*! "Breaking the panels: An application to the GDP per capita"
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0 — 26 March 2026
*!
*! Based on original GAUSS code (pd_kpss.src) by J.L. Carrion-i-Silvestre

program define xtpkpss, rclass
  version 14.0

  * ---- Load engine ----
  capture findfile _xtpkpss_engine.ado
  if _rc {
    di in red "required file _xtpkpss_engine.ado not found"
    exit 601
  }
  qui run "`r(fn)'"

  syntax varlist(min=1 ts) [if] [in], [             ///
    MODel(string)                                     ///
    MAXBreaks(integer 5)                              ///
    KERnel(string)                                    ///
    BANDwidth(integer -1)                             ///
    TRIM(real 0.10)                                   ///
    GRaph                                             ///
  ]

  * ---- Panel check ----
  qui xtset
  local ivar = r(panelvar)
  local tvar = r(timevar)

  if "`ivar'" == "" | "`tvar'" == "" {
    di in red "panel data not set; use {bf:xtset} first"
    exit 459
  }

  * ---- Parse variable ----
  local depvar : word 1 of `varlist'

  * ---- Model specification ----
  if "`model'" == "" local model "constant"
  local model_str = lower("`model'")

  if "`model_str'" == "constant" | "`model_str'" == "1" {
    local mod = 1
    local model_label "Constant (level stationarity)"
  }
  else if "`model_str'" == "trend" | "`model_str'" == "2" {
    local mod = 2
    local model_label "Constant + Trend (trend stationarity)"
  }
  else if "`model_str'" == "constbreak" | "`model_str'" == "3" {
    local mod = 3
    local model_label "Constant + Level breaks"
  }
  else if "`model_str'" == "trendbreak" | "`model_str'" == "4" {
    local mod = 4
    local model_label "Constant + Trend + Level and trend breaks"
  }
  else {
    di in red "invalid model(`model'). Choose: constant, trend, constbreak, trendbreak"
    exit 198
  }

  * ---- Kernel ----
  if "`kernel'" == "" local kernel "bartlett"
  local kernel_str = lower("`kernel'")
  if "`kernel_str'" == "bartlett" | "`kernel_str'" == "1" {
    local kern = 1
    local kernel_label "Bartlett"
  }
  else if "`kernel_str'" == "qs" | "`kernel_str'" == "quadratic" | "`kernel_str'" == "2" {
    local kern = 2
    local kernel_label "Quadratic Spectral"
  }
  else {
    di in red "invalid kernel(`kernel'). Choose: bartlett, qs"
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

  if `bandwidth' < 0 {
    local bandwidth = int(4 * (`T'/100)^(2/9))
  }

  * ====================================================================
  * BUILD DATA MATRIX
  * ====================================================================

  tempname y_mat
  matrix `y_mat' = J(`T', `N', 0)

  local unit_idx = 0
  foreach i of local panels {
    local unit_idx = `unit_idx' + 1
    local row = 0
    forvalues t = `Tmin'/`Tmax' {
      local row = `row' + 1
      qui summ `depvar' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
      if r(N) > 0 matrix `y_mat'[`row', `unit_idx'] = r(mean)
    }
  }

  * ====================================================================
  * COMPUTE INDIVIDUAL KPSS STATISTICS
  * ====================================================================

  tempname indiv_kpss indiv_lrv mu_vec var_vec num_vec den_vec
  tempname allbreaks nbreaks_vec
  matrix `indiv_kpss' = J(`N', 1, 0)
  matrix `indiv_lrv' = J(`N', 1, 0)
  matrix `num_vec' = J(`N', 1, 0)
  matrix `den_vec' = J(`N', 1, 0)
  matrix `mu_vec' = J(`N', 1, 0)
  matrix `var_vec' = J(`N', 1, 0)
  matrix `nbreaks_vec' = J(`N', 1, 0)
  matrix `allbreaks' = J(`maxbreaks', `N', 0)

  forvalues i = 1/`N' {
    tempname yi
    matrix `yi' = `y_mat'[1..`T', `i']

    local nbrk = 0
    tempname brk_i

    if `mod' >= 3 {
      * Detect structural breaks
      * First build base deterministic (constant or constant+trend)
      local base_mod = 1
      if `mod' == 4 local base_mod = 2

      _kpss_deterministics `T' `base_mod' . 0
      tempname z0
      matrix `z0' = r(result)

      _kpss_breaks `yi' `z0' `T' `maxbreaks' `trim'
      local nbrk = r(nbreaks)
      matrix `brk_i' = r(breaks)

      matrix `nbreaks_vec'[`i', 1] = `nbrk'
      if `nbrk' > 0 {
        forvalues k = 1/`nbrk' {
          matrix `allbreaks'[`k', `i'] = `brk_i'[`k', 1]
        }
      }
    }
    else {
      matrix `brk_i' = J(1, 1, 0)
    }

    * Compute individual KPSS
    _kpss_individual `yi' `mod' `brk_i' `nbrk' `bandwidth' "`kernel_str'"
    matrix `indiv_kpss'[`i', 1] = r(kpss)
    matrix `indiv_lrv'[`i', 1] = r(lrv)
    matrix `num_vec'[`i', 1] = r(num)
    matrix `den_vec'[`i', 1] = r(den)

    * Compute moments for this unit
    _kpss_moments `mod' `brk_i' `nbrk' `T'
    matrix `mu_vec'[`i', 1] = r(mu)
    matrix `var_vec'[`i', 1] = r(var)
  }

  * ====================================================================
  * PANEL STATISTICS
  * ====================================================================

  _kpss_panel_stats `indiv_kpss' `mu_vec' `var_vec' `num_vec' `den_vec' `N'
  local z_hom = r(z_hom)
  local z_het = r(z_het)
  local lm_hom = r(lm_hom)
  local lm_het = r(lm_het)
  local mu_bar = r(mu_bar)
  local var_bar = r(var_bar)

  * p-values (right tail)
  local pval_hom = 1 - normal(`z_hom')
  local pval_het = 1 - normal(`z_het')

  * ====================================================================
  * DISPLAY HEADER
  * ====================================================================

  di
  di in smcl in gr "{hline 78}"
  di in smcl in gr "{bf:Panel KPSS Stationarity Test with Structural Breaks}"
  di in smcl in gr "{hline 78}"
  di
  di in gr "  Variable:        " in ye "`depvar'"
  di in gr "  Model:           " in ye "`model_label'"
  di in gr "  Kernel:          " in ye "`kernel_label'"
  di in gr "  Panels (N):      " in ye "`N'"
  di in gr "  Time periods (T):" in ye " `T'"
  di in gr "  Bandwidth:       " in ye "`bandwidth'"
  if `mod' >= 3 {
    di in gr "  Max breaks:      " in ye "`maxbreaks'"
    di in gr "  Trimming:        " in ye "`trim'"
  }
  di

  * ====================================================================
  * INDIVIDUAL RESULTS TABLE
  * ====================================================================

  di in smcl in gr "{hline 78}"
  di in gr "{bf:Individual KPSS Statistics}"
  di in smcl in gr "{hline 78}"
  di

  if `mod' >= 3 {
    di in smcl in gr " {hline 68}"
    di in gr _col(3) "Panel" ///
      _col(18) "KPSS" ///
      _col(30) "Breaks" ///
      _col(40) "Break Dates"
    di in smcl in gr " {hline 68}"

    local unit_idx = 0
    foreach i of local panels {
      local unit_idx = `unit_idx' + 1
      local nb = `nbreaks_vec'[`unit_idx', 1]

      if `nb' > 0 {
        local bdates ""
        forvalues k = 1/`nb' {
          local bd = `allbreaks'[`k', `unit_idx'] + `Tmin' - 1
          if "`bdates'" == "" {
            local bdates "`bd'"
          }
          else {
            local bdates "`bdates', `bd'"
          }
        }
        di in gr _col(3) %12s "`i'" ///
          _col(16) in ye %8.5f `indiv_kpss'[`unit_idx', 1] ///
          _col(32) in ye %2.0f `nb' ///
          _col(40) in ye "`bdates'"
      }
      else {
        di in gr _col(3) %12s "`i'" ///
          _col(16) in ye %8.5f `indiv_kpss'[`unit_idx', 1] ///
          _col(32) in ye " 0" ///
          _col(40) in gr "(none)"
      }
    }
  }
  else {
    di in smcl in gr " {hline 35}"
    di in gr _col(3) "Panel" _col(18) "KPSS"
    di in smcl in gr " {hline 35}"

    local unit_idx = 0
    foreach i of local panels {
      local unit_idx = `unit_idx' + 1
      di in gr _col(3) %12s "`i'" ///
        _col(16) in ye %8.5f `indiv_kpss'[`unit_idx', 1]
    }
  }

  if `mod' >= 3 {
    di in smcl in gr " {hline 68}"
  }
  else {
    di in smcl in gr " {hline 35}"
  }
  di

  * ====================================================================
  * PANEL TEST RESULTS TABLE
  * ====================================================================

  di in smcl in gr "{hline 78}"
  di in gr "  H0: Panel is stationary (possibly with structural breaks)"
  di in gr "  H1: At least some units have a unit root"
  di in smcl in gr "{hline 78}"
  di
  di in smcl in gr " {hline 62}"
  di in gr _col(3) "Statistic" ///
    _col(22) "Value" ///
    _col(38) "p-value" ///
    _col(53) "Decision"
  di in smcl in gr " {hline 62}"

  * Homogeneous
  di in gr _col(3) "{bf:Z(hom)}" ///
    _col(18) in ye "{bf:" %10.4f `z_hom' "}" ///
    _col(35) in ye "{bf:" %8.4f `pval_hom' "}" ///
    _col(51) _c
  if `pval_hom' < 0.01 {
    di in ye "{bf:Reject ***}"
  }
  else if `pval_hom' < 0.05 {
    di in ye "{bf:Reject **}"
  }
  else if `pval_hom' < 0.10 {
    di in ye "{bf:Reject *}"
  }
  else {
    di in gr "Fail to reject"
  }

  * Heterogeneous
  di in gr _col(3) "{bf:Z(het)}" ///
    _col(18) in ye "{bf:" %10.4f `z_het' "}" ///
    _col(35) in ye "{bf:" %8.4f `pval_het' "}" ///
    _col(51) _c
  if `pval_het' < 0.01 {
    di in ye "{bf:Reject ***}"
  }
  else if `pval_het' < 0.05 {
    di in ye "{bf:Reject **}"
  }
  else if `pval_het' < 0.10 {
    di in ye "{bf:Reject *}"
  }
  else {
    di in gr "Fail to reject"
  }

  di in smcl in gr " {hline 62}"
  di in gr "  Large positive values indicate rejection (right tail of N(0,1))"
  di in gr "  Critical values: 1.282 (10%), 1.645 (5%), 2.326 (1%)"
  di

  * ---- Conclusion ----
  di in smcl in gr "{hline 78}"
  local min_pval = min(`pval_hom', `pval_het')
  if `min_pval' < 0.01 {
    di in gr "  {bf:Conclusion:} " ///
      in ye "Reject panel stationarity at 1% level"
  }
  else if `min_pval' < 0.05 {
    di in gr "  {bf:Conclusion:} " ///
      in ye "Reject panel stationarity at 5% level"
  }
  else if `min_pval' < 0.10 {
    di in gr "  {bf:Conclusion:} " ///
      in ye "Reject panel stationarity at 10% level"
  }
  else {
    di in gr "  {bf:Conclusion:} " ///
      in ye "Cannot reject panel stationarity — panel appears stationary"
  }
  di in smcl in gr "{hline 78}"
  di

  * ====================================================================
  * GRAPH (optional)
  * ====================================================================

  if "`graph'" != "" {
    preserve
    clear

    qui set obs `N'
    qui gen str32 panel_name = ""
    qui gen panel_order = .
    qui gen kpss_stat = .

    local unit_idx = 0
    foreach i of local panels {
      local unit_idx = `unit_idx' + 1
      qui replace panel_name = "`i'" in `unit_idx'
      qui replace panel_order = `unit_idx' in `unit_idx'
      qui replace kpss_stat = `indiv_kpss'[`unit_idx', 1] in `unit_idx'
    }

    * KPSS bar chart
    twoway (bar kpss_stat panel_order, ///
      fcolor(navy%70) lcolor(navy) barw(0.6)), ///
      title("{bf:Individual KPSS Statistics}", size(medlarge)) ///
      subtitle("`model_label'", size(small) color(gs6)) ///
      ytitle("KPSS") xtitle("Panel") ///
      xlabel(1/`N', angle(45) labsize(small)) ///
      yline(`mu_bar', lpattern(dash) lcolor(cranberry) ///
        lwidth(medthin)) ///
      graphregion(color(white)) plotregion(color(white)) ///
      scheme(s2color) ///
      name(xtpkpss_kpss, replace)

    capture qui graph export "xtpkpss_kpss.png", ///
      name(xtpkpss_kpss) replace width(1200)

    * Break dates timeline (models 3-4)
    if `mod' >= 3 {
      clear
      qui set obs `N'
      qui gen str32 panel_name = ""
      qui gen panel_order = .

      forvalues bb = 1/`maxbreaks' {
        qui gen break`bb' = .
      }

      local unit_idx = 0
      foreach i of local panels {
        local unit_idx = `unit_idx' + 1
        qui replace panel_name = "`i'" in `unit_idx'
        qui replace panel_order = `N' - `unit_idx' + 1 in `unit_idx'

        local nb = `nbreaks_vec'[`unit_idx', 1]
        forvalues bb = 1/`nb' {
          local bd = `allbreaks'[`bb', `unit_idx'] + `Tmin' - 1
          qui replace break`bb' = `bd' in `unit_idx'
        }
      }

      * Determine max actual breaks
      local act_max = 0
      forvalues i = 1/`N' {
        local nb = `nbreaks_vec'[`i', 1]
        if `nb' > `act_max' local act_max = `nb'
      }
      if `act_max' == 0 local act_max = 1

      local tw_cmd ""
      forvalues bb = 1/`act_max' {
        local sym "O"
        if `bb' == 2 local sym "D"
        if `bb' == 3 local sym "T"
        if `bb' == 4 local sym "S"
        if `bb' >= 5 local sym "X"

        local clr "navy"
        if `bb' == 2 local clr "cranberry"
        if `bb' == 3 local clr "forest_green"
        if `bb' == 4 local clr "dkorange"
        if `bb' >= 5 local clr "purple"

        local tw_cmd "`tw_cmd' (scatter panel_order break`bb', msymbol(`sym') mcolor(`clr'%80) msize(vlarge))"
      }

      twoway `tw_cmd', ///
        title("{bf:Estimated Structural Break Dates}", size(medlarge)) ///
        subtitle("`model_label'", size(small) color(gs6)) ///
        ytitle("") xtitle("Time Period") ///
        ylabel(1/`N', valuelabel angle(0) labsize(small) nogrid) ///
        legend(off) ///
        graphregion(color(white)) plotregion(color(white)) ///
        scheme(s2color) ///
        name(xtpkpss_breaks, replace)

      capture qui graph export "xtpkpss_breaks.png", ///
        name(xtpkpss_breaks) replace width(1200)
    }

    restore
  }

  * ====================================================================
  * STORED RESULTS
  * ====================================================================

  return scalar z_hom = `z_hom'
  return scalar z_het = `z_het'
  return scalar pval_hom = `pval_hom'
  return scalar pval_het = `pval_het'
  return scalar lm_hom = `lm_hom'
  return scalar lm_het = `lm_het'
  return scalar mu_bar = `mu_bar'
  return scalar var_bar = `var_bar'
  return scalar N = `N'
  return scalar T = `T'
  return scalar bandwidth = `bandwidth'

  return matrix kpss = `indiv_kpss'
  return matrix lrvar = `indiv_lrv'
  return matrix nbreaks = `nbreaks_vec'
  return matrix breaks = `allbreaks'

  return local model "`model_label'"
  return local kernel "`kernel_label'"
  return local depvar "`depvar'"

end
