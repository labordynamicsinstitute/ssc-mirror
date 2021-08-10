sysuse auto
eststo: quietly regress price weight mpg
eststo, noesample: quietly regress price weight mpg
_eststo: quietly regress price weight mpg
estimates dir
describe _est*
eststo clear
