*! tarur_arch.ado — Engle (1982) LM Test for ARCH Effects
*! Regress e²ₜ on a constant and q lags of e²ₜ; LM = n·R² ~ χ²(q).

program define tarur_arch, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in], [ ///
        LAGS(integer 4)      ///
        QUIETly ]

    quietly tarur_init

    marksample touse
    tempvar tv
    quietly gen double `tv' = `varlist' if `touse'

    mata: _tarur_run_arch("`tv'", `lags', "`quietly'")

    return scalar stat   = r(stat)
    return scalar pvalue = r(pvalue)
    return scalar lags   = r(lags)
    return local  test   "Engle ARCH Test"
end
