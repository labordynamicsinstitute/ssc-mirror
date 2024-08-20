*! 1.0.0 NJC 18aug2024 
program qbplot, sortpreserve 
	version 8.2
	syntax varname(numeric) [if] [in] ///
	[, a(str) spike(str asis) addplot(str asis) *]
	
	quietly { 
		* data to use 
		marksample touse 
		count if `touse'
		if r(N) == 0 error 2000 
		
		* determine y axis title 
		local y `varlist'
		local what : variable label `y'
		if `"`what'"' == "" local what `y'
		
		* sorting is needed if recast(line) or recast(connect) is called  
		replace `touse' = -`touse'
		sort `touse' `y'
	`'
		tempvar rank count pp quartiles where 
	
		egen `rank' = rank(`y') if `touse', unique 
		egen `count' = count(`y') if `touse' 
		if "`a'" == "" local a = 0.5 
		gen `pp' = (`rank' - (`a')) / (`count' + 1 - 2 * (`a'))

		su `y' if `touse', detail 

		foreach q in min p25 p50 p75 max { 
			local Q `Q' `r(`q')' 
		}

		local min = r(min)

		pctile `quartiles' = `y' if `touse', nq(4)
		gen `where' = 0.25 * _n in 1/3
	} 
	
	twoway spike `quartiles' `where', base(`min') pstyle(p2) `spike' ///
	|| spike `where' `quartiles', horizontal pstyle(p2) `spike' ///
    || scatter `y' `pp', pstyle(p1) ms(oh) ///
	xla(0 "0" 0.25 "0.25" 0.5 "0.5" 0.75 "0.75" 1 "1") yla(`Q') ///
	ytitle(`"`what'"') legend(off) xtitle(Fraction of the data) `options' ///
	|| `addplot' 
	
end

