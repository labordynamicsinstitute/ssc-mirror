sysuse auto
quietly regress price weight mpg foreign
estadd vif
esttab, cells("b(fmt(a3) star) vif(fmt(2))" t(par fmt(2)))
