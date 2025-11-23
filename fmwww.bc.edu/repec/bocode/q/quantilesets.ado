*! 1.0.0 NJC 17 November 2025
program quantilesets 
	version 19.50 
	
	// 19.50 is necessary ... but not sufficient 
	if daily("`c(born_date)'", "DMY") < 24057 {
		di as err "{p}Stata needs updating to 19.50 12 Nov 2025 or later to use this command{p_end}"
		exit 133
	}
	
	capture syntax varname(numeric) [if] [in] ///
	, OVER(varname) Prob(numlist >=0 <=1 sort) [Method(str) Total SAVING(str asis) * ]   
	
	if _rc == 0  { 
		quantilesets_g `0'
		exit 0  
	}
	
	syntax varlist(numeric) [if] [in] ///
	, Prob(numlist >=0 <=1 sort) [Method(str) SAVING(str asis) ALLobs inclusive cw * ]  
	
	if "`method'" == "" local method "tukey"
	else { 
		capture mata : quantile((1::5), (0.25, 0.5, 0.75)', "`method'")
		if _rc { 
			di as error "invalid method argument"
			exit 198
		}
	} 
	
	if "`allobs'`inclusive'`cw'" != "" marksample touse, novarlist 
	else marksample touse 
	
	quietly count if `touse'
	if r(N) == 0 error 2000
	if r(N) == 1 error 2001 
	
	preserve 
	quietly keep if `touse'

	if `"`saving'"' == "" {
		tempfile saving 
		local wantsave 0  
	}
	else local wantsave 1 

	local nq : word count `prob'
	
	forval q = 1/`nq' { 
		local call1 `call1' q`q' 
		local call2 `call2' (r(q`q'))
	}
	
	tempname handle 
	local mlength = strlen("`method'")
	postfile `handle' str32 varname str80 varlabel n `call1' str`mlength' method using `saving'
	
	quietly foreach v of local varlist {
	    local varlabel : var label `v'
		if `"`varlabel'"' == "" local varlabel "`v'"
		_quantile `v', prob(`prob') method(`method')
		post `handle' ("`v'") ("`varlabel'") (r(n)) `call2' ("`method'")
	}
	
	postclose `handle'
	
	gettoken filename rest : saving, parse(,) 
	use "`filename'", clear 

	foreach q of local call1 { 
		gettoken char prob : prob 
		if `char' > 0 & `char' < 1 local char 0`char'
		char `q'[varname] `char'
		label var `q' "`char' quantile" 
	} 

	list, noobs subvarname `options'
	
	if `wantsave' {
		quietly compress
		display  
		save "`filename'", replace
	} 
end 

program quantilesets_g                                                        
	syntax varname(numeric) [if] [in]             ///
	, OVER(varname) Prob(numlist >=0 <=1 sort) [ Method(str) SAVING(str asis) Total  * ]  
	
	if "`method'" == "" local method "tukey"
	else { 
		capture mata : quantile((1::5), (0.25, 0.5, 0.75)', "`method'")
		if _rc { 
			di as error "invalid method argument"
			exit 198
		}
	} 

	marksample touse  
	markout `touse' `over', strok 
	
	quietly count if `touse'
	if r(N) == 0 error 2000
	if r(N) == 1 error 2001 
	
	preserve 
	quietly keep if `touse' 
	
	local varlabel : variable label `varlist'
	local gvarlabel : variable label `over' 
	
	quietly statsby , by(`over') clear `total' : ///
	_quantile `varlist', prob(`prob') method(`method')
	
	/// work-around if -group- is an existing variable name 
	if "`over'" == "group" { 
		gen groupvar = "group"
		tempname work 
		rename group `work'
		local over `work'
	}
	else gen groupvar = "`over'"
	
	quietly egen group = group(`over'), label 
	_crcslbl group `over'

	quietly if "`total'" != "" { 
		su group, meanonly 
		local gmax = r(max) + 1 
		replace group = `gmax' if group == . 
		label def group `gmax' "Total", modify 
	}
	
	rename `over' origgvar  
	
	gen varname = "`varlist'"
	gen varlabel = cond(missing("`varlabel'"), varname, "`varlabel'")
	gen gvarlabel = cond(missing("`gvarlabel'"), groupvar, "`gvarlabel'")
	gen method = "`method'"

	label var n 

	local nq : word count `prob' 
	tokenize "`prob'" 
	forval q = 1/`nq' { 
		local call `call' q`q'
		if ``q'' > 0 & ``q'' < 1 local `q' 0``q''
		char q`q'[varname] ``q''
		label var q`q' "``q'' quantile" 
	}

	order varname varlabel origgvar groupvar gvarlabel group n `call' method 
	
	list, noobs subvarname `options'

	if `"`saving'"' != "" { 
		quietly compress 
		label data 
		display 
		save `saving'
	}
end 

* the following code needs to be in a separate ado, 
* but is included here for documentation 

* 1.0.0 NJC 17 November 2025
program _quantile, rclass    
	version 19.50
	syntax varname(numeric) [if] [in] , Prob(str) Method(str)

	marksample touse

	local nq : word count `prob'
	forval q = 1/`nq' { 
		local call `call' q`q' 
	}

	mata: _qua("`varlist'", "`touse'", "`call'", "`prob'", "`method'")  
  			
    return scalar n = scalar(n)  

	forval q = 1/`nq' { 
		return scalar q`q' = scalar(q`q')
	}
end

mata : 

void _qua(
string scalar varname, 
string scalar usename, 
string scalar qnames,  
string scalar p,
string scalar method
) 
{ 
	real colvector x, results    
	real scalar n, j   

	x = st_data(., varname, usename) 
	n = length(x) 
	
	st_numscalar("n", n)  
	if (n == 0) return 

	results = quantile(x, strtoreal(tokens(p))', method) 
	qnames = tokens(qnames) 

	for (j = 1; j <= length(qnames); j++) { 
		st_numscalar(qnames[j], results'[j])
	}
}

end

