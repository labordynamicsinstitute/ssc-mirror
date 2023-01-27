*! version 2.1  24jan2023  see endnotes
program gintreg, eclass
version 13.0
	set more off
	syntax varlist(min=2 fv ts)  [aw fw pw iw] [if] [in] ///
	[, DISTribution(string)		/// gintreg options
	sigma(varlist)              ///
	lambda(varlist)             ///
	p(varlist)                  ///
	q(varlist)                  ///
	eyx(string)                 ///
	gini                        ///
	aicbic                      ///
	plot(numlist)               ///
	INITial(numlist)            ///
	CONSTraints(numlist)        ///
	FREQuency(varlist)          ///
	DIFficult TECHnique(passthru) ITERate(passthru) 	/// ml_model options
	nolog TRace GRADient showstep HESSian SHOWTOLerance                 ///
	TOLerance(passthru) NONRTOLerance LTOLerance(passthru)			    ///
	NRTOLerance(passthru) robust cluster(passthru) repeat(integer 1)    ///
	NOCONStant svy vce(passthru)] 
	
	/* CHECKS PROPER DISTribution INPUT */
	* defines distribution trees; useful for concise if-statements
	local sgt_tree /// excludes normal bc inlist takes max 10 arguments
		`"snormal","laplace","slaplace","ged","sged","t","gt","st","sgt"'
	local gb2_tree ///
		`"lnormal","weibull","gamma","ggamma","br3","br12","gb2"'
	
	* returns error if DISTribution specified incorrectly
	if !inlist("`distribution'","`sgt_tree'") & !inlist("`distribution'","`gb2_tree'")	///
		& "`distribution'"!="normal" & "`distribution'"!="" {
		di as err "distribution not recognized"
		exit 498
	}
	
	* returns error if GINI activated with incompatible DISTribution
	if "`gini'"!="" & !inlist("`distribution'","weibull","gamma","br3","br12") {
		di as err "gini not operational with specified distribution"
		exit 498
	}
	
	/* CHECKS PARAMETER-DISTRIBUTION CONSISTENCY */
	if "`p'"!="" & !inlist("`distribution'","ged","sged","gt","sgt","gamma","ggamma","br3","gb2") {
		di as err "p is not a parameter of the chosen distribution"  
		exit 498
	}
	if "`q'"!="" & !inlist("`distribution'","t","gt","st","sgt","br12","gb2") {
		di as err "q is not a parameter of the chosen distribution"
		exit 498 
	}
	if "`lambda'"!="" & !inlist("`distribution'","snormal","slaplace","sged","st","sgt") {
		di as err "lambda is not a parameter of the chosen distribution"  
		exit 498 
	}
	
	/* DEFINES DEPVARs INDEPVARs */
	local depvar1: word 1 of `varlist'
	local depvar2: word 2 of `varlist'
	local tempregs: list varlist - depvar1 
	local regs: list tempregs - depvar2
	
	* returns error if the "higher bound" (depvar2) is lower than the "lower bound" (depvar1)
	qui count if `depvar1'>`depvar2' & `depvar1'!=.
	if r(N)>0 {
		di as err "dependent variable 1 is greater than dependent variable 2 for some observation"
		exit 198
	}
	
	/* MARKS OBSERVARTIONS TO USE in analysis */
	marksample touse, nov
	foreach i in  `regs' `sigma' `p' `q' `lambda' {
		qui replace `touse' = 0 if `i'==. // exclude obs with missing x's
	}
	qui replace `touse' = 0 if `depvar1'==`depvar2'==. // exclude obs with missing y's
	
	* if user specifies a positive distribution, returns warning and removes
	* from analysis observations with non-positive dependent variable
	if inlist("`distribution'","`gb2_tree'") { 
		quietly {
			count if `touse' & `depvar1'<0 & `depvar1'==`depvar2'
			if r(N)>0 {
				noi di as txt _n "{res:`depvar1'} has `r(N)' uncensored values < 0; not used in calculations"
			}
			count if `touse' & `depvar1'==0 & `depvar1'==`depvar2'
			if r(N)>0 {
				noi di as txt _n "{res:`depvar1'} has `r(N)' uncensored values = 0; not used in calculations"
			}
			count if `touse' & `depvar1'<=0 & `depvar2'<=0 & `depvar1'!=`depvar2'
			if r(N)>0 {
				noi di as txt _n "{res:`depvar1'} has `r(N)' intervals < 0; not used in calculations"
			}
			count if `touse' & `depvar1'==. & `depvar2'<=0 & `depvar1'!=`depvar2' 
			if r(N)>0 {
				noi di as txt _n "{res:`depvar1'} has `r(N)' left censored values <= 0; not used in calculations"
			}
		replace `touse' = 0 if `depvar2'<=0
		}
	}
	
	/* DEFINES variables tags and labels depending on status of FREQuency */
	if "`frequency'" != "" {
		* normalizes frequency variable to sum to one
		tempvar tot per
		qui egen `tot' = sum(`frequency')
		qui gen `per' = `frequency'/`tot'
		global group_per `per' // referenced by evaluator files for group data
		
		local group "_group" // tag to indicate correct evaluator file, ie intllf_normal(_group)
		local count_type "groups" // label for post-evaluation statistics
	}
	else {
		local count_type "observations" // label for post-evaulation statistics
	}
	
	/* SETS DEFAULT EYX TO MEAN */
	if "`eyx'" == "" local eyx "mean"
	
	/* AGGREGATES options used by every regression */
	local max_opts `" maximize missing `technique' `difficult' `iterate' `log' `trace' `gradient' `showstep' `hessian' `showtolerance' `nonrtolerance' `tolerance' `ltolerance' `nrtolerance' `vce' `robust' `cluster' `svy' "'

	/* DEFINES PARAMETERS AND CONSTRAINTS for distributions within SGT tree */
	if inlist("`distribution'","`sgt_tree'") | "`distribution'"=="normal" | "`distribution'"=="" {
		
		* evaluates normal if specified or by default
		if "`distribution'"=="normal" | "`distribution'"=="" {
			local evaluator intllf_normal`group'
			local title "{title:Interval Regression with Normal Distribution}"
			local params `" (mu: `depvar1' `depvar2' = `regs', `noconstant') (lnsigma: `sigma') "'
		}
		* if INITial activated, evaluates preliminary normal to estimate good starting parameters for other distributions in sgt-tree
		else if "`initial'"!="" {
			local params `" (mu: `depvar1' `depvar2' = `regs', `noconstant') (lnsigma: `sigma') "'
			quietly ml model lf intllf_normal`group' `params' [`weight' `exp'] if `touse', `max_opts' constraints(`constraints') search(norescale)
			matrix b_0 = e(b) // starting parameter values (mu, sigma)
			
			local init_opts `" init(b_0 `initial', copy) search(norescale) continue "' // defines options conditional on activation of INITial; previous contributors found that "search(norescale)" and "continue" improve convergence with INITial activated
		}
		
		* these distributions use a common evaluator file (namely, SGED); constraints are applied to estimate special cases
		if inlist("`distribution'","snormal","laplace","slaplace","ged","sged") {
			local evaluator intllf_sged`group'
			local params `" (mu: `depvar1' `depvar2' = `regs', `noconstant') (lnsigma: `sigma') (p: `p') (lambda: `lambda') "'
			local neq `" neq(3) "' // suppresses default lambda output; replaced in /transforming lambda/ section
			
			if "`distribution'"=="snormal" {
				local title "{title:Interval Regression with Skewed Normal Distribution}"
				constraint define 1 [p]_cons=2
				local const_list 1
			}
			else if "`distribution'"=="laplace" {
				local title "{title:Interval Regression with Laplace Distribution}"
				constraint define 1 [p]_cons=1
				constraint define 2 [lambda]_cons=0
				local const_list 1 2
			}
			else if "`distribution'"=="slaplace" {
				local title "{title:Interval Regression with Skewed Laplace Distribution}"
				constraint define 1 [p]_cons=1
				local const_list 1
			}
			else if "`distribution'"=="ged" {
				local title "{title:Interval Regression with Generalized Error Distribution}"
				constraint define 1 [lambda]_cons=0
				local const_list 1
			}
			else if "`distribution'"=="sged" {
				local title "{title:Interval Regression with Skewed Generalized Error Distribution}"
			}
		}
		
		* these distributions use a common evaluator file (namely, SGT); constraints are applied to estimate special cases
		if inlist("`distribution'","t","st","gt","sgt") {
			local evaluator intllf_sgt_condition`group'
			local params `" (mu: `depvar1' `depvar2' = `regs', `noconstant') (lnsigma: `sigma') (p: `p') (q: `q') (lambda: `lambda') "'
			local neq `" neq(4) "' // suppresses default lambda output; replaced in /transforming lambda/ section
			
			if "`distribution'"=="t" {
				local title "{title:Interval Regression with t Distribution}"
				constraint define 1 [p]_cons=2
				constraint define 2 [lambda]_cons=0
				local const_list 1 2
			}
			else if "`distribution'"=="st" {
				local title "{title:Interval Regression with Skewed t Distribution}"
				constraint define 1 [p]_cons=2
				local const_list 1
			}
			else if "`distribution'"=="gt" {
				local title "{title:Interval Regression with Generalized t Distribution}"
				constraint define 1 [lambda]_cons=0
				local const_list 1
			}
			else if "`distribution'"=="sgt" {
				local title "{title:Interval Regression with Skewed Generalized t Distribution}"
			}
		}
	}
	
	/* DEFINES PARAMETERS AND CONSTRAINTS for distributions within GB2 tree */
	if inlist("`distribution'","`gb2_tree'") {
		
		* evaluates lnormal if specified
		if "`distribution'"=="lnormal" {
			local evaluator intllf_lnormal`group'
			local title "{title:Interval Regression with Lognormal Distribution}"
			local params `" (mu: `depvar1' `depvar2' = `regs', `noconstant') (lnsigma: `sigma') "'
		}
		* if INITial activated, evaulates preliminary lnormal to estimate good starting parameters for other distributions in gb2-tree
		else if "`initial'"!="" {
			local params `" (mu: `depvar1' `depvar2' = `regs', `noconstant') (lnsigma: `sigma') "'
			quietly ml model lf intllf_lnormal`group' `params' [`weight' `exp'] if `touse', `max_opts' constraints(`constraints') search(norescale)
			matrix b_0 = e(b) // starting parameter values (mu, sigma); mu is interpreted as delta -- see help ml init (...,copy)
			
			local init_opts `" init(b_0 `initial', copy) search(norescale) continue "' // defines options conditional on activation of INITial; previous authors found that "search(norescale)" and "continue" improve convergence with INITial activated
		}
		
		* these distributions use a common evaluator file (namely, GGAMMA); constraints are applied to estimate special cases
		if inlist("`distribution'","weibull","gamma","ggamma") {
			local evaluator intllf_ggsigma`group'
			local params `" (delta: `depvar1' `depvar2' = `regs', `noconstant') (lnsigma: `sigma') (p: `p') "'
			
			if "`distribution'"=="weibull" {
				local title "{title:Interval Regression with Weibull Distribution}"
				constraint define 1 [p]_cons=1
				local const_list 1
			}
			else if "`distribution'"=="gamma" {
				local title "{title:Interval Regression with Gamma Distribution}"
				constraint define 1 [lnsigma]_cons=0
				local const_list 1
			}
			else if "`distribution'"=="ggamma" {
				local title "{title:Interval Regression with Generalized Gamma Distribution}"
			}
		}
		
		* these distributions use a common evaluator file (namely, GB2); constraints are applied in order to estimate special cases
		if inlist("`distribution'","br3","br12","gb2") {
			local evaluator intllf_gb2exp`group'
			local params `" (delta: `depvar1' `depvar2' = `regs', `noconstant') (lnsigma: `sigma' ) (p: `p') (q: `q') "'
			
			if "`distribution'"=="br3" {
				local title "{title:Interval Regression with Burr type 3 Distribution}"
				constraint define 1 [q]_cons=1
				local const_list 1
			}
			else if "`distribution'"=="br12" {
				local title "{title:Interval Regression with Burr type 12 Distribution}"
				constraint define 1 [p]_cons=1
				local const_list 1
			}
			if "`distribution'"=="gb2" {
				local title "{title:Interval Regression with Generalized Beta of the Second Kind Distribution}"
			}
		}
	}
	
	/* PERFORMS EVALUATION */
	local const_list `const_list' `constraints' // appends user's constraints to program constraints
	local max_opts `" `max_opts' constraints(`const_list') repeat(`repeat') title(`title') "' // appends options used by final evaluations
	
	ml model lf `evaluator' `params' [`weight' `exp'] if `touse', `max_opts' `init_opts'
	ml display, `neq'
	
	mat betas = e(b) // saves coefficient matrix for use in post-evaluation
	
	/* TRANSFORMS LAMBDA */
	local asterisk 0 // flag to print warning message regarding alpha/lambda
	if inlist("`distribution'","`sgt_tree'") {
		if "`lambda'"=="" { // homoskedastic lambda (_cons only)
			di "{res:lambda}       {c |}"
			
			if betas[1,"lambda:_cons"]==0 {
				table_line_zero "_cons" // reports constrained lambda
			}
			else { // transforms unconstrained lambda (from "alpha", see help file)
				* extracts alpha matrix from parameter matrix
				mat A = betas[1,"lambda:_cons"]
				mat A_SE = _se["lambda:_cons"]
				* extract constants and standard error from alpha matrix
				local alpha_c = A[1,1]
				local alpha_se = A_SE[1,1]
				* transforms alpha into lambda
				local lambda_c = (exp(`alpha_c')-1)/(exp(`alpha_c')+1)
				local lambda_se = `alpha_se'*(2*exp(`alpha_c')) / (exp(`alpha_c')+1)^2
				* calculates inference statistics
				local zscore = `lambda_c' / `lambda_se'
				local p = normal(-abs(`zscore'))
				local llimit = `lambda_c' + 1.96*`lambda_se'
				local ulimit = `lambda_c' - 1.96*`lambda_se'
				* display and ereturn							
				table_line "_cons" `lambda_c' `lambda_se' `zscore' `p' `ulimit' `llimit' 
			}
		}
		else { // heteroskedastic lambda (lambdavars and _cons) -- report untransformed alpha
		di "{res:alpha*}       {c |}"
			foreach var in `lambda' _cons {
				* extract alpha matrix from parameter matrix
				mat A_`var' = betas[1,"lambda:`var'"]
				mat A_SE_`var' = _se["lambda:`var'"]
				* extract constant and se from alpha matrix
				local alpha_`var' = A_`var'[1,1]
				local alpha_se_`var' = A_SE_`var'[1,1]
				* calculate inference statistics
				local zscore_`var' = alpha_`var' / alpha_se_`var'
				local p_`var' = normal(-abs(zscore_`var'))
				local llimit_`var' = alpha_`var' + 1.96*alpha_se_`var'
				local ulimit_`var' = alpha_`var' - 1.96*alpha_se_`var'
				* display and ereturn							
				table_line_alpha "`var'" `alpha_`var'' `alpha_se_`var'' ///
					`zscore_`var'' `p_`var'' `ulimit_`var'' `llimit_`var'' 
			}
		local asterisk 1 // activate flag to print warning message

		}
	di as text "{hline 13}{c BT}{hline 64}"
	}

	/* EXTRACTS ESTIMATED PARAMETERS at EYX for use in eyx, alt notation, aicbic, gini, plot */
	
	* /estimated params/	/distributions/
	* mu sigma		normal lnormal
	* mu sigma p lambda	snormal laplace slaplace ged sged
	* mu sigma p q lambda	t gt st sgt
	* delta sigma p		weibull gamma ggamma
	* delta sigma p q	br3 br12 gb2
	
	param_at_stat "lnsigma" `eyx'
	local _sigma = exp(r(result))
	
	if inlist("`distribution'","`sgt_tree'") | "`distribution'"=="normal" | "`distribution'"=="" | "`distribution'"=="lnormal" {
		
		param_at_stat "mu" `eyx'
		local _mu = r(result)
		
		if inlist("`distribution'","`sgt_tree'") {
			param_at_stat "p" `eyx'
			local _p = r(result)
			
			* Transform alpha into lambda 
			mat lambda = betas[1,"lambda:"]
			mata: st_matrix("explambda",exp(st_matrix("lambda")))
			mat explambd2 = explambda
			local ncols = colsof(explambda)
			forvalues j = 1/`ncols' {
				mat explambda[1,`j'] = explambda[1,`j']-1
				mat explambd2[1,`j'] = explambd2[1,`j']+1
			}
			mata: st_matrix("lambda", st_matrix("explambda") :/ st_matrix("explambd2"))
			mat betas[1,colnumb(betas,"lambda:")] = lambda 
			
			param_at_stat "lambda" `eyx'
			local _lambda = r(result)
			
			if inlist("`distribution'","t","gt","st","sgt") {
				param_at_stat "q" `eyx'
				local _q = r(result)
			}
		}
	}
	else { // gb2-tree excluding lnormal
	
		param_at_stat "delta" `eyx'
		local _delta = r(result) 
		
		param_at_stat "p" `eyx'
		local _p = r(result)
		
		if inlist("`distribution'","br3","br12","gb2") {
			param_at_stat "q" `eyx'
			local _q = r(result)
		}
		
		* alternate notation
		* add 'a' to betas and use param_at_stat 
		mat a = betas[1,"lnsigma:"]
		mat coleq a = "a"
		local ncols = colsof(a)
		forvalues j = 1/`ncols' {
			mat a[1,`j'] = 1/exp(a[1,`j'])
		}
		mat betas = betas, a
		param_at_stat "a" `eyx'
		local _a = r(result)

		* add 'b' to betas and use param_at_stat 
		mat b = betas[1,"delta:"]
		mat coleq b = "b"
		local ncols = colsof(b)
		forvalues j = 1/`ncols' {
			mat b[1,`j'] = exp(b[1,`j'])
		}
		mat betas = betas, b 
		param_at_stat "b" `eyx'
		local _b = r(result)
	}
	
	/* Opt EYX - CALCULATES CONDITIONAL EXPECTED VALUE AT SPECIFIED LEVEL */
	
	* check mean is defined
	local meandefined = 1 // trigger to only print warning if EYX not defined
	if inlist("`distribution'","br3","br12","gb2") {
		if `_q'<`_sigma' {
			di as res "E[Y|X]" as text " not defined where q>sigma; q=`_q' sigma=`_sigma'"
			di as text "{hline 78}"
			local meandefined = 0
		}
	}
	else if inlist("`distribution'","t","st","gt","sgt") {
		if `_p'*`_q'<1 {
			di as res "E[Y|X]" as text " not defined where q>1/p; q=`_q' 1/p=" 1/`_p'
			di as text "{hline 78}"
			local meandefined = 0
		}
	}
	
	* calculates eyx
	if `meandefined' { 
		* displays first line of eyx output
		if "`eyx'"=="" | "`eyx'"=="mean" { // spacing following "`eyx'" of length four
			local eyx "mean"
			di "{res:`eyx'}         {c |}" 
		}
		else if inlist("`eyx'","min","max","p10","p25","p50","p75","p90","p95","p99") {	// spacing following "`eyx'" of length three
			di "{res:`eyx'}          {c |}"
		}
		else if inlist("`eyx'","p1","p5") { // spacing following "`eyx'" of length two
			di "{res:`eyx'}           {c |}"
		}
		else {
			di as err "not a valid option for eyx"
			exit 498
		}
		
		if inlist("`distribution'","normal","") {
			scalar expected = `_mu'
		}
		else if inlist("`distribution'","`sgt_tree'") {
			
			if inlist("`distribution'","snormal","laplace","slaplace","ged","sged") {
				scalar expected = `_mu' + 2*`_lambda'*`_sigma'*(exp(lngamma(2/`_p'))/exp(lngamma(1/`_p')))
			}
			else if inlist("`distribution'","t","gt","st","sgt") {
				scalar expected = `_mu' + 2*`_lambda'*`_sigma'*((`_q'^(1/`_p'))*(exp(lngamma(2/`_p')+lngamma(`_q'-(1/`_p'))-lngamma((1/`_p')+`_q'))/exp(lngamma(1/`_p')+lngamma(`_q'))-lngamma((1/`_p')+`_q')))
			}
		}
		else if inlist("`distribution'","`gb2_tree'") {
			if "`distribution'"=="lnormal" {
				scalar expected = exp(`_mu'+(`_sigma'^2/2))
			}
			else {				
				if inlist("`distribution'","weibull","gamma","ggamma") {
					scalar expected = exp(`_delta')*((exp(lngamma(`_p'+`_sigma')))/(exp(lngamma(`_p'))))
				}
				else if inlist("`distribution'","br3","br12","gb2") {
					scalar expected = exp(`_delta')*((exp(lngamma(`_p'+`_sigma'))*exp(lngamma(`_q'-`_sigma')))/(exp(lngamma(`_p'))*exp(lngamma(`_q'))))
				}
			}
		}
		* prints eyx in output table format
		table_line "E[Y|X]" expected
		di as text "{hline 13}{c BT}{hline 64}"
	}

	/* PRINTS WARNING regarding untransformed lambda ("alpha") */
	if `asterisk' {
		di as text "*for a description of alpha/lambda, see model options in " in smcl "{help gintreg}" _n
	}
			
	/* REPORTS ALTERNATE NOTATION */
	di as txt "Alternate notation: "
	if inlist("`distribution'","`gb2_tree'") & "`distribution'"!="lnormal" {
		di as text "a: " `_a'
		di as text "beta: " `_b'
	}
	else {
		di as txt "sigma: " `_sigma'
	}
	
	/* Opt AICBIC - CALCULATES AND REPORTS AIC AND BIC */
	
	* 		AIC = 2k-2loglike
	* 		BIC = kln(n)-2loglike
	
	if "`aicbic'"!="" {
		if "`frequency'"!="" {
			di as err "option aicbic incompatible with grouped data"
			exit 498
		}
		else {
			* three ingredients: first, loglikelihood values
			scalar loglike = e(ll)
			
			* second, number of observations
			qui count if `touse'
			scalar nobs = r(N)
			
			* third, total number of estimated parameters
			scalar _k = colsof(betas)
			* correct for constrained parameters
			local nconstraints: word count `const_list'
			scalar _k = _k - `nconstraints'
			
			* perform calculations
			scalar _aic = 2*_k - 2*loglike
			scalar _bic = _k*ln(nobs) - 2*loglike
			
			* display and ereturn results
			di _n "AIC: " _aic
			di "BIC: " _bic
			ereturn scalar aic = _aic
			ereturn scalar bic = _bic
		}
	}
	
	/* Opt GINI - CALCULATES AND REPORTS GINI COEFFICIENTS */
	if "`gini'"!="" {
		if "`distribution'"=="weibull" {
			local gini_coef 1-(.5^(`_sigma'))
		}
		if "`distribution'"=="gamma" {
			local gini_coef exp(lngamma(`_p' + .5)) / (exp(lngamma(`_p' + 1)) * sqrt(_pi))
		}			
		else if "`distribution'"=="br3" {
			local gini_coef [exp(lngamma(`_p')) * exp(lngamma(2*`_p' + `_sigma'))] ///
											/ [exp(lngamma(`_p' + `_sigma')) * exp(lngamma(2*`_p'))] - 1
		}
		else if "`distribution'"=="br12" {
			local gini_coef 1 - [exp(lngamma(`_q')) * exp(lngamma(2*`_q' - `_sigma'))] ///
											/ [exp(lngamma(`_q' - `_sigma')) * exp(lngamma(2*`_q'))]
		}
		di _n "Gini coefficient: " `gini_coef'
	}
	
	/* Opt PLOT - PLOTS PDF */
	if "`plot'"!="" {
		
		* defines pdf function
		if "`distribution'"=="normal" | "`distribution'"=="" {
			local fn = `" y = normalden(x, `_mu', `_sigma') "'
		}
		else if inlist("`distribution'","snormal","laplace","slaplace","ged","sged") {
			local G = exp(lngamma(1/`_p')) // gamma function
			local fn = `" y = [`_p' * exp(-(abs(x-`_mu')^`_p' / ((1 + `_lambda'*sign(x-`_mu'))^`_p' * `_sigma'^`_p')))] / [2*`_sigma'*`G'] "'
		}
		else if inlist("`distribution'","t","gt","st","sgt") {
			local B = exp(lngamma(1/`_p')+lngamma(`_q')-lngamma(1/`_p' + `_q')) // beta function
			local fn = `"y = (`_p')/[(2*`_sigma'*`_q'^(1/`_p')*`B')*(1 + (abs(x-`_mu')^`_p')/(`_q'*`_sigma'^`_p'*(1 + `_lambda'*sign(x-`_mu'))^`_p'))^(`_q' + 1/`_p')] "'
		}
		else if "`distribution'" == "lnormal" {
			local fn = `" y = [exp(-(ln(x)-`_mu')^2 / 2 * `_sigma'^2)] / [sqrt(2*c(pi)) * x*`_sigma'] "'
		}
		if inlist("`distribution'","weibull","gamma","ggamma") {
			local G = exp(lngamma(`_p')) // gamma function
			local fn = `" y = (abs(`_a')*(x/`_b')^(`_a'*`_p')*exp(-(x/`_b')^`_a'))/(x*`G') "'
		}
		else if inlist("`distribution'","br3","br12","gb2") {
			local B = exp(lngamma(`_p')+lngamma(`_q')-lngamma(`_p'+`_q')) // beta function
			local fn = `" y = [abs(`_a') * (x/`_b')^(`_a'*`_p')] / [x*`B' * (1 + (x/`_b')^`_a')^(`_p'+`_q')] "'
		}
		
		* plots pdf
		twoway function `fn', range(`plot')
	}
	
	/* PRINTS COUNTS of data types */
	qui count if `touse'
	di _n as text "{res:`r(N)'} `count_type'" // total
	
	qui count if `depvar1'==. & `depvar2'!=. & `touse' // left censored
	di "{res:`r(N)'} left-censored `count_type'"	
	
	qui count if `depvar1'!=. & `depvar2'==. & `touse' // right censored
	di "{res:`r(N)'} right-censored `count_type'"
	
	qui count if `depvar1'!=. & `depvar2'!=. & `depvar1'==`depvar2' & `touse' // uncensored
	di "{res:`r(N)'} uncensored `count_type'"
	
	qui count if `depvar1'!=. & `depvar2'!=. & `depvar1'!=`depvar2' & `touse' // interval
	di "{res:`r(N)'} interval `count_type'"

	/* ERETURNS relevant information and cleans memory */
	qui ereturn list
	mat drop _all
	scalar drop _all
end

program table_line
	args vname coef se z p 95l 95h
	if (c(linesize) >= 100){
		local abname = "`vname'"
		}
	else if (c(linesize) > 80){
	local abname = abbrev("`vname'", 12+(c(linesize)-80))
	}
	else{
	local abname = abbrev("`vname'", 12)
	}
	local abname = abbrev("`vname'",12)
	display as text %12s "`abname'" " { c |}" /*
	*/ as result /*
	*/ "   " %8.0g `coef' "  " /*
	*/ %9.0g `se' "  " %7.2f `z' "  " /*
	*/ %6.3f `p' "    " %9.0g `95l' "   " /*
	*/ %9.0g `95h'
end

program table_line_alpha
	args vname coef se z p 95l 95h
	if (c(linesize) >= 100){
		local abname = "`vname'"
		}
	else if (c(linesize) > 80){
	local abname = abbrev("`vname'", 12+(c(linesize)-80))
	}
	else{
	local abname = abbrev("`vname'", 12)
	}
	local abname = abbrev("`vname'",12)
	display as text %12s "`abname'" " { c |}" /*
	*/ as result /*
	*/ "   " %8.0g `coef' "  " /*
	*/ %9.0g `se' "  " %7.2f `z' "  " /*
	*/ %6.3f `p' "    " %9.0g `95l' "   " /*
	*/ %9.0g `95h'
end

program table_line_zero
	args vname 
	if (c(linesize) >= 100){
		local abname = "`vname'"
		}
	else if (c(linesize) > 80){
	local abname = abbrev("`vname'", 12+(c(linesize)-80))
	}
	else{
	local abname = abbrev("`vname'", 12)
	}
	local abname = abbrev("`vname'",12)
	display as text %12s "`abname'" " { c |}" /*
	*/ "          " "{res:0}  (constrained)" " " 
end

program param_at_stat, rclass
	args paramname stat
	
	mat param = betas[1,"`paramname':"]
	local vars: colnames param 
	foreach var in `vars' {
		if "`var'"=="_cons" {
			capture mat stats = stats \ 1
			if _rc!=0 mat stats = 1
			continue 
		}
		qui summ `var', d 
		capture mat stats = stats \ r(`stat')
		if _rc!=0 mat stats = r(`stat')
	}
	
	mat result = param*stats 
	return scalar result = result[1,1]
	matrix drop param stats result
end

version 13.0
mata:
matrix function flipud(matrix X)
{
return(rows(X)>1 ? X[rows(X)..1,.] : X)
}
end

/*This ado file executes non-linear interval regressions where the error term is 
distributed in the GB2 or SGT family tree

Author--Jacob Orchard
v 1.4

******************************

Update for v 1.5 (5/19/2017) by Will Cockriel
1. Added repeat option 

******************************

Update for v 1.6 (1/12/2018) by Bryan Chia
1. Added no constant option
2. Changed the initial option to cases like the no constant option
3. Took out the limits on the number of initial parameters as it complicated stuff with heteroskedasticity 
4. Initially, I was thinking about having users put in only p,q, lambda if its heteroskedastic and 
   mu, sigma, p, q, lambda if it is homoskedastic. 
   I think that is probably too confusing so I standardized it. Decided to just have them put in p, q and lambda, 
   whichever is relevant. I edited the help file too. 
   Decided that if it is heteroskedastic though it is hard to know what sigma is 
   so that was my thoughts for why it would be good for them to just guess p, q and lambda.
   Mu and sigma is based on normal/ln values depending on what family the distribution is from. 
5. Edited some of the mean values that were incorrect 
6. We use an lnsigma now instead of sigma. All intllf files have been edited to exp(sigma) rather than sigma
   This is potentially confusing. Maybe I should change "sigma" to "lnsigma" for all the functions...
7. Edited nortolerance to nonrtolerance 
8. I took out the constant only ml optimization before the full model as there were some convergence issues
   Now, if they put in initial values, it will instead first optimize assuming the simplest distributions
   in each family, namely the lognormal and the normal and use those values as start values instead. 
9. Edited lambda to make it bounded between 0 to 1. Had to make some changes to transform what we call alpha
   back to lambda. 

******************************

Update for v 1.7 (3/27/2018) by Bryan Chia & Jonny Jensen
1. Fixed pdfs to allow better convergence for point estimates with sgt family
2. Point estimates - change sigma to exp(sigma) 
3. Add BIC and AIC 

******************************

Update for v 1.8 (5/22/2018) by Bryan Chia 
1. Changed it such that users can now specify the following distributions as well:
- for the SGT family: GT, ST, GED, SLaplace, T
- for the GB2 family: Br 12, Br3, Gamma 

******************************

Update for v 1.9 (06/21/2021) by Jacob Triplett
1. Fixed misidentified constraints for the Gamma and Weibull distributions
2. Corrected mechanism by which distribution defaults to Normal
3. BIC and AIC values are now returnable with e(BIC) and e(AIC) and are only
	displayed when option bicaic is specified and for gb2-tree distributions 
	and if data is non-grouped
4. Standardized output title formatting
5. The "ml display" table is now followed by alternate notation (a=1/sigma) 
	(beta=exp(delta)) (sigma=exp(lnsigma))
6. Initiated gini option, currently only coded for weibull, br3, br12
7. Conventionalized distribution input names to be consistent with what Stata's
	in-house programs use and trimmed superfluous labels (i.e. dropped "ln" when
	"lnormal" is also accepted and prefererred conventionally, changed "gg" to 
	"ggamma") 
8. Added plot option to vizualize pdf; works for all accepted distributions
9. Built a companion program, called 'pdfplot', to flexibly plot pdfs
10. Added these distributions: laplace, skewed normal ("snormal")
11. Corrected typo in pdf specification within inllf_lnormal.ado
12. Because of the nonlinear transformation to lambda reflected in update 1.6.9,
	only the constant was reported. Now, if lambda(varlist) is used, pre-
	transformation "alphas" are reported. See the help file for more info.
13. Updated help file to reflect changes and offer more detail

******************************

Update for v 2.0 (07/12/2022) by Jacob Triplett
1. gintreg has become incredibly advanced, adaptable and useful thanks to many 
	updates from Dr James B McDonald and his RAs. Though the program remained
	effective, under-the-hood, the code grew in complication and size to over 
	5000 lines. Nearly a year after beginning work on gintreg, I found I was 
	still in the process of understanding it thoroughly. I sought to create a 
	new edition of gintreg, following all best practices, that anyone could 
	comprehend in a single day, if not a single sitting. v2.0 is the result.
	v2.0 retains all previous functionality, adds far more instructive 
	commentary, and does so in about 625 lines. In the process, a few additional
	improvements (beyond rearranging & compressing) were made and are listed below
2. Facilitated accepting user-defined constraints in every setting; previously, 
	such constraints were ignored if the program also defined constraints 
3. Corrected AICBIC calculations with a simple, robust mechanism to count 
	estimated parameters; this replaced a long list of hard-coded equations
4. Reconfigured EYX code to operate correctly regardless of NOCONStant activation
5. EYX output is now printed as part of every estimation
6. Preserved extracted parameters by defining as locals rather than scalars; 
	otherwise the code might read "p" and interpret "price", for example,
	if price were a data variable's name
*/