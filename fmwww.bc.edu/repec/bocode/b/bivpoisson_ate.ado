*! version 1.0.0 , August-02-2023
*! Author: Abbie Zhang
*! Co-Authors: James Fisher
*! Website: https://github.com/zhangyl334/bivpoisson_ate
*! Support: abbiezha@bu.edu


*!***********************************************************!
*!     Average Treatment Effects (ATEs) Estimations in   *!
*!     Count Valued Seemingly Unrelated Regression   	 *!
*!     This is post-estimation command that calls        *!
*!     bivpoisson optimization routine and estimate      *!
*!     causal effects  	                                 *!
*!***********************************************************!


capture program drop bivpoisson_ate
program define bivpoisson_ate, sortpreserve eclass
	version 17.0
	/*Syntax: (t1 = pvar dvars1) (t2 = pvar dvars2) [if]
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
		gettoken pvar indep1 : indep1 /*Split indep1 into pvar and indep1 by parsing out first token defined by a space*/
		gettoken t eq2 : eq2, parse("=")
		gettoken indep2 : eq2, parse("=")
		gettoken pvar2 indep2 : indep2
	/*Parsed strings:
		dep1 = eq1 dependent variable
		dep2 = eq2 dependent variable
		indep1 = eq1 independent variables
		indep2 = eq2 independent variables
		pvar1 = eq1 policy variable
		pvar2 = eq2 policy variable
		ifstatement = sample to use for analysis
	*/
	/*Check Variables*/
	if "`pvar'" != "`pvar2'" {
		dis in green "Policy variable must be the same in both equations"
		exit 2000
		}
	qui tab `pvar'
	if r(r) > 2 {
		dis in green "Policy variable is not binary"
		exit 2000
		}
	if r(r) < 2 {
		dis in green "Policy variable has no variation"
		exit 2000
		}

	/*Estimate Parameters*/
	local toest1 = "`dep1' = `pvar' `indep1'"
	local toest2 = "`dep2' = `pvar' `indep2'"
	local toestif = "`ifstatement'"
	
	qui bivpoisson (`toest1') (`toest2') `toestif'

	/*Compute ATEs, Standard Errors, and PValues in Mata via Simulation*/
		/*Simulate Errors*/
		qui mata: estsigma12 = moptimize_result_eq_coefs(BivPoissNorm, 5)
		qui mata: SIGMA = (1, estsigma12 \ estsigma12, 1)
		qui mata: obs =rows(Y1)	
		qui mata: transmat=cholesky(SIGMA)
		qui mata: etamat = (transmat*(rnormal(1, obs,0,1) \ rnormal(1,obs,0,1)))'

		/*Compute ATEs*/
		qui mata: beta = moptimize_result_eq_coefs(BivPoissNorm)
		qui mata: ATEs = ATE(beta)

		/*Compute SEs + PValues for ATEs*/
		qui mata: V = moptimize_result_V(BivPoissNorm)
		qui mata: SEs = ATESE(beta)

		qui mata: Tp1 = ATEs[1] / SEs[1], 2 :* (1 :- normal( abs(ATEs[1] / SEs[1]) ) ) 
		qui mata: Tp2 = ATEs[2] / SEs[2], 2 :* (1 :- normal( abs(ATEs[2] / SEs[2]) ) )

	/*Returns*/
		qui mata: st_matrix("ATEs", ATEs)
		qui mata: st_matrix("Tp1", Tp1)
		qui mata: st_matrix("Tp2", Tp2)
		
		scalar ATE1 = ATEs[1,1]
		scalar ATE1_SE = Tp1[1,1]
		scalar ATE1_p = Tp1[1,2]

		scalar ATE2 = ATEs[1,2]
		scalar ATE2_SE = Tp2[1,1]
		scalar ATE2_p = Tp2[1,2]

		display "Y1's ATE is " ATE1 ". The Standard Error is " ATE1_SE ", with p-Value of " ATE1_p "."
		display "Y2's ATE is " ATE2 ". The Standard Error is " ATE2_SE ", with p-Value of " ATE2_p "."
				
		ereturn local cmd "bivpoisson_ate"
		ereturn local title "ATEs for Bivariate Count Seemingly Unrelated Regression Estimation"
		
end


/*Mata Programs*/
/*Program to Compute Intermediate Vectors*/
/*These vectors are used to compute the ATEs (by taking means), as well as 
various secondary objects for the variance computations*/
qui capture mata: mata drop IntVecs()
mata 
	real matrix IntVecs(beta) {
		external etamat
		external X1
		external X2
		external obs

		beta1 = beta[1..cols(X1)]
		beta2 = beta[cols(X1)+1..cols(X1)+cols(X2)]
		ssq1 = beta[cols(X1)+cols(X2)+1]
		ssq2 = beta[cols(X1)+cols(X2)+2]
		s12 = beta[cols(X1)+cols(X2)+3]

		treatment = J(obs,1,0)
		XB = treatment :* beta1[.,1]' :+ (X1[.,2..cols(beta1)]) * beta1[.,2..cols(beta1)]' :+ sqrt(ssq1):*etamat[.,1]
		L_NT = exp(XB) 
		treatment = J(obs,1,1)
		XB = treatment :* beta1[.,1]' :+ (X1[.,2..cols(beta1)]) * beta1[.,2..cols(beta1)]' :+ sqrt(ssq1):*etamat[.,1]
		L_T = exp(XB)
		IV1 = L_T :- L_NT

		treatment = J(obs,1,0)
		XB = treatment :* beta2[.,1]' :+ (X2[.,2..cols(beta2)]) * beta2[.,2..cols(beta2)]' :+ sqrt(ssq2):*etamat[.,2]
		L_NT = exp(XB) 
		treatment = J(obs,1,1)
		XB = treatment :* beta2[.,1]' :+ (X2[.,2..cols(beta2)]) * beta2[.,2..cols(beta2)]' :+ sqrt(ssq2):*etamat[.,2]
		L_T = exp(XB)
		IV2 = L_T :- L_NT

		return(IV1, IV2)
	}
end

/*Program to Simulate Mean ATEs*/
/*Will generate errors in small samples*/
qui capture mata: mata drop ATE()
mata
	real matrix ATE(beta) {
		return(mean(IntVecs(beta)))
	}
end

/*Programs to compute variance + pvalues for ATEs*/
qui capture mata: mata drop dxdyATE1()
qui capture mata: mata drop dxdyATE2()
qui capture mata: mata drop ATESE()
mata
	void dxdyATE1(beta, y){
		y = ATE(beta)[1]
	}

	void dxdyATE2(beta, y){
		y = ATE(beta)[2]
	}
	
	real matrix ATESE(beta) {
		external obs
		external ATEs
		external V
		
		D = deriv_init()
		deriv_init_params(D,beta)
		deriv_init_evaluator(D, &dxdyATE1())
		g = deriv(D,1)
		n = obs
		varAIE1 = g*(n:*(V))* g' :+ mean( ( IntVecs(beta)[.,1] :- J(obs,1,ATEs[1]) ):^2 )
		seAIE1 = sqrt(varAIE1/n)

		D = deriv_init()
		deriv_init_params(D,beta)
		deriv_init_evaluator(D, &dxdyATE2())
		g = deriv(D,1)
		varAIE1 = g*(n:*(V))* g' :+ mean( ( IntVecs(beta)[.,2] :- J(obs,1,ATEs[2]) ):^2 )
		seAIE2 = sqrt(varAIE1/n)

		return(seAIE1, seAIE2)
	}
end
