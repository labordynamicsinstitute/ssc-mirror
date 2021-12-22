* metan.ado
* Study-level (aka "aggregate-data" or "published data") meta-analysis

*! version 4.05  29nov2021
*! Current version by David Fisher
*! Previous versions by Ross Harris and Michael Bradburn


********************
* Mata subroutines *  (for iterative methods)
********************

version 11.0

mata:


/* Kontopantelis's bootstrap DerSimonian-Laird estimator */
// (PLoS ONE 2013; 8(7): e69930, and also implemented in -metaan- )
// N.B. using originally estimated ES within the re-samples, as in Kontopantelis's paper */
void DLb(string scalar varlist, string scalar touse, real scalar level, real scalar reps)
{
	// setup
	real colvector yi, se, vi, wi
	varlist = tokens(varlist)
	st_view(yi=., ., varlist[1], touse)
	if(length(yi)==0) exit(error(2000))
	st_view(se=., ., varlist[2], touse)
	vi = se:^2
	wi = 1:/vi

	// calculate I-V Common eff
	real scalar eff
	eff = mean(yi, wi)	

	// carry out bootstrap procedure
	transmorphic B, J
	real colvector report
	B = mm_bs(&ftausq(), (yi, vi), 1, reps, 0, 1, ., ., ., eff)
	J = mm_jk(&ftausq(), (yi, vi), 1, 1, ., ., ., ., ., eff)
	report = mm_bs_report(B, ("mean", "bca"), level, 0, J)

	// truncate at zero
	report = report:*(report:>0)
	
	// return tausq and confidence limits
	real scalar tausq
	tausq = report[1]
	st_numscalar("r(tausq)", tausq)
	st_numscalar("r(tsq_lci)", report[2])
	st_numscalar("r(tsq_uci)", report[3])
}

real scalar ftausq(real matrix coeffs, real colvector weight, real scalar eff) {
	real colvector yi, vi, wi
	real scalar k, Q, c, tausq
	yi = select(coeffs[,1], weight)
	vi = select(coeffs[,2], weight)
	k = length(yi)
	wi = 1:/vi
	Q = crossdev(yi, eff, wi, yi, eff)
	c = sum(wi) - mean(wi, wi)
	tausq = max((0, (Q-(k-1))/c))
	return(tausq)
}



/* "Generalised Q" methods */
void GenQ(string scalar varlist, string scalar touse, real scalar hlevel, real rowvector iteropts)
{
	// setup
	real colvector yi, se, vi, wi
	varlist = tokens(varlist)
	st_view(yi=., ., varlist[1], touse)
	if(length(yi)==0) exit(error(2000))
	st_view(se=., ., varlist[2], touse)
	vi = se:^2
	wi = 1:/vi

	real scalar maxtausq, itol, maxiter
	maxtausq = iteropts[1]
	itol = iteropts[2]
	maxiter = iteropts[3]
	
	real scalar k
	k = length(yi)
	
	/* Mandel-Paule estimator of tausq (J Res Natl Bur Stand 1982; 87: 377-85) */
	// (also DerSimonian & Kacker, Contemporary Clinical Trials 2007; 28: 105-114)
	// ... can be shown to be equivalent to the "empirical Bayes" estimator
	// (e.g. Sidik & Jonkman Stat Med 2007; 26: 1964-81)
	// and converges more quickly
	real scalar rc_tausq, tausq
	rc_tausq = mm_root(tausq=., &Q_crit(), 0, maxtausq, itol, maxiter, yi, vi, k, k-1)
	st_numscalar("r(tausq)", tausq)
	st_numscalar("r(rc_tausq)", rc_tausq)
	

	/* Confidence interval for tausq by generalised Q-profiling */
	// Viechtbauer Stat Med 2007; 26: 37-52
	// (N.B. most natural point estimate is Mandel-Paule, but any estimate will do)
	real scalar eff, Qmin, Qmax
	eff = mean(yi, wi)							// I-V common-effect estimate
	Qmin = crossdev(yi, eff, wi, yi, eff)		// Q(0) = standard Cochran's Q heterogeneity statistic (when tausq=0)
	wi = 1:/(vi:+maxtausq)
	eff = mean(yi, wi)
	Qmax = crossdev(yi, eff, wi, yi, eff)
	
	// estimate tausq confidence limits
	real scalar Q_crit_hi, Q_crit_lo, tsq_lci, rc_tsq_lci, tsq_uci, rc_tsq_uci
	Q_crit_hi = invchi2(k-1, .5 + hlevel/200)		// higher critical value (0.975) to compare GenQ against (for *lower* bound of tausq)
	Q_crit_lo = invchi2(k-1, .5 - hlevel/200)		//  lower critical value (0.025) to compare GenQ against (for *upper* bound of tausq)
	
	if (Qmin < Q_crit_lo) {			// if Q(0) is less the lower critical value, interval is set to null
		rc_tsq_lci = 2
		rc_tsq_uci = 2
		tsq_lci = 0
		tsq_uci = 0
	}	
	else {
		if (Qmax > Q_crit_lo) {		// If Q(maxtausq) is larger than the lower critical value...
			rc_tsq_uci = 2
			tsq_uci = maxtausq		// ...upper bound for tausq is tausqmax
		}
		else {
			rc_tsq_uci = mm_root(tsq_uci=., &Q_crit(), 0, maxtausq, itol, maxiter, yi, vi, k, Q_crit_lo)
		}
	}
	if (Qmax > Q_crit_hi) {			// If Q(maxtausq) is larger than the higher critical value, interval is set to null
		rc_tsq_lci = 2
		rc_tsq_uci = 2
		tsq_lci = maxtausq
		tsq_uci = maxtausq
	}
	else {
		if (Qmin < Q_crit_hi) {		// If Q(0) is less than the higher critical value...
			rc_tsq_lci = 2
			tsq_lci = 0				// ...lower bound for tausq is 0
		}		
		else {
			rc_tsq_lci = mm_root(tsq_lci=., &Q_crit(), 0, maxtausq, itol, maxiter, yi, vi, k, Q_crit_hi)
		}
	}
	
	// return confidence limits and rc codes
	st_numscalar("r(tsq_lci)", tsq_lci)
	st_numscalar("r(tsq_uci)", tsq_uci)
	st_numscalar("r(rc_tsq_lci)", rc_tsq_lci)
	st_numscalar("r(rc_tsq_uci)", rc_tsq_uci)
}

