*! 1.2.0 NJC 29 Dec 2022
*! 1.1.0 NJC 10 Dec 2022
*! 1.0.0 NJC 30 Nov 2022
* note: tab stop = 4 spaces 
program vennbar 
	version 8.2 
	syntax varlist(numeric) ///
	[if] [in]               /// 
	[fweight aweight/]      /// 
	[,                      ///
	fillin                  ///
	percent                 ///
	pcformat(str)           ///
	varlabels               ///
	vallabels               /// 
	varlabs                 /// undocumented 
	variablelabels          /// undocumented 
	valuelabels             /// undocumented 
	SEParator(str)          ///
	recast(str)             ///  
	savedata(str asis) *] 
	
	/// syntax check 
	if "`recast'" != "" { 
		if !inlist("`recast'", "hbar", "bar", "dot") { 
			di as err "invalid recast(): must be one of hbar, bar, dot" 
			exit 198
		}
	} 

	if "`variablelabels'" != "" | "`varlabes'" != "" local varlabels "varlabels" 

	if "`valuelabels'" != "" local vallabels "vallabels" 

	local sep "`separator'" 

	quietly { 
		/// data to use and dataset preparation 
		marksample touse 

		foreach v of local varlist {
			count if `touse' & !inlist(`v', 0, 1)
			if r(N) > 0 { 
				noisily bad_data `v' 			
				exit 450 
			}
		}

		count if `touse'
		if r(N) == 0 error 2000 
	
		preserve 

		keep if `touse'
		local nvars = wordcount("`varlist'")
		egen _binary = concat(`varlist') 
		decimal `varlist' 

		if "`exp'" == "" local exp 1 
		bysort _binary : gen double _count = sum(`exp')  
		bysort _binary : keep if _n == _N 
		compress _count 
		keep `varlist' _count _decimal _binary   

		/// want to show possible subsets that did not occur 
		if "`fillin'" != "" { 
			levelsof _decimal, local(present) 
			
			local ntuples = 2^`nvars' - 1 
			numlist "0/`ntuples'" 
			local complete `r(numlist)' 
			local absent : list complete - present 

			if "`absent'" != "" {
				local n = wordcount("`absent'") 
				set obs `= _N + `n'' 

				foreach x of local absent { 
					replace _decimal = `x' in -`n' 
					inbase 2 `x'
					replace _binary = string(`r(base)', "%0`nvars'.0f") in -`n'

					forval j = 1/`nvars' { 
						replace ``j'' = real(substr(_binary, `j', 1)) in -`n'
					} 
				
					local --n 
				} 

				replace _count = 0 if missing(_count)
			}  
		} 

		if "`percent'" != "" { 
			su _count, meanonly 
			gen _percent = 100 * _count / r(sum)
			if "`pcformat'" == "" local pcformat "%2.1f"
			format _percent `pcformat' 
			local pcshow _percent 
			local yvar _percent 
			gen _pcshow = strofreal(_percent, "`pcformat'") 
		} 
		else { 
			local yvar _count
		}
	
        /// text defaults to varnames, 
		/// optionally to variable labels if defined. 		
		/// optionally to value labels (values if not defined) 
		/// default separator is ", " 
		gen _text = "" 
		tokenize "`varlist'" 
		if "`sep'" == "" local sep = ", " 
		local lensep = length("`sep'")  

		if "`vallabels'" != "" { 
			forval j = 1/`nvars' { 
				replace _text = _text + "`: label (``j'') 0'`sep'" if substr(_binary, `j', 1) == "0" 
				replace _text = _text + "`: label (``j'') 1'`sep'" if substr(_binary, `j', 1) == "1" 
			}
		} 

		else forval j = 1/`nvars' {
			local label : var label ``j''
			if "`varlabels'" != "" & `"`label'"' != "" & `j' < `nvars' {
				replace _text = _text + `"`label'`sep'"' if substr(_binary, `j', 1) == "1"
			} 
 			else if "`varlabels'" != "" & `"`label'"' != "" & `j' == `nvars' {
				replace _text = _text + `"`label'"' if substr(_binary, `j', 1) == "1"
			}
 			else if `j' < `nvars' {
				replace _text = _text + "``j''`sep'" if substr(_binary, `j', 1) == "1"
			} 
			else replace _text = _text + "``j''" if substr(_binary, `j', 1) == "1" 
		} 

		replace _text = "<none>" if missing(_text) 
		replace _text = substr(_text, 1, length(_text) - `lensep') if substr(_text, -`lensep', .) == "`sep'" 

		gen _degree = length(_binary) - length(subinstr(_binary, "1", "", .)) 
	} 

	/// list major part 
	sort _decimal 
	list _binary _decimal _text _count `pcshow' _degree, noobs sep(0)

	quietly {
 		/// we may need to create extra observations to show set frequencies;
		/// if we do, best to drop them before graphics 
		local N = _N 
		if `nvars' >= _N set obs `nvars'
	
		gen _set = ""
		gen double _setfreq = . 

		forval j = 1/`nvars' { 
			if "`varlabels'" != "" { 
				local label : var label ``j'' 
				if `"`label'"' == "" replace _set = "``j''" in `j' 
				else replace _set = `"`label'"' in `j' 
			} 
			else replace _set = "``j''" in `j' 

			summarize _count if substr(_binary, `j', 1) == "1", meanonly 
			replace _setfreq = r(sum) in `j' 
		}

		compress _setfreq
	} 

	/// list minor part 
	list _set _setfreq if _set != "", noobs sep(0)  

	/// save dataset if requested 
	if `"`savedata'"' != "" save `savedata' 
 
	/// graph
	quietly keep in 1/`N'  
 
	local plot = cond("`recast'" == "", "hbar", "`recast'") 

	if !strpos(`"`options'"', "over(") { 
		local options `options' over(_text, sort(_count) descending)
	} 
 
	graph `plot' (asis) `yvar', `options'
end

program bad_data
	args v 
	di  
	di "{p}The variable `v' contains values that are not 0 or 1. " /// 
	"You may wish to exclude them, or to recode, or to reconsider. " ///
	"{cmd:vennbar} is for binary indicators only.{p_end}"
end 


/// essence of _gdecimal from -egenmore- on SSC 
/// original 1.0.0 NJC 26 Oct 2001
program decimal  
	version 8.2
	syntax varlist(numeric min=1)  
	local g _decimal 
	local nvars : word count `varlist'  
	tokenize `varlist' 

	quietly {
		gen long `g' = 0  
		forval i = 1/`nvars' { 
			local power = `nvars' - `i'  
			replace `g' = `g' + ``i'' * 2^`power' 
		} 	
		compress `g' 
	}
end


