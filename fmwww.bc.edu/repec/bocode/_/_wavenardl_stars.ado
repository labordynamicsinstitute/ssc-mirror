*! _wavenardl_stars 1.0.1  02jul2026 - significance stars helper for wavenardl
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _wavenardl_stars
program define _wavenardl_stars
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
