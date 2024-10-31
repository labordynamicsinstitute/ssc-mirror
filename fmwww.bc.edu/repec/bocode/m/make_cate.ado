********************************************************************************
* PROGRAM "make_cate"
********************************************************************************
*! make_cate, v3, GCerulli, 17Jul2024
program make_cate , eclass
version 16
syntax varlist [if] [in] , type(string) treatment(varlist max=1)  ///
train_cate(name) new_cate(name) [model(string) new_data(name)]
marksample touse
markout `touse' `treatment'
********************************************************************************
    if ("`type'" != "ra") & ("`type'" != "dr"){
		di _newline
		di in red "**********************************************"
		di in red "WARNING: Only options 'ra' or 'dr' are allowed"
		di in red "**********************************************"
		error 1
		exit
	}
********************************************************************************
* Regression adjustment
********************************************************************************
    if "`type'" == "ra" {
********************************************************************************
		* Form y and x
		************************************************************************
		tokenize "`varlist'"
		local y "`1'"
		macro shift 1
		local xvars "`*'"
		local w "`treatment'" 
		************************************************************************
		if "`new_data'"==""{
		************************************************************************
			if "`model'"=="linear"{
				teffects ra (`y' `xvars', linear) (`w') if `touse'
				}
			else if "`model'"=="logit"{
				teffects ra (`y' `xvars', logit) (`w') if `touse'
				}	
			else if "`model'"=="poisson"{
				teffects ra (`y' `xvars', poisson) (`w') if `touse'
				}
			else if "`model'"=="flogit"{
				teffects ra (`y' `xvars', flogit) (`w') if `touse'
				}	
		************************************************************************	
		tempvar Ey1_x Ey0_x
		predict `Ey1_x' , cmean tlevel(1)
		predict `Ey0_x' , cmean tlevel(0)
		gen `train_cate'=(`Ey1_x' - `Ey0_x')
		ereturn local cate = "`train_cate'"
		}
		************************************************************************
		if "`new_data'"!=""{
		************************************************************************
			if  "`model'"==""{
				cap drop _train_new_index
				gen _train_new_index="train"
				append using `new_data' 
				replace _train_new_index="new" if _train_new_index==""
				teffects ra (`y' `xvars') (`w') if `touse' & _train_new_index=="train"
			}
			else if  "`model'"=="linear"{
				cap drop _train_new_index
				gen _train_new_index="train"
				append using `new_data' 
				replace _train_new_index="new" if _train_new_index==""
				teffects ra (`y' `xvars') (`w') if `touse' & _train_new_index=="train"
			}
			else if ("`model'"=="logit"){
				cap drop _train_new_index
				gen _train_new_index="train"
				append using `new_data' 
				replace _train_new_index="new" if _train_new_index==""
				teffects ra (`y' `xvars', logit) (`w') if `touse' & _train_new_index=="train"
			}	
			else if ("`model'"=="poisson"){
				cap drop _train_new_index
				gen _train_new_index="train"
				append using `new_data' 
				replace _train_new_index="new" if _train_new_index==""
				teffects ra (`y' `xvars', poisson) (`w') if `touse' & _train_new_index=="train"
			}	
			else if ("`model'"=="flogit"){
				cap drop _train_new_index
				gen _train_new_index="train"
				append using `new_data' 
				replace _train_new_index="new" if _train_new_index==""
				teffects ra (`y' `xvars', flogit) (`w') if `touse' & _train_new_index=="train"
			}	
		************************************************************************
		tempvar Ey1_x1 Ey0_x1 Ey1_x2 Ey0_x2
		*
		predict `Ey1_x1' if _train_new_index=="train" , cmean tlevel(1)
		predict `Ey0_x1' if _train_new_index=="train" , cmean tlevel(0)
		gen `train_cate'=(`Ey1_x1' - `Ey0_x1') if _train_new_index=="train"
		ereturn local cate_train "`train_cate'"
		*
		predict `Ey1_x2' if _train_new_index=="new" , cmean tlevel(1)
		predict `Ey0_x2' if _train_new_index=="new" , cmean tlevel(0)
		gen `new_cate'=(`Ey1_x2' - `Ey0_x2') if _train_new_index=="new"
		ereturn local cate_new "`new_cate'"
		}
		************************************************************************
		ereturn clear
		ereturn local cate_train "`train_cate'"		
		ereturn local cate_new "`new_cate'"
		ereturn local dep_var "`y'"
		ereturn local treatment "`w'"
		ereturn local xvars "`xvars'"
		************************************************************************ 
    }
********************************************************************************
* Double robust
********************************************************************************
    else if "`type'" == "dr" {
		************************************************************************
		* Form y and x
		************************************************************************
		tokenize "`varlist'"
		local y "`1'"
		macro shift 1
		local xvars "`*'"
		local w "`treatment'" 
		************************************************************************
		local A `w'
		************************************************************************
qui{
		* Split the sample 
		tempvar split
		splitsample, generate(`split') nsplit(2) rseed(101)

		local j=2
		forvalues i=1/2{
		
		* propensity score estimation: pi=E(A|X) over split=i
		qui probit `A' `xvars' if `split'==`i'
		tempname PI_`i'
		estimate store `PI_`i''
		tempvar pi
		predict `pi' , p 

		* regression mu1=E(Y|X,A=1) over split=i
		qui regress `y' `xvars' if `A'==1 & `split'==`i'
		tempname MU1_`i'
		estimate store `MU1_`i''
		tempvar mu1
		predict `mu1'

		* regression mu0=E(Y|X,A=0) over split=i
		qui qui regress `y' `xvars' if `A'==0 & `split'==`i'
		tempname MU0_`i'
		estimate store `MU0_`i''
		tempvar mu0
		predict `mu0'

		* generate _fi
		tempvar mu_A
		gen `mu_A' = `A'*`mu1'+(1-`A')*`mu0'
		tempvar _fi
		gen `_fi' = ((`A'-`pi')/(`pi'*(1-`pi'))*(`y'-`mu_A'))+(`mu1'-`mu0')

		* regression E(_fi|X) over split==j
		qui reg `_fi' `xvars' if `split'==`j'
		tempname FI_`j'
		estimates store `FI_`j''
		tempvar tau_`i'
		predict `tau_`i''

		local j=`j'-1
		}
		gen `train_cate'=(`tau_1'+`tau_2')/2
	****************************************************************************
		if "`new_data'"!=""{
	****************************************************************************
			cap drop _train_new_index
			gen _train_new_index="train"
			append using `new_data' 
			replace _train_new_index="new" if _train_new_index==""
			
				* Split the sample 
				tempvar split2
				splitsample, generate(`split2') nsplit(2) rseed(101)
				* Generate pure out-of-sample predictions of tau(X)
				* taking the average in the two splits
				local j=2
				forvalues i=1/2{
				* out-of-sample regression E(_fi|X) over split==j
				estimates restore `FI_`j''
				tempvar tau_`i'
				predict `tau_`i'' if _train_new_index=="new"
				local j=`j'-1
				}
				gen `new_cate'=(`tau_1'+`tau_2')/2 if _train_new_index=="new"
				}	
}
	****************************************************************************
				ereturn clear
				ereturn local cate_train "`train_cate'"		
				ereturn local cate_new "`new_cate'"
				ereturn local dep_var "`y'"
				ereturn local treatment "`w'"
				ereturn local xvars "`xvars'"
	****************************************************************************
    }
end
