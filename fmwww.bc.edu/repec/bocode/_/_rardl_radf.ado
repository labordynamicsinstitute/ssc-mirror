*! _rardl_radf — Recursive Augmented Dickey-Fuller test
*! Version 1.0.0
*! Implements recursive ADF as in Khan, Shahbaz & Napari (2023, Resources Policy)
*! Tests subsample stability of stationarity using expanding windows

capture program drop _rardl_radf
program define _rardl_radf, rclass
    version 17

    syntax varlist(min=1 ts) [if] [in], ///
        [ INITobs(integer 60) ///
          TRANSform(string) ///
          ADFcase(string) ///
          maxlag(integer 4) ///
          ic(string) ///
          Level(integer 5) ///
          graph ///
          NOTable ]

    // =========================================================================
    // 1. VALIDATE AND SET DEFAULTS
    // =========================================================================
    marksample touse
    
    if "`transform'" == "" local transform "all"
    local transform = lower("`transform'")
    if !inlist("`transform'", "level", "log", "diff", "dlog", "all") {
        di as err "transform() must be level, log, diff, dlog, or all"
        exit 198
    }
    
    if "`adfcase'" == "" local adfcase "all"
    local adfcase = lower("`adfcase'")
    if !inlist("`adfcase'", "2", "3", "all") {
        di as err "adfcase() must be 2, 3, or all"
        exit 198
    }
    
    if "`ic'" == "" local ic "bic"
    local ic = lower("`ic'")
    
    // Build transformation list
    if "`transform'" == "all" {
        local trans_list "level log diff dlog"
    }
    else {
        local trans_list "`transform'"
    }
    
    // Build ADF case list
    if "`adfcase'" == "all" {
        local case_list "2 3"
    }
    else {
        local case_list "`adfcase'"
    }

    // =========================================================================
    // 2. HEADER
    // =========================================================================
    local nvars : word count `varlist'
    
    if "`notable'" == "" {
        di as txt ""
        di as txt "{hline 78}"
        di as txt "{bf:Recursive Augmented Dickey-Fuller Unit Root Test}"
        di as txt "{hline 78}"
        di as txt _col(5) "Variables         : " as res "`varlist'"
        di as txt _col(5) "Initial obs       : " as res "`initobs'"
        di as txt _col(5) "Max lag length    : " as res "`maxlag'"
        di as txt _col(5) "IC for lag select : " as res upper("`ic'")
        di as txt _col(5) "Transformations   : " as res "`trans_list'"
        di as txt _col(5) "ADF Cases         : " as res "`case_list'"
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
        di as err "initobs() must be less than sample size (T=`T')"
        exit 198
    }
    
    local nwindows = `T' - `initobs' + 1
    
    // Get time variable info
    qui tsset
    local timevar = r(timevar)
    local tsfmt : format `timevar'

    // =========================================================================
    // 4. RECURSIVE ADF FOR EACH VARIABLE
    // =========================================================================
    local vnum = 0
    foreach var of local varlist {
        local ++vnum

        foreach tr of local trans_list {
            
            // Create transformed variable
            capture drop _radf_y
            capture drop _radf_tmp
            if "`tr'" == "level" {
                qui gen double _radf_y = `var'
                local trlbl "Level"
            }
            else if "`tr'" == "log" {
                qui gen double _radf_y = ln(`var')
                local trlbl "Log"
            }
            else if "`tr'" == "diff" {
                qui gen double _radf_y = D.`var'
                local trlbl "1st Diff"
            }
            else if "`tr'" == "dlog" {
                qui gen double _radf_tmp = ln(`var')
                qui gen double _radf_y = D._radf_tmp
                capture drop _radf_tmp
                local trlbl "Diff Log"
            }

            foreach cas of local case_list {
                
                if `cas' == 2 local caslbl "Intercept"
                if `cas' == 3 local caslbl "Intercept + Trend"

                // -----------------------------------------------------------------
                // Recursive loop: estimate ADF from initobs to T
                // -----------------------------------------------------------------
                tempname zadf_mat
                mat `zadf_mat' = J(`nwindows', 4, .)
                // Cols: sample_end_obs, t_stat, cv, z_adf
                
                local widx = 0
                forvalues endobs = `initobs'/`T' {
                    local ++widx
                    
                    // ADF lag selection
                    local best_p = 0
                    local best_ic_v = .
                    forvalues pp = 0/`maxlag' {
                        if `pp' == 0 {
                            local lagterms ""
                        }
                        else {
                            local lagterms "L(1/`pp').D._radf_y"
                        }
                        
                        if `cas' == 2 {
                            capture qui reg D._radf_y L._radf_y `lagterms' in 1/`endobs'
                        }
                        else {
                            capture qui reg D._radf_y L._radf_y t `lagterms' in 1/`endobs'
                        }
                        
                        if _rc == 0 {
                            local nn = e(N)
                            local kk = e(rank)
                            if "`ic'" == "bic" {
                                local this_ic = `nn' * ln(e(rss)/`nn') + `kk' * ln(`nn')
                            }
                            else if "`ic'" == "aic" {
                                local this_ic = `nn' * ln(e(rss)/`nn') + 2 * `kk'
                            }
                            else {
                                local this_ic = `nn' * ln(e(rss)/`nn') + 2*`kk'*ln(ln(`nn'))
                            }
                            if `this_ic' < `best_ic_v' {
                                local best_ic_v = `this_ic'
                                local best_p = `pp'
                            }
                        }
                    }

                    // Estimate ADF with optimal lag
                    if `best_p' == 0 {
                        local lagterms ""
                    }
                    else {
                        local lagterms "L(1/`best_p').D._radf_y"
                    }
                    
                    local tstat = .
                    if `cas' == 2 {
                        capture qui reg D._radf_y L._radf_y `lagterms' in 1/`endobs'
                    }
                    else {
                        capture qui reg D._radf_y L._radf_y t `lagterms' in 1/`endobs'
                    }
                    if _rc == 0 {
                        local tstat = _b[L._radf_y] / _se[L._radf_y]
                    }

                    // Get critical value (approximate MacKinnon)
                    // Use Stata's built-in critical values
                    local nn = `endobs'
                    if `cas' == 2 {
                        // ADF with intercept - approximate 5% CV
                        if `level' == 1 {
                            local cv = -3.43 - 6.00/`nn' - 29.25/(`nn'^2)
                        }
                        else if `level' == 5 {
                            local cv = -2.86 - 2.74/`nn' - 3.14/(`nn'^2)
                        }
                        else {
                            local cv = -2.57 - 1.50/`nn' + 0.20/(`nn'^2)
                        }
                    }
                    else {
                        // ADF with intercept + trend
                        if `level' == 1 {
                            local cv = -3.96 - 8.35/`nn' - 47.44/(`nn'^2)
                        }
                        else if `level' == 5 {
                            local cv = -3.41 - 4.04/`nn' - 17.83/(`nn'^2)
                        }
                        else {
                            local cv = -3.13 - 2.42/`nn' - 7.58/(`nn'^2)
                        }
                    }

                    // z_ADF = t_stat / CV  (reject unit root if z > 1)
                    local zadf = .
                    if `tstat' != . & `cv' != . & `cv' != 0 {
                        local zadf = `tstat' / `cv'
                    }

                    mat `zadf_mat'[`widx', 1] = `endobs'
                    mat `zadf_mat'[`widx', 2] = `tstat'
                    mat `zadf_mat'[`widx', 3] = `cv'
                    mat `zadf_mat'[`widx', 4] = `zadf'
                }

                // -----------------------------------------------------------------
                // Determine consistency verdict
                // -----------------------------------------------------------------
                local nreject = 0
                local nfail = 0
                forvalues w = 1/`nwindows' {
                    local zv = el(`zadf_mat', `w', 4)
                    if `zv' != . {
                        if `zv' > 1 {
                            local ++nreject
                        }
                        else {
                            local ++nfail
                        }
                    }
                }
                local pct_reject = 100 * `nreject' / `nwindows'
                
                if `pct_reject' >= 95 {
                    local verdict "Consistent Stationarity"
                }
                else if `pct_reject' >= 80 {
                    local verdict "Stationarity w/ rare exceptions"
                }
                else if `pct_reject' >= 50 {
                    local verdict "Stationarity w/ exceptions"
                }
                else if `pct_reject' >= 20 {
                    if `pct_reject' < 50 & `pct_reject' >= 20 {
                        local verdict "Inconsistent / Switching"
                    }
                }
                else if `pct_reject' >= 5 {
                    local verdict "Non-stationarity w/ exceptions"
                }
                else {
                    local verdict "Consistent Non-stationarity"
                }

                // -----------------------------------------------------------------
                // Display results
                // -----------------------------------------------------------------
                if "`notable'" == "" {
                    di as txt ""
                    di as txt "{bf:`var' (`trlbl', Case `cas': `caslbl')}"
                    di as txt "{hline 78}"
                    di as txt _col(5) "Windows tested    : " as res "`nwindows'"
                    di as txt _col(5) "Reject unit root  : " as res "`nreject' (" %5.1f `pct_reject' "%)"
                    di as txt _col(5) "Fail to reject    : " as res "`nfail' (" %5.1f `=100-`pct_reject'' "%)"
                    di as txt _col(5) "{bf:Verdict}          : " as res "{bf:`verdict'}"
                    di as txt "{hline 78}"
                    
                    // Detailed table (sampled ~20 rows)
                    local tstep = max(1, int(`nwindows'/20))
                    di as txt ""
                    di as txt _col(3) "{bf:End Obs}" ///
                        _col(15) "{bf:End Period}" ///
                        _col(32) "{bf:t-stat}" ///
                        _col(44) "{bf:CV(`level'%)}" ///
                        _col(58) "{bf:z-ADF}" ///
                        _col(70) "{bf:Decision}"
                    di as txt "{hline 78}"
                    
                    forvalues w = 1(`tstep')`nwindows' {
                        local eobs = el(`zadf_mat', `w', 1)
                        local tst  = el(`zadf_mat', `w', 2)
                        local cvv  = el(`zadf_mat', `w', 3)
                        local zv   = el(`zadf_mat', `w', 4)
                        
                        local dec "Fail"
                        if `zv' != . & `zv' > 1 local dec "Reject"
                        
                        local tlab ""
                        if `eobs' != . {
                            local tlab : di `tsfmt' `timevar'[`eobs']
                        }
                        
                        if `tst' != . {
                            di as res _col(3) %6.0f `eobs' ///
                                _col(14) %12s "`tlab'" ///
                                _col(30) %8.4f `tst' ///
                                _col(42) %8.4f `cvv' ///
                                _col(56) %8.4f `zv' ///
                                _col(70) "`dec'"
                        }
                    }
                    // Always show last row
                    if mod(`nwindows', `tstep') != 1 & `nwindows' > 1 {
                        local w = `nwindows'
                        local eobs = el(`zadf_mat', `w', 1)
                        local tst  = el(`zadf_mat', `w', 2)
                        local cvv  = el(`zadf_mat', `w', 3)
                        local zv   = el(`zadf_mat', `w', 4)
                        local dec "Fail"
                        if `zv' != . & `zv' > 1 local dec "Reject"
                        local tlab ""
                        if `eobs' != . {
                            local tlab : di `tsfmt' `timevar'[`eobs']
                        }
                        if `tst' != . {
                            di as res _col(3) %6.0f `eobs' ///
                                _col(14) %12s "`tlab'" ///
                                _col(30) %8.4f `tst' ///
                                _col(42) %8.4f `cvv' ///
                                _col(56) %8.4f `zv' ///
                                _col(70) "`dec'"
                        }
                    }
                    di as txt "{hline 78}"
                }

                // -----------------------------------------------------------------
                // Graph (must run BEFORE return matrix which consumes it)
                // -----------------------------------------------------------------
                if "`graph'" != "" {
                    capture drop _zadf_plot _zadf_time
                    qui gen double _zadf_plot = .
                    qui gen double _zadf_time = .
                    forvalues w = 1/`nwindows' {
                        qui replace _zadf_plot = el(`zadf_mat', `w', 4) in `w'
                        local eobs = el(`zadf_mat', `w', 1)
                        if `eobs' != . {
                            qui replace _zadf_time = `timevar'[`eobs'] in `w'
                        }
                    }
                    
                    local gname "radf_`var'_`tr'_c`cas'"
                    
                    capture noisily {
                        twoway (area _zadf_plot _zadf_time if _zadf_plot >= 1, ///
                                   color("60 170 100%30") base(1)) ///
                               (area _zadf_plot _zadf_time if _zadf_plot < 1, ///
                                   color("220 50 47%20") base(0)) ///
                               (line _zadf_plot _zadf_time, ///
                                   lcolor("24 54 104") lwidth(medium)) ///
                               , yline(1, lcolor("220 50 47") lpattern(dash) lwidth(medthick)) ///
                               ytitle("z{sub:ADF}", size(medium)) ///
                               xtitle("Sample ending period", size(medium)) ///
                               ylabel(, labsize(small) grid glcolor(gs14%50)) ///
                               xlabel(, labsize(small) grid glcolor(gs14%50) angle(45)) ///
                               legend(off) ///
                               note("`var' (`trlbl', Case `cas'): `verdict'", ///
                                   size(vsmall) color(gs6)) ///
                               scheme(s2color) name(`gname', replace)
                        
                        qui graph export "`gname'.png", replace width(1400)
                    }
                }

                // Store result matrix (return matrix consumes the tempname)
                local matname "`var'_`tr'_c`cas'"
                local matname = subinstr("`matname'", ".", "_", .)
                mat colnames `zadf_mat' = end_obs t_stat cv z_adf
                return matrix zadf_`matname' = `zadf_mat'
            }
        }
    }

    // =========================================================================
    // 5. RETURN
    // =========================================================================
    return scalar nwindows = `nwindows'
    return scalar initobs = `initobs'
    return scalar T = `T'
    return local varlist "`varlist'"
    return local transform "`trans_list'"
    return local adfcase "`case_list'"

    restore
end
