/*
Pengzhan Qian, p.qian@qmul.ac.uk, 2023/01/07
*/

cap prog drop rowsum
program define rowsum, sortpreserve
	version 17.0
	syntax namelist(min=3), SUMLIST(varlist min=1) [NEW(str) KEEP EXAMPLE(varlist)]
	//Split the main input and define sonlist
	tokenize "`namelist'"
	local size=wordcount("`namelist'")
	local id="`1'"
	local name_mother="`2'"
	local sonlist = "`3'"
	if `size'>3 {
	    forvalues i=4(1)`size'{
			local sonname="``i''"
		    local sonlist="`sonlist'"+" `sonname'"
			}
	}
	//Create a copy for mother obs
	qui expand 2 if `id'=="`name_mother'", gen(_rowsum)
	//Re-define _rowsum
	label var _rowsum "Summed obs from rowsum"
	label define _rowsum_mean 0 "not involved obs" 1 "summed obs" 2 "original obs", replace
	label values _rowsum _rowsum_mean
	qui gen _rowsum_temp=0
	qui replace _rowsum_temp=1 if _rowsum==1
	qui replace _rowsum_temp=1 if `id'=="`name_mother'"
	//Flag son obs
	foreach name_son_order in `sonlist'{
		qui replace _rowsum_temp=1 if `id'=="`name_son_order'"
	}
	//Sum and replace
	foreach v of varlist `sumlist' {
		local vartype: type `v'
		if substr("`vartype'",1,3)=="str" {
			di as error "cannot sum string variables" 
		}
		if substr("`vartype'",1,4)=="byte" {
			di as error "`v' maybe a categorical variable (program is still running)" 
		}
		//let the value of newly created obs be 0
	    qui replace `v'=0 if _rowsum==1  
	    qui bysort _rowsum_temp: egen `v'_temp=sum(`v')
		qui replace `v'=`v'_temp if _rowsum==1
		drop `v'_temp
	}
	//Create new name if specified
	if "`new'"!= "" {
		qui replace `id'="`new'" if _rowsum==1
	}
	//Show examples of summing up
	tokenize "`sumlist'"
	local var_example="`1'"
	qui replace _rowsum=2 if _rowsum_temp==1 & _rowsum!=1
	if "`example'"=="" {
	    di as result "rowsum results example (with the first variable in sumlist):"
		list `id' `var_example' _rowsum if _rowsum_temp==1   
	}
	else {
	   di as result "rowsum results example (with user-defined variables):"
	   list `id' `example' _rowsum if _rowsum_temp==1   
	}
	//Drop original obs unless specified
	if "`keep'"!="keep" {
		qui drop if _rowsum==2
		di in red "original observations are dropped"
	}
	if "`keep'"=="keep" & "`new'"!= "" {
		di as result "original observations are kept" 
	}
	if "`keep'"=="keep" & "`new'"== "" {
		di in red "original observations are kept and share the same name with the new observation" 
	}
	//Drop temp variable
	drop _rowsum_temp
end
	