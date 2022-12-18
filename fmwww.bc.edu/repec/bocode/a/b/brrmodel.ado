*! brrmodel version 1.2  Nicholas Winter  15Nov2001

* Catch models with no observations or dropped variables
* Skip ftest if dof is negative
* Watch for negative or missing weights
*

prog define brrmodel, eclass
	version 7

	if ~replay() {
		syntax varlist [pweight/] [if] [in] , [ BRRWeight(string) FAY(string) /*
				*/ deff deft 	/*
				*/ Cmd(string) Level(int $S_level) DOF(real -1) or ] *

		if "`cmd'"=="" | substr(trim("`cmd'"),1,3)=="reg" {
			local cmd "regress"
			local predict "svyreg_p"
			*local predict "regres_p"
			local model "OLS"
			local svycmd "svyreg"
		}
		else if substr(trim("`cmd'"),1,4)=="prob" {
			local cmd "probit"
			*local predict "probit_p"
			local predict "svylog_p"
			local dor2 "*"
			local model "Probit"
			local svycmd "svyprobit"
		}
		else if trim("`cmd'")=="logistic" {
			local cmd "logistic"
			*local predict "logit_p"
			local predict "svylog_p"
			local eform "eform(Odds Ratio)"
			local dor2 "*"
			local model "Logit"
			local svycmd "svylogit"
		}
		else if substr(trim("`cmd'"),1,4)=="logi" {
			local cmd "logit"
			*local predict "logit_p"
			local predict "svylog_p"
			local dor2 "*"
			if "`or'"=="or" {
				local eform "eform(Odds Ratio)"
			}
			local model "Logit"
			local svycmd "svylogit"
		}
		else if substr(trim("`cmd'"),1,5)=="oprob" {
			local cmd "oprobit"
			local predict "ologit_p"
			local dor2 "*"
			local model "Ordered Probit"
			local svycmd "svyoprobit"
		}
		else if substr(trim("`cmd'"),1,4)=="olog" {
			local cmd "ologit"
			local predict "ologit_p"
			local dor2 "*"
			local model "Ordered Logit"
			local svycmd "svyologit"
		}
		else if substr(trim("`cmd'"),1,4)=="mlog" {
			local cmd "mlogit"
			local predict "mlogit_p"
			local dor2 "*"
			local model "Multinomial Logistic Regression"
			local svycmd "svymlogit"
		}
		else if substr(trim("`cmd'"),1,4)=="pois" {
			local cmd "poisson"
			local predict "poisso_p"
			local dor2 "*"
			local model "Poisson Regression"
			local svycmd "svypois"
		}
		else {
			di as err "cmd(`cmd') invalid"
			exit 198
		}

		if !inrange(`level',10,99) {
			di as err "level() must be between 10 and 99 inclusive"
			exit 198
		}

		if "`weight'"=="" {
			local exp : char _dta[pweight]
			if "`exp'"=="" {
				di as error "Must specify pweight for overall analysis, or set it with {help svyset}"
				error 198
			}
		}
		local mainweight `exp'

		if "`brrweight'"=="" {
			local brrweight : char _dta[brrwspec]
			if "`brrweight'"=="" {
				di as error "Must specify BRR Weights with BRRWeight() option for first BRR command"
				error 198
			}
		}
		local brrwspec "`brrweight'"
		unab brrw : `brrweight'
		local nbrrw : word count `brrw'	
		char define _dta[brrwspec] "`brrweight'"

		local depv : word 1 of `varlist'

		if "`fay'"=="" {
			local fay : char _dta[brrfay]
			if "`fay'"=="" {
				local fay 0
			}
		}
		cap confirm number `fay'
		if _rc {
			di in red "fay() must be a number in the range (0,1]"
			error 198
		}
		else if (`fay'<0) | (`fay'>=1) {
			di in red "fay() must be a number in the range (0,1]"
			error 198
		}
		char define _dta[brrfay] "`fay'"

		local printdeff=cond("`deff'`deft'"!="",1,0)

		marksample touse
		tempname totb repb accumV r2

*RUN THE FULL-SAMPLE COMMAND TO GET overall b-hat
		qui `cmd' `varlist' [pw=`mainweight'] if `touse' , `options' 
		local df_m=e(df_m)
		scalar `r2'=e(r2)

		matrix `totb'=get(_b)
		local nb = colsof(`totb')
		mat `accumV' = J(`nb',`nb',0)

*DO REPLICATES
		forval rep = 1/`nbrrw' {
			local curw : word `rep' of `brrw'
			qui `cmd' `varlist' [pw=`curw'] if `touse', `options'
			matrix `repb'=e(b)
			matrix `repb'=`repb'-`totb'						/* turn into deviation */
			matrix `accumV' = `accumV' + (`repb'')*(`repb')		/* add this one:  (b_k - b_tot)'(b_k - b_tot) */
													/* NOTE: Stata stores b as ROW vector, so b'b is  */
													/*       OUTER product, not inner				*/
		}

		tempname scalefac
		scalar `scalefac' = 1 / (`nbrrw' * (1-`fay')^2 )
		matrix `accumV'=`accumV' * `scalefac'

		qui count if `touse'
		local N `r(N)'
		if (`dof')==-1 {
			local dof `nbrrw'
		}
		tempname N_pop
		qui sum `mainweight' if `touse'
		scalar `N_pop'=`r(sum)'

