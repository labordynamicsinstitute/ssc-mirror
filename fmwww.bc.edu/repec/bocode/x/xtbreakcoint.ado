*! xtbreakcoint.ado — Panel Cointegration Test with Structural Breaks
*! Implements: Banerjee & Carrion-i-Silvestre (2015, JAE)
*! "Cointegration in panel data with structural breaks and cross-section dependence"
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.1 — 13 February 2026
*! Audited against original GAUSS code
*!
*! Based on original GAUSS code by A. Banerjee & J.L. Carrion-i-Silvestre
*! Translated to Stata with approval


program define xtbreakcoint, rclass
  version 14.0
  
  * ---- Load engine subroutines ----
  capture findfile _xtbreakcoint_engine.ado
  if _rc {
    di in red "required file _xtbreakcoint_engine.ado not found"
    di in red "install it alongside xtbreakcoint.ado"
    exit 601
  }
  qui run "`r(fn)'"
  
  syntax varlist(min=2 ts) [if] [in], [          ///
    MODel(string)                                  ///
    MAXFactors(integer 5)                          ///
    MAXLag(integer 4)                              ///
    METHod(string)                                 ///
    TRIM(real 0.15)                                ///
    MAXIter(integer 20)                            ///
    TOLerance(real 0.001)                          ///
    NOFactor                                       ///
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
  
  * ---- Parse depvar and indepvars ----
  gettoken depvar indepvars : varlist
  
  local nxvars : word count `indepvars'
  if `nxvars' == 0 {
    di in red "at least one independent variable required"
    exit 198
  }
  
  * ---- Model specification ----
  if "`model'" == "" local model "trendshift"
  
  local model_str = lower("`model'")
  
  if "`model_str'" == "constant" | "`model_str'" == "1" {
    local model_num = 1
    local model_label "Constant (Model 1)"
  }
  else if "`model_str'" == "trend" | "`model_str'" == "2" {
    local model_num = 2
    local model_label "Constant + Trend (Model 2)"
  }
  else if "`model_str'" == "levelshift" | "`model_str'" == "3" {
    local model_num = 3
    local model_label "Constant + Level Shift (Model 3)"
  }
  else if "`model_str'" == "trendshift" | "`model_str'" == "4" {
    local model_num = 4
    local model_label "Constant + Trend + Level Shift (Model 4)"
  }
  else if "`model_str'" == "regimeshift" | "`model_str'" == "5" {
    local model_num = 5
    local model_label "Constant + Trend + Level + Slope Shift (Model 5)"
  }
  else {
    di in red "invalid model(`model'). Choose: constant, trend, " ///
      "levelshift, trendshift, regimeshift"
    exit 198
  }
  
  * ---- Method ----
  if "`method'" == "" local method "auto"
  local method_str = lower("`method'")
  if "`method_str'" == "auto" {
    local method_num = 1
  }
  else if "`method_str'" == "fixed" {
    local method_num = 0
  }
  else {
    di in red "invalid method(`method'). Choose: auto or fixed"
    exit 198
  }
  
  * ---- Nofactor ----
  if "`nofactor'" != "" {
    local maxfactors = 0
  }
  
  * ---- Validation ----
  if `trim' <= 0 | `trim' >= 0.5 {
    di in red "trim() must be between 0 and 0.5"
    exit 198
  }
  
  if `maxlag' < 0 {
    di in red "maxlag() must be non-negative"
    exit 198
  }
  
  * ---- Mark sample ----
  marksample touse
  markout `touse' `varlist'
  
  * Get panel info
  qui levelsof `ivar' if `touse', local(panels)
  local N : word count `panels'
  
  qui summ `tvar' if `touse'
  local Tmin = r(min)
  local Tmax = r(max)
  local T = `Tmax' - `Tmin' + 1
  
  * ==================================================================
  * EMPIRICAL MOMENTS (from GAUSS brkfactors_heterog.gss)
  * Obtained for T=100, 100,000 replications
  *
  * GAUSS code (lines 79-106):
  *   if model[1]==1 or model[1]==3 or model[1]==6:
  *     mean_t = -0.41632799; var_t = 0.98339487
  *   elseif model[1]==2 or model[1]==4 or model[1]==7:
  *     mean_t = -1.5377067; var_t = 0.35005403
  *   elseif model[1]==5 or model[1]==8:
  *     mean_t = {vector by lambda}; var_t = {vector by lambda}
  * ==================================================================
  
  local moments_set = 0
  
  if `model_num' == 1 | `model_num' == 3 {
    * Constant-type models
    local mean_t = -0.41632799
    local var_t  = 0.98339487
    local moments_set = 1
  }
  else if `model_num' == 2 | `model_num' == 4 {
    * Trend-type models
    local mean_t = -1.5377067
    local var_t  = 0.35005403
    local moments_set = 1
  }
  else if `model_num' == 5 {
    * Regime shift: moments depend on break fraction (lambda)
    * GAUSS provides 9 values for lambda = 0.1, 0.2, ..., 0.9
    * We select after break estimation
    local moments_set = 0
  }
  
  * ==================================================================
  * DISPLAY HEADER
  * ==================================================================
  
  di
  di in smcl in gr "{hline 78}"
  di in gr "{bf:Panel Cointegration Test with Structural Breaks}" ///
    _col(51) in ye "xtbreakcoint 1.0.1"
  di in smcl in gr "{hline 78}"
  di in gr "  Reference:    " in ye ///
    "Banerjee & Carrion-i-Silvestre (2015, JAE)"
  di in gr "  Dep. var:     " in ye "`depvar'"
  di in gr "  Indep. vars:  " in ye "`indepvars'"
  di in gr "  Model:        " in ye "`model_label'"
  di in gr "  N (panels):   " in ye "`N'"
  di in gr "  T (periods):  " in ye "`T'"
  di in gr "  Max factors:  " in ye "`maxfactors'"
  di in gr "  Max ADF lag:  " in ye "`maxlag'"
  di in gr "  Lag method:   " in ye "`method_str'"
  di in gr "  Trimming:     " in ye "`trim'"
  di in gr "  Max iter:     " in ye "`maxiter'"
  di in gr "  Tolerance:    " in ye "`tolerance'"
  di in smcl in gr "{hline 78}"
  di
  
  * ==================================================================
  * STEP 1: ITERATIVE FACTOR + BREAK ESTIMATION
  * GAUSS: {mat_e_idio,fhat,csi,m_tbe,final_iter} = 
  *         factcoint_iter(lpm,lfp~e,model,zeros(n,1),k,tolerance,max_iter)
  * ==================================================================
  
  di in gr "{bf:Step 1: Iterative Factor-Break Estimation}"
  di in smcl in gr "{hline 50}"
  
  _bc_factcoint_iter, depvar(`depvar') indepvars(`indepvars') ///
    ivar(`ivar') tvar(`tvar') model(`model_num') ///
    maxfactors(`maxfactors') trim(`trim') ///
    touse(`touse') maxiter(`maxiter') tolerance(`tolerance')
  
  local n_factors = r(nfactors)
  local n_iters = r(iterations)
  local final_ssr = r(ssr)
  
  di
  di in gr "  Factors detected:  " in ye "`n_factors'"
  di in gr "  Iterations:        " in ye "`n_iters'"
  di in gr "  Final SSR:         " in ye %12.4f `final_ssr'
  di
  
  * ==================================================================
  * MODEL 5: Select lambda-dependent moments
  * GAUSS: lambda = estimated break fraction = m_tbe / T
  * ==================================================================
  
  if `model_num' == 5 & `moments_set' == 0 {
    * Get the common break point (stored in _bc_breaks)
    local brk_val = _bc_breaks[1, 1]
    local lambda = `brk_val' / `T'
    
    * GAUSS mean_t and var_t vectors (9 values, lambda 0.1 to 0.9)
    * Select the closest bin
    if `lambda' <= 0.15 {
      local mean_t = -1.6803178
      local var_t  = 0.40488013
    }
    else if `lambda' <= 0.25 {
      local mean_t = -1.8163351
      local var_t  = 0.41454518
    }
    else if `lambda' <= 0.35 {
      local mean_t = -1.9198423
      local var_t  = 0.40165997
    }
    else if `lambda' <= 0.45 {
      local mean_t = -1.9805257
      local var_t  = 0.36829752
    }
    else if `lambda' <= 0.55 {
      local mean_t = -1.998013
      local var_t  = 0.35833849
    }
    else if `lambda' <= 0.65 {
      local mean_t = -1.9752734
      local var_t  = 0.36808259
    }
    else if `lambda' <= 0.75 {
      local mean_t = -1.9125286
      local var_t  = 0.39040626
    }
    else if `lambda' <= 0.85 {
      local mean_t = -1.816865
      local var_t  = 0.4229098
    }
    else {
      local mean_t = -1.6755147
      local var_t  = 0.39749512
    }
    
    di in gr "  Break fraction (lambda): " in ye %6.3f `lambda'
    di in gr "  Moments (lambda-adj):    " ///
      in ye "E[t]=" %8.4f `mean_t' " Var[t]=" %8.4f `var_t'
    di
  }
  
  * ==================================================================
  * STEP 2: INDIVIDUAL ADF TESTS ON IDIOSYNCRATIC RESIDUALS
  *
  * GAUSS (brkfactors_heterog.gss lines 131-138):
  *   j=1; do until j>n;
  *     {t_adf,rho_adf,p} = ADFRC(mat_e_idio[.,j],method,p_max);
  *     m_adf[j] = t_adf;
  *     j=j+1;
  *   endo;
  *
  * mat_e_idio = cumsumc(De) — already in LEVELS
  * ==================================================================
  
  di in gr "{bf:Step 2: Individual ADF Tests on Idiosyncratic Residuals}"
  di in smcl in gr "{hline 78}"
  di in smcl in gr "{hline 11}{c +}{hline 66}"
  di in gr "  Panel   " _col(12) "{c |}" ///
    _col(14) "  t-ADF" ///
    _col(28) "  Lag(p)" ///
    _col(40) "  Break"
  di in smcl in gr "{hline 11}{c +}{hline 66}"
  
  * _bc_Dres is (T-1 x N) matrix of FIRST-DIFFERENCED idiosyncratic residuals
  * ADF is on LEVELS = cumsum of first diffs (GAUSS: e = cumsumc(De))
  
  tempname m_adf m_plag m_breaks
  matrix `m_adf' = J(`N', 1, .)
  matrix `m_plag' = J(`N', 1, 0)
  matrix `m_breaks' = _bc_breaks
  
  local unit_idx = 0
  foreach i of local panels {
    local unit_idx = `unit_idx' + 1
    
    * Build cumulated residuals in levels (GAUSS: e = cumsumc(De))
    tempvar resid_i
    qui gen double `resid_i' = . if `touse' & `ivar' == `i'
    
    local cumval = 0
    local row = 0
    forvalues t = `= `Tmin' + 1'/`Tmax' {
      local row = `row' + 1
      local dres_val = _bc_Dres[`row', `unit_idx']
      local cumval = `cumval' + `dres_val'
      qui replace `resid_i' = `cumval' ///
        if `touse' & `ivar' == `i' & `tvar' == `t'
    }
    
    * ADF test (GAUSS: ADFRC(mat_e_idio[.,j],method,p_max))
    _bc_adfrc, resvar(`resid_i') method(`method_num') ///
      pmax(`maxlag') touse(`touse')
    
    local tadf_i = r(t_adf)
    local plag_i = r(p_sel)
    
    matrix `m_adf'[`unit_idx', 1] = `tadf_i'
    matrix `m_plag'[`unit_idx', 1] = `plag_i'
    
    * Display
    local brk_i = `m_breaks'[`unit_idx', 1]
    if `brk_i' > 0 {
      local brk_time = `brk_i' + `Tmin'
      di in gr %10s "`i'" " {c |}" ///
        _col(14) in ye %9.4f `tadf_i' ///
        _col(32) in ye %3.0f `plag_i' ///
        _col(40) in ye "`brk_time'"
    }
    else {
      di in gr %10s "`i'" " {c |}" ///
        _col(14) in ye %9.4f `tadf_i' ///
        _col(32) in ye %3.0f `plag_i' ///
        _col(43) in gr "  ---"
    }
    
    capture drop `resid_i'
  }
  
  di in smcl in gr "{hline 11}{c +}{hline 66}"
  
  * ==================================================================
  * STEP 3: PANEL TEST STATISTIC
  *
  * GAUSS (brkfactors_heterog.gss line 140):
  *   test_t = ((N^(-1/2)*sumc(m_adf[.,1]))-(mean_t)*sqrt(N)) / sqrt(var_t)
  *
  * Which simplifies to:
  *   Z_t = sqrt(N) * (tbar - mean_t) / sqrt(var_t)
  *   where tbar = (1/N) * sum(m_adf)
  *
  * Under H0: Z_t ~ N(0,1). Reject for large negative Z_t.
  * ==================================================================
  
  local sum_adf = 0
  local n_valid = 0
  forvalues ui = 1/`N' {
    local adf_val = `m_adf'[`ui', 1]
    if `adf_val' < . {
      local sum_adf = `sum_adf' + `adf_val'
      local n_valid = `n_valid' + 1
    }
  }
  
  if `n_valid' == 0 {
    di in red "no valid ADF statistics computed"
    exit 498
  }
  
  local tbar = `sum_adf' / `n_valid'
  
  * GAUSS formula exactly:
  * test_t = (N^(-1/2)*sumc(m_adf) - mean_t*sqrt(N)) / sqrt(var_t)
  * = (sum_adf/sqrt(N) - mean_t*sqrt(N)) / sqrt(var_t)
  * = sqrt(N)*(sum_adf/N - mean_t) / sqrt(var_t)
  * = sqrt(N)*(tbar - mean_t) / sqrt(var_t)
  
  local Z_t = sqrt(`n_valid') * (`tbar' - `mean_t') / sqrt(`var_t')
  local p_value = normal(`Z_t')
  
  * Rejection rate at 5% (GAUSS: meanc(m_adf .lt -1.95))
  local n_reject = 0
  forvalues ui = 1/`N' {
    local adf_val = `m_adf'[`ui', 1]
    if `adf_val' < . & `adf_val' < -1.95 {
      local n_reject = `n_reject' + 1
    }
  }
  local reject_pct = 100 * `n_reject' / `n_valid'
  
  * ==================================================================
  * DISPLAY RESULTS
  * ==================================================================
  
  di
  di in smcl in gr "{hline 78}"
  di in gr "{bf:Panel Cointegration Test Results}"
  di in smcl in gr "{hline 78}"
  di
  di in gr "  H0: No cointegration (unit root in residuals)"
  di in gr "  H1: Cointegration exists"
  di
  di in smcl in gr "{hline 50}"
  di in gr "  Average t-ADF (tbar):        " ///
    in ye %9.4f `tbar'
  di in gr "  E[t] under H0:               " ///
    in ye %9.4f `mean_t'
  di in gr "  Var[t] under H0:             " ///
    in ye %9.4f `var_t'
  di in smcl in gr "{hline 50}"
  di in gr "  {bf:Panel Z_t statistic:}        " ///
    in ye "{bf:" %9.4f `Z_t' "}"
  di in gr "  {bf:p-value (one-sided):}        " ///
    in ye "{bf:" %9.4f `p_value' "}"
  di in smcl in gr "{hline 50}"
  di
  
  if `p_value' < 0.01 {
    di in gr "  {bf:Decision:} " ///
      in ye "Reject H0 at 1% level — strong evidence of cointegration"
  }
  else if `p_value' < 0.05 {
    di in gr "  {bf:Decision:} " ///
      in ye "Reject H0 at 5% level — evidence of cointegration"
  }
  else if `p_value' < 0.10 {
    di in gr "  {bf:Decision:} " ///
      in ye "Reject H0 at 10% level — weak evidence of cointegration"
  }
  else {
    di in gr "  {bf:Decision:} " ///
      in ye "Fail to reject H0 — no evidence of cointegration"
  }
  
  di
  di in gr "  Individual rejection rate (5%): " ///
    in ye %5.1f `reject_pct' "%" ///
    in gr " (" in ye "`n_reject'" in gr "/" in ye "`n_valid'" in gr " units)"
  di in gr "  Common factors detected:        " in ye "`n_factors'"
  di
  
  * ---- Break dates summary ----
  if `model_num' >= 3 {
    di in smcl in gr "{hline 78}"
    di in gr "{bf:Estimated Break Dates}"
    di in smcl in gr "{hline 40}"
    
    if `model_num' == 5 {
      * Common break
      local brk_common = `m_breaks'[1, 1] + `Tmin'
      di in gr "  Common break (all panels): " in ye "t = `brk_common'"
    }
    else {
      * Individual breaks
      local unit_idx = 0
      foreach i of local panels {
        local unit_idx = `unit_idx' + 1
        local brk_i = `m_breaks'[`unit_idx', 1]
        if `brk_i' > 0 {
          local brk_time = `brk_i' + `Tmin'
          di in gr "  Panel " in ye "`i'" in gr ":  " ///
            in ye "t = `brk_time'"
        }
      }
    }
    di
  }
  
  * ---- MQ test for common stochastic trends (if factors detected) ----
  * GAUSS (brkfactors_heterog.gss lines 156-186):
  *   if rows(fhat) > 1:
  *     detrend fhat (demean or regress-out trend)
  *     {test_np[1],test_np[2]} = MQ_test(fhat,model[1],N,0)
  
  local n_trends = 0
  local MQ_val = .
  local n_trends_p = 0
  local MQ_val_p = .
  
  if `n_factors' > 0 {
    di in smcl in gr "{hline 78}"
    di in gr "{bf:Step 4: MQ Test for Common Stochastic Trends (Bai & Ng, 2004)}"
    di in smcl in gr "{hline 50}"
    
    * Cumulate Fhat from first diffs to levels
    * GAUSS: fhat used in MQ_test is cumsumc(Fhat_diffs)
    
    local Tm1 = `T' - 1
    tempname Fhat_cumul
    matrix `Fhat_cumul' = J(`Tm1', `n_factors', 0)
    
    forvalues kk = 1/`n_factors' {
      local cumval = 0
      forvalues tt = 1/`Tm1' {
        local cumval = `cumval' + _bc_Fhat[`tt', `kk']
        matrix `Fhat_cumul'[`tt', `kk'] = `cumval'
      }
    }
    
    matrix _bc_Fhat_cumul = `Fhat_cumul'
    
    * Run non-parametric MQ test (GAUSS: MQ_test(fhat,model[1],N,0))
    _bc_mqtest, model(`model_num') npanels(`N')
    local MQ_val = r(MQ_np)
    local n_trends = r(n_trends)
    
    * Run parametric MQ test (GAUSS: MQ_test(fhat,model[1],N,1))
    _bc_mqtest_parametric, model(`model_num') npanels(`N')
    local MQ_val_p = r(MQ_p)
    local n_trends_p = r(n_trends_p)
    
    * Display results
    di
    di in smcl in gr "{hline 60}"
    di in gr _col(6) "Test" ///
      _col(25) "MQ Statistic" ///
      _col(45) "Stochastic Trends"
    di in smcl in gr "{hline 60}"
    di in gr _col(6) "Non-parametric" ///
      _col(25) in ye %12.4f `MQ_val' ///
      _col(50) in ye "`n_trends' / `n_factors'"
    di in gr _col(6) "Parametric" ///
      _col(25) in ye %12.4f `MQ_val_p' ///
      _col(50) in ye "`n_trends_p' / `n_factors'"
    di in smcl in gr "{hline 60}"
    di in gr "  (Inference at the 5% level using Bai & Ng (2004) Table I)"
    di
    
    * Interpretation based on non-parametric (primary)
    if `n_trends' == 0 {
      di in gr "  Non-parametric: All factors are " in ye "I(0) — stationary"
    }
    else if `n_trends' == `n_factors' {
      di in gr "  Non-parametric: All factors are " in ye "I(1) — stochastic trends"
    }
    else {
      di in gr "  Non-parametric: " in ye "`n_trends'" ///
        in gr " stochastic trend(s), " ///
        in ye "`= `n_factors' - `n_trends''" in gr " stationary"
    }
    di
    
    capture matrix drop _bc_Fhat_cumul
  }
  else {
    di
    di in gr "  No common factors detected — MQ test skipped."
    di
  }
  
  di in smcl in gr "{hline 78}"
  di in gr "Banerjee & Carrion-i-Silvestre (2015) — xtbreakcoint 1.0.1"
  di in gr "Dr Merwan Roudane — merwanroudane920@gmail.com"
  di in smcl in gr "{hline 78}"
  
  * ==================================================================
  * GRAPH (optional)
  * ==================================================================
  
  if "`graph'" != "" & `model_num' >= 3 {
    preserve
    clear
    
    local nobs = `N'
    qui set obs `nobs'
    qui gen str20 panel_name = ""
    qui gen break_date = .
    qui gen panel_order = .
    
    local unit_idx = 0
    foreach i of local panels {
      local unit_idx = `unit_idx' + 1
      local brk_i = `m_breaks'[`unit_idx', 1]
      local brk_time = `brk_i' + `Tmin'
      qui replace panel_name = "`i'" in `unit_idx'
      qui replace break_date = `brk_time' in `unit_idx'
      qui replace panel_order = `unit_idx' in `unit_idx'
    }
    
    twoway (bar break_date panel_order, horizontal barw(0.6) ///
      fcolor(navy%60) lcolor(navy)), ///
      title("{bf:Estimated Break Dates by Panel}", size(medium)) ///
      subtitle("xtbreakcoint — `model_label'", size(small)) ///
      ytitle("Panel") xtitle("Break Date") ///
      ylabel(1/`N', valuelabel angle(0)) ///
      scheme(s2color) name(xtbreakcoint_breaks, replace)
    
    restore
  }
  
  * ==================================================================
  * STORED RESULTS (match GAUSS output variables)
  * ==================================================================
  
  return scalar Z_t = `Z_t'
  return scalar p_value = `p_value'
  return scalar tbar = `tbar'
  return scalar mean_t = `mean_t'
  return scalar var_t = `var_t'
  return scalar N = `N'
  return scalar T = `T'
  return scalar nfactors = `n_factors'
  return scalar n_trends = `n_trends'
  return scalar MQ_np = `MQ_val'
  return scalar n_trends_p = `n_trends_p'
  return scalar MQ_p = `MQ_val_p'
  return scalar iterations = `n_iters'
  return scalar reject_pct = `reject_pct'
  
  return matrix adf = `m_adf'
  return matrix lags = `m_plag'
  return matrix breaks = `m_breaks'
  
  return local model "`model_label'"
  return local depvar "`depvar'"
  return local indepvars "`indepvars'"
  return local method "`method_str'"
  
end
