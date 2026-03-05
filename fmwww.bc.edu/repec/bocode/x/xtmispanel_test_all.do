* xtmispanel_test_all.do — Comprehensive test of xtmispanel v1.0.0
* Run: do "c:\Users\HP\Documents\xtpmg\xtmispanel\xtmispanel_test_all.do"

program drop _all
discard
adopath + "c:\Users\HP\Documents\xtpmg\xtmispanel"

clear all
set more off
set seed 12345

* Create simulated panel data
set obs 300
gen country = ceil(_n/30)
gen year = 1990 + mod(_n-1, 30)
gen double GDP = 5 + 0.5*country + 0.1*(year-1990) + rnormal(0,1)
gen double Investment = 2 + 0.3*country + 0.05*(year-1990) + 0.6*GDP + rnormal(0,0.8)
gen double Trade = 1 + 0.2*country + 0.08*(year-1990) + 0.4*GDP + rnormal(0,0.7)
xtset country year
replace GDP = . if runiform() < 0.10
replace Investment = . if runiform() < 0.15
replace Trade = . if inlist(country,3,7) & inrange(year,2005,2010)
replace Trade = . if runiform() < 0.08

* Show which file Stata is actually loading
which xtmispanel

* TEST 1: Detection (4 tables)
di _newline "{hline 50}"
di "{bf:TEST 1: DETECTION}"
di "{hline 50}"
xtmispanel GDP Investment Trade, detect

* TEST 2: Mechanism Tests
di _newline "{hline 50}"
di "{bf:TEST 2: MECHANISM TESTS}"
di "{hline 50}"
xtmispanel GDP Investment Trade, test

* TEST 3: All 13 Imputation Methods
di _newline "{hline 50}"
di "{bf:TEST 3: IMPUTATION (13 methods)}"
di "{hline 50}"
xtmispanel Trade, impute(mean)
drop Trade_imp
xtmispanel Trade, impute(median)
drop Trade_imp
xtmispanel Trade, impute(locf)
drop Trade_imp
xtmispanel Trade, impute(nocb)
drop Trade_imp
xtmispanel Trade, impute(linear)
drop Trade_imp
xtmispanel Trade, impute(spline)
drop Trade_imp
xtmispanel Trade, impute(regress)
drop Trade_imp
xtmispanel Trade, impute(pmm)
drop Trade_imp
xtmispanel Trade, impute(hotdeck)
drop Trade_imp
xtmispanel Trade, impute(knn)
drop Trade_imp
xtmispanel Trade, impute(rf)
drop Trade_imp
xtmispanel Trade, impute(em)
drop Trade_imp
xtmispanel Trade, impute(mice)
drop Trade_imp

* TEST 4: Sensitivity Analysis (13 methods comparison)
di _newline "{hline 50}"
di "{bf:TEST 4: SENSITIVITY ANALYSIS}"
di "{hline 50}"
xtmispanel Trade, sensitivity

* TEST 5: All 8 Graphs
di _newline "{hline 50}"
di "{bf:TEST 5: VISUALIZATIONS (8 graphs)}"
di "{hline 50}"
xtmispanel GDP Investment Trade, graph
graph display xtmis_combined
graph display xtmis_density

* TEST 6: Help File
di _newline "{hline 50}"
di "{bf:TEST 6: HELP FILE}"
di "{hline 50}"
help xtmispanel

di _newline(2) "{bf:ALL TESTS COMPLETED}"
