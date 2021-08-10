*! version 1.4.0 16jun2017 daniel klein
program kappaetc , byable(onecall)
	version 11.2
	
	if (replay()) {
		if (_by()) {
			error 190
		}
		kappaetc_display `0'
		exit 0
	}
	
	if (_by()) {
		local By by `_byvars' `_byrc0' :
	}
	
	`By' kappaetc_get_cmd2 `0'
	
	`By' kappaetc_cmd_`cmd2' `0'
end

/*
	command switcher */
	
program kappaetc_get_cmd2 , byable(onecall) // noby
	version 11.2
	
	local zero : copy local 0
	gettoken anything 0 : 0 , parse(",")
	syntax 				///
	[ , 				///
		TTEST 	/// ignored
		REPLAY 			/// not documented
		RESTORE 		/// not documented
		ICC(passthru) 	///
		* 				///
	]
	
	if (`"`icc'"' != "") {
		local cmd2 icc
	}
	else {
		local 0 : copy local zero
		gettoken name1 0 : 0 , parse(" =")
		gettoken equal 0 : 0 , parse(" =")
		if inlist(`"`equal'"', "=", "==") {
			local zero `name1' `0'
			local cmd2 ttest
		}
		else if ("`replay'`restore'" != "") {
			local cmd2 replay
		}
		else {
			local cmd2 cac
		}
	}
	
	if (_by() & inlist(`"`cmd2'"', "ttest", "replay", "restore")) {
		error 190
	}
	
	c_local 0 		: copy local zero
	c_local cmd2 	: copy local cmd2
end

/*
	chance-corrected agreement coefficients (cac) */
	
program kappaetc_cmd_cac , byable(recall)
	version 11.2
	
	syntax varlist(min = 2 numeric) 					///
	[ if ] [ in ] [ fweight iweight ] 					///
	[ , 												///
		Wgt(string) 									///
		SE(passthru) 									///
		CASEWISE 										///
		FREquency 										///
		CATegories(passthru) 							///
		DFmat(name) 									///
		NSUBJECTS(numlist integer missingok max = 1 >0) ///
		NRATERS(numlist integer missingok max = 1 >0) 	///
		STOre(name) 									///
		* 								/// display options
	]
	
	if (("`store'" != "") & _by()) {
		error 190
	}
	
	local varlist : list uniq varlist
	if (mi("`casewise'") | ("`frequency'" != "")) {
		local novarlist novarlist
	}
	marksample touse , `novarlist'
	
	tempvar weightvar
	if ("`weight'" != "") {
		local weight_exp [`weight' `exp']
	}
	kappaetc_get_weight `weightvar' `weight_exp'
	
	kappaetc_get_di_opts cac , `options'
	
	kappaetc_get_wgt_opt `wgt'
	
	kappaetc_get_se_opt , `se' `frequency'
	
	kappaetc_get_cat_opt `varlist' , `categories' `frequency'
	
	kappaetc_get_df_opt `dfmat' , error(`largesample')
	
	mata : kappaetc_ado()
	
	kappaetc_display , `options'
	
	if ("`store'" != "") {
		nobreak {
			capture _return drop `store'
			_return hold `store'
			_return restore `store' , hold
		}
	}
end

program kappaetc_get_weight
	version 11.2
	
	syntax newvarname [ fweight iweight ]
	
	if mi("`weight'") {
		local exp "= 1"
	}
	
	quietly generate double `varlist' `exp'
	
	if ("`weight'" != "fweight") {
		exit 0
	}
	
	if (c(stata_version) > 11.2) {
		local fast , fast
	}
	
	capture assert `varlist' == int(`varlist') `fast'
	if (_rc) {
		error 401
	}
	
	capture assert `varlist' >= 0 `fast'
	if (_rc) {
		error 402
	}
end

program kappaetc_get_wgt_opt
	version 11.2
	
	syntax [ anything ] [ , KAPwgt MATrix * ]
	local suboptions : copy local options
	
	gettoken anything void : anything , bind match(lpar) qed(syntaxerr)
	if ((`"`void'"' != "") | ("`lpar'" != "") | (`syntaxerr')) {
		display as err "option wgt() invalid"
		exit 198
	}
	
	if ("`kapwgt'`matrix'" != "") {
		if (("`kapwgt'" != "") & ("`matrix'" != "")) {
			local errmsg "; only one of kapwgt or matrix is allowed"
		}
		if (mi(`"`anything'"') | ("`errmsg'" != "")) {
			display as err "option wgt() invalid`errmsg'"
			exit 198
		}
		local userwgt : copy local anything
	}
	else {
		if mi(`"`anything'"') {
			local anything identity // default
		}
		
		local 0 , `anything'
		syntax 				///
		[ , 				///
			Identity 		///
			Ordinal 		///
			Linear 			///
			Quadratic 		///
			RADical 		///
			Ratio 			///
			Circular 		///
			Bipolar 		///
			Power(passthru) ///
			W 				/// synonym linear , noabsolute
			W2 				/// synonym quadratic , noabsolute
			* 				/// user weights 
		]
		local userwgt : copy local options
		
		if (`"`power'"' != "") {
			local 0 , `power'
			capture noisily syntax , POWER(numlist max = 1 >=0)
			if (_rc) {
				display as err "invalid suboption in option wgt()"
				exit 198
			}
			local raise : copy local power
			local power power
		}
		
		local wgt 	///
		`identity' 	///
		`ordinal' 	///
		`linear' 	///
		`quadratic' ///
		`radical' 	///
		`ratio' 	///
		`circular' 	///
		`bipolar' 	///
		`power' 	///
		`w' 		///
		`w2' 		///
		`userwgt'
		
		if (inlist(`"`wgt'"', "w", "w2")) {
			if (`"`wgt'"' == "w") {
				local wgt linear
			}
			else {
				local wgt quadratic
			}
			local suboptions `suboptions' noabsolute
		}
		
		if ("`wgt'" == "ordinal") {
			local KRIPPENdorff KRIPPENdorff
		}
		else if inlist("`wgt'", "linear", "quadratic", "radical", "ratio") {
			local noAbsolute noAbsolute
		}
		else if ("`wgt'" == "circular") {
			local SINE SINE(string)
			local U U(numlist max = 1 >= 0 < 1)
			local noAbsolute noAbsolute
		}
		else if ("`wgt'" == "power") {
			local noAbsolute noAbsolute
		}
	}
	
	if ("`userwgt'" != "") {
		local Indices Indices(numlist ascending integer min = 2 > 0)
		local FORCEwgt FORCEwgt
	}
	
	if (`"`suboptions'"' != "") {
		local 0 , `suboptions'
		capture noisily syntax 	///
		[ , 					///
			`KRIPPENdorff' 		///
			`noAbsolute' 		///
			`SINE' 				///
			`U' 				///
			`Indices' 			///
			`FORCEwgt' 			///
		]
		
		local rc = _rc
		
		if (!`rc') {
			local rc 198
			if (`"`sine'"' != "") {
				if !inlist(`"`sine'"', "pi", "180") {
					display as err `"`invalid `sine''"'
				}
				else if ("`u'" != "") {
					display as err "only one of sine() or u() allowed"
				}
				else {
					local rc 0
				}
			}
			else if (("`u'" != "") & mi("`absolute'")) {
				display as err "suboption noabsolute required with u()"
			}
			else {
				local rc 0
			}
		}
		
		if (`rc') {
			display as err "invalid suboption in option wgt()"
			exit 198
		}
		
		if (("`indices'" != "") & mi("`forcewgt'")) {
			display as err "option indices() not allowed"
			display as err "invalid suboption in option wgt()"
			display as err _n "{p 4 4 2}"
			display as err "You probably specified indices() because not " ///
			"all of the predetermined rating categories were observed in " ///
			"the data. Extracting the submatrix of weights corresponding " ///
			"to the observed ratings leads to inaccurate coefficients if " ///
			"the expected proportion of agreement is based on the number " ///
			"of rating categories. Consider specifying all predetermined " ///
			"rating categories in {help kappaetc##opt_cat:{bf:categories()}}"
			display as err "{p_end}"
			display as err _n "{p 4 4 2}"
			display as err "If you had another reason for specifying the " ///
			"indices() suboption and you wish to proceed anyway, specify " ///
			"{bf:wgt(`userwgt' , `kapwgt'`matrix' indices(`indices') force)}"
			display as err "{p_end}"
			exit 198
		}
	}
	
	if ("`userwgt'" != "") {
		kappaetc_get_wgt_opt_user `userwgt' , `kapwgt' `matrix'
	}
	
	c_local wgt 			: copy local wgt
	c_local wgttype 		: copy local wgttype
	c_local krippendorff 	: copy local krippendorff
	c_local absolute 		: copy local absolute
	c_local sine 			: copy local sine
	c_local U 				: copy local u
	c_local raise 			: copy local raise
	c_local indices 		: copy local indices
end

