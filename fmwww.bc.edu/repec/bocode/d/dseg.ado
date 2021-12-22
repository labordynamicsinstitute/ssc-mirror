*! version 3 Oct2020
*! author Ricardo Mora, UC3M
program dseg, rclass byable(recall)
syntax anything  [if] [in] [fweight],		///
			[GENerate(name)		///
			 Within(string asis)	///
                         By(varlist)		///
			 Format(string)		///
			 SAVING(string asis)	///
			 CLEAR			///
			 NOLIST			///
			 BOOTstraps(numlist integer max=1) /// // # of bootstrap samples
			 Random(numlist integer max=1)	/// // # of simulated samples
			 RSEED(numlist max=1)	/// // seed for random number generator
			 MISSING		///
			 NORMALIZED		/// // to normalized mutual information
			 FAST]
	version 14
	quietly {
	tempvar ones rep level n_random u
	tempfile dsegfile rassfile
	tempname random_name
	// counting sample
	marksample alluse, noby strok
	count if `alluse'
        local totN = r(N)
	// parsing index and group and units varlists
	gettoken index varlist: anything
	gettoken group_list varlist: varlist, match(p)
	gettoken given varlist: varlist, match(p)
	gettoken unit_list varlist: varlist, match(p)
	// parsing saving options
	gettoken saving saving_options: saving, parse(",")
	gettoken saving_options saving_options: saving_options, parse(",")
	// parsing within options
	gettoken within components: within, parse(",")
	gettoken components components: components, parse(",")
	local components =  strltrim("`components'")
	// warning messages
	if "`nolist'"!="" & "`clear'"=="" & "`saving'"=="" {
	    noi di as txt "Warning: you have chosen option <nolist> without options <clear> and <saving()>;" _newline ///
				_col(10) "hence, results are computed but neither displayed nor saved;" _newline ///
        			_col(10) "consider using options <clear> and/or <saving()>;"
	}
	if "`nolist'"!="" & "`clear'"=="" & "`saving'"=="" {
	    noi di as txt "Warning: you have chosen option <missing> with weighted data;" _newline ///
				_col(10) "observations with zero weights are not used;"
	}
	// error messages
	if "`index'"!="mutual" & "`index'"!="atkinson" & "`index'"!="theil" & "`index'"!="diversity"{
        	noi di as err "`index' index is not supported"
		error 197
   		}
	if "`given'"!="given" | "`varlist'"!="" {
        	noi di as err "groups and/or units varlists not identified"
		error 197
   		}
	if "`group_list'"==""  | "`unit_list'"=="" {
        	noi di as err "<group_varlist> and <units_varlist> are required"
		error 197
		}
	if "`fast'"!="" {
		foreach  c in ftools {
			capture : which `c'
			if (_rc) {
			    noi di as err "you need package {it:ftools} to use the <fast> option;" _newline ///
        			"you can install it by typing <ssc install ftools>;" _newline ///
				"you will also need to install the MOREMATA module if you do not have it;" _newline ///
        			"you can install it by typing <ssc install moremata>;" 
			    error 199
			}
		}
		foreach v of varlist `group_list' `unit_list' `within' `by' {
			capture confirm numeric variable `v'
			if (_rc) {
			    noi di as err "with option <fast> all variables must be numeric"
			    error 999
			}
		}
	}
	if "`components'"!="" & "`within'"=="" {
        	noi di as err "option <within()> is required if option <components> is used"
		error 197
   		}
	if "`components'"!="" & "`components'"!="components"  {
        	noi di as err "<within()> option <`components'> not allowed"
		error 197
   		}
	// generate can only be used when clear and/or saving are used
	if "`generate'"!="" {
		if "`clear'"=="" & "`saving'"=="" {
	        	noi di as err "option <generate()> only allowed with <clear> and/or <saving()>"
			error 197
		}
	}
	// generate: no debe generar un conflicto de nombres en el nuevo fichero de datos
	if "`generate'"!= "" { 	
		  if "`by'"!="" {
			  foreach v of varlist `by' {
				if "`v'"=="`generate'" {
				  noi di as error "conflict variable name;" _newline ///
					"choose another name in option <generate()>"
				  error 110
				}
			   }
		  }
		  if "`components'"!="" {
			  foreach v of varlist `within' {
				if "`v'"=="`generate'" {
				  noi di as error "conflict variable name;" _newline ///
					"choose another name in option <generate()>"
				  error 110
				}
			   }
		  }
	}
	if "`generate'"=="" {
		if "`index'"== "mutual" local generate = "M"
		else if "`index'"== "atkinson" local generate = "A"
		else if "`index'"== "theil" local generate = "H"
		else if "`index'"== "diversity" local generate = "R"
	}
	// no variable in group_list can also be in unit_list, within, or by variable
	foreach w in `group_list' {
		foreach v in `unit_list' `by' {
			if "`v'"=="`w'" {
	        	noi di as err "no variable in <groups_varlist> can be in <units_varlist>, <w_varlist>, or <by_varlist>"
			error 197
			}
		}
	}
	// units_lists and within variables cannot simultaneously be by variables
	foreach v_by in `by' {
		foreach v in `unit_list' `within' {
			if "`v'"=="`v_by'" {
		        	noi di as err "<units_varlist> and <w_varlist> cannot share variables with <by_varlist>"
				error 197
			}
		}
	}
	// bootstraps and random must be used with clear and/or saving
	if ("`bootstraps'"!="" | "`random'"!="") & "`clear'"=="" & "`saving'"=="" {
        	if ("`bootstraps'"!="") noi di as err "option <bootstraps()> must be used with options <clear> and/or <saving()>"
        	if ("`random'"!="") noi di as err "option <random()> must be used with options <clear> and/or <saving()>"
		error 197
	}
	// bootstraps and random cannot be used with weights
	if ("`bootstraps'"!="" | "`random'"!="") & "`weight'"!="" {
        	noi di as err "option <bootstraps()> cannot be used with weighted data"
		error 197
	}
	// rseed can only be used with bootstraps or random
	if "`bootstraps'"=="" & "`random'"=="" & "`rseed'"!="" {
        	noi di as err "option <rseed()> can only be used with option <bootstraps()>"
		error 197
	}
	// normalized option only for mutual
	if "`index'"!="mutual" & "`normalized'"=="normalized" {
        	noi di as err "option <normalized> can only be used with index <mutual>"
		error 197
	}

	// defaults
	// if within, default is decomposition, if components, then decomposition is null string
	if "`within'"!="" {
		if "`components'"=="" local decomposition="decomposition"
		else local decomposition=""
	}
	if "`format'"=="" local format="%9.4f"
	if "`weight'"=="" {
		local weight="fweight"	
		local exp="= `ones'"
		gen `ones'=1
		}
	if "`fast'"!="" local f="f"

	// heading message
	noi dis _newline _col(4) in g "Segregation Index: " _continue
	if "`index'"=="mutual" & "`normalized'"=="" noi dis in y "Mutual Information" 
	else if "`index'"=="mutual" noi dis in y "Mutual Information (normalized)"
	else if "`index'"=="atkinson" noi dis in y "Symmetric Atkinson"
	else if "`index'"=="theil" noi dis in y "Theil's H"
	else if "`index'"=="diversity" noi dis in y "Relative Diversity"
	noi dis _col(4) in g "Differences in " in y "`group_list' " in g "given" in y " `unit_list'" 
	if "`within'" != "" noi dis _col(4) in g "Between/Within " in y "`within'"
	if "`by'" != "" noi dis _col(4) in g "By " in y "`by'"
	noi dis ""

	// index computation
	if "`bootstraps'"=="" & "`random'"=="" {
		noi _decseg `index' `group_list' `if' `in' [`weight'`exp'], within(`within') by(`by') format(`format') ///
			generate(`generate') saving(`"`saving'"') savopt(`saving_options') `clear' `fast' `nolist'   ///
			unit(`unit_list') `decomposition' `missing' `normalized'
	}
	// bootstrapping
	else if "`bootstraps'"!="" {
		local i=0
		while `i'<=`bootstraps' {
		   preserve
		   if `i'!=0 {
			noi _show_iteration, i(`i') bootstraps(`bootstraps')
		   	bsample
		   }
		   _decseg `index' `group_list' `if' `in' [`weight'`exp'], within(`within') by(`by') format(`format') ///
			generate(`generate') clear `fast' nolist unit(`unit_list') `decomposition' `missing' `normalized'
		   gen `rep'=`i'
		   if "`i'"!="0" append using `dsegfile'
		   save `dsegfile', replace
		   local i=`i'+1
		   restore
		}
		if "`clear'"=="" preserve
			use `dsegfile', replace
			rename `rep' bsn
			label variable bsn "Bootstrap sample number"
			order bsn
			if "`components'"=="" sort bsn `by' 
			else sort bsn `by' `within'
			if "`saving'"!="" {
				save "`saving'", `saving_options'
				noi dis _newline as txt "File " in y "`saving'" as txt " saved"
		}
		if "`clear'"=="" restore
		if "`clear'"!="" {
			noi dis ""
			noi describe, fullnames
		}
	}
	// randomization test & Carrington-Troske modification
	else {
		// creating the random assignment file for group_list
		preserve
			keep `group_list'
			gen `n_random'=_n
			sort `n_random'
			save `rassfile', replace
		restore
		local i=0
		while `i'<=`random' {
		   preserve
		   if `i'!=0 {
			noi _show_iteration, i(`i') random(`random')
			gen `u'=runiform()
			sort `u'
			drop `u' `group_list'
			gen `n_random'=_n
			sort `n_random'
			merge 1:1 `n_random' using `rassfile', nogenerate sorted noreport
		   }
		   _decseg `index' `group_list' `if' `in' [`weight'`exp'], within(`within') by(`by') format(`format') ///
			generate(`generate') clear `fast' nolist unit(`unit_list') `decomposition' `missing' `normalized'
		   gen `rep'=`i'
		   if "`i'"!="0" append using `dsegfile'
		   save `dsegfile', replace
		   local i=`i'+1
		   restore
		}
		if "`clear'"=="" preserve
			use `dsegfile', replace
			rename `rep' ssn
			label variable ssn "Simulation sample number"
			order ssn
			if "`components'"=="" sort ssn `by' 
			else sort ssn `by' `within'
			if "`saving'"!="" {
				save "`saving'", `saving_options'
				noi dis _newline as txt "File " in y "`saving'" as txt " saved"
		}
		if "`clear'"=="" restore
		if "`clear'"!="" {
			noi dis ""
			noi describe, fullnames
		}
	}
	return clear
	return scalar N = `totN'
	return local index "`index'"
	return local cmd "dseg"
}		// endof quietly
end

