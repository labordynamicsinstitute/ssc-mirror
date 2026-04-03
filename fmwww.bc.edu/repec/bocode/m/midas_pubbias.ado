cap program drop midas_pubbias
program define midas_pubbias, rclass byable(recall) sortpreserve 
version 13
 #delimit;
 syntax [if] [in]
 [, Level(cilevel) 
 WGT 
 NOWgt
 REGline
 SUMline
 POINTopts(string asis)
 REGopts(string asis) *];
#delimit cr

capture assert e(package) == "midas"
if _rc !=0 {
di as error "Last estimation command was not a midas subcommand such as mle, smle, mh or inla or hmc"
error 301
}
qui {
preserve
clear
estimates store modpost
}
qui {
mat varrslist = e(varlist)
qui svmat varrslist, names(col)

/* Check syntax */

qui count if  ( (tp==0 & fn==0) | ( tn==0 & fp==0) )
if r(N) > 0 {
di as error "One or more studies have both tp and fn==0 or both tn and fp==0"
di as error  "replace both fp and tn as missing or botn fn and tp as missing which ever is applicable and rerun program."
exit 459 
}

if ~missing("`wgt'") & ~missing("`nowgt'") {
opts_exclusive "`wgt' `nowgt'" 
}

if `level' < 10 | `level' > 99 {
di as error "level() must be between 10 and 99"
	exit 198
}
* Log-scale axis labels (replaces mylabels dependency)
local ylab `"0 "1"  `=ln(10)' "10"  `=ln(100)' "100"  `=ln(1000)' "1000""'

/* initialise legend counter */
local li 1
local ptitle: di "Deeks' Funnel Plot Asymmetry Test"
tempvar  thetai sethetai xb yb stpred pubwgt dor ldor 
tempvar n1 n2 nt ESS xxline pid
tempname stbias b4pubbias sumdor
gen `pid'=_n
gen `n1' = tn + fp  
gen `n2' = tp + fn
gen `ESS' =(4 * `n1' * `n2')/(`n1' + `n2') 

gen `dor' = (tp*tn)/(fp*fn)
gen `ldor' = ln(`dor')
gen `thetai'=`ldor' 
gen `sethetai' = sqrt(`ESS') 
gen `xb'=1/sqrt(`ESS')
label var `xb' "1/root(ESS)"
gen `yb' = `thetai'
label var `yb' "Diagnostic Odds Ratio"
gen `pubwgt' = `ESS'
if ~missing("`sumline'") {
mat bbias=e(bsum)
mat Vbias=e(Vsum)
_coef_table, bmatrix(bbias) vmatrix(Vbias) 
mat biasmat=r(table)'
local sumdor =biasmat[3,1] 
local sumline `"xline(`sumdor', lpatt(solid) lcolor(red))"' 
}

if ~missing("`wgt'")  {
local _pdef "mlw(medthin) mlc(black) mfc(gs15) msize(*.5) ms(O)"
local _popts = cond(!missing("`pointopts'"), "`pointopts'", "`_pdef'")
local studypoints `"(scatter `xb' `yb' [aw=`pubwgt'*.10], sort `_popts')"' 
local studypoints `"`studypoints' (scatter `xb' `yb', ms(i) mlabp(0) mlabel(`pid') mlabs(*.5) mlabc(black))"'
local legend `"`legend' label(`li' "Study")"'
local order "`order' `li++'"
local ++li
}
else if ~missing("`nowgt'") {  
local _pdef2 "mlw(medthin) mlc(black) mfc(gs15) msize(*1.5) ms(O)"
local _popts2 = cond(!missing("`pointopts'"), "`pointopts'", "`_pdef2'")
local studypoints `"(scatter `xb' `yb', sort `_popts2')"' 
local studypoints `"`studypoints' (scatter `xb' `yb', ms(i) mlabp(0) mlabel(`pid') mlabs(*.5) mlabc(black))"'
local legend `"`legend' label(`li' "Study")"'
local order "`order' `li++'"
local ++li
}

* mylabels replaced with hardcoded log-scale labels above
regress  `yb' `xb'[weight=`pubwgt'], level(`level')
estimates store `stbias'
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
local pbias=2*ttail(e(df_r), abs(_b[Bias]/_se[Bias]))
local note: di "pvalue  = "%6.2f `pbias'
nois di " "
nois di " "
nois ereturn display, level(`level')
estimates restore `stbias'

if ~missing("`regline'") {
predict `stpred'
local _ropts = cond(!missing("`regopts'"), "`regopts'", "clpattern(solid) clwidth(vthin)")
local stline "(line `xb' `stpred' , `_ropts' )"
local legend `"`legend' label(`li' "Regression" "Line")"'
local order "`order' `li++'"
local ++li
}
#delimit;
nois twoway `studypoints' `stline', xlab(`ylab', angle(horizontal) labsize(*.75) format(%7.2f)) 
legend(order(`order') pos(6) row(1) size(*.50)  `legend') 
ylab(, labsize(*.75) angle(horizontal)) `title' aspectratio(1) 
/*plotregion(margin(zero))*/ xtitle("Diagnostic Odds Ratio")  `sumline'
subtitle("`ptitle'" "`note'", size(*.65)) yscale(rev) `scheme' `saving' `options';
#delimit cr
estimates drop  `stbias'
restore
estimates restore modpost
}

* Return bias regression results
return scalar bias_coef = b[1,1]
return scalar intercept = b[1,2]
return scalar bias_se   = sqrt(vcov[1,1])
return scalar bias_pval = `pbias'

end
