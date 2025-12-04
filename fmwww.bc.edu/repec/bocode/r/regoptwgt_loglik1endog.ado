

cap program drop regoptwgt_loglik1endog
program regoptwgt_loglik1endog
	
	args todo b lnf g_xb g_lnetasq g_lnnusq
	
	tempvar xb lnetasq lnnusq
	mleval `xb' = `b', eq(1)
	mleval `lnetasq' = `b', eq(2)
	mleval `lnnusq' = `b', eq(3)
	
	* Variance of error term, taking into account any extreme heteroskedasticity
	local sigsq ((${powerlaw_wgt})^(-1) * exp(`lnetasq') + exp(`lnnusq'))
	
	* Calculate objective function
	qui replace `lnf' = -.5 * ln(`sigsq') - .5 / (`sigsq') * (${ML_y1} - `xb')^2
	if (`todo'==0) exit
	
	* Derivatives
	qui replace `g_xb' = 1 / (`sigsq') * (${ML_y1} - `xb')
	qui replace `g_lnetasq' = -.5 * (`sigsq')^(-1) * (${powerlaw_wgt})^(-1) * exp(`lnetasq') ///
		+ .5 * (${ML_y1} - `xb')^2 * (`sigsq')^(-2) * (${powerlaw_wgt})^(-1) * exp(`lnetasq')
	qui replace `g_lnnusq' = -.5 * (`sigsq')^(-1) * exp(`lnnusq') ///
		+ .5 * (${ML_y1} - `xb')^2 * (`sigsq')^(-2) * exp(`lnnusq')
	
end // program regoptwgt_loglikendog1
