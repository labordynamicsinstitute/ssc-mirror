spex couart2
eststo poisson0: quietly poisson art fem mar kid5 phd ment, nolog
eststo nbreg0: quietly nbreg art fem mar kid5 phd ment, nolog
estadd prchange, outcome(0) : *0
eststo poisson1: quietly poisson art fem mar kid5 phd ment, nolog
eststo nbreg1: quietly nbreg art fem mar kid5 phd ment, nolog
estadd prchange, outcome(1) : *1
esttab, main(dc) nostar not scalars(outcome predval) mtitles
eststo clear
