*! _gvar_wetest 1.0.1  21aug2026
*! gvar wetest -- test the weak exogeneity of the foreign-specific and global
*! variables of each country model.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   marginal model for Dx*_i on a constant, the ECM terms of unit i and
*   lagged differences of the domestic and foreign variables, F-testing
*   H0: all ECM coefficients are zero   <- Toolbox test_weakexogeneity.m
*   lag orders of the marginal model    <- Toolbox select_lags_we.m

program define _gvar_wetest, rclass
    version 14.0

    * ls() and ln() are the lag orders of the marginal model.  Default 1 and 1.
    *
    * The Toolbox has THREE possible sources for these, selected by lagselect_we:
    *   lagselect_we = 0     inherit the estimation orders (p_i, q_i)
    *                        -- gvar.m:1767-1771
    *   lagselect_we = aic   choose per unit by AIC, from a maximum read off MAIN
    *   lagselect_we = sbc   the same by SBC
    *                        -- gvar.m:1735-1748, aic_sbc_we
    *
    * The shipped full demo uses AIC with a maximum of (2,2) (MAIN row 55), and
    * its exogeneity_test sheet shows the result: 24 of 26 units land on (1,1),
    * arg on (2,1) and chl on (1,2).  Note chl's q* = 2 exceeds its estimation
    * q = 1, which inheritance cannot produce -- that is the proof the demo
    * selected rather than inherited.
    *
    * So (1,1) reproduces 24 of the 26 units and is the right default until the
    * AIC selection is implemented.  A brief experiment defaulting these to the
    * per-unit (p_i, q_i) made things worse -- matching 7 units instead of 24 --
    * because inheritance is the branch the demo did NOT take.
    *
    * Passing ls(-1) or ln(-1) still requests inheritance, which is faithful to
    * the lagselect_we = 0 branch and is a legitimate thing to want.
    *
    * TODO, for exact reproduction: select ls and ln per unit by AIC over
    * 1..maxls, 1..maxln, as select_lags_we.m does.
    *
    * weforeign() names the marginal model's FOREIGN REGRESSOR block, which the
    * Toolbox specifies separately from the unit's weakly exogenous block:
    * fvflag_we / gvflag_we, read at gvar.m:1680-1714, defaulting to the
    * estimation spec (fvflag_we_tmp = fvflag, gvar.m:1632) but then offered to
    * the user for editing at a pause.  The default here is therefore empty --
    * the estimation block alone, matching gvar.m's default.
    *
    * The names are DOMESTIC variable names; their foreign counterparts are what
    * get added.  A global variable name adds the series itself, and is ignored
    * for any unit holding it endogenous.  The left-hand side is untouched, so
    * the shape of the table below does not change.
    *
    * Leave it alone to reproduce the demo.  gvar.m's note at that pause offers
    * "include the foreign variable, eps, in all country models" for DdPS(2007),
    * but that is NOT what the published exogeneity_test sheet was run with: the
    * sheet's degrees of freedom are reproduced by the default block for 24 of
    * the 26 units and by weforeign(ep) for none of them.  bra alone settles it,
    * at a published degfr of 118 against 117 with the extra column.
    syntax [, LS(integer 1) LN(integer 1) LEVel(real 95) noSUMmary ///
              SAVing(name) GRaph NAME(string)                      ///
              SELect(string) MAXLS(integer 2) MAXLN(integer 2)      ///
              WEForeign(string) ]

    * select(aic|sbc) chooses ls and ln per unit, as the demo does.  Without it
    * the given ls/ln apply to every unit.
    local selno 0
    if ("`select'" != "") {
        local select = lower("`select'")
        if      ("`select'" == "aic") local selno 2
        else if ("`select'" == "sbc") local selno 3
        else {
            di as err "select() must be {bf:aic} or {bf:sbc}"
            exit 198
        }
        if (`maxls' < 1 | `maxln' < 1) {
            di as err "maxls() and maxln() must be at least 1"
            exit 198
        }
    }

    _gvar_require estimate

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))
    mata: st_local("vn", invtokens(gvar_getvname()'))
    mata: st_local("gn", invtokens(gvar_getgvname()'))

    * Reject an unknown name rather than silently fitting a smaller model: a
    * typo in weforeign() would otherwise change every F in the table with no
    * hint that it had, which is the failure mode this whole option exists to
    * fix.  Duplicates are dropped in gvar_wesi(), not here.
    local weadd ""
    foreach v of local weforeign {
        local pv : list posof "`v'" in vn
        local pg : list posof "`v'" in gn
        if (`pv' == 0 & `pg' == 0) {
            di as err "weforeign(): {bf:`v'} is not a variable of this model"
            di as err "  domestic names: `vn'"
            if ("`gn'" != "") di as err "  global names:   `gn'"
            exit 111
        }
        local weadd "`weadd' `v'"
    }
    local weadd = trim("`weadd'")

    tempname R
    * If select() was given, choose (ls, ln) per unit first and pass them down.
    tempname SEL
    if (`selno' > 0) {
        mata: st_matrix("`SEL'", gvar_welagsel(`maxls', `maxln', `selno', ///
                                               tokens("`weadd'")'))
    }
    else {
        matrix `SEL' = J(1, 1, 0)
    }
    mata: st_matrix("`R'", gvar_wetest_all(`ls', `ln', `=`level'/100', ///
                                           st_matrix("`SEL'"),        ///
                                           tokens("`weadd'")'))
    local nr = rowsof(`R')
    if (`nr' == 0) {
        di as err "no unit has both weakly exogenous variables and a positive rank"
        exit 459
    }

    * Column order follows the model's variable order (domestic names, then
    * global names), not the order in which units happen to introduce them,
    * so the table reads the same way as every other table in the package.
    local seen ""
    forvalues i = 1/`N' {
        mata: st_local("sl", invtokens(gvar_getslist(`i')'))
        foreach s of local sl {
            local p : list posof "`s'" in seen
            if (`p' == 0) local seen "`seen' `s'"
        }
    }
    local wl ""
    foreach v of local vn {
        local p : list posof "`v'" in seen
        if (`p' > 0) local wl "`wl' `v'"
    }
    foreach v of local seen {
        local p : list posof "`v'" in wl
        if (`p' == 0) local wl "`wl' `v'"
    }
    local wl = trim("`wl'")
    local nw : word count `wl'

    * The counters are accumulated whether or not the table is printed:
    * -return- must always have something to return.
    local nrej 0
    local ntot 0
    local nmiss 0

    if ("`summary'" != "nosummary") {
        _gvar_title "Weak exogeneity test: F statistics"
        di as text "  H0: the error-correction terms of the country model do not"
        di as text "  enter the marginal model for the foreign variable."
        * Report what was actually used.  Printing "domestic 1, foreign 1"
        * unconditionally would now be a lie for the default path, where the
        * orders differ from unit to unit.
        if (`selno' > 0) {
            di as text "  Marginal model lags: chosen per unit by " ///
               as result upper("`select'") as text " over 1.." ///
               as result `maxls' as text " x 1.." as result `maxln' as text "."
            di as text "  This is what the Toolbox demo does (MAIN row 55: aic,"
            di as text "  maximum 2 and 2), and it is why 19 of its 26 units end"
            di as text "  up with orders differing from their estimation orders."
            mata: st_local("selshow", gvar_welagshow(st_matrix("`SEL'")))
            di as text "  Selected: " as result "`selshow'"
        }
        else if (`ls' < 0 & `ln' < 0) {
            di as text "  Marginal model lags: each unit's own VARX* orders"
            di as text "  (p_i, q_i), as the Toolbox uses by default."
        }
        else if (`ls' < 0) {
            di as text "  Marginal model lags: domestic p_i per unit" ///
                       as text ", foreign " as result `ln' as text "."
        }
        else if (`ln' < 0) {
            di as text "  Marginal model lags: domestic " as result `ls' ///
                       as text ", foreign q_i per unit."
        }
        else {
            di as text "  Marginal model lags: domestic " as result `ls' ///
                       as text ", foreign " as result `ln' ///
                       as text " for every unit (overriding p_i, q_i)."
        }
        * Say which marginal model was fitted.  Silence here is what let the
        * wrong regressor block go unnoticed: the table looked complete either
        * way, because the block affects the F values and nothing visible.
        if ("`weadd'" == "") {
            di as text "  Marginal model foreign block: each unit's own weakly"
            di as text "  exogenous variables -- the Toolbox default, and what"
            di as text "  the published demo used."
        }
        else {
            di as text "  Marginal model foreign block: each unit's own weakly"
            di as text "  exogenous variables plus " as result "`weadd'" ///
               as text "* where not already"
            di as text "  present -- the Toolbox's fvflag_we spec (gvar.m:1680)."
            di as text "  {bf:Note} this is NOT the published demo's block; it"
            di as text "  changes the degrees of freedom.  See {help gvar_methods}."
        }
        di ""
        local w = 14 + 9 * `nw'
        if (`w' > 120) local w 120
        di as text "{hline `w'}"
        di as text %-13s "  Unit" _continue
        foreach v of local wl {
            di as text %9s abbrev("`v'*", 8) _continue
        }
        di as text %8s "F cv95"
        di as text "{hline `w'}"
    }

    forvalues i = 1/`N' {
        local u : word `i' of `cn'
        local any 0
        forvalues q = 1/`nr' {
            if (`R'[`q', 1] == `i') local any 1
        }
        if (`any' == 0) continue

        mata: st_local("sl", invtokens(gvar_getslist(`i')'))
        if ("`summary'" != "nosummary") {
            di as text "  " %-11s abbrev("`u'", 11) _continue
        }
        foreach v of local wl {
            local pos : list posof "`v'" in sl
            if (`pos' == 0) {
                * A DASH means the variable is not in this unit's model -- a fact
                * about the specification.  A DOT is reserved for a test that
                * could not be computed, below.  One symbol for both made the
                * table unreadable: 25 of 26 rows are blank under ep* because
                * only the usa has a foreign exchange rate, and that looked
                * identical to 25 failures.
                if ("`summary'" != "nosummary") di as text %9s "-" _continue
            }
            else {
                local fv .
                local cv .
                forvalues q = 1/`nr' {
                    if (`R'[`q',1] == `i' & `R'[`q',2] == `pos') {
                        local fv = `R'[`q', 6]
                        local cv = `R'[`q', 5]
                        continue, break
                    }
                }
                if (`fv' >= .) {
                    * A DOT here is a genuine failure: the variable IS in the
                    * model but the auxiliary regression did not produce an F.
                    local ++nmiss
                    if ("`summary'" != "nosummary") di as text %9s "." _continue
                }
                else {
                    local ++ntot
                    local mk " "
                    if (`cv' < . & `fv' > `cv') {
                        local mk "*"
                        local ++nrej
                    }
                    if ("`summary'" != "nosummary") {
                        di as result %8.2f `fv' as text "`mk'" _continue
                    }
                }
            }
        }
        local cvi .
        forvalues q = 1/`nr' {
            if (`R'[`q',1] == `i') {
                local cvi = `R'[`q', 5]
                continue, break
            }
        }
        if ("`summary'" != "nosummary") di as result %8.2f `cvi'
    }

    if ("`summary'" != "nosummary") {
        di as text "{hline `w'}"
        di as text "  * marks rejection of weak exogeneity at " ///
                   as result `=100-`level'' as text "%: " ///
                   as result `nrej' as text " of " as result `ntot' ///
                   as text " (" as result %4.1f `=100*`nrej'/max(`ntot',1)' ///
                   as text "%)."
        * A dot is printed in TWO cases -- the variable is not in that unit's
        * weakly exogenous set (a specification fact), or it is and the statistic
        * came back missing (a failure, counted in nmiss).  This sentence used to
        * assert the first meaning unconditionally, which flatly contradicted the
        * "`nmiss' tests could not be computed" warning printed a few lines below
        * whenever nmiss > 0.  Two meanings for one symbol is bad enough; denying
        * it in the legend is worse, because the legend is what a reader believes.
        di as text "  {bf:-} means the variable is not in that unit's model."
        di as text "  Only the usa has a foreign exchange rate, for instance, so"
        di as text "  {bf:ep*} is a dash for the other 25; and the usa's foreign"
        di as text "  block is y*, Dp*, ep* alone, so its other columns are"
        di as text "  dashes.  Both follow the specification, not the data."
        if (`nmiss' == 0) {
            di as text "  {bf:.} would mark a test that could not be computed."
            di as text "  There are none: all " as result `ntot' ///
               as text " applicable tests were computed."
        }
        else {
            di as text "  {err:.} marks a test that could not be computed --" ///
               as text " {err:`nmiss'} of them; see below."
        }
        di as text "  The last column is the " ///
                   as result `=100-`level'' as text "% critical"
        di as text "  value, which varies with the unit's cointegrating rank."
        di as text "  Rejection means the variable is not weakly exogenous for the"
        di as text "  long-run parameters of that unit; see {help gvar_methods}."
        di as text "  Dees, di Mauro, Pesaran & Smith (2007) report rejection rates"
        di as text "  of roughly 5-10% for a correctly specified GVAR."
        if (`nmiss' > 0) {
            di as text "  {err:`nmiss'} tests could not be computed"
            di as text "  even though the variable is in the model; this is a"
            di as text "  failure, not a specification fact."
        }
        di ""
    }

    * ---- graph --------------------------------------------------------------
    * The whole point of the table is the share of rejections, and a share is
    * easier to see than to count: this puts every F beside its own 5% critical
    * value, which differs by unit because the restriction count does.
    if ("`graph'" != "") {
        tempname G
        matrix `G' = J(`nr', 4, .)
        forvalues q = 1/`nr' {
            matrix `G'[`q', 1] = `R'[`q', 1]
            matrix `G'[`q', 2] = `R'[`q', 6]
            matrix `G'[`q', 3] = `R'[`q', 5]
            matrix `G'[`q', 4] = 1
        }
        local sub "F test that the ECM terms are absent from the marginal model; cutoff at `=100-`level''%"
        _gvar_dotplot `G' `nr' "`cn'" ///
            "Weak exogeneity of the foreign variables" "`sub'" ///
            "F statistic" "`name'" 0
    }

    if ("`saving'" != "") {
        matrix `saving' = `R'
    }
    return matrix wetest = `R', copy
    return scalar nrej  = `nrej'
    return scalar ntot  = `ntot'
    return scalar nmiss = `nmiss'
end
