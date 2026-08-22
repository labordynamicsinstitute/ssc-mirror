*! _gvar_bfore 1.0.1  21aug2026
*! gvar bforecast -- the predictive density over the retained draws.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Inventory section 12, the Bayesian counterpart of gvar forecast.
* BGVAR R/predict.R.
*
* Why this exists.  gvar forecast's bands come from
*     Omega(h) = sum_{j<h} Phi_j Sigma_eta Phi_j'
* with the estimated system treated as KNOWN, so they carry no parameter
* uncertainty at all.  Integrating over the draws adds it, and that is the one
* thing the Bayesian branch offers here that the ML path cannot.
*
* Step -> source map
*   per-draw mean path                  <- gvar_forecast, shared with
*                                          gvar forecast so the two agree
*   Sigma_eta = G0^-1 Sigma_zeta G0^-1' <- predict.R Sig_t
*   Sigma_zeta blockdiag over units     <- predict.R S_large
*   Omega(h) cumulative                 <- predict.R Sigma00
*   marginal draw per horizon           <- predict.R yf
*
* TWO DEFECTS IN predict.R ARE CORRECTED, not reproduced; see gvar_bfcrun in
* _gvar_mata.ado and _INVENTORY.md 29-31.  BGVAR freezes the trend at its last
* in-sample value and starts the state a period early, so its horizon 1 is the
* fitted value at T.

