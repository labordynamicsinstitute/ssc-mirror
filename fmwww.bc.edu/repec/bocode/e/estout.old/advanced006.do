sysuse auto
eststo: quietly regress price mpg foreign
eststo: xi: quietly regress price mpg foreign i.rep78
esttab, indicate(rep dummies = _Irep78*)
eststo clear
