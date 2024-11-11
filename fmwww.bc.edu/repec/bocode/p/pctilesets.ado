*! 1.0.0 NJC 28 October 2024 
program pctilesets 
	version 8.1 
	
	capture syntax varname(numeric) [if] [in] [aweight fweight]      ///
	, OVER(varname) [ MINimum MAXimum Total Pctile(numlist int >0 <100 sort) SAVING(str asis) Total * ]   
	
	if _rc == 0  { 
		pctilesets_g `0'
		exit 0  
	}
	
	syntax varlist(numeric) [if] [in] [aweight fweight] ///
	[, SAVING(str asis) MINimum MAXimum Pctile(numlist int >0 <100) ALLobs inclusive cw * ]   
	
	if "`allobs'`inclusive'`cw'" != "" marksample touse, novarlist 
	else marksample touse 
	
	quietly count if `touse'
	if r(N) == 0 error 2000
	if r(N) == 1 error 2001 
	
	if "`minimum'" != "" { 
		local call1 min 
		local call2 (r(min))
	}
	
	if "`pctile'" != "" {
		foreach p of local pctile {
			if !inlist(`p', 1, 5, 10, 25, 50, 75, 90, 95, 99) { 
				local bad `bad' `p'
			}
			else {
				local call1 `call1' p`p'
				local call2 `call2' (r(p`p'))
			}
		}
		if "`bad'" != "" {
			local which = plural(`: word count `bad'', "pctile")
			noisily di _n "note: `which' `bad' not on offer"
		}
	}
	
	if "`maximum'" != "" { 
		local call1 `call1' max 
		local call2 `call2' (r(max))
	}
	
	if "`call1'" == "" { 
		di "nothing to do?"
		exit 0 
	}
	
	preserve 
	quietly keep if `touse'

	if `"`saving'"' == "" {
		tempfile saving 
		local wantsave 0  
	}
	else local wantsave 1 
	
	tempname handle 
	postfile `handle' str32 varname str80 varlabel n `call1' using `saving'
	
	quietly foreach v of local varlist {
	    local varlabel : var label `v'
		if `"`varlabel'"' == "" local varlabel "`v'"
		summarize `v' [`weight' `exp'], detail 
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

program pctilesets_g                                                        
	syntax varname(numeric) [if] [in] [aweight fweight]              ///
	, OVER(varname) [ SAVING(str asis) Total MINimum MAXimum Pctile(numlist int >0 <100 sort) * ]   

	marksample touse  
	markout `touse' `over', strok 
	
	quietly count if `touse'
	if r(N) == 0 error 2000
	if r(N) == 1 error 2001 
	
	if "`minimum'" != "" { 
		local call min
	}
	
	if "`pctile'" != "" {
		foreach p of local pctile {
			if !inlist(`p', 1, 5, 10, 25, 50, 75, 90, 95, 99) { 
				local bad `bad' `p'
			}
			else local call `call' p`p'
		}
		if "`bad'" != "" {
			local which = plural(`: word count `bad'', "pctile")
			noisily di _n "note: `which' `bad' not on offer"
		}
	}
	
	
	if "`maximum'" != "" local call `call' max
	
	preserve 
	quietly keep if `touse' 
	
	local varlabel : variable label `varlist'
	local gvarlabel : variable label `over' 
	
	quietly statsby , by(`over') clear `total' : ///
	summarize `varlist' [`weight' `exp'], detail 
	
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
	
	local perhaps min p1 p5 p10 p25 p50 p75 p90 p95 p99 max 
	local todrop : list perhaps - call 
	
	drop `todrop' mean sum sum_w sd Var skewness kurtosis 
	
	gen varname = "`varlist'"
	gen varlabel = cond(missing("`varlabel'"), varname, "`varlabel'")
	gen groupvar = "`over'"
	gen gvarlabel = cond(missing("`gvarlabel'"), groupvar, "`gvarlabel'")

	if "`weight'" != "" gen weight = "`weight' `exp'"
	
	foreach v in n `call' {
		label var `v' 
	}
	
	order varname varlabel origgvar groupvar gvarlabel group n `call'
	
	list, noobs `options'

	if `"`saving'"' != "" { 
		capture label data `"`0'"'
		display 
		save `saving'
	}
end 

