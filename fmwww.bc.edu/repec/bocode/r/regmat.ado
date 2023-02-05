*! Part of package matrixtools v. 0.30
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2023-01-01 > Option nozero added
*! 2022-12-29 > st_ regressions added as stregmat
*! 2022-12-29 > se(b) = . for base
*! 2022-12-29 > When convergence isn't achieved, missings are inserted
*! 2022-12-29 > run_regressions renamed to nhb_mt_run_regressions and moved to matrixtools
*! 2022-12-29 > tolabels renamed to nhb_mt_tolabels and moved to matrixtools
*! 2021-01-03 > Option names for alternative adjustment names
*! 2021-01-03 > toxl added
*! 2021-01-03 > Option btext for alternative column name for b added
* TODO: n and x as option in front of regmat table - Based on crossmat
* TODO: Enter adjustments variables at a level, force certain adjustment variables
* TODO: Option summary (sumat) of outcome by values of exposure
* 2019-03-11 > s(if) and s(in) added to regressions
* 2019-03-11 > Option verbose added
* 2018-12-16 > Changed to manual eform
* 2018-12-03 > Handling mixed regression
* 2018-12-03 > Fixed: keep b implies selecting se(b) BUG!
* 2018-06-05 > Created

program define regmat, rclass
	version 12.1

	if `c(version)' >= 13 set prefix regmat

	sreturn clear
	_prefix_clear

	capture _on_colon_parse `0'
	
	local 0 `s(before)'
	syntax [using], /*
		*/Outcomes(varlist min=1) /*
		*/Exposures(varlist min=1 fv) /*
		*/[ /*
            */Adjustments(string asis) /*
            */noQuietly /*
            */Labels /*
            */BAse /*
            */Keep(string) /*
            */DRop(string) /*
            */EForm /*
            */Verbose /*
            */noCleanupmata /*
            */BText(string) /*
            */Names(string asis) /*
            matprint options
            */Style(passthru) /*      
            */Decimals(passthru) /*
            */TItle(passthru) /*
            */TOp(passthru) /*
            */Undertop(passthru) /*
            */Bottom(passthru) /*
            */Replace(passthru) /*
            */noEqstrip /*
            */noZero /*
            */toxl(passthru) /*
		*/]

	if "`verbose'" != "" macro dir
	
	if `"`adjustments'"' == "" local adjustments  `""""'
		
	if "`quietly'" != "" {
		mata __showcode = 1
		mata __addquietly = 0
	}
	else {
		mata __showcode = 0
		mata __addquietly = 1	
	}
	
	mata __keep = 1
	if "`drop'" != "" {
		local __str_colnames "`drop'"
		mata __keep = 0
	}
	if "`keep'" != "" {
		local __str_colnames "`keep'"
		mata __keep = 1
	}
	local __str_colnames = strlower(`"`__str_colnames'"')
	local __str_colnames : list uniq __str_colnames
	local values b se ci p
	if ! `:list __str_colnames in values' {
		local __str_colnames = ""
		mata __keep = 1
	}
	mata: __str_slct = invtokens(tokens(st_local("__str_colnames")), "|")
	mata: __str_slct = regexm(__str_slct, "^b") ? "^" + __str_slct : __str_slct // keep b implies selecting se(b) BUG!
	mata: __str_slct = subinstr(__str_slct, "|b", "|^b")						// keep b implies selecting se(b) BUG!
	mata: __str_slct = subinstr(__str_slct, "ci", "CI")
	mata: __str_slct = subinstr(__str_slct, "p", "P")
    
    mata __names = J(1,0,"")
    if `"`names'"' != "" capture mata: __names = `names'
    if _rc mata __names = J(1,0,"")
	
	_prefix_command regmat: `s(after)'
	if "`verbose'" != "" return list
	if "`verbose'" != "" sreturn list
	local _cmd `s(cmdname)'
	*local __postcmd = subinstr(`"`s(command)'"', `"`_cmd'"', "", 1)	// 2018-12-03
	local __postcmd `"`s(anything0)'"'	// 2018-12-03
	if "`s(options)'" != "" local _options ", `s(options)'" // 2018-12-07
	*local eform = ("`s(efopt)'" != "") // 2018-12-16
	local eform = ("`eform'" != "") // 2018-12-16
	
	mata: __regressions = J(0,length(tokens(`"`adjustments'"')),"")
	foreach outcome in `outcomes' {
		foreach exposure in `exposures' {
			mata _row = J(1,0,"")
			foreach adj in `adjustments' {
				mata _row = _row, `"`_cmd' `outcome' `exposure' `adj' `s(if)' `s(in)' `__postcmd' `_options'"'
			}
			mata __regressions = __regressions \ _row
		}
	}
	mata: __regmattbl = nhb_mt_run_regressions(__regressions, "`base'" == "", ///
  `eform', __showcode, __addquietly, `"`btext'"', __names)
    
    mata: st_rclear()
	mata: st_eclear()
	local adjnbr = 1
	foreach adj in `adjustments' {
		if "`adj'" == "" return local Adjustment_`adjnbr' = "Crude"
		else return local Adjustment_`adjnbr++' = "`adj'"
	}
	mata: __regmattbl = nhb_mt_tolabels(__regmattbl, "`labels'" != "")
	mata: __regmattbl = __regmattbl.regex_select(__str_slct, __keep, 1, 0)
	mata: __regmattbl.to_matrix("r(regmat)")

	*** matprint ***************************************************************
	matprint r(regmat) `using',	`style' `decimals' `title' `top' `undertop'  ///
    `bottom' `replace' `eqstrip' `zero' `toxl'
	****************************************************************************
	
	return add
	if "`verbose'" != "" local cleanupmata cleanupmata
	if `"`cleanupmata'"' == "" capture mata: mata drop __* 
end

mata 
	class nhb_mt_labelmatrix scalar nhb_mt_run_regressions(
		string matrix regs,
		| real scalar nobase,
		real scalar eform,
		real scalar __showcode, 
		real scalar __addquietly,
    string scalar btext,
    string rowvector names)
	{
		real scalar r, c, R, C, rc, N
		string scalar exposure
		class nhb_mt_labelmatrix scalar tmp, column, out
	
		R = rows(regs)
		C = cols(regs)
        N = cols(names)
		for(c=1;c<=C;c++) {
			column.clear()
			for(r=1;r<=R;r++) {
				if ( regexm(tokens(regs[r,c])[3], "^(.+)\.(.+)$") ) {
					exposure = regexs(2)
				} else {
					exposure = tokens(regs[r,c])[3]
				}
				rc = nhb_sae_logstatacode(regs[r,c], __showcode, __addquietly)
				tmp = nhb_mc_post_ci_table(eform, st_numscalar("c(level)"))
        if ( rc == 430 ) tmp.values(J(rows(tmp.values()), 5, .))
				if ( nobase ) tmp = tmp.regex_select(exposure).regex_select("b\.",0)	//drop base
				tmp = tmp.regex_select(exposure).regex_select("o\.",0)	//drop omitted
				if ( column.empty() ) column = tmp
				else column.append(tmp)
			}
			if ( c > N ) column.column_equations(sprintf("Adjustment %f", c))
            else column.column_equations(names[c])
			if ( c == 1 ) out = column
			else out.add_sideways(column)
		}
    if ( btext != "") {
        out.column_names(regexr(out.column_names(), "^b$", btext))
        out.column_names(regexr(out.column_names(), "^se\(b\)$", sprintf("se(%s)", btext)))
    }
		return(out)
	}
end
