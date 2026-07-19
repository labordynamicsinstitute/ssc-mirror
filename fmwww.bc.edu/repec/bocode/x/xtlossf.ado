*! xtlossf 1.0.0  18jul2026
*! Distribution-free outlier detection in panel data via loss functions.
*! Part I  (nonnegative data): L = |F-B| * B^q ,  signed S = (F-B) * B^q.
*! Part II (mixed-sign data) : L = |F-B| * (|F|+|B|)^q.
*! Implements Coleman & Bryan, arXiv:2509.07014v2 (2025).
*! Part of the xtoutliers suite.
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
program define xtlossf, rclass
    version 14.0

    syntax varlist(numeric min=1 max=2) [if] [in] [ ,      ///
        Q(real -0.5)                                        ///
        C(real -1)                                          ///
        QUANtile(real -1)                                   ///
        TUkey(real -1)                                      ///
        SIGned                                              ///
        CPlus(real 9e30)                                    ///
        CMinus(real -9e30)                                  ///
        MIXedsign                                           ///
        TInvariant(varname numeric)                         ///
        FIT                                                 ///
        LAG                                                 ///
        GRAPH name(string) NOLABel LIST(integer 20) ]

    // ------------------------------------------------------------------
    // parse the base / future variables
    // ------------------------------------------------------------------
    local nv : word count `varlist'
    capture qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"

    tempvar B F touse obsno
    mark `touse' `if' `in'
    qui gen long `obsno' = _n

    if ("`lag'" != "") {
        if (`nv' != 1) {
            di as error "with -lag-, supply exactly one variable (F); base = L.F"
            exit 198
        }
        if ("`ivar'" == "" | "`tvar'" == "") {
            di as error "-lag- requires the data to be -xtset- with a time variable"
            exit 459
        }
        local fvar "`varlist'"
        qui gen double `F' = `fvar'
        qui gen double `B' = L.`fvar'
        local bname "L.`fvar'"
    }
    else {
        if (`nv' != 2) {
            di as error "supply two variables: base future   (or one with -lag-)"
            exit 198
        }
        local bvar : word 1 of `varlist'
        local fvar : word 2 of `varlist'
        qui gen double `B' = `bvar'
        qui gen double `F' = `fvar'
        local bname "`bvar'"
    }
    markout `touse' `B' `F'

    // ==================================================================
    // FIT mode: estimate q and C from a criteria table (Eq. I.19-I.20)
    //   B = size midpoints, F = epsilon midpoints ;  log eps = -q log B + K
    // ==================================================================
    if ("`fit'" != "") {
        tempvar lnB lnE
        qui gen double `lnB' = log(`B') if `touse' & `B' > 0
        qui gen double `lnE' = log(`F') if `touse' & `F' > 0
        qui regress `lnE' `lnB' if `touse'
        local qhat = -_b[`lnB']
        local Khat = _b[_cons]
        local Chat = exp(`Khat')
        di ""
        di as text "{hline 60}"
        di as text "Loss-function calibration (Eq. I.19-I.20)"
        di as text "{hline 60}"
        di as text "log eps = -q log B + K   fitted by OLS"
        di as text "  -q (slope)   = " as result %10.5f -`qhat'
        di as text "   q           = " as result %10.5f `qhat'
        di as text "   K (intercept)= " as result %10.5f `Khat'
        di as text "   C = exp(K)   = " as result %10.4f `Chat'
        di as text "{hline 60}"
        di as text "Use:  xtlossf B F , q(" %5.3f `qhat' ") c(" %6.2f `Chat' ")"
        return scalar q = `qhat'
        return scalar K = `Khat'
        return scalar C = `Chat'
        return local  cmd "xtlossf"
        exit
    }

    // ------------------------------------------------------------------
    // domain check for Part I (nonnegative)
    // ------------------------------------------------------------------
    if ("`mixedsign'" == "") {
        qui count if `touse' & `B' <= 0
        if (r(N) > 0) {
            di as text "note: `r(N)' obs with base <= 0 excluded " ///
                "(Part I requires nonnegative data; use -mixedsign- otherwise)"
            qui replace `touse' = 0 if `B' <= 0
        }
    }

    // ------------------------------------------------------------------
    // exponent (time-invariant if requested; Part I only)
    // ------------------------------------------------------------------
    tempvar expo
    if ("`tinvariant'" != "") {
        if ("`mixedsign'" != "") {
            di as error "time-invariant loss is defined for nonnegative data only (Part I)"
            exit 198
        }
        qui sum `tinvariant' if `touse', meanonly
        local tmax = r(max)
        tempvar ts
        qui gen double `ts' = `tinvariant'/`tmax' if `touse'
        qui gen double `expo' = `ts'*(`q') + `ts' - 1 if `touse'
    }
    else {
        qui gen double `expo' = `q' if `touse'
    }

    // ------------------------------------------------------------------
    // loss and signed loss
    // ------------------------------------------------------------------
    tempvar den absd sgnd L S
    if ("`mixedsign'" != "") {
        qui gen double `den' = abs(`F') + abs(`B') if `touse'
    }
    else {
        qui gen double `den' = `B' if `touse'
    }
    qui gen double `absd' = abs(`F' - `B') if `touse'
    qui gen double `sgnd' = (`F' - `B')     if `touse'

    qui gen double `L' = `absd' * (`den'^`expo') if `touse'
    qui gen double `S' = `sgnd' * (`den'^`expo') if `touse'
    // mixed-sign continuity convention L(0,0)=0
    if ("`mixedsign'" != "") {
        qui replace `L' = 0 if `touse' & `den' == 0
        qui replace `S' = 0 if `touse' & `den' == 0
    }

    // ------------------------------------------------------------------
    // critical value C  (unsigned)
    // ------------------------------------------------------------------
    local Cused = .
    local crule ""
    if (`c' >= 0) {
        local Cused = `c'
        local crule "user c()"
    }
    else if (`quantile' >= 0) {
        qui _pctile `L' if `touse', p(`=`quantile'*100')
        local Cused = r(r1)
        local crule "quantile `quantile'"
    }
    else {
        // default: Tukey upper fence
        local tk = `tukey'
        if (`tk' < 0) local tk = 1.5
        qui _pctile `L' if `touse', p(25 75)
        local q1 = r(r1)
        local q3 = r(r2)
        local Cused = `q3' + `tk'*(`q3' - `q1')
        local crule "Tukey Q3+`tk'*IQR"
    }

    // signed bounds (sentinels 9e30 / -9e30 mean "derive from the data")
    if ("`signed'" != "") {
        if (`cplus' >= 9e29) {
            qui _pctile `S' if `touse', p(25 75)
            local sp1 = r(r1)
            local sp3 = r(r2)
            local cplus = `sp3' + 1.5*(`sp3' - `sp1')
        }
        if (`cminus' <= -9e29) {
            qui _pctile `S' if `touse', p(25 75)
            local sm1 = r(r1)
            local sm3 = r(r2)
            local cminus = `sm1' - 1.5*(`sm3' - `sm1')
        }
    }

    // ------------------------------------------------------------------
    // flag outliers
    // ------------------------------------------------------------------
    tempvar out
    qui gen byte `out' = 0 if `touse'
    if ("`signed'" != "") {
        qui replace `out' = 1 if `touse' & (`S' > `cplus' | `S' < `cminus') & `S' < .
    }
    else {
        qui replace `out' = 1 if `touse' & `L' > `Cused' & `L' < .
    }
    qui count if `out' == 1
    local nout = r(N)
    qui count if `touse'
    local N = r(N)

    // ------------------------------------------------------------------
    // output
    // ------------------------------------------------------------------
    local part = cond("`mixedsign'"!="","II (mixed sign)","I (nonnegative)")
    di ""
    di as text "{hline 70}"
    di as text "Loss-function outlier detection — Part `part'"
    di as text "{hline 70}"
    di as text "Base = " as result "`bname'" as text "   Future = " as result "`fvar'"
    di as text "q = " as result %6.3f `q' ///
        as text "   loss = " ///
        cond("`mixedsign'"!="", "|F-B|*(|F|+|B|)^q", "|F-B|*B^q")
    if ("`tinvariant'" != "") di as text "time-invariant exponent: t*q+t-1 (t rescaled, last=1)"
    di as text "Critical value C = " as result %10.4f `Cused' ///
        as text "   (" "`crule'" ")"
    if ("`signed'" != "") {
        di as text "Signed bounds:  C+ = " as result %9.4f `cplus' ///
            as text "   C- = " as result %9.4f `cminus'
    }
    di as text "Observations = " as result `N' ///
        as text "   Outliers = " as result `nout' ///
        as text "  (" %4.1f 100*`nout'/`N' as text "%)"
    di as text "{hline 70}"

    // outlier listing
    if (`nout' > 0 & `list' > 0) {
        preserve
        qui keep if `out' == 1
        gsort -`L'
        local shown = min(`nout', `list')
        di as text %-8s "obs" _col(9) %-10s "panel" _col(20) %-8s "time" ///
            _col(28) %11s "base" _col(41) %11s "future" _col(54) %11s "loss"
        di as text "{hline 70}"
        forvalues r = 1/`shown' {
            local bb = `B'[`r']
            local ff = `F'[`r']
            local ll = `L'[`r']
            local plab ""
            local ttv .
            if ("`ivar'" != "") {
                local idc = `ivar'[`r']
                if ("`nolabel'" == "") {
                    local plab : label (`ivar') `idc'
                }
                if ("`plab'" == "") local plab "`idc'"
            }
            if ("`tvar'" != "") local ttv = `tvar'[`r']
            local obc = `obsno'[`r']
            di as text %-8.0f `obc' _col(9) as result %-10s abbrev("`plab'",10) ///
                _col(20) %-8.0f `ttv' ///
                _col(28) %11.4g `bb' _col(41) %11.4g `ff' _col(54) %11.4g `ll'
        }
        if (`nout' > `list') di as text "(showing top `list' of `nout'; use list() to change)"
        di as text "{hline 70}"
        restore
    }

    // ------------------------------------------------------------------
    // save loss / flag into the data (permanent copies)
    // ------------------------------------------------------------------
    capture drop _xtlossf_L
    capture drop _xtlossf_out
    qui gen double _xtlossf_L   = `L'   if `touse'
    qui gen byte   _xtlossf_out = `out' if `touse'
    label var _xtlossf_L   "loss L (xtlossf)"
    label var _xtlossf_out "outlier flag (xtlossf)"
    if ("`signed'" != "") {
        capture drop _xtlossf_S
        qui gen double _xtlossf_S = `S' if `touse'
        label var _xtlossf_S "signed loss S (xtlossf)"
    }

    // ------------------------------------------------------------------
    // stored results
    // ------------------------------------------------------------------
    return scalar N     = `N'
    return scalar nout  = `nout'
    return scalar q     = `q'
    return scalar C     = `Cused'
    if ("`signed'" != "") {
        return scalar Cplus  = `cplus'
        return scalar Cminus = `cminus'
    }
    return local  part   "`part'"
    return local  cmd    "xtlossf"

    // ------------------------------------------------------------------
    // graphs
    // ------------------------------------------------------------------
    if ("`graph'" != "") {
        if ("`name'" == "") local name "xtlossf"
        _xtlossf_graph `B' `F' `den' `L' `S' `out' `touse' ///
            `Cused' `q' "`mixedsign'" "`signed'" `cplus' `cminus' "`name'"
    }
