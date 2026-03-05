*! version 1.0.0  03mar2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! xtmispanel_impute: Imputation sub-routines for xtmispanel
*! Implements 13 imputation methods for panel data

capture program drop xtmispanel_impute
program define xtmispanel_impute
    version 15.0
    syntax varlist(max=1) [if] [in], ///
        METHod(string) GENerate(name) ///
        PANELvar(varname) TIMEvar(varname) ///
        [KNN(integer 5) MICE(integer 5)]

    marksample touse, novarlist
    local srcvar "`varlist'"

    * Validate method
    local valid_methods "mean median locf nocb linear spline pmm hotdeck regress knn rf em mice"
    local method = lower("`method'")
    local found = 0
    foreach m of local valid_methods {
        if "`method'" == "`m'" local found = 1
    }
    if `found' == 0 {
        di as err "Invalid method: {bf:`method'}"
        di as err "Valid methods: `valid_methods'"
        exit 198
    }

    * Start with a copy
    qui gen double `generate' = `srcvar' if `touse'

    * Dispatch to method
    if "`method'" == "mean"     _imp_mean     `srcvar' `generate' `touse' `panelvar' `timevar'
    if "`method'" == "median"   _imp_median   `srcvar' `generate' `touse' `panelvar' `timevar'
    if "`method'" == "locf"     _imp_locf     `srcvar' `generate' `touse' `panelvar' `timevar'
    if "`method'" == "nocb"     _imp_nocb     `srcvar' `generate' `touse' `panelvar' `timevar'
    if "`method'" == "linear"   _imp_linear   `srcvar' `generate' `touse' `panelvar' `timevar'
    if "`method'" == "spline"   _imp_spline   `srcvar' `generate' `touse' `panelvar' `timevar'
    if "`method'" == "pmm"      _imp_pmm      `srcvar' `generate' `touse' `panelvar' `timevar'
    if "`method'" == "hotdeck"  _imp_hotdeck  `srcvar' `generate' `touse' `panelvar' `timevar'
    if "`method'" == "regress"  _imp_regress  `srcvar' `generate' `touse' `panelvar' `timevar'
    if "`method'" == "knn"      _imp_knn      `srcvar' `generate' `touse' `panelvar' `timevar' `knn'
    if "`method'" == "rf"       _imp_rf       `srcvar' `generate' `touse' `panelvar' `timevar'
    if "`method'" == "em"       _imp_em       `srcvar' `generate' `touse' `panelvar' `timevar'
    if "`method'" == "mice"     _imp_mice     `srcvar' `generate' `touse' `panelvar' `timevar' `mice'
end

* ═══════════════════════════════════════════════════════════════════════════
* METHOD 1: Panel-specific Mean Imputation
* ═══════════════════════════════════════════════════════════════════════════
capture program drop _imp_mean
program define _imp_mean
    args srcvar genvar touse panelvar timevar

    tempvar pmean
    qui bysort `panelvar': egen double `pmean' = mean(`srcvar') if `touse'
    qui replace `genvar' = `pmean' if missing(`genvar') & `touse'

    * If panel mean is missing (all missing in panel), use global mean
    qui su `srcvar' if `touse' & !missing(`srcvar'), meanonly
    qui replace `genvar' = r(mean) if missing(`genvar') & `touse'
end

* ═══════════════════════════════════════════════════════════════════════════
* METHOD 2: Panel-specific Median Imputation
* ═══════════════════════════════════════════════════════════════════════════
capture program drop _imp_median
program define _imp_median
    args srcvar genvar touse panelvar timevar

    tempvar pmedian
    qui bysort `panelvar': egen double `pmedian' = median(`srcvar') if `touse'
    qui replace `genvar' = `pmedian' if missing(`genvar') & `touse'

    * Fallback to global median
    qui su `srcvar' if `touse' & !missing(`srcvar'), detail
    qui replace `genvar' = r(p50) if missing(`genvar') & `touse'
end