real scalar Q_crit(real scalar tausq, real colvector yi, real colvector vi, real scalar k, real scalar crit) {
	real colvector wi
	real scalar eff, newtausq
	wi = 1:/(vi:+tausq)
	eff = mean(yi, wi)
	newtausq = (k/crit)*crossdev(yi, eff, wi, yi, eff)/sum(wi) - mean(vi, wi)	// corrected June 2015
	return(tausq - newtausq)
}



/* ML + optional PL (for likelihood profiling for ES CI) */
// (N.B. pass wi back-and-forth as it needs to be calculated anyway for tausq likelihood profiling)
void MLPL(string scalar varlist, string scalar touse, real rowvector levels, real rowvector iteropts, string scalar hmethod, string scalar technique, string scalar model)
{		
	// setup
	real colvector yi, se, vi, wi
	varlist = tokens(varlist)
	st_view(yi=., ., varlist[1], touse)
	if(length(yi)==0) exit(error(111))
	st_view(se=., ., varlist[2], touse)
	vi = se:^2
	wi = 1:/vi

	// Initialize
	real scalar eff0, tausq, eff
	eff0 = mean(yi, wi)								// Effect size with zero tausq
	tausq = max((0, quadvariance(yi) - mean(vi)))	// Initialize tausq using Hedges estimator
	wi = 1:/(vi:+tausq)
	eff = mean(yi, wi)								// Initialize eff using Hedges estimator
	
	// Maximize log-likelihood for ML
	transmorphic S
	real rowvector p
	S = optimize_init()
	optimize_init_evaluator(S, &ML_est())
	optimize_init_evaluatortype(S, "d2")
	optimize_init_params(S, (eff, tausq))
	optimize_init_argument(S, 1, yi)
	optimize_init_argument(S, 2, vi)
	optimize_init_argument(S, 3, .)				// ML_est() can also estimate tausq with eff held constant; not relevant here
	optimize_init_technique(S, technique) 
	optimize_init_singularHmethod(S, hmethod)
	optimize_init_tracelevel(S, "none")
	p = optimize(S)
	
	real scalar rc
	rc = optimize_result_returncode(S)	
	if(rc) exit(error(rc))

	real scalar ll
	ll = optimize_result_value(S)
	eff = p[1]
	tausq = p[2]
	if(tausq < 0) {
		tausq = 0
		eff = eff0
		st_numscalar("r(ll_negtsq)", ll)
		ll = sum(lnnormalden(yi, eff, sqrt(vi)))
	}
	wi = 1:/(vi:+tausq)
	st_numscalar("r(tausq)", tausq)
	st_numscalar("r(converged)", optimize_result_converged(S))
	st_numscalar("r(ll)", ll)

	// Variance of tausq (using inverse Fisher information)
	real scalar tsq_var
	tsq_var = optimize_result_V(S)[2,2]
	st_numscalar("r(tsq_var)", tsq_var)	

	// Confidence interval for tausq using likelihood profiling
	real scalar maxtausq, itol, maxiter
	maxtausq = iteropts[1]
	itol     = iteropts[2]
	maxiter  = iteropts[3]
	
	real scalar level, hlevel, crit
	level  = levels[1]
	hlevel = levels[2]
	crit = ll - invchi2(1, hlevel/100)/2
	
	real scalar tsq_lci, rc_tsq_lci, tsq_uci, rc_tsq_uci
	rc_tsq_lci = mm_root(tsq_lci=., &ML_profile_tausq(), 0, tausq - itol, itol, maxiter, yi, vi, crit)
	st_numscalar("r(tsq_lci)", tsq_lci)
	st_numscalar("r(rc_tsq_lci)", rc_tsq_lci)

	rc_tsq_uci = mm_root(tsq_uci=., &ML_profile_tausq(), tausq + itol, 10*maxtausq, itol, maxiter, yi, vi, crit)
	st_numscalar("r(tsq_uci)", tsq_uci)
	st_numscalar("r(rc_tsq_uci)", rc_tsq_uci)
	
	// Profile likelihood
	if (model!="ml") {
	
		// Bartlett's correction
		// (see e.g. Huizenga et al, Br J Math Stat Psychol 2011)
		real scalar BCFinv
		BCFinv = 1
		if (model=="plbart") {
			BCFinv = 1 + 2*mean(wi, wi:^2)/sum(wi) - 0.5*mean(wi, wi)/sum(wi)
			st_numscalar("r(BCF)", 1/BCFinv)
		}

		// Log-likelihood based test statistic
		// (evaluated at b = 0)
		crit = ll - invchi2(1, level/100)*BCFinv/2
		
		S = optimize_init()
		optimize_init_evaluator(S, &ML_est())
		optimize_init_evaluatortype(S, "d2")
		optimize_init_params(S, tausq)
		optimize_init_argument(S, 1, yi)
		optimize_init_argument(S, 2, vi)
		optimize_init_argument(S, 3, 0)				// estimate tausq with b held constant at zero
		optimize_init_technique(S, technique) 
		optimize_init_singularHmethod(S, hmethod)
		optimize_init_tracelevel(S, "none")
		
		real scalar tausq0, rc_ll0, ll0, lr
		tausq0 = optimize(S)
		rc_ll0  = optimize_result_returncode(S)
		if(rc_ll0) exit(error(rc_ll0))
		ll0 = optimize_result_value(S)
		if(tausq0 < 0) {
			tausq0 = 0
			ll0 = sum(lnnormalden(yi, 0, sqrt(vi)))
		}
		if (abs(ll0 - ll) <= itol) lr = 0		// in case ll, ll_b are very close (within itol) and/or rounding error results in a negative value
		else lr = 2*(ll - ll0) / BCFinv
		
		// Signed log-likelihood statistic
		// (evaluated at b = 0)
		real scalar sll
		if (lr==0) sll = 0
		else sll = sign(eff)*sqrt(lr)
		
		// Confidence interval for ES using likelihood profiling
		// (use ten times the ML lci and uci for search limits)
		real scalar llim, ulim, eff_lci, eff_uci, rc_eff_lci, rc_eff_uci
		llim = eff - 19.6/sqrt(sum(wi))
		ulim = eff + 19.6/sqrt(sum(wi))
		
		// Skovgaard's correction to the signed likelihood statistic
		if (model=="plskov") {
		
			// Collect ML values of eff, tausq, ll to send to ML_skov()
			real rowvector params
			params = (eff, tausq, ll)
			
			// can't directly correct the critical value, due to the square root (i.e. expression is non-linear)
			// so instead need to pass the critical value to the iteration procedure, and correct afterwards
			crit = invnormal(.5 + level/200)
			sll = ML_skov(0, yi, vi, wi, params, crit, iteropts, hmethod, technique)	// find SLL for b fixed at zero
			sll = sll + crit															// ML_skov() returns sll-crit, so add crit back on
		
			rc_eff_lci = mm_root(eff_lci=., &ML_skov(), llim, eff-itol, itol, maxiter, yi, vi, wi, params,  crit, iteropts, hmethod, technique)
			rc_eff_uci = mm_root(eff_uci=., &ML_skov(), eff+itol, ulim, itol, maxiter, yi, vi, wi, params, -crit, iteropts, hmethod, technique)
			st_numscalar("r(eff_lci)", eff_lci)
			st_numscalar("r(eff_uci)", eff_uci)
			st_numscalar("r(rc_eff_lci)", rc_eff_lci)
			st_numscalar("r(rc_eff_uci)", rc_eff_uci)		
		}
		
		// Otherwise, use the (squared) likelihood statistic LR = SLL^2
		else {
			rc_eff_lci = mm_root(eff_lci=., &ML_profile_eff(), llim, eff, itol, maxiter, yi, vi, crit, tausq, iteropts, hmethod, technique)
			rc_eff_uci = mm_root(eff_uci=., &ML_profile_eff(), eff, ulim, itol, maxiter, yi, vi, crit, tausq, iteropts, hmethod, technique)
			st_numscalar("r(eff_lci)", eff_lci)
			st_numscalar("r(eff_uci)", eff_uci)
			st_numscalar("r(rc_eff_lci)", rc_eff_lci)
			st_numscalar("r(rc_eff_uci)", rc_eff_uci)
		}
		
		st_numscalar("r(ll)", ll)
		st_numscalar("r(lr)", lr)		
		st_numscalar("r(sll)", sll)
	}
}

