/*
User-written Stata ado
Estimates linear Fixed-Effects model with Individual-specific Slopes (FEIS)
Author: Volker Ludwig
Date this version: 23-07-2015
*/


version 12

mata:
void _feis_est(string scalar id, string scalar av, string scalar uv, string scalar slope, string scalar touse, string scalar noconstant, string scalar cluster, string scalar sp, string scalar transformed) 
{

/* get data matrix */
ID=st_data(., id, touse)
Y=st_data(., av, touse)
X=st_data(., tokens(uv), touse)


if (strlen(slope)>0) {
	Z=st_data(., tokens(slope), touse)
	if (strlen(noconstant)==0) {
		real colvector c
		c=J(rows(Z),1,1)
		Z=(Z,c)
	}
}
else if (strlen(slope)==0 & strlen(noconstant)==0) {
	Z=J(rows(Y),1,1)
}


/* set up panel data info matrix (identifies submatrix of units i) */ 
info = panelsetup(ID, 1, cols(Z)+1)


/* transform data matrix (premultiply by m), store transformed dep.var. in AV, transformed indep.vars in UV */
real colvector AV
real matrix UV
UV=J(0,cols(X),.)
real matrix m
i=1
while (i<=rows(info)) { 
	panelsubview(z, Z, i, info)
	panelsubview(x, X, i, info)
	panelsubview(y, Y, i, info)
	m=I(rows(z))-z*invsym(cross(z, z))*z'
	i++
	y=m*y
	AV=(AV\y)
	x=m*x
	UV=(UV\x)
}

/* add transformed data to current data set */
if (strlen(transformed)>0) {
	name = transformed + av
	st_store(., st_addvar("double", name), touse, AV)
	xvars = J(1,cols(UV),tokens(uv))
	i=1
	while (i<=cols(UV)) {
	name = transformed + xvars[i]
		st_store(., st_addvar("double", name), touse, UV[.,i])
		i++
	}
}

/* compute coefficient vector */
real colvector b
b=invsym(cross(UV, UV))*UV'*AV

/* compute residual vector */
real colvector u
u=AV-(UV*b)

/* compute variance matrix */
real matrix v
real scalar mindf
real scalar sigma
if (strlen(cluster)==0) {
	mindf=rows(info)*cols(Z)+cols(X) 
	sigma=sum(u:*u)/(rows(u)-mindf)
	v=sigma*invsym(cross(UV, UV))
}
if (strlen(cluster)>0) {
	mindf=cols(Z)+cols(X) /* ??? should be mindf=rows(info)*cols(Z)+cols(X) ??? */
	v=invsym(cross(UV, UV))
	st_store(., st_addvar("double", "__c1__"), touse, u)
}


/* compute R2 within */
real scalar rss
rss=sum(u:*u)
real scalar tss
tss=sum((AV):*(AV))
real scalar r2
r2=1-(rss/tss)

/* compute APE for ind. constants and slopes */
if (strlen(sp)>0) {
	real colvector alpha
	alpha=invsym(cross(Z, Z))*Z'*(Y-X*b)
}

/* pass results on to stata */
st_matrix("b", b')
st_matrix("V", v)
st_numscalar("mindf", mindf)
st_numscalar("N_g", rows(info))
st_numscalar("N_obs", rows(u))
info=info[.,2]-info[.,1]
st_numscalar("T_min", colmin(info)+1)
st_numscalar("T_max", colmax(info)+1)
st_numscalar("T_avg", sum(info)/rows(info)+1)
if (strlen(sp)>0) {
	st_matrix("a", alpha')
}
st_numscalar("R2", r2)

}
end



capture program drop xtfeis
program define xtfeis, eclass
syntax varlist (min=2 numeric) [if] [in], [SLope(varlist numeric)] [NOConstant] [i(varname numeric)] [t(varname numeric)] [cluster(varname)] [sp] [transformed(string)]

* Check group variable i() and time variable t()
if length("`i'") == 0 {	
	local i = "`_dta[iis]'"
	if length("`i'") == 0 {
		di in red "you must specify a group variable to identify panels"
		di in red "use option -i()- or command -xtset-"
		exit 198
	}
}
if length("`t'") == 0 {	
	local t = "`_dta[tis]'"
	if length("`t'") == 0 {
		di in red "you must specify a time variable to identify panels"
		di in red "use option -t()- or command -xtset-"
		exit 198
	}
}

* Check groups are nested within Clusters
if length("`cluster'") > 0 { 
	quietly {
		bys `i' (`t') : ge __check__ = `cluster'!=`cluster'[_n-1] & _n>1
		su __check__
		drop __check__
	}
	if r(mean)>0 {
		di in red "group variable i must be nested within clusters"
		exit 198
	}
}

* Check at least slope or constant
if length("`noconstant'")>0 & length("`slope'")==0 {	
	di in red "you must specify a slope variable or allow for individual constant"
	exit 198
}

* Expand macros
marksample touse
unab varlist : `varlist'
if length("`slope'")>0 {
	unab slope : `slope'
}
unab i : `i'
markout `touse' `slope' `i' `cluster'
qbys `i' : gen byte __no__=sum(`touse')
local s : word count `slope'
local s=`s'+1
if length("`noconstant'")==0 {
	local s=`s'+1
}
qbys `i' : replace __no__=. if __no__[_N]<`s'
qbys `i' : replace __no__=1 if __no__[_N]>=`s' & __no__[_N]<.
markout `touse' `slope' `i' `cluster' __no__
qui drop __no__

tokenize `varlist'
local av `1'
macro shift
local uv `*'
local id `i'

* invoke mata function
mata: _feis_est("`id'", "`av'", "`uv'", "`slope'", "`touse'", "`noconstant'", "`cluster'", "`sp'", "`transformed'")

* compute panel-robust s.e.
qui reg `av' `uv' if `touse', nocons
mat beta=e(b)
mat beta=b
mat colnames beta = `uv'
mat Var=e(V)
local mindf=mindf
local df_r=N_obs-`mindf'
if length("`cluster'")>0 {
	mat rownames V = `uv'
	mat colnames V = `uv'
	_robust __c1__ if `touse', v(V) cluster(`cluster') minus(`mindf')	
	drop __c1__
	local df_r=`r(df_r)'
}
mat Var=V
mat rownames Var = `uv'
mat colnames Var = `uv'
ereturn post beta Var, esample(`touse') depname(`av') dof(`df_r')
ereturn local ivar "`i'"
ereturn scalar N=N_obs
ereturn scalar N_g=N_g
ereturn scalar g_min=T_min
ereturn scalar g_avg=T_avg
ereturn scalar g_max=T_max
ereturn scalar r2_w=R2
ereturn local cmd "xtfeis"

#delimit ;
di _n in gr "Fixed-effects regression with individual-specific slopes (FEIS)" _n ;
        di in gr "Group variable: " in ye abbrev("`e(ivar)'",12) in gr
		   _col(49) in gr "Number of obs" _col(68) "="
                _col(70) in ye %9.0f e(N) ;
		di in gr _col(49) "Number of groups" _col(68) "="
                _col(70) in ye %9.0g e(N_g) _n ;
        di in gr "R-sq:  within  = " in ye %6.4f e(r2_w)
                _col(49) in gr "Obs per group: min" _col(68) "="
                _col(70) in ye %9.0g e(g_min) ;
        di in gr 
                _col(64) in gr "avg" _col(68) "="
                _col(70) in ye %9.1f e(g_avg) ;
        di in gr 
                _col(64) in gr "max" _col(68) "="
                _col(70) in ye %9.0g e(g_max) _n ;

if length("`cluster'")>0 {;
	di _n in gr "Standard errors adjusted for clusters in " in gr "`cluster'" _n ;
};

#delimit cr
ereturn display

cap drop __c1__

end








