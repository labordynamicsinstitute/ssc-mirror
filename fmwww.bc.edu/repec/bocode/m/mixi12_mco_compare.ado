*! mixi12_mco_compare 1.0.0  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Side-by-side comparison of every multicointegration estimator and every
*  test currently available via the user's {bf:multicoint} package.
*  Runs OLS, FM-OLS, DOLS, CCR, IM-OLS and TAOLS in turn, then collects the
*  long-run coefficient on the cumulated stock regressor (β_cum), its
*  standard error, R², the Granger-Lee (gl) statistic, the
*  Engsted-Gonzalo-Haldrup one-step (egh) statistic and the Sun et al.
*  TAOLS adaptive F.  Prints one clean comparison table.

program define mixi12_mco_compare, rclass
    version 14
    syntax varlist(min=2 ts numeric) [if] [in],                  ///
        [                                                         ///
        TRend(string)                                             ///
        AUTOLag(string)                                           ///
        MAXLag(integer 8)                                         ///
        LEAds(integer 2)                                          ///
        DLags(integer 2)                                          ///
        KERnel(string)                                            ///
        K(integer 12)                                             ///
        SAVing(string)                                            ///
        ]
    gettoken y x : varlist

    capture which multicoint
    if _rc {
        di as err "mixi12_mco_compare requires the {bf:multicoint} package."
        di as err `"Run "ssc install multicoint" or place multicoint.ado on the adopath."'
        exit 199
    }

    if "`trend'"   == "" local trend "c"
    if "`autolag'" == "" local autolag "bic"
    if "`kernel'"  == "" local kernel "bartlett"

    local taglist "ols fmols dols ccr imols taols"
    local nest : word count `taglist'

    tempname B SE R2 GL EGH TAOLS
    matrix `B'    = J(`nest', 1, .)
    matrix `SE'   = J(`nest', 1, .)
    matrix `R2'   = J(`nest', 1, .)
    matrix `GL'   = J(`nest', 1, .)
    matrix `EGH'  = J(`nest', 1, .)
    matrix `TAOLS' = J(`nest', 1, .)

    di
    di as text "{hline 78}"
    di as text "{bf:mixi12_mco_compare — multicointegration: estimators × tests}"
    di as text "{hline 78}"
    di as text _col(2) "Flow y_t :"  _col(20) "`y'"
    di as text _col(2) "Flow x_t :"  _col(20) "`x'"
    di as text _col(2) "Trend     :" _col(20) "`trend'"
    di as text _col(2) "Lead/Lag  :" _col(20) "`leads' / `dlags'"
    di as text _col(2) "Kernel    :" _col(20) "`kernel'"
    di as text _col(2) "TAOLS k   :" _col(20) "`k'"
    di as text "{hline 78}"

    local i 0
    quietly {
        foreach est of local taglist {
            local ++i
            local optstr = "est(`est') test(all) trend(`trend')"
            local optstr "`optstr' autolag(`autolag') maxlag(`maxlag')"
            local optstr "`optstr' leads(`leads') dlags(`dlags')"
            local optstr "`optstr' kernel(`kernel') k(`k') notable"

            cap noi multicoint `y' `x' `if' `in', `optstr'
            if _rc continue

            // pick coefficient on the cumulated regressor (suffix _cum)
            local firstx : word 1 of `x'
            local cumname "`firstx'_cum"
            cap matrix `B'[`i',1]  = _b[`cumname']
            cap matrix `SE'[`i',1] = _se[`cumname']
            cap matrix `R2'[`i',1] = e(r2)
            cap matrix `GL'[`i',1]    = e(gl_stat)
            cap matrix `EGH'[`i',1]   = e(egh_stat)
            cap matrix `TAOLS'[`i',1] = e(taols_Fa)
        }
    }

    matrix rownames `B'    = `taglist'
    matrix rownames `SE'   = `taglist'
    matrix rownames `R2'   = `taglist'
    matrix rownames `GL'   = `taglist'
    matrix rownames `EGH'  = `taglist'
    matrix rownames `TAOLS' = `taglist'

    di as text _col(2) "Estimator" _col(16) "β_cum" _col(28) "S.E." ///
        _col(40) "R²"  _col(50) "GL"  _col(60) "EGH"  _col(70) "TAOLS"
    di as text "{hline 78}"
    local i 0
    foreach est of local taglist {
        local ++i
        local lab : copy local est
        if "`lab'" == "ols"   local lab "OLS"
        if "`lab'" == "fmols" local lab "FM-OLS"
        if "`lab'" == "dols"  local lab "DOLS"
        if "`lab'" == "ccr"   local lab "CCR"
        if "`lab'" == "imols" local lab "IM-OLS"
        if "`lab'" == "taols" local lab "TAOLS"
        di as result _col(2) "`lab'" ///
            _col(16) %8.4f `B'[`i',1] ///
            _col(28) %8.4f `SE'[`i',1] ///
            _col(40) %6.3f `R2'[`i',1] ///
            _col(50) %8.3f `GL'[`i',1] ///
            _col(60) %8.3f `EGH'[`i',1] ///
            _col(70) %8.3f `TAOLS'[`i',1]
    }
    di as text "{hline 78}"

    if "`saving'" != "" {
        preserve
        clear
        qui set obs `nest'
        gen str10 estimator = ""
        gen double bcum = .
        gen double se   = .
        gen double r2   = .
        gen double gl   = .
        gen double egh  = .
        gen double taols_F = .
        local i 0
        foreach est of local taglist {
            local ++i
            qui replace estimator = "`est'" in `i'
            qui replace bcum    = `B'[`i',1] in `i'
            qui replace se      = `SE'[`i',1] in `i'
            qui replace r2      = `R2'[`i',1] in `i'
            qui replace gl      = `GL'[`i',1] in `i'
            qui replace egh     = `EGH'[`i',1] in `i'
            qui replace taols_F = `TAOLS'[`i',1] in `i'
        }
        qui save "`saving'", replace
        restore
    }

    return matrix bcum = `B'
    return matrix se   = `SE'
    return matrix r2   = `R2'
    return matrix gl   = `GL'
    return matrix egh  = `EGH'
    return matrix taols = `TAOLS'
end