program define _gvar_bfore, rclass
    version 14.0

    syntax [,                                   ///
        VARiables(string)                       ///
        STEP(integer 8)                         ///
        BANDs(numlist >0 <100 sort)             ///
        GRaph                                   ///
        FAN                                     ///
        NAME(string)                            ///
        noSUMmary                               ///
        SAVing(name)                            ///
    ]

    * A chain, and a solved system to stack the draws into.
    _gvar_require solve
    capture mata: st_local("hb", strofreal(gvar_hasbayes()))
    if (_rc | "`hb'" != "1") {
        di as err "there is no sampled chain in memory; run {bf:gvar bayes}"
        di as err "first.  This command integrates over the retained draws, so"
        di as err "there is nothing for it to do after {bf:gvar estimate} --"
        di as err "use {bf:gvar forecast} for that."
        exit 301
    }

    if (`step' < 1) {
        di as err "step() must be at least 1"
        exit 198
    }

    if ("`bands'" == "") local bands 68 90
    local nband : word count `bands'

    * Quantile list, symmetric around the median, low ends then high ends so the
    * table reads left to right.  The WIDEST band therefore occupies the first
    * and last quantile columns, which is what the graph and _test48.do assume.
    local qlo ""
    local qhi ""
    local bi = `nband'
    while (`bi' >= 1) {
        local bw : word `bi' of `bands'
        local a = (100 - `bw') / 200
        local qlo "`qlo' `a'"
        local --bi
    }
    forvalues bi = 1/`nband' {
        local bw : word `bi' of `bands'
        local a = 1 - (100 - `bw') / 200
        local qhi "`qhi' `a'"
    }
    local qs = trim(itrim("`qlo' 0.5 `qhi'"))
    local nq : word count `qs'

    * ---- which variables ---------------------------------------------------
    mata: st_local("K",  strofreal(gvar_getK()))
    mata: st_local("xn", invtokens(gvar_getxname()'))
    if ("`variables'" == "") {
        di as err "variables() is required: name the element(s) of the global"
        di as err "vector to forecast, as {bf:unit:variable}.  A predictive"
        di as err "density over all `K' variables would be a table nobody reads;"
        di as err "the system is solved jointly either way."
        exit 198
    }
    * _gvar_xsel is the resolver every other command uses; it takes
    * unit:variable with * wildcards and returns r(pos).  Reusing it means
    * variables(usa:y) means the same thing here as in gvar hd and gvar fevd.
    _gvar_xsel "`variables'"
    local sel  "`r(pos)'"
    local nsel = r(n)
    if (`nsel' == 0) {
        di as err "variables() selected nothing.  Give it as {bf:unit:variable},"
        di as err "e.g. {bf:variables(usa:y)}; {bf:gvar describe} lists the"
        di as err "names in order."
        exit 198
    }

    tempname SEL
    matrix `SEL' = J(`nsel', 1, .)
    local j 0
    foreach s of local sel {
        local ++j
        matrix `SEL'[`j', 1] = `s'
    }

    mata: st_local("nd", strofreal(gvar_getbdraws()))
    if ("`summary'" != "nosummary") {
        di as text "  integrating over " as result `nd' as text ///
           " draw(s): stacking and forecasting each ..."
    }

    * The quantiles go down as a MATRIX, not spliced into a Mata row-vector
    * literal.  Building "(`=subinstr(...)')" from the local produced
    * "(,0.05,0.16,...)" -- a leading space in the accumulated list became a
    * leading comma -- and Mata answered "expression invalid", rc 3000.  A
    * matrix has no such failure mode, and SEL already went down this way.
    tempname QS BF
    matrix `QS' = J(1, `nq', .)
    local j 0
    foreach q of local qs {
        local ++j
        matrix `QS'[1, `j'] = `q'
    }
    mata: st_matrix("`BF'", gvar_bfcrun(`step', st_matrix("`SEL'"), ///
                                        st_matrix("`QS'")))

    * ---- report -------------------------------------------------------------
    mata: st_local("xl", gvar_getxlabels())
    if ("`summary'" != "nosummary") {
        _gvar_title "Predictive density"
        di as text "  Draws used            " as result %8.0f `nd'
        di as text "  Horizons              " as result %8.0f `step'
        di as text "  Bands                 " as result "`bands'" as text " %"
        di ""
        di as text "  Each draw is stacked and solved on its own, so the"
        di as text "  interval carries {bf:parameter uncertainty} as well as"
        di as text "  shock uncertainty.  {bf:gvar forecast} carries only the"
        di as text "  second -- its bands treat the estimated system as known --"
        di as text "  so these are wider, and that difference is the point."
        di ""
        di as text "  {bf:Not sample paths.}  Each horizon is drawn from its own"
        di as text "  marginal predictive, so a row is correct for the interval"
        di as text "  at that horizon and must not be read as a trajectory."
        di ""

        local wid : word 1 of `bands'
        local wid : word `nband' of `bands'
        forvalues j = 1/`nsel' {
            local ix : word `j' of `sel'
            local nm : word `ix' of `xl'
            di as text "  {hline 60}"
            di as text "  " as result "`nm'"
            di as text "  {hline 60}"
            di as text "  " %6s "h" %14s "mean" %14s "median" ///
               %12s "lower" %12s "upper"
            forvalues h = 1/`step' {
                local r = (`j' - 1) * `step' + `h'
                local mn = `BF'[`r', 3]
                local md = `BF'[`r', `=3 + (`nq' + 1) / 2']
                local lo = `BF'[`r', 4]
                local up = `BF'[`r', `=3 + `nq'']
                di as text "  " %6.0f `h' as result %14.5f `mn' ///
                   %14.5f `md' %12.5f `lo' %12.5f `up'
            }
            di as text "  {hline 60}"
            di as text "  lower and upper are the " as result "`wid'" ///
               as text "% band"
            di ""
        }
    }

    if ("`graph'" != "") {
        _gvar_bfore_graph `BF' `step' `nsel' "`sel'" "`xl'" `nq' ///
                          "`bands'" "`fan'" "`name'"
    }

    if ("`saving'" != "") {
        preserve
        qui _gvar_bfore_data `BF' `step' `nsel' "`sel'" "`xl'" `nq'
        qui save "`saving'", replace
        restore
        if ("`summary'" != "nosummary") {
            di as text "  saved to " as result "`saving'.dta"
        }
    }

    return matrix table = `BF'
    return scalar draws = `nd'
    return scalar step  = `step'
    return local  bands  "`bands'"
    return local  quantiles "`qs'"
    return local  varlist "`variables'"
end

