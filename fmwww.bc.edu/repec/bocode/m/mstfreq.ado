*! version 1.1.0  25feb2022
capture program drop mstfreq
program define mstfreq, rclass
version 15.1

syntax varlist(numeric fv) [if] [in], INTervention(varlist numeric fv max=1) RANdom(varlist numeric max=1) [, NPerm(integer 0) NBoot(integer 0) SEED(integer 1020252) noDOT noIsily ML REML CASE(numlist asc >0 max=2) RESidual PERCentile BASIC PASTE *]

quietly {       
        
        preserve
		if "`paste'"!="" {
        if "`nperm'" != "0" {
        cap drop PermC_I*_W PermC_I*_T PermUnc_I*_W PermUnc_I*_T
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
        
        local maximization reml
        if "`ml'" != "" & "`reml'" != "" {
        noi disp as error "ml and reml may not be specified at the same time"
        error 198
        }
        if "`ml'" != "" {
                local maximization
                }
        
        tempname chk test0 test1 Beta1 Beta Cov X UschCov schCov schRand max chk b0 id_var_col1 cluster1_variance1 res_var_col res_variance1 Nu lvl res_variance2 vcovschTrt1 varB31 ///
        varB32 vcovschTrt2 b failtest group_max mstNt colnumber min Max tot1 res_star1 res_dfl1 tot2 res_star2 res_dfl2 coef summed xrecov1 xrecov2 sumvarB21 sumvarB22 sums
        tempvar res1 ressq1 res_refl1 res2 ressq2 res_refl2 fitted1 fitted2 EstmReff EstmReff_unc EstmReff_unc_sq1 brokn_fctor   /*set temporary variables/matrices/scalars to be used*/

        tempfile mst
        save `mst'
		
        tab `random'
        scalar `group_max' = r(r) /*number of groups*/
		tab `intervention'
        scalar `max' = r(r) 
		
        tab `random' `intervention', matcell(`chk')

		mata: st_numscalar("`chk'", colsum(rowsum(st_matrix("`chk'"):>0):>1)) 
		if `chk'==0 {
		display as error "error: This is not an MST design"
		error 459
		}

        
        baseset, max(`max') intervention(`intervraw')
        local refcat `r(refcat)'
        tempfile mst 
        save `mst'
        
        levelsof `intervention', local(levels)
        tokenize `levels'
        
        foreach i of numlist 1/`=`max''{
                if "`=`refcat'+0'" != "``i''" {
                        local rowname `rowname' "`intervention'``i''"
                        local spart `spart' `brokn_fctor'`i'
                        }
                else {
                local fpart `fpart' `brokn_fctor'`i'
                }
                }
        
        gettoken depvar indepvars: varlist
        tab `intervention', gen(`brokn_fctor')
        
        unab broken_treatment : `brokn_fctor'*
        rename (`fpart' `spart') (`broken_treatment')
        gettoken baseline rest: broken_treatment /*separate between baseline(0) and rest*/
        
        tempfile mst2
        save `mst2'
        
        /*Unconditional Model*/
        mixed `depvar' || `random':, `options' `maximization' /*NOTE: CONDITIONAL IS DENOTED WITH SUFFIX 2, UNCONDITIONAL WITH SUFFIX 1*/
        matrix `b0' = e(b)
		
        
        scalar `id_var_col1' = colnumb(`b0', "lns1_1_1:_cons")
        matrix `cluster1_variance1' = exp(`b0'[1, `id_var_col1'])^2  /*this gives var.B31=> cluster1..`=`max'-1'_variance1*/
                
        
        scalar `res_var_col' = colnumb(`b0', "lnsig_e:_cons")
        scalar `res_variance1' = exp(`b0'[1, `res_var_col'])^2 /*this gives var.W*/
        
        scalar `Nu' = e(N)                                       /*number of obs*/
		
        predict `fitted1'
		predict `res1', res
		predict `EstmReff_unc'*, reffects
        estat recovariance
        scalar `lvl' = r(relevels)
        matrix `xrecov1' = r(Cov`=`lvl'')         /*covariance matrix*/
        scalar `vcovschTrt1' = `xrecov1'[1,1]
        
		
        forvalues i =1/`=`max'-1' {
		tempname Br_F`i' MSTnt`i' sumBr_F`i'
                tab `random' `brokn_fctor'`=`i'+1', matcell(`Br_F`i'')  /*for 3 arms, `=`max'-1' = 2 , broken factor is 1,2,3 but we only need 2,3*/
                mata: functot("`Br_F`i''","`sumBr_F`i''") /*ensures it sums the N for ones (1) not zeros (0), all matrices Br_F#1 are for zeros*/
				matrix `MSTnt`i'' =`sumBr_F`i''[1,2] /*store sum in matrix*/
                }
				
		matrix `sums'=J(`=`max'-1',2,.)
		forvalues i=1/`=`max'-1'{
			forvalues k=1/2 {
				matrix `sums'[`i',`k']=`sumBr_F`i''[1,`k'] 
				}
			}
                
        matrix `mstNt' = `MSTnt1'
        matrix `varB31' = `cluster1_variance1'
        if `=`max'-1'>1 {
                foreach i of numlist 2/`=`max'-1' {
                        matrix `mstNt' = `mstNt' ,`MSTnt`i'' /*MSTnt`i' = nt`i' (MSTnt`i' is for conditional and nt`i' for the unconditional (see subprogram gUncondMSTNEW)*/
                        }
                }
		
        /*Conditional Model*/
        `isily' mixed `depvar' i.`intervention' `indepvars' || `random':`rest', cov(unstructured) `options' `maximization'
        matrix `b' = e(b)
	    
		
        matrix `test0' = r(table)[1...,1.."`depvar':_cons"] /*remove baseline category of intervention*/
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
		
		predict `fitted2'
		predict `res2', res
        predict `EstmReff'*, reffects
		
		tempfile beta1
        save `beta1'
        
        forvalues i=1/`=`max'' {
        tempname id_var_col`i' cluster`i'_variance2 
                scalar `id_var_col`i'' = colnumb(`b', "lns1_1_`i':_cons")
                matrix `cluster`i'_variance2' = exp(`b'[1, `id_var_col`i''])^2 
                }
        
        scalar `res_var_col' = colnumb(`b', "lnsig_e:_cons")
        scalar `res_variance2' = exp(`b'[1, `res_var_col'])^2 
        
        
        estat recovariance
        scalar `lvl' = r(relevels)
        matrix `xrecov2' = r(Cov`=`lvl'')
        matrix `vcovschTrt2' = `xrecov2'[`=`max'',1..`=`max'-1']
        
        matrix `schCov' = `xrecov2'
        mata funcround("`schCov'")   
		
        matrix rownames `schCov' = `rowname' "Intercept"
        matrix colnames `schCov' = `rowname' "Intercept"
        
                
        matrix `varB32' = `cluster1_variance2'
        if `=`max'-1'>1 {
                foreach i of numlist 2/`=`max'-1' {
                        matrix `varB32' = `varB32' , `cluster`i'_variance2'
                        }
                }
                
        mata:  hfunc1("`mstNt'", "`Nu'","`varB32'", "`vcovschTrt2'","`xrecov2'","`sumvarB22'","`summed'")  /*calls mata to produce "sumvarB2" and "summed"=sum(N.t/N*(var.B3+2*vcov.schTrt))*/
        
        tempname varSch1 varSch2 varTT1 varTT2
		scalar `sumvarB21'=`xrecov1'[1,1] 
        scalar `varSch1' =  `xrecov1'[1,1] 
        scalar `varSch2' =  `xrecov2'[`=`max'',`=`max'']
        scalar `varTT2' = `varSch2' + `res_variance2' + `summed' /*THIS IS EQUIVALENT TO vartt in R*/
        scalar `varTT1' = `varSch1' + `res_variance1'          /*THIS IS EQUIVALENT TO vartt1 in R*/
        forvalues s = 1/2 {
                tempvar ICC`s'
                scalar `ICC`s'' = `sumvarB2`s'' / `varTT`s''
                }
        cap scalar drop `sumvarB21' `sumvarB22' `summed'
        
                /*ICC1 IN STATA IS EQUIVALENT TO ICC2 IN R*/
                /*ICC2 IN STATA IS EQUIVALENT TO ICC1 IN R*/
        
        matrix `coef' = `b'[1,1..`=`max'']
        mata: funczero("`coef'")
        
        matrix `coef' = `coef'' 
        clear

        use `beta1'
        collapse `EstmReff'*, by(`random')
        mkmat `EstmReff'* `random', matrix(`schRand')

        mata funcround("`schRand'") 
        matrix colname `schRand' = `rowname' "Intercept" "School"

        clear
        use `mst'

       local m
		forvalues i = 1/`=`max'-1' {
		tempname CondES`i'
        gCondMST, res_variance2(`res_variance2') vartt2(`varTT2') group_max(`group_max') max(`max') varb32(`varB32') brf(`Br_F`i'') i(`i') coef(`coef')
		matrix `CondES`i''=r(CondES`i')
		}
		forvalues i = 1/`=`max'' {
		if "`=`refcat'+0'" != "``i''" {
		local m = `m' + 1
		
		matrix CondES``i'' = `CondES`m'' 
		local cond`m' CondES``i''
		}
		}
		
                
        tab `intervention', gen(`brokn_fctor')
        unab broken_treatment:`brokn_fctor'*
        rename (`fpart' `spart') (`broken_treatment') /*rename broken_factors based on new ref category (i.e. broken2 broken1 broken3 to broken1 broken2 broken3)*/
        
        
        gUncondMST, rand(`random') res_variance1(`res_variance1') res_variance2(`res_variance2') vartt2(`varTT2') vartt1(`varTT1') group_max(`group_max') ///
        max(`max') icc1(`ICC1') icc2(`ICC2') varb31(`varB31') sums(`sums') coef(`coef') brokn_fctor(`brokn_fctor') /*see sub-programs*/
        
        local m
        forvalues i = 1/`=`max'' {
                if "`=`refcat'+0'" != "``i''" {
                local m = `m' + 1
                
                matrix UncondES``i'' = r(UncondES`m') 
                local uncond`m' UncondES``i'' 
                }
                }
                
        
        matrix `UschCov' = round(r(UschCov)[1,1],.01)
        matrix rownames `UschCov' = "Intercept"
        matrix colnames `UschCov' = "Unconditional"
        
        matrix `Cov' = r(Cov)
        
        drop `brokn_fctor'*
        matrix drop `coef'
        
        tempfile touseit
        save `touseit'
       
    //====================================================//    
   //===================                =================//
  //==================  PERMUTATIONS  ==================//
 //=================                ===================//
//====================================================//
        
        if "`nperm'" != "0"  {
                tempname N_total from to sumnotconv sumconv
                count
                scalar `N_total' = `r(N)'
               
                levelsof `random', local(levels)
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
                        keep `random' `intervention'
                        tempvar rand1 rand2
                        gen double `rand1'=.
                        gen double `rand2'=.
                        foreach `random' in `levels' {
                                replace `rand1' = runiform() if `random' == ``random'' /*Stata randomnization produces less combinations than R*/
                                replace `rand2' = runiform() if `random' == ``random'' /*randomize twice for better randomnization. */
                                }
                        sort `random' `rand1' `rand2'
                        drop `rand1' `rand2'
                        tempfile clust
                        save `clust'
                        merge 1:1 _n using `touseit', nogenerate
                        tempfile permES
                        save `permES'
                         
                        mixed `depvar' || `random':, `options' `maximization'
                        matrix `b0' = e(b)
                        
                       
                        
                                scalar `id_var_col1' = colnumb(`b0', "lns1_1_1:_cons")
                                matrix `cluster1_variance1' = exp(`b0'[1, `id_var_col1'])^2  
                                
                
                                scalar `res_var_col' = colnumb(`b0', "lnsig_e:_cons")
                                scalar `res_variance1' = exp(`b0'[1, `res_var_col'])^2 
                                
                                
                                scalar `Nu'= e(N) 
                
                                estat recovariance
                                scalar `lvl' = r(relevels)
                                matrix `xrecov1' = r(Cov`=`lvl'')
                                matrix `vcovschTrt1' = `xrecov1'[1,1]
                                
                                tab `intervention', gen(`brokn_fctor')
                                rename (`fpart' `spart') (`broken_treatment')
                
                                matrix `varB31' = `cluster1_variance1'
                                
                        
                                
						`isily' mixed `depvar' i.`intervention' `indepvars' || `random': `rest', cov(unstructured) `options' `maximization'
                        matrix `b' = e(b)
                
        
                        
                                forvalues i=1/`=`max'' {
                                        tempname id_var_col`i' cluster`i'_variance2  
                                        scalar `id_var_col`i'' = colnumb(`b', "lns1_1_`i':_cons")
                                        matrix `cluster`i'_variance2' = exp(`b'[1, `id_var_col`i''])^2  
                                        }
                        
                                scalar `res_var_col' = colnumb(`b', "lnsig_e:_cons")
                                scalar `res_variance2' = exp(`b'[1, `res_var_col'])^2 /*this gives var.W*/
                                
                                estat recovariance
                                scalar `lvl' = r(relevels)
                                matrix `xrecov2' = r(Cov`=`lvl'')
                                matrix `vcovschTrt2' = `xrecov2'[`=`max'',1..`=`max'-1']

                        
                                matrix `varB32' = `cluster1_variance2'
                                if `=`max'-1'>1 {
                                        foreach i of numlist 2/`=`max'-1' {
                                                matrix `varB32' = `varB32' ,`cluster`i'_variance2'
                                                }
                                        }
								mata: hfunc1("`mstNt'", "`Nu'","`varB32'", "`vcovschTrt2'","`xrecov2'","`sumvarB22'","`summed'")
                                scalar `sumvarB21'=`xrecov1'[1,1] 
                                scalar `varSch1' =  `xrecov1'[1,1] 
                                scalar `varSch2' =  `xrecov2'[`=`max'',`=`max'']
                                scalar `varTT2' = `varSch2' + `res_variance2' + `summed' /*THIS IS EQUIVALENT TO vartt in R*/
                                
                                scalar `varTT1' = `varSch1' + `res_variance1'           /*THIS IS EQUIVALENT TO vartt1 in R*/
                                forvalues s = 1/2 {
                                        scalar `ICC`s'' = `sumvarB2`s'' / `varTT`s''
                                        }
                                
                                cap matrix drop `xrecov1' `xrecov2' 
                                cap scalar drop `sumvarB21' `sumvarB22' `summed'
                                
                                /*ICC1 IN STATA IS EQUIVALENT TO ICC2 IN R*/
                                /*ICC2 IN STATA IS EQUIVALENT TO ICC1 IN R*/
                        
                                matrix `coef' = `b'[1,1..`=`max'']
                                mata: funczero("`coef'")
        
                                matrix `coef' = `coef''
                                
                                clear
                                use `permES'
                                
                                tab `intervention', gen(`brokn_fctor')
                                rename (`fpart' `spart') (`broken_treatment')
								
                                forvalues i = 1/`=`max'-1' {
									tempname dwC`i'`j' dtTotalC`i'`j' dwU`i'`j' dtTotalU`i'`j'
								
									gCondUncondMST, i(`i') j(`j') in(`intervention') rand(`random') res_variance1(`res_variance1') res_variance2(`res_variance2') ///
									group_max(`group_max') max(`max') vartt1(`varTT1') vartt2(`varTT2') icc1(`ICC1') sums(`sums') coef(`coef') brokn_fctor(`brokn_fctor')
							
									scalar `dwC`i'`j'' = r(dwC`i'`j')
									scalar `dtTotalC`i'`j'' = r(dtTotalC`i'`j')
													
									scalar `dwU`i'`j'' = r(dwU`i'`j')
									scalar `dtTotalU`i'`j'' = r(dtTotalU`i'`j')
									}
                        
                                matrix drop `coef'
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
                if "`dot'" == "" {     
                                noi disp as txt ""
                                }
                noisily di as txt "  Permutations completed."
                
                tempname permutations   
                forvalues j = 1/`=`to'' {
                        forvalues i = 1/`=`max'-1' {
                                if `=`to''>`=`N_total'' {
                                        set obs `=`to''
                                        }
                                capture gen double PermC_I`i'_W=.
                                capture gen double PermC_I`i'_T=.
                                capture replace PermC_I`i'_W = `dwC`i'`j'' in `j'
                                capture replace PermC_I`i'_T = `dtTotalC`i'`j'' in `j' /*plug in estimates*/
                                                
                                capture gen double PermUnc_I`i'_W=.
                                capture gen double PermUnc_I`i'_T=.
                                capture replace PermUnc_I`i'_W = `dwU`i'`j'' in `j'
                                capture replace PermUnc_I`i'_T = `dtTotalU`i'`j'' in `j'
                                }                       
                        }
						
				/* Permutation Test*/
				
					tempname pval_C pval_U
					
					matrix `pval_C'=J(2,`=`max'-1',.)
					matrix `pval_U'=J(2,`=`max'-1',.)
					
					matrix rownames `pval_C' = "Within ES" "Total ES"
					matrix colnames `pval_C' = `rowname'
					
					matrix rownames `pval_U' = "Within ES" "Total ES"
					matrix colnames `pval_U' = `rowname'
					
					forvalues j=1/`=`max'' {
						if "`=`refcat'+0'" != "``j''" {
						//local pcolnames `pcolnames' "Intervention``j''"
							local i = `i' + 1
							tempvar WpC_`i' TpC_`i' WpU_`i' TpU_`i'
							
							 gen `WpC_`i'' = abs(PermC_I`i'_W)>=abs(d2w`i')
							 summarize `WpC_`i'', meanonly
							 matrix `pval_C'[1,`i'] =round(r(mean),.01)
					 
							 gen `TpC_`i'' = abs(PermC_I`i'_T)>=abs(dt2Total`i')
							 summarize `TpC_`i'', meanonly
							 matrix `pval_C'[2,`i'] =round(r(mean),.01)
							 
							 gen `WpU_`i'' = abs(PermUnc_I`i'_W)>=abs(d2w`i')
							 summarize `WpU_`i'', meanonly
							 matrix `pval_U'[1,`i'] =round(r(mean),.01)
					 
							 gen `TpU_`i'' = abs(PermUnc_I`i'_T)>=abs(dt1Total`i')
							 summarize `TpU_`i'', meanonly
							 matrix `pval_U'[2,`i'] =round(r(mean),.01)
					}
				}
			
			
			return matrix CondPv = `pval_C'
			return matrix UncondPv = `pval_U'
						if "`paste'"!="" {
                        local m
                        forvalues i = 1/`=`max''{
                                if "`=`refcat'+0'" != "``i''" {
                                        local m = `m' + 1
                                        rename (PermC_I`m'_W PermUnc_I`m'_W PermC_I`m'_T PermUnc_I`m'_T) (PermC_I``i''_W PermUnc_I``i''_W PermC_I``i''_T PermUnc_I``i''_T)
                                        }
                                }
                        
                        keep PermC_I*_W PermUnc_I*_W PermC_I*_T PermUnc_I*_T
                        tempfile origperm
                        save `origperm'
                                                
                        use `Original'
                        merge 1:1 _n using `origperm', nogenerate
                        tempfile Original
                        save `Original' 
						}
                        }/*if nperm*/
                
        
        
        
		    //====================================================//
		   //====================              ==================// 
		  //===================  BOOTSTRAPS  ===================//
		 //==================              ====================//
		//====================================================//   

                if "`nboot'" != "0" {
					tempname N_total from to sumnotconv sumconv
                        clear
						//use `mst'
                        use `beta1'
                        count
                        scalar `N_total' = `r(N)'
                      

                        if `nboot'<1000 {
                                display as error "error: nBoot must be greater than 1000"
                                error 7
                                }
        
                        set seed `seed'
						
						if "`residual'" != "" { 
							mata: rseed(strtoreal(st_local("`seed'")))

							tempname tot_reff1 EstmReff_unc_sq_star1 EstmReff_unc_sq_star_dfl1 tot_reff2 EstmReff_sq_star2 EstmReff_sq_star_dfl2
							tempvar EstmReff_sq`=`max'' EstmReff_sq_star_refl2
								
								forvalues i=1/2 {
									tempname resvar`i'
									
									summ `res`i'', meanonly
									replace `res`i''=`res`i''-r(mean)
									
									matrix `resvar`i''=`res_variance`i''
									mata: funcchol("`N_total'", "`resvar`i''", "`res`i''") /*reseffc local containing name(s) of residuals/reffects; covar needs to be matrix*/
									}
								
								tempfile beta1
								save `beta1'
								
								collapse `EstmReff_unc'* `EstmReff'*, by(`random')
								
								unab Estm_1Reff : `EstmReff_unc'*
								unab Estm_2Reff : `EstmReff'*
								
								forvalues i=1/2 {
									foreach v of local Estm_`i'Reff {
									summ `v', meanonly
									replace `v'=`v'-r(mean)
									
									local plusEstmReff_`i' `plusEstmReff_`i'' + `v'
									}
									
									mata: funcchol("`group_max'", "`xrecov`i''", "`Estm_`i'Reff'") /*reseffc local containing name(s) of residuals/reffects; covar needs to be matrix*/

									tempfile reff
									save `reff'
									}
								
								clear
								use `beta1'
							}/*residual*/
                                
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
                                gettoken depvar indepvars: varlist
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
                                if "`residual'"!="" {
								mata: funcsamp("`res1' `res2'")
									tempfile beta2
									save `beta2'
									
									clear
									use `reff'

									mata: funcsamp("`Estm_1Reff' `Estm_2Reff'")
									
									merge 1:m `random' using `beta2', nogenerate
												
									replace `depvar'=`fitted1'+ `res1'+ `Estm_1Reff'
									}
								
							
                                mixed `depvar' || `random':, `options' `maximization'
                                matrix `b0' = e(b)
                        
                                
                                        scalar `id_var_col1' = colnumb(`b0', "lns1_1_1:_cons")
                                        matrix `cluster1_variance1' = exp(`b0'[1, `id_var_col1'])^2
                                
                        
                                        scalar `res_var_col' = colnumb(`b0', "lnsig_e:_cons")
                                        scalar `res_variance1' = exp(`b0'[1, `res_var_col'])^2 /*this gives var.W*/
                        
                                        scalar `Nu'= e(N) /*number of obs*/
                        
                                        estat recovariance
                                        scalar `lvl' = r(relevels)
                                        matrix `xrecov1' = r(Cov`=`lvl'')
                                        matrix `vcovschTrt1' = `xrecov1'[1,1]
                        
										capt drop `brokn_fctor'*
                                        tab `intervention', gen(`brokn_fctor')
                                        rename (`fpart' `spart') (`broken_treatment')
                                        matrix `mstNt' = `MSTnt1'
										matrix `varB31' = `cluster1_variance1'
										if `=`max'-1'>1 {
											foreach i of numlist 2/`=`max'-1' {
													matrix `mstNt' = `mstNt' ,`MSTnt`i''
													}
											}
								
                                if "`residual'"!="" {
									replace `depvar'=`fitted2' + `res2' `plusEstmReff_2'
								}
								
								
								
								`isily' mixed `depvar' i.`intervention' `indepvars' || `random':`rest', cov(unstructured) `options' `maximization'
                                matrix `b' = e(b)
                                        
                                        
                                
                                        forvalues i=1/`=`max'' {
                                                scalar `id_var_col`i'' = colnumb(`b', "lns1_1_`i':_cons")
                                                matrix `cluster`i'_variance2' = exp(`b'[1, `id_var_col`i''])^2 
                                                }
                                
                                        scalar `res_var_col' = colnumb(`b', "lnsig_e:_cons")
                                        scalar `res_variance2' = exp(`b'[1, `res_var_col'])^2 /*this gives var.W*/

                                
                                        estat recovariance
                                        scalar `lvl' = r(relevels)
                                        matrix `xrecov2' = r(Cov`=`lvl'')
                                        matrix `vcovschTrt2' = `xrecov2'[`=`max'',1..`=`max'-1']

                                        matrix `varB32' = `cluster1_variance2'
                                        if `=`max'-1'>1 {
                                                foreach i of numlist 2/`=`max'-1' {
                                                        matrix `varB32' = `varB32' ,`cluster`i'_variance2'
                                                        }
                                                }
                                
                                        mata: hfunc1("`mstNt'", "`Nu'","`varB32'", "`vcovschTrt2'","`xrecov2'","`sumvarB22'","`summed'")
										scalar `sumvarB21'=`xrecov1'[1,1] 
										scalar `varSch1' =  `xrecov1'[1,1] 
										scalar `varSch2' =  `xrecov2'[`=`max'',`=`max'']
										scalar `varTT2' = `varSch2' + `res_variance2' + `summed' /*THIS IS EQUIVALENT TO vartt in R*/
										
										scalar `varTT1' = `varSch1' + `res_variance1'           /*THIS IS EQUIVALENT TO vartt1 in R*/
										forvalues s = 1/2 {
												scalar `ICC`s'' = `sumvarB2`s'' / `varTT`s''
												}
										
										
                                                
                                        matrix `coef' = `b'[1,1..`=`max'']
                                        mata: funczero("`coef'")
        
                                        matrix `coef' = `coef''
                                
										
											forvalues s = 1/2 {
													forvalues i=1/`=`max'-1' {
															tempname Within`s'_`i'`j' Total`s'_`i'`j'
															scalar `Within`s'_`i'`j'' = `coef'[`i',1]/sqrt(`res_variance`s'')
															scalar `Total`s'_`i'`j'' = `coef'[`i',1]/sqrt(`varTT`s'')										
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
                        
					
                        if "`dot'" == "" {     
                                noi disp as txt ""
                                }
                        noisily di as txt "  Bootstraps completed."
                        forvalues s = 1/2 {
                                forvalues j = 1/`=`to'' {       
                                        forvalues i = 1/`=`max'-1' {
                                                if  `=`to''>`=`N_total'' {
                                                        set obs `=`to''
                                                        }
                                                cap gen double Boot`s'_T`i'_W=.
                                                cap gen double Boot`s'_T`i'_T=.
                                                cap replace Boot`s'_T`i'_W = `Within`s'_`i'`j'' in `j'
                                                cap replace Boot`s'_T`i'_T = `Total`s'_`i'`j'' in `j'
                                                }
                                        }
                                }
						
						
                        capture {
						
							if "`ci'"=="percentile" { 
                                forvalues s = 1/2 {
                                        forvalues i = 1/ `=`max'-1' {
                                                tempname  W`s'_25_`i' W`s'_975_`i' T`s'_25_`i' T`s'_975_`i'
                                                centile Boot`s'_T`i'_W, centile(2.5)                                             /*quantiles*/
                                                scalar `W`s'_25_`i''    =r(c_1)
                                                centile Boot`s'_T`i'_W, centile(97.5)
                                                scalar `W`s'_975_`i''   =r(c_1)

                                                centile Boot`s'_T`i'_T, centile(2.5)
                                                scalar `T`s'_25_`i''    =r(c_1)
                                                centile Boot`s'_T`i'_T, centile(97.5)
                                                scalar `T`s'_975_`i''   =r(c_1)
                                                }
                                        }
									}
										
							if "`ci'"=="basic" { 
                                forvalues s = 1/2 {
                                        forvalues i = 1/ `=`max'-1' {
                                                tempname  W`s'_25_`i' W`s'_975_`i' T`s'_25_`i' T`s'_975_`i'
                                                centile Boot`s'_T`i'_W, centile(2.5)                                             /*quantiles*/
                                                scalar `W`s'_975_`i''  = 2*d`s'w`i'-r(c_1) /*scalars assigned in reverse order to respect basic (Hall's) CI formula*/
                                                centile Boot`s'_T`i'_W, centile(97.5)
                                                scalar `W`s'_25_`i''   = 2*d`s'w`i'-r(c_1)

                                                centile Boot`s'_T`i'_T, centile(2.5)
                                                scalar `T`s'_975_`i''  = 2*dt`s'Total`i'-r(c_1)
                                                centile Boot`s'_T`i'_T, centile(97.5)
                                                scalar `T`s'_25_`i''   = 2*dt`s'Total`i'-r(c_1)
                                                }
                                        }
										}
                                } /*capture*/
                                if _rc==1 {
                                        exit 1
                                        }
                        forvalues i = 1/`=`max'-1' {
                                tempname WC_`i' TC_`i' WU_`i' TU_`i'
                                matrix `WC_`i''                 = (round(d2w`i',.01),round(`W2_25_`i'',.01),round(`W2_975_`i'',.01))
                                matrix `TC_`i''                 = (round(dt2Total`i',.01),round(`T2_25_`i'',.01),round(`T2_975_`i'',.01))
                                matrix CondES`i'                = `WC_`i'' \ `TC_`i''

                                matrix rownames CondES`i' = "Within" "Total"
                                matrix colnames CondES`i' = "Estimate" "95% (BT)LB" "95% (BT)UB"
                                
                                scalar drop d2w`i' dt2Total`i'
                                }
                                                                
                        forvalues i = 1/`=`max'-1' {
                                matrix `WU_`i''                 = (round(d1w`i',.01),round(`W1_25_`i'',.01),round(`W1_975_`i'',.01))
                                matrix `TU_`i''                 = (round(dt1Total`i',.01),round(`T1_25_`i'',.01),round(`T1_975_`i'',.01))
                                matrix UncondES`i'      = `WU_`i'' \ `TU_`i''
                                
                                matrix rownames UncondES`i' = "Within" "Total"
                                matrix colnames UncondES`i' = "Estimate" "95% (BT)LB" "95% (BT)UB"
                                
                                scalar drop d1w`i' dt1Total`i'
                                }
                               if "`paste'"!="" { 
                                local m
                                forvalues i = 1/`=`max'' {
                                        if "`=`refcat'+0'" != "``i''" {
                                        local m = `m' + 1
                                        
                                        matrix CondES``i'' = CondES`m' 
                                        local cond`m' CondES``i'' 
                                        
                                        matrix UncondES``i'' = UncondES`m' 
                                        local uncond`m' UncondES``i'' 
                                        
                                        rename (Boot1_T`m'_W Boot2_T`m'_W Boot1_T`m'_T Boot2_T`m'_T) (BootUnc_I``i''_W BootC_I``i''_W BootUnc_I``i''_T BootC_I``i''_T )
                                        }
                                }

                                keep BootC_I*_W BootC_I*_T BootUnc_I*_W BootUnc_I*_T
                                tempfile mst
                                save `mst'
                                use `Original'
                                merge 1:1 _n using `mst', nogenerate
                                tempfile Original
                                save `Original'
							}
                        } /* if nboot*/
                        
                        /*TABLES*/
                        
                capture {
                        noisily {
                                return matrix Beta = `Beta'
                
                                return matrix Cov = `Cov'
                
                                return matrix schCov = `schCov'

                                return matrix UschCov = `UschCov'
                
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
        }/*quietly*/

end



/*SUB-PROGRAMS*/

capture program drop gCondMST
program define gCondMST, rclass
version 15.1
syntax, res_variance2(name) vartt2(name) group_max(name) max(name) varb32(name) brf(name) i(numlist) coef(name)
        

        tempname M vtermW1 vtermW2 seW LB_W UB_W gwithin vtermT1 vtermT2 seT LB_T UB_T gtotal N Nc Nt sumforvtermW1 sumforvtermT1 ni nt nc elemvarE CondES

        scalar d2w`i' = `coef'[`i',1]/sqrt(`res_variance2')
        matrix `nt' = `brf'[1...,2]              /*Br_F1,2  contained in matrix.*/
        matrix `nc' =  `brf'[1...,1]  
        scalar `elemvarE' = `varb32'[1,`i'] /*extract each element from matrix varB32 (=VarE) to use in mata for each iteration*/
		
	 mata hfunc2("`res_variance2'", "`vartt2'", "`nt'", "`nc'", "`elemvarE'","`Nt'","`Nc'","`ni'","`sumforvtermW1'","`sumforvtermT1'")
 
        
		scalar `M'=`group_max'

        scalar `N' = `Nt' + `Nc' /* is equivalent to N in g.within.mst*/
        scalar `vtermW1' = 1/`sumforvtermW1'
        scalar `vtermW2' = ((d2w`i'^2)/((2*`N'-4*`M')))
        scalar `seW' = sqrt(`vtermW1' + `vtermW2')
        scalar `LB_W' = (d2w`i'-1.96*`seW')
        scalar `UB_W' = (d2w`i'+1.96*`seW')
        matrix `gwithin' = (round(d2w`i',.01),round(`LB_W',.01),round(`UB_W',.01))
        
        scalar dt2Total`i' = `coef'[`i',1]/sqrt(`vartt2')
        scalar `vtermT1' = 1/`sumforvtermT1'
        scalar `vtermT2' = ((dt2Total`i'^2)/((2*`N'-4*`M')))
        scalar `seT' = sqrt(`vtermT1' + `vtermT2')
        scalar `LB_T' = (dt2Total`i'-1.96*`seT')
        scalar `UB_T' = (dt2Total`i'+1.96*`seT')
        matrix `gtotal' = (round(dt2Total`i',.01),round(`LB_T',.01),round(`UB_T',.01))
        
        
        matrix `CondES' = (`gwithin' \ `gtotal')
        matrix rownames `CondES' = "Within" "Total"
        matrix colnames `CondES' = "Estimate" "95% LB" "95% UB"
        
        return matrix CondES`i' = `CondES'
        
end

capture program drop gUncondMST
program define gUncondMST, rclass
version 15.1
syntax, RANdom(varlist fv) res_variance1(name) res_variance2(name) vartt2(name) vartt1(name) group_max(name) max(name) ///
icc1(name) icc2(name) varb31(name) sums(name) coef(name) brokn_fctor(name)

tempname M
scalar `M'=`group_max'
quietly {
        forvalues i = 1/`=`max'-1' {
                        
                tempname MatNt`i' Nc`i' N`i' Nt`i' Mc`i' Mt`i' M`i' nt`i' nc`i'

                tempfile forloop
                save `forloop'

                /*tab `random' brokn_fctor`=`i'+1', matcell(Br_F`i')*/  /*because `=`max'-1' = 2 , broken factor is 1,2,3 but we need 2,3 because 1 is baseline*/
                //svmat Br_F`i'

               // total Br_F`i'1 /*Generate Nt`i', Nc`i' nt`i' and nc`i' again for the unconditional model */
               // matrix `MatNt`i'' = e(b) 
                scalar `Nc`i'' = `sums'[`i',1]

                scalar `Nt`i'' = `sums'[`i',2]
                
                scalar `N`i'' = `Nc`i'' + `Nt`i''
                
        
                tab `random' `brokn_fctor'`=`i'+1' if `brokn_fctor'`=`i'+1'==1, matcell(`nt`i'') 
                scalar `Mt`i''= r(r) 
                
                tab `random' `brokn_fctor'`=`i'+1' if `brokn_fctor'`=`i'+1'==0, matcell(`nc`i'') 
                scalar `Mc`i''= r(r) 
                
                scalar `M`i'' = `Mc`i'' + `Mt`i''
                
                clear 
                use `forloop'
        
                }
                
        forvalues i = 1/`=`max'-1' {
        tempname UncondES`i' nsim1`i' nsim2`i' nsimTotal`i' vterm1`i' vterm2U`i' vterm3U`i' Uste`i' LUB`i' UUB`i' gUwithin`i' gUtotal`i' dt1Total`i' B`i' ///
        At`i' Ac`i' A`i' vterm1Tot`i' vterm2UTot`i' vterm3UTot`i' steUTot`i' LUBtot`i' UUBtot`i' nut`i' nuc`i' dtU_1`i' dtU_2`i' sqnt`i' sqnc`i' qnt`i' qnc`i'
		
		mata: hfunc3("`nt`i''", "`nc`i''","`sqnt`i''", "`sqnc`i''","`qnt`i''", "`qnc`i''")
       
                scalar d1w`i'= `coef'[`i',1]/sqrt(`res_variance1')
                scalar `nsim1`i''     = (`Nc`i'' * `sqnt`i'')/(`Nt`i'' * `N`i'')
                scalar `nsim2`i''    = (`Nt`i'' * `sqnc`i'')/(`Nc`i'' * `N`i'')
                scalar `nsimTotal`i'' = `nsim1`i'' + `nsim2`i''
                scalar `vterm1`i''    = ((`Nt`i''+`Nc`i'')/(`Nt`i''*`Nc`i''))
                scalar `vterm2U`i''    = (((1+(`nsimTotal`i''-1)*`icc1'))/(1-`icc1'))
                scalar `vterm3U`i''    = ((d1w`i'^2)/(2*(`N`i''-`M`i'')))
                scalar `Uste`i''       = sqrt(`vterm1`i''*`vterm2U`i''+`vterm3U`i'')
                scalar `LUB`i''        = (d1w`i'-1.96*`Uste`i'')
                scalar `UUB`i''        = (d1w`i'+1.96*`Uste`i'')
                matrix `gUwithin`i''    = (round(d1w`i',.01), round(`LUB`i'',.01), round(`UUB`i'',.01))
                
                
                /*End of g.within*/
                
                /*g.total*/
                
                scalar `nut`i''     = ((`Nt`i''^2-`sqnt`i'')/(`Nt`i'' *( `Mt`i'' -1)))
                scalar `nuc`i''     = ((`Nc`i''^2-`sqnc`i'')/(`Nc`i'' *( `Mc`i'' -1)))
                scalar `dtU_1`i''  = `coef'[`i',1]/sqrt(`vartt1')
                scalar `dtU_2`i''  = sqrt(1-`icc1'*(((`N`i''-`nut`i''*`Mt`i''-`nuc`i''*`Mc`i'')+`nut`i''+`nuc`i''-2)/(`N`i''-2)))
                scalar dt1Total`i' = ( `dtU_1`i'' * `dtU_2`i'' )
                
                scalar `B`i''  = (`nut`i''*(`Mt`i''-1)+`nuc`i''*(`Mc`i''-1))
                scalar `At`i'' = ((`Nt`i'' ^2*`sqnt`i''+(`sqnt`i'')^2-2* `Nt`i'' *`qnt`i'')/ `Nt`i'' ^2)
                scalar `Ac`i'' = ((`Nc`i''^2*`sqnc`i''+(`sqnc`i'')^2-2* `Nc`i'' *`qnc`i'')/ `Nc`i'' ^2)
        
                scalar `A`i''  = (`At`i'' + `Ac`i'')
        
                scalar `vterm1Tot`i'' = (((`Nt`i''+`Nc`i'')/(`Nt`i''*`Nc`i''))*(1+(`nsimTotal`i''-1)*`icc1'))
                scalar `vterm2UTot`i'' = (((`N`i''-2)*(1-`icc1')^2+`A`i''*`icc1'^2+2*`B`i''*`icc1'*(1-`icc1'))*dt1Total`i'^2)
                scalar `vterm3UTot`i'' = (2*(`N`i''-2)*((`N`i''-2)-`icc1'*(`N`i''-2-`B`i'')))
                scalar `steUTot`i''    = sqrt( `vterm1Tot`i'' + `vterm2UTot`i'' / `vterm3UTot`i'')
                scalar `LUBtot`i''     = (dt1Total`i'-1.96* `steUTot`i'' ) 
                scalar `UUBtot`i''              = (dt1Total`i'+1.96*`steUTot`i'')
                matrix `gUtotal`i'' = (round(dt1Total`i',.01), round(`LUBtot`i'',.01), round(`UUBtot`i'',.01))
                
                
                
                matrix `UncondES`i'' = ( `gUwithin`i'' \ `gUtotal`i'' )
                matrix rownames `UncondES`i'' = "Within" "Total"
                matrix colnames `UncondES`i'' = "Estimate" "95% LB" "95% UB"
                
                return matrix UncondES`i' = `UncondES`i''
                
                scalar drop `sqnt`i'' `sqnc`i'' `qnt`i'' `qnc`i''
                }

        tempname Cov Cov1 Cov2 
        matrix `Cov1' = (round(`res_variance2',.01),round(`vartt2',.01),round(`icc2',.01))
        matrix colnames `Cov1' = "Pupils" "Total" "ICC"
        matrix rownames `Cov1' = "Conditional"
        matrix `Cov2' = (round(`res_variance1',.01),round(`vartt1',.01),round(`icc1',.01))
        matrix colnames `Cov2' = "Pupils" "Total" "ICC"
        matrix rownames `Cov2' = "Unconditional"
        matrix `Cov' = `Cov1' \ `Cov2'
        
        return matrix Cov = `Cov'
        
        tempname UschCov
        matrix `UschCov' = `varb31'
        matrix rownames `UschCov' = "Unconditional"
        matrix colnames `UschCov' = "School"
        
        return matrix UschCov = `UschCov'
        }
end

capture program drop gCondUncondMST
program define gCondUncondMST, rclass
version 15.1
syntax, i(numlist) j(numlist) Intervention(varlist fv) RANdom(varlist fv) res_variance1(name) res_variance2(name) group_max(name) max(name) vartt1(name) ///
vartt2(name) icc1(name) sums(name) coef(name) brokn_fctor(name)


		tempname dwC`i'`j' dtTotalC`i'`j' MatNt`i' Nc`i' N`i' Nt`i' Mc`i' Mt`i' M`i' nt`i' nc`i' nut`i' nuc`i' dt_1U`i'`j' dt_2U`i' dwU`i'`j' dtTotalU`i'`j' ///
		sqnt`i' sqnc`i' qnt`i' qnc`i'
		
        scalar `dwC`i'`j'' = `coef'[`i',1]/sqrt(`res_variance2')
        scalar `dtTotalC`i'`j''  = `coef'[`i',1]/sqrt(`vartt2')
		
		return scalar dwC`i'`j' = `dwC`i'`j''
		return scalar dtTotalC`i'`j' = `dtTotalC`i'`j''
        
	   scalar `Nc`i'' = `sums'[`i',1]

	   scalar `Nt`i'' = `sums'[`i',2]
				
	   scalar `N`i'' = `Nc`i'' + `Nt`i''


        capture tab `random' `brokn_fctor'`=`i'+1' if `brokn_fctor'`=`i'+1'==1, matcell(`nt`i'')
        scalar `Mt`i''= r(r)

        capture tab `random' `brokn_fctor'`=`i'+1' if `brokn_fctor'`=`i'+1'==0, matcell(`nc`i'')
        scalar `Mc`i''= r(r)
        
        scalar `M`i'' = `Mc`i'' + `Mt`i''

        
       	mata: hfunc3("`nt`i''", "`nc`i''","`sqnt`i''", "`sqnc`i''","`qnt`i''", "`qnc`i''")
				
        scalar `dwU`i'`j''  = `coef'[`i',1]/sqrt(`res_variance1')
        scalar `nut`i''     = ((`Nt`i''^2-`sqnt`i'')/(`Nt`i''*(`Mt`i''-1)))
        scalar `nuc`i''     = ((`Nc`i''^2-`sqnc`i'')/(`Nc`i''*(`Mc`i''-1)))
        scalar `dt_1U`i'`j''      = `coef'[`i',1]/sqrt(`vartt1')
        scalar `dt_2U`i''      = sqrt(1-`icc1'*(((`N`i''-`nut`i''*`Mt`i''-`nuc`i''*`Mc`i'')+`nut`i''+`nuc`i''-2)/(`N`i''-2)))
        scalar `dtTotalU`i'`j''  = (`dt_1U`i'`j'' * `dt_2U`i'')
        
        scalar drop `sqnt`i'' `sqnc`i'' `qnt`i'' `qnc`i''
		
		return scalar dwU`i'`j' = `dwU`i'`j''
		return scalar dtTotalU`i'`j' = `dtTotalU`i'`j''
        
		
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
                        cap if "`refcat'" != "``i''" local s = `s'+1 /*checking cases were intervention is irregular (i.e. 1 4 9) and user has specified a number of baseline that is not 1,4 or 9 and not below
>  1 and not above 9*/
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

