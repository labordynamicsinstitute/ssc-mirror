capture program drop mi_impute_cmd_from_return
program mi_impute_cmd_from_return, rclass
version 18
syntax [, * ]
		qui count if  $MI_IMPUTE_user_touse==1
		local N = r(N)
		qui count if  $MI_IMPUTE_user_miss==1 & $MI_IMPUTE_user_touse==1 
		local I = r(N)
		return scalar N  = `N'
		return scalar N_incomplete = `I'	
		capture drop _MI_IMPUTE_from_imp
end