program define _decseg
        syntax  anything [if] [in] [fweight /] ,		///
					[GENerate(name)		///
					 UNIT(varlist) 	///
					 Within(varlist) 	///
                                         By(varlist)		///
					 Format(string)		///
					 SAVING(string) 	///
					 SAVOPT(string) 	///
					 CLEAR			///
					 FAST			///
					 NOLIST			///
					 MISSING		///
					 NORMALIZED		///
					 DECOMPOSITION]
	quietly {
	tempname njg ng         
	tempvar level group frequency tempv numG index_t index_w index_b comp_i comp_w
	marksample touse, strok novarlist
	gettoken index varlist: anything
	if "`by'"=="" {
		gen `level'=1
		local by="`level'"
		local noby="noby"
		}
	if "`fast'"!="" local f = "f"
	if "`clear'"=="" preserve
	keep if `touse'
	if "`missing'"=="" {
		foreach v of varlist `varlist' `unit' `within' `by' {
			capture confirm numeric variable `v'
			if (_rc) drop if `v'=="" | `v'=="."
			else drop if `v'>=.
		}
	}
	if wordcount("`varlist'")>1 `f'egen `group'=group(`varlist')		
	else {
		capture confirm numeric variable `varlist'	// 
		if _rc==7 `f'egen `group'=group(`varlist')
		else gen `group'=`varlist'
	}

	if "`index'"!="atkinson" {
		local units `unit' `within'
		local groups `group'
		if "`within'"!="" {		// with within, making sure there are not repeated names in list units
		noi gettoken units: units
		foreach v in `unit' `within' {
			local flag="0"
			foreach w in `units' {
				if "`flag'"=="0" if "`v'"=="`w'" local flag="1"
			}
			if "`flag'"=="0" local units `units' `v'
		}
		}
	}
	else {
		local units `unit' 
		local groups `group' `within'
		if "`within'"!="" {		// with within, making sure there are not repeated names in list groups
		noi gettoken groups: groups
		foreach v in `group' `within' {
			local flag="0"
			foreach w in `groups' {
				if "`flag'"=="0" if "`v'"=="`w'" local flag="1"
			}
			if "`flag'"=="0" local groups `groups' `v'
		}
		}
	}
	if "`weight'"=="" gen `frequency'=1
	else if "`weight'"=="fweight" gen `frequency'=`exp'
	capture `f'collapse (sum) `frequency', by(`groups' `units' `by') `fast'
		if (_rc) {
		    noi di as err "<fcollapse> is not running as expected" _n "try without the <fast> option"
		    exit 999
		}
	// preparando la normalizacion del mutual si es necesario
	if "`index'"=="mutual" & "`normalized'"=="normalized" {
		inspect `groups'
		local G=r(N_unique)
		inspect `units'
		local N=r(N_unique)
		if `G'<`N' local base=`G'
		else if `N'<`G' local base=`N'
		else if `N'!=. local base=`N'
		else {
	       		preserve
		       		`f'collapse (min) `by', by(`groups') `fast'
		       		local G=_N
		       	restore	
	       		preserve
		       		`f'collapse (min) `by', by(`units') `fast'
		       		local N=_N
		       	restore	
			if `G'<`N' local base=`G'
			else if `N'<`G' local base=`N'
			else if `N'!=. local base=`N'
	       }
	}
	// computando índices
	_decseg_`index' `frequency', group(`groups') unit(`units') by(`by') generate(`index_t') `fast'
	if "`within'"!="" {
	  _decseg_`index' `frequency', group(`groups') unit(`units') by(`within' `by') generate(`comp_i') `fast'
	  if "`index'"!="atkinson" _decseg_`index'_p `frequency',  group(`group') unit(`within') by(`by') generate(`comp_w') `fast'
	  else _decseg_`index'_p `frequency',  group(`within') unit(`units') by(`by') generate(`comp_w') `fast'
          gen double `index_w'=`comp_w'*`comp_i'
          `f'collapse (mean) `index_t' `tempv'=`index_w' `comp_i' `comp_w', by(`within' `by') `fast'
          egen_sum `index_w', sum(`tempv') by(`by') `fast'
          gen double `index_b'=`index_t'-`index_w'
	}
	else {
		foreach v in `index_w' `index_b' `comp_i' `comp_w' {
			gen `v'=.
		}
	}
	// normalizando el mutual si es necesario
	if "`index'"=="mutual" & "`normalized'"=="normalized" {
		foreach v in `index_t' `index_w' `index_b' `comp_w' {
			replace `v'=`v'/log(`base')
		}
	}
	// preparando variables y poniendo labels
	_decseg_data `index', group("`varlist'") unit("`unit'") gen(`generate') indext(`index_t') 		///
				indexw(`index_w') indexb(`index_b') compi(`comp_i') compw(`comp_w') 		///
				within(`within') by(`by') `fast' `decomposition' `noby' format(`format') `normalized'
	// saving
	if "`saving'"!="" {
		save "`saving'", `savopt'
		noi dis _col(4) as txt "File `saving' saved"
	}
	// display
	if "`clear'"!="" & "`nolist'"=="nolist" noi describe, fullnames
	if "`nolist'"=="" {
          if "`by'"=="`level'" & "`within'"=="" noi l , noobs clean noheader
	  else noi l , noobs clean
	}
	// si no se sustituyen los datos
	if "`clear'"=="" restore
	}	// endof quietly
end

program define _decseg_mutual
       syntax varlist(max=1), GROUP(varlist) UNIT(varlist) GENerate(name) BY(varlist) [FAST] 
       tempvar T Nj Ng m
       egen_sum `T', sum(`varlist') by(`by') `fast'
       egen_sum `Nj', sum(`varlist') by(`unit' `by') `fast'
       egen_sum `Ng', sum(`varlist') by(`group' `by') `fast'
       gen double `m'=0
       replace `m'=(`varlist'/`T')*log((`varlist'*`T')/(`Nj'*`Ng')) ///
		if `varlist'>0 & `varlist'<. & `Nj'>0 & `Nj'<. & `Ng'>0 & `Ng'<.
       egen_sum `generate', sum(`m') by(`by') `fast'
end

program define _decseg_mutual_p
       syntax varlist(max=1), GROUP(varlist) UNIT(varlist) GENerate(name) BY(varlist) [FAST]
       tempvar total T Nj
       tempfile fichero
       if "`fast'"!="" local f = "f"
       local by_unit "`by' `unit'"
       local by_unit : list uniq by_unit
       sort `by_unit'
       save `fichero', replace
       `f'collapse (sum) `varlist', by(`by_unit') `fast'
       egen_sum `T', sum(`varlist') by(`by') `fast'
       egen_sum `Nj', sum(`varlist') by(`by_unit') `fast'
       gen double `generate'=`Nj'/`T'
       keep `by_unit' `generate'
       sort `by_unit'
       merge m:m `by_unit' using `fichero', nogenerate sorted noreport
