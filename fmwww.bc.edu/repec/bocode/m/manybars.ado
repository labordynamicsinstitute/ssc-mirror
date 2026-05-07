program manybars, rclass

version 16.0

if regexm(`"`0'"', "over\s*\(.*\).*over\s*\(") {
    di as err "Option {cmd:over()} may not be specified more than once." 
	di "List all grouping variables in a single {opt overvars()} option."
    exit 198
    }
	
syntax varname [if] [in],	Xvars(varlist) ///
						  [ Stat(string) ///
							Displayvalues(numlist integer) ///
							OVERvars(varlist) ///
							Horizontal ///
							GRAphopts(string) ///
							ADDtolegend(string) ///
							NEWLegend(string) ///
							VARlabel ///
							NOWarn ]

*Set the warning flag on or off
if "`nowarn'" == "nowarn" local warn 0
else local warn 1

if "`horizontal'"=="horizontal" local call "graph hbar"
else local call "graph bar"

*Name `y' and validate as numeric
local y "`varlist'"
confirm numeric variable `y'

marksample touse, novarlist

*Number of nonmissing obs in sample
qui count if `touse'
local N_orig = `r(N)'

*Validate the over variables
if "`overvars'" != "" {
    foreach v of local overvars {
        confirm numeric variable `v'
        }
    }
	
*Check for missing values of y
if `warn' {
	qui count if missing(`y') & `touse'
	if `r(N)' > 0 {
		if "`overvars'" != "" {
			local ngvars: word count `overvars'
			if `ngvars' == 1 {
				qui levelsof `overvars', local(glevels)
				foreach lev of local glevels {
					qui count if missing(`y') & `touse' & `overvars'==`lev'
					if `r(N)' > 0 {
						local glab: label (`overvars') `lev'
						if `"`glab'"' != "" local glabstr " (`glab')"
						else local glabstr ""
						di as txt "Note: {bf:`y'} has {bf:`r(N)'} missing observation(s) where {bf:`overvars'==`lev'}`glabstr'." 
						di as txt "These observations will not be graphed."
						}
					}
				}
			else {
				di as txt "Note: {bf:`y'} has {bf:`r(N)'} missing observation(s)." 
				di "These observations will not be graphed."
				}
			}
		else {
			di as txt "Note: {bf:`y'} has {bf:`r(N)'} missing observation(s)."  
			di "These observations will not be graphed."
			}
		}
	}

*Check for missing x variables & over variables
if `warn' {
	foreach x of varlist `xvars' `overvars' {
		qui count if missing(`x') & `touse'
		if `r(N)' > 0 {
			di as txt "Note: {bf:`x'} has {bf:`r(N)'} missing observation(s)." 
			di "These observations will not be graphed."
			}
		}
	}

*Extend markout to variables with missing values on y or xvars
markout `touse' `y' `xvars' `overvars'

*If stat() is unspecified, set default yvar statistic to mean
if "`stat'" == "" local stat "mean"

*Parse stat into `stat' and `stat_op'
gettoken stat stat_op: stat, parse(",")
local stat = ustrtrim("`stat'")

*Validate stat
if 	"`stat'" != "mean" & ///
	"`stat'" != "median" & ///
	"`stat'" != "mode" & ///
	"`stat'" != "min" & ///
	"`stat'" != "max" & ///
	"`stat'" != "count" & ///
	"`stat'" != "iqr" & ///
	"`stat'" != "mad" & ///
	"`stat'" != "mdev" & ///
	"`stat'" != "skew" & ///
	"`stat'" != "kurt" & ///
	"`stat'" != "sd" & ///
	"`stat'" != "total" {
		di as err "Error: '`stat'' is not a valid statistic."
		di "See {help manybars:help manybars} for the list of allowed statistics."
		exit 119
	}

*Validate displayvalues
local nxvars: word count `xvars'
local ndv: word count `displayvalues'

if `ndv' == 0 { 				// if no display values are specified
	forvalues i = 1/`nxvars' {
		local d`i' = 1
		}
	}
else if `ndv' == 1 { 			// if one display values is specified
	forvalues i = 1/`nxvars' {
		local d`i' = `displayvalues'
		}
	}
else if `ndv' == `nxvars' { 	// if all display values are specified
	forvalues i = 1/`nxvars' {
		local d`i': word `i' of `displayvalues'
		}
	}
else {	
	di as err "Error: the number of {it:displayvalues} must be 0, 1, or the number of {it:xvars}."
	exit 1001
	}
	
*Validate xvars
*Confirm that xvar==displayvalue has >0 observations
tokenize "`xvars'"
local i = 0
while "`1'" != "" {
	local ++i
	confirm numeric variable `1'
	*Make sure x is categorical
	
	*Make sure y is observed at the relevant value of x
	qui count if `touse' & `1'==`d`i''
	if `r(N)' == 0 {
		di as err "Error: no observations of {bf:`y'} at {bf:`1'=`d`i''}."
		exit 2000
		}
	macro shift
	}	
	
