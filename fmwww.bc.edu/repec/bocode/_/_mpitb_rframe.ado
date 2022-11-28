*! part of -mpitb- the MPI toolbox

cap program drop _mpitb_rframe
program define _mpitb_rframe
syntax , FRame(name) [cot ts t add(name) DOUble replace]
	* check
	if "`cot'" != "" & "`t'" != "" {
		di as err "Please choose only one of {bf:cot} or {bf:t}!"
		e 197
	}
	if "`replace'" != "" {
		cap frame drop `frame'
	}
	else {
		confirm new frame `frame'
	}
	
	
	* changes		
	if "`cot'" != "" {
		foreach v in ann yt0 yt1 t0 t1 {
			loc `v' `v'
		}
	}
	if "`double'" == "" {
		loc double float
	}
	* options 
	if "`ts'" != "" {
		loc time ts_est
		loc timedata ts_data
	}
	loc double_vars b se ll ul pval tval `time' `timedata'			
	loc str_vars loa measure indicator spec wgts `add'
	loc float_vars k `yt0' `yt1' `t0' `t1'
	loc byte_vars ctype `ann'
	loc int_vars subg `t'
	
	* create
	frame create `frame' `double' (`double_vars') str10 (`str_vars') float (`float_vars') byte (`byte_vars') int (`int_vars')

	frame `frame' {
		* label
		lab var b "point estimate"
		lab var se "standard error"
		lab var ll "CI lower bound"
		lab var ul "CI upper bound"
		lab var pval "p-value"
		lab var tval "t-value"
		lab var wgts "weighting scheme"
		lab var measure "measure"
		lab var indicator "indicator"
		lab var k "poverty cutoff"
		lab var subg "subgroup"
		lab var spec "name of specification"
		lab var loa "level of analysis"
		lab var ctype "type of change"
		lab def ctype 0 "lev" 1 "abs" 2 "rel"
		lab val ctype ctype
		if "`ts'" != "" {
			lab var ts_est "timestamp estimate"
			lab var ts_data "timestamp (micro) data"
			format ts* %tcdd_Mon_CCYY_HH:MM	// time
		}
		if ("`t'" != "") lab var t "point of time (counter)"
		if ("`ann'" != "") lab var ann "annualised change"
		if ("`yt0'" != "") lab var yt0 "first year of change"
		if ("`yt1'" != "") lab var yt1 "second year of change"
	
		* data char 
		if ("`ts'" != "") char _dta[has_ts] 1	
		if ("`cot'" == "" & "`t'" == "") char _dta[type] "level"	
		if ("`cot'" == "" & "`t'" != "") char _dta[type] "level-hot"	
		if ("`cot'" != "") char _dta[type] "changes"	
	
	* formats
	format %5.4f b se ll ul 
	format %4.2f pval tval
	}
end 
