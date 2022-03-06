***************************************************
* ameta - Alternative and Bayesian Meta-analysis *
***************************************************

*! version 1.0  10march2021
*! by Kalliopi K. Exarchou-Kouveli, Eleni Nikolaidou, Panagiota I. Kontou and Pantelis G. Bagos


program define ameta , rclass
version 10.0
	syntax varlist(min=2 max=3 numeric) [if] [in], method(string) [study(string)]  [, a(real 0) b(real 2) l(real 95)] [by(string)] [graph] [eform] 
	

**** Alternative meta-analysis *********************

if ("`method'" == "dl") | ("`method'" == "dl2") | ("`method'" == "hm") | ("`method'" == "he") | ("`method'" == "sj") | ("`method'" == "sj2") | ("`method'" == "ca2") | ("`method'" == "pm") {

set more off
parse "`varlist'", parse(" ")

if "`if'"~="" {
preserve
quietly keep `if'
}

local dl 0
local dl2 0
local hm 0
local he 0
local sj 0
local sj2 0
local ca2 0
local pm 0


if "`method'" == "dl" {
	local dl=1
di in gr ""	
di in gr "Performing analysis using " in ye "DerSimonian-Laird" in gr " estimation method"  
	}

if "`method'" == "dl2" {
	local dl2=1
di in gr ""	
di in gr "Performing analysis using " in ye "Two-Step DerSimonian-Laird" in gr " estimation method"  
	}
	
if "`method'" == "hm" {
	local hm=1
di in gr ""	
di in gr "Performing analysis using " in ye "Hartung and Makambi" in gr " estimation method"  
	}
	
if "`method'" == "he" {
	local he=1
di in gr ""	
di in gr "Performing analysis using " in ye "Hedges" in gr " estimation method"  
	}	
	
if "`method'" == "sj" {
	local sj=1
di in gr ""	
di in gr "Performing analysis using " in ye "Sidik and Jonkman" in gr " estimation method"  
	}
	
if "`method'" == "sj2" {
	local sj2=1
di in gr ""	
di in gr "Performing analysis using " in ye "Sidik and Jonkman 2" in gr " estimation method"  
	}	
	
if "`method'" == "ca2" {
	local ca2=1
di in gr ""	
di in gr "Performing analysis using " in ye "Two-Step Cochran ANOVA" in gr " estimation method"  
	}
	
if "`method'" == "pm" {
	local pm=1
di in gr ""	
di in gr "Performing analysis using " in ye "Paule and Mandel" in gr " estimation method"  
	}	
	
	
	
qui summ `1' if `1'!=.   //summary statistics
local m=r(N)             //number of observations

//If the studies are more than one in the meta-analysis
if `m' >1 {
tempvar id
qui egen `id' = fill(1 2)
qui replace `id'=. if  `1'==. |`2'==. 
}


tempvar logrrsr sesr
qui gen `logrrsr'=`1'  //first argument the user types, Yi (effect size)
qui gen `sesr'=`2'     //second argument the user types, std. error of Yi


** For Subgroup Analysis 

tempvar by2 newby wei by_num max        
tempname k  

if("`by'"!=""){
cap confirm numeric var `by'
if _rc == 0{ 
	cap decode `by', gen(`by_num')
	if _rc != 0{
		local f: format `by'
		qui gen `by_num' = string(`by', "`f'")
	}
	qui drop `by'
	qui rename `by_num' `by'
}
}

qui count
local N = r(N)

qui gen `by2' = 1 in 1

local lab = `by'[1]
cap label drop bylab

if "`lab'" != ""{
	label define bylab 1 "`lab'"
}

local found1 "`lab'"
local max = 1

forvalues i = 2/`N'{

	local thisval = `by'[`i']
	local already = 0
	forvalues j = 1/`max'{
		if "`thisval'" == "`found`j''"{  
			local already = `j'
		}
	}
	if `already' > 0{
		qui replace `by2' = `already' in `i'
	}
	else{
		local max = `max' + 1
		qui replace `by2' = `max' in `i'
		local lab = `by'[`i']
		if "`lab'" != ""{
			label define bylab `max' "`lab'", modify
		}
		local found`max' "`lab'"
	}
}

label values `by2' bylab
sort `by2' `sortby' `id'

qui gen `newby'=(`by2'>`by2'[_n-1])
qui replace `newby'=1+sum(`newby')

local ngroups=`newby'[_N]


local j=0
local i=1
local x=0
local u=0
while `j'<=`ngroups'+1 & (`x'<= 2*`ngroups'+2) {
     if ("`by'"!="") {
     preserve	
     }

    qui count if (`newby'==`j')

	if("`by'"!="") & `j'<=`ngroups' & `j'>0 { 
    qui keep if (`newby'==`j') 
	} 
	scalar `k'=r(N)
	qui sum `1' if `newby'==`j' 
	
	

** DerSimonian-Laird estimator ---------------------------------

if `dl'==1{
 tempvar logorw sumwor sumw logorsf sesf sumwq q sumwsq d 

qui gen `logorw'=`1'/(`2')^2  //Yi*wi
qui egen `sumwor'=sum(`logorw')  //sum(Yi*wi)
qui egen `sumw'=sum(1/`2'^2)  //sum(wi) = S1
qui gen `logorsf'=`sumwor'/`sumw'  //m of fixed-effect model
qui gen `sesf'=1/`sumw'  // 1/sum(wi)
	
qui gen `sumwq'=((`logorsf' -`1')^2)/(`2'^2)  //Q without sum
qui egen `q'=sum(`sumwq')  //Q Cochrain's homogeneity test
qui egen `sumwsq'=sum(1/`2'^4)  //S2= sum(wi^2)


//t^2 of DerSimonian-Laird 
	
if ("`by'"=="")  | (`j'==`ngroups' +1) | (`j'==0) {
qui gen `d'= max(0, (`q'-`m'+1)/(`sumw' - (`sumwsq'/`sumw')))  //standard analysis
}	
else {
qui gen `d'= max(0, (`q'-`k'+1)/(`sumw' - (`sumwsq'/`sumw')))  //subgroup analysis
}
}


** Two-step DerSimonian-Laird estimator ----------------------------

if `dl2'==1{
 tempvar logorw sumwor sumw logorsf sesf sumwq qr sumwsq dr weirp logorwrp sumworrp sumwrp sesrrp logorsrp q d sumwqr lo sumlo ks sumks sumwrt 

qui gen `logorw'=`1'/(`2')^2  //Yi*wi
qui egen `sumwor'=sum(`logorw')  //sum(Yi*wi)
qui egen `sumw'=sum(1/`2'^2)  //sum(wi)= S1
qui gen `logorsf'=`sumwor'/`sumw'  //m of fixed-effect model
qui gen `sesf'=1/`sumw'  // 1/sum(wi)
	
qui gen `sumwq'=((`logorsf' -`1')^2)/(`2'^2)  //Q without sum
qui egen `q'=sum(`sumwq')  //Q Cochrain's homogeneity test
qui egen `sumwsq'=sum(1/`2'^4)  //S2= sum(wi^2)


//t^2 of DerSimonian-Laird
	
if("`by'"=="") | (`j'==`ngroups' +1) | (`j'==0) {
qui gen `dr'= max(0, (`q'-`m'+1)/(`sumw' - (`sumwsq'/`sumw')))  //standard analysis
}	
else {
qui gen `dr'= max(0, (`q'-`k'+1)/(`sumw' - (`sumwsq'/`sumw')))  //subgroup analysis
}
	

//DerSimonian-Laird 2 

qui gen `weirp'=1/(`dr'+(`2'^2))  // new wi
qui gen `logorwrp'=`1'*`weirp'  // Yi*wi
qui egen `sumworrp'=sum(`logorwrp')  //sum(Yi*wi)
qui egen `sumwrp'=sum(`weirp')  //sum(wi)
qui gen `sesrrp'=1/`sumwrp'  // 1/sum(wi)
	
qui gen `logorsrp' =`sumworrp'/`sumwrp'  //new mw - pooled m of DL

qui gen `sumwqr'=((`logorsrp' -`1')^2)*`weirp'  //((Yi-mw)^2)*wi
qui egen `qr'=sum(`sumwqr')  //first part of max
qui gen `lo'=`weirp'*(`2'^2)  //(si^2)*wi
qui egen `sumlo'=sum(`lo')  //beginning of second part of max
qui gen `ks'=(`weirp'^2)*(`2'^2)  //(si^2)*(wi^2)
qui egen `sumks'=sum(`ks')  //third part(1) of max
qui egen `sumwrt'=sum(`weirp'^2)  //sum(wi^2)


//t^2 of DerSimonian-Laird 2 

qui gen `d'= max(0, (`qr'- (`sumlo'- `sumks'/`sumwrp'))/(`sumwrp' - (`sumwrt'/`sumwrp')))   
}


** Hartung and Makambi estimator -------------------------------

if `hm'==1{
 tempvar logorw sumwor sumw logorsf sesf sumwq q sumwsq d 

qui gen `logorw'=`1'/(`2')^2  //Yi*wi
qui egen `sumwor'=sum(`logorw')  //sum(Yi*wi)
qui egen `sumw'=sum(1/`2'^2)  //sum(wi)= S1
qui gen `logorsf'=`sumwor'/`sumw'  //m of fixed-effect model
qui gen `sesf'=1/`sumw'  // 1/sum(wi)
	
qui gen `sumwq'=((`logorsf' -`1')^2)/(`2'^2)  //Q without sum
qui egen `q'=sum(`sumwq')  //Q Cochrain's homogeneity test
qui egen `sumwsq'=sum(1/`2'^4)  //S2= sum(wi^2)


//t^2 of Hartung and Makambi 

