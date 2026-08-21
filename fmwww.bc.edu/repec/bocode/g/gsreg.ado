*! version 3.0.0  02Jul2026
*===============================================================================================
* GSREG: Global Search Regressions                                                   
* Authors:																			 
* Pablo Glüzmann, CEDLAS-UNLP and CONICET - La Plata, Argentina - gluzmann@gmail.com
* Demian Panigo, Instituto Malvinas, UNLP and CONICET - La Plata, Argentina - panigo@gmail.com 
*-----------------------------------------------------------------------------------------------
* DNDA Exp. 5137544																				
*===============================================================================================
*DEFINE "gsreg" PROGRAM
program define gsreg, eclass
version 17.0
qui {
	syntax varlist(min=2 fv ts) [aw fw iw pw] [if] [in] , [NComb(numlist >=0 integer max=2) Fixvar(varlist fv ts) GRoupscandidates(string asis) Outsample(integer 0) CMDEst(string) CMDOptions(string) CMDStat(string) CMDIveq(string) AICbic HETtest hettest_o(string) ARChlm archlm_o(string) BGODfrey bgodfrey_o(string) DURbinalt durbinalt_o(string) DWatson SKtest sktest_o(string) SWilk swilk_o(string) SFrancia RESultsdta(string) COMpact TESTpass(numlist >0 <1 max=1 ) MIndex(string) MINDEXNOMissing  NIndex(string) best(numlist >0 integer max=1 ) NOCOunt DOuble REPlace SAMESample Part(numlist >0 integer min=2 max=2) BACKup(numlist >0 integer min=1 max=1) FIXINTeractions Lags(numlist >0 integer) DLags(numlist >0 integer) ILags(numlist >0 integer) SChange(varname) INTeractions SQuares CUBic]
	if "`resultsdta'"=="" loc resultsdta "gsreg"
	if "`cmdest'"=="" loc cmdest "regress"
	if "`nindex'"=="" & "`mindex'"=="" loc nindex "r_sqr_a"
	tempvar touse
	mark `touse' `if' `in' 
    capture tsset
	loc time=r(timevar)
	loc panel=r(panelvar)
	if "`time'"== "." loc time ""
	if "`panel'" == "." loc panel ""
	if (`outsample'>0 & `outsample'<. & "`time'"=="") {
		display as error "time variable not set"
		exit 111
	}

	if "`fixvar'"!="" {
			* Expansion of fixvar 
			fvunab expanded : `fixvar'
			loc fixvar "`expanded'"		
			loc aux 0
		foreach var1 in `fixvar'  {
			foreach var2 in `varlist' {
				if "`var1'"=="`var2'" loc aux 1
			}
		}
		if `aux' ==1 {
				display as error "Option fixvar contains at least one variable already included as main variable"
		exit 503
		}
	}

	if "`schange'"!="" | "`cubic'"!="" | "`squares'"!="" | "`interactions'"!="" | "`fixinteractions'"!="" {
		display as error "The lags, dlags, ilags, schange, interactions, squares, and cubic options are no longer available in gsreg version 3 and later. From v3.0.0, it is possible to explicitly use time variables and factor variables."
		exit 198
	}
	if "`mindex'"!="" & "`nindex'"!="" {
		display as error "mindex and nindex options are not allowed together"
		exit 198
	}
	if "`mindex'"!="" & "`best'"=="" {
		display as error "mindex not allowed without best option"
		exit 198
	}
	if "`best'"!="" & "`mindex'"=="" {
		display as error "best not allowed without mindex option"
		exit 198
	}

	if "`part'"!="" & "`backup'"!="" {
		display as error "part and backup options are not allowed together"
		exit 198
	}
	if "`part'"!="" {
		*********************************
		tokenize `part'	
		*********************************
		loc part_div `1'
		loc part_tot `2'
		if `part_div'>`part_tot' {
			display as error "part() invalid, elements out of order"
			exit 124
		}
	}
	loc path ""
	loc revresultsdta =reverse("`resultsdta'") 
	loc dta =substr("`resultsdta'",-4,.)
	loc dta =strmatch("`dta'",".dta")
	if `dta'==1 loc revresultsdta=substr("`revresultsdta'",5,.)
	loc resultsdta=reverse("`revresultsdta'")
	loc posit  =strpos("`revresultsdta'","\")
	loc posit2 =strpos("`revresultsdta'","/")
	loc position=max(`posit',`posit2')
	if `posit'>0 & `posit2'>0 loc position=min(`posit',`posit2')
	if `position'!=0 {
		loc revpath =substr("`revresultsdta'",`position',.)
		loc path =reverse("`revpath'")
	}
	if "`path'"=="" loc fname "`resultsdta'"
	if "`path'"!="" {
		loc posaux=`position'-1
		loc fname =substr("`resultsdta'",-`posaux',.)
	}
	loc length =length("`resultsdta'")
	loc aux 0
	capture loc aux=length(`part_tot')
	if `length'>245-10-2*`aux' & "`path'"=="" {
		display as error "the path of the working directory is too long, change the working directory using command cd or specify shorter path using option resultsdta"
		exit 603
	}
	if `length'>245-10-2*`aux' & "`path'"!="" {
		display as error "the path specified in option resultsdta too long, specify a shorter path using option resultsdta"
		exit 603
	}
	* Convert grouped iteration syntax separated by | into internal macros.
	* Each group behaves as one combinatorial unit, even if it contains several variables.
	if "`groupscandidates'" != "" {
		loc nwg: word count `groupscandidates'
		parse "`groupscandidates'",parse(|)
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
		* no necesito xq expando despues
		*fvexpand `var_groups_list'
		*loc var_groups_list_exp "`r(varlist)'"
	}

	preserve
	drop _all
	set obs 1
	tempname aux
	tempvar var1
	gen `var1' =1
	capture save "`resultsdta'`part_div'`part_tot'`aux'.dta", replace
	if _rc !=0 & "`path'"=="" {
		display as error "stata cannot save files in the working directory, change the working directory using command cd or specify another path using option resultsdta"
		exit 603
	}
	if _rc !=0 & "`path'"!="" {
		display as error "stata cannot save files the path specified in option resultsdta, change the working directory using command cd or specify another path using option resultsdta"
		exit 603
	}
	capture erase "`resultsdta'`part_div'`part_tot'`aux'.dta"
	drop _all
	if "`replace'"=="" {
		if "`compact'"!="" save "`resultsdta'_labels.dta", emptyok
		if "`part'" =="" save "`resultsdta'.dta", emptyok
	}
	restore
	local wt: word 2 of `exp'
	* varlist ya tiene la expansión teórica o sintáctica 
	tokenize `varlist'	
	loc depvar "`1'"
	macro shift 1
	loc indepvar "`*'"
	* extraigo todas las variables independientes resumidas
	* elimino categorias base indepvar
    fvexpand `indepvar'
	local laux "`r(varlist)'"
	local lista_comb1 = ustrregexra("`laux'", "[^ ]*b\.[^ ]*", "")
	* tamaño total
	if "`cmdiveq'"!=""  {
			_iv_parse `depvar' (`cmdiveq')
			loc instruments "`s(inst)'"
			loc endogenous "`s(endog)'"
	}
	if "`instruments'"!="" & "`endogenous'"!="" {
		foreach var1 of local endogenous {
			local lista_comb1: subinstr local lista_comb1 "`var1'" "", word
		}
		* elimino caterogias base de endogenous
		loc endogenous = ustrregexra("`endogenous'", "[^ ]*b\.[^ ]*", "")
		loc lista_comb1 "`lista_comb1' `endogenous'"
	}
	if "`groupscandidates'" != "" & "`lista_comb1'"!= "" {
		loc aux 0
		foreach var1 in `groups_list'  {
			foreach var2 in `lista_comb1' {
				if "`var1'" == "`var2'" loc aux 1
			}
		}
		if `aux'==1 {
			display as error "The groupscandidates option contains at least one variable already included in the candidates varlist"
			exit 503
		}
	}

	* `lista_comb1' hasta ahora tiene sintaxis expansión teórica o sintáctica es decir sin las posibilidades categoricas pero todo expandido (sin los nombres temporales de grupos)
	* agrego los grouplist como grupos para calcular las combinatorias
	* ListaTotComb: lista de convinatorias para tomar el total
	loc ListaTotComb "`lista_comb1' `groups_list'"
	* tindep numero de variables para combinatoria
	loc tindep: word count `ListaTotComb' 
	* lista teorica con todas las variable
	loc ListaTotVar "`fixvar' `indepvar' `endogenous' `var_groups_list' "
	*ListaTotVarExp: lista expandida total ListaTotVarExp incluyendo cada variable de los grupos
    fvexpand `ListaTotVar'
	local ListaTotVarExp "`r(varlist)' _cons"
	***
	* saco categorias base
	*local ListaTotVarExp = ustrregexra("`ListaTotVarExp'", "[^ ]*b\.[^ ]*", "")

	* Complete ncomb() when the user omits it.
	* Default behavior is to evaluate all subset sizes from 1 to the total number of
	* iteration units (single variables plus groups), plus the baseline model with none.
	* Complete the ncomb syntax
	if "`ncomb'" != "" {
		local none: word 1 of `ncomb'
		if `none' == 0 {
			if "`fixvar'"=="" {
				display as error "Combinatory 0 not allowed without fixvar"
				exit 198
			}
		}
	}
	if "`ncomb'" == "" {
		loc none = 1
		loc allcomb: word count `lista_comb1' `groups_list'
		loc ncomb "1 `allcomb'"
	}
	tokenize `ncomb'	
	loc kmin `1'
	if "`2'"!="" loc kmax `2'
	if "`2'"=="" loc kmax `1'
	if `kmin'>`kmax' {
		display as error "ncomb() invalid, elements out of order"
		exit 124
	}
	*ListaTotVar: lista expandida sintaxis expansión teórica o sintáctica incluyendo cada variable de los grupos
	if "`samesample'" != "" {
		tempvar aux
		gen `aux'=0 if `touse' ==1
		***********************************ver same
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
	if `none' ==0 loc total = `total'+1
	if `total'<=0 | `total' >=. {
		display as error "Too few independent variables specified for selected combinatorial"
		exit 198
	}
	noi di as text "----------------------------------------------------"
	noi di as text "Total Number of Estimations: " as result "`total'"
	noi di as text "----------------------------------------------------"
	if "`part'"!="" {
		if `part_tot'>`total' {
		noi di as text "The number of partitions is greater than the number of estimates"
		noi di as text "The number of partitions reset to " as result "`total'"
			loc part_tot `total'
			if `part_div'>`part_tot' loc part_div `part_tot' 
		}
		noi di as text "Part "as result "`part_div'" as text " of " as result "`part_tot'"
		noi di as text "----------------------------------------------------"
	}
	if "`backup'"!="" {
		if `backup'>`total' {
		noi di as text "The number of partitions is greater than the number of estimates"
		noi di as text "The number of partitions reset to " as result "`total'"
			loc backup `total'
		}
		loc part_tot `backup'
	}
	loc estcomoptions "cmde(`cmdest') cmdoptions(`cmdoptions') cmdstat(`cmdstat') resultsdta(`resultsdta') outsample(`outsample') `aicbic' `hettest' hettest_o(`hettest_o') `archlm' archlm_o(`archlm_o') `bgodfrey' bgodfrey_o(`bgodfrey_o') `durbinalt' durbinalt_o(`durbinalt_o') `dwatson' `sktest' sktest_o(`sktest_o') `swilk' swilk_o(`swilk_o') `sfrancia' `compact' testpass(`testpass') mindex(`mindex') best(`best') lastreg(`total') `double' `nocount' time(`time') panel(`panel') instruments(`instruments') endogenous(`endogenous') " 
	local hh1: word count `fixvar'
	local hh2: word count `ListaTotVarExp'
	loc hh 1
	if `hh2'>`kmax'+`hh1' {
		foreach var of local ListaTotVarExp {
			if `hh'<=(`kmax'+`hh1') loc listaaux "`listaaux' `var'"
			loc ++hh
		}
	}
	else loc listaaux "`ListaTotVarExp'"
	* Run a lightweight pilot estimation to approximate total runtime.
	* The pilot uses a truncated specification only to give the user an early warning.
	* Estimate the execution time
	timer clear 99
	timer on 99
	tempname aux
	_gsreg_estcomtry `depvar' `listaaux' [`weight'`exp'] if `touse' ==1 , matres2(`aux') `estcomoptions' ordervar(`ListaTotVarExp') nroreg(`Ntotreg') 
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
	if `timeprox'>=3 {
			noi di as text "----------------------------------------------------------------------------------"
			noi di as text "Warning: Estimation could take about " as result "`timeprox'" as text " minutes or more"
			noi di as text "----------------------------------------------------------------------------------"
	}

	* Build the full list of combinations requested by ncomb().
	* The helper subprogram writes temporary datasets containing index combinations.
	* Compute combinations
	noi di as text "Computing combinations..."
	forvalues combaux=1/`kmax' {
		tempfile __a_`combaux'
		loc __a_ "`__a_' `__a_`combaux''"
	}
	_gsreg_combinate `__a_', nsamp(`tindep') ncomb(`kmin',`kmax')
	noi di as text "Preparing regression list..."
	if `none' ==0 loc ++Ntotreg
	if `none' ==0 loc regress`Ntotreg' "" 
	tokenize `lista_comb1' `groups_list' 
	loc t1=`Ntotreg'
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
				if "`groupscandidates'" == "" {
					loc reg`i' " `reg`i'' `v1'`vaux'`v2'"
				}
				if "`groupscandidates'" != "" {
					loc vg = ""
					forvalues gi =1/`ng' {
						loc vv = "`v1'`vaux'`v2'"
						if "`vv'" == "`group`gi''" loc vg = "``group`gi'''"
					}
					if "`vg'" == "" loc reg`i' " `reg`i'' `v1'`vaux'`v2'"
					if "`vg'" != "" loc reg`i' " `reg`i'' `vg'"
				}
			}
			loc ++t1
		}
		restore
		*loc Ntotreg = 0
		forvalues i =1/`v' {
			loc ++Ntotreg
			loc regress`Ntotreg' "`reg`i''" 
			*completo sintaxis
			local regress`Ntotreg' = ustrregexra(`"`regress`Ntotreg''"', "(^|[ #])([0-9]+)\.", "$1$2bn.")
		}
	}

	if "`mindex'"=="" loc nindexaux "nindex(`nindex')"
	tempname matres1 matres2 mata_compact1
	
	forvalues i=1/`Ntotreg' {
		_gsreg_estcom_size `depvar' `fixvar' `regress`oreg'' `weight' if `touse' ==1 , constante(`h_cons') matres2(`matres2') `estcomoptions' `nindexaux' ordervar(`ListaTotVarExp') 
		loc constante= r(constante) 
		if _rc ==0 {
			loc aux = `matres2'[1,1]
			if `aux'>0 {
				loc aux=1
				continue, break
			}
		}
	}
	if "`aux'"!="1" {
		display as error "All estimatios have errors"
		exit _rc
	}
	* tamaño total matres1 
	local matac1 : word count `ListaTotVarExp' 
	local matac2 =colsof(`matres2')
	local namesc2: colfullnames(`matres2')
	mat `matres1' =J(1,`matac1'*2,.)
	if "`backup'"!="" loc tback =`backup'
	if "`backup'"=="" loc tback =1
	if "`part'"=="" & "`backup'"=="" {
		loc part_div=1
		loc part_tot=1
	}
	loc samemindex =0
	if "`mindex'"!="" {
		loc mindexcol ""
		loc aux: word count `mindex'
		if `aux'==1 loc mindexpond "1"
		if `aux'==1 loc mindexword word 1 of `mindex'
		if `aux'>1 {
			loc mindexpond ""
			loc mindexword ""
			loc h=1
			forvalues auxi = 1(2)`aux' {
				local aux1_`h': word `auxi' of `mindex'
				loc auxj=`auxi' +1
				local aux2_`h': word `auxj' of `mindex'
				loc mindexword "`mindexword' `aux2_`h''"
				loc ++h
			}
			macro drop auxi auxj
		}
		loc h=1
		foreach var2 of local mindexword {
			if "order" == "`var2'" {
				loc mindexcol "`mindexcol' 1"
				loc mindexpond "`mindexpond' `aux1_`h''"
			}
			loc ++h 
		}
		loc h=1
		foreach var2 of local mindexword {
			loc m1=1
			loc m2=2
			foreach var1 of local ListaTotVarExp {
				loc t_`m1' "v_`m1'_t"
				loc b_`m1' "v_`m1'_b"
				if "`b_`m1''" == "`var2'" {
					loc mindexcol "`mindexcol' `m2'"
					loc mindexpond "`mindexpond' `aux1_`h''"
				}		
				loc m3=`m2'+1
				if "`t_`m1''" == "`var2'" {
					loc mindexcol "`mindexcol' `m3'"
					loc mindexpond "`mindexpond' `aux1_`h''"
				}		
				loc ++m1
				loc m2=`m2'+2
			}		
			loc ++h
		}
		loc h=1
		foreach var2 of local mindexword {
			if "`compact'"!="" loc m1=2
			foreach var1 of local namesc2 {
				if "`var1'" == "`var2'" {
					loc mindexcol "`mindexcol' `m1'"
					loc mindexpond "`mindexpond' `aux1_`h''"
				}		
				loc ++m1
			}		
			loc ++h
		}
	}
	*ver********************************************************
	tempname mataNtotreg matapart_tot mataaux mataaux1 mataaux2 mataaux3 mataaux4 naux1 naux4	
	mata `mataNtotreg' =`Ntotreg'
	mata `matapart_tot' =`part_tot'
	mata `mataaux' =(`mataNtotreg'/`matapart_tot')
	mata `mataaux1' =floor(`mataaux')
	mata `mataaux2' = `mataaux' - `mataaux1'
	mata `mataaux3' = `mataaux2'*`matapart_tot'
	* pone a veces una linea de más que sería más seguro, dejo round
	*mata `mataaux4' = ceil(`mataaux3')
	mata `mataaux4' = round(`mataaux3')
	mata st_numscalar("`naux4'", `mataaux4')
	mata st_numscalar("`naux1'", `mataaux1')
	mata mata drop `mataNtotreg' `matapart_tot' `mataaux' `mataaux1' `mataaux2' `mataaux3' `mataaux4' 
	loc nnaux1=`naux1'
	loc nnaux4=`naux4'
	scalar drop `naux1' `naux4'
	macro drop mataNtotreg matapart_tot mataaux mataaux1 mataaux2 mataaux3 mataaux4 naux1 naux4	
	noi di as text "Doing regressions..."
	forvalues back=1/`tback' {
		if "`backup'"!="" loc part_div= `back'
		loc nopt =round(sqrt((`part_tot'/`part_div')*`Ntotreg'),1)
		if 	`nopt' <=100 loc nopt =100
		loc kk=1
		loc totS=0
		loc did=`Ntotreg' 
		if `part_div'<=`nnaux4' loc partes =`nnaux1'+1
		if `part_div'>`nnaux4' loc partes `nnaux1'
		********************************************************* armo en mata la matris de resultados
		tempname resultados matres 
		if "`best'"!="" & "`mindex'"!="" {
			if `partes'>`best'+1 loc partes =`best'+1
		}
		mata `resultados' =J(`partes',1+`matac1'*2+`matac2',.)
		if "`compact'"!="" {
				tempname resultados_c
				mata `resultados' =J(`partes',1+`matac2',.)
				mata `resultados_c' =J(`partes',1,"")
		}
		if "`best'"!="" & "`mindex'"!="" {
			tempname mataaux mataaux1 mataaux2 matamindex nnaux1 nnaux2 nnaux3 
			loc m1=1
			foreach mind of local mindexcol {
				tempname mcol`m1' mean`m1' sd`m1' 
				loc ++m1
			}
		}
		loc noestcom =0
		loc h=1
		forvalues i=1/`Ntotreg' {
			loc oreg =`part_div'+(`i'-1)*`part_tot'
			if `oreg'>`Ntotreg' continue, break
			if (`i'<=`partes' | `h'<`partes') loc h=`i'-`noestcom'
			noi _gsreg_estcom `depvar' `fixvar' `regress`oreg'' `weight' if `touse' ==1 , matres1(`matres1') mata_compact1(`mata_compact1') matres2(`matres2') `estcomoptions' ordervar(`ListaTotVarExp') nroreg(`oreg') 
			if r(noest) ==1 | r(notest) ==1 {
				loc ++noestcom
				continue
			}
			mat `matres' = `oreg',`matres1',`matres2',.
			if "`compact'"!="" mat `matres' = `oreg',`matres2',.
			mata `resultados'[`h',.]=st_matrix("`matres'")
		if "`compact'"!="" mata `resultados_c'[`h',.]=`mata_compact1'
			if (`h'>=`partes') & "`best'"!="" & "`mindex'"!="" {
				mata `mataaux1' =rows(`resultados')
				mata `mataaux2' =cols(`resultados')
				loc m1 = 1
				foreach mind of local mindexcol {
					mata `mcol`m1'' = `resultados'[.,`mind']
					mata `mataaux' =meanvariance(`mcol`m1'')
					mata `mean`m1'' = `mataaux'[1,1]*J(`mataaux1',1,1)
					mata `sd`m1'' =  `mataaux'[2,1]^(1/2)
					mata `mcol`m1'' = (`mcol`m1''-`mean`m1'')/`sd`m1''
					mata if (`sd`m1''==0) `mcol`m1'' = J(`mataaux1',1,0)
					`sd`m1'' 
					loc ++m1
				}	
				mata `matamindex' =J(`mataaux1',1,0)
				loc m1 = 1
				loc aux: word count `mindex'
				if `aux'==1 mata `matamindex' = `mcol`m1''
				if `aux'>1 {
					foreach pond of local mindexpond {
						mata `matamindex' =`matamindex'+`pond'*`mcol`m1''
						mata mata drop `mcol`m1'' `mean`m1'' `sd`m1'' 
						loc ++m1
					}
				}
				if "`mindexnomissing'"!="" mata _editmissing(`matamindex',mindouble())
				mata `resultados'[.,`mataaux2']=`matamindex'
				if "`compact'"!="" mata `nnaux2' =`resultados'[.,1]
				mata _sort(`resultados',`mataaux2')
				mata `mataaux' =`resultados'[1,`mataaux2']-`resultados'[2,`mataaux2'] 
				if "`compact'"!="" {
					mata `nnaux3'=`resultados'[1,1]
					mata _editvalue(`nnaux2',`nnaux3',0)
					mata `resultados_c'=select(`resultados_c',`nnaux2')\""
				mata mata drop `nnaux2' `nnaux3'
				}
				mata `resultados'[1,1]=`Ntotreg'+1
				mata `resultados'=sort(`resultados',1)
				mata st_numscalar("`nnaux1'", `mataaux')
				mata mata drop `mataaux' `mataaux1' `mataaux2' `matamindex' 
				loc aux1=`nnaux1'
				scalar drop `nnaux1'
				if `aux1'==0 loc samemindex= `samemindex'+1
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
		if "`compact'"=="" {
			foreach var of local ListaTotVarExp {
				loc h=`i'+1
				ren v`i' v_`j'_b 
				ren v`h' v_`j'_t 
				label var v_`j'_b "`var' coeff."
				label var v_`j'_t "`var' tstat."
				if "`var'"=="_cons" {
					label var v_`j'_b "Constant coeff."
					label var v_`j'_t "Constant tstat."
				}
				loc i=`i'+2
				loc ++j
			}
		}
		foreach name of local namesc2 {
			ren v`i' `name'
			loc ++i
		}
		label var obs "Observations"
		label var nvar "Number of regressors"
		label var rank "Rank (excluding omitted variables)"
		label var r_sqr_a "Adjusted R-squared"
		label var rmse_in "RMSE in sample"
		if `outsample'!=0 {
			label var rmse_out "RMSE out of sample"
		}
		if "`aicbic'"!="" {
			label var aic "Akaike information criterion"
			capture label var aicc "Akaike information criterion corrected"
			label var bic "Bayesian information criterion"
		}
		if "`hettest'"!=""	label var hettest "pvalue of Breusch-Pagan / Cook-Weisberg test for heteroskedasticity"
		if "`archlm'"!="" {
			foreach var of varlist archlm* {
				local aux1 ="`var'"
				loc aux2: subinstr local aux1 "archlm" ""
				label var archlm`aux2' "pvalue of lag `aux2', LM test for autoregressive conditional heteroskedasticity (ARCH)"
			}
		}
		if "`bgodfrey'"!="" {
			foreach var of varlist bgodfrey* {
				local aux1 ="`var'"
				loc aux2: subinstr local aux1 "bgodfrey" ""
				label var bgodfrey`aux2' "pvalue of lag `aux2', Breusch-Godfrey LM test for autocorrelation"
			}
		}
		if "`durbinalt'"!="" {
			foreach var of varlist durbinalt* {
				local aux1 ="`var'"
				loc aux2: subinstr local aux1 "durbinalt" ""
				label var durbinalt`aux2' "pvalue of lag `aux2', Durbin's alternative test for autocorrelation"
			}
		}
		if "`dwatson'"!=""	label var dwatson "Durbin-Watson d-statistic"
		if "`sktest'"!=""	label var sktest "Pvalue of joint skewness and kurtosis test for normality of residuals"
		if "`swilk'"!=""	label var swilk "Pvalue of joint Shapiro-Wilk W test for normality of residuals"
		if "`sfrancia'"!=""	label var sfrancia "Pvalue of joint Shapiro-Francia W' test for normality of residuals"
		if "`compact'" !="" {
			getmata (regressors) = `resultados_c'
			label var regressors "Order of regressors indicating witch variables are used in each model"
			tempfile foto
			save `foto', replace
			drop _all
			set obs `matac1'
			gen position=_n
			label var position "Position of each variable in regressors indicator variable"
			gen variable =""
			loc i=1
			foreach var of local ListaTotVarExp {
				replace variable ="`var'" in `i'
				loc ++i
			}
			replace variable ="Constant" if variable =="_cons"
			label var variable "Regressor variable used in each model"
			noi save "`resultsdta'_labels.dta", replace
			drop _all
			use `foto'
		}
		if "`part'" !="" | "`backup'" !="" {
			drop if order ==.
			compress
			sort order
			noi save "`resultsdta'_part_`part_div'_of_`part_tot'.dta", `replace'
			restore
			if "`part'" !="" exit
		}
	}
	if "`backup'" !="" {
		preserve
		drop _all
		forvalues back=1/`tback' {
			append using "`resultsdta'_part_`back'_of_`part_tot'.dta"
		}
	}
	count
	if r(N)==0 & "`testpass'"!="" {
		display as error "No estimations has passed the residual test specified"
		exit 
	}
	if r(N)==0  {
		display as error "No estimations has been stored"
		exit 
	}
	if "`mindex'"!="" {
		capture drop mindex
		loc aux: word count `mindex'
		if `aux' ==1 {
			sum `mindex'
			if "`double'" !="" gen double mindex =(`mindex'-r(mean))/r(sd)
			if "`double'" =="" gen mindex =(`mindex'-r(mean))/r(sd)
		}
		if `aux' >1 {
			if "`double'" !="" gen double mindex =0
			if "`double'" =="" gen mindex =0
			forvalues auxi = 1(2)`aux' {
				local aux1: word `auxi' of `mindex'
				loc auxj =`auxi' +1
				local aux2: word `auxj' of `mindex'
				sum `aux2'
				loc mean=r(mean)
				loc sd=r(sd)
				gen naux=(`aux2'-`mean')/`sd'
				replace mindex=mindex+`aux1'*naux if naux !=.
				drop naux
			}
		}
		macro drop drop auxi auxj
		if "`mindexnomissing'"!="" drop if mindex==.
		sort mindex, stable
		drop if _n>`best'+1
		if `samemindex'>0 noi di "Warning: when sorting models by mindex `samemindex' times the `best'th model and higher have the same value of mindex"
		if mindex[1] == mindex[2] noi di "Warning: when sorting models by mindex the `best'th model and higher have the same value of mindex"
		drop if _n == 1
		label var mindex "Lineal combination index of selected normalized estimation"
	}
	if "`nindex'"!="" {
		capture drop nindex
		loc aux: word count `nindex'
		if `aux' ==1 {
			sum `nindex'
			if "`double'" !="" gen double nindex =(`nindex'-r(mean))/r(sd)
			if "`double'" =="" gen nindex =(`nindex'-r(mean))/r(sd)
		}
		if `aux' >1 {
			if "`double'" !="" gen double nindex =0
			if "`double'" =="" gen nindex =0
			forvalues i = 1(2)`aux' {
				local aux1: word `i' of `nindex'
				loc j=`i' +1
				local aux2: word `j' of `nindex'
				sum `aux2'
				loc mean=r(mean)
				loc sd=r(sd)
				gen naux=(`aux2'-`mean')/`sd'
				replace nindex=nindex+`aux1'*naux if naux !=.
				drop naux
			}
		}
		label var nindex "Lineal combination index of selected normalized estimation"
	}
	if "`best'"!="" & "`nindex'"!="" {
		count
		loc aux=r(N)
		if `aux'>`best' {
			drop if nindex==.
			gsort -nindex +order
			if nindex[`best']==nindex[`best'+1] noi di "Warning: when sorting models by nindex the `best'th model and higher have the same value of nindex"
			drop if _n>`best'
		}
	}
	if "`compact'"=="" {
		order v_*,  seq
		loc i=1
		foreach var of varlist v_*_b {
			capture ren `var' v_`i'_b 
			loc ++i
		}
		loc i=1
		foreach var of varlist v_*_t {
			capture ren `var' v_`i'_t 
			loc ++i
		}
	}
	order order, first
	if "`double'" !="" {
		capture format r_sqr_a rmse_in	%20.0g
		capture format rmse_out %20.0g
		capture format mindex %20.0g
		capture format nindex %20.0g
		if "`cmdstat'"!="" {
			foreach i of local cmdstat {
				capture format `i' %20.0g
			}
			
		}
	}
	drop if order ==.
	compress
	sort order
	if "`part'"=="" noi save "`resultsdta'.dta", replace
	if "`backup'" !="" {
		forvalues back=1/`tback' {
			erase "`resultsdta'_part_`back'_of_`part_tot'.dta"
		}
	}
	if "`mindex'"!="" gsort -mindex +order
	if "`nindex'"!="" gsort -nindex +order
	if "`compact'"!="" {
		keep if _n==1
		sum order , mean
		loc bestreg =r(mean)
		loc aux =length(regressors)-1
		forvalues i=1/`aux' {
			gen aux= substr(regressors,`i',1)
			loc aux`i'=aux
			drop aux
		}
		
		use "`resultsdta'_labels.dta", clear
		loc listabestreg ""
		forvalues i=1/`aux' {
			loc vaux = word(variable[`i'],1)
			if `aux`i''==1 loc listabestreg "`listabestreg' `vaux'"
		}
		restore
	}
	if "`compact'"=="" {
		keep if _n==1
		sum order , mean
		loc bestreg =r(mean)
		drop *_t
		keep v_*
		d 
		loc aux =r(k)-1
		forvalues i=1/`aux' {
			sum v_`i'_b
			loc aux`i'=r(N)
		}
		describe, replace clear
		loc listabestreg ""
		forvalues i=1/`aux' {
			loc vaux =word(varlab[`i'],1)
			if `aux`i''==1 loc listabestreg "`listabestreg' `vaux'"
		}
		restore
	}
	noi di as text "----------------------------------------------------"
	noi di as text "Best estimation in terms of `nindex'`mindex' "
	noi di as text "Estimation number " as result "`bestreg'"
	noi di as text "----------------------------------------------------"
	tempvar insample
	gen `insample' =1 if `touse'==1
	if `outsample'!=0 {
		sort `panel' `time'
		if "`panel'"=="" replace `insample' =0 if _n>_N-`outsample' & `touse'==1
		if "`panel'"!="" by `panel': replace `insample' =0 if _n>_N-`outsample' & `touse'==1
	}
	if "`instruments'"!="" {
		foreach var1 of local listabestreg {
			foreach var2 of local endogenous {
				if "`var1'" =="`var2'" loc ivendogenous " `ivendogenous' `var2' "
			}
		}
		foreach var1 of local ivendogenous {
			local listabestreg: subinstr local listabestreg "`var1'" "", word
		}
		loc estim: word 2 of `cmdest'
		if ("`ivendogenous'"!="" | "`estim'"=="gmm") noi `cmdest' `depvar' `listabestreg' (`ivendogenous' =`instruments') `weight' if `insample'==1, `cmdoptions'
		else noi `cmdest' `depvar' `listabestreg' `weight' if `insample' ==1, `cmdoptions'
	}
	else noi `cmdest' `depvar' `listabestreg' `weight' if `insample' ==1, `cmdoptions'
}
end


*****************************************************************************************************
* auxiliary subprograms
*****************************************************************************************************
*! version 3.0.0  01jun2026
program define _gsreg_combinate
	version 17.0
	syntax anything ,NSamp(integer) NComb(numlist >0 integer max=2) [Reps]
	preserve
	tokenize `ncomb'
	loc kmin `1'
	if "`2'"!="" loc kmax `2'
	if "`2'"=="" loc kmax `1'
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
			if "`reps'" =="" drop if aux`j_1'>=aux`j'
			if "`reps'" !="" drop if aux`j_1'>aux`j'
			if `kmin'<=`j' {
				save "``j''", replace
				count
			}
		}
	}
	restore
