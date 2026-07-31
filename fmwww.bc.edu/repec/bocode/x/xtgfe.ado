*! xtgfe 1.5.5 - Grouped Fixed Effects, Bonhomme & Manresa (2015, Econometrica)
*! Author: H. Ozan Eruygur, AHBV University, Ankara, Turkiye
*!         https://www.ozaneruygur.com - eruygur@gmail.com
*!         Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik) - https://www.eruygurakademi.com
*! Balanced + unbalanced panels, Algorithm 1 (iterative) & 2 (VNS),
*! cluster-sandwich (default), bootstrap & Pollard fixed-T SEs,
*! BIC group-number selection.
*! Ported from: BM (2015) Fortran/Stata/MATLAB replication code and the gretl
*! GFE package by Lucchetti, Pionati & Valentini.
capture program drop xtgfe
program define xtgfe, eclass sortpreserve
    version 14.0

    * subcommand dispatch: "xtgfe plot, ..." graphs the last estimation
    gettoken subcmd rest : 0, parse(" ,")
    if `"`subcmd'"' == "plot" {
        _xtgfe_plot `rest'
        exit
    }
    if `"`subcmd'"' == "fx" {
        _xtgfe_fx `rest'
        exit
    }

    syntax varlist(numeric ts fv min=1) [if] [in], ///
        Groups(numlist integer >0 max=1) ///
        [ TINVariant ALGorithm(integer 2) RANDstarts(integer -1) ///
          NEIGHbors(integer -1) STEPs(integer 128) MAXiter(integer 1000) ///
          VCE(string) REPS(integer 100) BSTARTs(integer 32) ///
          EPSilon(real -1) BIC REFIT GENerate(name) SHOWFREQ SHOWAlpha ///
          VERbose LONGrun(string) HETcoef(string) ///
          SUBgroups(numlist integer >0) ]

    local ng : word 1 of `groups'
    if !inlist(`algorithm',1,2) {
        di as err "algorithm() must be 1 or 2"
        exit 198
    }
    local tvar = ("`tinvariant'"=="")

    if "`vce'"=="" local vce sandwich
    local vce = lower("`vce'")
    if "`vce'"=="boot" local vce bootstrap
    if !inlist("`vce'","sandwich","bootstrap","fixedt") {
        di as err "vce() must be sandwich, bootstrap, or fixedt"
        exit 198
    }
    local vmode = 0
    if "`vce'"=="bootstrap" local vmode = 1
    if "`vce'"=="fixedt"    local vmode = 2
    if `vmode'==2 & "`tinvariant'"!="" {
        di as err "vce(fixedt) requires time-varying group effects"
        exit 198
    }

    * extensions
    local mode = 0
    if `"`hetcoef'"' != "" & "`subgroups'" != "" {
        di as err "hetcoef() and subgroups() may not be combined"
        exit 198
    }
    if `"`hetcoef'"' != "" local mode = 1
    if "`subgroups'" != "" local mode = 2
    if `mode' > 0 {
        if `vmode' > 0 {
            di as err "hetcoef()/subgroups() allow vce(sandwich) only"
            exit 198
        }
        if "`bic'" != "" {
            di as err "bic may not be combined with hetcoef()/subgroups()"
            exit 198
        }
    }
    if `mode'==2 & "`tinvariant'"!="" {
        di as err "subgroups() requires time-varying group effects"
        exit 198
    }

    * panel setup
    quietly capture xtset
    if _rc {
        di as err "panel not set; use -xtset panelvar timevar- first"
        exit 459
    }
    local id `r(panelvar)'
    local tv `r(timevar)'

    marksample touse, novarlist
    markout `touse' `id' `tv'

    * dep var & covariates (ts and factor operators allowed, e.g. L.y, i.var)
    gettoken depn xraw : varlist
    _fv_check_depvar `depn'
    tsrevar `depn'
    local depv `r(varlist)'
    local xv ""
    local xn ""
    if `"`xraw'"' != "" {
        fvexpand `xraw' if `touse'
        local exlist `r(varlist)'
        foreach term of local exlist {
            * skip base and omitted levels
            if regexm("`term'","b\.") | regexm("`term'","(^|[0-9#])o\.") continue
            fvrevar `term'
            local xv `xv' `r(varlist)'
            local xn `xn' `term'
        }
    }
    local K : word count `xv'

    * a regressor with no cross-sectional variation within time periods is
    * collinear with the group-time effects alpha(gt): refuse it clearly
    if `tvar' & `K'>0 {
        forvalues j = 1/`K' {
            local vr : word `j' of `xv'
            local vn : word `j' of `xn'
            tempvar sdv
            quietly bysort `touse' `tv': egen double `sdv' = sd(`vr') if `touse'
            quietly count if `touse' & `sdv' > 1e-10 & !missing(`sdv')
            if r(N)==0 {
                di as txt "`vn' does not vary across units within time periods;"
                di as txt "it is collinear with the group-time effects alpha(gt) and cannot be included."
                di as txt "(with tinvariant, time effects are not in the model and such regressors are allowed)"
                exit 459
            }
            drop `sdv'
        }
    }
    if `vmode'>0 & `K'==0 {
        di as err "vce(bootstrap) and vce(fixedt) require covariates"
        exit 198
    }
    if `mode'>0 & `K'==0 {
        di as err "hetcoef()/subgroups() require covariates"
        exit 198
    }
    local Kc = 0
    if `mode'==1 {
        local hlist `hetcoef'
        if `"`hlist'"'=="_all" local hlist `xn'
        foreach h of local hlist {
            local found 0
            foreach v of local xn {
                if "`h'"=="`v'" local found 1
            }
            if !`found' {
                di as err "hetcoef(): `h' is not among the covariates"
                exit 198
            }
        }
        local xc ""
        local xcn ""
        local xh ""
        local xhn ""
        forvalues j = 1/`K' {
            local vn : word `j' of `xn'
            local vr : word `j' of `xv'
            local ishet 0
            foreach h of local hlist {
                if "`h'"=="`vn'" local ishet 1
            }
            if `ishet' {
                local xh `xh' `vr'
                local xhn `xhn' `vn'
            }
            else {
                local xc `xc' `vr'
                local xcn `xcn' `vn'
            }
        }
        local Kh : word count `xhn'
        if `Kh'==0 {
            di as err "hetcoef() must name at least one covariate"
            exit 198
        }
        local xv `xc' `xh'
        local xn `xcn' `xhn'
        local Kc : word count `xcn'
    }
    if `mode'==2 {
        local nH : word count `subgroups'
        if `nH' != `ng' {
            di as err "subgroups() must list exactly one integer per group"
            exit 198
        }
    }
    if "`longrun'" != "" {
        if `mode'==1 {
            di as err "longrun() is not available with hetcoef()"
            exit 198
        }
        if `K' < 2 {
            di as err "longrun() requires at least two covariates"
            exit 198
        }
        local lrok 0
        foreach v of local xn {
            if "`v'"=="`longrun'" local lrok 1
        }
        if !`lrok' {
            di as err "longrun(): `longrun' is not among the covariates"
            exit 198
        }
    }

    * assignment variable (default gfe_group is auto-replaced)
    if "`generate'"=="" {
        local generate gfe_group
        capture drop gfe_group
    }
    confirm new variable `generate'
    qui gen long `generate' = .
    local gen2 ""
    if `mode'==2 {
        local gen2 `generate'_sub
        capture drop `gen2'
        confirm new variable `gen2'
        qui gen long `gen2' = .
    }

    * complete-row flag (for the sandwich regression)
    tempvar ok
    mark `ok' if `touse'
    markout `ok' `depv' `xv'

    * ---- estimation in Mata ----
    timer clear 97
    timer on 97
    capture noisily mata: gfe_main("`depv'", "`xv'", "`id'", "`tv'", ///
        "`touse'", `ng', `tvar', `algorithm', `randstarts', `neighbors', ///
        `steps', `maxiter', ("`bic'"!=""), "`generate'", ///
        `vmode', `reps', `bstarts', `epsilon', ("`verbose'"!=""), ///
        `mode', `Kc', "`subgroups'", "`gen2'", ("`refit'"!=""))
    local rcx = _rc
    timer off 97
    if `rcx' {
        capture drop `generate'
        if "`gen2'"!="" capture drop `gen2'
        foreach s in __gfe_ssr __gfe_ll __gfe_N __gfe_T __gfe_nobs __gfe_G __gfe_bw __gfe_rst __gfe_neigh __gfe_S {
            capture scalar drop `s'
        }
        foreach m in __gfe_theta __gfe_alpha __gfe_Vboot __gfe_Vft __gfe_bictab __gfe_tvals __gfe_objs __gfe_BB __gfe_a __gfe_b __gfe_H {
            capture matrix drop `m'
        }
        exit `rcx'
    }

    local Gfin = scalar(__gfe_G)
    local Nun  = scalar(__gfe_N)
    local Tp   = scalar(__gfe_T)
    local nobs = scalar(__gfe_nobs)
    local ssr  = scalar(__gfe_ssr)
    local ll   = scalar(__gfe_ll)
    local rstv   = scalar(__gfe_rst)
    local neighv = scalar(__gfe_neigh)
    qui timer list 97
    local etime = r(t97)
    local tvlab = cond(`tvar',"time-varying","time-invariant")

    * ---- VCE ----
    tempname b V A Vf
    if `K' > 0 & `mode'==0 {
        mat `b' = __gfe_theta'
        mat colnames `b' = `xn'
        if `vmode'==0 {
            tempvar gid
            if `tvar' qui egen `gid' = group(`generate' `tv') if `ok'
            else      qui gen long `gid' = `generate' if `ok'
            qui regress `depv' `xv' i.`gid' if `ok', vce(cluster `id')
            mat `V' = e(V)
            mat `V' = `V'[1..`K',1..`K']
        }
        else if `vmode'==1 mat `V' = __gfe_Vboot
        else               mat `V' = __gfe_Vft
        mat colnames `V' = `xn'
        mat rownames `V' = `xn'
    }
    if `mode'==1 {
        local Kh : word count `xhn'
        local Gfin0 = scalar(__gfe_G)
        tempvar gid
        if `tvar' qui egen `gid' = group(`generate' `tv') if `ok'
        else      qui gen long `gid' = `generate' if `ok'
        if `Kc'>0 {
            qui regress `depv' `xc' ibn.`generate'#c.(`xh') i.`gid' if `ok', vce(cluster `id')
        }
        else {
            qui regress `depv' ibn.`generate'#c.(`xh') i.`gid' if `ok', vce(cluster `id')
        }
        mat `Vf' = e(V)
        local P = `Kc' + `Kh'*`Gfin0'
        mat `b' = J(1, `P', 0)
        mat `V' = J(`P', `P', 0)
        local src ""
        forvalues k = 1/`Kc' {
            local src `src' `k'
        }
        forvalues g = 1/`Gfin0' {
            forvalues k = 1/`Kh' {
                local src `src' `=`Kc'+(`k'-1)*`Gfin0'+`g''
            }
        }
        forvalues a = 1/`P' {
            local sa : word `a' of `src'
            mat `b'[1,`a'] = __gfe_theta[`sa',1]
            forvalues c = 1/`P' {
                local sc : word `c' of `src'
                mat `V'[`a',`c'] = `Vf'[`sa',`sc']
            }
        }
        local cn ""
        local ce ""
        foreach v of local xcn {
            local cn `cn' `v'
            local ce `ce' Common
        }
        forvalues g = 1/`Gfin0' {
            foreach v of local xhn {
                local cn `cn' `v'
                local ce `ce' Group`g'
            }
        }
        mat colnames `b' = `cn'
        mat coleq `b' = `ce'
        mat colnames `V' = `cn'
        mat coleq `V' = `ce'
        mat rownames `V' = `cn'
        mat roweq `V' = `ce'
    }
    if `mode'==2 {
        tempvar gtid fgid
        qui egen `gtid' = group(`generate' `tv') if `ok'
        qui egen `fgid' = group(`generate' `gen2') if `ok'
        qui regress `depv' `xv' i.`gtid' i.`fgid' if `ok', vce(cluster `id')
        mat `V' = e(V)
        mat `V' = `V'[1..`K',1..`K']
        mat `b' = __gfe_theta'
        mat colnames `b' = `xn'
        mat colnames `V' = `xn'
        mat rownames `V' = `xn'
    }
    * long-run table: lagged dependent variable, given or auto-detected
    local lrvar "`longrun'"
    local lrauto 0
    if "`lrvar'"=="" & `mode'!=1 & `K'>=2 {
        tempvar ldep0
        qui bysort `id' (`tv'): gen double `ldep0' = `depv'[_n-1]
        local j 0
        foreach vr of local xv {
            local ++j
            if "`lrvar'"=="" {
                qui count if `ok' & !missing(`vr') & !missing(`ldep0')
                if r(N) > 0 {
                    capture assert reldif(`vr', `ldep0') < 1e-7 if `ok' & !missing(`vr') & !missing(`ldep0')
                    if !_rc {
                        local lrvar : word `j' of `xn'
                        local lrauto 1
                    }
                }
            }
        }
    }

    if `vmode'==2 local bwv = scalar(__gfe_bw)
    if `vmode'==0 local sestr "(cluster-sandwich s.e.)"
    if `vmode'==1 local sestr "(bootstrap s.e., `reps' reps)"
    if `vmode'==2 local sestr "(Pollard fixed-T s.e.)"

    * ---- display ----
    di
    di as txt "{hline 70}"
    di as txt "Grouped fixed-effects estimator (Bonhomme-Manresa 2015)"
    di as txt "Algorithm `algorithm', `tvlab' group effects"
    if `algorithm'==2 {
        di as txt "Random starts: " as res `rstv' as txt "   Neighbors: " ///
           as res `neighv' as txt "   VNS steps: " as res `steps'
    }
    else {
        di as txt "Random starts: " as res `rstv'
    }
    di as txt "Dependent variable: " as res "`depn'"
    di as txt "Units: " as res `Nun' as txt "   Periods: " as res `Tp' ///
       as txt "   Complete obs: " as res `nobs'
    di as txt "Number of groups: " as res `Gfin' as txt "   `sestr'"
    if `mode'==1 {
        di as txt "Group-specific coefficients: " as res "`xhn'"
    }
    if `mode'==2 {
        di as txt "Two-layer specification, subgroups per group: " as res "`subgroups'"
    }
    if `vmode'==2 {
        di as txt "Kernel bandwidth (epsilon) = " as res %8.5f `bwv'
    }
    di as txt "SSR = " as res %12.6g `ssr' ///
       as txt "   log-likelihood = " as res %12.6g `ll'
    di as txt "Elapsed time = " as res %9.2f `etime' as txt " seconds"
    di as txt "{hline 70}"

    if "`bic'" != "" {
        tempname BT
        mat `BT' = __gfe_bictab
        local rr = rowsof(`BT')
        di as txt "BIC model selection (Gmax = `ng'):"
        di as txt "     G          BIC          SSR"
        forvalues r = 1/`rr' {
            local star = cond(`BT'[`r',1]==`Gfin'," *","")
            di as txt %6.0f `BT'[`r',1] "  " %11.5g `BT'[`r',2] ///
               "  " %11.5g `BT'[`r',3] "`star'"
        }
        di as txt "{hline 70}"
    }

    if `K' > 0 {
        ereturn post `b' `V', esample(`touse') depname(`depn') obs(`nobs')
        ereturn scalar ssr = `ssr'
        ereturn scalar ll = `ll'
        ereturn scalar G = `Gfin'
        ereturn scalar N_units = `Nun'
        ereturn scalar T = `Tp'
        ereturn scalar algorithm = `algorithm'
        ereturn scalar tvar = `tvar'
        ereturn scalar etime = `etime'
        ereturn scalar randstarts = `rstv'
        if `algorithm'==2 {
            ereturn scalar neighbors = `neighv'
            ereturn scalar steps = `steps'
        }
        if `vmode'==2 ereturn scalar bandwidth = `bwv'
        mat `A' = __gfe_alpha
        ereturn matrix alpha = `A'
        tempname TT
        mat `TT' = __gfe_tvals
        ereturn matrix tvals = `TT'
        if "`bic'" != "" {
            tempname BT2
            mat `BT2' = __gfe_bictab
            ereturn matrix bic = `BT2'
        }
        capture confirm matrix __gfe_objs
        if !_rc {
            tempname OB
            mat `OB' = __gfe_objs
            ereturn matrix objs = `OB'
        }
        if `vmode'==1 {
            tempname BR
            mat `BR' = __gfe_BB
            ereturn matrix bootreps = `BR'
        }
        if `mode'==1 {
            ereturn scalar Kc = `Kc'
            ereturn local hetvars "`xhn'"
        }
        if `mode'==2 {
            ereturn scalar S = scalar(__gfe_S)
            tempname A2 B2 H2
            mat `A2' = __gfe_a
            ereturn matrix a_primary = `A2'
            mat `B2' = __gfe_b
            ereturn matrix b_sub = `B2'
            mat `H2' = __gfe_H
            ereturn matrix H = `H2'
            ereturn local subgroupvar "`gen2'"
        }
        ereturn local timevar "`tv'"
        ereturn local panelvar "`id'"
        ereturn local groupvar "`generate'"
        ereturn local vce "`vce'"
        ereturn local depvar "`depn'"
        ereturn local cmd "xtgfe"
        ereturn display
        if "`lrvar'" != "" {
            tempname VVlr
            mat `VVlr' = e(V)
            local ip = colnumb(`VVlr', "`lrvar'")
            local phi = _b[`lrvar']
            di as txt "Long-run effects, b/(1 - b[`lrvar']):"
            if `lrauto' {
                di as txt "(`lrvar' detected as the lagged dependent variable)"
            }
            di as txt "{hline 62}"
            di as txt %12s "variable" %14s "coefficient" %12s "std. err." ///
               %8s "z" %10s "P>|z|"
            di as txt "{hline 62}"
            foreach v of local xn {
                if "`v'" != "`lrvar'" {
                    local iv = colnumb(`VVlr', "`v'")
                    local lrb = _b[`v']/(1-`phi')
                    local d1 = _b[`v']/(1-`phi')^2
                    local d2 = 1/(1-`phi')
                    local lrv = `d1'^2*`VVlr'[`ip',`ip'] + `d2'^2*`VVlr'[`iv',`iv'] + 2*`d1'*`d2'*`VVlr'[`ip',`iv']
                    local lrs = sqrt(`lrv')
                    local lrz = `lrb'/`lrs'
                    local lrp = 2*normal(-abs(`lrz'))
                    di as txt %12s abbrev("`v'",12) as res %14.6g `lrb' ///
                       %12.5g `lrs' %8.2f `lrz' %10.3g `lrp'
                }
            }
            di as txt "{hline 62}"
        }
        if "`showalpha'" != "" {
            tempname AL
            mat `AL' = e(alpha)
            if `tvar' {
                tempname TVv
                mat `TVv' = e(tvals)
                local rn ""
                local rr2 = rowsof(`AL')
                forvalues r = 1/`rr2' {
                    local rn `rn' t`=`TVv'[`r',1]'
                }
                mat rownames `AL' = `rn'
                local cn2 ""
                local cc2 = colsof(`AL')
                forvalues g = 1/`cc2' {
                    local cn2 `cn2' Group`g'
                }
                mat colnames `AL' = `cn2'
            }
            else {
                local rn ""
                local rr2 = rowsof(`AL')
                forvalues g = 1/`rr2' {
                    local rn `rn' Group`g'
                }
                mat rownames `AL' = `rn'
                mat colnames `AL' = alpha
            }
            matlist `AL', format(%9.4f) title(Estimated group effects alpha(gt)) ///
                rowtitle(period) border(rows)
        }
    }
    else {
        di as txt "(no covariates: group effects saved in matrix " ///
           as res "xtgfe_alpha" as txt ")"
        capture matrix drop xtgfe_alpha
        matrix xtgfe_alpha = __gfe_alpha
    }

    di as txt "Number of units per group:"
    tempvar f1a
    qui bysort `id' (`tv'): gen byte `f1a' = (_n==1) & !missing(`generate')
    forvalues g = 1/`Gfin' {
        qui count if `f1a' & `generate'==`g'
        di as txt "  Group " %2.0f `g' ":  " as res %4.0f r(N)
    }
    di
    di as txt "Group assignments saved in variable " as res "`generate'"
    if `mode'==2 {
        di as txt "Subgroup assignments saved in variable " as res "`gen2'"
    }

    if "`showfreq'" != "" {
        tempvar f1
        qui bysort `id' (`tv'): gen byte `f1' = (_n==1) & !missing(`generate')
        di as txt "Units per group:"
        tab `generate' if `f1'
    }

    foreach s in __gfe_ssr __gfe_ll __gfe_N __gfe_T __gfe_nobs __gfe_G __gfe_bw __gfe_rst __gfe_neigh __gfe_S {
        capture scalar drop `s'
    }
    foreach m in __gfe_theta __gfe_alpha __gfe_Vboot __gfe_Vft __gfe_bictab __gfe_tvals __gfe_objs __gfe_BB __gfe_a __gfe_b __gfe_H {
        capture matrix drop `m'
    }
end

* ============== xtgfe plot: plot group effects after xtgfe ==============
* Private subroutine dispatched via "xtgfe plot, ..." (ado-file subroutines
* are not callable interactively in modern Stata, hence the subcommand).
capture program drop _xtgfe_plot
program define _xtgfe_plot
    version 14.0
    syntax [, Title(string) MEans *]

    if "`e(cmd)'" != "xtgfe" {
        di as err "xtgfe estimation results not found; run xtgfe first"
        exit 301
    }

    tempname A Tv
    mat `A' = e(alpha)
    local G = e(G)
    local T = e(T)

    * means: plot group-specific means of the outcome (BM Figure 2 style)
    if "`means'" != "" {
        local gv `e(groupvar)'
        local tvn `e(timevar)'
        capture confirm numeric variable `gv'
        if _rc {
            di as err "group variable `gv' not found; re-run xtgfe"
            exit 111
        }
        tsrevar `e(depvar)'
        local dv `r(varlist)'
        if "`title'"=="" local title "Group means of `e(depvar)' (G = `G')"
        preserve
        qui keep if e(sample)
        collapse (mean) __m=`dv', by(`gv' `tvn')
        qui reshape wide __m, i(`tvn') j(`gv')
        local plots ""
        local leg ""
        forvalues g = 1/`G' {
            local plots `plots' (connected __m`g' `tvn')
            local leg `leg' `g' "Group `g'"
        }
        twoway `plots', title("`title'") xtitle("Time") ///
            ytitle("Group mean") legend(order(`leg') cols(2)) `options'
        restore
        exit
    }

    if "`title'"=="" local title "Grouped fixed effects (G = `G')"

    preserve
    qui drop _all

    if e(tvar) == 1 {
        * e(alpha) is T x G (or T x S with subgroups): one column per trajectory
        local nser = colsof(`A')
        qui svmat double `A', names(__ge)
        capture mat `Tv' = e(tvals)
        if _rc == 0 {
            qui svmat double `Tv', names(__tt)
        }
        else {
            qui gen double __tt1 = _n
        }
        local plots ""
        local leg ""
        forvalues g = 1/`nser' {
            local plots `plots' (connected __ge`g' __tt1)
            local leg `leg' `g' "Group `g'"
        }
        twoway `plots', title("`title'") xtitle("Time") ///
            ytitle("Group effect") legend(order(`leg') cols(2)) `options'
    }
    else {
        * e(alpha) is G x 1: one bar per group
        local nser = rowsof(`A')
        qui svmat double `A', names(__ga)
        qui gen double __gg = _n
        twoway (bar __ga1 __gg, barwidth(0.7)), title("`title'") ///
            xtitle("Group") ytitle("Group effect") xlabel(1/`nser') ///
            legend(off) `options'
    }

    restore
end

* ============== xtgfe fx: group-effect variable (gretl group_fx) ==============
capture program drop _xtgfe_fx
program define _xtgfe_fx
    version 14.0
    syntax [name]

    if "`e(cmd)'" != "xtgfe" {
        di as err "xtgfe estimation results not found; run xtgfe first"
        exit 301
    }
    local nv `namelist'
    if "`nv'"=="" {
        local nv gfe_fx
        capture drop gfe_fx
    }
    confirm new variable `nv'
    local gv `e(groupvar)'
    capture confirm numeric variable `gv'
    if _rc {
        di as err "group variable `gv' not found; re-run xtgfe"
        exit 111
    }
    local tvn `e(timevar)'
    local G = e(G)
    local T = e(T)
    tempname A Tv
    mat `A' = e(alpha)
    qui gen double `nv' = .
    if e(S) < . {
        * two-layer: columns of e(alpha) are fine groups; map (g,h) -> column
        local sv `e(subgroupvar)'
        capture confirm numeric variable `sv'
        if _rc {
            di as err "subgroup variable `sv' not found; re-run xtgfe"
            exit 111
        }
        tempname HH
        mat `HH' = e(H)
        mat `Tv' = e(tvals)
        local off = 0
        forvalues g = 1/`G' {
            local Hg = `HH'[1,`g']
            forvalues h = 1/`Hg' {
                local cc = `off' + `h'
                forvalues r = 1/`T' {
                    qui replace `nv' = `A'[`r',`cc'] if `gv'==`g' & `sv'==`h' & `tvn'==`Tv'[`r',1]
                }
            }
            local off = `off' + `Hg'
        }
    }
    else if e(tvar)==1 {
        mat `Tv' = e(tvals)
        forvalues r = 1/`T' {
            forvalues g = 1/`G' {
                qui replace `nv' = `A'[`r',`g'] if `gv'==`g' & `tvn'==`Tv'[`r',1]
            }
        }
    }
    else {
        forvalues g = 1/`G' {
            qui replace `nv' = `A'[`g',1] if `gv'==`g'
        }
    }
    label variable `nv' "GFE group effect (alpha)"
    di as txt "Group-effect variable created: " as res "`nv'"
end

* ===================== Mata core =====================
capture mata: mata drop gfe_main() _gfe_fit() _gfe_algo1() _gfe_vns() _gfe_core() _gfe_update() _gfe_assign() _gfe_reloc() _gfe_boot() _gfe_fixedt() _gfe_quant() _gfe_update_hc() _gfe_assign_hc() _gfe_update_tl() _gfe_upd_disp()

mata:
// ---------- update step: theta & alpha given assignment ----------
real scalar _gfe_update(real matrix Ym, real matrix XB, real matrix D,
        real colvector grp, real scalar G, real scalar tvar,
        real colvector theta, real matrix alpha, real matrix rmat,
        real scalar obj)
{
    real scalar N, T, K, g, k, tot
    real matrix mY, mX, mYe, mXk, W, Wk, Z, Ainv, Dg
    real colvector idx, w
    real rowvector cgt

    N = rows(Ym); T = cols(Ym); K = cols(XB)/T
    mY = J(G, T, 0)
    mX = J(G, T*K, 0)

    for (g=1; g<=G; g++) {
        idx = selectindex(grp:==g)
        if (rows(idx)==0) {
            return(1)
        }
        Dg  = D[idx,.]
        cgt = colsum(Dg)
        if (tvar) {
            if (min(cgt)<1) {
                return(1)
            }
            mY[g,.] = colsum(Dg:*Ym[idx,.]) :/ cgt
            for (k=1; k<=K; k++) {
                mX[g,((k-1)*T+1)..(k*T)] =
                    colsum(Dg:*XB[idx,((k-1)*T+1)..(k*T)]) :/ cgt
            }
        }
        else {
            tot = sum(cgt)
            if (tot<1) {
                return(1)
            }
            mY[g,.] = J(1,T, sum(Dg:*Ym[idx,.])/tot)
            for (k=1; k<=K; k++) {
                mX[g,((k-1)*T+1)..(k*T)] =
                    J(1,T, sum(Dg:*XB[idx,((k-1)*T+1)..(k*T)])/tot)
            }
        }
    }

    if (K>0) {
        mYe = mY[grp,.]
        W = D :* (Ym - mYe)
        w = vec(W')
        Z = J(N*T, K, .)
        for (k=1; k<=K; k++) {
            mXk = mX[.,((k-1)*T+1)..(k*T)]
            Wk = D :* (XB[.,((k-1)*T+1)..(k*T)] - mXk[grp,.])
            Z[.,k] = vec(Wk')
        }
        Ainv = invsym(quadcross(Z,Z))
        if (diag0cnt(Ainv)>0) {
            return(1)
        }
        theta = Ainv*quadcross(Z,w)
        rmat = Ym
        for (k=1; k<=K; k++) {
            rmat = rmat - theta[k]:*XB[.,((k-1)*T+1)..(k*T)]
        }
    }
    else {
        theta = J(0,1,0)
        rmat = Ym
    }

    alpha = mY
    for (k=1; k<=K; k++) {
        alpha = alpha - theta[k]:*mX[.,((k-1)*T+1)..(k*T)]
    }
    if (tvar) {
        obj = sum(D:*(rmat - alpha[grp,.]):^2)
    }
    else {
        alpha = alpha[.,1]
        obj = sum(D:*(rmat :- alpha[grp]):^2)
    }
    return(0)
}

// ---------- assignment step (+ empty-group repair, as in BM Fortran) ----------
real colvector _gfe_assign(real matrix rmat, real matrix D, real matrix alpha,
        real scalar G, real scalar tvar, real colvector bestssr)
{
    real scalar N, g, i, mi
    real colvector grp, sg, sel, cnt, cand, o
    N = rows(rmat)
    grp = J(N,1,1)
    if (tvar) {
        bestssr = rowsum(D:*(rmat :- alpha[1,.]):^2)
    }
    else {
        bestssr = rowsum(D:*(rmat :- alpha[1]):^2)
    }
    for (g=2; g<=G; g++) {
        if (tvar) {
            sg = rowsum(D:*(rmat :- alpha[g,.]):^2)
        }
        else {
            sg = rowsum(D:*(rmat :- alpha[g]):^2)
        }
        sel = sg :< bestssr
        grp     = sel:*g  + (1:-sel):*grp
        bestssr = sel:*sg + (1:-sel):*bestssr
    }
    cnt = J(G,1,0)
    for (i=1; i<=N; i++) {
        cnt[grp[i]] = cnt[grp[i]] + 1
    }
    for (g=1; g<=G; g++) {
        if (cnt[g]==0) {
            cand = selectindex(cnt[grp] :> 1)
            if (rows(cand)==0) continue
            o  = order(bestssr[cand], -1)
            mi = cand[o[1]]
            cnt[grp[mi]] = cnt[grp[mi]] - 1
            grp[mi] = g
            cnt[g] = 1
            bestssr[mi] = 0
        }
    }
    return(grp)
}

// ---------- Lloyd iteration to convergence ----------
real scalar _gfe_upd_disp(real matrix Ym, real matrix XB, real matrix D,
        real colvector grp, real scalar G, real scalar tvar,
        real colvector theta, real matrix alpha, real matrix rmat,
        real scalar obj)
{
    external real scalar GFE_MODE
    if (GFE_MODE==1) return(_gfe_update_hc(Ym,XB,D,grp,G,tvar,theta,alpha,obj))
    if (GFE_MODE==2) return(_gfe_update_tl(Ym,XB,D,grp,G,theta,alpha,rmat,obj))
    return(_gfe_update(Ym,XB,D,grp,G,tvar,theta,alpha,rmat,obj))
}

real scalar _gfe_core(real matrix Ym, real matrix XB, real matrix D,
        real scalar G, real scalar tvar, real colvector grp,
        real colvector theta, real matrix alpha, real scalar obj,
        real scalar maxiter)
{
    external real scalar GFE_MODE
    real scalar it
    real matrix rmat
    real colvector ng, bs
    rmat = .
    for (it=1; it<=maxiter; it++) {
        if (_gfe_upd_disp(Ym,XB,D,grp,G,tvar,theta,alpha,rmat,obj)) {
            return(1)
        }
        bs = .
        if (GFE_MODE==1) ng = _gfe_assign_hc(Ym,XB,D,theta,alpha,G,tvar,bs)
        else             ng = _gfe_assign(rmat, D, alpha, G, tvar, bs)
        if (sum(ng:!=grp)==0) {
            return(0)
        }
        grp = ng
    }
    return(_gfe_upd_disp(Ym,XB,D,grp,G,tvar,theta,alpha,rmat,obj))
}

// ---------- update step, heterogeneous coefficients (BM S4.2) ----------
real scalar _gfe_update_hc(real matrix Ym, real matrix XB, real matrix D,
        real colvector grp, real scalar G, real scalar tvar,
        real colvector theta, real matrix alpha, real scalar obj)
{
    external real scalar GFE_KC
    real scalar N, T, K, Kc, Kh, P, g, k, tot, col
    real matrix mY, mX, mXk, Bmat, Z, Ainv, Dg, rg, alphaGT, Xkb
    real colvector idx, w, sel
    real rowvector cgt

    N = rows(Ym); T = cols(Ym); K = cols(XB)/T
    Kc = GFE_KC; Kh = K - Kc
    P = Kc + Kh*G
    mY = J(G, T, 0)
    mX = J(G, T*K, 0)

    for (g=1; g<=G; g++) {
        idx = selectindex(grp:==g)
        if (rows(idx)==0) return(1)
        Dg  = D[idx,.]
        cgt = colsum(Dg)
        if (tvar) {
            if (min(cgt)<1) return(1)
            mY[g,.] = colsum(Dg:*Ym[idx,.]) :/ cgt
            for (k=1; k<=K; k++) {
                Xkb = XB[.,((k-1)*T+1)..(k*T)]
                mX[g,((k-1)*T+1)..(k*T)] = colsum(Dg:*Xkb[idx,.]) :/ cgt
            }
        }
        else {
            tot = sum(cgt)
            if (tot<1) return(1)
            mY[g,.] = J(1,T, sum(Dg:*Ym[idx,.])/tot)
            for (k=1; k<=K; k++) {
                Xkb = XB[.,((k-1)*T+1)..(k*T)]
                mX[g,((k-1)*T+1)..(k*T)] = J(1,T, sum(Dg:*Xkb[idx,.])/tot)
            }
        }
    }

    w = vec((D:*(Ym - mY[grp,.]))')
    Z = J(N*T, P, 0)
    for (k=1; k<=Kc; k++) {
        mXk = mX[.,((k-1)*T+1)..(k*T)]
        Z[.,k] = vec((D:*(XB[.,((k-1)*T+1)..(k*T)] - mXk[grp,.]))')
    }
    col = Kc
    for (k=Kc+1; k<=K; k++) {
        mXk = mX[.,((k-1)*T+1)..(k*T)]
        Bmat = D:*(XB[.,((k-1)*T+1)..(k*T)] - mXk[grp,.])
        for (g=1; g<=G; g++) {
            col++
            sel = (grp:==g)
            Z[.,col] = vec((Bmat:*sel)')
        }
    }
    Ainv = invsym(quadcross(Z,Z))
    if (diag0cnt(Ainv)>0) return(1)
    theta = Ainv*quadcross(Z,w)

    alphaGT = mY
    for (k=1; k<=Kc; k++) {
        alphaGT = alphaGT - theta[k]:*mX[.,((k-1)*T+1)..(k*T)]
    }
    for (k=1; k<=Kh; k++) {
        mXk = mX[.,((Kc+k-1)*T+1)..((Kc+k)*T)]
        for (g=1; g<=G; g++) {
            alphaGT[g,.] = alphaGT[g,.] - theta[Kc+(k-1)*G+g]:*mXk[g,.]
        }
    }

    obj = 0
    for (g=1; g<=G; g++) {
        idx = selectindex(grp:==g)
        rg = Ym[idx,.]
        for (k=1; k<=Kc; k++) {
            Xkb = XB[.,((k-1)*T+1)..(k*T)]
            rg = rg - theta[k]:*Xkb[idx,.]
        }
        for (k=1; k<=Kh; k++) {
            Xkb = XB[.,((Kc+k-1)*T+1)..((Kc+k)*T)]
            rg = rg - theta[Kc+(k-1)*G+g]:*Xkb[idx,.]
        }
        if (tvar) obj = obj + sum(D[idx,.]:*(rg :- alphaGT[g,.]):^2)
        else      obj = obj + sum(D[idx,.]:*(rg :- alphaGT[g,1]):^2)
    }
    if (tvar) alpha = alphaGT
    else      alpha = alphaGT[.,1]
    return(0)
}

// ---------- assignment step, heterogeneous coefficients ----------
real colvector _gfe_assign_hc(real matrix Ym, real matrix XB, real matrix D,
        real colvector theta, real matrix alpha, real scalar G,
        real scalar tvar, real colvector bestssr)
{
    external real scalar GFE_KC
    real scalar N, T, K, Kc, Kh, g, k, i, mi
    real matrix rg
    real colvector grp, sg, sel2, cnt, cand, o
    N = rows(Ym); T = cols(Ym); K = cols(XB)/T
    Kc = GFE_KC; Kh = K - Kc
    grp = J(N,1,1)
    bestssr = J(N,1,.)
    for (g=1; g<=G; g++) {
        rg = Ym
        for (k=1; k<=Kc; k++) {
            rg = rg - theta[k]:*XB[.,((k-1)*T+1)..(k*T)]
        }
        for (k=1; k<=Kh; k++) {
            rg = rg - theta[Kc+(k-1)*G+g]:*XB[.,((Kc+k-1)*T+1)..((Kc+k)*T)]
        }
        if (tvar) sg = rowsum(D:*(rg :- alpha[g,.]):^2)
        else      sg = rowsum(D:*(rg :- alpha[g]):^2)
        if (g==1) bestssr = sg
        else {
            sel2 = sg :< bestssr
            grp     = sel2:*g  + (1:-sel2):*grp
            bestssr = sel2:*sg + (1:-sel2):*bestssr
        }
    }
    cnt = J(G,1,0)
    for (i=1; i<=N; i++) cnt[grp[i]] = cnt[grp[i]] + 1
    for (g=1; g<=G; g++) {
        if (cnt[g]==0) {
            cand = selectindex(cnt[grp] :> 1)
            if (rows(cand)==0) continue
            o  = order(bestssr[cand], -1)
            mi = cand[o[1]]
            cnt[grp[mi]] = cnt[grp[mi]] - 1
            grp[mi] = g
            cnt[g] = 1
            bestssr[mi] = 0
        }
    }
    return(grp)
}

// ---------- update step, two-layer alpha = a_gt + b_gh (BM S4.1) ----------
real scalar _gfe_update_tl(real matrix Ym, real matrix XB, real matrix D,
        real colvector grp, real scalar S, real colvector theta,
        real matrix alpha, real matrix rmat, real scalar obj)
{
    external real colvector GFE_GMAP, GFE_TLB
    external real scalar GFE_GP
    external real matrix GFE_TLA
    real scalar N, T, K, Gp, g, k, s2, nidx
    real matrix ygt, xgt, Z, Ainv, xf, aM, Xkb, tmpM
    real colvector gp, idx, yg, yf, w, b
    real matrix xg

    N = rows(Ym); T = cols(Ym); K = cols(XB)/T
    Gp = GFE_GP
    gp = GFE_GMAP[grp]

    ygt = J(Gp, T, 0); xgt = J(Gp, T*K, 0)
    yg  = J(Gp, 1, 0); xg  = J(Gp, K, 0)
    for (g=1; g<=Gp; g++) {
        idx = selectindex(gp:==g)
        if (rows(idx)==0) return(1)
        nidx = rows(idx)
        ygt[g,.] = colsum(Ym[idx,.])/nidx
        yg[g] = sum(Ym[idx,.])/(nidx*T)
        for (k=1; k<=K; k++) {
            Xkb = XB[.,((k-1)*T+1)..(k*T)]
            xgt[g,((k-1)*T+1)..(k*T)] = colsum(Xkb[idx,.])/nidx
            xg[g,k] = sum(Xkb[idx,.])/(nidx*T)
        }
    }
    yf = J(S,1,0); xf = J(S,K,0)
    for (s2=1; s2<=S; s2++) {
        idx = selectindex(grp:==s2)
        if (rows(idx)==0) return(1)
        nidx = rows(idx)
        yf[s2] = sum(Ym[idx,.])/(nidx*T)
        for (k=1; k<=K; k++) {
            Xkb = XB[.,((k-1)*T+1)..(k*T)]
            xf[s2,k] = sum(Xkb[idx,.])/(nidx*T)
        }
    }

    w = vec((Ym - ygt[gp,.] :- yf[grp] :+ yg[gp])')
    Z = J(N*T, K, .)
    for (k=1; k<=K; k++) {
        Xkb = XB[.,((k-1)*T+1)..(k*T)]
        tmpM = xgt[.,((k-1)*T+1)..(k*T)]
        Z[.,k] = vec((Xkb - tmpM[gp,.] :- xf[grp,k] :+ xg[gp,k])')
    }
    Ainv = invsym(quadcross(Z,Z))
    if (diag0cnt(Ainv)>0) return(1)
    theta = Ainv*quadcross(Z,w)

    aM = ygt
    for (k=1; k<=K; k++) {
        aM = aM - theta[k]:*xgt[.,((k-1)*T+1)..(k*T)]
    }
    aM = aM :- (yg - xg*theta)
    b = yf - xf*theta
    GFE_TLA = aM
    GFE_TLB = b
    alpha = aM[GFE_GMAP,.] :+ b
    rmat = Ym
    for (k=1; k<=K; k++) {
        rmat = rmat - theta[k]:*XB[.,((k-1)*T+1)..(k*T)]
    }
    obj = sum(D:*(rmat - alpha[grp,.]):^2)
    return(0)
}

// ---------- Algorithm 1: multistart ----------
real scalar _gfe_algo1(real matrix Ym, real matrix XB, real matrix D,
        real scalar G, real scalar tvar, real scalar rst, real scalar maxiter,
        real colvector grp, real colvector theta, real matrix alpha,
        real scalar obj, real colvector objs, real scalar verbose)
{
    external real scalar GFE_PROG
    real scalar N, good, tries, besto, ob
    real colvector g1, th
    real matrix al
    N = rows(D); good = 0; tries = 0; besto = .
    objs = J(0,1,0)
    while (good<rst & tries<20*rst+50) {
        tries++
        g1 = ceil(runiform(N,1):*G)
        th = .; al = .; ob = .
        if (_gfe_core(Ym,XB,D,G,tvar,g1,th,al,ob,maxiter)) continue
        good++
        if (besto>=. | ob<besto) {
            besto = ob
            grp = g1; theta = th; alpha = al; obj = ob
        }
        objs = objs \ ob
        if (verbose) {
            printf("start %g: obj = %g   (best = %g)\n", good, ob, besto)
            displayflush()
        }
        if (GFE_PROG & !verbose & mod(good,25)==0) {
            printf(".")
            displayflush()
        }
    }
    if (GFE_PROG==1 & !verbose & good>=25) {
        printf("\n")
        displayflush()
    }
    if (besto>=.) {
        return(1)
    }
    return(0)
}

// ---------- random relocation of n units ----------
real colvector _gfe_reloc(real colvector grp, real scalar n, real scalar G)
{
    real scalar N
    real colvector ret, perm, idx, sh
    N = rows(grp)
    ret = grp
    perm = order(runiform(N,1),1)
    idx = perm[|1\n|]
    sh  = ceil(runiform(n,1):*(G-1))
    ret[idx] = mod(ret[idx] :+ sh :- 1, G) :+ 1
    return(ret)
}

// ---------- Algorithm 2: VNS from one random start ----------
real scalar _gfe_vns(real matrix Ym, real matrix XB, real matrix D,
        real scalar G, real scalar tvar, real scalar neigh, real scalar steps,
        real scalar maxiter, real colvector grp, real colvector theta,
        real matrix alpha, real scalar obj)
{
    real scalar N, rc, tries, j, n, ob
    real colvector g1, th
    real matrix al
    N = rows(D); tries = 0
    do {
        grp = ceil(runiform(N,1):*G)
        rc = _gfe_core(Ym,XB,D,G,tvar,grp,theta,alpha,obj,maxiter)
        tries++
    } while (rc & tries<50)
    if (rc) {
        return(1)
    }
    for (j=1; j<=steps; j++) {
        n = 1
        while (n<=neigh) {
            g1 = _gfe_reloc(grp, n, G)
            th = .; al = .; ob = .
            if (_gfe_core(Ym,XB,D,G,tvar,g1,th,al,ob,maxiter)) {
                n++
                continue
            }
            if (ob < obj - 1e-10) {
                grp = g1; theta = th; alpha = al; obj = ob
                n = 1
            }
            else n++
        }
    }
    return(0)
}

// ---------- estimation dispatcher ----------
real scalar _gfe_fit(real matrix Ym, real matrix XB, real matrix D,
        real scalar G, real scalar tvar, real scalar algo, real scalar rst,
        real scalar neigh, real scalar steps, real scalar maxiter,
        real colvector grp, real colvector theta, real matrix alpha,
        real scalar obj, real colvector objs, real scalar verbose)
{
    external real scalar GFE_PROG
    real scalar s, besto, ob, rc2
    real colvector g1, th
    real matrix al
    if (algo==1) {
        return(_gfe_algo1(Ym,XB,D,G,tvar,rst,maxiter,grp,theta,alpha,obj,
            objs,verbose))
    }
    besto = .
    objs = J(0,1,0)
    for (s=1; s<=rst; s++) {
        g1 = .; th = .; al = .; ob = .
        rc2 = _gfe_vns(Ym,XB,D,G,tvar,neigh,steps,maxiter,g1,th,al,ob)
        if (GFE_PROG & !verbose) {
            printf(".")
            displayflush()
        }
        if (rc2) continue
        if (besto>=. | ob<besto) {
            besto = ob
            grp = g1; theta = th; alpha = al; obj = ob
        }
        objs = objs \ ob
        if (verbose) {
            printf("start %g: obj = %g   (best = %g)\n", s, ob, besto)
            displayflush()
        }
    }
    if (GFE_PROG==1 & !verbose & rst>=1) {
        printf("\n")
        displayflush()
    }
    if (besto>=.) {
        return(1)
    }
    return(0)
}

// ---------- bootstrap (unit resampling, algorithm 1, bias-corrected) ----------
real matrix _gfe_boot(real matrix Ym, real matrix XB, real matrix D,
        real scalar G, real scalar tvar, real scalar reps, real scalar bstarts,
        real scalar maxiter, real colvector theta_hat)
{
    external real scalar GFE_PROG
    real scalar N, K, T, b, guard, ob, oldprog
    real matrix BB, Yb, Xb, Db, al, V
    real colvector draw, g1, th, bias, dob
    N = rows(D); T = cols(Ym); K = cols(XB)/T
    BB = J(reps, K, .)
    b = 0; guard = 0
    oldprog = GFE_PROG
    GFE_PROG = 0
    printf("bootstrap: ")
    displayflush()
    while (b<reps & guard<20*reps) {
        guard++
        draw = ceil(runiform(N,1):*N)
        Yb = Ym[draw,.]; Xb = XB[draw,.]; Db = D[draw,.]
        g1 = .; th = .; al = .; ob = .
        dob = .
        if (_gfe_algo1(Yb,Xb,Db,G,tvar,bstarts,maxiter,g1,th,al,ob,dob,0)) continue
        b++
        BB[b,.] = th'
        if (mod(b,10)==0) {
            printf(".")
            displayflush()
        }
    }
    printf("\n")
    displayflush()
    GFE_PROG = oldprog
    if (b<2) {
        _error(3498, "bootstrap failed: too few successful replications")
    }
    if (b<reps) BB = BB[|1,1 \ b,K|]
    st_matrix("__gfe_BB", BB)
    V = variance(BB)
    bias = mean(BB)' - theta_hat
    return(V + bias*bias')
}

// ---------- main driver ----------
void gfe_main(string scalar yn, string scalar xn, string scalar idn,
        string scalar tn, string scalar tou, real scalar G, real scalar tvar,
        real scalar algo, real scalar rst, real scalar neigh,
        real scalar steps, real scalar maxiter, real scalar dobic,
        string scalar gen, real scalar vmode, real scalar reps,
        real scalar bstarts, real scalar eps_in, real scalar verbose,
        real scalar mode, real scalar kc, string scalar hstr,
        string scalar gen2, real scalar dorefit)
{
    external real scalar GFE_MODE, GFE_KC, GFE_GP, GFE_PROG
    external real colvector GFE_GMAP, GFE_TLB
    external real matrix GFE_TLA
    real scalar n, N, T, K, r, k, i, t, okr, rc, obj, NT, ll, bw
    real scalar Gmax, g, s2, npar, bi, bobj, bg, ob1, S, Gf
    real colvector ids, tms, y, iidx, tidx, ord, grp, theta, gvals
    real colvector bgrp, btheta, g1, th1, objs, o1
    real colvector hv, gmapv, prim, sub, offs, svals, selc
    real rowvector cs
    real scalar Tk
    real matrix X, Ym, XB, D, alpha, balpha, al1, bictab, ut, uid, Om, XB2, Xkb

    GFE_MODE = mode
    GFE_PROG = (dobic ? 2 : 1)   // 1 = dots + newline; 2 = dots, line kept open (BIC grid)
    GFE_KC = kc
    GFE_GP = 0
    GFE_GMAP = J(0,1,0)
    GFE_TLA = J(0,0,0)
    GFE_TLB = J(0,1,0)

    ids = st_data(., idn, tou)
    tms = st_data(., tn, tou)
    y   = st_data(., yn, tou)
    if (xn=="") {
        K = 0
        X = J(rows(y),0,0)
    }
    else {
        K = cols(tokens(xn))
        X = st_data(., tokens(xn), tou)
    }

    n = rows(y)
    if (n<2) {
        _error(2001, "insufficient observations")
    }
    ord = order((ids,tms),(1,2))
    ids = ids[ord]; tms = tms[ord]; y = y[ord]
    if (K>0) {
        X = X[ord,.]
    }

    uid = uniqrows(ids); N = rows(uid)
    ut  = uniqrows(tms); T = rows(ut)

    iidx = J(n,1,1)
    for (r=2; r<=n; r++) {
        iidx[r] = iidx[r-1] + (ids[r]!=ids[r-1])
    }
    tidx = J(n,1,0)
    for (r=1; r<=n; r++) {
        for (t=1; t<=T; t++) {
            if (tms[r]==ut[t]) {
                tidx[r] = t
                break
            }
        }
    }

    Ym = J(N,T,0); D = J(N,T,0); XB = J(N,T*K,0)
    for (r=1; r<=n; r++) {
        okr = (y[r] < .)
        for (k=1; k<=K; k++) {
            okr = okr & (X[r,k] < .)
        }
        if (okr) {
            i = iidx[r]; t = tidx[r]
            if (D[i,t]==1) {
                _error(3498, "repeated time values within panel")
            }
            D[i,t] = 1
            Ym[i,t] = y[r]
            for (k=1; k<=K; k++) {
                XB[i,(k-1)*T+t] = X[r,k]
            }
        }
    }
    // drop periods in which no unit has a complete observation
    cs = colsum(D)
    selc = selectindex(cs' :> 0)
    if (rows(selc) < T) {
        for (t=1; t<=T; t++) {
            if (cs[t] == 0) {
                printf("note: period %g dropped (no complete observations)\n", ut[t])
            }
        }
        displayflush()
        Tk = rows(selc)
        XB2 = J(N, Tk*K, 0)
        for (k=1; k<=K; k++) {
            Xkb = XB[., ((k-1)*T+1)..(k*T)]
            XB2[., ((k-1)*Tk+1)..(k*Tk)] = Xkb[., selc']
        }
        XB = XB2
        Ym = Ym[., selc']
        D  = D[., selc']
        ut = ut[selc]
        T  = Tk
    }

    if (min(rowsum(D)) < 1) {
        _error(3498, "some units have no complete observation; drop them first")
    }
    if (G >= N) {
        _error(3498, "groups() must be smaller than the number of units")
    }

    Gf = G
    S = 0
    if (mode==2) {
        hv = strtoreal(tokens(hstr))'
        if (rows(hv)!=G) {
            _error(3498, "subgroups() must list one value per group")
        }
        S = sum(hv)
        if (S >= N) {
            _error(3498, "too many subgroups for the number of units")
        }
        if (sum(D) != rows(D)*cols(D)) {
            _error(3498, "subgroups() requires a balanced panel")
        }
        gmapv = J(0,1,0)
        for (g=1; g<=G; g++) {
            gmapv = gmapv \ J(hv[g],1,g)
        }
        GFE_GMAP = gmapv
        GFE_GP = G
        Gf = S
    }

    if (rst < 0) {
        if (algo==1) {
            rst = (Gf<8 ? 1024 : 4096)
        }
        else {
            rst = floor(8*sqrt(Gf))
        }
    }
    if (neigh < 0) {
        neigh = max((2, floor(sqrt(N))))
    }
    st_numscalar("__gfe_rst", rst)
    st_numscalar("__gfe_neigh", neigh)

    NT = sum(D)

    if (dobic) {
        Gmax = G
        bgrp = .; btheta = .; balpha = .; bobj = .; o1 = .
        if (_gfe_fit(Ym,XB,D,Gmax,tvar,algo,rst,neigh,steps,maxiter,
                     bgrp,btheta,balpha,bobj,o1,verbose)) {
            _error(3498, "estimation failed at Gmax")
        }
        printf(" %2.0f%% ", 100/Gmax)
        displayflush()
        npar = (tvar ? Gmax*T : Gmax)
        s2 = bobj/(NT - npar - N - K)
        bi = bobj/NT + s2*(npar + N + K)/NT*ln(NT)
        bictab = (Gmax, bi, bobj)
        bg = Gmax
        grp = bgrp; theta = btheta; alpha = balpha; obj = bobj
        for (g=Gmax-1; g>=2; g--) {
            g1 = .; th1 = .; al1 = .; ob1 = .; o1 = .
            rc = _gfe_fit(Ym,XB,D,g,tvar,algo,rst,neigh,steps,maxiter,
                         g1,th1,al1,ob1,o1,verbose)
            printf(" %2.0f%% ", 100*(Gmax-g+1)/Gmax)
            displayflush()
            if (rc) continue
            npar = (tvar ? g*T : g)
            bi = ob1/NT + s2*(npar + N + K)/NT*ln(NT)
            if (bi < min(bictab[.,2])) {
                bg = g
                grp = g1; theta = th1; alpha = al1; obj = ob1
            }
            bictab = bictab \ (g, bi, ob1)
        }
        g1 = J(N,1,1); th1 = .; al1 = .; ob1 = .
        rc = _gfe_core(Ym,XB,D,1,tvar,g1,th1,al1,ob1,maxiter)
        if (!rc) {
            npar = (tvar ? T : 1)
            bi = ob1/NT + s2*(npar + N + K)/NT*ln(NT)
            if (bi < min(bictab[.,2])) {
                bg = 1
                grp = g1; theta = th1; alpha = al1; obj = ob1
            }
            bictab = bictab \ (1, bi, ob1)
        }
        printf(" 100%%\n")
        displayflush()
        GFE_PROG = 1
        G = bg
        // optional refit at the selected G with a fresh search (not in the
        // original BM/gretl codes; enabled with the refit option)
        if (dorefit & bg >= 2) {
            g1 = .; th1 = .; al1 = .; ob1 = .; o1 = .
            if (!_gfe_fit(Ym,XB,D,bg,tvar,algo,rst,neigh,steps,maxiter,
                          g1,th1,al1,ob1,o1,verbose)) {
                if (ob1 < obj) {
                    grp = g1; theta = th1; alpha = al1; obj = ob1
                }
            }
            npar = (tvar ? bg*T : bg)
            bi = obj/NT + s2*(npar + N + K)/NT*ln(NT)
            for (r=1; r<=rows(bictab); r++) {
                if (bictab[r,1]==bg) {
                    bictab[r,2] = bi
                    bictab[r,3] = obj
                }
            }
        }
        st_matrix("__gfe_bictab", bictab)
    }
    else {
        grp = .; theta = .; alpha = .; obj = .; objs = .
        if (_gfe_fit(Ym,XB,D,Gf,tvar,algo,rst,neigh,steps,maxiter,
                     grp,theta,alpha,obj,objs,verbose)) {
            _error(3498, "estimation failed: no admissible grouping found (check for collinear covariates or too many groups)")
        }
        st_matrix("__gfe_objs", objs)
    }

    ll = -NT/2*(1 + ln(2*pi()) + ln(obj/NT))
    st_numscalar("__gfe_ssr", obj)
    st_numscalar("__gfe_ll", ll)
    st_numscalar("__gfe_N", N)
    st_numscalar("__gfe_T", T)
    st_numscalar("__gfe_nobs", NT)
    st_numscalar("__gfe_G", G)
    if (K>0) {
        st_matrix("__gfe_theta", theta)
    }
    if (tvar) {
        st_matrix("__gfe_alpha", alpha')
    }
    else {
        st_matrix("__gfe_alpha", alpha)
    }
    st_matrix("__gfe_tvals", ut)
    if (mode==2) {
        st_numscalar("__gfe_S", S)
        st_matrix("__gfe_a", GFE_TLA')
        st_matrix("__gfe_b", GFE_TLB)
        st_matrix("__gfe_H", hv')
    }

    gvals = J(n,1,.)
    if (mode==2) {
        offs = J(G,1,0)
        for (g=2; g<=G; g++) {
            offs[g] = offs[g-1] + hv[g-1]
        }
        prim = GFE_GMAP[grp]
        sub  = grp - offs[prim]
        for (r=1; r<=n; r++) {
            gvals[ord[r]] = prim[iidx[r]]
        }
        st_store(., gen, tou, gvals)
        svals = J(n,1,.)
        for (r=1; r<=n; r++) {
            svals[ord[r]] = sub[iidx[r]]
        }
        if (gen2!="") st_store(., gen2, tou, svals)
    }
    else {
        for (r=1; r<=n; r++) {
            gvals[ord[r]] = grp[iidx[r]]
        }
        st_store(., gen, tou, gvals)
    }

    if (vmode==1 & K>0) {
        st_matrix("__gfe_Vboot",
            _gfe_boot(Ym,XB,D,G,tvar,reps,bstarts,maxiter,theta))
    }
    if (vmode==2 & K>0) {
        if (sum(D) != N*T) {
            _error(3498, "vce(fixedt) requires a balanced panel")
        }
        bw = eps_in
        Om = _gfe_fixedt(Ym, XB, grp, theta, alpha, G, bw)
        st_matrix("__gfe_Vft", Om[|G*T+1,G*T+1 \ G*T+K,G*T+K|])
        st_numscalar("__gfe_bw", bw)
    }
}

// ---------- percentile (linear interpolation, type 7) ----------
real scalar _gfe_quant(real colvector v, real scalar p)
{
    real colvector s
    real scalar n, h, lo, fr
    s = sort(v, 1)
    n = rows(s)
    h = (n-1)*p + 1
    lo = floor(h)
    fr = h - lo
    if (lo >= n) return(s[n])
    return(s[lo] + fr*(s[lo+1]-s[lo]))
}

// ---------- Pollard (1982) fixed-T variance (BM's fixedT_function.m) ----------
// Returns the full (G*T+K) x (G*T+K) matrix; theta block is the last K.
// bw: on input the user epsilon (<=0 or missing = automatic Silverman rule
//     as in BM's GFE_estimates.m); on output the bandwidth actually used.
real matrix _gfe_fixedt(real matrix Ym, real matrix XB, real colvector grp,
        real colvector theta, real matrix alphaGT, real scalar G,
        real scalar bw)
{
    real scalar N, T, K, GT, g, h, l, g2, i, k, c, nrm, sigmin, sd, iqr, f
    real matrix a, rmat, ssr, F, Xstack, Gxx, GxgAll, GggAll, GgtAll
    real matrix BG, Vm, M, Om, iBG, Xi
    real colvector nv, proj, diffv, ag, ah, ri, e, u, ind, Vv, vres

    N = rows(Ym); T = cols(Ym); K = cols(XB)/T
    GT = G*T
    a = alphaGT'

    rmat = Ym
    for (k=1; k<=K; k++) {
        rmat = rmat - theta[k]:*XB[.,((k-1)*T+1)..(k*T)]
    }

    // stacked X: T rows per unit, unit-major
    Xstack = J(N*T, K, 0)
    for (i=1; i<=N; i++) {
        for (k=1; k<=K; k++) {
            Xstack[|(i-1)*T+1,k \ i*T,k|] = XB[i,((k-1)*T+1)..(k*T)]'
        }
    }

    // per-unit SSR under each group
    ssr = J(N, G, 0)
    for (g=1; g<=G; g++) {
        ssr[.,g] = rowsum((rmat :- (a[.,g])'):^2)
    }

    // automatic bandwidth (Silverman rule, as in BM's GFE_estimates.m)
    if (bw <= 0 | bw >= .) {
        sigmin = .
        for (g=1; g<G; g++) {
            for (h=g+1; h<=G; h++) {
                nv = a[.,g] - a[.,h]
                nv = nv/sqrt(nv'nv)
                proj = rmat*nv
                sd = sqrt(variance(proj))
                if (sd < sigmin) sigmin = sd
            }
        }
        vres = vec(rmat')
        iqr = _gfe_quant(vres, .75) - _gfe_quant(vres, .25)
        bw = 1.06*min((sigmin, iqr/1.34))*N^(-0.2)
    }

    // frontier kernel weights
    F = J(N, G*G, 0)
    for (g=1; g<=G; g++) {
        for (h=1; h<=G; h++) {
            if (h==g) continue
            c = (g-1)*G + h
            ag = a[.,g]; ah = a[.,h]
            nrm = sqrt((ah-ag)'(ah-ag))
            diffv = (ah-ag)/nrm
            ind = J(N,1,1)
            for (l=1; l<=G; l++) {
                if (l!=g & l!=h) {
                    ind = ind :* (ssr[.,g]:<=ssr[.,l]) :* (ssr[.,h]:<=ssr[.,l])
                }
            }
            Vv = (rmat :- ((ah+ag)/2)')*diffv
            F[.,c] = ind :* normalden(Vv:/bw) :/ bw
        }
    }

    // Gamma_xx
    Gxx = quadcross(Xstack, Xstack)/N
    for (g=1; g<=G; g++) {
        for (h=1; h<=G; h++) {
            if (h==g) continue
            c = (g-1)*G + h
            ag = a[.,g]; ah = a[.,h]
            nrm = sqrt((ah-ag)'(ah-ag))
            M = -0.5*(ah-ag)*(ah-ag)'/nrm
            for (i=1; i<=N; i++) {
                f = F[i,c]
                if (f > 1e-14) {
                    Xi = Xstack[|(i-1)*T+1,1 \ i*T,.|]
                    Gxx = Gxx + f*(Xi'M*Xi)/N
                }
            }
        }
    }

    // Gamma_xg, Gamma_gg, Gamma_ggtilde
    GxgAll = J(K, T*G, 0)
    GggAll = J(T, T*G, 0)
    GgtAll = J(T, T*G*G, 0)
    for (g=1; g<=G; g++) {
        ag = a[.,g]
        for (i=1; i<=N; i++) {
            if (grp[i]==g) {
                Xi = Xstack[|(i-1)*T+1,1 \ i*T,.|]
                GxgAll[|1,(g-1)*T+1 \ K,g*T|] =
                    GxgAll[|1,(g-1)*T+1 \ K,g*T|] + Xi'/N
            }
        }
        GggAll[|1,(g-1)*T+1 \ T,g*T|] = sum(grp:==g)*I(T)/N
        for (h=1; h<=G; h++) {
            if (h==g) continue
            c = (g-1)*G + h
            ah = a[.,h]
            nrm = sqrt((ah-ag)'(ah-ag))
            for (i=1; i<=N; i++) {
                f = F[i,c]
                if (f > 1e-14) {
                    Xi = Xstack[|(i-1)*T+1,1 \ i*T,.|]
                    ri = (rmat[i,.])'
                    GxgAll[|1,(g-1)*T+1 \ K,g*T|] =
                        GxgAll[|1,(g-1)*T+1 \ K,g*T|] +
                        f*(Xi'(ag-ah))*((ri-ag)')/nrm/N
                    GggAll[|1,(g-1)*T+1 \ T,g*T|] =
                        GggAll[|1,(g-1)*T+1 \ T,g*T|] -
                        f*(ri-ag)*((ri-ag)')/nrm/N
                    GgtAll[|1,(c-1)*T+1 \ T,c*T|] =
                        GgtAll[|1,(c-1)*T+1 \ T,c*T|] +
                        f*(ri-ag)*((ri-ah)')/nrm/N
                }
            }
        }
    }

    // assemble BigGamma
    BG = J(GT+K, GT+K, 0)
    BG[|GT+1,GT+1 \ GT+K,GT+K|] = Gxx
    for (g=1; g<=G; g++) {
        BG[|(g-1)*T+1,GT+1 \ g*T,GT+K|] = (GxgAll[|1,(g-1)*T+1 \ K,g*T|])'
        BG[|(g-1)*T+1,(g-1)*T+1 \ g*T,g*T|] = GggAll[|1,(g-1)*T+1 \ T,g*T|]
        for (g2=g+1; g2<=G; g2++) {
            c = (g-1)*G + g2
            BG[|(g-1)*T+1,(g2-1)*T+1 \ g*T,g2*T|] = GgtAll[|1,(c-1)*T+1 \ T,c*T|]
        }
    }
    for (i=2; i<=GT+K; i++) {
        for (k=1; k<i; k++) {
            BG[i,k] = BG[k,i]
        }
    }
    BG = BG*N

    // clustered meat
    Vm = J(GT+K, GT+K, 0)
    for (i=1; i<=N; i++) {
        ri = (rmat[i,.])'
        e = ri - a[.,grp[i]]
        u = J(GT+K, 1, 0)
        u[|(grp[i]-1)*T+1 \ grp[i]*T|] = e
        Xi = Xstack[|(i-1)*T+1,1 \ i*T,.|]
        u[|GT+1 \ GT+K|] = Xi'e
        Vm = Vm + u*u'
    }

    iBG = luinv(BG)
    Om = iBG*Vm*iBG'
    return(Om)
}
end
