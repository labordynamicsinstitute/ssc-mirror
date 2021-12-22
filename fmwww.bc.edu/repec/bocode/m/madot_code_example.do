*************************************************************
**** plot for dichotomous outcomes using defualt setting ****
*************************************************************

use data_madot_dichotomous_default, clear

gen order = _n

gen prop1 = trt_n/trt_N
gen prop2 = ctrl_n/ctrl_N
 
 *** generating variables for text columns ****
tostring trt_n, gen(trt_n_S)
tostring trt_N, gen(trt_N_S)
tostring ctrl_n, gen(ctrl_n_S)
tostring ctrl_N, gen(ctrl_N_S)
gen trt_n_N = trt_n_S + "/" + trt_N_S
gen ctrl_n_N = ctrl_n_S + "/" + ctrl_N_S
gen sIsquared = string(100 * Isquared, "%8.0f") + "%"
gen sRR = string(RR, "%8.2f") + " (" + string(cil, "%8.2f") + ", " + string(ciu, "%8.2f") + ")"

*** plot ****
madot, outcome(Outcome) dot1(prop1) dot2(prop2) poolest(RR) n(order) cil(cil) ciu(ciu) ///
textcol1(sRR) textcol2(trt_n_N) textcol3(ctrl_n_N) textcol4(NoofTrials) textcol5(sIsquared) textcol6(SOE)


****************************************************************
**** plot for dichotomous outcomes using cuotomized setting ****
****************************************************************

use data_madot_dichotomous_costomized, clear

gen order = _n

gen prop1 = trt_n/trt_N
gen prop2 = ctrl_n/ctrl_N
 
 *** generating variables for text columns ****
tostring trt_n, gen(trt_n_S)
tostring trt_N, gen(trt_N_S)
tostring ctrl_n, gen(ctrl_n_S)
tostring ctrl_N, gen(ctrl_N_S)
gen trt_n_N = trt_n_S + "/" + trt_N_S
gen ctrl_n_N = ctrl_n_S + "/" + ctrl_N_S
gen sIsquared = string(100 * Isquared, "%8.0f") + "%"
gen sRR = string(RR, "%8.2f") + " (" + string(cil, "%8.2f") + ", " + string(ciu, "%8.2f") + ")"

*** plot ****
madot, outcome(Outcome) dot1(prop1) dot2(prop2) poolest(RR) n(order) cil(cil) ciu(ciu) ///
textcol1(sRR) textcol2(trt_n_N) textcol3(ctrl_n_N) textcol4(NoofTrials) textcol5(sIsquared) textcol6(SOE) ///
legendleft1("TRT group name") textcol2name("TRT group n/N") rightxlabel(0.8 1 2 4 900) /// /*change ticker markders*/
textcol1pos(10) textcol2pos(35) textcol3pos(80) textcol4pos(150) textcol5pos(250) textcol6pos(500) /*adjust positions of text columns*/


****************************************************************
**** plot for continuous outcomes using cuotomized setting ****
****************************************************************
use data_madot_continuous, clear

gen order = _n

*** generating variables for text columns ****
gen sIsquared = string(100 * Isquared, "%8.0f") + "%"
gen sMD = string(MD, "%8.2f") + " (" + string(cil, "%8.2f") + ", " + string(ciu, "%8.2f") + ")"

gen sMD2 = string(MD, "%8.2f") + "(" + string(cil, "%8.2f") + ", " + string(ciu, "%8.2f") + ")"

*** plot ****
madot, outcome(Outcome) dot1(trt_bl_mean)  dot2(ctrl_bl_mean) poolest(MD) n(order) cil(cil) ciu(ciu) ///
textcol1(sMD2) textcol2(trt_N) textcol3(ctrl_N) textcol4(NoofTrials) textcol5(sIsquared) textcol6(SOE) ///
logoff(1) textcolposy(0.5) /// /*logoff(1) to turn off log-scale for x axis in right plot*/
textcol2name("Trt (N)") textcol3name("Ctrl (N)") rightxlabel( -8 -6 -4 -2 0 2 19) /// /* set right x axis ticks*/
textcol1pos(5) textcol2pos(8.7) textcol3pos(11) textcol4pos(13.5) textcol5pos(15) textcol6pos(17) /// /*adjusting position of text columns*/
graphheight(3) graphwidth(8.5) iscale(0.8) /*set graph height, width and text size */	
