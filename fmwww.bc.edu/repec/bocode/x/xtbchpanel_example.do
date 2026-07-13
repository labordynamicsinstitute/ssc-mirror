*! xtbchpanel_example.do   Dr Merwan Roudane   merwanroudane920@gmail.com
*! Self-testing DGP for xtbchpanel: a dynamic heterogeneous panel with KNOWN
*! country long-run effects theta_i = (beta_i0 + beta_i1)/(1 - phi_i).
*! The Mean-Group family must recover the cross-country average of theta_i.
*!
*! Run order (MCP-down protocol):
*!    do xtbchpanel.ado          // surfaces any Mata compile error + line
*!    do xtbchpanel_example.do   // truth-vs-estimate; paste the log back
version 15.1
clear
set more off
set seed 20260712

* =======================================================================
* 1.  SIMULATE a dynamic heterogeneous panel with a warming climate
* =======================================================================
local N   = 120           // countries
local T   = 80            // years
local m0  = 20            // climate-norm window used to BUILD the truth

set obs `N'
gen int id = _n

* --- country-specific parameters (heterogeneous, correlated with climate) ---
* NOTE on the DGP: the deviation regressor (2/(m+1))|T-MA_m| is small, so to
* give EACH country an identifiable signal we use ample temperature variation
* and a modest idiosyncratic error (per-country T is large, T=80).
gen double phi_i  = 0.20 + 0.30*runiform()          // in (0.20,0.50): stationary
gen double b0_i   = -0.60 + 0.30*rnormal()          // impact of D.deviation
gen double b1_i   = -0.30 + 0.20*rnormal()          // one lag
gen double gam_i  =  0.10 + 0.10*rnormal()          // loading on common factor
gen double a_i    =  0.02 + 0.01*rnormal()          // country growth intercept
gen double tbar_i = 10 + 20*runiform()              // baseline temperature (deg C)
gen double warm_i = 0.030 + 0.020*runiform()        // warming trend deg C / year

* TRUE long-run effect per country and its cross-country mean
gen double theta_i = (b0_i + b1_i)/(1 - phi_i)
qui summarize theta_i, meanonly
local TRUE_MG = r(mean)

* --- expand to a panel ---------------------------------------------------
expand `T'
bysort id: gen int t = _n
xtset id t

* --- a COMMON global factor, drawn ONCE and shared (not per-obs!) --------
*     (mimics unobserved global business-cycle / climate cycle: one AR(1)
*      path, identical across all countries)
sort id t
gen double f_com = .
forvalues s = 1/`T' {
    if `s'==1 {
        local fval = rnormal()
    }
    else {
        local fval = 0.6*`fval' + rnormal()
    }
    qui replace f_com = `fval' if t==`s'
}

* --- raw temperature: baseline + warming trend + common factor + AR noise -
*     ample year-to-year variation so the deviation regressor is informative
gen double temp = .
bysort id (t): replace temp = tbar_i + warm_i*t + 0.3*f_com + rnormal()*1.5 if t==1
bysort id (t): replace temp = tbar_i + warm_i*t + 0.3*f_com ///
        + 0.4*(L.temp - (tbar_i + warm_i*(t-1))) + rnormal()*1.5 if t>1

* --- build the deviation regressor EXACTLY as xtbchpanel will (m = `m0') ---
tempvar sum MA dev Ddev LDdev
qui gen double `sum' = 0
forvalues j = 1/`m0' {
    qui replace `sum' = `sum' + L`j'.temp
}
qui gen double `MA'   = `sum'/`m0'
qui gen double `dev'  = (2/(`m0'+1))*abs(temp - `MA')
qui gen double `Ddev' = D.`dev'
qui gen double `LDdev'= L.`Ddev'

* --- generate growth g recursively, then log-GDP y = running sum of g -----
gen double g = .
* pre-sample seed for the growth process where the deviation exists
bysort id (t): replace g = a_i + b0_i*`Ddev' + gam_i*L.f_com + 0.005*rnormal() ///
        if `Ddev'<. & L.`Ddev'>=.
* recursive ARDL(1,1): uses the already-updated L.g within the by-group pass
bysort id (t): replace g = a_i + phi_i*L.g + b0_i*`Ddev' + b1_i*`LDdev' ///
        + gam_i*L.f_com + 0.005*rnormal() if `Ddev'<. & `LDdev'<. & L.g<.

* cumulate growth into a log-GDP level
bysort id (t): gen double y = 100 + sum(g)

* a subgroup variable (hot vs temperate) for the by() demo
gen byte hot = tbar_i > 20

label var y    "log real GDP per capita (simulated)"
label var temp "temperature (deg C, warming)"
label var hot  "1 = hot climate, 0 = temperate/cold"

* =======================================================================
* 2.  RECOVERY CHECK  (q = 1 to match the DGP; single window m = `m0')
* =======================================================================
di as txt _n "{hline 70}"
di as res "TRUE cross-country mean long-run effect  theta_MG = " %8.4f `TRUE_MG'
di as txt "{hline 70}"

* world(f_com) supplies the TRUE common factor as the control, matching the
* DGP exactly (the default CSA proxy is only an approximation of it).
xtbchpanel y temp, difference mavars(temp) ma(`m0') lags(1 1) world(f_com) reps(80) nodots

di as txt _n "Compare the MG / HPJ-MG / BC / TMG rows above to " ///
    as res %7.4f `TRUE_MG' as txt " (the truth)."
di as txt "A consistent estimator should sit close to it; TMG is the preferred one."

* =======================================================================
* 3.  FULL DEFAULT RUN  (all windows, all estimators, all paths + graphs)
* =======================================================================
di as txt _n "{hline 70}"
di as res "Full specification: MA {20 30 40 50}, ARDL(1,4), all estimators"
di as txt "{hline 70}"

xtbchpanel y temp, difference mavars(temp) ma(20 30 40 50) lags(1 4) cce reps(60) graph gname(demo) nodots

* stored results
di as txt _n "e(b_all) — long-run estimates (rows = estimators, cols = MA):"
matrix list e(b_all)
di as txt _n "e(hpjfe_b) — pooled homogeneous benchmark:"
matrix list e(hpjfe_b)

* =======================================================================
* 4.  SUBGROUP DEMO  (like the paper's climate-zone tables)
* =======================================================================
di as txt _n "{hline 70}"
di as res "Subgroup analysis by climate zone (by(hot))"
di as txt "{hline 70}"

xtbchpanel y temp, difference mavars(temp) ma(30 40) lags(1 4) by(hot) cce reps(50) nodots

di as txt _n "Done. If MG≈truth in step 2 and every table/graph rendered, the"
di as txt "command reproduces the paper's estimator behaviour."
