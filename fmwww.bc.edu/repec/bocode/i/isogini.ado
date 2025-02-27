*! version 1.0.4 Louis Chauvel, Feb 2025
*! version 1.0.3 Louis Chauvel, Nov 2024
*! version 1.0.2 Louis Chauvel, mar 2024
*! Thanks to Philippe Van Kerm for review, corrections and suggestions
*! isogini prog 
program define isogini , rclass  
version 13
syntax varname(numeric) [aweight fweight pweight iweight] [if] [in]  ,  [REP(real 2)]  [GR(real 0)]  [Saving(string)]  
 marksample touse  
tempvar   wi iii j n md  tig01 tig05 tig10 tig99 tig95 tig90 tig50  tig25 tig75  nnn tmu tsigma tpi
tempname A B ig10 ig90 ig50  ig25 ig75 sdig10 sdig90 sdig50 sdig25 sdig75 mu sdmu sigma sdsigma pi sdpi tig tsdig iso sdiso trep
qui{
preserve
keep if `touse' 
if "`weight'" == "" gen byte `wi' = 1
else gen `wi' `exp'
gen `iii'=_n
local trep=`rep'
if (`trep' <2) {
local trep =2 
}
noi di "AAAA=" `trep'
gen `n'=max(2,`trep')
expand `n'
bysort `iii': gen `j'=_n
if (`trep'>=1) { 
keep if uniform()<.5
}
forvalues jj=1/`trep' {
if (int(`jj'/10)==`jj'/10) noi di "`jj'" "/" "`trep'"
su `varlist' [w = `wi'] if `jj'==`j', de
replace `varlist' =`varlist' /r(p50) if `jj'==`j' 
} 
gen `md'= `varlist' >=.9 & `varlist'<1.1 
collapse (mean) `md'=`md' (p1) `tig01'=`varlist' (p5) `tig05'=`varlist' (p10) `tig10'=`varlist'  ///
 (p25) `tig25'=`varlist'    (p75) `tig75'=`varlist' (p90) `tig90'=`varlist' (p95) `tig95'=`varlist' (p99) `tig99'=`varlist'   [w = `wi'] , by(`j')
 su *
replace `tig01'=ln(`tig01')/logit(.01)  
replace `tig05'=ln(`tig05')/logit(.05)  
replace `tig10'=ln(`tig10')/logit(.1)  
replace `tig25'=ln(`tig25')/logit(.25)  
replace `tig75'=ln(`tig75')/logit(.75)  
replace `tig90'=ln(`tig90')/logit(.9)  
replace `tig95'=ln(`tig95')/logit(.95)  
replace `tig99'=ln(`tig99')/logit(.99)  
gen `tig50'=.25*(.2/`md')
gen `tmu'=(`tig90'+`tig75'+`tig25'+`tig10')/(4)
gen `tsigma'=(2*`tig90'+`tig75'-`tig25'-2*`tig10')/(6)
gen `tpi'=`tig50'-`tmu'
su `tig01'
local ig01=r(mean) 
local sdig01=r(sd)
su `tig05'
local ig05=r(mean) 
local sdig05=r(sd)
su `tig10'
local ig10=r(mean) 
local sdig10=r(sd)
su `tig25'
local ig25=r(mean) 
local sdig25=r(sd)
su `tig50'
local ig50=r(mean) 
local sdig50=r(sd) 
su `tig75'
local ig75=r(mean) 
local sdig75=r(sd)
su `tig90'
local ig90=r(mean) 
local sdig90=r(sd) 
su `tig95'
local ig95=r(mean) 
local sdig95=r(sd) 
su `tig99'
local ig99=r(mean) 
local sdig99=r(sd) 
su `tmu'
local mu=r(mean) 
local sdmu=r(sd) 
su `tsigma'
local sigma=r(mean) 
local sdsigma=r(sd) 
su `tpi'
local pi=r(mean) 
local sdpi=r(sd) 
*local ig50=(`ig25'+`ig75')/2 
*local sdig50=(`sdig25'+`sdig75')/2 

*sd variables should be missing values if rep<2
if (`trep'<=2) { 
local sdig01=.
local sdig05=.
local sdig10=.
local sdig25=.
local sdig50=. 
local sdig75=.
local sdig90=. 
local sdig95=. 
local sdig99=. 
local sdmu=. 
local sdsigma=. 
local sdpi=. 
}


mat def iso=r(iso)
mat `iso' = J(9,5,.)
mat `iso'[1,1]=1
mat `iso'[2,1]=5
mat `iso'[3,1]=10
mat `iso'[4,1]=25
mat `iso'[5,1]=50
mat `iso'[6,1]=75
mat `iso'[7,1]=90
mat `iso'[8,1]=95
mat `iso'[9,1]=99
mat `iso'[1,2]=`ig01'
mat `iso'[2,2]=`ig05'
mat `iso'[3,2]=`ig10'
mat `iso'[4,2]=`ig25'
mat `iso'[5,2]=`ig50'
mat `iso'[6,2]=`ig75'
mat `iso'[7,2]=`ig90'
mat `iso'[8,2]=`ig95'
mat `iso'[9,2]=`ig99'
mat `iso'[1,3]=`ig01'-2*`sdig01'
mat `iso'[2,3]=`ig05'-2*`sdig05'
mat `iso'[3,3]=`ig10'-2*`sdig10''
mat `iso'[4,3]=`ig25'-2*`sdig25'
mat `iso'[5,3]=`ig50'-2*`sdig50'
mat `iso'[6,3]=`ig75'-2*`sdig75'
mat `iso'[7,3]=`ig90'-2*`sdig90'
mat `iso'[8,3]=`ig95'-2*`sdig95'
mat `iso'[9,3]=`ig99'-2*`sdig99'
 
mat `iso'[1,4]=`ig01'+2*`sdig01'
mat `iso'[2,4]=`ig05'+2*`sdig05'
mat `iso'[3,4]=`ig10'+2*`sdig10''
mat `iso'[4,4]=`ig25'+2*`sdig25'
mat `iso'[5,4]=`ig50'+2*`sdig50'
mat `iso'[6,4]=`ig75'+2*`sdig75'
mat `iso'[7,4]=`ig90'+2*`sdig90'
mat `iso'[8,4]=`ig95'+2*`sdig95'
mat `iso'[9,4]=`ig99'+2*`sdig99'
mat `iso'[1,5]=logit(.01)
mat `iso'[2,5]=logit(.05)
mat `iso'[3,5]=logit(.10)
mat `iso'[4,5]=logit(.25)
mat `iso'[5,5]=logit(.50)
mat `iso'[6,5]=logit(.75)
mat `iso'[7,5]=logit(.90)
mat `iso'[8,5]=logit(.95)
mat `iso'[9,5]=logit(.99)
 
matrix colnames `iso' = "p" "ISO" "Lower bound" "Upper bound" "X"
*noi matlist `iso',  left(20) names(c) title("iso for `varlist'") tind(20) bor(all) aligncolnames(c) for(%12.0g)
svmat `iso' 
rename `iso'* iso*
noi mat li `iso' 
rename iso5 X
if (`gr'!=0) {  
noi two (rarea iso3 iso4 X, color(blue%50)) (li iso2 X, color(blue)) if X>-3, legend(off) saving(`saving', replace)
}
return matrix iso=`iso'

noi di "mu    = " `mu' "  +/- " 2*`sdmu'
noi di "sigma = " `sigma'  "  +/- " 2*`sdsigma'
noi di "pi    = " `pi' "  +/- " 2*`sdpi'
 
return scalar iso01=`ig01'
return scalar sdig01=`sdig01'
return scalar iso05=`ig05'
return scalar sdig05=`sdig05'
return scalar iso10=`ig10'
return scalar sdig10=`sdig10'
return scalar iso25=`ig25'
return scalar sdig25=`sdig25'
return scalar iso50=`ig50'
return scalar sdig50=`sdig50'
return scalar iso75=`ig75'
return scalar sdig75=`sdig75'
return scalar iso90=`ig90'
return scalar sdig90=`sdig90'
return scalar iso95=`ig95'
return scalar sdig95=`sdig95'
return scalar iso99=`ig99'
return scalar sdig99=`sdig99'
return scalar mu=`mu'
return scalar sdmu=`sdmu'
return scalar sigma=`sigma'
return scalar sdsigma=`sdsigma'
return scalar pi=`pi'
return scalar sdpi=`sdpi'
restore
}

 end
 