*! imperfectiv: Estimating bounds with Nevo and Rosen's Imperfect IV procedure
*! Version 0.1.0 May 26, 2017 @ 08:54:12
*! Authors: Benjamin Matta and Damian Clarke


cap program drop imperfectiv
program imperfectiv, eclass
version 8.0

#delimit ;

syntax anything(name=0 id="variable list")
    [if] [in]
    [fweight pweight aweight iweight]
    [,
     Ncorr 
     Prop5
     NOASsumption4
     Level(cilevel)
     vce(string)
     short 
    ]
;
#delimit cr

*-------------------------------------------------------------------------------
*-- (1) Unpack arguments, check for valid syntax, general error capture
*-------------------------------------------------------------------------------
local 0: subinstr local 0 "=" " = ", count(local equal)
local 0: subinstr local 0 "(" " ( ", count(local lparen)
local 0: subinstr local 0 ")" " ) ", count(local rparen)

local rops  `if' `in' [`weight' `exp']
if length("`vce'")!=0 local rops  `if' `in' [`weight' `exp'], vce(`vce')

if `equal'!=1|`lparen'!=1|`rparen'!=1 {
    dis as error "Specification of varlist is incorrect."
    dis as error "Ensure that syntax is: method yvar [exog] (endog=iv), [opts]"
    exit 200
}

tokenize `0'

local yvar `1'
macro shift

local varlist1
while regexm(`"`1'"', "\(")==0 {
    local varlist1 `varlist1' `1'
    macro shift
}

local varlist2
while regexm(`"`1'"', "=")==0 {
    local var=subinstr(`"`1'"', "(", "", 1)
    local varlist2 `varlist2' `var'
    macro shift
}

local varlist_iv
while regexm(`"`1'"', "\)")==0 {
    local var=subinstr(`"`1'"', "=", "", 1)
    local varlist_iv `varlist_iv' `var'
    macro shift
}
macro shift

if length("`1'")!=0 {
    dis as error "Specification of varlist is incorrect."
    dis as error "Ensure that syntax is: imperfectiv yvar [exog] (endog=iv)"
    exit 200
}

