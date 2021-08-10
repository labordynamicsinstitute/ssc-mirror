sysuse auto
eststo: quietly regress price weight mpg
eststo: quietly regress price weight mpg foreign
esttab, label                               ///
    title(This is a regression table)       ///
    nonumbers mtitles("Model A" "Model B")  ///
    addnote("Source: auto.dta")
eststo clear
