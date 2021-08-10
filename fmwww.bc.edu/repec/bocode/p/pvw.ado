*pvw implements predictive value weighting, as proposed by Lyles and Lin, Stats in Med, 2010; 29: 2297-2309
*version 1.0
*Jonathan Bartlett
*jwb133@googlemail.com

capture program drop pvw
program define pvw, eclass
version 11.0
syntax varlist(fv) [if/], casesens(real) casespec(real) contsens(real) contspec(real) misclass(varname) outcome(varname) [othercov(varlist fv)] [cohort] [reps(integer 200)] [seed(integer -1)]

*first run naive regression
di as text "Naive regression ignoring misclassification"

logistic `outcome' `misclass' `othercov'
di ""
di as text "Running predictive value weighting, with bootstrap for variance estimation"

if "`seed'"=="-1" {
	local seedopt
}
else {
	local seedopt seed(`seed')
}

if "`cohort'"!="" {
	di "Unstratified sampling (cohort study)"
	bootstrap, eform reps(`reps')`seedopt': pvwcalc `varlist', casesens(`casesens') casespec(`casespec') contsens(`contsens') contspec(`contspec') z(`misclass') y(`outcome') c(`othercov')
}
else {
	di "Stratified sampling (case control study)"
	bootstrap, eform strata(`outcome') reps(`reps') `seedopt': pvwcalc `varlist', casesens(`casesens') casespec(`casespec') contsens(`contsens') contspec(`contspec') z(`misclass') y(`outcome') c(`othercov')
}

end

