program define hazdcmp, eclass
*! version 1.0 25jan2022 Dan Powers & Hiro Yoshioka
version 15	
syntax varlist [pw], by(varname) id(varname) OFFset(varname) [REVerse SCAle(integer 1) CLUSter(varname) ROBust DISCrete]
tempname matrix
capture tab `by', matrow(`matrix')

if ("`offset'"==""){
   di as error "offset must be specified"
}

if _rc==0 & r(r)!=2 {
   di as error "group variable (i.e., `by') must take exactly two values"
}
else{
gettoken depvar varlist: varlist

local weight [`weight'`exp']

/////   computing means (id-level) and determining high-low outcome order
	
if substr("`weight'",2,2)=="pw" {
      forval row = 1/2 {
		mata:wv`row'=0
		mata:st_view(wv`row', ., (tokens("`wv'")), "`touse'")
		mata:dv`row'=0
		mata:st_view(dv`row', ., (tokens("`depvar'")), "`touse'")
		mata:toff`row'=0
		mata:st_view(dv`row', ., "`offset'", "`touse'")
		mata:m`row'=sum(dv`row':*wv`row')/sum(exp(toff`row'):*wv`row')
		mata:st_matrix("m`row'", m`row')
local m`row' = m`row'[1,1]
		}
	}
    else{
      forval row = 1/2 {
		local val =  `matrix'[`row',1]
        	tempvar t_dep`row'
       	qui egen `t_dep`row''=total(`depvar') if `by'==`val'
        	tempvar t_exp`row'
        	qui egen `t_exp`row''=total(exp(`offset')) if `by'==`val'
        	tempvar rate`row'
        	qui gen `rate`row''=`t_dep`row''/`t_exp`row''
	  	sum `rate`row'' if `by'==`val', meanonly
local m`row' = r(mean)
		}
    }

if (`m2'>=`m1' & "`reverse'"=="") | (`m2'<`m1' & "`reverse'"!="") {
		local val0 = `matrix'[2,1]
		local val1 = `matrix'[1,1]
	}
	else {
		local val0 = `matrix'[1,1]
		local val1 = `matrix'[2,1]
		}
if ("`scale'" == "") {
       	local scale = 1 
   	 }
    else {
       	local scale = `scale'
    }

//// handle model options robust and cluster


if ("`robust'" !="") {
 local ropt = "robust"
  }
   else {
   local ropt = ""
}



if ("`cluster'" !="") {
  local copt = "cluster(`cluster')"
  }
  else { 
  local copt = ""
 }




//// estimation by group

forval i = 0/1 {

if ("`discrete'" == "") {
// default (poisson regression)
  qui poisson `depvar' `varlist' `weight' if `by'==`val`i'', offset(`offset') nocons `ropt' `copt'  
  }
// otherwise (logistic regression)  
  else {
  qui logit `depvar' `varlist' `weight' if `by'==`val`i'', offset(`offset') nocons `ropt' `copt'
  }
local lab`i' "`by'==`val`i''"
local df`i' = e(df_m)

tempvar touse
qui gen `touse'=0
qui replace `touse'=1 if `by'==`val`i''
mata: indx`i'=0
mata: st_view(indx`i', ., (tokens("`varlist'")), "`touse'")
mata: indx`i'=indx`i'
mata: b`i'=st_matrix("e(b)")
mata: varb`i'=st_matrix("e(V)")
mata: off`i'=0
mata: st_view(off`i', ., "`offset'", "`touse'")
mata: off`i'=off`i'
tempvar id`i'
tempvar awt`i'
tempvar nwt`i'
qui gen `id`i'' = `id' if `by' == `val`i''
qui bysort `id': egen `nwt`i'' = count(`id`i'')
qui gen `awt`i'' = 1/`nwt`i''
local nv : word count `varlist'
mata: mx`i' = J(1, `nv', .)

forval j = 1/`nv' {
  local var`j' : word `j' of `varlist'
  qui sum `var`j'' [iw = `awt`i''],  meanonly
  mata: mx`i'[1, `j'] = `r(mean)'
	}

mata: mx`i'= mean(mx`i')  // individ-level means
 }

// check if the number of independent variables
// included in each model is identical

if `df0'!=`df1' {
		di as error "Number of regressors differs between the groups"
		di as error "Perhaps a variable was dropped in one of the groups defined by `by'"
		exit
}

//// estimation

if ("`discrete'" == "") {
mata:PDF00=f_pois(indx0,b0,off0)
mata:PDF10=f_pois(indx1,b1,off1)
mata:PDF11=f_pois(indx1,b1,off1)
mata:E=sum(F_pois(indx0, b0, off0))/sum(exp(off0)) - sum(F_pois(indx1, b0, off1))/sum(exp(off1))
mata:st_matrix("E", E)
mata:C=sum(F_pois(indx1, b0, off1))/sum(exp(off1)) - sum(F_pois(indx1, b1, off1))/sum(exp(off1))
mata:st_matrix("C", C)
mata:Wdx=Wdx_F(mx0, mx1, b0)
mata:Wdb=Wdb_F(b0, b1, mx1)
mata:wbA=dwA_F(b0, b1, mx1)
mata:wbB=dwB_F(b0, b1, mx1)
mata:dWx=dW_F(b0, mx0, mx1)
}

else  {
mata:PDF00=f_lgt(indx0,b0,off0)
mata:PDF10=f_lgt(indx1,b0,off1)
mata:PDF11=f_lgt(indx1,b1,off1)
mata:E=sum(F_lgt(indx0, b0, off0))/sum(exp(off0)) - sum(F_lgt(indx1, b0, off1))/sum(exp(off1))
mata:st_matrix("E", E)
mata:C=sum(F_lgt(indx1, b0, off1))/sum(exp(off1)) - sum(F_lgt(indx1, b1, off1))/sum(exp(off1))
mata:st_matrix("C", C)
mata:Wdx=Wdx_F(mx0, mx1, b0)
mata:Wdb=Wdb_F(b0, b1, mx1)
mata:wbA=dwA_F(b0, b1, mx1)
mata:wbB=dwB_F(b0, b1, mx1)
mata:dWx=dW_F(b0, mx0, mx1)
}

mata:dCdb1=dCdb1(indx1, Wdb, wbA, off1, PDF10, C)
mata:dCdb2=dCdb2(indx1, Wdb, wbB, off1, PDF11, C)
mata:dEdb= dEdb(indx0, indx1, Wdx, dWx, E, off0, off1, PDF00, PDF10)
mata:Var_E_k=varcomp(dEdb, varb0)
mata:seWdx=colsum(sqrt(diag(Var_E_k)))
mata:st_matrix("seWdx", seWdx)
mata:Var_C_k=varcoef(dCdb1, dCdb2, varb0, varb1)
mata:seWdb=colsum(sqrt(diag(Var_C_k)))
mata:st_matrix("seWdb", seWdb)
mata:dEdb0=dEdb0(indx0, indx1, off0, off1, PDF00, PDF10)
mata:dCdb0A=dCdbA(indx1, off1, PDF10)
mata:dCdb0B=dCdbA(indx1, off1, PDF11)
mata:varE0=varE(dEdb0, varb0)
mata:sE0=sqrt(varE0) 
mata:st_matrix("sE0", sE0)
mata:varC0=varC(varb0, varb1, dCdb0A, dCdb0B)
mata:sC0=sqrt(varC0)
mata:st_matrix("sC0", sC0)
mata:R=E+C
mata:st_matrix("R", R)
mata:ZvalueE=E/sE0
mata:ZvalueC=C/sC0
mata:st_matrix("ZE", ZvalueE)
mata:st_matrix("ZC", ZvalueC)
mata:ZEWdx=E*Wdx:/seWdx
mata:st_matrix("ZEWdx", ZEWdx)
mata:PctE=100*E/(E+C)
mata:PctC=100*C/(E+C)
mata:st_matrix("PE", PctE)
mata:st_matrix("PC", PctC)
mata:PCTcom=100*(E*Wdx:/(E+C))
mata:st_matrix("PCTcom", PCTcom)
mata:CWdb=C*Wdb :* `scale'       // scale
mata:st_matrix("CWdb", CWdb)
mata:ZCWdb=C*Wdb:/seWdb
mata:st_matrix("ZCWdb", ZCWdb)
mata:PCTcoe=100*(C*Wdb:/(E+C))
mata:st_matrix("PCTcoe", PCTcoe)
mata:DCE=E:*Wdx :* `scale'      // scaled
mata:st_matrix("DCE", DCE)
local R=R[1,1]*`scale'
local E=E[1,1]*`scale'
local C=C[1,1]*`scale'
local sE0=sE0[1,1] * `scale'    //
local sC0=sC0[1,1] * `scale'    //
local ZE=ZE[1,1] 
local ZC=ZC[1,1]
mata: PZE=2*normal(-abs(ZvalueE))
mata: PZC=2*normal(-abs(ZvalueC))
mata:st_matrix("PZE", PZE)
mata:st_matrix("PZC", PZC)
local PZE=PZE[1,1]
local PZC=PZC[1,1]
mata:El=E - 1.96*sE0 
mata:Eh=E + 1.96*sE0
mata:Cl=C - 1.96*sC0
mata:Ch=C + 1.96*sC0
mata:st_matrix("El", El)
mata:st_matrix("Eh", Eh)
mata:st_matrix("Cl", Cl)
mata:st_matrix("Ch", Ch)
local El=El[1,1]*`scale'
local Eh=Eh[1,1]*`scale'
local Cl=Cl[1,1]*`scale'
local Ch=Ch[1,1]*`scale'
local PE=PE[1,1]
local PC=PC[1,1]
eret local label0 `lab0'
eret local label1 `lab1'
eret local R `R'
eret local E `E'
eret local C `C'
eret local sE0 `sE0'
eret local sC0 `sC0'
eret local ZE  `ZE'
eret local ZC `ZC'
eret local PZE `PZE'
eret local PZC `PZC'
eret local El `El'
eret local Eh `Eh'
eret local Cl `Cl'
eret local Ch `Ch'
eret local PE `PE'
eret local PC `PC'
eret local depvar `depvar'

local nvarlist "`varlist'"
local nvar : word count `nvarlist'
eret local nvar `nvar'

forval i = 1/`nvar' {
local varname`i' : word `i' of `nvarlist'
eret local varname`i' `varname`i''

local DCE`i'=DCE[1,`i'] 
eret local DCE`i' `DCE`i''

local seWdx`i'=seWdx[1,`i'] * `scale'
eret local seWdx`i' `seWdx`i''

local ZEWdx`i'=ZEWdx[1,`i']
eret local ZEWdx`i' `ZEWdx`i''

local PZE`i'=2*normal(-abs(`ZEWdx`i''))
eret local PZE`i' `PZE`i''

local El`i'=`DCE`i''-1.96*`seWdx`i''
eret local El`i' `El`i''

local Eh`i'=`DCE`i''+1.96*`seWdx`i''
eret local Eh`i' `Eh`i''

local PCTcom`i'=PCTcom[1,`i']
eret local PCTcom`i' `PCTcom`i''

local CWdb`i'=CWdb[1,`i']
eret local CWdb`i' `CWdb`i''

local seWdb`i'=seWdb[1,`i'] * `scale'
eret local seWdb`i' `seWdb`i''

