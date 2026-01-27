
* Example 1: Average and marginal effective tax rates for an equity-financed project using default parameters
 etr
* Example 2: Average and marginal effective tax rates with non-default assumptions on inflation, tax depreciation, economic depreciation, and financing
etr, inflation(0.03) depreciation(0.1) delta(0.12) debt(0.5)

* Example 3: Average and marginal effective tax rates with non-default assumptions
*            on inflation, tax depreciation, economic depreciation, financing,
*            and personal income tax rates
etr, inflation(0.03) depreciation(0.1) delta(0.12) debt(0.5) pitint(0.10) pitdiv(0.12) pitcgain(0.15)

* Example 4: Average and marginal effective tax rates for an equity-financed project
*            under a cash-flow tax system
etr, system(cft)

* Example 5: Average and marginal effective tax rates for an equity-financed project
*            under a minimum tax regime with default parameters
etr, minimumtax(yes)

* Example 6: Average and marginal effective tax rates under a minimum tax regime
*            with non-default assumptions on inflation, depreciation, and financing
etr, inflation(0.04) depreciation(0.1) delta(0.12) debt(0.5) minimumtax(yes)

* Example 7: Average and marginal effective tax rates for an equity-financed project
*            under a minimum tax regime with a qualified tax incentive equal to
*            50% of payroll expense
etr, minimumtax(yes) qtil(0.5)

* Example 8: Average and marginal effective tax rates for an equity-financed project
*            under a minimum tax regime with a qualified tax incentive equal to
*            50% of depreciation
etr, minimumtax(yes) qtik(0.5)


*Example: A routine to analyze how the Average Effective Tax Rate (ETR) varies with inflation


*First, compute the AETR for inflation rates of 1, 3, and 5 percent.

forval i=1(2)5 {
    local j = `i' / 100
    etr,  inflation(`j')
   
   rename (coc metr metr2 aetr) (coc_`i' metr_`i' metr2_`i' aetr_`i')
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

graph bar (asis) aetr_5 aetr_3 aetr_1  if statutory_tax_rate == 10, ///
        over(statutory_tax_rate, lab(nolab))  ytitle("AETR Values (%)") ylabel(0(3)12) ///
        title("AETR Comparison at Statutory Tax Rate = 10%") ///
        legend(order(1 "Inflation 5%" 2 "Inflation 3%" 3 "Inflation 1%") position(3)) note("Statutory Tax Rate: 10%")
        


*Fourth, create a line graph to visualize the AETR for the three inflation rates accross statutory tax rates.

twoway (line aetr_5 statutory_tax_rate, lcolor(blue) lpattern(solid)) ///
   (line aetr_3 statutory_tax_rate, lcolor(red) lpattern(dash)) ///
    (line aetr_1 statutory_tax_rate, lcolor(green) lpattern(dot)), ///
    ytitle("AETR Values (%)") ylabel(, angle(0) nogrid labsize(medium) format(%9.0f)) ///
    xtitle("Statutory Tax Rate (%)", size(medium)) ///
    title("AETR Values for Different Inflation Rates") ///
    legend(order(1 "Inflation 5%" 2 "Inflation 3%" 3 "Inflation 1%") position(3))



*Example: A routine to analyze how the Average Effective Tax Rate (ETR) varies accross tax systems 
	
foreach var in cit cft ace { 
etr, system(`var')
rename aetr aetr_`var'
tempfile `var'
save  ``var'', replace
}
use `cit', clear
merge 1:1 statutory_tax_rate using `cft', gen(m1)
merge 1:1 statutory_tax_rate using `ace', gen(m2)

drop m*

twoway (line aetr_cit statutory_tax_rate, lcolor(blue) lpattern(solid)) ///
   (line aetr_cft statutory_tax_rate, lcolor(red) lpattern(dash)) ///
    (line aetr_ace statutory_tax_rate, lcolor(green) lpattern(dot)), ///
    ytitle("AETR Values (%)") ylabel(, angle(0) nogrid labsize(medium) format(%9.0f)) ///
    xtitle("Statutory Tax Rate (%)", size(medium)) ///
    title("Comparison of CIT, CFT, and ACE") ///
    legend(order(1 "CIT" 2 "CFT" 3 "ACE") position(3))


