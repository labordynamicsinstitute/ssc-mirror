global workpath "/Users/lingyunzhou/Dropbox/2024_weakivtest2 Stata Package/weakivtest2"

cd "$workpath"
set seed 1234

cap log close demo
cap rm "demo.log"
log using "demo.log", name(demo)

loc h = 12
loc p = 4
loc state zlb

use data_Fiscal.dta, clear
tsset time

// cumulative variables
qui gen gdpsum = 0
qui gen gssum  = 0
forvalues hh = 1/`h' {
	qui replace gdpsum = gdpsum + F`hh'.gdp
	qui replace gssum  = gssum  + F`hh'.gs
}

// control variables
loc controls
forvalues pp = 1/`p' {
	qui gen gsl`pp'    = L`pp'.gs
	qui gen gdpl`pp'   = L`pp'.gdp
	qui gen newsl`pp' = L`pp'.news
	loc inexog `inexog' gsl`pp' gdpl`pp' newsl`pp'
}

// instrumental variables
loc exexog news gs

// endogenous variables
loc endog gssum

// Subsample analysis
qui gen `state'l1 = L.`state'
ivreg2 gdpsum `inexog' (`endog' = `exexog') if `state'l1 == 1, robust bw(auto)
weakivtest
ivreg2 gdpsum `inexog' (`endog' = `exexog') if `state'l1 == 0, robust bw(auto)
weakivtest

// Interaction
loc inexog1 `state'l1
loc exexog1
loc endog1
foreach vars in inexog exexog endog {
	foreach v in ``vars''  {
		qui gen `v'_`state'0 = `v' * (1 - `state'l1)
		qui gen `v'_`state'1 = `v' * `state'l1
		loc `vars'1 ``vars'1' `v'_`state'0 `v'_`state'1
	}
	loc `vars' ``vars'1'
}

// State dependent model
ivreg2 gdpsum `inexog' (`endog' = `exexog'), robust bw(auto)
weakivtest2, criterion(relative)
weakivtest2, criterion(absolute)

log close demo
