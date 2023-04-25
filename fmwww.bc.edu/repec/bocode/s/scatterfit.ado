*! version 1.4.5   Leo Ahrens   leo@ahrensmail.de

program define scatterfit
version 13.1
	
*-------------------------------------------------------------------------------
* syntax and options
*-------------------------------------------------------------------------------
	
#delimit ;

syntax varlist(min=2 max=2)	[if] [in] [aweight fweight] , [

fit(string) BWidth(numlist max=1)  
by(string) 
BINned DISCrete NQuantiles(numlist max=1) BINVar(varlist max=1) UNIBin(numlist max=1)
Controls(varlist) Fcontrols(varlist)     
BINARYModel(string)
REGParameters(string) PARPos(string) PARSize(string)
vce(string)
JITter(numlist max=1)
STANDardize 
LEGINside LEGSize(string)
MWeighted MSize(string)
scale(string) XYSize(string)
PLOTScheme(string asis) COLorscheme(string asis) CINTensity(numlist max=1)
opts(string asis)

/* legacy */
polybw(numlist max=1) 
COVariates(varlist) ABSorb(varlist)
coef COEFPos(string) COEFPLace(string)
] ;

#delimit cr

*-------------------------------------------------------------------------------
* install dependencies
*-------------------------------------------------------------------------------

local gtoolsu = 0
local paletteu = 0
foreach package in reghdfe gtools ftools {
	capture which `package'
	if _rc==111 & "`package'"=="gtools" local gtoolsu = 1 
	if _rc==111 ssc install `package', replace
}
if `gtoolsu'==1 gtools, upgrade
capture which colorpalette
if _rc==111 local paletteu = 1
if `paletteu'==1 ssc install colrspace, replace
if `paletteu'==1 ssc install palettes, replace
capture set scheme plotplain
if _rc==111 ssc install blindschemes, replace
capture which labmask
if _rc==111 ssc install labutil, replace


*-------------------------------------------------------------------------------
* prep
*-------------------------------------------------------------------------------

// suppress output
quietly {

// declare x and y variables
tokenize `varlist'
local y `1'
local x `2'

// weight local
if ("`weight'"!="") local w [`weight'`exp']
if ("`weight'"!="") local weightname = subinstr("`exp'","=","",.)


*-------------------------------------------------------------------------------
* check if options are correct & output errors
*-------------------------------------------------------------------------------

// report that legacy options were specified and changed internally							*****
if "`polybw'"!=""  di as error "You specified the legacy option {bf:polybw()}, which is now {bf:bwidth()}. The setting {bf:bwidth(`polybw')} is assumed."
if "`absorb'"!="" di as error "You specified the legacy option {bf:absorb()}, which is now {bf:fcontrols()}. The setting {bf:fcontrols(`absorb')} is assumed"
if "`covariates'"!="" di as error "You specified the legacy option {bf:covariates()}, which is now {bf:controls()}. The setting {bf:controls(`covariates')} is assumed"
if "`coef'"!="" di as error "You specified the legacy option {bf:coef}, which is now governed by {bf:regparameters()}. The setting {bf:regparameters(beta pval)} is assumed."
if "`coefpos'"!="" | "`coefplace'"!=""  di as error "You specified the legacy option {bf:coefpos()} or {bf:coefplace()}, which is now {bf:parpos()}. The setting {bf:parpos(`coefplace'`coefpos')} is assumed"

// harmonize legacy options
if "`polybw'"!="" & "`bwidth'"=="" local bwidth `polybw'
if "`absorb'"!="" & "`fcontrols'"=="" local fcontrols `absorb'
if "`covariates'"!="" & "`controls'"=="" local controls `covariates'
if "`coef'"!="" & "`regparameters'"=="" local regparameters beta pval
if "`coefplace'"!="" & "`parpos'"=="" local parpos `coefplace'
if "`coefpos'"!="" & "`parpos'"=="" local parpos `coefpos'

// x and y variables
capture confirm numeric variable `x'
if _rc {
	di as error "{it:xvar} must be numeric."
	exit 498
}
if "`binarymodel'"!="" & !("`binarymodel'"=="logit" | "`binarymodel'"=="probit") {
	di as error "{bf:binarymodel()} must be specified to logit or probit."
	exit 498
}
qui levelsof `y' `if', local(yval)
local yvalcount: word count `yval'
if `yvalcount'==2 {
	if "`controls'`fcontrols'"!="" {
		di as error "The use of covariates with a binary dependent variable is not supported."
		exit 498
	}
	if "`by'"!="" {
		di as error "The use of by() with a binary dependent variable is not supported."
		exit 498
	}
	if "`fit'"=="lowess" | strpos("`fit'","poly") {
		di as error "Local polynomial and lowess fits are not supported for binary dependent variables."
		exit 498
	}
	if "`binned'"=="" {
		di as error "It is advised to use the binned option with binary dependent variables."
	}
}
if "`binarymodel'"!="" & `yvalcount'!=2 {
	di as error "Logit/probit models require a binary dependent variable."
	exit 498
}

// fit specification and option combinations correct?
if !("`fit'"=="" | "`fit'"=="lfit" | "`fit'"=="lfitci" | "`fit'"=="qfit" | "`fit'"=="qfitci" | "`fit'"=="poly" | "`fit'"=="polyci" | "`fit'"=="lowess") {
	di as error "fit() must be lfit, lfitci, qfit, qfitci, poly, or polyci."
	exit 498
}
if "`bwidth'"!="" & !(strpos("`fit'","poly") | "`fit'"=="lowess") {
	di as error "The bwidth() option requires a local polynomial fit or a lowess smother as the fit line."
	exit 498
}

