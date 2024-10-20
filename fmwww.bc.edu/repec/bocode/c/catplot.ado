*! 3.0.1 NJC 19 October 2024 
*! 3.0.0 NJC 23 September 2024 
*! 2.0.2 NJC 10 December 2010 
* 2.0.1 NJC 18 May 2010 
* 2.0.0 NJC 28 May 2010 
* 1.1.2 NJC 11 February 2004 
* 1.1.1 NJC 2 February 2004 
* 1.1.0 NJC 8 January 2004 
* 1.0.1 NJC 29 April 2003
*! 1.0.0 NJC 18 February 2003
program catplot
	version 8
	
	syntax [if] [in] [fweight aweight iweight/] ///
	, OVER1(str asis) [PERCent(varlist) PERCent2 FRaction(varlist) FRaction2   ///
	YTItle(str asis) OVER2(str asis) by(str asis) recast(str) * ]

	// which observations? 
	marksample touse
	
	Parseopt 1 `"`over1"'  
	local opt1 over(`over1')
   	markout `touse' `over1var', strok 
	
	if `"`over2'"' != ""  { 
		Parseopt 2 `"`over2"'  
		local opt2 over(`over2')
	}
	
	markout `touse' `over2var', strok 
	
	if `"`by'"' != "" { 
		Parseopt 3 `"`by'"' 
		local opt3 by(`by')
		markout `touse' `byvar', strok 
	}

	quietly count if `touse' 
	if r(N) == 0 error 2000 

	// plot type: hbar (default) or bar or dot 
	if "`recast'" != "" { 
		local plotlist "bar dot hbar" 
		if !`: list recast in plotlist' { 
			di "{p}{txt}`recast' not an allowed type, one of {cmd: `plotlist'}{p_end}" 
			exit 198 
		}
	}
	else local recast hbar 

	// any percent or fraction calculations
	local pc "`percent'" 
	local pc2 "`percent2'" 
	
	local nopts = ("`pc'" != "") + ("`pc2'" != "") 
	local nopts = `nopts' + ("`fraction'" != "" ) + ("`fraction2'" != "") 
	if `nopts' > 1 {
		di as err "percent and fraction options may not be combined"
		exit 198
	}

	local pvars `pc' `fraction' 
	local prop = cond("`fraction'`fraction2'" != "", "prop", "") 
		
	tempvar toshow 

	quietly { 
		if "`pc2'" != "" | "`fraction2'" != "" {
			local total = cond("`pc2'" != "", 100, 1)
			if "`weight'" == "" { 
				egen double `toshow' = pc(`total') if `touse', `prop' 
			} 
			else egen double `toshow' = pc(`exp') if `touse', `prop'
		} 
		else if "`pvars'" != "" {
			local total = cond("`pc'" != "", 100, 1)
			if "`weight'" == "" { 
				egen double `toshow' = pc(`total') if `touse', ///
					`prop' by(`pvars') 
			}
			else egen double `toshow' = pc(`exp') if `touse', ///
					`prop' by(`pvars') 
		} 	
		else {
			if "`weight'" == "" {
				gen `toshow' = `touse' 
			}	
			else gen double `toshow' = `touse' * (`exp') 
		} 	
	} 	

	// default y axis title 
	if `"`ytitle'"' == "" { 
		if "`pc2'`pc'" != "" { 
			local ytitle "percent" 
		} 
		else if "`fraction2'`fraction'" != "" { 
			local ytitle "fraction" 
		}	
		else if "`exp'" != "" {
			cap local explbl : var label `exp' 
			if `"`explbl'"' != "" local ytitle `""`explbl'""' 
			else local ytitle "`exp'" 
		} 
		else local ytitle "frequency" 
	}

	// draw graph 
	graph `recast' (sum) `toshow' if `touse', /// 
	`opt1' `opt2' `opt3' ytitle(`ytitle') `options' 
end

program Parseopt 
	local which = word("over1var over2var byvar", `1')
	gettoken what rest : 2, parse(" ,")
	c_local `which' "`what'" 
end 