local ci=(100-`level')/200


local kEx   : word count `varlist1'
local kEn   : word count `varlist2'
local kIV   : word count `varlist_iv'

*-------------------------------------------------------------------------------
*-- (2) Regressions used to construct bounds
*-------------------------------------------------------------------------------
local lower
local upper
tokenize `varlist_iv'
local i=1
while `i'<`kIV'+1{
    if length("`noassumption4'")!=0{
        if `kEx'==0{
            qui: reg `yvar'  `varlist2' `rops'
        }
        else{
            qui: reg `yvar' `varlist1'  `varlist2' `rops'
        }
    }
    else{
        matrix P = J(2,1,0)
        qui: sum `varlist2'
        matrix P[1,1]=r(sd)
        qui: sum `1'
        matrix P[2,1]=r(sd)
        tempvar v_var
        gen `v_var'=P[1,1]*`1'-P[2,1]*`varlist2'
        
        if `kEx'==0{
            qui: ivregress 2sls `yvar'  (`varlist2'=`v_var') `rops'
        }
        else{
            qui: ivregress 2sls `yvar' `varlist1' (`varlist2'=`v_var') `rops'
        }        
    } 
    local DFM = e(N)-e(rank)
    local liv_v = _b[`varlist2']-invttail(`DFM',`ci')*_se[`varlist2']
    local uiv_v = _b[`varlist2']+invttail(`DFM',`ci')*_se[`varlist2']
    if `kEx'==0{
        qui: ivregress 2sls `yvar' (`varlist2'=`1') `rops'
    }
    else{
        qui: ivregress 2sls `yvar' `varlist1' (`varlist2'=`1') `rops'
    }
    
    local DFM = e(N)-e(rank)
    local liv = _b[`varlist2']-invttail(`DFM',`ci')*_se[`varlist2']
    local uiv = _b[`varlist2']+invttail(`DFM',`ci')*_se[`varlist2']
    
    
    if `kEx'==0 |  length("`noassumption4'")!=0{
        qui corr `varlist2' `1'
        
        if r(rho)<0{
            if length("`ncorr'")!=0{
                local lower `lower' `liv_v'
                local upper `upper' `uiv'
            }
            else {
                local lower `lower' `liv'
                local upper `upper' `uiv_v'
            }
        }
        else{
            if length("`ncorr'")!=0{  
                local lower `lower' `liv' `liv_v'
            }
            else {
                local upper `upper' `uiv' `uiv_v'    
            }
        }
    }
    else{
        qui: reg `varlist2' `varlist1' `rops'
        tempvar x2
        predict `x2', residuals
        matrix Q = J(2,1,0)
        qui: corr `varlist2' `x2', covariance 
        matrix Q[1,1]=r(cov_12) 
        qui: corr `1' `x2', covariance   
        matrix Q[2,1]=r(cov_12) 
        matrix Q[1,1]=(Q[1,1]*P[2,1]-Q[2,1]*P[1,1])*Q[2,1]                       
        if length("`ncorr'")!=0{
            matrix Q[2,1]=(-1)*Q[2,1]
        }
        
        
        if Q[1,1]<0{
            if Q[2,1]<0{
                local lower `lower' `liv'
                local upper `upper' `uiv_v'
            }
            else {
                local lower `lower' `liv_v'
                local upper `upper' `uiv'
            }
        }
        else{
            if Q[2,1]>0{  
                local  upper `upper' `uiv' `uiv_v' 
            }
            else {
                local lower `lower' `liv' `liv_v'    
            }
        }
    }
    macro shift
    local i=`i'+1    
}





if `kIV'>1 &  length("`prop5'")!=0 {
    tokenize `varlist_iv' 
    tempvar omega
    gen `omega'=0.5*`1'-0.5*`2' 
    
   
    if `kEx'==0{
        qui: ivregress 2sls `yvar'  (`varlist2'= `omega') `rops'
    }
    else{
        qui: ivregress 2sls `yvar' `varlist1' (`varlist2'= `omega') `rops'
    }
    
    local DFM = e(N)-e(rank)
    local liv_omega = _b[`varlist2']-invttail(`DFM',`ci')*_se[`varlist2']
    local uiv_omega = _b[`varlist2']+invttail(`DFM',`ci')*_se[`varlist2']
    
    local num_lo : word count `lower'
    local num_up : word count `upper'
    matrix G = J(1,1,0)
    if `num_lo'==0  {
        local lower `liv_omega'
        matrix G[1,1]=-1    
    }
    if `num_up'==0 {
        local upper `uiv_omega'
        matrix G[1,1]=1
    }
    
    if length("`noassumption4'")==0{  
        matrix H = J(2,1,0)
        qui: sum `varlist2'
        matrix H[1,1]=r(sd)
        qui: sum `omega' 
        matrix H[2,1]=r(sd)
        tempvar omega_var
        gen `omega_var'=H[1,1]*`omega'-H[2,1]*`varlist2'
        if `kEx'==0{
            qui: ivregress 2sls `yvar'  (`varlist2'=`omega_var') `rops'
        }
        else{
            qui: ivregress 2sls `yvar' `varlist1' (`varlist2'=`omega_var') `rops'
        }
                
        local DFM = e(N)-e(rank)
        local liv_omega_var = _b[`varlist2']-invttail(`DFM',`ci')*_se[`varlist2']
        local uiv_omega_var = _b[`varlist2']+invttail(`DFM',`ci')*_se[`varlist2']
        
        if G[1,1]==-1  {
            local upper `upper' `uiv_omega_var'
        }
        
        if G[1,1]==1 {
            local lower `lower' `liv_omega_var'
        }        
    }

}

*-------------------------------------------------------------------------------
*-- (3) Find bounds on endogenous variable
*-------------------------------------------------------------------------------
local num_lo : word count `lower'
local num_up : word count `upper'

if `num_lo'>1{
    local final_lower
    tokenize `lower'
    local i=1
    while `i'<`num_lo'{
        if `1'<`2'{
            local final_lower=`2'
        }
        else{
            local final_lower=`1'
        }
        macro shift
        local i=`i'+1
    }
}
else{
    local final_lower `lower'
}

