*! version 2.0.0  20mar2026  Carlos Gradin
*! Intertemporal poverty measures
*! Reference: Gradin, Del Rio, and Canto (2012), "Measuring Poverty Accounting
*!   for Time", Review of Income and Wealth, 58(2): 330-354.

program define povtime, rclass
    version 11
    syntax [aweight iweight fweight] [if] [in] , ///
        y(string) z(string) t(integer)            ///
        [NONnormalized THao(integer 1)            ///
         Format(string) Gamma(string)             ///
         Beta(string) Alpha(string)               ///
         GENerate(string) decomp]

    marksample touse, novarlist

    * ─── Input validation ─────────────────────────────────────────────────

    if `t' < 1 {
        di as error "t() must be a positive integer"
        exit 198
    }

    if `thao' < 1 | `thao' > `t' {
        di as error "thao() must be between 1 and `t'"
        exit 198
    }

    * Check that y and z variables exist for all periods
    forvalues j = 1/`t' {
        confirm numeric variable `y'`j'
        confirm numeric variable `z'`j'
    }

    * ─── Handle missing values ────────────────────────────────────────────
    * Exclude observations with any missing y or z across all periods

    tempvar missing
    qui gen byte `missing' = 0 if `touse'
    forvalues j = 1/`t' {
        qui replace `missing' = 1 if (`y'`j' >= . | `z'`j' >= .) & `touse'
    }

    qui count if `missing' == 1 & `touse'
    local nmissing = r(N)
    if `nmissing' > 0 {
        qui replace `touse' = 0 if `missing' == 1
    }

    * ─── Set default parameter values ─────────────────────────────────────

    if "`gamma'" == "" local gamma 0 1 2
    if "`alpha'" == "" local alpha 0 1 2
    if "`beta'"  == "" local beta  0 1

    * Store beta values with consecutive indices (beta can be non-integer)
    local nb = 0
    foreach b in `beta' {
        local nb = `nb' + 1
        local Beta`nb' `b'
    }

    * ═══════════════════════════════════════════════════════════════════════
    * STEP 1: Per-period poverty gaps g_it^gamma (Eq. 1 in paper)
    * ═══════════════════════════════════════════════════════════════════════

    forvalues j = 1/`t' {
        * g_j_0 = poverty indicator (0/1); g_j_1 = poverty gap
        tempvar g`j'_0 g`j'_1
        if "`nonnormalized'" != "" {
            qui gen double `g`j'_1' = max(`z'`j' - `y'`j', 0) if `touse'
        }
        else {
            qui gen double `g`j'_1' = max((`z'`j' - `y'`j') / `z'`j', 0) if `touse'
        }
        qui gen byte `g`j'_0' = (`g`j'_1' > 0) if `touse'

        * g_j_gamma = gap^gamma for gamma >= 2
        foreach i in `gamma' {
            if `i' >= 2 {
                tempvar g`j'_`i'
                qui gen double `g`j'_`i'' = `g`j'_1' ^ `i' if `touse'
            }
        }
    }

    * ═══════════════════════════════════════════════════════════════════════
    * STEP 2: Count poor periods (computed directly, independent of gamma/beta)
    * ═══════════════════════════════════════════════════════════════════════

    tempvar npoor
    qui gen int `npoor' = 0 if `touse'
    forvalues j = 1/`t' {
        qui replace `npoor' = `npoor' + `g`j'_0' if `touse'
    }

    * ═══════════════════════════════════════════════════════════════════════
    * STEP 3: Spell identification
    * ═══════════════════════════════════════════════════════════════════════
    * di_j = spell number at period j
    * qi_j = cumulative count of poverty spells through period j

    tempvar di_1 qi_1
    qui gen int `di_1' = 1 if `touse'
    qui gen int `qi_1' = (`g1_0' > 0) if `touse'

    forvalues j = 2/`t' {
        tempvar di_`j' qi_`j'
        local k = `j' - 1
        * New spell starts when poverty status changes
        qui gen int `di_`j'' = `di_`k'' + (`g`j'_0' != `g`k'_0') if `touse'
        * Count poverty spells (only when entering poverty)
        qui gen int `qi_`j'' = `qi_`k'' + (`g`j'_0' != `g`k'_0') * (`g`j'_0' > 0) if `touse'
    }

    * Total number of poverty spells per individual
    tempvar npovspells
    qui gen int `npovspells' = `qi_`t'' if `touse'

    * Average duration of poverty spells (safe division)
    tempvar meandur
    qui gen double `meandur' = cond(`npovspells' > 0, `npoor' / `npovspells', 0) if `touse'

    * ═══════════════════════════════════════════════════════════════════════
    * STEP 4: Spell duration and weights (Eq. 2 weight: w_it = (s_it/T)^beta)
    * ═══════════════════════════════════════════════════════════════════════
    * si_j = relative duration (s/T) of spell j
    * w_b_j = (s_j/T)^beta for each beta value

    forvalues j = 1/`t' {
        tempvar si_`j'
        qui gen double `si_`j'' = 0 if `touse'
        * Count how many periods belong to spell j
        forvalues i = 1/`t' {
            qui replace `si_`j'' = `si_`j'' + 1 if `di_`i'' == `j' & `touse'
        }

        * Convert to relative duration (s/T)
        qui replace `si_`j'' = `si_`j'' / `t' if `touse'

        * Spell weights: w = (s/T)^beta
        forvalues b = 1/`nb' {
            tempvar w_`b'_`j'
            qui gen double `w_`b'_`j'' = `si_`j'' ^ `Beta`b'' if `touse'
        }
    }

    * ─── Period-level weights ─────────────────────────────────────────────
    * wi_b_j = weight for period j = weight of the spell that period j belongs to

    forvalues j = 1/`t' {
        forvalues b = 1/`nb' {
            tempvar wi_`b'_`j'
            qui gen double `wi_`b'_`j'' = 0 if `touse'
        }
        forvalues i = 1/`t' {
            forvalues b = 1/`nb' {
                qui replace `wi_`b'_`j'' = `w_`b'_`i'' if `di_`j'' == `i' & `touse'
            }
        }
    }

    * ═══════════════════════════════════════════════════════════════════════
    * STEP 5: Individual intertemporal poverty indicator (Eq. 2)
    *   pi(gamma, beta) = (1/T) * SUM_t g_it^gamma * w_it(beta)
    * ═══════════════════════════════════════════════════════════════════════

    foreach i in `gamma' {
        forvalues b = 1/`nb' {
            tempvar pi_`i'_`b'
            qui gen double `pi_`i'_`b'' = 0 if `touse'
        }
        * Accumulate weighted gaps across periods
        forvalues j = 1/`t' {
            forvalues b = 1/`nb' {
                qui replace `pi_`i'_`b'' = `pi_`i'_`b'' + `g`j'_`i'' * `wi_`b'_`j'' if `touse'
            }
        }
        * Divide by T and apply chronicity threshold (tau)
        forvalues b = 1/`nb' {
            qui replace `pi_`i'_`b'' = `pi_`i'_`b'' / `t' if `touse'
            * Set pi=0 for individuals poor fewer than thao periods
            qui replace `pi_`i'_`b'' = 0 if `npoor' < `thao' & `touse'
        }
    }

    * ═══════════════════════════════════════════════════════════════════════
    * STEP 6: Aggregate intertemporal poverty P(Y;z) (Eqs. 3-4)
    *   P(gamma, beta, alpha) = (1/N) * SUM pi(gamma,beta)^alpha
    * ═══════════════════════════════════════════════════════════════════════

    foreach i in `gamma' {
        foreach j in `alpha' {
            forvalues b = 1/`nb' {
                tempvar pi_`i'_`b'_`j'
                qui gen double `pi_`i'_`b'_`j'' = 0 if `touse'
                qui replace    `pi_`i'_`b'_`j'' = `pi_`i'_`b'' ^ `j' ///
                    if `pi_`i'_`b'' > 0 & `touse'
            }
        }
    }

    * Store P values for display
    tempvar _alpha _gamma _beta P
    qui gen double `P' = .
    qui gen `_alpha' = .
    qui gen `_gamma' = .
    qui gen `_beta'  = .

    local k = 1
    foreach i in `gamma' {
        foreach j in `alpha' {
            forvalues b = 1/`nb' {
                qui sum `pi_`i'_`b'_`j'' [`weight' `exp'] if `touse'
                qui replace `P'      = r(mean) if _n == `k'
                qui replace `_gamma' = `i'     if _n == `k'
                qui replace `_alpha' = `j'     if _n == `k'
                qui replace `_beta'  = `b'     if _n == `k'
                local k = `k' + 1
            }
        }
    }

    * ─── Headcount ratio H (computed directly, not from P[1]) ─────────────

    tempvar _ispoor
    qui gen byte `_ispoor' = (`npoor' >= `thao') if `touse'
    qui sum `_ispoor' [`weight' `exp'] if `touse'
    local H_val = r(mean)

    * ═══════════════════════════════════════════════════════════════════════
    * STEP 7: Decomposition (Eq. 5): P = H * I^alpha * (1 + Ep)
    * ═══════════════════════════════════════════════════════════════════════

    if "`decomp'" != "" {
        tempvar H I V CV2 Ep
        qui gen double `H'   = `H_val'
        qui gen double `I'   = .
        qui gen double `V'   = .
        qui gen double `CV2' = .
        qui gen double `Ep'  = .

        local k = 1
        foreach i in `gamma' {
            foreach j in `alpha' {
                forvalues b = 1/`nb' {
                    * Intensity: mean of pi among the intertemporally poor
                    qui sum `pi_`i'_`b'' [`weight' `exp'] if `touse' & `pi_`i'_`b'' > 0
                    local I_local = r(mean)
                    local V_local = r(Var)
                    qui replace `I' = `I_local' if _n == `k'

                    * Alternative decomposition for alpha=2, normalized gaps
                    * P = H * [I^2 + V(p)], V(p) = CV2(1-p) * (1-I)^2
                    if `j' == 2 & "`nonnormalized'" == "" {
                        qui replace `V'   = `V_local'                     if _n == `k'
                        qui replace `CV2' = `V_local' / (1 - `I_local')^2 if _n == `k'
                    }

                    * Inequality among the poor: Ep
                    if `j' > 0 & `I_local' > 0 {
                        tempvar ppi_`i'_`b'_`j'
                        qui gen double `ppi_`i'_`b'_`j'' = ///
                            (`pi_`i'_`b'' / `I_local') ^ `j' - 1 if `touse'
                        qui sum `ppi_`i'_`b'_`j'' [`weight' `exp'] ///
                            if `touse' & `pi_`i'_`b'' > 0
                        qui replace `Ep' = max(r(mean), 0) if _n == `k'
                    }
                    else {
                        qui replace `Ep' = 0 if _n == `k'
                    }

                    local k = `k' + 1
                }
            }
        }
    }

    * ═══════════════════════════════════════════════════════════════════════
    * STEP 8: Save individual poverty indicators if requested
    * ═══════════════════════════════════════════════════════════════════════

    if "`generate'" != "" {
        cap drop `generate'_*
        foreach i in `gamma' {
            forvalues b = 1/`nb' {
                qui gen `generate'_`i'_`b' = `pi_`i'_`b'' if `touse'
                lab var `generate'_`i'_`b' ///
                    "Individual poverty indicator (gamma=`i', beta=`Beta`b'')"
            }
        }
    }

    * ═══════════════════════════════════════════════════════════════════════
    * STEP 9: Display results
    * ═══════════════════════════════════════════════════════════════════════

    if "`format'" == "" local format "%9.4f"

    * Value labels for parameters
    lab var `_alpha' "alpha (a)"
    lab var `_gamma' "gamma (g)"
    lab var `_beta'  "beta (b)"

    lab def `_beta'  -1 ""
    lab def `_alpha' -1 ""
    lab def `_gamma' -1 ""

    foreach j in `alpha' {
        lab def `_alpha' `j' "a=`j'", add
    }
    foreach i in `gamma' {
        lab def `_gamma' `i' "g=`i'", add
    }
    local bk = 0
    foreach b in `beta' {
        local bk = `bk' + 1
        lab def `_beta' `bk' "b=`b'", add
    }

    lab val `_alpha' `_alpha'
    lab val `_beta'  `_beta'
    lab val `_gamma' `_gamma'

    * ─── Header ───────────────────────────────────────────────────────────

    di ""
    di as text "{hline 100}"
    di ""
    di as result "Aggregate Intertemporal Poverty Measure, P(Y;z)"
    di ""
    di as text "Reference: Gradin, C., Del Rio, C., and Canto, O. (2012)"
    di as text "  Measuring Poverty Accounting for Time, Review of Income and Wealth, 58(2): 330-354."
    di ""
    di as text "Number of periods (T) = " as result `t'
    if "`nonnormalized'" == "" {
        di as text "Poverty gaps:" as result " normalized" as text " [(z-y)/z]"
    }
    else {
        di as text "Poverty gaps:" as result " non-normalized" as text " [z-y]"
    }
    di as text "Chronicity threshold (tau) = " as result `thao' ///
        as text " out of " as result `t' as text " periods"
    di as text "(individuals poor at least " as result `thao' ///
        as text " out of " as result `t' as text " periods are intertemporally poor)"
    di ""

    * ─── Descriptive statistics ───────────────────────────────────────────

    di as text "Intertemporally poor: " as result %9.2f `H_val' * 100 "%" ///
        as text " of the population"
    di ""

    lab var `npoor' "Number of periods below the poverty line"
    tab `npoor' [`weight' `exp'] if `touse'
    lab var `npovspells' "Number of poverty spells"
    tab `npovspells' [`weight' `exp'] if `touse'
    di as text "(poverty spell = 1 or more consecutive periods below the poverty line)"
    di ""

    di as text "Among the intertemporally poor:"
    tempname sc_npoor sc_npovspells sc_meandur
    qui sum `npoor' [`weight' `exp'] if `npoor' >= `thao' & `touse'
    scalar `sc_npoor' = r(mean)
    di as text "  - Average number of periods below the poverty line = " ///
        as result `format' r(mean)
    qui sum `npovspells' [`weight' `exp'] if `npoor' >= `thao' & `touse'
    scalar `sc_npovspells' = r(mean)
    di as text "  - Average number of poverty spells                = " ///
        as result `format' r(mean)
    qui sum `meandur' [`weight' `exp'] if `npoor' >= `thao' & `touse'
    scalar `sc_meandur' = r(mean)
    di as text "  - Average duration of poverty spells              = " ///
        as result `format' r(mean)
    di ""

    * ─── P(Y;z) table ────────────────────────────────────────────────────

    di as result "Aggregate Intertemporal Poverty, P(Y;z)"

    if `nmissing' > 0 {
        di ""
        di as text "Note: `y'/`z' variables contain " as result `nmissing' ///
            as text " observations with missings, excluded from calculations"
        di ""
    }

    tabdisp `_alpha' `_gamma' `_beta' if `P' != ., ///
        c(`P') f(`format') concise stubwidth(10) csepwidth(1)

    di ""
    di as text "Parameters:"
    di as text "  gamma = sensitivity to variability of per-period poverty gaps across time"
    di as text "  beta  = sensitivity to duration of poverty spells"
    di as text "  alpha = sensitivity to inequality of intertemporal poverty among the poor"

    * ─── Decomposition display ────────────────────────────────────────────

    if "`decomp'" != "" {
        di ""
        di as result "Decomposition (Eq. 5): P(Y;z) = H * I^a * [1 + Ep]"
        tabdisp `_alpha' `_gamma' `_beta' if `P' != ., ///
            c(`H' `I' `Ep') f(`format') concise stubwidth(10) csepwidth(1)
        di as text "  H  = headcount ratio (proportion intertemporally poor)"
        di as text "  I  = intensity (mean individual poverty indicator among the poor)"
        di as text "  Ep = inequality of poverty among the poor (relevant for alpha > 1)"
    }

    if "`decomp'" != "" & "`nonnormalized'" == "" {
        di ""
        di as result "Alternative decomposition for alpha=2: P(Y;z) = H * [I^2 + V(p)]"
        di as text "  equivalently: P(Y;z) = H * I^2 * [1 + CV2(1-p) * (1-I)^2]"
        di ""
        tabdisp `_gamma' `_beta' if `P' != . & `_alpha' == 2, ///
            c(`H' `I' `CV2' `V') f(`format') concise stubwidth(10) csepwidth(1)
        di as text "  CV2(1-p) = squared coefficient of variation of (1-p) among the poor"
        di as text "  V(p)     = variance of individual poverty indicators among the poor"
    }

    di ""
    di as text "{hline 100}"

    * ═══════════════════════════════════════════════════════════════════════
    * STEP 10: Saved results
    * ═══════════════════════════════════════════════════════════════════════

    * Scalars: P(gamma, beta_order, alpha) for each combination
    local k = 1
    foreach i in `gamma' {
        foreach j in `alpha' {
            forvalues b = 1/`nb' {
                tempname P_`i'_`b'_`j'
                scalar `P_`i'_`b'_`j'' = `P'[`k']
                return scalar P_`i'_`b'_`j' = `P_`i'_`b'_`j''
                local k = `k' + 1
            }
        }
    }

    return scalar everpoor   = `H_val' * 100
    return scalar npoor      = `sc_npoor'
    return scalar npovspells = `sc_npovspells'
    return scalar meandur    = `sc_meandur'

    * Replace beta order numbers with actual beta values for matrix output
    local r = 1
    foreach b in `beta' {
        qui replace `_beta' = `b' if `_beta' == `r'
        local r = `r' + 1
    }

    * Matrix: all poverty indices
    mkmat `_gamma' `_beta' `_alpha' `P' if `P' != ., mat(`P')
    mat colnames `P' = gamma beta alpha P

    if "`decomp'" != "" {
        tempname dec dec2
        mkmat `H' `I' `Ep' if `P' != ., mat(`dec')
        mat colnames `dec' = H I Ep
        mat `P' = `P', `dec'

        if "`nonnormalized'" == "" {
            mkmat `_gamma' `_beta' `_alpha' `P' `H' `I' `CV2' `V' ///
                if `P' != . & `_alpha' == 2, mat(`dec2')
            mat colnames `dec2' = gamma beta alpha P H I CV2 V
            return matrix dec2 = `dec2'
        }
    }
    return matrix pov = `P'

end
