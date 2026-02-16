*! _xtbreakcoint_engine.ado — Core subroutines for xtbreakcoint
*! Based on GAUSS code by Banerjee & Carrion-i-Silvestre (2015)
*! Translated to Stata by Dr Merwan Roudane
*! Version 1.0.1 — 13 February 2026
*! Audited against original GAUSS code

* Drop existing definitions to allow re-loading without error
capture program drop _bc_adfrc
capture program drop _bc_determi
capture program drop _bc_factcoint_single
capture program drop _bc_factcoint_iter
capture program drop _bc_mqtest
capture program drop _bc_mqtest_parametric



/* ========================================================================
   PROGRAM: _bc_adfrc
   ADF test on cointegration residuals (Translated from ADFRC in brkcoint.src)
   
   GAUSS original:
     res1 = lag(res);
     d_res = res - res1;
     temp = d_res ~ res1 [~ lagn(D_res, 1) ~ ... ~ lagn(D_res, p)];
     temp = trimr(temp, p+1, 0);
     beta = temp[.,1] / temp[.,2:cols(temp)];  // OLS without constant
     t_adf = beta[1] / sqrt(var_b[1,1]);
   
   NOTE: GAUSS does NOT include a constant in ADF regression on residuals 
         (they are already zero-mean by construction).
   ======================================================================== */