// binned options
if ("`discrete'"!="" | "`binvar'"!="" | "`unibin'"!="" | "`nquantiles'"!="") & "`binned'"=="" {
	di as error "The discrete, unibin(), binvar(), and nquatiles() options require the binned option."
	exit 498
}
if "`unibin'"!="" & ("`discrete'"!="" | "`binvar'"!="" | "`nquantiles'"!="") {
	di as error "The unibin() option cannot be combined with discrete, nquantiles(), and binvar()."
	exit 498
}

// CIs and standard errors
if "`controls'`fcontrols'"!="" {
	if strpos("`fit'","ci") & strpos("`fit'","poly") {
			di as error "Confidence intervals cannot be plotted when covariates as well as a polynomial fit is specified."
			exit 498
	}
	if "`by'"!="" {
		dis as error "The by() option is incompatible with the use of controls. Consider using the binscatter or binscatter2 package."
		exit 498
	}
}
if "`vce'"!="" {
	if !strpos("`fit'","ci") & "`regparameters'"=="" {
		di as error "The vce() option requires that confidence intervals are drawn by fit(lfitci) / fit(qfitci) or that regression parameters are plotted via the regparameters() option."
		exit 498
	}
	if "`by'"!="" {
		dis as error "The vce() option is incompatible with the by() option."
		exit 498
	}
	if strpos("`fit'","poly") |  "`fit'"=="lowess" {
		dis as error "The vce() option is incompatible with a polynomial or lowess fit."
		exit 498
	}
}

// coefficient print
if "`regparameters'"!="" {
	if strpos("`fit'","qfit") | strpos("`fit'","poly") |  "`fit'"=="lowess" {
		dis as error "Regression parameters can only be plotted for a linear fit."
		exit 498
	}
	if "`by'"!="" {
		dis as error "The regparameters() option is incompatible with by() - regression parameters can only be plotted for a single fit line."
		exit 498
	}
	if strpos("`regparameters'","sig") & !strpos("`regparameters'","beta") {
		dis as error "{bf:regparameters({it:sig})} requires {bf:regparameters({it:beta})}"
		exit 498
	}
}
if "`parpos'"!="" & "`regparameters'"=="" {
	di as error "The parpos() option requires the regparameters() option."
	exit 498
}


*-------------------------------------------------------------------------------
* drop superfluous observations and variables
*-------------------------------------------------------------------------------

// preserve original data
preserve

// clean dataset
if "`controls'`fcontrols'"!="" | "`binvar'"!="" {
	foreach v of varlist `controls' `fcontrols' `binvar' {
		local covdrop `covdrop' | mi(`v')
	}
}
if "`by'"!="" local bydrop | mi(`by')
drop if mi(`x') | mi(`y') `covdrop' `bydrop'
if "`if'"!="" keep `if'
if "`in'"!="" keep `in'
keep `x' `y' `by' `controls' `fcontrols' `binvar' `weightname'


*-------------------------------------------------------------------------------
* prep x, y, and by variables
*-------------------------------------------------------------------------------

// check if suitable by variable is specified, generate one otherwise
local isthereby = 0
if "`by'"!="" {
	levelsof `by', local(byvals)
	local byvalcount: word count `byvals'
	if `byvalcount'!=1 {
		local isthereby = 1
		local byparen by(`by')
	}
}
if `isthereby'==0 {
	gen sfitbyvar = 1
	local by sfitbyvar
}

// make by variable numeric if necessary
capture confirm numeric variable `by'
if _rc {
	rename `by' oldby
	egen `by' = group(oldby)
	labmask `by', values(oldby)
}
levelsof `by', local(bynum)

// check if by-variable is labeled
if `isthereby'==1 {
	local isbyvarlabeled = 1
	gen bylabcheck = .
	tostring bylabcheck, replace
	foreach bynum2 in `bynum' {
		local bylabrun: label (`by') `bynum2'
		replace bylabcheck = "`bylabrun'" if `by'==`bynum2'
	}
	destring bylabcheck, replace
	capture confirm numeric variable bylabcheck
	if !_rc { 
		local isbyvarlabeled = 0
	}
}

