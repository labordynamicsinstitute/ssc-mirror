*! version 07 January 17 2025
* First Version May 10 2023
program locproj, eclass
version 13.0:

	syntax varlist (fv ts) [if] [in] [fweight aweight pweight iweight], [Hor(numlist integer) Shock(varlist fv ts) Controls(varlist fv ts) /*
	*/FControls(varlist fv ts) Met(string) TRansf(string) lcs(string) YLags(integer 0) SLags(integer 0) LCOpt(string) SAVEirf IRFName(string) /*
	*/INStr(string) NOIsily STats hopt(string) Fact(real 1) conf(numlist max=2 integer) nograph LCOLor(string) TItle(string) LABel(string) /*
	*/TTItle(string) Zero GRName(string) GRSave(string) as(string) GROpt(string) MARGins MRFVar(varlist fv ts) MRPRed(string) MROpt(string) /*
	*/IVTest(string) * ]

*********************************************************************************************************************************************
*********************************************************************************************************************************************
loc nh = wordcount("`hor'")
if `nh'>1 {
	loc hor : subinstr local hor " " ",", all	
	loc hs=min(`hor')
	if `hs'<0 loc neghor=1
	loc hor=max(`hor')
	loc hran `hs'/`hor'	
}
else if `nh'==0 {
	loc hs=0
	loc hor=5
	loc hran `hs'/`hor'
}
else if `nh'==1 {
	loc hs=0
	loc hran `hs'/`hor'
}


*********************************************************************************************************************************************
*********************************************************************************************************************************************

if "`shock'"!="" {
	tokenize `varlist'
	loc y "`1'"
	macro shift 1
	loc c "`*'"
	if `ylags'==0 {
		foreach x of loc c {
			local n=regexm("`x'","\.`y'")+regexm("`x'","D\.`y'")
			if `n'==1 {
				loc yl `yl' `x'
				loc ylags = `ylags'+1
			}
		}
	}
	if "`controls'"=="" loc c : list c - yl
	else loc c `controls'
	
	loc ns = wordcount("`shock'")
	loc s `shock'
	tokenize `shock'
	loc s0 "`1'"
	local chl=regexm("`s0'","L\.")+regexm("`s0'","LD\.")
	if `slags'==0 loc ls 
	else loc ls L(1/`slags').(`shock')
	if `ns'>1 & "`lcs'"=="" {
		loc lcs : subinstr local s " " "+", all
	}

}
else {
	tokenize `varlist'
	loc y "`1'"
	macro shift 1
	loc c "`*'"
	if `ylags'==0 {
		foreach x of loc c {
			local n=regexm("`x'","\.`y'")+regexm("`x'","D\.`y'")
			if `n'==1 {
				loc yl `yl' `x'
				loc ylags = `ylags'+1
			}
		}
	}	
	loc c : list c - yl
 
	tokenize `c'
	loc s0 "`1'"
	loc s "`1'"
	loc c : list c - s
	local chl=regexm("`s'","L\.")+regexm("`s'","LD\.")
	local s0=regexr("`s0'","L\.","")
	local s0=regexr("`s0'","LD\.","")
	if `slags'==0 {	
		foreach x of loc c {
			local n=regexm("`x'","\.`s0'")
			if `n'==1 {
				loc ls `ls' `x'
				loc slags = `slags'+1
			}
		}
	}
	else loc ls L(1/`slags').(`s')
	if "`controls'"=="" loc c : list c - ls
	else loc c `controls'

}

*********************************************************************************************************************************************
*********************************************************************************************************************************************

loc nconf = wordcount("`conf'")
if `nconf'==0 loc conf=95
else if `nconf'>1 {
	tokenize `conf'
	loc conf "`1'"
	loc conf2 "`2'"
	if `conf2'<`conf' {
		loc conft `conf'
		loc conf `conf2'
		loc conf2 `conft'
	}
}

*********************************************************************************************************************************************
*********************************************************************************************************************************************
capture tsset
if _rc>0 {
	di as err "time/panel variables not set, use tsset/xtset ..."
	exit 0003
}
loc panvar=r(panelvar)
loc timevar=r(timevar)
loc tform=r(unit1)
loc tunit=r(unit)

if "`panvar'"=="." {
	loc panvar _id_
	capture qui gen _id_=1
	if "`tunit'"=="0"|"`tunit'"=="." |"`tunit'"=="per : "" 0" qui xtset _id_ `timevar'
	else qui xtset _id_ `timevar', `tunit'
}
if "`panvar'"=="_id_" & "`met'"=="" loc met reg
else if "`met'"=="" loc met xtreg

