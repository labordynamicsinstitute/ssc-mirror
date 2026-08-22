*! _gvar_hd 1.0.1  21aug2026
*! gvar hd -- historical decomposition of the solved GVAR.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   historical decomposition   <- BGVAR hd.R  (hd.bgvar.irf)
*       solveA = chol(Sigma_u)' R
*       eps    = (Y - X ALPHA') solve(solveA)'
*       HDshock(.,nn,jj) = invA_big e_jj + Fcomp HDshock(.,nn-1,jj)
*       plus constant, trend, initial condition and a leftover slice
*
* hd.R refuses to do this under generalized identification, and so does this
* command:
*   "Historical decomposition of the time series not implemented for GIRFs
*    since cross-correlation is unequal to zero (and hence decompositions do
*    not sum up to original time series)."
* A historical decomposition attributes each movement in the data to ONE
* shock.  Generalized shocks are correlated with each other by construction,
* so the attributions would double count and the pieces would not add back to
* the data.  Use an orthogonal scheme: {bf:first()} plus {bf:vorder()} for a
* Cholesky ordering.

program define _gvar_hd, rclass
    version 14.0

    syntax [,                                   ///
        VARiables(string)                       ///
        FIRST(string)                           ///
        VORDer(string)                          ///
        VCOV(string)                            ///
        SHRINK                                  ///
        LAMbda(real -1)                         ///
        BGVar                                   ///
        SHOCKs(string)                          ///
        TOP(integer 6)                          ///
        PERiods(string)                         ///
        LINEs                                   ///
        FULL                                    ///
        GRaph                                   ///
        NAME(string)                            ///
        noSUMmary                               ///
        SAVing(name)                            ///
    ]

    _gvar_require solve

    mata: st_local("K",  strofreal(gvar_getK()))
    mata: st_local("xl", gvar_getxlabels())

    * ---- the ordering IS the identification --------------------------------
    tempname ORD
    local nord 0
    if ("`first'" != "") {
        _gvar_reorder "`first'" "`vorder'"
        local ordlist "`r(ord)'"
        local nord : word count `ordlist'
        matrix `ORD' = J(`nord', 1, 0)
        local q 0
        foreach z of local ordlist {
            local ++q
            matrix `ORD'[`q', 1] = `z'
        }
    }
    else {
        matrix `ORD' = J(1, 1, 0)
    }
    local ordarg "J(0, 1, 0)"
    if (`nord' > 0) local ordarg `"st_matrix("`ORD'")"'

    * ---- the covariance must be factorable ---------------------------------
    _gvar_shrinkopt 2 `K' "`vcov'" "`shrink'" "`lambda'"
    local vmeth "`r(vmeth)'"
    local vexcl "`r(vexcl)'"
    local shr   "`r(shr)'"
    local lam   "`r(lam)'"

    * ---- compute -------------------------------------------------------------
    tempname H SH
    * align 0 reproduces hd.R exactly, including its off-by-one on the
    * initial-condition block; align 1 starts the recursions where the
    * companion identity requires.
    local align 1
    if ("`bgvar'" != "") local align 0
    mata: st_matrix("`H'", gvar_hdwrap(`vmeth', `vexcl', `shr', `lam', ///
                                       `ordarg', `align'))
    matrix `SH' = r_strshock

    local nblk = rowsof(`H') / `K'
    local T    = colsof(`H')
    local hastr = 0
    if (`nblk' == `=`K'+4') local hastr 1

    * block indices
    local bconst = `K' + 1
    local btrend = 0
    if (`hastr') local btrend = `K' + 2
    local binit  = `K' + 2 + `hastr'
    local bleft  = `K' + 3 + `hastr'

    * ---- which variable to decompose ---------------------------------------
    if ("`variables'" == "") local variables "usa:y"
    _gvar_xsel "`variables'"
    local vpos "`r(pos)'"
    local vlab "`r(labels)'"
    if (r(n) != 1) {
        di as err "variables() must select exactly one element, not `=r(n)'"
        di as err "a historical decomposition is read one series at a time"
        exit 198
    }

    * ---- rank the shocks by their contribution -----------------------------
    tempname CONTRIB
    matrix `CONTRIB' = J(`K', 1, 0)
    mata: st_matrix("`CONTRIB'", gvar_hdcontrib(st_matrix("`H'"), `K', ///
                                                `vpos'))
    if ("`shocks'" != "") {
        _gvar_xsel "`shocks'"
        local spos "`r(pos)'"
        local slab "`r(labels)'"
    }
    else {
        mata: st_local("spos", gvar_ranktop(st_matrix("`CONTRIB'"), `top'))
        local slab ""
        foreach j of local spos {
            local l : word `j' of `xl'
            local slab "`slab' `l'"
        }
        local slab = trim("`slab'")
    }
    local ns : word count `spos'

    * ---- does it add up? ----------------------------------------------------
    mata: st_local("addup", strofreal(gvar_hdcheck(st_matrix("`H'"), ///
                                                   `K', `bleft')))

    if ("`summary'" != "nosummary") {
        _gvar_title "Historical decomposition of `vlab'"
        di as text "  Each observation is split into the cumulated"
        di as text "  contribution of every structural shock, plus the"
        di as text "  deterministic terms and the initial condition."
        if (`nord' > 0) {
            di as text "  Identification: Cholesky, with " ///
                       as result "`first'" as text " ordered first."
        }
        else {
            di as text "  Identification: Cholesky on the model's own" ///
                       " variable order."
            di as text "  See {help gvar_describe:gvar describe, order} for" ///
                       " that order, and set"
            di as text "  a different one with {bf:first()} and {bf:vorder()}."
        }
        di as text "  Largest leftover after summing every piece: " ///
           as result %8.2e `addup' as text "."
        if (`align' == 0) {
            di as text "  {bf:bgvar} reproduces hd.R, whose initial-condition"
            di as text "  block is one application of the companion matrix"
            di as text "  short and which omits the first-period shock and"
            di as text "  constant.  The gap is propagated, not damped, so"
            di as text "  the leftover is large and systematic."
        }
        di ""

        di as text "{hline 74}"
        di as text "  {bf:Average absolute contribution over the sample}"
        di as text "{hline 74}"
        di as text %-22s "  source" _col(28) "mean |contribution|" ///
                   _col(52) "share of total"
        di as text "{hline 74}"

        local tot 0
        forvalues j = 1/`K' {
            local tot = `tot' + `CONTRIB'[`j', 1]
        }
        foreach j of local spos {
            local l : word `j' of `xl'
            local c = `CONTRIB'[`j', 1]
            _gvar_ablab "`l'" 20
            di as text "  " %-20s "`_ablab'"          ///
               _col(30) as result %12.6f `c'                 ///
               _col(54) as result %10.3f `=`c'/max(`tot',1e-30)'
        }
        di as text "{hline 74}"
        di as text "  Ranked by mean absolute contribution to `vlab'."
        di as text "  Shares are of the total across all " as result `K' ///
                   as text " shocks, so they"
        di as text "  exclude the deterministic and initial-condition terms."
        di ""

        * a short time-series view
        if ("`periods'" != "") {
            _gvar_hd_periods `H' `K' "`spos'" "`slab'" `vpos' "`periods'" ///
                             `bconst' `binit' `bleft'
        }
        else {
            di as text "  Add {bf:periods(}{it:numlist}{bf:)} to print the" ///
                       " contributions period by"
            di as text "  period, or {bf:graph} to plot them."
            di ""
        }
    }

    if ("`graph'" != "") {
        _gvar_hd_graph `H' `K' "`spos'" "`slab'" `vpos' `T' "`vlab'" "`name'" ///
                       `top' "`lines'" "`full'"
    }

    if ("`saving'" != "") {
        matrix `saving' = `H'
    }
    return matrix hd = `H', copy
    return matrix strshock = `SH', copy
    return matrix contrib  = `CONTRIB', copy
    return local  variable "`vlab'"
    return local  shocks   "`slab'"
    return scalar leftover = `addup'
    return scalar align    = `align'
    return scalar nblocks  = `nblk'
end

* ---------------------------------------------------------------------------
program define _gvar_hd_periods
    version 14.0
    args H K spos slab vpos periods bconst binit bleft

    local ns : word count `spos'
    local T = colsof(`H')

    local per 5
    local done 0
    while (`done' < `ns') {
        local lo = `done' + 1
        local hi = min(`done' + `per', `ns')
        local w = 10 + 13 * (`hi' - `lo' + 1 + 2)
        di as text "{hline `w'}"
        di as text %-9s "  period" _continue
        forvalues c = `lo'/`hi' {
            local l : word `c' of `slab'
            _gvar_ablab "`l'" 12
            di as text %13s "`_ablab'" _continue
        }
        di as text %13s "determ+init" %13s "TOTAL"
        di as text "{hline `w'}"
        foreach t of local periods {
            if (`t' < 1 | `t' > `T') continue
            di as text "  " %-7.0f `t' _continue
            local sum 0
            forvalues c = `lo'/`hi' {
                local j : word `c' of `spos'
                local row = (`j' - 1) * `K' + `vpos'
                local v = `H'[`row', `t']
                di as result %13.6f `v' _continue
            }
            local rc = (`bconst' - 1) * `K' + `vpos'
            local ri = (`binit'  - 1) * `K' + `vpos'
            local rl = (`bleft'  - 1) * `K' + `vpos'
            local di_ = `H'[`rc', `t'] + `H'[`ri', `t']
            local tt 0
            forvalues j = 1/`K' {
                local rr = (`j' - 1) * `K' + `vpos'
                local tt = `tt' + `H'[`rr', `t']
            }
            local tt = `tt' + `di_' + `H'[`rl', `t']
            di as result %13.6f `di_' %13.6f `tt'
        }
        di as text "{hline `w'}"
        di ""
        local done = `hi'
    }
    di as text "  TOTAL is every piece summed and must equal the observed"
    di as text "  series; that is what the leftover slice guarantees."
    di ""
end
* ---------------------------------------------------------------------------
* Historical decomposition: stacked bars (inventory 13.19).
*
* BGVAR's plot.bgvar draws this as stacked bars, and stacked bars are what the
* picture is for: the bars for one period must add up to the observed value, so
* the eye reads "this much of the move came from that shock".  Overlaid lines
* cannot do that -- six lines crossing zero tell you each series' size and
* nothing about the sum.  The previous version drew lines, which is why this
* was a faithfulness gap and not a matter of taste.
*
* Stata has no stacked bar for a series that changes sign, so the stacking is
* explicit and drawn with rbar: positive contributions accumulate upward from
* zero, negative ones downward, and each rbar spans its own slice of that
* running total.  A decomposition is full of negative contributions, so this
* is the only construction that works.
*
* Two pooled slices exist so the bars cannot lie:
*   other shocks      everything outside top(), summed
*   determ + initial  the constant, the trend when present, the initial
*                     condition and the leftover slice
* With both present the bars sum to the observed series, which is drawn over
* them as a line.  The sum is checked, not assumed, and a gap is reported.
*
* Colours are the eight-colour light qualitative set from _gvar_palette, with
* two greys for the pooled slices so they read as residual rather than as
* another shock.
*
* Step -> source map
*   stacked bars per period       <- BGVAR plot.bgvar
*   observed series drawn on top  <- BGVAR plot.bgvar
*   sign-aware stacking           <- required by Stata having no stacked bar
*                                    that handles negative values
* ---------------------------------------------------------------------------
program define _gvar_hd_graph
    version 14.0
    args H K spos slab vpos T vlab gname top lines full

    if ("`gname'" == "") local gname gvar_hd
    if ("`top'" == "")   local top 6
    if (`top' < 1)       local top 1

    _gvar_palette
    local reg  "`r(region)'"
    local zero "`r(zero)'"
    * The observed series is the PRIMARY series, so it takes the palette's c1.
    * It was lcolor("70 70 70") -- luminance 70, the one genuinely dark colour
    * in the package, against a documented requirement that plots avoid dark
    * colours.  The palette's zero grey (150) is too light to read as a data
    * line over the contribution bars; c1 is the designated primary and is both
    * lighter than 70 and consistent with every other line plot.
    local pobs "`r(c1)'"

    * top() used to be ignored here: the graph hardcoded six however many the
    * caller asked for.  Eight is the palette's limit; with the two pooled
    * slices and the observed line that is eleven legend keys, which is as many
    * as one can read.
    local nsp : word count `spos'
    local ns = min(`nsp', `top', 8)

    local shown ""
    forvalues c = 1/`ns' {
        local z : word `c' of `spos'
        local shown "`shown' `z'"
    }

    * Colours and labels go into NUMBERED locals, never into a list of quoted
    * strings: whether -: word- keeps or strips the quotes around "31 119 180"
    * is exactly the kind of question that should not decide whether a plot
    * draws.
    forvalues c = 1/`ns' {
        local col`c' "`r(c`c')'"
        local lab`c' : word `c' of `slab'
    }
    * The deterministic terms and the initial condition are not shock
    * contributions, and on a log level they are most of the number: drawing
    * them as a slice gave one grey block filling 85% of the height and
    * squashed every shock into a band at zero.  By default they are removed
    * from the line instead of drawn as a slice, so the picture shows what the
    * SHOCKS explain.  full puts them back.
    local col`=`ns'+1' "205 205 205"
    local lab`=`ns'+1' "other shocks"
    local nser = `ns' + 1
    if ("`full'" == "full") {
        local nser = `ns' + 2
        local col`=`ns'+2' "235 235 235"
        local lab`=`ns'+2' "determ + initial"
    }

    preserve
    clear
    qui set obs `T'
    tempname P
    mata: st_matrix("`P'", gvar_hdparts(st_matrix("`H'"), `K', `vpos', ///
                                        strtoreal(tokens("`shown'")), `T'))
    qui svmat double `P', names(p)

    * real dates, not a period index.  The window ends where the data end,
    * so period 1 is tvals[Traw - T + 1]; _gvar_xtime works that out.
    * _gvar_xtime is rclass, so r() is its return list from here on -- the
    * palette values were already read into col1..colN above.  Both returns are
    * copied into locals at once rather than read across an intervening command.
    _gvar_xtime `T'
    local xfmt  "`r(fmt)'"
    local xfmtc "`r(fmtc)'"
    local xlab  "`r(xlab)'"
    local t0    = r(t0)
    qui gen double t = `t0' + _n - 1

    * year-aligned ticks labelled with the year alone.  A %tq label is six
    * characters and eight of them across 35 years print as one run of digits.
    * xlabel() takes ONE comma -- xlabel(rule, suboptions) -- so the rule and
    * the suboptions are kept apart.  Folding format() in beside the rule puts
    * a second comma in the option and Stata reports "invalid 'labsize'".
    local xrule "#8"
    local xsub  "labsize(small)"
    local xt "period"
    if ("`xfmt'" != "") {
        format t `xfmt'
        local xrule "`xlab'"
        local xsub  "format(`xfmtc') labsize(small)"
        local xt ""
    }

    * gvar_hdparts returns, in order: the named shocks, every other shock
    * pooled, the deterministic block, and the observed series.  The
    * deterministic column is always there; whether it is drawn or subtracted
    * is what full decides.
    local pdet "p`=`ns'+2'"
    local praw "p`=`ns'+3'"
    if ("`full'" == "full") {
        local nobs "`praw'"
        local nlab "`vlab' (observed)"
        local sub  "each period's bars sum to the observed series"
    }
    else {
        tempvar netobs
        qui gen double `netobs' = `praw' - `pdet'
        local nobs "`netobs'"
        local nlab "`vlab' net of determ + initial"
        local sub  "bars sum to the series net of deterministic terms and the initial condition"
    }

    * ---- sign-aware stacking ------------------------------------------------
    * cpos and cneg are the running tops of the positive and negative stacks.
    * Each series is placed on whichever side its own sign puts it, period by
    * period, so a shock that changes sign changes side.
    qui gen double cpos = 0
    qui gen double cneg = 0
    forvalues c = 1/`nser' {
        qui gen double lo`c' = .
        qui gen double hi`c' = .
        qui replace lo`c' = cpos       if p`c' >= 0 & p`c' < .
        qui replace hi`c' = cpos + p`c' if p`c' >= 0 & p`c' < .
        qui replace cpos  = cpos + p`c' if p`c' >= 0 & p`c' < .
        qui replace hi`c' = cneg       if p`c' < 0
        qui replace lo`c' = cneg + p`c' if p`c' < 0
        qui replace cneg  = cneg + p`c' if p`c' < 0
    }

    * ---- the bars have to add up, so check it -------------------------------
    tempvar gap
    qui gen double `gap' = abs(cpos + cneg - `nobs')
    qui summarize `gap', meanonly
    local mxgap = r(max)

    * ---- build the plot list and the legend together ------------------------
    local plots ""
    local order ""
    local labopt ""
    forvalues c = 1/`nser' {
        local cc "`col`c''"
        if ("`lines'" == "lines") {
            local one `"(line p`c' t, lcolor("`cc'") lwidth(medthin))"'
        }
        else {
            local one `"(rbar lo`c' hi`c' t, barwidth(1) color("`cc'") lcolor("`cc'") lwidth(vvthin))"'
        }
        local plots  `"`plots' `one'"'
        local order  "`order' `c'"
        local labopt `"`labopt' label(`c' "`lab`c''")"'
    }
    * the observed series last so it draws over the bars
    local k = `nser' + 1
    local plots  `"`plots' (line `nobs' t, lcolor("`pobs'") lwidth(medthick))"'
    local order  "`order' `k'"
    local labopt `"`labopt' label(`k' "`nlab'")"'

    if ("`lines'" == "lines") local sub "contribution of each structural shock"

    twoway `plots' ///
        , `reg' ///
          yline(0, lcolor("`zero'") lpattern(solid) lwidth(thin)) ///
          ylabel(, angle(0) labsize(small) grid glcolor(gs15)) ///
          xlabel(`xrule', `xsub') ///
          xtitle("`xt'", size(small)) ///
          ytitle("contribution", size(small)) ///
          title("Historical decomposition of `vlab'", ///
                size(medium) color(black)) ///
          subtitle("`sub'", size(vsmall) color(gs7)) ///
          legend(order(`order') `labopt' size(vsmall) rows(3) ///
                 region(lcolor(gs12)) symxsize(4) symysize(2)) ///
          name(`gname', replace)
    restore

    if (`mxgap' > 1e-6) {
        di as text "  {err:the bars do not sum to the series}: largest gap " ///
           as err %10.3e `mxgap'
        di as text "  A stacked decomposition whose slices do not add up is" ///
                   " not a decomposition; treat the picture as wrong."
    }
    * stated in terms of what is DRAWN, so it holds in both modes
    di as text "  graph saved as {bf:`gname'}: " as result `ns' ///
       as text " shock(s) shown, the rest pooled, " as result `nser' ///
       as text " slice(s) sum to the plotted line within " ///
       as result %8.1e `mxgap' as text "."
end

