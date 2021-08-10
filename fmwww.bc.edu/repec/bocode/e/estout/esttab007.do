sysuse auto
eststo: quietly regress price weight
eststo: quietly regress price weight mpg
eststo: quietly regress price weight mpg foreign
eststo: quietly regress price weight mpg foreign displacement
esttab, compress
eststo clear
