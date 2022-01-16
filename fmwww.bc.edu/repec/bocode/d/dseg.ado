*! version JanNov2022
*! author Ricardo Mora, UC3M
program dseg, rclass byable(recall)
syntax anything  [if] [in] [fweight],		///
			 Given(varlist)		///
			[Addindex(string asis)	///
			 Within(string asis)	///
			 PREFIX(name)		///
                         By(varlist)		///
			 Format(string)		///
			 SAVING(string asis)	///
			 CLEAR			///
			 NOLIST			///
			 BOOTstraps(string asis) /// // # of bootstrap samples
			 Random(numlist integer max=1)	/// // # of simulated samples
			 RSEED(numlist max=1)	/// // seed for random number generator
			 MISSING		///
			 FAST]
//	version 14
	tempname index_t S 
	tempfile temp0 temp1
	quietly {
	// parsing index, varlist1, and addindex
	gettoken index varlist: anything
	local index=strlower("`index'")
	local varlist = strltrim("`varlist'")
	local varlist: list uniq varlist
	// eliminating repetitions in index addindex
	local addindex=strlower("`addindex'")
	local index_addindex: list index | addindex
	local index_addindex: list uniq index_addindex
	// parsing "index_addindex" to "indexes" and to "alt_indexes"
	  foreach i in `index_addindex' {
	     if ustrpos(" `indexes'"," `i'")==0 ///
		 if "`i'"=="atkinson" | "`i'"=="diversity" | "`i'"=="theil" | "`i'"=="mutual" | "`i'"=="n_mutual" local indexes: list indexes | i
	     if ustrpos("`alt_indexes'","`i'")==0 ///
		 if "`i'"=="alt_atkinson" | "`i'"=="alt_diversity" | "`i'"=="alt_theil" local alt_indexes: list alt_indexes | i
	  }
	// parsing within options
	gettoken w_varlist components: within, parse(",")
	gettoken components components: components, parse(",")
	local components =  strltrim("`components'")
	// counting sample
	marksample alluse, noby strok
	markout `alluse' `varlist' `given' `by' `w_varlist', strok 
	count if `alluse'
        local totN = r(N)
	// parsing saving options
	gettoken saving savopt: saving, parse(",")
	gettoken savopt savopt: savopt, parse(",")
	// format default
	if "`format'"=="" local format="%9.4f"
	// nolist is only option with bootstraps and random
	if ("`bootstraps'"!="" | "`random'"!="") local nolist="nolist"
	// warning message
	if "`missing'"!="" & "`weight'"!="" {
	    noi di as txt "Warning: you have chosen <missing> with weighted data;" _newline ///
				_col(10) "observations without weights are not used"
	}
	// error messages
	foreach  i in `index_addindex' {
	 if "`i'"!="mutual"   & "`i'"!="atkinson"     & "`i'"!="theil"     & "`i'"!="diversity" & ///
	    "`i'"!="n_mutual" & "`i'"!="alt_atkinson" & "`i'"!="alt_theil" & "`i'"!="alt_diversity" {
	        	noi di as err "`i' index is not supported"
			error 498
   		}
	}
	if "`varlist'"=="" {
        	noi di as err "varlist required after dseg `index'"
		error 498
		}
	if "`fast'"!="" {
		foreach  c in ftools moremata {
			if "`c'"=="moremata" local c `c'.hlp
			capture: which `c'
			if (_rc) {
			    if "`c'"=="ftools" {
			      noi di as err "you need package {it:ftools} to use <fast>;" _newline ///
        			"you can install it by typing <ssc install ftools>;" _newline ///
				"to run {it:ftools}, you need the MOREMATA module if you do not have it;" _newline ///
        			"you can install it by typing <ssc install moremata>" 
			    }
			    else {
			    noi di as err "to run {it:ftools}, you need the MOREMATA module;" _newline ///
        			"you can install it by typing <ssc install moremata>" 
			    }
		            error 498
			}
		}
		foreach v of varlist `varlist' `given' `w_varlist' `by' {
			capture confirm numeric variable `v'
			if (_rc) {
			    noi di as err "<fast> requires all variables to be numeric" 
			    error 498
			}
		}
	}
	if "`components'"!="" & "`w_varlist'"=="" {
        	noi di as err "syntax error in <within()>" 
		error 498
   		}
	if "`components'"!="" & "`components'"!="components"  {
        	noi di as err "<within> suboption <`components'> not allowed" 
		error 498
   		}
	// new names conflict
	local old_v = "`by'"
	if "`components'"!="" local old_v = "`by' `w_varlist'"
	if "`old_v'"!="" {
	 foreach v of varlist `old_v' {
		foreach  i in `index' `addindex' {
		 if "`i'"=="mutual" local nombre="`prefix'M"
		 else if "`i'"=="atkinson" local nombre="`prefix'A"
		 else if "`i'"=="theil" local nombre="`prefix'H"
		 else if "`i'"=="diversity" local nombre="`prefix'R"
		 else if "`i'"=="alt_atkinson" local nombre="`prefix'AltA"
		 else if "`i'"=="alt_theil" local nombre="`prefix'AltH"
		 else if "`i'"=="alt_diversity" local nombre="`prefix'AltR"
		 else if "`i'"=="n_mutual" local nombre="`prefix'NM"
		 if "`v'"=="`nombre'" {
			noi di as error "name conflict: <`v'> already in <by> or <within>; use <prefix>" 
			error 498
		 }
		 else if "`w_varlist'"!="" & ("`v'"=="`nombre'_B" | "`v'"=="`nombre'_W" ) {
			noi di as error "name conflict: <`v'> already in <by> or <within>; use <prefix>" 
			error 498 
		 }
		 else if "`components'"!="" & ("`v'"=="`nombre'_w" | "`v'"=="`nombre'_l" ) {
			noi di as error "name conflict: <`v'> already in <by> or <within>; use <prefix>" 
			error 498 
		 }
		}
	 }
	}
	// no variable in varlist can also be in given, within, or by 
	foreach w in `varlist' {
		foreach v in `given' `by' `w_varlist' {
			if "`v'"=="`w'" {
	        	noi di as err "no variable in <varlist> can be in <given>, <within>, or <by>"
			error 498
			}
		}
	}
	// given and within variables cannot simultaneously be by variables
	foreach v_by in `by' {
		foreach v in `given' `w_varlist' {
			if "`v'"=="`v_by'" {
		        	noi di as err "no variable in <given> and/or <within> can be in <by>"
				error 498
			}
		}
	}
	// bootstraps and random must be used with clear and/or saving
	if ("`bootstraps'"!="" | "`random'"!="") & "`clear'"=="" & "`saving'"=="" {
		noi di as err "<bootstraps> and <random> must be used with <clear> and/or <saving()>"
		error 498
	}
	// bootstraps and random cannot be used with weights
	if ("`bootstraps'"!="" | "`random'"!="") & "`weight'"!="" {
        	noi di as err "<bootstraps> and <random> cannot be used with weighted data"
		error 498
	}
	// rseed can only be used with bootstraps or random
	if "`bootstraps'"=="" & "`random'"=="" & "`rseed'"!="" {
        	noi di as err "<bootstraps> or <random> must be used if <rseed> used"
		error 498
	}
	// bootstraps and random cannot be used simultaneously
	if ("`bootstraps'"!="" & "`random'"!="") {
		noi di as err "<bootstraps> and <random> cannot be used simultaneously"
		error 498
	}
	// heading message
	noi dis _newline _col(4) in g "Decomposable Multigroup Segregation Indexes"
	noi dis _newline _col(4) in g "Differences in " in y "`varlist' " in g "given " in y "`given'" _continue 
	if wordcount("`indexes'")==1 noi dis _newline _col(6) in g "Index: " _continue
	else noi dis _newline _col(6) in g "Indexes: " 
	local j=1
	foreach i in `indexes' {
		if `j'>1  noi dis in g ", " _continue
		if `j'==4  noi dis in g "" 
		if "`i'"=="mutual" noi dis _col(6) in y "Mutual Information" _continue
		else if "`i'"=="n_mutual" noi dis _col(6) in y "Normalized Mutual Information" _continue
		else if "`i'"=="atkinson" noi dis _col(6) in y "Symmetric Atkinson" _continue
		else if "`i'"=="theil" noi dis _col(6) in y "Theil's H" _continue
		else if "`i'"=="diversity" noi dis _col(6) in y "Relative Diversity" _continue
		local j=`j'+1
	}
	if "`alt_indexes'"!="" {
	 noi dis _newline _col(4) in g "Differences in " in y "`given' " in g "given " in y "`varlist'" _continue
	 if wordcount("`alt_indexes'")==1 noi dis _newline _col(6) in g "Index: " _continue
	 else noi dis _newline _col(6) in g "Indexes: " 
	 local j=1
	 foreach i in `alt_indexes' {
		if `j'>1  noi dis in g ", " _continue
		if `j'==4  noi dis in g "" 
		else if "`i'"=="alt_atkinson" noi dis _col(4) in y "Symmetric Atkinson" _continue
		else if "`i'"=="alt_theil" noi dis _col(4) in y "Theil's H" _continue
		else if "`i'"=="alt_diversity" noi dis _col(4) in y "Relative Diversity" _continue
		local j=`j'+1
	 }
	}
	if "`w_varlist'" != "" noi dis _newline _col(4) in g "Between/Within " in y "`w_varlist'" in g " decomposition" _continue
	if "`by'" != "" noi dis _newline _col(4) in g "By " in y "`by'"
	noi dis ""
	// options
	if "`weight'"!="" local peso = "[`weight'`exp']"
	if "`within'"!="" local dentro="within(`within')"
	if "`by'"!="" local para="by(`by')"
	if "`bootstraps'"!="" local trabilla="bootstraps(`bootstraps')"
	if "`random'"!="" local aleatorio="random(`random')"
	if "`rseed'"!="" local semilla="rseed(`rseed')"
	// loop for each index
	foreach i in `index_addindex' {
		local normalized=""
		// names
		if "`i'"=="mutual" local index_t="`prefix'M"	
		else if "`i'"=="atkinson" local index_t="`prefix'A"
		else if "`i'"=="theil" local index_t="`prefix'H"
		else if "`i'"=="diversity" local index_t="`prefix'R"
		else if "`i'"=="alt_atkinson" local index_t="`prefix'AltA"
		else if "`i'"=="alt_theil" local index_t="`prefix'AltH"
		else if "`i'"=="alt_diversity" local index_t="`prefix'AltR"
		else if "`i'"=="n_mutual" {
			local index_t="`prefix'NM"
			local indice="mutual"
			local normalized="normalized"
		}
		if substr("`i'",1,4)!="alt_" {
			local lista1="`varlist'"
			local lista2="`given'"
			local indice=subinstr("`i'","n_","",1)
		}
		else {
			local lista1="`given'"
			local lista2="`varlist'"
			local indice=subinstr("`i'","alt_","",1)
		}
		preserve
		local orden=`orden'+1
		noi dseg2 `indice' `lista1' `if' `in' `peso',					///
			 given(`lista2')							///
			 names(`index_t' `index_t'_B `index_t'_W `index_t'_w `index_t'_l )	///
			 format(`format')	///
			 `dentro'		///
                         `para'			///
			 `trabilla'		/// // bootstraps option
			 `aleatorio'		/// // random option
			 `semilla'		/// // seed for random number generator
			 `missing'		///
			 `normalized'		/// // to normalize mutual information
			 `fast'
		if `orden'==1 {
			d, varlist
			local listaord=r(sortlist)
			local listaord="`listaord'"
		}
		save `temp0', replace
		if `orden'>1 {
			use `temp1', replace	
			merge 1:1 _n using `temp0', nogenerate sorted noreport
		}
		save `temp1', replace
		restore
	 }
	if "`clear'"!="clear" preserve
	  use `temp1', replace
	  if "`listaord'"!="." sort `listaord'
	  // storing in matrix (if possible)
	  d, varlist
	  local matvars=r(varlist)
	  capture mkmat `matvars', matrix(`S') 
	  if _rc!=0 noi di  _col(4) as txt "Warning: indexes could not be stored as matrix"
	  // saving in file
	  if "`saving'"!="" {
		save "`saving'", `savopt'
		noi dis _col(4) as txt "File `saving' saved"
	  }
	  // display
	  if "`clear'"=="clear" & "`nolist'"=="nolist" noi describe, fullnames
	  if "`nolist'"=="" noi l , noobs clean 
	if "`clear'"!="clear" restore
	return clear
	capture return matrix S = `S'
	return scalar N = `totN'
	return local notion = "Differences in `varlist' given `given'"
	return local index "`index' `addindex'"
	return local cmd "dseg"
	} // end of quietly
