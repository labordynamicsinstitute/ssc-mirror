*! xtrobust_example.do  1.0.0  18jul2026
*! Self-test / demonstration for xtrobust.
*! Part A: single-dataset FE and RE robust fits with figures.
*! Part B: Monte Carlo reproducing the source paper's DGP (Jaseem & Mohammad
*!         2024, Tables 1-2): compare OLS / S / WLE by MSE across sample size
*!         and contamination.  Scaled down for speed; bump the locals to the
*!         paper's n in {200,800}, reps=1000 for the full replication.
*! Run:  do xtrobust.ado    then    do xtrobust_example.do
*! Author: Dr Merwan Roudane

clear
set seed 20260718
version 14.0

* ======================================================================
* PART A — one dataset, FE and RE, with figures
* ======================================================================
local N = 50
local T = 8
set obs `=`N'*`T''
gen int id = ceil(_n/`T')
bysort id: gen int t = _n
xtset id t
by id: gen double a = rnormal()*2 if _n==1
by id: replace a = a[1]
gen double x1 = 0.5*a + rnormal()
gen double x2 = rnormal()
gen double x3 = rnormal()
gen double y  = a + 1.0*x1 - 0.5*x2 + 0.75*x3 + rnormal()
* 15% contamination
gen double u = runiform()
replace y = y + rnormal()*10 if u < 0.15

di as txt _n "TRUE slopes: b1=1.0 b2=-0.5 b3=0.75  (15% contamination)"

di as txt _n(2) "{hline 70}" _n "A1) FE robust (OLS vs S vs WLE) + figures" _n "{hline 70}"
xtrobust y x1 x2 x3, fe method(all) nsamp(200) seed(321) graph

di as txt _n(2) "{hline 70}" _n "A2) RE robust" _n "{hline 70}"
xtrobust y x1 x2 x3, re seed(321)

* ======================================================================
* PART B — Monte Carlo MSE table (paper Tables 1-2 structure)
* ======================================================================
di as txt _n(2) "{hline 70}" _n "B) Monte Carlo MSE (OLS/S/WLE) — scaled down" _n "{hline 70}"

* true slopes
scalar tb1 = 1.0
scalar tb2 = -0.5
scalar tb3 = 0.75

local reps = 50            // paper uses 1000
foreach model in fe re {
  foreach nn in 50 100 {   // paper uses 200, 800
    foreach cont in 0.10 0.20 {
        scalar mseO = 0
        scalar mseS = 0
        scalar mseW = 0
        forvalues r = 1/`reps' {
            quietly {
                clear
                set obs `=`nn'*8'
                gen int id = ceil(_n/8)
                bysort id: gen int t = _n
                xtset id t
                by id: gen double a = rnormal()*2 if _n==1
                by id: replace a = a[1]
                gen double x1 = 0.5*a + rnormal()
                gen double x2 = rnormal()
                gen double x3 = rnormal()
                gen double y  = a + tb1*x1 + tb2*x2 + tb3*x3 + rnormal()
                gen double uu = runiform()
                replace y = y + rnormal()*10 if uu < `cont'

                capture xtrobust y x1 x2 x3, `model' nsamp(50) seed(`=1000+`r'')
                if _rc==0 {
                    matrix bo = r(b_ols)
                    matrix bs = r(b_s)
                    matrix bw = r(b_wle)
                    scalar mseO = mseO + (bo[1,1]-tb1)^2 + (bo[1,2]-tb2)^2 + (bo[1,3]-tb3)^2
                    scalar mseS = mseS + (bs[1,1]-tb1)^2 + (bs[1,2]-tb2)^2 + (bs[1,3]-tb3)^2
                    scalar mseW = mseW + (bw[1,1]-tb1)^2 + (bw[1,2]-tb2)^2 + (bw[1,3]-tb3)^2
                }
            }
        }
        scalar mseO = mseO/`reps'
        scalar mseS = mseS/`reps'
        scalar mseW = mseW/`reps'
        di as txt "`model'  n=" %-4.0f `nn' "  cont=" %4.2f `cont' ///
            "   MSE:  OLS=" as res %8.5f mseO ///
            as txt "  S=" as res %8.5f mseS ///
            as txt "  WLE=" as res %8.5f mseW
    }
  }
}

di as txt _n(2) "{hline 70}" _n "REFEREE CHECKLIST" _n "{hline 70}"
di as txt "[ ] compiles clean"
di as txt "[ ] Part A: S and WLE slopes closer to truth than OLS under contamination"
di as txt "[ ] Part A: figure with S/WLE weights + resid-vs-fitted drawn"
di as txt "[ ] Part B: MSE(S) and MSE(WLE) < MSE(OLS) at every cell"
di as txt "[ ] Part B: robust advantage grows with contamination (as in the paper)"
