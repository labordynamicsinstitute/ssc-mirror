*! cs_fragility.ado  v1.0.3  2026-03-18  Stata 14.1 compatible ASCII only
program define cs_fragility, rclass
    version 14.0

    syntax [, Type(string) SAVEFragility(string) SAVing(string) NOPlot ]

    if "`type'" == "" local type "curvature_ratio"
    if !inlist("`type'", "curvature_ratio", "inverse_slope") {
        di as error "type() must be: curvature_ratio  inverse_slope"
        exit 198
    }
    if "$CSCMD" != "causalspline" {
        di as error "cs_fragility requires causalspline to be run first"
        exit 301
    }

    local ng = $CSNGRID

    // Get derivatives
    qui cs_gradient
    tempname ct ce cse d1 d2
    mat `ct'  = r(grad_t)
    mat `ce'  = r(grad_mu)
    mat `cse' = r(grad_se)
    mat `d1'  = r(grad_d1)
    mat `d2'  = r(grad_d2)

    // Adaptive epsilon from median |d1|
    local sumad = 0
    local nvalid = 0
    forval j = 1/`ng' {
        local d1v = `d1'[`j',1]
        if `d1v' != . {
            local nvalid = `nvalid' + 1
            local sumad  = `sumad' + abs(`d1v')
        }
    }
    local eps = 0.1
    if `nvalid' > 0 {
        local eps = (`sumad' / `nvalid') * 0.05
        if `eps' < 1e-8 local eps = 1e-8
    }

    // Compute fragility values
    tempname frag frag_norm zone_num hiflag
    mat `frag'      = J(`ng', 1, .)
    mat `frag_norm' = J(`ng', 1, .)
    mat `zone_num'  = J(`ng', 1, 1)
    mat `hiflag'    = J(`ng', 1, 0)

    forval j = 1/`ng' {
        local d1v = `d1'[`j',1]
        local d2v = `d2'[`j',1]
        local sev = `cse'[`j',1]
        if `d1v' != . & `d2v' != . {
            local ad1 = abs(`d1v')
            local ad2 = abs(`d2v')
            local den = `ad1' + `eps'
            if "`type'" == "curvature_ratio" {
                mat `frag'[`j',1] = `ad2' / `den'
            }
            else {
                mat `frag'[`j',1] = 1 / `den'
            }
            if `sev' != . & `sev' > 0 {
                mat `frag_norm'[`j',1] = `frag'[`j',1] / `sev'
            }
        }
    }

    // Collect non-missing fragility values and SORT to get quantiles
    // Store in dataset temporarily for proper sorting
    preserve
        qui drop _all
        qui set obs `ng'
        qui gen double fv = .
        forval j = 1/`ng' {
            local fval = `frag'[`j',1]
            if `fval' != . {
                qui replace fv = `fval' in `j'
            }
        }
        qui drop if fv == .
        qui sort fv
        local nf = _N
        local q50 = 0
        local q75 = 0
        if `nf' > 0 {
            local i50 = max(1, round(`nf' * 0.50))
            local i75 = max(1, round(`nf' * 0.75))
            qui sum fv in `i50'
            local q50 = r(mean)
            qui sum fv in `i75'
            local q75 = r(mean)
        }
    restore

    // Assign zones using correct quantiles
    forval j = 1/`ng' {
        local fv = `frag'[`j',1]
        if `fv' != . {
            if `fv' > `q75' {
                mat `zone_num'[`j',1] = 3
                mat `hiflag'[`j',1]   = 1
            }
            else if `fv' > `q50' {
                mat `zone_num'[`j',1] = 2
            }
            else {
                mat `zone_num'[`j',1] = 1
            }
        }
    }

    // Display table
    di as text " "
    di as text "{hline 75}"
    di as text " Fragility Curve   Type: " as result "`type'"
    di as text "{hline 75}"
    di as text %10s "t" %13s "E[Y(t)]" %13s "Fragility" ///
               %10s "Frag_norm" %10s "Zone"
    di as text "{hline 75}"

    foreach j in `= round(`ng'*0.15)' `= round(`ng'*0.35)' ///
                   `= round(`ng'*0.55)' `= round(`ng'*0.75)' ///
                   `= round(`ng'*0.90)' {
        if `j' >= 1 & `j' <= `ng' {
            local fv = `frag'[`j',1]
            local zv = `zone_num'[`j',1]
            local zlab = cond(`zv'==3,"high",cond(`zv'==2,"moderate","low"))
            if `fv' != . {
                di as result %10.3f `ct'[`j',1] ///
                             %13.4f `ce'[`j',1] ///
                             %13.5f `fv' ///
                             %10.5f `frag_norm'[`j',1] ///
                             %10s   "`zlab'"
            }
        }
    }
    di as text "{hline 75}"
    di as text "q50 = " %7.5f `q50' "  q75 = " %7.5f `q75'
    di as text "Zones: low < q50 <= moderate < q75 <= high"

    // Dual panel plot
    if "`noplot'" == "" {
        preserve
            qui drop _all
            qui set obs `ng'
            qui gen double t         = .
            qui gen double estimate  = .
            qui gen double ci_lo     = .
            qui gen double ci_hi     = .
            qui gen double fragility = .

            forval j = 1/`ng' {
                qui replace t         = `ct'[`j',1]    in `j'
                qui replace estimate  = `ce'[`j',1]    in `j'
                qui replace ci_lo     = CSCLO[`j',1]   in `j'
                qui replace ci_hi     = CSCHI[`j',1]   in `j'
                qui replace fragility = `frag'[`j',1]  in `j'
            }

            twoway (rarea ci_lo ci_hi t, lwidth(none) color(ltblue)) ///
                   (line estimate t, lcolor(navy) lwidth(medthick)),  ///
                xtitle("") ytitle("E[Y(t)]")                          ///
                title("Dose-response with fragility regions")          ///
                subtitle("Type: `type'")                              ///
                legend(off) name(cs_top, replace) nodraw

            twoway (line fragility t, lcolor(navy) lwidth(medthick)), ///
                xtitle("Treatment (T)") ytitle("Fragility")           ///
                note("Red dashed = 75th pct | Grey dotted = 50th pct") ///
                legend(off) name(cs_bot, replace) nodraw

            graph combine cs_top cs_bot, cols(1) ///
                title("CausalSpline Fragility Diagnostics") ///
                scheme(s2color)

            if "`saving'" != "" {
                graph save "`saving'", replace
            }
        restore
    }

    return scalar q50  = `q50'
    return scalar q75  = `q75'
    return scalar eps  = `eps'
    return local  type = "`type'"
    return matrix frag_t    = `ct'
    return matrix frag_mu   = `ce'
    return matrix frag_d1   = `d1'
    return matrix frag_d2   = `d2'
    return matrix fragility = `frag'
    return matrix frag_norm = `frag_norm'
    return matrix hiflag    = `hiflag'
    return matrix zone      = `zone_num'
end
