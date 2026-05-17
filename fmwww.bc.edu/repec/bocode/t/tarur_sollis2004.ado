*! tarur_sollis2004.ado — Sollis (2004) ST-TAR Asymmetric Unit-Root Test
*! NLS smooth-transition detrending then asymmetric TAR regression on
*! residuals: Δresₜ = ρ⁺ I·resₜ₋₁ + ρ⁻ (1-I)·resₜ₋₁ + Σ φᵢ Δresₜ₋ᵢ + uₜ
*! Iₜ = 1 if resₜ₋₁ ≥ 0
*! F joint test of ρ⁺ = ρ⁻ = 0 — right-tail rejection.

program define tarur_sollis2004, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in], [ ///
        MODel(string)        ///
        MAXLags(integer 8)   ///
        QUIETly ]

    quietly tarur_init
    if "`model'" == "" local model "A"
    local model = upper("`model'")
    if !inlist("`model'", "A","B","C") {
        di as error "Sollis (2004) model must be A, B, or C."
        exit 198
    }

    marksample touse
    tempvar tv
    quietly gen double `tv' = `varlist' if `touse'

    mata: _tarur_run_sollis2004("`tv'", "`model'", `maxlags', "`quietly'")

    return scalar stat = r(stat)
    return scalar cv1  = r(cv1)
    return scalar cv5  = r(cv5)
    return scalar cv10 = r(cv10)
    return scalar reject1  = r(reject1)
    return scalar reject5  = r(reject5)
    return scalar reject10 = r(reject10)
    return scalar lag      = r(lag)
    return local  model    "`model'"
    return local  test     "Sollis (2004) ST-TAR Model `model'"
end
