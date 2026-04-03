*! version 1.10 29nov2025
*! midas_ord2bin - Convert Ordinal Test Results to Binary 2x2 Tables
*! Ben A. Dwamena, University of Michigan

capture program drop midas_ord2bin
program define midas_ord2bin, rclass byable(recall)
version 13

syntax varlist(min=5 max=5 numeric) [if] [in], ///
IDvar(varname) ///
SAVEData(string) ///
[THRESHold(string) ///
REPlace ///
DETail ///
NOIsily]

marksample touse, novarlist

// Parse savedata option for replace
tokenize `"`savedata'"', parse(",")
local savefile = trim(subinstr(`"`1'"', `"""', "", .))

// Check if file exists and replace not specified
if "`replace'" == "" {
capture confirm file "`savefile'.dta"
if !_rc {
di as error "file `savefile'.dta already exists"
di as error "specify replace option to overwrite"
exit 602
}
}

// Validate input
qui count if `touse'
if r(N) == 0 {
di as error "no observations"
exit 2000
}

quietly keep if `touse'

// Unpack variables
tokenize `varlist'
tempvar Score test1 test0 ref1 ref0
gen `Score' = `1'
gen `test1' = `2' // diseased counts at each score
gen `test0' = `3' // non-diseased counts at each score
gen `ref1' = `4' // total diseased (should be constant within study)
gen `ref0' = `5' // total non-diseased (should be constant within study)

// Validate that reference totals are constant within studies
qui {
tempvar check_ref1 check_ref0
bysort `idvar' (`Score'): egen `check_ref1' = min(`ref1')
bysort `idvar' (`Score'): egen `check_ref0' = min(`ref0')

count if `ref1' != `check_ref1'
if r(N) > 0 {
noi di as error "Error: Reference diseased count varies within study"
noi di as error "The 4th variable should be constant within each study"
exit 198
}

count if `ref0' != `check_ref0'
if r(N) > 0 {
noi di as error "Error: Reference non-diseased count varies within study"
noi di as error "The 5th variable should be constant within each study"
exit 198
}
}

// Validate counts
qui {
tempvar total_dis total_ndis
bysort `idvar': egen `total_dis' = total(`test1')
bysort `idvar': egen `total_ndis' = total(`test0')

count if abs(`total_dis' - `ref1') > 0.01 & !missing(`ref1')
if r(N) > 0 {
noi di as error "Warning: Sum of diseased counts doesn't match reference total in some studies"
noi di as error "This may indicate data entry errors"
}

count if abs(`total_ndis' - `ref0') > 0.01 & !missing(`ref0')
if r(N) > 0 {
noi di as error "Warning: Sum of non-diseased counts doesn't match reference total in some studies"
noi di as error "This may indicate data entry errors"
}
}

// Set default threshold method
if "`threshold'" == "" {
local threshold "youden"
}

// Validate threshold method
if !inlist("`threshold'", "youden", "topleft", "product") {
di as error "threshold(`threshold') invalid"
di as error "valid options are: youden, topleft, product"
exit 198
}

if "`noisily'" != "" | "`detail'" != "" {
di as text _n "Converting ordinal test results to binary 2x2 tables..."
di as text "Threshold selection method: " as result "`threshold'"
di as text "{hline 70}"
}

tempfile results
tempname fh
quietly postfile `fh' str30 studyid threshold tp fp fn tn ///
using "`results'", replace

quietly levelsof `idvar', local(studies)
local nstudy: word count `studies'
local current = 0

// detect whether idvar is string or numeric
capture confirm string variable `idvar'
local _idvar_isstr = (_rc == 0)

foreach s of local studies {
local ++current
if "`noisily'" != "" {
di as text "Processing study `current' of `nstudy': `s'"
}

preserve
quietly {
    if `_idvar_isstr' {
        keep if `idvar' == `"`s'"'
    }
    else {
        keep if `idvar' == `s'
    }
}

// Get totals
qui {
egen ndis = total(`test1')
egen nndis = total(`test0')

local n_diseased = ndis[1]
local n_nondiseased = nndis[1]
}

// Sort scores ascending
sort `Score'
quietly levelsof `Score', local(scores)

quietly {
    tempvar TPR FPR Criterion
    gen double `TPR' = .
    gen double `FPR' = .
    gen double `Criterion' = .
}

// For each threshold: test+ if Score >= c
foreach c of local scores {
qui {
egen double _tp = total(`test1') if `Score' >= `c'
egen double _fp = total(`test0') if `Score' >= `c'

replace `TPR' = _tp / ndis if `Score' == `c'
replace `FPR' = _fp / nndis if `Score' == `c'

// Calculate criterion based on method
if "`threshold'" == "youden" {
replace `Criterion' = `TPR' - `FPR' if `Score' == `c'
}
else if "`threshold'" == "topleft" {
// Distance from top-left corner (0,1)
replace `Criterion' = -sqrt((1-`TPR')^2 + `FPR'^2) if `Score' == `c'
}
else if "`threshold'" == "product" {
// Product of sensitivity and specificity
replace `Criterion' = `TPR' * (1-`FPR') if `Score' == `c'
}

