*! version 2.0  WuLianghai WuHanyan ChenLiwen  19jun2026
*! ----------------------------------------------------------------------
*! Computes confidence intervals for the mean using the t-distribution.
*!
*! Authors:
*!   Wu Lianghai
*!     School of Business, Anhui University of Technology (AHUT),
*!     Ma'anshan, China
*!     Email: agd2010@yeah.net
*!
*!   Wu Hanyan
*!     School of Economics and Management,
*!     Nanjing University of Aeronautics and Astronautics (NUAA), China
*!     Email: 2325476320@qq.com
*!
*!   Chen Liwen
*!     School of Business, Anhui University of Technology (AHUT),
*!     Ma'anshan, China
*!     Email: 2184844526@qq.com
*! ----------------------------------------------------------------------

program define myinterval, rclass
    version 13.0

    syntax varlist(numeric) [if] [in] [, level(cilevel)]

    marksample touse

    quietly count if `touse'
    if r(N) < 2 {
        display as error "insufficient observations (need at least 2)"
        exit 2001
    }

    display _newline as text "{hline 64}"
    display as text "Confidence Intervals for the Mean (t-distribution)"
    display as text "{hline 64}"

    local varcount = 0

    foreach var of local varlist {
        quietly summarize `var' if `touse'
        local N = r(N)
        if `N' < 2 {
            display as error _newline "`var': insufficient observations (N = `N')"
            continue
        }

        local df    = `N' - 1
        local mean  = r(mean)
        local se    = sqrt(r(Var) / `N')
        local tcrit = invt(`df', (100 + `level') / 200)
        local lb    = `mean' - `tcrit' * `se'
        local ub    = `mean' + `tcrit' * `se'

        local varcount = `varcount' + 1

        display _newline as text "Variable: " as result "`var'"
        display as text "  Confidence Level: " as result %5.2f `level' "%"
        display as text "  N   = " as result %9.0f `N'   ///
                _col(36) as text "Mean = " as result %12.8f `mean'
        display as text "  SE  = " as result %12.8f `se'  ///
                _col(36) as text "df   = " as result %9.0f `df'
        display as text "  " as result %5.0f `level' "% CI:" ///
                _col(15) as text "[" as result %12.8f `lb' ///
                as text ", " as result %12.8f `ub' as text "]"

        return scalar N_`var'    = `N'
        return scalar mean_`var' = `mean'
        return scalar se_`var'   = `se'
        return scalar df_`var'   = `df'
        return scalar lb_`var'   = `lb'
        return scalar ub_`var'   = `ub'
    }

    return scalar level = `level'
    return scalar vars  = `varcount'

    display _newline as text "{hline 64}"
end
