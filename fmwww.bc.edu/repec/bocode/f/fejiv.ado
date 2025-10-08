*! version 1.0.0  26sep2025  Qihui Lei and Tymon Sloczynski

capture program drop fejiv
program define fejiv, eclass
	version 12
	syntax anything [if] [in] [, absorb(varname)]
	
	// parse
	_iv_parse `0'
	local cmd `cmd'
	local yvar `s(lhs)'
	local tvar `s(endog)'
	local zvars `s(inst)'
	local xvars `s(exog)'
	local zero `s(zero)'
	
	ereturn clear
	sreturn clear
	
	// mark sample
	marksample touse
	markout `touse' `yvar' `tvar' `zvars' `xvars' `absorb', strok
	
	preserve
	quietly keep if `touse'
	
	// constant term
	tempvar cons
	gen `cons' = 1
	
	if "`xvars'"=="" local xvars `cons'
	
	// manage the "clusters" if requested
	if "`absorb'"=="" {
		local cvars `cons'
	}
	else {
		local cvars ""
		
		quietly levelsof `absorb', local(cvals)
		local k = 1
		local K = r(r)
		
		foreach cval of local cvals {
			tempvar X`k'
			gen `X`k'' = (`absorb'==`cval')
			local cvars `cvars' `X`k''
			
			local k = `k'+1
		}
	}
	
	// code in Mata
	mata y = st_data(.,("`yvar'"))
	mata x = st_data(.,("`tvar'"))
	mata Z = st_data(.,("`zvars'"))
	mata W = st_data(.,("`xvars'"))
	mata Q = st_data(.,("`cvars'"))
	mata m = length(y)
	
	mata MQ = I(m)-(Q*invsym(Q'*Q)*Q')
	mata Zbar = (Z, W)
	mata Wbar = (W, Q)
	mata MWQ = MQ-((MQ*W)*(invsym((W')*MQ*W))*(W')*MQ)
	mata Portho = (MWQ*Z)*(invsym((Z')*MWQ*Z))*(Z')*MWQ
	mata dgP = diagonal(Portho)
	mata MXV = MQ-((MQ*Zbar)*(invsym((Zbar')*MQ*Zbar))*(Zbar')*MQ)
	
	mata HPMXV = (MXV:*MXV)
	mata vtheta = invsym(HPMXV)*dgP
	mata Dtheta = diag(vtheta)
	mata R = Portho-(MXV*Dtheta*MXV)
	mata Denomb = (x')*R*x
	mata Numb = (x')*R*y
	mata b = Numb/Denomb
	
	mata ehat = MXV*(y-(b*x))
	mata vsig = invsym(MQ:*MQ)*(ehat:*ehat)
	mata Dvsig = diag(vsig)
	mata MZWQx = MXV*x
	mata ue = invsym(MQ:*MQ)*(ehat:*MZWQx)
	mata Sig1 = ((x')*R*Dvsig*R*x)
	mata Sig2 = ((ue')*(R:*R)*(ue))
	mata Sig = Sig1+Sig2
	mata V = Sig/(Denomb^2)
	
	mata st_matrix("b", (b))
	mata st_matrix("V", (V))
	
	matrix rownames b = "`tvar'"
	matrix colnames b = "`tvar'"
	matrix rownames V = "`tvar'"
	matrix colnames V = "`tvar'"
	
	restore
	
	// post estimates
	quietly count if `touse'
	ereturn post b V, esample(`touse')
	ereturn scalar N = r(N)
	
	ereturn local title "FEJIV estimation"
	ereturn local clust `absorb'
	ereturn local covar `xvars'
	ereturn local instr `zvars'
	ereturn local treat `tvar'
	ereturn local depvar `yvar'
	ereturn local cmd "fejiv"
	ereturn local cmdline `"fejiv `0'"'
	
	// display estimates
	_coef_table_header
	_coef_table
end
