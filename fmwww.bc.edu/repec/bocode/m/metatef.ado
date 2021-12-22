*! version 1.0.0 PR 13oct2021
program define metatef, rclass
	version 11.0
	local cmdline : copy local 0
	mata: _parse_colon("hascolon", "rhscmd")
	if !`hascolon' error 198

	_metatef_i `"`0'"' `"`rhscmd'"'

	return local cmdline `"metatef_i `cmdline'"'
end

program define _metatef_i, rclass
version 11.0
args 0 statacmd

gettoken cmd statacmd: statacmd
if substr("`cmd'", -1, .) == "," {
	local cmd = substr("`cmd'", 1, length("`cmd'") - 1)
	local statacmd ,`statacmd'
}
if "`cmd'"=="stpm" | "`cmd'"=="stpm2" {
	local dist 7
	local glm 0
	local qreg 0
	local xtgee 0
	local normal 0
	local eqxb eq(xb)
	local vminmax 1
}
else {
	*xfrac_chk `cmd'
	cmdchk `cmd' 
	if `s(bad)' {
		di as error "invalid or unrecognised command, `cmd'"
		exit 198
	}
	if "`cmd'" == "streg" local eqxb eq(_t)
	/*
		dist=0 (normal), 1 (binomial), 2 (poisson), 3 (cox), 4 (glm),
		5 (xtgee), 6(ereg/weibull), 7 (streg/stpm/stpm2).
	*/
	local dist `s(dist)'
	local glm `s(isglm)'
	local qreg `s(isqreg)'
	local xtgee `s(isxtgee)'
	local normal `s(isnorm)'
	local vminmax 2
}

* `using' creates a new file of results
syntax , BY(string) FIXPowers(string) with(varname) [ ADJust(string) CENtre(string) ///
 DEGree(int 0) EBayes(string) FUNction(string) GENerate(string) GENWt(string) ///
 GENVariance(string) MEANzero RANdom STRata(string) STUdywise TAU(string) ]
if `dist'!=7 & "`strata'"!="" {
	di as err "strata() allowed only with survival models (stcox, streg, stpm, stpm2)"
	exit 198
}
if "`tau'"!="" & "`random'"=="" {
	di as err "tau() valid only with random"
	exit 198
}
if "`studywise'"!="" & "`fixpowers'"!="" confirm matrix `fixpowers'
if `degree'==0 & "`fixpowers'"=="" local fixpowers 1
if "`fixpowers'"!="" & `degree'!=0 {
	di as err "fixpowers() invalid with degree()"
	exit 198
}
if `degree'<0 {
	di as err "invalid degree(), must be at least 1"
	exit 198
}	
if "`centre'"=="" | "`centre'"=="mean" {
	local centre mean	// centre on the global mean of xvar. has no influence on the fitted functions.
}
else confirm num `centre'
if "`generate'"!="" {
	confirm new var `generate'
}
confirm var `by'
if "`adjust'"!="" {
	unab adjust: `adjust'
}

// Parse to extract varlist from statacmd
local 0 `statacmd'
if `dist'==7 {
	local vminmax 1
}
else local vminmax 2
syntax varlist(min=`vminmax' max=`vminmax' numeric) [if] [in] [aw fw pw iw] [, DEAD(str) noCONStant * ]
if !missing("`dead'") local options `options' dead(`dead')
if !missing("`constant'") local options `options' `constant'

marksample touse, novarlist
markout `touse' `varlist' `by' `with' `strata' `adjust', strok

