*First example: A routine to analyze how the Average Effective Tax Rate (ETR) varies with inflation

quietly {
*First, compute the AETR for inflation rates of 1, 3, and 5 percent.
		forval i=1(2)5 {
			local j = `i' / 100
			etr,  inflation(`j')
			rename AETR AETR`i'per
			rename METR METR`i'per
			tempfile etr`i'per
			save `etr`i'per.dta', replace
						}

*Second, merge the files together to produce a single file containing AETR for all inflation rates.

		tempfile mergedfile
		use `etr1per.dta', clear
		save `mergedfile', replace

		forval i=3(2)5 {
			use `etr`i'per.dta', clear
			merge 1:1 statutory_tax_rate using `mergedfile', gen(_merge`i')
			save `mergedfile', replace
						}


*Third, create a bar graph to visualize the AETR for the three inflation rates at a single statutory tax rate.

graph bar (asis) AETR5per AETR3per AETR1per  if statutory_tax_rate == 10, ///
        over(statutory_tax_rate, lab(nolab))  ytitle("AETR Values (%)") ylabel(0(3)12) ///
        title("AETR Comparison at Statutory Tax Rate = 10%") ///
        legend(order(1 "Inflation 5%" 2 "Inflation 3%" 3 "Inflation 1%") position(3)) note("Statutory Tax Rate: 10%")
        
}     // closes quitely      

*Fourth, create a line graph to visualize the AETR for the three inflation rates accross statutory tax rates.

twoway (line AETR5per statutory_tax_rate, lcolor(blue) lpattern(solid)) ///
   (line AETR3per statutory_tax_rate, lcolor(red) lpattern(dash)) ///
    (line AETR1per statutory_tax_rate, lcolor(green) lpattern(dot)), ///
    ytitle("AETR Values (%)") ylabel(, angle(0) nogrid labsize(medium) format(%9.0f)) ///
    xtitle("Statutory Tax Rate (%)", size(medium)) ///
    title("AETR Values for Different Inflation Rates") ///
    legend(order(1 "Inflation 5%" 2 "Inflation 3%" 3 "Inflation 1%") position(3))








******Second example: A routine to analyze how the Average Effective Tax Rate (ETR) varies accross tax systems (non-refundable)
quietly {
	
foreach var in cit cft ace { 
etr, system(`var') refund(no)
rename AETR AETR_`var'
tempfile `var'
save  ``var'', replace
}
use `cit', clear
merge 1:1 statutory_tax_rate using `cft', gen(m1)
merge 1:1 statutory_tax_rate using `ace', gen(m2)

drop m*

twoway (line AETR_cit statutory_tax_rate, lcolor(blue) lpattern(solid)) ///
   (line AETR_cft statutory_tax_rate, lcolor(red) lpattern(dash)) ///
    (line AETR_ace statutory_tax_rate, lcolor(green) lpattern(dot)), ///
    ytitle("AETR Values (%)") ylabel(, angle(0) nogrid labsize(medium) format(%9.0f)) ///
    xtitle("Statutory Tax Rate (%)", size(medium)) ///
    title("Comparison of CIT, CFT, and ACE") ///
    legend(order(1 "CIT" 2 "CFT" 3 "ACE") position(3))
}


