*! 1.1.0 NJC 24 August 2026
*! 1.0.0 NJC 5 March 2004 
program ppplot, sort 
    * addplot() requires version 9 up 
	version 8.0

	gettoken plottype 0 : 0 
	local plotlist "area bar connected dot dropline line scatter spike" 
	if !`: list plottype in plotlist' { 
		di ///
		"{p}{txt}syntax is {cmd:ppplot} {it:plottype} ... " /// 
		"... e.g. {cmd: ppplot connected} ...{p_end}" 
		exit 198 
	}

	capture syntax varname [if] [in] [fweight aweight/], BY(varname)  ///
	[ MISSing REFerence(str asis) PLOT(str asis) ADDPLOT(str asis) * ]

	if _rc { 
		syntax varlist(min=2 numeric) [if] [in] [fweight aweight/] ///
		[, PLOT(str asis) ADDPLOT(str asis) BY(varname) * ] 
		
		if "`by'" != "" { 
			di as err "by() not supported with two or more variables"
			exit 198 
		}
	}	
	
	marksample touse
	
	if "`exp'" == "" local exp "1" 
	else {
		capture assert `exp' >= 0 
		if _rc {
			di as err "weight assumes negative values"
			exit 402
	    }    
	}
	
	preserve 
	
	local defaultlabel `" 0 "0" 0.25 "0.25" 0.5 "0.5" 0.75 "0.75" 1 "1" "'
	
	quietly {
		
		if "`by'" != "" {
			if "`missing'" == "" markout `touse' `by', strok 
			keep if `touse'
			tempname stub 
			separate `varlist', by(`by') gen(`stub') `missing' short
			local vlist "`r(varlist)'"
			
			local ref `"`reference'"' 
			if `"`ref'"' != "" { 
				foreach v of local vlist {  
					count if `by' == `ref' & `v' == `varlist' 
					if `r(N)' { 
						local x "`v'" 
						continue, break 
					} 	
				} 
				local vlist : subinstr local vlist "`x'" "" 
				local vlist "`vlist' `x'" 
			}	
		
			sort `varlist' 
		
			foreach v of local vlist {
				local label : variable label `v' 
				local where = index(`"`label'"', "==") + 3
				local label = substr(`"`label'"', `where', .) 
				label var `v' `"`label'"' 
				format `v' %2.1g 
				replace `v' = sum(`exp' * (`v' < .)) 
				by `varlist' : replace `v' = `v'[_N] 
				replace `v' = `v' / `v'[_N]
			}   

			noisily twoway `plottype' `vlist', ///
			yla(`defaultlabel', ang(h)) xla(`defaultlabel') `options' ///
			|| `plot' ///
			|| `addplot' 
			// blank 
			
			exit 0 
		}
		else { 
			tempvar data wt 

			tokenize `varlist' 
			local nvars : word count `varlist' 
			forval i = 1/`nvars' { 
				local label`i' : variable label ``i'' 
				if `"`label`i''"' == "" local label`i' "``i''" 
			}	

			gen double `wt' = `exp' 

			foreach v of local varlist { 
				local tostack "`tostack' `v' `wt'" 
			} 	
			
			stack `tostack' if `touse', into(`data' `wt') clear 
			separate `data', by(_stack) 
			local vlist "`r(varlist)'" 
			sort `data' 
		
			local i = 1 
			foreach v of local vlist { 
				label var `v' `"`label`i''"' 
				format `v' %2.1g 
				replace `v' = sum(`wt' * (`v' < .)) 
				by `data' : replace `v' = `v'[_N] 
				replace `v' = `v' / `v'[_N]
				local ++i 
			}   

			noisily twoway `plottype' `vlist', /// 
			yla(`defaultlabel', ang(h)) xla(`defaultlabel') `options' ///
			|| `plot' ///
			|| `addplot'
			// blank 
		}
	}		
end
