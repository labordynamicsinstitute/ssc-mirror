*! example_lwavelet.do — Full worked example of the lwavelet package
*! Author: Dr. Merwan Roudane
*! Date: 2026-05-11
*!
*! A single coherent walkthrough exercising every command in lwavelet
*! on Stata's built-in Lütkepohl quarterly macro dataset (1960q1–1982q4).
*!
*! Economic question
*! -----------------
*! West German investment (inv), income (inc), and consumption (consump):
*!     - At which frequency bands do they co-move?
*!     - Is the co-movement statistically significant?
*!     - Does income lead investment, or the reverse?
*!
*! Wavelets answer all three at once: scale-by-scale magnitude (wmcorr),
*! scale-by-scale phase (xwt, wtc), and scale-by-scale lead-lag (wmxcorr).

clear all
set more off
cap log close
log using "example_lwavelet.log", text replace

// ═══════════════════════════════════════════════════════════════════════════
// 0a. Bootstrap — make sure the Mata library is loadable in THIS Stata
// ═══════════════════════════════════════════════════════════════════════════
//
// If the shipped lwavelet.mlib was built in a newer Stata than the one
// running now, it is silently rejected ("compiled by Stata X, too new").
// We probe a known function; on failure we recompile from the .mata
// sources that ship alongside the library.

capture mata: _wv_max_level(92, "la8")
if _rc {
    display as text "lwavelet.mlib unavailable in this Stata — compiling from .mata sources..."
    capture mata: mata drop _wv_*()
    local plus : sysdir PLUS
    local mdir "`plus'l/"
    if !fileexists("`mdir'_wv_filters.mata") {
        // fall back to current working directory (dev / un-installed use)
        local mdir "`c(pwd)'/"
    }
    foreach f in filters core cwt bivariate multi display {
        quietly do "`mdir'_wv_`f'.mata"
    }
    adopath ++ "`mdir'"
}

// ═══════════════════════════════════════════════════════════════════════════
// 0b. Data
// ═══════════════════════════════════════════════════════════════════════════
//
// Lütkepohl (2005) German macro panel — series are in logs, quarterly,
// 92 observations. dt = 0.25 (years/quarter) for the CWT.

webuse lutkepohl2, clear
tsset qtr

summarize inv inc consump

// Quick visual sanity check of the three series
tsline inv inc consump, ///
    title("Lütkepohl quarterly macro (log levels)") ///
    legend(order(1 "investment" 2 "income" 3 "consumption"))


// ═══════════════════════════════════════════════════════════════════════════
// 1. MODWT decomposition of investment (lmodwt)
// ═══════════════════════════════════════════════════════════════════════════
//
// Decompose investment into J = 3 frequency bands using the LA(8) filter.
// With N = 92 quarters, J = 3 is the maximum admissible level for LA(8)
// (the filter must fit inside the longest scale). The three detail bands
// correspond to:
//     D1 :  2–4   quarters  (≈ 6–12 months)
//     D2 :  4–8   quarters  (≈ 1–2  years)
//     D3 :  8–16  quarters  (≈ 2–4  years)   ← short business cycle
// S3 captures everything slower than ~4 years (trend + long cycle).

lmodwt inv, levels(3) filter(la8) mra generate(_inv)
ereturn list

// e(W1)…e(W3) hold the wavelet coefficients; e(VJ) is the final-level
// scaling (named VJ because V is reserved by ereturn post).
// e(wvar) gives the wavelet variance per scale — the energy decomposition.
matrix list e(wvar), format(%9.4f)

