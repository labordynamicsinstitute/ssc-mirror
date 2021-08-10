********************************************************************************
*! "pr_pred_cub", v.19, Cerulli, 02oct2020
********************************************************************************
prog pr_pred_cub , eclass
syntax varlist(min=1) [if] [in] [fweight pweight] , prob(name)
local y `varlist' 
tempvar p M R S
********************************************************************************
marksample touse
********************************************************************************
cub informat [`weight'`exp'] if `touse' , pi() xi() vce(oim) // esimates "cub00"
tempvar theta1
predict `theta1' , equation(pi_beta) 
tempvar theta2  
predict `theta2' , equation(xi_gamma)
local m=e(M) // number of categories
********************************************************************************
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
di as text in red ""
di as text in red "{hline}"
di as text in red "{bf:******************************************************************************}"
di as text in red "{bf:********************* PROBABILITY BY CATEGORY ********************************}"
di as text in red "{bf:******************************************************************************}"
di as text in red "{hline}"
tab `y' `prob' 
di as text in red "{hline}"
********************************************************************************
end 
********************************************************************************
