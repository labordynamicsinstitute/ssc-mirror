spex ordwarm2
eststo ologit: quietly ologit warm yr89 male white age ed prst, nolog
eststo oprobit: quietly oprobit warm yr89 male white age ed prst, nolog
estadd prchange male age prst: *
esttab, main(dc) nostar not mtitles
eststo clear