end

program define _decseg_atkinson
       syntax varlist(max=1), GROUP(varlist) UNIT(varlist) GENerate(name) BY(varlist) [FAST]
       tempvar Nj a tempv numN level unit_var
       tempfile fichero
       if "`fast'"!="" local f = "f"
       local by_unit "`by' `unit'"
       local by_unit : list uniq by_unit
       local by_group "`by' `group'"
       local by_group : list uniq by_group
       local by_group_unit "`by' `group' `unit'"
       local by_group_unit : list uniq by_group_unit
       sort `by'
       save `fichero', replace
       `f'collapse (sum) `varlist', by(`by_group_unit') `fast'
       egen `unit_var'=group(`unit')
       inspect `unit_var'
       qui if r(N_unique)!=. local n=r(N_unique)
       else {
       		preserve
		gen `tempv'=1
       		`f'collapse (min) `tempv', by(`unit') `fast'
		local n=_N
	       	restore	
       }
       gen `tempv'=1
       egen_sum `numN', sum(`tempv') by(`by_group') `fast'
       drop `tempv'
       egen_sum `Nj', sum(`varlist') by(`by_unit') `fast'
       drop if `numN'!=`n'
       gen double `a'=0
       replace `a'=log((`varlist')/(`Nj')) if `varlist'>0 & `varlist'<. & `Nj'>0 & `Nj'<.
       capture `f'collapse (sum) `a', by(`by_group') `fast'
       replace `a'=exp(`a'/`n')
       capture `f'collapse (sum) `a', by(`by') `fast'
       gen double `generate'=1-`a'
       sort `by'
       merge m:m `by' using `fichero', noreport nogenerate sorted
       mvencode `generate', mv(1)
end

program define _decseg_atkinson_p
       syntax varlist(max=1), GROUP(varlist) UNIT(varlist) GENerate(name) BY(varlist) [FAST]
       tempvar Nj a tempv numN unit_var
       tempfile fichero
       if "`fast'"!="" local f = "f"
       local by_unit "`by' `unit'"
       local by_unit : list uniq by_unit
       local by_group "`by' `group'"
       local by_group : list uniq by_group
       local by_group_unit "`by' `group' `unit'"
       local by_group_unit : list uniq by_group_unit
       sort `by_group'
       save `fichero', replace
       `f'collapse (sum) `varlist', by(`by_group_unit') `fast'
       egen `unit_var'=group(`unit')
       inspect `unit_var'
       if r(N_unique)!=. local n=r(N_unique)
       else {
       		preserve
		gen `tempv'=1
       		`f'collapse (min) `tempv', by(`unit') `fast'
		local n=_N
	       	restore	
       }
       gen `tempv'=1
       egen_sum `numN', sum(`tempv') by(`by_group') `fast'
       drop `tempv'
       egen_sum `Nj', sum(`varlist') by(`by_unit') `fast'
       drop if `numN'!=`n'
       if _N==0 set obs 1
       gen double `a'=0
       replace `a'=log((`varlist')/(`Nj')) if `varlist'>0 & `varlist'<. & `Nj'>0 & `Nj'<.
       egen_sum `tempv', sum(`a') by(`by_group') `fast'
       gen double `generate'=exp(`tempv'/`n') if (`numN'==`n')
       keep `by_group' `generate'
       sort `by_group'
       merge m:m `by_group' using `fichero', sorted noreport
       drop if _merge==1
       mvencode `generate', mv(0) 
end

program define _decseg_theil
       syntax varlist(max=1), GROUP(varlist) UNIT(varlist) GENerate(name) BY(varlist) [FAST]
       tempvar T Nj Ng m e tempv
       tempfile fichero
       if "`fast'"!="" local f = "f"
       local by_unit "`by' `unit'"
       local by_unit : list uniq by_unit
       local by_group "`by' `group'"
       local by_group : list uniq by_group
       local by_group_unit "`by' `group' `unit'"
       local by_group_unit : list uniq by_group_unit
       egen_sum `T', sum(`varlist') by(`by') `fast'
       egen_sum `Nj', sum(`varlist') by(`by_unit') `fast'
       egen_sum `Ng', sum(`varlist') by(`by_group') `fast'
       gen double `m'=0
       replace `m'=(`varlist'/`T')*log((`varlist'*`T')/(`Nj'*`Ng')) ///
		if `varlist'>0 & `varlist'<. & `Nj'>0 & `Nj'<. & `Ng'>0 & `Ng'<.
       egen_sum `generate', sum(`m') by(`by') `fast'
       sort `by_group'
       save `fichero', replace
       `f'collapse (sum) `varlist' (mean) `T' `Ng', by(`by_group') `fast'
       gen double `e'=0
       replace `e'=(`Ng'/`T')*log(`T'/`Ng') if `Ng'>0 & `Ng'<.
       egen_sum `tempv', sum(`e') by(`by') `fast'
       keep `by_group' `tempv'
       sort `by_group' 
       merge m:m `by_group' using `fichero', nogenerate sorted noreport
       replace `generate'=`generate'/`tempv'