program kappaetc_get_wgt_opt_user
	version 11.2
	
	syntax anything(name = wgt) [ , KAPWGT MATRIX ]
	
	if mi("`matrix'") {
		capture local w : copy global `wgt'
		gettoken KAPWGT w : w
		if ("`KAPWGT'" == "kapwgt") {
			gettoken dim w : w
			if (`: word count `w'' != `dim'*(`dim'+1)/2) {
				display as err "`wgt' not `dim' x `dim'"
				exit 498
			}
			local wgttype kapwgt
		}
		else {
			if ("`kapwgt'" != "") {
				display as err "kapwgt `wgt' not found"
				exit 111
			}
			local matrix matrix
		}
	}
	
	if ("`matrix'" != "") {
		confirm matrix `wgt'
		local wgttype matrix
	}
	
	c_local wgt 	: copy local wgt
	c_local wgttype : copy local wgttype
end

program kappaetc_get_se_opt
	version 11.2
	
	syntax 				///
	[ , 				///
		SE(string asis) ///
		FREquency 		///
	]
	
	gettoken se void : se , qed(syntaxerr)
	if ((`"`void'"' != "") | (`syntaxerr')) {
		display as err "option se() invalid"
		exit 198
	}
	
	if mi("`se'") {
		local se conditional
	}
	else {
		local 0 , `se'
		capture syntax 		///
		[ , 				///
			CONDitional 	///
			JACKknife 		///
			JKNIFE 			/// not documented
			UNCONDitional 	///
		]
		
		if (_rc) {
			display as err "option se() invalid"
			exit 198
		}
		
		if ("`jknife'" != "") {
			local jackknife jackknife
		}
		
		local se `conditional'`jackknife'`unconditional'
		
		if (("`frequency'" != "") & ("`se'" != "conditional")) {
			display as err "option se() invalid; " ///
			"`se' standard errors are not available for rating frequencies"
			exit 198
		}
	}
	
	c_local se : copy local se
end

