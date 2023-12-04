program mlmr2_2L, rclass sortpreserve
	version 17
	syntax [, ]
	qui _estimates hold mixedest, copy restore
	loc nlevels = colsof(e(N_g))+1
	//s2
	if e(rstructure)=="unstructured" | e(rstructure)=="banded" {
		if !mi(e(timevar)) & !mi(e(rbyvar)) {
			qui levelsof `e(timevar)' if e(sample), l(time)
			qui levelsof `e(rbyvar)' if e(sample), l(byvar)
			loc h = 1
			foreach t of loc time {
				loc j = 1
				foreach g of loc byvar {
					if `h'==1 & `j'==1 {
						tempname s2 s2t1g1
						sca `s2t1g1' = exp(_b[lnsig_e:_cons])^2
						qui su `e(depvar)' if e(sample) & `e(timevar)'==`t' & `e(rbyvar)'==`g'
						sca `s2' = `s2t1g1'*(r(N)/e(N))
					}
					else {
						tempname s2t`h'g`j'
						sca `s2t`h'g`j'' = `s2t1g1'*exp(_b[r_lns`j'_`h'ose:_cons])^2
						qui su `e(depvar)' if e(sample) & `e(timevar)'==`t' & `e(rbyvar)'==`g'
						sca `s2' = `s2'+(`s2t`h'g`j''*(r(N)/e(N)))
					}
					loc j = `j'+1
				}
				loc h = `h'+1
			}	
		}
		else if !mi(e(timevar)) & mi(e(rbyvar)) {
			qui levelsof `e(timevar)' if e(sample), l(time)
			loc h = 1
			foreach t of loc time {
				if `h'==1 {
					tempname s2 s2t1
					sca `s2t1' = exp(_b[lnsig_e:_cons])^2
					qui su `e(timevar)' if e(sample) & `e(timevar)'==`t'
					sca `s2' = `s2t1'*(r(N)/e(N))
				}
				else {
					tempname s2t`h'
					sca `s2t`h'' = `s2t1'*exp(_b[r_lns1_`h'ose:_cons])^2
					qui su `e(timevar)' if e(sample) & `e(timevar)'==`t'
					sca `s2' = `s2'+(`s2t`h''*(r(N)/e(N)))
				}
				loc h = `h'+1
			}
		}
		else if mi(e(timevar)) & !mi(e(rbyvar)) {
			qui levelsof `e(rbyvar)' if e(sample), l(byvar)
			loc h = 1
			foreach g of loc byvar {
				if `h'==1 {
					tempname s2 s2g1
					sca `s2g1' = exp(_b[lnsig_e:_cons])^2
					qui su `e(rbyvar)' if e(sample) & `e(rbyvar)'==`g'
					sca `s2' = `s2g1'*(r(N)/e(N))
				}
				else {
					tempname s2g`h'
					sca `s2g`h'' = `s2g1'*exp(_b[r_lns`h'ose:_cons])^2
					qui su `e(rbyvar)' if e(sample) & `e(rbyvar)'==`g'
					sca `s2' = `s2'+(`s2g`h''*(r(N)/e(N)))
				}
				loc h = `h'+1
			}
		}
	}
	else if e(rstructure)!="unstructured" & e(rstructure)!="banded" {
		if !mi(e(rbyvar)) {
			qui levelsof `e(rbyvar)' if e(sample), l(byvar)
			loc h = 1
			foreach g of loc byvar {
				if `h'==1 {
					tempname s2 s2g1
					sca `s2g1' = exp(_b[lnsig_e:_cons])^2
					qui su `e(rbyvar)' if e(sample) & `e(rbyvar)'==`g'
					sca `s2' = `s2g1'*(r(N)/e(N))
				}
				else {
					tempname s2g`h'
					sca `s2g`h'' = `s2g1'*exp(_b[r_lns`h'ose:_cons])^2
					qui su `e(rbyvar)' if e(sample) & `e(rbyvar)'==`g'
					sca `s2' = `s2'+(`s2g`h''*(r(N)/e(N)))
				}
				loc h = `h'+1
			}
		}	
		else if mi(e(rbyvar)) {
			tempname s2
			sca `s2' = exp(_b[lnsig_e:_cons])^2
		}
	}
	qui estat su
	loc dv = e(depvar)
	loc allvarlist : rownames r(stats)
	loc fvlist : list allvarlist - dv
	qui fvrevar `fvlist'
	loc fvfvlist = "`r(varlist)'"
	loc bfvlist = subinstr("`fvlist'","bn.",".",.)
	tempname f f1 f2 gamma phi phi1 phi2 tau2 v2 v12 v22 m2 vtau2 sigma2 sigma12 sigma22 mu2
	//f
	loc outputids = e(ivars)
	loc id : list uniq outputids
	if mi("`fvlist'") {
		mat `f' = 0
		mat `f1' = 0
		mat `f2' = 0
	}
	else {
		foreach v of loc bfvlist {
			mat `gamma' = (nullmat(`gamma'),e(b)[1,"`dv':`v'"])
		}
		loc i = 1
		foreach var of varlist `fvfvlist' {
			tempvar v`i'_1 v`i'_2m
			cap egen double `v`i'_2m' = mean(`var') if e(sample), by(`id') 
			cap gen double `v`i'_1' = `var'-`v`i'_2m' if e(sample)
			loc fvfvlist1 = strltrim(`"`fvfvlist1' `v`i'_1'"')
			loc fvfvlist2 = strltrim(`"`fvfvlist2' `v`i'_2m'"')
			loc i =`i'+1
		}
		qui corr `fvfvlist' if e(sample), cov
		mat `phi' = r(C)
		mat `f' = `gamma'*`phi'*`gamma''
		qui corr `fvfvlist1' if e(sample), cov
		mat `phi1' = r(C)
		mat `f1' = `gamma'*`phi1'*`gamma''
		qui corr `fvfvlist2' if e(sample), cov
		mat `phi2' = r(C)
		mat `f2' = `gamma'*`phi2'*`gamma''
	}
	//v2 & m2
	qui _estimates unhold mixedest
	qui _estimates hold mixedest, copy restore
	qui estat recov, relev(`id')
	cap conf mat r(Cov)
	if !_rc {
		mat `tau2' = r(Cov)
		loc relist2 : rownames `tau2'
		loc ccheck2 = word("`relist2'",wordcount("`relist2'"))
		if "`ccheck2'"=="_cons" {
			loc rcheck2 = rowsof(`tau2')
			if `rcheck2'==1 {
				mat `v2' = 0
				mat `v12' = 0
				mat `v22' = 0
				mat `m2' = `tau2'[1,1]
			}
			else {
				loc i = 1
				mat `vtau2' = `tau2'[1..rowsof(`tau2')-1,1..colsof(`tau2')-1]
				loc rvlist2 : rownames `vtau2'
				foreach v of loc rvlist2 {
					cap fvexpand `v'
					if !_rc {
						loc crvlist2 = strltrim(`"`crvlist2' `v'"')
					}
					else {
						if strpos("`v'","#")==0 {
							loc v_2 = subinstr("`v'","_",".",1)
							loc crvlist2 = strltrim(`"`crvlist2' `v_2'"')
						}
						else {
							loc tempv = subinstr("`v'","#"," ",.)
							foreach w of loc tempv {
								loc x = subinstr("`w'","_",".",1)
								loc y = subinstr("`x'","c.","",1)
								loc w`i' = strltrim(`"`w`i'' `y'"')
							}
							loc v_2 = subinstr(strltrim("`w`i''")," ","#",.)
							loc crvlist2 = strltrim(`"`crvlist2' `v_2'"')
							loc i = `i'+1
						}
					}
				}
				loc frvlist2 = strltrim(subinstr("`crvlist2'","bn.",".",.))
				qui fvrevar `frvlist2'
				loc fvrvlist2 = "`r(varlist)'"
				loc i = 1
				foreach var of varlist `fvrvlist2' {
					tempvar v`i'_12 v`i'_2m2
					cap egen double `v`i'_2m2' = mean(`var') if e(sample), by(`id')
					cap gen double `v`i'_12' = `var'-`v`i'_2m2' if e(sample)
					loc fvrvlist12 = strltrim(`"`fvrvlist12' `v`i'_12'"')
					loc fvrvlist22 = strltrim(`"`fvrvlist22' `v`i'_2m2'"')
					loc i =`i'+1
				}
				qui corr `fvrvlist2' if e(sample), cov
				mat `sigma2' = r(C)
				mat `v2' = trace(`sigma2'*`vtau2')
				qui corr `fvrvlist12' if e(sample), cov
				mat `sigma12' = r(C)
				mat `v12' = trace(`sigma12'*`vtau2')
				qui corr `fvrvlist22' if e(sample), cov
				mat `sigma22' = r(C)
				mat `v22' = trace(`sigma22'*`vtau2')
				qui _estimates unhold mixedest
				qui _estimates hold mixedest, copy restore
				foreach var of varlist `fvrvlist2' {
					qui su `var' if e(sample), meanonly
					mat `mu2' = (nullmat(`mu2'),r(mean))
				}
				mat `mu2' = (`mu2',1)
				mat `m2' = `mu2'*`tau2'*`mu2''
			}
		}
		else {
			loc rvlist2 : rownames `tau2'
			loc i = 1
			foreach v of loc rvlist2 {
				cap fvexpand `v'
				if !_rc {
					loc crvlist2 = strltrim(`"`crvlist2' `v'"')
				}
				else {
					if strpos("`v'","#")==0 {
						loc v_2 = subinstr("`v'","_",".",1)
						loc crvlist2 = strltrim(`"`crvlist2' `v_2'"')
					}
					else {
						loc tempv = subinstr("`v'","#"," ",.)
						foreach w of loc tempv {
							loc x = subinstr("`w'","_",".",1)
							loc y = subinstr("`x'","c.","",1)
							loc w`i' = strltrim(`"`w`i'' `y'"')
						}
						loc v_2 = subinstr(strltrim("`w`i''")," ","#",.)
						loc crvlist2 = strltrim(`"`crvlist2' `v_2'"')
						loc i = `i'+1
					}
				}
			}
			loc frvlist2 = strltrim(subinstr("`crvlist2'","bn.",".",.))
			qui fvrevar `frvlist2'
			loc fvrvlist2 = "`r(varlist)'"
			loc i = 1
			foreach var of varlist `fvrvlist2' {
				tempvar v`i'_12 v`i'_2m2
				cap egen double `v`i'_2m2' = mean(`var') if e(sample), by(`id')
				cap gen double `v`i'_12' = `var'-`v`i'_2m2' if e(sample)
				loc fvrvlist12 = strltrim(`"`fvrvlist12' `v`i'_12'"')
				loc fvrvlist22 = strltrim(`"`fvrvlist22' `v`i'_2m2'"')
				loc i =`i'+1
			}
			qui corr `fvrvlist2' if e(sample), cov
			mat `sigma2' = r(C)
			mat `v2' = trace(`sigma2'*`tau2')
			qui corr `fvrvlist12' if e(sample), cov
			mat `sigma12' = r(C)
			mat `v12' = trace(`sigma12'*`tau2')
			qui corr `fvrvlist22' if e(sample), cov
			mat `sigma22' = r(C)
			mat `v22' = trace(`sigma22'*`tau2')
			qui _estimates unhold mixedest
			qui _estimates hold mixedest, copy restore
			foreach var of varlist `fvrvlist2' {
				qui su `var' if e(sample), meanonly
				mat `mu2' = (nullmat(`mu2'),r(mean))
			}
			mat `m2' = `mu2'*`tau2'*`mu2''
		}
	}
	else {
		mat `v2' = 0
		mat `v12' = 0
		mat `v22' = 0
		mat `m2' = 0
	}
	tempname var1 var2 tvar R2_f1_1 R2_v12_1 Resid_1 R2_f2_2 R2_v22_2 R2_m2_2 R2_f1_t R2_f2_t R2_f_t R2_v12_t R2_v22_t R2_v_t R2_m_t R2_fv_t R2_fvm_t Resid_t R2_L1_t R2_L2_t R2
	sca `var1' = `f1'[1,1] + `v12'[1,1] + `s2'
	sca `var2' = `f2'[1,1] + `v22'[1,1] + `m2'[1,1]
	sca `tvar' = `var1' + `var2'
	sca `R2_f1_1' = `f1'[1,1]/`var1'
	sca `R2_v12_1' = `v12'[1,1]/`var1'
	sca `Resid_1' = `s2'/`var1'
	sca `R2_f2_2' = `f2'[1,1]/`var2'
	sca `R2_v22_2' = `v22'[1,1]/`var2'
	sca `R2_m2_2' = `m2'[1,1]/`var2'
	sca `R2_f1_t' = `f1'[1,1]/`tvar'
	sca `R2_f2_t' = `f2'[1,1]/`tvar'
	sca `R2_f_t' = `f'[1,1]/`tvar'
	sca `R2_v12_t' = `v12'[1,1]/`tvar'
	sca `R2_v22_t' = `v22'[1,1]/`tvar'
	sca `R2_v_t' = `v2'[1,1]/`tvar'
	sca `R2_m_t' = `m2'[1,1]/`tvar'
	sca `R2_fv_t' = (`f'[1,1]+`v2'[1,1])/`tvar'
	sca `R2_fvm_t' = (`f'[1,1]+`v2'[1,1]+`m2'[1,1])/`tvar'
	sca `Resid_t' = 1-`R2_fvm_t'
	sca `R2_L1_t' = `var1'/`tvar'
	sca `R2_L2_t' = `var2'/`tvar'
	di "{txt}mlmr2: R-Squared Measures for Mixed Models"
	di _newline"  Level-1 Model-Implied Variance of ""`dv'"" = {res}" `var1' "{txt} (Prop. of Total = {res}" %5.4f `R2_L1_t' "{txt})"_continue
	di _newline"  Level-2 Model-Implied Variance of ""`dv'"" = {res}" `var2' "{txt} (Prop. of Total = {res}" %5.4f `R2_L2_t' "{txt})"_continue
	di _newline"    Total Model-Implied Variance of ""`dv'"" = {res}" `tvar'
	di _newline"{txt}{hline 16}{c TT}{hline 68}"_continue
	di _newline"   R-Squared    {c |}                           Interpretation                           "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"    Level-1     {c |}       Proportion of level-1 outcome variance explained by...       "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"  R2f1 = {res}" %5.4f `R2_f1_1'  "{txt} {c |} the level-1 portion of predictors via fixed slopes.                "_continue
	di _newline" R2v12 = {res}" %5.4f `R2_v12_1' "{txt} {c |} the level-1 portion of predictors via random slope (co)variation.  "_continue
	di _newline" Resid = {res}" %5.4f `Resid_1'  "{txt} {c |} level-1 residuals (i.e., proportion of unexplained variance).      "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"    Level-2     {c |}       Proportion of level-2 outcome variance explained by...       "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"  R2f2 = {res}" %5.4f `R2_f2_2'  "{txt} {c |} the level-2 portion of predictors via fixed slopes.                "_continue
	di _newline" R2v22 = {res}" %5.4f `R2_v22_2' "{txt} {c |} the level-2 portion of predictors via random slope (co)variation.  "_continue
	di _newline"  R2m2 = {res}" %5.4f `R2_m2_2'  "{txt} {c |} outcome cluster means via random intercept variation.              "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"     Total      {c |}        Proportion of total outcome variance explained by...        "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"  R2f1 = {res}" %5.4f `R2_f1_t'  "{txt} {c |} the level-1 portion of predictors via fixed slopes.                "_continue
	di _newline"  R2f2 = {res}" %5.4f `R2_f2_t'  "{txt} {c |} the level-2 portion of predictors via fixed slopes.                "_continue
	di _newline" R2v12 = {res}" %5.4f `R2_v12_t' "{txt} {c |} the level-1 portion of predictors via random slope (co)variation.  "_continue
	di _newline" R2v22 = {res}" %5.4f `R2_v22_t' "{txt} {c |} the level-2 portion of predictors via random slope (co)variation.  "_continue
	di _newline"   R2f = {res}" %5.4f `R2_f_t'   "{txt} {c |} all predictors via fixed slopes.                                   "_continue
	di _newline"   R2v = {res}" %5.4f `R2_v_t'   "{txt} {c |} all predictors via random slope (co)variation.                     "_continue
	di _newline"   R2m = {res}" %5.4f `R2_m_t'   "{txt} {c |} outcome cluster means via random intercept variation.              "_continue
	di _newline"  R2fv = {res}" %5.4f `R2_fv_t'  "{txt} {c |} all predictors via fixed slopes and random slope (co)variation.    "_continue
	di _newline" R2fvm = {res}" %5.4f `R2_fvm_t' "{txt} {c |} the whole model.                                                   "_continue
	di _newline" Resid = {res}" %5.4f `Resid_t'  "{txt} {c |} level-1 residuals (i.e., proportion of unexplained variance).      "_continue
	di _newline"{hline 16}{c BT}{hline 68}"
	if wordcount("`fvlist'")>0 & !mi("`fvlist'") {
		loc i = 1
		foreach var of varlist `fvfvlist' {
			tempname v`i'_1var v`i'_2mvar
			qui su `v`i'_1' if e(sample)
			sca `v`i'_1var' = r(Var)
			loc v`i'_1vc = 0
			if `v`i'_1var'>=10^-10 & !mi(`v`i'_1var') {
				loc v`i'_1vc = 1
			}
			qui su `v`i'_2m' if e(sample)
			sca `v`i'_2mvar' = r(Var)
			loc v`i'_2mvc = 0
			if `v`i'_2mvar'>=10^-10 & !mi(`v`i'_2mvar') {
				loc v`i'_2mvc = 1
			}
			if `v`i'_1vc'==1 & `v`i'_2mvc'==1 {
				loc unconf2m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i' 
						tempname diff`i'_var
						cap gen double `diff`i'' = `v`i'_2m'-`fv' if e(sample)
						qui su `diff`i'' if e(sample)
						sca `diff`i'_var' = r(Var)
						if `diff`i'_var'<10^-10 {
							loc unconf2m = `unconf2m'+1
						}
					}
				}
				if `unconf2m'==0 {
					loc conflist_`i' = word("`fvlist'",`i')
					loc conflist = strltrim(`"`conflist' `conflist_`i''"')
				}
			}
			loc i =`i'+1
		}
		if !mi("`conflist'") {
			di as err "The following predictors may have conflated fixed effects because they are"_continue
			di as err _newline"not centered-within-clusters and their level-2 contextual fixed effects"_continue
			di as err _newline"have not been included in the model (see Rights 2023 for more info):"_continue
			di as err _newline"  `conflist'"
		}
	}
	if wordcount("`rvlist2'")>0 & !mi("`rvlist2'") {
		loc i = 1
		foreach var of varlist `fvrvlist2' {
			tempname v`i'_12var v`i'_2m2var
			qui su `v`i'_12' if e(sample)
			sca `v`i'_12var' = r(Var)
			loc v`i'_12vc = 0
			if `v`i'_12var'>=10^-10 & !mi(`v`i'_12var') {
				loc v`i'_12vc = 1
			}
			qui su `v`i'_2m2' if e(sample)
			sca `v`i'_2m2var' = r(Var)
			loc v`i'_2m2vc = 0
			if `v`i'_2m2var'>=10^-10 & !mi(`v`i'_2m2var') {
				loc v`i'_2m2vc = 1
			}
			if `v`i'_12vc'==1 & `v`i'_2m2vc'==1 {
				loc unconf2m2 = 0
				if wordcount("`rvlist2'")>1 {
					loc vc2 = word("`fvrvlist2'",`i')
					loc complist2 : list fvrvlist2 - vc2
					foreach rv2 of varlist `complist2' {
						tempvar diff2`i'
						tempname diff2`i'_var
						cap gen double `diff2`i'' = `v`i'_2m2'-`rv2' if e(sample)
						qui su `diff2`i'' if e(sample)
						sca `diff2`i'_var' = r(Var)
						if `diff2`i'_var'<10^-10 {
							loc unconf2m2 = `unconf2m2'+1
						}
					}
				}
				if `unconf2m2'==0  {
					loc conflist2_`i' = word("`rvlist2'",`i')
					loc conflist2 = strltrim(`"`conflist2' `conflist2_`i''"')
				}
			}
			loc i =`i'+1
		}
		if !mi("`conflist2'") {
			di as err _newline"The following predictors may have conflated random effects because they are"_continue
			di as err _newline"not centered-within-clusters and their level-2 contextual random effects have"_continue
			di as err _newline"not been included in the model (see Rights & Sterba 2023a for more info):"_continue
			di as err _newline"  `conflist2'"
		}
	}
	ret clear
	mat `R2' = (`R2_f1_1',`R2_v12_1',`Resid_1',`R2_f2_2',`R2_v22_2',`R2_m2_2',`R2_f1_t',`R2_f2_t',`R2_v12_t',`R2_v22_t',`R2_f_t',`R2_v_t',`R2_m_t',`R2_fv_t',`R2_fvm_t',`Resid_t')
	mat colnames `R2' = R2_f1_1 R2_v12_1 Resid_1 R2_f2_2 R2_v22_2 R2_m2_2 R2_f1_t R2_f2_t R2_v12_t R2_v22_t R2_f_t R2_v_t R2_m_t R2_fv_t R2_fvm_t Resid_t
	mat rownames `R2' = "`dv'"
	ret mat R2 = `R2'
	qui _estimates unhold mixedest
	qui _estimates hold mixedest, copy restore
	ret sca R2_L2_Total = `R2_L2_t'
	ret sca R2_L1_Total = `R2_L1_t'
	ret sca Resid_Total = `Resid_t'
	ret sca R2_fvm_Total = `R2_fvm_t'
	ret sca R2_fv_Total = `R2_fv_t'
	ret sca R2_m_Total = `R2_m_t'
	ret sca R2_v_Total = `R2_v_t'
	ret sca R2_v22_Total = `R2_v22_t'
	ret sca R2_v12_Total = `R2_v12_t'
	ret sca R2_f_Total = `R2_f_t'
	ret sca R2_f2_Total = `R2_f2_t'
	ret sca R2_f1_Total = `R2_f1_t'
	ret sca R2_m_L2 = `R2_m2_2'
	ret sca R2_v22_L2 = `R2_v22_2'
	ret sca R2_f2_L2 = `R2_f2_2'
	ret sca Resid_L1 = `Resid_1'
	ret sca R2_v12_L1 = `R2_v12_1'
	ret sca R2_f1_L1 = `R2_f1_1'
	ret sca Total_MI_Var = `tvar'
	ret sca L2_MI_Var = `var2'
	ret sca L1_MI_Var = `var1'
	ret sca s2 = `s2'
	ret sca m = `m2'[1,1]
	ret sca v = `v2'[1,1]
	ret sca v22 = `v22'[1,1]
	ret sca v12 = `v12'[1,1]
	ret sca f = `f'[1,1]
	ret sca f2 = `f2'[1,1]
	ret sca f1 = `f1'[1,1]
end