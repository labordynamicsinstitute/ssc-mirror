*! version 1.0.0  12sep2025  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2025 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop _teffects2_parse_tvar
program define _teffects2_parse_tvar, sclass sortpreserve
	version 17
	
	sreturn clear
	
	syntax varname(numeric), touse(varname) stat(string) ///
	[ freq(varname) noMARKout binary cmd(string) ]
	
	local tvar `varlist'
	
	if "`markout'"=="" {
		markout `touse' `tvar'
		_teffects2_count_obs `touse', freq(`freq') ///
		why(observations with missing values)
	}
	
	_teffects_validate_catvar `tvar', argname(treatment variable) touse(`touse') binary
	local klev = `r(klev)'
	
	if "`freq'"!="" local wt [fw=`freq']
	
	tempname tlev tfrq
	quietly tabulate `tvar' if `touse' `wt', matrow(`tlev') matcell(`tfrq')
	
	if `klev'!=2 {
		di as err "{p}treatment variable {bf:`tvar'} must have exactly 2 levels{p_end}"
		exit 459
	}
	
	// Infer treatment/control based on ascending order of values
	local v1 = `tlev'[1,1]
	local v2 = `tlev'[2,1]
	
	local control = min(`v1', `v2')
	local tlevel = max(`v1', `v2')
	
	// Return frequencies for both levels
	forvalues i=1/2 {
		local lev = `tlev'[`i',1]
		local k = `tfrq'[`i',1]
		sreturn local n`lev' = `k'
		local levels `levels' `lev'
	}
	
	local levels : list retokenize levels
	
	sreturn local tvar `tvar'
	sreturn local klev = `klev'
	sreturn local levels `"`levels'"'
	sreturn local control = `control'
	sreturn local tlevel = `tlevel'
end
