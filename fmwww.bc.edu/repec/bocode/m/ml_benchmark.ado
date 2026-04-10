*! ml_benchmark v1.5.0  metaLong for Stata 14.1
*! Benchmark Calibration of Longitudinal ITCV Against Observed Covariates
*! Subir Hait, Michigan State University  |  haitsubi@msu.edu
*!
*! FIX v1.5.0: replaced preserve/restore inside loop with tempfile approach
*! because Stata 14.1 does not allow nested preserve (r(621) already preserved)

program define ml_benchmark, rclass
    version 14.1

    syntax varlist(min=2 max=2 numeric) [if] [in] , ///
        STUDy(varname)              ///
        TIME(varname numeric)       ///
        METAfile(string asis)       ///
        SENSfile(string asis)       ///
        COVariates(varlist numeric) ///
        [                           ///
        ALpha(real 0.05)            ///
        MINk(integer 3)             ///
        SAVing(string asis)         ///
        REPLACE                     ///
        ]

    tokenize `varlist'
    local yi `1'
    local vi `2'

    /* ---- Mark analytic sample ----------------------------------------- */
    marksample touse
    markout `touse' `time' `yi' `vi' `covariates'

    capture confirm string variable `study'
    if !_rc {
        quietly replace `touse' = 0 if trim(`study') == ""
    }
    else {
        quietly replace `touse' = 0 if missing(`study')
    }

    local cov_list `covariates'
    local n_covs : word count `cov_list'

    if `n_covs' == 0 {
        di as error "covariates() must contain at least one numeric covariate."
        exit 198
    }

    /* ---- Load pooled meta results -------------------------------------- */
    preserve
    quietly use `"`metafile'"', clear
    capture confirm variable time k theta se df t_stat p_val ci_lb ci_ub tau2
    if _rc {
        di as error "metafile() invalid: expected variables not found."
        restore
        exit 198
    }
    tempname meta_mat
    mkmat time k theta se df t_stat p_val ci_lb ci_ub tau2, matrix(`meta_mat')
    local n_times = rowsof(`meta_mat')
    restore

    /* ---- Load sensitivity results -------------------------------------- */
    preserve
    quietly use `"`sensfile'"', clear
    capture confirm variable time itcv_alpha
    if _rc {
        di as error "sensfile() invalid: expected variables not found."
        restore
        exit 198
    }
    tempname sens_mat
    mkmat time itcv_alpha, matrix(`sens_mat')
    restore

    /* ---- Save working data to tempfile --------------------------------- */
    /* ONE save/use cycle; NO preserve inside the main loop             */
    quietly keep if `touse'
    quietly keep `study' `time' `yi' `vi' `cov_list'
    tempfile workdata
    quietly save `workdata'

    /* ---- Result matrix ------------------------------------------------- */
    /* cols: time cov_idx k r_partial t_stat df p_val itcv_alpha beats      */
    local n_rows = `n_times' * `n_covs'
    tempname bench_mat
    matrix `bench_mat' = J(`n_rows', 9, .)
    matrix colnames `bench_mat' = ///
        time cov_idx k r_partial t_stat df p_val itcv_alpha beats

    local mat_row = 0

    /* ================================================================== */
    /*  Main loop: time points x covariates                               */
    /* ================================================================== */
    forvalues row = 1/`n_times' {

        local t_val  = `meta_mat'[`row', 1]
        local tau2_t = max(0, `meta_mat'[`row', 10])

        /* ITCV_adj threshold for this time point */
        local itcv_t = .
        forvalues i = 1/`=rowsof(`sens_mat')' {
            if `sens_mat'[`i', 1] == `t_val' {
                local itcv_t = `sens_mat'[`i', 2]
            }
        }

        local cov_idx = 0
        foreach cov of local cov_list {

            local cov_idx = `cov_idx' + 1
            local mat_row = `mat_row' + 1

            /* ---- Load subset from tempfile — no preserve needed ------ */
            quietly use `workdata', clear
            quietly keep if `time' == `t_val'
            quietly keep `study' `yi' `vi' `cov'
            quietly drop if missing(`yi') | missing(`vi') | missing(`cov')

            quietly count
            local n_use = r(N)

            /* Populate defaults (missing = skipped) */
            matrix `bench_mat'[`mat_row', 1] = `t_val'
            matrix `bench_mat'[`mat_row', 2] = `cov_idx'
            matrix `bench_mat'[`mat_row', 3] = `n_use'
            matrix `bench_mat'[`mat_row', 8] = `itcv_t'

            if `n_use' < `mink' continue

            /* ---- Check covariate has non-zero variance --------------- */
            /* summarize WITHOUT meanonly so that r(Var) is returned      */
            quietly summarize `cov'
            if missing(r(Var)) | r(Var) < 1e-15 continue
            local cov_mean = r(mean)

            /* ---- Build RE weights and centred covariate -------------- */
            tempvar cov_c w
            quietly gen double `cov_c' = `cov' - `cov_mean'
            quietly gen double `w'     = 1 / (`vi' + `tau2_t')

            quietly count if missing(`w') | `w' <= 0
            if r(N) > 0 continue

            /* ---- Weighted meta-regression ---------------------------- */
            /* One observation per study within this time slice:          */
            /* ordinary WLS suffices — no clustering needed              */
            capture quietly regress `yi' `cov_c' [aw=`w']
            if _rc continue

            capture local t_cov = _b[`cov_c'] / _se[`cov_c']
            if _rc continue

            local df_cov = `n_use' - 2
            if `df_cov' < 1 local df_cov = 1

            local p_cov = 2 * ttail(`df_cov', abs(`t_cov'))
            local r_par = `t_cov' / sqrt(`t_cov'^2 + `df_cov')

            local beats = .
            if !missing(`itcv_t') & !missing(`r_par') {
                local beats = (abs(`r_par') >= `itcv_t')
            }

            matrix `bench_mat'[`mat_row', 4] = `r_par'
            matrix `bench_mat'[`mat_row', 5] = `t_cov'
            matrix `bench_mat'[`mat_row', 6] = `df_cov'
            matrix `bench_mat'[`mat_row', 7] = `p_cov'
            matrix `bench_mat'[`mat_row', 9] = `beats'

        }  /* end covariate loop */
    }  /* end time loop */

    /* ================================================================== */
    /*  Build output dataset                                              */
    /* ================================================================== */
    clear
    svmat double `bench_mat', names(col)

    gen str32 covariate = ""
    local i = 0
    foreach cov of local cov_list {
        local i = `i' + 1
        quietly replace covariate = "`cov'" if cov_idx == `i'
    }
    drop cov_idx

    order time covariate k r_partial t_stat df p_val itcv_alpha beats

    label var time       "Follow-up time"
    label var covariate  "Covariate name"
    label var k          "Number of studies"
    label var r_partial  "Partial correlation with effect"
    label var t_stat     "t-statistic (covariate slope)"
    label var df         "Degrees of freedom"
    label var p_val      "p-value"
    label var itcv_alpha "ITCV_adj threshold at this time"
    label var beats      "1 if |r_partial| >= ITCV_adj"

    char _dta[ml_type]  "ml_benchmark"
    char _dta[ml_alpha] "`alpha'"
    char _dta[ml_mink]  "`mink'"

    /* ================================================================== */
    /*  Display                                                           */
    /* ================================================================== */
    di _newline
    di as txt "  {hline 72}"
    di as txt "  metaLong: Benchmark Calibration of ITCV"
    di as txt "  Covariates: `cov_list'"
    di as txt "  {hline 72}"
    di as txt _col(4)  "Time" _col(10) "Covariate"   ///
              _col(26) "k"    _col(30) "|r_partial|" ///
              _col(44) "ITCV_adj" _col(55) "Beats?"  ///
              _col(63) "p-val"
    di as txt "  {hline 72}"

    quietly count
    local nout = r(N)
    forvalues j = 1/`nout' {
        local t_r  = time[`j']
        local c_r  = covariate[`j']
        local k_r  = k[`j']
        local rp_r = r_partial[`j']
        local ia_r = itcv_alpha[`j']
        local bt_r = beats[`j']
        local pv_r = p_val[`j']

        if missing(`rp_r') {
            di as txt %7.1f `t_r' "  " %-15s "`c_r'" %4.0f `k_r' ///
                "   (skipped)"
        }
        else {
            local bts_lbl = cond(`bt_r'==1, "YES", "no ")
            di as txt %7.1f `t_r' "  " %-15s "`c_r'" as res %4.0f `k_r' ///
                %12.4f abs(`rp_r') %12.4f `ia_r' "   `bts_lbl'" ///
                %10.4f `pv_r'
        }
    }
    di as txt "  {hline 72}"
    di as txt "  'Beats': |r_partial| >= ITCV_adj means observed confounding"
    di as txt "  of that magnitude would be sufficient to nullify the effect."

    /* ================================================================== */
    /*  Save                                                              */
    /* ================================================================== */
    if `"`saving'"' != "" {
        if "`replace'" != "" quietly save `saving', replace
        else                  quietly save `saving'
        di as txt _newline "  Results saved to: " as res `"`saving'"'
    }

    return matrix bench = `bench_mat'
    return scalar alpha  = `alpha'
    return scalar mink   = `mink'

end
