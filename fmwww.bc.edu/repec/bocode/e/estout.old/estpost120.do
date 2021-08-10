webuse nhanes2b, clear
svyset psuid [pweight=finalwgt], strata(stratid)
estpost svy: tabulate race
esttab, cell("b(f(4)) se lb ub deft")
