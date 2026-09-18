*! version 1.0.0 16sep2026
*! Fine-Gray CIF plots with conventional and subdistribution risk-set summaries
*! Copyright (c) 2026 Christina Laternser; MIT License

capture program drop fgcifplot
program define fgcifplot, rclass
    version 14.2

    syntax varname(numeric) [, ///
        VALUES(numlist) ///
        RISKTIMES(numlist) ///
        RISKTABLE(string) ///
        AT(string asis) ///
        NAME(name) ///
        RISKSAVING(string) ///
        REPLACE ///
        NOGRAPH ///
        CURVEOPTS(string asis) ///
        TABLEOPTS(string asis) ///
        COMBINEOPTS(string asis) ///
        TABLEPCT(integer 0) ///
        WFORMAT(string) ]

    local groupvar `varlist'

    *-------------------------------
    * Require Fine-Gray stcrreg fit
    *-------------------------------
    if "`e(cmd)'" != "stcrreg" {
        di as err "fgcifplot must be run immediately after stcrreg"
        exit 301
    }

    * The grouping variable must contribute to the fitted model.  Otherwise
    * stcurve would not be producing group-specific model predictions even
    * though observed risk tables could still be calculated by that variable.
    local __fg_inmodel 0
    local __fg_bnames : colfullnames e(b)
    foreach __fg_bn of local __fg_bnames {
        local __fg_term = regexr("`__fg_bn'", "^[^:]*:", "")
        if "`__fg_term'" == "`groupvar'" local __fg_inmodel 1
        else if regexm("`__fg_term'", "(^|[.#])`groupvar'($|#)") local __fg_inmodel 1
    }
    if !`__fg_inmodel' {
        di as err "group variable `groupvar' is not represented in the fitted stcrreg model"
        exit 498
    }

    if e(N) != e(N_sub) {
        di as err "fgcifplot 1.0 supports one record per subject only"
        di as err "multiple-record st data are not yet supported"
        exit 459
    }

    if "`e(wtype)'" != "" {
        di as err "fgcifplot 1.0 does not yet support stset observation weights"
        exit 459
    }

    capture confirm variable _t
    if _rc {
        di as err "survival-time variable _t not found; data must remain stset"
        exit 459
    }
    capture confirm variable _t0
    if _rc {
        di as err "survival entry-time variable _t0 not found; data must remain stset"
        exit 459
    }
    capture confirm variable _d
    if _rc {
        di as err "survival failure indicator _d not found; data must remain stset"
        exit 459
    }

    tempvar __esamp __compraw __comp __cens
    quietly gen byte `__esamp' = e(sample)

    * Version 1.0 deliberately restricts validation to subjects at risk from
    * time zero.  Left truncation/delayed entry changes the Fine-Gray
    * weighting problem and is not claimed until separately validated.
    quietly count if `__esamp' & _t0 != 0
    if r(N) > 0 {
        di as err "fgcifplot 1.0 does not yet support delayed entry / left truncation"
        exit 459
    }

    *-----------------------------------------------
    * Parse stcrreg compete() specification
    * e(compete) is of form var or var==numlist
    *-----------------------------------------------
    local compspec `"`e(compete)'"'
    local compspec = strtrim(`"`compspec'"')
    if `"`compspec'"' == "" {
        di as err "could not recover compete() specification from stcrreg"
        exit 498
    }

    local eqpos = strpos(`"`compspec'"', "==")
    if `eqpos' > 0 {
        local crvar = strtrim(substr(`"`compspec'"', 1, `eqpos'-1))
        local crnums = strtrim(substr(`"`compspec'"', `eqpos'+2, .))
        capture numlist `"`crnums'"'
        if _rc {
            di as err "could not parse competing-event values from e(compete): `compspec'"
            exit 498
        }
        local crvals `r(numlist)'
        capture confirm numeric variable `crvar'
        if _rc {
            di as err "competing-event variable `crvar' is not numeric or no longer exists"
            exit 111
        }
        quietly gen byte `__compraw' = 0 if `__esamp'
        foreach c of numlist `crvals' {
            quietly replace `__compraw' = 1 if `__esamp' & `crvar' == `c'
        }
    }
    else {
        local crvar `compspec'
        capture confirm numeric variable `crvar'
        if _rc {
            di as err "competing-event variable `crvar' is not numeric or no longer exists"
            exit 111
        }
        quietly gen byte `__compraw' = (`crvar' != 0 & `crvar' < .) if `__esamp'
    }

    * A record cannot simultaneously be the failure of interest and a
    * competing event.  Reject inconsistent bare indicators/data mutations
    * rather than silently retaining a failure as a prior competing event.
    quietly count if `__esamp' & _d == 1 & `__compraw' == 1
    if r(N) > 0 {
        di as err "competing-event specification overlaps the failure-of-interest indicator"
        di as err "ensure competing events are coded only on records with _d==0"
        exit 459
    }
    quietly gen byte `__comp' = (`__compraw' == 1 & _d == 0) if `__esamp'
    quietly gen byte `__cens' = (`__esamp' & _d == 0 & `__comp' == 0)

    *-------------------------------
    * Group values and labels
    *-------------------------------
    if `"`values'"' == "" {
        quietly levelsof `groupvar' if `__esamp' & `groupvar' < ., local(values)
    }
    if `"`values'"' == "" {
        di as err "no nonmissing values of `groupvar' in the estimation sample"
        exit 2000
    }

    local ng : word count `values'
    if `ng' < 1 {
        di as err "values() must identify at least one group"
        exit 198
    }
    if `ng' > 12 {
        di as txt "note: `ng' groups requested; the risk table may be crowded"
    }

    foreach g of numlist `values' {
        quietly count if `__esamp' & `groupvar' == `g'
        if r(N) == 0 {
            di as err "group value `g' has no observations in the stcrreg estimation sample"
            exit 2000
        }
    }

    local vallab : value label `groupvar'
    local legorder ""
    local grouplabels ""
    local gi = 0
    foreach g of numlist `values' {
        local ++gi
        if `"`vallab'"' != "" {
            local glab : label `vallab' `g'
        }
        else local glab `"`g'"'
        if `"`glab'"' == "" local glab `"`g'"'
        local glab`gi' `"`glab'"'
        local legorder `"`legorder' `gi' "`glab'""'
        local grouplabels `"`grouplabels'|`glab'"'
    }

    *-------------------------------
    * Risk-table types
    *-------------------------------
    local rtypes = lower(strtrim(`"`risktable'"'))
    if `"`rtypes'"' == "" local rtypes "conventional"
    if `"`rtypes'"' == "all" local rtypes "conventional retained weighted"

    local showtable = 1
    if `"`rtypes'"' == "none" local showtable = 0

    if `showtable' {
        local cleanrt ""
        foreach r of local rtypes {
            if !inlist(`"`r'"', "conventional", "retained", "weighted") {
                di as err "risktable() accepts conventional, retained, weighted, all, or none"
                exit 198
            }
            if strpos(" `cleanrt' ", " `r' ") == 0 local cleanrt "`cleanrt' `r'"
        }
        local rtypes = strtrim("`cleanrt'")
    }

    *-------------------------------
    * Risk-table time grid
    *-------------------------------
    if `"`risktimes'"' == "" {
        quietly summarize _t if `__esamp', meanonly
        local maxt = r(max)
        if missing(`maxt') | `maxt' <= 0 {
            di as err "cannot determine a positive follow-up range"
            exit 459
        }
        local step = `maxt'/4
        local risktimes "0 `step' `=`step'*2' `=`step'*3' `maxt'"
    }

    capture numlist `"`risktimes'"', sort
    if _rc {
        di as err "invalid risktimes()"
        exit 198
    }
    local risktimes `r(numlist)'
    local nt : word count `risktimes'
    if `nt' < 1 {
        di as err "risktimes() must contain at least one time"
        exit 198
    }

    local tmin : word 1 of `risktimes'
    local tmax : word `nt' of `risktimes'

    if `tmin' < 0 {
        di as err "risktimes() may not contain negative times"
        exit 198
    }

    if `"`wformat'"' == "" local wformat "%9.1f"

    *-----------------------------------------------------------
    * Layout rule: risk-table area is never more than one-third
    * of the combined figure.  Auto allocation gives smaller
    * tables when fewer risk summaries are requested.
    *-----------------------------------------------------------
    if `tablepct' == 0 {
        if !`showtable' local tablepct = 0
        else {
            local ntypes_auto : word count `rtypes'
            if `ntypes_auto' == 1 local tablepct = 22
            else if `ntypes_auto' == 2 local tablepct = 28
            else local tablepct = 33
        }
    }
    if `showtable' & (`tablepct' < 15 | `tablepct' > 33) {
        di as err "tablepct() must be between 15 and 33"
        exit 198
    }
    local curvepct = 100 - `tablepct'

    *----------------------------------------
    * Build matrices of group values / times
    *----------------------------------------
    tempname GVALS RTIMES MCONV MRET MWGT MG
    matrix `GVALS' = J(1, `ng', .)
    local j = 0
    foreach g of numlist `values' {
        local ++j
        matrix `GVALS'[1,`j'] = `g'
    }

    matrix `RTIMES' = J(1, `nt', .)
    local j = 0
    foreach tt of numlist `risktimes' {
        local ++j
        matrix `RTIMES'[1,`j'] = `tt'
    }

    *-----------------------------------------------------------
    * Calculate three risk-set summaries in Mata.
    * conventional: observed risk set at t
    * retained: conventional + prior competing events, weight 1
    * weighted: conventional + prior competing events weighted by
    *           G(t)/G(Tcomp), matching stcrreg IPCW construction
    *-----------------------------------------------------------
    mata: _fgcifplot_riskcalc("`__esamp'", "`__comp'", "`__cens'", ///
        "`groupvar'", "`GVALS'", "`RTIMES'", "`MCONV'", "`MRET'", "`MWGT'", "`MG'")

    *----------------------------------------
    * Risk-table long dataset and optional save
    *----------------------------------------
    tempfile riskdata riskall curveout
    tempname posth postall
    postfile `posth' str14 risk_type double group_value str120 group_label ///
        double time double value double row_y str20 display using "`riskdata'"

    local ntypes : word count `rtypes'
    local nrows = `ntypes' * (`ng' + 1)

    * Compact vertical geometry for the risk-table panel.  Headings and rows
    * use fractional y positions so multiple requested tables read as one
    * tight table rather than three widely separated mini-panels.
    local titlegap = .24
    local rowstep  = .22
    local blockgap = .12
    local blockdepth = `titlegap' + (`ng' - 1)*`rowstep'
    local totalspan  = `ntypes'*`blockdepth' + (`ntypes' - 1)*`blockgap'
    local ycursor = 0
    local section = 0

    if `showtable' {
        foreach r of local rtypes {
            local ++section
            local heading_y = `totalspan' - `ycursor' + .35
            local gi = 0
            foreach g of numlist `values' {
                local ++gi
                local yy = `heading_y' - `titlegap' - (`gi' - 1)*`rowstep'
                local k = 0
                foreach tt of numlist `risktimes' {
                    local ++k
                    if `"`r'"' == "conventional" {
                        local __fgv = `MCONV'[`gi',`k']
                        local dsp : display %9.0f `__fgv' 
                    }
                    else if `"`r'"' == "retained" {
                        local __fgv = `MRET'[`gi',`k']
                        local dsp : display %9.0f `__fgv' 
                    }
                    else {
                        local __fgv = `MWGT'[`gi',`k']
                        local dsp : display `wformat' `__fgv' 
                    }
                    local dsp = strtrim(`"`dsp'"')
                    post `posth' (`"`r'"') (`g') (`"`glab`gi''"') (`tt') ///
                        (`__fgv') (`yy') (`"`dsp'"')
                }
            }
            local ycursor = `ycursor' + `blockdepth' + `blockgap'
        }
    }
    postclose `posth'

    * risksaving() is an export interface, not a mirror of the displayed
    * table.  Always save all three summaries in a stable five-variable
    * schema, regardless of risktable().
    postfile `postall' str14 risk_type double group_value str120 group_label ///
        double time double value using "`riskall'"
    foreach r in conventional retained weighted {
        local gi = 0
        foreach g of numlist `values' {
            local ++gi
            local k = 0
            foreach tt of numlist `risktimes' {
                local ++k
                if `"`r'"' == "conventional" local __fgv = `MCONV'[`gi',`k']
                else if `"`r'"' == "retained" local __fgv = `MRET'[`gi',`k']
                else local __fgv = `MWGT'[`gi',`k']
                post `postall' (`"`r'"') (`g') (`"`glab`gi''"') (`tt') (`__fgv')
            }
        }
    }
    postclose `postall'

    if `"`risksaving'"' != "" {
        if `"`replace'"' != "" quietly copy "`riskall'" "`risksaving'", replace
        else quietly copy "`riskall'" "`risksaving'"
    }

    *-------------------------------
    * Graphing
    *-------------------------------
    if `"`nograph'"' == "" {
        tempname gcurve gtable gstcurve

        * Ask stcurve only for the model-based CIF coordinates.  Draw the
        * publication graph ourselves so that fgcifplot, rather than stcurve,
        * controls titles, legend placement, and panel proportions.
        quietly stcurve, cif ///
            at(`groupvar'=(`values') `at') ///
            outfile("`curveout'", replace) ///
            range(`tmin' `tmax') ///
            nodraw name(`gstcurve', replace)
        capture graph drop `gstcurve'

        preserve
        quietly use "`curveout'", clear

        local curveplots ""
        forvalues i = 1/`ng' {
            capture confirm variable ci`i'
            if _rc {
                restore
                di as err "stcurve output did not contain expected variable ci`i'"
                exit 498
            }
            local curveplots `"`curveplots' (line ci`i' _t, sort connect(J) lwidth(medthin))"'
        }

        quietly twoway `curveplots', ///
            xlabel(`risktimes', labsize(vsmall)) ///
            ylabel(, angle(horizontal) labsize(vsmall)) ///
            yscale(range(0 .)) ///
            legend(order(`legorder') row(1) position(6) size(vsmall) region(lstyle(none))) ///
            title("") ///
            ytitle("Cumulative incidence", size(vsmall)) ///
            xtitle("Analysis time", size(vsmall)) ///
            graphregion(color(white) margin(small)) ///
            plotregion(margin(small)) ///
            fysize(`curvepct') ///
            name(`gcurve', replace) ///
            `curveopts'
        restore

        if `showtable' {
            preserve
            quietly use "`riskdata'", clear

            local ylabels ""
            local section = 0
            local ycursor = 0
            foreach r of local rtypes {
                local ++section
                local heading_y = `totalspan' - `ycursor' + .35
                if `"`r'"' == "conventional" local head "Conventional N at risk"
                if `"`r'"' == "retained"     local head "FG retained N"
                if `"`r'"' == "weighted"     local head "FG weighted total"
                local ylabels `"`ylabels' `heading_y' "{bf:`head'}""'

                local gi = 0
                foreach g of numlist `values' {
                    local ++gi
                    local yy = `heading_y' - `titlegap' - (`gi' - 1)*`rowstep'
                    local ylabels `"`ylabels' `yy' "  `glab`gi''""'
                }
                local ycursor = `ycursor' + `blockdepth' + `blockgap'
            }

            local yhi = `totalspan' + .55
            local tablesize "vsmall"
            if `nrows' >= 8 local tablesize "tiny"

            quietly twoway ///
                (scatter row_y time if time == `tmin', msymbol(none) mlabel(display) ///
                    mlabposition(3) mlabgap(*1.2) mlabsize(`tablesize')) ///
                (scatter row_y time if time != `tmin' & time != `tmax', msymbol(none) mlabel(display) ///
                    mlabposition(0) mlabsize(`tablesize')) ///
                (scatter row_y time if time == `tmax' & `tmax' != `tmin', msymbol(none) mlabel(display) ///
                    mlabposition(9) mlabgap(*1.2) mlabsize(`tablesize')), ///
                xlabel(`risktimes', nogrid labcolor(white) noticks) ///
                ylabel(`ylabels', nogrid noticks angle(horizontal) labsize(`tablesize') labgap(2)) ///
                xscale(range(`tmin' `tmax') noline) ///
                yscale(range(.05 `yhi') noline) ///
                xtitle("") ytitle("") ///
                legend(off) ///
                plotregion(style(none) margin(zero)) ///
                graphregion(color(white) margin(zero)) ///
                fysize(`tablepct') ///
                name(`gtable', replace) ///
                `tableopts'
            restore

            if `"`name'"' == "" local name "fgcifplot"
            graph combine `gcurve' `gtable', cols(1) xcommon ///
                imargin(0 0 0 0) iscale(*.85) ///
                graphregion(color(white) margin(zero)) ///
                xsize(8) ysize(6) ///
                name(`name', replace) `combineopts'
            capture graph drop `gcurve'
            capture graph drop `gtable'
        }
        else {
            if `"`name'"' == "" local name "fgcifplot"
            graph rename `gcurve' `name', replace
        }
    }

    *-------------------------------
    * Return results
    *-------------------------------
    return matrix conventional = `MCONV'
    return matrix retained     = `MRET'
    return matrix weighted     = `MWGT'
    return matrix censor_survival = `MG'
    return matrix group_values = `GVALS'
    return matrix times        = `RTIMES'
    return local groupvar "`groupvar'"
    return local risk_types "`rtypes'"
    return local compete_var "`crvar'"
    return local compete_values "`crvals'"
    if `"`name'"' != "" return local graph "`name'"
end


capture mata: mata drop _fgcifplot_KM()
capture mata: mata drop _fgcifplot_Glookup()
capture mata: mata drop _fgcifplot_riskcalc()

mata:
real matrix _fgcifplot_KM(real colvector t, real colvector cens)
{
    real colvector ct, ts
    real matrix K
    real scalar n, m, i, p, k, u, d, y, G

    ct = sort(select(t, cens :== 1), 1)
    if (rows(ct) == 0) return(J(0, 2, .))

    ts = sort(t, 1)
    n = rows(ts)
    m = rows(ct)
    K = J(m, 2, .)
    i = 1
    p = 1
    k = 0
    G = 1

    /*
       Version 1.0 has already rejected delayed entry, so the censoring-KM
       risk set at u is the number of observations with t>=u.  Sweep the
       sorted follow-up times once rather than rescanning the full sample for
       every competing-event subject.
    */
    while (i <= m) {
        u = ct[i]
        d = 1
        i = i + 1
        while (i <= m) {
            if (ct[i] != u) break
            d = d + 1
            i = i + 1
        }

        if (u <= 0) y = 0
        else {
            while (p <= n) {
                if (ts[p] >= u) break
                p = p + 1
            }
            y = n - p + 1
        }

        k = k + 1
        K[k,1] = u
        if (y <= 0 | missing(G)) G = .
        else G = G * (1 - d/y)
        K[k,2] = G
    }

    return(K[|1,1 \ k,2|])
}

real scalar _fgcifplot_Glookup(real scalar x, real matrix K)
{
    real scalar lo, hi, mid, ans

    if (x <= 0 | rows(K) == 0) return(1)

    /* Find the last censoring time strictly less than x: G(x-). */
    lo = 1
    hi = rows(K)
    ans = 0
    while (lo <= hi) {
        mid = floor((lo + hi)/2)
        if (K[mid,1] < x) {
            ans = mid
            lo = mid + 1
        }
        else hi = mid - 1
    }

    if (ans == 0) return(1)
    return(K[ans,2])
}

void _fgcifplot_riskcalc(
    string scalar esampvar,
    string scalar compvar,
    string scalar censvar,
    string scalar groupvar,
    string scalar gmat,
    string scalar tmat,
    string scalar outconv,
    string scalar outret,
    string scalar outwgt,
    string scalar outG)
{
    real colvector es, t0, t, comp, cens, grp, keep, idx, Gcomp
    real rowvector gv, rt
    real matrix C, R, W, GG, KM
    real scalar i, j, q, tt, gg, Gt, denom, conv, retained, weighted
    real colvector inconv, priorcomp, pcidx

    es   = st_data(., esampvar)
    keep = (es :== 1)
    idx  = selectindex(keep)

    t0   = st_data(idx, "_t0")
    t    = st_data(idx, "_t")
    comp = st_data(idx, compvar)
    cens = st_data(idx, censvar)
    grp  = st_data(idx, groupvar)

    gv = st_matrix(gmat)
    rt = st_matrix(tmat)

    C = J(cols(gv), cols(rt), .)
    R = J(cols(gv), cols(rt), .)
    W = J(cols(gv), cols(rt), .)
    GG = J(1, cols(rt), .)

    /* Compute the censoring KM once; subsequent evaluations are O(log C). */
    KM = _fgcifplot_KM(t, cens)

    Gcomp = J(rows(t), 1, .)
    for (i=1; i<=rows(t); i++) {
        if (comp[i] == 1) Gcomp[i] = _fgcifplot_Glookup(t[i], KM)
    }

    for (j=1; j<=cols(rt); j++) {
        tt = rt[j]
        Gt = _fgcifplot_Glookup(tt, KM)
        GG[1,j] = Gt

        for (i=1; i<=cols(gv); i++) {
            gg = gv[i]

            /* Table convention: subjects entering exactly at displayed t are counted. */
            inconv   = (grp :== gg) :& (t0 :<= tt) :& (t :>= tt)
            priorcomp = (grp :== gg) :& (comp :== 1) :& (t :< tt)

            conv     = sum(inconv)
            retained = conv + sum(priorcomp)
            weighted = conv

            if (sum(priorcomp) > 0) {
                pcidx = selectindex(priorcomp)
                for (q=1; q<=rows(pcidx); q++) {
                    denom = Gcomp[pcidx[q]]
                    if (missing(Gt) | missing(denom) | denom <= 0) {
                        weighted = .
                        break
                    }
                    weighted = weighted + Gt/denom
                }
            }

            C[i,j] = conv
            R[i,j] = retained
            W[i,j] = weighted
        }
    }

    st_matrix(outconv, C)
    st_matrix(outret,  R)
    st_matrix(outwgt,  W)
    st_matrix(outG,     GG)
}
end
