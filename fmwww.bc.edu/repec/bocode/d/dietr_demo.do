clear all

use "dietr_database.dta", clear

*first, defualt paramaters (no minimum tax, full loss refund,...)
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) 
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k)  system(cft)
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k)  system(ace) 



twoway (scatter METR_CIT  z, lcolor(blue) lpattern(solid)) ///
   (scatter METR_CFT z, lcolor(red) lpattern(dash)) ///
    (scatter METR_ACE z, lcolor(green) lpattern(dot)), ///
    ytitle("METR (%)") ylabel(, angle(0) nogrid labsize(medium) format(%9.0f)) ///
    xtitle("Statutory Tax Rate (%)", size(medium)) ///
    title("Comparison of CIT, CFT, and ACE")  ///
    legend(order(1 "CIT" 2 "CFT" 3 "ACE") position(3))

	
*** second, check the implication of a tax holiday


use "dietr_database.dta", clear
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) holiday(s)


***Third, compare the non-refundable systems
use "dietr_database.dta", clear

dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) refund(no)
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k)  system(cft) refund(no)
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k)  system(ace) refund(no)



twoway (scatter METR_CIT  z, lcolor(blue) lpattern(solid)) ///
   (scatter METR_CFT z, lcolor(red) lpattern(dash)) ///
    (scatter METR_ACE z, lcolor(green) lpattern(dot)), ///
    ytitle("METR (%)") ylabel(, angle(0) nogrid labsize(medium) format(%9.0f)) ///
    xtitle("Statutory Tax Rate (%)", size(medium)) ///
    title("Comparison of CIT, CFT, and ACE")  ///
    legend(order(1 "CIT" 2 "CFT" 3 "ACE") position(3))


*Fourth, compare the ETRs without and with a top-up tax
use "database.dta", clear

dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) 
rename		(coc_cit METR_CIT AETR_CIT) (coc_cit_n METR_CIT_n AETR_CIT_n)
tempfile	pretopup
save 		`pretopup',replace
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) minimumtax(yes) 
merge 1:1 x using `pretopup'


twoway (scatter METR_CIT_n  z, lcolor(blue) lpattern(solid)) ///
   (scatter METR_CIT z, lcolor(red) lpattern(dash)), ///
    ytitle("METR (%)") ylabel(, angle(0) nogrid labsize(medium) format(%9.0f)) ///
    xtitle("Statutory Tax Rate (%)", size(medium)) ///
    title("METR without and with a top-up tax")  ///
    legend(order(1 "without topup" 2 "with topup") position(3))
  

	