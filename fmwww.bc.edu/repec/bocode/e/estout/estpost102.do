sysuse auto
estpost tabstat price mpg rep78, listwise ///
    statistics(mean sd)
esttab, cells("price mpg rep78") nomtitle nonumber
