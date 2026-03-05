*! aardl_advanced — Post-estimation advanced analysis for aardl
*! Version 1.2.0 — 2026-03-04
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Independent Researcher
*!
*! Usage:
*!   aardl ..., noadvanced          // suppress during estimation
*!   aardl_advanced                 // run advanced analysis separately
*!   aardl_advanced, horizon(30)    // with custom horizon

capture program drop aardl_advanced
program define aardl_advanced
    version 17

    syntax [, HORizon(integer -1) NOGraph]

    // ─── Validate that aardl was run ───
    if "`e(cmd)'" != "aardl" {
        di as err "{bf:aardl_advanced} requires a prior {bf:aardl} estimation"
        di as err "Run {bf:aardl} first, then use {bf:aardl_advanced} for post-estimation analysis."
        exit 301
    }

    // ─── Read stored results from aardl ───
    local depvar       "`e(depvar)'"
    local coint_status "`e(coint_status)'"
    local kstar        = e(kstar)
    local level        = c(level)
    local model_type   "`e(type)'"
    local decompose    "`e(decompose)'"

    // Use stored horizon if user did not override
    if `horizon' == -1 {
        capture local horizon = e(horizon)
        if `horizon' == . | `horizon' < 1 local horizon = 20
    }

    // ─── Extract coefficients from e(b) matrix ───
    tempname bb
    mat `bb' = e(b)
    local ncols = colsof(`bb')
    local cnames : coleq `bb'
    local colnames : colnames `bb'

    // ECM coefficient = first coefficient (ADJ equation: L.depvar)
    local ecm_coef = `bb'[1, 1]

    // ─── Extract LR coefficients and variable names ───
    local lr_vars ""
    local lr_coefs ""
    forvalues j = 1/`ncols' {
        local eq : word `j' of `cnames'
        if "`eq'" == "LR" {
            local vname : word `j' of `colnames'
            local lr_vars "`lr_vars' `vname'"
            local lr_coefs "`lr_coefs' `=`bb'[1, `j']'"
        }
    }

    // ─── Extract SR coefficients (D. prefix) for impact multipliers ───
    local sr_vars ""
    local sr_coefs ""
    forvalues j = 1/`ncols' {
        local eq : word `j' of `cnames'
        local vname : word `j' of `colnames'
        if "`eq'" == "SR" {
            // Only first-difference terms (D. prefix), not lagged diffs or _cons
            if substr("`vname'", 1, 2) == "D." | substr("`vname'", 1, 3) == "D1." {
                local sr_vars "`sr_vars' `vname'"
                local sr_coefs "`sr_coefs' `=`bb'[1, `j']'"
            }
        }
    }

    // ─── Detect if NARDL model ───
    local is_nardl = 0
    if "`model_type'" == "nardl" | "`model_type'" == "fanardl" | ///
       "`model_type'" == "banardl" | "`model_type'" == "fbanardl" {
        local is_nardl = 1
    }

    // ─── Info header ───
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Post-estimation: Advanced Analysis"
    di as txt "{hline 78}"

    if "`coint_status'" != "cointegrated" {
        di as txt ""
        di as txt _col(5) "{it:Note: Cointegration was not detected in the prior estimation.}"
        di as txt _col(5) "{it:Results below should be interpreted with caution.}"
        di as txt ""
    }

    // =========================================================================
    // 1. DYNAMIC MULTIPLIERS
    // =========================================================================
    local alpha = `ecm_coef'

    if `is_nardl' & "`decompose'" != "" {
        // ─── NARDL: Asymmetric Dynamic Multipliers ───
        di as txt _col(5) "{bf:Table 5: Asymmetric Dynamic Multipliers}"
        di as txt _col(5) "{it:Shin, Yu & Greenwood-Nimmo (2014)}"
        di as txt ""

        foreach cname of local decompose {
            // Find LR multipliers for positive and negative components
            local lr_pos = 0
            local lr_neg = 0
            local nw_lr : word count `lr_vars'
            forvalues i = 1/`nw_lr' {
                local v : word `i' of `lr_vars'
                local c : word `i' of `lr_coefs'
                // Remove L. prefix for matching
                local vclean = subinstr("`v'", "L.", "", 1)
                if "`vclean'" == "`cname'_pos" local lr_pos = `c'
                if "`vclean'" == "`cname'_neg" local lr_neg = `c'
            }

            // Find impact multipliers for positive and negative
            local theta0_pos = 0
            local theta0_neg = 0
            local nw_sr : word count `sr_vars'
            forvalues i = 1/`nw_sr' {
                local v : word `i' of `sr_vars'
                local c : word `i' of `sr_coefs'
                // Check for D.cname_pos or D1.cname_pos
                if "`v'" == "D.`cname'_pos" | "`v'" == "D1.`cname'_pos" local theta0_pos = `c'
                if "`v'" == "D.`cname'_neg" | "`v'" == "D1.`cname'_neg" local theta0_neg = `c'
            }

            di as txt _col(5) "Variable: `cname'"
            di as txt _col(7) "Positive LR multiplier = " as res %10.6f `lr_pos'
            di as txt _col(7) "Negative LR multiplier = " as res %10.6f `lr_neg'

            // Compute asymmetric multiplier paths
            tempname dm_pos dm_neg
            mat `dm_pos' = J(`horizon' + 1, 3, .)
            mat `dm_neg' = J(`horizon' + 1, 3, .)

            // h=0
            mat `dm_pos'[1, 1] = 0
            mat `dm_pos'[1, 2] = `theta0_pos'
            mat `dm_pos'[1, 3] = `theta0_pos'

            mat `dm_neg'[1, 1] = 0
            mat `dm_neg'[1, 2] = `theta0_neg'
            mat `dm_neg'[1, 3] = `theta0_neg'

            forvalues h = 1/`horizon' {
                // Positive path
                local prev_cum_p = el(`dm_pos', `h', 3)
                local this_dm_p = `alpha' * (`prev_cum_p' - `lr_pos')
                local this_cum_p = `prev_cum_p' + `this_dm_p'
                mat `dm_pos'[`h' + 1, 1] = `h'
                mat `dm_pos'[`h' + 1, 2] = `this_dm_p'
                mat `dm_pos'[`h' + 1, 3] = `this_cum_p'

                // Negative path
                local prev_cum_n = el(`dm_neg', `h', 3)
                local this_dm_n = `alpha' * (`prev_cum_n' - `lr_neg')
                local this_cum_n = `prev_cum_n' + `this_dm_n'
                mat `dm_neg'[`h' + 1, 1] = `h'
                mat `dm_neg'[`h' + 1, 2] = `this_dm_n'
                mat `dm_neg'[`h' + 1, 3] = `this_cum_n'
            }

            // Display
            di as txt ""
            di as txt _col(7) "h" _col(15) "Cum (+)" _col(30) "Cum (-)" _col(45) "Difference"
            di as txt _col(7) "{hline 45}"
            forvalues h = 0/`horizon' {
                if `h' <= 5 | `h' == `horizon' {
                    local cp = el(`dm_pos', `h' + 1, 3)
                    local cn = el(`dm_neg', `h' + 1, 3)
                    local diff = `cp' - `cn'
                    di as txt _col(7) %3.0f `h' ///
                       _col(13) as res %12.6f `cp' ///
                       _col(28) %12.6f `cn' ///
                       _col(43) %12.6f `diff'
                }
                else if `h' == 6 {
                    di as txt _col(7) "..."
                }
            }
            di as txt ""

            // Graph
            if "`nograph'" == "" {
                mat _aardl_dmp_`cname' = `dm_pos'
                mat _aardl_dmn_`cname' = `dm_neg'
                tempfile _ndm_tmpdata
                qui save `_ndm_tmpdata', replace

                capture noisily {
                    qui clear
                    local nrows = `horizon' + 1
                    qui set obs `nrows'
                    qui gen h = .
                    qui gen cum_pos = .
                    qui gen cum_neg = .
                    qui gen lr_pos_line = `lr_pos'
                    qui gen lr_neg_line = `lr_neg'

                    forvalues i = 1/`nrows' {
                        qui replace h = el(_aardl_dmp_`cname', `i', 1) in `i'
                        qui replace cum_pos = el(_aardl_dmp_`cname', `i', 3) in `i'
                        qui replace cum_neg = el(_aardl_dmn_`cname', `i', 3) in `i'
                    }

                    twoway (connected cum_pos h, lcolor("31 119 180") mcolor("31 119 180") ///
                            msize(small) lwidth(medthick)) ///
                           (connected cum_neg h, lcolor("214 39 40") mcolor("214 39 40") ///
                            msize(small) lwidth(medthick)) ///
                           (line lr_pos_line h, lcolor("31 119 180") lpattern(dash) lwidth(thin)) ///
                           (line lr_neg_line h, lcolor("214 39 40") lpattern(dash) lwidth(thin)), ///
                           title("Asymmetric Dynamic Multipliers: `cname'", size(medium)) ///
                           subtitle("Shin, Yu & Greenwood-Nimmo (2014)", size(small)) ///
                           ytitle("Cumulative Effect", size(small)) ///
                           xtitle("Horizon", size(small)) ///
                           legend(order(1 "Positive shock" 2 "Negative shock" ///
                                  3 "LR (+)" 4 "LR (-)") size(small) rows(1)) ///
                           scheme(s2color) name(aardl_asym_`cname', replace)
                }

                qui use `_ndm_tmpdata', clear
                capture mat drop _aardl_dmp_`cname'
                capture mat drop _aardl_dmn_`cname'
            }
        }
    }
    else {
        // ─── Linear ARDL: Dynamic Multipliers ───
        di as txt _col(5) "{bf:Table 5: Dynamic Multipliers}"
        di as txt ""

        // Get unique independent variable names from LR equation
        local nw_lr : word count `lr_vars'
        forvalues i = 1/`nw_lr' {
            local v : word `i' of `lr_vars'
            local c_lr : word `i' of `lr_coefs'
            // Clean name: remove L. prefix
            local vclean = subinstr("`v'", "L.", "", 1)

            // LR multiplier is already in e(b) LR equation
            local lr_mult = `c_lr'

            // Find impact multiplier from SR equation
            local theta0 = 0
            local nw_sr : word count `sr_vars'
            forvalues k = 1/`nw_sr' {
                local sv : word `k' of `sr_vars'
                local sc : word `k' of `sr_coefs'
                if "`sv'" == "D.`vclean'" | "`sv'" == "D1.`vclean'" local theta0 = `sc'
            }

            di as txt _col(5) "Variable: `vclean'"
            di as txt _col(7) "Impact multiplier   = " as res %10.6f `theta0'
            di as txt _col(7) "Long-run multiplier = " as res %10.6f `lr_mult'

            // Compute dynamic multiplier path
            tempname dm_mat
            mat `dm_mat' = J(`horizon' + 1, 3, .)

            mat `dm_mat'[1, 1] = 0
            mat `dm_mat'[1, 2] = `theta0'
            mat `dm_mat'[1, 3] = `theta0'

            forvalues h = 1/`horizon' {
                local prev_cum = el(`dm_mat', `h', 3)
                local this_dm = `alpha' * (`prev_cum' - `lr_mult')
                local this_cum = `prev_cum' + `this_dm'
                mat `dm_mat'[`h' + 1, 1] = `h'
                mat `dm_mat'[`h' + 1, 2] = `this_dm'
                mat `dm_mat'[`h' + 1, 3] = `this_cum'
            }

            // Display
            di as txt ""
            di as txt _col(7) "h" _col(15) "Dynamic" _col(30) "Cumulative"
            di as txt _col(7) "{hline 35}"
            forvalues h = 0/`horizon' {
                if `h' <= 5 | `h' == `horizon' {
                    di as txt _col(7) %3.0f el(`dm_mat', `h' + 1, 1) ///
                       _col(13) as res %12.6f el(`dm_mat', `h' + 1, 2) ///
                       _col(28) %12.6f el(`dm_mat', `h' + 1, 3)
                }
                else if `h' == 6 {
                    di as txt _col(7) "..."
                }
            }
            di as txt ""

            // Graph
            if "`nograph'" == "" {
                local cname = subinstr("`vclean'", ".", "_", .)
                mat _aardl_dm_`cname' = `dm_mat'
                tempfile _dm_tmpdata
                qui save `_dm_tmpdata', replace

                capture noisily {
                    qui clear
                    local nrows = `horizon' + 1
                    qui set obs `nrows'
                    qui gen h = .
                    qui gen dm = .
                    qui gen cumm = .
                    qui gen lr = `lr_mult'

                    forvalues i = 1/`nrows' {
                        qui replace h = el(_aardl_dm_`cname', `i', 1) in `i'
                        qui replace dm = el(_aardl_dm_`cname', `i', 2) in `i'
                        qui replace cumm = el(_aardl_dm_`cname', `i', 3) in `i'
                    }

                    twoway (connected cumm h, lcolor("31 119 180") mcolor("31 119 180") ///
                            msize(small) lwidth(medthick)) ///
                           (line lr h, lcolor("214 39 40") lpattern(dash) lwidth(medium)), ///
                           title("Cumulative Dynamic Multiplier: `vclean'", size(medium)) ///
                           ytitle("Cumulative Effect", size(small)) ///
                           xtitle("Horizon", size(small)) ///
                           legend(order(1 "Cumulative Multiplier" 2 "Long-run Equilibrium") ///
                                  size(small) rows(1)) ///
                           scheme(s2color) name(aardl_dm_`cname', replace)
                }

                qui use `_dm_tmpdata', clear
                capture mat drop _aardl_dm_`cname'
            }
        }
    }

    // =========================================================================
    // 2. HALF-LIFE ANALYSIS
    // =========================================================================
    di as txt _col(5) "{bf:Half-Life Analysis}"
    if `alpha' < 0 & `alpha' > -1 {
        local halflife = -ln(2) / ln(1 + `alpha')
        di as txt _col(7) "ECM coefficient (alpha)  = " as res %10.6f `alpha'
        di as txt _col(7) "Half-life (periods)      = " as res %10.4f `halflife'
    }
    else {
        di as txt _col(7) "ECM coefficient (alpha)  = " as res %10.6f `alpha'
        di as txt _col(7) "Half-life: " as err "not computable (alpha not in (-1, 0))"
    }
    di as txt ""

    // =========================================================================
    // 3. PERSISTENCE PROFILE
    // =========================================================================
    di as txt _col(5) "{bf:Persistence Profile}"
    di as txt ""

    if `alpha' < 0 & `alpha' > -2 {
        tempname pp_mat
        mat `pp_mat' = J(`horizon' + 1, 2, .)

        forvalues h = 0/`horizon' {
            local pp = (1 + `alpha')^`h'
            mat `pp_mat'[`h' + 1, 1] = `h'
            mat `pp_mat'[`h' + 1, 2] = `pp'
        }

        di as txt _col(7) "h" _col(20) "Persistence"
        di as txt _col(7) "{hline 25}"
        forvalues h = 0/`horizon' {
            if `h' <= 5 | `h' == 10 | `h' == `horizon' {
                di as txt _col(7) %3.0f `h' _col(18) as res %10.6f el(`pp_mat', `h' + 1, 2)
            }
            else if `h' == 6 {
                di as txt _col(7) "..."
            }
        }
        di as txt ""

        // Graph
        if "`nograph'" == "" {
            mat _aardl_pp = `pp_mat'
            tempfile _pp_tmpdata
            qui save `_pp_tmpdata', replace

            capture noisily {
                qui clear
                local nrows = `horizon' + 1
                qui set obs `nrows'
                qui gen h = .
                qui gen pp = .

                forvalues i = 1/`nrows' {
                    qui replace h = el(_aardl_pp, `i', 1) in `i'
                    qui replace pp = el(_aardl_pp, `i', 2) in `i'
                }

                twoway (connected pp h, lcolor("44 160 44") mcolor("44 160 44") ///
                        msize(small) lwidth(medthick)) ///
                       (scatteri 0.5 0 0.5 `horizon', recast(line) lcolor("128 128 128") ///
                        lpattern(dash) lwidth(thin)), ///
                       title("Persistence Profile", size(medium)) ///
                       ytitle("Persistence", size(small)) ///
                       xtitle("Horizon", size(small)) ///
                       legend(order(1 "Persistence" 2 "Half-life") ///
                              size(small) rows(1)) ///
                       scheme(s2color) name(aardl_persistence, replace)
            }

            qui use `_pp_tmpdata', clear
            capture mat drop _aardl_pp
        }
    }

    // =========================================================================
    // 4. FOURIER SIGNIFICANCE TEST (if applicable)
    // =========================================================================
    if `kstar' > 0 {
        di as txt _col(5) "{bf:Fourier Terms Joint Significance}"
        di as txt ""

        // Find column indices for sin and cos
        local sin_idx = 0
        local cos_idx = 0
        forvalues j = 1/`ncols' {
            local vname : word `j' of `colnames'
            if "`vname'" == "_aardl_sin" local sin_idx = `j'
            if "`vname'" == "_aardl_cos" local cos_idx = `j'
        }

        if `sin_idx' > 0 & `cos_idx' > 0 {
            local sin_coef = `bb'[1, `sin_idx']
            local cos_coef = `bb'[1, `cos_idx']

            // Wald F-test: H0: β_sin = β_cos = 0
            // F = (R*β)' * inv(R*V*R') * (R*β) / q,  q = 2
            tempname VV RbetA subV subV_inv wald_mat
            mat `VV' = e(V)
            // Extract 2x2 submatrix of V for sin and cos
            mat `subV' = J(2, 2, .)
            mat `subV'[1, 1] = `VV'[`sin_idx', `sin_idx']
            mat `subV'[1, 2] = `VV'[`sin_idx', `cos_idx']
            mat `subV'[2, 1] = `VV'[`cos_idx', `sin_idx']
            mat `subV'[2, 2] = `VV'[`cos_idx', `cos_idx']
            // β vector for sin and cos
            mat `RbetA' = J(2, 1, .)
            mat `RbetA'[1, 1] = `sin_coef'
            mat `RbetA'[2, 1] = `cos_coef'
            // Wald = β' * inv(V_sub) * β
            mat `subV_inv' = invsym(`subV')
            mat `wald_mat' = `RbetA'' * `subV_inv' * `RbetA'
            local wald = `wald_mat'[1, 1]
            // F = Wald / q (q = 2 restrictions)
            local F_fourier = `wald' / 2
            local df_r = e(df_r)
            local p_fourier = Ftail(2, `df_r', `F_fourier')

            di as txt _col(7) "sin coefficient           = " as res %10.6f `sin_coef'
            di as txt _col(7) "cos coefficient           = " as res %10.6f `cos_coef'
            di as txt _col(7) "Fourier k*                = " as res %6.2f `kstar'
            di as txt ""
            di as txt _col(7) "F-statistic (sin + cos)   = " as res %10.4f `F_fourier'
            di as txt _col(7) "p-value                   = " as res %10.4f `p_fourier'
            if `p_fourier' < 0.05 {
                di as txt _col(7) "Fourier terms are " as res "jointly significant"
            }
            else {
                di as txt _col(7) "Fourier terms are " as txt "not jointly significant"
            }
        }
        else {
            di as txt _col(7) "Fourier terms not found in stored results"
        }
        di as txt ""
    }

    // =========================================================================
    // 5. LONG-RUN EQUILIBRIUM RELATIONSHIP
    // =========================================================================
    di as txt _col(5) "{bf:Long-Run Equilibrium Relationship}"
    di as txt _col(5) "y = " _c
    local first = 1
    local nw : word count `lr_vars'
    forvalues i = 1/`nw' {
        local vname : word `i' of `lr_vars'
        local coef : word `i' of `lr_coefs'
        local dname = subinstr("`vname'", "L.", "", 1)
        if `first' {
            di as res %8.4f `coef' " * `dname'" _c
            local first = 0
        }
        else {
            if `coef' >= 0 {
                di as res " + " %8.4f `coef' " * `dname'" _c
            }
            else {
                di as res " - " %8.4f abs(`coef') " * `dname'" _c
            }
        }
    }
    di as txt ""
    di as txt ""

    di as txt "{hline 78}"
    di as res _col(5) "aardl_advanced complete."
    di as txt "{hline 78}"
end
