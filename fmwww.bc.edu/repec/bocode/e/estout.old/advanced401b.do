sysuse auto
replace price = price / 1000
replace weight = weight / 1000
quietly mlogit rep78 price mpg foreign if rep78>=3, nolog
estadd prchange, c(margefct) adapt
esttab, main(dc) not nostar
