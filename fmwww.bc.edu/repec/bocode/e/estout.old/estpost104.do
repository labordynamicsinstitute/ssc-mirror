sysuse auto
estpost tabstat price mpg rep78, by(foreign) ///
    statistics(mean sd) columns(statistics) listwise
esttab, main(mean) aux(sd) nostar unstack ///
    noobs nonote nomtitle nonumber
