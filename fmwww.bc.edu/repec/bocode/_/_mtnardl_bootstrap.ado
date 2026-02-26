*! _mtnardl_bootstrap — Bootstrap Cointegration Tests for MTNARDL
*! Implements McNown et al. (2018) and Bertelli et al. (2022)
*! Version 1.0.3 — 2026-02-24
*! Pattern follows _fbardl_bootstrap.ado

capture program drop _mtnardl_bootstrap
program define _mtnardl_bootstrap, rclass
    version 17

    syntax varlist(ts fv) [if] [in], ///
        depvar(string)               ///
        indepvars(string)            ///
        decomp_vars(string)          ///
        levelvars(string)            ///
        indeplev(string)             ///
        ecmvar(string)               ///
        bootstrap_type(string)       ///
        reps(integer)                ///
        nobs(integer)                ///
        best_p(integer)              ///
        timevar(string)              ///
        nq(integer)

    // Parse the LHS and RHS from varlist (like fbardl)
    gettoken lhs rhsvars : varlist

    // =========================================================================
    // COMPUTE ORIGINAL TEST STATISTICS
    // =========================================================================
    // Re-estimate unrestricted model
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

    // Number of decomposed independent variables
    local ndecomp : word count `decomp_vars'

    // =========================================================================
    // BOOTSTRAP SETUP
    // =========================================================================
    di as txt _col(5) "Running bootstrap (`reps' replications)..."
    di as txt ""

    // =========================================================================
    // METHOD A: McNown et al. (2018) — Unconditional Bootstrap
    // =========================================================================
    if "`bootstrap_type'" == "mtnardl_mcnown" {
        // Restricted model for y: drop all lagged levels
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

        // Unrestricted equations for each decomposed Δx_i
        foreach dvar of local decomp_vars {
            local cname = subinstr("`dvar'", ".", "_", .)
            local cname = subinstr("`cname'", "_mt_", "mt", .)
            local xreg "`levelvars'"
            forvalues j = 1/`best_p' {
                local xreg "`xreg' L`j'.D.`depvar'"
            }
            foreach dv2 of local decomp_vars {
                capture local chk = _b[D.`dv2']
                if _rc == 0 {
                    local xreg "`xreg' D.`dv2'"
                }
                forvalues j = 1/`best_p' {
                    capture local chk = _b[L`j'.D.`dv2']
                    if _rc == 0 {
                        local xreg "`xreg' L`j'.D.`dv2'"
                    }
                }
            }
            capture qui regress D.`dvar' `xreg'
            if _rc == 0 {
                tempvar resid_x_`cname'
                qui predict double `resid_x_`cname'', residuals
            }
            else {
                tempvar resid_x_`cname'
                qui gen double `resid_x_`cname'' = rnormal()
            }
        }

        // Save coefficient matrices for restricted y-model
        qui regress `lhs' `restr_rhsvars'
        tempname b_y_r
        mat `b_y_r' = e(b)
    }

    // =========================================================================
    // METHOD B: Bertelli et al. (2022) — Conditional Bootstrap
    // =========================================================================
    else {
        // (1) Full unrestricted model
        qui regress `lhs' `rhsvars'
        tempvar resid_full
        qui predict double `resid_full', residuals

        // (2) Restricted for Fov: drop all lagged levels
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

        // (3) Restricted for t: drop L.depvar only
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

        // (4) Restricted for Find: drop lagged levels of decomposed vars
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

        // VECM equations for each decomposed x
        foreach dvar of local decomp_vars {
            local cname = subinstr("`dvar'", ".", "_", .)
            local cname = subinstr("`cname'", "_mt_", "mt", .)
            local xreg "`levelvars'"
            forvalues j = 1/`best_p' {
                local xreg "`xreg' L`j'.D.`depvar'"
            }
            capture qui regress D.`dvar' `xreg'
            if _rc == 0 {
                tempvar resid_vecm_`cname'
                qui predict double `resid_vecm_`cname'', residuals
                tempname b_vecm_`cname'
                mat `b_vecm_`cname'' = e(b)
            }
            else {
                tempvar resid_vecm_`cname'
                qui gen double `resid_vecm_`cname'' = rnormal()
            }
        }
    }

    // =========================================================================
    // BOOTSTRAP LOOP — Exactly follows fbardl pattern
    // =========================================================================
    mata {
        boot_Fov  = J(`reps', 1, .)
        boot_t    = J(`reps', 1, .)
        boot_Find = J(`reps', 1, .)
    }

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
        if "`bootstrap_type'" == "mtnardl_mcnown" {
            // McNown: use restricted y residuals
            tempvar ridx
            qui gen `ridx' = ceil(uniform() * `NN')
            qui replace `ridx' = max(1, min(`NN', `ridx'))

            // Bootstrap y
            tempvar dy_star y_star
            qui gen double `dy_star' = D.`depvar' + `resid_y_restr'[`ridx'] - `resid_y_restr'
            qui gen double `y_star' = L.`depvar' + `dy_star' if _n > 1
            qui replace `y_star' = `depvar'[1] if _n == 1
            qui replace `depvar' = `y_star'

            // Bootstrap decomposed x variables
            foreach dvar of local decomp_vars {
                local cname = subinstr("`dvar'", ".", "_", .)
                local cname = subinstr("`cname'", "_mt_", "mt", .)
                tempvar dx_star_`cname' x_star_`cname'
                qui gen double `dx_star_`cname'' = D.`dvar' + `resid_x_`cname''[`ridx'] - `resid_x_`cname''
                qui gen double `x_star_`cname'' = L.`dvar' + `dx_star_`cname'' if _n > 1
                qui replace `x_star_`cname'' = `dvar'[1] if _n == 1
                qui replace `dvar' = `x_star_`cname''
            }
        }
        else {
            // Bertelli: use restricted residuals
            tempvar ridx
            qui gen `ridx' = ceil(uniform() * `NN')
            qui replace `ridx' = max(1, min(`NN', `ridx'))

            tempvar dy_star y_star
            qui gen double `dy_star' = D.`depvar' + `resid_Fov'[`ridx'] - `resid_Fov'
            qui gen double `y_star' = L.`depvar' + `dy_star' if _n > 1
            qui replace `y_star' = `depvar'[1] if _n == 1
            qui replace `depvar' = `y_star'

            foreach dvar of local decomp_vars {
                local cname = subinstr("`dvar'", ".", "_", .)
                local cname = subinstr("`cname'", "_mt_", "mt", .)
                capture {
                    tempvar dx_s_`cname' x_s_`cname'
                    qui gen double `dx_s_`cname'' = D.`dvar' + `resid_vecm_`cname''[`ridx'] - `resid_vecm_`cname''
                    qui gen double `x_s_`cname'' = L.`dvar' + `dx_s_`cname'' if _n > 1
                    qui replace `x_s_`cname'' = `dvar'[1] if _n == 1
                    qui replace `dvar' = `x_s_`cname''
                }
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
    di as txt ""

    // =========================================================================
    // COMPUTE BOOTSTRAP CRITICAL VALUES AND P-VALUES
    // Follows fbardl pattern exactly: mata block + st_numscalar
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

        // Store to Stata via st_numscalar
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

    // Return results (via r() scalars set by Mata)
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
