// Step 1: Add the ado, mata, and sthlp files to your personal path; see adopath
// Step 2: Modify your working path below (with saving.dta and democracy.dta in it)
global path "YourWorkPath"

// Step 3: Run the following scripts!

// Check the help file
help classifylasso

// Make a new dictionary to store results
cd "$path"
cap mkdir "results"
cd "$path/results"

// Create log file
cap log close demo
cap rm "$path/demo.log"
log using "$path/demo.log", name(demo)

******** Section 3.4 & 4.6 Implementation Example ********
***** (Replication of Su, Shi, and Phillips (2016)) ****** 
** Section 3.4: Estimation
use "$path/saving.dta", clear
xtset code year
classifylasso savings lagsavings cpi interest gdp, group(1/5) lambda(1.5485) tol(1e-4) dynamic 
estimates save ssp2016

** Section 4.6: Post-Estimation
estimates use ssp2016
classoselect, group(2) postselection
predict gid
predict yhat, xb
estimates replay, outreg2("ssp2016.xls")

** Figure 1: Visualization of the Implementation Example
set scheme sj
classogroup, export("selection1.eps")
classocoef cpi, export("coefcpi.eps")

// Stop logging
log close demo
