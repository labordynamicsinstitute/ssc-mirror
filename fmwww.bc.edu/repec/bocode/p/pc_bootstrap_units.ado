	
*******************************************************************************************
*** ----------------------------------------------------------------------------------- ***
*** pc_bootstrap_units: BOOTSTRAP ADDITIONAL UNITS FOR POWER CALCULATIONS BY SIMULATION ***
*** ----------------------------------------------------------------------------------- ***
*******************************************************************************************
	
*** version 1.0 19dec2016
*** part of ssc package "pcpanel"
	
program define pc_bootstrap_units
version `=clip(`c(version)', 9.0, 13.1)'

syntax varname [if] [in], Nunits(numlist max=1 integer >0) [VARlist(varlist) sort(varlist)]
{	
// store master dataset in tempfile to restore if program breaks
tempfile m_dta_before_bs
quietly save `m_dta_before_bs', replace

// local for cross-sectional unit to be bootstrapped with replacement
local uNIt = subinstr("`1'",",","",1)

// identify observations to be included
quietly gen tEMp_if_in = 0
quietly replace tEMp_if_in = 1 `if' `in'

// sort data and store order of sort
sort tEMp_if_in `uNIt' `sort'
quietly gen tEMp_sORt = _n 

// checks on bootstrap unit varaible
capture confirm numeric variable `uNIt' 
	local rc = _rc
	if `rc' {
		display "{err}Error: Bootstrap unit id variable `uNIt' must be numeric"
		use `m_dta_before_bs', clear	
		exit `rc'
	}
capture assert `uNIt'!=. if tEMp_if_in==1
	local rc = _rc
	if `rc' {
		display "{err}Error: `uNIt' cannot have missing values"
		use `m_dta_before_bs', clear	
		exit `rc'
	}

// confirm that the dataset needs to be bootstrapped
quietly unique `uNIt' if tEMp_if_in==1
local Nexisting = r(sum)
capture assert `Nexisting' < `nunits'
	local rc = _rc
	if `rc' {
		display "{err}Error: Dataset already contains `Nexisting' unique `uNIt' units"
		use `m_dta_before_bs', clear	
		exit `rc'
	}
	
// set parameters for bootstrap	loop
local Nloopstart = `Nexisting'+1
quietly sum `uNIt'
local uNIt_max = r(max)
quietly egen tEMp_taG_uNIt = tag(`uNIt') if tEMp_if_in==1
quietly gen ORIG`uNIt' = .


// bootstrap units
forvalues nLOOP = `Nloopstart'/`nunits' {
	
	* choose which unit to duplicate on each bootstrap
	quietly gen tEMp_rANdom = runiform()*tEMp_taG_uNIt
	sort tEMp_rANdom
	local uNIt_LOOP = `uNIt'[1]
	
	* identify rows to duplicate
	quietly sum tEMp_sORt if `uNIt'==`uNIt_LOOP' & tEMp_if_in==1
	local dUPstart = r(min)
	local dUPend = r(max)
	
	* increase observation count to accommodate new (duplicate) rows
	local oLDobs = _N
	local nEWobs = `dUPend'-`dUPstart'+1
	local oBs = `oLDobs'+`nEWobs'
	quietly set obs `oBs'
	
	* create new unit id for bootstrapped unit
	quietly replace `uNIt' = `uNIt_max'+`nLOOP'-`Nexisting' if `uNIt'==. 

	* store original unit from which simulated unit was created
	quietly replace ORIG`uNIt' =  `uNIt_LOOP' if `uNIt'==`uNIt_max'+`nLOOP'-`Nexisting' 
	
	* restore original sort, populate missing new rows with sort ids
	sort tEMp_sORt
	quietly replace tEMp_sORt = _n if tEMp_sORt==.
	capture assert tEMp_sORt==_n
		local rc = _rc
		if `rc' {
			display "{err}Error re-sorting data during bootstrap"
			use `m_dta_before_bs', clear	
			exit `rc'
		}
	
	* populate new variables
	forvalues iLOOP = 1/`nEWobs' {
		if "`varlist'"=="" {
			foreach v of varlist * {
				if inlist("`v'","`uNIt'","tEMp_rANdom","tEMp_taG_uNIt","ORIG`uNIt'","tEMp_sORt")==0 {
					quietly replace `v' = `v'[`dUPstart'+`iLOOP'-1] if tEMp_sORt==`oLDobs'+`iLOOP'
				}
			}
		}
		else {
			foreach v of varlist `varlist' {
				if inlist("`v'","`uNIt'","tEMp_rANdom","tEMp_taG_uNIt","ORIG`uNIt'","tEMp_sORt")==0 {
					quietly replace `v' = `v'[`dUPstart'+`iLOOP'-1] if tEMp_sORt==`oLDobs'+`iLOOP'
				}
			}
		}
	}	

	* reset within-loop random draw
	drop tEMp_rANdom

	* report intermediate output
	noisily display "   `nLOOP'"
}	
	
* clean up
sort tEMp_sORt
quietly drop tEMp_sORt tEMp_taG_uNIt tEMp_if_in

* done 
local Nnew = `nunits' - `Nexisting'
display _n
display "Bootstrapping complete, dataset now contains `nunits' unique `uNIt' units"
display "(`Nnew' simulated units bootstrapped from existing dataset with replacement, "
display "with original `uNIt' stored in the new variable ORIG`uNIt') "
}

end

*******************************************************************************************
*******************************************************************************************
