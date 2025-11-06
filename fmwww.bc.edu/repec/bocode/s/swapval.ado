*! 2.0.0 NJC 3 November 2025 
*! 1.0.1 NJC 24 November 1999 
program define swapval
	version 8.2 
	syntax varlist(min=2 max=2) [if] [in] 
	
	tokenize `varlist' 
	args a b
	
	capture confirm string variable `a' 
	local aisnum = _rc > 0 
	capture confirm string variable `b'
	local bisnum = _rc > 0 
	if `aisnum' != `bisnum' { 
		di as err "variables must be compatible types" 
		error 109 
	} 
	
	if `"`if'`in'"' == "" { 
		nobreak { 
			tempname copy 
            rename `b' `copy' 
            rename `a' `b' 
            rename `copy' `a' 
        }   
		
		exit 0 
	}
	
	marksample touse, novarlist strok 
	quietly count if `touse'
	if r(N) == 0 error 2000 
		
	tempvar copy 
	clonevar `copy' = `b'
	quietly { 
		replace `b' = `a' if `touse'
		replace `a' = `copy' if `touse'
	} 	
	
end 

