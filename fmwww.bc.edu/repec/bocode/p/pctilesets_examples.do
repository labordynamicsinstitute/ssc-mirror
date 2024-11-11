sysuse auto, clear 

pctilesets mpg, p(25 50 75) min max over(foreign) saving(foo, replace)

clonevar origgvar=foreign

merge m:1 origgvar using foo 

gen where = 1.1

qplot mpg, ms(O) by(foreign, note("") legend(off)) addplot(scatter p50 where, ms(Dh) msize(medlarge) pstyle(p2) || rbar p75 p25 where, fcolor(none) barw(0.12) pstyle(p2) || rspike p25 min where, pstyle(p2) || rspike p75 max where, pstyle(p2)) xla(0 1 0.25 "0.25" 0.5 "0.5" 0.75 "0.75") xtitle(Fraction of data) name(QB1, replace)

replace where = 2.7

qplot mpg, ms(O) by(foreign, note("") legend(off)) addplot(scatter p50 where, ms(Dh) msize(medlarge) pstyle(p2) || rbar p75 p25 where, fcolor(none) barw(0.44) pstyle(p2) || rspike p25 min where, pstyle(p2) || rspike p75 max where, pstyle(p2)) trscale(invnormal(@)) xla(-2/2) xtitle(Standard normal deviate) name(QB2, replace)

replace where = 0.5

qplot mpg, ms(O) by(foreign, note("") legend(off)) addplot(rbar p25 p50 where, barw(0.5) fcolor(none) pstyle(p2) || rbar p75 p50 where, fcolor(none) barw(0.5) pstyle(p2) || rspike p25 min where, pstyle(p2) || rspike p75 max where, pstyle(p2) below) xla(0 1 0.25 "0.25" 0.5 "0.5" 0.75 "0.75") xtitle(Fraction of data)  name(QB3, replace)

use https://www.stata-journal.com/software/sj20-2/pr0046_1/mathsmarks, clear 
rename * (marks*)
gen id = _n
reshape long marks, i(id) j(subject) string
myaxis subject2=subject, sort(median marks)

qplot marks, by(subject2, row(1) compact) ytitle(Mathematics marks)

pctilesets marks, over(subject2) min max p(25 50 75) saving(foo, replace)
gen where = 1.1 
clonevar origgvar=subject2 
merge m:1 origgvar using foo

#delimit ; 

qplot marks, by(subject2, row(1) compact legend(off) note("")) 
addplot(rspike p25 min where, pstyle(p2) 
|| rspike p75 max where, pstyle(p2) 
|| rbar p25 p75 where, barw(0.16) fcolor(none) pstyle(p2) 
|| scatter p50 where, ms(Dh) msize(medlarge) pstyle(p2)) 
ytitle(Mathematics marks)
xla(0 0.25 "0.25" 0.5 "0.5" 0.75 "0.75" 1) xtitle(Fraction of data) name(QB4, replace);

#delimit cr 

