*! _gvar_avgcorr 1.0.1  21aug2026
*! gvar avgcorr -- average pairwise cross-section correlations of the data and
*! of the country-model residuals.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   rhobar_i = (sum_j rho_ij - 1)/(N-1) on levels, differences and residuals
*                                   <- Toolbox avgcorrs.m, corrmat.m
*   the same statistic in R         <- GVARX averageCORgvar
*   bucketed summary of |rhobar|    <- BGVAR avg.pair.cc
*
* Including the foreign variables in each country model should soak up the
* cross-section dependence, so the residual correlations ought to be much
* smaller than those of the data.  If they are not, generalized impulse
* responses are not trustworthy (Dees, di Mauro, Pesaran & Smith 2007).

program define _gvar_avgcorr, rclass
    version 14.0

    syntax [, BLOCK(string) noSUMmary GRaph NAME(string) SAVing(name) ]

    _gvar_require foreign

    if ("`block'" == "") local block "levels diff resid"
    local block = lower("`block'")

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))
    mata: st_local("vn", invtokens(gvar_getvname()'))

    tempname R
    mata: st_matrix("`R'", gvar_avgcorr_all())
    local nr = rowsof(`R')

    local vl ""
    forvalues q = 1/`nr' {
        local j = `R'[`q', 1]
        local v : word `j' of `vn'
        local p : list posof "`v'" in vl
        if (`p' == 0) local vl "`vl' `v'"
    }
    local vl = trim("`vl'")
    local nv : word count `vl'

    if ("`summary'" != "nosummary") {
        foreach b of local block {
            if ("`b'" == "levels") {
                local col 3
                local blab "Levels of the variables"
            }
            if ("`b'" == "diff") {
                local col 4
                local blab "First differences of the variables"
            }
            if ("`b'" == "resid") {
                local col 5
                local blab "VECMX* residuals"
            }
            _gvar_avgcorr_table `R' `nr' `col' "`blab'" "`cn'" "`vl'" "`vn'"
        }
    }

    if ("`graph'" != "") {
        _gvar_avgcorr_graph `R' `nr' "`cn'" "`vl'" "`vn'" "`name'"
    }

    if ("`saving'" != "") {
        matrix `saving' = `R'
    }
    return matrix avgcorr = `R', copy
end

* ---------------------------------------------------------------------------
program define _gvar_avgcorr_table
    version 14.0
    args R nr col blab cn vl vn

    local nv : word count `vl'
    local nu : word count `cn'
    local w = 14 + 9 * `nv'
    if (`w' > 120) local w 120

    di ""
    di as text "{hline `w'}"
    di as text "  {bf:Average pairwise cross-section correlations} -- `blab'"
    di as text "{hline `w'}"
    di as text %-13s "  Unit" _continue
    foreach v of local vl {
        di as text %9s abbrev("`v'", 8) _continue
    }
    di ""
    di as text "{hline `w'}"

    * bucket counters, as in BGVAR's avg.pair.cc
    local b1 0
    local b2 0
    local b3 0
    local b4 0
    forvalues i = 1/`nu' {
        local u : word `i' of `cn'
        local any 0
        forvalues q = 1/`nr' {
            if (`R'[`q', 2] == `i' & `R'[`q', `col'] < .) local any 1
        }
        if (`any' == 0) continue
        di as text "  " %-11s abbrev("`u'", 11) _continue
        foreach v of local vl {
            local jj : list posof "`v'" in vn
            local x .
            forvalues q = 1/`nr' {
                if (`R'[`q',1] == `jj' & `R'[`q',2] == `i') {
                    local x = `R'[`q', `col']
                    continue, break
                }
            }
            if (`x' >= .) {
                * A dash, not a dot: this unit does not have this variable, so
                * there is no series to correlate.  Eleven countries have no long
                * rate and seven no equity price, which is most of the blanks in
                * this table; the usa has no exchange rate because it is the
                * numeraire.  A dot would suggest a correlation that failed to
                * compute, and none do.
                di as text %9s "-" _continue
            }
            else {
                di as result %9.3f `x' _continue
                local a = abs(`x')
                if (`a' <= 0.1)                    local ++b1
                else if (`a' > 0.1 & `a' <= 0.2)   local ++b2
                else if (`a' > 0.2 & `a' <= 0.5)   local ++b3
                else                               local ++b4
            }
        }
        di ""
    }
    di as text "{hline `w'}"
    local tot = `b1' + `b2' + `b3' + `b4'
    if (`tot' > 0) {
        * State what the percentages are taken over.  The shares are of the
        * cells that EXIST, so a reader comparing `tot' with 26 x (number of
        * variables) will find it short -- by exactly the dashes, not by
        * anything lost.
        di as text "  {bf:-} means that unit does not have that variable."
        di as text "  Shares below are over the " as result `tot' ///
           as text " (unit, variable) pairs that exist."
        di as text "  |rho| distribution:  " ///
           as text "<=0.1 " as result `b1' as text " (" %4.1f `=100*`b1'/`tot'' "%)  " ///
           as text "0.1-0.2 " as result `b2' as text " (" %4.1f `=100*`b2'/`tot'' "%)  " ///
           as text "0.2-0.5 " as result `b3' as text " (" %4.1f `=100*`b3'/`tot'' "%)  " ///
           as text ">0.5 " as result `b4' as text " (" %4.1f `=100*`b4'/`tot'' "%)"
    }
end

* ---------------------------------------------------------------------------
* Levels vs residual correlations: the residuals should collapse toward zero
* ---------------------------------------------------------------------------
program define _gvar_avgcorr_graph
    version 14.0
    args R nr cn vl vn gname
    if ("`gname'" == "") local gname gvar_avgcorr

    _gvar_palette
    local reg  "`r(region)'"
    local c1   "`r(c1)'"
    local c2   "`r(c2)'"
    local zero "`r(zero)'"

    preserve
    clear
    qui set obs `nr'
    qui gen int    vj  = .
    qui gen int    ui  = .
    qui gen double lev = .
    qui gen double res = .
    forvalues q = 1/`nr' {
        qui replace vj  = `R'[`q', 1] in `q'
        qui replace ui  = `R'[`q', 2] in `q'
        qui replace lev = `R'[`q', 3] in `q'
        qui replace res = `R'[`q', 5] in `q'
    }
    qui drop if missing(lev) & missing(res)

    twoway ///
        (function y = x, range(-1 1) lcolor("`c2'") ///
             lpattern(shortdash) lwidth(medthin)) ///
        (scatter res lev, msymbol(circle) msize(small) ///
             mcolor("`c1'%60") mlcolor("`c1'") mlwidth(vthin)) ///
        , `reg' ///
          yline(0, lcolor("`zero'") lpattern(dash)) ///
          xline(0, lcolor("`zero'") lpattern(dash)) ///
          ylabel(-1(0.5)1, angle(0) labsize(small) grid glcolor(gs15)) ///
          xlabel(-1(0.5)1, labsize(small)) ///
          ytitle("average correlation of the residuals", size(small)) ///
          xtitle("average correlation of the levels", size(small)) ///
          title("Cross-section dependence before and after conditioning", ///
                size(medium) color(black)) ///
          subtitle("points should fall well inside the 45-degree line", ///
                   size(vsmall) color(gs7)) ///
          aspectratio(1) name(`gname', replace) legend(off)
    restore
end
