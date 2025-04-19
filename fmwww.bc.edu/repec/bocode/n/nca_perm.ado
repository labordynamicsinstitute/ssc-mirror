*! nca_perm v1.0 04/18/2025
pro def nca_perm, eclass
syntax [anything], [reps(integer 10)]
tempname _estimates
quie estimates store `_estimates'
tempname test_res
local colnames: colfullnames e(results), quoted
cap mata: assert(st_matrix("e(results)")[8,.]==J(1, cols(st_matrix("e(results)")),0))
if !_rc {
quie estimates restore `_estimates'
matrix `test_res'= J(1, colsof(e(results)) , 1)
matrix `test_res'= `test_res'\J(1, colsof(e(results)) , 0)
matrix colnames `test_res'=`colnames'
matrix rownames `test_res'= "p-value" "p-accuracy" 
ereturn matrix testres=`test_res'
exit
}
tempname es
matrix `es'=e(results)["Effect size",.]
_dots 0, title("NCA approximate permutation test progress") reps(`reps')
local ncavars `e(indepvars)' `e(depvar)'
tempvar samp
tempname permres
quie gen byte `samp'=e(sample)
local vars
quie foreach v of varlist `ncavars' {
	tempname n`v'
	local vars `vars' `n`v''
}

quie forval rr=1/`reps' {
	
	quie foreach v of varlist `ncavars' {
		cap drop `n`v''
		clonevar `n`v'' = `v' if `samp'  /* usa var temporanea*/
		mata: st_store(., "`n`v''", jumble(st_data(., "`n`v''","`samp'")))
		}
	
	cap nca_estimate `vars' if `samp',  ceilings(`e(ceilings)') nograph
	noi	_dots `rr' 0
	if (!_rc) matrix `permres'=nullmat(`permres')\ e(results)["Effect size",.]

}
cap drop _s_c_r_*
tempname accuracy testres
matrix `testres'=`es'
matrix `accuracy'=`es'

mata: ______pval=mean ( (st_matrix("`permres'"):>st_matrix("`es'")) ) 
mata: st_matrix( "`testres'", ______pval)
mata: st_matrix( "`accuracy'", 1.96*sqrt(______pval:*(1:-______pval)/`reps')  )
cap mata: mata drop ______pval
matrix `testres'=(`testres' \ `accuracy' )
matrix colnames `testres' = `colnames'
matrix rownames `testres' = "p-value" "p-accuracy" 
quie estimates restore `_estimates'
ereturn matrix testres=`testres'
end
