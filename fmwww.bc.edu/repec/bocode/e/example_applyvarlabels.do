*! example_applyvarlabels.do -- worked examples for -applyvarlabels-
*! ----------------------------------------------------------------------------
*!  The situation (Statalist 1768839): you are handed a dataset with 100+
*!  variables, NONE of them labeled, and a separate spreadsheet that lists each
*!  variable name beside the label it should carry.  You want the labels on the
*!  data.  The obvious loop -- levelsof the labels, tokenize the variables,
*!  march down both at once -- puts the wrong label on the wrong variable,
*!  because levelsof returns the labels sorted ALPHABETICALLY (and drops the
*!  quotes off the first one).
*!
*!  applyvarlabels reads the crosswalk in row order, matches each label to its
*!  variable BY NAME, writes a capture-guarded relabel do-file, runs it, and
*!  prints an inventory of whatever did not line up.
*!
*!  Run from the package directory:   do example_applyvarlabels.do
*!  Requires: applyvarlabels.ado on the adopath, Stata 16+, and the shipped
*!            example_varlabels.xlsx alongside this do-file.
*! ----------------------------------------------------------------------------
version 16
clear all
set more off

local xlsx "example_varlabels.xlsx"
capture confirm file "`xlsx'"
if _rc {
    di as err "example_varlabels.xlsx not found -- run make_example_varlabels.py, or"
    di as err "cd into the package directory before running this do-file."
    exit 601
}

* ============================================================================
* 1. THE DATA -- unlabeled, exactly as handed to you
*    The "data" sheet's first row is the variable names; below it are values.
* ============================================================================
import excel using "`xlsx'", sheet("data") firstrow clear
describe
di as txt _n "None of these carry a meaningful label yet." _n

* ============================================================================
* 2. THE CROSSWALK -- one variable per row, a Variable column and a Label column
*    (this is the "var_labels" sheet of the same workbook)
* ============================================================================
preserve
import excel using "`xlsx'", sheet("var_labels") firstrow clear
list, sepby(Variable) noobs abbreviate(12)
restore

* ============================================================================
* 3. APPLY -- one line.  The data are in memory; point applyvarlabels at the
*    crosswalk sheet.  It reads the crosswalk without disturbing your data,
*    writes a capture-guarded relabel do-file, runs it, and reports.
* ============================================================================
applyvarlabels using "`xlsx'", sheet("var_labels")

* grab the returns NOW -- any later command (describe, di, ...) overwrites r():
local nap     = r(N_applied)
local nvar    = r(N_variables)
local nomatch `r(nomatch)'
local nolabel `r(nolabel)'
local dof     `r(dofile)'

* the labels are now on the variables:
describe

* what the inventory told us, also available in r() (captured above):
di as txt _n "applied to " as res `nap' as txt " of " as res `nvar' as txt " variables"
di as txt "crosswalk names with no such variable: " as res "`nomatch'"
di as txt "  (q7_other and income_2019 are in the spreadsheet but not the data)"
di as txt "variables with no crosswalk row: " as res "`nolabel'"
di as txt "  (notes was never listed in the spreadsheet -- still unlabeled)"
di as txt "the relabel do-file it wrote and ran: " as res "`dof'"

* ============================================================================
* 4. KEEP THE RELABEL DO-FILE -- name it, and it becomes a reusable, auditable
*    artifact you can commit next to your data-cleaning code and rerun anytime.
* ============================================================================
import excel using "`xlsx'", sheet("data") firstrow clear
applyvarlabels using "`xlsx'", sheet("var_labels") dofile("relabel_survey.do") replace
type "relabel_survey.do"

* ============================================================================
* 5. NAMES THAT DIFFER ONLY IN CASE -- add -nocase-.  The generated do-file
*    uses your data's actual spelling, so -capture- never misfires.
* ============================================================================
clear
input id AgeYears IncUSD
1 34 52000
end
preserve
clear
input str12 Variable str40 Label
"ageyears" "Age in years"
"incusd"   "Income in US dollars"
end
export excel using "case_crosswalk.xlsx", firstrow(variables) replace
restore
applyvarlabels using "case_crosswalk.xlsx", nocase
describe

* ============================================================================
* 6. DRY RUN -- -norun- writes the relabel do-file but applies nothing, so you
*    can inspect or edit it before it touches the data.
* ============================================================================
import excel using "`xlsx'", sheet("data") firstrow clear
applyvarlabels using "`xlsx'", sheet("var_labels") norun dofile("relabel_preview.do") replace
di as txt "labels NOT yet applied; preview written to r(dofile) = " as res "`r(dofile)'"

* ============================================================================
* Tidy up the demonstration files this walkthrough wrote into the current
* directory (in real use you would keep the relabel do-file you name).
* ============================================================================
foreach g in relabel_survey.do case_crosswalk.xlsx relabel_preview.do {
    capture erase "`g'"
}

di as res _n "example_applyvarlabels.do complete."
