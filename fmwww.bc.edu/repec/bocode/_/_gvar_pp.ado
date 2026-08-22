*! _gvar_pp 1.0.1  21aug2026
*! gvar pp -- persistence profiles of the cointegrating relations.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   persistence profile              <- Toolbox pprofile.m
*     PP_h = diag(b' W Phi_h G^-1 S G^-1' Phi_h' W' b)
*          / diag(b' W     G^-1 S G^-1'      W' b)
*
* Pesaran & Shin (1996).  The profile of a cointegrating relation starts at
* one by construction and must converge to zero: a relation that does not
* settle back is not a long-run relation, whatever the rank test said.  The
* speed of convergence is the economically interesting quantity -- Dees, di
* Mauro, Pesaran & Smith (2007, Figure 2) read overshooting and slow decay as
* evidence that the estimated rank is too high.

program define _gvar_pp, rclass
    version 14.0

    syntax [,                                   ///
        UNITs(string)                           ///
        STEP(integer 24)                        ///
        VCOV(string)                            ///
        REPS(integer 0)                         ///
        LEVel(cilevel)                          ///
        SHUFFLE                                 ///
        SHRINKDraw                              ///
        LAMDraw(real -1)                        ///
        SHRINK                                  ///
        LAMbda(real -1)                         ///
        HORizons(numlist integer >=0 sort)      ///
        GRaph                                   ///
        NAME(string)                            ///
        noSUMmary                               ///
        SAVing(name)                            ///
    ]

    _gvar_require solve
    _gvar_require vecmx

    if (`step' < 1) {
        di as err "step() must be at least 1"
        exit 198
    }

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))

    _gvar_shrinkopt 0 0 "`vcov'" "`shrink'" "`lambda'"
    local vmeth "`r(vmeth)'"
    local vexcl "`r(vexcl)'"
    local shr   "`r(shr)'"
    local lam   "`r(lam)'"

    * ---- bootstrap (bootstrap_GVAR.m / bootstrap_GVAR_ss.m) ---------------
    local shf 0
    if ("`shuffle'" != "") local shf 1
    local dgs 0
    local dgl .
    if ("`shrinkdraw'" != "") local dgs 1
    if ("`lamdraw'" != "" & "`lamdraw'" != "-1") {
        if (`lamdraw' < 0 | `lamdraw' > 1) {
            di as err "lamdraw() must lie between 0 and 1"
            exit 198
        }
        local dgs 1
        local dgl `lamdraw'
    }
    if (`reps' > 0 & `shf' == 0) {
        mata: st_local("dgok", strofreal(gvar_dgpd(`vmeth', `vexcl', ///
                                                   `dgs', `dgl')))
        if ("`dgok'" != "1") {
            mata: st_local("KK", strofreal(gvar_getK()))
            mata: st_local("rk", strofreal(gvar_szetarank()))
            di as err "the bootstrap cannot draw from this covariance:" ///
                      " it is not positive definite"
            di as text "  Sigma_zeta is `KK' by `KK' with rank `rk'."
            di as text "  Add {bf:shuffle} to resample whole date columns" ///
                       " (shuffleflag=1),"
            di as text "  or {bf:shrinkdraw} to shrink the draw covariance" ///
                       " (use_shrinkedvcv_dg=1)."
            exit 506
        }
    }

    tempname P PB
    mata: st_matrix("`P'", gvar_pprun(`step', `vmeth', `vexcl', `shr', `lam'))

    local haveband 0
    if (`reps' > 0) {
        local blo = (100 - `level') / 200
        local bhi = 1 - `blo'
        di as text "  bootstrapping " as result `reps' as text ///
                   " replications for the persistence profiles ..."
        mata: gvar_bootwrap(`reps', `shf', 3, J(0,1,0), `step', 0, 0, ///
                            `vmeth', `vexcl', `shr', `lam', 0, ///
                            `blo', 0.5, `bhi', `dgs', `dgl')
        local bnok   = r_nok
        local bndisc = r_ndisc
        if (`bnok' == 0) {
            di as err "every bootstrap replication failed or was unstable"
            exit 498
        }
        matrix `PB' = r_boot
        local haveband 1
    }
    local nr = rowsof(`P')
    if (`nr' == 0 | colsof(`P') < 3) {
        di as err "no cointegrating relation has a persistence profile;"
        di as err "every unit was estimated with rank 0"
        exit 459
    }

    * ---- restrict to the requested units -----------------------------------
    local usel ""
    if ("`units'" == "") {
        forvalues i = 1/`N' {
            local usel "`usel' `i'"
        }
    }
    else {
        foreach u of local units {
            local p : list posof "`u'" in cn
            if (`p' == 0) {
                di as err "unit {bf:`u'} is not in the model"
                exit 111
            }
            local usel "`usel' `p'"
        }
    }

    local rows ""
    forvalues q = 1/`nr' {
        local i = `P'[`q', 1]
        local in : list posof "`i'" in usel
        if (`in' > 0) local rows "`rows' `q'"
    }
    local rows = trim("`rows'")
    local nsel : word count `rows'
    if (`nsel' == 0) {
        di as err "the selected units have no cointegrating relations"
        exit 459
    }

    * ---- horizons to print --------------------------------------------------
    if ("`horizons'" == "") {
        local hshow 0 1 2 4 8 12 16 20 24 32 40
        local keep ""
        foreach h of local hshow {
            if (`h' <= `step') local keep "`keep' `h'"
        }
        local pin : list posof "`step'" in keep
        if (`pin' == 0) local keep "`keep' `step'"
    }
    else {
        local keep ""
        foreach h of local horizons {
            if (`h' <= `step') local keep "`keep' `h'"
        }
    }
    local keep = trim("`keep'")

    * ---- convergence diagnostics -------------------------------------------
    local nbad 0
    local nover 0
    local hlmax 0
    foreach q of local rows {
        local v = `P'[`q', `=`step'+3']
        if (`v' > 0.10) local ++nbad
        local mx 0
        forvalues h = 0/`step' {
            local x = `P'[`q', `=`h'+3']
            if (`x' > `mx') local mx = `x'
        }
        if (`mx' > 1.0001) local ++nover
    }

    if ("`summary'" != "nosummary") {
        _gvar_title "Persistence profiles of the cointegrating relations"
        di as text "  Effect of a system-wide shock on each long-run relation,"
        di as text "  scaled to one on impact.  A well-behaved relation decays"
        di as text "  monotonically to zero."
        di ""

        * Width of the rule must match the width of the header it rules off:
        * %-12s Unit + %-8s relation + 9 per horizon + 10 for half-life.  It was
        * 22 + 9n, which is 7 short at n = 7 and visibly stops before the header
        * ends.  And half-life is 9 characters in a 9-wide column, so it butted
        * straight against the last horizon: "24half-life".  10 gives it a space.
        local w = 30 + 9 * `: word count `keep''
        if (`w' > 120) local w 120
        di as text "{hline `w'}"
        di as text %-12s "  Unit" %-8s "relation" _continue
        foreach h of local keep {
            di as text %9.0f `h' _continue
        }
        di as text %10s "half-life"
        di as text "{hline `w'}"

        local lastu 0
        foreach q of local rows {
            local i = `P'[`q', 1]
            local j = `P'[`q', 2]
            local u : word `i' of `cn'
            if (`i' != `lastu') {
                di as text "  " %-10s abbrev("`u'", 10) _continue
                local lastu = `i'
            }
            else {
                di as text "  " %-10s "" _continue
            }
            di as text %-8.0f `j' _continue
            foreach h of local keep {
                di as result %9.3f `=`P'[`q', `=`h'+3']' _continue
            }
            * half-life: first horizon at or below 0.5
            local hl .
            forvalues h = 0/`step' {
                if (`hl' >= . & `P'[`q', `=`h'+3'] <= 0.5) local hl = `h'
            }
            if (`hl' < .) di as result %10.0f `hl'
            else          di as text   %10s ">`step'"
        }
        di as text "{hline `w'}"
        di as text "  half-life is the first horizon at which the profile"
        di as text "  falls to one half."
        di as text "  " as result `nsel' as text " relations across " ///
                   as result `: word count `usel'' as text " units."
        if (`nbad' > 0) {
            di as text "  {err:`nbad'} of them are still above" ///
               " 0.10 at horizon " as result `step' as text ":"
            di as text "  those relations are not settling back, which points"
            di as text "  to an overstated cointegrating rank; re-examine them"
            di as text "  with {help gvar_coint:gvar coint}."
        }
        else {
            di as text "  Every profile is below 0.10 by horizon " ///
               as result `step' as text ", as a long-run relation should be."
        }
        if (`nover' > 0) {
            di as text "  " as result `nover' as text " profiles overshoot" ///
               " one before decaying; that is common and reflects"
            di as text "  short-run dynamics, not a misspecification."
        }
        di ""
    }

    if ("`graph'" != "") {
        _gvar_pp_graph `P' "`rows'" `step' "`cn'" "`name'"
    }

    if ("`saving'" != "") {
        matrix `saving' = `P'
    }
    if (`haveband') {
        return matrix ppband = `PB', copy
        return scalar reps   = `bnok'
        return scalar discarded = `bndisc'
    }
    return matrix pp = `P', copy
    return scalar nrelations = `nsel'
    return scalar nslow = `nbad'
    return scalar step  = `step'
end

* ---------------------------------------------------------------------------
program define _gvar_pp_graph
    version 14.0
    args P rows step cn gname

    if ("`gname'" == "") local gname gvar_pp

    _gvar_palette
    local reg  "`r(region)'"
    local c1   "`r(c1)'"
    local zero "`r(zero)'"

    local nsel : word count `rows'

    preserve
    clear
    qui set obs `=(`step'+1) * `nsel''
    qui gen int    horizon = .
    qui gen double pp      = .
    qui gen str32  relname = ""

    local r 0
    foreach q of local rows {
        local i = `P'[`q', 1]
        local j = `P'[`q', 2]
        local u : word `i' of `cn'
        forvalues h = 0/`step' {
            local ++r
            qui replace horizon = `h'                    in `r'
            qui replace pp      = `P'[`q', `=`h'+3']     in `r'
            qui replace relname = "`u' (`j')"            in `r'
        }
    }
    qui encode relname, gen(relid)

    twoway (line pp horizon, lcolor("`c1'%50") lwidth(thin) ///
            connect(L) cmissing(n)) ///
        , `reg' ///
          by(relid, note("") ///
             title("Persistence profiles of the cointegrating relations", ///
                   size(medium) color(black)) ///
             subtitle("each profile starts at one and should decay to zero", ///
                      size(vsmall) color(gs7)) ///
             graphregion(color(white))) ///
          yline(0, lcolor("`zero'") lpattern(dash) lwidth(thin)) ///
          ylabel(0(0.5)1, angle(0) labsize(vsmall) grid glcolor(gs15)) ///
          xlabel(0(8)`step', labsize(vsmall)) ///
          ytitle("profile", size(small)) ///
          xtitle("horizon (periods)", size(small)) ///
          subtitle(, size(vsmall) color(black) fcolor(white) lcolor(gs12)) ///
          name(`gname', replace) legend(off)
    restore
end
