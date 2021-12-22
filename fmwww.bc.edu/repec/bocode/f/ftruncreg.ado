*! version 1.0.0  03Sep2019
*! version 1.0.1  07Sep2019
*! version 1.1.0  08Sep2019
*! version 1.2.0  10Sep2019
*! version 1.2.1  11Sep2019
*! version 1.2.2  12Sep2019
*! version 1.3.1  01Oct2019
*! version 1.3.2  20Jul2020
*! version 1.3.3  24Jul2020

capture program drop ftruncreg
program define ftruncreg, eclass
	version 11
	// STORE COMMANDLINE ENTRY
	if !replay() {
		local cmd "ftruncreg"
		local cmdline "`cmd' `*'"
		syntax varlist(numeric fv min=2) [if] [in] [pweight iweight] ///
			[, LL(string) UL(string) noCONStant NOLOG Robust VCE(string) PRFtruncreg] [OFFset(varname)] [ITERate(string)] [CONSTraints(passthru)] ///
			[LEVel(real `c(level)')] [noCI] [noPValues] [noOMITted] [noEMPTYcells] [VSQUISH] [BASElevels] [ALLBASElevels] [noFVLABel] [fvwrap(passthru)] [fvwrapon(passthru)] ///
			[CFORMAT(passthru)] [PFORMAT(passthru)] [SFORMAT(passthru)] [nolstretch] 
        // WARNINGS for IGNORED OPTIONS
        if "`offset'" != "" & "`nolog'" == "" {
            di as error "option {bf:offset()} ignored"
        }
        if "`weight'" != "" & "`nolog'" == "" {
            di as error "{bf:weights} ignored"
        } 
        if "`iterate'" != "" & "`nolog'" == "" {
            di as error "option {bf:iterate()} ignored"
        }
        if "`constraints'" != "" & "`nolog'" == "" {
            di as error "option {bf:constraints()} ignored"
        }
        // CHECK whether UL and LL are REAL NUMBERS
        if "`ll'" != "" {
            confirm number `ll'
        }
        if "`ul'" != "" {
            confirm number `ul'
        }
        // CHECK option VCE
        if "`vce'" != "" & "`vce'" != "robust" & "`vce'" != "oim" & "`vce'" != "opg" {
            di as error "option {bf:vce()} incorrecly specified; {bf:vce(`vce') not allowed with ftruncreg}"
            exit 198
        }
        if "`robust'" == "robust" & "`vce'" != "robust" {
            local vce "robust"
        }
        if "`robust'" != "robust" & "`vce'" == "" {
            local vce "oim"
        }
		marksample touse
		gettoken depvar indepvars : varlist
		_fv_check_depvar `depvar'
		// change touse
		if "`ll'" != "" & "`ul'" != "" {	
			quietly replace `touse' = 0 if `depvar' <= `ll' | `depvar' >= `ul'
		}
		else if "`ll'" != "" {
				quietly replace `touse' = 0 if `depvar' <= `ll'
			}
			else if "`ul'" != "" {
				quietly replace `touse' = 0 if `depvar' >= `ul'
			} 
			else {
				display as error " use regress instead"
				exit 198
			}
		_rmcoll `indepvars' if `touse', expand `constant'
		// return list
		local indepvars `r(varlist)'
		tempname b V N conv sigma df_m logl ic rc ve
		if "`nolog'" == "" {
			local mytrace = 1
		}
		else {
			local mytrace = 0
		}
		if "`constant'" == "" {
			local includecons = 1
		}
		else {
			local includecons = 0
		}
