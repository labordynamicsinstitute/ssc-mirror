*! version 1.0.0 17jan2026

// predict after xtselfe; loosely based on xtrefe_p.ado
program define xtselfe_p
	version 16.1
	
	// subroutine to predict
	local myopts "XB UE XBU U E"
	_pred_se "`myopts'" `0'
	if `s(done)' {
		exit
	}
	local vtyp `s(typ)'
	local varn `s(varn)'
	local 0 `"`s(rest)'"'
	
	// syntax
	syntax [if] [in], [XB UE XBU U E]
	
	// one option allowed
	local optstmt ""
	foreach option in xb ue xbu u e {
		if "``option''" != "" {
			local optstmt "`optstmt' ``option''"
		}
	}
	gettoken opt opttail : optstmt
	local opttail = trim("`opttail'")
	if "`opttail'" != "" {
		di as err "option '`opttail'' not allowed"
		exit 198
	}
	if "`opt'" == "" {
		local opt = "xb"  // xb is used by default
	}
	
	// mark observations
	marksample touse
	local touse2 "`touse' & e(sample)"  // or touse2 "`touse'"
	local selected "`e(seldep)'==1"
	
	// prediction
	tempname bhat
	mat `bhat' = e(b)
	local constant = `bhat'[1,"_cons"]
	local depvar = e(depvar)
	local ivar = e(ivar)
	tempvar xb_u xb ue u
	qui _predict double `xb_u' if `touse2', xb
	qui gen double `xb' = `xb_u'+`constant' if `touse2'
	if "`opt'" == "xb" {
		gen `vtyp' `varn' = `xb' if `touse2'
		qui label var `varn' "a + xb"
	}
	else {
		qui gen double `ue' = `depvar'-`xb' if `touse2'
		if "`opt'" == "ue" {
			gen `vtyp' `varn' = `ue' if `touse2'
			qui label var `varn' "u(i) + e(i,t)"
		}
		else {
			qui by `ivar': egen double `u' = mean(`ue') if `touse2' & `selected'
			if "`opt'" == "u" {
				gen `vtyp' `varn' = `u' if `touse2'
				qui label var `varn' "u(i)"
			}
			else if "`opt'" == "xbu" {
				gen `vtyp' `varn' = `xb'+`u' if `touse2'
				qui label var `varn' "a + xb + u(i)"
			}
			else if "`opt'" == "e" {
				gen `vtyp' `varn' = `ue'-`u' if `touse2'
				qui label var `varn' "e(i,t)"
			}
		}
	}
end
