*! _quasicoint_plot.ado — Publication-quality plots for quasicoint
*! Version 1.0.0 — 2026-05-09
*! Author: Dr. Merwan Roudane

capture program drop _quasicoint_plot
program define _quasicoint_plot
    version 14
    syntax , graph(string) saving(string) p(integer) q(integer) ///
            k(integer) rho(real) vars(string) level(real)

    local r = `p' - `q'
    local z_crit = invnormal(1 - (1-`level'/100)/2)

    // Premium colour palette
    local col1 "0 119 182"      // deep blue
    local col2 "217 72 1"       // burnt orange
    local col3 "44 160 44"      // forest green
    local col4 "148 103 189"    // purple
    local col5 "140 86 75"      // brown

    // =====================================================================
    //  PLOT 1: PROFILE LIKELIHOOD + CONDITIONAL CIs
    // =====================================================================
    if inlist("`graph'", "all", "profile") {
        di as text "  Generating profile likelihood plot..."

        preserve
        tempname pll cci
        capture matrix `pll' = _qc_profile_ll
        capture matrix `cci' = _qc_cond_ci

        if _rc == 0 {
            local ngrid = rowsof(`pll')
            qui drop _all
            qui set obs `ngrid'

            qui gen lambda = .
            qui gen loglik = .
            qui gen beta_hat = .
            qui gen ci_lo = .
            qui gen ci_hi = .

            forvalues i = 1/`ngrid' {
                qui replace lambda   = `pll'[`i', 1]  in `i'
                qui replace loglik   = `pll'[`i', 2]  in `i'
                qui replace beta_hat = `cci'[`i', 2]  in `i'
                local se_i = `cci'[`i', 3]
                qui replace ci_lo = `cci'[`i', 2] - `z_crit' * `se_i' in `i'
                qui replace ci_hi = `cci'[`i', 2] + `z_crit' * `se_i' in `i'
            }

            // Panel A: Profile log-likelihood
            twoway (line loglik lambda, lcolor("`col1'") lwidth(medthick) lpattern(solid)) ///
                , title("{bf:Profile Log-Likelihood}", size(medium)) ///
                  subtitle("Concentrated over dominant root λ", size(small)) ///
                  xtitle("Dominant root (λ)", size(small)) ///
                  ytitle("Log-likelihood", size(small)) ///
                  xline(1, lcolor(gs8) lpattern(dash)) ///
                  xlabel(, format(%5.3f) labsize(small)) ///
                  ylabel(, labsize(small) format(%10.1f)) ///
                  plotregion(margin(small)) ///
                  graphregion(color(white) margin(small)) ///
                  scheme(s2color) ///
                  note("rho = `rho'; VAR(`k'); p = `p', q = `q'", size(vsmall)) ///
                  name(_qc_profile_ll, replace)

            qui graph export "`saving'_profile_ll.png", ///
                as(png) width(1400) height(600) replace

            // Panel B: Conditional beta + CI
            twoway (rarea ci_lo ci_hi lambda, ///
                        fcolor("`col3'%20") lcolor("`col3'%40") lwidth(none)) ///
                   (line beta_hat lambda, ///
                        lcolor("`col1'") lwidth(medthick) lpattern(solid)) ///
                , title("{bf:Conditional β̂ and `level'% CI}", size(medium)) ///
                  subtitle("as a function of imposed dominant root λ", size(small)) ///
                  xtitle("Dominant root (λ)", size(small)) ///
                  ytitle("β̂", size(small)) ///
                  xline(1, lcolor(gs8) lpattern(dash)) ///
                  xlabel(, format(%5.3f) labsize(small)) ///
                  ylabel(, labsize(small)) ///
                  legend(order(2 "β̂|λ" 1 "`level'% CI") ///
                         ring(0) pos(11) cols(1) size(small)) ///
                  plotregion(margin(small)) ///
                  graphregion(color(white) margin(small)) ///
                  scheme(s2color) ///
                  name(_qc_cond_ci, replace)

            qui graph export "`saving'_cond_ci.png", ///
                as(png) width(1400) height(600) replace

            // Combined graph
            graph combine _qc_profile_ll _qc_cond_ci, ///
                rows(2) ///
                title("{bf:Quasi-Cointegration: Profile Analysis}", size(medium)) ///
                subtitle("Duffy & Simons (2023) — VAR(`k'), p=`p', q=`q'", size(small)) ///
                graphregion(color(white)) ///
                note("Lower bound ρ = `rho' (half-life ≥ " ///
                     %4.1f -log(2)/log(`rho') " periods)", size(vsmall)) ///
                name(_qc_profile_combined, replace)

            qui graph export "`saving'_profile.png", ///
                as(png) width(1400) height(1000) replace

            di as text "  Saved: `saving'_profile.png"
        }
        restore
    }

    // =====================================================================
    //  PLOT 2: IMPULSE RESPONSE FUNCTIONS
    // =====================================================================
    if inlist("`graph'", "all", "irf") {
        di as text "  Generating IRF comparison plot..."

        preserve
        tempname irf_mat
        capture matrix `irf_mat' = _qc_irf

        if _rc == 0 {
            local horizons = rowsof(`irf_mat') / `p'
            qui drop _all
            qui set obs `horizons'

            qui gen horizon = _n

            // Extract IRF for first shock -> each variable
            local vnames `vars'
            forvalues j = 1/`p' {
                local vn : word `j' of `vnames'
                qui gen irf_`vn' = .
                forvalues h = 1/`horizons' {
                    qui replace irf_`vn' = `irf_mat'[(`h'-1)*`p'+`j', 1] in `h'
                }
            }

            // Build twoway command dynamically
            local tw_cmd ""
            local lgnd_cmd ""
            forvalues j = 1/`p' {
                local vn : word `j' of `vnames'
                local jcol "col`j'"
                local tw_cmd `"`tw_cmd' (line irf_`vn' horizon, lcolor("``jcol''") lwidth(medthick))"'
                local lgnd_cmd `"`lgnd_cmd' `j' "`vn'""'
            }

            twoway `tw_cmd' ///
                , title("{bf:Impulse Responses to Shock 1}", size(medium)) ///
                  subtitle("VAR(`k') reduced-form IRF", size(small)) ///
                  xtitle("Horizon", size(small)) ///
                  ytitle("Response", size(small)) ///
                  yline(0, lcolor(gs10) lpattern(dash)) ///
                  xlabel(, labsize(small)) ///
                  ylabel(, labsize(small)) ///
                  legend(order(`lgnd_cmd') ring(0) pos(1) cols(1) size(small)) ///
                  plotregion(margin(small)) ///
                  graphregion(color(white) margin(small)) ///
                  scheme(s2color) ///
                  name(_qc_irf, replace)

            qui graph export "`saving'_irf.png", ///
                as(png) width(1400) height(600) replace
            di as text "  Saved: `saving'_irf.png"
        }
        restore
    }

    // =====================================================================
    //  PLOT 3: CHARACTERISTIC ROOT MAP
    // =====================================================================
    if inlist("`graph'", "all", "roots") {
        di as text "  Generating root map..."

        preserve
        tempname evals
        capture matrix `evals' = _qc_eigenvalues

        if _rc == 0 {
            local nroots = rowsof(`evals')
            local show = min(`nroots', 2*`p')
            qui drop _all
            qui set obs `show'

            qui gen re_part = .
            qui gen im_part = .
            qui gen region = .

            forvalues i = 1/`show' {
                qui replace re_part = `evals'[`i', 1] in `i'
                qui replace im_part = `evals'[`i', 2] in `i'
                qui replace region  = (`i' <= `q')     in `i'
            }

            // Unit circle
            qui set obs `=`show'+101'
            qui gen theta = (_n - `show') * 2 * _pi / 100 if _n > `show'
            qui gen uc_x = cos(theta) if _n > `show'
            qui gen uc_y = sin(theta) if _n > `show'

            twoway (line uc_y uc_x if _n > `show', lcolor(gs12) lwidth(thin) lpattern(solid)) ///
                   (scatter im_part re_part if region == 1, ///
                        mcolor("`col2'") msize(large) msymbol(diamond)) ///
                   (scatter im_part re_part if region == 0, ///
                        mcolor("`col1'") msize(medium) msymbol(circle)) ///
                , title("{bf:Characteristic Root Map}", size(medium)) ///
                  subtitle("VAR(`k') companion matrix eigenvalues", size(small)) ///
                  xtitle("Real part", size(small)) ///
                  ytitle("Imaginary part", size(small)) ///
                  xline(0, lcolor(gs14)) yline(0, lcolor(gs14)) ///
                  xlabel(-1(.5)1, labsize(small)) ///
                  ylabel(-1(.5)1, labsize(small)) ///
                  aspectratio(1) ///
                  legend(order(2 "Near-unit (L_LU)" 3 "Stationary (L_ST)") ///
                         ring(0) pos(5) cols(1) size(small)) ///
                  plotregion(margin(small)) ///
                  graphregion(color(white) margin(small)) ///
                  scheme(s2color) ///
                  note("Unit circle shown in grey; ρ = `rho'", size(vsmall)) ///
                  name(_qc_roots, replace)

            qui graph export "`saving'_roots.png", ///
                as(png) width(800) height(800) replace
            di as text "  Saved: `saving'_roots.png"
        }
        restore
    }

    di ""
end