if("`by'"=="") | (`j'==`ngroups' +1) | (`j'==0) {
qui gen `d'= max(0,`q'^2/((2*(`m'-1)+`q')*(`sumw' - (`sumwsq'/`sumw'))))  //since it is always positive & standard analysis
}	
else {
qui gen `d'= max(0,`q'^2/((2*(`k'-1)+`q')*(`sumw' - (`sumwsq'/`sumw'))))  //since it is always positive & subgroup analysis
}
}


** Hedges aka Cochran ANOVA aka variance component estimator -------------------------------

if `he'==1{
 tempvar sm mm kl kll op opp d logorw sumwor sumw logorsf sumwq q

qui egen `sm'=sum(`1')  //sum(Yi)
if("`by'"=="") | (`j'==`ngroups' +1) | (`j'==0) {
qui gen `mm'=`sm'/`m'  //sum(Yi/n) & standard analysis
}
else {
qui gen `mm'=`sm'/`k'  //sum(Yi/n) & subgroup analysis
}
qui gen `kl'=(`1'-`mm')^2  //(Yi-muw)^2
qui egen `kll'=sum(`kl')  //sum(Yi-muw^2)
qui gen `op'=`2'^2  //si^2
qui egen `opp'=sum(`op')  //sum(si^2)

qui gen `logorw'=`1'/(`2')^2  //Yi*wi
qui egen `sumwor'=sum(`logorw')  //sum(Yi*wi)
qui egen `sumw'=sum(1/`2'^2)  //sum(wi)
qui gen `logorsf'=`sumwor'/`sumw'  //m of fixed-effect model
qui gen `sumwq'=((`logorsf' -`1')^2)/(`2'^2)  //Q without sum
qui egen `q'=sum(`sumwq')  //Q Cochrain's homogeneity test


//t^2 of Hedges

if("`by'"=="") | (`j'==`ngroups' +1) | (`j'==0)  {
qui gen `d'= max(0,(`kll'/(`m'-1)) - (`opp'/`m'))  //since we want him non-negative & standard analysis
}
else {
qui gen `d'= max(0,(`kll'/(`k'-1)) - (`opp'/`k'))  //since we want him non-megative & subgroup analysis
}
}


** Sidik and Jonkman estimator -------------------------------------

if `sj'==1{
 tempvar sm mm kl kll dr d vv sumwqr qr weirr logorwrr sumworrs sumwrr logorsrs logorw sumwor sumw logorsf sumwq q

qui egen `sm'=sum(`1')  //sum(Yi)
if("`by'"=="") | (`j'==`ngroups' +1) | (`j'==0) {
qui gen `mm'=`sm'/`m'  //sum(Yi/n) & standard analysis
}
else {
qui gen `mm'=`sm'/`k'  //sum(Yi/n) & subgroup analysis
}
qui gen `kl'=(`1'-`mm')^2  //(Yi-muw)^2
qui egen `kll'=sum(`kl')  //sum(Yi-muw^2)


//initial to^2 of Sidik and Jonkman

if("`by'"=="") | (`j'==`ngroups' +1) | (`j'==0) {
qui gen `dr'= max(0, (1/`m')*`kll')  //standard analysis
}
else {
qui gen `dr'= max(0, (1/`k')*`kll')  //subgroup analysis
}


//Sidik and Jonkman

qui gen `weirr'=1/(((`2'^2)/`dr') +1)  //wi with initial to^2 
qui gen `logorwrr'=`1'*`weirr'  //Yi*wi
qui egen `sumworrs'=sum(`logorwrr')  //sum(Yi*wi)
qui egen `sumwrr'=sum(`weirr')  //sum(wi)
	
qui gen `logorsrs'=`sumworrs'/`sumwrr'  //m with initial to^2
qui gen `vv'=((`2'^2)/`dr') +1  //vi

qui gen `sumwqr'=((`logorsrs' -`1')^2)*(1/`vv')  //numerator of t^2 of sj without sum
qui egen `qr'=sum(`sumwqr')  //numerator of t^2 with sum

qui gen `logorw'=`1'/(`2')^2  //Yi*wi
qui egen `sumwor'=sum(`logorw')  //sum(Yi*wi)
qui egen `sumw'=sum(1/`2'^2)  //sum(wi)
qui gen `logorsf'=`sumwor'/`sumw'  //m of fixed-effect model
qui gen `sumwq'=((`logorsf' -`1')^2)/(`2'^2)  //Q without sum
qui egen `q'=sum(`sumwq')  //Q Cochrain's homogeneity test


//t^2 of Sidik and Jonkman

if("`by'"=="") | (`j'==`ngroups' +1) | (`j'==0) {
qui gen `d'= max(0,`qr'/(`m'-1))  //since it is positive & standard analysis
}
else {
qui gen `d'= max(0,`qr'/(`k'-1))  //since it is positive & subgroup analysis
}
}


** Sidik and Jonkman 2 estimator -------------------------------------

if `sj2'==1{
 tempvar sm mm kl kll op opp dr d vv sumwqr qr weirr logorwrr sumworrs sumwrr logorsrs logorw sumwor sumw logorsf sumwq q

qui egen `sm'=sum(`1')  //sum(Yi)
if("`by'"=="") | (`j'==`ngroups' +1) | (`j'==0) {
qui gen `mm'=`sm'/`m'  //sum(Yi/n) & standard analysis
}
else {
qui gen `mm'=`sm'/`k'  //sum(Yi/n) & subgroup analysis
}
qui gen `kl'=(`1'-`mm')^2  //(Yi-muw)^2
qui egen `kll'=sum(`kl')  //sum(Yi-muw^2)
qui gen `op'=`2'^2  //si^2
qui egen `opp'=sum(`op')  //sum(si^2)


//to^2 of Cochran ANOVA

if("`by'"=="") | (`j'==`ngroups' +1) | (`j'==0) {
qui gen `dr'= max(0, (1/(`m'-1))*`kll' - ((1/`m')*`opp'))  //standard analysis
}
else {
qui gen `dr'= max(0, (1/(`k'-1))*`kll' - ((1/`k')*`opp'))  //subgroup analysis
}


//Sidik and Jonkman 2

if `dr'==0 {
qui replace `dr'=0.01  
}

qui gen `weirr'=1/(((`2'^2)/`dr') +1)  //wi with Cochran ANOVA 
qui gen `logorwrr'=`1'*`weirr'  //Yi*wi
qui egen `sumworrs'=sum(`logorwrr')  //sum(Yi*wi)
qui egen `sumwrr'=sum(`weirr')  //sum(wi)
	
qui gen `logorsrs'=`sumworrs'/`sumwrr'  //m with Cochran ANOVA
qui gen `vv'=((`2'^2)/`dr') +1  //vi

qui gen `sumwqr'=((`logorsrs' -`1')^2)*(1/`vv')  //numerator of t^2 of sj without sum
qui egen `qr'=sum(`sumwqr')  //numerator of t^2 with sum

qui gen `logorw'=`1'/(`2')^2  //Yi*wi
qui egen `sumwor'=sum(`logorw')  //sum(Yi*wi)
qui egen `sumw'=sum(1/`2'^2)  //sum(wi)
qui gen `logorsf'=`sumwor'/`sumw'  //m of fixed-effect model
qui gen `sumwq'=((`logorsf' -`1')^2)/(`2'^2)  //Q without sum
qui egen `q'=sum(`sumwq')  //Q Cochrain's homogeneity test


//t^2 of Sidik and Jonkman 2

if("`by'"=="") | (`j'==`ngroups' +1) | (`j'==0) {
qui gen `d'= max(0,`qr'/(`m'-1))  //since it is positive & standard analysis
}
else {
qui gen `d'= max(0,`qr'/(`k'-1))  //since it is positive & subgroup analysis
}
}


** Two-step Cochran ANOVA estimator ------------------------------------

if `ca2'==1{
 tempvar sm mm kl kll op opp dr weirp logorwrp sumworrp sumwrp sesrrp logorsrp sumwqr qr lo sumlo ks sumks sumwrt d logorw sumwor sumw logorsf sumwq q

qui egen `sm'=sum(`1')  //sum(Yi)
if("`by'"=="") | (`j'==`ngroups' +1) | (`j'==0) {
qui gen `mm'=`sm'/`m'  //sum(Yi/n) &  standard analysis
}
else {
qui gen `mm'=`sm'/`k'  //sum(Yi/n) & subgroup analysis
}
qui gen `kl'=(`1'-`mm')^2  //(Yi-Ya)^2
qui egen `kll'=sum(`kl')  //sum((Yi-Ya)^2)
qui gen `op'=`2'^2  //si^2
qui egen `opp'=sum(`op')  //sum(si^2)


//t^2 of Cochran ANOVA 

if("`by'"=="") | (`j'==`ngroups' +1) | (`j'==0) {
qui gen `dr'= max(0, (1/(`m'-1))*`kll' - ((1/`m')*`opp'))  //standard analysis
	}
else {
qui gen `dr'= max(0, (1/(`k'-1))*`kll' - ((1/`k')*`opp'))  //subgroup analysis
}
	

//Cochran ANOVA 2 	
	
qui gen `weirp'=1/(`dr'+`2'^2)  //new wi
qui gen `logorwrp'=`1'*`weirp'  //Yi*wi
qui egen `sumworrp'=sum(`logorwrp')  //sum(Yi*wi)
qui egen `sumwrp'=sum(`weirp')  //sum(wi)
qui gen `sesrrp'=1/`sumwrp'  // 1/sum(wi)
	
qui gen `logorsrp' =`sumworrp'/`sumwrp'  //new m - pooled of Cochran ANOVA

qui gen `sumwqr'=((`logorsrp' -`1')^2)*`weirp'  //((Yi-mw)^2)*wi
qui egen `qr'=sum(`sumwqr')  //first part of max
qui gen `lo'=`weirp'*(`2'^2)  //wi*(si^2)
qui egen `sumlo'=sum(`lo')  //beginning of second part of max
qui gen `ks'=(`weirp'^2)*(`2'^2)  //(wi^2)*(si^2)
qui egen `sumks'=sum(`ks')  //third part(1) of max
qui egen `sumwrt'=sum(`weirp'^2)  //sum(weir^2)

