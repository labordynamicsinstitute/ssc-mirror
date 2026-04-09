*! finegray_predict Version 1.0.0  2026/04/06
*! Post-estimation predictions after finegray
*! Author: Timothy P Copeland
*! Department of Clinical Neuroscience, Karolinska Institutet
*! Program class: none (creates variable)

/*
Basic syntax:
  finegray_predict newvar [if] [in], [cif xb schoenfeld timevar(varname)]

Description:
  Generate predictions after finegray.

  xb (default) - linear predictor z'beta
  cif          - cumulative incidence function: 1 - exp(-H0(t)*exp(xb))

Required:
  newvar - name for the new variable

Options:
  cif          - predict CIF instead of xb
  xb           - predict linear predictor (default)
  timevar(var) - use specified variable for time (instead of _t)

See help finegray for complete documentation
*/

program define finegray_predict, nclass sortpreserve
    version 16.0
    local _orig_varabbrev = c(varabbrev)
    set varabbrev off

    capture noisily {

    syntax newvarname [if] [in] , [CIF XB SCHoenfeld TIMEvar(varname numeric)]

    * Check finegray was run
    if "`e(cmd)'" != "finegray" {
        display as error "last estimates not found"
        display as error "you must run {bf:finegray} before using finegray_predict"
        exit 301
    }

    * Default to xb
    local n_types = ("`cif'" != "") + ("`xb'" != "") + ("`schoenfeld'" != "")
    if `n_types' > 1 {
        display as error "specify only one of cif, xb, or schoenfeld"
        exit 198
    }
    if `n_types' == 0 local xb "xb"

    marksample touse, novarlist

    quietly count if `touse'
    if r(N) == 0 {
        display as error "no observations"
        exit 2000
    }

    if "`schoenfeld'" != "" {
        * Schoenfeld residuals require the original stset estimation data
        capture confirm variable _t
        if _rc {
            display as error "variable _t not found"
            display as error "schoenfeld residuals require the original stset estimation data"
            display as error "use {bf:finegray_predict, xb} for predictions on new data"
            exit 111
        }
        capture confirm variable _d
        if _rc {
            display as error "variable _d not found"
            display as error "schoenfeld residuals require the original stset estimation data"
            exit 111
        }
        quietly count if e(sample)
        if r(N) == 0 {
            display as error "no observations in estimation sample"
            display as error "schoenfeld residuals require the original stset estimation data"
            display as error "use {bf:finegray_predict, xb} for predictions on new data"
            exit 2000
        }
    }

    * Build the covariate columns used for prediction.
    * For FV models we reconstruct the design matrix on demand rather than
    * depending on persistent _fg_* columns remaining in the dataset.
    local _score_varlist "`e(covariates)'"
    local _score_labels "`e(covariates)'"
    if `"`e(fvvarlist)'"' != "" {
        capture noisily fvexpand `e(fvvarlist)' if `touse'
        if _rc {
            display as error "unable to expand factor-variable terms for prediction"
            exit _rc
        }
        local _fv_semantic `r(varlist)'

        capture noisily fvrevar `e(fvvarlist)' if `touse'
        if _rc {
            display as error "unable to reconstruct factor-variable design for prediction"
            exit _rc
        }
        local _fv_actual `r(varlist)'

        local _n_sem : word count `_fv_semantic'
        local _n_act : word count `_fv_actual'
        if `_n_sem' != `_n_act' {
            display as error "internal error: fvexpand/fvrevar mismatch during prediction"
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

            local _tvname "_fg_pred_`_i'"
            tempvar `_tvname'
            local _tv ``_tvname''
            quietly gen double `_tv' = `_var'
            local _rebuild_varlist "`_rebuild_varlist' `_tv'"
            local _rebuild_labels "`_rebuild_labels' `_label_term'"
        }

        local _score_varlist : list retokenize _rebuild_varlist
        local _score_labels : list retokenize _rebuild_labels

        local _n_score : word count `_score_varlist'
        local _n_b = colsof(e(b))
        if `_n_score' != `_n_b' {
            display as error "reconstructed factor-variable design does not match stored coefficients"
            exit 198
        }
    }
    else {
        local _cov_missing ""
        foreach _cov of local _score_varlist {
            capture confirm variable `_cov'
            if _rc {
                local _cov_missing "`_cov'"
                continue, break
            }
        }
        if "`_cov_missing'" != "" {
            display as error "required covariate `_cov_missing' not found"
            display as error "predict requires the variables used when finegray was estimated"
            exit 111
        }
    }

    if "`xb'" != "" {
        * Linear predictor: matrix score
        if "`typlist'" == "" local typlist "double"
        tempname b
        matrix `b' = e(b)
        matrix colnames `b' = `_score_varlist'
        matrix score `typlist' `varlist' = `b' if `touse'
        label variable `varlist' "Linear prediction (xb)"
    }
    else if "`cif'" != "" {
        * CIF = 1 - exp(-H0(t) * exp(xb))
        capture confirm matrix e(basehaz)
        if _rc {
            display as error "baseline hazard not available"
            display as error "CIF prediction requires e(basehaz) from finegray"
            exit 198
        }

        * Get time variable
        local tvar "_t"
        if "`timevar'" != "" local tvar "`timevar'"

        capture confirm variable `tvar'
        if _rc {
            display as error "time variable `tvar' not found"
            exit 111
        }

        * Exclude observations with missing time values
        markout `touse' `tvar'
        quietly count if `touse'
        if r(N) == 0 {
            display as error "no observations with non-missing `tvar'"
            exit 2000
        }

        * Compute xb first
        tempvar xb_val
        tempname b
        matrix `b' = e(b)
        matrix colnames `b' = `_score_varlist'
        matrix score double `xb_val' = `b' if `touse'

        * Get basehaz matrix
        tempname bh
        matrix `bh' = e(basehaz)

        if "`typlist'" == "" local typlist "double"

        * Step function lookup via Mata binary search: O(n log n_bh)
        * H0(t_i) = baseline cumhazard at time t_i
        * CIF(t_i|z) = 1 - exp(-H0(t_i) * exp(z'beta))
        tempvar H0_val
        quietly gen double `H0_val' = 0

        * Load Mata engine for step lookup
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
        mata: _finegray_step_lookup("`bh'", "`tvar'", "`H0_val'", "`touse'")

        quietly gen `typlist' `varlist' = ///
            1 - exp(-`H0_val' * exp(`xb_val')) if `touse'
        label variable `varlist' "CIF prediction"
    }
    else if "`schoenfeld'" != "" {
        * Schoenfeld residuals: creates stub_1, stub_2, ... for each covariate
        * Only defined at cause-event observations
        local covariates "`_score_labels'"
        local events_var "`e(compete)'"
        local cause_val = e(cause)
        local censvalue_val = e(censvalue)
        local byg_var "`e(strata)'"
        local p : word count `covariates'

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

        * Compute on estimation sample
        preserve
        quietly keep if e(sample)
        tempvar _pre_obs_id
        gen long `_pre_obs_id' = _n
        sort _t `_pre_obs_id'

        local _byg_mata "`byg_var'"
        if "`byg_var'" != "" {
            local _byg_nvar : word count `byg_var'
            if `_byg_nvar' > 1 {
                quietly egen long _finegray_byg = group(`byg_var')
                local _byg_mata "_finegray_byg"
            }
        }

        mata: _finegray_schoenfeld_compute( ///
            "`_score_varlist'", "`events_var'", `cause_val', `censvalue_val', ///
            "`_byg_mata'", 0)

        restore

        tempname sch_mat
        matrix `sch_mat' = _finegray_schoenfeld
        capture matrix drop _finegray_schoenfeld

        local n_fail = rowsof(`sch_mat')

        * Pre-check all stub variable names before creating any
        if `p' > 1 {
            local _pre_stub = "`varlist'"
            forvalues _pv = 2/`p' {
                local _pvname "`_pre_stub'_`_pv'"
                capture confirm new variable `_pvname'
                if _rc {
                    display as error "variable `_pvname' already exists"
                    exit 110
                }
            }
        }

        * Create stub variables for all covariates
        if "`typlist'" == "" local typlist "double"
        quietly gen `typlist' `varlist' = .

        local cov_1 : word 1 of `covariates'
        label variable `varlist' "Schoenfeld residual: `cov_1'"

        local _sch_varnames "`varlist'"
        if `p' > 1 {
            local stub = "`varlist'"
            forvalues v = 2/`p' {
                local vname "`stub'_`v'"
                quietly gen `typlist' `vname' = .
                local cov_v : word `v' of `covariates'
                label variable `vname' "Schoenfeld residual: `cov_v'"
                local _sch_varnames "`_sch_varnames' `vname'"
            }
        }

        * Mark cause events in estimation sample
        quietly count if e(sample) & `events_var' == `cause_val' & _d == 1
        if r(N) != `n_fail' {
            display as text "note: `n_fail' Schoenfeld residuals for " ///
                "`r(N)' cause events"
        }

        * Assign residuals via Mata index lookup (O(N) vs O(N*n_fail))
        * Stable sort by _t with observation ID as tiebreaker to match
        * the preserve-block sort order for tied event times
        tempvar _obs_id
        gen long `_obs_id' = _n
        sort _t `_obs_id'
        tempvar _is_cause_evt _cumcount
        quietly gen byte `_is_cause_evt' = ///
            (e(sample) & `events_var' == `cause_val' & _d == 1)
        quietly gen long `_cumcount' = sum(`_is_cause_evt') ///
            if `_is_cause_evt' == 1

        mata: _finegray_assign_schoenfeld_vars( ///
            "`sch_mat'", "`_cumcount'", ///
            tokens("`_sch_varnames'"), `p')

        * Enforce if/in: blank residuals outside the requested sample
        quietly replace `varlist' = . if !`touse'
        if `p' > 1 {
            local stub = "`varlist'"
            forvalues v = 2/`p' {
                quietly replace `stub'_`v' = . if !`touse'
            }
        }
    }

    } /* end capture noisily */

    local rc = _rc
    set varabbrev `_orig_varabbrev'
    if `rc' exit `rc'
end
