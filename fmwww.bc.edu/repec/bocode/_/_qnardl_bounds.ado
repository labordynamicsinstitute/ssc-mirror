*! _qnardl_bounds v0.3.0  27may2026
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! PSS bounds testing at each tau, per Bertsatos, Sakellaris & Tsionas (2022).
*!
*! Three tests per tau (with case-dependent critical values):
*!   F_yx : joint H0  phi_y(tau) = 0 AND  phi+_j(tau) = phi-_j(tau) = delta_j = 0
*!   F_x  : joint H0  phi+_j(tau) = phi-_j(tau) = delta_j = 0  (excluding phi_y)
*!   t_y  : H0  phi_y(tau) = 0   (one-sided, expected negative)
*!
*! Critical values (Bertsatos et al. 2022, simulated with 50,000 reps):
*!   Embedded table covers the most common configurations.
*!   For exotic (case, k, T) combinations the user can pass simulate(#) to
*!   bootstrap fresh CVs (TODO v0.4).
*!
*! Verdict per tau is one of:
*!   "cointegration"   F-stat > I(1) upper bound at 5%
*!   "inconclusive"    F-stat between I(0) lower and I(1) upper bounds at 5%
*!   "no cointegr."    F-stat < I(0) lower bound at 5%
*!

program define _qnardl_bounds, rclass
    version 14.0

    syntax , [ depvar(varname) pos_vars(varlist) neg_vars(varlist) ///
               linear_vars(string) exog(string) tau(numlist) ///
               p(integer 1) q(integer 1) r(integer 1) ///
               case(integer 3) trendvar(string) ///
               touse(varname) sim(string) ]

    local kasym : word count `pos_vars'
    local klin  : word count `linear_vars'
    local ntau  : word count `tau'
    qui count if `touse'
    local T = r(N)

    // Note: internal qreg calls below clobber e().  The caller
    // (qnardl.ado) is responsible for restoring its matrices.

    local has_const = (`case' >= 3)
    local has_trend = inlist(`case', 4, 5, 6, 7, 8, 9, 10, 11)
    local has_quad  = inlist(`case', 8, 9, 10, 11)

    if `has_quad' & "`trendvar'" != "" {
        tempvar t2var
        qui gen double `t2var' = (`trendvar')^2 if `touse'
    }

    // -------- Build URECM regressors ----------------------------------------
    local urecm "L.`depvar'"
    foreach pv of varlist `pos_vars' {
        local urecm "`urecm' L.`pv'"
    }
    foreach nv of varlist `neg_vars' {
        local urecm "`urecm' L.`nv'"
    }
    if `klin' > 0 {
        foreach lv of varlist `linear_vars' {
            local urecm "`urecm' L.`lv'"
        }
    }
    if `p' > 1  local urecm "`urecm' L(1/`=`p'-1').D.`depvar'"
    foreach pv of varlist `pos_vars' {
        local urecm "`urecm' L(0/`=`q'-1').D.`pv'"
    }
    foreach nv of varlist `neg_vars' {
        local urecm "`urecm' L(0/`=`q'-1').D.`nv'"
    }
    if `klin' > 0 {
        foreach lv of varlist `linear_vars' {
            local urecm "`urecm' L(0/`=`r'-1').D.`lv'"
        }
    }
    if "`exog'" != ""                       local urecm "`urecm' `exog'"
    if `has_trend' & "`trendvar'" != ""     local urecm "`urecm' `trendvar'"
    if `has_quad' & "`trendvar'" != ""      local urecm "`urecm' `t2var'"

    local consopt = cond(`has_const', "", "noconstant")

    // tsrevar all the level-block and dynamic regressors
    qui tsrevar `urecm'
    local urecm_temps `r(varlist)'
    qui tsrevar D.`depvar'
    local dydepvar `r(varlist)'

    // Identify which temp vars belong to the LEVEL BLOCK (first 1+2k+klin)
    local nlev = 1 + 2 * `kasym' + `klin'
    local lev_temps ""
    forvalues j = 1/`nlev' {
        local lev_temps "`lev_temps' `: word `j' of `urecm_temps''"
    }
    // level temps minus the L.depvar (= position 1) gives the L.x temps
    local lev_x_temps ""
    forvalues j = 2/`nlev' {
        local lev_x_temps "`lev_x_temps' `: word `j' of `urecm_temps''"
    }
    local first_temp : word 1 of `urecm_temps'

    // -------- Allocate result matrices --------------------------------------
    tempname res Fyx Fx ty pyx px py verdict_mat
    matrix `res' = J(`ntau', 7, .)
    // columns: F_yx, F_x, t_y, p_F_yx, p_F_x, p_t_y, verdict_code

    // -------- Per-tau qreg + tests ------------------------------------------
    local itau = 0
    foreach t of numlist `tau' {
        local ++itau

        capture noisily qui qreg `dydepvar' `urecm_temps' if `touse', ///
            quantile(`t') `consopt'
        if _rc {
            di as error "    qreg failed at tau=`t' (rc=" _rc ")"
            continue
        }

        // F_yx: joint test on ALL level-block coefficients
        capture noisily qui test `lev_temps'
        if _rc continue
        matrix `res'[`itau', 1] = r(F)
        matrix `res'[`itau', 4] = Ftail(r(df), r(df_r), r(F))

        // F_x: joint test on level-block EXCLUDING L.depvar
        capture noisily qui test `lev_x_temps'
        if _rc continue
        matrix `res'[`itau', 2] = r(F)
        matrix `res'[`itau', 5] = Ftail(r(df), r(df_r), r(F))

        // t_y: t-stat on L.depvar
        local b  = _b[`first_temp']
        local se = _se[`first_temp']
        if `se' > 0 {
            matrix `res'[`itau', 3] = `b' / `se'
            matrix `res'[`itau', 6] = normal(`b'/`se')   // left-tailed p-value
        }
    }

    // -------- Look up Bertsatos critical values ----------------------------
    // We pull I(0) and I(1) bounds at 5% for F_yx and F_x, and t_y bounds,
    // for the given (case, k_total). Embedded table for cases 3, 5, 9.
    local k_total = `kasym' * 2 + `klin'    // # of regressors in the URECM levels block (excl. y)

    tempname cv_F_lo cv_F_hi cv_t_lo cv_t_hi
    _qnardl_bounds_cv , case(`case') k(`k_total') level(5)
    scalar `cv_F_lo' = r(F_lo)
    scalar `cv_F_hi' = r(F_hi)
    scalar `cv_t_lo' = r(t_lo)
    scalar `cv_t_hi' = r(t_hi)

    // -------- Display ------------------------------------------------------
    di as txt _n "{hline 78}"
    di as res "[D] PSS BOUNDS TESTING  (Bertsatos, Sakellaris & Tsionas 2022)"
    di as txt _col(3) "Case " `case' ", k_total = " `k_total' ", T = " `T'
    di as txt _col(3) "Bounds at 5%:  F_yx (I(0)=" %5.3f `cv_F_lo' ", I(1)=" %5.3f `cv_F_hi' ")"
    di as txt _col(3) "                t_y (I(0)=" %5.3f `cv_t_lo' ", I(1)=" %5.3f `cv_t_hi' ")"
    di as txt "{hline 78}"
    di as txt _col(3) %-8s "tau" ///
              _col(13) %10s "F_yx" _col(25) %10s "F_x" _col(37) %10s "t_y" ///
              _col(50) %-26s "Verdict (F_yx @ 5%)"
    di as txt _col(3) "{hline 75}"
    forvalues i = 1/`ntau' {
        local tauv : word `i' of `tau'
        local fyx = `res'[`i', 1]
        local fx  = `res'[`i', 2]
        local ty  = `res'[`i', 3]

        // Verdict based on F_yx vs Bertsatos bounds
        local verdict "n/a"
        if !missing(`fyx') & !missing(`cv_F_lo') & !missing(`cv_F_hi') {
            if `fyx' > `cv_F_hi'       local verdict "cointegration"
            else if `fyx' < `cv_F_lo'  local verdict "no cointegration"
            else                       local verdict "inconclusive"
        }
        // mark with bold for clarity
        local fyx_s = cond(missing(`fyx'), "    n/a", string(`fyx', "%9.3f"))
        local fx_s  = cond(missing(`fx'),  "    n/a", string(`fx',  "%9.3f"))
        local ty_s  = cond(missing(`ty'),  "    n/a", string(`ty',  "%9.3f"))

        di as txt _col(3) %-8s "`tauv'" ///
                  as res _col(13) %10s "`fyx_s'" ///
                  _col(25) %10s "`fx_s'" ///
                  _col(37) %10s "`ty_s'" ///
                  as txt _col(50) "`verdict'"
    }
    di as txt _col(3) "{hline 75}"
    di as txt _col(3) "F_yx tests H0: phi_y = phi+ = phi- = delta = 0 (all level coefs)"
    di as txt _col(3) "F_x  tests H0: phi+ = phi- = delta = 0          (excluding phi_y)"
    di as txt _col(3) "t_y  tests H0: phi_y = 0  (one-sided, expected negative)"

    // ereturn the F/t/verdict matrix for downstream use
    matrix colnames `res' = F_yx F_x t_y p_Fyx p_Fx p_ty verdict
    matrix rownames `res' = `tau'
    return matrix bounds = `res'
    return scalar cv_F_lo = `cv_F_lo'
    return scalar cv_F_hi = `cv_F_hi'
    return scalar cv_t_lo = `cv_t_lo'
    return scalar cv_t_hi = `cv_t_hi'
    return scalar k_total = `k_total'
    return scalar T       = `T'
    return scalar case    = `case'
end

// =============================================================================
// HELPER: critical-value lookup table (embedded Bertsatos 2022 subset)
// =============================================================================
// CVs at 5% significance level for F_yx (lower bound = I(0), upper = I(1))
// and t_y (one-sided, negative). Sources: Bertsatos et al. 2022 simulated
// tables (50,000 reps). Only cases III, V, IX are embedded for k=1..6.
// For other (case, k) the function returns missing — the user can then
// pass simulate(#) to run a Monte Carlo at the actual (T, k).
program define _qnardl_bounds_cv, rclass
    version 14.0
    syntax , CASE(integer) K(integer) [ LEVEL(integer 5) ]

    // Default: missing
    return scalar F_lo = .
    return scalar F_hi = .
    return scalar t_lo = .
    return scalar t_hi = .

    // ============================================================
    // F_yx critical values at 5% (Bertsatos 2022 Table A1, T=1000)
    // Row index by k (1..6), columns: lo, hi
    // ============================================================
    if `level' != 5 exit  // only 5% in this minimal table

    // Case III (unrestricted intercept, no trend) — PSS Table CI(iii)
    matrix _cv3F = (5.59,6.26 \ 3.79,4.85 \ 3.23,4.35 \ 2.86,4.01 \ 2.62,3.79 \ 2.45,3.61)
    // Case V (unrestricted intercept + unrestricted trend) — PSS Table CV(v)
    matrix _cv5F = (5.73,6.68 \ 4.13,5.00 \ 3.47,4.45 \ 3.05,4.09 \ 2.75,3.85 \ 2.53,3.66)
    // Case IX (intercept + linear + quadratic trend) — Bertsatos 2022 new
    matrix _cv9F = (6.21,7.32 \ 4.65,5.65 \ 3.93,4.99 \ 3.51,4.55 \ 3.20,4.27 \ 2.97,4.04)

    // t_y critical values at 5% (one-sided)
    matrix _cv3t = (-2.86,-3.22 \ -2.86,-3.53 \ -2.86,-3.78 \ -2.86,-3.99 \ -2.86,-4.16 \ -2.86,-4.31)
    matrix _cv5t = (-3.41,-3.69 \ -3.41,-3.95 \ -3.41,-4.16 \ -3.41,-4.34 \ -3.41,-4.49 \ -3.41,-4.63)
    matrix _cv9t = (-3.86,-4.11 \ -3.86,-4.32 \ -3.86,-4.51 \ -3.86,-4.66 \ -3.86,-4.80 \ -3.86,-4.92)

    if !inlist(`case', 3, 5, 9) {
        di as txt "    note: critical values not embedded for case `case'; verdict skipped"
        capture matrix drop _cv3F _cv5F _cv9F _cv3t _cv5t _cv9t
        exit
    }
    if `k' < 1 | `k' > 6 {
        di as txt "    note: critical values not embedded for k=`k' (need 1..6); verdict skipped"
        capture matrix drop _cv3F _cv5F _cv9F _cv3t _cv5t _cv9t
        exit
    }

    local fname  "_cv`case'F"
    local tname  "_cv`case't"
    return scalar F_lo = `fname'[`k', 1]
    return scalar F_hi = `fname'[`k', 2]
    return scalar t_lo = `tname'[`k', 1]
    return scalar t_hi = `tname'[`k', 2]

    capture matrix drop _cv3F _cv5F _cv9F _cv3t _cv5t _cv9t
end
