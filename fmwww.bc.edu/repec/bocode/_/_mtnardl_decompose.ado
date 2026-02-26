*! _mtnardl_decompose — Quantile Threshold Decomposition for MTNARDL
*! Version 1.0.0 — 2026-02-24
*! Implements Pal & Mitra (2016) multiple threshold decomposition
*! Decomposes Δx into quantile-based partial sums

capture program drop _mtnardl_decompose
program define _mtnardl_decompose, rclass
    version 17

    syntax, depvar(string) decompose(string) partition(string) ///
        [cutpoints(numlist) savedecomp nograph]

    // =========================================================================
    // 1. DETERMINE QUANTILE CUTPOINTS
    // =========================================================================
    local partition = lower("`partition'")

    if "`partition'" == "quartile" {
        local nq = 4
        local pctiles "25 50 75"
        local partition_label "Quartile (4 regimes)"
    }
    else if "`partition'" == "quintile" {
        local nq = 5
        local pctiles "20 40 60 80"
        local partition_label "Quintile (5 regimes)"
    }
    else if "`partition'" == "decile" {
        local nq = 10
        local pctiles "10 20 30 40 50 60 70 80 90"
        local partition_label "Decile (10 regimes)"
    }
    else if "`partition'" == "percentile" {
        local nq = 20
        local pctiles "5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95"
        local partition_label "Percentile (20 regimes)"
    }
    else if "`partition'" == "custom" {
        if "`cutpoints'" == "" {
            di as err "custom partition requires cutpoints() option"
            exit 198
        }
        // Count cutpoints to determine nq
        local ncuts : word count `cutpoints'
        local nq = `ncuts' + 1
        local partition_label "Custom (`nq' regimes)"
    }
    else {
        di as err "partition() must be quartile, quintile, decile, percentile, or custom"
        exit 198
    }

    // =========================================================================
    // 2. DECOMPOSE EACH VARIABLE
    // =========================================================================
    local all_decomp_vars ""
    local decomp_info ""

    foreach xvar of local decompose {
        local cname = subinstr("`xvar'", ".", "_", .)

        // --- Compute first difference ---
        tempvar dx_`cname'
        qui gen double `dx_`cname'' = D.`xvar'

        // --- Compute quantile thresholds from the empirical distribution ---
        if "`partition'" != "custom" {
            // Get percentile values from the distribution of Δx
            qui sum `dx_`cname'', detail
            local cp_list ""
            foreach pct of local pctiles {
                // Use centile for precise percentile estimation
                qui centile `dx_`cname'', centile(`pct')
                local cp_`pct' = r(c_1)
                local cp_list "`cp_list' `cp_`pct''"
            }
        }
        else {
            // Custom cutpoints provided directly
            local cp_list "`cutpoints'"
        }

        // --- Display decomposition info ---
        di as txt ""
        di as txt "  {bf:Decomposition of `xvar'} — `partition_label'"
        di as txt "  {hline 68}"
        di as txt _col(5) "Regime" _col(18) "Range" _col(48) "N obs" _col(58) "% of total"
        di as txt "  {hline 68}"

        // Get actual min/max for display (instead of -inf/+inf)
        qui sum `dx_`cname''
        local dx_min = r(min)
        local dx_max = r(max)

        // --- Create partial sums for each quantile bin ---
        local ncuts : word count `cp_list'

        forvalues q = 1/`nq' {
            // Determine bin boundaries
            if `q' == 1 {
                // First bin: [min, cp_1]
                local cp_upper : word 1 of `cp_list'
                local range_str "[`: di %8.4f `dx_min'', `: di %8.4f `cp_upper'']"

                tempvar bin_`cname'_`q'
                qui gen double `bin_`cname'_`q'' = `dx_`cname'' * (`dx_`cname'' <= `cp_upper') ///
                    if !missing(`dx_`cname'')
            }
            else if `q' == `nq' {
                // Last bin: (cp_last, max]
                local cp_lower : word `ncuts' of `cp_list'
                local range_str "(`: di %8.4f `cp_lower'', `: di %8.4f `dx_max'']"

                tempvar bin_`cname'_`q'
                qui gen double `bin_`cname'_`q'' = `dx_`cname'' * (`dx_`cname'' > `cp_lower') ///
                    if !missing(`dx_`cname'')
            }
            else {
                // Interior bin: (cp_{q-1}, cp_q]
                local qm1 = `q' - 1
                local cp_lower : word `qm1' of `cp_list'
                local cp_upper : word `q' of `cp_list'
                if `q' <= `ncuts' {
                    local cp_upper : word `q' of `cp_list'
                }
                else {
                    // Should not happen, but safety
                    local cp_upper = .
                }
                local range_str "(`: di %8.4f `cp_lower'', `: di %8.4f `cp_upper'']"

                tempvar bin_`cname'_`q'
                qui gen double `bin_`cname'_`q'' = `dx_`cname'' * ///
                    (`dx_`cname'' > `cp_lower' & `dx_`cname'' <= `cp_upper') ///
                    if !missing(`dx_`cname'')
            }

            // Replace missing with 0 for cumulation
            qui replace `bin_`cname'_`q'' = 0 if missing(`bin_`cname'_`q'')

            // Create cumulative partial sum
            local psname "_mt_`cname'_q`q'"
            capture drop `psname'
            qui gen double `psname' = sum(`bin_`cname'_`q'')

            // Count observations in this bin
            qui count if `dx_`cname'' != 0 & !missing(`dx_`cname'')
            local total_nonzero = r(N)
            if `q' == 1 {
                qui count if `dx_`cname'' <= `cp_upper' & !missing(`dx_`cname'')
            }
            else if `q' == `nq' {
                qui count if `dx_`cname'' > `cp_lower' & !missing(`dx_`cname'')
            }
            else {
                qui count if `dx_`cname'' > `cp_lower' & `dx_`cname'' <= `cp_upper' & !missing(`dx_`cname'')
            }
            local nobs_q = r(N)
            qui count if !missing(`dx_`cname'')
            local total_obs = r(N)
            local pct_q = 100 * `nobs_q' / `total_obs'

            // Display row
            di as txt _col(5) "Q`q'" _col(18) "`range_str'" ///
               _col(48) as res %5.0f `nobs_q' _col(58) %5.1f `pct_q' "%"

            local all_decomp_vars "`all_decomp_vars' `psname'"
        }

        di as txt "  {hline 68}"

        // --- Verify decomposition identity ---
        // Sum of all partial sums at final obs should equal cumulative Δx
        tempvar check_sum
        qui gen double `check_sum' = 0
        forvalues q = 1/`nq' {
            local psname "_mt_`cname'_q`q'"
            qui replace `check_sum' = `check_sum' + `psname'
        }
        tempvar cum_dx
        qui gen double `cum_dx' = sum(`dx_`cname'')
        qui sum `check_sum'
        local cs_last = r(max)
        qui sum `cum_dx'
        local cd_last = r(max)
        local decomp_err = abs(`cs_last' - `cd_last')
        if `decomp_err' < 1e-6 {
            di as res _col(5) "Decomposition identity verified (error = " %12.2e `decomp_err' ")"
        }
        else {
            di as err _col(5) "WARNING: Decomposition error = " %12.6f `decomp_err'
        }
        di as txt ""
    }

    // =========================================================================
    // 3. GRAPH: DECOMPOSED SERIES VISUALIZATION
    // =========================================================================
    if "`nograph'" == "" {
        // Get timevar first
        qui tsset
        local timevar "`r(timevar)'"

        foreach xvar of local decompose {
            local cname = subinstr("`xvar'", ".", "_", .)

            // Professional color palette (vibrant, distinct)
            local colors `""33 150 243" "76 175 80" "255 152 0" "244 67 54" "156 39 176" "0 188 212" "255 235 59" "121 85 72" "63 81 181" "233 30 99" "0 150 136" "255 87 34" "103 58 183" "205 220 57" "96 125 139" "183 28 28" "27 94 32" "230 81 0" "49 27 146" "0 96 100""'

            // Build twoway plot command with distinct colors per regime
            local tw_cmd ""
            local legend_order ""
            forvalues q = 1/`nq' {
                local psname "_mt_`cname'_q`q'"
                local cidx = mod(`q' - 1, 20) + 1
                local this_color : word `cidx' of `colors'

                local tw_cmd `"`tw_cmd' (line `psname' `timevar', lcolor("`this_color'") lwidth(medium))"'
                local legend_order `"`legend_order' `q' "Q`q'""'
            }

            capture noisily {
                twoway `tw_cmd', ///
                    title("{bf:MTNARDL Decomposition — `xvar'}", ///
                        size(medlarge) color("24 54 104")) ///
                    subtitle("`partition_label' partial sums", ///
                        size(small) color(gs6)) ///
                    xtitle("Time", size(medsmall)) ///
                    ytitle("Cumulative Partial Sum", size(medsmall)) ///
                    legend(order(`legend_order') size(vsmall) cols(5) ///
                        ring(0) pos(6) region(fcolor(white%80) lcolor(gs12))) ///
                    graphregion(fcolor(white) lcolor(white)) ///
                    plotregion(fcolor(white) lcolor(gs14)) ///
                    ylabel(, format(%8.3f) labsize(small) angle(0) grid glcolor(gs14%50)) ///
                    xlabel(, labsize(small) grid glcolor(gs14%50)) ///
                    note("Pal & Mitra (2016) quantile decomposition", ///
                        size(vsmall) color(gs8)) ///
                    scheme(s2color) name(decomp_`cname', replace)

                qui graph export "mtnardl_decomp_`cname'.png", replace width(1600)
                di as txt _col(5) "Graph saved: mtnardl_decomp_`cname'.png"
            }
        }
    }

    // =========================================================================
    // 4. RETURN RESULTS
    // =========================================================================
    return local decomp_vars "`all_decomp_vars'"
    return local partition "`partition'"
    return local partition_label "`partition_label'"
    return scalar nq = `nq'

end
