sysuse auto
set seed 123
generate altmpg = invnorm(uniform())
eststo: quietly regress price weight mpg
eststo: quietly regress price weight altmpg
esttab
esttab, rename(altmpg mpg)
eststo clear
