*! version 1.0.1   November 2, 2007 Scott Merryman    
*! Based on on -betafit- by Cox, Jenkins, and Buis

program gevfit_lf
	version 10.0
	args lnf scale shape loc
	qui replace `lnf' = ///
	 -ln(`scale') - (1/`shape' +1)*ln(1 + `shape'*(($S_MLy  - `loc ')/`scale')) /// 
	 -exp((-1/`shape')*ln( (1 + `shape'*(($S_MLy  - `loc')/`scale'))))

end
