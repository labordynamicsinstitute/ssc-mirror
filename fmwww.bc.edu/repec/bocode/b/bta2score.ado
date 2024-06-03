*! version 1.2 30May2024
***Suppachai Lawanaskol, MD***
program define bta2score , rclass
	version 16.0
	syntax [, Name(string) Decimal(numlist) TABulation KEEPcons REPLACE CSTAT DSTAT AIC BIC GOF RSQUARE]
	**Define variable name contain the derivation individual score**
	**Define the coefficient matrix**
	qui mat def coef=e(b)
	
	**Define the number of parameter, if not stcox decrease scalar number -1 for constant elimination**
	if "`e(cmd2)'"=="stcox"{
		local k : colsof r(table)
		scalar num=`k'
		local endpoint fail
		if "`keepcons'"==""{
			di _column(2) in green "Cox semi parametric regression did not report the constant"
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
	
	**Multiple cuts of ordered logistic regression**
	**Backward remove the cutoff point respect to the e(cut) matrix**
	**Determine the item with scalar=(k)**
	if "`e(cmd)'"=="ologit"{
		local colcut: colsof e(cat)
		scalar colcut=`colcut'
		scalar num=`k'-`=scalar(colcut)'+1
		if "`keepcons'"!=""{
			scalar num=`k'-`=scalar(colcut)'+2
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
	
	**Tabulation the rounded score**
	if "`tabulation'"!=""{
		di in green  _column(2) "{hline 40}" _newline(1) _column(2) "Endpoint" _column(30) "`endpoint'"_newline(1) _column(2) "{hline 40}" _newline(1) ///
_column(2) "Predictors" _column(30) "Score" _newline(1) ///
_column(2) "{hline 40}"
		forvalues x=1/`=scalar(num)'{
			if length("`: word `x' of `: colnames devcoef''")>20{
			di in green _column(2) substr("`: word `x' of `: colnames devcoef''",1,10)+"~"+substr("`: word `x' of `: colnames devcoef''",length("`: word `x' of `: colnames devcoef''")-9,10) in yellow _column(35) roundcoef[1,`x']
			}
			else{
				di in green _column(2) "`: word `x' of `: colnames devcoef''"  in yellow _column(34) roundcoef[1,`x']
			}
		}
		di in green _column(2) "{hline 40}"
	}
	
	**Generate variable each predictors as _score**
	forvalues x=1/`=scalar(num)'{
		capture confirm variable _`name'`x'
		if !_rc {
			drop _`name'`x'
		}
		generate _`name'`x'=roundcoef[1,`x']*`: word `x' of `: colnames devcoef''
	}
	
	**Detect the variable score name**
	if "`replace'"!=""{
		capture confirm variable `name'
		if !_rc {
			di in green _column(2)"`name' was replaced"
			drop `name'
		}
	}
	else{
		capture confirm variable `name'
		if !_rc {
			di in green _column(2)"`name' already exists"
			drop _`name'*
		}
	}
	
	
	
	**Generate the total sum score**
	egen `name'=rowtotal(_`name'*),missing
	**Define the misssing predictors**
	capture drop _rowmiss
	egen _rowmiss=rowmiss(_`name'*)
	replace `name'=. if _rowmiss>0
	display in green _column(2)"Score variable, `name', was created"
	drop _rowmiss
	drop _`name'*
	
	**Reporting score part**
	**C-statistic**
	if "`cstat'"!=""{
		**Concordant statistic from binary regession, from glm, logit, logistic etc**
		if "`e(cmd)'"=="glm" | "`e(cmd)'"=="regress" | "`e(cmd)'"=="logit" | "`e(cmd)'"=="logistic"{
			qui logistic `e(depvar)' `name'
			qui lroc,nograph
			scalar cstat=round(r(area),0.0001)
			display in green _col(2)"Score Harrell's C-statistic" in yellow _column(30) %9.4f `=scalar(cstat)'
		}
		else if "`e(cmd2)'"=="stcox"{
			qui stcox `name'
			qui estat con
			scalar cstat=round(r(C),0.0001)
			display in green _col(2)"Score Harrell's C-statistic" in yellow _column(30) %9.4f `=scalar(cstat)'
		}
		else{
			display in green _col(2)"The Final model is not binary regression"
		}
		
		return scalar cstat=cstat 
	}
		
	**D-statistic**
	if "`dstat'"!=""{
		if "`e(cmd2)'"=="stcox"{
			qui stcox `name'
			qui estat con
			scalar dstat=round(r(D),0.0001)
			display in green _col(2)"Score Somer's D-statistic" %9.4f in yellow _column(30)`=scalar(dstat)'
			return scalar dstat=dstat
		}
		else{
			display in green _col(2)"The Final model is not support D-statistic"
		}
	}
	
	**AIC**
	if "`aic'"!=""{
		if "`e(cmd)'"=="glm" | "`e(cmd)'"=="regress" | "`e(cmd)'"=="logit" | "`e(cmd)'"=="logistic" | "`e(cmd)'"=="ologit" {
			qui `e(cmd)' `e(depvar)' `name'
			qui estat ic
			scalar aic=round(r(S)[1,5],0.01)
			display in green _column(2)"Score AIC" in yellow  %9.2f _column(30) `=scalar(aic)'
			return scalar aic=aic
		}
		else if "`e(cmd2)'"=="stcox"{
			qui `e(cmd2)' `name'
			qui estat ic
			scalar aic=round(r(S)[1,5],0.01)
			display in green _column(2)"Score AIC" in yellow  %9.2f _column(30) `=scalar(aic)'
			return scalar aic=aic
		} 
	}
	
	**BIC**
	if "`bic'"!=""{
		if "`e(cmd)'"=="glm" | "`e(cmd)'"=="regress" | "`e(cmd)'"=="logit" | "`e(cmd)'"=="logistic" | "`e(cmd)'"=="ologit" {
			qui `e(cmd)' `e(depvar)' `name'
			qui estat ic
			scalar bic=round(r(S)[1,6],0.01)
		}
		else if "`e(cmd2)'"=="stcox"{
			qui `e(cmd2)' `name'
			qui estat ic
			scalar bic=round(r(S)[1,6],0.01)
		}
		display in green _column(2)"Score BIC" in yellow %9.2f _column(30) `=scalar(bic)'
		return scalar bic=bic
	}
	
	**GOF**
	if "`gof'"!=""{
		if "`e(cmd)'"=="glm" | "`e(cmd)'"=="regress" | "`e(cmd)'"=="logit" | "`e(cmd)'"=="logistic"{
			qui logistic `e(depvar)' `name'
			qui estat gof
			scalar gof=round(r(p),0.001)
			display in green _col(2)"Score Hosmer-Lemeshow GOF" in yellow %9.2f _column(30)`=scalar(gof)'
		}
		else if "`e(cmd)'"=="ologit"{
			if "`e(stepwise)'"=="stepwise"{
				display in green _column(2)"The Final model is under stepwise command prefix"
			}
			else{
				qui xi: ologitgof `e(depvar)' `name'
				scalar gof=round(r(P_HL),0.001)
				display in green _col(2)"Score Hosmer-Lemeshow GOF" in yellow %9.2f _column(30)`=scalar(gof)'
			}	
		}
		else {
			display in green _col(2)"The Final model is not support GOF"
		}
		return scalar gof=gof
	}
	
	**R-sqaure**
	if "`rsquare'"!=""{
		if "`e(cmd)'"=="glm"{
			qui regress `e(depvar)' `name'
			scalar rsquare=e(r2)
		}
		else if "`e(cmd)'"=="logit" | "`e(cmd)'"=="logistic"{
			qui logit `e(depvar)' `name'
			scalar rsquare=round((1 - e(ll)/e(ll_0)),0.01)
		}
		else if "`e(cmd2)'"=="stcox" & "`e(stepwise)'"=="stepwise"{
			display in green _column(2)"The Final model is under stepwise command prefix"
		}
		else if "`e(cmd2)'"=="stcox" & "`e(stepwise)'"!="stepwise"{
			qui str2d: `e(cmd2)' `name'
			scalar rsquare=r(r2)
		}
		else{
			scalar rsquare=round((1 - e(ll)/e(ll_0)),0.01)
		}
			display in green _col(2)"Score R-square" in yellow %9.4f _column(30)`=scalar(rsquare)'
		return scalar rsquare=rsquare	
	}
	
	**Returning the rclass for generalized the result to others**
	return mat coef coef
	return local name `name'
	return local endpoint `endpoint'
	
end