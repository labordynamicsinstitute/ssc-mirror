// Package for weak-IV test (Daniel J. Lewis and Karel Mertens (2022))
// Author: Lingyun ZHOU
// This version: 03/29/2024

cap program drop weakivtest2
program weakivtest2, rclass
	version 17

	syntax [, level(cilevel) 		///
			  tau(real 0.1) 		///
			  points(real 1000)		///
			  fast					///
			  record				///
		   ]
	
	* If "avar" command is not installed in user's computer, display the error message.
	capture which avar
	if _rc==111 {
		di as err `"User contributed command avar is needed to run weakivtest. Install avar by typing "ssc install avar"."'
		exit
	}
	
	* weakivtest2 is a postestimation command to ivreg2 or xtivreg2; otherwise display error message.
	if (("`e(cmd)'" != "ivreg2") & ("`e(cmd)'" != "xtivreg2")) {
		di as err `"Weakivtest is a postestimation command after running ivreg2 or xtivreg2."'
		exit
	}
	else if (("`e(cmd)'" == "xtivreg2") & ("`e(xtmodel)'" != "fe")) {
		di as err "Weakivtest is a postestimation command after running xtivreg2 only with fixed effects."
		exit
	}
	loc ivcmd `e(cmd)'
	
	local alpha = 1 - `level' / 100

	* Hold and copy ereturn list
	tempname myereturn
    _estimates hold  `myereturn' , copy
	
	* Use observations from e(sample).
	tempvar touse
	gen byte `touse' = e(sample)
    
	* Use weights
	if ("`e(wtype)'" != "") local addweight "[`e(wtype)'`e(wexp)']"
	
	* Use only simplified version
	if ("`fast'" != "") loc fast = 1
	else loc fast = 0
	
	* Record the iteration
	if ("`record'" != "") loc record = 1
	else loc record = 0
	
	* Check for noconst_flag
	local noconst_flag = ( "`e(constant)'"=="noconstant") | ( "`e(cons)'"=="0")
	
	* Save ereturn results
	local K = e(exexog_ct) // Excluded Instrumental Variables
	local L = e(inexog_ct) // Exogenous Regressors
	if ("`ivcmd'" == "xtivreg2") local L = `L' + e(N_g)
	else if ( `noconst_flag' == 0) local L = `L' + 1
	local N = e(endog_ct)  // Endogenous Regressors
	local S = e(N)
	if strpos("`e(vce)'","bw"){
		local vcet=regexr("`e(vce)'","ac bartlett", "")
		local vcet=regexr("`vcet'","h", "")
		local vcet=regexr("`vcet'","=", "(")+")"
	}
	else if strpos("`e(vce)'","cluster") local vcet "robust cluster(`e(clustvar)')"
	else local vcet `e(vce)'
	
	fvrevar `e(depvar)'
	local y  "`r(varlist)'" 
	fvrevar `e(instd)'
	local Y   "`r(varlist)'"  
	fvrevar `e(exexog)'
	local Z  "`r(varlist)'" 
	fvrevar `e(inexog)'
	local X "`r(varlist)'"
	
	* Generate residuals of y, Y, Z
	foreach type in y Y Z { // yo, Yo, Zo
		local `type'o "" 
		foreach var in ``type'' {
			tempvar `var'temp
			if ("`ivcmd'" == "ivreg2") {
				if ( `noconst_flag' == 1) qui reg `var' `X' if `touse' `addweight', noconstant
				else qui reg `var' `X' if `touse' `addweight'
			}
			else if ("`ivcmd'" == "xtivreg2") qui xtreg `var' `X' if `touse' `addweight', fe
			qui predict double ``var'temp' if `touse', r
			if ("`ivcmd'" == "xtivreg2") {
				tempvar `var'temp1
				qui by `e(ivar)': egen ``var'temp1' = mean(``var'temp')
				qui replace ``var'temp' = ``var'temp' - ``var'temp1'
			}
			local `type'o ``type'o' ``var'temp'
		}
	}
	
	* Orthogonize instruments
	tempname Zs 
	qui orthog `Zo' if `touse' `addweight', gen(`Zs'*)
	fvrevar `Zs'*
	local Zo "`r(varlist)'"

	* Run second stage regression and save residuals as v1 in mata.
	tempvar v1 Pyo
	qui reg `yo' `Zo' if `touse' `addweight', noconstant
	qui predict double `Pyo', xb
	qui predict double `v1', r

	* Run first stage regression and save residuals as v2 in mata.
	local v2 ""
	loc PYo ""
	foreach var in `Yo' {
		tempvar v2`var' PYo`var'
		qui reg `var' `Zo' if `touse' `addweight', noconstant
		qui predict double `PYo`var'', xb
		qui predict double `v2`var'', r
		local PYo `PYo' `PYo`var''
		local v2 `v2' `v2`var''
	}
	
	* Transform variables to mata
	preserve
	qui drop if `Pyo' == .
	foreach vlist in yo Yo Zo PYo Pyo v1 v2 {
		mata: `vlist' = st_data(.,"``vlist''")
	}
	restore
	
	* Get W matrix and statistics
	tempname W W2 RNK Phi Svv
	tempname stat1 stat2 cv1 cv2 cv3
	/*
	stat1: gmin_generalized
	stat2: gmin_stock_yogo
	cv1: gmin_generalized_critical_value
	cv2: gmin_generalized_critical_value_simplified
	cv3: stock_yogo_critical_values_nagar
	*/
	qui avar (`v1' `v2') (`Zs'*) `addweight' if `touse', `vcet' noconstant
	mata: `W' = st_matrix("r(S)") * `S' / (`S' - `K' - `L')
	mata: `W2' = `W'[`K'+1..`K'*(`N'+1),`K'+1..`K'*(`N'+1)]
	mata: `RNK' = I(`N') # vec(I(`K'))
	mata: `Phi' = `RNK'' * (`W2' # I(`K')) * `RNK'
	mata: `Phi' = pinv(sqrtmat(`Phi'))
	mata: `stat1' = min(symeigenvalues(`Phi' * (PYo' * PYo) * `Phi'))
	mata: `Svv' = v2' * v2 / (`S' - `K' - `L')
	mata: `Svv' = pinv(sqrtmat(`Svv'))
	mata: `stat2' = min(symeigenvalues((`Svv' * (PYo' * PYo) * `Svv') / `K'))
	mata: critical_values = gweakivtest_critical_values(`W',`K',`alpha',`tau',`points',`fast', `record')
	mata: `cv1' = critical_values[1]
	mata: `cv2' = critical_values[2]
	mata: `cv3' = critical_values[3]

	foreach num in stat1 stat2 cv1 cv2 cv3 {
		mata: st_numscalar("``num''", ``num'')
	}

	* Return list
	return scalar wiv_stat = `stat1'
	return scalar wiv_stat_sy = `stat2'
	if (`fast' == 0) return scalar wiv_cv = `cv1'
	return scalar wiv_cv_simplified = `cv2'
	return scalar wiv_cv_sy = `cv3'
	return scalar alpha = `alpha'
	return scalar tau = `tau'
	
	* Generate output table
	loc b = `alpha' * 100
	loc t = `tau' * 100
	display ""
	display as text "Lewis-Mertens robust weak instrument test"
	display ""
	display "{txt}{hline 41}"
	display as text "Confidence level alpha:         " as result %8.0fc `b' as result "%"
	display as text "Relative bias threshold:        " as result %8.0fc `t' as result "%"
	display "{txt}{hline 41}"
	display as text "Lewis-Mertens statistic:        " as result %9.3fc `stat1'
	if (`fast' == 0) display as text "Critical value (Imhof):         " as result %9.3fc `cv1'
	display as text "Critical value (Simplified):    " as result %9.3fc `cv2'
	display "{txt}{hline 41}"
	if (`K' > `N' + 1) {
		display as text "Stock-Yogo statistic:           " as result %9.3fc `stat2'
		display as text "Critical value (Nagar):         " as result %9.3fc `cv3'
		display "{txt}{hline 41}"
	}

	* Unhold ereturn result
	_estimates unhold  `myereturn'
	
end

/* MATA CODE PART */
mata
	version 17
	mata clear
	
	real matrix sqrtmat(A) {
		real matrix eigvec, eigval, Ahalf
		real scalar i
		
		eigvec = 1; eigval = 1
		symeigensystem(A, eigvec, eigval)
		for (i=1;i<=cols(eigval);i++) if (abs(eigval[i]) < 1e-10) eigval[i] = 0
		Ahalf = eigvec * sqrt(diag(eigval)) * eigvec'
		return(Ahalf)
	}
	
	real matrix norm(A) { // L2 matrix norm
		return(max(svdsv(A)))
	}
	
	real matrix normfor(A) { // frobenius norm
		return(sqrt(sum(A :* A)))
	}
	
	real matrix gweakivtest_critical_values(W, K, alpha, tau, points, fast, record) {
		real scalar N, j, cv, lmin, n, ome, nu, cc, iter, mxitr, xtol, gtol, ftol, eta, gamma, nt, crit, tiny, ttau, rhols
		real matrix RNK, RNN, RNpK, M1, M2, W1, W2, W12, S, Sigma, Psi, X1, M2PsiM2, Bmax, Bmax_iters, Q, R, L0, k
		
		mxitr = 1000
		xtol = 1e-5
		gtol = 1e-5
		ftol = 1e-7
		eta = 0.1
		gamma = 0.85
		nt = 5
		tiny = 1e-13
		ttau = 1e-3
		rhols = 1e-4
		
		N = rows(W) / K - 1
		RNK = I(N) # vec(I(K))
		RNN = I(N) # vec(I(N))
		RNpK = I(N+1) # vec(I(K))
		M1 = RNN' * (I(N^3) + (Kgen(N,N) # I(N)))
		M2 = RNK * RNK' / (1 + N) - I(N * K^2)

		W1 = W[1..K,1..K]
		W2 = W[K+1..K*(N+1),K+1..K*(N+1)]
		W12 = W[1..K,K+1..K*(N+1)]

		S = (pinv(sqrtmat(RNK' * (W2 # I(K)) * RNK / K)) # I(K)) * sqrtmat(W2)
		Sigma = S * S'
		
		Psi = (((pinv(sqrtmat(RNK' * (W2 # I(K)) * RNK / K)) # I(K)) * (W12 \ W2)') # I(K)) * RNpK * pinv(sqrtmat(RNpK' * (W # I(K)) * RNpK))
		X1 = ((I(N) # Kgen(K^2,N)) # I(N^2)) * (vec(I(N)) # I(N^2*K^2)) * ((I(K) # Kgen(K,N)) # I(N)) * (I(N^2*K^2) + Kgen(N*K,N*K))
		M2PsiM2 = M2 * (Psi * Psi') * M2'

		Bmax = J(3,1,0)
		if (N == 1) {
			if (K > N + 1) Bmax[2] = min((sqrt(2*(N+1)/K)*norm(M2*Psi),1))
			else Bmax[2] = min((norm(Psi),1))
		}
		else {
			if (K > N + 1) Bmax[2] = min((sqrt(2*(N+1)/K)*norm(M2*Psi),norm(Psi)))
			else Bmax[2] = norm(Psi)
		}
		
		if (fast == 0) {
			if (K > N + 1) {
				Bmax_iters = J(points,1,0)
				Q = J(K, K, 0)
				R = J(K, K, 0)
				if (record == 1) printf("{txt}Iteration Counter:\n")
				for (iter=1;iter<=points;iter++) {
					qrd(rnormal(K,K,0,1), Q, R)
					L0 = Q[.,1..N]
					Bmax_iters[iter] = sqrt(- OptStiefelGBB(L0, M1, M2PsiM2, X1, mxitr, xtol, gtol, ftol, eta, gamma, nt, tiny, ttau, rhols))
					if (record == 1) {
						if (iter/50 == ceil(iter/50) | iter == points) printf("{txt}%s\n",strofreal(iter))
						else if ((iter-1)/50 == ceil((iter-1)/50)) printf("{txt}%s",strofreal(iter))
						else printf("{txt}·")
						displayflush()
					}
				}
				Bmax[1] = max(Bmax_iters)
			}
			else Bmax[1] = Bmax[2]
		}
		
		// Stock-Yogo under nagar Approximation
		if (K > N + 1) Bmax[3] = (K - (N + 1)) / K
		else Bmax[3] = .
		
		// Get critical value based on Imhof Approximation
		cv = J(3,1,.)
		k = J(3,1,0)
		for (j=1;j<=3;j++) {
			lmin = Bmax[j] / tau
			if (j < 3) {
				for (n=1;n<=3;n++) k[n] = 2^(n-1)*factorial(n-1)*(norm(RNK'*(matpowersym(Sigma,n) # I(K))*RNK)+n*K*lmin*(norm(Sigma))^(n-1))
				ome = k[2] / k[3]
				nu = 8 * k[2] * ome^2
				cc = invchi2(nu,1-alpha)
				cv[j] = ((cc - nu) / (4 * ome) + k[1]) / K
			}
			else cv[j] =  invnchi2(K, K*lmin, 1-alpha) / K
		}
		
		return(cv)
	}
	
	struct objresult {
		real scalar fval
		real matrix gradient
	}
	
	struct objresult scalar objL0(x, M1, M2PsiM2, X1, N, K) {
		real scalar fval, k
		real matrix gradient, g, L0, vecL0, QLL, Mobj, Qobj, Dobj, ev
		struct objresult scalar result
		
		L0 = x'
		vecL0 = vec(L0)
		QLL = (I(N) # L0) # L0
		Mobj = M1 * QLL * M2PsiM2 * QLL' * M1' / K
		Mobj = 0.5 * (Mobj + Mobj')
		Mobj = nearestSPD(Mobj)
		Qobj = 1; Dobj = 1
		symeigensystem(Mobj, Qobj, Dobj)
		Dobj = diag(Dobj)
		ev = Qobj[.,1]
		fval = - ev' * Mobj * ev
		g = 2 * ((ev' * M1 * QLL * M2PsiM2) # (ev' * M1)) * X1 * (I(N * K) # vecL0)
		g = vec(g)
		gradient = J(N,K,0)
		for (k=1;k<=K;k++) gradient[.,k] = g[(k-1)*N+1..k*N]
		gradient = - 1 * gradient'

		result.fval = fval
		result.gradient = gradient
		return(result)
	}
	
	real matrix Kgen(m,n) {
		real scalar mm, nn
		real matrix K
		
		K = J(m*n, m*n, 0)
		for (nn=1;nn<=n;nn++) for (mm=1;mm<=m;mm++) K[nn+(mm-1)*n,(nn-1)*m+mm] = 1
		return(K)
	}
	
	real scalar OptStiefelGBB(X, M1, M2PsiM2, X1, mxitr, xtol, gtol, ftol, eta, gamma, nt, tiny, ttau, rhols) {
		real scalar N, K, F, nrmG, Q, Cval, itr, XP, FP, GP, nls, deriv, XDiff, FDiff, SY, Qp
		real matrix crit, G, GX, dtX, dtXP, S, Y, mcrit
		struct objresult scalar result
		
		K = rows(X); N = cols(X)
		crit = J(mxitr, 3, 0)
		result = objL0(X, M1, M2PsiM2, X1, N, K)
		F = result.fval
		G = result.gradient
		GX = G' * X
		dtX = G - X * GX; nrmG = normfor(dtX)
		Q = 1; Cval = F

		for (itr=1;itr<=mxitr;itr++) {
			XP = X; FP = F; GP = G; dtXP = dtX
			nls = 1; deriv = rhols * nrmG^2
			while (nls <= 5) {
				X = myQR(XP - ttau * dtX)
				if (normfor(X' * X - I(N)) > tiny) X = myQR(X)
				result = objL0(X, M1, M2PsiM2, X1, N, K)
				F = result.fval
				G = result.gradient
				if (F <= Cval - ttau * deriv) break
				ttau = eta * ttau; nls = nls + 1
			}
			GX = G' * X
			dtX = G - X * GX; nrmG = normfor(dtX)
			S = X - XP; XDiff = normfor(S) / sqrt(K)
			FDiff = abs(FP - F) / (abs(FP) + 1)
			Y = dtX - dtXP
			SY = abs(sum(S :* Y))
			if (mod(itr, 2) == 0) ttau = (normfor(S))^2 / SY
			else ttau = SY / (normfor(Y))^2
			ttau = max((min((ttau, 1e20)), 1e-20))
			crit[itr,.] = (nrmG, XDiff, FDiff)
			mcrit = mean(crit[itr-min((nt,itr))+1..itr,.])
			if (((XDiff < xtol) & (FDiff < ftol)) | (nrmG < gtol) | ((mcrit[2] < 10 * xtol) & (mcrit[3] < 10 * ftol))) break
			Qp = Q; Q = gamma * Qp + 1; Cval = (gamma * Qp * Cval + F) / Q
		}
		
		return(F)
	}
	
	real matrix myQR(XX) { // cols(XX) <= rows(XX)
		real matrix Q, RR, diagRR
		real scalar k
		
		k = cols(XX); Q = 1; RR = 1
		qrd(XX, Q, RR)
		diagRR = sign(diagonal(RR))
		Q = Q[.,1..k] * diag(diagRR)
		
		return(Q)
	}
	
	real matrix nearestSPD(A) { // the nearest (in Frobenius norm) Symmetric Positive Definite matrix to A
		real scalar p, k, mineig
		real matrix Ahat, B, U, Sigma, V, H
		
		B = (A + A') / 2
		U = 1; Sigma = 1; V = 1
		svd(B, U, Sigma, V)
		H = V' * diag(Sigma) * V
		Ahat = (B + H) / 2
		Ahat = (Ahat + Ahat') / 2
		p = 1
		k = 0
		while (p == 1) {
			mineig = min(symeigenvalues(Ahat))
			if (mineig > 0) p = 0
			else {
				k = k + 1
				Ahat = Ahat + (- mineig * k^2 + epsilon(mineig)) * I(rows(A))
			}
			
		}
		
		return(Ahat)
	}
end
