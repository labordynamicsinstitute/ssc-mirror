*examples for nonparmde and xvalols

*exmaple data
clear
set sortseed 84123342
set seed 208914301

set obs 100
gen n = rpoisson(20)
qui sum n
gen p = .5*(n-r(min))/(r(max)-r(min))+.25
gen Y_total = rbinomial(n,p)
gen X_total = rbinomial(n,p)
gen Z_total = rbinomial(n,p)
gen x_avg = X_total/n
gen y_avg = Y_total/n
egen cut=seq(), from(1) to(2)
summarize 





***************************************



nonparmde Y_total, mtreatment(50) mcontrol(50) avgclustersize(20.61)
nonparmde y_avg n, n(n) averages mtreatment(5) mcontrol(5) 

nonparmde Y_total X_total Z_total, mtreatment(50) mcontrol(50) kx(.2 .1) avgclustersize(20.61)

nonparmde Y_total X_total Z_total, mtreatment(50) mcontrol(50) avgclustersize(20.61)
nonparmde Y_total X_total Z_total, mtreatment(50) mcontrol(50) n(n)

nonparmde Y_total X_total Z_total n, mtreatment(50) mcontrol(50) n(n)

nonparmde Y_total X_total Z_total n, mtreatment(50) mcontrol(50) n(n) crossfold(cut)
disp `e(output1)'
disp `e(output2)'
disp `e(output3)'
matrix list e(crossfold_output)
nonparmde Y_total X_total n, mtreatment(50) mcontrol(50) n(n) crossfold(2)
matrix list e(crossfold_output)

*******

xvalols Y_total X_total, cutoff(50) 
disp `e(output1)'
matrix list e(crossfold_output)
