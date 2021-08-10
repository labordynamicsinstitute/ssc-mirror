spex ordwarm2
quietly slogit warm yr89 male white age ed prst, nolog
estadd fitstat
estadd listcoef
esttab, cell("b b_fact b_facts") scalars(aic0 bic0) ///
    eqlabels(none)
