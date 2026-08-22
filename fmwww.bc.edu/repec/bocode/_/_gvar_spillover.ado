*! _gvar_spillover 1.0.1  21aug2026
*! gvar spillover -- Diebold-Yilmaz connectedness from the generalized FEVD.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   row-normalised generalized FEVD at one horizon  <- Toolbox fevd.m
*   directional and total connectedness             <- BGVAR conn / Diebold &
*                                                      Yilmaz (2009, 2012)
*
* The K x K table is far too large to read for a GVAR with 130-odd variables,
* so it is aggregated into blocks: by unit (the country-level connectedness
* that the empirical literature reports) or by variable.  Aggregation sums
* the shares within each block AFTER row normalisation, which is the
* convention in Diebold & Yilmaz (2014) and in BGVAR.

program define _gvar_spillover, rclass
    version 14.0

    syntax [,                                   ///
        STEP(integer 24)                        ///
        BY(string)                              ///
        TYPE(string)                            ///
        TOP(integer 12)                         ///
        FIRST(string)                           ///
        VORDer(string)                          ///
        VCOV(string)                            ///
        SHRINK                                  ///
        LAMbda(real -1)                         ///
        FULL                                    ///
        GRaph                                   ///
        NETwork                                 ///
        THRESHold(real 0)                       ///
        ROLLing(integer 0)                      ///
        EVery(integer 1)                        ///
        NAME(string)                            ///
        noSUMmary                               ///
        SAVing(name)                            ///
    ]

    _gvar_require solve

    if (`step' < 1) {
        di as err "step() must be at least 1"
        exit 198
    }

    if ("`by'" == "") local by unit
    local by = lower("`by'")
    if ("`by'" != "unit" & "`by'" != "variable" & "`by'" != "none") {
        di as err "by() must be {bf:unit}, {bf:variable} or {bf:none}"
        exit 198
    }

    if ("`type'" == "") local type girf
    local type = lower("`type'")
    if      ("`type'" == "girf")  local sg 0
    else if ("`type'" == "sgirf") local sg 1
    else if ("`type'" == "oirf")  local sg 2
    else {
        di as err "type() must be {bf:girf}, {bf:sgirf} or {bf:oirf}"
        exit 198
    }

    mata: st_local("K",  strofreal(gvar_getK()))
    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))
    mata: st_local("vn", invtokens(gvar_getvname()'))
    * n0 is DERIVED, never supplied: reorder_GVAR.m sets it to sumk0, the
    * total endogenous count of the units placed first.  For a full
    * orthogonalisation the leading block is the whole system.
    local n0 0
    if (`sg' == 2) local n0 = `K'

    * ---- aggregate ---------------------------------------------------------
    if ("`by'" == "unit")          local mode 1
    else if ("`by'" == "variable") local mode 2
    else                           local mode 0

    * ---- reordering, from which n0 is derived (reorder_GVAR.m) ------------
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
        if (`sg' == 1) local n0 = r(n0)
    }
    else {
        matrix `ORD' = J(1, 1, 0)
    }
    if (`sg' == 1 & "`first'" == "") {
        di as err "type(sgirf) identifies the shocks by orthogonalising the"
        di as err "leading block of x(t), so you must say which units lead:"
        di as err "    {bf:first(}{it:unit}[ {it:unit} ...]{bf:)}"
        di as err "and optionally their internal order with {bf:vorder()}."
        di as err "The block size n0 is then the total number of endogenous"
        di as err "variables in those units, as in reorder_GVAR.m."
        exit 198
    }
    * compound quotes: Stata has no backslash escape inside " "
    local ordarg "J(0, 1, 0)"
    if (`nord' > 0) local ordarg `"st_matrix("`ORD'")"'

    _gvar_shrinkopt `sg' `n0' "`vcov'" "`shrink'" "`lambda'"
    local vmeth "`r(vmeth)'"
    local vexcl "`r(vexcl)'"
    local shr   "`r(shr)'"
    local lam   "`r(lam)'"

    * ---- rolling windows ---------------------------------------------------
    * Not from the reference implementations: none of the three rolls the
    * estimation window.  This is Diebold & Yilmaz (2012, 2014) applied to the
    * GVAR, and it re-estimates every country model in every window.
    if (`rolling' > 0) {
        mata: st_local("T", strofreal(gvar_getT()))
        if (`rolling' > `T') {
            di as err "rolling(`rolling') exceeds the " as err `T' ///
                      as err " observations available"
            exit 198
        }
        if (`every' < 1) {
            di as err "every() must be at least 1"
            exit 198
        }
        if ("`network'" != "") {
            di as err "network and rolling() cannot be combined"
            di as err "A network is one picture of one table; a rolling run"
            di as err "produces one table per window.  Run them separately,"
            di as err "or draw the network on a subsample."
            exit 198
        }
        if ("`first'" != "") {
            di as err "first() and vorder() cannot be combined with rolling()"
            di as err "The reordering is applied to the solved full-sample"
            di as err "system; each window is re-solved in the model's own"
            di as err "order.  Use {bf:type(girf)}, which needs no ordering."
            exit 198
        }
        _gvar_spill_roll `rolling' `every' `step' `sg' `n0' `vmeth' `vexcl' ///
                         `shr' `lam' `mode' "`cn'" "`vn'" "`name'" ///
                         "`graph'" "`summary'" `T'
        return add
        exit
    }

    tempname A
    mata: st_matrix("`A'", gvar_spillblock(`step', `sg', `n0', `mode', ///
                                           `vmeth', `vexcl', `shr', `lam', ///
                                           `ordarg'))
    local nb = rowsof(`A')

    if ("`by'" == "unit") {
        local blab  "`cn'"
        local bword "unit"
        * gvar_getcname() lists the COUNTRY models only.  When a dominant unit is
        * present it occupies its own block of x_t under the label "dominant"
        * (_gvar_mata.ado:6281), so the aggregation has one more block than there
        * are country names and this exited 498 "27 blocks but 26 labels".
        * gvar_hasdu() is how _gvar_solve.ado:70 asks the same question.
        capture mata: st_local("hasdu", strofreal(gvar_hasdu()))
        if (_rc == 0 & "`hasdu'" == "1") local blab "`blab' dominant"
    }
    else if ("`by'" == "variable") {
        local blab  "`vn'"
        local bword "variable"
        mata: st_local("gv", invtokens(gvar_getgvname()'))
        foreach g of local gv {
            local inv : list posof "`g'" in blab
            if (`inv' == 0) local blab "`blab' `g'"
        }
    }
    else {
        mata: st_local("blab", gvar_getxlabels())
        local bword "element"
    }
    local nlab : word count `blab'
    if (`nlab' != `nb') {
        di as err "internal: `nb' blocks but `nlab' labels"
        exit 498
    }

    * directional measures on the aggregated table
    tempname FROM TO NET
    matrix `FROM' = J(`nb', 1, 0)
    matrix `TO'   = J(`nb', 1, 0)
    forvalues i = 1/`nb' {
        local s 0
        forvalues j = 1/`nb' {
            if (`j' != `i') local s = `s' + `A'[`i', `j']
        }
        matrix `FROM'[`i', 1] = `s'
    }
    forvalues j = 1/`nb' {
        local s 0
        forvalues i = 1/`nb' {
            if (`i' != `j') local s = `s' + `A'[`i', `j']
        }
        matrix `TO'[`j', 1] = `s'
    }
    matrix `NET' = `TO' - `FROM'
    local btci 0
    forvalues i = 1/`nb' {
        local btci = `btci' + `FROM'[`i', 1]
    }
    local btci = `btci' / `nb'

    * ---- display -----------------------------------------------------------
    if ("`summary'" != "nosummary") {
        _gvar_title "Connectedness (Diebold-Yilmaz) at horizon `step'"
        di as text "  Built from the " as result "`type'" as text ///
                   " variance decomposition, row-normalised to 100,"
        di as text "  then aggregated by `bword'."
        di ""
        di as text "  Total connectedness index: " as result %6.2f `btci' ///
                   as text "%"
        di as text "  (the share of forecast error variance that comes from"
        di as text "   other `bword's -- higher means a more interconnected system)"
        di ""

        * directional table, ranked by net
        tempname ORD
        mata: st_local("ord", gvar_ranktop(st_matrix("`NET'"), `nb'))
        local w 64
        di as text "{hline `w'}"
        di as text %-14s "  `bword'" _col(20) "FROM others" _col(36) ///
                   "TO others" _col(52) "NET"
        di as text "{hline `w'}"
        local nshow = min(`nb', `top')
        local c 0
        foreach i of local ord {
            local ++c
            if (`c' > `nshow' & `c' <= `=`nb' - `nshow'') continue
            if (`c' == `=`nb' - `nshow' + 1' & `nb' > 2 * `nshow') {
                di as text "  ..."
            }
            local b : word `i' of `blab'
            local nt = `NET'[`i', 1]
            di as text "  " %-12s abbrev("`b'", 12) ///
               _col(20) as result %10.2f `=`FROM'[`i',1]' ///
               _col(36) as result %10.2f `=`TO'[`i',1]' ///
               _col(50) as result %10.2f `nt'
        }
        di as text "{hline `w'}"
        di as text "  FROM  variance this `bword' imports from the others"
        di as text "  TO    variance it exports to the others"
        di as text "  NET   TO minus FROM; positive means a net transmitter"
        di as text "  Ranked by NET, largest transmitters first."
        di ""

        if ("`full'" != "" & `nb' <= 30) {
            di as text "  {bf:Pairwise table} (row = receiver, column = source)"
            local w2 = 14 + 7 * `nb'
            if (`w2' > 160) local w2 160
            di as text "{hline `w2'}"
            di as text %-13s "  from\to" _continue
            forvalues j = 1/`nb' {
                local b : word `j' of `blab'
                di as text %7s abbrev("`b'", 6) _continue
            }
            di ""
            di as text "{hline `w2'}"
            forvalues i = 1/`nb' {
                local b : word `i' of `blab'
                di as text "  " %-11s abbrev("`b'", 11) _continue
                forvalues j = 1/`nb' {
                    di as result %7.1f `=`A'[`i', `j']' _continue
                }
                di ""
            }
            di as text "{hline `w2'}"
            di ""
        }
        else if ("`full'" != "") {
            di as text "  {bf:full} suppressed: `nb' blocks is too wide to print."
            di as text "  Use {bf:by(unit)} or read the saved matrix."
            di ""
        }
    }

    if ("`network'" != "") {
        local nnm "`name'"
        if ("`nnm'" != "" & "`graph'" != "") local nnm "`name'_net"
        _gvar_net_graph `A' `nb' "`blab'" `threshold' "`nnm'"
    }

    if ("`graph'" != "") {
        _gvar_spill_graph `NET' `FROM' `TO' `nb' "`blab'" `step' "`name'" "`top'"
    }

    if ("`saving'" != "") {
        matrix `saving' = `A'
    }
    return matrix spillover = `A', copy
    return matrix from = `FROM', copy
    return matrix to   = `TO', copy
    return matrix net  = `NET', copy
    return scalar tci  = `btci'
    return scalar step = `step'
    return local  by   "`by'"
end

* ---------------------------------------------------------------------------
* Net-transmitter bar chart
* ---------------------------------------------------------------------------
program define _gvar_spill_graph
    version 14.0
    args NET FROM TO nb blab step gname top

    if ("`gname'" == "") local gname gvar_spillover

    _gvar_palette
    local reg "`r(region)'"
    local pos "`r(pos)'"
    local neg "`r(neg)'"

    preserve
    clear
    qui set obs `nb'
    qui gen str32  block = ""
    qui gen double net   = .
    forvalues i = 1/`nb' {
        local b : word `i' of `blab'
        qui replace block = "`b'"          in `i'
        qui replace net   = `NET'[`i', 1]  in `i'
    }
    gsort -net
    qui gen int rank = _n
    qui gen double netpos = net if net >= 0
    qui gen double netneg = net if net <  0

    * value labels for the axis, built here rather than with -labmask-, which
    * is a user-written command and cannot be a dependency
    capture label drop _gvspill
    forvalues i = 1/`nb' {
        local b = block[`i']
        label define _gvspill `i' "`b'", add
    }
    label values rank _gvspill

    twoway (bar netpos rank, barwidth(0.7) color("`pos'") lcolor(gs10) lwidth(vthin)) ///
           (bar netneg rank, barwidth(0.7) color("`neg'") lcolor(gs10) lwidth(vthin)) ///
        , `reg' ///
          yline(0, lcolor(gs8) lwidth(thin)) ///
          ylabel(, angle(0) labsize(small) grid glcolor(gs15)) ///
          xlabel(1(1)`nb', valuelabel angle(90) labsize(vsmall)) ///
          ytitle("net connectedness (percentage points)", size(small)) ///
          xtitle("") ///
          title("Net transmitters and receivers at horizon `step'", ///
                size(medium) color(black)) ///
          subtitle("positive = net transmitter of variance", ///
                   size(vsmall) color(gs7)) ///
          name(`gname', replace) legend(off)
    restore
end

* ---------------------------------------------------------------------------
* Rolling-window connectedness.
*
* Addition, not from the sources: none of the three reference implementations
* rolls the estimation window.  This is the standard rolling exercise of
* Diebold & Yilmaz (2012, 2014) applied to the GVAR.  Every window re-estimates
* all country models and re-solves the system, so it is expensive: with the
* 26-unit demo a 60-quarter window stepped every quarter is about 75 full
* re-estimations.
*
* Ranks and lag orders stay at their full-sample values.  Re-selecting them in
* each window would make the index jump whenever a rank test flipped, which
* says more about the test than about the connectedness.
* ---------------------------------------------------------------------------
program define _gvar_spill_roll, rclass
    version 14.0
    args win every step sg n0 vmeth vexcl shr lam mode cn vn name graph ///
         summary T

    mata: st_local("K", strofreal(gvar_getK()))

    tempname GRP R
    local blab ""
    if (`mode' == 1) {
        mata: st_matrix("`GRP'", gvar_getxunit())
        local blab "`cn'"
    }
    else if (`mode' == 2) {
        mata: st_matrix("`GRP'", gvar_getxvarid())
        local blab "`vn'"
    }
    else {
        matrix `GRP' = J(1, 1, 0)
    }
    local grparg "J(0, 1, 0)"
    if (`mode' > 0) local grparg `"st_matrix("`GRP'")"'

    local nwin = floor((`T' - `win') / `every') + 1
    di as text "  rolling a " as result `win' as text "-observation window" ///
       as text " in steps of " as result `every' as text ": " ///
       as result `nwin' as text " window(s),"
    di as text "  each one a full re-estimation of every country model ..."

    mata: gvar_rollwrap(`win', `every', `step', `sg', `n0', `vmeth', ///
                        `vexcl', `shr', `lam', `grparg')
    local nok  = r_nok
    local nbad = r_nbad
    if (`nok' == 0) {
        di as err "every window failed to estimate"
        di as err "The window is probably too short for the lag orders and"
        di as err "ranks of the full-sample specification.  Lengthen" ///
                  " {bf:rolling()},"
        di as err "or shorten the lags with {bf:gvar lags}."
        exit 498
    }
    matrix `R' = r_roll
    local nr = rowsof(`R')

    * ---- table -------------------------------------------------------------
    if ("`summary'" != "nosummary") {
        _gvar_title "Rolling total connectedness"
        di as text "  Window " as result `win' as text " observations," ///
           as text " stepped every " as result `every' as text "."
        di as text "  " as result `nok' as text " window(s) estimated" _continue
        if (`nbad' > 0) {
            di as text ", " as result `nbad' as text " could not be solved."
        }
        else {
            di as text "."
        }
        di ""
        local lvl "variable"
        if (`mode' == 1) local lvl "country"
        if (`mode' == 2) local lvl "variable type"
        di as text "{hline 74}"
        di as text %-22s "  window (obs)" _col(26) "TCI %" _col(38) ///
           "element %" _col(52) "max |eig|" _col(68) "n"
        di as text "{hline 74}"
        forvalues q = 1/`nr' {
            di as text "  " %4.0f `=`R'[`q',1]' as text " - " ///
               %4.0f `=`R'[`q',2]' ///
               _col(24) as result %8.2f `=`R'[`q',4]' ///
               _col(36) as result %8.2f `=`R'[`q',6]' ///
               _col(50) as result %10.6f `=`R'[`q',5]' ///
               _col(66) as result %5.0f `=`R'[`q',3]'
        }
        di as text "{hline 74}"
        di as text "  {bf:TCI} is the average share of forecast error" ///
                   " variance coming from"
        di as text "  {bf:another `lvl'}, in per cent.  It rises in crises."
        if (`mode' > 0) {
            di as text "  {bf:element %} is the same index computed over all" ///
               as result " `K'" as text " variables"
            di as text "  individually.  It is the higher of the two:" ///
                       " aggregating makes a"
            di as text "  spillover between two variables of the same" ///
                       " `lvl' count as own."
        }
        local nexp 0
        forvalues q = 1/`nr' {
            if (`R'[`q', 5] > 1 + 1e-8) local ++nexp
        }
        if (`nexp' > 0) {
            di ""
            di as text "  {err:`nexp'} window(s) have an" ///
               " eigenvalue above one, so the GVAR is"
            di as text "  explosive there and its variance decomposition does" ///
                       " not converge."
            di as text "  The index is still reported, but for those windows" ///
                       " it is not a"
            di as text "  share of anything finite.  Read them as a warning" ///
                       " that the"
            di as text "  window is too short for this specification, not as" ///
                       " a result."
        }
        di as text ""
        di as text "  {bf:Not from the reference implementations.}  None of" ///
                   " the three rolls the"
        di as text "  estimation window; this is Diebold & Yilmaz (2012," ///
                   " 2014) applied to"
        di as text "  the GVAR.  Ranks and lag orders are held at their" ///
                   " full-sample values,"
        di as text "  so a moving index is moving dynamics, not a moving" ///
                   " specification."
        di ""
    }

    if ("`graph'" != "") {
        _gvar_roll_graph `R' `nr' `mode' "`blab'" `win' "`name'"
    }

    return matrix rolling = `R', copy
    return scalar windows  = `nok'
    return scalar failed   = `nbad'
    return scalar window   = `win'
    return scalar every    = `every'
end

* ---------------------------------------------------------------------------
* The rolling index through time, with per-block net positions beneath it when
* the run was aggregated.
* ---------------------------------------------------------------------------
program define _gvar_roll_graph
    version 14.0
    args R nr mode blab win name

    _gvar_palette
    local c1   "`r(c1)'"
    local grid "`r(grid)'"
    local reg  "`r(region)'"
    local pos  "`r(pos)'"
    local neg  "`r(neg)'"
    local creg "graphregion(color(white)) plotregion(color(white) lcolor(none))"

    local nm "gvar_rolling"
    if ("`name'" != "") local nm "`name'"

    local nc = colsof(`R')
    local ng = `nc' - 6

    preserve
    quietly {
        clear
        svmat double `R', names(col)
        rename c1 wfirst
        rename c2 wlast
        rename c3 wn
        rename c4 tci
        rename c5 maxeig
        rename c6 tcielem

        * An explosive window has no convergent variance decomposition, so its
        * index is not comparable with the rest.  Draw the line through the
        * stable windows only and mark the others, rather than joining points
        * that do not measure the same thing.
        gen double tcistab = tci if maxeig <= 1 + 1e-8
        gen double tciexp  = tci if maxeig >  1 + 1e-8
        count if maxeig > 1 + 1e-8
        local nexp = r(N)
        local expl ""
        if (`nexp' > 0) {
            local expl `"(scatter tciexp wlast, msymbol(Oh) msize(medium) mcolor("`neg'") mlwidth(medthick))"'
        }

        local nt `""Each point is a full re-estimation of the GVAR on that window""'
        if (`nexp' > 0) {
            local nt `"`nt' "hollow markers: window is explosive, so its index is not a share of anything finite""'
        }

        twoway (line tcistab wlast, lcolor("`c1'") lwidth(medthick))         ///
               (scatter tcistab wlast, msymbol(o) msize(small)               ///
                    mcolor("`c1'"))                                          ///
               `expl'                                                        ///
               , `reg'                                                      ///
                 ylabel(, angle(0) labsize(small) grid glcolor("`grid'"))   ///
                 xlabel(, labsize(small))                                   ///
                 ytitle("total connectedness, %", size(small))              ///
                 xtitle("last observation of the window", size(small))      ///
                 title("Rolling total connectedness index",                 ///
                       size(medium) color(black))                           ///
                 subtitle("`win'-observation window", size(small)           ///
                          color(black))                                     ///
                 note(`nt', size(vsmall) color(black))                      ///
                 legend(off) name(_gvroll_tci, replace) nodraw

        * the net position of the biggest transmitters and receivers, so the
        * index can be read against who is driving it
        local panels "_gvroll_tci"
        if (`ng' > 1) {
            * rank blocks by the range of their net position over the windows
            local best ""
            local bestv ""
            forvalues g = 1/`ng' {
                summarize c`=`g'+6', meanonly
                local rg = r(max) - r(min)
                local best  "`best' `g'"
                local bestv "`bestv' `rg'"
            }
            * take the four most variable blocks
            local keep ""
            forvalues pick = 1/4 {
                local bi 0
                local bv -1
                local w 0
                foreach g of local best {
                    local ++w
                    local v : word `w' of `bestv'
                    local already : list posof "`g'" in keep
                    if (`already' == 0 & `v' > `bv') {
                        local bv `v'
                        local bi `g'
                    }
                }
                if (`bi' > 0) local keep "`keep' `bi'"
            }
            local plots ""
            foreach g of local keep {
                local l : word `g' of `blab'
                local gv = `g' + 6
                twoway (line c`gv' wlast, lcolor("`c1'") lwidth(medthick))   ///
                       , `reg'                                              ///
                         yline(0, lcolor("`grid'") lwidth(thin))            ///
                         ylabel(, angle(0) labsize(vsmall) grid             ///
                                glcolor("`grid'"))                          ///
                         xlabel(, labsize(vsmall))                          ///
                         ytitle("") xtitle("")                              ///
                         title("`l'", size(small) color(black))             ///
                         subtitle("net, %", size(vsmall) color(black))      ///
                         legend(off) name(_gvroll_g`g', replace) nodraw
                local plots "`plots' _gvroll_g`g'"
            }
            graph combine _gvroll_tci `plots', cols(1) `creg'               ///
                iscale(0.7) name(`nm', replace)
            foreach p of local plots {
                capture graph drop `p'
            }
        }
        else {
            graph combine _gvroll_tci, `creg' name(`nm', replace)
        }
        capture graph drop _gvroll_tci
    }
    restore

    di as text "  graph saved as {bf:`nm'}"
