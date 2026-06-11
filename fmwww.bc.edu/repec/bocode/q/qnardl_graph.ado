*! qnardl_graph v1.1.0  28may2026
*! Quantile-process plots for qnardl results.
*!
*! Plot types via option type():
*!   beta      Per-asymmetric-variable β⁺(τ) and β⁻(τ) panels
*!   ect       Speed-of-adjustment φ_y(τ) with shaded CI band
*!   asymmetry β⁺(τ) − β⁻(τ) for every variable on one panel
*!   all       Combined 2×2 layout (default)
*!
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>

program define qnardl_graph
    version 14.0

    syntax , [ TYpe(string) Level(cilevel) SAVing(string) ///
               TITLE(string) noCI XSize(real 10) YSize(real 7) SCheme(string) ]

    if "`e(cmd)'" != "qnardl" {
        di as error "qnardl_graph: estimation results from qnardl required"
        exit 301
    }

    if "`type'" == ""    local type "all"
    if "`level'" == ""   local level 95
    if "`scheme'" == ""  local scheme "s2color"
    local crit_z = invnormal(1 - (100-`level')/200)

    // Tabbed Graph window so multiple qnardl graphs coexist
    capture set autotabgraphs on

    if !inlist("`type'", "beta", "ect", "asymmetry", "all") {
        di as error "type() must be: beta | ect | asymmetry | all"
        exit 198
    }

    tempname bpos bneg phi
    matrix `bpos' = e(b_lr_pos)
    matrix `bneg' = e(b_lr_neg)
    matrix `phi'  = e(phi_y)
    local asymvars : colnames `bpos'
    local taus     : rownames `bpos'
    local kasym : word count `asymvars'
    local ntau  : word count `taus'

    if `ntau' < 3 {
        di as error "qnardl_graph: need at least 3 quantiles (got `ntau')"
        exit 198
    }

    preserve
    qui clear
    qui set obs `ntau'
    qui gen double tau = .
    forvalues t = 1/`ntau' {
        local tv : word `t' of `taus'
        qui replace tau = `tv' in `t'
    }

    // ===== BETA panels (one per variable) =====================================
    local beta_graphs ""
    if inlist("`type'", "beta", "all") {
        forvalues j = 1/`kasym' {
            qui gen double bp_`j' = .
            qui gen double bn_`j' = .
            forvalues t = 1/`ntau' {
                qui replace bp_`j' = `bpos'[`t', `j'] in `t'
                qui replace bn_`j' = `bneg'[`t', `j'] in `t'
            }
        }
        forvalues j = 1/`kasym' {
            local vn : word `j' of `asymvars'
            local gn "_qng_beta_`j'"
            qui twoway (line bp_`j' tau, lcolor(green) lwidth(medthick)) (line bn_`j' tau, lcolor(orange_red) lwidth(medthick) lpattern(dash)), yline(0, lcolor(gs10) lpattern(dot)) title(`"`vn'"', size(medsmall)) ytitle("", size(small)) xtitle("{&tau}", size(small)) ylabel(, labsize(small) angle(horizontal)) xlabel(, labsize(small)) legend(order(1 "{&beta}{sup:+}" 2 "{&beta}{sup:-}") rows(1) size(small) region(lwidth(none))) plotregion(margin(small)) graphregion(margin(small)) scheme(`scheme') name(`gn', replace) nodraw
            local beta_graphs `beta_graphs' `gn'
        }
        if "`type'" == "beta" {
            local bcols = cond(`kasym' <= 2, `kasym', cond(`kasym' <= 4, 2, 3))
            graph combine `beta_graphs', cols(`bcols') imargin(small) title("QNARDL long-run quantile process", size(medium)) subtitle("Solid green = {&beta}{sup:+}({&tau})    Dashed orange = {&beta}{sup:-}({&tau})", size(small)) xsize(`xsize') ysize(`ysize') name(qnardl_beta, replace)
            forvalues j = 1/`kasym' {
                capture graph drop _qng_beta_`j'
            }
            if "`saving'" != "" graph export "`saving'_beta.png", replace
        }
    }

    // ===== ECT panel ==========================================================
    if inlist("`type'", "ect", "all") {
        qui gen double ect_b  = .
        qui gen double ect_lo = .
        qui gen double ect_hi = .
        forvalues t = 1/`ntau' {
            local b  = `phi'[`t', 1]
            local s  = `phi'[`t', 2]
            qui replace ect_b  = `b' in `t'
            qui replace ect_lo = `b' - `crit_z'*`s' in `t'
            qui replace ect_hi = `b' + `crit_z'*`s' in `t'
        }
        local stxt = "Negative => convergence; `level'% CI shaded"
        if "`ci'" == "" {
            qui twoway (rarea ect_lo ect_hi tau, color(gs12) fintensity(60)) (line ect_b tau, lcolor(purple) lwidth(medthick)), yline(0, lcolor(gs10) lpattern(dot)) title("Speed of adjustment {&phi}{sub:y}({&tau})", size(medium)) subtitle(`"`stxt'"', size(small)) ytitle("{&phi}{sub:y}", size(small)) xtitle("{&tau}", size(small)) ylabel(, labsize(small) angle(horizontal)) xlabel(, labsize(small)) legend(order(2 "{&phi}{sub:y}({&tau})" 1 "`level'% CI") rows(1) size(small) region(lwidth(none))) plotregion(margin(medsmall)) graphregion(margin(small)) scheme(`scheme') name(qnardl_ect, replace) nodraw
        }
        else {
            qui twoway (line ect_b tau, lcolor(purple) lwidth(medthick)), yline(0, lcolor(gs10) lpattern(dot)) title("Speed of adjustment {&phi}{sub:y}({&tau})", size(medium)) ytitle("{&phi}{sub:y}", size(small)) xtitle("{&tau}", size(small)) ylabel(, labsize(small) angle(horizontal)) xlabel(, labsize(small)) legend(off) plotregion(margin(medsmall)) graphregion(margin(small)) scheme(`scheme') name(qnardl_ect, replace) nodraw
        }
        if "`type'" == "ect" {
            graph display qnardl_ect, xsize(`xsize') ysize(`ysize')
            if "`saving'" != "" graph export "`saving'_ect.png", replace
        }
    }

    // ===== ASYMMETRY panel ====================================================
    if inlist("`type'", "asymmetry", "all") {
        local asym_colors green orange_red purple cranberry magenta navy dkgreen
        forvalues j = 1/`kasym' {
            qui gen double asym_`j' = .
            forvalues t = 1/`ntau' {
                qui replace asym_`j' = `bpos'[`t', `j'] - `bneg'[`t', `j'] in `t'
            }
        }
        local asym_layers ""
        local asym_lgnd ""
        forvalues j = 1/`kasym' {
            local vn : word `j' of `asymvars'
            local cn : word `j' of `asym_colors'
            if "`cn'" == "" local cn "navy"
            local asym_layers `asym_layers' (line asym_`j' tau, lcolor(`cn') lwidth(medthick))
            local asym_lgnd  `asym_lgnd' `j' "`vn'"
        }
        qui twoway `asym_layers', yline(0, lcolor(gs10) lpattern(dot)) title("Asymmetry  {&beta}{sup:+}({&tau}) {&minus} {&beta}{sup:-}({&tau})", size(medium)) ytitle("{&beta}{sup:+} {&minus} {&beta}{sup:-}", size(small)) xtitle("{&tau}", size(small)) ylabel(, labsize(small) angle(horizontal)) xlabel(, labsize(small)) legend(order(`asym_lgnd') rows(1) size(small) region(lwidth(none))) plotregion(margin(medsmall)) graphregion(margin(small)) scheme(`scheme') name(qnardl_asym, replace) nodraw
        if "`type'" == "asymmetry" {
            graph display qnardl_asym, xsize(`xsize') ysize(`ysize')
            if "`saving'" != "" graph export "`saving'_asym.png", replace
        }
    }

    // ===== ALL — combined 2×2 (β-panel uses ALL its variables) =================
    if "`type'" == "all" {
        // Build the multi-panel β combine first (own row of beta_graphs)
        local bcols = cond(`kasym' <= 2, `kasym', cond(`kasym' <= 4, 2, 3))
        if `kasym' > 1 {
            graph combine `beta_graphs', cols(`bcols') name(qnardl_beta, replace) nodraw title("Long-run {&beta}{sup:+}({&tau}) vs {&beta}{sup:-}({&tau})", size(small)) imargin(small)
        }
        else {
            local solo : word 1 of `beta_graphs'
            cap graph drop qnardl_beta
            graph rename `solo' qnardl_beta
        }
        local main_title = cond("`title'"=="", "QNARDL — quantile process diagnostics", "`title'")
        graph combine qnardl_beta qnardl_ect qnardl_asym, cols(2) imargin(small) title(`"`main_title'"', size(medium)) subtitle("`level'% CI shaded for ECT", size(small)) xsize(`xsize') ysize(`ysize') name(qnardl_all, replace)
        // cleanup sub-graphs (β subpanels live inside qnardl_beta now)
        forvalues j = 1/`kasym' {
            capture graph drop _qng_beta_`j'
        }
        if "`saving'" != "" graph export "`saving'.png", replace
    }
    restore

    di as txt _n "qnardl_graph: " as res "`type'" as txt " plot(s) produced."
    di as txt "  Named graph(s) in memory: " as res cond("`type'"=="all", "qnardl_all (+ qnardl_beta, qnardl_ect, qnardl_asym)", cond("`type'"=="beta", "qnardl_beta", cond("`type'"=="ect", "qnardl_ect", "qnardl_asym")))
    di as txt "  Display any later with: {bf:graph display <name>}"
    if "`saving'" != "" di as txt "Saved to: " as res "`saving'_*.png"
end
