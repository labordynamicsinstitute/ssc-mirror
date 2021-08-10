*! version 1 abuxton 01oct2004.
* postcureregtask1, cure model regression or parametric cure model PCM
* post cureregr display survival estimates at(numlist times)

capture program drop postcureregtask1
program define postcureregtask1,rclass
version 8.2

		syntax [if] [in] , At_points(numlist)
			tempvar touse
			mark `touse' `if' `in' `e(sample)'
			qui count if `touse'
			if r(N)==0 {
				error 2000 			/* no observations */
				} 
			local Nlst = `"`at_points'"'
			numlist "`Nlst'" , min(1) sort ascending
			local timelst = r(numlist)
	preserve

	qui keep if `touse'
	qui keep if _n==1 /* try keeping one case - so this may run faster by not predicting the entire e(sample) */

	tempname S seS lci uci lmllci lmluci lmlS lml_lci lml_uci
	local ttfunction `"((exp(xb(#2)) * `time')^exp(xb(#3)))"'

capture noisily {
	foreach time of numlist `timelst' {

		local lnl = lower(substr(`"`e(user)'"',4,2))
		local krn = lower(substr(`"`e(user)'"',6,2))
		local cfl = lower(substr(`"`e(user)'"',8,2))
		
		if `"`cfl'"' == `"01"' {
			local pi `"(1/(1+exp(-1*(xb(#1)))))"'
			}	
		else if `"`cfl'"' == `"02"' {
			local pi `"(exp(-1*exp((xb(#1)))))"'
			}	
		else if `"`cfl'"' == `"03"' {
			local pi `"((xb(#1)))"'
			}
			
		local ttfunction `"((exp(xb(#2)) * `time')^exp(xb(#3)))"'
		
		if `"`krn'"' == `"01"' {
			local kr `"(1-exp(-1*(`ttfunction')))"'
			}
		else if `"`krn'"' == `"02"' {
			local kr `"(norm(ln(`ttfunction')))"'
			}
		else if `"`krn'"' == `"03"' {
			local kr `"(`ttfunction'/(1 + `ttfunction'))"'
			}
		else if `"`krn'"' == `"04"' {
			local tt `"((`time')/exp(xb(#2)))"'
			local kr `"(gammap(exp(xb(#3)),`tt'))"'
			}
		else if `"`krn'"' == `"05"' {				// exponential dist gamma shape==1
			local tt `"((`time')/exp(xb(#2)))"'
			local kr `"(gammap(1,`tt'))"'
			}
			
		if `"`lnl'"' == `"00"'	{
			local function `"(1+((`pi'-1)*`kr'))"'
			}
		else if `"`lnl'"' == `"01"'	{
			local function `"((`pi')^(`kr'))"'
			}

		local lmlfunction `"ln(-1*ln(`function'))"'
		
		qui predictnl double `S' = `function', se(`seS') ci(`lci' `uci') level(95) force iter(100)
		qui predictnl double `lmlS' = `lmlfunction', ci(`lmllci' `lmluci') level(95) force iter(100)
			qui gen double `lml_lci'  = exp(-exp(`lmluci'))
			qui gen double `lml_uci'  = exp(-exp(`lmllci'))
			local surv = round(`S'[1]*1000000)/1000000
			local serr = round(`seS'[1]*1000000)/1000000
			local slci = round(`lml_lci'[1]*1000000)/1000000
			local suci = round(`lml_uci'[1]*1000000)/1000000
			di `"{res}time: "' `time', _col(12) `"S(t)= "' `surv', _col(27) `"se= "' `serr' _col(40) `"ci: ("' `slci' _col(52) `" - "' _col(55) `suci' `") {txt}"'
			qui drop `S' `seS' `lci' `uci' `lmllci' `lmluci' `lmlS' `lml_lci' `lml_uci'
			local rtn_time = `time'
	}
}
	di `"{txt}"'
	return scalar pcm_uci=`suci'
	return scalar pcm_lci=`slci'
	return scalar pcm_se=`serr'
	return scalar pcm_s=`surv'
	return scalar pcm_time=`rtn_time'
end /* postcureregtask1 */ 
