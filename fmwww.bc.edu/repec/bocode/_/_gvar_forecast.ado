*! _gvar_forecast 1.0.1  21aug2026
*! gvar forecast -- ex-ante point and conditional forecasts from the solved
*! GVAR.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   recursive point forecast          <- Toolbox forecast_GVAR.m
*       x(T+j) = d0 + d1*(T-1+j) + sum_l F_l x(T+j-l)
*   lower bound on interest rates     <- Toolbox forecast_GVAR.m, x_lb block
*       trIR = (1/freq)*log(1 + Rmin/100)
*   conditional forecast              <- Toolbox con_forecast_GVAR.m
*       mu_s(h) = mu(h) + Omega(h,.) Psi' (Psi Omega Psi')^-1 vec(g)
*
* The bound is stated in PER-ANNUM PERCENT and converted into the units the
* rates are held in, because the Toolbox builds r as (1/freq)*log(1+R/100).
* Passing 0.25 straight through would floor the quarterly series at 25 basis
* points per quarter rather than per year.

program define _gvar_forecast, rclass
    version 14.0

    syntax [,                                   ///
        STEP(integer 8)                         ///
        VARiables(string)                       ///
        BOUND(string)                           ///
        RMIN(real 0.25)                         ///
        NOBound                                 ///
        CONDition(string)                       ///
        BANDs(numlist >0 <100 sort)             ///
        VCOV(string)                            ///
        SHRINK                                  ///
        LAMbda(real -1)                         ///
        EVALuate                                ///
        HOLDout(integer 0)                      ///
        BGVAR                                   ///
        GRaph                                   ///
        FAN                                     ///
        NAME(string)                            ///
        noSUMmary                               ///
        SAVing(name)                            ///
    ]

    _gvar_require solve

    * ---- hold-out evaluation, which bypasses everything else --------------
    if ("`evaluate'" != "" | `holdout' > 0) {
        if (`holdout' <= 0) {
            di as err "evaluate needs {bf:holdout(#)}: the number of final"
            di as err "observations to set aside and forecast."
            exit 198
        }
        if ("`condition'" != "") {
            di as err "condition() cannot be combined with evaluate"
            di as err "A conditional forecast uses information from the very"
            di as err "period it is meant to predict, so it is not an" ///
                      " out-of-sample"
            di as err "forecast and cannot be scored as one."
            exit 198
        }
        if (`step' < 1) {
            di as err "step() must be at least 1"
            exit 198
        }
        _gvar_shrinkopt 0 0 "`vcov'" "`shrink'" "`lambda'"
        local vmeth "`r(vmeth)'"
        local vexcl "`r(vexcl)'"
        local shr   "`r(shr)'"
        local lam   "`r(lam)'"
        _gvar_fc_eval `holdout' `step' `"`variables'"' `vmeth' `vexcl' ///
                      `shr' "`lam'" "`bgvar'" "`summary'" ///
                      "`graph'" "`name'" "`saving'"
        return add
        exit
    }

    if (`step' < 1) {
        di as err "step() must be at least 1"
        exit 198
    }

    mata: st_local("K",    strofreal(gvar_getK()))
    mata: st_local("freq", strofreal(gvar_getfreq()))
    mata: st_local("xn",   invtokens(gvar_getxname()'))
    mata: st_local("xl",   gvar_getxlabels())

    * ---- the lower bound ---------------------------------------------------
    tempname LB
    matrix `LB' = J(`K', 1, .)
    local nb 0
    local trir .
    if ("`nobound'" == "") {
        if ("`bound'" == "") {
            * the Toolbox's default: short and long rates, where present
            local bound "r lr"
        }
        if (`freq' <= 0) {
            di as err "the data frequency is unknown; use {bf:nobound}"
            exit 198
        }
        local trir = (1 / `freq') * ln(1 + `rmin' / 100)
        foreach v of local bound {
            forvalues j = 1/`K' {
                local vj : word `j' of `xn'
                if ("`vj'" == "`v'") {
                    matrix `LB'[`j', 1] = `trir'
                    local ++nb
                }
            }
        }
    }

    * ---- conditional path ---------------------------------------------------
    tempname D
    local hr 0
    if ("`condition'" != "") {
        _gvar_forecast_cond `K' "`condition'" "`xl'" `step'
        matrix `D' = r(D)
        local hr = colsof(`D')
        local ncon = r(ncon)
    }

    * ---- compute ------------------------------------------------------------
    tempname F
    if (`hr' > 0) {
        mata: st_matrix("`F'", gvar_confcastrun(`step', st_matrix("`D'")))
    }
    else {
        mata: st_matrix("`F'", gvar_forecastrun(`step', st_matrix("`LB'")))
    }

    * ---- which variables to report -----------------------------------------
    if ("`variables'" == "") local variables "*:y"
    _gvar_xsel "`variables'"
    local vpos "`r(pos)'"
    local vlab "`r(labels)'"
    local nv = r(n)

    tempname R
    matrix `R' = J(`step', `nv', .)
    local c 0
    foreach j of local vpos {
        local ++c
        forvalues t = 1/`step' {
            matrix `R'[`t', `c'] = `F'[`j', `t']
        }
    }

    * ---- forecast standard errors and interval bands -----------------------
    * Omega(h) = sum_{j<h} Phi_j Sigma_eta Phi_j' is the forecast-error
    * covariance the Toolbox accumulates in con_forecast_GVAR.m as
    * sm = sm + Cfi*covmtx*Cfi'.  Its square root gives the fan.
    *
    * These are the bands implied by the estimated system treated as known;
    * they do NOT include parameter uncertainty.  gvar irf, reps() bootstraps
    * that for the responses, and the same caveat is printed below.
    _gvar_shrinkopt 0 0 "`vcov'" "`shrink'" "`lambda'"
    local vmeth "`r(vmeth)'"
    local vexcl "`r(vexcl)'"
    local shr   "`r(shr)'"
    local lam   "`r(lam)'"

    if ("`bands'" == "") local bands 68 90
    local nband : word count `bands'

    tempname SE
    mata: st_matrix("`SE'", gvar_fcsd(`step', `vmeth', `vexcl', `shr', `lam'))

    * lower and upper limits, one pair of matrices per requested band, laid
    * out like R so the table and the fan read from the same object
    local bi 0
    foreach bw of local bands {
        local ++bi
        tempname RL`bi' RU`bi'
        local z = invnormal(1 - (1 - `bw' / 100) / 2)
        matrix `RL`bi'' = J(`step', `nv', .)
        matrix `RU`bi'' = J(`step', `nv', .)
        local c 0
        foreach j of local vpos {
            local ++c
            forvalues t = 1/`step' {
                local pv = `R'[`t', `c']
                local sv = `SE'[`j', `t']
                if (`sv' < .) {
                    matrix `RL`bi''[`t', `c'] = `pv' - `z' * `sv'
                    matrix `RU`bi''[`t', `c'] = `pv' + `z' * `sv'
                }
            }
        }
        * a floored variable cannot have a band below its floor
        if (`nb' > 0 & `trir' < .) {
            local c 0
            foreach j of local vpos {
                local ++c
                if (`LB'[`j', 1] < .) {
                    forvalues t = 1/`step' {
                        if (`RL`bi''[`t', `c'] < `LB'[`j', 1]) {
                            matrix `RL`bi''[`t', `c'] = `LB'[`j', 1]
                        }
                    }
                }
            }
        }
    }

    * ---- display -------------------------------------------------------------
    if ("`summary'" != "nosummary") {
        local ttl "Ex-ante forecasts from the solved GVAR"
        if (`hr' > 0) local ttl "Conditional forecasts from the solved GVAR"
        _gvar_title "`ttl'"
        di as text "  Horizon " as result `step' as text " periods beyond the" ///
                   " end of the estimation sample."
        if (`hr' > 0) {
            di as text "  " as result `ncon' as text " restriction(s) imposed" ///
                       " over the first " as result `hr' as text " period(s)."
            di as text "  Beyond that the conditioning still moves the path," ///
                       " through the"
            di as text "  cross-horizon covariance; it is not switched off."
        }
        else if (`nb' > 0) {
            di as text "  Lower bound of " as result %5.2f `rmin' ///
                       as text "% per annum applied to " as result `nb' ///
                       as text " interest-rate series"
            di as text "  (" as result %9.6f `trir' as text " in the units the" ///
                       " model holds them in, = (1/" as result `freq' ///
                       as text ")*ln(1+" as result %4.2f `rmin' as text "/100))."
        }
        else {
            di as text "  No lower bound applied."
        }
        di ""

        * With a band under every point forecast the columns have to be wide
        * enough for "[-12.345,-12.345]", so they widen and fewer fit per
        * block.  A forecast in levels can be 4.7150, unlike an impulse
        * response, so the narrow layout used elsewhere does not do here.
        local cw 11
        local per 7
        if (`nband' > 0) {
            local cw 17
            local per 4
        }
        local done 0
        while (`done' < `nv') {
            local lo = `done' + 1
            local hi = min(`done' + `per', `nv')
            local w = 10 + `cw' * (`hi' - `lo' + 1)
            di as text "{hline `w'}"
            di as text %-9s "  period" _continue
            forvalues c = `lo'/`hi' {
                local l : word `c' of `vlab'
                _gvar_ablab "`l'" `=`cw'-1'
                di as text %`cw's "`_ablab'" _continue
            }
            di ""
            di as text "{hline `w'}"
            forvalues t = 1/`step' {
                di as text "  +" %-6.0f `t' _continue
                forvalues c = `lo'/`hi' {
                    di as result %`cw'.4f `=`R'[`t', `c']' _continue
                }
                di ""
                * the widest requested band, printed under the point forecast.
                * The bracket string is built into a local first: -display-
                * cannot be handed "a" + f(b) directly, because it reads the
                * leading + as part of a function name.
                if (`nband' > 0) {
                    di as text %-9s "" _continue
                    forvalues c = `lo'/`hi' {
                        local lv = `RL`nband''[`t', `c']
                        local uv = `RU`nband''[`t', `c']
                        local bs ""
                        if (`lv' < . & `uv' < .) {
                            local bs = "[" + strtrim(string(`lv', "%7.4f")) ///
                                       + "," + strtrim(string(`uv', "%7.4f")) ///
                                       + "]"
                        }
                        di as text %`cw's "`bs'" _continue
                    }
                    di ""
                }
            }
            di as text "{hline `w'}"
            di ""
            local done = `hi'
        }
        local widest : word `nband' of `bands'
        di as text "  Brackets give the " as result `widest' as text ///
           "% interval implied by Omega(h), the"
        di as text "  forecast-error covariance sum_{j<h} Phi_j Sigma_eta" ///
                   " Phi_j'."
        di as text "  It treats the estimated system as {bf:known}, so it is" ///
                   " the uncertainty"
        di as text "  from future shocks only -- parameter uncertainty is not" ///
                   " in it and"
        di as text "  the true interval is wider."
        if (`nb' > 0) {
            di as text "  The lower limit of a floored series is held at its" ///
                       " floor."
        }
        di as text "  Forecasts are in the units of the model: the variables"
        di as text "  are already logged where the source data were logged,"
        di as text "  so differences are approximate growth rates."
        di ""
    }

    if ("`graph'" != "" | "`fan'" != "") {
        local fanargs ""
        forvalues bi = 1/`nband' {
            local fanargs "`fanargs' `RL`bi'' `RU`bi''"
        }
        _gvar_forecast_graph `R' `step' `nv' "`vlab'" "`name'" ///
                             `nband' "`bands'" "`fan'" `fanargs'
    }

    if ("`saving'" != "") {
        matrix `saving' = `R'
    }
    return matrix forecast = `R', copy
    return matrix full     = `F', copy
    return matrix se       = `SE', copy
    return matrix lower    = `RL`nband'', copy
    return matrix upper    = `RU`nband'', copy
    return scalar step     = `step'
    return scalar nbound   = `nb'
    return local  bands    "`bands'"
    return local  variables "`vlab'"
    if (`trir' < .) return scalar bound = `trir'
end

* ---------------------------------------------------------------------------
* Parse condition(usa:r = 0.001 0.001 0.002 ; euro:y = 0.01)
* into the K x H_bar matrix con_forc_restr_mtx, missing where free.
* ---------------------------------------------------------------------------
program define _gvar_forecast_cond, rclass
    version 14.0
    args K spec xl step

    local ncon 0
    local hmax 0
    local nblk 0
    local rest "`spec'"
    while ("`rest'" != "") {
        local semi = strpos("`rest'", ";")
        if (`semi' == 0) {
            local blk = trim("`rest'")
            local rest ""
        }
        else {
            local blk  = trim(substr("`rest'", 1, `semi' - 1))
            local rest = trim(substr("`rest'", `semi' + 1, .))
        }
        if ("`blk'" == "") continue
        local ++nblk

        local eq = strpos("`blk'", "=")
        if (`eq' == 0) {
            di as err "condition(): each block needs {bf:unit:variable = values}"
            di as err "offending block: {bf:`blk'}"
            exit 198
        }
        local lhs`nblk' = trim(substr("`blk'", 1, `eq' - 1))
        local rhs`nblk' = trim(substr("`blk'", `eq' + 1, .))
        local nvals : word count `rhs`nblk''
        if (`nvals' > `hmax') local hmax = `nvals'
    }

    if (`hmax' > `step') {
        di as err "condition() gives `hmax' period(s) but step() is `step'"
        exit 198
    }

    tempname D
    matrix `D' = J(`K', `hmax', .)
    forvalues b = 1/`nblk' {
        _gvar_xsel "`lhs`b''"
        if (r(n) != 1) {
            di as err "condition(): {bf:`lhs`b''} must select one element," ///
                      " not `=r(n)'"
            exit 198
        }
        local p = r(pos)
        local t 0
        foreach val of local rhs`b' {
            local ++t
            capture confirm number `val'
            if (_rc) {
                di as err "condition(): {bf:`val'} is not a number"
                exit 198
            }
            matrix `D'[`p', `t'] = `val'
            local ++ncon
        }
    }

    return matrix D = `D'
    return scalar ncon = `ncon'
    return scalar hbar = `hmax'
end

* ---------------------------------------------------------------------------
* Fan chart: the point forecast with one shaded band per requested coverage,
* widest at the back.  One panel per variable.
*
* The bands come from Omega(h) and so widen with the square root of the
* accumulated multipliers -- the classic fan.  A variable whose fan does not
* widen is one whose forecast error does not accumulate, which for a series in
* levels means it is being pulled back by a cointegrating relation.
* ---------------------------------------------------------------------------
program define _gvar_forecast_graph
    version 14.0
    * NOT args.  args assigns exactly one token per name, so the
    * variable-length tail RL1 RU1 RL2 RU2 ... could never arrive:
    * naming 0 in the list gave it a single token instead of the
    * remainder of the line.  gettoken peels the fixed arguments off
    * and leaves the rest in 0, which is what the band loop below
    * reads.
    gettoken R     0 : 0
    gettoken step  0 : 0
    gettoken nv    0 : 0
    gettoken vlab  0 : 0
    gettoken gname 0 : 0
    gettoken nband 0 : 0
    gettoken bands 0 : 0
    gettoken fan   0 : 0

    if ("`gname'" == "") local gname gvar_forecast
    if ("`nband'" == "") local nband 0

    _gvar_palette
    local reg  "`r(region)'"
    local c1   "`r(c1)'"
    local grid "`r(grid)'"
    local creg "graphregion(color(white)) plotregion(color(white) lcolor(none))"
    * successively lighter fills, widest band palest
    local f1 "`r(h5)'"
    local f2 "`r(h4)'"
    local f3 "`r(h3)'"
    local f4 "`r(h2)'"

    * the remaining arguments are RL1 RU1 RL2 RU2 ... in band order
    local blo ""
    local bhi ""
    forvalues b = 1/`nband' {
        gettoken a 0 : 0
        gettoken c 0 : 0
        local blo "`blo' `a'"
        local bhi "`bhi' `c'"
    }

    preserve
    local plots ""
    quietly {
        forvalues c = 1/`nv' {
            local l : word `c' of `vlab'
            clear
            set obs `step'
            gen int    period = _n
            gen double fc     = .
            forvalues t = 1/`step' {
                replace fc = `R'[`t', `c'] in `t'
            }
            * widest band first so the narrower ones draw on top
            local layers ""
            forvalues b = `nband'(-1)1 {
                local ml : word `b' of `blo'
                local mu : word `b' of `bhi'
                capture confirm matrix `ml'
                if (_rc) continue
                gen double lo`b' = .
                gen double hi`b' = .
                forvalues t = 1/`step' {
                    replace lo`b' = `ml'[`t', `c'] in `t'
                    replace hi`b' = `mu'[`t', `c'] in `t'
                }
                local fc_ "`f`b''"
                if ("`fc_'" == "") local fc_ "`f4'"
                local layers `"`layers' (rarea hi`b' lo`b' period, color("`fc_'") lwidth(none))"'
            }
            local gn "_gvfan`c'"
            twoway `layers'                                                 ///
                   (line fc period, lcolor("`c1'") lwidth(medthick))        ///
                   , `reg'                                                  ///
                     ylabel(, angle(0) labsize(vsmall) grid                 ///
                            glcolor("`grid'"))                              ///
                     xlabel(1(1)`step', labsize(vsmall))                    ///
                     ytitle("") xtitle("")                                  ///
                     title("`l'", size(small) color(black))                 ///
                     legend(off) name(`gn', replace) nodraw
            local plots "`plots' `gn'"
        }
    }
    restore

    local np : word count `plots'
    local cols 2
    if (`np' == 1) local cols 1
    if (`np' > 6)  local cols 3

    local bl ""
    foreach b of local bands {
        local bl "`bl' `b'%"
    }
    graph combine `plots', cols(`cols') `creg'                              ///
        title("Ex-ante forecasts", size(medsmall) color(black))             ///
        note("shaded:`bl' intervals from Omega(h), the forecast-error"       ///
             " covariance"                                                   ///
             "parameter uncertainty is NOT included, so the true fan is"     ///
             " wider"                                                        ///
             "horizontal axis: periods beyond the estimation sample",        ///
             size(vsmall) color(black))                                     ///
        name(`gname', replace)

    foreach g of local plots {
        capture graph drop `g'
    }
    di as text "  graph saved as {bf:`gname'}"
