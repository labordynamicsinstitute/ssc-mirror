spex travel2
quietly clogit choice train bus time invc, group(id) nolog
quietly asprvalue, x(time=643.4 674.6 578.3) rest(asmean) ///
    cat(train bus) base(car) save
estadd asprvalue, x(time=653.4 674.6 578.3) rest(asmean) ///
    cat(train bus) base(car) label(time train + 10 min) brief diff
estadd asprvalue, x(time=643.4 684.6 578.3) rest(asmean) ///
    cat(train bus) base(car) label(time bus + 10 min) brief diff
estadd asprvalue, x(time=643.4 674.6 588.3) rest(asmean) ///
    cat(train bus) base(car) label(time car + 10 min) brief diff
estadd asprvalue post
esttab, unstack not nostar varwidth(20)
