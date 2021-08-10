/***************************************************************************/
/* THIS PROGRAM READ DATASET ENTERED INTO STATA AND REPLACES STATEMENT */
/* NUMBERS WITH THEIR RANKINGS. */

*! version 1.0 15Mar2017
program define qconvert
version 12.0
syntax varlist(min=2 numeric) [if] [in], SAVe(string)

preserve

qui gen StatNo=_n

foreach var in `varlist' {
confirm variable `var' 
qui gen new`var'=StatNo
local N=_N
forvalues j=1/`N' {
local s=`var'[`j']
qui replace new`var'=ranking[`j'] if StatNo==`s' 
}
}
//
keep StatNo new*
ren new* qsort#, renumber
save `save'.dta, replace
restore
end
