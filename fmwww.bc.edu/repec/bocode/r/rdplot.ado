*! NJC 2.1.0 3 November 2004
* NJC 2.0.1 4 Feb 2004
* NJC 2.0.0 26 Feb 2003
* NJC 1.0.0 15 Apr 2002
program rdplot
	// residual distribution plot 
	version 8
	syntax [anything(name=plottype)]                               ///
	[, Anscombe Deviance Likelihood Pearson Residuals              ///
	RESPonse RSTAndard RSTUdent Score Working RSCale(str)          ///
	BY(varname) AT(numlist min=1 sort) Group(numlist int >0 max=1) ///
	plot(passthru) * ]

	// plot type 
	local l = length("`plottype'")
	
	// if l is 0 because no plottype specified, defaults to -dotplot- 
	
	if substr("`plottype'",1,`l') == substr("dotplot",1,`l') { 
		if "`plot'" != "" { 
			di as err "plot() and dotplot may not be combined" 
			exit 198 
		}	
		local plottype "dotplot" 
	}
	else if substr("`plottype'",1,max(2,`l')) == ///
	        substr("histogram",1,max(2,`l')) { 
		local plottype "histogram" 
	}
	else if substr("`plottype'",1,max(2,`l')) == ///
	        substr("hbox",1,max(2,`l')) { 
		if "`plot'" != "" { 
			di as err "plot() and hbox may not be combined" 
			exit 198 
		}	
		local plottype "graph hbox" 
	}
	else if substr("`plottype'",1,`l') == substr("box",1,`l') { 
		if "`plot'" != "" { 
			di as err "plot() and box may not be combined" 
			exit 198 
		}	
		local plottype "graph box" 
	}
	else if substr("`plottype'",1,`l') == substr("onewayplot",1,`l') { 
		local plottype "onewayplot" 
	}
	else if substr("`plottype'",1,`l') == substr("skewplot",1,`l') { 
		local plottype "skewplot" 
	}
	else if substr("`plottype'",1,`l') == substr("qplot",1,`l') { 
		local plottype "qplot connected" 
	}
	else if substr("`plottype'",1,5) == substr("qplot",1,5) { 
		local plottype "`plottype'" 
	}
	else { 
		di ///
		"{p}{txt}syntax is {inp:rdplot} {it:plottype} ... " /// 
		"e.g. {inp: rdplot histogram} ...{p_end}" 
		exit 198 
	} 

	// -rscale()- option
	if "`rscale'" != "" & !index("`rscale'","X") { 
		di as err "rscale() does not contain X"
		exit 198 
	} 	

	// -egen, cut()- options, or plain -by()-  
	if "`group'" != "" & "`at'" != "" { 
		di as err "must choose between group() and at() options"
		exit 198 
	} 
	if "`group'" != "" { 
		if "`by'" == "" { 
			local by : word 1 of `e(varnames)' 
			if "`by'" == "" { 
				tempname b 
				mat `b' = e(b) 
				local by : word 1 of `: colnames `b'' 
				if "`by'" == "" { 
					di as err "no covariate names stored"
					exit 198 
				} 	
			} 	
		}
		tempvar g
		qui egen `g' = cut(`by') if e(sample), gr(`group') label
		_crcslbl `g' `by' 
	} 
	else if "`at'" != "" { 
		if "`by'" == "" {
			local by : word 1 of `e(varnames)' 
			if "`by'" == "" {
				tempname b 
				mat `b' = e(b) 
				local by : word 1 of `: colnames `b'' 
				if "`by'" == "" { 
					di as err "no covariate names stored"
					exit 198 
				} 	
			} 	
		}
		tempvar g 
		qui egen `g' = cut(`by') if e(sample), at(`at') label 
		_crcslbl `g' `by' 
	} 
	else if "`by'" != "" local g "`by'" 
	
	// choice of type of residual 
	local opts "`anscombe' `deviance' `likelihood' `pearson'"  
	local opts "`opts' `residuals' `response' `rstandard' `rstudent'"
	local opts "`opts' `score' `working'" 
	local opts = trim("`opts'") 
	
	local nopts : word count `opts' 
	if `nopts' > 1 { 
		di as err "must specify at most one type of residual" 
		exit 198 
	}
	else if `nopts' == 0 {
		if "`e(cmd)'" == "glm" local opts "response" 
		else local opts "residuals" 
	}	

	// calculation of residual 
	tempvar resid 
	quietly predict `resid' if e(sample), `opts' 
	
	// label residual variable  
	if "`opts'" == "rstudent"       local opt "Studentized"
	else if "`opts'" == "rstandard" local opt "Standardized" 
	else local opt = upper(substr("`opts'",1,1)) + substr("`opts'",2,.)
		
	if "`opts'" != "residuals" label var `resid' "`opt' residuals" 
	
	// change residual scale? 
	qui if "`rscale'" != "" {
		local lbl : variable label `resid' 
		local lbl : subinstr local rscale "X" `"`lbl'"', all 
		label var `resid' `"`lbl'"' 
		local scale : subinstr local rscale "X" "`resid'", all  
		replace `resid' = `rscale' 
	}
	
	// graph 
	if "`g'" != "" { 
		local glbl : variable label `g' 
		if "`plottype'" == "graph box" | "`plottype'" == "graph hbox" { 
			local byby `"over(`g') note("Graphs by `glbl'")"' 
		}
		else if "`plottype'" == "histogram" { 
			local byby "by(`g', col(1)) frequency"
		} 	
		else local byby "by(`g')" 
	}	

	`plottype' `resid', `byby' `options' `plot' 
end
