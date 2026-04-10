*! ml_spline v1.1.0  metaLong for Stata 14.1
*! Spline-Based Nonlinear Time Trend in Longitudinal Meta-Analysis
*! Subir Hait, Michigan State University  |  haitsubi@msu.edu
*!
*! FIX v1.1.0: expanded all single-line { cmd; cmd } blocks to proper
*! multi-line blocks — Stata 14.1 requires open brace at end of if-line.

program define ml_spline, rclass
    version 14.1

    syntax , ///
        METAfile(string asis)  ///
        [                      ///
        DF(integer 3)          ///
        NPred(integer 100)     ///
        ALpha(real 0.05)       ///
        noLINEARtest           ///
        PLOT                   ///
        SAVing(string asis)    ///
        REPLACE                ///
        ]

    if `df' < 1 {
        di as error "df() must be >= 1"
        exit 198
    }

    /* ================================================================== */
    /*  Load and validate ml_meta results                                  */
    /* ================================================================== */
    preserve

    quietly use `"`metafile'"', clear
    capture confirm variable time theta se
    if _rc {
        di as error "metafile() is not a valid ml_meta results file."
        restore
        exit 198
    }

    quietly drop if missing(theta) | missing(se) | se <= 0
    quietly count
    local n_obs = r(N)

    if `n_obs' < `df' + 1 {
        di as error "Too few valid time points (`n_obs') for spline df=`df'."
        restore
        exit 198
    }

    quietly gen double wt = 1 / se^2

    quietly summ time, meanonly
    local t_min = r(min)
    local t_max = r(max)

    /* ================================================================== */
    /*  Build knot positions at quantiles of observed time               */
    /* ================================================================== */
    local n_knots = `df' - 1

    if `n_knots' >= 1 {
        local knot_vals ""
        forvalues kk = 1/`n_knots' {
            local prob = 100 * `kk' / (`n_knots' + 1)
            quietly _pctile time, p(`prob')
            local knot_vals "`knot_vals' `r(r1)'"
        }
        mkspline __spl = time, cubic knots(`knot_vals') displayknots
        unab spline_vars : __spl*
        quietly regress theta `spline_vars' [aw=wt]
    }
    else {
        local spline_vars ""
        quietly regress theta time [aw=wt]
    }

    local r2       = e(r2)
    local df_model = e(df_m)
    local df_resid = e(df_r)

    /* ================================================================== */
    /*  Nonlinearity F-test: spline vs linear                            */
    /* ================================================================== */
    local p_nonlin = .
    local df_extra = 0

    if "`lineartest'" == "" & `df' > 1 {
        local r2_spl   = `r2'
        quietly regress theta time [aw=wt]
        local r2_lin   = e(r2)
        local df_extra = `df_model' - 1
        if `df_extra' > 0 & `df_resid' > 0 {
            local f_nl     = ((`r2_spl' - `r2_lin') / `df_extra') / ///
                             ((1 - `r2_spl') / `df_resid')
            local p_nonlin = Ftail(`df_extra', `df_resid', `f_nl')
        }
        if "`spline_vars'" != "" {
            quietly regress theta `spline_vars' [aw=wt]
        }
        else {
            quietly regress theta time [aw=wt]
        }
    }

    /* ================================================================== */
    /*  Save observed data; build prediction grid in a tempfile          */
    /* ================================================================== */
    tempfile obs_data
    quietly save `obs_data'

    quietly {
        clear
        set obs `npred'
        gen double time = `t_min' + (_n - 1) * (`t_max' - `t_min') / (`npred' - 1)

        if `n_knots' >= 1 {
            mkspline __spl = time, cubic knots(`knot_vals')
        }

        predict double theta_hat, xb
        predict double se_hat,    stdp

        local crit = invt(`df_resid', 1 - `alpha' / 2)
        gen double ci_lb = theta_hat - `crit' * se_hat
        gen double ci_ub = theta_hat + `crit' * se_hat

        if `n_knots' >= 1 {
            capture drop __spl*
        }

        keep time theta_hat se_hat ci_lb ci_ub

        label var time      "Prediction time"
        label var theta_hat "Spline-predicted pooled effect"
        label var se_hat    "SE of prediction"
        label var ci_lb     "Lower CI bound"
        label var ci_ub     "Upper CI bound"

        char _dta[ml_type]  "ml_spline"
        char _dta[ml_df]    "`df'"
        char _dta[ml_alpha] "`alpha'"
    }

    /* ================================================================== */
    /*  Display                                                           */
    /* ================================================================== */
    di _newline
    di as txt "  {hline 58}"
    di as txt "  metaLong: Restricted Cubic Spline Time Trend"
    di as txt "  {hline 58}"
    di as txt "  Spline df       : `df'  |  Internal knots: `n_knots'"
    di as txt "  Valid obs       : `n_obs'"
    di as txt "  Weighted R2     : " as res %6.4f `r2'
    if !missing(`p_nonlin') {
        di as txt "  Nonlinearity p  : " as res %6.4f `p_nonlin' ///
                   as txt "  [F(`df_extra',`df_resid')]"
    }
    di as txt "  Pred range      : [" as res `t_min' ///
               as txt " , " as res `t_max' as txt "]"
    di as txt "  {hline 58}"

    /* ================================================================== */
    /*  Optional quick plot                                               */
    /* ================================================================== */
    if "`plot'" != "" {
        tempfile pred_data
        quietly save `pred_data'
        quietly use `obs_data', clear
        twoway ///
            (rarea ci_ub ci_lb time using `pred_data', ///
                color(maroon%20) lwidth(none)) ///
            (line theta_hat time using `pred_data', ///
                lcolor(maroon) lwidth(medthick)) ///
            (rcap ci_ub ci_lb time if !missing(theta), ///
                lcolor(gs10) lwidth(thin)) ///
            (scatter theta time if !missing(theta), ///
                msymbol(O) mcolor(gs5) msize(small)) ///
            , yline(0, lpattern(dash) lcolor(gs8)) ///
              xtitle("Time") ytitle("Pooled effect") ///
              title("Spline Trend (df=`df')") legend(off)
        quietly use `pred_data', clear
    }

    /* ================================================================== */
    /*  Save prediction dataset                                           */
    /* ================================================================== */
    if `"`saving'"' != "" {
        if "`replace'" != "" {
            quietly save `saving', replace
        }
        else {
            quietly save `saving'
        }
        di as txt "  Saved to: " as res `"`saving'"'
    }

    restore

    return scalar r_squared   = `r2'
    return scalar p_nonlinear = `p_nonlin'
    return scalar df          = `df'
    return scalar df_resid    = `df_resid'
    return scalar n_obs       = `n_obs'
    return scalar alpha       = `alpha'

end
