*! tarur_huchen.ado — Hu & Chen (2016) Modified Wald Unit Root Test (3-param)
*! Δyₜ = β₁ yₜ₋₁ + β₂ y²ₜ₋₁ + β₃ y³ₜ₋₁ + Σ ρᵢ Δyₜ₋ᵢ + uₜ
*! τ = τ²_I + 𝟙(β̂₃<0)·t²(β₃=0)  — right-tail rejection.

program define tarur_huchen, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in], [ ///
        Case(string)         ///
        MAXLags(integer 8)   ///
        LAGMethod(string)    ///
        QUIETly ]

    quietly tarur_init
    if "`case'"      == "" local case      "demeaned"
    if "`lagmethod'" == "" local lagmethod "aic"

    marksample touse
    tempvar tv
    quietly gen double `tv' = `varlist' if `touse'

    mata: _tarur_run_huchen("`tv'", "`case'", `maxlags', "`lagmethod'", "`quietly'")

    return scalar stat = r(stat)
    return scalar cv1  = r(cv1)
    return scalar cv5  = r(cv5)
    return scalar cv10 = r(cv10)
    return scalar reject1  = r(reject1)
    return scalar reject5  = r(reject5)
    return scalar reject10 = r(reject10)
    return scalar lag      = r(lag)
    return scalar beta3    = r(beta3)
    return local  case     "`case'"
    return local  test     "Hu & Chen (2016) Modified Wald Test"
end
