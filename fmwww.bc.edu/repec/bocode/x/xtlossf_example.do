*! xtlossf_example.do  1.0.0  18jul2026
*! Self-test / demonstration for xtlossf.
*! Simulates a panel of a positive series (population-like) with KNOWN injected
*! jumps, then exercises the nonnegative, lag, mixed-sign, signed and fit paths.
*! Run:  do xtlossf.ado    then    do xtlossf_example.do
*! Author: Dr Merwan Roudane

clear
set seed 20260718
version 14.0

* ---- panel of a positive series over two periods ----------------------
local N = 60
set obs `N'
gen int id = _n
* base level, spanning several orders of magnitude (coefficient of variation
* falls with level — the motivating feature of the loss function)
gen double B = exp(rnormal()*1.5 + 8)          // ~ e^8 .. wide range
* future = base * growth + noise
gen double F = B*(1 + rnormal()*0.03)
* inject 4 known outliers (large relative jumps in SMALL units especially)
gen byte trueout = 0
foreach o in 5 22 41 57 {
    replace F = B*1.8 in `o'
    replace trueout = 1 in `o'
}

di as txt _n "TRUE outliers injected at id = 5 22 41 57"

* ======================================================================
* 1. Part I nonnegative, q=-1/2, default Tukey cutoff, with figures
* ======================================================================
di as txt _n(2) "{hline 70}" _n "1) xtlossf B F, q(-0.5) graph" _n "{hline 70}"
xtlossf B F, q(-0.5) graph
di as txt "detected flag in _xtlossf_out ; compare with trueout:"
list id trueout _xtlossf_out _xtlossf_L if _xtlossf_out==1

* ======================================================================
* 2. Signed loss (direction matters)
* ======================================================================
di as txt _n(2) "{hline 70}" _n "2) signed loss" _n "{hline 70}"
xtlossf B F, q(-0.5) signed

* ======================================================================
* 3. Lag mode (chronological time) on a stacked long panel
* ======================================================================
di as txt _n(2) "{hline 70}" _n "3) lag mode on a long panel" _n "{hline 70}"
clear
set obs 200
gen int id = ceil(_n/10)
bysort id: gen int year = 2010 + _n
xtset id year
gen double sales = exp(rnormal()*0.5 + 6)
bysort id (year): replace sales = sales[_n-1]*(1+rnormal()*0.05) if _n>1
* a couple of jumps
replace sales = sales*2 in 45
replace sales = sales*2 in 130
xtlossf sales, lag q(-0.5) tukey(3)

* ======================================================================
* 4. Mixed-sign data (Part II)
* ======================================================================
di as txt _n(2) "{hline 70}" _n "4) mixed-sign (Part II)" _n "{hline 70}"
clear
set obs 80
gen int id = _n
gen double actual   = rnormal()*5
gen double forecast = actual + rnormal()
replace forecast = actual + 15 in 10
replace forecast = actual - 15 in 60
xtlossf forecast actual, mixedsign signed q(-0.5)

* ======================================================================
* 5. Fit mode: recover q and C from the paper's Table I.1 midpoints
* ======================================================================
di as txt _n(2) "{hline 70}" _n "5) fit mode (Eq. I.19-I.20) — paper Table I.1" _n "{hline 70}"
clear
input double Bmid double epsmid
37500 5625
17500 7000
7500  4500
3750  3750
1250  2625
750   2250
250   1000
end
* (row for eps/B=.40 dropped by the paper for monotonicity)
drop if Bmid==17500
xtlossf Bmid epsmid, fit
di as txt "paper reports  q ~ 0.327 ,  C ~ 222.6"

di as txt _n(2) "{hline 70}" _n "REFEREE CHECKLIST" _n "{hline 70}"
di as txt "[ ] run 1: injected ids (5 22 41 57) flagged in _xtlossf_out"
di as txt "[ ] run 1: two-panel criticality + loss figure drawn"
di as txt "[ ] run 3: lag mode flags the two doubled sales obs"
di as txt "[ ] run 4: both mixed-sign shocks (obs 10, 60) flagged"
di as txt "[ ] run 5: fit recovers q ~ 0.327 and C ~ 223"
