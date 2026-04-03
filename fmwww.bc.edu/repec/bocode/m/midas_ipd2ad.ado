*! version 2.00  27nov2025
*! midas_ipd2ad - Convert Individual Patient Data to Aggregate Diagnostic Data
*! Ben A. Dwamena, University of Michigan

program define midas_ipd2ad
version 16.0

syntax varlist(min=2 max=2 numeric) [if] [in], ///
    BY(varname) ///
    [SAVing(string) REPLACE ///
     STUDYlabel(varname) ///
     DESIGNvar(varname) ///
     KEEPvars(varlist) ///
     NOIsily ]

*----------------------------------------------------------
* Parse and validate
*----------------------------------------------------------
marksample touse

* Get test and reference standard variables
tokenize `varlist'
local testvar `1'
local refvar `2'

* Validate binary variables
quietly {
    count if `touse'
    if r(N) == 0 {
        di as error "no observations"
        exit 2000
    }

    * Check test variable is binary
    count if `touse' & !inlist(`testvar', 0, 1, .)
    if r(N) > 0 {
        di as error "test variable `testvar' must be coded as 0/1"
        exit 198
    }

    * Check reference standard is binary
    count if `touse' & !inlist(`refvar', 0, 1, .)
    if r(N) > 0 {
        di as error "reference standard variable `refvar' must be coded as 0/1"
        exit 198
    }

    * Check missing data
    count if `touse' & (missing(`testvar') | missing(`refvar'))
    if r(N) > 0 {
        local nmiss = r(N)
        di as text "Note: `nmiss' observations with missing test or reference standard will be excluded"
        replace `touse' = 0 if missing(`testvar') | missing(`refvar')
    }
}

* Check by variable
capture confirm variable `by'
if _rc {
    di as error "by variable `by' not found"
    exit 198
}

* Validate saving option
if "`saving'" != "" {
    if "`replace'" == "" {
        capture confirm file "`saving'.dta"
        if !_rc {
            di as error "file `saving'.dta already exists; specify replace option"
            exit 602
        }
    }
}

*----------------------------------------------------------
* Create aggregate 2x2 tables by study
*----------------------------------------------------------

if "`noisily'" != "" {
    di as text _n "Converting individual patient data to aggregate format..."
    di as text "{hline 60}"
}

* Preserve original data
preserve

* Keep only necessary observations and variables
quietly keep if `touse'

* Create temporary variables for calculations
tempvar diseased healthy test_pos test_neg

quietly {
    * Identify disease status
    gen byte `diseased' = (`refvar' == 1)
    gen byte `healthy' = (`refvar' == 0)

    * Identify test results
    gen byte `test_pos' = (`testvar' == 1)
    gen byte `test_neg' = (`testvar' == 0)
}

* Calculate 2x2 table elements by study
tempfile aggregate_data

