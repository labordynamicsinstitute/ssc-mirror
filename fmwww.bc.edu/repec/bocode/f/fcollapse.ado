*! version 2.10.0 08jun2017
program define fcollapse
	cap noi Inner `0'
	loc rc = c(rc)
	cap mata: mata drop query
	cap mata: mata drop fun_dict
	cap mata: mata drop F
	exit `rc'
end


program define Inner
	syntax [anything(equalok)] [if] [in] [fw aw pw iw/] , ///
		[by(varlist)] ///
		[FAST] ///
		[cw] ///
		[FREQ FREQvar(name)] /// -contract- feature for free
		[REGister(namelist local)] /// additional aggregation functions
		[pool(numlist integer missingok max=1 >0 min=1)] /// memory-related
		[MERGE] /// adds back collapsed vars into dataset; replaces egen
		[SMART] /// allow calls to collapse instead of fcollapse
		[Verbose] // debug info
	
	// Parse
	if ("`freq'" != "" & "`freqvar'" == "") local freqvar _freq
	if ("`pool'" == "") loc pool . // all obs together
	if ("`fast'" == "") preserve
	if ("`by'" == "") {
		tempvar byvar
		gen byte `byvar' = 1
		loc by `byvar'
	}
	loc merge = ("`merge'" != "")
	loc smart = ("`smart'" != "") & !`merge' & ("`freqvar'" == "") & ("`register'" == "") & ("`anything'" != "") & ("`by'" != "")
	loc verbose = ("`verbose'" != "")

	if (`smart') {
		gettoken first_by _ : by
		loc ok = strpos("`: sortedby'", "`first_by'") == 1
		if (!`ok' & c(N)>1) {
			tempvar notok
			gen byte `notok' = `first_by' < `first_by'[_n-1]
			cou if `notok' in 2/`c(N)'
			loc ok = r(N)==0
			drop `notok'
		}
		if (`ok') {
			if (`verbose') di as text "data already sorted; calling -collapse- due to -smart- option"
			if ("`weight'" != "") loc eqsign =
			collapse `anything' `if' `in' [`weight'`eqsign'`exp'] , by(`by') `fast' `cw'
			exit
		}
	}

	if ("`anything'" == "") {
		if ("`freqvar'"=="") {
			di as error "need at least a varlist or a freq. option"
			error 110
		}
	}
	else {
		ParseList `anything', merge(`merge') // modify `targets' `keepvars'
	}

	loc valid_stats mean median sum count percent max min ///
		iqr first last firstnm lastnm sd
	loc invalid_stats : list stats - valid_stats
	loc invalid_stats : list invalid_stats - register
	foreach stat of local invalid_stats {
		if !(regexm("`stat'", "^p[0-9]+$")) {
			di as error "Invalid stat: (`stat')"
			error 110
		}
	}

	// Check dependencies
	cap qui mata: mata which _mm_quantile()
	loc rc = c(rc)
	if (`rc') {
		di as error "SSC Package Moremata required (to compute quantiles)"
		di as smcl "{err}To install: {stata ssc install moremata}"
		error `rc'
	}

	loc interserction : list targets & by
	if ("`intersection'" != "") {
		di as error "targets in collapse are also in by(): `intersection'"
		error 110
	}
	loc interserction : list targets & freqvar
	if ("`intersection'" != "") {
		di as error "targets in collapse are also in freq(): `intersection'"
		error 110
	}

	// Trim data
	loc need_touse = ("`if'`in'"!="" | "`cw'"!="")
	if (`need_touse') {
		marksample touse, strok novarlist
		if ("`cw'" != "") {
			markout `touse' `keepvars', strok
		}
	
		if (!`merge') {
			qui keep if `touse'
			drop `touse'
			loc touse
		}
	}

	// Create factor structure
	mata: F = factor("`by'", "`touse'", `verbose')

	// Trim again
	// (saves memory but is slow for big datasets)
	if (!`merge' & `pool' < .) keep `keepvars' `exp'

	// Get list of aggregating functions
	mata: fun_dict = aggregate_get_funs()
	if ("`register'" != "") {
		foreach fun of local register {
			mata: asarray(fun_dict, "`fun'", &aggregate_`fun'())
		}
	}

	// Main loop: collapses data
	if ("`anything'" != "") {
		mata: f_collapse(F, fun_dict, query, "`keepvars'", `merge', `pool', "`exp'", "`weight'")
	}
	else {
		clear
		mata: F.store_keys(1)
	}

	// Add frequencies (already stored in -F-)
	if ("`freqvar'" != "") {
		mata: st_local("maxfreq", strofreal(max(F.counts)))
		loc freqtype long
		if (`maxfreq' <= 32740) loc freqtype int
		if (`maxfreq' <= 100) loc freqtype byte
		if (`merge') {
			mata: st_store(., st_addvar("`freqtype'", "`freqvar'", 1), F.counts[F.levels])
		}
		else {
			mata: st_store(., st_addvar("`freqtype'", "`freqvar'", 1), F.counts)
		}
		la var `freqvar' "Frequency"
	}

	if (!`merge') order `by' `targets'
	if ("`fast'" == "") restore, not
end


program define ParseList
	syntax [anything(equalok)] , MERGE(integer)
	TrimSpaces 0 : `anything'

	loc stat mean // default
	mata: query = asarray_create("string") // query[var] -> [stat, target]
	mata: asarray_notfound(query, J(0, 2, ""))

	while ("`0'" != "") {
		GetStat stat 0 : `0'
		GetTarget target 0 : `0'
		gettoken vars 0 : 0
		unab vars : `vars'
		foreach var of local vars {
			if ("`target'" == "") {
				if (`merge') {
					loc target `stat'_`var'
				}
				else {
					loc target `var'
				}
			}
			loc targets `targets' `target'
			loc keepvars `keepvars' `var'
			loc stats `stats' `stat'
			mata: asarray(query, "`var'", asarray(query, "`var'") \ ("`target'", "`stat'"))
			loc target
		}
	}

	// Check that targets don't repeat
	loc dups : list dups targets
	if ("`dups'" != "") {
		cap mata: mata drop query
		di as error "repeated targets in collapse: `dups'"
		error 110
	}

	loc keepvars : list uniq keepvars
	loc stats : list uniq stats
	c_local targets `targets'
	c_local stats `stats'
	c_local keepvars `keepvars'
end


program define TrimSpaces
	_on_colon_parse `0'
	loc lhs `s(before)'
	loc rest `s(after)'
	
	* Trim spaces around equal signs ("= ", " =", "  =   ", etc)
	loc old_n .b
	loc n .a
	while (`n' < `old_n') {
		loc rest : subinstr loc rest "  " " ", all
		loc old_n `n'
		loc n : length local rest
	}
	loc rest : subinstr loc rest " =" "=", all
	loc rest : subinstr loc rest "= " "=", all
	c_local `lhs' `rest'
end


program define GetStat
	_on_colon_parse `0'
	loc before `s(before)'
	gettoken lhs rhs : before
	loc rest `s(after)'

	gettoken stat rest : rest , match(parens)
	if ("`parens'" != "") {
		c_local `lhs' `stat'
		c_local `rhs' `rest'
	}
end


program define GetTarget
	_on_colon_parse `0'
	loc before `s(before)'
	gettoken lhs rhs : before
	loc rest `s(after)'

	loc rest : subinstr loc rest "=" "= ", all
	gettoken target rest : rest, parse("= ")
	gettoken eqsign rest : rest
	if ("`eqsign'" == "=") {
		c_local `lhs' `target'
		c_local `rhs' `rest'
	}
end


ftools, check
findfile "ftools_type_aliases.mata"
include "`r(fn)'"
findfile "fcollapse_main.mata"
include "`r(fn)'"
exit
