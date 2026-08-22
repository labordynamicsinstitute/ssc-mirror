*! _gvar_util 1.0.1  21aug2026
*! Shared table, formatting and graph-palette utilities for the gvar package.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane

program define _gvar_util
    version 14.0
end

* ---------------------------------------------------------------------------
* Resolve a specification of elements of the global vector x_t.
*
* Accepts, space separated:
*     unit:var      one element, e.g.  usa:r
*     unit:*        every variable of that unit
*     *:var         that variable wherever it appears  (same as bare  var)
*     var           shorthand for  *:var
*
* Returns r(pos) with the 1-based positions in x_t, r(n) with how many, and
* r(labels) with "unit:var" for each, in the order of x_t rather than the
* order typed, so every table in the package reads the same way.
* ---------------------------------------------------------------------------
program define _gvar_xsel, rclass
    version 14.0
    args spec

    mata: st_local("K",  strofreal(gvar_getK()))
    mata: st_local("xn", invtokens(gvar_getxname()'))
    mata: st_local("xc", invtokens(gvar_getxcname()'))

    local pos ""
    local lab ""

    foreach tok of local spec {
        local nc = strpos("`tok'", ":")
        if (`nc' == 0) {
            local wu "*"
            local wv "`tok'"
        }
        else {
            local wu = substr("`tok'", 1, `nc' - 1)
            local wv = substr("`tok'", `nc' + 1, .)
        }
        if ("`wu'" == "") local wu "*"
        if ("`wv'" == "") local wv "*"

        local hit 0
        forvalues j = 1/`K' {
            local cj : word `j' of `xc'
            local vj : word `j' of `xn'
            local ok 1
            if ("`wu'" != "*" & "`wu'" != "`cj'") local ok 0
            if ("`wv'" != "*" & "`wv'" != "`vj'") local ok 0
            if (`ok') {
                local hit 1
                local already : list posof "`j'" in pos
                if (`already' == 0) local pos "`pos' `j'"
            }
        }
        if (`hit' == 0) {
            di as err "no element of the global vector matches {bf:`tok'}"
            di as err "use {bf:unit:variable}, {bf:unit:*}, {bf:*:variable}" ///
                      " or a bare variable name"
            exit 111
        }
    }

    * sort into x_t order so tables are always in the model's own ordering
    local sorted ""
    forvalues j = 1/`K' {
        local in : list posof "`j'" in pos
        if (`in' > 0) local sorted "`sorted' `j'"
    }
    local sorted = trim("`sorted'")

    foreach j of local sorted {
        local cj : word `j' of `xc'
        local vj : word `j' of `xn'
        local lab "`lab' `cj':`vj'"
    }

    local nsel : word count `sorted'
    return local  pos    "`sorted'"
    return local  labels = trim("`lab'")
    return scalar n      = `nsel'
end

* ---------------------------------------------------------------------------
* Reordering of the global vector, following reorder_GVAR.m.
*
* A structural GIRF orthogonalises the LEADING block of x(t), so which
* variables sit at the front IS the identifying assumption.  The Toolbox
* takes two inputs from the interface file:
*     firstcountries   the units to move to the front, in order
*     newordervars     the variable order inside each of those units,
*                      one block per unit, blank-separated
* and derives  sumk0 = sum of k_i over those units,  which becomes the size
* of the block that irf.m factors.  n0 is therefore DERIVED, never typed.
*
* Here:  first(usa euro)
*        vorder(r Dp y eq lr poil pmat pmetal ; y Dp eq ep r lr)
* with ";" separating one block per unit, matching the blank separators of
* the Excel sheet.  Units not listed keep their own order, after the listed
* ones, exactly as reorder_GVAR.m appends them.
*
* Returns r(ord) the permutation as a numlist, and r(n0) = sumk0.
* ---------------------------------------------------------------------------
program define _gvar_reorder, rclass
    version 14.0
    args firstspec vorderspec

    mata: st_local("K",  strofreal(gvar_getK()))
    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))
    mata: st_local("xn", invtokens(gvar_getxname()'))
    mata: st_local("xc", invtokens(gvar_getxcname()'))

    * ---- the units that go first, in the order given -----------------------
    local funits ""
    foreach u of local firstspec {
        local p : list posof "`u'" in cn
        if (`p' == 0) {
            di as err "first(): unit {bf:`u'} is not in the model"
            exit 111
        }
        local dup : list posof "`p'" in funits
        if (`dup' > 0) {
            di as err "first(): unit {bf:`u'} is listed twice"
            exit 198
        }
        local funits "`funits' `p'"
    }
    local funits = trim("`funits'")
    local nf : word count `funits'

    * ---- the variable order inside each of them ----------------------------
    local nblk 0
    if ("`vorderspec'" != "") {
        local rest "`vorderspec'"
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
            local ++nblk
            local vblk`nblk' "`blk'"
        }
        if (`nblk' != `nf') {
            di as err "vorder() has `nblk' block(s) but first() names `nf' unit(s)"
            di as err "separate one block per unit with {bf:;}"
            exit 198
        }
    }

    * ---- build the new ordering of x(t) ------------------------------------
    local ord ""
    local n0  0
    local b   0

    foreach i of local funits {
        local ++b
        * this unit's positions in x(t), in the model's own order
        local own ""
        forvalues j = 1/`K' {
            local cj : word `j' of `xc'
            local uu : word `i' of `cn'
            if ("`cj'" == "`uu'") local own "`own' `j'"
        }
        local own = trim("`own'")
        local k_i : word count `own'
        local n0 = `n0' + `k_i'

        if (`nblk' == 0) {
            local ord "`ord' `own'"
        }
        else {
            local want "`vblk`b''"
            local nw : word count `want'
            if (`nw' != `k_i') {
                local uu : word `i' of `cn'
                di as err "vorder() block `b' lists `nw' variable(s) but unit" ///
                          " {bf:`uu'} has `k_i'"
                exit 198
            }
            foreach v of local want {
                local hit 0
                foreach j of local own {
                    local vj : word `j' of `xn'
                    if ("`vj'" == "`v'") {
                        local ord "`ord' `j'"
                        local hit 1
                        continue, break
                    }
                }
                if (`hit' == 0) {
                    local uu : word `i' of `cn'
                    di as err "vorder(): {bf:`v'} is not endogenous for unit" ///
                              " {bf:`uu'}"
                    exit 111
                }
            }
        }
    }

    * ---- every other unit, in the model's own order ------------------------
    forvalues j = 1/`K' {
        local in : list posof "`j'" in ord
        if (`in' == 0) local ord "`ord' `j'"
    }
    local ord = trim("`ord'")

    local nord : word count `ord'
    if (`nord' != `K') {
        di as err "internal: permutation has `nord' elements, expected `K'"
        exit 498
    }

    return local  ord "`ord'"
    return scalar n0 = `n0'
    return scalar nfirst = `nf'
