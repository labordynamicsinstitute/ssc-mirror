*! _gvar_estimate 1.0.1  21aug2026
*! gvar estimate -- reduced-rank ML estimation of every VECMX* country model
*! and recovery of the VARX* representation.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   exactly identified reduced-rank ML,
*   beta normalised by beta'S11 beta = I     <- Toolbox mlcoint.m
*   beta imposed (over-identifying restr.)   <- Toolbox mlcoint_r.m
*   identity-block normalisation of beta     <- Toolbox gvar.m (beta_norm)
*   OLS / White / Newey-West standard errors <- Toolbox mlcoint.m, neweywest.m
*   Phi and Lambda from the VECMX* estimates <- Toolbox vecx2varx.m

program define _gvar_estimate, rclass
    version 14.0

    syntax [, VCE(string)        ///
              BETA               ///
              BETARestr(name)    ///
              DETail(string)     ///
              SOLVE              ///
              noSUMmary ]

    _gvar_require foreign

    if ("`vce'" == "") local vce ols
    local vce = lower("`vce'")
    if ("`vce'" == "ols")         local ivce 1
    else if ("`vce'" == "robust") local ivce 2
    else if ("`vce'" == "nwest")  local ivce 3
    else {
        di as err "vce() must be {bf:ols}, {bf:robust} or {bf:nwest}"
        exit 198
    }

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))
    mata: st_local("pmax", strofreal(gvar_getpmax()))

    * -----------------------------------------------------------------------
    * Imposed cointegrating vectors, if any
    * -----------------------------------------------------------------------
    if ("`betarestr'" != "") {
        capture confirm matrix `betarestr'
        if _rc {
            di as err "betarestr(): matrix {bf:`betarestr'} not found"
            exit 111
        }
        di as err "betarestr() is accepted but the restricted branch is exercised"
        di as err "through {bf:gvar overid}; use that subcommand."
        exit 198
    }
    mata: __gvar_betar = J(gvar_getN(), 1, NULL)
    mata: gvar_estim(__gvar_betar)
    mata: mata drop __gvar_betar

    if ("`solve'" != "") {
        * Same precondition gvar solve enforces: a dominant block declared at
        * setup but not yet fitted makes the stack non-conformable.  Reached via
        * this option too, so the check belongs on both paths.
        _gvar_require dominant
        mata: gvar_solvemodel()
    }

    * -----------------------------------------------------------------------
    * Report
    * -----------------------------------------------------------------------
    tempname FIT RK LG CS
    mata: st_matrix("`FIT'", gvar_getfit())
    mata: st_matrix("`RK'",  gvar_getrank())
    mata: st_matrix("`LG'",  gvar_getlags())
    mata: st_matrix("`CS'",  gvar_getcase())

    if ("`summary'" != "nosummary") {
        _gvar_title "VECMX* country models, reduced-rank ML"
        di as text "  GVAR lag order        " as result %6.0f `pmax'
        di as text "  Standard errors       " as result %10s "`vce'"
        di ""
        di as text "  {hline 72}"
        di as text "  Unit" _col(16) "p" _col(21) "q" _col(27) "r" ///
                   _col(33) "case" _col(44) "logL" _col(58) "SBC"
        di as text "  {hline 72}"
        forvalues i = 1/`N' {
            local u : word `i' of `cn'
            di as text "  " %-12s abbrev("`u'", 12)          ///
               _col(14) as result %3.0f `=`LG'[`i',1]'       ///
               _col(19) as result %3.0f `=`LG'[`i',2]'       ///
               _col(25) as result %3.0f `=`RK'[`i',1]'       ///
               _col(32) as result %4.0f `=`CS'[`i',1]'       ///
               _col(38) as result %13.2f `=`FIT'[`i',1]'     ///
               _col(52) as result %13.2f `=`FIT'[`i',3]'
        }
        di as text "  {hline 72}"
        di as text "  p, q are the VARX* orders; r the cointegrating rank;"
        di as text "  case the MacKinnon-Haug-Michelis deterministic case."
        di ""
    }

    * -----------------------------------------------------------------------
    * Cointegrating vectors
    * -----------------------------------------------------------------------
    if ("`beta'" != "") {
        _gvar_show_beta "`cn'" `N'
    }

    * -----------------------------------------------------------------------
    * Full coefficient table for one unit
    * -----------------------------------------------------------------------
    if ("`detail'" != "") {
        local pos : list posof "`detail'" in cn
        if (`pos' == 0) {
            di as err "detail(): unknown unit {bf:`detail'}"
            exit 198
        }
        _gvar_show_unit `pos' "`detail'" `ivce' "`vce'"
    }

    return matrix fit  = `FIT', copy
    return matrix rank = `RK', copy
    return matrix lags = `LG', copy
    return local  vce  "`vce'"
    return scalar N    = `N'
    return scalar pmax = `pmax'
