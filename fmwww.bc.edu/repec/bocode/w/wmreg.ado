*! wmreg — Wavelet Multiple Regression
*! Version 1.0.0  2026-05-10
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
*! Part of the lwavelet package
*! Reference: Fernandez-Macho (2012)

program define wmreg, eclass sortpreserve
    version 11

    syntax varlist(min=2 ts) [if] [in], ///
        [Levels(integer 4)          ///
         Filter(string)             ///
         NODisplay                  ///
         PLOT                       ///
        ]

    * ── Defaults ──
    if ("`filter'" == "") local filter "la8"
    local filter = lower(trim("`filter'"))

    * ── Sample ──
    marksample touse
    qui count if `touse'
    local N = r(N)
    local d : word count `varlist'

    * ── Extract data ──
    tempname Xmat vnames
    mata: `Xmat' = st_data(., "`varlist'", "`touse'")
    mata: `vnames' = tokens("`varlist'")'

    * ── Compute ──
    tempname result
    mata: `result' = _wv_wmreg(`Xmat', "`filter'", `levels')

    * ── Store results ──
    local dk = `d' - 1

    forvalues j = 1/`levels' {
        tempname b_`j' se_`j' t_`j' p_`j'
        mata: st_matrix("`b_`j''", `result'.beta[`j', .])
        mata: st_matrix("`se_`j''", `result'.se[`j', .])
        mata: st_matrix("`t_`j''", `result'.tstat[`j', .])
        mata: st_matrix("`p_`j''", `result'.pval[`j', .])
    }

    tempname rsq_mat ymaxr_mat
    mata: st_matrix("`rsq_mat'", `result'.rsq)
    mata: st_matrix("`ymaxr_mat'", `result'.ymaxr)

    ereturn clear
    ereturn local cmd      "wmreg"
    ereturn local varlist  "`varlist'"
    ereturn local filter   "`filter'"
    ereturn scalar N       = `N'
    ereturn scalar J       = `levels'
    ereturn scalar d       = `d'
    ereturn matrix rsq     = `rsq_mat'
    ereturn matrix ymaxr   = `ymaxr_mat'

    forvalues j = 1/`levels' {
        ereturn matrix beta`j' = `b_`j''
        ereturn matrix se`j'   = `se_`j''
        ereturn matrix tstat`j' = `t_`j''
        ereturn matrix pval`j'  = `p_`j''
    }

    * ── Display ──
    if ("`nodisplay'" == "") {
        mata: _wv_display_wmreg(`result', `vnames')
    }

    * ── Plot ──
    if ("`plot'" != "") {
        _wmreg_plot, levels(`levels')
    }

    * ── Cleanup ──
    mata: mata drop `Xmat' `vnames' `result'
end

* ═════════════════════════════════════════════════════════════
* Internal: Wavelet regression coefficient plot
* ═════════════════════════════════════════════════════════════
program define _wmreg_plot
    syntax, levels(integer)

    local d = e(d)
    local dk = `d' - 1

    * Build dataset for plotting
    preserve
    clear

    local totalobs = `levels' * `dk'
    qui set obs `totalobs'

    qui gen int    _level = .
    qui gen int    _varid = .
    qui gen double _beta  = .
    qui gen double _se    = .
    qui gen double _ci_lo = .
    qui gen double _ci_up = .
    qui gen str32  _vname = ""

    local obs = 0
    forvalues j = 1/`levels' {
        tempname bj sj
        matrix `bj' = e(beta`j')
        matrix `sj' = e(se`j')

        forvalues k = 1/`dk' {
            local ++obs
            qui replace _level = `j'              in `obs'
            qui replace _varid = `k'              in `obs'
            qui replace _beta  = `bj'[1, `k']     in `obs'
            qui replace _se    = `sj'[1, `k']     in `obs'
            qui replace _ci_lo = `bj'[1,`k'] - 1.96*`sj'[1,`k'] in `obs'
            qui replace _ci_up = `bj'[1,`k'] + 1.96*`sj'[1,`k'] in `obs'
        }
    }

    * MATLAB-style color palette for variables
    local colors `""24 116 205" "220 50 50" "34 139 34" "148 103 189" "255 127 14""'

    * Generate plot
    local plotcmd ""
    forvalues k = 1/`dk' {
        local kc : word `k' of `colors'
        local plotcmd `"`plotcmd' (rcap _ci_up _ci_lo _level if _varid==`k', lcolor("`kc'%60"))"'
        local plotcmd `"`plotcmd' (scatter _beta _level if _varid==`k', mcolor("`kc'") msymbol(circle) msize(medium))"'
    }

    * Legend: "Regressor 1...k" — labels are scale-dependent because the
    * dependent variable shifts per scale (YmaxR), so generic IDs are
    * less misleading than fixed variable names.
    local legopts ""
    forvalues k = 1/`dk' {
        local pos = `k' * 2
        local legopts `"`legopts' `pos' "Regressor `k'""'
    }

    twoway `plotcmd' ///
        (function y=0, range(0.5 `= `levels' + 0.5') ///
            lcolor(gs8) lpattern(dash) lwidth(thin)) ///
        , ///
        legend(order(`legopts') rows(1) size(small) region(lstyle(none))) ///
        xtitle("Wavelet scale") ///
        ytitle("Regression coefficient") ///
        xlabel(1(1)`levels') ///
        note("Error bars = 95% CI; dependent variable per scale = YmaxR", size(small)) ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        scheme(s2mono) ///
        name(wmreg, replace)

    restore
end
