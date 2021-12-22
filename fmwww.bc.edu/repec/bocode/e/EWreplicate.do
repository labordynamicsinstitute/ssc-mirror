* Usage examples for XTEWreg - Erickson-Whited linear cross-sectional
* regression for one mismeasured regressor and arbitrarily many perfectly
* measured regressors.
*
* Author: Robert Parham - send bug reports to robert.parham@simon.rochester.edu
*
* See help EWreg and help XTEWreg for full description of methods.
*
********************************************
** Replicate table 7 of EW2011 RFS

clear all
set memory 900m
set matsize 1000

use EW2011RFS

tsset gvkey fyear

* In levels
XTEWreg ik q cfk, meth(GMM4) bx(-0.1(0.006)0.5 0)
* Within transformation - fixed effects
XTEWreg ik q cfk, meth(GMM4) bx(-0.1(0.006)0.5 0) fe