qui gen `logorw'=`1'/(`2')^2  //Yi*wi
qui egen `sumwor'=sum(`logorw')  //sum(Yi*wi)
qui egen `sumw'=sum(1/`2'^2)  //sum(wi)
qui gen `logorsf'=`sumwor'/`sumw'  //m of fixed-effect model
qui gen `sumwq'=((`logorsf' -`1')^2)/(`2'^2)  //Q without sum
qui egen `q'=sum(`sumwq')  //Q Cochrain's homogeneity test


//t^2 of Cochran ANOVA 2  

qui gen `d'= max(0, (`qr'- (`sumlo'- `sumks'/`sumwrp'))/(`sumwrp' - (`sumwrt'/`sumwrp')))   
}


** Paule and Mandel aka empirical Bayes estimator ---------------------------------------

if `pm'==1{
 tempvar tp ftt ww kj kjj yw hu huu kh khh d dt logorw sumwor sumw logorsf sumwq q

qui gen `tp'= 0     //t^2(previous) initial
qui gen `ftt'= 0.1  //F(t^2)
qui gen `ww'= 0
qui gen `yw'= 0
qui gen `hu'= 0
qui gen `kh'= 0
qui gen `dt'= 0
qui gen `d'= 0

while `ftt' > 0 {  //or !=

if `tp' <0 {
qui replace `tp'=0 
}

qui replace `ww'=1/(`tp'+(`2')^2)  //first weight with tp=0
qui egen `kj'=sum(`ww'*`1')  //sum(Yi*wi)
qui egen `kjj'=sum(`ww')  //sum(wi)
qui replace `yw'=`kj'/`kjj'  //yw

qui replace `hu'=`ww'*((`1'-`yw')^2) 
qui egen `huu'=sum(`hu') //numerator of dt^2 without k-1

qui replace `kh'=(`ww'^2)*((`1'-`yw')^2)
qui egen `khh'=sum(`kh')  //denominator of dt^2

//F(t^2)
if("`by'"=="") | (`j'==`ngroups' +1) | (`j'==0) {
qui replace `ftt'=`huu'-(`m'-1)  //standard analysis
	}
else {
qui replace `ftt'=`huu'-(`k'-1)  //subgroup analysis
}	

	
//t^2 of Paule and Mandel
	
if `ftt'<0 & `tp'==0 {
qui replace `d'=0 
}
else if `ftt'<0 & `tp'>0 {  
qui replace `d'=`tp' 
}
else if `ftt'==0 {
qui replace `d'=`tp'
}
else if `ftt'>0 {
qui replace `dt'=`ftt'/(`khh') 
qui replace `tp'=`tp'+`dt'
}

qui drop `kj'
qui drop `kjj'
qui drop `huu'
qui drop `khh'	
}

qui gen `logorw'=`1'/(`2')^2  //Yi*wi
qui egen `sumwor'=sum(`logorw')  //sum(Yi*wi)
qui egen `sumw'=sum(1/`2'^2)  //sum(wi)
qui gen `logorsf'=`sumwor'/`sumw'  //m of fixed-effect model
qui gen `sumwq'=((`logorsf' -`1')^2)/(`2'^2)  //Q without sum
qui egen `q'=sum(`sumwq')  //Q Cochrain's homogeneity test
}


//For one study, there is no need for meta-analysis. Tau-squared will be zero.
if `m' == 1 | `k'== 1 {
qui replace `d'= 0
}


tempvar weir logorwr sumworr sumwr sesrr logorsr ss de vf vr dd

** weighted mean and se  ---------------------
	
qui gen `weir'=1/(`d'+`2'^2)  //new wi of random-effects model
qui gen `logorwr'=`1'*`weir'  //Yi*wi
qui egen `sumworr'=sum(`logorwr')  //sum(Yi*wi)
qui egen `sumwr'=sum(`weir')  //sum(wi)
qui gen `sesrr'=1/`sumwr'  // 1/sum(wi)
	
qui gen `logorsr'=`sumworr'/`sumwr'  //new m of random-effects model
qui gen `ss'=sqrt(1/`sumwr')  //se of new m


** degree of heterogeneity I-square  -----------------
 
if("`by'"=="") | (`j'== `ngroups'+1) | (`j'==0) {
qui gen `de'= max(0, (`q'-`m'+1)/`q')  //standard analysis
	}
else {
qui gen `de'= max(0, (`q'-`k'+1)/`q')  //subgroup analysis
}
 
 
** percentage of heterogeneity D-square  -----------------------

qui gen `vf' = 1/`sumw'
qui gen `vr' = 1/`sumwr'
qui gen `dd'= 1-(`vf'/`vr')


** confidence intervals of pooled m  -------------------------

tempvar low1 up1

qui gen `low1'=`logorsr'-1.96*`ss'
qui gen `up1'=`logorsr'+1.96*`ss'

if "`eform'" ~= "" {
qui replace `low1'=exp(`logorsr'-1.96*`ss')
qui replace `up1'=exp(`logorsr'+1.96*`ss')
}


** confidence intervals of effect size (f.e. RR)  -------------------------

tempvar low2 up2

qui gen `low2'=`logrrsr'-1.96*`sesr'
qui gen `up2'=`logrrsr'+1.96*`sesr'

if "`eform'" ~= "" {
qui replace `low2'=exp(`logrrsr'-1.96*`sesr')
qui replace `up2'=exp(`logrrsr'+1.96*`sesr')
}


** p-value  ---------------------

local z=`logorsr'/`ss'  // (pooled m)/(std. error of pooled m)
local p=2*min(1-normprob(`z'), normprob(`z'))

 
** plot for standard analysis  ----------------------

if ("`by'"=="") {
local estt=`logorsr'

if "`eform'" ~= "" {
local estt=exp(`logorsr')
}

local loww=`low1'
local upp=`up1'


if "`eform'" == "" {
if "`graph'" != "" {
if "`study'" != "" {
metagraph `1' `2', id(`study') mscale(0.22) combined(`estt' `loww' `upp') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
else {
metagraph `1' `2', id(`id') mscale(0.22) combined(`estt' `loww' `upp') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
}
}

if "`eform'" ~= "" {
if "`graph'" != "" {
if "`study'" != "" {
metagraph `1' `2', id(`study') eform x(0.1 0.25 0.5 1 2 4 8 10) mscale(0.22) combined(`estt' `loww' `upp') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black)) 
}
else {
metagraph `1' `2', id(`id') eform x(0.1 0.25 0.5 1 2 4 8 10) mscale(0.22) combined(`estt' `loww' `upp') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
}
}

}


** results  ------------------------

if "`eform'" ~= "" {
qui replace `logrrsr'=exp(`logrrsr')
qui replace `logorsr'=exp(`logorsr')
qui replace `sesr'=exp(`sesr')
qui replace `ss'=exp(`ss')
}

//Standard analysis results

if ("`by'"=="") {
di _n in gr _col(14) "Study |" _col(24) "Eff. size" _col(37) /*
 */ "[$IND% Conf. Interval]     % Weight"  _n _dup(19) "-" "+" _dup(55) "-"
 
 forvalues i = 1/`m' {
if "`study'" != "" {
di in gr `study'[`i'] _col(20) in gr"|   " in ye %7.3f `logrrsr'[`i'] "     ", %7.3f `low2'[`i'] "  ", %7.3f `up2'[`i'], "     " %7.2f (`weir'[`i']/`sumwr')*100
}
else {
di in gr `id'[`i'] _col(20) in gr"|   " in ye %7.3f `logrrsr'[`i'] "     ", %7.3f `low2'[`i'] "  ", %7.3f `up2'[`i'], "     " %7.2f (`weir'[`i']/`sumwr')*100 
}
}
di in gr "-------------------+--------------------------------------------------------"
di in ye strupper(" `method' ") in gr "pooled ES" in gr _col(20) "|   "  in ye %7.3f `logorsr' "     ", %7.3f `low1' "  ", %7.3f `up1', "     " %7.2f (`sumwr'/`sumwr')*100  



di in gr "----------------------------------------------------------------------------"
di in gr "Number of studies: " in ye `m'                                                                          
di in gr "Cochran's homogeneity test: Q= " in ye %7.4f /* 
*/ `q' in gr " on " in ye (`m'-1) in gr " degrees of freedom (p= " in ye %4.3f chiprob(`m'-1,`q') in gr ")"
di in gr "Estimate of between-study variance " "Tau-squared=" in ye %7.4f `d'                                 
di in gr "Pooled intervention effect m= " in ye %7.4f `logorsr' in gr " and its standard error se=" in ye %7.4f `ss' 
di in gr "I-square=" in ye %7.4f `de' in gr "   D-square=" in ye %7.4f `dd' 
di in gr "95% Conf. Interval= [" in ye %7.4f `low1' , %7.4f `up1' in gr "]" 
di in gr "z= "  in ye %7.4f `z'  in gr  "   p-value="  in ye %7.4f `p'
}


//Subgroup analysis results

if ("`by'"~="") & (`x'<=`ngroups') {
if `j' ==1 {
di _n in gr _col(0) proper("`by'") " and Study" _col(20) "|" _col(24) "Eff. size" _col(37) /*
 */ "[$IND% Conf. Interval]      % Weight"  _n _dup(19) "-" "+" _dup(57) "-"
}

forvalues i = 1/`m' {
 if `newby'[`i']==`j' { 
 if `by'[`i'+1] ~= `by'[`i'] {
di in ye `by'[`i'] _col(20) in gr"|   "
 }
 }
}

if "`by'" ~= "" & (`j'== 0) {
qui gen `wei' = (`weir'/`sumwr')*100  //random-effects weights of the standard analysis
 forvalues i = 1/`m' {
 scalar w`i' = `wei'[`i'] 
 }
}

local sumsum = 0  //sum of the random-effects weights of the standard analysis
  
forvalues i = 1/`m' {
 if `newby'[`i']==`j' { 
 local u = `u'+1   
 
 if "`study'" != "" {
 di in gr `study'[`i'] _col(20) in gr"|   " in ye %7.3f `logrrsr'[`i'] "     ", %7.3f `low2'[`i'] "  ", %7.3f `up2'[`i'], "      " %7.2f w`u'
 }
 else {
 di in gr `id'[`i'] _col(20) in gr"|   " in ye %7.3f `logrrsr'[`i'] "     ", %7.3f `low2'[`i'] "  ", %7.3f `up2'[`i'], "      " %7.2f w`u' 
 }

