*! version 1.0.0  20mar2026  Dr. Merwan Roudane
*! _lrmbounds_stars: Significance star helpers for lrmbounds

capture program drop _lrmbounds_stars
program define _lrmbounds_stars, sclass
    args pval
    if missing(`pval')       sreturn local s ""
    else if `pval' < 0.01    sreturn local s "***"
    else if `pval' < 0.05    sreturn local s "**"
    else if `pval' < 0.10    sreturn local s "*"
    else                     sreturn local s ""
end

capture program drop _lrmbounds_decision
program define _lrmbounds_decision, sclass
    * Given a test statistic, lower bound, upper bound, and test type
    * Returns decision string
    args tstat lb ub testtype
    
    if "`testtype'" == "f" {
        * F-test: reject if above upper bound
        if `tstat' > `ub' {
            sreturn local decision "Reject H0"
            sreturn local dcode "reject"
        }
        else if `tstat' < `lb' {
            sreturn local decision "Fail to Reject"
            sreturn local dcode "fail"
        }
        else {
            sreturn local decision "Inconclusive"
            sreturn local dcode "inconclusive"
        }
    }
    else {
        * t-test: reject if |t| > upper bound (bounds are positive, t is negative)
        local abst = abs(`tstat')
        if `abst' > `ub' {
            sreturn local decision "Reject H0"
            sreturn local dcode "reject"
        }
        else if `abst' < `lb' {
            sreturn local decision "Fail to Reject"
            sreturn local dcode "fail"
        }
        else {
            sreturn local decision "Inconclusive"
            sreturn local dcode "inconclusive"
        }
    }
end

capture program drop _lrmbounds_center
program define _lrmbounds_center
    syntax , TEXT(string) WIDTH(integer)
    local len = udstrlen("`text'")
    if `len' >= `width' {
        di "`text'" _continue
    }
    else {
        local lpad = int((`width' - `len')/2)
        di _skip(`lpad') "`text'" _continue
    }
end