quietly {
    * Create 2x2 cell indicators
    gen byte tp_raw = (`diseased' == 1) & (`test_pos' == 1)
    gen byte fn_raw = (`diseased' == 1) & (`test_neg' == 1)
    gen byte fp_raw = (`healthy'  == 1) & (`test_pos' == 1)
    gen byte tn_raw = (`healthy'  == 1) & (`test_neg' == 1)

    * Collapse to study level
    collapse ///
        (sum) tp = tp_raw ///
        (sum) fn = fn_raw ///
        (sum) fp = fp_raw ///
        (sum) tn = tn_raw ///
        (count) n_total = `testvar' ///
        , by(`by' `studylabel' `designvar' `keepvars')

    * Some cells may be missing (system missing) if no observations in that cell
    * Replace with 0
    foreach var in tp fp fn tn {
        replace `var' = 0 if missing(`var')
    }

    * Calculate study-level measures
    gen sensitivity = tp / (tp + fn)
    gen specificity = tn / (fp + tn)
    gen n_diseased = tp + fn
    gen n_healthy = fp + tn

    * Label variables
    label variable tp "True Positives"
    label variable fp "False Positives"
    label variable fn "False Negatives"
    label variable tn "True Negatives"
    label variable sensitivity "Sensitivity"
    label variable specificity "Specificity"
    label variable n_diseased "Number with disease"
    label variable n_healthy "Number without disease"
    label variable n_total "Total number of patients"
}

*----------------------------------------------------------
* Generate study identifier if needed
*----------------------------------------------------------
if "`studylabel'" == "" {
    quietly {
        * Create numeric study ID only if not already present
        capture confirm variable studyid
        if _rc {
            gen long studyid = _n
            label variable studyid "Study ID"
        }
        capture order studyid
    }
}
else {
    order `studylabel'
}

*----------------------------------------------------------
* Display results
*----------------------------------------------------------
if "`noisily'" != "" | "`saving'" == "" {
    di as text _n "{hline 60}"
    di as text "Aggregate Data Summary"
    di as text "{hline 60}"

    quietly count
    local nstudies = r(N)
    di as text "Number of studies: " as result `nstudies'

    quietly summarize n_total
    di as text "Total patients: " as result r(sum)

    quietly summarize n_diseased
    di as text "Patients with disease: " as result r(sum)

    quietly summarize n_healthy 
    di as text "Patients without disease: " as result r(sum)

    di as text _n "Study-level summary statistics:"
    di as text "{hline 60}"
    summarize sensitivity specificity, format

    di as text _n "First few studies:"
    di as text "{hline 60}"
    list in 1/5, abbreviate(15) noobs
}

*----------------------------------------------------------
* Check for potential data issues
*----------------------------------------------------------
quietly {
    * Zero cells
    count if tp == 0 | fp == 0 | fn == 0 | tn == 0
    if r(N) > 0 {
        local nzero = r(N)
        di as text _n "Warning: " as result `nzero' as text " studies have zero cells"
        di as text "  Consider applying continuity correction"
    }

    * Perfect sensitivity or specificity
    count if sensitivity == 1 | specificity == 1
    if r(N) > 0 {
        local nperf = r(N)
        di as text _n "Note: " as result `nperf' as text " studies have perfect sensitivity or specificity"
    }

    * Small studies
    count if n_total < 30
    if r(N) > 0 {
        local nsmall = r(N)
        di as text _n "Note: " as result `nsmall' as text " studies have fewer than 30 patients"
    }
}

*----------------------------------------------------------
* Save if requested
*----------------------------------------------------------
if "`saving'" != "" {
    quietly save "`saving'", `replace'
    di as text _n "Aggregate data saved to: " as result "`saving'.dta"
}

* Restore or keep
if "`saving'" == "" {
    restore, not
    di as text _n "Aggregate data kept in memory (original data discarded)"
}
else {
    restore
    di as text _n "Original data restored in memory"
}

end

exit

# /*

# HELP FILE DOCUMENTATION

## Title

midas_ipd2ad - Convert Individual Patient Data to Aggregate Diagnostic Data

## Syntax

midas ipd2ad testvar refvar [if] [in], by(studyvar) [options]

## Description

midas_ipd2ad converts individual patient-level diagnostic test accuracy data
to aggregate study-level format (2x2 tables). This is useful when you have
individual patient data from multiple studies and need to create aggregate
data for meta-analysis.

The command calculates true positives (TP), false positives (FP), false
negatives (FN), and true negatives (TN) for each study, along with derived
measures like sensitivity and specificity.

## Required Arguments

testvar      Binary variable indicating test result (0=negative, 1=positive)
refvar       Binary variable indicating reference standard (0=no disease, 1=disease)
by(studyvar) Variable identifying individual studies

## Options

saving(filename)      Save aggregate data to specified file
replace              Overwrite existing file
studylabel(varname)  Variable with study labels/names to keep
designvar(varname)   Variable indicating study design (cohort/case-control)
keepvars(varlist)    Additional variables to keep in aggregate dataset
noisily              Display detailed output

## Examples

. * Basic conversion
. use ipd_data, clear
. midas ipd2ad test_result disease_status, by(studyid)

. * With saving
. midas ipd2ad test_result disease_status, by(studyid) ///
saving(aggregate_data, replace)

. * Keep study information
. midas ipd2ad test_result disease_status, by(studyid) ///
studylabel(author) designvar(studytype) ///
keepvars(year country)

. * After conversion, run meta-analysis
. midas mle tp fp fn tn, case(studytype)

## Stored Results

The command creates a dataset with the following variables:

studyid (or studylabel)  - Study identifier
tp                       - True positives
fp                       - False positives
fn                       - False negatives
tn                       - True negatives
sensitivity              - Sensitivity (TP / (TP+FN))
specificity              - Specificity (TN / (FP+TN))
n_diseased              - Number with disease (TP+FN)
n_healthy               - Number without disease (FP+TN)
n_total                 - Total patients in study
[keepvars]              - Any additional variables specified

## Remarks

Data Requirements:

- Test and reference standard variables must be coded as 0/1
- Missing values are automatically excluded
- Each study must have at least one patient

Data Quality Checks:

- The command checks for zero cells (may cause meta-analysis issues)
- Identifies studies with perfect sensitivity/specificity
- Flags small studies (<30 patients)

Typical Workflow:

1. Load individual patient data
1. Run midas ipd2ad to create aggregate data
1. Check aggregate data for issues
1. Apply continuity correction if needed
1. Run meta-analysis with midas mle or midas inla

## Author

Ben A. Dwamena
University of Michigan
bdwamena@umich.edu

## Also See

# midas_con2bin  - Convert continuous test results to binary
midas_ord2bin  - Convert ordinal test results to binary
midas_bclust   - Convert clustered data to binary
midas_mle      - Maximum likelihood meta-analysis

*/