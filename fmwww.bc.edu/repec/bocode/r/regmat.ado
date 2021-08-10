*! Part of package matrixtools v. 0.27
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2021-01-03 Option names for alternative adjustment names
*! 2021-01-03 Option btext for alternative column name for b added
*! 2021-01-03 toxl added
* 2019-03-11 > s(if) and s(in) added to regressions
* 2019-03-11 > Option verbose added
* 2018-12-16 > Changed to manual eform
* 2018-12-03 > Handling mixed regression
* 2018-12-03 > Fixed: keep b implies selecting se(b) BUG!
* 2018-06-05 > Created
* TODO: Add st_ regressions, see: st_is 2 analysis
* TODO: Enter adjustments variables at a level, force certain adjustment variables
* TODO: Option summary (sumat) of outcome by values of exposure
* TODO: Add option btext for alternative column name for b
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
	mata: __regmattbl = run_regressions(__regressions, "`base'" == "", `eform', ///
		__showcode, __addquietly, `"`btext'"', __names)
    
    mata: st_rclear()
	mata: st_eclear()
	local adjnbr = 1
	foreach adj in `adjustments' {
		if "`adj'" == "" return local Adjustment_`adjnbr' = "Crude"
		else return local Adjustment_`adjnbr++' = "`adj'"
	}
	mata: __regmattbl = tolabels(__regmattbl, "`labels'" != "")
	mata: __regmattbl = __regmattbl.regex_select(__str_slct, __keep, 1, 0)
	mata: __regmattbl.to_matrix("r(regmat)")

	*** matprint ***************************************************************
	matprint r(regmat) `using',	`style' `decimals' `title' `top' `undertop' `bottom' `replace' `toxl'
	****************************************************************************
	
	return add
	if "`verbose'" != "" local cleanupmata cleanupmata
	if `"`cleanupmata'"' == "" capture mata: mata drop __* 
end

mata 
	class nhb_mt_labelmatrix scalar run_regressions(
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
 
 class nhb_mt_labelmatrix tolabels(	class nhb_mt_labelmatrix mat_tbl,
									|real scalar uselbl,
									real scalar userows)
	{
		real scalar c, C
		string scalar varnametxt, varvaluetxt
		string colvector eq, nms

		if ( userows) {
			eq = mat_tbl.row_equations()
			nms = mat_tbl.row_names()
		} else {
			eq = mat_tbl.column_equations()
			nms = mat_tbl.column_names()
		}
		C = rows(eq)
		if ( uselbl ) for(c=1;c<=C;c++) eq[c] = st_varlabel(eq[c])
		for(c=1;c<=C;c++) {
			if ( regexm(nms[c], "([0-9]+)b?\.(.+)$") ) {
				if ( uselbl ) {
					varnametxt = st_varlabel(regexs(2))
					if ( st_varvaluelabel(regexs(2)) != "" ) {
						varvaluetxt = nhb_sae_labelsof(regexs(2), 
														strtoreal(regexs(1)))
					} else {
						varvaluetxt = regexs(1)
					}
				} else {
					varnametxt = regexs(2)
					varvaluetxt = regexs(1)
				}
				nms[c] = sprintf("%s (%s)", varnametxt, varvaluetxt)
			} else {
				if ( uselbl ) nms[c] = st_varlabel(nms[c])
			}
		}
		mat_tbl.row_equations(eq)
		mat_tbl.row_names(nms)
		return(mat_tbl)
	}
end
