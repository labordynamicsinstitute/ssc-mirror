*! version 1.0.0  12sep2025  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2025 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop _teffects2_parse_tvarlist
program define _teffects2_parse_tvarlist, sclass
	version 17
	
	cap noi syntax varlist(numeric fv), touse(varname) stat(passthru) ///
	[ freq(passthru) logit cbps ipt ///
	CONtrol(passthru) TLEVel(passthru) ///
	BASEoutcome(passthru) noMARKout cmd(string) binary ]
	
	local rc = c(rc)
	if `rc' {
		di as txt "{phang}The treatment model is misspecified.{p_end}"
		exit `rc'
	}
	
	ParsePSmodel2 `binary' : `"`logit' `cbps' `ipt'"'
	local tmodel `s(tmodel)'
	local markvlist `varlist'
	
	if "`markout'"=="" {
		cap noi markout `touse' `markvlist'
		
		local rc = c(rc)
		if `rc' {
			di as txt "{phang}There is a conflict in the " ///
			"treatment model specification.{p_end}"
			exit `rc'
		}
		
		_teffects2_count_obs `touse', `freq' ///
		why(observations with missing values)
	}
	
	gettoken tvar tvarlist : varlist, bind
	
	if "`tvarlist'"=="" & "`constant'"!="" {
		di as err "{p}treatment model is misspecified; there " ///
		"must be at least a constant term in the model{p_end}"
		exit 100
	}
	
	_teffects2_parse_tvar `tvar', touse(`touse') `freq' `control' ///
	`tlevel' `baseoutcome' nomarkout `stat' `binary' cmd(`cmd')
	
	local klev = `s(klev)'
	local tvar `s(tvar)'
	local fvtvar `s(fvtvar)'
	local control = `s(control)'
	local levels `"`s(levels)'"'
	
	foreach lev of local levels {
		local n`lev' = `s(n`lev')'
	}
	
	if "`s(tlevel)'"!="" local tlevel = `s(tlevel)'
	
	if `klev'>2 {
		di as err "{p}treatment-model {bf:`tmodel'} requires 2 " ///
		"levels in treatment variable {bf:`tvar'}, but `klev' " ///
		"were found{p_end}"
		exit 459
	}
	
	local fvops false
	if "`tvarlist'"!="" {
		_teffects2_vlist_exclusive2, vlist1(`tvar') vlist2(`tvarlist') case(4)
		
		_rmdcoll `tvar' `tvarlist' `wts' if `touse', `constant'
		if r(k_omitted)!=0 local tvarlist `r(varlist)'
		
		cap fvexpand `tvarlist' if `touse'
		if c(rc) {
			di as err "{p}unable to expand treatment model " ///
			"{bf:`tvarlist'}{p_end}"
			exit 198
		}
		
		if "`r(fvops)'"=="true" {
			local fvtvarlist "`r(varlist)'"
			local fvops true
		}
		else local fvtvarlist `tvarlist'
		
		fvrevar `tvarlist', list
		local tvarlist `r(varlist)'
		local tvarlist : list uniq tvarlist
	}
	
	sreturn local tmodel `tmodel'
	sreturn local tvarlist `"`tvarlist'"'
	sreturn local k : word count `tvarlist'
	sreturn local fvtvarlist `"`fvtvarlist'"'
	sreturn local kfv : word count `fvtvarlist'
	sreturn local levels `"`levels'"'
	sreturn local control = `control'
	sreturn local klev = `klev'
	sreturn local tvar `tvar'
	sreturn local fvtvar `fvtvar'
	sreturn local levels `"`levels'"'
	sreturn local fvops `fvops'
	sreturn local tfvops `tfvops'
	sreturn local constant `constant'
	foreach lev of local levels {
		sreturn local n`lev' = `n`lev''
	}
	if "`tlevel'"!="" sreturn local tlevel = `tlevel'
end

capture program drop ParsePSmodel2
program define ParsePSmodel2, sclass
	version 17
	
	_on_colon_parse `0'
	local which `s(before)'
	local 0 `s(after)'
	
	cap noi syntax [anything(id="tmodel" name=tmodel)] [, linear ]
	
	local rc = c(rc)
	if `rc' {
		di as err "treatment model is misspecified"
		exit `rc'
	}
	
	ParseLogitCBPSIPT, `tmodel'
	
	local logit `s(logit)'
	local cbps `s(cbps)'
	local ipt `s(ipt)'
	
	local k : word count `logit' `cbps' `ipt'
	
	if `k'>1 {
		di as err "treatment model is misspecified; only one of {bf:logit}, {bf:cbps}, or {bf:ipt} is allowed"
		exit 184
	}
	
	if `k'==0 local tmodel logit
	else local tmodel `logit'`cbps'`ipt'
	
	sreturn local tmodel `tmodel'
	sreturn local linear `linear'
end

capture program drop ParseLogitCBPSIPT
program define ParseLogitCBPSIPT, sclass
	version 17
	
	cap noi syntax, [ logit cbps ipt ]
	
	local rc = c(rc)
	if `rc' {
		di as txt "{phang}treatment model is misspecified; specify one of {bf:logit}, {bf:cbps}, or {bf:ipt}{p_end}"
		exit `rc'
	}
	
	sreturn local logit `logit'
	sreturn local cbps `cbps'
	sreturn local ipt `ipt'
end
