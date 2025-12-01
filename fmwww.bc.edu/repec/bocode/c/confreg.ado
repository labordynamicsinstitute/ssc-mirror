*! Package confreg v. 1.0
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2025-11-24 Created

*TODO Add -1 for inconclusive in test. Report P(inconclusive|C+) and P(inconclusive|C-) ?
*TODO noSPec and noSEns ?

program define confreg, rclass
    version 15.1
	// varlist truevals testvals groups
	syntax varlist(min=2 max=3) [if], /*
	*/[ /*
		*/id(passthru) /*
		*/Randomeffects(passthru) /*
		*/ADJustment(varlist fv) /*
		*/Coleq(string) /*
		*/Prevalence(numlist max=1 >0 <1) /*
		*/vce(passthru) /*
		*/STub(string) /*
		*/SCale(real 100) /*
	*/]
	
	tokenize `"`varlist'"'
	local truevals `1'
	local tstvals `2'
	local msrmnt `3'
	return clear
	if "`msrmnt'" == "" {
		tempvar msrmnt
		generate `msrmnt' = 1
	}
	qui levelsof `truevals', local(zero_one)
	if "`zero_one'" != "0 1" mata: _error("True values (1st variable) is not zero-one")
	qui levelsof `tstvals', local(zero_one)
	if "`zero_one'" != "0 1" mata: _error("Test values (2nd variable) is not zero-one")
	
	_se_sp_auc `if', tst(`tstvals') trv(`truevals') tp(`msrmnt') `vce' `randomeffects' `id'
	matrix se_sp_auc = r(se_sp_auc)
	if "`coleq'" != "" matrix coleq se_sp_auc = "`coleq'"
	matrix se_sp_auc_corr = r(se_sp_auc_corr)
	matlist se_sp_auc, twidth(32)

	if "`prevalence'" == "" {
		su `truevals' `if', mean
		local prevalence `r(mean)'
	}
	_acc_ppv_npv `tstvals' `if', prev(`prevalence') tp(`msrmnt') stub(`stub')
	matrix acc_ppv_npv = r(acc_ppv_npv)
	if "`coleq'" != "" matrix coleq acc_ppv_npv = "`coleq'"
	
	matrix confreg = acc_ppv_npv[1,1...]
	qui levelsof `msrmnt' `if', local(lvls)
	local n = 1
	foreach lvl in `lvls' {
		matrix confreg = confreg ///
			\ se_sp_auc[`n'..`=`n'+2', 1...] ///
			/*\ se_sp_auc[`n'..`=`n'+4', 1...]*/ ///
			\ acc_ppv_npv[`=`n'+1'..`=`n'+3', 1...]
		local n = `n' + 3
	}
	
	return matrix se_sp_auc = se_sp_auc
	return matrix se_sp_auc_corr = se_sp_auc_corr
	return matrix acc_ppv_npv = acc_ppv_npv
	return matrix confreg = confreg
	drop _est*
end

program define _se_sp_auc, rclass
	syntax [if], tst(varname) trv(varname) tp(varname) ///
		[id(varname) Randomeffects(string) adj(varlist) vce(passthru) ///
		stub(string) scale(real 100)]
	
	local fnd
	capture matrix drop totals
	qui levelsof `tp' `if', local(lvls)
	local notfirst 0
	foreach lvl in `lvls' {
		if !`notfirst++' == 1 local rnms "`:label (`tp') `lvl'':Sensitivity, P(TP|C+)"
		else local rnms "`rnms'" "`:label (`tp') `lvl'':Sensitivity, P(TP|C+)"
		local fnd `fnd' ( se`lvl' : `' _b[1.`trv'#`lvl'.`tp'])
		local rnms "`rnms'" "`:label (`tp') `lvl'':Specificity, P(TN|C-)"
		local fnd `fnd' ( sp`lvl' : (1 - _b[0.`trv'#`lvl'.`tp']))
		local rnms "`rnms'" "`:label (`tp') `lvl'':AUC, (sens+spec)/2"
		local fnd `fnd' (auc`lvl' : 0.5 * (_b[1.`trv'#`lvl'.`tp'] + 1 - _b[0.`trv'#`lvl'.`tp']))
		*local rnms "`rnms'" "`:label (`tp') `lvl'':LR+, sens/(1-spec)"
		*local fnd `fnd' (LRp`lvl' : _b[1.`trv'#`lvl'.`tp'] / _b[0.`trv'#`lvl'.`tp'])
		*local rnms "`rnms'" "`:label (`tp') `lvl'':LR-, (1-sens)/spec"
		*local fnd `fnd' (LRm`lvl' : (1 - _b[1.`trv'#`lvl'.`tp']) / (1 - _b[0.`trv'#`lvl'.`tp']))
		if "`if'" == "" qui su `trv' if `tp' == `lvl'
		else qui su `trv' `if' & `tp' == `lvl'
		matrix totals = nullmat(totals) \ r(sum) \ r(N) - r(sum) \ r(N)
	}
	if "`id'" != "" local id ||`id':
	qui mixed `tst' i.`trv'##i.`tp' `adj' `if', `vce' `randomeffects' `id'
	*qui mepoisson `tst' i.`trv'##i.`tp' `adj' `if', `vce' `id'
	qui margins `trv'#`tp', post
	qui nlcom `fnd', post
	qui _coef_table
	matrix _tbl = r(table)
	matrix se_sp_auc = totals, `scale' * (_tbl["b", 1...]', _tbl["ll", 1...]', _tbl["ul", 1...]')
	matrix colnames se_sp_auc = N p [`c(level)'% CI]
	matrix rownames se_sp_auc = "`rnms'"
	estimates store `stub'_se_sp_auc
	return matrix se_sp_auc = se_sp_auc
	qui estat vce, correlation
	matrix C = r(V) 
	mata: C = st_matrix("C")
	mata: dc = 1 :/ sqrt(diagonal(C))
	mata: newC = lowertriangle(C :* (dc # dc'))
	mata: newC = newC :* (1 :/ (newC :> 1e-4))
	mata: st_replacematrix("C", newC)
	matrix colnames C = "`rnms'"
	matrix rownames C = "`rnms'"
	return matrix se_sp_auc_corr = C
end

program define _acc_ppv_npv, rclass
	syntax varname [if], prev(numlist max=1 >0 <1) tp(varname) [stub(string) scale(real 100)]
	
	estimates restore `stub'_se_sp_auc

	capture matrix drop totals
	local fnd
	qui levelsof `tp' `if', local(lvls)
	local rnms ":Prevalence, C+/N"
	foreach lvl in `lvls' {
		local rnms "`rnms'" "`:label (`tp') `lvl'':Accuracy, P(TP + TN)"
		local fnd `fnd' (acc`lvl': _b[se`lvl'] * `prev' + _b[sp`lvl'] * (1 - `prev'))
		local rnms "`rnms'" "`:label (`tp') `lvl'':PPV, P(TP|P+)"
		local fnd `fnd' (ppv`lvl': _b[se`lvl'] * `prev' / (_b[se`lvl'] * `prev' + (1 - _b[sp`lvl']) * (1 - `prev')))
		local rnms "`rnms'" "`:label (`tp') `lvl'':NPV, P(TN|P-)"
		local fnd `fnd' (npv`lvl': _b[sp`lvl'] * (1 - `prev') / (_b[sp`lvl'] * (1 - `prev') + (1 - _b[se`lvl']) * `prev'))
		if "`if'" == "" qui su `varlist' if `tp' == `lvl'
		else qui su `varlist' `if' & `tp' == `lvl'
		matrix totals = nullmat(totals) \ r(sum) \ r(N) - r(sum) \ r(N)
	}
	qui nlcom `fnd', post
	qui _coef_table
	matrix _tbl = r(table)
	matrix acc_ppv_npv = totals, `scale' * (_tbl["b", 1...]', _tbl["ll", 1...]', _tbl["ul", 1...]')
	matrix acc_ppv_npv = (., `prev', ., .) \ acc_ppv_npv
	matrix colnames acc_ppv_npv = N p [`c(level)'% CI]
	matrix rownames acc_ppv_npv = "`rnms'"
	estimates store `stub'_acc_ppv_npv
	return matrix acc_ppv_npv = acc_ppv_npv
end
