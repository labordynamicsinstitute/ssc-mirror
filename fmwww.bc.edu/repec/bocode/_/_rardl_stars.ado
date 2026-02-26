*! _rardl_stars — Significance star helper for rardl package
*! Version 1.0.0
capture program drop _rardl_stars
program define _rardl_stars, rclass
    version 17
    syntax , pval(real)
    
    if `pval' <= 0.01 {
        return local stars "***"
    }
    else if `pval' <= 0.05 {
        return local stars "**"
    }
    else if `pval' <= 0.10 {
        return local stars "*"
    }
    else {
        return local stars ""
    }
end
