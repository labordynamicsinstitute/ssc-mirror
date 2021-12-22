webuse page2
estpost stci, by(group)
esttab, cell("count p50 se lb ub") noobs compress ///
    varlabels(, blist(total "{hline @width}{break}"))
