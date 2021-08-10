* rollreg_X2.do    09sep2004 CFBaum
* Program illustrating use of rollreg on panels
webuse invest2, clear
tsset company time
rollreg market L(0/1).invest time, move(8) stub(mktM)
local dv `r(depvar)'
local rl `r(reglist)'
local stub `r(stub)'
local wantcoef invest
local m "`r(rolloption)'(`r(rollobs)')"
forv i=1/4 {
	qui reg `dv' `rl' if company==`i'
	local cinv = _b[`wantcoef']
	tsline `stub'_`wantcoef' if company==`i' & `stub'_`wantcoef'<., ///
	ti("company `i'") yli(`cinv') yti("moving beta") ///
	name(comp`i',replace) nodraw
	local all "`all' comp`i' "
	}
graph combine `all', ti("`m' coefficient of `dv' on `wantcoef'") ///
	ysize(4) xsize(4) col(2) ///
	t1("Full-sample coefficient displayed") saving("`wantcoef'.gph",replace)
