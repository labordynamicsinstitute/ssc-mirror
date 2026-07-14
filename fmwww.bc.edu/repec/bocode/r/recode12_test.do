version 19.5
clear all
set more off
set varabbrev off

clear
set obs 6
generate x = cond(_n==1,1,cond(_n==2,2,cond(_n==3,.,cond(_n==4,1,cond(_n==5,2,.)))))
generate y = x
generate bad = cond(_n==1,1,cond(_n==2,2,3))
generate only1 = 1
generate ext = cond(_n==1,1,cond(_n==2,2,.a))

recode12 x y bad only1 ext, yesvalue(1)
scalar n_recoded = r(n_recoded)
assert x_01 == 1 if x == 1
assert x_01 == 0 if x == 2
assert missing(x_01) if missing(x)
assert y_01 == 1 if y == 1
assert y_01 == 0 if y == 2
assert n_recoded == 2
assert `"`: variable label x_01'"' == "Recoded x == 1 (0=No; 1=Yes)"
assert recode12_status == "confirmed"
assert `"`: variable label recode12_status'"' == "recode12 verification status"

drop x_01 y_01
recode12 x, yesvalue(2) suffix(_bin)
assert recode12_status == "confirmed"
assert x_bin == 0 if x == 1
assert x_bin == 1 if x == 2
assert missing(x_bin) if missing(x)

recode12 y, yesvalue(2) replace
assert y == 0 in 1
assert y == 1 in 2
assert missing(y) in 3

capture noisily recode12 x, yesvalue(3)
assert _rc == 198
capture noisily recode12 x
assert _rc == 198
capture noisily recode12 x, yesvalue(1) suffix(_z) replace
assert _rc == 198

clear
set obs 3
generate only1 = 1
recode12 only1, yesvalue(1)
assert r(n_recoded) == 0
assert r(verified) == 0
assert r(yesvalue) == 1
assert `"`r(status_variable)'"' == ""

display as result "recode12 tests passed"