end

* ---------------------------------------------------------------------------
* Covariance handling shared by every dynamic-analysis subcommand.
*
* Follows gvar.m exactly:
*     pe_varcov_tx = transform_varcov(pe_meth, pe_country_exc, Sigma_zeta, .)
*     pe_varcov    = ShrinkageCorrLstar(pe_varcov_tx, cols(zeta), lambda)
* transformation first, shrinkage second, and the positive-definiteness test
* applied only when an orthogonalisation is requested (sgirfflag == 2).
*
*   vcov(sample)              pe_meth = 1   the estimated matrix
*   vcov(blockdiag)           pe_meth = 2   no cross-unit covariance
*   vcov(blockdiag unit)      pe_meth = 3   ... except for that unit
*   shrink                    use_shrinkedvcv = 1, lambda computed internally
*   lambda(#)                 arbitrarylambda
*
* Returns r(vmeth), r(vexcl), r(shr), r(lam), r(lamused).
* ---------------------------------------------------------------------------
program define _gvar_shrinkopt, rclass
    version 14.0
    args sg n0 vcovspec shrink lambda

    * ---- transformation ----------------------------------------------------
    local vmeth 1
    local vexcl 0
    if ("`vcovspec'" != "") {
        gettoken vkind vrest : vcovspec
        local vkind = lower("`vkind'")
        if ("`vkind'" == "sample") {
            local vmeth 1
        }
        else if ("`vkind'" == "blockdiag") {
            local vmeth 2
            local vrest = trim("`vrest'")
            if ("`vrest'" != "") {
                local vmeth 3
                mata: st_local("cn", invtokens(gvar_getcname()'))
                local vexcl : list posof "`vrest'" in cn
                if (`vexcl' == 0) {
                    di as err "vcov(blockdiag `vrest'): unit {bf:`vrest'}" ///
                              " is not in the model"
                    exit 111
                }
            }
        }
        else {
            di as err "vcov() must be {bf:sample}, {bf:blockdiag} or" ///
                      " {bf:blockdiag }{it:unit}"
            exit 198
        }
    }

    * ---- shrinkage ---------------------------------------------------------
    local shr 0
    local lam .
    if ("`shrink'" != "")  local shr 1
    if ("`lambda'" != "" & "`lambda'" != "-1") {
        if (`lambda' < 0 | `lambda' > 1) {
            di as err "lambda() must lie between 0 and 1"
            exit 198
        }
        local shr 1
        local lam `lambda'
    }

    * ---- the positive-definiteness gate, as in gvar.m ----------------------
    * Only an orthogonalisation needs a Cholesky factor.  The generalized
    * responses do not, which is why they are what the GVAR literature
    * reports for systems this large.
    if (`sg' == 2 | `sg' == 1) {
        mata: st_local("pd", strofreal(gvar_sigmapd(`vmeth', `vexcl', ///
                                                    `shr', `lam', `n0')))
        if ("`pd'" != "1") {
            mata: st_local("KK", strofreal(gvar_getK()))
            mata: st_local("rk", strofreal(gvar_szetarank()))
            di as err "the covariance matrix is not positive definite over" ///
                      " the leading `n0' variables"
            di as text "  Sigma_zeta is " as result "`KK'" as text " by " ///
                       as result "`KK'" as text " with rank " ///
                       as result "`rk'" as text ": with only that many"
            di as text "  quarters it cannot have full rank, so no Cholesky" ///
                       " factor exists."
            di as text "  This is the case the GVAR Toolbox stops on too." ///
                       "  Its remedy, and"
            di as text "  the one here, is to shrink the correlation matrix" ///
                       " towards the"
            di as text "  identity:"
            di as text ""
            di as text "      {bf:. gvar irf, ... shrink}" ///
                       "            (intensity chosen internally)"
            di as text "      {bf:. gvar irf, ... lambda(0.2)}" ///
                       "      (intensity set by hand)"
            di as text ""
            di as text "  Or stay with {bf:type(girf)}, which needs no" ///
                       " Cholesky factor and is"
            di as text "  what Dees, di Mauro, Pesaran & Smith (2007) report."
            exit 506
        }
    }

    return scalar vmeth = `vmeth'
    return scalar vexcl = `vexcl'
    return scalar shr   = `shr'
    return local  lam   "`lam'"
end

* ---------------------------------------------------------------------------
* Significance stars from a p-value
* ---------------------------------------------------------------------------
program define _gvar_stars, rclass
    version 14.0
    args p
    local s ""
    if ("`p'" != "" & "`p'" != ".") {
        if (`p' < 0.01)      local s "***"
        else if (`p' < 0.05) local s "**"
        else if (`p' < 0.10) local s "*"
    }
    return local stars "`s'"
end

* ---------------------------------------------------------------------------
* Stars from a statistic against a critical value (used where the sources
* supply a 95% critical value rather than a p-value)
* ---------------------------------------------------------------------------
program define _gvar_starcv, rclass
    version 14.0
    args stat cv
    local s ""
    if ("`stat'" != "." & "`cv'" != "." & "`cv'" != "") {
        if (abs(`stat') > abs(`cv')) local s "*"
    }
    return local stars "`s'"
end

* ---------------------------------------------------------------------------
* A horizontal rule of a given width
* ---------------------------------------------------------------------------
program define _gvar_hline
    version 14.0
    args w
    if ("`w'" == "") local w 78
    di as text "{hline `w'}"
end

* ---------------------------------------------------------------------------
* A centred table title inside a box
* ---------------------------------------------------------------------------
* Called as:  _gvar_title "some text" [width]
* -args- rather than -syntax- so that titles may freely contain commas,
* colons, parentheses and equals signs.
program define _gvar_title
    version 14.0
    args t width
    if ("`width'" == "") local width 78
    local n = length("`t'")
    local pad = int((`width' - `n') / 2)
    if (`pad' < 0) local pad 0
    di ""
    di as text "{hline `width'}"
    di as text _col(`=`pad'+1') as result "`t'"
    di as text "{hline `width'}"
end

* ---------------------------------------------------------------------------
* Truncate / pad a string to a fixed display width
* ---------------------------------------------------------------------------
program define _gvar_fit, rclass
    version 14.0
    args s w
    local s = trim("`s'")
    if (length("`s'") > `w') {
        local s = substr("`s'", 1, `w')
    }
    return local out "`s'"
end

* ---------------------------------------------------------------------------
* The light graph palette.  No dark fills anywhere: every colour below is a
* mid or light tone chosen to stay legible on a white plot region and to print
* acceptably in greyscale.
* ---------------------------------------------------------------------------
program define _gvar_palette, rclass
    version 14.0

    * primary series -- medium blue
    return local c1     "31 119 180"
    * band fill -- light blue
    return local band   "174 199 232"
    * secondary series
    return local c2     "255 152 150"     // light red
    return local c3     "152 223 138"     // light green
    return local c4     "255 187 120"     // light orange
    return local c5     "197 176 213"     // light purple
    return local c6     "158 218 229"     // light cyan
    return local c7     "219 219 141"     // light olive
    return local c8     "247 182 210"     // light pink
    * reference lines
    return local zero   "150 150 150"
    return local grid   "224 224 224"
    * contribution signs (historical decompositions, net spillovers)
    return local pos    "152 223 138"
    return local neg    "255 187 120"
    * sequential heat ramp, low -> high (all light to medium)
    return local h1     "247 251 255"
    return local h2     "222 235 247"
    return local h3     "198 219 239"
    return local h4     "158 202 225"
    return local h5     "107 174 214"
    return local h6     " 66 146 198"
    * a common region/graph style applied by every plot in the package
    return local region "graphregion(color(white) lwidth(none)) plotregion(color(white) lcolor(none)) bgcolor(white)"
    return local band_o "45"
end

* ---------------------------------------------------------------------------
* Standard error message when a step has not been run yet
* ---------------------------------------------------------------------------
program define _gvar_require
    version 14.0
    args what
    if ("`what'" == "setup") {
        capture mata: st_local("ok", strofreal(gvar_isbuilt()))
        if (_rc | "`ok'" != "1") {
            di as err "no GVAR in memory; run {bf:gvar setup} first"
            exit 301
        }
    }
    if ("`what'" == "foreign") {
        _gvar_require setup
        * NOTE: never touch gvar_MODEL.<member> from the command level -- Mata
        * cannot type an external struct outside a function and reports
        * "transmorphic found where struct expected".  Always go via an
        * accessor compiled inside the engine.
        mata: st_local("ok", strofreal(gvar_hasforeign()))
        if ("`ok'" != "1") {
            di as err "foreign-specific variables have not been built; run {bf:gvar foreign} first"
            exit 301
        }
    }
    if ("`what'" == "estimate") {
        _gvar_require foreign
        mata: st_local("ok", strofreal(gvar_isestimated()))
        if ("`ok'" != "1") {
            di as err "the country models have not been estimated; run {bf:gvar estimate} first"
            exit 301
        }
    }
    * PROVENANCE.  This check has NO counterpart in gvar.m, because the Toolbox
    * runs specification, estimation and stacking as one script and so cannot
    * reach the state at all.  It exists only because this package exposes the
    * flow as separate user commands.  What IS from the source is the principle:
    * gvar.m:978-1010 tests the declared dominant-unit flag against what the
    * specification actually implies (duerror 1 and 2) and stops with an
    * explanatory message rather than continuing into a dimension error.  The
    * two duerror cases themselves are implemented where they belong, in
    * gvar_setflags -- see the dumark loop in _gvar_mata.ado.  Nothing here
    * changes any computation.
    *
    * Declared by gvar setup, but not yet estimated by gvar dominant.  These are
    * two different flags and the gap between them is reachable: gvar setup's
    * dominant() sets dumark, which puts the dominant variables into x_t and so
    * into K, while hasdu is set only when gvar dominant actually fits the block.
    * Stacking in between builds a K x K system out of country blocks that
    * account for K - ki_du rows of it, and gvar_stack() answers with a bare
    * "3200 conformability error" naming a function the user never called.
    * gvar wetest, gvar coint and gvar diag are all fine in this state -- they
    * are per-country -- so this cannot live in _gvar_require estimate; it
    * belongs to whatever is about to stack.
    if ("`what'" == "dominant") {
        _gvar_require estimate
        mata: st_local("dm", strofreal(gvar_hasdumark()))
        mata: st_local("du", strofreal(gvar_hasdu()))
        if ("`dm'" == "1" & "`du'" != "1") {
            di as err "{bf:gvar setup} declared a dominant block with"
            di as err "{bf:dominant()}, so its variables are part of the global"
            di as err "vector, but the block itself has not been estimated yet."
            di as err "Stacking now would build a system with more rows than the"
            di as err "country models fill."
            di as err ""
            di as err "Run {bf:gvar dominant} first, e.g."
            di as err "    {bf:gvar dominant, lags(2) flags(1) case(4) rank(1)}"
            di as err ""
            di as err "See {bf:help gvar_dominant}.  If you meant the"
            di as err "Dees-di Mauro-Pesaran-Smith device instead -- one country"
            di as err "owning the global variable -- re-run {bf:gvar setup} with"
            di as err "{bf:gendog()} rather than {bf:dominant()}; that needs no"
            di as err "separate estimation step."
            exit 301
        }
    }
    if ("`what'" == "solve") {
        _gvar_require estimate
        mata: st_local("ok", strofreal(gvar_issolved()))
        if ("`ok'" != "1") {
            di as err "the GVAR has not been solved; run {bf:gvar solve} first"
            exit 301
        }
    }
    * The cointegration structure, for the commands that are defined ON it.
    * gvar bayes fits a VARX in LEVELS and imposes no rank, so after it beta and
    * alpha hold whatever an earlier gvar estimate left behind -- stale values
    * that would produce a plausible-looking persistence profile for a model
    * that has no cointegrating relations at all.  Refusing is the only honest
    * answer; BGVAR has no counterpart to these commands for the same reason.
    if ("`what'" == "vecmx") {
        _gvar_require estimate
        mata: st_local("et", gvar_getesttype())
        if ("`et'" != "vecmx") {
            di as err "this command needs the cointegrating vectors, which"
            di as err "come from reduced-rank ML.  The model in memory was fit"
            di as err "by {bf:gvar bayes} as a VARX in levels (esttype `et'),"
            di as err "so it imposes no cointegrating rank and there is no beta"
            di as err "to test or to profile."
            di as err ""
            di as err "Run {bf:gvar estimate} for the VECMX* version of the"
            di as err "model, or use the reduced-form tools -- {bf:gvar irf},"
            di as err "{bf:gvar fevd}, {bf:gvar hd}, {bf:gvar forecast} -- which"
            di as err "work from either."
            exit 301
        }
    }
end

* ---------------------------------------------------------------------------
* Shared diagnostic scan plot.
*
* Four of the specification tests have the same shape -- a statistic per
* (unit, variable) against a critical value -- so they share one picture
* rather than four near-identical ones:
*
*   gvar wetest   F against its 5% F critical value
*   gvar coint    trace or max-eigenvalue against the PSS critical value
*   gvar unitroot the test statistic against its critical value
*   gvar contemp  the elasticity against zero, with a confidence interval
*
* The plot puts the statistic on the vertical axis and the observation index
* on the horizontal, so 136 points stay readable, and separates them by
* colour according to whether each one crosses its own cutoff.  Per-row
* cutoffs are drawn as their own series rather than as one line, because in
* gvar coint and gvar unitroot the critical value differs from row to row.
*
* MAT columns: 1 group (for the axis ticks), 2 the statistic, 3 its cutoff
* (missing where there is none), 4 a flag, 1 if crossing the cutoff is a
* REJECTION worth marking.
* ---------------------------------------------------------------------------
program define _gvar_dotplot
    version 14.0
    args MAT nr glab title subtitle ytitle name below

    _gvar_palette
    local c1   "`r(c1)'"
    local c2   "`r(c2)'"
    local grid "`r(grid)'"
    local reg  "`r(region)'"
    local pos  "`r(pos)'"
    local neg  "`r(neg)'"

    local nm "gvar_scan"
    if ("`name'" != "") local nm "`name'"

    * below = 1 when a statistic BELOW its cutoff is the rejection, as for the
    * unit-root tests where the statistic is negative
    if ("`below'" == "") local below 0

    preserve
    quietly {
        clear
        svmat double `MAT', names(col)
        rename c1 grp
        rename c2 stat
        rename c3 cut
        capture rename c4 flag
        capture confirm variable flag
        if (_rc) gen byte flag = 1

        gen long idx = _n
        gen byte rej = 0
        * below = 0  statistic ABOVE its cutoff is the rejection
        *         1  statistic BELOW it is, as for the unit-root tests where
        *            the statistic is negative
        *         2  the flag column decides on its own, for a two-sided
        *            comparison the cutoff cannot express
        if (`below' == 2)      replace rej = 1 if flag == 1
        else if (`below' == 1) replace rej = 1 if stat < cut & cut < . & flag == 1
        else                   replace rej = 1 if stat > cut & cut < . & flag == 1

        * A missing statistic has rej == 0 and would sit silently in the
        * "within" series as an unplotted point, so the two are separated and
        * the count of undrawable rows is reported.  A plot that quietly drops
        * rows is worse than one that says how many it dropped.
        gen double s_ok  = stat if rej == 0 & stat < . & cut < .
        gen double s_bad = stat if rej == 1
        count if rej == 1
        local nrej = r(N)
        count if stat >= . | cut >= .
        local nmiss = r(N)
        count
        local ntot = r(N)

        * ticks at the first row of each group, labelled with the group name
        local xlab ""
        local g 0
        forvalues q = 1/`nr' {
            local gq = grp[`q']
            if (`gq' != `g') {
                local g `gq'
                local l : word `g' of `glab'
                if ("`l'" != "") {
                    local xlab `"`xlab' `q' "`=abbrev("`l'", 7)'""'
                }
            }
        }

        * the cutoff series: a step line, since it can differ by row
        local cl ""
        count if cut < .
        if (r(N) > 0) {
            local cl `"(line cut idx, lcolor("`c2'") lpattern(dash) lwidth(medthin) connect(stairstep))"'
        }

        local lopt `"legend(order(2 "within" 3 "crosses the cutoff" 1 "cutoff") rows(1) size(vsmall) region(lcolor(none)) position(6))"'
        if (`nrej' == 0) {
            local lopt `"legend(order(2 "within" 1 "cutoff") rows(1) size(vsmall) region(lcolor(none)) position(6))"'
        }

        twoway `cl'                                                          ///
               (scatter s_ok idx, msymbol(o) msize(small)                    ///
                    mcolor("`c1'%70"))                                       ///
               (scatter s_bad idx, msymbol(O) msize(small)                   ///
                    mcolor("`neg'") mlcolor("`c2'") mlwidth(vthin))          ///
               , `reg'                                                       ///
                 ylabel(, angle(0) labsize(small) grid glcolor("`grid'"))    ///
                 xlabel(`xlab', labsize(vsmall) angle(90) noticks)           ///
                 ytitle("`ytitle'", size(small))                             ///
                 xtitle("")                                                  ///
                 title("`title'", size(medium) color(black))                 ///
                 subtitle("`subtitle'", size(small) color(black))            ///
                 `lopt'                                                      ///
                 name(`nm', replace)
    }
    restore

    di as text "  graph saved as {bf:`nm'}" _continue
    di as text "  (" as result `nrej' as text " of " as result `ntot' ///
       as text " marked" _continue
    if (`nmiss' > 0) {
        di as text ", " as result `nmiss' as text " not computed" _continue
    }
    di as text ")"

    * the caller can check that nothing vanished
    global GVAR_dotplot_n     `ntot'
    global GVAR_dotplot_rej   `nrej'
    global GVAR_dotplot_miss  `nmiss'
end
* ---------------------------------------------------------------------------
* A readable dated horizontal axis for a T-period window.
*
* Every time plot in the package labelled its x axis 1, 18, 35 ... -- a period
* index, which no journal figure uses.  The model already carries what is
* needed: gvar_gettvals() holds the Traw values of the time variable and freq
* records the frequency.
*
* Two things have to be right, and each fails while still looking plausible.
*
* ALIGNMENT.  A decomposition or a cycle covers T periods, and T is usually
* SHORTER than Traw because the lags are consumed at the START of the sample.
* The window therefore ENDS where the data end, so period 1 carries
* tvals[Traw - T + 1].  Using tvals[1] shifts the whole figure left by the lag
* order and draws a perfectly convincing picture of the wrong dates.
*
* LEGIBILITY.  A %tq label is six characters.  Eight of them across a 35-year
* span run together as 1980q11985q11990q1 -- the dates were correct and
* unreadable.  So the ticks are placed on YEAR boundaries at a round number of
* years apart, and labelled with the year alone (%tqCY and friends).
*
* Stata's date encodings are consecutive integers and the panel is balanced, so
* the date for period s is r(t0) + s - 1.  Returning that rather than a
* variable lets a caller in wide layout and one in long layout share this.
*
* Returns
*     r(t0)    date value of period 1 of the window
*     r(fmt)   storage format for the variable, e.g. %tq  (empty if unknown)
*     r(fmtc)  compact display format for the axis, e.g. %tqCY
*     r(xlab)  a ready-made numlist for xlabel(), year-aligned
*     r(ok)    1 if real dates were found; 0 means fall back to the index
* ---------------------------------------------------------------------------
program define _gvar_xtime, rclass
    version 14.0
    args T

    local ok 0
    local fmt ""
    local fmtc ""
    local xlab ""
    local t0 1

    capture mata: st_local("fr", strofreal(gvar_getfreq()))
    if (_rc) local fr 0
    if ("`fr'" == "1")   local fmt "%ty"
    if ("`fr'" == "4")   local fmt "%tq"
    if ("`fr'" == "12")  local fmt "%tm"
    if ("`fr'" == "52")  local fmt "%tw"
    if ("`fr'" == "365") local fmt "%td"

    tempname TV
    capture mata: st_matrix("`TV'", gvar_gettvals())
    if (!_rc & "`fmt'" != "") {
        local Traw = rowsof(`TV')
        if (`Traw' >= `T' & `T' > 0) {
            local t0 = `TV'[`=`Traw' - `T' + 1', 1]
            local ok 1
        }
    }
    if (!`ok') {
        return scalar t0 = 1
        return scalar ok = 0
        return local fmt  ""
        return local fmtc ""
        return local xlab ""
        exit
    }

    * ---- the axis ----------------------------------------------------------
    local fmtc "`fmt'"
    if ("`fmt'" != "%ty") local fmtc "`fmt'CY"

    * a round number of years, giving at most about eight ticks
    local nyr = `T' / `fr'
    local sy 1
    foreach cand in 1 2 5 10 20 25 50 {
        if (`nyr' / `sy' > 8) local sy `cand'
    }
    local step = `sy' * `fr'

    * first tick on a year boundary at or after t0.  In every Stata date
    * encoding except %ty, period 0 of a year satisfies mod(t, freq) == 0.
    local first = `t0'
    if ("`fmt'" != "%ty") {
        local first = `t0' + mod(`fr' - mod(`t0', `fr'), `fr')
    }
    local last = `t0' + `T' - 1
    if (`first' > `last') local first = `t0'
    local xlab "`first'(`step')`last'"

    return scalar t0   = `t0'
    return scalar ok   = 1
    return local  fmt  "`fmt'"
    return local  fmtc "`fmtc'"
    return local  xlab "`xlab'"
end

* ---------------------------------------------------------------------------
* Abbreviate a unit:variable label without losing the variable.
* ---------------------------------------------------------------------------
* abbrev() truncates from the right, so at width 10 both "dominant:poil" and
* "dominant:pmetal" collapse to "dominant~l" -- two DIFFERENT shocks under one
* header, which appeared in gvar fevd the first time the demo was run with a
* dominant unit.  A table cannot have two identical column headings.
*
* The variable is what distinguishes these, so it is kept whole and the unit
* prefix absorbs the truncation: "dom:poil", "dom:pmetal".  Only if the variable
* alone will not fit does this fall back on plain abbrev().
program define _gvar_ablab
    version 14.0
    args lab w uw

    * NOT rclass, and it returns through c_local rather than return local.
    * An rclass program CLEARS r() when it is called, and several callers read
    * r(sdc), r(sdp), r(share) or r(irf) from a previous command on the line
    * immediately after this one.  The first version was rclass and blanked the
    * whole gvar tcdecomp table -- every statistic printed as missing -- because
    * the helper wiped the results it was supposed to be labelling.
    *
    * uw is the OPTIONAL unit width.  Without it the unit absorbs whatever room
    * the variable leaves, which is unambiguous but inconsistent ACROSS a table:
    * at w = 10 "dominant:pmetal" became "dom:pmetal" while "dominant:pmat"
    * became "domin:pmat", so one header row carried three spellings of the same
    * unit.  A caller that knows its whole label set should compute one uw for the
    * table -- see _gvar_fevd.ado -- so every unit truncates identically.
    local p = strpos("`lab'", ":")
    if (`p' == 0) {
        c_local _ablab = abbrev("`lab'", `w')
        exit
    }
    local u = substr("`lab'", 1, `p' - 1)
    local v = substr("`lab'", `p' + 1, .)
    local room = `w' - strlen("`v'") - 1
    if ("`uw'" != "") {
        if (`uw' >= 1 & `uw' < `room') local room = `uw'
    }
    if (`room' < 1) {
        c_local _ablab = abbrev("`lab'", `w')
        exit
    }
    if (strlen("`u'") > `room') local u = substr("`u'", 1, `room')
    c_local _ablab "`u':`v'"
end
