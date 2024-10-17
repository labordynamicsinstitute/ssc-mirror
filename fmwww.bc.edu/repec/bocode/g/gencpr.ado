/*
Version 2024-10-14 (yyyy-mm-dd)
*/

capture program drop gencpr
program gencpr

version 18.0
syntax newvarname [if] [in], From(varname string) [MODulus] [GENder] [BIRTHday] [AGEat(varname numeric)] [AGEFracat(varname numeric)] [GT100]
tempvar touse

mark `touse' `if' `in'

**Generate string variable of cpr in the format 012345-1234
di ". generating `varlist'"
cap: gen str11 `varlist'="" if `touse', a(`from')
local signs `" |\-|\/|\."'
di as res ". cleaning patterns such as 012345-1234, 12345-1234, 0123451234, 123451234 and ddmm20åå-1234"
replace `varlist' = cond(regexs(1)=="","0",regexs(1))+regexs(2)+regexs(3)+"-"+regexs(4) if regexm(`from', "([0-9]?)([0-9][0-9][0-9])[19|20]?([0-9][0-9])[ |\-]?([0-9][0-9][0-9][0-9])[ ]*$") & `varlist'=="" & `touse'
di as res ". cleaning patterns such as 012345-xxxx, 12345-abcd, 012345XXXX and 12345ABCD"
replace `varlist' = cond(regexs(1)=="","0",regexs(1))+regexs(2)+"-????" if regexm(`from', "([0-9]?)([0-9][0-9][0-9][0-9][0-9])[ |\-]?([ a-zA-Z][ a-zA-Z][ a-zA-Z][ a-zA-Z])$") & `varlist'=="" & `touse'
di as res ". cleaning patterns such as dd.mm.yyyy, d-mm-yy, dd.mm-yyyy and dd/mm/yy"
replace `varlist' = cond(regexs(1)=="","0"+regexs(2),regexs(1)+regexs(2))+regexs(3)+regexs(4)+"-????" if regexm(`from', "([0-9]?)([0-9])[`signs']?([0-9][0-9])[19|20|`signs']?([0-9][0-9])*$") & `varlist'=="" & `touse'
lab var `varlist' "CPR numbers"

**Modulus-11 test for validity of cpr
if "`modulus'" != "" {
	di ""
	di as res ". generating {it:mod11}"
	gen mod11=(real(usubstr(`varlist',1,1))*4 ///
			+ real(usubstr(`varlist',2,1))*3 ///
			+ real(usubstr(`varlist',3,1))*2 ///
			+ real(usubstr(`varlist',4,1))*7 ///
			+ real(usubstr(`varlist',5,1))*6 ///
			+ real(usubstr(`varlist',6,1))*5 ///
			+ real(usubstr(`varlist',8,1))*4 ///
			+ real(usubstr(`varlist',9,1))*3 ///
			+ real(usubstr(`varlist',10,1))*2 ///
			+ real(usubstr(`varlist',11,1))*1)/11 if `varlist'!="" & `touse', a(`varlist') 
	replace mod11=(mod11==int(mod11) & mod11!=.) if `varlist'!="" & `touse'
	lab var mod11 "Modulus 11 valid CPR"
	cap: lab def mod11lab 0 "Invalid CPR" 1 "Valid CPR"
	lab val mod11 mod11lab
	tab mod11, m
	di as text "Note: An invalid CPR pattern can be a true CPR number, and some"
	di as text "CPR patterns (e.g. 000000-0000) are not true CPR numbers."
	di as text "So you should only use the Modulus-11 test as a guideline"
	di ""
}

**Gender
if "`gender'" != "" {
di as res ". generate variable {it:koen} from last digit in {it:`varlist'}"
	gen koen=regexm(usubstr(`varlist',11,1),"[1 3 5 7 9]") if regexm(usubstr(`varlist',11,1),"[0-9]") & `touse', a(`varlist')
	lab var koen "Gender"
	cap: lab def koenlab 0 Female 1 Male
	lab val koen koenlab
}

if "`gt100'" == "" {

*Birthday
if "`birthday'" != "" {
di as res ". generate variable {it:birthday} from first 6 digits in {it:`varlist'}"
	gen birthday = date(usubstr(`varlist',1,6),"DMY",real(usubstr(c(current_date),-4,4))) if `touse', a(`varlist')
	format %-td birthday
	lab var birthday "Birthday"
}

**Age
if "`ageat'" != "" {	
di as res ". generate variable {it:age}"
	gen age=age(date(usubstr(`varlist',1,6),"DMY",real(usubstr(c(current_date),-4,4))) , `ageat' , "01mar") if `varlist'!="" & `touse', a(`varlist')
	lab var age "Age in years"
}

*Age_frac
if "`agefracat'" != "" {	
di as res ". generate variable {it:age_frac}"
	gen age_frac=age_frac(date(usubstr(`varlist',1,6),"DMY",real(usubstr(c(current_date),-4,4))) , `agefracat' , "01mar") if `varlist'!="" & `touse', a(`varlist')
	lab var age_frac "Age in years, including the fractional part"
}
}

*gt100
if "`gt100'" != "" {

*Birthday
if "`birthday'" != "" {
di as res ". generate variable {it:birthday} from first 7 digits in {it:`varlist'}"
	cap: gen birthday = . if `varlist'!="" & `touse', a(`varlist')
	di as text "(born during 1900-1999)"
	replace birthday = date(usubstr(`varlist',1,6),"DMY",1999) if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="0" & usubstr(`varlist',8,1)<="3"
	di as text "(born during 2000-2036)"
	replace birthday = date(usubstr(`varlist',1,6),"DMY",2036) if `varlist'!="" & `touse' & usubstr(`varlist',8,1)=="4" & usubstr(`varlist',5,2)<="36"
	di as text "(born during 1937-1999)"
	replace birthday = date(usubstr(`varlist',1,6),"DMY",1999) if `varlist'!="" & `touse' & usubstr(`varlist',8,1)=="4" & usubstr(`varlist',5,2)>="37"
	di as text "(born during 2000-2057)"
	replace birthday = date(usubstr(`varlist',1,6),"DMY",2057) if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="5" & usubstr(`varlist',8,1)<="8" & usubstr(`varlist',5,2)<="57"
	di as text "(born during 1858-1899)"
	replace birthday = date(usubstr(`varlist',1,6),"DMY",1899) if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="5" & usubstr(`varlist',8,1)<="8" & usubstr(`varlist',5,2)>="58"
	di as text "(born during 2000-2036)"
	replace birthday = date(usubstr(`varlist',1,6),"DMY",2036) if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="9" & usubstr(`varlist',5,2)<="36"
	di as text "(born during 1937-1999)"
	replace birthday = date(usubstr(`varlist',1,6),"DMY",1999) if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="9" & usubstr(`varlist',5,2)>="37"
	format %-td birthday
	lab var birthday "Birthday"
}

**Age
if "`ageat'" != "" {	
di as res ". generate variable {it:age}"
	cap: gen age=. if `varlist'!="" & `touse', a(`varlist')
	di as text "(born during 1900-1999)"
	replace age=age(date(usubstr(`varlist',1,6),"DMY",1999) , `ageat' , "01mar") if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="0" & usubstr(`varlist',8,1)<="3"
	di as text "(born during 2000-2036)"
	replace age=age(date(usubstr(`varlist',1,6),"DMY",2036) , `ageat' , "01mar") if `varlist'!="" & `touse' & usubstr(`varlist',8,1)=="4" & usubstr(`varlist',5,2)<="36"
	di as text "(born during 1937-1999)"
	replace age=age(date(usubstr(`varlist',1,6),"DMY",1999) , `ageat' , "01mar") if `varlist'!="" & `touse' & usubstr(`varlist',8,1)=="4" & usubstr(`varlist',5,2)>="37"
	di as text "(born during 2000-2057)"
	replace age=age(date(usubstr(`varlist',1,6),"DMY",2057) , `ageat' , "01mar") if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="5" & usubstr(`varlist',8,1)<="8" & usubstr(`varlist',5,2)<="57"
	di as text "(born during 1858-1899)"
	replace age=age(date(usubstr(`varlist',1,6),"DMY",1899) , `ageat' , "01mar") if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="5" & usubstr(`varlist',8,1)<="8" & usubstr(`varlist',5,2)>="58"
	di as text "(born during 2000-2036)"
	replace age=age(date(usubstr(`varlist',1,6),"DMY",2036) , `ageat' , "01mar") if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="9" & usubstr(`varlist',5,2)<="36"
	di as text "(born during 1937-1999)"
	replace age=age(date(usubstr(`varlist',1,6),"DMY",1999) , `ageat' , "01mar") if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="9" & usubstr(`varlist',5,2)>="37"
	lab var age "Age in years"
}

*Age_frac
if "`agefracat'" != "" {	
di as res ". generate variable {it:age_frac}"
	cap: gen age_frac=. if `varlist'!="" & `touse', a(`varlist')
	di as text "(born during 1900-1999"
	replace age_frac=age_frac(date(usubstr(`varlist',1,6),"DMY",1999) , `agefracat' , "01mar") if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="0" & usubstr(`varlist',8,1)<="3"
	di as text "(born during 2000-2036)"
	replace age_frac=age_frac(date(usubstr(`varlist',1,6),"DMY",2036) , `agefracat' , "01mar") if `varlist'!="" & `touse' & usubstr(`varlist',8,1)=="4" & usubstr(`varlist',5,2)<="36"
	di as text "(born during 1937-1999)"
	replace age_frac=age_frac(date(usubstr(`varlist',1,6),"DMY",1999) , `agefracat' , "01mar") if `varlist'!="" & `touse' & usubstr(`varlist',8,1)=="4" & usubstr(`varlist',5,2)>="37"
	di as text "(born during 2000-2057)"
	replace age_frac=age_frac(date(usubstr(`varlist',1,6),"DMY",2057) , `agefracat' , "01mar") if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="5" & usubstr(`varlist',8,1)<="8" & usubstr(`varlist',5,2)<="57"
	di as text "(born during 1858-1899)"
	replace age_frac=age_frac(date(usubstr(`varlist',1,6),"DMY",1899) , `agefracat' , "01mar") if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="5" & usubstr(`varlist',8,1)<="8" & usubstr(`varlist',5,2)>="58"
	di as text "(born during 2000-2036)"
	replace age_frac=age_frac(date(usubstr(`varlist',1,6),"DMY",2036) , `agefracat' , "01mar") if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="9" & usubstr(`varlist',5,2)<="36"
	di as text "(born during 1937-1999)"
	replace age_frac=age_frac(date(usubstr(`varlist',1,6),"DMY",1999) , `agefracat' , "01mar") if `varlist'!="" & `touse' & usubstr(`varlist',8,1)>="9" & usubstr(`varlist',5,2)>="37"
	lab var age_frac "Age in years, including the fractional part"
}

di as res "Note: option {opt gt100} uses the 7th digits in {it:`varlist'} to determine the birth century,"
di as res "so you should make sure that the 7th digits in {it:`varlist'} is correct"

}
end



