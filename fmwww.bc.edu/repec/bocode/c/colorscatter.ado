cap program drop colorscatter
program define colorscatter 
    version 11.0
	syntax varlist(max=3)  [if] [in],[ keeplegend scatter_options(string) cmin(string) cmax(string) rgb_low(string) rgb_high(string) * ]
	marksample touse
	
	tokenize `varlist'
	local x "`1'"
	local y "`2'"
	local c  "`3'"
	qui sum `c'
	if "`cmin'"=="" {
		local cmin=r(min)
	}
	if "`cmax'"=="" {
		local cmax=r(max)
	}
	if "`rgb_low'"=="" {
		local rgb_low  0 0 255
	}
	if "`rgb_high'"=="" {
		local rgb_high 255 0 0
	}
	local rl1 : word 1 of `rgb_low'
	local rl2 : word 2 of `rgb_low'
	local rl3 : word 3 of `rgb_low'
	local rh1 : word 1 of `rgb_high'
	local rh2 : word 2 of `rgb_high'
	local rh3 : word 3 of `rgb_high'
	
	
	tempvar cscaled
	gen `cscaled' = round(255*(`c'-`cmin')/(`cmax'-`cmin'))
	
	qui replace `cscaled'=0 if `cscaled' <0
	qui replace `cscaled'=255 if `cscaled'>255 & ! missing(`cscaled') 
	local command tw 
	qui levelsof `cscaled' if `touse', local(levels) 
	
	local i 0
	foreach l of local levels {
		local i = `i'+1
		local gradient=`l'/255		
		local command `command' (scatter `x' `y' if `cscaled'==`l' & `touse', mcolor("`: di round(`gradient'*`rl1' + (1-`gradient')*`rh1')' `: di round(`gradient'*`rl2' + (1-`gradient')*`rh2')' `: di round(`gradient'*`rl3' + (1-`gradient')*`rh3')'") `scatter_options')
	}
	
	if ("`keeplegend'"=="") {
		local legend  legend(order(2 "`c' = `:di round(`cmin',0.1)' " `i' "`c' = `:di round(`cmax',0.1)'"))
	}
	else {
		local legend 
	}
	//di `"`command'"'
	`command', `legend' `options'
end
