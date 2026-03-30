*! xtcbc.ado - Coefficient-by-Coefficient Breaks in Panel Data Models
*! Implements: Kaddoura (2025, Journal of Econometrics)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0 - 28 March 2026

program define xtcbc, eclass
  version 14.0

  capture findfile _xtcbc_engine.ado
  if _rc {
    di in red "required file _xtcbc_engine.ado not found"
    exit 601
  }
  qui run "`r(fn)'"

  syntax varlist(min=2 ts) [if] [in], [ ///
    KAPpa(real 2)      ///
    NGRid(integer 50)  ///
    CONStant(real 0.05) ///
    CSDemean           ///
    GRaph              ///
    Level(cilevel)     ///
  ]

  qui xtset
  local ivar = r(panelvar)
  local tvar = r(timevar)

  if "`ivar'" == "" | "`tvar'" == "" {
    di in red "panel data not set; use {bf:xtset} first"
    exit 459
  }

  gettoken depvar indepvars : varlist
  local p : word count `indepvars'
  if `p' == 0 {
    di in red "at least one independent variable required"
    exit 198
  }

  if `kappa' <= 0 {
    di in red "kappa() must be positive"
    exit 198
  }
  if `ngrid' < 5 | `ngrid' > 500 {
    di in red "ngrid() must be between 5 and 500"
    exit 198
  }

  marksample touse
  markout `touse' `varlist'

  qui levelsof `ivar' if `touse', local(panels)
  local N : word count `panels'

  qui summ `tvar' if `touse'
  local Tmin = r(min)
  local Tmax = r(max)
  local TT = `Tmax' - `Tmin' + 1

  if `TT' < 3 {
    di in red "at least 3 time periods required"
    exit 198
  }

  * ====================================================================
  * BUILD DATA MATRICES FOR MATA
  * Y: N x T, X: N x (T*p)
  * ====================================================================

  tempname y_mat x_mat

  matrix `y_mat' = J(`N', `TT', 0)
  matrix `x_mat' = J(`N', `TT'*`p', 0)

  local unit_idx = 0
  foreach i of local panels {
    local unit_idx = `unit_idx' + 1

    forvalues t = `Tmin'/`Tmax' {
      local col = `t' - `Tmin' + 1
      qui summ `depvar' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
      if r(N) > 0 {
        matrix `y_mat'[`unit_idx', `col'] = r(mean)
      }
    }

    local xv_idx = 0
    foreach xv of local indepvars {
      local xv_idx = `xv_idx' + 1
      forvalues t = `Tmin'/`Tmax' {
        local col_t = `t' - `Tmin' + 1
        local xcol = (`col_t' - 1) * `p' + `xv_idx'
        qui summ `xv' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
        if r(N) > 0 {
          matrix `x_mat'[`unit_idx', `xcol'] = r(mean)
        }
      }
    }
  }

  if "`csdemean'" != "" {
    mata: cbc_csdemean("`y_mat'", "`x_mat'")
  }

  * ====================================================================
  * RUN ESTIMATION IN MATA
  * ====================================================================

  mata: cbc_estimate_homogeneous(st_matrix("`y_mat'"), st_matrix("`x_mat'"), `p', `kappa', `ngrid', `constant')

  * ====================================================================
  * RETRIEVE RESULTS FROM MATA
  * ====================================================================

  tempname nbreaks_mat break_dates_mat alpha_info_mat
  tempname beta_hat_mat ic_vec_mat lambda_grid_mat

  mata: st_matrix("`nbreaks_mat'", cbc_nbreaks)
  mata: st_matrix("`break_dates_mat'", cbc_break_dates)
  mata: st_matrix("`alpha_info_mat'", cbc_alpha_info)
  mata: st_matrix("`beta_hat_mat'", cbc_beta_hat)
  mata: st_matrix("`ic_vec_mat'", cbc_ic_values)
  mata: st_matrix("`lambda_grid_mat'", cbc_lambda_grid)
  mata: st_numscalar("r_opt_lambda", cbc_optimal_lambda)

  local opt_lambda = scalar(r_opt_lambda)

  local total_breaks = 0
  forvalues k = 1/`p' {
    local nb_`k' = `nbreaks_mat'[1, `k']
    local total_breaks = `total_breaks' + `nb_`k''
  }

  local k_idx = 0
  foreach xv of local indepvars {
    local k_idx = `k_idx' + 1
    local varname_`k_idx' "`xv'"
  }

  * ====================================================================
  * DISPLAY: HEADER
  * ====================================================================

  di
  di in smcl in gr "{hline 78}"
  di in smcl in gr _col(3) "{bf:Coefficient-by-Coefficient Breaks in Panel Data}"
  di in smcl in gr "{hline 78}"
  di
  di in gr _col(3) "Dependent variable" _col(26) "= " in ye "`depvar'"
  di in gr _col(3) "Regressors" _col(26) "= " in ye "`indepvars'"
  di in gr _col(3) "Cross-sections (N)" _col(26) "= " in ye "`N'"
  di in gr _col(3) "Time periods (T)" _col(26) "= " in ye "`TT'" ///
     in gr _col(45) "Penalty constant (c)" _col(68) "= " in ye %8.4f `constant'
  di in gr _col(3) "Regressors (p)" _col(26) "= " in ye "`p'" ///
     in gr _col(45) "Weight exponent (kappa)" _col(68) "= " in ye %8.1f `kappa'
  di in gr _col(3) "Lambda grid points" _col(26) "= " in ye "`ngrid'" ///
     in gr _col(45) "Optimal lambda" _col(68) "= " in ye %8.6f `opt_lambda'
  if "`csdemean'" != "" {
    di in gr _col(3) "Cross-section demeaning" _col(26) "= " in ye "Yes"
  }
  di

  * ====================================================================
  * DISPLAY: BREAK DETECTION TABLE
  * ====================================================================

  di in smcl in gr "{hline 78}"
  di in smcl in gr _col(3) "{bf:Break Detection}"
  di in smcl in gr "{hline 78}"
  di

  di in smcl in gr _col(3) "{hline 72}"
  di in gr _col(3) "Variable" _col(22) "{c |}" ///
     _col(25) "Breaks" _col(36) "{c |}" ///
     _col(39) "Break Dates"
  di in smcl in gr _col(3) "{hline 18}{c +}{hline 13}{c +}{hline 39}"

  forvalues k = 1/`p' {
    local nb = `nb_`k''
    local vname = "`varname_`k''"

    if `nb' == 0 {
      di in gr _col(3) %18s "`vname'" " {c |}" ///
         _col(27) in ye %4.0f 0 ///
         _col(36) in gr " {c |}" ///
         _col(39) in gr "{it:none}"
    }
    else {
      local bdates ""
      forvalues bb = 1/`nb' {
        local bd = `break_dates_mat'[`bb', `k']
        local bd_time = `bd' + `Tmin' - 1
        if "`bdates'" == "" {
          local bdates "`bd_time'"
        }
        else {
          local bdates "`bdates', `bd_time'"
        }
      }
      di in gr _col(3) %18s "`vname'" " {c |}" ///
         _col(27) in ye %4.0f `nb' ///
         _col(36) in gr " {c |}" ///
         _col(39) in ye "`bdates'"
    }
  }
  di in smcl in gr _col(3) "{hline 18}{c BT}{hline 13}{c BT}{hline 39}"
  di

  * ====================================================================
  * DISPLAY: POST-SELECTION COEFFICIENT TABLE
  * ====================================================================

  di in smcl in gr "{hline 78}"
  di in smcl in gr _col(3) "{bf:Post-Selection Estimates}"
  di in smcl in gr "{hline 78}"
  di

  local n_alpha = rowsof(`alpha_info_mat')

  di in smcl in gr _col(3) "{hline 72}"
  di in gr _col(3) "Variable" _col(18) "{c |}" ///
     _col(20) "Regime" _col(30) "{c |}" ///
     _col(33) "Coef." _col(45) "{c |}" ///
     _col(48) "Std. Err." _col(60) "{c |}" ///
     _col(63) "t-stat" _col(72) "{c |}"
  di in smcl in gr _col(3) "{hline 14}{c +}{hline 11}{c +}{hline 14}{c +}{hline 14}{c +}{hline 11}{c +}{hline 6}"

  local prev_k = 0
  forvalues row = 1/`n_alpha' {
    local cur_k = `alpha_info_mat'[`row', 1]
    local cur_j = `alpha_info_mat'[`row', 2]
    local st_t  = `alpha_info_mat'[`row', 3]
    local en_t  = `alpha_info_mat'[`row', 4]
    local coef  = `alpha_info_mat'[`row', 5]
    local se    = `alpha_info_mat'[`row', 6]

    local st_time = `st_t' + `Tmin' - 1
    local en_time = `en_t' + `Tmin' - 1
    local regime_label "`st_time'-`en_time'"

    local tstat = 0
    if `se' > 0 {
      local tstat = `coef' / `se'
    }

    local stars ""
    local pval = 2 * (1 - normal(abs(`tstat')))
    if `pval' < 0.01 {
      local stars "***"
    }
    else if `pval' < 0.05 {
      local stars "**"
    }
    else if `pval' < 0.10 {
      local stars "*"
    }

    local vdisp ""
    if `cur_k' != `prev_k' {
      if `prev_k' > 0 {
        di in smcl in gr _col(3) "{hline 14}{c +}{hline 11}{c +}{hline 14}{c +}{hline 14}{c +}{hline 11}{c +}{hline 6}"
      }
      local vdisp = "`varname_`cur_k''"
    }
    local prev_k = `cur_k'

    di in gr _col(3) %14s "`vdisp'" " {c |}" ///
       _col(20) in ye %9s "`regime_label'" ///
       _col(30) in gr " {c |}" ///
       _col(32) in ye %11.4f `coef' ///
       _col(45) in gr " {c |}" ///
       _col(47) in ye %11.4f `se' ///
       _col(60) in gr " {c |}" ///
       _col(62) in ye %8.3f `tstat' ///
       _col(72) in gr " {c |}" ///
       in ye " `stars'"
  }
  di in smcl in gr _col(3) "{hline 14}{c BT}{hline 11}{c BT}{hline 14}{c BT}{hline 14}{c BT}{hline 11}{c BT}{hline 6}"
  di in gr _col(3) "{it:* p<0.10, ** p<0.05, *** p<0.01}"
  di

  * ====================================================================
  * DISPLAY: MODEL SUMMARY
  * ====================================================================

  di in smcl in gr "{hline 78}"
  di in gr _col(3) "Total coefficients estimated" _col(35) "= " in ye "`n_alpha'"
  di in gr _col(3) "Total breaks detected" _col(35) "= " in ye "`total_breaks'"

  local nobreak_vars ""
  forvalues k = 1/`p' {
    if `nb_`k'' == 0 {
      if "`nobreak_vars'" == "" {
        local nobreak_vars "`varname_`k''"
      }
      else {
        local nobreak_vars "`nobreak_vars', `varname_`k''"
      }
    }
  }
  if "`nobreak_vars'" != "" {
    di in gr _col(3) "Non-breaking coefficients" _col(35) "= " in ye "`nobreak_vars'"
  }
  di in smcl in gr "{hline 78}"
  di

  * ====================================================================
  * DISPLAY: PAPER-STYLE CBC TABLE (Table 6 format, Kaddoura 2025)
  * ====================================================================

  di in smcl in gr "{hline 78}"
  di in smcl in gr _col(20) "{bf:CBC Estimation Results}"
  di in smcl in gr "{hline 78}"

  * Collect ALL unique break dates across all coefficients
  local all_bdates ""
  forvalues k = 1/`p' {
    forvalues bb = 1/`nb_`k'' {
      local bd = `break_dates_mat'[`bb', `k']
      local bd_time = `bd' + `Tmin' - 1
      local found = 0
      foreach existing of local all_bdates {
        if `existing' == `bd_time' {
          local found = 1
        }
      }
      if `found' == 0 {
        local all_bdates "`all_bdates' `bd_time'"
      }
    }
  }

  * Sort break dates
  local sorted_bd ""
  local n_all_bd : word count `all_bdates'
  if `n_all_bd' > 0 {
    numlist "`all_bdates'", sort
    local sorted_bd "`r(numlist)'"
  }
  local n_all_bd : word count `sorted_bd'

  * Build common regime boundaries
  local n_regimes = `n_all_bd' + 1

  forvalues r = 1/`n_regimes' {
    if `r' == 1 {
      local reg_s_`r' = `Tmin'
    }
    else {
      local prev_r = `r' - 1
      local bd_r : word `prev_r' of `sorted_bd'
      local reg_s_`r' = `bd_r'
    }
    if `r' == `n_regimes' {
      local reg_e_`r' = `Tmax'
    }
    else {
      local bd_r : word `r' of `sorted_bd'
      local reg_e_`r' = `bd_r' - 1
    }
  }

  * Build regime labels
  forvalues r = 1/`n_regimes' {
    if `reg_s_`r'' == `reg_e_`r'' {
      local rlabel_`r' "`reg_s_`r''"
    }
    else {
      local rlabel_`r' "`reg_s_`r''-`reg_e_`r''"
    }
  }

  * Column width
  local cw = 12
  if `n_regimes' > 4 {
    local cw = 10
  }
  if `n_regimes' > 5 {
    local cw = 9
  }

  * --- Table header ---
  if `n_all_bd' > 0 {
    * Header row 1: regime column labels
    di in gr _col(16) "{c |}" _col(30) "{c |}" _c
    forvalues r = 1/`n_regimes' {
      di in gr %`cw's "`rlabel_`r''" _c
      if `r' < `n_regimes' {
        di in gr "  " _c
      }
    }
    di

    * Header row 2: Regressor | No breaks | regime columns
    di in gr %14s "Regressor" " " "{c |}" " " %`cw's "No breaks" " " "{c |}" _c
    forvalues r = 1/`n_regimes' {
      di in gr %`cw's " " _c
      if `r' < `n_regimes' {
        di in gr "  " _c
      }
    }
    di
  }
  else {
    di in gr %14s "Regressor" " " "{c |}" " " %`cw's "Coef."
  }

  di in smcl in gr _col(3) "{hline 74}"

  * --- Table rows ---
  forvalues k = 1/`p' {
    local vname = "`varname_`k''"
    local nb = `nb_`k''

    if `nb' == 0 {
      * No breaks: show coefficient in "No breaks" column
      local coef_nb = 0
      local se_nb = 0
      forvalues row = 1/`n_alpha' {
        local ai_k = `alpha_info_mat'[`row', 1]
        if `ai_k' == `k' {
          local coef_nb = `alpha_info_mat'[`row', 5]
          local se_nb = `alpha_info_mat'[`row', 6]
        }
      }

      local tstat_nb = 0
      if `se_nb' > 0 {
        local tstat_nb = `coef_nb' / `se_nb'
      }
      local stars_nb ""
      local pv_nb = 2 * (1 - normal(abs(`tstat_nb')))
      if `pv_nb' < 0.01 {
        local stars_nb "***"
      }
      else if `pv_nb' < 0.05 {
        local stars_nb "**"
      }
      else if `pv_nb' < 0.10 {
        local stars_nb "*"
      }

      local coef_disp : di %8.4f `coef_nb'
      local coef_disp = strtrim("`coef_disp'") + "`stars_nb'"

      * Display row
      di in ye %14s "`vname'" " " in gr "{c |}" " " in ye %`cw's "`coef_disp'" " " in gr "{c |}" _c
      if `n_all_bd' > 0 {
        forvalues r = 1/`n_regimes' {
          di in gr %`cw's " " _c
          if `r' < `n_regimes' {
            di "  " _c
          }
        }
      }
      di
    }
    else {
      * Has breaks: show regime-specific coefficients
      di in ye %14s "`vname'" " " in gr "{c |}" " " %`cw's " " " " "{c |}" _c

      if `n_all_bd' > 0 {
        forvalues r = 1/`n_regimes' {
          * Find the alpha_info row that covers this common regime
          local found_coef = 0
          local reg_coef = 0
          local reg_se = 0
          local mid_t = int((`reg_s_`r'' + `reg_e_`r'') / 2)
          local mid_int = `mid_t' - `Tmin' + 1

          forvalues row = 1/`n_alpha' {
            local ai_k = `alpha_info_mat'[`row', 1]
            local ai_st = `alpha_info_mat'[`row', 3]
            local ai_en = `alpha_info_mat'[`row', 4]
            if `ai_k' == `k' {
              if `mid_int' >= `ai_st' & `mid_int' <= `ai_en' {
                local reg_coef = `alpha_info_mat'[`row', 5]
                local reg_se = `alpha_info_mat'[`row', 6]
                local found_coef = 1
              }
            }
          }

          if `found_coef' == 1 {
            local tstat_r = 0
            if `reg_se' > 0 {
              local tstat_r = `reg_coef' / `reg_se'
            }
            local stars_r ""
            local pv_r = 2 * (1 - normal(abs(`tstat_r')))
            if `pv_r' < 0.01 {
              local stars_r "***"
            }
            else if `pv_r' < 0.05 {
              local stars_r "**"
            }
            else if `pv_r' < 0.10 {
              local stars_r "*"
            }

            local coef_disp : di %8.4f `reg_coef'
            local coef_disp = strtrim("`coef_disp'") + "`stars_r'"
            di in ye %`cw's "`coef_disp'" _c
          }
          else {
            di %`cw's " " _c
          }

          if `r' < `n_regimes' {
            di "  " _c
          }
        }
      }
      di
    }
  }

  di in smcl in gr _col(3) "{hline 74}"
  di in gr _col(3) "{it:* p<0.10, ** p<0.05, *** p<0.01}"
  di

  * ====================================================================
  * GRAPHS (optional)
  * ====================================================================

  if "`graph'" != "" {
    xtcbc_graph, ///
        beta_mat(`beta_hat_mat') nbreaks_mat(`nbreaks_mat') ///
        break_dates_mat(`break_dates_mat') alpha_mat(`alpha_info_mat') ///
        ic_mat(`ic_vec_mat') lambda_mat(`lambda_grid_mat') ///
        initial_mat(`beta_hat_mat') ///
        tmin(`Tmin') tmax(`Tmax') p(`p') ///
        depvar(`depvar') indepvars(`indepvars') ///
        opt_lambda(`opt_lambda') n_obs(`N')
  }

  * ====================================================================
  * STORED RESULTS
  * ====================================================================

  ereturn clear
  ereturn scalar N = `N'
  ereturn scalar T = `TT'
  ereturn scalar p = `p'
  ereturn scalar kappa = `kappa'
  ereturn scalar ngrid = `ngrid'
  ereturn scalar c_const = `constant'
  ereturn scalar opt_lambda = `opt_lambda'
  ereturn scalar total_breaks = `total_breaks'

  ereturn matrix nbreaks = `nbreaks_mat'
  ereturn matrix break_dates = `break_dates_mat'
  ereturn matrix alpha_info = `alpha_info_mat'
  ereturn matrix beta_hat = `beta_hat_mat'
  ereturn matrix ic_values = `ic_vec_mat'

  ereturn local depvar "`depvar'"
  ereturn local indepvars "`indepvars'"
  ereturn local cmd "xtcbc"
  ereturn local cmdline "xtcbc `0'"
  ereturn local title "CBC Breaks - Kaddoura (2025)"

  forvalues k = 1/`p' {
    ereturn scalar nbreaks_`k' = `nb_`k''
  }

end
