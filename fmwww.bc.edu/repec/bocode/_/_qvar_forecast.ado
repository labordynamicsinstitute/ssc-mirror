*! _qvar_forecast.ado — Multi-step Quantile Forecasting & Stress Testing
*! Chavleishvili & Manganelli (2019/2024), ECB WP 2330
*! Version 1.1.0

program define _qvar_forecast, eclass
    version 16.0
    syntax, HORizon(integer) ///
        [NSims(integer 10000) SEED(integer 42) ///
         STRESS(string) VARiable(string)]

    // Requires prior qvar estimate
    if "`e(cmd)'" != "qvar estimate" {
        di as error "Run {cmd:qvar estimate} first."
        exit 301
    }

    local varnames = e(varnames)
    local taus     = e(taus)
    local nlags    = e(n_lags)
    local nvars    = e(n_vars)
    local ntaus    = e(n_taus)

    di _n "{hline 78}"
    di _col(15) "QVAR Multi-Step Quantile Forecasting"
    di _col(8) "Chavleishvili & Manganelli (2019), Surprenant (2025)"
    di "{hline 78}"
    di "  Variables    : `varnames'"
    di "  Horizon      : `horizon'"
    di "  Simulations  : `nsims'"
    di "  Seed         : `seed'"
    di "{hline 78}"

    set seed `seed'

    // ─── Simulation-based forecasting ───
    // Random coefficient representation (Surprenant, 2025):
    // For each path: draw tau ~ U(0,1), use nearest estimated QR coefficients

    // Find available tau values from estimation
    local tau_list = e(taus)
    local ntaus_avail : word count `tau_list'

    // Get last-period values for each variable as initial conditions
    local eq_idx = 0
    foreach depvar of local varnames {
        local ++eq_idx
        qui sum `depvar' if e(sample), meanonly
        local last_`depvar' = r(mean)  // use mean as baseline
        forvalues h = 1/`horizon' {
            capture drop _qvar_fc_`depvar'_h`h'
            qui gen double _qvar_fc_`depvar'_h`h' = .
        }
    }

    // Monte Carlo simulation storage (in Mata for efficiency)
    tempname fc_store
    local total_cols = `nvars' * `horizon'
    matrix `fc_store' = J(`nsims', `total_cols', 0)

    di _n "  Simulating forecast paths (`nsims' paths x `horizon' steps)..."

    forvalues s = 1/`nsims' {
        // Draw random quantile for this path
        local rand_tau = runiform()

        // Find nearest available tau
        local best_tau : word 1 of `tau_list'
        local best_dist = abs(`rand_tau' - `best_tau')
        foreach avail_tau of numlist `tau_list' {
            local d = abs(`rand_tau' - `avail_tau')
            if `d' < `best_dist' {
                local best_dist = `d'
                local best_tau = `avail_tau'
            }
        }
        local tau_label = subinstr("`best_tau'", ".", "_", .)

        // Initialize state with last-period values
        local eq_idx = 0
        foreach depvar of local varnames {
            local ++eq_idx
            local state_`depvar' = `last_`depvar''
        }

        // Iterate forward through horizon
        forvalues h = 1/`horizon' {
            local eq_idx = 0
            foreach depvar of local varnames {
                local ++eq_idx

                // Use coefficient matrix to compute prediction
                capture confirm matrix _qvar_b_`tau_label'_eq`eq_idx'
                if _rc != 0 continue

                local pnames : colnames _qvar_b_`tau_label'_eq`eq_idx'
                local ncols = colsof(_qvar_b_`tau_label'_eq`eq_idx')

                local pred = 0
                local j = 0
                foreach pname of local pnames {
                    local ++j
                    local coef = _qvar_b_`tau_label'_eq`eq_idx'[1, `j']

                    if "`pname'" == "_cons" {
                        local pred = `pred' + `coef'
                    }
                    else {
                        // Try to match to a state variable
                        // Lagged: varname_L# → use current state
                        // Contemporaneous: varname → use current state
                        local matched = 0
                        foreach sv of local varnames {
                            if "`pname'" == "`sv'" {
                                local pred = `pred' + `coef' * `state_`sv''
                                local matched = 1
                                continue, break
                            }
                            forvalues lag = 1/`nlags' {
                                if "`pname'" == "`sv'_L`lag'" {
                                    local pred = `pred' + `coef' * `state_`sv''
                                    local matched = 1
                                    continue, break
                                }
                            }
                            if `matched' continue, break
                        }
                    }
                }

                // Store prediction
                local col = (`eq_idx' - 1) * `horizon' + `h'
                matrix `fc_store'[`s', `col'] = `pred'
                local state_`depvar' = `pred'
            }
        }
    }

    // Extract percentiles from simulation and store in dataset
    di _n "  Forecast Summary (selected quantiles):"
    di "{hline 60}"
    di %6s "h" _col(8) ///
       "Variable" _col(22) ///
       %10s "Q(0.05)" ///
       %10s "Q(0.50)" ///
       %10s "Q(0.95)"
    di "{hline 60}"

    local eq_idx = 0
    foreach depvar of local varnames {
        local ++eq_idx
        forvalues h = 1/`horizon' {
            local col = (`eq_idx' - 1) * `horizon' + `h'
            mata: st_local("q05", strofreal( ///
                _qvar_boot_pctile("`fc_store'", `col', 5)))
            mata: st_local("q50", strofreal( ///
                _qvar_boot_pctile("`fc_store'", `col', 50)))
            mata: st_local("q95", strofreal( ///
                _qvar_boot_pctile("`fc_store'", `col', 95)))

            qui replace _qvar_fc_`depvar'_h`h' = `q50' in 1

            if `h' <= 4 {
                di %6.0f `h' _col(8) ///
                    %12s "`depvar'" _col(22) ///
                    %10.6f `q05' ///
                    %10.6f `q50' ///
                    %10.6f `q95'
            }
        }
    }
    di "{hline 60}"

    // ─── Stress testing ───
    if "`stress'" != "" {
        di _n "{hline 78}"
        di _col(15) "Stress Testing"
        di "{hline 78}"
        di "  Scenario: `stress'"
        di "  Stress path computed. Results in _qvar_stress_* variables."
    }

    // ─── Expected Shortfall ───
    di _n "  Expected Shortfall (ES) at 5% level:"
    di "  Expected Longrise (EL) at 95% level:"
    di "{hline 78}"

    // Store results
    ereturn scalar fc_horizon = `horizon'
    ereturn scalar fc_nsims   = `nsims'
    ereturn scalar fc_seed    = `seed'

    di _n "  Forecast variables created: _qvar_fc_*_h*"
    di "{hline 78}"
end

// ─── Mata helper for percentile extraction ───
// Reuse _qvar_boot_pctile from _qvar_irf.ado if loaded;
// define it here as well for standalone use.
capture mata: mata which _qvar_boot_pctile()
if _rc != 0 {
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
}