*********************************************************************************************************************************************
*********************************************************************************************************************************************

local iv=regexm("`met'","ivreg")
if `iv'==1 & "`instr'"=="" {
	di as err "If an instrumental variables method is being used, a list of instruments must be defined in the option instr() ..."
	exit 0004
}


*********************************************************************************************************************************************
*********************************************************************************************************************************************

* levels
if "`transf'"==""|"`transf'"=="level" {
	forvalues h = `hran' {
		loc hstr = `h' - `hs'
		loc m = `h'+`chl'
		tempvar y_h`hstr'
		if `h'<0 {
			loc ah = abs(`h')
			qui gen `y_h`hstr'' = l`ah'.`y'
			}				
		else qui gen `y_h`hstr'' = f`h'.`y'		
		loc trn`hstr' "`y'_h(`m')"
	}
	if `ylags'==0 loc ly
	if `ylags'>0 loc ly L(1/`ylags').`y'
	loc y y_h
}

* differences
else if "`transf'"=="diff" {
	tempvar dy
	qui gen `dy' = `y' - l.`y'
	fvexpand `dy' 
	loc ltr=r(varlist)
	loc ltrn "D.`y'"
	forvalues h = `hran' {
		loc hstr = `h' - `hs'
		loc m = `h'+`chl'
		tempvar dy_h`hstr'
		if `h'<0 {
			loc ah = abs(`h')
			qui gen `dy_h`hstr'' = l`ah'.`y' - l.l`ah'.`y'
			}				
		else qui gen `dy_h`hstr'' = f`h'.`y' - l.f`h'.`y' 
		loc trn`hstr' "D.`y'_h(`m')"
	}
	if `ylags==0' loc yl
	if `ylags'>0 loc ly L(1/`ylags').`dy'
	loc y dy_h
}

