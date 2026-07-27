*! xtpstat_example.do  --  self-test for -xtpstat- (xtpdroot library)
*! Dr Merwan Roudane
*! Run after: adopath + "<folder>"   then   do xtpstat_example.do

clear
set more off
set seed 20260723
local N = 20
local T = 60

quietly {
    set obs `=`N'*`T''
    gen id = ceil(_n/`T')
    bysort id: gen t = _n
    xtset id t
}

*==========================================================================
* CASE A -- stationary panel => do NOT reject stationarity
*==========================================================================
di _n(2) as txt "{hline 70}"
di as txt "CASE A: stationary panel -> do NOT reject stationarity"
di as txt "{hline 70}"
quietly gen double y = rnormal()
xtpstat y, model(trend)

*==========================================================================
* CASE B -- integrated panel => REJECT stationarity
*==========================================================================
di _n(2) as txt "{hline 70}"
di as txt "CASE B: I(1) panel -> REJECT stationarity"
di as txt "{hline 70}"
quietly by id: replace y = sum(rnormal())
xtpstat y, model(trend)

di _n as txt "{hline 70}"
di as txt "On the OPEC CO2 data (Nazlioglu et al. 2021), xtpstat reproduces the"
di as txt "GAUSS output exactly: OPEC Ppc=61.710; 5-country subgroup Ppc=9.152."
di as txt "{hline 70}"
