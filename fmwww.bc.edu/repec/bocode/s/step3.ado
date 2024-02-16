* Bias-Adjusted 3Step Latent Class Analysis
* v1.3 – 15feb2024
* Written by Giovanbattista Califano
* Dept. Agricultural Sciences – Economics and Policy Group
* University of Naples Federico II
* giovanbattista.califano@unina.it

cap program drop step3
program step3
version 15.1
syntax [varlist(numeric fv default=none)] [if] [in], posterior(string) id(string) [base(integer 1) rrr uneq distal diff iter(integer 20) pval]

local fvops = "`s(fvops)'"

local n_var = `:word count `varlist''
if "`distal'" !="" & `n_var' > 1 {
display as error "one outcome at a time with option 'distal'"
exit
}

local k = 0
foreach var of varlist `posterior'* {
local ++k
}

local code = 0

if "`distal'"=="" & "`uneq'"=="" {
local code = 11
local unequal = ""
}
else if "`distal'"=="" & "`uneq'"!="" {
local code = 11
local unequal = "lcinvariant(none)"
}
else if "`distal'"!="" & "`uneq'"==""{
local code = 12
local unequal = ""
}
else if "`distal'"!="" & "`uneq'"!=""{
local code = 12
local unequal = "lcinvariant(none)"
}

local oddsr = ""
local active = "in (multinomial) log-odds"

if "`rrr'" !="" {
    local oddsr = "eform"
    local active "in odds/relative risk ratios"
}

if "`pval'" !="" {
    local pval = "p(%9.3f)"
}
if "`pval'" == "" {
    local pval = "star"
}


cap qui drop prob_w_*
cap qui drop prob_x_*
cap qui drop temp_*
cap qui drop L_CLASS
cap qui drop CPP_*
cap qui drop ___c*
cap qui drop modal_CLASS
cap qui drop step3_std_*
cap qui ren _merge MeRgE

tempvar max obs1 obs2 class
qui egen `max' = rowmax(`posterior'*)
qui gen L_CLASS = 0

forvalues c = 1/`k' {
qui replace L_CLASS = `c' if `max'==`posterior'`c'
qui gen CPP_1_`c' = `posterior'`c'
   }

local first = "1"
local second = ""
forvalues i = 1/`k' {
  if `i' > 1 {
    local second = "`second' \ `first'"
  }
   else {
   local second = "`first'"
  }
}

matrix dist_x = [`second']
forvalues t = 1/`k' {
   qui total `posterior'`t'
   matrix dist_x[`t', 1] = e(b)
   }

forvalues class = 1/`k' {
   gen prob_w_is`class'_given_y = cond(L_CLASS==`class',1,0)
   gen prob_x_is`class'_given_y = `posterior'`class'
   }

forvalues t=1/`k' {
   forvalues s = 1/`k' {
   gen temp_w`s'_x`t' = (prob_x_is`t'_given_y)*(prob_w_is`s'_given_y)
   }
   }

local string = ""
forval i = 1/`k' {
    local string "`string'`i'"
    if `i' < `k' {
        local string "`string',"
    }
}

local result = ""
forval i = 1/`k' {
    local result "`result'`string'"
    if `i' < `k' {
        local result "`result'\\"
    }
}

matrix D = [`result']
forvalues t=1/`k' {
   forvalues s = 1/`k' {
   qui total temp_w`s'_x`t'
   matrix D[`t',`s'] = e(b)/dist_x[`t',1]
   }
}

matrix logit_modal = [`result']
forvalues x=1/`k' {
   forvalues y = 1/`k' {
   matrix logit_modal[`y',`x'] = D[`y',`x']/D[`y',`base']
   matrix logit_modal[`y',`x'] = ln(logit_modal[`y',`x'])
   if logit_modal[`y',`x'] == . {
    matrix logit_modal[`y',`x'] = 0
   }
   }
}

local constraints = ""
  forvalues i=1/`k' {
  forvalues j=1/`k'  {
  if inlist(`j',`base') continue
  local L_`i'`j'=logit_modal[`i',`j']
  local C_`i'`j'= "(`i': `j'.L_CLASS<-_cons@`L_`i'`j'')"
  local constraints = "`constraints' `C_`i'`j''"
    }
}

        *** CODE 11 ***

