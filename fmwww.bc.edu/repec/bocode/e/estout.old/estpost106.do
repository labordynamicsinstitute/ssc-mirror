sysuse auto
estpost ttest price mpg headroom trunk, by(foreign)
esttab, wide nonumber mtitle("diff.")
