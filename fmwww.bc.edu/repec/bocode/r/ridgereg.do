log using c:\ridgereg.smcl , replace

* (1) Example of Ridge regression models,
*     is decribed in: [Judge, et al(1988, p.882)], and also Theil R2 Multicollinearity
*     Effect in: [Judge, et al(1988, p.872)], for Klein-Goldberger data.
clear all
sysuse ridgereg1.dta, clear
ridgereg y x1 x2 x3 , model(orr) kr(0.5) mfx(lin) lmcol diag
ridgereg y x1 x2 x3 , model(orr) kr(0.5) mfx(lin) weights(x) wvar(x1)
ridgereg y x1 x2 x3 , model(grr1) mfx(lin)
ridgereg y x1 x2 x3 , model(grr2) mfx(lin)
ridgereg y x1 x2 x3 , model(grr3) mfx(lin)

* (2) Example of Gleason-Staelin, and Heo Multicollinearity Ranges,
*     is decribed in: [Rencher(1998, pp. 20-22)].
clear all
sysuse ridgereg2.dta, clear
ridgereg y x1 x2 x3 x4 x5 , model(orr) lmcol

* (3) Example of Farrar-Glauber Multicollinearity Chi2, F, t Tests
*     is decribed in:[Evagelia(2011, chap.2, p.23)].
clear all
sysuse ridgereg3.dta, clear
ridgereg y x1 x2 x3 x4 x5 x6 , model(orr) lmcol

log close