if `code'==11 {
    gsem `constraints' (class <- `varlist') `if' `in', lclass(class `k', base(`base')) nocapslatent nocnsr notable `diff' vce(cluster `id') emopts(iterate(`iter')) startvalues(classid L_CLASS) `unequal'
	est store step3
    qui predict CPP_2_*, classposteriorpr

    est tab, d(i.class) b(%9.3f) `pval'  title("Bias-Adjusted 3Step ML Results `active': `varlist' -> Classes") noomitted `oddsr' noempty

}

        *** CODE 12 ***

else if `code'==12 { 
gsem `constraints' (`varlist' <-) `if' `in', lclass(class `k', base(`base')) nocapslatent nocnsr notable `diff' vce(cluster `id') emopts(iterate(`iter')) `unequal'
est store step3
qui predict CPP_2_*, classposteriorpr

if "`fvops'" != "true" {
    est tab, k(`varlist':) b(%9.3f) se(%9.3f) title("Bias-Adjusted 3Step ML Results: Classes -> `varlist'") noomitted noempty

local wald = ""
forval i = 1/`k' {
    local wald "`wald'[`varlist']:`i'.class"
    if `i' < `k' {
        local wald "`wald'="
    }
}

mat PWCchi = J(`k',`k',.)
mat PWCp = J(`k',`k',.)
local rownames = ""
local colnames = ""
forval i = 1/`k' {
    local ii = `i'+1
    forval j = `ii'/`k' {
    qui test [`varlist']:`i'.class=[`varlist']:`j'.class
    mat PWCchi[`j',`i'] = r(chi2)
    mat PWCp[`j',`i'] = r(p)
    }
    local rownames = "`rownames' Class`i'"
    local colnames = "`colnames' Class`i'"
}
di ""
di ""
di as text "Wald Tests"
di ""
di as text "Total"
test "`wald'"
    mat rown PWCchi = `rownames'
    mat coln PWCchi = `colnames'
    mat rown PWCp = `rownames'
    mat coln PWCp = `colnames'
di ""
di as text "Pairwise comparisons: chi2( 1)"
mat list PWCchi, format(%10.2f) noheader
di ""
di as text "Pairwise comparisons: Prob > chi2"
mat list PWCp, format(%10.3f) noheader
}
  else  {
 
  unopvarlist `varlist'
  local unop = "`r(varlist)'"
  qui levelsof `r(varlist)', local(levels)
  foreach l of local levels {
    local tab_`l' "`l'.`unop':i.class "
    local estab "`estab'`tab_`l''"
}

est tab, k(`estab') b(%9.3f) `pval' title("Bias-Adjusted 3Step ML Results `active': Classes -> `varlist'") noempty noomitted `oddsr'

foreach l of local levels {
    local wald_`l' ""
    forval i = 1/`k' {    
    local wald_`l' "`wald_`l''[`l'.`unop']:`i'.class"
    if `i' < `k' {
       local wald_`l' "`wald_`l''="
    }
}

qui test "`wald_`l''"
if r(df) > 0 {
    di ""
    di as text "Wald Test for level `l' of `varlist'"
    test "`wald_`l''"
 }
}

}
}


                *** CCTEST ***
qui gen `obs1' = _n
qui reshape long CPP_1_ CPP_2_, i(`obs1') j(___c2)
qui gen `obs2' = _n
qui ren (CPP_1_ CPP_2_) (CPP_1 CPP_2)
qui reshape long CPP_, i(`obs2') j(___c1)
qui reg CPP_ i.___c1##i.___c2, vce(cluster `id')
mat CCTEST = r(table)
local pvalue = CCTEST[4,2]
qui reshape wide CPP_, i(`obs2') j(___c1)
drop `obs2'
qui reshape wide CPP_1 CPP_2, i(`obs1') j(___c2)

if `pvalue' < 0.05 {
    di ""
    di as error "The original composition of latent classes has likely changed"
  }
if `pvalue' < 0.05 & "`uneq'"=="" {
    di as error "– try with option 'uneq'"
  }

                *** Classic Proportional with sandwich ***

if `pvalue' < 0.05 & "`uneq'"!="" {
    di as text "– estimating with classic proportional assignment..."
    sleep 3000
    qui reshape long CPP_1, i(`obs1') j(modal_CLASS)

    if "`distal'" == "" {
        qui mlogit modal_CLASS `varlist' [iw=CPP_1], vce(cluster `id') b(`base')
        di ""
        est tab, star(0.10 0.05 0.01) b(%9.3f) title("3Step Results `active': `varlist' -> Classes") noomitted `oddsr' noempty
        di as text "Note: Results from classical proportional assignment; variances estimated using the sandwich estimator for clustered and weighted observations"
    } 

    if "`distal'" != "" {
        if "`fvops'" != "true" {
            qui reg `varlist' i.modal_CLASS [iw=CPP_1], vce(cluster `id')
            di ""
            di as text "3Step Results: Classes -> `varlist'"
            pwcompare modal_CLASS, group bonferroni ateq
            di as text "Note: Results from classical proportional assignment; variances estimated using the sandwich estimator for clustered and weighted observations"
        }
        else {
            qui mlogit `unop' i.modal_CLASS [iw=CPP_1], vce(cluster `id') b(`base') 
            di ""
            di as text "3Step Results: Classes -> `varlist'"
            pwcompare modal_CLASS, group bonferroni ateq
            di as text "Note: Results from classical proportional assignment; variances estimated using the sandwich estimator for clustered and weighted observations"  


        }    

    }
qui reshape wide    
}

qui est restore step3

cap qui drop prob_w_*
cap qui drop prob_x_*
cap qui drop temp_*
cap qui drop CPP_*
cap qui drop ___c*
cap qui drop modal_CLASS
cap qui drop step3_std_*
cap qui ren MeRgE _merge


end
