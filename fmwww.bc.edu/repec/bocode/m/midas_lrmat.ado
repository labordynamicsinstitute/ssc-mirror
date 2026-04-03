*! midas_lrmat - Likelihood Ratio Matrix
cap program drop midas_lrmat
program midas_lrmat
syntax [if] [in], ///
[ LEVEL(integer 95) ///
WGT ///
cc(real 0.5) ///
XRANge(numlist min=2 max=2 ascending) ///
YRANge(numlist min=2 max=2 ascending) ///
* ]

capture assert e(package) == "midas"
if _rc != 0 {
di as error "Last estimation command was not a midas subcommand such as mle, qrsim, hmc, mh or inla"
error 301
}

preserve

*--- Summary PLR/NLR from previous midas_* command ----------------------
if e(cmd) == "midas_mle" | e(cmd) == "midas_qrsim" | e(cmd) == "midas_qrsim" | e(cmd) == "midas_qrsim" | e(cmd) == "midas_qrsim" {
tempname lrpm blratio Vlratio
mat `blratio' = e(bsum)
mat `Vlratio' = e(Vsum)
qui _coef_table, bmatrix(`blratio') vmatrix(`Vlratio')
mat `lrpm' = r(table)'
local mlrp = `lrpm'[4,1]
local mlrplo = `lrpm'[4,5]
local mlrphi = `lrpm'[4,6]
local mlrn = `lrpm'[5,1]
local mlrnlo = `lrpm'[5,5]
local mlrnhi = `lrpm'[5,6]
}
else if e(cmd) == "midas_inla" | e(cmd) == "midas_mh" | e(cmd) == "midas_hmc" {
tempname lrp lrn sen spe
if e(cmd) == "midas_mh" {
	local _mf = e(midas_filename)
	clear
	qui use "`_mf'", clear
}
else {
	mat data = e(midas_sim_data)
	clear
	qui svmat data, names(col)
}
gen double `sen' = invlogit(logitsen)
gen double `spe' = invlogit(logitspe)
gen double `lrp' = `sen'/(1-`spe')
gen double `lrn' = (1-`sen')/`spe'
qui midas sumstats `lrp' `lrn'
local mlrp = min(100, r(mn1))
local mlrplo = min(100, r(lb1))
local mlrphi = min(100, r(ub1))
local mlrn = r(mn2)
local mlrnlo = r(lb2)
local mlrnhi = r(ub2)
}

*--- Back to study-level 2x2 data --------------------------------------
clear
tempvar zero zc_sens zc_fpr zc_spec zc_tpr zc_fnr lrp lrn pid

gen `zero' = 0
mat varrslist = e(varlist)
qui svmat varrslist, names(col)

* continuity correction for zero cells
qui replace `zero' = 1 if tp == 0 | fp == 0 | fn == 0 | tn == 0
qui replace tp = tp + `cc' if `zero' == 1
qui replace fp = fp + `cc' if `zero' == 1
qui replace fn = fn + `cc' if `zero' == 1
qui replace tn = tn + `cc' if `zero' == 1

qui gen `zc_sens' = tp/(tp+fn)
qui gen `zc_fnr' = fn/(tp+fn)
qui gen `zc_spec' = tn/(tn+fp)
qui gen `zc_fpr' = fp/(tn+fp)
qui gen `lrp' = `zc_sens'/`zc_fpr'
qui gen `lrn' = `zc_fnr'/`zc_spec'
qui gen `pid' = _n

*--- Quadrant interpretation notes -------------------------------------
local note1a : di "{bf: Left Upper Quadrant:}"
local note1b : di "PLR>10, NLR<0.1"
local note1c : di "Exclusion & Confirmation"
local note1d : di "Substantial Informativeness"

local note2a : di "{bf: Right Upper Quadrant:}"
local note2b : di "PLR>10, NLR>0.1"
local note2c : di "Confirmation Only"
local note2d : di "Moderate Informativeness"

local note3a : di "{bf: Left Lower Quadrant:}"
local note3b : di "PLR<10, NLR<0.1"
local note3c : di "Exclusion Only"
local note3d : di "Moderate Informativeness"

local note4a : di "{bf: Right Lower Quadrant:}"
local note4b : di "PLR<10, NLR>0.1"
local note4c : di "No Exclusion or Confirmation"
local note4d : di "Minimal Informativeness"

*--- Weighted vs unweighted points -------------------------------------
if !missing("`wgt'") {
tempvar wgted
// Extract bivariate weight via standardized helper
tempvar _sw _spw
_midas_getwgts, senwgt(`_sw') spewgt(`_spw') bivwgt(`wgted')
local splot1 ///
"(scatter `lrp' `lrn' [aw = `wgted'], sort mlw(medthin) mlc(black) mfc(gs15) msize(*1.0) ms(O)) "
}
else {
local splot1 ///
"(scatter `lrp' `lrn', sort mlw(medthin) mlc(black) mfc(gs15) msize(*1.5) ms(O))"
}

