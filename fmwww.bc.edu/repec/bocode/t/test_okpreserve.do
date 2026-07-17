********************************************************************************
* test_okpreserve.do
* Verification script for the vpreservek package (okpreserve / okrestore)
* Author: Vikrant V. Kamble
* Tests three levels of nested preserve and restore using auto.dta
********************************************************************************

clear all
macro drop vpres_cnt vpres_id

sysuse auto, clear
display "LEVEL 0 (Original): N = " _N

* --- Level 1 ---
okpreserve
collapse (mean) price mpg, by(foreign)
display "LEVEL 1 (Collapsed): N = " _N
assert _N == 2

    * --- Level 2 ---
    okpreserve
    keep if foreign == 1
    display "LEVEL 2 (Foreign only): N = " _N
    assert _N == 1

        * --- Level 3 ---
        okpreserve
        drop if missing(price)
        display "LEVEL 3 (No missing): N = " _N
        assert _N == 1
        okrestore

    assert _N == 1
    okrestore

assert _N == 2
okrestore

display "LEVEL 0 (Restored): N = " _N
assert _N == 74

* Note: no temporary files remain in the working directory after this test.

display "ALL TESTS PASSED!"
