sysuse auto
eststo: quietly regress price mpg foreign
estadd local hasrep "No"
eststo: xi: quietly regress price mpg foreign i.rep78
estadd local hasrep "Yes"
esttab, drop(_Irep78*) scalars("hasrep rep dummies")
eststo clear
