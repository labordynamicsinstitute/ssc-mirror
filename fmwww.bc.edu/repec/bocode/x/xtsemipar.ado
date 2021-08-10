*! Version 2.0, 21 December 2021
*! Contact: francois.libois@psemail.eu

*V1.2 There were problems with the number of knots and their location. This has been solved in version V2.0
*V1.2 There were some bugs in the graphical display, this has been solved in version V2.0
*V2.0 Time-series operators have been activated
*V2.0 If bspline.ado is not already installed, a dialog box will open asking if bspline has to be installed
*V2.0 Confidence intervals of the non-parametric plot are corrected to take into account the number of estimated fixed-effects 

* This program is free software: you can redistribute it and/or modify it.

* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details <http://www.gnu.org/licenses/>.


program define xtsemipar, eclass

	version 13.0

	if replay()& "`e(cmd)'"=="xtsemipar" {
		ereturn  display
		exit
	}

	local required_ados "bspline"
	foreach x of local required_ados {
		capture which `x'.ado	
		if _rc != 0 {
			di "Please install the bspline package before using xtsemipar"
			capture window stopbox rusure "Do you want to install `x' from SJ?"
			if _rc != 0 {
				di ""
				di in r "The `x' package is needed for xtsemipar to run"
				exit
			}
			qui net install sg151_2.pkg
		}
	}

	syntax varlist(numeric ts) [if] [in] [aw fw/], nonpar(varlist) [robust cluster(varlist) ci DEGree(real 4)  NOGraph GENerate(string) level(cilevel) BWidth(numlist max=1) spline  knots1(numlist) knots2(numlist) KERnel(string)]

	tempname lnonpar touse

	mark `touse' `if' `in'
	markout `touse' `varlist'

	local level0=$S_level
	set level `level'
	
	qui query graphics
	local gphon=c(graphics)

	capture tsset

	capture local ivar "`r(panelvar)'"
	if "`ivar'"=="" {
		di as err "must tsset data and specify panelvar"
		exit 459
	}
	capture local tvar "`r(timevar)'"
	if "`tvar'" == "" {
		di as err "must tsset data and specify timevar"
		exit 459
	}
	
	qui xtsum `ivar' if `touse'
	local nd=r(n)
	
	tokenize `"`generate'"'
	if `"`3'"'!="" { error 198 }
	local marker `1'
	local Dvar `2'		/* may be null */
	confirm new var `marker' `Dvar'
	di ""
	di in r "Maximum two variables can be declared in option generate"
	exit 198
}

local varlist: list varlist -nonpar

tempvar tmax tmin
bysort `ivar': egen `tmax'=count(`tvar')
bysort `ivar': egen `tmin'=max(`tmax')
qui sum `tmin'

markout `touse' `varlist'

*1. Generate differences of variables entering the model parametrically and lags of the variable entering non-parametrically.


qui gen `lnonpar'=l.`nonpar' if `touse'
local dvarlist "d.(`varlist')"
local dv: word 1 of `varlist'
local expl: list varlist -dv

tokenize `expl'
local nex: word count `expl'

if "`weight'"!="" {
    local wgt "[`weight' = `exp']"
}

if `nex'==0 {
	di ""
	di in r "No parametric part is present. Use a nonparametric regression estimator instead"
	exit 198
}

local nvar: word count `dvarlist'
local nvar=`nvar'-1
qui {

	qui reg `dvarlist' `wgt'  if `touse'

* 2. Set the knots

	if "`knots1'"!= "" {
		local nknots1: word count `knots1'
	}

	else {
		local nknots1=9
	}

	if "`knots2'"!= "" {
		local nknots2: word count `knots2'
	}

	else {
		local nknots2=9
	}

	if "`knots1'"!= ""& "`knots2'"== ""{
		local nknots2=`nknots1'
	}

	local nfin1=`nknots1'+`degree'-1

* 3. Create an empty list that will be filled by differences in splines

	forvalues i=1(1)`nfin1' {
		tempname diffa`i'
		local diffa="`diffa' `diffa`i''"
		tempname diffb`i'
		local diffb="`diffb' `diffb`i''"
	}


	if "`degree'"<="0" {
		di ""
		di in r "degree should be strictly positive"
		exit 198
	}

* 4. Generate B-splines and fill the lists described in point 3.

	if "`knots1'"!="" {
		qui bspline `diffa' if `touse', x(`nonpar') power(`degree') knots(`knots1')
		qui bspline `diffb' if `touse', x(`lnonpar') power(`degree')  knots(`knots1')
	
	}

	else {

		tempvar pct
		pctile `pct' = `nonpar' if `touse', nq(10)

		forvalues k=1(1)9 {
			local ck=`pct'[`k']
			local knots=("`knots' `ck'")
		}

		qui sum `nonpar' if `touse'
		local min=r(min)
		local max=r(max)
		
		local knots="`min' `knots' `max'"
		qui bspline `diffa' if `touse', x(`nonpar') power(`degree') knots(`knots') 
		qui bspline `diffb' if `touse', x(`lnonpar') power(`degree')  knots(`knots')
	}

