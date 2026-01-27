clear all


use dietr_database.dta, clear     // This demonstration do-file requires that dietr_demo.dta be saved in the current working directory.

*use "https://shafikhebous.com/data/dietr_database.dta", clear    // Alternatively, the data can be loaded from this location


***Example 1:  Calculate the METR and AETR of an equity-financed project using default parameters and no top-up tax:
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) inal(inal) delta(k)

foreach var in coc metr metr2 aetr {
	rename `var' `var'_ex1
}


***Example 2: Calculate the METR and AETR of an equity-financed project with a profitability of 30%:
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) inal(inal) p(0.3)
foreach var in coc metr metr2 aetr {
	rename `var' `var'_ex2
}

***Example 3: Calculate METR and AETR for a project with debt financing using variable loan:
gen loan=1
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) inal(inal) debt(loan)
foreach var in coc metr metr2 aetr {
	rename `var' `var'_ex3
}


***Example 4: Calculate ETRs assuming a cash-flow tax system
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k)  system(cft)
foreach var in coc metr metr2 aetr {
	rename `var' `var'_ex4
}

***Example 5: Calculate ETRs assuming an ACE tax system
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k)  inal(inal) system(ace) 
foreach var in coc metr metr2 aetr {
	rename `var' `var'_ex5
}

**Example 6: Calculate ETRs for a debt-financed project with personal income tax on interest, dividends, and capital gains

input 	interst 	div 	cgain
		0.10 	0.10 	0.10
		0.12 	0.12 	0.12
		0.15 	0.15 	0.15
		0.12 	0.1  	0.15
		0.1  	0.12  	0.15


dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k) inal(inal) debt(loan) pitint(interst) pitdiv(div) pitcgain(cgain)
foreach var in coc metr metr2 aetr {
	rename `var' `var'_ex6
}



**Compare the METRs of a CIT, CFT, and ACE system.
twoway (scatter metr_ex1 z, lcolor(blue) lpattern(solid)) ///
   (scatter metr_ex4 z, lcolor(red) lpattern(dash)) ///
    (scatter metr_ex5 z, lcolor(green) lpattern(dot)), ///
    ytitle("METR (%)") ylabel(, angle(0) nogrid labsize(medium) format(%9.0f)) ///
    xtitle("Statutory Tax Rate (%)", size(medium)) ///
    title("Comparison of CIT, CFT, and ACE")  ///
    legend(order(1 "CIT" 2 "CFT" 3 "ACE") position(3))


	
	
	
****Pillar two

***Since the pillar two part of the script only takes depreciaiton types Sl and DB, we need to replace the depreciaion type in the database.
replace b="sl" in 3

*Example 7: Calculate METR and AETR under a standard cit tax with a Pillar Two top-up tax:
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k)  system(cit) minimumtax(yes) 
rename (coc_cit metr_cit metr2_cit aetr_cit)(coc_ex7 metr_ex7 metr2_ex7 aetr_ex7)

***Example 8: alculate METR and AETR under a cash-flow tax with a Pillar Two top-up tax:
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k)  system(cft) minimumtax(yes)
rename (coc_cft metr_cft metr2_cft aetr_cft)(coc_ex8 metr_ex8 metr2_ex8 aetr_ex8)
	
***Example 9: Apply a Pillar Two minimum tax rate of 20%:
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k)  system(cit) minimumtax(yes) minrate(0.2)
rename (coc_cit metr_cit metr2_cit aetr_cit)(coc_ex9 metr_ex9 metr2_ex9 aetr_ex9)
	
***Example 10: use of payroll based qualified tax incentives (50% of the maximum)
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k)  system(cit) minimumtax(yes) qtil(0.5)
rename (coc_cit metr_cit metr2_cit aetr_cit)(coc_ex10 metr_ex10 metr2_ex10 aetr_ex10)

***Example 10: Change the coefficnit of the payroll tax incentive to 4% for of payroll based qualified tax incentives (50% of the maximum)
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k)  system(cit) minimumtax(yes) qtil(0.5) sl(0.04)
rename (coc_cit metr_cit metr2_cit aetr_cit)(coc_ex11 metr_ex11 metr2_ex11 aetr_ex11)

***Example 11: use of depreciation based qualified tax incentives(50% of the maximum)
dietr , id(x) taxrate(z) inflation(a) deprtype(b) depreciation(c) delta(k)  system(cit) minimumtax(yes) qtik(0.5)
rename (coc_cit metr_cit metr2_cit aetr_cit)(coc_ex12 metr_ex12 metr2_ex12 aetr_ex12)