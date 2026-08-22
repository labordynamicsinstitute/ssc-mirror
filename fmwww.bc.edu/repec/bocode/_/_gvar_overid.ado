*! _gvar_overid 1.0.1  21aug2026
*! gvar overid -- likelihood-ratio test of over-identifying restrictions on
*! the cointegrating vectors.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   restricted ML estimation of the VECMX*   <- Toolbox mlcoint_r.m
*   restriction input sheet                  <- Toolbox overid_restr.m
*   the test                                 <- gvar.m:1479-1481
*       overid_LR  = -2*(logl_r - logl)
*       overid_dgf = rows(beta)*cols(beta) - cols(beta)^2 - nunrestrpar
*
* The r^2 term removes the just-identifying normalisation; nunrestrpar is the
* number of coefficients left freely estimated, so only the genuinely
* over-identifying restrictions enter the degrees of freedom.
*
* Restrictions are read from a dataset with one row per restricted
* coefficient:
*
*     unit      relation   term        value
*     usa       1          y            1
*     usa       1          r          -1
*     usa       1          _trend       0
*     euro      1          y            1
*     euro      1          y*          -1
*
* {bf:term} names a row of beta: a domestic variable, a foreign variable
* written {it:name}{bf:*}, or {bf:_trend} (case 4) / {bf:_cons} (case 2).
* Every row of a restricted unit's beta must be supplied -- mlcoint_r.m takes
* beta as GIVEN and estimates the rest conditional on it, so a partially
* specified vector is not meaningful.  Coefficients you want estimated freely
* are declared through {bf:free()}, which feeds nunrestrpar.