* 5. Difference B-splines

	forvalues i=1(1)`nfin1' {
		tempname diffc`i'
		gen `diffc`i''=`diffa`i''-`diffb`i''  if `touse'
		local diff="`diff' `diffc`i''"
	}

	tempvar touse0
	qui generate byte `touse0' = `touse'

* 6. Run the estimation with differenced variables and differenced splines

	else if "`robust'"!="" { 
		qui reg `dvarlist' `diff'  `wgt' if `touse', robust nocons level(`level')
	}

	if "`cluster'"!="" { 
		qui reg `dvarlist' `diff' `wgt' if `touse', cluster(`cluster') nocons level(`level')
	}

	else { 
		qui reg `dvarlist' `diff'  `wgt'  if `touse', nocons level(`level')
	}

	local dof  = e(df_r)
	local F   = e(F)
	local r2   = e(r2)
	local rmse = e(rmse)
	local mss  = e(mss)
	local rss = e(rss)
	local r2_a = e(r2_a)
	local ll   = e(ll)
	local nobs = e(N)

	local j=0
	foreach var of varlist `diff' {
		local j=`j'+1
		drop `var'
		qui rename `diffa`j'' `var'
		local diff2 "`diff2' `var'"
	}

	tempname B1 B2 res2 Vb Vb2 Vb0 B10

	matrix `B1'=e(b)
	matrix `Vb'=e(V)

	matrix `B10'=e(b)
	matrix `Vb0'=e(V)

	qui reg `varlist' `diff2'  `wgt' if `touse', noc level(`level')
	matrix `B2'=e(b)
	matrix `Vb2'=e(V)

	ereturn post `B2' `Vb2'

	matrix repost b=`B1'
	matrix repost V=`Vb'

	tempvar ehat
	qui predict `ehat' if `touse'&`tmin'!=1
	qui replace `ehat'=`dv'-`ehat'  if `touse'
	tempname m`ehat'
	bysort `ivar': egen `m`ehat''=mean(`ehat')  if `touse'

	matrix `Vb'=`Vb0'[1..`nvar',1..`nvar']
	matrix `B1'=`B10'[1,1..`nvar']

	qui reg `varlist' `wgt' if `touse', noc
	matrix `B2'=e(b)
	matrix `B2'=`B2'[1,1..`nvar']
	matrix `Vb2'=e(V)
	matrix `Vb2'=`Vb2'[1..`nvar',1..`nvar']
}

