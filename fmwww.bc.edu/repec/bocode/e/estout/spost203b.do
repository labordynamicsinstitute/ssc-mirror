spex binlfp2
quietly logit lfp k5 k618 age wc hc lwg inc, nolog
quietly prvalue, x(k5=0 wc=0) save
estadd  prvalue, x(k5=0 wc=1) label(k5 = 0) brief diff
quietly prvalue, x(k5=1 wc=0) save
estadd  prvalue, x(k5=1 wc=1) label(k5 = 1) brief diff
quietly prvalue, x(k5=2 wc=0) save
estadd  prvalue, x(k5=2 wc=1) label(k5 = 2) brief diff
estadd  prvalue post
esttab, keep(inLF:) ci wide nostar ///
    mtitle("wc=1 - wc=0")
