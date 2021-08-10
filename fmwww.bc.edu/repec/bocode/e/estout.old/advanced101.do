sysuse auto
eststo: quietly regress price weight mpg
eststo: quietly regress price weight mpg foreign
esttab, cells(none) scalars(rank r2 r2_a bic aic) nomtitles
eststo clear
