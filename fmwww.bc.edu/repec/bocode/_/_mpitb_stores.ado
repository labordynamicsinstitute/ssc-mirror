*! part of -mpitb- the MPI toolbox

cap program drop _mpitb_stores
program define _mpitb_stores 	
	syntax , FRame(name) Loa(name)  Measure(name) SPec(name) /// 
		[CType(integer 0) K(numlist min=1 max=1 >=1 <=100 int) /// 
		Indicator(name) Wgts(name)  tvar(varname) add(string) ts /// 
		ann(numlist int min=1 max=1 >=0 <=1) yt0(numlist min=1 max=1) yt1(numlist min=1 max=1) ///
		t0(numlist int min=1 max=1) t1(numlist int min=1 max=1) /// 
		subg(numlist min=1 max=1)] /// only used with for actual changes (which -store_results- is called for each subgroup)

	* check: estimates available?
	if "`e(cmd)'" == "" {
		di as err "last estimates not found"
		e 301
	}
		 
	* check: estimation cmd supported? 
	if !inlist(e(cmd),"mean","lincom","nlcom","proportion","total") {
		di as err "{bf:`e(cmd)'} not supported!"
		e 198   
	}
	if "`c(cmd)'" == "proportion" & "`loa'" == "nat" {
		di as err "{bf:`e(cmd)'} together with loa = nat is not meaningful!"
		e 198
	}

	if ("`e(cmd)'" == "proportion") {
		loc prop "prop" 	// makes -prop- option obsolete
		* di "prop = `prop'"
	} 

	* check: ctype has valid values? 
	if (!inlist(`ctype',0,1,2)) {
		di as err "Unknown {bf:ctype} (`ctype')!"
		e 198
	}
	* check: ctype consistent with other options
	if `ctype' == 0 & "`yt0'`yt1'`t0'`t1'`ann'" != "" {
		di as err "Options {bf:yt0}, {bf:yt1}, {bf:t0}, {bf:t1}, {bf:ann} are not allowed for level estimates (ctype=0)."
		e 198
	}
	if inlist(`ctype',1,2) & "`tvar'" != "" {
		di as err "Option {bf:tvar} not allowed for change estimates (ctype=1,2)."
		e 198
	}
	if inlist(`ctype',1,2) & ("`yt0'" == "" | "`yt1'" == "" | "`t0'" == "" | "`t1'" == "" | "`ann'" == "") {
		di as err "Options {bf:yt0}, {bf:yt1}, {bf:t0}, {bf:t1}, {bf:ann} are required for change estimates (ctype=1,2)."
		e 198
	}
