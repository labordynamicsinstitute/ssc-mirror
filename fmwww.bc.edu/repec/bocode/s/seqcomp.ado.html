program seqcomp
	version 9
	syntax varlist [if] [iw/] using/ [, id(varname)]
	marksample touse
	if (`"`weight'"'== "")	{
		/*display "No weights are used"*/
		ge wt_=1
	} 
 	else {
 		display "Weights used: `exp'"
 		quietly ge wt_=`exp'
 		quietly count
 		local n1=r(N)
 		quietly count if `exp'<.
 		local n2=r(N)
 		local n3=`n1'-`n2'
 		if (`n3'!=0) display "Warning! `exp' contains `n3' missing values: corresponding sequences are not analyzed"
 	} 
	if (`"`id'"'== "")	{
		/*display "No weights are used"*/
		ge id_=_n
	} 
	else ge id_=`id'
	plugin call distseq `varlist' wt_ id_ `if', "`using'"
	drop wt_ id_
end
program distseq, plugin 

