
clear all
set more off
which ivreg2
which ivhettest
sysuse auto, clear

qui xi:ivreg2 price (mpg=displacement weight) i.rep78
ivhettest
ivhettest, all
qui ivreg2 price (mpg=displacement weight) i.rep78
ivhettest
ivhettest, all

char rep78[omit] 4
qui xi:ivreg2 price (mpg=displacement weight) i.rep78
char rep78[omit]
ivhettest
qui ivreg2 price (mpg=displacement weight) ib4.rep78
ivhettest

qui xi:ivreg2 price (mpg=displacement weight) i.rep78 foreign
ivhettest
qui ivreg2 price (mpg=displacement weight) i.rep78 i.foreign
ivhettest

capt drop t2
g t2=turn*turn
qui xi:ivreg2 price turn t2 (mpg=displacement weight) i.rep78 foreign
ivhettest
qui ivreg2 price c.turn##c.turn (mpg=displacement weight) i.rep78 i.foreign
ivhettest

capt drop rf*
xi i.rep78
g rf3=_Irep78_3 * foreign
g rf4=_Irep78_4 * foreign
qui ivreg2 price (mpg=displacement weight) _I* foreign rf3 rf4
ivhettest
qui ivreg2 price (mpg=displacement weight) i.rep78##i.foreign
ivhettest

