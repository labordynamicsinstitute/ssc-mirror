sysuse auto, clear
logit foreign turn weight mpg, nolog
eststo logodds
margins, dydx(*) post
eststo AMEs
esttab logodds AMEs, mtitles
