capture log close
log using margins_dynxteprobit_example_log.txt, replace text
webuse womenhlthre, clear
xtset personid year
bysort personid: replace select = 0 if select[_n-1] == 0
generate goodhlth = health>3 if select == 1
bysort personid: generate attrit = select[_n-1] != 0

preserve
keep if attrit == 1
xteprobit goodhlth l.i.goodhlth exercise grade, select(select = grade i.regcheck)
margins, dydx(1L.goodhlth)  
restore

margins_dynxteprobit

margins_dynxteprobit if attrit == 1

margins_dynxteprobit, dydx(grade)

margins_dynxteprobit, diff(exercise = (0 1))

margins_dynxteprobit, at(exercise = 0 grade = 12)

margins_dynxteprobit, dydx(grade) post
test 1._at = 2._at
log close