*! ntreatreg_1 v6, GCerulli 16/05/2022
program ntreatreg_2, eclass sortpreserve
	version 14
	#delimit ;     
	syntax varlist [if] [in] [fweight iweight pweight] , 
	spill(string)  
	[hetero(varlist numeric) 
	vce(string) 
	beta 
	graphic
	save_graph(string)
	const(string) 
	head(string) 
	conf(numlist max=1)];
	#delimit cr
	****************************************************************************
	* BEGIN PROGRAM
	****************************************************************************
	* DROP OUTCOME VARIABLES GENERATED LATER ON
	****************************************************************************
	foreach var of local xvars{
    capture drop _ws_`var' _z_`var' _v_`var' _ws_v_`var' 
    }	
	foreach var of local hetero{
	capture drop _ws_`var'  
	}
	capture drop ATE_x ATET_x ATENT_x 
	****************************************************************************
	* START BY ASKING IF A SPECIFIC MODEL HAS BEEN CHOSEN 
	****************************************************************************
	marksample touse
	tokenize `varlist'
    local y `1'
    local w `2'
	macro shift
	macro shift
	local xvars `*'
	****************************************************************************
	* GENERATE THE VARIABLES
	****************************************************************************
	tempvar ___ID // NEW
	gen `___ID'=_n // NEW
	gsort - `w' `___ID' // NEW
    ****************************************************************************
	foreach var of local hetero{
	tempvar m_`var' 
	tempvar s_`var'
	tempvar ws_`var'
	egen `m_`var'' = mean(`var') if `touse' 
	gen `s_`var'' = (`var' - `m_`var'') if `touse' 
	*
	capture drop _ws_`var'
	*	
	gen _ws_`var'=`w'*`s_`var'' if `touse' 
	}
	foreach var of local hetero{
    local xvar2 `xvar2' _ws_`var'
	}
	****************************************************************************
	* Create the variables v for each obs i
	****************************************************************************
	foreach var of local xvars{
	tempname mat_`var'
	tempname v_`var'
	tempvar m_v_`var'
	tempvar s_v_`var'
	mkmat `var' , matrix(`mat_`var'')
	mat `v_`var''=`spill'*`mat_`var''
	svmat `v_`var''
	cap drop _v_`var'
	gen _v_`var' = `v_`var''1
	egen `m_v_`var'' = mean(_v_`var') if `touse' 
	gen  `s_v_`var'' = (`m_v_`var'' - _v_`var') if `touse'
	cap drop _ws_v_`var'
	gen  _ws_v_`var' =`w'*`s_v_`var'' if `touse'
	cap drop _z_`var'
	gen  _z_`var' = _v_`var' + _ws_v_`var'
	local z_vars `z_vars' _z_`var'  
	}
	***********************************************************************************************
	* BASELINE REGRESSION
	***********************************************************************************************
	regress `y' `w' `xvars' `xvar2' `z_vars' if `touse' [`weight'`exp'] , vce(`vce') `beta' `const' `head' level(`conf')
	***********************************************************************************************
	tempvar yhat
	tempvar res
	predict `yhat' if `touse', xb
	predict `res' if `touse', res
	ereturn scalar ate = _b[`w']
	****************************************************************************
	foreach var of local hetero{
	scalar _d`var' = _b[_ws_`var']
	scalar _g`var' = _b[_z_`var']
	}
	tempvar k
    generate `k' = 0 
    foreach var of local hetero{
 	replace `k' = `k' + (`s_`var'' * _d`var') + (`s_v_`var'' * _g`var')
	}
	****************************************************************************
	*** Calculate the spillover _spill_=z*lambda
	****************************************************************************
	cap drop _spill_
	gen _spill_=0
	la var _spill_ "Neighborhood effect (=z*lambda)"
	foreach v of local xvars{
	replace _spill_=_spill_+_z_`v'*_b[_z_`v'] if `touse'
	}
	****************************************************************************
	capture drop ATE_x ATET_x ATENT_x
	gen ATE_x = _b[`w'] + `k'
	tempvar wk
	gen `wk' = `w'*`k' if `touse'
	qui sum `wk' if `w' == 1
	local mean_h = r(mean)
	ereturn scalar atet = _b[`w'] + `mean_h'
	tempvar ATET_x
	gen ATET_x = _b[`w'] + `wk'  if `w'==1
	tempvar w2
	tempvar w2k
	gen `w2'=(1-`w')
	gen `w2k' = `w2'*`k'  if `touse'
	qui sum `w2k' if `w'==0
	local mean_h2 = r(mean)
	ereturn scalar atent = _b[`w'] + `mean_h2'
	tempvar ATENT_x
	gen ATENT_x =_b[`w'] + `w2k'  if `w'==0
	*************************
	* Calculating sample size
	*************************
	qui sum ATE_x
	ereturn scalar N_tot=r(N)
	qui sum ATET_x
	ereturn scalar N_treat=r(N)
	qui sum ATENT_x
	ereturn scalar N_untreat=r(N)
	********************************
	* End of calculating sample size
	********************************
	if "`hetero'" != ""{
	if "`graphic'"=="graphic"{
	graph_1 `model'
	if "`graphic'"=="graphic" & & "`save_graph'"!=""{
    qui graph save `save_graph' , replace
    }
	}
	}
end
***********************************************************************
* PROGRAM "graph_1" TO DRAW THE OVELAPPING DISTRIBUTIONS 
* OF ATE(x), ATET(x) and ATENT(x)
***********************************************************************
capture program drop graph_1
program graph_1
args model
version 11
twoway kdensity ATE_x , /// 
|| ///
kdensity ATET_x , lpattern(dash) ///
|| ///
kdensity ATENT_x , lpattern(longdash_dot) xtitle("") ///
ytitle(Kernel density) legend(order(1 "ATE(x)" 2 "ATET(x)" 3 "ATENT(x)")) ///
title("Distribution of ATE(x) ATET(x) ATENT(x)", size(medlarge)) ///
scheme(s1mono) 
end
********************************************************************************
