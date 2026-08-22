*! _gvar_describe 1.0.1  21aug2026
*! gvar describe -- what is currently in memory: dimensions, the per-unit
*! specification, and the order of the global vector.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* The order of x(t) is the part that matters operationally: every
* orthogonalised object depends on it, and {help gvar_irf:gvar irf} with
* type(sgirf) or type(oirf) is only interpretable once you have seen it.
* It is also the order in which every table in the package is laid out.

program define _gvar_describe, rclass
    version 14.0

    syntax [, ORDer VARlist STats noSUMmary ]

    _gvar_require setup

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("K",  strofreal(gvar_getK()))
    mata: st_local("T",  strofreal(gvar_getT()))
    mata: st_local("cn", invtokens(gvar_getcname()'))
    mata: st_local("vn", invtokens(gvar_getvname()'))
    mata: st_local("gv", invtokens(gvar_getgvname()'))
    mata: st_local("hasf", strofreal(gvar_hasforeign()))
    mata: st_local("hase", strofreal(gvar_isestimated()))
    mata: st_local("hass", strofreal(gvar_issolved()))

    * ---- state --------------------------------------------------------------
    * describe IS the summary, so nosummary silences the whole thing and leaves
    * only r().  Previously it printed regardless, which made the option a lie
    * on the one command whose entire purpose is to print.
    if ("`summary'" == "nosummary") {
        local order   ""
        local varlist ""
        local stats   ""
    }

    if ("`summary'" != "nosummary") {
    _gvar_title "GVAR currently in memory"
    di as text "  Units " as result %-6s "`N'" ///
       as text "  Endogenous variables (K) " as result %-6s "`K'" ///
       as text "  Periods " as result "`T'"
    di as text "  Distinct domestic variables: " as result "`vn'"
    if ("`gv'" != "") {
        di as text "  Global variables: " as result "`gv'"
    }
    di ""
    di as text "  Stage reached:"
    di as text "    setup      " as result "yes"
    local s3 "no"
    if ("`hasf'" == "1") local s3 "yes"
    di as text "    foreign    " as result "`s3'"
    local s4 "no"
    if ("`hase'" == "1") local s4 "yes"
    di as text "    estimate   " as result "`s4'"
    local s5 "no"
    if ("`hass'" == "1") local s5 "yes"
    di as text "    solve      " as result "`s5'"
    if ("`hass'" == "1") {
        mata: st_local("mm", strofreal(gvar_maxmod()))
        di as text "    largest eigenvalue modulus " as result %8.6f `mm'
    }
    di ""
    }

    * ---- per-unit specification ---------------------------------------------
    if ("`summary'" != "nosummary") {
        di as text "{hline 74}"
        di as text %-12s "  Unit" _col(16) "k" _col(22) "k*" _col(30) "p" ///
                   _col(36) "q" _col(44) "case" _col(52) "rank" _col(62) "logL"
        di as text "{hline 74}"
        tempname KI KS LG CS RK
        mata: st_matrix("`KI'", gvar_getki())
        mata: st_matrix("`KS'", gvar_getksi())
        mata: st_matrix("`LG'", gvar_getlags())
        mata: st_matrix("`CS'", gvar_getcase())
        mata: st_matrix("`RK'", gvar_getrank())
        local haslog 0
        if ("`hase'" == "1") {
            tempname LL
            mata: st_matrix("`LL'", gvar_getlogl())
            local haslog 1
        }
        local sumk 0
        local sumr 0
        forvalues i = 1/`N' {
            local u : word `i' of `cn'
            local sumk = `sumk' + `KI'[`i', 1]
            local rr = `RK'[`i', 1]
            if (`rr' < .) local sumr = `sumr' + `rr'
            di as text "  " %-10s abbrev("`u'", 10)          ///
               _col(13) as result %5.0f `=`KI'[`i',1]'       ///
               _col(19) as result %5.0f `=`KS'[`i',1]'       ///
               _col(27) as result %5.0f `=`LG'[`i',1]'       ///
               _col(33) as result %5.0f `=`LG'[`i',2]'       ///
               _col(41) as result %5.0f `=`CS'[`i',1]'       ///
               _col(49) as result %5.0f `rr' _continue
            if (`haslog') di as result %14.2f `=`LL'[`i',1]'
            else          di ""
        }
        di as text "{hline 74}"
        di as text "  k  endogenous variables    k* weakly exogenous variables"
        di as text "  p, q  lag orders of the domestic and foreign blocks"
        di as text "  case  deterministic case 2, 3 or 4 (MacKinnon-Haug-Michelis)"
        di as text "  Total endogenous " as result `sumk' ///
           as text "   total cointegrating rank " as result `sumr' ///
           as text "   implied unit roots " as result `=`K' - `sumr''
        di ""
    }

    * ---- the order of x(t) --------------------------------------------------
    if ("`order'" != "") {
        mata: st_local("xl", gvar_getxlabels())
        di as text "{hline 74}"
        di as text "  {bf:Order of the global vector x(t)}"
        di as text "{hline 74}"
        di as text "  This is the Cholesky ordering used by {bf:type(oirf)}"
        di as text "  and the block boundary used by {bf:type(sgirf)}."
        di as text "  Change it with {bf:first()} and {bf:vorder()}; see"
        di as text "  {help gvar_irf:gvar irf}."
        di ""
        local j 0
        foreach l of local xl {
            local ++j
            di as text %5.0f `j' " " as result %-16s "`l'" _continue
            if (mod(`j', 4) == 0) di ""
        }
        if (mod(`j', 4) != 0) di ""
        di as text "{hline 74}"
        di ""
    }

    * ---- which unit owns which variable -------------------------------------
    if ("`varlist'" != "") {
        di as text "{hline 74}"
        di as text "  {bf:Domestic and weakly exogenous blocks by unit}"
        di as text "{hline 74}"
        forvalues i = 1/`N' {
            local u : word `i' of `cn'
            mata: st_local("yl", invtokens(gvar_getylist(`i')'))
            mata: st_local("sl", invtokens(gvar_getslist(`i')'))
            di as text "  " as result %-10s abbrev("`u'", 10) ///
               as text "  y : " as result "`yl'"
            di as text "  " %-10s "" as text "  y*: " as result "`sl'"
        }
        di as text "{hline 74}"
        di ""
    }

    * ---- descriptive statistics (Toolbox print_dstats.m) --------------------
    tempname DS
    if ("`stats'" != "") {
        _gvar_require foreign
        mata: st_matrix("`DS'", gvar_dstatstab())
        local nk = rowsof(`DS')
        _gvar_dstats_table `DS' "`cn'" "`vn'" "`gv'" `nk'
        return matrix dstats = `DS', copy
    }

    return scalar N = `N'
    return scalar K = `K'
    return scalar T = `T'
    return local  units    "`cn'"
    return local  domestic "`vn'"
    return local  global   "`gv'"
    return scalar estimated = ("`hase'" == "1")
    return scalar solved    = ("`hass'" == "1")
end

* ---------------------------------------------------------------------------
* Descriptive statistics of the variable blocks.
*
* Step -> source map
*   nine statistics per (block, unit, variable)  <- Toolbox print_dstats.m
*   the seven moments                            <- Toolbox dstats.m
*   Jarque-Bera and its probability              <- Toolbox jarquebera.m
*
* print_dstats.m writes three Excel sheets and is called unconditionally by
* gvar.m.  Dumping four hundred rows to the Stata console on every describe
* would be worse than useless, so the same table is produced by an option.
* Nothing about the numbers differs.
*
* Two things about the moments are the Toolbox's own conventions and are kept:
* dstats.m divides the third and fourth central moments by T and by the plain
* standard deviation, so the kurtosis column is the RAW fourth standardised
* moment -- 3 under normality, not 0.
* ---------------------------------------------------------------------------
program define _gvar_dstats_table
    version 14.0
    args D cn vn gv nk

    local vl "`vn' `gv'"
    local nvl : word count `vl'

    forvalues kind = 1/2 {
        local any 0
        forvalues q = 1/`nk' {
            if (`D'[`q', 1] == `kind') local any 1
        }
        if (`any' == 0) continue

        local klab "Domestic variables"
        if (`kind' == 2) local klab "Foreign-specific variables (x*)"

        di ""
        di as text "{hline 96}"
        di as text "  {bf:Descriptive statistics} -- `klab'"
        di as text "{hline 96}"
        di as text %-10s "  Unit" %-8s "var" _col(20) "mean" _col(31) "median" ///
           _col(42) "max" _col(52) "min" _col(62) "sd" _col(71) "skew" ///
           _col(80) "kurt" _col(88) "JB p"
        di as text "{hline 96}"

        local lastu .
        local nnorm 0
        local ntot  0
        forvalues q = 1/`nk' {
            if (`D'[`q', 1] != `kind') continue
            local ii = `D'[`q', 2]
            local jj = `D'[`q', 3]
            local u : word `ii' of `cn'
            local v : word `jj' of `vl'
            if ("`ii'" != "`lastu'") {
                di as text "  " %-8s abbrev("`u'", 8) _continue
                local lastu "`ii'"
            }
            else {
                di as text "  " %-8s "" _continue
            }
            local pv = `D'[`q', 12]
            local st ""
            if (`pv' < .) {
                local ++ntot
                if (`pv' < 0.05) local ++nnorm
                _gvar_stars `pv'
                local st "`r(stars)'"
            }
            di as text %-8s abbrev("`v'", 8) ///
               _col(16) as result %10.4f `=`D'[`q',4]'  ///
               _col(27) as result %10.4f `=`D'[`q',5]'  ///
               _col(38) as result %9.4f  `=`D'[`q',6]'  ///
               _col(48) as result %9.4f  `=`D'[`q',7]'  ///
               _col(58) as result %8.4f  `=`D'[`q',8]'  ///
               _col(67) as result %8.3f  `=`D'[`q',9]'  ///
               _col(76) as result %8.3f  `=`D'[`q',10]' ///
               _col(85) as result %7.3f  `pv' as text "`st'"
        }
        di as text "{hline 96}"
        di as text "  {bf:kurt} is the RAW fourth standardised moment, 3 under" ///
                   " normality, as in"
        di as text "  dstats.m -- not excess kurtosis.  {bf:JB p} is the" ///
                   " Jarque-Bera probability;"
        di as text "  * marks rejection of normality."
        if (`ntot' > 0) {
            di as text "  Non-normal at 5%: " as result `nnorm' as text " of " ///
               as result `ntot' as text " (" as result %4.1f ///
               `=100*`nnorm'/`ntot'' as text "%).  Quarterly macro series are"
            di as text "  routinely non-normal; this does not invalidate the" ///
                       " generalized"
            di as text "  responses, which need only the second moments."
        }
    }
end
