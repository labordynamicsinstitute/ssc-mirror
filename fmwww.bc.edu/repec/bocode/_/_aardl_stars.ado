*! _aardl_stars — significance stars utility for aardl
*! Version 2.0.0
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _aardl_stars
program define _aardl_stars
    version 17
    args pval
    if "`pval'" == "" {
        di as txt ""
        exit
    }
    if missing(`pval') {
        di as txt ""
        exit
    }
    if `pval' < 0.01 {
        di as txt " ***"
    }
    else if `pval' < 0.05 {
        di as txt " **"
    }
    else if `pval' < 0.10 {
        di as txt " *"
    }
    else {
        di as txt ""
    }
end
