*! _qvar_significance_stars.ado — Return significance stars
*! Version 1.1.0

program define _qvar_significance_stars, rclass
    version 16.0
    args pvalue

    if `pvalue' < 0.01 {
        return local stars "***"
    }
    else if `pvalue' < 0.05 {
        return local stars "**"
    }
    else if `pvalue' < 0.10 {
        return local stars "*"
    }
    else {
        return local stars ""
    }
end
