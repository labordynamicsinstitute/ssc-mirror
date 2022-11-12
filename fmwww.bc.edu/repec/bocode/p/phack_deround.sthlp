{smcl}

{title:Title}

phack_deround - A module to deround coefficients and standard errors for meta-analysis following Kranz and Putz (2022) and Brodeur et al. (2020)

{title:Requirements}

No dependencies.

{title:Contact Information}

Please direct any inquiries to ncook@wlu.ca

{title:Syntax}

{cmdab:phack_deround} coef_var se_var [{cmd:,}{it:options}]

options		description

zcrit()		The statistical threshold in question (expressed as abs(z)).
bunch()		The integer value where z-bunching occurs (expressed as abs(z)).


{title:Description}
		
{p}
{opt phack_deround} generates 4 variables useful for meta-analysis. To do this, the command accepts the coefficients and standard errors of a meta-analysis dataset (one coefficient and one standard error per observation). The command will then generate (1) the standard error's significand and generate (2) a variable which identifies the observations that should be kept according to Kranz and Putz (2022). The command will also apply the derounding applied in Brodeur et al. (2020) (which assumes that the missing-from-publication coefficient and standard error decimals are distributed uniformly) and generate (3) a smoothed coefficient and (4) a smoothed standard error value.

{p}

{title:Examples}

Example 1: using simulated data

clear
set more off
set obs 200000
set seed 1008

gen decimals_reported = 1+ceil(runiform()*2) 	// number of decimals_reported in paper
gen values_above_1 = runiform()*2			// adjust some estimates to be above 1 	

gen true_coef = runiform()
replace true_coef = true_coef + 1 if values_above_1>1  

gen true_se = runiform()
replace true_se = true_se + 1 if values_above_1>1  

tostring true_coef, gen(string_coef) force
tostring true_se, gen(string_se) force

replace string_coef = substr(string_coef,1,decimals_reported+1)  
replace string_se = substr(string_se,1,decimals_reported+1)  

// Explicit Illustrations of Significand Calculation

replace string_se = "7300" 		in 1 // 73
replace string_se = "0.065" 		in 2 // 65
replace string_se = "3020.40" 		in 3 // 302040
replace string_se = "8002" 		in 4 // 8002
replace string_se = "0.020"		in 5 // 20
replace string_se = "0.02"		in 6 // 2
replace string_se = "-8002"		in 7 // 2

phack_deround string_coef string_se 

Example 2: 

phack_deround string_coef string_se, bunch(3) zcrit(2.58)

 
