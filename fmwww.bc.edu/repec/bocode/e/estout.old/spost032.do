spex nomocc2
quietly mlogit occ white ed exper, nolog
estadd listcoef
esttab , cell("b_facts b_sdx") nocons
quietly mprobit occ white ed exper, nolog
estadd listcoef
esttab , cell("b_xs b_sdx") nocons
