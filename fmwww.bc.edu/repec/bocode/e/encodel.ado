*! 5apr2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
* 29aug2007 
program encodel 
version 11.1 
syntax varlist, [Label(string) Multilabel yn] 
 
foreach v of local varlist { 
	capture confirm str var `v' 
	if (_rc) mata: errel("`v' is not a string variable")
	} 
if mi("`yn'") { 
	if mi("`label'") { 
		gettoken label: varlist 
		local label `label'_enc 
		} 
	foreach v of local varlist { 
		encode `v', g(`v'__) l(`=cond(mi("`multilabel'"),"`label'","`v'_enc")') 
		order `v'__, after(`v')
		drop `v' 
		rename `v'__ `v' 
		} 
	} 
else { 
	foreach v of local varlist {
		mata: CheckVar("`v'")
		quietly { 
			replace `v'=trim(lower(`v'))
			replace `v'="0" if inlist(`v',"n","no","f","false")
			replace `v'="1" if inlist(`v',"y","yes","t","true")
			}
		destring `v', replace 
		} 
	mata:qlabel("`varlist'",(0,1),("No","Yes"),"yn")
	} 
end 
 
version 11.1
mata:
void CheckVar(string scalar vname) { //>>def func<<
	st_sview(V=.,.,vname)
	vals=uniqrows(strtrim(strlower(uniqrows(V))))
	if (sum(vals:==J(length(vals),1,("","n","y","no","yes","f","t","false","true","0","1")))!=length(vals)) errel(sprintf("Cannot interpret %s as yes/no",vname))
	}
end
	
	
