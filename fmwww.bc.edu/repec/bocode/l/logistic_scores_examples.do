sysuse auto, clear

logistic_scores rep78, symmetric gen(lgstc_s)

* another way to do it 
local text : variable label rep78
contract rep78, nomiss 
logistic_scores rep78 [fw=_freq], gen(lgstc)

gen cufreq = sum(_freq) 
gen cuprob = cufreq / cufreq[_N]
gen X = logit(cuprob)
set obs 1000
range x -6 6
gen density = exp(x) / (1 + exp(x))^2
gen where = -0.007

foreach y in 0.05 0.1 0.15 0.2 0.25 {
	local ylabel `ylabel' `y' "`y'"
}

twoway mspline density x, color(black) lw(thick) bands(200) ///
|| area density x if x < X[1], color(red*0.8) ///
|| area density x if inrange(x, X[1], X[2]), color(red*0.4) ///
|| area density x if inrange(x, X[2], X[3]), color(white) ///
|| area density x if inrange(x, X[3], X[4]), color(blue*0.4) ///
|| area density x if x > X[4], color(blue*0.8) ///
|| scatter where lgstc, ms(T) msize(large) mc(black) ///
mlabel(rep78) mlabpos(6) mlabcolor(black) mlabsize(medium) /// 
|| scatteri 0 -6 0 6, recast(line) lcolor(black) ysc(r(-0.025, .)) /// 
ytitle(density) yla(0 `ylabel' ) ///
xtitle(logistic scores) xla(-6/6) legend(off) ///
subtitle("`text'", place(left)) ///
note("cumulative probabilities define slices;" "centres of gravity define scores") ///
name(G1, replace)

* Mosteller and Tukey 1977 p.106 
clear 
set obs 5
gen MT106 = _n 
label def MT106 1 A 2 B 3 C 4 D 5 E 
label val MT106 MT106 
decode MT106, gen(letters)
gen freq = real(word("127 497 3243 231 74", MT106))
logistic_scores MT106 [fw=freq], gen(lgstc_MT)

gen cufreq = sum(freq) 
gen cuprob = cufreq / cufreq[_N]
gen X = logit(cuprob)

set obs 1000
range x -6 6
gen density = exp(x) / (1 + exp(x))^2
gen where = -0.007

foreach y in 0.05 0.1 0.15 0.2 0.25 {
	local ylabel `ylabel' `y' "`y'"
}

twoway mspline density x, color(black) lw(thick) bands(200) ///
|| area density x if x < X[1], color(red*0.8) ///
|| area density x if inrange(x, X[1], X[2]), color(red*0.4) ///
|| area density x if inrange(x, X[2], X[3]), color(white) ///
|| area density x if inrange(x, X[3], X[4]), color(blue*0.4) ///
|| area density x if x > X[4], color(blue*0.8) ///
|| scatter where lgstc_MT, ms(T) msize(large) mc(black) ///
mlabel(letters) mlabpos(6) mlabcolor(black) mlabsize(medium) /// 
|| scatteri 0 -6 0 6, recast(line) lcolor(black) ysc(r(-0.025, .)) /// 
ytitle(density) yla(0 `ylabel' ) ///
xtitle(logistic scores) xla(-6/6) legend(off) ///
subtitle("Mosteller and Tukey 1977 p.106", place(left)) ///
note("cumulative probabilities define slices;" "centres of gravity define scores") ///
name(G2, replace)

* Evans and Cox 1995; Evans 2015 
clear 
set obs 5
gen grade = _n 
* reverses 1995 order 
label def grade 1 poor 2 marginal 3 definite 4 "well-defined" 5 classic
label val grade grade 
decode grade, gen(words)
gen freq = real(word("35 36 44 31 11", grade))
logistic_scores grade [fw=freq], gen(lgstc_grade)

gen cufreq = sum(freq) 
gen cuprob = cufreq / cufreq[_N]
gen X = logit(cuprob)

set obs 1000
range x -6 6
gen density = exp(x) / (1 + exp(x))^2
gen where = -0.007

foreach y in 0.05 0.1 0.15 0.2 0.25 {
	local ylabel `ylabel' `y' "`y'"
}

twoway mspline density x, color(black) lw(thick) bands(200) ///
|| area density x if x < X[1], color(red*0.8) ///
|| area density x if inrange(x, X[1], X[2]), color(red*0.4) ///
|| area density x if inrange(x, X[2], X[3]), color(white) ///
|| area density x if inrange(x, X[3], X[4]), color(blue*0.4) ///
|| area density x if x > X[4], color(blue*0.8) ///
|| scatter where lgstc_grade, ms(T) msize(large) mc(black) ///
mlabel(words) mlabpos(6) mlabcolor(black) mlabsize(small) /// 
|| scatteri 0 -6 0 6, recast(line) lcolor(black) ysc(r(-0.025, .)) /// 
ytitle(density) yla(0 `ylabel' ) ///
xtitle(logistic scores) xla(-6/6) legend(off) ///
subtitle("Lake District cirques", place(left)) ///
note("cumulative probabilities define slices;" "centres of gravity define scores") ///
name(G3, replace)

