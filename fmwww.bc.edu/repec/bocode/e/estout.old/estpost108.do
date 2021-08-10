sysuse auto
estpost tabulate foreign
esttab, cells("b(label(freq)) pct(fmt(2)) cumpct(fmt(2))") ///
    varlabels(, blist(Total "{hline @width}{break}"))      ///
    nonumber nomtitle noobs