* ---------------------------------------------------------------------------
* The table as a dataset, one row per (variable, horizon).
* ---------------------------------------------------------------------------
program define _gvar_bfore_data
    version 14.0
    args BF step nsel sel xl nq

    qui clear
    qui set obs `=`nsel' * `step''
    qui gen str32  variable = ""
    qui gen int    horizon  = .
    qui gen double mean     = .
    qui gen double median   = .
    qui gen double lower    = .
    qui gen double upper    = .
    forvalues j = 1/`nsel' {
        local ix : word `j' of `sel'
        local nm : word `ix' of `xl'
        forvalues h = 1/`step' {
            local r = (`j' - 1) * `step' + `h'
            qui replace variable = "`nm'"                      in `r'
            qui replace horizon  = `h'                         in `r'
            qui replace mean     = `BF'[`r', 3]                in `r'
            qui replace median   = `BF'[`r', `=3+(`nq'+1)/2']  in `r'
            qui replace lower    = `BF'[`r', 4]                in `r'
            qui replace upper    = `BF'[`r', `=3+`nq'']        in `r'
        }
    }
end

* ---------------------------------------------------------------------------
* Fan chart, one panel per variable.  Light fills, as everywhere else in the
* package: the shaded band has to sit behind the median without competing
* with it.
* ---------------------------------------------------------------------------
program define _gvar_bfore_graph
    version 14.0
    args BF step nsel sel xl nq bands fan name

    local nb : word count `bands'
    preserve
    qui clear
    qui set obs `step'
    qui gen int _h = _n

    local plots ""
    local nm1 ""
    forvalues j = 1/`nsel' {
        local ix : word `j' of `sel'
        local nm : word `ix' of `xl'
        if (`j' == 1) local nm1 "`nm'"
        qui gen double _md`j' = .
        forvalues b = 1/`nb' {
            qui gen double _lo`j'_`b' = .
            qui gen double _up`j'_`b' = .
        }
        forvalues h = 1/`step' {
            local r = (`j' - 1) * `step' + `h'
            qui replace _md`j' = `BF'[`r', `=3+(`nq'+1)/2'] in `h'
            forvalues b = 1/`nb' {
                * band b outward from the median: column 3+b is the b-th
                * lowest quantile, and the widest band is the outermost pair
                local cl = 3 + `b'
                local cu = 3 + `nq' + 1 - `b'
                qui replace _lo`j'_`b' = `BF'[`r', `cl'] in `h'
                qui replace _up`j'_`b' = `BF'[`r', `cu'] in `h'
            }
        }
    }

    local nm "gvar_bforecast"
    if ("`name'" != "") local nm "`name'"

    * one shade per band, palest outermost
    * The band shades and the median line come from _gvar_palette.  They used to
    * be four literals here -- the three shades were character-for-character the
    * palette's h2/h3/h4, and the median line was a hardcoded "51 102 153" that
    * was darker than the palette's own primary series colour.  Duplicating the
    * palette means this one figure silently stops matching the rest the first
    * time the palette changes.
    _gvar_palette
    local sh1 `"`r(h2)'"'
    local sh2 `"`r(h3)'"'
    local sh3 `"`r(h4)'"'
    local pmed `"`r(c1)'"'

    local gl ""
    forvalues j = 1/`nsel' {
        local ix : word `j' of `sel'
        local vn : word `ix' of `xl'
        local body ""
        forvalues b = 1/`nb' {
            local col : word `b' of "`sh1'" "`sh2'" "`sh3'"
            if ("`col'" == "") local col "`sh3'"
            local body `body' (rarea _up`j'_`b' _lo`j'_`b' _h, ///
                color("`col'") lwidth(none))
        }
        local body `body' (line _md`j' _h, lcolor("`pmed'") lwidth(medthick))
        tempname g`j'
        twoway `body', ///
            title("`vn'", size(medsmall)) ///
            xtitle("horizon") ytitle("") legend(off) ///
            graphregion(color(white)) plotregion(color(white)) ///
            name("`nm'_`j'", replace) nodraw
        local gl `gl' `nm'_`j'
    }

    if (`nsel' == 1) {
        graph display `nm'_1
        capture graph rename `nm'_1 `nm', replace
    }
    else {
        graph combine `gl', ///
            title("Predictive density", size(medium)) ///
            subtitle("`bands'% bands, integrating over the draws", size(small)) ///
            graphregion(color(white)) plotregion(color(white)) ///
            name("`nm'", replace)
    }
    restore
end
