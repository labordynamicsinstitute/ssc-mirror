sysuse auto
eststo: quietly reg weight mpg
eststo: quietly reg weight mpg foreign
eststo: quietly reg price weight mpg
eststo: quietly reg price weight mpg foreign
esttab using example.tex, booktabs label            ///
    mgroups(A B, pattern(1 0 1 0)                   ///
        prefix(\multicolumn{@span}{c}{) suffix(})   ///
        span erepeat(\cmidrule(lr){@span}))         ///
    alignment(D{.}{.}{-1}) page(dcolumn) nonumber
eststo clear
