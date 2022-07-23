*! version 1.0.0 , July-20-2022
*! Author: Abbie Yilei Zhang
*! Co-Authors: James Fisher, Joseph Terza
*! Website: https://github.com/zhangyl334/bivpoisson
*! Support: zhangyl334@gmail.com


*!***********************************************************!
*!     Count Valued Seemingly Unrelated Regression   	 *!
*!***********************************************************!


/* ESTIMATION */


clear all

capture program drop bivpoisson
program define bivpoisson, sortpreserve eclass
	version 17.0
	/*Syntax: (t1 = dvars1) (t2 = dvars2) [if]
	Model automatically adds a constant. 
	Code is not-yet robust to syntax errors.*/
	
	/*Parsing of Inputs*/
	/*Equations and If Statement*/
		gettoken eq1 0 : 0, parse(") (") match(parns)
		gettoken eq2 0 : 0, parse(") (") match(parns)
		local ifstatement = "`0'"
	/*Dependent Variables from Equations*/
		gettoken dep1 eq1 : eq1, parse(" = ")
		gettoken dep2 eq2 : eq2, parse(" = ")
	/*Independent Variables from Equations*/		
		gettoken t eq1 : eq1, parse("=") /*Remove equals sign*/
		gettoken indep1 : eq1, parse("=")
		gettoken t eq2 : eq2, parse("=") /*Remove equals sign*/
		gettoken indep2 : eq2, parse("=")
	/*Parsed strings:
		dep1 = eq1 dependent variable
		dep2 = eq2 dependent variable
		indep1 = eq1 independent variables
		indep2 = eq2 independent variables
		ifstatement = sample to use for analysis
	*/
	
	/*Mark Sample*/
		tempvar touse
		qui gen byte `touse' = 0
		qui replace `touse' = 1 `ifstatement'	
		markout	`touse' `dep1' `dep2' `indep1' `indep2'	 /*Drop missing variables*/
	
	/*Check Variables*/
		/*Check that targets are positive, have 
		positive total variation, and are integer valued*/
		/*Eq 1*/ 
			qui sum `dep1' if `touse' == 1
			if r(min) < 0 {
				dis in green "{bf:`dep1'} is negative"
				exit 2000
			}	
			if r(Var) == 0 {
				dis in green "{bf:`dep1'} does not vary"
				exit 2000
			}	
			tempvar tmp
			qui gen `tmp' = (`dep1' - int(`dep1'))^2 if `touse' == 1
			qui sum `tmp' if `touse' == 1
			if r(sum) >0 {
				dis in green "{bf:`dep1'} is not integer valued"
				exit 2000
			}
		/*Eq2*/
			qui sum `dep2' if `touse' == 1
			if r(min) < 0 {
				dis in green "{bf:`dep2'} is negative"
				exit 2000
			}	
			if r(Var) == 0 {
				dis in green "{bf:`dep2'} does not vary"
				exit 2000
			}	
			tempvar tmp
			qui gen `tmp' = (`dep2' - int(`dep2'))^2 if `touse' == 1
			qui sum `tmp' if `touse' == 1
			if r(sum) > 0 {
				dis in green "{bf:`dep2'} is not integer valued"
				exit 2000
			}
		/*Check that target variables are not overly zero-inflated.
		Current test: poisson regression returns coefficient >= 0.
		Needs work*/
		/*Eq1*/
			qui: poisson `dep1' if `touse' == 1
			scalar tmp = e(b)[1,1]
			if tmp < 0 {
				dis in green "{bf:`dep1'} is zero-inflated"
				exit 2000
			}
		/*Eq2*/
			qui: poisson `dep2' if `touse' == 1
			scalar tmp = e(b)[1,1]
			if tmp < 0 {
				dis in green "{bf:`dep2'} is zero-inflated"
				exit 2000
			}
		/*Check for colinear feature variables and remove them*/
		/*Eq1*/
			qui _rmcoll `indep1' if `touse' == 1, forcedrop
			local indep1 "`r(varlist)'"
			if r(k_omitted) > 0 {
				dis in green "{bf:EQ1} several independent variables are colinear, automatically dropping them"
				dis in green "{bf:EQ1} revised independent variables are: `indep1'"
			}
		/*Eq2*/
			qui _rmcoll `indep2' if `touse' == 1, forcedrop
			local indep2 "`r(varlist)'"
			if r(k_omitted) > 0 {
				dis in green "{bf:EQ2} several independent variables are colinear, automatically dropping them"
				dis in green "{bf:EQ2} revised independent variables are: `indep2'"
			}
		
	/*Starting Values*/
	/*Eq1 via Poisson Regression*/
		qui poisson `dep1' `indep1' if `touse' == 1
		if _rc == 0{
			tempname cb1
			mat `cb1' = e(b)
			local ll_1 = e(ll)
		}
		if _rc !=0 {
			dis in green "{bf:EQ1} Initial values could not be estimated"
			exit 2000
		}
	/*Eq2 via Poisson Regression*/
		qui poisson `dep2' `indep2' if `touse' == 1
		if _rc == 0{
			tempname cb2
			mat `cb2' 	= e(b)
			local ll_2 = e(ll)
		}
		if _rc !=0 {
			dis in green "{bf:EQ2} Initial values could not be estimated"
			exit 2000
		}
	/*Starting Values for Rho via Assumption; needs work.*/
		tempname sigma12
		mat `sigma12' = (0)
		mat colnames `sigma12' = "/:sigma12"
	
	/*Mata Load*/
		/*Data
			We save into Y1, Y2, X1, and X2.  These will be overwritten. */
			tempvar cons
			qui gen `cons' = 1
			qui putmata Y1 = `dep1' if `touse' == 1, replace
			qui putmata Y2 = `dep2' if `touse' == 1, replace
			qui putmata X1 = (`indep1' `cons') if `touse' == 1, replace
			qui putmata X2 = (`indep2' `cons') if `touse' == 1, replace
		/*Initial Values*/
			mata: beta1_1n = st_matrix("`cb1'")
			mata: beta2_1n = st_matrix("`cb2'")
			mata: sigma12 = st_matrix("`sigma12'")
			mata: sigmasq1= 1  // Diagonal element of bi-NRV
			mata: sigmasq2 = 1  // See above.
		/*Parameters*/
			mata: quadpts = 30 // Number of quadrature points 
			mata: lims = (-5,5)  // Vector of numerical integration limits
			mata: limits = lims#J(rows(Y1),1,1) //Transformation
	
	/*Perform Estimation in Mata*/ 
		/*Setup Problem*/
			qui capture mata: mata drop BivPoissNorm
			qui mata: BivPoissNorm=moptimize_init()
			qui mata: moptimize_init_evaluator(BivPoissNorm, &BivPoissNormLF())
			qui mata: moptimize_init_evaluatortype(BivPoissNorm, "lf0")
			qui mata: moptimize_init_depvar(BivPoissNorm, 1, Y1)
			qui mata: moptimize_init_depvar(BivPoissNorm, 2, Y2)
			qui mata: moptimize_init_eq_indepvars(BivPoissNorm, 1, X1)
			qui mata: moptimize_init_eq_cons(BivPoissNorm, 1, "off") 
			qui mata: moptimize_init_eq_colnames(BivPoissNorm, 1, tokens("`indep1' _cons"))
			qui mata: moptimize_init_eq_indepvars(BivPoissNorm, 2, X2)
			qui mata: moptimize_init_eq_colnames(BivPoissNorm, 2, tokens("`indep2' _cons"))
			qui mata: moptimize_init_eq_cons(BivPoissNorm, 2,  "off" ) 
			qui mata: moptimize_init_eq_indepvars(BivPoissNorm, 3, "")
			qui mata: moptimize_init_eq_indepvars(BivPoissNorm, 4, "")
			qui mata: moptimize_init_eq_indepvars(BivPoissNorm, 5, "")
			qui mata: moptimize_init_eq_name(BivPoissNorm, 1, "`dep1'")
			qui mata: moptimize_init_eq_name(BivPoissNorm, 2, "`dep2'")
			qui mata: moptimize_init_eq_name(BivPoissNorm, 3, "sigmasq1")
			qui mata: moptimize_init_eq_name(BivPoissNorm, 4, "sigmasq2")
			qui mata: moptimize_init_eq_name(BivPoissNorm, 5, "sigma12")
		/*Initial Values*/
			qui mata: moptimize_init_eq_coefs(BivPoissNorm, 1, beta1_1n)
			qui mata: moptimize_init_eq_coefs(BivPoissNorm, 2, beta2_1n)
			qui mata: moptimize_init_eq_coefs(BivPoissNorm, 3, sigmasq1)
			qui mata: moptimize_init_eq_coefs(BivPoissNorm, 4, sigmasq2)
			qui mata: moptimize_init_eq_coefs(BivPoissNorm, 5, sigma12)
		/*Solve*/
			mata: moptimize(BivPoissNorm)
		/*Write results to console + Stata */
			mata: moptimize_result_display(BivPoissNorm)
			qui mata: moptimize_result_post(BivPoissNorm)
			/*Additional Entries for Ereturn*/
			ereturn local cmd "bivpoisson"
			ereturn local title "Bivariate Count Seemingly Unrelated Regression Estimation"
			ereturn local depvar1 `dep1'
			ereturn local indep1 `indep1'
			ereturn local depvar2 `dep2'
			ereturn local indep2 `indep2'
			ereturn local ifstatement "`ifstatement'"	
end

/*Mata Programs*/
	/*Quadrature Weights and Abscissa*/
	capture mata: mata drop GLQwtsandabs()
	mata 
	matrix GLQwtsandabs(real scalar quadpts)
	{
	  i = (1..quadpts-1)
	  b = i:/sqrt(4:*i:^2:-1) 
	  z1 = J(1,quadpts,0)
	  z2 = J(1,quadpts-1,0)
	  CM = ((z2',diag(b))\z1) + (z1\(diag(b),z2'))
	  V=.
	  ABS=.
	  symeigensystem(CM, V, ABS)
	  WTS = (2:* V':^2)[,1]
	  return(WTS,ABS') 
	} 
	end

	/*Integrand Bivariate Probit*/
	capture mata: mata drop BivPoissNormIntegrand()
	mata
	real matrix BivPoissNormIntegrand(real matrix xxu1, real matrix xxu2, /*
								   */ real matrix Y1, real matrix Y2, /*
								   */ real matrix xb1, real matrix xb2, /*
								   */ real matrix sigma12, real matrix sigmasq1, /*
								   */ real matrix sigmasq2)
	{
	lambda1=exp(xb1:+xxu1)
	lambda2=exp(xb2:+xxu2)
	
	poisspart=poissonp(lambda1,Y1):*poissonp(lambda2,Y2)
	
	SIGMA= sigmasq1,sigma12 \
           sigma12,sigmasq2
		   
	xxu=colshape(xxu1,1),colshape(xxu2,1)
	
	factor=rowsum((xxu*invsym(SIGMA)):*xxu)
	
	bivnormpart= (1:/(2:*pi():*sqrt(det(SIGMA))))/*
			   */ :*exp(-.5:*factor)
			   
	matbivnormpart=colshape(bivnormpart,cols(xxu1))
	
	integrandvals=poisspart:*matbivnormpart		 
	return(integrandvals)
	}	
	end

	/*2-D Integration Procedure*/
	capture mata: mata drop bivquadleg()
	mata
	real matrix bivquadleg(pointer(function) func, real matrix limits1, /*
						 */ real matrix limits2, real matrix wtsabs, /*
						 */ real matrix Y1, real matrix Y2, real matrix xb1, /*
						 */ real matrix xb2, real matrix sigma12, /*
						 */ real matrix sigmasq1, real matrix sigmasq2)
	{
	wts=wtsabs[.,1]'
	abcissae=wtsabs[.,2]'
	quadpts=rows(wtsabs)
	constant11=(limits1[.,2]:-limits1[.,1]):/2
	constant12=(limits1[.,2]:+limits1[.,1]):/2
	constant21=(limits2[.,2]:-limits2[.,1]):/2
	constant22=(limits2[.,2]:+limits2[.,1]):/2
	abcissaeC=J(1,quadpts,1)#abcissae'
	abcissaeR=abcissaeC'
	vecabcissaeC=rowshape(abcissaeC,1)
	vecabcissaeR=rowshape(abcissaeR,1)
	bigargs1=vecabcissaeC#constant11:+constant12
	bigargs2=vecabcissaeR#constant21:+constant22
	funvals=(*func)(bigargs1, bigargs2, Y1, Y2, xb1, xb2, sigma12, sigmasq1, sigmasq2)
	bigwts=wts'*wts
	vecbigwts=rowshape(bigwts,1)
	summand=constant11:*constant21:*(vecbigwts:*funvals)
	integapprox=colsum(summand')
	return(integapprox')
	}
	end

	/*Objective Function for Bivariate Probit*/
	capture mata: mata drop BivPoissNormLF()
	mata
	function BivPoissNormLF(transmorphic BivPoissNorm, real scalar todo, /*
						 */ real rowvector b, real matrix fv, real matrix SS, /*
						 */ real matrix HH) 
	{
	Y1 = moptimize_util_depvar(BivPoissNorm, 1)
	Y2 = moptimize_util_depvar(BivPoissNorm, 2)
	xb1 = moptimize_util_xb(BivPoissNorm, b, 1)
	xb2 = moptimize_util_xb(BivPoissNorm, b, 2)
	sigmasq1 = moptimize_util_xb(BivPoissNorm, b, 3)
	sigmasq2 = moptimize_util_xb(BivPoissNorm, b, 4)
	sigma12 = moptimize_util_xb(BivPoissNorm, b, 5)
	external quadpts
	external limits
	wtsandabs=GLQwtsandabs(quadpts)	
	likeval=bivquadleg(&BivPoissNormIntegrand(), limits, limits, wtsandabs,
						Y1, Y2, xb1, xb2, sigma12, sigmasq1, sigmasq2)     
	fv=ln(likeval)
	}
	end
	