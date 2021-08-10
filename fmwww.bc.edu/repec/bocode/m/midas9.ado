cap program drop midas9
*! version 1.00 August 15, 2007
*! Ben A. Dwamena: bdwamena@umich.edu 

program define midas9, rclass byable(recall) sortpreserve
version 9
 #delimit;
 syntax varlist(min=4) [if] [in] , [ ID(varname) YEAR(varname)  EStimator(string)
 NIP(integer 15) LEVEL(integer 95) SCHEME (string) 
 QUALITab QUALIBar QLAB   RESults(string) TABle(string)   
 BIVBOX  CHIPlot GALB(string) CUM INF FUNnel PUBBias MAXbias QQplot(string)
 FORest(string) FORData  HETfor MScale(real 0.45) TEXTScale(real 0.50) 
 ROCPlane SROC1 SROC2
 FAGAN PDDAM(string) PRIOR(real 1.0) LRMatrix
 PLOTtype TESTlab(string asis) HSIZE(integer 6) VSIZE(integer 8)
 COVars ZCF(real 0.5)  *];
#delimit cr


qui {
preserve
marksample touse, novarlist
keep if `touse'
}

tokenize `varlist'
global tp `1'
global fp `2'    
global fn `3'
global tn `4'
macro shift 4
global varlist2 `*'


/* Check syntax */

if `level' < 10 | `level' > 99 {
di as error "level() must be between 10 and 99"
	exit 198
}


if ( "`pddam'" != "" | "`fagan'" != "" | "`forest'" != "" ///
| "`rocplane'" != "" | "`sroc1'" != "" | "`sroc2'" != "" ///
| "`hetfor'" != ""|"`results'" != "" | "`table'" != "" ///
| "`lrmatrix'" != "")  & ("`estimator'" == "" ) {
  	di as error "estimator() must be specified with this option"
	exit 198
}

if ("`qlab'" != "") & ("`qualitab'" == "" | "`qualibar'" == "") { 
 di as error "qlab and quality varlist must be used with qualibar or qualitab"
	exit 198

}		


/*Data Management*/

qui {	
global alph = (100-`level')/200
local numobs = _N
if ("`id'" != "" & "`year'" != "") {
local id `id'
local year `year'
format `id' %30s/* right aligned string */ 
egen StudyIds = concat(`id' `year'), p(" ") 
}
else gen str30 StudyIds = string(_n)
 
if "`scheme'" != ""{
 set scheme `scheme'      
  }
  if "`scheme'" == ""{
  set scheme s2color
  }

if `"`testlab'"' == "" {
local tlab  "" 
}
else if `"`testlab'"' != "" {
local tlab `"`testlab'"'
}
 
nois di ""
nois di ""
nois di ""

nois di as text "{title:META-ANALYTIC INTEGRATION OF DIAGNOSTIC TEST ACCURACY STUDIES}"    
/* QUALITY ASSESSMENT */
if "`qualibar'" == "qualibar" {
if "`qlab'" == "qlab" {
noisily quadas $varlist2,  labvar(`qlab') qgraph
}
else if "`qlab'" == "" {
noisily quadas $varlist2, qgraph 
}     
}

else  if "`qualitab'" == "qualitab" {
if "`qlab'" == "qlab" {
noisily quadas $varlist2, labvar(`qlab') qtable
}
else if "`qlab'" == "" {
noisily quadas $varlist2, qtable 
}
}

/* CALCULATE TOTALS */
tempvar sum sumtp sumfn sumtn sumfp sumtpfn sumtnfp sumsu
egen `sumtp' = total($tp)
egen `sumfn' = total($fn)
egen `sumtn' = total($tn)
egen `sumfp' = total($fp)
gen `sumtpfn' = `sumtp' + `sumfn'
gen `sumtnfp' = `sumtn' + `sumfp'
egen `sum' = rsum($tp $fn $tn $fp)
global prev = `sumtpfn'/(`sumtnfp' + `sumtpfn')
gen `sumsu' = sum(`sum')


/* Study Specific Adjustment for Zeros */
tempvar zc_tp zc_fn zc_fp zc_tn zero zc_sens zc_fpr zc_spec zc_tpr zc_fnr zc_tot 
gen `zc_tp' = $tp
gen `zc_fp' = $fp
gen `zc_fn' = $fn
gen `zc_tn' = $tn
gen `zero' = 0
replace `zero' = 1 if $tp == 0 | $fp == 0 | $fn == 0 | $tn == 0
replace `zc_tp' = `zc_tp' + `zcf' if `zero' == 1
replace `zc_fp' = `zc_fp' + `zcf' if `zero' == 1
replace `zc_fn' = `zc_fn' + `zcf' if `zero' == 1
replace `zc_tn' = `zc_tn' + `zcf' if `zero' == 1
gen `zc_sens' = `zc_tp'/(`zc_tp'+`zc_fn')    /* adjusted sensitivity */
gen `zc_tpr' = `zc_sens'             /* adjusted true pos rate */
gen `zc_fnr' = `zc_fn'/(`zc_tp'+`zc_fn')     /* adjusted false neg rate */  
gen `zc_spec' = `zc_tn'/(`zc_tn'+`zc_fp')    /* adjusted specificity */
gen `zc_fpr' = `zc_fp'/(`zc_tn'+`zc_fp')     /* adjusted false pos rate */
gen `zc_tot' = `zc_tp'+`zc_fp'+`zc_fn'+`zc_tn'   /* adjusted total */


/* STUDY-SPECIFIC Sensitivity (True Positive Rate)*/
tempvar sens senslo senshi sensse spec speclo spechi specse FPR          
gen `sens' = $tp/($tp+$fn)  
gen `senslo' = invbinomial($tp+$fn,$tp,$alph)   
gen `senshi' = invbinomial($tp+$fn,$tp,1-$alph)
gen `sensse' = (`senshi'-`senslo')/(2*invnorm(1-$alph)) 

/* STUDY-SPECIFIC Specificity (True Negative Rate) */

gen `spec' = $tn/($tn+$fp)      
gen `speclo' = invbinomial($tn+$fp,$tn,$alph)  
gen `spechi' = invbinomial($tn+$fp,$tn,1-$alph) 
gen `specse' =(`spechi'-`speclo')/(2*invnorm(1-$alph)) 
gen `FPR' = 1 - `spec'


/* Study Specific Positive Likelihood Ratio And Confidence Interval */
tempvar lrp llrp llrpvar llrpse lrplo lrphi lrpse 
gen `lrp' = `zc_sens'/`zc_fpr'
gen `llrp' = ln(`zc_sens'/`zc_fpr')
gen `llrpvar' = (1/`zc_tp')+(1/`zc_fp')-(1/(`zc_tp'+`zc_fn'))-(1/(`zc_fp'+`zc_tn'))
gen `llrpse' = sqrt((1/`zc_tp')+(1/`zc_fp')-(1/(`zc_tp'+`zc_fn'))-(1/(`zc_fp'+`zc_tn')))
gen `lrplo' = exp(`llrp' - invnorm(1-$alph)*`llrpse')
gen `lrphi' = exp(`llrp' + invnorm(1-$alph)*`llrpse')
gen `lrpse' = (`lrphi'-`lrplo')/(2*invnorm(1-$alph))

/* Study Specific Negative Likelihood Ratio And Confidence Interval */
tempvar lrn llrn llrnvar llrnse lrnlo lrnhi lrnse 

gen `lrn' = `zc_fnr'/`zc_spec'
gen `llrn' = ln(`zc_fnr'/`zc_spec')
gen `llrnvar' = (1/`zc_fn')+(1/`zc_tn')-(1/(`zc_tp'+`zc_fn'))-(1/(`zc_fp'+`zc_tn'))
gen `llrnse' = sqrt((1/`zc_fn')+(1/`zc_tn')-(1/(`zc_tp'+`zc_fn'))-(1/(`zc_fp'+`zc_tn')))
gen `lrnlo' = exp(`llrn' - invnorm(1-$alph)*`llrnse')
gen `lrnhi' = exp(`llrn' + invnorm(1-$alph)*`llrnse')
gen `lrnse' = (`lrnhi'-`lrnlo')/(2*invnorm(1-$alph))

/* Study Specific Diagnostic Odds Ratio And Confidence Interval */
tempvar dor dorvar dorse dorlo dorhi ldor ldorvar ldorse ldorlo ldorhi 
tempname ecf
scalar `ecf' = sqrt(3)/_pi
gen `dor' = (`zc_tp'*`zc_tn')/(`zc_fp'*`zc_fn')
gen `ldor' = ln(`dor')
gen `dorvar' = (1/`zc_fn')+(1/`zc_tn')+(1/`zc_fp')+(1/`zc_tp')
gen `ldorvar' = (1/`zc_fn')+(1/`zc_tn')+(1/`zc_fp')+(1/`zc_tp')
gen `ldorse' = sqrt(`ldorvar')
gen `ldorlo' = `ldor'-invnorm(1-$alph)*`ldorse'
gen `ldorhi' = `ldor'+invnorm(1-$alph)*`ldorse'
gen `dorlo' = exp(`ldor'-invnorm(1-$alph) * `ldorse')
gen `dorhi' = exp(`ldor'+invnorm(1-$alph) * `ldorse')
gen `dorse' = (`dorhi'-`dorlo')/(2*invnorm(1-$alph))
replace `ldorse' = `ldorse' * `ecf'
replace `ldorlo' = `ldorlo' * `ecf'
replace `ldorhi' = `ldorhi' * `ecf'


