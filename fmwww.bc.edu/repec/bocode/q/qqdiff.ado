*! qqdiff 1.0.0 16may2026
*! Difference-of-surfaces diagnostics for QQR  beta(tau,theta)
*! Author: Merwan Roudane
*!
*! Reads draws file(s) written by  qqr ... , bsave("draws.dta")
*! Two modes:
*!   (default) asymmetry  diff(tau,theta) = beta(tau,theta) - beta(1-tau,theta)
*!                        with a paired two-sided bootstrap p per cell.
*!   compare(file2)       diff = beta_1(tau,theta) - beta_2(tau,theta) across
*!                        two draws files; p from a normal-approx z using the
*!                        per-cell bootstrap SDs (independent-samples).
*! Renders the difference as a starred heatmap (redwhitegreen) by default.

program qqdiff, rclass
    version 14
    syntax [using/] [, COMPARE(string) COLORMAP(name) NOHEAT          ///
        TITLE(string) NAME(string asis) SAVE(string)                  ///
        SAVING(string) REPLACE * ]

    if "`colormap'"=="" local colormap "redwhitegreen"

    tempname OUT A Bm
    tempfile diffdta

    * ---------- compute the difference grid into matrix `OUT' ----------
    if `"`compare'"' == "" {
        * ---- asymmetry mode (single draws file) ----
        preserve
        if `"`using'"' != "" qui use `"`using'"', clear
        foreach v in rep tau theta beta {
            cap confirm variable `v'
            if _rc {
                di as err "expected variable {bf:`v'} in the draws file"
                exit 111
            }
        }
        mata: lqqr_boot_recon()
        mata: lqqr_qqdiff_asym("`OUT'")
        restore
        if `"`title'"' == "" local title "QQR asymmetry: beta(tau,theta) - beta(1-tau,theta)"
    }
    else {
        * ---- compare mode (two draws files) ----
        preserve
        if `"`using'"' != "" qui use `"`using'"', clear
        mata: lqqr_boot_recon()
        mata: lqqr_cellsummary("`A'")
        restore
        preserve
        qui use `"`compare'"', clear
        mata: lqqr_boot_recon()
        mata: lqqr_cellsummary("`Bm'")
        restore
        if rowsof(`A') != rowsof(`Bm') {
            di as err "the two draws files have different grids (cannot compare)"
            exit 198
        }
        * combine: diff = b1 - b2 ; se = sqrt(sd1^2+sd2^2) ; p = 2*Phi(-|z|)
        mata: lqqr_qqdiff_combine("`A'", "`Bm'", "`OUT'")
        if `"`title'"' == "" local title "QQR difference: surface 1 - surface 2"
    }

    * ---------- write the difference dataset (tau theta coef p) ----------
    preserve
    drop _all
    qui svmat double `OUT'
    rename `OUT'1 tau
    rename `OUT'2 theta
    rename `OUT'3 coef
    rename `OUT'4 p
    qui drop if missing(coef)
    label var coef "difference"
    if `"`saving'"' != "" {
        if "`replace'"=="replace" qui save `"`saving'"', replace
        else                      qui save `"`saving'"'
    }
    qui save `"`diffdta'"', replace
    restore

    * ---------- heatmap ----------
    if "`noheat'" == "" {
        local namopt
        if `"`name'"' != "" local namopt name(`name')
        local savopt
        if `"`save'"' != "" local savopt save(`"`save'"')
        qqheat using `"`diffdta'"', value(coef) colormap(`colormap') sigmark ///
            title(`"`title'"') ztitle("difference") `namopt' `savopt' `replace' `options'
    }

    return local mode = cond(`"`compare'"'=="", "asymmetry", "compare")
end
