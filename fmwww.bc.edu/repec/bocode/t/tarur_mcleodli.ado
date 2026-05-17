*! tarur_mcleodli.ado — McLeod & Li (1983) Portmanteau Test on Squared Residuals
*! Q = n(n+2) Σ ρ²ₖ/(n-k)  ~ χ²(m)

program define tarur_mcleodli, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in], [ ///
        LAGS(integer 12)     ///
        QUIETly ]

    quietly tarur_init

    marksample touse
    tempvar tv
    quietly gen double `tv' = `varlist' if `touse'

    mata: _tarur_run_mcleodli("`tv'", `lags', "`quietly'")

    return scalar stat   = r(stat)
    return scalar pvalue = r(pvalue)
    return scalar lags   = r(lags)
    return local  test   "McLeod-Li Test"
end
