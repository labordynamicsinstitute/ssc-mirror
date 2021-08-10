* Authors: Ercio Munoz & Mariel Siravegna 
*! version 1.0 22August2020
*! version 1.1 March2021

*** predict command for qregsel ***
cap program drop qregsel_p

program define qregsel_p, eclass sortpreserve
	version 15.0
	
	syntax newvarlist(min=2 max=2 generate) [if] [in]
	
	marksample touse, novarlist

	local copula  "`e(copula)'"
	local depvar = "`e(depvar)'"
	local indepvars = "`e(indepvars)'"
	local cmdline = "`e(cmdline)'"
	local outcome_eq = "`e(outcome_eq)'"
	local selection_eq = "`e(select_eq)'"
	local cmd = "`e(cmd)'"
	local predict = "`e(predict)'"
	local rescale = "`e(rescale)'"
	local title = "`e(title)'"

	local NN = e(N)
	local N_selected = e(N_selected)
	local rho = e(rho)
	local kendall = e(kendall)
	local spearman = e(spearman)
	
	local noconstant: list indepvars- outcome_eq
	if ("`noconstant'"=="") local noconstant "noconstant" 
	else if ("`noconstant'"!="") local noconstant "" 

	local myvars "`indepvars'"
	local not "_cons"
	local myvars: list myvars- not

tempname previous_coefs coefs grid b bb Y output X y R M N pZ k XX RR
tempvar v pZ sample touse_select

	g byte `sample' = e(sample)
	g byte `touse_select' = `sample' 
	markout `touse_select' `depvar' `myvars' `selection_eq'

	mat `grid' = e(grid)
	mat `b' = e(b)
	mat `previous_coefs' = e(coefs)
	local newvar1 = "`1'"
	local newvar2 = "`2'"
	
quietly {
tokenize `selection_eq', parse("=")
	if "`2'" != "=" {
		local x_s `selection_eq'
		tempvar y_s
		qui gen `y_s' = (`depvar'!=.)
	}
	else {
		local y_s `1'
		local x_s `3'
	}
	capture unab x_s : `x_s'
qui: probit `y_s' `selection_eq' if `sample'
qui: predict `pZ' 

********************************************************************************	
* Send data to mata 
********************************************************************************
mata: `y'  = st_data(., "`depvar'", "`touse_select'")
mata: `X'  = st_data(., "`myvars'", "`touse_select'")
mata: `XX' = st_data(., "`myvars'", "`touse'")
mata: `M'  = rows(`X')
mata: `N'  = cols(`X')
mata: `pZ' = st_data(.,"`pZ'", "`touse_select'") 

if ("`rescale'" != "non-rescaled") {
mata:	`R'    = meanvariance(`X')
mata:	`X' = (`X':-`R'[1,.]):/sqrt(diagonal(`R'[2::rows(`R'),]))'

mata:	`RR'    = meanvariance(`XX')
mata:	`XX' = (`XX':-`RR'[1,.]):/sqrt(diagonal(`RR'[2::rows(`RR'),]))'
}

if ("`noconstant'"=="") mata: `X' = `X',J(rows(`X'),1,1)
if ("`noconstant'"=="") mata: `XX' = `XX',J(rows(`XX'),1,1)

mata: `coefs' = rqreg(`pZ',`y',`X',`M',`N',"`copula'",`rho')
mata: st_matrix("`coefs'",`coefs'') 

tempvar q1 q2 sorting
gen double `q1' = uniform()
gen double `q2' = uniform()
g long `sorting' = _n

if "`copula'" == "frank" {
gen double `v'  = (-1/`rho')*log(1+(`q2'*(exp(-`rho')-1))/(1+(1-`q2')*(exp(-`rho'*`q1')-1)))
}
else if "`copula'" == "gaussian" {
gen double `v' = rnormal(.5+`rho'*(`q1'-.5),sqrt((1-`rho'^2)/12))
}
replace `newvar2'  = (`v'<=`pZ') if !missing(`pZ')
recast byte `newvar2'
replace `q1' = (int(`q1'*99 + 1))

preserve
clear
matlist `coefs'
svmat `coefs', names(a)
gen byte `q1' = _n
ta `q1'
tempfile temp1
save "`temp1'"
restore

preserve
keep `q1' `sorting' `touse'
merge m:1 `q1' using "`temp1'"
drop if _merge==2
drop _merge
sort `sorting'
mata: `bb'  = st_data(., "a*","`touse'")
restore

mata: `Y' = rowsum(`XX':*`bb',1)
mata: `output' = J(rows(`XX'),1,.)

mata: st_view(`output', ., "`newvar1'","`touse'")
mata: `output'[.,.] = `Y'

}

********************************************************************************	
** Generating the output
********************************************************************************	
    ereturn post `b', esample(`sample') buildfvinfo		
	ereturn matrix coefs      = `previous_coefs'
	ereturn matrix grid       = `grid'
    ereturn scalar N          = `NN'
	ereturn scalar N_selected = `N_selected'
    ereturn scalar rho        = `rho'
	ereturn scalar kendall    = `kendall'
	ereturn scalar spearman   = `spearman'

	ereturn local title   "Quantile selection model"
	ereturn local rescale "`rescale'"
	ereturn local predict "qregsel_p"
    ereturn local cmd     "qregsel"
	ereturn local select_eq "`select_eq'"	
	ereturn local outcome_eq "`outcome_eq'"
	ereturn local cmdline "`cmdline'"
	ereturn local indepvars "`indepvars'"
	ereturn local depvar  "`depvar'"
	ereturn local copula "`copula'"

