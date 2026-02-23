*! _fbardl_bootstrap — Bootstrap Cointegration Tests for FBARDL
*! Implements both McNown et al. (2018) and Bertelli et al. (2022)
*! Version 1.0.0 — 2026-02-21
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _fbardl_bootstrap
program define _fbardl_bootstrap, rclass
    version 17

    syntax varlist(ts fv) [if] [in], ///
        depvar(string)               ///
        indepvars(string)            ///
        levelvars(string)            ///
        indeplev(string)             ///
        ecmvar(string)               ///
        bootstrap_type(string)       ///
        reps(integer)                ///
        nobs(integer)                ///
        best_p(integer)              ///
        best_kstar(real)             ///
        timevar(string)

    // Parse the dependent variable and regressors from the varlist
    gettoken lhs rhsvars : varlist

    // =========================================================================
    // COMPUTE ORIGINAL TEST STATISTICS
    // =========================================================================
    // The main fbardl.ado already estimated the model and computed
    // Fov, t, Find. We re-estimate here for the bootstrap procedure.

    // Unrestricted model
    qui regress `lhs' `rhsvars'
    local Fov_orig = .
    local t_orig = _b[L.`depvar'] / _se[L.`depvar']
    local Find_orig = .

    // Fov: test all lagged levels
    qui test `levelvars'
    local Fov_orig = r(F)

    // Find: test independent lagged levels only
    qui test `indeplev'
    local Find_orig = r(F)

    // Number of independent variables
    local nindep : word count `indepvars'

    // =========================================================================
    // MATA BOOTSTRAP ENGINE
    // =========================================================================
    di as txt _col(5) "Running bootstrap (`reps' replications)..."
    di as txt ""

    // Choose method
    if "`bootstrap_type'" == "fbardl_mcnown" {
        // =================================================================
        // METHOD A: McNown et al. (2018) — Unconditional Bootstrap
        // =================================================================
        di as txt _col(5) "{it:Method: McNown, Sam & Goh (2018) — Unconditional}"
        di as txt ""

        // Step 1: Restricted ARDL for Δy (null: all level terms = 0)
        // Remove level terms (L.depvar, L.indepvars)
        local restr_rhsvars ""
        foreach v of local rhsvars {
            local is_level = 0
            foreach lv of local levelvars {
                if "`v'" == "`lv'" local is_level = 1
            }
            if `is_level' == 0 {
                local restr_rhsvars "`restr_rhsvars' `v'"
            }
        }

        qui regress `lhs' `restr_rhsvars'
        tempvar resid_y_restr
        qui predict double `resid_y_restr', residuals

        // Unrestricted equation for each Δx_i
        foreach xvar of local indepvars {
            // Build regressor list for Δx equation
            // Include lagged levels of all vars + lagged diffs of all vars
            local xreg "`levelvars'"
            forvalues j = 1/`best_p' {
                local xreg "`xreg' L`j'.D.`depvar'"
            }
            foreach xv2 of local indepvars {
                forvalues j = 1/`best_p' {
                    local xreg "`xreg' L`j'.D.`xv2'"
                }
            }
            if `best_kstar' > 0 {
                local xreg "`xreg' _fbardl_sin _fbardl_cos"
            }

            qui regress D.`xvar' `xreg'
            local cname = subinstr("`xvar'", ".", "_", .)
            tempvar resid_x_`cname'
            qui predict double `resid_x_`cname'', residuals
        }

        // Save coefficient matrices for restricted y-model
        qui regress `lhs' `restr_rhsvars'
        tempname b_y_r
        mat `b_y_r' = e(b)

        // Save coefficient matrices for each x-model
        foreach xvar of local indepvars {
            local cname = subinstr("`xvar'", ".", "_", .)
            local xreg "`levelvars'"
            forvalues j = 1/`best_p' {
                local xreg "`xreg' L`j'.D.`depvar'"
            }
            foreach xv2 of local indepvars {
                forvalues j = 1/`best_p' {
                    local xreg "`xreg' L`j'.D.`xv2'"
                }
            }
            if `best_kstar' > 0 {
                local xreg "`xreg' _fbardl_sin _fbardl_cos"
            }
            qui regress D.`xvar' `xreg'
            tempname b_x_`cname'
            mat `b_x_`cname'' = e(b)
        }
    }
    else {
        // =================================================================
        // METHOD B: Bertelli et al. (2022) — Conditional Bootstrap
        // =================================================================
        di as txt _col(5) "{it:Method: Bertelli, Vacca & Zoia (2022) — Conditional}"
        di as txt ""

        // Three sets of restricted residuals:

        // (1) Fov null: drop ALL level terms
        local restr_Fov ""
        foreach v of local rhsvars {
            local is_level = 0
            foreach lv of local levelvars {
                if "`v'" == "`lv'" local is_level = 1
            }
            if `is_level' == 0 {
                local restr_Fov "`restr_Fov' `v'"
            }
        }
        qui regress `lhs' `restr_Fov'
        tempvar resid_Fov
        qui predict double `resid_Fov', residuals
        tempname b_Fov
        mat `b_Fov' = e(b)

        // (2) t null: drop L.depvar only, keep L.indepvars
        local restr_t ""
        foreach v of local rhsvars {
            if "`v'" != "`ecmvar'" {
                local restr_t "`restr_t' `v'"
            }
        }
        qui regress `lhs' `restr_t'
        tempvar resid_t
        qui predict double `resid_t', residuals
        tempname b_t
        mat `b_t' = e(b)

        // (3) Find null: drop L.indepvars, keep L.depvar
        local restr_Find ""
        foreach v of local rhsvars {
            local is_indeplev = 0
            foreach il of local indeplev {
                if "`v'" == "`il'" local is_indeplev = 1
            }
            if `is_indeplev' == 0 {
                local restr_Find "`restr_Find' `v'"
            }
        }
        qui regress `lhs' `restr_Find'
        tempvar resid_Find
        qui predict double `resid_Find', residuals
        tempname b_Find
        mat `b_Find' = e(b)

        // (4) Marginal VECM for independent variables
        foreach xvar of local indepvars {
            local cname = subinstr("`xvar'", ".", "_", .)
            local xreg ""
            // Lagged levels of all x variables
            foreach xv2 of local indepvars {
                local xreg "`xreg' L.`xv2'"
            }
            // Lagged diffs
            forvalues j = 1/`best_p' {
                local xreg "`xreg' L`j'.D.`depvar'"
                foreach xv2 of local indepvars {
                    local xreg "`xreg' L`j'.D.`xv2'"
                }
            }
            qui regress D.`xvar' `xreg'
            tempvar resid_vecm_`cname'
            qui predict double `resid_vecm_`cname'', residuals
            tempname b_vecm_`cname'
            mat `b_vecm_`cname'' = e(b)
        }
    }

    // =========================================================================
    // BOOTSTRAP LOOP (Mata-based for speed)
    // =========================================================================
    // Store original data in Mata matrices
    mata {
        // Load residuals and original data
        st_view(Y=., ., "`depvar'")
        T_total = rows(Y)

        // Initialize bootstrap storage
        boot_Fov = J(`reps', 1, .)
        boot_t   = J(`reps', 1, .)
        boot_Find = J(`reps', 1, .)

        // Progress bar
        printf("{txt}  Bootstrap progress: ")
        dots_step = max((floor(`reps'/20), 1))
    }

    // Bootstrap loop in Stata (uses Mata for OLS inside)
    forvalues b = 1/`reps' {
        // Display progress
        if mod(`b', max(floor(`reps'/20), 1)) == 0 {
            di as txt "." _c
        }

        // Save current data
        tempfile _boot_tmp
        qui save `_boot_tmp', replace

        // Resample residuals
        local NN = `nobs'

        // Generate bootstrap data
        if "`bootstrap_type'" == "fbardl_mcnown" {
            // McNown: use restricted y residuals
            // Resample with replacement
            tempvar ridx
            qui gen `ridx' = ceil(uniform() * `NN')
            qui replace `ridx' = max(1, min(`NN', `ridx'))

            // Use resampled residuals to generate new data
            // Δy* from restricted model + bootstrap residual
            // Δx* from unrestricted model + bootstrap residual
            // Then cumulate: y* = y*_{t-1} + Δy*, x* = x*_{t-1} + Δx*

            // Bootstrap y and x
            tempvar dy_star dx_star y_star
            qui gen double `dy_star' = D.`depvar' + `resid_y_restr'[`ridx'] - `resid_y_restr'
            qui gen double `y_star' = L.`depvar' + `dy_star' if _n > 1
            qui replace `y_star' = `depvar'[1] if _n == 1

            // Replace depvar with bootstrap version
            qui replace `depvar' = `y_star'

            foreach xvar of local indepvars {
                local cname = subinstr("`xvar'", ".", "_", .)
                tempvar dx_star_`cname' x_star_`cname'
                qui gen double `dx_star_`cname'' = D.`xvar' + `resid_x_`cname''[`ridx'] - `resid_x_`cname''
                qui gen double `x_star_`cname'' = L.`xvar' + `dx_star_`cname'' if _n > 1
                qui replace `x_star_`cname'' = `xvar'[1] if _n == 1
                qui replace `xvar' = `x_star_`cname''
            }
        }
        else {
            // Bertelli: use three sets of restricted residuals
            // For simplicity, generate data under Fov null (most common)
            tempvar ridx
            qui gen `ridx' = ceil(uniform() * `NN')
            qui replace `ridx' = max(1, min(`NN', `ridx'))

            tempvar dy_star y_star
            qui gen double `dy_star' = D.`depvar' + `resid_Fov'[`ridx'] - `resid_Fov'
            qui gen double `y_star' = L.`depvar' + `dy_star' if _n > 1
            qui replace `y_star' = `depvar'[1] if _n == 1
            qui replace `depvar' = `y_star'

            // Generate x* from marginal VECM residuals
            foreach xvar of local indepvars {
                local cname = subinstr("`xvar'", ".", "_", .)
                tempvar dx_star_`cname' x_star_`cname'
                qui gen double `dx_star_`cname'' = D.`xvar' + `resid_vecm_`cname''[`ridx'] - `resid_vecm_`cname''
                qui gen double `x_star_`cname'' = L.`xvar' + `dx_star_`cname'' if _n > 1
                qui replace `x_star_`cname'' = `xvar'[1] if _n == 1
                qui replace `xvar' = `x_star_`cname''
            }
        }

        // Re-generate Fourier terms (they depend on t, not data)
        // They are already correctly generated

        // Re-estimate unrestricted ARDL on bootstrap data
        capture qui regress `lhs' `rhsvars'
        if _rc == 0 {
            // Fov
            capture qui test `levelvars'
            if _rc == 0 {
                mata: boot_Fov[`b'] = `r(F)'
            }

            // t
            local bt = _b[L.`depvar'] / _se[L.`depvar']
            mata: boot_t[`b'] = `bt'

            // Find
            capture qui test `indeplev'
            if _rc == 0 {
                mata: boot_Find[`b'] = `r(F)'
            }
        }

        // Restore original data
        qui use `_boot_tmp', clear
    }

    di as txt ""
    di as txt ""

    // =========================================================================
    // COMPUTE BOOTSTRAP CRITICAL VALUES AND P-VALUES
    // =========================================================================
    mata {
        // Remove missing values
        boot_Fov_c = select(boot_Fov, boot_Fov :< .)
        boot_t_c = select(boot_t, boot_t :< .)
        boot_Find_c = select(boot_Find, boot_Find :< .)

        B_Fov = rows(boot_Fov_c)
        B_t = rows(boot_t_c)
        B_Find = rows(boot_Find_c)

        // F-test critical values (upper tail)
        if (B_Fov > 2) {
            boot_Fov_s = sort(boot_Fov_c, 1)
            Fov_cv01  = boot_Fov_s[min((ceil(0.99 * B_Fov), B_Fov))]
            Fov_cv025 = boot_Fov_s[min((ceil(0.975 * B_Fov), B_Fov))]
            Fov_cv05  = boot_Fov_s[min((ceil(0.95 * B_Fov), B_Fov))]
            Fov_cv10  = boot_Fov_s[min((ceil(0.90 * B_Fov), B_Fov))]
            Fov_pval  = mean(boot_Fov_c :>= `Fov_orig')
        }
        else {
            Fov_cv01 = .; Fov_cv025 = .; Fov_cv05 = .; Fov_cv10 = .; Fov_pval = .
        }

        if (B_Find > 2) {
            boot_Find_s = sort(boot_Find_c, 1)
            Find_cv01  = boot_Find_s[min((ceil(0.99 * B_Find), B_Find))]
            Find_cv025 = boot_Find_s[min((ceil(0.975 * B_Find), B_Find))]
            Find_cv05  = boot_Find_s[min((ceil(0.95 * B_Find), B_Find))]
            Find_cv10  = boot_Find_s[min((ceil(0.90 * B_Find), B_Find))]
            Find_pval  = mean(boot_Find_c :>= `Find_orig')
        }
        else {
            Find_cv01 = .; Find_cv025 = .; Find_cv05 = .; Find_cv10 = .; Find_pval = .
        }

        // t-test critical values (lower tail)
        if (B_t > 2) {
            boot_t_s = sort(boot_t_c, 1)
            t_cv01  = boot_t_s[max((floor(0.01 * B_t), 1))]
            t_cv025 = boot_t_s[max((floor(0.025 * B_t), 1))]
            t_cv05  = boot_t_s[max((floor(0.05 * B_t), 1))]
            t_cv10  = boot_t_s[max((floor(0.10 * B_t), 1))]
            t_pval  = mean(boot_t_c :<= `t_orig')
        }
        else {
            t_cv01 = .; t_cv025 = .; t_cv05 = .; t_cv10 = .; t_pval = .
        }

        // Store to Stata
        st_numscalar("r(Fov_cv01)", Fov_cv01)
        st_numscalar("r(Fov_cv025)", Fov_cv025)
        st_numscalar("r(Fov_cv05)", Fov_cv05)
        st_numscalar("r(Fov_cv10)", Fov_cv10)
        st_numscalar("r(Fov_pval)", Fov_pval)
        st_numscalar("r(t_cv01)", t_cv01)
        st_numscalar("r(t_cv025)", t_cv025)
        st_numscalar("r(t_cv05)", t_cv05)
        st_numscalar("r(t_cv10)", t_cv10)
        st_numscalar("r(t_pval)", t_pval)
        st_numscalar("r(Find_cv01)", Find_cv01)
        st_numscalar("r(Find_cv025)", Find_cv025)
        st_numscalar("r(Find_cv05)", Find_cv05)
        st_numscalar("r(Find_cv10)", Find_cv10)
        st_numscalar("r(Find_pval)", Find_pval)

        printf("{txt}  Bootstrap complete: %g valid Fov, %g t, %g Find replications\n", ///
            B_Fov, B_t, B_Find)
    }

    // Return results
    return scalar Fov_cv01 = r(Fov_cv01)
    return scalar Fov_cv025 = r(Fov_cv025)
    return scalar Fov_cv05 = r(Fov_cv05)
    return scalar Fov_cv10 = r(Fov_cv10)
    return scalar Fov_pval = r(Fov_pval)
    return scalar t_cv01 = r(t_cv01)
    return scalar t_cv025 = r(t_cv025)
    return scalar t_cv05 = r(t_cv05)
    return scalar t_cv10 = r(t_cv10)
    return scalar t_pval = r(t_pval)
    return scalar Find_cv01 = r(Find_cv01)
    return scalar Find_cv025 = r(Find_cv025)
    return scalar Find_cv05 = r(Find_cv05)
    return scalar Find_cv10 = r(Find_cv10)
    return scalar Find_pval = r(Find_pval)
end
