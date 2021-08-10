*! 29aug2007 
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program xtilel, byable(onecall) 
version 9.1 
syntax newvarname =exp [if] [in] [, Nquantiles(integer 2)] 
 
tempvar groups 
marksample touse, novarlist 
quietly { 
	gen `varlist'=. 
	egen `groups'=group(`_byvars') 
	levelsof `groups', local(gl) 
	foreach gr of local gl { 
		tempvar hold 
		xtile `hold'`exp' if `groups'==`gr' & `touse', nq(`nquantiles') 
		replace `varlist'=`hold' if `groups'==`gr' 
		drop `hold' 
		} 
	} 
end 