/*
	if `ctype' == 1 & "`e(cmd)'" != "lincom" {
		di as err "please estimate absolute changes using {bf:lincom}"
		err 198
	}
	if `ctype' == 2 & "`e(cmd)'" != "nlcom"  {
		di as err "please estimate relative changes using {bf:nlcom}"
		err 198
	}
*/
	frame `frame' : loc ftype : char _dta[type]							// used in several checks
	
	* check: results frame and tvar consistent? 
	if ("`ftype'" == "level-hot" & "`tvar'" == "" ) {
		di as err "Results frame requires {bf:tvar}! Add {bf:tvar()} option or recreate results frame."
		e 198
	}
	if ("`ftype'" != "level-hot" & "`tvar'" != "" ) {
		di as err "Results frame lacks {bf:tvar}! Remove {bf:tvar()} option or recreate results frame."
		e 198
	}
	
	* check: tvar and over() option of e(cmd) consistent? 
	if "`e(over)'" == "" & "`tvar'" != "" {
		di as err "{bf:tvar} is set, but {bf:`e(cmd)'} lacks {bf:over()} option." 
		e 198 
	}
	if "`e(over)'" != "" & "`tvar'" == "" & `ctype' == 0 & "`loa'" != "`e(over)'"  {
		di as err "{bf:`e(cmd)'} has {bf:over()} option. Forgot setting {bf:tvar} option?" 
		e 198 
	}
	
	* check: results frame and -ctype()- consistent for changes
	if inlist(`ctype',1,2) & "`ftype'" != "changes" {
		di as err "Tried to store change estimates, but results frame is of type -`ftype'-. Recreate results frame?"
		e 198
	}
	
	* check: results frame and timestamp option consistent?  
	frame `frame' : loc fhasts : char _dta[has_ts]
	if ("`fhasts'" == "" & "`ts'" != "" ) {
		di as err "Results frame lacks timestamps! Remove {bf:ts} option or recreate results frame."
		e 198
	}
	else if ("`fhasts'" != "" & "`ts'" == "" ) {
		di as err "Results frame requires timestamps! Add {bf:ts} option or recreate results frame."
		e 198
	} 

	
	* fill empty locals with mv to post
	foreach l in k subg {				// 	ann  		// define subg in if-sections?
		if "``l''" == "" {
			loc `l' = .			
		}
	}

	* enclose strings with (" ") if specified 
	foreach l in add {
		if "``l''" != "" {
			loc `l' ("``l''")		
		}
	}
	* enclose numerics with ( ) if specified 
	foreach l in k ann yt0 yt1 t0 t1 {								// tvar
		if "``l''" != "" {
			loc `l' (``l'')		
		}
	}
	if "`e(subpop)'" != "" {
		loc subpop & `e(subpop)'		// improve: condition may stated differently
	}
	
	* optional 
	if "`ts'" != "" {
		loc ts (`=Clock("`c(current_date)' `c(current_time)'","DMY hms")') (`=Clock("`c(filedate)'","DMY hm")')
	}
*	if ("`show'" == "") loc qui qui 
*	else if ("`show'" != "") loc qui  
	
	* check str length in rframe and adjust if needed 							(added 30/10/2022)
	foreach l in loa measure indicator spec wgts {
		frame `frame' {
			loc fvarl = substr("`: type `l''",4,.) 	// get frame var length
			loc pvall = ustrlen("``l''")			// get posted val length 
			if `pvall' > `fvarl' {
				*di "recast of `l' to `pvall' needed"	
				recast str`pvall' `l'
			}
		}
	}

	
	* declare general locals to post 
	loc str_vars ("`loa'") ("`measure'") ("`indicator'") ("`spec'") ("`wgts'")`add'
	loc byte_vars (`ctype')`ann'
	loc float_vars `k'`yt0'`yt1'`t0'`t1'
	
	loc Npost = 0				// count posted results 
	* levels (=> based on -mean-)
	if `ctype' == 0 {
		tempname rtab row_rtab
		qui _coef_table , citype(logit)
		mat `rtab' = r(table)		// store early to avoid replacement
			// mat li rtab
	
		* levels
		if "`loa'" == "nat" & "`tvar'" == "" {
			mat `row_rtab' = `rtab'[1...,"`e(varlist)'"]
			
			* declare core locals to post 
			loc tval = el(`row_rtab',rownumb(`row_rtab',"t"),1)
			foreach l in b se ll ul pvalue {
				loc `l' = el(`row_rtab',rownumb(`row_rtab',"`l'"),1)
			}
			loc double_vars (`b') (`se') (`ll') (`ul') (`pvalue') (`tval')`ts'

			frame post `frame' `double_vars' `str_vars' `float_vars' `byte_vars' (.) 		// subg always mv; tvar not to be set
			loc ++Npost
		}
		
		* levels over subgroup 
		else if "`loa'" != "nat" & "`tvar'" == ""  { 
			if "`prop'" == "" {
				loc noprop `e(varlist)'@			// modify cmd below if not -prop-
			}
			qui levelsof `loa' if e(sample) `subpop' , loc(slist)
			foreach s of loc slist {
					mat `row_rtab' = `rtab'[1...,"`noprop'`s'.`loa'"]
					
					* declare locals to post
					loc tval = el(`row_rtab',rownumb(`row_rtab',"t"),1)
					foreach l in b se ll ul pvalue {
						loc `l' = el(`row_rtab',rownumb(`row_rtab',"`l'"),1)
					}
					loc double_vars (`b') (`se') (`ll') (`ul') (`pvalue') (`tval')`ts'
				frame post `frame' `double_vars' `str_vars' `float_vars' `byte_vars' (`s')	// storing for each subgroup 
				loc ++Npost
			}
		}
		* levels over time 
		else if "`loa'" == "nat" & "`tvar'" != ""  {
			qui levelsof `tvar' if e(sample) `subpop' , loc(tlist)
			foreach t of loc tlist {
					mat `row_rtab' = `rtab'[1...,"`e(varlist)'@`t'.`tvar'"]
					
					* declare locals to post 
					loc tval = el(`row_rtab',rownumb(`row_rtab',"t"),1)
					foreach l in b se ll ul pvalue {
						loc `l' = el(`row_rtab',rownumb(`row_rtab',"`l'"),1)
					}
					loc double_vars (`b') (`se') (`ll') (`ul') (`pvalue') (`tval')`ts'
				frame post `frame' `double_vars' `str_vars' `float_vars' `byte_vars' (.) (`t')
				loc ++Npost
			}
		}
		
		* levels over time and subgroup 
		else if "`loa'" != "nat" & "`tvar'" != ""  { 
			if "`prop'" == "" {
				loc noprop `e(varlist)'@			// modify cmd below if not -prop-
			}
			qui levelsof `tvar' if e(sample) `subpop' , loc(tlist)
			qui levelsof `loa' if e(sample) `subpop', loc(slist)
			foreach t of loc tlist {
				foreach s of loc slist {
					* test for omitted coef 
					loc cnum = scalar(colnumb(e(b),"`noprop'`t'.`tvar'#`s'.`loa'"))		// col num
					loc cname : word `cnum' of `: coln(e(b))'							// actual col name
					_ms_parse_parts `cname'
					if `r(omit)' == 0 {
						mat `row_rtab' = `rtab'[1...,`cnum']
						
						* declare locals to post
						loc tval = el(`row_rtab',rownumb(`row_rtab',"t"),1)
						foreach l in b se ll ul pvalue {
							loc `l' = el(`row_rtab',rownumb(`row_rtab',"`l'"),1)
						}
						loc double_vars (`b') (`se') (`ll') (`ul') (`pvalue') (`tval')`ts'
					}
					else if `r(omit)' == 1 {
						loc double_vars (.z) (.) (.) (.) (.) (.)`ts'
					}
					frame post `frame' `double_vars' `str_vars' `float_vars' `byte_vars' (`s') (`t')
					loc ++Npost
				}
			}
		}
	}

	* absolute changes (=> based on -lincom-)
	else if `ctype' == 1 {
		loc double_vars (`r(estimate)') (`r(se)') (`r(lb)') (`r(ub)') (`r(p)') (`r(t)')`ts'
		frame post `frame' `double_vars' `str_vars' `float_vars' `byte_vars' (`subg') 
		loc ++Npost
	}	
	
	* relative changes (=> based on -nlcom-)
	else if `ctype' == 2 {
		tempname rt
		qui _coef_table 		// required in addition to -post- option
		mat `rt' = r(table)		// matrix created in inside program as -nlcom- only returns single line
		
		loc tval = el(`rt',rownumb(`rt',"z"),1)						// negligible for 30+ dof
		foreach l in collist b se ll ul pvalue {
			loc `l' = el(`rt',rownumb(`rt',"`l'"),1)
		}
		loc double_vars (`b') (`se') (`ll') (`ul') (`pvalue') (`tval')`ts'
		frame post `frame' `double_vars' `str_vars' `float_vars' `byte_vars' (`subg') 
		loc ++Npost
	}
	qui di as txt "Note: " as res `Npost' as txt " results posted to frame `frame':"
	qui frame `frame': li in `=`_N'-`Npost''/l, noob sep(0)
end 
