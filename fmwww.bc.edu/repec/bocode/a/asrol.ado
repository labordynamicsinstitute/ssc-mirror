*! Attaullah Shah 3.1.0 4Mar2015
*! Email: attaullah.shah@imsciences.edu.pk
*! Support website: www.OpenDoors.Pk

cap prog drop asrol
prog asrol, byable(onecall) sortpreserve
version 13
	syntax                 ///
	varname(numeric)      ///
	[in] [if],           ///
	Stat(str) 		    ///
	[Generate(str)     ///
	Window(string)    ///
	SMiss 			 ///
	MINimum(real 0) ///
	by(varlist)    ///
	] 
	marksample touse, nov
	if "`stat'"~="mean" & "`stat'"~="sd" & "`stat'"~="sum" &   ///
		"`stat'"~="median" & "`stat'"~="count" & "`stat'"~="min"  ///
		& "`stat'"~="max" & "`stat'"~="first" & "`stat'"~="last" ///
		& "`stat'"~="missing" { 
		display as error " Incorrect statistics specified!"
		display as text "You have entered {cmd: `stat'} in the {cmd: stat option}. However, only the following staticts are allowed with {help asrol}"
		dis as res "mean, sd, sum, median, count, min, max, first, last, missing"
		exit
	}
	local nwindow : word count `window'
	if `nwindow'!=2 & `nwindow'!=1{
		dis in red "The rolling window accepts minimum one and maximum two arguments. You have entered " `nwindow'
	exit
	}
	if `nwindow'==2 {
		tokenize `window'
		gettoken    rangevar window : window
		gettoken  rollwindow window : window
	}
	else{ // if only rangevar is not specified
		local rollwindow `window'
	}
	if `rollwindow'<=0 {
		dis as error "The rolling window should have minimum value of 1 or greater"
		exit
	}
	tempvar GByVars dup first n 
	if "`by'"!="" {
		if "`rangevar'"=="" {
			local rangevar "`_dta[_TStvar]'"
		}
		gen `n'=_n
		bysort `by' (`rangevar' `n'): gen  `first' = _n == 1
		gen `GByVars'=sum(`first')
		drop `first' `n'
		sort `GByVars' `rangevar'
		by `GByVars' `rangevar' : gen `dup'=_N
		qui sum `dup', meanonly
		if r(max) > 1 {
			local IsPanel "No"
		}
		else {
			local IsPanel "Yes"
		}
	}
	else{ 
		if "`_dta[_TSpanel]'"!=""{
			local GByVars "`_dta[_TSpanel]'"
			local IsPanel "Yes"
			if "`rangevar'"=="" {
				local rangevar "`_dta[_TStvar]'"
				
			}
		}
		else { 
			
			if "`_dta[_TStvar]'"!=""{
			local IsPanel "Yes"
				if "`rangevar'"=="" {
					local rangevar "`_dta[_TStvar]'"
					tempvar GByVars
					qui gen `GByVars'=1
					
				}
			}
		}
	}
		if "`rangevar'"==""{
			dis as error "The data is not declared as panel or time series data"
			dis as text "If your data is not time series or panel, you can specify range variable {break} in the option {cmd: window} as a first argument. For example, {cmd: window(year 5)} where {break} {cmd: year} is the range variable and {cmd: 5} is the length of the rolling window."
			exit
		}

	if "`generate'"=="" {
		local generate "`stat'`rollwindow'_`varlist'"
	}
	
	local nmiss: word count `smiss'
	if `nmiss'==1 {
		local nomiss = 1
	}
	else{
		local nomiss =2
	}
	
	if "`IsPanel'" =="Yes" {
		qui tsf, panel(`GByVars') timevar(`rangevar')
	}
	
	mata: fasrol("`varlist'", 		     ///
	              "`GByVars'" ,		    ///
				  "`generate'" , 	   ///
	              `rollwindow',		  /// 
				  "`stat'", 	     ///
				  `nomiss' , 		///
				  `minimum', 	   ///
				  "`rangevar'",	  /// 
				  "`IsPanel'", 	 ///
				  "`touse'"		///
				  )
	if "`IsPanel'" =="Yes" {
		qui drop if TimeDiff==. 
		drop TimeDiff
	}
	cap qui label variable `generate' "`stat' of `varlist' in a `rollwindow'-periods rol. wind."
	end
*! tsf is based on Stata's official 'tsfill' program
program define tsf, rclass
syntax , timevar(varlist) [panel(varlist)] 
	if "`panel'" != ""   {
		local bypfx "qui by `panel': "
	}
	else    local bypfx "qui "  
	tempvar numreps TimeDiff
	noi cap `bypfx' gen double TimeDiff = `timevar'[_n+1] - `timevar'
	if _rc {
		sort `panel' `timevar'
		cap `bypfx' gen double TimeDiff = `timevar'[_n+1] - `timevar'
	}
	`bypfx' replace TimeDiff =  0 if _n == _N
	`bypfx' gen double `numreps' = TimeDiff 
	qui replace `numreps' = 0 if `numreps' == .
	local orign = _N
	qui count if  `numreps'  > 1
	local addns `r(N)'
	if `addns' > 0 {
		local newobs = `orign' + `addns'
		qui replace `numreps' = - `numreps'
		sort `numreps'
		qui replace `numreps' = - `numreps'
		qui set obs `newobs'
		local orign1 = `orign' + 1
		qui replace `numreps' = `numreps'[_n-`orign']  in `orign1'/l
		qui replace `timevar' = `timevar'[_n-`orign']  in `orign1'/l
		if "`panel'" != "" {
			qui replace `panel' = `panel'[_n-`orign']  in `orign1'/l
		}
		qui replace `numreps' = 0  in 1/`orign'
		qui replace `numreps' = `numreps' - 1  if `numreps'
		qui expand `numreps'
		sort `panel' `timevar' `numreps'
		qui by `panel' `timevar': replace `timevar' = `timevar' + /*
			*/ 1 * (`numreps' - _n + 2)  if `numreps' > 0
		drop  `numreps'
		sort `panel' `timevar'
	}

end

