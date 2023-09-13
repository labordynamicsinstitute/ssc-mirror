*! Version	: 0.12
*! Author	: Niels Henrik Bruun, Research data and statistics, Aalborg University Hospital
/*
2021-04-20 > Code rewritten and DEFACTUM weights added
2016-12-18 > Minor alterations
2015-12-09 > First version
*/

version 12

capture program drop sf12
program define sf12
	syntax varlist(min=12 max=12), [Weights(string) noQuietly Clear Prefix(string)]
	* 1  2   3   4   5   6   7   8  9   10  11  12
	* i1 i2a i2b i3a i3b i4a i4b i5 i6a i6b i6c i7
    
    if "`quietly'" != "" local QUIETLY ""
    else local QUIETLY quietly
    if "`clear'" != "" capture drop `prefix'pf `prefix'rp `prefix'bp `prefix'gh ///
		`prefix'vt `prefix'sf `prefix're `prefix'mh `prefix'agg_phys agg_ment
    
    `QUIETLY' _create_scales `varlist' , prefix("`prefix'")
    if "`weights'" == "" local weights us1990
    if "`weights'" == "us1990" {
        local weights "NEMC (US 1990)"
        `QUIETLY' _scores_us1990, prefix("`prefix'")
    }
    else if "`weights'" == "dk2018" {
        local weights "DEFACTUM (2018)"
        `QUIETLY' _scores_dk2018, prefix("`prefix'")
    }
    else mata: _error("Weights not found.")

    * Add labels and notes
    label variable `prefix'pf "`weights' physical functioning t-score"
    label variable `prefix'rp "`weights' role limitation physical t-score"
    label variable `prefix'bp "`weights' pain t-score"
    label variable `prefix'gh "`weights' general health t-score"
    label variable `prefix'vt "`weights' vitality t-score"
    label variable `prefix're "`weights' role limitation emotional t-score"
    label variable `prefix'sf "`weights' social functioning t-score"
    label variable `prefix'mh "`weights' mental health t-score"
    label variable `prefix'agg_phys "`weights' physical health t-score - sf12"
    label variable `prefix'agg_ment "`weights' mental health t-score - sf12"
    note `prefix'pf: Based on `2' (i2a) and `3' (i2b)
    note `prefix'rp: Based on `4' (i3a) and `5' (i3b)
    note `prefix'bp: Based on reversed `8' (i5)
    note `prefix'gh: Based on reversed `1' (i1)
    note `prefix'vt: Based on reversed `10' (i6b)
    note `prefix're: Based on `6' (i4a) and `7' (i4b)
    note `prefix'sf: Based on `12' (i7)
    note `prefix'mh: Based on `reversed 9' (i6a) and `11' (i6c)
    note `prefix'agg_phys: Based on all
    note `prefix'agg_ment: Based on all
	format `prefix'pf-`prefix'agg_ment %6.2f
end

