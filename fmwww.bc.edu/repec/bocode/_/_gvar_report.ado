*! _gvar_report 1.0.1  21aug2026
*! gvar report -- one specification audit of the fitted model.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Runs the checks a referee would ask for, in the order they matter, and
* summarises each to a line or two rather than printing every table.  It is a
* triage tool: it tells you which of the detailed subcommands to go and read.
*
* Nothing here is new arithmetic; every number comes from the subcommand
* named beside it.

program define _gvar_report, rclass
    version 14.0

    * report is nothing but display, so it never declared nosummary -- which
    * made it the one subcommand that ERRORED on an option every other one
    * accepts.  The body runs quietly, so the audit still populates r() for a
    * caller that wants the numbers without the text.
    *
    * report is also the ONLY subcommand that silences itself with quietly;
    * every other one guards its displays with an if.  That difference is not
    * cosmetic: quietly does NOT suppress -display as error-, because Stata
    * treats error output as something a user must always see.  The audit used
    * red for emphasis inside its table, and under nosummary those words
    * escaped on their own -- "not solved" printed while the -as text- around
    * it vanished.  Emphasis in the body is therefore {err:...} markup inside
    * an -as text- display, which quietly does suppress.  -as err- is reserved
    * here for a message that precedes an exit.
    syntax [, PSC(integer 4) STEP(integer 24) noSUMmary ///
              GRaph NAME(string) PANels(string) ]

    if ("`summary'" == "nosummary") {
        quietly _gvar_report_body `psc' `step'
    }
    else {
        _gvar_report_body `psc' `step'
    }
    return add

    * The dashboard runs AFTER the audit and outside the quietly, so that
    * -nosummary graph- still says where the page went.  Its panels come from
    * the same subcommands the audit just called; nothing is recomputed here
    * that the text above did not already report.
    if ("`graph'" != "") {
        _gvar_report_dash "`name'" `psc' `step' "`panels'"
        return add
    }
end

