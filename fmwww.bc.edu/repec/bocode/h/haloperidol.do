* results as in paper 1
prog drop _all
set more off
use "haloperidol to test simplemetamiss.dta", clear

*local options xtitle(,size(large)) ytitle(,size(large)) xlabel(0.1, 1, 10, 100) force xsize(9) ysize(6) 
local options nograph

metamiss r1 f1 m1 r2 f2 m2, `options' fixed id(author) aca name(aca, replace) title(ACA) 

metamiss r1 f1 m1 r2 f2 m2, `options' fixed id(author) w4 ica0 name(ica0, replace) title(ICA-0)

metamiss r1 f1 m1 r2 f2 m2, `options' fixed id(author) w4 ica1 name(ica1, replace) title(ICA-1)

metamiss r1 f1 m1 r2 f2 m2, `options' fixed id(author) w4 icapc name(icapc, replace) title(ICA-pC)

metamiss r1 f1 m1 r2 f2 m2, `options' fixed id(author) w4 icape name(icape, replace) title(ICA-pE)

metamiss r1 f1 m1 r2 f2 m2, `options' fixed id(author) w4 icap name(icap, replace) title(ICA-p)

metamiss r1 f1 m1 r2 f2 m2, `options' fixed id(author) w4 ica0(df1 df2) ica1(ds1 ds2) icapc(dc1 dc2) icap(dg1 dg2) name(icar, replace) title(ICA-R)

metamiss r1 f1 m1 r2 f2 m2, `options' fixed id(author) w4 icab name(icab, replace) title(ICA-B)

metamiss r1 f1 m1 r2 f2 m2, `options' fixed id(author) w4 icaw name(icaw, replace) title(ICA-W)

metamiss r1 f1 m1 r2 f2 m2, `options' fixed id(author) w4 icaimor imor(2 2) name(icaimor22, replace) title(ICA-IMOR: IMORs 2, 2)

metamiss r1 f1 m1 r2 f2 m2, `options' fixed id(author) w4 icaimor imor(1/2 1/2) name(icaimorhalfhalf, replace) title(ICA-IMOR: IMORs 1/2, 1/2)

metamiss r1 f1 m1 r2 f2 m2, `options' fixed id(author) w4 sdlogimor(1) logimor(0) name(N01, replace) title("logimor ~ N(0,1)")

metamiss r1 f1 m1 r2 f2 m2, `options' fixed id(author) w4 sdlogimor(2) logimor(0) name(N04, replace) title("logimor ~ N(0,2^2)")

metamiss r1 f1 m1 r2 f2 m2, `options' fixed id(author) gamblehollis name(GH, replace) title(Gamble-Hollis)

/* NB metan bug: 
metan r1 f1 r2 f2, xsize(9) ysize(6) title("Gamble-Hollis") 
fails
metan r1 f1 r2 f2, title("Gamble-Hollis") 
metan r1 f1 r2 f2, xsize(9) ysize(6) title(Gamble-Hollis) 
*/
