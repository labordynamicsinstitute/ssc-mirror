sysuse auto
eststo: quietly regress price weight mpg
eststo: quietly regress price weight mpg foreign
esttab, b(a6) p(4) r2(4) nostar wide
eststo clear
