** Main_Implement.do
** This code is for implementation of the GC-robust test for a VAR

*cd ""

capture clear
set more off

* import data
import excel GCdata.xlsx, sheet(SW2001) firstrow clear

* time-series settings
generate year = int(pdate)
generate quarter = (pdate - int(pdate))*4 + 1 
generate tq = yq(year, quarter)
format tq %tq
tsset tq

* import p-value table
mata:
mata clear

mata matuse pvtable,replace
st_matrix("r(pvap0opt)",pvap0opt)
st_matrix("r(pvapiopt)",pvapiopt)
st_matrix("r(pvnybopt)",pvnybopt)
st_matrix("r(pvqlropt)",pvqlropt)

end

mat pvap0opt = r(pvap0opt)
mat pvapiopt = r(pvapiopt)
mat pvnybopt = r(pvnybopt)
mat pvqlropt = r(pvqlropt)

* run gcrobust test for a VAR
gcrobustvar pi u R, pos(1,2) lags(1/4)

* save graph
*graph save gcrobustvar_pi_u, asis replace


