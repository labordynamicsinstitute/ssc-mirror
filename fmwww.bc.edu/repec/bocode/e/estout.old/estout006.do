sysuse auto
eststo: quietly regress price weight mpg
eststo: quietly regress price weight mpg foreign
estout, cells(b(fmt(a3)) t(fmt(2) par)) stats(r2 N, fmt(3 0))
