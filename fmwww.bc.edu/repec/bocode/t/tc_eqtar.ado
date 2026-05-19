*! tc_eqtar.ado -- EQ-TAR / Band-TAR / RD-TAR (Balke-Fomby 1997)
program define tc_eqtar, rclass
    version 14
    syntax varname(numeric) [if] [in] [, TYPE(string) THReshold(real -999) MAXLag(integer 0) TRIM(real 0.15) NGrid(integer 300)]
    if "`type'" == "" local type "eq"
    marksample touse
    _tc_load

    local drift = cond("`type'"=="rd", 1, 0)
    local th_in = `threshold'
    if `threshold' == -999 local th_in .

    tempname rho1 rmid rho2 dlow dmid dhigh thr lags n1 n2
    mata: tc_run_eqtar("`varlist'", "`touse'", `th_in', `maxlag', `trim', `ngrid', `drift', "`rho1'", "`rmid'", "`rho2'", "`dlow'", "`dmid'", "`dhigh'", "`thr'", "`lags'", "`n1'", "`n2'")

    di
    di as text "{hline 72}"
    if `drift' di as result "  RD-TAR (Balke-Fomby 1997) -- returning drift"
    else       di as result "  EQ-TAR / Band-TAR (Balke-Fomby 1997)"
    di as text "{hline 72}"
    if `drift' {
        di as text "  drift_low                : " as result %10.4f scalar(`dlow')
        di as text "  drift_mid                : " as result %10.4f scalar(`dmid')
        di as text "  drift_high               : " as result %10.4f scalar(`dhigh')
    }
    else {
        di as text "  rho_low                  : " as result %10.4f scalar(`rho1')
        di as text "  rho_mid                  : " as result %10.4f scalar(`rmid')
        di as text "  rho_high                 : " as result %10.4f scalar(`rho2')
    }
    di as text "  Threshold                : " as result %10.4f scalar(`thr')
    di as text "{hline 72}"

    return scalar threshold = scalar(`thr')
    return local cmd "tc_eqtar"
end