local sumsum = `sumsum' + w`u'
 }
}


if "`by'" ~= "" & (`j'<= `ngroups') & (`x'<=`ngroups') & (`j'>0) {
di in gr _col(20) in gr"|   "
di in ye "Subgroup , " strupper("`method'") _col(20) in gr"|   "  in ye %7.3f `logorsr'  "     ", %7.3f `low1' "  ", %7.3f `up1' "       " %7.2f `sumsum' 
di in gr _dup(19) "-" "+" _dup(57) "-"
 }
}


 if "`by'" ~= "" & (`j'== `ngroups'+1) & (`x'==`ngroups'+1) {
di in ye "Overall , " strupper("`method'") _col(20) in gr"|   "  in ye %7.3f `logorsr'  "     ", %7.3f `low1' "  ", %7.3f `up1' "       " %7.2f (`sumwr'/`sumwr')*100 
di in gr "-----------------------------------------------------------------------------"
di in gr ""
}


if "`by'" ~= "" & (`j'<= `ngroups' & `x'>=`ngroups'+1 & `x'<= 2*`ngroups'+1) {
 if `j' ==1 {
 di in gr "Subgroup analysis measures:"
 }
di in gr `by' _col(13) in ye "          "in gr "z = "  in ye %7.4f `z' _col(39) in gr  "p = "  in ye %7.4f `p'
}
 
if "`by'" ~= "" & (`j'== `ngroups'+1) & (`x'==2*`ngroups'+2) {
di in gr "Overall" _col(13) in ye "          " in gr "z = "  in ye %7.4f `z' _col(39) in gr  "p = "  in ye %7.4f `p'
}
 
 
if "`by'" ~= "" & (`j'== `ngroups'+1) | "`by'" == "" {

return scalar pvalue = `p'
return scalar z = `z'
return scalar ConfIntervalUp = `up1'
return scalar ConfIntervalLow = `low1' 
return scalar Dsquare = `dd'
return scalar Isquare = `de'
return scalar se = `ss'
return scalar m = `logorsr'
return scalar Tausquared = `d'
return scalar Qtest = `q'
return scalar numberofstudies = `m' 
 
}
 
 
if ("`by'"!="") {
 if (`x'<=`ngroups') {
 local x = `x'+1
 local j=`j'+1
 restore  
 }
 else if (`x'>`ngroups' & `x'<= 2*`ngroups'+2) {
  if `x'==`ngroups'+1 {
  local j=0
  }
  local x = `x'+1
  local j=`j'+1
  restore
 }
}
else {
continue, break
restore
}
qui sort `id'
}
}


**** Bayesian meta-analysis *********************

else if ("`method'" == "abi") | ("`method'" == "metareg") | ("`method'" == "gllamm") {

set more off
tokenize `varlist', parse(" ")

if "`if'"~="" {
preserve
quietly keep `if'
}

local m1 0
local m2 0
local m3 0

tempvar _USE1 _USE2 _USE3
if("`method'"== "abi"){
qui gen `_USE1'=`1'  //first argument the user types, Yi (effect size)
qui gen `_USE2'=`2'
qui gen `_USE3'=`3'
	local m1=1
	di in ye " "
	di as text in ye _dup(60) "-"
	di in ye "	Approximate Bayesian Inference For Random 
	di in ye "		Effects meta - analysis
	di as text in ye _dup(60) "-"
	}
else if("`method'"== "gllamm"){
qui gen `_USE1'=`1'  //first argument the user types, Yi (effect size)
qui gen `_USE2'=`2'
	local m2=1
	di in ye " "
	di as text in ye _dup(60) "-"
	di in ye "	Bayesian meta-analysis using gllamm	"
	di as text in ye _dup(60) "-"
	}
else if("`method'"== "metareg"){
qui gen `_USE1'=`1'  //first argument the user types, Yi (effect size)
qui gen `_USE2'=`2'
	local m3=1
	di in ye " "
	di as text in ye _dup(60) "-"
	di in ye "	Bayesian meta-analysis using meta-regression "		
	di as text in ye _dup(60) "-"
}


if("`by'"==""){

if(`m1'==1){
tempvar s2 nom_sum yi2 dnom_sum lci uci lny  id plci puci em mn rss vm et2 c nvt2 b2 dvt2 vt2 t1 t2 f t nom1 nom k y2 sumy r denom1 denom  z numberofstudies ConfIntervalLow ConfIntervalUp

global IND `l'
if (`l' == 80){
	 scalar `z' = 1.282
	 }
else if (`l' ==85){
	 scalar `z' = 1.440
	 }
else if (`l' ==90){
	 scalar `z' = 1.645
	 }
else if (`l'==95){
	 scalar `z' = 1.960
	 }
else if (`l'==98){
	 scalar `z' = 2.33
	 }
else if (`l'==99){
	 scalar `z' = 2.576
	 }
else if (`l'==99.5){
	 scalar `z' = 2.807
	 }
else if (`l'==99.9){
	 scalar `z' = 3.291
	 }
else{
	di as err "Please choose one of the following confidence levels : 80% , 85% , 90% , 95% , 98% , 99% , 99.5% , 99.9%  "
	exit _rc
	}
	
scalar `k'= _N
if (`k'==1){
	local i=1
	qui gen `id'=_n
	
	if `_USE2'<=0{
	di as err "Varlist containing standard error should have only positive values" 
		exit 125
		}
	if `_USE3'<=0 {
		di as err "Varlist containing number of participants should have only positive values" 
		exit 125
		}
	} 
else if(`k'>1) {
qui egen `id' = fill(1 2)
qui replace `id'=. if  `_USE1'==. |`_USE2'==. 
qui levelsof `_USE2' , local(slev)
foreach i in `slev' {
	if `i'<=0 {
		di as err "Varlist containing standard error should have only positive values" 
		exit 125
		}
}
qui levelsof `_USE3' , local(nlev)
foreach i in `nlev' {
	if `i'<=0 {
		di as err "Varlist containing number of participants should have only positive values" 
		exit 125
		}
}
} 
	qui gen `lci' = `_USE1' - `z' * `_USE2'
	qui gen `uci' = `_USE1' + `z' * `_USE2'

if "`eform'" ~= "" {
qui replace `lci'=exp(`_USE1' - `z' * `_USE2')
qui replace `uci'=exp(`_USE1' + `z' * `_USE2')
}

di in ye "Inverse-Gamma Distribution parameters are a = " `a' " and b = " `b'
di in ye "The number of studies included in this meta-analysis is " `k'

qui sum `_USE1'
scalar `mn'=r(mean)

qui gen `yi2' = `_USE1'*`_USE1'
qui sum `yi2'
scalar `sumy' = r(sum)

scalar `y2' = `mn'*`mn'
scalar `rss' = `sumy' - `k'*`y2'

scalar `vm' = (2*(1 + `b'*`rss'/2))/(`b'*`k'*(2*`a' + `k' -3))
scalar `et2' = (2*(1 + `b'*`rss'/2))/(`b'*(2*`a' + `k' -3))

scalar `c' = (1 + `b'*`rss'/2)*(1 + `b'*`rss'/2)
scalar `nvt2' = 8*`c'

scalar `b2' = `b'*`b'
scalar `dvt2' = `b2'*((2*`a' + `k' - 3)*(2*`a' + `k' - 3))*(`k' + 2*`a' -5)

scalar `vt2' = `nvt2'/`dvt2'

//calculation of e(m)

quietly generate `s2' = `_USE2'*`_USE2'

//nominator
scalar `t1' = `b'*(`k' + 2*`a' -1)
scalar `t2' = 2*(1 + (`b'*`rss'/2))
scalar `f' = `t1'/`t2'

qui generate `nom_sum' = ((`_USE3'*`s2')/(`_USE3'-3))*(((`mn'*(`k'-3)+`_USE1')/`k')-(((`y2'*(`mn'-`_USE1')+(`mn'*`yi2'))*(`k'+(2*`a')+1)*`b')/(2*(1+`b'*`rss'/2))))
qui summarize `nom_sum' 
scalar `nom1' = r(sum)

scalar `nom' = `mn'-`f'*`nom1'

//denominator
qui gen `dnom_sum' = ((`_USE3'*`s2')/(`_USE3'-3))*(((`k'-1)/`k') - (((`mn'*(`mn'-`_USE1')+`yi2')*(`k'+2*`a'+1)*`b')/(2*(1+`b'*`rss'/2))))
qui summarize `dnom_sum'
scalar `denom1' =r(sum)
scalar `denom' = 1-`f'*`denom1'

scalar `em' = `nom'/`denom'

tempvar ss 
tempname plci puci
qui gen `ss' = sqrt(`vm')
scalar `plci' = `em' - `z'*`ss'
scalar `puci' = `em' + `z'*`ss'

if "`eform'" ~= "" {
scalar `plci'=exp(`plci')
scalar `puci'=exp(`puci')
}


**results  ------------------------  

if (`k'<=5 & `a'<=2){
di as err "If the studies included in the meta-analysis are less or equal to five and the shape parameter (a) of the inverse gamma distribution "
di as err "is less than or equal to two meta-analysis can not be completed, since these approximations are not suitable for meta-analyses with "
di as err "fewer than six studies in them.The value of the shape parameter must greater than two."
exit _rc
}

if `k'==1{

di _n in gr _col(12) "Study" _col(22) "|" _col(26) "Effect size" _col(40) "|" _col(45) "[$IND% Conf. Interval]" 
	di  _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 

	local i=1
	
	if "`study'" != "" {
	di in gr `study'[`i']  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
	}
	else {
	di in gr `id'[`i']  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
	}
	
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
di _col(1) in gr "Pooled effect"  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
local plci=`lci'[`i']
local puci=`uci'[`i']
local em = `_USE1'[`i']

