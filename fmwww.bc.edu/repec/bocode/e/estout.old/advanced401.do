sysuse auto
replace price = price / 1000
replace weight = weight / 1000
quietly mlogit rep78 price mpg foreign if rep78>=3, nolog
foreach o in 3 4 5 {
    eststo, title(Outcome `o'): quietly mfx, predict(outcome(`o')) nose
}
esttab, margin scalars(Xmfx_y) noobs not nostar nocons ///
    mtitles nonumbers keep(4:) eqlabels(none) collabels(none)
eststo clear
