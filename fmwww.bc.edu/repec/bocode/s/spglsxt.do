log using c:\spglsxt.smcl , replace

clear all
sysuse spglsxt.dta, clear

* (1) Spatial Panel Autoregressive Generalized Least Squares Regression
spglsxt y  x1 x2 , nc(7) wmfile(SPWxt) gmm(1) mfx(lin) test
spglsxt y  x1 x2 , nc(7) wmfile(SPWxt) gmm(1) mfx(log) test tolog
spglsxt y  x1 x2 , nc(7) wmfile(SPWxt) gmm(2) mfx(lin) test
spglsxt y  x1 x2 , nc(7) wmfile(SPWxt) gmm(3) mfx(lin) test

* (2) Spatial Panel Autoregressive Generalized Least Squares Regression (Cont.)
* This example is taken from Prucha data about Spatial Panel Regression.
* More details can be found in:
* http://econweb.umd.edu/~prucha/Research_Prog3.htm
* Results of (spglsxt) with gmm(3) option is identical to:
* http://econweb.umd.edu/~prucha/STATPROG/PANOLS/PROGRAM3(L3).log

clear all
sysuse spglsxt1.dta, clear
spglsxt y x1 , wmfile(SPWxt1) nc(100) gmm(1) stand
spglsxt y x1 , wmfile(SPWxt1) nc(100) gmm(2) stand
spglsxt y x1 , wmfile(SPWxt1) nc(100) gmm(3) stand

log close
