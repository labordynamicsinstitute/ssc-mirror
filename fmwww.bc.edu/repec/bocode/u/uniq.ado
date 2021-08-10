*! 2feb2011 
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program uniq, byable(recall) sort 
version 8.2 
syntax varlist [if] [in] , [Count]
 
marksample touse, strok 
sort `touse' `varlist' 
tempvar temp 
qui gen byte `temp'=_n==1 
foreach v of local varlist { 
	qui replace `temp'=1 if `v'[_n]~=`v'[_n-1] & _n>1 
	} 
qui cnt if `temp' & `touse'
if mi("`count'") di as res %12.0fc `r(N)' 
else di as res %12.0fc `r(N)',"{txt: of }",%12.0fc `c(N)',"{txt: records}"
end 
 
