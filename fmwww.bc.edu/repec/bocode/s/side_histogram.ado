* 1.0.0 NJC 2 September 2024
program side_histogram, sortpreserve 
	version 8.2 
	syntax varname(numeric) [if] [in] [fweight], over(varname) ///
	[start(numlist max=1) width(numlist max=1 >0) Discrete FRACtion FREQuency ///
	BAR1options BAR2options squeeze(real 1) * ]
	
	quietly { 
		if "`fraction'" != "" & "`frequency'" != "" { 
			di as err "may not specify both fraction and frequency"
			exit 198 
		}
		local f "`fraction'`frequency'"
		
		marksample touse 
		markout `touse' `over', strok 
		count if `touse'
		if r(N) == 0 error 2000 
		local N = r(N)

		replace `touse' = -`touse'
		sort `touse' `over'

		capture confirm numeric variable `over'
		if _rc { 
			tempvar numover 
			encode `over' if `touse', gen(`numover')
			local over `numover'
		} 
		
		local over1 = `over'[1]
		local over2 = `over'[`N']
		
		count if `touse' & !inlist(`over', `over1', `over2')
		if r(N) > 0 {
			di as err "`over' takes on more than 2 distinct values"
			exit 420
		}
		if `over1' == `over2' {
			di as err "`over' takes on only 1 distinct value"
			exit 420
		} 
		
		local item1 : label (`over') `over1'
		local item2 : label (`over') `over2' 
		
		su `varlist' if `touse', meanonly
		local min = r(min)
		local max = r(max)
		
		if "`start'" == "" local start = r(min)
		if "`width'" == "" local width = (r(max) - r(min)) / 20 
		
		tempvar h1 h2 x1 x2 
		twoway__histogram_gen `varlist' if `over' == `over1' [`weight' `exp'] ///
		, `discrete' `f' start(`start') width(`width') gen(`h1' `x1')
		twoway__histogram_gen `varlist' if `over' == `over2' [`weight' `exp'] ///
		, `discrete' `f' start(`start') width(`width') gen(`h2' `x2')	 
		replace `x1' = `x1' - `squeeze' * `width'/4 
		replace `x2' = `x2' + `squeeze' * `width'/4 
	}
	
	local wh = `squeeze' * `width'/2 
	
	twoway bar `h1' `x1', barwidth(`wh') pstyle(p1) `bar1options' ///
	|| bar `h2' `x2', pstyle(p2) barwidth(`wh') ///
	legend(order(1 "`item1'" 2 "`item2'")) `bar2options' `options'
end 
	
		
		
		
		