end

program dseg2, rclass byable(recall)
syntax anything  [if] [in] [fweight],		///
			 Given(varlist)		///
			 NAMES(namelist)	///
			 Format(string)		///
			[Within(string asis)	///
                         By(varlist)		///
			 BOOTstraps(string asis) /// // # of bootstrap samples
			 Random(string asis)	/// // # of simulated samples
			 RSEED(numlist max=1)	/// // seed for random number generator
			 MISSING		///
			 NORMALIZED		/// // to normalized mutual information
			 FAST]
	quietly {
	tempvar ones rep level n_random u
	tempfile dsegfile rassfile
	tempname random_name 
	// parsing index and varlist1
	gettoken index varlist: anything
	// parsing within options
	gettoken within components: within, parse(",")
	gettoken components components: components, parse(",")
	local components =  strltrim("`components'")
	// counting sample
	marksample alluse, noby strok
	markout `alluse' `varlist' `given' `by' `within', strok 
	// defaults
	// if within, default is decomposition, if components, then decomposition is null string
	if "`within'"!="" {
		if "`components'"=="" local decomposition="decomposition"
		else local decomposition=""
	}
	if "`weight'"=="" {
		local weight="fweight"	
		local exp="= `ones'"
		gen `ones'=1
		}
	if "`fast'"!="" local f="f"
	// index computation
	if "`bootstraps'"=="" & "`random'"=="" {
		noi _decseg `index' `varlist' `if' `in' [`weight'`exp'], unit(`given') names(`names') ///
			within(`within') by(`by') `fast' `components' `missing' `normalized' format(`format') 
	}
	// bootstrapping
	else if "`bootstraps'"!="" {
		// parsing bootstraps options
		gettoken bootstraps bootstraps_options: bootstraps, parse(",")
		local bootstraps_options =  strltrim("`bootstraps_options'")
		noi dis _newline as txt "Index: `index'" 
		local i=0
		while `i'<=`bootstraps' {
		   preserve
		   if `i'!=0 {
			noi _show_iteration, i(`i') bootstraps(`bootstraps')
		   	bsample `bootstraps_options'
		   }
		   _decseg `index' `varlist' `if' `in' [`weight'`exp'], unit(`given') names(`names') ///
			within(`within') by(`by') `fast' `components' `missing' `normalized' format(`format') 
		   if `i'==0 {
			d, varlist
			if r(listaord)!=. local listaord=r(sortlist)
		   }
		   gen bsn=`i'
		   if "`i'"!="0" append using `dsegfile'
		   save `dsegfile', replace
		   local i=`i'+1
		   restore
		}
		use `dsegfile', replace
		label variable bsn "Bootstrap sample number"
		order bsn `listaord'
		sort bsn `listaord'
		noi dis _newline _col(4) as txt "" 
	}
	// randomization test & Carrington-Troske modification
	else {
		noi dis _newline as txt "Index: `index'" 
		// creating the random assignment file for group_list
		preserve
			keep `varlist'
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
			drop `u' `varlist'
			gen `n_random'=_n
			sort `n_random'
			merge 1:1 `n_random' using `rassfile', nogenerate sorted noreport
		   }
		   _decseg `index' `varlist' `if' `in' [`weight'`exp'], unit(`given') names(`names') ///
			within(`within') by(`by') `fast' `components' `missing' `normalized' format(`format') 
		   if `i'==0 {
			d, varlist
			if r(listaord)!=. local listaord=r(sortlist)
		   }
		   gen ssn=`i'
		   if "`i'"!="0" append using `dsegfile'
		   save `dsegfile', replace
		   local i=`i'+1
		   restore
		}
		use `dsegfile', replace
		label variable ssn "Simulation sample number"
		order ssn `listaord'
		sort ssn `listaord'
		noi dis _newline _col(4) as txt "" 
	}
}		// endof quietly
end

program define _decseg
        syntax  anything [if] [in] [fweight /] ,		///
					 NAMES(namelist)	///
					 UNIT(varlist) 		///
					[Within(varlist) 	///
                                         By(varlist)		///
					 FAST			///
					 MISSING		///
					 NORMALIZED		///
					 COMPONENTS		///
					 Format(string)		///
					]
	quietly {
	tempname njg ng         
	tempvar level group frequency tempv numG grupos unidades 
	marksample touse, strok novarlist
	gettoken index varlist: anything
	local varlist = strltrim("`varlist'")
	// parsing names options
	gettoken index_t names: names
	gettoken index_b names: names
	gettoken index_w names: names
	gettoken comp_w names: names
	gettoken comp_i names: names
	if "`by'"=="" {
		gen `level'=1
		local by="`level'"
		local noby="noby"
		}
	if "`fast'"!="" local f = "f"
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
	// preparing for mutual normalization if required
	if "`index'"=="mutual" & "`normalized'"=="normalized" {
		egen `grupos'=group(`groups')
		inspect `grupos'
		local G=r(N_unique)
		egen `unidades'=group(`units')
		inspect `unidades'
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
          replace `index_b'=0 if `index_b'<0 		// to avoid very small negative values instead of zero
	}
	else {
		foreach v in `index_w' `index_b' `comp_i' `comp_w' {
			gen `v'=.
		}
	}
	// normalizing mutual if required
	if "`index'"=="mutual" & "`normalized'"=="normalized" {
		foreach v in `index_t' `index_w' `index_b' `comp_w' {
			replace `v'=`v'/log(`base')
		}
	}
	// preparing the data
	format `index_t' `index_b' `index_w' `comp_i' `comp_w' `format'
	order `by' `within' `index_t' `index_b' `index_w' `comp_w' `comp_i' 
	sort `by' `within'
	// simpler cases:
	if "`components'"=="" `f'collapse (mean) `index_t' `index_b' `index_w', by(`by') `fast'
	if "`noby'"=="noby" drop `by'
	if "`noby'"=="noby" & "`within'"=="" keep `index_t'
	else if "`noby'"=="noby" & "`within'"!="" & "`components'"=="" keep `index_t' `index_b' `index_w' 
	else if "`noby'"=="noby" & "`within'"!="" & "`components'"!="" {
		order `within' `index_t' `index_b' `index_w' `comp_w' `comp_i' 
		sort `within'
	}
	else if "`noby'"=="" & "`within'"=="" {
		keep `by' `index_t'
		order `by' `index_t'
		sort `by' `index_t'
	}
	else if "`noby'"=="" & "`within'"!="" & "`components'"=="" {
		order `by' `index_t' `index_b' `index_w'
		sort `by' 
	}
	// labels
	if "`within'"!="" local dentro = " indexw(`index_w') indexb(`index_b') within(`within')"
	if "`noby'"=="" local para = "by(`by')"
	if "`components'"!="" local componentes= " compi(`comp_i') compw(`comp_w')"
	noi _decseg_labels `index', group("`varlist'") unit("`unit'") indext(`index_t') 	///
			`dentro' `para'	`componentes' 						///
			`fast' `normalized' format(`format') 
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
       merge 1:m `by_unit' using `fichero', nogenerate sorted noreport
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
       merge 1:m `by' using `fichero', noreport nogenerate sorted
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
       `f'collapse (mean) `generate', by(`by_group') `fast'
       merge 1:m `by_group' using `fichero', sorted noreport
       drop if _merge==1
       drop _merge
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
       merge 1:m `by_group' using `fichero', nogenerate sorted noreport
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
       merge 1:m `by_group_unit' using `fichero', nogenerate sorted noreport
       sort `by_group'
       save `fichero', replace
       `f'collapse (sum) `varlist' (mean) `T' `Ng', by(`by_group') `fast'
       gen double `e'=0
       replace `e'=(`Ng'/`T')*log(`T'/`Ng') if `Ng'>0 & `Ng'<.
       egen_sum `tempv3', sum(`e') by(`by') `fast'
       keep `by_group' `tempv3'
       sort `by_group' 
       merge 1:m `by_group' using `fichero', nogenerate sorted noreport
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
       merge 1:m `by_group_unit' using `fichero', nogenerate sorted noreport
       sort `by_group'
       save `fichero', replace
       capture `f'collapse (sum) `varlist' (mean) `T' `Ng', by(`by_group') `fast'
       gen double `e'=0
       replace `e'=(`Ng'/`T')*(1-(`Ng'/`T')) if `Ng'>0 & `Ng'<.
       egen_sum `tempv3', sum(`e') by(`by') `fast'
       keep `by_group' `tempv3'
       sort `by_group'
       merge 1:m `by_group' using `fichero', nogenerate sorted noreport
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

