 clear all
 log using d:\almon1.smcl , replace
 sysuse almon1.dta , clear

* (1) Ordinary Least Squares (OLS)
 almon1 y x , model(ols) lag(3) pdl(2) mfx(lin)
 almon1 y x
 almon1 y x ,   model(ols) lag(3) pdl(0) end(0) mfx(lin)
 almon1 y x z , model(ols) lag(3) pdl(2) end(0) mfx(lin)
 almon1 y x z , model(ols) lag(4) pdl(3) end(0) mfx(lin)

 tsset t
 reg y l(0/3).x
 almon1 y x , model(ols) lag(3) pdl(0) end(0)

 almon1 y x , model(ols) lag(3) pdl(2) end(0)
 almon1 y x , model(ols) lag(3) pdl(2) end(1)
 almon1 y x , model(ols) lag(3) pdl(2) end(2)
 almon1 y x , model(ols) lag(3) pdl(2) end(3)
 almon1 y x , model(ols) lag(3) pdl(2) end(0) test mfx(lin)
 almon1 y x , model(ols) lag(3) pdl(2) end(0) test mfx(log) tolog
 almon1 y x , model(ols) lag(3) pdl(2) end(0) test mfx(lin) predict(Yh) resid(Ue)

* (2) Autoregressive Least Squares (ALS)
 almon1 y x , model(als) lag(3) pdl(2) end(0) test mfx(lin)
 almon1 y x , model(als) lag(3) pdl(2) end(0) test mfx(lin) order(1)
 almon1 y x , model(als) lag(3) pdl(2) end(0) test mfx(lin) order(2)

* (3) Generalized Least Squares (GLS)
 almon1 y x , model(gls) lag(3) pdl(2) wvar(x)
 almon1 y x , model(gls) lag(3) pdl(2) wvar(x) ominv

* (4) Autoregressive Conditional Heteroskedasticity (ARCH)
 almon1 y x , model(arch) lag(4) pdl(2) end(0) test mfx(lin) nolag
 almon1 y x , model(arch) lag(4) pdl(2) end(0) test mfx(lin) nolag order(1)
 almon1 y x , model(arch) lag(4) pdl(2) end(0) test mfx(lin) nolag order(2)

* Example from Damodar [2009, p. 651].
 clear all
 sysuse almon2.dta , clear
 almon1 y x , model(ols) lag(3) pdl(2) end(0)

* Example from Griffiths, Hill and Judge [1993, p. 687].
 clear all
 sysuse almon3.dta , clear
 almon1 y x , model(ols) lag(8) pdl(2) end(0)

 clear all
 sysuse almon1.dta , clear
 almon1 y x , model(ols) lag(3) pdl(2) end(0) test mfx(lin) predict(Yh) resid(Ue)

 log close

