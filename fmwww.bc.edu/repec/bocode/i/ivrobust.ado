/*
Carolin Pflueger and Su Wang 15/08/2013 
Stata routine implementing robust weak instrument pre-test of

Jose Montiel Olea and Carolin Pflueger
“A Robust Test for Weak Instruments?
Journal of Business & Economic Statistics, 2013, 31(3):358-369

Lines 28 through 78 and line 587-617 are from 
Robbins, Jacob, 2012. tsls: Fast and Small 2SLS with FE, IV and Clustered SE. 
http://www.nber.org/stata/tsls.pdf
*/ 
program ivrobust,rclass byable(recall)
version 10
syntax [anything(name=0)] [if] [in] [, robust CLuster(varlist) BW(string) level(string) eps(string)]

marksample touse
preserve
* hold and restore ereturn output in stata before running ivrobust command
tempvar base
_estimates hold `base', restore nullok

**********************************
/*Parsing the Syntax */
**********************************
local n 0
		gettoken lhs 0 : 0, parse(" ,[") match(paren)
		IsStop `lhs'
		if `s(stop)' { 
			error 198 
		}
		while `s(stop)'==0 { 
			if "`paren'"=="(" {
				local n = `n' + 1
				if `n'>1 { 
capture noi error 198
display in red `"syntax is "(all instrumented variables = instrument variables)""'
exit 198
				}
				gettoken p lhs : lhs, parse(" =")
				while "`p'"!="=" {
					if "`p'"=="" {
capture noi error 198 
display in red `"syntax is "(all instrumented variables = instrument variables)""'
display in red `"the equal sign "=" is required"'
exit 198 
					}
					local endo `endo' `p'
					gettoken p lhs : lhs, parse(" =")
				}
* To enable Cragg HOLS estimator, allow for empty endo list
				local temp_ct  : word count `endo'
				if `temp_ct' > 0 {
					tsunab endo : `endo'
* Only allow one endogenous variable				
                if `temp_ct'> 1 {
