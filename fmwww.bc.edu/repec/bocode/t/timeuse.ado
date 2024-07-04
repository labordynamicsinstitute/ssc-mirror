


program timeuse, rclass

	version 11 
	
	syntax varlist(min=1 max=1 numeric), diaryid(string) 

	tokenize `varlist'
	
		local activity `1'
		
	quietly {
	
		sequencex `activity', diaryid(`diaryid') diaryst(4)

		levelsof `activity', local(levels)

		local vlname: value label `activity' 
		
		foreach l of local levels {
			
			tempvar x 
			gen `x'=0
	
			replace `x'=time if `activity'==`l'
			bysort `diaryid': egen `activity'_`l'=total(`x')
			
			capture qui local thelabel: label `vlname' `l'
			capture lab var `activity'_`l' "mpd on: `thelabel'"
		}

levelsof `activity', local(levels)

local vlname: value label `activity' 


foreach l of local levels {
	tempvar x
	gen `x'=0
	replace `x'=1 if `activity'==`l'
	bysort `diaryid': egen `activity'_`l'_n=total(`x')
	capture qui local thelabel: label `vlname' `l'
	capture lab var `activity'_`l'_n "n episodes: `thelabel'"
}

keep if epnum==1
drop `activity' 
drop start end epnum time clockst 

order `diaryid' `activity'_*

/* Add the 1440 check. */
	
tempvar y
gen `y'=0

foreach l of local levels {
	replace `y'=`y'+ `activity'_`l'
}
		
	
} // end of quietly

qui sum `y'
local e=1440-`r(mean)'

if `e'==0 {
	disp as text "The activities created, `activity'_1 to `activity'_n, add up to 1440 minutes."
}

else {
	disp as text "The activities created, `activity'_1 to `activity'_n, do not add up to 1440 minutes."
	disp as text "`activity' had missing values, recode them as valid numbers if you wish the program to create activity variables that add up to 1440 mpd."
}


end
