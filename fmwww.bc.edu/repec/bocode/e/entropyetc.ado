*! 3.0.1 NJC 17 June 2024 
*! 3.0.0 NJC 11 January 2024 
*! 2.0.2 NJC 29 June 2021 
*! 2.0.1 NJC 15 June 2020 
*! 2.0.0 NJC 5 July 2018
*! 1.0.0 NJC 20 November 2016
program entropyetc, sortpreserve    
    version 8.2
    syntax varname [if] [in] [aweight fweight/] /// 
    [, GENerate(str)  by(varlist) list Format(str) * ]
	
	if "`generate'`list'" == "" { 
		di "nothing to do"
		exit 0 
	}

	quietly { 
		marksample touse, strok  
		if "`by'" != "" markout `touse' `by', strok 
		count if `touse' 
		if r(N) == 0 error 2000 
	
		if "`by'" == "" { 
			tempvar by 
			gen byte `by' = `touse' 
			label def `by' 1 "all"
			label val `by' `by'
			char `by'[varname] " "
		}

		if "`generate'" != "" parsegenerate `generate' 
	
		tempvar freq total S p Shannon Simpson Shannon2 Simpson2 
	
		if "`exp'" == ""  local exp = 1 
	
		bysort `touse' `by' `varlist' : gen double `freq' = sum(`touse' * `exp')   
		by `touse' `by' `varlist' : replace `freq' = cond(_n == _N, `freq'[_N], .)
		by `touse' `by' `varlist' : gen `S' = cond(_n == _N, `freq'[_N] > 0, .)
		bysort `touse' `by' (`S') : replace `S' = sum(`S')
		by `touse' `by' : replace `S' = `S'[_N]
		by `touse' `by' : gen double `total' = sum(`freq')
		by `touse' `by' : replace `total' = `total'[_N] 
			
		gen double `p' = `freq' / `total'
	
		by `touse' `by': gen double `Shannon' = sum(`p' * ln(1/`p'))
		by `touse' `by': replace `Shannon' = `Shannon'[_N]
		gen double `Shannon2' = exp(`Shannon')
	
		by `touse' `by': gen double `Simpson' = sum(`p'^2)
		by `touse' `by': replace `Simpson' = `Simpson'[_N]
		gen double `Simpson2' = 1/`Simpson'
	
		label var `S'        "distinct"
		label var `Shannon'  "Shannon H" 
		label var `Shannon2' "exp(H)" 
		label var `Simpson'  "Simpson" 
		label var `Simpson2' "1/Simpson" 
			
		if "`format'" == "" local format "%4.3f"
		format `S' %1.0f 
		format `Shannon' `Shannon2' `Simpson' `Simpson2' `format'
	}	

	tokenize `S' `Shannon' `Shannon2' `Simpson' `Simpson2'   
	
	if "`list'" != "" {
		forval j = 1/5 { 
			char ``j''[varname] "`: var label ``j'''"
		}
	
		tempvar tolist 
		egen `tolist' = tag(`touse' `by')
	
		list `by' `S' `Shannon' `Shannon2' `Simpson' `Simpson2' if `touse' & `tolist', ///
		abbrev(9) subvarname noobs `options' 
	}	

	forval j = 1/5 { 
		if "`var_`j''" != "" { 
			gen `var_`j'' = ``j'' if `touse'
		}
	}

end

program parsegenerate 
	tokenize `0' 
	if "`6'" != "" { 
		di as err "generate() should specify 1 to 5 tokens" 
		exit 134 
	}

	forval j = 1/5 { 
		if "``j''" != "" { 
			gettoken no rest : `j', parse(=)  
			capture numlist "`no'", max(1) int range(>=1 <=5) 
			if _rc { 
				di as err "generate() error: ``j''"
				exit _rc 
			} 

			gettoken eqs rest : rest, parse(=) 
			confirm new var `rest' 
			c_local var_`no' "`rest'" 
		}
	}  
end 