void ML_est(todo, p, yi, vi, eff_cons, lnf, S, H) {
	real scalar eff, tausq
	real colvector wi
	if(cols(p)==2) {
		eff = p[1]
		tausq = max((0, p[2]))
		lnf = sum(lnnormalden(yi, eff, sqrt(vi:+tausq)))
		if(todo>=1) {
			wi = 1:/(vi:+tausq)
			S = J(1, 2, .)
			S[1] = quadcross(wi, yi:-eff)
			S[2] = -0.5*sum(wi) + 0.5*quadcrossdev(yi, eff, wi:^2, yi, eff)
			if(todo>=2) {
				H = J(2, 2, .)
				H[1, 1] = -sum(wi)
				H[2, 1] = -quadcross(wi:^2, yi:-eff)
				H[2, 2] = 0.5*quadcross(wi, wi) - quadcrossdev(yi, eff, wi:^3, yi, eff)
				_makesymmetric(H)
			}
		}
	}
	else {
		eff = eff_cons		// estimate tausq with eff held constant
		tausq = max((0, p))
		lnf = sum(lnnormalden(yi, eff, sqrt(vi:+tausq)))
		if(todo>=1) {
			wi = 1:/(vi:+tausq)
			S = -0.5*sum(wi) + 0.5*quadcrossdev(yi, eff, wi:^2, yi, eff)
			if(todo>=2) {
				H = 0.5*quadcross(wi, wi) - quadcrossdev(yi, eff, wi:^3, yi, eff)
			}
		}
	}
}

