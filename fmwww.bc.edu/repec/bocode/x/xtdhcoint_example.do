/*==============================================================================
    XTDHCOINT EXAMPLES
    
    This do-file demonstrates the use of the xtdhcoint command for
    Durbin-Hausman panel cointegration tests (Westerlund, 2008).
    
    Author: Dr. Merwan Roudane
    Email:  merwanroudane920@gmail.com
    Date:   February 2026
==============================================================================*/

clear all
set more off

*------------------------------------------------------------------------------
* EXAMPLE 1: Basic usage with Grunfeld data
*------------------------------------------------------------------------------

di _n as text "{hline 78}"
di as text "{bf:Example 1: Basic Durbin-Hausman Panel Cointegration Test}"
di as text "{hline 78}"

webuse grunfeld, clear
xtset company year

* Basic test
xtdhcoint invest mvalue kstock

* Store and display results
di _n as text "Stored results:"
di as text "  DHg z-value = " as result r(dhg_z)
di as text "  DHp z-value = " as result r(dhp_z)
di as text "  DHg p-value = " as result r(dhg_p)
di as text "  DHp p-value = " as result r(dhp_p)
di as text "  Number of factors = " as result r(nf)

*------------------------------------------------------------------------------
* EXAMPLE 2: Testing with predetermined coefficient
*------------------------------------------------------------------------------

di _n as text "{hline 78}"
di as text "{bf:Example 2: Test with Predetermined Coefficient (e.g., Fisher Effect)}"
di as text "{hline 78}"

* When testing the Fisher effect, the theory suggests beta = 1
xtdhcoint invest mvalue, predet(1)

*------------------------------------------------------------------------------
* EXAMPLE 3: Using different information criteria
*------------------------------------------------------------------------------

di _n as text "{hline 78}"
di as text "{bf:Example 3: Comparing Different Information Criteria}"
di as text "{hline 78}"

di as text "Using IC criterion (default):"
qui xtdhcoint invest mvalue kstock, criterion(ic)
di as text "  Factors: " as result r(nf) ///
   as text ", DHg_z = " as result %7.3f r(dhg_z) ///
   as text ", DHp_z = " as result %7.3f r(dhp_z)

di _n as text "Using PC criterion:"
qui xtdhcoint invest mvalue kstock, criterion(pc)
di as text "  Factors: " as result r(nf) ///
   as text ", DHg_z = " as result %7.3f r(dhg_z) ///
   as text ", DHp_z = " as result %7.3f r(dhp_z)

di _n as text "Using BIC criterion:"
qui xtdhcoint invest mvalue kstock, criterion(bic)
di as text "  Factors: " as result r(nf) ///
   as text ", DHg_z = " as result %7.3f r(dhg_z) ///
   as text ", DHp_z = " as result %7.3f r(dhp_z)

*------------------------------------------------------------------------------
* EXAMPLE 4: Varying maximum factors
*------------------------------------------------------------------------------

di _n as text "{hline 78}"
di as text "{bf:Example 4: Varying Maximum Number of Factors}"
di as text "{hline 78}"

forvalues k = 1/5 {
    qui xtdhcoint invest mvalue kstock, kmax(`k')
    di as text "  kmax = `k': nf = " as result r(nf) ///
       as text ", DHg_z = " as result %7.3f r(dhg_z) ///
       as text ", DHp_z = " as result %7.3f r(dhp_z)
}

*------------------------------------------------------------------------------
* EXAMPLE 5: Monte Carlo - Testing under H0 (no cointegration)
*------------------------------------------------------------------------------

di _n as text "{hline 78}"
di as text "{bf:Example 5: Simulated Data under H0 (no cointegration)}"
di as text "{hline 78}"

clear
set seed 12345

local N = 20
local T = 100

set obs `=`N' * `T''
gen id = ceil(_n / `T')
gen time = mod(_n - 1, `T') + 1
xtset id time

* Independent random walks (no cointegration)
gen u_y = rnormal()
gen u_x = rnormal()
bysort id (time): gen y = sum(u_y)
bysort id (time): gen x = sum(u_x)

di as text "Testing under H0 (no cointegration):"
xtdhcoint y x

di _n as text "Under H0, z-values should be small and p-values > 0.05."

*------------------------------------------------------------------------------
* EXAMPLE 6: Monte Carlo - Testing under H1 (cointegration)
*------------------------------------------------------------------------------

di _n as text "{hline 78}"
di as text "{bf:Example 6: Simulated Data under H1 (cointegration)}"
di as text "{hline 78}"

clear
set seed 54321

local N = 20
local T = 100

set obs `=`N' * `T''
gen id = ceil(_n / `T')
gen time = mod(_n - 1, `T') + 1
xtset id time

* Cointegrated series: y = 0.5 + x + stationary error
gen e = rnormal()
gen u_x = rnormal()
bysort id (time): gen x = sum(u_x)
gen y = 0.5 + x + e

di as text "Testing under H1 (with cointegration, beta=1):"
xtdhcoint y x

di _n as text "Under H1, z-values should be large and p-values < 0.05."

*------------------------------------------------------------------------------
* SUMMARY
*------------------------------------------------------------------------------

di _n as text "{hline 78}"
di as text "{bf:Summary}"
di as text "{hline 78}"
di as text " "
di as text "The xtdhcoint command implements Westerlund's (2008) Durbin-Hausman"
di as text "panel cointegration tests. Key features:"
di as text " "
di as text "  1. Allows for cross-sectional dependence via common factors"
di as text "  2. Robust to stationary regressors"
di as text "  3. Can use predetermined cointegrating coefficients"
di as text "  4. Normal asymptotic distribution"
di as text " "
di as text "For more details: help xtdhcoint"
di as text "{hline 78}"
