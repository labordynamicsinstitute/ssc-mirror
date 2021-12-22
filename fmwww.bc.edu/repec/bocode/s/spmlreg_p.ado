*! Postestimation command for spmlreg
*! Author: P. Wilner Jeanty
*! Born: November 8, 2012

prog define spmlreg_p, sortpreserve
	version 11
	syntax anything [if] [in] [, xb(str) RESiduals  SCore wmat(str) wfrom(str) replace] // default=xb(naive)
	
	        // check syntax
    if `"`anything'"' == "" {
		local 0
        syntax newvarlist
        exit 100        
    }
	foreach var of local anything {
		Confnewvar `var' `replace' 
	}
	marksample touse
	if "`xb'"!="" & !inlist("`xb'", "redform", "naive") {
		di "{error}Option xb() takes either redform or naive"
		exit 198
	}	
	local nbopt = "`xb' `residuals' `score'"
    local cntopt : word count `nbopt'
	if `cntopt' > 1 {
		di "{err}Only one of xb(), residuals, and score can be specified"
		exit 198
	}
	if strpos("`anything'", "*") & "`score'"=="" {
		di as err "stub* can only be combined with {bf:score} option"
		exit
	}
	if !inlist("`e(model)'", "lag", "durbin") & "`score'"!="" {
		di as err "{bf:Scores} are calculated only for the spatial lag and spatial durbin models."
		exit // will calculate scores for other models depending on the number of users who need them.
	}
	
	capture _score_spec `anything'
	
	if c(rc)!=0 {
		local varn `s(varlist)'
		if c(rc)==110 {
			foreach var of local varn {
				Confnewvar `var' `replace' 
			}
		}
		else _score_spec `anything'
	}
	
	local varn `s(varlist)'
	local vtyp `s(typlist)'
	local nvs : word count `varn'
	forv i=1/`nvs' {
		local vv`i' : word `i' of `varn'
		local vtyp`i' : word `i' of `vtyp'
	}	

	tempvar predy yhat	
	if inlist("`e(model)'", "lag", "durbin", "sac") {
		if "`nbopt'" == "" {
			di as text "(option xb(naive) assumed; fitted values)"
            local xb naive
        }
		
		local depv "`e(depvar)'"
		if "`wmat'"=="" local wmat `e(wname)'
		if "`wfrom'"=="" local wfrom `e(wfrom)'
		local eigv `e(eignvar)'
		local cons =_b[_cons]
		if "`cons'"=="" local noconst noconst
		tempname bmat rho tmat	
		tempname bet r2b brho
		matrix `bmat'=e(b)
		matrix `bmat'=`bmat'[1, "`depv':"]
		scalar `rho'=[rho]_cons
		matrix `tmat'=`bmat'[1, 1.. colsof(`bmat')-1]
		local varlist : colnames `tmat' // to ascertain that those are the variables used in the regression
		if "`e(model)'"=="durbin" {
			local x2lag `e(indvar)'
			qui splagvar if `touse', wn(`wmat') wfrom(`wfrom') ind(`x2lag') 
		}		
		capture drop spmlreg_Py
		qui gen spmlreg_Py=`depv' 
		qui splagvar spmlreg_Py if `touse', wname(`wmat') wfrom(`wfrom') replace
		qui _predict double `yhat' if `touse'
		qui replace `yhat'=`yhat' + `rho'*wy_spmlreg_Py if `touse' 
		
		local sigma= `e(sigma)'
		if "`xb'"!="" & "`xb'"=="redform" {
			mata: CalcSR2("`rho'", "`bmat'", "`varlist'", "`touse'")
			gen `vtyp1' `vv1' =`predy' if `touse'
			label var `vv1' "Linear prediction - reduced form"
		}
		if "'xb'"!="" & "`xb'"=="naive" {
			gen `vtype1' `vv1'=`yhat' if `touse' // naive
			label var `vv1' "Linear prediction - naive"
		}	
		if "`residuals'"!="" {
			gen `vtype1' `vv1'=`depv'-`yhat' if `touse' // usually calculated based on naive predictor
			label var `vv1' "Regression residuals"
		}
		if "`score'"!="" {
			if inlist("`e(model)'", "lag", "durbin") {
				if !inlist(`nvs', 1, 3) {
					di as err "Incorrect number of variable names"
					exit
				}
				if inlist(`nvs', 1, 3) {					
					qui gen `vtyp1' `vv1'=(`depv'-`yhat')/`sigma'^2  // usually calculated based on naive predictor
					label var `vv1' "Equation-level score"
					if `nvs'==3 {
						qui gen `vtyp2' `vv2' = -(1/`eigv' - `rho')^-1 + wy_spmlreg_Py*`vv1'
						label var `vv2' "Equation-level score for Rho"
						qui gen `vtyp3' `vv3' = -0.5/`sigma'^2 + (`sigma'*`vv1')^2
						label var `vv3' "Equation-level score for sigma"
					}	
				}	
			} 
		}	
		drop wy_spmlreg_Py spmlreg_Py		
	}
	else if "`e(model)'"=="error" {
		if "`nbopt'" == "" {
			di as text "(option xb(naive) assumed; fitted values XB)"
			local xb xb
        }
		if "'xb'"!="" _predict `vtyp1' `vv1' if `touse'         
        else {  
              qui _predict double `yhat' if `touse'
              gen `vtyp1' `vv1' = `depv' - `yhat' if `touse'
              label var `vv1' "Residuals"
        }
	}
	capture drop wx_*
end
prog define Confnewvar
        version 11.0
        args varname replace
        loc confv confirm new var 
        cap `confv' `varname' 
        if _rc==110 {
			if "`replace'"!=""  drop `varname'
			else {
				di              
				`confv' `varname'
            }
        } 
end
version 11
mata:
mata set matastrict on
void CalcSR2(string scalar brho, string scalar bvec, string scalar xvars, string scalar tousev) 
{
        rho=st_numscalar(brho) 
        real matrix B, Cons, xxs, invIRW
        xxs=st_data(., tokens(xvars), tousev)
		if (st_local("noconst")=="") {
			Cons=J(rows(xxs),1,1)
			xxs=xxs, Cons
		}
		if (st_local("wfrom")=="Mata") {
			fh = fopen(st_local("wmat"), "r") // Assuming weights matrix is from a Mata file
			w=fgetmatrix(fh)
			fclose(fh)
		}	
		else w=st_matrix(st_local("wmat"))
		nw=rows(w)			
		invIRW=luinv(I(nw)-rho*w)
        B=st_matrix(bvec)
        XB=xxs*B'
        ypred=invIRW*XB
		st_store(., st_addvar(st_local("vtyp1"), st_local("predy")), tousev, ypred)
}
end
