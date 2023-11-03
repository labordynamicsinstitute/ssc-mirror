/*
Testing script for artcat
IW
18may2023 add test of unnecessary zeroes
01jun2022 
	renamed test_consistency
	use new artbin
15jul2020 minor updates 
24nov2020 
	reflect change of default to ologit 
	add test of whitehead=NN
	add test of increase/decrease
9dec2020
	reflect change to best/worst
16dec2020
	reflect change to un/favourable
*/


cscript "Ian's testing of artcat" adofile artcat artbin
set type float

/* SETTING 1 */

* rr vs pe
artcat, pc(.2 .4 .6) rr(.5) power(.9) probtable cum noround unfavourable
local n1 = r(n_ologit_NA)

* format of pc
artcat, pc(.2, .4, .6) rr(.5) power(.9) probtable cum noround unfavourable
assert reldif(r(n_ologit_NA),`n1')<1E-6

artcat, pc(.2 .2 .2) rr(.5) power(.9) probtable  noround unfavourable
assert reldif(r(n_ologit_NA),`n1')<1E-6

* format of pe
artcat, pc(.2 .4 .6) pe(.1 .2 .3) power(.9) probtable cum noround unfavourable
assert reldif(r(n_ologit_NA),`n1')<1E-6

artcat, pc(.2 .2 .2) pe(.1 .1 .1) power(.9) probtable noround unfavourable
assert reldif(r(n_ologit_NA),`n1')<1E-6

* extra row
artcat, pc(.2 .2 .2 .4) pe(.1 .1 .1 .7) power(.9) probtable noround unfavourable
assert reldif(r(n_ologit_NA),`n1')<1E-6

* with zeroes
artcat, pc(0 .2 .2 .2 .4 0) pe(0 .1 .1 .1 .7 0) power(.9) probtable noround unfavourable
assert reldif(r(n_ologit_NA),`n1')<1E-6

* extra row and rr
artcat, pc(.2 .2 .2 .4) rr(.5) power(.9) probtable noround unfavourable
assert reldif(r(n_ologit_NA),`n1')<1E-6

* check it also works with type double (this one previously failed)
set type double
artcat, pc(.2 .2 .2 .4) pe(.1 .1 .1 .7) power(.9) probtable noround unfavourable
assert reldif(r(n_ologit_NA),`n1')<1E-6
set type float

* rr as expression
artcat, pc(.2 .4 .6) rr(1/2) power(.9) probtable cum noround unfavourable
assert reldif(r(n_ologit_NA),`n1')<1E-6

* C and E the other way round
artcat, pc(.1 .2 .3) rr(2) power(.9) cum noround
assert reldif(r(n_ologit_NA),`n1')<1E-6

* n to power to n
foreach method in NN NA AA {
	artcat, pc(.2 .4 .6) rr(.5) n(200) probtable cum ologit(`method') noround unfavourable
	local power = r(power)
	artcat, pc(.2 .4 .6) rr(.5) power(`power') probtable cum ologit(`method') noround unfavourable
	assert reldif(r(n),200)<1E-6
}

* affected by aratio
artcat, pc(.2 .4 .6) rr(.5) power(.9) probtable cum aratio(2 1) noround unfavourable
assert r(n_ologit_NA) > `n1'

* NI
artcat, pc(.2 .4 .6) rr(.5) margin(1) power(.9) probtable cum noround unfavourable
assert r(n_ologit_NA) == `n1'

artcat, pc(.2 .4 .6) rr(.5) margin(1.1) power(.9) probtable cum noround unfavourable
assert r(n_ologit_NA) < `n1'

* NI defaults to or(1)
artcat, pc(.2 .4 .6) rr(1) margin(1.5) power(.9) probtable cum noround unfavourable
local nNI = r(n)
artcat, pc(.2 .4 .6) margin(1.5) power(.9) probtable cum noround unfavourable
assert reldif(r(n),`nNI')<1E-6

* options
artcat, pc(.2 .4 .6) rr(.5) power(.9) probformat(%7.3f) format(%10.4f) alpha(0.025) ///
	onesid cum noround unf
assert r(n_ologit_NA) == `n1'

* rounding
artcat, pc(.2 .4 .6) rr(.5) power(.9) cum unfavourable
assert r(n_ologit_NA) == ceil(`n1')
assert r(n_ologit_NA) == ceil(r(n_ologit_NA))

* whitehead = NN
artcat, pc(.2 .4 .6) or(.5) power(.9) probtable cum noround whitehead unfavourable
local n2 = r(n)
artcat, pc(.2 .4 .6) or(.5) power(.9) probtable cum noround ologit(NN) unfavourable
assert reldif(r(n),`n2')<1E-6


/* SETTING 2 */

* or vs pe
artcat, pc(.4) or(2.25) power(.9) probtable cum noround favourable
local n1 = r(n)

artcat, pc(.4) pe(.6) power(.9) probtable cum noround fav
assert reldif(r(n),`n1')<1E-6

artbin, pr(0.4 0.6) power(.9)
local n0 = r(n)

artcat, pc(.4) pe(.6) power(.9) probtable ologit favourable
assert reldif(r(n_ologit_NN),`n0')<0.05

/* SETTING 3: FLU-IVIG */

artcat, pc(.018 .036 .156 .141 .39) or(1/1.77) power(.8) probtable ologit unfavourable
assert r(n_ologit_NN) == 320

* same the other way round, without and with last category
artcat, pc(.259 .390 .141 .156 .036) or(1.77) power(.8) probtable ologit fav
assert r(n_ologit_NN) == 320
artcat, pc(.259 .390 .141 .156 .036 .018) or(1.77) power(.8) probtable ologit favo
assert r(n_ologit_NN) == 320

* check error message if favourable is wrongly specified
cap noi artcat, pc(.018 .036 .156 .141 .39) or(1/1.77) power(.8) probtable ologit favourable
assert _rc==498

* check warning if unfavourable/favourable is not specified
artcat, pc(.018 .036 .156 .141 .39) or(1/1.77) power(.8) probtable ologit 

*** CONCLUSION: ARTCAT PASSED ALL TESTS ***

