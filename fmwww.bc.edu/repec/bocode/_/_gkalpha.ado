*! version 1.2.0 11jul2014 Daniel Klein

pr _gkalpha
	vers 11.2
	
	gettoken type 0 : 0
	gettoken varn 0 : 0
	gettoken eqs 0 : 0
	
	syntax varlist [if] [in] ///
	[, SCale(passthru) TRANSPOSE XPOSE BY(varlist) ]
	
	if (c(stata_version) < 12.1) {
		m : st_local("EGEN_SVarname", st_global("EGEN_SVarname"))
		loc varlist : list varlist - EGEN_SVarname
	}
	
	marksample touse ,nov
	
	qui {
		tempvar lvls
		bys `touse' `by' : g long `lvls' = 1 if (_n == 1) & `touse'
		replace `lvls' = sum(`lvls')
		su `lvls' ,mean
		loc max = r(max)
		
		g `type' `varn' = .
		forv j = 1/`max' {
			kalpha `varlist' if (`lvls' == `j') ///
			,`scale' `transpose' `xpose'
			replace `varn' = r(kalpha) if (`lvls' == `j')
		}
	}
end
e

1.2.0	11jul2014	no bootstrap options allowed
1.1.0	07jun2014	allow string variables
1.0.0	05jun2014	initial version
