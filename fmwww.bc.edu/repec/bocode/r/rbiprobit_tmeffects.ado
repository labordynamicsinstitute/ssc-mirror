*! version 1.1.0 , 18apr2022
*! Author: Mustafa Coban, Institute for Employment Research (Germany)
*! Website: mustafacoban.de
*! Support: mustafa.coban@iab.de


/****************************************************************/
/*     rbiprobit tmeffects: rbiprobit postestimation command	*/
/****************************************************************/


/*-------------------TREATMENT EFFECTS COMMAND --------------------------*/


/* TREATMENT EFFECTS */
program define rbiprobit_tmeffects, eclass
	
	version 11
	syntax [anything] [if] [in] [pw fw iw] [, 		/*
				*/	TMEFFect(string) VCE(passthru) NOWEIGHTs	/*
				*/	NOEsample force	Level(cilevel) post	/*
				*/	*]
	
	if ("`e(cmd)'" != "rbiprobit") error 301

	local wtype `weight'
	local wtexp `"`exp'"'
	if "`weight'" != "" { 
		local wgt `"[`weight'`exp']"'  
	}
	
	if "`level'" != ""{
		local level "level(`level')"
	}
	
	local margopts0 `options'
	_get_diopts diopts margopts0, `margopts0'
	
	if "`margopts0'" != ""{
		dis as err "Following options or their multiples are not allowed: {bf: `margopts0'}"
		dis as res	"See {help rbiprobit tmeffects}." 
		exit 198
	}
	
	if "`anything'" != ""{
		dis as err "{it: marginlist} not allowed."
		exit 198
	}

	
	*! tmeffect()
	if "`tmeffect'" == ""{
		local effect "ate"
	}
	else if !inlist("`tmeffect'","ate","atet","atec"){
		dis in red "option tmeffect() incorrectly specified."
		error 198
	}
	
	tokenize `e(depvar)'
	local dep1 `1'
	local dep2 `2'	

	
	*! estimation of ate, atet, and atec
	tempname margfailed
	
	if "`tmeffect'" == "ate"{		
		cap qui margins `if' `in' `wgt', /*
				*/	dydx(`dep2') predict(pmarg1) `vce' /*
				*/	`noweights' `noesample' `force' `post'
	}
	else if "`tmeffect'" == "atet"{
		if "`if'" != ""{
			local iftot "`if' & `dep2' == 1"
		}
		else{
			local iftot "if `dep2' == 1"
		}		
		cap qui margins `iftot' `in' `wgt', /*
					*/	dydx(`dep2') predict(pmargcond1) `vce'	/*
					*/	`noweights' `noesample' `force' `post' 
	}
	else if "`tmeffect'" == "atec"{
		cap qui margins `if' `in' `wgt', /*
				*/	exp(predict(pcond1)-predict(pcond10)) `vce'	/*
				*/	`noweights' `noesample' `force' `post' 
	}
	
	scalar `margfailed' = _rc
	
	if `margfailed' != 0{
		exit `margfailed'
	}

	
	*! adjust output table			
	if "`post'" == ""{
		
		tempname sampyes
		qui: gen byte 	`sampyes' = 1		if e(sample)
		qui: replace	`sampyes' = 0		if `sampyes' == .
		
		*!	safe e() and r() from margins
		foreach y in scalars macros matrices{
			local elis_`y': e(`y')
			local elis_`y'_cnt: word count `elis_`y''
		}
		
		
		*!	Extract "b", "V", and "Cns" from Matrices-List of e()
		local elis_matrices: subinstr local elis_matrices `"b"' "", word
		local elis_matrices: subinstr local elis_matrices `"V"' "", word
		local elis_matrices: subinstr local elis_matrices `"Cns"' "", word
		local elis_matrices_cnt: word count `elis_matrices'

									
		forvalue y = 1(1)`elis_scalars_cnt'{
			tempname eret_scalars_c`y'
			local wd: word `y' of `elis_scalars'
			scalar `eret_scalars_c`y'' = `e(`wd')'
		}
				
		forvalue y = 1(1)`elis_macros_cnt'{
			local wd: word `y' of `elis_macros'
			local eret_macros_c`y'= "`e(`wd')'"
		}
		
		forvalue y = 1(1)`elis_matrices_cnt'{
			tempname eret_matrices_c`y'
			local wd: word `y' of `elis_matrices'
			matrix `eret_matrices_c`y'' = e(`wd')
		}
		
		foreach x in b V Cns{
			tempname eret_post_`x'
			matrix `eret_post_`x'' = e(`x')
		}
				
		
		*!	change current e() with r()
		postrtoe
		
		*!	safe r() as tempvar
		tempname retoriginal
		_return hold `retoriginal'
		
		
		*! display output table
		TmEff_Disp, `tmeffect' dep1(`dep1') dep2(`dep2') `level' `diopts'
				

		*!	restore original e() from margins
		ereturn post	`eret_post_b' `eret_post_V' `eret_post_Cns' ///
						, esample(`sampyes')
		
		
		forvalue y = 1(1)`elis_scalars_cnt'{
			local wd: word `y' of `elis_scalars'
			if inlist("`wd'","k_autoCns","consonly","noconstant"){
				ereturn hidden scalar `wd' = `eret_scalars_c`y''
			}
			else{
				ereturn scalar `wd' = `eret_scalars_c`y''
			}
		}
							
		forvalue y = 1(1)`elis_macros_cnt'{
			local wd: word `y' of `elis_macros'
			if inlist("`wd'","marginsderiv","diparm1","crittype","singularHmethod"){
				ereturn hidden local `wd' "`eret_macros_c`y''"
			}
			else{
				ereturn local `wd' "`eret_macros_c`y''"
			}
		}				
		
		forvalue y = 1(1)`elis_matrices_cnt'{
			local wd: word `y' of `elis_matrices'
			ereturn matrix `wd' = `eret_matrices_c`y''
		}
			
		
		*! restore original r() from margins	
		_return restore `retoriginal'
		
		TmEff_Rt `if' `in', `post' `tmeffect' dep1(`dep1') dep2(`dep2')
		
	}
	else{
		
		*! display output table
		TmEff_Disp, `tmeffect' dep1(`dep1') dep2(`dep2') `level' `diopts'
		
		*! adjust e()
		TmEff_Ert `if' `in', `tmeffect' dep1(`dep1') dep2(`dep2')
		
		*! adjust r()
		TmEff_Rt `if' `in', `post' `tmeffect' dep1(`dep1') dep2(`dep2')
		
	}
			
	exit `margfailed'
end




/* OUTPUT TABLE */
program define TmEff_Disp, eclass
	
 	syntax [anything] [, ate atet atec dep1(string) dep2(string) /*
					*/	Level(cilevel) /*
					*/	* ]
		
	local diopts `options'
	
	if "`level'" != ""{
		local level "level(`level')"
	}	

	*! table header
	_coef_table_header, title(Treatment effect)
	
	
	if "`e(vce)'" == "delta"{
		vceHeader
	}
	
	if "`ate'" != ""{
		local label `"`e(predict_label)'"'
		local label `"`label', `e(expression)'"'
		dis
	
		Legend Expression `"`label'"'
		Legend Effect `"Average treatment effect"'
	}
	
	if "`atet'" != ""{
		local label `"normal(`dep1'=1|`dep2'=1) - normal(`dep1'=1|`dep2'=0)"'
		dis
	
		Legend Expression `"`label'"'
		Legend Effect `"Average treatment effect on the treated"'
	}
	
	if "`atec'" != ""{
		local label `"Pr(`dep1'=1|`dep2'=1)-Pr(`dep1'=1|`dep2'=0)"'
		local label `"`label', `e(expression)'"'
		dis
	
		Legend Expression `"`label'"'
		Legend Effect `"Average treatment effect on conditional probability"'
	}
	
	if "`atec'" != ""{
		local xvars `"1.`dep2'"'
	}
	else{
		local xvars `"`e(xvars)'"'
	}
	
	foreach x of local xvars {
		_ms_parse_parts `x'
		if !r(omit) {
			local XVARS `XVARS' `x'
		}
	}
	Legend "dydx w.r.t." "`XVARS'"
	dis
	

	*! output table
	tempname bmat vmat errmat
	mat `bmat' = e(b)
	mat `vmat' = e(V)
	mat `errmat' = e(error)
	
	if "`atec'" == ""{	
		mat `bmat' = `bmat'[1,2]
		mat `vmat' = `vmat'[2,2]
		mat `errmat' = `errmat'[1,2]
	}
	
	mat rownames `bmat' = y1
	mat colnames `bmat' = `ate'`atet'`atec'
	
	mat rownames `vmat' = `ate'`atet'`atec'
	mat colnames `vmat' = `ate'`atet'`atec'	
	
	mat rownames `errmat' = r1
	mat colnames `errmat' = `ate'`atet'`atec'
	
	ereturn repost b = `bmat' V = `vmat', rename resize
	ereturn matrix error = `errmat'
	
	
	
	version 11, missing:  /*
		*/	_coef_table,  coeftitle(dy/dx) `level' `diopts'