program define _gvar_report_body, rclass
    version 14.0
    args psc step

    _gvar_require estimate

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("K",  strofreal(gvar_getK()))
    mata: st_local("T",  strofreal(gvar_getT()))
    mata: st_local("sv", strofreal(gvar_issolved()))

    * When a dominant unit is present, K counts its variables but they belong to
    * no country model, so the diagnostics below cover fewer equations than K.
    * Reporting "136 endogenous variables" above a table of 133 equations reads
    * as three lost results.  Say the split instead.
    capture mata: st_local("hasdu", strofreal(gvar_hasdu()))
    local ndu 0
    if (_rc == 0 & "`hasdu'" == "1") {
        mata: st_local("ndu", strofreal(rows(gvar_getduylist())))
    }

    _gvar_title "GVAR specification audit"
    di as text "  " as result `N' as text " units, " as result `K' ///
       as text " endogenous variables, " as result `T' as text " periods."
    if (`ndu' > 0) {
        di as text "  Of those " as result `K' as text ", " as result `ndu' ///
           as text " belong to the dominant unit and " ///
           as result `=`K' - `ndu'' as text " to the " as result `N' ///
           as text " country models."
        di as text "  The dominant unit has no VECMX*, so the residual and"
        di as text "  cointegration checks below cover " ///
           as result `=`K' - `ndu'' as text " equations, not " as result `K' ///
           as text "."
        di as text "  Its own diagnostics come from {bf:gvar dominant}; the"
        di as text "  Toolbox reports them separately too (DUmodel_augres_sc)."
    }
    di ""

    * ---- 1. the solved system ----------------------------------------------
    di as text "{hline 74}"
    di as text "  {bf:1. Does the system solve?}" _col(58) "{it:gvar solve}"
    di as text "{hline 74}"
    if ("`sv'" != "1") {
        di as text "  {err:not solved}.  Run {bf:gvar solve}."
    }
    else {
        qui gvar solve, nosummary
        local mm = r(maxmod)
        local nexp = r(nexpl)
        local nu = r(nunit)
        local ex = r(expected)
        di as text "  largest eigenvalue modulus  " as result %10.6f `mm'
        if (`nexp' > 0) {
            di as text "  {err:`nexp'} explosive root(s): every" ///
               " impulse response is meaningless until this is fixed."
        }
        else {
            di as text "  no explosive roots."
        }
        di as text "  unit roots found " as result `nu' as text ", implied by" ///
           " the ranks " as result `ex' _continue
        if (`nu' == `ex') di as text "   {bf:agree}"
        else              di as text "   {err:{bf:disagree}}"
        if (`nu' != `ex') {
            di as text "  A mismatch means the ranks and the dynamics" ///
                       " disagree; the usual"
            di as text "  cause is an overstated rank.  See {bf:gvar coint}" ///
                       " and {bf:gvar pp}."
        }
    }
    di ""

    * ---- 2. weak exogeneity -------------------------------------------------
    di as text "{hline 74}"
    di as text "  {bf:2. Are the foreign variables weakly exogenous?}" ///
               _col(56) "{it:gvar wetest}"
    di as text "{hline 74}"
    qui gvar wetest, nosummary
    local nrej = r(nrej)
    local ntot = r(ntot)
    local nmis = r(nmiss)
    local pct  = 100 * `nrej' / max(`ntot', 1)
    di as text "  rejected at 5%: " as result `nrej' as text " of " ///
       as result `ntot' as text "  (" as result %4.1f `pct' as text "%)"
    di as text "  Dees, di Mauro, Pesaran & Smith report 5-10% for a" ///
               " correctly specified GVAR."
    if (`pct' > 15) {
        di as text "  {err:Above that range}: the assumption" ///
           " the whole estimation rests on"
        di as text "  is in doubt.  Read {bf:gvar wetest} in full."
    }
    if (`nmis' > 0) {
        di as text "  {err:`nmis'} test(s) could not be computed."
    }
    di ""

    * ---- 3. cross-section dependence ---------------------------------------
    di as text "{hline 74}"
    di as text "  {bf:3. Did the foreign variables absorb the dependence?}" ///
               _col(56) "{it:gvar avgcorr}"
    di as text "{hline 74}"
    qui gvar avgcorr, nosummary
    tempname AC
    matrix `AC' = r(avgcorr)
    mata: gvar_reportcorr(st_matrix("`AC'"))
    local ml = r(mlev)
    local mr = r(mres)
    di as text "  mean |correlation| in the levels    " as result %8.4f `ml'
    di as text "  mean |correlation| in the residuals " as result %8.4f `mr'
    if (`mr' > 0) {
        di as text "  reduction factor " as result %6.1f `=`ml'/`mr''
    }
    if (`mr' > 0.2) {
        di as text "  {err:Still substantial}.  The country" ///
           " models are not conditionally"
        di as text "  independent and the generalized responses are not" ///
                   " trustworthy."
    }
    di ""

    * ---- 4. residual diagnostics -------------------------------------------
    di as text "{hline 74}"
    di as text "  {bf:4. Are the residuals well behaved?}" _col(60) ///
               "{it:gvar diag}"
    di as text "{hline 74}"
    qui gvar diag, psc(`psc') nosummary
    local ne  = r(nequations)
    di as text "  serial correlation  " as result r(nsc)  as text "/" ///
       as result `ne' as text "   non-normal " as result r(njb) as text "/" ///
       as result `ne' as text "   ARCH " as result r(narch) as text "/" ///
       as result `ne'
    local scp = 100 * r(nsc) / max(`ne', 1)
    if (`scp' > 15) {
        di as text "  Serial correlation in " as result %4.1f `scp' ///
           as text "% of equations suggests the lag"
        di as text "  orders are too short.  See {bf:gvar lags} and" ///
                   " {bf:gvar diag, multivariate}."
    }
    di as text "  Non-normality is the usual finding in quarterly macro data"
    di as text "  and does not invalidate the generalized responses, which"
    di as text "  need only the second moments."
    di ""

    * ---- 5. the long-run relations -----------------------------------------
    if ("`sv'" == "1") {
        di as text "{hline 74}"
        di as text "  {bf:5. Do the long-run relations settle back?}" ///
                   _col(62) "{it:gvar pp}"
        di as text "{hline 74}"
        qui gvar pp, step(`step') nosummary
        local nr = r(nrelations)
        local ns = r(nslow)
        di as text "  " as result `nr' as text " cointegrating relations, " ///
           as result `ns' as text " still above 0.10 at horizon " ///
           as result `step' as text "."
        if (`ns' > 0) {
            di as text "  Those relations are not settling back, which points"
            di as text "  to an overstated rank.  Re-examine with" ///
                       " {bf:gvar coint}."
        }
        else {
            di as text "  Every profile decays as a long-run relation should."
        }
        di ""
    }

    * ---- 6. what to do next -------------------------------------------------
    di as text "{hline 74}"
    di as text "  {bf:Reading order}"
    di as text "{hline 74}"
    di as text "  {bf:gvar diag, multivariate reps(200)}   system-wide," ///
               " bootstrap p-values"
    di as text "  {bf:gvar stability, reps(250) shuffle}   parameter" ///
               " stability"
    di as text "  {bf:gvar irf, shock() reps(200) shuffle} responses with bands"
    di as text "  {bf:gvar spillover, by(unit)}            connectedness"
    di as text "  {help gvar_methods:gvar methods}         what the numbers mean"
    di ""

    return scalar wetest_rej = `nrej'
    return scalar wetest_tot = `ntot'
    return scalar corr_lev   = `ml'
    return scalar corr_res   = `mr'
    return scalar nequations = `ne'
end

* ---------------------------------------------------------------------------
mata:
void gvar_reportcorr(real matrix A)
{
    real scalar i, nl, nr, sl, sr

    nl = nr = sl = sr = 0
    for (i = 1; i <= rows(A); i++) {
        if (A[i, 3] < .) {
            sl = sl + abs(A[i, 3]); nl = nl + 1
        }
        if (A[i, 5] < .) {
            sr = sr + abs(A[i, 5]); nr = nr + 1
        }
    }
    st_numscalar("r(mlev)", sl / max((nl, 1)))
    st_numscalar("r(mres)", sr / max((nr, 1)))
}
end
* ---------------------------------------------------------------------------
* The specification dashboard (inventory 13.23).
*
* One page holding the six checks a referee asks for, in the order the audit
* prints them.  Each panel is produced by the subcommand that owns it -- this
* program computes nothing, it only arranges.  That matters: a dashboard that
* recomputed its own numbers could disagree with the tables beside it.
*
* Panels are built into temporary named graphs, combined, and dropped.  A
* panel that cannot be produced is SKIPPED and named in a note, rather than
* aborting the page: on an unsolved model four of the six still mean something.
*
* The whole panel list is resolved BEFORE any panel is built.  Validating
* inside the build loop left a temporary graph behind whenever a later name
* was bad, and made a typo cost a full eigen-decomposition first.  Every exit
* path from here drops what it created.
*
* graph combine rejects bgcolor(), so the shared region style cannot be
* passed to it wholesale -- only graphregion() is given here.
* ---------------------------------------------------------------------------
program define _gvar_report_dash, rclass
    version 14.0
    args gname psc step panels

    if ("`gname'" == "") local gname gvar_dashboard
    if ("`panels'" == "") local panels "solve wetest avgcorr diag pp unitroot"

    mata: st_local("sv", strofreal(gvar_issolved()))

    * ---- pass 1: resolve every name, build nothing --------------------------
    * name -> command map.  Kept as a table so adding a panel is one line and
    * so the skip message can name the subcommand the reader should run.
    local todo   ""
    local failed ""
    foreach p of local panels {
        local cmd ""
        if ("`p'" == "solve")     local cmd "gvar solve, graph nosummary"
        if ("`p'" == "wetest")    local cmd "gvar wetest, graph nosummary"
        if ("`p'" == "avgcorr")   local cmd "gvar avgcorr, graph nosummary"
        if ("`p'" == "diag")      local cmd "gvar diag, psc(`psc') graph nosummary"
        if ("`p'" == "pp")        local cmd "gvar pp, step(`step') graph nosummary"
        if ("`p'" == "coint")     local cmd "gvar coint, graph nosummary"
        if ("`p'" == "stability") local cmd "gvar stability, graph nosummary"
        if ("`p'" == "unitroot") {
            local cmd "gvar unitroot, domestic blocks(1) graph gstat(adf) gblock(1) nosummary"
        }
        if ("`cmd'" == "") {
            di as err "unknown dashboard panel: `p'"
            di as err "choose from: solve wetest avgcorr diag pp unitroot" ///
                      " coint stability"
            exit 198
        }

        * solve, pp and stability all need a solved system; asking for them on
        * an unsolved model is a skip, not an error
        if (("`p'" == "solve" | "`p'" == "pp" | "`p'" == "stability") ///
            & "`sv'" != "1") {
            local failed "`failed' `p'(not solved)"
            continue
        }
        local todo "`todo' `p'"
    }

    * ---- pass 2: build ------------------------------------------------------
    local built ""
    local np 0
    foreach p of local todo {
        local cmd ""
        if ("`p'" == "solve")     local cmd "gvar solve, graph nosummary"
        if ("`p'" == "wetest")    local cmd "gvar wetest, graph nosummary"
        if ("`p'" == "avgcorr")   local cmd "gvar avgcorr, graph nosummary"
        if ("`p'" == "diag")      local cmd "gvar diag, psc(`psc') graph nosummary"
        if ("`p'" == "pp")        local cmd "gvar pp, step(`step') graph nosummary"
        if ("`p'" == "coint")     local cmd "gvar coint, graph nosummary"
        if ("`p'" == "stability") local cmd "gvar stability, graph nosummary"
        if ("`p'" == "unitroot") {
            local cmd "gvar unitroot, domestic blocks(1) graph gstat(adf) gblock(1) nosummary"
        }

        local ++np
        local gn "_gvar_dash`np'"
        capture graph drop `gn'
        * capture already suppresses output; quietly inside it would let
        * -display as error- through, which is how the audit's own red
        * emphasis used to escape nosummary
        capture `cmd' name(`gn')
        if (_rc) {
            local failed "`failed' `p'(rc=`=_rc')"
            local --np
            continue
        }
        * a subcommand can return 0 and still draw nothing -- for instance a
        * scan in which every statistic is missing.  Confirm the graph exists
        * before it goes into the combine list.
        capture graph describe `gn'
        if (_rc) {
            local failed "`failed' `p'(no graph)"
            local --np
            continue
        }
        local built "`built' `gn'"
    }

    local nb : word count `built'
    if (`nb' == 0) {
        di as err "no dashboard panel could be produced."
        exit 459
    }

    * 1 panel -> 1 column, 2 -> 2, 3 or 4 -> 2, 5 or 6 -> 3.  Rows follow.
    local cols 3
    if (`nb' <= 2) local cols `nb'
    if (`nb' == 3 | `nb' == 4) local cols 2

    local nte "each panel is produced by the subcommand named in its title"
    if ("`failed'" != "") local nte "`nte'; skipped:`failed'"

    * NOT xcommon/ycommon.  The unit-circle panel has x in [-1,1] and the
    * diagnostic scans have x = 1..K; a common axis would flatten both into
    * unreadability.  Panels here are different measurements, not facets.
    capture noisily graph combine `built' ///
        , cols(`cols') iscale(0.62) ///
          graphregion(color(white) lwidth(none)) ///
          title("GVAR specification dashboard", size(medium) color(black)) ///
          note("`nte'", size(vsmall)) ///
          name(`gname', replace)
    local crc = _rc

    * drop the temporaries whether the combine worked or not
    foreach gn of local built {
        capture graph drop `gn'
    }
    if (`crc') exit `crc'

    di as text "  dashboard saved as " as result "`gname'" as text ///
       "  (" as result `nb' as text " panel(s)" _continue
    if ("`failed'" != "") di as text ", skipped: {err:`failed'}" _continue
    di as text ")"

    return local panels "`built'"
    return local skipped "`failed'"
    return scalar npanels = `nb'
end
