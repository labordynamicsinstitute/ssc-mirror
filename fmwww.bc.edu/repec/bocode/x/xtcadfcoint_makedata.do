/*
================================================================================
   xtcadfcoint_makedata.do — Convert PSY raw data to Stata format
   
   Reads RHPI.txt and RDIPC.txt from the Banerjee & Carrion-i-Silvestre
   GAUSS distribution package and creates a balanced panel dataset.
   
   Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
   Date: 14 February 2026
================================================================================
*/

clear all
set more off

local basedir "banerjee2025_zip/Distribute/Empirical"

// ============================================================================
// Read RHPI (Real House Price Index)
// ============================================================================
di as text "Reading RHPI data..."

// The TXT file is tab-delimited, 45 rows (1975-2019) x 52 cols (year + 51 states)
// First row is a GAUSS comment with column headers

insheet using "`basedir'/RHPI.txt", tab clear

// Rename columns — the GAUSS file has state abbreviations as headers
// Row 1 is years, cols 2-52 are 51 states
// The file uses GAUSS format so we read all as numeric

// Since the file format has GAUSS comments, let's handle it differently
clear
import delimited "`basedir'/RHPI.txt", delimiter(tab) clear

// The first row has @headers@ so it's read as string
// Drop it and destring
drop in 1

// Generate year variable
gen int year = 1974 + _n

// Reshape: each v variable is a state
local states "AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN KS KY LA MA MD ME MI MN MO MS MT NC ND NE NH NJ NM NV NY OH OK OR PA RI SC SD TN TX UT VA VT WA WI WV WY"

local i = 1
foreach s of local states {
    local vname = "v`i'"
    capture destring `vname', replace force
    capture rename `vname' rhpi_`s'
    local i = `i' + 1
}

// Drop the year column that was v1 which had @Year...@ header
drop if year == .

// Save wide format temporarily
tempfile rhpi_wide
save `rhpi_wide'

// ============================================================================
// Read RDIPC (Real Disposable Income per capita)
// ============================================================================
di as text "Reading RDIPC data..."

clear
import delimited "`basedir'/RDIPC.txt", delimiter(tab) clear

drop in 1

gen int year = 1974 + _n

local i = 1
foreach s of local states {
    local vname = "v`i'"
    capture destring `vname', replace force
    capture rename `vname' rdipc_`s'
    local i = `i' + 1
}

drop if year == .

tempfile rdipc_wide
save `rdipc_wide'

// ============================================================================
// Merge and reshape to long format
// ============================================================================
di as text "Merging and reshaping..."

use `rhpi_wide', clear
merge 1:1 year using `rdipc_wide', nogen

// Reshape to long
reshape long rhpi_ rdipc_, i(year) j(state) string

rename rhpi_ rhpi
rename rdipc_ rdipc

// Create numeric state ID
encode state, gen(state_id)

// Create log variables (matching GAUSS: y=ln(RHPI), x=ln(RDIpc))
gen double ln_rhpi  = ln(rhpi)
gen double ln_rdipc = ln(rdipc)

// Labels
label variable year     "Year"
label variable state    "US State"
label variable state_id "State numeric ID"
label variable rhpi     "Real House Price Index"
label variable rdipc    "Real Disposable Income per capita"
label variable ln_rhpi  "Log Real House Price Index"
label variable ln_rdipc "Log Real Disposable Income per capita"

// Set panel
xtset state_id year

// Sort and save
sort state_id year
save "psy_rhpi_rdipc.dta", replace

di as text ""
di as text "  Dataset saved: psy_rhpi_rdipc.dta"
di as text "  Panel: state_id (N=51), year (T=45, 1975-2019)"
di as text "  Variables: ln_rhpi (dependent), ln_rdipc (independent)"
di as text ""

// Summary
xtdescribe
summarize ln_rhpi ln_rdipc
