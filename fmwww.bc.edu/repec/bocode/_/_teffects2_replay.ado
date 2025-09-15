*! version 1.0.0  12sep2025  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2025 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop _teffects2_replay
program define _teffects2_replay
	version 17
	
	syntax, [ * ]
	
	_get_diopts diopts, `options'
	
	if "`e(subcmd)'"=="ipw" {
		local omodel "weighted mean"
		
		if "`e(tmodel)'"!="ipt" {
			if "`e(statnorm)'"=="nrm" local estimator "IPW"
			else if "`e(statnorm)'"=="unnrm" local estimator "IPW (unnormalized)"
			
			if "`e(tmodel)'"=="logit" local tmodel "logit ML"
			else if "`e(tmodel)'"=="cbps" local tmodel "logit CBPS"
			else local tmodel `e(tmodel)'
		}
		else if "`e(tmodel)'"=="ipt" {
			local estimator "IPW"
			local tmodel "logit IPT"
		}
	}
	
	else if "`e(subcmd)'"=="ipwra" {
		local omodel "linear"
		local estimator "IPW regression adjustment"
		
		if "`e(tmodel)'"=="logit" local tmodel "logit ML"
		else if "`e(tmodel)'"=="cbps" local tmodel "logit CBPS"
		else if "`e(tmodel)'"=="ipt" local tmodel "logit IPT"
		else local tmodel `e(tmodel)'
	}
	
	else if "`e(subcmd)'"=="aipw" {
		local omodel "linear"
		
		if "`e(tmodel)'"!="ipt" {
			if "`e(statnorm)'"=="nrm" local estimator "augmented IPW (normalized)"
			else if "`e(statnorm)'"=="unnrm" local estimator "augmented IPW"
			
			if "`e(tmodel)'"=="logit" local tmodel "logit ML"
			else if "`e(tmodel)'"=="cbps" local tmodel "logit CBPS"
			else local tmodel `e(tmodel)'
		}
		else if "`e(tmodel)'"=="ipt" {
			local estimator "augmented IPW"
			local tmodel "logit IPT"
		}
	}

	di as txt _n "`e(title)'" ///
	"{col 49}Number of obs {col 67}= " as res %10.0fc e(N)
	di "{txt:Estimator}{col 16}:{res: `estimator'}"
	di "{txt:Outcome model}{col 16}:{res: `omodel'}"
	di "{txt:Treatment model}{col 16}:{res: `tmodel'}"
	
	_coef_table, versus `neq' `diopts'
end
