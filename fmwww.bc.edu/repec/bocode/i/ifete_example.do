cscript
log using ifete_example.txt, replace

** Example 1: estimating the impact of economic integration between Hong Kong and mainland China in 2004q1 (Hsiao et al., 2012)
use growth2, clear
xtset region time
* Visualize the configuration of the treatment variable "ei" for economic integration in panel data ("panelview" has been installed from SSC)
panelview gdp ei, i(region) t(time) type(treat)
* Implement factor-based estimation and create a Stata frame "growth_ei" storing generated variables including treatment effects and confidence intervals
ifete gdp, treatvar(ei) frame(growth_ei)
* Change to the generated Stata frame "growth_ei" containing the results
frame change growth_ei
describe, simple
* Change back to the default Stata frame
frame change default

** Example 2: estimating the effect of California's tobacco control program (Abadie, Diamond, and Hainmueller 2010)
use smoking2, clear
xtset state year
* Visualize the treatment structure for California's tobacco control program 
panelview cigsale ctcp, i(state) t(year) type(treat)
* Implement factor-based estimation for a model with covariates and a nonstationary trend using eigenvalue ratio criterion (er)
ifete cigsale lnincome eduattain poverty, treatvar(ctcp) trend(1) rmethod(er)
* List the names and values of the macros, scalars and matrix stored in e()
ereturn list

log close