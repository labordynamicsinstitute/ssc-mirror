*! _rardl_recursive — Recursive ARDL Bounds Test
*! Version 1.0.0
*! Implements Khan, Shahbaz & Napari (2023, Resources Policy) methodology
*! Tests subsample stability of cointegration using expanding windows

capture program drop _rardl_recursive
program define _rardl_recursive, rclass
    version 17

    syntax varlist(min=2 ts) [if] [in], ///
        [ INITobs(integer 60) ///
          maxlag(integer 4) ///
          ic(string) ///
          Case(integer 3) ///
          Level(integer 5) ///
          nsim(integer 50000) ///
          seed(integer -1) ///
          NOSimulate ///
          TRANSform(string) ///
          graph ///
          NOTable ///
          ALLCases ]

    // =========================================================================
    // 1. VALIDATE
    // =========================================================================
    marksample touse
    
    if "`ic'" == "" local ic "bic"
    local ic = lower("`ic'")
    
    if !inrange(`case', 1, 5) {
        di as err "case() must be 1-5"
        exit 198
    }
    
    if "`transform'" == "" local transform "level"
    local transform = lower("`transform'")
    if !inlist("`transform'", "level", "log", "both") {
        di as err "transform() must be level, log, or both"
        exit 198
    }
    
    // Parse variables
    tokenize `varlist'
    local depvar "`1'"
    macro shift
    local indvars "`*'"
    local nregs : word count `indvars'
    
    if "`allcases'" != "" {
        local case_list "2 3 5"
    }
    else {
        local case_list "`case'"
    }
    
    if "`transform'" == "both" {
        local tr_list "level log"
    }
    else {
        local tr_list "`transform'"
    }

    // =========================================================================
    // 2. PRESERVE AND PREPARE
    // =========================================================================
    preserve
    qui keep if `touse'
    qui count
    local T = r(N)
    
    if `initobs' >= `T' {
        di as err "initobs() >= T=`T'"
        exit 198
    }
    
    local nwindows = `T' - `initobs' + 1
    
    qui tsset
    local timevar = r(timevar)
    local tsfmt : format `timevar'

    // =========================================================================
    // 3. HEADER
    // =========================================================================
    if "`notable'" == "" {
        di as txt ""
        di as txt "{hline 78}"
        di as txt "{bf:Recursive ARDL Bounds Test}"
        di as txt "{hline 78}"
        di as txt _col(5) "Dependent variable: " as res "`depvar'"
        di as txt _col(5) "Independent var(s) : " as res "`indvars'"
        di as txt _col(5) "Sample size (T)    : " as res "`T'"
        di as txt _col(5) "Initial obs        : " as res "`initobs'"
        di as txt _col(5) "Max lag length     : " as res "`maxlag'"
        di as txt _col(5) "IC for lag select  : " as res upper("`ic'")
        di as txt _col(5) "PSS Case(s)        : " as res "`case_list'"
        di as txt _col(5) "Transformation(s)  : " as res "`tr_list'"
        di as txt _col(5) "Significance level : " as res "`level'%"
        if "`nosimulate'" == "" {
            di as txt _col(5) "Simulated CVs      : " as res "Yes (`nsim' reps)"
        }
        di as txt "{hline 78}"
    }

    // =========================================================================
    // 4. SIMULATE CRITICAL VALUES
    // =========================================================================
    // For recursive, we need CVs for each expanding sample size
    // We simulate for a grid of representative sizes and interpolate
    if "`nosimulate'" == "" {
        di as txt ""
        di as txt _col(3) "{bf:Step 1: Simulating critical values for recursive samples...}"
        
        // Create a representative grid of sample sizes
        local cvgrid ""
        local step = max(1, int((`T' - `initobs') / 10))
        forvalues s = `initobs'(`step')`T' {
            local cvgrid "`cvgrid' `s'"
        }
        // Ensure we include the last sample size
        local last : word count `cvgrid'
        local lastval : word `last' of `cvgrid'
        if `lastval' != `T' {
            local cvgrid "`cvgrid' `T'"
        }
        
        _rardl_simulate, tobs(`cvgrid') nregs(`nregs') nsim(`nsim') ///
            maxlag(`maxlag') ic(`ic') seed(`seed') notable
        
        foreach m of local case_list {
            tempname rcv_m`m'
            mat `rcv_m`m'' = r(cv_model`m')
        }
    }

    // =========================================================================
    // 5. RECURSIVE ESTIMATION
    // =========================================================================
    di as txt ""
    di as txt _col(3) "{bf:Step 2: Recursive bounds testing...}"
    
    foreach tr of local tr_list {
        
        if "`tr'" == "log" {
            local trlbl "Log"
        }
        else {
            local trlbl "Level"
        }
        
        // Transform variables
        capture drop _rec_dep
        foreach iv of local indvars {
            capture drop _rec_`iv'
        }
        
        if "`tr'" == "log" {
            qui gen double _rec_dep = ln(`depvar')
            foreach iv of local indvars {
                qui gen double _rec_`iv' = ln(`iv')
            }
        }
        else {
            qui gen double _rec_dep = `depvar'
            foreach iv of local indvars {
                qui gen double _rec_`iv' = `iv'
            }
        }
        
        local rec_indvars ""
        foreach iv of local indvars {
            local rec_indvars "`rec_indvars' _rec_`iv'"
        }

        foreach cas of local case_list {
            
            tempname rec_mat
            mat `rec_mat' = J(`nwindows', 10, .)
            // Cols: end_obs, F, UCV, z_bt, ecm, lr_beta, sr_delta, sr_fstat, best_p, best_q
            
            // Always compute asymptotic CVs for this case
            local aucv = .
            local alcv = .
            if `cas' == 1 {
                if `level' == 1      local aucv = 6.84
                if `level' == 1      local alcv = 4.94
                if `level' == 5      local aucv = 4.94
                if `level' == 5      local alcv = 3.62
                if `level' == 10     local aucv = 4.04
                if `level' == 10     local alcv = 3.02
            }
            if `cas' == 2 {
                if `level' == 1      local aucv = 8.74
                if `level' == 1      local alcv = 6.84
                if `level' == 5      local aucv = 6.56
                if `level' == 5      local alcv = 4.94
                if `level' == 10     local aucv = 5.62
                if `level' == 10     local alcv = 4.04
            }
            if `cas' == 3 {
                if `level' == 1      local aucv = 7.84
                if `level' == 1      local alcv = 6.84
                if `level' == 5      local aucv = 5.73
                if `level' == 5      local alcv = 4.94
                if `level' == 10     local aucv = 4.85
                if `level' == 10     local alcv = 4.04
            }
            if `cas' == 4 {
                if `level' == 1      local aucv = 8.74
                if `level' == 1      local alcv = 7.52
                if `level' == 5      local aucv = 6.56
                if `level' == 5      local alcv = 5.59
                if `level' == 10     local aucv = 5.62
                if `level' == 10     local alcv = 4.68
            }
            if `cas' == 5 {
                if `level' == 1      local aucv = 8.74
                if `level' == 1      local alcv = 7.52
                if `level' == 5      local aucv = 6.56
                if `level' == 5      local alcv = 5.59
                if `level' == 10     local aucv = 5.62
                if `level' == 10     local alcv = 4.68
            }
            
            forvalues widx = 1/`nwindows' {
                local endobs = `initobs' + `widx' - 1
                
                // --- Get critical value for this sample size ---
                local ucv = .
                if "`nosimulate'" == "" {
                    // Interpolate from simulated grid
                    local nrows = rowsof(`rcv_m`cas'')
                    local found = 0
                    
                    // Find bracketing rows
                    forvalues rr = 1/`nrows' {
                        local ts_rr = el(`rcv_m`cas'', `rr', 1)
                        if `ts_rr' >= `endobs' & `found' == 0 {
                            if `level' == 1 {
                                local ucv = el(`rcv_m`cas'', `rr', 3)
                            }
                            else if `level' == 5 {
                                local ucv = el(`rcv_m`cas'', `rr', 5)
                            }
                            else {
                                local ucv = el(`rcv_m`cas'', `rr', 7)
                            }
                            local found = 1
                        }
                    }
                    if `found' == 0 {
                        // Use last row
                        if `level' == 1 {
                            local ucv = el(`rcv_m`cas'', `nrows', 3)
                        }
                        else if `level' == 5 {
                            local ucv = el(`rcv_m`cas'', `nrows', 5)
                        }
                        else {
                            local ucv = el(`rcv_m`cas'', `nrows', 7)
                        }
                    }
                }
                else {
                    // Asymptotic
                    if `cas' == 3 {
                        if `level' == 1      local ucv = 7.84
                        else if `level' == 5 local ucv = 5.73
                        else                 local ucv = 4.85
                    }
                    else if `cas' == 5 {
                        if `level' == 1      local ucv = 8.74
                        else if `level' == 5 local ucv = 6.56
                        else                 local ucv = 5.62
                    }
                    else {
                        // Generic fallback
                        if `level' == 1      local ucv = 7.0
                        else if `level' == 5 local ucv = 5.0
                        else                 local ucv = 4.0
                    }
                }

                // --- ARDL(p,q) lag selection: grid search ---
                local best_p = 1
                local best_q = 0
                local best_ic_v = .
                forvalues pp = 1/`maxlag' {
                    forvalues qq = 0/`maxlag' {
                        local regvars "L._rec_dep"
                        foreach riv of local rec_indvars {
                            local regvars "`regvars' L.`riv'"
                        }
                        forvalues ll = 1/`pp' {
                            local regvars "`regvars' L`ll'.D._rec_dep"
                        }
                        foreach riv of local rec_indvars {
                            forvalues ll = 0/`qq' {
                                if `ll' == 0 {
                                    local regvars "`regvars' D.`riv'"
                                }
                                else {
                                    local regvars "`regvars' L`ll'.D.`riv'"
                                }
                            }
                        }
                        
                        local nocon ""
                        local det ""
                        if `cas' == 1 local nocon "noconstant"
                        if inlist(`cas', 4, 5) local det "t"
                        
                        capture qui reg D._rec_dep `regvars' `det' in 1/`endobs', `nocon'
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

                // --- Final estimation with ARDL(best_p, best_q) ---
                local regvars "L._rec_dep"
                local testvars "L._rec_dep"
                local sr_testvars ""
                foreach riv of local rec_indvars {
                    local regvars "`regvars' L.`riv'"
                    local testvars "`testvars' L.`riv'"
                }
                forvalues ll = 1/`best_p' {
                    local regvars "`regvars' L`ll'.D._rec_dep"
                }
                foreach riv of local rec_indvars {
                    forvalues ll = 0/`best_q' {
                        if `ll' == 0 {
                            local regvars "`regvars' D.`riv'"
                            local sr_testvars "`sr_testvars' D.`riv'"
                        }
                        else {
                            local regvars "`regvars' L`ll'.D.`riv'"
                            local sr_testvars "`sr_testvars' L`ll'.D.`riv'"
                        }
                    }
                }
                
                local nocon ""
                local det ""
                if `cas' == 1 local nocon "noconstant"
                if inlist(`cas', 4, 5) {
                    local det "t"
                    if `cas' == 4 local testvars "`testvars' t"
                }
                
                local fstat = .
                local ecm_c = .
                local lr_beta = .
                local sr_delta = .
                local sr_fstat = .
                capture qui reg D._rec_dep `regvars' `det' in 1/`endobs', `nocon'
                if _rc == 0 {
                    local ecm_c = _b[L._rec_dep]
                    
                    // LR beta
                    local firstriv : word 1 of `rec_indvars'
                    capture local lr_beta = _b[L.`firstriv']
                    
                    // SR delta
                    capture local sr_delta = _b[D.`firstriv']
                    
                    // LR F-test
                    capture qui testparm `testvars'
                    if _rc == 0 {
                        local fstat = r(F)
                    }
                    
                    // SR F-test
                    if "`sr_testvars'" != "" {
                        capture qui testparm `sr_testvars'
                        if _rc == 0 {
                            local sr_fstat = r(F)
                        }
                    }
                }
                
                local zbt = .
                if `fstat' != . & `ucv' > 0 {
                    local zbt = `fstat' / `ucv'
                }

                mat `rec_mat'[`widx', 1] = `endobs'
                mat `rec_mat'[`widx', 2] = `fstat'
                mat `rec_mat'[`widx', 3] = `ucv'
                mat `rec_mat'[`widx', 4] = `zbt'
                mat `rec_mat'[`widx', 5] = `ecm_c'
                mat `rec_mat'[`widx', 6] = `lr_beta'
                mat `rec_mat'[`widx', 7] = `sr_delta'
                mat `rec_mat'[`widx', 8] = `sr_fstat'
                mat `rec_mat'[`widx', 9] = `best_p'
                mat `rec_mat'[`widx', 10] = `best_q'
                
                if mod(`widx', 50) == 0 {
                    di as txt "." _continue
                }
            }
            di as txt " done"

            // -----------------------------------------------------------------
            // Verdict
            // -----------------------------------------------------------------
            local ncoint = 0
            local first_coint = .
            local last_coint = .
            forvalues w = 1/`nwindows' {
                local zv = el(`rec_mat', `w', 4)
                if `zv' != . & `zv' > 1 {
                    local ++ncoint
                    if `first_coint' == . local first_coint = `w'
                    local last_coint = `w'
                }
            }
            local pct_coint = 100 * `ncoint' / `nwindows'
            
            if `pct_coint' >= 95 {
                local verdict "Cointegration w/ rare exceptions"
            }
            else if `pct_coint' >= 80 {
                local verdict "Cointegration w/ exceptions"
            }
            else if `pct_coint' >= 50 {
                local verdict "Inconsistent"
            }
            else if `pct_coint' >= 20 {
                local verdict "No cointegration w/ exceptions"
            }
            else if `pct_coint' >= 5 {
                local verdict "No cointegration w/ rare exceptions"
            }
            else {
                local verdict "No cointegration"
            }

            // -----------------------------------------------------------------
            // Display
            // -----------------------------------------------------------------
            if "`notable'" == "" {
                if `cas' == 2 local caslbl "Restricted intercept"
                if `cas' == 3 local caslbl "Unrestricted intercept"
                if `cas' == 5 local caslbl "Unrestrict. intercept + trend"
                if `cas' == 1 local caslbl "No intercept, No trend"
                if `cas' == 4 local caslbl "Unrestrict. intercept, Restrict. trend"
                
                di as txt ""
                di as txt "{bf:Recursive ARDL — `trlbl', Case `cas' (`caslbl')}"
                di as txt "{hline 78}"
                di as txt _col(5) "Total recursive tests : " as res "`nwindows'"
                di as txt _col(5) "Cointegrated          : " as res "`ncoint' (" %5.1f `pct_coint' "%)"
                
                if `first_coint' != . {
                    local fobs = el(`rec_mat', `first_coint', 1)
                    local lobs = el(`rec_mat', `last_coint', 1)
                    local ftime : di `tsfmt' `timevar'[`fobs']
                    local ltime : di `tsfmt' `timevar'[`lobs']
                    di as txt _col(5) "First coint. at       : " as res "`ftime'"
                    di as txt _col(5) "Last coint. at        : " as res "`ltime'"
                }
                di as txt _col(5) "{bf:Verdict}              : " as res "{bf:`verdict'}"
                di as txt "{hline 78}"
                
                // Detailed tables (sampled ~20 rows)
                local rstep = max(1, int(`nwindows'/20))
                local firstriv : word 1 of `rec_indvars'
                
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
                
                forvalues w = 1(`rstep')`nwindows' {
                    local eobs = el(`rec_mat', `w', 1)
                    local fst  = el(`rec_mat', `w', 2)
                    local ucvv = el(`rec_mat', `w', 3)
                    local zbt  = el(`rec_mat', `w', 4)
                    local ecm  = el(`rec_mat', `w', 5)
                    local lrb  = el(`rec_mat', `w', 6)
                    local bp   = el(`rec_mat', `w', 9)
                    local bq   = el(`rec_mat', `w', 10)
                    
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
                            _col(53) %6.3f `ucvv' ///
                            _col(62) %6.3f `zbt' ///
                            _col(73) "`dec'"
                    }
                }
                if mod(`nwindows', `rstep') != 1 & `nwindows' > 1 {
                    local w = `nwindows'
                    local eobs = el(`rec_mat', `w', 1)
                    local fst  = el(`rec_mat', `w', 2)
                    local ucvv = el(`rec_mat', `w', 3)
                    local zbt  = el(`rec_mat', `w', 4)
                    local ecm  = el(`rec_mat', `w', 5)
                    local lrb  = el(`rec_mat', `w', 6)
                    local bp   = el(`rec_mat', `w', 9)
                    local bq   = el(`rec_mat', `w', 10)
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
                            _col(53) %6.3f `ucvv' ///
                            _col(62) %6.3f `zbt' ///
                            _col(73) "`dec'"
                    }
                }
                di as txt "{hline 78}"
                di as txt _col(2) "ARDL(p,q)  ECM(a)=L.`depvar'  LR(b)=L.`firstriv'  *** = coint."
                
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
                
                forvalues w = 1(`rstep')`nwindows' {
                    local eobs = el(`rec_mat', `w', 1)
                    local srd  = el(`rec_mat', `w', 7)
                    local srf  = el(`rec_mat', `w', 8)
                    local ecm  = el(`rec_mat', `w', 5)
                    local zbt  = el(`rec_mat', `w', 4)
                    
                    local sr_pv = .
                    if `srf' != . {
                        local sr_ndf = `nregs' * (`best_p'+1)
                        local sr_dfr = `endobs' - `sr_ndf' - `nregs' - 5
                        if `sr_dfr' > 0 {
                            capture local sr_pv = Ftail(`sr_ndf', `sr_dfr', `srf')
                        }
                    }
                    
                    local srdec "   "
                    if `sr_pv' != . & `sr_pv' < `level'/100 local srdec "***"
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
                if mod(`nwindows', `rstep') != 1 & `nwindows' > 1 {
                    local w = `nwindows'
                    local eobs = el(`rec_mat', `w', 1)
                    local srd  = el(`rec_mat', `w', 7)
                    local srf  = el(`rec_mat', `w', 8)
                    local ecm  = el(`rec_mat', `w', 5)
                    local zbt  = el(`rec_mat', `w', 4)
                    local sr_pv = .
                    if `srf' != . {
                        local sr_ndf = `nregs' * (`best_p'+1)
                        local sr_dfr = `endobs' - `sr_ndf' - `nregs' - 5
                        if `sr_dfr' > 0 {
                            capture local sr_pv = Ftail(`sr_ndf', `sr_dfr', `srf')
                        }
                    }
                    local srdec "   "
                    if `sr_pv' != . & `sr_pv' < `level'/100 local srdec "***"
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
                di as txt _col(2) "SR(d)=D.`firstriv'  *** = SR significant at `level'%"
                
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
                
                forvalues w = 1(`rstep')`nwindows' {
                    local eobs = el(`rec_mat', `w', 1)
                    local fst  = el(`rec_mat', `w', 2)
                    local simucv = el(`rec_mat', `w', 3)
                    
                    local tlab ""
                    if `eobs' != . {
                        local tlab : di `tsfmt' `timevar'[`eobs']
                    }
                    
                    if `fst' != . {
                        local adec "   "
                        if `fst' > `aucv' local adec "***"
                        
                        if "`nosimulate'" == "" {
                            local sdec "   "
                            if `fst' > `simucv' local sdec "***"
                            local agree "Yes"
                            if "`adec'" != "`sdec'" local agree " NO"
                            
                            di as res _col(1) %10s "`tlab'" ///
                                _col(13) %7.3f `fst' ///
                                _col(23) %7.3f `aucv' ///
                                _col(36) "`adec'" ///
                                _col(43) %7.3f `simucv' ///
                                _col(56) "`sdec'" ///
                                _col(64) "`agree'"
                        }
                        else {
                            local zone "Inconclusive"
                            local zdec "   "
                            if `fst' > `aucv' {
                                local zone "Cointegration"
                                local zdec "***"
                            }
                            else if `fst' < `alcv' {
                                local zone "No coint."
                            }
                            
                            di as res _col(1) %10s "`tlab'" ///
                                _col(13) %7.3f `fst' ///
                                _col(23) %7.3f `aucv' ///
                                _col(35) %7.3f `alcv' ///
                                _col(47) %13s "`zone'" ///
                                _col(61) "`zdec'"
                        }
                    }
                }
                // Always show last row
                if mod(`nwindows', `rstep') != 1 & `nwindows' > 1 {
                    local w = `nwindows'
                    local eobs = el(`rec_mat', `w', 1)
                    local fst  = el(`rec_mat', `w', 2)
                    local simucv = el(`rec_mat', `w', 3)
                    local tlab ""
                    if `eobs' != . {
                        local tlab : di `tsfmt' `timevar'[`eobs']
                    }
                    if `fst' != . {
                        local adec "   "
                        if `fst' > `aucv' local adec "***"
                        if "`nosimulate'" == "" {
                            local sdec "   "
                            if `fst' > `simucv' local sdec "***"
                            local agree "Yes"
                            if "`adec'" != "`sdec'" local agree " NO"
                            di as res _col(1) %10s "`tlab'" ///
                                _col(13) %7.3f `fst' ///
                                _col(23) %7.3f `aucv' ///
                                _col(36) "`adec'" ///
                                _col(43) %7.3f `simucv' ///
                                _col(56) "`sdec'" ///
                                _col(64) "`agree'"
                        }
                        else {
                            local zone "Inconclusive"
                            local zdec "   "
                            if `fst' > `aucv' {
                                local zone "Cointegration"
                                local zdec "***"
                            }
                            else if `fst' < `alcv' {
                                local zone "No coint."
                            }
                            di as res _col(1) %10s "`tlab'" ///
                                _col(13) %7.3f `fst' ///
                                _col(23) %7.3f `aucv' ///
                                _col(35) %7.3f `alcv' ///
                                _col(47) %13s "`zone'" ///
                                _col(61) "`zdec'"
                        }
                    }
                }
                di as txt "{hline 78}"
                if "`nosimulate'" == "" {
                    di as txt _col(2) "Asym=PSS(2001) T->inf   Sim=MC (finite-sample)"
                }
                else {
                    di as txt _col(2) "UCV=I(1) bound  LCV=I(0) bound  PSS(2001) asymptotic"
                    di as txt _col(2) "Note: use simulation for finite-sample CVs (remove nosimulate)"
                }
            }

            // Graph (must run BEFORE return matrix which consumes tempname)
            local suf = cond("`tr'" == "log", "_log", "_lev")
            
            if "`graph'" != "" {
                capture drop _rec_zbt _rec_time
                qui gen double _rec_zbt = .
                qui gen double _rec_time = .
                forvalues w = 1/`nwindows' {
                    qui replace _rec_zbt = el(`rec_mat', `w', 4) in `w'
                    local eobs = el(`rec_mat', `w', 1)
                    if `eobs' != . {
                        qui replace _rec_time = `timevar'[`eobs'] in `w'
                    }
                }
                
                local gname "rardl_rec_c`cas'`suf'"
                
                capture noisily {
                    twoway (area _rec_zbt _rec_time if _rec_zbt >= 1, ///
                               color("60 170 100%30") base(1)) ///
                           (area _rec_zbt _rec_time if _rec_zbt < 1, ///
                               color("220 50 47%15") base(0)) ///
                           (line _rec_zbt _rec_time, ///
                               lcolor("24 54 104") lwidth(medium)) ///
                           , yline(1, lcolor("220 50 47") lpattern(dash) lwidth(medthick)) ///
                           ytitle("z{sub:bt} = F-stat / UCV", size(medium)) ///
                           xtitle("Sample ending period", size(medium)) ///
                           ylabel(, labsize(small) grid glcolor(gs14%50)) ///
                           xlabel(, labsize(small) grid glcolor(gs14%50) angle(45)) ///
                           legend(off) ///
                           note("Recursive ARDL (`trlbl', Case `cas'): `verdict'", ///
                               size(vsmall) color(gs6)) ///
                           scheme(s2color) name(`gname', replace)
                    
                    qui graph export "`gname'.png", replace width(1400)
                }
            }

            // Store (return matrix consumes the tempname)
            mat colnames `rec_mat' = end_obs F_stat UCV z_bt ecm_coef
            return matrix rec_c`cas'`suf' = `rec_mat'
            return local verdict_c`cas'`suf' "`verdict'"
        }
    }

    // =========================================================================
    // 6. RETURN
    // =========================================================================
    return scalar T = `T'
    return scalar initobs = `initobs'
    return scalar nwindows = `nwindows'
    return scalar nregs = `nregs'
    return local depvar "`depvar'"
    return local indvars "`indvars'"

    restore
end
