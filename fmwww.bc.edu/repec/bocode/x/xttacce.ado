program define xttacce, eclass
    version 12
    syntax varlist(min=2) [if] [in]  
	   
	tsunab fullvarlist : `varlist' 
	gettoken depvar indepvars : fullvarlist
	marksample touse
	
	quietly{
	

	local varnames `indepvars'
	ereturn clear

	
	xtset
	local panelvar `r(panelvar)'
	local timevar `r(timevar)'
	local fmt : format `timevar'

	if r(balanced) != "strongly balanced" {
		di as err "Error: panel is not strongly balanced"
        exit 198
	}


	tempvar _miss
	gen `_miss' = 0
	foreach var of varlist `varlist'{
	replace `_miss' = missing(`var') `if' `in'
	count if `_miss' == 1
    if r(N) > 0 {
        di as err "Error: Variable `var' contains missing values."
        exit 198
		}
	}  

	local pm = 1

	

	
	tempvar countme
	qui by `panelvar':egen `countme'=total(`touse')
	summ `countme' if `touse',mean
	local capT=r(min)
	qui count if `touse'
	local capN=r(N)/`capT'

	
	mata:est_tacce("`depvar'","`indepvars'",`capT',`capN',`pm',"`touse'","`panelvar'","`timevar'")
	


	
	tempname p fstat tstat tstat se pval lower95 upper95 b V
	scalar `p' = e(p)
	scalar `fstat' = e(fstat)
	matrix `tstat' = e(tstat)'
	matrix `se' = e(se)'
	matrix `pval' = e(pval)'
	matrix `lower95' = e(lower95)'
	matrix `upper95' = e(upper95)'
	matrix `b' = e(bhat)'
	matrix `V' = e(V_bhat)
	
	matrix colnames `b' = `varnames'
	matrix colnames `V' = `varnames'
	matrix rownames `V' = `varnames'
	
	matrix colnames `tstat'  = `varnames'
	matrix colnames `se'  = `varnames'
	matrix colnames `pval'  = `varnames'
	matrix colnames `lower95'  = `varnames'
	matrix colnames `upper95'  = `varnames'

	}
	

	

	eret post `b' `V'
	eret scalar p_num = `p'
	eret scalar fstat = `fstat'
	eret matrix t = `tstat'
	eret matrix se =`se'
	eret matrix p = `pval'
	eret matrix ci_lb = `lower95'
	eret matrix ci_ub = `upper95'
	
	eret scalar N = `capN'*`capT'
	eret scalar T = `capT'
	eret scalar df_r = `capN'*`capT'- colsof(e(b))
	eret local panelvar = "`panelvar'"
	eret local timevar = "`timevar'"
	eret local indepvars = "`varnames'"
	eret local depvar = "`depvar'"
	eret local cmd = "xttacce"
	
	
	di
	
	di as text "TACCE estimator "  ///
		_col(49) as text "Number of obs" ///
		_col(67) "="	///
		_col(76) as res `capN'*`capT'
	di as text "Group variable:" _c
		di as res e(panelvar) ///
		_col(49) as text "Number of groups" ///
		_col(67) "="	///
		_col(77) as res `capN'
	di as text "Time variable:" _c
		di as res e(timevar) ///
		_col(49) as text "Obs per group" ///
		_col(67) "="	///
		_col(77) as res `capT'
	di 	_col(49) as text "F("colsof(e(b)) ", " `capN' * `capT' - colsof(e(b)) ")" ///
		_col(67) "="	///
		_col(73) as res %6.2f e(fstat)
	di _col(49) as text "Prob > F" ///
		_col(67) "="   ///
		_col(73) as res %6.4f Ftail(colsof(e(b)), `capN' * `capT' - colsof(e(b)) , 		e(fstat))
	di

di in smcl as text  "{hline 13}{c TT}{hline 64}"
di in smcl _col(7) e(depvar) _col(14) "{c |}" _col(16) "Coefficient" _col(29) "Std. err." /// 
_col(44) "z" _col(49) "P>|z|" _col(59) "[95% conf. interval]"
di in smcl as text  "{hline 13}{c +}{hline 64}"

foreach var of local varnames {

    local show = abbrev("`var'", 7)


    local padlen = 7 - length("`show'")
    local pad = ""
    if `padlen' > 0 {
        forvalues i = 1/`padlen' {
            local pad = "`pad' "
        }
    }
    local rightalign = "`pad'`show'"

    di in smcl as text ///
        _col(7)  "`rightalign'" ///
        _col(14) "{c |}" ///
        _col(17) as res  %8.6f e(b)[1,"`var'"] ///
        _col(29) %8.6f   e(se)[1,"`var'"] ///
        _col(41) %5.2f   e(t)[1,"`var'"]  ///
        _col(49) %5.3f   e(p)[1,"`var'"]  ///
        _col(58) %9.6f   e(ci_lb)[1,"`var'"] ///
        _col(70) %9.6f   e(ci_ub)[1,"`var'"]
}
di in smcl as text "{hline 13}{c BT}{hline 64}"

		
end

