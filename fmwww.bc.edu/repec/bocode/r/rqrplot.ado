*! rqrplot 1.0.2 15june2022 Nicolai T. Borgen 

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
	
	tempname matquantile
	matrix `matquantile'=e(quantiles)
	local nquantiles=rowsof(`matquantile')
	if `nquantiles'==1 {
		di as error "RQR model estimated for only one quantile; re-estimate with two or more quantiles before using rqrplot."
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
	

	tempvar Q b se cil ciu 
	tempname plotmat plotout
	
	qui {
			
		gen `Q'=.
		gen `b'=.
		gen `se'=.
		gen `cil'=.
		gen `ciu'=.
		
		lab var `Q' "Quantile"
		
		tempname eb eV bootV
		matrix `eb'=e(b)
		matrix `eV'=e(V)

		forvalues i=1/`nquantiles' {
			
			local q=`matquantile'[`i',1]
			local ebcolnumb=colnumb(`eb',"Q`q':`treat'")
			local ebrownumb=rownumb(`eb',"y1")
			local eVcolnumb=colnumb(`eV',"Q`q':`treat'")
			local eVrownumb=rownumb(`eV',"Q`q':`treat'")			
			local coef=`eb'[`ebrownumb',`ebcolnumb']
			local StandErr=sqrt(`eV'[`eVrownumb',`eVcolnumb'])			
			
			replace `Q'=`q' in `i'/`i'
			replace `b'=`coef' in `i'/`i'
			replace `se'=`StandErr' in `i'/`i'
			
			if substr(e(cmdline),1,9)!="bootstrap" {
				replace `cil'=`coef'-(`crit'*`StandErr') in `i'/`i'
				replace `ciu'=`coef'+(`crit'*`StandErr') in `i'/`i'
			}
			
			if substr(e(cmdline),1,9)=="bootstrap" & ("`bootstrap'"=="" | "`bootstrap'"=="normal") {
			    replace `cil'=`coef'-(`crit'*`StandErr') in `i'/`i'
				replace `ciu'=`coef'+(`crit'*`StandErr') in `i'/`i'
			}
			
			if substr(e(cmdline),1,9)=="bootstrap" & ("`bootstrap'"!="" & "`bootstrap'"!="normal") {
				if "`bootstrap'"=="percentile" matrix `bootV'=e(ci_percentile)
				if "`bootstrap'"=="bc" matrix `bootV'=e(ci_bc)
				if "`bootstrap'"=="bca" matrix `bootV'=e(ci_bca)
				if "`bootstrap'"=="" matrix `bootV'=e(ci_normal)
				
				local bootVcolnumb=colnumb(`bootV',"Q`q':`treat'")
				local bootVrownumbll=rownumb(`bootV',"ll")				
				local bootVrownumbul=rownumb(`bootV',"ul")				
				
				local bootCIl=`bootV'[`bootVrownumbll',`bootVcolnumb']
				local bootCIu=`bootV'[`bootVrownumbul',`bootVcolnumb']
				replace `cil'=`bootCIl' in `i'/`i'
				replace `ciu'=`bootCIu' in `i'/`i'
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




