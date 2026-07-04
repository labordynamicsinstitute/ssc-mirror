* ==========================================================================
* xtfmg_example.do -- self-test for the xtfmg package
* Simulates the Monte Carlo DGP of Guliyev (2026): heterogeneous slopes,
* a common factor driving both regressor and error (rho = 0.6, the
* "moderate dependence" regime), and a sharp level break at a different,
* uniformly drawn date in every unit.
* Exercises EVERY subcommand and every plot, then runs sanity assertions.
* Author: Merwan Roudane (merwanroudane920@gmail.com)
* ==========================================================================
clear all
set more off
set seed 20260703

* ---------------- DGP: y_it = a_i + b_i x_it + d_i D_it + rho g_i f_t + e_it
local N   = 10
local T   = 100
local rho = 0.6

set obs `=`N'*`T''
gen long id = ceil(_n/`T')
bysort id: gen int t = _n

* common factor f_t, shared by all units in period t
bysort t (id): gen double f = rnormal() if _n == 1
bysort t (id): replace f = f[1]

* unit-specific parameters (constant within unit)
bysort id (t): gen double bi  = rnormal(1, 0.30) if _n == 1
bysort id (t): replace bi = bi[1]
bysort id (t): gen double gi  = rnormal(1, 0.50) if _n == 1
bysort id (t): replace gi = gi[1]
bysort id (t): gen double di_ = rnormal(0, 2)    if _n == 1
bysort id (t): replace di_ = di_[1]
bysort id (t): gen double tau = floor(0.25*`T' + runiform()*0.50*`T') if _n == 1
bysort id (t): replace tau = tau[1]

* regressor correlated with the factor; idiosyncratic break; error
gen double x   = `rho'*f + rnormal()
gen byte   D   = (t > tau)
gen double y   = 0.5 + bi*x + di_*D + `rho'*gi*f + rnormal()

xtset id t

* ---------------- 1. regime map ------------------------------------------
xtfmg map y x
assert "`r(recommend)'" != ""
assert r(cd) < .

* ---------------- 2. per-unit break dates (should be dispersed) ----------
xtfmg breaks y x, plot
matrix BRK = r(breaks)
assert rowsof(BRK) == `N'

* ---------------- 3. each estimator --------------------------------------
xtfmg fe y x
xtfmg mg y x
xtfmg ccemg y x, heteroplot
xtfmg surmg y x
xtfmg fsurmg y x, fourierplot
xtfmg fccemg y x, heteroplot fourierplot

* the F-CCEMG point estimate should be close to the true mean slope of 1
qui xtfmg fccemg y x, notable
matrix bchk = r(b)
di as txt "F-CCEMG estimate of the mean slope (true value 1): " ///
    as res %8.4f el(bchk,1,1)
assert abs(el(bchk,1,1) - 1) < 0.35

* stored results present
assert r(N) == `N'
assert r(cd) < .
matrix buchk = r(bunit)
assert rowsof(buchk) == `N'
assert colsof(buchk) == 3    // slope + sin + cos

* ---------------- 4. full comparison table + coefficient plot ------------
xtfmg all y x, coefplot
matrix BB = r(B)
assert colsof(BB) == 6
assert rowsof(BB) == 3       // x + sin + cos
* CCE-based estimators should be closer to 1 than the factor-ignoring ones
di as txt "MG bias:      " as res %8.4f abs(el(BB,1,2) - 1)
di as txt "F-CCEMG bias: " as res %8.4f abs(el(BB,1,6) - 1)

* ---------------- 4b. journal-format table export -------------------------
xtfmg all y x, notable saving("xtfmg_tab8.tex") replace
confirm file "xtfmg_tab8.tex"
xtfmg all y x, notable saving("xtfmg_tab8.rtf") replace
confirm file "xtfmg_tab8.rtf"
qui xtfmg fccemg y x, notable saving("xtfmg_fccemg.csv") replace
confirm file "xtfmg_fccemg.csv"
qui xtfmg breaks y x, saving("xtfmg_tab7.tex") replace
confirm file "xtfmg_tab7.tex"
qui xtfmg breaks y x, saving("xtfmg_tab7.rtf") replace
confirm file "xtfmg_tab7.rtf"
* refusing to overwrite without replace
capture xtfmg all y x, notable saving("xtfmg_tab8.tex")
assert _rc == 602
* bad extension rejected
capture xtfmg all y x, notable saving("xtfmg_tab8.pdf") replace
assert _rc == 198
erase "xtfmg_tab8.tex"
erase "xtfmg_tab8.rtf"
erase "xtfmg_fccemg.csv"
erase "xtfmg_tab7.tex"
erase "xtfmg_tab7.rtf"

* ---------------- 5. SUR estimators must reject unbalanced panels --------
preserve
qui drop if id == 1 & t <= 10
qui xtset id t
capture noisily xtfmg surmg y x
assert _rc == 459
capture noisily xtfmg fsurmg y x
assert _rc == 459
* but fccemg must still run on the unbalanced panel
qui xtfmg fccemg y x, notable
assert r(N) == `N'
restore
qui xtset id t

* ---------------- 6. error handling --------------------------------------
capture xtfmg
assert _rc == 198
capture xtfmg nosuchsub y x
assert _rc == 198
capture xtfmg fccemg y x, kfreq(0)
assert _rc == 198

* ==========================================================================
di as res _n "xtfmg self-test: ALL TESTS PASSED"
* ==========================================================================

* --------------------------------------------------------------------------
* Optional: small Monte Carlo replicating the ranking of Guliyev (2026),
* Table 3 (rho = 0.6). Uncomment to run (about a minute).
* --------------------------------------------------------------------------
* local R = 50
* matrix MCE = J(`R', 2, .)    // columns: MG error, F-CCEMG error
* forvalues r = 1/`R' {
*     qui {
*         clear
*         set obs `=10*100'
*         gen long id = ceil(_n/100)
*         bysort id: gen int t = _n
*         bysort t (id): gen double f = rnormal() if _n == 1
*         bysort t (id): replace f = f[1]
*         bysort id (t): gen double bi = rnormal(1, .3) if _n == 1
*         bysort id (t): replace bi = bi[1]
*         bysort id (t): gen double gi = rnormal(1, .5) if _n == 1
*         bysort id (t): replace gi = gi[1]
*         bysort id (t): gen double di_ = rnormal(0, 2) if _n == 1
*         bysort id (t): replace di_ = di_[1]
*         bysort id (t): gen double tau = floor(25 + runiform()*50) if _n == 1
*         bysort id (t): replace tau = tau[1]
*         gen double x = .6*f + rnormal()
*         gen double y = .5 + bi*x + di_*(t > tau) + .6*gi*f + rnormal()
*         xtset id t
*         xtfmg mg y x, notable
*         matrix tmp = r(b)
*         matrix MCE[`r', 1] = el(tmp,1,1) - 1
*         xtfmg fccemg y x, notable
*         matrix tmp = r(b)
*         matrix MCE[`r', 2] = el(tmp,1,1) - 1
*     }
* }
* clear
* qui svmat double MCE, name(err)
* gen double sq1 = err1^2
* gen double sq2 = err2^2
* qui su sq1, meanonly
* local rmse_mg = 100*sqrt(r(mean))
* qui su sq2, meanonly
* local rmse_fccemg = 100*sqrt(r(mean))
* di as txt "RMSE x 100  --  MG: " as res %6.2f `rmse_mg' ///
*     as txt "   F-CCEMG: " as res %6.2f `rmse_fccemg'
* di as txt "(paper Table 3, N=10 T=100 rho=0.6: MG 28.10, F-CCEMG 7.78)"
