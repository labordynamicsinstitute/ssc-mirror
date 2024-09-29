version 18 

	mata:
	real colvector mi_impute_cmd_from_xb_qreg(real matrix X, real rowvector b)
	{
				p = cols(X)
				u = runiform(rows(X),1, 0.01, .99)*100
				pvec = J(1, 99, NULL)
				for (i=1; i<=99; i++) pvec[i] = &(b[1, (i*p)-(p-1)::(i*p)])
				yi = J(rows(X), 1, .)
				for (i=1; i<=rows(X); i++) {				
					f = floor(u[i])
					mod = mod(u[i],1)
					yi[i] = (1-mod)*(X[i,]* *pvec[f]')+mod*(X[i,]* *pvec[f+1]')
				}
	return(yi)
	}


real colvector mi_impute_cmd_from_xb_logit(real matrix X, real rowvector b)
{
			p = cols(X)
			u = runiform(rows(X),1, 0, 1)
			yi = J(rows(X), 1, .)
			
			for (i=1; i<=rows(X); i++) {
				fit_p = invlogit(X[i,]*b')
				yi[i] = (u[i]<=fit_p)*1 + (u[i]>fit_p)*0
			}
return(yi)
}

real colvector mi_impute_cmd_from_xb_mlogit(real matrix X, pointer rowvector cdf, pointer rowvector v)
{
			p = cols(X)
			u = runiform(rows(X),1, 0, 1)
			levels = cols(v)
			yi = J(rows(X), 1, *v[levels])
			for (i=1; i<=rows(X); i++) {
				j = levels-1
				while (j>0) {
						get_cdf = *cdf[j]
						if (u[i] <= get_cdf[i]) yi[i] = *v[j]
						j--
				}			
			}
return(yi)
}

end

capture program drop mi_impute_cmd_from
program define mi_impute_cmd_from 
    version 18.0
	tempvar first_ivar idn unique_values
	qui gen `idn' = _n 
	qui capture drop `first_ivar' `unique_values' 
	qui gen `first_ivar' = $MI_IMPUTE_user_ivar
	sort `idn'
	quietly count if $MI_IMPUTE_user_touse==1 & $MI_IMPUTE_user_miss==1 
		local tot_iv = r(N)
		if `tot_iv' != 0 {
			quietly capture drop yi 
			tempname betai Vi beta bstar V R sub suV bstar_eq var			
			mat `beta' = $MI_IMPUTE_user_ib
			mat `bstar' = $MI_IMPUTE_user_ib
			mat `V' =  $MI_IMPUTE_user_iV
			mat `var' = vecdiag(`V')
			local ncols = colsof(`beta')
			local names $MI_IMPUTE_user_ipred
			local n_params_eq : word count `names'
			tempname np
			scalar `np' = $MI_IMPUTE_user_np
			local imodel $MI_IMPUTE_user_imodel
			if "`imodel'" == "qreg" {
				forv t = 1/`ncols' {
						mat `bstar'[1, `t'] = rnormal(`beta'[1, `t'], sqrt(`var'[1, `t'])) 
				}
				qui putmata `idn' X=($MI_IMPUTE_user_indepv 1) if  $MI_IMPUTE_user_miss==1  , replace 
				mata: bi = st_matrix("`bstar'")
				mata: np = st_numscalar("`np'")
				noi mata: yi = mi_impute_cmd_from_xb_qreg(X, bi)
				qui getmata yi, id(`idn') update force
				qui replace `first_ivar'  = yi if $MI_IMPUTE_user_touse==1
			}
			
			if "`imodel'" == "logit" {
				forv t = 1/`ncols' {
						mat `bstar'[1, `t'] = rnormal(`beta'[1, `t'], sqrt(`var'[1, `t'])) 
				}
				qui putmata `idn' X=($MI_IMPUTE_user_indepv 1) if  $MI_IMPUTE_user_miss==1  , replace 
				mata: bi = st_matrix("`bstar'")
				mata: np = st_numscalar("`np'")
				noi mata: yi = mi_impute_cmd_from_xb_logit(X, bi)
				qui getmata yi, id(`idn') update force
				qui replace `first_ivar'  = yi if $MI_IMPUTE_user_touse==1	
			}
	
			if "`imodel'" == "mlogit" {
				
				tempname sub 
				mat `sub' = $MI_IMPUTE_user_ib
				local names: colnames `sub'
				local eqnames: coleq `sub'
				local k : colnlfs `sub'
				local k_1 = `k'-1
				local nrw: word count `names'
				local stop = 0
				local i = 1
				while `stop' != 1 {
					local pick: word `i' of `names'
					if `sub'[1, `i']==0 {
								local baseout: word `i' of `eqnames'
								local stop = 1 
					}
					local i = `i' + 1
				}
				local list_v_m ""
				forv s = 1/`nrw' {
					local pick: word `s' of `eqnames'
					if regexm("`list_v_m'", "`pick'") != 1 local list_v_m "`list_v_m' `pick'"
				}


				local no_base_list_v : subinstr local list_v_m "`baseout'" ""
				local no_base_list_v = stritrim("`no_base_list_v'")
 
				qui putmata `idn' X=($MI_IMPUTE_user_indepv 1) if  $MI_IMPUTE_user_miss==1  , replace 

				forv t = 1/`ncols' {
						mat `bstar'[1, `t'] = rnormal(`beta'[1, `t'], sqrt(`var'[1, `t'])) 
				}
				
				forv s = 1/`k_1' {
					local pick: word `s' of `no_base_list_v'
					tempname b`pick'
					mat `b`pick'' = `bstar'[1, "`pick':"]
					noi mata: ib`pick' = st_matrix("`b`pick''")
					noi mata: odds`pick' = exp(X*ib`pick'')
					if `s' == 1 noi mata: sumodds = odds`pick'
					else noi mata: sumodds = sumodds + odds`pick'
				}

				forv s = 1/`k' {
					local pick: word `s' of `list_v_m'
					if `pick' == $MI_IMPUTE_mogit_ref mata: pred`pick' = 1:/(1:+sumodds)
					else  mata: pred`pick' = odds`pick':/(1:+sumodds)
				}
	
				mata: pvec = J(1, `k', NULL)
				mata: evec = J(1, `k', NULL)

				forv s = 1/`k' {
					local pick: word `s' of `list_v_m'
					if `s' == 1 {
								mata: sumpred`pick' = pred`pick'
					}
					if `s' > 1 {
							local j = `s' -1
							local previous : word `j' of `list_v_m'
							mata: sumpred`pick' = sumpred`previous' + pred`pick'
					}

					 mata: pvec[`s'] = &(sumpred`pick')
					 mata: evec[`s'] = &(`pick')

				}
		
				noi mata: yi = mi_impute_cmd_from_xb_mlogit(X, pvec, evec)
				qui getmata yi, id(`idn') update force
				qui replace `first_ivar'  = yi if $MI_IMPUTE_user_touse==1	
			}
			
		}
			
		qui capture drop yi 
		quietly replace $MI_IMPUTE_user_ivar  = `first_ivar' if $MI_IMPUTE_user_miss==1 & $MI_IMPUTE_user_touse==1

		capture confirm numeric variable _MI_IMPUTE_from_imp
		if _rc != 0 quietly gen _MI_IMPUTE_from_imp = `first_ivar' if $MI_IMPUTE_user_miss==1 & $MI_IMPUTE_user_touse==1
		else quietly replace _MI_IMPUTE_from_imp = `first_ivar' if $MI_IMPUTE_user_miss==1 & $MI_IMPUTE_user_touse==1
		global MI_IMPUTE_from_imp = _MI_IMPUTE_from_imp
end