end



*! taken from _marg_report
program define vceHeader

	local model_vce `"`e(model_vcetype)'"'
	
	if !`:length local model_vce' {
		local model_vce `"`e(model_vce)'"'
		local proper conventional twostep unadjusted
		if `:list model_vce in proper' {
			local model_vce = strproper(`"`e(model_vce)'"')
		}
		else	local model_vce = strupper(`"`e(model_vce)'"')
	}
	local col 14
	local h1 "Model VCE"
	if `:length local model_vce' {
		di as txt `"`h1'"'  _col(`col') ": " as res `"`model_vce'"'
	}
end



*! taken from _marg_report
program define Legend

	version 11
	args name value
	local len = strlen("`name'")
	local c2 = 14
	local c3 = 16
	di "{txt}{p2colset 1 `c2' `c3' 2}{...}"
	if `len' {
		di `"{p2col:`name'}:{space 1}{res:`value'}{p_end}"'
	}
	else {
		di `"{p2col: }{space 2}{res:`value'}{p_end}"'
	}
	di "{p2colreset}{...}"
end



/* STORED RESULTS */

*! adjust r()
program define TmEff_Rt, rclass
	
 	syntax [anything] [if] [in] [, post ate atet atec dep1(string) dep2(string) *]
		
	local cmd 		= "margins"
	
	local title		= "Treatment Effect"
	local cmdline	= "rbiprobit tmeffects `if' `in', tmeffect(`ate'`atet'`atec') `post'"
	local xvars		= "`ate'`atet'`atec'"
	
	if "`ate'" != ""{	
		local effect	= "Average treatment effect"
	}
	else if "`atet'" != ""{	
		local effect	= "Average treatment effect on the treated"	
		local predict1_label = "normal(`dep1'=1|`dep2'=1) - normal(`dep1'=1|`dep2'=0)"
		local predict_label  = "normal(`dep1'=1|`dep2'=1) - normal(`dep1'=1|`dep2'=0)"
	}	
	else if "`atec'" != ""{	
		local effect	= "Average treatment effect on the conditional probability"	
		local expression_label = "Pr(`dep1'=1|`dep2'=1)-Pr(`dep1'=1|`dep2'=0)"
	}		
	
	
	
	if "`post'" == ""{
	
		tempname bmat vmat errmat tabl Jac Nmat 
		
		mat `bmat' = r(b)
		mat `vmat' = r(V)
		mat `errmat' = r(error)
		mat `tabl' = r(table)
		mat `Jac' = r(Jacobian)
		mat `Nmat' = r(_N)
		
		if "`atec'" == ""{
			mat `bmat' = `bmat'[1,2]
			mat `vmat' = `vmat'[2,2]	
			mat `errmat' = `errmat'[1,2]
			mat `tabl' = `tabl'[1...,2]
			mat `Jac' = `Jac'[2,1...]
			mat `Nmat' = `Nmat'[1,2]
		}
		
		mat rownames `bmat' = y1
		mat colnames `bmat' = `ate'`atet'`atec'
		mat rownames `vmat' = `ate'`atet'`atec'
		mat colnames `vmat' = `ate'`atet'`atec'			
		mat rownames `errmat' = r1
		mat colnames `errmat' = `ate'`atet'`atec'	
		mat colnames `tabl' = `ate'`atet'`atec'
		mat rownames `Jac' = `ate'`atet'`atec'
		mat rownames `Nmat' = r1
		mat colnames `Nmat' = `ate'`atet'`atec'
		
		return add
		
		return matrix b 		= `bmat'
		return matrix V 		= `vmat'
		return matrix error 	= `errmat'
		return matrix table 	= `tabl'
		return matrix Jacobian 	= `Jac'
		return matrix _N 		= `Nmat'
	}
	else{
			
		return add
		
		foreach y in scalars macros matrices{
			local elis_`y': e(`y')
		}

		foreach x in scalars macros matrices{
			foreach y of local elis_`x'{
				
				if "`x'" == "scalars"{
					return scalar `y' = e(`y')
				}
				else if "`x'" == "macros"{
					if inlist("`y'", "marg_dims", "predict"){
						return hidden local `y' "`e(`y')'"
					}
					else if inlist("`y'", "predict_label", "predict_opts"){
						return historical (14) local `y' "`e(`y')'"
					}
					else{
						return local `y' "`e(`y')'"
					}
				}
				else{
					tempname tempmat
					mat `tempmat' = e(`y')
					return matrix `y' = `tempmat'
				}
			}
		}
	}
	
	return local cmd 		"`cmd'"
	return local cmdline 	"`cmdline'"
	return local xvars 		"`xvars'"
	return local title 		"`title'"
	return local effect 	"`effect'"
	
	if "`atet'" != ""{
		return local predict1_label "`predict1_label'"
		return historical (14) local predict_label "`predict_label'"
	}
	else if "`atec'" != ""{
		return local expression_label "`expression_label'"
	}	