// check if dependent variable is binary & transform into a dummy if required
local binarydv = 0
if "`yval'"=="0 1" local binarydv = 1
capture confirm numeric variable `y'
if `yvalcount'==2 & ("`yval'"!="0 1" | _rc) {
	local binarydv = 1
	local ylab: variable label `y'
	rename `y' old`y'
	egen `y' = group(old`y')
	replace `y' = `y'-1
	lab var `y' "`ylab'"
}

// retrieve names and labels from variables
local xlab: variable label `x'
local xtitle xtitle("`xlab'")
local ylab: variable label `y'
local ytitle ytitle("`ylab'")
if `binarydv'==1 {
	cap confirm variable old`y'
	if _rc {
		local ylabber `y'
	}
	else {
		local ylabber old`y'
	}
	levelsof `ylabber', local(oldyvals)
	foreach kk in `oldyvals' {
		local ylab: label (`ylabber') `kk'
	}
	gen ytitletest = "`ylab'"
	destring ytitletest,replace
	capture confirm numeric variable ytitletest
	if !_rc { 
		local ylab: variable label `y'
	}
	else {
		local ylab Pr(`ylab')
	}
	local ytitle ytitle("`ylab'")
}
if "`ylab'"=="" local ytitle ytitle("`y'")
if "`xlab'"=="" local xtitle xtitle("`x'")

if `isthereby'==1 {
	foreach bynum2 in `bynum' {
		local bylab`bynum2': label (`by') `bynum2'
	}
}

// standardize x and y
if "`standardize'"!="" {
	if `binarydv'==0 gstats transform (standardize) `y' `x' `w', replace
	if `binarydv'==1 gstats transform (standardize) `x' `w', replace
}


*-------------------------------------------------------------------------------
* generate / specify bin variable
*-------------------------------------------------------------------------------

if "`binned'"!="" {
	if "`nquantiles'"=="" local nquantiles 30
	if "`binvar'"=="" {
		if "`discrete'"=="" & "`unibin'"=="" { // quantiles
			gquantiles `x'_q = `x' `w', xtile nq(`nquantiles') `byparen'  
		}
		else if "`unibin'"=="" {  // discrete
			clonevar `x'_q = `x'  
		}
		else {  // uniform bin
			local `unibin' = `unibin'+1
			gen `x'_q = .
			local bincount = 0
			sum `x' `w'
			range binrange r(min) r(max) `unibin'
			foreach bb of numlist 1/`unibin' {
				local bincount = `bincount'+1
				qui sum binrange if _n==`bb'+1
				local binrange1 = r(mean)
				qui sum binrange if _n==`bb'
				replace `x'_q = `bb' if `x'>=r(mean) & `x'<`binrange1'
			}
		}
	}
	if "`binvar'"!="" {
		clonevar `x'_q = `binvar'
	}
}
cap confirm variable `x'_q
if _rc {
	gen `x'_q = `x'
}
local xbin `x'_q `by'


*-------------------------------------------------------------------------------
* gather parameters, confidence intervals, and point estimates
*-------------------------------------------------------------------------------

if `binarydv'==1 | "`regparameters'"!="" | "`controls'`fcontrols'"!="" | "`vce'"!="" {

