

*! version 1.00 January 15, 2007 

program define midas_binsse, rclass byable(recall) sortpreserve
version 9

syntax varlist(min=4 max=4) [if] [in], Method(string)[ LEVEL(integer 95) SCHEME (string) /// 
FUNnel REGplot Graph TEXTScale(real 0.50) ZCF(real 0.5) ///
POINTopts(string asis) REGopts(string asis) *]

tokenize `varlist'
global tp `1'
global fp `2'
global fn `3'
global tn `4'

/* Check syntax */
	
if `level' < 10 | `level' > 99 {
di as error "level() must be between 10 and 99"
	exit 198
		}

if !inlist("`method'", "d", "e", "h", "m", "p", "r", "s", "t") {
	di as error "method() must be one of: d (Deeks), e (Egger), h (Harbord),"
	di as error "  m (Macaskill), p (Peters), r (Rucker), s (Sterne), t (Stanley)"
	exit 198
}
			
if "`scheme'" != ""{
 set scheme `scheme'      
  }
  if "`scheme'" == ""{
  set scheme s2color
  }

local alph = (100-`level')/200

qui {

nois di " "
nois di " "
nois di as text "{title:STATISTICAL TESTS FOR SMALL STUDY EFFECTS/PUBLICATION BIAS}"

tempvar  n1 n2 nt ESS zero lthetai thetai sethetai xb yb stpred logn pubwgt
tempvar zc_tp zc_fn zc_fp zc_tn 
tempvar zz ll2 ul2 vl z mmm vvar w wl swl
tempname oe sw
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


gen `n1' = `zc_tp' + `zc_fn'  
gen `n2' = `zc_tn' + `zc_fp'
gen `nt' =  `n1' + `n2'
gen `ESS' =(4 * `n1' * `n2')/(`n1' + `n2')
gen `logn' = log(`nt')
gen `lthetai' = log((`zc_tp' * `zc_tn')/(`zc_fp' * `zc_fn')) 
gen `thetai' =.
gen `sethetai' =.
gen `pubwgt' =.
gen `xb' =.
gen `yb' =.

if "`method'" == "d" {
replace `thetai'=`lthetai' 
replace `sethetai' = sqrt(`ESS') 
replace `xb'=1/sqrt(`ESS')
label var `xb' "1/root(ESS)"
replace `yb' = `thetai'
label var `yb' "Odds Ratio"
local xxtitle "xtitle("Odds Ratio", size(*.90))" 
local yxtitle "ytitle("Odds Ratio", size(*.90)) xtitle("1/root(ESS)", size(*.90))"   
 
replace `pubwgt' = `ESS'
nois di " "
nois di " "
nois di as text "Regression of Log Odds Ratio on Inverse Root of Effective Sample Size" 
local ptitle: di "Deeks' Funnel Asymmetry Test"
nois di " "
}
else if "`method'" == "e" {
replace `thetai'=`lthetai' 
replace `sethetai' = sqrt((1/`zc_tp') + (1/`zc_fn') +(1/`zc_fp') + (1/`zc_tn'))
replace `xb'= 1/`sethetai'
label var `xb' "1/Standard Error"
replace `yb'=`thetai'/`sethetai' 
label var `yb' "Odds Ratio/Standard Error"
local xxtitle "xtitle("Odds Ratio/Standard Error", size(*.90))"  
local yxtitle "ytitle("Odds Ratio/Standard Error", size(*.90)) xtitle("1/Standard Error", size(*.90))"  
replace `pubwgt' = 1
nois di " "
nois di " "
nois di as text "Regression of Odds Ratio on Inverse Standard Error" 
local ptitle: di "Egger's Funnel Asymmetry Test"
nois di " "
}

else if "`method'" == "h" {

tempvar V rootV Z  		
gen `V'=(`zc_tp'+`zc_fn')*(`zc_tn'+`zc_fp')*(`zc_tp'+`zc_tn')*(`zc_fn'+`zc_fp') / (`nt')^3 
gen `Z'=(`zc_tp'*`zc_fp'-`zc_tn'*`zc_fn')/`nt'
gen `rootV'=sqrt(`V') 
replace `thetai' = `Z'/`rootV' 
replace `sethetai' = `rootV'
replace `xb'= `rootV'
label var `xb' "rootV"
replace `yb' = `thetai'
label var `yb' "ZoverrootV"
local xxtitle "xtitle("ZoverrootV", size(*.90))"  
local yxtitle "ytitle("ZoverrootV", size(*.90)) xtitle("rootV", size(*.90))"  

replace `pubwgt' = 1
nois di " "
nois di " "
display as text _n ///
"Regression of Z/sqrt(V) on sqrt(V)," _n ///
"where Z is efficient score and V is Fisher's information." _n
local ptitle: di "Harbord's Funnel Asymmetry Test"
nois di " "
}

