
capture program drop vbkwbstrap 
program define vbkwbstrap, rclass
version 14.2
        #delimit ;
        syntax varlist(min=2 fv) [if] [in], 
		OUTcome(varlist)
        ;
        #delimit cr
********************************************************************************
        // clean up data: these are empty varnames which i will use later for _ATTsupport _ATTweight etc.
		tokenize `varlist'
		gettoken treat xvars : varlist
		di "`treat'"
		di "`xvars'"
		_fv_check_depvar `treat'
		*local nx : list sizeof xvars
		levelsof `treat', local(levels)
		di "`levels'"
		di r(levels)
		qui tab `treat'
		local n_cat = r(r)
		
		
********************************************************************************
        if ("`outcome'"!="") {
                foreach v of varlist `outcome' {
                        cap drop _`v'
                        local moutvar `moutvar' _`v'
						
                }
        }
		di "`moutvar'"
********************************************************************************
        // determine subset we work on
        marksample touse
        capture markout `touse' `outcome'
		//markout makes it so that obs in the vars of varlist or outcome that are missing aren't used in the program. 
		tab `touse'



*draw bootstrap samples the same size as N: 
*https://www.stata.com/support/faqs/statistics/bootstrapped-samples-guidelines/
use vbkwtemp_jesslum, clear 
bsample

vbkw_main `treat' `xvars', outcome(`outcome')

levelsof `treat', local(levels)
tokenize `levels'
if `n_cat' == 3 {
return scalar vbkw_ATE`1'`2'b = vbkw_ATE`1'`2'
return scalar vbkw_ATE`1'`3'b = vbkw_ATE`1'`3' 
return scalar vbkw_ATE`2'`3'b = vbkw_ATE`2'`3'
return scalar vbkw_ATT`1'`2'_`1'b = vbkw_ATT`1'`2'_`1'
return scalar vbkw_ATT`1'`2'_`2'b = vbkw_ATT`1'`2'_`2'
return scalar vbkw_ATT`1'`3'_`1'b = vbkw_ATT`1'`3'_`1'
return scalar vbkw_ATT`1'`3'_`3'b = vbkw_ATT`1'`3'_`3'
return scalar vbkw_ATT`2'`3'_`2'b = vbkw_ATT`2'`3'_`2'
return scalar vbkw_ATT`2'`3'_`3'b = vbkw_ATT`2'`3'_`3'

}

if `n_cat' == 4 {
return scalar vbkw_ATE`1'`2'b = vbkw_ATE`1'`2'
return scalar vbkw_ATE`1'`3'b = vbkw_ATE`1'`3'
return scalar vbkw_ATE`1'`4'b = vbkw_ATE`1'`4' 
return scalar vbkw_ATE`2'`3'b = vbkw_ATE`2'`3'
return scalar vbkw_ATE`2'`4'b = vbkw_ATE`2'`4'
return scalar vbkw_ATE`3'`4'b = vbkw_ATE`3'`4'
return scalar vbkw_ATT`1'`2'_`1'b = vbkw_ATT`1'`2'_`1'
return scalar vbkw_ATT`1'`2'_`2'b = vbkw_ATT`1'`2'_`2'
return scalar vbkw_ATT`1'`3'_`1'b = vbkw_ATT`1'`3'_`1'
return scalar vbkw_ATT`1'`3'_`3'b = vbkw_ATT`1'`3'_`3'
return scalar vbkw_ATT`1'`4'_`1'b = vbkw_ATT`1'`4'_`1'
return scalar vbkw_ATT`1'`4'_`4'b = vbkw_ATT`1'`4'_`4'
return scalar vbkw_ATT`2'`3'_`2'b = vbkw_ATT`2'`3'_`2'
return scalar vbkw_ATT`2'`3'_`3'b = vbkw_ATT`2'`3'_`3'
return scalar vbkw_ATT`2'`4'_`2'b = vbkw_ATT`2'`4'_`2'
return scalar vbkw_ATT`2'`4'_`4'b = vbkw_ATT`2'`4'_`4'
return scalar vbkw_ATT`3'`4'_`3'b = vbkw_ATT`3'`4'_`3'
return scalar vbkw_ATT`3'`4'_`4'b = vbkw_ATT`3'`4'_`4'




}

if `n_cat' == 5 {

return scalar vbkw_ATE`1'`2'b = vbkw_ATE`1'`2'
return scalar vbkw_ATE`1'`3'b = vbkw_ATE`1'`3'
return scalar vbkw_ATE`1'`4'b = vbkw_ATE`1'`4' 
return scalar vbkw_ATE`1'`5'b = vbkw_ATE`1'`5' 
return scalar vbkw_ATE`2'`3'b = vbkw_ATE`2'`3'
return scalar vbkw_ATE`2'`4'b = vbkw_ATE`2'`4'
return scalar vbkw_ATE`2'`5'b = vbkw_ATE`2'`5'
return scalar vbkw_ATE`3'`4'b = vbkw_ATE`3'`4'
return scalar vbkw_ATE`3'`5'b = vbkw_ATE`3'`5'
return scalar vbkw_ATE`4'`5'b = vbkw_ATE`4'`5'
return scalar vbkw_ATT`1'`2'_`1'b = vbkw_ATT`1'`2'_`1'
return scalar vbkw_ATT`1'`2'_`2'b = vbkw_ATT`1'`2'_`2'
return scalar vbkw_ATT`1'`3'_`1'b = vbkw_ATT`1'`3'_`1'
return scalar vbkw_ATT`1'`3'_`3'b = vbkw_ATT`1'`3'_`3'
return scalar vbkw_ATT`1'`4'_`1'b = vbkw_ATT`1'`4'_`1'
return scalar vbkw_ATT`1'`4'_`4'b = vbkw_ATT`1'`4'_`4'
return scalar vbkw_ATT`1'`5'_`1'b = vbkw_ATT`1'`5'_`1'
return scalar vbkw_ATT`1'`5'_`5'b = vbkw_ATT`1'`5'_`5'
return scalar vbkw_ATT`2'`3'_`2'b = vbkw_ATT`2'`3'_`2'
return scalar vbkw_ATT`2'`3'_`3'b = vbkw_ATT`2'`3'_`3'
return scalar vbkw_ATT`2'`4'_`2'b = vbkw_ATT`2'`4'_`2'
return scalar vbkw_ATT`2'`4'_`4'b = vbkw_ATT`2'`4'_`4'
return scalar vbkw_ATT`2'`5'_`2'b = vbkw_ATT`2'`5'_`2'
return scalar vbkw_ATT`2'`5'_`5'b = vbkw_ATT`2'`5'_`5'
return scalar vbkw_ATT`3'`4'_`3'b = vbkw_ATT`3'`4'_`3'
return scalar vbkw_ATT`3'`4'_`4'b = vbkw_ATT`3'`4'_`4'
return scalar vbkw_ATT`3'`5'_`3'b = vbkw_ATT`3'`5'_`3'
return scalar vbkw_ATT`3'`5'_`5'b = vbkw_ATT`3'`5'_`5'
return scalar vbkw_ATT`4'`5'_`4'b = vbkw_ATT`4'`5'_`4'
return scalar vbkw_ATT`4'`5'_`5'b = vbkw_ATT`4'`5'_`5'

}
end 
