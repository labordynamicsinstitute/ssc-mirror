// Command: phack_deround 
// Version: 1.0
// Date: 2022-11-09
// Author: Nikolai M Cook
// Description: A module to deround coefficients and standard errors for meta-analysis following Kranz and Putz (2022) and Brodeur et al. (2020)
// This module code comes with no warranties, but I welcome your inquiries at ncook@wlu.ca
// 
// References:
// Brodeur, A., Cook, N., & Heyes, A. (2020). Methods matter: P-hacking and publication bias in causal analysis in economics. American Economic Review, 110(11), 3634-60.
// Kranz, S., & Pütz, P. (2022). Methods matter: P-hacking and publication bias in causal analysis in economics: Comment. American Economic Review, 112(9), 3124-36.
//
// The KP Significand is the significant digits of the standard error, written as integers. The below examples are illustrations:
// 7300 has a significand of 73
// 0.065 has a significand of 65
// 3020.40 has a significand of 302040
// 8002 has a significand of 8002
// 0.020 has a significand of 20
// 0.02 has a significand of 2
// -8002 has a significand of 8002

capture program drop phack_deround

program phack_deround // define the command's call

version 11.0

syntax varlist(min=2 max=2) [, zcrit(real 1.96) bunch(integer 2)  ]

args _coef _se // first argument is coeff second argument is se

quietly {
	
gen kranz_putz_2022_sign = `_se'  
label var kranz_putz_2022_sign "KP Significand of S.E."

// convert to string variable if numeric
capture confirm string variable kranz_putz_2022_sign 
if _rc {
	tostring kranz_putz_2022_sign, force replace
}

// ensures there is at most one decimal place in the se's
assert length(kranz_putz_2022_sign) - length(subinstr(kranz_putz_2022_sign, ".", "", .)) < 2 // 

// identify and remove trailing zeros from se's without decimal points (from https://www.stata.com/support/faqs/data-management/removing-leading-or-trailing-zeros/)
while r(N) { 
replace kranz_putz_2022_sign = usubstr(kranz_putz_2022_sign, 1,length(kranz_putz_2022_sign)-1) if usubstr(kranz_putz_2022_sign, -1, 1) == "0" & strpos(kranz_putz_2022_sign,".")==0
count if usubstr(kranz_putz_2022_sign, -1, 1) == "0" & strpos(kranz_putz_2022_sign,".")==0
}

// now remove decimal and destring
replace kranz_putz_2022_sign = subinstr(kranz_putz_2022_sign,".","",.)
destring kranz_putz_2022_sign, replace
replace kranz_putz_2022_sign = abs(kranz_putz_2022_sign)

// generate kranz_putz_2022 variables
gen kranz_putz_2022_keep = 0
replace kranz_putz_2022_keep = 1 if kranz_putz_2022_sign >= (1+`zcrit')/(2*abs(`bunch'-`zcrit')) // keep if significand is above 37 (default), where 37 is from Putz and Kranz (2022 p.3127)

label var kranz_putz_2022_keep "=1 to keep KP derounding"


// brodeur et al 2020 AER (identical to brodeur et al 2016 AEJ:Applied) derounding

set seed 1156

gen _bch_coef = `_coef'
gen _bch_se = `_se'

capture confirm string variable _bch_coef
if _rc {
	tostring _bch_coef, force replace
	}
	
capture confirm string variable _bch_se
if _rc {
	tostring _bch_se, force replace
	}
	
capture drop _after_decimal_coef
egen _after_decimal_coef = ends(_bch_coef), punct(".") tail

capture drop _precision_coef
gen _precision_coef = length(_after_decimal_coef)

capture drop brodeur_et_al_2020_coef
destring _bch_coef, gen(brodeur_et_al_2020_coef) 
replace brodeur_et_al_2020_coef = brodeur_et_al_2020_coef+(uniform()-0.5)*10^(-1*_precision_coef)
label var brodeur_et_al_2020_coef "BCH smoothed Coefficient"

capture drop _after_decimal_se
egen _after_decimal_se = ends(_bch_se), punct(".") tail

capture drop _precision_se
gen _precision_se = length(_after_decimal_se)

capture drop brodeur_et_al_2020_se
destring _bch_se, gen(brodeur_et_al_2020_se) 
replace brodeur_et_al_2020_se = brodeur_et_al_2020_se+(uniform()-0.5)*10^(-1*_precision_se)
label var brodeur_et_al_2020_se "BCH smoothed S.E."

capture drop _after_decimal_coef
capture drop _after_decimal_se
capture drop _precision_coef
capture drop _precision_se
capture drop _bch_coef
capture drop _bch_se

}

di "Kranz & Putz (2022) derounding applied for bunching around z=" `bunch' " and z-critical of z=" `zcrit' " (Significand Threshold=" (1+`zcrit')/(2*abs(`bunch'-`zcrit')) ")."

end

phack_deround string_coef string_se 