program define _decseg_labels
	syntax anything, 	///
		GROUP(string) 	///
		UNIT(string) 	///
		INDEXT(varlist) ///
		FORMAT(string)	///
		[BY(varlist) WITHIN(string) FAST INDEXW(varlist) INDEXB(varlist) ///
		COMPI(varlist) COMPW(varlist) NORMALIZED] 
	quietly {
	if "`anything'"=="mutual" {
		local short_name="Mutual"
		local long_name="Mutual Information index"
	}
	else if "`anything'"=="atkinson" {
		local short_name="Atkinson"
		local long_name="Symmetric Atkinson index"
	}
	else if "`anything'"=="theil" {
		local short_name="Theil"
		local long_name="Theil's index"
	}
	else if "`anything'"=="diversity" {
		local short_name="R Diversity"
		local long_name="Relative Diversity index"
	}
	local maxlon = 63
	if "`noby'"=="" local maxlon = `maxlon' - 4
	if "`within'"!="" local maxlon = `maxlon' - 7
	local longitud = ustrlen("`group' `unit' `by' `within'")
	// variable labels
	if "`within'"!="" {
		if `longitud'<`maxlon' {
			if "`by'"!="" {
			   label variable `indext' "`short_name': `group' given `unit' by `by'"
			   label variable `indexb' "`short_name' (Between term): `group' given `within' by `by'"
			   label variable `indexw' "`short_name' (Within term): `group' given `unit' within `within' by `by'"
			}
			else {
			   label variable `indext' "`short_name': `group' given `unit'"
			   label variable `indexb' "`short_name' (Between term): `group' given `within'"
			   label variable `indexw' "`short_name' (Within term): `group' given `unit' within `within'"
			}
		}
		else {
			label variable `indext' "`long_name'"
			label variable `indexb' "Between term"
			label variable `indexw' "Within term"
		}
	}

	else {
	  if `longitud'<`maxlon' {
		if "`by'"!=""  label variable `indext' "`short_name': `group' given `unit' by `by'
		else             label variable `indext' "`short_name': `group' given `unit'
	  }
	  else label variable `indext' "`long_name'"
	}
	// labels para pesos e indices locales
	if "`compw'"!="" {
	   if `longitud'<`maxlon' {
		if "`by'"!="" {
		 label variable `compw' "`short_name': Local weight for each `within' in `by'"
		 label variable `compi' "`short_name': `group' given `unit' for each `within' by `by'"
		}
		else {
		 label variable `compw' "`short_name': Local weight for each `within'"
		 label variable `compi' "`short_name': `group' given `unit' for each `within'"
		}
	   }
	   else {
		label variable `compw' "Local weight"
		label variable `compi' "Local index"
	  }
	}
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