// Plot the MRA components stored in _inv_D1 … _inv_D3 and _inv_S3.
// Stacked panels are short, so force a small number of horizontal,
// comma-formatted y-ticks and make the combined canvas tall.
local mraopts ytitle("") xtitle("") ///
    ylabel(#3, angle(horizontal) labsize(small) format(%9.0fc)) ///
    xlabel(, labsize(small)) ///
    yline(0, lcolor(gs10) lwidth(vthin))

tsline _inv_D1, name(d1, replace) title("D1: 6–12 month cycle") `mraopts' nodraw
tsline _inv_D2, name(d2, replace) title("D2: 1–2 year cycle")   `mraopts' nodraw
tsline _inv_D3, name(d3, replace) title("D3: 2–4 year cycle")   `mraopts' nodraw
tsline _inv_S3, name(sj, replace) title("S3: trend (>4 yrs)")   `mraopts' nodraw

graph combine d1 d2 d3 sj, cols(1) ysize(10) xsize(7) ///
    title("MODWT MRA of investment") ///
    name(mra, replace)


// ═══════════════════════════════════════════════════════════════════════════
// 2. CWT power spectrum of investment (wt)
// ═══════════════════════════════════════════════════════════════════════════
//
// The CWT gives a continuous time–frequency picture of where the energy
// of `inv' lives. Anti-symmetric reflect padding + cosine taper suppress
// edge artifacts. Hatched region = cone of influence (COI) — interpret
// power inside it with caution. Black contours mark 95% significance
// against an AR(1) red-noise null.

wt inv, dt(0.25) mother(morlet) plot colormap(turbo)

display "Power matrix:  " rowsof(e(power)) " scales × " colsof(e(power)) " time points"
display "Period range:  " el(e(period),1,1) " – " ///
    el(e(period),rowsof(e(period)),1) " years"


// ═══════════════════════════════════════════════════════════════════════════
// 3. Cross-wavelet transform inv–inc (xwt)
// ═══════════════════════════════════════════════════════════════════════════
//
// XWT highlights time–scale regions where investment AND income are both
// energetic. e(phase) gives the relative phase — converted to lead-lag
// in years via lag = phase * period / (2π).

xwt inv inc, dt(0.25) mother(morlet)

display "var1 = " e(var1) ", var2 = " e(var2)
display "Cross-power matrix: " rowsof(e(power)) " × " colsof(e(power))


// ═══════════════════════════════════════════════════════════════════════════
// 4. Wavelet coherence with Monte Carlo significance (wtc)
// ═══════════════════════════════════════════════════════════════════════════
//
// Coherence is the time–scale analogue of squared correlation: it tells
// you WHERE (in time and frequency) the two series co-move, regardless
// of common amplitude. Monte Carlo simulates AR(1) surrogates to set the
// 95% significance contour. Phase arrows on the plot encode lead-lag:
//
//     →  in phase                 (inv and inc move together)
//     ←  anti-phase               (inv and inc move oppositely)
//     ↑  inv leads inc by 90°    (quarter cycle)
//     ↓  inc leads inv by 90°    (quarter cycle)

wtc inv inc, dt(0.25) nrands(500) plot


// ═══════════════════════════════════════════════════════════════════════════
// 5. Wavelet multiple correlation across inv, inc, consump (wmcorr)
// ═══════════════════════════════════════════════════════════════════════════
//
// Fernández-Macho (2012): at each scale j, invert the d×d pairwise
// correlation matrix and form R²(j) = 1 − 1/max(diag(P⁻¹)). e(ymaxr)
// reports which variable plays the "dependent" role (yields max R²) at
// each scale — useful for spotting where one series is well-explained
// by the others, and where it is not.

wmcorr inv inc consump, levels(3) filter(la8) plot

matrix list e(wmcorr), format(%9.4f)
matrix list e(ymaxr)


// ═══════════════════════════════════════════════════════════════════════════
// 6. Wavelet multiple regression (wmreg)
// ═══════════════════════════════════════════════════════════════════════════
//
// OLS at each wavelet scale, with the dependent variable auto-selected as
// the one yielding max R² (YmaxR). Compare which regressor dominates at
// short vs long horizons — coefficients are scale-specific, not global.

wmreg inv inc consump, levels(3) filter(la8) plot

matrix list e(rsq),   format(%9.4f)

// Per-scale coefficients are stored individually as e(beta1)…e(betaJ)
// (along with e(se*), e(tstat*), e(pval*)). Inspect each scale:
forvalues j = 1/3 {
    di as text "  Coefficients at scale j=`j':"
    matrix list e(beta`j'), format(%9.4f) noheader
}


// ═══════════════════════════════════════════════════════════════════════════
// 7. Wavelet multiple cross-correlation (wmxcorr)
// ═══════════════════════════════════════════════════════════════════════════
//
// For each scale j, compute correlations at lags −maxlag…+maxlag. Peak at
// positive lag → first variable leads; peak at negative lag → first lags.
// With quarterly data, maxlag(8) covers up to two years of lead-lag.

wmxcorr inv inc consump, levels(3) filter(la8) maxlag(8) plot


// ═══════════════════════════════════════════════════════════════════════════
// 8. What to do with the e() returns
// ═══════════════════════════════════════════════════════════════════════════
//
// Every command stores its full output as e() matrices so downstream
// analysis is straightforward. A few useful idioms:
//
//   matrix R = e(wmcorr)            // export scale-by-scale R with CI
//   svmat   R, names(col)
//
//   matrix P = e(power)             // CWT power → wide-form variables
//   svmat   P
//
//   matrix W = e(W2)                // pick a single MODWT scale
//   svmat   W

display ""
display as result "Worked example complete. Inspect the plots in the Graph window."
display as text   "See {help wavelet} for the command reference."

log close
