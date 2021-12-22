sysuse auto
quietly regress price weight mpg
eststo model1
quietly regress price weight mpg foreign
eststo model2
estimates table model1 model2
eststo clear