real scalar ML_profile_tausq(real scalar tausq, real colvector yi, real colvector vi, real scalar crit) {
	real colvector wi
	real scalar eff, ll
	wi = 1:/(vi:+tausq)
	eff = mean(yi, wi)
	ll = sum(lnnormalden(yi, eff, sqrt(vi:+tausq)))
	return(ll - crit)
}

real scalar ML_profile_eff(real scalar eff, real colvector yi, real colvector vi, real scalar crit, real scalar tausq_init, real rowvector iteropts, string scalar hmethod, string scalar technique) {
	real scalar maxtausq, itol, maxiter
	maxtausq = iteropts[1]
	itol = iteropts[2]
	maxiter = iteropts[3]

	transmorphic S
	S = optimize_init()
	optimize_init_evaluator(S, &ML_est())
	optimize_init_evaluatortype(S, "d2")
	optimize_init_params(S, tausq_init)
	optimize_init_argument(S, 1, yi)
	optimize_init_argument(S, 2, vi)
	optimize_init_argument(S, 3, eff)
	optimize_init_technique(S, technique) 
	optimize_init_singularHmethod(S, hmethod)
	optimize_init_tracelevel(S, "none")

	real scalar tausq_ll, rc, ll
	tausq_ll = optimize(S)
	rc = optimize_result_returncode(S)	
	if(rc) exit(error(rc))
	ll = optimize_result_value(S)
	if(tausq_ll < 0) ll = sum(lnnormalden(yi, eff, sqrt(vi)))

	return(ll - crit)
}

