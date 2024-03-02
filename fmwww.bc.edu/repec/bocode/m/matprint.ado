*! Part of package matrixtools v. 0.31
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2024-02-23 > Option todocx added
* 2023-01-01 > Option nozero added
* 2021-01-03 > toxl added
* 2020-03-05 > empty rownames not printet
* 2020-03-05 > option no rowlabels
* 2019-06-11 > Caption/Title added
* 2018-09-09 > Option for removing row header from print
* 2017-01-06 > Rewritten 
* TODO: To word?
* TODO: Option order as basetable
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
			*/noZero /*
			*/Hidesmall(integer 0) /*
			*/noCleanupmata /*
      */toxl(passthru) /*
      */todocx(string) /*
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
  if `"`zero'"' != "" mata: __mp_lm.values(__mp_lm.values() :/ (__mp_lm.values() :!= 0))
	if "`rowheaders'" != "" {
		mata: __mp_lm.row_equations("")
		mata: __mp_lm.row_names("")
	}
    
	mata: __mp_lm.print(	"`style'",  __decimals, ///
							"`eqstrip'" == "", `hidesmall', ///
							"`caption'", "`top'", "`undertop'", "`bottom'", ///
							"`using'", "`replace'" == "replace")
    capture mata: mata drop __decimals
    
	if `"`decimals'"' != "" local decimals decimals(`decimals')
	if `"`hidesmall'"' != "." local hidesmall hidesmall(`hidesmall')
	else local hidesmall 
	
	*** mat2xl *******************************************************************
	if `"`toxl'"' != "" {
		if `c(stata_version)' >= 13 mat2xl `matrixname', `toxl' `eqstrip' `hidesmall' `decimals' 
	}
	******************************************************************************
	
	*** mat2docx *****************************************************************
	if "`todocx'" != "" {
		if `c(stata_version)' >= 13 mata: msm2d("`todocx'", __mp_lm.to_strings(), "`title'")
		else display "{error:Option todocx do not work in version 12 for Stata.}" 
	}
	******************************************************************************

	if `"`cleanupmata'"' == "" capture mata: mata drop __mp_lm
end

if `c(stata_version)' >= 13 {
    mata st_local( "__2docx_fn", findfile("ltodocx_v13.mata"))
    include "`__2docx_fn'"
}
