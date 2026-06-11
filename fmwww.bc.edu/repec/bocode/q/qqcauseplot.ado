*! qqcauseplot 1.0.0 16may2026
*! Plot QQ causality test statistics with significance bands
*! Author: Merwan Roudane

program qqcauseplot
    version 14
    syntax [using/] [,                  ///
        Title(string)                   ///
        SUBtitle(string)                ///
        XTitle(string)                  ///
        YTitle(string)                  ///
        SAVE(string)                    ///
        Name(string asis)               ///
        SCheme(string)                  ///
        REPLACE ]

    if "`title'"==""  local title  "Nonparametric Quantile Causality"
    if "`xtitle'"=="" local xtitle "{&tau} (quantile of effect)"
    if "`ytitle'"=="" local ytitle "Test statistic"
    if "`scheme'"=="" local scheme "s2color"

    preserve
    if `"`using'"' != "" use `"`using'"', clear

    foreach v in tau tstat {
        cap confirm variable `v'
        if _rc {
            di as err "expected variable `v' in dataset"
            exit 111
        }
    }

    local nameopt
    if `"`name'"' != "" {
        if strpos(`"`name'"', ",") local nameopt name(`name')
        else                       local nameopt name(`name', replace)
    }

    twoway                                                          ///
        (area tstat tau if abs(tstat) > 1.96,                        ///
            color(red%20))                                           ///
        (line tstat tau, lcolor(navy) lwidth(medthick))              ///
        (function y = 1.96,  range(0 1) lpattern(dash) lcolor(red))  ///
        (function y = -1.96, range(0 1) lpattern(dash) lcolor(red))  ///
        (function y = 1.645, range(0 1) lpattern(longdash) lcolor(orange)) ///
        (function y = -1.645,range(0 1) lpattern(longdash) lcolor(orange)) ///
        (function y = 0,     range(0 1) lcolor(black) lwidth(thin)), ///
        title(`"`title'"', size(medium))                             ///
        subtitle(`"`subtitle'"', size(small))                        ///
        xtitle(`"`xtitle'"') ytitle(`"`ytitle'"')                    ///
        legend(order(2 "T-stat" 3 "5% CV" 5 "10% CV") rows(1)        ///
            size(small))                                             ///
        scheme(`scheme') `nameopt'

    if `"`save'"' != "" {
        if "`replace'"=="replace" graph export `"`save'"', replace
        else                       graph export `"`save'"'
    }

    restore
end
