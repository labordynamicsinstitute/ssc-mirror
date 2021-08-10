******************************************
**    Luciano Lopez & Sylvain Weber     **
**        University of Neuchâtel       **
**    Institute of Economic Research    **
**      This version: July 29, 2017     **
******************************************

*! version 2.2 Luciano Lopez & Sylvain Weber 29jul2017
program xtgcause, rclass
version 10.0


*** Syntax ***
syntax varlist(min=2 max=2 numeric) [if] [in], [Lags(string) REGress]

*Mark sample to be used
marksample touse, novarlist

*Separate varlist into depvar/indepvar
tokenize `varlist'
local depvar `1'
local indepvar `2'


*** Checks ***
*Data must be -xtset- before
cap: xtset
if _rc {
	di as error "Panel variable not set; use xtset before running xtgcause."
	exit 459
}

*Panel must be strongly balanced
qui: xtset
local id "`r(panelvar)'"
local time "`r(timevar)'"
qui: tab `id' if `touse'
local N = r(r)
qui: tab `time' if `touse'
local T = r(r)
qui: sum `time' if `touse'
local tmin = `r(min)'
local tmax = `r(max)'
if `=`tmax'-(`tmin'-1)'>`T' {
	di as error "Panel must be strongly balanced and without gaps (no missing values allowed in " as input "`depvar'" as error " and " as input "`indepvar'" as error ")."
	exit 459
}
qui: count if `touse' & mi(`depvar',`indepvar')
if r(N)>0 {
	di as error "Panel must be strongly balanced and without gaps (no missing values allowed in " as input "`depvar'" as error " and " as input "`indepvar'" as error ")."
	exit 459
}

*Minimal number of obs
if `T'<=8 {
	di as error "Warning: there must be more than 8 periods to run the test, even in its simplest form."
	di as error "(General condition: T > 5+3K, where K is the lag order.)"
	exit 459
}

*Check that lags are correctly specified
if "`lags'"=="" {
	local K = 1
}
else {
	cap: confirm integer number `lags'
	if !_rc local K = `lags'
	if _rc {
		if wordcount("`lags'")>2 {
			di as error "lags() must be a positive integer or aic [#], bic [#], or hqic [#]."
			exit 198
		}
		local ltype = lower(word("`lags'",1))
		if !inlist("`ltype'","aic","bic","hqic") {
			di as error "lags() must be a positive integer or aic [#], bic [#], or hqic [#]."
			exit 198
		}
		cap: local Kmax = word("`lags'",2)
		if "`Kmax'"=="" local Kmax = floor((`T'-6)/3)
		cap: confirm integer number `Kmax'
		if _rc {
			di as error "lags() must be a positive integer or aic [#], bic [#], or hqic [#]."
			exit 198
		}
	}
}

*Minimal/maximal number of lags
if inlist("`ltype'","aic","bic","hqic") local K = `Kmax' // temporarily set K equal to Kmax to run the checks in a single loop
if `K'<=0 {
	di as error "lags() must be a positive integer or aic [#], bic [#], or hqic [#]."
	exit 198
}
if `T'-`K'<=`=5+2*`K'' {
	di as error "Warning: T (here " as input "`T'" as error ") must be larger than 5+3K (here " as input "`=5+3*`K''" as error ") where K is the lag order."
	di as error "The maximal lag order that can be included here is " as input "`=floor((`T'-6)/3)'" as error "." 
	exit 459
}


