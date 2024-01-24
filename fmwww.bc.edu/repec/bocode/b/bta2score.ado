***Suppachai Lawanaskol, MD***
program define bta2score
	version 16.0
	syntax [, Name(string) Decimal(numlist) TABulation KEEPcons REPLACE CSTAT DSTAT AIC BIC GOF]
	**Define variable name contain the derivation individual score**
	**Define the coefficient matrix**
	qui mat def coef=e(b)
	
	**Define the number of parameter, if not stcox decrease scalar number -1 for constant elimination**
	if "`e(cmd2)'"=="stcox"{
		local k : colsof r(table)
		scalar num=`k'
		local endpoint fail
		if "`keepcons'"==""{
			di _column(5) in green "Cox semi parametric regression did not report the constant"
		}
	}
	else{
		if "`keepcons'"!=""{
			local k: colsof r(table)
			scalar num=`k'
			local endpoint `e(depvar)'
		}
		else{
			local k: colsof r(table)
			scalar num=`k'-1
			local endpoint `e(depvar)'
		}
	}
	
	**Round decimal**
	if "`decimal'"==""{
		local decimal "1"
	}
	
	**Name of score**
	if "`name'"==""{
		local name "score"
	}
	
	**Define the absolute cofficient matrix**
	qui mat def abscoef=J(1,`=scalar(num)',.)
	qui mat li abscoef

	**Convert to absolute**
	qui forvalues x=1/`=scalar(num)'{
		if coef[1,`x']<0{
			mat def abscoef[1,`x']=-coef[1,`x']
		}
		else{
			mat def abscoef[1,`x']=coef[1,`x']
		}
	}
	**Explore to check the absolute coefficient**
	qui mat li abscoef

	**Delete zero coefficient**
	forvalues x=1/`=scalar(num)'{
		if abscoef[1,`x']==0{
			mat def abscoef[1,`x']==.
		}
	}
	**Minimum values define intial values of min is infinity**
	qui scalar min=.

	forvalues x=1/`=scalar(num)'{
		if abscoef[1,`x']<`=scalar(min)'{
			scalar min=abscoef[1,`x']
		}	
	}
	
	**Define scalar min to be an divider**
	qui di `=scalar(min)'
	
	**Use coefficient / scalar min**
	qui mat def devcoef=coef/`=scalar(min)'
	qui mat li devcoef
	
	**Round up each coefficient**
	qui mat def roundcoef=J(1,`=scalar(num)',.)
	qui forvalues x=1/`=scalar(num)'{
		mat def roundcoef[1,`x']=round(devcoef[1,`x'],`decimal')
	}
	
	**Reporting part**
	**C-statistic**
	if "`cstat'"!=""{
		**Concordant statistic form binary regession, from glm, logit, logistic etc**
		if "`e(cmd)'"=="glm" | "`e(cmd)'"=="regress"{
			capture confirm variable glm_xb_score
			if !_rc {
				qui drop glm_xb_score
				qui predict glm_xb_score,xb
			}
			else{
				qui predict glm_xb_score,xb
			}
			qui logistic `e(depvar)' glm_xb_score
			qui lroc,nograph
			scalar cstat=round(r(area),0.0001)
		}
		if "`e(cmd)'"=="logit" | "`e(cmd)'"=="logistic"{
			qui lroc,nograph
			scalar cstat=round(r(area),0.0001)
		}
		else{
			display in green _col(5)"The Final model is not binary regression"
		}
		display in green _col(5)"Harrell C-statistic is" in yellow _column(40)"`=scalar(cstat)'"
	}
	
	**D-statistic**
	if "`dstat'"!=""{
		if "`e(cmd2)'"=="stcox"{
			qui estat con
			scalar dstat=round(r(D),0.0001)
			display in green _col(5)"Somer'D-statistic is" in yellow _column(40)"`=scalar(dstat)'"
		}
		else{
			display in green _col(5)"The Final model is not support D statistic"
		}
	}
	
	**AIC**
	if "`aic'"!=""{
		qui estat ic
		scalar aic=round(r(S)[1,5],0.01)
		display in green _column(5)"AIC is" in yellow  _column(40) "`=scalar(aic)'"
	}
	
	**BIC**
	if "`bic'"!=""{
		qui estat ic
		scalar bic=round(r(S)[1,6],0.01)
		display in green _column(5)"BIC is" in yellow _column(40) "`=scalar(bic)'"
	}
	
	**GOF**
	if "`gof'"!=""{
		if "`e(cmd)'"=="glm" | "`e(cmd)'"=="regress"{
			capture confirm variable glm_xb_score
			if !_rc {
				qui drop glm_xb_score
				qui predict glm_xb_score,xb
			}
			else{
				qui predict glm_xb_score,xb
			}
			qui logistic `e(depvar)' glm_xb_score
			qui estat gof
			scalar gof=round(r(p),0.001)
			qui drop glm_xb_score
		}
		if "`e(cmd)'"=="logit" | "`e(cmd)'"=="logistic"{
			qui estat gof
			scalar gof=round(r(p),0.001)
		}
		else{
			display in green _col(5)"The Final model is not binary regression"
		}
		display in green _col(5)"Hosmer-Lemeshow Goodness-of-fit" in yellow _column(40)"`=scalar(gof)'"
	}
	**Tabulation the rounded score**
	if "`tabulation'"!=""{
		di in green  _column(5) "_________________________________" _newline(1) _column(5) "Endpoint" _column(20) "`endpoint'"_newline(1) _column(5) "________________________________" _newline(1) ///
_column(5) "Predictors" _column(20) "`name'" _newline(1) ///
_column(5) "________________________________"
		forvalues x=1/`=scalar(num)'{
		di in green _column(5) "`: word `x' of `: colnames devcoef''"  in yellow _column(20) roundcoef[1,`x']
		}
		di in green _column(5) "________________________________"
	}
	
	**Generate variable each predictors as _score**
	forvalues x=1/`=scalar(num)'{
		generate _`name'`x'=roundcoef[1,`x']*`: word `x' of `: colnames devcoef''
	}
	
	**Detect the variable score name**
	if "`replace'"!=""{
		capture confirm variable `name'
		if !_rc {
			di in green "`name' was deleted"
			drop `name'
		}
	}
	else{
		capture confirm variable `name'
		if !_rc {
			di in green "`name' already exists"
			drop _`name'*
		}
	}
	egen `name'=rowtotal(_`name'*)
	drop _`name'*
end