if "`eform'" == "" {
if "`graph'" != "" {
if "`study'" != "" {
qui metagraph `1' `2', id(`study') mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
else {
qui metagraph `1' `2', id(`id') mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
}
}
if "`eform'" ~= "" {
if "`graph'" != "" {
if "`study'" != "" {
metagraph `1' `2', id(`study') eform x(0.1 0.25 0.5 1 2 4 8 10) mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
else {
metagraph `1' `2', id(`id') eform x(0.1 0.25 0.5 1 2 4 8 10) mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
}
}
return scalar numberofstudies = `k'
return scalar em = `em'
return scalar ConfIntervalLow = `plci'
return scalar ConfIntervalUp = `puci'
exit _rc
}

else{

if "`eform'" ~= "" {
scalar `em'=exp(`em')
scalar `vm' = exp(`vm')
scalar `vt2'=exp(`vt2')
scalar `et2'=exp(`et2')
qui replace `_USE1'=exp(`_USE1')
}

di in gr "***** Results *****"
display in ye "V(mu) = " `vm'
display in ye "E(tau-square) = " `et2'
display in ye "V(tau-square) = " `vt2'
display in ye  "E(mu) = " `em'
di _n in gr _col(12) "Study" _col(22) "|" _col(26) "Effect size" _col(40) "|" _col(45) "[$IND% Conf. Interval]" 
	di  _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 

	
local i = 1

while `i' <= `k'{
	if "`study'" != "" {
	di in gr `study'[`i']  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
	}
	else {
	di in gr `id'[`i']  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
	}
	local i = `i' + 1	
}
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
di _col(1) in gr "Pooled effect"  _col(22) "| " in ye  %7.3f  `em' _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `plci' _col(50) in ye  %7.3f _col(56) `puci'
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 


local plci=`plci'
local puci=`puci'
local em = `em'

if "`eform'" == "" {
if "`graph'" != "" {
if "`study'" != "" {
qui metagraph `1' `2', id(`study') mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
else {
qui metagraph `1' `2', id(`id') mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
}
}
if "`eform'" ~= "" {
if "`graph'" != "" {
if "`study'" != "" {
qui metagraph `1' `2', id(`study') eform x(0.1 0.25 0.5 1 2 4 8 10) mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
else {
qui metagraph `1' `2', id(`id') eform x(0.1 0.25 0.5 1 2 4 8 10) mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
}
}
}
	
return scalar numberofstudies = `k'
return scalar vm = `vm'
return scalar et2 = `et2'
return scalar vt2 = `vt2'
return scalar em = `em'
return scalar ConfIntervalLow = `plci'
return scalar ConfIntervalUp = `puci'
} //end m1

if(`m2'==1){
tempvar s1 v k coef vars vm et2 t2 em vt2 mt2 id lci uci lny numberOfStudies het z plci puci numberofstudies ConfIntervalLow ConfIntervalUp

global IND `l'
if (`l' == 80){
	 scalar `z' = 1.282
	 }
else if (`l' ==85){
	 scalar `z' = 1.440
	 }
else if (`l' ==90){
	 scalar `z' = 1.645
	 }
else if (`l'==95){
	 scalar `z' = 1.960
	 }
else if (`l'==98){
	 scalar `z' = 2.33
	 }
else if (`l'==99){
	 scalar `z' = 2.576
	 }
else if (`l'==99.5){
	 scalar `z' = 2.807
	 }
else if (`l'==99.9){
	 scalar `z' = 3.291
	 }
else{
	di as err "Please choose one of the following confidence levels : 80% , 85% , 90% , 95% , 98% , 99% , 99.5% , 99.9%  "
	exit _rc
	}
	
scalar `k'= _N
if (`k'==1){
	
	di as err "You can not run gllamm command with only one observation "
	exit _rc
		
} // if k==1

else if(`k'>1) {
qui egen `id' = fill(1 2)
qui replace `id'=. if  `_USE1'==. | `_USE2'==. 
qui levelsof `_USE2' , local(slev)
foreach i in `slev' {
	if `i'<=0 {
		di as err "Varlist containing standard error should have only positive values"
		exit 125
		}
}
}	
qui gen `lci' = `_USE1' - `z' * `_USE2'
	qui gen `uci' = `_USE1' + `z' * `_USE2'

if "`eform'" ~= "" {
qui replace `lci'=exp(`_USE1' - `z' * `_USE2')
qui replace `uci'=exp(`_USE1' + `z' * `_USE2')
}	
	
di in ye "The value of the shape parameter is set to 2 and " 
di in ye "the value of the scale parameter is close to 0"
di in ye "The number of studies included in this meta-analysis is " `k'
eq het: `_USE2'
	constraint define 1 `[s1]'`_USE2'=1
	
	qui gllamm `_USE1', i(`id') s(het) nats constraint(1) level(`l') adapt prior(gamma, scale(10000) shape(2))
	
	qui mat coef = e(b)
	qui mat vars = e(V)
	qui mat mt2 = e(chol)
	qui mat list coef
	
	scalar `em'=coef[1,1]
	qui mat list vars
	scalar `vm'=vars[1,1]
	scalar `t2'=mt2[1,1]
	scalar `et2' = `t2'*`t2'
	ereturn post coef vars
	
tempvar ss 
tempname plci puci
qui gen `ss' = sqrt(`vm')
scalar `plci' = `em' - `z'*`ss'
scalar `puci' = `em' + `z'*`ss'

if "`eform'" ~= "" {
scalar `plci'=exp(`plci')
scalar `puci'=exp(`puci')
}

if "`eform'" ~= "" {
scalar `em'=exp(`em')
scalar `vm' = exp(`vm')
scalar `et2'=exp(`et2')
qui replace `_USE1'=exp(`_USE1')
}
	
	di in gr "***** Results *****"
	di in ye "V(mu) = " `vm'
	di in ye "E(tau-square) = " `et2'
	di in ye "E(mu) = " `em'
	
	di _n in gr _col(12) "Study" _col(22) "|" _col(26) "Effect size" _col(40) "|" _col(45) "[$IND% Conf. Interval]" 
	di  _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
	
	
	local i = 1

while `i' <= `k'{
	if "`study'" != "" {
	di in gr `study'[`i']  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
	}
	else {
	di in gr `id'[`i']  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
	}
	local i = `i' + 1	
}
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
di _col(1) in gr "Pooled effect"  _col(22) "| " in ye  %7.3f  `em' _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `plci' _col(50) in ye  %7.3f _col(56) `puci'
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 

local plci=`plci'
local puci=`puci'
local em = `em'

if "`eform'" == "" {
if "`graph'" != "" {
if "`study'" != "" {
qui metagraph `1' `2', id(`study') mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
else {
qui metagraph `1' `2', id(`id') mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
}
}
if "`eform'" ~= "" {
if "`graph'" != "" {
if "`study'" != "" {
qui metagraph `1' `2', id(`study') eform x(0.1 0.25 0.5 1 2 4 8 10) mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
else {
qui metagraph `1' `2', id(`id') eform x(0.1 0.25 0.5 1 2 4 8 10) mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
}
}

return scalar numberOfStudies = `k'
return scalar em = `em'
return scalar vm = `vm'
return scalar et2 = `et2'
return scalar ConfIntervalLow = `plci'
return scalar ConfIntervalUp = `puci'
} // end of m2

if(`m3'==1){
tempvar type1 s2 v id z plci puci K Y k i j o f coef vars em ev et2 z r id lci uci lny q artf orig numberofstudies ConfIntervalLow ConfIntervalUp

global IND `l'
if (`l' == 80){
	 scalar `z' = 1.282
	 }
else if (`l' ==85){
	 scalar `z' = 1.440
	 }
else if (`l' ==90){
	 scalar `z' = 1.645
	 }
else if (`l'==95){
	 scalar `z' = 1.960
	 }
else if (`l'==98){
	 scalar `z' = 2.33
	 }
else if (`l'==99){
	 scalar `z' = 2.576
	 }
else if (`l'==99.5){
	 scalar `z' = 2.807
	 }
else if (`l'==99.9){
	 scalar `z' = 3.291
	 }
else{
	di as err "Please choose one of the following confidence levels : 80% , 85% , 90% , 95% , 98% , 99% , 99.5% , 99.9%  "
	exit _rc
	}
	
scalar `k'= _N

if (`k'==1){
	if (`_USE2'<=0){
	di as err "Varlist containing standard error should have only positive values"
		exit 125
		}
	}
	
if (`k'>1){
qui levelsof `_USE2' , local(slev)
foreach i in `slev' {
	if `i'<=0 {
		di as err "Varlist containing standard error should have only positive values" 
		exit 125
		}
}
}

if (`k'<3 & `a'<0.8){
	di as err "You can not run metareg command with only two or less observations when the value of the parameter a is less than 0.8"
	exit _rc
	}
	
di in ye "Inverse-Gamma Distribution parameters are a = " `a' " and b = " `b'
di in ye "The number of original studies included in this meta-analysis is " `k'
local K = round(2*`a')
di in ye "The number of artificial studies is " `K'
	confirm integer number `K'

	qui gen `type1'=0
	qui gen `v'=`_USE2'*`_USE2'
	 
qui sum `_USE1'
local k=`k'
forvalues r=1/`k'{
	qui replace `type1'=1
	}

    local i = `k' + 1
	local j = `K' + `k'
	qui set obs `j'
	
	forvalues f = `i'/`j'{
	 qui replace `type1'=0 if `type1'>=.
	 qui replace `_USE1'=0 if `_USE1'>=.
	 qui replace `v'=0 if `v'>=.
	 if "`study'" ~= ""{
	 qui replace `study'="artificial study" if `study'==""
	 }
	 } 
	  
	local Y = sqrt(2*`b'/`K')
	
	if (`k'==1){	
	forvalues o = 2/`j'{
	qui replace `_USE1' = `Y' if `type1'==0
	qui replace `v'=1E-20 if `type1'==0
	}
}	

if (`k'>1){	
	forvalues o = 1/`j'{
	qui replace `_USE1' = `Y' if `type1'==0
	qui replace `v'=1E-20 if `type1'==0
	}
}

