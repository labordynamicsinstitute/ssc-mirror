
program mcattest
version 14.1
syntax  , mcvar(varname) var2(varname) vallist(string) 
tempname estnm
qui{
est store `estnm'
levelsof `mcvar', loc(nval)
loc ncat : list sizeof nval
mtable , at (`var2' "= (`vallist')" `mcvar'=(`nval')) atmeans stat(pvalue noci) post
mlincom , clear
loc atind = 1-`ncat'
forvalues fi = `vallist' {
	loc atind= `atind' + `ncat'
	loc difftxt ""
	forvalues i=1/`=`ncat'-1' {
	forvalues j=1/`=`ncat'- `i'' {
	
		if `j' == 1 & `i'== 1 loc difftxt "`difftxt' `=`atind'+`j'' - `atind'  "
		if `j' > 1 | `i' > 1 loc difftxt "`difftxt' + `=`atind'+`j'+`i'-1' - `=`atind'+`i'-1'  "
	}
	}
	mlincom `difftxt' , add rowname("`fi'")
}
}
mlincom
qui est restore `estnm'
end 
