*! xtbreakmodel_example.do
*! Replicates Okui & Wang (2021) DGP.1 and demonstrates all methods
*! Author: Dr Merwan Roudane
*! Version 1.0.0

clear all
set more off
set seed 12345

* Add path so Stata can find xtbreakmodel files
adopath + "C:\Users\HP\Desktop\qardl stata"

// ====================================================================
// DGP.1 from Okui & Wang (2021, Journal of Econometrics)
// N=100, T=20, G=3, sigma=0.5
// Group 1: beta = (1, 2, 3) with breaks at T/2 and 5T/6
// Group 2: beta = (3, 4, 5) with breaks at T/3 and 5T/6
// Group 3: beta = 1.5 (no breaks)
// ====================================================================

local N = 100
local T = 20
local sigma = 0.5
local N1 = round(`N'/3)
local N2 = round(`N'/3)
local N3 = `N' - `N1' - `N2'

// Break points
local bp1_1 = round(`T'/2)
local bp1_2 = round(`T'/2) + round(`T'/3)
local bp2_1 = round(`T'/3)
local bp2_2 = round(`T'/2) + round(`T'/3)

set obs `=`N'*`T''
gen id = ceil(_n/`T')
bysort id: gen time = _n
xtset id time

// Generate regressor and error
gen x = rnormal()
gen e = `sigma' * rnormal()

// Assign groups
gen group0 = cond(id <= `N1', 1, cond(id <= `N1' + `N2', 2, 3))

// Generate true beta based on group and time
gen beta_true = .
// Group 1: breaks at bp1_1 and bp1_2
replace beta_true = 1 if group0 == 1 & time < `bp1_1'
replace beta_true = 2 if group0 == 1 & time >= `bp1_1' & time < `bp1_2'
replace beta_true = 3 if group0 == 1 & time >= `bp1_2'
// Group 2: breaks at bp2_1 and bp2_2
replace beta_true = 3 if group0 == 2 & time < `bp2_1'
replace beta_true = 4 if group0 == 2 & time >= `bp2_1' & time < `bp2_2'
replace beta_true = 5 if group0 == 2 & time >= `bp2_2'
// Group 3: no breaks
replace beta_true = 1.5 if group0 == 3

// Generate dependent variable
gen y = x * beta_true + e

di _n(2) "{hline 78}"
di "{bf:                    xtbreakmodel — Full Demonstration}"
di "{hline 78}"
di "{bf:DGP.1 from Okui & Wang (2021, Journal of Econometrics)}"
di "N = `N', T = `T', G = 3, sigma = `sigma'"
di "Group 1 (N1=`N1'): beta = (1, 2, 3), breaks at t=`bp1_1', t=`bp1_2'"
di "Group 2 (N2=`N2'): beta = (3, 4, 5), breaks at t=`bp2_1', t=`bp2_2'"
di "Group 3 (N3=`N3'): beta = 1.5, no breaks"
di "{hline 78}"

// ====================================================================
// METHOD 1: PLS / AGFL (Qian & Su, 2016) — Common breaks
// ====================================================================
di _n(3)
di "{bf:=== METHOD 1: PLS / AGFL (Qian & Su, 2016) — Common Breaks ===}"
di

xtbreakmodel y x, method(pls)

// ====================================================================
// METHOD 2: GAGFL (Okui & Wang, 2021) — Heterogeneous breaks
// ====================================================================
di _n(3)
di "{bf:=== METHOD 2: GAGFL (Okui & Wang, 2021) — Heterogeneous Breaks ===}"
di

xtbreakmodel y x, method(gagfl) groups(3)

// ====================================================================
// METHOD 3: BFK (Baltagi, Feng & Kao, 2016)
// ====================================================================
di _n(3)
di "{bf:=== METHOD 3: BFK (Baltagi, Feng & Kao, 2016) ===}"
di

xtbreakmodel y x, method(bfk)

// ====================================================================
// METHOD 4: SaRa (Li, Xiao & Chen, 2025)
// ====================================================================
di _n(3)
di "{bf:=== METHOD 4: SaRa (Li, Xiao & Chen, 2025) ===}"
di

xtbreakmodel y x, method(sara) bandwidths(3 5 8) c1(0.1)

// ====================================================================
// SUMMARY
// ====================================================================
di _n(3)
di "{hline 78}"
di "{bf:Summary of Results}"
di "{hline 78}"
di
di "All four methods have been estimated with visualizations."
di "The GAGFL method provides the most complete analysis by"
di "simultaneously detecting groups and group-specific breaks."
di "{hline 78}"
