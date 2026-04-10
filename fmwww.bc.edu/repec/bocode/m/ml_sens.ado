*! ml_sens v1.0.0  metaLong for Stata 14.1
*! Time-Varying Sensitivity Analysis via Longitudinal ITCV
*! Subir Hait, Michigan State University  |  haitsubi@msu.edu
*!
*! Computes the Impact Threshold for a Confounding Variable (ITCV) at each
*! follow-up time using pooled estimates from ml_meta.
*!
*! Reference: Frank, K.A. (2000). Sociological Methods & Research, 29(2), 147-194.
*!
*! Mathematical background
*! -----------------------
*! At time t, let theta_t = pooled effect, sy2_t = weighted variance of yi,
*! se_t = cluster-robust SE, df_t = degrees of freedom.
*!
*! Correlation-scale: r_t = theta_t / sqrt(theta_t^2 + sy2_t)
*! Raw ITCV:          itcv_t = sqrt(|r_t|)
*! Significance-adjusted:
*!   theta_star_t = |theta_t| - crit_t * se_t
*!   if theta_star_t > 0:
*!     r_star_t = theta_star_t / sqrt(theta_star_t^2 + sy2_t)
*!     itcv_alpha_t = sqrt(|r_star_t|)
*!   else: itcv_alpha_t = 0
*!
*! fragile at time t if itcv_alpha_t < delta