end

// ----------------------------------------------------------------------
// graphs: (a) criticality log-log with the L=C line
//         (b) loss index plot with the cutoff
// ----------------------------------------------------------------------
program define _xtlossf_graph
    args B F den L S out touse Cused q mix sign cplus cminus name
    preserve
    qui keep if `touse'
    tempvar oo lden lL
    qui gen long `oo' = _n
    qui gen double `lden' = log(`den') if `den' > 0
    qui gen double `lL'   = log(`L')   if `L' > 0

    local sch "graphregion(color(white)) plotregion(color(white))"

    // criticality line in log-log: log L = log C  (since L=|F-B|*den^q,
    // the boundary L=C is a horizontal line at log C in (log den, log L))
    local lC = log(`Cused')
    qui twoway (scatter `lL' `lden' if `out'==0, mcolor(navy) msize(small)) ///
        (scatter `lL' `lden' if `out'==1, mcolor(red) msize(small)) ///
        , yline(`lC', lcolor(red) lpattern(dash)) ///
        title("(a) Criticality (log-log)", size(medsmall)) ///
        ytitle("log L") xtitle("log base / (|F|+|B|)") ///
        legend(order(1 "ok" 2 "outlier") size(small) rows(1)) ///
        note("dashed: L = C") `sch' name(`name'_a, replace) nodraw

    qui twoway (scatter `L' `oo' if `out'==0, mcolor(navy) msize(small)) ///
        (scatter `L' `oo' if `out'==1, mcolor(red) msize(small)) ///
        , yline(`Cused', lcolor(red) lpattern(dash)) ///
        title("(b) Loss by observation", size(medsmall)) ///
        ytitle("L") xtitle("Observation") ///
        legend(order(1 "ok" 2 "outlier") size(small) rows(1)) ///
        `sch' name(`name'_b, replace) nodraw

    graph combine `name'_a `name'_b, ///
        title("Loss-function diagnostics", size(medium)) ///
        `sch' name(`name', replace)
    restore
end
