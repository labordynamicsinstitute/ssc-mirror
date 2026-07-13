*! hpcm_example.do  -- self-test / validation for the hpcm package
*! Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Validates hpcm against Hosoya (2001) using the paper's own examples as
*! known-truth DGPs:
*!   Example 2.4  -> Hsiao spurious causality is AVOIDED  : PM(y->x:z) ~ 0
*!   Example 2.2  -> genuine one-way effect y=>x          : PM(y->x:z) >> 0
*! plus a Monte-Carlo size (null) and power (causal) check of the Wald test.
*!
*! Run this file line-by-line or all at once in Stata (StataMP/SE/BE >= 14).
* -----------------------------------------------------------------------
clear all
set more off
* make hpcm findable without installing (adjust the path if you moved it)
adopath ++ "C:/Users/HP/Documents/xtpmg/hpcm"
discard

* =======================================================================
* 1. EXAMPLE 2.4  (Hsiao spurious causality; Theorem 4.4)
*    x=e+.5h ; y=xi ; z=h+.5 L.xi   (e,h,xi mutually orthogonal WN)
*    Naive conditioning finds y->x; Hosoya's partial measure must be ~0.
* =======================================================================
set seed 12345
qui set obs 6000
gen t = _n
tsset t
gen e  = rnormal()
gen h  = rnormal()
gen xi = rnormal()
gen y  = xi
gen z  = h + 0.5*L.xi
gen x  = e + 0.5*h

di _n as res "### Example 2.4 : expect PM(y->x:z) ~ 0 and PM(x->y:z) ~ 0 ###"
hpcm x y z, var(2) grid(256)

* =======================================================================
* 2. EXAMPLE 2.2  (genuine one-way effect y => x)
*    x=a L.y + e ; y=eta ; z=b L.y + xi + g L.xi
*    v(t)=eta causes u(t) one-sidedly  ->  PM(y->x:z) large, PM(x->y:z)~0.
* =======================================================================
clear
set seed 222
qui set obs 6000
gen t = _n
tsset t
gen e   = rnormal()
gen eta = rnormal()
gen xi  = rnormal()
local a = 0.8
local b = 0.5
local g = 0.4
gen y = eta
gen x = `a'*L.y + e
gen z = `b'*L.y + xi + `g'*L.xi

di _n as res "### Example 2.2 : expect PM(y->x:z) >> PM(x->y:z) (~0) ###"
hpcm x y z, var(3) grid(256)

di _n as txt "band-restricted (low-frequency, 0 to 0.4 rad) + plot:"
hpcm x y z, var(3) band(0 0.4) plot name(ex22) nodraw

* =======================================================================
* 3. Bootstrap CIs and the differencing reduction (Section 5)
* =======================================================================
di _n as res "### bootstrap CIs (parametric) ###"
hpcm x y z, var(3) breps(199) seed(777) grid(200)

di _n as res "### I(1) reduction: cumulate to unit roots, use difference(1) ###"
gen X = sum(x)
gen Y = sum(y)
gen Z = sum(z)
hpcm X Y Z, var(3) difference(1) grid(200)

* =======================================================================
* 4. MONTE CARLO : size (null) and power (causal) of the Wald test
*    NOTE: vary the seed every replication so the DGP is genuinely random.
* =======================================================================
di _n as res "### Monte Carlo : Wald size (null: no partial y->x) ###"
tempname MC
tempfile mcf
postfile `MC' double(pyx pxy) using "`mcf'", replace
local R = 100
forvalues r = 1/`R' {
    quietly {
        clear
        set seed `=1000+`r''
        set obs 800
        gen t = _n
        tsset t
        * NULL: x,y independent given z (Example 2.4 structure)
        gen e2  = rnormal()
        gen h2  = rnormal()
        gen x2  = rnormal()
        gen yv  = x2
        gen zv  = h2 + 0.5*L.x2
        gen xv  = e2 + 0.5*h2
        capture hpcm xv yv zv, var(2) grid(96)
        if _rc==0 post `MC' (r(p_yx)) (r(p_xy))
        else      post `MC' (.) (.)
    }
}
postclose `MC'
preserve
use "`mcf'", clear
gen rej_yx = pyx < .05 if pyx<.
gen rej_xy = pxy < .05 if pxy<.
qui summ rej_yx
di as txt "empirical size, H0: PM(y->x:z)=0  (nominal .05) = " as res %5.3f r(mean)
qui summ rej_xy
di as txt "empirical size, H0: PM(x->y:z)=0  (nominal .05) = " as res %5.3f r(mean)
restore

di _n as res "### Monte Carlo : Wald power (causal: y => x) ###"
tempname MP
tempfile mpf
postfile `MP' double(pyx) using "`mpf'", replace
forvalues r = 1/`R' {
    quietly {
        clear
        set seed `=5000+`r''
        set obs 800
        gen t = _n
        tsset t
        gen e2   = rnormal()
        gen eta2 = rnormal()
        gen xi2  = rnormal()
        gen yv = eta2
        gen xv = 0.8*L.yv + e2
        gen zv = 0.5*L.yv + xi2 + 0.4*L.xi2
        capture hpcm xv yv zv, var(3) grid(96)
        if _rc==0 post `MP' (r(p_yx))
        else      post `MP' (.)
    }
}
postclose `MP'
preserve
use "`mpf'", clear
gen rej = pyx < .05 if pyx<.
qui summ rej
di as txt "empirical power, H0: PM(y->x:z)=0  = " as res %5.3f r(mean)
restore

di _n as res "=== self-test complete ==="
