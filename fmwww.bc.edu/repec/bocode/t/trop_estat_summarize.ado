*! trop_estat_summarize
*! Display estimation sample summary

/*
    trop_estat_summarize -- Display estimation sample summary

    Syntax:
        estat summarize [, detailed]

    Options:
        detailed    Display a guide for the unit-by-period treatment distribution.

    Description:
        Reports sample dimensions, treatment structure, outcome variable
        descriptive statistics, estimation method, and variable names stored
        in e() after a call to trop.
*/

program define trop_estat_summarize
    version 17
    syntax [, detailed]

    // Verify that trop estimation results exist in e()
    if "`e(cmd)'" != "trop" {
        di as error "last estimates not found"
        exit 301
    }

    // Display estimation sample dimensions
    di as txt ""
    di as txt "{hline 78}"
    di as txt "Estimation sample summary"
    di as txt "{hline 78}"

    local balance_text = cond(e(balanced) == 1, "(balanced panel)", "(unbalanced panel)")

    di as txt "  Number of observations:    " as res %8.0f e(N_obs) ///
        as txt "    `balance_text'"
    di as txt "  Number of units (N):       " as res %8.0f e(N_units)
    di as txt "  Number of periods (T):     " as res %8.0f e(N_periods)
    di as txt "  Missing rate:              " as res %8.1f e(miss_rate)*100 "%"

    // Display treatment structure statistics
    di as txt ""
    di as txt "Treatment structure:"

    local treat_pct = e(N_treat) / e(N_obs) * 100
    di as txt "  Treated observations:      " as res %8.0f e(N_treat) ///
        as txt "    (" as res %5.1f `treat_pct' "%)"

    local control_pct = e(N_control) / e(N_obs) * 100
    di as txt "  Control observations:      " as res %8.0f e(N_control) ///
        as txt "    (" as res %5.1f `control_pct' "%)"

    local treat_units_pct = e(N_treated_units) / e(N_units) * 100
    di as txt "  Treated units:             " as res %8.0f e(N_treated_units) ///
        as txt "    (" as res %5.1f `treat_units_pct' "%)"

    local treat_periods_pct = e(T_treat_periods) / e(N_periods) * 100
    di as txt "  Treated periods:           " as res %8.0f e(T_treat_periods) ///
        as txt "    (" as res %5.1f `treat_periods_pct' "%)"

    di as txt "  Pattern:                   " as res "`e(treatment_pattern)'"

    // Display outcome variable descriptive statistics
    di as txt ""
    di as txt "Outcome variable (`e(depvar)'):"

    // Compute descriptive statistics from the estimation sample.
    // First check e(y_mean) for backward compatibility; then fall back
    // to computing from the data directly.
    local _has_stats = 0
    capture confirm scalar e(y_mean)
    if !_rc {
        local _has_stats = 1
    }
    else if "`e(depvar)'" != "" {
        capture qui sum `e(depvar)' if e(sample), detail
        if !_rc & r(N) > 0 {
            local _has_stats = 2
            local _y_mean = r(mean)
            local _y_sd   = r(sd)
            local _y_min  = r(min)
            local _y_max  = r(max)
            local _y_p25  = r(p25)
            local _y_p75  = r(p75)
        }
    }

    if `_has_stats' == 1 {
        di as txt "  Mean:      " as res %9.3f e(y_mean)
        capture confirm scalar e(y_sd)
        if !_rc {
            di as txt "  Std. Dev:  " as res %9.3f e(y_sd)
        }
        capture confirm scalar e(y_min)
        if !_rc {
            di as txt "  Min:       " as res %9.3f e(y_min)
        }
        capture confirm scalar e(y_max)
        if !_rc {
            di as txt "  Max:       " as res %9.3f e(y_max)
        }
    }
    else if `_has_stats' == 2 {
        di as txt "  Mean:      " as res %9.3f `_y_mean'
        di as txt "  Std. Dev:  " as res %9.3f `_y_sd'
        di as txt "  Min:       " as res %9.3f `_y_min'
        di as txt "  Max:       " as res %9.3f `_y_max'
        di as txt "  p25:       " as res %9.3f `_y_p25'
        di as txt "  p75:       " as res %9.3f `_y_p75'
    }
    else {
        di as txt "  (Descriptive statistics not available)"
    }

    // Display estimation method and variable names
    di as txt ""
    di as txt "Estimation details:"

    if "`e(method)'" != "" {
        if "`e(method)'" == "joint" {
            di as txt "  Method:        " as res "joint" ///
                as txt " (Remark 6.1 extension; shared tau)"
        }
        else {
            di as txt "  Method:        " as res "twostep" ///
                as txt " (Algorithm 2 default)"
        }
    }
    else {
        di as txt "  Method:        " as res "twostep" ///
            as txt " (Algorithm 2 default)"
    }

    di as txt "  Outcome var:   " as res "`e(depvar)'"
    di as txt "  Treatment var: " as res "`e(treatvar)'"

    if "`e(panelvar)'" != "" {
        di as txt "  Panel var:     " as res "`e(panelvar)'"
    }
    if "`e(timevar)'" != "" {
        di as txt "  Time var:      " as res "`e(timevar)'"
    }

    di as txt "{hline 78}"

    // Output detailed treatment distribution if requested
    if "`detailed'" != "" {
        _estat_summarize_detailed
    }
end

/*
    _estat_summarize_detailed -- Display guide for treatment distribution tabulation
*/
program define _estat_summarize_detailed
    di as txt ""
    di as txt "Treatment distribution (unit × time):"
    di as txt "  Note: Detailed treatment table requires access to original data"
    di as txt "        Use {bf:tabulate `e(panelvar)' `e(timevar)' if `e(treatvar)'==1}"
    di as txt "        in your dataset to see full distribution"
end