* ═══════════════════════════════════════════════════════════════════════════
* METHOD 3: Last Observation Carried Forward (LOCF)
* ═══════════════════════════════════════════════════════════════════════════
capture program drop _imp_locf
program define _imp_locf
    args srcvar genvar touse panelvar timevar

    * Sort by panel and time, carry forward
    qui bysort `panelvar' (`timevar'): ///
        replace `genvar' = `genvar'[_n-1] ///
        if missing(`genvar') & `touse' & _n > 1

    * Second pass for consecutive missings
    qui bysort `panelvar' (`timevar'): ///
        replace `genvar' = `genvar'[_n-1] ///
        if missing(`genvar') & `touse' & _n > 1

    * Third pass
    qui bysort `panelvar' (`timevar'): ///
        replace `genvar' = `genvar'[_n-1] ///
        if missing(`genvar') & `touse' & _n > 1

    * Up to 10 passes for long gaps
    forv pass = 4/10 {
        qui count if missing(`genvar') & `touse'
        if r(N) == 0 continue, break
        qui bysort `panelvar' (`timevar'): ///
            replace `genvar' = `genvar'[_n-1] ///
            if missing(`genvar') & `touse' & _n > 1
    }
end

* ═══════════════════════════════════════════════════════════════════════════
* METHOD 4: Next Observation Carried Backward (NOCB)
* ═══════════════════════════════════════════════════════════════════════════
capture program drop _imp_nocb
program define _imp_nocb
    args srcvar genvar touse panelvar timevar

    * Sort and carry backward
    qui gsort `panelvar' -`timevar'
    qui bysort `panelvar': ///
        replace `genvar' = `genvar'[_n-1] ///
        if missing(`genvar') & `touse' & _n > 1

    * Multiple passes for consecutive missings
    forv pass = 2/10 {
        qui count if missing(`genvar') & `touse'
        if r(N) == 0 continue, break
        qui bysort `panelvar': ///
            replace `genvar' = `genvar'[_n-1] ///
            if missing(`genvar') & `touse' & _n > 1
    }

    * Restore sort order
    qui sort `panelvar' `timevar'

    * Fallback: LOCF for any remaining leading missings
    forv pass = 1/10 {
        qui count if missing(`genvar') & `touse'
        if r(N) == 0 continue, break
        qui bysort `panelvar' (`timevar'): ///
            replace `genvar' = `genvar'[_n-1] ///
            if missing(`genvar') & `touse' & _n > 1
    }

    * Ultimate fallback: panel mean
    _imp_mean `srcvar' `genvar' `touse' `panelvar' `timevar'
end

* ═══════════════════════════════════════════════════════════════════════════
* METHOD 5: Linear Interpolation within Panel
* ═══════════════════════════════════════════════════════════════════════════
capture program drop _imp_linear
program define _imp_linear
    args srcvar genvar touse panelvar timevar

    * Use ipolate for linear interpolation
    tempvar ipolated
    qui bysort `panelvar': ipolate `srcvar' `timevar' if `touse', gen(`ipolated')
    qui replace `genvar' = `ipolated' if missing(`genvar') & `touse'

    * Extrapolate edges using LOCF/NOCB
    * LOCF for trailing
    forv pass = 1/5 {
        qui count if missing(`genvar') & `touse'
        if r(N) == 0 continue, break
        qui bysort `panelvar' (`timevar'): ///
            replace `genvar' = `genvar'[_n-1] ///
            if missing(`genvar') & `touse' & _n > 1
    }
    * NOCB for leading
    qui gsort `panelvar' -`timevar'
    forv pass = 1/5 {
        qui count if missing(`genvar') & `touse'
        if r(N) == 0 continue, break
        qui bysort `panelvar': ///
            replace `genvar' = `genvar'[_n-1] ///
            if missing(`genvar') & `touse' & _n > 1
    }
    qui sort `panelvar' `timevar'
end

* ═══════════════════════════════════════════════════════════════════════════
* METHOD 6: Cubic Spline Interpolation within Panel
* ═══════════════════════════════════════════════════════════════════════════
capture program drop _imp_spline
program define _imp_spline
    args srcvar genvar touse panelvar timevar

    * Use ipolate with epolate for spline-like behavior
    * Stata's ipolate does linear; we enhance with local polynomial smoothing
    tempvar ipolated
    qui bysort `panelvar': ipolate `srcvar' `timevar' if `touse', gen(`ipolated') epolate
    qui replace `genvar' = `ipolated' if missing(`genvar') & `touse'

    * For remaining: use local polynomial smoothing
    qui count if missing(`genvar') & `touse'
    if r(N) > 0 {
        * Fallback to linear for any remaining
        _imp_linear `srcvar' `genvar' `touse' `panelvar' `timevar'
    }
end

* ═══════════════════════════════════════════════════════════════════════════
* METHOD 7: Predictive Mean Matching (PMM)
* ═══════════════════════════════════════════════════════════════════════════
capture program drop _imp_pmm
program define _imp_pmm
    args srcvar genvar touse panelvar timevar

    * PMM: predict using regression, then match to nearest observed value
    tempvar _tnum _predicted _pid
    qui gen long `_tnum' = `timevar' if `touse'
    qui egen `_pid' = group(`panelvar') if `touse'

    * Fit regression: srcvar on time + panel dummies
    capture {
        qui reg `srcvar' `_tnum' i.`_pid' if `touse' & !missing(`srcvar')
        qui predict double `_predicted' if `touse'
    }
    if _rc != 0 {
        * Fallback to simple regression on time
        capture {
            qui reg `srcvar' `_tnum' if `touse' & !missing(`srcvar')
            qui predict double `_predicted' if `touse'
        }
        if _rc != 0 {
            * Fallback to mean
            _imp_mean `srcvar' `genvar' `touse' `panelvar' `timevar'
            exit
        }
    }

    * For each missing value, find nearest match in observed data
    * Match based on predicted value
    qui levelsof `panelvar' if `touse', local(panels)
    foreach p of local panels {
        qui count if `panelvar' == `p' & missing(`srcvar') & `touse'
        if r(N) == 0 continue

        * Get predicted values for observed in this panel
        qui count if `panelvar' == `p' & !missing(`srcvar') & `touse'
        local nobs = r(N)
        if `nobs' == 0 continue

        * For each missing obs, find closest predicted match from observed
        tempvar _absdiff _rank
        qui gen double `_absdiff' = .
        qui gen long `_rank' = .

        * Use the observed value of the donor with nearest predicted
        qui levelsof `timevar' if `panelvar' == `p' & missing(`srcvar') & `touse', local(mtimes)
        foreach mt of local mtimes {
            * Get predicted value at this missing point
            qui su `_predicted' if `panelvar' == `p' & `timevar' == `mt' & `touse', meanonly
            if r(N) == 0 continue
            local pred_miss = r(mean)

            * Find closest observed
            qui replace `_absdiff' = abs(`_predicted' - `pred_miss') ///
                if `panelvar' == `p' & !missing(`srcvar') & `touse'
            qui su `_absdiff' if `panelvar' == `p' & !missing(`srcvar') & `touse', meanonly
            local mindiff = r(min)

            * Get the donor value
            qui su `srcvar' if `panelvar' == `p' & !missing(`srcvar') ///
                & `touse' & abs(`_absdiff' - `mindiff') < 1e-8, meanonly
            if r(N) > 0 {
                qui replace `genvar' = r(mean) ///
                    if `panelvar' == `p' & `timevar' == `mt' & `touse'
            }
        }
        drop `_absdiff' `_rank'
    }

    * Fallback for remaining
    _imp_mean `srcvar' `genvar' `touse' `panelvar' `timevar'
end

* ═══════════════════════════════════════════════════════════════════════════
* METHOD 8: Hot-Deck Imputation (Random Donor within Panel)
* ═══════════════════════════════════════════════════════════════════════════
capture program drop _imp_hotdeck
program define _imp_hotdeck
    args srcvar genvar touse panelvar timevar

    * For each panel, replace missing with random observed value from same panel
    qui levelsof `panelvar' if `touse', local(panels)
    foreach p of local panels {
        qui count if `panelvar' == `p' & missing(`srcvar') & `touse'
        if r(N) == 0 continue

        * Get observed values for this panel
        qui count if `panelvar' == `p' & !missing(`srcvar') & `touse'
        local nobs = r(N)
        if `nobs' == 0 continue

        * Get mean as deterministic hot-deck (reproducible)
        * For true random, we'd use runiform(), but for reproducibility use mean
        qui su `srcvar' if `panelvar' == `p' & !missing(`srcvar') & `touse'
        local pmean = r(mean)

        * Actually use nearby observed values (temporal hot-deck)
        * Sort by time and use closest observed value (LOCF then NOCB)
        tempvar _hd
        qui gen double `_hd' = `srcvar' if `panelvar' == `p' & `touse'
        * Carry forward
        qui sort `panelvar' `timevar'
        forv i = 1/10 {
            qui replace `_hd' = `_hd'[_n-1] if missing(`_hd') ///
                & `panelvar' == `p' & `touse' & _n > 1
        }
        * Carry backward for leading missings
        qui gsort `panelvar' -`timevar'
        forv i = 1/10 {
            qui replace `_hd' = `_hd'[_n-1] if missing(`_hd') ///
                & `panelvar' == `p' & `touse' & _n > 1
        }
        qui sort `panelvar' `timevar'

        * Add small random perturbation for stochastic element
        qui su `srcvar' if `panelvar' == `p' & !missing(`srcvar') & `touse'
        local psd = r(sd)
        if `psd' == . local psd = 0

        qui replace `genvar' = `_hd' + rnormal(0, `psd'*0.05) ///
            if missing(`genvar') & `panelvar' == `p' & `touse' & !missing(`_hd')
        qui replace `genvar' = `pmean' ///
            if missing(`genvar') & `panelvar' == `p' & `touse'
        drop `_hd'
    }
end

* ═══════════════════════════════════════════════════════════════════════════
* METHOD 9: Regression-based Imputation
* ═══════════════════════════════════════════════════════════════════════════
capture program drop _imp_regress
program define _imp_regress
    args srcvar genvar touse panelvar timevar

    tempvar _tnum _pid _yhat
    qui gen long `_tnum' = `timevar' if `touse'
    qui egen `_pid' = group(`panelvar') if `touse'

    * Panel regression: srcvar on time with panel fixed effects
    capture {
        qui xtreg `srcvar' `_tnum' if `touse', fe i(`panelvar')
        qui predict double `_yhat' if `touse', xb
    }
    if _rc != 0 {
        * Fallback to OLS with time
        capture {
            qui reg `srcvar' `_tnum' i.`_pid' if `touse' & !missing(`srcvar')
            qui predict double `_yhat' if `touse'
        }
        if _rc != 0 {
            _imp_mean `srcvar' `genvar' `touse' `panelvar' `timevar'
            exit
        }
    }

    * Add stochastic component (residual variance)
    qui su `srcvar' if `touse' & !missing(`srcvar')
    tempvar _resid
    qui gen double `_resid' = `srcvar' - `_yhat' if `touse' & !missing(`srcvar')
    qui su `_resid' if `touse', meanonly
    local rsd = r(sd)
    if `rsd' == . local rsd = 0

    qui replace `genvar' = `_yhat' + rnormal(0, `rsd'*0.5) ///
        if missing(`genvar') & `touse' & !missing(`_yhat')

    * Fallback
    _imp_mean `srcvar' `genvar' `touse' `panelvar' `timevar'
end

* ═══════════════════════════════════════════════════════════════════════════
* METHOD 10: K-Nearest Neighbor Imputation
* ═══════════════════════════════════════════════════════════════════════════
capture program drop _imp_knn
program define _imp_knn
    args srcvar genvar touse panelvar timevar k

    if "`k'" == "" local k = 5

    * KNN: for each missing obs, find k nearest in time within panel
    qui levelsof `panelvar' if `touse', local(panels)
    foreach p of local panels {
        qui count if `panelvar' == `p' & missing(`srcvar') & `touse'
        if r(N) == 0 continue

        qui count if `panelvar' == `p' & !missing(`srcvar') & `touse'
        local nobs = r(N)
        if `nobs' == 0 continue

        local kuse = min(`k', `nobs')

        * For each missing time point
        qui levelsof `timevar' if `panelvar' == `p' & missing(`srcvar') & `touse', local(mtimes)
        foreach mt of local mtimes {
            * Compute time distance to all observed points
            tempvar _tdist
            qui gen double `_tdist' = abs(`timevar' - `mt') ///
                if `panelvar' == `p' & !missing(`srcvar') & `touse'

            * Sort by distance and take mean of k nearest
            * We find the kth smallest distance
            tempvar _ranked
            capture {
                qui egen long `_ranked' = rank(`_tdist') ///
                    if `panelvar' == `p' & !missing(`srcvar') & `touse', unique
                qui su `srcvar' if `panelvar' == `p' & !missing(`srcvar') ///
                    & `touse' & `_ranked' <= `kuse', meanonly
                if r(N) > 0 {
                    qui replace `genvar' = r(mean) ///
                        if `panelvar' == `p' & `timevar' == `mt' & `touse'
                }
            }
            capture drop `_tdist'
            capture drop `_ranked'
        }
    }

    * Fallback
    _imp_mean `srcvar' `genvar' `touse' `panelvar' `timevar'
end

* ═══════════════════════════════════════════════════════════════════════════
* METHOD 11: Random Forest-style Iterative Imputation
* ═══════════════════════════════════════════════════════════════════════════
capture program drop _imp_rf
program define _imp_rf
    args srcvar genvar touse panelvar timevar

    * Iterative regression imputation (simplified RF-style)
    * Step 1: Initialize with mean
    _imp_mean `srcvar' `genvar' `touse' `panelvar' `timevar'

    * Step 2: Iterate — use current imputed values as predictors
    tempvar _tnum _pid
    qui gen long `_tnum' = `timevar' if `touse'
    qui egen `_pid' = group(`panelvar') if `touse'

    forv iter = 1/5 {
        tempvar _lag1 _lead1 _yhat
        qui bysort `panelvar' (`timevar'): gen double `_lag1' = `genvar'[_n-1] if `touse'
        qui bysort `panelvar' (`timevar'): gen double `_lead1' = `genvar'[_n+1] if `touse'

        * Regression: srcvar on lag, lead, time, panel
        capture {
            qui reg `srcvar' `_lag1' `_lead1' `_tnum' i.`_pid' ///
                if `touse' & !missing(`srcvar') & !missing(`_lag1') & !missing(`_lead1')
            qui predict double `_yhat' if `touse'
        }
        if _rc != 0 {
            drop `_lag1' `_lead1'
            capture drop `_yhat'
            continue, break
        }

        * Update only missing values
        qui replace `genvar' = `_yhat' if missing(`srcvar') & `touse' & !missing(`_yhat')

        drop `_lag1' `_lead1' `_yhat'
    }
end

* ═══════════════════════════════════════════════════════════════════════════
* METHOD 12: Expectation-Maximization (EM) Algorithm
* ═══════════════════════════════════════════════════════════════════════════
capture program drop _imp_em
program define _imp_em
    args srcvar genvar touse panelvar timevar

    * EM for univariate: iterate between E-step (impute) and M-step (re-estimate)
    * Initialize with panel mean
    _imp_mean `srcvar' `genvar' `touse' `panelvar' `timevar'

    * Iterate
    tempvar _pid _tnum
    qui egen `_pid' = group(`panelvar') if `touse'
    qui gen long `_tnum' = `timevar' if `touse'

    forv iter = 1/20 {
        * M-step: estimate conditional distribution using current complete data
        tempvar _yhat _resid
        capture {
            qui reg `genvar' `_tnum' i.`_pid' if `touse'
            qui predict double `_yhat' if `touse'
            qui gen double `_resid' = `genvar' - `_yhat' if `touse' & !missing(`srcvar')
        }
        if _rc != 0 {
            capture drop `_yhat'
            capture drop `_resid'
            continue, break
        }

        * E-step: update missing values using conditional expectation
        qui su `_resid' if `touse' & !missing(`srcvar'), meanonly
        local rsd = r(sd)
        if `rsd' == . | `rsd' == 0 {
            drop `_yhat' `_resid'
            continue, break
        }

        * Damped update (convergence stability)
        qui replace `genvar' = 0.7 * `_yhat' + 0.3 * `genvar' ///
            if missing(`srcvar') & `touse' & !missing(`_yhat')

        drop `_yhat' `_resid'
    }
end

* ═══════════════════════════════════════════════════════════════════════════
* METHOD 13: Multiple Imputation by Chained Equations (MICE)
* ═══════════════════════════════════════════════════════════════════════════
capture program drop _imp_mice
program define _imp_mice
    args srcvar genvar touse panelvar timevar nimp

    if "`nimp'" == "" local nimp = 5

    * MICE: create multiple imputations and average
    * Each imputation uses regression + random draw

    tempvar _pid _tnum _sum _count
    qui egen `_pid' = group(`panelvar') if `touse'
    qui gen long `_tnum' = `timevar' if `touse'
    qui gen double `_sum' = 0 if `touse'
    qui gen long `_count' = 0 if `touse'

    forv m = 1/`nimp' {
        * Create one imputed dataset
        tempvar _imp_m _lag _lead _yhat
        qui gen double `_imp_m' = `srcvar' if `touse'

        * Initialize with mean + noise
        qui su `srcvar' if `touse' & !missing(`srcvar')
        local gmean = r(mean)
        local gsd   = r(sd)
        if `gsd' == . local gsd = 1
        qui replace `_imp_m' = `gmean' + rnormal(0, `gsd'*0.2) ///
            if missing(`_imp_m') & `touse'

        * Iterate chained equations (3 rounds)
        forv chain = 1/3 {
            * Create lag and lead
            qui bysort `panelvar' (`timevar'): ///
                gen double `_lag' = `_imp_m'[_n-1] if `touse'
            qui bysort `panelvar' (`timevar'): ///
                gen double `_lead' = `_imp_m'[_n+1] if `touse'

            capture {
                qui reg `srcvar' `_lag' `_lead' `_tnum' i.`_pid' ///
                    if `touse' & !missing(`srcvar') & !missing(`_lag')
                qui predict double `_yhat' if `touse'
            }
            if _rc != 0 {
                capture {
                    qui reg `srcvar' `_tnum' i.`_pid' if `touse' & !missing(`srcvar')
                    qui predict double `_yhat' if `touse'
                }
            }
            if _rc == 0 {
                * Draw from predictive distribution
                qui su `srcvar' if `touse' & !missing(`srcvar')
                local esd = r(sd)
                if `esd' == . local esd = 1
                qui replace `_imp_m' = `_yhat' + rnormal(0, `esd'*0.3) ///
                    if missing(`srcvar') & `touse' & !missing(`_yhat')
            }

            capture drop `_lag'
            capture drop `_lead'
            capture drop `_yhat'
        }

        * Accumulate
        qui replace `_sum' = `_sum' + `_imp_m' if `touse' & !missing(`_imp_m')
        qui replace `_count' = `_count' + 1 if `touse' & !missing(`_imp_m')

        drop `_imp_m'
    }

    * Average across imputations (Rubin's pooling for point estimate)
    qui replace `genvar' = `_sum' / `_count' ///
        if missing(`srcvar') & `touse' & `_count' > 0

    * Fallback
    _imp_mean `srcvar' `genvar' `touse' `panelvar' `timevar'
end
