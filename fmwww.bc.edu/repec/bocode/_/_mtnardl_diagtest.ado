*! _mtnardl_diagtest — Diagnostic Tests for MTNARDL
*! Version 1.0.0 — 2026-02-24
*! Adapted from fbardl diagnostic suite

capture program drop _mtnardl_diagtest
program define _mtnardl_diagtest
    version 17
    args resid_var nobs nparams

    // =========================================================================
    // A. NORMALITY TESTS
    // =========================================================================
    di as txt ""
    di as txt "  {bf:A. Normality Tests}"
    di as txt "  {hline 55}"
    di as txt _col(5) "Test" _col(35) "Statistic" _col(50) "p-value"
    di as txt "  {hline 55}"

    // Jarque-Bera
    capture qui sum `resid_var', detail
    if _rc == 0 {
        local skew = r(skewness)
        local kurt = r(kurtosis)
        local n_jb = r(N)
        if `n_jb' > 5 {
            local jb = (`n_jb' / 6) * (`skew'^2 + ((`kurt' - 3)^2) / 4)
            local jb_p = chi2tail(2, `jb')
            di as txt _col(5) "Jarque-Bera" _col(33) as res %10.4f `jb' _col(48) %8.4f `jb_p' _c
            _mtnardl_stars `jb_p'
        }
    }

    // Shapiro-Wilk
    capture qui swilk `resid_var'
    if _rc == 0 {
        local sw_p = r(p)
        if `sw_p' < . {
            di as txt _col(5) "Shapiro-Wilk W" _col(33) as res %10.4f r(W) _col(48) %8.4f `sw_p' _c
            _mtnardl_stars `sw_p'
        }
    }

    // Shapiro-Francia
    capture qui sfrancia `resid_var'
    if _rc == 0 {
        local sf_p = r(p)
        if `sf_p' < . {
            di as txt _col(5) "Shapiro-Francia W'" _col(33) as res %10.4f r(W) _col(48) %8.4f `sf_p' _c
            _mtnardl_stars `sf_p'
        }
    }
    di as txt "  {hline 55}"

    // =========================================================================
    // B. SERIAL CORRELATION (manual LM)
    // =========================================================================
    di as txt ""
    di as txt "  {bf:B. Serial Correlation Tests}"
    di as txt "  {hline 55}"
    di as txt _col(5) "Test" _col(35) "Statistic" _col(50) "p-value"
    di as txt "  {hline 55}"

    // Breusch-Godfrey LM
    forvalues lag = 1/4 {
        local bg_chi = .
        local bg_p = .
        capture {
            tempvar resid_copy_`lag'
            qui gen double `resid_copy_`lag'' = `resid_var'
            qui regress `resid_copy_`lag'' L(1/`lag').`resid_copy_`lag''
            local bg_r2 = e(r2)
            local bg_n = e(N)
            local bg_chi = `bg_n' * `bg_r2'
            local bg_p = chi2tail(`lag', `bg_chi')
        }
        if `bg_p' < . {
            di as txt _col(5) "BG LM(`lag')" _col(33) as res %10.4f `bg_chi' _col(48) %8.4f `bg_p' _c
            _mtnardl_stars `bg_p'
        }
    }

    // Durbin-Watson (manual)
    local dw = .
    capture {
        tempvar dw_e dw_de
        qui gen double `dw_e' = `resid_var'
        qui gen double `dw_de' = `dw_e' - L.`dw_e'
        qui sum `dw_de' if !missing(`dw_de')
        local dw_ss_de = r(Var) * (r(N) - 1)
        qui sum `dw_e' if !missing(`dw_e')
        local dw_ss_e = r(Var) * (r(N) - 1)
        if `dw_ss_e' > 0 {
            local dw = `dw_ss_de' / `dw_ss_e'
        }
    }
    if `dw' < . {
        di as txt _col(5) "Durbin-Watson" _col(33) as res %10.4f `dw'
    }
    di as txt "  {hline 55}"

    // =========================================================================
    // C. HETEROSKEDASTICITY
    // =========================================================================
    di as txt ""
    di as txt "  {bf:C. Heteroskedasticity Tests}"
    di as txt "  {hline 55}"
    di as txt _col(5) "Test" _col(35) "Statistic" _col(50) "p-value"
    di as txt "  {hline 55}"

    // ARCH LM(1)
    local arch_F = .
    local arch_p = .
    capture {
        tempvar esq1
        qui gen double `esq1' = `resid_var'^2
        qui regress `esq1' L.`esq1'
        local arch_F = e(F)
        local arch_p = Ftail(e(df_m), e(df_r), e(F))
    }
    if `arch_p' < . {
        di as txt _col(5) "ARCH LM(1)" _col(33) as res %10.4f `arch_F' _col(48) %8.4f `arch_p' _c
        _mtnardl_stars `arch_p'
    }

    // ARCH LM(4)
    local arch4_F = .
    local arch4_p = .
    capture {
        tempvar esq4
        qui gen double `esq4' = `resid_var'^2
        qui regress `esq4' L(1/4).`esq4'
        local arch4_F = e(F)
        local arch4_p = Ftail(e(df_m), e(df_r), e(F))
    }
    if `arch4_p' < . {
        di as txt _col(5) "ARCH LM(4)" _col(33) as res %10.4f `arch4_F' _col(48) %8.4f `arch4_p' _c
        _mtnardl_stars `arch4_p'
    }

    // White's test (manual via squared residuals on fitted^2)
    local white_chi = .
    local white_p = .
    capture {
        tempvar esq_w yhat yhat2
        qui gen double `esq_w' = `resid_var'^2
        qui predict double `yhat'
        qui gen double `yhat2' = `yhat'^2
        qui regress `esq_w' `yhat' `yhat2'
        local white_chi = e(N) * e(r2)
        local white_p = chi2tail(e(df_m), `white_chi')
    }
    if `white_p' < . {
        di as txt _col(5) "White (NR2)" _col(33) as res %10.4f `white_chi' _col(48) %8.4f `white_p' _c
        _mtnardl_stars `white_p'
    }
    di as txt "  {hline 55}"

    // =========================================================================
    // D. FUNCTIONAL FORM
    // =========================================================================
    di as txt ""
    di as txt "  {bf:D. Functional Form}"
    di as txt "  {hline 55}"

    local reset_p = .
    capture {
        qui estat ovtest
        local reset_F = r(F)
        local reset_p = r(p)
    }
    if `reset_p' < . {
        di as txt _col(5) "Ramsey RESET" _col(33) as res %10.4f `reset_F' _col(48) %8.4f `reset_p' _c
        _mtnardl_stars `reset_p'
    }
    else {
        di as txt _col(5) "Ramsey RESET" _col(33) as txt "(not available)"
    }
    di as txt "  {hline 55}"

    // =========================================================================
    // E. STABILITY TESTS
    // =========================================================================
    di as txt ""
    di as txt "  {bf:E. Stability Tests}"
    di as txt "  {hline 55}"

    capture qui sum `resid_var'
    if _rc == 0 {
        local sd_resid = r(sd)
        local n_resid = r(N)

        if `sd_resid' > 0 & `n_resid' > 5 {
            // CUSUM
            local cusum_ok = 0
            capture {
                tempvar csum_v
                qui gen double `csum_v' = sum(`resid_var' / `sd_resid')
                qui sum `csum_v'
                local max_csum = max(abs(r(min)), abs(r(max)))
                local cusum_cv = 0.948 * sqrt(`n_resid')
                local cusum_ok = 1
            }
            if `cusum_ok' == 1 {
                if `max_csum' < `cusum_cv' {
                    di as txt _col(5) "CUSUM (5%)" _col(35) as res "Stable"
                }
                else {
                    di as txt _col(5) "CUSUM (5%)" _col(35) as err "Unstable"
                }
            }

            // CUSUM-SQ
            local cusumsq_ok = 0
            capture {
                tempvar esq2_v csumsq_v expected_v dev_v
                qui gen double `esq2_v' = `resid_var'^2
                qui sum `esq2_v'
                local total_sq = r(sum)
                if `total_sq' > 0 {
                    qui gen double `csumsq_v' = sum(`esq2_v') / `total_sq'
                    qui gen double `expected_v' = _n / _N
                    qui gen double `dev_v' = abs(`csumsq_v' - `expected_v')
                    qui sum `dev_v'
                    local max_dev = r(max)
                    local cusumsq_cv = 1.36 / sqrt(`n_resid')
                    local cusumsq_ok = 1
                }
            }
            if `cusumsq_ok' == 1 {
                if `max_dev' < `cusumsq_cv' {
                    di as txt _col(5) "CUSUM-SQ (5%)" _col(35) as res "Stable"
                }
                else {
                    di as txt _col(5) "CUSUM-SQ (5%)" _col(35) as err "Unstable"
                }
            }
        }
    }
    di as txt "  {hline 55}"
    di as txt _col(5) "{it:H0 (normality): normally distributed residuals}"
    di as txt _col(5) "{it:H0 (serial): no serial correlation}"
    di as txt _col(5) "{it:H0 (heterosk.): homoskedastic errors}"
    di as txt _col(5) "{it:Stars: *** p<0.01, ** p<0.05, * p<0.10}"
    di as txt ""
end
