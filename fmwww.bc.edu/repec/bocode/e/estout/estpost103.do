sysuse auto
estpost tabstat price mpg rep78, listwise ///
    statistics(mean sd) columns(statistics)
esttab, cells("mean sd") nomtitle nonumber
