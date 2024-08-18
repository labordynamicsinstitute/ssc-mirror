cscript
cap log close
log using xtteifeci_example, replace

** Example 1: estimating the impact of political integration of Hong Kong with mainland China in 1997q3 (Hsiao et al., 2012)

use growth2, clear
xtset region time
* Visualize the configuration of the treatment variable "pi" for political integration in panel data ("panelview" has been installed from SSC).
qui panelview gdp pi, i(region) t(time) type(treat)
* Implement factor-based estimation upon the condition of no missing values in "pi"
xtteifeci gdp if !missing(pi), treatvar(pi)
* Implement factor-based estimation with the reporting of symmetric confidence intervals
xtteifeci gdp if !missing(pi), treatvar(pi) citype(sy)

** Example 2: estimating the impact of economic integration between Hong Kong and mainland China in 2004q1 (Hsiao et al., 2012)

use growth2, clear
xtset region time
* Visualize the configuration of the treatment variable "ei" for economic integration in panel data ("panelview" has been installed from SSC)
qui panelview gdp ei, i(region) t(time) type(treat)
* Implement factor-based estimation and create a Stata frame "growth_ei" storing generated variables
xtteifeci gdp, treatvar(ei) frame(growth_ei)
* Change to the generated Stata frame "growth_ei"
frame change growth_ei
* Change back to the default Stata frame
frame change default


**Example 3: estimating the effect of California's tobacco control program (Abadie, Diamond, and Hainmueller 2010)

use smoking2, clear
xtset state year
* Visualize the configuration of the treatment variable "ctcp" for California's tobacco control program (CTCP) in panel data ("panelview" has been installed from SSC)
qui panelview cigsale ctcp, i(state) t(year) type(treat)
* Implement factor-based estimation for the model with covariates, a nonstationary trend and the number of factors calculated by ABC information criterion
xtteifeci cigsale lnincome eduattain poverty, treatvar(ctcp) trend(1) rmethod(abc)
* List the names and values of the macros, scalars and matrix stored in e()
ereturn list

log close
