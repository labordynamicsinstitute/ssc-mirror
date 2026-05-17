*! tarur_kilic.ado — Kılıç (2011) inf-t Unit-Root Test
*! Grid search over γ in G(γ) = 1 - exp(-γ z²ₜ₋₁); ADF-style regression
*!   Δyₜ = β yₜ₋₁ · G(γ) + Σ φᵢ Δyₜ₋ᵢ + uₜ
*! Statistic: inf-t (sup of t-statistic across γ)  — left-tail rejection.

program define tarur_kilic, rclass
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

    mata: _tarur_run_inft("`tv'", "`case'", `maxlags', "`lagmethod'", "`quietly'", "kilic")

    return scalar stat = r(stat)
    return scalar cv1  = r(cv1)
    return scalar cv5  = r(cv5)
    return scalar cv10 = r(cv10)
    return scalar reject1  = r(reject1)
    return scalar reject5  = r(reject5)
    return scalar reject10 = r(reject10)
    return scalar lag      = r(lag)
    return scalar gamma    = r(gamma)
    return local  case     "`case'"
    return local  test     "Kilic (2011) inf-t"
end