end

*! version 3.0.0  01jun2026
program define _gsreg_estcom, rclass
	version 17.0
	qui	{
		* Purpose: run one estimation, recover coefficients and test statistics, and write
		* them into caller-provided matrices. This is the core engine used by samregc.
		loc setmoreprev=c(more)
		set more off
		syntax anything [aw fw iw pw] [if], matres1(string) mata_compact1(string) matres2(string) CMDEst(string) [CMDOptions(string) cmdstat(string)] resultsdta(string) ordervar(string) [nroreg(integer 0) Outsample(integer 0) compact aicbic hettest hettest_o(string) archlm  archlm_o(string) bgodfrey bgodfrey_o(string) durbinalt durbinalt_o(string) dwatson sktest sktest_o(string) swilk swilk_o(string) sfrancia testpass(numlist >0 <1 max=1 ) lastreg(integer 0) double NOCOunt time(string) panel(string) instruments(string) endogenous(string) ] [*]
		if "`nocount'"=="" noi di as text "Estimation number " as result "`nroreg'" as text " of " as result "`lastreg'"
		loc error =0
		tempvar touse insample
		tempname table
		mark `touse' `if' 
		gen `insample' =1 if `touse'==1
		if `outsample'!=0 {
			sort `panel' `time'
			if "`panel'"=="" replace `insample' =0 if _n>_N-`outsample' & `touse'==1
			if "`panel'"!="" by `panel': replace `insample' =0 if _n>_N-`outsample' & `touse'==1
		}
		if "`instruments'"!="" {
			foreach var1 of local anything {
				foreach var2 of local endogenous {
					if "`var1'" =="`var2'" loc ivendogenous " `ivendogenous' `var2' "
				}
			}
			loc anything2 "`anything'"
				local anything2: subinstr local anything2 "[]" "", word
			foreach var1 of local ivendogenous {
				local anything2: subinstr local anything2 "`var1'" "", word
			}
			loc estim: word 2 of `cmdest'
			if ("`ivendogenous'"!="" | "`estim'"=="gmm") {
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
	if `error' !=0 & "`nocount'"=="" noi di as text "Error " as input "r(" _rc ")" as text " in estimation number " as result "`nroreg'" 
	if `error' !=0 {
		return scalar noest =1
		sleep 300
		exit
	}

	if `error' == 0 {
		tempname betas sigmas t
		mat `betas' =e(b) 
		loc nvar =colsof(`betas')
		loc obs =e(N)
		loc rank =e(rank)
		if `rank' ==0 exit
		local rmse_in = e(rmse) 
		local r_sqr_a = e(r2_a) 
		capture loc nv2 = colsof(`table')
		if _rc ==0 & `nvar' == `nv2' {
			capture mat `t' =`table'["t",1...]
			if _rc !=0 {
				return local t = "z"
				mat `t' =`table'["z",1...]
			}
		}
		else {
			mat `sigmas' =e(V)
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
		*set trace on
		local names : colfullnames e(b)
		* corrijo listas para sacar bn
		local names : subinstr local names "bn." ".", all
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
		set trace off
		if `outsample'!=0 {
			loc df_r=e(df_r)
			tempvar resout resout_sq 
			if "`cmdest'"=="xtreg" predict `resout' if `insample'==0, e  
			else predict `resout' if `insample'==0, res
			gen double `resout_sq'= `resout'*`resout' 
			sum `resout_sq', mean
			tempname rmse_out
			mat `rmse_out' =( r(sum)/`df_r' )^.5	
			mat colnames `rmse_out' = rmse_out
		}
		if "`aicbic'"!="" {
			estat ic
			tempname aicbic
			mat `aicbic'=r(S)
			mat `aicbic'=`aicbic'[1,5],`aicbic'[1,6]
			mat colnames `aicbic' = aic bic 
		}
		if "`hettest'"!="" {
			estat hettest
			tempname hettest
			mat `hettest' =r(p)
			mat colnames `hettest' = hettest
		}
		if "`archlm'"!="" {
			loc lista ""
			estat archlm, `archlm_o'
			loc aux=r(lags)
			foreach i of local aux {
				loc lista "`lista' archlm`i'"
			}
			tempname archlm
			mat `archlm' =r(p)
			mat colnames `archlm' =`lista' 
		}
		if "`bgodfrey'"!="" {
			loc lista ""
			estat bgodfrey, `bgodfrey_o'
			loc aux=r(lags)
			foreach i of local aux {
				loc lista "`lista' bgodfrey`i'"
			}
			tempname bgodfrey
			mat `bgodfrey' =r(p)
			mat colnames `bgodfrey' =`lista' 
		}
		if "`durbinalt'"!="" {
			loc lista ""
			estat durbinalt, `durbinalt_o'
			loc aux=r(lags)
			foreach i of local aux {
				loc lista "`lista' durbinalt`i'"
			}
			tempname durbinalt
			mat `durbinalt' =r(p)
			mat colnames `durbinalt' =`lista' 
		}
		if "`dwatson'"!="" {
			estat dwatson
			tempname dwatson
			mat `dwatson' =r(dw)
			mat colnames `dwatson' = dwatson
		}
		if "`sktest'"!="" | "`swilk'"!="" | "`sfrancia'"!="" {
			tempvar resxt
			if "`cmdest'"=="xtreg" predict `resxt' if e(sample), e  
			else predict `resxt' if e(sample), res
			if "`sktest'"!="" {
				sktest `resxt' ,`sktest_o'
				tempname sktest1
				mat `sktest1' =r(P_chi2)
				mat colnames `sktest1' = sktest
			}
			if "`swilk'"!="" {
				swilk `resxt' ,`swilk_o'
				tempname swilk1
				mat `swilk1' =r(p)
				mat colnames `swilk1' = swilk
			}
			if "`sfrancia'"!="" {
				sfrancia `resxt' 
				tempname sfrancia1
				mat `sfrancia1' =r(p)
				mat colnames `sfrancia1' = sfrancia
			}
		}
		mat `matres2' = `obs',`nvar',`rank',`r_sqr_a',`rmse_in'
		mat colnames `matres2'= obs nvar rank r_sqr_a rmse_in
		if "`cmdstat'"!="" {
			tempname aux
			foreach i of local cmdstat {
				mat `aux'=e(`i')
				mat colnames `aux'= `i'
				mat `matres2'=`matres2',`aux'
			}
		}
		if `outsample'!=0	mat `matres2' =`matres2',`rmse_out'
		if "`aicbic'"!=""	mat `matres2' =`matres2',`aicbic'
		if "`testpass'" !="" {
			if "`hettest'"!="" {
				loc aux1 =colsof(`hettest')
				forvalues i =1/`aux1' {
					loc aux = `hettest'[1,`i']
					if `hettest'[1,`i']<`testpass' continue, break
				}
			}
			if "`archlm'"!="" {
				loc aux1 =colsof(`archlm')
				forvalues i =1/`aux1' {
					loc aux = `archlm'[1,`i']
					if `archlm'[1,`i']<`testpass' continue, break
				}
			}
			if "`bgodfrey'"!="" {
				loc aux1 =colsof(`bgodfrey')
				forvalues i =1/`aux1' {
					loc aux = `bgodfrey'[1,`i']
					if `bgodfrey'[1,`i']<`testpass' continue, break
				}
			}
			if "`durbinalt'"!="" {
				loc aux1 =colsof(`durbinalt')
				forvalues i =1/`aux1' {
					loc aux = `durbinalt'[1,`i']
					if `durbinalt'[1,`i']<`testpass' continue, break
				}
			}
			if `aux'<`testpass' return scalar notest =1
			if "`sktest'"!="" {
					loc aux= `sktest1'[1,1]
					if `aux'<`testpass' return scalar notest =1
			}
			if "`swilk'"!="" {
					loc aux= `swilk1'[1,1]
					if `aux'<`testpass' return scalar notest =1
			}
			if "`sfrancia'"!="" {
					loc aux= `sfrancia1'[1,1]
					if `aux'<`testpass' return scalar notest =1
			}
		}
		if "`hettest'"!=""	mat `matres2' =`matres2',`hettest'
		if "`archlm'"!=""	mat `matres2' =`matres2',`archlm'
		if "`bgodfrey'"!=""	mat `matres2' =`matres2',`bgodfrey'
		if "`durbinalt'"!=""	mat `matres2' =`matres2',`durbinalt'
		if "`dwatson'"!=""	mat `matres2' =`matres2',`dwatson'
		if "`sktest'"!=""	mat `matres2' =`matres2',`sktest1'
		if "`swilk'"!=""	mat `matres2' =`matres2',`swilk1'
		if "`sfrancia'"!=""	mat `matres2' =`matres2',`sfrancia1'
		if "`compact'"!="" {
			mata `mata_compact1' =J(1,1,"")
			loc i=1
			foreach var1 of local ordervar {
				if `matres1'[1,`i']!=. mata `mata_compact1'=`mata_compact1'+"1"
				if `matres1'[1,`i']==. mata `mata_compact1'=`mata_compact1'+"."
				loc i=`i'+2
			}
		}
		if "`setmoreprev'"=="on" set more on
	}
