log using D:\spregsem.smcl , replace

clear all
sysuse spregsem.dta, clear

* (1) MLE Spatial Error Normal Regression Model
spregsem y x1 x2 , wmfile(SPWcs) mfx(lin) test
spregsem y x1 x2 , wmfile(SPWcs) mfx(lin) test
spregsem y x1 x2 , wmfile(SPWcs) mfx(log) test tolog
spregsem y x1 x2 , wmfile(SPWcs) predict(Yh) resid(Ue)

* (2) MLE Spatial Error Exponential Regression Model
spregsem y x1 x2 , wmfile(SPWcs) mfx(lin) test dist(exp)

* (3) MLE Spatial Error Weibull Regression Model
spregsem y x1 x2 , wmfile(SPWcs) mfx(lin) test dist(weib)

* (4) Weighted MLE Spatial Error Regression Model
spregsem y x1 x2  [weight = x1], wmfile(SPWcs) mfx(lin) test
spregsem y x1 x2 [aweight = x1], wmfile(SPWcs) mfx(lin) test

* (5) MLE Spatial Error Tobit - Truncated Dependent Variable (ys)
spregsem ys x1 x2, wmfile(SPWcs) mfx(lin) test tobit ll(0)
spregsem ys x1 x2, wmfile(SPWcs) mfx(lin) test tobit ll(3)

log close
