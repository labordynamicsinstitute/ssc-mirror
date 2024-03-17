*! version 1.0.2 Louis Chauvel, march 2024
*! Thanks to Philippe Van Kerm for reviewing, corrections and suggestions
*! isogini prog 
program define isogini , rclass  
version 13
syntax varname(numeric) [aweight fweight pweight iweight] [if] [in]  ,  [rep(real 1)]
 marksample touse  
tempvar   wi i j n md tig10 tig90 tig50  tig25 tig75  nnn tsigma tpi
tempname A B ig10 ig90 ig50  ig25 ig75 sdig10 sdig90 sdig50 sdig25 sdig75 sigma sdsigma pi sdpi 
qui{
preserve
keep if `touse' 
if "`weight'" == "" gen byte `wi' = 1
else gen `wi' `exp'
gen `i'=_n
gen `n'=max(20,`rep')
expand `n'
bysort `i': gen `j'=_n
if (`rep'>20) { 
keep if uniform()<.5
}
forvalues jj=1/`rep' {
su `varlist' [w = `wi'] if `jj'==`j', de
replace `varlist' =`varlist' /r(p50) if `jj'==`j' 
} 
gen `md'= `varlist' >=.9 & `varlist'<1.1 
collapse (mean) `md'=`md' (p10) `tig10'=`varlist' (p90) `tig90'=`varlist'   (p25) `tig25'=`varlist'    (p75) `tig75'=`varlist'   [w = `wi'] , by(`j')
 su *
replace `tig10'=ln(`tig10')/logit(.1)  
replace `tig90'=ln(`tig90')/logit(.9)  
replace `tig25'=ln(`tig25')/logit(.25)  
replace `tig75'=ln(`tig75')/logit(.75)  
gen `tig50'=.25*(.2/`md')
gen `tsigma'=(`tig90'-`tig10')/(2*logit(.9))
gen `tpi'=`tig50'-.5*(`tig90'+`tig10')

su `tig10'
local ig10=r(mean) 
local sdig10=r(sd)
su `tig25'
local ig25=r(mean) 
local sdig25=r(sd)
su `tig75'
local ig75=r(mean) 
local sdig75=r(sd)
su `tig90'
local ig90=r(mean) 
local sdig90=r(sd) 
su `tig50'
local ig50=r(mean) 
local sdig50=r(sd) 
su `tsigma'
local sigma=r(mean) 
local sdsigma=r(sd) 
su `tpi'
local pi=r(mean) 
local sdpi=r(sd) 


return scalar ig10=`ig10'
return scalar sdig10=`sdig10'
return scalar ig25=`ig25'
return scalar sdig25=`sdig25'
return scalar ig50=`ig50'
return scalar sdig50=`sdig50'
return scalar ig75=`ig75'
return scalar sdig75=`sdig75'
return scalar ig90=`ig90'
return scalar sdig90=`sdig90'
return scalar sigma=`sigma'
return scalar sdsigma=`sdsigma'
return scalar pi=`pi'
return scalar sdpi=`sdpi'


restore
}
 end
 
