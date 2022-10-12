*! v3 10 Oct 2022
//this program assigns observations to classing by calculating the maximum a posteriori probabilities 
pro def cwmglm_predict
syntax newvarname (min=1 max=1) 
version 16
local posterior=e(posterior)
tempvar max touse
gen `touse'=e(sample)
quie egen double `max'=rowmax(`posterior') if `touse'
quie gen double `varlist'=. if `touse'
local i=1
foreach var of local posterior {
    quie replace `varlist'=`i' if `var'==`max' & `touse'
	local i=`i'+1
}

end
