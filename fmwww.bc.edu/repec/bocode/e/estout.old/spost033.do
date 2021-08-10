spex nomocc2
quietly mlogit occ white ed exper, nolog
estadd listcoef, gt adjacent adapt
esttab , cell("b_facts b_sdx") nocons varwidth(15)
quietly mprobit occ white ed exper, nolog
estadd listcoef, gt adjacent adapt
esttab , cell("b_xs b_sdx") nocons varwidth(15)
