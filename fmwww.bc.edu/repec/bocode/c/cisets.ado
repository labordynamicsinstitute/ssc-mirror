*! 1.1.2 NJC 31 October 2024
* 1.1.1 NJC 26 October 2024
* 1.1.0 NJC 25 October 2024 
* 1.0.0 NJC 21 October 2024 
program cisets
	version 14.1 
	
	gettoken subcmd 0 : 0 
	
	if substr("`subcmd'", 1, 4) == "mean" { 
		_mean `0'
	}
	else if substr("`subcmd'", 1, 4) == "prop" {
		_prop `0'
	}
	else if substr("`subcmd'", 1, 3) == "var" {
		_var `0'
	}
	else if "`subcmd'" == "gmean" { 
		_gmean `0'
	}
	else if "`subcmd'" == "hmean" { 
		_hmean `0'
	}
	else if "`subcmd'" == "centile" {
		_centile `0'
	}
	else { 
		display as err "did not understand subcommand `subcmd'"
		exit 198 
	}

end 

* I guess shorter code would be entirely possible with more programs, 
* but it might be harder to follow the flow. 
* In essence, once each statistic -whatever- is chosen the 
* default program _whatever loops over or more variables using 
* -postfile- to assemble a confidence interval set.
* But if -over()- is specified, we branch off to program _whatever_g 
* which handles groups of observations using -statsby-. 

* Here we keep a record of which weights are allowed. 
* mean            aweight (if normal), fweight 
* proportion      fweight 
* variance / SD   fweight
* geometric mean  aweight, fweight 
* harmonic mean   aweight, fweight 
* centile         none 

program _mean 
	capture syntax varname(numeric) [if] [in] [aweight fweight]      ///
	, OVER(varname) [ SAVING(str asis) Level(integer $S_level) Total ///
	POISson EXPosure(passthru) * ]   
			
	if _rc == 0  {
 		if "`weight'" == "aweight" & "`poisson'`exposure'" != "" {
			display as err "aweights not allowed for Poisson means"
			exit 101 
		}

		_mean_g `0'
		exit 0  
	}
	
	syntax varlist(numeric) [if] [in] [aweight fweight] ///
	[, SAVING(str asis) Level(integer $S_level)        ///
	POISson EXPosure(passthru) ALLobs inclusive cw * ]   
	
	if "`weight'" == "aweight" & "`poisson'`exposure'" != "" {
		display as err "aweights not allowed for Poisson means"
		exit 101 
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
	
	tempname handle 
	postfile `handle' str32 varname str80 varlabel n point se lb ub using `saving'
	
	quietly foreach v of local varlist {
	    local varlabel : var label `v'
		if `"`varlabel'"' == "" local varlabel "`v'"
		ci means `v', `poisson' `exposure'
		post `handle' ("`v'") ("`varlabel'") (r(N)) (r(mean)) (r(se)) (r(lb)) (r(ub)) 
	}
	
	postclose `handle'
	
	gettoken filename rest : saving, parse(,) 
	use "`filename'", clear 
	gen level = `level'
	gen statname = "mean"

	if "`poisson'`exposure'" != "" {
		gen options = trim("`poisson' `exposure'")
	}
	
	if "`weight'" != "" gen weight = "`weight' `exp'"
	
	order varname varlabel n statname point se lb ub level 
	list, noobs `options'
	
	if `wantsave' {
		display  
		quietly compress
		save "`filename'", replace
	} 
end 

