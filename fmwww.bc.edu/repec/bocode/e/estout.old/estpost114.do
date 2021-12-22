sysuse auto
estpost ci price mpg rep78, listwise
esttab, cells("b se lb ub") label
