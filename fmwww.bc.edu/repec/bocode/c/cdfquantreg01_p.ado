program define cdfquantreg01_p
version 15.0
		   /* I have to include xb and stdp because _pred_se does only equation(1) */
        local myopts "Xb Stdp Qtile Pctle(real -1)"
        _pred_se "`myopts'" `0'
        if `s(done)'  exit 
        local vtyp `s(typ)'
        local varn `s(varn)'
        local 0    `"`s(rest)'"'
		
		syntax [if] [in] [, `myopts']
		marksample touse, novarlist  
		
		  /* concatenate switch options together */
        local type "`xb'`stdp'`qtile'`pctle(real -1)'"
		
		  /* Estimate quantiles if qtile is requested */
quietly {
_predict xb if `touse', equation(#1)
_predict xd if `touse', equation(#2)
if `"`e(k_eq)'"'=="3" {
_predict xw if `touse', equation(#3)
   }
if "`qtile'" != "" {
	tempvar qtile  w  reptile
    gen `qtile' = 0.5  
if `pctle'==-1 {
	cumul `e(depvar)', gen(`reptile') 
	replace `qtile' =  (`reptile'*(_N-1))*((0.999999 - 1e-06)/(_N-1)) + 1e-06 if `touse'
      }
else {
      replace `qtile' = `pctle' if `touse'
	  if `pctle' < 0|`pctle' > 1 {
	display as error `"Argument out of [0,1] range"'
	exit 198
		}
	  }
	}
}
	
quietly {
if `"`e(user)'"'=="asinhcauchyinnerw2" {
    gen fitted = 1/2 - atan(sinh((xb) - asinh(((1 - 2*`qtile')*(exp(xd)))/(2*(-1 + `qtile')*`qtile'))))/_pi
    }
if `"`e(user)'"'=="asinhcauchyouterw2" {
    gen fitted = 1/2 - atan((exp(xd))*sinh((xb) - asinh((1 - 2*`qtile')/(2*(-1 + `qtile')*`qtile'))))/_pi
    }
if `"`e(user)'"'=="asinhcauchyinnerv2" {
    gen fitted = (_pi - 2*atan(((exp(xd)) - 2*`qtile'*(exp(xd)))/(2*`qtile' - 2*`qtile'^2)))/((1 + exp(xb))*_pi + 2*(-1 + exp(xb))*atan(((exp(xd)) - 2*`qtile'*(exp(xd)))/(2*`qtile' - 2*`qtile'^2)))
    }
if `"`e(user)'"'=="asinhcauchyouterv2" {
	gen fitted = 1/2 + atan(((exp(2*(xb))*(-1 + `qtile')^2 - `qtile'^2)*(exp(xd)))/(exp(xb)*(2*(-1 + `qtile')*`qtile')))/_pi
	}	

if `"`e(user)'"'=="cauchitasinhinnerw2" {
    gen fitted = 1/(1 + exp(asinh(sinh((xb) - asinh((exp(xd))*tan((1/2)*(-_pi + 2*_pi*`qtile')))))))
    }
if `"`e(user)'"'=="cauchitasinhouterw2" {
    gen fitted = 1/(1 + exp(asinh((exp(xd))*sinh((xb) - asinh(tan((1/2)*(-_pi + 2*_pi*`qtile')))))))
    }
if `"`e(user)'"'=="cauchitasinhinnerv2" {
    gen fitted = 1/((1 + exp(-asinh((exp(xd))*tan((1/2)*(-_pi + 2*_pi*`qtile')))))* (exp(xb) + 1/(1 + exp(-asinh((exp(xd))*tan((1/2)*(-_pi + 2*_pi*`qtile'))))) - exp(xb)/(1 + exp(-asinh((exp(xd))*tan((1/2)*(-_pi + 2*_pi*`qtile')))))))
    }
if `"`e(user)'"'=="cauchitasinhouterv2" {
	gen fitted = 1/(1 + exp(-asinh((exp(xd))*tan((1/2)*(-_pi + (2*_pi*`qtile')/(exp(xb) + `qtile' - exp(xb)*`qtile'))))))
	}	

if `"`e(user)'"'=="cauchitcauchyinnerw2" {
    gen fitted = 1/2 - atan(sinh((xb) - asinh((exp(xd))*tan((1/2)*(-_pi + 2*_pi*`qtile')))))/_pi
    }
if `"`e(user)'"'=="cauchitcauchyouterw2" {
    gen fitted = 1/2 - atan((exp(xd))*sinh((xb) - asinh(tan((1/2)*(-_pi + 2*_pi*`qtile')))))/_pi
    }
if `"`e(user)'"'=="cauchitcauchyinnerv2" {
    gen fitted = (1/2 + atan((exp(xd))*tan((1/2)*(-_pi + 2*_pi*`qtile')))/_pi)/(1/2 + exp(xb) + atan((exp(xd))*tan((1/2)*(-_pi + 2*_pi*`qtile')))/_pi - exp(xb)*(1/2 + atan((exp(xd))*tan((1/2)*(-_pi + 2*_pi*`qtile')))/_pi))
    }
if `"`e(user)'"'=="cauchitcauchyouterv2" {
	gen fitted = 1/2 + atan((exp(xd))*tan((1/2)*(-_pi + (2*_pi*`qtile')/(exp(xb) + `qtile' - exp(xb)*`qtile'))))/_pi
	}	

if `"`e(user)'"'=="t2t2innerw2" {
    gen fitted = 1/2 - sinh((xb) - asinh((exp(xd))*( sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile'))))))/(2*sqrt(2 + sinh((xb) - asinh((exp(xd))*( sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile'))))))^2))
    }
if `"`e(user)'"'=="t2t2outerw2" {
    gen fitted = 1/2 - ((exp(xd))*sinh((xb) - asinh(sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile'))))))/(2*sqrt(2 + (exp(xd))^2*sinh((xb) - asinh(sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile')))))^2))
    }
if `"`e(user)'"'=="t2t2innerv2" {
    gen fitted = (1/2 + ((exp(xd))*( sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile')))))/(2*sqrt(2 + (exp(xd))^2*(sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile'))))^2)))/(1/2 + exp(xb) + ((exp(xd))*(sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile')))))/(2*sqrt(2 + (exp(xd))^2*(sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile'))))^2)) - exp(xb)*(1/2 + ((exp(xd))*(sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile')))))/(2*sqrt(2 + (exp(xd))^2*(sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile'))))^2))))
    }
if `"`e(user)'"'=="t2t2outerv2" {
	gen fitted = 1/2 + ((exp(xd))*(sign(2*`qtile'/(exp(xb) + `qtile' - exp(xb)*`qtile') - 1)*(sqrt((1 - (2*`qtile')/(exp(xb) + `qtile' - exp(xb)*`qtile'))^2)/(sqrt(2)*sqrt((`qtile'*(1 - `qtile'/(exp(xb) + `qtile' - exp(xb)*`qtile')))/(exp(xb) + `qtile' - exp(xb)*`qtile'))))))/(2*sqrt(2 + (exp(xd))^2*(sign(2*`qtile'/(exp(xb) + `qtile' - exp(xb)*`qtile') - 1)*(sqrt((1 - (2*`qtile')/(exp(xb) + `qtile' - exp(xb)*`qtile'))^2)/(sqrt(2)*sqrt((`qtile'*(1 - `qtile'/(exp(xb) + `qtile' - exp(xb)*`qtile')))/(exp(xb) + `qtile' - exp(xb)*`qtile')))))^2))
	}	
	
if `"`e(user)'"'=="asinhasinhinnerw2" {
    gen fitted = 1/(1 + exp(asinh(sinh((xb) - asinh(((1 - 2*`qtile')*(exp(xd)))/(2*(-1 + `qtile')*`qtile'))))))
    }
if `"`e(user)'"'=="asinhasinhouterw2" {
    gen fitted = 1/(1 + exp(asinh((exp(xd))*sinh((xb) - asinh((1 - 2*`qtile')/(2*(-1 + `qtile')*`qtile'))))))
    }
if `"`e(user)'"'=="asinhasinhinnerv2" {
    gen fitted = 1/(1 + exp((xb) + asinh(((exp(xd)) - 2*`qtile'*(exp(xd)))/(2*`qtile' - 2*`qtile'^2))))
    }
if `"`e(user)'"'=="asinhasinhouterv2" {
	gen fitted = 1/(1 + exp(-asinh(((exp(xb) + `qtile' - exp(xb)*`qtile')*(1 - (2*`qtile')/(exp(xb) + `qtile' - exp(xb)*`qtile'))*(exp(xd)))/(2*`qtile'*(-1 + `qtile'/(exp(xb) + `qtile' - exp(xb)*`qtile'))))))
	}	

if `"`e(user)'"'=="asinhcauchyinnerw3" {
    gen fitted = 1/2 - atan(sinh((xd) - asinh((xb) + ((1 - 2*`qtile')*(exp(xw)))/(2*(-1 + `qtile')*`qtile'))))/_pi
    }
if `"`e(user)'"'=="asinhcauchyouterw3" {
    gen fitted = 1/2 + atan((xb) - (exp(xw))*sinh((xd) - asinh((1 - 2*`qtile')/(2*(-1 + `qtile')*`qtile'))))/_pi
    }
if `"`e(user)'"'=="asinhcauchyinnerv3" {
    gen fitted = (_pi + 2*atan((xb) + ((exp(xw)) - 2*`qtile'*(exp(xw)))/(2*(-1 + `qtile')*`qtile')))/((1 + exp(xd))*_pi - 2*(-1 + exp(xd))*atan((xb) + ((exp(xw)) - 2*`qtile'*(exp(xw)))/(2*(-1 + `qtile')*`qtile')))
    }
if `"`e(user)'"'=="asinhcauchyouterv3" {
	gen fitted = 1/2 + atan((xb) + (exp(xd)*(-1 + `qtile')*(exp(xw)))/(2*`qtile') + (`qtile'*(exp(xw)))/(exp(xd)*(2 - 2*`qtile')))/_pi
	}	

if `"`e(user)'"'=="cauchitcauchyinnerw3" {
    gen fitted = 1/2 - atan(sinh((xd) - asinh((xb) + (exp(xw))*tan((1/2)*(-_pi + 2*_pi*`qtile')))))/_pi
    }
if `"`e(user)'"'=="cauchitcauchyouterw3" {
    gen fitted = 1/2 + atan((xb) - (exp(xw))*sinh((xd) - asinh(tan((1/2)*(-_pi + 2*_pi*`qtile')))))/_pi
    }
if `"`e(user)'"'=="cauchitcauchyinnerv3" {
    gen fitted = (1/2 + atan((xb) + (exp(xw))*tan((1/2)*(-_pi + 2*_pi*`qtile')))/_pi)/(1/2 + exp(xd) + atan((xb) + (exp(xw))*tan((1/2)*(-_pi + 2*_pi*`qtile')))/_pi - exp(xd)*(1/2 + atan((xb) + (exp(xw))*tan((1/2)*(-_pi + 2*_pi*`qtile')))/_pi))
    }
if `"`e(user)'"'=="cauchitcauchyouterv3" {
	gen fitted = 1/2 + atan((xb) + (exp(xw))*tan((1/2)*(-_pi + (2*_pi*`qtile')/(exp(xd) + `qtile' - exp(xd)*`qtile'))))/_pi
	}	

if `"`e(user)'"'=="cauchitasinhinnerw3" {
    gen fitted = 1/(1 + exp(asinh(sinh((xd) - asinh((xb) + (exp(xw))*tan((1/2)*(-_pi + 2*_pi*`qtile')))))))
    }
if `"`e(user)'"'=="cauchitasinhouterw3" {
    gen fitted = 1/(1 + exp(-asinh((xb) - (exp(xw))*sinh((xd) - asinh(tan((1/2)*(-_pi + 2*_pi*`qtile')))))))
    }
if `"`e(user)'"'=="cauchitasinhinnerv3" {
    gen fitted = 1/((1 + exp(-asinh((xb) + (exp(xw))*tan((1/2)*(-_pi + 2*_pi*`qtile')))))*(exp(xd) + 1/(1 + exp(-asinh((xb) + (exp(xw))*tan((1/2)*(-_pi + 2*_pi*`qtile'))))) - exp(xd)/(1 + exp(-asinh((xb) + (exp(xw))*tan((1/2)*(-_pi + 2*_pi*`qtile')))))))
    }
if `"`e(user)'"'=="cauchitasinhouterv3" {
	gen fitted = 1/(1 + exp(-asinh((xb) + (exp(xw))*tan((1/2)*(-_pi + (2*_pi*`qtile')/(exp(xd) + `qtile' - exp(xd)*`qtile'))))))
	}	

if `"`e(user)'"'=="asinhasinhinnerw3" {
    gen fitted = 1/(1 + exp(asinh(sinh((xd) - asinh((xb) + ((1 - 2*`qtile')*(exp(xw)))/(2*(-1 + `qtile')*`qtile'))))))
    }
if `"`e(user)'"'=="asinhasinhouterw3" {
    gen fitted = 1/(1 + exp(-asinh((xb) - (exp(xw))*sinh((xd) - asinh((1 - 2*`qtile')/(2*(-1 + `qtile')*`qtile'))))))
    }
if `"`e(user)'"'=="asinhasinhinnerv3" {
    gen fitted = 1/((1 + exp(-asinh((xb) + ((1 - 2*`qtile')*(exp(xw)))/(2*(-1 + `qtile')*`qtile'))))*(exp(xd) + 1/(1 + exp(-asinh((xb) + ((1 - 2*`qtile')*(exp(xw)))/(2*(-1 + `qtile')*`qtile')))) - exp(xd)/(1 + exp(-asinh((xb) + ((1 - 2*`qtile')*(exp(xw)))/(2*(-1 + `qtile')*`qtile'))))))
    }
if `"`e(user)'"'=="asinhasinhouterv3" {
	gen fitted = 1/(1 + exp(-asinh((xb) + ((exp(xd) + `qtile' - exp(xd)*`qtile')*(1 - (2*`qtile')/(exp(xd) + `qtile' - exp(xd)*`qtile'))*(exp(xw)))/(2*`qtile'*(-1 + `qtile'/(exp(xd) + `qtile' - exp(xd)*`qtile'))))))
	}	

if `"`e(user)'"'=="t2t2innerw3" {
    gen fitted = 1/2 - sinh((xd) - asinh((xb) + (exp(xw))*sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile')))))/(2*sqrt(2 + sinh((xd) - asinh((xb) + (exp(xw))*sign(2*`qtile'-1)* (sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile'))))))^2)
    }
if `"`e(user)'"'=="t2t2outerw3" {
    gen fitted = 1/2 + ((xb) - (exp(xw))*sinh((xd) - asinh(sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile'))))))/(2*sqrt(2 + ((xb) - (exp(xw))*sinh((xd) - asinh(sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile'))))))^2))
    }
if `"`e(user)'"'=="t2t2innerv3" {
    gen fitted = (1/2 + ((xb) + (exp(xw))*sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile')))))/(2*sqrt(2 + ((xb) + (exp(xw))*sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile'))))^2))/(1/2 + exp(xd) + ((xb) + (exp(xw))*sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile')))))/(2*sqrt(2 + ((xb) + (exp(xw))*sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile'))))))/(2*sqrt(2 + ((xb) + (exp(xw))*sign(2*`qtile'-1)*(sqrt((1 - 2*`qtile')^2)/(sqrt(2)*sqrt((1 - `qtile')*`qtile'))))^2))
    }
if `"`e(user)'"'=="t2t2outerv3" {
	if `qtile'/(exp(xd) + `qtile' - exp(xd)*`qtile') < 0.5 {
       gen fitted = 1/2 + ((xb) + (exp(xw))*(-1)*(sqrt((1 - (2*`qtile')/(exp(xd) + `qtile' - exp(xd)*`qtile'))^2)/(sqrt(2)*sqrt((`qtile'*(1 - `qtile'/(exp(xd) + `qtile' - exp(xd)*`qtile')))/(exp(xd) + `qtile' - exp(xd)*`qtile')))))/(2*sqrt(2 + ((xb) + (exp(xw))*(-1)*(sqrt((1 - (2*`qtile')/(exp(xd) + `qtile' - exp(xd)*`qtile'))^2)/(sqrt(2)*sqrt((`qtile'*(1 - `qtile'/(exp(xd) + `qtile' - exp(xd)*`qtile')))/(exp(xd) + `qtile' - exp(xd)*`qtile')))))^2))
        }
     if `qtile'/(exp(xd) + `qtile' - exp(xd)*`qtile') >= 0.5 {
       gen fitted = 1/2 + ((xb) + (exp(xw))*(1)*(sqrt((1 - (2*`qtile')/(exp(xd) + `qtile' - exp(xd)*`qtile'))^2)/(sqrt(2)*sqrt((`qtile'*(1 - `qtile'/(exp(xd) + `qtile' - exp(xd)*`qtile')))/(exp(xd) + `qtile' - exp(xd)*`qtile')))))/(2*sqrt(2 + ((xb) + (exp(xw))*(1)*(sqrt((1 - (2*`qtile')/(exp(xd) + `qtile' - exp(xd)*`qtile'))^2)/(sqrt(2)*sqrt((`qtile'*(1 - `qtile'/(exp(xd) + `qtile' - exp(xd)*`qtile')))/(exp(xd) + `qtile' - exp(xd)*`qtile')))))^2))
        }
	}

}
			  /* Generate residuals only if estimating casewise quantiles */
quietly {
if `pctle'==-1 {
    gen residuals = fitted - `e(depvar)' if `touse'
	}
}
			  /* Get rid of the fitted and residuals if not requested */
if "`qtile'" == "" {
	drop fitted
	drop residuals
}
		  /* Get the standard errors of predictions if stdp requested */
if "`stdp'" != "" {
_predict seb if `touse', stdp equation(#1) 
_predict sed if `touse', stdp equation(#2) 
if `"`e(k_eq)'"'=="3" {
_predict sew if `touse', stdp equation(#3)
   } 
}
end
