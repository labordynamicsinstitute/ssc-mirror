sysuse auto
eststo A: quietly logit foreign weight
eststo B: quietly logit foreign weight mpg price
estadd lrtest A
esttab, scalars(lrtest_chi2 lrtest_df lrtest_p)
eststo clear
