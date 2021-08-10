sysuse auto
quietly regress price weight mpg
test weight = mpg
eststo, addscalars(p_diff r(p))
esttab, scalars(p_diff) obslast
eststo clear