end

program define _decseg_theil_p
       syntax varlist(max=1), GROUP(varlist) UNIT(varlist) GENerate(name) BY(varlist) [FAST]
       tempvar total T Nj Ng tempv1 tempv2 tempv3 e ej
       tempfile fichero
       if "`fast'"!="" local f = "f"
       local by_unit "`by' `unit'"
       local by_unit : list uniq by_unit
       local by_group "`by' `group'"
       local by_group : list uniq by_group
       local by_group_unit "`by' `group' `unit'"
       local by_group_unit : list uniq by_group_unit
       sort `by_group_unit'
       save `fichero', replace
       `f'collapse (sum) `varlist', by(`by_group_unit') `fast'
       egen_sum `T', sum(`varlist') by(`by') `fast'
       egen_sum `Nj', sum(`varlist') by(`by_unit') `fast'
       egen_sum `Ng', sum(`varlist') by(`by_group') `fast'
       gen double `tempv1'=`Nj'/`T'
       gen double `ej'=0
       replace `ej'=(`varlist'/`Nj')*log(`Nj'/`varlist') if `Nj'>0 & `Nj'<. & `varlist'<. & `varlist'>0
       egen_sum `tempv2', sum(`ej') by(`by_unit') `fast'
       keep `by_group_unit' `tempv1' `tempv2' `T' `Ng'
       sort `by_group_unit'
       merge m:m `by_group_unit' using `fichero', nogenerate sorted noreport
       sort `by_group'
       save `fichero', replace
       `f'collapse (sum) `varlist' (mean) `T' `Ng', by(`by_group') `fast'
       gen double `e'=0
       replace `e'=(`Ng'/`T')*log(`T'/`Ng') if `Ng'>0 & `Ng'<.
       egen_sum `tempv3', sum(`e') by(`by') `fast'
       keep `by_group' `tempv3'
       sort `by_group' 
       merge m:m `by_group' using `fichero', nogenerate sorted noreport
       gen double `generate'=`tempv1'*(`tempv2'/`tempv3')
end

program define _decseg_diversity
       syntax varlist(max=1), GROUP(varlist) UNIT(varlist) GENerate(name) BY(varlist) [FAST]
       tempvar T Nj Ng IPgn_0 IPg_0 IPgn IPg d e tempv
       tempfile fichero
       local by_unit "`by' `unit'"
       local by_unit : list uniq by_unit
       local by_group "`by' `group'"
       local by_group : list uniq by_group
       if "`fast'"!="" local f="f"
       egen_sum `Nj', sum(`varlist') by(`by_unit') `fast'
       gen double `IPgn_0'=0
       replace `IPgn_0'=`varlist'/`Nj'*(1-`varlist'/`Nj') ///
		if `varlist'>0 & `varlist'<. & `Nj'>0 & `Nj'<.
       egen_sum `IPgn', sum(`IPgn_0') by(`by_unit') `fast'
       sort `by_group' 
       save `fichero', replace
       `f'collapse (sum) `Ng'=`varlist', by(`by_group') `fast'
       egen_sum `T', sum(`Ng') by(`by') `fast'
       gen double `IPg_0'=0
       replace `IPg_0'=`Ng'/`T'*(1-`Ng'/`T') 
       egen_sum `IPg',  sum(`IPg_0')  by(`by') `fast'
       sort `by_group' 
       merge 1:m `by_group' using `fichero', nogenerate sorted noreport
       gen double `generate'=0
       replace `generate'=(`Nj'/`T')*(`IPg'-`IPgn')/`IPg' if `IPg'>0 & `IPg'
       sort `by'
       save `fichero', replace
       `f'collapse (mean) `generate', by(`by_unit') `fast'
       `f'collapse (sum) `generate', by(`by') `fast'
       sort `by'
       merge 1:m `by' using `fichero', nogenerate sorted noreport
end

program define _decseg_diversity_p
       syntax varlist(max=1), GROUP(varlist) UNIT(varlist) GENerate(name) BY(varlist) [FAST]
       tempvar total T Nj Ng tempv1 tempv2 tempv3 e ej
       tempfile fichero
       local by_unit "`by' `unit'"
       local by_unit : list uniq by_unit
       local by_group "`by' `group'"
       local by_group : list uniq by_group
       local by_group_unit "`by' `group' `unit'"
       local by_group_unit : list uniq by_group_unit
       if "`fast'"!="" local f="f"
       sort `by_group_unit'
       save `fichero', replace
       `f'collapse (sum) `varlist', by(`by_group_unit') `fast'
       egen_sum `T', sum(`varlist') by(`by') `fast'
       egen_sum `Nj', sum(`varlist') by(`by_unit') `fast'
       egen_sum `Ng', sum(`varlist') by(`by_group') `fast'
       gen double `tempv1'=`Nj'/`T'
       gen double `ej'=0
       replace `ej'=(`varlist'/`Nj')*(1-(`varlist'/`Nj')) if `Nj'>0 & `Nj'<. & `varlist'<. & `varlist'>0
       egen_sum `tempv2', sum(`ej') by(`by_unit') `fast'
       keep `by_group_unit' `tempv1' `tempv2' `T' `Ng'
       sort `by_group_unit'
       merge m:m `by_group_unit' using `fichero', nogenerate sorted noreport
       sort `by_group'
       save `fichero', replace
       capture `f'collapse (sum) `varlist' (mean) `T' `Ng', by(`by_group') `fast'
       gen double `e'=0
       replace `e'=(`Ng'/`T')*(1-(`Ng'/`T')) if `Ng'>0 & `Ng'<.
       egen_sum `tempv3', sum(`e') by(`by') `fast'
       keep `by_group' `tempv3'
       sort `by_group'
       merge m:m `by_group' using `fichero', nogenerate sorted noreport
       gen double `generate'=`tempv1'*(`tempv2'/`tempv3')
end

program define egen_sum
	syntax namelist(max=1), SUM(string) BY(string) [FAST]
	quietly {
	if "`by'"!="" {
		if "`fast'"!="" fcollapse (sum) `namelist'=`sum', by(`by') fast merge
		else egen double `namelist'=sum(`sum'), by(`by')
	}
	else {
		if "`fast'"!="" fcollapse (sum) `namelist'=`sum', fast merge
		else egen double `namelist'=sum(`sum')
		}
	}
