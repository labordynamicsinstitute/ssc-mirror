*! blockboot v1.0 CFBaum & JOtero 06dec2024
*! modified  v1.1 cfb 04dec2024
*! modified  v1.2 jotero 4jun2025
*! modified  v1.3 cfb 27aug2025 for tsset checks
*! modified  v1.4 jotero 11nov2025 for nbb fix
*! This routine implements the stationary bootstrap for bootstrapping stationary, dependent series
*! The code draws on the MATLAB function stationary_bootstrap developed by Kevin Sheppard

capture program drop blockboot
program define blockboot, rclass
version 14

// make prefix and lblock required
syntax varlist(min=1 numeric ts fv) [if] [in], ///
								TYPE(string) ///
								PREfix(string) ///
								LBLOCK(string) ///
								[ SEED(integer -1) ///
								]
marksample touse
capt tsset
if _rc>0 {
	di as err  "The dataset must be tsset."
	exit 111
}
qui tsreport if `touse'
if r(N_gaps)>1 {
	di as err  "Only one panel unit can be specified."
	exit 198
}
markout `touse' `tvar'

loc schemes sbb cbb mbb nbb
loc wh : list posof "`type'" in schemes
if !`wh' {
  di as err "Error: type must be chosen from"
  display as error "                    sbb (stationary block bootstrap)"
  display as error "                    cbb (circular block bootstrap)"
  display as error "                    mbb (moving block bootstrap)"
  display as error "                    nbb (nonoverlapping block bootstrap)"
  error 198
}

if ("`lblock'" == "auto") {
	if ("`type'" == "sbb") {
		loc tauto sbb
	}
	else {
		loc tauto cbb
	}
}
else {
	loc tauto noauto
	loc _lblk `lblock'
}

tempvar trd
qui gen `trd' = _n if `touse'
qui sum `trd'
local initobs = r(min)
local lastobs = r(max)
local totalobs = `lastobs' - `initobs' + 1
// local nlastobs = `lastobs' - `lblock'  

tempvar _indices fid
g `fid' = _n 
  
/*

quietly tsreport if `touse'
if r(N_gaps) {
	display in red "sample may not contain gaps"
	exit
}

if `lblock' >= `lastobs' - `initobs' + 1 {
	display in red "Length of bootstrap block exceeds number of available observations"
}
*/

if `seed'!=-1 {
   local seednum = `seed'
   set seed `seednum'
}

	foreach x of varlist `varlist' {
		confirm new var `prefix'`x'
		qui putmata `fid' if `touse', replace
		if ("`tauto'"!="noauto") {
			mata: bstar("`x'","`touse'","`tauto'")
//		di "Optimal block boot size = " _lblk
			loc _lblk = _lblk
		}
		mata: `type'indx(`initobs',`lastobs',`totalobs',`_lblk')
		getmata (`_indices'`x') = indices, id(`fid') replace
		qui gen `prefix'`x' = `x'[`_indices'`x'] if `touse'
//		list `_indices'`x' `prefix'`x' , sep(0)
	}
	return local cmdname "blockboot"
	return local type "`type'"
	return local prefix "`prefix'"
	return scalar lblock = `_lblk'
	return local varlist "`varlist'"
	return scalar N = `totalobs'	
end

// mata: mata clear
mata:
// stationary block bootstrap 
void sbbindx(
				real scalar iniobs,
				real scalar endobs,
				real scalar nobs,
				real scalar lbck
				)
{
	external real colvector indices

	prob = 1/lbck	// Define the probability of a new block
	//nobs, prob, maxval
	indices = J(nobs,1,0)
	indices = runiformint(nobs,1, iniobs, endobs) :* (runiform(nobs, 1) :< prob)
	indices[1,1]= runiformint(1,1, iniobs, endobs)
	for (i=1;i<=nobs;i++) {
		indices[i] = indices[i]:>0 ? indices[i] : ///
		(indices[i-1]:<endobs ? indices[i-1]+1 : iniobs)
	}
}

// circular block bootstrap
void cbbindx(
				real scalar iniobs,
				real scalar endobs,
				real scalar nobs,
				real scalar lbck
				)
{
	external real colvector indices
	// iniobs endobs nobs lbck
	indices = J(nobs,1,0)
	for (i=1;i<=nobs;i=i+lbck) {
		indices[i,1] = runiformint(1,1, iniobs, endobs)
	}
	for (i=1;i<=nobs;i++) {
		indices[i,1] = indices[i,1]:>0 ? indices[i,1] : ///
		(indices[i-1,1]:<endobs ? indices[i-1,1]+1 : iniobs)
	}
}

// moving block bootstrap
void mbbindx(
				real scalar iniobs,
				real scalar endobs,
				real scalar nobs,
				real scalar lbck
				)
{
	external real colvector indices
	//nobs, lbck, maxval
	indices = J(nobs,1,0)
	for (i=1;i<=nobs;i=i+lbck) {
		indices[i,1] = runiformint(1,1, iniobs, nobs-lbck+1)
	}
	for (i=1;i<=nobs;i++) {
		indices[i,1] = indices[i,1]:>0 ? indices[i,1] : indices[i-1,1]+1
	}
}

// nonoverlapping block bootstrap
void nbbindx(
				real scalar iniobs,
				real scalar endobs,
				real scalar nobs,
				real scalar lbck
				)
{
	external real colvector indices
	//nobs, lbck, maxval
	numbck = trunc(nobs/lbck)	// Total  number of blocks
	obsbck = numbck*lbck		// Total number of observations in complete blocks
	idxini = J(nobs,1,.)
	indices = J(nobs,1,.)
	for (i=1;i<=obsbck;i=i+lbck) {
		idxini[i,1] = i
	}
	idx = select(idxini, rowmissing(idxini):==0)
	for (i=1;i<=obsbck;i=i+lbck) {
		pick = runiformint(1,1,1,numbck)
		indices[i,1] = idx[pick]
	}
	for (i=1;i<=obsbck;i++) {
		indices[i,1] = indices[i,1]:!=. ? indices[i,1] : indices[i-1,1]+1
	}
}

// Optimal block length

void bstar(
			string scalar vname,
			string scalar selvar,
			string scalar tauto
)
{
	real vector x
	real scalar BstarSB, BstarCB
	
	x = st_data(., vname, selvar)
	T = length(x)

	Kn = (5 > ceil(log10(length(x))) ? 5 : ceil(log10(T))) 
	mmax = ceil(sqrt(T))+Kn
	Bmax = ceil(3*sqrt(T) < T/3 ? 3*sqrt(T) : T/3)
	c = invnormal(0.975)
	
	rhokcrit = c*sqrt(log10(T)/T)

	// Computes autocorrelation
	mean_x = mean(x)
	var_x = mean((x :- mean_x) :^ 2)

	rhok = J(mmax, 1, .)
	insignif = J(mmax, 1, .)
	runsuminsignif = J(mmax-Kn+1, 1, .)
	
    for (k = 1; k <= mmax; k++) {
        x1 = x[1::(T - k)]
		T1 = length(x1)
        x2 = x[(1 + k)::T]
        rhok[k,1] = (mean((x1 :- mean_x) :* (x2 :- mean_x)) / var_x)*(T1/T)
    }
		
	for (k = 1; k <= mmax; k++) {
		insignif[k,1] = abs(rhok[k,1]) < rhokcrit	// Find insignificant autocorr
	}
	
	signif = 1 :- insignif	// Find significant autocorr
	sumsignif = sum(signif)
	
	for (k = 1; k <= mmax-Kn+1; k++) {
		runsuminsignif[k,1] = sum(insignif[(k::(k+Kn-1)),1])	// Running sum of Kn elements
	}
	
	maxindex((runsuminsignif :== Kn), 1, valueindex=., .)
	mhatindex = valueindex[1,1]

	if (mhatindex > 1) {
		mhat = mhatindex
	}
	else if (sumsignif > 0) {
		minindex((sumsignif :== 0), 1, valueindex=., .)
		mhatindex = valueindex[1,1]
		mhat = mhatindex
	}
	else if (sumsignif == 0) {
		mhat = 1
	}

	M = (2*mhat > mmax ? mmax : 2*mhat)
	
	// Computes autocovariances
	
	acov = J(2 * M + 1, 1, .)  // Preallocate result vector

    for (k = -M; k <= M; k++) {
        if (k < 0) {
            // Negative lag
            x1 = x[(1 - k)::T]
            x2 = x[1::(T + k)]
			T1 = length(x2)
        } else if (k > 0) {
            // Positive lag
            x1 = x[1::(T - k)]
			T1 = length(x1)
            x2 = x[(1 + k)::T]
        } else {
            // Zero lag
            x1 = x
			T1 = length(x1)
            x2 = x
        }
        acov[M + 1 + k] = (mean((x1 :- mean_x) :* (x2 :- mean_x)))*(T1/T)
    }
//    acov
	
	kk = (-M::M)
	lam = (abs(kk:/M):>=0):*(abs(kk:/M):<0.5):+2:*(1:-abs(kk:/M)):*(abs(kk:/M):>=0.5):*(abs(kk:/M):<=1)
	Ghat = sum(lam :* abs(kk) :* acov)
	DCBhat = (4/3)*sum(lam :* acov)^2
	DSBhat = 2*sum(lam :* acov)^2
	BstarSB = ((2*Ghat^2)/DSBhat)^(1/3)*T^(1/3)
	BstarCB = ((2*(Ghat^2)/DCBhat)^(1/3))*(T^(1/3))

	BstarSB = (BstarSB > Bmax ? Bmax : (BstarSB < 1 ? 1 : round(BstarSB)))
	BstarCB = (BstarCB > Bmax ? Bmax : (BstarCB < 1 ? 1 : ceil(BstarCB)))
	
	st_numscalar("_lblk", BstarCB)
	
	if (tauto=="sbb") { 
		st_numscalar("_lblk",BstarSB) 
	} 
}
end
