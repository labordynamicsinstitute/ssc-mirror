*! tarur_sollis2009.ado — Sollis (2009) Asymmetric ESTAR (AESTAR) unit-root test
*! Δyₜ = φ₁ y³ₜ₋₁ + φ₂ y⁴ₜ₋₁ + Σ κᵢ Δyₜ₋ᵢ + ηₜ
*! F_AE = joint test of φ₁ = φ₂ = 0          — right-tail rejection
*! Fas  = standard F on φ₂ = 0 (symmetry check)

program define tarur_sollis2009, rclass
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

    mata: _tarur_run_sollis2009("`tv'", "`case'", `maxlags', "`lagmethod'", "`quietly'")

    return scalar stat   = r(stat)
    return scalar cv1    = r(cv1)
    return scalar cv5    = r(cv5)
    return scalar cv10   = r(cv10)
    return scalar reject1  = r(reject1)
    return scalar reject5  = r(reject5)
    return scalar reject10 = r(reject10)
    return scalar lag      = r(lag)
    return scalar phi1     = r(phi1)
    return scalar phi2     = r(phi2)
    return scalar Fas      = r(Fas)
    return scalar Fas_p    = r(Fas_p)
    return local  case     "`case'"
    return local  test     "Sollis (2009) AESTAR Test"
end