else if "`method'" == "m" {
replace `thetai'=`lthetai' 
replace `sethetai' = `nt'
replace `xb'=`sethetai'
label var `xb' "Total Sample Size"
replace `yb'=`thetai'
label var `yb' "Odds Ratio"
local xxtitle "xtitle("Odds Ratio", size(*.90))"  
local yxtitle "ytitle("Odds Ratio", size(*.90)) xtitle("Total Sample Size", size(*.90))"  

replace `pubwgt' = 1/((1/(`zc_tp'+`zc_fp'))+(1/(`zc_tn'+`zc_fn')))
nois di " "
nois di " "
nois di as text "Regression of Log Odds Ratio on Sample Size" 
local ptitle: di "Macaskill's Funnel Asymmetry Test"
nois di " "
}

else if "`method'" == "p" {
replace `thetai'=`lthetai' 
replace `sethetai' = 1/`nt'
replace `xb'=`sethetai'
label var `xb' "Inverse Sample Size"
replace `yb'=`thetai'
label var `yb' "Odds Ratio"
local xxtitle "xtitle("Odds Ratio", size(*.90))"  
local yxtitle "ytitle("Odds Ratio", size(*.90)) xtitle("Inverse Sample Size", size(*.90))"  

replace `pubwgt' = 1/((1/(`zc_tp'+`zc_fp'))+(1/(`zc_tn'+`zc_fn')))
nois di " "
nois di " "
nois di as text "Regression of Log Odds Ratio on Inverse Sample Size" 
local ptitle: di "Peters' Funnel Asymmetry Test"
nois di " "
}