//     handle `vce`
    if "`vce'" == "oim" {
		local ve = 0
		}
    else {
      if "`vce'" == "robust" {
        local ve = 1
    	}
      else {
        local ve = 2
      }
    }
		if "`ll'" != "" & "`ul'" != "" {	
			mata: ftruncregab_work("`depvar'", "`indepvars'", "`touse'",  ///
				"`ll'", "`ul'", "`b'", "`V'",  "`includecons'", "`ve'",  ///
				"`N'", "`conv'", "`sigma'",              ///
				"`df_m'", "`logl'", "`ic'", "`rc'", "`mytrace'")
		}
		else if "`ll'" != "" {
				mata: ftruncrega_work("`depvar'", "`indepvars'", "`touse'",  ///
				"`ll'", "`b'", "`V'",  "`includecons'", "`ve'",  ///
				"`N'", "`conv'", "`sigma'",               ///
				"`df_m'", "`logl'", "`ic'", "`rc'", "`mytrace'")
			}
			else if "`ul'" != "" {
				mata: ftruncregb_work("`depvar'", "`indepvars'", "`touse'",  ///
				"`ul'", "`b'", "`V'",  "`includecons'", "`ve'",   ///
				"`N'", "`conv'", "`sigma'",                ///
				"`df_m'", "`logl'", "`ic'", "`rc'", "`mytrace'")
			} 
			else {
				display as error " use regress instead"
				exit 198
			}
		if "`constant'" == "" {
			local indepvars "`indepvars' _cons"
	   }
		if _caller() >= 15 {
			matrix colnames `b' = `indepvars' /:sigma
			matrix rownames `V' = `indepvars' /:sigma
			matrix colnames `V' = `indepvars' /:sigma
		}
		else {
			local diindepvars ""	
		    foreach dd in `indepvars' {
				local diindepvars "`diindepvars' eq1:`dd'"	
			}
			matrix colnames `b' = `diindepvars' sigma:_cons
			matrix rownames `V' = `diindepvars' sigma:_cons
			matrix colnames `V' = `diindepvars' sigma:_cons
		}
		ereturn post `b' `V', esample(`touse') buildfvinfo properties(b V)
		ereturn scalar N  = `N'
		ereturn scalar converged  = `conv'
		ereturn scalar k_eq = 2
		ereturn scalar df_m = `df_m'
		ereturn scalar sigma = `sigma'
        ereturn scalar level = `level'
		ereturn scalar ll = `logl'
		ereturn scalar ic = `ic'
		ereturn scalar rc = `rc'
		ereturn local cmd `cmd'
		ereturn local cmdline "`cmdline'"
		ereturn local depvar "`depvar'"
        if "`prftruncreg'" == "prftruncreg" {
            ereturn local predict "_ftruncreg_p"
            ereturn local marginsok "default XB"
        }
        else {
            ereturn local predict "truncr_p"
            ereturn local marginsok "default XB Pr(passthru) E(passthru) YStar(passthru)"
        }
    ereturn local vce "`vce'"
    if "`vce'" == "robust" {
      ereturn local vcetype "Robust"
    }
	}
	if replay() {
    syntax, [LEVel(real `c(level)')] [noCI] [noPValues] [noOMITted] [noEMPTYcells] [VSQUISH] [BASElevels] [ALLBASElevels] [noFVLABel] [fvwrap(passthru)] [fvwrapon(passthru)] ///
		[CFORMAT(passthru)] [PFORMAT(passthru)] [SFORMAT(passthru)] [nolstretch]
  }
	if "`nolog'" == "" {
		display as text _newline "Truncated (using ftruncreg) Regression"
		ereturn display, level(`level')	`ci' `pvalues' `omitted' `emptycells' `vsquish' `baselevels' `allbaselevels' `fvlabel' `fvwrap' `fvwrapon' `cformat' `pformat' `sformat' `lstretch'	
	}
end

mata mata clear

mata:

void ftruncregab_work( string scalar depvar,                ///
	string scalar indepvars, string scalar touse,            ///
	string scalar a2, string scalar b2,                      ///
	string scalar bs, string scalar vs, ///
	string scalar inccons, string scalar ves, ///
	string scalar ns,    ///
	string scalar conv, string scalar sigma,                 ///
	string scalar df_m, string scalar logl,                  ///
	string scalar ic, string scalar rc,                      ///
	string scalar mytrace)
{
	real vector y, bh
	real matrix X, vh
	real scalar n, K, ll, ul, tr, ve
    ve = strtoreal(ves)
	tr = strtoreal(mytrace)
	co = strtoreal(inccons)
	ll = strtoreal(a2)
	ul = strtoreal(b2)
	y  = st_data(., depvar, touse)
	X  = st_data(., indepvars, touse)
	n  = rows(y)
	if (co == 1){
		X  = X, J(n,1,1)
	}
	//matlist(X)
	//matlist(y)
	//matlist(ll)
	//matlist(ul)
	//matlist(tr)
	K  = cols(X)
	
	//Ct = makeCt(mo)
	
	bh = 0.999999*invsym(cross(X,X)) * quadcross(X,y)
	//matlist(bh)
	ee = y - X*bh
	//matlist(ee)
	//matlist(n)
	//matlist(K)
	sh = 1.000001*sqrt( cross(ee,ee) / (n - K))
	//matlist(sh)
	bh = bh', sh
	//matlist(bh)
	S  = optimize_init()
	optimize_init_evaluator(S, &ftruncregab())
	optimize_init_evaluatortype(S, "gf2")
	optimize_init_technique(S, "nr")
	optimize_init_argument(S, 1, y)
	optimize_init_argument(S, 2, X)
	optimize_init_argument(S, 3, ll)
	optimize_init_argument(S, 4, ul)
	optimize_init_params(S, bh)
	if (tr == 0){
		optimize_init_verbose(S, 0)
		optimize_init_tracelevel(S, "none")
	}
	//matlist(bh)
	bh = optimize(S)
  if (ve != 0){
    if (ve == 1){
      vh = optimize_result_V_robust(S)
    }
    if (ve == 2){
      vh = optimize_result_V_opg(S)
    }
  }
  else {
    vh = optimize_result_V_oim(S)
  }
	// matlist(bh)
	st_matrix(bs, bh)
	st_matrix(vs, vh)
	st_numscalar(ns, n)
	st_numscalar(df_m, K-1)
	st_numscalar(sigma, bh[K+1])
	st_numscalar(logl, optimize_result_value(S))
	st_numscalar(conv, optimize_result_converged(S))
	st_numscalar(ic,   optimize_result_iterations(S)-1)
	st_numscalar(rc,   optimize_result_returncode(S))
}

/*
	in = (y :> ll :& y :< ul)
	y  = select(y,in)
	X  = select(X,in)
*/

void ftruncrega_work( string scalar depvar,                 ///
	string scalar indepvars, string scalar touse,            ///
	string scalar a2,                                        ///
	string scalar bs, string scalar vs, ///
	string scalar inccons, string scalar ves, ///
	string scalar ns,    ///
	string scalar conv, string scalar sigma,                 ///
	string scalar df_m, string scalar logl,                  ///
	string scalar ic, string scalar rc,                      ///
	string scalar mytrace)
{
	real vector y, bh
	real matrix X, vh
	real scalar n, K, ll, tr, ve
    ve = strtoreal(ves)
	tr = strtoreal(mytrace)
	co = strtoreal(inccons)
	ll = strtoreal(a2)
	y  = st_data(., depvar, touse)
	X  = st_data(., indepvars, touse)
	n  = rows(y)
	if (co == 1){
		X  = X, J(n,1,1)
	}
	K  = cols(X)
	//t = makeCt(mo)
	bh = 0.999999*invsym(cross(X,X)) * quadcross(X,y)
	ee = y - X*bh
	sh = 1.000001*sqrt( cross(ee,ee)/ (n -cols(X)))
	bh = bh', sh
	S  = optimize_init()
	optimize_init_evaluator(S, &ftruncrega())
	optimize_init_evaluatortype(S, "gf2")
	optimize_init_technique(S, "nr")
	optimize_init_argument(S, 1, y)
	optimize_init_argument(S, 2, X)
	optimize_init_argument(S, 3, ll)
	optimize_init_params(S, bh)
	if (tr == 0){
		optimize_init_verbose(S, 0)
		optimize_init_tracelevel(S, "none")
	}
	bh = optimize(S)
  if (ve != 0){
    if (ve == 1){
      vh = optimize_result_V_robust(S)
    }
    if (ve == 2){
      vh = optimize_result_V_opg(S)
    }
  }
  else {
    vh = optimize_result_V_oim(S)
  }
	st_matrix(bs, bh)
	st_matrix(vs, vh)
	st_numscalar(ns, n)
	st_numscalar(df_m, K-1)
	st_numscalar(sigma, bh[K+1])
	st_numscalar(logl, optimize_result_value(S))
	st_numscalar(conv, optimize_result_converged(S))
	st_numscalar(ic,   optimize_result_iterations(S)-1)
	st_numscalar(rc,   optimize_result_returncode(S))
}

void ftruncregb_work( string scalar depvar,                 ///
	string scalar indepvars, string scalar touse,            ///
	string scalar b2,                                        ///
	string scalar bs, string scalar vs, ///
	string scalar inccons, string scalar ves, ///
	string scalar ns,    ///
	string scalar conv, string scalar sigma,                 ///
	string scalar df_m, string scalar logl,                  ///
	string scalar ic, string scalar rc,                      ///
	string scalar mytrace)
{
	real vector y, bh
	real matrix X, vh
	real scalar n, K, ul, tr, ve
    ve = strtoreal(ves)
	tr = strtoreal(mytrace)
	co = strtoreal(inccons)
	ul = strtoreal(b2)
	y  = st_data(., depvar, touse)
	X  = st_data(., indepvars, touse)
	n  = rows(y)
	if (co == 1){
		X  = X, J(n,1,1)
	}
	K  = cols(X)
	//Ct = makeCt(mo)
	bh = 0.999999*invsym(cross(X,X)) * quadcross(X,y)
	ee = y - X*bh
	sh = 1.000001*sqrt( cross(ee,ee)/ (n -cols(X)))
	bh = bh', sh
	S  = optimize_init()
	optimize_init_evaluator(S, &ftruncregb())
	optimize_init_evaluatortype(S, "gf2")
	optimize_init_technique(S, "nr")
	optimize_init_argument(S, 1, y)
	optimize_init_argument(S, 2, X)
	optimize_init_argument(S, 3, ul)
	optimize_init_params(S, bh)
	if (tr == 0){
		optimize_init_verbose(S, 0)
		optimize_init_tracelevel(S, "none")
	}
	bh = optimize(S)
  if (ve != 0){
    if (ve == 1){
      vh = optimize_result_V_robust(S)
    }
    if (ve == 2){
      vh = optimize_result_V_opg(S)
    }
  }
  else {
    vh = optimize_result_V_oim(S)
  }
	st_matrix(bs, bh)
	st_matrix(vs, vh)
	st_numscalar(ns, n)
	st_numscalar(df_m, K-1)
	st_numscalar(sigma, bh[K+1])
	st_numscalar(logl, optimize_result_value(S))
	st_numscalar(conv, optimize_result_converged(S))
	st_numscalar(ic,   optimize_result_iterations(S)-1)
	st_numscalar(rc,   optimize_result_returncode(S))
}

/*
	optimize_init_trace_Hessian(S, "on")
	optimize_init_verbose(S, 0)
	optimize_init_tracelevel(S, "none")
*/

void ftruncregab(real scalar todo, real vector beta,   ///
	real vector y, real matrix X,                       ///
	real scalar a, real scalar b,                       ///
	lnf, grad, Hess)
{
	real vector  xb
	K = cols(X)
	beta1  = beta[1::K]
	sigma1 = beta[K+1]
	xb     = X*beta1'
	axb    = a :- xb
	bxb    = b :- xb
	yxb    = y :- xb
	hdenom = normal(bxb/sigma1) - normal(axb/sigma1)
	lnf    = -0.5*log(2*pi()*sigma1^2) ///
		:- 0.5/sigma1^2*yxb:^2          ///
		:- log( hdenom )
	if (todo>=1) {
		normbxb = normalden(bxb/sigma1)
		normaxb = normalden(axb/sigma1)
		h0   = (1*normbxb - 1*normaxb) :/ hdenom
		h1   = (bxb:*normbxb - axb:*normaxb) :/ hdenom
		grad = 1/sigma1^2 * yxb :* X + 1/sigma1 * h0 :* X,      ///
			-1/sigma1 :+ 1/sigma1^3 * yxb:^2 + 1/sigma1^2 * h1
			if (todo>=2) {
				h2   = (bxb:^2:*normbxb - axb:^2:*normaxb) :/ hdenom
				h3   = (bxb:^3:*normbxb - axb:^3:*normaxb) :/ hdenom
				ddlA11 = (-1/sigma1^2 * (X :* (1 :- (1/sigma1 * h1 + h0:^2)))') * X
				ddlA12 = X' * (-2/sigma1^3* yxb - 1/sigma1^2*h0 + 1/sigma1^4*h2 + 1/sigma1^3*h0:*h1)
				ddlA22 = rows(y)/sigma1^2 - 3/sigma1^4* sum(yxb:^2) - 2/sigma1^3 * sum(h1) + 1/sigma1^5 * sum(h3) + 1/sigma1^4 * sum(h1:^2)
				Hess = ddlA11, ddlA12\ ddlA12', ddlA22
			}
	}
}

void ftruncrega(real scalar todo, real vector beta,    ///
	real vector y, real matrix X,                       ///
	real scalar a,                                      ///
	lnf, grad, Hess)
{
	real vector  xb
	K = cols(X)
	beta1  = beta[1::K]
	sigma1 = beta[K+1]
	xb     = X*beta1'
	axb    = a :- xb
	yxb    = y :- xb
	hdenom = 1 :- normal(axb/sigma1)
	lnf    = -0.5*log(2*pi()*sigma1^2) ///
		:- 0.5/sigma1^2*yxb:^2          ///
		:- log( hdenom )
	if (todo>=1) {
		normaxb = normalden(axb/sigma1)
		h0   = (   -1*normaxb) :/ hdenom
		h1   = (-axb:*normaxb) :/ hdenom
		grad = 1/sigma1^2 * yxb :* X + 1/sigma1 * h0 :* X,      ///
			-1/sigma1 :+ 1/sigma1^3 * yxb:^2 + 1/sigma1^2 * h1
			if (todo>=2) {
				h2   = (-axb:^2:*normaxb) :/ hdenom
				h3   = (-axb:^3:*normaxb) :/ hdenom
				ddlA11 = (-1/sigma1^2 * (X :* (1 :- (1/sigma1 * h1 + h0:^2)))') * X
				ddlA12 = X' * (-2/sigma1^3* yxb - 1/sigma1^2*h0 + 1/sigma1^4*h2 + 1/sigma1^3*h0:*h1)
				ddlA22 = rows(y)/sigma1^2 - 3/sigma1^4* sum(yxb:^2) - 2/sigma1^3 * sum(h1) + 1/sigma1^5 * sum(h3) + 1/sigma1^4 * sum(h1:^2)
				Hess = ddlA11, ddlA12\ ddlA12', ddlA22
			}
	}
}

void ftruncregb(real scalar todo, real vector beta,    ///
	real vector y, real matrix X,                       ///
	real scalar b,                                      ///
	lnf, grad, Hess)
{
	real vector  xb
	K = cols(X)
	beta1  = beta[1::K]
	sigma1 = beta[K+1]
	xb     = X*beta1'
	bxb    = b :- xb
	yxb    = y :- xb
	hdenom = normal(bxb/sigma1)
	lnf    = -0.5*log(2*pi()*sigma1^2) ///
		:- 0.5/sigma1^2*yxb:^2          ///
		:- log( hdenom )
	if (todo>=1) {
		normbxb = normalden(bxb/sigma1)
		h0   = (   1*normbxb) :/ hdenom
		h1   = (bxb:*normbxb) :/ hdenom
		grad = 1/sigma1^2 * yxb :* X + 1/sigma1 * h0 :* X,      ///
			-1/sigma1 :+ 1/sigma1^3 * yxb:^2 + 1/sigma1^2 * h1
			if (todo>=2) {
				h2   = (bxb:^2:*normbxb) :/ hdenom
				h3   = (bxb:^3:*normbxb) :/ hdenom
				ddlA11 = (-1/sigma1^2 * (X :* (1 :- (1/sigma1 * h1 + h0:^2)))') * X
				ddlA12 = X' * (-2/sigma1^3* yxb - 1/sigma1^2*h0 + 1/sigma1^4*h2 + 1/sigma1^3*h0:*h1)
				ddlA22 = rows(y)/sigma1^2 - 3/sigma1^4* sum(yxb:^2) - 2/sigma1^3 * sum(h1) + 1/sigma1^5 * sum(h3) + 1/sigma1^4 * sum(h1:^2)
				Hess = ddlA11, ddlA12\ ddlA12', ddlA22
			}
	}
}

// taken from web
void matlist(
    real matrix X,
    | string scalar fmt
    )
{
    real scalar     i, j, wd, rw, cw
    string scalar   sfmt

    if (fmt=="") fmt = "%g"
    wd = strlen(sprintf(fmt,-1/3))

    if (length(X)==0) return

    rw = trunc(log10(rows(X))) + 1
    cw = trunc(log10(cols(X))) + 1
    wd = max((cw,wd)) + 2
    sfmt = "%"+strofreal(wd)+"s"

    printf("{txt}"+(2+rw+1+1)*" ")
    for (j=1;j<=cols(X);j++) {
        printf(sfmt+" ", sprintf("%g", j))
    }
    printf("  \n")
    printf((2+rw+1)*" " + "{c TLC}{hline " +
        strofreal((wd+1)*cols(X)+1) + "}{c TRC}\n")
    for (i=1;i<=rows(X);i++) {
        printf("{txt}  %"+strofreal(rw)+"s {c |}{res}", sprintf("%g", i))
        for (j=1;j<=cols(X);j++) {
            printf(sfmt+" ",sprintf(fmt, X[i,j]))
        }
        printf(" {txt}{c |}\n")
    }
    printf((2+rw+1)*" " + "{c BLC}{hline " +
        strofreal((wd+1)*cols(X)+1) + "}{c BRC}\n")
}

real matrix makeCt(string scalar mo)
{
    real vector mo_v
    real scalar ko, j, p

    mo_v = st_matrix(mo)
    p    = cols(mo_v)
    ko   = sum(mo_v)
    if (ko>0) {
        Ct   = J(0, p, .)
        for(j=1; j<=p; j++) {
            if (mo_v[j]==1) {
                Ct  = Ct \ e(j, p)
            }
        }
        Ct = Ct, J(ko, 1, 0)
    }
    else {
        Ct = J(0,p+1,.)
    }
    return(Ct)
}
end
