sysuse auto
replace price = price / 1000
replace weight = weight / 1000
quietly mlogit rep78 price mpg foreign if rep78>=3, nolog
eststo mlogit
foreach o in 3 4 5 {
    quietly margins, dydx(*) predict(outcome(`o')) post
    eststo, title(Outcome `o')
    estimates restore mlogit
}
eststo drop mlogit
esttab, noobs se nostar mtitles nonumbers title(Average Marginal Effects)
eststo clear
