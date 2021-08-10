*! 1.0.0 NJC 26 November 2003
program catploti 
	version 8
	
	gettoken plottype 0 : 0 
	local plotlist "bar dot hbar" 
	if !`: list plottype in plotlist' { 
		di ///
		"{p}{txt}syntax is {inp:catploti} {it:plottype} ..." /// 
		"... e.g. {inp: catploti hbar} ...{p_end}" 
		exit 198 
	}

	gettoken args 0 : 0, parse(",") 
	syntax [, Tabi(str asis) Catplot(str asis)]
	preserve 

	if index("`tabi'", "replace") tabi `args', `tabi' 
	else tabi `args', `tabi' replace 

	catplot `plottype' row col [fw=pop] , `catplot' 
end

