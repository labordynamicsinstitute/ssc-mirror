log using D:\spgmmxt.smcl , replace

clear all
sysuse spgmmxt.dta, clear

* (1) Spatial Panel Autoregressive Generalized Method of Moments
spgmmxt y  x1 x2 , nc(7) wmfile(SPWxt) gmm(1) mfx(lin) test
spgmmxt y  x1 x2 , nc(7) wmfile(SPWxt) gmm(2) mfx(lin) test
spgmmxt y  x1 x2 , nc(7) wmfile(SPWxt) gmm(3) mfx(lin) test
spgmmxt y  x1 x2 , nc(7) wmfile(SPWxt) gmm(1) mfx(log) test tolog
spgmmxt y  x1 x2 , nc(7) wmfile(SPWxt) gmm(2) mfx(log) test tolog
spgmmxt y  x1 x2 , nc(7) wmfile(SPWxt) gmm(3) mfx(log) test tolog

* (2) Tobit Spatial Panel Autoregressive Generalized Method of Moments
spgmmxt ys x1 x2 , nc(7) wmfile(SPWxt) gmm(1) mfx(lin) test tobit ll(0)
spgmmxt ys x1 x2 , nc(7) wmfile(SPWxt) gmm(2) mfx(lin) test tobit ll(3)
spgmmxt ys x1 x2 , nc(7) wmfile(SPWxt) gmm(3) mfx(lin) test tobit ll(0)
spgmmxt ys x1 x2 , nc(7) wmfile(SPWxt) gmm(3) mfx(lin) test tobit ll(3)

* (3) Spatial Panel Autoregressive Generalized Method of Moments (Cont.)
* This example is taken from Prucha data about Spatial Panel Regression.
* More details can be found in:
* http://econweb.umd.edu/~prucha/Research_Prog3.htm
* Results of (spgmmxt) with gmm(3) option is identical to:
* http://econweb.umd.edu/~prucha/STATPROG/PANOLS/PROGRAM3(L3).log

clear all
sysuse spgmmxt1.dta, clear
spgmmxt y x1 , wmfile(SPWxt1) nc(100) gmm(1) stand
spgmmxt y x1 , wmfile(SPWxt1) nc(100) gmm(2) stand
spgmmxt y x1 , wmfile(SPWxt1) nc(100) gmm(3) stand

log close