// prepare options
	if "`vce'"!="" local vce vce(`vce')
	local `x'marg `x'
	if strpos("`fit'","qfit") local `x'marg c.`x'##c.`x'
	local hdfeabsorb noabsorb
	if "`fcontrols'"!="" local hdfeabsorb absorb(`fcontrols')
	
	// estimate regression
	if `binarydv'==0 reghdfe `y' ``x'marg' `controls' `w', `hdfeabsorb' `vce'
	if `binarydv'==1 {
		if "`binarymodel'"=="" local binarymodel logit
		`binarymodel' `y' ``x'marg' `w', `vce'
	}
	est sto regmodel
	
	// gather and round parameters
	if "`regparameters'"!="" {
		est res regmodel
		if `binarydv'==0 {
			local beta = _b[`x']
			local pval = 2*normal(-abs(_b[`x']/_se[`x']))
			local r2 = e(r2)
			local adjr2 = e(r2_a)
			local nobs = e(N)
			if strpos("`regparameters'","se") {
				qui reghdfe `y' ``x'marg' `controls' `w', `hdfeabsorb' `vce'
				local se = r(table)[2,1]
			}
		}
		if `binarydv'==1 {
			margins, dydx(`x') post
			local beta = r(table)[1,1]
			est res regmodel
			local r2 = e(r2_p)
			local adjr2 = e(r2_p)
			local nobs = e(N)
			margins, dydx(`x')
			local pval = e(p)
			local se = r(table)[2,1]
		}
		if strpos("`regparameters'","sig") {
			local siglevel = 99
			if `pval'<.1 & `pval'>.05 local siglevel = .1
			if `pval'<.05 & `pval'>.01 local siglevel = .05
			if `pval'<.01 local siglevel = .01
		}
		foreach par in beta pval r2 adjr2 se {
			if strpos("`regparameters'","`par'") {
				local smallround`par' = 0
				if ``par''>=10 | ``par''<=-10 {
					local `par'round "1"
				}
				else {
					if ``par''>=1 | ``par''<=-1 {
						local `par'round ".1"
					}
					else {
						local roundcount = 0
						local `par'string = subinstr("``par''","-","",.)
						
						local `par'round ".0"
						foreach rr of numlist 2/6 {
							if substr("``par'string'",`rr',1)!="0" {
								local `par'round "``par'round'1"
								continue, break
							}
							else {
								local `par'round "``par'round'0"
								local roundcount = `roundcount'+1
							}
						}
					}
				}
				dis "`par' " ``par'' " " ``par'round'
				cap if strpos("``par'string'","e") & ``par''>0 local smallround`par' = 1
				cap if strpos("``par'string'","e") & ``par''<0 local smallround`par' = -1
				local `par' = round(``par'',``par'round')
				if `smallround`par''==0 {
					local `par' "= ``par''"
				}
				else if `smallround`par''==1 {
					local `par' "< .00001"
				}
				else {
					local `par' "{&cong} 0"
				}
				if strpos("``par''","000000") & "``par''"!="< .00001" {
					foreach zz of numlist 1/9 {
						if substr("``par''",`zz',1)=="." local dotpos = `zz'
					}
					if "`dotpos'"!="" {
						if "``par'round'"=="1" local `par' = substr("``par''",1,`dotpos'-1)
						if "``par'round'"==".1" local `par' = substr("``par''",1,`dotpos'+1)
						if "``par'round'"==".01" local `par' = substr("``par''",1,`dotpos'+2)
						if "``par'round'"==".001" local `par' = substr("``par''",1,`dotpos'+3)
						if "``par'round'"==".0001" local `par' = substr("``par''",1,`dotpos'+4)
						if "``par'round'"==".00001" local `par' = substr("``par''",1,`dotpos'+5)
					}
				}
			}
		}
	}

	// gather linear prediction & CIs when controls or binary dv is specified
	if `binarydv'==1 | (strpos("`fit'","ci") & ("`controls'`fcontrols'"!="" | "`vce'"!="")) {
		if `binarydv'==1 | "`binned'"!="" gen `x'2 = `x'
		if `binarydv'==0 & "`binned'"=="" {
			reghdfe `x' `controls' `w', `hdfeabsorb' res(`x'2)
			sum `x' `w'
			replace `x'2 = `x'2 + r(mean)
		}
		foreach vv in cix ciu cil pe {
			gen `vv' = .
		}
		local mcount = 0
		local margpoints 30
		if strpos("`fit'","qfit") local margpoints 50
		sum `x'2 `w'
		range range r(min) r(max) `margpoints'
		foreach p of numlist 1/`margpoints' {
			local mcount = `mcount'+1
			qui sum range if _n==`p'
			local ranger`mcount' = r(mean)
			local margat `margat' `ranger`mcount''
		}
		if `binarydv'==0 local atmean atmeans
		est res regmodel	
		margins, at(`x'=(`margat')) `atmean' post
		foreach num of numlist 1/`mcount' {
			replace cix = `ranger`num'' if _n==`num'
			replace cil = r(table)[5,`num'] if _n==`num'
			replace ciu = r(table)[6,`num'] if _n==`num'
			replace pe = r(table)[1,`num'] if _n==`num'
		}
	}
}