real scalar ML_skov(real scalar b, real colvector yi, real colvector vi, real colvector wi, real rowvector params, real scalar crit, real rowvector iteropts, string scalar hmethod, string scalar technique) {

	// unpack iteropts and params
	real scalar maxtausq, itol, maxiter
	maxtausq = iteropts[1]
	itol     = iteropts[2]
	maxiter  = iteropts[3]
	
	// unpack params (ML values of eff, tausq, ll)
	real scalar eff, tausq, ll
	eff   = params[1]
	tausq = params[2]
	ll    = params[3]
	
	// maximize LL for fixed b
	transmorphic S
	S = optimize_init()
	optimize_init_evaluator(S, &ML_est())
	optimize_init_evaluatortype(S, "d2")
	optimize_init_params(S, tausq)
	optimize_init_argument(S, 1, yi)
	optimize_init_argument(S, 2, vi)
	optimize_init_argument(S, 3, b)
	optimize_init_technique(S, technique) 
	optimize_init_singularHmethod(S, hmethod)
	optimize_init_tracelevel(S, "none")
	
	real scalar tausq_b, rc, ll_b
	tausq_b = optimize(S)
	rc = optimize_result_returncode(S)
	if(rc) exit(error(rc))
	ll_b = optimize_result_value(S)
	if(tausq_b < 0) {
		tausq_b = 0
		ll_b = sum(lnnormalden(yi, b, sqrt(vi)))
	}
	
	real colvector wi_b
	wi_b = 1:/(vi:+tausq_b)
	
	// (unsigned, positive) likelihood statistic at b
	real scalar sll
	if (abs(ll_b - ll) <= itol) sll = 0		// in case ll, ll_b are very close (within itol) and rounding results in a negative value
	else {
	    sll = sqrt(2*(ll - ll_b))

		// calculate u for Skovgaard correction (always positive)
		real scalar u
		u = U(yi, wi, wi_b, eff, b)

		// Improved (Skovgaard-corrected) signed likelihood statistic
		if (callersversion()>=16.0) {	// make use of ln1p, for possible improvement in numerical stability when u very close to sll
			sll = sll + (1/sll)*ln1p( (sll-u) / (-sll))
		}
		else sll = sll + (1/sll)*ln(u/sll)
	}
	
	sll = sign(eff - b)*sll
	return(sll - crit)
}

real scalar U(real colvector yi, real colvector wi, real colvector wi_b, real scalar eff, real scalar b) {

	// Expected (I) & observed (J) information, evaluated at ML estimate
	real matrix Imat, Jmat
	Imat = Jmat = J(2, 2, 0)
	Imat[1,1] = Jmat[1,1] = sum(wi)
	Imat[2,2] = .5*quadcross(wi, wi)
	
	Jmat[1,2] =  Jmat[2,1] = quadcross(wi, yi:-eff, wi)
	Jmat[2,2] = -Imat[2,2] + quadcrossdev(yi, eff, wi:^3, yi, eff)
	
	// Observed (J) information under constraint eff = b, corresponding to tausq
	real scalar Jtsq
	Jtsq = -.5*quadcross(wi_b, wi_b) + quadcrossdev(yi, b, wi_b:^3, yi, b)

	// S and q
	real matrix S, Sinvq
	real colvector q
	S = (sum(wi_b), (eff-b)*quadcross(wi_b, wi_b) \ 0, .5*quadcross(wi_b, wi_b))
	q = ((eff-b)*sum(wi_b) \ -.5*sum(wi - wi_b))
	Sinvq = luinv(S)*q
	
	real scalar u
	u = abs(Sinvq[1,1]) * sqrt(abs(det(Jmat))) * abs(det(S)) / (sqrt(abs(Jtsq)) * abs(det(Imat)))
	return(u)
}



