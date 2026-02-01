*! 1.0.0 Ariel Linden 30Jan2026

capture program drop tau2ci
program define tau2ci, rclass
	version 11
	syntax [, Level(cilevel)]
    
	// check if meta regress was last estimation model
	if !inlist("`e(cmd)'", "meta regress") {
		di as error "{bf:tau2ci} will only work after {bf:meta regress} with the {bf:random} option"
		exit 301
	}
    
	// check if random-effects model was estimated
	if "`e(model)'" != "random" {
		di as error "{bf:tau2ci} will only work with a random-effects model"
		exit 198
	}
    
	local k = e(N)
	local tau2 = e(tau2)
	local stmethod = e(method)
    
	// map to method names for display
	if "`stmethod'" == "reml" local rmethod "restricted maximum likelihood"
	else if "`stmethod'" == "mle" local rmethod "maximum likelihood"
	else if "`stmethod'" == "dlaird" local rmethod "DerSimonian–Laird"
	else if "`stmethod'" == "ebayes" local rmethod "empirical Bayes"
	else if "`stmethod'" == "sjonkman" local rmethod "Sidik–Jonkman"
	else if "`stmethod'" == "hedges" local rmethod "Hedges"
	else if "`stmethod'" == "hschmidt" local rmethod "Hunter–Schmidt"
	else local rmethod "`stmethod'"
    
	// get moderator names
	matrix b = e(b)
	local p = colsof(b)
    
	foreach name in `:colnames b' {
		if "`name'" != "_cons" local xvars "`xvars' `name'"
	}
    
	// generate sample indicator
	tempvar esample
	gen byte `esample' = e(sample)
    
	// call Mata function to compute std err and CIs
	mata: compute_tau2_se("`esample'", "`xvars'", `tau2', `k', `p', "`rmethod'", "`stmethod'", `level')
    
	// get results
	local se_tau2 = r(se_tau2)
	local ci_lb = r(ci_lb)
	local ci_ub = r(ci_ub)
    
	// return values
	return scalar se = `se_tau2'
	return scalar tau2 = `tau2'
	return scalar ll = `ci_lb'
	return scalar ul = `ci_ub'
	return local method "`stmethod'"
    
	// display output table
	tempname mytab
	.`mytab' = ._tab.new, col(5) lmargin(0)
	.`mytab'.width    10   |11  12  12    12
	.`mytab'.titlefmt  .    .   . %24s   .
	.`mytab'.pad       .     1   1  3     3
	.`mytab'.numfmt    . %9.0g %9.0g %9.0g %9.0g
	.`mytab'.strcolor result  .  .  .  .
	.`mytab'.strfmt    %19s  .  .  .  .
	.`mytab'.strcolor   text  .  .  .  .
	.`mytab'.sep, top
	.`mytab'.titles ""								/// 1
					"Tau-sq"						/// 2
					"Std. Err."						/// 3
					"[`level'% Conf. Interval]" ""	// 4 5
	.`mytab'.sep, middle
	.`mytab'.strfmt    %24s  .  .  .  .
	.`mytab'.row    ""			///
					`tau2'		///
					`se_tau2'	///
					`ci_lb'	///
					`ci_ub'
	.`mytab'.sep, bottom
    
	// display method information below the table
	di as text "Random-effects method: " as result "`rmethod'"
    
end

// Mata function to compute std err and CIs
mata:
mata clear

void compute_tau2_se(string scalar esample, string scalar xvars,
					real scalar tau2, real scalar k, real scalar p,
					string scalar method, string scalar stmethod,
					real scalar level) {
    
	// get effect sizes and standard errors
	y = st_data(., "_meta_es", esample)
	se = st_data(., "_meta_se", esample)
	vi = se:^2
    
	// build X matrix (design matrix with intercept)
	X = J(k, 1, 1)
	if (xvars != "") {
		vars = tokens(xvars)
		for (i = 1; i <= cols(vars); i++) {
			X = X, st_data(., vars[i], esample)
		}
	}
    
	// ensure non-negative tau2
	if (tau2 < 0) tau2 = 0
    
	// calculate weights with estimated tau2 (for most methods)
	wi_tau = 1 :/ (vi :+ tau2)
    
	// DerSimonian-Laird method
	if (stmethod == "dlaird") {		
		wi = 1 :/ vi  // DL uses tau2=0 for weights
		W = diag(wi)
		stXWX = invsym(X' * W * X)
		P = W - W * X * stXWX * X' * W
		trP = trace(P)
		sum_P_sq = sum(P:*P)
		se = sqrt(1/trP^2 * (2*(k-p) + 4*max((tau2,0))*trP + 2*max((tau2,0))^2*sum_P_sq))
	}
    
	// Sidik-Jonkman method
	else if (stmethod == "sj") {		
		ymc = y :- mean(y)
		tau2_0 = variance(ymc) * (k-1)/k
		wi_sj = 1 :/ (vi :+ tau2_0)
		W_sj = diag(wi_sj)
		stXWX_sj = invsym(X' * W_sj * X)
		P_sj = W_sj - W_sj * X * stXWX_sj * X' * W_sj
		V = diag(vi)
		PV_sj = P_sj * V
		sum_P_sq_sj = sum(P_sj:*P_sj)
		sum_PV_PV_sj = sum(PV_sj:*PV_sj)
		sum_PV_P_sj = sum(PV_sj:*P_sj)
		se = sqrt(tau2_0^2/(k-p)^2 * (2*sum_PV_PV_sj + 4*max((tau2,0))*sum_PV_P_sj + 2*max((tau2,0))^2*sum_P_sq_sj))
	}
    
	// Hedges method
	else if (stmethod == "he") {	
		stXX = invsym(X' * X)
		P_he = I(k) - X * stXX * X'
		V = diag(vi)
		PV_he = P_he * V
		trPV_he = trace(PV_he)
		sum_PV_PV_he = sum(PV_he:*PV_he)
		se = sqrt(1/(k-p)^2 * (2*sum_PV_PV_he + 4*max((tau2,0))*trPV_he + 2*max((tau2,0))^2*(k-p)))
	}
    
	// Hunter-Schmidt method
	else if (stmethod == "hs") {	
		wi_hs = 1 :/ vi
		W_hs = diag(wi_hs)
		stXWX_hs = invsym(X' * W_hs * X)
		P_hs = W_hs - W_hs * X * stXWX_hs * X' * W_hs
		V = diag(vi)
		PV_hs = P_hs * V
		sum_P_sq_hs = sum(P_hs:*P_hs)
		sum_PV_PV_hs = sum(PV_hs:*PV_hs)
		sum_PV_P_hs = sum(PV_hs:*P_hs)
		sum_wi_hs = sum(wi_hs)
		se = sqrt(1/sum_wi_hs^2 * (2*sum_PV_PV_hs + 4*max((tau2,0))*sum_PV_P_hs + 2*max((tau2,0))^2*sum_P_sq_hs))
	}
    
	// Restricted Maximum Likelihood
	else if (stmethod == "reml") {	
		W = diag(wi_tau)
		stXWX = invsym(X' * W * X)
		P = W - W * X * stXWX * X' * W
		sum_P_sq = sum(P:*P)
		se = sqrt(2/sum_P_sq)
	}
    
	// Maximum Likelihood
	else if (stmethod == "mle") {	
		se = sqrt(2/sum(wi_tau:^2))
	}
    
	// Empirical Bayes
	else if (stmethod == "eb") {	
		se = sqrt(2*k^2/(k-p) / sum(wi_tau)^2)
	}
    
	// Default for unknown methods (added in the future?)
	else {
		se = sqrt(2/sum(wi_tau:^2))
	}
    
	// confidence interval using normal approximation (two-sided)
	alpha = (100 - level)/100
	z = invnormal(1 - alpha/2)
    
	ci_lb = tau2 - z * se
	ci_ub = tau2 + z * se
    
	// store results
	st_numscalar("r(se_tau2)", se)
	st_numscalar("r(tau2)", tau2)
	st_numscalar("r(ci_lb)", ci_lb)
	st_numscalar("r(ci_ub)", ci_ub)
}
end