* 2004 examples, revised slightly 
sysuse auto, clear

ppplot connected mpg, by(foreign) name(mpg1, replace)
ppplot connected mpg, by(foreign) ref(0) name(mpg2, replace)
ppplot connected mpg, by(foreign) plot(function equality = x, clp(dash)) name(mpg3, replace)

foreach t in area bar connected dot dropline line scatter spike { 
ppplot `t' mpg, by(foreign) name(mpg`t', replace)
}

ppplot bar mpg, by(foreign) bartype(spanning) base(0) name(mpg4, replace)

* 2026 additions 
webuse lbw, clear 

* example code originally from Chen Samulsion
ppplot line bwt, by(race) plot(function equality=x, clp(dash)) name(gr123, replace)

ppplot line bwt if race==1 | race==2, by(race) plot(function equality=x, clp(dash)) name(gr12, replace)

* qplot 2.5.0 Stata Journal 26(3)
qplot bwt, by(race, row(1) compact) name(G1, replace)
egen mean = mean(bwt), by(race)
bysort race (bwt) : gen x = cond(_n == 1, 0, cond(_n == _N, 1, 0))
qplot bwt, by(race, row(1) compact note("lines show means") legend(off)) addplot(line mean x) xtitle(Fraction of data) name(G2, replace)

* pctilesets from Stata Journal 26(2)
pctilesets bwt, over(race) pctile(5 25 50 75 95) saving(pctiles, replace)
clonevar origgvar=race 
merge m:1 origgvar using pctiles
gen where = 1.1

qplot bwt , by(race, row(1) compact note("lines show means; diamonds show medians; boxes show quartiles; spikes to 5% and 95% points") legend(off)) xtitle(Fraction of data) addplot(line mean x || scatter p50 where, ms(Dh) msize(medlarge) pstyle(p2) || rbar p25 p75 where, barw(0.1) pstyle(p2) fcol(none) || rspike p75 p95 where, pstyle(p2) || rspike p25 p5 where, pstyle(p2))  name(G3, replace)


