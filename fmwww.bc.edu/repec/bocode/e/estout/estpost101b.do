sysuse auto
by foreign: eststo: quietly estpost summarize price mpg rep78, listwise
esttab, cells("mean sd") label nodepvar
eststo clear