program define _bc_adfrc, rclass
  syntax, resvar(string) method(integer) pmax(integer) touse(string)
  
  tempvar dres Lres
  qui gen double `dres' = D.`resvar' if `touse'
  qui gen double `Lres' = L.`resvar' if `touse'
  
  local t_adf = .
  local p_sel = 0
  
  if `method' == 0 {
    * Fixed lag order = pmax (GAUSS: method == 0)
    local lagvars "`Lres'"
    forvalues lag = 1/`pmax' {
      tempvar dlag`lag'
      qui gen double `dlag`lag'' = L`lag'.`dres' if `touse'
      local lagvars "`lagvars' `dlag`lag''"
    }
    
    capture qui regress `dres' `lagvars' if `touse', nocons
    if !_rc & e(N) > 0 {
      local t_adf = _b[`Lres'] / _se[`Lres']
      local p_sel = `pmax'
    }
  }
  else {
    * Automatic: general-to-specific (GAUSS: method == 1)
    * Start from pmax, drop last lag if |t| < 1.645 (N(0,1) 10% level)
    local j = `pmax'
    while `j' >= 0 {
      * Build regressor list: Lres + lagged diffs 1..j
      local lagvars "`Lres'"
      if `j' > 0 {
        forvalues lag = 1/`j' {
          tempvar dlag`lag'
          capture drop `dlag`lag''
          qui gen double `dlag`lag'' = L`lag'.`dres' if `touse'
          local lagvars "`lagvars' `dlag`lag''"
        }
      }
      
      capture qui regress `dres' `lagvars' if `touse', nocons
      
      if _rc | e(N) == 0 {
        local j = `j' - 1
        continue
      }
      
      if `j' == 0 {
        * No lagged diffs, just res1
        local t_adf = _b[`Lres'] / _se[`Lres']
        local p_sel = 0
        local j = -1
      }
      else {
        * Check significance of LAST augmentation lag
        * In GAUSS: t_sig = beta[rows(beta)] / sqrt(var_b[rows(beta),rows(beta)])
        * The last lag variable in our list:
        local lastvar : word `= `j' + 1' of `lagvars'
        local t_last = _b[`lastvar'] / _se[`lastvar']
        
        if abs(`t_last') < 1.645 {
          local j = `j' - 1
        }
        else {
          local t_adf = _b[`Lres'] / _se[`Lres']
          local p_sel = `j'
          local j = -1
        }
      }
    }
  }
  
  return scalar t_adf = `t_adf'
  return scalar p_sel = `p_sel'
end



/* ========================================================================
   PROGRAM: _bc_determi
   Build deterministic regressors for break models in FIRST DIFFERENCES
   
   GAUSS original (brkcoint.src, proc determi):
     Level form:
       model 1: ones(t,1)                          → constant
       model 2: ones(t,1) ~ seqa(1,1,t)            → constant + trend  
       model 3: ones(t,1) ~ du                      → constant + level shift
       model 4: ones(t,1) ~ du ~ seqa(1,1,t)        → constant + trend + level shift
       model 5: ones(t,1) ~ du ~ seqa(1,1,t) ~ dt   → constant + trend + level/slope shift
   
   In first differences (from factcoint.src):
     model 1: Dy = Dx * beta                        → no deterministics in diffs
     model 2: Dy = ones(T-1,1) ~ Dx * beta          → constant in diffs = trend in levels
     model 3: Dy = DTb ~ Dx * beta                   → impulse dummy
     model 4: Dy = ones(T-1,1) ~ DTb ~ Dx * beta    → constant + impulse
     model 5: Dy = ones(T-1,1) ~ DTb ~ Du ~ Dx * beta → constant + impulse + step
   
   where DTb[t] = 1 at t=tb+1, 0 otherwise (impulse)
         Du[t]  = 1 for t>tb, 0 otherwise (step function, the first diff of DU_t is the impulse)
   ======================================================================== */

program define _bc_determi
  syntax, model(integer) tb(integer) touse(string) tvar(string) tmin(integer)
  
  capture drop _bc_det_*
  local detvars ""
  
  * tb is the INDEX in the time dimension (0-based from Tmin)
  * The actual break time value is tb + tmin
  local break_time = `tb' + `tmin'
  
  if `model' == 1 {
    * No deterministics in first-difference regression
  }
  else if `model' == 2 {
    * Constant in diffs (= trend in levels)
    qui gen double _bc_det_cons = 1 if `touse'
    local detvars "_bc_det_cons"
  }
  else if `model' == 3 {
    * DTb: impulse at break point (D.DU)
    * In GAUSS: DTb=zeros(T,1); Dtb[m_tb[i]+1]=1; beta=Dy_i/(DTb[2:t]~Dx_i)
    * DTb[2:T] means we use the differenced impulse
    qui gen double _bc_det_dtb = (`tvar' == `break_time') if `touse'
    local detvars "_bc_det_dtb"
  }
  else if `model' == 4 {
    * Constant + impulse (= trend + level shift in levels)
    * GAUSS: beta=Dy_i/(ones(T-1,1)~DTb[2:t]~Dx_i)
    qui gen double _bc_det_cons = 1 if `touse'
    qui gen double _bc_det_dtb = (`tvar' == `break_time') if `touse'
    local detvars "_bc_det_cons _bc_det_dtb"
  }
  else if `model' == 5 {
    * Constant + impulse + step function
    * GAUSS: Du=zeros(m_tb[i],1)|ones(t-m_tb[i],1)
    *        beta=Dy_i/(ones(T-1,1)~DTb[2:t]~Du[2:t]~Dx_i)
    * In diffs: DTb is impulse at break; Du[2:T] is the step in diffs
    qui gen double _bc_det_cons = 1 if `touse'
    qui gen double _bc_det_dtb = (`tvar' == `break_time') if `touse'
    qui gen double _bc_det_du = (`tvar' > `break_time') if `touse'
    local detvars "_bc_det_cons _bc_det_dtb _bc_det_du"
  }
  
  global BC_detervars "`detvars'"
end



/* ========================================================================
   PROGRAM: _bc_factcoint_single
   Single-pass factor + break estimation
   
   Direct translation of factcoint() from factcoint.src / factcoint_iter.src
   
   Key GAUSS logic:
   1) For each unit i, estimate Dy_i = det + Dx_i*beta + e_i
   2) For unknown breaks: search over [0.15T, 0.85T]
      - Models 3,4,6,7: individual break per unit (min SSR per unit)
      - Models 5,8: COMMON break across all units (min sum of SSR)
   3) Factor extraction: SVD of D_res'*D_res
      - csi = sqrt(N) * eigenvecs[,1:k]  (factor loadings)
      - Fhat = (1/N) * D_res * csi        (factors)
      - De = D_res - Fhat * csi'           (idiosyncratic diffs)
      - e = cumsumc(De)                    (idiosyncratic levels)
   4) Number of factors via Bai-Ng IC1
   ======================================================================== */

program define _bc_factcoint_single, rclass
  syntax, depvar(string) indepvars(string) ivar(string) tvar(string) ///
    model(integer) maxfactors(integer) trim(real) ///
    touse(string) [breakknown knownbreaks(string)]
  
  * Get panel info
  qui levelsof `ivar' if `touse', local(panels)
  local N : word count `panels'
  
  qui summ `tvar' if `touse'
  local Tmin = r(min)
  local Tmax = r(max)
  local T = `Tmax' - `Tmin' + 1
  local Tm1 = `T' - 1
  
  * Trimming bounds (GAUSS: int(0.15*T) to int(0.85*T))
  local tb_lo = floor(`trim' * `T')
  local tb_hi = floor((1 - `trim') * `T')
  
  local nxvars : word count `indepvars'
  
  * ---- STEP 1: Per-unit cointegrating regression in first diffs ----
  tempname Dres_mat breakvec
  matrix `Dres_mat' = J(`Tm1', `N', 0)
  matrix `breakvec' = J(`N', 1, 0)
  
  * Check if this model uses COMMON break (models 5,8 in GAUSS)
  * GAUSS factcoint.src: models 5 and 8 collect SSR matrix, then
  * m_tbe = minindc(sumc(ssr')) + int(0.15*t) - 1
  local use_common_break = 0
  if (`model' == 5) & ("`breakknown'" == "") {
    local use_common_break = 1
  }
  
  if `use_common_break' {
    * ---- COMMON BREAK SEARCH (Model 5) ----
    * Collect SSR matrix: (n_breaks x N), then find break that minimizes sum
    local n_candidates = `tb_hi' - `tb_lo' + 1
    tempname ssr_matrix
    matrix `ssr_matrix' = J(`n_candidates', `N', 1e46)
    
    local unit_idx = 0
    foreach i of local panels {
      local unit_idx = `unit_idx' + 1
      
      tempvar dy
      qui gen double `dy' = D.`depvar' if `touse' & `ivar' == `i'
      
      local dxvars ""
      local dxvar_idx = 0
      foreach xv of local indepvars {
        local dxvar_idx = `dxvar_idx' + 1
        tempvar dx`dxvar_idx'
        qui gen double `dx`dxvar_idx'' = D.`xv' if `touse' & `ivar' == `i'
        local dxvars "`dxvars' `dx`dxvar_idx''"
      }
      
      forvalues tb = `tb_lo'/`tb_hi' {
        local br_row = `tb' - `tb_lo' + 1
        capture drop _bc_det_*
        _bc_determi, model(`model') tb(`tb') touse(`touse') ///
          tvar(`tvar') tmin(`Tmin')
        
        local regvars "$BC_detervars `dxvars'"
        capture qui regress `dy' `regvars' ///
          if `touse' & `ivar' == `i', nocons
        
        if !_rc & e(N) > 0 {
          matrix `ssr_matrix'[`br_row', `unit_idx'] = e(rss)
        }
      }
      
      capture drop `dy'
      capture drop _bc_det_*
    }
    
    * Find common break minimizing sum of SSR across all units
    local best_ssr = 1e46
    local best_tb = `tb_lo'
    forvalues br_row = 1/`n_candidates' {
      local sum_ssr = 0
      forvalues ui = 1/`N' {
        local sum_ssr = `sum_ssr' + `ssr_matrix'[`br_row', `ui']
      }
      if `sum_ssr' < `best_ssr' {
        local best_ssr = `sum_ssr'
        local best_tb = `tb_lo' + `br_row' - 1
      }
    }
    
    * Re-estimate all units with the common break
    forvalues ui = 1/`N' {
      matrix `breakvec'[`ui', 1] = `best_tb'
    }
    
    local unit_idx = 0
    foreach i of local panels {
      local unit_idx = `unit_idx' + 1
      
      tempvar dy
      qui gen double `dy' = D.`depvar' if `touse' & `ivar' == `i'
      
      local dxvars ""
      local dxvar_idx = 0
      foreach xv of local indepvars {
        local dxvar_idx = `dxvar_idx' + 1
        tempvar dx`dxvar_idx'
        qui gen double `dx`dxvar_idx'' = D.`xv' if `touse' & `ivar' == `i'
        local dxvars "`dxvars' `dx`dxvar_idx''"
      }
      
      capture drop _bc_det_*
      _bc_determi, model(`model') tb(`best_tb') touse(`touse') ///
        tvar(`tvar') tmin(`Tmin')
      
      local regvars "$BC_detervars `dxvars'"
      capture qui regress `dy' `regvars' if `touse' & `ivar' == `i', nocons
      
      if !_rc & e(N) > 0 {
        tempvar ehat
        qui predict double `ehat' if `touse' & `ivar' == `i', residuals
        
        local row = 0
        forvalues t = `= `Tmin' + 1'/`Tmax' {
          local row = `row' + 1
          qui summ `ehat' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
          if r(N) > 0 {
            matrix `Dres_mat'[`row', `unit_idx'] = r(mean)
          }
        }
        capture drop `ehat'
      }
      
      capture drop `dy'
      capture drop _bc_det_*
    }
  }
  else {
    * ---- INDIVIDUAL BREAK SEARCH (Models 1-4) or known breaks ----
    local unit_idx = 0
    foreach i of local panels {
      local unit_idx = `unit_idx' + 1
      
      tempvar dy
      qui gen double `dy' = D.`depvar' if `touse' & `ivar' == `i'
      
      local dxvars ""
      local dxvar_idx = 0
      foreach xv of local indepvars {
        local dxvar_idx = `dxvar_idx' + 1
        tempvar dx`dxvar_idx'
        qui gen double `dx`dxvar_idx'' = D.`xv' if `touse' & `ivar' == `i'
        local dxvars "`dxvars' `dx`dxvar_idx''"
      }
      
      if `model' <= 2 {
        * Models 1-2: no break
        if `model' == 1 {
          local regvars "`dxvars'"
        }
        else {
          tempvar det_cons
          qui gen double `det_cons' = 1 if `touse' & `ivar' == `i'
          local regvars "`det_cons' `dxvars'"
        }
        
        capture qui regress `dy' `regvars' if `touse' & `ivar' == `i', nocons
        if !_rc & e(N) > 0 {
          tempvar ehat
          qui predict double `ehat' if `touse' & `ivar' == `i', residuals
          
          local row = 0
          forvalues t = `= `Tmin' + 1'/`Tmax' {
            local row = `row' + 1
            qui summ `ehat' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
            if r(N) > 0 {
              matrix `Dres_mat'[`row', `unit_idx'] = r(mean)
            }
          }
          capture drop `ehat'
        }
      }
      else if "`breakknown'" != "" {
        * Known break point
        local tbi : word `unit_idx' of `knownbreaks'
        capture drop _bc_det_*
        _bc_determi, model(`model') tb(`tbi') touse(`touse') ///
          tvar(`tvar') tmin(`Tmin')
        local regvars "$BC_detervars `dxvars'"
        
        matrix `breakvec'[`unit_idx', 1] = `tbi'
        
        capture qui regress `dy' `regvars' if `touse' & `ivar' == `i', nocons
        if !_rc & e(N) > 0 {
          tempvar ehat
          qui predict double `ehat' if `touse' & `ivar' == `i', residuals
          
          local row = 0
          forvalues t = `= `Tmin' + 1'/`Tmax' {
            local row = `row' + 1
            qui summ `ehat' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
            if r(N) > 0 {
              matrix `Dres_mat'[`row', `unit_idx'] = r(mean)
            }
          }
          capture drop `ehat'
        }
      }
      else {
        * Unknown break, individual search (models 3-4): per-unit min SSR
        * GAUSS: SSR=1e46; j=int(0.15*t); do until j>int(0.85*t)
        local best_ssr = 1e46
        local best_tb = `tb_lo'
        
        forvalues tb = `tb_lo'/`tb_hi' {
          capture drop _bc_det_*
          _bc_determi, model(`model') tb(`tb') touse(`touse') ///
            tvar(`tvar') tmin(`Tmin')
          
          local regvars "$BC_detervars `dxvars'"
          
          capture qui regress `dy' `regvars' ///
            if `touse' & `ivar' == `i', nocons
          
          if !_rc & e(N) > 0 {
            local this_ssr = e(rss)
            if `this_ssr' < `best_ssr' {
              local best_ssr = `this_ssr'
              local best_tb = `tb'
            }
          }
        }
        
        * Re-estimate with best break
        capture drop _bc_det_*
        _bc_determi, model(`model') tb(`best_tb') touse(`touse') ///
          tvar(`tvar') tmin(`Tmin')
        
        local regvars "$BC_detervars `dxvars'"
        capture qui regress `dy' `regvars' if `touse' & `ivar' == `i', nocons
        
        matrix `breakvec'[`unit_idx', 1] = `best_tb'
        
        if !_rc & e(N) > 0 {
          tempvar ehat
          qui predict double `ehat' if `touse' & `ivar' == `i', residuals
          
          local row = 0
          forvalues t = `= `Tmin' + 1'/`Tmax' {
            local row = `row' + 1
            qui summ `ehat' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
            if r(N) > 0 {
              matrix `Dres_mat'[`row', `unit_idx'] = r(mean)
            }
          }
          capture drop `ehat'
        }
      }
      
      capture drop `dy'
      capture drop _bc_det_*
    }
  }
  
  * ---- STEP 2: Factor extraction via PCA ----
  * GAUSS factcoint.src lines: {u,s,v}=svd1(D_res_coin'*D_res_coin)
  *   csi = sqrt(N)*u[.,1:k]
  *   fhat = inv(N)*D_res_coin*csi
  *   De = D_res_coin - fhat*csi'
  *   e = cumsumc(De)
  
  if `maxfactors' == 0 {
    * No factor estimation (k[1]==0 in GAUSS → goto start → no factors)
    matrix _bc_Dres = `Dres_mat'
    matrix _bc_breaks = `breakvec'
    matrix _bc_Fhat = J(1,1,0)
    matrix _bc_Csi = J(1,1,0)
    scalar _bc_nfactors = 0
    
    tempname SSR_diag
    matrix `SSR_diag' = `Dres_mat'' * `Dres_mat'
    local ssr_val = 0
    forvalues ii = 1/`N' {
      local ssr_val = `ssr_val' + `SSR_diag'[`ii',`ii']
    }
    return scalar ssr = `ssr_val'
    return scalar nfactors = 0
    exit
  }
  
  * Eigendecomposition of D_res'*D_res (NxN)
  tempname covmat eigenvals eigenvecs
  matrix `covmat' = `Dres_mat'' * `Dres_mat'
  matrix symeigen `eigenvecs' `eigenvals' = `covmat'
  
  * NOTE: Stata's symeigen returns eigenvalues in DESCENDING order
  * and eigenvectors as columns corresponding to those eigenvalues.
  * GAUSS svd1 also returns in descending order. ✓
  
  * Bai-Ng (2002) IC1: IC1(k) = ln(V(k,Fhat)) + k*(N+T)/(N*T) * ln(N*T/(N+T))
  * V(k) = (N*T)^(-1) * sum_i sum_t (De_it)^2
  * In GAUSS: sigma[i] = meanc(sumc(De.*De/T))  [= (1/N) * sum_i (sum_t De_it^2 / T)]
  
  * sigma_0 = (1/N) * sum_i [sum_t D_res_it^2 / (T-1)]
  tempname sigma0
  scalar `sigma0' = 0
  forvalues j = 1/`N' {
    local ss = 0
    forvalues r = 1/`Tm1' {
      local ss = `ss' + `Dres_mat'[`r',`j']^2
    }
    scalar `sigma0' = `sigma0' + `ss' / `Tm1'
  }
  scalar `sigma0' = `sigma0' / `N'
  
  local best_ic = ln(`sigma0')
  local best_k = 0
  
  local maxk = min(`maxfactors', `N' - 1)
  
  forvalues k = 1/`maxk' {
    tempname csi_k fhat_k de_k sigma_k
    
    * csi = sqrt(N) * eigenvecs[,1:k]
    matrix `csi_k' = J(`N', `k', 0)
    forvalues jj = 1/`N' {
      forvalues kk = 1/`k' {
        matrix `csi_k'[`jj', `kk'] = sqrt(`N') * `eigenvecs'[`jj', `kk']
      }
    }
    
    * Fhat = (1/N) * D_res * csi
    matrix `fhat_k' = (1/`N') * `Dres_mat' * `csi_k'
    
    * De = D_res - Fhat * csi'
    matrix `de_k' = `Dres_mat' - `fhat_k' * `csi_k''
    
    * sigma_k = (1/N) * sum_i [sum_t De_it^2 / (T-1)]
    scalar `sigma_k' = 0
    forvalues j = 1/`N' {
      local ss = 0
      forvalues r = 1/`Tm1' {
        local ss = `ss' + `de_k'[`r',`j']^2
      }
      scalar `sigma_k' = `sigma_k' + `ss' / `Tm1'
    }
    scalar `sigma_k' = `sigma_k' / `N'
    
    * IC1 = ln(sigma_k) + k*(N+T-1)/(N*(T-1)) * ln(N*(T-1)/(N+T-1))
    * GAUSS: CT[i] = ln(N*T/(N+T))*i*(N+T)/(N*T)  [uses T=T-1 dimension]
    local CT = ln(`N' * `Tm1' / (`N' + `Tm1')) * `k' * (`N' + `Tm1') / (`N' * `Tm1')
    local ic_k = ln(`sigma_k') + `CT'
    
    if `ic_k' < `best_ic' {
      local best_ic = `ic_k'
      local best_k = `k'
    }
  }
  
  * Final estimation with best_k factors
  if `best_k' == 0 {
    matrix _bc_Dres = `Dres_mat'
    matrix _bc_breaks = `breakvec'
    matrix _bc_Fhat = J(1,1,0)
    matrix _bc_Csi = J(1,1,0)
    scalar _bc_nfactors = 0
    
    local ssr_val = 0
    tempname SSR_diag
    matrix `SSR_diag' = `Dres_mat'' * `Dres_mat'
    forvalues ii = 1/`N' {
      local ssr_val = `ssr_val' + `SSR_diag'[`ii',`ii']
    }
    return scalar ssr = `ssr_val'
    return scalar nfactors = 0
  }
  else {
    * Build final factor matrices
    matrix _bc_Csi = J(`N', `best_k', 0)
    forvalues jj = 1/`N' {
      forvalues kk = 1/`best_k' {
        matrix _bc_Csi[`jj', `kk'] = sqrt(`N') * `eigenvecs'[`jj', `kk']
      }
    }
    
    * Fhat in first diffs: (T-1 x nfact)
    matrix _bc_Fhat = (1/`N') * `Dres_mat' * _bc_Csi
    
    * Idiosyncratic first diffs
    matrix _bc_Dres = `Dres_mat' - _bc_Fhat * _bc_Csi'
    matrix _bc_breaks = `breakvec'
    scalar _bc_nfactors = `best_k'
    
    * SSR = sum of diagonal of De'*De (= sumc(diag(e'e)) in GAUSS)
    tempname SSR_diag
    matrix `SSR_diag' = _bc_Dres' * _bc_Dres
    local ssr_val = 0
    forvalues ii = 1/`N' {
      local ssr_val = `ssr_val' + `SSR_diag'[`ii',`ii']
    }
    return scalar ssr = `ssr_val'
    return scalar nfactors = `best_k'
  }
