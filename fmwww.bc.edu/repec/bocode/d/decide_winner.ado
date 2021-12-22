
cap program drop decide_winner
program define decide_winner
syntax, out(string) type(string) tdvar(string) i(integer) [margin(string)]



* --------------------------------------
* 1a. Outcome type: time to event (failure e.g. death, MI)
* --------------------------------------
if "`type'"=="tf" {		
qui gen comp`i'=((`out'_j==1 & `tdvar'_i>`tdvar'_j) | (`out'_j==1 & `out'_i==0 & `tdvar'_i==`tdvar'_j))+((`out'_i==1 & `tdvar'_j>`tdvar'_i) | (`out'_i==1 & `out'_j==0 & `tdvar'_j==`tdvar'_i))*-1  if !missing(`out'_i , `out'_j , `tdvar'_i , `tdvar'_j) 
				 }
* --------------------------------------
* 1b. Outcome type: time to event (success e.g. discharge)
* --------------------------------------
if "`type'"=="ts" {  	
qui gen comp`i'=((`out'_i==1 & `tdvar'_i<`tdvar'_j) | (`out'_i==1 & `out'_j==0 & `tdvar'_i==`tdvar'_j))+((`out'_j==1 & `tdvar'_i>`tdvar'_j) | (`out'_j==1 & `out'_i==0 & `tdvar'_j==`tdvar'_i))*-1 if !missing(`out'_i , `out'_j , `tdvar'_i , `tdvar'_j) 
				 }
* --------------------------------------
* 2. Outcome type: continuous/categorical/binary
* --------------------------------------
if "`type'"=="c" {  	
qui gen comp`i'=(`out'_i `tdvar' `out'_j)+(`out'_j `tdvar' `out'_i)*-1 if !missing(`out'_i , `out'_j) 
				 }		
* --------------------------------------
* 3. Outcome type: repeat events
* --------------------------------------
if "`type'"=="r" {

tempvar fu_min events_i events_j 
* Find max number of events
local repev=0 
	foreach var of varlist `out'*_j  {
	local ++repev
	}

/* Event qualifies only if it occurs during the shared follow up of two patients...set events after the end of shared follow up to 0 */
qui egen `fu_min'=rowmin(`tdvar'`repev'_i `tdvar'`repev'_j)
	forvalues r=1/`repev' {
	qui replace `out'`r'_i=0 if `fu_min'<`tdvar'`r'_i & !missing(`fu_min', `tdvar'`r'_i)
	qui replace `out'`r'_j=0 if `fu_min'<`tdvar'`r'_j & !missing(`fu_min', `tdvar'`r'_j)
	}

* Calculate number of events for i and j
qui egen `events_i'=rowtotal(`out'*_i)
qui egen `events_j'=rowtotal(`out'*_j)

* WLT
qui gen comp`i'=(`events_i'<`events_j')+(`events_i'>`events_j')*-1 if !missing(`events_i', `events_j')

} 	// end of repeat events type 

end

