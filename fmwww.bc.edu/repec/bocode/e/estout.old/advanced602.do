sysuse auto
generate y = uniform()
by foreign: eststo: quietly regress y price weight mpg, nocons
estadd summ : *
esttab, main(mean) aux(sd) label nodepvar nostar nonote
eststo clear
