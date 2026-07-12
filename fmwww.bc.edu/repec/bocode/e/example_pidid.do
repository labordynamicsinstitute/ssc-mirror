*-------------------------------------------------------------------
* example_pidid.do
* Reproduces every example shown in "pidid: A command for
* path-integrated difference-in-differences impact evaluation"
* (Salavi, 2026), using the accompanying trainingpanel.dta dataset.
*
* Run from the directory containing pidid.ado, pididplot.ado, and
* trainingpanel.dta (or adjust the adopath/cd lines below).
*
* Expected results (matching Table 1 of the article exactly):
*   sigma (cumulative causal effect)   = 20,500
*   tau-bar (path-integrated ATT)      =  4,100 per year
*   conventional static DiD (0 vs. 5)  =      0
*
* Figures are saved as PDF and use the "sj" scheme, per the Stata
* Journal's figure guidelines (PDF format, sj/stsj scheme, legible in
* grayscale).
*-------------------------------------------------------------------

capture log close
log using pidid.log, replace text

version 14.0
clear all
set more off
set linesize 80

* Make pidid/pididplot available if they sit alongside this do-file
* rather than in a standard ado-path directory:
capture adopath ++ "`c(pwd)'"

set scheme sj

use trainingpanel, clear
describe
list, sepby(treat) noobs

* --- Full-horizon estimate (t0 = 0, t1 = 5) -------------------------
pidid earnings, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(5)

display as text ""
display as text "sigma should equal 20500:      " as result r(sigma)
display as text "tau-bar should equal 4100:     " as result r(att_path)
display as text "static DiD should equal 0:     " as result r(did_static)

* --- Dedicated impact graph (paths + cumulative sigma(t) buildup) --
* t2(5) here since the paths fully rejoin exactly at Year 5 in this
* illustration; set t2() to an earlier date if convergence happens
* before the chosen evaluation horizon t1().
pididplot earnings, panelvar(id) timevar(time) treatvar(treat) ///
	t0(0) t1(5) t2(5) ///
	title("Training program: cumulative earnings impact") ///
	name(pidid_impact)

graph export pididplot_example.pdf, replace

* --- Truncating the evaluation horizon at the rejoining point ------
* (t2 = 5 here as well, so this reproduces the same, horizon-invariant
*  sigma even if T1 were pushed further out -- try t1(8) after adding
*  more post-rejoining years of identical c0()=c1() to see sigma stay
*  fixed at 20,500 while tau-bar shrinks.)
pidid earnings, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(3)

log close