program _mean_g 
	syntax varname(numeric) [if] [in] [aweight fweight]              ///
	, OVER(varname) [ SAVING(str asis) Level(integer $S_level) Total ///
	POISson EXPosure(passthru) * ]   

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
	ci means `varlist' [`weight' `exp'], `poisson' `exposure' level(`level')
	
	quietly egen group = group(`over'), label 
	_crcslbl group `over'

	quietly if "`total'" != "" { 
		su group, meanonly 
		local gmax = r(max) + 1 
		replace group = `gmax' if group == . 
		label def group `gmax' "Total", modify 
	}
	
	rename (`over' N mean) (origgvar n point) 
	
	gen varname = "`varlist'"
	gen varlabel = cond(missing("`varlabel'"), varname, "`varlabel'")
	gen groupvar = "`over'"
	gen gvarlabel = cond(missing("`gvarlabel'"), groupvar, "`gvarlabel'")
	gen statname = "mean"
	
	if "`poisson'`exposure'" != "" {
		gen options = trim("`poisson' `exposure'")
	}
	
	if "`weight'" != "" gen weight = "`weight' `exp'"
	
	foreach v in n point se ub lb level {
		label var `v' 
	}

	order varname varlabel origgvar groupvar gvarlabel group n statname point se lb ub level 
	list, noobs `options'

	if `"`saving'"' != "" { 
		label data 
		display 
		quietly compress 
		save `saving'
	}
end 

program _prop 
    capture syntax varname(numeric) [if] [in] [fweight]              ///
	, OVER(varname) [ SAVING(str asis) Level(integer $S_level) Total ///
	exact wald wilson AGRESti JEFFreys * ]   
	
	if _rc == 0 { 
		_prop_g `0'
		exit 0
	}
	
	syntax varlist(numeric) [if] [in] [fweight]  ///
	[, SAVING(str asis) Level(integer $S_level) ///
	exact wald wilson AGRESti JEFFreys ALLobs inclusive cw * ]  
	
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

	tempname handle 
	postfile `handle' str32 varname str80 varlabel n point se lb ub using `saving'
	
	local bad = 0 
	local nv : word count `varlist'
	
	quietly foreach v of local varlist {
		count if !(inlist(`v', 0, 1) | missing(`v'))
		if r(N) { 
			local flag `flag' `v'
			local ++bad 
			continue 
		}
		local varlabel : var label `v'
		if `"`varlabel'"' == "" local varlabel "`v'"
		ci prop `v', `exact' `wald' `wilson' `agresti' `jeffreys'
		post `handle' ("`v'") ("`varlabel'") (r(N)) (r(mean)) (r(se)) (r(lb)) (r(ub)) 
	}
		
	postclose `handle'
	
	noisily if "`flag'" != "" {
		display _n "{p}" plural(`bad', "variable") " ignored: `flag'{p_end}"
		display "{p}(0, 1) binary variables are needed for confidence intervals for proportions{p_end}"
		if `bad' == `nv' exit 450
	}
	
	gettoken filename rest : saving, parse(,) 
	use "`filename'", clear 
	gen level = `level'
	gen statname = "proportion"
	
	if "`exact'`wald'`wilson'`agresti'`jeffreys'" != "" {
		gen options = trim("`exact' `wald' `wilson' `agresti' `jeffreys'") 
	}
	
	if "`weight'" != "" gen weight = "`weight' `exp'"
	
	order varname varlabel n statname point se lb ub level 
	list, noobs `options'

	if `wantsave' {
		display
		quietly compress 
		save "`filename'", replace
	}
end 