* Cumulative
else if "`transf'"=="cmlt" {
	tempvar dy
	qui gen `dy' = `y' - l.`y'
	fvexpand `dy' 
	loc ltr=r(varlist)
	loc ltrn "D.`y'"
	forvalues h = `hran' {
		loc hstr = `h' - `hs'
		loc m = `h'+`chl'
		tempvar cy_h`hstr'
		if `h'<0 {
			loc ah = abs(`h')
			qui gen `cy_h`hstr'' = l`ah'.`y' - l.`y'
			}				
		else qui gen `cy_h`hstr'' = f`h'.`y' - l.`y' 
		loc trn`hstr' "cml_`y'_h(`m')"
	}
	if `ylags==0' loc yl
	if `ylags'>0 loc ly L(1/`ylags').`dy'
	loc y cy_h
}
* logs
if "`transf'"=="logs" {
	tempvar lny
	qui gen `lny' = ln(`y')		
	fvexpand `lny' 
	loc ltr=r(varlist)
	loc ltrn "ln`y'"
	forvalues h = `hran' {
		loc hstr = `h' - `hs'
		loc m = `h'+`chl'
		tempvar lny_h`hstr'
		if `h'<0 {
			loc ah = abs(`h')
			qui gen `lny_h`hstr'' = ln(l`ah''.`y')
			}				
		else qui gen `lny_h`hstr'' = ln(f`h'.`y')		
		loc trn`hstr' "ln`y'_h(`m')"
	}
	if `ylags'==0 loc ly
	if `ylags'>0 loc ly L(1/`ylags').`lny'
	loc y lny_h
}

* log differences
else if "`transf'"=="logs diff" {
	tempvar dlny
	qui gen `dlny' = ln(`y') - ln(l.`y')
	fvexpand `dlny' 
	loc ltr=r(varlist)
	loc ltrn "D.ln`y'"
	forvalues h = `hran' {
		loc hstr = `h' - `hs'
		loc m = `h'+`chl'
		tempvar dlny_h`hstr'
		if `h'<0 {
			loc ah = abs(`h')
			qui gen `dlny_h`hstr'' = ln(l`ah'.`y') - ln(l.l`ah'.`y')
			}				
		else qui gen `dlny_h`hstr'' = ln(f`h'.`y') - ln(l.f`h'.`y') 
		loc trn`hstr' "D.ln`y'_h(`m')"
	}
	if `ylags==0' loc yl
	if `ylags'>0 loc ly L(1/`ylags').`dlny'
	loc y dlny_h
}

* Cumulative logs
else if "`transf'"=="logs cmlt" {
	tempvar dlny
	qui gen `dlny' = ln(`y') - ln(l.`y')
	fvexpand `dlny' 
	loc ltr=r(varlist)
	loc ltrn "D.ln`y'"
	forvalues h = `hran' {
		loc hstr = `h' - `hs'
		loc m = `h'+`chl'
		tempvar clny_h`hstr'
		if `h'<0 {
			loc ah = abs(`h')
			qui gen `clny_h`hstr'' = ln(l`ah'.`y') - ln(l.`y')
			}				
		else qui gen `clny_h`hstr'' = ln(f`h'.`y') - ln(l.`y')
		loc trn`hstr' "cml_ln`y'_h(`m')"
	}
	if `ylags==0' loc yl
	if `ylags'>0 loc ly L(1/`ylags').`dlny'
	loc y clny_h
}
*********************************************************************************************************************************************
*********************************************************************************************************************************************
cap drop _birf _seirf _birf_lo _birf_up	
cap drop _birf_lo2 _birf_up2
tempvar birf seirf _t birf_up birf_lo birf_up2 birf_lo2 _zero

if `hs'<=0 loc h1 = `hor'+ 1 -`hs'
else loc h1 = `hor'

qui gen `birf' = 0 if _n<=`h1'
qui gen `seirf' = 0 if _n<=`h1'
qui gen `birf_up' = 0 if _n<=`h1'
qui gen `birf_lo' = 0 if _n<=`h1'
if `nconf'>1 {
	qui gen `birf_up2' = 0 if _n<=`h1'
	qui gen `birf_lo2' = 0 if _n<=`h1'
}

if `hs'<=0 qui gen `_t' =_n-1+`hs'
else  qui gen `_t' =_n

if "`zero'"=="zero" qui gen `_zero' = 0
else qui gen `_zero' = .
if "`label'"=="" loc off off
else lab var `birf' "`label'"
if "`ttitle'"=="" loc ttitle "Period"
label var `birf' "`label'"

*********************************************************************************************************************************************
*********************************************************************************************************************************************
matrix stats = J(`hor'+`chl'-`hs'+1,6,.)

qui {
	forval h=`hran' {
		if `hs'<=0 loc k=`h'+ 1 +`chl' - `hs'
		else loc k=`h'+`chl'
		loc hstr = `h' - `hs'
		if `h'<0 loc elag = abs(`h')
		else loc elag = 0

		tempname b`hstr' V`hstr'
		
		if "`hopt'"!="" {
			if "`fcontrols'"=="" `met' ``y'`hstr'' `s' `ls' L(`elag')(`ly') `c' `if' `in' [`weight'`exp'], `hopt'(`h') `mopt' `options'
			else qui `met' ``y'`hstr'' `s' `ls' L(`elag')(`ly') `c' f`h'.(`fcontrols') `if' `in' [`weight'`exp'], `hopt'(`h') `mopt' `options'
		}
		else if `iv'==1 {
			if "`fcontrols'"=="" `met' ``y'`hstr'' `ls' L(`elag')(`ly') `c' (`s'=`instr') `if' `in' [`weight'`exp'], `mopt' `options'
			else qui `met' ``y'`hstr'' `ls' L(`elag')(`ly') `c' f`h'.(`fcontrols') (`s'=`instr') `if' `in' [`weight'`exp'], `mopt' `options'
		}	
		else {
			if "`fcontrols'"=="" `met' ``y'`hstr'' `s' `ls' L(`elag')(`ly') `c' `if' `in' [`weight'`exp'], `mopt' `options'
			else qui `met' ``y'`hstr'' `s' `ls' L(`elag')(`ly') `c' f`h'.(`fcontrols') `if' `in' [`weight'`exp'], `mopt' `options'
		}
		
        matrix `b`hstr'' = e(b)
        matrix `V`hstr'' = e(V)
		loc cfn : colfullnames e(b)
		
		matrix stats[`hstr'+`chl'+1,1]=e(N)
		if e(r2)!=. matrix stats[`hstr'+`chl'+1,2]=e(r2)
		else if e(r2_o)!=. matrix stats[`hstr'+`chl'+1,2]=e(r2_o)
		else matrix stats[`hstr'+`chl'+1,2]=1-e(rss)/(e(rss)+e(mss))
		matrix stats[`hstr'+`chl'+1,3]=e(r2_p)
		matrix stats[`hstr'+`chl'+1,4]=e(F)
		matrix stats[`hstr'+`chl'+1,5]=e(chi2)		
		if e(p)!=.  matrix stats[`hstr'+`chl'+1,6]=e(p)
		else if e(F)!=. matrix stats[`hstr'+`chl'+1,6]=1-F(e(df_m)+1,e(df_r),e(F))
		else matrix stats[`hstr'+`chl'+1,6]=1-chi2(e(df_m)+1,e(chi2))

		
		local cfn=regexr("`cfn'","`ltr'","`ltrn'")
		if `ylags'>1 {
			if `h'<0 loc ylags = `ylags' + `elag'
			forval p=2/`ylags' {
				local cfn=regexr("`cfn'","`p'\.`ltr'","`p'.`ltrn'")
			}	
		}
        matrix colnames `b`hstr'' = `cfn'
        matrix rownames `V`hstr'' = `cfn'
        matrix colnames `V`hstr'' = `cfn'

*********************************************************************************************************************************************
		
		if "`margins'"=="margins" {
			if "`mrpred'"=="" margins `mrfvar', dydx(`s') `mropt' level(`conf')
			else margins `mrfvar', dydx(`s') predict(`mrpred') `mropt' level(`conf')
			mat M=r(table)
			foreach i in b se ll ul {
					scalar _sca`i'=M[rownumb(M,"`i'"),1]
			}
			if `nconf'>1 {
				if "`mrpred'"=="" margins `mrfvar', dydx(`s') `mropt' level(`conf2')
				else margins `mrfvar', dydx(`s') predict(`mrpred') `mropt' level(`conf2')
				mat M=r(table)
				foreach i in ll ul {
					scalar _sca`i'2=M[rownumb(M,"`i'"),1]
				}		
			}
			replace `birf' = `fact'*_scab if _n==`k'
			replace `seirf' = `fact'*_scase if _n==`k'
			replace `birf_up' = `fact'*_scaul if _n==`k'
			replace `birf_lo' = `fact'*_scall if _n==`k'
			if `nconf'>1 {
				replace `birf_up2' = `fact'*_scaul2 if _n==`k'
				replace `birf_lo2' = `fact'*_scall2 if _n==`k'
			}				
		}	
*********************************************************************************************************************************************
		else {
			if "`lcs'"!="" {
				lincom `lcs', `lcopt' level(`conf')
				loc lb = r(lb)
				loc ub = r(ub)			
				if `nconf'>1 {
					lincom `lcs', `lcopt' level(`conf2')
					loc lb2 = r(lb)
					loc ub2 = r(ub)				
				}	
			}
			else {
				lincom `s', `lcopt' level(`conf')
				loc lb = r(lb)
				loc ub = r(ub)			
				if `nconf'>1 {
					lincom `s', `lcopt' level(`conf2')
					loc lb2 = r(lb)
					loc ub2 = r(ub)				
				}		
			}
				
			replace `birf' = `fact'*r(estimate) if _n==`k'
			replace `seirf' = `fact'*r(se) if _n==`k'

			if `lb'==. loc lb = `fact'*r(estimate)
			if `ub'==. loc ub = `fact'*r(estimate)
				if `nconf'>1 {
					if `lb2'==. loc lb2 = `fact'*r(estimate)
					if `ub2'==. loc ub2 = `fact'*r(estimate)		
				}
			
			replace `birf_up' = `fact'*`ub' if _n==`k'
			replace `birf_lo' = `fact'*`lb' if _n==`k'
			if `nconf'>1 {
				replace `birf_up2' = `fact'*`ub2' if _n==`k'
				replace `birf_lo2' = `fact'*`lb2' if _n==`k'
			}
		}

*********************************************************************************************************************************************
		if `iv'==1 & "`ivtest'"!="" {
			noi di "IV Test Step = `h'" 
			noi estat `ivtest'
			noi di "  "
		}
	
********************************************************************************************************************************************
		ereturn post `b`hstr'' `V`hstr''
        `noisily' di "`trn`hstr''"
		`noisily' _coef_table
	}

}

loc h1 = `h1'+`chl'
loc hor = `hor'+`chl'
loc hran `hs'/`hor'	


mkmat `birf' if _n<=`h1', mat(BIRF)
mkmat `seirf' if _n<=`h1', mat(SEIRF)
mkmat `birf_lo' if _n<=`h1', mat(SEIRF_LO)
mkmat `birf_up' if _n<=`h1', mat(SEIRF_UP)

if `nconf'>1 {
	mkmat `birf_lo2' if _n<=`h1', mat(SEIRF_LO2)
	mkmat `birf_up2' if _n<=`h1', mat(SEIRF_UP2)	
}
mat IRF = BIRF , SEIRF , SEIRF_LO , SEIRF_UP
matrix colnames IRF = "IRF" "Std.Err." "IRF LOW" "IRF UP"

if `nconf'>1 {
	mat IRF = BIRF , SEIRF , SEIRF_LO , SEIRF_UP, SEIRF_LO2 , SEIRF_UP2
	matrix colnames IRF = "IRF" "Std.Err." "IRF LOW `conf'" "IRF UP `conf'" "IRF LOW `conf2'" "IRF UP `conf2'"
}
forval i=`hran' {
	loc rows `rows' `i'
	loc lines `lines'&
}
matrix rownames IRF = `rows'

matrix colnames stats = " N " "R2" "psR2" "F" "Chi2" "Prob"
matrix rownames stats = `rows'

if "`stats'"=="stats" matlist stats, cspec(&o4 %9.0f w2 R|o1 %9.0f &o1 %9.3f &o1 %9.3f &o1 %9.2f &o1 %9.1f &o1 %9.3f &) rspec(&-`lines') title("Statistics by step") 
matlist IRF, noheader format(%9.5f) title("Impulse Response Function") lines(oneline)

*********************************************************************************************************************************************
*********************************************************************************************************************************************
loc mod = mod(`hor'-`hs',2)
if `hor'-`hs'>12 & `mod'==0 loc p 2
else if `hor'-`hs'>12 & `mod'==1 loc p 3
else loc p 1

if "`graph'"!="nograph" {
	if "`lcolor'"=="" loc lcolor blue
	if `nconf'>1 {
		qui twoway (rarea `birf_up2' `birf_lo2' `_t', fcolor(`lcolor'%15) lc(`lcolor'%7)) ///
		(rarea `birf_up' `birf_lo' `_t', fcolor(`lcolor'%30) lc(`lcolor'%15)) ///
		(line `_zero' `_t', lcolor(gs5) lpattern(dash)) ///
		(line `birf' `_t', lcolor(`lcolor') lpattern(solid)) if _n<=`h1', ///
		legend(`off' order(4) position(6)) title("`title'", size(*0.8)) `gropt' tlabel(`hs'(`p')`hor') xtitle(`ttitle') ///
		name(`grname', replace)
	}
	else {
		qui twoway (rarea `birf_up' `birf_lo' `_t', fcolor(`lcolor'%15) lc(`lcolor'%7)) ///
		(line `_zero' `_t', lcolor(gs5) lpattern(dash)) ///
		(line `birf' `_t', lcolor(`lcolor') lpattern(solid)) if _n<=`h1', ///
		legend(`off' order(3) position(6)) title("`title'", size(*0.8)) `gropt' tlabel(`hs'(`p')`hor') xtitle(`ttitle') ///
		name(`grname', replace)
	}
}
if "`grsave'"!="" {
	if "`as'"=="" graph save "`grsave'.gph", replace
	else graph export "`grsave'.`as'", as(`as') replace
}

*********************************************************************************************************************************************
*********************************************************************************************************************************************

if "`saveirf'"=="saveirf" {
	if "`irfname'"=="" {
		qui gen _birf = `birf'
		qui gen _seirf = `seirf'
		qui gen _birf_up = `birf_up'
		qui gen _birf_lo = `birf_lo'
		if `nconf'>1 {
			qui gen _birf_up2 = `birf_up2'
			qui gen _birf_lo2 = `birf_lo2'
		}
		label var _birf "`label'"
	}
	else {
		cap drop `irfname' `irfname'_se `irfname'_up `irfname'_lo
		cap drop `irfname'_up2 `irfname'_lo2
		qui gen `irfname' = `birf'
		qui gen `irfname'_se = `seirf'
		qui gen `irfname'_up = `birf_up'
		qui gen `irfname'_lo = `birf_lo'
		if `nconf'>1 {
			qui gen `irfname'_up2 = `birf_up2'
			qui gen `irfname'_lo2 = `birf_lo2'
		}
		label var `irfname' "`label'"		
	}
}
*********************************************************************************************************************************************
*********************************************************************************************************************************************

if "`panvar'"=="_id_" {
	qui drop _id_
	qui tsset `timevar'
}

ereturn matrix irf IRF

end