end

* ---------------------------------------------------------------------------
* Normalised cointegrating vectors, one block per unit
* ---------------------------------------------------------------------------
program define _gvar_show_beta
    version 14.0
    args cn N

    _gvar_title "Normalised cointegrating vectors (beta)"
    forvalues i = 1/`N' {
        local u : word `i' of `cn'
        tempname B
        mata: st_matrix("`B'", gvar_getbeta(`i'))
        if (colsof(`B') == 0 | rowsof(`B') == 0) continue
        mata: st_local("yl", invtokens(gvar_getylist(`i')'))
        mata: st_local("sl", invtokens(gvar_getslist(`i')'))
        mata: st_local("ec", strofreal(gvar_getcase()[`i']))

        local rn ""
        if (`ec' == 4) local rn "trend"
        if (`ec' == 2) local rn "const"
        foreach v of local yl {
            local rn "`rn' `v'"
        }
        foreach v of local sl {
            local rn "`rn' `v'*"
        }

        di ""
        di as text "  {bf:`u'}   rank = " as result colsof(`B')
        di as text "  {hline 60}"
        local nrw = rowsof(`B')
        forvalues rr = 1/`nrw' {
            local lab : word `rr' of `rn'
            di as text "  " %-12s "`lab'" _continue
            forvalues cc = 1/`=colsof(`B')' {
                di as result %12.4f `=`B'[`rr',`cc']' _continue
            }
            di ""
        }
        di as text "  {hline 60}"
    }
    di as text "  Normalised so that the leading r x r block is the identity."
    di ""
end

* ---------------------------------------------------------------------------
* Full VECMX* coefficient table for one unit, with stars
* ---------------------------------------------------------------------------
program define _gvar_show_unit
    version 14.0
    args pos uname ivce vce

    tempname PS SE AL
    mata: st_matrix("`PS'", gvar_getPsi(`pos'))
    mata: st_matrix("`SE'", gvar_getse(`pos', `ivce'))
    mata: st_matrix("`AL'", gvar_getalpha(`pos'))
    mata: st_local("yl", invtokens(gvar_getylist(`pos')'))
    mata: st_local("sl", invtokens(gvar_getslist(`pos')'))
    mata: st_local("ec", strofreal(gvar_getcase()[`pos']))
    mata: st_local("pq", invtokens(strofreal(gvar_getlags()[`pos', .])))
    local p : word 1 of `pq'
    local q : word 2 of `pq'
    local ki = rowsof(`PS')
    local rk = colsof(`AL')

    * column names of the regressor block [ ecm | Z2 ]
    local rn ""
    forvalues j = 1/`rk' {
        local rn "`rn' ec`j'"
    }
    if (`ec' == 3 | `ec' == 4) local rn "`rn' _cons"
    forvalues l = 0/`=`q'-1' {
        foreach v of local sl {
            if (`l' == 0) local rn "`rn' D.`v'*"
            else          local rn "`rn' LD`l'.`v'*"
        }
    }
    forvalues l = 1/`=`p'-1' {
        foreach v of local yl {
            local rn "`rn' LD`l'.`v'"
        }
    }

    _gvar_title "VECMX* coefficients for `uname'   (`vce' standard errors)"
    local nc : word count `rn'
    local eq 0
    foreach dv of local yl {
        local ++eq
        di ""
        di as text "  Equation: D." as result "`dv'"
        di as text "  {hline 62}"
        di as text %-22s "  regressor" _col(26) "coef." _col(40) "s.e." ///
                   _col(52) "t" _col(60) " "
        di as text "  {hline 62}"
        forvalues c = 1/`nc' {
            local lab : word `c' of `rn'
            if (`c' <= `rk') {
                local b = `AL'[`eq', `c']
            }
            else {
                local b = `PS'[`eq', `=`c'-`rk'']
            }
            local s = `SE'[`eq', `c']
            local t = .
            if (`s' > 0 & `s' < .) local t = `b' / `s'
            local st ""
            if (`t' < . ) {
                local pv = 2 * normal(-abs(`t'))
                _gvar_stars `pv'
                local st "`r(stars)'"
            }
            di as text "  " %-20s "`lab'"          ///
               _col(24) as result %12.4f `b'       ///
               _col(37) as result %11.4f `s'       ///
               _col(49) as result %8.2f  `t'       ///
               as text " `st'"
        }
        di as text "  {hline 62}"
    }
    di as text "  * p<0.10   ** p<0.05   *** p<0.01"
    di as text "  ec1..ec`rk' are the error-correction terms; LDl. is the l-th"
    di as text "  lag of a first difference; a trailing * marks a foreign variable."
    di ""
end
