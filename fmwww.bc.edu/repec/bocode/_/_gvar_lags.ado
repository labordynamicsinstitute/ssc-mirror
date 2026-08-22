*! _gvar_lags 1.0.1  21aug2026
*! gvar lags -- VARX*(p,q) order selection for every country model.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   VARX*(p,q) with constant AND trend, OLS   <- Toolbox select_varxlag.m
*   AIC / SBC in the DdPS levels form         <- Toolbox AIC_SBC.m
*     (larger is better -- see _INVENTORY.md trap 2)
*   F test for residual serial correlation    <- Toolbox Ftest_rsc.m
*   per-unit lag orders may differ            <- Toolbox gvar.m section 3.5
*   log-determinant AIC/HQ/SC/FPE             <- GVARX .VARselect (gvar lags, vars)

program define _gvar_lags, rclass
    version 14.0

    syntax [, MAXLag(integer 2)   ///
              MAXP(integer 0)     ///
              MAXQ(integer 0)     ///
              IC(string)          ///
              PSC(integer 4)      ///
              SET                 ///
              FIXed(numlist integer min=1 max=2 >0) ///
              DETail(string)      ///
              noSUMmary ]

    _gvar_require foreign

    if (`maxp' == 0) local maxp `maxlag'
    if (`maxq' == 0) local maxq `maxlag'

    if ("`ic'" == "") local ic sbc
    local ic = lower("`ic'")
    if ("`ic'" == "aic")      local icsel 2
    else if ("`ic'" == "sbc") local icsel 3
    else {
        di as err "ic() must be {bf:aic} or {bf:sbc}"
        exit 198
    }

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))

    * =======================================================================
    * A fixed order for every unit
    * =======================================================================
    if ("`fixed'" != "") {
        local fp : word 1 of `fixed'
        local fq : word 2 of `fixed'
        if ("`fq'" == "") local fq `fp'
        tempname L
        matrix `L' = J(`N', 2, 0)
        forvalues i = 1/`N' {
            matrix `L'[`i', 1] = `fp'
            matrix `L'[`i', 2] = `fq'
        }
        mata: gvar_setlags(st_matrix("`L'"))
        di as text "VARX* order fixed at p = " as result `fp' ///
                   as text ", q = " as result `fq' as text " for all units."
        return scalar p = `fp'
        return scalar q = `fq'
        exit
    }

    * =======================================================================
    * Grid search
    * =======================================================================
    tempname R
    mata: st_matrix("`R'", gvar_lagsel(`maxp', `maxq', `icsel', `psc'))

    if ("`summary'" != "nosummary") {
        _gvar_title "VARX*(p,q) order selection by `=upper("`ic'")'"
        di as text "  Grid searched: p = 1..`maxp', q = 1..`maxq'"
        di as text "  AIC and SBC are in the Dees-di Mauro-Pesaran-Smith levels"
        di as text "  form, so LARGER is better."
        di ""
        di as text "  {hline 74}"
        di as text "  Unit" _col(16) "p" _col(22) "q" _col(32) "logL" ///
                   _col(44) "AIC" _col(56) "SBC" _col(66) "F(sc)"
        di as text "  {hline 74}"
        local nrej 0
        forvalues i = 1/`N' {
            local u : word `i' of `cn'
            local fs = `R'[`i', 8]
            local fc = `R'[`i', 7]
            local mk " "
            if (`fs' < . & `fc' < . & `fs' > `fc') {
                local mk "*"
                local ++nrej
            }
            di as text "  " %-12s abbrev("`u'", 12)                ///
               _col(15) as result %3.0f `=`R'[`i',1]'              ///
               _col(21) as result %3.0f `=`R'[`i',2]'              ///
               _col(27) as result %11.2f `=`R'[`i',3]'             ///
               _col(39) as result %11.2f `=`R'[`i',4]'             ///
               _col(51) as result %11.2f `=`R'[`i',5]'             ///
               _col(64) as result %7.2f `=`R'[`i',8]' as text "`mk'"
        }
        di as text "  {hline 74}"
        di as text "  F(sc) is the largest residual serial-correlation F across"
        di as text "  the unit's equations, order " as result `psc' as text ";"
        di as text "  * marks rejection at 5% (" as result `nrej' ///
                   as text " of " as result `N' as text " units)."
        di ""
    }

    * =======================================================================
    * Detail for one unit: the whole grid
    * =======================================================================
    if ("`detail'" != "") {
        local pos : list posof "`detail'" in cn
        if (`pos' == 0) {
            di as err "detail(): unknown unit {bf:`detail'}"
            exit 198
        }
        tempname G
        mata: st_matrix("`G'", gvar_laggrid(`pos', `maxp', `maxq', `psc'))
        _gvar_title "VARX* order grid for `detail'"
        di as text "  {hline 66}"
        di as text "     p     q" _col(20) "logL" _col(34) "AIC" ///
                   _col(48) "SBC" _col(60) "F(sc)"
        di as text "  {hline 66}"
        forvalues r = 1/`=rowsof(`G')' {
            di as result "  " %4.0f `=`G'[`r',1]' %6.0f `=`G'[`r',2]' ///
               _col(13) %12.2f `=`G'[`r',3]'                          ///
               _col(27) %12.2f `=`G'[`r',4]'                          ///
               _col(41) %12.2f `=`G'[`r',5]'                          ///
               _col(56) %8.2f `=`G'[`r',7]'
        }
        di as text "  {hline 66}"
        return matrix grid = `G', copy
    }

    * =======================================================================
    * Store the selected orders
    * =======================================================================
    if ("`set'" != "") {
        tempname L
        matrix `L' = `R'[1..`N', 1..2]
        mata: gvar_setlags(st_matrix("`L'"))
        mata: st_local("pmax", strofreal(gvar_getpmax()))
        * outside the summary guard this escaped nosummary, the same way the
        * matching line in gvar coint did
        if ("`summary'" != "nosummary") {
            di as text "Selected orders stored; the GVAR lag order is " ///
                       as result `pmax' as text "."
        }
    }
    else if ("`summary'" != "nosummary") {
        di as text "Add {bf:set} to store these orders in the model."
    }

    return matrix lags = `R', copy
    return local  ic   "`ic'"
    return scalar maxp = `maxp'
    return scalar maxq = `maxq'
end
