sysuse auto
estpost correlate price turn foreign rep78, matrix listwise
esttab, unstack not noobs compress
