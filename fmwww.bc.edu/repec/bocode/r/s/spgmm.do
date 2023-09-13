log using D:\spgmm.smcl , replace

clear all
sysuse spgmm.dta, clear

* (1) Spatial Autoregressive Generalized Method of Moments (SPGMM)
 spgmm y  x1 x2 , wmfile(SPWcs) mfx(lin) test
 spgmm y  x1 x2 , wmfile(SPWcs) mfx(log) tolog test

* (2) Tobit Spatial Autoregressive Generalized Method of Moments (SPGMM)
 spgmm ys x1 x2 , wmfile(SPWcs) mfx(lin) test tobit ll(0)
 spgmm ys x1 x2 , wmfile(SPWcs) mfx(lin) test tobit ll(3)
 spgmm ys x1 x2 , wmfile(SPWcs) mfx(log) test tobit ll(3) tolog

* (3) Spatial Autoregressive Generalized Method of Moments (SPGMM) (Cont.)
* This example is taken from Prucha data about:
* Generalized Moments Estimator for the Autoregressive Parameter in a Spatial Model  
* More details can be found in:
* http://econweb.umd.edu/~prucha/Research_Prog1.htm
* Results of model(spgmm) is identical to:
* http://econweb.umd.edu/~prucha/STATPROG/OLS/PROGRAM1.log

clear all
sysuse spgmm1.dta , clear
spgmm y x1 , wmfile(SPWcs1)

log close
