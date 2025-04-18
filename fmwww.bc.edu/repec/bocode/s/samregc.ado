*===============================================================================================
* samregc: Sensitivity Analysis of the Main Regression Coefficients					   
* Authors:																			                  
* Pablo Glüzmann, CEDLAS-UNLP and CONICET - La Plata, Argentina - gluzmann@yahoo.com
* Demian Panigo, Instituto Malvinas, UNLP and CONICET - La Plata, Argentina - panigo@gmail.com 
*-----------------------------------------------------------------------------------------------
* Version 1.0 - 14-04-2025                                                          
*===============================================================================================
*DEFINE "samregc" PROGRAM
capture program drop samregc
program define samregc, rclass
qui {
	version 15.0
	*Define Syntax Program
	syntax varlist(min=2 numeric ts) [aw fw iw pw] [if] [in],	///
	[														   	///
	ITerateover(varlist numeric ts)						///
	GRITerateover(string)									///
	NComb(numlist >=1 integer max=2) 			   	///
	Fixvar(varlist numeric ts)								///
	CMDEst(string) 									   	///
	CMDOptions(string) 								   	///
	CMDIveq(string) 									   	///
	RESults(string) 								   	   ///
	REPlace 												   	///
	COUnt 												   	///
	DOuble 												   	///
	NOExcel														///
	NOGraph														///
	GRAPHTYpe(string)											///
	GRAPHTItle(string)                              ///
	GRAPHOptions(string)										///
	LEVel(real 95)											   ///
	at(real 0)											      ///
	SAMEsample 											   	///
	UNBalanced                                      ///
	SISters(string)        									///
	]
	if "`iterateover'" == "" & "`griterateover'" == "" {
			display as error "One or both of the options iterateover() or griterateover() are required."
			exit 503
	}
	if "`results'" == ""		 loc results "samregc"
	if "`cmdest'" == ""		 loc cmdest "regress"
	if "`graphtype'" == ""	 loc graphtype "gph"
	if "`graphtitle'" == ""	 loc graphtitle "varnames"
	if "`sisters'" != ""	    loc unbalanced "unbalanced"
	
	tempvar touse
	mark `touse' `if' `in'

	*Define Error Messages
	capture tsset
	loc time=r(timevar)
	loc panel=r(panelvar)
	if "`time'" == "."	loc time ""
	if "`panel'" == "."	loc panel ""

	if "`fixvar'" != "" {
		loc aux 0
		foreach var1 of varlist `fixvar'  {
			foreach var2 of varlist `varlist' {
				if "`var1'" == "`var2'" loc aux 1
			}
		}
		if `aux'==1 {
			display as error "Option fixvar contains at least one variable already included as main variable"
			exit 503
		}
	}
	if "`samesample'" != ""	 & "`unbalanced'" != "" {
			display as error "Option samesample cannot be combined with options unbalanced, sisters or arrows"
			exit 198
	}

	* Define and correct the location of the results
	loc path ""
	loc revresults=reverse("`results'")
	loc dta=substr("`results'",-4,.)
	loc dta=strmatch("`dta'",".dta")
	if `dta'==1 loc revresults=substr("`revresults'",5,.)
	loc results=reverse("`revresults'")
	loc posit=strpos("`revresults'","\")
	loc posit2=strpos("`revresults'","/")
	loc position = max(`posit',`posit2')
	if `posit'>0 & `posit2'>0 loc position=min(`posit',`posit2')
	if `position'!=0 {
		loc revpath =substr("`revresults'",`position',.)
		loc path =reverse("`revpath'")
	}
	if "`path'" == "" loc fname "`results'"
	if "`path'" != "" {
		loc posaux=`position'-1
		loc fname =substr("`results'",-`posaux',.)
	}
	loc length =length("`results'")
	loc aux 0

	if `length'>245-20 & "`path'" == "" {
		display as error "the path of the working directory is too long, change the working directory using command cd or specify shorter path using option results"
		exit 603
	}
	if `length'>245-20 & "`path'" != "" {
		display as error "the path specified in option results too long, specify a shorter path using option results"
		exit 603
	}
	preserve
	drop _all
	set obs 1
	tempname aux
	tempvar var1
	gen `var1' =1
	capture save "`results'.dta", `replace'
	if _rc == 602 {
		display as error "file `results'.dta already exists"
		exit 602
	}
	if _rc !=0 & "`path'" == "" {
		display as error "stata cannot save files in the working directory, change the working directory using command cd or specify another path using option results"
		exit 603
	}
	if _rc !=0 & "`path'" != "" {
		display as error "stata cannot save files the path specified in option results, change the working directory using command cd or specify another path using option results"
		exit 603
	}
	capture erase "`results'.dta"
	* Exports an empty Excel file to force an error if it already exists, or it is open
	if "`noexcel'" == "" {
		export excel using "`results'.xlsx", `replace'
		erase "`results'.xlsx"
	}

	* Split Depvar and MainVariables
	drop _all
	restore
	local wt: word 2 of `exp'
	tokenize `varlist'	
	loc depvar "`1'"
	macro shift 1
	loc MainVar "`*'"
	loc graphtitle_list ""
	loc nMainvar = wordcount("`MainVar'")
	loc nn=1
	foreach var of varlist `MainVar' {
		if "`graphtitle'" == "varnames" loc gr_mv`nn' "`var'"
		if "`graphtitle'" == "varlabels" {
			capture loc gr_mv`nn': variable label `var'
			if _rc !=0 | "`gr_mv`nn''" == "" loc gr_mv`nn' "`var'"
		}
		if `nn' ==1 loc graphtitle_list "`gr_mv`nn''"
		else loc graphtitle_list "`graphtitle_list'|`gr_mv`nn''"
		loc ++nn
	}
	* Split & add Instrumental Variables
	if "`cmdiveq'" != ""  {
			_iv_parse `depvar' (`cmdiveq')
			loc instruments "`s(inst)'"
			loc endogenous "`s(endog)'"
	}
	/*
	if "`instruments'" != "" & "`endogenous'" != "" {
		foreach var1 of local endogenous {
			local iterateover: subinstr local iterateover "`var1'" "", word
		}
		loc iterateover "`iterateover' `endogenous'"
	}
	*/
	if "`griterateover'" != "" & "`iterateover'"!= "" {
		loc aux 0
		foreach var1 in `griterateover'  {
			foreach var2 of varlist `iterateover' {
				if "`var1'" == "`var2'" loc aux 1
			}
		}
		if `aux'==1 {
			display as error "Option griterateover contains at least one variable already included in iterateover"
			exit 503
		}
	}
	if "`griterateover'" != "" {
		loc nwg: word count `griterateover'
		parse "`griterateover'",parse(|)
		loc gi =1
		forvalues i=1/`nwg' {
			if "``i''" != "|" & "``i''" != "" {
				tempname group`gi'
				loc `group`gi'' = "``i''"
				loc ++gi
			}
		}
		loc ng =`gi'-1
		loc groups_list ""
		loc var_groups_list ""
		forvalues gi=1/`ng' {
			loc groups_list "`groups_list' `group`gi''"
			loc var_groups_list "`var_groups_list' ``group`gi'''"
		}
	}
	* Complete the ncomb syntax
	if "`ncomb'" == "" {
		loc allcomb: word count `iterateover' `groups_list'
		loc ncomb "1 `allcomb'"
	}
	tokenize `ncomb'	
	loc kmin `1'
	if "`2'" != "" loc kmax `2'
	if "`2'" == "" loc kmax `1'
	if `kmin'>`kmax' {
		display as error "ncomb() invalid, elements out of order"
		exit 124
	}
	loc tindep: word count `iterateover' `groups_list'
	loc ListaTotVar "`MainVar' `fixvar' `iterateover' `var_groups_list'"
	if "`samesample'" != "" {
		tempvar aux
		gen `aux'=0 if `touse' ==1
		foreach var of varlist `ListaTotVar' {
			replace `aux'=1 if `touse' ==1 & `var'>=. 
		}
		replace `touse' =0 if `aux' ==1
	}
	* Calculate the total number of regressions to run
	loc Ntotreg 0
	loc total 0
	forvalues j=`kmin'/`kmax' {
		loc n1=comb(`tindep',`j')
		loc total = `total'+`n1'
	}
	* Including without varlist_iterate
	loc total = `total'+1
	if `total'<=0 | `total' >=. {
		display as error "Too few independent variables specified for selected combinatorial"
		exit 198
	}
	noi di as text "---------------------------------------------------------------------------"
	noi di as text " Baseline Regression: without iteration variables "
	noi di as text "---------------------------------------------------------------------------"
	* Split & add Instrumental Variables
	loc estim: word 2 of `cmdest'
	if ("`instruments'" != "" | "`estim'" == "gmm") {
		loc ivendogenous = ""
		foreach var1 of varlist `MainVar' `fixvar' {
			foreach var2 of local endogenous {
				if "`var1'" == "`var2'" loc ivendogenous " `ivendogenous' `var2' "
			}
		}
		loc anything2 "`MainVar' `fixvar'"
		foreach var1 of local ivendogenous {
			local anything2: subinstr local anything2 "`var1'" "", word
		}
		noi `cmdest' `depvar' `anything2' (`endogenous' =`instruments') [`weight'`exp'] if `touse' ==1 ,`cmdoptions'
	}
	else noi `cmdest' `depvar' `MainVar' `fixvar' [`weight'`exp'] if `touse' ==1 ,`cmdoptions'
	* check for omitted variables
	tempname bomit
	local noitnames : colfullnames e(b)
	mat `bomit' =e(b)
	loc omit =0
	foreach var1 of local noitnames {
		if substr("`var1'",1,2) == "o." loc omit=1
		if _b[`var1'] ==0 | _b[`var1'] ==. loc omit=1
	}
	if `omit'==1 {
		display as error "The estimation without iteration variables cannot contain variables omitted due to collinearity"
		exit 503
	}
	noi di as text "---------------------------------------------------------------------------"
	noi di as text "Total Number of Estimations: " as result "`total'"
	noi di as text "---------------------------------------------------------------------------"
	loc estcomoptions "cmde(`cmdest') cmdoptions(`cmdoptions') cmdstat(`cmdstat') results(`results') lastreg(`total') `double' `count' time(`time') panel(`panel') instruments(`instruments') endogenous(`endogenous')  " 
	local hh1: word count `fixvar'
	local hh2: word count `ListaTotVar'
	loc hh 1
	if `hh2'>`kmax'+`hh1' {
		foreach var of local ListaTotVar {
			if `hh'<=(`kmax'+`hh1') loc listaaux "`listaaux' `var'"
			loc ++hh
		}
	}
	else loc listaaux "`ListaTotVar'"
	* Estimate the execution time
	timer clear 99
	timer on 99
	tempname aux
	_samregc_estcomtry `depvar' `MainVar' `listaaux' [`weight'`exp'] if `touse' ==1 , matres2(`aux') `estcomoptions' ordervar(`ListaTotVar') nroreg(`Ntotreg') 
	loc error =r(noest)
	if `error' == 1 di as error "Time estimation was not performed."
	capture mat drop `aux'
	macro drop aux
	timer off 99
	timer list
	ret li
	loc time1 r(t99)
	timer clear 99
	loc timeprox =round((`time1'*`total')/50)
	if "`sisters'" != "" loc timeprox =round((`time1'*`total')/50)*2
	if `timeprox'>=3 {
		noi di as text "----------------------------------------------------------------------------------"
		noi di as text "Warning: Estimation could take about " as result "`timeprox'" as text " minutes or more"
		noi di as text "----------------------------------------------------------------------------------"
	}

	* Compute combinations
	noi di as text "Computing combinations..."
	forvalues combaux=1/`kmax' {
		tempfile __a_`combaux'
		loc __a_ "`__a_' `__a_`combaux''"
	}
	_samregc_combinate `__a_', nsamp(`tindep') ncomb(`kmin',`kmax')
	noi di as text "Preparing estimation list..."

	tokenize `iterateover' `groups_list'
	forvalues j=`kmin'/`kmax' {
		preserve
		use `__a_`j'', clear
		erase `__a_`j''
		loc v =_N
		loc v1 "`"
		loc v2 "'"
		d _all
		forvalues i =1/`v' {
			macro drop _reg`i' 
			foreach var of varlist _all {
				loc vaux = `var'[`i']
				if "`griterateover'" == "" loc reg`i' " `reg`i'' `v1'`vaux'`v2'"
				if "`griterateover'" != "" {
					loc vg = ""
					forvalues gi =1/`ng' {
						loc vv = "`v1'`vaux'`v2'"
						if "`vv'" == "`group`gi''" loc vg = "``group`gi'''"
					}
					if "`vg'" == "" loc reg`i' " `reg`i'' `v1'`vaux'`v2'"
					if "`vg'" != "" loc reg`i' " `reg`i'' `vg'"
				}
			}
		}
		restore
		forvalues i =1/`v' {
			loc ++Ntotreg
			loc regress`Ntotreg' "`reg`i''" 
			macro drop _reg_`i'
		}
	}
	noi di as text "Doing estimations..."
	
	* Create the results matrix in Mata
	* k = nro of variables
	* 1+k plus constant
	* (1+`k')*2 = t y coeff of all plus order 
	* 1+(1+`k')*2 +3 add 1 for order + 1 for observations + 1 number of variables + 1 for rank (variables that were effectively included)
	tempname resultados matres matres1 matres2 matres1S matres2S resultadosS matresS
	loc ListaTotsigleVar ""
	foreach var of varlist `ListaTotVar' {
		loc ListaTotsigleVar "`ListaTotsigleVar' `var'"
	}
	local k: word count `ListaTotsigleVar'
	mat `matres1' = J(1,(1+`k')*2,.)
	mat `matres2' = J(1,3,.)
	*`Ntotreg'+1== including without varlist_iterate 
	mata `resultados' = J(`Ntotreg'+1,1+(1+`k')*2+3,.)

	if "`sisters'" != "" {
		mat `matres1S' = J(1,(1+`k')*2,.)
		mat `matres2S' = J(1,3,.)
		*`Ntotreg'+1== including without varlist_iterate
		mata `resultadosS' = J(`Ntotreg'+1,1+(1+`k')*2+3,.)
	}
	* Add constant to the list
	loc aux = regexm("`cmdoptions'","nocons")
	if "`aux'" == "0" loc ListaTotVarCons "`ListaTotsigleVar' _cons"

	* Run regressions
	loc noestcom =0
	loc h=1
	*including without varlist_iterate 
	loc regress0 ""
	forvalues i=0/`Ntotreg' {
		loc error_est =0
		loc oreg =`i'
		*h=`i'-`noestcom'+1== including without varlist_iterate 
		loc h=`i'-`noestcom'+1
		noi _samregc_estcom `depvar' `MainVar' `fixvar' `regress`oreg'' [`weight'`exp'] if `touse' ==1 , matres1(`matres1')  matres2(`matres2') `estcomoptions' ordervar(`ListaTotVarCons') nroreg(`oreg') 
		loc zt =r(t)
		if "`zt'" == "." loc zt = "t"
		capture loc zt0 = v_`i'_`zt'[1] 

		if r(noest) ==1 {
			loc ++noestcom
			loc error_est =1
			continue
		}
		mat `matres' = `oreg',`matres1',`matres2'
		mata `resultados'[`h',.]=st_matrix("`matres'")

		* sisters regressions
		if "`sisters'" != "" {
			if "`samesample'" == "" {
				_samregc_estcom `depvar' `MainVar' `fixvar' [`weight'`exp'] if `touse' ==1 & e(sample), matres1(`matres1S')  matres2(`matres2S') `estcomoptions' ordervar(`ListaTotVarCons') nroreg(`oreg') 
				mat `matresS' = `oreg',`matres1S',`matres2S'
				mata `resultadosS'[`h',.]=st_matrix("`matresS'")
			}

			if "`samesample'" != "" {
				if `i'==1 _samregc_estcom `depvar' `MainVar' `fixvar' [`weight'`exp'] if `touse' ==1 , matres1(`matres1S')  matres2(`matres2S') `estcomoptions' ordervar(`ListaTotVarCons') nroreg(`oreg') 
				mat `matresS' = `oreg',`matres1S',`matres2S'
				mata `resultadosS'[`h',.]=st_matrix("`matresS'")
			}
		}
	}
	noi di as text "Saving results..."
	preserve
	drop _all
	getmata (v*) = `resultados'
	mata mata drop `resultados'
	loc i=1
	ren v`i' order
	label var order "Order number of estimation"
	loc i=2
	loc j=1

	foreach var of local ListaTotVarCons {
		loc h = `i'+1
		ren v`i' v_`j'_b 
		label var v_`j'_b "`var' coeff."
		if "`var'" == "_cons" label var v_`j'_b "Constant coeff."
		ren v`h' v_`j'_`zt' 
		label var v_`j'_`zt' "`var' `zt'-stat."
		if "`var'" == "_cons" label var v_`j'_`zt' "Constant `zt'-stat."
		loc i=`i'+2
		loc ++j
	}
	foreach name in obs nvar rank {
		ren v`i' `name'
		loc ++i
	}
	label var obs  "Number of observations"
	label var nvar "Number of variables"
	label var rank "Rank (excluding omitted variables)"
	*************************************************************************************************************************
	order v_*,  seq
	loc i=1
	foreach var of varlist v_*_b {
		capture ren `var' v_`i'_b 
		loc ++i
	}
	loc i=1
	foreach var of varlist v_*_`zt' {
		capture ren `var' v_`i'_`zt'
		loc ++i
	}
	if r(N)==0  {
		display as error "No estimations have been stored."
		exit 
	}

	order order, first
	if "`double'" != "" {
		if "`cmdstat'" != "" {
			foreach i of local cmdstat {
				capture format `i' %20.0g
			}
			
		}
	}
	drop if order ==.
	gen omitted =0
	foreach var of varlist *_b {
		replace omitted =1 if `var'== 0 
	}
	replace omitted =. if order ==0
	label var omitted "=1 One or more variables were omitted because of collinearity"
	compress
	sort order
	noi save "`results'.dta", `replace'
	count if omitted ==1
	loc est_omit =r(N)
	if "`nograph'" == "" noi _samregc_g1 `MainVar' if omitted == 0 , path(`path') `replace' at(`at') level(`level') graphtype(`graphtype') graphoptions(`graphoptions') graphtitle_list(`graphtitle_list') zt(`zt') 
	tempname table1 
	noi _samregc_table1 `MainVar' if omitted == 0 & order!=0, path(`path') `replace' results(`results') at(`at') level(`level') mtname(`table1') zt(`zt')

	return matrix table1 = `table1'
   
	return local Pos    =r(Pos)
	return local Neg    =r(Neg)
	return local st_Low =r(st_Low)
	return local st_Ins =r(st_Ins)
	return local st_Up  =r(st_Up)
	return local Total  =r(Total)
	if `est_omit'>0 {
		return local Est_Omit =r(Est_Omit)
		return local Tot_Est  =r(Tot_Est)
	}
	if `est_omit'==0 return local Table1Colnames Pos Neg st_Low st_Ins st_Up Total 
	if `est_omit'>0 return local Table1Colnames  Pos Neg st_Low st_Ins st_Up Total Total
   sum obs if order!=0
	if r(min) != r(max) loc sameobs =0 
	if r(min) == r(max) loc sameobs =1 

	noi display as text 
	if `sameobs' !=1 & "`unbalanced'" == "" {
		noi di as text "--------------------------------------------------------"
		noi di as text " Unbalanced sample across covariates"
	   noi di as text " Use options unbalanced and sisters for further analysis"
		noi di as text "--------------------------------------------------------"
	}

	if "`unbalanced'" != "" & "`nograph'" == "" noi _samregc_scatterbt `MainVar' if omitted == 0 , path(`path') `replace' at(`at') level(`level') graphtype(`graphtype') graphoptions(`graphoptions') graphtitle_list(`graphtitle_list') zt(`zt') 
	
	if "`sisters'" != "" {
		drop _all
		getmata (v*) = `resultadosS'
		mata mata drop `resultadosS'
		loc i=1
		ren v`i' order
		label var order "Order number of estimation"
		loc i=2
		loc j=1

		foreach var of local ListaTotVarCons {
			loc h = `i'+1
			foreach mainvar in `MainVar' {
				if "`var'" == "`mainvar'" {
					ren v`i' v_`j'_bSIS 
					label var v_`j'_bSIS "`var' coeff. of Sister Estim."
					ren v`h' v_`j'_`zt'SIS 
					label var v_`j'_`zt'SIS "`var' `zt'-stat. of Sister Estim."
				}
			}
			loc i=`i'+2
			loc ++j
		}
		keep order v_*
		*************************************************************************************************************************
		order v_*,  seq
		loc i=1
		foreach var of varlist v_*_bSIS {
			capture ren `var' v_`i'_bSIS 
			loc ++i
		}
		loc i=1
		foreach var of varlist v_*_`zt'SIS {
			capture ren `var' v_`i'_`zt'SIS
			loc ++i
		}

		if r(N)==0  {
			display as error "No estimations has been stored"
			exit 
		}

		order order, first
		if "`double'" != "" {
			if "`cmdstat'" != "" {
				foreach i of local cmdstat {
					capture format `i' %20.0g
				}
				
			}
		}
		drop if order ==.
		drop if order ==0
		compress
		sort order
		tempfile sisters_coef
		save `sisters_coef', replace
		drop _all
		use "`results'.dta"
		merge 1:1 order using `sisters_coef'
		foreach var of varlist *SIS {
			replace `var' =. if omitted ==1 & order!=0
		}
		drop _merge 
		save "`results'.dta", replace
		if "`nograph'" == "" noi _samregc_g_sisters `MainVar' if omitted == 0 ,path(`path') `replace' at(`at') level(`level') graphtype(`graphtype') graphoptions(`graphoptions') graphtitle_list(`graphtitle_list') sisters(`sisters')  zt(`zt') 
	}

	loc mainList ""
	foreach var in `MainVar' {
		loc a =ustrtoname("`var'")
		tempname `a'Table
		loc mainList "`mainList' ``a'Table'"
	}
	loc obs_no_it = obs[1]
	noi _samregc_MvTable `MainVar' if omitted == 0 & order!=0, path(`path') `replace' results(`results') at(`at') level(`level')  fixvar(`fixvar') `unbalanced' sisters(`sisters') mtname(`mainList') zt(`zt') obs_no_it(`obs_no_it') `noexcel'
	loc list_var_des =r(list_var_des)
	foreach vd in `list_var_des' {
		return local `vd' =r(`vd')
	}	
	return local MainVarColnames  `list_var_des'
                
	foreach var in `MainVar' {
		loc a =ustrtoname("`var'")
	   return matrix `a'_Table = ``a'Table'
	}

	restore
}
end


*****************************************************************************************************
* auxiliary subprograms
*****************************************************************************************************

* "_samregc_combinate" SUBPROGRAM
capture program drop _samregc_combinate
program define _samregc_combinate

	syntax anything ,NSamp(integer) NComb(numlist >0 integer max=2) [Reps] [*]
	preserve
	tokenize `ncomb'
	loc kmin `1'
	if "`2'" !="" loc kmax `2'
	if "`2'" == "" loc kmax `1'
	tokenize `anything'
	clear
	set obs `nsamp'
	gen aux1=_n
	tempfile temp
	save `temp', replace
	if `kmin' ==1 {
		save "`1'", replace
		count
	}
	if `kmax' >=2 {
		loc lista_ant = "aux1 "
		tempfile foto
		save `foto', replace
		forvalues j=2/`kmax' {
			tempfile temp`j'
			ren aux aux`j'
			save `temp`j'', replace
		}
		use `foto', clear
		forvalues j=2/`kmax' {
			loc j_1 =`j'-1
			cross using `temp`j''
			if "`reps'" == "" drop if aux`j_1'>=aux`j'
			if "`reps'" !="" drop if aux`j_1'>aux`j'
			if `kmin'<=`j' {
				save "``j''", replace
				count
			}
		}
	}
	restore
