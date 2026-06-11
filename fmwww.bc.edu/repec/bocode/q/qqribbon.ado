*! qqribbon 1.0.0 16may2026
*! Per-quantile CI ribbon (slice) of the QQR surface beta(tau,theta)
*! Author: Merwan Roudane
*!
*! Reads a draws file written by  qqr ... , bsave("draws.dta")
*! Fix one quantile dimension and plot beta vs. the other, with a pointwise
*! bootstrap CI band and (optional) a joint sup-t band.
*!   theta(#)  fix theta (nearest grid value), vary tau   on the x-axis
*!   tau(#)    fix tau   (nearest grid value), vary theta on the x-axis

program qqribbon, rclass
    version 14
    syntax [using/] [, THETA(real -1) TAU(real -1) LEVel(cilevel) JOINT ///
        TITLE(string) SUBTITLE(string) XTITLE(string) YTITLE(string)    ///
        SAVE(string) NAME(string asis) SCHEME(name) REPLACE ]

    if "`scheme'"=="" local scheme "s2color"

    if (`theta' < 0 & `tau' < 0) | (`theta' >= 0 & `tau' >= 0) {
        di as err "specify exactly one of {bf:theta()} or {bf:tau()}"
        exit 198
    }
    if `theta' >= 0 {
        local fixdim 1
        local fixval `theta'
        local fixlab "theta"
        local varlab "tau"
    }
    else {
        local fixdim 2
        local fixval `tau'
        local fixlab "tau"
        local varlab "theta"
    }

    preserve
    if `"`using'"' != "" qui use `"`using'"', clear

    foreach v in rep tau theta beta {
        cap confirm variable `v'
        if _rc {
            di as err "expected variable {bf:`v'} in the draws file " ///
                "(create it with {bf:qqr ..., bsave())})"
            exit 111
        }
    }

    mata: lqqr_boot_recon()

    tempname OUT
    mata: lqqr_ribbon_data(`fixdim', `fixval', `level', "`OUT'")

    drop _all
    qui svmat double `OUT'
    rename `OUT'1 xval
    rename `OUT'2 bhat
    rename `OUT'3 lo
    rename `OUT'4 hi
    rename `OUT'5 jlo
    rename `OUT'6 jhi
    qui drop if missing(xval)
    sort xval

    if `"`title'"'  == "" local title  "QQR slice: `varlab' effect"
    if `"`xtitle'"' == "" local xtitle "`varlab'"
    if `"`ytitle'"' == "" local ytitle "coefficient  beta"

    local namopt
    if `"`name'"' != "" {
        if strpos(`"`name'"', ",") local namopt name(`name')
        else                       local namopt name(`name', replace)
    }

    local jointlayer
    local jointnote
    if "`joint'" != "" {
        local jointlayer (rarea jhi jlo xval, color(navy%12) lwidth(none))
        local jointnote "shaded: `level'% pointwise (dark) & joint sup-t (light) bands"
    }
    else {
        local jointnote "shaded: `level'% pointwise bootstrap band"
    }

    twoway `jointlayer'                                                  ///
           (rarea hi lo xval, color(navy%30) lwidth(none))              ///
           (line bhat xval, lcolor(navy) lwidth(medthick)),             ///
           yline(0, lcolor(gs8) lpattern(dash))                         ///
           title(`"`title'"', size(medium))                             ///
           subtitle(`"`subtitle'"')                                     ///
           xtitle(`"`xtitle'"') ytitle(`"`ytitle'"')                    ///
           note(`"fixed `fixlab' (nearest grid).  `jointnote'"', size(vsmall)) ///
           legend(off) scheme(`scheme') `namopt'

    if `"`save'"' != "" {
        if "`replace'"=="replace" graph export `"`save'"', replace
        else                      graph export `"`save'"'
    }

    restore
end
