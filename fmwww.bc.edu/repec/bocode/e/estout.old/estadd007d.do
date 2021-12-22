capture program drop estadd_bstdy
program estadd_bstdy, eclass
    tempname bstdy
    matrix `bstdy' = e(b)
    quietly summarize `e(depvar)' if e(sample)
    matrix `bstdy' = `bstdy' / r(sd)
    ereturn matrix bstdy = `bstdy'
end
sysuse auto
eststo: quietly regress price weight mpg
eststo: quietly regress price weight mpg foreign
estadd bstdy : *
estout, cells(b bstdy(par))
eststo clear
