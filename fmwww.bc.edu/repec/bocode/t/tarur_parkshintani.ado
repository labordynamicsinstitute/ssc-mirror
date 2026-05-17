*! tarur_parkshintani.ado — Park & Shintani (2016) inf-t Unit-Root Test
*! Same grid-search engine as Kılıç (2011) but with P&S critical values.

program define tarur_parkshintani, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in], [ ///
        Case(string)         ///
        MAXLags(integer 8)   ///
        LAGMethod(string)    ///
        QUIETly ]

    quietly tarur_init
    if "`case'"      == "" local case      "raw"
    if "`lagmethod'" == "" local lagmethod "aic"

    marksample touse
    tempvar tv
    quietly gen double `tv' = `varlist' if `touse'

    mata: _tarur_run_inft("`tv'", "`case'", `maxlags', "`lagmethod'", "`quietly'", "parkshintani")

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
    return local  test     "Park & Shintani (2016) inf-t"
end
