spex ordwarm2
quietly ologit warm yr89 male white age ed prst
estadd brant
esttab, cell("b t brant[chi2] brant[p>chi2]") ///
    scalars(brant_chi2 brant_df brant_p) ///
    eqlabels(none)
