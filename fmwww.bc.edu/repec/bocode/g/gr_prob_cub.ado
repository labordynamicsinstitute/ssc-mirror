********************************************************************************
*! "gr_prob_cub", v.20, Cerulli, 06nov2020
********************************************************************************
program gr_prob_cub , eclass
syntax varlist(max=1) [if] [in] [fweight pweight] , prob(name) ///
[save_graph(string) outname(name) shelter(numlist max=1)]
marksample touse
local y `varlist'
cub `y' [`weight'`exp']  if `touse' ,  pi() xi() vce(oim) shelter(`shelter')
local m=e(M)
tempvar theta1 
predict `theta1' , equation(pi_beta)   
tempvar theta2 
predict `theta2' , equation(xi_gamma) 
********************************************************************************
tempvar p M R S
quietly generate double `p' = 1/(1+exp(-`theta1'))
local c = exp(lnfactorial(`m'-1))
mat cmb = J(`m',1,.)
forv i=1/`m' {
sca d = (exp(lnfactorial(`i'-1))*exp(lnfactorial(`m'-`i')))
mat cmb[`i',1] = `c'/d
}
qui gen double `M' = cmb[`y',1]
quietly generate double `R' = ((exp(-`theta2'))^(`y'-1))/((1+exp(-`theta2'))^(`m'-1))
quietly generate double `S' = 1/`m'
cap gen `prob' = (`p'*(`M'*`R'-`S')+`S')
********************************************************************************
tempfile data1 
********************************************************************************
qui{  // start quietly
preserve
tempvar prob_real
gen `prob_real'=1
collapse (percent) `prob_real' , by(`y')
replace `prob_real'=`prob_real'/100
save `data1' , replace
restore
********************************************************************************
preserve
collapse `prob' , by(`y')
merge 1:1 `y' using `data1'
********************************************************************************
la var `prob' "Expected probabilities"
la var `prob_real' "Actual probabilities"
tempname M
mkmat `y' `prob' `prob_real' , matrix(`M')
mat colnames `M' = `y' fitted_prob actual_prob
ereturn matrix M=`M'
********************************************************************************
set scheme s1mono
********************************************************************************
if ("`outname'"=="" & "`shelter'"==""){
tw (connected `prob' `y' , xtitle("") xlabel(1(1)`m')) ///
(connected `prob_real' `y') , note("Outcome = `y'" "Shelter = Not specified") ///
name(gr_pred , replace) saving(`save_graph',replace)
}
if ("`outname'"=="" & "`shelter'"!=""){
tw (connected `prob' `y' , xtitle("") xlabel(1(1)`m')) ///
(connected `prob_real' `y') , note("Outcome = `y'" "Shelter = `shelter'") ///
name(gr_pred , replace) saving(`save_graph',replace)
}
if ("`outname'"!="" & "`shelter'"==""){
tw (connected `prob' `y' , xtitle("") xlabel(1(1)`m')) ///
(connected `prob_real' `y') , note("Outcome = `outname'" "Shelter = Not specified") ///
name(gr_pred , replace) saving(`save_graph',replace)
}
else if ("`outname'"!="" & "`shelter'"!=""){
tw (connected `prob' `y' , xtitle("") xlabel(1(1)`m')) ///
(connected `prob_real' `y') , note("Outcome = `outname'" "Shelter = `shelter'") ///
name(gr_pred , replace) saving(`save_graph',replace)
}
********************************************************************************
restore
} // end quietly
********************************************************************************
end
********************************************************************************
*END
********************************************************************************