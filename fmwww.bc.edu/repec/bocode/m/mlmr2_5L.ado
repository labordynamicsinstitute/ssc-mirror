program mlmr2_5L, rclass sortpreserve
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
	tempname f f1 f2 f3 f4 f5 gamma phi phi1 phi2 phi3 phi4 phi5 tau2 tau3 tau4 tau5 v2 v3 v4 v5 m2 m3 m4 m5 vtau2 vtau3 vtau4 vtau5 sigma2 sigma3 sigma4 sigma5 mu2 mu3 mu4 mu5
	tempname v12 v22 v32 v42 v52 v13 v23 v33 v43 v53 v14 v24 v34 v44 v54 v15 v25 v35 v45 v55 sigma12 sigma22 sigma32 sigma42 sigma52 sigma13 sigma23 sigma33 sigma43 sigma53 sigma14 sigma24 sigma34 sigma44 sigma54 sigma15 sigma25 sigma35 sigma45 sigma55
	//f
	loc outputids = e(ivars)
	loc ids : list uniq outputids
	gettoken (local)id5 (local)ids : ids
	gettoken (local)id4 (local)ids : ids
	gettoken (local)id3 (local)id2 : ids
	if mi("`fvlist'") {
		mat `f' = 0
		mat `f1' = 0
		mat `f2' = 0
		mat `f3' = 0
		mat `f4' = 0
		mat `f5' = 0
	}
	else {
		foreach v of loc bfvlist {
			mat `gamma' = (nullmat(`gamma'),e(b)[1,"`dv':`v'"])
		}
		loc i = 1
		foreach var of varlist `fvfvlist' {
			tempvar v`i'_1 v`i'_2 v`i'_3 v`i'_4 v`i'_2m v`i'_3m v`i'_4m v`i'_5m
			cap egen double `v`i'_2m' = mean(`var') if e(sample), by(`id5' `id4' `id3' `id2')
			cap egen double `v`i'_3m' = mean(`var') if e(sample), by(`id5' `id4' `id3')
			cap egen double `v`i'_4m' = mean(`var') if e(sample), by(`id5' `id4')
			cap egen double `v`i'_5m' = mean(`var') if e(sample), by(`id5')
			cap gen double `v`i'_1' = `var'-`v`i'_2m' if e(sample)
			cap gen double `v`i'_2' = `v`i'_2m'-`v`i'_3m' if e(sample)
			cap gen double `v`i'_3' = `v`i'_3m'-`v`i'_4m' if e(sample)
			cap gen double `v`i'_4' = `v`i'_4m'-`v`i'_5m' if e(sample)
			loc fvfvlist1 = strltrim(`"`fvfvlist1' `v`i'_1'"')
			loc fvfvlist2 = strltrim(`"`fvfvlist2' `v`i'_2'"')
			loc fvfvlist3 = strltrim(`"`fvfvlist3' `v`i'_3'"')
			loc fvfvlist4 = strltrim(`"`fvfvlist4' `v`i'_4'"')
			loc fvfvlist5 = strltrim(`"`fvfvlist5' `v`i'_5m'"')
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
		qui corr `fvfvlist3' if e(sample), cov
		mat `phi3' = r(C)
		mat `f3' = `gamma'*`phi3'*`gamma''
		qui corr `fvfvlist4' if e(sample), cov
		mat `phi4' = r(C)
		mat `f4' = `gamma'*`phi4'*`gamma''
		qui corr `fvfvlist5' if e(sample), cov
		mat `phi5' = r(C)
		mat `f5' = `gamma'*`phi5'*`gamma''
	}
	//v2 & m2
	qui _estimates unhold mixedest
	qui _estimates hold mixedest, copy restore
	qui estat recov, relev(`id2')
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
				mat `v32' = 0
				mat `v42' = 0
				mat `v52' = 0
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
					tempvar v`i'_12 v`i'_22 v`i'_32 v`i'_42 v`i'_2m2 v`i'_3m2 v`i'_4m2 v`i'_5m2
					cap egen double `v`i'_2m2' = mean(`var') if e(sample), by(`id5' `id4' `id3' `id2')
					cap egen double `v`i'_3m2' = mean(`var') if e(sample), by(`id5' `id4' `id3')
					cap egen double `v`i'_4m2' = mean(`var') if e(sample), by(`id5' `id4')
					cap egen double `v`i'_5m2' = mean(`var') if e(sample), by(`id5')
					cap gen double `v`i'_12' = `var'-`v`i'_2m2' if e(sample)
					cap gen double `v`i'_22' = `v`i'_2m2'-`v`i'_3m2' if e(sample)
					cap gen double `v`i'_32' = `v`i'_3m2'-`v`i'_4m2' if e(sample)
					cap gen double `v`i'_42' = `v`i'_4m2'-`v`i'_5m2' if e(sample)
					loc fvrvlist12 = strltrim(`"`fvrvlist12' `v`i'_12'"')
					loc fvrvlist22 = strltrim(`"`fvrvlist22' `v`i'_22'"')
					loc fvrvlist32 = strltrim(`"`fvrvlist32' `v`i'_32'"')
					loc fvrvlist42 = strltrim(`"`fvrvlist42' `v`i'_42'"')
					loc fvrvlist52 = strltrim(`"`fvrvlist52' `v`i'_5m2'"')
					loc i=`i'+1
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
				qui corr `fvrvlist32' if e(sample), cov
				mat `sigma32' = r(C)
				mat `v32' = trace(`sigma32'*`vtau2')
				qui corr `fvrvlist42' if e(sample), cov
				mat `sigma42' = r(C)
				mat `v42' = trace(`sigma42'*`vtau2')
				qui corr `fvrvlist52' if e(sample), cov
				mat `sigma52' = r(C)
				mat `v52' = trace(`sigma52'*`vtau2')
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
				tempvar v`i'_12 v`i'_22 v`i'_32 v`i'_42 v`i'_2m2 v`i'_3m2 v`i'_4m2 v`i'_5m2
				cap egen double `v`i'_2m2' = mean(`var') if e(sample), by(`id5' `id4' `id3' `id2')
				cap egen double `v`i'_3m2' = mean(`var') if e(sample), by(`id5' `id4' `id3')
				cap egen double `v`i'_4m2' = mean(`var') if e(sample), by(`id5' `id4')
				cap egen double `v`i'_5m2' = mean(`var') if e(sample), by(`id5')
				cap gen double `v`i'_12' = `var'-`v`i'_2m2' if e(sample)
				cap gen double `v`i'_22' = `v`i'_2m2'-`v`i'_3m2' if e(sample)
				cap gen double `v`i'_32' = `v`i'_3m2'-`v`i'_4m2' if e(sample)
				cap gen double `v`i'_42' = `v`i'_4m2'-`v`i'_5m2' if e(sample)
				loc fvrvlist12 = strltrim(`"`fvrvlist12' `v`i'_12'"')
				loc fvrvlist22 = strltrim(`"`fvrvlist22' `v`i'_22'"')
				loc fvrvlist32 = strltrim(`"`fvrvlist32' `v`i'_32'"')
				loc fvrvlist42 = strltrim(`"`fvrvlist42' `v`i'_42'"')
				loc fvrvlist52 = strltrim(`"`fvrvlist52' `v`i'_5m2'"')
				loc i=`i'+1
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
			qui corr `fvrvlist32' if e(sample), cov
			mat `sigma32' = r(C)
			mat `v32' = trace(`sigma32'*`tau2')
			qui corr `fvrvlist42' if e(sample), cov
			mat `sigma42' = r(C)
			mat `v42' = trace(`sigma42'*`tau2')
			qui corr `fvrvlist52' if e(sample), cov
			mat `sigma52' = r(C)
			mat `v52' = trace(`sigma52'*`tau2')
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
		mat `v32' = 0
		mat `v42' = 0
		mat `v52' = 0
		mat `m2' = 0
	}
	//v3 & m3
	qui _estimates unhold mixedest
	qui _estimates hold mixedest, copy restore
	qui estat recov, relev(`id3')
	cap conf mat r(Cov)
	if !_rc {
		mat `tau3' = r(Cov)
		loc relist3 : rownames `tau3'
		loc ccheck3 = word("`relist3'",wordcount("`relist3'"))
		if "`ccheck3'"=="_cons" {
			loc rcheck3 = rowsof(`tau3')
			if `rcheck3'==1 {
				mat `v3' = 0
				mat `v13' = 0
				mat `v23' = 0
				mat `v33' = 0
				mat `v43' = 0
				mat `v53' = 0
				mat `m3' = `tau3'[1,1]
			}
			else {
				loc i = 1
				mat `vtau3' = `tau3'[1..rowsof(`tau3')-1,1..colsof(`tau3')-1]
				loc rvlist3 : rownames `vtau3'
				foreach v of loc rvlist3 {
					cap fvexpand `v'
					if !_rc {
						loc crvlist3 = strltrim(`"`crvlist3' `v'"')
					}
					else {
						if strpos("`v'","#")==0 {
							loc v_3 = subinstr("`v'","_",".",1)
							loc crvlist3 = strltrim(`"`crvlist3' `v_3'"')
						}
						else {
							loc tempv = subinstr("`v'","#"," ",.)
							foreach w of loc tempv {
								loc x = subinstr("`w'","_",".",1)
								loc y = subinstr("`x'","c.","",1)
								loc w`i' = strltrim(`"`w`i'' `y'"')
							}
							loc v_3 = subinstr(strltrim("`w`i''")," ","#",.)
							loc crvlist3 = strltrim(`"`crvlist3' `v_3'"')
							loc i = `i'+1
						}
					}
				}
				loc frvlist3 = strltrim(subinstr("`crvlist3'","bn.",".",.))
				qui fvrevar `frvlist3'
				loc fvrvlist3 = "`r(varlist)'"
				loc i = 1
				foreach var of varlist `fvrvlist3' {
					tempvar v`i'_13 v`i'_23 v`i'_33 v`i'_43 v`i'_2m3 v`i'_3m3 v`i'_4m3 v`i'_5m3
					cap egen double `v`i'_2m3' = mean(`var') if e(sample), by(`id5' `id4' `id3' `id2')
					cap egen double `v`i'_3m3' = mean(`var') if e(sample), by(`id5' `id4' `id3')
					cap egen double `v`i'_4m3' = mean(`var') if e(sample), by(`id5' `id4')
					cap egen double `v`i'_5m3' = mean(`var') if e(sample), by(`id5')
					cap gen double `v`i'_13' = `var'-`v`i'_2m3' if e(sample)
					cap gen double `v`i'_23' = `v`i'_2m3'-`v`i'_3m3' if e(sample)
					cap gen double `v`i'_33' = `v`i'_3m3'-`v`i'_4m3' if e(sample)
					cap gen double `v`i'_43' = `v`i'_4m3'-`v`i'_5m3' if e(sample)
					loc fvrvlist13 = strltrim(`"`fvrvlist13' `v`i'_13'"')
					loc fvrvlist23 = strltrim(`"`fvrvlist23' `v`i'_23'"')
					loc fvrvlist33 = strltrim(`"`fvrvlist33' `v`i'_33'"')
					loc fvrvlist43 = strltrim(`"`fvrvlist43' `v`i'_43'"')
					loc fvrvlist53 = strltrim(`"`fvrvlist53' `v`i'_5m3'"')
					loc i=`i'+1
				}
				qui corr `fvrvlist3' if e(sample), cov
				mat `sigma3' = r(C)
				mat `v3' = trace(`sigma3'*`vtau3')
				qui corr `fvrvlist13' if e(sample), cov
				mat `sigma13' = r(C)
				mat `v13' = trace(`sigma13'*`vtau3')
				qui corr `fvrvlist23' if e(sample), cov
				mat `sigma23' = r(C)
				mat `v23' = trace(`sigma23'*`vtau3')
				qui corr `fvrvlist33' if e(sample), cov
				mat `sigma33' = r(C)
				mat `v33' = trace(`sigma33'*`vtau3')
				qui corr `fvrvlist43' if e(sample), cov
				mat `sigma43' = r(C)
				mat `v43' = trace(`sigma43'*`vtau3')
				qui corr `fvrvlist53' if e(sample), cov
				mat `sigma53' = r(C)
				mat `v53' = trace(`sigma53'*`vtau3')
				qui _estimates unhold mixedest
				qui _estimates hold mixedest, copy restore
				foreach var of varlist `fvrvlist3' {
					qui su `var' if e(sample), meanonly
					mat `mu3' = (nullmat(`mu3'),r(mean))
				}
				mat `mu3' = (`mu3',1)
				mat `m3' = `mu3'*`tau3'*`mu3''
			}
		}
		else {
			loc rvlist3 : rownames `tau3'
			loc i = 1
			foreach v of loc rvlist3 {
				cap fvexpand `v'
				if !_rc {
					loc crvlist3 = strltrim(`"`crvlist3' `v'"')
				}
				else {
					if strpos("`v'","#")==0 {
						loc v_3 = subinstr("`v'","_",".",1)
						loc crvlist3 = strltrim(`"`crvlist3' `v_3'"')
					}
					else {
						loc tempv = subinstr("`v'","#"," ",.)
						foreach w of loc tempv {
							loc x = subinstr("`w'","_",".",1)
							loc y = subinstr("`x'","c.","",1)
							loc w`i' = strltrim(`"`w`i'' `y'"')
						}
						loc v_3 = subinstr(strltrim("`w`i''")," ","#",.)
						loc crvlist3 = strltrim(`"`crvlist3' `v_3'"')
						loc i = `i'+1
					}
				}
			}
			loc frvlist3 = strltrim(subinstr("`crvlist3'","bn.",".",.))
			qui fvrevar `frvlist3'
			loc fvrvlist3 = "`r(varlist)'"
			loc i = 1
			foreach var of varlist `fvrvlist3' {
				tempvar v`i'_13 v`i'_23 v`i'_33 v`i'_43 v`i'_2m3 v`i'_3m3 v`i'_4m3 v`i'_5m3
				cap egen double `v`i'_2m3' = mean(`var') if e(sample), by(`id5' `id4' `id3' `id2')
				cap egen double `v`i'_3m3' = mean(`var') if e(sample), by(`id5' `id4' `id3')
				cap egen double `v`i'_4m3' = mean(`var') if e(sample), by(`id5' `id4')
				cap egen double `v`i'_5m3' = mean(`var') if e(sample), by(`id5')
				cap gen double `v`i'_13' = `var'-`v`i'_2m3' if e(sample)
				cap gen double `v`i'_23' = `v`i'_2m3'-`v`i'_3m3' if e(sample)
				cap gen double `v`i'_33' = `v`i'_3m3'-`v`i'_4m3' if e(sample)
				cap gen double `v`i'_43' = `v`i'_4m3'-`v`i'_5m3' if e(sample)
				loc fvrvlist13 = strltrim(`"`fvrvlist13' `v`i'_13'"')
				loc fvrvlist23 = strltrim(`"`fvrvlist23' `v`i'_23'"')
				loc fvrvlist33 = strltrim(`"`fvrvlist33' `v`i'_33'"')
				loc fvrvlist43 = strltrim(`"`fvrvlist43' `v`i'_43'"')
				loc fvrvlist53 = strltrim(`"`fvrvlist53' `v`i'_5m3'"')
				loc i=`i'+1
			}
			qui corr `fvrvlist3' if e(sample), cov
			mat `sigma3' = r(C)
			mat `v3' = trace(`sigma3'*`tau3')
			qui corr `fvrvlist13' if e(sample), cov
			mat `sigma13' = r(C)
			mat `v13' = trace(`sigma13'*`tau3')
			qui corr `fvrvlist23' if e(sample), cov
			mat `sigma23' = r(C)
			mat `v23' = trace(`sigma23'*`tau3')
			qui corr `fvrvlist33' if e(sample), cov
			mat `sigma33' = r(C)
			mat `v33' = trace(`sigma33'*`tau3')
			qui corr `fvrvlist43' if e(sample), cov
			mat `sigma43' = r(C)
			mat `v43' = trace(`sigma43'*`tau3')
			qui corr `fvrvlist53' if e(sample), cov
			mat `sigma53' = r(C)
			mat `v53' = trace(`sigma53'*`tau3')
			qui _estimates unhold mixedest
			qui _estimates hold mixedest, copy restore
			foreach var of varlist `fvrvlist3' {
				qui su `var' if e(sample), meanonly
				mat `mu3' = (nullmat(`mu3'),r(mean))
			}
			mat `m3' = `mu3'*`tau3'*`mu3''
		}
	}
	else {
		mat `v3' = 0
		mat `v13' = 0
		mat `v23' = 0
		mat `v33' = 0
		mat `v43' = 0
		mat `v53' = 0
		mat `m3' = 0
	}
	//v4 & m4
	qui _estimates unhold mixedest
	qui _estimates hold mixedest, copy restore
	qui estat recov, relev(`id4')
	cap conf mat r(Cov)
	if !_rc {
		mat `tau4' = r(Cov)
		loc relist4 : rownames `tau4'
		loc ccheck4 = word("`relist4'",wordcount("`relist4'"))
		if "`ccheck4'"=="_cons" {
			loc rcheck4 = rowsof(`tau4')
			if `rcheck4'==1 {
				mat `v4' = 0
				mat `v14' = 0
				mat `v24' = 0
				mat `v34' = 0
				mat `v44' = 0
				mat `v54' = 0
				mat `m4' = `tau4'[1,1]
			}
			else {
				loc i = 1
				mat `vtau4' = `tau4'[1..rowsof(`tau4')-1,1..colsof(`tau4')-1]
				loc rvlist4 : rownames `vtau4'
				foreach v of loc rvlist4 {
					cap fvexpand `v'
					if !_rc {
						loc crvlist4 = strltrim(`"`crvlist4' `v'"')
					}
					else {
						if strpos("`v'","#")==0 {
							loc v_4 = subinstr("`v'","_",".",1)
							loc crvlist4 = strltrim(`"`crvlist4' `v_4'"')
						}
						else {
							loc tempv = subinstr("`v'","#"," ",.)
							foreach w of loc tempv {
								loc x = subinstr("`w'","_",".",1)
								loc y = subinstr("`x'","c.","",1)
								loc w`i' = strltrim(`"`w`i'' `y'"')
							}
							loc v_4 = subinstr(strltrim("`w`i''")," ","#",.)
							loc crvlist4 = strltrim(`"`crvlist4' `v_4'"')
							loc i = `i'+1
						}
					}
				}
				loc frvlist4 = strltrim(subinstr("`crvlist4'","bn.",".",.))
				qui fvrevar `frvlist4'
				loc fvrvlist4 = "`r(varlist)'"
				loc i = 1
				foreach var of varlist `fvrvlist4' {
					tempvar v`i'_14 v`i'_24 v`i'_34 v`i'_44 v`i'_2m4 v`i'_3m4 v`i'_4m4 v`i'_5m4
					cap egen double `v`i'_2m4' = mean(`var') if e(sample), by(`id5' `id4' `id3' `id2')
					cap egen double `v`i'_3m4' = mean(`var') if e(sample), by(`id5' `id4' `id3')
					cap egen double `v`i'_4m4' = mean(`var') if e(sample), by(`id5' `id4')
					cap egen double `v`i'_5m4' = mean(`var') if e(sample), by(`id5')
					cap gen double `v`i'_14' = `var'-`v`i'_2m4' if e(sample)
					cap gen double `v`i'_24' = `v`i'_2m4'-`v`i'_3m4' if e(sample)
					cap gen double `v`i'_34' = `v`i'_3m4'-`v`i'_4m4' if e(sample)
					cap gen double `v`i'_44' = `v`i'_4m4'-`v`i'_5m4' if e(sample)
					loc fvrvlist14 = strltrim(`"`fvrvlist14' `v`i'_14'"')
					loc fvrvlist24 = strltrim(`"`fvrvlist24' `v`i'_24'"')
					loc fvrvlist34 = strltrim(`"`fvrvlist34' `v`i'_34'"')
					loc fvrvlist44 = strltrim(`"`fvrvlist44' `v`i'_44'"')
					loc fvrvlist54 = strltrim(`"`fvrvlist54' `v`i'_5m4'"')
					loc i=`i'+1
				}
				qui corr `fvrvlist4' if e(sample), cov
				mat `sigma4' = r(C)
				mat `v4' = trace(`sigma4'*`vtau4')
				qui corr `fvrvlist14' if e(sample), cov
				mat `sigma14' = r(C)
				mat `v14' = trace(`sigma14'*`vtau4')
				qui corr `fvrvlist24' if e(sample), cov
				mat `sigma24' = r(C)
				mat `v24' = trace(`sigma24'*`vtau4')
				qui corr `fvrvlist34' if e(sample), cov
				mat `sigma34' = r(C)
				mat `v34' = trace(`sigma34'*`vtau4')
				qui corr `fvrvlist44' if e(sample), cov
				mat `sigma44' = r(C)
				mat `v44' = trace(`sigma44'*`vtau4')
				qui corr `fvrvlist54' if e(sample), cov
				mat `sigma54' = r(C)
				mat `v54' = trace(`sigma54'*`vtau4')
				qui _estimates unhold mixedest
				qui _estimates hold mixedest, copy restore
				foreach var of varlist `fvrvlist4' {
					qui su `var' if e(sample), meanonly
					mat `mu4' = (nullmat(`mu4'),r(mean))
				}
				mat `mu4' = (`mu4',1)
				mat `m4' = `mu4'*`tau4'*`mu4''
			}
		}
		else {
			loc rvlist4 : rownames `tau4'
			loc i = 1
			foreach v of loc rvlist4 {
				cap fvexpand `v'
				if !_rc {
					loc crvlist4 = strltrim(`"`crvlist4' `v'"')
				}
				else {
					if strpos("`v'","#")==0 {
						loc v_4 = subinstr("`v'","_",".",1)
						loc crvlist4 = strltrim(`"`crvlist4' `v_4'"')
					}
					else {
						loc tempv = subinstr("`v'","#"," ",.)
						foreach w of loc tempv {
							loc x = subinstr("`w'","_",".",1)
							loc y = subinstr("`x'","c.","",1)
							loc w`i' = strltrim(`"`w`i'' `y'"')
						}
						loc v_4 = subinstr(strltrim("`w`i''")," ","#",.)
						loc crvlist4 = strltrim(`"`crvlist4' `v_4'"')
						loc i = `i'+1
					}
				}
			}
			loc frvlist4 = strltrim(subinstr("`crvlist4'","bn.",".",.))
			qui fvrevar `frvlist4'
			loc fvrvlist4 = "`r(varlist)'"
			loc i = 1
			foreach var of varlist `fvrvlist4' {
				tempvar v`i'_14 v`i'_24 v`i'_34 v`i'_44 v`i'_2m4 v`i'_3m4 v`i'_4m4 v`i'_5m4
				cap egen double `v`i'_2m4' = mean(`var') if e(sample), by(`id5' `id4' `id3' `id2')
				cap egen double `v`i'_3m4' = mean(`var') if e(sample), by(`id5' `id4' `id3')
				cap egen double `v`i'_4m4' = mean(`var') if e(sample), by(`id5' `id4')
				cap egen double `v`i'_5m4' = mean(`var') if e(sample), by(`id5')
				cap gen double `v`i'_14' = `var'-`v`i'_2m4' if e(sample)
				cap gen double `v`i'_24' = `v`i'_2m4'-`v`i'_3m4' if e(sample)
				cap gen double `v`i'_34' = `v`i'_3m4'-`v`i'_4m4' if e(sample)
				cap gen double `v`i'_44' = `v`i'_4m4'-`v`i'_5m4' if e(sample)
				loc fvrvlist14 = strltrim(`"`fvrvlist14' `v`i'_14'"')
				loc fvrvlist24 = strltrim(`"`fvrvlist24' `v`i'_24'"')
				loc fvrvlist34 = strltrim(`"`fvrvlist34' `v`i'_34'"')
				loc fvrvlist44 = strltrim(`"`fvrvlist44' `v`i'_44'"')
				loc fvrvlist54 = strltrim(`"`fvrvlist54' `v`i'_5m4'"')
				loc i=`i'+1
			}
			qui corr `fvrvlist4' if e(sample), cov
			mat `sigma4' = r(C)
			mat `v4' = trace(`sigma4'*`tau4')
			qui corr `fvrvlist14' if e(sample), cov
			mat `sigma14' = r(C)
			mat `v14' = trace(`sigma14'*`tau4')
			qui corr `fvrvlist24' if e(sample), cov
			mat `sigma24' = r(C)
			mat `v24' = trace(`sigma24'*`tau4')
			qui corr `fvrvlist34' if e(sample), cov
			mat `sigma34' = r(C)
			mat `v34' = trace(`sigma34'*`tau4')
			qui corr `fvrvlist44' if e(sample), cov
			mat `sigma44' = r(C)
			mat `v44' = trace(`sigma44'*`tau4')
			qui corr `fvrvlist54' if e(sample), cov
			mat `sigma54' = r(C)
			mat `v54' = trace(`sigma54'*`tau4')
			qui _estimates unhold mixedest
			qui _estimates hold mixedest, copy restore
			foreach var of varlist `fvrvlist4' {
				qui su `var' if e(sample), meanonly
				mat `mu4' = (nullmat(`mu4'),r(mean))
			}
			mat `m4' = `mu4'*`tau4'*`mu4''
		}
	}
	else {
		mat `v4' = 0
		mat `v14' = 0
		mat `v24' = 0
		mat `v34' = 0
		mat `v44' = 0
		mat `v54' = 0
		mat `m4' = 0
	}
	//v5 & m5
	qui _estimates unhold mixedest
	qui _estimates hold mixedest, copy restore
	qui estat recov, relev(`id5')
	cap conf mat r(Cov)
	if !_rc {
		mat `tau5' = r(Cov)
		loc relist5 : rownames `tau5'
		loc ccheck5 = word("`relist5'",wordcount("`relist5'"))
		if "`ccheck5'"=="_cons" {
			loc rcheck5 = rowsof(`tau5')
			if `rcheck5'==1 {
				mat `v5' = 0
				mat `v15' = 0
				mat `v25' = 0
				mat `v35' = 0
				mat `v45' = 0
				mat `v55' = 0
				mat `m5' = `tau5'[1,1]
			}
			else {
				loc i = 1
				mat `vtau5' = `tau5'[1..rowsof(`tau5')-1,1..colsof(`tau5')-1]
				loc rvlist5 : rownames `vtau5'
				foreach v of loc rvlist5 {
					cap fvexpand `v'
					if !_rc {
						loc crvlist5 = strltrim(`"`crvlist5' `v'"')
					}
					else {
						if strpos("`v'","#")==0 {
							loc v_5 = subinstr("`v'","_",".",1)
							loc crvlist5 = strltrim(`"`crvlist5' `v_5'"')
						}
						else {
							loc tempv = subinstr("`v'","#"," ",.)
							foreach w of loc tempv {
								loc x = subinstr("`w'","_",".",1)
								loc y = subinstr("`x'","c.","",1)
								loc w`i' = strltrim(`"`w`i'' `y'"')
							}
							loc v_5 = subinstr(strltrim("`w`i''")," ","#",.)
							loc crvlist5 = strltrim(`"`crvlist5' `v_5'"')
							loc i = `i'+1
						}
					}
				}
				loc frvlist5 = strltrim(subinstr("`crvlist5'","bn.",".",.))
				qui fvrevar `frvlist5'
				loc fvrvlist5 = "`r(varlist)'"
				loc i = 1
				foreach var of varlist `fvrvlist5' {
					tempvar v`i'_15 v`i'_25 v`i'_35 v`i'_45 v`i'_2m5 v`i'_3m5 v`i'_4m5 v`i'_5m5
					cap egen double `v`i'_2m5' = mean(`var') if e(sample), by(`id5' `id4' `id3' `id2')
					cap egen double `v`i'_3m5' = mean(`var') if e(sample), by(`id5' `id4' `id3')
					cap egen double `v`i'_4m5' = mean(`var') if e(sample), by(`id5' `id4')
					cap egen double `v`i'_5m5' = mean(`var') if e(sample), by(`id5')
					cap gen double `v`i'_15' = `var'-`v`i'_2m5' if e(sample)
					cap gen double `v`i'_25' = `v`i'_2m5'-`v`i'_3m5' if e(sample)
					cap gen double `v`i'_35' = `v`i'_3m5'-`v`i'_4m5' if e(sample)
					cap gen double `v`i'_45' = `v`i'_4m5'-`v`i'_5m5' if e(sample)
					loc fvrvlist15 = strltrim(`"`fvrvlist15' `v`i'_15'"')
					loc fvrvlist25 = strltrim(`"`fvrvlist25' `v`i'_25'"')
					loc fvrvlist35 = strltrim(`"`fvrvlist35' `v`i'_35'"')
					loc fvrvlist45 = strltrim(`"`fvrvlist45' `v`i'_45'"')
					loc fvrvlist55 = strltrim(`"`fvrvlist55' `v`i'_5m5'"')
					loc i=`i'+1
				}
				qui corr `fvrvlist5' if e(sample), cov
				mat `sigma5' = r(C)
				mat `v5' = trace(`sigma5'*`vtau5')
				qui corr `fvrvlist15' if e(sample), cov
				mat `sigma15' = r(C)
				mat `v15' = trace(`sigma15'*`vtau5')
				qui corr `fvrvlist25' if e(sample), cov
				mat `sigma25' = r(C)
				mat `v25' = trace(`sigma25'*`vtau5')
				qui corr `fvrvlist35' if e(sample), cov
				mat `sigma35' = r(C)
				mat `v35' = trace(`sigma35'*`vtau5')
				qui corr `fvrvlist45' if e(sample), cov
				mat `sigma45' = r(C)
				mat `v45' = trace(`sigma45'*`vtau5')
				qui corr `fvrvlist55' if e(sample), cov
				mat `sigma55' = r(C)
				mat `v55' = trace(`sigma55'*`vtau5')
				qui _estimates unhold mixedest
				qui _estimates hold mixedest, copy restore
				foreach var of varlist `fvrvlist5' {
					qui su `var' if e(sample), meanonly
					mat `mu5' = (nullmat(`mu5'),r(mean))
				}
				mat `mu5' = (`mu5',1)
				mat `m5' = `mu5'*`tau5'*`mu5''
			}
		}
		else {
			loc rvlist5 : rownames `tau5'
			loc i = 1
			foreach v of loc rvlist5 {
				cap fvexpand `v'
				if !_rc {
					loc crvlist5 = strltrim(`"`crvlist5' `v'"')
				}
				else {
					if strpos("`v'","#")==0 {
						loc v_5 = subinstr("`v'","_",".",1)
						loc crvlist5 = strltrim(`"`crvlist5' `v_5'"')
					}
					else {
						loc tempv = subinstr("`v'","#"," ",.)
						foreach w of loc tempv {
							loc x = subinstr("`w'","_",".",1)
							loc y = subinstr("`x'","c.","",1)
							loc w`i' = strltrim(`"`w`i'' `y'"')
						}
						loc v_5 = subinstr(strltrim("`w`i''")," ","#",.)
						loc crvlist5 = strltrim(`"`crvlist5' `v_5'"')
						loc i = `i'+1
					}
				}
			}
			loc frvlist5 = strltrim(subinstr("`crvlist5'","bn.",".",.))
			qui fvrevar `frvlist5'
			loc fvrvlist5 = "`r(varlist)'"
			loc i = 1
			foreach var of varlist `fvrvlist5' {
				tempvar v`i'_15 v`i'_25 v`i'_35 v`i'_45 v`i'_2m5 v`i'_3m5 v`i'_4m5 v`i'_5m5
				cap egen double `v`i'_2m5' = mean(`var') if e(sample), by(`id5' `id4' `id3' `id2')
				cap egen double `v`i'_3m5' = mean(`var') if e(sample), by(`id5' `id4' `id3')
				cap egen double `v`i'_4m5' = mean(`var') if e(sample), by(`id5' `id4')
				cap egen double `v`i'_5m5' = mean(`var') if e(sample), by(`id5')
				cap gen double `v`i'_15' = `var'-`v`i'_2m5' if e(sample)
				cap gen double `v`i'_25' = `v`i'_2m5'-`v`i'_3m5' if e(sample)
				cap gen double `v`i'_35' = `v`i'_3m5'-`v`i'_4m5' if e(sample)
				cap gen double `v`i'_45' = `v`i'_4m5'-`v`i'_5m5' if e(sample)
				loc fvrvlist15 = strltrim(`"`fvrvlist15' `v`i'_15'"')
				loc fvrvlist25 = strltrim(`"`fvrvlist25' `v`i'_25'"')
				loc fvrvlist35 = strltrim(`"`fvrvlist35' `v`i'_35'"')
				loc fvrvlist45 = strltrim(`"`fvrvlist45' `v`i'_45'"')
				loc fvrvlist55 = strltrim(`"`fvrvlist55' `v`i'_5m5'"')
				loc i=`i'+1
			}
			qui corr `fvrvlist5' if e(sample), cov
			mat `sigma5' = r(C)
			mat `v5' = trace(`sigma5'*`tau5')
			qui corr `fvrvlist15' if e(sample), cov
			mat `sigma15' = r(C)
			mat `v15' = trace(`sigma15'*`tau5')
			qui corr `fvrvlist25' if e(sample), cov
			mat `sigma25' = r(C)
			mat `v25' = trace(`sigma25'*`tau5')
			qui corr `fvrvlist35' if e(sample), cov
			mat `sigma35' = r(C)
			mat `v35' = trace(`sigma35'*`tau5')
			qui corr `fvrvlist45' if e(sample), cov
			mat `sigma45' = r(C)
			mat `v45' = trace(`sigma45'*`tau5')
			qui corr `fvrvlist55' if e(sample), cov
			mat `sigma55' = r(C)
			mat `v55' = trace(`sigma55'*`tau5')
			qui _estimates unhold mixedest
			qui _estimates hold mixedest, copy restore
			foreach var of varlist `fvrvlist5' {
				qui su `var' if e(sample), meanonly
				mat `mu5' = (nullmat(`mu5'),r(mean))
			}
			mat `m5' = `mu5'*`tau5'*`mu5''
		}
	}
	else {
		mat `v5' = 0
		mat `v15' = 0
		mat `v25' = 0
		mat `v35' = 0
		mat `v45' = 0
		mat `v55' = 0
		mat `m5' = 0
	}
	tempname var1 var2 var3 var4 var5 tvar R2_f1_1 R2_v12_1 R2_v13_1 R2_v14_1 R2_v15_1 Resid_1 R2_f2_2 R2_v22_2 R2_v23_2 R2_v24_2 R2_v25_2 R2_m2_2 R2_f3_3 R2_v32_3 R2_v33_3 R2_v34_3 R2_v35_3 R2_m3_3 R2_f4_4 R2_v42_4 R2_v43_4 R2_v44_4 R2_v45_4 R2_m4_4 R2_f5_5 R2_v52_5 R2_v53_5 R2_v54_5 R2_v55_5 R2_m5_5 R2_f1_t R2_f2_t R2_f3_t R2_f4_t R2_f5_t R2_f_t R2_v12_t R2_v22_t R2_v32_t R2_v42_t R2_v52_t R2_v2_t R2_v13_t R2_v23_t R2_v33_t R2_v43_t R2_v53_t R2_v3_t R2_v14_t R2_v24_t R2_v34_t R2_v44_t R2_v54_t R2_v4_t R2_v15_t R2_v25_t R2_v35_t R2_v45_t R2_v55_t R2_v5_t R2_v_t R2_m2_t R2_m3_t R2_m4_t R2_m5_t R2_m_t R2_fv_t R2_fvm_t Resid_t R2_L1_t R2_L2_t R2_L3_t R2_L4_t R2_L5_t R2
	sca `var1' = `f1'[1,1] + `v12'[1,1] + `v13'[1,1] + `v14'[1,1] + `v15'[1,1] + `s2'
	sca `var2' = `f2'[1,1] + `v22'[1,1] + `v23'[1,1] + `v24'[1,1] + `v25'[1,1] + `m2'[1,1]
	sca `var3' = `f3'[1,1] + `v32'[1,1] + `v33'[1,1] + `v34'[1,1] + `v35'[1,1] + `m3'[1,1]
	sca `var4' = `f4'[1,1] + `v42'[1,1] + `v43'[1,1] + `v44'[1,1] + `v45'[1,1] + `m4'[1,1]
	sca `var5' = `f5'[1,1] + `v52'[1,1] + `v53'[1,1] + `v54'[1,1] + `v55'[1,1] + `m5'[1,1]
	sca `tvar' = `var1' + `var2' + `var3' + `var4' + `var5'
	sca `R2_f1_1' = `f1'[1,1]/`var1'
	sca `R2_v12_1' = `v12'[1,1]/`var1'
	sca `R2_v13_1' = `v13'[1,1]/`var1'
	sca `R2_v14_1' = `v14'[1,1]/`var1'
	sca `R2_v15_1' = `v15'[1,1]/`var1'
	sca `Resid_1' = `s2'/`var1'
	sca `R2_f2_2' = `f2'[1,1]/`var2'
	sca `R2_v22_2' = `v22'[1,1]/`var2'
	sca `R2_v23_2' = `v23'[1,1]/`var2'
	sca `R2_v24_2' = `v24'[1,1]/`var2'
	sca `R2_v25_2' = `v25'[1,1]/`var2'
	sca `R2_m2_2' = `m2'[1,1]/`var2'
	sca `R2_f3_3' = `f3'[1,1]/`var3'
	sca `R2_v32_3' = `v32'[1,1]/`var3'
	sca `R2_v33_3' = `v33'[1,1]/`var3'
	sca `R2_v34_3' = `v34'[1,1]/`var3'
	sca `R2_v35_3' = `v35'[1,1]/`var3'
	sca `R2_m3_3' = `m3'[1,1]/`var3'
	sca `R2_f4_4' = `f4'[1,1]/`var4'
	sca `R2_v42_4' = `v42'[1,1]/`var4'
	sca `R2_v43_4' = `v43'[1,1]/`var4'
	sca `R2_v44_4' = `v44'[1,1]/`var4'
	sca `R2_v45_4' = `v45'[1,1]/`var4'
	sca `R2_m4_4' = `m4'[1,1]/`var4'
	sca `R2_f5_5' = `f5'[1,1]/`var5'
	sca `R2_v52_5' = `v52'[1,1]/`var5'
	sca `R2_v53_5' = `v53'[1,1]/`var5'
	sca `R2_v54_5' = `v54'[1,1]/`var5'
	sca `R2_v55_5' = `v55'[1,1]/`var5'
	sca `R2_m5_5' = `m5'[1,1]/`var5'
	sca `R2_f1_t' = `f1'[1,1]/`tvar'
	sca `R2_f2_t' = `f2'[1,1]/`tvar'
	sca `R2_f3_t' = `f3'[1,1]/`tvar'
	sca `R2_f4_t' = `f4'[1,1]/`tvar'
	sca `R2_f5_t' = `f5'[1,1]/`tvar'
	sca `R2_f_t' = `f'[1,1]/`tvar'
	sca `R2_v12_t' = `v12'[1,1]/`tvar'
	sca `R2_v22_t' = `v22'[1,1]/`tvar'
	sca `R2_v32_t' = `v32'[1,1]/`tvar'
	sca `R2_v42_t' = `v42'[1,1]/`tvar'
	sca `R2_v52_t' = `v52'[1,1]/`tvar'
	sca `R2_v2_t' = `v2'[1,1]/`tvar'
	sca `R2_v13_t' = `v13'[1,1]/`tvar'
	sca `R2_v23_t' = `v23'[1,1]/`tvar'
	sca `R2_v33_t' = `v33'[1,1]/`tvar'
	sca `R2_v43_t' = `v43'[1,1]/`tvar'
	sca `R2_v53_t' = `v53'[1,1]/`tvar'
	sca `R2_v3_t' = `v3'[1,1]/`tvar'
	sca `R2_v14_t' = `v14'[1,1]/`tvar'
	sca `R2_v24_t' = `v24'[1,1]/`tvar'
	sca `R2_v34_t' = `v34'[1,1]/`tvar'
	sca `R2_v44_t' = `v44'[1,1]/`tvar'
	sca `R2_v54_t' = `v54'[1,1]/`tvar'
	sca `R2_v4_t' = `v4'[1,1]/`tvar'
	sca `R2_v15_t' = `v15'[1,1]/`tvar'
	sca `R2_v25_t' = `v25'[1,1]/`tvar'
	sca `R2_v35_t' = `v35'[1,1]/`tvar'
	sca `R2_v45_t' = `v45'[1,1]/`tvar'
	sca `R2_v55_t' = `v55'[1,1]/`tvar'
	sca `R2_v5_t' = `v5'[1,1]/`tvar'
	sca `R2_v_t' = (`v2'[1,1]+`v3'[1,1]+`v4'[1,1]+`v5'[1,1])/`tvar'
	sca `R2_m2_t' = `m2'[1,1]/`tvar'
	sca `R2_m3_t' = `m3'[1,1]/`tvar'
	sca `R2_m4_t' = `m4'[1,1]/`tvar'
	sca `R2_m5_t' = `m5'[1,1]/`tvar'
	sca `R2_m_t' = (`m2'[1,1]+`m3'[1,1]+`m4'[1,1]+`m5'[1,1])/`tvar'
	sca `R2_fv_t' = (`f'[1,1]+`v2'[1,1]+`v3'[1,1]+`v4'[1,1]+`v5'[1,1])/`tvar'
	sca `R2_fvm_t' = (`f'[1,1]+`v2'[1,1]+`v3'[1,1]+`v4'[1,1]+`v5'[1,1]+`m2'[1,1]+`m3'[1,1]+`m4'[1,1]+`m5'[1,1])/`tvar'
	sca `Resid_t' = 1-`R2_fvm_t'
	sca `R2_L1_t' = `var1'/`tvar'
	sca `R2_L2_t' = `var2'/`tvar'
	sca `R2_L3_t' = `var3'/`tvar'
	sca `R2_L4_t' = `var4'/`tvar'
	sca `R2_L5_t' = `var5'/`tvar'
	di "{txt}mlmr2: R-Squared Measures for Mixed Models"
	di _newline"  Level-1 Model-Implied Variance of ""`dv'"" = {res}" `var1' "{txt} (Prop. of Total = {res}" %5.4f `R2_L1_t' "{txt})"_continue
	di _newline"  Level-2 Model-Implied Variance of ""`dv'"" = {res}" `var2' "{txt} (Prop. of Total = {res}" %5.4f `R2_L2_t' "{txt})"_continue
	di _newline"  Level-3 Model-Implied Variance of ""`dv'"" = {res}" `var3' "{txt} (Prop. of Total = {res}" %5.4f `R2_L3_t' "{txt})"_continue
	di _newline"  Level-4 Model-Implied Variance of ""`dv'"" = {res}" `var4' "{txt} (Prop. of Total = {res}" %5.4f `R2_L4_t' "{txt})"_continue
	di _newline"  Level-5 Model-Implied Variance of ""`dv'"" = {res}" `var5' "{txt} (Prop. of Total = {res}" %5.4f `R2_L5_t' "{txt})"_continue
	di _newline"    Total Model-Implied Variance of ""`dv'"" = {res}" `tvar'
	di _newline"{txt}{hline 16}{c TT}{hline 68}"_continue
	di _newline"   R-Squared    {c |}                           Interpretation                           "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"    Level-1     {c |}       Proportion of level-1 outcome variance explained by...       "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"  R2f1 = {res}" %5.4f `R2_f1_1'  "{txt} {c |} the level-1 portion of predictors via fixed slopes.                "_continue
	di _newline" R2v12 = {res}" %5.4f `R2_v12_1' "{txt} {c |} the level-1 portion of predictors via level-2 random slope (co)var."_continue
	di _newline" R2v13 = {res}" %5.4f `R2_v13_1' "{txt} {c |} the level-1 portion of predictors via level-3 random slope (co)var."_continue
	di _newline" R2v14 = {res}" %5.4f `R2_v14_1' "{txt} {c |} the level-1 portion of predictors via level-4 random slope (co)var."_continue
	di _newline" R2v15 = {res}" %5.4f `R2_v15_1' "{txt} {c |} the level-1 portion of predictors via level-5 random slope (co)var."_continue
	di _newline" Resid = {res}" %5.4f `Resid_1'  "{txt} {c |} level-1 residuals (i.e., proportion of unexplained variance).      "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"    Level-2     {c |}       Proportion of level-2 outcome variance explained by...       "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"  R2f2 = {res}" %5.4f `R2_f2_2'  "{txt} {c |} the level-2 portion of predictors via fixed slopes.                "_continue
	di _newline" R2v22 = {res}" %5.4f `R2_v22_2' "{txt} {c |} the level-2 portion of predictors via level-2 random slope (co)var."_continue
	di _newline" R2v23 = {res}" %5.4f `R2_v23_2' "{txt} {c |} the level-2 portion of predictors via level-3 random slope (co)var."_continue
	di _newline" R2v24 = {res}" %5.4f `R2_v24_2' "{txt} {c |} the level-2 portion of predictors via level-4 random slope (co)var."_continue
	di _newline" R2v25 = {res}" %5.4f `R2_v25_2' "{txt} {c |} the level-2 portion of predictors via level-5 random slope (co)var."_continue
	di _newline"  R2m2 = {res}" %5.4f `R2_m2_2'  "{txt} {c |} level-2 outcome means via level-2 random intercept variation.      "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"    Level-3     {c |}       Proportion of level-3 outcome variance explained by...       "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"  R2f3 = {res}" %5.4f `R2_f3_3'  "{txt} {c |} the level-3 portion of predictors via fixed slopes.                "_continue
	di _newline" R2v32 = {res}" %5.4f `R2_v32_3' "{txt} {c |} the level-3 portion of predictors via level-2 random slope (co)var."_continue
	di _newline" R2v33 = {res}" %5.4f `R2_v33_3' "{txt} {c |} the level-3 portion of predictors via level-3 random slope (co)var."_continue
	di _newline" R2v34 = {res}" %5.4f `R2_v34_3' "{txt} {c |} the level-3 portion of predictors via level-4 random slope (co)var."_continue
	di _newline" R2v35 = {res}" %5.4f `R2_v35_3' "{txt} {c |} the level-3 portion of predictors via level-5 random slope (co)var."_continue
	di _newline"  R2m3 = {res}" %5.4f `R2_m3_3'  "{txt} {c |} level-3 outcome means via level-3 random intercept variation.      "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"    Level-4     {c |}       Proportion of level-4 outcome variance explained by...       "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"  R2f4 = {res}" %5.4f `R2_f4_4'  "{txt} {c |} the level-4 portion of predictors via fixed slopes.                "_continue
	di _newline" R2v42 = {res}" %5.4f `R2_v42_4' "{txt} {c |} the level-4 portion of predictors via level-2 random slope (co)var."_continue
	di _newline" R2v43 = {res}" %5.4f `R2_v43_4' "{txt} {c |} the level-4 portion of predictors via level-3 random slope (co)var."_continue
	di _newline" R2v44 = {res}" %5.4f `R2_v44_4' "{txt} {c |} the level-4 portion of predictors via level-4 random slope (co)var."_continue
	di _newline" R2v45 = {res}" %5.4f `R2_v45_4' "{txt} {c |} the level-4 portion of predictors via level-5 random slope (co)var."_continue
	di _newline"  R2m4 = {res}" %5.4f `R2_m4_4'  "{txt} {c |} level-4 outcome means via level-4 random intercept variation.      "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"    Level-5     {c |}       Proportion of level-5 outcome variance explained by...       "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"  R2f5 = {res}" %5.4f `R2_f5_5'  "{txt} {c |} the level-5 portion of predictors via fixed slopes.                "_continue
	di _newline" R2v52 = {res}" %5.4f `R2_v52_5' "{txt} {c |} the level-5 portion of predictors via level-2 random slope (co)var."_continue
	di _newline" R2v53 = {res}" %5.4f `R2_v53_5' "{txt} {c |} the level-5 portion of predictors via level-3 random slope (co)var."_continue
	di _newline" R2v54 = {res}" %5.4f `R2_v54_5' "{txt} {c |} the level-5 portion of predictors via level-4 random slope (co)var."_continue
	di _newline" R2v55 = {res}" %5.4f `R2_v55_5' "{txt} {c |} the level-5 portion of predictors via level-5 random slope (co)var."_continue
	di _newline"  R2m5 = {res}" %5.4f `R2_m5_5'  "{txt} {c |} level-5 outcome means via level-5 random intercept variation.      "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"     Total      {c |}        Proportion of total outcome variance explained by...        "_continue
	di _newline"{hline 16}{c +}{hline 68}"_continue
	di _newline"  R2f1 = {res}" %5.4f `R2_f1_t'  "{txt} {c |} the level-1 portion of predictors via fixed slopes.                "_continue
	di _newline"  R2f2 = {res}" %5.4f `R2_f2_t'  "{txt} {c |} the level-2 portion of predictors via fixed slopes.                "_continue
	di _newline"  R2f3 = {res}" %5.4f `R2_f3_t'  "{txt} {c |} the level-3 portion of predictors via fixed slopes.                "_continue
	di _newline"  R2f4 = {res}" %5.4f `R2_f4_t'  "{txt} {c |} the level-4 portion of predictors via fixed slopes.                "_continue
	di _newline"  R2f5 = {res}" %5.4f `R2_f5_t'  "{txt} {c |} the level-5 portion of predictors via fixed slopes.                "_continue
	di _newline" R2v12 = {res}" %5.4f `R2_v12_t' "{txt} {c |} the level-1 portion of predictors via level-2 random slope (co)var."_continue
	di _newline" R2v22 = {res}" %5.4f `R2_v22_t' "{txt} {c |} the level-2 portion of predictors via level-2 random slope (co)var."_continue
	di _newline" R2v32 = {res}" %5.4f `R2_v32_t' "{txt} {c |} the level-3 portion of predictors via level-2 random slope (co)var."_continue
	di _newline" R2v42 = {res}" %5.4f `R2_v42_t' "{txt} {c |} the level-4 portion of predictors via level-2 random slope (co)var."_continue
	di _newline" R2v52 = {res}" %5.4f `R2_v52_t' "{txt} {c |} the level-5 portion of predictors via level-2 random slope (co)var."_continue
	di _newline"  R2v2 = {res}" %5.4f `R2_v2_t'  "{txt} {c |} all predictors via level-2 random slope (co)variation.             "_continue
	di _newline" R2v13 = {res}" %5.4f `R2_v13_t' "{txt} {c |} the level-1 portion of predictors via level-3 random slope (co)var."_continue
	di _newline" R2v23 = {res}" %5.4f `R2_v23_t' "{txt} {c |} the level-2 portion of predictors via level-3 random slope (co)var."_continue
	di _newline" R2v33 = {res}" %5.4f `R2_v33_t' "{txt} {c |} the level-3 portion of predictors via level-3 random slope (co)var."_continue
	di _newline" R2v43 = {res}" %5.4f `R2_v43_t' "{txt} {c |} the level-4 portion of predictors via level-3 random slope (co)var."_continue
	di _newline" R2v53 = {res}" %5.4f `R2_v53_t' "{txt} {c |} the level-5 portion of predictors via level-3 random slope (co)var."_continue
	di _newline"  R2v3 = {res}" %5.4f `R2_v3_t'  "{txt} {c |} all predictors via level-3 random slope (co)variation.             "_continue
	di _newline" R2v14 = {res}" %5.4f `R2_v14_t' "{txt} {c |} the level-1 portion of predictors via level-4 random slope (co)var."_continue
	di _newline" R2v24 = {res}" %5.4f `R2_v24_t' "{txt} {c |} the level-2 portion of predictors via level-4 random slope (co)var."_continue
	di _newline" R2v34 = {res}" %5.4f `R2_v34_t' "{txt} {c |} the level-3 portion of predictors via level-4 random slope (co)var."_continue
	di _newline" R2v44 = {res}" %5.4f `R2_v44_t' "{txt} {c |} the level-4 portion of predictors via level-4 random slope (co)var."_continue
	di _newline" R2v54 = {res}" %5.4f `R2_v54_t' "{txt} {c |} the level-5 portion of predictors via level-4 random slope (co)var."_continue
	di _newline"  R2v4 = {res}" %5.4f `R2_v4_t'  "{txt} {c |} all predictors via level-4 random slope (co)variation.             "_continue
	di _newline" R2v15 = {res}" %5.4f `R2_v15_t' "{txt} {c |} the level-1 portion of predictors via level-5 random slope (co)var."_continue
	di _newline" R2v25 = {res}" %5.4f `R2_v25_t' "{txt} {c |} the level-2 portion of predictors via level-5 random slope (co)var."_continue
	di _newline" R2v35 = {res}" %5.4f `R2_v35_t' "{txt} {c |} the level-3 portion of predictors via level-5 random slope (co)var."_continue
	di _newline" R2v45 = {res}" %5.4f `R2_v45_t' "{txt} {c |} the level-4 portion of predictors via level-5 random slope (co)var."_continue
	di _newline" R2v55 = {res}" %5.4f `R2_v55_t' "{txt} {c |} the level-5 portion of predictors via level-5 random slope (co)var."_continue
	di _newline"  R2v5 = {res}" %5.4f `R2_v5_t'  "{txt} {c |} all predictors via level-5 random slope (co)variation.             "_continue
	di _newline"  R2m2 = {res}" %5.4f `R2_m2_t'  "{txt} {c |} level-2 outcome means via level-2 random intercept variation.      "_continue
	di _newline"  R2m3 = {res}" %5.4f `R2_m3_t'  "{txt} {c |} level-3 outcome means via level-3 random intercept variation.      "_continue
	di _newline"  R2m4 = {res}" %5.4f `R2_m4_t'  "{txt} {c |} level-4 outcome means via level-4 random intercept variation.      "_continue
	di _newline"  R2m5 = {res}" %5.4f `R2_m5_t'  "{txt} {c |} level-5 outcome means via level-5 random intercept variation.      "_continue
	di _newline"   R2f = {res}" %5.4f `R2_f_t'   "{txt} {c |} all predictors via fixed slopes.                                   "_continue
	di _newline"   R2v = {res}" %5.4f `R2_v_t'   "{txt} {c |} all predictors via random slope (co)variation.                     "_continue
	di _newline"   R2m = {res}" %5.4f `R2_m_t'   "{txt} {c |} all outcome means via random intercept variation.                  "_continue
	di _newline"  R2fv = {res}" %5.4f `R2_fv_t'  "{txt} {c |} all predictors via fixed slopes and random slope (co)variation.    "_continue
	di _newline" R2fvm = {res}" %5.4f `R2_fvm_t' "{txt} {c |} the whole model.                                                   "_continue
	di _newline" Resid = {res}" %5.4f `Resid_t'  "{txt} {c |} level-1 residuals (i.e., proportion of unexplained variance).      "_continue
	di _newline"{hline 16}{c BT}{hline 68}"
	if wordcount("`fvlist'")>0 & !mi("`fvlist'") {
		loc i = 1
		foreach var of varlist `fvfvlist' {
			tempname v`i'_1var v`i'_2var v`i'_3var v`i'_4var v`i'_5mvar
			qui su `v`i'_1' if e(sample)
			sca `v`i'_1var' = r(Var)
			loc v`i'_1vc = 0
			if `v`i'_1var'>=10^-10 & !mi(`v`i'_1var') {
				loc v`i'_1vc = 1
			}
			qui su `v`i'_2' if e(sample)
			sca `v`i'_2var' = r(Var)
			loc v`i'_2vc = 0
			if `v`i'_2var'>=10^-10 & !mi(`v`i'_2var') {
				loc v`i'_2vc = 1
			}
			qui su `v`i'_3' if e(sample)
			sca `v`i'_3var' = r(Var)
			loc v`i'_3vc = 0
			if `v`i'_3var'>=10^-10 & !mi(`v`i'_3var') {
				loc v`i'_3vc = 1
			}
			qui su `v`i'_4' if e(sample)
			sca `v`i'_4var' = r(Var)
			loc v`i'_4vc = 0
			if `v`i'_4var'>=10^-10 & !mi(`v`i'_4var') {
				loc v`i'_4vc = 1
			}
			qui su `v`i'_5m' if e(sample)
			sca `v`i'_5mvar' = r(Var)
			loc v`i'_5mvc = 0
			if `v`i'_5mvar'>=10^-10 & !mi(`v`i'_5mvar') {
				loc v`i'_5mvc = 1
			}
			if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==0 & `v`i'_4vc'==0 & `v`i'_5mvc'==0 {
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
			if (`v`i'_1vc'==1 & `v`i'_2vc'==0 & `v`i'_3vc'==1 & `v`i'_4vc'==0 & `v`i'_5mvc'==0) | (`v`i'_1vc'==0 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==0 & `v`i'_5mvc'==0)  {
				loc unconf3m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i' 
						tempname diff`i'_var
						cap gen double `diff`i'' = `v`i'_3m'-`fv' if e(sample)
						qui su `diff`i'' if e(sample)
						sca `diff`i'_var' = r(Var)
						if `diff`i'_var'<10^-10 {
							loc unconf3m = `unconf3m'+1
						}
					}
				}
				if `unconf3m'==0 {
					loc conflist_`i' = word("`fvlist'",`i')
					loc conflist = strltrim(`"`conflist' `conflist_`i''"')
				}
			}
			if (`v`i'_1vc'==1 & `v`i'_2vc'==0 & `v`i'_3vc'==0 & `v`i'_4vc'==1 & `v`i'_5mvc'==0) | (`v`i'_1vc'==0 & `v`i'_2vc'==1 & `v`i'_3vc'==0 & `v`i'_4vc'==1 & `v`i'_5mvc'==0) | (`v`i'_1vc'==0 & `v`i'_2vc'==0 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==0) {
				loc unconf4m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i' 
						tempname diff`i'_var
						cap gen double `diff`i'' = `v`i'_4m'-`fv' if e(sample)
						qui su `diff`i'' if e(sample)
						sca `diff`i'_var' = r(Var)
						if `diff`i'_var'<10^-10 {
							loc unconf4m = `unconf4m'+1
						}
					}
				}
				if `unconf4m'==0 {
					loc conflist_`i' = word("`fvlist'",`i')
					loc conflist = strltrim(`"`conflist' `conflist_`i''"')
				}
			}
			if (`v`i'_1vc'==1 & `v`i'_2vc'==0 & `v`i'_3vc'==0 & `v`i'_4vc'==0 & `v`i'_5mvc'==1) | (`v`i'_1vc'==0 & `v`i'_2vc'==1 & `v`i'_3vc'==0 & `v`i'_4vc'==0 & `v`i'_5mvc'==1) | (`v`i'_1vc'==0 & `v`i'_2vc'==0 & `v`i'_3vc'==1 & `v`i'_4vc'==0 & `v`i'_5mvc'==1) | (`v`i'_1vc'==0 & `v`i'_2vc'==0 & `v`i'_3vc'==0 & `v`i'_4vc'==1 & `v`i'_5mvc'==1) {
				loc unconf5m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i' 
						tempname diff`i'_var
						cap gen double `diff`i'' = `v`i'_5m'-`fv' if e(sample)
						qui su `diff`i'' if e(sample)
						sca `diff`i'_var' = r(Var)
						if `diff`i'_var'<10^-10 {
							loc unconf5m = `unconf5m'+1
						}
					}
				}
				if `unconf5m'==0 {
					loc conflist_`i' = word("`fvlist'",`i')
					loc conflist = strltrim(`"`conflist' `conflist_`i''"')
				}
			}
			if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==0 & `v`i'_5mvc'==0 {
				loc unconf2m = 0
				loc unconf2 = 0
				loc unconf3m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i'_2m diff`i'_2 diff`i'_3m
						tempname diff`i'_2m_var diff`i'_2_var diff`i'_3m_var
						cap gen double `diff`i'_2m' = `v`i'_2m'-`fv' if e(sample)
						qui su `diff`i'_2m' if e(sample)
						sca `diff`i'_2m_var' = r(Var)
						cap gen double `diff`i'_2' = `v`i'_2'-`fv' if e(sample)
						qui su `diff`i'_2' if e(sample)
						sca `diff`i'_2_var' = r(Var)
						cap gen double `diff`i'_3m' = `v`i'_3m'-`fv' if e(sample)
						qui su `diff`i'_3m' if e(sample)
						sca `diff`i'_3m_var' = r(Var)
						if `diff`i'_2m_var'<10^-10 {
							loc unconf2m = `unconf2m'+1
						}
						if `diff`i'_2_var'<10^-10 {
							loc unconf2 = `unconf2'+1
						}
						if `diff`i'_3m_var'<10^-10 {
							loc unconf3m = `unconf3m'+1
						}
					}
				}
				if `unconf2'>0 & `unconf3m'>0 {
					loc unconf2m = `unconf2m'+1
				}
				if `unconf2m'==0 {
					loc conflist_`i' = word("`fvlist'",`i')
					loc conflist = strltrim(`"`conflist' `conflist_`i''"')
				}
			}
			if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==0 & `v`i'_4vc'==1 & `v`i'_5mvc'==0 {
				loc unconf2m = 0
				loc unconf2 = 0
				loc unconf4m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i'_2m diff`i'_2 diff`i'_4m
						tempname diff`i'_2m_var diff`i'_2_var diff`i'_4m_var
						cap gen double `diff`i'_2m' = `v`i'_2m'-`fv' if e(sample)
						qui su `diff`i'_2m' if e(sample)
						sca `diff`i'_2m_var' = r(Var)
						cap gen double `diff`i'_2' = `v`i'_2'-`fv' if e(sample)
						qui su `diff`i'_2' if e(sample)
						sca `diff`i'_2_var' = r(Var)
						cap gen double `diff`i'_4m' = `v`i'_4m'-`fv' if e(sample)
						qui su `diff`i'_4m' if e(sample)
						sca `diff`i'_4m_var' = r(Var)
						if `diff`i'_2m_var'<10^-10 {
							loc unconf2m = `unconf2m'+1
						}
						if `diff`i'_2_var'<10^-10 {
							loc unconf2 = `unconf2'+1
						}
						if `diff`i'_4m_var'<10^-10 {
							loc unconf4m = `unconf4m'+1
						}
					}
				}
				if `unconf2'>0 & `unconf4m'>0 {
					loc unconf2m = `unconf2m'+1
				}
				if `unconf2m'==0 {
					loc conflist_`i' = word("`fvlist'",`i')
					loc conflist = strltrim(`"`conflist' `conflist_`i''"')
				}
			}
			if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==0 & `v`i'_4vc'==0 & `v`i'_5mvc'==1 {
				loc unconf2m = 0
				loc unconf2 = 0
				loc unconf5m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i'_2m diff`i'_2 diff`i'_5m
						tempname diff`i'_2m_var diff`i'_2_var diff`i'_5m_var
						cap gen double `diff`i'_2m' = `v`i'_2m'-`fv' if e(sample)
						qui su `diff`i'_2m' if e(sample)
						sca `diff`i'_2m_var' = r(Var)
						cap gen double `diff`i'_2' = `v`i'_2'-`fv' if e(sample)
						qui su `diff`i'_2' if e(sample)
						sca `diff`i'_2_var' = r(Var)
						cap gen double `diff`i'_5m' = `v`i'_5m'-`fv' if e(sample)
						qui su `diff`i'_5m' if e(sample)
						sca `diff`i'_5m_var' = r(Var)
						if `diff`i'_2m_var'<10^-10 {
							loc unconf2m = `unconf2m'+1
						}
						if `diff`i'_2_var'<10^-10 {
							loc unconf2 = `unconf2'+1
						}
						if `diff`i'_5m_var'<10^-10 {
							loc unconf5m = `unconf5m'+1
						}
					}
				}
				if `unconf2'>0 & `unconf5m'>0 {
					loc unconf2m = `unconf2m'+1
				}
				if `unconf2m'==0 {
					loc conflist_`i' = word("`fvlist'",`i')
					loc conflist = strltrim(`"`conflist' `conflist_`i''"')
				}
			}
			if (`v`i'_1vc'==1 & `v`i'_2vc'==0 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==0) | (`v`i'_1vc'==0 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==0) {
				loc unconf3m = 0
				loc unconf3 = 0
				loc unconf4m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i'_3m diff`i'_3 diff`i'_4m
						tempname diff`i'_3m_var diff`i'_3_var diff`i'_4m_var
						cap gen double `diff`i'_3m' = `v`i'_3m'-`fv' if e(sample)
						qui su `diff`i'_3m' if e(sample)
						sca `diff`i'_3m_var' = r(Var)
						cap gen double `diff`i'_3' = `v`i'_3'-`fv' if e(sample)
						qui su `diff`i'_3' if e(sample)
						sca `diff`i'_3_var' = r(Var)
						cap gen double `diff`i'_4m' = `v`i'_4m'-`fv' if e(sample)
						qui su `diff`i'_4m' if e(sample)
						sca `diff`i'_4m_var' = r(Var)
						if `diff`i'_3m_var'<10^-10 {
							loc unconf3m = `unconf3m'+1
						}
						if `diff`i'_3_var'<10^-10 {
							loc unconf3 = `unconf3'+1
						}
						if `diff`i'_4m_var'<10^-10 {
							loc unconf4m = `unconf4m'+1
						}
					}
				}
				if `unconf3'>0 & `unconf4m'>0 {
					loc unconf3m = `unconf3m'+1
				}
				if `unconf3m'==0 {
					loc conflist_`i' = word("`fvlist'",`i')
					loc conflist = strltrim(`"`conflist' `conflist_`i''"')
				}
			}
			if (`v`i'_1vc'==1 & `v`i'_2vc'==0 & `v`i'_3vc'==1 & `v`i'_4vc'==0 & `v`i'_5mvc'==1) | (`v`i'_1vc'==0 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==0 & `v`i'_5mvc'==1) {
				loc unconf3m = 0
				loc unconf3 = 0
				loc unconf5m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i'_3m diff`i'_3 diff`i'_5m
						tempname diff`i'_3m_var diff`i'_3_var diff`i'_5m_var
						cap gen double `diff`i'_3m' = `v`i'_3m'-`fv' if e(sample)
						qui su `diff`i'_3m' if e(sample)
						sca `diff`i'_3m_var' = r(Var)
						cap gen double `diff`i'_3' = `v`i'_3'-`fv' if e(sample)
						qui su `diff`i'_3' if e(sample)
						sca `diff`i'_3_var' = r(Var)
						cap gen double `diff`i'_5m' = `v`i'_5m'-`fv' if e(sample)
						qui su `diff`i'_5m' if e(sample)
						sca `diff`i'_5m_var' = r(Var)
						if `diff`i'_3m_var'<10^-10 {
							loc unconf3m = `unconf3m'+1
						}
						if `diff`i'_3_var'<10^-10 {
							loc unconf3 = `unconf3'+1
						}
						if `diff`i'_5m_var'<10^-10 {
							loc unconf5m = `unconf5m'+1
						}
					}
				}
				if `unconf3'>0 & `unconf5m'>0 {
					loc unconf3m = `unconf3m'+1
				}
				if `unconf3m'==0 {
					loc conflist_`i' = word("`fvlist'",`i')
					loc conflist = strltrim(`"`conflist' `conflist_`i''"')
				}
			}
			if (`v`i'_1vc'==1 & `v`i'_2vc'==0 & `v`i'_3vc'==0 & `v`i'_4vc'==1 & `v`i'_5mvc'==1) | (`v`i'_1vc'==0 & `v`i'_2vc'==1 & `v`i'_3vc'==0 & `v`i'_4vc'==1 & `v`i'_5mvc'==1) | (`v`i'_1vc'==0 & `v`i'_2vc'==0 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==1) {
				loc unconf4m = 0
				loc unconf4 = 0
				loc unconf5m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i'_4m diff`i'_4 diff`i'_5m
						tempname diff`i'_4m_var diff`i'_4_var diff`i'_5m_var
						cap gen double `diff`i'_4m' = `v`i'_4m'-`fv' if e(sample)
						qui su `diff`i'_4m' if e(sample)
						sca `diff`i'_4m_var' = r(Var)
						cap gen double `diff`i'_4' = `v`i'_4'-`fv' if e(sample)
						qui su `diff`i'_4' if e(sample)
						sca `diff`i'_4_var' = r(Var)
						cap gen double `diff`i'_5m' = `v`i'_5m'-`fv' if e(sample)
						qui su `diff`i'_5m' if e(sample)
						sca `diff`i'_5m_var' = r(Var)
						if `diff`i'_4m_var'<10^-10 {
							loc unconf4m = `unconf4m'+1
						}
						if `diff`i'_4_var'<10^-10 {
							loc unconf4 = `unconf4'+1
						}
						if `diff`i'_5m_var'<10^-10 {
							loc unconf5m = `unconf5m'+1
						}
					}
				}
				if `unconf4'>0 & `unconf5m'>0 {
					loc unconf4m = `unconf4m'+1
				}
				if `unconf4m'==0 {
					loc conflist_`i' = word("`fvlist'",`i')
					loc conflist = strltrim(`"`conflist' `conflist_`i''"')
				}
			}
			if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==0 {
				loc unconf2m = 0
				loc unconf2 = 0
				loc unconf3m = 0
				loc unconf3 = 0
				loc unconf4m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i'_2m diff`i'_2 diff`i'_3m diff`i'_3 diff`i'_4m
						tempname diff`i'_2m_var diff`i'_2_var diff`i'_3m_var diff`i'_3_var diff`i'_4m_var
						cap gen double `diff`i'_2m' = `v`i'_2m'-`fv' if e(sample)
						qui su `diff`i'_2m' if e(sample)
						sca `diff`i'_2m_var' = r(Var)
						cap gen double `diff`i'_2' = `v`i'_2'-`fv' if e(sample)
						qui su `diff`i'_2' if e(sample)
						sca `diff`i'_2_var' = r(Var)
						cap gen double `diff`i'_3m' = `v`i'_3m'-`fv' if e(sample)
						qui su `diff`i'_3m' if e(sample)
						sca `diff`i'_3m_var' = r(Var)
						cap gen double `diff`i'_3' = `v`i'_3'-`fv' if e(sample)
						qui su `diff`i'_3' if e(sample)
						sca `diff`i'_3_var' = r(Var)
						cap gen double `diff`i'_4m' = `v`i'_4m'-`fv' if e(sample)
						qui su `diff`i'_4m' if e(sample)
						sca `diff`i'_4m_var' = r(Var)
						if `diff`i'_2m_var'<10^-10 {
							loc unconf2m = `unconf2m'+1
						}
						if `diff`i'_2_var'<10^-10 {
							loc unconf2 = `unconf2'+1
						}
						if `diff`i'_3m_var'<10^-10 {
							loc unconf3m = `unconf3m'+1
						}
						if `diff`i'_3_var'<10^-10 {
							loc unconf3 = `unconf3'+1
						}
						if `diff`i'_4m_var'<10^-10 {
							loc unconf4m = `unconf4m'+1
						}
					}
				}
				if `unconf2'>0 & `unconf3'>0 & `unconf4m'>0 {
					loc unconf2m = `unconf2m'+1
				}
				if `unconf2'>0 & `unconf3m'>0 {
					loc unconf2m = `unconf2m'+1
				}
				if `unconf2m'==0 {
					loc conflist_`i' = word("`fvlist'",`i')
					loc conflist = strltrim(`"`conflist' `conflist_`i''"')
				}
			}
			if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==0 & `v`i'_5mvc'==1 {
				loc unconf2m = 0
				loc unconf2 = 0
				loc unconf3m = 0
				loc unconf3 = 0
				loc unconf5m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i'_2m diff`i'_2 diff`i'_3m diff`i'_3 diff`i'_5m
						tempname diff`i'_2m_var diff`i'_2_var diff`i'_3m_var diff`i'_3_var diff`i'_5m_var
						cap gen double `diff`i'_2m' = `v`i'_2m'-`fv' if e(sample)
						qui su `diff`i'_2m' if e(sample)
						sca `diff`i'_2m_var' = r(Var)
						cap gen double `diff`i'_2' = `v`i'_2'-`fv' if e(sample)
						qui su `diff`i'_2' if e(sample)
						sca `diff`i'_2_var' = r(Var)
						cap gen double `diff`i'_3m' = `v`i'_3m'-`fv' if e(sample)
						qui su `diff`i'_3m' if e(sample)
						sca `diff`i'_3m_var' = r(Var)
						cap gen double `diff`i'_3' = `v`i'_3'-`fv' if e(sample)
						qui su `diff`i'_3' if e(sample)
						sca `diff`i'_3_var' = r(Var)
						cap gen double `diff`i'_5m' = `v`i'_5m'-`fv' if e(sample)
						qui su `diff`i'_5m' if e(sample)
						sca `diff`i'_5m_var' = r(Var)
						if `diff`i'_2m_var'<10^-10 {
							loc unconf2m = `unconf2m'+1
						}
						if `diff`i'_2_var'<10^-10 {
							loc unconf2 = `unconf2'+1
						}
						if `diff`i'_3m_var'<10^-10 {
							loc unconf3m = `unconf3m'+1
						}
						if `diff`i'_3_var'<10^-10 {
							loc unconf3 = `unconf3'+1
						}
						if `diff`i'_5m_var'<10^-10 {
							loc unconf5m = `unconf5m'+1
						}
					}
				}
				if `unconf2'>0 & `unconf3'>0 & `unconf5m'>0 {
					loc unconf2m = `unconf2m'+1
				}
				if `unconf2'>0 & `unconf3m'>0 {
					loc unconf2m = `unconf2m'+1
				}
				if `unconf2m'==0 {
					loc conflist_`i' = word("`fvlist'",`i')
					loc conflist = strltrim(`"`conflist' `conflist_`i''"')
				}
			}
			if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==0 & `v`i'_4vc'==1 & `v`i'_5mvc'==1 {
				loc unconf2m = 0
				loc unconf2 = 0
				loc unconf4m = 0
				loc unconf4 = 0
				loc unconf5m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i'_2m diff`i'_2 diff`i'_4m diff`i'_4 diff`i'_5m
						tempname diff`i'_2m_var diff`i'_2_var diff`i'_4m_var diff`i'_4_var diff`i'_5m_var
						cap gen double `diff`i'_2m' = `v`i'_2m'-`fv' if e(sample)
						qui su `diff`i'_2m' if e(sample)
						sca `diff`i'_2m_var' = r(Var)
						cap gen double `diff`i'_2' = `v`i'_2'-`fv' if e(sample)
						qui su `diff`i'_2' if e(sample)
						sca `diff`i'_2_var' = r(Var)
						cap gen double `diff`i'_4m' = `v`i'_4m'-`fv' if e(sample)
						qui su `diff`i'_4m' if e(sample)
						sca `diff`i'_4m_var' = r(Var)
						cap gen double `diff`i'_4' = `v`i'_4'-`fv' if e(sample)
						qui su `diff`i'_4' if e(sample)
						sca `diff`i'_4_var' = r(Var)
						cap gen double `diff`i'_5m' = `v`i'_5m'-`fv' if e(sample)
						qui su `diff`i'_5m' if e(sample)
						sca `diff`i'_5m_var' = r(Var)
						if `diff`i'_2m_var'<10^-10 {
							loc unconf2m = `unconf2m'+1
						}
						if `diff`i'_2_var'<10^-10 {
							loc unconf2 = `unconf2'+1
						}
						if `diff`i'_4m_var'<10^-10 {
							loc unconf4m = `unconf4m'+1
						}
						if `diff`i'_4_var'<10^-10 {
							loc unconf4 = `unconf4'+1
						}
						if `diff`i'_5m_var'<10^-10 {
							loc unconf5m = `unconf5m'+1
						}
					}
				}
				if `unconf2'>0 & `unconf4'>0 & `unconf5m'>0 {
					loc unconf2m = `unconf2m'+1
				}
				if `unconf2'>0 & `unconf4m'>0 {
					loc unconf2m = `unconf2m'+1
				}
				if `unconf2m'==0 {
					loc conflist_`i' = word("`fvlist'",`i')
					loc conflist = strltrim(`"`conflist' `conflist_`i''"')
				}
			}
			if (`v`i'_1vc'==1 & `v`i'_2vc'==0 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==1) | (`v`i'_1vc'==0 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==1) {
				loc unconf3m = 0
				loc unconf3 = 0
				loc unconf4m = 0
				loc unconf4 = 0
				loc unconf5m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i'_3m diff`i'_3 diff`i'_4m diff`i'_4 diff`i'_5m
						tempname diff`i'_3m_var diff`i'_3_var diff`i'_4m_var diff`i'_4_var diff`i'_5m_var
						cap gen double `diff`i'_3m' = `v`i'_3m'-`fv' if e(sample)
						qui su `diff`i'_3m' if e(sample)
						sca `diff`i'_3m_var' = r(Var)
						cap gen double `diff`i'_3' = `v`i'_3'-`fv' if e(sample)
						qui su `diff`i'_3' if e(sample)
						sca `diff`i'_3_var' = r(Var)
						cap gen double `diff`i'_4m' = `v`i'_4m'-`fv' if e(sample)
						qui su `diff`i'_4m' if e(sample)
						sca `diff`i'_4m_var' = r(Var)
						cap gen double `diff`i'_4' = `v`i'_4'-`fv' if e(sample)
						qui su `diff`i'_4' if e(sample)
						sca `diff`i'_4_var' = r(Var)
						cap gen double `diff`i'_5m' = `v`i'_5m'-`fv' if e(sample)
						qui su `diff`i'_5m' if e(sample)
						sca `diff`i'_5m_var' = r(Var)
						if `diff`i'_3m_var'<10^-10 {
							loc unconf3m = `unconf3m'+1
						}
						if `diff`i'_3_var'<10^-10 {
							loc unconf3 = `unconf3'+1
						}
						if `diff`i'_4m_var'<10^-10 {
							loc unconf4m = `unconf4m'+1
						}
						if `diff`i'_4_var'<10^-10 {
							loc unconf4 = `unconf4'+1
						}
						if `diff`i'_5m_var'<10^-10 {
							loc unconf5m = `unconf5m'+1
						}
					}
				}
				if `unconf3'>0 & `unconf4'>0 & `unconf5m'>0 {
					loc unconf3m = `unconf3m'+1
				}
				if `unconf3'>0 & `unconf4m'>0 {
					loc unconf3m = `unconf3m'+1
				}
				if `unconf3m'==0 {
					loc conflist_`i' = word("`fvlist'",`i')
					loc conflist = strltrim(`"`conflist' `conflist_`i''"')
				}
			}
			if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==1 {
				loc unconf2m = 0
				loc unconf2 = 0
				loc unconf3m = 0
				loc unconf3 = 0
				loc unconf4m = 0
				loc unconf4 = 0
				loc unconf5m = 0
				if wordcount("`fvlist'")>1 {
					loc vc = word("`fvfvlist'",`i')
					loc complist : list fvfvlist - vc
					foreach fv of varlist `complist' {
						tempvar diff`i'_2m diff`i'_2 diff`i'_3m diff`i'_3 diff`i'_4m diff`i'_4 diff`i'_5m
						tempname diff`i'_2m_var diff`i'_2_var diff`i'_3m_var diff`i'_3_var diff`i'_4m_var diff`i'_4_var diff`i'_5m_var
						cap gen double `diff`i'_2m' = `v`i'_2m'-`fv' if e(sample)
						qui su `diff`i'_2m' if e(sample)
						sca `diff`i'_2m_var' = r(Var)
						cap gen double `diff`i'_2' = `v`i'_2'-`fv' if e(sample)
						qui su `diff`i'_2' if e(sample)
						sca `diff`i'_2_var' = r(Var)
						cap gen double `diff`i'_3m' = `v`i'_3m'-`fv' if e(sample)
						qui su `diff`i'_3m' if e(sample)
						sca `diff`i'_3m_var' = r(Var)
						cap gen double `diff`i'_3' = `v`i'_3'-`fv' if e(sample)
						qui su `diff`i'_3' if e(sample)
						sca `diff`i'_3_var' = r(Var)
						cap gen double `diff`i'_4m' = `v`i'_4m'-`fv' if e(sample)
						qui su `diff`i'_4m' if e(sample)
						sca `diff`i'_4m_var' = r(Var)
						cap gen double `diff`i'_4' = `v`i'_4'-`fv' if e(sample)
						qui su `diff`i'_4' if e(sample)
						sca `diff`i'_4_var' = r(Var)
						cap gen double `diff`i'_5m' = `v`i'_5m'-`fv' if e(sample)
						qui su `diff`i'_5m' if e(sample)
						sca `diff`i'_5m_var' = r(Var)
						if `diff`i'_2m_var'<10^-10 {
							loc unconf2m = `unconf2m'+1
						}
						if `diff`i'_2_var'<10^-10 {
							loc unconf2 = `unconf2'+1
						}
						if `diff`i'_3m_var'<10^-10 {
							loc unconf3m = `unconf3m'+1
						}
						if `diff`i'_3_var'<10^-10 {
							loc unconf3 = `unconf3'+1
						}
						if `diff`i'_4m_var'<10^-10 {
							loc unconf4m = `unconf4m'+1
						}
						if `diff`i'_4_var'<10^-10 {
							loc unconf4 = `unconf4'+1
						}
						if `diff`i'_5m_var'<10^-10 {
							loc unconf5m = `unconf5m'+1
						}
					}
				}
				if `unconf2'>0 & `unconf3'>0 & `unconf4'>0 & `unconf5m'>0 {
					loc unconf2m = `unconf2m'+1
				}
				if `unconf2'>0 & `unconf3'>0 & `unconf4m'>0 {
					loc unconf2m = `unconf2m'+1
				}
				if `unconf2'>0 & `unconf3m'>0 {
					loc unconf2m = `unconf2m'+1
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
			di as err _newline"not centered-within-clusters and their higher-level contextual fixed effects"_continue
			di as err _newline"have not been included in the model (see Rights 2023 for more info):"_continue
			di as err _newline"  `conflist'"
		}
	}
	forvalues q = 2/5 {
		if wordcount("`rvlist`q''")>0 & !mi("`rvlist`q''") {
			loc i = 1
			foreach var of varlist `fvrvlist`q'' {
				tempname v`i'_1`q'var v`i'_2`q'var v`i'_3`q'var v`i'_4`q'var v`i'_5m`q'var
				qui su `v`i'_1`q'' if e(sample)
				sca `v`i'_1`q'var' = r(Var)
				loc v`i'_1`q'vc = 0
				if `v`i'_1`q'var'>=10^-10 & !mi(`v`i'_1`q'var') {
					loc v`i'_1`q'vc = 1
				}
				qui su `v`i'_2`q'' if e(sample)
				sca `v`i'_2`q'var' = r(Var)
				loc v`i'_2`q'vc = 0
				if `v`i'_2`q'var'>=10^-10 & !mi(`v`i'_2`q'var') {
					loc v`i'_2`q'vc = 1
				}
				qui su `v`i'_3`q'' if e(sample)
				sca `v`i'_3`q'var' = r(Var)
				loc v`i'_3`q'vc = 0
				if `v`i'_3`q'var'>=10^-10 & !mi(`v`i'_3`q'var') {
					loc v`i'_3`q'vc = 1
				}
				qui su `v`i'_4`q'' if e(sample)
				sca `v`i'_4`q'var' = r(Var)
				loc v`i'_4`q'vc = 0
				if `v`i'_4`q'var'>=10^-10 & !mi(`v`i'_4`q'var') {
					loc v`i'_4`q'vc = 1
				}
				qui su `v`i'_5m`q'' if e(sample)
				sca `v`i'_5m`q'var' = r(Var)
				loc v`i'_5m`q'vc = 0
				if `v`i'_5m`q'var'>=10^-10 & !mi(`v`i'_5m`q'var') {
					loc v`i'_5m`q'vc = 1
				}
				if `v`i'_1`q'vc'==1 & `v`i'_2`q'vc'==1 & `v`i'_3`q'vc'==0 & `v`i'_4`q'vc'==0 & `v`i'_5m`q'vc'==0 {
					loc unconf2m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i' 
							tempname diff`q'_`i'_var
							cap gen double `diff`q'_`i'' = `v`i'_2m`q''-`fv`q'' if e(sample)
							qui su `diff`q'_`i'' if e(sample)
							sca `diff`q'_`i'_var' = r(Var)
							if `diff`q'_`i'_var'<10^-10 {
								loc unconf2m`q' = `unconf2m`q''+1
							}
						}
					}
					if `unconf2m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				if (`v`i'_1vc'==1 & `v`i'_2vc'==0 & `v`i'_3vc'==1 & `v`i'_4vc'==0 & `v`i'_5mvc'==0) | (`v`i'_1vc'==0 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==0 & `v`i'_5mvc'==0)  {
					loc unconf3m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i' 
							tempname diff`q'_`i'_var
							cap gen double `diff`q'_`i'' = `v`i'_3m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'' if e(sample)
							sca `diff`q'_`i'_var' = r(Var)
							if `diff`q'_`i'_var'<10^-10 {
								loc unconf3m`q' = `unconf3m`q''+1
							}
						}
					}
					if `unconf3m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				if (`v`i'_1vc'==1 & `v`i'_2vc'==0 & `v`i'_3vc'==0 & `v`i'_4vc'==1 & `v`i'_5mvc'==0) | (`v`i'_1vc'==0 & `v`i'_2vc'==1 & `v`i'_3vc'==0 & `v`i'_4vc'==1 & `v`i'_5mvc'==0) | (`v`i'_1vc'==0 & `v`i'_2vc'==0 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==0) {
					loc unconf4m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i' 
							tempname diff`q'_`i'_var
							cap gen double `diff`q'_`i'' = `v`i'_4m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'' if e(sample)
							sca `diff`q'_`i'_var' = r(Var)
							if `diff`q'_`i'_var'<10^-10 {
								loc unconf4m`q' = `unconf4m`q''+1
							}
						}
					}
					if `unconf4m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				if (`v`i'_1vc'==1 & `v`i'_2vc'==0 & `v`i'_3vc'==0 & `v`i'_4vc'==0 & `v`i'_5mvc'==1) | (`v`i'_1vc'==0 & `v`i'_2vc'==1 & `v`i'_3vc'==0 & `v`i'_4vc'==0 & `v`i'_5mvc'==1) | (`v`i'_1vc'==0 & `v`i'_2vc'==0 & `v`i'_3vc'==1 & `v`i'_4vc'==0 & `v`i'_5mvc'==1) | (`v`i'_1vc'==0 & `v`i'_2vc'==0 & `v`i'_3vc'==0 & `v`i'_4vc'==1 & `v`i'_5mvc'==1) {
					loc unconf5m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i' 
							tempname diff`q'_`i'_var
							cap gen double `diff`q'_`i'' = `v`i'_5m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'' if e(sample)
							sca `diff`q'_`i'_var' = r(Var)
							if `diff`q'_`i'_var'<10^-10 {
								loc unconf5m`q' = `unconf5m`q''+1
							}
						}
					}
					if `unconf5m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==0 & `v`i'_5mvc'==0 {
					loc unconf2m`q' = 0
					loc unconf2_`q' = 0
					loc unconf3m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i'_2m diff`q'_`i'_2 diff`q'_`i'_3m
							tempname diff`q'_`i'_2m_var diff`q'_`i'_2_var diff`q'_`i'_3m_var
							cap gen double `diff`q'_`i'_2m' = `v`i'_2m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_2m' if e(sample)
							sca `diff`q'_`i'_2m_var' = r(Var)
							cap gen double `diff`q'_`i'_2' = `v`i'_2`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_2' if e(sample)
							sca `diff`q'_`i'_2_var' = r(Var)
							cap gen double `diff`q'_`i'_3m' = `v`i'_3m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_3m' if e(sample)
							sca `diff`q'_`i'_3m_var' = r(Var)
							if `diff`q'_`i'_2m_var'<10^-10 {
								loc unconf2m`q' = `unconf2m`q''+1
							}
							if `diff`q'_`i'_2_var'<10^-10 {
								loc unconf2_`q' = `unconf2`q''+1
							}
							if `diff`q'_`i'_3m_var'<10^-10 {
								loc unconf3m`q' = `unconf3m`q''+1
							}
						}
					}
					if `unconf2_`q''>0 & `unconf3m`q''>0 {
						loc unconf2m`q' = `unconf2m`q''+1
					}
					if `unconf2m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==0 & `v`i'_4vc'==1 & `v`i'_5mvc'==0 {
					loc unconf2m`q' = 0
					loc unconf2_`q' = 0
					loc unconf4m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i'_2m diff`q'_`i'_2 diff`q'_`i'_4m
							tempname diff`q'_`i'_2m_var diff`q'_`i'_2_var diff`q'_`i'_4m_var
							cap gen double `diff`q'_`i'_2m' = `v`i'_2m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_2m' if e(sample)
							sca `diff`q'_`i'_2m_var' = r(Var)
							cap gen double `diff`q'_`i'_2' = `v`i'_2`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_2' if e(sample)
							sca `diff`q'_`i'_2_var' = r(Var)
							cap gen double `diff`q'_`i'_4m' = `v`i'_4m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_4m' if e(sample)
							sca `diff`q'_`i'_4m_var' = r(Var)
							if `diff`q'_`i'_2m_var'<10^-10 {
								loc unconf2m`q' = `unconf2m`q''+1
							}
							if `diff`q'_`i'_2_var'<10^-10 {
								loc unconf2_`q' = `unconf2_`q''+1
							}
							if `diff`q'_`i'_4m_var'<10^-10 {
								loc unconf4m`q' = `unconf4m`q''+1
							}
						}
					}
					if `unconf2_`q''>0 & `unconf4m`q''>0 {
						loc unconf2m`q' = `unconf2m`q''+1
					}
					if `unconf2m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==0 & `v`i'_4vc'==0 & `v`i'_5mvc'==1 {
					loc unconf2m`q' = 0
					loc unconf2_`q' = 0
					loc unconf5m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i'_2m diff`q'_`i'_2 diff`q'_`i'_5m
							tempname diff`q'_`i'_2m_var diff`q'_`i'_2_var diff`q'_`i'_5m_var
							cap gen double `diff`q'_`i'_2m' = `v`i'_2m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_2m' if e(sample)
							sca `diff`q'_`i'_2m_var' = r(Var)
							cap gen double `diff`q'_`i'_2' = `v`i'_2`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_2' if e(sample)
							sca `diff`q'_`i'_2_var' = r(Var)
							cap gen double `diff`q'_`i'_5m' = `v`i'_5m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_5m' if e(sample)
							sca `diff`q'_`i'_5m_var' = r(Var)
							if `diff`q'_`i'_2m_var'<10^-10 {
								loc unconf2m`q' = `unconf2m`q''+1
							}
							if `diff`q'_`i'_2_var'<10^-10 {
								loc unconf2_`q' = `unconf2_`q''+1
							}
							if `diff`q'_`i'_5m_var'<10^-10 {
								loc unconf5m`q' = `unconf5m`q''+1
							}
						}
					}
					if `unconf2_`q''>0 & `unconf5m`q''>0 {
						loc unconf2m`q' = `unconf2m`q''+1
					}
					if `unconf2m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				if (`v`i'_1vc'==1 & `v`i'_2vc'==0 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==0) | (`v`i'_1vc'==0 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==0) {
					loc unconf3m`q' = 0
					loc unconf3_`q' = 0
					loc unconf4m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i'_3m diff`q'_`i'_3 diff`q'_`i'_4m
							tempname diff`q'_`i'_3m_var diff`q'_`i'_3_var diff`q'_`i'_4m_var
							cap gen double `diff`q'_`i'_3m' = `v`i'_3m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_3m' if e(sample)
							sca `diff`q'_`i'_3m_var' = r(Var)
							cap gen double `diff`q'_`i'_3' = `v`i'_3`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_3' if e(sample)
							sca `diff`q'_`i'_3_var' = r(Var)
							cap gen double `diff`q'_`i'_4m' = `v`i'_4m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_4m' if e(sample)
							sca `diff`q'_`i'_4m_var' = r(Var)
							if `diff`q'_`i'_3m_var'<10^-10 {
								loc unconf3m`q' = `unconf3m`q''+1
							}
							if `diff`q'_`i'_3_var'<10^-10 {
								loc unconf3_`q' = `unconf3_`q''+1
							}
							if `diff`q'_`i'_4m_var'<10^-10 {
								loc unconf4m`q' = `unconf4m`q''+1
							}
						}
					}
					if `unconf3_`q''>0 & `unconf4m`q''>0 {
						loc unconf3m`q' = `unconf3m`q''+1
					}
					if `unconf3m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				if (`v`i'_1vc'==1 & `v`i'_2vc'==0 & `v`i'_3vc'==1 & `v`i'_4vc'==0 & `v`i'_5mvc'==1) | (`v`i'_1vc'==0 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==0 & `v`i'_5mvc'==1) {
					loc unconf3m`q' = 0
					loc unconf3_`q' = 0
					loc unconf5m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i'_3m diff`q'_`i'_3 diff`q'_`i'_5m
							tempname diff`q'_`i'_3m_var diff`q'_`i'_3_var diff`q'_`i'_5m_var
							cap gen double `diff`q'_`i'_3m' = `v`i'_3m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_3m' if e(sample)
							sca `diff`q'_`i'_3m_var' = r(Var)
							cap gen double `diff`q'_`i'_3' = `v`i'_3`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_3' if e(sample)
							sca `diff`q'_`i'_3_var' = r(Var)
							cap gen double `diff`q'_`i'_5m' = `v`i'_5m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_5m' if e(sample)
							sca `diff`q'_`i'_5m_var' = r(Var)
							if `diff`q'_`i'_3m_var'<10^-10 {
								loc unconf3m`q' = `unconf3m`q''+1
							}
							if `diff`q'_`i'_3_var'<10^-10 {
								loc unconf3_`q' = `unconf3_`q''+1
							}
							if `diff`q'_`i'_5m_var'<10^-10 {
								loc unconf5m`q' = `unconf5m`q''+1
							}
						}
					}
					if `unconf3_`q''>0 & `unconf5m`q''>0 {
						loc unconf3m`q' = `unconf3m`q''+1
					}
					if `unconf3m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				if (`v`i'_1vc'==1 & `v`i'_2vc'==0 & `v`i'_3vc'==0 & `v`i'_4vc'==1 & `v`i'_5mvc'==1) | (`v`i'_1vc'==0 & `v`i'_2vc'==1 & `v`i'_3vc'==0 & `v`i'_4vc'==1 & `v`i'_5mvc'==1) | (`v`i'_1vc'==0 & `v`i'_2vc'==0 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==1) {
					loc unconf4m`q' = 0
					loc unconf4_`q' = 0
					loc unconf5m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i'_4m diff`q'_`i'_4 diff`q'_`i'_5m
							tempname diff`q'_`i'_4m_var diff`q'_`i'_4_var diff`q'_`i'_5m_var
							cap gen double `diff`q'_`i'_4m' = `v`i'_4m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_4m' if e(sample)
							sca `diff`q'_`i'_4m_var' = r(Var)
							cap gen double `diff`q'_`i'_4' = `v`i'_4`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_4' if e(sample)
							sca `diff`q'_`i'_4_var' = r(Var)
							cap gen double `diff`q'_`i'_5m' = `v`i'_5m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_5m' if e(sample)
							sca `diff`q'_`i'_5m_var' = r(Var)
							if `diff`q'_`i'_4m_var'<10^-10 {
								loc unconf4m`q' = `unconf4m`q''+1
							}
							if `diff`q'_`i'_4_var'<10^-10 {
								loc unconf4_`q' = `unconf4_`q''+1
							}
							if `diff`q'_`i'_5m_var'<10^-10 {
								loc unconf5m`q' = `unconf5m`q''+1
							}
						}
					}
					if `unconf4_`q''>0 & `unconf5m`q''>0 {
						loc unconf4m`q' = `unconf4m`q''+1
					}
					if `unconf4m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==0 {
					loc unconf2m`q' = 0
					loc unconf2_`q' = 0
					loc unconf3m`q' = 0
					loc unconf3_`q' = 0
					loc unconf4m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i'_2m diff`q'_`i'_2 diff`q'_`i'_3m diff`q'_`i'_3 diff`q'_`i'_4m
							tempname diff`q'_`i'_2m_var diff`q'_`i'_2_var diff`q'_`i'_3m_var diff`q'_`i'_3_var diff`q'_`i'_4m_var
							cap gen double `diff`q'_`i'_2m' = `v`i'_2m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_2m' if e(sample)
							sca `diff`q'_`i'_2m_var' = r(Var)
							cap gen double `diff`q'_`i'_2' = `v`i'_2`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_2' if e(sample)
							sca `diff`q'_`i'_2_var' = r(Var)
							cap gen double `diff`q'_`i'_3m' = `v`i'_3m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_3m' if e(sample)
							sca `diff`q'_`i'_3m_var' = r(Var)
							cap gen double `diff`q'_`i'_3' = `v`i'_3`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_3' if e(sample)
							sca `diff`q'_`i'_3_var' = r(Var)
							cap gen double `diff`q'_`i'_4m' = `v`i'_4m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_4m' if e(sample)
							sca `diff`q'_`i'_4m_var' = r(Var)
							if `diff`q'_`i'_2m_var'<10^-10 {
								loc unconf2m`q' = `unconf2m`q''+1
							}
							if `diff`q'_`i'_2_var'<10^-10 {
								loc unconf2_`q' = `unconf2_`q''+1
							}
							if `diff`q'_`i'_3m_var'<10^-10 {
								loc unconf3m`q' = `unconf3m`q''+1
							}
							if `diff`q'_`i'_3_var'<10^-10 {
								loc unconf3_`q' = `unconf3_`q''+1
							}
							if `diff`q'_`i'_4m_var'<10^-10 {
								loc unconf4m`q' = `unconf4m`q''+1
							}
						}
					}
					if `unconf2_`q''>0 & `unconf3_`q''>0 & `unconf4m`q''>0 {
						loc unconf2m`q' = `unconf2m`q''+1
					}
					if `unconf2_`q''>0 & `unconf3m`q''>0 {
						loc unconf2m`q' = `unconf2m`q''+1
					}
					if `unconf2m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==0 & `v`i'_5mvc'==1 {
					loc unconf2m`q' = 0
					loc unconf2_`q' = 0
					loc unconf3m`q' = 0
					loc unconf3_`q' = 0
					loc unconf5m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i'_2m diff`q'_`i'_2 diff`q'_`i'_3m diff`q'_`i'_3 diff`q'_`i'_5m
							tempname diff`q'_`i'_2m_var diff`q'_`i'_2_var diff`q'_`i'_3m_var diff`q'_`i'_3_var diff`q'_`i'_5m_var
							cap gen double `diff`q'_`i'_2m' = `v`i'_2m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_2m' if e(sample)
							sca `diff`q'_`i'_2m_var' = r(Var)
							cap gen double `diff`q'_`i'_2' = `v`i'_2`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_2' if e(sample)
							sca `diff`q'_`i'_2_var' = r(Var)
							cap gen double `diff`q'_`i'_3m' = `v`i'_3m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_3m' if e(sample)
							sca `diff`q'_`i'_3m_var' = r(Var)
							cap gen double `diff`q'_`i'_3' = `v`i'_3`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_3' if e(sample)
							sca `diff`q'_`i'_3_var' = r(Var)
							cap gen double `diff`q'_`i'_5m' = `v`i'_5m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_5m' if e(sample)
							sca `diff`q'_`i'_5m_var' = r(Var)
							if `diff`q'_`i'_2m_var'<10^-10 {
								loc unconf2m`q' = `unconf2m`q''+1
							}
							if `diff`q'_`i'_2_var'<10^-10 {
								loc unconf2_`q' = `unconf2_`q''+1
							}
							if `diff`q'_`i'_3m_var'<10^-10 {
								loc unconf3m`q' = `unconf3m`q''+1
							}
							if `diff`q'_`i'_3_var'<10^-10 {
								loc unconf3_`q' = `unconf3_`q''+1
							}
							if `diff`q'_`i'_5m_var'<10^-10 {
								loc unconf5m`q' = `unconf5m`q''+1
							}
						}
					}
					if `unconf2_`q''>0 & `unconf3_`q''>0 & `unconf5m`q''>0 {
						loc unconf2m`q' = `unconf2m`q''+1
					}
					if `unconf2_`q''>0 & `unconf3m`q''>0 {
						loc unconf2m`q' = `unconf2m`q''+1
					}
					if `unconf2m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==0 & `v`i'_4vc'==1 & `v`i'_5mvc'==1 {
					loc unconf2m`q' = 0
					loc unconf2_`q' = 0
					loc unconf4m`q' = 0
					loc unconf4_`q' = 0
					loc unconf5m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i'_2m diff`q'_`i'_2 diff`q'_`i'_4m diff`q'_`i'_4 diff`q'_`i'_5m
							tempname diff`q'_`i'_2m_var diff`q'_`i'_2_var diff`q'_`i'_4m_var diff`q'_`i'_4_var diff`q'_`i'_5m_var
							cap gen double `diff`q'_`i'_2m' = `v`i'_2m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_2m' if e(sample)
							sca `diff`q'_`i'_2m_var' = r(Var)
							cap gen double `diff`q'_`i'_2' = `v`i'_2`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_2' if e(sample)
							sca `diff`q'_`i'_2_var' = r(Var)
							cap gen double `diff`q'_`i'_4m' = `v`i'_4m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_4m' if e(sample)
							sca `diff`q'_`i'_4m_var' = r(Var)
							cap gen double `diff`q'_`i'_4' = `v`i'_4`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_4' if e(sample)
							sca `diff`q'_`i'_4_var' = r(Var)
							cap gen double `diff`q'_`i'_5m' = `v`i'_5m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_5m' if e(sample)
							sca `diff`q'_`i'_5m_var' = r(Var)
							if `diff`q'_`i'_2m_var'<10^-10 {
								loc unconf2m`q' = `unconf2m`q''+1
							}
							if `diff`q'_`i'_2_var'<10^-10 {
								loc unconf2_`q' = `unconf2_`q''+1
							}
							if `diff`q'_`i'_4m_var'<10^-10 {
								loc unconf4m`q' = `unconf4m`q''+1
							}
							if `diff`q'_`i'_4_var'<10^-10 {
								loc unconf4_`q' = `unconf4_`q''+1
							}
							if `diff`q'_`i'_5m_var'<10^-10 {
								loc unconf5m`q' = `unconf5m`q''+1
							}
						}
					}
					if `unconf2_`q''>0 & `unconf4_`q''>0 & `unconf5m`q''>0 {
						loc unconf2m`q' = `unconf2m`q''+1
					}
					if `unconf2_`q''>0 & `unconf4m`q''>0 {
						loc unconf2m`q' = `unconf2m`q''+1
					}
					if `unconf2m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				if (`v`i'_1vc'==1 & `v`i'_2vc'==0 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==1) | (`v`i'_1vc'==0 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==1) {
					loc unconf3m`q' = 0
					loc unconf3_`q' = 0
					loc unconf4m`q' = 0
					loc unconf4_`q' = 0
					loc unconf5m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i'_3m diff`q'_`i'_3 diff`q'_`i'_4m diff`q'_`i'_4 diff`q'_`i'_5m
							tempname diff`q'_`i'_3m_var diff`q'_`i'_3_var diff`q'_`i'_4m_var diff`q'_`i'_4_var diff`q'_`i'_5m_var
							cap gen double `diff`q'_`i'_3m' = `v`i'_3m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_3m' if e(sample)
							sca `diff`q'_`i'_3m_var' = r(Var)
							cap gen double `diff`q'_`i'_3' = `v`i'_3`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_3' if e(sample)
							sca `diff`q'_`i'_3_var' = r(Var)
							cap gen double `diff`q'_`i'_4m' = `v`i'_4m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_4m' if e(sample)
							sca `diff`q'_`i'_4m_var' = r(Var)
							cap gen double `diff`q'_`i'_4' = `v`i'_4`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_4' if e(sample)
							sca `diff`q'_`i'_4_var' = r(Var)
							cap gen double `diff`q'_`i'_5m' = `v`i'_5m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_5m' if e(sample)
							sca `diff`q'_`i'_5m_var' = r(Var)
							if `diff`q'_`i'_3m_var'<10^-10 {
								loc unconf3m`q' = `unconf3m`q''+1
							}
							if `diff`q'_`i'_3_var'<10^-10 {
								loc unconf3_`q' = `unconf3_`q''+1
							}
							if `diff`q'_`i'_4m_var'<10^-10 {
								loc unconf4m`q' = `unconf4m`q''+1
							}
							if `diff`q'_`i'_4_var'<10^-10 {
								loc unconf4_`q' = `unconf4_`q''+1
							}
							if `diff`q'_`i'_5m_var'<10^-10 {
								loc unconf5m`q' = `unconf5m`q''+1
							}
						}
					}
					if `unconf3_`q''>0 & `unconf4_`q''>0 & `unconf5m`q''>0 {
						loc unconf3m`q' = `unconf3m`q''+1
					}
					if `unconf3_`q''>0 & `unconf4m`q''>0 {
						loc unconf3m`q' = `unconf3m`q''+1
					}
					if `unconf3m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				if `v`i'_1vc'==1 & `v`i'_2vc'==1 & `v`i'_3vc'==1 & `v`i'_4vc'==1 & `v`i'_5mvc'==1 {
					loc unconf2m`q' = 0
					loc unconf2_`q' = 0
					loc unconf3m`q' = 0
					loc unconf3_`q' = 0
					loc unconf4m`q' = 0
					loc unconf4_`q' = 0
					loc unconf5m`q' = 0
					if wordcount("`rvlist`q''")>1 {
						loc vc`q' = word("`fvrvlist`q''",`i')
						loc complist`q' : list fvrvlist`q' - vc`q'
						foreach rv`q' of varlist `complist`q'' {
							tempvar diff`q'_`i'_2m diff`q'_`i'_2 diff`q'_`i'_3m diff`q'_`i'_3 diff`q'_`i'_4m diff`q'_`i'_4 diff`q'_`i'_5m
							tempname diff`q'_`i'_2m_var diff`q'_`i'_2_var diff`q'_`i'_3m_var diff`q'_`i'_3_var diff`q'_`i'_4m_var diff`q'_`i'_4_var diff`q'_`i'_5m_var
							cap gen double `diff`q'_`i'_2m' = `v`i'_2m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_2m' if e(sample)
							sca `diff`q'_`i'_2m_var' = r(Var)
							cap gen double `diff`q'_`i'_2' = `v`i'_2`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_2' if e(sample)
							sca `diff`q'_`i'_2_var' = r(Var)
							cap gen double `diff`q'_`i'_3m' = `v`i'_3m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_3m' if e(sample)
							sca `diff`q'_`i'_3m_var' = r(Var)
							cap gen double `diff`q'_`i'_3' = `v`i'_3`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_3' if e(sample)
							sca `diff`q'_`i'_3_var' = r(Var)
							cap gen double `diff`q'_`i'_4m' = `v`i'_4m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_4m' if e(sample)
							sca `diff`q'_`i'_4m_var' = r(Var)
							cap gen double `diff`q'_`i'_4' = `v`i'_4`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_4' if e(sample)
							sca `diff`q'_`i'_4_var' = r(Var)
							cap gen double `diff`q'_`i'_5m' = `v`i'_5m`q''-`rv`q'' if e(sample)
							qui su `diff`q'_`i'_5m' if e(sample)
							sca `diff`q'_`i'_5m_var' = r(Var)
							if `diff`q'_`i'_2m_var'<10^-10 {
								loc unconf2m`q' = `unconf2m`q''+1
							}
							if `diff`q'_`i'_2_var'<10^-10 {
								loc unconf2_`q' = `unconf2_`q''+1
							}
							if `diff`q'_`i'_3m_var'<10^-10 {
								loc unconf3m`q' = `unconf3m`q''+1
							}
							if `diff`q'_`i'_3_var'<10^-10 {
								loc unconf3_`q' = `unconf3_`q''+1
							}
							if `diff`q'_`i'_4m_var'<10^-10 {
								loc unconf4m`q' = `unconf4m`q''+1
							}
							if `diff`q'_`i'_4_var'<10^-10 {
								loc unconf4_`q' = `unconf4_`q''+1
							}
							if `diff`q'_`i'_5m_var'<10^-10 {
								loc unconf5m`q' = `unconf5m`q''+1
							}
						}
					}
					if `unconf2_`q''>0 & `unconf3_`q''>0 & `unconf4_`q''>0 & `unconf5m`q''>0 {
						loc unconf2m`q' = `unconf2m`q''+1
					}
					if `unconf2_`q''>0 & `unconf3_`q''>0 & `unconf4m`q''>0 {
						loc unconf2m`q' = `unconf2m`q''+1
					}
					if `unconf2_`q''>0 & `unconf3m`q''>0 {
						loc unconf2m`q' = `unconf2m`q''+1
					}
					if `unconf2m`q''==0 {
						loc conflist`q'_`i' = word("`rvlist`q''",`i')
						loc conflist`q' = strltrim(`"`conflist`q'' `conflist`q'_`i''"')
					}
				}
				loc i =`i'+1
			}
			if !mi("`conflist`q''") {
				di as err _newline"The following predictors may have conflated level-""`q'"" random effects because they"_continue
				di as err _newline"are not centered-within-clusters and their higher-level contextual level-""`q'"" random"_continue
				di as err _newline"effects have not been included in the model (see Rights & Sterba 2023a for more info):"_continue
				di as err _newline"  `conflist`q''"
			}
		}
	}
	ret clear
	mat `R2' = (`R2_f1_1',`R2_v12_1',`R2_v13_1',`R2_v14_1',`R2_v15_1',`Resid_1',`R2_f2_2',`R2_v22_2',`R2_v23_2',`R2_v24_2',`R2_v25_2',`R2_m2_2',`R2_f3_3',`R2_v32_3',`R2_v33_3',`R2_v34_3',`R2_v35_3',`R2_m3_3',`R2_f4_4',`R2_v42_4',`R2_v43_4',`R2_v44_4',`R2_v45_4',`R2_m4_4',`R2_f5_5',`R2_v52_5',`R2_v53_5',`R2_v54_5',`R2_v55_5',`R2_m5_5',`R2_f1_t',`R2_f2_t',`R2_f3_t',`R2_f4_t',`R2_f5_t',`R2_v12_t',`R2_v22_t',`R2_v32_t',`R2_v42_t',`R2_v52_t',`R2_v2_t',`R2_v13_t',`R2_v23_t',`R2_v33_t',`R2_v43_t',`R2_v53_t',`R2_v3_t',`R2_v14_t',`R2_v24_t',`R2_v34_t',`R2_v44_t',`R2_v54_t',`R2_v4_t',`R2_v15_t',`R2_v25_t',`R2_v35_t',`R2_v45_t',`R2_v55_t',`R2_v5_t',`R2_m2_t',`R2_m3_t',`R2_m4_t',`R2_m5_t',`R2_f_t',`R2_v_t',`R2_m_t',`R2_fv_t',`R2_fvm_t',`Resid_t')
	mat colnames `R2' = R2_f1_1 R2_v12_1 R2_v13_1 R2_v14_1 R2_v15_1 Resid_1 R2_f2_2 R2_v22_2 R2_v23_2 R2_v24_2 R2_v25_2 R2_m2_2 R2_f3_3 R2_v32_3 R2_v33_3 R2_v34_3 R2_v35_3 R2_m3_3 R2_f4_4 R2_v42_4 R2_v43_4 R2_v44_4 R2_v45_4 R2_m4_4 R2_f5_5 R2_v52_5 R2_v53_5 R2_v54_5 R2_v55_5 R2_m5_5 R2_f1_t R2_f2_t R2_f3_t R2_f4_t R2_f5_t R2_v12_t R2_v22_t R2_v32_t R2_v42_t R2_v52_t R2_v2_t R2_v13_t R2_v23_t R2_v33_t R2_v43_t R2_v53_t R2_v3_t R2_v14_t R2_v24_t R2_v34_t R2_v44_t R2_v54_t R2_v4_t R2_v15_t R2_v25_t R2_v35_t R2_v45_t R2_v55_t R2_v5_t R2_m2_t R2_m3_t R2_m4_t R2_m5_t R2_f_t R2_v_t R2_m_t R2_fv_t R2_fvm_t Resid_t
	mat rownames `R2' = "`dv'"
	ret mat R2 = `R2'
	qui _estimates unhold mixedest
	qui _estimates hold mixedest, copy restore
	ret sca R2_L5_Total = `R2_L5_t'
	ret sca R2_L4_Total = `R2_L4_t'
	ret sca R2_L3_Total = `R2_L3_t'
	ret sca R2_L2_Total = `R2_L2_t'
	ret sca R2_L1_Total = `R2_L1_t'
	ret sca Resid_Total = `Resid_t'
	ret sca R2_fvm_Total = `R2_fvm_t'
	ret sca R2_fv_Total = `R2_fv_t'
	ret sca R2_m_Total = `R2_m_t'
	ret sca R2_m5_Total = `R2_m5_t'
	ret sca R2_m4_Total = `R2_m4_t'
	ret sca R2_m3_Total = `R2_m3_t'
	ret sca R2_m2_Total = `R2_m2_t'
	ret sca R2_v_Total = `R2_v_t'
	ret sca R2_v5_Total = `R2_v5_t'
	ret sca R2_v55_Total = `R2_v55_t'
	ret sca R2_v45_Total = `R2_v45_t'
	ret sca R2_v35_Total = `R2_v35_t'
	ret sca R2_v25_Total = `R2_v25_t'
	ret sca R2_v15_Total = `R2_v15_t'
	ret sca R2_v4_Total = `R2_v4_t'
	ret sca R2_v54_Total = `R2_v54_t'
	ret sca R2_v44_Total = `R2_v44_t'
	ret sca R2_v34_Total = `R2_v34_t'
	ret sca R2_v24_Total = `R2_v24_t'
	ret sca R2_v14_Total = `R2_v14_t'
	ret sca R2_v3_Total = `R2_v3_t'
	ret sca R2_v53_Total = `R2_v53_t'
	ret sca R2_v43_Total = `R2_v43_t'
	ret sca R2_v33_Total = `R2_v33_t'
	ret sca R2_v23_Total = `R2_v23_t'
	ret sca R2_v13_Total = `R2_v13_t'
	ret sca R2_v2_Total = `R2_v2_t'
	ret sca R2_v52_Total = `R2_v52_t'
	ret sca R2_v42_Total = `R2_v42_t'
	ret sca R2_v32_Total = `R2_v32_t'
	ret sca R2_v22_Total = `R2_v22_t'
	ret sca R2_v12_Total = `R2_v12_t'
	ret sca R2_f_Total = `R2_f_t'
	ret sca R2_f5_Total = `R2_f5_t'
	ret sca R2_f4_Total = `R2_f4_t'
	ret sca R2_f3_Total = `R2_f3_t'
	ret sca R2_f2_Total = `R2_f2_t'
	ret sca R2_f1_Total = `R2_f1_t'
	ret sca R2_m5_L5 = `R2_m5_5'
	ret sca R2_v55_L5 = `R2_v55_5'
	ret sca R2_v54_L5 = `R2_v54_5'
	ret sca R2_v53_L5 = `R2_v53_5'
	ret sca R2_v52_L5 = `R2_v52_5'		
	ret sca R2_f5_L5 = `R2_f5_5'	
	ret sca R2_m4_L4 = `R2_m4_4'
	ret sca R2_v45_L4 = `R2_v45_4'
	ret sca R2_v44_L4 = `R2_v44_4'
	ret sca R2_v43_L4 = `R2_v43_4'
	ret sca R2_v42_L4 = `R2_v42_4'
	ret sca R2_f4_L4 = `R2_f4_4'
	ret sca R2_m3_L3 = `R2_m3_3'
	ret sca R2_v35_L3 = `R2_v35_3'
	ret sca R2_v34_L3 = `R2_v34_3'
	ret sca R2_v33_L3 = `R2_v33_3'
	ret sca R2_v32_L3 = `R2_v32_3'
	ret sca R2_f3_L3 = `R2_f3_3'
	ret sca R2_m2_L2 = `R2_m2_2'
	ret sca R2_v25_L2 = `R2_v25_2'
	ret sca R2_v24_L2 = `R2_v24_2'
	ret sca R2_v23_L2 = `R2_v23_2'
	ret sca R2_v22_L2 = `R2_v22_2'
	ret sca R2_f2_L2 = `R2_f2_2'
	ret sca Resid_L1 = `Resid_1'
	ret sca R2_v15_L1 = `R2_v15_1'
	ret sca R2_v14_L1 = `R2_v14_1'
	ret sca R2_v13_L1 = `R2_v13_1'
	ret sca R2_v12_L1 = `R2_v12_1'
	ret sca R2_f1_L1 = `R2_f1_1'
	ret sca Total_MI_Var = `tvar'
	ret sca L5_MI_Var = `var5'
	ret sca L4_MI_Var = `var4'
	ret sca L3_MI_Var = `var3'
	ret sca L2_MI_Var = `var2'
	ret sca L1_MI_Var = `var1'
	ret sca s2 = `s2'
	ret sca m5 = `m5'[1,1]
	ret sca m4 = `m4'[1,1]
	ret sca m3 = `m3'[1,1]
	ret sca m2 = `m2'[1,1]
	ret sca v5 = `v5'[1,1]
	ret sca v55 = `v55'[1,1]
	ret sca v45 = `v45'[1,1]
	ret sca v35 = `v35'[1,1]
	ret sca v25 = `v25'[1,1]
	ret sca v15 = `v15'[1,1]
	ret sca v4 = `v4'[1,1]
	ret sca v54 = `v54'[1,1]
	ret sca v44 = `v44'[1,1]
	ret sca v34 = `v34'[1,1]
	ret sca v24 = `v24'[1,1]
	ret sca v14 = `v14'[1,1]
	ret sca v3 = `v3'[1,1]
	ret sca v53 = `v53'[1,1]
	ret sca v43 = `v43'[1,1]
	ret sca v33 = `v33'[1,1]
	ret sca v23 = `v23'[1,1]
	ret sca v13 = `v13'[1,1]
	ret sca v2 = `v2'[1,1]
	ret sca v52 = `v52'[1,1]
	ret sca v42 = `v42'[1,1]
	ret sca v32 = `v32'[1,1]
	ret sca v22 = `v22'[1,1]
	ret sca v12 = `v12'[1,1]
	ret sca f = `f'[1,1]
	ret sca f5 = `f5'[1,1]
	ret sca f4 = `f4'[1,1]
	ret sca f3 = `f3'[1,1]
	ret sca f2 = `f2'[1,1]
	ret sca f1 = `f1'[1,1]
end