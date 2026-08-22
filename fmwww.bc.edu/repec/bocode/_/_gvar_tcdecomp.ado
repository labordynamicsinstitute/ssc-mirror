*! _gvar_tcdecomp 1.0.1  21aug2026
*! gvar tcdecomp -- Beveridge-Nelson trend/cycle decomposition of the GVAR.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   C(0)=I, C(1)=F_1-I, C(j)=sum_l C(j-l) F_l, C(1)=sum_j C(j)
*   permanent stochastic  xp_st(t) = C(1) * cumsum(residuals)
*   permanent determ.     xp_dt    = a1 + a2*trend    (OLS of v on 1, trend)
*   cycle                 xc       = v - xp_dt
*                                                     <- Toolbox TCdecomp.m
*   per-variable trend restrictions                   <- TC_trend_restr.m
*
* On the residual: TCdecomp.m documents its third argument as the
* reduced-form residual, and its C(.) recursion is the reduced-form long-run
* multiplier, but gvar.m:3106 passes the STRUCTURAL residual zeta.  The
* default here cumulates eta, which is what the Beveridge-Nelson
* decomposition requires; {bf:residuals(zeta)} reproduces the Toolbox
* exactly.  See {help gvar_methods} and section 15 of the inventory.

program define _gvar_tcdecomp, rclass
    version 14.0

    syntax [,                                   ///
        VARiables(string)                       ///
        RESTrict(string)                        ///
        NOTRend                                 ///
        RESIDuals(string)                       ///
        PERiods(numlist integer >0 sort)         ///
        GRaph                                   ///
        NAME(string)                            ///
        noSUMmary                               ///
        SAVing(name)                            ///
    ]

    _gvar_require solve

    if ("`residuals'" == "") local residuals eta
    local residuals = lower("`residuals'")
    if ("`residuals'" == "eta")        local ue 1
    else if ("`residuals'" == "zeta")  local ue 0
    else {
        di as err "residuals() must be {bf:eta} or {bf:zeta}"
        exit 198
    }

    mata: st_local("K",  strofreal(gvar_getK()))
    mata: st_local("xl", gvar_getxlabels())

    * ---- trend restrictions -------------------------------------------------
    tempname RS
    matrix `RS' = J(`K', 1, 0)
    local nres 0
    if ("`restrict'" != "") {
        _gvar_xsel "`restrict'"
        local rp "`r(pos)'"
        foreach j of local rp {
            matrix `RS'[`j', 1] = 1
            local ++nres
        }
    }

    * ---- compute -------------------------------------------------------------
    tempname XP XC XPST XPDT XTIL
    local nt 0
    if ("`notrend'" != "") local nt 1

    di as text "  computing C(1) by 1000-term recursion ..."
    mata: gvar_tcwrap(st_matrix("`RS'"), `nt', `ue')
    matrix `XP'   = r_xp
    matrix `XC'   = r_xc
    matrix `XPST' = r_xpst
    matrix `XPDT' = r_xpdt
    matrix `XTIL' = r_xtil

    * ---- the source's own identity check ------------------------------------
    mata: st_local("dev", strofreal(max(abs(st_matrix("`XC'") - ///
                                            st_matrix("`XTIL'")))))
    if (`dev' > 1e-10) {
        di as err "the cyclical component and the deviation from the"
        di as err "permanent component differ by `dev'; they must be equal."
        di as err "TCdecomp.m stops here too.  This indicates a numerical"
        di as err "failure in the C(1) recursion."
        exit 498
    }

    * ---- report ---------------------------------------------------------------
    if ("`variables'" == "") local variables "*:y"
    _gvar_xsel "`variables'"
    local vpos "`r(pos)'"
    local vlab "`r(labels)'"
    local nv = r(n)
    local T = colsof(`XC')

    if ("`summary'" != "nosummary") {
        _gvar_title "Trend/cycle decomposition of the GVAR"
        di as text "  Beveridge-Nelson: the permanent component is C(1) times"
        di as text "  the cumulated innovations plus a deterministic trend;"
        di as text "  the cycle is what remains."
        di as text "  Residual cumulated: " as result "`residuals'" _continue
        if (`ue' == 0) {
            di as text "  (reproduces gvar.m:3106)"
        }
        else {
            di as text "  (the reduced-form residual)"
        }
        if (`nres' > 0) {
            di as text "  Trend restricted to zero for " as result `nres' ///
                       as text " variable(s)."
        }
        if (`nt' == 1) {
            di as text "  No trend in the deterministic component."
        }
        di as text "  Identity xc = x - xp holds to " as result %8.2e `dev' ///
                   as text "."
        di ""

        di as text "{hline 78}"
        di as text %-16s "  variable" _col(20) "sd(cycle)" _col(34) ///
                   "sd(perm)" _col(48) "cycle/total" _col(64) "last cycle"
        di as text "{hline 78}"
        local c 0
        foreach j of local vpos {
            local ++c
            local l : word `c' of `vlab'
            mata: gvar_tcstats(st_matrix("`XC'"), st_matrix("`XP'"), `j')
            _gvar_ablab "`l'" 14
            di as text "  " %-14s "`_ablab'"              ///
               _col(19) as result %10.4f `=r(sdc)'               ///
               _col(33) as result %10.4f `=r(sdp)'               ///
               _col(48) as result %10.3f `=r(share)'             ///
               _col(63) as result %11.4f `=r(last)'
        }
        di as text "{hline 78}"
        di as text "  sd(cycle) and sd(perm) are the standard deviations of the"
        di as text "  two components over the " as result `T' as text " periods."
        di as text "  cycle/total is sd(cycle) divided by their sum: a value"
        di as text "  near zero means the series is almost pure trend."
        di ""
        di as text "  A cycle that trends rather than mean-reverting is the"
        di as text "  symptom of cumulating the wrong residual; compare"
        di as text "  {bf:residuals(eta)} with {bf:residuals(zeta)}."
        di ""

        * periods() was declared and never read.  It lists the dates at which
        * to print the two components, which is what makes the table readable
        * for a long sample: the summary above is one row per variable, this is
        * one row per (variable, date).
        if ("`periods'" != "") {
            local pk ""
            foreach t of local periods {
                if (`t' >= 1 & `t' <= `T') local pk "`pk' `t'"
                else {
                    di as text "  {bf:note}: period " as result `t' ///
                       as text " is outside 1-" as result `T' as text ", skipped"
                }
            }
            local npk : word count `pk'
            if (`npk' > 0) {
                di as text "  {bf:The two components at selected periods}"
                di as text "{hline 62}"
                di as text %-16s "  variable" _col(20) "period" ///
                   _col(32) "cycle" _col(48) "permanent"
                di as text "{hline 62}"
                local c 0
                foreach j of local vpos {
                    local ++c
                    local l : word `c' of `vlab'
                    local first 1
                    foreach t of local pk {
                        if (`first') {
                            _gvar_ablab "`l'" 14
                            di as text "  " %-14s "`_ablab'" _continue
                            local first 0
                        }
                        else {
                            di as text "  " %-14s "" _continue
                        }
                        di as text _col(19) as result %7.0f `t' ///
                           _col(26) as result %12.5f `=`XC'[`j', `t']' ///
                           _col(42) as result %12.5f `=`XP'[`j', `t']'
                    }
                }
                di as text "{hline 62}"
                di as text "  cycle + permanent = the observed series, by" ///
                           " construction."
                di ""
            }
        }
    }

    if ("`graph'" != "") {
        _gvar_tc_graph `XC' `XP' "`vpos'" "`vlab'" `T' "`name'"
    }

    if ("`saving'" != "") {
        matrix `saving' = `XC'
    }
    return matrix cycle     = `XC', copy
    return matrix permanent = `XP', copy
    return matrix permst    = `XPST', copy
    return matrix permdt    = `XPDT', copy
    return scalar deviation = `dev'
    return local  residuals "`residuals'"
end

* ---------------------------------------------------------------------------
program define _gvar_tc_graph
    version 14.0
    args XC XP vpos vlab T gname

    if ("`gname'" == "") local gname gvar_tc
    _gvar_palette
    local reg  "`r(region)'"
    local c1   "`r(c1)'"
    local zero "`r(zero)'"

    local nv : word count `vpos'
    preserve
    clear

    * real dates rather than a period index; see _gvar_xtime for why the
    * offset is taken from the END of the sample
    _gvar_xtime `T'
    local xfmt  "`r(fmt)'"
    local xfmtc "`r(fmtc)'"
    local xlab  "`r(xlab)'"
    local t0    = r(t0)
    * xlabel(rule, suboptions) -- one comma only
    local xrule "#6"
    local xsub  "labsize(vsmall)"
    local xt "period"
    if ("`xfmt'" != "") {
        local xrule "`xlab'"
        local xsub  "format(`xfmtc') labsize(vsmall)"
        local xt ""
    }

    qui set obs `=`T' * `nv''
    qui gen double t      = .
    qui gen double cyc    = .
    qui gen str32  series = ""
    local r 0
    local c 0
    foreach j of local vpos {
        local ++c
        local l : word `c' of `vlab'
        forvalues s = 1/`T' {
            local ++r
            qui replace t      = `t0' + `s' - 1   in `r'
            qui replace cyc    = `XC'[`j', `s']   in `r'
            qui replace series = "`l'"            in `r'
        }
    }
    qui encode series, gen(sid)
    if ("`xfmt'" != "") format t `xfmt'

    twoway (line cyc t, lcolor("`c1'") lwidth(thin)) ///
        , `reg' ///
          by(sid, note("") ///
             title("Cyclical components", size(medium) color(black)) ///
             subtitle("deviations from the permanent component", ///
                      size(vsmall) color(gs7)) ///
             graphregion(color(white))) ///
          yline(0, lcolor("`zero'") lpattern(dash) lwidth(thin)) ///
          ylabel(, angle(0) labsize(vsmall) grid glcolor(gs15)) ///
          xlabel(`xrule', `xsub') ///
          xtitle("`xt'", size(small)) ytitle("cycle", size(small)) ///
          subtitle(, size(vsmall) color(black) fcolor(white) lcolor(gs12)) ///
          name(`gname', replace) legend(off)
    restore
end
