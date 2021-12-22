sysuse auto
quietly regress price weight mpg foreign
estadd vif
esttab, aux(vif 2) wide nopar
