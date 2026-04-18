*! version 2.10  15apr2026
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

* Validate saving option — handle replace inside saving()
if `"`saving'"' != "" {
    local saving_clean `"`saving'"'
    local has_replace = 0
    if strpos(lower(`"`saving'"'), "replace") > 0 {
        local saving_clean = subinstr(`"`saving'"', ", replace", "", .)
        local saving_clean = subinstr(`"`saving_clean'"', ",replace", "", .)
        local saving_clean = subinstr(`"`saving_clean'"', "replace", "", .)
        local saving_clean = strtrim(`"`saving_clean'"')
        local has_replace = 1
    }
    if "`replace'" != "" {
        local has_replace = 1
    }
    local saving `"`saving_clean'"'
    if !`has_replace' {
        capture confirm file `"`saving'"'
        if !_rc {
            di as error `"file `saving' already exists; specify replace option"'
            exit 602
        }
        if !strpos(`"`saving'"', ".dta") {
            capture confirm file `"`saving'.dta"'
            if !_rc {
                di as error `"file `saving'.dta already exists; specify replace option"'
                exit 602
            }
        }
    }
    if `has_replace' {
        local replace "replace"
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
if `"`saving'"' != "" {
    quietly save `"`saving'"', `replace'
    di as text _n "Aggregate data saved to: " as result `"`saving'"'
}

* Restore or keep
if `"`saving'"' == "" {
    restore, not
    di as text _n "Aggregate data kept in memory (original data discarded)"
}
else {
    restore
    di as text _n "Original data restored in memory"
}

end
