*! _aardl_bootstrap — Bootstrap engine for aardl package
*! Version 1.2.0
*!
*! Implements both McNown et al. (2018) unconditional and
*! Bertelli, Vacca & Zoia (2022) conditional bootstrap methods.
*! Pattern follows _fbardl_bootstrap.ado / _fqardl_bootstrap.ado exactly.
*! Key: bootstraps BOTH y and x variables using VECM residuals.

capture program drop _aardl_bootstrap
program define _aardl_bootstrap, rclass
    version 17

    syntax varname(ts), ///
        INDEPvars(string)  ///   list of independent variables
        FORMula(string)    ///   best model formula
        REPS(integer)      ///   bootstrap replications
        BMEThod(string)    ///   mcnown or bvz
        CASEval(integer)   ///   PSS case
        KSTAR(real)        ///   Fourier frequency
        NOBS(integer)           // sample size

    local depvar "`varlist'"

    // Parse regressor list
    local lhs "D.`depvar'"
    local rhsvars "`formula'"

    // ─── Observed test statistics ───
    qui regress `lhs' `rhsvars'
    qui estimates store _bs_main

    // F_overall: joint significance of all lagged levels
    local levelvars "L.`depvar'"
    foreach xvar of local indepvars {
        local levelvars "`levelvars' L.`xvar'"
    }
    qui test `levelvars'
    local Fov_orig = r(F)

    // t_DV: lagged dependent
    local t_orig = _b[L.`depvar'] / _se[L.`depvar']

    // F_ind: lagged independent variables
    local indeplev ""
    foreach xvar of local indepvars {
        local indeplev "`indeplev' L.`xvar'"
    }
    qui test `indeplev'
    local Find_orig = r(F)

    local nindep : word count `indepvars'

    // ─── Extract best_p from formula (count L#.D.depvar terms) ───
    local best_p = 0
    foreach token of local rhsvars {
        if regexm("`token'", "^L[0-9]+\.D\.`depvar'$") {
            local best_p = `best_p' + 1
        }
    }
    if `best_p' == 0 local best_p = 1

    // =========================================================================
    // BOOTSTRAP SETUP (follows fbardl/fqardl pattern exactly)
    // =========================================================================

    if "`bmethod'" == "mcnown" {
        // =================================================================
        // McNown et al. (2018) — Unconditional Bootstrap
        // =================================================================

        // Step 1: Restricted y regression (null: all level terms = 0)
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

        // Step 2: Unrestricted regression for each Δx (VECM equations)
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

            qui regress D.`xvar' `xreg'
            tempvar resid_x_`cname'
            qui predict double `resid_x_`cname'', residuals
        }
    }
    else {
        // =================================================================
        // Bertelli et al. (2022) — Conditional Bootstrap
        // =================================================================

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

        // (2) t null: drop L.depvar only
        local restr_t ""
        foreach v of local rhsvars {
            if "`v'" != "L.`depvar'" {
                local restr_t "`restr_t' `v'"
            }
        }
        qui regress `lhs' `restr_t'
        tempvar resid_t
        qui predict double `resid_t', residuals

        // (3) Find null: drop L.indepvars
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

        // (4) Marginal VECM for each x (same as fbardl/fqardl)
        foreach xvar of local indepvars {
            local cname = subinstr("`xvar'", ".", "_", .)
            local xreg ""
            foreach xv2 of local indepvars {
                local xreg "`xreg' L.`xv2'"
            }
            forvalues j = 1/`best_p' {
                local xreg "`xreg' L`j'.D.`depvar'"
                foreach xv2 of local indepvars {
                    local xreg "`xreg' L`j'.D.`xv2'"
                }
            }
            qui regress D.`xvar' `xreg'
            tempvar resid_vecm_`cname'
            qui predict double `resid_vecm_`cname'', residuals
        }
    }

    // =========================================================================
    // BOOTSTRAP LOOP (uses Mata vectors + tempfile, like fbardl/fqardl)
    // =========================================================================
    mata {
        boot_Fov  = J(`reps', 1, .)
        boot_t    = J(`reps', 1, .)
        boot_Find = J(`reps', 1, .)
    }

    forvalues b = 1/`reps' {
        // Progress display
        if mod(`b', 100) == 0 {
            di as txt _col(7) "Bootstrap replication `b'/`reps'..."
        }

        // Save current data
        tempfile _boot_tmp
        qui save `_boot_tmp', replace

        local NN = `nobs'

        // ── Generate bootstrap data (BOTH y AND x) ──
        // Resampling index (same for y and all x — joint resampling)
        tempvar ridx
        qui gen `ridx' = ceil(uniform() * `NN')
        qui replace `ridx' = max(1, min(`NN', `ridx'))

        if "`bmethod'" == "mcnown" {
            // McNown: use restricted y residuals + unrestricted x residuals
            tempvar dy_star y_star
            qui gen double `dy_star' = D.`depvar' + `resid_y_restr'[`ridx'] - `resid_y_restr'
            qui gen double `y_star' = L.`depvar' + `dy_star' if _n > 1
            qui replace `y_star' = `depvar'[1] if _n == 1
            qui replace `depvar' = `y_star'

            // Bootstrap each x variable (same as fbardl)
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
            // BVZ: use Fov restricted residuals for y + VECM residuals for x
            tempvar dy_star y_star
            qui gen double `dy_star' = D.`depvar' + `resid_Fov'[`ridx'] - `resid_Fov'
            qui gen double `y_star' = L.`depvar' + `dy_star' if _n > 1
            qui replace `y_star' = `depvar'[1] if _n == 1
            qui replace `depvar' = `y_star'

            // Bootstrap each x variable using VECM residuals (same as fbardl)
            foreach xvar of local indepvars {
                local cname = subinstr("`xvar'", ".", "_", .)
                tempvar dx_star_`cname' x_star_`cname'
                qui gen double `dx_star_`cname'' = D.`xvar' + `resid_vecm_`cname''[`ridx'] - `resid_vecm_`cname''
                qui gen double `x_star_`cname'' = L.`xvar' + `dx_star_`cname'' if _n > 1
                qui replace `x_star_`cname'' = `xvar'[1] if _n == 1
                qui replace `xvar' = `x_star_`cname''
            }
        }

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

    // =========================================================================
    // COMPUTE BOOTSTRAP CRITICAL VALUES AND P-VALUES
    // (Exact same code as _fbardl_bootstrap.ado and _fqardl_bootstrap.ado)
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
        st_numscalar("r(Fov_cv05)", Fov_cv05)
        st_numscalar("r(Fov_pval)", Fov_pval)
        st_numscalar("r(t_cv05)", t_cv05)
        st_numscalar("r(t_pval)", t_pval)
        st_numscalar("r(Find_cv05)", Find_cv05)
        st_numscalar("r(Find_pval)", Find_pval)

        printf("{txt}  Bootstrap complete: %g valid Fov, %g t, %g Find replications\n", ///
            B_Fov, B_t, B_Find)
    }

    // Return results
    return scalar Fov_bp = r(Fov_pval)
    return scalar tDV_bp = r(t_pval)
    return scalar Find_bp = r(Find_pval)
    return scalar Fov_cv5 = r(Fov_cv05)
    return scalar tDV_cv5 = r(t_cv05)
    return scalar Find_cv5 = r(Find_cv05)

    // Restore main estimation
    qui estimates restore _bs_main
    qui estimates drop _bs_main

end
