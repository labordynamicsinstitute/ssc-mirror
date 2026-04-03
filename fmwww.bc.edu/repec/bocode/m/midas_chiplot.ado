*! midas_chiplot - Chi-plot for bivariate association
*! version 3.00 24mar2026
*! Pure Stata implementation (no Mata)

cap program drop midas_chiplot
program define midas_chiplot
version 15.1

syntax varlist(num min=4 max=4 numeric) [if] [in] [, SCATTERopts(string asis) FITopts(string asis) CHIopts(string asis) *]
marksample touse
tokenize `varlist'
local tp `1'
local fp `2'
local fn `3'
local tn `4'

preserve
qui keep if `touse'

tempvar logitse logitsp pid
qui gen double `logitse' = logit((`tp' + 0.5) / (`tp' + `fn' + 1))
qui gen double `logitsp' = logit((`tn' + 0.5) / (`tn' + `fp' + 1))
qui gen `pid' = _n

local chivar1 `logitse'
local chivar2 `logitsp'

qui {
    tempvar ry rx Hi Fi Gi Si CHIi Li
    * Gi
    egen `ry' = rank(`chivar1'), field
    gsort -`ry'
    gen `Gi' = (_N - `ry') / (_N - 1)
    * Fi
    egen `rx' = rank(`chivar2'), field
    gsort -`rx'
    gen `Fi' = (_N - `rx') / (_N - 1)
    * Hi
    sort `ry'
    by `ry': replace `ry' = _N
    sort `chivar1'
    tempname xi
    gen `Hi' = 0
    local r1 = 1
    local N = _N
    forvalues i = 1/`N' {
        if `chivar1'[`i'] == `chivar1'[`i'-1] {
            local r1 = `r1' + 1
        }
        else {
            local r1 = 1
        }
        local k = min(`N', `i' + `ry'[`i'] - `r1')
        scalar `xi' = `chivar2'[`i']
        qui count if `chivar2' <= `xi' & _n != `i' in 1/`k'
        replace `Hi' = r(N) in `i'
    }
    replace `Hi' = `Hi' / (_N - 1)
    * Si, CHIi, Li
    gen `Si'   = sign((`Fi' - .5)*(`Gi' - .5))
    gen `CHIi' = (`Hi' - `Fi'*`Gi') / (`Fi'*(1-`Fi')*`Gi'*(1-`Gi'))^.5
    gen `Li'   = 4 * `Si' * max((`Fi'-.5)^2, (`Gi'-.5)^2)
    label var `CHIi' "{&chi} statistic"
    label var `Li'   "{&lambda} statistic"

    spearman `chivar1' `chivar2'
    local r = r(rho)
}
local note: di "Spearman rho = " %4.3f `r'
local cp  = 1.78 / sqrt(_N)
local cphi =  `cp'
local cplo = -`cp'

* Scatterplot
#delimit ;
twoway
    (scatter `chivar1' `chivar2', `=cond(!missing("`scatteropts'"), "`scatteropts'", "mlw(medthin) mlc(black) mfc(gs15) msize(*1.5) ms(O)")')
    (lfit    `chivar1' `chivar2', `=cond(!missing("`fitopts'"), "`fitopts'", "")' )
    (scatter `chivar1' `chivar2', ms(i) mlabp(0) mlabel(`pid') mlabs(*.5) mlabc(black)),
    name(midas_splot, replace)
    title("Scatter Plot" "`note'")
    ytitle("Logit Sensitivity")
    xtitle("Logit Specificity")
    legend(off)
    nodraw `options' ;
#delimit cr

* Chi-plot
#delimit ;
twoway
    (scatter `CHIi' `Li', `=cond(!missing("`chiopts'"), "`chiopts'", "mlw(medthin) mlc(black) mfc(gs15) msize(*1.5) ms(S)")')
    (scatter `CHIi' `Li', ms(i) mlabp(0) mlabel(`pid') mlabs(*.5) mlabc(black)),
    yline(`cplo' `cphi', lpat(solid) lwidth(medthick) lcolor(red))
    yline(0, lpat(dash) lwidth(vvthin))
    xline(0, lpat(dash) lwidth(vvthin))
    xla(-1(0.5)1) yla(-1(.5)1, angle(360))
    title("Chi-Plot")
    ytitle("{&chi} statistic")
    xtitle("{&lambda} statistic")
    legend(off)
    name(midas_cplot, replace)
    nodraw `options' ;
#delimit cr

nois graph combine midas_splot midas_cplot, `options'
cap graph drop midas_splot midas_cplot

restore
end
