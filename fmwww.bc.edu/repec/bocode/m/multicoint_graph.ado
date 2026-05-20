*! multicoint_graph v1.0.2  18may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Diagnostic graphs after {bf:multicoint}.
*! Produces:
*!   1) Flow series  y_t, x_t      (top row)
*!   2) Cumulated series Y_t, X_t  (bottom row)
*!   3) Cumulated equilibrium error S_t = cumsum(Z_t)
*!   4) Multicoint regression residual  u_t = Y_t - a - b'X_t - g'x_t
*!   5) Long-run scatter / histogram (six-panel)

program define multicoint_graph
    version 14.0
    if "`e(cmd)'" != "multicoint" {
        di as err "you must run {bf:multicoint} first"
        exit 301
    }
    syntax [, SAVE(string) NAME(string) SCHeme(string) ///
              ONEPanel TWOpanel FOURpanel SIXpanel  ///
              TItle(string) NOTE(string) ]

    if "`scheme'" == "" local scheme s2color
    if "`name'"   == "" local name   mc_diag
    if "`title'"  == "" local title "Multicointegration diagnostic plots"
    if "`note'"   == "" local note  "multicoint - `e(estimator)' (`e(test)' test)"

    local layout fourpanel
    if "`onepanel'"  != "" local layout onepanel
    if "`twopanel'"  != "" local layout twopanel
    if "`fourpanel'" != "" local layout fourpanel
    if "`sixpanel'"  != "" local layout sixpanel

    * --------- snapshot e() now (regress below will overwrite it) ---------
    qui tsset, noquery
    local tvar  = r(timevar)
    local yv    = "`e(depvar)'"
    local indep = "`e(indepvars)'"
    local xv    : word 1 of `indep'
    local uhat  = "`e(resvar)'"
    local Ycv   = "`e(Ycumvar)'"
    local Xcv   : word 1 of `e(Xcumvars)'
    tempvar smask
    qui gen byte `smask' = e(sample)

    * --------- recover cumulated cointegration error (Granger-Lee S_t) ----
    cap drop _mc_Sgl
    cap drop _mc_Zgl

    * Save the current ereturn so internal regress doesn't clobber it.
    tempname mc_save
    _estimates hold `mc_save', copy

    * Stage 1: y on flow x
    qui regress `yv' `indep' if `smask'
    qui predict double _mc_Zgl if `smask', resid
    label var _mc_Zgl "Stage 1 residual Z_t (y on x)"

    * Restore original multicoint estimates so e(cmd) etc. survive
    _estimates unhold `mc_save'

    qui sort `tvar'
    qui gen double _mc_Sgl = sum(_mc_Zgl) if `smask'
    label var _mc_Sgl "Cumulated equilibrium error S_t"

    local gopts xtitle("`tvar'") graphregion(color(white))                ///
                plotregion(color(white)) lwidth(medthick) scheme(`scheme')

    * (1) Flow series
    qui tsline `yv' `xv' if `smask', name(g_flow, replace)                ///
        `gopts'                                                            ///
        title("Flow series", size(small))                                  ///
        legend(order(1 "`yv' (y)" 2 "`xv' (x)") rows(1) size(small))

    * (2) Cumulated I(2) series
    qui tsline `Ycv' `Xcv' if `smask', name(g_cum, replace)               ///
        `gopts'                                                            ///
        title("Cumulated I(2) series", size(small))                        ///
        legend(order(1 "Y_t = sum y" 2 "X_t = sum x") rows(1) size(small))

    * (3) Cumulated equilibrium error S_t
    qui tsline _mc_Sgl if `smask', name(g_Scoint, replace)                ///
        `gopts' lcolor(maroon)                                             ///
        title("Cumulated equilibrium error S_t (GL stage 1)", size(small))  ///
        yline(0, lc(gs10) lp(dash))

    * (4) Multicoint regression residual u_hat
    qui tsline `uhat' if `smask', name(g_uhat, replace)                   ///
        `gopts' lcolor(forest_green)                                       ///
        title("Multicoint regression residual u_t", size(small))           ///
        yline(0, lc(gs10) lp(dash))

    if "`layout'" == "onepanel" {
        graph display g_uhat, name(`name', replace) scheme(`scheme')
    }
    else if "`layout'" == "twopanel" {
        graph combine g_flow g_cum, cols(2) name(`name', replace)         ///
            title("`title'", size(small)) note("`note'", size(small)) scheme(`scheme')
    }
    else if "`layout'" == "fourpanel" {
        graph combine g_flow g_cum g_Scoint g_uhat, cols(2) rows(2)       ///
            name(`name', replace) iscale(0.85)                             ///
            title("`title'", size(small)) note("`note'", size(small)) scheme(`scheme')
    }
    else if "`layout'" == "sixpanel" {
        qui twoway (scatter `Ycv' `Xcv' if `smask', msize(small) mcolor(navy%30)) ///
                   (lfit    `Ycv' `Xcv' if `smask', lcolor(red)),                  ///
            name(g_scat, replace) graphregion(color(white))                        ///
            title("Long-run scatter Y vs X", size(small))                          ///
            legend(off) xtitle("`Xcv'") ytitle("`Ycv'") scheme(`scheme')
        qui histogram `uhat' if `smask', normal                                    ///
            name(g_hist, replace) graphregion(color(white))                        ///
            title("Distribution of u_t (with N fit)", size(small)) scheme(`scheme')
        graph combine g_flow g_cum g_Scoint g_uhat g_scat g_hist, cols(2) rows(3)  ///
            name(`name', replace) iscale(0.7)                                       ///
            title("`title'", size(small)) note("`note'", size(small)) scheme(`scheme')
    }

    if "`save'" != "" {
        graph export "`save'", replace
        di as txt "Saved graph to: " as res "`save'"
    }
end
