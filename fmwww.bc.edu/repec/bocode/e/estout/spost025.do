spex ordwarm2
quietly ologit warm yr89 male white age ed prst, nolog
estadd prchange male age prst, outcome(2)
eststo ologit
quietly oprobit warm yr89 male white age ed prst, nolog
estadd prchange male age prst, outcome(2)
eststo oprobit
esttab, main(dc) nostar not stats(predval outcome) mtitles
eststo clear
