* 2.0.0 NJC 7 May 2003
* 1.0.1 NJC 29 January 1999
* 1.0.0 13 March 1998
* computes (i - a)/(n - 2a + 1)
program _gmypp
        version 8
        syntax newvarname =/exp [if] [in] [ , a(real 0.5) BY(string) ] 
        tempvar value i touse
        quietly {
                mark `touse' `if' `in'
                markout `touse' `exp'
                gen `value' = `exp' if `touse'
                bysort `touse' `by' (`value') : ///
			gen long `i' = _n if `value' < .
                by `touse' `by' : gen `varlist' = ///
                	(`i' - `a') / (`i'[_N] - 2 * `a' + 1)
                label var `varlist' "fraction of the data"
        }
end

