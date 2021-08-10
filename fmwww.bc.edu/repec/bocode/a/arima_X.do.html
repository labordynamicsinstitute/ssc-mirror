* arima_X.do  10sep2004 CFBaum
use http://www.stata-press.com/data/r8/friedman2.dta, clear
* in Stata 8, could do
webuse friedman2, clear
arima pc92 L.pc92 L(0/1).m2 if tin(,1981q4)
* static (one-step-ahead) 20-quarter forecast
predict consump_st if tin(1982q1,1986q4)
* dynamic (recursive) 20-quarter forecast
predict consump_dyn if tin(1982q1,1986q4), dynamic(q(1982q1))
label var pc92 "Actual"
label var consump_st "one-step forecast"
label var consump_dyn "dynamic forecast"
* graphics could be produced in Stata 7 via tsgraph
tsline pc92 consump_st consump_dyn if tin(1982q1,1986q4), ///
 ti("Actual and Predicted Real Consumption")
graph display, xsize(4) ysize(3) scheme(s2mono)