*Remove leading comma from stat_op
local stat_op = usubinstr(`"`stat_op'"',","," ",1) 

*Build the overs graph option
local overs ""
foreach v of local overvars {
    local overs `"`overs' over(`v')"'
    }

*Can't specify both addtolegend and newlegend
if `"`addtolegend'"' != "" & `"`newlegend'"' != "" {
	di as err "Error: options addtolegend() and newlegend() may not be combined."
	exit 184
	}
	
*Remove leading comma from addtolegend
local addtolegend = ustrtrim(`"`addtolegend'"')
if strpos(`"`addtolegend'"', ",") == 1 {
	local addtolegend = usubinstr(`"`addtolegend'"',","," ",1) 
	}

*Remove leading comma from newlegend
local newlegend = ustrtrim(`"`newlegend'"')
if strpos(`"`newlegend'"', ",") == 1 {
	local newlegend = usubinstr(`"`newlegend'"',","," ",1) 
	}

*Remove leading comma from graphopts
local graphopts = ustrtrim(`"`graphopts'"')
if strpos(`"`graphopts'"', ",") == 1 {
	local graphopts = usubinstr(`"`graphopts'"',","," ",1) 
	}	
	
*New temporary frame to preserve original data & frame
local fr "__manybars__temp"
capt frame drop `fr'
qui pwf
local oldframe "`r(currentframe)'"
frame copy `r(currentframe)' `fr'
capture {
frame `fr' {
	
	*Limit to [if] [in] sample
	qui drop if !`touse'
	qui count
	local N = `r(N)'
	
	*Sort by overvars, if any
	if "`overvars'" != "" sort `overvars'
	
	*Confirm xvar==displayvalue still has >0 observations after sample restriction
	tokenize "`xvars'"
	local i = 0
	while "`1'" != "" {
		local ++i
		qui count if `1'==`d`i''
		if `r(N)' == 0 {
			di as err "Error: no observations of {bf:`y'} at {bf:`1'=`d`i''} in the specified sample."
			exit 2000
			}
		macro shift
		}

	*Create display variables
	tokenize "`xvars'"
	local i = 0
	local leg ""
	local disp_vars ""
	while "`1'" != "" {
		local ++i
		tempvar disp`i'
		local disp_vars "`disp_vars' `disp`i''"
		if "`overvars'" != "" {
			capture noisily egen `disp`i'' = `stat'(`y')  ///
							if `touse' & `1'==`d`i'', by(`overvars') `stat_op'
			}
		else {
			capture noisily egen 	`disp`i'' = `stat'(`y') ///
										if `touse' & `1'==`d`i'' `stat_op'
			}
		
		if _rc {
			di as err "Error in {it:stat_options}."
			exit _rc
			}

		*Check for missing values of the stat
		if `warn' {
			qui summ `disp`i'' if `1'==`d`i'' & `touse'
			if "`r(mean)'" == "" {
				di as txt "Warning: no values of {bf:`y'} at {bf:`1'==`d`i''}."
			}
		}

		*Legend labels
		if "`varlabel'" == "varlabel" {
			local lab: variable label `1'
			if "`lab'" == "" { 
				local lab = "`1'" // if no var label, use varname
				}
			}
		else {
			local lab: label (`1') `d`i'' // if not varlabel, use value label
			}
		lab var `disp`i'' "`lab'"
		local leg `"`leg' label(`i' "`lab'")"'
		
		macro shift
		}

	*Replace with newlegend if specified
	if `"`newlegend'"' != "" local legend `"legend(`newlegend')"'
	else if `"`legend'"' == "" local legend `"legend(`leg' `addtolegend')"'

	*Draw the graph
	capt noisily `call' `disp_vars', ti(`stat' of `y')  ///
						yti(`stat' of `y') `overs' `graphopts' `legend'

	if _rc {
		di as err "Invalid graph syntax. Check the help file section on {help manybars##graph_options:Graph and Legend Options}."
		exit _rc
		}
	} // end -frame-
} // end -capture-

*Change back to previous frame and clean up
local rc = _rc
capt frame drop `fr'
frame change `oldframe'
if `rc' {
    exit `rc'
    }

*Return
return scalar	n_xvars = `nxvars'
return scalar	N_missing = `N_orig' - `N'
return scalar 	N_graphed = `N'

return local	cmd = "manybars"
if "`stat_op'" == "" return local	stat = "`stat'"
else return local stat = "`stat', `stat_op'"
return local	overvars = "`overvars'"
return local	xvars = "`xvars'"
return local	yvar = "`y'"

end
