*! version 1.0.2 PR 30sep2004.
program define micombine7, eclass
version 7

if replay() {
	if "`e(cmd)'"!="micombine7" {
		error 301
	}
	di as text _n "Multiple imputation parameter estimates (" e(m) " imputations)"
	estimates display, `e(eform)'
	exit
}

gettoken cmd 0 : 0
if "`cmd'"=="stpm" {
	local dist 7
	local glm 0
	local qreg 0
	local xtgee 0
	local normal 0
}
else {
	cmdchk7 `cmd' 
	if `s(bad)' {
		di as error "invalid or unrecognised command, `cmd'"
		exit 198
	}
	/*
		dist=0 (normal), 1 (binomial), 2 (poisson), 3 (cox), 4 (glm),
		5 (xtgee), 6(ereg/weibull).
	*/
	local dist `s(dist)'
	local glm `s(isglm)'
	local qreg `s(isqreg)'
	local xtgee `s(isxtgee)'
	local normal `s(isnorm)'
}
syntax varlist(min=1 numeric) [if] [in] [aw fw pw iw] , [ IMPid(string) /*
*/ CC(varlist) noCONStant DEAD(varname) DETail Eform(passthru) Genxb(string) LRR * ]

if "`impid'"=="" {
	local impid _j
}
cap confirm var `impid'
if _rc {
	di as err "imputation identifier `impid' not found"
	exit 601
}

chkrowid
local I `s(I)'

if "`detail'"!="" {
	local detail noisily
}
else local detail
frac_cox "`dead'" `dist'
if "`constant'"=="noconstant" {
	if "`cmd'"=="fit" | "`cmd'"=="cox" {
		di as error "noconstant invalid with `cmd'"
		exit 198
	}
	local options "`options' noconstant"
}
if `dist'==7 {	/* stcox, streg, stpm */
	local y
	local yname _t
	local xvars `varlist'
}
else {
	gettoken y xvars : varlist
	local yname `y'
}

tempvar touse
quietly {
	marksample touse
	markout `touse' `varlist' `dead' `cc'
	if "`dead'"!="" {
		local dead "dead(`dead')"
	}

* Deal with weights.
	frac_wgt `"`exp'"' `touse' `"`weight'"'
	local wgt `r(wgt)'

	tempvar J
	egen int `J'=group(`impid') if `touse'
	sum `J', meanonly
	local m=r(max)
	if `m'<2 {
		di as error "there must be at least 2 imputations"
		exit 198
	}

	local nxvar: word count `xvars'
	if `nxvar'<1 {
		di as err "there must be at least one covariate"
		exit 198
	}
	local ncc: word count `cc'		/* could legitimately be zero */
	local nvar=`nxvar'+`ncc'		/* number of covariates in model */

	count if `touse'==1 & `J'==1
	local nobs=r(N)