if `num_up'>1{
    local final_upper
    tokenize `upper'
    local i=1
    while `i'<`num_up'{
        if `1'>`2'{
            local final_upper=`2'
        }
        else{
            local final_upper=`1'
        }
        macro shift
        local i=`i'+1
    }
}
else{
    local final_upper `upper'
}

*-------------------------------------------------------------------------------
*-- (4) Find bounds on exogenous parameters
*-------------------------------------------------------------------------------
if `kEx'!=0{
    matrix w_bounds = J(`kEx'+1,2,.)
    
    if length("`final_lower'")!=0{
        matrix w_bounds[1,1]=`final_lower'  
        tempvar y2
        gen `y2'= `yvar' -`final_lower'*`varlist2'
        qui: reg `y2' `varlist1' `rops'
        local i=2
        tokenize 
        foreach var of varlist `varlist1' {
            matrix w_bounds[`i',1]= _b[`var']-invttail(e(df_r),`ci')*_se[`var']
            local ++i
        }        
    }
    if length("`final_upper'")!=0{
        matrix w_bounds[1,2]=`final_upper'
        tempvar y2
        gen `y2'= `yvar' -`final_upper'*`varlist2'
        qui: reg `y2' `varlist1' `rops'
        local i=2
        foreach var of varlist `varlist1' {
            matrix w_bounds[`i',2]=_b[`var']+invttail(e(df_r),`ci')*_se[`var']
            local ++i
        }        
    }
}
if `kEx'==0{
    matrix w_bounds = J(1,2,.)
    if length("`final_lower'")!=0 matrix w_bounds[1,1]=`final_lower'
    if length("`final_upper'")!=0 matrix w_bounds[1,2]=`final_upper'
}
*-------------------------------------------------------------------------------
*-- (5) Return
*-------------------------------------------------------------------------------
matrix colnames w_bounds = LB UB
matrix rowname  w_bounds = `varlist2' `varlist1'

dis _newline
dis "Nevo and Rosen (2012)'s Imperfect IV bounds" _col(55) "Number of obs =    " e(N)
dis in yellow in smcl "{hline 78}"
dis "Variable" _col(20) "Lower Bound" _col(34) "Upper Bound"
dis in yellow in smcl "{hline 78}"

if length("`short'")==0 {
local list `varlist2' `varlist1'
}
else{
local list `varlist2' 
}



if length("`final_lower'")==0 {
    local jj=1
    foreach var of varlist `list'{
        local eUB = string(w_bounds[`jj',2], "%09.6f")
        dis in green "`var' " _col(20) "-----" _col(34) `eUB'
        local ++jj
    }
    dis in yellow in smcl "{hline 78}"
    dis "Note: One sided bounds only are returned."
    dis "Refer to Nevo and Rosen (2012) for situations in which two-sided bounds are possible."
    ereturn scalar ub_`varlist2'=`final_upper'
}
else if length("`final_upper'")==0 {
    local jj=1
    foreach var of varlist `list' {
        local eLB = string(w_bounds[`jj',1], "%09.6f")
        dis in green "`var' " _col(20) `eLB' _col(34) "-----"
        local ++jj
    }
    dis in yellow in smcl "{hline 78}"
    dis "Note: One sided bounds only are returned."
    dis "Refer to Nevo and Rosen (2012) for situations in which two-sided bounds are possible."
    ereturn scalar lb_`varlist2'=`final_lower'
}
else {
    local jj=1
    foreach var of varlist `list' {
        local eLB = string(w_bounds[`jj',1], "%09.6f")
        local eUB = string(w_bounds[`jj',2], "%09.6f")
        dis in green "`var' " _col(20) `eLB' _col(34) `eUB'
        local ++jj
    }
    dis in yellow in smcl "{hline 78}"
    ereturn scalar lb_`varlist2'=`final_lower'
    ereturn scalar ub_`varlist2'=`final_upper'
}
ereturn matrix LRbounds w_bounds

end