*** Dumitrescu-Hurlin Granger causality test with # lags ***
if !inlist("`ltype'","aic","bic","hqic") {

	*Initialize some matrices
	mat W = J(`N',1,0)
	mat PV = J(`N',1,0)

	*Individual Wald statistics
	sort `id' `time'
	cap: levelsof `id' if `touse', local(idlist)
	local j 0 
	foreach i of local idlist {
		local ++j
		qui: reg `depvar' l(1/`K').`depvar' l(1/`K').`indepvar' if `id'==`i' & inrange(`time',`=`tmin'+`K'',`tmax')
		if "`regress'"=="regress" {
			di _n(1) as input "Reg for id==`i'"
			noi: reg
			di _n(1) 
		}
		local i 0
		while `i'<`K' {
			local ++i		
			qui: test l`i'.`indepvar', accum
		}
		matrix W[`j',1] = `K'*r(F)
		matrix PV[`j',1] = 1-F(`K',`e(df_r)',`r(F)')
	}

	*Average Wald statistic
	mat O = J(rowsof(W),1,1)
	mat sum = O'*W
	mat wmean = sum/rowsof(W)
	local wbar = wmean[1,1]
}


*** Dumitrescu-Hurlin Granger causality test with AIC/BIC # lags ***
if inlist("`ltype'","aic","bic","hqic") {

	*Select and estimate best model based on IC. At the end of the loop: local K is the optimal # of lags.
	local ICmin = .
	forv k = 1/`Kmax' {
	
		*Initialize some matrices
		mat IC = J(`N',1,0)
		mat W = J(`N',1,0)
		mat PV = J(`N',1,0)
		mat IC = J(`N',1,0)

		*Calculate IC statistics
		sort `id' `time'
		cap: levelsof `id' if `touse', local(idlist)
		local j 0 
		foreach i of local idlist {
			local ++j
			qui: reg `depvar' l(1/`k').`depvar' l(1/`k').`indepvar' if `id'==`i' & inrange(`time',`=`tmin'+`Kmax'',`tmax')
			if "`ltype'"=="aic" local IC = -2*e(ll) + 2*e(rank) 
			if "`ltype'"=="bic" local IC = -2*e(ll) + ln(e(N))*e(rank) 
			if "`ltype'"=="hqic" local IC = -2*e(ll) + 2*ln(ln(e(N)))*e(rank) 
			mat IC[`j',1] = `IC'
		}
		
		*Identify lowest IC 
		mat O = J(rowsof(IC),1,1)
		mat ICsum = O'*IC
		mat ICmean = ICsum/rowsof(IC)
		local ICbar = ICmean[1,1]
		local ICmin = min(`ICmin',`ICbar')
		if `ICbar'==`ICmin' {
			local K = `k'
		}
	}
	
	*Individual Wald statistics for best model
	sort `id' `time'
	cap: levelsof `id' if `touse', local(idlist)
	local j 0 
	foreach i of local idlist {
		local ++j
		qui: reg `depvar' l(1/`K').`depvar' l(1/`K').`indepvar' if `id'==`i' & inrange(`time',`=`tmin'+`K'',`tmax')
		if "`regress'"=="regress" {
			di _n(1) as input "Reg for id==`i' and lags==`K'"
			noi: reg
			di _n(1) 
		}
		local i 0
		while `i'<`K' {
			local ++i		
			qui: test l`i'.`indepvar', accum
		}
		matrix W[`j',1] = `K'*r(F)
		matrix PV[`j',1] = 1-F(`K',`e(df_r)',`r(F)')
	}

	*Average Wald statistic
	mat O = J(rowsof(W),1,1)
	mat sum = O'*W
	mat wmean = sum/rowsof(W)
	local wbar = wmean[1,1]
}


*** Compute and display results ***
di _n(1) as text "Dumitrescu & Hurlin (2012) Granger non-causality test results:"
di _dup(62) "-"
if !inlist("`ltype'","aic","bic","hqic") {
	di as text "Lag order: " as res "`K'"
}
if inlist("`ltype'","aic","bic","hqic") {
	di as text "Optimal number of lags (`=upper("`ltype'")'): " as res "`K'" as text " (lags tested: " as res "1" as text " to " as res "`Kmax'" as text ")."
	local lags `K'
}

local wbar_d: di %9.4f `wbar'
local upper = `T' - (2*`K') - 1 
di as text "W-bar =" _col(15) as res "`wbar_d'" 

local zbar = sqrt(`N'/(2*`K')) * (`wbar'-`K') // Equation (9) in DH
local zbar_d: di %9.4f `zbar'
local pvzbar = 2*(1-normal(abs(`zbar')))
local pvzbar_d: di %5.4f `pvzbar'
di as text "Z-bar =" _col(15) as res "`zbar_d'" _col(27) as text "(p-value = " as res "`pvzbar_d'" as text ")"

local zbart = sqrt(`N'/(2*`K') * ((`T'-`K')-2*`K'-5)/((`T'-`K')-`K'-3)) * (((`T'-`K')-2*`K'-3)/((`T'-`K')-2*`K'-1)*`wbar' - `K') // Equation (26) in DH adapted with T-K instead of T
local zbart_d: di %9.4f `zbart'
local pvzbart = 2*(1-normal(abs(`zbart')))
local pvzbart_d: di %5.4f `pvzbart'
di as text "Z-bar tilde = " _col(15) as res "`zbart_d'" _col(27) as text "(p-value = " as res "`pvzbart_d'" as text ")"

di _dup(62) "-"
di as text "H0: " as input "`indepvar'" as text " does not Granger-cause " as input "`depvar'" as text "." 
di "H1: " as input "`indepvar'" as text " does Granger-cause " as input "`depvar'" as text " for at least one panelvar (" as input "`id'" as text ")." 


*** Store results ***
foreach stat in pvzbart zbart pvzbar zbar K wbar {
	if "`stat'"!="K" return scalar `stat' = ``stat''
	if "`stat'"=="K" return scalar lags = ``stat''
}

*Rename columns and rows of matrices
qui: levelsof `id' if `touse', local(levels)
foreach i of local levels {
	local rnames `rnames' `id'`i' 
}
foreach M in PV W {
	mat colnames `M' = `M'i
	mat rownames `M' = `rnames'
	return matrix `M'i = `M'
}

end 

/*
Update history:
- v1.1 (10feb2017): 
	- A parenthesis was missing in line 251: sqrt(`N'/2*`lags') --> sqrt(`N'/(2*`lags'))
	- Names of stored statistics modified/shortened: probz --> pvzbar, zbartilde --> zbart, probzbartilde --> pvzbart
- v1.2 (23feb2017):
	- Version submitted to Stata Journal.
	- Order of the stored statistics modified.
- v1.3 (12jul2017):
	- Addition of a nosmall sample adjustment option.
	  Eviews results correspond to xtgcause results (and Zbar-Stat. in Eviews = Z-bar tilde in xtgcause).
	  Exec&Share results (DH) correspond to xtgcause results with the nosmall option.
- v2.0 (13jul2017):
	- Special thanks to Gareth Thomas.
	- nosmall option removed.
	- Selection of lags by AIC/BIC improved.
- v2.1 (18jul2017):
	- Change from locals lags/lmax to a single local K
	- HQIC added
- v2.2 (29jul2017)
	- option -novarlist- added to -marksample- (line 17)
	- Error messages formatted (colors)
*/
