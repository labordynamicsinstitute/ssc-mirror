*! _trop_estat_distance.ado
*! Unit distance distribution diagnostics for trop
*!
*! Computes and visualizes the pairwise unit distance matrix distribution.
*! Theory: Paper Eq.3 defines dist_{-t}^unit(j,i) = sqrt[mean_{u!=t}((Y_iu-Y_ju)^2)]
*!
*! Syntax:
*!   _trop_estat_distance [, GRAPH SAVing(string) BINS(integer)]
*!
*! Options:
*!   graph       - Display publication-quality weight diagnostic plots
*!   saving(str) - Save combined graph to file (e.g., saving(diag.gph))
*!   bins(#)     - Number of histogram bins (default: 30)

program define _trop_estat_distance, rclass
    version 17.0
    syntax [, GRAPH SAVing(string) BINS(integer 30)]

    /* ──────────────────────────────────────────────────────────────────────
       1. Pre-checks
    ────────────────────────────────────────────────────────────────────── */

    if "`e(cmd)'" != "trop" {
        di as error "estat distance requires trop estimation results"
        exit 301
    }

    // Retrieve panel dimensions from estimation results
    local N_units   = e(N_units)
    local N_periods = e(N_periods)
    local depvar    "`e(depvar)'"
    local treatvar  "`e(treatvar)'"
    local panelvar  "`e(panelvar)'"
    local timevar   "`e(timevar)'"

    if `N_units' < 2 {
        di as error "Distance computation requires at least 2 panel units"
        exit 459
    }

    /* ──────────────────────────────────────────────────────────────────────
       2. Compute pairwise unit distances via Mata
    ────────────────────────────────────────────────────────────────────── */

    // Rebuild 1..N / 1..T index variables (originals cleaned after trop)
    tempvar _ed_pidx _ed_tidx _ed_touse
    qui gen byte `_ed_touse' = e(sample)
    qui egen `_ed_pidx' = group(`panelvar') if `_ed_touse'
    qui egen `_ed_tidx' = group(`timevar') if `_ed_touse'
    // Pass tempvar names to Mata via globals (only way across ADO->Mata boundary)
    mata: st_global("__trop_panel_idx_var", "`_ed_pidx'")
    mata: st_global("__trop_time_idx_var", "`_ed_tidx'")
    mata: st_global("__trop_touse_var", "`_ed_touse'")

    mata: _trop_estat_distance_compute(`N_units', `N_periods', "`depvar'", "`treatvar'")

    // Check for computation errors
    if `_ed_rc' != 0 {
        exit `_ed_rc'
    }

    // Check for zero valid pairs
    if scalar(__ed_N_pairs) == 0 | missing(scalar(__ed_N_pairs)) {
        di as txt _n "{hline 78}"
        di as txt "Unit Distance Distribution (Eq.3: RMSE over control periods)"
        di as txt "{hline 78}"
        di as txt "  {it:No valid unit pairs found.}"
        di as txt "  All unit pairs lack common non-treated periods with"
        di as txt "  non-missing outcomes, so distances cannot be computed."
        di as txt "{hline 78}"
        return scalar N_pairs = 0
        capture scalar drop __ed_N_pairs
        capture scalar drop __ed_mean
        capture scalar drop __ed_sd
        capture scalar drop __ed_min
        capture scalar drop __ed_max
        capture scalar drop __ed_p25
        capture scalar drop __ed_p50
        capture scalar drop __ed_p75
        capture matrix drop __ed_distances
        exit 0
    }

    /* ──────────────────────────────────────────────────────────────────────
       3. Display results table
    ────────────────────────────────────────────────────────────────────── */

    di as txt _n "{hline 78}"
    di as txt "Unit Distance Distribution (Eq.3: RMSE over control periods)"
    di as txt "{hline 78}"
    di as txt "  Number of unit pairs: " as res %10.0f scalar(__ed_N_pairs)
    di as txt "  Mean distance:        " as res %10.4f scalar(__ed_mean)
    di as txt "  Std. deviation:       " as res %10.4f scalar(__ed_sd)
    di as txt "  Minimum:              " as res %10.4f scalar(__ed_min)
    di as txt "  25th percentile:      " as res %10.4f scalar(__ed_p25)
    di as txt "  Median:               " as res %10.4f scalar(__ed_p50)
    di as txt "  75th percentile:      " as res %10.4f scalar(__ed_p75)
    di as txt "  Maximum:              " as res %10.4f scalar(__ed_max)
    di as txt "{hline 78}"

    /* ──────────────────────────────────────────────────────────────────────
       4. Weight interpretation (if lambda_unit available)
    ────────────────────────────────────────────────────────────────────── */

    capture confirm scalar e(lambda_unit)
    if !_rc & !missing(e(lambda_unit)) {
        local lambda_u = e(lambda_unit)
        local w_median = exp(-`lambda_u' * scalar(__ed_p50))
        local w_p75    = exp(-`lambda_u' * scalar(__ed_p75))
        local pct_p75 : di %4.1f `w_p75' * 100

        di as txt _n "Weight mapping (lambda_unit = " as res %6.4f `lambda_u' as txt "):"
        di as txt "  w(median dist) = exp(-" %4.2f `lambda_u' ///
            " * " %6.4f scalar(__ed_p50) ") = " as res %8.6f `w_median'
        di as txt "  w(75th pctl)   = exp(-" %4.2f `lambda_u' ///
            " * " %6.4f scalar(__ed_p75) ") = " as res %8.6f `w_p75'
        di as txt "  {it:Units beyond 75th pctl contribute <`pct_p75'% weight}"
    }

    /* ──────────────────────────────────────────────────────────────────────
       5. Graphical output (publication quality)
    ────────────────────────────────────────────────────────────────────── */

    if "`graph'" != "" {
        local n_dist = colsof(__ed_distances)

        // Check lambda availability
        capture confirm scalar e(lambda_unit)
        local _has_lambda_u = (!_rc & !missing(e(lambda_unit)))
        capture confirm scalar e(lambda_time)
        local _has_lambda_t = (!_rc & !missing(e(lambda_time)))

        if `_has_lambda_u' {
            local lambda_unit = e(lambda_unit)
        }
        if `_has_lambda_t' {
            local lambda_time = e(lambda_time)
        }

        preserve
        clear
        quietly {
            set obs `n_dist'
            gen double distance = .
            forvalues i = 1/`n_dist' {
                replace distance = __ed_distances[1, `i'] in `i'
            }
        }

        // ── Figure 1: Distance distribution histogram ──────────────────────
        quietly {
            local med_line = scalar(__ed_p50)
            histogram distance, bins(`bins') ///
                color("24 105 175%60") lcolor("24 105 175") ///
                xtitle("Unit Distance (RMSE)", size(medsmall)) ///
                ytitle("Frequency", size(medsmall)) ///
                title("Distribution of Unit Distances", ///
                    size(medium) position(11)) ///
                xline(`med_line', lcolor(cranberry) lpattern(dash) ///
                    lwidth(medium)) ///
                note("Dashed line = median distance", size(vsmall)) ///
                graphregion(color(white)) plotregion(lcolor(none)) ///
                xsize(6) ysize(3.75) ///
                name(__trop_dist_hist, replace)
        }

        // ── Figure 2: Unit weights vs distance ─────────────────────────────
        if `_has_lambda_u' {
            quietly gen double weight = exp(-`lambda_unit' * distance)

            twoway (scatter weight distance, ///
                    mcolor("24 105 175%70") msymbol(o) msize(small)) ///
                (lowess weight distance, ///
                    lcolor(cranberry) lwidth(medium)), ///
                xtitle("Unit Distance (RMSE)", size(medsmall)) ///
                ytitle("Unit Weight {&omega}", size(medsmall)) ///
                title("Unit Weights vs Distance", ///
                    size(medium) position(11)) ///
                note("{&omega} = exp(-{&lambda}{sub:unit} {&times} d); " ///
                    "{&lambda}{sub:unit} = `lambda_unit'", size(vsmall)) ///
                legend(off) ///
                graphregion(color(white)) plotregion(lcolor(none)) ///
                xsize(6) ysize(3.75) ///
                name(__trop_dist_weight, replace)
        }

        // ── Figure 3: Time weight decay ────────────────────────────────────
        if `_has_lambda_t' {
            // Generate time horizon range from -N_periods/2 to N_periods/2
            local max_h = floor(`N_periods' / 2)
            local n_horizon = 2 * `max_h' + 1

            drop _all
            quietly {
                set obs `n_horizon'
                gen int horizon = _n - `max_h' - 1
                gen double time_weight = exp(-`lambda_time' * abs(horizon))
            }

            twoway (connected time_weight horizon, ///
                    lcolor("24 105 175") mcolor("24 105 175") ///
                    msymbol(O) msize(medsmall) lwidth(medium)), ///
                xtitle("Periods from Treatment", size(medsmall)) ///
                ytitle("Time Weight {&theta}", size(medsmall)) ///
                title("Time Weight Decay", ///
                    size(medium) position(11)) ///
                note("{&theta} = exp(-{&lambda}{sub:time} {&times} |t - t{sub:0}|); " ///
                    "{&lambda}{sub:time} = `lambda_time'", size(vsmall)) ///
                yline(0, lcolor(gs12) lwidth(vthin)) ///
                graphregion(color(white)) plotregion(lcolor(none)) ///
                xsize(6) ysize(3.75) ///
                name(__trop_time_weight, replace)
        }

        // ── Figure 4: Combined panel ───────────────────────────────────────
        local combine_list "__trop_dist_hist"
        if `_has_lambda_u' {
            local combine_list "`combine_list' __trop_dist_weight"
        }
        if `_has_lambda_t' {
            local combine_list "`combine_list' __trop_time_weight"
        }

        local n_graphs : word count `combine_list'
        if `n_graphs' > 1 {
            local cols = cond(`n_graphs' == 3, 2, `n_graphs')
            graph combine `combine_list', ///
                cols(`cols') ///
                title("TROP Weight Diagnostics", size(medium)) ///
                graphregion(color(white)) ///
                xsize(10) ysize(6) ///
                name(_trop_weight_diag, replace)

            // Clean up individual sub-graphs (combined panel kept)
            capture graph drop __trop_dist_hist
            capture graph drop __trop_dist_weight
            capture graph drop __trop_time_weight

            // Save combined graph if requested
            if `"`saving'"' != "" {
                graph export `"`saving'"', replace
            }
        }
        else {
            // Only histogram available: rename to canonical name
            graph rename __trop_dist_hist _trop_weight_diag, replace
            if `"`saving'"' != "" {
                graph export `"`saving'"', replace
            }
        }

        restore
    }

    /* ──────────────────────────────────────────────────────────────────────
       6. Store r() results and clean up
    ────────────────────────────────────────────────────────────────────── */

    return scalar N_pairs = scalar(__ed_N_pairs)
    return scalar mean    = scalar(__ed_mean)
    return scalar sd      = scalar(__ed_sd)
    return scalar min     = scalar(__ed_min)
    return scalar max     = scalar(__ed_max)
    return scalar p25     = scalar(__ed_p25)
    return scalar p50     = scalar(__ed_p50)
    return scalar p75     = scalar(__ed_p75)

    // Clean up temporary scalars and matrices
    capture scalar drop __ed_N_pairs
    capture scalar drop __ed_mean
    capture scalar drop __ed_sd
    capture scalar drop __ed_min
    capture scalar drop __ed_max
    capture scalar drop __ed_p25
    capture scalar drop __ed_p50
    capture scalar drop __ed_p75
    capture matrix drop __ed_distances
end
