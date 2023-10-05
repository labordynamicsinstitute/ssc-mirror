*! version 0.1  3 Oct 2023
* by Kerry Du
cap program drop hanoitower
program define hanoitower 
version 16
//args num s
syntax anything, [FIG]
gettoken num anything:anything
if "`num'"==""{
	di as error "# of Disks should be specified as the first argument."
	error 198
}
else{
	confirm integer num `num'
	if (`num'<1 | `num'>10){
		di as error "# of Disks (the first argument) shoud >=1 & <=10."
		error 198
	}
}
local s `anything'
if "`s'"==""{
   local s 1000
}
else{
	if (`s'<0){
		di as error "argument for sleep time should not be <0."
		error 198
	}
}

di "Game Start..."
di "#1 denotes the smallest disk, #2 denotes the second smallest disk and so on." _n

preserve	   
clear
qui set obs 10
forv j=1/10{
	gen y`j' = 11-`j'
	gen x`j' = 2+`j'/3*(_n-5.5)/10*(10/`num') 
	gen xB`j' = 6+`j'/3*(_n-5.5)/10*(10/`num') 
	gen xC`j' = 10+`j'/3*(_n-5.5)/10*(10/`num') 
	
}

gen x11 = 2+ (_n-5.5)/80
gen xB11 = 6+ (_n-5.5)/80
gen xC11 = 10+ (_n-5.5)/80
gen y11 = 11
gen y12 = 13
gen y0 =0
gen x00 = 0+(_n-1)*13/_n

local a A 
local b B 
local c C
global n = 1 
global `b'
global `c'
global `a'
forv j=1/`num'{
	global `a' ${`a'} `j'
}

	global aa `a' 
	global bb `b'
	global cc `c'

if "`fig'"!="" plotfig 0 0 ${aa} ${bb} ${cc}
hannuota `num' `a' `b' `c' `s' `fig'
restore
end


cap program drop hannuota
program define hannuota
version 16
args num a b c s fig

global `a' ${`a'}
global `b' ${`b'}
global `c' ${`c'}

if `num'==1{
	sleep `s'
	di _n
	disp "-----------------------------------"
	display "$n:Move Disk#`num' from `a' to `c'"
	disfig `a' `c' ${aa} ${bb} ${cc}
	global n=$n+1
	global `c' `num' ${`c'}
	local aa ${`a'}
	gettoken j aa:aa
	global `a' `aa'
	sleep `s'
	if "`fig'"!="" plotfig `a' `c' ${aa} ${bb} ${cc}
   disp "↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓"
	di "$aa:${$aa}" _n(2) "$bb:${$bb}" _n(2) "$cc:${$cc}"
}
else{
	local num2 = `num' -1
	hannuota `num2' `a' `c' `b' `s' `fig'
	sleep `s'
	di _n
	disp "-----------------------------------"
	display "$n:Move Disk#`num' from `a' to `c'" 
	disfig `a' `c' ${aa} ${bb} ${cc}
	
	global `c' `num' ${`c'}
	local aa ${`a'}
	gettoken j aa:aa
	global `a' `aa'
	global n=$n+1
	sleep `s'
	if "`fig'"!="" plotfig `a' `c' ${aa} ${bb} ${cc}
   disp "↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓"
	di "$aa:${$aa}" _n(2) "$bb:${$bb}" _n(2) "$cc:${$cc}"
	hannuota `num2' `b' `a' `c' `s' `fig'
	
}

end



//////////////////////////

cap program drop plotfig 
program define plotfig 
version 16
args from to A B C

local cols gray orange sand navy maroon green purple olive red blue

local na: word count $`A'
foreach j in $`A'{
	tempvar yA`j'  yA`=`j'+1'
	qui gen `yA`j'' = `na'
	qui gen `yA`=`j'+1''= `na' + 1
	local cj: word `j' of `cols'
	local line1 `line1' (rarea `yA`j'' `yA`=`j'+1'' x`j', color(`cj'))
	local na = `na' -1
}

local nb: word count $`B'
foreach j in $`B'{
	tempvar yB`j'  yB`=`j'+1'
	qui gen `yB`j'' = `nb'
	qui gen `yB`=`j'+1''= `nb' + 1
	local cj: word `j' of `cols'	
	local line2 `line2' (rarea `yB`j'' `yB`=`j'+1'' xB`j', color(`cj'))
	local nb = `nb' -1
}

local nc: word count $`C'
foreach j in $`C'{
	tempvar yC`j'  yC`=`j'+1'
	qui gen `yC`j'' = `nc'
	qui gen `yC`=`j'+1''= `nc' + 1
	local cj: word `j' of `cols'	
	local line2 `line2' (rarea `yC`j'' `yC`=`j'+1'' xC`j', color(`cj'))
	local nc = `nc' -1
}



twoway  `line1' `line2' `line3' ///
       (rarea y0 y12 xC11,color(black)) ///	
	   (rarea y0 y12 xB11,color(black)) ///	
	   (rarea y0 y12 x11,color(black)) ///
	   (rarea y0 y10 x00,color(black)) ///
	   , legend(off) xtitle("") ytitle("") ///
       xlabel(none) ylabel(none) ///
	   yscale(lstyle(none)) xscale(lstyle(none)) ///
	   text(-0.3 2 "A") text(-0.3 6 "B") text(-0.3 10 "C")

end


//////////////////////
cap program drop disfig 
program define disfig 
version 16
args from to A B C

if "`from'"=="`A'" {
	local line1 `"`A':${`A'}"'
	if "`to'"=="`B'"{
		local line2 `"`B':□ ${`B'}"'
		local line3 `"`C':${`C'}"'
		di `"`line1'"' _n `"  ↓ "' _n `"`line2'"' _n(2) `"`line3'"'
	}
	else{
		local line2 `"`B':| ${`B'}"'
		local line3 `"`C':□ ${`C'}"'
		di `"`line1'"'  _n `"  | "' _n `"`line2'"' _n `"  ↓ "' _n `"`line3'"'
	}

}
if "`from'"=="`B'" {
	local line2 `"`B':${`B'}"'
	if "`to'"=="`A'"{
		local line1 `"`A':□ ${`A'}"'
		local line3 `"`C':${`C'}"'
		di `"`line1'"' _n `"  ↑ "' _n `"`line2'"' _n(2) `"`line3'"'
	}
	else{
		local line1 `"`A':${`A'}"'
		local line3 `"`C':□ ${`C'}"'
		di `"`line1'"'  _n  _n `"`line2'"' _n `"  ↓ "' _n `"`line3'"'
	}
}

if "`from'"=="`C'" {
	local line3 `"`C':${`C'}"'
	if "`to'"=="`A'"{
		local line1 `"`A':□ ${`A'}"'
		local line2 `"`B':| ${`B'}"'
		di `"`line1'"' _n `"  ↑ "' _n `"`line2'"' _n `"  | "' _n `"`line3'"'
	}
	else{
		local line1 `"`A':${`A'}"'
		local line2 `"`B':□ ${`B'}"'
		di `"`line1'"'  _n  _n `"`line2'"' _n `"  ↑ "' _n `"`line3'"'
	}
}


end

