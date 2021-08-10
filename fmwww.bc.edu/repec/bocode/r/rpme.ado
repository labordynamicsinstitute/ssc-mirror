*! version 2.0.1 15jan2015
//cap prog drop rpme
program define rpme, nclass byable(recall) sortpreserve
version 12.0 
//set trace on 
// check
qui findfile _ggini.ado

if "`r(fn)'" == "" {
         di as txt "user-written package egen_inequal needs to be installed first;"
         di as txt "use -ssc install egen_inequal- to do that"
         exit 498
}

syntax varlist (min=3 max=3 numeric) [if] [in]  [, SAVing(string asis) ALPHA_min(real 2.0) PARETO_stat(string) BY(varlist)]
if "`pareto_stat'" == "" local pareto_stat "harmonic"
marksample touse, novarlist
if "`saving'" !=""{
 di "generated data will saved to `saving'"
}
di "alpha_min set to `alpha_min'"
di "pareto_stat set to `pareto_stat'"
// if "`by'"!=""{
//   di "by variable is `by'"
//   }
if "`pareto_stat'"!="median" & "`pareto_stat'"!="arithmetic" & "`pareto_stat'"!="geometric" & "`pareto_stat'"!="harmonic" {
     di as txt "Error in pareto_stat() argument. Possible values are median, arithmetic, geometric, harmonic."
     exit 498
}
if `alpha_min'<=0  {
     di as txt "Error in alpha_min() argument. alpha_min must be positive."
     exit 498
}

if `alpha_min'<=1 & "`pareto_stat'"=="arithmetic"  {
     di as txt "Error in alpha_min() argument. The arithmetic mean is undefined unless alpha_min>1."
     exit 498
}

tokenize `varlist'
local n `1'
local l `2'
local u `3'

qui drop if `n'==0 & `touse'
	qui count if ( `l' > `u')  & `touse'
	 if r(N) > 0 {
     di as txt "`r(N)' observations `l' > `u', please check input"
     exit 498
	 }

if "`by'"!=""{
   qui sort `by' `l' 
}
else {
   qui sort `l' 
}

preserve

tempvar bin_mid n_lag l_lag alpha c 
qui egen  `bin_mid' = rowmean(`l' `u') if `touse'
qui replace `bin_mid' = . if `u' == . & `touse'
qui gen  `n_lag' = `n'[_n-1] if `touse'
qui gen  `l_lag' = `l'[_n-1] if `touse'
qui gen  `alpha' = (log(`n'+`n_lag') - log(`n')) / (log(`l') - log(`l_lag')) if `touse'
qui replace `alpha' = max(`alpha_min',`alpha') if `touse'
qui replace `alpha' = . if `u' != . & `touse'

if "`pareto_stat'" == "arithmetic" { 
  qui gen      `c' = `alpha' / (`alpha' - 1) 
} 
else if "`pareto_stat'" == "harmonic"   { 
  qui gen      `c' =  (1+1/`alpha')         
} 
else if "`pareto_stat'" == "geometric"  { 
 qui gen      `c' = exp(1/`alpha')          
} 
else if "`pareto_stat'" == "median"     { 
 qui gen      `c' =  2^(1/`alpha')  
} 

qui replace `bin_mid' = `c' * `l' if `u' ==. & `touse'

local inequality rmd cov sdl gini mehran piesch kakwani theil mld entropy half
if "`by'" != "" {
foreach stat in  `inequality' {
 qui egen `stat'=`stat'(`bin_mid') if `touse', by(`by') weight(`n')
 }
}

else {
 foreach stat in  `inequality' {
  qui egen `stat'=`stat'(`bin_mid') if `touse',  weight(`n')
  }
}


gen pareto_stat = "`pareto_stat'" 
gen alpha_min = `alpha_min'

// remaining vars will be saved
if "`by'" != "" {
   collapse (mean) alpha = `alpha' (mean) mean=`bin_mid' (median) median=`bin_mid' (sd) sd=`bin_mid' (mean) `inequality'  [fw=`n'] if `touse', by(`by' pareto_stat alpha_min)  
}
else {
   collapse (mean) alpha = `alpha' (mean) mean=`bin_mid' (median) median=`bin_mid' (sd) sd=`bin_mid' (mean) `inequality'  [fw=`n'] if `touse', by(pareto_stat alpha_min)
}

qui drop cov
qui gen cv = sd / mean
label variable mean "Mean"
label variable median "Median"
label variable sd "Standard deviation"
label variable cv "Coefficient of variation"
label variable rmd "Relative mean deviation"
label variable sdl "Standard deviation of logs"
label variable gini "Gini index"
label variable mehran     "Mehran index"
label variable piesch     "Piesch index"
label variable kakwani    "Kakwani index"
label variable theil      "Theil index"
label variable mld        "Mean log deviation"
label variable entropy    "generalized entropy measure (GE -1)"
label variable alpha      "estimated alpha"

format alpha-cv %9.2g 
list, compress table

//  save it to designated file if specified
if "`saving'" != ""{
   save `saving', replace
   di "saving results to `saving'"
  }
drop _all
end
