program flagout
    version 13
    syntax varname [pweight] [if], item(varlist max=1) [over(varlist) z(real 3.5) minn(integer 30) VERbose]

    tempfile stats
    tempvar p10 p25 center p75 p90 n scale i

    gen `i' = 1 if `varlist' < .

    preserve
        collapse (p10) `p10' = `varlist' (p25) `p25' = `varlist' (p50) `center' = `varlist' (p75) `p75' = `varlist' (p90) `p90' = `varlist' (rawsum) `n' = `i' [`weight'`exp'], by(`item')
        qui gen `scale' = (`p75'-`p25')/1.35
        qui replace `scale' = (`p90'-`p10')/2.56 if `scale' == 0 
        keep `item' `center' `scale' `n'
        qui save `stats'
    restore

    qui merge m:1 `item' using `stats', assert(match) nogen

if "`over'" != "" {
    foreach var of varlist `over' {
        tempfile stats_`var'
        preserve
            collapse (p10) `p10' = `varlist' (p25) `p25' = `varlist' (p50) `center' = `varlist' (p75) `p75' = `varlist' (p90) `p90' = `varlist' (rawsum) `n' = `i' [`weight'`exp'], by(`item' `var')
            qui drop if `n' < `minn'
            gen `scale' = (`p75'-`p25')/1.35
            qui replace `scale' = (`p90'-`p10')/2.56 if `scale' == 0 
            keep `item' `var' `center' `scale' 
            qui save `stats_`var''
        restore

        qui merge m:1 `item' `var' using `stats_`var'',  update replace nogen
    }
}

    qui count if `scale' == 0
    if r(N) > 0 {
        di as err _n "warning: items with 0 scale (p10 = p90)."
        di as err "Any value not equal to p10 = p90 will be flagged as outlier"
        tab `item' if `scale' == 0 & `varlist' < .
    }
    qui count if `n' < `minn' 
    if r(N) > 0 {
        di as err _n "warning: items with less than `minn' observations globally"
        di as err "No values flagged as outlier for this items."
        tab `item' if `n' < `minn' & `varlist' < .
    }

    qui cap gen _flag = 0 if `varlist' < . & `n' > `minn'
    if _rc == 110 {
        di "_flag already exists, dropping"
        drop _flag
        qui gen _flag = 0 if `varlist' < . & `n' > `minn'
    }
    qui cap gen _min  = `center' - `z'*`scale'
    if _rc == 110 {
        di "_min already exists, dropping"
        drop _min
        qui gen _min = `center' - `z'*`scale'
    }
    qui cap gen _max  = `center' + `z'*`scale'
    if _rc == 110 {
        di "_max already exists, dropping"
        drop _max
        qui gen _max = `center' + `z'*`scale'
    }

    if "`verbose'" == "verbose" {
        di "table"
        lab var `scale' "scale"
        lab var `n' "global N"
        table `item', stat(mean _min `center' _max `scale' `n')
    }

    qui cap gen _median = `center' // can use this to impute
    if _rc == 110 {
        di "_median already exists, dropping"
        drop _median
        qui gen _median = `center'
    }

    qui replace _flag = -1 if `varlist' < _min & `varlist' < . & `n' > `minn'
    qui replace _flag = 1  if `varlist' > _max & `varlist' < . & `n' > `minn'

    if "`verbose'" == "verbose" {
        tempvar up low
        qui gen `up' = 100 *(_flag == 1) if `varlist' < .
        qui gen `low' = 100 *(_flag == -1) if `varlist' < .
        lab var `up' "% upper outliers"
        lab var `low' "% lower outliers"
        table `item', stat(mean `low' `up')
    }

    tempname xx
    lab def `xx' -1 "lower" 0 "nonoutlier" 1 "upper"
    lab val _flag `xx'

    tab _flag if `varlist' < ., m

end