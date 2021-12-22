sysuse auto
estpost tabulate rep78 foreign
esttab, cell(colpct(fmt(2))) unstack noobs
esttab, cell(colpct(fmt(2)) b(fmt(g) par keep(Total))) ///
    collabels(none) unstack noobs nonumber nomtitle    ///
    eqlabels(, lhs("Repair Rec."))                     ///
    varlabels(, blist(Total "{hline @width}{break}"))