// `with' must be binary. We recode it to 0,1 and call it `t'.
quietly {
	tempvar t t_save
	egen int `t' = group(`with') if `touse'
	sum `t', meanonly
	if r(max) > 2 {
		noi di as err "`with' must have exactly 2 values"
		exit 198
	}
	replace `t' = `t' - 1
	clonevar `t_save' = `t'

	// Deal with weights (includes replacing touse with 0 if zero weight)
	frac_wgt `"`exp'"' `touse' `"`weight'"'
	local wgt `r(wgt)'

	if `dist'==7 {
		local anddead "& _d==1"
		local xvar `varlist'
	}
	else gettoken yvar xvar: varlist

	tempvar x study fbag sfbag
	tempname z shift scale
	scalar `z'=-invnorm((100-$S_level)/200)
	egen int `study'=group(`by') if `touse'
	sum `study',  meanonly
	local nstudy=r(max)

	* Extract original study codes for integer study numbers 1,...,nstudy
	levelsof `by', local(levels)
	local j 0
	while (`"`levels'"' != "") {
		local ++j
		gettoken studyval`j' levels : levels
	}
/*
	Extract fixpowers into strings from matrix, if fixpowers used with studywise
	First row of matrix is used for overall model, rest of rows are powers for each study.
*/
	local fixpowmat 0
	if "`studywise'"!="" & "`fixpowers'"!="" {
		local fixpowmat 1
		local rows=rowsof(`fixpowers')
		if `rows'!=(`nstudy'+1) {
			di as err "number of powers in fixpowers() not equal to number of studies plus 1"
			exit 198
		}
		local cols=colsof(`fixpowers')
		forvalues j=0/`nstudy' {
			local j1=`j'+1
			forvalues i=1/`cols' {
				local p=`fixpowers'[`j1',`i']
				if !missing(`p') local pwrs`j' `pwrs`j'' `p'
			}
		}
	}
	* Adjust xvar to its overall unweighted mean
	fracgen `xvar' 0 if `touse', nogen
	scalar `shift'=r(shift)
	scalar `scale'=r(scale)
	gen `x'=(`xvar'+`shift')/`scale' if `touse'
	if "`centre'"=="mean" {
		sum `xvar' if `touse'
		local centre=r(mean)
	}
	local centx=(`centre'+`shift')/`scale'
	local m `degree'
	if `degree'>=1 local degree degree(`m')
	else local degree
	noi di as txt "[`xvar' centered at " %8.0g `centre' "]"
	noi di as txt "Processing ... overall" _cont
	* Pooled-data estimate of deviance
	if `dist'==7 {	// survival models
		if ("`cmd'"=="stpm" | "`cmd'"=="stpm2") local strat stratify(`study' `strata')
		else local strat strata(`study' `strata')
	}

	if `dist'==7 {	// survival models
		if ("`cmd'"=="stpm" | "`cmd'"=="stpm2") {
			local strat stratify(`study' `strata')
			local strat2 stratify(`strata')
		}
		else {
			local strat strata(`study' `strata')
			local strat2 strata(`strata')
		}
	}

	if "`studywise'" == "" {
		// Single set of powers to be used for all data, supplied in fixpowers().
		local pwrs `fixpowers'
	}
	else {
		// FP powers as supplied in 1st row of fixpowers() matrix
		local pwrs `pwrs0'
	}
	local overallpowers `pwrs'
	fracgen `x' `pwrs' if `touse', replace adjust(`centx') noscaling
	local v `r(names)'
	if `dist' == 7 {
		`cmd' `yvar' `t'##c.(`v') `adjust' `wgt' if `touse', `strat' `options'
	}
	else {
		`cmd' `yvar' `t'##c.(`v') `adjust' i.`study' `wgt' if `touse', `options'
	}
	local devstrat=-2*e(ll)

	// Calc fixed-effects weighted mean function, fbag
	noi di as txt " ... study " _cont
	tempvar sumw se
	local devsum 0
	gen double `sumw' = 0 if `touse'
	gen double `fbag' = 0 if `touse'
	forvalues j=1/`nstudy' {
		noi di as txt `j', _cont
		tempvar f`j' v`j' w`j'			// fitted values, variance, weight for study j
		if "`studywise'" != "" {			// use studywise fixedpowers
			// Note that fracgen is calculated with centering over all studies
			fracgen `x' `pwrs`j'' if `touse', replace adjust(`centx') noscaling
			local v `r(names)'
		}
		// Refit model and make predictions for all observations
		`cmd' `yvar' `t'##c.(`v') `adjust' `wgt' if `study'==`j' & `touse'==1, `options' `strat2'
		local dev`j' = -2 * e(ll)
		local devsum = `devsum' + `dev`j''
		if "`meanzero'" != "" {
			// Compute column vector of mean(s) of predictor(s) for adjustment
			tempname means
			local mm
			tokenize `v'
			while "`1'" != "" {
				sum `1' if `study'==`j' & `touse'==1
				local mx = r(mean)
				if "`mm'" == "" local mm `mx'
				else local mm `mm' \ `mx'
				mac shift
			}
			matrix `means' = `mm'
			local Mean mean(`means')
		}
		replace `t' = 1
		xpredict2 `f`j'', with(1.`t' 1.`t'#c.(`v')) double `eqxb'
		if "`meanzero'" != "" {
			sum `f`j'' if `study'==`j' & `touse'==1
			replace `f`j'' = `f`j'' - r(mean)
		}
		xpredict2 `se', with(1.`t' 1.`t'#c.(`v')) double `eqxb' stdp `Mean'
		replace `t' = `t_save'
		
		* Compute weights for each function
		gen double `v`j''=`se'^2 if `touse'
		gen double `w`j''=1/`v`j'' if `touse'
		replace `sumw'=`sumw'+`w`j''
		replace `fbag'=`fbag'+`w`j''*`f`j''
		drop `se'
	}
	replace `fbag' = cond(`sumw'==0, 0, `fbag'/`sumw') if `touse'
	* Calc SE of mean function
	gen double `sfbag' = cond(`sumw'==0, 0, `sumw'^(-0.5)) if `touse'
	if "`random'"!="" {
		* Calculate estimate of random-effects variance, tausq
		tempvar Q tausq sumw2
		gen double `Q'=0 if `touse'
		gen double `sumw2'=0 if `touse'
		forvalues j=1/`nstudy' {
			replace `Q'=`Q'+`w`j''*(`f`j''-`fbag')^2
			replace `sumw2'=`sumw2'+`w`j''^2
		}
		gen `tausq' = cond(`sumw'==0, 0, max(0, (`Q'-(`nstudy'-1))/(`sumw'-`sumw2'/`sumw'))) if `touse'
		* Calculate estimated function with random-effects weights and its SE
		* This requires "wstar" random-effects weights
		replace `sumw'=0 if `touse'
		replace `fbag'=0 if `touse'
		forvalues j=1/`nstudy' {
			replace `w`j''=1/(`v`j''+`tausq')
			replace `w`j'' = 0 if missing(`w`j'') & `touse'==1
			replace `sumw'=`sumw'+`w`j''
			replace `fbag'=`fbag'+`w`j''*`f`j''
		}
		replace `fbag' = cond(`sumw'==0, 0, `fbag'/`sumw') if `touse'
		replace `sfbag' = cond(`sumw'==0, 0, `sumw'^(-0.5)) if `touse'
		if "`ebayes'"!="" {
			* Calculate empirical Bayes estimates and SE for function
			* (only applicable with random-effects estimates)
			forvalues j=1/`nstudy' {
				cap drop `ebayes'`j'
				cap drop `ebayes'se`j'
				gen `ebayes'`j' = cond(`v`j''==0, 0, (`tausq'*`f`j''/`v`j''+`fbag')/(`tausq'/`v`j''+1)) if `touse'
				gen `ebayes'se`j' = cond(`v`j''==0, 0, sqrt(`tausq'*`v`j''/(`tausq'+`v`j'')+(`v`j''/(`tausq'+`v`j''))^2/`sumw')) if `touse'
				lab var `ebayes'`j' "empirical Bayes f(`xvar') for study `studyval`j''"
				lab var `ebayes'se`j' "SE(empirical Bayes f(`xvar')) for study `studyval`j''"
			}
		}
	}
	if "`function'"!="" {
		* Save individual functions and SE
		forvalues j=1/`nstudy' {
			cap drop `function'`j'
			cap drop `function'se`j'
			gen `function'`j'=`f`j''
			gen `function'se`j'=sqrt(`v`j'')
			lab var `function'`j' "f(`xvar') for study `studyval`j''"
			lab var `function'se`j' "fixed-effects SE(f(`xvar')) for study `studyval`j''"
		}
	}
	if "`genvariance'"!="" {
		* Save within-study variance functions
		forvalues j=1/`nstudy' {
			cap drop `genvariance'`j'
			gen `genvariance'`j'=`v`j''
			lab var `genvariance'`j' "study `studyval`j''"
		}
	}
	if "`genwt'"!="" {
		* Save weight functions, standardized by sum of weights
		forvalues j=1/`nstudy' {
			cap drop `genwt'`j'
			gen `genwt'`j' = cond(`sumw'==0, 0, `w`j''/`sumw') if `touse'
			lab var `genwt'`j' "study `studyval`j''"
		}
	}
	if "`tau'"!="" {
		cap drop `tau'
		rename `tausq' `tau'
		lab var `tau' "Random-effects component of variance between studies"
	}
	drop `v'
	if "`generate'"!="" {
		cap drop `generate'_ll
		cap drop `generate'_ul
		cap drop `generate'_se
		gen `generate'_se=`sfbag'
		gen `generate'_ll=`fbag'-`z'*`sfbag'
		gen `generate'_ul=`fbag'+`z'*`sfbag'
		rename `fbag' `generate'
		lab var `generate' "`frs' average function f(`xvar')"
		lab var `generate'_se "standard error of f(`xvar')"
		lab var `generate'_ll "lower confidence limit for f(`xvar')"
		lab var `generate'_ul "upper confidence limit for f(`xvar')"
	}
	if "`random'"!="" {
		local frs "random-effects"
	}
	else local frs "fixed-effects"
	* Store deviance and d.f.
	return scalar deviance=`devsum'
	return scalar devstrat=`devstrat'
	forvalues j=1/`nstudy' {
		return scalar dev`j'=`dev`j''
	}
}
if !`fixpowmat' {
	if "`fixpowers'"!="" {
		local df: word count `fixpowers'
		local DF=`df'*`nstudy'
		local dfhomog=`df'*(`nstudy'-1)
	}
	else {
		if "`studywise'"=="" {	// same powers for all studies and overall
			local DF=`m'*`nstudy'+`m'
			local dfhomog=`m'*(`nstudy'-1)
		}
		else {
			local DF=2*`m'*`nstudy'
			local dfhomog=2*`m'*(`nstudy'-1)
		}
	}
	return scalar df=`DF'
	return scalar dfhomog=`dfhomog'
	return scalar aic=return(deviance)+2*return(df)
	return scalar P=chi2tail(`dfhomog', return(devstrat)-return(deviance))
	di as text _n(2) "Total deviance over studies: " as res _col(30) return(deviance) as text ", df = " as res `DF'
	di as text "Stratified model deviance: " as res _col(30) return(devstrat) as text ", df = " as res `DF'-`dfhomog'
	di as text "Heterogeneity chi-square: " as res _col(30) return(devstrat)-return(deviance) ///
	 as text ", df = " as res `dfhomog' as text " (P = " as res %5.3f return(P) as text ")"
}
else {
	di as text _n(2) "Total deviance over studies: " as res _col(30) return(deviance) // as text ", df = " as res `DF'
	di as text "Stratified model deviance: " as res _col(30) return(devstrat) // as text ", df = " as res `DF'-`dfhomog'
}
di as text _n "Powers for stratified model = " as res "`overallpowers'"
return local powers `overallpowers'
if "`studywise'"!="" {
	forvalues j=1/`nstudy' {
		return local powers`j' `pwrs`j''
	}
}
end