local ZCWdb`i'=ZCWdb[1,`i']
eret local ZCWdb`i' `ZCWdb`i''

local PZC`i'=2*normal(-abs(`ZCWdb`i''))
eret local PZC`i' `PZC`i''

local Cl`i'=`CWdb`i''-1.96*`seWdb`i''
eret local Cl`i' `Cl`i''

local Ch`i'=`CWdb`i''+1.96*`seWdb`i''
eret local Ch`i' `Ch`i''

local PCTcoe`i'=PCTcoe[1,`i']
eret local PCTcoe`i' `PCTcoe`i''
  }
displayresult
eret clear // keep essentials for return
//
// return b V (01/27/22) only
//
mata:DCEu = E:*Wdx              // unscaled
mata:st_matrix("bE", DCEu)
/// post for return
mata:st_matrix("VarE", Var_E_k)  
eret mat bE = bE  
eret mat VE = VarE
mata:CWdbu=C*Wdb                // unscaled        
mata:st_matrix("bC", CWdbu)
/// post for return
mata:st_matrix("VarC", Var_C_k)  
eret local cmd "hazdcmp"     // b's V's and command name
eret mat bC = bC  
eret mat VC = VarC
	}
end

program displayresult
local format	
{
		di
        di %10s as text "Decomposition Results"
        di as text "{hline 31}{hline 71}"
		di as text "Reference group (A): " as res "`e(label0)'"  as text " ---  Comparison group (B): " as res "`e(label1)'""
        di as text "{hline 30}{c TT}{hline 71}"
        di as text %30s "`e(depvar)'" _col(30) as text "{c |}" _col(11) as text %11s "Coef." _col(22) as text %11s "Std. Err." _col(29) as text %8s "z" _col(38) /*
        */ as text %9s "P>|z|" _col(47) as text %24s "[95% Conf. Interval]" _col(71) as text %8s "Pct."
        di as text "{hline 30}{c +}{hline 71}"
        di as text %30s  "E"       _col(30) as text "{c |}"  as res %11.5fc `e(E)' as res %11.5fc `e(sE0)' as res %8.2fc `e(ZE)' /*
        */as res %9.3fc `e(PZE)' as res %12.5fc `e(El)'  as res %12.5fc `e(Eh)'   as res %8.3fc `e(PE)'
        di as text %30s  "C"        _col(30) as text "{c |}" as res %11.5fc `e(C)' as res %11.5fc `e(sC0)' as res %8.2fc `e(ZC)' /*
        */as res %9.3fc `e(PZC)' as res %12.5fc `e(Cl)'  as res %12.5fc `e(Ch)'    as res %8.3fc `e(PC)'
        di as text "{hline 30}{c +}{hline 71}"
        di as text %30s  "Total" _col(30) as res %11.5fc `e(R)'

        di
        di %~100s as text "Due to Difference in Composition (E)"
        di as text "{hline 30}{c TT}{hline 71}"
        di as text %30s "`e(depvar)'" _col(30) as text "{c |}" _col(11) as text %11s "Coef." _col(22) as text %11s "Std. Err." _col(29) as text %8s "z" _col(38) /*
        */ as text %9s "P>|z|" _col(47) as text %24s "[95% Conf. Interval]" _col(71) as text %8s "Pct."
        di as text "{hline 30}{c +}{hline 71}"