capture mata mata drop est_tacce()
version 12
mata: 
void est_tacce(string scalar yvar,string scalar xvar, real scalar T, real scalar N, real scalar pm, string scalar touse, string scalar panelvar, string scalar timevar)
{
	real matrix y,x,Vid,Tid
	string vector xvarlist
	xvarlist = tokens(xvar)
	st_view(y,.,yvar,touse)
	st_view(x,.,xvarlist,touse)
	st_view(Vid,.,panelvar,touse)
	st_view(Tid,.,timevar,touse)

	
	p = cols(x)
	e = J(N,1,1)
	zbar = J(N,p+1,.)
	
	info=panelsetup(Vid,1)
	for (i=1;i<=rows(info);i++){
	xi=panelsubmatrix(x,i,info)
	yi=panelsubmatrix(y,i,info)
	xbar = mean(xi)
	ybar = mean(yi)
	zbar[i,1]= ybar
	zbar[i,2..p+1] = xbar
	}
	
	M = I(N) - zbar * invsym(zbar' * zbar) * zbar'
	
	Tvals = uniqrows(Tid)

	ehat= asarray_create("real",1)
	betadenom = asarray_create("real",1)
	betanum = asarray_create("real",1)
	bhati = asarray_create("real",1)
	
	for (t = 1; t <= T; t++) {
		which = selectindex(Tid :== Tvals[t])
		yt = y[which, ]
 		xt = x[which, ]
		
		denom_t = xt' * M * xt
		num_t   = xt' * M * yt
		
		asarray(betadenom, t, denom_t)
		asarray(betanum, t, num_t)
		asarray(bhati, t, invsym(denom_t) * num_t)

	}

	sum_denom = asarray(betadenom, 1)
	sum_num = asarray(betanum, 1)

	for (t = 2; t <= T; t++) {
		sum_denom = sum_denom + asarray(betadenom, t)
		sum_num = sum_num + asarray(betanum, t)
	}

	bhat = invsym(sum_denom) * sum_num
	Phihat = sum_denom/T
	
	for (t = 1; t <= T; t++) {
    which = selectindex(Tid :== Tvals[t])
    yt = y[which, ]
    xt = x[which, ]
    asarray(ehat, t, M * (yt - xt * bhat))
	}

	
	Omega = J(p, p, 0)

	for (t = 1; t <= T; t++) {
		which = selectindex(Tid :== Tvals[t])
		xt = x[which, ]

		if (pm == 1) {
			et = asarray(ehat, t)
			Omega = Omega + xt' * M * et * et' * M * xt
		}
		else {
			bhat_t = asarray(bhati, t)
			diff = bhat_t - bhat
			Omega = Omega + xt' * M * xt * diff * diff' * xt' * M * xt
		}
	}

	Omega = Omega / T

	
	tstat_j = J(p,1,.)
	se_j = J(p,1,.)
	pval_j = J(p,1,.)
	lower95 = J(p,1,.)
	upper95 = J(p,1,.)
	
	for (j = 1; j <= p; j++) {
		R = J(1, p, 0)
		R[1, j] = 1

		tstat_j[j,1] = sqrt(T) * (R * (bhat))  	/ sqrt(R * invsym(Phihat) * 		Omega * 	   invsym(Phihat) * R')
		
		se_j[j,1] = sqrt(R * invsym(Phihat) * Omega * invsym(Phihat) * R')/sqrt(T)
		
		pval_j[j,1] = 2 * (1 :- normal(abs(tstat_j[j,1])))
		
		lower95[j,1] = bhat[j, 1] - 1.96 * se_j[j,1]
		upper95[j,1] = bhat[j, 1] + 1.96 * se_j[j,1]
	}
		
	V_bhat = (1/T) * invsym(Phihat) * Omega * invsym(Phihat)
	F_stat = (1/p) * (bhat') * invsym(V_bhat) * bhat

	st_eclear()
	
	st_numscalar("e(p)",p)
	st_numscalar("e(fstat)", F_stat)
	
	st_matrix("e(V_bhat)",V_bhat)
	st_matrix("e(bhat)",bhat)
	st_matrix("e(tstat)",tstat_j)
	st_matrix("e(se)",se_j)
	st_matrix("e(pval)",pval_j)
	st_matrix("e(lower95)",lower95)
	st_matrix("e(upper95)",upper95)
	

   

 }
 end
 
 
	
