
*! version 1.1.0  25feb2022
capture program drop crtfreq
program define crtfreq, rclass
version 15.1
syntax varlist(numeric fv) [if] [in], INTervention(varlist numeric fv max=1) RANdom(varlist numeric max=1) [, NPerm(integer 0) NBoot(integer 0) SEED(integer 1020252) noDOT noIsily ML REML CASE(numlist asc >0 max=2) RESidual PERCentile BASIC PASTE *]

quietly {
	preserve
	if "`paste'"!="" {
	if "`nperm'" != "0" {
		cap drop PermC_I*_W PermUnc_I*_W PermC_I*_T PermUnc_I*_T
		}
	if "`nboot'" != "0" {
		cap drop BootC_I*_W BootC_I*_T BootUnc_I*_W BootUnc_I*_T
		}
	}
	if "`nboot'" == "0" & "`percentile'"!="" | "`nboot'" == "0" & "`basic'"!="" | "`nboot'" == "0" &  "`case'" != "" | "`nboot'" == "0" &  "`residual'" != "" {
		noi disp as error "Please specify number of bootstraps"
        error 198
		}
	if "`percentile'"!="" & "`basic'"!="" | "`nperm'" != "0" & "`nboot'" != "0" {
		noi disp as error "you have included resampling options that cannot be specified at the same time"
        error 198
		}
	
	local ci percentile
	if "`basic'"!="" local ci `basic'
	
	tempfile Original
	save `Original'
	
	local intervraw: copy local intervention
	
	fvrevar `intervention', list
	local intervention `r(varlist)'
	
	local maximization reml
	if "`ml'" != "" & "`reml'" != "" {
	noi disp as error "ml and reml may not be specified at the same time"
	error 198
	}
	if "`ml'" != "" {
		local maximization
		}
	
	cap {
		local newvarlist	
		foreach var of local varlist {
			if "`var'" != "`intervention'" & !regexm("`var'","i[^\.]*\.`intervention'$") & !regexm("`var'","\((#[0-9])\)*\.`intervention'$") | regexm("`var'","#")   {
				local newvarlist `newvarlist' `var'
				}
			else {
			noi disp as txt "Note: Inclusion of the intervention variable in the variable list is redundant."
			}
			}
		local varlist: copy local newvarlist
		}
	
	fvrevar `varlist', list
	local varlist_clean `r(varlist)'
	
	marksample touse
	markout `touse' `intervention' `random'
	keep if `touse'

	
	tempname chk Beta Beta1 test1 test0 b0 Cov schRand X max b id_var_col cluster_variance2 res_var_col res_variance1 res_variance2 Total2 ICC2 ICC1 ///
	B cluster_variance1 Total1 A M N_total colnumber min Max Coef
	tempvar r total_chk res1 rIntercept1 ressq1 rInterceptsq1 res2 rIntercept2 fitted1 fitted2 broken_factor
	tab `random' `intervention', matcell(`chk')
	
	tab `intervention'
	scalar `max' = r(r)
	mata: st_numscalar("`chk'", colsum(rowsum(st_matrix("`chk'"):>0):>1))
	if `chk'!=0 {
	display as error "error: This is not a CRT design"
	error 459
	}
	
	baseset, max(`max') intervention(`intervraw')
	local refcat `r(refcat)'
	
	tempfile crt
	save `crt'
	
	tempfile crt2
	save `crt2'
	
	levelsof `intervention', local(levels)
	tokenize `levels'

	gettoken depvar indepvars: varlist
	
	mixed `depvar' || `random':, `options' `maximization'
	matrix `b' = e(b)
	predict `fitted2', xb
	predict `res2', res
	predict `rIntercept2', reffects
	scalar `id_var_col' = colnumb(`b', "lns1_1_1:_cons")
	scalar `cluster_variance2' = exp(`b'[1, `id_var_col'])^2

	scalar `res_var_col' = colnumb(`b', "lnsig_e:_cons")
	scalar `res_variance2' = exp(`b'[1, `res_var_col'])^2
	scalar `Total2' = `res_variance2' + `cluster_variance2'

	scalar `ICC2' = `cluster_variance2'/`Total2'
	
	matrix `B' = (round(`cluster_variance2',.01),round(`res_variance2',.01),round(`Total2',.01),round(`ICC2',.01))
	
	`isily' mixed `depvar' i.`intervention' `indepvars' || `random':, `options' `maximization'
	matrix `test0' = r(table)[1...,1.."`depvar':_cons"]
	scalar `colnumber' = colnumb(`test0',"`=`refcat'+0'b.`intervention'")
	
	if "`=`colnumber''"=="1" { 
		matrix `test0' = `test0'[1...,2...]
		}
	else {
		matrix `test0' = `test0'[1...,1..`=`colnumber'-1'],`test0'[1...,`=`colnumber'+1'...]
		}
	matrix `test1' = `test0'
	forvalues i = 1/`=rowsof(`test0')' {
		forvalues j = 1/`=colsof(`test0')' {
			matrix `test1'[`i',`j']= round(`test0'[`i',`j'],.01)
		}
	}
		
	matrix `Beta1' = (`test1'["b", .] \ `test1'["ll".."ul", . ])
	matrix `Beta'=`Beta1''
	matrix colnames `Beta' = "Estimate" "95% LB" "95% UB"

	matrix `b' = e(b)
	predict `fitted1', xb
	predict `res1', res
	predict `rIntercept1', reffects

	scalar `id_var_col' = colnumb(`b', "lns1_1_1:_cons")
	scalar `cluster_variance1' = exp(`b'[1, `id_var_col'])^2

	scalar `res_var_col' = colnumb(`b', "lnsig_e:_cons")
	scalar `res_variance1' = exp(`b'[1, `res_var_col'])^2
	scalar `Total1' = `res_variance1' + `cluster_variance1'

	scalar `ICC1' = `cluster_variance1' / `Total1'

	matrix `A' = (round(`cluster_variance1',.01),round(`res_variance1',.01),round(`Total1',.01),round(`ICC1',.01))
	
	matrix `Cov' = (`A' \ `B')
	matrix colnames `Cov' = "Schools" "Pupils" "Total" "ICC"
	matrix rownames `Cov' = "Conditional" "Unconditional"
	
	matrix `Coef' = `b'[1,1..`=`max'']
	
	mata funczero("`Coef'")
	matrix `Coef' = `Coef''
	
	tempfile beta1
	save `beta1'
	keep `rIntercept1' `random'
	collapse `rIntercept1', by(`random')
	mkmat `rIntercept1' `random', matrix(`schRand')
	mata funcround("`schRand'")
	matrix colnames `schRand' = "Intercept" "School"
	clear
	use `crt'
	
	/*g.within*/

	tab `intervention', generate(`broken_factor')
	
	foreach i of numlist 1/`=`max''{
		if "`=`refcat'+0'" != "``i''" {
			local rowname `rowname' "`intervention'``i''"
			local two `two' `broken_factor'`i'
			}
		else {
		local one `one' `broken_factor'`i'
		}
		}

	local broken_treatment
	foreach i of numlist 1/`=`max'' {
		local broken_treatment `broken_treatment' `broken_factor'`i' /*store all brokn_fctors in local*/
		}
	rename (`one' `two') (`broken_treatment') /*rename broken_factors based on new ref category (i.e. broken2 broken1 broken3 to broken1 broken2 broken3)*/
	forvalues s = 1/2 {
		forvalues i = 1/`=`max'-1' {
			tempfile forloop
			save `forloop'
			
			tempname sumBr_F`i' nt`i' nc`i' d`s'w`i' MatNt`i' Nc`i' N`i' Nt`i' Mc`i' Mt`i' M`i' Br_F`i' 
			
			scalar `d`s'w`i'' = `Coef'[`i',1] / sqrt( `res_variance`s'' )
	
			tab `random' `broken_factor'`=`i'+1', matcell(`Br_F`i'')  /*because `=`max'-1' = 2 , broken factor is 1,2,3 but we need 2,3 because 1 is baseline*/
			//svmat Br_F`i'
			mata functot("`Br_F`i''","`sumBr_F`i''") 
			
			//total Br_F`i'1 /*Br_F will always be 0/1 ( Br_F`i'1 is 0 and Br_F`i'2 is 1)*/
			matrix `MatNt`i'' = `sumBr_F`i''[1,1]
			scalar `Nc`i'' = `MatNt`i''[1,1]
	
			//total Br_F`i'2
			matrix `MatNt`i'' = `sumBr_F`i''[1,2]
			scalar `Nt`i'' = `MatNt`i''[1,1]
			
			scalar `N`i'' = `Nc`i'' + `Nt`i'' 
			
			tab `random' `broken_factor'`=`i'+1' if `broken_factor'`=`i'+1'==1, matcell(`nt`i'') 
			scalar `Mt`i''= r(r) 
			
			tab `random' `broken_factor'`=`i'+1' if `broken_factor'`=`i'+1'==0, matcell(`nc`i'') 
			scalar `Mc`i''= r(r) 
			
			scalar `M`i'' = `Mc`i'' + `Mt`i''
			clear
			use `forloop'
			}
	
	forvalues i = 1/`=`max'-1' {
	tempname nsim1`i' nsim2`i' nsimTotal`i' vterm1`i' v`s'term2`i' v`s'term3`i' s`s'te`i' L`s'B`i' U`s'B`i' Out`s'put`i' nut`i' nuc`i' d`s't1`i' d`s't2`i' d`s'tTotal`i' B`i' At`i' Ac`i' A`i' v`s'term1Tot`i' v`s'term2Tot`i' v`s'term3Tot`i' s`s'teTot`i' L`s'Btot`i' U`s'Btot`i' Out`s'putTot`i' Out`s'putG`i' sqnt`i' sqnc`i' qnt`i' qnc`i' 
	
		mata: hfunc3("`nt`i''", "`nc`i''","`sqnt`i''", "`sqnc`i''","`qnt`i''", "`qnc`i''") 
		
		scalar `nsim1`i''     = (`Nc`i'' *`sqnt`i'')/(`Nt`i''*`N`i'')
		scalar `nsim2`i''     = (`Nt`i'' * `sqnc`i'')/( `Nc`i''*`N`i'')
		scalar `nsimTotal`i'' = `nsim1`i'' + `nsim2`i''
		scalar `vterm1`i''    = ((`Nt`i''+`Nc`i'')/(`Nt`i''*`Nc`i''))
		scalar `v`s'term2`i''    = (((1+( `nsimTotal`i''-1) * `ICC`s'' ))/(1- `ICC`s''))
		scalar `v`s'term3`i''    = ((`d`s'w`i''^2)/(2*(`N`i'' - `M`i'')))
		scalar `s`s'te`i''       = sqrt( `vterm1`i'' * `v`s'term2`i'' + `v`s'term3`i'')
		scalar `L`s'B`i''        = (`d`s'w`i'' -1.96* `s`s'te`i'')
		scalar `U`s'B`i''        = (`d`s'w`i'' +1.96* `s`s'te`i'')
		matrix `Out`s'put`i''    = (round(`d`s'w`i'',.01), round(`L`s'B`i'',.01), round(`U`s'B`i'',.01))
		
		
		/*End of g.within*/
		
		/*g.total*/
		
		scalar `nut`i''     = ((`Nt`i''^2-`sqnt`i'')/(`Nt`i'' *( `Mt`i'' -1)))
		scalar `nuc`i''     = ((`Nc`i''^2-`sqnc`i'')/(`Nc`i''*(`Mc`i''-1)))
		scalar `d`s't1`i''     = `Coef'[`i',1] / sqrt( `Total`s'' )
		scalar `d`s't2`i''     = sqrt(1-`ICC`s'' * ((( `N`i'' - `nut`i'' * `Mt`i'' - `nuc`i'' * `Mc`i'' ) + `nut`i'' + `nuc`i'' -2) / ( `N`i'' -2)))
		scalar `d`s'tTotal`i'' = ( `d`s't1`i'' * `d`s't2`i'' )
		
		scalar `B`i''  = (`nut`i''*(`Mt`i''-1)+`nuc`i''*(`Mc`i''-1))
		scalar `At`i'' = ((`Nt`i''^2*`sqnt`i''+(`sqnt`i'')^2-2*`Nt`i''*`qnt`i'')/`Nt`i''^2)
		scalar `Ac`i'' = ((`Nc`i''^2*`sqnc`i''+(`sqnc`i'')^2-2*`Nc`i''*`qnc`i'')/`Nc`i''^2)
	
		scalar `A`i''  = (`At`i'' + `Ac`i'')
	
		scalar `v`s'term1Tot`i'' = (((`Nt`i''+`Nc`i'')/(`Nt`i''*`Nc`i''))*(1+(`nsimTotal`i''-1)*`ICC`s''))
		scalar `v`s'term2Tot`i'' = (((`N`i''-2)*(1-`ICC`s'')^2+`A`i''*`ICC`s''^2+2*`B`i''*`ICC`s''*(1-`ICC`s''))*`d`s'tTotal`i''^2)
		scalar `v`s'term3Tot`i'' = (2*(`N`i''-2)*((`N`i''-2)-`ICC`s''*(`N`i''-2-`B`i'')))
		scalar `s`s'teTot`i''    = sqrt(`v`s'term1Tot`i''+`v`s'term2Tot`i''/`v`s'term3Tot`i'')
		scalar `L`s'Btot`i''     = (`d`s'tTotal`i''-1.96*`s`s'teTot`i'') 
		scalar `U`s'Btot`i''		= (`d`s'tTotal`i''+1.96*`s`s'teTot`i'')
		matrix `Out`s'putTot`i'' = (round(`d`s'tTotal`i'',.01), round(`L`s'Btot`i'',.01), round(`U`s'Btot`i'',.01))
		
		scalar drop `sqnt`i'' `sqnc`i'' `qnt`i'' `qnc`i''
		
		matrix `Out`s'putG`i'' = ( `Out`s'put`i'' \ `Out`s'putTot`i'' )
		matrix rownames `Out`s'putG`i'' = "Within" "Total"
		matrix colnames `Out`s'putG`i'' = "Estimate" "95% LB" "95% UB"
		}
	}
	local g
	forvalues i = 1/`=`max'' {
		if "`=`refcat'+0'" != "``i''" {
		local g = `g' + 1
		
		matrix CondES``i'' = `Out1putG`g''
		local cond`g' CondES``i'' 
		matrix UncondES``i'' = `Out2putG`g''
		local uncond`g' UncondES``i'' 
		}
		}
	tempfile touseit
	save `touseit'
		
	   //====================================================//	
	  //===================                =================//	
	 //==================  PERMUTATIONS  ==================//
	//=================                ===================//
   //====================================================//
	
	if "`nperm'" != "0"  {
		tempname N_total from to sumnotconv sumconv
		clear
		use `crt'
		count
		scalar `N_total' = `r(N)'
		
			if `nperm'<1000 {
				display as error "error: nPerm must be greater than 1000"
				error 7
				}
		noisily di as txt "  Running Permutations..."
		scalar `sumnotconv'= 0
		scalar `sumconv'= 0
		scalar `from' = 1
		scalar `to' = `nperm'
				
		while `=`sumconv''!=`nperm' {
			
			if "`dot'" == "" {     
				noi disp as txt ""
				}
				if `=`sumnotconv''!=0 {
				noi di " Total of `=`sumnotconv'' models failed"
				noi di "  Running supplementary permutations..."
				}
				
		scalar `sumnotconv'= 0
								
            forvalues j = `=`from''/`=`to'' {
			if "`seed'" == "1020252" {
				local defseed = `=12890*`j'+1'
				set seed `defseed'
				}
			else {
				local seeds = `=`seed'*`j'+1'
				set seed `seeds'
				}
			if "`dot'" == "" {	
					if !mod(`j', 100) {
					noi di _c "`j'"
					}
				else {
					if !mod(`j', 10) {
						noi di _c "." 
						}
					}
				}
		capture {
			tempvar n shuffle
			keep `intervention' `random'
			collapse `intervention', by(`random')
			gen double `shuffle'=runiform()	
			mata funcsh("`intervention'","`shuffle'")
			tempfile clust
			save `clust'
			
			use `crt'
			merge m:1 `random' using `clust', update replace nogenerate
			
			`isily' mixed `depvar' i.`intervention' `indepvars' || `random':, `options' `maximization'
			matrix `b' = e(b)

			scalar `id_var_col' = colnumb(`b', "lns1_1_1:_cons")
			scalar `cluster_variance1' = exp(`b'[1, `id_var_col'])^2

			scalar `res_var_col' = colnumb(`b', "lnsig_e:_cons")
			scalar `res_variance1' = exp(`b'[1, `res_var_col'])^2
			scalar `Total1' = `res_variance1' + `cluster_variance1'

			scalar `ICC1' = `cluster_variance1'/`Total1'

			matrix `Coef' = `b'[1,1..`=`max'']

			mata funczero("`Coef'")
			matrix `Coef' = `Coef''
			clear
		
			use `crt'

	/*g.within*/
			forvalues s = 1/2 {
			
				forvalues i = 1/`=`max'-1' {
				tempname d`s'w`i'`j' d`s't1`i'`j' d`s'tTotal`i'`j'
					scalar `d`s'w`i'`j''        = `Coef'[`i',1]/sqrt(`res_variance`s'')
					scalar `d`s't1`i'`j''     = `Coef'[`i',1]/sqrt(`Total`s'')
					scalar `d`s't2`i''     = sqrt(1-`ICC`s''*(((`N`i''-`nut`i''*`Mt`i''-`nuc`i''*`Mc`i'')+`nut`i''+`nuc`i''-2)/(`N`i''-2)))
					scalar `d`s'tTotal`i'`j'' = (`d`s't1`i'`j''*`d`s't2`i'')
					}
				}
			scalar `sumconv' = `sumconv' + 1
				}/*capture*/
				if _rc==1 {
						exit 1
						}
				else if _rc!=0 {
				  scalar `sumnotconv' = `sumnotconv' + 1 
					 }
			clear
			use `touseit'
			} /*nperm*/
			scalar `from' = `=`to'' + 1
			scalar `to' = `=`to''+ `=`sumnotconv''
		} /*while*/
			forvalues s = 1/2 {
				forvalues j = 1/`nperm' {
					forvalues i = 1/`=`max'-1' {
						if `nperm'>`=`N_total'' {
							set obs `nperm'
							}
						capture gen double Perm`s'_T`i'_W=.
						capture gen double Perm`s'_T`i'_T=.
						capt replace Perm`s'_T`i'_W = `d`s'w`i'`j'' in `j'
						capt replace Perm`s'_T`i'_T = `d`s'tTotal`i'`j'' in `j'
						}
					}
				}
				/* Permutation Test*/
				
				forvalues s=1/2 {
					tempname pval_`s'
					local i
					
					matrix `pval_`s''=J(2,`=`max'-1',.)
					matrix rownames `pval_`s'' = "Within ES" "Total ES"
					matrix colnames `pval_`s'' = `rowname'
					
					forvalues j=1/`=`max'' {
						if "`=`refcat'+0'" != "``j''" {
						//local pcolnames `pcolnames' "Intervention``j''"
							local i = `i' + 1
							tempvar Wp`s'_`i' Tp`s'_`i'
							
							 gen `Wp`s'_`i'' = abs(Perm`s'_T`i'_W)>=abs(`d`s'w`i'')
							 summarize `Wp`s'_`i'', meanonly
							 matrix `pval_`s''[1,`i'] =round(r(mean),.01)
					 
							 gen `Tp`s'_`i'' = abs(Perm`s'_T`i'_T)>=abs(`d`s't1`i'')
							 summarize `Tp`s'_`i'', meanonly
							 matrix `pval_`s''[2,`i'] =round(r(mean),.01)
					}
				}
			}
			
			return matrix CondPv = `pval_1'
			return matrix UncondPv = `pval_2'
			
		if "`dot'" == "" {
			noi di as txt ""
			}
		noisily di as txt "  Permutations completed."
		tempfile crt
		save `crt'
		if "`paste'"!="" {
		local f
		forvalues i = 1/`=`max'' {
			if "`=`refcat'+0'" != "``i''" {
			local f = `f' + 1
			rename (Perm1_T`f'_W Perm2_T`f'_W Perm1_T`f'_T Perm2_T`f'_T) (PermC_I``i''_W PermUnc_I``i''_W PermC_I``i''_T PermUnc_I``i''_T )
			}
		}
		keep PermC_I*_W PermUnc_I*_W PermC_I*_T PermUnc_I*_T
		
		tempfile permES
		save `permES'
		use `Original'
		merge 1:1 _n using `permES', nogenerate
		tempfile Original
		save `Original'	
		}
		} /*if nperm is chosen*/
		
		
	   //====================================================//	
	  //====================              ==================//	
	 //===================	BOOTSTRAPS	===================//
	//==================              ====================//
   //====================================================//	
	
	if "`nboot'" != "0" {
	tempname N_total from to sumnotconv sumconv
		clear
		use `beta1'
		count
		scalar `N_total' = `r(N)'
		
		if `nboot'<1000 {
			display as error "error: nBoot must be greater than 1000"
			error 7
			}
				
		gettoken depvar indepvars: varlist
		set seed `seed'
		
		if "`residual'" != "" { 
			mata: rseed(strtoreal(st_local("`seed'")))
		
			tab `random'
			scalar `M'=r(r)
			
			forvalues i=1/2 {
				tempname resvar`i'
				
				summ `res`i'', meanonly
				replace `res`i''=`res`i''-r(mean)
				
				matrix `resvar`i''=`res_variance`i''
				mata: funcchol("`N_total'", "`resvar`i''", "`res`i''") /*reseffc local containing name(s) of residuals/reffects; covar needs to be matrix*/
				}
			
			tempfile beta1
			save `beta1'
			
				collapse `rIntercept1' `rIntercept2', by(`random')

			forvalues i=1/2 {
				
				summ `rIntercept`i'', meanonly
				replace `rIntercept`i''=`rIntercept`i''-r(mean)
				
				matrix `resvar`i''=`cluster_variance`i''
				
				mata: funcchol("`M'", "`resvar`i''", "`rIntercept`i''") /*reseffc local containing name(s) of residuals/reffects; covar needs to be matrix*/

				tempfile reff
				save `reff'
				}
			clear
			use `beta1'
			}
			
			

	
		noisily di as txt "  Running Bootstraps..."
		
		scalar `sumnotconv'= 0
		scalar `sumconv'= 0
		scalar `from' = 1
		scalar `to' = `nboot'
								
		while `=`sumconv''!=`nboot' {
			
			if "`dot'" == "" {     
				noi disp as txt ""
				}
				if `=`sumnotconv''!=0 {
				noi di " Total of `=`sumnotconv'' models failed"
				noi di "  Running supplementary bootstraps..."
				}
				
				scalar `sumnotconv'= 0
		
		forvalues j = `=`from''/`=`to'' {
			
			if "`dot'" == "" {	
					if !mod(`j', 100) {
					noi di _c "`j'"
					}
				else {
					if !mod(`j', 10) {
						noi di _c "." 
						}
					}
				}
		capture {
		if "`residual'" == "" {
			keep `varlist_clean' `intervention' `random'
			local countn: word count `case'
			if "`countn'"=="2" {
				bsample, cluster(`random')
				bsample, strata(`random')
				} 
			else if "`case'"=="2" {
				bsample, cluster(`random')
				} 
			else if "`case'"=="1" | "`case'"=="" {
				bsample, strata(`random')
				}
			}
			
		if "`residual'" != "" {
		
			mata: funcsamp("`res1' `res2'")
			tempfile beta2
			save `beta2'
			
			clear
			use `reff'

			mata: funcsamp("`rIntercept1' `rIntercept2'")
			
			merge 1:m `random' using `beta2', nogenerate
						
			replace `depvar'=`fitted2'+ `res2'+ `rIntercept2'
			} /*residual*/
			
			
			mixed `depvar' || `random':, `options' `maximization'
			matrix `b0' = e(b)
	
			scalar `id_var_col' = colnumb(`b0', "lns1_1_1:_cons")
			scalar `cluster_variance2' = exp(`b0'[1, `id_var_col'])^2

			scalar `res_var_col' = colnumb(`b0', "lnsig_e:_cons")
			scalar `res_variance2' = exp(`b0'[1, `res_var_col'])^2
			scalar `Total2' = `res_variance2' + `cluster_variance2'

			scalar `ICC2' = `cluster_variance2'/`Total2'
			
		if "`residual'" != "" {
			replace `depvar'=`fitted1'+ `res1'+ `rIntercept1'
			}
			`isily' mixed `depvar' i.`intervention' `indepvars' || `random':, `options' `maximization'
			matrix `b' = e(b)
			scalar `id_var_col' = colnumb(`b', "lns1_1_1:_cons")
			scalar `cluster_variance1' = exp(`b'[1, `id_var_col'])^2

			scalar `res_var_col' = colnumb(`b', "lnsig_e:_cons")
			scalar `res_variance1' = exp(`b'[1, `res_var_col'])^2
			scalar `Total1' = `res_variance1' + `cluster_variance1'

			scalar `ICC1' = `cluster_variance1'/`Total1'
			
			matrix list `b'
			matrix `Coef' = `b'[1,1..`=`max'']

			mata funczero("`Coef'")
			matrix `Coef' = `Coef''
			
			forvalues s = 1/2 {
				forvalues i=1/`=`max'-1' {
				tempname Within`s'_`i'`j' Total`s'_`i'`j' 
					scalar `Within`s'_`i'`j'' = `Coef'[`i',1]/sqrt(`res_variance`s'')
					scalar `Total`s'_`i'`j'' = `Coef'[`i',1]/sqrt(`Total`s'')
					}
				}
			
					scalar `sumconv' = `sumconv' + 1
						} /*capture*/
				if _rc==1 {
						exit 1
						}
				else if _rc!=0 {
				   scalar `sumnotconv' = `sumnotconv' + 1 
				 }
				 clear
				use `beta1'
				} /*nboot*/
			scalar `from' = `to' + 1
		scalar `to' = `to'+ `sumnotconv'
		} /*while*/
						
		forvalues s = 1/2 {
			forvalues j = 1/`nboot' {	
				forvalues i = 1/`=`max'-1' {
					if `nboot'>`=`N_total'' {
						set obs `nboot'
						}
					capture gen double Boot`s'_T`i'_W=.
					capture gen double Boot`s'_T`i'_T=.
					capt replace Boot`s'_T`i'_W = `Within`s'_`i'`j'' in `j'
					capt replace Boot`s'_T`i'_T = `Total`s'_`i'`j'' in `j'
					}
				}
			}
		if "`ci'" == "basic" {	
		forvalues s = 1/2 {
			forvalues i = 1/ `=`max'-1' {
			tempname W`s'_25_`i' W`s'_975_`i' T`s'_25_`i' T`s'_975_`i'
			
				centile Boot`s'_T`i'_W, centile(2.5)
				scalar `W`s'_975_`i''	=2*`d`s'w`i''-r(c_1) /*scalars assigned in reverse order to respect basic (Hall's) CI formula.*/
				centile Boot`s'_T`i'_W, centile(97.5)
				scalar `W`s'_25_`i''	=2*`d`s'w`i''-r(c_1)
			
				centile Boot`s'_T`i'_T, centile(2.5)
				scalar `T`s'_975_`i''	=2*`d`s't1`i''-r(c_1)
				centile Boot`s'_T`i'_T, centile(97.5)
				scalar `T`s'_25_`i''	=2*`d`s't1`i''-r(c_1)
				}
			}
		}
		if "`ci'" == "percentile" {	
		forvalues s = 1/2 {
			forvalues i = 1/ `=`max'-1' {
			tempname W`s'_25_`i' W`s'_975_`i' T`s'_25_`i' T`s'_975_`i'
			
				centile Boot`s'_T`i'_W, centile(2.5)
				scalar `W`s'_25_`i''	=r(c_1)
				centile Boot`s'_T`i'_W, centile(97.5)
				scalar `W`s'_975_`i''	=r(c_1)
			
				centile Boot`s'_T`i'_T, centile(2.5)
				scalar `T`s'_25_`i''	=r(c_1)
				centile Boot`s'_T`i'_T, centile(97.5)
				scalar `T`s'_975_`i''	=r(c_1)
				}
			}
		}
		forvalues s = 1/2 {
			forvalues i = 1/`=`max'-1' {
			tempname W`s'_`i' T`s'_`i' F`s'_`i' 
				matrix `W`s'_`i'' 		= (round(`d`s'w`i'',.01),round(`W`s'_25_`i'',.01),round(`W`s'_975_`i'',.01))
				matrix `T`s'_`i'' 		= (round(`d`s'tTotal`i'',.01),round(`T`s'_25_`i'',.01),round(`T`s'_975_`i'',.01))
				matrix `F`s'_`i'' 		= `W`s'_`i'' \ `T`s'_`i''

				matrix rownames `F`s'_`i'' = "Within" "Total"
				matrix colnames `F`s'_`i'' = "Estimate" "95% (BT)LB" "95% (BT)UB"
				}
			}
		forvalues i = 1/ `=`max'-1' {
			matrix `cond`i'' = `F1_`i'' 
			matrix `uncond`i'' = `F2_`i'' 
			}
		if "`paste'"!="" {
		local m
		forvalues i = 1/`=`max'' {
			if "`=`refcat'+0'" != "``i''" {
			local m = `m' + 1
			rename (Boot1_T`m'_W Boot2_T`m'_W Boot1_T`m'_T Boot2_T`m'_T) (BootC_I``i''_W BootUnc_I``i''_W BootC_I``i''_T BootUnc_I``i''_T )
			}
		}
		keep BootC_I*_W BootC_I*_T BootUnc_I*_W BootUnc_I*_T
		tempfile results
		save `results'
		use `Original'
		merge 1:1 _n using `results', nogenerate
		tempfile Original
		save `Original'
		}
		if "`dot'" == "" {
			noi di as txt ""
			}
		noi di as txt "  Bootstraps completed."
		} /*if nboot*/
	
			/*TABLES*/
	
	capture {
		noisily {
			return matrix Beta = `Beta'

			return matrix Cov = `Cov'

			return matrix SchEffects = `schRand'
		
			forvalues i = 1/`=`max'-1' {
		
				matrix list `cond`i''
				return matrix `cond`i'' = `cond`i''
		 
				matrix list `uncond`i''
				return matrix `uncond`i'' = `uncond`i''
			}
		}
	}
	clear
	use `Original'
	restore, not
	}	
end

capture program drop baseset
program define baseset, rclass
syntax, max(name) INTervention(varlist fv)

	if regexm("`intervention'", "bn\.") | regexm("`intervention'", "^i\(?([0-9] ?)+\)?\.") {
	noi disp as error "i(numlist) not allowed; you must specify a base level"
	error 198
	}

	local refcat
	if regexm("`intervention'", "([0-9]?)[ ]*\.") local refcat = regexs(1) 
	local allow opt1
		
	if "`refcat'" == "" {
		if regexm("`intervention'", "\(\#*([0-9]?)\)[ ]*\.") local refcat = regexs(1)
		if "`refcat'"!="" local allow opt2
	}
	if "`refcat'" == "" {
		if regexm("`intervention'", "\(([a-zA-Z]+)*\)\.") local refcat = regexs(1)
		if "`refcat'"!="" local allow opt3
		}
	
	fvrevar `intervention', list
	local intervention `r(varlist)'

	levelsof `intervention', local(levels)
	tokenize `levels'
	
	tempname min Max
	scalar `min'=`1'
	scalar `Max' = ``=`max'''
	
	if "`allow'" == "opt1" { 
		forvalues i=1/`=`max'' {
			cap if "`refcat'" != "``i''" local s = `s'+1 /*checking cases were intervention is irregular (i.e. 1 4 9) and user has specified a number of baseline that is not 1,4 or 9 and not below 1 and not above 9*/
			}
		if "`refcat'" != "" {
			if "`refcat'">"`=`Max''" | "`refcat'"<"`=`min''" | "`s'" == "`=`max''" {
			noi disp as error "{bf:Warning:} selected baseline level `refcat' is out of bounds; level `=`Max'' chosen instead"
				}
			}
		else {
			local refcat = `=`min''
		}
		if "`s'" == "`=`max''" & "`refcat'" != "`=`min''" {
			local refcat = `=`Max''
			}
	
		if "`refcat'" != "" {
		fvset base `refcat' `intervention'
		}
	}
	else if "`allow'"=="opt2" {
		fvset base ``refcat'' `intervention'
		local refcat = ``refcat''
		}
	else if "`allow'"=="opt3" {
		fvset base `refcat' `intervention'
		if strpos("`refcat'","first") >0 {
		local refcat = `=`min''
		}
		if strpos("`refcat'","last") >0 {
		local refcat = `=`Max''
		}
		if strpos("`refcat'","freq")>0 {
		tempname maximum z
		tab `intervention', matcell(`maximum')
		mata funcmax("`maximum'")
		
		forvalues i = 1/`=`max''{
		scalar `z' = `maximum'[`i',1]
		if "`matr'"== "`=`z''" local refcat = ``i''
				}
			}
		}
		return local refcat = `refcat'
		end
		
		
