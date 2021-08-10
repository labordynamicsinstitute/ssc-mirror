eststo clear
sysuse auto
local vlist price mpg weight
local upper
local lower `vlist'
foreach v of local vlist {
    estpost correlate `v' `lower' if foreign==1
    foreach m in b rho p count {
        matrix `m' = e(`m')
    }
    if "`upper'"!="" {
        estpost correlate `v' `upper' if foreign==0
        foreach m in b rho p count {
            matrix `m' = e(`m'), `m'
        }
    }
    ereturn post b
    foreach m in rho p count {
        quietly estadd matrix `m' = `m'
    }
    eststo `v'
    local lower: list lower - v
    local upper `upper' `v'
}
esttab, nonumbers mtitles noobs not
