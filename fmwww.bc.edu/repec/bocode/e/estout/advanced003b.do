sysuse auto
sureg (price foreign weight length) (mpg displ = foreign weight)
esttab, unstack scalars(r2 chi2 p) noobs nomtitle
