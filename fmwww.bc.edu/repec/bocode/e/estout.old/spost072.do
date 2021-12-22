spex couart2
eststo poisson: quietly poisson art fem mar kid5 phd ment, nolog
eststo nbreg: quietly nbreg art fem mar kid5 phd ment, nolog
estadd listcoef fem ment: *
estadd listcoef fem ment, percent nosd : *
esttab, cell("b_facts b_pcts") keep(fem ment) mtitles
eststo clear