drop _tp _fp
}
}

// Select best threshold
qui {
    summarize `Criterion' if !missing(`Criterion'), meanonly
    if r(N) == 0 {
        // fallback: use median score
        summarize `Score', meanonly
        local thr = r(mean)
        local crit = .
    }
    else {
        local best_crit = r(max)
        keep if abs(`Criterion' - `best_crit') < 1e-10 & !missing(`Criterion')

        // Pick first (lowest score) if ties
        sort `Score'
        keep in 1

        local thr = `Score'[1]
        local crit = `Criterion'[1]
    }
}

if "`detail'" != "" {
di as text " Optimal threshold: " as result `thr' ///
as text " (criterion = " as result %5.3f `crit' as text ")"
di as text " TPR = " as result %5.3f `TPR'[1] ///
as text ", FPR = " as result %5.3f `FPR'[1]
}

// Compute 2x2 at this threshold using known totals
// tp and fp come from the threshold; fn and tn from subtraction
qui {
    local Lfn = `n_diseased' - round(`TPR'[1] * `n_diseased')
    local Ltp = `n_diseased' - `Lfn'
    local Lfp = round(`FPR'[1] * `n_nondiseased')
    local Ltn = `n_nondiseased' - `Lfp'
}

// Validate 2x2 table
if "`detail'" != "" | "`noisily'" != "" {
    if `Ltp' + `Lfn' != `n_diseased' {
        noi di as txt "  Note: Study `s' - tp+fn != total diseased (threshold-based approximation)"
    }
    if `Lfp' + `Ltn' != `n_nondiseased' {
        noi di as txt "  Note: Study `s' - fp+tn != total non-diseased (threshold-based approximation)"
    }
}

post `fh' ("`s'") (`thr') (`Ltp') (`Lfp') (`Lfn') (`Ltn')

restore
}

postclose `fh'

// Load results and add derived measures
use "`results'", clear

quietly {
    // Add sensitivity and specificity
    gen sensitivity = tp/(tp+fn)
    gen specificity = tn/(tn+fp)
    gen n_diseased = tp + fn
    gen n_nondiseased = fp + tn
    gen n_total = n_diseased + n_nondiseased
}

// Label variables
label variable studyid "Study identifier"
label variable threshold "Optimal threshold value"
label variable tp "True positives"
label variable fp "False positives"
label variable fn "False negatives"
label variable tn "True negatives"
label variable sensitivity "Sensitivity at optimal threshold"
label variable specificity "Specificity at optimal threshold"
label variable n_diseased "Total diseased"
label variable n_nondiseased "Total non-diseased"
label variable n_total "Total sample size"

// Display summary — always show brief; detail adds full table
di as txt _n "{hline 60}"
di as txt "  ord2bin: Ordinal to 2x2 table conversion"
di as txt "  Studies: " as res `nstudy' as txt "   Method: " as res "`threshold'"
di as txt "{hline 60}"
local _nshow = min(5, _N)
list studyid threshold tp fp fn tn in 1/`_nshow', noobs separator(0) abbreviate(12)
if _N > 5 {
    di as txt "  ... (`=_N - 5' more studies)"
}

if "`noisily'" != "" | "`detail'" != "" {
    di as txt _n "{hline 60}"
    qui sum sensitivity
    di as txt "  Sensitivity range: " as res %5.3f r(min) " - " %5.3f r(max)
    qui sum specificity
    di as txt "  Specificity range: " as res %5.3f r(min) " - " %5.3f r(max)
    di as txt "{hline 60}"
}

// Check for zero cells
qui {
count if tp == 0 | fp == 0 | fn == 0 | tn == 0
if r(N) > 0 {
local nzero = r(N)
noi di as text _n "Note: " as result `nzero' ///
as text " studies have zero cells"
noi di as text "Consider applying continuity correction before meta-analysis"
}
}

// Save
save "`savefile'", replace

di as text _n "Binary 2x2 table data saved to: " as result "`savefile'.dta"

// Return values
return scalar N = `nstudy'
return local threshold "`threshold'"
return local savefile "`savefile'"
end