qui gen `lci' = `_USE1' - `z' * sqrt(`v')
qui gen `uci' = `_USE1' + `z' * sqrt(`v')

	
	gen `s2'=sqrt(`v')
	
	qui metareg `_USE1' `type1', wsse(`s2') reml z level(`l') noconst
	
	mat coef = e(b)
	mat vars = e(V)
	local et2 = e(tau2) 
	qui mat list coef
	local em=coef[1,1]
	qui mat list vars
	local vm=vars[1,1]

tempvar ss 
qui gen `ss' = sqrt(`vm')
scalar `plci' = `em' - `z'*`ss'
scalar `puci' = `em' + `z'*`ss'

if "`eform'" ~= "" {
local em=exp(`em')
local vm = exp(`vm')
local et2=exp(`et2')
qui replace `_USE1'=exp(`_USE1')
qui replace `lci'=exp(`lci')
qui replace `uci'=exp(`uci')
local plci=exp(`plci')
local puci=exp(`puci')
}

	di in gr "***** Results *****"
	di in ye "V(mu) = " `vm'
	di in ye "E(tau-square) = " `et2'
	di in ye "E(mu) = " `em'
	
	global em=`em'
	di _n in gr _col(12) "Study" _col(22) "|" _col(26) "Effect size" _col(40) "|" _col(45) "[$IND% Conf. Interval]" 
	di  _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 

global k1 = _N
local q = 1
qui gen `id'=_n
while `q' <= $k1{
	if "`study'" != "" {
	di in gr `study'[`q']  _col(22) "| " in ye  %7.3f  `_USE1'[`q'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`q'] _col(50) in ye  %7.3f _col(56) `uci'[`q']
	}
	else {
	di in gr `id'[`q']  _col(22) "| " in ye  %7.3f  `_USE1'[`q'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`q'] _col(50) in ye  %7.3f _col(56) `uci'[`q']
	}
	local q = `q' + 1	
}

di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
di _col(1) in gr "Pooled effect"  _col(22) "| " in ye  %7.3f  `em' _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `plci' _col(50) in ye  %7.3f _col(56) `puci'
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 

local plci=`plci'
local puci=`puci'
local em = `em'

if "`eform'" == "" {
if "`graph'" != "" {
if "`study'" != "" {
qui metagraph `_USE1' `_USE2', id(`study') mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
else {
qui metagraph `_USE1' `_USE2', id(`id') mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
}
}
if "`eform'" ~= "" {
if "`graph'" != "" {
if "`study'" != "" {
qui metagraph `_USE1' `_USE2', id(`study') eform x(0.1 0.25 0.5 1 2 4 8 10) mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
else {
qui metagraph `_USE1' `_USE2', id(`id') eform x(0.1 0.25 0.5 1 2 4 8 10) mscale(0.22) combined(`em' `plci' `puci') bgcolor(black) plotregion(fcolor(white) lcolor(black)) graphregion(color(ltbluishgray)) title({bf:Meta-analysis} , color(black)) ytitle({bf:Study}, color(black)) xtitle({bf:Estimate of the Effect}, color(black))
}
}
}

return scalar numberofstudies = _N
return scalar em = `em'
return scalar vm = `vm'
return scalar et2 = `et2'
return scalar ConfIntervalLow = `plci'
return scalar ConfIntervalUp = `puci'

	qui{
	if `K'!=0{
	drop in `i'/`j'
	}
	}
} //end of m3
}  //end of by

if("`by'"!=""){

if(`m1'==1){
tempvar s2 nom_sum yi2 dnom_sum lci uci lny  id plci puci em mn rss vm et2 c nvt2 b2 dvt2 vt2 t1 t2 f t nom1 nom k y2 sumy r denom1 denom  z by2 newby by_num max numberofstudies ConfIntervalLow ConfIntervalUp

global IND `l'
if (`l' == 80){
	 scalar `z' = 1.282
	 }
else if (`l' ==85){
	 scalar `z' = 1.440
	 }
else if (`l' ==90){
	 scalar `z' = 1.645
	 }
else if (`l'==95){
	 scalar `z' = 1.960
	 }
else if (`l'==98){
	 scalar `z' = 2.33
	 }
else if (`l'==99){
	 scalar `z' = 2.576
	 }
else if (`l'==99.5){
	 scalar `z' = 2.807
	 }
else if (`l'==99.9){
	 scalar `z' = 3.291
	 }
else{
	di as err "Please choose one of the following confidence levels : 80% , 85% , 90% , 95% , 98% , 99% , 99.5% , 99.9%  "
	exit _rc
	}
	
scalar `k'= _N
if (`k'==1){
	local i=1
	qui gen `id'=_n
	
	if `_USE2'<=0{
	di as err "Varlist containing standard error should have only positive values"
		exit 125
		}
	if `_USE3'<=0 {
		di as err "Varlist containing number of participants should have only positive values" 
		exit 125
		}
	} 
else if(`k'>1) {
qui egen `id' = fill(1 2)
qui replace `id'=. if  `_USE1'==. |`_USE2'==. 
qui levelsof `_USE2' , local(slev)
foreach i in `slev' {
	if `i'<=0 {
		di as err "Varlist containing standard error should have only positive values"
		exit 125
		}
}
qui levelsof `_USE3' , local(nlev)
foreach i in `nlev' {
	if `i'<=0 {
		di as err "Varlist containing number of participants should have only positive values"  
		exit 125
		}
}
} 
	qui gen `lci' = `_USE1' - `z' * `_USE2'
	qui gen `uci' = `_USE1' + `z' * `_USE2'

di in ye "Inverse-Gamma Distribution parameters are a = " `a' " and b = " `b'
di in ye "The number of studies included in this meta-analysis is " `k'

qui gen `yi2' = `_USE1'*`_USE1'
quietly generate `s2' = `_USE2'*`_USE2'
qui generate `nom_sum' = 0
qui gen `dnom_sum' = 0 

constraint define 1 `[s1]'`_USE2'=1
cap confirm numeric var `by'
if _rc == 0{
	tempvar by_num 
	cap decode `by', gen(`by_num')
	if _rc != 0{
		local f: format `by'
		qui gen `by_num' = string(`by', "`f'")
	}
	qui drop `by'
	rename `by_num' `by'
}

qui count
local N = r(N)

qui gen `by2' = 1 in 1

local lab = `by'[1]

cap label drop bylab

if "`lab'" != ""{
	label define bylab 1 "`lab'"
}
local found1 "`lab'"
local max = 1

forvalues i = 2/`N'{

	local thisval = `by'[`i']
	
	local already = 0
	forvalues j = 1/`max'{
		if "`thisval'" == "`found`j''"{
			local already = `j'
		}
	}
	if `already' > 0{
		qui replace `by2' = `already' in `i'

	}
	else{
		local max = `max' + 1
		qui replace `by2' = `max' in `i'
		local lab = `by'[`i']
		if "`lab'" != ""{
			label define bylab `max' "`lab'", modify
		}
		local found`max' "`lab'"
	}
	
}

label values `by2' bylab

sort `by2' `sortby' `id'

qui gen `newby'=(`by2'>`by2'[_n-1])

qui replace `newby'=1+sum(`newby')

local ngroups=`newby'[_N]

local j=1
local i=1
while `j'<=`ngroups' {
qui count if (`newby'==`j')
	if r(N)==0{
	di "Subgroup analysis can not be completed"
	}
	qui sum `_USE1' if `newby'==`j' 
	scalar `mn'=r(mean)
	scalar `k'=r(N)
	
	qui sum `yi2' if `newby'==`j'
	scalar `sumy' = r(sum)

	scalar `y2' = `mn'*`mn'
	scalar `rss' = `sumy' - `k'*`y2'
	
	scalar `vm' = (2*(1 + `b'*`rss'/2))/(`b'*`k'*(2*`a' + `k' -3))
	scalar `et2' = (2*(1 + `b'*`rss'/2))/(`b'*(2*`a' + `k' -3))

	scalar `c' = (1 + `b'*`rss'/2)*(1 + `b'*`rss'/2)
	scalar `nvt2' = 8*`c'

	scalar `b2' = `b'*`b'
	scalar `dvt2' = `b2'*((2*`a' + `k' - 3)*(2*`a' + `k' - 3))*(`k' + 2*`a' -5)

	scalar `vt2' = `nvt2'/`dvt2'

	scalar `t1' = `b'*(`k' + 2*`a' -1)
	scalar `t2' = 2*(1 + (`b'*`rss'/2))
	
	scalar f = `t1'/`t2'
	
	qui replace `nom_sum' = ((`3'*`s2')/(`3'-3))*(((`mn'*(`k'-3)+`1')/`k')-(((`y2'*(`mn'-`1')+(`mn'*`yi2'))*(`k'+(2*`a')+1)*`b')/(2*(1+`b'*`rss'/2))))	
	qui summarize `nom_sum' if `newby'==`j'
	
	scalar `nom1' = r(sum)
	scalar `nom' = `mn'-(f*`nom1')
	
	qui replace `dnom_sum' = ((`3'*`s2')/(`3'-3))*(((`k'-1)/`k') - (((`mn'*(`mn'-`1')+`yi2')*(`k'+2*`a'+1)*`b')/(2*(1+`b'*`rss'/2))))
	qui summarize `dnom_sum' if `newby'==`j'
	scalar `denom1' =r(sum)
	scalar `denom' = 1-(f*`denom1')
	
	global em = `nom'/`denom'
	global plci = $em - `z'*sqrt(`vm')
	global puci = $em + `z'*sqrt(`vm') 

