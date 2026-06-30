*-------------------------------------------------------------------------
* xtgunitroot_example.do
* Worked examples + self-test for xtgunitroot
* Karavias & Tzavalis (2019, Scandinavian Journal of Statistics)
* Author: Merwan Roudane
*-------------------------------------------------------------------------
clear all
set more off
set seed 12345

* Simulate a balanced panel with MA(1) errors (serial correlation)
* h = 0 : unit root ; h = 1 : stationary
capture program drop _gsim
program define _gsim
    args N T h theta
    clear
    set obs `=`N'*(`T'+1)'
    egen id = seq(), from(1) to(`N') block(`=`T'+1')
    bysort id: gen t = _n - 1
    xtset id t
    tempvar e u fe
    bysort id (t): gen double `e' = rnormal()
    bysort id (t): gen double `u' = `e' if _n==1
    bysort id (t): replace `u' = `e' + `theta'*`e'[_n-1] if _n>1   // MA(1)
    bysort id (t): gen double `fe' = 5*runiform() if _n==1
    bysort id (t): replace `fe' = `fe'[1]
    if (`h'==0) bysort id (t): gen double y = sum(`u') + `fe'      // I(1)
    else        bysort id (t): gen double y = `u' + `fe'          // stationary
    keep id t y
    xtset id t
end

*-------------------------------------------------------------------------
* 1. Functional examples
*-------------------------------------------------------------------------
_gsim 100 14 0 0.4
xtgunitroot y                                    // intercept, no serial-corr correction
xtgunitroot y, maxlag(1)                         // robust to MA(1)
xtgunitroot y, model(break) break(0.5) maxlag(1) // known break
xtgunitroot y, model(break) break(unknown) maxlag(1) breps(199) seed(7)

*-------------------------------------------------------------------------
* 2. Monte Carlo size (H0 unit root, MA(1)) -- maxlag(1) should be ~5%
*-------------------------------------------------------------------------
di as txt _n "{hline 60}"
di as txt "  SIZE (rho=1, MA(1) theta=0.4), nominal 5%"
di as txt "{hline 60}"
local reps 300
foreach pm in 0 1 {
    local rej 0
    forvalues r = 1/`reps' {
        set seed `=2000+`r''
        quietly _gsim 150 14 0 0.4
        quietly xtgunitroot y, model(intercept) maxlag(`pm')
        if (r(p) < 0.05) local ++rej
    }
    di as txt "  intercept maxlag(`pm') : size = " as res %5.3f `rej'/`reps'
}

*-------------------------------------------------------------------------
* 3. Monte Carlo power (stationary MA(1))
*-------------------------------------------------------------------------
di as txt _n "{hline 60}"
di as txt "  POWER (stationary, MA(1)), maxlag(1)"
di as txt "{hline 60}"
local pw 0
forvalues r = 1/`reps' {
    set seed `=3000+`r''
    quietly _gsim 150 14 1 0.4
    quietly xtgunitroot y, model(intercept) maxlag(1)
    if (r(p) < 0.05) local ++pw
}
di as txt "  power = " as res %5.3f `pw'/`reps'
di as txt _n "Self-test complete."