end

program define _decseg_data
	syntax anything, GROUP(string) UNIT(string) BY(varlist) GENerate(name) INDEXT(varlist) ///
			[WITHIN(varlist) NOBY DECOMPOSITION FAST INDEXW(varlist) INDEXB(varlist) ///
			COMPI(varlist) COMPW(varlist) NORMALIZED ] FORMAT(string)		
	quietly {
	if "`anything'"=="mutual" {
		local short_name="M"
		local long_name="Mutual Information index"
	}
	else if "`anything'"=="atkinson" {
		local short_name="A"
		local long_name="Symmetric Atkinson index"
	}
	else if "`anything'"=="theil" {
		local short_name="H"
		local long_name="Theil's index"
	}
	else if "`anything'"=="diversity" {
		local short_name="R"
		local long_name="Relative Diversity index"
	}
	// preparing the data
	foreach lname in `generate' `generate'_B `generate'_W `generate'_weight `generate'_within {
		capture drop `lname'
	}
	if "`decomposition'"!="" {
		`f'collapse (mean) `generate'=`indext' `generate'_B=`indexb' `generate'_W=`indexw', by(`by') `fast'
		order `by' `generate' `generate'_B `generate'_W
		format `generate' `generate'_B `generate'_W `format'
	}
	else if "`within'"!="" {
		rename `indext' `generate'
		rename `indexb' `generate'_B
		rename `indexw' `generate'_W
		rename `compi'  `generate'_within
		rename `compw'  `generate'_weight
		keep `by' `within' `generate' `generate'_B `generate'_W `generate'_weight `generate'_within
		order `by' `within' `generate' `generate'_B `generate'_W `generate'_weight `generate'_within
		format `generate' `generate'_B `generate'_W `generate'_weight `generate'_within `format'
	}
	else {
		`f'collapse (mean) `generate'=`indext', by(`by') `fast'
		order `by' `generate' 
		format `generate' `format'
	}
	if "`within'"!="" & "`decomposition'"=="" {
		if "`noby'"=="" sort `by' `within'
		else {
			drop `by'
			sort `within'
		}	
	}
	else {
		if "`noby'"=="" sort `by'
		else drop `by'
	}
	// labels
	local maxlon = 63
	if "`noby'"=="" local maxlon = `maxlon' - 4
	if "`within'"!="" local maxlon = `maxlon' - 7
	local variables `group' `unit' `by' `within'
	local longitud = ustrlen("`variables'")
	// labels para generate variable
	if "`within'"!="" {
		if `longitud'<`maxlon' {
			if "`noby'"=="" {
			   label variable `generate'   "`short_name': `group' given `unit' by `by'"
			   label variable `generate'_B "`short_name' (Between term): `group' given `within' by `by'"
			   label variable `generate'_W "`short_name' (Within term): `group' given `unit' within `within' by `by'"
			}
			else {
			   label variable `generate' "`short_name': `group' given `unit'"
			   label variable `generate'_B "`short_name' (Between term): `group' given `within'"
			   label variable `generate'_W "`short_name' (Within term): `group' given `unit' within `within'"
			}
		}
		else {
			label variable `generate' "`long_name'"
			label variable `generate'_B "Between term"
			label variable `generate'_W "Within term"
		}
	}
	else {
	  if `longitud'<`maxlon' {
		if "`noby'"==""  ///
			label variable `generate' "`short_name': `group' given `unit' by `by'
		else label variable `generate' "`short_name': `group' given `unit'
	  }
	  else label variable `generate' "`long_name'"
	}
	// labels para pesos e indices locales
	if "`within'"!="" & "`decomposition'"=="" {
	   if `longitud'<`maxlon' {
		if "`noby'"=="" {
		 if "`anything'"=="mutual" label variable `generate'_weight "Proportion of `within' over `by'"
		 else label variable `generate'_weight "`short_name': Weight for each `within' in `by'"
		 label variable `generate'_within "`short_name': `group' given `unit' for each `within' by `by'"
		}
		else {
		 if "`anything'"=="mutual" label variable `generate'_weight "Proportion of `within' over total"
		 else label variable `generate'_weight "`short_name': Weight for each `within'"
		 label variable `generate'_within "`short_name': `group' given `unit' for each `within'"
		}
	   }
	   else {
		if "`anything'"=="mutual" label variable `generate'_weight "Proportion of 'within' category over 'by' category"
		else label variable `generate'_weight "Weight for each 'within' category in 'by' category"
		label variable `generate'_within "`long_name' for each 'within' category in 'by' category"
	  }
	}
	// label para dataset
	local labeldata = "`short_name' index:`group' given `unit'"
	if "`within'"!="" local labeldata = "`labeldata' within `within'"
	if "`noby'"=="" local labeldata = "`labeldata' by `by'"
	if "`normalized'"=="normalized" local labeldata = "`labeldata' (`normalized')"
	label data "`labeldata'"
	}