*-------------------------------------------------------------------------------
* covariate adjustment of scatter points
*-------------------------------------------------------------------------------

if "`controls'`fcontrols'"!="" {

	if "`binned'"=="" {
		foreach v in `y' `x' {
			gen `v'_r = .
			foreach bynum2 in `bynum' {
				reghdfe `v' `controls' if `by'==`bynum2' `w', `hdfeabsorb' res(`v'_r`bynum2')
				sum `v' if `by'==`bynum2' `w'
				replace `v'_r = `v'_r`bynum2' + r(mean) if `by'==`bynum2'
			}
		}
		local y `y'_r 
		local x `x'_r
	}
	
	if "`binned'"!="" {
		gen `y'_r = .
		foreach bynum2 in `bynum' {
			reghdfe `y' `controls' i.`xbin' if `by'==`bynum2' `w', `hdfeabsorb'
			predict `y'_r`bynum2' if e(sample), xb
			if "`controls'"!="" {
				foreach v of varlist `controls' {
					replace `y'_r`bynum2' = `y'_r`bynum2' - _b[`v']*`v' if `by'==`bynum2'
				}
			}
			replace `y'_r = `y'_r`bynum2' if !mi(`y'_r`bynum2')
		}
		sum `y' `w'
		local adjm = r(mean)
		sum `y'_r `w'
		replace `y'_r = `y'_r + (`adjm'-r(mean))
		local y `y'_r
	}
}

*-------------------------------------------------------------------------------
* mean within bins
*-------------------------------------------------------------------------------

if "`binned'"!="" {
	gegen `y'_mean = mean(`y') `w', by(`xbin')
	gegen `x'_mean = mean(`x') `w', by(`xbin')
	if "`mweighted'"!="" gegen scw = count(`y'), by(`xbin')
	egen tag = tag(`xbin') if !mi(`y'_mean)
	replace `y'_mean = . if tag!=1
}

*-------------------------------------------------------------------------------
* specify variable to be plotted depending on binned / non-binned
*-------------------------------------------------------------------------------

if "`binned'"=="" {
	local yplot `y'
	local xplot `x'
}
else {
	local yplot `y'_mean
	local xplot `x'_mean
}

count if !mi(`xplot') & !mi(`yplot') & !mi(`by')
local n = r(N)

*-------------------------------------------------------------------------------
* color palette
*-------------------------------------------------------------------------------

if "`colorscheme'"=="" {
	local cpal `" "210 0 0" "49 113 166" "15 137 1" "255 127 14" "169 58 228" "41 217 231" "250 238 22"  "222 115 50" "'
}
else {
	local cpal `colorscheme'
}
if "`cintensity'"=="" & "`colorscheme'"=="" local cpalo int(1.2)
if "`cintensity'"=="" & "`colorscheme'"!="" local cpalo int(1)
if "`cintensity'"!="" local cpalo int(`cintensity')

if "`colorscheme'"!="" | "`plotscheme'"=="" {
	colorpalette `cpal', `cpalo' nograph local(,prefix(c) nonames)
	foreach i of numlist 25 30 50 75 {
		colorpalette `cpal', `cpalo' op(`i') nograph local(,prefix(c) suffix(o`i') nonames) 
	}
}

*-------------------------------------------------------------------------------
* overall plot scheme
*-------------------------------------------------------------------------------

if "`plotscheme'"=="" {
	local plotscheme scheme(plotplain) graphregion(lc(white) lw(vthick)) title(,size(medium)) ///
	ysc(lc(gs5) lw(thin)) ylab(#6, labs(*1.05) tlc(gs5) tlw(thin) glc(gs13) glp(solid) glw(thin) gmin gmax) ///
	xsc(lc(gs5) lw(thin)) xlab(#6, labs(*1.05) tlc(gs5) tlw(thin) glc(gs13) glp(solid) glw(thin) gmin gmax)
	
	foreach i of numlist 1/8 {
		local mlines`i' lc(`c`i'') lw(medthick)
		local mlinesci`i' acol(`c`i'o50') alw(none) clc(`c`i'') clw(medthick)
		local ciareas`i' lw(none) fc(`c`i'o30')
		local mfullscatterm`i' mfc(`c`i'o50') mlc(`c`i'') mlw(thin)
		local efullscatterm`i' `mfullscatterm`i''
		local mscatter75m`i' mfc(`c`i'o50') mlc(`c`i'o75') mlw(vthin) mlalign(inside)
		local escatter75m`i' `mscatter75m`i''
		foreach h of numlist 25 50  {
			local mscatter`h'm`i' mfc(`c`i'o`h'') mlalign(outside) mlw(none)
			local escatter`h'm`i' `mscatter`h'm`i''
		}
	}

	local nf = `n'
	local nfmin = 18 
	local nfmax = 500
	if `nf'<`nfmin' local nf = `nfmin'
	if `nf'>`nfmax' local nf = `nfmax'
	local globmsize = ((((`nfmax'+1-`nf')*(1/`nfmax'))^30)+(`nfmax'*.0005))*(2.6^1.5)

	local osize = 1
	local tsize = .98
	local ssize = .85
	local dsize = .8
	
	if "`mweighted'"!="" local mweightedresize *.3
	if `isthereby'==1 local mbyresize *.8
	
	if "`msize'"!="" {
	    if strpos("`msize'","*") local msize = subinstr("`msize'","*","",.)
		local mresize *`msize'
	}

	foreach sizeloc in osize tsize ssize dsize {
	    local e`sizeloc' = ``sizeloc''*`globmsize'
		local m`sizeloc' = ``sizeloc''*`globmsize'`mresize'`mweightedresize'`mbyresize'
	}

	foreach en in e m {
		if `isthereby'==0 {
			local m1 m(d) msize(*``en'dsize')
			local m2 m(o) msize(*``en'osize')
		}
		else {
			local m1 m(o) msize(*``en'osize')
			local m2 m(d) msize(*``en'dsize')
		}
		foreach g in `en'fullscatterm `en'scatter25m `en'scatter50m `en'scatter75m { 
			local `g'1 ``g'1' `m1'
			local `g'2 ``g'2' `m2'
			local `g'3 ``g'3' m(t) msize(*``en'tsize')
			local `g'4 ``g'4' m(s) msize(*``en'ssize')
			local `g'5 ``g'5' m(oh) msize(*``en'osize')
			local `g'6 ``g'6' m(dh) msize(*``en'dsize')
			local `g'7 ``g'7' m(th) msize(*``en'tsize')
			local `g'8 ``g'8' m(sh) msize(*``en'dsize')
		}
	}

	foreach g in mlines mlinesci {
		local `g'1 ``g'1' lp(solid)
		local `g'2 ``g'2' lp(dash)
		local `g'3 ``g'3' lp(shortdash)
		local `g'4 ``g'4' lp("-.")
		local `g'5 ``g'5' lp("_-")
		local `g'6 ``g'6' lp(longdash)
		local `g'7 ``g'7' lp("_.")
		local `g'8 ``g'8' lp("--.")
	}
}
else {
	local plotscheme scheme(`plotscheme')
	if "`colorscheme'"!="" {
		foreach i of numlist 1/8 {
			local mlines`i' lc(`c`i'') lw(medthick)
			local mlinesci`i' acol(`c`i'o50') alw(none) clc(`c`i'') clw(medthick)
			local ciareas`i' lw(none) fc(`c`i'o30')
			local mfullscatterm`i' mfc(`c`i'o50') mlc(`c`i'') mlw(thin) mlalign(inside)
			local mscatter75m`i' mfc(`c`i'o50') mlc(`c`i'o75') mlw(vthin) mlalign(inside)
			foreach h of numlist 25 50  {
				local mscatter`h'm`i' mfc(`c`i'o`h'') mlalign(outside) mlw(none)
			}
		}
	}
}

*-------------------------------------------------------------------------------
* refine scatter markers
*-------------------------------------------------------------------------------

// marker size weight
if "`mweighted'"!="" {
	if "`binned'"=="" gegen scw = count(`y'), by(`xbin')
	sum scw 
	replace scw = scw/r(mean)
	local scw [w=scw]
}

// different scatter marker opacity depending on number of data points
foreach en in e m {
	if `n'<=100 local `en'scattermarkers `en'fullscatterm
	if `n'>100 & `n'<=300 local `en'scattermarkers `en'scatter75m
	if `n'>300 & `n'<=2000 local `en'scattermarkers `en'scatter50m
	if `n'>2000 local `en'scattermarkers `en'scatter25m
}

*-------------------------------------------------------------------------------
* fit line
*-------------------------------------------------------------------------------

if "`fit'"=="lfitci" local fittype lfitci
if "`fit'"=="lfit" | "`fit'"=="" | ("`fit'"=="lfitci" & ("`controls'`fcontrols'"!="" | "`vce'"!="")) local fittype lfit
if "`fit'"=="qfitci" local fittype qfitci
if "`fit'"=="qfit" | ("`fit'"=="qfitci" & ("`controls'`fcontrols'"!="" | "`vce'"!="")) local fittype qfit
if "`fit'"=="polyci" local fittype lpolyci
if "`fit'"=="poly" | ("`fit'"=="polyci" & "`controls'`fcontrols'"!="") local fittype lpoly
if "`fit'"=="lowess" local fittype lowess

if "`fit'"=="" | "`fit'"=="lfit" | "`fit'"=="qfit" | "`fit'"=="poly" | "`fit'"=="lowess" {
	foreach ff of numlist 1/9 {
		local o`ff' `mlines`ff''
	}
}
if "`fit'"=="lfitci" | "`fit'"=="qfitci" | "`fit'"=="polyci" {
	foreach ff of numlist 1/9 {
		local o`ff' `mlinesci`ff''
	}
}

*-------------------------------------------------------------------------------
* regression parameters
*-------------------------------------------------------------------------------

local wherecoef = 0
if "`regparameters'"!="" {
	
// figure out where to position the box
	sum `yplot',d
	local ymax = r(max)
	local ymin = r(min)
	local y25 = r(p25)
	local y75 = r(p75)
	count if `yplot'>`y75'
	local y75larger = r(N)
	count if `yplot'<`y25'
	local y25smaller = r(N)
	sum `xplot',d
	local xmax = r(max)
	local xmin = r(min)
	local xmean = r(mean)
	local x75 = r(p75)
	count if `xplot'>`x75'
	local x75larger = r(N)
	count if `xplot'<`x75'
	local x75smaller = r(N)

	count if `yplot'>`y75' & `xplot'<`y75'
	if (r(N)/`n')<.03 {
		local textplacey `ymax'
		local textplacex `xmean'
	}
	else {
		count if `yplot'>`y75' & `xplot'>`y75'
		if (r(N)/`n')<.03 {
			local textplacey `ymax'
			local textplacex `xmax'
		}
		else {
			count if `yplot'<`y25' & `xplot'>`y75'
			if (r(N)/`n')<.03 {
				local textplacey `ymin'
				local textplacex `xmax'
				local wherecoef = 5
			}
			else {
				local textplacey `ymax'
				local textplacex `xmean'
			}
		}
	}
	local textplace `textplacey' `textplacex'
	if "`parpos'"!="" local textplace `parpos'
	
// compile the text box
	if strpos("`regparameters'","beta") | strpos("`regparameters'","ß") {
		if strpos("`regparameters'","sig") {
			if `siglevel'==.1 local sigstar *
			if `siglevel'==.05 local sigstar **
			if `siglevel'==.01 local sigstar ***
		}
		if `binarydv'==0 local betapar `""{it:ß} `beta'`sigstar'""'
		if `binarydv'==1 local betapar `""{it:{&delta}Pr/{&delta}x} `beta'`sigstar'""'
	}
	if strpos("`regparameters'","r2") {
		if `binarydv'==0 {
			local r2par `""{it:R sq.} `r2'""'
			if strpos("`regparameters'","adjr2") local r2par `""{it:Adj. R sq.} `adjr2'""'
		}
		if `binarydv'==1 {
			if "`r2'"!="" local r2par `""{it:Pseudo R sq.} `r2'""'
		}
	}
	if strpos("`regparameters'","pval") local pvalpar `""{it:p} `pval'""'
	if strpos("`regparameters'","se") local separ `""{it:se} `se'""'
	if strpos("`regparameters'","nobs") | strpos("`regparameters'","n") local nobspar `""{it:N} = `nobs'""'
	
	local parresize size(*.8)
	if "`parsize'"!="" {
	    if  strpos("`parsize'","*") local parsize = subinstr("`parsize'","*","",.)
		local parresize size(*`parsize')
	}

	local printcoef2 text(`textplace' `betapar' `separ' `pvalpar' `r2par' `nobspar', ///
	placement(center) `parresize' box fc(white) lc(gs5) lw(thin) la(outside) margin(vsmall) alignment(middle) linegap(.3))
}


*-------------------------------------------------------------------------------
* legend
*-------------------------------------------------------------------------------

// overall legend options
if "`legsize'"=="" local legresize size(*1.05)
if "`legsize'"!="" {
	if strpos("`legsize'","*") local legsize = subinstr("`legsize'","*","",.)
	local legresize size(*`legsize')
}

local legtype region(lc(white)) pos(3)
if "`leginside'"!="" {
    local leginsidepl 5
	if `wherecoef'==5 local leginsidepl 1
    local legtype ring(0) region(lc(gs5) fc(white)) pos(`leginsidepl')
}

local legopts legend(`legtype' `legresize')

// compile labels and legend options
if "`binned'"=="" local leg_obs Observed
if "`binned'"!="" local leg_obs Bin means
if strpos("`fit'","lfit") | "`fit'"=="" local leg_fit Linear
if strpos("`fit'","qfit") local leg_fit Quadratic
if strpos("`fit'","poly") local leg_fit Local polynomial
if strpos("`fit'","lowess") local leg_fit Lowess

foreach ii of numlist 1/4 {
    local n`ii' = `ii'
	if "`mweighted'"!="" local n`ii' = `n`ii''+1
}

if `isthereby'==0 {
	if !strpos("`fit'","ci") {
		local legopts `legopts' legend(order(1 "`leg_obs'" `n2' "`leg_fit' fit"))
	}
	else {
		local legopts `legopts' legend(order(1 "`leg_obs'" `n3' "`leg_fit' fit" `n2' "95% CIs"))
	}
}

if `isthereby'==1 {
	egen distinctby = group(`by')
	sum distinctby
	local maxdistinctby = r(max)
	local coln = 0
	levelsof `by', local(bynum)
	foreach bynum2 in `bynum' {
		local coln = `coln'+1
		if !strpos("`fit'","ci") | (strpos("`fit'","ci") & "`controls'`fcontrols'"!="") {
			local coln2 = `coln'+`maxdistinctby' 
		}
		else {
			local coln2 = `coln'+`maxdistinctby'+`coln'
		}
		if "`mweighted'"!="" local coln2 = `coln2'+`maxdistinctby'
		if `isbyvarlabeled'==1 local legorder `legorder' `coln' "`bylab`bynum2''" `coln2' ""
		if `isbyvarlabeled'==0 local legorder `legorder' `coln' "`by'==`bynum2'" `coln2' ""
	}
	local legopts `legopts' legend(order(`legorder') col(2) textfirst)
}


*-------------------------------------------------------------------------------
* overall plot size
*-------------------------------------------------------------------------------

if strpos("`scale'","*") {
	local scale2 = subinstr("`scale'","*","",.)
	local scale = `scale2'
}
if strpos("`xysize'","*") {
	local xysize2 = subinstr("`xysize'","*","",.)
	local xysize = `xysize2'
}

if "`scale'"!="" local plotsize scale(`scale')
if "`xysize'"!="" {
	if `xysize'<=1 {
		local ysize = 100
		local xsize = 100*`xysize'
	}
	if `xysize'>1 {
		local xsize = 100
		local ysize = 100*(1/`xysize')
	}
	local plotsize `plotsize' xsize(`xsize') ysize(`ysize')
}


*-------------------------------------------------------------------------------
* compile the final plot
*-------------------------------------------------------------------------------

// options
local lscatteropts `plotscheme' `xtitle' `ytitle' `printcoef2' `legopts' `plotsize' `opts' 
if "`bwidth'"!="" local bwidth bw(`bwidth')
if "`jitter'"!="" local jitter jitter(`jitter')

// empty scatter marker plot for correct legend in case of weighted scatter markers
if "`mweighted'"!="" {
	local coln = 0
	foreach bynum2 in `bynum' {
		local coln = `coln'+1
		local coln2 = `coln'
		if `isthereby'==0 local coln2 = `coln'+1
		local sce `sce' (scatter `yplot' `xplot' if `by'==`bynum2' & mi(`yplot'), ``escattermarkers'`coln2'')
	}
}

// correct plot
local coln = 0
foreach bynum2 in `bynum' {
	local coln = `coln'+1
	local coln2 = `coln'
	if `isthereby'==0 local coln2 = `coln'+1
	local sc `sc' (scatter `yplot' `xplot' if `by'==`bynum2' `scw', ``mscattermarkers'`coln2'' `jitter')
	if (("`fit'"=="lfitci" | "`fit'"=="qfitci") & ("`controls'`fcontrols'"!="" | "`vce'"!="") & `isthereby'==0) | `binarydv'==1 {
		if strpos("`fit'","ci") local ci `ci' (rarea cil ciu cix, `ciareas`coln'')
		local pl (line pe cix, `o`coln'')
	}
	else {
		local pl `pl' (`fittype' `y' `x' if `by'==`bynum2', `o`coln'' `bwidth')
	}
}


*-------------------------------------------------------------------------------
* draw the final plot
*-------------------------------------------------------------------------------

tw `sce' `sc' `ci' `pl', `lscatteropts'
	

*-------------
restore
}
*-------------


end













