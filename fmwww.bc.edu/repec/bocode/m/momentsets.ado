*! 1.0.0 NJC 1 November 2024 
program momentsets 
	version 8.1 
	
	capture syntax varname(numeric) [if] [in] [aweight fweight]      ///
	, OVER(varname) [ Mean SD Var SKewness KUrtosis Total SAVING(str asis) * ]   
	
	if _rc == 0  { 
		momentsets_g `0'
		exit 0  
	}
	
	syntax varlist(numeric) [if] [in] [aweight fweight] ///
	[, SAVING(str asis) Mean SD Var SKewness KUrtosis ALLobs inclusive cw * ]   
	
	if "`allobs'`inclusive'`cw'" != "" marksample touse, novarlist 
	else marksample touse 
	
	quietly count if `touse'
	if r(N) == 0 error 2000
	if r(N) == 1 error 2001 
	
	if "`mean'`sd'`var'`skewness'`kurtosis'" == "" {
		noisily di "nothing to do?"
		exit 0 
	}
	else if "`sd'`var'`skewness'`kurtosis'" == "" { 
		local option "meanonly"
	}
	else if "`skewness'`kurtosis'" != "" {
		local option "detail"
	}
		
	preserve 
	quietly keep if `touse'

	if `"`saving'"' == "" {
		tempfile saving 
		local wantsave 0  
	}
	else local wantsave 1 
	
	if "`var'" != ""  local var "Var"
	
	foreach s in mean sd var skewness kurtosis { 
		if "``s''" != "" {
			local call1 `call1' `s'
			local call2 `call2' (r(`s'))
		}
	}
	
	tempname handle 
	postfile `handle' str32 varname str80 varlabel n  `call1' using `saving'
	
	quietly foreach v of local varlist {
	    local varlabel : var label `v'
		if `"`varlabel'"' == "" local varlabel "`v'"
		summarize `v' [`weight' `exp'], `option'
		post `handle' ("`v'") ("`varlabel'") (r(N)) `call2'
	}
	
	postclose `handle'
	
	gettoken filename rest : saving, parse(,) 
	use "`filename'", clear 
		
	capture label data `"`0'"'
	
	if "`weight'" != "" gen weight = "`weight' `exp'"
	
	list, noobs `options'
	
	if `wantsave' {
		quietly compress
		capture label data `"`0'"'
		display  
		save "`filename'", replace
	} 
end 

program momentsets_g                                                        
	syntax varname(numeric) [if] [in] [aweight fweight]              ///
	, OVER(varname) [ SAVING(str asis) Mean SD Var SKewness KUrtosis Total  * ]   

	marksample touse  
	markout `touse' `over', strok 
	
	quietly count if `touse'
	if r(N) == 0 error 2000
	if r(N) == 1 error 2001 
	
	if "`mean'`sd'`var'`skewness'`kurtosis'" == "" {
		noisily di "nothing to do?"
		exit 0 
	}
	else if "`sd'`var'`skewness'`kurtosis'" == "" { 
		local option "meanonly"
	}
	else if "`skewness'`kurtosis'" != "" {
		local option "detail"
	}
	
	preserve 
	quietly keep if `touse' 
	
	if "`var'" != "" local var "Var"
	
	foreach s in mean sd var skewness kurtosis { 
		if "``s''" != "" {
			local call1 `call1' `s'
			local call2 `call2' (r(`s'))
		}
	}
	
	local varlabel : variable label `varlist'
	local gvarlabel : variable label `over' 
	
	quietly statsby , by(`over') clear `total' : ///
	summarize `varlist' [`weight' `exp'], `option'
	
	quietly egen group = group(`over'), label 
	_crcslbl group `over'

	quietly if "`total'" != "" { 
		su group, meanonly 
		local gmax = r(max) + 1 
		replace group = `gmax' if group == . 
		label def group `gmax' "Total", modify 
	}
	
	rename `over' origgvar  
	rename N n  
	
	local list1 sum sum_w min max 
	
	local list2 `list1' 
	if "`var'" == "" local list2 `list2' Var 
	
	local list3 `list1'
	if "`mean'" == "" local list3 `list3' mean 
	if "`var'" == "" local list3 `list3' Var 
	
	local list4 `list2' p1 p5 p10 p25 p50 p75 p90 p95 p99 
	if "`mean'" == "" local list4 `list4' mean 
	if "`sd'" == "" local list4 `list4' sd 
	if "`var'" == "" local list4 `list4' Var 
	if "`skewness'" == "" local list4 `list4' skewness
	if "`kurtosis'" == "" local list4 `list4' kurtosis 
	
	if "`option'" == "meanonly" {
		drop `list1'
	}
	else if "`option'" == "detail" {
		drop `list4'
	}
	else drop `list3'
	
	gen varname = "`varlist'"
	gen varlabel = cond(missing("`varlabel'"), varname, "`varlabel'")
	gen groupvar = "`over'"
	gen gvarlabel = cond(missing("`gvarlabel'"), groupvar, "`gvarlabel'")

	if "`weight'" != "" gen weight = "`weight' `exp'"
	
	foreach v in n `mean' `sd' `var' `skewness' `kurtosis' {
		label var `v' 
	}
	
	order varname varlabel origgvar groupvar gvarlabel group n `mean' `sd' `var' `skewness' `kurtosis'
	
	list, noobs `options'

	if `"`saving'"' != "" { 
		quietly compress 
		capture label data `"`0'"'
		display 
		save `saving'
	}
end 