end

program define _show_iteration
	syntax  , I(numlist integer max=1) [BOOTstraps(numlist integer max=1) random(numlist integer max=1)]
	quietly {
		local total=`bootstraps'`random'
		if `i'==1 {
		 if "`bootstraps'"!="" noi dis as txt "Bootstrap replications (" in y `bootstraps' as txt ")" _continue
		 if "`random'"!="" noi dis as txt "Simulations (" in y `random' as txt ")" _continue
		 if `total'>500 { 
			noi dis _newline in g "{hline 4}{c +}{hline 1} 100 {hline 3}{c +}{hline 1} " _continue 
			noi dis in g "200 {hline 3}{c +}{hline 1} 300 {hline 3}{c +}{hline 1} 400 {hline 3}{c +}{hline 1} 500"
		 }
		 else  { 
			noi dis _newline in g "{hline 4}{c +}{hline 2} 10 {hline 3}{c +}{hline 2} " _continue 
			noi dis in g "20 {hline 3}{c +}{hline 2} 30 {hline 3}{c +}{hline 2} 40 {hline 3}{c +}{hline 2} 50"
		 }
		}
		if `total'>500 {
			if int(`i'/500)==(`i'/500) noi dis in g "." 
			else if int(`i'/10)==(`i'/10) noi dis in g "." _continue
		}
		else {
			if int(`i'/50)==(`i'/50) noi dis in g "." 
			else noi dis in g "." _continue
		}
	}
end

exit



