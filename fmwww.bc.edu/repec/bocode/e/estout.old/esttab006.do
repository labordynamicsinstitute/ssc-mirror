sysuse auto
eststo: quietly regress price weight mpg
eststo: quietly regress price weight mpg foreign
esttab, plain
eststo clear