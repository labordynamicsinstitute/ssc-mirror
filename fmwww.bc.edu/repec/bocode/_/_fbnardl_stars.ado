*! _fbnardl_stars — Display significance stars for FBNARDL package
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _fbnardl_stars
program define _fbnardl_stars
    version 17
    args pval
    if `pval' < 0.001 {
        di as res " ***"
    }
    else if `pval' < 0.01 {
        di as res " **"
    }
    else if `pval' < 0.05 {
        di as res " *"
    }
    else if `pval' < 0.1 {
        di as res " ."
    }
    else {
        di as txt ""
    }
end
