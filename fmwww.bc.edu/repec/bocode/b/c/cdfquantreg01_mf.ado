program define cdfquantreg01_mf, eclass
version 13.0

syntax varlist [, pctle(real 0.5)]

if `pctle' <= 0|`pctle' >= 1 {
	display as error `"Argument out of (0,1) range"'
	exit 198
	}
estimates store modresults
margins `varlist', predict(equation(#1)) post
mat m1 = e(b)

local col_names : colfullnames e(b)
   tokenize "`col_names'"
   local i = 0
   local j = 0
   while "``++j''" != "" {
       local blist`++i' `"``j''"'
       if "`char'" == "nochar" {
           local ++j
           }
       }

estimates restore modresults
margins `varlist', predict(equation(#2)) post
mat m2 = e(b)
estimates restore modresults
di ""
di "`varlist'"
di "`pctle' quantile  factor level"
di "--------------------------"

if `"`e(k_eq)'"'=="3" {
estimates restore modresults
margins `varlist', predict(equation(#3)) post
mat m3 = e(b)
estimates restore modresults
di ""
di "`varlist'"
di "`pctle' quantile  factor level"
di "--------------------------"
   }

local mcol = `=colsof(m1)'  /* I can use this for the loop for m1, m2, and m3*/

/* Compute the relevant quantile function */

if `"`e(user)'"'=="t2t2innerw3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 - sinh((m2[1,`j']) - asinh((m1[1,`j']) + (exp(m3[1,`j']))*sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle')))))/(2*sqrt(2 + sinh((m2[1,`j']) - asinh((m1[1,`j']) + (exp(m3[1,`j']))*sign(2*`pctle'-1)* (sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle')))))^2))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="t2t2outerw3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
	   local ypred = 1/2 + ((m1[1,`j']) - (exp(m3[1,`j']))*sinh((m2[1,`j']) - asinh(sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle'))))))/(2*sqrt(2 + ((m1[1,`j']) - (exp(m3[1,`j']))*sinh((m2[1,`j']) - asinh(sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle'))))))^2))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="t2t2innerv3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = (1/2 + ((m1[1,`j']) + (exp(m3[1,`j']))*sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle')))))/(2*sqrt(2 + ((m1[1,`j']) + (exp(m3[1,`j']))*sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle'))))^2))/(1/2 + exp(m2[1,`j']) + ((m1[1,`j']) + (exp(m3[1,`j']))*sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle')))))/(2*sqrt(2 + ((m1[1,`j']) + (exp(m3[1,`j']))*sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle'))))))/(2*sqrt(2 + ((m1[1,`j']) + (exp(m3[1,`j']))*sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle'))))^2))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="t2t2outerv3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
	   if `pctle'/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle') < 0.5 {
           local ypred = 1/2 + ((m1[1,`j']) + (exp(m3[1,`j']))*(-1)*(sqrt((1 - (2*`pctle')/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle'))^2)/(sqrt(2)*sqrt((`pctle'*(1 - `pctle'/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle')))/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle')))))/(2*sqrt(2 + ((m1[1,`j']) + (exp(m3[1,`j']))*(-1)*(sqrt((1 - (2*`pctle')/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle'))^2)/(sqrt(2)*sqrt((`pctle'*(1 - `pctle'/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle')))/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle')))))^2))
           }
       if `pctle'/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle') >= 0.5 {
            local ypred = 1/2 + ((m1[1,`j']) + (exp(m3[1,`j']))*(1)*(sqrt((1 - (2*`pctle')/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle'))^2)/(sqrt(2)*sqrt((`pctle'*(1 - `pctle'/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle')))/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle')))))/(2*sqrt(2 + ((m1[1,`j']) + (exp(m3[1,`j']))*(1)*(sqrt((1 - (2*`pctle')/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle'))^2)/(sqrt(2)*sqrt((`pctle'*(1 - `pctle'/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle')))/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle')))))^2))
            }
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhcauchyinnerw3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 - atan(sinh((m2[1,`j']) - asinh((m1[1,`j']) + ((1 - 2*`pctle')*(exp(m3[1,`j'])))/(2*(-1 + `pctle')*`pctle'))))/_pi
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhcauchyouterw3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 + atan((m1[1,`j']) - (exp(m3[1,`j']))*sinh((m2[1,`j']) - asinh((1 - 2*`pctle')/(2*(-1 + `pctle')*`pctle'))))/_pi
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhcauchyinnerv3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = (_pi + 2*atan((m1[1,`j']) + ((exp(m3[1,`j'])) - 2*`pctle'*(exp(m3[1,`j'])))/(2*(-1 + `pctle')*`pctle')))/((1 + exp(m2[1,`j']))*_pi - 2*(-1 + exp(m2[1,`j']))*atan((m1[1,`j']) + ((exp(m3[1,`j'])) - 2*`pctle'*(exp(m3[1,`j'])))/(2*(-1 + `pctle')*`pctle')))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhcauchyouterv3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 + atan((m1[1,`j']) + (exp(m2[1,`j'])*(-1 + `pctle')*(exp(m3[1,`j'])))/(2*`pctle') + (`pctle'*(exp(m3[1,`j'])))/(exp(m2[1,`j'])*(2 - 2*`pctle')))/_pi
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitcauchyinnerw3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 - atan(sinh((m2[1,`j']) - asinh((m1[1,`j']) + (exp(m3[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle')))))/_pi
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitcauchyouterw3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 + atan((m1[1,`j']) - (exp(m3[1,`j']))*sinh((m2[1,`j']) - asinh(tan((1/2)*(-_pi + 2*_pi*`pctle')))))/_pi
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitcauchyinnerv3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = (1/2 + atan((m1[1,`j']) + (exp(m3[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle')))/_pi)/(1/2 + exp(m2[1,`j']) + atan((m1[1,`j']) + (exp(m3[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle')))/_pi - exp(m2[1,`j'])*(1/2 + atan((m1[1,`j']) + (exp(m3[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle')))/_pi))
        di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitcauchyouterv3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 + atan((m1[1,`j']) + (exp(m3[1,`j']))*tan((1/2)*(-_pi + (2*_pi*`pctle')/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle'))))/_pi
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitasinhinnerw3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/(1 + exp(asinh(sinh((m2[1,`j']) - asinh((m1[1,`j']) + (exp(m3[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle')))))))
       di `ypred' "     `blist`j''" 
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitasinhouterw3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/(1 + exp(-asinh((m1[1,`j']) - (exp(m3[1,`j']))*sinh((m2[1,`j']) - asinh(tan((1/2)*(-_pi + 2*_pi*`pctle')))))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitasinhinnerv3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/((1 + exp(-asinh((m1[1,`j']) + (exp(m3[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle')))))*(exp(m2[1,`j']) + 1/(1 + exp(-asinh((m1[1,`j']) + (exp(m3[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle'))))) - exp(m2[1,`j'])/(1 + exp(-asinh((m1[1,`j']) + (exp(m3[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle')))))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitasinhouterv3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/(1 + exp(-asinh((m1[1,`j']) + (exp(m3[1,`j']))*tan((1/2)*(-_pi + (2*_pi*`pctle')/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle'))))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhasinhinnerw3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/(1 + exp(asinh(sinh((m2[1,`j']) - asinh((m1[1,`j']) + ((1 - 2*`pctle')*(exp(m3[1,`j'])))/(2*(-1 + `pctle')*`pctle'))))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhasinhouterw3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/(1 + exp(-asinh((m1[1,`j']) - (exp(m3[1,`j']))*sinh((m2[1,`j']) - asinh((1 - 2*`pctle')/(2*(-1 + `pctle')*`pctle'))))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhasinhinnerv3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/((1 + exp(-asinh((m1[1,`j']) + ((1 - 2*`pctle')*(exp(m3[1,`j'])))/(2*(-1 + `pctle')*`pctle'))))*(exp(m2[1,`j']) + 1/(1 + exp(-asinh((m1[1,`j']) + ((1 - 2*`pctle')*(exp(m3[1,`j'])))/(2*(-1 + `pctle')*`pctle')))) - exp(m2[1,`j'])/(1 + exp(-asinh((m1[1,`j']) + ((1 - 2*`pctle')*(exp(m3[1,`j'])))/(2*(-1 + `pctle')*`pctle'))))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhasinhouterv3" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/(1 + exp(-asinh((m1[1,`j']) + ((exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle')*(1 - (2*`pctle')/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle'))*(exp(m3[1,`j'])))/(2*`pctle'*(-1 + `pctle'/(exp(m2[1,`j']) + `pctle' - exp(m2[1,`j'])*`pctle'))))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="t2t2innerw2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 - sinh((m1[1,`j']) - asinh((exp(m2[1,`j']))*( sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle'))))))/(2*sqrt(2 + sinh((m1[1,`j']) - asinh((exp(m2[1,`j']))*( sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle'))))))^2))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="t2t2outerw2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 - ((exp(m2[1,`j']))*sinh((m1[1,`j']) - asinh(sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle'))))))/(2*sqrt(2 + (exp(m2[1,`j']))^2*sinh((m1[1,`j']) - asinh(sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle')))))^2))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="t2t2innerv2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = (1/2 + ((exp(m2[1,`j']))*( sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle')))))/(2*sqrt(2 + (exp(m2[1,`j']))^2*(sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle'))))^2)))/(1/2 + exp(m1[1,`j']) + ((exp(m2[1,`j']))*(sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle')))))/(2*sqrt(2 + (exp(m2[1,`j']))^2*(sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle'))))^2)) - exp(m1[1,`j'])*(1/2 + ((exp(m2[1,`j']))*(sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle')))))/(2*sqrt(2 + (exp(m2[1,`j']))^2*(sign(2*`pctle'-1)*(sqrt((1 - 2*`pctle')^2)/(sqrt(2)*sqrt((1 - `pctle')*`pctle'))))^2))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="t2t2outerv2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 + ((exp(m2[1,`j']))*(sign(2*`pctle'/(exp(m1[1,`j']) + `pctle' - exp(m1[1,`j'])*`pctle') - 1)*(sqrt((1 - (2*`pctle')/(exp(m1[1,`j']) + `pctle' - exp(m1[1,`j'])*`pctle'))^2)/(sqrt(2)*sqrt((`pctle'*(1 - `pctle'/(exp(m1[1,`j']) + `pctle' - exp(m1[1,`j'])*`pctle')))/(exp(m1[1,`j']) + `pctle' - exp(m1[1,`j'])*`pctle'))))))/(2*sqrt(2 + (exp(m2[1,`j']))^2*(sign(2*`pctle'/(exp(m1[1,`j']) + `pctle' - exp(m1[1,`j'])*`pctle') - 1)*(sqrt((1 - (2*`pctle')/(exp(m1[1,`j']) + `pctle' - exp(m1[1,`j'])*`pctle'))^2)/(sqrt(2)*sqrt((`pctle'*(1 - `pctle'/(exp(m1[1,`j']) + `pctle' - exp(m1[1,`j'])*`pctle')))/(exp(m1[1,`j']) + `pctle' - exp(m1[1,`j'])*`pctle')))))^2))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhcauchyinnerw2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 - atan(sinh((m1[1,`j']) - asinh(((1 - 2*`pctle')*(exp(m2[1,`j'])))/(2*(-1 + `pctle')*`pctle'))))/_pi
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhcauchyouterw2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 - atan((exp(m2[1,`j']))*sinh((m1[1,`j']) - asinh((1 - 2*`pctle')/(2*(-1 + `pctle')*`pctle'))))/_pi
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhcauchyinnerv2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = (_pi - 2*atan(((exp(m2[1,`j'])) - 2*`pctle'*(exp(m2[1,`j'])))/(2*`pctle' - 2*`pctle'^2)))/((1 + exp(m1[1,`j']))*_pi + 2*(-1 + exp(m1[1,`j']))*atan(((exp(m2[1,`j'])) - 2*`pctle'*(exp(m2[1,`j'])))/(2*`pctle' - 2*`pctle'^2)))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhcauchyouterv2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 + atan(((exp(2*(m1[1,`j']))*(-1 + `pctle')^2 - `pctle'^2)*(exp(m2[1,`j'])))/(exp(m1[1,`j'])*(2*(-1 + `pctle')*`pctle')))/_pi
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitasinhinnerw2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/(1 + exp(asinh(sinh((m1[1,`j']) - asinh((exp(m2[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle')))))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitasinhouterw2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/(1 + exp(asinh((exp(m2[1,`j']))*sinh((m1[1,`j']) - asinh(tan((1/2)*(-_pi + 2*_pi*`pctle')))))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitasinhinnerv2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/((1 + exp(-asinh((exp(m2[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle')))))* (exp(m1[1,`j']) + 1/(1 + exp(-asinh((exp(m2[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle'))))) - exp(m1[1,`j'])/(1 + exp(-asinh((exp(m2[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle')))))))
        di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitasinhouterv2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/(1 + exp(-asinh((exp(m2[1,`j']))*tan((1/2)*(-_pi + (2*_pi*`pctle')/(exp(m1[1,`j']) + `pctle' - exp(m1[1,`j'])*`pctle'))))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitcauchyinnerw2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 - atan(sinh((m1[1,`j']) - asinh((exp(m2[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle')))))/_pi
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitcauchyouterw2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 - atan((exp(m2[1,`j']))*sinh((m1[1,`j']) - asinh(tan((1/2)*(-_pi + 2*_pi*`pctle')))))/_pi
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitcauchyinnerv2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = (1/2 + atan((exp(m2[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle')))/_pi)/(1/2 + exp(m1[1,`j']) + atan((exp(m2[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle')))/_pi - exp(m1[1,`j'])*(1/2 + atan((exp(m2[1,`j']))*tan((1/2)*(-_pi + 2*_pi*`pctle')))/_pi))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="cauchitcauchyouterv2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/2 + atan((exp(m2[1,`j']))*tan((1/2)*(-_pi + (2*_pi*`pctle')/(exp(m1[1,`j']) + `pctle' - exp(m1[1,`j'])*`pctle'))))/_pi
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhasinhinnerw2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/(1 + exp(asinh(sinh((m1[1,`j']) - asinh(((1 - 2*`pctle')*(exp(m2[1,`j'])))/(2*(-1 + `pctle')*`pctle'))))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhasinhouterw2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/(1 + exp(asinh((exp(m2[1,`j']))*sinh((m1[1,`j']) - asinh((1 - 2*`pctle')/(2*(-1 + `pctle')*`pctle'))))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhasinhinnerv2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/(1 + exp((m1[1,`j']) + asinh(((exp(m2[1,`j'])) - 2*`pctle'*(exp(m2[1,`j'])))/(2*`pctle' - 2*`pctle'^2))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

if `"`e(user)'"'=="asinhasinhouterv2" {
     /* begin loop */
     local j=1
    while `j'<=`mcol' {
       local ypred = 1/(1 + exp(-asinh(((exp(m1[1,`j']) + `pctle' - exp(m1[1,`j'])*`pctle')*(1 - (2*`pctle')/(exp(m1[1,`j']) + `pctle' - exp(m1[1,`j'])*`pctle'))*(exp(m2[1,`j'])))/(2*`pctle'*(-1 + `pctle'/(exp(m1[1,`j']) + `pctle' - exp(m1[1,`j'])*`pctle'))))))
       di `ypred' "     `blist`j''"
		local j = `j' + 1
    } /* end loop */
}

drop _est_modresults
end


