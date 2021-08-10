* postcureregtask2, cure model regression or parametric cure model PCM
* post cureregr calculate hazard estimate and fail density for 
* non-mixture model with a log-minus-log curefraction link function
capture program drop postcureregtask2
program define postcureregtask2
version 8.2
/* calculate the fail density */
			local pi `"(exp(-1*exp((xb(#1)))))"'
			local ttfunction `"((exp(xb(#2)) * _t)^exp(xb(#3)))"'
			local dtt = `"((`ttfunction')*exp(xb(#3))/_t)"'
			
		local md  = lower(substr(`"`e(user)'"',4,2))
		local krn = lower(substr(`"`e(user)'"',6,2))
		local cf  = lower(substr(`"`e(user)'"',8,2))
		if `"`cf'"' == `"02"' & `"`md'"' == `"01"' {
		if `"`krn'"' == `"01"' {					// weibull, exponential in tt,  dist
			local kr `"(1-exp(-1*(`ttfunction')))"'
			local dk `"((exp(-1*(`ttfunction')))*(`dtt'))"'
			}
		else if `"`krn'"' == `"02"' {				// ln-normal dist
			local kr `"(norm(ln(`ttfunction')))"'
			local dk `"(normden(ln(`ttfunction'))*exp(xb(#3))/_t)"'
			}
		else if `"`krn'"' == `"03"' {				// logistic dist
			local kr `"(`ttfunction'/(1 + `ttfunction'))"'
			local dk `"((1/(1+`ttfunction')^2)*(`dtt'))"'
			}
		else if `"`krn'"' == `"04"' {				// gamma dist
			local tt `"((_t)/exp(xb(#2)))"'
			local kr `"(gammap(exp(xb(#3)),`tt'))"'
			local dk `"(gammaden(exp(xb(#3)),exp(xb(#2)),0,_t))"'
			}
		else if `"`krn'"' == `"05"' {				// exponential dist gamma shape==1
			local tt `"((_t)/exp(xb(#2)))"'
			local kr `"(gammap(1,`tt'))"'
			local dk `"(gammaden(1,exp(xb(#2)),0,_t))"'
			}
			local function `"((`pi')^(`kr'))"'
			local lmlfunction `"ln(-1*ln(`function'))"'
			tempvar lmlS lmllci lmluci 
			qui predictnl double S = `function', se(seS) level(95) force iter(100)
			qui predictnl double `lmlS' = `lmlfunction', ci(`lmllci' `lmluci') level(95) force iter(100)
			qui gen double lciS  = exp(-exp(`lmluci'))
			qui gen double uciS  = exp(-exp(`lmllci'))
			local ecf = `"(exp((xb(#1))))"'
			local function `"(`ecf')*(`dk')"'
			qui predictnl double haz = `function', force iter(100)
			local function `"(`dk')"'
			qui predictnl double fd = `function', force iter(100)
}
end /* postcureregtask2 */
