*! 1.0.0 NJC 28 Nov 2022 
program jaccard 
version 11 
syntax varlist(min=2) [if] [in] [fweight aweight/] ///
[, upper lower DIAGonal complement count           ///
varlabels variablelabels savedata(str asis) *]

if "`count'" != "" & "`complement'" != "" {
	di as err "count and complement may not be combined" 
	exit 198 
}

quietly {
 
marksample touse 
foreach v of local varlist {
	replace `touse' = 0 if !inlist(`v', 0, 1)
}

count if `touse'
if r(N) == 0 error 2000 
if r(N) == 1 error 2001 

local nvars : word count `varlist'
tokenize `varlist'

tempfile jaccard 
tempname where 
postfile `where' _which1 str80 _name1 _which2 str80 _name2 _inter _union _Jaccard using "`jaccard'"

if "`exp'" == "" {
	tempvar exp 
	gen `exp' = 1 
}

forval i = 1/`nvars' { 
	
	forval j = 1/`nvars' { 
		
		su `exp' if `touse' & ``i'' == 1 & ``j'' == 1, meanonly 
		local inter = r(sum)
		su `exp' if `touse' & (``i'' == 1 | ``j'' == 1), meanonly 
		local this = `inter'/r(sum)

		if "`varlabels'`variablelabels'" != "" {
			local text1 : var label ``i'' 
			if `"`text1'"' == "" local text1 "``i''"  
			local text2 : var label ``j''
			if `"`text2'"' == "" local text2 "``j''"
			post `where' (`i') (`"`text1'"') (`j') (`"`text2'"') (`inter') (`r(sum)') (`this') 
		}
		else post `where' (`i') ("``i''") (`j') ("``j''") (`inter') (`r(sum)') (`this')
		
	}
	
}

postclose `where'

preserve 
use "`jaccard'", clear 
compress 

labmask _which1, values(_name1)
labmask _which2, values(_name2)

} /// end quietly 

if "`lower'`upper'`diagonal'" == "" {
	local select if _which2 < _which1 
}
else if "`lower'" != "" & "`diagonal'`upper'" == "" {
	local select if _which2 < _which1 
}
else if "`lower'" != "" & "`diagonal'" != "" & "`upper'" == ""{
	local select if _which2 <= _which1 
}
else if "`diagonal'" != "" & "`upper'" != "" & "`lower'" == "" {
	local select if _which2 >= _which1 
}
else if "`diagonal'" == "" & "`upper'" != "" & "`lower'" == "" {
	local select if _which2 > _which1 
}
else if "`diagonal'" == "" & "`upper'" != "" & "`lower'" != "" {
	local select if _which2 != _which1 
}
else if "`upper'" != "" & "`diagonal'" != "" & "`lower'" != "" {
	local select 
}

local opts xtitle("") ytitle("") aspect(1) `options' 

if "`complement'" != "" { 
	quietly replace _Jaccard = 1 - _Jaccard
	label var _Jaccard "1 {&minus} Jaccard"  
	char _Jaccard[varname] "1 - Jaccard" 
}
else char _Jaccard[varname] "Jaccard" 

if "`complement'" != "" { 
	c_local graph_cmd "tabplot _which1 _which2 `select' [iw=_Jaccard], subtitle(1 {&minus} Jaccard) `opts'"
	tabplot _which1 _which2 `select' [iw=_Jaccard], subtitle(1 {&minus} Jaccard) `opts'
}
else if "`count'" != "" { 
	c_local graph_cmd "tabplot _which1 _which2 `select' [iw=_inter], subtitle(intersection count) `opts'"
	tabplot _which1 _which2 `select' [iw=_inter], subtitle(intersection count) `opts'
} 
else {
	c_local graph_cmd "tabplot _which1 _which2 `select' [iw=_Jaccard], `opts'"
	tabplot _which1 _which2 `select' [iw=_Jaccard], subtitle(Jaccard) `opts'
}

char _which1[varname] "`=char(32)'"
char _which2[varname] "`=char(32)'" 
char _union[varname] "union" 
char _inter[varname] "intersection count"

list _which? _inter _union _Jaccard, sep(`nvars') subvarname abbrev(12) 

if `"`savedata'"' != "" {
	save `savedata'
}
end 
