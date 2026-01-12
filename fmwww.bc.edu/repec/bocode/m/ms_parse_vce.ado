*! version 2.50.0 09jan2026
program ms_parse_vce, sclass
	sreturn clear
	syntax, [vce(string) weighttype(string)]
	loc 0 `vce'
	* need -anything- instead of -namelist- because clusters can be x#y
	syntax 	[anything(id="VCE type")] , [*]

	gettoken vcetype vce_arg : anything
	loc clustervars
	loc dkraay_lags

	* vcetype abbreviations:
	if (substr("`vcetype'",1,3)=="ols") loc vcetype unadjusted
	if (substr("`vcetype'",1,2)=="un") loc vcetype unadjusted
	if (substr("`vcetype'",1,1)=="r") loc vcetype robust
	if (substr("`vcetype'",1,2)=="cl") loc vcetype cluster
	if (substr("`vcetype'",1,2)=="dk") loc vcetype dkraay
	if ("`vcetype'"=="conventional") loc vcetype unadjusted
	// Conventional is the name given in e.g. xtreg

	* Handle arguments based on vcetype
	if ("`vcetype'" == "cluster") {
		loc clustervars `vce_arg'
	}
	else if ("`vcetype'" == "dkraay") {
		* vce_arg should be the bandwidth (= lags + 1), or empty for default
		* This matches ivreg2/ivreghdfe convention
		if ("`vce_arg'" != "") {
			cap confirm integer number `vce_arg'
			_assert !_rc, msg("vce(dkraay #): # must be a positive integer (bandwidth = lags + 1)")
			_assert `vce_arg' >= 1, msg("vce(dkraay #): # must be >= 1 (bandwidth = lags + 1)")
			loc dkraay_lags `vce_arg'
		}
	}

	* Expand variable abbreviations for cluster variables
	if ("`clustervars'" != "") {
		ms_fvunab clustervars : `clustervars', stringok
		loc clustervars : subinstr loc clustervars "i." "", all
		_assert !strpos("`clustervars'", "."), msg("unexpected dot in clustervars: `clustervars'")

		unopvarlist `clustervars'
		loc base_clustervars `r(varlist)'
	}

	* Implicit defaults
	if ("`vcetype'"=="" & "`weighttype'"=="pweight") loc vcetype robust
	if ("`vcetype'"=="") loc vcetype unadjusted

	* Sanity checks on vcetype
	_assert inlist("`vcetype'", "unadjusted", "robust", "cluster", "dkraay"), ///
		msg("vcetype '`vcetype'' not allowed")

	_assert !("`vcetype'"=="unadjusted" & "`weighttype'"=="pweight"), ///
		msg("pweights do not work with vce(unadjusted), use a different vce()")
	* Recall that [pw] = [aw] + _robust
	* http://www.stata.com/statalist/archive/2007-04/msg00282.html
	
	* Also see: http://www.stata.com/statalist/archive/2004-11/msg00275.html
	* "aweights are for cell means data, i.e. data which have been collapsed
	* through averaging, and pweights are for sampling weights"

	* Cluster vars
	loc num_clusters : word count `clustervars'
	_assert inlist( (`num_clusters'>0) + ("`vcetype'"=="cluster") , 0 , 2), msg("Can't specify cluster without clustervars (and viceversa)") // XOR

	_assert "`options'" == "", msg("VCE options not supported: `options'")

	* Convert i.turn#i.trunk into turnk#trunk (so we can generate the new variable with the combination of both)


	sreturn loc vcetype `vcetype'
	sreturn loc num_clusters `num_clusters'
	sreturn loc clustervars `clustervars'
	sreturn loc base_clustervars `base_clustervars'
	sreturn loc dkraay_lags `dkraay_lags'
	sreturn loc vceextra `options'
end
