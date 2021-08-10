spex travel2
gen busXhinc = bus*hinc
gen trainXhinc = train*hinc
gen busXpsize = bus*psize
gen trainXpsize = train*psize
quietly clogit choice busXhinc busXpsize bus trainXhinc trainXpsize train ///
    time invc, group(id) nolog
quietly asprvalue, x(psize=1) rest(asmean) base(car) save
estadd asprvalue,  x(psize=2) rest(asmean) base(car) label(_cons) brief diff
estadd asprvalue post
esttab, b not nostar eqlabels(none) ///
     mtitle("psize=2 - psize=1") modelw(20)