capture noi error 198 
display in red `"only one endogenous variable allowed"'
exit 198 			
				}
				}
* To enable OLS estimator with (=) syntax, allow for empty exexog list
				local temp_ct  : word count `lhs'
				if `temp_ct' > 0 {
					tsunab exexog : `lhs'
				}
			}
			else {
				local depvar `depvar' `lhs'
			}
			gettoken lhs 0 : 0, parse(" ,[") match(paren)
			
			
			IsStop `lhs'
		}
	
 gettoken depvar Zincl: depvar ,parse(" ") 
 gettoken exex1 exexrest: exexog ,parse(" ") 
 
 
*******
local instru_n: word count `exexog'
qui ds
local varnum=wordcount("`r(varlist)'")
local instru_num2=0
local instru_num_star=0
foreach var in `exexog'{
if substr("`var'",length("`var'"),1)=="*"{
local instru_num_star=`instru_num_star'+1
forvalues i=1/`varnum' {
local var1 word("`r(varlist)'",`i')
if  strmatch(`var1',"`var'")==1{ 
local instru_num2=`instru_num2'+1
}
}
}
}
local instru_num=`instru_n'+`instru_num2'-`instru_num_star'

local Zincl_num: word count `Zincl'
qui ds
local varnum=wordcount("`r(varlist)'")
local Zincl_num2=0
local Zincl_num_star=0
foreach var in `Zincl'{
if substr("`var'",length("`var'"),1)=="*"{
local Zincl_num_star=`Zincl_num_star'+1
forvalues i=1/`varnum' {
local var1 word("`r(varlist)'",`i')
if  strmatch(`var1',"`var'")==1{ 
local Zincl_num2=`Zincl_num2'+1
}
}
}
}

tempname L
mat `L'=`Zincl_num'+`Zincl_num2'-`Zincl_num_star'


if "`robust'" != "" {
			local vce "robust"
		}
if "`cluster'" != "" {
			
				local vce "cluster `cluster'"
		}
if "`bw'" != "" {
				local vce "hac nw `bw'"
		}
			
if "`vce'"==""{
            local vce "unadjusted"
}


if "`level'"==""    local level "0.05"
if "`eps'"==""      local eps "0.0001"
local b=`level'*100

**********************************
/*Preparing Data for regression*/
**********************************
 **check if the time series observations are continuous observations**
fvrevar `exexog', tsonly
local exexogtemp  "`r(varlist)'"
fvrevar `endo', tsonly
local endotemp   "`r(varlist)'"
fvrevar `depvar', tsonly
local depvartemp  "`r(varlist)'"
fvrevar `Zincl', tsonly
local Zincltemp  "`r(varlist)'"



**delete missing variables **

keep if `touse'

foreach var in `exexogtemp' `depvartemp' `endotemp' `Zincltemp'{
if substr("`var'",length("`var'"),1)!="*"{
qui drop if `var'==.

}
}


**demean endotemp and depvartemp variables**
foreach var in `depvartemp' `endotemp'{
qui reg `var' `Zincltemp'
tempvar rsd
predict `rsd', r
drop `var'
rename `rsd' `var'
}

tempname Z  
foreach var in `exexogtemp' {
tempvar exrsd 
qui reg `var' `Zincltemp'
predict `exrsd', r
drop `var'
rename `exrsd' `var'
}



tempname Zs 

tempname S

orthog `exexogtemp' , gen(`Zs'*)
/*
mkmat `Zs'*, matrix (Zz)
matlist Zz
*/

matrix `S'=r(N)

tempname K

matrix `K'=`instru_num'


*************************************
/*Regressions*/
*************************************

*GMM and OLS are the same for the first stage up to a scaling factor
*Need to divide by rat to make sure we use the same degrees of freedom adjustment as Yogo
tempvar rat W2 RF Whom F omega_22 F_eff W Omega W_1 W_12 W_2 num 

mat `rat'=`S'*invsym(`S'-`K'-`L'-1)


qui gmm (eq1: `endotemp'-{xg1:`Zs'*}),onestep instruments(1:`Zs'*, noconstant) winitial(identity) vce(`vce') 

mat `W2'=e(V)*`S'*`rat'


mat `RF'=e(b)*invsym(`W2')*e(b)'*`S'*invsym(`K')

qui gmm (eq1: `endotemp'-{xg1:`Zs'*}),onestep instruments(1:`Zs'*, noconstant) winitial(identity) vce(unadjusted) 

mat `Whom'=e(V)*`S'*`rat'


mat `F'=e(b)*invsym(`Whom')*e(b)'*`S'*invsym(`K')
mat `omega_22'=trace(`Whom')*inv(`K')
*Effective F

mat `F_eff'=`F'*(`K'*`omega_22')/trace(`W2')


*Get full W matrix from GMM

qui gmm (eq1: `depvartemp'-{xg2:`Zs'*})(eq2: `endotemp'-{xg1:`Zs'*}),onestep instruments(`Zs'*, noconstant) winitial(identity) vce(`vce') 

mat `W'=e(V)*`S'*`rat'

qui gmm (eq1: `depvartemp'-{xg2:`Zs'*})(eq2: `endotemp'-{xg1:`Zs'*}),onestep instruments(`Zs'*, noconstant) winitial(identity) vce(unadjusted) 

mat `Omega'=e(V)*`S'*`rat'

*put matrix in stata to mata

mata `num'=st_matrix("`S'")
mata `W'=st_matrix("`W'")
mata `Omega'=st_matrix("`Omega'")
mata `K'=rows(`W')/2
mata `W_1'=`W'[1::`K',1..`K']
mata `W_12'=`W'[1::`K',`K'+1..2*`K']
mata `W_2'=`W'[1+`K'::2*`K',1+`K'..2*`K']
mata `W2'=eigenvalues(`W_2')
mata `W2'=Re(`W2')
mata `Omega'=(`Omega'[1,1],`Omega'[`K'+1,1] \ `Omega'[`K'+1,1],`Omega'[`K'+1,`K'+1])
mata `F_eff'=st_matrix("`F_eff'")
mata st_local("F_eff", strofreal(`F_eff'))
mata st_local("num", strofreal(`num'))


tempvar BTSLS BLIML BTSLS_start BLIML_start
qui mata `BTSLS_start'=BTSLS_start(`W_1',`W_12',`W_2',`eps')

mata st_local("BTSLS_error", strofreal(`BTSLS_start'*(1,0)'))
mata st_local("BTSLS_start", strofreal(`BTSLS_start'*(0,1)'))

qui mata `BTSLS'=BTSLS(`W_1',`W_12',`W_2',`BTSLS_start')
mata st_local("BTSLS", strofreal(`BTSLS'))


qui mata `BLIML_start'=BLIML_start(`W_1',`W_12',`W_2',`Omega',`eps')

mata st_local("BLIML_error", strofreal(`BLIML_start'*(1,0)'))


mata st_local("BLIML_start", strofreal(`BLIML_start'*(0,1)'))

qui mata `BLIML'=BLIML(`W_1',`W_2',`W_12',`Omega',`BLIML_start')
mata st_local("BLIML", strofreal(`BLIML'))


***************************************
/*Critical value*/
***************************************
quietly capture findfile CVN.dta /*if ",all" is added, there will be no problem*/
local filelist `"`r(fn)'"'
use `"`filelist'"',clear
mata  CVN=st_data(.,.)

tempvar CVNrt 
*display "Simplified TSLS critical values:"

mata  `CVNrt'=cpatnaikgen(`W_2', `level' , 20 , CVN)
mata st_local("c_simple_5", strofreal(`CVNrt'*(1,0,0)'))
mata st_local("EK_simp_5",  strofreal(`CVNrt'*(0,1,0)'))
mata st_local("exerr_simp_5",strofreal(`CVNrt'*(0,0,1)'))


mata  `CVNrt'=cpatnaikgen(`W_2', `level' , 10 , CVN)
mata st_local("c_simple_10", strofreal(`CVNrt'*(1,0,0)'))
mata st_local("EK_simp_10",  strofreal(`CVNrt'*(0,1,0)'))
mata st_local("exerr_simp_10",strofreal(`CVNrt'*(0,0,1)'))


mata  `CVNrt'=cpatnaikgen(`W_2', `level' , 5 , CVN)
mata st_local("c_simple_20", strofreal(`CVNrt'*(1,0,0)'))
mata st_local("EK_simp_20",  strofreal(`CVNrt'*(0,1,0)'))
mata st_local("exerr_simp_20",strofreal(`CVNrt'*(0,0,1)'))


mata  `CVNrt'=cpatnaikgen(`W_2', `level' , 3.33 , CVN)
mata st_local("c_simple_30", strofreal(`CVNrt'*(1,0,0)'))
mata st_local("EK_simp_30",  strofreal(`CVNrt'*(0,1,0)'))
mata st_local("exerr_simp_30",strofreal(`CVNrt'*(0,0,1)'))


*GENERALIZED TSLS

local c_TSLS_5 ""
local c_TSLS_10 ""
local c_TSLS_20 ""
local c_TSLS_30 ""

if `BTSLS_error'==0 {

tempvar X_TSLS CVNrt_T 
mata `X_TSLS'=20*`BTSLS' /*X_TSLS is the input for the critical value*/
mata st_local("X_TSLS_5", strofreal(`X_TSLS'))
mata  `CVNrt_T'=cpatnaikgen(`W_2', `level' , `X_TSLS' , CVN)
mata st_local("c_TSLS_5", strofreal(`CVNrt_T'*(1,0,0)'))
mata st_local("EK_TSLS_5", strofreal(`CVNrt_T'*(0,1,0)'))
mata st_local("exerr_TSLS_5", strofreal(`CVNrt_T'*(0,0,1)')) 


mata `X_TSLS'=10*`BTSLS' /*X_TSLS is the input for the critical value*/
mata st_local("X_TSLS_10", strofreal(`X_TSLS'))
mata  `CVNrt_T'=cpatnaikgen(`W_2', `level' , `X_TSLS' , CVN)
mata st_local("c_TSLS_10", strofreal(`CVNrt_T'*(1,0,0)'))
mata st_local("EK_TSLS_10", strofreal(`CVNrt_T'*(0,1,0)'))
mata st_local("exerr_TSLS_10", strofreal(`CVNrt_T'*(0,0,1)')) 


mata `X_TSLS'=5*`BTSLS' /*X_TSLS is the input for the critical value*/
mata st_local("X_TSLS_20", strofreal(`X_TSLS'))
mata  `CVNrt_T'=cpatnaikgen(`W_2', `level' , `X_TSLS' , CVN)
mata st_local("c_TSLS_20", strofreal(`CVNrt_T'*(1,0,0)'))
mata st_local("EK_TSLS_20", strofreal(`CVNrt_T'*(0,1,0)'))
mata st_local("exerr_TSLS_20", strofreal(`CVNrt_T'*(0,0,1)')) 


mata `X_TSLS'=3.33*`BTSLS' /*X_TSLS is the input for the critical value*/
mata st_local("X_TSLS_30", strofreal(`X_TSLS'))
mata  `CVNrt_T'=cpatnaikgen(`W_2', `level' , `X_TSLS' , CVN)
mata st_local("c_TSLS_30", strofreal(`CVNrt_T'*(1,0,0)'))
mata st_local("EK_TSLS_30", strofreal(`CVNrt_T'*(0,1,0)'))
mata st_local("exerr_TSLS_30", strofreal(`CVNrt_T'*(0,0,1)')) 
}

*GENERALLIZED LIML

local c_LIML_5 ""
local c_LIML_10 ""
local c_LIML_20 ""
local c_LIML_30 ""

if `BLIML_error'==0{
tempvar X_LIML CVNrt_L
mata `X_LIML'=20*`BLIML' /*X_LIML is the input for the critical value*/
mata st_local("X_LIML_5", strofreal(`X_LIML'))
mata  `CVNrt_L'=cpatnaikgen(`W_2', `level' , `X_LIML' , CVN)
mata st_local("c_LIML_5", strofreal(`CVNrt_L'*(1,0,0)'))
mata st_local("EK_LIML_5", strofreal(`CVNrt_L'*(0,1,0)'))
mata st_local("exerr_LIML_5", strofreal(`CVNrt_L'*(0,0,1)')) 

tempvar X_LIML CVNrt_L
mata `X_LIML'=20*`BLIML' /*X_LIML is the input for the critical value*/
mata st_local("X_LIML_5", strofreal(`X_LIML'))
mata  `CVNrt_L'=cpatnaikgen(`W_2', `level' , `X_LIML' , CVN)
mata st_local("c_LIML_5", strofreal(`CVNrt_L'*(1,0,0)'))
mata st_local("EK_LIML_5", strofreal(`CVNrt_L'*(0,1,0)'))
mata st_local("exerr_LIML_5", strofreal(`CVNrt_L'*(0,0,1)')) 


mata `X_LIML'=10*`BLIML' /*X_LIML is the input for the critical value*/
mata st_local("X_LIML_10", strofreal(`X_LIML'))
mata  `CVNrt_L'=cpatnaikgen(`W_2', `level' , `X_LIML' , CVN)
mata st_local("c_LIML_10", strofreal(`CVNrt_L'*(1,0,0)'))
mata st_local("EK_LIML_10", strofreal(`CVNrt_L'*(0,1,0)'))
mata st_local("exerr_LIML_10", strofreal(`CVNrt_L'*(0,0,1)')) 


mata `X_LIML'=5*`BLIML' /*X_LIML is the input for the critical value*/
mata st_local("X_LIML_20", strofreal(`X_LIML'))
mata  `CVNrt_L'=cpatnaikgen(`W_2', `level' , `X_LIML' , CVN)
mata st_local("c_LIML_20", strofreal(`CVNrt_L'*(1,0,0)'))
mata st_local("EK_LIML_20", strofreal(`CVNrt_L'*(0,1,0)'))
mata st_local("exerr_LIML_20", strofreal(`CVNrt_L'*(0,0,1)')) 


mata `X_LIML'=3.33*`BLIML' /*X_LIML is the input for the critical value*/
mata st_local("X_LIML_30", strofreal(`X_LIML'))
mata  `CVNrt_L'=cpatnaikgen(`W_2', `level' , `X_LIML' , CVN)
mata st_local("c_LIML_30", strofreal(`CVNrt_L'*(1,0,0)'))
mata st_local("EK_LIML_30", strofreal(`CVNrt_L'*(0,1,0)'))
mata st_local("exerr_LIML_30", strofreal(`CVNrt_L'*(0,0,1)')) 
}
/*Output table*/

display ""
display "Montiel-Pflueger robust weak instrument test"

display "{txt}{hline 62}"
display "Effective F statistic:	" %9.3fc `F_eff'
display "Confidence level alpha: 	`b'%"
display "{txt}{hline 62}"

display ""

display "{txt}{hline 62}"
display "Critical Values	" "	TSLS" "	     " "LIML"
display "{txt}{hline 62}"
display "% of Worst Case Bias" 	
display "tau=5%			" %9.3fc `c_TSLS_5' "	" %9.3fc `c_LIML_5'
display "tau=10%		" %9.3fc `c_TSLS_10' "	" %9.3fc `c_LIML_10'
display "tau=20%		" %9.3fc `c_TSLS_20' "	" %9.3fc `c_LIML_20'
display "tau=30%		" %9.3fc `c_TSLS_30' "	" %9.3fc `c_LIML_30'
display "{txt}{hline 62}"

if `BTSLS_error'==0{
/*Error message*/ /*`exerr_simp_5'==1 |`exerr_simp_10'==1 |`exerr_simp_20'==1 |`exerr_simp_30'==1 | */
if `exerr_TSLS_5'==1 |`exerr_TSLS_10'==1 |`exerr_TSLS_20'==1 |`exerr_TSLS_30'==1 { ///
 
if `exerr_TSLS_5'==1 {
local eT_5 " Generalized TSLS tau=5% "
}

else{
local eT_5 ""
}


if `exerr_TSLS_10'==1 {
local eT_10 " Generalized TSLS tau=10% "
}
else{
local eT_10 ""
}


if `exerr_TSLS_20'==1 {
local eT_20= " Generalized TSLS tau=20% "
}
else{
local eT_20=""
}

if `exerr_TSLS_30'==1 {
local eT_30 " Generalized TSLS tau=30% "
}
else{
local eT_30 ""
}

}
}


if `BLIML_error'==0{
if `exerr_LIML_5'==1 |`exerr_LIML_10'==1 |`exerr_LIML_20'==1 |`exerr_LIML_30'==1{
if `exerr_LIML_5'==1 {
local eL_5  " Generalized LIML tau=5% "
}
else{
local eL_5""
}

if `exerr_LIML_10'==1 {
local eL_10 " Generalized LIML tau=10% "
}
else{
local eL_10 ""
}

if `exerr_LIML_20'==1 {
local eL_20 " Generalized LIML tau=20% "
}
else{
local eL_20 ""
}

if `exerr_LIML_30'==1 {
local eL_30 " Generalized LIML tau=30% "
}
else{
local eL_30 ""
}

display in red "Critical values are extrapolated and may be unreliable for the following cases: "   "`eT_5'" "`eT_10'" "`eT_20'" "`eT_30'" ///
  "`eL_5'" "`eL_10'" "`eL_20'" "`eL_30'""."
 /* "`es_5'" "`es_10'" "`es_20'" "`es_30'" */
}

}

/*error message of eps*/
if `BTSLS_error'==1{
di in r "TSLS bound did not converge. Current value of eps=`eps'. Consider reducing eps."
}

if `BLIML_error'==1{
di in r "LIML bound did not converge. Current value of eps=`eps'. Consider reducing eps."
}


/*Returned values*/
/*c_simple*/
return local K_eff_simp_30= `EK_simp_30'
return local K_eff_simp_20= `EK_simp_20'
return local K_eff_simp_10= `EK_simp_10'
return local K_eff_simp_5=  `EK_simp_5'

return local x_simp_30= "3.33"
return local x_simp_20= "5"
return local x_simp_10= "10"
return local x_simp_5=  "20"



/*c_LIML*/
if `BLIML_error'==0{
return local K_eff_LIML_30= `EK_LIML_30'
return local K_eff_LIML_20= `EK_LIML_20'
return local K_eff_LIML_10= `EK_LIML_10'
return local K_eff_LIML_5=  `EK_LIML_5'

return local x_LIML_30= `X_LIML_30'
return local x_LIML_20= `X_LIML_20'
return local x_LIML_10= `X_LIML_10'
return local x_LIML_5=  `X_LIML_5'
}


/*c_TSLS*/
if `BTSLS_error'==0{
return local K_eff_TSLS_30= `EK_TSLS_30'
return local K_eff_TSLS_20= `EK_TSLS_20'
return local K_eff_TSLS_10= `EK_TSLS_10'
return local K_eff_TSLS_5=  `EK_TSLS_5'

return local x_TSLS_30= `X_TSLS_30'
return local x_TSLS_20= `X_TSLS_20'
return local x_TSLS_10= `X_TSLS_10'
return local x_TSLS_5=  `X_TSLS_5'
}

return local c_simp_30= `c_simple_30'
return local c_simp_20= `c_simple_20'
return local c_simp_10= `c_simple_10'
return local c_simp_5=  `c_simple_5'
if `BLIML_error'==0{
return local c_LIML_30= `c_LIML_30'
return local c_LIML_20= `c_LIML_20'
return local c_LIML_10= `c_LIML_10'
return local c_LIML_5=  `c_LIML_5'
}
if `BTSLS_error'==0{
return local c_TSLS_30= `c_TSLS_30'
return local c_TSLS_20= `c_TSLS_20'
return local c_TSLS_10= `c_TSLS_10'
return local c_TSLS_5=  `c_TSLS_5'
}

return local F_eff  `F_eff' /*Effective F statisti*/
return local eps    `eps'      /*eps*/
return local level  `level' /*significance level*/
return local K      `instru_num' /*number of instruments*/
return local N      `num'         /*number of observations*/




restore
end

***************************************************************************
program define IsStop, sclass
				/* sic, must do tests one-at-a-time, 
				 * 0, may be very large */
	version 8.2
	if `"`0'"' == "[" {		
		sret local stop 1
		exit
	}
	if `"`0'"' == "," {
		sret local stop 1
		exit
	}
	if `"`0'"' == "if" {
		sret local stop 1
		exit
	}
* per official ivreg 5.1.3
	if substr(`"`0'"',1,3) == "if(" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "in" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "" {
		sret local stop 1
		exit
	}
	else sret local stop 0
end


/*Mata programs for the critical values*/


mata
version 10
real matrix cpatnaikgen(W_2, a, x ,CV){
W2=eigenvalues(W_2)
W2=Re(W2)
W2=W2/sum(W2)
W2=sort(W2',1)'
variance=2*sum(W2:*W2)+4*x*max(W2)
EK=2*(1+2*x)/variance
EK1=EK
if (x<0 | x>20 | EK<0.1 | EK>15){
exerr=1
}
else{
exerr=0
}
if (x<0){
x=0
}
if (x>20){
x=20
}
if (EK>15){
EK=15
}
if (EK<0.1){
EK=0.1
}
if(a==0.01)
{
p=1
} 
else if (a==0.05)
{
p=2
}
else if (a==0.10)
{
p=3
}
a=EK*10-1
b=EK*10-0.5
c=EK*10
for (i=1; i<=150; i=i+1){
if (i>a & i<b){
k=i+1
}
if (i==b){
k=i
}
if (i>b & i<c){
k=i
}
if (i==c){
k=i
}
}
j=150*p+k-150

a=x*100-1
b=x*100-0.5
c=x*100
for (i=1; i<=2001; i=i+1){
if (i>a & i<b){
q=i+2
}
if (i==b){
q=i+1
}

if (i>b & i<c){
q=i+1
}
if (i==c){
q=i+1
}
}

/*add situation when the subscript is missing*/
cvalue=CV[q,j]
RTN=cvalue, EK1, exerr
return (RTN)
}


end


/*Optimization for TSLS*/

mata
version 10
real matrix Bmaxfunction (real scalar beta, real matrix W_1, real matrix W_12, real matrix W_2){
S_2=W_2
S_12=W_12-beta*W_2
S_1=W_1-2*beta*W_12+beta^2*W_2
L=eigenvalues(0.5*S_12+0.5*S_12')
L=Re(L)
mineig=rowmin(L)
maxeig=rowmax(L)
B=abs(trace(S_12)/sqrt(trace(S_2)*trace(S_1))*(1-2*mineig/trace(S_12)))
C=abs(trace(S_12)/sqrt(trace(S_2)*trace(S_1))*(1-2*maxeig/trace(S_12)))
B=max(B\C)
X=B,beta
return (X)
}
end


mata
version 10
real matrix BTSLS_start (real matrix W_1, real matrix W_12, real matrix W_2,eps){
L=eigenvalues(W_2)
L=Re(L)
eigmin=rowmin(L)
LimitB=1-2*eigmin/trace(W_2)
betastart=0
points=10000
val=max(abs(abs(Bmaxfunction(betastart, W_1, W_12, W_2)*(1,0)'/LimitB)-1)\ abs(abs(Bmaxfunction(-betastart, W_1, W_12, W_2)*(1,0)'/LimitB)-1))
if (val<eps | val==eps){
epserror=1
s=0
}
else {
while (val>eps){
    val=max(abs(abs(Bmaxfunction(betastart, W_1, W_12, W_2)*(1,0)'/LimitB)-1)\ abs(abs(Bmaxfunction(-betastart, W_1, W_12, W_2)*(1,0)'/LimitB)-1))
    betastart=betastart+1
}
	epserror=0

t=-betastart 
s=t
BplotTSLS=Bmaxfunction(t, W_1, W_12, W_2)*(1,0)'
	while (t<=betastart){
	t=t+2*betastart/points
	BTSLS=Bmaxfunction(t, W_1, W_12, W_2)*(1,0)'
	BplotTSLS=max(BTSLS\BplotTSLS)
	if (BTSLS<BplotTSLS){
	s=s
	}
	else{
	s=t
	}
	}
	}
	x=epserror,s
return(x)

}
/*mata drop myfun()*/
/*Carolin: I added extra arguments to this function
*/
mata
version 10
void myfun (todo, beta,W_1,W_2,W_12,BTSLS_start,y, g, h)
{
S_2=W_2
S_12=W_12-beta*W_2
S_1=W_1-2*beta*W_12+beta^2*W_2
L=eigenvalues(0.5*S_12+0.5*S_12')
L=Re(L)
mineig=rowmin(L)
maxeig=rowmax(L)
B=abs(trace(S_12)/sqrt(trace(S_2)*trace(S_1))*(1-2*mineig/trace(S_12)))
C=abs(trace(S_12)/sqrt(trace(S_2)*trace(S_1))*(1-2*maxeig/trace(S_12)))
y=max(B\C)
}

end

mata
version 10
real matrix BTSLS (real matrix W_1, real matrix W_12, real matrix W_2, BTSLS_start){
S=optimize_init()
optimize_init_evaluator(S, &myfun ())
optimize_init_params(S,BTSLS_start)
/*This line tells the optimizer to hold W_1, W_2, and W_12 constant */
optimize_init_argument(S, 1, W_1)
optimize_init_argument(S, 2, W_2)
optimize_init_argument(S, 3, W_12)
optimize_init_argument(S, 4, BTSLS_start)
/*I added two statements specify the nelder-mead method for the optimization*/
optimize_init_technique(S, "nm")
optimize_init_nmsimplexdeltas(S,0.5)
beta_TSLS=optimize(S)
BTSLS=optimize_result_value(S)
return (BTSLS)
}
end

/*Optimization for LIML*/
mata
version 10
real matrix BmaxLIML (real scalar beta, real matrix W_1, real matrix W_12, real matrix W_2, real matrix Omega){
S_2=W_2
S_12=W_12-beta*W_2
S_1=W_1-2*beta*W_12+beta^2*W_2
om_1=Omega[1,1]
om_12=Omega[1,2]
om_2=Omega[2,2]
sig_12=om_12-beta*om_2
sig_1=om_1-2*beta*om_12+beta^2*om_2

Matrix=2*S_12-sig_12/sig_1*S_1
Matrix=0.5*(Matrix+Matrix')

L=eigenvalues(Matrix)
L=Re(L)
mineig=rowmin(L)
maxeig=rowmax(L)

B=1/sqrt(trace(S_2)*trace(S_1))*(trace(S_12)-sig_12/sig_1*trace(S_1)-mineig)
B=abs(B)
B=max(B\abs(1/sqrt(trace(S_2)*trace(S_1))*(trace(S_12)-sig_12/sig_1*trace(S_1)-maxeig)))

X=B,beta
return (X)
}
end

mata
version 10
real matrix BLIML_start (real matrix W_1, real matrix W_12, real matrix W_2, real matrix Omega, eps){
L=eigenvalues(W_2)
L=Re(L)
eigmin=rowmin(L)
eigmax=rowmax(L)
LimitB=eigmax/trace(W_2)
betastart=0
points=10000
val=max(abs(BmaxLIML(betastart, W_1, W_12, W_2, Omega)*(1,0)'/LimitB-1)\ abs(BmaxLIML(-betastart, W_1, W_12, W_2, Omega)*(1,0)'/LimitB-1))
if (val<eps |val==eps){
epserror=1
s=0
}
else{
while (val>eps){
    val=max(abs(BmaxLIML(betastart, W_1, W_12, W_2, Omega)*(1,0)'/LimitB-1)\ abs(BmaxLIML(-betastart, W_1, W_12, W_2, Omega)*(1,0)'/LimitB-1))
    betastart=betastart+1
}
epserror=0

t=-betastart 
s=t
BplotLIML=BmaxLIML(t, W_1, W_12, W_2, Omega)*(1,0)'
while (t<=betastart){
t=t+2*betastart/points
BLIML=BmaxLIML(t, W_1, W_12, W_2,Omega)*(1,0)'
BplotLIML=max(BLIML\BplotLIML)
if (BLIML<BplotLIML){
	s=s
	}
	else{
	s=t
	}
	}
	}
x=epserror, s
return(x)

}



void myfun2(todo,beta, W_1, W_2, W_12, Omega,BLIML_start, y, g, h)

{

S_2=W_2
S_12=W_12-beta*W_2
S_1=W_1-2*beta*W_12+beta^2*W_2
om_1=Omega[1,1]
om_12=Omega[1,2]
om_2=Omega[2,2]
sig_12=om_12-beta*om_2
sig_1=om_1-2*beta*om_12+beta^2*om_2

Matrix=2*S_12-sig_12/sig_1*S_1
Matrix=0.5*(Matrix+Matrix')

L=eigenvalues(Matrix)
L=Re(L)
mineig=rowmin(L)
maxeig=rowmax(L)

B=abs(1/sqrt(trace(S_2)*trace(S_1))*(trace(S_12)-sig_12/sig_1*trace(S_1)-mineig))

y=max(B\abs(1/sqrt(trace(S_2)*trace(S_1))*(trace(S_12)-sig_12/sig_1*trace(S_1)-maxeig)))

}

mata
version 10
real matrix BLIML (real matrix W_1,  real matrix W_2, real matrix W_12, real matrix Omega, BLIML_start){
S=optimize_init()
optimize_init_evaluator(S, &myfun2 ())
optimize_init_params(S, BLIML_start)
/*This line tells the optimizer to hold W_1, W_2, and W_12 constant */
optimize_init_argument(S, 1, W_1)
optimize_init_argument(S, 2, W_2)
optimize_init_argument(S, 3, W_12)
optimize_init_argument(S, 4, Omega) 
optimize_init_argument(S, 5, BLIML_start) 
/*I added two statements to specify the nelder-mead method for the optimization*/
optimize_init_technique(S, "nm")
optimize_init_nmsimplexdeltas(S,0.5)
beta_BLIML=optimize(S)
BLIML=optimize_result_value(S)
return (BLIML)
}

end

