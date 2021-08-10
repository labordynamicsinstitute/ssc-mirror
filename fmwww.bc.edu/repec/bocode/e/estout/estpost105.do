sysuse auto
estpost tabstat price in 1/15, by(make)
esttab, cells(mean) noobs nomtitle nonumber ///
    varlabels(`e(labels)') varwidth(20)
lab def origin 0 "Car type: domestic" 1 "Car type: foreign", modify
estpost tabstat price weight, statistics(mean sd) by(foreign)
esttab, cells("price weight") noobs nomtitle nonumber ///
    eqlabels(`e(labels)') varwidth(20)