/* REML */
void REML(string scalar varlist, string scalar touse, real scalar hlevel, real rowvector iteropts, string scalar hmethod, string scalar technique)
{
	// setup
	real colvector yi, se, vi, wi
	varlist = tokens(varlist)
	st_view(yi=., ., varlist[1], touse)
	if(length(yi)==0) exit(error(2000))
	st_view(se=., ., varlist[2], touse)
	vi = se:^2
	wi = 1:/vi
	
	// Initialize
	real scalar eff0, tausq
	eff0 = mean(yi, wi)								// effect size with zero tausq
	tausq = max((0, quadvariance(yi) - mean(vi)))	// Initialize tausq using Hedges estimator	
	
	// Iterative tau-squared using REML
	transmorphic S
	S = optimize_init()
	optimize_init_evaluator(S, &REML_est())
	optimize_init_evaluatortype(S, "d0")
	optimize_init_params(S, tausq)
	optimize_init_argument(S, 1, yi)
	optimize_init_argument(S, 2, vi)
	optimize_init_technique(S, technique) 
	optimize_init_singularHmethod(S, hmethod)
	optimize_init_tracelevel(S, "none")
	
	real scalar rc, ll
	tausq = optimize(S)
	rc = optimize_result_returncode(S)	
	if(rc) exit(error(rc))
	ll = optimize_result_value(S)
	if(tausq < 0) {
		tausq = 0
		st_numscalar("r(ll_negtsq)", ll)
		ll = sum(lnnormalden(yi, eff0, sqrt(vi))) - 0.5*ln(sum(wi))
	}
	
	st_numscalar("r(tausq)", tausq)
	st_numscalar("r(converged)", optimize_result_converged(S))
	st_numscalar("r(ll)", ll)

	// Variance of tausq (using inverse Fisher information)
	real scalar tsq_var
	tsq_var = optimize_result_V(S)
	st_numscalar("r(tsq_var)", tsq_var)

	// Confidence interval for tausq using likelihood profiling
	real scalar maxtausq, itol, maxiter, crit
	maxtausq = iteropts[1]
	itol     = iteropts[2]
	maxiter  = iteropts[3]
	crit = ll - (invchi2(1, hlevel/100)/2)
	
	real scalar tsq_lci, rc_tsq_lci, tsq_uci, rc_tsq_uci
	rc_tsq_lci = mm_root(tsq_lci=., &REML_profile_tausq(), 0, tausq - itol, itol, maxiter, yi, vi, crit)
	st_numscalar("r(tsq_lci)", tsq_lci)
	st_numscalar("r(rc_tsq_lci)", rc_tsq_lci)

	rc_tsq_uci = mm_root(tsq_uci=., &REML_profile_tausq(), tausq + itol, 10*maxtausq, itol, maxiter, yi, vi, crit)
	st_numscalar("r(tsq_uci)", tsq_uci)
	st_numscalar("r(rc_tsq_uci)", rc_tsq_uci)
}

void REML_est(todo, tausq, yi, vi, lnf, S, H) {
	real colvector wi
	real scalar eff
	tausq = max((0, tausq))
	wi = 1:/(vi:+tausq)
	eff = mean(yi, wi)
	lnf = sum(lnnormalden(yi, eff, sqrt(vi:+tausq))) - 0.5*ln(sum(wi))
	
	// Note: using d2debug reveals discrepancy in the Hessian using my formulae below
	//  not sure if I've done it correctly, so using d0 instead (as do -metaan- and -metareg- to be fair)
	// if(todo>=1) {
	// 	S = -0.5*sum(wi) + 0.5*mean(wi, wi) + 0.5*quadcrossdev(yi, eff, wi:^2, yi, eff)
	// 	if(todo>=2) {
	// 		H = 0.5*quadcross(wi, wi) - mean(wi:^2, wi) + 0.5*(mean(wi, wi)^2) - quadcrossdev(yi, eff, wi:^3, yi, eff)
	// 	}
	// }
}

real scalar REML_profile_tausq(real scalar tausq, real colvector yi, real colvector vi, real scalar crit) {
	real colvector wi
	real scalar eff, ll
	tausq = max((0, tausq))
	wi = 1:/(vi:+tausq)
	eff = mean(yi, wi)
	ll = sum(lnnormalden(yi, eff, sqrt(vi:+tausq))) - 0.5*ln(sum(wi))
	return(ll - crit)
}


