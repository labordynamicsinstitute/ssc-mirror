* TVTIE: three examples using simulated data.
* Both tvtie_example.dta and tvtie_nonlinear.dta contain simulated observations.
* They are illustrative datasets, not the empirical banking data from the paper.
* Extract all package files, set Stata's working directory to that folder,
* and run: do tvtie_example.do
* The examples use the included datasets and do not require internet access.
* Save any unsaved data before running this file.
version 16.0
clear all
set more off

capture which tvtie
if _rc {
    display as error "Set the working directory to the extracted package folder or install tvtie first."
    exit 111
}

* 1. Exogenous cost frontier with quadratic individual trends.
use "tvtie_example.dta", clear
xtset id period
tvtie y_exo x1 x2, u(u1 u2) cost nolog
predict double te_exogenous, efficiency
summarize te_exogenous

* 2. Endogenous frontier and scaling covariates.
tvtie y x1 x2, u(u1 u2) en(x2 u2) i(z3 z4) cost nolog
estat endogeneity
estat firststage
predict double te_endogenous, efficiency
predict double mean_te, meante
summarize te_endogenous mean_te

* 3. One endogenous variable and its square; z is the excluded instrument.
use "tvtie_nonlinear.dta", clear
xtset id period
tvtie y c.x##c.x, nohet u(u1) en(x) i(z) nolog
estat firststage
predict double te_production, efficiency
summarize te_production
