
*! version 1.00 November 20, 2009
*! Ben A. Dwamena: bdwamena@umich.edu 

program define midas_bclust2bin, rclass byable(recall) sortpreserve
version 15

syntax varlist(min=5) [if] [in] , [ ID(varlist max=6) *]

marksample touse, novarlist

tokenize `varlist'
global tp `1'
global fp `2'
global fn `3'
global tn `4'
global np `5'

tempvar nn kk pr cv icc vif mcs 

gen  `nn' = $tp + $fp + $fn + $tn
gen  `kk' = ($np-1)/$np
gen `pr' = ($tp + $fn) /`nn'

gen  `cv' = (sqrt(2*`nn'*($fp + $fn))/(($fp + $fn)+(2*$tp)))^2

gen `icc' = 1-(($fp + $fn)/(2*`nn'*`pr'*(1-`pr')))

gen `mcs' = `nn'/$np 
gen `vif' = 1
qui replace `vif' = 1 + (((1 + `cv'*`kk')*`mcs') - 1)*`icc' if `mcs' != 1
foreach v of varlist $tp-$tn {
gen midas_`v' = int(`v'/`vif')
}

end