spex binlfp2
quietly probit lfp k5 k618 age wc hc lwg inc, nolog
estadd prvalue, x(k5=0 wc=0) label(k5 = 0) brief
estadd prvalue, x(k5=1 wc=0) label(k5 = 1) brief
estadd prvalue, x(k5=2 wc=0) label(k5 = 2) brief
estadd prvalue, x(k5=3 wc=0) label(k5 = 3) brief
estadd prvalue post NoCollege
estadd prvalue, x(k5=0 wc=1) label(k5 = 0) brief replace
estadd prvalue, x(k5=1 wc=1) label(k5 = 1) brief
estadd prvalue, x(k5=2 wc=1) label(k5 = 2) brief
estadd prvalue, x(k5=3 wc=1) label(k5 = 3) brief
estadd prvalue post College
quietly prvalue, x(k5=0 wc=0) save
estadd  prvalue, x(k5=0 wc=1) label(k5 = 0) brief diff replace
quietly prvalue, x(k5=1 wc=0) save
estadd  prvalue, x(k5=1 wc=1) label(k5 = 1) brief diff
quietly prvalue, x(k5=2 wc=0) save
estadd  prvalue, x(k5=2 wc=1) label(k5 = 2) brief diff
quietly prvalue, x(k5=3 wc=0) save
estadd  prvalue, x(k5=3 wc=1) label(k5 = 3) brief diff
estadd prvalue post Difference
esttab, se nostar nonumber noobs mtitles ///
    keep(inLF:) eqlabels(none)
eststo clear
