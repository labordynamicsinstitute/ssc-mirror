sysuse auto, clear

qbplot mpg, aspect(1) name(qb1, replace)

qbplot mpg, ysc(log) subtitle(logarithmic scale, place(w)) aspect(1) name(qb2, replace)

means mpg
local gmean = r(mean_g)
qbplot mpg, ysc(log) subtitle(logarithmic scale, place(w)) note(dashed line shows geometric mean) addplot(function `gmean', lp(dash) lc(magenta)) aspect(1) name(qb3, replace)

levelsof foreign 

foreach g in `r(levels)' { 
	local this : label (foreign) `g'
	qbplot mpg if foreign == `g', ytitle("`this'", size(large)) name(G`g', replace)
	local G `G' G`g'
}

graph combine `G', ycommon subtitle("`: var label mpg'") name(qb4, replace)

label var price "Price (USD)"

foreach v in price weight length mpg { 
	qbplot `v', ytitle(, size(large)) name(`v', replace) 
	local V `V' `v'
}

graph combine `V', imargin(small) name(qb5, replace) 

sysuse nlsw88, clear

qbplot wage, name(qb6, replace)

qbplot wage, ysc(log) name(qb7, replace)

qbplot wage, ysc(log) yla(, format(%3.2f)) name(qb8, replace) 

