*! koenker 1.0.0 cfb 10may2025
*! cloned from ivhettest 1.2.1 4may2025

program define koenker, rclass
	version 12.0
	local version 1.0.0

	syntax

	if  "`e(cmd)'" != "regress" {
		error 301
	}
	
	tempname res b
	mat `b' = e(b)

	local cn : colnames `b'
// require varlist with no FVs or interactions
	loc dot = strpos("`cn'",".")
	if `dot' {
		di as err  "koenker: only individual variables allowed."
		error 198
	}
	local cn_ct = colsof(`b')
	tokenize `cn'
* `hc' is hascons flag, =1 if regressors include constant
	local hc = ("``cn_ct''"=="_cons")
	if `hc' {
		local xvars_ct = `cn_ct'-1
		forvalues i=1/`xvars_ct' {
			local xvars "`xvars' ``i''"
		}
	}
	else {
		local xvars_ct = `cn_ct'
		local xvars "`cn'"
	}
//	di "`xvars'"
	
qui {
	loc nr = `xvars_ct' + 1
	mat `res' = J(`nr',3,1)
	loc i 0
	loc rn 
	foreach v of varlist `xvars' {
		loc i=`i'+1
		ivhettest `v', nr2
		mat `res'[`i',1] = r(nr2)
		mat `res'[`i',3] = r(nr2p)
		loc rn "`rn' `v'"
	}
	ivhettest, nr2
	loc i=`i'+1
	mat `res'[`i',1] = r(nr2)
	mat `res'[`i',2] = `xvars_ct'
	mat `res'[`i',3] = r(nr2p)
	loc rn "`rn' `Simuultaneous'"
	mat rownames `res' = `rn'
	mat colnames `res' = nr2 df nr2p
	matlist `res'
}	
	di _n as txt "Koenker/White test for heteroskedasticity" 
	di as txt "H0: Errors are i.i.d." _n
	di as txt "{hline 13}{c TT}{hline 24}"
    di as txt "    Variable {c |}      chi2   df        p"
    di as txt "{hline 13}{c +}{hline 24}"

    local i 0
    foreach v of local xvars {
                        local ++i
						loc vn: word `i' of `rn'
                        di as txt "`vn'" as res             ///
						  _col(14) "{c |} " as res          ///
                          _col(16)  %9.2f  el(`res',`i',1)  ///
                          _col(24)  %5.0f  el(`res',`i',2)  ///
                          _col(33)  %6.4f  el(`res',`i',3) 
                }
	            loc i=`i'+1
                di as txt  "{hline 13}{c +}{hline 24}"
                di as txt "Simultaneous"         ///
                   _col(14) "{c |} " as res      ///
                   _col(16) %9.2f  el(`res',`i',1)   ///
                   _col(24) %5.0f  el(`res',`i',2)    ///
                   _col(33) %6.4f  el(`res',`i',3)  
                di as txt  "{hline 13}{c BT}{hline 24}"

				return scalar nr2 = el(`res',`nr',1)
				return scalar df = el(`res',`nr',2) 
				return scalar nr2p =  el(`res',`nr',3) 
				return matrix tests = `res'
				
	end
	