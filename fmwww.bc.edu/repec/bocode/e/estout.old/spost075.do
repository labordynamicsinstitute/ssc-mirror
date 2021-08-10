spex couart2
eststo poisson: quietly poisson art fem mar kid5 phd ment, nolog
estadd prvalue
eststo nbreg: quietly nbreg art fem mar kid5 phd ment, nolog
estadd prvalue
estadd prvalue post, swap: *
esttab, b(4) nostar ci wide compress ///
    mtitles eqlabels(none)
eststo clear