program define ml_sens, rclass
    version 14.1

    syntax varlist(min=2 max=2 numeric) [if] [in] , ///
        STUDy(varname)          ///
        TIME(varname numeric)   ///
        METAfile(string asis)   ///  path to saved ml_meta results dataset
        [                       ///
        ALpha(real 0.05)        ///
        DELTA(real 0.15)        ///  fragility threshold
        SAVing(string asis)     ///
        REPLACE                 ///
        ]

    tokenize `varlist'
    local yi `1'
    local vi `2'

    /* ---- mark sample ---- */
    marksample touse
    markout `touse' `time' `yi' `vi'
    quietly replace `touse' = 0 if `study' == ""

    /* ---- load meta results ---- */
    preserve

    quietly use `"`metafile'"', clear

    /* validate it's an ml_meta results file */
    capture confirm variable time theta se df tau2
    if _rc {
        di as error "metafile() does not look like ml_meta output (missing columns)."
        exit 198
    }

    /* extract meta results into matrix */
    local n_times = _N
    tempname meta_mat
    mkmat time k theta se df t_stat p_val ci_lb ci_ub tau2, matrix(`meta_mat')

    restore

    /* ---- result matrix: time theta se df sy r_effect itcv itcv_alpha fragile ---- */
    tempname sens_mat
    matrix `sens_mat' = J(`n_times', 9, .)
    matrix colnames `sens_mat' = time theta se df sy r_effect itcv itcv_alpha fragile

    /* ---- preserve and work on analysis data ---- */
    preserve
    quietly keep if `touse'
    quietly keep `yi' `vi' `study' `time'

    /* ================================================================== */
    /*  Loop over time points from meta results                            */
    /* ================================================================== */
    forvalues row = 1/`n_times' {

        local t_val   = `meta_mat'[`row', 1]
        local theta_t = `meta_mat'[`row', 3]
        local se_t    = `meta_mat'[`row', 4]
        local df_t    = `meta_mat'[`row', 5]
        local tau2_t  = `meta_mat'[`row', 10]

        matrix `sens_mat'[`row', 1] = `t_val'
        matrix `sens_mat'[`row', 2] = `theta_t'
        matrix `sens_mat'[`row', 3] = `se_t'
        matrix `sens_mat'[`row', 4] = `df_t'

        /* Skip if meta estimate is missing */
        if missing(`theta_t') | missing(`se_t') | missing(`df_t') continue

        /* ---- Subset to current time point ---- */
        tempvar in_t
        quietly gen byte `in_t' = (`time' == `t_val')

        /* ---- tau2-adjusted weights ---- */
        local tau2_use = max(0, `tau2_t')
        tempvar wi_RE
        quietly gen double `wi_RE' = 1 / (`vi' + `tau2_use') if `in_t'

        /* ---- Weighted variance of yi (sy2) ---- */
        quietly summ `wi_RE' if `in_t', meanonly
        local sw = r(sum)

        tempvar wdev2
        quietly gen double `wdev2' = `wi_RE' * (`yi' - `theta_t')^2 if `in_t'
        quietly summ `wdev2' if `in_t', meanonly
        local sy2 = r(sum) / `sw'
        local sy  = sqrt(`sy2')

        /* ---- Correlation-scale effect ---- */
        local denom = sqrt(`theta_t'^2 + `sy2')
        if `denom' <= 0 {
            drop `in_t' `wi_RE' `wdev2'
            continue
        }
        local r_effect = `theta_t' / `denom'

        /* ---- Raw ITCV ---- */
        local itcv = sqrt(abs(`r_effect'))

        /* ---- Significance-adjusted ITCV ---- */
        if `df_t' > 1e5 {
            /* z-based */
            local crit = invnormal(1 - `alpha' / 2)
        }
        else {
            local crit = invt(`df_t', 1 - `alpha' / 2)
        }

        local theta_star = abs(`theta_t') - `crit' * `se_t'

        if `theta_star' <= 0 {
            local itcv_alpha = 0
        }
        else {
            local denom_star = sqrt(`theta_star'^2 + `sy2')
            local r_star     = `theta_star' / `denom_star'
            local itcv_alpha = sqrt(abs(`r_star'))
        }

        /* fragile if itcv_alpha < delta */
        local fragile = (`itcv_alpha' < `delta')

        /* Store */
        matrix `sens_mat'[`row', 5] = `sy'
        matrix `sens_mat'[`row', 6] = `r_effect'
        matrix `sens_mat'[`row', 7] = `itcv'
        matrix `sens_mat'[`row', 8] = `itcv_alpha'
        matrix `sens_mat'[`row', 9] = `fragile'

        drop `in_t' `wi_RE' `wdev2'
    }

    /* ================================================================== */
    /*  Build results dataset                                              */
    /* ================================================================== */
    quietly {
        clear
        svmat double `sens_mat', names(col)

        label var time       "Follow-up time"
        label var theta      "Pooled effect"
        label var se         "Cluster-robust SE"
        label var df         "Degrees of freedom"
        label var sy         "Weighted SD of effects (sqrt of sy2)"
        label var r_effect   "Effect on correlation scale (r)"
        label var itcv       "Raw ITCV: threshold to nullify estimate"
        label var itcv_alpha "Adj. ITCV: threshold to lose significance"
        label var fragile    "1 if itcv_alpha < delta (`delta')"

        char _dta[ml_type]   "ml_sens"
        char _dta[ml_alpha]  "`alpha'"
        char _dta[ml_delta]  "`delta'"
    }

    /* ================================================================== */
    /*  Compute summary statistics                                         */
    /* ================================================================== */
    quietly summ itcv_alpha, meanonly
    local itcv_min  = r(min)
    local itcv_mean = r(mean)

    quietly count if fragile == 1
    local n_fragile = r(N)
    quietly count if !missing(itcv_alpha)
    local n_valid = r(N)
    local frag_prop = cond(`n_valid' > 0, `n_fragile' / `n_valid', .)

    /* ================================================================== */
    /*  Display                                                            */
    /* ================================================================== */
    di _newline
    di as txt "  {hline 72}"
    di as txt "  metaLong: Longitudinal Sensitivity Analysis (ITCV)"
    di as txt "  Fragility threshold (delta) = `delta'"
    di as txt "  {hline 72}"
    di as txt _col(4) "Time" _col(12) "theta" _col(21) "sy" ///
               _col(30) "r_effect" _col(40) "ITCV" _col(50) "ITCV_adj" ///
               _col(60) "Fragile?"
    di as txt "  {hline 72}"

    forvalues row = 1/`n_times' {
        local t_r   = `sens_mat'[`row', 1]
        local th_r  = `sens_mat'[`row', 2]
        local sy_r  = `sens_mat'[`row', 5]
        local re_r  = `sens_mat'[`row', 6]
        local iv_r  = `sens_mat'[`row', 7]
        local ia_r  = `sens_mat'[`row', 8]
        local fg_r  = `sens_mat'[`row', 9]

        if missing(`th_r') {
            di as txt %7.1f `t_r' "    (missing estimate)"
            continue
        }

        local frag_lbl = cond(`fg_r' == 1, "YES", "no")
        local frag_col = cond(`fg_r' == 1, "as err", "as res")

        di as txt  %7.1f `t_r' ///
           as res  %9.4f `th_r' %9.4f `sy_r' %9.4f `re_r' ///
                   %9.4f `iv_r' %9.4f `ia_r' " " ///
           `frag_col' "  `frag_lbl'"
    }
    di as txt "  {hline 72}"
    di as txt "  ITCV_adj min  = " as res %6.4f `itcv_min'
    di as txt "  ITCV_adj mean = " as res %6.4f `itcv_mean'
    di as txt "  Fragile prop  = " as res %6.4f `frag_prop' ///
               as txt "  (`n_fragile' / `n_valid' time points)"

    /* ================================================================== */
    /*  Save                                                               */
    /* ================================================================== */
    if `"`saving'"' != "" {
        if "`replace'" != "" quietly save `saving', replace
        else                  quietly save `saving'
        di as txt _newline "  Results saved to: " as res `"`saving'"'
    }

    restore

    /* ================================================================== */
    /*  Return                                                             */
    /* ================================================================== */
    return matrix sens      = `sens_mat'
    return scalar itcv_min  = `itcv_min'
    return scalar itcv_mean = `itcv_mean'
    return scalar frag_prop = `frag_prop'
    return scalar delta     = `delta'
    return scalar alpha     = `alpha'

end
