*! coefconv_plot v1.0.0 — April 2026
*! Dr Noman Arshed, Sunway Business School, Sunway University
*! Visualization companion for coefconv
*! ─────────────────────────────────────────────────────────────────
*! Produces three graphs to assess coefficient meaningfulness:
*!   (1) Standardized slopes forest plot  — β* with CI, all predictors
*!   (2) Pratt importance bar chart       — % of R², all predictors
*!   (3) Discrete effects bar chart       — ΔY scenarios, one per predictor
*!
*! Syntax:
*!   coefconv_plot [, GRate(#) LEVEL(#) SCHeme(str) SAVing(str)
*!                  noSTD noPRATT noEFFects noLABels]
*!
*! Must be run immediately after the regression (before any other
*! estimation command overwrites e()).
*! ─────────────────────────────────────────────────────────────────

capture program drop coefconv_plot
program define coefconv_plot
    version 14.0

    syntax [, ///
        GRate(real 0.01)   /// Growth rate for discrete effects (default 1%)
        LEVEL(real 95)     /// CI level for forest plot (default 95%)
        SCHeme(string)     /// Stata graph scheme
        SAVing(string asis) /// Save graphs: saving(stub[, replace])
        noSTD              /// Skip standardized slopes plot
        noPRATT            /// Skip Pratt importance plot
        noEFFects          /// Skip per-variable discrete effects plots
        noLABels           /// Suppress Cohen benchmark labels on forest plot
    ]

    // =========================================================================
    // 0. SETUP
    // =========================================================================
    if "`e(cmd)'" == "" {
        di as error "coefconv_plot: No estimation results found. Run a regression first."
        exit 301
    }

    local depvar  "`e(depvar)'"
    local ecmd    "`e(cmd)'"
    local N       = e(N)
    local r2      = e(r2)
    local r2str   = string(`r2', "%6.4f")
    local zc      = invnormal(1 - (100-`level')/200)

    // Scheme option string
    local schopt = cond("`scheme'" == "", "", `"scheme(`scheme')"')

    // Parse saving option: saving(stub [, replace])
    local savstub  ""
    local savrep   ""
    if `"`saving'"' != "" {
        tokenize `"`saving'"', parse(",")
        local savstub = trim("`1'")
        if trim("`3'") == "replace" local savrep "replace"
    }

    // =========================================================================
    // 1. EXTRACT COEFFICIENT VECTOR & CLEAN VARIABLE LIST
    // =========================================================================
    tempname B V
    matrix `B' = e(b)
    matrix `V' = e(V)
    local allvars : colnames `B'

    local indepvars ""
    foreach v of local allvars {
        if "`v'" == "_cons"           continue
        if substr("`v'",1,2) == "o."  continue
        if substr("`v'",1,2) == "b."  continue
        local indepvars "`indepvars' `v'"
    }
    local k : word count `indepvars'

    if `k' == 0 {
        di as error "coefconv_plot: No valid predictors found."
        exit 198
    }

    // =========================================================================
    // 2. Y DESCRIPTIVES
    // =========================================================================
    quietly summarize `depvar' if e(sample)
    local ymean = r(mean)
    local ysd   = r(sd)

    // =========================================================================
    // 3. RUN COEFCONV SILENTLY — GET PRATT % AND SAVED DATASET
    // =========================================================================
    tempfile ccv_results
    quietly coefconv, notable grate(`grate') saving(`"`ccv_results'"', replace)

    // Capture all Pratt r() scalars NOW before any subsequent command
    // overwrites r().  We store them as locals indexed by variable position.
    local jj = 0
    foreach v of local indepvars {
        local jj = `jj' + 1
        local ccv_pratt_`jj' = r(pratt_pct_`v')
    }

    // =========================================================================
    // 4. COMPUTE beta*, CIs, AND STORE PRATT % FOR EACH VARIABLE
    // =========================================================================
    local j = 0
    foreach v of local indepvars {
        local j = `j' + 1

        capture confirm variable `v'
        if _rc {
            // Factor/interaction variable — store raw only
            local bstar_`j'   = .
            local lb_`j'      = .
            local ub_`j'      = .
            local sig_`j'     = 0
            local pratt_`j'   = .
            local sdx_`j'     = .
            local xm_`j'      = .
            local xmn_`j'     = .
            local xmx_`j'     = .
            continue
        }

        quietly summarize `v' if e(sample)
        local sdx_`j'  = r(sd)
        local xm_`j'   = r(mean)
        local xmn_`j'  = r(min)
        local xmx_`j'  = r(max)

        local beta_j = `B'[1, `j']
        local varj   = `V'[`j', `j']
        local se_j   = sqrt(max(`varj', 0))

        if !missing(`sdx_`j'') & `ysd' > 0 & `sdx_`j'' > 0 {
            local bstar_`j'   = `beta_j' * `sdx_`j'' / `ysd'
            local sebstar_`j' = `se_j'   * `sdx_`j'' / `ysd'
            local lb_`j'      = `bstar_`j'' - `zc' * `sebstar_`j''
            local ub_`j'      = `bstar_`j'' + `zc' * `sebstar_`j''
        }
        else {
            local bstar_`j'   = .
            local lb_`j'      = .
            local ub_`j'      = .
        }
        local sig_`j'   = cond(!missing(`lb_`j''), ///
                               ((`lb_`j'' > 0) | (`ub_`j'' < 0)), 0)
        // Use pre-captured Pratt value (safe from r() overwrite)
        local pratt_`j' = `ccv_pratt_`j''
    }
    local ktot = `j'

    // =========================================================================
    // 5. GRAPH 1 — STANDARDIZED SLOPES FOREST PLOT
    // =========================================================================
    if "`std'" == "" {

        preserve

        quietly {
            clear
            set obs `ktot'
            gen str32  vname    = ""
            gen double bstar    = .
            gen double lb       = .
            gen double ub       = .
            gen int    sig      = 0
            gen int    obsnum   = _n

            forvalues j2 = 1/`ktot' {
                local vn : word `j2' of `indepvars'
                replace vname  = "`vn'"       in `j2'
                replace bstar  = `bstar_`j2'' in `j2'
                replace lb     = `lb_`j2''    in `j2'
                replace ub     = `ub_`j2''    in `j2'
                replace sig    = `sig_`j2''   in `j2'
            }

            // Split by significance for two-color coding
            gen double bstar_sig  = bstar if sig == 1
            gen double bstar_nsig = bstar if sig == 0
        }

        // Build ylabel macro from current data
        local ylabs ""
        forvalues j2 = 1/`ktot' {
            local vn : word `j2' of `indepvars'
            local ylabs `"`ylabs' `j2' "`vn'""'
        }

        // Subtitle string (no format specs in subtitle())
        local sub1 "Model: `ecmd'   Dep. Var.: `depvar'   N = `N'   R2 = `r2str'"
        local sub2 "Dashed lines: Cohen small (0.20) / medium (0.50) / large (0.80)"

        twoway ///
            (rcap lb ub obsnum, horizontal ///
                lcolor(gs11) lwidth(thin)) ///
            (scatter obsnum bstar_nsig, ///
                msymbol(D) msize(medlarge) mcolor(gs9) mlwidth(thin)) ///
            (scatter obsnum bstar_sig, ///
                msymbol(D) msize(medlarge) mcolor(navy) mlwidth(thin)) ///
            , ///
            xline(0,   lcolor(black)  lwidth(medthin) lpattern(solid)) ///
            xline(-0.2, lcolor(gs12)  lwidth(vthin)   lpattern(shortdash)) ///
            xline( 0.2, lcolor(gs12)  lwidth(vthin)   lpattern(shortdash)) ///
            xline(-0.5, lcolor(gs10)  lwidth(vthin)   lpattern(shortdash)) ///
            xline( 0.5, lcolor(gs10)  lwidth(vthin)   lpattern(shortdash)) ///
            xline(-0.8, lcolor(gs8)   lwidth(vthin)   lpattern(shortdash)) ///
            xline( 0.8, lcolor(gs8)   lwidth(vthin)   lpattern(shortdash)) ///
            ylabel(`ylabs', angle(0) labsize(small) nogrid) ///
            xlabel(, format(%5.2f) labsize(small)) ///
            xtitle("Standardized Slope (beta*)", size(small)) ///
            ytitle("") ///
            title("Standardized Slopes with `level'% Confidence Intervals", ///
                  size(medsmall) margin(b=2)) ///
            subtitle("`sub1'", size(vsmall) margin(b=1)) ///
            note("`sub2'", size(vsmall)) ///
            legend(order(3 "Significant at `level'%" 2 "Not significant") ///
                   size(vsmall) rows(1) position(6)) ///
            name(ccv_std, replace) ///
            `schopt'

        if "`savstub'" != "" {
            quietly graph save `"`savstub'_std"', `savrep'
        }

        restore
    }

    // =========================================================================
    // 6. GRAPH 2 — PRATT IMPORTANCE BAR CHART
    // =========================================================================
    if "`pratt'" == "" {

        preserve

        quietly {
            use `"`ccv_results'"', clear

            // Drop rows with missing pratt (factor vars etc)
            drop if missing(pratt_pct)

            // Sort ascending so largest appears at top
            gen double abs_pratt = abs(pratt_pct)
            sort abs_pratt
            gen int order = _n

            gen double pp_pos = max(pratt_pct, 0)
            gen double pp_neg = min(pratt_pct, 0)
        }

        local nobs = _N
        local ylabs2 ""
        forvalues i = 1/`nobs' {
            local vn = varname[`i']
            local ylabs2 `"`ylabs2' `i' "`vn'""'
        }

        local sub3 "Dep. Var.: `depvar'   N = `N'   R2 = `r2str'"
        local sub4 "Negative values = suppressor variables"

        twoway ///
            (bar pp_pos order, horizontal barwidth(0.65) ///
                fcolor(navy%70) lcolor(navy%80) lwidth(vthin)) ///
            (bar pp_neg order, horizontal barwidth(0.65) ///
                fcolor(cranberry%70) lcolor(cranberry%80) lwidth(vthin)) ///
            , ///
            xline(0, lcolor(black) lwidth(medthin)) ///
            ylabel(`ylabs2', angle(0) labsize(small) nogrid) ///
            xlabel(, format(%5.1f) labsize(small)) ///
            xtitle("Share of R-squared (%)", size(small)) ///
            ytitle("") ///
            title("Relative Importance: Pratt's Decomposition of R-Squared", ///
                  size(medsmall) margin(b=2)) ///
            subtitle("`sub3'", size(vsmall) margin(b=1)) ///
            note("`sub4'", size(vsmall)) ///
            legend(order(1 "Productive predictor" 2 "Suppressor") ///
                   size(vsmall) rows(1) position(6)) ///
            name(ccv_pratt, replace) ///
            `schopt'

        if "`savstub'" != "" {
            quietly graph save `"`savstub'_pratt"', `savrep'
        }

        restore
    }

    // =========================================================================
    // 7. GRAPH 3 — PER-VARIABLE DISCRETE EFFECTS (one graph per predictor)
    // =========================================================================
    if "`effects'" == "" {

        local j = 0
        foreach v of local indepvars {
            local j = `j' + 1

            // Skip factor/interaction terms or zero-SD variables
            capture confirm variable `v'
            if _rc continue
            if missing(`sdx_`j'') | `sdx_`j'' == 0 continue

            local beta_j = `B'[1, `j']
            local sdx_v  = `sdx_`j''
            local xm_v   = `xm_`j''
            local xmn_v  = `xmn_`j''
            local xmx_v  = `xmx_`j''

            // Get quantiles
            quietly _pctile `v' if e(sample), percentiles(10 25 50 75 90)
            local xp10 = r(r1)
            local xp25 = r(r2)
            local xp50 = r(r3)
            local xp75 = r(r4)
            local xp90 = r(r5)

            // Compute all delta-Y values
            local dy_gr   = `beta_j' * `xm_v'  * `grate'
            local dy_1sd  = `beta_j' * `sdx_v'
            local dy_2sd  = `beta_j' * 2 * `sdx_v'
            local dy_iqr  = `beta_j' * (`xp75' - `xp25')
            local dy_rng  = `beta_j' * (`xmx_v' - `xmn_v')
            local dy_p10  = `beta_j' * (`xp10'  - `xp50')
            local dy_p25  = `beta_j' * (`xp25'  - `xp50')
            local dy_p75  = `beta_j' * (`xp75'  - `xp50')
            local dy_p90  = `beta_j' * (`xp90'  - `xp50')

            // Pre-format subtitle numbers (title() does not accept %fmt)
            local betastr  = string(`beta_j',        "%9.4f")
            local bstarstr = string(`bstar_`j'',     "%6.4f")
            local prattstr = string(`pratt_`j'',     "%5.2f")
            local grpct    = string(`grate' * 100,   "%4.1f")

            // Scenario labels (short enough for ylabel)
            local sc1 "Growth `grpct'% of mean"
            local sc2 "+/-1 SD"
            local sc3 "+/-2 SD"
            local sc4 "IQR  (Q25 to Q75)"
            local sc5 "Full range (min to max)"
            local sc6 "p50 to p10"
            local sc7 "p50 to p25"
            local sc8 "p50 to p75"
            local sc9 "p50 to p90"

            preserve

            quietly {
                clear
                set obs 9

                gen double delta_y  = .
                gen double abs_dy   = .
                gen str50  scenario = ""
                gen double dy_pos   = .
                gen double dy_neg   = .

                replace delta_y  = `dy_gr'  in 1
                replace scenario = "`sc1'"  in 1
                replace delta_y  = `dy_1sd' in 2
                replace scenario = "`sc2'"  in 2
                replace delta_y  = `dy_2sd' in 3
                replace scenario = "`sc3'"  in 3
                replace delta_y  = `dy_iqr' in 4
                replace scenario = "`sc4'"  in 4
                replace delta_y  = `dy_rng' in 5
                replace scenario = "`sc5'"  in 5
                replace delta_y  = `dy_p10' in 6
                replace scenario = "`sc6'"  in 6
                replace delta_y  = `dy_p25' in 7
                replace scenario = "`sc7'"  in 7
                replace delta_y  = `dy_p75' in 8
                replace scenario = "`sc8'"  in 8
                replace delta_y  = `dy_p90' in 9
                replace scenario = "`sc9'"  in 9

                replace abs_dy = abs(delta_y)
                sort abs_dy                 // smallest effect at bottom
                gen int order = _n

                replace dy_pos = max(delta_y, 0)
                replace dy_neg = min(delta_y, 0)
            }

            // Build ylabel from sorted data
            local ylabs3 ""
            forvalues i = 1/9 {
                local sc = scenario[`i']
                local ylabs3 `"`ylabs3' `i' "`sc'""'
            }

            // Graph subtitle lines
            local sub5 "Predictor: `v'   beta = `betastr'   beta* = `bstarstr'   Pratt% = `prattstr'%"
            local sub6 "Dep. Var.: `depvar'   Growth rate = `grpct'%   Sorted by |delta-Y| ascending"
            local xttl "Predicted delta-Y (in `depvar' units)"
            local ttl   "Discrete Effect Scenarios: `v'"

            twoway ///
                (bar dy_pos order, horizontal barwidth(0.72) ///
                    fcolor(navy%65) lcolor(navy%75) lwidth(vthin)) ///
                (bar dy_neg order, horizontal barwidth(0.72) ///
                    fcolor(cranberry%65) lcolor(cranberry%75) lwidth(vthin)) ///
                , ///
                xline(0, lcolor(black) lwidth(medthin)) ///
                ylabel(`ylabs3', angle(0) labsize(vsmall) nogrid) ///
                xlabel(, format(%9.2f) labsize(vsmall)) ///
                xtitle("`xttl'", size(small)) ///
                ytitle("Scenario  (sorted by |delta-Y|)", size(vsmall)) ///
                title("`ttl'", size(medsmall) margin(b=2)) ///
                subtitle("`sub5'", size(vsmall) margin(b=1)) ///
                note("`sub6'", size(vsmall)) ///
                legend(off) ///
                name(ccv_eff_`v', replace) ///
                `schopt'

            if "`savstub'" != "" {
                quietly graph save `"`savstub'_eff_`v'"', `savrep'
            }

            restore

        } // end foreach v

    } // end noEFFects check

end