scalar k_`j' = `k'
scalar vm_`j' = `vm'
scalar et2_`j' = `et2'
scalar vt2_`j' = `vt2'
scalar em_`j' = $em
scalar plci_`j' = $plci
scalar puci_`j' = $puci

if "`eform'"!=""{
qui replace `lci' = exp(`_USE1' - `z' * `_USE2')
qui replace `uci' = exp(`_USE1' + `z' * `_USE2')
scalar vm_`j' = exp(`vm')
scalar et2_`j' = exp(`et2')
scalar vt2_`j' = exp(`vt2')
scalar em_`j' = exp($em)
scalar plci_`j' = exp($plci)
scalar puci_`j' = exp($puci)
}

if ((k_`j'!=1 &  k_`j'>5 )| (k_`j'!=1 & k_`j'<=5 & `a'>2 )){
return scalar numberofstudies_`j' = k_`j'
return scalar vm_`j' = vm_`j'
return scalar et2_`j' = et2_`j'
return scalar vt2_`j' = vt2_`j'
return scalar em_`j' = em_`j'
return scalar ConfIntervalLow_`j' = plci_`j'
return scalar ConfIntervalUp_`j' = puci_`j'
}

if k_`j'==1{
forvalues i = 1/`N' {
 if `newby'[`i']==`j' {
scalar plci_`j' = `lci'[`i']
scalar puci_`j' = `uci'[`i']
scalar em_`j'= `_USE1'[`i']
}
}
if "`eform'"!=""{
scalar em_`j' = exp(em_`j')
}
return scalar numberofstudies_`j' = k_`j'
return scalar em_`j' = em_`j'
return scalar ConfIntervalLow_`j' = plci_`j'
return scalar ConfIntervalUp_`j' = puci_`j'
}
	local j=`j'+1
	
} //end of while `j'<=`ngroups'

if "`eform'"!=""{
qui replace `_USE1'=exp(`_USE1')
}
local i=1
local j=1
di _n in gr _col(10) "Study" _col(22) "|" _col(26) "Effect size" _col(40) "|" _col(45) "[$IND% Conf. Interval]" 
di  _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 

forvalues j=1/`ngroups'{
forvalues i = 1/`N' {
if `newby'[`i']==`j' {   
if "`study'" != "" {

di in gr `study'[`i']  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
}
else {
di in gr `id'[`i']  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
}

if k_`j'==1{
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
di _col(1) in gr "Pooled effect"  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
 
forval i=1/`N'{
if `newby'[`i']==`j'{
if `by'[`i'+1] != `by'[`i'] {
 
}
}
}
 
}
}
}

if (k_`j'<=5 & `a'<=2){
di as err "If the studies included in the meta-analysis are less or equal to five and the shape parameter (a) of the inverse gamma distribution "
di as err "is less than or equal to two meta-analysis can not be completed, since these approximations are not suitable for meta-analyses with "
di as err "fewer than six studies in them.The value of the shape parameter must greater than two."

forval i=1/`N'{
if `newby'[`i']==`j'{
if `by'[`i'+1] != `by'[`i'] {
di in ye "("`by'[`i'] ")" _col(1) 
}
}
}
di "number of studies in subgroup `j' = " = k_`j'
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
	}
	
if ((k_`j'!=1 &  k_`j'>5 )| (k_`j'!=1 & k_`j'<=5 & `a'>2 ) ) {
di in gr "***** Results *****"
di in ye "V(mu) = " vm_`j'
display in ye "E(tau-square) = " et2_`j'
display in ye "V(tau-square) = " vt2_`j'
display in ye  "E(mu) = " em_`j'

di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
di _col(1) in gr "Pooled effect"  _col(22) "| " in ye  %7.3f  em_`j' _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) plci_`j' _col(50) in ye  %7.3f _col(56) puci_`j'

forval i=1/`N'{
if `newby'[`i']==`j'{
if `by'[`i'+1] != `by'[`i'] {
di in ye "("`by'[`i'] ")" _col(1) 
}
}
}
di "number of studies in subgroup `j' = " = k_`j'
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
}
}
} // end of m1

if (`m2'==1){
tempvar s1 v k coef vars vm et2 t2 em vt2 mt2 id by2 newby by_num max lci uci lny het z plci puci numberofstudies ConfIntervalLow ConfIntervalUp

global IND `l'
if (`l' == 80){
	 scalar `z' = 1.282
	 }
else if (`l' ==85){
	 scalar `z' = 1.440
	 }
else if (`l' ==90){
	 scalar `z' = 1.645
	 }
else if (`l'==95){
	 scalar `z' = 1.960
	 }
else if (`l'==98){
	 scalar `z' = 2.33
	 }
else if (`l'==99){
	 scalar `z' = 2.576
	 }
else if (`l'==99.5){
	 scalar `z' = 2.807
	 }
else if (`l'==99.9){
	 scalar `z' = 3.291
	 }
else{
	di as err "Please choose one of the following confidence levels : 80% , 85% , 90% , 95% , 98% , 99% , 99.5% , 99.9%  "
	exit _rc
	}

	
qui levelsof `_USE2' , local(slev)
foreach i in `slev' {
	if `i'<=0 {
		di as err "Varlist containing standard error should have only positive values"
		exit 125
		}
}
scalar `k'=_N	
qui gen `lci' = `_USE1' - `z' * `_USE2'
qui gen `uci' = `_USE1' + `z' * `_USE2'

di in ye "The value of the shape parameter is set to 2 and " 
di in ye "the value of the scale parameter is close to 0"
di in ye "The number of studies included in this meta-analysis is " `k'

qui egen `id' = fill(1 2)
qui replace `id'=. if  `_USE1'==. | `_USE2'==.

qui gen `v'=`_USE2'*`_USE2'
	
eq het: `_USE2'
constraint define 1 `[s1]'`_USE2'=1
cap confirm numeric var `by'


if _rc == 0{
	cap decode `by', gen(`by_num')
	if _rc != 0{
		local f: format `by'
		qui gen `by_num' = string(`by', "`f'")
	}
	qui drop `by'
	rename `by_num' `by'
}		

qui count
local N = r(N)

qui gen `by2' = 1 in 1

local lab = `by'[1]

cap label drop bylab

if "`lab'" != ""{
	label define bylab 1 "`lab'"
}

local found1 "`lab'"
local max = 1

forvalues i = 2/`N'{

	local thisval = `by'[`i']
	local already = 0
	forvalues j = 1/`max'{
		if "`thisval'" == "`found`j''"{
			local already = `j'
		}
	}
	if `already' > 0{
		qui replace `by2' = `already' in `i'

	}
	else{
		local max = `max' + 1
		qui replace `by2' = `max' in `i'
		local lab = `by'[`i']
		if "`lab'" != ""{
			label define bylab `max' "`lab'", modify
		}
		local found`max' "`lab'"
	}
	
}

label values `by2' bylab

sort `by2' `sortby' `id'

qui gen `newby'=(`by2'>`by2'[_n-1])

qui replace `newby'=1+sum(`newby')

local ngroups=`newby'[_N]


local j=1
local i=1
di _n in gr _col(10) "Study" _col(22) "|" _col(26) "Effect size" _col(40) "|" _col(45) "[$IND% Conf. Interval]" 
	di  _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 

while `j'<=`ngroups' {
preserve
qui count if (`newby'==`j')
	if _N==0{
	di as err "Subgroup analysis can not be completed"
	exit _rc
	}
	qui sum `1' if `newby'==`j'
	scalar `k'=r(N)
		
	qui keep if (`newby'==`j')
	scalar k_`j' = `k'
	if `k'==1{
	return scalar numberofstudies_`j' = k_`j'
	}
	
	if `k'>1 {
	constraint define 1 `[s1]'`_USE2'=1
	qui gllamm `_USE1', i(`id') s(het) nats constraint(1) level(`l') adapt prior(gamma, scale(10000) shape(2))

	qui mat coef_`j' = e(b)
	qui mat vars_`j' = e(V)
	qui mat mt2_`j' = e(chol)
	qui mat list coef_`j'
	
	scalar em_`j'=coef_`j'[1,1]
	qui mat list vars_`j'
	scalar vm_`j'=vars_`j'[1,1]
	scalar t2_`j'=mt2_`j'[1,1]
	scalar et2_`j' = t2_`j'*t2_`j'
	ereturn post coef_`j' vars_`j'
	
	scalar plci_`j' = em_`j' - `z'*sqrt(vm_`j')
	scalar puci_`j' = em_`j' + `z'*sqrt(vm_`j') 	
	
	if "`eform'"!=""{
	scalar vm_`j' = exp(vm_`j')
	scalar et2_`j' = exp(et2_`j')
	//scalar vt2_`j' = exp(`vt2')
	scalar em_`j' = exp(em_`j')
	scalar plci_`j' = exp(plci_`j')
	scalar puci_`j' = exp(puci_`j')
	}

return scalar numberofstudies_`j' = k_`j'
return scalar em_`j' = em_`j'
return scalar vm_`j' = vm_`j'
return scalar et2_`j' = et2_`j'
return scalar ConfIntervalLow_`j' = plci_`j'
return scalar ConfIntervalUp_`j' = puci_`j'
	}
	
if k_`j'==1{
forvalues i = 1/`N' {
 if `newby'[`i']==`j' {
scalar plci_`j' = `lci'[`i']
scalar puci_`j' = `uci'[`i']
scalar em_`j' = `_USE1'[`i']
}
}

if "`eform'"!=""{
scalar plci_`j' = exp(plci_`j')
scalar puci_`j' = exp(puci_`j')
scalar em_`j' = exp(em_`j')
}
return scalar numberofstudies_`j' = k_`j'
return scalar em_`j' = em_`j'
return scalar ConfIntervalLow_`j' = plci_`j'
return scalar ConfIntervalUp_`j' = puci_`j'
}

	local j=`j'+1
	restore
} //end of while `j'<=`ngroups'

