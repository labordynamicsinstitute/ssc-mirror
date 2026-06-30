*-------------------------------------------------------------------------
* xtmunitroot_example.do
* Self-test + worked examples for xtmunitroot
* Karavias, Tzavalis & Zhang (2022, Econometrics)
* Author: Merwan Roudane
*-------------------------------------------------------------------------
clear all
set more off
set seed 12345

*-------------------------------------------------------------------------
* 0. Helper program: simulate an N x T panel with AR(1) errors and gaps
*    rho = 1 -> unit root (size) ; rho < 1 -> stationary (power)
*-------------------------------------------------------------------------
capture program drop _simpanel
program define _simpanel
    syntax , N(integer) T(integer) RHO(real) [MISS(real 0.10) det(string)]
    if ("`det'"=="") local det "none"
    clear
    local NT = `N'*(`T'+1)
    set obs `NT'
    egen id = seq(), from(1) to(`N') block(`=`T'+1')
    bysort id: gen t = _n - 1            // t = 0..T
    xtset id t
    * AR(1) errors, recursive (uses already-updated previous row)
    gen double u = rnormal() if t==0
    bysort id (t): replace u = `rho'*u[_n-1] + rnormal() if t>0
    * deterministics
    gen double y = u
    if ("`det'"=="trend") {
        by id: replace y = y + rnormal()*0.5 + 0.2*t
    }
    if ("`det'"=="break") {
        by id: replace y = y + cond(t> `=int(`T'/2)', 3, 0)
    }
    * unit-specific intercept
    bysort id (t): replace y = y + 5*runiform() if t==0
    bysort id (t): replace y = y + y[1] if t>0 & "`det'"!="break"
    * punch random holes (never the first obs of a unit)
    gen double rr = runiform()
    replace y = . if rr < `miss' & t>0
    drop rr u
end

*-------------------------------------------------------------------------
* 1. Functional test: every code path, standalone forms
*-------------------------------------------------------------------------
di as txt _n "{hline 70}"
di as txt "  1. FUNCTIONAL TEST - all models and methods run"
di as txt "{hline 70}"

_simpanel , n(80) t(10) rho(0.5) miss(0.12) det(none)

xtmunitroot y                                  // intercept, zeroout (default)
xtmunitroot y, model(trend)
xtmunitroot y, model(break) break(0.5)
xtmunitroot y, model(breaktrend) break(0.5)
xtmunitroot y, method(previous)
xtmunitroot y, method(linear)
xtmunitroot y, method(all)
xtmunitroot y, model(break) break(0.5) method(all) graph

*-------------------------------------------------------------------------
* 2. Monte Carlo SIZE check  (rho = 1 -> rejection rate should be ~ nominal)
*-------------------------------------------------------------------------
di as txt _n "{hline 70}"
di as txt "  2. MONTE CARLO SIZE  (rho=1, nominal 5%, expect ~0.03-0.08)"
di as txt "{hline 70}"

local reps 200
foreach m in zeroout previous linear {
    local rej 0
    forvalues r = 1/`reps' {
        quietly _simpanel , n(100) t(8) rho(1) miss(0.10) det(none)
        quietly xtmunitroot y, method(`m')
        if (r(p) < 0.05) local ++rej
    }
    di as txt "  size, method=" as res %-10s "`m'" as txt ": " as res %5.3f `rej'/`reps'
}

*-------------------------------------------------------------------------
* 3. Monte Carlo POWER check  (rho = 0.5 -> rejection rate should be high)
*    Also confirms the paper's ranking: zeroout >= linear >= previous
*-------------------------------------------------------------------------
di as txt _n "{hline 70}"
di as txt "  3. MONTE CARLO POWER  (rho=0.5, expect high; zeroout strongest)"
di as txt "{hline 70}"

local reps 200
foreach m in zeroout previous linear {
    local rej 0
    forvalues r = 1/`reps' {
        quietly _simpanel , n(100) t(8) rho(0.5) miss(0.10) det(none)
        quietly xtmunitroot y, method(`m')
        if (r(p) < 0.05) local ++rej
    }
    di as txt "  power, method=" as res %-10s "`m'" as txt ": " as res %5.3f `rej'/`reps'
}

di as txt _n "{hline 70}"
di as txt "  Self-test complete."
di as txt "{hline 70}"
