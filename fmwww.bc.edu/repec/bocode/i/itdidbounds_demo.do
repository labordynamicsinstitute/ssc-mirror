* ITDIDBOUNDS demonstration file
* Copyright (c) 2026 Christina Laternser
* Licensed under the MIT License.

version 17.0
clear all
set more off
set varabbrev off

/*
Deterministic example:
- T1 has feasible adoption dates 2018-2019.
- T2 is exact at 2019.
- C1 and C2 are never treated.
- The event-0 timing envelope is [2.5, 4.0].
*/

quietly set obs 20
quietly gen int state = ceil(_n/5)
quietly bysort state: gen int year = 2016 + _n - 1

quietly gen byte treated = inlist(state, 1, 2)
quietly gen byte never = inlist(state, 3, 4)

quietly gen int L = .
quietly gen int U = .
quietly replace L = 2018 if state == 1
quietly replace U = 2019 if state == 1
quietly replace L = 2019 if state == 2
quietly replace U = 2019 if state == 2

quietly gen double y = year - 2016

quietly replace y = 0  if state == 1 & year == 2016
quietly replace y = 1  if state == 1 & year == 2017
quietly replace y = 4  if state == 1 & year == 2018
quietly replace y = 10 if state == 1 & year == 2019
quietly replace y = 11 if state == 1 & year == 2020

quietly replace y = 0 if state == 2 & year == 2016
quietly replace y = 1 if state == 2 & year == 2017
quietly replace y = 2 if state == 2 & year == 2018
quietly replace y = 6 if state == 2 & year == 2019
quietly replace y = 7 if state == 2 & year == 2020

quietly isid state year

tempfile aggregate detail
itdidbounds y, id(state) time(year) treated(treated) ///
    lower(L) upper(U) never(never) event(0) ///
    saving(`aggregate') detail(`detail') replace

matrix E = r(envelope)
assert abs(el(E,1,3) - 2.5) < 1e-10
assert abs(el(E,1,4) - 4.0) < 1e-10

use `aggregate', clear
assert c(k) == 10
quietly isid event_time
list, noobs

di as result "ITDIDBOUNDS DEMO PASSED."