if "`eform'"!=""{
qui replace `_USE1'=exp(`_USE1')
qui replace `lci' = exp(`lci')
qui replace `uci' = exp(`uci')
}
forvalues j=1/`ngroups'{
forvalues i = 1/`N' {
if `newby'[`i']==`j' {   
if "`study'" != "" {

di in gr `study'[`i']  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
}
else {
di in gr `id'[`i']  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
}
if k_`j'==1{
	
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
di _col(1) in gr "Pooled effect"  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
 
}
}
}

if (k_`j'==1){
di as err "You can not run gllamm command with only one observation "
forval i=1/`N'{
if `newby'[`i']==`j'{
if `by'[`i'+1] != `by'[`i'] {
di in ye "("`by'[`i'] ")" _col(1) 
}
}
}
di "number of studies in subgroup `j' = " = k_`j'
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
	
	}
else{
di in gr "***** Results *****"
di in ye "V(mu) = " vm_`j'
display in ye "E(tau-square) = " et2_`j'
display in ye  "E(mu) = " em_`j'

di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
di _col(1) in gr "Pooled effect"  _col(22) "| " in ye  %7.3f  em_`j' _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) plci_`j' _col(50) in ye  %7.3f _col(56) puci_`j'
forval i=1/`N'{
if `newby'[`i']==`j'{
if `by'[`i'+1] != `by'[`i'] {
di in ye "("`by'[`i'] ")" _col(1) 
}
}
}
di "number of studies in subgroup `j' = " = k_`j'
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
}
}
} //end of m2

if(`m3'==1){
tempvar type1 s2 v id by2 newby by_num max lci uci z plci puci K Y k i j o f coef vars em ev et2 z lp fr r id lci uci lny numberofstudies ConfIntervalLow ConfIntervalUp

global IND `l'
if (`l' == 80){
	 scalar `z' = 1.282
	 }
else if (`l' == 85){
	 scalar `z' = 1.440
	 }
else if (`l' == 90){
	 scalar `z' = 1.645
	 }
else if (`l'== 95){
	 scalar `z' = 1.960
	 }
else if (`l'== 98){
	 scalar `z' = 2.33
	 }
else if (`l'== 99){
	 scalar `z' = 2.576
	 }
else if (`l'== 99.5){
	 scalar `z' = 2.807
	 }
else if (`l'== 99.9){
	 scalar `z' = 3.291
	 }
else{
	di as err "Please choose one of the following confidence levels : 80% , 85% , 90% , 95% , 98% , 99% , 99.5% , 99.9% "
	exit _rc
	}
	
qui levelsof `_USE2' , local(slev)
foreach i in `slev' {
	if `i'<=0 {
		di as err "Varlist containing standard error should have only positive values" 
		exit 125
		}
}
qui gen `lci' = `_USE1' - `z' * `_USE2'
qui gen `uci' = `_USE1' + `z' * `_USE2'
qui gen `type1'=0
qui gen `v'=`_USE2'*`_USE2'
qui gen `s2'=0
qui gen `id'=_n
constraint define 1 `[s1]'`_USE2'=1
cap confirm numeric var `by'
if _rc == 0{
	cap decode `by', gen(`by_num')
	if _rc != 0{
		local f: format `by'
		qui gen `by_num' = string(`by', "`f'")
	}
	qui drop `by'
	rename `by_num' `by'
}	
qui count
local N = r(N)

qui gen `by2' = 1 in 1

local lab = `by'[1]

cap label drop bylab

if "`lab'" != ""{
	label define bylab 1 "`lab'"
}

local found1 "`lab'"
local max = 1

forvalues i = 2/`N'{

	local thisval = `by'[`i']
	local already = 0
	forvalues j = 1/`max'{
		if "`thisval'" == "`found`j''"{
			local already = `j'
		}
	}
	if `already' > 0{
		qui replace `by2' = `already' in `i'

	}
	else{
		local max = `max' + 1
		qui replace `by2' = `max' in `i'
		local lab = `by'[`i']
		if "`lab'" != ""{
			label define bylab `max' "`lab'", modify
		}
		local found`max' "`lab'"
	}
	
}

label values `by2' bylab

sort `by2' `sortby' `id'

qui gen `newby'=(`by2'>`by2'[_n-1])

qui replace `newby'=1+sum(`newby')


local ngroups=`newby'[_N]

local j=1
local i=1

while `j'<=`ngroups' {
preserve	
qui count if (`newby'==`j')
	if r(N)==0{
	di "Subgroup analysis can not be completed"
	}
	
	qui keep if (`newby'==`j')
	local K = round(2*`a')
	
	qui confirm integer number `K'
	
	qui sum `_USE1'
	local k = r(N)
	
	if(`k'==1 & `a'==0 & `b'==2){
	//di as err "You can not run metareg command with only one observation with parameters a=0 and b=2"
	}
	else if(`k'==2 & `a'==0 & `b'==2){
	//di as err "You can not run metareg command with only two observation with parameters a=0 and b=2"
	}
	else{
	forvalues r=1/`k'{
	qui replace `type1'=1
	}
	local i = `k' + 1
	local f = `K' + `k'
	qui set obs `f'
	
	forvalues lp = `i'/`f'{
	 qui replace `type1'=0 if `type1'>=.
	 qui replace `_USE1'=0 if `_USE1'>=.
	 qui replace `v'=0 if `v'>=.
	 } 
	 
	local Y = sqrt(2*`b'/`K')
	
	forvalues o = 1/`f'{
	qui replace `_USE1' = `Y' if `type1'==0
	qui replace `v'=1E-20 if `type1'==0
	}
	
	qui replace `s2'=sqrt(`v')
	
	qui metareg `_USE1' `type1', wsse(`s2') reml z level(`l') noconst
	}
	
	scalar k_`j' = `k'
	if (`k'==1 & `a'==0 ){
	return scalar numberofstudies_`j' = k_`j'	
	}
	else if(`k'==2 & `a'==0){
	return scalar numberofstudies_`j' = k_`j'
	}
	else{
	scalar K_`j' = `K'
	mat coef_`j' = e(b)
	mat vars_`j' = e(V)
	scalar et2_`j' = e(tau2) 
	qui mat list coef_`j'
	scalar em_`j'=coef_`j'[1,1]
	scalar m_st_`j'=coef_`j'[1,2]
	qui mat list vars_`j'
	scalar vm_`j'=vars_`j'[1,1]
	
	scalar plci_`j' = em_`j' - `z'*sqrt(vm_`j')
	scalar puci_`j' = em_`j' + `z'*sqrt(vm_`j')
	
	if "`eform'"!=""{
scalar vm_`j' = exp(vm_`j')
scalar et2_`j' = exp(et2_`j')
scalar em_`j' = exp(em_`j')
scalar plci_`j' = exp(plci_`j')
scalar puci_`j' = exp(puci_`j')
}
return scalar numberofstudies_`j' = k_`j'
return scalar em_`j' = em_`j'
return scalar vm_`j' = vm_`j'
return scalar et2_`j' = et2_`j'
return scalar ConfIntervalLow_`j' = plci_`j'
return scalar ConfIntervalUp_`j' = puci_`j'
	}
if (k_`j'<3 & `a'<0.8){
forvalues i = 1/`N' {
 if `newby'[`i']==`j' {
scalar plci_`j' = `lci'[`i']
scalar puci_`j' = `uci'[`i']
scalar em_`j' = `_USE1'[`i']
}
}
if "`eform'"!=""{
scalar plci_`j' = exp(plci_`j')
scalar puci_`j' = exp(puci_`j')
scalar em_`j' = exp(em_`j')
}
return scalar numberofstudies_`j' = k_`j'

}
	local j=`j'+1
	restore
} //end of while `j'<=`ngroups'

if "`eform'"!=""{
qui replace `lci' = exp(`lci')
qui replace `uci' = exp(`uci')
qui replace `_USE1'=exp(`_USE1')
}

di in ye "Inverse-Gamma Distribution parameters are a = " `a' " and b = " `b'
di in ye "The number of studies included in this meta-analysis is " `N'

qui replace `id' = `id'[_n-1]+1 if `id'>=.
di _n in gr _col(10) "Study" _col(22) "|" _col(26) "Effect size" _col(40) "|" _col(45) "[$IND% Conf. Interval]" 
	di  _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 

forvalues j=1/`ngroups'{
forvalues i = 1/`N' {
 if `newby'[`i']==`j' {   
if "`study'" != "" {

di in gr `study'[`i']  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
}
else {
di in gr `id'[`i']  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
}
if (k_`j'==1 & `a'==0){

di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
di _col(1) in gr "Pooled effect"  _col(22) "| " in ye  %7.3f  `_USE1'[`i'] _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) `lci'[`i'] _col(50) in ye  %7.3f _col(56) `uci'[`i']
 
}
}
}

if (k_`j'<3 & `a'<0.8){
di as err "You can not run metareg command with only two or less observations when the value of the parameter a is less than 0.8"
	
forval i=1/`N'{
if `newby'[`i']==`j'{
if `by'[`i'+1] != `by'[`i'] {
di in ye "("`by'[`i'] ")" _col(1) 
}
}
}
di "number of studies in subgroup `j' = " = k_`j'
di "The number of artificial studies is " `K'
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
	}
	
else{
di in gr "***** Results *****"
di in ye "V(mu) = " vm_`j'
display in ye "E(tau-square) = " et2_`j'
display in ye  "E(mu) = " em_`j'

di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
di _col(1) in gr "Pooled effect"  _col(22) "| " in ye  %7.3f  em_`j' _col(40) in gr "|" _col(45) in ye  %7.3f _col(46) plci_`j' _col(50) in ye  %7.3f _col(56) puci_`j'
forval i=1/`N'{
if `newby'[`i']==`j'{
if `by'[`i'+1] != `by'[`i'] {
di in ye "("`by'[`i'] ")" _col(1) 
}
}
}
di "number of studies in subgroup `j' = " = k_`j'
di "The number of artificial studies is " `K'
di in gr _dup(21) "-" "+" _dup(17) "-" "+" _dup(33) "-" 
}
}
} //end of m3

qui sort `id'
} //end of by!=0
}

else {   
di as err "Invalid random-effects method"
di as err "Choose one of the following: dl, dl2, hm, he, sj, sj2, ca2, pm, abi, gllamm, metareg"
	exit _rc  
	}	

end



**** **** **** **** **** **** **** **** **** **** **** **** **** **** **** **** 
