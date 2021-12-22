*! rqrplot 1.0.0 05oct2021 Nicolai T. Borgen 

program define rqrplot, rclass

	version 12 
	syntax [, twopts(string asis) level(string asis) bopts(string asis) 	///
		ciopts(string asis) NODRAW NOTABOUT NOCI bootstrap(string asis)]	
	
	if substr(e(cmdline),1,9)=="bootstrap" {
		if e(cmdname)!="rqr" {
			di as error "Previous command not rqr"
			exit 198
		}
	}
	if substr(e(cmdline),1,9)!="bootstrap" {
		if substr(e(cmdline),1,3)!="rqr" {
			di as error "Previous command not rqr"
			exit 198
		}
	}
	
	if substr(e(cmdline),1,9)!="bootstrap" & "`bootstrap'"!="" {
	    di as error "RQR model not estimated with bootstrap prefix"
		exit 198
	}

	if ("`bootstrap'"!="" & "`bootstrap'"!="normal") & "`level'"!="" {
		di as error "bootstrap(`bootstrap') option cannot be combined with level() option."
		di as error "Re-run the rqr command with the chosen level() option in the bootstrap"
		di as error "prefix before using rqrplot (e.g., bootstrap, reps(100) level(70): rqr...)"
		exit 198
	}
	
	local treat=e(treatment)

	if "`level'"!="" local level=(1-(`level'/100))/2
	if "`level'"=="" local level .025
	
	if substr(e(cmdline),1,9)!="bootstrap" local crit=invttail(e(df_r),`level')
	if substr(e(cmdline),1,9)=="bootstrap" local crit=invnormal(`level')*-1
	

	tempvar Q b se cil ciu plotmat plotout
	
	qui {
			
		gen `Q'=.
		gen `b'=.
		gen `se'=.
		gen `cil'=.
		gen `ciu'=.
		
		lab var `Q' "Quantile"
			
		local nquantiles=rowsof(e(quantiles))
		forvalues i=1/`nquantiles' {
			local q=e(quantiles)[`i',1]
			
			replace `Q'=`q' in `i'/`i'
			replace `b'=e(b)["y1","Q`q':`treat'"] in `i'/`i'
			replace `se'=sqrt(e(V)["Q`q':`treat'","Q`q':`treat'"]) in `i'/`i'
			
			if substr(e(cmdline),1,9)!="bootstrap" {
				replace `cil'=`b'[`i']-(`crit'*sqrt(e(V)["Q`q':`treat'","Q`q':`treat'"])) in `i'/`i'
				replace `ciu'=`b'[`i']+(`crit'*sqrt(e(V)["Q`q':`treat'","Q`q':`treat'"])) in `i'/`i'
			}
			
			if substr(e(cmdline),1,9)=="bootstrap" & ("`bootstrap'"=="" | "`bootstrap'"=="normal") {
			    replace `cil'=`b'[`i']-(`crit'*sqrt(e(V)["Q`q':`treat'","Q`q':`treat'"])) in `i'/`i'
				replace `ciu'=`b'[`i']+(`crit'*sqrt(e(V)["Q`q':`treat'","Q`q':`treat'"])) in `i'/`i'
			}
			
			if substr(e(cmdline),1,9)=="bootstrap" & ("`bootstrap'"!="" & "`bootstrap'"!="normal") {
				if "`bootstrap'"=="percentile" local V e(ci_percentile)
				if "`bootstrap'"=="bc" local V e(ci_bc)
				if "`bootstrap'"=="bca" local V e(ci_bca)
				if "`bootstrap'"=="" local V e(ci_normal)
				replace `cil'=`V'["ll","Q`q':`treat'"] in `i'/`i'
				replace `ciu'=`V'["ul","Q`q':`treat'"] in `i'/`i'
			}
			
		}
		
	}
	
	if substr(e(cmdline),1,9)=="bootstrap" {
	    if "`bootstrap'"=="" local printboot (normal-approximation bootstrapped CIs)
		if "`bootstrap'"=="normal" local printboot (normal-approximation bootstrapped CIs)
		if "`bootstrap'"=="percentile" local printboot (percentile bootstrapped CIs)
		if "`bootstrap'"=="bc" local printboot (bias-corrected bootstrapped CIs)
		if "`bootstrap'"=="bca" local printboot (bias-corrected and accelerated bootstrapped CIs)
}
	
	di _newline(1)
	di as text "Plot RQR coefficients"
	di as text "Outcome: "  e(depvar)
	di as text "Treatment: " e(treatment)
	di as text "Confidence bands: "( 1-`level'*2)*100 "% `printboot'"
		
	if "`nodraw'"=="" {
	    if "`noci'"=="" {
			tw 	(line `b' `Q', `bopts') 						///
				(rarea `cil' `ciu' `Q', color(%40) `ciopts')	///
				, legend(off) ytitle(Coefficient) `twopts'
		}
		if "`noci'"=="noci" {
			tw 	(line `b' `Q', `bopts') 						///
				, legend(off) ytitle(Coefficient) `twopts'
		}
	}
	mkmat `Q' `b' `se' `cil' `ciu', matrix(`plotmat') nomissing 
	mat colnames `plotmat'=q b se ll ul
	if "`notabout'"=="" {
		mkmat `b' `se' `cil' `ciu', matrix(`plotout') nomissing 
		qui levelsof `Q', local(qlevels)
		local myrownames
		foreach j of local qlevels {
			local temp: di %6.2f `j'
			local myrownames `myrownames' `temp'
		}
		matrix rownames `plotout'=`myrownames'
		matrix colnames `plotout'= b se ll ul
		mat l `plotout', noheader
	}
	return matrix plotmat=`plotmat'
	
end 



capture program drop rqrboot 
program define rqrboot, 

	bootstrap, reps(`reps'): 


end 



