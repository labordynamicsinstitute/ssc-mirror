*! bootur_example.do  -- worked examples for the bootur package
*! Author: Merwan Roudane (merwanroudane920@gmail.com)
*  Run after installing bootur.  Uses the packaged MacroTS.dta.
clear all
set more off

* If installed from SSC/net, retrieve the ancillary data with:  net get bootur
* Here we assume MacroTS.dta is on the current path.
capture use MacroTS, clear
if _rc {
    di as error "MacroTS.dta not found on the path; run -net get bootur- first"
    exit 601
}

di as text _n "{hline 70}" _n "1. Standard ADF test (asymptotic MacKinnon p-value)" _n "{hline 70}"
bootur adf GDP_BE, deterministics(trend)
bootur adf GDP_BE, deterministics(trend) onestep

di as text _n "{hline 70}" _n "2. Bootstrap union / ADF test on a single series" _n "{hline 70}"
set seed 202607
bootur union GDP_BE, bootstrap(AWB) b(999)
bootur bootadf GDP_BE, deterministics(trend) detrend(QD) bootstrap(MBB) b(999)

di as text _n "{hline 70}" _n "3. Bootstrap tests on several series (no correction)" _n "{hline 70}"
bootur ur GDP_BE GDP_DE GDP_FR GDP_NL GDP_UK, level(0.05) bootstrap(AWB) b(999)
matrix list r(indiv_stat)

di as text _n "{hline 70}" _n "4. False discovery rate control" _n "{hline 70}"
bootur fdr GDP_BE GDP_DE GDP_FR GDP_NL GDP_UK CONS_BE CONS_DE, level(0.10) b(999)

di as text _n "{hline 70}" _n "5. Sequential quantile test (two groups)" _n "{hline 70}"
bootur sqt GDP_BE GDP_DE GDP_FR GDP_NL GDP_UK, steps(0 0.5 1) b(999)

di as text _n "{hline 70}" _n "6. Panel group-mean unit root test" _n "{hline 70}"
bootur panel GDP_BE GDP_DE GDP_FR GDP_NL GDP_UK, b(999)

di as text _n "{hline 70}" _n "7. Order of integration + plot" _n "{hline 70}"
bootur order GDP_BE GDP_DE GDP_FR GDP_NL GDP_UK, method(ur) b(499)
matrix ord = r(order)
bootur plotorder ord, name(orders, replace)

di as text _n "{hline 70}" _n "8. Differencing and missing-value map" _n "{hline 70}"
bootur diff GDP_BE GDP_DE, orders(1 1) generate(d_)
summarize d_GDP_BE d_GDP_DE
bootur plotmiss GDP_NL HICP_BE UR_FR, name(missmap, replace)

di as text _n "bootur_example.do finished successfully."
