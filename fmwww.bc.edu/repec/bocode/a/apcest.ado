/*******************************************************************************
APCEST: An estimation wrapper command to facilitate Fosse-Winship bounding 
approach to APC analysis.
********************************************************************************
Version: 1.1 (08.05.2025)
Author: Gordey Yastrebov, University of Cologne
License: GPL-3.0
*******************************************************************************/

	
	pr define apcest
		version 18
		preserve
		n _apcest `0'
		loc rc = _rc
		if `rc' {
			restore
			exit `rc'
		}
	end
	
	pr de _apcest, eclass
	syntax anything(name=estimation_cmd) [if] [in] [aw fw pw iw], ///
		a(string) p(string) c(string) [*]

*** Parse estimation command
	gettoken cmd vars : estimation_cmd
	gettoken depvar indepvars: vars
		
*** Parse APC arguments
	foreach apcvar in a p c {
	* categorical argument defined as "i.anything/ib.anything"
		if strpos("``apcvar''", ".") {
			loc dotpos = strpos("``apcvar''", ".")
			loc varname = substr("``apcvar''", `dotpos' + 1, .)
			loc prefix = substr("``apcvar''", 1, `dotpos' - 1)
			unab `apcvar'var : `varname'
			confirm_exists ``apcvar'var'
			loc `apcvar'spec `prefix'.``apcvar'var'
			loc `apcvar'continuous = 0
		}
	* categorical argument defined as "var:numlist"
		else if strpos("``apcvar''", ":") {
			loc colonpos = strpos("``apcvar''", ":")
			loc varname = substr("``apcvar''", 1, `colonpos' - 1)
			loc numlist = substr("``apcvar''", `colonpos' + 1, .)
			unab `apcvar'var : `varname'
			confirm_exists ``apcvar'var'
			numlist "`numlist'", sort
			loc `apcvar'numlist = r(numlist)
			loc `apcvar'continuous = 0
		}
	* polynomial argument ("var^#"):
		else if strpos("``apcvar''", "^") { 
			loc hatpos = strpos("``apcvar''", "^")
			loc varname = substr("``apcvar''", 1, `hatpos' - 1)
			loc power = real(substr("``apcvar''", `hatpos' + 1, .))
			unab `apcvar'var : `varname'
			confirm_exists ``apcvar'var'
			check_power `power'
			loc `apcvar'spec 
			loc term c.``apcvar'var'#c.``apcvar'var'
			forv i=2/`power' {
				loc `apcvar'spec ``apcvar'spec' `term'
				loc term `term'#c.``apcvar'var'
			}
			loc `apcvar'continuous = 1
		}
	* linear argument:
		else {
			loc varname ``apcvar''
			unab `apcvar'var : `varname'
			confirm_exists ``apcvar'var'
			loc `apcvar'continuous = 1
		}
	}
	
*** Scale consistency check
	qui g __apcacheck = `pvar' - `cvar'
	qui g __apcpcheck = `cvar' + `avar'
	qui g __apcccheck = `pvar' - `avar'
	foreach apcvar in a p c {
		qui reg ``apcvar'var' __apc`apcvar'check
		if !inrange(_b[__apc`apcvar'check], .95, 1.05) {
			di as err "APC variables inconsistently measured ({help apcbound:help apcbound})."
			exit
		}
		drop __apc`apcvar'check
	}
	
*** Define estimation sample to bypass the problem with [if] (when conditioning on APC variabels)
	qui cap reg `depvar' `aspec' `pspec' `cspec' `indepvars' `if' `in'
	
*** Continuous variable transformations
	foreach apcvar in a p c {
		if ``apcvar'continuous' {
			qui clonevar __apccache``apcvar'var' = ``apcvar'var'
			qui center_var ``apcvar'var' mean
			loc `apcvar'ref = 0
			loc `apcvar'center = r(center)
		}
		else if "``apcvar'numlist'" != "" {
			qui clonevar __apccache``apcvar'var' = ``apcvar'var'
			drop ``apcvar'var'
			qui egen ``apcvar'var' = cut(__apccache``apcvar'var'), at(``apcvar'numlist')
			levelsof ``apcvar'var', l(values)
			loc base = `:word `=floor(`:word count `values''/2)' of `values''
			loc `apcvar'spec ib`base'.``apcvar'var'
		}
	}
		
*** Run estimation command and store estimates
	n `cmd' `depvar' `avar' `cvar' `aspec' `pspec' `cspec' `indepvars' if e(sample) `in' [`weight'`exp'], `options'
	foreach apcvar in a p c {
		if !``apcvar'continuous' {
			loc colnames : colnames r(table)
			foreach colname of loc colnames {
				if strpos("`colname'", "b.``apcvar'var'") ///
					loc `apcvar'ref = substr("`colname'", 1, strpos("`colname'", "b.") - 1)
			}
		}
	}
	eret loc theta1var "`avar'"
	eret loc theta2var "`cvar'"
	eret sca theta1 = _b[`avar']
	eret sca theta2 = _b[`cvar']
	foreach apcvar in a p c {
		foreach info in var spec ref center {
			cap eret loc `apcvar'`info' = "``apcvar'`info''"
		}
	}
	est sto __apcestimate
	
*** Uncache everything
	foreach v of varlist __apccache* {
		qui uncache_var `v'
	}

	end

/////// Routines: //////////////////////////////////////////////////////////////
	pr de confirm_exists
		syntax varlist(min=1 max=1)
		cap conf v `varlist'
		if _rc {
			di as error "Variable {bf:`varlist'} not found."
			exit
		}
	end
	pr de center_var, rclass
		args var value
		qui sum `var', d
		if real("`value'") < . loc center = `value'
		else loc center = r(`value')
		replace `var' = `var' - `center'
		ret loc center = `center'
	end
	pr de check_power
		args power
		cap conf n `power'
		if _rc | floor(`power') != `power' | `power' <= 1 {
			di as error "Power must be an integer greater than one."
			exit
		}
	end
	pr de uncache_var
		args var
		loc varname = substr("`var'", 11, .)
		cap drop `varname'
		clonevar `varname' = __apccache`varname'
		cap drop __apccache`varname'
	end