end


*! version 3.0.0  01jun2026
program define _gsreg_estcom_size, rclass
	version 17.0
	qui	{
		* Purpose: cheap pilot estimation used only to approximate runtime and verify that
		* the chosen estimator/options are compatible with the assembled syntax.
		loc setmoreprev=c(more)
		set more off
		syntax anything [aw fw iw pw] [if], matres2(string) CMDEst(string) [CMDOptions(string) cmdstat(string)] resultsdta(string) ordervar(string) [nroreg(integer 0) Outsample(integer 0) compact aicbic hettest hettest_o(string) archlm  archlm_o(string) bgodfrey bgodfrey_o(string) durbinalt durbinalt_o(string) dwatson sktest sktest_o(string) swilk swilk_o(string) sfrancia testpass(numlist >0 <1 max=1 ) nindex(string) mindex(string) best(numlist >0 integer max=1 ) lastreg(integer 0) double NOCOunt time(string) panel(string) instruments(string) endogenous(string) ] [*]
		loc error =0
		tempvar touse insample
		tempname table
		mark `touse' `if' 
		gen `insample' =1 if `touse'==1
		if `outsample'!=0 {
			sort `panel' `time'
			if "`panel'"=="" replace `insample' =0 if _n>_N-`outsample' & `touse'==1
			if "`panel'"!="" by `panel': replace `insample' =0 if _n>_N-`outsample' & `touse'==1
		}
		if "`instruments'"!="" {
			foreach var1 of local anything {
				foreach var2 of local endogenous {
					if "`var1'" =="`var2'" loc ivendogenous " `ivendogenous' `var2' "
				}
			}
			loc anything2 "`anything'"
			foreach var1 of local ivendogenous {
				local anything2: subinstr local anything2 "`var1'" "", word
			}
			loc estim: word 2 of `cmdest'
			if ("`ivendogenous'"!="" | "`estim'"=="gmm") {
				capture `cmdest' `anything2' (`ivendogenous' =`instruments') `weight' if `insample'==1, `cmdoptions'
				if _rc !=0 exit
				if _rc ==0 capture mat `table' =r(table)
			}
			else {
				capture cmdest' `anything2' `weight' if `insample'==1, `cmdoptions'
				if _rc !=0 exit
				if _rc ==0 capture mat `table' =r(table)
			}
		}
		else {
			capture `cmdest' `anything' `weight' if `insample'==1, `cmdoptions'
			if _rc !=0 exit 
			if _rc ==0 capture mat `table' =r(table)
		}
		* me fijo si tiene constante
		local names: colfullnames e(b)
		foreach cons of local names {
			if "`cons'" == "_cons" local constante "_cons"
			else local constante ""
		}
		* calculo tamaño matriz matres2
		tempname betas 
		mat `betas' =e(b) 
		loc nvar =colsof(`betas')
		loc obs =e(N)
		loc rank =e(rank)
		if `rank' ==0 exit
		local r_sqr_a = e(r2_a) 
		local rmse_in = e(rmse) 
		capture loc nv2 = colsof(`table')
		loc i 1
		loc h 1
		if `outsample'!=0 {
			loc df_r=e(df_r)
			tempvar resout resout_sq 
			if "`cmdest'"=="xtreg" predict `resout' if `insample'==0, e  
			else predict `resout' if `insample'==0, res
			gen double `resout_sq'= `resout'*`resout' 
			sum `resout_sq', mean
			tempname rmse_out
			mat `rmse_out' =( r(sum)/`dr_r' )^.5	
			mat colnames `rmse_out' = rmse_out
		}
		if "`aicbic'"!="" {
			estat ic
			tempname aicbic
			mat `aicbic'=r(S)
			mat `aicbic'=`aicbic'[1,5],`aicbic'[1,6]
			mat colnames `aicbic' = aic bic 
		}
		if "`hettest'"!="" {
			estat hettest
			tempname hettest
			mat `hettest' =r(p)
			mat colnames `hettest' = hettest
		}
		if "`archlm'"!="" {
			loc lista ""
			estat archlm, `archlm_o'
			loc aux=r(lags)
			foreach i of local aux {
				loc lista "`lista' archlm`i'"
			}
			tempname archlm
			mat `archlm' =r(p)
			mat colnames `archlm' =`lista' 
		}
		if "`bgodfrey'"!="" {
			loc lista ""
			estat bgodfrey, `bgodfrey_o'
			loc aux=r(lags)
			foreach i of local aux {
				loc lista "`lista' bgodfrey`i'"
			}
			tempname bgodfrey
			mat `bgodfrey' =r(p)
			mat colnames `bgodfrey' =`lista' 
		}
		if "`durbinalt'"!="" {
			loc lista ""
			estat durbinalt, `durbinalt_o'
			loc aux=r(lags)
			foreach i of local aux {
				loc lista "`lista' durbinalt`i'"
			}
			tempname durbinalt
			mat `durbinalt' =r(p)
			mat colnames `durbinalt' =`lista' 
		}
		if "`dwatson'"!="" {
			estat dwatson
			tempname dwatson
			mat `dwatson' =r(dw)
			mat colnames `dwatson' = dwatson
		}
		if "`sktest'"!="" | "`swilk'"!="" | "`sfrancia'"!="" {
			tempvar resxt
			if "`cmdest'"=="xtreg" predict `resxt' if e(sample), e  
			else predict `resxt' if e(sample), res
			if "`sktest'"!="" {
				sktest `resxt' ,`sktest_o'
				tempname sktest1
				mat `sktest1' =r(P_chi2)
				mat colnames `sktest1' = sktest
			}
			if "`swilk'"!="" {
				swilk `resxt' ,`swilk_o'
				tempname swilk1
				mat `swilk1' =r(p)
				mat colnames `swilk1' = swilk
			}
			if "`sfrancia'"!="" {
				sfrancia `resxt' 
				tempname sfrancia1
				mat `sfrancia1' =r(p)
				mat colnames `sfrancia1' = sfrancia
			}
		}
		if "`mindex'"!="" {
			tempname mindex1
			mat `mindex1' = 0
			mat colnames `mindex1' = mindex
		}
		if "`nindex'"!="" {
			tempname nindex1
			mat `nindex1' = 0
			mat colnames `nindex1' = nindex1
		}
		mat `matres2' = `obs',`nvar',`rank',`r_sqr_a',`rmse_in'
		mat colnames `matres2'= obs nvar rank r_sqr_a rmse_in
		if "`cmdstat'"!="" {
			tempname aux
			foreach i of local cmdstat {
				mat `aux'=e(`i')
				mat colnames `aux'= `i'
				mat `matres2'=`matres2',`aux'
			}
		}
		if `outsample'!=0	mat `matres2' =`matres2',`rmse_out'
		if "`aicbic'"!=""	mat `matres2' =`matres2',`aicbic'
		if "`hettest'"!=""	mat `matres2' =`matres2',`hettest'
		if "`archlm'"!=""	mat `matres2' =`matres2',`archlm'
		if "`bgodfrey'"!=""	mat `matres2' =`matres2',`bgodfrey'
		if "`durbinalt'"!=""	mat `matres2' =`matres2',`durbinalt'
		if "`dwatson'"!=""	mat `matres2' =`matres2',`dwatson'
		if "`sktest'"!=""	mat `matres2' =`matres2',`sktest1'
		if "`swilk'"!=""	mat `matres2' =`matres2',`swilk1'
		if "`sfrancia'"!=""	mat `matres2' =`matres2',`sfrancia1'
		if "`mindex'"!=""	mat `matres2' =`matres2',`mindex1'
		if "`nindex'"!=""	mat `matres2' =`matres2',`nindex1'
		return local constante "`constante'"
		if "`setmoreprev'"=="on" set more on
	}
	if `error' !=0 {
		if "`setmoreprev'" == "on" set more on
		noi di as text "Error " as input "r(" `error' ")" as text " in estimation number " as result "`nroreg'" 
		return scalar noest =1
		if `error'==1 sleep 300
		exit
	}
end


*! version 3.0.0  01jun2026
program define _gsreg_estcomtry, rclass
	version 17.0
	qui	{
		loc setmoreprev=c(more)
		set more off
		syntax anything [aw fw iw pw] [if], matres2(string) CMDEst(string) [CMDOptions(string) cmdstat(string)] resultsdta(string) ordervar(string) [nroreg(integer 0) Outsample(integer 0) compact aicbic hettest hettest_o(string) archlm  archlm_o(string) bgodfrey bgodfrey_o(string) durbinalt durbinalt_o(string) dwatson sktest sktest_o(string) swilk swilk_o(string) sfrancia testpass(numlist >0 <1 max=1 ) lastreg(integer 0) double NOCOunt time(string) panel(string) instruments(string) endogenous(string) ] [*]
		if "`nocount'"=="" noi di as text "Estimation number " as result "`nroreg'" as text " of " as result "`lastreg'"
		loc error =0
		tempvar touse insample
		tempname table
		mark `touse' `if' 
		gen `insample' =1 if `touse'==1
		if `outsample'!=0 {
			sort `panel' `time'
			if "`panel'"=="" replace `insample' =0 if _n>_N-`outsample' & `touse'==1
			if "`panel'"!="" by `panel': replace `insample' =0 if _n>_N-`outsample' & `touse'==1
		}
		if "`instruments'"!="" {
			foreach var1 of local anything {
				foreach var2 of local endogenous {
					if "`var1'" =="`var2'" loc ivendogenous " `ivendogenous' `var2' "
				}
			}
			loc anything2 "`anything'"
				local anything2: subinstr local anything2 "[]" "", word
			foreach var1 of local ivendogenous {
				local anything2: subinstr local anything2 "`var1'" "", word
			}
			loc estim: word 2 of `cmdest'
			if ("`ivendogenous'"!="" | "`estim'"=="gmm") {
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
	if `error' !=0 & "`nocount'"=="" noi di as text "Error " as input "r(" _rc ")" as text " in estimation number " as result "`nroreg'" 
	if `error' !=0 {
				return scalar noest =1
		sleep 300
				exit
			}

	if `error' == 0 {
		tempname betas sigmas t
		mat `betas' =e(b) 
		loc nvar =colsof(`betas')
		loc obs =e(N)
		loc rank =e(rank)
		if `rank' ==0 exit
		local rmse_in = e(rmse) 
		local r_sqr_a = e(r2_a) 
		capture loc nv2 = colsof(`table')
		if _rc ==0 & `nvar' == `nv2' {
			capture mat `t' =`table'["t",1...]
			if _rc !=0 {
				return local t = "z"
				mat `t' =`table'["z",1...]
			}
		}
		else {
			mat `sigmas' =e(V)
			capture mat `t'=(`betas'*inv(cholesky(diag(vecdiag(`sigmas')))))
			if _rc !=0 {
				mat `t' = `betas'
				forvalues i=1/`nvar'{
					mat `t'[1,`i'] = `betas'[1,`i'] / `sigmas'[`i',`i']^.5
				}
			}
		}
		*mat `matres1'=`matres1'*.
		loc i=1
		loc h=1
		local names : colfullnames e(b)
		* corrijo listas para sacar bn
		local names : subinstr local names "bn." ".", all
		foreach var1 of local ordervar {
			foreach var2 of local names {
					if "`var1'" == "`var2'" | "o.`var1'" == "`var2'" | "`dependiente':o.`var1'" == "`var2'" | "`dependiente':`var1'" == "`var2'" {
					*mat `matres1'[1,`i']=`betas'[1,`h']
					*mat `matres1'[1,`i'+1]=`t'[1,`h']
					loc ++h	
				} 
			}
			loc i=`i'+2
		}
		if `outsample'!=0 {
			loc df_r=e(df_r)
			tempvar resout resout_sq 
			if "`cmdest'"=="xtreg" predict `resout' if `insample'==0, e  
			else predict `resout' if `insample'==0, res
			gen double `resout_sq'= `resout'*`resout' 
			sum `resout_sq', mean
			tempname rmse_out
			mat `rmse_out' =( r(sum)/`df_r' )^.5	
			mat colnames `rmse_out' = rmse_out
		}
		if "`aicbic'"!="" {
			estat ic
			tempname aicbic
			mat `aicbic'=r(S)
			mat `aicbic'=`aicbic'[1,5],`aicbic'[1,6]
			mat colnames `aicbic' = aic bic 
		}
		if "`hettest'"!="" {
			estat hettest
			tempname hettest
			mat `hettest' =r(p)
			mat colnames `hettest' = hettest
		}
		if "`archlm'"!="" {
			loc lista ""
			estat archlm, `archlm_o'
			loc aux=r(lags)
			foreach i of local aux {
				loc lista "`lista' archlm`i'"
			}
			tempname archlm
			mat `archlm' =r(p)
			mat colnames `archlm' =`lista' 
		}
		if "`bgodfrey'"!="" {
			loc lista ""
			estat bgodfrey, `bgodfrey_o'
			loc aux=r(lags)
			foreach i of local aux {
				loc lista "`lista' bgodfrey`i'"
			}
			tempname bgodfrey
			mat `bgodfrey' =r(p)
			mat colnames `bgodfrey' =`lista' 
		}
		if "`durbinalt'"!="" {
			loc lista ""
			estat durbinalt, `durbinalt_o'
			loc aux=r(lags)
			foreach i of local aux {
				loc lista "`lista' durbinalt`i'"
			}
			tempname durbinalt
			mat `durbinalt' =r(p)
			mat colnames `durbinalt' =`lista' 
		}
		if "`dwatson'"!="" {
			estat dwatson
			tempname dwatson
			mat `dwatson' =r(dw)
			mat colnames `dwatson' = dwatson
		}
		if "`sktest'"!="" | "`swilk'"!="" | "`sfrancia'"!="" {
			tempvar resxt
			if "`cmdest'"=="xtreg" predict `resxt' if e(sample), e  
			else predict `resxt' if e(sample), res
			if "`sktest'"!="" {
				sktest `resxt' ,`sktest_o'
				tempname sktest1
				mat `sktest1' =r(P_chi2)
				mat colnames `sktest1' = sktest
			}
			if "`swilk'"!="" {
				swilk `resxt' ,`swilk_o'
				tempname swilk1
				mat `swilk1' =r(p)
				mat colnames `swilk1' = swilk
			}
			if "`sfrancia'"!="" {
				sfrancia `resxt' 
				tempname sfrancia1
				mat `sfrancia1' =r(p)
				mat colnames `sfrancia1' = sfrancia
			}
		}
		mat `matres2' = `obs',`nvar',`rank',`r_sqr_a',`rmse_in'
		mat colnames `matres2'= obs nvar rank r_sqr_a rmse_in
		if "`cmdstat'"!="" {
			tempname aux
			foreach i of local cmdstat {
				mat `aux'=e(`i')
				mat colnames `aux'= `i'
				mat `matres2'=`matres2',`aux'
			}
		}
		if `outsample'!=0	mat `matres2' =`matres2',`rmse_out'
		if "`aicbic'"!=""	mat `matres2' =`matres2',`aicbic'
		if "`testpass'" !="" {
			if "`hettest'"!="" {
				loc aux1 =colsof(`hettest')
				forvalues i =1/`aux1' {
					loc aux = `hettest'[1,`i']
					if `hettest'[1,`i']<`testpass' continue, break
				}
			}
			if "`archlm'"!="" {
				loc aux1 =colsof(`archlm')
				forvalues i =1/`aux1' {
					loc aux = `archlm'[1,`i']
					if `archlm'[1,`i']<`testpass' continue, break
				}
			}
			if "`bgodfrey'"!="" {
				loc aux1 =colsof(`bgodfrey')
				forvalues i =1/`aux1' {
					loc aux = `bgodfrey'[1,`i']
					if `bgodfrey'[1,`i']<`testpass' continue, break
				}
			}
			if "`durbinalt'"!="" {
				loc aux1 =colsof(`durbinalt')
				forvalues i =1/`aux1' {
					loc aux = `durbinalt'[1,`i']
					if `durbinalt'[1,`i']<`testpass' continue, break
				}
			}
			if `aux'<`testpass' return scalar notest =1
			if "`sktest'"!="" {
					loc aux= `sktest1'[1,1]
					if `aux'<`testpass' return scalar notest =1
			}
			if "`swilk'"!="" {
					loc aux= `swilk1'[1,1]
					if `aux'<`testpass' return scalar notest =1
			}
			if "`sfrancia'"!="" {
					loc aux= `sfrancia1'[1,1]
					if `aux'<`testpass' return scalar notest =1
			}
		}
		if "`hettest'"!=""	mat `matres2' =`matres2',`hettest'
		if "`archlm'"!=""	mat `matres2' =`matres2',`archlm'
		if "`bgodfrey'"!=""	mat `matres2' =`matres2',`bgodfrey'
		if "`durbinalt'"!=""	mat `matres2' =`matres2',`durbinalt'
		if "`dwatson'"!=""	mat `matres2' =`matres2',`dwatson'
		if "`sktest'"!=""	mat `matres2' =`matres2',`sktest1'
		if "`swilk'"!=""	mat `matres2' =`matres2',`swilk1'
		if "`sfrancia'"!=""	mat `matres2' =`matres2',`sfrancia1'
		if "`compact'"!="" {
			mata `mata_compact1' =J(1,1,"")
			loc i=1
			foreach var1 of local ordervar {
				if `matres1'[1,`i']!=. mata `mata_compact1'=`mata_compact1'+"1"
				if `matres1'[1,`i']==. mata `mata_compact1'=`mata_compact1'+"."
				loc i=`i'+2
			}
		}
		if "`setmoreprev'"=="on" set more on
	}
end


