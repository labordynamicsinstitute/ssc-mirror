*! version 1.2 30mar2026
*! Ben A. Dwamena: bdwamena@umich.edu
*! midas_con2bin - Convert Continuous Test Results to 2x2 Tables
*! v1.2: fix type mismatch r(109) when id() is numeric
*! v1.1: fix variable-already-defined error; display results; leave data in memory

capture program drop midas_con2bin
program define midas_con2bin, rclass byable(recall) sortpreserve
version 9
// n1 x1 sd1 n0 x0 sd0
syntax varlist(min=6 max=6 numeric) [if] [in] , ID(string) ///
[ SAVEData(string) * ]

marksample touse, novarlist

quietly keep if `touse'

// unpack varlist
tokenize `varlist'
local n1 `1'
local x1 `2'
local sd1 `3'
local n0 `4'
local x0 `5'
local sd0 `6'

tempvar ahat bhat bvar inside nsen nspe

quietly {
    // basic binormal parameters
    gen double `ahat' = `x1' - `x0'
    gen double `bhat' = `sd1' / `sd0'
    gen double `bvar' = `bhat'^2 - 1

    // argument inside the square root
    gen double `inside' = `ahat'^2 + `bvar'*(`sd0'^2)*ln(`bhat'^2)

    // threshold
    capture drop thresh
    gen double thresh = .
    replace thresh = ((`x1'*`bvar') - `ahat' + `bhat'*sqrt(`inside')) / `bvar' ///
        if `bhat' != 1 & `inside' > 0

    // fallback: equal variances or numerically problematic case
    replace thresh = (`x1' + `x0')/2 if `bhat' == 1 | `inside' <= 0

    // implied sensitivity and specificity under binormal model
    gen double `nsen' = 1 - normal((thresh - `x1')/`sd1')
    gen double `nspe' = normal((thresh - `x0')/`sd0')

    // convert to integer counts
    capture drop tp fn tn fp
    gen tp = int(`n1'*`nsen')
    gen fn = int(`n1' - tp)
    gen tn = int(`n0'*`nspe')
    gen fp = int(`n0' - tn)
}

// display results
di as txt _n "{hline 60}"
di as txt "  con2bin: Continuous to 2x2 table conversion"
di as txt "  Studies: " as res _N
di as txt "{hline 60}"
list `id' tp fp fn tn, noobs separator(0)
di as txt "{hline 60}"

if "`savedata'" != "" {
    quietly {
        capture drop studyid
        // Handle both string and numeric ID variables
        capture confirm string variable `id'
        if _rc == 0 {
            gen str80 studyid = `id'
        }
        else {
            gen studyid = `id'
        }
        preserve
        keep studyid tp fp fn tn
        save "`savedata'", replace
        restore
    }
    di as txt "  Saved to: " as res "`savedata'"
}

return scalar N = _N
end
