*! tarur_enderssiklos.ado — Enders & Siklos (2001) TAR Cointegration Test
*! Step 1: OLS  yₜ = α + β xₜ + uₜ  → residuals û.
*! Step 2: Apply Enders & Granger (1998) MTAR test to û (case=raw).

program define tarur_enderssiklos, rclass
    version 14.0
    syntax varlist(min=2 max=2 numeric ts) [if] [in], [ ///
        MAXLags(integer 8)   ///
        LAGMethod(string)    ///
        QUIETly ]

    quietly tarur_init
    if "`lagmethod'" == "" local lagmethod "aic"

    tokenize "`varlist'"
    local y "`1'"
    local x "`2'"

    marksample touse
    tempvar yv xv
    quietly gen double `yv' = `y' if `touse'
    quietly gen double `xv' = `x' if `touse'

    mata: _tarur_run_es("`yv'", "`xv'", `maxlags', "`lagmethod'", "`quietly'")

    return scalar stat = r(stat)
    return scalar cv1  = r(cv1)
    return scalar cv5  = r(cv5)
    return scalar cv10 = r(cv10)
    return scalar reject1  = r(reject1)
    return scalar reject5  = r(reject5)
    return scalar reject10 = r(reject10)
    return scalar lag      = r(lag)
    return scalar rho_pos  = r(rho_pos)
    return scalar rho_neg  = r(rho_neg)
    return local  test     "Enders & Siklos (2001) TAR Cointegration"
end