/* Study Specific Logit Transform of Sensitivity (TPR) and CI */
tempvar lsens lsensvar lsensse lsenslo lsenshi 
gen `lsens' = logit(`zc_sens')
gen `lsensvar' = 1/(`zc_sens'*(1-`zc_sens')*(`zc_tp'+`zc_fn'))
gen `lsensse' = sqrt(`lsensvar')
gen `lsenslo' = `lsens' - invnormal(1-$alph) * `lsensse'
gen `lsenshi' = `lsens' + invnormal(1-$alph) * `lsensse'

/* Study Specific Logit Transform of Specificity and CI */
tempvar lspec lspecvar lspecse lspeclo lspechi
gen `lspec' = logit(`zc_spec')
gen `lspecvar' = 1/(`zc_spec'*(1-`zc_spec')*(`zc_tn'+`zc_fp'))
gen `lspecse' = sqrt(`lspecvar')
gen `lspeclo' = `lspec' - invnormal(1-$alph) * `lspecse'
gen `lspechi' = `lspec' + invnormal(1-$alph) * `lspecse'


/* Study Specific Logit Transform of 1 - Specificity (FPR) and CI */
tempvar lfpr lfprvar lfprsd lfprlo lfprhi
gen `lfpr' = logit(`zc_fpr')
gen `lfprvar' = 1/(`zc_fpr'*(1-`zc_fpr')*(`zc_tn'+`zc_fp'))
gen `lfprsd' = sqrt(`lfprvar')
gen `lfprlo' = `lfpr' - invnormal(1-$alph) * `lfprsd'
gen `lfprhi' = `lfpr' + invnormal(1-$alph) * `lfprsd'
nois di ""


/*GALBRAITH PLOT FOR INVESTIGATING HETEROGENEITY AND SMALL STUDY BIAS*/     


if "`galb'" != ""{
if "`plottype'" != "" {
local plottype "Galbraith Plot"
}
else if "`plottype'" == "" {
local plottype " "
}

if "`galb'" == "ldor" {
nois midagalb `ldor' `ldorse'
}

else if "`galb'" == "lrp" {
nois midagalb `llrp' `llrpse'
}

else if "`galb'" == "lrn" {
nois midagalb `llrn' `llrnse'
}
else if "`galb'" == "tpr" {
nois midagalb `lsens' `lsensse'
}
else if "`galb'" == "tnr" {
nois midagalb `lspec' `lspecse'
}
}


/* BIVARIATE BOX PLOT */
if "`bivbox'"=="bivbox" {
tempvar boxvar1 boxvar2
gen `boxvar1' = `lsens'
label var `boxvar1' "LOGIT_SENS"
gen `boxvar2' = `lspec'
label var `boxvar2' "LOGIT_SPEC"
nois di as text "BIVARIATE BOXPLOT"
nois bvbox `boxvar1' `boxvar2' 
}
          
                                     
/* CHI PLOT */

if "`chiplot'" == "chiplot" {
tempvar cvar1 cvar2
gen `cvar1' = `lsens'
label var `cvar1' "LOGIT_SENS"
gen `cvar2' = `lspec'
label var `cvar2' "LOGIT_SPEC"
nois di as text "CHIPLOT"

nois midachi `cvar1' `cvar2'
}

/* CUMULATIVE META-ANALYSIS*/
	if "`cum'" == "cum" {
	tempvar var1 var1lo var1se var1hi var2 var2se var2lo var2hi
     gen `var1' = `sens'			
     gen `var1lo' = `senslo' 
     gen `var1se' = `sensse' 
     gen `var1hi' = `senshi' 
     gen `var2' = `spec'			
     gen `var2lo' = `speclo' 
     gen `var2hi' = `spechi'
     gen `var2se' = `specse' 

     
	tempvar cumvar1 cumvar1se cumvar2 cumvar2se     
     local obs=_N     
     gen `cumvar1'=`var1' in 1
     gen `cumvar1se' = `var1se' in 1
     gen `cumvar2' = `var2' in 1
     gen `cumvar2se' = `var2se' in 1
     
	local i 2

     while `i'<=`obs' {
     metan `var1' `var1lo' `var1hi' in 1/`i', random nograph
     replace `cumvar1' = r(ES) in `i'  
     replace `cumvar1se' = r(seES) in `i'
     metan `var2' `var2lo' `var2hi' in 1/`i', random nograph
     replace `cumvar2' = r(ES) in `i'  
     replace `cumvar2se' = r(seES) in `i'
     local i=`i'+1
      }     
    
 	tempname  obs1 stvar1 stvar1se stvar2 stvar2 stvar2se 
	gen `stvar1' = `cumvar1'
	gen `stvar1se' = `cumvar1se'
	gen `stvar2' = `cumvar2'
	gen `stvar2se' = `cumvar2se'
	gen `obs1' = _n 
	local xmax = `obs1'[_N]
	
	set graphics off      

	#delimit;
	serrbar `stvar1' `stvar1se' `obs1', scale(2) ylab(, format(%9.2f) angle(hor) labs(*.50)) 
	xtitle("StudyNo", size(*.75)) ytitle("Sensitivity", size(*0.75)) name(cumplot1, replace)
	xlab(1(1)`xmax',  labs(*.50) format(%9.0f) angle(hor));
	#delimit cr 

	#delimit;
	serrbar `stvar2' `stvar2se' `obs1', scale(2) ylab(, format(%9.2f) angle(hor) labs(*.50)) 
	xtitle("StudyNo", size(*.75)) ytitle("Specificity", size(*0.75)) name(cumplot2, replace)
	xlab(1(1)`xmax', labs(*.50) format(%9.0f) angle(hor)) ;
	#delimit cr

	set graphics on

	nois graph combine cumplot1 cumplot2, cols(1) subtitle("Cumulative Analysis By Publication Year", size(*0.75))
	}


/* INFLUENCE ANALYSIS */
   	if  "`inf'" =="inf" {
   	tempvar var1 var1lo var1hi var2 var2lo var2hi
     gen `var1' = `sens'
     gen `var1lo' = `senslo' 
     gen `var1hi' = `senshi' 
     gen `var2' = `spec'
     gen `var2lo' = `speclo' 
     gen `var2hi' = `spechi'

   	tempvar so 
   	qui gen `so' = _n
   	sort `so'

* Meta-analysis estimate omiting one study each step
    
   tempvar istvar1 istvar1se istvar2 istvar2se 
      local n = _N
      gen `istvar1' = .
      gen `istvar1se' = .
      gen `istvar2' = .
      gen `istvar2se' = .
           
    local i = 1
    tempvar s
    gen `s' = _n
    while (`i' <= `n') { 
    sort `so'
    metan `var1' `var1lo' `var1hi' if `s' != `i', random nograph
     replace `istvar1' = r(ES) in `i'  
     replace `istvar1se' = r(seES) in `i'
     
     metan `var2' `var2lo' `var2hi' if `s' != `i', random nograph
     replace `istvar2' = r(ES) in `i' 
     replace `istvar2se' = r(seES) in `i'
     
     local i=`i'+1
   }
       
   
	tempvar obs1 studyvar1 studyvar2 studyvar1se studyvar2se 
 
	gen `studyvar2' = `istvar2'
	gen `studyvar2se' = `istvar2se'
	gen `studyvar1' = `istvar1'
	gen `studyvar1se' = `istvar1se'
		
	tempvar  obs1 		      
	gen `obs1' = _n 
	local xmax = `obs1'[_N]
	set graphics off 
     
	#delimit;
	serrbar `studyvar1' `studyvar1se' `obs1', scale(2) ylab(, format(%9.2f) angle(hor) labs(*.75)) 
	xsc(r(1 `xmax')) xlab(1(1)`xmax', labs(*.50) format(%9.0f) angle(hor))
	ytitle("Sensitivity", size(*0.75)) xtitle("StudyNo", size(*.75)) name(infplot1, replace);
	#delimit cr 


	#delimit;
	serrbar `studyvar2' `studyvar2se' `obs1', scale(2) ylab(, format(%9.2f) angle(hor) labs(*.75)) 
	xsc(r(1 `xmax')) xlab(1(1)`xmax', labs(*.50) format(%9.0f) angle(hor)) 
	ytitle("Specificity", size(*0.75)) xtitle("StudyNo", size(*.75)) name(infplot2, replace);
	#delimit cr

	set graphics on

	nois graph combine infplot1 infplot2, cols(1) title("Influence Analysis", size(*0.75))

	} 


/* PUBLICATION BIAS */
 
 if "`pubbias'" != "" | "`maxbias'" != "" | "`funnel'" != "" { 
local ptitle: di "Log Odds Ratio versus 1/sqrt(Effective Sample Size)(Deeks)"
tempvar  n1 n2 nt ESS zero lthetai thetai sethetai xb yb stpred logn pubwgt
gen `n1' = `zc_tp' + `zc_fn'  
gen `n2' = `zc_tn' + `zc_fp'
gen `nt' =  `n1' + `n2'
gen `ESS' =(4 * `n1' * `n2')/(`n1' + `n2')
gen `lthetai' = log((`zc_tp' * `zc_tn')/(`zc_fp' * `zc_fn')) 
gen `thetai' =.
gen `sethetai' =.
gen `pubwgt' =.
gen `xb' =.
gen `yb' =.

if "`pubbias'" == "pubbias"  {
nois di " "
nois di " "
nois di as text "{title:STATISTICAL TESTS FOR SMALL STUDY EFFECTS/PUBLICATION BIAS}"
replace `thetai'=`lthetai' 
replace `sethetai' = sqrt(`ESS') 
replace `xb'=1/sqrt(`ESS')
label var `xb' "1/root(ESS)"
replace `yb' = `thetai'
label var `yb' "Diagnostic Odds Ratio"
replace `pubwgt' = `ESS'
nois di " "
nois di " "
nois di " "
sum `xb', detail
local xbmax=r(max)
sum `yb', detail
local ybmax=r(max)
local ybmin=r(min)
mylabels 1 10 100 1000, myscale(log(@)) local(ylab) 
regress  `yb' `xb'[weight=`pubwgt'], level(`level')
estimates store stbias
scalar intercept = _b[_cons]
scalar se_intercept = _se[_cons]
scalar rmse = e(rmse)
scalar df = e(df_r)
scalar p = 2*ttail(e(df_r), abs(return(score_bc)/return(score_se)))
nois matrix define vcov = e(V)
nois matrix define b = e(b)
matrix colnames b =     Bias Intercept
matrix rownames vcov =  Bias Intercept 
matrix colnames vcov =  Bias Intercept 
nois matrix post b vcov, dep(yb) dof(`e(df_r)') obs(`e(N)')
nois ereturn display, level(`level')
estimates restore stbias
predict `stpred'
local stline "(line `stpred' `xb' ,  clpattern(dash) clwidth(vthin))"
#delimit;
nois twoway `stline'(scatter `yb' `xb' , sort ms(O) `options'), 
legend(label(2 "Study") label(1 "Regression" "Line") order(2 1) pos(2) col(1) size(*.75)) 
 xlab(, angle(horizontal) labsize(*`textscale') format(%7.2f)) 
ylab( `ylab', labsize(*`textscale')) title("`plottype' `tlab'", size(*0.75)) 
 xsize(`hsize') plotregion(margin(zero)) ytitle("Diagnostic Odds Ratio") 
subtitle(`ptitle', size(*.65)) ;
#delimit cr
}
 
if "`maxbias'" == "maxbias" {
nois di " "
nois di " "
nois di as text "{title: WORST CASE SENSITIVITY ANALYSIS FOR SMALL STUDY EFFECTS/PUBLICATION BIAS}"

replace `sethetai' = sqrt(`ESS') 
nois copas `lthetai' `sethetai'
}

if "`funnel'" == "funnel" {

replace `thetai'=`lthetai' 
replace `sethetai' = 1/sqrt(`ESS') 
replace `pubwgt' = `ESS'
label var `thetai' "Log Odds Ratio "
nois di " "
nois di " "
nois di " "
if "`plottype'" != "" {
local plottype "Funnel Plot"
}
else if "`plottype'" == "" {
local plottype " "
}

mylabels 1 10 100 1000, myscale(log(@)) local(xlab) 
twoway (scatter `sethetai' `thetai', legend(off) ms(O)), yscale(rev) ylab(,  angle(horizontal) format(%7.2f) labsize(*`textscale')) title("`plottype' `tlab'", size(*.75)) /*
*/ ytitle("Precision", size(*.75)) xtitle("Log Odds Ratio", size(*.75)) plotregion(margin(zero)) xlab(`xlab', format(%2.0f) labsize(*`textscale'))    
  
  	drop if missing(`sethetai') 
   } 
}

/*NORMAL QUANTILE PLOT FOR INVESTIGATING NORMALITY ASSUMPTION, HETEROGENEITY AND PUBLICATION SELECTION BIAS*/     
if "`qqplot'" != ""{
if "`plottype'" != "" {
local plottype "Normal Quantile Plot"
}
else if "`plottype'" == "" {
local plottype " "
}

if "`qqplot'" == "ldor" {
nois metanorm `ldor' `ldorse'
}

else if "`qqplot'" == "lrp" {
nois metanorm `llrp' `llrpse'
}

else if "`qqplot'" == "lrn" {
nois metanorm `llrn' `llrnse'
}
else if "`qqplot'" == "tpr" {
nois metanorm `lsens' `lsensse'
}
else if "`qqplot'" == "tnr" {
nois metanorm `lspec' `lspecse'
}
}


if ("`qualitab'`qualibar'`qqplot'`pubbias'`bivbox'`chiplot'" == "") /// 
& ("`galb'`maxbias'`funnel'`cum'`inf'" == "") {


/*  MODEL SPECIFICATION AND ESTIMATION   */
if "`estimator'" == "g" {
bbrre tp fp fn tn
}
else if "`estimator'" == "x" {
version 10
xtbbrre tp fp fn tn, `nip'
}
version 9
*saving transformed estimates
return scalar mtpr = r(mtpr)
return scalar mtprlo = r(mtprlo) 
return scalar mtprhi = r(mtprhi)
return scalar mtprse = r(mtprse)

return scalar mtnr = r(mtnr)
return scalar mtnrlo = r(mtnrlo)
return scalar mtnrhi = r(mtnrhi)
return scalar mtnrse = r(mtnrse)

return scalar mldor =  r(mldor)
return scalar mldorlo = r(mldorlo)
return scalar mldorhi = r(mldorhi)
return scalar mldorse = r(mldorse)

return scalar mdor = r(mdor)
return scalar mdorlo = r(mdorlo)
return scalar mdorhi = r(mdorhi)
return scalar mdorse = r(mdorse)

return scalar mlrp = r(mlrp)
return scalar mlrplo = r(mlrplo)
return scalar mlrphi = r(mlrphi)
return scalar mlrpse = r(mlrpse)

return scalar mlrn = r(mlrn)
return scalar mlrnlo = r(mlrnlo)
return scalar mlrnhi = r(mlrnhi)
return scalar mlrnse = r(mlrnse)

return scalar  reffs1 = r(mreffs1)
return scalar  reffs1lo = r(mreffs1lo)
return scalar  reffs1hi = r(mreffs1hi)
return scalar  reffs1se = r(mreffs1se)


return scalar  reffs2 = r(mreffs2)
return scalar  reffs2lo = r(mreffs2lo)
return scalar  reffs2hi = r(mreffs2hi)
return scalar  reffs2se = r(mreffs2se)


return scalar  rho = r(mrho)
return scalar  rholo = r(mrholo)
return scalar  rhohi = r(mrhohi)
return scalar  covar = r(mcovar)

return scalar fsens = r(fsens)
return scalar fspec = r(fspec)
return scalar fldor = r(fldor)
return scalar fdor =  r(fdor)
return scalar flrp =  r(flrp)
return scalar flrn =  r(flrn)

return scalar Islrt = r(Islrt)
return scalar Islrtlo = r(Islrtlo)
return scalar Islrthi = r(Islrthi)



*SUMMARY ESTIMATES
local cov01 = r(covsnsp)
local mtpr = r(mtpr)
local mtprlo = r(mtprlo) 
local mtprhi = r(mtprhi)
local mtprse = r(mtprse)

local mtnr = r(mtnr)
local mtnrlo = r(mtnrlo)
local mtnrhi = r(mtnrhi)
local mtnrse = r(mtnrse)

local mldor =  r(mldor)
local mldorlo = r(mldorlo)
local mldorhi = r(mldorhi)
local mldorse = r(mldorse)

local mdor = r(mdor)
local mdorlo = r(mdorlo)
local mdorhi = r(mdorhi)
local mdorse = r(mdorse)

local mlrp = r(mlrp)
local mlrplo = r(mlrplo)
local mlrphi = r(mlrphi)
local mlrpse = r(mlrpse)

local mlrn = r(mlrn)
local mlrnlo = r(mlrnlo)
local mlrnhi = r(mlrnhi)
local mlrnse = r(mlrnse)

local reffs1 = r(mreffs1)
local reffs1lo = r(mreffs1lo)
local reffs1hi = r(mreffs1hi)
local reffs1se = r(mreffs1se)


local reffs2 = r(mreffs2)
local reffs2lo = r(mreffs2lo)
local reffs2hi = r(mreffs2hi)
local reffs2se = r(mreffs2se)


local rho = r(mrho)
local rholo = r(mrholo)
local rhohi = r(mrhohi)
local covar = r(mcovar)

global fsens = r(fsens)
global fspec = r(fspec)
global fldor = r(fldor)
global fdor =  r(fdor)
global flrp =  r(flrp)
global flrn =  r(flrn)

tempname sp sn spse snse lrtchi lrtpchi lrtdf 
tempname Islrt Islrtlo Islrthi
scalar `sp' = r(sp)
scalar `spse' = r(spse)
scalar `sn' = r(sn)
scalar `snse' = r(snse)
scalar `lrtchi'  = r(lrtchi)
scalar `lrtpchi' = r(lrtpchi)
scalar `lrtdf' = r(lrtdf)
scalar `Islrt' = r(Islrt)
scalar `Islrtlo' = r(Islrtlo)
scalar `Islrthi' = r(Islrthi)

 
*Multi-column Forest Plot

if "`hetfor'" == "hetfor" {
set graphics off
qui {
tempvar obs wgt1 wgt2 wgt3 wgt4 wgt5
gen `obs' = _n 
local mscale2 = .25 * `mscale'
count
local max1 = r(N)
label value `obs' obs
forval i = 1/`max1'{
local value = `"`value' `i'"'
label define obs `i' "`=StudyIds[`i']'", modify
}
gen line=_n
gen textx=0
local n1=_N+2
local n2=_N+1
local ylabopt "labsize(*.50) tl(*0) labgap(*5)"

local xlab1 "xlab(minmax, format(%5.1f) labsize(*.50))"
local xlab2 "xlab(minmax, format(%5.1f) labsize(*.50))xsc(log)"

gen `wgt1' = 1/(`sensse' *`sensse')
#delimit ;
twoway (rspike `senslo' `senshi' `obs', ylabel(`"`value'"', valuelabel labsize(*.50) tl(*0) angle(360)) 
hor s(i) lpat(blank)  `xlab1')(scatter `obs' `sens' [aw = `wgt1'], ms(i) msize(*`mscale2') mcolor(gs10)), 
legend(off) xtitle("", size(*.5)) yscale(noline) xscale(off fill) plotregion(style(none)) ytitle("", size(*.5)) 
title("StudyId", size(*.5) pos(1)) fxsize(0) name(mplot, replace);
#delimit cr

#delimit ;
twoway (rspike `senslo' `senshi' `obs', ylabel(`"`value'"', nolabel 
`ylabopt' angle(360)) hor s(i) blpattern(solid) blwidth(vthin) blcolor(black) `xlab1')
(scatter `obs' `sens' [aw = `wgt1'], ms(O) msize(*`mscale2') mcolor(gs10))
(scatter `obs' `sens', ms(o) msize(*`mscale') mcolor(black)), xline(`mtpr', lpattern(dash))
ytitle("", size(*.5)) legend(off) xtitle("", size(*.5)) title("Sensitivity", size(*.5) 
justification(left)) name(mplot1, replace) ;
#delimit cr

gen `wgt2' = 1/(`specse'*`specse')

#delimit ;
twoway (rspike `speclo' `spechi' `obs', ylabel(`"`value'"', nolabel 
`ylabopt' angle(360)) hor s(i) blpattern(solid) blwidth(vthin) blcolor(black) `xlab1')
(scatter `obs' `spec' [aw = `wgt2'], ms(O) msize(*`mscale2') mcolor(gs10))
(scatter `obs' `spec', ms(o) msize(*`mscale') mcolor(black)), legend(off) 
xtitle("", size(*.5)) ytitle("", size(*.5))  title("Specificity", size(*.5) 
justification(left)) nodraw xline(`mtnr', lpattern(dash)) name(mplot2, replace) ;
#delimit cr

gen `wgt3' = 1/(`lrpse' *`lrpse')

#delimit ;
twoway (rspike `lrplo' `lrphi' `obs', ylabel(`"`value'"', nolabel `ylabopt' angle(360)) 
hor s(i) blpattern(solid) blwidth(vthin) blcolor(black) `xlab2')(scatter `obs' `lrp' [aw = `wgt3'], 
ms(O) msize(*`mscale2') mcolor(gs10))(scatter `obs' `lrp', ms(o) msize(*`mscale') mcolor(black)), 
nodraw legend(off) title("Positive Likelihood Ratio", size(*.5) 
justification(left)) xline(`mlrp', lpattern(dash)) ytitle("", size(*.5)) 
xtitle("", size(*.5)) name(mplot3, replace) ;
#delimit cr

gen `wgt4' = 1/(`lrnse' *`lrnse')


#delimit ;
twoway (rspike `lrnlo' `lrnhi' `obs', ylabel(`"`value'"', nolabel `ylabopt' angle(360)) 
hor s(i) blpattern(solid) blwidth(vthin) blcolor(black) `xlab1')(scatter `obs' `lrn' [aw = `wgt4'], 
ms(O) msize(*`mscale2') mcolor(gs10))(scatter `obs' `lrn', ms(o) msize(*`mscale') mcolor(black)) 
, nodraw legend(off) xtitle("", size(*.5)) ytitle("", size(*.5))  
title("Negative Likelihood Ratio", size(*.5) justification(left)) xline(`mlrn', lpattern(dash)) 
name(mplot4, replace);
#delimit cr

gen `wgt5' = 1/(`dorse' *`dorse')

#delimit ;
twoway (rspike `dorlo' `dorhi' `obs', ylabel(`"`value'"', nolabel `ylabopt' angle(360)) 
hor s(i) blpattern(solid) blwidth(vthin) blcolor(black) `xlab2')(scatter `obs' `dor' [aw = `wgt5'], 
ms(O) msize(*`mscale2') mcolor(gs10))(scatter `obs' `dor', ms(o) msize(*`mscale') mcolor(black)), 
nodraw legend(off) title("Diagnostic Odds Ratio", size(*.5) justification(left)) 
xtitle("", size(*.5)) ytitle("", size(*.5)) xline(`mdor', lpattern(dash)) name(mplot5, replace) ;
#delimit cr
}
set graphics on
nois graph combine mplot mplot1 mplot2 mplot3 mplot4 mplot5, row(1)                                                                                                                   
                                                                                                               
}
 
    
/* HETEROGENEITY: Sensitivity */ 

tempvar devsens Qsens
tempname  Qsensdf  prsens Isqsens Isqsenslo Isqsenshi
gen `devsens' = ((`sens' - $fsens)^2)/(($fsens*(1-$fsens))/($tp+$fn))
egen `Qsens' = total(`devsens')
scalar `Qsensdf' = `numobs' - 1
scalar `prsens' = chi2tail(`Qsensdf',`Qsens')
homogeni `Qsens' `Qsensdf'
scalar `Isqsens' = r(Isq)
scalar `Isqsenslo' = r(Isqlo)
scalar `Isqsenshi' = r(Isqhi)


/* HETEROGENEITY: Specificity  */

tempvar devspec Qspec
tempname  Qspecdf  prspec Isqspec Isqspeclo Isqspechi
gen `devspec' = ((`spec' - $fspec)^2)/(($fspec*(1-$fspec))/($tn+$fp))
egen `Qspec' = total(`devspec')
scalar `Qspecdf' = `numobs' - 1

scalar `prspec' = chi2tail(`Qspecdf',`Qspec')
homogeni `Qspec' `Qspecdf'
scalar `Isqspec' = r(Isq)
scalar `Isqspeclo' = r(Isqlo)
scalar `Isqspechi' = r(Isqhi)


/* HETEROGENEITY: Positive Likelihood Ratio */

tempvar Qlrp devlrp
tempname prlrp Qlrpdf Isqlrp Isqlrplo Isqlrphi 
gen `devlrp' = ((`llrp' - ln($flrp))^2)/`llrpvar'
egen `Qlrp' = total(`devlrp')
scalar `Qlrpdf' = `numobs' - 1
scalar `prlrp' = chi2tail(`Qlrpdf',`Qlrp')
homogeni `Qlrp' `Qlrpdf'
scalar `Isqlrp' = r(Isqlo)
scalar `Isqlrplo' = r(Isqlo)
scalar `Isqlrphi' = r(Isqhi)


/* HETEROGENEITY:  Negative Likelihood Ratio */

tempvar Qlrn devlrn
tempname prlrn Qlrndf Isqlrn Isqlrnlo Isqlrnhi 

gen `devlrn' = ((`llrn' - ln($flrn))^2)/`llrnvar'
egen `Qlrn' = total(`devlrn')
scalar `Qlrndf' = `numobs' - 1
scalar `prlrn' = chi2tail(`Qlrndf',`Qlrn')
homogeni `Qlrn' `Qlrndf'
scalar `Isqlrn' = r(Isq)
scalar `Isqlrnlo' = r(Isqlo)
scalar `Isqlrnhi' = r(Isqhi)


/*  HETEROGENEITY: Diagnostic Odds Ratio */

tempvar Qldor devldor
tempname prldor Qldordf Isqldor Isqldorlo Isqldorhi
gen `devldor' = (`ldor' - $fldor)^2/`ldorvar'
egen `Qldor' = total(`devldor')
scalar `Qldordf' = `numobs' - 1
scalar `prldor' = chi2tail(`Qldordf',`Qldor')

homogeni `Qldor' `Qldordf'
scalar `Isqldor' = r(Isq)
scalar `Isqldorlo' = r(Isqlo)
scalar `Isqldorhi' = r(Isqhi)


tempvar Qdor devdor
tempname prdor Qdordf Isqdor Isqdorlo Isqdorhi
gen `devdor' = exp(((`ldor' - ln($fdor))^2)/`ldorvar')
egen `Qdor' = total(`devdor')
scalar `Qdordf' = `numobs' - 1
scalar `prdor' = chi2tail(`Qdordf',`Qdor')

homogeni `Qdor' `Qdordf'
scalar `Isqdor' = r(Isq)
scalar `Isqdorlo' = r(Isqlo)
scalar `Isqdorhi' = r(Isqhi)

tempvar var1 var2 var1se var2se var1lo var2lo var1hi var2hi
tempname Isq1 Isq1lo Isq1hi Isq2 Isq2lo Isq2hi 
tempname Qvar1 Qvar1df pr1 Qvar2  Qvar2df pr2
     
     gen `var1' = .
     gen `var1se' = .
     gen `var1lo' = . 
     gen `var1hi' = . 
     gen `var2' = .
     gen `var2se' = .
     gen `var2lo' = .
     gen `var2hi' = .
     
if ("`forest'" == "dss" | "`table'" == "dss" | "`rocplane'" == "rocplane" )  {
     	
     replace `var1' = `sens'
     replace `var1se' = `sensse'
     replace `var1lo' = `senslo' 
     replace `var1hi' = `senshi' 
     replace `var2' = `spec'
     replace `var2se' = `specse'
     replace `var2lo' = `speclo' 
     replace `var2hi' = `spechi'
     
     local mvar1 = `mtpr'
     local mvar1lo = `mtprlo'
     local mvar1hi = `mtprhi'
     local mvar2 = `mtnr'
     local mvar2lo = `mtnrlo'
     local mvar2hi = `mtnrhi'
     
     scalar `Isq1' = `Isqsens'
     scalar `Isq1lo' = `Isqsenslo'
     scalar `Isq1hi' = `Isqsenshi'
     scalar `Isq2' = `Isqspec'
     scalar `Isq2lo' = `Isqspeclo'
     scalar `Isq2hi' = `Isqspechi'
	scalar `Qvar1' = `Qsens' 
	scalar `Qvar1df' = `Qsensdf' 
	scalar `pr1' = `prsens' 
	scalar `Qvar2' = `Qspec'  
	scalar `Qvar2df' = `Qspecdf' 
	scalar `pr2' = `prspec'

local note1a: di " "%4.2f `mvar1' " [" %4.2f `mvar1lo' " - " %4.2f `mvar1hi' "]"
local note1b: di "Q ="%6.2f `Qvar1' ", df = " %3.2f `Qvar1df' ", p = "%5.2f `pr1' "
local note1c: di "I2 = "%3.2f `Isq1' " [" %3.2f `Isq1lo' " - " %3.2f `Isq1hi' "]"               
local note2a: di " "%4.2f `mvar2' " [" %4.2f `mvar2lo' " - " %4.2f `mvar2hi' "]"
local note2b: di "Q ="%6.2f `Qvar2' ", df = " %3.2f `Qvar2df' ", p = "%5.2f `pr2' "
local note2c: di "I2 = "%3.2f `Isq2' " [" %3.2f `Isq2lo' " - " %3.2f `Isq2hi' "]" 


     
     local gtitle1 "SENSITIVITY"
     local gtitle2 "SPECIFICITY"
     }
     

if ("`forest'" == "dlr" | "`table'" == "dlr" ) {
     	
     replace `var1' = `lrp'
     replace `var1se' = `lrpse'
     replace `var1lo' = `lrplo' 
     replace `var1hi' = `lrphi' 
     replace `var2' = `lrn'
     replace `var2se' = `lrnse'
     replace `var2lo' = `lrnlo' 
     replace `var2hi' = `lrnhi'
     
     local mvar1 = `mlrp'
     local mvar1lo = `mlrplo'
     local mvar1hi = `mlrphi'
     local mvar2 = `mlrn'
     local mvar2lo = `mlrnlo'
     local mvar2hi = `mlrnhi'
     
     scalar `Isq1' = `Isqlrp'
     scalar `Isq1lo' = `Isqlrplo'
     scalar `Isq1hi' = `Isqlrphi'
     scalar `Isq2' = `Isqlrn'
     scalar `Isq2lo' = `Isqlrnlo'
     scalar `Isq2hi' = `Isqlrnhi'
     
          scalar `Qvar1' = `Qlrp' 
	scalar `Qvar1df' = `Qlrpdf' 
	scalar `pr1' = `prlrp' 
	scalar `Qvar2' = `Qlrn'  
	scalar `Qvar2df' = `Qlrndf' 
	scalar `pr2' = `prlrn'
	
	local note1a: di " "%4.2f `mvar1' " [" %4.2f `mvar1lo' " - " %4.2f `mvar1hi' "]"
local note1b: di "Q ="%6.2f `Qvar1' ", df = " %3.2f `Qvar1df' ", p = "%5.2f `pr1' "
local note1c: di "I2 = "%3.2f `Isq1' " [" %3.2f `Isq1lo' " - " %3.2f `Isq1hi' "]"               
local note2a: di " "%4.2f `mvar2' " [" %4.2f `mvar2lo' " - " %4.2f `mvar2hi' "]"
local note2b: di "Q ="%6.2f `Qvar2' ", df = " %3.2f `Qvar2df' ", p = "%5.2f `pr2' "
local note2c: di "I2 = "%3.2f `Isq2' " [" %3.2f `Isq2lo' " - " %3.2f `Isq2hi' "]" 

     
     local gtitle1 "DLR POSITIVE"
     local gtitle2 "DLR NEGATIVE"
     }
     
if ("`forest'" == "dlor" | "`table'" == "dlor") {
     	
     replace `var1' = `ldor'
     replace `var1se' = `ldorse'
     replace `var1lo' = `ldorlo' 
     replace `var1hi' = `ldor' 
     replace `var2' = `dor'
     replace `var2se' = `dorse'
     replace `var2lo' = `dorlo' 
     replace `var2hi' = `dorhi'
     
     local mvar1 = `mldor'
     local mvar1lo = `mldorlo'
     local mvar1hi = `mldorhi'
     local mvar2 = `mdor'
     local mvar2lo = `mdorlo'
     local mvar2hi = `mdorhi'
     
     scalar `Isq1' = `Isqldor'
     scalar `Isq1lo' = `Isqldorlo'
     scalar `Isq1hi' = `Isqldorhi'
     scalar `Isq2' = `Isqdor'
     scalar `Isq2lo' = `Isqdorlo'
     scalar `Isq2hi' = `Isqdorhi'
     scalar `Qvar1' = `Qldor' 
     scalar `Qvar1df' = `Qldordf' 
     scalar `pr1' = `prldor' 
     scalar `Qvar2' = `Qdor'  
     scalar `Qvar2df' = `Qdordf' 
     scalar `pr2' = `prdor'

local note1a: di " "%4.2f `mvar1' " [" %4.2f `mvar1lo' " - " %4.2f `mvar1hi' "]"
local note1b: di "Q ="%6.2f `Qvar1' ", df = " %3.2f `Qvar1df' ", p = "%5.2f `pr1' "
local note1c: di "I2 = "%3.2f `Isq1' " [" %3.2f `Isq1lo' " - " %3.2f `Isq1hi' "]"               
local note2a: di " "%4.2f `mvar2' " [" %4.2f `mvar2lo' " - " %4.2f `mvar2hi' "]"
local note2b: di "Q ="%6.2f `Qvar2' ", df = " %3.2f `Qvar2df' ", p = "%5.2f `pr2' "
local note2c: di "I2 = "%3.2f `Isq2' " [" %3.2f `Isq2lo' " - " %3.2f `Isq2hi' "]" 

     local gtitle1 "DIAGNOSTIC SCORE"
     local gtitle2 "ODDS RATIO"
     } 
     
      
     
 if "`table'" != "" {
nois di ""
nois di ""
nois di as text "{title: STUDY-SPECIFIC TEST PERFORMANCE ESTIMATES}"
nois di " "
nois di " "
sum `var1', detail
local n1=r(N)
nois di as text "`gtitle1'"
nois di " "
nois di as text"{hline 65}"
nois di in gr _col(2) "Study" _col(20) "{c |}" _col(24) "Estimate" _col(39) "[95%  Conf.  Interval]"
nois di as text"{hline 19}{c +}{hline 47}"
local i = 1
while `i' <= `n1' {            
local a1 = StudyIds in `i' 
local b1 = `var1' in `i'
local c1 = `var1lo'  in `i'
local d1 = `var1hi'  in `i'
nois di in gr _col(2) %6.2f "`a1'" _col(20) in gr "{c |}" in ye _col(24) %6.2f `b1' _col(39) %6.2f `c1' _col(49) %6.2f `d1'
local i=`i'+1
}
nois di as text"{hline 65}"
nois di in gr _col(2) "Combined" _col(20) in gr "{c |}" in ye _col(24) %6.2f `mvar1' _col(39) %6.2f `mvar1lo' _col(49) %6.2f `mvar1hi'
nois di as text"{hline 19}{c BT}{hline 47}"
nois di ""
nois di as txt "Heterogeneity (Chi-square): Q = "as result %5.2f `Qvar1' ///
as txt ", df = "as result %3.2f `Qvar1df' as txt", p = "as result %5.2f `pr1'
nois di " "
nois di as txt"Inconsistency (I-square): I2 = "as res %3.2f `Isq1' _c
nois di as txt", 95% CI = ["as res %3.2f `Isq1lo'                _c
nois di as txt" - "as res %3.2f `Isq1hi' as txt"]"               _n
nois di " "
nois di ""
nois di as text "`gtitle2'"
nois di " "
nois di as text"{hline 65}"
nois di in gr _col(2) "Study" _col(20) "{c |}" _col(24) "Estimate" _col(39) "[95%  Conf.  Interval]"
nois di as text"{hline 19}{c +}{hline 47}"
local i = 1
while `i' <= `n1' {
local a2 = StudyIds in `i' 
local b2 = `var2' in `i'
local c2 = `var2lo'  in `i'
local d2 = `var2hi'  in `i'
nois di in gr _col(2) %6.2f "`a2'" _col(20) in gr "{c |}" in ye _col(24) %6.2f `b2' _col(39) %6.2f `c2' _col(49) %6.2f `d2'
local i=`i'+1
}
nois di as text"{hline 65}" 
nois di in gr _col(2) "Combined" _col(20) in gr "{c |}" in ye _col(24) %6.2f `mvar2' _col(39) %6.2f `mvar2lo' _col(49) %6.2f `mvar2hi'
nois di as text"{hline 19}{c BT}{hline 47}"
nois di ""
nois di as txt "Heterogeneity (Chi-square): Q = " as result %5.2f `Qvar2' ///
as txt ", df =" as result %3.2f `Qvar2df' as txt", p ="as result %5.2f `pr2'
nois di " "
nois di as txt "Inconsistency (I-square): I2 = "as res %3.2f `Isq2' _c
nois di as txt ", 95% CI = ["as res %3.2f `Isq2lo'                _c
nois di as txt " - "as res %3.2f `Isq2hi' as txt"]"               _n
nois di " "
nois di "" 
}


/*ROC PLANE*/
if "`rocplane'" == "rocplane" {
local msens = `mvar1'
local msenslo = `mvar1lo'
local msenshi= `mvar1hi'
local mspec = 1-`mvar2'
local mspeclo = 1-`mvar2hi'
local mspechi = 1-`mvar2lo'
nois twoway (pci `msens' 0 `msens' 1, lpat(longdash) lwidth(vthin)) /*
*/ (pci  0 `mspec' 1 `mspec' , lpat(shortdash) lwidth(vthin))(scatter `sens' `FPR', /*
*/ sort msymbol(O) mcolor(black)), ytitle("Sensitivity", size(*.90)) /*
*/ xtitle("1-Specificity", size(*.90)) yscale(range(0 1)) /*
*/ yline(`msenslo' `msenshi', lpat(longdash) lwidth(vthin))/*
*/ xline(`mspeclo' `mspechi', lpat(shortdash) lwidth(medthin)) ylabel( 0(.2)1, nogrid angle(horizontal) format(%7.2f)) /*
*/ xscale(range(0 1)) xlabel(0(.2)1, nogrid format(%7.2f)) title(ROC Plane, size(*.5)) /*
*/ legend(order(1 "Sensitivity" "`note1a'" "`note1b'" "`note1c'" 2 "Specificity" "`note2a'" "`note2b'" "`note2c'") /*
*/ pos(2) symxsize(1) forcesize rowgap(1) col(1) size(*.90)) name(ROCplot, replace) 
}


    
/*COMBINED FOREST PLOTS*/
tempname obs obs1 obs2 studyvar1 studyvar2 studyvar1lo studyvar1hi studyvar2lo studyvar2hi 
gen `obs' = _n 
gen `obs1' = _n 
gen `obs2' = _n 
local null1: di " "
count
local max = r(N)
local maxx = `max' + 2
label value `obs' obs
forval i = 1/`max'{
local value = `"`value' `i'"'
label define obs `i' "`=StudyIds[`i']'", modify
}

gen `studyvar2' = .
gen `studyvar2lo' = .
gen `studyvar2hi' = .
gen `studyvar1' = .
gen `studyvar1lo' = .
gen `studyvar1hi' = .
	
local ylabopt "labsize(*`textscale') tl(*0) labgap(*5)"

if "`forest'" == "dss"{
local notef1a: di "Q ="%6.2f `Qvar1' ", df = " %3.2f `Qvar1df' ", p = "%5.2f `pr1' "
local notef1b: di "I2 = "%3.2f `Isq1' " [" %3.2f `Isq1lo' " - " %3.2f `Isq1hi' "]"               
local notef2a: di "Q ="%6.2f `Qvar2' ", df = " %3.2f `Qvar2df' ", p = "%5.2f `pr2' "
local notef2b: di "I2 = "%3.2f `Isq2' " [" %3.2f `Isq2lo' " - " %3.2f `Isq2hi' "]" 
replace `studyvar2' = `var2'
replace `studyvar2lo' = `var2lo'
replace `studyvar2hi' = `var2hi'
replace `studyvar1' = `var1'
replace `studyvar1lo' = `var1lo'
replace `studyvar1hi' = `var1hi'
local xlab1 "xlab(minmax, format(%5.1f) labsize(*`textscale'))"
local xlab2 "xlab(minmax, format(%5.1f) labsize(*`textscale'))"
tostring `studyvar1lo' `studyvar1' `studyvar1hi', gen(`studyvar1lo'1 `studyvar1'1 `studyvar1hi'1) format(%7.2f) force
replace `studyvar1lo'1 = " [" + `studyvar1lo'1 + " - "
replace `studyvar1hi'1 = `studyvar1hi'1 + "]"
egen studyvar1ci = concat(`studyvar1'1 `studyvar1lo'1 `studyvar1hi'1)
label value `obs1' obs1
forval i = 1/`max'{
local value1 = `"`value' `i'"'
label define obs1 `i' "`=studyvar1ci[`i']'", modify
}
tostring `studyvar2lo' `studyvar2' `studyvar2hi', gen(`studyvar2lo'1 `studyvar2'1 `studyvar2hi'1) format(%7.2f) force
replace `studyvar2lo'1 = " [" + `studyvar2lo'1 + " - "
replace `studyvar2hi'1= `studyvar2hi'1 + "]"
egen studyvar2ci = concat(`studyvar2'1 `studyvar2lo'1 `studyvar2hi'1)
label value `obs2' obs2
forval i = 1/`max'{
local value2 = `"`value' `i'"'
label define obs2 `i' "`=studyvar2ci[`i']'", modify
} 	
}

else if "`forest'" == "dlr" {
local notef1a: di "Q ="%6.2f `Qvar1' ", df = " %3.2f `Qvar1df' ", p = "%5.2f `pr1' "
local notef1b: di "I2 = "%3.2f `Isq1' " [" %3.2f `Isq1lo' " - " %3.2f `Isq1hi' "]"               
local notef2a: di "Q ="%6.2f `Qvar2' ", df = " %3.2f `Qvar2df' ", p = "%5.2f `pr2' "
local notef2b: di "I2 = "%3.2f `Isq2' " [" %3.2f `Isq2lo' " - " %3.2f `Isq2hi' "]" 
replace `studyvar2' = `var2'
replace `studyvar2lo' = max(0.01, `var2lo')
replace `studyvar2hi' = min(1.00, `var2hi')
replace `studyvar1' = `var1'
replace `studyvar1lo' = max(0.01, `var1lo')
replace `studyvar1hi' = min(1000, `var1hi')	
local xlab1 "xlab(minmax, format(%5.1f) labsize(*`textscale'))xsc(log)"
local xlab2 "xlab(minmax, format(%5.0f) labsize(*`textscale'))"
tostring `studyvar1lo' `studyvar1' `studyvar1hi', gen(`studyvar1lo'1 `studyvar1'1 `studyvar1hi'1) format(%7.2f) force
replace `studyvar1lo'1 = " [" + `studyvar1lo'1 + " - "
replace `studyvar1hi'1 = `studyvar1hi'1 + "]"
egen studyvar1ci = concat(`studyvar1'1 `studyvar1lo'1 `studyvar1hi'1)
label value `obs1' obs1
forval i = 1/`max'{
local value1 = `"`value' `i'"'
label define obs1 `i' "`=studyvar1ci[`i']'", modify
}
tostring `studyvar2lo' `studyvar2' `studyvar2hi', gen(`studyvar2lo'1 `studyvar2'1 `studyvar2hi'1) format(%7.2f) force
replace `studyvar2lo'1 = " [" + `studyvar2lo'1 + " - "
replace `studyvar2hi'1= `studyvar2hi'1 + "]"
egen studyvar2ci = concat(`studyvar2'1 `studyvar2lo'1 `studyvar2hi'1)
label value `obs2' obs2
forval i = 1/`max'{
local value2 = `"`value' `i'"'
label define obs2 `i' "`=studyvar2ci[`i']'", modify

}
}

else if "`forest'" == "dlor" {
local notef1a: di "Q ="%6.2f `Qvar1' ", df = " %3.2f `Qvar1df' ", p = "%5.2f `pr1' "
local notef1b: di "I2 = "%3.2f `Isq1' " [" %3.2f `Isq1lo' " - " %3.2f `Isq1hi' "]"               
local notef2a: di "Q ="%6.2f `Qvar2' ", df = " %3.2f `Qvar2df' ", p = "%5.2f `pr2' "
local notef2b: di "I2 = "%3.2f `Isq2' " [" %3.2f `Isq2lo' " - " %3.2f `Isq2hi' "]" 
replace `studyvar2' = `var2'
replace `studyvar2lo' = max(0.01, `var2lo')
replace `studyvar2hi' = min(1000, `var2hi')
replace `studyvar1' = `var1'
replace `studyvar1lo' = max(0.01, `var1lo')
replace `studyvar1hi' = `var1hi'
local xlab1 "xlab(minmax, format(%5.1f) labsize(*`textscale')) "
local xlab2 "xlab(minmax, format(%5.0f) labsize(*`textscale')) xsc(log)"
tostring `studyvar1lo' `studyvar1' `studyvar1hi', gen(`studyvar1lo'1 `studyvar1'1 `studyvar1hi'1) format(%7.2f) force
replace `studyvar1lo'1 = " [" + `studyvar1lo'1 + " - "
replace `studyvar1hi'1 = `studyvar1hi'1 + "]"
egen studyvar1ci = concat(`studyvar1'1 `studyvar1lo'1 `studyvar1hi'1)
label value `obs1' obs1
forval i = 1/`max'{
local value1 = `"`value' `i'"'
label define obs1 `i' "`=studyvar1ci[`i']'", modify
}
tostring `studyvar2lo' `studyvar2' `studyvar2hi', gen(`studyvar2lo'1 `studyvar2'1 `studyvar2hi'1) format(%7.2f) force
replace `studyvar2lo'1 = " [" + `studyvar2lo'1 + " - "
replace `studyvar2hi'1= `studyvar2hi'1 + "]"
egen studyvar2ci = concat(`studyvar2'1 `studyvar2lo'1 `studyvar2hi'1)
label value `obs2' obs2
forval i = 1/`max'{
local value2 = `"`value' `i'"'
label define obs2 `i' "`=studyvar2ci[`i']'", modify
}
}

if "`forest'" != "" {
if "`plottype'" != "" {
local plottype "Forest Plot"
}
else if "`plottype'" == "" {
local plottype " "
}

local null  " "

local note1f: di " "%4.2f `mvar1'  "[" %4.2f `mvar1lo' " - " %4.2f `mvar1hi' "]"
local note2f: di " "%4.2f `mvar2'  "[" %4.2f `mvar2lo' " - " %4.2f `mvar2hi' "]"

if ("`fordata'" == "") {
nois twoway (pcarrow `obs' `studyvar1hi' `obs' `studyvar1lo'  if (`studyvar1lo' == 0.01 & "`forest'" == "dlor"),  lwidth(vthin) lpat(solid)  barbsize(0) mlwidth(vthin) ylabel(-1 "" `"`value'"', valuelabel labc(none)))/*
*/ (pcarrow `obs' `studyvar1lo' `obs' `studyvar1hi'  if (`studyvar1hi' == 1000 & "`forest'" == "dlr"),  lpat(solid) lwidth(vthin)  barbsize(0) mlwidth(vthin) ylabel(-1 "" `"`value'"', valuelabel labc(none)))/*
*/ (pcarrow `obs' `studyvar1hi' `obs' `studyvar1lo'  if (`studyvar1lo' == 0.01 & "`forest'" == "dlr"),  lwidth(vthin) lpat(solid)  barbsize(0) mlwidth(vthin) ylabel(-1 "" `"`value'"', valuelabel labc(none)))/*
*/(rspike `studyvar1lo' `studyvar1hi' `obs', ylabel(`maxx' "STUDY(YEAR)" -1 "COMBINED" -2 "`notef1a'" -3 "`notef1b'" `"`value'"', valuelabel `ylabopt' angle(360)) /*
*/ hor s(i) blpattern(solid) blwidth(vthin) blcolor(black) `xlab1')(scatter `obs' `studyvar1', ms(S) msize(*`mscale2') mcolor(gs10))(scatter `obs' `studyvar1', ms(o) msize(*`mscale') mcolor(black) xline(`mvar1', lpattern(-)))/*
*/ (scatteri -1 `mvar1lo' -0.8 `mvar1', clcolor(black) c(l) s(i))(scatteri -1 `mvar1lo' -1.2 `mvar1', clcolor(black) c(l) s(i)) (scatteri -0.8 `mvar1' -1 /*
*/ `mvar1hi', clcolor(black) c(l) s(i))(scatteri -1.2 `mvar1' -1 `mvar1hi', clcolor(black) c(l) s(i)),  /*
*/ legend(off)  xtitle("`gtitle1'", size(*.5)) title("`plottype'" "`tlab'", size(*0.75)) name(forplot1, replace)


nois twoway (pcarrow `obs' `studyvar2hi' `obs' `studyvar2lo'  if (`studyvar2lo' == 0.01 & "`forest'" == "dlor"),  lpat(solid) lwidth(vthin)   barbsize(0) mlwidth(vthin) ylabel(-1 "" `"`value'"', valuelabel labc(none)))/*
*/ (pcarrow `obs' `studyvar2lo' `obs' `studyvar2hi'  if (`studyvar2hi' == 1000 & "`forest'" == "dlor"),  lwidth(vthin) lpat(solid)  barbsize(0) mlwidth(vthin) ylabel(-1 "" `"`value'"', valuelabel labc(none)))/*
*/ (pcarrow `obs' `studyvar2hi' `obs' `studyvar2lo'  if (`studyvar2lo' == 0.01 & "`forest'" == "dlr"),  lpat(solid) lwidth(vthin)   barbsize(0) mlwidth(vthin) ylabel(-1 "" `"`value'"', valuelabel labc(none)))/*
*/ (rspike `studyvar2lo' `studyvar2hi' `obs', ylabel(`maxx' "STUDY(YEAR)" -1 "COMBINED" -2 "`notef2a'" -3 "`notef2b'"  `"`value'"', valuelabel `ylabopt' angle(360)) /*
*/ hor s(i) blpattern(solid) blwidth(vthin) blcolor(black) `xlab2')(scatter `obs' `studyvar2', ms(S) msize(*`mscale2') mcolor(gs10))(scatter `obs' `studyvar2', ms(o) msize(*`mscale') mcolor(black) xline(`mvar2', lpattern(-)))/*
*/ (scatteri -1 `mvar2lo' -0.8 `mvar2', clcolor(black) c(l) s(i))(scatteri -1 `mvar2lo' -1.2 `mvar2', clcolor(black) c(l) s(i)) (scatteri -0.8 `mvar2' -1 /*
*/ `mvar2hi', clcolor(black) c(l) s(i))(scatteri -1.2 `mvar2' -1 `mvar2hi', clcolor(black) c(l) s(i)), /*
*/ legend(off) xtitle("`gtitle2'", size(*.5)) title("`plottype'" "`tlab'", size(*0.75)) name(forplot2, replace)
}
else if "`fordata'" == "fordata" {
nois twoway (pcarrow `obs' `studyvar1hi' `obs' `studyvar1lo'  if (`studyvar1lo' == 0.01 & "`forest'" == "dlor"),  lwidth(vthin) lpat(solid)  barbsize(0) mlwidth(vthin) ylabel(-1 "" `"`value'"', valuelabel labc(none)))/*
*/ (pcarrow `obs' `studyvar1lo' `obs' `studyvar1hi'  if (`studyvar1hi' == 1000 & "`forest'" == "dlr"),  lpat(solid) lwidth(vthin)  barbsize(0) mlwidth(vthin) ylabel(-1 "" `"`value'"', valuelabel labc(none)))/*
*/ (pcarrow `obs' `studyvar1hi' `obs' `studyvar1lo'  if (`studyvar1lo' == 0.01 & "`forest'" == "dlr"),  lwidth(vthin) lpat(solid)  barbsize(0) mlwidth(vthin) ylabel(-1 "" `"`value'"', valuelabel labc(none)))/*
*/(rspike `studyvar1lo' `studyvar1hi' `obs', ylabel(`maxx' "STUDY(YEAR)" -1 "COMBINED" -2 "`notef1a'" -3 "`notef1b'" `"`value'"', valuelabel `ylabopt' angle(360)) /*
*/ hor s(i) blpattern(solid) blwidth(vthin) blcolor(black) `xlab1')(scatter `obs' `studyvar1', ms(S) msize(*`mscale2') mcolor(gs10))(scatter `obs' `studyvar1', ms(o) msize(*`mscale') mcolor(black) xline(`mvar1', lpattern(-)))/*
*/ (scatter `obs1' `studyvar1', ms(i) yaxis(2) ylab(`maxx' "`gtitle1' (95% CI)" -3 "`null1'" -2 "`null1'" -1 "`note1f'" `"`value1'"', valuelabel labsize(*`textscale') noticks labgap(*5) angle(360) axis(2)))(scatteri -1 `mvar1lo' -0.8 `mvar1', clcolor(black) c(l) s(i)) /*
*/ (scatteri -1 `mvar1lo' -1.2 `mvar1', clcolor(black) c(l) s(i)) (scatteri -0.8 `mvar1' -1 /*
*/ `mvar1hi', clcolor(black) c(l) s(i))(scatteri -1.2 `mvar1' -1 `mvar1hi', clcolor(black) c(l) s(i)) /*
*/ , legend(off)  yti("", axis(2)) xtitle("`gtitle1'", size(*.5)) title("`plottype'" "`tlab'", size(*0.75)) name(forplot1, replace)


nois twoway (pcarrow `obs' `studyvar2hi' `obs' `studyvar2lo'  if (`studyvar2lo' == 0.01 & "`forest'" == "dlor"),  lpat(solid) lwidth(vthin)   barbsize(0) mlwidth(vthin) ylabel(-1 "" `"`value'"', valuelabel labc(none)))/*
*/ (pcarrow `obs' `studyvar2lo' `obs' `studyvar2hi'  if (`studyvar2hi' == 1000 & "`forest'" == "dlor"),  lwidth(vthin) lpat(solid)  barbsize(0) mlwidth(vthin) ylabel(-1 "" `"`value'"', valuelabel labc(none)))/*
*/ (pcarrow `obs' `studyvar2hi' `obs' `studyvar2lo'  if (`studyvar2lo' == 0.01 & "`forest'" == "dlr"),  lpat(solid) lwidth(vthin)   barbsize(0) mlwidth(vthin) ylabel(-1 "" `"`value'"', valuelabel labc(none)))/*
*/ (rspike `studyvar2lo' `studyvar2hi' `obs', ylabel(`maxx' "STUDY(YEAR)" -1 "COMBINED" -2 "`notef2a'" -3 "`notef2b'"  `"`value'"', valuelabel `ylabopt' angle(360)) /*
*/ hor s(i) blpattern(solid) blwidth(vthin) blcolor(black) `xlab2')(scatter `obs' `studyvar2', ms(S) msize(*`mscale2') mcolor(gs10))(scatter `obs' `studyvar2', ms(o) msize(*`mscale') mcolor(black) xline(`mvar2', lpattern(-)))/*
*/ (scatter `obs2' `studyvar2', ms(i) yaxis(2) ylab(`maxx' "`gtitle2' (95% CI)"  -3 "`null1'" -2 "`null1'" -1 "`note2f'" `"`value2'"', valuelabel labsize(*`textscale') noticks  labgap(*5) angle(360) axis(2)))(scatteri -1 `mvar2lo' -0.8 `mvar2', clcolor(black) c(l) s(i)) /*
*/ (scatteri -1 `mvar2lo' -1.2 `mvar2', clcolor(black) c(l) s(i)) (scatteri -0.8 `mvar2' -1 /*
*/ `mvar2hi', clcolor(black) c(l) s(i))(scatteri -1.2 `mvar2' -1 `mvar2hi', clcolor(black) /*
*/ c(l) s(i)), legend(off) xtitle("`gtitle2'", size(*.5))  yti("", axis(2)) title("`plottype'" "`tlab'", size(*0.75)) name(forplot2, replace)

 }

}


/* FAGAN PLOT */
if "`fagan'" == "fagan" {
if `prior' == 1.0 {
	local prev = $prev 
}
if `prior' != 1.0 {
local prev = `prior'
}
nois di as text "FAGAN'S(BAYESIAN) NOMOGRAM"
nois di " "
nois di " "

fagani `prev' `mlrp' `mlrn'
}



/*LIKELIHOOD RATIO SCATTERGRAM */

if "`lrmatrix'" == "lrmatrix" {
nois di as text "LIKELIHOOD RATIO SCATTERGRAM "
nois lrmat `lrp' `lrn', sum1(`mlrp' `mlrplo' `mlrphi') sum2(`mlrn' `mlrnlo' `mlrnhi')
}

/*UNCONDITIONAL PREDICTIVE VALUES OR CONDITIONAL PROBABILITY PLOT*/

 if "`pddam'" == "p" {
nois di as text "CONDITIONAL PROBABILITY PLOT"
nois di " "
nois di " "
nois pddami `mtpr' `mtprse' `mtnr' `mtnrse', plot sum1(`mlrp' `mlrplo' `mlrphi') sum2(`mlrn' `mlrnlo' `mlrnhi')
}
else  if "`pddam'" == "r" {
nois di as text "UNCONDITIONAL PREDICTIVE VALUES"
nois di " "
nois di " "
nois pddami `mtpr' `mtprse' `mtnr' `mtnrse', report sum1(`mlrp' `mlrplo' `mlrphi') sum2(`mlrn' `mlrnlo' `mlrnhi')
}



/* BIVARIATE MIXED-EFFECTS METAREGRESSION */

if "`covars'" =="covars" {

noi di in gr "{title: UNIVARIABLE BIVARIATE MIXED-EFFECTS BINARY META-REGRESSION}"
nois midareg $tp $fp $fn $tn $varlist2, `nip' `level'
}

/*SUMMARY ROC CURVE*/
tempvar  x CB1 CB2 CBsens CBspec yroc llyroc ulyroc
tempvar PB1 PB2 PBsn PBsp CPI
	          
/* model-based parameters */

local rhoci = `cov01'/ (`snse' * `spse')
local pred1se = sqrt(`reffs2' + `snse'^2)
local pred2se = sqrt(`reffs1' + `spse'^2)
local rhopred = (`covar' + `cov01')/(`pred1se'*`pred2se')
local NP = 500
range `CPI' 0 `=2* c(pi)' `NP'

/* Parameters for mean operating point and SROC Space */
local mbeta = (max(0.001, `reffs1')/max(0.001, `reffs2'))^.25
local malpha = `sn'*`mbeta' + `sp'/`mbeta'


range `x' 0 1 `NP'
gen double `yroc' = invlogit( ( -logit(`x') /`mbeta' + `malpha') / `mbeta' )
replace `yroc' = 0 if `x' == 1
replace `yroc' = 1 if `x' == 0
integ `yroc' `x',  trapezoid
local AUC = r(integral)
scalar N=r(N_points)
return scalar AUC = `AUC'
local AUClo = min(1.00, (`AUC'+(invnormal(0.975)^2)/(2*N)-invnormal(0.975)*sqrt((`AUC'*(1-`AUC')+/*
*/((invnormal(0.975)^2)/(4*N)))/N))/(1+((invnormal(0.975)^2)/N)))

local AUChi = max(0, (`AUC'+(invnormal(0.975)^2)/(2*N)+invnormal(0.975)*sqrt((`AUC'*(1-`AUC')+/*
*/((invnormal(0.975)^2)/(4*N)))/N))/(1+((invnormal(0.975)^2)/N)))
return scalar AUClo = `AUClo'
return scalar AUChi = `AUChi'

local note: di "AUC = "%3.2f `AUC' " [" %3.2f `AUClo' " - " %3.2f `AUChi' "]" 
local snnote: di "SENS = "%3.2f `mtpr' " [" %3.2f `mtprlo' " - " %3.2f `mtprhi' "]" 
local spnote: di "SPEC = "%3.2f `mtnr' " [" %3.2f `mtnrlo' " - " %3.2f `mtnrhi' "]"
				
/* Derivation of parameters for 95% confidence ellipse about mean operating point*/

local kci = sqrt(2*invF(2, `numobs'-2,`level'/100))
gen `CB2' = `sp' + `spse' * `kci' * cos(`CPI')
gen `CB1' = `sn' + `snse' * `kci' * cos(`CPI' + acos(`rhoci'))
gen `CBsens' = invlogit(`CB1')
gen `CBspec' = invlogit(`CB2')
					
/* Derivation of 95% prediction ellipse*/
		
gen `PB2' = `sp' + `pred2se' * `kci' * cos(`CPI')
gen `PB1' = `sn' + `pred1se' * `kci' * cos(`CPI' + acos(`rhopred'))
gen `PBsn' = invlogit(`PB1')
gen `PBsp' = invlogit(`PB2') 

if "`sroc2'" == "sroc2" {
if "`plottype'" != "" {
local plottype "SROC with Confidence and Predictive Ellipses"
}
else if "`plottype'" == "" {
local plottype " "
}

#delimit;				
nois twoway (scatter `sens' `spec', msym(x))
(scatteri `mtpr' `mtnr', msym(D))
(line `yroc' `x', clpat(solid) clc(black))
(line `CBsens' `CBspec', clpat(dash) clc(black) clw(thin))
(line `PBsn' `PBsp', clpat(dot)  clc(black)), plotregion(margin(zero)) 
xsc(range(0 1) rev) ysc(range(0 1))  xla(0(.5)1, nogrid format(%7.1f)) 
yla(0(.5)1, nogrid angle(horizontal) format(%7.1f)) xti(Specificity) 
yti(Sensitivity)  legend(order(1 "Observed Data" 2 "Summary Operating Point" "`snnote'" "`spnote'"
3 "SROC Curve" "`note'" 4 "`level'% Confidence Ellipse" 5 "`level'% Prediction Ellipse") 
pos(2) col(1) size(*.75)) xsize(`hsize') title("`plottype'" "`tlab'", size(*0.75)) ;
#delimit cr
}
if "`sroc1'" == "sroc1" {
if "`plottype'" != "" {
local plottype "SROC without Confidence and Predictive Ellipses"
}
else if "`plottype'" == "" {
local plottype " "
}

#delimit;				
nois twoway (scatter `sens' `spec', msym(x))
(scatteri `mtpr' `mtnr', msym(D))
(line `yroc' `x', clpat(solid) clc(black)), 
xsc(range(0 1) rev) ysc(range(0 1))  xla(0(.5)1, nogrid format(%7.1f)) 
yla(0(.5)1, nogrid angle(horizontal) format(%7.1f)) plotregion(margin(zero)) xti(Specificity) 
yti(Sensitivity)  legend(order(1 "Observed Data" 2 "Summary Operating Point" "`snnote'" "`spnote'"
3 "SROC Curve" "`note'") pos(2) col(1) size(*.75)) xsize(`hsize') title("`plottype'" "`tlab'", size(*0.75)) ;
#delimit cr
}

nois di ""
nois di ""

if "`results'" == "all" {
nois di "SUMMARY DATA AND PERFORMANCE ESTIMATES"
nois di as text "Bivariate Binomial Mixed Model"
nois di " "
nois di as txt "Number of studies = ", as res `numobs'
nois di " "
nois di as txt "Reference-positive Subjects ="as result %5.0f `sumtpfn'
nois di " "
nois di as txt "Reference-negative Subjects ="as result %5.0f `sumtnfp'
nois di " "
nois di as txt "Pretest Prob of Disease ="as result %5.3f $prev
nois di " "
nois di ""
nois di as txt "Between-study variance(varlogitSEN) ="as result %5.3f `reffs2' _c
nois di as txt ", 95% CI = ["as res %5.3f `reffs2lo'                _c
nois di as txt "-"as res %5.3f `reffs2hi' as txt"]"               _n
nois di " "
nois di as txt "Between-study variance(varlogitSPE)= "as result %5.3f `reffs1' _c  
nois di as txt ", 95% CI = ["as res %5.3f `reffs1lo'                _c
nois di as txt "-"as res %5.3f `reffs1hi' as txt"]"               _n
nois di " "
nois di as txt "Correlation (Mixed Model)= " as result %5.3f `rho' 
nois di " "
nois di as txt "ROC Area, AUROC = " as res %3.2f `AUC' " [" as res %3.2f `AUClo' " - " as res %3.2f `AUChi' "]" 
nois di ""
nois di ""
nois di as txt "Heterogeneity (Chi-square): LRT_Q = " as result %5.3f `lrtchi' ///
as txt ", df =" as result %3.2f `lrtdf' as txt", LRT_p ="as result %5.3f `lrtpchi'
nois di ""
nois di as txt "Inconsistency (I-square): LRT_I2 = "as res %3.2f `Islrt' _c
nois di as txt ", 95% CI = ["as res %3.2f `Islrtlo'                _c
nois di as txt "-"as res %3.2f `Islrthi' as txt"]"               _n
nois di ""
nois di ""
nois di %-28s "Parameter" %8s "Estimate" %16s "`level'% CI"
nois di ""

nois di as text %-28s "Sensitivity" as res %8.3f `mtpr' as text " " "[" as res %8.3f `mtprlo' as text "," as res %8.3f `mtprhi' as text"]"
nois di ""
nois di as text %-28s "Specificity" as res %8.3f `mtnr' as text " " "[" as res %8.3f `mtnrlo' as text "," as res %8.3f `mtnrhi' as text"]"  
nois di ""
nois di as text %-28s "Positive Likelihood Ratio" as res %8.3f `mlrp' as text " " "[" as res %8.3f `mlrplo' as text "," as res %8.3f `mlrphi' as text"]"
nois di ""
nois di as text %-28s "Negative Likelihood Ratio" as res %8.3f `mlrn' as text " " "[" as res %8.3f `mlrnlo' as text "," as res %8.3f `mlrnhi' as text"]"
nois di ""
nois di as text %-28s "Diagnostic Score" as res %8.3f `mldor' as text " " "[" as res %8.3f `mldorlo' as text "," as res %8.3f `mldorhi' as text"]"
nois di ""
nois di as text %-28s "Diagnostic Odds Ratio" as res %8.3f `mdor' as text " " "[" as res %8.3f `mdorlo' as text "," as res %8.3f `mdorhi' as text"]"
nois di ""
nois di ""	  
}
else if "`results'" == "het" {
nois di ""
nois di ""
nois di "GLOBAL HETEROGENEITY STATISTICS"
nois di as txt "Heterogeneity (Chi-square): LRT_Q = " as result %5.3f `lrtchi' ///
as txt ", df =" as result %3.2f `lrtdf' as txt", LRT_p ="as result %5.3f `lrtpchi'
nois di ""
nois di as txt "Inconsistency (I-square): LRT_I2 = "as res %3.2f `Islrt' _c
nois di as txt ", 95% CI = ["as res %3.2f `Islrtlo'                _c
nois di as txt "-"as res %3.2f `Islrthi' as txt"]"               _n
nois di ""
nois di ""
nois di as txt "Between-study variance(varlogitSEN) ="as result %5.3f `reffs2' _c
nois di as txt ", 95% CI = ["as res %5.3f `reffs2lo'                _c
nois di as txt "-"as res %5.3f `reffs2hi' as txt"]"               _n
nois di " "
nois di as txt "Between-study variance(varlogitSPE)= "as result %5.3f `reffs1' _c  
nois di as txt ", 95% CI = ["as res %5.3f `reffs1lo'                _c
nois di as txt "-"as res %5.3f `reffs1hi' as txt"]"               _n
nois di " "
}
else if "`results'" == "sum" {
nois di ""
nois di "SUMMARY PERFORMANCE ESTIMATES"
nois di ""
nois di ""
nois di %-28s "Parameter" %8s "Estimate" %16s "`level'% CI"
nois di ""
nois di as text %-28s "Sensitivity" as res %8.3f `mtpr' as text " " "[" as res %8.3f `mtprlo' as text "," as res %8.3f `mtprhi' as text"]"
nois di ""
nois di as text %-28s "Specificity" as res %8.3f `mtnr' as text " " "[" as res %8.3f `mtnrlo' as text "," as res %8.3f `mtnrhi' as text"]"  
nois di ""
nois di as text %-28s "Positive Likelihood Ratio" as res %8.3f `mlrp' as text " " "[" as res %8.3f `mlrplo' as text "," as res %8.3f `mlrphi' as text"]"
nois di ""
nois di as text %-28s "Negative Likelihood Ratio" as res %8.3f `mlrn' as text " " "[" as res %8.3f `mlrnlo' as text "," as res %8.3f `mlrnhi' as text"]"
nois di ""
nois di as text %-28s "Diagnostic Score" as res %8.3f `mldor' as text " " "[" as res %8.3f `mldorlo' as text "," as res %8.3f `mldorhi' as text"]"
nois di ""
nois di as text %-28s "Diagnostic Odds Ratio" as res %8.3f `mdor' as text " " "[" as res %8.3f `mdorlo' as text "," as res %8.3f `mdorhi' as text"]"
nois di ""
nois di ""	  
}
}
}
end


program xtbbrre, rclass sortpreserve byable(recall)
version 10
syntax varlist(min=4 max=4 numeric) [if] [in], [ NIP(integer 7) INDex(string) LEVEL(integer 95) *] 

qui {
preserve
marksample touse, novarlist
keep if `touse'
}
tokenize `varlist'
local tp `1'
local fp `2'
local fn `3'
local tn `4'



/* MIXED EFFECTS ESTIMATION */

qui {
local alph = (100-`level')/200
gen study = _n
gen ttruth1 = `tn'                   
gen ttruth2 = `tp'                    
gen num1 = `tn'+`fp'                      
gen num2 = `tp'+`fn'                      
reshape long num ttruth, i(study) j(dtruth) string
tabulate dtruth, generate(disgrp)
}
xtmelogit (ttruth disgrp1 disgrp2, noc)(study: disgrp1 disgrp2, noc cov(unstr)), bin(num) intp(`nip') var nolr nofet noret nohead

qui {
 nois di " "
 nois di " " 
estimates store modr 
mat V = e(V)
mat b = e(b)
return local covsnsp = V[1,2]
return scalar mcovar = tanh(_b[atr1_1_1_2:_cons]) * _b[lns1_1_1:_cons] * _b[lns1_1_2:_cons] 
nlcom (spbeta: _b[disgrp1])(snbeta: _b[disgrp2])/*
*/(mrho: _b[atr1_1_1_2:_cons])/*
*/(mreffs1: _b[lns1_1_1:_cons])(mreffs2: _b[lns1_1_2:_cons])/* 
*/(msens: _b[disgrp2])(mspec: _b[disgrp1])(mldor: _b[disgrp2]+_b[disgrp1]) /*
*/(mdor: _b[disgrp2]+_b[disgrp1]) /*
*/(mlrp: log(invlogit(_b[disgrp2])/(1-invlogit(_b[disgrp1]))))/* 
*/(mlrn: log((1-invlogit(_b[disgrp2]))/invlogit(_b[disgrp1]))), post
return scalar mrho = tanh(_b[mrho])
return scalar mrholo = tanh(_b[mrho] - invnorm(1-`alph')*_se[mrho])
return scalar mrhohi = tanh(_b[mrho] + invnorm(1-`alph')*_se[mrho])
ret scalar mreffs1 = exp(_b[mreffs1])^2
ret scalar mreffs1se = exp(_se[mreffs1])^2
ret scalar mreffs1lo = exp(_b[mreffs1] - invnorm(1-`alph') * _se[mreffs1])^2
ret scalar mreffs1hi = exp(_b[mreffs1] + invnorm(1-`alph') * _se[mreffs1])^2
ret scalar mreffs2 = exp(_b[mreffs2])^2
ret scalar mreffs2se = exp(_se[mreffs2])^2
ret scalar mreffs2lo = exp(_b[mreffs2] - invnorm(1-`alph') * _se[mreffs2])^2
ret scalar mreffs2hi = exp(_b[mreffs2] + invnorm(1-`alph') * _se[mreffs2])^2
return scalar mtpr = invlogit(_b[msens])
return scalar mtprlo = invlogit(_b[msens] - invnorm(1-`alph')*_se[msens]) 
return scalar mtprhi = invlogit(_b[msens] + invnorm(1-`alph')*_se[msens])
return scalar mtprse = (return(mtprhi)-return(mtpr))/invnorm(1-`alph')
return scalar mtnr = invlogit(_b[mspec])
return scalar mtnrlo = invlogit(_b[mspec] - invnorm(1-`alph')*_se[mspec])
return scalar mtnrhi = invlogit(_b[mspec] + invnorm(1-`alph')*_se[mspec])
return scalar mtnrse = (return(mtnrhi)-return(mtnr))/invnorm(1-`alph')
return scalar mldor = _b[mldor]
return scalar mldorlo = _b[mldor] - invnorm(1-`alph')*_se[mldor]
return scalar mldorhi = _b[mldor] + invnorm(1-`alph')*_se[mldor]
return scalar mldorse = (return(mldorhi)-return(mldor))/invnorm(1-`alph')
return scalar mdor = exp(_b[mdor])
return scalar mdorlo = exp(_b[mdor] - invnorm(1-`alph')*_se[mdor])
return scalar mdorhi = exp(_b[mdor] + invnorm(1-`alph')*_se[mdor])
return scalar mdorse = (return(mdorhi)-return(mdor))/invnorm(1-`alph')
return scalar mlrp = exp(_b[mlrp])
return scalar mlrplo = exp(_b[mlrp] - invnorm(1-`alph')*_se[mlrp])
return scalar mlrphi = exp(_b[mlrp] + invnorm(1-`alph')*_se[mlrp])
return scalar mlrpse = (return(mlrphi)-return(mlrp))/invnorm(1-`alph')
return scalar mlrn = exp(_b[mlrn])
return scalar mlrnlo = exp(_b[mlrn] - invnorm(1-`alph')*_se[mlrn])
return scalar mlrnhi = exp(_b[mlrn] + invnorm(1-`alph')*_se[mlrn])
return scalar mlrnse = (return(mlrnhi)-return(mlrn))/invnorm(1-`alph')
return scalar sp = _b[spbeta]
return scalar spse = _se[spbeta]
return scalar splo = _b[snbeta] - invnorm(1-$alph)*_se[spbeta]
return scalar sphi = _b[snbeta] + invnorm(1-$alph)*_se[spbeta]
return scalar sn = _b[snbeta]
return scalar snse = _se[snbeta]
return scalar snlo = _b[snbeta] - invnorm(1-$alph) * _se[snbeta]
return scalar snhi = _b[snbeta] + invnorm(1-$alph) * _se[snbeta]


/* FIXED EFFECTS ESTIMATION */

xtmelogit (ttruth disgrp1 disgrp2, noc)(study: ), bin(num) 
estimates store modf
nlcom (fsens: _b[disgrp2])/*
*/(fspec: _b[disgrp1])/*
*/(fldor: (_b[disgrp2]+_b[disgrp1])) /*
*/(fdor: _b[disgrp2]+_b[disgrp1]) /*
*/(flrp: log(invlogit(_b[disgrp2])/(1-invlogit(_b[disgrp1]))))/* 
*/(flrn: log((1-invlogit(_b[disgrp2]))/invlogit(_b[disgrp1]))), post

return scalar fsens = invlogit(_b[fsens])
return scalar fspec =  invlogit(_b[fspec])
return scalar fldor = _b[fldor]
return scalar fdor = exp(_b[fdor])
return scalar flrp = exp(_b[flrp])
return scalar flrn = exp(_b[flrn])

/*LRT STATISTICS AND HETEROGENEITY*/

tempname lrtchi lrtpchi lrtdf
lrtest modr modf, stats force
scalar `lrtchi' = r(chi2)
scalar `lrtpchi'= 0.5 * r(p)
scalar `lrtdf' = r(df)
return scalar lrtchi = r(chi2)
return scalar lrtpchi= 0.5 * r(p)
return scalar  lrtdf = r(df)
homogeni `lrtchi' `lrtdf'
return scalar Islrt = r(Isq)
return scalar Islrtlo = r(Isqlo)
return scalar Islrthi = r(Isqhi)
}

end

program bbrre, rclass sortpreserve byable(recall)
version 9
syntax varlist(min=4 max=4 numeric) [if] [in], [ NIP(integer 15) INDex(string) LEVEL(integer 95) *] 

qui {
preserve
marksample touse, novarlist
keep if `touse'
}
tokenize `varlist'
local tp `1'
local fp `2'
local fn `3'
local tn `4'

if  !inlist(`nip', 5, 7, 9, 11, 15) {
di as error "nip must be 5, 7, 9, 11 or 15"
error 198
			}


/* MIXED EFFECTS ESTIMATION */

qui {
local alph = (100-`level')/200
gen study = _n
gen ttruth1 = `tn'                   
gen ttruth2 = `tp'                    
gen num1 = `tn'+`fp'                      
gen num2 = `tp'+`fn'                      
reshape long num ttruth, i(study) j(dtruth) string
tabulate dtruth, generate(disgrp)
eq disgrp1: disgrp1
eq disgrp2: disgrp2
gllamm ttruth disgrp1 disgrp2, nocons i(study) nrf(2) eqs(disgrp1 disgrp2) ///
f(bin) l(logit) denom(num)   
mat a = e(b)
local l = e(ll)
local k = e(k)
}
gllamm ttruth disgrp1 disgrp2, nocons i(study) nrf(2) eqs(disgrp1 disgrp2) ///
f(bin) l(logit) denom(num) from(a) lf0(`k' `l') adapt ip(m) nip(`nip')

qui {
 nois di " "
 nois di " " 
estimates store modr 
mat V = e(V)
mat b = e(b)
scalar cov = V[5,4]
ret scalar mreffs1 =  _b[stu1_1 : disgrp1]^2
ret scalar mreffs1se = 2 * sqrt(return(mreffs1) * _se[stu1_1 : disgrp1]^2)
ret scalar mreffs1lo = return(mreffs1) - invnorm(1-`alph') * return(mreffs1se)
ret scalar mreffs1hi = return(mreffs1) + invnorm(1-`alph') * return(mreffs1se)
ret scalar mreffs2 = _b[stu1_2 : disgrp2]^2 + _b[stu1_2_1 : _cons]^2
return scalar mreffs2se = sqrt( 4*_b[stu1_2 : disgrp2]^2*_se[stu1_2 : disgrp2]^2 /*
*/ + 4* _b[stu1_2_1 : _cons]^2*_se[stu1_2_1 : _cons]^2 /*
 */ + 8* _b[stu1_2 : disgrp2]*_b[stu1_2_1 : _cons]*cov )
ret scalar mreffs2lo = return(mreffs2) - invnorm(1-`alph') * return(mreffs2se)
ret scalar mreffs2hi = return(mreffs2) + invnorm(1-`alph') * return(mreffs2se)
return local covsnsp = V[1,2] 
mat chol= e(chol)
mat chol2 = chol*chol'
mat covar= chol2[2,1]
local covar = trace(covar)
return scalar mcovar = trace(covar)
return scalar mrho = `covar'/(sqrt(_b[stu1_1 : disgrp1]^2)* sqrt(_b[stu1_2 : disgrp2]^2 + _b[stu1_2_1 : _cons]^2)) 

nlcom (spbeta: _b[disgrp1])(snbeta: _b[disgrp2])(msens: _b[disgrp2])/*
*/(mspec: _b[disgrp1])(mldor: _b[disgrp2]+_b[disgrp1]) /*
*/(mdor: _b[disgrp2]+_b[disgrp1]) /*
*/(mlrp: log(invlogit(_b[disgrp2])/(1-invlogit(_b[disgrp1]))))/* 
*/(mlrn: log((1-invlogit(_b[disgrp2]))/invlogit(_b[disgrp1]))), post
return scalar mtpr = invlogit(_b[msens])
return scalar mtprlo = invlogit(_b[msens] - invnorm(1-`alph')*_se[msens]) 
return scalar mtprhi = invlogit(_b[msens] + invnorm(1-`alph')*_se[msens])
return scalar mtprse = (return(mtprhi)-return(mtpr))/invnorm(1-`alph')
return scalar mtnr = invlogit(_b[mspec])
return scalar mtnrlo = invlogit(_b[mspec] - invnorm(1-`alph')*_se[mspec])
return scalar mtnrhi = invlogit(_b[mspec] + invnorm(1-`alph')*_se[mspec])
return scalar mtnrse = (return(mtnrhi)-return(mtnr))/invnorm(1-`alph')
return scalar mldor = _b[mldor]
return scalar mldorlo = _b[mldor] - invnorm(1-`alph')*_se[mldor]
return scalar mldorhi = _b[mldor] + invnorm(1-`alph')*_se[mldor]
return scalar mldorse = (return(mldorhi)-return(mldor))/invnorm(1-`alph')
return scalar mdor = exp(_b[mdor])
return scalar mdorlo = exp(_b[mdor] - invnorm(1-`alph')*_se[mdor])
return scalar mdorhi = exp(_b[mdor] + invnorm(1-`alph')*_se[mdor])
return scalar mdorse = (return(mdorhi)-return(mdor))/invnorm(1-`alph')
return scalar mlrp = exp(_b[mlrp])
return scalar mlrplo = exp(_b[mlrp] - invnorm(1-`alph')*_se[mlrp])
return scalar mlrphi = exp(_b[mlrp] + invnorm(1-`alph')*_se[mlrp])
return scalar mlrpse = (return(mlrphi)-return(mlrp))/invnorm(1-`alph')
return scalar mlrn = exp(_b[mlrn])
return scalar mlrnlo = exp(_b[mlrn] - invnorm(1-`alph')*_se[mlrn])
return scalar mlrnhi = exp(_b[mlrn] + invnorm(1-`alph')*_se[mlrn])
return scalar mlrnse = (return(mlrnhi)-return(mlrn))/invnorm(1-`alph')
return scalar sp = _b[spbeta]
return scalar spse = _se[spbeta]
return scalar splo = _b[snbeta] - invnorm(1-$alph)*_se[spbeta]
return scalar sphi = _b[snbeta] + invnorm(1-$alph)*_se[spbeta]
return scalar sn = _b[snbeta]
return scalar snse = _se[snbeta]
return scalar snlo = _b[snbeta] - invnorm(1-$alph) * _se[snbeta]
return scalar snhi = _b[snbeta] + invnorm(1-$alph) * _se[snbeta]

if "`index'" != "" & "`index'" == "dss" {
return scalar ES1 = invlogit(_b[msens])
return scalar ES1lo = invlogit(_b[msens] - invnorm(1-`alph')*_se[msens]) 
return scalar ES1hi = invlogit(_b[msens] + invnorm(1-`alph')*_se[msens])
return scalar ES1se = (return(ES1hi)-return(ES1))/invnorm(1-`alph')
return scalar ES2 = invlogit(_b[mspec])
return scalar ES2lo = invlogit(_b[mspec] - invnorm(1-`alph')*_se[mspec])
return scalar ES2hi = invlogit(_b[mspec] + invnorm(1-`alph')*_se[mspec])
return scalar ES2se = (return(ES2hi)-return(ES2))/invnorm(1-`alph')
}
else if "`index'" != "" & "`index'" == "dlor" {

return scalar ES1 = _b[mldor]
return scalar ES1lo = _b[mldor] - invnorm(1-`alph')*_se[mldor]
return scalar ES1hi = _b[mldor] + invnorm(1-`alph')*_se[mldor]
return scalar ES1se = (return(ES1hi)-return(ES1))/invnorm(1-`alph')
return scalar ES2 = exp(_b[mdor])
return scalar ES2lo = exp(_b[mdor] - invnorm(1-`alph')*_se[mdor])
return scalar ES2hi = exp(_b[mdor] + invnorm(1-`alph')*_se[mdor])
return scalar ES2se = (return(ES2hi)-return(ES2))/invnorm(1-`alph')
}
else if "`index'" != "" & "`index'" == "dlr" {
return scalar ES1 = exp(_b[mlrp])
return scalar ES1lo = exp(_b[mlrp] - invnorm(1-`alph')*_se[mlrp])
return scalar ES1hi = exp(_b[mlrp] + invnorm(1-`alph')*_se[mlrp])
return scalar ES1se = (return(ES1hi)-return(ES1))/invnorm(1-`alph')
return scalar ES2 = exp(_b[mlrn])
return scalar ES2lo = exp(_b[mlrn] - invnorm(1-`alph')*_se[mlrn])
return scalar ES2hi = exp(_b[mlrn] + invnorm(1-`alph')*_se[mlrn])
return scalar ES2se = (return(mlrnhi)-return(mlrn))/invnorm(1-`alph')
}


/* FIXED EFFECTS ESTIMATION */

gllamm ttruth disgrp1 disgrp2, nocons i(study)  ///
f(bin) l(logit) denom(num)  init ip(m) nip(`nip') adapt   

estimates store modf
nlcom (fsens: _b[disgrp2])/*
*/(fspec: _b[disgrp1])/*
*/(fldor: (_b[disgrp2]+_b[disgrp1])) /*
*/(fdor: _b[disgrp2]+_b[disgrp1]) /*
*/(flrp: log(invlogit(_b[disgrp2])/(1-invlogit(_b[disgrp1]))))/* 
*/(flrn: log((1-invlogit(_b[disgrp2]))/invlogit(_b[disgrp1]))), post

return scalar fsens = invlogit(_b[fsens])
return scalar fspec =  invlogit(_b[fspec])
return scalar fldor = _b[fldor]
return scalar fdor = exp(_b[fdor])
return scalar flrp = exp(_b[flrp])
return scalar flrn = exp(_b[flrn])

/*LRT STATISTICS AND HETEROGENEITY*/

tempname lrtchi lrtpchi lrtdf
lrtest modr modf, stats force
scalar `lrtchi' = r(chi2)
scalar `lrtpchi'= 0.5 * r(p)
scalar `lrtdf' = r(df)
return scalar lrtchi = r(chi2)
return scalar lrtpchi= 0.5 * r(p)
return scalar  lrtdf = r(df)
homogeni `lrtchi' `lrtdf'
return scalar Islrt = r(Isq)
return scalar Islrtlo = r(Isqlo)
return scalar Islrthi = r(Isqhi)
}

end


program homogeni, rclass

syntax anything [, Level(int 95) Format(string) ]

tempname Q K df I2 I22 varI2 lb_I2 ub_I2 levelci 
tokenize "`anything'"
scalar `Q' = `1'
scalar `df' = `2'
scalar `K' = `df' + 1


if `level' <10 | `level'>99 { 
 di in red "level() invalid"
 exit 198
}   

scalar `levelci' = `level' * 0.005 + 0.50

if "`format'" == "" { 
 local formatI2 = "%4.2f"
 local formatH = "%4.2f"
}   
else {
 local formatI2 = "`format'"
 local formatH = "`format'"
}

preserve
tempname varI2 lb_I2 ub_I2 
scalar H2 = `Q' / `df'
scalar I2 = max(0, (100*(`Q' -`df')/(`Q' )) )
scalar I22 = max(0, (H2-1)/H2)
if sqrt(H2) < 1 scalar H2 = 1
if `Q' > `K'  {
 scalar SElnH1 = .5*[(log(`Q')-ln(`df')) / ( sqrt(2*`Q') - sqrt(2*`K'-3) )]
}
else {
 scalar SElnH1 = sqrt( ( 1/(2*(`K'-2) )*(1-1/(3*(`K'-2)^2)) )  )
}
scalar `varI2'  = 4*SElnH1^2/exp(4*log(sqrt(H2)))
scalar `lb_I2' = I22-invnorm(`levelci')*sqrt(`varI2')
scalar `ub_I2' = I22+invnorm(`levelci')*sqrt(`varI2')

if  `lb_I2' < 0 {
 scalar  `lb_I2' = 0
}
else scalar `lb_I2' = `lb_I2'
if  `ub_I2' > 1 {
 scalar  `ub_I2' = 1
}
else scalar `ub_I2' = `ub_I2'

return scalar Isq = min(100, 100 * I22)
return scalar Isqlo = max(0, 100 * `lb_I2')
return scalar Isqhi = min(100, 100 * `ub_I2')
return scalar df = `df'
return scalar Q = `Q'

end


program define quadas, sortpreserve
version 9
syntax varlist(min=2) [if] [in] [, LABvar(string) qtable qgraph *] 
qui {
preserve
marksample touse, novarlist
keep if `touse'
}

tokenize `varlist'
qui{
tempfile qualires
tempname qualifile
postfile `qualifile' str40 Criterion Yes No Yes_percent No_percent using qualires, replace
foreach var in `varlist' {
count 
local totalvar = r(N)
count if `var' == 1
local yesvar = r(N)
count if `var' == 0
local novar = r(N)
local yes_cent = (`yesvar'/`totalvar') * 100
local no_cent = (`novar'/`totalvar') * 100

if "`labvar'" != "" {
local critvar : variable label `var'
post `qualifile' ("`critvar'") (`yesvar') (`novar') (`yes_cent') (`no_cent')
}
else { 
post `qualifile' ("`var'") (`yesvar') (`novar') (`yes_cent') (`no_cent')
}
} 
postclose `qualifile'
postutil clear
use qualires, clear
summarize Yes
}
local N = r(N)
if "`qtable'"=="qtable" {
di as text "{title: METHODOLOGICAL QUALITY ASSESSMENT}"
di " "
di as text"{hline 83}"
di as text _col(2) "Criterion" _col(44)  "{c |}"  _col(48) "Yes" _col(54) "Yes(%)" _col(64) "No" _col(72) "No(%)"
di as text"{hline 43}{c +}{hline 39}"
local i = 1
while `i' <= `N' {            
local a1 = Criterion in `i' 
local b1 = Yes in `i'
local c1 = Yes_percent  in `i'
local d1 = No  in `i'
local e1 = No_percent  in `i'
di as text _col(2)  "`a1'" _col(44) in gr "{c |}" as result _col(45) %6.0f `b1' _col(50) %6.0f `c1' _col(60) %6.0f `d1' _col(68) %6.0f `e1'
local i=`i'+1
}
di as text"{hline 43}{c BT}{hline 39}"
}
if "`qgraph'"=="qgraph" {
#delimit;
graph hbar (asis) Yes No, over(Criterion, sort(Total) descending) 
nolab  bar (1, fcolor(gs0)) bar(2, fcolor(gs16)) legend(rows(1) position(6))
stack percent title("BAR GRAPH OF QUALITY ASSESSMENT", size(*.75)) lintensity(*.50) ysize(`vsize');
#delimit cr 
}
end

program fagani, rclass
version 9
syntax anything, [ *]

tempname prev lrp lrn sens spec
qui{

	tokenize "`anything'"
	scalar `prev' = `1'
	scalar `lrp' = `2'
	scalar `lrn' = `3'
	local prprob = logit(1-`prev')
	local postprob1 = logit(`prev') + log(`lrp')
	local postprob2 = logit(`prev') + log(`lrn')


foreach p in 0.1 0.2 0.3 0.5 0.7 1 2 3 5 7 10 ///
20 30 40 50 60 70 80 90 93 95 97 98 99  99.3 99.5 99.7 99.8 99.9 {   
         local ylab `"`ylab' `=ln(`p' / (100 - `p'))' "`p'" "'
}
foreach lr in 0.001 0.002 0.005 0.01 0.02 0.05 0.1 0.2 0.5 1 2 5 10 20  ///
               50 100 200 500 1000 {
         local lrpts `"`lrpts' `=-.5*ln(`lr')' 0 "`lr'" "'
}

	local priorprob = 100*`prev' 
	local postprobpos = 100*invlogit(`postprob1')
	local postprobneg = 100*invlogit(`postprob2')

	local notebb1: di "Prior Prob (%) = " %5.0f `priorprob' "
	local notebb2: di "LR_Positive = " %5.0f `lrp' "
	local notebb3: di "Post_Prob_Pos (%) =" %5.0f `postprobpos' "
	local notebb4: di "LR_Negative = " %5.2f `lrn' "
	local notebb5: di "Post_Prob_Neg (%) = " %5.0f `postprobneg' "

#delimit;
tw (scatteri 0 0, mcolor(none) yaxis(1) ylab(`ylab', angle(0) 
tpos(cross)) yscale(reverse axis(1)) ytitle("Pre-test Probability (%)", axis(1)))
(scatteri 0 0, mcolor(none) yaxis(2) ylab(`ylab', angle(0) tpos(cross) axis(2))
 ytitle("Post-test Probability (%)", axis(2)))
(scatteri `lrpts', msymbol(+) mcolor(black) mlabcolor(black) mlabsize(medsmall))
(pci -3.4538776 0 3.4538776 0, recast(pcspike) lcolor(black) 
xscale(range(-1 1)) plotregion(margin(zero)) xsize(4) ysize(6)
xscale(off) ylab(, nogrid) text(-4 0 "Likelihood Ratio", place(n)))
(scatteri `prprob' -1, msym(D) yaxis(2))(pcarrowi `prprob' -1 `postprob1' 1,
 yaxis(2) lpat(solid) lwidth(vthin))(pcarrowi `prprob' -1 `postprob2' 1, 
 yaxis(2) lpat(dash) lwidth(thin)),subt(Fagan's Nomogram) 
 legend(order(5 "`notebb1'" 6 "`notebb2'" "`notebb3'" 7 "`notebb4'"
 "`notebb5'") pos(6) col(1)  rowgap(2) size(*.90)) name(faganplot, replace); 
#delimit cr 
}
end                                                                
               
program pddami, rclass
version 9
syntax anything, [SUM1(numlist min=3 max=3) SUM2(numlist min=3 max=3) C1(real 0) C2(real 1.0) LEVEL(integer 95) REPort PLOT*]
	tempname contpr contprse contprlo contprhi 
	tempname contnr contnrse contnrlo contnrhi  
	tempname sigma1 uppv uppvlo uppvhi 
	tempname sigma2 unpv unpvlo unpvhi

	qui{
	tokenize "`anything'"
	scalar `contpr' = `1'
	scalar `contprse' = `2'
	scalar `contnr' = `3'
	scalar `contnrse' = `4'
	
	tokenize `sum1'
          local convar1 `1' 
          local convar1lo `2'
          local convar1hi `3'
          tokenize `sum2'
          local convar2 `1' 
          local convar2lo `2'
          local convar2hi `3'


       	if `level' < 10 | `level' > 99 {
	di as error "level() must be between 10 and 99"
	exit 198
		}
          
          if `c1' < 0 | `c2' > 1.0 {
	di as error "c1-c2 must be between 0 and 1"
	exit 198
		}
		
          if `c1' > `c2' {
	di as error "c1 must always be less than c2 must be between 0 and 1"
	exit 198
		}
          
          local alph = (100-`level')/200
          tempvar PPP1 PPN1 x1 x2
          twoway__function_gen y= `convar1' * x/(1- x * (1 - `convar1')), r(0 1) x(x) gen(`PPP1' `x1', replace) n(`c(N)') 
          twoway__function_gen y= `convar2' * x /(1 - x * (1 - `convar2')), r(0 1) x(x) gen(`PPN1' `x2', replace) n(`c(N)') 
          local note1a: di "LR+ =" %4.2f `convar1' " [" %4.2f `convar1lo' " - " %4.2f `convar1hi' "]"               
          local note2a: di "LR- =" %4.2f `convar2' " [" %4.2f `convar2lo' " - " %4.2f `convar2hi' "]"
 

 if "`plot'" == "plot" {
          #delimit;
	nois twoway (line `PPP1' `x1', sort clpat(dash) clwidth(medium) connect(direct ) clcolor(black))
	(line `PPN1' `x2', sort clpat(shortdash_dot) clcolor(black) clwidth(medium) connect(direct ))
 	(function y=x, sort range(0 1)clcolor(black) clpat(solid) clwidth(vthin) connect(direct)), 
 	ytitle("Posterior Probability", size(*.90)) yscale(range(0 1))
 	ylabel( 0(.2)1,  angle(horizontal) format(%3.1f)) xtitle("Prior Probability", size(*.90)) 
 	xscale(range(0 1)) xlabel(0(.2)1, format(%3.1f)) legend(order(1 "Positive Test Result" 
 	"`note1a'" 2 "Negative Test Result" "`note2a'") pos(6) colgap(1) row(1) size(*.75)) 
 	aspect(1) title("Conditional Probability Plot", size(*.75)) plotregion(margin(zero));
	#delimit cr

}
          
          *estimate unconditional positive or negative predictive values and the 95% confidence intervals 
          *assuming Uniform distribution for prior from zero to one. 
          *It can be easily adjusted for other uniform priors (by modifying the values of `c1' and `c2')

	scalar `contprlo' = `contpr'-invnorm(1-`alph')*`contprse'
	scalar `contprhi' = `contpr'+invnorm(1-`alph')*`contprse'
	scalar `contnrlo' = `contnr'-invnorm(1-`alph')*`contnrse'
	scalar `contnrhi' = `contnr'+invnorm(1-`alph')*`contnrse'

   	scalar `uppv' = `contpr'/(`contpr'+`contnr'-1)-`contpr'*(1-`contnr')*log((`c2'*`contpr'+(1-`c2')*(1-`contnr'))/(`c1'*`contpr'+(1-`c1')*(1-`contnr')))/((`c2'-`c1')*(`contpr'+`contnr'-1)^2)
   	scalar `sigma1' = (1/(`contpr'+`contnr'-1)^4)*((`contprse')^2*(`contnr'-1-`contpr'*(1-`contnr')^2/((`c2'*`contpr'+(1-`c2')*(1-`contnr'))*(`c1'*`contpr'+(1-`c1')*(1-`contnr')))-((1-`contnr')*(`contnr'-1-`contpr')/((`c2'-`c1')*(`contnr'-1+`contpr')))*log((`c2'*`contpr'+(1-`c2')*(1-`contnr'))/(`c1'*`contpr'+(1-`c1')*(1-`contnr'))))^2+(`contnrse')^2*(-`contpr'-(`contpr'^2)*(1-`contnr')/((`c2'*`contpr'+(1-`c2')*(1-`contnr'))*(`c1'*`contpr'+(1-`c1')*(1-`contnr')))+(`contpr'*(`contpr'-`contnr'+1)/((`c2'-`c1')*(`contpr'+`contnr'-1)))*log((`c2'*`contpr'+(1-`c2')*(1-`contnr'))/(`c1'*`contpr'+(1-`c1')*(1-`contnr'))))^2)
   	scalar `uppvlo' = `uppv'-invnorm(1-`alph')*sqrt(`sigma1')
   	scalar `uppvhi' = `uppv'+invnorm(1-`alph')*sqrt(`sigma1')
     
   	scalar `unpv' = `contnr'/(`contpr'+`contnr'-1)-`contnr'*(1-`contpr')*log(((1-`c1')*`contnr'+`c1'*(1-`contpr'))/((1-`c2')*`contnr'+`c2'*(1-`contpr')))/((`c2'-`c1')*(`contpr'+`contnr'-1)^2)
	scalar `sigma2' = (1/(`contnr'+`contnr'-1)^4)*((`contnrse')^2*(`contnr'-1-`contnr'*(1-`contnr')^2/((`c2'*`contnr'+(1-`c2')*(1-`contnr'))*(`c1'*`contnr'+(1-`c1')*(1-`contnr')))-((1-`contnr')*(`contnr'-1-`contnr')/((`c2'-`c1')*(`contnr'-1+`contnr')))*log((`c2'*`contnr'+(1-`c2')*(1-`contnr'))/(`c1'*`contnr'+(1-`c1')*(1-`contnr'))))^2+(`contnrse')^2*(-`contnr'-(`contnr'^2)*(1-`contnr')/((`c2'*`contnr'+(1-`c2')*(1-`contnr'))*(`c1'*`contnr'+(1-`c1')*(1-`contnr')))+(`contnr'*(`contnr'-`contnr'+1)/((`c2'-`c1')*(`contnr'+`contnr'-1)))*log((`c2'*`contnr'+(1-`c2')*(1-`contnr'))/(`c1'*`contnr'+(1-`c1')*(1-`contnr'))))^2) 
   	scalar `unpvlo' = `unpv'-invnorm(1-`alph')*sqrt(`sigma2')
   	scalar `unpvhi' = `unpv'+invnorm(1-`alph')*sqrt(`sigma2')
   	
   	*returned results
   	return scalar contpr = `contpr'
   	return scalar tprlo = `contprlo'
	return scalar tprhi =  `contprhi'
	return scalar contnr = `contnr'
	return scalar tnrlo = `contnrlo'
	return scalar tnrhi = `contnrhi'
   	return scalar uppv = `uppv' 
  	return scalar uppvlo = max(0, `uppvlo')
  	return scalar uppvhi = min(1.00, `uppvhi')
  	return scalar unpv = `unpv' 
  	return scalar unpvlo = max(0, `unpvlo')
  	return scalar unpvhi = min(1.00, `unpvhi')
  	return scalar c1 = `c1'
  	return scalar c2 = `c2'

  	if "`report'" == "report" {
  	nois di ""
	nois di as txt "Prior Prevalence = Uniform [" as res %3.2f return(c1) "," as res %3.2f return(c2) as text"]"
          nois di "" 
	nois di as txt "Unconditional Positive Predictive Value= "as res %3.2f return(uppv) _c
          nois di as txt ", 95% CI = ["as res %3.2f return(uppvlo)                _c
          nois di as txt "-"as res %3.2f return(uppvhi) as txt"]"               _n
          nois di ""
          nois di as txt "Unconditional Negative Predictive Value= "as res %3.2f return(unpv) _c
          nois di as txt ", 95% CI = ["as res %3.2f return(unpvlo)                _c
          nois di as txt "-"as res %3.2f return(unpvhi) as txt"]"               _n
          }

}
end
program bvbox, sortpreserve 
	version 9   
	syntax varlist(numeric min=2 max=2) [if] [in][, smooth(str asis) data(str asis) `options' *] 
	
	// observations to use 
	marksample touse 
		
	tempvar use diff sum diff1 sum1 work theta radius radius1 sm order 
          tempname ymed ymad xmed xmad dmad smad
	
	// variables set-up 
	tokenize `varlist' 
	args y x 
	
	quietly { 
		// initialize 
		gen `work' = . 
		gen byte `use' = . 
		gen `diff' = . 
		gen `sum' = . 
		gen `radius' = . 
		gen `diff1' = . 
		gen `sum1' = . 
		gen `radius1' = .
		gen `theta' = . 
		gen `order' = . 		
					
		rreg `x' `y'
                    predict xpredict 
                    rreg `y' `x'
                    predict ypredict 
                    local ypred "(line ypredict `x', lpat(dash) lc(black) lw(thin))"
                    local xpred "(line `y' xpredict, lpat(dash) lc(black) lw(thin))"  
		tempvar s sx S SX s1 S1  sx1 SX1
 
		replace `use' = `touse' & `y' < . 
			
		// y <- (y - median y) / MAD y 
		mata : median("`y'", "`use'")  
		scalar `ymed' = r(p50)
                    replace `work' = abs(`y' - `ymed') if `use' 
		mata : median("`work'", "`use'")  
		scalar `ymad' = r(p50)
                    clonevar `s' = `y' 
		if `"`: variable label `s''"' == "" label var `s' "`y'"
		replace `s' = (`y' - `ymed') / `ymad' if `use' 
		
		// x <- (x - median x) / MAD x 
		mata : median("`x'", "`use'") 
		scalar `xmed' = r(p50) 
		replace `work' = abs(`x' - `xmed') if `use' 
		mata : median("`work'", "`use'")  
		scalar `xmad' = r(p50)
		gen `sx' = (`x' - `xmed') / `xmad' if `use' 
		
		// (y - x), (y + x) scaled to z / MAD z 
		replace `diff' = `s' - `sx' if `use' 
		mata : median("`diff'", "`use'")  
		replace `work' = abs(`diff' - r(p50)) 
		mata : median("`work'", "`use'")  
		scalar `dmad' = r(p50)
		replace `diff' = `diff' / `dmad'
		
		replace `sum' = `s' + `sx' if `use' 
		mata : median("`sum'", "`use'")  
		replace `work' = abs(`sum' - r(p50))
		mata : median("`work'", "`use'")  
		scalar `smad' = r(p50)
		replace `sum' = `sum' / `smad'

		// radius = cube root of sum^2 + diff^2 
		// theta = arctan of diff / sum 
		replace `radius' = sqrt(`sum'^2 + `diff'^2)
		replace `radius' = `radius'^(2/3)
		replace `theta' = atan2(`diff', `sum')   

		local sc  
		tempvar S C
		gen `S' = sin(`theta') 
		gen `C' = cos(`theta') 
		local sc `sc' `S' `C'
			 
		capture regress `radius' `sc' if `use' 
		if _rc gen `sm' = . if `use' 
		else predict `sm' if `use' 

		drop `sc' 
			
		// reverse transformation, (x, y) coordinates, scale 
		replace `radius' = `sm'^(3/2)
		replace `radius1' = 1.58 * `sm'^(3/2)
		drop `sm' 
		replace `diff' = `dmad' * `radius' * sin(`theta')
		replace `sum' = `smad' * `radius' * cos(`theta')
		replace `sx' = `xmed' + `xmad' * (`sum' - `diff')/2
		replace `s' = `ymed' + `ymad' * (`sum' + `diff')/2
		replace `diff1' = `dmad' * `radius1' * sin(`theta')
		replace `sum1' = `smad' * `radius1' * cos(`theta')
		gen `sx1' = `xmed' + `xmad' * (`sum1' - `diff1')/2
		gen `s1' = `ymed' + `ymad' * (`sum1' + `diff1')/2


		// sort order and end points for closing loop 
		bysort `use' (`theta') : replace `order' = _n if `use' 
		count if !`use'
		local first = 1 + r(N) 
		gen `SX' = `sx' in `first' 
		gen `S' = `s' in `first' 
		replace `SX' = `sx' in l 
		replace `S' = `s' in l 
		gen `SX1' = `sx1' in `first' 
		gen `S1' = `s1' in `first' 
		replace `SX1' = `sx1' in l 
		replace `S1' = `s1' in l 
                   
                    local hshade "fcolor(gs12) nodropbase recast(area)"
                    local fshade "fcolor(gs14) nodropbase recast(area)"
                    local clpcw1 "clpat(solid) clc(black) clw(thin)"
                    local clpcw2 "clpat(dash) clc(black) clw(thin)"
                    
                    
		// construct graph call 
		// line plot of smooth 
		local l "(line `s' `sx', `clpcw1' `hshade' `smooth')" 
		local l1 "(line `s1' `sx1', `clpcw2' `fshade' `smooth')"
		// line plot to close loop 
		local p	"(line `S' `SX', `clpcw1' `hshade' `smooth')" 
		local p1	"(line `S1' `SX1', `clpcw2' `fshade' `smooth')" 
			
		// scatter of data 
		local d "(scatter `y' `x' if `touse', ms(+) `data')"  
		                               
                    local call "`call'  `l1' `p1' `l' `p' `d' `xpred' `ypred'" 		
	

	local off "legend(off)" 
	
	// final graph preparation 
	sort `order' 
	local yttl : variable label `y' 
	if `"`yttl'"' == "" local yttl "`y'" 
	local xttl : variable label `x' 
	if `"`xttl'"' == "" local xttl "`x'" 

	// graph 
	#delimit;
    	twoway `call', ti("Bivariate Boxplot", size(*.75)) yti(`"`yttl'"') xti(`"`xttl'"') 
	legend(order(`show')) plotregion(margin(zero)) `off' `options';
	#delimit cr
}
end



mata : 
void median(string scalar varname, string scalar which) 
{ 
	real scalar L, U 
	real matrix X
	
	st_view(X, ., varname, which) 
	X = sort(X,1)
	L = ceil(rows(X) / 2) 
	U = floor((rows(X) + 2) / 2) 
	 
	st_numscalar("r(p50)", (X[L,1] + X[U,1]) / 2) 
}
end 

   

program define midachi
version 9

syntax varlist(num min=2 max=2)[if][in][, *]
marksample touse
tokenize `varlist'
local chivar1 `1'
local chivar2 `2'
qui {
tempvar ry rx Hi Fi Gi Si CHIi Li
 * Gi
 egen `ry' = rank(`chivar1'), field
 gsort -`ry'
 gen `Gi' = (_N - `ry') / (_N - 1)
 * Fi
 egen `rx' = rank(`chivar2'), field
 gsort -`rx'
 gen `Fi' = (_N - `rx') / (_N - 1)
 * Hi
 sort `ry'
  by `ry': replace `ry' = _N 
 sort `chivar1'
 tempname xi
 gen `Hi' = 0
 local r1 = 1
 local N = _N 
 forvalues i = 1 / `N' { 
  if `chivar1'[`i'] == `chivar1'[`i'-1] {
 local r1 = `r1' + 1
 }
    else {
 local r1 = 1 
}
    local k = min(`N', `i' + `ry'[`i'] - `r1')
    scalar `xi' = `chivar2'[`i']
    count if `chivar2' <= `xi' & _n != `i' in 1/`k'
    replace `Hi' = r(N) in `i'       
 }
 replace `Hi' = `Hi' / (_N - 1)
 * Si, CHIi, Li
  gen `Si'   = sign((`Fi' - .5)*(`Gi' - .5))
 gen `CHIi' = (`Hi' - `Fi'*`Gi') / (`Fi'*(1 - `Fi')*`Gi'*(1 - `Gi'))^.5
 gen `Li'   = 4 * `Si' * max((`Fi' - .5)^2, (`Gi' - .5)^2)  
 label var `CHIi' "CHI"
 label var `Li' "LAMDA"
 
    
 spearman `chivar1' `chivar2'
 local r = r(rho)
 local note: di "rho = " %3.2f `r' "

*Scatterplot 
#delimit;
twoway (scatter `chivar1' `chivar2', ms(o) msize(medium))(lfit `chivar1' `chivar2'), 
name(splot, replace) title(ScatterPlot (`note')) plotregion(margin(zero)) legend(off) nodraw `options';
#delimit cr 

* cp lines
 
 local cp = 1.78 
 local cphi = `cp' / sqrt(_N)
 local cplo= -`cp' / sqrt(_N)

*chi-plot

#delimit;
twoway (scatter `CHIi' `Li', ms(S) msize(*`mscale')), yline(`cplo' `cphi', lpat(solid) lwidth(vvthin)) 
yline(0, lpat(dash) lwidth(vvthin)) xline(0, lpat(dash) lwidth(vvthin)) 
xla(-1(0.5)1) yla(-1(.5)1) title(ChiPlot) plotregion(margin(zero)) nodraw name(cplot, replace) `options';
#delimit cr
nois graph combine splot cplot, xsize(`hsize') ysize(`vsize')       
}

end

program define lrmat, rclass byable(recall) sortpreserve
version 9

syntax varlist(min=2 max=2) [if] [in] , SUM1(numlist min=3 max=3) SUM2(numlist min=3 max=3)[ *]


tokenize `varlist'
local var1 `1'
local var2 `2'    
tokenize `sum1'
local mvar1 `1' 
local mvar1lo `2'
local mvar1hi `3'
tokenize `sum2'
local mvar2 `1' 
local mvar2lo `2'
local mvar2hi `3'
 
qui{
local note11: di "LUQ: Exclusion & Confirmation"
local note11b: di "LRP>10, LRN<0.1"
local note12: di "RUQ: Confirmation Only"
local note12b: di "LRP>10, LRN>0.1"
local note13: di "LLQ: Exclusion Only"
local note13b: di "LRP<10, LRN<0.1"
local note14: di "RLQ: No Exclusion or Confirmation"
local note14b: di "LRP<10, LRN>0.1"
               
#delimit;
nois twoway (scatter `var1' `var2', sort msymbol(Oh) msize(small) mcolor(black))
(scatteri `mvar1' `mvar2', msymbol(D) msize(large) clcol(black) clwidth (medium))
(scatteri `mvar1' `mvar2lo' `mvar1' `mvar2hi', recast(line) clcol(black) clpat(solid) clwidth (medium))
(scatteri `mvar1lo' `mvar2' `mvar1hi' `mvar2', recast(line) clcol(black) clpat(solid) clwidth (medium)), 
xtitle("Negative Likelihood Ratio", size(*.90)) xsc(log) xlab(0.1 "0.1"  1) 
xmticks(.02(0.01).09 .2(.1).9) ylab(1 10 100, angle(horizontal))ymticks(2(1)9 20(10)90) 
xline(0.1, lpattern(shortdash) lwidth(vthin)) ytitle("Positive Likelihood Ratio", size(*.90))
 ysc(log) yline(10, lpattern(shortdash) lwidth(vthin)) title(Likelihood Ratio Scattergram, size(*.90)) 
 legend(order(3 "`note11'"  "`note11b'"  "`note12'" "`note12b'" 4 "`note13'"  "`note13b'"  "`note14'" 
  "`note14b'" 2 "Summary LRP & LRN for Index Test" "With `level' % Confidence Intervals") 
 pos(2) symxsize(0) forcesize rowgap(1) col(1) size(*.75)) xsize(`hsize') plotregion(margin(zero)) 
name(ScatterMatrix, replace); 
#delimit cr
}
end

 

program midareg, rclass sortpreserve byable(recall)
version 9
syntax varlist(min=4) [if] [in], [ NIP(integer 15) LEVEL(integer 95) *] 

qui {
preserve
marksample touse, novarlist
keep if `touse'
}
tokenize `varlist'
local tp `1'
local fp `2'
local fn `3'
local tn `4'
macro shift 4
local varlist2 `*'

if "`varlist2'" =="" {
di as error " covariate varlist must be used with covars" 
exit 198
}		


/* MIXED EFFECTS ESTIMATION */

qui {
local alph = (100-`level')/200
local ctitle1 "Sensitivity"
local ctitle2 "Specificity"

gen ctruth1 = `tn'                  
gen ctruth2 = `tp'                   
gen cnum1 = `tn'+`fp'                   
gen cnum2 = `tp'+`fn'                      
gen cstudy = _n
reshape long cnum ctruth, i(cstudy) j(cdtruth) string
tabulate cdtruth, generate(cdisgrp)

tempname covfile
tempfile covresults
postfile `covfile' str30 Parameter coef1 cVAR1 cVAR1lo cVAR1hi z1 p1 coef2 cVAR2 cVAR2lo cVAR2hi /*
*/ z2 p2 LRTCHI LRTPCHI I2 I2lo I2hi using covresults, replace
xtmelogit (ctruth cdisgrp1 cdisgrp2, noc)(cstudy: cdisgrp1 cdisgrp2, noc cov(unstr)), bin(cnum) intp(`nip')
estimates store mod0
foreach var in `varlist2' {
   local varlab "`var'"
   su `var', meanonly
   replace `var'= `var'-r(mean) if r(mean)>1
   forvalues i=1/2 {
     g `var'_`i' = cdisgrp`i'*`var'
   }
nois di " "
nois di " "
nois di in gr "Estimating Covariate Effect Of: " in white " `varlab'"
nois di " "
gllamm ctruth cdisgrp1 cdisgrp2 `var'_1 `var'_2, nocons i(cstudy) nrf(2) eqs(cdisgrp1 cdisgrp2) ///
f(bin) l(logit) denom(cnum) from(a) lf0(`k' `l') adapt ip(m) nip(`nip')

estimates store mod`var'
nlcom (csens: _b[cdisgrp2] + _b[`var'_2]) /*
*/(csens0: _b[cdisgrp2]) /*
*/(cspec: _b[cdisgrp1] + _b[`var'_1]) /*
*/(cspec0: _b[cdisgrp1]), post

local coef2 = _b[cspec]
local cvar2= invlogit(_b[cspec])
local cvar2se=_se[cspec]
local cvar2lo=invlogit(_b[cspec]-invnorm(1-$alph) * _se[cspec])
local cvar2hi=invlogit(_b[cspec] + invnorm(1-$alph) * _se[cspec])
local coef1 = _b[csens]
local cvar1= invlogit(_b[csens])
local cvar1se=_se[csens]
local cvar1lo=invlogit(_b[csens]- invnorm(1-$alph) * _se[csens])
local cvar1hi= invlogit(_b[csens] + invnorm(1-$alph) * _se[csens])
local z_cov2=(_b[cspec]-_b[cspec0])/sqrt((_se[cspec]^2) + (_se[cspec0]^2))
if `z_cov2' <=0{
local p_cov2=2*normal(`z_cov2')
}
else {
local p_cov2=2*(1-normal(`z_cov2'))
}
local z_cov1=(_b[csens]-_b[csens0])/sqrt((_se[csens]^2) + (_se[csens0]^2))
if `z_cov1' <=0{
local p_cov1=2*normal(`z_cov1')
}
else {
local p_cov1=2*(1-normal(`z_cov1'))
}
qui lrtest mod0 mod`var', stats force
local LRTchi = r(chi2)
local LRTpchi = r(p)
local LRTdf = r(df)
homogeni `LRTchi' `LRTdf'
scalar I2 = r(Isq)
scalar I2lo = r(Isqlo)
scalar I2hi = r(Isqhi)
post `covfile' ("`var'") (`coef1') (`cvar1') (`cvar1lo') (`cvar1hi') (`z_cov1') (`p_cov1') ///
(`coef2') (`cvar2') (`cvar2lo') (`cvar2hi') (`z_cov2') (`p_cov2') (`LRTchi') (`LRTpchi') ///
(I2) (I2lo) (I2hi)
 }
postclose `covfile'
postutil clear
use covresults, clear
format coef1 z1 p1 cVAR1 cVAR1lo cVAR1hi coef2 z2 p2 cVAR2 cVAR2lo cVAR2hi LRTCHI LRTPCHI I2 I2lo I2hi  %7.2f
format Parameter %-30s
foreach var of varlist cVAR1 cVAR2 I2 {
tostring `var'lo `var' `var'hi, gen(`var'lo1 `var'1 `var'hi1) format(%7.2f) force
replace `var'lo1=" " + "[" + `var'lo1 +" - "
replace `var'hi1= `var'hi1+ "]"
egen `var'_ci= concat(`var'1 `var'lo1 `var'hi1) 
format `var'_ci %50s force
}
nois di ""
summarize p1
local N = r(N)
nois di ""
nois di ""
nois di ""
nois di as text "`ctitle1'"
nois di ""
nois di as text"{hline 78}"
nois di as text _col(2) "Parameter" _col(20)  "{c |}"  _col(24) "Estimate(95%CI)" _col(50) "Coef" _col(60) "Z" _col(70) "P>|z|" 
nois di as text"{hline 19}{c +}{hline 59}"
local i = 1
while `i' <= `N' {            
local a1 = Parameter in `i' 
local b1 = cVAR1_ci in `i'
local c1 =  coef1 in `i'
local d1 = z1  in `i'
local e1 = p1  in `i'
nois di as text _col(2)  "`a1'" _col(20) in gr "{c |}" as result _col(22)  "`b1'" _col(48) %6.2f `c1' _col(58) %6.2f `d1' _col(68) %6.2f `e1'
local i=`i'+1
}
nois di as text"{hline 19}{c BT}{hline 59}"
nois di ""
nois di ""
nois di ""
nois di as text "`ctitle2'"
nois di ""
nois di as text"{hline 78}"
nois di as text _col(2) "Parameter" _col(20)  "{c |}"  _col(24) "Estimate(95%CI)" _col(50) "Coef" _col(60) "Z" _col(70) "P>|z|"
nois di as text"{hline 19}{c +}{hline 59}"
local i = 1
while `i' <= `N' {            
local a1 = Parameter in `i' 
local b1 = cVAR2_ci in `i'
local c1 =  coef2 in `i'
local d1 = z2  in `i'
local e1 = p2  in `i'
nois di as text _col(2)  "`a1'" _col(20) in gr "{c |}" as result _col(22) "`b1'" _col(48) %6.2f `c1' _col(58) %6.2f `d1' _col(68) %6.2f `e1'
local i=`i'+1
}
nois di as text"{hline 19}{c BT}{hline 59}"
nois di ""
nois di ""
nois di ""
nois di "Joint Model"
nois di ""
nois di as text"{hline 78}"
nois di as text _col(2) "Parameter" _col(20)  "{c |}"  _col(24) "I-squared(95%CI)" _col(50) "LRTChi" _col(60) "P value"
nois di as text"{hline 19}{c +}{hline 59}"
local i = 1
while `i' <= `N' {            
local a1 = Parameter in `i' 
local b1 = I2_ci in `i'
local c1 =  LRTCHI in `i'
local d1 = LRTPCHI  in `i'
nois di as text _col(2)  "`a1'" _col(20) in gr "{c |}" as result _col(22) "`b1'" _col(48) %6.2f `c1' _col(58) %6.2f `d1'
local i=`i'+1
}
nois di as text"{hline 19}{c BT}{hline 59}" 
}    

end


program define metanorm
version 9.0

// Setup
syntax varlist(numeric min=2 max=2) [if] [in] ///
       [ , Title(str) ID(varname) LEvel(real 95) XTitle(string) YTitle(string) * ]

tokenize `varlist'
tempvar theta setheta

local theta `1'
local setheta `2'
  
tempvar yq z psubi obs nobs normal normse normallo normalhi 
tempname kurtvar skewvar pchi
     qui {
     gen `yq'= `theta'/`setheta'
     label var `yq' "Effect Size"
     sort `yq'
     local xmax=r(max)
     gen `obs'=_n
     gen `nobs'=_N
     gen double `psubi'=(`obs'-0.5)/`nobs'
     gen `z'=invnormal(`psubi')
     label var `z' "Normal Quantile"
     sum `yq', detail
     local sd=r(sd)
     local ymean=r(mean)
     gen double `normal'=`ymean' + `z' * `sd'
     gen double `normse'=(`sd'/((1/sqrt(8 * atan(1)))*exp(-0.5 * `z' * `z')))* sqrt(`psubi' * (1-`psubi')/`nobs')
     gen double `normallo'=`normal'-2*`normse'
     gen double `normalhi'=`normal'+2*`normse'
  	}
  
     qui sktest `yq'
     scalar `skewvar' =r(P_skew)
     scalar `kurtvar' =r(P_kurt)
     scalar `pchi' =r(P_chi2)
     di as text "TESTING NORMALITY ASSUMPTIONS" 
     di ""
     di ""
     di as text "Skewness Test: pvalue = " as result %4.3f `skewvar'
     di ""
     di ""
	di as text "Kurtosis Test: pvalue = " as result %4.3f `kurtvar'
     di ""
     di ""
	di as text "Kurtosis/Skewness Test: pvalue = " as result %4.3f `pchi'

     twoway (scatter `yq' `z', sort ms(O))(line `normal' `normallo' `normalhi' `z', clpat(solid dash dash) clwidth(medium medium medium)),  /*
     */ legend(off) ytitle("Standardized Effect Size", size(medsmall)) plotregion(margin(zero)) /* 
     */ylab(,  angle(horizontal) format(%7.0f)) xtitle("Normal Quantile", size(medsmall)) `options'   

end

program define midagalb
version 9.0

	syntax varlist(numeric min=2 max=2) [if] [in] ///
       [ , Title(str) ID(varname) LEvel(real 95) XTitle(string) YTitle(string) * ]

	tokenize `varlist'
	tempvar theta setheta

	local theta `1'
	local setheta `2'
qui {
        tempvar x y 
        su `theta',detail        
        local emax=r(max)
        local emay=r(min)
        gen `x' = 1 / `setheta'
        su `x' , detail
        local maxx = r(max) 
        gen `y' = `theta'/`setheta' 
        reg `y' `x', noconstant  

    local galbropts " yscale(r(-2 2) noline) ylab(-2 2,angle(horizontal) nogrid )"  
    local yaxis2 " ysc(r(`emay' `emax') fex)  yti("Unstandardized effect size",  axis(2)) ylab(`emay'(1.0)`emax', angle(horizontal) format(%7.1f) axis(2))"
  } 
#delimit; 
    twoway(scatter `y' `x', `show' `scatter')(scatteri -2 0 2 0, s(i) recast(line)) 
    (function fitted = _b[`x'] * x, ra(0 `maxx') `fitted') (function upper = 2 + _b[`x'] * x, ra(0 `maxx') 
	clp(dash) clc(green) `upper' )(function lower = -2 + _b[`x'] * x, ra(0 `maxx')
    clp(dash) clc(green) `lower')(scatter `theta' `x', s(i)  `scatter' yaxis(2)) 
    , legend(off)  yti("standardized effect size",) xti("precision") yline(0, lpat(shortdash)) 
	`galbropts' `yaxis2' plotregion(margin(zero)) `options' ;
#delimit cr
 end 
  
program define copas, sortpreserve
version 9
syntax varlist(min=2 max=2) [if] [in] [, *] 
qui {
preserve
marksample touse, novarlist
keep if `touse'
}
tokenize `varlist'
local y `1'
local yse `2'
qui {
postutil clear
postfile biasfile nstudies maxbias using biasresults, replace
local N = _N
egen sumvar = total(`yse'^-2)
local sumvar = sumvar
egen sumsvar = total(`y' * `yse'^-2)
local sumsvar = sumsvar
egen sumse = total(1/`yse')
local sumse = sumse
scalar upbias = abs(sumsvar/sumvar) - (1.96/sqrt(sumvar))
display upbias
gen maxbias=.
forvalues M = 1/1000 {
gen b`M' = ((_N + `M')/_N) * normalden(invnormal(_N /(_N+ `M'))) * (sumse/sumvar)
replace maxbias = b`M'
post biasfile (`M') (maxbias)
if maxbias >= upbias {
continue, break
}
}
postclose biasfile
postutil clear
use biasresults, clear
count
local nn = r(N)
local prob = `N'/(`nn' + `N')
noi di ""
noi di ""
noi di ""

local note1: di "Estimated Number of Missing Studies: " `nn'
local note2: di "Estimated Publication Probability: " %3.2f `prob' 
sum maxbias, detail
local xmin = r(min)
local num = maxbias[_N]
noi di ""
noi di ""
local xmax = `nn' + 5

twoway__function_gen y= ((`N' + x)/`N') * normalden(invnormal(`N' /(`N' + x)))*(`sumse'/`sumvar'), r(1 `xmax') x(x) gen(y x1, replace) n(100)

if `nn' >= 5 {
#delimit;
nois twoway (line y x, lp(solid) lw(medium)lc(black))(scatteri `num' `nn'), xtitle("Number of Missing Studies", size(*.75)) 
legend(order(2 "Maximum Bias Point" "`note1'" "`note2'") colgap(1) pos(6) col(1) size(*.50)) ylab(, format(%9.3f) angle(hor) labs(*.75) ) xsc(r(`xmin' `xmax')) plotregion(margin(zero)) 
yline(`num', lpat(dash) lw(thin)) xline(`nn', lpat(dash) lw(thin)) xlab(, format(%9.0f) labs(*.75)) ytitle("Maximum Bias", size(*.75));
#delimit cr
}
else if `nn' < 5 {
nois di "Estimated Number of Missing Studies: " `nn'
nois di "Estimated Publication Probability: " %3.2f `prob' 
}
}
end



