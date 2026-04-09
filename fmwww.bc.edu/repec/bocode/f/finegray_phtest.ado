*! finegray_phtest Version 1.0.0  2026/04/06
*! Proportional subdistribution hazards test after finegray
*! Author: Timothy P Copeland
*! Department of Clinical Neuroscience, Karolinska Institutet
*! Program class: rclass

/*
Basic syntax:
  finegray_phtest [, time(rank|log|identity) detail]

Description:
  Tests the proportional subdistribution hazards assumption after finegray.
  Computes scaled Schoenfeld residuals and tests their correlation with time.
  Approximate PH diagnostic (diagonal scaling, independent per-variable tests).

Options:
  time(string)  - time function: rank (default), log, identity
  detail        - display scaled Schoenfeld residuals

See help finegray_phtest for complete documentation
*/

program define finegray_phtest, rclass
    version 16.0
    local _orig_varabbrev = c(varabbrev)
    set varabbrev off

    capture noisily {

    syntax [, TIME(string) DETail]

    * Check finegray was run
    if "`e(cmd)'" != "finegray" {
        display as error "last estimates not found"
        display as error "you must run {bf:finegray} before using finegray_phtest"
        exit 301
    }

    * Default time function
    if "`time'" == "" local time "rank"
    if !inlist("`time'", "rank", "log", "identity") {
        display as error "time() must be rank, log, or identity"
        exit 198
    }

    * Get model info from e()
    local covariates "`e(covariates)'"
    local events "`e(compete)'"
    local cause = e(cause)
    local censvalue = e(censvalue)
    local byg "`e(strata)'"
    local p : word count `covariates'

    if `p' == 0 {
        display as error "no covariates in model"
        exit 198
    }

    * Preflight: schoenfeld residuals require original stset estimation data
    capture confirm variable _t
    if _rc {
        display as error "variable _t not found"
        display as error "finegray_phtest requires the original stset estimation data"
        exit 111
    }
    capture confirm variable _d
    if _rc {
        display as error "variable _d not found"
        display as error "finegray_phtest requires the original stset estimation data"
        exit 111
    }
    quietly count if e(sample)
    if r(N) == 0 {
        display as error "no observations in estimation sample"
        display as error "finegray_phtest requires the original stset estimation data"
        exit 2000
    }

    * Load Mata engine
    capture program list _finegray_mata_loaded
    if _rc {
        capture findfile _finegray_mata.ado
        if _rc == 0 {
            run "`r(fn)'"
        }
        else {
            display as error "_finegray_mata.ado not found; reinstall finegray"
            exit 111
        }
    }

    * For FV models, reconstruct the design matrix if _fg_* columns are gone
    local covlabels "`covariates'"
    if `"`e(fvvarlist)'"' != "" {
        local _need_rebuild = 0
        foreach _cov of local covariates {
            capture confirm variable `_cov'
            if _rc {
                local _need_rebuild = 1
                continue, break
            }
        }
        if `_need_rebuild' {
            capture noisily fvexpand `e(fvvarlist)' if e(sample)
            if _rc {
                display as error "unable to expand factor-variable terms for PH test"
                exit _rc
            }
            local _fv_semantic `r(varlist)'

            capture noisily fvrevar `e(fvvarlist)' if e(sample)
            if _rc {
                display as error "unable to reconstruct factor-variable design for PH test"
                exit _rc
            }
            local _fv_actual `r(varlist)'

            local _n_sem : word count `_fv_semantic'
            local _n_act : word count `_fv_actual'
            if `_n_sem' != `_n_act' {
                display as error "internal error: fvexpand/fvrevar mismatch in PH test"
                exit 198
            }

            local _rebuild_varlist ""
            local _rebuild_labels ""
            forvalues _i = 1/`_n_sem' {
                local _term : word `_i' of `_fv_semantic'
                local _var : word `_i' of `_fv_actual'
                local _label_term = subinstr("`_term'", "c.", "", .)
                if regexm("`_term'", "[0-9]+b\.") {
                    continue
                }
                if substr("`_var'", 1, 2) != "__" {
                    local _rebuild_varlist "`_rebuild_varlist' `_var'"
                    local _rebuild_labels "`_rebuild_labels' `_label_term'"
                    continue
                }
                local _tvname "_fg_ph_`_i'"
                tempvar `_tvname'
                local _tv ``_tvname''
                quietly gen double `_tv' = `_var'
                local _rebuild_varlist "`_rebuild_varlist' `_tv'"
                local _rebuild_labels "`_rebuild_labels' `_label_term'"
            }

            local covariates : list retokenize _rebuild_varlist
            local covlabels : list retokenize _rebuild_labels

            local _n_score : word count `covariates'
            local _n_b = colsof(e(b))
            if `_n_score' != `_n_b' {
                display as error "reconstructed FV design does not match stored coefficients"
                exit 198
            }
            local p : word count `covariates'
        }
    }

    * Preserve and compute Schoenfeld residuals on estimation sample
    preserve
    quietly keep if e(sample)

    sort _t

    * Combine byg variables if multiple
    local _byg_mata "`byg'"
    if "`byg'" != "" {
        local _byg_nvar : word count `byg'
        if `_byg_nvar' > 1 {
            quietly egen long _finegray_byg = group(`byg')
            local _byg_mata "_finegray_byg"
        }
    }

    * Compute scaled Schoenfeld residuals via Mata
    mata: _finegray_schoenfeld_compute( ///
        "`covariates'", "`events'", `cause', `censvalue', ///
        "`_byg_mata'", 1)

    restore

    * Retrieve the Schoenfeld matrix (n_fail x (p+1))
    tempname sch_mat
    matrix `sch_mat' = _finegray_schoenfeld
    capture matrix drop _finegray_schoenfeld

    local n_fail = rowsof(`sch_mat')

    if `n_fail' < 3 {
        display as error "too few cause events (`n_fail') for PH test"
        exit 198
    }

    * Compute time function
    tempname times test_mat
    matrix `times' = `sch_mat'[1..`n_fail', 1]

    * Build test results: p x 3 matrix [chi2, df, p]
    matrix `test_mat' = J(`p', 3, .)

    local global_chi2 = 0

    * Load Schoenfeld matrix into a temporary dataset once (svmat),
    * then loop correlations over columns — avoids O(p) preserve/clear cycles.
    preserve
    quietly {
        clear
        svmat double `sch_mat', names(_sch)

        * _sch1 = time, _sch2.._sch`=`p'+1' = residuals per covariate
        if "`time'" == "rank" {
            egen double _sch_tfunc = rank(_sch1)
        }
        else if "`time'" == "log" {
            gen double _sch_tfunc = ln(_sch1)
        }
        else {
            gen double _sch_tfunc = _sch1
        }
    }

    forvalues v = 1/`p' {
        local col = `v' + 1
        quietly correlate _sch`col' _sch_tfunc
        local rho = r(rho)
        local n_corr = r(N)

        if `n_corr' < `n_fail' {
            local vname : word `v' of `covlabels'
            noisily display as text ///
                "note: `=`n_fail'-`n_corr'' event times produced " ///
                "missing values after `time' transform for `vname'"
        }

        local chi2_v = `n_corr' * (`rho')^2
        local p_v = chi2tail(1, `chi2_v')

        matrix `test_mat'[`v', 1] = `chi2_v'
        matrix `test_mat'[`v', 2] = 1
        matrix `test_mat'[`v', 3] = `p_v'

        local global_chi2 = `global_chi2' + `chi2_v'
    }
    restore

    local global_df = `p'
    local global_p = chi2tail(`global_df', `global_chi2')

    * Label test matrix
    local rownames ""
    foreach v of local covlabels {
        local rownames "`rownames' `v'"
    }
    matrix rownames `test_mat' = `rownames'
    matrix colnames `test_mat' = chi2 df p

    * Display results
    display as text ""
    display as text "Test of proportional subdistribution hazards assumption"
    display as text ""
    display as text "Time function: " as result "`time'"
    display as text "Cause events:  " as result "`n_fail'"
    display as text ""

    display as text "{hline 13}{c TT}{hline 36}"
    display as text %12s "Variable" " {c |}" ///
        %10s "chi2" %6s "df" %12s "Prob>chi2"
    display as text "{hline 13}{c +}{hline 36}"

    forvalues v = 1/`p' {
        local vname : word `v' of `covlabels'
        local chi2_v = `test_mat'[`v', 1]
        local p_v = `test_mat'[`v', 3]
        display as text %12s abbrev("`vname'", 12) " {c |}" ///
            as result %10.2f `chi2_v' %6.0f 1 %12.4f `p_v'
    }

    display as text "{hline 13}{c +}{hline 36}"
    display as text %12s "Global test" " {c |}" ///
        as result %10.2f `global_chi2' %6.0f `global_df' %12.4f `global_p'
    display as text "{hline 13}{c BT}{hline 36}"

    * Return results
    return scalar chi2 = `global_chi2'
    return scalar df = `global_df'
    return scalar p = `global_p'
    return scalar N_fail = `n_fail'
    return local time "`time'"
    return matrix phtest = `test_mat'

    if "`detail'" != "" {
        display as text ""
        display as text "Scaled Schoenfeld residuals (first 20 rows):"
        local show_rows = min(`n_fail', 20)
        tempname sch_show
        matrix `sch_show' = `sch_mat'[1..`show_rows', 1...]
        local colnames "time"
        foreach v of local covlabels {
            local colnames "`colnames' `v'"
        }
        matrix colnames `sch_show' = `colnames'
        matrix list `sch_show', format(%9.4f) noheader
    }

    } /* end capture noisily */

    local rc = _rc
    set varabbrev `_orig_varabbrev'
    if `rc' exit `rc'
end
