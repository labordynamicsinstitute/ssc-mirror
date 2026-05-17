*! tarur_cuestasgarratt.ado — Cuestas & Garratt (2011) χ² Unit-Root Test
*! Cubic polynomial detrending, then Δyₜ = β₁ y³ₜ₋₁ + β₂ y²ₜ₋₁ + ...
*! χ² test on (β₁,β₂) jointly  — right-tail rejection.

program define tarur_cuestasgarratt, rclass
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

    mata: _tarur_run_cuestasg("`tv'", `maxlags', "`lagmethod'", "`quietly'")

    return scalar stat = r(stat)
    return scalar cv1  = r(cv1)
    return scalar cv5  = r(cv5)
    return scalar cv10 = r(cv10)
    return scalar reject1  = r(reject1)
    return scalar reject5  = r(reject5)
    return scalar reject10 = r(reject10)
    return scalar lag      = r(lag)
    return local  test     "Cuestas & Garratt (2011)"
end
