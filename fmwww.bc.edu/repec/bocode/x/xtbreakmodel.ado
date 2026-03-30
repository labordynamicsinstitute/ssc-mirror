*! xtbreakmodel.ado — Heterogeneous Structural Breaks in Panel Data
*! Implements: Okui & Wang (2021, JoE), Qian & Su (2016), Baltagi et al. (2016), Li et al. (2025)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0 — 29 March 2026

program define xtbreakmodel, eclass
  version 14.0

  capture findfile _xtbreakmodel_engine.ado
  if _rc {
    di in red "required file _xtbreakmodel_engine.ado not found"
    exit 601
  }
  qui run "`r(fn)'"

  syntax varlist(min=2 ts) [if] [in], Method(string) [ ///
    GRoups(integer 0)       ///
    MAXLambda(real 100)     ///
    MINLambda(real 0.01)    ///
    NGRid(integer 40)       ///
    NSim(integer 50)        ///
    MAXIter(integer 20)     ///
    TOLerance(real 1e-4)    ///
    BANDwidths(numlist)     ///
    C1(real 0.1)            ///
    C2(real 0.025)          ///
    NOGraph                 ///
    Level(cilevel)          ///
  ]

  * Validate method
  local method = lower("`method'")
  if !inlist("`method'", "gagfl", "pls", "bfk", "sara") {
    di in red "method() must be one of: gagfl, pls, bfk, sara"
    exit 198
  }

  if "`method'" == "gagfl" & `groups' < 2 {
    di in red "groups() must be >= 2 for method(gagfl)"
    exit 198
  }

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

  local G = `groups'
  if "`method'" == "pls" local G = 1

  * ====================================================================
  * BUILD DATA MATRICES
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

  local k_idx = 0
  foreach xv of local indepvars {
    local k_idx = `k_idx' + 1
    local varname_`k_idx' "`xv'"
  }

  * ====================================================================
  * DISPATCH TO MATA ENGINE
  * ====================================================================

  if "`method'" == "gagfl" | "`method'" == "pls" {
    mata: _xtbm_run_gagfl(st_matrix("`y_mat'"), st_matrix("`x_mat'"), ///
          `N', `TT', `p', `G', `maxlambda', `minlambda', `ngrid', ///
          `nsim', `maxiter', `tolerance', "`method'")
  }
  else if "`method'" == "bfk" {
    mata: _xtbm_run_bfk(st_matrix("`y_mat'"), st_matrix("`x_mat'"), ///
          `N', `TT', `p')
  }
  else if "`method'" == "sara" {
    if "`bandwidths'" == "" {
      local bandwidths "3 5 8"
    }
    mata: _xtbm_run_sara(st_matrix("`y_mat'"), st_matrix("`x_mat'"), ///
          `N', `TT', `p', "`bandwidths'", `c1')
  }

  * ====================================================================
  * RETRIEVE RESULTS
  * ====================================================================

  tempname res_nbreaks res_regime res_alpha res_se res_group
  tempname res_ssr res_niter

  mata: st_matrix("`res_nbreaks'", xtbm_nbreaks)
  mata: st_matrix("`res_regime'", xtbm_regime)
  mata: st_matrix("`res_alpha'", xtbm_alpha)
  mata: st_matrix("`res_se'", xtbm_se)
  mata: st_numscalar("r_ssr", xtbm_ssr)
  mata: st_numscalar("r_niter", xtbm_niter)
  
  local ssr_val = scalar(r_ssr)
  local niter_val = scalar(r_niter)

  if "`method'" == "gagfl" {
    mata: st_matrix("`res_group'", xtbm_group)
  }

  * ====================================================================
  * DISPLAY: HEADER
  * ====================================================================

  di
  di in smcl in gr "{hline 78}"
  if "`method'" == "gagfl" {
    di in smcl in gr _col(5) "{bf:GAGFL: Grouped Adaptive Group Fused Lasso}"
    di in smcl in gr _col(5) "{bf:Heterogeneous Structural Breaks in Panel Data}"
  }
  else if "`method'" == "pls" {
    di in smcl in gr _col(5) "{bf:AGFL: Adaptive Group Fused Lasso}"
    di in smcl in gr _col(5) "{bf:Common Structural Breaks (Qian & Su, 2016)}"
  }
  else if "`method'" == "bfk" {
    di in smcl in gr _col(5) "{bf:BFK: Sequential Least Squares Break Detection}"
    di in smcl in gr _col(5) "{bf:Baltagi, Feng & Kao (2016)}"
  }
  else if "`method'" == "sara" {
    di in smcl in gr _col(5) "{bf:SaRa: Screening and Ranking Algorithm}"
    di in smcl in gr _col(5) "{bf:Li, Xiao & Chen (2025)}"
  }
  di in smcl in gr "{hline 78}"
  di
  di in gr _col(3) "Dependent variable" _col(26) "= " in ye "`depvar'"
  di in gr _col(3) "Regressors" _col(26) "= " in ye "`indepvars'"
  di in gr _col(3) "Cross-sections (N)" _col(26) "= " in ye "`N'" ///
     in gr _col(45) "Time periods (T)" _col(68) "= " in ye "`TT'"

  if "`method'" == "gagfl" {
    di in gr _col(3) "Number of groups (G)" _col(26) "= " in ye "`G'" ///
       in gr _col(45) "Iterations" _col(68) "= " in ye "`niter_val'"
  }

  if inlist("`method'", "gagfl", "pls") {
    di in gr _col(3) "Lambda range" _col(26) "= " in ye "[`minlambda', `maxlambda']" ///
       in gr _col(45) "Grid points" _col(68) "= " in ye "`ngrid'"
  }

  if "`method'" == "sara" {
    di in gr _col(3) "Bandwidths" _col(26) "= " in ye "`bandwidths'" ///
       in gr _col(45) "IC constant (c1)" _col(68) "= " in ye %8.4f `c1'
  }
  di
  
  * ====================================================================
  * DISPLAY: METHOD-SPECIFIC RESULTS
  * ====================================================================

  if "`method'" == "gagfl" {
    _xtbm_display_gagfl, nbreaks(`res_nbreaks') regime(`res_regime') ///
        alpha(`res_alpha') se(`res_se') group(`res_group') ///
        n(`N') tt(`TT') p(`p') g(`G') ///
        tmin(`Tmin') level(`level') indepvars(`indepvars')
  }
  else if "`method'" == "pls" {
    _xtbm_display_pls, nbreaks(`res_nbreaks') regime(`res_regime') ///
        alpha(`res_alpha') se(`res_se') ///
        n(`N') tt(`TT') p(`p') ///
        tmin(`Tmin') level(`level') indepvars(`indepvars')
  }
  else if "`method'" == "bfk" {
    _xtbm_display_bfk, nbreaks(`res_nbreaks') regime(`res_regime') ///
        alpha(`res_alpha') se(`res_se') ///
        n(`N') tt(`TT') p(`p') ///
        tmin(`Tmin') level(`level') indepvars(`indepvars')
  }
  else if "`method'" == "sara" {
    _xtbm_display_sara, nbreaks(`res_nbreaks') regime(`res_regime') ///
        alpha(`res_alpha') se(`res_se') ///
        n(`N') tt(`TT') p(`p') ///
        tmin(`Tmin') level(`level') indepvars(`indepvars')
  }

  * ====================================================================
  * GRAPHS
  * ====================================================================

  if "`nograph'" == "" {
    capture xtbreakmodel_graph, method(`method') ///
        nbreaks(`res_nbreaks') regime(`res_regime') ///
        alpha(`res_alpha') se(`res_se') ///
        n(`N') tt(`TT') p(`p') g(`G') ///
        tmin(`Tmin') tmax(`Tmax') ///
        depvar(`depvar') indepvars(`indepvars') ///
        level(`level')
  }

  * ====================================================================
  * STORED RESULTS
  * ====================================================================

  ereturn clear
  ereturn scalar N = `N'
  ereturn scalar T = `TT'
  ereturn scalar p = `p'
  ereturn scalar G = `G'
  ereturn scalar ssr = `ssr_val'
  ereturn scalar rmse = sqrt(`ssr_val' / (`N' * `TT'))
  ereturn scalar niter = `niter_val'
  
  ereturn matrix nbreaks = `res_nbreaks'
  ereturn matrix regime = `res_regime'
  ereturn matrix alpha = `res_alpha'
  ereturn matrix se = `res_se'

  if "`method'" == "gagfl" {
    ereturn matrix group = `res_group'
  }

  ereturn local depvar "`depvar'"
  ereturn local indepvars "`indepvars'"
  ereturn local method "`method'"
  ereturn local cmd "xtbreakmodel"
  ereturn local cmdline "xtbreakmodel `0'"

  if "`method'" == "gagfl" {
    ereturn local title "GAGFL - Okui & Wang (2021)"
  }
  else if "`method'" == "pls" {
    ereturn local title "AGFL - Qian & Su (2016)"
  }
  else if "`method'" == "bfk" {
    ereturn local title "BFK - Baltagi, Feng & Kao (2016)"
  }
  else if "`method'" == "sara" {
    ereturn local title "SaRa - Li, Xiao & Chen (2025)"
  }
end

* ====================================================================
* MATA WRAPPER: GAGFL/PLS
* ====================================================================

capture mata: mata drop _xtbm_run_gagfl()
capture mata: mata drop _xtbm_run_bfk()
capture mata: mata drop _xtbm_run_sara()

mata:

void _xtbm_run_gagfl(real matrix y_mat, real matrix x_mat,
                     real scalar NN, real scalar TT, real scalar p,
                     real scalar G, real scalar maxLam, real scalar minLam,
                     real scalar nGrid, real scalar nsim, real scalar maxiter,
                     real scalar tol, string scalar method)
{
    real scalar K, n, i, t, k, g
    real colvector Y
    real matrix X
    
    K = p
    n = NN * TT
    
    // Stack Y: NT x 1
    Y = J(n, 1, 0)
    X = J(n, K, 0)
    for (i = 1; i <= NN; i++) {
        for (t = 1; t <= TT; t++) {
            Y[(i-1)*TT + t] = y_mat[i, t]
            for (k = 1; k <= K; k++) {
                X[(i-1)*TT + t, k] = x_mat[i, (t-1)*K + k]
            }
        }
    }
    
    if (method == "pls") {
        // PLS: common breaks
        real colvector regime_pls
        real matrix alpha_pls, se_pls
        real scalar ssr_pls
        
        // Initial beta: time-by-time OLS (so adaptive weights are informative)
        real matrix b_init, ax_t, ay_t_vec
        real colvector beta_t
        real scalar tt_idx, ii
        b_init = J(TT, K, 0)
        for (tt_idx = 1; tt_idx <= TT; tt_idx++) {
            ax_t = J(NN, K, 0)
            ay_t_vec = J(NN, 1, 0)
            for (ii = 1; ii <= NN; ii++) {
                ax_t[ii, .] = X[(ii-1)*TT + tt_idx, .]
                ay_t_vec[ii] = Y[(ii-1)*TT + tt_idx]
            }
            beta_t = lusolve(cross(ax_t, ax_t), cross(ax_t, ay_t_vec))
            b_init[tt_idx, .] = beta_t'
        }
        
        _xtbm_pls(Y, X, NN, b_init, maxLam, minLam, nGrid,
                  regime_pls, alpha_pls, se_pls, ssr_pls)
        
        real scalar nb_pls
        nb_pls = rows(regime_pls) - 2
        
        external xtbm_nbreaks, xtbm_regime, xtbm_alpha, xtbm_se
        external xtbm_ssr, xtbm_niter, xtbm_group
        
        xtbm_nbreaks = nb_pls
        xtbm_regime = regime_pls
        xtbm_alpha = alpha_pls
        xtbm_se = se_pls
        xtbm_ssr = ssr_pls
        xtbm_niter = 0
        xtbm_group = J(NN, 1, 1)
    }
    else {
        // GAGFL: heterogeneous breaks with groups
        real matrix beta_init_gfe, gi_init
        _xtbm_gfe_est(Y, X, NN, TT, G, beta_init_gfe, gi_init)
        
        real matrix est_regime, est_alpha, est_se, est_group
        real scalar resQ, niter_out
        
        _xtbm_gpls_est(Y, X, NN, TT, G, beta_init_gfe, gi_init,
                       maxLam, minLam, nGrid,
                       est_regime, est_alpha, est_se, est_group,
                       resQ, niter_out)
        
        external xtbm_nbreaks, xtbm_regime, xtbm_alpha, xtbm_se
        external xtbm_ssr, xtbm_niter, xtbm_group
        
        // Compute nbreaks per group
        real colvector nb_vec
        nb_vec = J(G, 1, 0)
        for (g = 1; g <= G; g++) {
            real scalar cnt_nz
            cnt_nz = 0
            for (j = 1; j <= rows(est_regime); j++) {
                if (est_regime[j, g] != 0) cnt_nz++
            }
            nb_vec[g] = cnt_nz - 2
            if (nb_vec[g] < 0) nb_vec[g] = 0
        }
        
        xtbm_nbreaks = nb_vec'
        xtbm_regime = est_regime
        xtbm_alpha = est_alpha
        xtbm_se = est_se
        xtbm_ssr = resQ
        xtbm_niter = niter_out
        xtbm_group = est_group
    }
}

void _xtbm_run_bfk(real matrix y_mat, real matrix x_mat,
                   real scalar NN, real scalar TT, real scalar p)
{
    real scalar K, i, t, k, kk
    real matrix ymat_r, xmat_r
    
    K = p
    ymat_r = y_mat'  // T x N
    
    // Reshape X: T x (N*K)
    xmat_r = J(TT, NN * K, 0)
    for (i = 1; i <= NN; i++) {
        for (t = 1; t <= TT; t++) {
            for (k = 1; k <= K; k++) {
                xmat_r[t, (i-1)*K + k] = x_mat[i, (t-1)*K + k]
            }
        }
    }
    
    // Sequential break detection (simplified: find 3 breaks)
    real scalar bp1, bp2, bp3
    bp1 = _xtbm_bfk_single(NN, TT, xmat_r, ymat_r)
    
    // Second break: search in larger segment
    if (bp1 <= TT/2) {
        real matrix xsub, ysub
        ysub = ymat_r[(bp1+1)..TT, .]
        xsub = xmat_r[(bp1+1)..TT, .]
        bp2 = bp1 + _xtbm_bfk_single(NN, TT - bp1, xsub, ysub)
    }
    else {
        ysub = ymat_r[1..bp1, .]
        xsub = xmat_r[1..bp1, .]
        bp2 = _xtbm_bfk_single(NN, bp1, xsub, ysub)
    }
    
    // Sort breaks
    real colvector bps
    bps = sort((bp1 \ bp2), 1)
    
    // Third break: search in largest remaining segment
    real scalar seg1, seg2, seg3
    seg1 = bps[1]
    seg2 = bps[2] - bps[1]
    seg3 = TT - bps[2]
    
    if (seg1 >= seg2 & seg1 >= seg3 & seg1 > 2) {
        ysub = ymat_r[1..bps[1], .]
        xsub = xmat_r[1..bps[1], .]
        bp3 = _xtbm_bfk_single(NN, bps[1], xsub, ysub)
    }
    else if (seg3 >= seg1 & seg3 >= seg2 & seg3 > 2) {
        ysub = ymat_r[(bps[2]+1)..TT, .]
        xsub = xmat_r[(bps[2]+1)..TT, .]
        bp3 = bps[2] + _xtbm_bfk_single(NN, TT - bps[2], xsub, ysub)
    }
    else if (seg2 > 2) {
        ysub = ymat_r[(bps[1]+1)..bps[2], .]
        xsub = xmat_r[(bps[1]+1)..bps[2], .]
        bp3 = bps[1] + _xtbm_bfk_single(NN, bps[2] - bps[1], xsub, ysub)
    }
    else {
        bp3 = bps[2]  // no valid third break
    }
    
    bps = sort((bps \ bp3), 1)
    // Remove duplicates
    real colvector ubps
    ubps = uniqrows(bps)
    
    // Post-break estimation
    real scalar n_breaks
    n_breaks = rows(ubps)
    
    real colvector regime_bfk
    regime_bfk = 1
    for (i = 1; i <= n_breaks; i++) {
        regime_bfk = regime_bfk \ (ubps[i] + 1)
    }
    regime_bfk = regime_bfk \ (TT + 1)
    
    // Post-PLS estimation for coefficients
    real colvector Y_stack
    real matrix X_stack
    Y_stack = J(NN * TT, 1, 0)
    X_stack = J(NN * TT, K, 0)
    for (i = 1; i <= NN; i++) {
        for (t = 1; t <= TT; t++) {
            Y_stack[(i-1)*TT + t] = y_mat[i, t]
            for (k = 1; k <= K; k++) {
                X_stack[(i-1)*TT + t, k] = x_mat[i, (t-1)*K + k]
            }
        }
    }
    
    real matrix alpha_bfk, se_bfk
    real scalar ssr_bfk
    _xtbm_post_pls(Y_stack, X_stack, NN, regime_bfk, alpha_bfk, ssr_bfk, se_bfk)
    
    external xtbm_nbreaks, xtbm_regime, xtbm_alpha, xtbm_se
    external xtbm_ssr, xtbm_niter, xtbm_group
    
    xtbm_nbreaks = n_breaks
    xtbm_regime = regime_bfk
    xtbm_alpha = alpha_bfk
    xtbm_se = se_bfk
    xtbm_ssr = ssr_bfk
    xtbm_niter = 0
    xtbm_group = J(NN, 1, 1)
}

void _xtbm_run_sara(real matrix y_mat, real matrix x_mat,
                    real scalar NN, real scalar TT, real scalar p,
                    string scalar bw_str, real scalar c1)
{
    real scalar K, i, t, k
    real colvector Y, bandwidths
    real matrix X
    
    K = p
    Y = J(NN * TT, 1, 0)
    X = J(NN * TT, K, 0)
    for (i = 1; i <= NN; i++) {
        for (t = 1; t <= TT; t++) {
            Y[(i-1)*TT + t] = y_mat[i, t]
            for (k = 1; k <= K; k++) {
                X[(i-1)*TT + t, k] = x_mat[i, (t-1)*K + k]
            }
        }
    }
    
    // Parse bandwidths string
    real scalar nbw
    bandwidths = strtoreal(tokens(bw_str))'
    
    real colvector est_breaks
    real scalar est_nbreaks
    
    _xtbm_sara_static(Y, X, NN, TT, bandwidths, c1, 0.5,
                      est_breaks, est_nbreaks)
    
    // Build regime vector
    real colvector regime_sara
    regime_sara = 1
    if (est_nbreaks > 0) {
        for (i = 1; i <= est_nbreaks; i++) {
            regime_sara = regime_sara \ (est_breaks[i] + 1)
        }
    }
    regime_sara = regime_sara \ (TT + 1)
    
    // Post estimation
    real matrix alpha_sara, se_sara
    real scalar ssr_sara
    _xtbm_post_pls(Y, X, NN, regime_sara, alpha_sara, ssr_sara, se_sara)
    
    external xtbm_nbreaks, xtbm_regime, xtbm_alpha, xtbm_se
    external xtbm_ssr, xtbm_niter, xtbm_group
    
    xtbm_nbreaks = est_nbreaks
    xtbm_regime = regime_sara
    xtbm_alpha = alpha_sara
    xtbm_se = se_sara
    xtbm_ssr = ssr_sara
    xtbm_niter = 0
    xtbm_group = J(NN, 1, 1)
}

end

* ====================================================================
* DISPLAY PROGRAMS
* ====================================================================

program _xtbm_display_gagfl
  syntax, nbreaks(name) regime(name) alpha(name) se(name) ///
         group(name) n(integer) tt(integer) p(integer) g(integer) ///
         tmin(integer) level(cilevel) indepvars(string)

  local K = `p'
  local G = `g'
  local za = invnormal(1 - (100 - `level') / 200)

  * --- Group Membership ---
  di in smcl in gr "{hline 78}"
  di in smcl in gr _col(5) "{bf:Group Membership}"
  di in smcl in gr "{hline 78}"
  di
  
  forvalues gg = 1/`G' {
    local ng = 0
    forvalues i = 1/`n' {
      if `group'[`i', `gg'] == 1 {
        local ng = `ng' + 1
      }
    }
    local nb_g = `nbreaks'[1, `gg']
    di in gr _col(3) "Group `gg'" _col(18) ": " in ye "`ng' units" ///
       in gr _col(38) "Structural breaks: " in ye "`nb_g'"
  }
  di

  * --- Break Detection & Coefficients ---
  forvalues gg = 1/`G' {
    local nb_g = `nbreaks'[1, `gg']
    
    di in smcl in gr "{hline 78}"
    di in smcl in gr _col(5) "{bf:Group `gg' — Regime-Specific Estimates}"
    di in smcl in gr "{hline 78}"
    
    if `nb_g' == 0 {
      di in gr _col(5) "{it:No structural breaks detected}"
    }
    else {
      * Show break dates
      di in gr _col(5) "Break dates: " _c
      forvalues bb = 2/`=`nb_g'+1' {
        local bd = `regime'[`bb', `gg']
        local bd_time = `bd' + `tmin' - 1
        if `bb' > 2 di in ye ", " _c
        di in ye "`bd_time'" _c
      }
      di
    }
    di

    * Coefficient table
    di in smcl in gr _col(3) "{hline 72}"
    di in gr _col(3) "Variable" _col(16) "{c |}" ///
       _col(19) "Regime" _col(32) "{c |}" ///
       _col(35) "Coef." _col(47) "{c |}" ///
       _col(49) "Std.Err." _col(60) "{c |}" ///
       _col(62) "z" _col(68) "{c |}" ///
       _col(70) "P>|z|"
    di in smcl in gr _col(3) "{hline 12}{c +}{hline 15}{c +}{hline 14}{c +}{hline 12}{c +}{hline 7}{c +}{hline 8}"

    local n_regimes = `nb_g' + 1
    local kk_idx = 0
    foreach xv of local indepvars {
      local kk_idx = `kk_idx' + 1

      forvalues rr = 1/`n_regimes' {
        local s_t = `regime'[`rr', `gg']
        if `rr' < `n_regimes' {
          local e_t = `regime'[`rr'+1, `gg'] - 1
        }
        else {
          * find next nonzero
          local e_t = `tt'
        }
        
        local s_time = `s_t' + `tmin' - 1
        local e_time = `e_t' + `tmin' - 1
        local rlabel "`s_time'-`e_time'"

        local coef = `alpha'[`rr', (`gg'-1)*`K' + `kk_idx']
        local se_v = `se'[`rr', (`gg'-1)*`K' + `kk_idx']
        
        local tstat = 0
        if `se_v' > 0 {
          local tstat = `coef' / `se_v'
        }
        local pval = 2 * (1 - normal(abs(`tstat')))
        
        local stars ""
        if `pval' < 0.01 local stars "***"
        else if `pval' < 0.05 local stars "**"
        else if `pval' < 0.10 local stars "*"

        local vdisp ""
        if `rr' == 1 local vdisp "`xv'"

        di in gr _col(3) %12s "`vdisp'" " {c |}" ///
           _col(19) in ye %13s "`rlabel'" ///
           _col(32) in gr " {c |}" ///
           _col(34) in ye %11.4f `coef' ///
           _col(47) in gr " {c |}" ///
           _col(49) in ye %10.4f `se_v' ///
           _col(60) in gr " {c |}" ///
           _col(62) in ye %6.2f `tstat' ///
           _col(68) in gr " {c |}" ///
           _col(70) in ye %5.3f `pval' " `stars'"
      }
      if `kk_idx' < `K' {
        di in smcl in gr _col(3) "{hline 12}{c +}{hline 15}{c +}{hline 14}{c +}{hline 12}{c +}{hline 7}{c +}{hline 8}"
      }
    }
    di in smcl in gr _col(3) "{hline 12}{c BT}{hline 15}{c BT}{hline 14}{c BT}{hline 12}{c BT}{hline 7}{c BT}{hline 8}"
    di in gr _col(3) "{it:* p<0.10, ** p<0.05, *** p<0.01}"
    di
  }
end

program _xtbm_display_pls
  syntax, nbreaks(name) regime(name) alpha(name) se(name) ///
         n(integer) tt(integer) p(integer) ///
         tmin(integer) level(cilevel) indepvars(string)

  local K = `p'
  local nb = `nbreaks'[1,1]
  local n_regimes = `nb' + 1

  di in smcl in gr "{hline 78}"
  di in smcl in gr _col(5) "{bf:Break Detection}"
  di in smcl in gr "{hline 78}"
  
  di in gr _col(3) "Number of breaks detected" _col(35) "= " in ye "`nb'"
  
  if `nb' > 0 {
    di in gr _col(3) "Break dates" _col(35) "= " _c
    forvalues bb = 2/`=`nb'+1' {
      local bd = `regime'[`bb', 1]
      local bd_time = `bd' + `tmin' - 1
      if `bb' > 2 di in ye ", " _c
      di in ye "`bd_time'" _c
    }
    di
  }
  di

  * Coefficient table
  di in smcl in gr "{hline 78}"
  di in smcl in gr _col(5) "{bf:Regime-Specific Coefficient Estimates}"
  di in smcl in gr "{hline 78}"
  di

  di in smcl in gr _col(3) "{hline 72}"
  di in gr _col(3) "Variable" _col(16) "{c |}" ///
     _col(19) "Regime" _col(32) "{c |}" ///
     _col(35) "Coef." _col(47) "{c |}" ///
     _col(49) "Std.Err." _col(60) "{c |}" ///
     _col(62) "z" _col(68) "{c |}" ///
     _col(70) "P>|z|"
  di in smcl in gr _col(3) "{hline 12}{c +}{hline 15}{c +}{hline 14}{c +}{hline 12}{c +}{hline 7}{c +}{hline 8}"

  local kk_idx = 0
  foreach xv of local indepvars {
    local kk_idx = `kk_idx' + 1

    forvalues rr = 1/`n_regimes' {
      local s_t = `regime'[`rr', 1]
      if `rr' < `n_regimes' {
        local e_t = `regime'[`rr'+1, 1] - 1
      }
      else {
        local e_t = `tt'
      }
      local s_time = `s_t' + `tmin' - 1
      local e_time = `e_t' + `tmin' - 1
      local rlabel "`s_time'-`e_time'"

      local coef = `alpha'[`rr', `kk_idx']
      local se_v = `se'[`rr', `kk_idx']
      
      local tstat = 0
      if `se_v' > 0 local tstat = `coef' / `se_v'
      local pval = 2 * (1 - normal(abs(`tstat')))
      
      local stars ""
      if `pval' < 0.01 local stars "***"
      else if `pval' < 0.05 local stars "**"
      else if `pval' < 0.10 local stars "*"

      local vdisp ""
      if `rr' == 1 local vdisp "`xv'"

      di in gr _col(3) %12s "`vdisp'" " {c |}" ///
         _col(19) in ye %13s "`rlabel'" ///
         _col(32) in gr " {c |}" ///
         _col(34) in ye %11.4f `coef' ///
         _col(47) in gr " {c |}" ///
         _col(49) in ye %10.4f `se_v' ///
         _col(60) in gr " {c |}" ///
         _col(62) in ye %6.2f `tstat' ///
         _col(68) in gr " {c |}" ///
         _col(70) in ye %5.3f `pval' " `stars'"
    }
  }
  di in smcl in gr _col(3) "{hline 12}{c BT}{hline 15}{c BT}{hline 14}{c BT}{hline 12}{c BT}{hline 7}{c BT}{hline 8}"
  di in gr _col(3) "{it:* p<0.10, ** p<0.05, *** p<0.01}"
  di
end

program _xtbm_display_bfk
  _xtbm_display_pls `0'
end

program _xtbm_display_sara
  _xtbm_display_pls `0'
end
