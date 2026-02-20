*! rbfmvar_graph — Post-estimation graphs for RBFM-VAR
*! Version 2.0.0, February 2026
*! Author: Dr. Merwan Roudane
*! Email: merwanroudane920@gmail.com

capture program drop rbfmvar_graph
program define rbfmvar_graph
    version 14.0

    syntax , [                                    ///
        IRF                                       /// Impulse response functions
        EIG                                       /// Eigenvalue stability plot
        DENSity                                   /// Residual density vs normal
        FEVD                                      /// Forecast error variance decomp
        FORecast                                  /// Forecast fan chart
        COMBine                                   /// Combine all into one panel
        SAVing(string)                            /// Base filename for saving
        NODIsplay                                 /// Suppress display
        ]

    *--------------------------------------------------------------------------
    * Verify post-estimation
    *--------------------------------------------------------------------------
    if "`e(cmd)'" != "rbfmvar" {
        di as error "rbfmvar_graph requires rbfmvar estimation results"
        di as error "Run {bf:rbfmvar} first."
        exit 301
    }

    local n_vars = e(n_vars)
    local p_lags = e(p_lags)
    local varlist "`e(varlist)'"

    * Check what results are available
    local has_irf = 0
    local has_irf_ci = 0
    local has_fevd_data = 0
    local has_fcast = 0
    local has_resid = 0

    capture confirm matrix e(irf)
    if _rc == 0 local has_irf = 1

    capture confirm matrix e(irf_lo)
    if _rc == 0 local has_irf_ci = 1

    capture confirm matrix e(fevd)
    if _rc == 0 local has_fevd_data = 1

    capture confirm matrix e(forecast)
    if _rc == 0 local has_fcast = 1

    capture confirm matrix e(residuals)
    if _rc == 0 local has_resid = 1

    * Default: show what's requested
    local do_irf   = 0
    local do_eig   = 0
    local do_dens  = 0
    local do_fevd  = 0
    local do_fcast = 0

    if "`irf'"      != "" local do_irf   = 1
    if "`eig'"      != "" local do_eig   = 1
    if "`density'"  != "" local do_dens  = 1
    if "`fevd'"     != "" local do_fevd  = 1
    if "`forecast'" != "" local do_fcast = 1

    * If nothing specified, show all available
    if `do_irf' == 0 & `do_eig' == 0 & `do_dens' == 0 & `do_fevd' == 0 & `do_fcast' == 0 {
        local do_irf  = 1
        local do_eig  = 1
        local do_dens = 1
        if `has_fevd_data' local do_fevd = 1
        if `has_fcast'     local do_fcast = 1
    }

    local graph_list ""
    local graph_count = 0

    *==========================================================================
    * Premium Color Palette
    *==========================================================================
    * Rich, modern, publication-quality colors
    local c1 "24 116 205"     /* Royal Blue      */
    local c2 "220 50 47"      /* Crimson Red      */
    local c3 "0 158 115"      /* Emerald Green    */
    local c4 "230 159 0"      /* Amber Gold       */
    local c5 "106 61 154"     /* Deep Purple      */
    local c6 "0 114 178"      /* Steel Blue       */
    local c7 "204 121 167"    /* Rose Pink        */
    local c8 "86 180 233"     /* Sky Blue         */

    * CI band color (lighter version of c1)
    local ci_fill "24 116 205"
    local ci_opacity "%20"

    *==========================================================================
    * 1. IRF Plot — With Bootstrap Confidence Intervals
    *==========================================================================
    if `do_irf' & `has_irf' {
        tempname irf_mat irf_lo_mat irf_hi_mat
        mat `irf_mat' = e(irf)
        local horizon = e(irf_horizon)

        if `has_irf_ci' {
            mat `irf_lo_mat' = e(irf_lo)
            mat `irf_hi_mat' = e(irf_hi)
            local ci_level = e(irf_ci_level)
        }

        local n = `n_vars'
        local ncols = `horizon' + 1

        preserve
        qui {
            clear
            set obs `ncols'
            gen horizon = _n - 1

            local row_idx = 0
            forval i = 1/`n' {
                local vi : word `i' of `varlist'
                forval j = 1/`n' {
                    local vj : word `j' of `varlist'
                    local row_idx = `row_idx' + 1
                    gen double irf_`i'_`j' = .
                    if `has_irf_ci' {
                        gen double irf_lo_`i'_`j' = .
                        gen double irf_hi_`i'_`j' = .
                    }
                    forval h = 1/`ncols' {
                        replace irf_`i'_`j' = `irf_mat'[`row_idx', `h'] in `h'
                        if `has_irf_ci' {
                            replace irf_lo_`i'_`j' = `irf_lo_mat'[`row_idx', `h'] in `h'
                            replace irf_hi_`i'_`j' = `irf_hi_mat'[`row_idx', `h'] in `h'
                        }
                    }
                }
            }
        }

        * Create individual response-to-shock subplots
        forval j = 1/`n' {
            local vj : word `j' of `varlist'

            forval i = 1/`n' {
                local vi : word `i' of `varlist'
                local ci_index = `i'
                local ci_color : word `ci_index' of "`c1'" "`c2'" "`c3'" "`c4'" "`c5'"
                if "`ci_color'" == "" local ci_color "`c1'"

                local gname "rbfmvar_irf_`j'_`i'"

                if `has_irf_ci' {
                    twoway (rarea irf_lo_`i'_`j' irf_hi_`i'_`j' horizon, ///
                            fcolor("`ci_color'`ci_opacity'") lcolor("`ci_color'%0") ///
                            ) ///
                           (line irf_`i'_`j' horizon, ///
                            lcolor("`ci_color'") lwidth(medthick) ///
                            ) ///
                           (function y=0, range(0 `horizon') ///
                            lcolor(gs12) lpattern(dash) lwidth(thin) ///
                            ), ///
                        title("{bf:`vi'} {&larr} {bf:`vj'} Shock", ///
                            size(medsmall) color(black)) ///
                        xtitle("Horizon", size(small)) ///
                        ytitle("Response", size(small)) ///
                        xlabel(0(5)`horizon', labsize(vsmall) grid glcolor(gs14)) ///
                        ylabel(, labsize(vsmall) grid glcolor(gs14) angle(0)) ///
                        scheme(s2color) ///
                        plotregion(lcolor(gs13) margin(small)) ///
                        graphregion(fcolor(white) ifcolor(white) lcolor(white)) ///
                        legend(order(2 "Point estimate" 1 "`ci_level'% CI") ///
                            rows(1) size(vsmall) region(lcolor(white)) ///
                            position(6)) ///
                        name(`gname', replace) ///
                        `=cond("`nodisplay'"!="", "nodraw", "")'
                }
                else {
                    twoway (line irf_`i'_`j' horizon, ///
                            lcolor("`ci_color'") lwidth(medthick) ///
                            ) ///
                           (function y=0, range(0 `horizon') ///
                            lcolor(gs12) lpattern(dash) lwidth(thin) ///
                            ), ///
                        title("{bf:`vi'} {&larr} {bf:`vj'} Shock", ///
                            size(medsmall) color(black)) ///
                        xtitle("Horizon", size(small)) ///
                        ytitle("Response", size(small)) ///
                        xlabel(0(5)`horizon', labsize(vsmall) grid glcolor(gs14)) ///
                        ylabel(, labsize(vsmall) grid glcolor(gs14) angle(0)) ///
                        scheme(s2color) ///
                        plotregion(lcolor(gs13) margin(small)) ///
                        graphregion(fcolor(white) ifcolor(white) lcolor(white)) ///
                        legend(off) ///
                        name(`gname', replace) ///
                        `=cond("`nodisplay'"!="", "nodraw", "")'
                }

                local graph_list "`graph_list' `gname'"
                local graph_count = `graph_count' + 1
            }
        }

        * Combine all IRF subplots into one panel
        local n_subplots = `n' * `n'
        if `n_subplots' > 1 {
            graph combine `graph_list', ///
                title("{bf:Orthogonalized Impulse Response Functions}", ///
                    size(medium) color(black)) ///
                subtitle("RBFM-VAR(`p_lags') — `=cond(`has_irf_ci', "`ci_level'% Bootstrap CI", "Point Estimates")'", ///
                    size(small) color(gs6)) ///
                rows(`n') cols(`n') ///
                graphregion(fcolor(white) ifcolor(white) lcolor(white)) ///
                name(rbfmvar_irf_panel, replace) ///
                `=cond("`nodisplay'"!="", "nodraw", "")'

            if "`saving'" != "" {
                qui graph export "`saving'_irf.png", ///
                    name(rbfmvar_irf_panel) replace width(1800)
            }
        }
        else if "`saving'" != "" {
            qui graph export "`saving'_irf.png", ///
                name(`graph_list') replace width(1200)
        }

        restore

        * Reset graph list for combine
        local graph_list ""
        if `n_subplots' > 1 {
            local graph_list "rbfmvar_irf_panel"
        }
        local graph_count = 1
    }
    else if `do_irf' & !`has_irf' {
        di as txt "{col 5}Note: No IRF results. Re-run {bf:rbfmvar} with {bf:irf()} option."
    }

    *==========================================================================
    * 2. Eigenvalue Stability Plot — Premium Styling
    *==========================================================================
    if `do_eig' {
        tempname Pi1 Pi2
        mat `Pi1' = e(Pi1_plus)
        mat `Pi2' = e(Pi2_plus)
        local n = `n_vars'
        local p = `p_lags'

        capture noisily mata: _rbfmvar_eigenvalues("`Pi1'", "`Pi2'", `n', `p')

        if _rc {
            di as error "Eigenvalue computation failed."
        }
        else {
            tempname eig_re_mat eig_im_mat eig_mod_mat
            mat `eig_re_mat' = r(eig_re)
            mat `eig_im_mat' = r(eig_im)
            mat `eig_mod_mat' = r(eig_mod)
            local neig = colsof(`eig_re_mat')

            preserve
            qui {
                clear
                set obs `neig'
                gen double eig_re = .
                gen double eig_im = .
                gen double eig_mod = .
                gen byte inside = .
                forval i = 1/`neig' {
                    replace eig_re = `eig_re_mat'[1, `i'] in `i'
                    replace eig_im = `eig_im_mat'[1, `i'] in `i'
                    replace eig_mod = `eig_mod_mat'[1, `i'] in `i'
                    replace inside = (eig_mod < 1) in `i'
                }
            }

            local gname "rbfmvar_eigen"
            twoway (function y = sqrt(1-x^2), range(-1 1) ///
                    lcolor("`c4'%60") lpattern(solid) lwidth(medthick)) ///
                   (function y = -sqrt(1-x^2), range(-1 1) ///
                    lcolor("`c4'%60") lpattern(solid) lwidth(medthick)) ///
                   (scatter eig_im eig_re if inside == 1, ///
                    mcolor("`c3'") msize(large) msymbol(circle) ///
                    mlcolor("`c3'%80") mlwidth(thin)) ///
                   (scatter eig_im eig_re if inside == 0, ///
                    mcolor("`c2'") msize(large) msymbol(diamond) ///
                    mlcolor("`c2'%80") mlwidth(thin)), ///
                title("{bf:Eigenvalue Stability}", ///
                    size(medium) color(black)) ///
                subtitle("Companion matrix — RBFM-VAR(`p_lags')", ///
                    size(small) color(gs6)) ///
                xtitle("Real", size(small)) ///
                ytitle("Imaginary", size(small)) ///
                xlabel(-1.5(0.5)1.5, labsize(vsmall) grid glcolor(gs14)) ///
                ylabel(-1.5(0.5)1.5, labsize(vsmall) grid glcolor(gs14) angle(0)) ///
                xline(0, lcolor(gs14) lpattern(solid)) ///
                yline(0, lcolor(gs14) lpattern(solid)) ///
                aspect(1) scheme(s2color) ///
                plotregion(lcolor(gs13) margin(small)) ///
                graphregion(fcolor(white) ifcolor(white) lcolor(white)) ///
                legend(order(3 "Inside unit circle" 4 "Outside/on boundary") ///
                    rows(1) size(vsmall) region(lcolor(white)) position(6)) ///
                note("All eigenvalues inside unit circle {&rArr} stable system", ///
                    size(vsmall) color(gs8)) ///
                name(`gname', replace) ///
                `=cond("`nodisplay'"!="", "nodraw", "")'

            local graph_list "`graph_list' `gname'"
            local graph_count = `graph_count' + 1

            if "`saving'" != "" {
                qui graph export "`saving'_eigen.png", ///
                    name(`gname') replace width(1200)
            }

            restore
        }
    }

    *==========================================================================
    * 3. Residual Density Plot — Working Implementation
    *==========================================================================
    if `do_dens' & `has_resid' {
        tempname resid_m
        mat `resid_m' = e(residuals)
        local n = `n_vars'
        local T_eff = rowsof(`resid_m')

        preserve
        qui {
            clear
            set obs `T_eff'
            forval i = 1/`n' {
                local vi : word `i' of `varlist'
                gen double resid_`i' = .
                forval t = 1/`T_eff' {
                    replace resid_`i' = `resid_m'[`t', `i'] in `t'
                }
                * Standardize residuals
                sum resid_`i', detail
                replace resid_`i' = (resid_`i' - r(mean)) / r(sd)
            }
        }

        * Create density plot for each variable
        forval i = 1/`n' {
            local vi : word `i' of `varlist'
            local ci_color : word `i' of "`c1'" "`c2'" "`c3'" "`c4'" "`c5'"
            if "`ci_color'" == "" local ci_color "`c1'"

            local gname "rbfmvar_dens_`i'"

            twoway (kdensity resid_`i', ///
                    lcolor("`ci_color'") lwidth(medthick) ///
                    bwidth(0.4) ///
                    recast(area) fcolor("`ci_color'%15") ///
                    ) ///
                   (function normalden(x), range(-4 4) ///
                    lcolor(gs8) lpattern(dash) lwidth(medium) ///
                    ), ///
                title("{bf:Residual Density: `vi'}", ///
                    size(medsmall) color(black)) ///
                subtitle("Standardized residuals vs. Normal", ///
                    size(small) color(gs6)) ///
                xtitle("Std. Residual", size(small)) ///
                ytitle("Density", size(small)) ///
                xlabel(-4(1)4, labsize(vsmall) grid glcolor(gs14)) ///
                ylabel(, labsize(vsmall) grid glcolor(gs14) angle(0)) ///
                scheme(s2color) ///
                plotregion(lcolor(gs13) margin(small)) ///
                graphregion(fcolor(white) ifcolor(white) lcolor(white)) ///
                legend(order(1 "Kernel density" 2 "N(0,1)") ///
                    rows(1) size(vsmall) region(lcolor(white)) position(6)) ///
                name(`gname', replace) ///
                `=cond("`nodisplay'"!="", "nodraw", "")'

            local graph_list "`graph_list' `gname'"
            local graph_count = `graph_count' + 1
        }

        if "`saving'" != "" {
            forval i = 1/`n' {
                local gname "rbfmvar_dens_`i'"
                qui graph export "`saving'_density_`i'.png", ///
                    name(`gname') replace width(1200)
            }
        }

        restore
    }
    else if `do_dens' & !`has_resid' {
        di as txt "{col 5}Note: No residuals stored. Density plot unavailable."
    }

    *==========================================================================
    * 4. FEVD Plot — Stacked Area Chart
    *==========================================================================
    if `do_fevd' & `has_fevd_data' {
        tempname fevd_m
        mat `fevd_m' = e(fevd)
        local n = `n_vars'
        local horizon = e(irf_horizon)
        local ncols = `horizon' + 1

        preserve
        qui {
            clear
            set obs `ncols'
            gen horizon = _n - 1

            * Extract FEVD for each response variable
            forval i = 1/`n' {
                forval j = 1/`n' {
                    local row_idx = (`i' - 1) * `n' + `j'
                    gen double fevd_`i'_`j' = .
                    forval h = 1/`ncols' {
                        replace fevd_`i'_`j' = `fevd_m'[`row_idx', `h'] * 100 in `h'
                    }
                }
            }
        }

        * Create FEVD stacked area chart for each variable
        forval i = 1/`n' {
            local vi : word `i' of `varlist'
            local gname "rbfmvar_fevd_`i'"

            * Create cumulative variables for stacking
            qui {
                gen double cum_`i'_0 = 0
                forval j = 1/`n' {
                    gen double cum_`i'_`j' = cum_`i'_`=`j'-1' + fevd_`i'_`j'
                }
            }

            * Use named Stata colors (no quotes needed in dynamic local)
            local nc1 navy
            local nc2 maroon
            local nc3 forest_green
            local nc4 dkorange
            local nc5 purple
            local nc6 teal
            local nc7 cranberry
            local nc8 dknavy

            * Build legend labels and order
            local leg_order ""
            local leg_labels ""
            forval jj = 1/`n' {
                local j = `n' + 1 - `jj'
                local vj : word `j' of `varlist'
                local leg_order "`leg_order' `jj'"
                local leg_labels `"`leg_labels' label(`jj' "`vj'")"'
            }

            * Build area plot command using named colors (no quote nesting needed)
            local plot_cmd ""
            forval jj = 1/`n' {
                local j = `n' + 1 - `jj'
                local thiscol "`nc`j''"
                local plot_cmd "`plot_cmd' (area cum_`i'_`j' horizon, fcolor(`thiscol'%60) lcolor(`thiscol') lwidth(vthin))"
            }

            twoway `plot_cmd', ///
                title("{bf:FEVD: `vi'}", size(medsmall) color(black)) ///
                subtitle("Forecast Error Variance Decomposition", ///
                    size(small) color(gs6)) ///
                xtitle("Horizon", size(small)) ///
                ytitle("Percent (%)", size(small)) ///
                xlabel(0(5)`horizon', labsize(vsmall) grid glcolor(gs14)) ///
                ylabel(0(20)100, labsize(vsmall) grid glcolor(gs14) angle(0)) ///
                scheme(s2color) ///
                plotregion(lcolor(gs13) margin(small)) ///
                graphregion(fcolor(white) ifcolor(white) lcolor(white)) ///
                legend(order(`leg_order') `leg_labels' ///
                    rows(1) size(vsmall) region(lcolor(white)) position(6)) ///
                name(`gname', replace) ///
                `=cond("`nodisplay'"!="", "nodraw", "")'

            local graph_list "`graph_list' `gname'"
            local graph_count = `graph_count' + 1
        }

        if "`saving'" != "" {
            forval i = 1/`n' {
                local gname "rbfmvar_fevd_`i'"
                qui graph export "`saving'_fevd_`i'.png", ///
                    name(`gname') replace width(1200)
            }
        }

        restore
    }
    else if `do_fevd' & !`has_fevd_data' {
        di as txt "{col 5}Note: No FEVD results. Re-run {bf:rbfmvar} with {bf:fevd irf()} options."
    }

    *==========================================================================
    * 5. Forecast Fan Chart
    *==========================================================================
    if `do_fcast' & `has_fcast' {
        tempname fc_mat fc_se_mat
        mat `fc_mat' = e(forecast)
        mat `fc_se_mat' = e(forecast_se)
        local n = `n_vars'
        local steps = e(forecast_steps)

        preserve
        qui {
            clear
            set obs `steps'
            gen step = _n

            forval i = 1/`n' {
                gen double fc_`i' = .
                gen double fc_lo95_`i' = .
                gen double fc_hi95_`i' = .
                gen double fc_lo80_`i' = .
                gen double fc_hi80_`i' = .
                gen double fc_lo50_`i' = .
                gen double fc_hi50_`i' = .

                forval s = 1/`steps' {
                    local fc_val = `fc_mat'[`i', `s']
                    local fc_se  = `fc_se_mat'[`i', `s']
                    replace fc_`i' = `fc_val' in `s'
                    replace fc_lo95_`i' = `fc_val' - 1.96 * `fc_se' in `s'
                    replace fc_hi95_`i' = `fc_val' + 1.96 * `fc_se' in `s'
                    replace fc_lo80_`i' = `fc_val' - 1.28 * `fc_se' in `s'
                    replace fc_hi80_`i' = `fc_val' + 1.28 * `fc_se' in `s'
                    replace fc_lo50_`i' = `fc_val' - 0.67 * `fc_se' in `s'
                    replace fc_hi50_`i' = `fc_val' + 0.67 * `fc_se' in `s'
                }
            }
        }

        forval i = 1/`n' {
            local vi : word `i' of `varlist'
            local ci_color : word `i' of "`c1'" "`c2'" "`c3'" "`c4'" "`c5'"
            if "`ci_color'" == "" local ci_color "`c1'"

            local gname "rbfmvar_fcast_`i'"

            twoway (rarea fc_lo95_`i' fc_hi95_`i' step, ///
                    fcolor("`ci_color'%10") lcolor("`ci_color'%0")) ///
                   (rarea fc_lo80_`i' fc_hi80_`i' step, ///
                    fcolor("`ci_color'%20") lcolor("`ci_color'%0")) ///
                   (rarea fc_lo50_`i' fc_hi50_`i' step, ///
                    fcolor("`ci_color'%35") lcolor("`ci_color'%0")) ///
                   (line fc_`i' step, ///
                    lcolor("`ci_color'") lwidth(medthick)), ///
                title("{bf:Forecast: `vi'}", ///
                    size(medsmall) color(black)) ///
                subtitle("Multi-step ahead from RBFM-VAR(`p_lags')", ///
                    size(small) color(gs6)) ///
                xtitle("Steps Ahead", size(small)) ///
                ytitle("Value", size(small)) ///
                xlabel(1(2)`steps', labsize(vsmall) grid glcolor(gs14)) ///
                ylabel(, labsize(vsmall) grid glcolor(gs14) angle(0)) ///
                scheme(s2color) ///
                plotregion(lcolor(gs13) margin(small)) ///
                graphregion(fcolor(white) ifcolor(white) lcolor(white)) ///
                legend(order(4 "Point forecast" 3 "50% CI" 2 "80% CI" 1 "95% CI") ///
                    rows(1) size(vsmall) region(lcolor(white)) position(6)) ///
                name(`gname', replace) ///
                `=cond("`nodisplay'"!="", "nodraw", "")'

            local graph_list "`graph_list' `gname'"
            local graph_count = `graph_count' + 1
        }

        if "`saving'" != "" {
            forval i = 1/`n' {
                local gname "rbfmvar_fcast_`i'"
                qui graph export "`saving'_forecast_`i'.png", ///
                    name(`gname') replace width(1200)
            }
        }

        restore
    }
    else if `do_fcast' & !`has_fcast' {
        di as txt "{col 5}Note: No forecast results. Re-run {bf:rbfmvar} with {bf:forecast()} option."
    }

    *==========================================================================
    * 6. Combine all graphs
    *==========================================================================
    if "`combine'" != "" & `graph_count' > 1 {
        graph combine `graph_list', ///
            title("{bf:RBFM-VAR Diagnostics}", size(medium) color(black)) ///
            subtitle("Chang (2000) Residual-Based Fully Modified VAR", ///
                size(small) color(gs6)) ///
            scheme(s2color) ///
            graphregion(fcolor(white) ifcolor(white) lcolor(white)) ///
            name(rbfmvar_combined, replace) ///
            `=cond("`nodisplay'"!="", "nodraw", "")'

        if "`saving'" != "" {
            qui graph export "`saving'_combined.png", ///
                name(rbfmvar_combined) replace width(2000)
        }
    }
end


// ========================================================================
// Mata function for eigenvalue computation (unchanged logic, kept here)
// ========================================================================
capture mata: mata drop _rbfmvar_eigenvalues()

mata:
void _rbfmvar_eigenvalues(
    string scalar pi1_name,
    string scalar pi2_name,
    real scalar n_v,
    real scalar p_v)
{
    real matrix Pi1_m, Pi2_m, Gamma_est
    real matrix A_levs, A_companion
    real scalar p_levels, comp_dim, k
    real matrix Gamma_k

    Pi1_m = st_matrix(pi1_name)
    Pi2_m = st_matrix(pi2_name)

    // Reconstruct levels VAR: A₁ = Π₁+Π₂, A₂ = -Π₁, plus Γ contributions
    p_levels = p_v
    A_levs = J(n_v, n_v * p_levels, 0)

    // Π₂·y_{t-1}
    A_levs[., 1::n_v] = A_levs[., 1::n_v] + Pi2_m

    // Π₁·Δy_{t-1} = Π₁·y_{t-1} - Π₁·y_{t-2}
    A_levs[., 1::n_v] = A_levs[., 1::n_v] + Pi1_m
    if (p_levels >= 2) {
        A_levs[., (n_v+1)::(2*n_v)] = A_levs[., (n_v+1)::(2*n_v)] - Pi1_m
    }

    // Γ_j·Δ²y_{t-j} for j=1,...,p-2 (if p≥3)
    if (p_v >= 3) {
        Gamma_est = st_matrix("e(Gamma_plus)")
        for (k = 1; k <= p_v - 2; k++) {
            Gamma_k = Gamma_est[., (n_v*(k-1)+1)::(n_v*k)]
            A_levs[., (n_v*(k-1)+1)::(n_v*k)] = A_levs[., (n_v*(k-1)+1)::(n_v*k)] + Gamma_k
            if (k + 1 <= p_levels) {
                A_levs[., (n_v*k+1)::(n_v*(k+1))] = A_levs[., (n_v*k+1)::(n_v*(k+1))] - 2 * Gamma_k
            }
            if (k + 2 <= p_levels) {
                A_levs[., (n_v*(k+1)+1)::(n_v*(k+2))] = A_levs[., (n_v*(k+1)+1)::(n_v*(k+2))] + Gamma_k
            }
        }
    }

    // Build companion matrix
    comp_dim = p_levels * n_v
    A_companion = J(comp_dim, comp_dim, 0)
    A_companion[1::n_v, .] = A_levs
    if (p_levels >= 2) {
        A_companion[(n_v+1)::comp_dim, 1::((p_levels-1)*n_v)] = I((p_levels-1)*n_v)
    }

    // Eigenvalues
    eig = eigenvalues(A_companion)
    re_part = Re(eig)
    im_part = Im(eig)
    modulus = sqrt(re_part:^2 + im_part:^2)

    // Return as Stata matrices (1 x neig row vectors)
    st_matrix("r(eig_re)", re_part)
    st_matrix("r(eig_im)", im_part)
    st_matrix("r(eig_mod)", modulus)
}
end
