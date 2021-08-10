spex nomocc2
quietly mlogit occ white ed exper, nolog
estadd mlogtest, wald lr set(white exper)
estout, cell("wald[chi2] wald[df] wald[p]")       ///
    stat(wald_set1_chi2 wald_set1_df wald_set1_p, ///
        layout("@ @ @") label("white&exper"))     ///
    mlabel(none)
estout, cell("lrtest[chi2] lrtest[df] lrtest[p]")       ///
    stat(lrtest_set1_chi2 lrtest_set1_df lrtest_set1_p, ///
        layout("@ @ @") label("white&exper"))           ///
    mlabel(none)
estout, cell(" wald[p](label(P>Wald) fmt(4)) lrtest[p](label(P>LR))")   ///
    stat(wald_set1_p lrtest_set1_p, layout("@ @") label("white&exper")) ///
    mlabel(none)
