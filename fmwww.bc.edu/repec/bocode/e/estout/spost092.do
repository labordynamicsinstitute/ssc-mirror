spex couart2
eststo zip: quietly zip art fem mar kid5 phd ment, ///
                    inf(fem mar kid5 phd ment) nolog
eststo zinb: quietly zinb art fem mar kid5 phd ment, ///
                    inf(fem mar kid5 phd ment) nolog
estadd listcoef fem ment : *
estadd listcoef fem ment, percent nosd : *
esttab, cell("b_facts b_pcts") keep(fem ment) mtitles
eststo clear