end

* "_samregc_estcom" SUBPROGRAM
capture program drop _samregc_estcom
program define _samregc_estcom, rclass
qui	{
	loc setmoreprev=c(more)
	set more off
	syntax anything [aw fw iw pw] [if], matres1(string) matres2(string) CMDEst(string) [CMDOptions(string) cmdstat(string)] results(string) ordervar(string) [nroreg(integer 0) lastreg(integer 0) double COUnt time(string) panel(string) instruments(string) endogenous(string) ] [*]
	if "`count'" != "" noi di as text "Estimation number " as result "`nroreg'" as text " of " as result "`lastreg'"
	loc error =0
	tempvar touse insample
	tempname table
	mark `touse' `if' 
	gen `insample' =1 if `touse'==1
	if "`instruments'" != "" {
		foreach var1 of local anything {
			foreach var2 of local endogenous {
				if "`var1'" == "`var2'" loc ivendogenous " `ivendogenous' `var2' "
			}
		}
		loc anything2 "`anything'"
		local anything2: subinstr local anything2 "[]" "", word
		foreach var1 of local ivendogenous {
			local anything2: subinstr local anything2 "`var1'" "", word
		}
		loc estim: word 2 of `cmdest'
		if ("`ivendogenous'" != "" | "`estim'" == "gmm") {
			loc dependiente: word 1 of `anything2' 
			capture `cmdest' `anything2' (`ivendogenous' =`instruments') [`weight'`exp'] if `insample'==1, `cmdoptions'
			if _rc !=0 loc error = _rc
			if _rc ==0 capture mat `table' =r(table)
		}
		else {
			loc dependiente: word 1 of `anything2' 
			capture `cmdest' `anything2' [`weight'`exp'] if `insample'==1, `cmdoptions'
			if _rc !=0 loc error = _rc
			if _rc ==0 capture mat `table' =r(table)
		}
	}
	else {
		loc dependiente: word 1 of `anything' 
		capture `cmdest' `anything' [`weight'`exp'] if `insample'==1, `cmdoptions'
		if _rc !=0 loc error = _rc
		if _rc ==0 capture mat `table' =r(table)
	}
}

if `error' == 0 {
	tempname betas sigmas t 
	mat `betas'  =e(b) 
	loc nvar     = colsof(`betas')
	loc obs      = e(N)
	loc rank     = e(rank)
	if `rank'    ==0 exit
	capture loc nv2 = colsof(`table')
	if _rc ==0 & `nvar' == `nv2' {
		capture mat `t' =`table'["t",1...]
		if _rc !=0 {
			return local t = "z"
			mat `t' =`table'["z",1...]
		}
	}
	else {
		mat `sigmas' = e(V)
		capture mat `t'=(`betas'*inv(cholesky(diag(vecdiag(`sigmas')))))
		if _rc !=0 {
			mat `t' = `betas'
			forvalues i=1/`nvar'{
				mat `t'[1,`i'] = `betas'[1,`i'] / `sigmas'[`i',`i']^.5
			}
		}
	}
	mat `matres1'=`matres1'*.
	loc i=1
	loc h=1
	local names : colfullnames e(b)
	foreach var1 of local ordervar {
		foreach var2 of local names {
			if "`var1'" == "`var2'" | "o.`var1'" == "`var2'" | "`dependiente':o.`var1'" == "`var2'" | "`dependiente':`var1'" == "`var2'" {
				mat `matres1'[1,`i']=`betas'[1,`h']
				mat `matres1'[1,`i'+1]=`t'[1,`h']
				loc ++h	
			} 
		}
		loc i=`i'+2
	}
	mat `matres2' = `obs',`nvar',`rank'
	if "`cmdstat'" != "" {
		tempname aux
		foreach i of local cmdstat {
			mat `aux'=e(`i')
			mat colnames `aux'= `i'
			mat `matres2'=`matres2',`aux'
		}
	}
	if "`setmoreprev'" == "on" set more on
}
if `error' !=0 {
	noi di as text "Error " as input "r(" `error' ")" as text " in estimation number " as result "`nroreg'" 
	return scalar noest =1
	sleep 300
	exit
}

end

* "_samregc_estcomtry" SUBPROGRAM
capture program drop _samregc_estcomtry
program define _samregc_estcomtry, rclass
qui	{
	loc setmoreprev=c(more)
	set more off
	syntax anything [aw fw iw pw] [if], matres2(string) CMDEst(string) [CMDOptions(string) cmdstat(string)] results(string) ordervar(string) [nroreg(integer 0) lastreg(integer 0) double COUnt time(string) panel(string) instruments(string) endogenous(string) ] [*]
	loc error =0
	tempvar touse insample
	tempname table
	mark `touse' `if' 
	gen `insample' =1 if `touse'==1
	if "`instruments'" !="" {
		foreach var1 of local anything {
			foreach var2 of local endogenous {
				if "`var1'" == "`var2'" loc ivendogenous " `ivendogenous' `var2' "
			}
		}
		loc anything2 "`anything'"
		local anything2: subinstr local anything2 "[]" "", word
		foreach var1 of local ivendogenous {
			local anything2: subinstr local anything2 "`var1'" "", word
		}
		loc estim: word 2 of `cmdest'
		if ("`ivendogenous'" !="" | "`estim'" == "gmm") {
			loc dependiente: word 1 of `anything2' 
			capture `cmdest' `anything2' (`ivendogenous' =`instruments') [`weight'`exp'] if `insample'==1, `cmdoptions'
			if _rc !=0 loc error = _rc
			if _rc ==0 capture mat `table' =r(table)
		}
		else {
			loc dependiente: word 1 of `anything2' 
			capture `cmdest' `anything2' [`weight'`exp'] if `insample'==1, `cmdoptions'
			if _rc !=0 loc error = _rc
			if _rc ==0 capture mat `table' =r(table)
		}
	}
	else {
		loc dependiente: word 1 of `anything' 
		capture `cmdest' `anything' [`weight'`exp'] if `insample'==1, `cmdoptions'
		if _rc !=0 loc error = _rc
		if _rc ==0 capture mat `table' =r(table)
	}
}

if `error' == 0 {
	tempname betas sigmas t 
	mat `betas'  =e(b) 
	loc nvar     = colsof(`betas')
	loc obs      = e(N)
	loc rank     = e(rank)
	if `rank'    ==0 exit
	capture loc nv2 = colsof(`table')
	if _rc ==0 & `nvar' == `nv2' {
		capture mat `t' = `table'["t",1...]
		if _rc !=0 {
			return local t = "z"
			mat `t' =`table'["z",1...]
		}
	}
	else {
		mat `sigmas' = e(V)
		capture mat `t'=(`betas'*inv(cholesky(diag(vecdiag(`sigmas')))))
		if _rc !=0 {
			mat `t' = `betas'
			forvalues i=1/`nvar'{
				mat `t'[1,`i'] = `betas'[1,`i'] / `sigmas'[`i',`i']^.5
			}
		}
	}
	mat `matres2' = `obs',`nvar', `rank'
	if "`cmdstat'" !="" {
		tempname aux
		foreach i of local cmdstat {
			mat `aux'=e(`i')
			mat colnames `aux'= `i'
			mat `matres2'=`matres2',`aux'
		}
	}
	if "`setmoreprev'" == "on" set more on
}
if `error' !=0 {
	noi di as text "Error " as input "r(" `error' ")" as text "estimating time in estimation number " as result "`nroreg'" 
	return scalar noest =1
	sleep 300
	exit
}

end

* "_samregc_table1" SUBPROGRAM
capture program drop _samregc_table1
program define _samregc_table1, rclass
	qui	{
		syntax anything [if], [replace path(string) results(string) level(real 95) at(real 0) mtname(string) zt(string) ] [*]
		loc vt =invnorm((100-`level')/200)
		tempname table1_1 table1
		mat `table1_1' =J(1,8,.)
		loc i=1
		tempvar touse
		mark `touse' `if'
		foreach var in `anything' {
			mat `table1' =J(1,8,.)
			count if v_`i'_b >=  `at' & `touse'==1
			mat `table1'[1,1] =r(N)
			count if v_`i'_b < `at' & `touse'==1
			mat `table1'[1,2] =r(N)
			

			loc lx = round(`at' + `vt',0.01)
			loc ux = round(`at' - `vt',0.01)

			count if v_`i'_`zt' < `lx' & `touse'==1
			mat `table1'[1,3] =r(N)
			count if v_`i'_`zt' >= `lx' & v_`i'_`zt' <= `ux' & `touse'==1
			mat `table1'[1,4] =r(N)
			count if v_`i'_`zt' > `ux' & `touse'==1
			mat `table1'[1,5] =r(N)
			count if v_`i'_`zt' != . & `touse'==1
			loc totval =r(N)
			mat `table1'[1,6] = `totval'
			count if v_`i'_`zt' != .
			* -1 == varlist_iterate
			loc totest =r(N)-1
			loc est_omit = `totest'-`totval'
			mat `table1'[1,7] = `est_omit'
			mat `table1'[1,8] = `totest'			
			mat `table1_1' = `table1_1' \ `table1'
			loc ++i
		}

		preserve
		drop _all
		svmat `table1_1' 
		drop if _n==1
		gen varname = ""
		loc i=1
		foreach var in `anything' {
			replace varname = "`var'" in `i'
			loc ++i
		}
		order varname, first
		rename `table1_1'1 Pos
		rename `table1_1'2 Neg
		rename `table1_1'3 st_Low
		rename `table1_1'4 st_Ins
		rename `table1_1'5 st_Up
		rename `table1_1'6 Total
		rename `table1_1'7 Est_Omit
		rename `table1_1'8 Tot_Est
		loc dPos      "Coeff. > `at'"
		loc dNeg      "Coeff. < `at'"
		loc dst_Low    "Coeff. significantly below the `level'% conf. interval"
		loc dst_Ins    "Coeff. inside `level'% conf. interval (not significantly diff. from `at')"
		loc dst_Up     "Coeff. significantly above the `level'% conf. interval"
		loc dTotal    "Total number of valid estimations"
		loc dEst_Omit "Number of estimations with omitted variables"
		loc dTot_Est  "Total number estimations"
		loc list_var "Pos Neg st_Low st_Ins st_Up Total Est_Omit Tot_Est "
		noi di as text " "
		noi di as text " Valid Estimations decomposition:"
		noi di as text "---------------------------------"
		loc totm1 =`totest'+1
		if `est_omit' !=0 {
			
			noi di as text " Total estimations: " as result `totm1'
			noi di as text " Total estimations excluding the baseline regression: " as result `totest'
			noi di as text " Estimations excluded because of omitted variables: " as result `est_omit'
			noi di as text " Valid estimations: " as result `totval'
		}
		if `est_omit' ==0 {
			noi di as text " Total estimations: " as result `totm1'
			noi di as text " Total estimations excluding the baseline regression: " as result `totest'
			drop Est_Omit Tot_Est
			loc dTotal    "Total number of estimations"
			label var Total "`dTotal'"
			return local Total "`dTotal'"
			loc list_var "Pos Neg st_Low st_Ins st_Up Total"
		}
		foreach v in `list_var' {
			label var `v' "`d`v''"
			return local `v' "`d`v''"
		}
		noi di as text " "
		noi di as text " Acronyms description:"
		noi di as text "----------------------"
		foreach v in `list_var' {
			noi di as text " `v': `d`v''"
		}
		noi di as text " "
		noi di as text " Table 1 (values): Aggregate impact of iteration vars. on each main var."
		noi di as text "------------------------------------------------------------------------"
		mkmat  `list_var' , matrix(`mtname') rownames(varname)
		if "`noexcel'" == "" export excel using "`results'.xlsx", sheet("Table 1", modify) firstrow(varlabels) keepcellfmt
		noi list, noobs table divider
		replace Pos     = round(Pos     / Total *100, 0.1)
		replace Neg     = round(Neg     / Total *100, 0.1)
		replace st_Low   = round(st_Low   / Total *100, 0.1)
		replace st_Ins   = round(st_Ins / Total *100, 0.1)
		replace st_Up    = round(st_Up    / Total *100, 0.1)
		drop Total 
		if `est_omit' !=0 drop Est_Omit Tot_Est
		noi di as text " "
		noi di as text " Table 1 (percentages)"
		noi di as text "----------------------"
		noi list, noobs table divider
		if "`noexcel'" == "" export excel using "`results'.xlsx", sheet("Table 2", modify) firstrow(varlabels) keepcellfmt
		restore
	}

end

* "_samregc_g1" SUBPROGRAM
capture program drop _samregc_g1
program define _samregc_g1, rclass
	qui	{
		syntax anything [if], [path(string) replace level(real 95) at(real 0) graphtype(string) graphoptions(string) graphtitle_list(string) zt(string) ] [*]
		loc vt =invnorm((100-`level')/200)
		parse "`graphtitle_list'",parse(|)
		loc ngrit=1
		loc i=1
		foreach var in `anything' {
			loc graphtitle "``ngrit''"
			sum v_`i'_b `if' , mean
			loc rmin =r(min)
			loc rmax =r(max)
			* beta coefficient without iteration variables
			loc beta0 = v_`i'_b[1] 
			* z or t statistic without iteration variables
			loc zt0 = v_`i'_`zt'[1] 
			* Extend the range to include beta0
			if `rmin' > `beta0' loc rmin = `beta0'
			if `rmax' < `beta0' loc rmax = `beta0'
			* include 0 in y-axis

			kdensity v_`i'_b `if' & _n!=1, xline(`beta0') yscale(range(0)) xscale(range(`rmin' `rmax')) text(0 `beta0' "Coefficient without iteration variables", place(neast) orientation(vertical) ) xtitle("`graphtitle' coeff.")  `graphoptions'
			if "`graphtype'" == "gph" noi graph save "`path'/kdensity_b_`var'.`graphtype'", `replace'
			else if "`graphtype'" != "" noi graph export "`path'/kdensity_b_`var'.`graphtype'", `replace' as(`graphtype')
			loc lx =`at'+`vt'
			loc ux =`at'-`vt'
			sum v_`i'_`zt' `if', mean
			loc rmin =r(min)
			loc rmax =r(max)
			* Extend the range to include interval + zt0
			if `rmin' > `lx' loc rmin =`lx'
			if `rmax' < `ux' loc rmax =`ux'
			loc agrego_xline `" xline(`lx') xline(`ux') xline(`zt0') yscale(range(0)) xscale(range(`rmin' `rmax')) text(0 `lx' "`level'% lower conf. interval", place(neast) orientation(vertical) ) text(0 `ux' "`level'% upper conf. interval", place(nwest) orientation(vertical) ) text(0 `zt0' "`zt'-stat. without iteration variables", place(neast) orientation(vertical) )"'
			* "
			kdensity v_`i'_`zt' `if' & _n!=1, `agrego_xline' xtitle("`graphtitle' coeff.") `graphoptions'

			if "`graphtype'" == "gph" noi graph save "`path'/kdensity_t_`var'.`graphtype'", `replace'
			else if "`graphtype'" != "" noi graph export "`path'/kdensity_t_`var'.`graphtype'", `replace' as(`graphtype')
			loc ++i
			loc ngrit = `ngrit' +2
		}
	}
end

* "_samregc_scatterbt" SUBPROGRAM
capture program drop _samregc_scatterbt
program define _samregc_scatterbt, rclass
	qui	{
		syntax anything [if], [path(string) replace level(real 95) at(real 0) graphtype(string) graphoptions(string) graphtitle_list(string) zt(string) ] [*]
		loc vt =invnorm((100-`level')/200)
		parse "`graphtitle_list'",parse(|)
		loc ngrit=1
		loc i=1
		foreach var in `anything' {
			loc graphtitle "``ngrit''"
			* t or z statistic without iteration variables
			loc b0 = v_`i'_b[1] 
			loc zt0 = v_`i'_`zt'[1] 
			

			loc lx =`at' + `vt'
			loc ux =`at' - `vt'
			if `zt0'<=`lx' loc ztpos "neast"
			if `zt0'>`lx'  loc ztpos "seast"
			sum obs, mean
			loc pos =r(min)
			* Extend the range to include interval + zt0
			sum v_`i'_`zt' `if', mean
			loc rmin =r(min)
			loc rmax =r(max)
			if `rmin' > `lx' loc rmin =`lx'
			if `rmax' < `ux' loc rmax =`ux'

			* scatter of coeff.
			twoway (scatter v_`i'_b obs `if' & order!=0, title(`graphtitle') ytitle("Coefficient values") legend(off) yline(`b0') text(`b0' `pos' "Coeff. without iteration variables", place(seast)) mfcolor(none)) , `graphoptions'
			if "`graphtype'" == "gph" noi graph save "`path'/unbalanced_b_`var'.`graphtype'", `replace'
			else if "`graphtype'" != "" noi graph export "`path'/unbalanced_b_`var'.`graphtype'", `replace' as(`graphtype') 

			* scatter of t/z statistic
			loc add_yline `" yline(`lx') yline(`ux') yline(`zt0') yscale(range(`rmin' `rmax')) text(`lx' `pos' "`level'% lower c.i.", place(neast)) text(`ux' `pos' "`level'% upper c.i.", place(seast)) text(`zt0' `pos' "`zt'-stat. without iteration var.", place(`ztpos')) mfcolor(none) "'
			* "
			twoway (scatter v_`i'_`zt' obs `if' & order!=0, title(`graphtitle') `add_yline' ytitle("`zt'-statistic") legend(label(1 "`zt'-statistic"))) (lfit v_`i'_`zt' obs `if' & order!=0,legend(label(2 "Linear fit"))), `graphoptions'
			if "`graphtype'" == "gph" noi graph save "`path'/unbalanced_`zt'_`var'.`graphtype'", `replace'
			else if "`graphtype'" != "" noi graph export "`path'/unbalanced_`zt'_`var'.`graphtype'", `replace' as(`graphtype')
			loc ++i
			loc ngrit = `ngrit' +2
		}
	}
end


* "_samregc_g_sisters" SUBPROGRAM
capture program drop _samregc_g_sisters
program define _samregc_g_sisters, rclass
	qui	{
		syntax anything [if], [path(string) replace level(real 95) at(real 0) graphtype(string) graphoptions(string) graphtitle_list(string) sisters(string) zt(string) ] [*]
		loc vt = -invnorm((100-`level')/200)
		parse "`graphtitle_list'",parse(|)
		loc ngrit =1
		loc i=1
		foreach var in `anything' {
			loc graphtitle "``ngrit''"
			* t or z statistic without iteration variables (Benchmark)
			loc zt0 = v_`i'_`zt'[1] 
			
			loc lx = `at' - `vt'
			loc ux = `at' + `vt'
			if `zt0'<=`lx' loc ztpos "neast"
			if `zt0'>`lx'  loc ztpos "seast"
			sum obs, mean
			loc pos =r(min)
			* add range
			sum v_`i'_`zt' `if', mean
			loc rmin =r(min)
			loc rmax =r(max)
			* Extend the range to include sisters
			sum v_`i'_`zt'SIS `if' & _n!=1, mean
			if r(min) <`rmin' loc rmin=r(min)
			if r(max) <`rmax' loc rmax=r(max)
			* Extend the range to include interval + zt0
			sum v_`i'_`zt' `if', mean
			loc rmin =r(min)
			loc rmax =r(max)
			if `rmin' > `lx' loc rmin =`lx'
			if `rmax' < `ux' loc rmax =`ux'
			

			loc add_yline `" yline(`lx') yline(`ux') yline(`zt0') yscale(range(`rmin' `rmax')) text(`lx' `pos' "`level'% lower c.i.", place(neast)) text(`ux' `pos' "`level'% upper c.i.", place(seast)) text(`zt0' `pos' "`zt'-stat. without iteration var.", place(`ztpos'))  "'
			* "
			*Arrow plot, color-coded for positive and negative changes
			capture clonevar v_`i'_`zt'SIS = v_`i'_zSIS 
			if "`sisters'" == "scatter" | "`sisters'" == "both" {
				twoway (scatter v_`i'_`zt' obs `if' & _n!=1, title(`graphtitle') pstyle(p1) `add_yline' ytitle("`zt'-statistic") legend(label(1 "With iteration variables")) mfcolor(none)) (scatter v_`i'_`zt'SIS obs `if', msymbol(T) pstyle(p2) legend(label(2 "Without iteration variables")) mfcolor(none)) (lfit v_`i'_`zt' obs, pstyle(p1) legend(label(3 "lfit: with iteration var."))) (lfit v_`i'_`zt'SIS obs, pstyle(p2) legend(label(4 "lfit: without iteration var."))), `graphoptions'
				if "`graphtype'" == "gph" noi graph save "`path'/sisters_scatter_`var'.`graphtype'", `replace'
				else if "`graphtype'" != "" noi graph export "`path'/sisters_scatter_`var'.`graphtype'", `replace' as(`graphtype')
			}			
			if "`sisters'" == "pcarrow" | "`sisters'" == "both" {
				twoway (pcarrow v_`i'_`zt'SIS obs v_`i'_`zt' obs `if' & v_`i'_`zt'SIS-v_`i'_`zt' <=0 & _n!=1, title(`graphtitle') legend(label(1 "Sister `zt'-stat < `zt'-stat")) ytitle("`zt'-statistic") `add_yline' mstyle(p3arrow) color(green)  barbsize(1)) (pcarrow v_`i'_`zt'SIS obs v_`i'_`zt' obs `if' & v_`i'_`zt'SIS-v_`i'_`zt' >0 & _n!=1, `add_yline' color(maroon) barbsize(1) legend(label(2 "Sister `zt'-stat > `zt'-stat"))), `graphoptions' 
				if "`graphtype'" == "gph" noi graph save "`path'/sisters_pcarrow_`var'.`graphtype'", `replace'
				else if "`graphtype'" != "" noi graph export "`path'/sisters_pcarrow_`var'.`graphtype'", `replace' as(`graphtype')
			}			
			loc ++i
			loc ngrit = `ngrit' +2
		}
	}
end


* "_samregc_MvTable" SUBPROGRAM
capture program drop _samregc_MvTable
program define _samregc_MvTable, rclass
	qui	{
		syntax anything [if],  [path(string) replace level(real 95) at(real 0) results(string) fixvar(string) unbalanced sisters(string) mtname(string) zt(string) obs_no_it(integer 0)] [*]
		tokenize `mtname'
		if "`sisters'" != "" loc altn "SIS"
		if "`sisters'" == "" {
			loc altn "BASE"
			loc i=1
			foreach var in `anything' {
				gen v_`i'_`zt'BASE =v_`i'_`zt'[1]
				gen v_`i'_bBASE =v_`i'_b[1]
				loc ++i
			}
		}
		keep `if'
		loc vt = -invnorm((100-`level')/200)
		loc ndrop =wordcount("`anything'")+wordcount("`fixvar'")
		loc lx = round(`at' - `vt',0.01)
		loc ux = round(`at' + `vt',0.01)
		loc i=1
		foreach var in `anything' {
			preserve
			* Range changes: significant to non-significant
			gen aux_`zt'lost = 0 
			* Positive changes
			replace aux_`zt'lost = 1 if v_`i'_`zt'`altn' < `lx' & (v_`i'_`zt' >= `lx' & v_`i'_`zt' <= `ux') 
			* Negative changes
			replace aux_`zt'lost = 2 if v_`i'_`zt'`altn' > `ux' & (v_`i'_`zt' >= `lx' & v_`i'_`zt' <= `ux') 
			* Never significant
			replace aux_`zt'lost = 3 if (v_`i'_`zt'`altn' >= `lx' & v_`i'_`zt'`altn' <= `ux') & (v_`i'_`zt' >= `lx' & v_`i'_`zt' <= `ux')

			* t-statistic changes
			gen aux_`zt'changes = 0 
			* Increase
			replace aux_`zt'changes = 1 if v_`i'_`zt'>v_`i'_`zt'`altn'
			* Decrease
			replace aux_`zt'changes = 2 if v_`i'_`zt'<=v_`i'_`zt'`altn'

			* Significant t-statistic changes
			gen aux_`zt'sig = 0 
			* Significant increase
			replace aux_`zt'sig = 1 if abs(v_`i'_`zt'-v_`i'_`zt'`altn') >= `vt'/2 & v_`i'_`zt'<0 & (v_`i'_`zt'>v_`i'_`zt'`altn')
			* Significant decrease
			replace aux_`zt'sig = 2 if abs(v_`i'_`zt'-v_`i'_`zt'`altn') >= `vt'/2 & v_`i'_`zt'>=0 & (v_`i'_`zt'<=v_`i'_`zt'`altn')

			* no significant on NIT/SIS
			gen aux_`zt'nosig = 1 if (v_`i'_`zt'`altn' >= `lx' & v_`i'_`zt'`altn' <= `ux') 
			
			foreach v of varlist aux_`zt'lost aux_`zt'sig aux_`zt'nosig {
				replace `v' =. if v_`i'_`zt' ==0 | v_`i'_`zt' ==.
				replace `v' =. if v_`i'_`zt'`altn' ==0 | v_`i'_`zt'`altn' ==.
			}
			gen nreglostsig =1 if aux_`zt'lost !=.
			replace nreglostsig =2 if aux_`zt'sig !=.
			replace nreglostsig =3 if aux_`zt'nosig !=.
			count if nreglostsig!=.
			loc tot =r(N)
			if `tot' == 0 {
				noi di as text "----------------------------------------------------"
				noi di as text " `var': No iterations "
				noi di as text "----------------------------------------------------"
				restore
				loc ++i
				continue
			}
			drop nvar  
			tempfile aux
			save `aux', replace
			* drop main and fix variables
			forvalues f =1/`ndrop' {
				drop v_`f'_`zt'
				drop v_`f'_b
				cap drop v_`f'_`zt'`altn'
				cap drop v_`f'_b`altn'
			}
			loc listav ""
			foreach cvar of varlist *_`zt' {
				loc listav "`listav' `cvar'"
				replace `cvar' =1 if `cvar'!=0 & `cvar'!=.
			}
			merge 1:1 order using `aux'
			drop if _merge ==1
			drop if _merge ==2
			drop _merge order 
			loc nv = wordcount("`listav'")
			tempname lv
			mat `lv' =J(`nv',14,.)
			if "`unbalanced'" != "" mat `lv' =J(`nv',18,.)
			loc j=1
			foreach sv of varlist `listav' {
				* numero de veces que se incluye la variable de iteracion `sv'
				* Number of estim. where the iteration variable is included
				sum `sv', mean
				mat `lv'[`j',1]=r(sum)
				* numero de veces que se incluye la iter var `sv' + changes from signif. to not signif.
				* Number of estim. where the iteration var. renders the main var. not significant
				sum `sv' if aux_`zt'lost ==1 | aux_`zt'lost ==2, mean
				mat `lv'[`j',2]=r(sum)
				* numero de veces que se incluye la iter var `sv' + positive changes from signif. to not signif.
				sum `sv' if aux_`zt'lost ==1, mean
				mat `lv'[`j',3]=r(sum)
				* numero de veces que se incluye la iter var `sv' + negative changes from signif. to not signif.
				sum `sv' if aux_`zt'lost ==2, mean
				mat `lv'[`j',4]=r(sum)

				* numero de veces que se incluye la iter var `sv' + MV no significant without ItV  
				sum `sv' if aux_`zt'nosig ==1, mean
				mat `lv'[`j',5]=r(sum)
				* numero de veces que se incluye la iter var `sv' + never significant 
				sum `sv' if aux_`zt'lost ==3, mean
				mat `lv'[`j',6]=r(sum)

				* numero de veces que se incluye la iter var `sv' + Increase
				sum `sv' if aux_`zt'changes ==1, mean
				mat `lv'[`j',7]=r(sum)
				* numero de veces que se incluye la iter var `sv' + Decrease
				sum `sv' if aux_`zt'changes ==2, mean
				mat `lv'[`j',8]=r(sum)

				* numero de veces que se incluye la iter var `sv' + Significant increase
				sum `sv' if aux_`zt'sig ==1, mean
				mat `lv'[`j',9]=r(sum)
				* numero de veces que se incluye la iter var `sv' + Significant decrease
				sum `sv' if aux_`zt'sig ==2, mean
				mat `lv'[`j',10]=r(sum)

				*Average coefficient of main variable where iteration variable is included
				sum v_`i'_b if `sv' ==1, mean
				mat `lv'[`j',11]=r(mean)
				*SIS: Average coefficient of main variable on Sister Estimations
				*NIT: Coefficient of main variable without iteration variables 
				sum v_`i'_b`altn' if `sv' ==1, mean
				mat `lv'[`j',12]=r(mean)
				*Average `zt'-statistic of main variable where iteration variable is included
				sum v_`i'_`zt' if `sv' ==1, mean 
				mat `lv'[`j',13]=r(mean)
				*SIS: Average `zt'-statistic of main variable on Sister Estimations
				*NIT: `zt'-statistic of main variable without iteration variables
				sum v_`i'_`zt'`altn' if `sv' ==1 , mean
				mat `lv'[`j',14]=r(mean)

				if "`unbalanced'" != "" {
					sum obs if `sv'!=., mean
					*Average number of observations where the iteration variable is included
					mat `lv'[`j',15]=r(mean)
					*Minimun number of observations where the iteration variable is included
					mat `lv'[`j',16]=r(min)
					*Maximun number of observations where the iteration variable is included
					mat `lv'[`j',17]=r(max)
					*Number of observations with no iteration variables
					mat `lv'[`j',18]=`obs_no_it'
				}
				loc ++j
			}
			keep `listav'
			d, replace clear
			count
			loc tt=r(N)
			forvalues j =1 / `tt' {
				loc name_`j' =varlab[`j']
			}
			drop _all
			svmat `lv'
			gen varname = ""
			loc j=1
			forvalues j =1 / `tt' {
				replace varname = strreverse(substr(strreverse("`name_`j''"), 8,.)) in `j'
			}
			order varname, first
			* drop Constant
			drop if substr(varname,1,8) == "Constant"

			rename `lv'1 TotEst
			loc dTotEst			"Total number of reg. where the iteration var. is included"
			rename `lv'2 SigToNonSig
			loc dSigToNonSig	"No. of reg. where iteration var. makes main var. non-significant"

			rename `lv'3 PosToNonSig
			loc dPosToNonSig		"No. of reg. where main var. coef. > 0 & sig. turns non-sig. w/ iter. var."
			rename `lv'4 NegToNonSig
			loc dNegToNonSig		"No. of reg. where main var. coef. < 0 & sig. turns non-sig. w/ iter. var."

			if "`sisters'" != "" {
				rename `lv'5 SisBaseNonSig  
				loc dSisBaseNonSig	"No. of sister baseline reg. w/ non-significant main var. coef."
			}
			if "`sisters'" == "" drop `lv'5 
			rename `lv'6 BothNonSig  
			if "`sisters'" != ""  loc dBothNonSig		"No. of reg. w/ non-sig. main var. coef. with & without (sister) iter. var."
			if "`sisters'" == ""  loc dBothNonSig		"No. of reg. w/ non-sig. main var. coef. with & without (baseline) iter. var."
			rename `lv'7 PosTImpact
			loc dPosTImpact		"No. of reg. where iter. var. increases main var. `zt'-stat."
			rename `lv'8 NegTImpact
			loc dNegTImpact		"No. of reg. where iter. var. decreases main var. `zt'-stat."
			loc rvt =round(`vt',0.001)
			rename `lv'9 SigPosTImpact
			loc dSigPosTImpact	"No. reg. w/ main var. `zt'-stat increases > 1.96 due to iter. var."
			rename `lv'10 SigNegTimpact
			loc dSigNegTimpact		"No. reg. w/ main var. `zt'-stat decreases > 1.96 due to iter. var."
			rename `lv'11 AvgBeta
			loc dAvgBeta			"Average coef. of main var. where iter. var. is included"
			if "`sisters'" != "" {
				rename `lv'12 AvgBeta`altn'
				loc dAvgBetaSIS "Average coef. of main var. in sister reg."
			}
			if "`sisters'" == "" {
				rename `lv'12 BaseBeta
				loc dBaseBeta "Main var. coef. in the Baseline regression."
			}
			rename `lv'13 Avg_`zt'
			loc dAvg_`zt'		"Average `zt'-stat. of main var. where iter. var. is included"
			if "`sisters'" != "" {
				rename `lv'14 Avg_`zt'_`altn'
				loc dAvg_`zt'_`altn' "Average `zt'-stat. of main var. in sister reg."
			}
			if "`sisters'" == "" {
				rename `lv'14 Base_`zt'
				loc dBase_`zt' "Average `zt'-stat. of main var. in the Baseline regression."
			}

			label var varname "Variable Name"
			
			loc list_unb ""
			if "`unbalanced'" != "" {
				rename `lv'15 AvgIterVarObs
				loc dAvgIterVarObs	"Average No. of observations where iter. var. is included"
				rename `lv'16 MinIterVarObs
				loc dMinIterVarObs	"Minimun No. of observations where iter. var. is included"
				rename `lv'17 MaxIterVarObs
				loc dMaxIterVarObs	"Maximun No. of observations where iter. var. is included"
				rename `lv'18 BaseObs
				loc dBaseObs "Number of observations in the baseline regression"
				loc list_unb	"AvgIterVarObs MinIterVarObs MaxIterVarObs BaseObs"
			}
			if "`sisters'" != "" loc list_var "TotEst SigToNonSig NegToNonSig PosToNonSig SisBaseNonSig BothNonSig PosTImpact NegTImpact SigPosTImpact SigNegTimpact AvgBeta AvgBeta`altn' Avg_`zt' Avg_`zt'_`altn' `list_unb'"
			if "`sisters'" == "" loc list_var "TotEst SigToNonSig NegToNonSig PosToNonSig BothNonSig PosTImpact NegTImpact SigPosTImpact SigNegTimpact AvgBeta BaseBeta Avg_`zt' Base_`zt'"
			return local list_var_des "`list_var'"
			foreach v in `list_var' {
				label var `v' "`d`v''"
				return local `v' "`d`v''"
			}

			gen aux = -SigToNonSig
			sort aux, stable
			drop aux
			loc a =ustrtoname("`var'")
			noi di as text "------------------------------------------------------------------------------------------"
			noi di as text " `var': "
			noi di as text " Matrix with detailed results showing how each individual iteration variable affects `var'"
			if "`noexcel'" == "" noi di as text " was stored as r(`a'_Table) and included as a new sheet the Excel report"
			if "`noexcel'" != "" noi di as text " was stored as r(`a'_Table)"
			noi di as text "------------------------------------------------------------------------------------------"
			mkmat `list_var', matrix(``i'') rownames(varname)
			if "`noexcel'" == "" {
				capture export excel using "`results'.xlsx", sheet("`var' List", modify) firstrow(varlabels) keepcellfmt
				if _rc != 0 {
					no di as text "Variable name `var' is too long, list of interaction covariates exported in csv format"
					export delimited using "`var'_List.csv", datafmt `replace'
				}
			}
			restore
			loc ++i
		}
	}
end

