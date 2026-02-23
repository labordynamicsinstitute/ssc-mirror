*! fqardl_graph v2.0.1 — Premium Visualization Suite for FQARDL
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Generates 6 publication-quality graphs:
*!   1. Optimal k* Selection (SSR vs k)
*!   2. Long-Run β(τ) Quantile Process with CI bands
*!   3. Speed of Adjustment ρ(τ) across quantiles
*!   4. Short-Run Coefficient Process
*!   5. IRF Fan Chart by Quantile
*!   6. Persistence Profile (half-life + ρ)

capture program drop fqardl_graph
program define fqardl_graph
    version 14.0

    syntax , TAU(numlist >0 <1 sort) [P(integer 1) Q(integer 1) ///
        K(integer 1) DEPVAR(string) INDEPVARS(string) ///
        KSTAR(real 0) NOBS(integer 0) ///
        SAVing(string) SCHEME(string) ///
        SSRonly BETAonly RHOonly SRonly IRFonly PERSISTonly ///
        ECM NOQprocess]

    local ntau : word count `tau'
    if `ntau' < 2 {
        di as err "At least 2 quantiles are needed for visualization."
        exit 198
    }

    if "`scheme'" == "" local scheme "s2color"

    di
    di in smcl in gr "{hline 78}"
    di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
    di in smcl in gr "  {bf:║   FQARDL Premium Visualizations                         v2.0.0     ║}"
    di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
    di in smcl in gr "{hline 78}"

    * Determine which plots to create
    local do_all = 1
    if "`ssronly'`betaonly'`rhoonly'`sronly'`irfonly'`persistonly'" != "" {
        local do_all = 0
    }

    * ================================================================
    * Graph 1: k* Selection — SSR vs Fourier frequency
    * ================================================================
    capture matrix list e(ssr_matrix)
    if _rc == 0 & (`do_all' | "`ssronly'" != "") {
        capture noisily _fqg_plot_kstar, kstar(`kstar') scheme(`scheme')
    }

    * ================================================================
    * Graph 2: Long-Run β(τ) Quantile Process Plot with CI
    * ================================================================
    capture matrix list e(beta)
    if _rc == 0 & (`do_all' | "`betaonly'" != "") {
        capture noisily _fqg_plot_beta_process, tau(`tau') k(`k') ///
            indepvars("`indepvars'") depvar("`depvar'") scheme(`scheme')
    }

    * ================================================================
    * Graph 3: Speed of Adjustment ρ(τ) — ECT coefficient
    * ================================================================
    capture matrix list e(rho_vec)
    if _rc == 0 & (`do_all' | "`rhoonly'" != "") {
        capture noisily _fqg_plot_rho, tau(`tau') depvar("`depvar'") scheme(`scheme')
    }

    * ================================================================
    * Graph 4: Short-Run Coefficient Quantile Process
    * ================================================================
    capture matrix list e(gamma)
    if _rc == 0 & (`do_all' | "`sronly'" != "") {
        capture noisily _fqg_plot_sr_process, tau(`tau') k(`k') ///
            indepvars("`indepvars'") scheme(`scheme')
    }

    * ================================================================
    * Graph 5: Variable-Specific IRF — response of depvar to each x shock
    * ================================================================
    capture matrix list e(rho_vec)
    if _rc == 0 & (`do_all' | "`irfonly'" != "") {
        capture matrix list e(beta)
        if _rc == 0 {
            capture matrix list e(gamma)
            if _rc == 0 {
                capture noisily _fqg_plot_irf_vars, tau(`tau') k(`k') ///
                    indepvars("`indepvars'") depvar("`depvar'") scheme(`scheme')
            }
        }
    }

    * ================================================================
    * Graph 6: Persistence Profile (half-life + ρ)
    * ================================================================
    capture matrix list e(rho_vec)
    if _rc == 0 & (`do_all' | "`persistonly'" != "") {
        capture noisily _fqg_plot_persistence, tau(`tau') scheme(`scheme')
    }

    di in smcl in gr "{hline 78}"
    di in gr "  Graphs saved. Use " in ye "{bf:graph dir}" in gr " to list."
    di in gr "  Export: " in ye "{bf:graph export file.png, name(fqardl_*) replace}"
    di in smcl in gr "{hline 78}"
    di

    if "`saving'" != "" {
        capture graph export "`saving'", replace width(1600)
        if _rc == 0 {
            di as txt "  Graph exported to: `saving'"
        }
    }
end


* ================================================================
* GRAPH 1: Optimal k* — SSR vs Fourier frequency
* ================================================================
capture program drop _fqg_plot_kstar
program define _fqg_plot_kstar
    syntax , KSTAR(real) SCHEME(string)

    tempname ssr_mat
    mat `ssr_mat' = e(ssr_matrix)
    local nk = rowsof(`ssr_mat')

    if `nk' < 2 {
        di in gr "  ⊘ k* selection: only 1 frequency tested, skipping."
        exit
    }

    preserve
    clear
    qui set obs `nk'
    qui gen double kfreq = .
    qui gen double ssr = .
    qui gen byte is_opt = 0

    forvalues i = 1/`nk' {
        qui replace kfreq = `ssr_mat'[`i', 1] in `i'
        qui replace ssr = `ssr_mat'[`i', 2] in `i'
    }
    qui replace is_opt = 1 if abs(kfreq - `kstar') < 0.001

    capture {
        twoway (connected ssr kfreq, ///
                lcolor("24 54 104") mcolor("24 54 104") ///
                lwidth(medthick) msymbol(circle) msize(small)) ///
               (scatter ssr kfreq if is_opt, ///
                mcolor("220 50 47") msymbol(diamond) msize(vlarge)), ///
            title("{bf:Optimal Fourier Frequency Selection}", ///
                size(medlarge) color(black)) ///
            subtitle("k* selected by minimum SSR", size(small) color(gs5)) ///
            xtitle("Fourier frequency (k)", size(small)) ///
            ytitle("Sum of Squared Residuals", size(small)) ///
            xlabel(, labsize(small) grid glcolor(gs14%50)) ///
            ylabel(, labsize(small) angle(0) grid glcolor(gs14%50)) ///
            plotregion(fcolor(white) lcolor(gs14)) ///
            graphregion(fcolor(white) color(white) margin(small)) ///
            legend(order(1 "SSR(k)" 2 "Optimal k*={bf:`kstar'}") ///
                size(small) rows(1) position(6) ///
                region(lcolor(gs14))) ///
            scheme(`scheme') name(fqardl_kstar, replace)
    }
    if _rc == 0 {
        di in gr "  ✓ " in ye "fqardl_kstar" in gr " — Fourier frequency selection"
    }
    restore
end


* ================================================================
* GRAPH 2: Long-Run β(τ) Quantile Process with 95% CI
* ================================================================
capture program drop _fqg_plot_beta_process
program define _fqg_plot_beta_process
    syntax , TAU(numlist) K(integer) INDEPVARS(string) ///
        DEPVAR(string) SCHEME(string)

    local ntau : word count `tau'

    tempname beta_mat beta_cov_mat
    mat `beta_mat' = e(beta)
    mat `beta_cov_mat' = e(beta_cov)

    preserve
    clear
    qui set obs `= `ntau' * `k''

    qui gen double tau_val = .
    qui gen double beta_est = .
    qui gen double beta_lo = .
    qui gen double beta_hi = .
    qui gen int var_id = .

    local idx = 0
    local vnum = 0
    foreach v of local indepvars {
        local ++vnum
        forvalues t = 1/`ntau' {
            local ++idx
            local tauval : word `t' of `tau'

            * beta is stacked: vec(beta_matrix)
            * beta_matrix is k x ntau, vec stacks columns
            local bidx = (`t' - 1) * `k' + `vnum'

            qui replace tau_val = `tauval' in `idx'
            qui replace var_id = `vnum' in `idx'

            local brows = rowsof(`beta_mat')
            if `bidx' <= `brows' {
                qui replace beta_est = `beta_mat'[`bidx', 1] in `idx'

                local cov_rows = rowsof(`beta_cov_mat')
                if `bidx' <= `cov_rows' {
                    local se_val = sqrt(abs(`beta_cov_mat'[`bidx', `bidx']))
                    if `se_val' > 0 & `se_val' != . {
                        qui replace beta_lo = `beta_mat'[`bidx', 1] - 1.96 * `se_val' in `idx'
                        qui replace beta_hi = `beta_mat'[`bidx', 1] + 1.96 * `se_val' in `idx'
                    }
                }
            }
        }
    }

    * Colors for each variable
    local colors `" "0 128 128" "220 80 50" "100 60 200" "200 60 140" "50 100 220" "'

    local vnum = 0
    local graph_list ""
    foreach v of local indepvars {
        local ++vnum
        local col_idx = mod(`vnum' - 1, 5) + 1
        local this_color : word `col_idx' of `colors'
        local gname "fqardl_beta_`vnum'"

        capture {
            twoway (rarea beta_lo beta_hi tau_val if var_id == `vnum', ///
                    fcolor("`this_color'%20") lwidth(none)) ///
                   (connected beta_est tau_val if var_id == `vnum', ///
                    mcolor("`this_color'") lcolor("`this_color'") ///
                    msize(large) msymbol(circle) lwidth(medthick)), ///
                title("{bf:`v': Long-Run β(τ)}", size(medlarge) color(black)) ///
                subtitle("FQARDL quantile process with 95% CI band", ///
                    size(small) color(gs5)) ///
                xtitle("Quantile (τ)", size(small)) ///
                ytitle("β(τ)", size(small)) ///
                xlabel(, labsize(small) grid gstyle(dot)) ///
                ylabel(, labsize(small) grid gstyle(dot)) ///
                plotregion(fcolor(white) lcolor(gs14)) ///
                graphregion(fcolor(white) color(white) margin(small)) ///
                legend(order(2 "β(τ)" 1 "95% CI") ///
                    size(small) rows(1) position(6) ///
                    region(lcolor(gs14))) ///
                yline(0, lcolor(gs12) lpattern(dash) lwidth(thin)) ///
                scheme(`scheme') name(`gname', replace) nodraw
        }
        if _rc == 0 {
            local graph_list "`graph_list' `gname'"
            di in gr "  ✓ " in ye "`gname'" in gr " — β(`v') quantile process"
        }
    }

    * Combine if multiple variables
    if `k' > 1 & "`graph_list'" != "" {
        capture {
            graph combine `graph_list', ///
                title("{bf:FQARDL Long-Run Quantile Process}", ///
                    size(medlarge) color(black)) ///
                graphregion(fcolor(white) color(white)) ///
                name(fqardl_beta_combined, replace)
        }
        if _rc == 0 {
            di in gr "  ✓ " in ye "fqardl_beta_combined" in gr " — combined β(τ) process"
        }
    }
    else if "`graph_list'" != "" {
        graph display `: word 1 of `graph_list''
    }

    restore
end


* ================================================================
* GRAPH 3: Speed of Adjustment ρ(τ) with significance markers
* ================================================================
capture program drop _fqg_plot_rho
program define _fqg_plot_rho
    syntax , TAU(numlist) DEPVAR(string) SCHEME(string)

    local ntau : word count `tau'

    tempname rho_mat
    mat `rho_mat' = e(rho_vec)

    preserve
    clear
    qui set obs `ntau'

    qui gen double tau_val = .
    qui gen double rho_val = .
    qui gen double halflife = .

    forvalues t = 1/`ntau' {
        local tauval : word `t' of `tau'
        qui replace tau_val = `tauval' in `t'
        local rv = `rho_mat'[1, `t']
        qui replace rho_val = `rv' in `t'
        if `rv' < 0 {
            qui replace halflife = ln(2) / abs(`rv') in `t'
        }
    }

    capture {
        twoway (bar rho_val tau_val, ///
                barwidth(0.06) fcolor("24 54 104%70") lcolor("24 54 104") ///
                lwidth(medium)) ///
               (scatter rho_val tau_val, ///
                mcolor("220 50 47") msize(vlarge) msymbol(diamond)), ///
            title("{bf:Speed of Adjustment ρ(τ)}", ///
                size(medlarge) color(black)) ///
            subtitle("Error-correction coefficient across quantiles", ///
                size(small) color(gs5)) ///
            xtitle("Quantile (τ)", size(small)) ///
            ytitle("ρ(τ)", size(small)) ///
            xlabel(, labsize(small) grid gstyle(dot)) ///
            ylabel(, labsize(small) grid gstyle(dot)) ///
            plotregion(fcolor(white) lcolor(gs14)) ///
            graphregion(fcolor(white) color(white) margin(small)) ///
            yline(0, lcolor(gs12) lpattern(dash) lwidth(thin)) ///
            yline(-1, lcolor("220 50 47%40") lpattern(shortdash) lwidth(thin)) ///
            legend(order(1 "ρ(τ)" 2 "Point estimate") ///
                size(small) rows(1) position(6) ///
                region(lcolor(gs14))) ///
            note("ρ < 0 implies error-correction mechanism", ///
                size(vsmall) color(gs8)) ///
            scheme(`scheme') name(fqardl_rho, replace)
    }
    if _rc == 0 {
        di in gr "  ✓ " in ye "fqardl_rho" in gr " — speed of adjustment ρ(τ)"
    }
    restore
end


* ================================================================
* GRAPH 4: Short-Run γ(τ) Coefficient Process
* ================================================================
capture program drop _fqg_plot_sr_process
program define _fqg_plot_sr_process
    syntax , TAU(numlist) K(integer) INDEPVARS(string) SCHEME(string)

    local ntau : word count `tau'

    tempname gamma_mat gamma_cov_mat
    mat `gamma_mat' = e(gamma)
    mat `gamma_cov_mat' = e(gamma_cov)

    preserve
    clear
    qui set obs `= `ntau' * `k''

    qui gen double tau_val = .
    qui gen double gamma_est = .
    qui gen double gamma_lo = .
    qui gen double gamma_hi = .
    qui gen int var_id = .

    local idx = 0
    local vnum = 0
    foreach v of local indepvars {
        local ++vnum
        forvalues t = 1/`ntau' {
            local ++idx
            local tauval : word `t' of `tau'
            local gidx = (`t' - 1) * `k' + `vnum'

            qui replace tau_val = `tauval' in `idx'
            qui replace var_id = `vnum' in `idx'

            local grows = rowsof(`gamma_mat')
            if `gidx' <= `grows' {
                qui replace gamma_est = `gamma_mat'[`gidx', 1] in `idx'

                local cov_rows = rowsof(`gamma_cov_mat')
                if `gidx' <= `cov_rows' {
                    local se_val = sqrt(abs(`gamma_cov_mat'[`gidx', `gidx']))
                    if `se_val' > 0 & `se_val' != . {
                        qui replace gamma_lo = `gamma_mat'[`gidx', 1] - 1.96 * `se_val' in `idx'
                        qui replace gamma_hi = `gamma_mat'[`gidx', 1] + 1.96 * `se_val' in `idx'
                    }
                }
            }
        }
    }

    local colors `" "220 80 50" "0 128 128" "100 60 200" "200 60 140" "50 100 220" "'
    local symbols `" "circle" "diamond" "triangle" "square" "plus" "'

    local plots ""
    local legend_order ""
    local vnum = 0
    foreach v of local indepvars {
        local ++vnum
        local col_idx = mod(`vnum' - 1, 5) + 1
        local this_color : word `col_idx' of `colors'
        local this_sym : word `col_idx' of `symbols'

        * CI band
        local plots `"`plots' (rarea gamma_lo gamma_hi tau_val if var_id == `vnum', fcolor("`this_color'%15") lwidth(none))"'
        * Connected line
        local plots `"`plots' (connected gamma_est tau_val if var_id == `vnum', lcolor("`this_color'") mcolor("`this_color'") msymbol(`this_sym') msize(large) lwidth(medthick))"'

        local pnum = `vnum' * 2
        local legend_order `"`legend_order' `pnum' "`v'""'
    }

    capture {
        twoway `plots', ///
            title("{bf:Short-Run Impact γ(τ)}", ///
                size(medlarge) color(black)) ///
            subtitle("Contemporaneous effect across quantiles with 95% CI", ///
                size(small) color(gs5)) ///
            xtitle("Quantile (τ)", size(small)) ///
            ytitle("γ(τ)", size(small)) ///
            xlabel(, labsize(small) grid gstyle(dot)) ///
            ylabel(, labsize(small) grid gstyle(dot)) ///
            plotregion(fcolor(white) lcolor(gs14)) ///
            graphregion(fcolor(white) color(white) margin(small)) ///
            legend(order(`legend_order') size(small) rows(1) ///
                position(6) region(lcolor(gs14))) ///
            yline(0, lcolor(gs12) lpattern(dash) lwidth(thin)) ///
            scheme(`scheme') name(fqardl_sr_impact, replace)
    }
    if _rc == 0 {
        di in gr "  ✓ " in ye "fqardl_sr_impact" in gr " — short-run γ(τ) process"
    }
    restore
end


* ================================================================
* GRAPH 5: Variable-Specific IRF — Dynamic Multiplier per indepvar
* IRF_j(h,τ) = β_j(τ) + (γ_j(τ) - β_j(τ)) · (1+ρ(τ))^h
* Shows transition from short-run impact γ to long-run β
* ================================================================
capture program drop _fqg_plot_irf_vars
program define _fqg_plot_irf_vars
    syntax , TAU(numlist) K(integer) INDEPVARS(string) ///
        DEPVAR(string) SCHEME(string)

    local ntau : word count `tau'
    local periods = 20

    tempname rho_mat beta_mat gamma_mat
    mat `rho_mat' = e(rho_vec)
    mat `beta_mat' = e(beta)
    mat `gamma_mat' = e(gamma)

    local colors `" "0 128 128" "220 80 50" "100 60 200" "200 60 140" "50 100 220" "230 160 20" "80 140 220" "'

    local graph_list ""
    local vnum = 0
    foreach v of local indepvars {
        local ++vnum

        preserve
        clear
        qui set obs `= (`periods' + 1) * `ntau''

        qui gen int horizon = .
        qui gen double irf_val = .
        qui gen double tau_val = .
        qui gen int tau_id = .
        qui gen double lr_level = .

        local idx = 0
        local ti = 0
        foreach tauval of local tau {
            local ++ti

            * Get ρ(τ), β_j(τ), γ_j(τ)
            local rv = `rho_mat'[1, `ti']
            local bidx = (`ti' - 1) * `k' + `vnum'
            local bv = 0
            local gv = 0

            if `bidx' <= rowsof(`beta_mat') {
                local bv = `beta_mat'[`bidx', 1]
            }
            if `bidx' <= rowsof(`gamma_mat') {
                local gv = `gamma_mat'[`bidx', 1]
            }

            forvalues h = 0/`periods' {
                local ++idx
                qui replace horizon = `h' in `idx'
                qui replace tau_val = `tauval' in `idx'
                qui replace tau_id = `ti' in `idx'
                qui replace lr_level = `bv' in `idx'

                * Dynamic multiplier: β + (γ - β)·(1+ρ)^h
                if `rv' != . & `rv' < 0 {
                    local decay = (1 + `rv')^`h'
                    local irf = `bv' + (`gv' - `bv') * `decay'
                    qui replace irf_val = `irf' in `idx'
                }
            }
        }

        * Build plot layers per quantile
        local plots ""
        local legend_order ""
        local ti = 0
        foreach tauval of local tau {
            local ++ti
            local col_idx = mod(`ti' - 1, 7) + 1
            local this_color : word `col_idx' of `colors'

            local plots `"`plots' (connected irf_val horizon if tau_id == `ti', lcolor("`this_color'") mcolor("`this_color'") msymbol(circle) msize(vsmall) lwidth(medthick))"'
            local legend_order `"`legend_order' `ti' "τ=`tauval'""'
        }

        * Add LR reference line for median quantile (middle one)
        local mid_tau = int(`ntau' / 2) + 1
        local plots `"`plots' (line lr_level horizon if tau_id == `mid_tau', lcolor(gs10) lpattern(longdash) lwidth(medium))"'
        local lr_plot_num = `ntau' + 1
        local legend_order `"`legend_order' `lr_plot_num' "Long-run β""'

        local gname "fqardl_irf_`vnum'"
        capture {
            twoway `plots', ///
                title("{bf:IRF: `depvar' ← `v'}", ///
                    size(medlarge) color(black)) ///
                subtitle("Dynamic multiplier: γ(τ) → β(τ) across quantiles", ///
                    size(small) color(gs5)) ///
                xtitle("Horizon (periods)", size(small)) ///
                ytitle("Cumulative response of `depvar'", size(small)) ///
                xlabel(0(5)`periods', labsize(small) grid gstyle(dot)) ///
                ylabel(, labsize(small) grid gstyle(dot)) ///
                plotregion(fcolor(white) lcolor(gs14)) ///
                graphregion(fcolor(white) color(white) margin(small)) ///
                legend(order(`legend_order') size(vsmall) rows(1) ///
                    position(6) region(lcolor(gs14))) ///
                yline(0, lcolor(gs12) lpattern(dash) lwidth(thin)) ///
                note("h=0: short-run impact γ(τ);  h→∞: long-run β(τ)", ///
                    size(vsmall) color(gs8)) ///
                scheme(`scheme') name(`gname', replace)
        }
        if _rc == 0 {
            local graph_list "`graph_list' `gname'"
            di in gr "  ✓ " in ye "`gname'" in gr " — IRF: `depvar' ← `v'"
        }

        restore
    }

    * Combine if multiple variables
    if `k' > 1 & "`graph_list'" != "" {
        capture {
            graph combine `graph_list', ///
                title("{bf:FQARDL Impulse Responses by Variable}", ///
                    size(medlarge) color(black)) ///
                subtitle("Response of `depvar' to unit shock in each regressor", ///
                    size(small) color(gs5)) ///
                graphregion(fcolor(white) color(white)) ///
                name(fqardl_irf_combined, replace)
        }
        if _rc == 0 {
            di in gr "  ✓ " in ye "fqardl_irf_combined" in gr " — combined IRF panel"
        }
    }
end


* ================================================================
* GRAPH 6: Persistence Profile (ρ, half-life, and persistence)
* ================================================================
capture program drop _fqg_plot_persistence
program define _fqg_plot_persistence
    syntax , TAU(numlist) SCHEME(string)

    local ntau : word count `tau'

    tempname rho_mat
    mat `rho_mat' = e(rho_vec)

    preserve
    clear
    qui set obs `ntau'

    qui gen double tau_val = .
    qui gen double rho_val = .
    qui gen double persist = .
    qui gen double halflife = .

    forvalues t = 1/`ntau' {
        local tauval : word `t' of `tau'
        local rv = `rho_mat'[1, `t']
        qui replace tau_val = `tauval' in `t'
        qui replace rho_val = `rv' in `t'
        qui replace persist = 1 + `rv' in `t'
        if `rv' < 0 & `rv' != . {
            local hl = ln(2) / abs(`rv')
            if `hl' < 100 {
                qui replace halflife = `hl' in `t'
            }
        }
    }

    capture {
        twoway (bar rho_val tau_val, ///
                barwidth(0.04) fcolor("220 60 40%60") ///
                lcolor("220 60 40") lwidth(medium)) ///
               (connected persist tau_val, ///
                lcolor("0 128 128") mcolor("0 128 128") ///
                msize(vlarge) msymbol(diamond) lwidth(thick) ///
                lpattern(solid) yaxis(2)) ///
               (connected halflife tau_val, ///
                lcolor("100 60 200") mcolor("100 60 200") ///
                msize(large) msymbol(triangle) lwidth(medthick) ///
                lpattern(dash) yaxis(2)), ///
            title("{bf:Persistence Profile Across Quantiles}", ///
                size(medlarge) color(black)) ///
            subtitle("ρ(τ), persistence 1+ρ(τ), and half-life", ///
                size(small) color(gs5)) ///
            xtitle("Quantile (τ)", size(small)) ///
            ytitle("ρ(τ) — speed of adjustment", size(small) axis(1)) ///
            ytitle("Persistence | Half-life", size(small) axis(2)) ///
            xlabel(, labsize(small) grid gstyle(dot)) ///
            ylabel(, labsize(small) axis(1) grid gstyle(dot)) ///
            ylabel(, labsize(small) axis(2)) ///
            plotregion(fcolor(white) lcolor(gs14)) ///
            graphregion(fcolor(white) color(white) margin(small)) ///
            legend(order(1 "ρ(τ)" 2 "1+ρ(τ)" 3 "Half-life") ///
                size(small) rows(1) position(6) ///
                region(lcolor(gs14))) ///
            yline(0, lcolor(gs12) lpattern(dash) lwidth(thin) axis(1)) ///
            scheme(`scheme') name(fqardl_persistence, replace)
    }
    if _rc == 0 {
        di in gr "  ✓ " in ye "fqardl_persistence" in gr " — persistence profile"
    }
    restore
end
