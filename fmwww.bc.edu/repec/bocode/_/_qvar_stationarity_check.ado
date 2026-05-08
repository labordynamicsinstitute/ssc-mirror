*! _qvar_stationarity_check.ado — ADF tests on all variables
*! Version 0.1.0

program define _qvar_stationarity_check
    version 16.0
    syntax varlist [if] [in], [SIGnificance(real 0.05)]

    marksample touse

    di as text ""
    di as text "{hline 78}"
    di as text "  Stationarity Tests (Augmented Dickey-Fuller)"
    di as text "{hline 78}"
    di as text %20s "Variable" %14s "ADF Stat" %12s "p-value" %8s "Lags" %14s "Stationary"
    di as text "{hline 78}"

    foreach var of varlist `varlist' {
        qui count if `touse' & !missing(`var')
        local T = r(N)
        local maxlags = floor(12 * (`T'/100)^0.25)

        qui dfuller `var' if `touse', lags(`maxlags')

        local stat   = r(Zt)
        local pval   = r(p)
        local stnry  = cond(`pval' < `significance', "Yes", "No")

        di as result %20s "`var'" ///
                     %14.4f `stat' ///
                     %12.4f `pval' ///
                     %8.0f  `maxlags' ///
                     %14s   "`stnry'"
    }

    di as text "{hline 78}"
    di as text "  Significance level: `significance'"
    di as text "{hline 78}"
end