end



*! adjust e()
program define TmEff_Ert, eclass
	
 	syntax [anything] [if] [in] [, ate atet atec dep1(string) dep2(string)]
		
	local cmd 		= "margins"
	
	local title		= "Treatment Effect"
	local cmdline	= "rbiprobit tmeffects `if' `in', tmeffect(`ate'`atet'`atec') `post'"
	local xvars		= "`ate'`atet'`atec'"
	
	if "`ate'" != ""{		
		local effect	= "Average treatment effect"
	}
	else if "`atet'" != ""{	
		local effect	= "Average treatment effect on the treated"		
		local predict1_label = "normal(`dep1'=1|`dep2'=1) - normal(`dep1'=1|`dep2'=0)"
		local predict_label  = "normal(`dep1'=1|`dep2'=1) - normal(`dep1'=1|`dep2'=0)"
	}
	else if "`atec'" != ""{	
		local effect	= "Average treatment effect on conditional probability"		
		local expression_label = "Pr(`dep1'=1|`dep2'=1)-Pr(`dep1'=1|`dep2'=0)"
	}
		
	tempname Jac Nmat 
	
	mat `Jac' = e(Jacobian)
	mat `Nmat' = e(_N)
	
	if "`atec'" == ""{
		mat `Jac' = `Jac'[2,1...]
		mat `Nmat' = `Nmat'[1,2]
	}
	mat rownames `Jac' = `ate'`atet'`atec'	
	mat rownames `Nmat' = r1
	mat colnames `Nmat' = `ate'`atet'`atec'
	
	ereturn local cmd 		"`cmd'"
	ereturn local cmdline 	"`cmdline'"
	ereturn local xvars 	"`xvars'"
	ereturn local title 	"`title'"
	ereturn local effect 	"`effect'"
	
	if "`atet'" != ""{
		ereturn local predict1_label "`predict1_label'"
		ereturn historical (14) local predict_label "`predict_label'"
	}
	else if "`atec'" != ""{
		ereturn local expression_label "`expression_label'"
	}
	
	ereturn matrix Jacobian 	= `Jac'
	ereturn matrix _N 			= `Nmat'		
end
