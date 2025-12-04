
cap program drop regoptwgt_loglik2endog
program regoptwgt_loglik2endog
	
	local paramlist xb1 lnetasq1 lnnusq1 xb2 lnetasq2 lnnusq2 fncorreta fncorrnu
	foreach currparam in `paramlist' {
		local arglist `arglist' g_`currparam'
	}
	
	args todo b lnf `arglist'
	tempvar `paramlist'
	
	local eqnum 1
	foreach currparam in `paramlist' {
		mleval ``currparam'' = `b', eq(`eqnum')
		local ++eqnum
	}
	
	* Variance of error term, taking into account any extreme heteroskedasticity
	forvalues i = 1/2 {
		local sigsq`i' ((${powerlaw_wgt})^(-1) * exp(`lnetasq`i'') + exp(`lnnusq`i''))
	}
	
	* Set up matrices
	forvalues i = 1/2 {
		local gbmat_`i' (${ML_y`i'} - `xb`i'')
	}
	
	* Useful intermediate steps
	local sigmat_1_2 ( ((${powerlaw_wgt})^(-1) * sqrt(exp(`lnetasq1')*exp(`lnetasq2')) * (2*invlogit(`fncorreta')-1)) ///
		+ sqrt(exp(`lnnusq1')*exp(`lnnusq2')) * (2*invlogit(`fncorrnu')-1) )
	local matdeterm ((`sigsq1')*(`sigsq2') - (`sigmat_1_2')^2)
	local deriv_sig_eta1 ((${powerlaw_wgt})^(-1)*exp(`lnetasq1'))
	local deriv_sig_eta2 ((${powerlaw_wgt})^(-1)*exp(`lnetasq2'))
	local deriv_sig_nu1  exp(`lnnusq1')
	local deriv_sig_nu2  exp(`lnnusq2')
	local deriv_sigmat12_eta1 ((${powerlaw_wgt})^(-1) * sqrt(exp(`lnetasq2')) * (2*invlogit(`fncorreta')-1) * .5 * sqrt(exp(`lnetasq1')))
	local deriv_sigmat12_eta2 ((${powerlaw_wgt})^(-1) * sqrt(exp(`lnetasq1')) * (2*invlogit(`fncorreta')-1) * .5 * sqrt(exp(`lnetasq2')))
	local deriv_sigmat12_nu1 (sqrt(exp(`lnnusq2')) * (2*invlogit(`fncorrnu')-1) * .5 * sqrt(exp(`lnnusq1')))
	local deriv_sigmat12_nu2 (sqrt(exp(`lnnusq1')) * (2*invlogit(`fncorrnu')-1) * .5 * sqrt(exp(`lnnusq2')))
	local deriv_sigmat12_correta ( (${powerlaw_wgt})^(-1) * sqrt(exp(`lnetasq1')*exp(`lnetasq2')) * 2 * invlogit(`fncorreta')*(1-invlogit(`fncorreta')) )
	local deriv_sigmat12_corrnu ( sqrt(exp(`lnnusq1')*exp(`lnnusq2')) * 2 * invlogit(`fncorrnu')*(1-invlogit(`fncorrnu')) )
	local matdeterm_deriv_eta1 ((`sigsq2')*(`deriv_sig_eta1') - 2*(`sigmat_1_2')*(`deriv_sigmat12_eta1'))
	local matdeterm_deriv_eta2 ((`sigsq1')*(`deriv_sig_eta2') - 2*(`sigmat_1_2')*(`deriv_sigmat12_eta2'))
	local matdeterm_deriv_nu1  ((`sigsq2')*(`deriv_sig_nu1')  - 2*(`sigmat_1_2')*(`deriv_sigmat12_nu1'))
	local matdeterm_deriv_nu2  ((`sigsq1')*(`deriv_sig_nu2')  - 2*(`sigmat_1_2')*(`deriv_sigmat12_nu2'))
	local matdeterm_deriv_correta ( -2*(`sigmat_1_2')*(`deriv_sigmat12_correta') )
	local matdeterm_deriv_corrnu  ( -2*(`sigmat_1_2')*(`deriv_sigmat12_corrnu') )
	
	* Calculate inv(sigmat)
	local invsigmat_1_1 (1/(`matdeterm')*`sigsq2')
	local invsigmat_2_2 (1/(`matdeterm')*`sigsq1')
	local invsigmat_1_2 (-1/(`matdeterm')*(`sigmat_1_2'))
	local invsigmat_2_1 `invsigmat_1_2'
	
	* Calculate gbmat' * inv(sigmat)
	forvalues i = 1/2 {
		local intermediatemat_`i' 0
		forvalues j = 1/2 {
			local intermediatemat_`i' `intermediatemat_`i'' + (`gbmat_`j'')*(`invsigmat_`i'_`j'')
		}
	}
	
	* Calculate (gbmat' * sigmat) * gbmat
	local finalmat 0
	forvalues i = 1/2 {
		local finalmat `finalmat' + (`intermediatemat_`i'') * (`gbmat_`i'')
	}
	
	qui replace `lnf' = -.5 * ln(`matdeterm') - .5 * (`finalmat')
	if (`todo'==0) exit
	
	qui replace `g_xb1' = 1 * (`intermediatemat_1')
	qui replace `g_xb2' = 1 * (`intermediatemat_2')
	
	forvalues i = 1/2 {
	foreach currerr in eta nu {
		local othernum = 3-`i'
		qui replace `g_ln`currerr'sq`i'' = -1/2 * 1/(`matdeterm') * (`matdeterm_deriv_`currerr'`i'') ///
			- 1/2 * ( (-1)*(`matdeterm')^(-1) * (`matdeterm_deriv_`currerr'`i'') * (`finalmat') ///
				+ (`matdeterm')^(-1)*( (`gbmat_`othernum'')^2*(`deriv_sig_`currerr'`i'') + ///
					-2*(`gbmat_1')*(`gbmat_2')*(`deriv_sigmat12_`currerr'`i'') ) )
	}
	}
	
	foreach currerr in eta nu {
		qui replace `g_fncorr`currerr'' = -1/2 * 1/(`matdeterm') * (`matdeterm_deriv_corr`currerr'') ///
			-1/2 * ( (-1)*(`matdeterm')^(-1) * (`matdeterm_deriv_corr`currerr'') * (`finalmat') ///
				+ (`matdeterm')^(-1)*(-1)*2*(`gbmat_1')*(`gbmat_2')*(`deriv_sigmat12_corr`currerr'') )
	}
	
end // program regoptwgt_loglikendog2
