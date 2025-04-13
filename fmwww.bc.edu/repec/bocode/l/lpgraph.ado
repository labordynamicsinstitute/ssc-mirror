* First Version June 26 2023
* This Version February 07 2025

program lpgraph
version 13.0:

syntax anything [if] [in], [Hor(numlist integer) Zero TItle(string) TTItle(string) YTItle(string) ti1(string) ti2(string) ti3(string) ti4(string) /*
*/ lab1(string) lab2(string) lab3(string) lab4(string) LColor(string) lc1(string) lc2(string) lc3(string) lc4(string) SEParate nolegend /*
*/ GRName(string) GRSave(string) as(string) COMBine(string) *]

*********************************************************************************************************************************************
*********************************************************************************************************************************************

loc nh = wordcount("`hor'")
if `nh'>1 {
	loc hor : subinstr local hor " " ",", all	
	loc hs=min(`hor')
	if `hs'<0 loc neghor=1
	loc hor=max(`hor')
	loc hran `hs'/`hor'	
}
else if `nh'==0 {
	loc hs=0
	loc hor=5
	loc hran `hs'/`hor'
}
else if `nh'==1 {
	loc hs=0
	loc hran `hs'/`hor'
}
if `hs'<=0 loc h1 = `hor'+ 1 -`hs'
else loc h1 = `hor'

loc mod = mod(`hor'-`hs',2)
if `hor'-`hs'>12 & `mod'==0 loc p 2
else if `hor'-`hs'>12 & `mod'==1 loc p 3
else loc p 1

*********************************************************************************************************************************************
*********************************************************************************************************************************************

loc n = wordcount("`anything'")
tokenize `anything'
if "`separate'"=="" {
	if "`lc1'"=="" loc color1 blue
	else loc color1 `lc1'
	if "`lc2'"=="" loc color2 red
	else loc color2 `lc2'
	if "`lc3'"=="" loc color3 green
	else loc color3 `lc3'
	if "`lc4'"=="" loc color4 orange
	else loc color4 `lc4'
} 
else {
	if "`lcolor'"=="" {
		loc color1 blue
		loc color2 blue
		loc color3 blue	
		loc color4 blue	
	} 
	else {
		loc color1 `lcolor'
		loc color2 `lcolor'
		loc color3 `lcolor'	
		loc color4 `lcolor'	
	} 
}

tempvar t _zero
if `hs'<=0 qui gen `t' =_n-1+`hs'
else  qui gen `t' =_n
if "`zero'"=="zero" qui gen `_zero' = 0
else qui gen `_zero' = .
loc linezero (line `_zero' `t', lcolor(gs5) lpattern(dash)) 

if "`ttitle'"=="" loc ttitle Period
if "`legend'"=="nolegend" loc off off

loc areas
loc lines
loc order
loc names
loc size=1

forval i=1/`n' {
	loc names `names' ``i''
	loc irf`i' "``i''"
	loc elabel`i': variable label ``i''
	if "`lab`i''"=="" label var ``i'' "`elabel`i''"
	else label var ``i'' "`lab`i''"
	loc area`i' (rarea `irf`i''_lo `irf`i''_up `t', fcolor(`color`i''%15) lc(`color`i''%7))
	loc areas `areas' `area`i''
	loc line`i' (line `irf`i'' `t', fcolor(`color`i'') lc(`color`i''))
	loc lines `lines' `line`i''
	loc o`i'=`i'+`n'+1
	loc order `order' `o`i''
	loc s`i' 0.1
	loc size=`size'-`s`i''
}


if "`separate'"=="" {
	twoway `areas' `linezero' `lines' if _n<=`h1', ///
	legend(order(`order') rows(1) position(6)) ///
	title(`title') tlabel(`hs'(`p')`hor') xtitle(`ttitle') ytitle(`ytitle') `options' name(`grname', replace)
}

if "`separate'"=="separate" {
	forval i=1/`n' {
		twoway `area`i'' `linezero' `line`i'' if _n<=`h1', legend(`off' order(3) rows(1) position(6)) ///
		title(`ti`i'', size(*`size')) tlabel(`hs'(`p')`hor') xtitle(`ttitle') ytitle(`ytitle') name(``i'', replace) `options' nodraw
	}	
gr combine `names', title(`title') name(`grname', replace) `combine'
}

if "`grsave'"!="" {
	if "`as'"=="" graph save "`grsave'.gph", replace
	else graph export "`grsave'.`as'", as(`as') replace
}

end
