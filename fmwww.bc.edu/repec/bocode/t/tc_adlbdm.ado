*! tc_adlbdm.ado -- ADL-BDM (Li & Lee 2010)
program define tc_adlbdm, rclass
    version 14
    syntax varlist(min=2 numeric) [if] [in] [, MAXLag(integer 4) TRIM(real 0.15) NGrid(integer 200) CASE(string)]
    if "`case'" == "" local case "c"
    gettoken depvar indepvars : varlist
    marksample touse
    _tc_load

    tempname stat thr cv
    mata: tc_run_adlbdm("`depvar'", "`indepvars'", "`touse'", `maxlag', `trim', `ngrid', "`case'", "`stat'", "`thr'", "`cv'")

    di
    di as text "{hline 72}"
    di as result "  ADL-BDM test (Li & Lee 2010)"
    di as text "{hline 72}"
    di as text "  sup-|t| statistic        : " as result %10.4f scalar(`stat')
    di as text "  Threshold                : " as result %10.4f scalar(`thr')
    di as text "  Critical (1% / 5% / 10%) : " as result %8.3f el(`cv',1,1) " " %8.3f el(`cv',1,2) " " %8.3f el(`cv',1,3)
    di as text "{hline 72}"

    return scalar sup_t = scalar(`stat')
    return matrix cv = `cv'
    return local cmd "tc_adlbdm"
end
