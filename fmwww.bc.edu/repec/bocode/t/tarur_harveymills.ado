*! tarur_harveymills.ado — Harvey & Mills (2002) Double Smooth-Transition UR Test
*! Two logistic transitions in the NLS detrending (Models A/B/C),
*! then ADF on residuals.  Left-tail rejection.

program define tarur_harveymills, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in], [ ///
        MODel(string)        ///
        MAXLags(integer 8)   ///
        LAGMethod(string)    ///
        QUIETly ]

    quietly tarur_init
    if "`model'"     == "" local model     "A"
    if "`lagmethod'" == "" local lagmethod "aic"
    local model = upper("`model'")
    if !inlist("`model'", "A","B","C") {
        di as error "Harvey-Mills model must be A, B, or C."
        exit 198
    }

    marksample touse
    tempvar tv
    quietly gen double `tv' = `varlist' if `touse'

    mata: _tarur_run_hm("`tv'", "`model'", `maxlags', "`lagmethod'", "`quietly'")

    return scalar stat = r(stat)
    return scalar cv1  = r(cv1)
    return scalar cv5  = r(cv5)
    return scalar cv10 = r(cv10)
    return scalar reject1  = r(reject1)
    return scalar reject5  = r(reject5)
    return scalar reject10 = r(reject10)
    return scalar lag      = r(lag)
    return local  model    "`model'"
    return local  test     "Harvey & Mills (2002) Model `model'"
end
