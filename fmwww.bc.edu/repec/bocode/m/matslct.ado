*! Part of package matrixtools v. 0.32
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*TODO add eform selected cells
*TODO make selected cells missing
*TODO suboption replace in option name
!* 2024-12-17 > created 
program define matslct, rclass
	version 12.1

	syntax anything(name=matrixexpression), /*
	*/[ /*
		*/Name(string) /*
		*/Rowselect(string) /*
		*/Columnselect(string) /*
		*/Transpose /*
		matprint options
		*/Style(passthru) /*
		*/Decimals(passthru) /*
		*/TItle(passthru) /*
		*/TOp(passthru) /*
		*/Undertop(passthru) /*
		*/Bottom(passthru) /*
		*/Replace /*
		*/noEqstrip /*
		*/noZero /*
		*/toxl(passthru) /*
		*/todocx(passthru) /*
	*/]

	if regexm("`matrixexpression'", "(.+)\[(.+);(.+)\]") {
		local matrixexpression = regexs(1)
		local rowselect = regexs(2)
		local columnselect = regexs(3)
	} 
	else if regexm("`matrixexpression'", "\((.+)\)\[(.+);(.+)\]") {
		local matrixexpression = regexs(1)
		local rowselect = regexs(2)
		local columnselect = regexs(3)
	}
	if "`rowselect'" == "" local rowselect .
	else local rowselect (`rowselect')
	if "`colselect'" == "" local colselect .
	else local colselect (`colselect')
	
	tempname matrixname
	capture matrix `matrixname' = `matrixexpression'
	if _rc mata: _error("Expression is no matrix")
	capture mata: _rnms = st_matrixrowstripe("`matrixname'")[`rowselect', .]
	if  _rc mata _error("Option rowselect is not proper or matrix is empty")
	capture mata: _cnms = st_matrixcolstripe("`matrixname'")[`columnselect', .]
	if  _rc mata _error("Option columnselect is not proper")
	mata: st_matrix("matslct", st_matrix("`matrixname'")[`rowselect', `columnselect'])
	mata: st_matrixrowstripe("matslct", _rnms)
	mata: st_matrixcolstripe("matslct", _cnms)
	if "`transpose'" != "" matrix matslct = matslct'
	if "`name'" != "" matrix `name' = matslct
	mata mata drop _* 

	*** matprint ***************************************************************
	matprint matslct `using',	`style' `decimals' `title' `top' `undertop' ///
    `bottom' `replace' `eqstrip' `zero' `toxl' `todocx'
	****************************************************************************
	return matrix matslct = matslct
end