program _prop_g 
    syntax varname(numeric) [if] [in] [fweight]                       ///
	, OVER(varname) [ SAVING(str asis) Level(integer $S_level) Total  ///
	exact wald wilson AGRESti JEFFreys * ]   
	
	marksample touse  
	markout `touse' `over', strok 
	
	quietly count if `touse'
	if r(N) == 0 error 2000
	if r(N) == 1 error 2001 
	
	preserve 
	quietly keep if `touse' 
	
	quietly count if !inlist(`varlist', 0, 1) 
	
	if r(N) { 
		noisily display _n "{p}(0, 1) binary variables are needed for confidence intervals for proportions{p_end}"
		exit 450
	}
	
	local varlabel : variable label `varlist'
	local gvarlabel : variable label `over' 
	
	quietly statsby , by(`over') clear `total' : ///
	ci prop `varlist' [`weight' `exp'],  level(`level') `exact' `wald' `wilson' `agresti' `jeffreys'
	
	quietly egen group = group(`over'), label 
	_crcslbl group `over'
	
	quietly if "`total'" != "" { 
		su group, meanonly 
		local gmax = r(max) + 1 
		replace group = `gmax' if group == . 
		label def group `gmax' "Total", modify 
	}

	rename (`over' N mean) (origgvar n point)
	drop proportion 
	
	gen varname = "`varlist'"
	gen varlabel = cond(missing("`varlabel'"), varname, "`varlabel'")
	gen groupvar = "`over'"
	gen gvarlabel = cond(missing("`gvarlabel'"), groupvar, "`gvarlabel'")
	gen statname = "proportion"
	
	if "`exact'`wald'`wilson'`agresti'`jeffreys'" != "" {
		gen options = trim("`exact' `wald' `wilson' `agresti' `jeffreys'") 
	}
	
	if "`weight'" != "" gen weight = "`weight' `exp'"
	
	foreach v in n point se ub lb level {
		label var `v' 
	}

	order varname varlabel origgvar groupvar gvarlabel group n statname point se lb ub level 
	list, noobs `options'
	
	if `"`saving'"' != "" { 
		label data 
		display 
		quietly compress
		save `saving'
	} 
end 

program _var
    capture syntax varname(numeric) [if] [in] [fweight]    ///
	, OVER(varname) [ SAVING(str asis) Level(integer $S_level) Total SD BONett * ]   
	
	if _rc == 0 {
		_var_g `0'
		exit 0
	}
	
	syntax varlist(numeric) [if] [in] [fweight]    ///
	[, SAVING(str asis) Level(integer $S_level) SD BONett ALLobs inclusive cw * ]  
	
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
	
	tempname handle 
	postfile `handle' str32 varname str80 varlabel n point lb ub using `saving'
	
	local which = cond("`sd'" != "", "sd", "Var")
	
	quietly foreach v of local varlist {
		local varlabel : var label `v'
		if `"`varlabel'"' == "" local varlabel "`v'"
		ci var `v' [`weight' `exp'],  level(`level') `sd'`bonett'
		post `handle' ("`v'") ("`varlabel'") (r(N)) (r(`which')) (r(lb)) (r(ub)) 
	}
	
	postclose `handle'
	
	gettoken filename rest : saving, parse(,) 
	use "`filename'", clear 
	gen level = `level'
	gen statname = cond("`sd'" != "", "SD", "variance")
		
	if "`sd'`bonett'" != "" {
		gen options = trim("`sd' `bonett'") 
	}
	
	if "`weight'" != "" gen weight = "`weight' `exp'"
	
	order varname varlabel n statname point lb ub level 
	list, noobs `options'
	
	if `wantsave' {
		display 
		quietly compress 
		save "`filename'", replace
	}
end 

program _var_g 
    syntax varname(numeric) [if] [in] [fweight]                       ///
	, OVER(varname) [ SAVING(str asis) Level(integer $S_level) Total  ///
	SD BONett * ]   
	
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
	ci var `varlist' [`weight' `exp'],  level(`level') `sd' `bonett'

	quietly egen group = group(`over'), label 
	_crcslbl group `over'

	quietly if "`total'" != "" { 
		su group, meanonly 
		local gmax = r(max) + 1 
		replace group = `gmax' if group == . 
		label def group `gmax' "Total", modify 
	}
		
	local which = cond("`sd'" != "", "sd", "Var")
	if "`sd'" != "" drop Var
	drop Var_se 
	rename (`over' N `which') (origgvar n point)
	
	gen varname = "`varlist'"
	gen varlabel = cond(missing("`varlabel'"), varname, "`varlabel'")
	gen groupvar = "`over'"
	gen gvarlabel = cond(missing("`gvarlabel'"), groupvar, "`gvarlabel'")
	gen statname =  cond("`sd'" == "sd", "SD", "variance")
	
	if "`sd'`bonett'" != "" {
		gen options = trim("`sd' `bonett'") 
	}
	
	if "`weight'" != "" gen weight = "`weight' `exp'"
	
	foreach v in n point ub lb level {
		label var `v' 
	}

	order varname varlabel origgvar groupvar gvarlabel group n statname point lb ub level
	list, noobs `options'

	if `"`saving'"' != "" { 
		label data
		display 
		quietly compress 
		save `saving'
	}
end 
	
program _gmean 
	capture syntax varname(numeric) [if] [in] [aweight fweight]      ///
	, OVER(varname) [ SAVING(str asis) Level(integer $S_level) Total ///
	overasis * ]   
	
	if _rc == 0 { 
		_gmean_g `0'
		exit 0 
	} 
	
	syntax varlist(numeric) [if] [in] [aweight fweight]    ///
	[, SAVING(str asis) Level(integer $S_level) ALLobs inclusive cw * ]   
	
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

	tempname handle 
	postfile `handle' str32 varname str80 varlabel n point lb ub using `saving'
	
	quietly foreach v of local varlist {
		local varlabel : var label `v'
		if `"`varlabel'"' == "" local varlabel "`v'"
		ameans `v' [`weight' `exp'],  level(`level') 
		post `handle' ("`v'") ("`varlabel'") (r(N_pos)) (r(mean_g)) (r(lb_g)) (r(ub_g)) 
		if r(N) > r(N_pos) local flag `flag' `v'
	}
	
	postclose `handle'
	
	if "`flag'" != "" { 
		noisily display _n "{p}note: zero or negative values on `flag' ignored{p_end}"
	}
	
	gettoken filename rest : saving, parse(,) 
	use "`filename'", clear 
	gen level = `level'
	gen statname = "geometric mean"
	
	if "`weight'" != "" gen weight = "`weight' `exp'"
		
	order varname varlabel n statname point lb ub level 
	list, noobs `options'
	
	if `wantsave' {
		display 
		quietly compress 
		save "`filename'", replace
	}
end 

program _gmean_g 
	syntax varname(numeric) [if] [in] [aweight fweight]              ///
	, OVER(varname) [ SAVING(str asis) Level(integer $S_level) Total * ]   

	marksample touse  
	markout `touse' `over', strok 
	
	quietly count if `touse'
	if r(N) == 0 error 2000
	if r(N) == 1 error 2001 
	
	preserve 
	quietly keep if `touse' 
	
	qui count if `varlist' <= 0 
	if r(N) {
		noisily display "`r(N)' values of `varlist' zero or negative; will be ignored"
	}
	
	local varlabel : variable label `varlist'
	local gvarlabel : variable label `over' 
	
	quietly statsby , by(`over') clear `total' : ///
	ameans `varlist' [`weight' `exp'], level(`level')
	
	drop N mean lb ub *_h Var* 

	quietly egen group = group(`over'), label 
	_crcslbl group `over'
	
	quietly if "`total'" != "" { 
		su group, meanonly 
		local gmax = r(max) + 1 
		replace group = `gmax' if group == . 
		label def group `gmax' "Total", modify 
	}
	
	rename (`over' N_pos mean_g lb_g ub_g) (origgvar n point lb ub)
	
	gen varname = "`varlist'"
	gen varlabel = cond(missing("`varlabel'"), varname, "`varlabel'")
	gen groupvar = "`over'"
	gen gvarlabel = cond(missing("`gvarlabel'"), groupvar, "`gvarlabel'")
	gen statname = "geometric mean"
	
	if "`weight'" != "" gen weight = "`weight' `exp'"
	
	foreach v in n point ub lb level {
		label var `v' 
	}
	
	order varname varlabel origgvar groupvar gvarlabel group n statname point lb ub level 
	list, noobs `options'
	
	if `"`saving'"' != "" { 
		label data 
		display 
		quietly compress 
		save `saving'
	}
end 

program _hmean 
	capture syntax varname(numeric) [if] [in] [aweight fweight]      ///
	, OVER(varname) [ SAVING(str asis) Level(integer $S_level) Total * ]   
	
	if _rc == 0 { 
		_hmean_g `0'
		exit 0 
	}
	
	syntax varlist(numeric) [if] [in] [aweight fweight] ///
	[, SAVING(str asis) Level(integer $S_level) ALLobs inclusive cw * ]   
	
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

	tempname handle 
	postfile `handle' str32 varname str80 varlabel n point lb ub using `saving'
	
	quietly foreach v of local varlist {
		local varlabel : var label `v'
		if `"`varlabel'"' == "" local varlabel "`v'"
		ameans `v' [`weight' `exp'],  level(`level') 
		post `handle' ("`v'") ("`varlabel'") (r(N_pos)) (r(mean_h)) (r(lb_h)) (r(ub_h)) 
		if r(N) > r(N_pos) local flag `flag' `v'
	}
	
	postclose `handle'
	
	if "`flag'" != "" { 
		noisily display _n "{p}note: zero or negative values on `flag' ignored{p_end}"
	}
	
	gettoken filename rest : saving, parse(,) 
	use "`filename'", clear 
	gen level = `level'
	gen statname = "harmonic mean"
	
	if "`weight'" != "" gen weight = "`weight' `exp'"
		
	order varname varlabel n statname point lb ub level 
	list, noobs `options'
	
	if `wantsave' {
		display  
		quietly compress 
		save "`filename'", replace
	}
end 

program _hmean_g 
	syntax varname(numeric) [if] [in] [aweight fweight]                  ///
	, OVER(varname) [ SAVING(str asis) Level(integer $S_level) Total * ]   

	marksample touse  
	markout `touse' `over', strok 
	
	quietly count if `touse'
	if r(N) == 0 error 2000
	if r(N) == 1 error 2001 
	
	preserve 
	quietly keep if `touse' 
	
	qui count if `varlist' <= 0 
	if r(N) {
		noisily display "`r(N)' values of `varlist' zero or negative; will be ignored"
	}
	
	local varlabel : variable label `varlist'
	local gvarlabel : variable label `over' 
	
	quietly statsby , by(`over') clear `total' : ///
	ameans `varlist' [`weight' `exp'], level(`level')
	
	drop N mean lb ub *_g Var* 

	quietly egen group = group(`over'), label 
	_crcslbl group `over'

	quietly if "`total'" != "" { 
		su group, meanonly 
		local gmax = r(max) + 1 
		replace group = `gmax' if group == . 
		label def group' `gmax' "Total", modify 
	}
	
	rename (`over' N_pos mean_h lb_h ub_h) (origgvar n point lb ub)
	
	gen varname = "`varlist'"
	gen varlabel = cond(missing("`varlabel'"), varname, "`varlabel'")
	gen groupvar = "`over'"
	gen gvarlabel = cond(missing("`gvarlabel'"), groupvar, "`gvarlabel'")
	gen statname = "harmonic mean"
	
	if "`weight'" != "" gen weight = "`weight' `exp'"
	
	foreach v in n point ub lb level {
		label var `v' 
	}
	
	order varname varlabel origgvar groupvar gvarlabel group n statname point lb ub level 
	list, noobs `options'

	if `"`saving'"' != "" { 
		label data 
		display 
		quietly compress 
		save `saving'
	}
end 

program _centile
	capture syntax varname(numeric) [if] [in]                        ///
	, OVER(varname) [ SAVING(str asis) Level(integer $S_level) Total ///
	Centile(numlist max=1 >0 <100)  CCi Normal Meansd * ]   
	
	if _rc == 0 { 
		_centile_g `0'
		exit 0
	} 
	
	syntax varlist(numeric) [if] [in]            ///
	[ , SAVING(str asis) Level(integer $S_level) ///   
	Centile(numlist max=1 >0 <100)  CCi Normal Meansd ALLobs inclusive cw * ]   
	
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

	tempname handle 
	postfile `handle' str32 varname str80 varlabel n point lb ub using `saving'
	
	if "`centile'" == "" local centile 50 
	
	quietly foreach v of local varlist {
		local varlabel : var label `v'
		if `"`varlabel'"' == "" local varlabel "`v'"
		centile `v', centile(`centile') level(`level') `cci' `normal' `meansd'
		post `handle' ("`v'") ("`varlabel'") (r(N)) (r(c_1)) (r(lb_1)) (r(ub_1))
	}
	
	postclose `handle'
	
	gettoken filename rest : saving, parse(,) 
	use "`filename'", clear 
	gen level = `level'
	gen statname = "`centile' pctile"
	
	if "`cci'`normal'`meansd'" != "" { 
		gen options = trim("`cci' `normal' `meansd'")
	}
		
	order varname varlabel n statname point lb ub level 
	list, noobs `options'
	
	if `wantsave' {
		display 
		quietly compress 
		save "`filename'", replace
	}
end 

program _centile_g 
	syntax varname(numeric) [if] [in]                                ///
	, OVER(varname) [ SAVING(str asis) Level(integer $S_level) Total ///
	Centile(numlist max=1 >0 <100)  CCi Normal Meansd * ]   

	marksample touse  
	markout `touse' `over', strok 
	
	quietly count if `touse'
	if r(N) == 0 error 2000
	if r(N) == 1 error 2001 
	
	preserve 
	quietly keep if `touse' 
		
	local varlabel : variable label `varlist'
	local gvarlabel : variable label `over' 
	
	if "`centile'" == "" local centile 50 
	
	quietly statsby , by(`over') clear `total' :       ///
	centile `varlist', centile(`centile') level(`level') ///
	`cci' `normal' `meansd'
		
	quietly egen group = group(`over'), label 
	_crcslbl group `over'

	quietly if "`total'" != "" { 
		su group, meanonly 
		local gmax = r(max) + 1 
		replace group = `gmax' if group == . 
		label def group `gmax' "Total", modify 
	}
	
	drop n_cent 
	rename (`over' N c_1 lb_1 ub_1) (origgvar n point lb ub)
	
	gen varname = "`varlist'"
	gen varlabel = cond(missing("`varlabel'"), varname, "`varlabel'")
	gen groupvar = "`over'"
	gen gvarlabel = cond(missing("`gvarlabel'"), groupvar, "`gvarlabel'")
	gen statname = "`centile' pctile"
	gen level = `level'
	
	if "`cci'`normal'`meansd'" != "" { 
		gen options = trim("`cci' `normal' `meansd'")
	}
	
	foreach v in n point ub lb level {
		label var `v' 
	}
	
	order varname varlabel origgvar groupvar gvarlabel group n statname point lb ub level 
	list, noobs `options'
	
	if `"`saving'"' != "" { 
		label data 
		display  
		quietly compress 
		save `saving'
	} 
end 
	