/* Confidence interval for tausq estimated using approximate Gamma distribution for Q */
/* based on paper by Biggerstaff and Tweedie (Stat Med 1997; 16: 753-768) */
// Point estimate of tausq is simply the D+L estimate
void BTGamma(string scalar varlist, string scalar touse, string scalar wtvec, real scalar hlevel, real rowvector iteropts)
{
	// Setup
	real colvector yi, se, vi, wi
	varlist = tokens(varlist)
	st_view(yi=., ., varlist[1], touse)
	if(length(yi)==0) exit(error(2000))
	st_view(se=., ., varlist[2], touse)
	vi = se:^2
	wi = 1:/vi

	real scalar maxtausq, itol, maxiter, quadpts
	maxtausq = iteropts[1]
	itol = iteropts[2]
	maxiter = iteropts[3]
	quadpts	= iteropts[4]

	// Estimate variance of tausq
	real scalar k, eff, Q, c, d, tausq_m, tausq, Q_var, tsq_var
	k = length(yi)
	eff = mean(yi, wi)					// I-V common-effect estimate
	Q = crossdev(yi, eff, wi, yi, eff)	// standard Q heterogeneity statistic
	c = sum(wi) - mean(wi,wi)			// c = S1 - (S2/S1)
	d = cross(wi,wi) - 2*mean(wi:^2,wi) + (mean(wi,wi)^2)
	tausq_m = (Q - (k-1))/c				// untruncated D+L tausq

	// Variance of Q and tausq (based on untruncated tausq)
	Q_var = 2*(k-1) + 4*c*tausq_m + 2*d*(tausq_m^2)
	tsq_var = Q_var/(c^2)
	st_numscalar("r(tsq_var)", tsq_var)

	// Find confidence limits for tausq
	real scalar tsq_lci, rc_tsq_lci, tsq_uci, rc_tsq_uci
	rc_tsq_lci = mm_root(tsq_lci=., &Gamma_crit(), 0, maxtausq, itol, maxiter, tausq_m, k, c, d, .5 + hlevel/200)
	st_numscalar("r(tsq_lci)", tsq_lci)
	st_numscalar("r(rc_tsq_lci)", rc_tsq_lci)

	rc_tsq_uci = mm_root(tsq_uci=., &Gamma_crit(), tsq_lci + itol, 10*maxtausq, itol, maxiter, tausq_m, k, c, d, .5 - hlevel/200)
	st_numscalar("r(tsq_uci)", tsq_uci)
	st_numscalar("r(rc_tsq_uci)", rc_tsq_uci)
		
	// Find and return new weights
	real scalar EQ, VQ, lambda, r, se_eff
	EQ = (k-1) + c*tausq_m
	VQ = 2*(k-1) + 4*c*tausq_m + 2*d*(tausq_m^2)
	lambda = EQ/VQ
	r = lambda*EQ
	
	real colvector wsi
	real rowvector params
	real scalar i
	wsi = wi
	for(i=1; i<=k; i++) {
		params = (vi[i], lambda, r, c, k)
		wsi[i] = integrate(&BTIntgrnd(), 0, ., quadpts, params)
	}
	wi = wi*gammap(r, lambda*(k-1)) :+ wsi								// update weights
	st_store(st_viewobs(yi), wtvec, wi)									// write new weights to Stata
}

real scalar Gamma_crit(real scalar tausq, real scalar tausq_m, real scalar k, real scalar c, real scalar d, real scalar crit) {
	real scalar lambda, r, limit, ans
	lambda = ((k-1) + c*tausq)/(2*(k-1) + 4*c*tausq + 2*d*(tausq^2))
	r = ((k-1) + c*tausq)*lambda
	limit = lambda*(c*tausq_m + (k-1))
	ans = gammap(r, limit) - crit
	return(ans)
}

real rowvector BTIntgrnd(real rowvector t, real rowvector params) {
	real scalar s, lambda, r, c, k, ans
	s = params[1,1]				// vi[i] > 0
	lambda = params[1,2]		// lambda = E(Q)/Var(Q) [N.B. the inverse of this is used in Henmi & Copas]
	r = params[1,3]				// r = [E(Q)^2]/Var(Q)
	c = params[1,4]				// c = f(weights)
	k = params[1,5]				// k = no. studies > 1
	ans = (c:/(s:+t)) :* gammaden(r, 1/lambda, 1-k, c*t)
	return(ans)
}


