spex nomocc2
quietly mlogit occ white ed exper, nolog
estadd prchange
eststo mlogit
quietly mprobit occ white ed exper, nolog
estadd prchange
eststo mprobit
esttab mlogit, main(dc) nostar not unstack compress
esttab mprobit, main(dc) nostar not unstack compress
esttab, main(dc) nostar not mtitles
eststo clear
