program pooledsd, rclass
	version 9
	syntax varlist(min=1 max=1 numeric) [if] [in], by(varlist min=1 max=1 numeric) [mdiff(numlist min=1 max=1)]
	local dv `varlist'
	local iv `by'
	marksample touse
	markout `touse' `iv'
	preserve
	local numerator = 0
	local denominator = 0
	capture : sum if `touse' 
	if _rc {
		dis as error "Basic sum command failed to run; are there data?"
		error
	}
	local totalobs = string(r(N),"%14.0fc")
	capture: levelsof `iv' if `touse', local(ivlevels)
	if _rc {
		dis as error "levelsof command failed to run; are there too many categories?"
		error
	}
	if `: list sizeof ivlevels' == 0 {
		dis as error "`iv' does not contain any valid observations."
		error
	}
		else if `: list sizeof ivlevels' == 1 {
			dis as error "`iv' does not vary. All observations are `ivlevels'."
			error
		}
			else if `: list sizeof ivlevels' > 2500 {
				dis as error "by variable (`iv') has too many levels"
				error
			}
				else {
				}
	tempvar column
	tempvar row
	tempvar cell
	qui gen strL `column' = ""
	qui gen strL `row' = ""
	if !missing("`: var label `iv''") {
		label var `row' "`: var label `iv''"
	}
		else {
			label var `row' "`iv'"
		}
	label var `column' " "
	qui gen double `cell' = .
	local loop = 0
	foreach n of numlist `ivlevels' {
		capture: sum `dv' if `touse' & `iv' == `n'
		if _rc {
			dis as error "sum command did not run."
			error
		}
		local obs = r(N)
		if `obs' == 1 {
			dis as error "Only one observation in `iv' for level `n'"
			error
		}
		local var = r(Var)
		if `var' == . {
			dis as error "sum command did not produce variance estimate."
			error
		}
		if `var' == 0 {
			dis as error "No variance in Group #`n'."
			error
		}
		local sd = r(sd)
		if `sd' == 0 {
			dis as error "No variance in Group #`n'."
			error
		}		
		local ++loop
		qui replace `column' = "n" in `loop'
		qui replace `row' = "#`n' (`: label (`iv') `n'')" in `loop'
		qui replace `cell' = `obs' in `loop'
		local ++loop
		qui replace `column' = "sd" in `loop'
		qui replace `row' = "#`n' (`: label (`iv') `n'')" in `loop'
		qui replace `cell' = `sd' in `loop'
		local numerator = `numerator' + ((`obs'-1)*`var')
		local denominator = `denominator' + (`obs')
	}
	local denominator = `denominator' - `: list sizeof ivlevels'
	local psd = sqrt(`numerator'/`denominator')
	keep `column' `row' `cell'
	local start = `loop' + 1
	qui drop in `start'/L
	dis as text _newline(2) "Pooled standard deviation for groups " as result "`ivlevels'" as text" in " as result "`iv'."
	dis as text "There were a total of " as result "`totalobs'" as text " observations used in the calculation."
	tabdisp `row' `column' , cellvar(`cell') concise
	local temp = string(round(`psd',.0001),"%14.4fc")
	dis as text "The pooled standard deviation is " as result "`temp'"
	return scalar psd = `psd'
	if !missing("`mdiff'") {
		local cohd = `mdiff'/`psd'
		return scalar cohd = `cohd'
		local temp = string(round(`cohd',.0001),"%14.4fc")
		dis as text "The Cohen's {it:d} estimate is " as result "`temp'" 
	}
end
