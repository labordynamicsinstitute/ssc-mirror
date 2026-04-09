/* =====================================================================
   qmodplot_demo.do
   Demonstration script for qmodplot v1.0.0
   Noman Arshed, Sunway Business School, Sunway University

   All examples use Stata's built-in -auto- dataset.
   Install first:  ssc install qmodplot
   ===================================================================== */

clear all
set more off


/* -------------------------------------------------------------------
   EXAMPLE 1
   Model 1 — Linear MPG + Binary Moderator (domestic vs foreign)
   Two curves: one for domestic (m=0), one for foreign (m=1)
   ------------------------------------------------------------------- */

sysuse auto, clear
gen mpgf = mpg * foreign

regress price mpg foreign mpgf

qmodplot, model(1) fromereturn                   ///
    xvar(mpg) mvar(foreign) xmvar(mpgf)          ///
    xname(MPG) mname(Foreign) yname(Price)        ///
    xrange(12 41) mvalues(0 1)                   ///
    combine

graph export "qmodplot_ex1.png", name(qmodplot_combined) replace


/* -------------------------------------------------------------------
   EXAMPLE 2
   Model 2 — Quadratic MPG + Continuous Moderator (vehicle weight)
   Five theory-driven reference points show how the parabola vertex
   shifts as cars get heavier.  CI bands and turning-point table.
   ------------------------------------------------------------------- */

sysuse auto, clear
gen mpgsq = mpg^2
gen mpgwt = mpg * weight

regress price mpg mpgsq weight mpgwt

qmodplot, model(2) fromereturn                       ///
    xvar(mpg) xsqvar(mpgsq) mvar(weight) xmvar(mpgwt) ///
    xname(MPG) mname(Weight) yname(Price)             ///
    xrange(12 41) mvalues(2000 2500 3000 3500 4000)   ///
    ci level(95) cutstats combine

graph export "qmodplot_ex2.png", name(qmodplot_combined) replace


/* -------------------------------------------------------------------
   EXAMPLE 3
   Model 2 — Same model, but let the DATA choose reference points
   nquantiles(4) => p20 / p40 / p60 / p80 of weight
   ------------------------------------------------------------------- */

qmodplot, model(2) fromereturn                       ///
    xvar(mpg) xsqvar(mpgsq) mvar(weight) xmvar(mpgwt) ///
    xname(MPG) mname(Weight) yname(Price)             ///
    xrange(12 41) mdata(weight) nquantiles(4)         ///
    ci level(95) cutstats combine

graph export "qmodplot_ex3.png", name(qmodplot_combined) replace


/* -------------------------------------------------------------------
   EXAMPLE 4
   Model 3 — Fully Moderated Curvature + CI + scatter labels
   x2*m term means curvature itself changes with the moderator.
   Scatter overlays each observation with its origin label.
   Results saved to CSV.
   ------------------------------------------------------------------- */

sysuse auto, clear
gen mpgsq  = mpg^2
gen mpgf   = mpg   * foreign
gen mpgfsq = mpgsq * foreign

regress price mpg mpgsq foreign mpgf mpgfsq

qmodplot, model(3) fromereturn                           ///
    xvar(mpg) xsqvar(mpgsq) mvar(foreign)               ///
    xmvar(mpgf) xsqmvar(mpgfsq)                         ///
    xname(MPG) mname(Foreign) yname(Price)               ///
    xrange(12 41) mvalues(0 1)                           ///
    xdata(mpg) ydata(price) mdata(foreign)               ///
    ci level(95) cutstats                                ///
    scatter labelvar(foreign)                            ///
    combine savetable("qmodplot_ex4.csv")

graph export "qmodplot_ex4_combined.png", name(qmodplot_combined) replace
graph export "qmodplot_ex4_scatter.png",  name(qmodplot_scatter)  replace


/* -------------------------------------------------------------------
   EXAMPLE 5
   Panel-mean scatter — group by repair record (rep78)
   Collapses data to group means before plotting labelled points.
   ------------------------------------------------------------------- */

sysuse auto, clear
drop if missing(rep78)
gen mpgsq = mpg^2
gen mpgwt = mpg * weight

regress price mpg mpgsq weight mpgwt

qmodplot, model(2) fromereturn                       ///
    xvar(mpg) xsqvar(mpgsq) mvar(weight) xmvar(mpgwt) ///
    xname(MPG) mname(Weight) yname(Price)             ///
    xrange(12 41) mdata(weight) nquantiles(3)         ///
    xdata(mpg) ydata(price)                           ///
    cutstats scatter panelid(rep78) combine

graph export "qmodplot_ex5.png", name(qmodplot_combined) replace

di as text _n "qmodplot_demo complete."
