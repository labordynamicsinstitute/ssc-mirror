*! v4 29 Nov 2023
//this program assigns observations to classing by calculating the maximum a posteriori probabilities 
pro def cwmglm_predict
syntax newvarname (min=1 max=1) [if] [in] , [Map Posterior]
version 16
tempvar touse
mark `touse' 
markout `touse'
if ("`posterior'`map'"=="") local posterior posterior
if ("`posterior'"!="" & "`map'"!="") {
	di as error "choose either {bf:posterior} or {bf:map}"
	exit 144
}
if ("`posterior'"!="") {
	_stubstar2names `varlist'*, nvars(`e(k)')
	local varlist `s(varlist)'
	foreach v of local varlist {
	quie 	gen double `v'=.
	}
	di as text  "(posterior probabilities)"
	}
else {
	quie gen byte `varlist'=.
	di as text "(maximum posterior probability group allocation)"
	}
 mata: _cwmglm_predict("`touse'", "`varlist'", "`map'`posterior'") 


end
