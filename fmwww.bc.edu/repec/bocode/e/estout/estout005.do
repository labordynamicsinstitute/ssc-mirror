sysuse auto
eststo, title("Model 1"): quietly regress price weight mpg
eststo, title("Model 2"): quietly regress price weight mpg foreign
label variable foreign "Car type (1=foreign)"
estout, cells("b(star label(Coef.)) se(label(Std. err.))")  ///
    stats(r2 N, labels(R-squared "N. of cases"))            ///
    label legend varlabels(_cons Constant)
eststo clear