*CALCULATE F STAT FOR FULL MODEL
		tempname b D F aug
		mat `b' = `totb''			/* column vector! */
		mat `D' = I(`df_m')			/* i.e. number of variables in b */
		local nextra = rowsof(`b')-`df_m'
		mat `aug' = J(`df_m',`nextra',0)
		mat `D' = `D' , `aug'
		mat `F'= (`D'*`b')' * inv(`D'*`accumV'*`D'') * (`D'*`b') * ( (`dof'-`df_m'+1) / (`dof'*`df_m') )

*USE SVY-BASED COMMAND TO GET SRS VARIANCE FOR DEFF

		qui `svycmd' `varlist' [pw=`mainweight'] if `touse' , `options'
		tempname V_srs deff deft
		matrix `V_srs'=e(V_srs)
		local i = colsof(`V_srs')
		matrix `deff' = vecdiag(`accumV')
		matrix `deft' = `deff'
		forval j=1/`i' {
			matrix `deff'[1,`j']=`deff'[1,`j']/`V_srs'[`j',`j']
			matrix `deft'[1,`j']=sqrt(`deff'[1,`j'])
		}

*POST RESULTS!
		estimates post `totb' `accumV' , dof(`dof') depn(`depv') obs(`N') esample(`touse')
	
		est scalar N_pop=`N_pop'
		est scalar N_reps=`nbrrw'
		est scalar df_m=`df_m'
		est scalar N_psu=`dof'*2			/* cludge to get svytest to work appropriately */
		est scalar N_strata=`dof'			/* ditto */
		est scalar F=`F'[1,1]
		`dor2' est scalar r2=`r2'

		est local brr_wspec "`brrwspec'"
		est local pweight "`mainweight'"
		est local depvar "`depv'"
		est local predict "`predict'"
		est local model "`model'"
		est local cmd "svybrrmodel"		/* svy at beginning to get svytest to accept results */

		est matrix deff `deff'
		est matrix deft `deft'
		est matrix V_srs `V_srs'

	}
	else {							/* this is a re-display */
		if "`e(cmd)'"!="svybrrmodel" {
			error 301
		}
		syntax [, Level(integer $S_level) or deff deft ]
		if !inrange(`level',10,99) {
			di as err "level() must be between 10 and 99 inclusive"
			exit 198
		}
		if "`or'"=="or" {
			local eform "eform(Odds Ratio)"
		}
		local printdeff=cond("`deff'`deft'"!="",1,0)

	}

*DISPLAY RESULTS

	di
	di "{txt}`e(model)' estimates with BRR-based standard errors"
	di
	di "{txt}Analysis weight:      `e(pweight)'" _c
	di "{col 48}Number of obs       ={res}{ralign 10:`e(N)'}"

	di "{txt}Replicate weights:    `e(brr_wspec)'" _c
	di "{txt}{col 48}Population size     ={res}{ralign 10:`e(N_pop)'}"

	di "{txt}Number of replicates: `e(N_reps)'" _c
	di "{txt}{col 48}Degrees of freedom{col 68}={res}{ralign 10:`e(df_r)'}"

	local df_d=e(df_r)-e(df_m)+1
	local dispF : di %3.2f e(F)

	di "{txt}k (Fay's method):     " %4.3f `fay' _c
	di "{txt}{col 48}F({res}{ralign 4:`e(df_m)'}{txt},{res}{ralign 7:`df_d'}{txt})     ={res}{ralign 10:`dispF'}"

	local prob=Ftail(`e(df_m)',`df_d',`e(F)')
	local prob : di %5.4f `prob'
	di "{txt}{col 48}Prob > F{col 68}={res}{ralign 10:`prob'}"

	local r2 : di %5.4f e(r2)
	if `r2'!=. {
		di `"{txt}{col 48}R-squared{col 68}={res}{ralign 10:`r2'}"'
	}
	di

	estimates display, level(`level') `eform'

	if `printdeff' {

		tempname df dt
		matrix `df'=e(deff)
		matrix `dt'=e(deft)
		tempname v

		di
		di "{hline 13}{c TT}{hline 22}"
		di %12s abbrev("`depv'",12) " {c |}      Deff       Deft"
		di "{hline 13}{c +}{hline 22}"

		local names : colnames `df'
		local i=colsof(`df')
		forval i=1/`i' {
			local vn : word `i' of `names'
			di "{txt}" %12s abbrev("`vn'",12) " {c |}" _c
			scalar `v'=`df'[1,`i']
			di "  {res}" %9.0g `v' _c
			scalar `v'=`dt'[1,`i']
			di "  " %9.0g `v' 
		}
		di "{txt}{hline 13}{c BT}{hline 22}"
			
	}

	
end