* Compute model over m imputations
	tempname W Q B T QQ
	if "`genxb'"!="" {
		tempvar xb xbtmp
		gen `xb'=.
	}
	forvalues i=1/`m' {
		tempname Q`i'
		`detail' `cmd' `y' `xvars' `cc' if `touse'==1 & `J'==`i' `wgt', `options' `dead' `constant'
		if "`genxb'"!="" {
			predict `xbtmp' if `touse'==1 & `J'==`i', xb
			replace `xb'=`xbtmp' if  `touse'==1 & `J'==`i'
			drop `xbtmp'
		}
		matrix `Q`i''=e(b)
		if `i'==1 {
			matrix `Q'=e(b)
			matrix `W'=e(V)
		}
		else {
			matrix `Q'=`Q'+e(b)
			matrix `W'=`W'+e(V)
		}
	}
	if "`genxb'"!="" {
		sort `touse' `I' `J'
		by `touse' `I': gen `genxb'=sum(`xb')/`m' if `touse'==1
		by `touse' `I': replace `genxb'=`genxb'[_N] if _n<_N
		lab var `genxb' "Mean Linear Predictor (`m' imputations)"
	}
	matrix `Q'=`Q'/`m'		/* MI param estimates */
	matrix `W'=`W'/`m'
	local k=colsof(`Q')
	matrix `B'=J(`k',`k',0)
	forvalues i=1/`m' {
		matrix `QQ'=`Q`i''-`Q'
		if `i'==1 {
			matrix `B'=`QQ''*`QQ'
		}
		else matrix `B'=`B'+`QQ''*`QQ'
	}
	matrix `B'=`B'/(`m'-1)
	matrix `T'=`W'+(1+1/`m')*`B'	/* estimated VCE matrix */
	/*
		Relative increase in variance due to missing information (r) for
		each variable, and df and lambda, the fraction of missing information.
		All measures are unstable for low m. See Schafer (1997) p. 110.

		Note that BIF = sqrt(T/W) = sqrt(1 + (B/W)*(1+1/m)) = sqrt(1+r)
		is the between-imputation imprecision factor, i.e. the ratio
		of the SE derived from T to the SE derived from W,
		ignoring between-imputation variation in parameter estimates.
	*/
	tempname r lambda nu BIF
	matrix `r'=J(1,`k',0)
	matrix `lambda'=J(1,`k',0)
	matrix `nu'=J(1,`k',0)
	matrix `BIF'=J(1,`k',0)
	forvalues j=1/`k' {
		matrix `r'[1,`j']=(1+1/`m')*`B'[`j',`j']/`W'[`j',`j']
		matrix `nu'[1,`j']=(`m'-1)*(1+1/`r'[1,`j'])^2
		matrix `lambda'[1,`j']=(`r'[1,`j']+2/(`nu'[1,`j']+3))/(`r'[1,`j']+1)
		matrix `BIF'[1,`j']=sqrt(1+`r'[1,`j'])	/* = sqrt(`T'[`j',`j']/`W'[`j',`j']) */
	}
	* use all varnames
	local names: colnames(`Q1')
	matrix colnames `r'=`names'
	matrix colnames `nu'=`names'
	matrix colnames `lambda'=`names'
	matrix colnames `BIF'=`names'

	* Li, Raghunathan & Rubin (1991) estimates of T and nu1
	* for F test of all params=0 on k,nu1 degrees of freedom
	tempname r1 t BW TLRR
	matrix `BW'=`B'*syminv(`W')
	scalar `r1'=trace(`BW')*(1+1/`m')/`k'
	matrix `TLRR'=`W'*(1+`r1')
	scalar `t'=`k'*(`m'-1)
	
	matrix colnames `Q'=`names'
	matrix rownames `T'=`names'
	matrix colnames `T'=`names'
	matrix rownames `B'=`names'
	matrix colnames `B'=`names'
	matrix rownames `TLRR'=`names'
	matrix colnames `TLRR'=`names'

}
if `normal' {
	local dof dof(`k')
}
di as text _n "Multiple imputation parameter estimates (`m' imputations)"
if "`lrr'"!="" {
	di as text "[Using Li-Raghunathan-Rubin (LRR) estimate of VCE matrix]"
	estimates post `Q' `TLRR', depname(`yname') obs(`nobs')
	estimates matrix T `T'
}
else {
	estimates post `Q' `T', depname(`yname') obs(`nobs')
	estimates matrix TLRR `TLRR'
}
estimates display, `eform'
di as result `nobs' as text " observations."
estimates matrix B `B'
estimates matrix W `W'
estimates matrix r `r'
estimates matrix nu `nu'
estimates matrix lambda `lambda'
estimates matrix BIF `BIF'
estimates scalar r1=`r1'
estimates scalar nu1=cond(`t'>4, 4+(`t'-4)*(1+(1-2/`t')/`r1')^2, /*
 */ 0.5*`t'*(1+1/`k')*(1+1/`r1')^2)
estimates scalar m=`m'
estimates local eform `eform'
estimates local cmd micombine7
end

program define chkrowid, sclass
local I: char _dta[mi_id]
if "`I'"=="" {
	di as error "no row-identifier variable found - data may have incorrect format"
	exit 198
}
cap confirm var `I'
local rc=_rc
if `rc' {
	di as error "row-identifier variable `I' not found"
	exit `rc'
}
sret local I `I'
end
