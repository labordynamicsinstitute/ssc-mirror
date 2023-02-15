* Bias-Adjusted 3Step Latent Class Analysis
* v1.0 – 13feb2023
* Written by Giovanbattista Califano
* Dept. Agricultural Sciences – Economics and Policy Group
* University of Naples "Federico II"
* giovanbattista.califano@unina.it

cap program drop step3
program step3
version 15.1
syntax varlist(numeric fv), posterior(string) [base(integer 1) rrr distal id(string) diff iter(integer 20)]

if "`distal'" !="" & "`id'"=="" {
display as error "option id() required"
exit 198
}

local k = 0
foreach var of varlist `posterior'* {
local ++k
}

cap qui drop prob_w_* prob_x_* temp_* L_CLASS

tempvar max inversep order
qui egen `max' = rowmax(`posterior'*)
qui gen L_CLASS = 0

forvalues c = 1/`k' {
qui replace L_CLASS = `c' if `max'==`posterior'`c'
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

  if "`distal'"=="" {
    gsem `constraints' (class <- `varlist'),mlogit lclass(class `k', base(`base')) nocapslatent nocnsr notable `diff' vce(robust) emopts(iterate(`iter'))

    if "`rrr'"=="" {
    est tab, d(i.class) star(0.10 0.05 0.01) b(%9.3f) title("Bias-Adjusted 3Step ML Results: `varlist' -> Classes") noomitted style(columns)
    di "active: multinomial log-odds"

  }
  else { 
      est tab, d(i.class) star(0.10 0.05 0.01) b(%9.3f) title("Bias-Adjusted 3Step ML Results: `varlist' -> Classes") noomitted eform style(columns)
      di "active: relative risk ratios"
  }
}
else { 
    matrix Dinv = inv(D)
    qui reshape long `posterior', i(`id') j(`order')
    qui gen `inversep'=0
    forval i=1/`k'{
        forval j=1/`k'{
        qui replace `inversep'=Dinv[`i',`j'] if L_CLASS == `i' & `order' == `j'
    }
}


foreach w in `varlist' {
    qui regress `w' i.L_CLASS [iw=`inversep'], vce(cluster `id')
    di ""
    di "Bias-Adjusted BCH Results: Classes -> `w'"
    pwcompare L_CLASS, group eff bonferroni
 }  
cap qui drop `inversep'
qui reshape wide
  }


cap qui drop prob_w_* prob_x_* temp_* L_CLASS

end