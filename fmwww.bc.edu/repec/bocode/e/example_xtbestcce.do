// =====================================================================
//  example_xtbestcce.do
//
//  Demonstration of the xtbestcce package.
//
//  Implements:
//   1. A small empirical example on the Grunfeld panel.
//   2. A Monte Carlo experiment that mirrors Section 4.1 of
//      Stauskas & De Vos (2024) — distinct factors driving y and X,
//      heterogeneous slopes, and high cross-section dependence.
//
//  Author : Dr. Merwan Roudane (merwanroudane920@gmail.com)
//  Paper  : MPRA No. 120194.
// =====================================================================

clear all
set more off

// Make sure xtbestcce sits in your adopath. If running from the package
// folder, that is automatically the case.
adopath ++ "`c(pwd)'"

// -----------------------------------------------------------------
// PART 1 — Empirical illustration (Grunfeld)
// -----------------------------------------------------------------
webuse grunfeld, clear
xtset company year

di as txt _newline "{bf:Plain CCEP (full CAs, analytical SE):}"
xtbestcce invest mvalue kstock, pooled fe

di as txt _newline "{bf:CCEMG with IC-selected CAs:}"
xtbestcce invest mvalue kstock, mg fe ic

di as txt _newline "{bf:Full toolbox — CCEP + IC + CS bootstrap (B=499):}"
xtbestcce invest mvalue kstock,                                      ///
        pooled fe ic                                                    ///
        bootstrap reps(499) seed(202612)                                ///
        nice plot bootplot

// Save the graphs to disk
graph display
graph export coef_grunfeld.png, replace width(1200)


// -----------------------------------------------------------------
// PART 2 — Monte Carlo (Section 4.1 design)
// -----------------------------------------------------------------
//
//   y_{i,t} = β x_{i,t} + f_{y,t}' γ_i + ε_{i,t}
//   x_{i,t} =              f_{x,t}' Γ_i + v_{i,t}
//
//   f_{y,t} ~ N(0, I_{my}/my), my = 2     (distinct from x's factors)
//   f_{x,t} ~ N(0, I_{mx}/mx), mx = 2
//   corr(f_y, f_x) = 0.7  (high dependence — Table 1)
//
//   Heterogeneous slopes:  β_i = β + v_i,  v_i ~ N(0, 1)
//
//   N = 50, T = 50  ;  500 replications
//
program drop _all
program define _xtbestcce_dgp
        syntax , N(integer) T(integer) my(integer) mx(integer) rhof(real)
        clear
        local NT = `N' * `T'
        set obs `NT'
        gen long i = mod(_n-1, `N') + 1
        bys i (_n): gen long t = _n
        xtset i t

        // Common factor generator: f_y and f_x correlated cross-sectionally
        forvalues s = 1/`my' {
                gen double fy`s' = .
        }
        forvalues s = 1/`mx' {
                gen double fx`s' = .
        }
        forvalues tt = 1/`T' {
                forvalues s = 1/`my' {
                        local fy = rnormal(0, sqrt(1/`my'))
                        local fx = `rhof'*`fy' + sqrt(1-`rhof'^2)*rnormal(0, sqrt(1/`mx'))
                        quietly replace fy`s' = `fy' if t == `tt'
                        quietly replace fx`s' = `fx' if t == `tt'
                }
                if `mx' > `my' {
                        forvalues s = `=`my'+1'/`mx' {
                                quietly replace fx`s' = rnormal(0, sqrt(1/`mx')) if t == `tt'
                        }
                }
        }

        // Per-unit loadings
        bys i: gen double gam = rnormal(0.5, 1) if _n == 1
        bys i (t): replace gam = gam[1]
        bys i: gen double Gam = rnormal(0.5, 1) if _n == 1
        bys i (t): replace Gam = Gam[1]

        // x and y
        gen double x = 0
        forvalues s = 1/`mx' {
                quietly replace x = x + Gam*fx`s'
        }
        quietly replace x = x + rnormal()

        // heterogeneous beta
        bys i: gen double bi = 1 + rnormal() if _n == 1
        bys i (t): replace bi = bi[1]

        gen double y = bi*x
        forvalues s = 1/`my' {
                quietly replace y = y + gam*fy`s'
        }
        quietly replace y = y + rnormal()

        keep i t y x
end


// run a small MC
local R     = 50           // keep small for demo speed; raise as desired
local N     = 50
local T     = 50
local truebeta = 1

tempname results
matrix `results' = J(`R', 6, .)
matrix colnames `results' =                                            ///
        ccep_plain ccep_boot ccemg_plain ccemg_boot ccemg_ic ccemg_boot_ic

di as txt _newline "{bf:Monte Carlo: distinct factors, het. slopes, B=199}"
di as txt "rep  ccepP   ccepB   ccemgP  ccemgB  ccemgIC ccemgBIC"
forvalues r = 1/`R' {
        quietly _xtbestcce_dgp, n(`N') t(`T') my(2) mx(2) rhof(0.7)
        quietly xtbestcce y x, pooled fe notable
        local b1 = _b[x]
        quietly xtbestcce y x, pooled fe bootstrap reps(199) seed(`r') notable
        local b2 = _b[x]
        quietly xtbestcce y x, mg fe notable
        local b3 = _b[x]
        quietly xtbestcce y x, mg fe bootstrap reps(199) seed(`r') notable
        local b4 = _b[x]
        quietly xtbestcce y x, mg fe ic notable
        local b5 = _b[x]
        quietly xtbestcce y x, mg fe ic bootstrap reps(199) seed(`r') notable
        local b6 = _b[x]
        matrix `results'[`r', 1] = `b1'
        matrix `results'[`r', 2] = `b2'
        matrix `results'[`r', 3] = `b3'
        matrix `results'[`r', 4] = `b4'
        matrix `results'[`r', 5] = `b5'
        matrix `results'[`r', 6] = `b6'
        di as res %3.0f `r'   ///
           "   " %6.3f `b1' "  " %6.3f `b2' "  " %6.3f `b3' "  " ///
                 %6.3f `b4' "  " %6.3f `b5' "  " %6.3f `b6'
}

// Summarise MC bias against truebeta = `truebeta'
clear
svmat `results', names(col)
foreach v in ccep_plain ccep_boot ccemg_plain ccemg_boot ccemg_ic ccemg_boot_ic {
        gen double bias_`v' = `v' - `truebeta'
}
di as txt _newline "{bf:MC summary (bias):}"
summarize bias_*
