sysuse auto
eststo: regress price mpg foreign
eststo: regress price mpg foreign weight
esttab, cells(_sign) nogap
esttab, cells(_star) nogap ///
    starlevels(n.s. 1 * 0.05 ** 0.01)
esttab, cells(_sigsign) nogap ///
    starlevels("+/-" 1 "++/--" 0.05 "+++/---" 0.01)
eststo clear
