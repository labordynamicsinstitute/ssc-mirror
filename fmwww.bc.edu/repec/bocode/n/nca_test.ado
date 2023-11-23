pro def nca_test, eclass
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
//ereturn matrix testres=J(1, colsof(e(results)),0)
exit
}
di "executing permutations"
quietly permute `e(depvar)' `e(permlist)', reps(`reps')  : nca_estimate `e(indepvars)' `e(depvar)' ,  ceilings(`e(ceilings)') nograph
display _newline(1)
tempname test_res
matrix `test_res'= r(p_upper)
matrix `test_res'=(`test_res'\1.96*r(se_p_upper))
matrix colnames `test_res'=`colnames'
matrix rownames `test_res'= "p-value" "p-accuracy" 
quie estimates restore `_estimates'
ereturn matrix testres=`test_res'

end
