*! Package mrgtbl2 v. 1.1
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2026-01-11 1.1 naming bugs fixed
* 2025-12-31 1.0 Revised and send
* 2025-12-17 1.0 Created

program define mrgtbl2, rclass

	* The option constraints are added to mixed in version 17.1 and up.
	* Hence this strange setting of version.
	if `c(version)' >= 17.1 version 17.1
	else version 15.1

	syntax [anything(name=regname)] [if], /*
		*/Outcome(passthru) /*
		*/Exposure(passthru) /*
		*/[ /*
			*/By1(passthru) /*
			*/by2(passthru) /*
			*/Adjustments(passthru) /*
			*/Cluster(passthru) /*
			*/CONSTraints(passthru) /*
			*/BOOTstrap(passthru)/*
			*/vce(passthru) /*
			*/Regopts(passthru) /*
			*/Mrgopts(passthru) /*
			*/btext(string) /*
			*/roweq(passthru) /*
			*/noLabel /*
			*/EForm /*
			*/Wide /*
			*/noQuietly /*
		*/]
	
	if "`quietly'" == "" local QUIETLY quietly
	if "`btext'" == "" local btext mrg
	
	_regcmd `regname' `if', `outcome' `exposure' `by1'  `by2' `adjustments' ///
		`cluster' `constraints' `bootstrap' `regopts' `mrgopts'
	local regcmd `r(regcmd)'
	local mrgcmd `r(mrgcmd)'
	local outcome `r(outcome)'
	local exposure `r(exposure)'
	local by1 `r(by1)'
	local by2 `r(by2)'
	local poscmds = `"`r(plst)'"'
	if "`QUIETLY'" == "" di as input _n `". `regcmd'"' _n
	`QUIETLY' `regcmd'
	if "`QUIETLY'" == "" di as input _n `". `mrgcmd'"' _n
	`QUIETLY' `mrgcmd'
	estimates store _mrgtbl2
	return local regcmd = `"`regcmd'"'
	return local mrgcmd = `"`mrgcmd'"'
	return local poscmds = `"`poscmds'"'
	
	_mrgtbl2 `exposure', btext(`btext') by1(`by1') by2(`by2') `label' `wide' ///
		`eform' `roweq'
	matrix mrgtbl2 = r(mrgtbl2)
	matlist mrgtbl2, tw(32)
	return matrix mrgtbl2 = mrgtbl2
end


program define _regcmd, rclass
	syntax [anything(name=regname)] [if], /*
		*/Outcome(varname) /*
		*/Exposure(varname) /*
		*/[ /*
			*/By1(varname) /*
			*/by2(varname) /*
			*/Adjustments(varlist fv) /*
			*/Cluster(varname) /*
			*/CONSTraints(passthru) /*
			*/BOOTstrap(string)/*
			*/vce(passthru) /*
			*/Regopts(string) /*
			*/Mrgopts(string) /*
		*/]
		
	if "`regname'" == "" local regname mixed
	local plst `""regress", "cnsreg", "mixed", "glm", "poisson", "nbreg", "'
	local plst `"`plst' "logit", "probit", "cloglog", "binreg", "meprobit", "'
	local plst `"`plst' "melogit", "mepoisson", "menbreg", "meglm", "mecloglog""'
	if !regexm(`"`plst'"', "`regname'") mata: _error("Chosen regression isn't allowed")
	if "`bootstrap'" != "" local bootstrap bootstrap, `bootstrap':
	if `"`cluster'"' != "" local cluster ||`cluster':,

	if "`by1'" == "" & "`by2'" == "" local expby i.`exposure'
	else if "`by1'" != "" & "`by2'" == "" local expby i.`exposure'#i.`by1'
	else if "`by1'" != "" & "`by2'" != "" local expby i.`exposure'#i.`by1'#i.`by2'
	local regcmd `bootstrap' `regname' `outcome' `expby' `adjustments' `if' ///
		, `constraints' `vce' `cluster' `regopts'

	if "`by1'" == "" & "`by2'" == "" local expby `exposure'
	else if "`by1'" != "" & "`by2'" == "" local expby `exposure'#`by1'
	else if "`by1'" != "" & "`by2'" != "" local expby `exposure'#`by1'#`by2'
	local mrgcmd margins `expby', `mrgopts' post
		
	return local regcmd `regcmd'
	return local mrgcmd `mrgcmd'
	return local outcome `outcome'
	return local exposure `exposure'
	return local by1 `by1'
	return local by2 `by2'
	return local plst `plst'
end

program define _row, rclass
	syntax , Formula(string) /*
		*/[ /*
			*/Pvalue /*
			*/Mrgtext(string) /*
			*/Wide /* 
			*/EForm /*
		*/]
	
	qui lincom `formula', `eform'
	if "`pvalue'" == "" {
		matrix _row = r(estimate), r(lb), r(ub)
		matrix colnames _row = `mrgtext' [`c(level)'% CI]
	} 
	else {
		matrix _row = r(estimate), r(lb), r(ub), r(p)
		matrix colnames _row = `mrgtext' [`c(level)'% CI] P(`mrgtext')		
	}
	if mi(`r(lb)') matrix _row = J(1,`=colsof(_row)',.)
	return matrix row = _row
end

program define _btbl, rclass
	syntax varname [if], /*
		*/[ /*
			*/Btext(string) /*
			*/by(string) /*
			*/roweq(string) /*
			*/Label /* (nolabel)
			*/Wide /*
			*/EForm /*
		*/]

	*qui estimates restore _mrgtbl2
	capture matrix drop btbl
	qui levelsof `varlist' `if'
	foreach lvl in `r(levels)' {
		if "`wide'" == "" local btxt `btext'
		else  local btxt `btext'(`lvl')
		local lbl `:label (`varlist') `lvl''
		if "`lbl'" == "" & "`label'" == "" local lbl `varlist'(`lvl')
		_row,  f("`lvl'.`varlist'`by'") m(`btxt') `eform'
		matrix _row = r(row)
		if "`wide'" == "" {
			matrix coleq _row = ""
			matrix rownames _row = "`=abbrev("`lbl'", 32)'"
			local btxt `btxt'
			matrix btbl = nullmat(btbl) \ _row
		}
		else {
			matrix coleq _row = "`=abbrev("`lbl'", 32)'"
			matrix rownames _row = ""
			local btxt `btxt'
			matrix btbl = _row, nullmat(btbl)
		}
	}
	return matrix btbl = btbl
end

program define _dtbl, rclass
	syntax varname [if], /*
		*/[ /*
			*/Btext(string) /*
			*/by(string) /*
			*/roweq(string) /*
			*/Label /* (nolabel)
			*/Wide /*
			*/EForm /*
		*/]
		
	*qui estimates restore _mrgtbl2
	capture matrix drop dtbl
	local ref 
	qui levelsof `varlist' `if'
	foreach lvl in `r(levels)' {
		if "`ref'" == "" {
			local ref `lvl'
			continue
		}

		local btxt `btext'(vsRef)
		_row,  f("`lvl'.`varlist'`by' - `ref'.`varlist'`by'") p m(`btxt') `eform'
		matrix _row = r(row)
		if "`wide'" == "" {
			matrix rownames _row = "`=abbrev("`btext'(`lvl'vs`ref')", 32)'"
			matrix dtbl = nullmat(dtbl) \ _row
		}
		else {
			matrix coleq _row = "`=abbrev("`btext'(`lvl'vs`ref')",32)'"
			matrix dtbl = _row, nullmat(dtbl)
		}
	}
	if "`wide'" == "" {
		matrix _refrow = J(1,4,.)
		matrix rownames _refrow = ref
		matrix colnames _refrow = `:colnames dtbl'
		matrix dtbl = _refrow \ dtbl
	}
	return matrix dtbl = dtbl
end

program define _mrgtbl2, rclass
	syntax varname [if] , /*
		*/[ /*
			*/By1(varname) /*
			*/by2(varname) /*
			*/btext(string) /*
			*/roweq(string) /*
			*/noLabel /*
			*/noCounts /*
			*/Wide /*
			*/EForm /*
		*/]

	*qui estimates restore _mrgtbl2
	if "`by1'" == "" & "`by2'" == "" {
		_btbl `varlist', btext(`btext') `label' `wide' `eform'
		matrix _mrgtbl2 = r(btbl)
		_dtbl `varlist', btext(`btext') `label' `wide' `eform'
		matrix _mrgtbl2 = _mrgtbl2, r(dtbl)
		if "`roweq'" != "" & "`wide'" == "" matrix roweq _mrgtbl2 ="`=abbrev("`roweq'", 32)'"
		if "`roweq'" != "" & "`wide'" != ""  matrix rownames _mrgtbl2 = "`=abbrev("`roweq'", 32)'"
	}
	else if "`by1'" != "" & "`by2'" == "" {
		capture matrix drop _mrgtbl2
		qui levelsof `by1' `if'
		foreach lvl1 in `r(levels)' {
			_btbl `varlist', btext(`btext') by(#`lvl1'.`by1') `label' `wide' `eform'
			matrix _brow = r(btbl)
			_dtbl `varlist', btext(`btext') by(#`lvl1'.`by1') `label' `wide' `eform'
			matrix _drow = r(dtbl)
			mata: st_replacematrix("_drow", st_matrix("_drow") ///
				:/ (rowmissing(st_matrix("_brow")) :== 0))
			if `=_brow[1,2]== .' mata: st_replacematrix("_drow", st_matrix("_drow") :/ 0)
			matrix _row = _brow, _drow
			local lbl1 `:label (`by1') `lvl1''
			if "`lbl1'" == "`lvl1'" & "`label'" == "" local lbl1 `by1'(`lvl1')
			if "`wide'" == "" matrix roweq _row = "`lbl1'"
			else matrix rownames _row = "`=abbrev("`lbl1'", 32)'"
			matrix _mrgtbl2 = nullmat(_mrgtbl2) \ _row
		}
		if "`roweq'" != "" & "`wide'" != "" matrix roweq _mrgtbl2 ="`=abbrev("`roweq'", 32)'"
	}
	else if "`by1'" != "" & "`by2'" != "" {
		capture matrix drop _mrgtbl2
		qui levelsof `by2' `if'
		foreach lvl2 in `r(levels)' {
			local lbl2 `:label (`by2') `lvl2''
			if "`lbl2'" == "`lvl2'" & "`label'" == "" local lbl2 `by2'(`lvl2')
			qui levelsof `by1' `if'
			foreach lvl1 in `r(levels)' {
				_btbl `varlist', btext(`btext') by(#`lvl1'.`by1'#`lvl2'.`by2') ///
					`label' `wide' `eform'
				matrix _brow = r(btbl)
				_dtbl `varlist', btext(`btext') by(#`lvl1'.`by1'#`lvl2'.`by2') ///
					`label' `wide' `eform'
				matrix _drow = r(dtbl)
				mata: st_replacematrix("_drow", st_matrix("_drow") ///
					:/ (rowmissing(st_matrix("_brow")) :== 0))
				if `=_brow[1,2]== .' mata: st_replacematrix("_drow", st_matrix("_drow") :/ 0)
				matrix _row = _brow, _drow
				local lbl1 `:label (`by1') `lvl1''
				if "`lbl1'" == "`lvl1'" & "`label'" == "" local lbl1 `by1'(`lvl1')
				if "`wide'" == "" matrix roweq _row = "`lbl2'&`lbl1'"
				else matrix rownames _row = "`=abbrev("`lbl2'&`lbl1'", 32)'"
				matrix _mrgtbl2 = nullmat(_mrgtbl2) \ _row
			}
		}		
		if "`roweq'" != "" & "`wide'" != "" matrix roweq _mrgtbl2 ="`=abbrev("`roweq'", 32)'"
	}
	return matrix mrgtbl2 = _mrgtbl2
end
