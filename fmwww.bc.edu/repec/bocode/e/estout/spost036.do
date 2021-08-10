spex nomocc2
quietly mlogit occ white ed exper, nolog
estadd prchange, outcome(3)
eststo mlogit
quietly mprobit occ white ed exper, nolog
estadd prchange, outcome(3)
eststo mprobit
esttab, aux(dc) wide nopar stats(predval outcome) keep(Craft:) mtitles
eststo clear