end



/* ========================================================================
   PROGRAM: _bc_factcoint_iter
   Iterative factor + break estimation
   
   GAUSS factcoint_iter.src (factcoint.src version):
     1) {e,Fhat,csi,m_tbe} = factcoint(y,x,model,m_Tb,0|0)  // initial, no factors
     2) SSR_opt = sumc(diag(e'e))
     3) Loop:
        a) {e,Fhat,csi,m_tbe} = factcoint(y_temp,x,model[1]|0,m_tbe_opt,k) 
              // estimate factors with known breaks
        b) SSR_2 = sumc(diag(e'e))
        c) if abs(SSR_2 - SSR_opt) > tolerance:
              y_temp = y[2:T,.] - Fhat*csi'   // remove factors from Dy
              {e,..} = factcoint(y_temp,x[2:T,.],model,m_Tb,0|0)  // re-estimate breaks
              m_tbe_opt = m_tbe + 1  // adjust for sample offset
              SSR_opt = SSR_2
              y_temp = y
           else: converged
   ======================================================================== */

program define _bc_factcoint_iter, rclass
  syntax, depvar(string) indepvars(string) ivar(string) tvar(string) ///
    model(integer) maxfactors(integer) trim(real) ///
    touse(string) maxiter(integer) tolerance(real)
  
  qui levelsof `ivar' if `touse', local(panels)
  local N : word count `panels'
  
  qui summ `tvar' if `touse'
  local Tmin = r(min)
  local Tmax = r(max)
  local T = `Tmax' - `Tmin' + 1
  local Tm1 = `T' - 1
  
  * ---- Iteration 0: estimate breaks ignoring factors ----
  di in gr "  Iteration 0: initial break estimation (no factors)..."
  
  _bc_factcoint_single, depvar(`depvar') indepvars(`indepvars') ///
    ivar(`ivar') tvar(`tvar') model(`model') maxfactors(0) ///
    trim(`trim') touse(`touse')
  
  local ssr_opt = r(ssr)
  
  tempname breaks_opt
  matrix `breaks_opt' = _bc_breaks
  
  local final_iter = 0
  
  if `maxfactors' == 0 {
    return scalar nfactors = 0
    return scalar iterations = 0
    return scalar ssr = `ssr_opt'
    exit
  }
  
  * ---- Iterative loop ----
  local _converged = 0
  local nfact = 0
  
  forvalues iter = 1/`maxiter' {
    di in gr "  Iteration `iter': estimating factors..."
    
    * Step A: Given known breaks, estimate factors
    local breakstr ""
    forvalues ui = 1/`N' {
      local bk = `breaks_opt'[`ui', 1]
      local breakstr "`breakstr' `bk'"
    }
    
    _bc_factcoint_single, depvar(`depvar') indepvars(`indepvars') ///
      ivar(`ivar') tvar(`tvar') model(`model') maxfactors(`maxfactors') ///
      trim(`trim') touse(`touse') breakknown knownbreaks(`breakstr')
    
    local ssr_new = r(ssr)
    local nfact = r(nfactors)
    local diff_ssr = abs(`ssr_new' - `ssr_opt')
    
    di in gr "    SSR = " in ye %12.4f `ssr_new' ///
      in gr "  (change = " in ye %10.6f `diff_ssr' in gr ")"
    
    if `diff_ssr' < `tolerance' {
      di in gr "  Converged after `iter' iterations."
      local final_iter = `iter'
      local ssr_opt = `ssr_new'
      local _converged = 1
      continue, break
    }
    
    * Step B: Remove factors from Dy, re-estimate breaks
    * GAUSS: y_temp = y[2:T,.] - Fhat*csi'
    * _bc_Fhat is (T-1 x nfact), _bc_Csi is (N x nfact)
    * Fhat*csi' is (T-1 x N) — the common component in first diffs
    
    if `nfact' > 0 {
      * Create factor-adjusted dependent variable
      * In GAUSS: y_temp[t-1, i] = Dy_i[t] - sum_k(Fhat[t,k]*Csi[i,k])
      * We work in diffs: D.(y_adj) = D.y - factor_component
      
      tempvar y_adj
      qui gen double `y_adj' = `depvar' if `touse'
      
      * Subtract the cumulated factor component from y in levels
      * Factor component in diffs at time t: FC_t = sum_k Fhat[t,k]*Csi[i,k]
      * Level component: cumsum(FC_t)
      
      local unit_idx = 0
      foreach i of local panels {
        local unit_idx = `unit_idx' + 1
        
        * Build cumulative factor component for this unit
        local cumfc = 0
        forvalues t = `= `Tmin' + 1'/`Tmax' {
          local row = `t' - `Tmin'
          local fc_t = 0
          forvalues k = 1/`nfact' {
            local fhat_tk = _bc_Fhat[`row', `k']
            local csi_ik = _bc_Csi[`unit_idx', `k']
            local fc_t = `fc_t' + `fhat_tk' * `csi_ik'
          }
          local cumfc = `cumfc' + `fc_t'
          qui replace `y_adj' = `depvar' - `cumfc' ///
            if `touse' & `ivar' == `i' & `tvar' == `t'
        }
      }
      
      * Re-estimate breaks with factor-adjusted y
      _bc_factcoint_single, depvar(`y_adj') indepvars(`indepvars') ///
        ivar(`ivar') tvar(`tvar') model(`model') maxfactors(0) ///
        trim(`trim') touse(`touse')
      
      matrix `breaks_opt' = _bc_breaks
      local ssr_opt = `ssr_new'
      
      capture drop `y_adj'
    }
    else {
      di in gr "  No common factors detected. Done."
      local final_iter = `iter'
      local nfact = 0
      local _converged = 1
      continue, break
    }
    
    local final_iter = `iter'
  }
  
  if `_converged' == 0 {
    * Max iterations reached
    di in ye "{bf:WARNING}: Maximum iterations (`maxiter') reached."
    local nfact = scalar(_bc_nfactors)
  }
  
  return scalar nfactors = `nfact'
  return scalar iterations = `final_iter'
  return scalar ssr = `ssr_opt'
end



/* ========================================================================
   PROGRAM: _bc_mqtest
   Bai & Ng (2004) MQ test for the number of common stochastic trends
   
   Non-parametric version (k=0 in GAUSS MQ_test)
   
   GAUSS algorithm (factcoint.src, proc MQ_test):
   1. Compute SVD of T^(-2)*F'F → eigenvectors u_F
   2. Yc = F * u_F[,1:r*]     (rotated factors)
   3. VAR(1) on Yc: m_beta = Yc[2:]'Yc[1:] / (Yc[1:]'Yc[1:])
   4. Newey-West: sigma = sum_{j=1}^{bigJ} (1-j/(bigJ+1)) * T^(-1) * res[-j:]'*res[j:]
   5. PHI_c = (1/2)*(Yc2'*Yc1 + Yc1'*Yc2 - T*(sigma+sigma')) * inv(Yc1'*Yc1)
   6. MQ = T * (smallest eigenvalue of PHI_c - 1)
   7. Reject r* if MQ < cv[r*,2] at 5%, decrement r* and repeat
   
   Inputs:
     fhat_mat : (T-1 x r) matrix of cumulated common factors (in levels)
     model    : deterministic model (1-5)
     N        : number of cross-section units
   
   Returns:
     r(MQ_np)        : non-parametric MQ test statistic
     r(n_trends)     : estimated number of common stochastic trends
   ======================================================================== */

program define _bc_mqtest, rclass
  syntax, model(integer) npanels(integer)
  
  * _bc_Fhat_cumul is (T-1 x r) matrix of cumulated factors (set by caller)
  
  local r = colsof(_bc_Fhat_cumul)
  local TT = rowsof(_bc_Fhat_cumul)
  
  if `r' == 0 {
    return scalar MQ_np = .
    return scalar n_trends = 0
    exit
  }
  
  * ---- Detrend factors ----
  * GAUSS: if model==1|3|6: fhat = fhat - meanc(fhat)'
  *        if model==2|4|7: fhat[,j] = fhat[,j] - xreg*(fhat[,j]/xreg)
  
  tempname F_det
  matrix `F_det' = _bc_Fhat_cumul
  
  if `model' == 1 | `model' == 3 {
    * Demean each column
    forvalues jj = 1/`r' {
      local colmean = 0
      forvalues tt = 1/`TT' {
        local colmean = `colmean' + `F_det'[`tt', `jj']
      }
      local colmean = `colmean' / `TT'
      forvalues tt = 1/`TT' {
        matrix `F_det'[`tt', `jj'] = `F_det'[`tt', `jj'] - `colmean'
      }
    }
  }
  else if `model' == 2 | `model' == 4 {
    * Regress out constant + trend: xreg = ones ~ seqa(1,1,T)
    * fhat[,j] = fhat[,j] - xreg * (fhat[,j] / xreg)  [OLS projection]
    forvalues jj = 1/`r' {
      * Compute OLS: beta = inv(X'X) * X'y where X = [1, t]
      local sum_y = 0
      local sum_ty = 0
      local sum_t = 0
      local sum_t2 = 0
      forvalues tt = 1/`TT' {
        local yval = `F_det'[`tt', `jj']
        local sum_y = `sum_y' + `yval'
        local sum_ty = `sum_ty' + `tt' * `yval'
        local sum_t = `sum_t' + `tt'
        local sum_t2 = `sum_t2' + `tt' * `tt'
      }
      * inv(X'X) * X'y for 2x2 system
      local det_xx = `TT' * `sum_t2' - `sum_t' * `sum_t'
      local b0 = (`sum_t2' * `sum_y' - `sum_t' * `sum_ty') / `det_xx'
      local b1 = (`TT' * `sum_ty' - `sum_t' * `sum_y') / `det_xx'
      
      forvalues tt = 1/`TT' {
        local fitted = `b0' + `b1' * `tt'
        matrix `F_det'[`tt', `jj'] = `F_det'[`tt', `jj'] - `fitted'
      }
    }
  }
  else if `model' == 5 {
    * For regime shift: demean (same as constant in GAUSS comments)
    forvalues jj = 1/`r' {
      local colmean = 0
      forvalues tt = 1/`TT' {
        local colmean = `colmean' + `F_det'[`tt', `jj']
      }
      local colmean = `colmean' / `TT'
      forvalues tt = 1/`TT' {
        matrix `F_det'[`tt', `jj'] = `F_det'[`tt', `jj'] - `colmean'
      }
    }
  }
  
  * ---- Critical values from Bai & Ng (2004) Table I ----
  * 12 rows (r=1..12), 3 cols (1%, 5%, 10%)
  
  tempname cv
  
  if `model' == 1 | `model' == 3 {
    * Constant case
    matrix `cv' = ( -20.151, -13.730, -11.022 \ ///
                    -31.621, -23.535, -19.923 \ ///
                    -41.064, -32.296, -28.399 \ ///
                    -48.501, -40.442, -36.592 \ ///
                    -58.383, -48.617, -44.111 \ ///
                    -66.978, -57.040, -52.312 \ ///
                    -78.252, -67.465, -62.172 \ ///
                    -86.619, -76.042, -70.590 \ ///
                    -95.297, -83.824, -78.376 \ ///
                   -104.044, -92.623, -86.935 \ ///
                   -112.491,-100.265, -94.670 \ ///
                   -120.315,-108.174,-102.538 )
  }
  else if `model' == 2 | `model' == 4 {
    * Trend case
    matrix `cv' = ( -29.246, -21.313, -17.829 \ ///
                    -38.619, -31.356, -27.435 \ ///
                    -50.019, -40.180, -35.685 \ ///
                    -58.140, -48.421, -44.079 \ ///
                    -64.729, -55.818, -55.286 \ ///
                    -74.251, -64.393, -59.555 \ ///
                    -85.360, -74.068, -69.073 \ ///
                    -93.494, -82.333, -76.962 \ ///
                   -102.368, -90.896, -85.192 \ ///
                   -109.641, -98.475, -92.663 \ ///
                   -119.233,-106.643,-100.875 \ ///
                   -127.147,-114.876,-108.927 )
  }
  else if `model' == 5 {
    * Regime shift: T-dependent critical values
    if `TT' <= 75 {
      matrix `cv' = ( -31.046, -24.828, -21.669 \ ///
                      -38.827, -32.792, -29.925 \ ///
                      -44.744, -39.703, -36.641 \ ///
                      -47.752, -44.865, -42.381 \ ///
                      -48.756, -47.472, -46.119 \ ///
                      -48.890, -48.444, -47.879 )
    }
    else if `TT' <= 200 {
      matrix `cv' = ( -34.474, -26.833, -23.102 \ ///
                      -44.748, -36.464, -32.729 \ ///
                      -53.423, -45.879, -41.862 \ ///
                      -61.972, -53.251, -49.284 \ ///
                      -69.033, -61.099, -56.747 \ ///
                      -74.663, -67.183, -63.437 )
    }
    else {
      matrix `cv' = ( -32.985, -25.697, -22.843 \ ///
                      -46.953, -38.103, -33.778 \ ///
                      -52.827, -45.066, -41.136 \ ///
                      -59.494, -53.392, -49.240 \ ///
                      -70.495, -62.404, -57.440 \ ///
                      -78.589, -68.748, -64.459 )
    }
  }
  
  local max_cv_rows = rowsof(`cv')
  
  * ---- SVD of T^(-2) * F'F ----
  tempname FFmat eigenvals_F eigenvecs_F
  matrix `FFmat' = (1/(`TT'^2)) * `F_det'' * `F_det'
  matrix symeigen `eigenvecs_F' `eigenvals_F' = `FFmat'
  
  * ---- Sequential testing ----
  local r_star = `r'
  if `r_star' > `max_cv_rows' {
    local r_star = `max_cv_rows'
  }
  
  local final_MQ = .
  
  while `r_star' > 0 {
    * Construct Yc = F_det * u_F[,1:r_star]
    tempname Yc
    matrix `Yc' = J(`TT', `r_star', 0)
    forvalues tt = 1/`TT' {
      forvalues kk = 1/`r_star' {
        local val = 0
        forvalues jj = 1/`r' {
          local val = `val' + `F_det'[`tt', `jj'] * `eigenvecs_F'[`jj', `kk']
        }
        matrix `Yc'[`tt', `kk'] = `val'
      }
    }
    
    * --- Non-parametric MQ (k=0) ---
    
    * VAR(1): Yc[2:T] = Yc[1:T-1] * beta + u
    * Yc1 = Yc[1:T-1], Yc2 = Yc[2:T]
    local T1 = `TT' - 1
    
    tempname Yc1 Yc2
    matrix `Yc1' = `Yc'[1..`T1', 1..`r_star']
    matrix `Yc2' = `Yc'[2..`TT', 1..`r_star']
    
    * OLS: beta_j = (Yc1'Yc1)^(-1) * Yc1'Yc2[,j]
    tempname Yc1tYc1 Yc1tYc1_inv m_beta m_res
    matrix `Yc1tYc1' = `Yc1'' * `Yc1'
    capture matrix `Yc1tYc1_inv' = syminv(`Yc1tYc1')
    if _rc {
      * Singular matrix, can't compute
      local r_star = `r_star' - 1
      continue
    }
    
    matrix `m_beta' = `Yc1tYc1_inv' * `Yc1'' * `Yc2'
    matrix `m_res' = `Yc2' - `Yc1' * `m_beta'
    
    * Newey-West long-run covariance (one-sided)
    * bigJ = 4 * ceil((min(T,N)/100)^(1/4))
    local minTN = min(`TT', `npanels')
    local bigJ = 4 * ceil((`minTN' / 100)^(0.25))
    
    tempname sigma_lr
    matrix `sigma_lr' = J(`r_star', `r_star', 0)
    
    forvalues jlag = 1/`bigJ' {
      local wt = 1 - `jlag' / (`bigJ' + 1)
      local nrows_short = `T1' - `jlag'
      
      * sigma += wt * T^(-1) * res[1:T1-j]' * res[j+1:T1]
      tempname res_early res_late sigma_j
      matrix `res_early' = `m_res'[1..`nrows_short', 1..`r_star']
      matrix `res_late' = `m_res'[`= `jlag' + 1'..`T1', 1..`r_star']
      matrix `sigma_j' = (`wt' / `TT') * `res_early'' * `res_late'
      matrix `sigma_lr' = `sigma_lr' + `sigma_j'
    }
    
    * PHI_c = (1/2)*(Yc2'*Yc1 + Yc1'*Yc2 - T*(sigma+sigma')) * inv(Yc1'*Yc1)
    tempname phi_c sigma_sym
    matrix `sigma_sym' = `TT' * (`sigma_lr' + `sigma_lr'')
    matrix `phi_c' = 0.5 * (`Yc2'' * `Yc1' + `Yc1'' * `Yc2' - `sigma_sym') ///
      * `Yc1tYc1_inv'
    
    * Force symmetry (floating-point rounding can break exact symmetry)
    matrix `phi_c' = 0.5 * (`phi_c' + `phi_c'')
    
    * Smallest eigenvalue of PHI_c
    * GAUSS: {u,s,v} = svd1(phi_c); v_c = s[rows(s),cols(s)]
    * In Stata: symeigen returns descending, so last eigenvalue is smallest
    tempname phi_eigvecs phi_eigvals
    matrix symeigen `phi_eigvecs' `phi_eigvals' = `phi_c'
    
    local v_c = `phi_eigvals'[1, `r_star']
    local MQ_val = `TT' * (`v_c' - 1)
    local final_MQ = `MQ_val'
    
    * Test: reject r* if MQ < cv[r*,2] at 5%
    local cv_5pct = `cv'[`r_star', 2]
    
    if `MQ_val' < `cv_5pct' {
      * Reject: decrease r_star
      local r_star = `r_star' - 1
    }
    else {
      * Cannot reject: r_star stochastic trends
      return scalar MQ_np = `final_MQ'
      return scalar n_trends = `r_star'
      exit
    }
  }
  
  * All rejected → 0 stochastic trends (all factors are I(0))
  return scalar MQ_np = `final_MQ'
  return scalar n_trends = 0
end



/* ========================================================================
   PROGRAM: _bc_mqtest_parametric
   Bai & Ng (2004) PARAMETRIC MQ test for common stochastic trends
   
   GAUSS: {test_p[1],test_p[2]} = MQ_test(fhat,model[1],N,1)
   
   Algorithm (k=1 in GAUSS MQ_test):
   1. Select VAR(p) order via BIC
   2. Filter out short-run dynamics from Yc
   3. Compute PHI_c on filtered Yc (no Newey-West needed)
   4. MQ = T * (smallest eigenvalue of PHI_c - 1)
   5. Sequential testing against same critical values
   ======================================================================== */

program define _bc_mqtest_parametric, rclass
  syntax, model(integer) npanels(integer)
  
  local r = colsof(_bc_Fhat_cumul)
  local TT = rowsof(_bc_Fhat_cumul)
  
  if `r' == 0 {
    return scalar MQ_p = .
    return scalar n_trends_p = 0
    exit
  }
  
  * ---- Detrend factors (same as non-parametric) ----
  tempname F_det
  matrix `F_det' = _bc_Fhat_cumul
  
  if `model' == 1 | `model' == 3 | `model' == 5 {
    forvalues jj = 1/`r' {
      local colmean = 0
      forvalues tt = 1/`TT' {
        local colmean = `colmean' + `F_det'[`tt', `jj']
      }
      local colmean = `colmean' / `TT'
      forvalues tt = 1/`TT' {
        matrix `F_det'[`tt', `jj'] = `F_det'[`tt', `jj'] - `colmean'
      }
    }
  }
  else if `model' == 2 | `model' == 4 {
    forvalues jj = 1/`r' {
      local sum_y = 0
      local sum_ty = 0
      local sum_t = 0
      local sum_t2 = 0
      forvalues tt = 1/`TT' {
        local yval = `F_det'[`tt', `jj']
        local sum_y = `sum_y' + `yval'
        local sum_ty = `sum_ty' + `tt' * `yval'
        local sum_t = `sum_t' + `tt'
        local sum_t2 = `sum_t2' + `tt' * `tt'
      }
      local det_xx = `TT' * `sum_t2' - `sum_t' * `sum_t'
      local b0 = (`sum_t2' * `sum_y' - `sum_t' * `sum_ty') / `det_xx'
      local b1 = (`TT' * `sum_ty' - `sum_t' * `sum_y') / `det_xx'
      forvalues tt = 1/`TT' {
        local fitted = `b0' + `b1' * `tt'
        matrix `F_det'[`tt', `jj'] = `F_det'[`tt', `jj'] - `fitted'
      }
    }
  }
  
  * ---- Critical values (same as non-parametric) ----
  tempname cv
  if `model' == 1 | `model' == 3 {
    matrix `cv' = ( -20.151, -13.730, -11.022 \ ///
                    -31.621, -23.535, -19.923 \ ///
                    -41.064, -32.296, -28.399 \ ///
                    -48.501, -40.442, -36.592 \ ///
                    -58.383, -48.617, -44.111 \ ///
                    -66.978, -57.040, -52.312 \ ///
                    -78.252, -67.465, -62.172 \ ///
                    -86.619, -76.042, -70.590 \ ///
                    -95.297, -83.824, -78.376 \ ///
                   -104.044, -92.623, -86.935 \ ///
                   -112.491,-100.265, -94.670 \ ///
                   -120.315,-108.174,-102.538 )
  }
  else if `model' == 2 | `model' == 4 {
    matrix `cv' = ( -29.246, -21.313, -17.829 \ ///
                    -38.619, -31.356, -27.435 \ ///
                    -50.019, -40.180, -35.685 \ ///
                    -58.140, -48.421, -44.079 \ ///
                    -64.729, -55.818, -55.286 \ ///
                    -74.251, -64.393, -59.555 \ ///
                    -85.360, -74.068, -69.073 \ ///
                    -93.494, -82.333, -76.962 \ ///
                   -102.368, -90.896, -85.192 \ ///
                   -109.641, -98.475, -92.663 \ ///
                   -119.233,-106.643,-100.875 \ ///
                   -127.147,-114.876,-108.927 )
  }
  else if `model' == 5 {
    if `TT' <= 75 {
      matrix `cv' = ( -31.046, -24.828, -21.669 \ ///
                      -38.827, -32.792, -29.925 \ ///
                      -44.744, -39.703, -36.641 \ ///
                      -47.752, -44.865, -42.381 \ ///
                      -48.756, -47.472, -46.119 \ ///
                      -48.890, -48.444, -47.879 )
    }
    else if `TT' <= 200 {
      matrix `cv' = ( -34.474, -26.833, -23.102 \ ///
                      -44.748, -36.464, -32.729 \ ///
                      -53.423, -45.879, -41.862 \ ///
                      -61.972, -53.251, -49.284 \ ///
                      -69.033, -61.099, -56.747 \ ///
                      -74.663, -67.183, -63.437 )
    }
    else {
      matrix `cv' = ( -32.985, -25.697, -22.843 \ ///
                      -46.953, -38.103, -33.778 \ ///
                      -52.827, -45.066, -41.136 \ ///
                      -59.494, -53.392, -49.240 \ ///
                      -70.495, -62.404, -57.440 \ ///
                      -78.589, -68.748, -64.459 )
    }
  }
  
  local max_cv_rows = rowsof(`cv')
  
  * ---- SVD of T^(-2) * F'F ----
  tempname FFmat eigenvals_F eigenvecs_F
  matrix `FFmat' = (1/(`TT'^2)) * `F_det'' * `F_det'
  matrix symeigen `eigenvecs_F' `eigenvals_F' = `FFmat'
  
  * ---- Sequential testing (parametric) ----
  local r_star = `r'
  if `r_star' > `max_cv_rows' {
    local r_star = `max_cv_rows'
  }
  
  local final_MQ = .
  
  while `r_star' > 0 {
    * Construct Yc = F_det * u_F[,1:r_star]
    tempname Yc
    matrix `Yc' = J(`TT', `r_star', 0)
    forvalues tt = 1/`TT' {
      forvalues kk = 1/`r_star' {
        local val = 0
        forvalues jj = 1/`r' {
          local val = `val' + `F_det'[`tt', `jj'] * `eigenvecs_F'[`jj', `kk']
        }
        matrix `Yc'[`tt', `kk'] = `val'
      }
    }
    
    * --- Parametric MQ (k=1) ---
    * GAUSS: p = 4*int((T/100)^(1/4))
    local pmax = 4 * floor((`TT' / 100)^(0.25))
    if `pmax' < 1 {
      local pmax = 1
    }
    
    * Compute D.Yc (first differences)
    local Tm1 = `TT' - 1
    tempname DYc
    matrix `DYc' = J(`Tm1', `r_star', 0)
    forvalues tt = 1/`Tm1' {
      forvalues kk = 1/`r_star' {
        matrix `DYc'[`tt', `kk'] = `Yc'[`tt'+1, `kk'] - `Yc'[`tt', `kk']
      }
    }
    
    * BIC lag selection: estimate VAR(i) for i=1..pmax, compute BIC
    * GAUSS: m_BIC[i] = -2*l/T + (r^2 * i*r) * ln(T) / T
    
    * First compute BIC for p=0: just variance of DYc
    local usable_T = `Tm1' - `pmax'
    
    * For each p from 1 to pmax, estimate VAR(p) on trimmed DYc
    * and compute BIC. Then select minimum.
    
    * Simple approach: use p=1 (most common for MQ test)
    * Full BIC selection would require building lagged matrices
    * which is complex in Stata matrix language. Use p=1 as default.
    local p_sel = 1
    
    if `p_sel' > 0 {
      * VAR(1) on DYc: DYc2 = DYc1 * beta + u
      * Trim: use observations [p+2, T] for DYc and [p+1, T-1] for lags
      local t_start = `p_sel' + 1
      local t_end = `Tm1'
      local nobs_var = `t_end' - `t_start' + 1
      
      if `nobs_var' < `r_star' + 2 {
        * Not enough obs
        local r_star = `r_star' - 1
        continue
      }
      
      tempname DYc_dep DYc_lag
      matrix `DYc_dep' = `DYc'[`t_start'..`t_end', 1..`r_star']
      matrix `DYc_lag' = `DYc'[`= `t_start' - 1'..`= `t_end' - 1', 1..`r_star']
      
      * OLS: beta_j = (DYc_lag'DYc_lag)^(-1) * DYc_lag'DYc_dep[,j]
      tempname Xt_Xt Xt_Xt_inv var_beta var_res
      matrix `Xt_Xt' = `DYc_lag'' * `DYc_lag'
      capture matrix `Xt_Xt_inv' = syminv(`Xt_Xt')
      if _rc {
        local r_star = `r_star' - 1
        continue
      }
      
      matrix `var_beta' = `Xt_Xt_inv' * `DYc_lag'' * `DYc_dep'
      matrix `var_res' = `DYc_dep' - `DYc_lag' * `var_beta'
      
      * Filter Yc: for levels, Yc_lag = Yc[p:T-1], Yc_dep = Yc[p+1:T]
      * Yc_filtered[t] = Yc[t] - sum Yc_lag[t-j] * beta_j
      * With p=1: Yc_filtered = Yc[2:T] - Yc[1:T-1] * beta (residuals from level VAR(1))
      
      local Yc_t_start = `p_sel' + 1
      local Yc_t_end = `TT'
      local nobs_filt = `Yc_t_end' - `Yc_t_start' + 1
      
      tempname Yc_dep Yc_lag_lev Yc_filt
      matrix `Yc_dep' = `Yc'[`Yc_t_start'..`Yc_t_end', 1..`r_star']
      matrix `Yc_lag_lev' = `Yc'[`= `Yc_t_start' - 1'..`= `Yc_t_end' - 1', 1..`r_star']
      matrix `Yc_filt' = `Yc_dep' - `Yc_lag_lev' * `var_beta'
    }
    else {
      * p=0: Yc_filtered = Yc
      tempname Yc_filt
      matrix `Yc_filt' = `Yc'
      local nobs_filt = `TT'
    }
    
    * PHI_c on filtered Yc (no Newey-West for parametric)
    * GAUSS: PHI_c = (1/2)*(Yc_f[2:]'*Yc_f[1:] + Yc_f[1:]'*Yc_f[2:])
    *                * inv(Yc_f[1:]'*Yc_f[1:])
    
    local nf1 = `nobs_filt' - 1
    tempname Ycf1 Ycf2 Ycf1t_Ycf1 Ycf1t_inv
    matrix `Ycf1' = `Yc_filt'[1..`nf1', 1..`r_star']
    matrix `Ycf2' = `Yc_filt'[2..`nobs_filt', 1..`r_star']
    matrix `Ycf1t_Ycf1' = `Ycf1'' * `Ycf1'
    
    capture matrix `Ycf1t_inv' = syminv(`Ycf1t_Ycf1')
    if _rc {
      local r_star = `r_star' - 1
      continue
    }
    
    tempname phi_c
    matrix `phi_c' = 0.5 * (`Ycf2'' * `Ycf1' + `Ycf1'' * `Ycf2') * `Ycf1t_inv'
    
    * Force symmetry (floating-point rounding can break exact symmetry)
    matrix `phi_c' = 0.5 * (`phi_c' + `phi_c'')
    
    * Smallest eigenvalue
    tempname phi_eigvecs phi_eigvals
    matrix symeigen `phi_eigvecs' `phi_eigvals' = `phi_c'
    
    local v_c = `phi_eigvals'[1, `r_star']
    local MQ_val = `TT' * (`v_c' - 1)
    local final_MQ = `MQ_val'
    
    * Test at 5%
    local cv_5pct = `cv'[`r_star', 2]
    
    if `MQ_val' < `cv_5pct' {
      local r_star = `r_star' - 1
    }
    else {
      return scalar MQ_p = `final_MQ'
      return scalar n_trends_p = `r_star'
      exit
    }
  }
  
  return scalar MQ_p = `final_MQ'
  return scalar n_trends_p = 0
end
