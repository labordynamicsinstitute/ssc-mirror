*! version 0.8.4 21may2024
program xt2treatments, eclass
version 18.0

syntax varname(numeric) [if], treatment(varname numeric) control(varname numeric) [, pre(integer 1) post(integer 3) baseline(string) weighting(string) graph]
if ("`baseline'" == "") {
    local baseline "-1"
}
if ("`weighting'" == "") {
    local weighting "equal"
}
local T1 = `pre'-1
local K = `pre'+`post'+1

marksample touse

* read panel structure
xtset
local group = r(panelvar)
local time = r(timevar)
local y `varlist'

tempvar yg  evert everc time_g dy eventtime n_g n_gt
tempname w W0 bad_coef bad_Var b V Wcum Wsum D  

quietly egen `evert' = max(cond(`touse', `treatment', 0)), by(`group')
quietly egen `everc' = max(cond(`touse', `control', 0)), by(`group')

* no two treatment can happen to the same group
capture assert !(`evert' & `everc') if `touse'
if (_rc) {
    display in red "Some groups receive both treatments"
    inspect `group' if `evert' & `everc' & `touse'
    error(459)
}

quietly egen `time_g' = min(cond(`treatment' | `control', `time', .)) if `touse', by(`group')
* everyone receives treatment
capture assert !missing(`time_g')  if `touse'
if (_rc) {
    display in red "Some groups do not receive any treatment"
    inspect `group' if !`evert' & !`everc' & `touse'
    error(459)
}

quietly generate `eventtime' = `time' - `time_g'  if `touse'
quietly egen `n_gt' = count(1)  if `touse', by(`time_g' `time') 
quietly egen `n_g' = max(`n_gt')  if `touse', by(`time_g')

quietly levelsof `time_g'  if `touse', local(gs)
quietly levelsof `time'  if `touse', local(ts)

local G : word count `gs'
local T : word count `ts'
local N = `G' * (`T' - 1)

tempname n1 n0
matrix `w' = J(`G', `T', 0.0)
forvalues g = 1/`G' {
    forvalues t = 2/`T' {
        local time_t : word `t' of `ts'
        local cohort : word `g' of `gs'
        local e = `time_t' - `cohort'
        if inrange(`e', -`pre', `post') {
            quietly count if `time_g' == `cohort' & (`touse') & `everc' & `time_t' == `time'
            scalar `n0' = r(N)
            quietly count if `time_g' == `cohort' & (`touse') & `evert' & `time_t' == `time'
            scalar `n1' = r(N)
            if ("`weighting'" == "equal") {
                * if either of the groups has no observations, we cannot estimate a treatment effect
                matrix `w'[`g', `t'] = cond(`n0'*`n1'==0, 0.0, 1.0)
            }
            if ("`weighting'" == "proportional") {
                matrix `w'[`g', `t'] = cond(`n0'*`n1'==0, 0.0, `n0' + `n1')
            }
            if ("`weighting'" == "optimal") {
                matrix `w'[`g', `t'] = cond(`n0'*`n1'==0, 0.0, `n0' * `n1' / (`n0' + `n1'))
            }
        }
    }
}

quietly egen `yg' = mean(cond(`eventtime' == -1, `y', .)) if `touse', by(`group')
quietly generate `dy' = `y' - `yg' if `touse'

capture drop _att_*
forvalues g = 1/`G' {
    forvalues t = 2/`T' {
        local running_time : word `t' of `ts'
        local treatment_time : word `g' of `gs'
        quietly generate byte _att_`g'_`t' = cond(`time_g' == `treatment_time' & `time' == `running_time', `evert', 0) if `touse'
    }
}

***** This is the actual estimation
quietly reghdfe `dy' _att_*_* if `touse', a(`time_g'##`time') cluster(`group') nocons
matrix `bad_coef' = e(b)
matrix `bad_Var' = e(V)

local GT = colsof(`bad_coef')

assert `GT' == `G' * `=`T'-1'
assert colsof(`bad_Var') == `GT'

matrix `Wcum' = J(`GT', `K', 0)
local i = 1
forvalues g = 1/`G' {
    forvalues t = 2/`T' {
        local time_t : word `t' of `ts'
        local start : word `g' of `gs'
        local e = `time_t' - `start'
        if inrange(`e', -`pre', `post') {
            matrix `Wcum'[`i', `e' + `pre' + 1] = `w'[`g', `t']
        }
        local i = `i' + 1
    }
}
matrix `Wsum' = J(1, `GT', 1) * `Wcum' 
matrix `D' = diag(`Wsum')
matrix `Wcum' = `Wcum' * inv(`D')

tempvar esample
* exclude observations outside of the event window
quietly generate `esample' = e(sample) 
quietly replace `esample' = 0 if !`touse'
quietly count if `esample'
local Nobs = r(N)
******

capture drop _att_*

if ("`baseline'" == "average") {
    matrix `W0' = I(`K') - (J(`K', `pre', 1/`pre'), J(`K', `post'+1, 0))
}
else if ("`baseline'" == "atet") {
    matrix `W0' = (J(1, `pre', -1/`pre'), J(1, `post'+1, 1/(`post'+1)))
}
else {
    if (!inrange(`baseline', -`pre', -1)) {
        display in red "Baseline must be between -`pre' and -1"
        error 198
    }
    matrix `W0' = I(`K')
    local bl = `pre' + `baseline' + 1
    forvalues i = 1/`K' {
        matrix `W0'[`i', `bl'] = `W0'[`i', `bl'] - 1.0
    }
}
matrix `b' = `bad_coef' * `Wcum' * `W0''
matrix `V' = `W0' * `Wcum'' * `bad_Var' * `Wcum' * `W0''
if ("`baseline'" == "atet") {
    local colnames "ATET"
}
else {
    * label coefficients
    forvalues t = -`pre'/`post' {
        local colnames `colnames' `t'
    }
}
matrix colname `b' = `colnames'
matrix colname `V' = `colnames'
matrix rowname `V' = `colnames'

local level 95
tempname coefplot
matrix `coefplot' = J(`K', 4, .)
matrix colname `coefplot' = xvar b ll ul
local tlabels ""
forvalues t = -`pre'/`post' {
    local tlabels `tlabels' `t'
    local i = `t' + `pre' + 1
    matrix `coefplot'[`i', 1] = `t''
    matrix `coefplot'[`i', 2] = `b'[1, `i']
    matrix `coefplot'[`i', 3] = `b'[1, `i'] + invnormal((100-`level')/200) * sqrt(`V'[`i', `i'])
    matrix `coefplot'[`i', 4] = `b'[1, `i'] - invnormal((100-`level')/200) * sqrt(`V'[`i', `i'])
}

ereturn post `b' `V', obs(`Nobs') esample(`esample')
ereturn local depvar `y'
ereturn local cmd xt2treatments
ereturn local cmdline xt2treatments `0'

_coef_table_header, title(Event study relative to `baseline') width(62)
display
_coef_table, bmat(e(b)) vmat(e(V)) level(`level') 	///
    depname(`depvar') coeftitle(ATET)

if ("`graph'" == "graph") {
    hetdid_coefplot, mat(`coefplot') title(Event study relative to `baseline') ///
        ylb(`y') xlb("Length of exposure to the treatment") ///
        yline(0) legend(off) level(`level') yline(0,  extend) ytick(0, add) ylabel(0, add) xlabel(`tlabels')
}

end