ereturn post `B2' `Vb2', depname(`dv') obs(`nobs') dof(`dof')

ereturn scalar df_m   = `nobs'-`dof'
ereturn scalar F=`F'
ereturn scalar r2=`r2'
ereturn scalar rmse=`rmse'
ereturn scalar mss=`mss'
ereturn scalar rss=`rss'
ereturn scalar r2_a=`r2_a'
ereturn scalar ll =`ll'

matrix repost b=`B1'
matrix repost V=`Vb'

ereturn repost, esample(`touse0')

ereturn local title "Panel fixed-effects partial linear regression"
ereturn local depvar "`dv'"
ereturn local model "Baltagi and Li Fixed-effect Series Semiparametric Estimation"
ereturn local cmd "xtsemipar"

noi di ""
noi di in green "{col 48} Number of obs        =" in yellow %8.0f `nobs'
noi di in green "{col 48} Within R-squared     =" in yellow %8.4f `r2'
noi di in green "{col 48} Adj Within R-squared =" in yellow %8.4f  `r2_a'
noi di in green "{col 48} Root MSE             =" in yellow %8.4f `rmse'
tempname E1
est store `E1'
ereturn display, level(`level')

*7: Fit partialled-out residuals

qui predict `res2' if `touse'
qui replace `res2'=`dv'-`res2'-`m`ehat''  if `touse'
qui sum `res2'  if `touse'

*8: Center the residuals

qui replace `res2'=`res2'-r(mean)  if `touse'
qui replace `res2'=. if `tmin'==1|`tmax'==1

tempvar aaa bbb low up z2

if "`nograph'"!="" {
	set graph off
}

*9: Run graphs on partialled-out residuals

if "`spline'"=="" {


	tempvar nonpar2
	qui gen `nonpar2'=`nonpar'
	qui replace `nonpar2'=. if `touse'==0
	
	qui reg `res2' `nonpar' `wgt' if `touse'
	local df=e(df_r)-`nd'-`nex'+1-`nknots1'-`degree'+1
	lpoly `res2' `nonpar' `wgt' if `touse', bw(`bwidth') kernel(`kernel') degree(`degree') at(`nonpar2') gen(`aaa') se(`bbb') level(`level') nograph
	local bw=round(r(bwidth),.001)
	local kernel=r(kernel)
	
	qui replace `bbb'=`bbb'*sqrt(r(N))/sqrt(`df') if `touse'
	qui sum `res2' if `touse'
	qui replace `res2'=`res2'-r(mean)  if `touse'
	local lev = (1 - (100 - `level') / 200)


	
	if "`ci'"=="" {
		local leglab0=`"order(1 "Partialled-out residuals" 2 "Local polynomial smooth")"'
		local z=0
		twoway (scatter `res2' `nonpar' if `touse', mcolor(navy) ytitle("Linear prediction""`note'")) (line `aaa' `nonpar' if `touse', sort(`nonpar') color(maroon) note("Kernel=`kernel',  Bandwidth=`bw',  Degrees=`degree'")), legend(`leglab0' rows(1) position(6))

	}
	
	local t=invt(`df',`lev')
	qui gen `low'=`aaa'-`t'*`bbb'
	qui gen `up'=`aaa'+`t'*`bbb'

	if "`ci'"!="" {
	
		if `df'<=0 {
		di in r "CI for the non-parametric part cannot be calculated - insufficient number of observations"
		}
		
		local leglab0=`"order(2 "Partialled-out residuals" 3 "Local polynomial smooth")"'
		local note="`level'% Confidence Intervals"		
		twoway (rarea `low' `up' `nonpar' if `touse',  ytitle("Linear prediction""`note'") sort(`nonpar') color(gs12))(scatter `res2' `nonpar' if `touse', mcolor(navy)) (line `aaa' `nonpar' if `touse', sort(`nonpar') color(maroon) note("Kernel=`kernel',  Bandwidth=`bw',  Degrees=`degree'") legend(`leglab0' rows(1) position(6)))

	}
	
	
	if "`knots2'"!="" {
		di ""
		no di in r "Option knots2 is ignored as it is meaningful only in Spline regressions." 
		di""
	}


}

else {

	if "`bwidth'"!="" {
		di ""
		no di in r "Only Spline options are considered, bw is meaningful only in Kernel regressions." 
		di""
	}	

	qui sum `nonpar' if `touse'
	local min=r(min)
	local max=r(max)

	if "`knots2'"==""&"`knots1'"=="" {
		local knots3="`min' `knots' `max'"
		local nfin1=`nfin1'+2
	}

	else if "`knots2'"==""&"`knots1'"!="" {
		local knots3="`knots1'"
	}

	else if "`knots2'"!=""&"`knots2'"!="" {
		local knots3="`knots2'"
	}

	forvalues i=1(1)`nfin1' {
		tempname fina`i'
		local fina="`fina' `fina`i''"
	}


	qui bspline `fina' if `touse', x(`nonpar') power(`degree') knots(`knots3')


	qui  reg `res2' `fina'  `wgt' if `touse', noc
	local df=e(df_r)-`nd'-`nex'-`nknots1'-`degree'+1

	qui predict `aaa' if `touse'
	qui sum `aaa' if `touse'
	qui replace `aaa'=`aaa'-r(mean)  if `touse'
	qui predict `bbb'  if `touse', stdp
	qui replace `bbb'=`bbb'*sqrt(e(df_r))/sqrt(`df') if `touse'

	qui replace `res2'=`res2'-r(mean)  if `touse'

	local lev = (1 - (100 - `level') / 200)


		
	if "`ci'"=="" {
		local leglab=`"order(1 "Partialled-out residuals" 2 "B-spline smooth""'
		local z=0
		twoway (scatter `res2' `nonpar' if `touse', mcolor(navy) ytitle("Linear prediction""`note'" )) (line `aaa' `nonpar' if `touse', sort(`nonpar') color(maroon)), legend(`leglab') rows(1) position(6))

	}
	
	local t=invt(`df',`lev')
	qui gen `low'=`aaa'-`t'*`bbb'
	qui gen `up'=`aaa'+`t'*`bbb'

	if "`ci'"!="" {
	
		if `df'<=0 {
		di in r "CI for the non-parametric part cannot be calculated - insufficient number of observations"
		}
		
		local leglab=`"order(2 "Partialled-out residuals" 3 "B-spline smooth""'
		local note="`level'% Confidence Intervals"
		twoway (rarea `low' `up' `nonpar' if `touse',  ytitle("Linear prediction""`note'") sort(`nonpar') color(gs12))(scatter `res2' `nonpar' if `touse', mcolor(navy)) (line `aaa' `nonpar' if `touse', sort(`nonpar') color(maroon)), legend(`leglab') rows(1) position(6))

	}

}


if "`generate'"!="" {

	tokenize `"`generate'"'
	label var `aaa' `"Nonparametric fit"'
	local marker `1'
	local Dvar `2'
	rename `aaa' `marker'

	if `"`Dvar'"'!="" {
		label var `res2' `"Partialled-out residuals"'
		rename `res2' `Dvar'
	}

}

if "`nograph'"!=""&"`ci'"!="" {
	noi di ""
	noi di in red "Option ci ignored since no graph is requested"
	noi di ""
}

if "`nograph'"!=""&"`spline'"!="" {
	noi di ""
	noi di in red "Option spline is ignored since no graph is requested"
	noi di ""
}

if "`nograph'"!=""&"`knots2'"!="" {
	noi di ""
	noi di in red "Option knots2 is ignored since no graph is requested"
	noi di ""
}

qui est restore `E1'

if "`spline'"==""&"`nograph'"=="" {
ereturn local kernel="`kernel'"
ereturn scalar bwidth=`bw'
ereturn scalar degree =`degree'
}

set level `level0'
set graph `gphon'

end
