*! version 1.0.0  2025-11-30
cap program drop regoptwgt
program regoptwgt
	version 13.1

	syntax anything(name=0) [aweight/] [if] [in], [ TECHnique(namelist) ITERate(real 300) CLuster(varlist) Robust ///
		DIFficult mlsearch(real -1) initnowgt jackknife ]
	
	* Read input
	_iv_parse `0'
	foreach optname in lhs exog endog inst {
		local `optname' = s(`optname')
		if "``optname''"=="." local `optname' 
	}
	
	* Weights are required
	if "`exp'"=="" {
		di as error "Error: Must include aweight."
		error 198
	}
	
	* Error options
	*  Note that option robust does nothing here - it is always used - but is allowed for compatability reasons
	if "`jackknife'"=="jackknife" & wordcount("`cluster'")>1 {
		di as error "Error: May not combine jackknife with multiway clustering"
	}
	local vceopt vce(robust)
	if "`cluster'"!="" local vceopt cluster(`cluster')
	
	* Set global for weight, which is needed for powerlawliklihood_* functions
	global powerlaw_wgt `exp'
	
	* Defaults
	if "`technique'"=="" local technique nr bhhh dfp bfgs
	
	* Check for errors
	if wordcount("`inst'")<wordcount("`endog'") {
		di as error "Error: Must be at least as many instruments as endogenous variables."
		error 198
	}
	
	* Run QML
	local mlmodeltext 
	local inittext 
	if wordcount("`endog'")==0 {
		if "`inst'"!="" {
			di as error "Error: Instruments not allowed if no other endogenous variables."
			error 198
		}
		
		*****
		* Choose starting values based on unweighted estimates
		if "`initnowgt'"=="" {
			qui reg `lhs' `exog'
			tempvar residlhs
			qui predict double `residlhs', resid
			local inittext `inittext' `lhs':_cons = `=_b[_cons]'
			foreach vname in `exog' {
				local inittext `inittext' `lhs':`vname' = `=_b[`vname']'
			}
			qui sum `residlhs'
			local lnrVar = ln(r(Var))
			local inittext `inittext' /lnetasq = `=`lnrVar'-10'
			local inittext `inittext' /lnnusq = `lnrVar'
		}
		*****
		
		local mlmodeltext ml model lf1 regoptwgt_loglik1endog (`lhs': `lhs' = `exog') /lnetasq /lnnusq `if' `in', ///
			tech(`technique') `vceopt'
		
	}
	else if wordcount("`endog'")==1 {
		
		*****
		* Choose starting values based on unweighted estimates
		if "`initnowgt'"=="" {
			* Eq: lhs
			qui ivregress liml `lhs' (`endog' = `inst') `exog'
			tempvar residlhs
			qui predict double `residlhs', resid
			local inittext `inittext' `lhs':_cons = `=_b[_cons]'
			foreach vname in `endog' `exog' {
				local inittext `inittext' `lhs':`vname' = `=_b[`vname']'
			}
			qui sum `residlhs'
			local lnrVar = ln(r(Var))
			local inittext `inittext' /lnetasq_`lhs' = `=`lnrVar'-10'
			local inittext `inittext' /lnnusq_`lhs' = `lnrVar'
			
			* Eq: endog
			qui reg `endog' `inst' `exog'
			tempvar residendog
			qui predict double `residendog', resid
			local inittext `inittext' `endog':_cons = `=_b[_cons]'
			foreach vname in `inst' `exog' {
				local inittext `inittext' `endog':`vname' = `=_b[`vname']'
			}
			qui sum `residendog'
			local lnrVar = ln(r(Var))
			local inittext `inittext' /lnetasq_`endog' = `=`lnrVar'-10'
			local inittext `inittext' /lnnusq_`endog' = `lnrVar'
			
			* Correlation
			local inittext `inittext' /fncorreta = 0
			qui corr `residlhs' `residendog'
			local inittext `inittext' /fncorrnu = `=logit((r(rho)+1)/2)'
		}
		*****
		
		local mlmodeltext ml model lf1 regoptwgt_loglik2endog ///
			(`lhs': `lhs' = `endog' `exog') /lnetasq_`lhs' /lnnusq_`lhs' ///
			(`endog': `endog' = `inst' `exog') /lnetasq_`endog' /lnnusq_`endog' ///
			/fncorreta /fncorrnu `if' `in', ///
			tech(`technique') `vceopt'
		
	}
	else {
		global powerlaw_numendog = 1 + wordcount("`endog'")
		
		*****
		* Choose starting values based on unweighted estimates
		if "`initnowgt'"=="" {
			* Eq: lhs
			qui ivregress liml `lhs' (`endog' = `inst') `exog'
			tempvar residlhs
			qui predict double `residlhs', resid
			local inittext `inittext' `lhs':_cons = `=_b[_cons]'
			foreach vname in `endog' `exog' {
				local inittext `inittext' `lhs':`vname' = `=_b[`vname']'
			}
			qui sum `residlhs'
			local lnrVar = ln(r(Var))
			local inittext `inittext' /lnetasq_`lhs' = `=`lnrVar'-10'
			local inittext `inittext' /lnnusq_`lhs' = `lnrVar'
			
			* Eq: endog
			forvalues i = 1/`=wordcount("`endog'")' {
				local currendog = word("`endog'",`i')
				qui reg `endog' `inst' `exog'
				tempvar resid_`i'
				qui predict double `resid_`i'', resid
				local inittext `inittext' `currendog':_cons = `=_b[_cons]'
				foreach vname in `inst' `exog' {
					local inittext `inittext' `currendog':`vname' = `=_b[`vname']'
				}
				qui sum `resid_`i''
				local lnrVar = ln(r(Var))
				local inittext `inittext' /lnetasq_`currendog' = `=`lnrVar'-10'
				local inittext `inittext' /lnnusq_`currendog' = `lnrVar'
			}
			
			* Correlation
			forvalues i=1/${powerlaw_numendog} {
			forvalues j=`=`i'+1'/${powerlaw_numendog} {
				local inittext `inittext' /fceta_`=word("`lhs' `endog'",`i')'_`=word("`lhs' `endog'",`j')' = 0
				qui corr `=word("`lhs' `endog'",`i')' `=word("`lhs' `endog'",`j')'
				local inittext `inittext' /fcnu_`=word("`lhs' `endog'",`i')'_`=word("`lhs' `endog'",`j')' = `=logit((r(rho)+1)/2)'
			}
			}
		}
		*****
		
		local modeltext (`lhs': `lhs' = `endog' `exog') /lnetasq_`lhs' /lnnusq_`lhs'
		forvalues i = 1/`=wordcount("`endog'")' {
			local currendog = word("`endog'",`i')
			local modeltext `modeltext' (`currendog': `currendog' = `inst' `exog') ///
				/lnetasq_`currendog' /lnnusq_`currendog'
		}
		forvalues i=1/${powerlaw_numendog} {
		forvalues j=`=`i'+1'/${powerlaw_numendog} {
			local modeltext `modeltext' /fceta_`=word("`lhs' `endog'",`i')'_`=word("`lhs' `endog'",`j')'
			local modeltext `modeltext'  /fcnu_`=word("`lhs' `endog'",`i')'_`=word("`lhs' `endog'",`j')'
		}
		}
		local mlmodeltext ml model lf1 regoptwgt_loglik3plusendog `modeltext' `if' `in', tech(`technique') `vceopt'
		
	}
	
	if wordcount("`cluster'")<=1 & "`jackknife'"=="" {
		`mlmodeltext'
		ml init `inittext'
		
		* Find the maximum, using options specified
		if `mlsearch'>=0 {
			ml search, repeat(`mlsearch')
		}
		ml maximize, iter(`iterate') `difficult'
	}
	else if  wordcount("`cluster'")>1 {
		local repeattext 
		if `mlsearch'>=0 {
			local repeattext repeat(`mlsearch')
		}
		vcemway `mlmodeltext' maximize init(`inittext') iter(`iterate') `difficult' `repeattext'
		ml display
	}
	else {
		local repeattext 
		if `mlsearch'>=0 {
			local repeattext repeat(`mlsearch')
		}
		jackknife, eclass: `mlmodeltext' maximize init(`inittext') iter(`iterate') `difficult' `repeattext'
		ml display
	}
	
end // program regoptwgt
