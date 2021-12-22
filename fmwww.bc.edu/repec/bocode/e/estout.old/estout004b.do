sysuse auto
eststo: quietly regress price weight
eststo: quietly regress price weight, robust
eststo: quietly regress price weight, vce(bootstrap)
estout, cells(b se(par)) stats(N vce)
eststo clear
