*! mixi12_unit 1.0.1  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Cross-variable integration-order battery for mixed I(1)/I(2) analysis.
*  Delegates per-variable testing to the user's dptest package
*  (c:/ado/plus/d/dptest.ado), then assembles a single clean summary table
*  with the verdict of every test for every variable.

program define mixi12_unit, rclass
    version 14
    syntax varlist(ts) [if] [in] ,             ///
        [                                       ///
        TEst(string)                            ///
        DET(string)                             ///
        MAXLag(integer -1)                      ///
        MAXDiff(integer 3)                      ///
        BANDwidth(integer -1)                   ///
        LEvel(integer 5)                        ///
        CRIT(string)                            ///
        SAVing(string)                          ///
        ]

    if "`test'" == "" local test "all"
    if "`det'"  == "" local det  "const"
    if "`crit'" == "" local crit "bic"

    capture which dptest
    if _rc {
        di as err "mixi12_unit requires the {bf:dptest} package."
        di as err `"Run "ssc install dptest" to install it."'
        exit 199
    }

    marksample touse, novarlist
    qui count if `touse'
    if r(N) < 25 {
        di as err "mixi12_unit: need at least 25 observations (have `=r(N)')."
        exit 2001
    }

    local k : word count `varlist'

    // result matrices
    tempname IO DPD HFF HFD HZZ HZD
    matrix `IO'  = J(`k', 1, .)
    matrix `DPD' = J(`k', 1, .)
    matrix `HFF' = J(`k', 1, .)
    matrix `HFD' = J(`k', 1, .)
    matrix `HZZ' = J(`k', 1, .)
    matrix `HZD' = J(`k', 1, .)
    local rownames ""

    di
    di as text "{hline 78}"
    di as text "{bf:mixi12_unit — cross-variable integration-order battery}"
    di as text "{hline 78}"
    di as text _col(2) "Test(s):"      _col(28) "`test'"
    di as text _col(2) "Deterministics:" _col(28) "`det'"
    di as text _col(2) "Level:"          _col(28) "`level'%"
    di as text _col(2) "Lag selection:"  _col(28) "`crit'"
    di as text _col(2) "N:"              _col(28) "`=r(N)'"
    di as text "{hline 78}"

    local i 0
    quietly {
        foreach v of varlist `varlist' {
            local ++i
            local rownames "`rownames' `v'"

            local optstr ""
            if `maxlag'    >= 0 local optstr "`optstr' maxlag(`maxlag')"
            if `bandwidth' >= 0 local optstr "`optstr' bandwidth(`bandwidth')"

            cap noi dptest `v' if `touse', ///
                test(`test') det(`det') level(`level') crit(`crit')   ///
                maxdiff(`maxdiff') `optstr' notable
            if _rc continue

            cap matrix `DPD'[`i',1] = r(dp_d)
            cap matrix `HFF'[`i',1] = r(hf_F)
            cap matrix `HFD'[`i',1] = r(hf_d)
            cap matrix `HZZ'[`i',1] = r(hz_ZF)
            cap matrix `HZD'[`i',1] = r(hz_d)

            // consensus integration order:
            //   take dp_d if available, else hz_d, else hf_d
            local ord = .
            cap local ord = `DPD'[`i',1]
            if `ord' == . cap local ord = `HZD'[`i',1]
            if `ord' == . cap local ord = `HFD'[`i',1]
            if `ord' < . matrix `IO'[`i',1] = `ord'
        }
    }

    matrix rownames `IO'  = `rownames'
    matrix rownames `DPD' = `rownames'
    matrix rownames `HFF' = `rownames'
    matrix rownames `HFD' = `rownames'
    matrix rownames `HZZ' = `rownames'
    matrix rownames `HZD' = `rownames'

    // pretty cross-variable table
    di as text _col(2) "Variable"       ///
       _col(20) "DP d"                   ///
       _col(32) "HF F"                   ///
       _col(44) "HZ Z(F*)"               ///
       _col(58) "Order"
    di as text "{hline 78}"
    local i 0
    foreach v of varlist `varlist' {
        local ++i
        local ord = `IO'[`i',1]
        local mark = "—"
        if `ord' == 0 local mark "I(0)"
        if `ord' == 1 local mark "I(1)"
        if `ord' == 2 local mark "I(2)"
        if `ord' >= 3 local mark "I(`=`ord'')"

        local dp = `DPD'[`i',1]
        local hf = `HFF'[`i',1]
        local hz = `HZZ'[`i',1]
        di as result _col(2) "`v'" ///
            _col(20) %8.3f `dp' ///
            _col(32) %8.3f `hf' ///
            _col(44) %8.3f `hz' ///
            _col(58) "{bf:`mark'}"
    }
    di as text "{hline 78}"

    if "`saving'" != "" {
        preserve
        clear
        qui set obs `k'
        gen str32 variable = ""
        gen byte  order    = .
        gen double DP_d    = .
        gen double HF_F    = .
        gen double HZ_ZF   = .
        local i 0
        foreach v of varlist `varlist' {
            local ++i
            qui replace variable = "`v'" in `i'
            qui replace order    = `IO'[`i',1] in `i'
            qui replace DP_d     = `DPD'[`i',1] in `i'
            qui replace HF_F     = `HFF'[`i',1] in `i'
            qui replace HZ_ZF    = `HZZ'[`i',1] in `i'
        }
        qui save "`saving'", replace
        restore
    }

    return matrix order = `IO'
    return matrix DPd   = `DPD'
    return matrix HFF   = `HFF'
    return matrix HFd   = `HFD'
    return matrix HZZ   = `HZZ'
    return matrix HZd   = `HZD'
    return local trend  "`det'"
    return scalar k     = `k'
end
