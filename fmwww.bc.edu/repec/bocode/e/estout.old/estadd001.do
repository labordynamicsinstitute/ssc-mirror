sysuse auto
quietly regress price weight mpg
estadd beta
estimates store model1
quietly regress price weight mpg foreign
estadd beta
estimates store model2
estout model1 model2, cells(beta) drop(_cons)
estimates clear
