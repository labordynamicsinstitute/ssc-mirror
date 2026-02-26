*! _rardl_rolling — Rolling-Window ARDL Bounds Test (RARDL)
*! Version 1.0.0
*! Implements Shahbaz, Khan & Mubarak (2023, QREF) methodology
*! Tests time-varying cointegration using fixed-size rolling windows

capture program drop _rardl_rolling
program define _rardl_rolling, rclass
    version 17

    syntax varlist(min=2 ts) [if] [in], ///
        [ Wsize(numlist min=1 integer >10) ///
          maxlag(integer 4) ///
          ic(string) ///
          Case(integer 3) ///
          Level(integer 5) ///
          nsim(integer 50000) ///
          seed(integer -1) ///
          NOSimulate ///
          graph ///
          NOTable ///
          ALLModels ]

    // =========================================================================
    // 1. VALIDATE
    // =========================================================================
    marksample touse
    
    if "`ic'" == "" local ic "bic"
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic", "hqic") {
        di as err "ic() must be aic, bic, or hqic"
        exit 198
    }
    
    if !inrange(`case', 1, 5) {
        di as err "case() must be 1, 2, 3, 4, or 5"
        exit 198
    }
    
    // Parse variables
    tokenize `varlist'
    local depvar "`1'"
    macro shift
    local indvars "`*'"
    local nregs : word count `indvars'
    
    if "`wsize'" == "" {
        local wsize "60 120 180 240"
    }

    // =========================================================================
    // 2. PRESERVE AND PREPARE
    // =========================================================================
    preserve
    qui keep if `touse'
    qui count
    local T = r(N)
    
    qui tsset
    local timevar = r(timevar)
    local tsfmt : format `timevar'

    // =========================================================================
    // 3. HEADER
    // =========================================================================
    if "`notable'" == "" {
        di as txt ""
        di as txt "{hline 78}"
        di as txt "{bf:Rolling-Window ARDL Bounds Test (RARDL)}"
        di as txt "{hline 78}"
        di as txt _col(5) "Dependent variable: " as res "`depvar'"
        di as txt _col(5) "Independent var(s) : " as res "`indvars'"
        di as txt _col(5) "Sample size (T)    : " as res "`T'"
        di as txt _col(5) "Max lag length     : " as res "`maxlag'"
        di as txt _col(5) "IC for lag select  : " as res upper("`ic'")
        if "`allmodels'" != "" {
            di as txt _col(5) "PSS Models         : " as res "All (1-5)"
        }
        else {
            di as txt _col(5) "PSS Case           : " as res "Case `case'"
        }
        di as txt _col(5) "Window size(s)     : " as res "`wsize'"
        di as txt _col(5) "Significance level : " as res "`level'%"
        if "`nosimulate'" == "" {
            di as txt _col(5) "Simulated CVs      : " as res "Yes (`nsim' reps)"
        }
        else {
            di as txt _col(5) "Critical values    : " as res "Asymptotic (PSS 2001)"
        }
        di as txt "{hline 78}"
    }

    // =========================================================================
    // 4. SET MODEL LIST AND SIMULATE CRITICAL VALUES (if needed)
    // =========================================================================
    if "`allmodels'" != "" {
        local model_list "1 2 3 4 5"
    }
    else {
        local model_list "`case'"
    }
    
    if "`nosimulate'" == "" {
        di as txt ""
        di as txt _col(3) "{bf:Step 1: Simulating critical values...}"
        
        _rardl_simulate, tobs(`wsize') nregs(`nregs') nsim(`nsim') ///
            maxlag(`maxlag') ic(`ic') seed(`seed')
        
        // Retrieve critical value matrices for specified case
        local nwsizes : word count `wsize'
        
        // Store CVs indexed by window size
        foreach m of local model_list {
            tempname sim_cv_m`m'
            mat `sim_cv_m`m'' = r(cv_model`m')
        }
    }

    // =========================================================================
    // 5. ROLLING WINDOW ESTIMATION
    // =========================================================================
    di as txt ""
    di as txt _col(3) "{bf:Step 2: Rolling-window bounds testing...}"
    
    local widx_global = 0
    foreach ws of numlist `wsize' {
        local ++widx_global
        
        if `ws' >= `T' {
            di as err "Window size `ws' >= sample size `T', skipping"
            continue
        }
        
        local nrolls = `T' - `ws' + 1
        
        di as txt ""
        di as txt _col(5) "Window size = `ws' observations (`nrolls' rolling windows)"
        
        // Always compute asymptotic CVs for comparison
        foreach m of local model_list {
            if `level' == 1 {
                if `m' == 1 local aucv_m`m' = 6.84
                if `m' == 1 local alcv_m`m' = 4.94
                if `m' == 2 local aucv_m`m' = 8.74
                if `m' == 2 local alcv_m`m' = 6.84
                if `m' == 3 local aucv_m`m' = 7.84
                if `m' == 3 local alcv_m`m' = 6.84
                if `m' == 4 local aucv_m`m' = 8.74
                if `m' == 4 local alcv_m`m' = 7.52
                if `m' == 5 local aucv_m`m' = 8.74
                if `m' == 5 local alcv_m`m' = 7.52
            }
            else if `level' == 5 {
                if `m' == 1 local aucv_m`m' = 4.94
                if `m' == 1 local alcv_m`m' = 3.62
                if `m' == 2 local aucv_m`m' = 6.56
                if `m' == 2 local alcv_m`m' = 4.94
                if `m' == 3 local aucv_m`m' = 5.73
                if `m' == 3 local alcv_m`m' = 4.94
                if `m' == 4 local aucv_m`m' = 6.56
                if `m' == 4 local alcv_m`m' = 5.59
                if `m' == 5 local aucv_m`m' = 6.56
                if `m' == 5 local alcv_m`m' = 5.59
            }
            else {
                if `m' == 1 local aucv_m`m' = 4.04
                if `m' == 1 local alcv_m`m' = 3.02
                if `m' == 2 local aucv_m`m' = 5.62
                if `m' == 2 local alcv_m`m' = 4.04
                if `m' == 3 local aucv_m`m' = 4.85
                if `m' == 3 local alcv_m`m' = 4.04
                if `m' == 4 local aucv_m`m' = 5.62
                if `m' == 4 local alcv_m`m' = 4.68
                if `m' == 5 local aucv_m`m' = 5.62
                if `m' == 5 local alcv_m`m' = 4.68
            }
        }
        
        // Get critical value for this window size
        if "`nosimulate'" == "" {
            foreach m of local model_list {
                // Find the row for this window size
                local cvrow = 0
                local nwsizes : word count `wsize'
                local ww = 0
                foreach ww_s of numlist `wsize' {
                    local ++ww
                    if `ww_s' == `ws' {
                        local cvrow = `ww'
                    }
                }
                
                if `cvrow' > 0 {
                    if `level' == 1 {
                        local ucv_m`m' = el(`sim_cv_m`m'', `cvrow', 3)
                        local lcv_m`m' = el(`sim_cv_m`m'', `cvrow', 2)
                    }
                    else if `level' == 5 {
                        local ucv_m`m' = el(`sim_cv_m`m'', `cvrow', 5)
                        local lcv_m`m' = el(`sim_cv_m`m'', `cvrow', 4)
                    }
                    else {
                        local ucv_m`m' = el(`sim_cv_m`m'', `cvrow', 7)
                        local lcv_m`m' = el(`sim_cv_m`m'', `cvrow', 6)
                    }
                }
            }
        }
        else {
            // Use asymptotic values as active CVs
            foreach m of local model_list {
                local ucv_m`m' = `aucv_m`m''
                local lcv_m`m' = `alcv_m`m''
            }
        }

        // Result storage
        foreach m of local model_list {
            tempname roll_m`m'_w`ws'
            mat `roll_m`m'_w`ws'' = J(`nrolls', 11, .)
            // Cols: start, end, F, pval, z_bt, ecm, lr_beta, sr_delta, sr_fstat, best_p, best_q
        }
        
        // -----------------------------------------------------------------
        // Rolling loop
        // -----------------------------------------------------------------
        forvalues r = 1/`nrolls' {
            local sobs = `r'
            local eobs = `r' + `ws' - 1
            
            // Build regression for each model
            foreach m of local model_list {
                
                // ARDL(p,q) lag selection: grid search over p and q
                local best_p = 1
                local best_q = 0
                local best_ic_v = .
                forvalues pp = 1/`maxlag' {
                    forvalues qq = 0/`maxlag' {
                        // Build regressors for ARDL(pp, qq)
                        local regvars "L.`depvar'"
                        foreach iv of local indvars {
                            local regvars "`regvars' L.`iv'"
                        }
                        // Dependent variable lags: L1.D.y ... Lpp.D.y
                        forvalues ll = 1/`pp' {
                            local regvars "`regvars' L`ll'.D.`depvar'"
                        }
                        // Independent variable diffs: D.X, L1.D.X ... Lqq.D.X
                        foreach iv of local indvars {
                            forvalues ll = 0/`qq' {
                                if `ll' == 0 {
                                    local regvars "`regvars' D.`iv'"
                                }
                                else {
                                    local regvars "`regvars' L`ll'.D.`iv'"
                                }
                            }
                        }
                        
                        // Deterministic terms
                        local detterms ""
                        if `m' == 1 {
                            local nocon "noconstant"
                        }
                        else if inlist(`m', 2, 3) {
                            local nocon ""
                        }
                        else if inlist(`m', 4, 5) {
                            local detterms "t"
                            local nocon ""
                        }
                        
                        capture qui reg D.`depvar' `regvars' `detterms' ///
                            in `sobs'/`eobs', `nocon'
                        if _rc == 0 {
                            local nn = e(N)
                            local kk = e(rank)
                            if "`ic'" == "bic" {
                                local this_ic = `nn'*ln(e(rss)/`nn') + `kk'*ln(`nn')
                            }
                            else if "`ic'" == "aic" {
                                local this_ic = `nn'*ln(e(rss)/`nn') + 2*`kk'
                            }
                            else {
                                local this_ic = `nn'*ln(e(rss)/`nn') + 2*`kk'*ln(ln(`nn'))
                            }
                            if `this_ic' < `best_ic_v' {
                                local best_ic_v = `this_ic'
                                local best_p = `pp'
                                local best_q = `qq'
                            }
                        }
                    }
                }

                // Estimate with optimal ARDL(best_p, best_q)
                local regvars "L.`depvar'"
                local testvars "L.`depvar'"
                local sr_testvars ""
                foreach iv of local indvars {
                    local regvars "`regvars' L.`iv'"
                    local testvars "`testvars' L.`iv'"
                }
                forvalues ll = 1/`best_p' {
                    local regvars "`regvars' L`ll'.D.`depvar'"
                }
                foreach iv of local indvars {
                    forvalues ll = 0/`best_q' {
                        if `ll' == 0 {
                            local regvars "`regvars' D.`iv'"
                            local sr_testvars "`sr_testvars' D.`iv'"
                        }
                        else {
                            local regvars "`regvars' L`ll'.D.`iv'"
                            local sr_testvars "`sr_testvars' L`ll'.D.`iv'"
                        }
                    }
                }
                
                local detterms ""
                local nocon ""
                if `m' == 1 {
                    local nocon "noconstant"
                }
                else if inlist(`m', 4, 5) {
                    local detterms "t"
                    if `m' == 4 {
                        local testvars "`testvars' t"
                    }
                }
                
                local fstat = .
                local ecm_c = .
                local lr_beta = .
                local sr_delta = .
                local sr_fstat = .
                capture qui reg D.`depvar' `regvars' `detterms' ///
                    in `sobs'/`eobs', `nocon'
                if _rc == 0 {
                    local ecm_c = _b[L.`depvar']
                    
                    // Long-run beta
                    local firstiv : word 1 of `indvars'
                    capture local lr_beta = _b[L.`firstiv']
                    
                    // Short-run delta
                    capture local sr_delta = _b[D.`firstiv']
                    
                    // Long-run F-test (bounds test)
                    capture qui testparm `testvars'
                    if _rc == 0 {
                        local fstat = r(F)
                    }
                    
                    // Short-run F-test
                    if "`sr_testvars'" != "" {
                        capture qui testparm `sr_testvars'
                        if _rc == 0 {
                            local sr_fstat = r(F)
                        }
                    }
                }
                
                // Compute z and approximate p-value
                local zbt = .
                local pval = .
                if `fstat' != . {
                    local this_ucv = `ucv_m`m''
                    if `this_ucv' > 0 {
                        local zbt = `fstat' / `this_ucv'
                    }
                    local nrest = 1 + `nregs'
                    if `m' == 4 local nrest = 2 + `nregs'
                    local dfr = e(df_r)
                    if `dfr' > 0 {
                        local pval = Ftail(`nrest', `dfr', `fstat')
                    }
                }

                mat `roll_m`m'_w`ws''[`r', 1] = `sobs'
                mat `roll_m`m'_w`ws''[`r', 2] = `eobs'
                mat `roll_m`m'_w`ws''[`r', 3] = `fstat'
                mat `roll_m`m'_w`ws''[`r', 4] = `pval'
                mat `roll_m`m'_w`ws''[`r', 5] = `zbt'
                mat `roll_m`m'_w`ws''[`r', 6] = `ecm_c'
                mat `roll_m`m'_w`ws''[`r', 7] = `lr_beta'
                mat `roll_m`m'_w`ws''[`r', 8] = `sr_delta'
                mat `roll_m`m'_w`ws''[`r', 9] = `sr_fstat'
                mat `roll_m`m'_w`ws''[`r', 10] = `best_p'
                mat `roll_m`m'_w`ws''[`r', 11] = `best_q'
            }
            
            // Progress
            if mod(`r', 50) == 0 {
                di as txt "." _continue
            }
        }
        di as txt " done"

        // -----------------------------------------------------------------
        // Summarize results per model per window
        // -----------------------------------------------------------------
        foreach m of local model_list {
            local ncoint = 0
            local ncoint_1 = 0
            local ncoint_5 = 0
            local ncoint_10 = 0
            local first_coint = .
            local last_coint = .
            
            forvalues r = 1/`nrolls' {
                local zv = el(`roll_m`m'_w`ws'', `r', 5)
                if `zv' != . & `zv' > 1 {
                    local ++ncoint
                    if `first_coint' == . local first_coint = `r'
                    local last_coint = `r'
                }
            }
            local pct_coint = 100 * `ncoint' / `nrolls'
            
            // Verdict
            if `pct_coint' >= 95 {
                local verdict "Strong consistent cointegration"
            }
            else if `pct_coint' >= 80 {
                local verdict "Cointegration w/ rare exceptions"
            }
            else if `pct_coint' >= 50 {
                local verdict "Cointegration w/ exceptions"
            }
            else if `pct_coint' >= 20 {
                local verdict "Inconsistent"
            }
            else if `pct_coint' >= 5 {
                local verdict "No cointegration w/ rare exceptions"
            }
            else {
                local verdict "No cointegration"
            }

            if "`notable'" == "" {
                // Model label
                if `m' == 1 local mlbl "No intercept, No trend"
                if `m' == 2 local mlbl "Restricted intercept"
                if `m' == 3 local mlbl "Unrestricted intercept"
                if `m' == 4 local mlbl "Unrestrict. intercept, Restrict. trend"
                if `m' == 5 local mlbl "Unrestrict. intercept, Unrestrict. trend"
                
                di as txt ""
                di as txt "{bf:Model `m' (`mlbl'), Window = `ws'}"
                di as txt "{hline 78}"
                di as txt _col(5) "Rolling windows   : " as res "`nrolls'"
                di as txt _col(5) "Cointegrated      : " as res "`ncoint' (" %5.1f `pct_coint' "%)"
                
                if "`nosimulate'" == "" {
                    di as txt _col(5) "UCV (`level'%)         : " as res %8.4f `ucv_m`m''
                    di as txt _col(5) "LCV (`level'%)         : " as res %8.4f `lcv_m`m''
                }
                
                if `first_coint' != . {
                    local fobs = el(`roll_m`m'_w`ws'', `first_coint', 2)
                    local lobs = el(`roll_m`m'_w`ws'', `last_coint', 2)
                    local ftime : di `tsfmt' `timevar'[`fobs']
                    local ltime : di `tsfmt' `timevar'[`lobs']
                    di as txt _col(5) "First coint. at   : " as res "`ftime'"
                    di as txt _col(5) "Last coint. at    : " as res "`ltime'"
                }
                di as txt _col(5) "{bf:Verdict}          : " as res "{bf:`verdict'}"
                di as txt "{hline 78}"
                
                // Detailed tables (sampled ~20 rows)
                local rstep = max(1, int(`nrolls'/20))
                local firstiv : word 1 of `indvars'
                
                // ============ LONG-RUN TABLE ============
                di as txt ""
                di as txt "{bf:Long-Run Results (Cointegration)}"
                di as txt "{hline 78}"
                di as txt _col(1) "{bf:Period}" ///
                    _col(13) "{bf:ARDL}" ///
                    _col(21) "{bf:ECM(a)}" ///
                    _col(33) "{bf:LR(b)}" ///
                    _col(44) "{bf:F-bnd}" ///
                    _col(54) "{bf:UCV}" ///
                    _col(63) "{bf:z-bt}" ///
                    _col(73) "{bf:Dec}"
                di as txt "{hline 78}"
                
                forvalues r = 1(`rstep')`nrolls' {
                    local eobs = el(`roll_m`m'_w`ws'', `r', 2)
                    local fst  = el(`roll_m`m'_w`ws'', `r', 3)
                    local zbt  = el(`roll_m`m'_w`ws'', `r', 5)
                    local ecm  = el(`roll_m`m'_w`ws'', `r', 6)
                    local lrb  = el(`roll_m`m'_w`ws'', `r', 7)
                    local bp   = el(`roll_m`m'_w`ws'', `r', 10)
                    local bq   = el(`roll_m`m'_w`ws'', `r', 11)
                    
                    local dec "   "
                    if `zbt' != . & `zbt' > 1 local dec "***"
                    
                    local tlab ""
                    if `eobs' != . {
                        local tlab : di `tsfmt' `timevar'[`eobs']
                    }
                    
                    local pqlbl "(`=int(`bp')',`=int(`bq')')"
                    
                    if `fst' != . {
                        di as res _col(1) %10s "`tlab'" ///
                            _col(13) %6s "`pqlbl'" ///
                            _col(20) %8.4f `ecm' ///
                            _col(31) %8.4f `lrb' ///
                            _col(43) %7.3f `fst' ///
                            _col(53) %6.3f `ucv_m`m'' ///
                            _col(62) %6.3f `zbt' ///
                            _col(73) "`dec'"
                    }
                }
                // Always show last row
                if mod(`nrolls', `rstep') != 1 & `nrolls' > 1 {
                    local r = `nrolls'
                    local eobs = el(`roll_m`m'_w`ws'', `r', 2)
                    local fst  = el(`roll_m`m'_w`ws'', `r', 3)
                    local zbt  = el(`roll_m`m'_w`ws'', `r', 5)
                    local ecm  = el(`roll_m`m'_w`ws'', `r', 6)
                    local lrb  = el(`roll_m`m'_w`ws'', `r', 7)
                    local bp   = el(`roll_m`m'_w`ws'', `r', 10)
                    local bq   = el(`roll_m`m'_w`ws'', `r', 11)
                    local dec "   "
                    if `zbt' != . & `zbt' > 1 local dec "***"
                    local tlab ""
                    if `eobs' != . {
                        local tlab : di `tsfmt' `timevar'[`eobs']
                    }
                    local pqlbl "(`=int(`bp')',`=int(`bq')')"
                    if `fst' != . {
                        di as res _col(1) %10s "`tlab'" ///
                            _col(13) %6s "`pqlbl'" ///
                            _col(20) %8.4f `ecm' ///
                            _col(31) %8.4f `lrb' ///
                            _col(43) %7.3f `fst' ///
                            _col(53) %6.3f `ucv_m`m'' ///
                            _col(62) %6.3f `zbt' ///
                            _col(73) "`dec'"
                    }
                }
                di as txt "{hline 78}"
                di as txt _col(2) "ARDL(p,q)  ECM(a)=L.`depvar'  LR(b)=L.`firstiv'  *** = coint."
                
                // ============ SHORT-RUN TABLE ============
                di as txt ""
                di as txt "{bf:Short-Run Results (Dynamics)}"
                di as txt "{hline 78}"
                di as txt _col(2) "{bf:Period}" ///
                    _col(16) "{bf:SR(d)}" ///
                    _col(28) "{bf:SR F-stat}" ///
                    _col(42) "{bf:p-val}" ///
                    _col(54) "{bf:Dec}" ///
                    _col(62) "{bf:ECM(a)}" ///
                    _col(72) "{bf:LR Dec}"
                di as txt "{hline 78}"
                
                // Count short-run significant
                local nsrsig = 0
                
                forvalues r = 1(`rstep')`nrolls' {
                    local eobs = el(`roll_m`m'_w`ws'', `r', 2)
                    local srd  = el(`roll_m`m'_w`ws'', `r', 8)
                    local srf  = el(`roll_m`m'_w`ws'', `r', 9)
                    local ecm  = el(`roll_m`m'_w`ws'', `r', 6)
                    local zbt  = el(`roll_m`m'_w`ws'', `r', 5)
                    
                    // SR p-value (approx from F dist)
                    local sr_pv = .
                    if `srf' != . {
                        local sr_dfr = e(df_r)
                        if `sr_dfr' <= 0 local sr_dfr = `ws' - 10
                        capture local sr_pv = Ftail(`nregs'*(`best_p'+1), `sr_dfr', `srf')
                    }
                    
                    local srdec "   "
                    if `sr_pv' != . & `sr_pv' < `level'/100 {
                        local srdec "***"
                        local ++nsrsig
                    }
                    local lrdec "   "
                    if `zbt' != . & `zbt' > 1 local lrdec "***"
                    
                    local tlab ""
                    if `eobs' != . {
                        local tlab : di `tsfmt' `timevar'[`eobs']
                    }
                    
                    if `srf' != . {
                        di as res _col(1) %12s "`tlab'" ///
                            _col(15) %8.4f `srd' ///
                            _col(28) %8.3f `srf' ///
                            _col(40) %8.4f `sr_pv' ///
                            _col(54) "`srdec'" ///
                            _col(61) %8.4f `ecm' ///
                            _col(72) "`lrdec'"
                    }
                }
                // Always show last row
                if mod(`nrolls', `rstep') != 1 & `nrolls' > 1 {
                    local r = `nrolls'
                    local eobs = el(`roll_m`m'_w`ws'', `r', 2)
                    local srd  = el(`roll_m`m'_w`ws'', `r', 8)
                    local srf  = el(`roll_m`m'_w`ws'', `r', 9)
                    local ecm  = el(`roll_m`m'_w`ws'', `r', 6)
                    local zbt  = el(`roll_m`m'_w`ws'', `r', 5)
                    local sr_pv = .
                    if `srf' != . {
                        local sr_dfr = e(df_r)
                        if `sr_dfr' <= 0 local sr_dfr = `ws' - 10
                        capture local sr_pv = Ftail(`nregs'*(`best_p'+1), `sr_dfr', `srf')
                    }
                    local srdec "   "
                    if `sr_pv' != . & `sr_pv' < `level'/100 {
                        local srdec "***"
                    }
                    local lrdec "   "
                    if `zbt' != . & `zbt' > 1 local lrdec "***"
                    local tlab ""
                    if `eobs' != . {
                        local tlab : di `tsfmt' `timevar'[`eobs']
                    }
                    if `srf' != . {
                        di as res _col(1) %12s "`tlab'" ///
                            _col(15) %8.4f `srd' ///
                            _col(28) %8.3f `srf' ///
                            _col(40) %8.4f `sr_pv' ///
                            _col(54) "`srdec'" ///
                            _col(61) %8.4f `ecm' ///
                            _col(72) "`lrdec'"
                    }
                }
                di as txt "{hline 78}"
                di as txt _col(2) "SR(d)=D.`firstiv'  *** = SR significant at `level'%"
                
                // ============ CV COMPARISON TABLE ============
                di as txt ""
                di as txt "{bf:Critical Value Comparison}"
                di as txt "{hline 78}"
                if "`nosimulate'" == "" {
                    di as txt _col(1) "{bf:Period}" ///
                        _col(13) "{bf:F-stat}" ///
                        _col(24) "{bf:Asym UCV}" ///
                        _col(36) "{bf:A-Dec}" ///
                        _col(44) "{bf:Sim UCV}" ///
                        _col(56) "{bf:S-Dec}" ///
                        _col(64) "{bf:Agree?}"
                }
                else {
                    di as txt _col(1) "{bf:Period}" ///
                        _col(13) "{bf:F-stat}" ///
                        _col(24) "{bf:Asym UCV}" ///
                        _col(36) "{bf:Asym LCV}" ///
                        _col(48) "{bf:Zone}" ///
                        _col(58) "{bf:Decision}"
                }
                di as txt "{hline 78}"
                
                local nagree = 0
                local ndisagree = 0
                local ncoint_asym = 0
                local ncoint_sim = 0
                
                forvalues r = 1(`rstep')`nrolls' {
                    local eobs = el(`roll_m`m'_w`ws'', `r', 2)
                    local fst  = el(`roll_m`m'_w`ws'', `r', 3)
                    
                    local tlab ""
                    if `eobs' != . {
                        local tlab : di `tsfmt' `timevar'[`eobs']
                    }
                    
                    if `fst' != . {
                        // Asymptotic decision
                        local adec "   "
                        if `fst' > `aucv_m`m'' {
                            local adec "***"
                            local ++ncoint_asym
                        }
                        
                        if "`nosimulate'" == "" {
                            // Simulated decision
                            local sdec "   "
                            if `fst' > `ucv_m`m'' {
                                local sdec "***"
                                local ++ncoint_sim
                            }
                            
                            local agree "Yes"
                            if "`adec'" != "`sdec'" {
                                local agree " NO"
                                local ++ndisagree
                            }
                            else {
                                local ++nagree
                            }
                            
                            di as res _col(1) %10s "`tlab'" ///
                                _col(13) %7.3f `fst' ///
                                _col(23) %7.3f `aucv_m`m'' ///
                                _col(36) "`adec'" ///
                                _col(43) %7.3f `ucv_m`m'' ///
                                _col(56) "`sdec'" ///
                                _col(64) "`agree'"
                        }
                        else {
                            // No simulation: show zone (below LCV, inconclusive, above UCV)
                            local zone "Inconclusive"
                            local zdec "   "
                            if `fst' > `aucv_m`m'' {
                                local zone "Cointegration"
                                local zdec "***"
                            }
                            else if `fst' < `alcv_m`m'' {
                                local zone "No coint."
                            }
                            
                            di as res _col(1) %10s "`tlab'" ///
                                _col(13) %7.3f `fst' ///
                                _col(23) %7.3f `aucv_m`m'' ///
                                _col(35) %7.3f `alcv_m`m'' ///
                                _col(47) %13s "`zone'" ///
                                _col(61) "`zdec'"
                        }
                    }
                }
                // Always show last row
                if mod(`nrolls', `rstep') != 1 & `nrolls' > 1 {
                    local r = `nrolls'
                    local eobs = el(`roll_m`m'_w`ws'', `r', 2)
                    local fst  = el(`roll_m`m'_w`ws'', `r', 3)
                    local tlab ""
                    if `eobs' != . {
                        local tlab : di `tsfmt' `timevar'[`eobs']
                    }
                    if `fst' != . {
                        local adec "   "
                        if `fst' > `aucv_m`m'' local adec "***"
                        if "`nosimulate'" == "" {
                            local sdec "   "
                            if `fst' > `ucv_m`m'' local sdec "***"
                            local agree "Yes"
                            if "`adec'" != "`sdec'" local agree " NO"
                            di as res _col(1) %10s "`tlab'" ///
                                _col(13) %7.3f `fst' ///
                                _col(23) %7.3f `aucv_m`m'' ///
                                _col(36) "`adec'" ///
                                _col(43) %7.3f `ucv_m`m'' ///
                                _col(56) "`sdec'" ///
                                _col(64) "`agree'"
                        }
                        else {
                            local zone "Inconclusive"
                            local zdec "   "
                            if `fst' > `aucv_m`m'' {
                                local zone "Cointegration"
                                local zdec "***"
                            }
                            else if `fst' < `alcv_m`m'' {
                                local zone "No coint."
                            }
                            di as res _col(1) %10s "`tlab'" ///
                                _col(13) %7.3f `fst' ///
                                _col(23) %7.3f `aucv_m`m'' ///
                                _col(35) %7.3f `alcv_m`m'' ///
                                _col(47) %13s "`zone'" ///
                                _col(61) "`zdec'"
                        }
                    }
                }
                di as txt "{hline 78}"
                if "`nosimulate'" == "" {
                    di as txt _col(2) "Asym=PSS(2001) T->inf   Sim=MC(`nsim' reps, T=`ws')"
                    di as txt _col(2) "Agreement: `nagree' rows agree, `ndisagree' rows disagree"
                }
                else {
                    di as txt _col(2) "UCV=I(1) bound  LCV=I(0) bound  PSS(2001) asymptotic"
                    di as txt _col(2) "Note: use simulation for finite-sample CVs (remove nosimulate)"
                }
            }

            // Graph: p-value and z-statistic over time
            if "`graph'" != "" {
                capture drop _rw_pval _rw_zbt _rw_time
                qui gen double _rw_pval = .
                qui gen double _rw_zbt = .
                qui gen double _rw_time = .
                
                forvalues r = 1/`nrolls' {
                    qui replace _rw_pval = el(`roll_m`m'_w`ws'', `r', 4) in `r'
                    qui replace _rw_zbt = el(`roll_m`m'_w`ws'', `r', 5) in `r'
                    local eobs = el(`roll_m`m'_w`ws'', `r', 2)
                    if `eobs' != . {
                        qui replace _rw_time = `timevar'[`eobs'] in `r'
                    }
                }
                
                local gname "rardl_rolling_m`m'_w`ws'"
                
                // P-value plot (matches paper figures)
                capture noisily {
                    twoway (area _rw_pval _rw_time if _rw_pval <= 0.`level', ///
                               color("60 170 100%30") base(0)) ///
                           (line _rw_pval _rw_time, ///
                               lcolor("24 54 104") lwidth(medium)) ///
                           , yline(0.01, lcolor("220 50 47") lpattern(dash) lwidth(thin)) ///
                           yline(0.05, lcolor("255 140 0") lpattern(dash) lwidth(thin)) ///
                           yline(0.10, lcolor("100 149 237") lpattern(dash) lwidth(thin)) ///
                           ytitle("p-value (F{sub:UB})", size(medium)) ///
                           xtitle("Window ending period", size(medium)) ///
                           ylabel(0(0.1)1, labsize(small) grid glcolor(gs14%50)) ///
                           xlabel(, labsize(small) grid glcolor(gs14%50) angle(45)) ///
                           legend(order(2 "p-value") ring(0) pos(2) ///
                               size(vsmall) rows(1)) ///
                           note("Rolling-Window ARDL (T{sub:R}=`ws', Model `m')", ///
                               size(vsmall) color(gs6)) ///
                           scheme(s2color) name(`gname', replace)
                    
                    qui graph export "`gname'.png", replace width(1400)
                }
                
                // z-statistic plot
                local gname2 "rardl_rolling_z_m`m'_w`ws'"
                capture noisily {
                    twoway (area _rw_zbt _rw_time if _rw_zbt >= 1, ///
                               color("60 170 100%30") base(1)) ///
                           (line _rw_zbt _rw_time, ///
                               lcolor("24 54 104") lwidth(medium)) ///
                           , yline(1, lcolor("220 50 47") lpattern(dash) lwidth(medthick)) ///
                           ytitle("z{sub:bt} = F-stat / UCV", size(medium)) ///
                           xtitle("Window ending period", size(medium)) ///
                           ylabel(, labsize(small) grid glcolor(gs14%50)) ///
                           xlabel(, labsize(small) grid glcolor(gs14%50) angle(45)) ///
                           legend(off) ///
                           note("Rolling-Window ARDL (T{sub:R}=`ws', Model `m')", ///
                               size(vsmall) color(gs6)) ///
                           scheme(s2color) name(`gname2', replace)
                    
                    qui graph export "`gname2'.png", replace width(1400)
                }
            }

            // Store matrices (return matrix consumes the tempname)
            mat colnames `roll_m`m'_w`ws'' = start_obs end_obs F_stat p_value z_bt ecm_coef
            return matrix roll_m`m'_w`ws' = `roll_m`m'_w`ws''
            return local verdict_m`m'_w`ws' "`verdict'"
        }
    }

    // =========================================================================
    // 6. RETURN
    // =========================================================================
    return scalar T = `T'
    return scalar nregs = `nregs'
    return local depvar "`depvar'"
    return local indvars "`indvars'"
    return local wsize "`wsize'"
    return local ic "`ic'"
    return scalar case = `case'

    restore
end
