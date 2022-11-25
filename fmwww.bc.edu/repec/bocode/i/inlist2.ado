* version 1.2  Nov2022  Matteo Pinna, matteo.pinna@gess.ethz.ch

* version 1.1: adds warning for the overwriting of the dummy variable
* version 1.2: adds sample conditions (if,in); defines the inlist dummy as a byte and sets it equal to zero when conditions are not satisfied; sets to quietly the replace commands (unless verbose option is on); optimises the dummy creation and sets a default var label.  The author would like to thank Mead Over for proposing these additions to the command.

cap program drop inlist2
program define inlist2
version 12.1
	syntax varlist (min=1 max=1) [if] [in], VALues(string) [  ///
	/* optional */ name(string) Verbose ///
	]
	
	marksample touse, strok
	
	if "`verbose'"==""  local silently quietly
	
	if ("`name'"=="") local name "inlist2" 
	capture confirm variable `name'
	if (!_rc==1) di as error "Warning: inlist2 is replacing a preexisting variable with the same name. See option name(string)"
	cap drop `name'
	
	tokenize "`values'", parse(",")
	local num_values=((length("`values'") - length(subinstr("`values'",",","", .)))*2)+1
	cap gen byte `name'=.
	capture confirm string variable `varlist'
		if !_rc {
			forvalues iteration=1(2)`num_values' {
				`silently' replace `name'= (`varlist'=="``iteration''") if `touse' & `name'!=1
			}	
		}
		else {
			forvalues iteration=1(2)`num_values'{
				`silently' replace `name'= (`varlist'==``iteration'') if `touse' & `name'!=1
			}
		}
		lab var `name' "=1 if -`varlist'- equals the specified value(s); 0 otherwise"
		note `name' : Specified values: `values'
end