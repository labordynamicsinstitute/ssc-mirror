*! _mtnardl_stars — Significance stars helper for MTNARDL
*! Version 1.0.0 — 2026-02-24

capture program drop _mtnardl_stars
program define _mtnardl_stars
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
