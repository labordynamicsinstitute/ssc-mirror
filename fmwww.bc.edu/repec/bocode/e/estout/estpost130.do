sysuse auto, clear
logit foreign turn weight mpg, nolog
eststo logodds
estpost margins, dydx(*)
eststo AMEs
esttab logodds AMEs, mtitles
