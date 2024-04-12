*! 1.2.0 Ariel Linden 10Apr2024 // fixed trperiod() to allow the user to enter a pseudofunction datetime e.g. (20jan1988)
*! 1.1.0 Ariel Linden 21Nov2017 // Added local()option
*! 1.0.0 Ariel Linden 21October2017

capture program drop itsamatch
program define itsamatch, rclass
version 11.0

	/* obtain settings */
	syntax varlist(min=1 numeric ts fv) [if] [in] [aweight] ,	/// weight only relevant for -newey-
	TRPeriod(string)											///     
	TREATid(numlist min=1 max=1 int sort)						///
	[ Pr(numlist max=1 >0 <1)									/// 
	LAG(int -1)													/// lag only relevant for -newey-
	PRAIS														///
	Local(str)													/// macro that can be used in -itsa-
	* ]
								
	preserve
	quietly {

		marksample touse
		count if `touse'
		if r(N) == 0 error 2000
		local N = r(N)
		replace `touse' = -`touse'

		/* check if data is tsset with panel and time var */
		/* -tsset- errors out if no time variable set */
		tsset
		local tvar `r(timevar)'
		local pvar `r(panelvar)'
		loc tsf `r(tsfmt)'
		* check format of date
		if substr("`tsf'",2,1) == "t" {
			local tsfr = substr("`tsf'",1,3)
			local period = lower(substr("`tsf'", 3, 1))
		}
		else local tsfr `tsf'
		
		local cnt: word count `trperiod'
		if `cnt' > 1 {
			di as err "{p}Only one treatment period can be specified{p_end}"
			exit 198			
		}
		
		/* parse dates in trperiod() */
		tokenize "`trperiod'", parse(";")
		local done = 0
		local i = 0
		local count = 0
		while !`done' {  
			local ++i
			local next = "``i''"
			local done = ("`next'" == "")
			// keep dates only (exclude semicolon)
			if ("`next'" != ";") & (!`done') {
				local ++count
				local trp`count' = `period'(`next') 
				local trp `trp' `trp`count''
				local trperiod2 `trp'
			}  // end if
		} // end while
		
		/* check if trperiod is among tvars */
		levelsof `tvar' if `touse', local(levt)
		if !`: list trperiod2 in levt' {
			di as err "{p}Treatment period not found in the time variable: check {bf:trperiod()} to ensure that the date is specified correctly{p_end}"
			exit 198
		}
		
		/* check if treatid is among pvars */
		levelsof `pvar' if `touse', local(pevt)
		if ! `: list treatid in pevt' {
			di as err "treatid(`treatid') is not found in the `pvar' variable"
			exit 498
		}
	
		// Parse varlist and generate _z and _zt variables
		tokenize `varlist'
		local varcount : word count `varlist'
	
		foreach var of varlist `varlist'  {
			gen _z`var' =.
			gen _zt`var' =.
			local clist `clist' _z`var' _zt`var'
		}

		// Get unique levels of the panel (group) variable 
		tab `pvar' if `touse'
		local num = r(r) - 1
		levelsof `pvar' if `touse', local(levels)

	} // end quietly	

		// setup for dots
		di _n
		di as txt "Iterating across (" as res `num' as txt ") panels (`pvar') "
		di as txt "{hline 4}{c +}{hline 3} 10 " "{hline 3}{c +}{hline 3} 20 " "{hline 3}{c +}{hline 3} 30 " "{hline 3}{c +}{hline 3} 40 " "{hline 3}{c +}{hline 3} 50 "


		tempname B C D OPT contid rowmin
		
		// loop thru -itsa- for each panel within each variable of varlist
		foreach num of local levels {
			_dots `varcount' 0
			foreach var of varlist `varlist'  {
				
				if `num' != `treatid' {
		
			qui {
					if "`prais'" != "" { 
						itsa `var' if `touse', treat(`treatid') trp(`trperiod') cont(`num') replace prais `options'
					}
				else itsa `var' if `touse' [`weight' `exp'], treat(`treatid') trp(`trperiod') cont(`num') lag(`lag') replace `options'
			
				mat `B' = r(table)
				mat `C' = `B'["pvalue","_z"]
				mat `D' = `B'["pvalue","_z_t"]
				replace _z`var' = trace(`C') if `pvar' == `num'	
				replace _zt`var' = trace(`D') if `pvar' == `num'
			} // !treatid
				} //qui
			} //foreach var
		} //foreach num

	// Collapse _z and _zt variables by panel, and compute minimum row value 
	collapse `clist' if `pvar' !=`treatid' & `touse', by(`pvar')
	egen `rowmin' =rowmin(`clist')
	
	// make a matrix of values for those panels exceeding the specified p-value cutoff
	mkmat `pvar' `clist' if `rowmin' > `pr' , matrix(`OPT')
	
	//make a matrix of just the control IDs
	mat `contid' = `OPT'[1..., 1]'
			
	//make a c_local macro of control IDs that can be used within -itsa-
	if "`local'" != "" {
		forval i = 1/`=colsof(`contid')' {
			local Y `Y'  `=`contid'[1,`i']'
			}
		c_local `local' `"`Y'"'  
	}
	
	restore
	
	// show results 
	di _n
	matlist `OPT', names(col)
	// save control IDs in matrix format
	return matrix contids = `contid' 

end
