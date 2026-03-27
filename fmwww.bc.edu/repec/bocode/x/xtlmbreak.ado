*! xtlmbreak.ado — Panel LM Cointegration Test with Multiple Structural Breaks
*! Implements: Westerlund (2006, OBES)
*! "Testing for Panel Cointegration with Multiple Structural Breaks"
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0 — 25 March 2026
*!
*! Based on original GAUSS code (llm.src) by Joakim Westerlund
*! Department of Economics, Lund University

program define xtlmbreak, rclass
  version 14.0

  * ---- Load engine ----
  capture findfile _xtlmbreak_engine.ado
  if _rc {
    di in red "required file _xtlmbreak_engine.ado not found"
    di in red "install it alongside xtlmbreak.ado"
    exit 601
  }
  qui run "`r(fn)'"

  syntax varlist(min=2 ts) [if] [in], [          ///
    MODel(string)                                  ///
    ESTImator(string)                              ///
    MAXBreaks(integer 5)                           ///
    TRIM(real 0.15)                                ///
    MAXIter(integer 50)                            ///
    TOLerance(real 0.0001)                         ///
    GRaph                                          ///
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
  if "`model'" == "" local model "intercept"
  local model_str = lower("`model'")

  if "`model_str'" == "none" | "`model_str'" == "1" {
    local mod = 0
    local model_label "Case 1: No deterministic component"
  }
  else if "`model_str'" == "intercept" | "`model_str'" == "2" {
    local mod = 1
    local model_label "Case 2: Individual intercept"
  }
  else if "`model_str'" == "trend" | "`model_str'" == "3" {
    local mod = 2
    local model_label "Case 3: Individual intercept and trend"
  }
  else if "`model_str'" == "levelbreak" | "`model_str'" == "4" {
    local mod = 3
    local model_label "Case 4: Level break"
  }
  else if "`model_str'" == "trendbreak" | "`model_str'" == "5" {
    local mod = 4
    local model_label "Case 5: Level and trend break"
  }
  else {
    di in red "invalid model(`model'). Choose: none, intercept, " ///
      "trend, levelbreak, trendbreak"
    exit 198
  }

  * ---- Estimator ----
  if "`estimator'" == "" local estimator "dols"
  local est_str = lower("`estimator'")
  if "`est_str'" == "dols" {
    local est = 1
    local est_label "DOLS (Dynamic OLS)"
  }
  else if "`est_str'" == "fmols" {
    local est = 2
    local est_label "FMOLS (Fully Modified OLS)"
  }
  else {
    di in red "invalid estimator(`estimator'). Choose: dols or fmols"
    exit 198
  }

  * ---- Validation ----
  if `trim' <= 0 | `trim' >= 0.5 {
    di in red "trim() must be between 0 and 0.5"
    exit 198
  }
  if `maxbreaks' < 1 | `maxbreaks' > 10 {
    di in red "maxbreaks() must be between 1 and 10"
    exit 198
  }

  * ---- Mark sample ----
  marksample touse
  markout `touse' `varlist'

  * ---- Get panel dimensions ----
  qui levelsof `ivar' if `touse', local(panels)
  local N : word count `panels'

  qui summ `tvar' if `touse'
  local Tmin = r(min)
  local Tmax = r(max)
  local T = `Tmax' - `Tmin' + 1

  * Segment length (trimming)
  local seg = floor(`trim' * `T')
  if `seg' < 2 {
    di in red "time dimension too short for given trimming parameter"
    exit 198
  }

  * ====================================================================
  * BUILD DATA MATRICES FOR MATA
  * y: T × N matrix, x: T × (N*K) matrix
  * ====================================================================

  tempname y_mat x_mat

  * Initialize matrices
  matrix `y_mat' = J(`T', `N', 0)
  matrix `x_mat' = J(`T', `N'*`nxvars', 0)

  local unit_idx = 0
  foreach i of local panels {
    local unit_idx = `unit_idx' + 1

    * Extract y for this unit
    local row = 0
    forvalues t = `Tmin'/`Tmax' {
      local row = `row' + 1
      qui summ `depvar' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
      if r(N) > 0 {
        matrix `y_mat'[`row', `unit_idx'] = r(mean)
      }
    }

    * Extract x for this unit
    local xv_idx = 0
    foreach xv of local indepvars {
      local xv_idx = `xv_idx' + 1
      local col = `nxvars'*(`unit_idx'-1) + `xv_idx'
      local row = 0
      forvalues t = `Tmin'/`Tmax' {
        local row = `row' + 1
        qui summ `xv' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
        if r(N) > 0 {
          matrix `x_mat'[`row', `col'] = r(mean)
        }
      }
    }
  }

  * ====================================================================
  * RUN PANEL LM TEST IN MATA
  * ====================================================================

  mata: lb_lmbreak_panel(st_matrix("`y_mat'"), st_matrix("`x_mat'"), ///
    `mod', `est', `seg', `maxbreaks', `tolerance', `maxiter')

  * Retrieve results from Mata
  mata: st_numscalar("r_Z", lb_Z_stat)
  mata: st_numscalar("r_mu_bar", lb_mu_bar)
  mata: st_numscalar("r_var_bar", lb_var_bar)
  mata: st_numscalar("r_mean_lm", lb_mean_lm)
  mata: st_numscalar("r_mu", lb_mu_moment)
  mata: st_numscalar("r_var", lb_var_moment)

  local Z_M = scalar(r_Z)
  local mu_bar = scalar(r_mu_bar)
  local var_bar = scalar(r_var_bar)
  local mean_lm = scalar(r_mean_lm)
  local mu_mom = scalar(r_mu)
  local var_mom = scalar(r_var)

  * Get breaks matrix
  tempname breaks_mat
  mata: st_matrix("`breaks_mat'", lb_breaks_mat)

  * Calculate p-value (right tail of normal)
  local p_value = 1 - normal(`Z_M')

  * ====================================================================
  * DISPLAY HEADER
  * ====================================================================

  di
  di in smcl in gr "{hline 78}"
  di in gr "{bf:Panel LM Cointegration Test with Multiple Structural Breaks}"
  di in smcl in gr "{hline 78}"
  di in gr "  Reference:    " in ye ///
    "Westerlund (2006, Oxford Bull. Econ. Stat.)"
  di in gr "  Dep. var:     " in ye "`depvar'"
  di in gr "  Indep. vars:  " in ye "`indepvars'"
  di in gr "  Model:        " in ye "`model_label'"
  di in gr "  Estimator:    " in ye "`est_label'"
  di in gr "  N (panels):   " in ye "`N'"
  di in gr "  T (periods):  " in ye "`T'"
  di in gr "  K (regressors):" in ye " `nxvars'"
  di in gr "  Max breaks:   " in ye "`maxbreaks'"
  di in gr "  Trimming:     " in ye "`trim'"
  di in gr "  Tolerance:    " in ye "`tolerance'"
  di in gr "  Max iter:     " in ye "`maxiter'"
  di in smcl in gr "{hline 78}"

  * ====================================================================
  * INDIVIDUAL RESULTS TABLE
  * ====================================================================

  if `mod' >= 3 {
    di
    di in gr "{bf:Individual Break Detection Results}"
    di in smcl in gr "{hline 78}"
    di in smcl in gr " {hline 14}{c TT}{hline 62}"
    di in gr "  Panel       " _col(16) "{c |}" ///
      _col(19) "Breaks" ///
      _col(30) "Break Dates"
    di in smcl in gr " {hline 14}{c +}{hline 62}"

    local unit_idx = 0
    foreach i of local panels {
      local unit_idx = `unit_idx' + 1
      local nbr_i = `breaks_mat'[1, `unit_idx']

      if `nbr_i' > 0 {
        local break_dates ""
        forvalues bb = 2/`= `nbr_i' + 1' {
          local bd = `breaks_mat'[`bb', `unit_idx']
          if `bd' > 0 {
            local bd_time = `bd' + `Tmin' - 1
            if "`break_dates'" == "" {
              local break_dates "`bd_time'"
            }
            else {
              local break_dates "`break_dates', `bd_time'"
            }
          }
        }
        di in gr %13s "`i'" " {c |}" ///
          _col(21) in ye %3.0f `nbr_i' ///
          _col(30) in ye "`break_dates'"
      }
      else {
        di in gr %13s "`i'" " {c |}" ///
          _col(21) in ye "  0" ///
          _col(30) in gr "  (no break)"
      }
    }
    di in smcl in gr " {hline 14}{c BT}{hline 62}"
  }

  * ====================================================================
  * PANEL TEST RESULTS
  * ====================================================================

  di
  di in smcl in gr "{hline 78}"
  di in gr "{bf:Panel LM Test Results}"
  di in smcl in gr "{hline 78}"
  di
  di in gr "  H0: All individuals are cointegrated"
  di in gr "  H1: At least some individuals are not cointegrated"
  di
  di in smcl in gr " {hline 50}"
  di in gr "  Response surface moments (K=`nxvars'):"
  di in gr "    Q (expected value):          " ///
    in ye %12.5f `mu_mom'
  di in gr "    R (variance):                " ///
    in ye %12.5f `var_mom'
  di in smcl in gr " {hline 50}"
  di in gr "  Average LM statistic:          " ///
    in ye %12.5f `mean_lm'
  di in gr "  Cross-sectional mean (mu_bar): " ///
    in ye %12.5f `mu_bar'
  di in gr "  Cross-sectional var  (R_bar):  " ///
    in ye %12.5f `var_bar'
  di in smcl in gr " {hline 50}"
  di
  di in smcl in gr " {hline 58}"
  di in gr _col(3) "Statistic" ///
    _col(20) "Value" ///
    _col(38) "p-value" ///
    _col(52) "Decision"
  di in smcl in gr " {hline 58}"
  di in gr _col(3) "{bf:Z(M)}" ///
    _col(16) in ye "{bf:" %10.4f `Z_M' "}" ///
    _col(35) in ye "{bf:" %8.4f `p_value' "}" ///
    _col(50) _c

  if `p_value' < 0.01 {
    di in ye "{bf:Reject H0 ***}"
  }
  else if `p_value' < 0.05 {
    di in ye "{bf:Reject H0 **}"
  }
  else if `p_value' < 0.10 {
    di in ye "{bf:Reject H0 *}"
  }
  else {
    di in gr "Fail to reject"
  }

  di in smcl in gr " {hline 58}"
  di in gr "  Note: Large positive values of Z(M) indicate rejection."
  di in gr "  Compare with right tail of N(0,1) distribution."
  di in gr "  Critical values: 1.282 (10%), 1.645 (5%), 2.326 (1%)"
  di

  * ---- Significance stars interpretation ----
  if `p_value' < 0.01 {
    di in gr "  {bf:Decision:} " ///
      in ye "Reject H0 at 1% level"
    di in ye "  Strong evidence against cointegration for some units"
  }
  else if `p_value' < 0.05 {
    di in gr "  {bf:Decision:} " ///
      in ye "Reject H0 at 5% level"
    di in ye "  Evidence against cointegration for some units"
  }
  else if `p_value' < 0.10 {
    di in gr "  {bf:Decision:} " ///
      in ye "Reject H0 at 10% level"
    di in ye "  Weak evidence against cointegration for some units"
  }
  else {
    di in gr "  {bf:Decision:} " ///
      in ye "Fail to reject H0"
    di in ye "  No evidence against cointegration — panel is cointegrated"
  }

  di
  di in smcl in gr "{hline 78}"

  * ====================================================================
  * GRAPH (optional)
  * ====================================================================

  if "`graph'" != "" {

    * --- Graph 1: Break dates timeline (Cases 4-5 only) ---
    if `mod' >= 3 {
      preserve
      clear

      local nobs = `N'
      qui set obs `nobs'
      qui gen str32 panel_name = ""
      qui gen panel_order = .
      qui gen nbreaks = 0

      * Determine max breaks for variable creation
      local actual_max_br = 0
      local unit_idx = 0
      foreach i of local panels {
        local unit_idx = `unit_idx' + 1
        local nb = `breaks_mat'[1, `unit_idx']
        if `nb' > `actual_max_br' local actual_max_br = `nb'
      }
      if `actual_max_br' == 0 local actual_max_br = 1

      forvalues bb = 1/`actual_max_br' {
        qui gen break`bb' = .
      }

      local unit_idx = 0
      foreach i of local panels {
        local unit_idx = `unit_idx' + 1
        qui replace panel_name = "`i'" in `unit_idx'
        qui replace panel_order = `N' - `unit_idx' + 1 in `unit_idx'
        local nb = `breaks_mat'[1, `unit_idx']
        qui replace nbreaks = `nb' in `unit_idx'

        forvalues bb = 1/`nb' {
          local bd = `breaks_mat'[`= `bb' + 1', `unit_idx']
          local bd_time = `bd' + `Tmin' - 1
          qui replace break`bb' = `bd_time' in `unit_idx'
        }
      }

      * Build scatter plot of break dates
      local tw_cmd ""
      forvalues bb = 1/`actual_max_br' {
        local sym "O"
        if `bb' == 1 local sym "O"
        if `bb' == 2 local sym "D"
        if `bb' == 3 local sym "T"
        if `bb' == 4 local sym "S"
        if `bb' >= 5 local sym "X"

        local clr "navy"
        if `bb' == 2 local clr "cranberry"
        if `bb' == 3 local clr "forest_green"
        if `bb' == 4 local clr "dkorange"
        if `bb' >= 5 local clr "purple"

        local tw_cmd "`tw_cmd' (scatter panel_order break`bb', msymbol(`sym') mcolor(`clr'%80) msize(large))"
      }

      twoway `tw_cmd', ///
        title("{bf:Estimated Structural Break Dates}", size(medlarge)) ///
        subtitle("Westerlund (2006) — `model_label'", size(small)) ///
        ytitle("Panel") xtitle("Time Period") ///
        ylabel(1/`N', valuelabel angle(0) labsize(small)) ///
        legend(off) ///
        graphregion(color(white)) plotregion(color(white)) ///
        scheme(s2color) ///
        name(xtlmbreak_breaks, replace)

      qui graph export "xtlmbreak_breaks.png", name(xtlmbreak_breaks) replace width(1200)
      di in gr "  Graph saved: xtlmbreak_breaks.png"

      restore
    }

    * --- Graph 2: LM statistics bar chart ---
    * Re-compute individual LM stats for display
    preserve
    clear

    qui set obs `N'
    qui gen str32 panel_name = ""
    qui gen panel_order = .
    qui gen lm_stat = .

    mata: lb_graph_individual_lm(st_matrix("`y_mat'"), ///
      st_matrix("`x_mat'"), `mod', `est', `seg', ///
      `maxbreaks', `tolerance', `maxiter')

    local unit_idx = 0
    foreach i of local panels {
      local unit_idx = `unit_idx' + 1
      qui replace panel_name = "`i'" in `unit_idx'
      qui replace panel_order = `unit_idx' in `unit_idx'
    }

    twoway (bar lm_stat panel_order, ///
      fcolor(navy%70) lcolor(navy) barw(0.6)), ///
      title("{bf:Individual LM Statistics}", size(medlarge)) ///
      subtitle("Westerlund (2006) — `model_label'", size(small)) ///
      ytitle("LM Statistic") xtitle("Panel") ///
      xlabel(1/`N', valuelabel angle(45) labsize(small)) ///
      yline(`mu_mom', lpattern(dash) lcolor(cranberry) ///
        lwidth(medthin)) ///
      graphregion(color(white)) plotregion(color(white)) ///
      scheme(s2color) ///
      name(xtlmbreak_lm, replace)

    qui graph export "xtlmbreak_lm.png", name(xtlmbreak_lm) replace width(1200)
    di in gr "  Graph saved: xtlmbreak_lm.png"

    restore
  }

  * ====================================================================
  * STORED RESULTS
  * ====================================================================

  return scalar Z_M = `Z_M'
  return scalar p_value = `p_value'
  return scalar mean_lm = `mean_lm'
  return scalar mu_bar = `mu_bar'
  return scalar R_bar = `var_bar'
  return scalar Q = `mu_mom'
  return scalar R = `var_mom'
  return scalar N = `N'
  return scalar T = `T'
  return scalar K = `nxvars'
  return scalar maxbreaks = `maxbreaks'

  return matrix breaks = `breaks_mat'

  return local model "`model_label'"
  return local estimator "`est_label'"
  return local depvar "`depvar'"
  return local indepvars "`indepvars'"

end
