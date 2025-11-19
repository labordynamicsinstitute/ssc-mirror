*! 1.0.0 Ariel Linden 12Nov2025

program define power_cmd_abk, rclass
    version 16.0

	syntax , [				///
		N(integer -1)		/// number of subjects
		PHASes(integer -1)	/// number of phase repetitions
		Mobs(integer -1)	/// number of observations per phase
		Delta(real -1)		/// effect size
		ICC(real -1)		/// intraclass correlation
		Phi(real -1)		/// autocorrelation
		Alpha(real 0.05)	/// alpha
		POWer(real -1)		/// power
		ONESIDed]			//
		

		// check for missing required parameters
		foreach param in phases mobs icc phi {
			if ``param'' == -1 {
				di as error "{bf: `param'()} is required"
				exit 198
			}
		}
		
		// count missing options
		local missing_count = 0
		local missing_params
		foreach param in n delta power {
			if ``param'' == -1 {
				local missing_count = `missing_count' + 1
				local missing_params "`missing_params' `param'"
			}
		}
		local missing_params = trim("`missing_params'")

		// check for all target parameters specified
		if `power' != -1 & `n' != -1 & `delta' != -1 {
			di as error "Power, N, and delta are all specified. Leave one blank."
			exit 198
		}

		// Check phases (number of phase repetitions)
		if `phases' != -1 {
			if `phases' <= 1 | `phases' != int(`phases') {
				di as error "{bf:phases} must be an integer greater than 1"
				exit 198
			}
		}
    
		// Check n (number of subjects)  
		if `n' != -1 {
			if `n' <= 1 | `n' != int(`n') {
				di as error "{bf:n} must be an integer greater than 1"
				exit 198
			}
		}
    
		// check mobs (observations per phase per subject)
		if `mobs' != -1 {
			if `mobs' <= 1 | `mobs' != int(`mobs') {
				di as error "{bf:mobs} must be an integer greater than 1"
				exit 198
			}
		}
    
		// check phi (autocorrelation)
		if `phi' != -1 {
			if `phi' <= -1 | `phi' >= 1 {
				di as error "{bf:phi} must be between -0.99 and 0.99, inclusive"
				exit 198
			}
		}
    
		// check icc (intraclass correlation)
		if `icc' != -1 {
			if `icc' <= 0 | `icc' >= 1 {
				di as error "{bf:icc} must be between 0 and 0.99, inclusive"
				exit 198
			}
		}
    
		// check delta (effect size)
		if `delta' != -1 {
			if `delta' < 0 {
				di as error "{bf:delta} must be greater than or equal to 0"
				exit 198
			}
		}
    
		// check alpha (type 1 error rate)
		if `alpha' <= 0 | `alpha' >= 1 {
			di as error "{bf:alpha} must be between 0 and 1, exclusive"
			exit 198
		}
    
		// check power
		if `power' != -1 {
			if `power' < 0 | `power' > 1 {
				di as error "{bf:power} must be between 0 and 1, inclusive"
				exit 198
			}
		}

		// adjust alpha for two-sided test
		if "`onesided'" == "" {
			local alpha_adj = `alpha' / 2
			local test_type "Two-sided"			
		}
		else {
			local alpha_adj = `alpha'
			local test_type "One-sided"	
		}
  
		// determine which parameter to solve for
		if `missing_count' == 1 {
			// One parameter missing - solve for it
			local solve_for = word("`missing_params'", 1)
        
			// compute power (N and delta specified)
			if "`solve_for'" == "power" {
				local mode "power"
				mata: calculate_power_wrapper(`n', `phases', `mobs', `delta', `icc', `phi', `alpha_adj')
				local result = r(power)
			}
            // solve for number of subjects (delta and power specified)			
			else if "`solve_for'" == "n" {
				local mode "solve"
				mata: solve_for_n(`phases', `mobs', `delta', `icc', `phi', `alpha_adj', `power')
				local result = r(n_solved)
			}
			// solve for effect size (N and power specified)			
			else if "`solve_for'" == "delta" {
				local mode "solve"
				mata: solve_for_delta(`n', `phases', `mobs', `icc', `phi', `alpha_adj', `power')
				local result = r(delta_solved)
			}
			// for future consideration
			else {
				di as error "solving for {bf:`solve_for'} is not yet implemented"
				exit 198
			}
		}
        // multiple parameters missing	
		else {
			di as error "one of the following parameters is missing: {bf:`missing_params'}"
			exit 198
		}
  
		// save results
		if `n' == -1 {
			return scalar N = r(n_solved)
		}
		else return scalar N = `n'

		if `power' == -1 {
			return scalar power = r(power)
		}
		else return scalar power = `power'
		
		if `delta' == -1 {
			return scalar delta = r(delta_solved)
		}
		else return scalar delta = `delta'
		return scalar alpha = `alpha'
		return scalar phases = `phases'	
		return scalar mobs = `mobs'
		return scalar icc = `icc'
		return scalar phi = `phi'		
		return scalar onesided = ("`onesided'" != "")
		return local solve_for = "`solve_for'"

end

version 16.0
mata:

// utility function to calculate trace of a matrix
real scalar trace(real matrix X) {

	real scalar n, tr, i
	n = rows(X)
	if (n != cols(X)) {
		_error(3200, "Matrix must be square for trace calculation")
	}
	tr = 0
	for (i = 1; i <= n; i++) {
		tr = tr + X[i, i]
	}
	return(tr)
}

// create A matrix row for error term calculation
real matrix ARow(real scalar phases, real scalar n, real scalar mobs, 
	real scalar phi, real scalar tau2, real scalar s2,
	real scalar row) {
    
	real matrix one, Ablock, Oblock, BR
	real scalar j, limit, LL, UL
    
	one = J(mobs, 1, 1)
	Ablock = I(mobs) - one * one' / mobs
	Oblock = J(mobs, mobs, 0)
    
	BR = Ablock
	limit = 2 * phases * n
    
	for (j = 1; j <= limit; j++) {
		if (j == row) {
			BR = BR, Ablock
		}
		else {
			BR = BR, Oblock
		}
	}
    
	LL = mobs + 1
	UL = 2 * phases * n * mobs + mobs
	BR = BR[|1, LL \ ., UL|]
	return(BR)
}

// create full A matrix
real matrix A(real scalar phases, real scalar n, real scalar mobs,
	real scalar phi, real scalar tau2, real scalar s2) {
    
	real matrix A_mat
	real scalar i, limit
    
	// check matrix size to prevent memory issues
	if (2 * phases * n * mobs > 1000) {
		_error(498, "Matrix dimensions too large - reduce phases, n, or mobs")
	}
    
	limit = 2 * phases * n
	A_mat = ARow(phases, n, mobs, phi, tau2, s2, 1)
    
	for (i = 2; i <= limit; i++) {
		A_mat = A_mat \ ARow(phases, n, mobs, phi, tau2, s2, i)
	}
	return(A_mat)
}

// create covariance matrix row
real matrix CovYRow(real scalar phases, real scalar n, real scalar mobs,
	real scalar phi, real scalar tau2, real scalar s2,
	real scalar row) {
    
	real matrix Block, BR
	real scalar j, limit, LL, UL
    
	Block = I(mobs)
	BR = Block * s2 + Block * tau2
	limit = 2 * phases * n
    
	for (j = 1; j <= limit; j++) {
		BR = BR, ((s2 / (1 - phi^2)) * (phi^abs(j - row)) * Block + Block * tau2)
	}
    
	LL = mobs + 1
	UL = 2 * phases * n * mobs + mobs
	BR = BR[|1, LL \ ., UL|]
	return(BR)
}

// create full covariance matrix
real matrix CovY(real scalar phases, real scalar n, real scalar mobs,
	real scalar phi, real scalar tau2, real scalar s2) {
    
	real matrix R
	real scalar i, limit
    
	// check matrix size
	if (2 * phases * n * mobs > 1000) {
		_error(498, "Covariance matrix dimensions too large")
	}
    
	limit = 2 * phases * n
	R = CovYRow(phases, n, mobs, phi, tau2, s2, 1)
    
	for (i = 2; i <= limit; i++) {
		R = R \ CovYRow(phases, n, mobs, phi, tau2, s2, i)
	}
	return(R)
}

// calculate B (expected mean square)
real scalar B(real scalar phases, real scalar n, real scalar mobs,
	real scalar phi, real scalar tau2, real scalar s2) {
    
	real scalar E
	real matrix A_mat, CovY_mat
    
	A_mat = A(phases, n, mobs, phi, tau2, s2)
	CovY_mat = CovY(phases, n, mobs, phi, tau2, s2)
    
	E = trace(A_mat * CovY_mat) / (2 * phases * n * (mobs - 1) * (s2 + tau2))
	return(E)
}

// calculate C (variance of mean square)
real scalar Cee(real scalar phases, real scalar n, real scalar mobs,
	real scalar phi, real scalar tau2, real scalar s2) {
    
	real scalar V
	real matrix A_mat, CovY_mat, AC, ACAC
    
	A_mat = A(phases, n, mobs, phi, tau2, s2)
	CovY_mat = CovY(phases, n, mobs, phi, tau2, s2)
	AC = A_mat * CovY_mat
	ACAC = AC * AC
    
	V = 2 * trace(ACAC) / (2 * phases * n * (mobs - 1) * (s2 + tau2))^2
	return(V)
}

// calculate degrees of freedom using Satterthwaite approximation
real scalar h_func(real scalar phases, real scalar n, real scalar mobs,
	real scalar phi, real scalar tau2, real scalar s2) {
    
	real scalar h_val, b_val, c_val
    
	b_val = B(phases, n, mobs, phi, tau2, s2)
	c_val = Cee(phases, n, mobs, phi, tau2, s2)
    
	// prevent division by zero
	if (c_val <= 0) {
		h_val = 2 * phases * n * (mobs - 1)  // use standard df as fallback
	}
	else {
		h_val = 2 * (b_val^2) / c_val
	}
    return(h_val)
}

// main power calculation function
real scalar calculate_power(real scalar n, real scalar phases, real scalar mobs,
	real scalar delta, real scalar icc, real scalar phi,
	real scalar alpha) {
    
	real scalar tau2, sigma2, nobs
	real matrix Contrast, R, Sigma
	real scalar i, j, idx, VD, a_val, b_val, c_val, h_val, L
	real scalar crit_f, power_f
    
	// input validation
	if (n < 2 | phases < 2 | mobs < 2) {
		return(.)
	}
	if (icc <= 0 | icc >= 1 | phi <= -1 | phi >= 1 | alpha <= 0 | alpha >= 1) {
		return(.)
	}
    
	nobs = 2 * phases * mobs
	tau2 = icc
	sigma2 = 1 - icc

	// construct contrast vector - FIXED: proper indexing
	Contrast = J(nobs, 1, 0)
	for (i = 1; i <= phases; i++) {
		// A phases (positive contrast)
		for (j = 1; j <= mobs; j++) {
			idx = (i-1)*2*mobs + j
			if (idx <= nobs) {
				Contrast[idx,1] = 1/(phases*mobs)
			}
		}
		// B phases (negative contrast)  
		for (j = 1; j <= mobs; j++) {
			idx = (i-1)*2*mobs + mobs + j
			if (idx <= nobs) {
				Contrast[idx,1] = -1/(phases*mobs)
			}
		}
	}

	// AR(1) correlation matrix
	R = J(nobs, nobs, 0)
	for (i = 1; i <= nobs; i++) {
		for (j = 1; j <= nobs; j++) {
			R[i,j] = phi^(abs(i-j))
		}
	}

	// covariance matrix
	Sigma = (sigma2 / (1 - phi^2)) :* R :+ J(nobs, nobs, tau2)

	// variance of contrast
	VD = (Contrast' * Sigma * Contrast)[1,1] / n
	a_val = VD / sigma2

	// calculate b, c, and h
	b_val = B(phases, n, mobs, phi, tau2, sigma2)
	c_val = Cee(phases, n, mobs, phi, tau2, sigma2)
	h_val = h_func(phases, n, mobs, phi, tau2, sigma2)

	// check for valid values
	if (missing(b_val) | missing(c_val) | missing(h_val) | h_val <= 0) {
		return(.)
	}

	// non-centrality parameter
	L = (b_val / a_val) * (delta^2)

	// critical F-value and power
	crit_f = invFtail(1, h_val, alpha)
	power_f = nFtail(1, h_val, L, crit_f)
    
	return(power_f)
}

// wrapper to return power to Stata
void calculate_power_wrapper(real scalar n, real scalar phases, real scalar mobs,
	real scalar delta, real scalar icc, real scalar phi,
	real scalar alpha) {
    
	real scalar power_val
	power_val = calculate_power(n, phases, mobs, delta, icc, phi, alpha)
	st_numscalar("r(power)", power_val)
}

// solver for sample size N using binary search
void solve_for_n(real scalar phases, real scalar mobs, real scalar delta,
	real scalar icc, real scalar phi, real scalar alpha,
	real scalar target_power) {
    
	real scalar n_low, n_high, n_mid, power_low, power_high, power_mid
	real scalar tolerance, max_iter, iter
    
    tolerance = 1e-4
    max_iter = 50
    
	// first, find reasonable bounds
	n_low = 2
	power_low = calculate_power(n_low, phases, mobs, delta, icc, phi, alpha)
    
	// if even the minimum doesn't reach power, return 2
	if (power_low >= (target_power - tolerance)) {
		st_numscalar("r(n_solved)", n_low)
		return
	}
    
	// find an upper bound
	n_high = 2
	power_high = power_low
    
	while (power_high < (target_power - tolerance) & n_high <= 1000) {
		n_high = n_high * 2
		if (n_high > 1000) {
			n_high = 1000
			power_high = calculate_power(n_high, phases, mobs, delta, icc, phi, alpha)
			break
		}
		power_high = calculate_power(n_high, phases, mobs, delta, icc, phi, alpha)
	}
    
	// if even the maximum doesn't reach power, return the max
	if (power_high < (target_power - tolerance)) {
		st_numscalar("r(n_solved)", n_high)
		return
	}
    
	// binary search for optimal n
	iter = 0
	while (n_high - n_low > 1 & iter < max_iter) {
		n_mid = floor((n_low + n_high) / 2)
		power_mid = calculate_power(n_mid, phases, mobs, delta, icc, phi, alpha)
        
		if (power_mid >= (target_power - tolerance)) {
			n_high = n_mid
			power_high = power_mid
		}
		else {
			n_low = n_mid
			power_low = power_mid
		}
		iter = iter + 1
	}
    
	// return the smallest n that meets or exceeds target power
	power_low = calculate_power(n_low, phases, mobs, delta, icc, phi, alpha)
	if (power_low >= (target_power - tolerance)) {
		st_numscalar("r(n_solved)", n_low)
	}
	else {
		st_numscalar("r(n_solved)", n_high)
	}
}

// solve for effect size delta
void solve_for_delta(real scalar n, real scalar phases, real scalar mobs,
	real scalar icc, real scalar phi, real scalar alpha,
	real scalar target_power) {
    
	real scalar delta, current_power
	real scalar tolerance, max_delta, step
    
	tolerance = 1e-4
	max_delta = 10  // maximum effect size to search
	step = 0.001    // step size for search
    
	// search from delta=0 upwards
	for (delta = 0; delta <= max_delta; delta = delta + step) {
		current_power = calculate_power(n, phases, mobs, delta, icc, phi, alpha)
        
		if (current_power >= (target_power - tolerance)) {
			st_numscalar("r(delta_solved)", delta)
			return
		}
	}
	st_numscalar("r(delta_solved)", max_delta)
}
end