end

* ---------------------------------------------------------------------------
* Recursive out-of-sample forecast evaluation.
*
* For each of the last holdout() forecast origins every country model is
* re-estimated on the data up to that origin only, the GVAR is re-solved, and
* it forecasts forward.  Nothing after an origin enters the estimation that
* produced its forecast.
*
* Rolling the origin, rather than making one split, is what gives H forecasts
* at each horizon -- enough to average, and enough for a Diebold-Mariano test
* to mean anything.  It costs holdout() full re-estimations.
*
* Step -> source map
*   log predictive score      <- BGVAR predict.R lps(), with the frequentist
*                                forecast-error variance in place of the
*                                posterior predictive one
*   forecast-error variance   <- Toolbox con_forecast_GVAR.m omega_Hbar_tilda
*   per-cell absolute error   <- BGVAR predict.R rmse(), which despite its
*                                name returns sqrt((y-yhat)^2) with no mean
*   RMSE, MAE, bias, Theil U, Diebold-Mariano
*                                standard; not in any of the three sources.
*                                The benchmark is the no-change forecast.
* ---------------------------------------------------------------------------
program define _gvar_fc_eval, rclass
    version 14.0
    args H hmax variables vmeth vexcl shr lam bgvar summary graph name saving

    mata: st_local("K",  strofreal(gvar_getK()))
    mata: st_local("T",  strofreal(gvar_getT()))

    if (`H' >= `T' - 20) {
        di as err "holdout(`H') leaves too little to estimate on"
        di as err "The sample has `T' observations, and the earliest origin"
        di as err "would be `=`T'-`H''."
        exit 198
    }
    if (`hmax' > `H') {
        di as text "  {bf:note}: step(`hmax') exceeds holdout(`H'), so the" ///
                   " longest horizons"
        di as text "  are scored at fewer origins than the shortest.  The" ///
                   " origins column"
        di as text "  in the table below says how many each one had."
    }

    di as text "  recursive evaluation: " as result `H' as text ///
       " origin(s) from " as result `=`T'-`H'' as text " to " ///
       as result `=`T'-1' as text ","
    di as text "  each a full re-estimation of every country model ..."

    mata: gvar_evalwrap(`H', `hmax', `vmeth', `vexcl', `shr', `lam')
    local nori = r_nori
    local nbad = r_nbad
    if (`nori' == 0) {
        di as err "no forecast origin could be estimated"
        di as err "Shorten {bf:holdout()}, or the lag orders."
        exit 498
    }
    tempname E
    matrix `E' = r_eval

    * ---- which variables to report -----------------------------------------
    if (`"`variables'"' == "") local variables "*:y"
    _gvar_xsel `"`variables'"'
    local vpos "`r(pos)'"
    local vlab "`r(labels)'"
    local nv = r(n)

    tempname VP S
    matrix `VP' = J(`nv', 1, .)
    local c 0
    foreach j of local vpos {
        local ++c
        matrix `VP'[`c', 1] = `j'
    }
    mata: st_matrix("`S'", gvar_evaltab(st_matrix("`E'"), ///
                                        st_matrix("`VP'"), `hmax'))
    local nr = rowsof(`S')

    * ---- display -----------------------------------------------------------
    if ("`summary'" != "nosummary") {
        _gvar_title "Recursive out-of-sample forecast evaluation"
        di as text "  " as result `nori' as text " forecast origin(s)" _continue
        if (`nbad' > 0) {
            di as text ", " as result `nbad' as text " could not be estimated."
        }
        else {
            di as text "."
        }
        di as text "  Horizons 1 to " as result `hmax' ///
           as text ".  Benchmark: the no-change forecast."
        di ""
        di as text "{hline 92}"
        di as text %-14s "  variable" _col(16) "h" _col(22) "n" ///
           _col(31) "RMSE" _col(43) "MAE" _col(55) "bias" ///
           _col(66) "Theil U" _col(77) "LPS" _col(87) "DM"
        di as text "{hline 92}"
        local lastv .
        forvalues q = 1/`nr' {
            local jj = `S'[`q', 1]
            local hh = `S'[`q', 2]
            local iv : list posof "`jj'" in vpos
            local l : word `iv' of `vlab'
            if ("`jj'" != "`lastv'") {
                _gvar_ablab "`l'" 12
                di as text "  " %-12s "`_ablab'" _continue
                local lastv "`jj'"
            }
            else {
                di as text "  " %-12s "" _continue
            }
            local st ""
            if (`S'[`q', 11] < .) {
                _gvar_stars `=`S'[`q',11]'
                local st "`r(stars)'"
            }
            di as text _col(15) as result %3.0f `hh' ///
               _col(19) as result %5.0f `=`S'[`q',3]' ///
               _col(25) as result %11.5f `=`S'[`q',4]' ///
               _col(37) as result %11.5f `=`S'[`q',5]' ///
               _col(49) as result %11.5f `=`S'[`q',6]' ///
               _col(62) as result %10.4f `=`S'[`q',8]' ///
               _col(73) as result %9.3f  `=`S'[`q',9]' ///
               _col(83) as result %8.2f  `=`S'[`q',10]' as text "`st'"
        }
        di as text "{hline 92}"
        di as text "  {bf:n} is the number of origins at which that horizon" ///
                   " could be scored."
        di as text "  {bf:Theil U} < 1 means the GVAR beat the no-change" ///
                   " forecast, > 1 that it lost."
        di as text "  {bf:LPS} is the mean log predictive score; higher is" ///
                   " better.  It rewards a"
        di as text "  forecast for being well calibrated as well as close," ///
                   " so a model can win"
        di as text "  on RMSE and lose on LPS by being overconfident."
        di as text "  {bf:DM} is Diebold-Mariano against the no-change" ///
                   " forecast, NEGATIVE favouring"
        di as text "  the GVAR, with a Newey-West variance at lag h-1 and the"
        di as text "  Harvey-Leybourne-Newbold small-sample correction."
        di as text "  * 10%  ** 5%  *** 1%"
        di ""
        di as text "  Two things to keep in mind before reading a DM" ///
                   " star as a result:"
        di as text "  with " as result `nori' as text " origins the test has" ///
                   " little power, and successive origins"
        di as text "  share most of their estimation sample, so they are far" ///
                   " from independent."
        di ""
        di as text "  The predictive variance treats the estimated system as" ///
                   " known, so the LPS"
        di as text "  is optimistic about calibration.  It is Omega(h), the" ///
                   " Toolbox's own"
        di as text "  forecast-error covariance from con_forecast_GVAR.m."
        if ("`bgvar'" != "") {
            di ""
            di as text "  {bf:bgvar}: the MAE column is what BGVAR's" ///
                       " rmse() returns, namely"
            di as text "  sqrt((y - yhat)^2) averaged over origins.  Its" ///
                       " name notwithstanding,"
            di as text "  that function contains no mean and no square root" ///
                       " of a mean."
        }
        di ""
    }

    if ("`graph'" != "") {
        _gvar_eval_graph `S' `nr' `hmax' "`vpos'" "`vlab'" "`name'"
    }
    if ("`saving'" != "") {
        matrix `saving' = `S'
    }

    return matrix eval    = `S', copy
    return matrix detail  = `E', copy
    return scalar origins = `nori'
    return scalar failed  = `nbad'
    return scalar holdout = `H'
    return scalar nvars   = `nv'
