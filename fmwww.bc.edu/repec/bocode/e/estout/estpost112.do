sysuse auto
estpost correlate price turn foreign rep78
esttab, cell("rho p count") noobs
