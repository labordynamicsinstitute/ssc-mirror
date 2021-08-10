
program define mediate , rclass
version 10.0
preserve

gettoken eqn 0 : 0, parse(" ,[") match(paren)
gettoken eqn2 0 : 0, parse(" ,[") match(paren)

if "`eqn2'"=="" {
nois di as error "You must specify two equations"
exit 198
}
gettoken modname1 var1 : eqn
gettoken modname2 var2 : eqn2
*[] are options

syntax  [if] [in] [fweight pweight iweight] [, SIMs(int 1000) SEED(int 0) vce(passthru) Level(cilevel)] MEDiate(varname) TREAT(string) 
marksample touse
gettoken depvar1 rhsvars1 : var1
gettoken depvar2 rhsvars2 : var2

markout `touse' `var1' `var2'
if `seed'>0 {
set seed `seed'
}

if "`depvar1'"~="`mediate'" {
nois di as error "Mediate variable not the dependent variable in equation 1"
exit 198
}

local tcheck : word count `treat'
if `tcheck'<1 {
nois di as error "No treatment variable specified. Please specify a treatment variable"
exit 198
}
if `tcheck'==1 {
nois di "Using 0 and 1 as treatment values"
local trf = 0
local trt = 1
}

if `tcheck'==2 {
nois di as error "Please specify a from and to value for treatment."
exit 198
}
if `tcheck'>3 {
nois di as error "Too many treatment values specified."
exit 198
}


   gettoken treat trtemp: treat
if `tcheck'==3 {
   gettoken trf trtemp : trtemp
   gettoken trt trtemp : trtemp
}

if `trf'==`trt' {
nois di as error "Treatment values are the same. Please specify different values for the treatment."
exit 198
}
   
if "`treat'"=="" {
nois di as error "No treatment variable specified. Please specify a treatment variable"
exit 198
}

local ck: list treat & rhsvars1
if "`ck'"~="`treat'" {
nois di as error "Treatment variable `treat' is not in equation 1."
exit 198
}
local ck: list treat & rhsvars2
if "`ck'"~="`treat'" {
nois di as error "Treatment variable `treat' is not in equation 2."
exit 198
}
local ck: list mediate & rhsvars2
if "`ck'"~="`mediate'" {
nois di as error "Mediate variable is not in equation 2."
exit 198
}


local rhs1 : list treat | rhsvars1
/* Treat first var in eq 2; mediate second var 
The two commands puts mediate first in rhs2 and then treatment first*/
local rhs2 : list mediate | rhsvars2
local rhs2 : list treat | rhs2

if "`modname1'"~="regress" & "`modname1'"~="logit" & "`modname1'"~="probit" {
nois di as error "Mediate only supports OLS, logit, and probit"
exit 198
}
if "`modname2'"~="regress" & "`modname2'"~="logit" & "`modname2'"~="probit"  {
nois di as error "The outcome stage only supports OLS, logit, and probit"
exit 198
}

if `sims'<1 {
nois di as error "The number of sims must be greater than 0"
exit 198
}

local N = _N
tempvar _s1 _s2
*** MODEL 1 : M as dependent variable
local cmdline1 `modname1' `depvar1' `rhs1' 

`cmdline1'  [`weight'`exp'] if `touse' , `vce'
gen `_s1'=e(sample)
tempname bm vm rmse by vy  
mat define `bm'=get(_b)
mat `vm' = vecdiag(cholesky(e(V)))
if "`modname1'"=="regress" {
scalar `rmse' = e(rmse)
}

local rhs1 : subinstr local rhs1 "_cons" "" ,
local samp1 = e(N)

*** MODEL 2 : Y as dependent variable
local cmdline2 `modname2' `depvar2' `rhs2' 

`cmdline2'  [`weight'`exp'] if `touse' , `vce'
gen `_s2'=e(sample)
mat define `by'=get(_b)

mat `vy' = vecdiag(cholesky(e(V)))

local rhs2 : subinstr local rhs2 "_cons" "" ,
local samp2 = e(N)

qui drop if ~`touse'

qui if `samp1'~=`samp2' {
nois di as error "There are missing values of Y. The command cannot be run."
exit 198
}

local N = _N