end

* ---------------------------------------------------------------------------
* RMSE against the no-change benchmark, by horizon, one panel per variable.
* The reference line at one is where the GVAR stops beating a random walk.
* ---------------------------------------------------------------------------
program define _gvar_eval_graph
    version 14.0
    args S nr hmax vpos vlab name

    _gvar_palette
    local c1   "`r(c1)'"
    local c2   "`r(c2)'"
    local grid "`r(grid)'"
    local reg  "`r(region)'"
    local zero "`r(zero)'"
    local creg "graphregion(color(white)) plotregion(color(white) lcolor(none))"

    local nm "gvar_eval"
    if ("`name'" != "") local nm "`name'"

    preserve
    local plots ""
    local w 0
    quietly {
        foreach j of local vpos {
            local ++w
            local l : word `w' of `vlab'
            clear
            set obs `hmax'
            gen int    h     = _n
            gen double theil = .
            forvalues q = 1/`nr' {
                if (`S'[`q', 1] == `j') {
                    local hh = `S'[`q', 2]
                    replace theil = `S'[`q', 8] in `hh'
                }
            }
            local gn "_gvev`w'"
            twoway (line theil h, lcolor("`c1'") lwidth(medthick))          ///
                   (scatter theil h, msymbol(o) msize(small)                ///
                        mcolor("`c1'"))                                     ///
                   , `reg'                                                  ///
                     yline(1, lcolor("`c2'") lpattern(dash) lwidth(thin))   ///
                     ylabel(, angle(0) labsize(vsmall) grid                 ///
                            glcolor("`grid'"))                              ///
                     xlabel(1(1)`hmax', labsize(vsmall))                    ///
                     ytitle("") xtitle("")                                  ///
                     title("`l'", size(small) color(black))                 ///
                     legend(off) name(`gn', replace) nodraw
            local plots "`plots' `gn'"
        }
    }
    restore

    local np : word count `plots'
    local cols 2
    if (`np' == 1) local cols 1
    if (`np' > 6)  local cols 3

    graph combine `plots', cols(`cols') `creg'                              ///
        title("Forecast accuracy against a random walk",                    ///
              size(medsmall) color(black))                                  ///
        note("Theil's U by horizon; below the dashed line the GVAR wins"     ///
             "horizontal axis: forecast horizon in periods",                 ///
             size(vsmall) color(black))                                     ///
        name(`nm', replace)

    foreach g of local plots {
        capture graph drop `g'
    }
    di as text "  graph saved as {bf:`nm'}"
end
