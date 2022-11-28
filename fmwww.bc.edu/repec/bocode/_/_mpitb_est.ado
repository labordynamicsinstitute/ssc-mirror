*! part of -mpitb- the MPI toolbox

cap program drop _mpitb_est
program define _mpitb_est 
	syntax [if] [in], Name(string) /// 
		[Klist(numlist min=1 >=1 <=100 asc int) Weights(string) /// 
		INDKlist(numlist min=1 >=1 <=100 asc int) Measures(string) /// 
		INDMeasures(string) aux(string) Over(string) addmeta(string asis)  /// 
		DTAsave(string) svy DOUble gen replace skipgen noestimate Verbose /// 
		TVar(varname) LFRame(string) LSAve(string) /// LEVELFRame(string) LEVELSAve(string) /// 08-04-2021 
		COTMeasures(namelist) COTOpt(namelist) ts /// 
		COTYear(varname numeric) COTFRame(string) COTSAve(string) /// 
		cotk(numlist)]	// todo

	* syntax checks (direct)
	if "`measures'`indmeasures'`aux'" == "" & "`cotmeasures'" == "" {
		di as err "No measure specified. Nothing to estimate."
		exit 197
	}
	else if "`measures'`indmeasures'`aux'" == "" & "`cotmeasures'" != "" {
		di as err "Estimation of COT requires level estimates. Set option {bf:measures()} ..."
		exit 198
	}
	
	if ("`indklist'" == "") loc indklist `klist'

	if ("`measures'" != "" | "`indmeasures'" != "") & ("`klist'" == "" | "`weights'" == "")  {
		di as err "Both {bf:measures()} and {bf:indmeasures()} require {bf:klist()} and {bf:weights()}!"
		exit 198
	}
	
	if "`measures'" == "all"{
		loc measures H M0 A
		//loc dim dim							// switch of gafvars - redundant
	}
	if "`measures'" != "" {
		foreach m in `measures' {
			if !inlist("`m'","M0","H","A") {
				di as err "{bf:`m'} cannot be estimated. Unknown measure."
				err 198
			} 
		}
	}
	
	if "`indmeasures'" == "all" {
		loc indmeasures hdk actb pctb
	}
	if "`indmeasures'" != "" {
		foreach m in `indmeasures' {
			if !inlist("`m'","hdk","actb","pctb") {				// censored hc, abs ctrb, rel ctrb
				di as err "{bf:`m'} cannot be estimated. Unknown measure."
				err 198
			}
		}
		loc ivar indicator	// switch on for gafvars
		if ustrpos("`indmeasures'","pctb") != 0 & ustrpos("`measures'","M0") == 0 {
			di as err "Estimation of {bf:pctb} requires {bf:M0}!"
			err 198 
		}
	}
		
	if "`aux'" == "all" {
		loc aux mv hd N
	}
	else if "`aux'" != "" {
		foreach m in `aux' {
			if !inlist("`m'","mv","hd","N") {					// miss values, uncensored headcounts, N
				di as err "{bf:`m'} cannot be estimated. Unknown measure."
				err 198
			} 
		}
	}
	
	if "`measures'" == "" & "`indmeasures'" == "" {
		loc skipgen skipgen		// now needed for dropping gen vars correctly; later: depends on whether gafvars is called within or after weight options
	}
	

	if "`over'" != "" {
		parse_over `over'
		
		loc over_varlist = s(over_varlist)
		if "`s(over_k)'" != "" {
			loc over_k = s(over_k)
		}
		else {
			loc over_k `klist'
		}
		
		if "`s(over_indklist)'" != "" {
			loc over_indklist = s(over_indklist)
		}
		else {	
			loc over_indklist `over_k'
		}	
		loc nooverall `s(overall)'
	}
	
	if "`gen'" != "" & "`skipgen'" != "" {
		di as err "Please choose either {bf:gen} or {bf:skipgen}"
		err 198
	}
	
	if "`estimate'" != "" {					// provisions if nothing is estimated
		loc nooverall nooverall
		loc over_varlist ""		// maybe better dedicated switch?
		if "`addmeta'" != "" {
			di as err "option -addmeta()- not allowed with -noestimate-"
			err 198
		}	
	}
	
	* checks on svy 
	qui svyset 
	if "`svy'" != "" & ("`if'" != "" | "`in'" != "") {
		di as err "Option {bf:svy} may not be combined with {bf:if} or {bf:in}."
		exit 119 
	}
	else if "`svy'" != "" & "`r(settings)'" == ", clear" {
		di as err "Option {bf:svy} set, but data not {helpb svyset}."
		exit 119
	}
	else if "`svy'" == "" & "`r(settings)'" != ", clear" {
		di as err "Warning: Data is {helpb svyset}, but {bf:svy} option not set." /// 
			_n "Either set {bf:svy} option or {bf:svyset, clear}."
		exit 119 
	}
	if "`svy'" == "" & "`r(settings)'" == ", clear" {
		di as err "Warning: Data assumed to be simple random sample." /// 
			_n "Consider {bf:svy} option and {helpb svyset}."
			svyset _n 
	}

	* new direct checks (08-04-2021)
	if "`lframe'`lsave'" == "" & "`estimate'" == "" {
		di as err "at least one of {bf:lframe}, {bf:lsave} is required."
		exit 197
	}
	if "`cotmeasures'" != "" {
		if "`cotmeasures'" == "all"{
			loc cotmeasures H M0 A hd hdk
		}
		foreach m in `cotmeasures' {
			if !inlist("`m'","M0","H","A","hd","hdk","") {
				di as err "Unknown COT measure {bf:`m'}."
				exit 198
			} 
		}
		* check whether required levels will be estimated (16/05/2022)
		loc unestcot : list cotmeasures - measures 
		loc unestcot : list unestcot - indmeasures
		loc unestcot : list unestcot - aux
		if "`unestcot'" != "" {
			di as err "Changes of {bf:`unestcot'} cannot be estimated without respective levels." 
			exit 197
		}

		if "`cotframe'`cotsave'" == "" & "`estimate'" == ""  {
			di as err "at least one of {bf:cotframe()}, {bf:cotsave()} is required (for COT)."
			exit 197
		}
		foreach l in tvar cotyear {
			if "``l''" == "" {
				di as err "option {bf:`l'()} is required (for COT)."
				exit 198
			}
		}
		if "`cotopt'" != "" {
			foreach o in `cotopt' {
				if !inlist("`o'","tot","tota","total","inseq") & !inlist("`o'","noa","noan","noann","nor","nora","noraw") {
					di as err "Unknown option {bf:`o'}."
				err 198
				}
			}			
		}
		if "`cotopt'" == "" {
			loc cotopt total
		}
	}
	
	* file and frame name checks (08-04-2021)
	if "`lframe'" != "" {
		parse_frname `lframe'				// includes syntax checks & new, valid frame name
		loc lframe `s(name)' , `s(replace)'	// update loc 
	}
	if "`cotframe'" != "" {
		parse_frname `cotframe'
		loc cotframe `s(name)' , `s(replace)'
	}
	if "`lsave'" != "" {
		parse_save `lsave'
		loc lsave `s(name)' , `s(replace)'
	}
	if "`cotsave'" != "" {
		parse_save `cotsave'
		loc cotsave `s(name)' , `s(replace)'
	}
	

	* syntax checks (indirect)
	loc names `_dta[MPITB_names]'
	if "`name'" == "" {
		if "`names'" == "" {
			di as err "No MPI found. Please run {cmd:mpitb set} first!"
			err 198
		}
		else if `: word count `names'' > 1 {
			di as err "Found more than 1 MPI. Please use option 'name()'!"
			err 198
		}
		else {
			loc name `names'
		}
	}
	else {
		if `:list name in names' == 0 {
			di as err "MPI '`name'' not found!"
			err 198
		}
	}
	
	* existing sample variable (chk before est)
	if "`gen'" != "" & "`replace'" == "" {
		conf new v sample
	}
	
	* verbose option
	if "`verbose'" == "" {
		loc qui qui
	}
		
	marksample touse
	
	* further checks
		// - svyset?
	* read in svy weights vars (for _wmbygroup)
	qui svyset 
	if "`r(wvar)'" != "" {
		loc wgt_opt wgt(`r(wvar)')
	}
	
	* read in chars
	loc dnames `_dta[MPITB_`name'_dim_names]'
	loc Ndim : word count `dnames'
	foreach d of loc dnames {
		loc `d'vars `_dta[MPITB_`name'_dim_`d'_vars]'
		loc depvars `depvars' ``d'vars'
	}
	
	* preprocess indicator list
	foreach d of varlist `depvars' {
		qui count if !mi(`d')
		if (`r(N)'>0) loc actdepvars `actdepvars' `d'
	}
	loc misind : list depvars - actdepvars

	* preprocess meta					// todo: add test for # meta
	loc i 0
	foreach s in `addmeta' {
		parse_meta "`s'"
		loc m`++i'_name = s(name)
		loc m`i'_cont = s(content)
	}
	loc Nmeta `i'
	
	* preprocess weights
	if "`weights'" != "" {
		parse_weights , `weights'
		loc dimw `s(dimw)'
		loc indw `s(indw)'
		loc equal `s(equal)'
		loc allwgts `s(all)'
		loc wgts_name `s(name)'
		
		if "`equal'" != "" & "`wgts_name'" == "" {
			loc wgts_name "equal"
		}
		
		if "`dimw'" != "" & "`wgts_name'" == "" {
			// check (i) sum = 1; (ii) # weights = # dimensions; (iii) each weight 0-100 ?
			* loc wgts_name ""
			foreach w of numlist `dimw' {
				loc w = strofreal(`=100*`w'',"%03.0f")
				loc wgts_name "`wgts_name'`w'"
			}

		}
	}
	
	* preprocess k 
	loc allk `klist' `indklist' `over_k' `over_indklist'
	loc allk : list uniq allk
	loc allk : list sort allk

	********************
	*** program body *** 
	********************
		* calc wgts matrix if needed
		if "`allwgts'" != "" {
			genwgts , ndim(`Ndim') step(`allwgts')
			mat W = r(wgts)						// make tempname ASP
		}
		
		* calc number of estimates
/*
		loc Ndep `: word count `depvars''
		loc Nmsr `: word count `measures''
		loc Nmsrd `: word count `indmeasures''
	
		if ("`nooverall'" == "") loc Noverall = `Nmsr' *  `: word count `klist'' + `Nmsrd'  * `: word count `indklist'' * `Ndep'
		else loc Noverall 0
		
		if "`over_varlist'" != "" {
			foreach v of varlist `over_varlist' {
				qui inspect `v'
				loc Nsubgr`v' = r(N_unique)
				loc Nsubgr = `Nsubgr' + `Nsubgr`v''
			}
			loc Nover`v' = `Nsubgr' * (`Nmsr' *  `: word count `over_k'' +  `Nmsrd' *  `: word count `over_indklist'' * `Ndep') 
		}
		else loc Nover 0
		loc Ntot = `Nover' + `Noverall'
		di as txt "#Estimates: overall `Noverall'; all subgroups: `Nover'; in total `Ntot'. "
*/	
		* genafvars --- by wgts-option:
		if "`dimw'" != "" {
			// create name based on input (place in preprocess?)
			// correct wgts assumed
			_mpitb_setwgts , dimw("`dimw'") name(`name') wgtsname(`wgts_name') store
			loc wgts_dep `r(wgts_dep)'				// obsolete - just for double check
			loc wgts_dim `r(wgts_dim)'
			loc Nwgts = 1						// cross-check and estimation loop
			if ("`skipgen'" == "") `qui' _mpitb_gafvars , k(`allk') indvars(`actdepvars') indw(`wgts_dep') wgtsid(`wgts_name') cvec `ivar' `double' `replace'
			loc genvars `r(genvars)'
		}
		if "`indw'" != "" {
			_mpitb_setwgts , indw("`indw'") name(`name') wgtsname(`wgts_name') store
			loc wgts_dep `r(wgts_dep)'				// obsolete - just for double check
			loc wgts_dim `r(wgts_dim)'
			loc Nwgts = 1						// cross-check and estimation loop
			if ("`skipgen'" == "") `qui' _mpitb_gafvars , k(`allk') indvars(`actdepvars') indw(`wgts_dep') wgtsid(`wgts_name') cvec `ivar' `double' `replace'
			loc genvars `r(genvars)'
		}
		if "`equal'" != "" {
			forval d = 1/`Ndim'{
				loc w "`w' `=1/`Ndim''"
			}
			_mpitb_setwgts , dimw("`w'") name(`name') wgtsname(equal) store
			loc wgts_dep `r(wgts_dep)'				// obsolete - just for double check
			loc wgts_dim `r(wgts_dim)'
			loc Nwgts = 1						// cross-check and estimation loop
			if ("`skipgen'" == "") `qui' _mpitb_gafvars , k(`allk') indvars(`actdepvars') indw(`wgts_dep') wgtsid(`wgts_name') cvec `ivar' `double' `replace'
			loc genvars `r(genvars)'
		}
		if "`allwgts'" != "" {
			
			genwgts , ndim(`Ndim') step(`allwgts') mat(allwgts)		// create all pos wgts matrix
			loc Nwgts = `r(Nwgts)'
					// make allwgts matrix temp ASP
			if "`skipgen'" == "" {
				forval w = 1/`Nwgts' {
					m swgts(`w',"allwgts","cwgts","cwgtsid")
					mpi_setwgts , dimw(`cwgts') name(`name') wgtsname(`cwgtsid') store
					loc wgts_dep `r(wgts_dep)'
					`qui' _mpitb_gafvars , k(`allk') indvars(`actdepvars') indw(`wgts_dep') wgtsid(`cwgtsid') `double' `replace' // cvec
					loc genvars `r(genvars)'
				}
			}
			loc wgts_dep "Omitted. Too many..."
			loc wgts_dim "Omitted. Too many..."
		}
		
		* now indw are defined
		_mpitb_show , n(`name') 
		
		* defined locals
		`qui' {
			di as txt "{hline}"
			di as txt "names: " as res "`name'"
			di as txt "klist: " as res "`klist'"
			di as txt "indklist: " as res "`indklist'"
			di as txt "allk: " as res "`allk'"
			di as txt "weights (option): " as res "`weights'"
			di as txt "# of wgts: " as res "`Nwgts'"
			di as txt "ind-wgts: " as res "`wgts_dep'" 
			di as txt "dim-wgts: " as res "`wgts_dim'" 
			di as txt "weights name: " as res "`wgts_name'"
			di as txt "measures: " as res "`measures'"
			di as txt "indmeasures: " as res "`indmeasures'"
			di as txt "aux-measures: " as res "`aux'"
			di as txt "overvars: " as res "`over_varlist'" 
			di as txt "overk: " as res "`over_k'"
			di as txt "overindklist: " as res "`over_indklist'" 
			*di as txt "Nsubgroups (all): " as res "`Nsubgr'"
		
			di as txt "nooverall: " as res "`nooverall'"
			di as txt "dtasave: " as res "`dtasave'"
			di as txt "estimate: " as res "`estimate'"

			di as txt "dimensions: " as res  "`dnames'"
			di as txt "indicator: " as res "`depvars'" 
			di as txt "actual indicators: " as res "`actdepvars'"
			di as txt "missing indicators: " as res "`misind'" 
			foreach d of loc dnames {
				di as txt "dimensions `d': " as res "``d'vars'"
			}
			di as txt "# metainfos: " as res "`Nmeta'"
			forval i = 1/`Nmeta' {
				di as txt "meta info `i': " as res "`meta`i'_name'" as txt " and " as res "`meta`i'_content'"
			}
		}
		* generated variable / sum

		if "`skipgen'" == "" & "`qui'" == "" {
			di as txt "generated variables:"
			sum `genvars' 	
			di as txt "{hline}"
		}

		* create sample vars / marksample
		markout `touse' `actdepvars'
		cap svymarkout `touse'
		if _rc == 2000 {
			di as err "check your svy and deprivation vars:"
			err 2000
		}
		if "`skipgen'" == "" {
			if ("`replace'" != "") cap drop sample
			`qui' gen sample = `touse'
			loc genvars `genvars' sample
		}
		
		**************************
		*** actual estimations ***
		**************************
		
		* setup frame (added 08-04-2021)
		if ("`tvar'" != "") loc t t 	// only for rframe
		tempname frlev 
		_mpitb_rframe , fr(`frlev') add(`m1_name') `ts' `double' `t' 
		if "`cotmeasures'" != ""  {
			tempname frcot
			_mpitb_rframe , fr(`frcot') add(`m1_name') `ts' `double' cot
		}
		
		* overall 
		if "`nooverall'" == "" {
			loc ri = c(linesize) - 79
			di in txt "{dlgtab 0 `ri':Estimation}"
			
			* aux
			if ustrpos("`aux'","mv") != 0 {				// missing values, retained sample, N
				* mv indicators
				foreach d of varlist `actdepvars' {
					`qui' recode `d' (nonmiss=0)(mis=1) , gen(`d'_mv)
					loc genauxvars `genauxvars' `d'_mv
					`qui' mean `d'_mv , over(`tvar')
					_mpitb_stores , fr(`frlev') tvar(`tvar') l(nat) m(mv_uw) i(`d') sp(`name') add(`m1_cont') `ts'
				}
				* retained sample 
				`qui' mean `touse' , over(`tvar')			// unweighted 
				_mpitb_stores , fr(`frlev') tvar(`tvar') l(nat) m(mv_uw) sp(`name') add(`m1_cont') `ts'
				
				if "`svy'" != "" & "`_dta[_svy_wvar]'" != "" {
					`qui' mean `touse' [aw=`_dta[_svy_wvar]'] , over(`tvar')		// weighted 
					_mpitb_stores , fr(`frlev') tvar(`tvar') l(nat) m(mv_w) sp(`name') add(`m1_cont') `ts'
				}
			}
			if ustrpos("`aux'","N") != 0 {
				`qui' total `touse' if `touse'  , over(`tvar')		
				_mpitb_stores , fr(`frlev') tvar(`tvar') l(nat) m(N) sp(`name') add(`m1_cont') `ts'
			}
			if ustrpos("`aux'","hd") != 0 {				// uncensored headcounts
				foreach d of varlist `actdepvars' {
					`qui' svy : mean `d' if `touse' , over(`tvar')
					_mpitb_stores , fr(`frlev') tvar(`tvar') l(nat) m(hd) i(`d') sp(`name') add(`m1_cont') `ts'
					if ustrpos("`cotmeasures'","hd") != 0 {
						`qui' _mpitb_estcot , fr(`frcot') tvar(`tvar') y(`cotyear') m(hd) i(`d') sp(`name') add(`m1_cont') `ts' `cotopt'
					}

				}
			}
			* main-measures
			if "`measures'" != "" {
				forval w = 1/`Nwgts' {
					if (`Nwgts' > 1) m swgts(`w',"allwgts","cwgts","wgts_name")
				
					foreach k of numlist `klist' {
						loc ks = strofreal(`k',"%02.0f")		// k-string 
						if ustrpos("`measures'","H") != 0 {
							`qui' svy : mean I_`ks'_`wgts_name' if `touse' , over(`tvar') 
							_mpitb_stores , fr(`frlev')  tvar(`tvar') l(nat) m(H) sp(`name') w(`wgts_name') k(`ks') add(`m1_cont') `ts'
							if ustrpos("`cotmeasures'","H") != 0 {
								`qui' _mpitb_estcot , fr(`frcot') tvar(`tvar') y(`cotyear') m(H) sp(`name') k(`ks') w(`wgts_name') add(`m1_cont') `ts' `cotopt'
							}
						}
						if ustrpos("`measures'","M0") != 0 {
							`qui' svy : mean c_`ks'_`wgts_name' if `touse'	, over(`tvar')
							_mpitb_stores , fr(`frlev')  tvar(`tvar') l(nat) m(M0) sp(`name') w(`wgts_name') k(`ks') add(`m1_cont') `ts'
							if ustrpos("`cotmeasures'","M0") != 0 {
								`qui' _mpitb_estcot , fr(`frcot') tvar(`tvar') y(`cotyear') m(M0) sp(`name') k(`ks') w(`wgts_name') add(`m1_cont') `ts' `cotopt'
							}
						}
						if ustrpos("`measures'","A") != 0 {
							`qui' count if I_`ks'_`wgts_name' == 1 
							if `r(N)' > 0 {
								`qui' svy, subpop(I_`ks'_`wgts_name') : mean c_`ks'_`wgts_name' if `touse' , over(`tvar')				
								_mpitb_stores , fr(`frlev')  tvar(`tvar') l(nat) m(A) sp(`name') w(`wgts_name') k(`ks') add(`m1_cont') `ts'
								if ustrpos("`cotmeasures'","A") != 0 {
									`qui' _mpitb_estcot , fr(`frcot') tvar(`tvar') y(`cotyear') m(A) sp(`name') k(`ks') w(`wgts_name') add(`m1_cont') `ts' `cotopt'
								}
							}
						}
					}
				}
				rpt_Nest , f(`frlev') s(national main)
				if ("`frcot'" != "") rpt_Nest , f(`frcot') cot s(national main)
			}
			* dimensional
			if "`indmeasures'" != "" {
				foreach k of numlist `indklist' {
					loc ks = strofreal(`k',"%02.0f")		// k-string 
					foreach d of varlist `actdepvars' {
						if ustrpos("`indmeasures'","hdk") != 0 {
							`qui' svy : mean c`d'_`ks'_`wgts_name' if `touse'	, over(`tvar')				
							_mpitb_stores , fr(`frlev')  tvar(`tvar') l(nat) m(hdk) i(`d') sp(`name') w(`wgts_name') k(`ks') add(`m1_cont') `ts'
							if ustrpos("`cotmeasures'","hd") != 0 {
								`qui' _mpitb_estcot , fr(`frcot') tvar(`tvar') y(`cotyear') m(hdk) i(`d') sp(`name') w(`wgts_name') k(`ks') add(`m1_cont') `ts' `cotopt'
							}
						}
						if ustrpos("`indmeasures'","actb") != 0 {
							`qui' svy : mean actb_`d'_`ks'_`wgts_name' if `touse'	, over(`tvar')
							_mpitb_stores , fr(`frlev')  tvar(`tvar') l(nat) m(actb) i(`d') sp(`name') w(`wgts_name') k(`ks') add(`m1_cont') `ts'
						}
						if ustrpos("`indmeasures'","pctb") != 0 {
							if ("`replace'" != "") cap drop pctb_`d'_`ks'_`wgts_name'
							*est res M0`ks'_`wgts_name'_nat
							*loc M0_`ks'_`wgts_name' = _b[c_`ks'_`wgts_name']
							*di `"`M0_`ks'_`wgts_name''"'
							tempvar m0group
							_wmbygrp c_`ks'_`wgts_name' if `touse' , bys(`tvar') `wgt_opt' outvar(`m0group')
							`qui' gen `double' pctb_`d'_`ks'_`wgts_name' = actb_`d'_`ks'_`wgts_name' / `m0group' 
							loc genvars `genvars' pctb_`d'_`ks'_`wgts_name'
							`qui' count if !mi(pctb_`d'_`ks'_`wgts_name')
							if r(N) != 0 {
								`qui' svy : mean pctb_`d'_`ks'_`wgts_name' if `touse' , over(`tvar')				
								_mpitb_stores , fr(`frlev')  tvar(`tvar') l(nat) m(pctb) i(`d') sp(`name') w(`wgts_name') k(`ks') add(`m1_cont') `ts' 
							}
							// if r(N) == 0: post MV ASP
						}
					}
				}
				rpt_Nest , f(`frlev') s(national indicators)
				if ("`frcot'" != "") rpt_Nest , f(`frcot') cot s(national indicators)
			}
		}
		* subgroup
		if "`over_varlist'" != "" {
			foreach v of varlist `over_varlist' {
				
				* skip var if all missing
				`qui' count if !mi(`v')				
				if `r(N)' == 0 {
					di as txt "Note: `v' is missing for all obs. Skipping subnational analyses..."
					continue					
				}
				capture lab val `v'				// remove value label to obtain mergeable estimation output
				
				* aux
				if ustrpos("`aux'","mv") != 0 {					// missing values -- subgroup 
					* mv indicators 
					foreach d of varlist `actdepvars' {
						if ustrpos("`genauxvars'","`d'_mv") == 0 {				// why should this be the case? (09-04-2021)
							`qui' recode `d' (nonmiss=0)(mis=1) , gen(`d'_mv)
							loc genauxvars `genauxvars' `d'_mv
						}
						
						`qui' mean `d'_mv , over(`v' `tvar')		
						_mpitb_stores , fr(`frlev')  tvar(`tvar') l(`v') m(mv_uw) i(`d') sp(`name') add(`m1_cont') `ts'
					}
					* retained sample 
					`qui' mean `touse' , over(`v' `tvar') 					
					_mpitb_stores , fr(`frlev')  tvar(`tvar') l(`v') m(mv_uw) sp(`name') add(`m1_cont') `ts'
					
					if "`svy'" != "" & "`_dta[_svy_wvar]'" != "" {
						`qui' mean `touse' [aw=`_dta[_svy_wvar]'], over(`v' `tvar')					
						_mpitb_stores , fr(`frlev')  tvar(`tvar') l(`v') m(mv_w) sp(`name') add(`m1_cont') `ts'
					}
				}
				if ustrpos("`aux'","N") != 0 {
					`qui' total `touse' if `touse'  , over(`v' `tvar')
					_mpitb_stores , fr(`frlev') tvar(`tvar') l(`v') m(N) sp(`name') add(`m1_cont') `ts'
				}
				if ustrpos("`aux'","hd") != 0 {					// uncensored headcounts subgroup
					foreach d of varlist `actdepvars' {
						`qui' svy : mean `d' if `touse' , over(`v' `tvar')
						_mpitb_stores , fr(`frlev')  tvar(`tvar') l(`v') m(hd) i(`d') sp(`name') add(`m1_cont') `ts'
						if ustrpos("`cotmeasures'","hd") != 0 {
							`qui' _mpitb_estcot , fr(`frcot') tvar(`tvar') subgvar(`v') y(`cotyear') m(hd) i(`d') sp(`name') add(`m1_cont') `ts' `cotopt'
						}
					}					
				}
				* main-measures
				if "`measures'" != "" {
					forval w = 1/`Nwgts' {
						if (`Nwgts' > 1) m swgts(`w',"allwgts","cwgts","wgts_name")
					
						foreach k of numlist `over_k' {
							loc ks = strofreal(`k',"%02.0f")		// k-string 
							if ustrpos("`measures'","H") != 0 {						
								`qui' svy : mean I_`ks'_`wgts_name' if `touse' , over(`v' `tvar')							
								_mpitb_stores , fr(`frlev')  tvar(`tvar') l(`v') m(H) sp(`name') w(`wgts_name') k(`ks') add(`m1_cont') `ts'
								if ustrpos("`cotmeasures'","H") != 0 {
									`qui' _mpitb_estcot , fr(`frcot') tvar(`tvar') subgvar(`v') y(`cotyear') m(H) k(`ks') w(`wgts_name') sp(`name') add(`m1_cont') `ts' `cotopt'
								}
							}
							if ustrpos("`measures'","M0") != 0 {						
								`qui' svy : mean c_`ks'_`wgts_name' if `touse' , over(`v' `tvar')
								_mpitb_stores , fr(`frlev')  tvar(`tvar') l(`v') m(M0) sp(`name') w(`wgts_name') k(`ks') add(`m1_cont') `ts'
								if ustrpos("`cotmeasures'","M0") != 0 {
									_mpitb_estcot , fr(`frcot') tvar(`tvar') subgvar(`v') y(`cotyear') m(M0) k(`ks') w(`wgts_name') sp(`name') add(`m1_cont') `ts' `cotopt'
								}

							}
							if ustrpos("`measures'","A") != 0 {
								`qui' count if I_`ks'_`wgts_name' == 1 
								if `r(N)' > 0 {
									`qui' svy , subpop(I_`ks'_`wgts_name') : mean c_`ks'_`wgts_name' if `touse' , over(`v' `tvar')
									_mpitb_stores , fr(`frlev')  tvar(`tvar') l(`v') m(A) sp(`name') w(`wgts_name') k(`ks') add(`m1_cont') `ts'
									if ustrpos("`cotmeasures'","A") != 0 {
										`qui' _mpitb_estcot , fr(`frcot') tvar(`tvar') subgvar(`v') y(`cotyear') m(A) k(`ks') w(`wgts_name') sp(`name') add(`m1_cont') `ts' `cotopt'
									}
								}
							}
						} 
					}
					rpt_Nest , f(`frlev') s(`v')
					if ("`frcot'" != "") rpt_Nest , f(`frcot') cot s(`v' main)
				}
				* dimensionsal				
				if "`indmeasures'" != "" {
					foreach k of numlist `over_indklist' {
						loc ks = strofreal(`k',"%02.0f")		// k-string 
						foreach d of varlist `actdepvars' {
							if ustrpos("`indmeasures'","hdk") != 0 {
								`qui' svy : mean c`d'_`ks'_`wgts_name' if `touse' , over(`v' `tvar')							
								_mpitb_stores , fr(`frlev')  tvar(`tvar') l(`v') m(hdk) sp(`name') w(`wgts_name') i(`d') k(`ks') add(`m1_cont') `ts'
								if ustrpos("`cotmeasures'","H") != 0 {
									`qui' _mpitb_estcot , fr(`frcot') tvar(`tvar') subgvar(`v') y(`cotyear') m(hdk) i(`d') k(`ks') w(`wgts_name') sp(`name') add(`m1_cont') `ts' `cotopt'
								}
							}
							if ustrpos("`indmeasures'","actb") != 0 {
								`qui' svy : mean actb_`d'_`ks'_`wgts_name' if `touse' , over(`v' `tvar')
								_mpitb_stores , fr(`frlev')  tvar(`tvar') l(`v') m(actb) sp(`name') w(`wgts_name') i(`d') k(`ks') add(`m1_cont') `ts'
							}
							if ustrpos("`indmeasures'","pctb") != 0 {
								if ("`replace'" != "") cap drop pctb_`d'_`ks'_`wgts_name'_`v'
								* est res M0`ks'_`wgts_name'_`v'								
								tempvar m0group
								`qui' _wmbygrp c_`ks'_`wgts_name' if `touse' , bys(`v' `tvar') `wgt_opt' outvar(`m0group')
								`qui' gen `double' pctb_`d'_`ks'_`wgts_name'_`v' = actb_`d'_`ks'_`wgts_name' / `m0group'

								/*
								gen pctb_`d'_`ks'_`wgts_name'_`v' = .
								*gen debug_`d'_`ks'_`wgts_name'_`v' = .
								levelsof `v' 
								foreach l in `r(levels)' {
									*replace debug_`d'_`ks'_`wgts_name'_`v' = _b[`e(varlist)':`l'] if `v' == `l'
									replace pctb_`d'_`ks'_`wgts_name'_`v' = actb_`d'_`ks'_`wgts_name' / _b[`e(varlist)':`l'] if `v' == `l'
									// use bys `v' `t' egen mean ci ?
								}
								*/
								loc genvars `genvars' pctb_`d'_`ks'_`wgts_name'_`v'
								`qui' count if !mi(pctb_`d'_`ks'_`wgts_name'_`v')
								if r(N) != 0 {
									`qui' svy : mean pctb_`d'_`ks'_`wgts_name'_`v' if `touse' , over(`v' `tvar')
									_mpitb_stores , fr(`frlev')  tvar(`tvar') l(`v') m(pctb) sp(`name') w(`wgts_name') i(`d') k(`ks') add(`m1_cont') `ts'
								}
							}								
						}
					}
					rpt_Nest , f(`frlev') s(`v' indicators)
					if ("`frcot'" != "") rpt_Nest , f(`frcot') cot s(`v' indicators)
				}
				* population shares
				`qui' svy : prop `v' if `touse' , over(`tvar')
				_mpitb_stores , fr(`frlev')  tvar(`tvar') l(`v') m(popsh) sp(`name') add(`m1_cont') `ts' // prop
			} 
		} // end subgroup
		
		* remove unconfirmed numbers 
		foreach q in se ll ul {
			qui frame `frlev' : replace `q' = .a if inlist(measure,"actb","pctb","mv_w","mv_uw")
		}
		
		********************
		*** some options ***
		********************
		
		* save postid file
		if "`dtasave'" != "" {
			parse_save `dtasave'
			save `s(name)' , `s(replace)'
		} 
	
		* drop generated variables (based on list)
		if "`gen'" == "" & "`skipgen'" == "" {
			drop `genvars'
		}
		if "`gen'" != "" & "`indmeasures'" != "" {
			if ustrpos("`indmeasures'","hdk") == 0  {
				unab hdklist : cd_* 
				drop `: list genvars & hdklist'
			}
			if ustrpos("`indmeasures'","actb") == 0 {
				unab actblist : actb_* 
				drop `: list genvars & actblist'
			}
		}
		if "`genauxvars'" != "" {
			drop `genauxvars'		// always drop if created, make a switch ASP
		}
		
		* store tempes in frames or files  (08-04-2021)
		if "`lframe'" != "" {
			frame copy `frlev' `lframe'
		}
		if "`cotframe'" != "" {
			frame copy `frcot' `cotframe'
		}
		if "`lsave'" != "" {
			frame `frlev': save `lsave'
		}
		if "`cotsave'" != "" {
			frame `frcot': save `cotsave'
		}
		
		

	************************
	*** program body end ***
	************************
	
	* return
	
	* disp
	loc ri = c(linesize) - 79
	di in txt "{dlgtab 0 `ri':Result frames & files}"
	if "`estimate'" != "" {
		di _n "No results to show (option {bf:noestimate} was set). "
	}
	else {
		if "`lframe'" != "" {
			loc frname : word 1 of `lframe'
			
			prev_rfile , fr(`frname')
			
			if "`cotframe'" != "" {
				loc frname : word 1 of `cotframe'
				prev_rfile , fr(`frname')
			}
		}
		if "`lsave'" != "" {
			loc dtaname : word 1 of `lsave'
			
			prev_rfile , fi(`dtaname')
			
			if "`cotsave'" != "" {
				loc dtaname : word 1 of `cotsave'
				prev_rfile , fi(`dtaname')
			}
		}
	}
end


**# weighted mean by group				// 17-05-2021
capture program drop _wmbygrp	
program define _wmbygrp , sortpreserve	// weighted mean by group
	syntax varname [if], outvar(name) [wgt(varname) bys(varlist)]
	conf new v `outvar'
	marksample touse 
	if "`bys'" != "" {
		loc by bys `bys' (`touse') : 		// allow for empty -bys()-
	}
	else {
		sort `touse'	
	}
	if "`wgt'" == "" {
		tempvar wgt 
		gen `wgt' = 1 
	}
	tempvar num den m
	qui {
		`by' gen double `num' = sum(`wgt' * `varlist') if `touse'
		`by' gen double `den' = sum(`wgt') if `touse'
		`by' gen double `m' = `num'[_N] / `den'[_N] if `touse'
		`by' gen double `outvar' = `m'[_N] if `touse'
	}
end 

**# previewing the results file
capture program drop prev_rfile
program prev_rfile
	syntax [ , FIle(string) FRame(name)]
	
	if "`file'" != "" & "`frame'" != "" {
		di as err "Only one of option {bf:file()} and {bf:frame()} is allowed.}"
		e 197
	}
	if "`file'`frame'" == "" {
		di as err "One of option {bf:file()} and {bf:frame()} is required."
		e 197
	}
	
	loc content frame 
	loc source `frame'
	if "`file'" != "" {
		tempname frame 
		mkf `frame'
		frame `frame' : use `file' , clear
		loc content file
		loc source `file'
	}
	
	frame `frame' : loc rtype : char _dta[type]
	
	* type-specific
	if "`rtype'" == "level" {
		di _n(1) _col(3) as txt "{bf:Level `content'} (`source'): Estimates overview"
	}
	if "`rtype'" == "level-hot" {
		di _n(1) _col(3) as txt "{bf:Level `content' (HOT)} (`source'): Estimates overview"

		qui frame `frame' : levelsof t , loc(tlist)
		di _n as txt "Number of time periods: " as res `: word count `tlist''
	}
	if "`rtype'" == "changes" {
		di _n(1) _col(3) as txt "{bf:Change `content'} (`source'): Estimates overview"
		
		qui frame `frame' : levelsof t0 , loc(t0list)
		qui frame `frame' : levelsof t1 , loc(t1list)
		loc tlist : list t0list | t1list
		di _n as txt "Number of time periods: " as res `: word count `tlist''
	}
	
	* main 
	qui frame `frame': levelsof loa , loc(loalist) c 
	loc loalist : subinstr local loalist "nat" "" , word 
	if "`loalist'" != "" {
		di _n as txt "Number of subgroups:" 
		foreach s of local loalist {
			qui frame `frame': levelsof subg if loa == "`s'" , loc(slist) c
			di as txt _col(3) "`s': " _col(15) as res `: word count `slist''
		}
	}
	frame `frame' : table measure loa 
	di _n "Number of parameters:"
	foreach m in k wgts spec {
		qui frame `frame' : levelsof `m' , loc(llist) c
			di as txt _col (3) "`m': " _col(15) as res `: word count `llist'' /// 
					_col(18) as txt "(" as res"`llist'" as res")"
		}
	di _col(1) as txt "{hline 79}"

