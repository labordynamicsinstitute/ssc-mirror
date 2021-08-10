 log using "D:\dlagif.smcl", replace
 clear all
 sysuse dlagif.dta , clear

* (1) Ordinary Least Squares (OLS)
 dlagif y x z , model(ols) mfx(lin) test
 dlagif y x z , model(ols) mfx(log) test tolog
 dlagif y x z , model(ols) lag(1) diag
 dlagif y x z , model(ols) lag(2) diag
 dlagif y x z , model(ols) lag(3) diag

* (2) Autoregressive Least Squares (ALS)
 dlagif y x z , model(als) mfx(lin) test
 dlagif y x z , model(als) mfx(lin) test ar(2)
 dlagif y x z , model(als) mfx(log) test tolog
 dlagif y x z , model(als) mfx(lin) test twostep

* (3) Autoregressive Conditional Heteroskedasticity (ARCH)
 dlagif y x z , model(arch) mfx(lin) test
 dlagif y x z , model(arch) mfx(lin) test ar(2)
 dlagif y x z , model(arch) mfx(log) test tolog

* (4) Box-Cox Regression Model (Box-Cox)
 dlagif y x z , model(bcox) mfx(lin) test

* (5) Generalized Least Squares (GLS)
 dlagif y x z , model(gls) wvar(x) mfx(lin) test
 dlagif y x z , model(gls) wvar(x) mfx(log) test tolog

* (6) Quantile Regression (QREG)
 dlagif y x z , model(qreg) mfx(lin) test
 dlagif y x z , model(qreg) mfx(log) test tolog

* (7) Robust Regression (RREG)
 dlagif y x z , model(qreg) mfx(lin) test
 dlagif y x z , model(qreg) mfx(log) test tolog

* (8) Generalized Method of Moments (GMM)
* White:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(white)
* Bartlett:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(bart)
* Cragg:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(crag)
* Daniell:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(dan)
* Horn-Duncan:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(hdun)
* Hinkley:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(hink)
* Jackknife:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(jack)
* Newey-West:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(nwest)
* Parzen:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(parzen)
* Quadratic Spectral:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(quad)
* Tent:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(tent)
* Truncated:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(trunc)
* Tukey:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(tukey)
* Tukey-Hamming:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(tukeym)
* Tukey-Hanning:
 dlagif y x z , mfx(lin) test model(gmm) hetcov(tukeyn)

* (9) Weighted OLS & GMM Regression
 dlagif y x z , mfx(lin) test model(ols) weights(yh)
 dlagif y x z , mfx(lin) test model(ols) weights(yh2)
 dlagif y x z , mfx(lin) test model(ols) weights(abse)
 dlagif y x z , mfx(lin) test model(ols) weights(e2)
 dlagif y x z , mfx(lin) test model(ols) weights(x) wvar(x)
 dlagif y x z , mfx(lin) test model(ols) weights(xi) wvar(x)
 dlagif y x z , mfx(lin) test model(ols) weights(x2) wvar(x)
 dlagif y x z , mfx(lin) test model(ols) weights(xi2) wvar(x)

 dlagif y x z , mfx(lin) test model(gmm) hetcov(white) weights(yh)
 dlagif y x z , mfx(lin) test model(gmm) hetcov(white) weights(x) wvar(x)

* (10) Ridge Regression
 dlagif y x z , mfx(lin) test model(ols) ridge(orr) kr(0.5)
 dlagif y x z , mfx(lin) test model(ols) ridge(orr) kr(0.5) weights(x) wvar(x)
 dlagif y x z , mfx(lin) test model(ols) ridge(grr1)
 dlagif y x z , mfx(lin) test model(ols) ridge(grr2)
 dlagif y x z , mfx(lin) test model(ols) ridge(grr3)

 dlagif y x z , mfx(lin) test model(gmm) hetcov(white) ridge(orr) kr(0.5)
 dlagif y x z , mfx(lin) test model(gmm) hetcov(white) ridge(orr) kr(0.5) weights(x) wvar(x)
 dlagif y x z , mfx(lin) test model(gmm) hetcov(white) ridge(grr1)
 dlagif y x z , mfx(lin) test model(gmm) hetcov(white) ridge(grr2)
 dlagif y x z , mfx(lin) test model(gmm) hetcov(white) ridge(grr3)

 log close
