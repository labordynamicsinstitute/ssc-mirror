*! _gvar_gc 1.0.1  21aug2026
*! gvar gc -- Granger causality within a country model, with and without the
*! foreign block.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   two tests per unit, one on a plain VAR of the unit's own variables and
*   one on a VARX carrying the foreign block as exogenous regressors
*                                             <- GVARX .grangerGVAR
*   the test itself                           <- vars::causality
*       STAT = (R b)' [R (Sigma kron (Z'Z)^-1) R']^-1 (R b) / N
*       df1  = p * #cause * #(non-cause)
*       df2  = K * obs - length(PI)
*   foreign block entered at lags 0..FLag-1   <- embed(Ft, FLag)
*   instantaneous causality                   <- vars::causality, result2
*       lambda = obs * v' C' [2 C D+ (S kron S) D+' C']^-1 C v,  v = vech(S)
*
* causality() has NO effect argument: R2[g,-j] restricts the cause lags in
* every equation EXCEPT the cause's own, so the effect set is all non-cause
* variables and df1 follows from that.  {bf:effect()} narrows it, and is a
* generalisation of the source rather than part of it.
*
* {bf:Note on fidelity.}  vars::causality was read from the package source;
* sandwich::vcovHC, which .grangerGVAR passes by default, is not part of the
* supplied sources.  {bf:vce(oim)} is causality()'s own default,
* Sigma kron (Z'Z)^-1, and is exact.  {bf:vce(robust)} is the standard HC0
* sandwich rather than a port of sandwich::vcovHC, and is labelled as such.
*
* Reporting both the VAR and the VARX test is the point of the exercise: it
* shows whether conditioning on the rest of the world overturns a
* within-country causal reading.

program define _gvar_gc, rclass
    version 14.0

    syntax [,                                   ///
        UNITs(string)                           ///
        CAUSE(string)                           ///
        EFFect(string)                          ///
        LAGS(integer 0)                         ///
        FLAGS(integer 3)                        ///
        VCE(string)                             ///
        noSUMmary                               ///
        SAVing(name)                            ///
        GRaph                                   ///
        NAME(string)                            ///
    ]

    _gvar_require foreign

    if ("`cause'" == "") {
        di as err "cause() is required: the variable(s) whose lags are"
        di as err "excluded under the null, e.g. {bf:cause(r)}"
        exit 198
    }
    if (`flags' < 1) {
        di as err "flags() must be at least 1"
        exit 198
    }

    if ("`vce'" == "") local vce oim
    local vce = lower("`vce'")
    if      ("`vce'" == "oim")    local rb 0
    else if ("`vce'" == "robust") local rb 1
    else {
        di as err "vce() must be {bf:oim} or {bf:robust}"
        exit 198
    }

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))
    tempname LG
    mata: st_matrix("`LG'", gvar_getlags())

    * ---- which units --------------------------------------------------------
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

    * ---- run ----------------------------------------------------------------
    * Stata matrices cannot have zero rows, so J(0, 9, .) is an error rather
    * than an empty accumulator.  Count the eligible units first.
    local elig ""
    local nskip 0
    local skipped ""
    foreach i of local usel {
        local u : word `i' of `cn'
        mata: st_local("yl", invtokens(gvar_getylist(`i')'))
        local ok 1
        local hitc 0
        foreach v of local cause {
            local q : list posof "`v'" in yl
            if (`q' > 0) local hitc 1
        }
        if (`hitc' == 0) local ok 0
        if ("`effect'" != "") {
            local hite 0
            foreach v of local effect {
                local q : list posof "`v'" in yl
                if (`q' > 0) local hite 1
            }
            if (`hite' == 0) local ok 0
        }
        if (`ok') local elig "`elig' `i'"
        else {
            local ++nskip
            local skipped "`skipped' `u'"
        }
    }
    local nelig : word count `elig'
    if (`nelig' == 0) {
        di as err "no unit has {bf:`cause'} in its own endogenous block"
        if ("`effect'" != "") {
            di as err "together with {bf:`effect'}"
        }
        exit 459
    }

    tempname R ROW CS ES
    matrix `R' = J(`nelig', 12, .)
    local rowq 0
    foreach i of local elig {
        local ++rowq
        local u : word `i' of `cn'
        mata: st_local("yl", invtokens(gvar_getylist(`i')'))
        local ki : word count `yl'

        local cpos ""
        foreach v of local cause {
            local q : list posof "`v'" in yl
            if (`q' > 0) local cpos "`cpos' `q'"
        }

        * causality() takes no effect argument: R2[g,-j] restricts the cause
        * lags in EVERY equation except the cause's own, so the effect set is
        * all non-cause variables.  effect() narrows that, and is a
        * generalisation of the source rather than part of it.
        local epos ""
        if ("`effect'" == "") {
            forvalues z = 1/`ki' {
                local in : list posof "`z'" in cpos
                if (`in' == 0) local epos "`epos' `z'"
            }
        }
        else {
            foreach v of local effect {
                local q : list posof "`v'" in yl
                if (`q' > 0) local epos "`epos' `q'"
            }
        }
        local nc : word count `cpos'
        local ne : word count `epos'

        matrix `CS' = J(`nc', 1, 0)
        local q 0
        foreach z of local cpos {
            local ++q
            matrix `CS'[`q', 1] = `z'
        }
        matrix `ES' = J(`ne', 1, 0)
        local q 0
        foreach z of local epos {
            local ++q
            matrix `ES'[`q', 1] = `z'
        }

        local pu = `LG'[`i', 1]
        if (`lags' > 0) local pu = `lags'
        mata: st_matrix("`ROW'", gvar_gcrun(`i', st_matrix("`CS'"), ///
                                            st_matrix("`ES'"), `pu', ///
                                            `flags', `rb'))
        forvalues z = 1/12 {
            matrix `R'[`rowq', `z'] = `ROW'[1, `z']
        }
    }

    local nr = rowsof(`R')

    * ---- counters live outside the summary guard ----------------------------
    local nv 0
    local nx 0
    local nflip 0
    forvalues q = 1/`nr' {
        local pa = `R'[`q', 5]
        local pb = `R'[`q', 9]
        if (`pa' < . & `pa' < 0.05) local ++nv
        if (`pb' < . & `pb' < 0.05) local ++nx
        if (`pa' < . & `pb' < .) {
            if ((`pa' < 0.05) != (`pb' < 0.05)) local ++nflip
        }
    }

    * the label is needed by the graph too, so it cannot live inside the
    * display guard
    local elab "`effect'"
    if ("`effect'" == "") local elab "every other variable"

    if ("`summary'" != "nosummary") {
        _gvar_title "Granger causality: `cause' -> `elab'"
        di as text "  H0: the lags of " as result "`cause'" as text ///
                   " do not enter the " as result "`elab'" as text ///
                   " equation(s)."
        di as text "  Left block: a plain VAR of the unit's own variables."
        di as text "  Right block: the same VAR with the foreign block added"
        di as text "  as exogenous regressors at lags 0 to " ///
                   as result `=`flags'-1' as text "."
        di as text "  Covariance: " as result "`vce'" _continue
        if (`rb' == 1) {
            di as text "  (HC0 sandwich, not a port of sandwich::vcovHC)"
        }
        else {
            di as text "  (Sigma kron (Z'Z)^-1, causality()'s own default)"
        }
        di ""
        di as text "{hline 100}"
        di as text %-10s "  Unit" _col(14) "{bf:VAR}" _col(22) "F" ///
                   _col(34) "df1" _col(42) "df2" _col(52) "p" ///
                   _col(60) "{bf:VARX}" _col(68) "F" _col(78) "p" ///
                   _col(88) "instant p"
        di as text "{hline 100}"
        forvalues q = 1/`nr' {
            local i = `R'[`q', 1]
            local u : word `i' of `cn'
            local pa = `R'[`q', 5]
            local pb = `R'[`q', 9]
            local ma " "
            if (`pa' < . & `pa' < 0.05) local ma "*"
            local mb " "
            if (`pb' < . & `pb' < 0.05) local mb "*"
            local fl " "
            if (`pa' < . & `pb' < .) {
                if ((`pa' < 0.05) != (`pb' < 0.05)) local fl "<"
            }
            di as text "  " %-8s abbrev("`u'", 8)          ///
               _col(16) as result %10.3f `=`R'[`q',2]'     ///
               _col(30) as result %6.0f  `=`R'[`q',3]'     ///
               _col(38) as result %7.0f  `=`R'[`q',4]'     ///
               _col(46) as result %8.3f  `pa' as text "`ma'" ///
               _col(62) as result %10.3f `=`R'[`q',6]'     ///
               _col(72) as result %8.3f  `pb' as text "`mb'" ///
               _col(84) as result %9.3f  `=`R'[`q',12]'      ///
               _col(95) as text "`fl'"
        }
        di as text "{hline 100}"
        di as text "  instant p is the instantaneous-causality test that"
        di as text "  causality() returns alongside the Granger one: a Wald"
        di as text "  chi2 on the contemporaneous covariance block."
        di as text "  * rejects at 5%.  VAR " as result `nv' as text "/" ///
           as result `nr' as text ",  VARX " as result `nx' as text "/" ///
           as result `nr' as text "."
        if (`nflip' > 0) {
            di as text "  < marks the " as result `nflip' as text ///
               " unit(s) where the two disagree: conditioning on"
            di as text "  the foreign block changes the conclusion, which is"
            di as text "  the whole reason for running both."
        }
        else {
            di as text "  The two blocks agree everywhere."
        }
        if (`nskip' > 0) {
            di as text "  Skipped " as result `nskip' as text ///
               " unit(s) lacking one of the variables:"
            di as text "  " as result "`skipped'"
        }
        di ""
    }

    if ("`graph'" != "") {
        _gvar_gc_graph `R' `nr' "`cn'" "`cause'" "`elab'" "`name'"
    }

    if ("`saving'" != "") {
        matrix `saving' = `R'
    }
    return matrix gc = `R', copy
    return scalar nvar  = `nv'
    return scalar nvarx = `nx'
    return scalar nflip = `nflip'
    return scalar nunits = `nr'
    return scalar nskip  = `nskip'
end

* ---------------------------------------------------------------------------
* Granger causality with and without the foreign block, one point per unit.
*
* The interesting thing about a GVAR Granger test is not the level of either
* p-value but whether conditioning on x* changes the answer, so the two are
* plotted against each other.  A unit off the diagonal in the top-left or
* bottom-right quadrant is one whose verdict FLIPS when the foreign variables
* are added -- which for the demo model happens for a quarter of the units, and
* is invisible in either column read on its own.
*
* Both axes are on a log scale because the interesting p-values are small and a
* linear axis piles them all into one corner.
* ---------------------------------------------------------------------------
program define _gvar_gc_graph
    version 14.0
    args R nr cn clab elab name

    _gvar_palette
    local c1   "`r(c1)'"
    local c2   "`r(c2)'"
    local grid "`r(grid)'"
    local reg  "`r(region)'"
    local neg  "`r(neg)'"
    local band "`r(band)'"

    local nm "gvar_gc"
    if ("`name'" != "") local nm "`name'"

    preserve
    quietly {
        clear
        svmat double `R', names(col)
        rename c1 unit
        rename c5 pvar
        rename c9 pvarx

        * floor the p-values so a log axis has something to show for an exact
        * zero, and say so in the note rather than dropping the point
        gen double lp_var  = max(pvar,  1e-6)
        gen double lp_varx = max(pvarx, 1e-6)

        gen str12 ulab = ""
        forvalues q = 1/`nr' {
            local u = unit[`q']
            local l : word `u' of `cn'
            _gvar_ablab "`l'" 10
            replace ulab = "`_ablab'" in `q'
        }

        * a flip is a unit that crosses 5% in one specification but not the
        * other, in either direction
        gen byte flip = 0
        replace flip = 1 if (pvar < 0.05) != (pvarx < 0.05)
        count if flip == 1
        local nflip = r(N)

        gen double f_var  = lp_var  if flip == 1
        gen double f_varx = lp_varx if flip == 1
        gen double k_var  = lp_var  if flip == 0
        gen double k_varx = lp_varx if flip == 0

        twoway (function y = x, range(1e-6 1) lcolor("`grid'")              ///
                    lpattern(solid) lwidth(thin))                          ///
               (scatter k_varx k_var, msymbol(o) msize(small)              ///
                    mcolor("`c1'%70"))                                     ///
               (scatter f_varx f_var, msymbol(O) msize(small)              ///
                    mcolor("`neg'") mlcolor("`c2'") mlwidth(vthin)         ///
                    mlabel(ulab) mlabsize(vsmall) mlabcolor(black)         ///
                    mlabposition(3))                                       ///
               , `reg'                                                     ///
                 xscale(log) yscale(log)                                   ///
                 xlabel(0.000001 "1e-6" 0.0001 "1e-4" 0.01 "0.01"          ///
                        0.05 "0.05" 0.5 "0.5" 1 "1", labsize(vsmall))      ///
                 ylabel(0.000001 "1e-6" 0.0001 "1e-4" 0.01 "0.01"          ///
                        0.05 "0.05" 0.5 "0.5" 1 "1", labsize(vsmall)       ///
                        angle(0))                                          ///
                 xline(0.05, lcolor("`c2'") lpattern(dash) lwidth(thin))   ///
                 yline(0.05, lcolor("`c2'") lpattern(dash) lwidth(thin))   ///
                 xtitle("p-value, VAR (no foreign block)", size(small))    ///
                 ytitle("p-value, VARX* (conditioning on x*)", size(small)) ///
                 title("Does `clab' Granger-cause `elab'?",                ///
                       size(medium) color(black))                          ///
                 subtitle("labelled points change verdict at 5% when x* is added", ///
                          size(small) color(black))                        ///
                 note("dashed lines: 5%; solid line: no change."            ///
                      "  p-values are floored at 1e-6 for the log axis.",   ///
                      size(vsmall) color(black))                            ///
                 legend(off) name(`nm', replace)
    }
    restore

    di as text "  graph saved as {bf:`nm'}  (" as result `nflip' ///
       as text " unit(s) change verdict)"
end
