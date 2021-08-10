eststo clear
sysuse auto
local vlist price mpg weight
local rest `vlist'
foreach v of local vlist {
    estpost correlate `v' `rest' if foreign==0
    foreach m in b rho p count {
        matrix tmp = e(`m')
        matrix coleq tmp = "foreign=0"
        matrix `m' = tmp
    }
    estpost correlate `v' `rest' if foreign==1
    foreach m in b rho p count {
        matrix tmp = e(`m')
        matrix coleq tmp = "foreign=1"
        matrix `m' = `m', tmp
    }
    ereturn post b
    foreach m in rho p count {
        quietly estadd matrix `m' = `m'
    }
    eststo `v'
    local rest: list rest - v
}
esttab, nonumbers mtitles noobs not