end

* ---------------------------------------------------------------------------
* Network diagram of the pairwise net flows.
*
* Blocks sit on a circle.  An edge is drawn whenever the NET pairwise flow
* between two blocks exceeds the threshold, oriented from transmitter to
* receiver.  Node colour separates net transmitters from net receivers and
* node area is the size of that net position, so a large green node that only
* emits is a systemic transmitter.
*
* Stata's -twoway- has no arrowhead, so direction is carried by the ordering
* of the endpoints and by the node colours rather than by a glyph.
* ---------------------------------------------------------------------------
program define _gvar_net_graph
    version 14.0
    args A nb blab thresh name

    _gvar_palette
    local grid "`r(grid)'"
    local reg  "`r(region)'"
    local pos  "`r(pos)'"
    local neg  "`r(neg)'"
    local zero "`r(zero)'"
    local band "`r(band)'"

    local nm "gvar_network"
    if ("`name'" != "") local nm "`name'"

    if (`nb' < 2) {
        di as err "a network needs at least two blocks; use {bf:by(unit)}"
        exit 198
    }

    * ---- the net pairwise flows -------------------------------------------
    tempname NET
    matrix `NET' = J(`nb', `nb', 0)
    local nedge 0
    forvalues i = 1/`nb' {
        forvalues j = 1/`nb' {
            if (`i' < `j') {
                matrix `NET'[`i', `j'] = `A'[`j', `i'] - `A'[`i', `j']
            }
        }
    }

    * threshold(0) means "choose one": keep roughly the strongest tenth of the
    * pairs, because a complete graph on `nb' nodes is not a picture of
    * anything once nb is more than about six
    local th = `thresh'
    if (`th' <= 0) {
        preserve
        quietly {
            clear
            local npair = `nb' * (`nb' - 1) / 2
            set obs `npair'
            gen double av = .
            local e 0
            forvalues i = 1/`nb' {
                forvalues j = 1/`nb' {
                    if (`i' < `j') {
                        local ++e
                        replace av = abs(`NET'[`i', `j']) in `e'
                    }
                }
            }
            _pctile av, percentiles(90)
            local th = r(r1)
        }
        restore
        di as text "  threshold chosen automatically: " as result %6.3f `th' ///
           as text "% (the strongest tenth of pairs)"
    }

    preserve
    quietly {
        clear
        set obs `nb'
        gen int    node   = _n
        gen double nx     = cos(2 * _pi * (_n - 1) / `nb')
        gen double ny     = sin(2 * _pi * (_n - 1) / `nb')
        gen str32  nlab   = ""
        gen double netpos = .
        forvalues i = 1/`nb' {
            local l : word `i' of `blab'
            replace nlab = "`l'" in `i'
            local to 0
            local fr 0
            forvalues j = 1/`nb' {
                if (`j' != `i') {
                    local to = `to' + `A'[`j', `i']
                    local fr = `fr' + `A'[`i', `j']
                }
            }
            replace netpos = `to' - `fr' in `i'
        }
        * analytic weights must be strictly positive, and netpos is signed:
        * size by magnitude, colour by sign
        gen double nsize = abs(netpos)
        summarize nsize, meanonly
        local smax = r(max)
        if (`smax' <= 0) local smax 1
        replace nsize = 0.02 * `smax' if nsize < 0.02 * `smax'

        gen double ex1 = .
        gen double ey1 = .
        gen double ex2 = .
        gen double ey2 = .
        local e 0
        forvalues i = 1/`nb' {
            forvalues j = 1/`nb' {
                if (`i' < `j') {
                    local v = `NET'[`i', `j']
                    if (abs(`v') > `th') {
                        local ++e
                        if (`e' > _N) set obs `e'
                        * orient from transmitter to receiver
                        if (`v' > 0) {
                            local a `i'
                            local b `j'
                        }
                        else {
                            local a `j'
                            local b `i'
                        }
                        replace ex1 = cos(2 * _pi * (`a' - 1) / `nb') in `e'
                        replace ey1 = sin(2 * _pi * (`a' - 1) / `nb') in `e'
                        replace ex2 = cos(2 * _pi * (`b' - 1) / `nb') in `e'
                        replace ey2 = sin(2 * _pi * (`b' - 1) / `nb') in `e'
                    }
                }
            }
        }
        local nedge = `e'
    }

    if (`nedge' == 0) {
        restore
        di as err "no pairwise net flow exceeds threshold(`th')"
        di as text "  Lower {bf:threshold()}, or leave it out to have one" ///
                   " chosen."
        exit 498
    }

    quietly {
        twoway (pcspike ey1 ex1 ey2 ex2, lcolor("`band'") lwidth(medthin))  ///
               (scatter ny nx if netpos > 0 [w=nsize], msymbol(O)           ///
                    mcolor("`pos'%70") mlcolor("`zero'") mlwidth(vthin))    ///
               (scatter ny nx if netpos <= 0 [w=nsize], msymbol(O)          ///
                    mcolor("`neg'%70") mlcolor("`zero'") mlwidth(vthin))    ///
               (scatter ny nx, msymbol(none) mlabel(nlab)                   ///
                    mlabposition(0) mlabsize(vsmall) mlabcolor(black))      ///
               , `reg' aspectratio(1)                                       ///
                 xscale(off range(-1.3 1.3))                               ///
                 yscale(off range(-1.3 1.3))                               ///
                 title("Net connectedness network", size(medium)            ///
                       color(black))                                       ///
                 subtitle("edges are net pairwise flows above"              ///
                          " `=string(`th', "%5.2f")'%",                     ///
                          size(small) color(black))                        ///
                 legend(order(2 "net transmitter" 3 "net receiver")         ///
                        rows(1) size(vsmall) region(lcolor(none))           ///
                        position(6))                                        ///
                 note("Edges run from transmitter to receiver; node area is" ///
                      " the block's own net position", size(vsmall)         ///
                      color(black))                                        ///
                 name(`nm', replace)
    }
    restore

    di as text "  network graph saved as {bf:`nm'} (" as result `nedge' ///
       as text " edge(s))"
    if (`nedge' > 60) {
        di as text "  {bf:note}: " as result `nedge' as text " edges is more" ///
           " than a circular layout can show"
        di as text "  legibly.  Raise {bf:threshold()}, or leave it out to" ///
                   " keep only the"
        di as text "  strongest tenth of pairs."
    }
end
