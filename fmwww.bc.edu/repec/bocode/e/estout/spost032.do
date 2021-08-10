spex nomocc2
quietly mlogit occ white ed exper, nolog
estadd listcoef, gt adjacent
esttab , cell("b_raw b_fact b_facts b_sdx") varwidth(14)

