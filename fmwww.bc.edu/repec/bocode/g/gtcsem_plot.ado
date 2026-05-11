*! version 1.0.0  11May2026  Plot CSEMs from gtcsem
*! Companion post-estimation plot command for gtcsem.ado
*!
*! Renders Brennan-style plots of conditional SEMs against
*! observed score, optionally with confidence bands and method
*! comparisons.
*!
*! Author:  Rene Gempp <rene.gempp@udp.cl>

capture program drop gtcsem_plot
program define gtcsem_plot
    version 16.0
    
    syntax [, ///
        PLOT(string)         ///
        ABSrel(string)       ///
        PREfix(name)         ///
        METHod(string)       ///
        SMooth               ///
        COMPare              ///
        CI(real 95)          ///
        CIBands(string)      ///
        ASEmethod(string)    ///
        SAVING(string)       ///
        TITLE(string)        ///
        SUBTITLE(string)     ///
        XTitle(string)       ///
        YTitle(string)       ///
        Name(string)         ///
        *                    /// pass-through twoway options
    ]
    
    /* ========================================================
       Defaults and validation
       ======================================================== */
    
    if "`plot'"      == "" local plot      "csem"
    if "`absrel'"    == "" local absrel    "relative"
    if "`asemethod'" == "" local asemethod "analytical"
    if "`method'"    == "" local method    "full"
    if "`cibands'"   == "" local cibands   "person"

    local plot      = lower("`plot'")
    local absrel    = lower("`absrel'")
    local asemethod = lower("`asemethod'")
    local method    = lower("`method'")
    local cibands   = lower("`cibands'")

    if !inlist("`plot'", "csem", "ci", "both") {
        di as error "plot() must be one of: csem, ci, both"
        exit 198
    }
    if !inlist("`absrel'", "relative", "absolute", "both") {
        di as error "absrel() must be one of: relative, absolute, both"
        exit 198
    }
    if !inlist("`asemethod'", "analytical", "bootstrap") {
        di as error "asemethod() must be one of: analytical, bootstrap"
        exit 198
    }
    if !inlist("`method'", "full", "large_a", "uncorrelated") {
        di as error "method() must be one of: full, large_a, uncorrelated"
        exit 198
    }
    if !inlist("`cibands'", "person", "model") {
        di as error "cibands() must be one of: person, model"
        exit 198
    }
    
    if `ci' <= 0 | `ci' >= 100 {
        di as error "ci() must be strictly between 0 and 100."
        exit 198
    }
    
    /* Read prefix from r(prefix) if not supplied; fall back to the
       dataset characteristic stored by gtcsem so that repeat plot
       calls keep working even after intervening r-class commands. */
    local r_method "`r(method)'"
    if "`prefix'" == "" {
        local prefix "`r(prefix)'"
        if "`prefix'" == "" {
            local prefix : char _dta[gtcsem_prefix]
        }
        if "`prefix'" == "" {
            di as error "No prefix supplied and gtcsem state not found. " ///
                "Run gtcsem first or supply prefix() option."
            exit 198
        }
    }
    if "`r_method'" == "" {
        local r_method : char _dta[gtcsem_method]
    }
    
    /* ========================================================
       Verify required variables exist
       ======================================================== */
    
    capture confirm variable `prefix'_score
    if _rc {
        di as error "Variable `prefix'_score not found. " ///
            "Did you run gtcsem with generate(`prefix') first?"
        exit 111
    }
    
    /* Mapping from method to suffix used by gtcsem when method=all */
    local sfx ""
    if "`r_method'" == "all" {
        if "`method'" == "full"          local sfx "_full"
        if "`method'" == "large_a"       local sfx "_la"
        if "`method'" == "uncorrelated"  local sfx "_unc"
    }
    
    /* When compare requested, ensure all three methods exist */
    if "`compare'" != "" {
        capture confirm variable `prefix'_rel_csem_full
        if _rc {
            di as error "compare requires gtcsem to have been called " ///
                "with method(all)."
            exit 111
        }
    }
    
    /* ========================================================
       Variable bookkeeping
       ======================================================== */
    
    local x        `prefix'_score
    local abs_y    `prefix'_abs_csem
    local rel_y    `prefix'_rel_csem`sfx'
    local abs_y_sm `prefix'_abs_csem_sm
    local rel_y_sm `prefix'_rel_csem_sm`sfx'

    /* If gtcsem was run with -excludeextremes-, the smoothed
       variables are missing for floor/ceiling cases. We use that
       missingness to filter the raw scatter as well, so that
       the displayed cloud and the fitted line cover the same
       sample. Without -excludeextremes-, `keep' is just `1'. */
    local gtcsem_excl : char _dta[gtcsem_excludeextremes]
    tempvar keep
    if "`gtcsem_excl'" != "" {
        capture confirm variable `abs_y_sm'
        if !_rc {
            quietly gen byte `keep' = !missing(`abs_y_sm')
        }
        else {
            quietly gen byte `keep' = 1
        }
    }
    else {
        quietly gen byte `keep' = 1
    }

    if "`asemethod'" == "analytical" {
        local v_abs `prefix'_vabs_an
        local v_rel `prefix'_vrev_an`sfx'
    }
    else {
        local v_abs `prefix'_vabs_bs
        local v_rel `prefix'_vrev_bs`sfx'
        capture confirm variable `v_abs'
        if _rc {
            di as error "asemethod(bootstrap) requested, but `v_abs' not " ///
                "found. Did you run gtcsem with semethod(bootstrap) or both?"
            exit 111
        }
    }
    
    /* ========================================================
       Compute CI band variables (squared error variances are
       on the CSEM scale via sqrt). Delta-method approximation:
       Var[csem] = Var[ev] / (4 * ev)
       so SE[csem] = sqrt(Var[ev]) / (2 * sqrt(ev))
       ======================================================== */
    
    local zcrit = invnormal(1 - (1 - `ci'/100)/2)

    tempvar abs_se_csem rel_se_csem
    tempvar abs_lo abs_hi rel_lo rel_hi

    if "`plot'" == "ci" | "`plot'" == "both" {
        if "`cibands'" == "model" {
            /* Model-based bands: refit the quadratic smoother on
               the per-person _ev variables, use predict, stdp to
               obtain the SE of the mean fit, then convert to the
               CSEM scale via the delta method:
                  SE[csem] = SE[ev_hat] / (2 * sqrt(ev_hat)).
               The refit is restricted to the same `keep' sample
               (non-extreme cases when -excludeextremes- was on).
               asemethod() is ignored under cibands(model). */
            tempvar score2_m
            quietly generate double `score2_m' = `x'^2

            if inlist("`absrel'", "absolute", "both") {
                tempvar yhat_a stdp_a csem_a
                quietly regress `prefix'_abs_ev `x' `score2_m' if `keep'
                quietly predict double `yhat_a'
                quietly predict double `stdp_a', stdp
                quietly generate double `csem_a' = ///
                    sqrt(max(`yhat_a', 0))
                quietly generate double `abs_se_csem' = ///
                    cond(`csem_a' > 0, `stdp_a' / (2 * `csem_a'), .)
                quietly generate double `abs_lo' = ///
                    max(0, `csem_a' - `zcrit' * `abs_se_csem')
                quietly generate double `abs_hi' = ///
                    `csem_a' + `zcrit' * `abs_se_csem'
            }
            if inlist("`absrel'", "relative", "both") {
                tempvar yhat_r stdp_r csem_r
                quietly regress `prefix'_rel_ev`sfx' `x' `score2_m' if `keep'
                quietly predict double `yhat_r'
                quietly predict double `stdp_r', stdp
                quietly generate double `csem_r' = ///
                    sqrt(max(`yhat_r', 0))
                quietly generate double `rel_se_csem' = ///
                    cond(`csem_r' > 0, `stdp_r' / (2 * `csem_r'), .)
                quietly generate double `rel_lo' = ///
                    max(0, `csem_r' - `zcrit' * `rel_se_csem')
                quietly generate double `rel_hi' = ///
                    `csem_r' + `zcrit' * `rel_se_csem'
            }
        }
        else {
            /* Person-level bands (default). Each person's CSEM
               gets its own CI from the per-person Var[ev_p]. */
            if inlist("`absrel'", "absolute", "both") {
                quietly generate double `abs_se_csem' = ///
                    cond(`abs_y' > 0, sqrt(`v_abs') / (2 * `abs_y'), .)
                quietly generate double `abs_lo' = ///
                    max(0, `abs_y' - `zcrit' * `abs_se_csem')
                quietly generate double `abs_hi' = `abs_y' + `zcrit' * `abs_se_csem'
            }
            if inlist("`absrel'", "relative", "both") {
                quietly generate double `rel_se_csem' = ///
                    cond(`rel_y' > 0, sqrt(`v_rel') / (2 * `rel_y'), .)
                quietly generate double `rel_lo' = ///
                    max(0, `rel_y' - `zcrit' * `rel_se_csem')
                quietly generate double `rel_hi' = `rel_y' + `zcrit' * `rel_se_csem'
            }
        }
    }
    
    /* ========================================================
       Default titles
       ======================================================== */
    
    if "`xtitle'"  == "" local xtitle  "Observed score"
    if "`ytitle'"  == "" local ytitle  "Conditional SEM"
    if "`title'"   == "" {
        if "`absrel'" == "absolute" local title "Absolute conditional SEM"
        else if "`absrel'" == "relative" local title "Relative conditional SEM"
        else local title "Conditional SEMs"
    }
    
    /* ========================================================
       Construct the twoway command
       ======================================================== */
    
    local plotcmds ""
    
    /* ----- Compare mode: three methods overlaid ----- */
    if "`compare'" != "" {
        local plotcmds `plotcmds' ///
            (scatter `prefix'_rel_csem_full         `x' if `keep', msymbol(O) ///
                msize(small) mcolor(navy)) ///
            (scatter `prefix'_rel_csem_la           `x' if `keep', msymbol(D) ///
                msize(small) mcolor(maroon)) ///
            (scatter `prefix'_rel_csem_unc          `x' if `keep', msymbol(T) ///
                msize(small) mcolor(forest_green))
        local legend ///
            legend(order(1 "full" 2 "large_a" 3 "uncorrelated") rows(1))
        if "`smooth'" != "" {
            capture confirm variable `prefix'_rel_csem_sm_full
            if !_rc {
                local plotcmds `plotcmds' ///
                    (line `prefix'_rel_csem_sm_full `x' if `keep', sort lcolor(navy)) ///
                    (line `prefix'_rel_csem_sm_la   `x' if `keep', sort lcolor(maroon)) ///
                    (line `prefix'_rel_csem_sm_unc  `x' if `keep', sort lcolor(forest_green))
            }
        }
    }
    /* ----- Standard plot ----- */
    else {
        if "`plot'" == "ci" | "`plot'" == "both" {
            if inlist("`absrel'", "absolute", "both") {
                local plotcmds `plotcmds' ///
                    (rarea `abs_lo' `abs_hi' `x' if `keep', sort ///
                        color(navy%20) lwidth(none))
            }
            if inlist("`absrel'", "relative", "both") {
                local plotcmds `plotcmds' ///
                    (rarea `rel_lo' `rel_hi' `x' if `keep', sort ///
                        color(maroon%20) lwidth(none))
            }
        }
        if inlist("`absrel'", "absolute", "both") {
            if inlist("`plot'", "csem", "both") {
                local plotcmds `plotcmds' ///
                    (scatter `abs_y' `x' if `keep', msymbol(O) msize(small) ///
                        mcolor(navy))
            }
            if "`smooth'" != "" {
                capture confirm variable `abs_y_sm'
                if !_rc {
                    local plotcmds `plotcmds' ///
                        (line `abs_y_sm' `x' if `keep', sort lcolor(navy) lwidth(medthick))
                }
            }
        }
        if inlist("`absrel'", "relative", "both") {
            if inlist("`plot'", "csem", "both") {
                local plotcmds `plotcmds' ///
                    (scatter `rel_y' `x' if `keep', msymbol(O) msize(small) ///
                        mcolor(maroon))
            }
            if "`smooth'" != "" {
                capture confirm variable `rel_y_sm'
                if !_rc {
                    local plotcmds `plotcmds' ///
                        (line `rel_y_sm' `x' if `keep', sort lcolor(maroon) lwidth(medthick))
                }
            }
        }

        /* Legend logic. We track which positional index in the
           overlay corresponds to the absolute and relative
           "anchor" series (preferring scatter when present, then
           rarea, then line). Indices follow the order in which
           the (...) plots were added above. */
        if "`absrel'" == "both" {
            local idx_abs 0
            local idx_rel 0
            local pos     0
            if inlist("`plot'", "ci", "both") {
                local pos = `pos' + 1
                local idx_abs = `pos'
                local pos = `pos' + 1
                local idx_rel = `pos'
            }
            if inlist("`plot'", "csem", "both") {
                local pos = `pos' + 1
                local idx_abs = `pos'
                if "`smooth'" != "" local pos = `pos' + 1
                local pos = `pos' + 1
                local idx_rel = `pos'
            }
            else if "`smooth'" != "" {
                /* plot(ci) with smooth: lines come right after both rareas */
                local pos = `pos' + 1
                local idx_abs = `pos'
                local pos = `pos' + 1
                local idx_rel = `pos'
            }
            local legend legend(order(`idx_abs' "absolute" `idx_rel' "relative") rows(1))
        }
        else {
            local legend legend(off)
        }
    }
    
    /* Add subtitle showing CI level when CI shown */
    if ("`plot'" == "ci" | "`plot'" == "both") & "`compare'" == "" {
        if "`subtitle'" == "" {
            if "`cibands'" == "model" {
                local subtitle "`ci'% CI bands around quadratic fit"
            }
            else {
                local subtitle "`ci'% CI bands using `asemethod' SE"
            }
        }
    }
    
    /* ========================================================
       Execute twoway
       ======================================================== */
    
    local nameopt ""
    if "`name'"   != "" local nameopt   name(`name')
    local saveopt ""
    if "`saving'" != "" local saveopt   saving(`saving')
    
    twoway `plotcmds', ///
        title("`title'") subtitle("`subtitle'") ///
        xtitle("`xtitle'") ytitle("`ytitle'") ///
        `legend' `nameopt' `saveopt' `options'
    
end
