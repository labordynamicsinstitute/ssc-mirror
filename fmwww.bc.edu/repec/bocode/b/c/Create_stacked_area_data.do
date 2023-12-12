** CONTENTS: Downloaded do-file Create_stacked_area_data.do

clear
**set letter of last column and last line number in plotdata_ worksheets 
loc lastcol "I"
loc nline= 209

** set eqnames for outcome categories, usually the value label
loc eqnames "upperwc lowerwc upperbc lowerbc"

**set path and excel filename
loc xfilenm "c:\temp\OccEdRaceSex_Phat.xlsx"

*** DO NOT MAKE CHANGES BELOW THIS POINT
foreach vn in `eqnames' {
	import excel using "`xfilenm'" , sheet("plotdata_`vn'") clear first cellra(C1:`lastcol'`nline') case(lower)
	qui ds
	loc nlst: word count `r(varlist)'
	loc mod2stub : word `nlst' of `r(varlist)'
	loc mod1stub : word `=`nlst'-1' of `r(varlist)'
	loc focal : word `=`nlst'-2' of `r(varlist)'
	
	**get values of moderator categories
	levelsof `mod2stub', loc(mod2num)
	levelsof `mod1stub', loc(mod1num)
	loc jn=0
	foreach j of numlist `mod1num' {
		loc jn=`jn'+1
		if `jn' ==1 gen yhatint`vn' = yhatint`mod1stub'`j'
		if `jn' != 1  replace yhatint`vn' = yhatint`mod1stub'`j' if  yhatint`mod1stub'`j' < .
	}
	drop yhatint`mod1stub'*
	order `focal' , after(`mod2stub')
save c:\temp/`vn'.dta , replace
}

loc vn1: word 1 of `eqnames'
use c:\temp/`vn1'.dta, clear

foreach vn in `eqnames' {
	if "`vn'" != "`vn1'" {
		merge 1:1 _n using c:\temp/`vn'.dta 
		drop _merge
	}
}

loc colstart = 1
loc m1n : list sizeof m1
loc m2n : list sizeof m2
loc colinc = 3 + `jn'
loc collet1 ""
loc collet1n = 0

foreach m2 of numlist `mod2num' {
foreach m1 of numlist `mod1num' {
	
	if `colstart' >  26 {
		loc ++collet1n
		loc collet1 "`=char(`=64+`collet1n'')'"
		loc colstart = `colstart' - 26
	}
	export excel "`xfilenm'" if `mod2stub' == `m2' & `mod1stub' == `m1'  , sheet("plotdata_combined") ///
		sheetmodify nolabel firstrow(variables) cell(`collet1'`=char(`=64+`colstart'')'1)
	loc colstart= `colstart' +`colinc'
}
}
