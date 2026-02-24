*! _aardl_stars — Significance stars utility for aardl package
*! Version 1.0.0

capture program drop _aardl_stars
program define _aardl_stars
    args pval
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
