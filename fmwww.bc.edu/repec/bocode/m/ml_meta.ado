*! ml_meta v1.0.0  metaLong for Stata 14.1
*! Longitudinal Meta-Analysis with DerSimonian-Laird tau2 and Cluster-Robust SE
*! Subir Hait, Michigan State University  |  haitsubi@msu.edu
*!
*! Reference: Hedges, Tipton & Johnson (2010); Tipton (2015)
*! Small-sample correction: cluster-robust SE with df = k-1 (analogous to
*!   Tipton CR1; CR2/Satterthwaite requires external packages such as ivreg2)

program define ml_meta, rclass
    version 14.1

    syntax varlist(min=2 max=2 numeric) [if] [in] , ///
        STUDy(varname)          ///  cluster / study-ID variable
        TIME(varname numeric)   ///  follow-up time variable
        [                       ///
        ALpha(real 0.05)        ///  significance level (default 0.05)
        MINk(integer 2)         ///  minimum studies per time point
        noSMALLsample           ///  use z-based inference instead of t(k-1)
        SAVing(string asis)     ///  file to store results dataset
        REPLACE                 ///  overwrite saving() file
        ]

    /* ---- parse varlist ---- */
    tokenize `varlist'
    local yi `1'   // effect size
    local vi `2'   // sampling variance

    /* ---- mark sample ---- */
    marksample touse
    markout `touse' `time' `yi' `vi'              /* numeric vars only  */
    quietly replace `touse' = 0 if `study' == "" /* string study guard */

    quietly count if `touse'
    if r(N) == 0 {
        di as error "No observations in estimation sample."
        exit 2000
    }

    /* ---- unique sorted time points ---- */
    quietly levelsof `time' if `touse', local(timevals)
    local n_times = wordcount("`timevals'")

    /* ---- result matrix: rows=time points, cols=10 ---- */
    /* cols: time k theta se df t_stat p_val ci_lb ci_ub tau2 */
    tempname res_mat
    matrix `res_mat' = J(`n_times', 10, .)
    matrix colnames `res_mat' = time k theta se df t_stat p_val ci_lb ci_ub tau2

    /* ---- preserve data for computations ---- */
    preserve
    quietly keep if `touse'
    quietly keep `yi' `vi' `study' `time'

    /* ================================================================== */
    /*  Main loop over time points                                         */
    /* ================================================================== */
    local row = 0

    foreach t of local timevals {
        local row = `row' + 1
        local t_val `t'

        /* flag obs at current time point */
        tempvar in_t
        quietly gen byte `in_t' = (`time' == `t_val')

        /* count unique studies */
        quietly levelsof `study' if `in_t', local(study_list_t)
        local k_t : word count `study_list_t'

        matrix `res_mat'[`row', 1] = `t_val'
        matrix `res_mat'[`row', 2] = `k_t'

        if `k_t' < `mink' {
            drop `in_t'
            continue
        }

        /* -------------------------------------------------------------- */
        /*  Step 1: DerSimonian-Laird tau2                                 */
        /* -------------------------------------------------------------- */
        /* Fixed-effects weights: wi = 1/vi */
        tempvar wi
        quietly gen double `wi' = 1 / `vi' if `in_t'

        /* Weighted sums for FE estimate */
        tempvar wyi
        quietly gen double `wyi' = `wi' * `yi' if `in_t'

        quietly summ `wi'  if `in_t', meanonly
        local sw = r(sum)
        quietly summ `wyi' if `in_t', meanonly
        local theta_FE = r(sum) / `sw'

        /* Q statistic: sum( wi*(yi - theta_FE)^2 ) */
        tempvar dev2
        quietly gen double `dev2' = `wi' * (`yi' - `theta_FE')^2 if `in_t'
        quietly summ `dev2' if `in_t', meanonly
        local Q = r(sum)

        /* sum(wi^2) */
        tempvar wi2
        quietly gen double `wi2' = `wi'^2 if `in_t'
        quietly summ `wi2' if `in_t', meanonly
        local sw2 = r(sum)

        /* DL estimator */
        local c_dl = `sw' - `sw2' / `sw'
        if `c_dl' <= 0 {
            local tau2 = 0
        }
        else {
            local tau2 = max(0, (`Q' - (`k_t' - 1)) / `c_dl')
        }

        /* -------------------------------------------------------------- */
        /*  Step 2: RE pooled estimate with cluster-robust SE              */
        /* -------------------------------------------------------------- */
        tempvar wi_RE
        quietly gen double `wi_RE' = 1 / (`vi' + `tau2') if `in_t'

        /* Intercept-only WLS with cluster-robust SE */
        quietly regress `yi' [aw=`wi_RE'] if `in_t', vce(cluster `study')

        local theta  = _b[_cons]
        local se_hat = _se[_cons]
        local k_clust = e(N_clust)

        /* Degrees of freedom */
        if "`smallsample'" == "" {
            /* small-sample: t(k-1) */
            local df_hat = `k_clust' - 1
        }
        else {
            /* z-based (large df) */
            local df_hat = 1e6
        }

        /* Inference */
        local t_stat = `theta' / `se_hat'
        local p_val  = 2 * ttail(`df_hat', abs(`t_stat'))
        local crit   = invt(`df_hat', 1 - `alpha' / 2)
        local ci_lb  = `theta' - `crit' * `se_hat'
        local ci_ub  = `theta' + `crit' * `se_hat'

        /* Store */
        matrix `res_mat'[`row', 3]  = `theta'
        matrix `res_mat'[`row', 4]  = `se_hat'
        matrix `res_mat'[`row', 5]  = `df_hat'
        matrix `res_mat'[`row', 6]  = `t_stat'
        matrix `res_mat'[`row', 7]  = `p_val'
        matrix `res_mat'[`row', 8]  = `ci_lb'
        matrix `res_mat'[`row', 9]  = `ci_ub'
        matrix `res_mat'[`row', 10] = `tau2'

        /* Cleanup temp vars for this time point */
        drop `in_t' `wi' `wyi' `dev2' `wi2' `wi_RE'
    }

    /* ================================================================== */
    /*  Build output dataset from matrix                                   */
    /* ================================================================== */
    quietly {
        clear
        svmat double `res_mat', names(col)

        label var time   "Follow-up time"
        label var k      "Number of studies"
        label var theta  "Pooled effect (RE)"
        label var se     "Cluster-robust SE"
        label var df     "Degrees of freedom"
        label var t_stat "t-statistic"
        label var p_val  "p-value (two-sided)"
        label var ci_lb  "Lower bound of CI"
        label var ci_ub  "Upper bound of CI"
        label var tau2   "Between-study variance (DL)"

        gen byte sig = (p_val < `alpha') if !missing(p_val)
        label var sig "Significant (alpha=`alpha')"

        /* Store call metadata as dataset characteristics */
        char _dta[ml_alpha]      "`alpha'"
        char _dta[ml_mink]       "`mink'"
        char _dta[ml_smallsamp]  "`smallsample'"
        char _dta[ml_type]       "ml_meta"
    }

    /* ================================================================== */
    /*  Display table                                                       */
    /* ================================================================== */
    local conf_pct = string((1-`alpha')*100, "%3.0f")

    di _newline
    di as txt "  {hline 72}"
    di as txt "  metaLong: Longitudinal Pooled Effects"
    di as txt "  Method: DerSimonian-Laird  |  Robust SE: Cluster (study)"
    if "`smallsample'" == "" di as txt "  Small-sample correction: t(k-1) df"
    else                     di as txt "  Inference: z-based (no small-sample correction)"
    di as txt "  alpha = `alpha'  |  min_k = `mink'"
    di as txt "  {hline 72}"
    di as txt _col(4) "Time" _col(10) "k" _col(16) "theta" _col(26) "SE" ///
               _col(35) "df" _col(43) "p-val" _col(53) "[`conf_pct'% CI]"
    di as txt "  {hline 72}"

    forvalues r = 1/`n_times' {
        local t_r  = `res_mat'[`r',1]
        local k_r  = `res_mat'[`r',2]
        local th_r = `res_mat'[`r',3]

        if missing(`th_r') {
            di as txt %7.1f `t_r' "  " %4.0f `k_r' ///
               "    (too few studies — skipped)"
        }
        else {
            local se_r  = `res_mat'[`r',4]
            local df_r  = `res_mat'[`r',5]
            local pv_r  = `res_mat'[`r',7]
            local lb_r  = `res_mat'[`r',8]
            local ub_r  = `res_mat'[`r',9]
            local sg_mk = ""
            if `pv_r' < `alpha' local sg_mk "*"

            di as txt %7.1f `t_r' "  " as res %4.0f `k_r' ///
               %10.4f `th_r' %9.4f `se_r' %7.1f `df_r' ///
               %9.4f `pv_r'  "   [" %7.4f `lb_r' "," %7.4f `ub_r' "]" ///
               as txt " `sg_mk'"
        }
    }
    di as txt "  {hline 72}"
    di as txt "  * significant at alpha = `alpha'"

    /* ================================================================== */
    /*  Save results dataset                                               */
    /* ================================================================== */
    if `"`saving'"' != "" {
        if "`replace'" != "" quietly save `saving', replace
        else                  quietly save `saving'
        di as txt _newline "  Results saved to: " as res `"`saving'"'
    }

    restore   /* restore original data */

    /* ================================================================== */
    /*  Return values                                                       */
    /* ================================================================== */
    return matrix meta    = `res_mat'
    return scalar alpha   = `alpha'
    return scalar mink    = `mink'
    return scalar n_times = `n_times'

end