local splot2 ///
"(scatter `lrp' `lrn', ms(i) mlabp(0) mlabel(`pid') mlabs(*.5) mlabc(black))"
local splot3 ///
"(scatteri `mlrp' `mlrn', msymbol(D) msize(large) clcol(black) clwidth(medium))"
local splot4 ///
"(scatteri `mlrp' `mlrnlo' `mlrp' `mlrnhi', recast(line) clcol(black) clpat(solid) clwidth(medium))"
local splot5 ///
"(scatteri `mlrplo' `mlrn' `mlrphi' `mlrn', recast(line) clcol(black) clpat(solid) clwidth(medium))"

*--- Handle default vs user-specified axis ranges ----------------------
* X axis (NLR)
if missing("`xrange'") {
* default: symmetric (log) around NLR = 0.1 -> equal quadrants
local xlo = 0.01
local xhi = 1
local xlab `"xlab(0.01 "0.01" 0.1 "0.1" 1 "1", labsize(*.75))"'
local xscale `"xscale(log range(0.01 1))"'
}
else {
tokenize "`xrange'"
local xlo `1'
local xhi `2'
local xlab "" // let Stata choose ticks
local xscale `"xscale(log range(`xlo' `xhi'))"'
}

* Y axis (PLR)
if missing("`yrange'") {
* default: symmetric (log) around PLR = 10 -> equal quadrants
local ylo = 1
local yhi = 100
local ylab `"ylab(1 10 100, labsize(*.75) angle(horizontal))"'
local yscale `"yscale(log range(1 100))"'
}
else {
tokenize "`yrange'"
local ylo `1'
local yhi `2'
local ylab `"ylab(`ylo' `yhi', labsize(*.75) angle(horizontal))"' // simple labels
local yscale `"yscale(log range(`ylo' `yhi'))"'
}

local xxopts1 ///
`"xtitle("{bf: Negative Likelihood Ratio (NLR)}", size(*.75)) `xlab' `xscale'"'
local xxopts2 ///
`"xline(0.1, lpattern(shortdash) lwidth(vthin))"'

local yyopts1 ///
`"ytitle("{bf: Positive Likelihood Ratio (PLR)}", size(*.75)) `yscale' `ylab'"'
local yyopts2 ///
`"yline(10, lpattern(shortdash) lwidth(vthin))"'

*--- Draw graph --------------------------------------------------------
#delimit ;
nois tw `splot1' `splot2' `splot3' `splot4' `splot5',
`xxopts1' `xxopts2' `yyopts1' `yyopts2'
plotregion(margin(zero))
legend(
order(
3 "Summary PLR & NLR"
4 "`note1a'" "`note1b'" "`note1c'" "`note1d'"
5 "`note2a'" "`note2b'" "`note2c'" "`note2d'"
6 "`note3a'" "`note3b'" "`note3c'" "`note3d'"
7 "`note4a'" "`note4b'" "`note4c'" "`note4d'"
)
pos(3) symxsize(0) forcesize rowgap(1) col(1) size(*.4)
)
aspectr(1)
`options' ;
#delimit cr

restore
end

// Standardized weight extraction from e(studywgts)
capture program drop _midas_getwgts
program define _midas_getwgts
    version 16
    syntax, SENwgt(string) SPEwgt(string) BIVwgt(string)
    capture confirm matrix e(studywgts)
    if _rc {
        qui gen double `senwgt' = 100 / _N
        qui gen double `spewgt' = 100 / _N
        qui gen double `bivwgt' = 100 / _N
        exit
    }
    tempname wgtmat
    mat `wgtmat' = e(studywgts)
    local ncol = colsof(`wgtmat')
    local nrow = rowsof(`wgtmat')
    if `ncol' < 3 {
        qui gen double `senwgt' = 100 / _N
        qui gen double `spewgt' = 100 / _N
        qui gen double `bivwgt' = 100 / _N
        exit
    }
    qui gen double `senwgt' = .
    qui gen double `spewgt' = .
    qui gen double `bivwgt' = .
    local maxrow = min(`nrow', _N)
    forvalues i = 1/`maxrow' {
        qui replace `senwgt' = `wgtmat'[`i', 1] in `i'
        qui replace `spewgt' = `wgtmat'[`i', 2] in `i'
        qui replace `bivwgt' = `wgtmat'[`i', 3] in `i'
    }
end

