log using D:\spregsdmxt.smcl , replace

clear all
sysuse spregsdmxt.dta, clear

* (1) MLE Spatial Durbin Panel Normal Regression Model
spregsdmxt y x1 x2 , nc(7) wmfile(SPWxt) mfx(lin) test
spregsdmxt y x1 x2 , nc(7) wmfile(SPWxt) mfx(lin) test
spregsdmxt y x1 x2 , nc(7) wmfile(SPWxt) mfx(log) test tolog
spregsdmxt y x1 x2 , nc(7) wmfile(SPWxt) predict(Yh) resid(Ue)
spregsdmxt y x1 x2       , nc(7) wmfile(SPWxt) mfx(lin) test aux(x3 x4)
spregsdmxt y x1 x2 x3 x4 , nc(7) wmfile(SPWxt) mfx(lin) test

* (2) MLE Spatial Durbin Panel Exponential Regression Model
spregsdmxt y x1 x2 , nc(7) wmfile(SPWxt) dist(exp) mfx(lin) test

* (3) MLE Spatial Durbin Panel Weibull Regression Model
spregsdmxt y x1 x2 , nc(7) wmfile(SPWxt) dist(weib) mfx(lin) test

* (4) MLE Weighted Spatial Durbin Panel Regression Model
spregsdmxt y x1 x2 [weight = x1] , nc(7) wmfile(SPWxt) mfx(lin) test
spregsdmxt y x1 x2 [aweight = x1] , nc(7) wmfile(SPWxt) mfx(lin) test

* (5) MLE Spatial Durbin Panel Tobit - Truncated Dependent Variable (ys)
spregsdmxt ys x1 x2, nc(7) wmfile(SPWxt) mfx(lin) test tobit ll(0)
spregsdmxt ys x1 x2, nc(7) wmfile(SPWxt) mfx(lin) test tobit ll(3)

* (6) MLE Spatial Durbin Panel Multiplicative Heteroscedasticity
spregsdmxt y x1 x2 , nc(7) wmfile(SPWxt) mfx(lin) test mhet(x2)

log close
