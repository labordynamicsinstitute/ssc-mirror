sysuse auto
eststo: quietly regress price weight mpg
eststo: quietly regress price weight mpg foreign
estout, style(tex) varlabels(_cons \_cons)
eststo clear
