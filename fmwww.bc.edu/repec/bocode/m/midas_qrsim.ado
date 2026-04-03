*! version 2.00 march 24, 2026
*! Ben A. Dwamena: bdwamena@umich.edu

cap program drop midas_qrsim
program midas_qrsim, eclass byable(recall) sortpreserve
version 15.1

if _by() {
local BY `"by `_byvars'`_byrc0':"'
}

if  !replay()  {

#delimit;
syntax varlist(min=4  max=4)
[if] [in],  ID(varlist)  
SIMulation(string asis)
[Link(string)
BURN(integer 50)
DRAWS(integer 25)      
LEVEL(integer 95)
noHEADer  
noCOEFficients
noSUMmary
HSROC
noFITstats  
HETstats *];
#delimit cr

qui {
preserve
marksample touse
markout `touse'
if _by()  {
qui replace `touse' = 0  if  `_byindex' != _byindex()
}
global touse= `touse'
nois di ""
nois di in white "........................................................................."
nois di ""
nois di in white "........................................................................."  
nois di ""
nois di in white "........................................................................."
nois di ""
tokenize `varlist'
local tp `1'
local fp `2'
local fn  `3'
local tn `4'



qui {

tempvar pid StudyIds counts
gen `pid'= _n
global alph = (100-`level')/200


if "`id'" != "" {
egen __midas_studylabel = concat(`id'), p(" ")
}
else {
tempvar id
gen `id'=string(_n)
egen __midas_studylabel  = concat(`id'), p(" ")
}
qui count   if `touse'  & ( (`tp'==0 & `fn'==0) | (`tn'==0 & `fp'==0) )
if r(N) > 0 {
di as error "One or more studies have both tp and fn==0 or both tn and fp==0"
di as error  "replace both fp and tn as missing or botn fn and tp as missing which ever is applicable and rerun program."
exit 459
}
// Link functions
// logit is the default link if none has been specified.
if wordcount("`link'") > 1 {
disp in re "only one of the following options allowed at a time: "
disp in re "logit probit cloglog"
exit 198
}

local model "Bivariate Generalized Linear Mixed Modeling"
// logit link
if "`link'"=="logit" | "`link'"=="l" | "`link'"=="" {
local link "logit"
}
// probit
else if "`link'"=="probit" | "`link'"=="p" | {
local link "probit"
}
// cloglog
else if "`link'"=="cloglog" | "`link'"=="c" |  {
local link "cloglog"
}
// Approximation Strategies

if wordcount("`simulation'")   > 1 {
disp in re "only one of the following options allowed at a time: "
disp in re "halton hrandom shuffle random"
exit 198
}

if !inlist("`simulation'", "halton", "hrandom", "shuffle", "random") {
disp in re "simulation() must be one of: halton, hrandom, shuffle, random"
exit 198
}


if `level' < 10 | `level' > 99 {
di as error "level() must be between 10 and 99"
exit 198
}

if ~missing("`sortby'") {
gsort  `sortby'
local sortby "`sortby'"
}

tempname varlist
sort __midas_studylabel
mkmat `1' `2' `3' `4', mat(`varlist')  rownames(__midas_studylabel)
count if `touse'
local numobs = r(N)
ereturn scalar nstudies=`numobs'
}
tempvar sum sumtp sumfn sumtn sumfp prev
tempname
egen `sumtp' = total(`tp')  if `touse'
egen `sumfn' = total(`fn')  if `touse'
egen `sumtn' = total(`tn')  if `touse'
egen `sumfp' = total(`fp')   if `touse'

local sumtpfn = `sumtp' + `sumfn'
local sumtnfp = `sumtn' + `sumfp'  
gen `prev'=(`tp' + `fn')/(`tp' + `tn' + `fn' + `fp')   if `touse'
sum `prev'
local prev=r(mean)
local prevmin= r(min)
local prevmax=r(max)

/*  MODEL SPECIFICATION AND ESTIMATION   */
gen __midas_dep1 = int(`1')                  
gen __midas_dep2 = int(`4')                    
gen __midas_denom1 =  int(`1' + `3')                      
gen __midas_denom2 = int(`2' + `4')
gen __midas_studyid =_n
global midas_nobs =_N
qui gen double __midas_invnum1 = 1/__midas_denom1
sum __midas_invnum1, meanonly
global avnum1=r(mean)
qui gen double __midas_invnum2 = 1/__midas_denom2
sum __midas_invnum2, meanonly
global avnum2=r(mean)

global draws "`draws'"
sort __midas_studyid
if  "`simulation'"=="halton" {
qui mdraws, neq(2) dr($draws) prefix(__midas_c) burn( `burn')   seed(1234) antithetics
}
else if  "`simulation'"=="hrandom" |"`simulation'"=="shuffle"  {
qui mdraws, neq(2) dr($draws) prefix(__midas_c) burn( `burn')   seed(1234) antithetics  `simulation'
}
else if "`simulation'"=="random" {
* mdraws only supports quasi-random sequences; generate pseudo-random draws manually
set seed 1234
local _N = _N
forvalues r = 1/$draws {
	qui gen double __midas_c1_`r' = runiform() in 1/`_N'
	qui gen double __midas_c2_`r' = runiform() in 1/`_N'
}
}
forvalues r = 1/$draws {
bysort __midas_studyid: gen random1`r'=invnormal(__midas_c1_`r')
bysort __midas_studyid: gen random2`r'=invnormal(__midas_c2_`r')
       }
sort __midas_studyid    
qui reshape long __midas_denom __midas_dep, i(__midas_studyid) j(__midas_dtruth)
qui tabulate __midas_dtruth, generate(__midas_mu)
tempvar disgroup
tempname groups
qui gen `disgroup'1 = __midas_mu1
qui gen `disgroup'2 = __midas_mu2
mkmat `disgroup'1 `disgroup'2, mat(`groups') rown(__midas_studylabel)
matrix colnames `groups' = disgroup2 disgroup1

qui meglm (__midas_dep __midas_mu1 __midas_mu2, noconstant)(__midas_studyid: __midas_mu1 __midas_mu2, noconstant ///
cov(un)), family(binomial __midas_denom) link(logit) intmethod(laplace) nogroup nolrt

qui nlcom (mu1: _b[__midas_mu1])(mu2: _b[__midas_mu2]) ///
(varmu1:_b[/var(__midas_mu1[__midas_studyid])]) (varmu2: _b[/var(__midas_mu2[__midas_studyid])]) ///
(covmu: _b[/cov(__midas_mu1[__midas_studyid],__midas_mu2[__midas_studyid])]), post

mat start = e(b)
nois ml model derivative0 midas_d0 (__midas_dep = __midas_mu1, nocons) ///
(__midas_dep = __midas_mu2, nocons) /lnsig1 /lnsig2 /atsig12, ///
maximize search(off) from(start, copy) difficult negh ///
nopreserve group(__midas_studyid) nooutput

tempname modest
estimates store __midas_modest
local ll = e(ll)
local k = e(k)
local N = e(N)
local dev = -2 * `ll'
local AIC =  -2 * `ll' + 2*`k'
local BIC= -2 * `ll' + `k'*log(`N')


drop  __midas_c* random*  __midas_mu* `disgroup'*

qui reshape wide

set seed 124586

forvalues i=1/2 {
gen double __midas_randeff`i' = rnormal(0, (exp(_b[/lnsig`i'])))
gen double __midas_serandeff`i' = rnormal(0, (exp(_se[/lnsig`i'])))
gen double __midas_eta`i' = _b[eq`i':__midas_mu`i'] + __midas_randeff`i'
gen double __midas_pred`i' = invlogit(_b[eq`i':__midas_mu`i'] + __midas_randeff`i')
gen __midas_ypred`i' = (__midas_denom`i'*__midas_pred`i')
gen double dres`i' =  cond(__midas_dep`i' > 0 & __midas_dep`i' < __midas_denom`i', ///
2*__midas_dep`i'*ln(__midas_dep`i'/__midas_ypred`i') + 2*(__midas_denom`i'-__midas_dep`i') * ///
ln((__midas_denom`i'-__midas_dep`i')/(__midas_denom`i'-__midas_ypred`i')), ///
cond(__midas_dep`i'==0, 2*__midas_denom`i'*ln(__midas_denom`i'/(__midas_denom`i' - __midas_ypred`i')), ///
2*__midas_dep`i'*ln(__midas_dep`i'/__midas_ypred`i')))
gen double dresidi`i'= sign(__midas_ypred`i'-__midas_dep`i')*sqrt(abs(dres`i'))
qui replace dresidi`i' = dresidi`i'/sqrt(__midas_pred`i'*(1 - __midas_pred`i')*__midas_denom`i')
}
save "c:\ado/personal/__midas_qrsim_data.dta", replace

tempname Vsum bsum Vhess Vhsroc bhsroc scores
tempname Vblogit VIsquared bIsquared b V
tempname studywgts pred residuals reffects

halton_fitted
mat `pred' = r(pred)
mat `residuals' = r(residuals)
mat `reffects' = r(reffects)

halton_weights
mat `studywgts' =  r(studywgts)

halton_scorei
mat `scores' = r(scores)

halton_mat
local corrlogits = r(corrlogits)
local covlogits =  r(covlogits)
mat `b' = r(b)
mat `V' = r(V)
mat `bsum' = r(bsum)
mat `Vsum' = r(Vsum)

mat `Vhsroc' = r(Vhsroc)
mat `bhsroc' = r(bhsroc)

mat `Vblogit' = r(Vblogit)

mat `VIsquared' = r(VIsquared)

mat `bIsquared' = r(bIsquared)

mat `Vhess' = r(Vhess)

ereturn post `b' `V'

restore
tempvar tousecopy
gen `tousecopy'=$touse
ereturn repost,  esample(`tousecopy')
foreach i in Vsum bsum Vhess Vhsroc bhsroc varlist scores groups  {
ereturn matrix `i'= ``i'', copy
}

foreach i in Vblogit VIsquared bIsquared studywgts pred residuals reffects {
ereturn matrix `i'= ``i'', copy
}
ereturn scalar N =$midas_nobs
ereturn scalar Ndis =`sumtpfn'
ereturn scalar Nnodis =`sumtnfp'
ereturn scalar ll =`ll'
ereturn  scalar dev = `dev'
ereturn  scalar AIC =`AIC'
ereturn scalar BIC =`BIC'
ereturn scalar k = 5
ereturn scalar kf = 2
ereturn scalar kr = 3
ereturn scalar prev = `prev'
ereturn scalar prevmin = `prevmin'
ereturn scalar prevmax = `prevmax'
ereturn scalar corrlogits = `corrlogits'
ereturn scalar covlogits = `covlogits'
if ~missing("`sortby'") {
eret local sortby `sortby'
}
ereturn local title "Bivariate Meta-analysis of Binary Diagnostic Test Accuracy Data"
if "`simulation'"== "halton" {
ereturn local estmethod  "Maximum Simulated Likelihood Using Halton Sequences"
}
else if "`simulation'"== "hrandom" {
ereturn local estmethod  "Maximum Simulated Likelihood Using Halton Sequences With Random Pertubation"
}
else if "`simulation'"== "shuffle" {
ereturn local estmethod  "Maximum Simulated Likelihood Using Shuffled Halton Sequences "
}
else if "`simulation'"== "random" {
ereturn local estmethod  "Maximum Simulated Likelihood Using Pseudo-Random Draws"
}
ereturn local family "Binomial"
ereturn local link `link'

ereturn local cmdline "midas_qrsim `0'"
eret local predict  "midas_qrsim_p"
ereturn local package "midas"
ereturn local cmd   "midas_qrsim"
}
}
else { // replay
if  "`e(cmd)'" != "midas_qrsim" error 301  // last estimates not found
if _by() error 190
#delimit;
syntax [if] [in] [, Level(cilevel)  
noHEADer  
noCOEFficients
noSUMmary
HSROC noFITstats  
HETstats
 UPVstats(numlist min=2 max=2)
 SRUC(string)  
 DIAGplot
 EBayes(string)
 REVman
XSIZE(passthru) YSIZE(passthru) TITLE(passthru) cc(real 0.5)
MScale(real 0.80) TEXTScale(real 1.00) CSIZE(real 36)  
SCHEME(passthru) GRSave(string) XTITLE(passthru) YTITLE(passthru)
*];
#delimit cr
}
if missing("`header'") {
nois di ""
nois di ""
nois di in smcl as text "{hline 76}"
nois di ""
nois di as txt _n e(title) _n
nois di as txt _n "By " e(estmethod) _n
nois di in smcl as text "{hline 76}"
nois di ""
nois di ""
nois di as txt "Number of studies" _col(60) "= " _col(64) as res %5.0f e(N)
nois di ""
nois di as txt "Reference-positive Units" _col(60) "= " _col(64) as result %5.0f e(Ndis)
nois di ""
nois di as txt "Reference-negative Units" _col(60) "= " _col(64) as result %5.0f e(Nnodis)
nois di ""
nois di as txt "Pretest Prob of Disease" _col(60) "= " _col(64) as result %5.2f e(prev)
}
nois di ""
nois di ""
if missing("`fitstats'") {
nois di ""
nois  di as txt "Deviance" _col(60) "= " _col(64) as res %5.0f  e(dev)
nois  di " "
nois  di as txt "Akaike Information Criterion" _col(60) "= " _col(64) as res  %5.0f  e(AIC)
nois  di " "
nois  di as txt "Bayesian Information Criterion" _col(60) "= " _col(64) as res  %5.0f e(BIC)
nois  di " "
nois  di as txt "Log-likelihood " _col(60) "= " _col(64) as res  %5.0f  e(ll)
nois di ""
}
nois di ""
nois di ""
if  mi("`coefficients'") {
nois di  in smcl in gr  _newline(1)  "{hilite: Fixed and Random Effects Estimates:}"
tempname b V bsum Vsum
mat `b' = e(b)
mat `V' = e(V)
nois _coef_table , bmatrix(`b')  vmatrix(`V') cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)
}
nois di ""
nois di ""
nois di ""
if mi("`summary'") {
nois di in smcl in gr  _newline(1)   "{hilite: Summary Test Performance Estimates:}"
mat `bsum' = e(bsum)
mat `Vsum' = e(Vsum)
nois _coef_table , bmatrix(`bsum')  vmatrix(`Vsum') cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)
nois di ""
}
if !mi("`hetstats'") {
nois di in smcl in gr  _newline(1) "{hilite: Heterogeneity/Inconsistency Statistics:}"
tempname bIsquared VIsquared
mat `bIsquared' = e(bIsquared)
mat `VIsquared' = e(VIsquared)
nois _coef_table , bmatrix(`bIsquared')  vmatrix(`VIsquared') cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)
nois di ""
}

if !mi("`hsroc'") {
nois di in smcl in gr  _newline(1) "{hilite: Derived HSROC Model Estimates:}"
tempname bhsroc Vhsroc
mat `bhsroc' = e(bhsroc)
mat `Vhsroc' = e(Vhsroc)
nois _coef_table , bmatrix(`bhsroc')  vmatrix(`Vhsroc') cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)
nois di ""
}
if !missing("`revman'") {
tempname brev Vrev crev
mat `brev' = e(b)
mat `Vrev' = e(V)
local cov01 = `Vrev'[1,2]
qui _coef_table , bmatrix(`brev')  vmatrix(`Vrev')
mat `crev' = r(table)'
local  sp = `crev'[1,1]
local  spse = `crev'[1,2]
local  sn = `crev'[2,1]
local  snse = `crev'[2,2]
local reffs1= `crev'[3,1]
local reffs2= `crev'[4,1]

nois di in smcl as text "{hline 76}"
nois di  in smcl in gr  _newline(1)  "{hilite: Parameters Estimates for Export into RevMan}"
nois di ""
nois di ""
nois di  in smcl in blue  "{title: Parameters for SROC Curve}"
nois di ""
nois di as text "{hilite:E(logitse)}" as text ": Expected mean logit sensitivity" _col(66) " =   " _col(70) as res %5.4f `sn'
nois di ""
nois di as text "{hilite:E(logitsp)}" as text ": Expected mean logit specificity" _col(66) " =   " _col(70) as res %5.4f `sp'
nois di ""
nois di as text  "{hilite:Var(logitse)}" as text ": Between-study variance of logit sensitivity" _col(66) " =   " _col(70) as res %5.4f `reffs2'
nois di ""
nois di as text  "{hilite:Var(logitsp)}" as text ": Between-study variance of logit specificity" _col(66) " =   " _col(70) as res %5.4f `reffs1'
nois di ""
nois di as text  "{hilite:Cov(logits)}" as text ": Between-study Covariance" _col(66) " =   " _col(70) as res %5.4f e(covlogits)
nois di ""
nois di as text  "{hilite:Corr(logits)}" as text": Between-study Correlation" _col(66) " =  " _col(70) as res %5.4f e(corrlogits)
nois di ""
nois di ""
nois di ""
nois di  in smcl in blue "{title: Parameters for Confidence and Prediction Regions:}"
nois di ""
nois di as text "{hilite:SE(E(logitse))}" as text ": Standard error of expected mean logit sensitivity" _col(66) " =   " _col(70) as res %5.4f `snse'
nois di ""
nois di as text  "{hilite:SE(E(logitsp))}" as text ": Standard error of expected mean logit specificity" _col(66) " =   " _col(70) as res %5.4f `spse'
nois di ""
nois di  as text "{hilite:Cov(Es)}" as text ": Covariance between mean logit sensitivity and specificity" _col(66) " =  " _col(70) as res %5.4f `cov01'
nois di ""
nois di as text  "{hilite:Studies}" as text ": Number of Studies included in meta-analysis" _col(66) " =   " _col(70) as res %2.0f e(N)
nois di ""
}
nois di ""
nois di ""

if "`sruc'"  !="" {
qui{
preserve
tempname bsruc Vsruc srucmat srucsens srucspec srucprev
tempvar Treated Untreated x1 x2
mat `bsruc' = e(bsum)
mat `Vsruc' = e(Vsum)
_coef_table, bmatrix(`bsruc') vmatrix(`Vsruc')
mat `srucmat' = r(table)'
scalar `srucsens' = `srucmat'[1,1]  
scalar `srucspec' = `srucmat'[2,1]
scalar `srucprev' = e(prev)
twoway__function_gen y = `srucsens'-((1 - `srucprev')/`srucprev')*(x/(1-x))*(1-`srucspec') , r(0.1 0.99) x(x) gen(`Treated' `x1', replace) n(`c(N)')
 
twoway__function_gen y = `srucspec'-(`srucprev'/(1-`srucprev'))*((1-x)/x)*(1-`srucsens'), r(0.1 0.99) x(x) gen(`Untreated' `x2', replace) n(`c(N)')
         
 
local a: di "1:100"
local b: di  "1:4"
local c: di "2:3"
local d: di "3:2"
local e: di "4:1"
local f: di "100:1"
if "`sruc'"  == "snbt" {
#delimit;
nois twoway (line `Treated' `x1', sort clpat(solid) clwidth(medium) clcolor(green) connect(direct) xaxis(1 2))(function y=0),
xlabel(0 "`a'" 0.2 "`b'" 0.4 "`c'" 0.6 "`d'" 0.8 "`e'" 1 "`f'", axis(2))
xtitle("Risk Threshold", axis(1)  size(*0.75)) ytitle("Standardized Net Benefit Treated", size(*0.75))
xtitle("Cost:Benefit Ratio", axis(2) size(*0.75)) ylabel(, angle(hor));
#delimit cr
}
if "`sruc'"  == "snbu" {
#delimit;
nois twoway (line `Untreated' `x2', sort clpat(solid) clcolor(red) clwidth(medium) connect(direct) xaxis(1 2))(function y=0),
xlabel(0 "`a'" 0.2 "`b'" 0.4 "`c'" 0.6 "`d'" 0.8 "`e'" 1 "`f'", axis(2))
xtitle("Risk Threshold", axis(1) size(*0.75)) ytitle("Standardized Net Benefit Untreated", size(*0.75))
xtitle("Cost:Benefit Ratio", axis(2) size(*0.75)) ylabel(, angle(hor));
#delimit cr
 }
 
if "`sruc'"  == "both" {
#delimit;
twoway (line `Treated' `x1', sort clpat(solid) clwidth(medium) clcolor(green) connect(direct) xaxis(1 2))(function y=0),
xlabel(0 "`a'" 0.2 "`b'" 0.4 "`c'" 0.6 "`d'" 0.8 "`e'" 1 "`f'", axis(2))
xtitle("Risk Threshold", axis(1)  size(*0.75)) ytitle("Standardized Net Benefit Treated", size(*0.75))
xtitle("Cost:Benefit Ratio", axis(2) size(*0.75)) ylabel(, angle(hor)) nodraw name(treated, replace) ;
#delimit cr
#delimit;
twoway (line `Untreated' `x2', sort clpat(solid) clcolor(red) clwidth(medium) connect(direct) xaxis(1 2))(function y=0),
xlabel(0 "`a'" 0.2 "`b'" 0.4 "`c'" 0.6 "`d'" 0.8 "`e'" 1 "`f'", axis(2))
xtitle("Risk Threshold", axis(1) size(*0.75)) ytitle("Standardized Net Benefit Untreated", size(*0.75))
xtitle("Cost:Benefit Ratio", axis(2) size(*0.75)) ylabel(, angle(hor)) nodraw name(untreated, replace);
#delimit cr

nois graph combine treated untreated, rows(1)
}
restore
}
}


if "`ebayes'" != "" {
qui {
mat ebforest=e(varlist)
local id: rowfullnames ebforest
local x: word  count("`id'")
tempvar Studddy ebs iddd
tempname befor Vefor eforest
qui gen `Studddy' = ""
forvalues i =1/`x' {
local bb: word `i' of `id'
qui replace `Studddy' = "`bb'" in `i'
}

gen `iddd'=_n
gsort  `iddd'
gen `ebs' = strlen(`Studddy')
sum `ebs', meanonly
local ebs4 = int(r(max) + 40)
format `Studddy' %-`ebs4's
mat `befor' = e(bsum)
mat `Vefor' = e(Vsum)
_coef_table, bmatrix(`befor') vmatrix(`Vefor')
mat `eforest' = r(table)'
local mvar1 = `eforest'[1,1]  
local mvar2 = `eforest'[2,1]

/* STUDY-SPECIFIC Sensitivity (True Positive Rate)*/
tempvar sens senslo senshi sensse spec speclo spechi specse FPR          
version 9: gen `sens' = tp/(tp+fn)  
version 9: gen `senslo' = invbinomial(tp+fn,tp,$alph)  
version 9: gen `senshi' = invbinomial(tp+fn,tp,1-$alph)
version 9: gen `sensse' = (`senshi'-`senslo')/(2*invnormal(1-$alph))

/* STUDY-SPECIFIC Specificity (True Negative Rate) */

version 9: gen `spec' = tn/(tn+fp)      
version 9: gen `speclo' = invbinomial(tn+fp,tn,$alph)  
version 9: gen `spechi' = invbinomial(tn+fp,tn,1-$alph)
version 9: gen `specse' =(`spechi'-`speclo')/(2*invnormal(1-$alph))

           
tempvar ebsens ebsenslo ebsenshi ebsensse ebspec ebspeclo ebspechi ebspecse
tempvar randeffs1 randeffs2 serandeffs1 serandeffs2
tempname reffects coeffs1 coeffs2  
mat `reffects' = e(reffects)
local eid: rownames `reffects'
local x: word  count("`eid'")
gen `randeffs1' = .
gen `randeffs2' = .
gen `serandeffs1' = .
gen `serandeffs2' = .
forvalues i =1/`x' {
replace `randeffs1' = `reffects'[`i',1] in `i'
replace `randeffs2' = `reffects'[`i',2] in `i'
replace `serandeffs1' = `reffects'[`i',3] in `i'
replace `serandeffs2' = `reffects'[`i',4] in `i'
}
mat bvars = e(Vblogit)
mat coeffs = e(b)
scalar `coeffs1' = coeffs[1,1]
scalar `coeffs2' = coeffs[1,2]
gen `ebsens' = invlogit(`randeffs2' + `coeffs2')
gen `ebsenslo' = invlogit(`randeffs2'  + `coeffs2' - 1.96*`serandeffs2')
gen `ebsenshi' = invlogit(`randeffs2'  + `coeffs2' + 1.96*`serandeffs2')
gen `ebsensse' = (`ebsenshi'-`ebsens')/invnormal(0.975)
gen `ebspec' = invlogit(`randeffs1' + `coeffs1')
gen `ebspechi' = invlogit(`randeffs1'  + `coeffs1' + 1.96*`serandeffs1')
gen `ebspeclo' = invlogit(`randeffs1'  + `coeffs1' - 1.96*`serandeffs1')
gen `ebspecse'=(`ebspechi'-`ebspec')/invnormal(0.975)
format `ebsens' `ebsenslo' `ebsenshi' `ebspec' `ebspeclo' `ebspechi' %9.2f
format `sens' `senslo' `senshi' `spec' `speclo' `spechi' %9.2f

tempvar obs obs1 wgt1 wgt2
gen `obs' = _n
gen `obs1' = _n + 0.30
count
local max1 = r(N)
local maxx = `max' + 2
label value `obs' obs
label value `obs1' obs1

forval i = 1/`max1'{
local value = `"`value' `i'"'
local value1 = `"`value' `i'"'
label define obs `i' "`=`Studddy'[`i']'", modify
}

local ylabopt "labsize(*`textscale') tl(*0) labgap(*0)  labc(bg) tlc(none) "
local xlab1 "xlab(0(.5)1.0, format(%2.1f) labsize(*`textscale') labc(bg) tlc(none))"



if "`ebayes'"=="for" {

gen `wgt1' = 1/(`ebsensse' * `ebsensse')
#delimit ;
twoway (rspike `ebsenslo' `ebsenshi' `obs', ylabel(`"`value'"', valuelabel labsize(*.75) tl(*0) angle(360))
hor s(i) lpat(blank)  `xlab1')(scatter `obs1' `sens', ms(i) msize(`mscale2') mcolor(gs10))
(scatter `obs' `ebsens', ms(i) msize(`mscale2') mcolor(gs10))
(rspike `senslo' `senshi' `obs1', ylabel(`"`value'"', valuelabel labsize(*.75) tl(*0) angle(360))
hor s(i) lpat(blank)  `xlab1'), legend(off) xtitle("", size(*.5)) yscale(noline) xscale(off fill)
plotregion(style(none)) nodraw ytitle("", size(*.5)) ysca(rev) title("", size(*.5) pos(1) justification(right)) fxsize(10) name(mplot, replace);
#delimit cr

#delimit ;
twoway (rspike `ebsenslo' `ebsenshi' `obs', ylabel(`"`value'"', nolabel
`ylabopt' angle(360)) hor s(i) blpattern(solid) blwidth(thin) blcolor(black) `xlab1')
(rspike `senslo' `senshi' `obs1', ylabel(`"`value1'"', nolabel
`ylabopt' angle(360)) hor s(i) blpattern(dash) blwidth(thin) blcolor(black) `xlab1')
(scatter `obs' `ebsens', ms(o) mcolor(black))
(scatter `obs1' `sens', ms(oh) mcolor(black)), ytitle("", size(*.5))
legend(off) xtitle("Sensitivity", size(*.75)) title("", size(*.5)
justification(left)) ysca(rev) nodraw name(mplot1, replace) xline(`mvar1') ;
#delimit cr

gen `wgt2' = 1/(`ebspecse'*`ebspecse')

#delimit ;
twoway (rspike `ebspeclo' `ebspechi' `obs', ylabel(`"`value'"', nolabel
`ylabopt' angle(360)) hor s(i) blpattern(solid) blwidth(thin) blcolor(black) `xlab1')
(rspike `speclo' `spechi' `obs1', ylabel(`"`value1'"', nolabel
`ylabopt' angle(360)) hor s(i) blpattern(dash) blwidth(thin) blcolor(black) `xlab1')
(scatter `obs' `ebspec', ms(o) mcolor(black))
(scatter `obs1' `spec', ms(oh) mcolor(black)), legend(off)
xtitle("Specificity", size(*.75)) ytitle("", size(*.5))  title("", size(*.5)
justification(left)) ysca(rev) nodraw  name(mplot2, replace) xline(`mvar2');
#delimit cr
#delimit ;
nois graph combine mplot mplot1 mplot2,  row(1) ysize(6) xsize(4)
note("MLE of mean sensitivity and specificity (solid vertical lines)"
"Predicted data (solid horizontal lines and solid markers)"
"Observed data (dashed horizontal lines and open markers)",
position(12) justification(center) size(*.75)) `options';                                  
#delimit cr
}
else if "`ebayes'"=="roc" {
#delimit;
nois twoway (pci 0 1 1 0, clpat(solid) clc(black))
(pcspike `sens' `spec' `ebsens' `ebspec', lwidth(vvthin) lpatt(solid) lcol(black*5))
(scatter `sens' `spec', mlab(`studddy') mlabsize(*.5)
mlabpos(0) mcolor(gray) mlabc(black*2) msym(O) sort)
(scatter `ebsens' `ebspec', mlabel(`studddy') mlabpos(0) mlabsize(*.5)
mlabc(black*2) mcolor(black) msym(Sh) sort)
, legend(order(3 "Observed Data" 4 "EBayes" 1 "Null Line") size(*.75)
symxsize(2) pos(5) ring(0) col(1))
xsc(range(0(0.2)1)) ysc(range(0 1))  xla(0(.2)1, nogrid format(%7.1f))
yla(0(.2)1, nogrid angle(horizontal) format(%7.1f))  
plotregion(margin(zero)) xsc(rev) xti(Specificity)
yti(Sensitivity);                                  
#delimit cr
}
}
}

if "`diagplot'"  !="" {
qui{
tempname reffects scores residuals H invH scorei ci
tempvar cooksd
mat `reffects' = e(reffects)
svmat `reffects', names(col)
mat `scores'= e(scores)
svmat `scores', names(col)
mat `residuals'= e(residuals)
svmat `residuals', names(col)

matrix `H' = e(Vhess)
local k = colsof(`H')
local N = _N

qui gen `cooksd' = .
 local i = 1
 while `i'<=`N'{
 mkmat g1-g`k' if _n==`i', matrix(`scorei')
 matrix `ci' = 2*`scorei'*`H'*`scorei''
 qui replace `cooksd' = `ci'[1,1] in `i'
 local i = `i' + 1
  }
format `cooksd' %5.2f
count if `cooksd' !=.
local xmax=r(N)
local n = 4*e(k)/r(N)

tw (spike `cooksd' studdy)(scatter `cooksd' studdy if `cooksd' !=. & `cooksd' > `n' & studdy !=., ///
mlw(medthin) mfc(yellow) mlc(black) msize(*1.5) ms(O)) ///
(scatter `cooksd' studdy if `cooksd' !=. & `cooksd' > `n' & studdy !=., ///
ms(i) mlabp(0) mlabel(studdy) mlabs(*.5) mlabc(black)) , ///
legend(off) yline(`n', lpat(dash) lw(thin)) ylab(, angle(hor) nogrid) xlab(, nogrid) ///
name(cooksd, replace) ytitle("Cook's Distance", size(*.75)) ///
xtitle("Study", size(*.75)) nodraw title("Influence Analysis", size(*.75))

******Residual-based Goodness-of-fit Assessment**********
gen dresid=dresid1 + dresid2
pnorm dresid, name(pdresid, replace) title("Goodness-Of-Fit", size(*.75)) ///
xtitle("Normal Quantile", size(*.75)) ylab(, angle(hor) ///
format(%7.2f)) nodraw ytitle("Deviance Residual", size(*.75))

******Bivariate Normality using Mahalanobis Squared Distances**********
mkmat __midas_randeff*, matrix(xvar)
matrix accum cov = __midas_randeff*, noc dev
matrix cov = cov/(r(N)-1)
matrix mahascorex= (xvar) * (inv(cov)) * (xvar')
matrix mahascore= (vecdiag(mahascorex))'
svmat mahascore, names(mahascore)
pchi mahascore1,  df(2)  nodraw name(bivar, replace) ///
ylab(, angle(hor)) title("Bivariate Normality", size(*.75)) ///
xtitle("Chi-squared Quantile", size(*.75)) ///
ytitle("Mahalanobis Score", size(*.75))

*****Outlier Detection using standardized residuals**********
tempname groups bvars
tempvar stdres1 stdres2
mat `groups' = e(groups)
mat `bvars' = e(Vblogit)
local bvars1 = `bvars'[1,1]
local bvars2 = `bvars'[2,2]
svmat `groups', names(col)
gen `stdres1' = (1-disgroup1)*__midas_randeff1/ sqrt(`bvars1' - __midas_serandeff1^2)
gen `stdres2' = disgroup2*__midas_randeff2/ sqrt(`bvars2' - __midas_serandeff2^2)
tw (scatter `stdres2' `stdres1', mlw(medthin) mlc(black) mfc(gs15) msize(*1.5) ms(O)) ///
(scatter `stdres2' `stdres1' if (`stdres2' < -2 | `stdres2' > 2)|(`stdres1' < -2 | `stdres1' > 2), mlw(medthin) mlc(black) mfc(yellow) msize(*1.5) ms(O)) ///
(scatter `stdres2' `stdres1', ms(i) mlabp(0) mlabel(studdy) mlabs(*.5) mlabc(black)), ylab(-3(1)3, angle(hor) format(%7.1f) nogrid) ///
xlab(-3(1)3, format(%7.1f) nogrid) xline(-2 0 2, lw(thin) lpat(dash)) yline(-2 0 2, lpat(dash) lw(thin) ) legend(off) ///
name(outlier, replace) ytitle("Standardized_Residual_2", size(*.75)) xtitle("Standardized_Residual_1", size(*.75)) ///
title("Outlier Detection", size(*.75)) nodraw

nois graph combine pdresid outlier cooksd  bivar, rows(2)  `title'  `options'
}
}
end

program define halton_fitted, rclass
cap preserve
cap estimates restore __midas_modest
use "c:\ado/personal/__midas_qrsim_data.dta", clear
tempname residuals reffects pred
sort __midas_studylabel
mkmat dresidi*, mat(`residuals') rownames(__midas_studylabel)
matrix colnames `residuals' = dresid1 dresid2

sort __midas_studylabel
mkmat __midas_eta* __midas_pred*, mat(`pred') rownames(__midas_studylabel)
matrix colnames `pred' = eta1 eta2 pred1 pred2

sort __midas_studylabel

mkmat __midas_randeff* __midas_serandeff*, mat(`reffects') rownames(__midas_studylabel)
matrix colnames `reffects' = __midas_randeff1 __midas_randeff2 __midas_serandeff1 __midas_serandeff2
return matrix reffects = `reffects', copy
return matrix residuals = `residuals', copy
return matrix pred = `pred', copy
cap restore
cap estimates restore __midas_modest
end

program define halton_weights, rclass
cap preserve
cap estimates restore __midas_modest
use "c:\ado/personal/__midas_qrsim_data.dta", clear

tempname Sigma Xmat Amat Bmat XTmat fish
tempname Zmat ZZmat Gmat invmat Vmat varb
tempvar true invn varp
mat `Sigma' = ((exp(_b[/lnsig1]))^2,[exp(2*tanh(_b[/atsig12]))-1]/[exp(2*tanh(_b[/atsig12]))+1]*(exp(_b[/lnsig2]))*(exp(_b[/lnsig1]))  ///
\ [exp(2*tanh(_b[/atsig12]))-1]/[exp(2*tanh(_b[/atsig12]))+1]*(exp(_b[/lnsig2]))*(exp(_b[/lnsig1])) , (exp(_b[/lnsig2]))^2)

sort __midas_studyid    
qui reshape long __midas_denom __midas_dep __midas_ypred __midas_pred __midas_eta, i(__midas_studyid) j(__midas_dtruth)

qui tabulate __midas_dtruth, generate(`true')

mkmat `true'1 `true'2, mat(`Xmat')


// transpose the design matrix

mat `XTmat' = `Xmat''

// create the random effects design matrix
// Create A (diagonal matrix) using variable, n (number of diseased for sensitivity and __midas_denomber of non-diseased for specificity) in dataset

gen double `invn' = 1/__midas_denom
mkmat `invn', mat(`Amat')

// create a diagonal matrix with the matrix, A, above

mat `Amat' = diag(`Amat')
// create variable containing the probability of true positive and true negative

// create variance of Bernoulli distribution

gen double `varp' = ((__midas_pred)*(1-__midas_pred))

// Create B (diagonal matrix) based on the predicted probability,

mkmat `varp', mat(`Bmat')
mat `Bmat' = diag(`Bmat')

// Creating the G matrix containing the variances of the random effects
mat `Zmat' = I(_N)
mat `ZZmat' = I(0.5*_N)

mat `Gmat' =`ZZmat'#`Sigma'

// create within-trialid, between-trialid and total variance matrix for the observations

mat `Vmat' = (`Zmat'*`Gmat'*`Zmat'') + (`Amat'*syminv(`Bmat'))


// invert the variance matrix, V

mat `invmat' = invsym(`Vmat')

// derive fisher's Information matrix

mat `fish' = `XTmat'*`invmat'*`Xmat'

// invert fisher's Information matrix

mat `varb' = invsym(`fish')

// Loop over studies to obtain the trialid specific percentage weights

qui forvalues i = 1/$midas_nobs {
mat `Vmat'`i' = `Vmat'

// Replace trialid i so that it has zero information

mat `Vmat'`i'[(`i'*2)-1,(`i'*2)-1] = 1000000000

mat `Vmat'`i'[(`i'*2)-1,`i'*2] = 0

mat `Vmat'`i'[`i'*2,(`i'*2)-1] = 0


mat `Vmat'`i'[`i'*2,`i'*2] = 1000000000

// recalculate matrices when trialid i removed

mat `invmat'`i' = invsym(`Vmat'`i')

mat `fish'`i' = `XTmat'*`invmat'`i'*`Xmat'

mat `fish'`i'_`i' = `fish' - `fish'`i'

mat weight`i' = `varb'*`fish'`i'_`i'*`varb'

// derive percentage weight for trialid i for sensitivity

mat pctwgt`i'sens = 100*(weight`i'[1,1]/`varb'[1,1])

// derive percentage weight for trialid i for specificity

mat pctwgt`i'spec = 100*(weight`i'[2,2]/`varb'[2,2])
// derive percentage weight for trialid i
scalar wgt`i' = 100*trace(weight`i')/trace(`varb')
 
}

// Display the percentage weights
qui keep __midas_dtruth __midas_pred __midas_studylabel __midas_studyid
qui reshape wide __midas_pred , i(__midas_studyid) j(__midas_dtruth)
tempvar senwgt spewgt bivwgt
tempname studywgts
nois di ""
nois di ""
qui gen double `senwgt' =.
qui gen double `spewgt' =.
qui gen double `bivwgt' =.
qui forvalues i = 1/$midas_nobs {
qui replace `senwgt' = pctwgt`i'sens[1,1]    in `i'
qui replace `spewgt' = pctwgt`i'spec[1,1]   in `i'
qui replace `bivwgt' = wgt`i'   in `i'
}
sort __midas_studylabel
mkmat `senwgt' `spewgt' `bivwgt', matrix(`studywgts')  rownames(__midas_studylabel)
matrix colnames `studywgts' = senwgt spewgt bivwgt
// matname rename removed: col 3 stays "bivwgt" to match midas_mle convention
// (midas_bvsroc, midas_rgsroc, midas_lrmat all expect svmat col named "bivwgt")
return matrix studywgts = `studywgts', copy
cap restore
cap estimates restore __midas_modest
end

cap program drop halton_mat
program define halton_mat, rclass
cap preserve
cap estimates restore __midas_modest
tempname Vblogit Vwlogit sigmasqspe sigmasqsen Isqspe Isqsen Isqbiv
tempname bIsquared  VIsquared Vhess Sens Spec DOR LRN LRP
tempname bsum Vsum bhsroc Vhsroc Alpha Theta beta s2alpha s2theta
tempname Vblogit Vwlogit bIsquared VIsquared VVV bbb

mat `Vblogit' =((exp(_b[/lnsig1]))^2 , [exp(2*tanh(_b[/atsig12]))-1]/[exp(2*tanh(_b[/atsig12]))+1]*(exp(_b[/lnsig2]))*(exp(_b[/lnsig1])) ///
\ [exp(2*tanh(_b[/atsig12]))-1]/[exp(2*tanh(_b[/atsig12]))+1]*(exp(_b[/lnsig2]))*(exp(_b[/lnsig1])) , ///
(exp(_b[/lnsig2]))^2)
return matrix Vblogit = `Vblogit', copy

qui nlcom (`sigmasqspe': $avnum2*(exp((((exp(_b[/lnsig2]))^2)/2)+_b[eq2: __midas_mu2])+ ///
exp((((exp(_b[/lnsig2]))^2)/2)-_b[eq2: __midas_mu2])+2)) ///
(`sigmasqsen': $avnum1*(exp((((exp(_b[/lnsig1]))^2)/2)+_b[eq1: __midas_mu1])+ ///
exp((((exp(_b[/lnsig1]))^2)/2)-_b[eq1: __midas_mu1])+2)),  ///
post  cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)

mat `Vwlogit' = (_b[`sigmasqsen'],0 \ 0, _b[`sigmasqspe'])
return matrix Vwlogit = `Vwlogit', copy
 estimates restore __midas_modest

qui nlcom (`Isqsen': (exp(_b[/lnsig1]))^2/((exp(_b[/lnsig1]))^2+ ///
 ($avnum1*(exp((((exp(_b[/lnsig1]))^2)/2)+  ///
 _b[eq1: __midas_mu1])+exp((((exp(_b[/lnsig1]))^2)/2)-_b[eq1: __midas_mu1])+2)))) ///
 (`Isqspe': (exp(_b[/lnsig2]))^2/((exp(_b[/lnsig2]))^2+  ///
($avnum2*(exp((((exp(_b[/lnsig2]))^2)/2)+_b[eq2: __midas_mu2])+ ///
 exp((((exp(_b[/lnsig2]))^2)/2)-_b[eq2: __midas_mu2])+2)))) ///
 (`Isqbiv' : sqrt(exp(log(det(`Vblogit'))))/(sqrt(exp(log(det(`Vblogit'))))+ ///
 sqrt(($avnum1*(exp((((exp(_b[/lnsig1]))^2)/2)+_b[eq1: __midas_mu1])+ ///
 exp((((exp(_b[/lnsig1]))^2)/2)-_b[eq1: __midas_mu1])+2))* ///
($avnum2*(exp((((exp(_b[/lnsig2]))^2)/2)+_b[eq2: __midas_mu2])+ ///
 exp((((exp(_b[/lnsig2]))^2)/2)-_b[eq2: __midas_mu2])+2))))),  ///
 cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)

mat `bIsquared' = r(b)
mat `VIsquared' = r(V)
local hetsnames: di "Isqsen Isqspe Isqbiv"
mat colnames `bIsquared' = `hetsnames'
mat colnames `VIsquared' = `hetsnames'
mat rownames `VIsquared' = `hetsnames'
return matrix bIsquared = `bIsquared', copy
return matrix VIsquared = `VIsquared', copy


qui nlcom (`Sens': invlogit(_b[eq1: __midas_mu1]))(`Spec': invlogit(_b[eq2: __midas_mu2])) ///
(`DOR': _b[eq1: __midas_mu1]+_b[eq2: __midas_mu2])(`LRP': invlogit(_b[eq1: __midas_mu1])/(1-invlogit(_b[eq2: __midas_mu2]))) ///
(`LRN': (1-invlogit(_b[eq1: __midas_mu1]))/invlogit(_b[eq2: __midas_mu2])),  ///
cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)
 
mat `bsum' = r(b)
mat `Vsum' = r(V)
local sumnames: di "Sens Spec DOR LRP LRN"
mat colnames `bsum' = `sumnames'
mat colnames `Vsum' = `sumnames'
mat rownames `Vsum' = `sumnames'  
return matrix bsum = `bsum', copy
return matrix Vsum = `Vsum', copy

qui nlcom ///
(`Alpha': ((exp(_b[/lnsig1]))^2 / (exp(_b[/lnsig2]))^2)^(.25) * _b[eq2: __midas_mu2] ///
+ ((exp(_b[/lnsig2]))^2 / (exp(_b[/lnsig1]))^2)^(.25) * _b[eq1: __midas_mu1]) ///
(`Theta': .5*(((exp(_b[/lnsig1]))^2 / (exp(_b[/lnsig2]))^2)^(.25) * _b[eq2: __midas_mu2] ///
- ((exp(_b[/lnsig2]))^2 / (exp(_b[/lnsig1]))^2)^(.25) * _b[eq1: __midas_mu1])) ///
(`beta': .5*log((exp(_b[/lnsig1]))^2 / (exp(_b[/lnsig2]))^2)) ///
(`s2alpha': 2*( sqrt((exp(_b[/lnsig2]))^2 * (exp(_b[/lnsig1]))^2)+ ///
[exp(2*tanh(_b[/atsig12]))-1]/[exp(2*tanh(_b[/atsig12]))+1]*(exp(_b[/lnsig1]))*(exp(_b[/lnsig2])))) ///
(`s2theta': .5*( sqrt((exp(_b[/lnsig2]))^2 * ///
(exp(_b[/lnsig1]))^2) - [exp(2*tanh(_b[/atsig12]))-1]/[exp(2*tanh(_b[/atsig12]))+1]*(exp(_b[/lnsig1]))*(exp(_b[/lnsig2])))) ///
, cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)

local hsrocnames: di "Alpha Theta beta s2alpha s2theta"
matrix `bhsroc' = r(b)
matrix `Vhsroc' = r(V)
mat colnames `bhsroc' = `hsrocnames'
mat colnames `Vhsroc' = `hsrocnames'
mat rownames `Vhsroc' = `hsrocnames'
return matrix bhsroc = `bhsroc', copy
return matrix Vhsroc = `Vhsroc', copy


tempname logitspe logitsen varlogitspe varlogitsen covlogits corrlogits
qui nlcom (`logitsen': _b[eq1: __midas_mu1]) (`logitspe': _b[eq2: __midas_mu2]) ///
(`varlogitsen': (exp(_b[/lnsig1]))^2) (`varlogitspe': (exp(_b[/lnsig2]))^2) ///
(`covlogits': [exp(2*tanh(_b[/atsig12]))-1]/[exp(2*tanh(_b[/atsig12]))+1]*(exp(_b[/lnsig2]))*(exp(_b[/lnsig1]))),  ///
cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)
nois di ""
nois di ""
mat `Vhess' = r(V)
local coefnames: di "logitsen logitspe  varlogitsen varlogitspe covlogits"

return matrix Vhess = `Vhess', copy

tempname logitspe logitsen varlogitspe varlogitsen covlogits corrlogits bbb VVV
qui nlcom (`logitsen': _b[eq1: __midas_mu1]) (`logitspe': _b[eq2: __midas_mu2]) ///
(`varlogitsen': (exp(_b[/lnsig1]))^2) (`varlogitspe': (exp(_b[/lnsig2]))^2) ///
(`covlogits': [exp(2*tanh(_b[/atsig12]))-1]/[exp(2*tanh(_b[/atsig12]))+1]*(exp(_b[/lnsig2]))*(exp(_b[/lnsig1]))) ///
(`corrlogits': [exp(2*tanh(_b[/atsig12]))-1]/[exp(2*tanh(_b[/atsig12]))+1]*(exp(_b[/lnsig2]))*(exp(_b[/lnsig1])) / ///
sqrt((exp(_b[/lnsig1]))^2 * (exp(_b[/lnsig2]))^2)),  ///
cformat(%5.4f) pformat(%5.4f) sformat(%8.4f)
nois di ""
nois di ""
mat `bbb' = r(b)
mat `VVV' = r(V)
local coefnames: di "logitsen logitspe  varlogitsen varlogitspe covlogits corrlogits"
return scalar corrlogits = `bbb'[1,6]
return scalar covlogits = `bbb'[1,5]
mat colnames `bbb' = `coefnames'
mat colnames `VVV' = `coefnames'
mat rownames `VVV' = `coefnames'
return matrix b = `bbb', copy
return matrix V = `VVV', copy
cap restore
cap estimates restore __midas_modest

end

#delimit
program define halton_scorei, rclass;
cap preserve;
cap estimates restore __midas_modest;
use "c:\ado/personal/__midas_qrsim_data.dta", clear;
tempvar Sigma rho mu score_eq;
mat bb=e(b);
sort __midas_studyid;
qui gen double `mu'1 = bb[1,1];
qui gen double `mu'2 = bb[1,2];
qui gen double `Sigma'11 = bb[1,3];
qui gen double `Sigma'22 = bb[1,4];
qui gen double `Sigma'12 = bb[1,5];

qui gen double `rho' = `Sigma'12/sqrt(`Sigma'11*`Sigma'22);

qui gen double `score_eq'1 = 1/(1-`rho'^2)*((__midas_eta1-`mu'1)/(`Sigma'11)-(`rho'*(__midas_eta2-`mu'2))/sqrt(`Sigma'11*`Sigma'22));

qui gen double `score_eq'2 = 1/(1-`rho'^2)*((__midas_eta2-`mu'2)/(`Sigma'22)-(`rho'*(__midas_eta1-`mu'1))/sqrt(`Sigma'11*`Sigma'22));
qui {;
gen double `score_eq'3 = 1/(2*(`Sigma'11*`Sigma'22-`Sigma'12^2))*(-`Sigma'22 + `Sigma'22/
(`Sigma'11*`Sigma'22-`Sigma'12^2)*(`Sigma'22*(__midas_eta1-`mu'1)^2-2*`Sigma'12*(__midas_eta1-`mu'1)*(__midas_eta2 - `mu'2)
+ `Sigma'11*(__midas_eta2-`mu'2)^2)-(__midas_eta2-`mu'2)^2);

gen double `score_eq'4 = 1/(2*(`Sigma'11*`Sigma'22 - `Sigma'12^2))*(-`Sigma'11 + `Sigma'11/
(`Sigma'11*`Sigma'22-`Sigma'12^2)*(`Sigma'22*(__midas_eta1-`mu'1)^2-2*`Sigma'12*(__midas_eta1-`mu'1)*(__midas_eta2-`mu'2)
+`Sigma'11*(__midas_eta2-`mu'2)^2)-(__midas_eta1-`mu'1)^2);

gen double `score_eq'5 = (1/(`Sigma'11*`Sigma'22-`Sigma'12^2))*(`Sigma'12+
(__midas_eta1-`mu'1)*(__midas_eta2-`mu'2)-(`Sigma'12/(`Sigma'11*`Sigma'22-`Sigma'12^2))*(`Sigma'22*(__midas_eta1 -
`mu'1)^2-2*`Sigma'12*(__midas_eta1-`mu'1)*(__midas_eta2-`mu'2)+`Sigma'11*(__midas_eta2-`mu'2)^2));
};
 
mkmat __midas_studyid `score_eq'1-`score_eq'5, mat(scores) rownames(__midas_studylabel);
mat colnames scores = studdy g1 g2 g3 g4 g5;

return matrix scores= scores, copy;
cap restore;
cap estimates restore __midas_modest;
end;

