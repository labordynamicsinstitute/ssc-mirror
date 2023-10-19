******** Optimization for Classification ********
mata:
 mata clear
 // Initial Beta
 real matrix initbeta(Y, X, tidx) {
 	real matrix b0, xx, yy
	real scalar i, N, p

	p = cols(X); N = rows(tidx) - 1
	b0 = J(N, 1, 1) # (pinv(X'*X)*X'*Y)
	for (i=1; i<=N; i++) {
		xx = X[tidx[i]+1..tidx[i+1],.]
		yy = Y[tidx[i]+1..tidx[i+1],.]
		if (yy' * yy / N > 0.001) b0[(i-1)*p+1..i*p,.] = pinv(xx' * xx) * xx' * yy
	}
	return(b0)
 }
 
 // Objective Function
 void PLSmse(todo, real matrix xv, Y, X, N, lamk, plsmse, g, H) {
	real matrix b, a, r, tht, ntht
	real matrix g_part, h_part, temp1, temp2
	real scalar p, n, i

	p = cols(X)/N; n = rows(X)
	b = rowshape(xv[1..N*p], N) // beta
	a = xv[N*p+1..N*p+p] // alpha
	tht = b - a # J(N,1,1)
	plsmse = 0 // Objective Function
	g = J(1, N*p+p, 0) // Gradient
	H = J(N*p+p, N*p+p, 0) // Hessian

	r = Y - X * (xv[1..N*p])'
	ntht = sqrt(diagonal(tht * tht'))
	plsmse = (r' * r) / n + lamk' * ntht
	g_part = lamk :/ ntht
	h_part = lamk :/ ((ntht):^3)
	temp1 = tht :* (g_part # J(1, p, 1))
	g[1..N*p] = - 2 * r' * X / n + rowshape(temp1, 1)
	g[N*p+1..N*p+p] = - colsum(temp1)
	H[1..N*p,1..N*p] = 2 * X' * X / n + diag(g_part # J(p, 1, 1))
	H[N*p+1..N*p+p,1..N*p] = - g_part' # I(p)
	H[N*p+1..N*p+p,N*p+1..N*p+p] = colsum(g_part) * I(p)
	for (i=1; i<=N; i++) {
		temp2 = tht[i,.]' * tht[i,.] * h_part[i]
		H[(i-1)*p+1..i*p,(i-1)*p+1..i*p] = H[(i-1)*p+1..i*p,(i-1)*p+1..i*p] - temp2
		H[N*p+1..N*p+p, (i-1)*p+1..i*p] = H[N*p+1..N*p+p, (i-1)*p+1..i*p] + temp2
		H[N*p+1..N*p+p, N*p+1..N*p+p] = H[N*p+1..N*p+p, N*p+1..N*p+p] - temp2
	}
	_makesymmetric(H)
 }
				
 // Procedure
 void classo(Y, X, tidx, K, lam, tol, maxit, optp, optv, optnr, optm, opti, optt, opts, itname, aname, gidname) {
	real matrix b, a, a1, xv, xv1, ii, temp
	real matrix XX, lamk, gid, Q, number
	real scalar s, s1, r, k, i, kk, N, p, w, idx
	transmorphic S
	
	p = cols(X); N = rows(tidx) - 1
	XX = J(tidx[N+1], N*p, 0)
 	for (i=1; i<=N; i++) XX[tidx[i]+1..tidx[i+1],(i-1)*p+1..i*p]=X[tidx[i]+1..tidx[i+1],.]
	b = initbeta(Y, X, tidx)
	b = b' # J(K, 1, 1); a = J(K, p, 0)
	a1 = a; s = 1; s1 = 2
	Q = J(K, 1, 0); xv1 = J(1, N*p+p , 0)
	
	S = optimize_init()
	optimize_init_which(S, "min")
	optimize_init_evaluator(S, &PLSmse())
	optimize_init_evaluatortype(S, "d2")
	optimize_init_argument(S, 1, Y)
	optimize_init_argument(S, 2, XX)
	optimize_init_argument(S, 3, N)
	optimize_init_tracelevel(S, "none")
	optimize_init_verbose(S, 0)
	optimize_init_technique(S, optt)
	optimize_init_singularHmethod(S, opts)
	optimize_init_conv_warning(S, "off")
	optimize_init_conv_maxiter(S, optm)
	optimize_init_conv_ptol(S, optp)
	optimize_init_conv_vtol(S, optv)
	optimize_init_conv_nrtol(S, optnr)
	optimize_init_conv_ignorenrtol(S, opti)
	
	r = 1
 	while (((abs(s - s1) >= tol) | (norm(a1-a) / (norm(a1) + 0.001) >= tol)) & r <= maxit) {
		s1 = s
        a1 = a
		for (k=1; k<=K; k++) {
			lamk = J(N, 1, 1)
			for (kk=1; kk<=K; kk++) if (kk != k) for (i=1; i<=N; i++) lamk[i] = lamk[i] * (b[kk, p*(i-1)+1..p*i] - a[kk,.]) * (b[kk, p*(i-1)+1..p*i] - a[kk,.])'
			lamk = lam * sqrt(lamk) / N
			optimize_init_argument(S, 4, lamk)
			xv1[1..p*N] = b[k,.]; xv1[p*N+1..p*N+p] = a[k,.]
			optimize_init_params(S, xv1)
			xv = _optimize(S)
			xv = optimize_result_params(S)
			Q[k] = optimize_result_value(S)
			b[k,.] = xv[1..p*N]; a[k,.] = xv[p*N+1..p*N+p]
		}
		s = colsum(Q)
		if (r/5 == ceil(r/5) || r == 1) printf("{txt}%s",strofreal(r))
		else printf("{txt}·")
		displayflush()
		r = r + 1
	}
	// report group
	gid = J(N, 1, 0)
	temp = J(K, 1, 0)
	for (i=1; i<=N; i++) {
		for (k=1; k<=K; k++) temp[k] = norm(a[k,.]-b[k,(i-1)*p+1..i*p])/norm(a[k,.])
		minindex(temp, 1, ii , w)
		gid[i] = ii[1]
	}
	// empty group: 1. delete here; 2. remain empty in the inference step to generate a and V, classo and post; 3. finally expand the matrix by adding null elements
	number = group2num(gid)
	number = number \ J(K-rows(number),1,0)
	idx = 0; a = number, a
	for (k=1;k<=K;k++) if (a[k,1] == 0) idx = 1
	while (idx == 1) {
		for (k=1;k<=K;k++) {
			if (a[k,1] == 0) {
				for (i=1;i<=N;i++) if (gid[i]>k) gid[i] = gid[i] - 1
				if (k == 1) a = a[2..K,.]
				else if (k == K) a = a[1..K-1,.]
				else a = a[1..k-1,.] \ a[k+1..K,.]
				K = rows(a)
				break
			}
		}
		idx = 0
		for (k=1;k<=K;k++) if  (a[k,1] == 0) idx = 1
	}
	number = a[.,1]; a = a[.,2..p+1]

	st_numscalar(itname, r-1)
	st_matrix(aname, a)
	st_matrix(gidname,gid)
 }
 
 real matrix updatea(alpha, gid, Y, X, tidx) {
 	real matrix Yk, Xk, alphak
 	real scalar N, K, i, k, p
	
	K = max(gid); N = rows(tidx) - 1; p = cols(X)
	alpha = alpha, J(K,1,0)
	for (k=1;k<=K;k++) {
		Xk = J(0, p, 0); Yk = J(0, 1, 0)
		for (i=1; i<=N; i++) {
			if (gid[i] == k) {
				Xk = Xk \ X[tidx[i]+1..tidx[i+1],.]
				Yk = Yk \ Y[tidx[i]+1..tidx[i+1],.]
			}
		}
		alphak = Yk - Xk[.,1..p-1] * (alpha[k,1..p-1])'
		alpha[k,p] = mean(alphak)
	}
	return(alpha)
 }
end

************* Statistical Inference *************
mata:
 void inference_static(Y, X, tidx, a, gid, Vname) {
	real matrix Xk, Yk, Phi, Xu, Omega, V, number
	real scalar k, i, j, Nk, uk, p, K, N, obsk
	
	number = group2num(gid)
	K = max(gid); N = rows(gid); p = cols(a); 
	V = J(K*p, p, 0)
	for (k=1; k<=K; k++) {
		Nk = number[k]
		Xk = J(0, p, 0)
		Yk = J(0, 1, 0)
		for (i=1; i<=N; i++) {
			if (gid[i] == k) {
				Xk = Xk \ X[tidx[i]+1..tidx[i+1],.]
				Yk = Yk \ Y[tidx[i]+1..tidx[i+1],.]
			}
		}
		obsk = rows(Yk)
		Phi = (Xk' * Xk) / obsk
		uk = Yk - Xk * (a[k,.])'
		uk = uk :- mean(uk)
		Xu = Xk :* (uk # J(1, p, 1))
		Omega = Xu' * Xu / (obsk - Nk)
		V[(k-1)*p+1..k*p,.] = 1 / obsk * pinv(Phi) * Omega * pinv(Phi)
	}
	st_matrix(Vname, V)
 }
 
 void inference_dynamic(Y, X, tvar, tidx, a, gid, Vname) {
	real matrix number, Xk, Xki, Yk, VarU, Phi, Omega, V
	real matrix tlistk, tidxk, tvark
	real scalar MT, k, i, j, s, t, Nk, uk, p, T, K, N, obsk, Tki
	
	number = group2num(gid)
	K = max(gid); N = rows(gid); p = cols(a); T = rows(X)/N
	V = J(K*p, p, 0); MT = ceil(T^(1/4))
	for (k=1; k<=K; k++) {
		Nk = number[k]
		Xk = J(0, p, 0); Yk = J(0, 1, 0)
		tlistk = J(0, 1, 0)
		tvark = J(0, 1, 0)
		for (i=1; i<=N; i++) {
			if (gid[i] == k) {
				Xk = Xk \ X[tidx[i]+1..tidx[i+1],.]
				Yk = Yk \ Y[tidx[i]+1..tidx[i+1],.]
				tvark = tvark \ tvar[tidx[i]+1..tidx[i+1],.]
				tlistk = tlistk \ (tidx[i+1]-tidx[i])
			}
		}
		obsk = rows(Yk)
		Phi = (Xk' * Xk) / obsk
		uk = Yk - Xk * (a[k,.])'
		Omega = J(p, p, 0)
		tidxk = cum(tlistk)
		for (i=1; i<=Nk; i++) {
			Xki = Xk[tidxk[i]+1..tidxk[i+1],.]
			Tki = tlistk[i]
			VarU = J(Tki, Tki, 0)
			for (s=1;s<=Tki;s++) for (t=1;t<=Tki;t++) VarU[s,t] = kernel(tvark[tidxk[i]+s]-tvark[tidxk[i]+t], MT) * uk[tidxk[i]+s] * uk[tidxk[i]+t]
			Omega = Omega + Xki' * VarU * Xki
		}
		Omega = Omega / obsk
		V[(k-1)*p+1..k*p,.] = 1 / obsk * pinv(Phi) * Omega * pinv(Phi)
	}
	
	st_matrix(Vname, V)
 }

 real scalar kernel(u, MT) {
 	real scalar kernel
	
	kernel = 0
	if (abs(u) <= MT) kernel = 1 - abs(u) / MT
	return(kernel)
 }

 real matrix comb2(T) {
 	real scalar t, i, j
	real matrix combNK, comb_st
	
 	comb_st = J(T^2, 2, 0); combNK = J(T*(T-1)/2, 2, 0)
	j = 0
	for (t=T-1; t>=1; t--) {
		comb_st[t,.] = (t,t)
		combNK[j+1..j+t,1] = J(t, 1, T - t)
		for (i=1; i<=t; i++) combNK[j+i,2] = i + T - t
		j = j + t
	}
	comb_st[T,.] = (T,T)
	comb_st[T+1..T*(T+1)/2,.] = combNK
	comb_st[T*(T+1)/2+1..T^2,1] = combNK[.,2]
	comb_st[T*(T+1)/2+1..T^2,2] = combNK[.,1]
	return(comb_st)
 }
end

************* Goodness-of-fit *************
mata:  
 real matrix rsquared(Y, X, Y0, X0, tidx, a_classo, a_post, gid, df) {
 	real matrix rsq, Xk, Yk, X0k, Y0k
	real scalar K, i, k, p, N
	
	K = max(gid); p = cols(a_classo); N = rows(gid);
	rsq = J(rows(df), 10, 0) // classo: r2, r2adj, withr2, withinr2adj, RMSE; post: ...
	for (k=1; k<=K; k++) {
		Xk = J(0, p, 0); Yk = J(0, 1, 0)
		X0k = J(0, p, 0); Y0k = J(0, 1, 0)
		for (i=1; i<=N; i++) {
			if (gid[i] == k) {
				Xk = Xk \ X[tidx[i]+1..tidx[i+1],.]
				Yk = Yk \ Y[tidx[i]+1..tidx[i+1],.]
				X0k = X0k \ X0[tidx[i]+1..tidx[i+1],.]
				Y0k = Y0k \ Y0[tidx[i]+1..tidx[i+1],.]
			}
		}
		rsq[k,1] = 1 - vecmse(Yk - Xk * (a_classo[k,.])') / vecmse(Y0k)
		rsq[k,2] = 1 - (1 - rsq[k,1]) * (df[k,1] - 1) / df[k,5]
		rsq[k,3] = 1 - vecmse(Yk - Xk * (a_classo[k,.])') / vecmse(Yk)
		rsq[k,4] = 1 - (1 - rsq[k,3]) * (df[k,1] - df[k,6]) / df[k,5]
		rsq[k,5] = sqrt(vecmse(Yk - Xk * (a_classo[k,.])') * df[k,1] / df[k,5])
		rsq[k,6] = 1 - vecmse(Yk - Xk * (a_post[k,.])') / vecmse(Y0k)
		rsq[k,7] = 1 - (1 - rsq[k,6]) * (df[k,1] - 1) / df[k,5]
		rsq[k,8] = 1 - vecmse(Yk - Xk * (a_post[k,.])') / vecmse(Yk)
		rsq[k,9] = 1 - (1 - rsq[k,8]) * (df[k,1] - df[k,6]) / df[k,5]
		rsq[k,10] = sqrt(vecmse(Yk - Xk * (a_post[k,.])') * df[k,1] / df[k,5])
	}
	
	return(rsq)
 }
 
 real scalar vecmse(v) {
 	real scalar s2, N, i, m
	
	N = rows(v); m = 0; s2 = 0
	for (i=1;i<=N;i++) {
		m = m + v[i]
	}
	m = m / N
	v = v - J(N, 1, m)
	s2 = 1 / N * v' * v
	
	return(s2)
 }
 
 real scalar mse(Y, X, tidx, a, gid, df) {
	real matrix xx, yy
	real scalar Nk, Q, k, i, j, p, N, K, df_total

	K = max(gid); p = cols(X); N = rows(tidx) - 1
	Q = 0
	for (i=1; i<=N; i++) {
		yy = Y[tidx[i]+1..tidx[i+1],.]
		xx = X[tidx[i]+1..tidx[i+1],.]
		for (k=1; k<=K; k++) if (gid[i] == k) Q = Q + norm(yy - xx * a[k,.]')^2
	}
	df_total = 0
	for (k=1; k<=K; k++) df_total = df_total + df[k,5]
	Q = Q / df_total
	
	return(Q)
 }
end

************* Useful Functions *************
mata:
 real matrix cum(tlist) {
 	real matrix tidx
	real scalar N, i
	
	N = rows(tlist)
	tidx = tlist
	for (i=2;i<=N;i++) {
		tidx[i] = tidx[i] + tidx[i-1]
	}
	tidx = 0 \ tidx
	
	return(tidx)
 }
 
 real matrix group2num(gid) {
 	real matrix number
	real scalar K, N, k, i
	
	K = max(gid); N = rows(gid)
 	number = J(K, 1, 0)
	for (k=1; k<=K; k++) for (i=1; i<=N; i++) if (gid[i] == k) number[k] = number[k] + 1
	
	return(number)
 }

 real matrix gentlist(panelvar, N) {
 	real matrix tlist, diff
	real scalar i, obs, s
	
	obs = rows(panelvar)
	tlist = J(N, 1, 0)
	diff = panelvar - (panelvar[2..obs] \ panelvar[1])
	i = 1
	for (s=1;s<=obs;s++) {
		if (diff[s] != 0) {
			tlist[i] = s
			i = i + 1
		}
	}
	tlist = tlist - (0 \ tlist[1..N-1])
	return(tlist)
 }
end