forval i = 1/`e(nvar)' {
        di as text %30s  "`e(varname`i')'" _col(30) as text "{c |}" as res %11.5fc `e(DCE`i')'  as res %11.5fc `e(seWdx`i')' /*
        */ as res %8.2fc `e(ZEWdx`i')' as res %9.3fc `e(PZE`i')' as res %12.5fc `e(El`i')' as res %12.5fc `e(Eh`i')'  as res %8.3fc `e(PCTcom`i')'
	}
        di as text "{hline 30}{c +}{hline 71}"
        di
        di %~100s as text "Due to Difference in Coefficients (C)"
        di as text "{hline 30}{c TT}{hline 71}"
        di as text %30s "`e(depvar)'" _col(30) as text "{c |}" _col(11) as text %11s "Coef." _col(22) as text %11s "Std. Err." _col(29) as text %8s "z" _col(38) /*
        */ as text %9s "P>|z|" _col(47) as text %24s "[95% Conf. Interval]" _col(71) as text %8s "Pct."
        di as text "{hline 30}{c +}{hline 71}"
forval i = 1/`e(nvar)' {
        di as text %30s  "`e(varname`i')'" _col(30) as text "{c |}" as res %11.5fc  `e(CWdb`i')'  as res %11.5fc `e(seWdb`i')' /*
        */ as res %8.2fc `e(ZCWdb`i')' as res %9.3fc `e(PZC`i')' as res %12.5fc `e(Cl`i')' as res %12.5fc `e(Ch`i')'  as res %8.3fc `e(PCTcoe`i')'
   }
        di as text "{hline 30}{c BT}{hline 71}"
}

  
end  // hazdcmp

******************************
*                            *
*       mata functions       *
*                            *
******************************

///////  Yun x-weights Wdx.F
mata:
function Wdx_F(real matrix xMean0, real matrix xMean1, real matrix b0)
{
  Wdx=J(1, cols(b0), .)
    A=(xMean0-xMean1)*b0'
  for (i=1; i<=cols(b0); i++){
      Wdx[i]=(xMean0[i]-xMean1[i])*b0[i]':/A
  }
return(Wdx)
}
end

///////// Yun b-weights Wdb.F
mata:
function Wdb_F(real matrix b0, real matrix b1, real matrix xMean1)
{
  Wdb=J(1, cols(xMean1), .)
    A=xMean1*(b0'-b1')
  for (i=1; i<=cols(b0); i++){
      Wdb[i]=(xMean1[i]*(b0[i]'-b1[i]')):/A
  }
return(Wdb)
}
end

/////  dwA_F
mata:
function dwA_F(real matrix b0, real matrix b1, real matrix xMean1)
{
  dwA=J(cols(xMean1), cols(xMean1), .)
   A=xMean1*(b0'-b1')
     for (i=1; i<=cols(xMean1); i++){
     for (j=1; j<=cols(xMean1); j++){
     if(i==j){
       B = 1
       }
     else{
       B = 0
      }
dwA[i,j]= B:*xMean1[i]:/A - (xMean1[i]:*xMean1[j]*(b0[i]'-b1[i]')):/A:^2
  }
 }
return (dwA)
}
end

///// dwB_F
mata:
function dwB_F(real matrix b0, real matrix b1, real matrix xMean1)
{
   dwB=J(cols(xMean1), cols(xMean1), .)
     A=xMean1*(b0'-b1')
      for (i=1; i<=cols(xMean1); i++){
        for (j=1; j<=cols(xMean1); j++){
   if(i==j){
         B = 1
      }
    else{
         B = 0
   }
dwB[i,j]= (xMean1[i]:*xMean1[j]*(b0[i]'-b1[i]')):/A:^2  - B:*xMean1[i]:/A
  }
}
return (dwB)
}
end

///// dW_F
mata:
function dW_F(real matrix b0, real matrix xMean0, real matrix xMean1)
{
  dW=J(cols(xMean1), cols(xMean1), .)
   A=(xMean0-xMean1)*b0'
     for (i=1; i<=cols(xMean1); i++){
      for (j=1; j<=cols(xMean1); j++){
         if(i==j){
        B = 1
        }
         else{
        B = 0
  }
dW[i,j]= B:*(xMean0[i]-xMean1[i]):/A - (b0[i]'*(xMean0[i]-xMean1[i]):*(xMean0[j]-xMean1[j])):/A:^2
 }
}
return (dW)
}
end

///// dCdb2
mata:
function dCdb2(real matrix x1, real matrix Wdb, real matrix wbB, real matrix off, real matrix PDF, real scalar C)
{
  dCdb2=J(cols(x1), cols(x1), .)
    for (i=1; i<=cols(x1); i++){
      for (j=1; j<=cols(x1); j++){
        dCdb2[i,j] = wbB[i,j]:*C - Wdb[i]:*sum(PDF:*x1[,j]):/sum(exp(off))
    }
  }
return(dCdb2)
}
end

///// dCdb1
mata:
function dCdb1(real matrix x1, real matrix Wdb, real matrix wbA, real matrix off, real matrix PDF, real scalar C)
{
  dCdb1=J(cols(x1), cols(x1), .)
     for (i=1; i<=cols(x1); i++){
       for (j=1; j<=cols(x1); j++){
         dCdb1[i,j]=Wdb[i]:*sum(x1[,j]:*PDF):/sum(exp(off)) :+ wbA[i,j]:*C
    }
  }
return(dCdb1)
}
end

///// dEdb
mata:
function dEdb(real matrix x0, real matrix x1, real matrix Wdx, real matrix dWx, real scalar E,
real matrix off0, real matrix off1, real matrix PDF0, real matrix PDF1)
{
    dEdb=J(cols(x0), cols(x0), .)
      for (i=1; i<=cols(x0); i++){
       for (j=1; j<=cols(x0); j++){
         dEdb[i,j]= Wdx[i]:*(sum(PDF0:*x0[,j]):/sum(exp(off0)) :-sum(PDF1:*x1[,j]):/sum(exp(off1))):+dWx[i,j]:*E
   }
 } 
return(dEdb)
}
end

///// dCdbA
mata:
function dCdbA(x, off, PDF) {
    dCdba=J(1, cols(x), .)
      for (i=1; i<=cols(x); i++){
        dCdba[i] = sum(PDF:*x[,i]):/sum(exp(off))
  }
return(dCdba)
}
end

//// calculate variances (E)

mata:
function varcomp(real matrix dEdb, real matrix varb0)
{
 Var_E_k= J(cols(dEdb),cols(dEdb),.)
Var_E_k=dEdb*varb0*dEdb'
return(Var_E_k)
}
end

//// calculate variances (C)

mata:
function varcoef(dCdb0, dCdb1, varb0, varb1)
{
 Var_C_k=J(cols(dCdb1), cols(dCdb1), .)
 Var_C_k = dCdb0*varb0*dCdb0' + dCdb1*varb1*dCdb1'
return(Var_C_k)
}
end

mata:
function varE(real matrix dEdb, real matrix varb0)
{
 varE0=J(1, cols(dEdb), .)
 varE0=dEdb*varb0*dEdb'
return(varE0)
}
end

mata:
function varC(varb0, varb1, dCdb0, dCdb1)
{
 varC0=0
 varC0=dCdb0*varb0*dCdb0' + dCdb1*varb1*dCdb1'
return(varC0)
}
end

mata:
function dEdb0(x0, x1, off0, off1, PDF0, PDF1)
{
 dEdb0=J(1,cols(x0), .)
   for (i=1; i<=cols(x0); i++){
     dEdb0[i] = sum(PDF0:*x0[,i])/sum(exp(off0)) - sum(PDF1:*x1[,i]):/sum(exp(off1))
 }
return(dEdb0)
}
end

**********************************************
*                                            *
*           functions for Poisson            *
*                                            *
**********************************************

mata:
function F_pois(real matrix x, real matrix b, real matrix off)
{
 xb=x*b'
  F=exp(xb :+ off)
return(F)
}
end

mata:
function f_pois(real matrix x, real matrix b, real matrix off)
{
 xb=x*b'
 f=exp(xb :+ off)
return(f)
}
end

**********************************************
*                                            *
*           functions for logit              *
*                                            *
**********************************************

mata:
function F_lgt(real matrix x, real matrix b, real matrix off)
{
xb=x*b'
F=exp(xb :+ off) :/(1:+exp(xb :+ off)) 
return(F)
}
end

mata:
function f_lgt(real matrix x, real matrix b, real matrix off)
{
xb=x*b'
f=exp(xb :+ off):/(1:+exp(xb :+ off)):^2
return(f)
}
end

