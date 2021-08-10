sysuse auto
eststo: quietly regress price weight mpg
eststo: quietly regress price weight mpg foreign
estadd beta : *
estout, cells(beta) drop(_cons)
eststo clear
