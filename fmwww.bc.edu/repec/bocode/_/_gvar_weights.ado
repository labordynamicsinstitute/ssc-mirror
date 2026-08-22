*! _gvar_weights 1.0.1  21aug2026
*! gvar weights -- build, install, inspect and plot the GVAR weight matrices.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   flows -> weights, columns sum to one   <- Toolbox weightmat.m
*   averaging over a flow-year window      <- Toolbox build_wmat.m (fixed)
*   year-by-year time-varying matrices     <- Toolbox build_wmat.m (tv branch)
*                                             GVARX GVAR_Ft (list branch)
*   separate solution matrix               <- Toolbox tvw_solution_modeflag
*   equal weights                          <- GVARX GVAR_Ft (null branch)
*   several weight types, one per variable <- Toolbox gvar.m vtypes / wmat1..10

program define _gvar_weights, rclass
    version 14.0

    syntax [using/] [,                     ///
        MATrix(name)                       ///
        TYPE(integer 1)                    ///
        FLOW(name)                         ///
        SOUrce(name)                       ///
        DESTination(name)                  ///
        YEAR(name)                         ///
        YEARs(numlist integer ascending)   ///
        MAP(string)                        ///
        WIDE                               ///
        ROWname(name)                      ///
        SLICE(name)                        ///
        TIMEvarying                        ///
        WINdow(integer 3)                  ///
        SOLyears(numlist integer ascending) ///
        EQual                              ///
        LIST                               ///
        GRaph                              ///
        NAME(string)                       ///
        noREBuild                          ///
        noSUMmary ]

    _gvar_require setup

    * weights keeps its progress lines in helper programs, where a
    * `summary' local is out of scope, so those helpers are called under
    * quietly.  Safe here because every -as err- in them comes
    * immediately before an -exit-: an error must still reach the user.
    local qui ""
    if ("`summary'" == "nosummary") local qui "quietly"

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))

    local nmode = 0
    if ("`matrix'" != "")  local ++nmode
    if ("`using'" != "")   local ++nmode
    if ("`equal'" != "")   local ++nmode
    if (`nmode' > 1) {
        di as err "specify only one of {bf:matrix()}, {bf:using} or {bf:equal}"
        exit 198
    }

    * =======================================================================
    * 1.  Equal weights
    * =======================================================================
    if ("`equal'" != "") {
        mata: gvar_setw(`type', gvar_wequal(`N'))
        if ("`summary'" != "nosummary") di as text "Equal weights installed for weight type " as result `type' ///
                   as text " (w_ij = 1/(N-1))."
    }

    * =======================================================================
    * 2.  Install a Stata matrix
    * =======================================================================
    else if ("`matrix'" != "") {
        capture confirm matrix `matrix'
        if _rc {
            di as err "matrix {bf:`matrix'} not found"
            exit 111
        }
        if (rowsof(`matrix') != `N' | colsof(`matrix') != `N') {
            di as err "matrix {bf:`matrix'} is " rowsof(`matrix') " x " colsof(`matrix') ///
                      ", expected `N' x `N'"
            exit 503
        }
        * reorder to the model's unit order when the matrix carries names
        tempname W
        matrix `W' = `matrix'
        local rn : rownames `matrix'
        local okname = 1
        foreach c of local cn {
            local p : list posof "`c'" in rn
            if (`p' == 0) local okname = 0
        }
        if (`okname') {
            matrix `W' = `matrix'[ "`cn'" , "`cn'" ]
            if ("`summary'" != "nosummary") di as text "Matrix reordered to the GVAR unit order using its row/column names."
        }
        mata: gvar_setw(`type', st_matrix("`W'"))
        if ("`summary'" != "nosummary") di as text "Weight matrix installed for weight type " as result `type' as text "."
    }

    * =======================================================================
    * 3.  Build from a bilateral-flow file
    * =======================================================================
    else if ("`using'" != "" & "`wide'" != "") {
        `qui' _gvar_wide_matrix `"`using'"', type(`type') units(`cn') ///
            rowname(`rowname') slice(`slice')
    }

    else if ("`using'" != "") {
        if ("`flow'" == "" | "`source'" == "" | "`destination'" == "") {
            di as err "building from flows requires {bf:flow()}, {bf:source()} and {bf:destination()}"
            exit 198
        }
        `qui' _gvar_build_from_flows `"`using'"', flow(`flow') source(`source')       ///
            destination(`destination') year(`year') years(`years')             ///
            type(`type') `timevarying' window(`window') solyears(`solyears')   ///
            units(`cn') map(`"`map'"')
    }

    * =======================================================================
    * Guard: a unit whose weight column sums to zero has NO trading partners,
    * so every one of its foreign variables would be identically zero.  That
    * is a silent catastrophe -- the unit's VECMX* would be estimated on a
    * block of zeros -- so refuse rather than continue.
    * =======================================================================
    tempname WCHK
    mata: st_matrix("`WCHK'", colsum(gvar_getW(`type')))
    local nzero 0
    local zlist ""
    forvalues i = 1/`N' {
        if (abs(`WCHK'[1, `i']) < 1e-10) {
            local ++nzero
            local u : word `i' of `cn'
            local zlist "`zlist' `u'"
        }
    }
    if (`nzero' > 0) {
        di as err ""
        di as err "gvar weights: `nzero' unit(s) have a weight column of zeros,"
        di as err "meaning no counterpart supplies them with any weight:"
        di as err "   `zlist'"
        di as err ""
        di as err "Their foreign-specific variables would all be identically zero."
        di as err "Usually this means the flow file names those units differently,"
        di as err "or that they are aggregates whose members still appear under"
        di as err "their own names in the flow file.  Supply a crosswalk with"
        di as err "   {bf:gvar weights using flows.dta, ... map(crosswalk.dta)}"
        di as err "where the crosswalk has string variables {bf:from} and {bf:to}."
        exit 459
    }

    * =======================================================================
    * 4.  Report / plot the current matrix
    * =======================================================================
    if ("`rebuild'" != "norebuild" & "`list'`graph'" == "") {
        mata: gvar_specify()
        if ("`summary'" != "nosummary") di as text "Foreign-specific variables rebuilt with the new weights."
    }

    tempname WW
    mata: st_matrix("`WW'", gvar_getW(`type'))
    matrix rownames `WW' = `cn'
    matrix colnames `WW' = `cn'
    return matrix W = `WW', copy

    if ("`list'" != "") {
        _gvar_weights_list `WW' `type'
    }
    if ("`graph'" != "") {
        _gvar_weights_graph `WW' `type' "`name'"
    }

    return scalar type = `type'
    return local  units "`cn'"
end

* ---------------------------------------------------------------------------
* Journal-style listing of a weight matrix
* ---------------------------------------------------------------------------
program define _gvar_weights_list
    version 14.0
    args W type

    local cn : rownames `W'
    local N = rowsof(`W')

    _gvar_title "Weight matrix (type `type'): column j holds the weights of country j"

    local perpage 8
    local blocks = ceil(`N' / `perpage')
    forvalues b = 1/`blocks' {
        local lo = (`b' - 1) * `perpage' + 1
        local hi = min(`b' * `perpage', `N')

        di ""
        di as text "  from / to" _continue
        forvalues j = `lo'/`hi' {
            local nm : word `j' of `cn'
            di as text %9s abbrev("`nm'", 8) _continue
        }
        di ""
        di as text "  {hline `=11 + 9*(`hi'-`lo'+1)'}"
        forvalues i = 1/`N' {
            local nm : word `i' of `cn'
            di as text "  " %-9s abbrev("`nm'", 9) _continue
            forvalues j = `lo'/`hi' {
                local v = `W'[`i', `j']
                if (`v' == 0) {
                    di as text %9s "." _continue
                }
                else {
                    di as result %9.4f `v' _continue
                }
            }
            di ""
        }
        di as text "  {hline `=11 + 9*(`hi'-`lo'+1)'}"
        di as text "  column sums" _continue
        forvalues j = `lo'/`hi' {
            local s = 0
            forvalues i = 1/`N' {
                local s = `s' + `W'[`i', `j']
            }
            di as result %9.4f `s' _continue
        }
        di ""
    }
    di ""
    di as text "  Columns sum to one by construction (Toolbox {it:weightmat.m} convention):"
    di as text "  w(i,j) is the weight of country i in country j's foreign aggregate."
    di ""
end

* ---------------------------------------------------------------------------
* Heatmap of a weight matrix, built from base twoway only (light palette).
* One scatter layer per colour bin -- no dependency on heatplot.
* ---------------------------------------------------------------------------
program define _gvar_weights_graph
    version 14.0
    args W type gname

    local cn : rownames `W'
    local N = rowsof(`W')
    if ("`gname'" == "") local gname gvar_weights

    _gvar_palette
    local reg  "`r(region)'"
    local h1   "`r(h1)'"
    local h2   "`r(h2)'"
    local h3   "`r(h3)'"
    local h4   "`r(h4)'"
    local h5   "`r(h5)'"
    local h6   "`r(h6)'"

    preserve
    clear
    qui set obs `=`N' * `N''
    qui gen int  row = ceil(_n / `N')
    qui gen int  col = _n - (row - 1) * `N'
    qui gen double wv = .
    forvalues i = 1/`N' {
        forvalues j = 1/`N' {
            qui replace wv = `W'[`i', `j'] if row == `i' & col == `j'
        }
    }
    * Trade weights are extremely right-skewed: a handful of large bilateral
    * links and hundreds of near-zero ones.  Equal-width bins put almost every
    * cell in the lowest colour and waste the scale, so the cuts are taken at
    * quantiles of the NON-ZERO weights instead.
    qui summarize wv if wv > 1e-12, detail
    local q20 = r(p25)
    local q40 = r(p50)
    local q60 = r(p75)
    local q80 = r(p90)
    local q95 = r(p99)
    local mx  = r(max)

    qui gen byte bin = 1
    qui replace bin = 2 if wv > 1e-12
    qui replace bin = 3 if wv > `q20'
    qui replace bin = 4 if wv > `q40'
    qui replace bin = 5 if wv > `q60'
    qui replace bin = 6 if wv > `q80'
    qui replace bin = 7 if wv > `q95'

    * y axis reversed so that row 1 is at the top, as in a printed matrix
    qui gen int yrow = `N' + 1 - row

    * marker size chosen so that the squares tile the grid without gaps
    local msz = max(1.4, 65 / `N')

    local lab ""
    forvalues i = 1/`N' {
        local nm : word `i' of `cn'
        local yy = `N' + 1 - `i'
        local lab `lab' `yy' "`=abbrev("`nm'", 8)'"
    }
    local xlab ""
    forvalues j = 1/`N' {
        local nm : word `j' of `cn'
        local xlab `xlab' `j' "`=abbrev("`nm'", 8)'"
    }

    local f : display %5.3f `q20'
    local g : display %5.3f `q40'
    local h : display %5.3f `q60'
    local k : display %5.3f `q80'
    local l : display %5.3f `q95'

    twoway ///
        (scatter yrow col if bin==1, msymbol(square) msize(*`msz') mcolor(white)   mlcolor(gs14) mlwidth(vvthin)) ///
        (scatter yrow col if bin==2, msymbol(square) msize(*`msz') mcolor("`h1'") mlcolor(gs14) mlwidth(vvthin)) ///
        (scatter yrow col if bin==3, msymbol(square) msize(*`msz') mcolor("`h2'") mlcolor(gs14) mlwidth(vvthin)) ///
        (scatter yrow col if bin==4, msymbol(square) msize(*`msz') mcolor("`h3'") mlcolor(gs14) mlwidth(vvthin)) ///
        (scatter yrow col if bin==5, msymbol(square) msize(*`msz') mcolor("`h4'") mlcolor(gs14) mlwidth(vvthin)) ///
        (scatter yrow col if bin==6, msymbol(square) msize(*`msz') mcolor("`h5'") mlcolor(gs14) mlwidth(vvthin)) ///
        (scatter yrow col if bin==7, msymbol(square) msize(*`msz') mcolor("`h6'") mlcolor(gs14) mlwidth(vvthin)) ///
        , `reg' ///
          ylabel(`lab', angle(0) labsize(vsmall) nogrid notick) ///
          xlabel(`xlab', angle(90) labsize(vsmall) notick) ///
          ytitle("weight of country i (row)", size(small)) ///
          xtitle("in country j's foreign aggregate (column)", size(small)) ///
          title("GVAR weight matrix, type `type'", size(medium) color(black)) ///
          subtitle("columns sum to one; cuts at quantiles of the non-zero weights", ///
                   size(vsmall) color(gs7)) ///
          legend(order(1 "0" 2 "<`f'" 3 "<`g'" 4 "<`h'" 5 "<`k'" 6 "<`l'" 7 "max `: display %5.3f `mx''") ///
                 rows(1) position(6) region(lstyle(none)) size(vsmall) ///
                 symxsize(*.5) keygap(*.5)) ///
          name(`gname', replace) ///
          aspectratio(1) xsize(7) ysize(7)

    restore
end

* ---------------------------------------------------------------------------
* Read a weight matrix stored in wide form: a string identifier column plus
* one numeric column per unit.  Rows and columns are matched to the GVAR unit
* order by name, so the file may be in any order and may cover extra units.
* With slice(), one block of a stacked time-varying file is read instead.
* ---------------------------------------------------------------------------
program define _gvar_wide_matrix
    version 14.0
    syntax anything(name=fname), type(integer) units(string) ///
        [ rowname(name) slice(name) ]

    * -anything- keeps the compound quotes, so strip one layer before re-quoting
    local fname `fname'
    local N : word count `units'
    if ("`rowname'" == "") local rowname rowname

    preserve
    qui use `"`fname'"', clear

    capture confirm string variable `rowname'
    if _rc {
        restore
        di as err "wide weight file needs a string identifier variable; " ///
                  "specify {bf:rowname()} (default {bf:rowname})"
        exit 198
    }

    if ("`slice'" != "") {
        capture confirm variable `slice'
        if _rc {
            restore
            di as err "variable {bf:`slice'} not found in {bf:`fname'}"
            exit 111
        }
    }

    if ("`slice'" != "") {
        qui summarize `slice', meanonly
        qui keep if `slice' == r(min)
    }

    tempvar rowno
    qui gen long `rowno' = _n

    tempname W
    matrix `W' = J(`N', `N', 0)

    local nmiss 0
    local i 0
    foreach ru of local units {
        local ++i
        qui count if `rowname' == "`ru'"
        if (r(N) == 0) {
            local ++nmiss
            continue
        }
        qui levelsof `rowno' if `rowname' == "`ru'", local(rr)
        local rr : word 1 of `rr'
        local j 0
        foreach cu of local units {
            local ++j
            capture confirm variable `cu'
            if !_rc {
                matrix `W'[`i', `j'] = `cu'[`rr']
            }
        }
    }
    restore

    if (`nmiss' > 0) {
        di as err "`nmiss' of the `N' GVAR units were not found in the weight file"
        di as err "expected identifiers: `units'"
        exit 459
    }

    mata: gvar_setw(`type', st_matrix("`W'"))
    di as text "Weight matrix read from " as result `"`fname'"' ///
               as text " and installed for type " as result `type' as text "."
end

* ---------------------------------------------------------------------------
* Build weight matrices from a long bilateral-flow dataset
* ---------------------------------------------------------------------------
program define _gvar_build_from_flows
    version 14.0
    syntax anything(name=fname), flow(name) source(name) destination(name) ///
        units(string) type(integer) [ year(name) years(numlist) map(string) ///
        TIMEvarying window(integer 3) solyears(numlist) ]

    local fname `fname'
    local N : word count `units'

    preserve
    qui use `"`fname'"', clear

    * -----------------------------------------------------------------------
    * Optional crosswalk: rename flow-file identifiers before matching, so
    * that the members of an aggregated unit are summed into it.  This is the
    * long-data equivalent of the Toolbox's update_matrix.m, which adds the
    * region members' rows and columns of the trade matrix together; the
    * resulting intra-region trade lands on the diagonal and is zeroed by
    * weightmat.m.
    * -----------------------------------------------------------------------
    if (`"`map'"' != "") {
        local mapf `map'
        tempfile flowtmp
        qui save `"`flowtmp'"'
        qui use `"`mapf'"', clear
        capture confirm string variable from
        local rc1 = _rc
        capture confirm string variable to
        if (`rc1' | _rc) {
            restore
            di as err "map(): the crosswalk needs string variables {bf:from} and {bf:to}"
            exit 198
        }
        local nmap = _N
        forvalues m = 1/`nmap' {
            local mf`m' = from[`m']
            local mt`m' = to[`m']
        }
        qui use `"`flowtmp'"', clear
        forvalues m = 1/`nmap' {
            qui replace `source'      = "`mt`m''" if `source'      == "`mf`m''"
            qui replace `destination' = "`mt`m''" if `destination' == "`mf`m''"
        }
        di as text "Crosswalk applied: " as result `nmap' ///
                   as text " flow-file identifiers remapped before aggregation."
    }

    foreach v in `flow' `source' `destination' {
        capture confirm variable `v'
        if _rc {
            restore
            di as err "variable {bf:`v'} not found in {bf:`fname'}"
            exit 111
        }
    }
    if ("`year'" != "") {
        capture confirm variable `year'
        if _rc {
            restore
            di as err "variable {bf:`year'} not found in {bf:`fname'}"
            exit 111
        }
    }

    * ---- restrict to the requested flow years -----------------------------
    if ("`years'" != "" & "`year'" != "") {
        local y1 : word 1 of `years'
        local nyw : word count `years'
        local y2 : word `nyw' of `years'
        qui keep if `year' >= `y1' & `year' <= `y2'
        qui count
        if (r(N) == 0) {
            restore
            di as err "no flow observations in the requested year range"
            exit 2000
        }
    }

    * ---- map the flow-file country identifiers onto the GVAR unit order ---
    tempvar si di_
    qui gen int `si' = .
    qui gen int `di_' = .
    local k 0
    foreach u of local units {
        local ++k
        capture confirm string variable `source'
        if (!_rc) {
            qui replace `si'  = `k' if strtoname(`source')      == "`u'" | `source'      == "`u'"
            qui replace `di_' = `k' if strtoname(`destination') == "`u'" | `destination' == "`u'"
        }
        else {
            qui replace `si'  = `k' if string(`source')      == "`u'"
            qui replace `di_' = `k' if string(`destination') == "`u'"
        }
    }
    qui drop if missing(`si') | missing(`di_')
    qui count
    if (r(N) == 0) {
        restore
        di as err "none of the flow-file country identifiers matched the GVAR units"
        di as err "expected identifiers: `units'"
        exit 459
    }

    * =====================================================================
    * The averaging and normalisation are done in Mata: the FLOWS are
    * averaged first and the weights computed from the averaged flows, as
    * build_wmat.m does.  Doing it here in the interpreter would be
    * O(years x rows) and take minutes on a full flow database.
    * =====================================================================
    if ("`timevarying'" == "") {
        * The year variable goes down even for FIXED weights: the averaging
        * divisor is the number of years, and without it a region aggregate would
        * be divided by members x years and come out as the mean of its members
        * rather than their sum.  Passing "" here is what produced a euro-area
        * weight of 0.009 against the Toolbox's 0.145.
        mata: _gvar_flowmat("`si'", "`di_'", "`flow'", "`year'", `N', `type', 0, 0)
        restore
        di as text "Fixed weight matrix built from flows and installed for type " ///
                   as result `type' as text "."
        exit
    }

    if ("`year'" == "") {
        restore
        di as err "{bf:timevarying} requires {bf:year()}"
        exit 198
    }

    mata: _gvar_flowmat("`si'", "`di_'", "`flow'", "`year'", `N', `type', 1, `window')
    restore

    local ny = __gvar_ny
    local nn = min(`ny', `window')

    * map each period of the estimation window onto a flow-year block
    mata: _gvar_yrmap(st_matrix("__gvar_uy"))
    mata: gvar_setwtv(`type', st_matrix("__gvar_WS"), `ny',            ///
                      st_matrix("__gvar_yrid"), st_matrix("__gvar_FS"))

    capture matrix drop __gvar_WS __gvar_FS __gvar_uy __gvar_yrid
    capture scalar drop __gvar_ny

    di as text "Time-varying weight matrices installed for type " as result `type' ///
               as text ": " as result `ny' as text " flow years."
    di as text "Solution matrix built from the flows averaged over the last " ///
               as result `nn' as text " flow years (Toolbox {it:tvw_solution_modeflag})."
end

* ---------------------------------------------------------------------------
