*! _rardl_rgranger — Recursive Granger Causality Test
*! Version 1.0.0
*! Implements recursive Granger causality as in Khan, Shahbaz & Napari (2023)
*! Tests subsample stability of short-run causal relationships

capture program drop _rardl_rgranger
program define _rardl_rgranger, rclass
    version 17

    syntax varlist(min=2 max=2 ts) [if] [in], ///
        [ INITobs(integer 60) ///
          maxlag(integer 4) ///
          ic(string) ///
          TRANSform(string) ///
          Level(integer 5) ///
          graph ///
          NOTable ]

    // =========================================================================
    // 1. VALIDATE
    // =========================================================================
    marksample touse
    
    if "`ic'" == "" local ic "bic"
    local ic = lower("`ic'")
    
    if "`transform'" == "" local transform "level"
    local transform = lower("`transform'")
    if !inlist("`transform'", "level", "log", "both") {
        di as err "transform() must be level, log, or both"
        exit 198
    }
    
    tokenize `varlist'
    local depvar "`1'"
    local indvar "`2'"
    
    if "`transform'" == "both" {
        local tr_list "level log"
    }
    else {
        local tr_list "`transform'"
    }

    // =========================================================================
    // 2. HEADER
    // =========================================================================
    if "`notable'" == "" {
        di as txt ""
        di as txt "{hline 78}"
        di as txt "{bf:Recursive Granger Causality Test}"
        di as txt "{hline 78}"
        di as txt _col(5) "Variable 1        : " as res "`depvar'"
        di as txt _col(5) "Variable 2        : " as res "`indvar'"
        di as txt _col(5) "Initial obs       : " as res "`initobs'"
        di as txt _col(5) "Max lag length    : " as res "`maxlag'"
        di as txt _col(5) "IC for lag select : " as res upper("`ic'")
        di as txt _col(5) "Transformation    : " as res "`tr_list'"
        di as txt _col(5) "Significance level: " as res "`level'%"
        di as txt "{hline 78}"
    }

    // =========================================================================
    // 3. PRESERVE AND PREPARE
    // =========================================================================
    preserve
    qui keep if `touse'
    qui count
    local T = r(N)
    
    if `initobs' >= `T' {
        di as err "initobs() must be less than T=`T'"
        exit 198
    }
    
    local nwindows = `T' - `initobs' + 1
    
    qui tsset
    local timevar = r(timevar)

    // =========================================================================
    // 4. RECURSIVE GRANGER CAUSALITY
    // =========================================================================
    foreach tr of local tr_list {
        
        // Create transformed variables
        capture drop _rgc_y1 _rgc_y2
        if "`tr'" == "level" {
            qui gen double _rgc_y1 = `depvar'
            qui gen double _rgc_y2 = `indvar'
            local trlbl "Level"
        }
        else {
            qui gen double _rgc_y1 = ln(`depvar')
            qui gen double _rgc_y2 = ln(`indvar')
            local trlbl "Log"
        }

        // Matrices: direction 1 (y2 -> y1) and direction 2 (y1 -> y2)
        tempname gc_12 gc_21
        mat `gc_12' = J(`nwindows', 4, .)  // end_obs, F, cv, z
        mat `gc_21' = J(`nwindows', 4, .)

        local widx = 0
        forvalues endobs = `initobs'/`T' {
            local ++widx

            // --- Lag selection for VAR ---
            local best_p = 1
            local best_ic_v = .
            forvalues pp = 1/`maxlag' {
                capture qui var _rgc_y1 _rgc_y2 in 1/`endobs', lags(1/`pp')
                if _rc == 0 {
                    if "`ic'" == "bic" {
                        local this_ic = e(sbic)
                    }
                    else if "`ic'" == "aic" {
                        local this_ic = e(aic)
                    }
                    else {
                        local this_ic = e(hqic)
                    }
                    if `this_ic' < `best_ic_v' {
                        local best_ic_v = `this_ic'
                        local best_p = `pp'
                    }
                }
            }

            // --- Estimate VAR and test Granger causality ---
            capture qui var _rgc_y1 _rgc_y2 in 1/`endobs', lags(1/`best_p')
            if _rc == 0 {
                local nn = e(N)
                
                // Direction 1: y2 does not Granger cause y1
                capture qui vargranger
                if _rc == 0 {
                    // vargranger stores r(gstats) with structure:
                    // Row 1: y2 excluded from y1 eq (chi2, df, p)
                    // Row 2: ALL excluded from y1 eq
                    // Row 3: y1 excluded from y2 eq (chi2, df, p)
                    // Row 4: ALL excluded from y2 eq
                    mat _gc_result = r(gstats)
                    local nrgc = rowsof(_gc_result)
                    
                    // chi2 and df for direction y2->y1
                    local chi2_21 = el(_gc_result, 1, 1)
                    local df_21   = el(_gc_result, 1, 2)
                    local p_21    = el(_gc_result, 1, 3)
                    
                    // chi2 and df for direction y1->y2
                    // With 2 variables: row 3 has the other direction
                    local r_12 = min(3, `nrgc')
                    if `nrgc' == 2 local r_12 = 2
                    local chi2_12 = el(_gc_result, `r_12', 1)
                    local df_12   = el(_gc_result, `r_12', 2)
                    local p_12    = el(_gc_result, `r_12', 3)
                    
                    // Convert chi2 to F: F = chi2/df
                    local f_21 = .
                    local f_12 = .
                    if `df_21' > 0 & `chi2_21' != . {
                        local f_21 = `chi2_21' / `df_21'
                    }
                    if `df_12' > 0 & `chi2_12' != . {
                        local f_12 = `chi2_12' / `df_12'
                    }
                    
                    // Critical value at given level
                    local df1 = `best_p'
                    local df2 = `nn' - 2*`best_p' - 1
                    local cv_f = invFtail(`df1', `df2', `level'/100)
                    
                    // z = F/CV; reject if z > 1
                    local z_21 = .
                    local z_12 = .
                    if `cv_f' > 0 {
                        if `f_21' != . local z_21 = `f_21' / `cv_f'
                        if `f_12' != . local z_12 = `f_12' / `cv_f'
                    }
                    
                    mat `gc_21'[`widx', 1] = `endobs'
                    mat `gc_21'[`widx', 2] = `f_21'
                    mat `gc_21'[`widx', 3] = `cv_f'
                    mat `gc_21'[`widx', 4] = `z_21'
                    
                    mat `gc_12'[`widx', 1] = `endobs'
                    mat `gc_12'[`widx', 2] = `f_12'
                    mat `gc_12'[`widx', 3] = `cv_f'
                    mat `gc_12'[`widx', 4] = `z_12'
                    
                    capture mat drop _gc_result
                }
            }
        }

        // -----------------------------------------------------------------
        // Determine verdicts
        // -----------------------------------------------------------------
        foreach dir in 12 21 {
            local nreject = 0
            local ntotal = 0
            forvalues w = 1/`nwindows' {
                local zv = el(`gc_`dir'', `w', 4)
                if `zv' != . {
                    local ++ntotal
                    if `zv' > 1 {
                        local ++nreject
                    }
                }
            }
            local pct_`dir' = 0
            if `ntotal' > 0 {
                local pct_`dir' = 100 * `nreject' / `ntotal'
            }
            
            if `pct_`dir'' >= 95 {
                local verdict_`dir' "Consistently Reject (Granger causes)"
            }
            else if `pct_`dir'' >= 80 {
                local verdict_`dir' "Reject w/ rare exceptions"
            }
            else if `pct_`dir'' >= 50 {
                local verdict_`dir' "Inconsistent"
            }
            else if `pct_`dir'' >= 20 {
                local verdict_`dir' "Fail to reject w/ exceptions"
            }
            else if `pct_`dir'' >= 5 {
                local verdict_`dir' "Fail to reject w/ rare exceptions"
            }
            else {
                local verdict_`dir' "Consistently fail to reject"
            }
        }

        // -----------------------------------------------------------------
        // Display
        // -----------------------------------------------------------------
        if "`notable'" == "" {
            di as txt ""
            di as txt "{bf:Recursive Granger Causality (`trlbl' prices)}"
            di as txt "{hline 78}"
            
            if "`tr'" == "log" {
                local d1lbl "log(`indvar') does not GC log(`depvar')"
                local d2lbl "log(`depvar') does not GC log(`indvar')"
            }
            else {
                local d1lbl "`indvar' does not Granger cause `depvar'"
                local d2lbl "`depvar' does not Granger cause `indvar'"
            }
            
            di as txt _col(3) "{bf:H0: `d1lbl'}"
            di as txt _col(5) "Reject     : " as res "`=round(`pct_21',0.1)'%"
            di as txt _col(5) "{bf:Verdict}  : " as res "{bf:`verdict_21'}"
            di as txt ""
            di as txt _col(3) "{bf:H0: `d2lbl'}"
            di as txt _col(5) "Reject     : " as res "`=round(`pct_12',0.1)'%"
            di as txt _col(5) "{bf:Verdict}  : " as res "{bf:`verdict_12'}"
            di as txt "{hline 78}"
            
            // Detailed table (sampled ~20 rows)
            local rstep = max(1, int(`nwindows'/20))
            qui tsset
            local tsfmt : format `timevar'
            
            di as txt ""
            di as txt _col(2) "{bf:End Obs}" ///
                _col(14) "{bf:Period}" ///
                _col(27) "{bf:F(`indvar')}" ///
                _col(39) "{bf:z-GC}" ///
                _col(46) "{bf:Dec}" ///
                _col(52) "{bf:F(`depvar')}" ///
                _col(64) "{bf:z-GC}" ///
                _col(71) "{bf:Dec}"
            di as txt _col(27) "{bf:-> `depvar'}" ///
                _col(52) "{bf:-> `indvar'}"
            di as txt "{hline 78}"
            
            forvalues w = 1(`rstep')`nwindows' {
                local eobs21 = el(`gc_21', `w', 1)
                local f21    = el(`gc_21', `w', 2)
                local z21    = el(`gc_21', `w', 4)
                local f12    = el(`gc_12', `w', 2)
                local z12    = el(`gc_12', `w', 4)
                
                local tlab ""
                if `eobs21' != . {
                    local tlab : di `tsfmt' `timevar'[`eobs21']
                }
                
                local s21 "   "
                local s12 "   "
                if `z21' != . & `z21' > 1 local s21 "***"
                if `z12' != . & `z12' > 1 local s12 "***"
                
                if `f21' != . {
                    di as res _col(2) %6.0f `eobs21' ///
                        _col(13) %12s "`tlab'" ///
                        _col(27) %7.3f `f21' ///
                        _col(37) %6.3f `z21' ///
                        _col(46) "`s21'" ///
                        _col(52) %7.3f `f12' ///
                        _col(62) %6.3f `z12' ///
                        _col(71) "`s12'"
                }
            }
            // Always show last row
            if mod(`nwindows', `rstep') != 1 & `nwindows' > 1 {
                local w = `nwindows'
                local eobs21 = el(`gc_21', `w', 1)
                local f21    = el(`gc_21', `w', 2)
                local z21    = el(`gc_21', `w', 4)
                local f12    = el(`gc_12', `w', 2)
                local z12    = el(`gc_12', `w', 4)
                local tlab ""
                if `eobs21' != . {
                    local tlab : di `tsfmt' `timevar'[`eobs21']
                }
                local s21 "   "
                local s12 "   "
                if `z21' != . & `z21' > 1 local s21 "***"
                if `z12' != . & `z12' > 1 local s12 "***"
                if `f21' != . {
                    di as res _col(2) %6.0f `eobs21' ///
                        _col(13) %12s "`tlab'" ///
                        _col(27) %7.3f `f21' ///
                        _col(37) %6.3f `z21' ///
                        _col(46) "`s21'" ///
                        _col(52) %7.3f `f12' ///
                        _col(62) %6.3f `z12' ///
                        _col(71) "`s12'"
                }
            }
            di as txt "{hline 78}"
            di as txt _col(3) "Note: *** denotes Granger causality at `level'% level"
        }

        // -----------------------------------------------------------------
        // Graph (must run BEFORE return matrix which consumes tempnames)
        // -----------------------------------------------------------------
        local suf = cond("`tr'" == "log", "_log", "_lev")
        
        if "`graph'" != "" {
            foreach dir in 21 12 {
                if "`dir'" == "21" {
                    local from "`indvar'"
                    local to "`depvar'"
                }
                else {
                    local from "`depvar'"
                    local to "`indvar'"
                }
                
                capture drop _zgc_plot _zgc_time
                qui gen double _zgc_plot = .
                qui gen double _zgc_time = .
                forvalues w = 1/`nwindows' {
                    qui replace _zgc_plot = el(`gc_`dir'', `w', 4) in `w'
                    local eobs = el(`gc_`dir'', `w', 1)
                    if `eobs' != . {
                        qui replace _zgc_time = `timevar'[`eobs'] in `w'
                    }
                }
                
                local gname "rgc_`from'_to_`to'`suf'"
                
                if "`tr'" == "log" {
                    local gtitle "log(`from') {&rarr} log(`to')"
                }
                else {
                    local gtitle "`from' {&rarr} `to'"
                }
                
                capture noisily {
                    twoway (area _zgc_plot _zgc_time if _zgc_plot >= 1, ///
                               color("60 170 100%30") base(1)) ///
                           (area _zgc_plot _zgc_time if _zgc_plot < 1, ///
                               color("220 50 47%15") base(0)) ///
                           (line _zgc_plot _zgc_time, ///
                               lcolor("24 54 104") lwidth(medium)) ///
                           , yline(1, lcolor("220 50 47") lpattern(dash) lwidth(medthick)) ///
                           ytitle("z{sub:GC}", size(medium)) ///
                           xtitle("Sample ending period", size(medium)) ///
                           ylabel(, labsize(small) grid glcolor(gs14%50)) ///
                           xlabel(, labsize(small) grid glcolor(gs14%50) angle(45)) ///
                           legend(off) ///
                           note("`gtitle': `verdict_`dir''", ///
                               size(vsmall) color(gs6)) ///
                           scheme(s2color) name(`gname', replace)
                    
                    qui graph export "`gname'.png", replace width(1400)
                }
            }
        }

        // Store matrices (return matrix consumes tempnames)
        mat colnames `gc_21' = end_obs F_stat CV z_gc
        mat colnames `gc_12' = end_obs F_stat CV z_gc
        return matrix gc_`indvar'_to_`depvar'`suf' = `gc_21'
        return matrix gc_`depvar'_to_`indvar'`suf' = `gc_12'
        return local verdict_`indvar'_to_`depvar'`suf' "`verdict_21'"
        return local verdict_`depvar'_to_`indvar'`suf' "`verdict_12'"
    }

    // =========================================================================
    // 5. RETURN
    // =========================================================================
    return scalar nwindows = `nwindows'
    return scalar initobs = `initobs'
    return scalar T = `T'
    
    restore
end
