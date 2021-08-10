sysuse auto
eststo: quietly regress price weight mpg
eststo: quietly regress price weight mpg foreign
esttab using example.tex, label nostar ///
  title(Regression table\label{tab1})
