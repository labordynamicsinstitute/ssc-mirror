*! _fbardl_stars — Significance Stars for FBARDL
*! Version 1.0.0 — 2026-02-21
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _fbardl_stars
program define _fbardl_stars
    version 17
    args pval
    if `pval' < 0.01 {
        di as res " ***"
    }
    else if `pval' < 0.05 {
        di as res " **"
    }
    else if `pval' < 0.10 {
        di as res " *"
    }
    else {
        di as txt ""
    }
end
