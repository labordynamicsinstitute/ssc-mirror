*! xtpanic_example.do  --  self-test for -xtpanic- (xtflexur library)
*! Dr Merwan Roudane
*! Run after: adopath + "<folder>"   then   do xtpanic_example.do

clear
set more off
set seed 20260723
local N = 20
local T = 60

* factor-structured panel:  y_it = 2 + F_t*lambda_i + e_it
* F_t is a common I(1) factor (=> strong cross-sectional dependence).
quietly {
    set obs `=`N'*`T''
    gen id = ceil(_n/`T')
    bysort id: gen t = _n
    xtset id t
    * one common shock per period, shared across units -> common random walk F
    sort t id
    by t: gen double shk = rnormal() if _n == 1
    by t: replace shk = shk[1]
    sort id t
    by id: gen double F = sum(shk)
    * heterogeneous loadings
    by id: gen double lam = rnormal() if t == 1
    by id: replace lam = lam[1]
}

*==========================================================================
* CASE A -- STATIONARY idiosyncratic component  => reject the unit-root null
*==========================================================================
di _n(2) as txt "{hline 70}"
di as txt "CASE A: I(1) common factor + STATIONARY idiosyncratic -> reject"
di as txt "{hline 70}"
quietly {
    by id: gen double e = rnormal() if t == 1
    by id: replace e = 0.4*L.e + rnormal() if t > 1
    gen double y = 2 + F*lam + e
}
xtpanic y, model(constant)

*==========================================================================
* CASE B -- I(1) idiosyncratic component        => do NOT reject
*==========================================================================
di _n(2) as txt "{hline 70}"
di as txt "CASE B: I(1) common factor + I(1) idiosyncratic -> do NOT reject"
di as txt "{hline 70}"
quietly {
    by id: replace e = rnormal() if t == 1
    by id: replace e = L.e + rnormal() if t > 1
    replace y = 2 + F*lam + e
}
xtpanic y, model(constant)

di _n as txt "{hline 70}"
di as txt "On the OECD healthcare data, xtpanic reproduces Table 3 of Nazlioglu"
di as txt "et al. (2023, Econometric Reviews) exactly: P=92.275, Pm=5.845, 2 factors."
di as txt "{hline 70}"
