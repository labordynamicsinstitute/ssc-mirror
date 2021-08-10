/*
	Version 7 version of mvis suite and brcaeximp.do
	PR 30sep2004
*/
set logtype text
cap log close
log using brcaeximp7.sto , replace
set more off
/*
	Create new dataset brcaeximp7.dta containing 5 imputations
	from brcaex.dta.
	Then analyse using micombine7.
*/
use brcaex, clear
mvis7 mx1 mx4a mx5e mx6 mhormon lnt _d using brcaeximp7, m(5) genmiss(m_) seed(101) replace

use brcaeximp7, clear

fracgen mx1 -2 -0.5
fracgen mx6 0.5

micombine7 stcox mx1_1 mx1_2 mx4a mx5e mx6_1 mhormon, nohr

log close