end 

**# program to report # of estimates
capture program drop rpt_Nest
program rpt_Nest
	syntax , Frame(name) [cot Stage(string)]
	
	if ("`cot'" == "") loc ftype levels 
	else loc ftype changes
	
	frame `frame' : loc Nest = _N
	di as txt "# accumulated estimates (`ftype'): " as res `Nest' as txt " ({bf:`stage'} completed)"
end 


**************
**# parser ***
**************
/*
capture program drop parse_save
program define parse_save , sclass
	syntax , file(string) [replace]
	sret loc file `file'
	sret loc replace `replace'
end
*/

capture program drop parse_frname			// 08-04-2021
program define parse_frname , sclass
	syntax name , [replace]
	if ("`replace'" == "") conf new frame `namelist'
	sret loc name `namelist'
	sret loc replace `replace'
	
end


capture program drop parse_save				// 08-04-2021
program define parse_save , sclass
	syntax anything , [replace]
	if "`replace'" == "" {
		if usubstr("`anything'",-4,4) == ".dta" {
			 conf new file `anything' 		
		}
		else {
			conf new file `anything'.dta 
		}
	} 
	sret loc name `anything'
	sret loc replace `replace'
end

capture program drop parse_over
program define parse_over , sclass
	cap noi syntax varlist , [Klist(numlist min=1 >=1 <=100 asc int) /// 
			INDKlist(numlist min=1 >=1 <=100 asc int) nooverall]
	
	if _rc != 0 {
		di as err "in {bf:over()} option" 
		e _rc
	}
	sret clear
	sret loc over_varlist `varlist'
	sret loc over_k `klist'
	sret loc over_indklist `indklist'
	sret loc overall `overall'
end

capture program drop parse_meta
program parse_meta , sclass
	syntax anything 
	token `anything' , parse("=")
	conf name `1'
	sret loc name `1'
	sret loc content `"`3'"'
end 

capture program drop parse_weights
program parse_weights, sclass
	syntax , [dimw(numlist) indw(numlist) equal all(numlist min=1 max=1 >0 <.5) name(name)]
	if ("`dimw'" != "" & "`indw'`equal'`all'" != "") | ("`indw'" != "" & "`dimw'`equal'`all'" != "") | /// 
		("`equal'" != "" & "`dimw'`indw'`all'" != "") | ("`all'" != "" & "`dimw'`equal'`indw'" != "") | ("`dimw'`equal'`indw'`all'" == "")  {
		di as err "Please choose one of dimw(), indw(), equal, or all()"			// simplier if conditions
		err 198
	}
	if "`indw'" != "" & "`name'" == "" {
		di as err "using option {bf:indw()} requires option {bf:name()}"
		err 197
	}
	sret loc dimw `dimw'
	sret loc indw `indw'
	sret loc equal `equal'
	sret loc all `all'
	sret loc name `name'
end





