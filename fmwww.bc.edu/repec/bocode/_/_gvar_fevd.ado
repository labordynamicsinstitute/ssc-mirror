*! _gvar_fevd 1.0.1  21aug2026
*! gvar fevd -- forecast error variance decomposition of the solved GVAR.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   generalized FEVD                        <- Toolbox fevd.m
*   orthogonalised FEVD (Cholesky)          <- Toolbox fevd.m, sgirf flag 2
*   structural GFEVD, leading block          <- Toolbox fevd.m, sgirf flag 1
*
* The generalized decomposition does NOT sum to one across shocks, because
* the shocks are not orthogonal.  That is a property of the estimator, not a
* defect: Pesaran & Shin (1998) define the shares against the own-variance of
* each shock separately.  The row sum is reported so the reader can see how
* far from one it falls; for shares that do sum to one use type(oirf).

program define _gvar_fevd, rclass
    version 14.0

    syntax [,                                   ///
        VARiable(string)                        ///
        STEP(integer 24)                        ///
        TYPE(string)                            ///
        HORizons(numlist integer >=0 sort)      ///
        TOP(integer 10)                         ///
        FIRST(string)                           ///
        VORDer(string)                          ///
        VCOV(string)                            ///
        SHRINK                                  ///
        LAMbda(real -1)                         ///
        SHOCKs(string)                          ///
        GRaph                                   ///
        NAME(string)                            ///
        noSUMmary                               ///
        SAVing(name)                            ///
    ]

    _gvar_require solve

    if ("`variable'" == "") {
        di as err "variable() is required: the variable whose forecast error"
        di as err "variance is decomposed, as {bf:unit:variable}"
        exit 198
    }
    if (`step' < 1) {
        di as err "step() must be at least 1"
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

    mata: st_local("K", strofreal(gvar_getK()))
    * n0 is DERIVED, never supplied: reorder_GVAR.m sets it to sumk0, the
    * total endogenous count of the units placed first.  For a full
    * orthogonalisation the leading block is the whole system.
    local n0 0
    if (`sg' == 2) local n0 = `K'

    _gvar_xsel "`variable'"
    local vpos "`r(pos)'"
    local vlab "`r(labels)'"
    if (r(n) != 1) {
        di as err "variable() must select exactly one element, not `=r(n)'"
        exit 198
    }

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

    tempname E F
    matrix `E' = J(`K', 1, 0)
    matrix `E'[`vpos', 1] = 1
    mata: st_matrix("`F'", gvar_fevdrun(st_matrix("`E'"), `step', `sg', `n0', ///
                                        `vmeth', `vexcl', `shr', `lam', ///
                                        `ordarg'))

    * ---- which shocks to display -------------------------------------------
    if ("`shocks'" != "") {
        _gvar_xsel "`shocks'"
        local spos "`r(pos)'"
        local slab "`r(labels)'"
        local ns = r(n)
    }
    else {
        * rank by the share at the final horizon and keep the largest
        mata: st_local("spos", gvar_ranktop(st_matrix("`F'")[., `step' + 1], `top'))
        mata: st_local("xn", invtokens(gvar_getxname()'))
        mata: st_local("xc", invtokens(gvar_getxcname()'))
        local slab ""
        foreach j of local spos {
            local cj : word `j' of `xc'
            local vj : word `j' of `xn'
            local slab "`slab' `cj':`vj'"
        }
        local slab = trim("`slab'")
        local ns : word count `spos'
    }

    * ---- assemble the reported matrix --------------------------------------
    tempname R
    matrix `R' = J(`=`step'+1', `=`ns'+1', .)
    local c 0
    foreach j of local spos {
        local ++c
        forvalues h = 1/`=`step'+1' {
            matrix `R'[`h', `c'] = `F'[`j', `h']
        }
    }
    * last column: the total over ALL shocks, not just the displayed ones
    forvalues h = 1/`=`step'+1' {
        local s 0
        forvalues j = 1/`K' {
            local s = `s' + `F'[`j', `h']
        }
        matrix `R'[`h', `=`ns'+1'] = `s'
    }

    if ("`horizons'" == "") {
        local hshow 0 1 2 4 8 12 16 20 24 32 40
        local keep ""
        foreach h of local hshow {
            if (`h' <= `step') local keep "`keep' `h'"
        }
        local pin : list posof "`step'" in keep
        if (`pin' == 0) local keep "`keep' `step'"
    }
    else {
        local keep ""
        foreach h of local horizons {
            if (`h' <= `step') local keep "`keep' `h'"
        }
    }
    local keep = trim("`keep'")

    if ("`summary'" != "nosummary") {
        local tname "Generalized forecast error variance decomposition"
        if (`sg' == 1) local tname "Structural generalized FEVD"
        if (`sg' == 2) local tname "Orthogonalised forecast error variance decomposition"
        _gvar_title "`tname'"
        di as text "  Variable decomposed: " as result "`vlab'" as text "."
        if ("`shocks'" == "") {
            di as text "  Showing the " as result `ns' as text ///
                       " largest contributors at horizon " as result `step' ///
                       as text "; the last column is the total over all " ///
                       as result `K' as text " shocks."
        }
        di as text "  Entries are shares of the forecast error variance."
        di ""

        * One unit width for the whole table, so every unit truncates the same
        * way.  Sized per label, "dominant:pmetal" and "dominant:pmat" came out
        * as "dom:pmetal" and "domin:pmat" -- three spellings of one unit in a
        * single header row.  The binding constraint is the LONGEST variable
        * name among the displayed shocks, so compute that once here.
        local uwmin 99
        foreach l of local slab {
            local p = strpos("`l'", ":")
            if (`p' > 0) {
                local room = 10 - (strlen("`l'") - `p') - 1
                if (`room' < `uwmin') local uwmin = `room'
            }
        }
        if (`uwmin' < 1 | `uwmin' == 99) local uwmin ""

        local per 7
        local done 0
        while (`done' < `ns') {
            local lo = `done' + 1
            local hi = min(`done' + `per', `ns')
            local last 0
            if (`hi' == `ns') local last 1
            local ncol = `hi' - `lo' + 1 + `last'
            local w = 10 + 11 * `ncol'
            di as text "{hline `w'}"
            di as text %-9s "  horizon" _continue
            forvalues c = `lo'/`hi' {
                local l : word `c' of `slab'
                * _gvar_ablab, not abbrev(): at width 10 abbrev() maps both
                * dominant:poil and dominant:pmetal to "dominant~l", so this
                * table printed two different shocks under one heading.
                _gvar_ablab "`l'" 10 "`uwmin'"
                di as text %11s "`_ablab'" _continue
            }
            if (`last') di as text %11s "TOTAL" _continue
            di ""
            di as text "{hline `w'}"
            foreach h of local keep {
                local row = `h' + 1
                di as text "  " %-7.0f `h' _continue
                forvalues c = `lo'/`hi' {
                    di as result %11.4f `=`R'[`row', `c']' _continue
                }
                if (`last') {
                    di as result %11.4f `=`R'[`row', `=`ns'+1']' _continue
                }
                di ""
            }
            di as text "{hline `w'}"
            di ""
            local done = `hi'
        }

        if (`sg' == 0) {
            di as text "  The generalized decomposition does not sum to one:"
            di as text "  the shocks are correlated, so the shares overlap."
            di as text "  A TOTAL well above one signals strong contemporaneous"
            di as text "  correlation among the shocks.  Pesaran & Shin (1998)"
            di as text "  define each share against its own shock variance;"
            di as text "  use {bf:type(oirf)} for shares that sum to one."
        }
        else {
            di as text "  Orthogonal shocks: the shares sum to one at every"
            di as text "  horizon, up to rounding."
        }
        di ""
    }

    if ("`graph'" != "") {
        _gvar_fevd_graph `R' `step' `ns' "`slab'" "`vlab'" "`name'"
    }

    if ("`saving'" != "") {
        matrix `saving' = `R'
    }
    return matrix fevd = `R', copy
    return matrix fevdfull = `F', copy
    return local  variable "`vlab'"
    return local  shocks   "`slab'"
    return local  type     "`type'"
    return scalar step     = `step'
end

* ---------------------------------------------------------------------------
* Stacked contribution plot in the light palette
* ---------------------------------------------------------------------------
program define _gvar_fevd_graph
    version 14.0
    args R step ns slab vlab gname

    if ("`gname'" == "") local gname gvar_fevd

    _gvar_palette
    local reg "`r(region)'"
    * NUMBERED locals, not one list.  _gvar_palette returns each colour
    * as an RGB triple, so accumulating eight of them into a single macro
    * gives twenty-four numbers and -word c of- returns the c-th NUMBER.
    * Stata then reports "named style 31 not found in class color" and
    * silently uses its default, which is why the plot looked fine.
    forvalues c = 1/8 {
        local col`c' "`r(c`c')'"
    }

    preserve
    clear
    qui set obs `=`step'+1'
    qui gen int horizon = _n - 1
    local nshow = min(`ns', 8)
    local plots ""
    local legs  ""
    forvalues c = 1/`nshow' {
        qui gen double y`c' = .
        forvalues h = 1/`=`step'+1' {
            qui replace y`c' = `R'[`h', `c'] in `h'
        }
        local cc "`col`c''"
        * Compound quotes here, not a backslash before the inner quote:
        * Stata has no backslash escape inside a double-quoted string, so
        * that form arrives at twoway as a literal backslash plus an
        * unbalanced quote and the command dies with unmatched quote.
        local plots `"`plots' (line y`c' horizon, lcolor("`cc'") lwidth(medthick))"'
        local l : word `c' of `slab'
        local legs `"`legs' `c' "`l'""'
    }

    twoway `plots' ///
        , `reg' ///
          ylabel(, angle(0) labsize(small) grid glcolor(gs15)) ///
          xlabel(0(4)`step', labsize(small)) ///
          ytitle("share of forecast error variance", size(small)) ///
          xtitle("horizon (periods)", size(small)) ///
          title("Variance decomposition of `vlab'", ///
                size(medium) color(black)) ///
          legend(order(`legs') size(vsmall) rows(2) region(lcolor(gs12))) ///
          name(`gname', replace)
    restore
end
