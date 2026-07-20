version 19.5
clear all
set more off
set varabbrev off

* Numeric variables only: preserve the original SSC behavior.
clear
set obs 6
generate x = cond(_n==1,1,cond(_n==2,2,cond(_n==3,.,cond(_n==4,1,cond(_n==5,2,.)))))
generate y = x
generate bad = cond(_n==1,1,cond(_n==2,2,3))
generate only1 = 1
generate ext = cond(_n==1,1,cond(_n==2,2,.a))
generate extm = cond(_n==1,1,cond(_n==2,2,.m))
generate extn = cond(_n==1,1,cond(_n==2,2,.n))
generate only1miss = cond(_n==1,1,.)
generate only2miss = cond(_n==1,2,.)

recode12 x y bad only1 ext extm extn only1miss only2miss, yesvalue(1)
assert x_01 == 1 if x == 1
assert x_01 == 0 if x == 2
assert missing(x_01) if missing(x)
assert y_01 == 1 if y == 1
assert y_01 == 0 if y == 2
assert r(n_recoded) == 2
assert r(n_numeric_recoded) == 2
assert r(n_string_recoded) == 0
assert `"`r(numeric_recoded)'"' == "x_01 y_01"
assert `"`r(string_recoded)'"' == ""
assert `"`r(numeric_source)'"' == "x y"
assert `"`r(string_source)'"' == ""
assert `"`: variable label x_01'"' == "Recoded x == 1 (0=No; 1=Yes)"
assert recode12_status == "confirmed"

* String variables only: first two distinct trimmed nonempty categories define 1 and 2.
clear
input str12 exam str12 fruit str8 onlyone str8 threecat str8 allblank
"Pass" "."     "Yes" "A" ""
"."    "Plum"  "."   "B" "   "
"Fail" ""      "Yes" "C" ""
"Pass" "Plum"  ""    "A" " "
"Fail" "Peach" "Yes" "B" ""
" . "  "Peach" ""    "C" " . "
end

generate str8 ascii3 = cond(_n<=2,"Pass",cond(_n<=4,"Fail","m"))
generate str8 dotm3 = cond(_n<=2,"Pass",cond(_n<=4,"Fail",".m"))
generate str8 ascii_n3 = cond(_n<=2,"Pass",cond(_n<=4,"Fail","n"))
generate str8 dotn3 = cond(_n<=2,"Pass",cond(_n<=4,"Fail",".n"))

recode12 exam fruit onlyone threecat allblank ascii3 dotm3 ascii_n3 dotn3, yesvalue(2)
assert exam_01 == 0 if ustrtrim(exam) == "Pass"
assert exam_01 == 1 if ustrtrim(exam) == "Fail"
assert missing(exam_01) if inlist(ustrtrim(exam), "", ".")
assert fruit_01 == 0 if ustrtrim(fruit) == "Plum"
assert fruit_01 == 1 if ustrtrim(fruit) == "Peach"
assert missing(fruit_01) if inlist(ustrtrim(fruit), "", ".")
assert r(n_recoded) == 2
assert r(n_numeric_recoded) == 0
assert r(n_string_recoded) == 2
assert `"`r(numeric_recoded)'"' == ""
assert `"`r(string_recoded)'"' == "exam_01 fruit_01"
assert `"`r(numeric_source)'"' == ""
assert `"`r(string_source)'"' == "exam fruit"
assert `"`r(skipped)'"' == "onlyone threecat allblank ascii3 dotm3 ascii_n3 dotn3"
assert `"`: value label exam_01'"' == "recode12_NoYes"
assert `"`: variable label exam_01'"' == "Recoded Fail (0=No; 1=Yes)"

* Mixed eligible numeric and string variables in one call.
clear
set obs 6
generate numeric12 = cond(inlist(_n,1,4),1,cond(inlist(_n,2,5),2,.))
generate str10 string12 = cond(_n==1,"No",cond(_n==2,"",cond(_n==3,"Yes",cond(_n==4,"No",cond(_n==5,"Yes","")))))
generate continuous = _n/10
generate str8 threecat = cond(_n<=2,"A",cond(_n<=4,"B","C"))

recode12 numeric12 string12 continuous threecat, yesvalue(2)
assert numeric12_01 == 0 if numeric12 == 1
assert numeric12_01 == 1 if numeric12 == 2
assert string12_01 == 0 if string12 == "No"
assert string12_01 == 1 if string12 == "Yes"
assert r(n_recoded) == 2
assert r(n_numeric_recoded) == 1
assert r(n_string_recoded) == 1
assert `"`r(numeric_recoded)'"' == "numeric12_01"
assert `"`r(string_recoded)'"' == "string12_01"
assert `"`r(numeric_source)'"' == "numeric12"
assert `"`r(string_source)'"' == "string12"

* Omitting varlist scans both numeric and string variables.
clear
set obs 4
generate n = cond(mod(_n,2),1,2)
generate str8 s = cond(mod(_n,2),"First","Second")
generate z = _n
recode12, yesvalue(1) display
assert n_01 == 1 if n == 1
assert n_01 == 0 if n == 2
assert s_01 == 1 if s == "First"
assert s_01 == 0 if s == "Second"
assert r(n_recoded) == 2

* replace supports both source types and retains their original names.
clear
set obs 5
generate n = cond(_n==5,.,cond(mod(_n,2),1,2))
generate str8 s = cond(_n==5," . ",cond(mod(_n,2),"First","Second"))
recode12 n s, yesvalue(2) replace
confirm numeric variable s
assert n == 0 if mod(_n,2) & _n<5
assert n == 1 if !mod(_n,2) & _n<5
assert s == 0 if mod(_n,2) & _n<5
assert s == 1 if !mod(_n,2) & _n<5
assert missing(n) in 5
assert missing(s) in 5
assert r(n_numeric_recoded) == 1
assert r(n_string_recoded) == 1
assert `"`r(numeric_recoded)'"' == "n"
assert `"`r(string_recoded)'"' == "s"

capture noisily recode12 n, yesvalue(3)
assert _rc == 198
capture noisily recode12 n
assert _rc == 198
capture noisily recode12 n, yesvalue(1) suffix(_z) replace
assert _rc == 198

clear
set obs 3
generate only1 = 1
generate str8 onlys = "One"
recode12 only1 onlys, yesvalue(1)
assert r(n_recoded) == 0
assert r(verified) == 0
assert r(n_numeric_recoded) == 0
assert r(n_string_recoded) == 0
assert r(yesvalue) == 1
assert `"`r(status_variable)'"' == ""

display as result "recode12 tests passed"
