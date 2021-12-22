sysuse auto
quietly regress price weight mpg
eststo
quietly regress price weight mpg foreign
eststo
esttab
eststo clear
