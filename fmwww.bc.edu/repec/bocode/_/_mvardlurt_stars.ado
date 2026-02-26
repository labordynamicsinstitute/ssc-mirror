*! _mvardlurt_stars — Significance star formatting for mvardlurt
*! Version 1.0.0 — 2026-02-24

capture program drop _mvardlurt_stars
program define _mvardlurt_stars, rclass
    version 14

    syntax , pval(real)

    if `pval' < 0.01 {
        return local stars "***"
    }
    else if `pval' < 0.025 {
        return local stars "**"
    }
    else if `pval' < 0.05 {
        return local stars "*"
    }
    else if `pval' < 0.10 {
        return local stars "+"
    }
    else {
        return local stars ""
    }
end
