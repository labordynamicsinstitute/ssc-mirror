** Adrien Avril 2015
cap program drop clean_fname
program clean_fname
version 13
	syntax varlist

foreach i in `varlist' {
replace `i'=lower(`i')
replace `i'=subinstr(`i',"�","a",.)
replace `i'=subinstr(`i',"�","a",.)
replace `i'=subinstr(`i',"�","a",.)
replace `i'=subinstr(`i',"�","a",.)
replace `i'=subinstr(`i',"�","e",.)
replace `i'=subinstr(`i',"�","e",.)
replace `i'=subinstr(`i',"�","e",.)
replace `i'=subinstr(`i',"�","e",.)
replace `i'=subinstr(`i',"�","e",.)
replace `i'=subinstr(`i',"�","e",.)
replace `i'=subinstr(`i',"�","e",.)
replace `i'=subinstr(`i',"�","e",.)
replace `i'=subinstr(`i',"�","u",.)
replace `i'=subinstr(`i',"�","u",.)
replace `i'=subinstr(`i',"�","u",.)
replace `i'=subinstr(`i',"�","i",.)
replace `i'=subinstr(`i',"�","c",.)
replace `i'=subinstr(`i',"�","o",.)
replace `i'=subinstr(`i',"�","i",.)
replace `i'=subinstr(`i',"�","n",.)
replace `i'=subinstr(`i',"`=char(160)'","",.)
replace `i'=subinstr(`i',"'"," ",.)
replace `i'=subinstr(`i',"-"," ",.)
replace `i'=trim(`i')
replace `i'=subinstr(`i',"    "," ",.)
replace `i'=subinstr(`i',"   "," ",.)
replace `i'=subinstr(`i',"  "," ",.)
replace `i'="" if `i'=="."
replace `i'=proper(`i')
}
end

