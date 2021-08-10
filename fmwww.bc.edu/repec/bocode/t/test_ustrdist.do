*! version 1.1  06may2017 Michael D Barker Felix Pöge

/*
    Testing the ustrdist method using direct inputs.
*/

version 14

// How many unicode characters to test.
local unicode_max_test = 10000

// Tests for empty strings
ustrdist "" ""
assert r(d) == 0
ustrdist "x" ""
assert r(d) == 1
ustrdist "" "x"
assert r(d) == 1
ustrdist "yxz" ""
assert r(d) == 3
ustrdist "" "yxz"
assert r(d) == 3

// Tests for equal strings
ustrdist "x" "x"
assert r(d) == 0
ustrdist "test" "test"
assert r(d) == 0

// Tests for inserts only
ustrdist "test" "test1"
assert r(d) == 1
ustrdist "test" "te1st"
assert r(d) == 1
ustrdist "test" "1test2"
assert r(d) == 2
ustrdist "test" "xxtyxexysyyxctc"
assert r(d) == 11

// Tests for deletes only
ustrdist "test1" "test"
assert r(d) == 1
ustrdist "te1st" "test"
assert r(d) == 1
ustrdist "1test2" "test"
assert r(d) == 2
ustrdist "xxtyxexysyyxctc" "test"
assert r(d) == 11

// Tests for substitutions only
ustrdist "x" "y"
assert r(d) == 1
ustrdist "vx" "vy"
assert r(d) == 1
ustrdist "xv" "yv"
assert r(d) == 1
ustrdist "vxm" "vym"
assert r(d) == 1

// Tests for multiple operations at the same time
ustrdist "example" "samples"
assert r(d) == 3
ustrdist "sturgeon" "urgently"
assert r(d) == 6
ustrdist "levenshtein" "frankenstein"
assert r(d) == 6
ustrdist "distance" "difference"
assert r(d) == 5

// Testing all the cases again, but this time with variables instead of direct inputs.
// Also, test the usage of gen
clear
 input str20 x str20 y target
 "" "" 0
 "x" "" 1
 "" "x" 1
 "yxz" "" 3
 "" "yxz" 3
 "x" "x" 0
 "test" "test" 0
 "test" "test1" 1
 "test" "te1st" 1
 "test" "1test2" 2
 "test" "xxtyxexysyyxctc" 11
 "test1" "test" 1
 "te1st" "test" 1
 "1test2" "test" 2
 "xxtyxexysyyxctc" "test" 11
 "x" "y" 1
 "vx" "vy" 1
 "xv" "yv" 1
 "vxm" "vym" 1
 "example" "samples" 3
 "sturgeon" "urgently" 6
 "levenshtein" "frankenstein" 6
 "distance" "difference" 5
 end
ustrdist x y, gen(test_strdist)
assert target == test_strdist
drop test_strdist

/*
    Testing the same cases again with one part variable, one part string.
    Also, test the usage of if and in.
*/
count
noi di as text "Case: " _c
forvalues i = 1/`=r(N)' {
    local to_test = x[`i']
    ustrdist "`to_test'" y in `i'
    assert strdist == target in `i'
    drop strdist 
    local to_test = y[`i']
    ustrdist x "`to_test'" if _n == `i'
    assert strdist == target | _n != `i'
    drop strdist 
    noi di as text "`i' " _c
}

// Testing compatibility with several unicode examples
forvalues i = 1/`unicode_max_test' {
    quietly {
        // These do not work for Stata reasons (Characters $ and `).
        // They are tested below.
        if inlist(`i', 36, 96) {    
            continue
        }
        cap {
            noi di as text uchar(`i') _c
            ustrdist `""' `"`=uchar(`i')'"'
            assert r(d) == 1
            ustrdist `"`=uchar(`i')'"' `""'
            assert r(d) == 1
            ustrdist `"test"' `"test`=uchar(`i')'"'
            assert r(d) == 1
            ustrdist `"test`=uchar(`i')'"' `"test`=uchar(`i')'"'
            assert r(d) == 0
            ustrdist `"`=uchar(`i')'test`=uchar(`i')'"' `"te`=uchar(`i')'st"'
            assert r(d) == 3
            ustrdist `"test`=uchar(`=`i'+1')'"' `"test`=uchar(`i')'"'
            assert r(d) == 1
        }
        if _rc == 9 {
            noi di as error _n "Failed for `i' (`=char(`i')')."
            error 9
        }
    }
}

// Testing $ and `
ustrdist "" "$"
assert r(d) == 1
ustrdist "$" ""
assert r(d) == 1
// ` cannot be directly put as a string, hence it is here tested using a variable
clear
set obs 1
gen x = ""
replace x = uchar(96) in 1
ustrdist "a" x
assert strdist == 1
drop strdist
ustrdist x "a"
assert strdist == 1
clear

/*************************************************************************************
    ALL TESTS SUCCESSFUL
*************************************************************************************/
