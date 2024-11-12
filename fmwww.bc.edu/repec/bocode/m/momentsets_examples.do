u https://www.stata-journal.com/software/sj10-4/gr0046/windspeed.dta, clear 

momentsets windspeed, over(place) mean sd skewness kurtosis saving(foo, replace)
u foo
gen where = cond(mean < 51, 3, 9)
scatter sd mean, mla(group) mlabvpos(where) name(MO1, replace)
scatter kurt skew, mla(group) mlabvpos(where) name(MO2, replace)
graph combine MO1 MO2 

