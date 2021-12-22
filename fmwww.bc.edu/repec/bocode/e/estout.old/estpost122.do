webuse nhanes2b, clear
svyset psuid [pweight=finalwgt], strata(stratid)
estpost svy: tabulate race diabetes, row percent
esttab ., se nostar nostar unstack
