*! 2.0.0 NJC 8 December 2022 
*! 1.0.0 NJC 14 November 2011
program find_denom, rclass 
	version 9 
	gettoken percent 0 : 0, parse(,)
	syntax , EPSilon(real)
	
	numlist "`percent'", min(0) max(100)
	local percent `r(numlist)'
	local npc : word count `percent'
	tempname pc 
	matrix `pc' = J(`npc', 1, .) 
	tokenize `percent'
	forval i = 1/`npc' { 
		matrix `pc'[`i', 1] = ``i''
	}
	
	mata: find_denom_v("`pc'", `epsilon')
	display _n "minimum sample size is " scalar(n)
	display "frequencies are `frequencies'"	
	return scalar n = scalar(n)
	return local frequencies "`frequencies'" 
end 

mata : 

mata clear 

void find_denom_v(string scalar vecname, real scalar eps) { 
	real scalar n   
	real vector work, i   
	work = st_matrix(vecname)
	work = select(work, (work :< .)) :/ 100
	eps = eps / 100 
	n = 1 

	while (1) {
		i = round(n :* work)
		if (all((((work :- eps) :* n) :<= i) :& 
			(((work :+ eps) :* n) :>= i))) { 
			st_numscalar("n", n)
			st_local("frequencies", invtokens(strofreal(i')))
			break
		}
		n++ 
	}
} 

end 
	
	
