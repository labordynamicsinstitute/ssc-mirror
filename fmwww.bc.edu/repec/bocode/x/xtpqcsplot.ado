*! xtpqcsplot v1.0.1  08apr2026
*! Quantile process visualization for xtpqcs
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
*!
*! Estimates xtpqcs at a grid of quantile indices and produces a
*! beautiful coefficient process plot with confidence bands from both
*! the robust covariance (Chiang, Galvao & Wei 2026) and the classical
*! Kato et al. (2012) sandwich, allowing direct visual comparison.

program define xtpqcsplot, rclass
    version 14.0
    syntax varlist(min=2 numeric) [if] [in], ///
        Id(varname numeric) ///
        Time(varname numeric) ///
    [ ///
        Quantiles(numlist >0 <1 sort) ///
        VARiables(varlist numeric) ///
        Bandwidth(real 0) ///
        Kernel(string) ///
        Level(cilevel) ///
        SAVing(string) ///
        TITle(string asis) ///
        SUBtitle(string asis) ///
        SCHeme(string) ///
        NOCLassical ///
        NOCOMbine ///
        ASIS ///
    ]

    if "`quantiles'" == "" {
        local quantiles "0.10 0.25 0.50 0.75 0.90"
    }
    if "`kernel'" == "" local kernel "gaussian"
    if "`scheme'" == "" local scheme "s2color"

    marksample touse
    markout `touse' `id' `time'

    gettoken depvar indepvars : varlist

    if "`variables'" == "" {
        local plotvars `indepvars'
    }
    else {
        local plotvars `variables'
    }

    local nq : word count `quantiles'
    local np : word count `plotvars'

    /*-----------------------------------------------------------------*/
    /*  Build a results frame                                          */
    /*-----------------------------------------------------------------*/
    tempname memhold
    tempfile results
    postfile `memhold' tau str32 var double(b se_rob se_cl lo_rob hi_rob lo_cl hi_cl) ///
        using `results', replace

    local crit = invnormal(1 - (100-`level')/200)

    di as txt _n "{hline 78}"
    di as res "  xtpqcsplot - estimating quantile process"
    di as txt "{hline 78}"
    di as txt "  Quantiles: " as res "`quantiles'"
    di as txt "  Variables: " as res "`plotvars'"
    di as txt "  Level    : " as res "`level'%"
    di as txt "{hline 78}"

    foreach q of local quantiles {
        di as txt "  tau = " as res %5.3f `q' as txt " ..."
        qui xtpqcs `depvar' `indepvars' if `touse', ///
            id(`id') time(`time') quantile(`q') ///
            bandwidth(`bandwidth') kernel(`kernel') noheader

        tempname Vrob Vcl
        matrix `Vrob' = e(V_robust)
        matrix `Vcl'  = e(V_classical)

        foreach v of local plotvars {
            local b   = _b[`v']
            local sr  = sqrt(`Vrob'["`v'","`v'"])
            local sc  = sqrt(`Vcl' ["`v'","`v'"])
            local lor = `b' - `crit'*`sr'
            local hir = `b' + `crit'*`sr'
            local loc = `b' - `crit'*`sc'
            local hic = `b' + `crit'*`sc'
            post `memhold' (`q') ("`v'") (`b') (`sr') (`sc') ///
                (`lor') (`hir') (`loc') (`hic')
        }
    }
    postclose `memhold'

    /*-----------------------------------------------------------------*/
    /*  Capture variable labels BEFORE preserve replaces data          */
    /*-----------------------------------------------------------------*/
    local k 0
    foreach v of local plotvars {
        local ++k
        local vlab`k' : variable label `v'
        if "`vlab`k''" == "" local vlab`k' "`v'"
    }

    /*-----------------------------------------------------------------*/
    /*  Load results and graph                                         */
    /*-----------------------------------------------------------------*/
    preserve
    qui use `results', clear

    set scheme `scheme'

    local graphs ""
    local k 0
    foreach v of local plotvars {
        local ++k
        local vlab "`vlab`k''"

        local clopt ""
        if "`noclassical'" == "" {
            local clopt (rarea lo_cl hi_cl tau if var=="`v'", ///
                color(navy%18) lwidth(none)) ///
                (line lo_cl tau if var=="`v'", lcolor(navy%70) lpattern(dash) lwidth(thin)) ///
                (line hi_cl tau if var=="`v'", lcolor(navy%70) lpattern(dash) lwidth(thin))
        }

        tempname g`k'
        twoway ///
            `clopt' ///
            (rarea lo_rob hi_rob tau if var=="`v'", ///
                color(cranberry%30) lwidth(none)) ///
            (line lo_rob tau if var=="`v'", lcolor(cranberry%80) lpattern(shortdash) lwidth(thin)) ///
            (line hi_rob tau if var=="`v'", lcolor(cranberry%80) lpattern(shortdash) lwidth(thin)) ///
            (line  b      tau if var=="`v'", lcolor(black) lwidth(medthick)) ///
            (scatter b tau if var=="`v'", mcolor(black) msymbol(O) msize(small) ///
                mfcolor(white) mlwidth(medthick)) ///
            , ///
            title("{bf:`vlab'}", size(medsmall) color(black)) ///
            ytitle("Coefficient", size(small)) ///
            xtitle("Quantile {&tau}", size(small)) ///
            ylabel(, angle(horizontal) labsize(small) glcolor(gs15) glwidth(thin)) ///
            xlabel(, labsize(small) glcolor(gs15) glwidth(thin)) ///
            yline(0, lcolor(gs10) lpattern(dot)) ///
            legend(off) ///
            graphregion(color(white) margin(medium)) ///
            plotregion(color(white) margin(medium) lcolor(gs12)) ///
            name(`g`k'', replace)

        local graphs `graphs' `g`k''
    }

    if `"`title'"' == "" {
        local title "Panel Quantile Regression Process with Common Shocks"
    }
    if `"`subtitle'"' == "" {
        local subtitle "Robust 95% CI (red) vs classical Kato et al. CI (blue, dashed)"
    }

    if "`nocombine'" == "" & `np' > 1 {
        local cols = min(`np', 3)
        graph combine `graphs', ///
            cols(`cols') ///
            title(`"`title'"', size(medium) color(black)) ///
            subtitle(`"`subtitle'"', size(small) color(gs6)) ///
            note("Source: xtpqcs, Chiang, Galvao & Wei (2026). Implementation: Dr. Merwan Roudane.", ///
                size(vsmall) color(gs8)) ///
            graphregion(color(white) margin(medium)) ///
            imargin(small) ///
            name(xtpqcs_process, replace)

        if `"`saving'"' != "" {
            graph save xtpqcs_process `saving', replace
        }
    }

    return local quantiles "`quantiles'"
    return local variables  "`plotvars'"

    if "`asis'" != "" {
        // keep the results dataset open in memory
        exit
    }
    restore
end
