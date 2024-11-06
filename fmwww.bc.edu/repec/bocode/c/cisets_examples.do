* one example requires myaxis from Stata Journal 
* one example requires qplot from Stata Journal 
* in Stata <18 use a different scheme 

sysuse auto, clear 

cisets mean mpg, over(rep78) saving(foo, replace)
d using foo 

cisets mean mpg price weight, saving(foo, replace)
d using foo 

cisets prop foreign, over(rep78) jeffreys saving(foo, replace)
d using foo 

cisets prop foreign, jeffreys saving(foo, replace)
d using foo 

cisets var mpg, over(rep78) saving(foo, replace)
d using foo 

cisets var mpg price weight, saving(foo, replace)
d using foo 

cisets gmean mpg, over(rep78) saving(foo, replace)
d using foo 

cisets gmean mpg price weight, saving(foo, replace)
d using foo 

cisets hmean mpg, over(rep78) saving(foo, replace)
d using foo 

cisets hmean mpg price weight, saving(foo, replace)
d using foo 

cisets centile mpg, over(rep78) saving(foo, replace)
d using foo 

cisets centile mpg price weight, saving(foo, replace)
d using foo 

cisets centile mpg price weight, centile(75) saving(foo, replace)
d using foo 

set scheme stcolor 

cisets centile mpg, over(rep78) total saving(foo, replace)

u foo, clear

replace statname = "median"

twoway rspike ub lb group || scatter point group, pstyle(p1) msize(medlarge) ms(D) xtitle("`=gvarlabel'") xla(1/6, valuelabel) legend(off) ytitle("`=varlabel'") subtitle("`=statname's: `=level'% confidence intervals", place(w)) name(CI1, replace)

twoway rspike ub lb group, horizontal || scatter group point, pstyle(p1) msize(medlarge) ms(D) ytitle("`=gvarlabel'") yla(1/6, valuelabel) legend(off) xtitle("`=varlabel'") subtitle("`=statname's: `=level'% confidence intervals", place(w)) ysc(reverse) xsc(alt) ysc(r(0.8 .)) name(CI2, replace)

su ub, meanonly
local ubmax = r(max)
su lb, meanonly 
local lbmin = r(min)
 
gen where = `lbmin' - (`ubmax' - `lbmin') / 10 
gen show_n = ("{it:n} = ") + strofreal(n)

twoway rspike ub lb group || scatter where group, ms(none) mla(show_n) mlabpos(0) mlabc(black) mlabsize(medium) ///
|| scatter point group, pstyle(p1) msize(medlarge)  ms(D) xtitle("`=gvarlabel'")   ///
xla(1/6, valuelabel) xsc(r(0.5, 6.5)) legend(off) ytitle("`=varlabel'") subtitle("`=statname's: `=level'% confidence intervals", place(w)) name(CI3, replace)

twoway rbar ub lb group, lcolor(stc1) fcolor(none) barw(0.2) ///
|| scatter where group, ms(none) mla(show_n) mlabpos(0) mlabc(black) mlabsize(medium) ///
|| scatter point group, pstyle(p1) msize(medlarge)  ms(D) xtitle("`=gvarlabel'")   ///
xla(1/6, valuelabel) xsc(r(0.5, 6.5)) legend(off) ytitle("`=varlabel'") subtitle("`=statname's: `=level'% confidence intervals", place(w)) name(CI4, replace)

webuse citytemp, clear
cisets mean heatdd, over(division) saving(foo, replace)

u foo
myaxis group2=group, sort(mean point)
set scheme stcolor
twoway rspike ub lb group2 || scatter point group2, pstyle(p1) xla(1/9, valuelabel tlc(none)) ytitle(`=varlabel' (day {&degree}F)) subtitle("`=statname's: `=level'% confidence intervals", place(w)) legend(off) xsc(r(0.8 9.2)) name(CI5, replace)

sysuse auto, clear

cisets gmean price, over(foreign) saving(foo, replace)

clonevar origgvar=foreign

merge m:1 origgvar using foo

gen where = 1

qplot price, ms(O) by(foreign, legend(off) note(95% confidence intervals for geometric means)) ///
xla(0 0.25 "0.25" 0.5 "0.5" 0.75 "0.75" 1) ///
ysc(log) yla(3000(2000)15000) ytitle(Price (USD)) xtitle(Fraction of data) ///
addplot(rbar ub lb where, barw(0.08) fcolor(none) pstyle(p2) ///
|| scatter point where, ms(D) msize(medlarge) pstyle(p2)) name(CI6, replace)




