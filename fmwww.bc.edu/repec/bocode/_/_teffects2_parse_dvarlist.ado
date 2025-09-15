*! version 1.0.0  12sep2025  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2025 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop _teffects2_parse_dvarlist
program define _teffects2_parse_dvarlist, sclass
	version 17
	
	cap noi syntax varlist(numeric fv), touse(varname) [ wtype(string) ///
		wvar(string) linear ///
		rmcoll noMARKout ]
	local rc = c(rc)
	
	if `rc' {
		di as txt "{phang}The outcome model is misspecified.{p_end}"
		exit `rc'
	}
	
	if "`wtype'"!="" {
		local wts [`wtype'=`wvar']
	}
	
	if "`markout'"=="" {
		markout `touse' `varlist'
		_teffects2_count_obs `touse', freq(`freq') ///
			why(observations with missing values)
	}
	
	gettoken depvar varlist : varlist, bind
	_fv_check_depvar `depvar'
	
	if "`varlist'"=="" & "`constant'"!="" {
		di as err "{p}The outcome model is misspecified; there " ///
			"must be at least a constant term in the model{p_end}"
		exit 100
	}
	
	if "`rmcoll'"=="" local rmcoll _rmdcoll `depvar'
	else local rmcoll _rmcoll
	
	`rmcoll' `varlist' if `touse' `wts', `constant'
	
	local k_omitted = r(k_omitted)
	if `k_omitted'!=0 local varlist `r(varlist)'
	
	fvrevar `varlist', list
	local dvarlist `r(varlist)'
	local dvarlist : list uniq dvarlist
	
	fvexpand `varlist' if `touse'
	if c(rc) {
		di as err "{p}Unable to expand factor variables in " ///
			"outcome-model varlist{p_end}"
		exit c(rc)
	}
	
	local fvops `r(fvops)'
	local fvdvarlist `r(varlist)'
	if "`fvops'"=="" local fvops false
	
	ParseDModel2, `linear'
	local omodel `s(omodel)'
	
	sreturn local omodel `omodel'
	sreturn local k_omitted = `k_omitted'
	sreturn local fvdvarlist `fvdvarlist'
	sreturn local kfv : word count `fvdvarlist'
	sreturn local dvarlist `dvarlist'
	sreturn local k : word count `dvarlist'
	sreturn local depvar `depvar'
	sreturn local fvops `fvops'
	sreturn local constant `constant'
end

capture program drop ParseDModel2
program define ParseDModel2, sclass
	version 17
	
	cap noi syntax, [ linear ]
	local rc = c(rc)
	
	if `rc' {
		di as txt "{phang}The outcome model is misspecified.{p_end}"
		exit `rc'
	}
	
	local k : word count `linear'
	if `k'>1 {
		di as err "{p}The outcome model is misspecified{p_end}"
		di as txt "{p}You can only specify " ///
			"{bf:linear}.{p_end}"
		exit 184
	}
	
	sreturn local omodel `omodel'
end

exit
