sysuse auto
quietly heckman price weight, select(foreign = weight mpg) twostep
esttab, wide
