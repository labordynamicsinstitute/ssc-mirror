* panelauto_X.do    24jun2004 CFBaum
* Program illustrating use of panelauto features to generate
* table of per-unit regression results
webuse grunfeld, clear
mat def comp_stat = J(10,5,0)
qui forvalues i=1/10 {
		reg invest L.invest mvalue time if company==`i'
		mat comp_stat[`i',1] = e(r2)
		archlm2
		mat comp_stat[`i',2] = r(arch)
		mat comp_stat[`i',3] = r(p)
		bgodfrey2, lag(2)
		mat comp_stat[`i',4] = r(chi2)
		mat comp_stat[`i',5] = r(p)
		local rn "`rn' comp_`i'"
 	}
mat rownames comp_stat = `rn'
mat colnames comp_stat = r^2 ARCH p-value BG(2) p-value
mat list comp_stat, format(%9.3f) ///
 ti("Regression statistics for Grunfeld data") noheader
