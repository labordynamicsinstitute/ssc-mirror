*! _gvar_coint 1.0.1  21aug2026
*! gvar coint -- Johansen trace and maximum-eigenvalue tests for each country
*! model, with I(1) weakly exogenous regressors, and rank selection.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   moment matrices, concentrated on Z2      <- Toolbox cointegration_test.m
*   trace = -T sum log(1-lambda)             <- same
*   max eigenvalue = -T log(1-lambda_r)      <- same
*   Pesaran-Shin-Smith 95% critical values,
*   indexed by (case, n-r, #weakly exog)     <- Toolbox Tech/coint_critvalues.xls
*                                               and get_rank.m
*   sequential rank: stop at the first
*   non-rejection, trace by default          <- Toolbox get_rank.m

program define _gvar_coint, rclass
    version 14.0

    syntax [, STAT(string)      ///
              SET               ///
              RANK(string)      ///
              GRaph             ///
              NAME(string)      ///
              noSUMmary ]

    _gvar_require foreign

    if ("`stat'" == "") local stat trace
    local stat = lower("`stat'")
    if ("`stat'" == "trace")       local istat 1
    else if ("`stat'" == "maxeig") local istat 2
    else {
        di as err "stat() must be {bf:trace} or {bf:maxeig}"
        exit 198
    }

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))

    * -----------------------------------------------------------------------
    * The Pesaran-Shin-Smith critical values, from the engine
    * -----------------------------------------------------------------------
    * These were read from a shipped gvar_cv.dta with findfile, which meant the
    * command failed with rc 601 if that one file went missing.  They are
    * constants, so they now live in gvar_cvtable() in _gvar_mata.ado: no data
    * file, no preserve/restore of the user's data, and nothing to lose.
    * Columns are (dcase, stat, nr, k, cv95), the order mkmat produced.
    tempname CV
    mata: st_matrix("`CV'", gvar_cvtable())

    * -----------------------------------------------------------------------
    * Run the tests
    * -----------------------------------------------------------------------
    tempname R
    mata: st_matrix("`R'", gvar_cointall(st_matrix("`CV'")))

    tempname RK
    mata: st_matrix("`RK'", gvar_rankfrom(st_matrix("`R'"), `istat', `N'))

    * -----------------------------------------------------------------------
    * A unit whose (case, n-r, k) combination is outside the Pesaran-Shin-Smith
    * table gets a MISSING rank, never a fabricated zero.  Stop and say why.
    * -----------------------------------------------------------------------
    local nbad 0
    local badlist ""
    forvalues i = 1/`N' {
        if (`RK'[`i', 1] >= .) {
            local ++nbad
            local u : word `i' of `cn'
            * n and k for this unit sit in columns 8 and 9 of the results
            local kk .
            local nn .
            forvalues q = 1/`=rowsof(`R')' {
                if (`R'[`q', 1] == `i') {
                    local nn = `R'[`q', 8]
                    local kk = `R'[`q', 9]
                    continue, break
                }
            }
            local badlist "`badlist' `u'(n=`nn', k=`kk')"
        }
    }
    if (`nbad' > 0) {
        di as err ""
        di as err "gvar coint: no critical value is available for `nbad' unit(s)."
        di as err "The Pesaran, Shin & Smith (2000) table shipped with the GVAR"
        di as err "Toolbox covers at most 8 weakly exogenous I(1) regressors."
        di as err "Offending units (n = endogenous, k = weakly exogenous):"
        di as err "   `badlist'"
        di as err ""
        di as err "Reduce k for those units, for example with"
        di as err "   {bf:gvar setup ..., noforeign(ep)}      to drop a star variable"
        di as err "   {bf:gvar setup ..., exclude(usa:ep)}    to drop one from one unit"
        di as err "or model the commodity prices with {bf:gvar dominant} instead of"
        di as err "carrying them as weakly exogenous in every country model."
        exit 459
    }

    * -----------------------------------------------------------------------
    * Report
    * -----------------------------------------------------------------------
    if ("`summary'" != "nosummary") {
        _gvar_title "Cointegration tests for the VARX* country models"
        di as text "  Rank chosen sequentially on the " ///
                   as result "`stat'" as text " statistic at 5%."
        di ""
        di as text "  {hline 84}"
        di as text "  Unit" _col(16) "H0" _col(26) "eigenvalue" ///
                   _col(40) "trace" _col(52) "cv95" ///
                   _col(63) "max-eig" _col(76) "cv95"
        di as text "  {hline 84}"

        local nr = rowsof(`R')
        local cur 0
        forvalues q = 1/`nr' {
            local i = `R'[`q', 1]
            local j = `R'[`q', 2]
            if (`i' != `cur') {
                if (`cur' != 0) di as text "  {dup 84:-}"
                local cur = `i'
                local u : word `i' of `cn'
            }
            else {
                local u ""
            }
            local tr  = `R'[`q', 4]
            local tcv = `R'[`q', 5]
            local mx  = `R'[`q', 6]
            local mcv = `R'[`q', 7]
            local t1 " "
            local t2 " "
            if (`tr' < . & `tcv' < . & `tr' > `tcv') local t1 "*"
            if (`mx' < . & `mcv' < . & `mx' > `mcv') local t2 "*"
            di as text "  " %-12s abbrev("`u'", 12)                  ///
               _col(15) as text "r = " as result %2.0f `=`j'-1'      ///
               _col(26) as result %10.4f `=`R'[`q',3]'               ///
               _col(37) as result %10.2f `tr' as text "`t1'"         ///
               _col(49) as result %8.2f  `tcv'                       ///
               _col(60) as result %10.2f `mx' as text "`t2'"         ///
               _col(72) as result %8.2f  `mcv'
        }
        di as text "  {hline 84}"
        di as text "  * marks rejection of H0 at 5% (Pesaran, Shin & Smith 2000"
        di as text "  critical values, indexed by the deterministic case and the"
        di as text "  number of I(1) weakly exogenous regressors)."
        di ""

        di as text "  {hline 50}"
        di as text "  Selected cointegrating ranks"
        di as text "  {hline 50}"
        local line "   "
        forvalues i = 1/`N' {
            local u : word `i' of `cn'
            local rr = `RK'[`i', 1]
            local piece = abbrev("`u'", 9) + "=" + string(`rr')
            if (length("`line'`piece'  ") > 76) {
                di as text "`line'"
                local line "   "
            }
            local line "`line'`piece'  "
        }
        if (trim("`line'") != "") di as text "`line'"
        di as text "  {hline 50}"
        di ""
    }

    * -----------------------------------------------------------------------
    * Store, with optional per-unit overrides
    * -----------------------------------------------------------------------
    if ("`set'" != "" | "`rank'" != "") {
        tempname RR
        matrix `RR' = `RK'
        if ("`rank'" != "") {
            foreach pair of local rank {
                if (strpos("`pair'", "=") == 0) continue
                local nm  = substr("`pair'", 1, strpos("`pair'", "=") - 1)
                local val = substr("`pair'", strpos("`pair'", "=") + 1, .)
                local pos : list posof "`nm'" in cn
                if (`pos' == 0) {
                    di as err "rank(): unknown unit {bf:`nm'}"
                    exit 198
                }
                matrix `RR'[`pos', 1] = `val'
                if ("`summary'" != "nosummary") {
                    di as text "Rank for " as result "`nm'" as text ///
                       " set to " as result `val' as text " by hand."
                }
            }
        }
        mata: gvar_setrank(st_matrix("`RR'"))
        * these three lines were outside the summary guard, so nosummary did
        * not silence the command -- the one thing nosummary exists to do
        if ("`summary'" != "nosummary") {
            di as text "Cointegrating ranks stored in the model."
        }
        return matrix rank = `RR', copy
    }
    else {
        if ("`summary'" != "nosummary") {
            di as text "Add {bf:set} to store these ranks in the model."
        }
        return matrix rank = `RK', copy
    }

    * ---- graph --------------------------------------------------------------
    * Every H0: r = j-1 against its own Pesaran-Shin-Smith critical value.  The
    * cutoff is drawn as a step line because it changes with n-r within each
    * unit, which is the part of the table that is hardest to read as numbers.
    if ("`graph'" != "") {
        local nq = rowsof(`R')
        tempname G
        matrix `G' = J(`nq', 4, .)
        local sc 4
        local cc 5
        if (`istat' == 2) {
            local sc 6
            local cc 7
        }
        forvalues q = 1/`nq' {
            matrix `G'[`q', 1] = `R'[`q', 1]
            matrix `G'[`q', 2] = `R'[`q', `sc']
            matrix `G'[`q', 3] = `R'[`q', `cc']
            matrix `G'[`q', 4] = 1
        }
        local sname "Trace"
        if (`istat' == 2) local sname "Maximal-eigenvalue"
        local sub "each H0: r = j-1 against its 95% Pesaran-Shin-Smith value; marked = reject"
        _gvar_dotplot `G' `nq' "`cn'" ///
            "`sname' cointegration statistics" "`sub'" ///
            "statistic" "`name'" 0
    }

    return matrix coint = `R', copy
    return local  stat  "`stat'"
end