* version 1.0.6 PR 15feb2013
program define xpredict2
version 8.0
syntax newvarname [if] [in], WITH(varlist fv) [ CONStant A(numlist) DOUble EQ(string) mi stdp mean(string) * ]
if "`mi'"!="" {
	confirm var _mj
}
fvexpand `with'
local with `r(varlist)'
if "`mean'" != "" & "`stdp'" != "" {
/*
	`mean' is a matrix containing adjustment for each variable in `with';
	could be the mean of each variable; option could be called `centre'
*/
	confirm matrix `mean'
	marksample touse, novarlist
	markout `touse' `with'
	local origwith `with'
}
tempname tmp b V b2 V2
matrix `b'=e(b)
matrix `V'=e(V)
if "`constant'"!="" {
	local with `with' _cons
}
if missing(`"`eq'"') {
	local eq : coleq `b'
	local eq : word 1 of `eq'
	if (`"`eq'"' == "-") local eq
}
if !missing(`"`eq'"') {
	* include equation name with variable(s)
	tokenize `with'
	local with
	while "`1'"!="" {
		local with `with' `eq':`1'
		mac shift
	}
}
matselrc `b' `b2', row(1) col(`with')
matselrc `V' `V2', row(`with') col(`with')
local nc = colsof(`b2')
if "`a'"!="" {
	local na: word count `a'
	if `na'!=`nc' {
		di in red "wrong number of elements in a(), should be `nc'"
		exit 198
	}
	* construct matrix from `a' by hand
	tempname A
	matrix `A'=J(1,`nc',0)
	tokenize `a'
	local i 1
	while `i'<=`nc' {
		matrix `A'[1,`i']=``i''
		local i=`i'+1
	}
	local cn: colnames `b2'
	* Linear combination of elements in b2 with a.
	* Multiply A by b2 elementwise and overwrite b2.
	qui matewm `A' `b2' `b2'
	matrix colnames `b2'=`cn'
	* Form outer product of A with itself then multiply by V2 elementwise,
	* overwriting V2.
	matrix `A'=`A''*`A'
	qui matewm `A' `V2' `V2'
	matrix colnames `V2'=`cn'
	matrix rownames `V2'=`cn'
}
_estimates hold `tmp'
capture ereturn post `b2' `V2'
local rc=_rc
if `rc' {
	_estimates unhold `tmp'
	error `rc'
}
qui if "`mi'"!="" {
	* Partial prediction for all obs, then average over imputations
	sum _mj, meanonly
	local m=r(max)
	tempvar f
	if `"`if'"'=="" {
		local If if _mj>0
	}
	else local If `if' & _mj>0
	capture predict `double' `f' `If' `in', xb
	local rc=_rc
	_estimates unhold `tmp'
	if `rc' {
		error `rc'
	}
	sort _mi _mj
	by _mi: gen `double' `varlist'=sum(`f')/`m' if _mj>0
	by _mi: replace `varlist'=`varlist'[_N] if _n<_N & _mj>0
}
else {
	tempvar newvar
	capture predict `double' `newvar' `if' `in', `stdp' `options'
	local rc=_rc
	if `rc' error `rc'
	if "`meanzero'" != "" {
		if "`stdp'" == "" {
			qui sum `newvar' `if' `in'
			qui gen `double' `varlist' = `newvar' - r(mean)
		}
		else {
			matrix `V' = e(V)
			mata: zcalc("`varlist'", "`V'", "`origwith'", "`mean'", "`touse'")
		}
	}
	else rename `newvar' `varlist'
	_estimates unhold `tmp'
}
end

* NJC 1.1.0 20 Apr 2000  (STB-56: dm79)
program def matselrc
* NJC 1.0.0 14 Oct 1999 
        version 6.0
        gettoken m1 0 : 0, parse(" ,")
        gettoken m2 0 : 0, parse(" ,") 
	
	if "`m1'" == "," | "`m2'" == "," | "`m1'" == "" | "`m2'" == "" { 
		di in r "must name two matrices" 
		exit 198
	} 
	
        syntax , [ Row(str) Col(str) Names ]
        if "`row'`col'" == "" {
                di in r "nothing to do"
                exit 198
        }

        tempname A B 
        mat `A' = `m1' /* this will fail if `matname' not a matrix */
	local cols = colsof(`A') 
	local rows = rowsof(`A') 

        if "`col'" != "" {
		if "`names'" != "" { local colnum 1 } 
		else { 
	                capture numlist "`col'", int r(>0 <=`cols')
			if _rc == 0 { local col "`r(numlist)'" } 
                	else if _rc != 121 { 
				local rc = _rc 
				error `rc' 
			} 	
			local colnum = _rc == 0 
		}	
		/* colnum = 1 for numbers, 0 for names */ 

		tokenize `col' 
		local ncols : word count `col' 
		if `colnum' { 
			mat `B' = `A'[1..., `1'] 
			local j = 2 
			while `j' <= `ncols' { 
                		mat `B' = `B' , `A'[1..., ``j'']
				local j = `j' + 1 
			} 	
		} 
		else {
			mat `B' = `A'[1..., "`1'"] 
			local j = 2 
			while `j' <= `ncols' { 
                		mat `B' = `B' , `A'[1..., "``j''"]
				local j = `j' + 1 
			} 	
		} 
		mat `A' = `B' 	
		local cols = colsof(`A')  		
        }
	
	if "`row'" != "" {
		if "`names'" != "" { local rownum 0 } 
		else { 
	                capture numlist "`row'", int r(>0 <=`rows')
			if _rc == 0 { local row "`r(numlist)'" } 
                	else if _rc != 121 { 
				local rc = _rc 
				error `rc' 
			} 	
			local rownum = _rc == 0   
		} 	
		/* rownum = 1 for numbers, 0 for names */ 

		tokenize `row' 
		local nrows : word count `row' 
		if `rownum' { 
			mat `B' = `A'[`1', 1...] 
			local j = 2 
			while `j' <= `nrows' { 
                		mat `B' = `B' \ `A'[``j'', 1...]
				local j = `j' + 1 
			} 	
		} 
		else {
			mat `B' = `A'["`1'", 1...] 
			local j = 2 
			while `j' <= `nrows'  { 
                		mat `B' = `B' \ `A'["``j''", 1...]
				local j = `j' + 1 
			} 	
		} 
		mat `A' = `B' 	
        }
	
        mat `m2' = `A'
end
program define matewm
* 1.0.1 NJC 15 June 1999 STB-50 dm59
* 1.0.0  NJC 21 July 1998
    version 5.0
    parse "`*'", parse(" ,")
    if "`3'" == "" | "`3'" == "," {
        di in r "invalid syntax"
        exit 198
    }

    matchk `1'
    local A "`1'"
    matchk `2'
    local B "`2'"
    matcfa `A' `B'
    local nr = rowsof(matrix(`A'))
    local nc = colsof(matrix(`A'))
    local C "`3'"
    mac shift 3
    local options "Format(str)"
    parse "`*'"

    tempname D
    mat `D' = J(`nr',`nc',1)
    local i 1
    while `i' <= `nr' {
        local j 1
        while `j' <= `nc' {
            mat `D'[`i',`j'] = `A'[`i',`j'] * `B'[`i',`j']
            local j = `j' + 1
        }
        local i = `i' + 1
    }

    if "`format'" == "" { local format "%9.3f" }
    mat `C' = `D' /* allows overwriting of either `A' or `B' */
    mat li `C', format(`format')
end
* 1.0.0 NJC 19 July 1998    STB-50 dm69
program def matcfa
* matrices conformable for addition?
* matcfa `1' `2'
    version 5.0
    if "`1'" == "" | "`2'" == "" | "`3'" != "" {
        di in r "invalid syntax"
        exit 198
    }
    tempname C
    mat `C' = `1' + `2'
end
* 1.0.0 NJC 5 July 1998    STB-50 dm69
program def matchk
* matrix?
* matchk `1'
    version 5.0
    if "`1'" == "" | "`2'" != "" {
        di in r "invalid syntax"
        exit 198
    }
    tempname C
    mat `C' = `1'
end

* version 1.0.4 PR 30sep2005
* Based on private version 6.1.4 of frac_chk, PR 25aug2004
program define cmdchk, sclass
	version 7
	local cmd `1'
	mac shift
	local cmds `*'
	sret clear
	if substr("`cmd'",1,3)=="reg" {
		local cmd regress
	}
	if "`cmds'"=="" {
		tokenize clogit cnreg cox ereg fit glm logistic logit poisson probit /*
		*/ qreg regress rreg weibull xtgee streg stcox stpm stpm2 /*
		*/ ologit oprobit mlogit nbreg
	}
	else tokenize `cmds'
	sret local bad 0
	local done 0
	while "`1'"!="" & !`done' {
		if "`1'"=="`cmd'" {
			local done 1
		}
		mac shift
	}
	if !`done' {
		sret local bad 1
		*exit
	}
	/*
		dist=0 (normal), 1 (binomial), 2 (poisson), 3 (cox), 4 (glm),
		5 (xtgee), 6 (ereg/weibull), 7 (stcox, streg, stpm, stpmrs).
	*/
	if "`cmd'"=="logit" | "`cmd'"=="probit" /*
 	*/ |"`cmd'"=="clogit"| "`cmd'"=="logistic" /*
 	*/ |"`cmd'"=="mlogit"| "`cmd'"=="ologit" | "`cmd'"=="oprobit" {
						sret local dist 1
	}
	else if "`cmd'"=="poisson" {
						sret local dist 2
	}
	else if "`cmd'"=="cox" {
						sret local dist 3
	}
	else if "`cmd'"=="glm" {
						sret local dist 4
	}
	else if "`cmd'"=="xtgee" {
						sret local dist 5
	}
	else if "`cmd'"=="cnreg" | "`cmd'"=="ereg" | "`cmd'"=="weibull" | "`cmd'"=="nbreg" {
						sret local dist 6
	}
	else if "`cmd'"=="stcox" | "`cmd'"=="streg" | "`cmd'"=="stpm" | "`cmd'"=="stpm2" {
						sret local dist 7
	}
	else if substr("`cmd'",1,2)=="st" {
						sret local dist 7
	}
	else					sret local dist 0

	sret local isglm  = (`s(dist)'==4)
	sret local isqreg = ("`cmd'"=="qreg")
	sret local isxtgee= (`s(dist)'==5)
	sret local isnorm = ("`cmd'"=="regress"|"`cmd'"=="fit"|"`cmd'"=="rreg") 
end

mata:
void zcalc(string scalar newvarname, string scalar cov_beta, string scalar xvarlist, string scalar Xbar, string scalar tousevar)
{
	xbar = st_matrix(Xbar)
	// Form views of data in Mata
	V = st_matrix(cov_beta)
	xvars = tokens(xvarlist)
	st_view(X=., ., xvars, tousevar)
	n = rows(X)
	st_view(result=., ., st_addvar("double", newvarname), tousevar)
	// Should be possibe to do this in one matrix calc!
	for(i=1; i<=n; i++) {
		// result[i] = x1' * V * x1 + xbar' * V * xbar - 2 * x1' * V * xbar
		x1 = X[i, .]' - xbar
		result[i]  = sqrt(x1' * V * x1)
	}
}
end
