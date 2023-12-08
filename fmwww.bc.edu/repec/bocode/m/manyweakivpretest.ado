*! version 0.1  23aug2023  Liyang Sun, lsun20@cemfi.es
*! version 0.0  25apr2021  Liyang Sun, lsun20@mit.edu


capture program drop manyweakivpretest
program define manyweakivpretest, eclass sortpreserve
	version 13 
	set more off
	
	_iv_parse `0'
        
	local lhs `s(lhs)'
	local endog `s(endog)'
	local covariates `s(exog)'
	local instr `s(inst)'
	local 0 `s(zero)'
	
	syntax [if] [in] [aweight fweight], ///
	[NOConstant]

// 	* Mark sample (reflects the if/in conditions, and includes only nonmissing observations)
// 	marksample touse
// 	markout `touse' `by' `xq' `covariates', strok
	tempname x h xtilde

	qui regress `endog' `covariates', `noconstant' // partial out controls from X (if empty, then partial out the constant term)
	qui predict double `x', residual
	
// 	dis "`instr'"
// 		dis "`covariates'"
// 		dis "`noconstant'"
	if "`covariates'" == "" & "`noconstant'" != "" {
		local instr_partialed "`instr'" // nothing to partial out
	} 
	else if "`covariates'" == "" & "`noconstant'" == "" {
		local instr_partialed ""
		local k = 1
		foreach z of varlist `instr' {
			tempvar z`k'
	// 			dis "`z'"
			qui regress `z', `noconstant'
			qui predict double `z`k'', residual // partial out the constant
			local instr_partialed "`instr_partialed' `z`k''"
		local k = `k' + 1

		}
	}
	else {
		qui mvreg `instr' = `covariates', `noconstant' // partial out controls from Z
		local instr_partialed ""
		local k = 1
		foreach z of varlist `instr' {
			tempvar z`k'
	// 			dis "`z'"
			qui predict double `z`k'', residual equation(#`k') // partial out controls from Z
			local instr_partialed "`instr_partialed' `z`k''"
		local k = `k' + 1

		}
	}
	
	
	
	** now the endogenous varibale and instruments have controls partialled out

	** first-stage regression
	qui regress `x' `instr_partialed', nocons // the constant term is already partialled out 
	qui predict double `h', hat // leverage Z_i'(Z'Z)^-1 Z_i
	qui predict double `xtilde', // predicted value Z\hat{pi}
	** move to mata for matrix calculation
	mata: Fhat_fun("`instr_partialed'","`xtilde'","`x'","`h'")
	di
	di in smcl "{help manyweakiv##manyweakiv:Many weak identification test}"

	if `r(F)' == . {
	// if Sigma1_hh is negative, it is also a situation that the asymptotic approximation underlying the test fails and hints strong identification
		dis in gr "Unfortunately the asymptotic approximation underlying this test fails, which might be due to strong identification. Please consult alternative solutions."
	} 
	else {
			di in ye "The many-instruments F test statistic" _col(65) %8.2f `r(F)'
	di

	di in gr "Critical values for:"
	di in gr "Ho:   weakly identified so that a nominal 5% JIVE t-test has "
	di in gr _col(30) "maximal actual size larger than 10%" in ye _col(60) %6.2f 4.14
	di in gr "Ho:   weakly identified so that a nominal 2% JIVE t-test has "
	di in gr _col(30) "maximal actual size larger than 5%" in ye _col(60) %6.2f 9.98
    di in gr "Source: Mikusheva and Sun (2022). "
	di in gr "NB: Critical values are for heteroskedatic errors."
	di
	}
	ereturn clear
	ereturn scalar Fhat = `r(F)'
	ereturn scalar Sigma_hh = `r(Sigma1_hh)'
	




end


mata:
void Fhat_fun(
        string scalar Z_name,			///
		string scalar Zhat_name,		///
		string scalar X_name,			///
		string scalar H_name			///
)
{
			Z = st_data(.,Z_name)
			Zhat = st_data(.,Zhat_name)
			X = st_data(.,X_name)
			H = st_data(.,H_name)
			N = rows(Z)
			K = cols(Z)
			M_diag = J(N,1,1)-H
			ZZ_inv = qrinv(Z'*Z)
			ZZZ_inv = Z*ZZ_inv

			XMX = X:*X - X:*Zhat

			Sigma1_hh = 0
			for (i=1; i<=N; i++) {
				if (mod(i,10000) == 0) {
					printf("Finished %g observations\n",i)
					printf("Sigma1_hh=%g\n",Sigma1_hh)

				}
				Zi = Z[i,]
				Pi = ZZZ_inv * Zi'
				PP = Pi:^2
				PP_off = (PP):/((1-H[i])*M_diag + PP)
				PP_off[i]=0
				Sigma1_hh = Sigma1_hh + XMX[i]*PP_off'*XMX
			}
// 			Sigma1_hh
			Fhat = (X'*Zhat - sum(X:*X:*H))/sqrt(K)/sqrt(2*Sigma1_hh/K)
// 			Fhat
			st_numscalar("r(F)", Fhat)
			st_numscalar("r(Sigma1_hh)", Sigma1_hh)
}
end


