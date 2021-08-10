spex nomocc2
quietly mlogit occ white ed exper, nolog
estadd fitstat
eststo mlogit
esttab, wide scalars(r2_ct r2_ctadj aic0 aic_n) mtitles
eststo clear
