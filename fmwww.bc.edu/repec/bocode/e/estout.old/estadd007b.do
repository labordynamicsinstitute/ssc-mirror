capture program drop estadd_R
program estadd_R, eclass
    ereturn scalar R = sqrt(e(r2))
end
sysuse auto
eststo: quietly regress price weight mpg
eststo: quietly regress price weight mpg foreign
estadd R : *
estout, stats(r2 R)
eststo clear
