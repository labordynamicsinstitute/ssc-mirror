*! Part of package matrixtools v. 0.28
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2021-01-03 toxl added
* 2020-03-05 empty rownames not printet
* 2020-03-05 option no rowlabels
* 2019-06-11 Caption/Title added
* 2018-09-09 Option for removing row header from print
* 2017-01-06 Rewritten 
* TODO: To word?
program define matprint
	version 12.1
	syntax anything(name=matrixexpression) [using/]/*
		*/[,/*
			*/Style(string) /*
			*/Decimals(string) /*
			*/noRowheaders /*
			*/TItle(string) /*
			*/CAPtion(string) /*
			*/TOp(string) /*
			*/Undertop(string) /*
			*/Bottom(string) /*
			*/Replace /*
			*/noEqstrip /*
			*/Hidesmall(integer 0) /*
			*/noCleanupmata /*
            */toxl(passthru) /*
		*/]

	if "`title'" != "" local caption `"`title'"'
	tempname matrixname
	matrix `matrixname' = `matrixexpression'

	capture mata: __decimals = `decimals'
	if _rc mata: __decimals = 2	
	if `=`hidesmall' <= 0' local hidesmall .
	
	// Returned lines lines are accessible from Mata in variable __mp_lm
	mata: __mp_lm = nhb_mt_labelmatrix()
	mata: __mp_lm.from_matrix("`matrixname'")
	if "`rowheaders'" != "" {
		mata: __mp_lm.row_equations("")
		mata: __mp_lm.row_names("")
	}
    
	mata: __mp_lm.print(	"`style'",  __decimals, ///
							"`eqstrip'" == "", `hidesmall', ///
							"`caption'", "`top'", "`undertop'", "`bottom'", ///
							"`using'", "`replace'" == "replace")
    capture mata: mata drop __decimals
	if `"`cleanupmata'"' == "" capture mata: mata drop __mp_lm
    
    if `"`decimals'"' != "" local decimals decimals(`decimals')
    if `"`hidesmall'"' != "." local hidesmall hidesmall(`hidesmall')
    else local hidesmall 
    
    *** mat2xl *****************************************************************
    if `"`toxl'"' != "" mat2xl `matrixname', `toxl' `eqstrip' `hidesmall' `decimals' 
    ****************************************************************************
	end
