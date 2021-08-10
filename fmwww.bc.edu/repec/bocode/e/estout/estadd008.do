sysuse auto
by foreign: eststo: quietly regress price weight mpg
estadd summ : *
estout, cells(mean sd(par)) drop(_cons)
eststo clear
