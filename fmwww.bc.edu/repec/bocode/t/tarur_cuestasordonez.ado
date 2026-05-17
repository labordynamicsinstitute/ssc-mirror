*! tarur_cuestasordonez.ado — Cuestas & Ordóñez (2014) NLS-detrend + KSS
*! Apply logistic-trend detrending then KSS cubic auxiliary.
*! Statistic: t(β₁) on y³ — left-tail rejection.

program define tarur_cuestasordonez, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in], [ ///
        MAXLags(integer 8)   ///
        LAGMethod(string)    ///
        QUIETly ]

    quietly tarur_init
    if "`lagmethod'" == "" local lagmethod "aic"

    marksample touse
    tempvar tv
    quietly gen double `tv' = `varlist' if `touse'

    mata: _tarur_run_cuestaso("`tv'", `maxlags', "`lagmethod'", "`quietly'")

    return scalar stat = r(stat)
    return scalar cv1  = r(cv1)
    return scalar cv5  = r(cv5)
    return scalar cv10 = r(cv10)
    return scalar reject1  = r(reject1)
    return scalar reject5  = r(reject5)
    return scalar reject10 = r(reject10)
    return scalar lag      = r(lag)
    return local  test     "Cuestas & Ordonez (2014)"
end
