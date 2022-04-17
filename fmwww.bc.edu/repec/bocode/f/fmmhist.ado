*! version 1.0.0  13April2022 Jan Brogger jan@brogger.no
program define fmmhist
	version 17.0
	syntax  , [numbins(integer -1) DENSity TItle(passthru) XLAB(passthru) YLAB(passthru) XTItle(passthru) YTItle(passthru) ]
	if (substr("`e(cmdline)'",1,4)!="fmm ") {
		di as error "No previous fmm model found"
		error 999
	}
	// Find the dependent variable, check it is the same across equations
	local depvars "`e(depvar)'"
	local depvarcount : word count `depvars'
	local firstdepvar : word 1 of `depvars'
	forv i=2(1)`depvarcount' {
		local newdepvar : word `i' of `depvars'
		if "`newdepvar'" != "`firstdepvar'" {
			di as error "Multiple dependent variables found"
			error 999
		}
	}
	local outcomevar `firstdepvar'
	confirm numeric variable `outcomevar'
	
	preserve	
	tempvar densityvar prob allfreq binnedOutcome freq
	predict `densityvar', marginal density
	label variable `densityvar' "Fitted density"	
	predict `prob'*, classposteriorpr
	qui ds `prob'*
	local classcount : word count `r(varlist)'
	
	if (`numbins'==-1) {
		qui summ `outcomevar'
		local minBin=floor(`r(min)')
		local belowMinBin=`minBin'-1
		local maxBin=ceil(`r(max)')
		local aboveMaxBin=`maxBin'+1
		local binStep=1	
		egen `binnedOutcome'=cut(`outcomevar'), at( `minBin'(`binStep')`maxBin' )  label
	}
	else {
		
		qui summ `outcomevar'
		local belowMinBin=`minBin'-1
		local minBin=`r(min)'
		local maxBin=`r(max)'
		local aboveMaxBin=`maxBin'+1
		local range=`maxBin'-`minBin'
		local binStep=`range'/`numbins'
				
		egen `binnedOutcome'=cut(`outcomevar'), at( `minBin'(`binStep')`maxBin' )  label		
	}
	local label: variable label `outcomevar'
	label variable `binnedOutcome' "`label'"
	
	*Copy outcome value labels	
	local labelvalues : value label `binnedOutcome'	
	
	collapse (count) `allfreq'=`outcomevar' (mean) `densityvar' (mean) `prob'*  , by(`binnedOutcome')		
	label variable `binnedOutcome' "`label'"
	*Reapply outcome value labels
	label var `binnedOutcome' `labelvalues'
	
	label variable `densityvar' "Fitted density"	
	local i=1
	local graphstatement ""
	local graphopts `" xti("`label'") xlab(,valuelabel) "'
	foreach v of varlist `prob'* {
		gen `freq'`i'=`v'*`allfreq'
		label variable `freq'`i' "Count in class `i'"
		if `i'>1 {
			local graphstatement "`graphstatement' || "	
		}
		local graphstatement "`graphstatement' bar  `freq'`i' `binnedOutcome' , bcol(%30) "	
				
		local i=`i'+1
	}
	
	if "`density'"!="" {
		local graphstatement "`graphstatement' || line `densityvar' `binnedOutcome' , yaxis(2)  "			
		local graphopts "`graphopts'  yti("", axis(2)) ylab(,axis(2) nolabels) "
	}
	
	* di "`graphstatement'"
	* di "`graphopts'"
	
	local graphopts "`graphopts' `title' `xlab' `ylab' `xtitle' `ytitle' "
			
	twoway ///		
		`graphstatement'  ///		
		, yti("Count", axis(1))	`graphopts'
	*list
	restore
	
end