if `N'<`sims' {
qui set obs `sims'
local N = _N
nois di as text "The number of observations in the data is less than the number of simulations. Expanding the data to the number of simulations"
}
tempname wtvar
if "`exp'"~="" {
local wtlist : subinstr local exp "= " "" , all
mkmat `wtlist'  , mat(`wtvar')
}
if "`exp'"=="" {
mat `wtvar' =J(`N',1,1)
}


*Depending on model use different mata commands
if "`modname1'"=="regress" {
mata: med_reg("`rmse'",`sims',`seed',`N',"`bm'","`vm'","`rhs1'",`trf',`trt')
}
if "`modname1'"=="logit" {
mata: med_logit(`sims',`seed',`N',"`bm'","`vm'","`rhs1'",`trf',`trt')
}
if "`modname1'"=="probit" {
mata: med_probit(`sims',`seed',`N',"`bm'","`vm'","`rhs1'",`trf',`trt')
}

if "`modname2'"=="regress" {
mata: med_tmod(`sims',`seed',`N',"`by'","`vy'","`rhs2'",`trf',`trt')
}
if "`modname2'"=="logit" {
mata: med_tlogit(`sims',`seed',`N',"`by'","`vy'","`rhs2'",`trf',`trt')
}
if "`modname2'"=="probit" {
mata: med_tprobit(`sims',`seed',`N',"`by'","`vy'","`rhs2'",`trf',`trt')
}


local out delta1 d1 delta0 d0  zeta1 z1 zeta0 z0 tau t
qui while "`out'" ~="" {
 gettoken var out : out
 gettoken s out : out
 gettoken m tmpvrs2: tmpvrs2
 macro dir
 local avg_`var'  `m'
summ `avg_`var''
local `s'mu =r(mean)
tempname ll ul
local `ll' = round((100-`level')/2,.01)
local `ul' = round((100+`level')/2,.01)
di "``ll''" " ``ul''"
_pctile `avg_`var'' , p(``ll'' ``ul'')
 local `s'lo=r(r1)
local `s'hi=r(r2)
return scalar `var'=``s'mu'
return scalar `var'lo=``s'lo'
return scalar `var'hi=``s'hi'
}

nois {
di as text "{hline 25}{c TT}{hline 52}"
di as text   "        Effect           {c |}  Mean           [`level'% Conf. Interval]"
di as text "{hline 25}{c +}{hline 52}"
di as result "        ACME1            {c |} "     as result %9.0g     `d1mu' "     "   as result %9.0g  `d1lo' "     "   as result %9.0g  `d1hi'    "
di as result "        ACME0            {c |} "     as result %9.0g     `d0mu' "     "   as result %9.0g  `d0lo' "     "   as result %9.0g  `d0hi'    "
di as result "        Direct Effect 1  {c |} "     as result %9.0g     `z1mu' "     "   as result %9.0g  `z1lo' "     "  as result %9.0g  `z1hi'    "
di as result "        Direct Effect 0  {c |} "     as result %9.0g     `z0mu' "     "   as result %9.0g  `z0lo' "     "  as result %9.0g  `z0hi'    "
di as result "        Total Effect     {c |} "     as result %9.0g     `tmu'  "     "   as result %9.0g  `tlo' "     "   as result %9.0g  `thi'    "
di as text "{hline 25}{c BT}{hline 52}"
}

restore
end

mata
void med_reg(string scalar rmse, real scalar sims, real scalar seed, real scalar n, string colvector bm, string colvector vm, string scalar rhs1, real scalar trf, real scalar trt)
{

 bm = st_matrix(st_local("bm"))
 vm = st_matrix(st_local("vm"))
 rmse=st_numscalar(st_local("rmse"))
rseed(seed)
/// define matrices to use within the program
real matrix MModel_sim , MModel, MModel0, MModel1, predM1, predM0, error
real rowvector ones
real scalar j 
/// coeffient draws for m model
MModel_sim = rnormal(sims,1,bm, vm)'
error = rnormal(n,sims,0,rmse)

ones = J(n,1,1)
from = J(n,1,trf)
to = J(n,1,trt)
MModel=(st_data(.,tokens(rhs1)),ones)

MModel0 = MModel
MModel1 = MModel
/// set t=0 or from for control and t=1 or to for treat

MModel0[.,1] = from 
MModel1[.,1] = to 


predM1=J(n,sims,0)
predM0=J(n,sims,0)
for(j=1; j<=sims; j++) {
predM1[,j] = predM1[,j]+MModel1*MModel_sim[,j] 
predM0[,j] = predM0[,j]+MModel0*MModel_sim[,j] 
predM1[,j] = predM1[,j]+error[,j]
predM0[,j] = predM0[,j]+error[,j]

}

st_matrix("predM1",predM1)
st_matrix("predM0",predM0)

}
end

mata
void med_logit(real scalar sims, real scalar seed, real scalar n, string colvector bm, string colvector vm, string scalar rhs1, real scalar trf, real scalar trt)
{
 bm = st_matrix(st_local("bm"))
 vm = st_matrix(st_local("vm"))
rseed(seed)

real matrix MModel_sim , MModel, MModel0, MModel1, predM1, predM0, predM1_temp, predM0_temp
real rowvector ones
real scalar j

MModel_sim = rnormal(sims,1,bm, vm)'
MModel_sim[.,1..10]
ones = J(n,1,1)
from = J(n,1,trf)
to = J(n,1,trt)
MModel=(st_data(.,tokens(rhs1)),ones)

MModel0 = MModel
MModel1 = MModel
MModel0[.,1] = from 
MModel1[.,1] = to 

predM1_temp=J(n,sims,0)
predM1=J(n,sims,0)
predM0_temp=J(n,sims,0)
predM0=J(n,sims,0)
for(j=1; j<=sims; j++) {
predM1_temp[,j] = predM1_temp[,j]+MModel1*MModel_sim[,j]
predM0_temp[,j] = predM0_temp[,j]+MModel0*MModel_sim[,j]
  predM1_temp[,j]=exp(predM1_temp[,j]) :/ (exp(predM1_temp[,j]):+ 1)
  predM0_temp[,j]=exp(predM0_temp[,j]) :/ (exp(predM0_temp[,j]):+ 1)
  rseed(seed)
 predM1[,j] = predM1_temp[,j] :> runiform(n,1)
 predM0[,j] = predM0_temp[,j] :> runiform(n,1)
}
st_matrix("predM1",predM1)
st_matrix("predM0",predM0)

}
end

mata
void med_probit(real scalar sims, real scalar seed, real scalar n, string colvector bm, string colvector vm, string scalar rhs1, real scalar trf, real scalar trt)
{
 bm = st_matrix(st_local("bm"))
 vm = st_matrix(st_local("vm"))
rseed(seed)

real matrix MModel_sim , MModel, MModel0, MModel1, predM1, predM0, predM1_temp, predM0_temp
real rowvector ones
real scalar j

MModel_sim = rnormal(sims,1,bm, vm)'
ones = J(n,1,1)
from = J(n,1,trf)
to = J(n,1,trt)
MModel=(st_data(.,tokens(rhs1)),ones)

MModel0 = MModel
MModel1 = MModel
MModel0[.,1] = from 
MModel1[.,1] = to 

predM1_temp=J(n,sims,0)
predM1=J(n,sims,0)
predM0_temp=J(n,sims,0)
predM0=J(n,sims,0)
for(j=1; j<=sims; j++) {
predM1_temp[,j] = predM1_temp[,j]+MModel1*MModel_sim[,j]
predM0_temp[,j] = predM0_temp[,j]+MModel0*MModel_sim[,j]
  predM1_temp[,j]=normal(predM1_temp[,j]) 
  predM0_temp[,j]=normal(predM0_temp[,j]) 
  rseed(seed)
 predM1[,j] = predM1_temp[,j] :> runiform(n,1)
 predM0[,j] = predM0_temp[,j] :> runiform(n,1)
}
st_matrix("predM1",predM1)
st_matrix("predM0",predM0)

}
end

mata

void med_tmod( real scalar sims, real scalar seed, real scalar n, string colvector by, string colvector vy, string scalar rhs2, real scalar trf, real scalar trt)
{
 by = st_matrix(st_local("by"))
 vy = st_matrix(st_local("vy"))

rseed(seed)

real matrix TModel_sim , TModel, TModel0, TModel1, avg_delta1, avg_delta0 , predM1 , predM0
pointer(real matrix) rowvector pmat
real rowvector ones 
real colvector kavg_delta1, kavg_delta0 , wt
real scalar i, j 
predM1 =st_matrix("predM1")
 predM0=st_matrix("predM0")
 wt = st_matrix(st_local("wtvar"))
ones = J(n,1,1)
from = J(n,1,trf)
to = J(n,1,trt)
TModel_sim = rnormal(sims,1,by, vy)'
TModel=(st_data(.,tokens(rhs2)),ones)

pmat = J(1,10,NULL)
for (i=1;i<=9; i++) pmat[i] = &(J(n,sims,.))

TModel0 = TModel
TModel1 = TModel
TModel1[.,1]=to
TModel0[.,1]=from

for(j=1; j<=sims; j++) {
 TModel1[,2]=predM1[.,j]
 TModel0[,2]=predM1[.,j]
(*pmat[1])[,j] = TModel1* TModel_sim[,j] /*prob1_t1*/
(*pmat[2])[,j] = TModel0* TModel_sim[,j] /*prob1_t0*/
TModel1[,2]=predM0[.,j]
TModel0[,2]=predM0[.,j]
(*pmat[3])[,j] = TModel1* TModel_sim[,j] /*prob0_t1*/
(*pmat[4])[,j] = TModel0* TModel_sim[,j] /*prob0_t0*/
(*pmat[5])[,j]=(*pmat[1])[,j] - (*pmat[3])[,j] /*delta1*/
(*pmat[6])[,j]=(*pmat[2])[,j] - (*pmat[4])[,j] /*delta0*/
(*pmat[7])[,j]=(*pmat[1])[,j] - (*pmat[4])[,j] /*tau*/
(*pmat[8])[,j]=(*pmat[1])[,j] - (*pmat[2])[,j] /*zeta1*/
(*pmat[9])[,j]=(*pmat[3])[,j] - (*pmat[4])[,j] /*zeta0*/

}

avg_delta1=J(1,sims,0)
avg_delta0=J(1,sims,0)
avg_tau=J(1,sims,0)
avg_zeta1=J(1,sims,0)
avg_zeta0=J(1,sims,0)

for(j=1; j<=sims; j++) {
avg_delta1[1,j]=mean((*pmat[5])[,j], wt )
avg_delta0[1,j]=mean((*pmat[6])[,j], wt)
avg_tau[1,j]=mean((*pmat[7])[,j], wt)
avg_zeta1[1,j]=mean((*pmat[8])[,j], wt)
avg_zeta0[1,j]=mean((*pmat[9])[,j], wt)
}

kavg_delta1 = st_addvar("float",st_tempname())
kavg_delta0 = st_addvar("float",st_tempname())

kavg_zeta1 = st_addvar("float",st_tempname())
kavg_zeta0 = st_addvar("float",st_tempname())
kavg_tau = st_addvar("float",st_tempname())

 names = st_varname((kavg_delta1, kavg_delta0, kavg_zeta1, kavg_zeta0, kavg_tau))
 st_local("tmpvrs2", invtokens(names))

st_store((1,rows(avg_delta1')),kavg_delta1,avg_delta1')
st_store((1,rows(avg_delta0')),kavg_delta0,avg_delta0')
st_store((1,rows(avg_zeta1')),kavg_zeta1,avg_zeta1')
st_store((1,rows(avg_zeta0')),kavg_zeta0,avg_zeta0')
st_store((1,rows(avg_tau')),kavg_tau,avg_tau')
}

end

mata
void med_tprobit( real scalar sims, real scalar seed, real scalar n, string colvector by, string colvector vy, string scalar rhs2, real scalar trf, real scalar trt)
{
 by = st_matrix(st_local("by"))
 vy = st_matrix(st_local("vy"))

rseed(seed)

real matrix TModel_sim , TModel, TModel0, TModel1, avg_delta1, avg_delta0 , predM1 , predM0
pointer(real matrix) rowvector pmat
real rowvector ones 
real colvector kavg_delta1, kavg_delta0 , wt
real scalar i, j 
predM1 =st_matrix("predM1")
 predM0=st_matrix("predM0")
 wt = st_matrix(st_local("wtvar"))
ones = J(n,1,1)
from = J(n,1,trf)
to = J(n,1,trt)
TModel_sim = rnormal(sims,1,by, vy)'
TModel=(st_data(.,tokens(rhs2)),ones)

pmat = J(1,10,NULL)
for (i=1;i<=9; i++) pmat[i] = &(J(n,sims,.))

TModel0 = TModel
TModel1 = TModel
TModel1[.,1]=to
TModel0[.,1]=from

for(j=1; j<=sims; j++) {
 TModel1[,2]=predM1[.,j]
 TModel0[,2]=predM1[.,j]
(*pmat[1])[,j] = TModel1* TModel_sim[,j]  /*prob1_t1*/
(*pmat[2])[,j] = TModel0* TModel_sim[,j]  /*prob1_t0*/

(*pmat[1])[,j] = normal((*pmat[1])[,j]) /*prob1_t1*/
(*pmat[2])[,j] = normal((*pmat[2])[,j]) /*prob1_t0*/
rseed(seed)
TModel1[,2]=predM0[.,j]
TModel0[,2]=predM0[.,j]
(*pmat[3])[,j] = TModel1* TModel_sim[,j]  /*prob0_t1*/
(*pmat[4])[,j] = TModel0* TModel_sim[,j]  /*prob0_t0*/
(*pmat[3])[,j] = normal((*pmat[3])[,j]) /*prob0_t1*/
(*pmat[4])[,j] = normal((*pmat[4])[,j]) /*prob0_t0*/
rseed(seed)

(*pmat[5])[,j]=(*pmat[1])[,j]-(*pmat[3])[,j] /*delta1*/
(*pmat[6])[,j]=(*pmat[2])[,j]-(*pmat[4])[,j] /*delta0*/
(*pmat[7])[,j]=(*pmat[1])[,j]-(*pmat[4])[,j] /*tau*/
(*pmat[8])[,j]=(*pmat[1])[,j]-(*pmat[2])[,j] /*zeta1*/
(*pmat[9])[,j]=(*pmat[3])[,j]-(*pmat[4])[,j] /*zeta0*/

}


avg_delta1=J(1,sims,0)
avg_delta0=J(1,sims,0)
avg_tau=J(1,sims,0)
avg_zeta1=J(1,sims,0)
avg_zeta0=J(1,sims,0)
for(j=1; j<=sims; j++) {
avg_delta1[1,j]=mean((*pmat[5])[,j], wt)
avg_delta0[1,j]=mean((*pmat[6])[,j] , wt)
avg_tau[1,j]=mean((*pmat[7])[,j], wt)
avg_zeta1[1,j]=mean((*pmat[8])[,j], wt)
avg_zeta0[1,j]=mean((*pmat[9])[,j], wt)
}
kavg_delta1 = st_addvar("float",st_tempname())
kavg_delta0 = st_addvar("float",st_tempname())

kavg_zeta1 = st_addvar("float",st_tempname())
kavg_zeta0 = st_addvar("float",st_tempname())
kavg_tau = st_addvar("float",st_tempname())

 names = st_varname((kavg_delta1, kavg_delta0, kavg_zeta1, kavg_zeta0, kavg_tau))
 st_local("tmpvrs2", invtokens(names))

st_store((1,rows(avg_delta1')),kavg_delta1,avg_delta1')
st_store((1,rows(avg_delta0')),kavg_delta0,avg_delta0')
st_store((1,rows(avg_zeta1')),kavg_zeta1,avg_zeta1')
st_store((1,rows(avg_zeta0')),kavg_zeta0,avg_zeta0')
st_store((1,rows(avg_tau')),kavg_tau,avg_tau')

}

end


mata
void med_tlogit( real scalar sims, real scalar seed, real scalar n, string colvector by, string colvector vy, string scalar rhs2, real scalar trf, real scalar trt)
{
 by = st_matrix(st_local("by"))
 vy = st_matrix(st_local("vy"))

rseed(seed)
real matrix TModel_sim , TModel, TModel0, TModel1, avg_delta1, avg_delta0 , predM1 , predM0
pointer(real matrix) rowvector pmat
real rowvector ones 
real colvector kavg_delta1, kavg_delta0 , wt
real scalar i, j 
predM1 =st_matrix("predM1")
 predM0=st_matrix("predM0")
 wt = st_matrix(st_local("wtvar"))
 
ones = J(n,1,1)
from = J(n,1,trf)
to = J(n,1,trt)
TModel_sim = rnormal(sims,1,by, vy)'
TModel=(st_data(.,tokens(rhs2)),ones)

pmat = J(1,10,NULL)
for (i=1;i<=9; i++) pmat[i] = &(J(n,sims,.))

TModel0 = TModel
TModel1 = TModel
TModel1[.,1]=to
TModel0[.,1]=from

for(j=1; j<=sims; j++) {
 TModel1[,2]=predM1[.,j]
 TModel0[,2]=predM1[.,j]
(*pmat[1])[,j] = TModel1* TModel_sim[,j]  /*prob1_t1*/
(*pmat[2])[,j] = TModel0* TModel_sim[,j]  /*prob1_t0*/
 (*pmat[1])[,j] = exp((*pmat[1])[,j]) :/ (exp((*pmat[1])[,j]):+ 1) /*prob1_t1*/
 (*pmat[2])[,j] = exp((*pmat[2])[,j]) :/ (exp((*pmat[2])[,j]):+ 1)  /*prob1_t0*/
rseed(seed)
TModel1[,2]=predM0[.,j]
TModel0[,2]=predM0[.,j]
(*pmat[3])[,j] = TModel1* TModel_sim[,j]  /*prob0_t1*/
(*pmat[4])[,j] = TModel0* TModel_sim[,j]  /*prob0_t0*/
(*pmat[3])[,j] = exp((*pmat[3])[,j]) :/ (exp((*pmat[3])[,j]):+ 1) /*prob0_t1*/
(*pmat[4])[,j] = exp((*pmat[4])[,j]) :/ (exp((*pmat[4])[,j]):+ 1) /*prob0_t0*/
rseed(seed)

(*pmat[5])[,j]=(*pmat[1])[,j]-(*pmat[3])[,j] /*delta1*/
(*pmat[6])[,j]=(*pmat[2])[,j]-(*pmat[4])[,j] /*delta0*/
(*pmat[7])[,j]=(*pmat[1])[,j]-(*pmat[4])[,j] /*tau*/
(*pmat[8])[,j]=(*pmat[1])[,j]-(*pmat[2])[,j] /*zeta1*/
(*pmat[9])[,j]=(*pmat[3])[,j]-(*pmat[4])[,j] /*zeta0*/

}

avg_delta1=J(1,sims,0)
avg_delta0=J(1,sims,0)
avg_tau=J(1,sims,0)
avg_zeta1=J(1,sims,0)
avg_zeta0=J(1,sims,0)
for(j=1; j<=sims; j++) {
avg_delta1[1,j]=mean((*pmat[5])[,j] , wt)
avg_delta0[1,j]=mean((*pmat[6])[,j] , wt)
avg_tau[1,j]=mean((*pmat[7])[,j], wt)
avg_zeta1[1,j]=mean((*pmat[8])[,j], wt)
avg_zeta0[1,j]=mean((*pmat[9])[,j], wt)
}

kavg_delta1 = st_addvar("float",st_tempname())
kavg_delta0 = st_addvar("float",st_tempname())

kavg_zeta1 = st_addvar("float",st_tempname())
kavg_zeta0 = st_addvar("float",st_tempname())
kavg_tau = st_addvar("float",st_tempname())

 names = st_varname((kavg_delta1, kavg_delta0, kavg_zeta1, kavg_zeta0, kavg_tau))
 st_local("tmpvrs2", invtokens(names))

st_store((1,rows(avg_delta1')),kavg_delta1,avg_delta1')
st_store((1,rows(avg_delta0')),kavg_delta0,avg_delta0')
st_store((1,rows(avg_zeta1')),kavg_zeta1,avg_zeta1')
st_store((1,rows(avg_zeta0')),kavg_zeta0,avg_zeta0')
st_store((1,rows(avg_tau')),kavg_tau,avg_tau')

}

end

