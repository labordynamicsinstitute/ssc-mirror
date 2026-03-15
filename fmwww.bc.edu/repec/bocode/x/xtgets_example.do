********************************************************************************
* xtgets_example.do
* Example do-file for the xtgets package
* Panel General-to-Specific (GETS) Indicator Saturation
* Author: Dr Merwan Roudane  merwanroudane920@gmail.com
* Date: 14 March 2026
*
* Replicates the R getspanel package examples (Pretis & Schwarz, 2022/2026)
* using log-scale data similar to:
*   isatpanel(data=EU_emissions_road,
*     formula = ltransport.emissions ~ lgdp + lpop,
*     index = c("country","year"), effect="twoways", fesis=TRUE, t.pval=0.01)
********************************************************************************

clear all
set more off

* ==============================================================================
* 1. SIMULATE PANEL DATA WITH KNOWN STRUCTURAL BREAKS
*    All variables in logs — matching R EU_emissions_road usage
*    Coefficients are elasticities (reasonable magnitudes)
* ==============================================================================

set seed 12345
local N_units = 15
local T_periods = 25
local nobs = `N_units' * `T_periods'
set obs `nobs'

* Panel structure
gen country = ceil(_n / `T_periods')
gen year = mod(_n - 1, `T_periods') + 1995

xtset country year

* Generate regressors (all in logs)
gen lgdp = 9.5 + country * 0.05 + 0.02 * (year - 1995) + rnormal(0, 0.03)
gen lpop = 15.5 + country * 0.1 + rnormal(0, 0.01)

* Individual FE (absorbed by dummies)
gen alpha_i = 2 + country * 0.3

* Time FE (common trend)
gen gamma_t = 0.015 * (year - 1995)

* TRUE structural breaks (FESIS-type level shifts in log emissions):
*   Country 3:  +0.5 from year 2008  (e.g. policy event increasing emissions)
*   Country 7:  -0.4 from year 2010  (e.g. policy reducing emissions)
*   Country 5:  +0.3 from year 2005  (e.g. structural change)
*   Country 12: -0.35 from year 2012 (e.g. regulation)
gen break_3  = (country == 3  & year >= 2008) * 0.5
gen break_7  = (country == 7  & year >= 2010) * (-0.4)
gen break_5  = (country == 5  & year >= 2005) * 0.3
gen break_12 = (country == 12 & year >= 2012) * (-0.35)

* DGP: log(emissions) = alpha_i + gamma_t + 0.8*lgdp - 0.3*lpop + breaks + u
gen lemissions = alpha_i + gamma_t + 0.8 * lgdp + (-0.3) * lpop ///
    + break_3 + break_7 + break_5 + break_12 + rnormal(0, 0.05)

drop alpha_i gamma_t break_*

* ==============================================================================
* Display
* ==============================================================================

di
di "{hline 78}"
di "{bf:xtgets Example: Simulated Panel Data (log scale)}"
di "{hline 78}"
di
di "DGP: lemissions = alpha_i + gamma_t + 0.8*lgdp - 0.3*lpop + breaks + u"
di "     where u ~ N(0, 0.05)"
di
di "True FESIS breaks:"
di "  Country 3:  +0.50 from 2008"
di "  Country 5:  +0.30 from 2005"
di "  Country 7:  -0.40 from 2010"
di "  Country 12: -0.35 from 2012"
di

* ==============================================================================
* 2. Example 1: FESIS only (detecting structural level shifts)
* ==============================================================================

di
di "{hline 78}"
di "{bf:Example 1: FESIS with t.pval = 0.01}"
di "{hline 78}"
di

xtgets lemissions lgdp lpop, fesis effect(twoways) t_pval(0.01)

* ==============================================================================
* 2b. VISUALIZATIONS (replicating R getspanel plot functions)
*     plot(is1)              -> xtgets_plot, type(breaks)     [scatter]
*     plot(is1)              -> xtgets_plot, type(heatmap)    [heatmap]
*     plot_grid(is1)         -> xtgets_plot, type(grid)
*     plot_counterfactual    -> xtgets_plot, type(counter)
*     plot_residuals(is1)    -> xtgets_plot, type(residuals)
* ==============================================================================

di
di "{hline 78}"
di "{bf:Visualization: Break Detection Timeline}"
di "  R equivalent: plot(is1)"
di "{hline 78}"

xtgets_plot, type(breaks) saving(xtgets_breaks)

di
di "{hline 78}"
di "{bf:Visualization: Effect Heatmap}"
di "  R equivalent: plot(is1) — heatmap style"
di "{hline 78}"

xtgets_plot, type(heatmap) saving(xtgets_heatmap)

di
di "{hline 78}"
di "{bf:Visualization: Fitted vs Actual Grid}"
di "  R equivalent: plot_grid(is1)"
di "{hline 78}"

xtgets_plot, type(grid) saving(xtgets_grid)

di
di "{hline 78}"
di "{bf:Visualization: Counterfactual Analysis}"
di "  R equivalent: plot_counterfactual(is1, plus_t=5)"
di "{hline 78}"

xtgets_plot, type(counter) saving(xtgets_counterfactual)

di
di "{hline 78}"
di "{bf:Visualization: Residual Analysis}"
di "  R equivalent: plot_residuals(is1)"
di "{hline 78}"

xtgets_plot, type(residuals) saving(xtgets_residuals)

* ==============================================================================
* 3. Example 2: FESIS with R-default (t.pval = 0.001, very strict)
* ==============================================================================

di
di "{hline 78}"
di "{bf:Example 2: FESIS with t.pval = 0.001 (R default)}"
di "{hline 78}"
di

xtgets lemissions lgdp lpop, fesis effect(twoways) t_pval(0.001) verbose

* ==============================================================================
* 4. Example 3: Combined FESIS + IIS (two-stage selection)
*    Stage 1 finds structural breaks, Stage 2 finds residual outliers
* ==============================================================================

di
di "{hline 78}"
di "{bf:Example 3: FESIS + IIS (two-stage selection)}"
di "{hline 78}"
di

xtgets lemissions lgdp lpop, fesis iis effect(twoways) t_pval(0.01)

* ==============================================================================
* 5. Example 4: CSIS — testing coefficient stability
* ==============================================================================

di
di "{hline 78}"
di "{bf:Example 4: CSIS - testing stability of lgdp coefficient}"
di "{hline 78}"
di

xtgets lemissions lgdp lpop, csis csis_var(lgdp) effect(twoways) t_pval(0.01)

* ==============================================================================
* 6. Stored results
* ==============================================================================

di
di "{hline 78}"
di "{bf:Stored Results}"
di "{hline 78}"
di

di "  Command:       " e(cmd)
di "  Effect:        " e(effect)
di "  t-limit:       " %6.3f e(tlimit)
di "  t.pval:        " %7.5f e(t_pval)
di "  gamma_c:       " %9.6f e(gamma_c)
di "  N indicators:  " e(n_indicators)
di "  N retained:    " e(n_retained)
di "  N units:       " e(N_units)
di "  T periods:     " e(T_periods)
di "  Retained:      " e(retained)

* ==============================================================================
di
di "{hline 78}"
di "{bf:All examples completed.}"
di "{hline 78}"
