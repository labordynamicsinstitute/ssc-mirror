clear
set obs 1000
* kudos to readers who figure out where this number comes from
set seed 9732

scalar A = 0.3
scalar B = 0.6
scalar sigma = 0.1

generate i = int((_n - 1)/10) + 1
generate t = _n - int((_n - 1)/10)*10
generate g = 4
replace g = 6 if i > 50
* group 1 and 2 are special to illustrate weighting
replace g = 5 if inlist(i, 1, 2)

generate str treatment_group = "A" if mod(i, 2) == 0
replace treatment_group = "B" if mod(i, 2) == 1

generate treatmentA = (treatment_group == "A") & (t >= g)
generate treatmentB = (treatment_group == "B") & (t >= g)

generate y = sigma * invnormal(uniform()) + A * treatmentA + B * treatmentB
replace y = y + (B - A) if (g==5) & treatmentB

save "xt2treatments_testdata.dta", replace
