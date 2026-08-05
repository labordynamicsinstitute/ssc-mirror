*! _qardl_rolling v1.2.0 - Rolling window QARDL estimation
*! Translates rollingQardl() from GAUSS QARDL 3.1.1 (qardl.src)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _qardl_rolling, rclass
    version 14.0

    * The shared Wald Mata routines live in _qardl_waldtest.ado so that
    * postestimation commands can use them without qardl.ado having been
    * loaded first.  Pull them in if they are not already compiled.
    capture mata which _qardl_wald_stat()
    if _rc {
        capture program drop _qardl_waldtest
        qui findfile _qardl_waldtest.ado
        qui run "`r(fn)'"
    }

    syntax varlist(min=2 numeric ts) [if] [in], P(integer) Q(integer) ///
        TAU(numlist >0 <1 sort) WINdow(integer) ///
        [NOCONStant COVariance(string) HAClags(integer 0) ECM]

    marksample touse

    gettoken depvar indepvars : varlist
    local k : word count `indepvars'

    if "`covariance'" == "" local covariance "iid"

    qui count if `touse'
    local nobs = r(N)

    if `window' == 0 {
        local window = max(int(`nobs' * 0.1), `p' + `q' + `k' + 10)
    }

    local num_est = `nobs' - `window'
    if `num_est' < 1 {
        di as error "window too large for available observations"
        exit 198
    }

    local ntau : word count `tau'

    * Get first and last obs numbers
    tempvar obsnum
    qui gen long `obsnum' = _n if `touse'
    qui sum `obsnum' if `touse', meanonly
    local first_obs = r(min)
    local last_obs = r(max)

    * Storage matrices
    local beta_cols = `k' * `ntau'
    local gamma_cols = `k' * `ntau'
    local phi_cols = `p' * `ntau'

    tempname rbeta rgamma rphi rbeta_se rgamma_se rphi_se
    tempname rwald_beta rwald_phi rwald_gamma

    mat `rbeta' = J(`num_est', `beta_cols', .)
    mat `rgamma' = J(`num_est', `gamma_cols', .)
    mat `rphi' = J(`num_est', `phi_cols', .)
    mat `rbeta_se' = J(`num_est', `beta_cols', .)
    mat `rgamma_se' = J(`num_est', `gamma_cols', .)
    mat `rphi_se' = J(`num_est', `phi_cols', .)

    * Wald matrices: column 1 = statistic, column 2 = p-value, column 3 = df
    mat `rwald_beta' = J(`num_est', 3, .)
    mat `rwald_phi' = J(`num_est', 3, .)
    mat `rwald_gamma' = J(`num_est', 3, .)

    * Rolling two-step ECM (rollingQardlECM in GAUSS)
    tempname ralpha rrho
    if "`ecm'" != "" {
        capture mata which _qardl_ecm2_estimate()
        if _rc {
            capture program drop _qardl_ecm2
            qui findfile _qardl_ecm2.ado
            qui run "`r(fn)'"
        }
        mat `ralpha' = J(`num_est', `ntau', .)
        mat `rrho' = J(`num_est', `ntau', .)
    }
    else {
        mat `ralpha' = J(1, 1, .)
        mat `rrho' = J(1, 1, .)
    }

    * Rolling estimation loop
    tempvar roll_touse
    qui gen byte `roll_touse' = 0

    local nfail = 0

    forvalues w = 1/`num_est' {
        local win_start = `first_obs' + `w' - 1
        local win_end = `win_start' + `window' - 1

        * Set rolling window sample
        qui replace `roll_touse' = (`obsnum' >= `win_start' & `obsnum' <= `win_end')

        * Estimate on this window
        capture noisily {
            qui _qardl_estimate `varlist' if `roll_touse', p(`p') q(`q') ///
                tau(`tau') covariance(`covariance') haclags(`haclags') ///
                `noconstant'

            tempname wbeta wbeta_cov wphi wphi_cov wgamma wgamma_cov
            mat `wbeta' = r(beta)
            mat `wbeta_cov' = r(beta_cov)
            mat `wphi' = r(phi)
            mat `wphi_cov' = r(phi_cov)
            mat `wgamma' = r(gamma)
            mat `wgamma_cov' = r(gamma_cov)

            local wsc_beta = r(scale_beta)
            local wsc_short = r(scale_short)

            * Store beta estimates and SEs
            local ncb = min(rowsof(`wbeta'), `beta_cols')
            forvalues j = 1/`ncb' {
                mat `rbeta'[`w', `j'] = `wbeta'[`j', 1]
                if `wbeta_cov'[`j', `j'] > 0 {
                    mat `rbeta_se'[`w', `j'] = ///
                        sqrt(`wbeta_cov'[`j', `j'] / `wsc_beta')
                }
            }

            * Store gamma estimates and SEs
            local ncg = min(rowsof(`wgamma'), `gamma_cols')
            forvalues j = 1/`ncg' {
                mat `rgamma'[`w', `j'] = `wgamma'[`j', 1]
                if `wgamma_cov'[`j', `j'] > 0 {
                    mat `rgamma_se'[`w', `j'] = ///
                        sqrt(`wgamma_cov'[`j', `j'] / `wsc_short')
                }
            }

            * Store phi estimates and SEs
            local ncp = min(rowsof(`wphi'), `phi_cols')
            forvalues j = 1/`ncp' {
                mat `rphi'[`w', `j'] = `wphi'[`j', 1]
                if `wphi_cov'[`j', `j'] > 0 {
                    mat `rphi_se'[`w', `j'] = ///
                        sqrt(`wphi_cov'[`j', `j'] / `wsc_short')
                }
            }

            * ------------------------------------------------------
            * Cross-quantile constancy Wald tests for this window.
            * GAUSS rollingQardl() calls wtestlrb / wtestsrp / wtestsrg
            * once per window; these are the corresponding statistics.
            * ------------------------------------------------------
            if `ntau' >= 2 {
                _qardl_roll_wald `wbeta' `wbeta_cov' `k' `ntau' `wsc_beta'
                mat `rwald_beta'[`w', 1] = r(wald)
                mat `rwald_beta'[`w', 2] = r(pval)
                mat `rwald_beta'[`w', 3] = r(df)

                _qardl_roll_wald `wphi' `wphi_cov' `p' `ntau' `wsc_short'
                mat `rwald_phi'[`w', 1] = r(wald)
                mat `rwald_phi'[`w', 2] = r(pval)
                mat `rwald_phi'[`w', 3] = r(df)

                _qardl_roll_wald `wgamma' `wgamma_cov' `k' `ntau' `wsc_short'
                mat `rwald_gamma'[`w', 1] = r(wald)
                mat `rwald_gamma'[`w', 2] = r(pval)
                mat `rwald_gamma'[`w', 3] = r(df)
            }

            * Two-step ECM on the same window
            if "`ecm'" != "" {
                qui _qardl_ecm2 `varlist' if `roll_touse', p(`p') q(`q') ///
                    tau(`tau') covariance(iid)
                tempname wa wr
                mat `wa' = r(alpha)
                mat `wr' = r(rho)
                forvalues j = 1/`ntau' {
                    mat `ralpha'[`w', `j'] = `wa'[`j', 1]
                    mat `rrho'[`w', `j'] = `wr'[`j', 1]
                }
            }
        }
        if _rc {
            local ++nfail
        }

        * Progress indicator
        if mod(`w', 50) == 0 {
            di as txt "  Rolling window `w' of `num_est' completed"
        }
    }

    * Column names make the stored matrices self-documenting
    local bnames ""
    local gnames ""
    local pnames ""
    local ti = 0
    foreach t of local tau {
        local ++ti
        foreach v of local indepvars {
            local bnames "`bnames' b_`v'_t`ti'"
            local gnames "`gnames' g_`v'_t`ti'"
        }
        forvalues j = 1/`p' {
            local pnames "`pnames' phi`j'_t`ti'"
        }
    }
    capture mat colnames `rbeta' = `bnames'
    capture mat colnames `rbeta_se' = `bnames'
    capture mat colnames `rgamma' = `gnames'
    capture mat colnames `rgamma_se' = `gnames'
    capture mat colnames `rphi' = `pnames'
    capture mat colnames `rphi_se' = `pnames'
    capture mat colnames `rwald_beta' = wald pvalue df
    capture mat colnames `rwald_phi' = wald pvalue df
    capture mat colnames `rwald_gamma' = wald pvalue df

    * Summary
    di as txt _n "{hline 70}"
    di as res "  Rolling QARDL Summary"
    di as txt "{hline 70}"
    di as txt "  Number of windows  : " as res `num_est'
    di as txt "  Window size        : " as res `window'
    if `nfail' > 0 {
        di as res "  Failed windows     : " `nfail' " (stored as missing)"
    }
    di as txt "{hline 70}"

    * Return results
    return matrix rolling_beta = `rbeta'
    return matrix rolling_gamma = `rgamma'
    return matrix rolling_phi = `rphi'
    return matrix rolling_beta_se = `rbeta_se'
    return matrix rolling_gamma_se = `rgamma_se'
    return matrix rolling_phi_se = `rphi_se'
    return matrix rolling_wald_beta = `rwald_beta'
    return matrix rolling_wald_phi = `rwald_phi'
    return matrix rolling_wald_gamma = `rwald_gamma'
    return matrix rolling_alpha = `ralpha'
    return matrix rolling_rho = `rrho'
    return scalar window = `window'
    return scalar num_est = `num_est'
    return scalar nfail = `nfail'
end

* ============================================================
* One cross-quantile constancy Wald test for a rolling window
* ============================================================
capture program drop _qardl_roll_wald
program define _qardl_roll_wald, rclass
    args param cov dim ntau scale

    return scalar wald = .
    return scalar pval = .
    return scalar df = .

    if rowsof(`param') < `dim' * `ntau' exit
    if rowsof(`cov') < `dim' * `ntau' exit

    tempname R r W
    capture mata: _qardl_build_constancy_R(`dim', `ntau', "`R'", "`r'")
    if _rc exit

    capture mata: _qardl_wald_stat("`param'", "`cov'", "`R'", "`r'", `scale', "`W'")
    if _rc exit

    local wstat = `W'[1,1]
    local df = `W'[2,1]
    if `df' < 1 exit
    if `wstat' >= . exit

    return scalar wald = `wstat'
    return scalar df = `df'
    return scalar pval = chi2tail(`df', `wstat')
end
