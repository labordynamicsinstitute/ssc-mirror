*! version 0.1.0, Brent McSharry, 12july2013
* Risk adjusted sequential probability ratio chart
program define rasprt, sortpreserve
version 10.1
syntax varlist(min=2 max=2 numeric) [if] [in] , Predicted(varname numeric) [OR(real 2) A1(real 0.01) B1(real 0.01) A2(real 0.05) B2(real 0.05) noSPRT noCUSUM noRESET XLABEL(passthru)] 
	marksample touse
	qui {
		count if `touse'
		local count `r(N)'
		if (`count'==0) {
			di as error "no obs"
			return 2000
		}
		if ("`sprt'"!="" & "`cusum'"!="") {
			di as error "only one of noraspt or nocusum can be specified (otherwise chart is empty)"
			return 198
		}
		tempvar si Tisprt timevar resetvar1 resetvar2 Tihalf
		local observed:word 1 of `varlist'
		local timevar:word 2 of `varlist'

		gsort  -`touse' `timevar'
		local H01 = round(-ln((1-`a1')/`b1'),0.01) /* /ln(`or') */
		local H11 = round(ln((1-`b1')/`a1'),0.01) /* /ln(`or') */
		local H02 = round(-ln((1-`a2')/`b2'),0.01) /* /ln(`or') */
		local H12 = round(ln((1-`b2')/`a2'),0.01) /* /ln(`or') */
		foreach v in `H01' `H11' `H02' `H12' {
			local v:di %3.1g `v' 
			local homac `homac' `v' 
		}

		gen `si' = (ln(`or')* `observed') - ln(1-`predicted' +(`or' * `predicted')) in 1/`count'
		if "`sprt'" == "" {
			gen float `Tisprt' = `si' in 1
			if "`reset'" == "" {
				replace `Tisprt' = `si' + (!((`Tisprt'[_n-1] >= `H11')|(`Tisprt'[_n-1] <= `H01')) * `Tisprt'[_n-1]) in 2/`count'
				gen byte `resetvar1' = ( (`Tisprt' >= `H11') | (`Tisprt' <= `H01') ) & `touse'
				local circleresets (scatter `Tisprt' `timevar' if `resetvar1', msymbol(Oh))
			}
			else {
				replace `Tisprt' = `si' + `Tisprt'[_n-1] in 2/`count'
			}
			local sprtgraph (connected `Tisprt' `timevar' if `touse', msymbol(i))
		}
		
		if "`cusum'" == "" {
			gen float `Tihalf' = `si' in 1
			if  "`reset'"==""{
				replace `Tihalf' = max(`si' + ((`Tihalf'[_n-1] < `H11')*`Tihalf'[_n-1]),0) in 2/`count'
				gen byte `resetvar2' = (`Tihalf' >= `H11') & `touse'
				local circleresets `circleresets' (scatter `Tihalf' `timevar' if `resetvar2', msymbol(Oh))
			}
			else {
				replace `Tihalf' = max(`si' + `Tihalf'[_n-1],0) in 2/`count'
			}
			local halfgraph (connected `Tihalf' `timevar' if `touse', msymbol(i))
		}
	}

	twoway `sprtgraph' `halfgraph' `circleresets' /*
	*/ , yline(`H01' `H11' 0 `H02' `H12') /*
	*/ legend(off) `xlabel' ytitle("Cumulative Log-Likelihood Ratio") /*
	*/ ylabel(`H01' `H02' 0 `H12' `H11', angle(0)) yscale(range(`=1.2*`H01'' `=1.2*`H11''))
end
