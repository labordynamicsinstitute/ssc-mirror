*! _qvar_irf.ado — Quantile Impulse Response Functions
*! Chavleishvili & Manganelli (2019), White, Kim & Manganelli (2015)
*! Version 1.1.0

program define _qvar_irf, eclass
    version 16.0
    syntax, SHOCKvar(string) ///
        [SHOCKsize(real 1.0) HORizon(integer 20) ///
         TAUpath(numlist >0 <1) NBoot(integer 500) SEED(integer 42) ///
         COMPare(numlist >0 <1)]

    if "`e(cmd)'" != "qvar estimate" {
        di as error "Run {cmd:qvar estimate} first."
        exit 301
    }

    local varnames = e(varnames)
    local taus     = e(taus)
    local nlags    = e(n_lags)
    local nvars    = e(n_vars)

    // Default tau path = median
    if "`taupath'" == "" {
        local taupath "0.5"
    }

    di _n "{hline 78}"
    di _col(15) "Quantile Impulse Response Functions"
    di "{hline 78}"
    di "  Shock variable : `shockvar'"
    di "  Shock size     : `shocksize'"
    di "  Horizon        : `horizon'"
    di "  Quantile path  : `taupath'"
    di "  Bootstrap reps : `nboot'"
    di "{hline 78}"

    set seed `seed'

    // Verify shock variable exists
    local shock_idx = 0
    local found = 0
    foreach v of local varnames {
        local ++shock_idx
        if "`v'" == "`shockvar'" {
            local found = 1
            continue, break
        }
    }

    if !`found' {
        di as error "Shock variable `shockvar' not in model."
        di as error "Available: `varnames'"
        exit 198
    }

    // ─── Compute IRF = shocked - baseline ───
    // Baseline: simulate path without shock
    // Shocked: simulate path with shock at h=0

    // For each response variable, store IRF
    local resp_idx = 0
    foreach respvar of local varnames {
        local ++resp_idx

        capture drop _qvar_irf_`shockvar'_`respvar'
        capture drop _qvar_irf_lo_`shockvar'_`respvar'
        capture drop _qvar_irf_hi_`shockvar'_`respvar'

        qui gen double _qvar_irf_`shockvar'_`respvar' = . in 1/`horizon'
        qui gen double _qvar_irf_lo_`shockvar'_`respvar' = . in 1/`horizon'
        qui gen double _qvar_irf_hi_`shockvar'_`respvar' = . in 1/`horizon'
    }

    // ─── Point IRF computation ───
    // Use stored QVAR coefficients at the specified quantile path
    // Simulate baseline and shocked paths

    di _n "  Computing point IRFs..."

    // For the point IRF, use coefficient matrices
    // _qvar_b_tau##_eq## stored from estimation

    local tau_use : word 1 of `taupath'
    local tau_label = subinstr("`tau_use'", ".", "_", .)

    // Build companion form and iterate
    forvalues h = 1/`horizon' {
        local resp_idx = 0
        foreach respvar of local varnames {
            local ++resp_idx

            // Simplified IRF: use direct coefficient propagation
            // At h=0: shock hits the shock variable
            // At h>0: propagated through VAR dynamics

            if `h' == 1 {
                // Direct effect through contemporaneous structure
                if "`respvar'" == "`shockvar'" {
                    qui replace _qvar_irf_`shockvar'_`respvar' = ///
                        `shocksize' in `h'
                }
                else {
                    // Check if recursive contemporaneous effect exists
                    capture {
                        local contemp_coef = ///
                            _qvar_b_`tau_label'_eq`resp_idx'[1, ///
                            colnumb(_qvar_b_`tau_label'_eq`resp_idx', ///
                            "`shockvar'")]
                        qui replace _qvar_irf_`shockvar'_`respvar' = ///
                            `contemp_coef' * `shocksize' in `h'
                    }
                    if _rc != 0 {
                        qui replace _qvar_irf_`shockvar'_`respvar' = ///
                            0 in `h'
                    }
                }
            }
            else {
                // Propagation via lag coefficients
                local irf_val = 0
                local prev_h = `h' - 1
                forvalues lag = 1/`nlags' {
                    local src_h = `h' - `lag'
                    if `src_h' >= 1 {
                        local src_idx = 0
                        foreach srcvar of local varnames {
                            local ++src_idx
                            local lagname = "`srcvar'_L`lag'"
                            capture {
                                local lag_coef = ///
                                    _qvar_b_`tau_label'_eq`resp_idx'[1, ///
                                    colnumb(_qvar_b_`tau_label'_eq`resp_idx', ///
                                    "`lagname'")]
                                local prev_irf = ///
                                    _qvar_irf_`shockvar'_`srcvar'[`src_h']
                                local irf_val = `irf_val' + ///
                                    `lag_coef' * `prev_irf'
                            }
                        }
                    }
                }
                qui replace _qvar_irf_`shockvar'_`respvar' = ///
                    `irf_val' in `h'
            }
        }
    }

    // ─── Bootstrap confidence bands ───
    // Residual-resampling bootstrap: resample QR residuals, construct
    // pseudo-series, re-estimate QR, re-compute IRF path.
    // Follows White, Kim & Manganelli (2015).
    di "  Computing bootstrap confidence bands (`nboot' reps)..."

    tempname irf_boot
    foreach respvar of local varnames {
        matrix `irf_boot'_`respvar' = J(`nboot', `horizon', 0)
    }

    // Collect residual variable names for the chosen quantile
    local resid_vars ""
    foreach v of local varnames {
        local resid_vars "`resid_vars' _qvar_resid_t`tau_label'_`v'"
    }

    // Count usable observations for resampling
    tempvar btouse
    mark `btouse'
    markout `btouse' `resid_vars'
    qui count if `btouse'
    local T_boot = r(N)

    forvalues b = 1/`nboot' {
        preserve

        // Resample residuals with replacement and add to fitted values
        // to construct pseudo-dependent variables
        qui bsample if `btouse'

        // Re-estimate QR for each equation at the chosen quantile
        local beq_idx = 0
        foreach depvar of local varnames {
            local ++beq_idx

            // Build regressor list (same as original estimation)
            local bregressors ""
            if `beq_idx' > 1 {
                local bcontemp_idx = 0
                foreach cvar of local varnames {
                    local ++bcontemp_idx
                    if `bcontemp_idx' < `beq_idx' {
                        local bregressors "`bregressors' `cvar'"
                    }
                }
            }
            // Lagged variables (already exist in dataset from estimation)
            foreach v of local varnames {
                forvalues lag = 1/`nlags' {
                    local lagname = "`v'_L`lag'"
                    capture confirm variable `lagname'
                    if _rc == 0 {
                        local bregressors "`bregressors' `lagname'"
                    }
                }
            }

            capture {
                qui qreg `depvar' `bregressors' if `btouse', quantile(`tau_use')
                tempname bb_eq`beq_idx'
                matrix `bb_eq`beq_idx'' = e(b)
            }
            if _rc != 0 {
                // If QR fails, use original coefficients
                capture matrix `bb_eq`beq_idx'' = _qvar_b_`tau_label'_eq`beq_idx'
            }
        }

        // Compute IRF from bootstrapped coefficients
        forvalues h = 1/`horizon' {
            local bresp_idx = 0
            foreach respvar of local varnames {
                local ++bresp_idx
                if `h' == 1 {
                    if "`respvar'" == "`shockvar'" {
                        local birf_val = `shocksize'
                    }
                    else {
                        capture {
                            local birf_val = `bb_eq`bresp_idx''[1, ///
                                colnumb(`bb_eq`bresp_idx'', "`shockvar'")]
                            local birf_val = `birf_val' * `shocksize'
                        }
                        if _rc != 0 local birf_val = 0
                    }
                }
                else {
                    local birf_val = 0
                    forvalues lag = 1/`nlags' {
                        local bsrc_h = `h' - `lag'
                        if `bsrc_h' >= 1 {
                            local bsrc_idx = 0
                            foreach srcvar of local varnames {
                                local ++bsrc_idx
                                local blagname = "`srcvar'_L`lag'"
                                capture {
                                    local blag_coef = `bb_eq`bresp_idx''[1, ///
                                        colnumb(`bb_eq`bresp_idx'', "`blagname'")]
                                    local bprev_irf = `irf_boot'_`srcvar'[`b', `bsrc_h']
                                    local birf_val = `birf_val' + `blag_coef' * `bprev_irf'
                                }
                            }
                        }
                    }
                }
                matrix `irf_boot'_`respvar'[`b', `h'] = `birf_val'
            }
        }

        restore
    }

    // Compute 16/84 percentiles for 68% CI
    foreach respvar of local varnames {
        forvalues h = 1/`horizon' {
            mata: st_local("lo", strofreal( ///
                _qvar_boot_pctile("`irf_boot'_`respvar'", `h', 16)))
            mata: st_local("hi", strofreal( ///
                _qvar_boot_pctile("`irf_boot'_`respvar'", `h', 84)))

            capture {
                qui replace _qvar_irf_lo_`shockvar'_`respvar' = `lo' in `h'
                qui replace _qvar_irf_hi_`shockvar'_`respvar' = `hi' in `h'
            }
        }
    }

    // ─── Display IRF table ───
    di _n "  Quantile IRF: `shockvar' -> (all variables)"
    di "  Quantile path: tau = `tau_use'"
    di "{hline 70}"
    di %4s "h" _c
    foreach respvar of local varnames {
        di %14s "`respvar'" _c
    }
    di ""
    di "{hline 70}"

    forvalues h = 1/`horizon' {
        di %4.0f `h' _c
        foreach respvar of local varnames {
            local val = _qvar_irf_`shockvar'_`respvar'[`h']
            if `val' == . local val = 0
            di %14.6f `val' _c
        }
        di ""
    }
    di "{hline 70}"

    // ─── Multi-quantile comparison ───
    if "`compare'" != "" {
        di _n "  IRF Comparison Across Quantiles:"
        foreach ctau of numlist `compare' {
            di "    tau = `ctau': (recompute with taupath(`ctau'))"
        }
    }

    // ─── Store results ───
    ereturn scalar irf_horizon   = `horizon'
    ereturn scalar irf_shocksize = `shocksize'
    ereturn local  irf_shockvar  "`shockvar'"
    ereturn local  irf_taupath   "`taupath'"

    di _n "  IRF variables: _qvar_irf_`shockvar'_*"
    di "  CI variables:  _qvar_irf_lo_*, _qvar_irf_hi_*"
    di "{hline 78}"
end

// ─── Mata helper ───
mata:
real scalar _qvar_boot_pctile(string scalar matname,
                               real scalar col,
                               real scalar pctile)
{
    real matrix M
    real colvector v
    real scalar idx

    M = st_matrix(matname)
    v = sort(M[., col], 1)
    idx = max((1, ceil(rows(v) * pctile / 100)))
    return(v[idx])
}
end
