*! ardldml_p 1.0.1  24aug2026
*! predict after ardldml -- DML-Bounds
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! https://github.com/merwanroudane

program define ardldml_p
	version 14.0

	if ("`e(cmd)'" != "ardldml") {
		di as error "last estimates not found; {bf:ardldml} must be run first"
		exit 301
	}

	ardldml_mata

	syntax newvarname [if] [in] , [ XB Residuals EC ]

	local nopt : word count `xb' `residuals' `ec'
	if (`nopt' > 1) {
		di as error "only one statistic may be requested"
		exit 198
	}
	if (`nopt' == 0) local xb "xb"

	marksample touse, novarlist
	qui replace `touse' = 0 if !e(sample)

	tempvar ry rzy rzd
	qui gen double `ry'  = .
	qui gen double `rzy' = .
	qui gen double `rzd' = .

	mata: ardldml_predict("`ry'", "`rzy'", "`rzd'", "`touse'")

	// read the coefficients positionally: the column names carry a "L."
	// prefix that would be parsed as a time-series operator inside _b[].
	tempname bb
	matrix `bb' = e(b)
	local b1 = `bb'[1,1]
	local b2 = `bb'[1,2]

	if ("`xb'" != "") {
		qui gen `typlist' `varlist' = `b1'*`rzy' + `b2'*`rzd' if `touse'
		label var `varlist' "Fitted value from the orthogonalised level regression"
	}
	else if ("`residuals'" != "") {
		qui gen `typlist' `varlist' = `ry' - `b1'*`rzy' - `b2'*`rzd' if `touse'
		label var `varlist' "Residual from the orthogonalised level regression"
	}
	else {
		// the residualised equilibrium error: L.y - theta * L.d, both
		// taken after partialling the controls out
		local th = e(theta)
		qui gen `typlist' `varlist' = `rzy' - `th'*`rzd' if `touse'
		label var `varlist' "Residualised equilibrium error (L.y - theta*L.x, orthogonalised)"
	}
end
