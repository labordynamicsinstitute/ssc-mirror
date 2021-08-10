sysuse auto
eststo: quietly logit foreign weight mpg
eststo: quietly logit foreign weight mpg turn displ
esttab, stats(chi2 df_m r2_p N, layout(`""@ (@)""' @ @))
eststo clear