capture program drop _create_scales
program define _create_scales
	syntax varlist(min=12 max=12) [, prefix(string)]
	* 1  2   3   4   5   6   7   8  9   10  11  12
	* i1 i2a i2b i3a i3b i4a i4b i5 i6a i6b i6c i7

    * WHEN NECESSARY, REVERSE CODE ITEMS SO A HIGHER SCORE MEANS BETTER HEALTH
    *						i1	 i5  i6a i6b
    foreach var of varlist `1' `8' `9' `10' {
        tempvar `var'r
        generate double ``var'r' = 6 - `var' if inlist(`var', 1,2,3,4,5)
    }
    replace ``1'r' = 4.4 if ``1'r' == 4 //i1
    replace ``1'r' = 3.4 if ``1'r' == 3 //i1
    
    * CREATE SCALES AND CODE OUT-OF-RANGE VALUES TO MISSING
    generate double `prefix'pf = 100 * (`2' + `3' - 2) / 4 ///
        if inlist(`2', 1,2,3) & inlist(`3', 1,2,3) //i2*
    generate double `prefix'rp = 100 * (`4' + `5' - 2) / 8 ///
        if inlist(`4', 1,2,3,4,5) & inlist(`5', 1,2,3,4,5) //i3*
    generate double `prefix'bp = 100 * (``8'r' - 1) / 4 if inlist(`8', 1,2,3,4,5) // i5
    generate double `prefix'gh = 100 * (``1'r' - 1) / 4 if inlist(`1', 1,2,3,4,5) //i1
    generate double `prefix'vt = 100 * (``10'r' - 1) / 4 if inlist(`10', 1,2,3,4,5) // i6b
    generate double `prefix'sf = 100 * (`12' - 1) / 4 if inlist(`12', 1,2,3,4,5) // i7
    generate double `prefix're = 100 * (`6' + `7' - 2) / 8 ///
        if inlist(`6', 1,2,3,4,5) & inlist(`7', 1,2,3,4,5) // i4*
    generate double `prefix'mh = 100 * (``9'r' + `11' - 2) / 8 ///
        if inlist(`9', 1,2,3,4,5) & inlist(`11', 1,2,3,4,5) // i6a i6c
end

capture program drop _scores_us1990
program define _scores_us1990
	syntax , [prefix(string)]

    * 1) TRANSFORM SCORES TO Z-SCORES 
    *** US GENERAL POPULATION MEANS AND SD'S ARE USED HERE (NOT AGE/GENDER BASED)
    replace `prefix'pf = (`prefix'pf - 81.18122) / 29.10588
    replace `prefix'rp = (`prefix'rp - 80.52856) / 27.13526
    replace `prefix'bp = (`prefix'bp - 81.74015) / 24.53019
    replace `prefix'gh = (`prefix'gh - 72.19795) / 23.19041
    replace `prefix'vt = (`prefix'vt - 55.59090) / 24.84380
    replace `prefix'sf = (`prefix'sf - 83.73973) / 24.75775
    replace `prefix're = (`prefix're - 86.41051) / 22.35543
    replace `prefix'mh = (`prefix'mh - 70.18217) / 20.50597

    * 2) CREATE PHYSICAL AND MENTAL HEALTH COMPOSITE SCORES
    *** MULTIPLY Z-SCORES BY VARIMAX-ROTATED FACTOR SCORING COEFFICIENTS AND SUM THE PRODUCTS
    generate double `prefix'agg_phys 	= (`prefix'pf * 0.42402) + (`prefix'rp * 0.35119) ///
										+ (`prefix'bp * 0.31754) + (`prefix'gh * 0.24954) ///
										+ (`prefix'vt * 0.02877) + (`prefix'sf * -.00753) ///
										+ (`prefix're * -.19206) + (`prefix'mh * -.22069)

    generate double `prefix'agg_ment	= (`prefix'pf * -.22999) + (`prefix'rp * -.12329) ///
                                + (`prefix'bp * -.09731) + (`prefix'gh * -.01571) ///
                                + (`prefix'vt * 0.23534) + (`prefix'sf * 0.26876) ///
                                + (`prefix're * 0.43407) + (`prefix'mh * 0.48581)

    * 3) TRANSFORM COMPOSITE AND SCALE SCORES TO T-SCORES
    foreach var of varlist `prefix'pf-`prefix'agg_ment {
        replace `var' = 50 + (`var' * 10)
    }
end

capture program drop _scores_dk2018
program define _scores_dk2018
	syntax , [prefix(string)]

    * 1) TRANSFORM SCORES TO Z-SCORES 
    *** DEFACTUM, Region Midtjylland 2018 means and SDs
    replace `prefix'pf = (`prefix'pf - 83.01098) / 28.03756
    replace `prefix'rp = (`prefix'rp - 79.23666) / 27.12947
    replace `prefix'bp = (`prefix'bp - 78.64166) / 27.46395
    replace `prefix'gh = (`prefix'gh - 68.06165) / 24.67408
    replace `prefix'vt = (`prefix'vt - 53.79299) / 25.97755
    replace `prefix'sf = (`prefix'sf - 85.16767) / 23.98612
    replace `prefix're = (`prefix're - 80.78423) / 25.22565
    replace `prefix'mh = (`prefix'mh - 70.08673) / 20.66073

    * 2) CREATE PHYSICAL AND MENTAL HEALTH COMPOSITE SCORES
    *** MULTIPLY Z-SCORES BY ROTATE OBLIQUE PROMAX(3) FACTOR SCORING COEFFICIENTS AND SUM THE PRODUCTS
    ***
    generate double `prefix'agg_phys    =   (`prefix'pf * 0.20112) + (`prefix'rp * 0.38361) ///
										+   (`prefix'bp * 0.23444) + (`prefix'gh * 0.16524) ///
										+   (`prefix'vt * 0.05528) + (`prefix'sf * 0.03314) ///
										+   (`prefix're * 0.05660) + (`prefix'mh * -0.02012) 

    generate double `prefix'agg_ment	=   (`prefix'pf * -0.02180) + (`prefix'rp * 0.05336) ///
										+   (`prefix'bp * 0.01414) + (`prefix'gh * 0.09961) ///
										+   (`prefix'vt * 0.21575) + (`prefix'sf * 0.20673) ///
										+   (`prefix're * 0.24391) + (`prefix'mh * 0.31583)

    * 3) TRANSFORM COMPOSITE AND SCALE SCORES TO T-SCORES
    foreach var of varlist `prefix'pf-`prefix'agg_ment {
        replace `var' = 50 + (`var' * 10)
    }
end