else if "`method'" == "r" {
replace `thetai'= asin(sqrt(`zc_tp'/`n1')) - asin(sqrt(`zc_fp'/`n2')) 
replace `sethetai' = sqrt((1/(4*`n1')) + (1/(4*`n2'))) 
replace `xb'=`sethetai'
label var `xb' "Standard Error"
replace `yb'=`thetai'
label var `yb' "Arcsine Difference"
local xxtitle "xtitle("Arcsine Difference", size(*.90))"  
local yxtitle "ytitle("ArcSine Difference", size(*.90)) xtitle("Standard Error", size(*.90))"  
replace `pubwgt' = 1/`sethetai'
nois di " "
nois di " "
nois di as text "Regression of Arcsine Difference on Standard Error"
local ptitle: di "Rucker's Funnel Asymmetry Test"
nois di " "
}
else if "`method'" == "s" {
replace `thetai'=`lthetai' 
replace `sethetai' = sqrt((1/`zc_tp') + (1/`zc_fn') +(1/`zc_fp') + (1/`zc_tn'))
replace `xb'= `sethetai'
label var `xb' "Standard Error"
replace `yb'=`thetai'
label var `yb' "Odds Ratio"
local xxtitle "xtitle("Odds Ratio", size(*.90))"  
local yxtitle "ytitle("Odds Ratio", size(*.90)) xtitle("Standard Error", size(*.90))"  
replace `pubwgt' = 1/`sethetai'^2

nois di " "
nois di " "
nois di as text "Regression of Log Odds Ratio on Standard Error" 
local ptitle: di "Sterne's Funnel Asymmetry Test"
nois di " "
}
else if "`method'" == "t" {
replace `thetai'=`lthetai' 
replace `sethetai' = `logn'
replace `xb' = `sethetai'
label var `xb' "Log Sample Size"
replace `yb'= log(abs(`thetai'/`sethetai'))
label var `yb' "|t-statistic|(log scale)"
local xxtitle "xtitle("log(|t-statistic|)", size(*.90))"  
local yxtitle "ytitle("log(|t-statistic|)", size(*.90)) xtitle("Log(Sample Size)", size(*.90))"  
replace `pubwgt' = 1
nois di " "
nois di " "
nois di as text "Metasignificance Testing: Regression of log_|t-statistic| on log_Sample_Size"
local ptitle: di "Stanley's Meta-significance Test"
nois di " "
}

sum `xb', detail
local xbmax=r(max)
sum `yb', detail
local ybmax=r(max)
local ybmin=r(min)
mylabels 1 10 100 1000, myscale(log(@)) local(xlab) 
regress  `yb' `xb'[weight=`pubwgt'], level(`level')
estimates store stbias
scalar intercept = _b[_cons]
scalar se_intercept = _se[_cons]
scalar rmse = e(rmse)
scalar df = e(df_r)
scalar p = 2*ttail(e(df_r), abs(return(score_bc)/return(score_se)))
nois matrix define vcov = e(V)
nois matrix define b = e(b)


if "`method'" == "d"| "`method'" == "m" | "`method'" == "p"  | "`method'" == "r" | "`method'" == "s" {
matrix colnames b =     Bias Intercept
matrix rownames vcov =  Bias Intercept 
matrix colnames vcov =  Bias Intercept 
}
else if "`method'" == "e"  | "`method'" == "h" {
nois matrix colnames b =     Slope Bias
nois matrix rownames vcov =  Slope Bias
nois matrix colnames vcov =  Slope Bias 
}

else if "`method'" == "t" {
nois matrix colnames b =     Slope Intercept
nois matrix rownames vcov =  Slope Intercept
nois matrix colnames vcov =  Slope Intercept 
}
local yvar : variable label `yb'
nois matrix post b vcov, dep("`yvar'") dof(`e(df_r)') obs(`e(N)')
nois ereturn display, level(`level')
nois di " "
nois di " "
if "`method'" == "t" {
nois di in green "If intercept > 0 there is genuine empirical effect" 
nois di " "
nois di " "
nois di in yellow "If intercept > 0 and intercept < 0.5 there is"  
nois di in yellow "both small study bias and genuine empirical effect"  
nois di " "
nois di " "
nois di in red "If intercept < 0 there is significant small study bias" 

}


estimates restore stbias
predict `stpred'
local _ropts = cond(!missing("`regopts'"), "`regopts'", "clpattern(dash) clwidth(vthin)")
local stline "(line `xb' `stpred', `_ropts' )"
local _ropts2 = cond(!missing("`regopts'"), "`regopts'", "clpattern(dash) clwidth(vthin)")
local regline "(line `stpred' `xb' , `_ropts2' )"

if "`graph'" != "" {

if "`method'" == "d" | "`method'" == "p" | "`method'" == "s"{

#delimit;
nois twoway `stline'(scatter `xb' `yb', sort `=cond(!missing("`pointopts'"), "`pointopts'", "ms(O)")' `options'),
legend(label(2 "Study") label(1 "Regression" "Line") order(2 1) pos(2) col(1) size(*.75))
ylab(, angle(horizontal) labsize(*`textscale') format(%7.2f)) 
subtitle("Funnel Plot-Fitted Regression Line", size(*.90))
xlab(`xlab', labsize(*`textscale') angle(horizontal)) `xxtitle' title(`ptitle', size(*.90));
#delimit cr
}
else if "`method'" == "m" {
#delimit;
nois twoway `stline'(scatter `xb' `yb', sort `=cond(!missing("`pointopts'"), "`pointopts'", "ms(O)")' `options'), 
legend(label(2 "Study") label(1 "Regression" "Line") order(2 1) pos(2) col(1) size(*.75))
ylab(, angle(horizontal) labsize(*`textscale') format(%7.0f)) 
subtitle("Funnel Plot-Fitted Regression Line", size(*.90))
xlab(`xlab', labsize(*`textscale') angle(horizontal)) `xxtitle' title(`ptitle', size(*.90));
#delimit cr
}  
else if "`method'" == "h" | "`method'" == "r" | "`method'" == "e" | "`method'" == "t"  {
#delimit;
nois twoway `stline'(scatter `xb' `yb', sort `=cond(!missing("`pointopts'"), "`pointopts'", "ms(O)")' `options') , 
legend(label(2 "Study") label(1 "Regression" "Line") order(2 1) pos(2) col(1) size(*.75))
ylab(, angle(horizontal) labsize(*`textscale') format(%7.2f)) 
subtitle("Funnel Plot-Fitted Regression Line", size(*.90))
xlab(, labsize(*`textscale') angle(horizontal)) `xxtitle' title(`ptitle', size(*.90));
#delimit cr
} 
}

if "`funnel'" != "" {
if "`method'" == "d" | "`method'" == "p" | "`method'" == "s"{

#delimit;
nois twoway (scatter `xb' `yb', sort `=cond(!missing("`pointopts'"), "`pointopts'", "ms(O)")' `options'),  
legend(label(1 "Study") pos(2) col(1) size(*.75))
ylab(, angle(horizontal) labsize(*`textscale') format(%7.2f)) 
subtitle("Funnel Plot", size(*.90)) xlab(`xlab', labsize(*`textscale') angle(horizontal)) 
`xxtitle' title(`ptitle', size(*.90));
#delimit cr
}
else if "`method'" == "m" {
#delimit;
nois twoway (scatter `xb' `yb', sort `=cond(!missing("`pointopts'"), "`pointopts'", "ms(O)")' `options'), 
legend(label( 1 "Study") pos(2) col(1) size(*.75))
ylab(, angle(horizontal) labsize(*`textscale') format(%7.0f)) 
subtitle("Funnel Plot", size(*.90)) xlab(`xlab', labsize(*`textscale') angle(horizontal))
 `xxtitle' title(`ptitle', size(*.90));
#delimit cr
}  
else if "`method'" == "h" | "`method'" == "r" | "`method'" == "e" | "`method'" == "t"  {
#delimit;
nois twoway (scatter `xb' `yb', sort `=cond(!missing("`pointopts'"), "`pointopts'", "ms(O)")' `options'), 
legend(label(1 "Study") pos(2) col(1) size(*.75))
ylab(, angle(horizontal) labsize(*`textscale') format(%7.2f)) 
subtitle("Funnel Plot", size(*.90))
xlab(, labsize(*`textscale') angle(horizontal)) `xxtitle' title(`ptitle', size(*.90));
#delimit cr
} 
} 

 

if "`regplot'" != "" {
if "`method'" == "d" | "`method'" == "p" | "`method'" == "s"{

#delimit;
nois twoway `regline'(scatter `yb' `xb', sort `=cond(!missing("`pointopts'"), "`pointopts'", "ms(O)")' `options'), 
legend(label(2 "Study") label(1 "Regression" "Line") order(2 1) pos(2) col(1) size(*.75))
xlab(, angle(horizontal) labsize(*`textscale') format(%7.2f)) 
subtitle("Linear Regression Plot", size(*.90))
ylab(`xlab', labsize(*`textscale') angle(horizontal)) `yxtitle' title(`ptitle', size(*.90));
#delimit cr
}
else if "`method'" == "m" {
#delimit;
nois twoway `regline'(scatter `yb' `xb', sort `=cond(!missing("`pointopts'"), "`pointopts'", "ms(O)")' `options'), 
legend(label(2 "Study") label(1 "Regression" "Line") order(2 1) pos(2) col(1) size(*.75))
xlab(, angle(horizontal) labsize(*`textscale') format(%7.0f)) 
subtitle("Linear Regression Plot", size(*.90))
ylab(`xlab', labsize(*`textscale') angle(horizontal)) `yxtitle' title(`ptitle', size(*.90));
#delimit cr
}  
else if "`method'" == "h" | "`method'" == "r" | "`method'" == "e" | "`method'" == "t"  {
#delimit;
nois twoway `regline'(scatter `yb' `xb', sort `=cond(!missing("`pointopts'"), "`pointopts'", "ms(O)")' `options'), 
legend(label(2 "Study") label(1 "Regression" "Line") order(2 1) pos(2) col(1) size(*.75))
xlab(, angle(horizontal) labsize(*`textscale') format(%7.2f)) 
subtitle("Linear Regression Plot", size(*.90))
ylab(, labsize(*`textscale') angle(horizontal)) `yxtitle' title(`ptitle', size(*.90));
#delimit cr
} 
} 

}


end
