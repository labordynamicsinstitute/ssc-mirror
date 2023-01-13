clear all

*********************
*** Preliminaries ***
*********************
global a = "System 7" // Input a-side system
global b = "System 5" // Input b-side system

use "...\sim_data.dta", clear // Input discharge data

** Identify party hospitals **
foreach x in "a" "b" {
	* Identify system observations *
	gen `x'_side0 = (strpos(system,"$`x'") > 0)
	label var `x'_side0 "$`x'"
	
	* Create hospital flags *
	display "{ul: $`x'}"
	tab hospital if `x'_side0 == 1
	global num_`x' = r(r)
	quietly levelsof hospital if `x'_side0 == 1, local(hosp)
	local j = 1
	foreach i of local hosp {
		gen `x'_side`j' = (hospital == "`i'")
		label var `x'_side`j' "`i'"
		local j = `j' + 1
		}
	}

*******************************	
*** Semiparametric Analysis ***
*******************************
global bins "pat_county pat_zip mdc drg age female"

divratio a_side0 b_side0 hospital system pat_zip drg, ///
	groups($bins) geo_ref(combined) prod_ref(overlap) svc_pct(90) ///
	min_group_size(25) wtp