program kappaetc_get_cat_opt
	version 11.2
	
	syntax varlist 				///
	[ , 						///
		CATegories(passthru) 	///
		FREquency 				///
	]
	
	local nvar : word count `varlist'
	
	local 0 , `categories'
	capture syntax [ , CATegories(numlist missingokay) ]
	if (_rc) {
		if mi("`frequency'") {
			syntax , CATegories(string asis)
			gettoken float : categories , parse("(") quotes
			if (`"`float'"' == "float") {
				gettoken float categories : categories , parse("(")
				gettoken categories void : categories , match(opar)
				if (mi(`"`categories'"') | (strtrim(`"`void'"') != "")) {
					local categories invalid_numlist
				}
				local 0 , categories(`categories')
			}
		}
		syntax , CATegories(numlist missingokay)
	}
	
	if ("`categories'" != "") {
		local dup : list dups categories
		if ("`dup'" != "") {
			display as err "categories() invalid " ///
			"-- invalid numlist has repeated values"
			exit 121
		}
		
		if ("`frequency'" != "") {
			local ncat : word count `categories'
			if (`ncat' != `nvar') {
				local rc = 122 + (`ncat' > `nvar')
				display as err "categories() invalid -- " _continue
				error `rc' 
			}
		}
	}
	
	c_local categories 	: copy local categories
	c_local float 		: copy local float
end

program kappaetc_get_df_opt
	version 11.2
	
	syntax [ name(name = dfmat) ] , ERROR(integer)
	
	if mi("`dfmat'") {
		exit 0
	}
	else if (`error') {
		display as err "option dfmat() may not be combined with largesample"
		exit 198
	}
	
	capture noisily confirm matrix `dfmat'
	if (_rc) {
		display as err "option df() invalid"
		exit 198
	}
	
	local rows = rowsof(`dfmat')
	local cols = colsof(`dfmat')
	
	if ((`rows' != 1) | (`cols' != 6)) {
		if ((`rows' != 6) | (`cols' != 1)) {
			display as err "option df() invalid"
			display as err "1 x 6 or 6 x 1 vector required"
			display as err "`dfmat' is `rows' x `cols'"
			err 498
		}
	}
	
	local bad = 504 * matmissing(`dfmat')
	if (!`bad') {
		mata : st_local("bad", strofreal(any(st_matrix("`dfmat'"):<1)))
		local bad = `bad' * 498
	}
	
	if (`bad') {
		display as err "option df() invalid"
		display as err "`dfmat' has invalid values"
		exit `bad'
	}
	
	c_local dfmat `dfmat'
end

/*
	paired t-tests (ttest) */
	
program kappaetc_cmd_ttest
	version 11.2
	
	syntax namelist(min = 2 max = 2) 	///
	[ , 								///
		TTEST 					/// ignored
		TOLERANCE(real 1e-14) 			/// not documented
		* 				/// display options
	]
	
	gettoken name1 namelist : namelist
	gettoken name2 namelist : namelist
	
	kappaetc_get_di_opts ttest , `options'
		
	tempname rresults
	
	nobreak {
		forvalues j = 1/2 {
			_return hold `rresults'
			_return restore `rresults' , hold
			quietly kappaetc_cmd_replay `name`j'' , restore
			if ("`r(weight_i)'" == "matrix") {
				local weight_i weight_i
			}
			else {
				local weight_i // void
			}
			local matnames b_istar `weight_i' df b W categories
			capture noisily {
				foreach mat of local matnames {
					confirm matrix r(`mat')
					tempname `mat'`j'
					matrix ``mat'`j'' = r(`mat')
				}
			}
			local rc = _rc
			if ((!`rc') & ("`r(dfmat)'" != "")) {
				display as err "not possible " ///
				"with user defined degrees of freedom"
				local rc 498
			}
			if ((!`rc') & ("`r(setype)'" != "conditional")) {
				display as err "not appropriate " /// 
				"with `r(setype)' standard errors"
				local rc 498
			}
			_return restore `rresults'
			capture _return drop `rresults'
			if (`rc') {
				exit `rc'
			}
		}
	}
	
	mata : kappaetc_ttest_ado()
	
	kappaetc_display , `options'
end

/*
	replay or restore results */
	
program kappaetc_cmd_replay
	version 11.2
	
	syntax namelist ///
	[ , 			///
		REPLAY 		///
		RESTORE 	///
		* 			///
	]
	
	if mi("`replay'`restore'") {
		display as err "one of replay or restore must be specified"
		exit 198
	}
	else if ("`restore'" != "") {
		if (`: word count `namelist'' > 1) {
			display as err "too many names specified"
			exit 103
		}
	}
	
	tempname rresults
	
	nobreak {
		_return hold `rresults'
		foreach name of local namelist {
			capture _return restore `name' , hold
			if ((_rc) | ("`r(cmd)'" != "kappaetc")) {
				_return restore `rresults'
				display as err "results `namelist' not found"
				exit 111
			}
			else if ("`replay'" != "") {
				display as txt "{hline 79}"
				display as txt "Results " as res "`name`j''" 
				display as txt "{hline 79}"
				capture noisily break kappaetc_display , `options'
				if (_rc) {
					_return restore `rresults'
					exit _rc
				}
			}
		}
		
		if mi("`restore'") {
			_return restore `rresults'
			exit 0
		}
		
		capture _return drop `rresults'
		display as txt "(results {stata kappaetc:`namelist'} are active now)"
	}
end

/*
	intraclass correlation coefficients (icc) */
	
program kappaetc_cmd_icc , byable(onecall)
	version 11.2
	
	display as err "option icc() is not yet implemented"
	exit 198
end

/*
	display results */
	
program kappaetc_display
	version 11.2
	
	if ("`r(cmd)'" != "kappaetc") {
		display as err "last command not kappaetc"
		exit 301
	}
	
	syntax [ , * ]
	kappaetc_get_di_opts `r(cmd2)' , `options'
	
	mata : kappaetc_di_set_rtable()
	mata : kappaetc_di_set_benchmark()
	
	if (("`r(cmd2)'" == "ttest") & ("`replay'" != "")) {
		kappaetc_cmd_replay `r(results1)' `r(results2)' , `options'
	}
	
	if mi("`noheader'") {
		kappaetc_display_header_`r(cmd2)'
	}
	
	if mi("`notable'") {
		kappaetc_display_table , `options'
	}
	
	if (("`showscale'" != "") & ("`benchmark_method'" != "")) {
		kappaetc_display_benchmark ///
			`cformat' (`benchmark_scale') (`benchmark_label')
	}
	
	if ("`showweights'" != "") {
		display
		display as txt "Weighting matrix (`r(wgt)' weights)" _continue
		matlist r(W) , format(%5.4f) nonames nohalf left(2)
	}
end

program kappaetc_display_header_
	version 11.2
	
	display
	display as txt "Interrater agreement" _continue
	display as txt %48s "Number of subjects"  			" = " 	///
		as res %7.0f r(N)
	if ("`r(wgt)'" != "identity") {
		display as txt "(weighted analysis)" _continue
		local pos 49
	}
	else {
		local pos 68
	}
	if (r(r_min) != r(r_max)) {
		local cmin ": min"
		local rval r(r_min)
	}
	else {
		local rval r(r_max)
	}
	display as txt %`pos's "Ratings per subject`cmin'" 	" = " 	///
		as res %7.0g `rval'
	if (r(r_min) != r(r_max)) {
		display as txt %68s "avg" 						" = " 	///
			as res %7.0g r(r_avg)
		display as txt %68s "max" 						" = " 	///
			as res %7.0g r(r_max)
	}
	display as txt %68s "Number of rating categories" 	" = " 	///
		as res %7.0f `= rowsof(r(categories))'
end

program kappaetc_display_header_ttest
	version 11.2
	
	local name1 = abbrev(r(results1), 31)
	local name2 = abbrev(r(results2), 31)
	local len12 = strlen("`name1'`name2'")
	local cdiff = min(58, (78 - (15 + `len12')))
	
	local name1 {stata kappaetc `r(results1)' , replay:{res:`name1'}}
	local name2 {stata kappaetc `r(results2)' , replay:{res:`name2'}}
	
	display
	display as txt "Paired t tests of agreement coefficients" _continue
	display as txt %28s "Number of subjects"  			" = " 	///
		as res %7.0f r(N)
	display as txt _col(`cdiff') "Differences " 				///
		_skip(`= 5 - `len12'') 									///
		as txt "(" as res "`name1'" as txt ")" 					///
		as txt "-" 												///
		as txt "(" as res "`name2'" as txt ")"
end

program kappaetc_display_table
	version 11.2
	
	syntax [ , * ]
	kappaetc_get_di_opts `r(cmd2)' , `options'
	
	local levlen = strlen("`level'")
	if (`levlen' < 5) {
		local ispace " "
	}
	
	if ("`relop'" == ">") {
		local invrelop "<"
	}
	else {
		local invrelop ">"
	}
	
	if mi("`r(cmd2)'") {
		local cname Coef.
	}
	else if ("`r(cmd2)'" == "ttest") {
		local cname Diff.
	}
	else {
		mata : kappaetc_error("display_table", 0)
	}
	
	if ("`benchmark_method'" != "") {
		local rtable table_benchmark
		if ("`benchmark_method'" == "probabilistic") {
			local rtable `rtable'_prob
			local pname ">`ispace'`level'%"
		}
		else if ("`benchmark_method'" == "deterministic") {
			local rtable `rtable'_det
			local pname "P cum."
		}
		else {
			mata : kappaetc_error("display_table", 0)
		}
		local ttcol 44
		local tname "P in."
		local tpcol 52
		local ticol 60
		local iname [Benchmark Interval]
		local xformat : copy local pformat
		local _continue _continue
	}
	else {
		local rtable table
		local tname : word 3 of `: rownames r(table)'
		local ttcol 47
		if ("`relop'" != "") {
			local tpcol 53
			local abs_bar // void
		}
		else {
			local tpcol 52
			local abs_bar "|"
		}
		local pname P`invrelop'`abs_bar'`tname'`abs_bar'
		local ticol = 62 - min(4, max(2, `levlen'))
		local iname [`level'% Conf.`ispace'Interval]
		local xformat : copy local sformat
	}
	
	confirm matrix r(`rtable')
	
	tempname table
	matrix `table' = r(`rtable')
	
	local cols = colsof(`table')
	mata : st_local("names", ///
	invtokens(st_matrixcolstripe("`table'")[., 2]' :+ ";"))
	
	local c1 _col(22)
	local c2 _col(23)
	local c3 _col(33)
	local c4 _col(`= 43 + ("`benchmark_method'" != "")')
	local c5 _col(52)
	local c6 _col(61)
	local c7 _col(71)
	
	display as txt "{hline 21}{c TT}{hline 57}"
	if (mi("`r(cmd2)'") & ///
	(("`r(setype)'" != "conditional") | ("`benchmark_method'" != ""))) {
		display as txt `c1' "{c |}" _continue
		if ("`r(setype)'" != "conditional") {
			if ("`r(setype)'" == "jackknife") {
				local _colse _col(33)
			}
			else if ("`r(setype)'" == "unconditional") {
				local _colse _col(31)
			}
			else {
				mata : kappaetc_error("display_table", 0)
			}
			display as txt `_colse' strproper(r(setype)) `_continue'
		}	
		if ("`benchmark_method'" != "") {
			if ("`benchmark_method'" == "probabilistic") {
				display as txt _col(52) "P cum." _continue
			}
			display as txt _col(`= `ticol' + 3') ///
				strproper("`benchmark_method'")
		}
	}
	display 							///
		as txt `c1' "{c |}" 			///
		as txt _col(26) "`cname'" 		///
		as txt _col(33) "Std. Err." 	///
		as txt _col(`ttcol') "`tname'" 	///
		as txt _col(`tpcol') "`pname'" 		///
		as txt _col(`ticol') "`iname'"
	display as txt "{hline 21}{c +}{hline 57}"
	forvalues j = 1/`cols' {
		gettoken name names : names , parse(";")
		gettoken semi names : names , parse(";")
		display 									///
			as txt "`name'" `c1' "{c |}" 			///
			as res `c2' `cformat' `table'[1, `j'] 	///
			as res `c3' `cformat' `table'[2, `j'] 	///
			as res `c4' `xformat' `table'[3, `j'] 	///
			as res `c5' `pformat' `table'[4, `j']	///
			as res `c6' `cformat' `table'[5, `j'] 	///
			as res `c7' `cformat' `table'[6, `j']
	}
	display as txt "{hline 21}{c BT}{hline 57}"
	
	if (mi("`r(cmd2)'")) {
		if (((`testvalue') | ("`relop'" != "")) & mi("`benchmark_method'")) {
			if mi("`relop'") {
				local invrelop "!="
			}
			display as txt _col(`= 4 - strlen("`relop'")') "`tname' test " ///
				"Ho: Coef. `relop'= " `cformat' `testvalue' ///
				_col(35) "Ha: Coef. `invrelop' " `cformat' `testvalue'	
		}
		if (("`r(setype)'" != "conditional") & (r(jk_miss))) {
			if (r(jk_miss) > 1) {
				local s s
			}
			display as txt "Note: `r(jk_miss)' coefficient`s' " ///
			"could not be estimated in jackknife replicates"
		}
	}
end

program kappaetc_display_benchmark
	version 11.2
	
	gettoken cformat 0 : 0
	gettoken benchmark_scale 0 : 0 , match(par)
	gettoken benchmark_label 0 : 0 , match(par)
	
	local lcformat : copy local cformat
	local rcformat : subinstr local cformat "%" "%-"
	
	display
	display as txt %17s "Benchmark scale"
	
	display
	local J : word count `benchmark_scale'
	local ul : word 1 of `benchmark_scale'
	local ul : display `rcformat' `ul'
	mata : st_local("ll", char(32)*strlen(st_local("ul")))
	local label : word 1 of `benchmark_label'
	display as txt %9s "`ll'" "<" "`ul'" _col(23) `"`label'"'
	forvalues j = 1/`--J' {
		local ll : word `j' of `benchmark_scale'
		local ul : word `= `j'+1' of `benchmark_scale'
		local ll : display `lcformat' `ll'
		local ul : display `rcformat' `ul'
		local label : word `= `j' + 1' of `benchmark_label'
		display as txt %9s "`ll'" "-" "`ul'" _col(23) `"`label'"'
	}
end	

/*
	parse display options */

program kappaetc_get_di_opts
	version 11.2
	
	syntax [ name(name = cmd2) ] 	///
	[ , 							///
		Level(cilevel) 				///
		noHeader 					///
		noTABle 					///
		CFORMAT(string) 			///
		PFORMAT(string) 			///
		SFORMAT(string) 			///
		* 	/// cmd2 specific reporting
	]
	
	if inlist("`cmd2'", "", "cac") {
		local DIOPTS 				///
			SHOWWeights 			///
			BENCHmark42 			///
			BENCHmark(string asis) 	///
			SHOWScale 				///
			LARGESAMPLE 			///
			TESTVALue(passthru)
	}
	else if ("`cmd2'" == "ttest") {
		local DIOPTS 				///
			TTEST 			/// ignored
			REPLAY
			
	}
	else if ("`cmd2'" == "icc") {
		local DIOPTS 				///
			ICC 			/// ignored
			TESTVALue(real 0)
	}
	
	local 0 , `options'
	syntax 	[ , `DIOPTS' ]
	
	local cfmt %8.4f
	local pfmt %5.3f
	local sfmt %6.2f
	
	foreach fmt in c p s {
		if ("``fmt'format'" != "") {
			confirm numeric format ``fmt'format'
			local `fmt'format : subinstr local `fmt'format "-" ""
			gettoken p `fmt'format : `fmt'format , parse("%")
			gettoken w `fmt'format : `fmt'format , parse(".")
			local totwidth = abs(`w')
			local maxwidth = real(substr("``fmt'fmt'", 2, 1))
			if (`totwidth' > `maxwidth') {
				display as err "option `fmt'format() invalid"
				display as err "width too large"
				exit 198
			}
			local `fmt'format `p'`w'``fmt'format'
		}
		else {
			local `fmt'format ``fmt'fmt'
		}
	}
	
	if (`"`benchmark42'`benchmark'"' != "") {
		kappaetc_get_di_opts_bench_opt , `benchmark'
	}
	
	local largesample = ("`largesample'" != "")
	
	kappaetc_get_di_opts_testval , `testvalue'
	
	c_local level 				: copy local level
	c_local noheader 			: copy local header
	c_local notable 			: copy local table
	c_local cformat 			: copy local cformat
	c_local pformat 			: copy local pformat
	c_local sformat 			: copy local sformat
	c_local showweights 		: copy local showweights
	c_local benchmark_method 	: copy local benchmark_method
	c_local benchmark_scale 	: copy local benchmark_scale
	c_local benchmark_label 	: copy local benchmark_label
	c_local showscale 			: copy local showscale
	c_local largesample 		: copy local largesample
	c_local replay 				: copy local replay
	c_local testvalue 			: copy local testvalue
	c_local relop 				: copy local relop
end

program kappaetc_get_di_opts_bench_opt
	version 11.2
	
	capture syntax 			///
	[ , 					///
		Probabilistic 		///
		Deterministic 		///
		Scale(string) 		///
		LABEL(string asis) 	/// not documented
	]
	
	if (_rc) {
		display as err "option benchmark() invalid"
		exit 198
	}
	
	if mi("`probabilistic'`deterministic'") {
		local probabilistic probabilistic
	}
	else if (("`probabilistic'" != "") & ("`deterministic'" != "")) {
		display as err "option benchmark() invalid; " ///
		"only one of probabilistic or deterministic is allowed"
		exit 198
	}
	
	if mi("`scale'") {
		local scale landis koch
	}
	
	local 0 , `scale'
	capture syntax 	///
	[ , 			///
		LANDIS 		///
		KOCH 		///
		FLEISS 		///
		ALTMAN 		///
	]
	
	if (_rc) {
		local 0 , scale(`scale')
		capture noisily syntax , scale(numlist ascending >=0 <=1)
		local rc = _rc
		if (!`rc') {
			if (`: word `: word count `scale'' of `scale'' < 1) {
				local scale `scale' 1
			}
			if (`: word count `scale'' < 2) {
				local rc 122
			}
		}
		if (`rc') {
			display as err "option benchmark() invalid"
			exit `rc'
		}
	}
	else {
		local n : word count `landis'`koch' `fleiss' `altman'
		if (`n' > 1) {
			display as err "option benchmark() invalid; " ///
			"only one of landis/koch, fleiss or altman allowed"
			exit 198
		}
		if ("`landis'`koch'" != "") {
			local scale 0 .2 .4 .6 .8 1
			local scalelabel ///
			`"Poor Slight Fair Moderate Subtantial "Almost Perfect""'
		}
		else if ("`fleiss'" != "") {
			local scale .4 .75 1
			local scalelabel `"Poor "Intermediate to Good" Excellent"'
		}
		else if ("`altman'" != "") {
			local scale .2 .4 .6 .8 1
			local scalelabel `"Poor Fair Moderate Good "Very Good""'
		}
		else {
			mata : kappaetc_error("get_di_bench_opt", 0)
		}
	}
	
	if (`"`label'"' != "") {
		if ((`: word count `label'') != (`: word count `scale'')) {
			display as err "option benchmark() invalid; " ///
			"number of labels does not match number of benchmarks"
			exit 198
		}
		local scalelabel : copy local label
	}
	
	c_local benchmark_method `probabilistic'`deterministic'
	c_local benchmark_scale : copy local scale
	c_local benchmark_label : copy local scalelabel
end

program kappaetc_get_di_opts_testval
	version 11.2
	
	capture syntax [ , TESTVALUE(real 0) ]
	
	if (_rc) {
		syntax , TESTVALUE(string asis)
		gettoken relop testvalue : testvalue , parse("><=") qed(syntaxerr)
		if ((`syntaxerr') | ///
			!inlist(`"`relop'"', ">", "<", "=", ">=", "<=", "==")) {
			display as err "option testvalue() incorrectly specified"
			exit 198
		}
		gettoken relop : relop , parse("=")
		local 0 , testvalue(`testvalue')
		syntax , TESTVALUE(numlist max=1 >=-1 <=1)
		if inlist("`relop'", "=", "==") {
			local relop // void
		}
	}
	
	c_local testvalue 	: copy local testvalue
	c_local relop 		: copy local relop
end

/*
	mata */
	
version 11.2

local S scalar
local R rowvector
local C colvector
local M matrix

local SS string `S'
local SR string `R'
local SC string `C'
local SM string `M'

local RS real `S'
local RR real `R'
local RC real `C'
local RM real `M'

local stInfoAdo struct_kappaetc_infoado_def
local stInfoAdoS struct `stInfoAdo' `S'

local stResults struct_kappaetc_results_def
local stResultsS struct `stResults' `S'

local clAgreeStat class_kappaetc_agreestat_def
local clAgreeStatS class `clAgreeStat' `S'

local clAgreeCoef class_kappaetc_agreecoef_def
local clAgreeCoefR class `clAgreeCoef' `R'

local stTtestR struct_kappaetc_ttestr_def
local stTtestRV struct `stTtestR' vector

local clTtest class_kappaetc_ttest_def
local clTtestS class `clTtest' `S'

mata :

struct `stInfoAdo' {
	`SR' varlist
	`SS' touse
	`SS' weight
	`SS' exp
	`SS' weightvar
	`SS' wgt
	`SS' wgttype
	`RS' krippendorff
	`RS' absolute
	`RS' sinearg
	`RS' U
	`RS' raise
	`RR' indices
	`SS' setype
	`RS' casewise
	`RS' store
	`RS' frequency
	`RC' categories
	`RS' floatfcn
	`SS' dfmat
	`RS' nsubjects
	`RS' nraters
}

struct `stResults' {
	`RR' b
	`RR' se
	`RR' df
	`RM' K_g
	`RR' se_jknife
	`RR' se_conditional
	`RM' b_istar
}

class `clAgreeStat' {
	static `stInfoAdoS' info
	`stResultsS' 		results
	`RM' 				raw
	`RC' 				w_i
	static `RC' 		cat
	static `RS' 		q
	`RC' 				r_i
	`RS' 				r
	`RS' 				n
	`RS' 				f
	`RS' 				g_r
	`RM' 				r_ik
	`RM' 				n_gk
	`RC' 				n_g
	`RM' 				p_gk
	`RR' 				pi_k
	`RC' 				more2
	`RS' 				nprime
	`RS' 				rbar_m2
	static `RM' 		w_kl
	`clAgreeCoefR' 		K
}

class `clAgreeCoef' extends `clAgreeStat' {
	`SS' name
	`RS' eps_n
	`RC' p_ai
	`RC' p_ei
	`RS' p_a
	`RS' p_e
	`RS' b()
	`RC' b_istar()
	`RS' bprime()
	`RS' V()
}

`RS' `clAgreeCoef'::b()
{
	return((((1-eps_n)*(1/nprime)*quadcolsum(w_i:*p_ai)+eps_n)-p_e)/(1-p_e))
}

`RC' `clAgreeCoef'::b_istar()
{
	`RC' b_i	
	b_i = ((n/nprime)*(p_ai:-p_e)/(1-p_e)):*more2
	return(b_i:-2*(1-bprime())*((p_ei:-p_e)/(1-p_e)):*!(!more2*eps_n))
}

`RS' `clAgreeCoef'::bprime()
{
	return((p_a-p_e)/(1-p_e))
}

`RS' `clAgreeCoef'::V()
{
	return((1-f)/(n*(n-1))* ///
		quadcolsum(w_i:*(b_istar():-bprime()):^2:*!(!more2*eps_n), 1))
}

void kappaetc_ado()
{
	`clAgreeStatS' A
	
	kappaetc_get_infoado(A)
	kappaetc_get_rawdata(A)
	
	kappaetc_get_allmats(A)
	kappaetc_get_weights(A)
	
	kappaetc_set_basicsK(A)
	
	kappaetc_get_propobs(A)
	kappaetc_get_propexp(A)
	
	kappaetc_get_results(A)
	kappaetc_set_results(A)
}

void kappaetc_get_infoado(`clAgreeStatS' A)
{
	A.info.varlist 		= tokens(st_local("varlist"))
	A.info.touse 		= st_local("touse")
	A.info.weight 		= st_local("weight")
	A.info.exp 			= st_local("exp")
	A.info.weightvar 	= st_local("weightvar")
	A.info.wgt 			= st_local("wgt")
	A.info.wgttype 		= st_local("wgttype")
	A.info.krippendorff = (st_local("krippendorff") != "")
	A.info.absolute 	= (st_local("absolute") != "noabsolute")
	A.info.sinearg 		= (st_local("sine") == "180") ? 180 : c("pi")
	A.info.U 			= strtoreal(st_local("U"))
	A.info.raise 		= strtoreal(st_local("raise"))
	A.info.indices 		= strtoreal(tokens(st_local("indices")))
	A.info.setype 		= st_local("se")
	A.info.casewise 	= (st_local("casewise") != "")
	A.info.store 		= (st_local("store") != "")
	A.info.frequency 	= (st_local("frequency") != "")
	A.info.categories 	= strtoreal(tokens(st_local("categories")))'
	A.info.floatfcn 	= (st_local("float") != "")
	A.info.dfmat 		= st_local("dfmat")
	A.info.nsubjects 	= strtoreal(st_local("nsubjects"))
	A.info.nraters 		= strtoreal(st_local("nraters"))
}

void kappaetc_get_rawdata(`clAgreeStatS' A)
{
	A.raw = st_data(., A.info.varlist, A.info.touse)
	A.w_i = st_data(., A.info.weightvar, A.info.touse)
	
	if (!A.info.frequency) {
		kappaetc_get_rawdata_raw(A)
	}
	else {
		kappaetc_get_rawdata_freq(A)
	}
	
	if (rows(A.cat) < 2) {
		errprintf("ratings do not vary\n")
		exit(459)
	}
	
	A.q = rows(A.cat)
}

void kappaetc_get_rawdata_raw(`clAgreeStatS' A)
{
	A.w_i = select(A.w_i, (rowmissing(A.raw) :< cols(A.raw)))
	A.raw = select(A.raw, (rowmissing(A.raw) :< cols(A.raw)))
	A.raw = select(A.raw, (colmissing(A.raw) :< rows(A.raw)))
	if ((rows(A.raw) < 2) | (cols(A.raw) < 2)) {
		exit(error(2001))
	}
	
	if ((A.info.setype != "conditional") & (cols(A.raw) < 3)) {
		errprintf("insufficient number of raters to calculate")
		errprintf(" %s standard errors\n", A.info.setype)
		exit(459)
	}
	
	A.cat = uniqrows(vec(A.raw))
	A.cat = select(A.cat, (rownonmissing(A.cat)))
	
	if (rows(A.info.categories)) {
		if (A.info.floatfcn) {
			A.info.categories = floatround(A.info.categories)
		}
		for (i = 1; i <= rows(A.cat); ++i) {
			if (!anyof(A.info.categories, A.cat[i])) {
				errprintf("categories() invalid -- ")
				errprintf("value " + strofreal(A.cat[i]) + " not ")
				errprintf("specified but observed in the data\n")
				exit(198)
			}
		}
		A.cat = sort(A.info.categories, 1)
		A.cat = select(A.cat, (rownonmissing(A.cat)))
	}
}

void kappaetc_get_rawdata_freq(`clAgreeStatS' A)
{
	`RS' order
	
	if (any(A.raw :< 0) | hasmissing(A.raw) | any(A.raw :!= trunc(A.raw))) {
		errprintf("negative, missing or noninteger ")
		errprintf("rating frequencies encountered\n")
		exit(459)
	}
	
	A.cat = (1::cols(A.raw))
	
	if (rows(A.info.categories)) {
		order = sort((A.info.categories, A.cat), 1)[., 2]
		A.raw = A.raw[., order]
		A.cat = A.info.categories[order]
		A.raw = select(A.raw, (rownonmissing(A.cat)'))
	}
	
	A.r_i 	= rowsum(A.raw)
	A.r  	= colmax(A.r_i)
	A.w_i 	= select(A.w_i, (A.r_i :> 0))
	A.raw 	= select(A.raw, (A.r_i :> 0))
	if (A.info.casewise) {
		A.w_i = select(A.w_i, (A.r_i :== A.r))
		A.raw = select(A.raw, (A.r_i :== A.r))
		A.r_i = select(A.r_i, (A.r_i :== A.r))
	}
	
	if (rows(A.raw) < 2) {
		exit(error(2001))
	}
}

void kappaetc_get_allmats(`clAgreeStatS' A)
{
	A.n = quadcolsum(A.w_i)
	if (!A.info.frequency) {
		A.r_ik = J(rows(A.raw), A.q, .)
		A.n_gk = J(cols(A.raw), A.q, .)
		for (k = 1; k <= A.q; ++k) {
			A.r_ik[., k] = rowsum((A.raw :== A.cat[k]))
			A.n_gk[., k] = (A.w_i'*(A.raw :== A.cat[k]))'
		}
		A.n_g 	= quadrowsum(A.n_gk)
		A.p_gk 	= A.n_gk:/A.n_g
		A.r_i 	= rowsum(A.r_ik)
		A.r 	= cols(A.raw)
	}
	else {
		A.r_ik = A.raw
	}
	
	A.pi_k 		= (1/A.n)*quadcolsum(A.w_i:*(A.r_ik:/A.r_i))
	A.more2 	= (A.r_i :> 1)
	A.nprime 	= A.w_i'*A.more2
	A.rbar_m2 	= (1/A.nprime)*(A.w_i'*(A.r_i:*A.more2))	
}

void kappaetc_get_weights(`clAgreeStatS' A)
{
	`RM' k, l
	`RS' min, max
	
	if (A.info.wgttype != "") {
		kappaetc_get_weights_user(A)
		return
	}
	
	if (A.info.wgt == "identity") {
		A.w_kl = !I(A.q)
	}
	else if (A.info.wgt == "ordinal") {
		if (A.info.krippendorff) {
			// Krippendorff 2013, p. 6
			A.w_kl = select(A.r_ik, A.more2):*select(A.w_i, A.more2)
			k = J(1, A.q, quadcolsum(A.w_kl)')
			l = J(A.q, 1, quadcolsum(A.w_kl))
			A.w_kl = lowertriangle(k)
			for (i = 1; i < A.q; ++i) {
				A.w_kl[., i] = quadrunningsum(A.w_kl[., i])
			}
			A.w_kl = makesymmetric((A.w_kl-(k+l)/2):^2)
			A.w_kl = A.w_kl/max(A.w_kl)
		}
		else { 
			// Gwet 2014, p. 91 (3.5.1) and (3.5.2)
			k = J(1, A.q, (1::A.q))
			l = J(A.q, 1, (1..A.q))
			A.w_kl = comb((abs(k-l):+1), 2):/comb(A.q, 2)
		}
	}
	else {
		if (!A.info.absolute) {
			k = J(1, A.q, (1::A.q))
			l = J(A.q, 1, (1..A.q))
			min = 1
			max = A.q
		}
		else {
			k = J(1, rows(A.cat), A.cat)
			l = J(rows(A.cat), 1, A.cat')
			min = A.cat[1]
			max = A.cat[rows(A.cat)]
		}
		if (A.info.wgt == "linear") {
			// Gwet 2014, p. 92 (3.5.3)
			A.w_kl = abs(k-l)/abs(max-min)
		}
		else if (A.info.wgt == "quadratic") {
			// Gwet 2014, p. 79 (3.2.5)
			A.w_kl = ((k-l):^2)/((max-min)^2)
		}
		else if (A.info.wgt == "radical") {
			// Gwet 2014, p. 93 (3.5.4)
			A.w_kl = sqrt(abs(k-l))/sqrt(abs(max-min))
		}
		else if (A.info.wgt == "ratio") {
			// Gwet 2014, p. 93 (3.5.5)
			A.w_kl = (((k-l):/(k+l)):^2)/(((max-min)/(max+min)):^2)
		}
		else if (A.info.wgt == "circular") {
			if (A.info.U != .) {
				// Warrens 2016, p. 513 (7)
				A.w_kl = ((abs(k-l):==1):|(abs(k-l):==(max-min)))
				A.w_kl = 1:-A.w_kl:*A.info.U
			}
			else {
				// Gwet 2014, p. 94 (3.5.6) and (3.5.7)
				A.w_kl = sin(A.info.sinearg*(k-l)/((max-min)+1)):^2
				A.w_kl = A.w_kl/max(A.w_kl)
			}
		}
		else if (A.info.wgt == "bipolar") {
			// Gwet 2014, p. 94 (3.5.8)
			A.w_kl = ((k-l):^2):/((k+l:-2*min):*(2*max:-k:-l))
			A.w_kl = A.w_kl/max(A.w_kl)
		}
		else if (A.info.wgt == "power") {
			// Warrens 2014, p. 2 (3)
			A.w_kl = (abs(k-l):^A.info.raise)/(abs(max-min):^A.info.raise)
		}
		else {
			kappaetc_error("get_weights")
		}
	}
	_diag(A.w_kl, 0)
	A.w_kl = 1:-A.w_kl
	
	kappaetc_get_weights_ok(A)
}

void kappaetc_get_weights_user(`clAgreeStatS' A)
{
	`RR' w
	`RS' dim, l
	
	if (A.info.wgttype == "kapwgt") {
		w = strtoreal(tokens(st_global(A.info.wgt)))
		dim = w[2]
		w = w[3..cols(w)]
		A.w_kl = I(dim)
		l = 1
		for (k = 2; k <= dim; ++k) {
			l = (l+k-1)
			A.w_kl[k, .] = w[l..(l+k-1)], J(1, (dim-k), 0)
		}
		A.w_kl = makesymmetric(A.w_kl)
	}
	else if (A.info.wgttype == "matrix") {
		A.w_kl = st_matrix(A.info.wgt)
	}
	else {
		kappaetc_error("get_weights_user")
	}
	
	if (cols(A.info.indices)) {
		dim = rows(A.w_kl)
		if (A.info.indices[cols(A.info.indices)] > dim) {
			errprintf("suboption indices() invalid; ")
			errprintf("weighting matrix %s is only ", A.info.wgt)
			errprintf("%s x %s\n", strofreal(dim), strofreal(dim))
			exit(498)
		}
		A.w_kl = A.w_kl[A.info.indices', A.info.indices]
	}
	
	kappaetc_get_weights_ok(A)
}

void kappaetc_get_weights_ok(`clAgreeStatS' A)
{
	`RS' err
	`SS' msg
	
	err = 0
	msg = ""
	if (missing(A.w_kl)) {
		err = 504
		msg = "matrix has missing values"
	}
	else if (!issymmetric(A.w_kl)) {
		err = 505
		msg = "matrix not symmetric"
	}
	else if (any(diagonal(A.w_kl):!=1)) {
		err = 498
		msg = "diagonals must be 1"
	}
	else if (any((A.w_kl :< 0):|(A.w_kl :> 1))) {
		err = 498
		msg = "elemnts must be between 0 and 1"
	}
	else if (rows(A.w_kl) != A.q) {
		err = 498
		msg = strofreal(A.q)
		msg = "not " + msg + " x " + msg
	}
	
	if (!err) {
		return
	}
	
	errprintf("invalid weighting matrix %s\n", A.info.wgt)
	errprintf("%s\n", msg)
	
	if (A.info.wgttype == "") {
		if (err == 504) {
			errprintf("\n{p 4 4 2}")
			errprintf("The definition of %s weights results ", A.info.wgt)
			errprintf("in missing values when applied to the observed ")
			errprintf("ratings. Perhaps %s weights are not ", A.info.wgt)
			errprintf("appropriate for your data. You might want to ")
			errprintf("consider specifying another set of weights. See ")
			errprintf("{helpb kappaetc##opt_wgt:kappaetc} for options.")
			errprintf("{p_end}")
		}
		else {
			kappaetc_error("get_weights_ok")
		}
	}
	
	exit(err)
}

void kappaetc_set_basicsK(`clAgreeStatS' A)
{
	A.K = `clAgreeCoef'(6)
	
	A.K[1].name = "Percent Agreement"
	A.K[2].name = "Brennan and Prediger"
	A.K[3].name = "Cohen/Conger's Kappa"
	A.K[4].name = "Fleiss' Kappa"
	A.K[5].name = "Gwet's AC"
	A.K[6].name = "Krippendorff's alpha"
	
	for (i = 1; i <= length(A.K); ++i) {
		A.K[i].w_i 		= A.w_i
		A.K[i].n 		= (i < 6) ? A.n : A.nprime
		A.K[i].nprime 	= A.nprime
		A.K[i].more2 	= A.more2
		A.K[i].f		= missing(A.info.nsubjects) ? 0 : A.n/A.info.nsubjects
		A.K[i].g_r 		= missing(A.info.nraters) ? 0 : A.r/A.info.nraters
		A.K[i].eps_n 	= (i < 6) ? 0 : 1/(A.K[i].n*A.rbar_m2)		
	}	
}

void kappaetc_get_propobs(`clAgreeStatS' A)
{
	// Percent agreement
		// Gwet 2014, p. 147 (5.3.22)
	A.K[1].p_ai = ///
		quadrowsum((A.r_ik:*((A.w_kl*A.r_ik')':-1)):/(A.r_i:*(A.r_i:-1)))
		
	// Brennan and Prediger, Cohen/Conger, Fleiss, Gwet
		// Gwet 2014, p. 147 (5.3.22)
	for (i = 1; i < length(A.K); ++i) {
		A.K[i].p_ai = A.K[1].p_ai
		if (colmissing(A.K[i].p_ai) == rows(A.K[i].p_ai)) {
			A.K[i].p_a = .
		}
		else {
			A.K[i].p_a = (1/A.K[i].nprime)*quadcolsum(A.K[i].w_i:*A.K[i].p_ai)
		}
	}
	
		// Cohen/Conger not possible with frequency data
	if (A.info.frequency) {
		A.K[3].p_ai = J(rows(A.raw), 1, .)
		A.K[3].p_a = .
	}
	
	// Krippendorff's alpha
		// Gwet 2014, p. 149; p. 88 (3.4.8); also error page and email
	A.K[6].p_ai = (A.r_ik:*((A.w_kl*A.r_ik')':-1):/(A.rbar_m2:*(A.r_i:-1)))
	if (colmissing(A.K[i].p_ai) == rows(A.K[i].p_ai)) {
		A.K[6].p_a = .
	}
	else {
		A.K[6].p_a 	= (1/A.nprime)*quadsum(A.K[6].w_i:*A.K[6].p_ai)		
		A.K[6].p_ai = quadrowsum(A.K[6].p_ai):- ///
			A.K[6].p_a*(A.r_i:-A.rbar_m2)/A.rbar_m2
		A.K[6].p_ai = A.K[6].p_ai:*A.more2
	}
}

void kappaetc_get_propexp(`clAgreeStatS' A)
{
	`RM' eps_g, delta
	`RR' pi_k_m2
	
	// Percent agreement
	A.K[1].p_ei = J(rows(A.r_ik), 1, 0)
	
	// Brennan-Prediger (equivalent to PABAK, cf. p. 69)
		// Gwet 2014, p. 87 (3.4.5)
	A.K[2].p_ei = J(rows(A.r_ik), 1, 1/A.q^2*quadsum(A.w_kl))
	
	// Cohen/Conger kappa
		// Gwet 2014, p. 149; error page
	if (!A.info.frequency) {
		eps_g = (A.raw':<missingof(A.raw))
		A.K[3].p_ei = J(A.r*A.q, rows(A.r_ik), 0)
		for (l = 1; l <= A.q; ++l) {
			delta = (A.raw':==A.cat[l])
			A.K[3].p_ei = A.K[3].p_ei + ///
				A.w_kl[., l]#(delta:-A.p_gk[., l]:*(eps_g:-A.n_g/A.K[3].n))
		}
		A.K[3].p_ei = J(A.q, 1, A.K[3].n:/(A.n_g)):*A.K[3].p_ei
		A.K[3].p_ei = quadcolsum(A.K[3].p_ei:*vec(A.r*mean(A.p_gk):-A.p_gk))	
		A.K[3].p_ei = 1/(A.r*(A.r-1)):*A.K[3].p_ei'
	}
	else {
			// not possible with frequency data 
		A.K[3].p_ei = J(rows(A.raw), 1, .)
	}
	
	// Fleiss kappa
		// Gwet 2014, p. 148 (5.3.24)
	A.K[4].p_ei = quadcolsum((A.w_kl:*A.pi_k':+(A.w_kl:*A.pi_k)'):/2)
	A.K[4].p_ei = quadrowsum(A.K[4].p_ei:*(A.r_ik:/A.r_i))
	
	// Gwet AC
		// Gwet 2014, p. 148 (5.3.23)
	A.K[5].p_ei = quadsum(A.w_kl)/(A.q*(A.q-1))*((A.r_ik:/A.r_i)*(1:-A.pi_k)')
	
		// p_e
	for (i = 1; i <= length(A.K); ++i) {
		if (colmissing(A.K[i].p_ei) == rows(A.K[i].p_ei)) {
			A.K[i].p_e = .
		}
		else {
			A.K[i].p_e = (1/A.K[i].n)*quadcolsum(A.K[i].w_i:*A.K[i].p_ei)
		}
	}
	
	// Krippendorff's alpha
		// Gwet 2014, p. 149
	pi_k_m2 = (1/A.K[6].n)*(A.w_i'*((A.r_ik:/A.rbar_m2):*A.more2))
	A.K[6].p_ei = quadcolsum((A.w_kl:*pi_k_m2':+(A.w_kl:*pi_k_m2)'):/2)
	A.K[6].p_ei = quadrowsum(A.K[6].p_ei:*(A.r_ik:/A.rbar_m2))
	if (colmissing(A.K[6].p_ei) == rows(A.K[6].p_ei)) {
		A.K[6].p_e = .
	}
	else {
		A.K[6].p_e 	= (1/A.K[6].n)*quadcolsum(A.K[6].w_i:*A.K[6].p_ei:*A.more2)
		A.K[6].p_ei = A.K[6].p_ei:-A.K[6].p_e:*(A.r_i:-A.rbar_m2)/A.rbar_m2
		A.K[6].p_ei = A.K[6].p_ei:*A.more2
	}	
}

void kappaetc_get_results(`clAgreeStatS' A)
{
	A.results.b = A.results.se = A.results.df = J(1, length(A.K), .)
	
	if (A.info.store) {
		A.results.b_istar = J(rows(A.w_i), length(A.K), .)
	}
	
	for (i = 1; i <= length(A.K); ++i) {
		A.results.b[i] = A.K[i].b()
		if ((A.info.setype != "jackknife") & (!A.info.krippendorff)) {
			A.results.se[i] = A.K[i].V()
		}
		if (A.info.dfmat != "") {
			A.results.df[i] = st_matrix(A.info.dfmat)[i]
		}
		else {
			A.results.df[i] = A.K[i].n-1
		}
		if (A.info.store) {
			A.results.b_istar[., i] = ///
				((1-A.K[i].eps_n):*A.K[i].b_istar():+A.K[i].eps_n)
			A.results.b_istar[., i] = ///
				(1:/(!(!A.K[i].more2*A.K[i].eps_n))):*A.results.b_istar[., i]
		}
	}
	
	if (A.info.setype != "conditional") {
		kappaetc_get_results_jknife(A)
		A.results.se_conditional = A.results.se
	}
	
	if (A.info.setype == "jackknife") {
		A.results.se = A.results.se_jknife
	}
	else if (A.info.setype == "unconditional") {
		// Gwet 2014, p. 156 (5.4.4)
		A.results.se = A.results.se_conditional + A.results.se_jknife
		A.results.se_conditional 	= sqrt(A.results.se_conditional)
		A.results.se_jknife 		= sqrt(A.results.se_jknife)
	}
	
	A.results.se = sqrt(A.results.se)
}

void kappaetc_get_results_jknife(`clAgreeStatS' A)
{
	`clAgreeStatS' Ajknife
	
	A.results.K_g = J(A.r, length(A.K), .)
	for (g = 1; g <= A.r; ++g) {
		Ajknife.raw = select(A.raw, ((1..cols(A.raw)):!=g))
		Ajknife.w_i = A.w_i:*(rowmissing(Ajknife.raw):<cols(Ajknife.raw))
		kappaetc_get_allmats(Ajknife)
		kappaetc_set_basicsK(Ajknife)
		kappaetc_get_propobs(Ajknife)
		kappaetc_get_propexp(Ajknife)		
		for (i = 1; i <= length(A.K); ++i) {
			A.results.K_g[g, i] = Ajknife.K[i].b()
		}
	}
	
	A.results.se_jknife = ///
		(1:/colnonmissing(A.results.K_g)):*quadcolsum(A.results.K_g)
	A.results.se_jknife = ///
		quadcolsum((A.results.K_g:-A.results.se_jknife):^2, 1)
	A.results.se_jknife = ///
		((1-A.K[1].g_r)*(A.r-1)/A.r)*A.results.se_jknife	
}

void kappaetc_set_results(`clAgreeStatS' A)
{
	`SC' names
	`RM' tmp
	
	st_rclear()
	
	st_numscalar("r(N)", A.n)
	st_numscalar("r(r)", A.r)
	st_numscalar("r(r_min)", min(A.r_i))
	st_numscalar("r(r_avg)", (1/A.n)*quadcolsum(A.w_i:*A.r_i))
	st_numscalar("r(r_max)", max(A.r_i))
	if (A.info.setype != "conditional") {
		st_numscalar("r(jk_miss)", missing(A.results.K_g))
	}
	
	if (A.info.dfmat != "") {
		st_global("r(dfmat)", A.info.dfmat)
	}
	st_global("r(wexp)", A.info.exp)
	st_global("r(wtype)", A.info.weight)
	st_global("r(setype)", A.info.setype)
	st_global("r(userwgt)", A.info.wgttype)
	st_global("r(wgt)", A.info.wgt)
	st_global("r(cmd)", "kappaetc")
	
	names = J(length(A.K), 2, "")
	for (i = 1; i <= length(A.K); ++i) {
		names[i, 2] = A.K[i].name
	}
	
	if (A.info.store) {
		if (A.info.weight != "") {
			st_matrix("r(weight_i)", A.w_i)
		}
		st_matrix("r(b_istar)", A.results.b_istar)
		st_matrixcolstripe("r(b_istar)", names)
	}
	
	st_matrix("r(categories)", A.cat)
	
	st_matrix("r(W)", A.w_kl)
	
	tmp = J(2, length(A.K), .)
	for (i = 1; i <= length(A.K); ++i) {
		tmp[1, i] = A.K[i].p_e
		tmp[2, i] = (1-A.K[i].eps_n)*A.K[i].p_a+A.K[i].eps_n
	}
	
	st_matrix("r(prop_e)", tmp[1, .])
	st_matrixcolstripe("r(prop_e)", names)
	st_matrix("r(prop_o)", tmp[2, .])
	st_matrixcolstripe("r(prop_o)", names)
	
	st_matrix("r(df)", A.results.df)
	st_matrixcolstripe("r(df)", names)
	
	if (A.info.setype != "conditional") {
		if (A.info.setype == "unconditional") {
			st_matrix("r(se_conditional)", A.results.se_conditional)
			st_matrixcolstripe("r(se_conditional)", names)
			st_matrix("r(se_jknife)", A.results.se_jknife)
			st_matrixcolstripe("r(se_jknife)", names)
		}
		st_matrix("r(b_jknife)", A.results.K_g)
		st_matrixcolstripe("r(b_jknife)", names)
	}
	
	st_matrix("r(se)", A.results.se)
	st_matrixcolstripe("r(se)", names)
	
	st_matrix("r(b)", A.results.b)
	st_matrixcolstripe("r(b)", names)
}

/*
	t test */
	
struct `stTtestR' {
	`SS' name
	`RM' b_istar
	`RC' w_i
	`RR' df
	`RR' rb
	`RM' W
	`RC' cat
}

class `clTtest' {
	`stTtestRV' R
	`RS' 		tolerance
	`RC' 		w_i
	`RR' 		n
	`RM' 		d_i()
	`RR' 		b()
	`RR' 		se()
	void 		new()
}

void `clTtest'::new()
{
	R = `stTtestR'(2)
}

`RM' `clTtest'::d_i()
{
	return(R[1].b_istar:-R[2].b_istar)
}

`RR' `clTtest'::b()
{
	return((1:/n):*quadcolsum(w_i:*d_i()))
}

`RR' `clTtest'::se()
{
	return(sqrt((1:/n):*(1:/(n:-1)):*quadcolsum(w_i:*(d_i():-b()):^2)))
}

void kappaetc_ttest_ado()
{
	`clTtestS' T
	
	kappaetc_ttest_get_r(T)
	kappaetc_ttest_set_r(T)
}

void kappaetc_ttest_get_r(`clTtestS' T)
{
	for (i = 1; i <= length(T.R); ++i) {
		T.R[i].name 	= st_local("name" + strofreal(i))
		T.R[i].b_istar 	= st_matrix(st_local("b_istar" + strofreal(i)))
		if (st_local("weight_i" + strofreal(i)) != "") {
			T.R[i].w_i 	= st_matrix(st_local("weight_i" + strofreal(i)))
		}
		else {
			T.R[i].w_i = 1
		}
		T.R[i].df 		= st_matrix(st_local("df" + strofreal(i)))
		T.R[i].rb 		= st_matrix(st_local("b" + strofreal(i)))
		T.R[i].W 		= st_matrix(st_local("W" + strofreal(i)))
		T.R[i].cat 		= st_matrix(st_local("categories" + strofreal(i)))
	}
	
	T.tolerance = strtoreal(st_local("tolerance"))
	T.w_i 		= T.R[1].w_i
	T.n 		= T.R[1].df:+1
	
	kappaetc_ttest_verify(T)
}

void kappaetc_ttest_verify(`clTtestS' T)
{
	`RR' b
	
	if (length(T.R) != 2) {
		kappaetc_error("ttest_verify")
	}
	
	for (i = 1; i <= length(T.R); ++i) {
		b = (1:/(T.R[i].df:+1)):*quadcolsum(T.R[i].w_i:*T.R[i].b_istar)
		if (mreldif(T.R[i].rb, b) > T.tolerance) {
			errprintf("kappaetc result %s is invalid\n", T.R[i].name)
			errprintf("subject-level coefficients do not ")
			errprintf("average to estimated coefficients\n")
			errprintf("maximum relative difference is ")
			errprintf("%-18.0g\n", mreldif(T.R[i].rb, b))
			exit(499)
		}
	}
	
	if ( ///
	(mreldif(T.R[1].df, T.R[2].df) > T.tolerance) 	| 	///
	(rows(T.R[1].b_istar) != rows(T.R[2].b_istar)) 	| 	///
	(rows(T.R[1].w_i) != rows(T.R[2].w_i)) 				///
	) {
		kappaetc_ttest_err459("the same number of subjects")
	}
	
	if ((cols(T.R[1].W) != cols(T.R[2].W)) | ///
	(cols(T.R[1].cat) != cols(T.R[2].cat))) {
		kappaetc_ttest_err459("the same number of rating categories")
	}
	
	if (mreldif(T.R[1].cat, T.R[2].cat) > T.tolerance) {
		kappaetc_ttest_err459("the same rating categories")
	}
	
	if (mreldif(T.R[1].W, T.R[2].W) > T.tolerance) {
		kappaetc_ttest_err459("the same weights for disagreements")
	}
	
	if (mreldif(T.R[1].w_i, T.R[2].w_i) > T.tolerance) {
		kappaetc_ttest_err459("the same subject-level weights")
	}
	
	if (mreldif(T.b(), (T.R[1].rb:-T.R[2].rb)) > T.tolerance) {
		errprintf("subject-level differences do not average ")
		errprintf("to differences of estimated coefficients\n")
		errprintf("maximum relative difference is ")
		errprintf("%-18.0g\n", mreldif(T.b(), (T.R[1].rb:-T.R[2].rb)))
		exit(499)
	}
}

void kappaetc_ttest_err459(`SS' txt)
{
	errprintf("kappaetc results not based on %s\n", txt)
	errprintf("cannot perform paired t test\n")
	exit(459)
}

void kappaetc_ttest_set_r(`clTtestS' T)
{
	`SM' names
	
	st_rclear()
	
	st_numscalar("r(N)", max(T.n))
	
	st_global("r(results2)", T.R[2].name)
	st_global("r(results1)", T.R[1].name)
	st_global("r(cmd2)", "ttest")
	st_global("r(cmd)", "kappaetc")
	
	names = st_matrixcolstripe(st_local("b1"))
	
	st_matrix("r(df)", T.n:-1)
	st_matrixcolstripe("r(df)", names)
	st_matrix("r(se)", T.se())
	st_matrixcolstripe("r(se)", names)
	st_matrix("r(b)", T.b())
	st_matrixcolstripe("r(b)", names)
}

/*
	utility */
	
void kappaetc_di_set_rtable()
{
	`RS' level, testvalue, largesample
	`RR' b, se, df, t, signt, pvalue, crit, ll, ul
	`SC' names
	`SS' relop, sname
	
	level 		= strtoreal(st_local("level"))
	testvalue 	= strtoreal(st_local("testvalue"))
	relop 		= st_local("relop")	
	largesample = strtoreal(st_local("largesample"))
	
	b 		= st_matrix("r(b)")
	se 		= st_matrix("r(se)")
	df 		= st_matrix("r(df)")
	t 		= (b:-testvalue):/se
	signt 	= sign(t)
	
	if ((!largesample) & ( ///
			(st_global("r(setype)") == "conditional") 	| ///
			(st_global("r(dfmat)") != "") 				| ///
			(st_global("r(cmd2)") == "ttest")			///
		)) {
		pvalue 	= 2*ttail(df, abs(t))
		sname 	= "t"
		crit = invttail(df, (1-level/100)/2)
	}
	else {
		pvalue 	= 2*normal(-abs(t))
		sname 	= "z"
		crit = J(1, cols(b), (-1)*invnormal((1-level/100)/2))
	}
	
	if (relop == "<") {
		pvalue = abs((signt:<0):-(pvalue/2))
	}
	else if (relop == ">") {
		pvalue = abs((signt:>0):-(pvalue/2))
	}
	
	ll = b-crit:*se
	ul = b+crit:*se
	if (st_global("r(cmd2)") != "ttest") {
		ll = ll:/abs(ll:*(abs(ll):>1):+(abs(ll):<=1))
		ul = ul:/abs(ul:*(abs(ul):>1):+(abs(ul):<=1))
	}
	
	names = ("b", "se", sname, "pvalue", "ll", "ul", "df", "crit")
	names = (J(8, 1, ""), names')
	st_numscalar("r(level)", level)
	st_matrix("r(table)", (b\ se\ t\ pvalue\ ll\ ul\ df\ crit))
	st_matrixcolstripe("r(table)", st_matrixcolstripe("r(b)"))
	st_matrixrowstripe("r(table)", names)
}

void kappaetc_di_set_benchmark()
{
	`RS' level, largesample
	`RM' bm, b, imp, p_cum, idx, table_prob, table_det
	`RR' z
	
	bm = strtoreal(tokens(st_local("benchmark_scale")))
	if (!cols(bm)) {
		st_matrix("r(table_benchmark_prob)", J(0, 0, .))
		st_matrix("r(table_benchmark_det)", J(0, 0, .))
		st_matrix("r(benchmarks)", J(0, 0, .))
		st_matrix("r(imp)", J(0, 0, .))
		st_matrix("r(p_cum)", J(0, 0, .))
		return
	}
	
	level 		= strtoreal(st_local("level"))
	largesample = strtoreal(st_local("largesample"))
	
	bm 	= J(1, 6, bm[cols(bm)..1]')
	b 	= st_matrix("r(b)")
	z 	= (b:-bm):/st_matrix("r(se)")
	
	if ((!largesample) & ///
		((st_global("r(setype)") == "conditional") | ///
		(st_global("r(dfmat)") != "") ///
		)) {
			imp = (1:-ttail(st_matrix("r(df)"), z))
	}
	else {
		imp = normal(z)
	}
	
	p_cum = imp
	if (rows(imp) > 1) {
		for (i = 1; i <= rows(imp); ++i) {
			if (i < rows(imp)) {
				imp[i, .] = imp[(i+1), .]:-imp[i, .]
			}
			p_cum[i, .] = quadcolsum(imp[(1::i), .])
		}
	}	
	p_cum = p_cum:/(p_cum:*(p_cum:>1)+(p_cum:<=1))
	
	table_prob = table_det = J(6, 6, .)
	table_prob[(1::2), .] = table_det[(1::2), .] = ///
		st_matrix("r(table)")[(1::2), .]
	
	for (i = 1; i <= cols(table_prob); ++i) {
		idx = ((p_cum[., i] :> (level/100)), (b[i] :<= bm[., i]))
		idx = (colmin(select((1::rows(bm)), idx[., 1])), ///
			colmax(select((1::rows(bm)), idx[., 2])))
		table_prob[3, i] 	= missing(idx[1]) ? idx[1] : imp[idx[1], i]
		table_det[3, i] 	= missing(idx[2]) ? idx[2] : imp[idx[2], i]
		table_prob[4, i] 	= missing(idx[1]) ? idx[1] : p_cum[idx[1], i]
		table_det[4, i] 	= missing(idx[2]) ? idx[2] : p_cum[idx[2], i]
		table_prob[5, i] 	= (idx[1] < rows(bm)) ? bm[(idx[1]+1), i] : .
		table_det[5, i] 	= (idx[2] < rows(bm)) ? bm[(idx[2]+1), i] : .
		table_prob[6, i] 	= missing(idx[1]) ? idx[1] : bm[idx[1], i]
		table_det[6, i] 	= missing(idx[2]) ? idx[2] : bm[idx[2], i]
	}
	
	st_matrix("r(p_cum)", p_cum)
	st_matrixcolstripe("r(p_cum)", st_matrixcolstripe("r(b)"))
	st_matrix("r(imp)", imp)
	st_matrixcolstripe("r(imp)", st_matrixcolstripe("r(b)"))
	st_matrix("r(benchmarks)", bm[., 1])
	st_matrixcolstripe("r(benchmarks)", ("", "Benchmarks"))
	st_matrix("r(table_benchmark_det)", table_det)
	st_matrixrowstripe("r(table_benchmark_det)", ///
		(J(cols(b), 1, ""), ("b"\ "se"\ "imp"\ "p_cum"\ "ll"\ "ul")))
	st_matrixcolstripe("r(table_benchmark_det)", st_matrixcolstripe("r(b)"))
	st_matrix("r(table_benchmark_prob)", table_prob)
	st_matrixrowstripe("r(table_benchmark_prob)", ///
	st_matrixrowstripe("r(table_benchmark_det)"))
	st_matrixcolstripe("r(table_benchmark_prob)", ///
	st_matrixcolstripe("r(table_benchmark_det)"))
}

void kappaetc_error(`SS' where, | `RS' par)
{	
	if (par) {
		where = where + "()"
	}
	
	errprintf("{col 3}unexpected error in {bf:kappaetc_%s}\n", where)
	errprintf("This should not happen. Please contact the author ")
	errprintf("(klein.daniel.81@gmail.com)\n")
	exit(3498)
}

end
exit

1.4.0 	16jun2017	bug fix variance Krippendorff's alpha with missing ratings
					suboption scale() adds 1 as upper limit if not specified
					new wgt_option u(#) for circular weights
					new wgtid power(#)
					new reporting option testvalue()
					new reporting option largesample
1.3.0	20may2017	bug fix ttest did not work (correctly) with weights
					bug fix finite sample correction incorrect in 1.2.0
					modified r(b_istar) now unweighted
					new r(weight_i)
					default tolerance in ttest 1e-14 (was 1e-15)
					option ttest now optional
					option df() now accepts both row and column vector
					suboption scale() requires at least two upper limits
					never released on SSC
1.2.0	06may2017	bug fix revised variance formula for Krippendorff's alpha
					bug fix incorrect jacknife se with missing replicates
					bug fix see kappaetci 1.1.0
					bug fix ignored option df()
					bug fix wgt_options kapwgt and matrix evoked error
					option indices() no longer allowed (questionable results)
					new wgt_option force[wgt] (not documented)
					new option store()
					new r() b_istar
					new option ttest implements paired t tests
					new option categories() specifies predetermined ratings
					new options replay and restore (not documented)
					slightly changed output (removed blank line before table)
					code polish new classes and structs
1.1.0	17jan2017	bug fix incorrect Cohen/Conger's kappa with missing ratings
					bug fix incorrect jackknife se with missing ratings
					bug fix extended missing values treated as valid ratings
					bug fix incorrect ratio weights with zero (0) ratings
					CIs now truncated to [-1<=ll<=ul<=1]
					new options benchmark and showscale
					new r() table_benchmark_{prob & det} benchmarks imp p_cum
					new option frequency
					new wgt_option indices()
					implement fweights into formulas (no longer expand)
					add support for iweights
					add checks of weighting matrix
					new output label ratings per subject
					new output add number of rating categories
					new command kappaetci
1.0.0	13dec2016	release on SSC