/* Henmi and Copas method */
// Point estimate of tausq is simply the D+L estimate
void HC(string scalar varlist, string scalar touse, real scalar level, real rowvector iteropts)
{
	// Setup
	real colvector yi, se, vi, wi
	varlist = tokens(varlist)
	st_view(yi=., ., varlist[1], touse)
	if(length(yi)==0) exit(error(2000))
	st_view(se=., ., varlist[2], touse)
	vi = se:^2

	real scalar itol, maxiter, quadpts
	itol = iteropts[1]
	maxiter = iteropts[2]
	quadpts = iteropts[3]

	real scalar k, eff, Q, W1, W2, W3, W4, tausq, VR, SDR
	k = length(yi)
	wi = 1:/vi
	eff = mean(yi, wi)							// I-V common-effect estimate
	Q = crossdev(yi, eff, wi, yi, eff)			// standard Q heterogeneity statistic
	W1 = sum(wi)
	W2 = mean(wi, wi)
	W3 = mean(wi:^2, wi)
	W4 = mean(wi:^3, wi)
	tausq = max((0, (Q - (k-1))/(W1 - W2)))		// truncated D+L
	VR = 1 + tausq*W2
	SDR = sqrt(VR)
	
	// Coefficients of 1 and (x^2) for the following functions:
	// EQ(x) = conditional mean of Q given R=x
	// VQ(x) = conditional variance of Q given R=x
	// finv(x) = inverse function of f(Q).
	// All three functions are linear combinations of 1 and (x^2),
	//   so all can be represented by a single function, f.
	real scalar aEQ, bEQ
	aEQ = (k - 1) + tausq*(W1 - W2) - (tausq^2)*(W3 - W2^2)/VR
	bEQ = (W3 - W2^2)*(tausq/VR)^2
	
	real scalar aVQ, bVQ
	aVQ = 2*(k - 1) + 4*tausq*(W1 - W2) + 2*(tausq^2)*(W1*W2 - 2*W3 + W2^2)
	aVQ = aVQ - 4*(tausq^2)*(W3 - W2^2)/VR
	aVQ = aVQ - 4*(tausq^3)*(W4 - 2*W2*W3 + W2^3)/VR
	aVQ = aVQ + 2*(tausq^4)*(1/VR^2)*(W3 - W2^2)^2
	
	bVQ = 4*(tausq^2)*((1/VR^2))*(W3 - W2^2)
	bVQ = bVQ + 4*(tausq^3)*(1/VR^2)*(W4 - 2*W2*W3 + W2^3)
	bVQ = bVQ - 2*(tausq^4)*2*(1/VR^3)*(W3 - W2^2)^2
	
	real scalar afinv, bfinv
	afinv = (k-1) - (W1/W2 - 1)
	bfinv = (W1/W2 - 1)

	real rowvector params
	params = (aEQ, bEQ, aVQ, bVQ, afinv, bfinv, SDR)
	
	// Find quantile of approximate distribution
	// (u_alpha/2 in Henmi & Copas)
	real scalar t, rc_t
	rc_t = mm_root(t=., &Eqn(), 0, 2, itol, maxiter, quadpts, level, params)
	if (rc_t > 0) exit(error(498))
	st_numscalar("r(crit)", SDR*t)
	
	// Find test statistic (u) and p-value
	real scalar u, p
	u = eff/sqrt((tausq*W2 + 1)/W1)
	p = 2*integrate(&HCIntgrnd(), abs(u)/SDR, 40, quadpts, (abs(u)/SDR, params))
	st_numscalar("r(p)", p)
	st_numscalar("r(u)", u)
}

// N.B. Integration should be from x to infinity,
//  but we only integrate up to 40 since the integrand's value is indistinguishable from zero at this point.
// To see this, note that the integrand is the product of a cumulative Gamma function ==> between 0 and 1
//  and a standard normal density which is indistinguishable from zero at ~40.
// (thanks to Ben Jann for pointing this out)
real scalar Eqn(real scalar x, real scalar quadpts, real scalar level, real rowvector params) {
	real scalar ans
	ans = integrate(&HCIntgrnd(), x, 40, quadpts, (x, params))
	return(ans - (.5 - level/200))
}

real rowvector HCIntgrnd(real rowvector r, real rowvector params) {
	real scalar t, aEQ, bEQ, aVQ, bVQ, afinv, bfinv, SDR
	t     = params[1]
	aEQ   = params[2]
	bEQ   = params[3]
	aVQ   = params[4]
	bVQ   = params[5]
	afinv = params[6]
	bfinv = params[7]
	SDR   = params[8]
	
	real rowvector ans
	ans = gammap((f(r*SDR, aEQ, bEQ):^2):/f(r*SDR, aVQ, bVQ), f(r/t, afinv, bfinv):/(f(r*SDR, aVQ, bVQ):/f(r*SDR, aEQ, bEQ))) :* normalden(r)
	if(t==0) ans = normalden(r)
	return(ans)
}

real rowvector f(real rowvector x, real scalar a, real scalar b) {
	return(a :+ b*(x:^2))
}

end




