*! dnqr_example.do  version 1.0.0  27may2026
*! Demo script for the dnqr / nqar Stata package
*! Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>

clear all
set more off
set scheme s2color

* If the package is in a local folder, add it to the adopath:
* sysdir set PLUS "C:\Users\HP\Documents\xtpmg\dynqnr\dnqr_pkg"
* adopath ++ "C:\Users\HP\Documents\xtpmg\dynqnr\dnqr_pkg"

* ---------------------------------------------------------------------
* 1. Simulate a Dynamic Network Quantile Regression DGP
* ---------------------------------------------------------------------
dnqr_simulate,                                                   ///
        n(80) t(50)                                              ///
        wtype(powerlaw) wparam(2.5)                              ///
        gamma1(0.25) gamma2(0.20) gamma3(0.30)                   ///
        z(2) factors(2)                                          ///
        errordist(normal)                                        ///
        seed(20260527) clear wname(W)

describe
xtsum y

* ---------------------------------------------------------------------
* 2. Baseline: NQAR (lagged-network only)
* ---------------------------------------------------------------------
nqar y, network(W) rowstd                                        ///
        quantile(0.1 0.25 0.5 0.75 0.9)                          ///
        z(Z1 Z2) factors(F1 F2) bandwidth(HS) level(95)

dnqr_plot, name(g_nqar) saving(g_nqar.gph)

* ---------------------------------------------------------------------
* 3. Full DNQR with contemporaneous network endogeneity
* ---------------------------------------------------------------------
dnqr y, network(W) rowstd                                        ///
        quantile(0.1 0.25 0.5 0.75 0.9)                          ///
        z(Z1 Z2) factors(F1 F2)                                  ///
        ivtype(wy23) gridpoints(30) gridscale(4)

dnqr_plot WY WY_L1 Y_L1 Z1 Z2, ncols(3) name(g_dnqr) ///
        color(maroon) bcolor(orange%30) saving(g_dnqr.gph)

* ---------------------------------------------------------------------
* 4. Tail-event impulse response at tau = 0.9
* ---------------------------------------------------------------------
dnqr_impulse, network(W) rowstd horizon(12) quantile(0.9)        ///
        shocknode(1) shocksize(1) plot top(6)                    ///
        name(g_irf90) saving(g_irf90.gph)

* ---------------------------------------------------------------------
* 5. Build a multi-quantile esttab-style table
* ---------------------------------------------------------------------
capture which esttab
local hasesttab = (_rc == 0)

if `hasesttab' {
        foreach q in 0.10 0.25 0.50 0.75 0.90 {
                quietly dnqr y, network(W) rowstd quantile(`q') ///
                        z(Z1 Z2) factors(F1 F2) notable
                local nm = round(100*`q')
                estimates store dnqr_`nm'
        }
        esttab dnqr_10 dnqr_25 dnqr_50 dnqr_75 dnqr_90 , ///
                se star(* 0.10 ** 0.05 *** 0.01) ///
                mtitles("tau=0.10" "tau=0.25" "tau=0.50" "tau=0.75" "tau=0.90") ///
                title("DNQR estimates across quantiles") ///
                addnote("Powell standard errors with HS bandwidth.")
}

if !`hasesttab' di as txt "Install -estout- (ssc install estout) to use esttab integration."

* ---------------------------------------------------------------------
* 6. Tiny Monte-Carlo loop (illustrative; bumps R reps to a larger N for a real run)
* ---------------------------------------------------------------------
local Rep = 25
matrix MC = J(`Rep', 3, .)
forvalues r = 1/`Rep' {
        local sd = 1000 + `r'
        quietly dnqr_simulate, n(60) t(40) gamma1(0.25) gamma2(0.2) gamma3(0.3) ///
                seed(`sd') clear wname(W)
        quietly dnqr y, network(W) rowstd quantile(0.5) notable
        matrix MC[`r', 1] = e(b_q)[2, 1]
        matrix MC[`r', 2] = e(b_q)[3, 1]
        matrix MC[`r', 3] = e(b_q)[4, 1]
}
mata: st_matrix("MEAN", mean(st_matrix("MC")))
mata: st_matrix("SD",   sqrt(variance(st_matrix("MC"))))
matrix list MEAN
matrix list SD
