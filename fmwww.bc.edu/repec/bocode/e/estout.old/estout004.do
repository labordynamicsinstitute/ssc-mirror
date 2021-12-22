sysuse auto
eststo: quietly regress price weight mpg
eststo: quietly regress price weight mpg foreign
estout, stats(r2 bic N)
eststo clear