program define _gvar_overid, rclass
    version 14.0

    syntax [using/] [,                          ///
        FREE(string)                            ///
        LIST                                    ///
        REPLACE                                 ///
        noSUMmary                               ///
        SAVing(name)                            ///
    ]

    _gvar_require vecmx

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))

    * ---- show the beta layout and stop -------------------------------------
    if ("`list'" != "") {
        _gvar_title "Layout of beta, by unit"
        di as text "  Every row below must appear in the restriction file for"
        di as text "  a unit you restrict.  Rank is the number of relations."
        di ""
        di as text "{hline 78}"
        di as text %-10s "  Unit" %6s "rank" "  beta rows in order"
        di as text "{hline 78}"
        tempname RK
        mata: st_matrix("`RK'", gvar_getrank())
        forvalues i = 1/`N' {
            local u : word `i' of `cn'
            mata: st_local("br", gvar_betarownames(`i'))
            di as text "  " %-8s abbrev("`u'", 8) ///
               as result %6.0f `=`RK'[`i',1]' as text "  `br'"
        }
        di as text "{hline 78}"
        di ""
        exit
    }

    if ("`using'" == "") {
        di as err "specify a restriction dataset:"
        di as err "    {bf:gvar overid using} {it:filename}"
        di as err "with variables {bf:unit relation term value}."
        di as err "Run {bf:gvar overid, list} to see the beta layout first."
        exit 198
    }

    * ---- read the restrictions ---------------------------------------------
    preserve
    quietly use "`using'", clear
    foreach v in unit relation term value {
        capture confirm variable `v'
        if (_rc) {
            di as err "the restriction file must contain {bf:`v'}"
            exit 111
        }
    }
    quietly count
    local nrow = r(N)
    if (`nrow' == 0) {
        di as err "the restriction file is empty"
        exit 2000
    }

    tempname RESTR
    matrix `RESTR' = J(`nrow', 4, .)
    local bad 0
    forvalues q = 1/`nrow' {
        local uu = unit[`q']
        local rr = relation[`q']
        local tt = term[`q']
        local vv = value[`q']

        local ui : list posof "`uu'" in cn
        if (`ui' == 0) {
            di as err "row `q': unit {bf:`uu'} is not in the model"
            local ++bad
            continue
        }
        mata: st_local("br", gvar_betarownames(`ui'))
        local ri : list posof "`tt'" in br
        if (`ri' == 0) {
            di as err "row `q': {bf:`tt'} is not a beta row of unit {bf:`uu'}"
            di as err "   its rows are: `br'"
            local ++bad
            continue
        }
        matrix `RESTR'[`q', 1] = `ui'
        matrix `RESTR'[`q', 2] = `ri'
        matrix `RESTR'[`q', 3] = `rr'
        matrix `RESTR'[`q', 4] = `vv'
    }
    restore
    if (`bad' > 0) {
        di as err "`bad' restriction row(s) could not be matched"
        exit 111
    }

    * ---- free-parameter counts ---------------------------------------------
    tempname NUNR
    matrix `NUNR' = J(`N', 1, 0)
    if ("`free'" != "") {
        local nf : word count `free'
        if (mod(`nf', 2) != 0) {
            di as err "free() takes pairs: {bf:free(}{it:unit} {it:count}" ///
                      " [{it:unit} {it:count} ...]{bf:)}"
            exit 198
        }
        forvalues q = 1(2)`nf' {
            local uu : word `q' of `free'
            local cc : word `=`q'+1' of `free'
            local ui : list posof "`uu'" in cn
            if (`ui' == 0) {
                di as err "free(): unit {bf:`uu'} is not in the model"
                exit 111
            }
            matrix `NUNR'[`ui', 1] = `cc'
        }
    }

    * ---- the test ------------------------------------------------------------
    local st 0
    if ("`replace'" != "") local st 1
    tempname R
    mata: st_matrix("`R'", gvar_overidrun(st_matrix("`RESTR'"), ///
                                          st_matrix("`NUNR'"), `st'))
    local nr = rowsof(`R')
    if (`nr' == 0 | colsof(`R') < 6) {
        di as err "no unit carried a usable restriction"
        di as err "(a unit with rank 0 cannot be restricted)"
        exit 459
    }

    * counters live outside the summary guard: -return- must always have
    * something to read.  Same trap as gvar wetest and gvar stability.
    local nrej 0
    forvalues q = 1/`nr' {
        local pv = `R'[`q', 4]
        if (`pv' < . & `pv' < 0.05) local ++nrej
    }

    if ("`summary'" != "nosummary") {
        _gvar_title "Over-identifying restrictions on the cointegrating vectors"
        di as text "  LR = -2(logL restricted - logL unrestricted)."
        di as text "  d.f. = rows(beta)*rank - rank^2 - free parameters."
        di ""
        di as text "{hline 84}"
        di as text %-12s "  Unit" _col(16) "logL unrestr" _col(32) "logL restr" ///
                   _col(46) "LR" _col(56) "d.f." _col(66) "p (chi2)"
        di as text "{hline 84}"
        forvalues q = 1/`nr' {
            local i = `R'[`q', 1]
            local u : word `i' of `cn'
            local pv = `R'[`q', 4]
            local mk " "
            if (`pv' < . & `pv' < 0.05) local mk "*"
            di as text "  " %-10s abbrev("`u'", 10)      ///
               _col(14) as result %14.3f `=`R'[`q',5]'   ///
               _col(30) as result %13.3f `=`R'[`q',6]'   ///
               _col(44) as result %10.3f `=`R'[`q',2]'   ///
               _col(55) as result %6.0f  `=`R'[`q',3]'   ///
               _col(64) as result %9.3f  `pv' as text "`mk'"
        }
        di as text "{hline 84}"
        di as text "  * rejects the restrictions at 5% on the asymptotic" ///
                   " chi-squared: " as result `nrej' as text " of " ///
                   as result `nr' as text "."
        di ""
        di as text "  {bf:Read the chi-squared p-value with care.}  The GVAR"
        di as text "  Toolbox does not use it: gvar.m takes overid_LR_95cv and"
        di as text "  overid_LR_99cv from bootstrap_GVAR.m, because the country"
        di as text "  models are estimated conditional on weakly exogenous"
        di as text "  regressors whose own uncertainty the asymptotic"
        di as text "  distribution ignores."
        if (`st' == 1) {
            di as text "  The restricted estimates have been installed in the"
            di as text "  model; re-run {bf:gvar solve} to propagate them."
        }
        else {
            di as text "  Add {bf:replace} to install the restricted estimates."
        }
        di ""
    }

    if ("`saving'" != "") {
        matrix `saving' = `R'
    }
    return matrix overid = `R', copy
    return scalar nunits = `nr'
    return scalar nrej   = `nrej'
end
