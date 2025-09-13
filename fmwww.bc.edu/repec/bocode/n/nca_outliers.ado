*! nca_outliers v0.1 08/27/2025
pro def nca_outliers
syntax varlist (numeric min=2 max=2) [if] [in], IDvar(varlist  numeric  min=1 max=1) [CEILing(string) CORner(integer 1) flipx flipy k(integer 1) MINDif(real 0.01)  MAXResults(integer 25) save(string asis) verbose SCOpe(numlist missingokay)]
version 17
if ("`ceiling'"=="") local ceiling ce_fdh
isid `idvar'
tempname  scopeout1 peers1 scopeout peers
tempvar pv
marksample touse
if ("`scope'"!="") {
	local scope scope(`scope')
}
 nca_estimate `varlist' if `touse', ceil(`ceiling') corner(`corner') `flipx' `flipy' nograph peers(`peers1') scopeobs(`scopeout1') `scope'

local ES=e(results)["Effect size",1]

quie gen `pv'=((`peers1'==1) | (`scopeout1'==1)) if e(sample)


local droplist   `peers1' `scopeout1'

quie forval j=1/`k' {
if (`j'==1 | `k'==1) continue
	tempname  scopeout`j' peers`j'
    nca_estimate `varlist' if `touse' & !`pv', ceil(`ceiling') corner(`corner') `flipx' `flipy' nograph peers(`peers`j'') scopeobs(`scopeout`j'') `scope'
	replace `pv'=1 if (`peers`j''==1) | (`scopeout`j''==1)
	local droplist `droplist'  `peers`j'' `scopeout`j''
	 }
	 
	 tempname _temp _temp2
	frame put `idvar' `droplist' if `pv'==1  , into(`_temp')
if (`k'>1) frame put `idvar' `droplist' if `pv'==1  , into(`_temp2')

local lblname: value label `idvar' 

quie frame `_temp': {
	if (`k'==1)  gen _l2=`idvar'
		else {
			drop `droplist'
			forval i=2/`=`k'' {
				tempvar id`i'
				clonevar `id`i'' =`idvar' 
			}	
			fillin *
			drop _fillin
			rowsort *, gen(___id1-___id`k')
			keep ___id*
			duplicates drop *, force
			list

			egen _lists = concat(___id*), punct(" ")

			quie forval i=1/`=_N' {
				local stri=_lists[`i']
				local stri:  list uniq stri
				replace _lists="`stri'" in `i'
			}
			drop ___id*
			duplicates drop
			gen _l2=subinstr(_lists," ",",",.)
			split _lists,  generate(___id)
			destring ___id*, replace
			sort ___id*
			cap   label values ___id* `lblname' 
			rename (___id*) (`idvar'*)
			} // end else
			local Ncombs=_N
			gen eff_size=.
			gen ES=`ES'
} // end frame
if (`Ncombs'>49) _dots 0, title(NCA Outliers Progress) reps(`Ncombs')
else noi di as result "NCA Outliers"
quie forval i=1/`Ncombs' {
	frame `_temp': local ll= _l2[`i']
	if ("`verbose'"!="") di in red "excluding combination `ll' ... "
	if (`Ncombs'>49) noi _dots `i' 0
	cap nca_estimate `varlist' if !inlist(`idvar',`ll'), ceil(`ceiling') corner(`corner') `flipx' `flipy' nograph `scope'
	if (!_rc) frame `_temp': {
		replace eff_size=e(results)["Effect size",1] in `i'
		}
	}


frame `_temp': {

quie gen dif_abs = eff_size-ES 
quie gen dif_rel= 100*dif_abs / ES
quie rename (ES eff_size) (eff_or eff_nw)
quie gen absrel=abs(dif_rel)

quietly if (`k'==1) {
	gen byte ceiling=`peers1'
	gen byte scope=`scopeout1'
} 
else quietly: {
	tempfile _temp3

forval i=1/`k' {
	frame `_temp2': {
		gen `idvar'`i'=`idvar' 
		gen ceiling`i'=(`peers`i''==1) 
		gen scope`i'=(`scopeout`i''==1)
		save `_temp3', replace
	}
	merge m:1 `idvar'`i' using `_temp3', keepusing(ceiling`i' scope`i') keep(match master) 
	drop _merge
		}
	
	quie egen check= rowmiss(`idvar'*)
	levelsof `idvar'1 if (check==`k'-1) & scope1, local(scopeoutliers)
	quie egen scope=anymatch(`idvar'*), v(`scopeoutliers')
	levelsof `idvar'1 if (check==`k'-1) & ceiling1, local(ceilingoutliers)
	quie egen ceiling=anymatch(`idvar'*), v(`ceilingoutliers')
	
	drop ceiling1-ceiling`k' scope1-scope`k'
}
	quie describe `idvar'*, varlist
	gsort -absrel `r(sortlist)', mfirst
	quie gen _rank=_n
	quie drop absrel
	quie drop if dif_abs==0
	format eff_or     eff_nw     dif_abs  %9.2f
	format dif_rel   %9.1f
	keep _rank `idvar'* eff_nw eff_or dif_abs dif_rel ceiling scope
	label define cs 0 "" 1 "X"
	label values ceiling scope cs
	list `idvar'* eff_or eff_nw   dif_abs dif_rel ceiling* scope* if _n<=`maxresults' & abs(dif_rel)>=`mindif'
	if ("`save'"!="") save `save', replace	
} 

end
