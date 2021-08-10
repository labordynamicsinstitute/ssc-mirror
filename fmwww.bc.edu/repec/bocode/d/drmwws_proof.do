* This code demonstrates that DRMMWS performs equally as well as IPWRA and AIPW when the outcome is correctly specified and the propensity score is misspecified 
* but outperforms these other DR estimators when the outcome and propensity score models are both misspecified (true effect is 1.0)


clear
set obs 2000


gen x = rnormal()
gen x2 = x^2
gen x3 = x^3

/* true treatment assignment mechanism */
gen z = rbinomial(1, invlogit(1 + .6*x + -.6*x2)) //severe non-linearity


/* generate misspecified pscore */
logit z x
predict pscore, pr

/* generate true non-linear outcome */
gen y = 6+ .5*x +.25*x2 -.125*x3 +rnormal(0,.25) if z==1
replace y = 5+ .5*x +.25*x2 -.125*x3 +rnormal(0,.25) if z==0

/* Compare doubly robust models under different types of misspecification */
* true treatment effect is 1.0

* true outcome model / misspecified propensity score model

** IPWRA
teffects ipwra (y x x2 x3) (z x), vce(bootstrap, reps(10))

** AIPW
teffects aipw (y x x2 x3) (z x), vce(bootstrap, reps(10))

** DRMMWS
drmmws y z, ovars(x x2 x3) pvars(x) nstrata(5) reps(10)

* misspecified outcome model / misspecified propensity score model*

** IPWRA
teffects ipwra (y x) (z x), vce(bootstrap, reps(10))

** AIPW
teffects aipw (y x) (z x), vce(bootstrap, reps(10))

** DRMMWS
drmmws y z, ovars(x) pvars(x) nstrata(5) reps(10)