end

********************************************************************************	
** Auxiliary functions
********************************************************************************
mata:
real matrix rqreg(real matrix pZ,
					real matrix y, 
					real matrix X, 
					real scalar M, 
					real scalar N,
					string scalar copula,
					real scalar rho) {

real vector copula_p
real matrix bb, b

bb = J(cols(X),1,.)

for (i=1; i<=99; i++) {  
    
copula_p  = copulafn(pZ,rho,i/100,copula) 	
b         = mywork(y,X,pZ,rho,i/100,copula_p,M,N)   

bb = bb,b 
}
bb = bb[1...,2..cols(bb)]
return(bb)

}

real matrix bound(numeric matrix x, numeric matrix dx) 
{

	real vector b, f
	
	b = 1e20 :+ 0* x 
	f = selectindex(dx:<0) 
	b[f] = -x[f] :/ dx[f] 

	return(b)
}

real vector copulafn(real vector pZ1, 
						numeric vector rho,
						numeric vector tau,	 
						string scalar name) 
{
	real vector G,vs,v1

	if (name=="gaussian") {
	vs = J(rows(pZ1),1,invnormal(tau))
	v1 = invnormal(pZ1)
	G  = binormal(vs,v1,rho) :/ pZ1
	}
	else {
	G = -ln(1:+(exp(-rho*tau):-1):*(exp(-rho:*pZ1):-1):/(exp(-rho)-1)):/(rho:*pZ1)
	}
	
	return(G)		
}

real vector mywork(real vector y,
					real matrix X,   
					real vector pZ1,     
					numeric vector rho,
					real vector tau,	         
					real matrix p,
					real scalar M,
					real scalar N) 
{
    real vector yy, bb
    real matrix u, a, b, A, x, G
    real scalar m, n, k, it, beta, small, max_it
	
	k    = cols(X) 	
	u    = J(M, 1, 1)
	a    = (1:-p):*u
	it=0
	  
	A = X'
	c = -y'
	b = X'*a
	x = a 
  
	beta = 0.9995
	small = 1e-5
	max_it = 50
	m = rows(A)
	n = cols(A)

// Generate initial feasible point 
	s = u - x  
	yy = svsolve(A',c')'
	r = c - yy * A
	r = mm_cond(r:==0,r:+0.001,r)  
	z = mm_cond(r:>0,r,0)
	w = z - r
	gap = c * x - yy * b + w * u

// Start iterations
	it = 0
while (gap > small & it < max_it) {
    it++

// Compute affine step
    q = 1 :/ (z' :/ x + w' :/ s)
    r = z - w
	AQ = J(k,n,0)
	for (i=1;i<=n;i++) {
		for (j=1;j<=k;j++) {
			AQ[j,i] = q[i,1]*A[j,i]
		}
	}		
	AQA = AQ * A' 
	rhs = AQ * r' 
	dy = (invsym(AQA) * rhs)' 
    dx = q :* (dy * A - r)'
    ds = -dx
    dz = -z :* (1 :+ dx :/ x)'
    dw = -w :* (1 :+ ds :/ s)'
	
// Compute maximum allowable step lengths
	fx = bound(x, dx) 
	fs = bound(s, ds)
	fw = bound(w, dw) 
	fz = bound(z, dz) 
	fp = rowmin((fx,fs)) 
	fd = colmin((fw \ fz)) 
	fp = min((min(beta * fp), 1)) 
	fd = min((min(beta * fd), 1)) 
	
if (mm_cond(fp:<fd,fp,fd) < 1) {
    
// Update mu
    mu = z * x + w * s
    g = (z + fd * dz) * (x + fp * dx) + (w + fd * dw) * (s + fp * ds)
    mu = mu * (g / mu) ^3 / ( 2 * n)

// Compute modified step
	dxdz = dx :* dz'
    dsdw = ds :* dw'
    xinv = 1 :/ x
    sinv = 1 :/ s
    xi = mu * (xinv - sinv)
	rhs = rhs + A * ( q :* (dxdz - dsdw - xi)) 
	dy = (invsym(AQA)* rhs)' 
    dx = q :* (A' * dy' + xi - r' -dxdz + dsdw)
    ds = -dx
    dz = mu * xinv' - z - xinv' :* z :* dx' - dxdz'
    dw = mu * sinv' - w - sinv' :* w :* ds' - dsdw'
 
	// Compute maximum allowable step lengths
	fx = bound(x, dx) 
	fs = bound(s, ds) 
	fw = bound(w, dw) 
	fz = bound(z, dz) 
	fp = rowmin((fx,fs)) 
	fd = colmin((fw\ fz)) 
	fp = min((min(beta * fp), 1)) 
	fd = min((min(beta * fd), 1)) 
}

// Take the step
    x = x + fp * dx
    s = s + fp * ds
    yy = yy + fd * dy
    w = w + fd * dw
    z = z + fd * dz
    gap = c * x - yy * b + w * u
}
	
// Return vector of estimates
	bb = -yy'
	return(bb)
		
}

end
