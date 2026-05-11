*! version 1.0.0 Percy Soto-Becerra 11may2026

program define qresid, rclass
	version 15.0
	syntax newvarname(max=1) [if] [in] [, SEED(string) UVAR(varname) ///
		SAVEV(name) SAVEFLO(name) SAVEFHI(name) SAVEU(name) FAMILY(string) ///
		TYPE(string) DISPersion(string)]

	if "`e(cmd)'" == "" {
		display as err "qresid requires active estimation results"
		exit 301
	}

	local cmd "`e(cmd)'"
	local depvar "`e(depvar)'"
	local rtype = lower(trim("`type'"))
	if "`rtype'" == "" {
		local rtype "quantile"
	}
	if !inlist("`rtype'", "quantile", "studentized", "adjusted", "standardized") {
		display as err "type() must be quantile, studentized, or adjusted"
		exit 198
	}
	if "`rtype'" == "standardized" {
		display as err "qresid's default type(quantile) is already on the standard normal quantile scale; use type(studentized) only where validated"
		exit 198
	}
	local dispersion_source "STATA_DEFAULT"
	tempname dispersion_override
	if "`dispersion'" != "" {
		capture scalar `dispersion_override' = real("`dispersion'")
		if _rc | missing(`dispersion_override') | `dispersion_override' <= 0 {
			display as err "dispersion() must be a positive numeric value"
			exit 198
		}
		local dispersion_source "USER_FIXED"
	}
	if "`depvar'" == "" {
		display as err "qresid could not identify the dependent variable"
		exit 498
	}
	local depvar : word 1 of `depvar'
	local wtype "`e(wtype)'"

	marksample touse, novarlist
	tempvar esample
	capture generate byte `esample' = e(sample)
	if _rc {
		display as err "qresid requires estimation results with e(sample)"
		exit 498
	}
	quietly replace `touse' = `touse' & `esample'
	quietly count if `touse'
	local N = r(N)
	if `N' == 0 {
		display as err "qresid has no observations in the requested estimation sample"
		exit 2000
	}

	foreach out in `varlist' `savev' `saveflo' `savefhi' `saveu' {
		if "`out'" != "" {
			capture confirm name `out'
			if _rc {
				display as err "`out' is not a valid variable name"
				exit 198
			}
			capture confirm variable `out'
			if _rc == 0 {
				display as err "variable `out' already exists"
				exit 110
			}
		}
	}

	local fam ""
	local binom_m ""
	if "`cmd'" == "regress" {
		local fam "gaussian"
	}
	else if "`cmd'" == "poisson" {
		local fam "poisson"
	}
	else if "`cmd'" == "logit" | "`cmd'" == "logistic" {
		local fam "bernoulli"
	}
	else if "`cmd'" == "glm" {
		local vf = lower("`e(varfunct)'")
		if "`vf'" == "gaussian" {
			local fam "gaussian"
		}
		else if "`vf'" == "poisson" {
			local fam "poisson"
		}
		else if "`vf'" == "gamma" {
			local fam "gamma"
		}
		else if "`vf'" == "inverse gaussian" | "`vf'" == "igaussian" {
			local fam "igaussian"
		}
		else if "`vf'" == "neg. binomial" {
			local vfraw "`e(varfuncf)'"
			if strpos(lower("`e(cmdline)'"), "nbinomial ml") {
				display as err "glm, family(nbinomial ml) is not currently supported because Stata does not expose the estimated alpha with full precision in e(); use nbreg or glm, family(nbinomial #)"
				exit 198
			}
			if regexm("`vfraw'", "u\+\(([0-9.+-eE]+)\)u\^2") {
				local glm_nb_alpha = real(regexs(1))
			}
			else {
				display as err "glm nbinomial support requires fixed positive family(nbinomial #)"
				exit 198
			}
			if missing(`glm_nb_alpha') | `glm_nb_alpha' <= 0 {
				display as err "glm nbinomial support requires fixed positive family(nbinomial #)"
				exit 198
			}
			local fam "glm_nb_fixed"
		}
		else if "`vf'" == "bernoulli" | "`vf'" == "binomial" {
			if "`e(m)'" != "" & "`e(m)'" != "1" {
				local fam "grouped_binomial"
				local binom_m "`e(m)'"
			}
			else {
				local fam "bernoulli"
			}
		}
	}
	else if "`cmd'" == "binreg" {
		local vf = lower("`e(varfunct)'")
		if ("`vf'" == "bernoulli" | "`vf'" == "binomial") & ("`e(m)'" == "" | "`e(m)'" == "1") {
			local fam "bernoulli"
		}
		else if ("`vf'" == "bernoulli" | "`vf'" == "binomial") & "`e(m)'" != "" {
			local fam "grouped_binomial"
			local binom_m "`e(m)'"
		}
		else {
			display as err "grouped binomial support requires the documented binomial trials gate"
			exit 198
		}
	}
	else if "`cmd'" == "nbreg" {
		if "`e(dispers)'" == "mean" {
			local fam "nbreg_mean"
		}
		else if "`e(dispers)'" == "constant" {
			local fam "nbreg_constant"
		}
		else {
			display as err "negative binomial support requires documented dispersion(mean) or dispersion(constant)"
			exit 198
		}
	}
	else if "`cmd'" == "gnbreg" {
		local fam "gnbreg"
	}
	else if "`cmd'" == "zip" {
		local fam "zip"
	}
	else if "`cmd'" == "zinb" {
		local fam "zinb"
	}
	else if "`cmd'" == "tpoisson" | "`cmd'" == "ztp" {
		local fam "trunc_poisson"
	}
	else if "`cmd'" == "tnbreg" | "`cmd'" == "ztnb" {
		local fam "trunc_nbreg"
	}
	else if "`cmd'" == "cpoisson" {
		local fam "cens_poisson"
	}
	else if "`cmd'" == "gpoisson" {
		local fam "genpoisson"
	}
	else if "`cmd'" == "ml" {
		local title_l = lower(strtrim("`e(title)'"))
		local user_l = lower(strtrim("`e(user)'"))
		local bfull : colfullnames e(b)
		if "`user_l'" == "jhpoi_logit_ll" & "`title_l'" == "poisson-logit hurdle regression" {
			if strpos("`bfull'", "logit:") & strpos("`bfull'", "poisson:") {
				local fam "hurdle_poisson"
			}
			else {
				display as err "hplogit support requires the documented Hilbe-Hardin equations logit and poisson"
				exit 198
			}
		}
		else if "`user_l'" == "jhnb_logit_ll" & "`title_l'" == "negative binomial-logit hurdle regression" {
			if strpos("`bfull'", "logit:") & strpos("`bfull'", "negbinomial:") & strpos("`bfull'", "lnalpha:") {
				local fam "hurdle_nb"
			}
			else {
				display as err "hnblogit support requires the documented Hilbe-Hardin equations logit, negbinomial and /lnalpha"
				exit 198
			}
		}
	}

	if "`fam'" == "" {
		display as err "estimation command `cmd' is not supported by qresid"
		exit 198
	}
	if "`rtype'" == "studentized" | "`rtype'" == "adjusted" {
		if !inlist("`cmd'", "regress", "glm") {
			display as err "type(`rtype') is validated only after regress and glm; use type(quantile) for this estimator"
			exit 198
		}
		if !inlist("`fam'", "gaussian", "poisson", "bernoulli", "gamma", "igaussian") {
			display as err "type(`rtype') is available only for unweighted regress and supported glm Gaussian/Poisson/Bernoulli/Gamma/inverse Gaussian specifications"
			exit 198
		}
		if "`wtype'" != "" {
			display as err "type(`rtype') is not yet validated for weighted fits; use type(quantile)"
			exit 198
		}
	}
	if "`dispersion'" != "" & !inlist("`fam'", "gamma", "igaussian") {
		display as err "dispersion() is available only for glm Gamma and inverse Gaussian specifications"
		exit 198
	}

	local weight_status "none"
	if "`wtype'" != "" {
		if "`wtype'" == "fweight" & inlist("`fam'", "gaussian", "poisson", "bernoulli", "grouped_binomial", "gamma", "nbreg_mean", "igaussian") {
			local weight_status "fweight_experimental"
		}
		else if "`wtype'" == "pweight" & ("`fam'" == "gaussian" | "`fam'" == "poisson" | "`fam'" == "bernoulli") {
			local weight_status "pweight_direct_experimental"
		}
		else if "`fam'" == "genpoisson" {
			display as err "gpoisson weight support is not currently available; only unweighted st0279 gpoisson specifications are supported"
			exit 198
		}
		else if "`fam'" == "hurdle_poisson" | "`fam'" == "hurdle_nb" {
			display as err "hurdle count weight support is not currently available; only unweighted documented hplogit/hnblogit specifications are supported"
			exit 198
		}
		else {
			display as err "this weight specification is not currently supported by qresid"
			exit 198
		}
	}

	if "`family'" != "" {
		local requested = lower("`family'")
		if "`requested'" == "normal" {
			local requested "gaussian"
		}
		if "`requested'" == "binomial" {
			local requested "bernoulli"
		}
		if "`requested'" != "`fam'" {
			display as err "family(`family') contradicts inferred family `fam'"
			exit 198
		}
	}

	if "`seed'" != "" {
		capture confirm integer number `seed'
		if _rc {
			display as err "seed() must be an integer"
			exit 198
		}
		set seed `seed'
	}
	if "`uvar'" != "" {
		capture confirm numeric variable `uvar'
		if _rc {
			display as err "uvar() must be numeric"
			exit 198
		}
	}

	tempvar y mu flo fhi v u uc resid missflag m p
	quietly generate double `y' = `depvar' if `touse'
	quietly generate double `flo' = .
	quietly generate double `fhi' = .
	quietly generate double `v' = .
	quietly generate double `u' = .
	quietly generate double `uc' = .
	quietly generate double `resid' = .
	quietly generate double `p' = .

	if "`fam'" == "gaussian" {
		if "`cmd'" == "regress" {
			tempvar xb
			quietly predict double `xb' if `touse', xb
			quietly replace `resid' = (`y' - `xb') / e(rmse) if `touse'
		}
		else {
			quietly predict double `mu' if `touse', mu
			quietly replace `resid' = (`y' - `mu') / sqrt(e(dispers)) if `touse'
		}
		quietly replace `fhi' = normal(`resid') if `touse'
		quietly replace `flo' = `fhi' if `touse'
		quietly replace `u' = `fhi' if `touse'
	}
	else if "`fam'" == "poisson" {
		if "`cmd'" == "poisson" {
			quietly predict double `mu' if `touse', n
		}
		else {
			quietly predict double `mu' if `touse', mu
		}
		quietly count if `touse' & (`y' < 0 | `y' != floor(`y'))
		if r(N) {
			display as err "Poisson outcomes must be nonnegative integers"
			exit 459
		}
		quietly replace `flo' = cond(`y' > 0, poisson(`mu', `y' - 1), 0) if `touse'
		quietly replace `fhi' = poisson(`mu', `y') if `touse'
	}
	else if "`fam'" == "bernoulli" {
		if "`cmd'" == "glm" | "`cmd'" == "binreg" {
			quietly predict double `mu' if `touse', mu
		}
		else {
			quietly predict double `mu' if `touse', pr
		}
		quietly count if `touse' & !inlist(`y', 0, 1)
		if r(N) {
			display as err "Bernoulli outcomes must be 0 or 1"
			exit 459
		}
		quietly count if `touse' & (`mu' < 0 | `mu' > 1 | missing(`mu'))
		if r(N) {
			display as err "Bernoulli fitted probabilities must be in [0,1]"
			exit 459
		}
		quietly replace `flo' = cond(`y' > 0, binomial(1, `y' - 1, `mu'), 0) if `touse'
		quietly replace `fhi' = binomial(1, `y', `mu') if `touse'
	}
	else if "`fam'" == "grouped_binomial" {
		quietly predict double `mu' if `touse', mu
		quietly generate double `m' = .
		capture confirm numeric variable `binom_m'
		if _rc == 0 {
			quietly replace `m' = `binom_m' if `touse'
		}
		else {
			capture confirm number `binom_m'
			if _rc {
				display as err "grouped binomial trials could not be extracted from e(m)"
				exit 498
			}
			quietly replace `m' = real("`binom_m'") if `touse'
		}
		quietly replace `p' = `mu' / `m' if `touse'
		quietly count if `touse' & (`m' <= 0 | `m' != floor(`m') | missing(`m'))
		if r(N) {
			display as err "grouped binomial trials must be positive integers"
			exit 459
		}
		quietly count if `touse' & (`y' < 0 | `y' > `m' | `y' != floor(`y') | missing(`y'))
		if r(N) {
			display as err "grouped binomial outcomes must be integers in [0, trials]"
			exit 459
		}
		quietly count if `touse' & (`p' < 0 | `p' > 1 | missing(`p'))
		if r(N) {
			display as err "grouped binomial fitted probabilities must be in [0,1]"
			exit 459
		}
		quietly replace `flo' = cond(`y' > 0, binomial(`m', `y' - 1, `p'), 0) if `touse'
		quietly replace `fhi' = binomial(`m', `y', `p') if `touse'
	}
	else if "`fam'" == "gamma" {
		tempname phi shape
		if "`dispersion'" != "" {
			scalar `phi' = `dispersion_override'
		}
		else {
			capture scalar `phi' = e(dispers)
			if _rc | missing(`phi') {
				capture scalar `phi' = e(phi)
			}
			if _rc | missing(`phi') | `phi' <= 0 {
				display as err "Gamma support requires positive e(dispers)"
				exit 459
			}
		}
		scalar `shape' = 1 / `phi'
		quietly predict double `mu' if `touse', mu
		quietly count if `touse' & (`y' <= 0 | `mu' <= 0 | missing(`y', `mu'))
		if r(N) {
			display as err "Gamma outcomes and fitted means must be positive"
			exit 459
		}
		quietly replace `fhi' = gammap(`shape', `y' / (`mu' * `phi')) if `touse'
		quietly replace `flo' = `fhi' if `touse'
		quietly replace `u' = `fhi' if `touse'
	}
	else if "`fam'" == "igaussian" {
		tempname phi lambda
		tempvar igz1 igz2 iglogterm igterm
		if "`dispersion'" != "" {
			scalar `phi' = `dispersion_override'
		}
		else {
			capture scalar `phi' = e(dispers)
			if _rc | missing(`phi') {
				capture scalar `phi' = e(phi)
			}
			if _rc | missing(`phi') | `phi' <= 0 {
				display as err "inverse Gaussian support requires positive e(dispers)"
				exit 459
			}
		}
		scalar `lambda' = 1 / `phi'
		quietly predict double `mu' if `touse', mu
		quietly count if `touse' & (`y' <= 0 | `mu' <= 0 | missing(`y', `mu'))
		if r(N) {
			display as err "inverse Gaussian outcomes and fitted means must be positive"
			exit 459
		}
		quietly generate double `igz1' = sqrt(`lambda' / `y') * (`y' / `mu' - 1) if `touse'
		quietly generate double `igz2' = -sqrt(`lambda' / `y') * (`y' / `mu' + 1) if `touse'
		quietly generate double `iglogterm' = 2 * `lambda' / `mu' + lnnormal(`igz2') if `touse'
		quietly generate double `igterm' = cond(`iglogterm' < -745, 0, exp(`iglogterm')) if `touse'
		quietly replace `fhi' = normal(`igz1') + `igterm' if `touse'
		quietly replace `flo' = `fhi' if `touse'
		quietly replace `u' = `fhi' if `touse'
	}
	else if "`fam'" == "nbreg_mean" | "`fam'" == "nbreg_constant" | "`fam'" == "gnbreg" | "`fam'" == "glm_nb_fixed" {
		tempname alpha theta
		if "`fam'" == "nbreg_mean" {
			capture scalar `alpha' = e(alpha)
			if _rc | missing(`alpha') | `alpha' <= 0 {
				display as err "NB support requires positive e(alpha)"
				exit 459
			}
			scalar `theta' = 1 / `alpha'
			quietly predict double `mu' if `touse', n
			quietly replace `p' = `theta' / (`theta' + `mu') if `touse'
			quietly replace `flo' = cond(`y' > 0, nbinomial(`theta', `y' - 1, `p'), 0) if `touse'
			quietly replace `fhi' = nbinomial(`theta', `y', `p') if `touse'
		}
		else if "`fam'" == "nbreg_constant" {
			capture scalar `alpha' = exp(_b[/lndelta])
			if _rc | missing(`alpha') | `alpha' <= 0 {
				display as err "NB dispersion(constant) support requires positive /lndelta"
				exit 459
			}
			quietly predict double `mu' if `touse', n
			quietly generate double `m' = .
			quietly replace `m' = `mu' / `alpha' if `touse'
			quietly replace `p' = 1 / (1 + `alpha') if `touse'
			quietly replace `flo' = cond(`y' > 0, nbinomial(`m', `y' - 1, `p'), 0) if `touse'
			quietly replace `fhi' = nbinomial(`m', `y', `p') if `touse'
		}
		else if "`fam'" == "gnbreg" {
			quietly predict double `mu' if `touse', n
			quietly predict double `m' if `touse', alpha
			quietly replace `m' = 1 / `m' if `touse'
			quietly replace `p' = `m' / (`m' + `mu') if `touse'
			quietly replace `flo' = cond(`y' > 0, nbinomial(`m', `y' - 1, `p'), 0) if `touse'
			quietly replace `fhi' = nbinomial(`m', `y', `p') if `touse'
		}
		else if "`fam'" == "glm_nb_fixed" {
			scalar `alpha' = `glm_nb_alpha'
			scalar `theta' = 1 / `alpha'
			quietly predict double `mu' if `touse', mu
			quietly replace `p' = `theta' / (`theta' + `mu') if `touse'
			quietly replace `flo' = cond(`y' > 0, nbinomial(`theta', `y' - 1, `p'), 0) if `touse'
			quietly replace `fhi' = nbinomial(`theta', `y', `p') if `touse'
		}
		quietly count if `touse' & (`y' < 0 | `y' != floor(`y') | missing(`y'))
		if r(N) {
			display as err "NB outcomes must be nonnegative integers"
			exit 459
		}
		quietly count if `touse' & (`mu' <= 0 | missing(`mu'))
		if r(N) {
			display as err "NB fitted means must be positive"
			exit 459
		}
	}
	else if "`fam'" == "zip" | "`fam'" == "zinb" {
		tempvar xb_count pi
		tempname alpha theta
		quietly _predict double `xb_count' if `touse', xb eq(#1)
		quietly generate double `mu' = exp(`xb_count') if `touse'
		quietly predict double `pi' if `touse', pr
		quietly count if `touse' & (`y' < 0 | `y' != floor(`y') | missing(`y'))
		if r(N) {
			display as err "zero-inflated count outcomes must be nonnegative integers"
			exit 459
		}
		quietly count if `touse' & (`mu' <= 0 | `pi' < 0 | `pi' > 1 | missing(`mu', `pi'))
		if r(N) {
			display as err "zero-inflated count parameters must be in valid ranges"
			exit 459
		}
		if "`fam'" == "zip" {
			quietly replace `flo' = cond(`y' > 0, `pi' + (1 - `pi') * poisson(`mu', `y' - 1), 0) if `touse'
			quietly replace `fhi' = `pi' + (1 - `pi') * poisson(`mu', `y') if `touse'
		}
		else {
			capture scalar `alpha' = e(alpha)
			if _rc | missing(`alpha') {
				capture scalar `alpha' = exp(_b[/lnalpha])
			}
			if _rc | missing(`alpha') | `alpha' <= 0 {
				display as err "ZINB support requires positive e(alpha)"
				exit 459
			}
			scalar `theta' = 1 / `alpha'
			quietly replace `p' = `theta' / (`theta' + `mu') if `touse'
			quietly replace `flo' = cond(`y' > 0, `pi' + (1 - `pi') * nbinomial(`theta', `y' - 1, `p'), 0) if `touse'
			quietly replace `fhi' = `pi' + (1 - `pi') * nbinomial(`theta', `y', `p') if `touse'
		}
	}
	else if "`fam'" == "trunc_poisson" {
		tempvar llv ulv baseF topF denom rawflo rawfhi
		local llopt "`e(llopt)'"
		local ulopt "`e(ulopt)'"
		quietly predict double `mu' if `touse', n
		quietly generate double `llv' = 0 if `touse'
		if "`cmd'" == "tpoisson" & "`llopt'" != "" {
			capture confirm numeric variable `llopt'
			if _rc == 0 {
				quietly replace `llv' = `llopt' if `touse'
			}
			else {
				capture confirm number `llopt'
				if _rc {
					display as err "tpoisson lower truncation point could not be extracted"
					exit 498
				}
				quietly replace `llv' = real("`llopt'") if `touse'
			}
		}
		quietly generate double `ulv' = . if `touse'
		if "`cmd'" == "tpoisson" & "`ulopt'" != "" {
			capture confirm numeric variable `ulopt'
			if _rc == 0 {
				quietly replace `ulv' = `ulopt' if `touse'
			}
			else {
				capture confirm number `ulopt'
				if _rc {
					display as err "tpoisson upper truncation point could not be extracted"
					exit 498
				}
				quietly replace `ulv' = real("`ulopt'") if `touse'
			}
		}
		quietly count if `touse' & (`y' != floor(`y') | `llv' != floor(`llv') | (!missing(`ulv') & `ulv' != floor(`ulv')) | `y' <= `llv' | (!missing(`ulv') & `y' >= `ulv') | `mu' <= 0 | missing(`y', `mu', `llv'))
		if r(N) {
			display as err "truncated Poisson outcomes must be integers inside the open truncation interval"
			exit 459
		}
		quietly generate double `baseF' = poisson(`mu', `llv') if `touse'
		quietly generate double `topF' = cond(missing(`ulv'), 1, poisson(`mu', `ulv' - 1)) if `touse'
		quietly generate double `denom' = `topF' - `baseF' if `touse'
		quietly generate double `rawflo' = poisson(`mu', `y' - 1) if `touse'
		quietly generate double `rawfhi' = poisson(`mu', `y') if `touse'
		quietly replace `flo' = (`rawflo' - `baseF') / `denom' if `touse'
		quietly replace `fhi' = (`rawfhi' - `baseF') / `denom' if `touse'
	}
	else if "`fam'" == "trunc_nbreg" {
		tempvar llv baseF denom rawflo rawfhi theta_i
		tempname alpha theta
		local llopt "`e(llopt)'"
		quietly predict double `mu' if `touse', n
		quietly generate double `llv' = 0 if `touse'
		if "`cmd'" == "tnbreg" & "`llopt'" != "" {
			capture confirm numeric variable `llopt'
			if _rc == 0 {
				quietly replace `llv' = `llopt' if `touse'
			}
			else {
				capture confirm number `llopt'
				if _rc {
					display as err "tnbreg lower truncation point could not be extracted"
					exit 498
				}
				quietly replace `llv' = real("`llopt'") if `touse'
			}
		}
		if "`e(dispers)'" == "mean" | "`e(dispers)'" == "" {
			capture scalar `alpha' = e(alpha)
			if _rc | missing(`alpha') | `alpha' <= 0 {
				display as err "truncated NB support requires positive e(alpha)"
				exit 459
			}
			scalar `theta' = 1 / `alpha'
			quietly replace `p' = `theta' / (`theta' + `mu') if `touse'
			quietly generate double `baseF' = nbinomial(`theta', `llv', `p') if `touse'
			quietly generate double `rawflo' = nbinomial(`theta', `y' - 1, `p') if `touse'
			quietly generate double `rawfhi' = nbinomial(`theta', `y', `p') if `touse'
		}
		else if "`e(dispers)'" == "constant" {
			capture scalar `alpha' = exp(_b[/lndelta])
			if _rc | missing(`alpha') | `alpha' <= 0 {
				display as err "truncated NB dispersion(constant) support requires positive /lndelta"
				exit 459
			}
			quietly generate double `theta_i' = `mu' / `alpha' if `touse'
			quietly replace `p' = 1 / (1 + `alpha') if `touse'
			quietly generate double `baseF' = nbinomial(`theta_i', `llv', `p') if `touse'
			quietly generate double `rawflo' = nbinomial(`theta_i', `y' - 1, `p') if `touse'
			quietly generate double `rawfhi' = nbinomial(`theta_i', `y', `p') if `touse'
		}
		else {
			display as err "truncated NB support requires documented dispersion(mean) or dispersion(constant)"
			exit 198
		}
		quietly count if `touse' & (`y' != floor(`y') | `llv' != floor(`llv') | `y' <= `llv' | `mu' <= 0 | missing(`y', `mu', `llv'))
		if r(N) {
			display as err "truncated NB outcomes must be integers above the truncation point"
			exit 459
		}
		quietly generate double `denom' = 1 - `baseF' if `touse'
		quietly replace `flo' = (`rawflo' - `baseF') / `denom' if `touse'
		quietly replace `fhi' = (`rawfhi' - `baseF') / `denom' if `touse'
	}
	else if "`fam'" == "cens_poisson" {
		tempvar llv ulv left right
		local llopt "`e(llopt)'"
		local ulopt "`e(ulopt)'"
		quietly predict double `mu' if `touse', n
		quietly generate double `llv' = . if `touse'
		quietly generate double `ulv' = . if `touse'
		if "`llopt'" != "" {
			capture confirm numeric variable `llopt'
			if _rc == 0 {
				quietly replace `llv' = `llopt' if `touse'
			}
			else {
				capture confirm number `llopt'
				if _rc {
					display as err "cpoisson lower censoring point could not be extracted"
					exit 498
				}
				quietly replace `llv' = real("`llopt'") if `touse'
			}
		}
		if "`ulopt'" != "" {
			capture confirm numeric variable `ulopt'
			if _rc == 0 {
				quietly replace `ulv' = `ulopt' if `touse'
			}
			else {
				capture confirm number `ulopt'
				if _rc {
					display as err "cpoisson upper censoring point could not be extracted"
					exit 498
				}
				quietly replace `ulv' = real("`ulopt'") if `touse'
			}
		}
		if "`llopt'" == "" & "`ulopt'" == "" {
			display as err "cpoisson support requires at least one censoring point"
			exit 198
		}
		quietly count if `touse' & (`y' != floor(`y') | `mu' <= 0 | (!missing(`llv') & `llv' != floor(`llv')) | (!missing(`ulv') & `ulv' != floor(`ulv')) | missing(`y', `mu'))
		if r(N) {
			display as err "censored Poisson outcomes and censoring limits must be integer-valued with positive fitted means"
			exit 459
		}
		quietly generate byte `left' = !missing(`llv') & `y' <= `llv' if `touse'
		quietly generate byte `right' = !missing(`ulv') & `y' >= `ulv' if `touse'
		quietly replace `flo' = cond(`y' > 0, poisson(`mu', `y' - 1), 0) if `touse'
		quietly replace `fhi' = poisson(`mu', `y') if `touse'
		quietly replace `flo' = 0 if `touse' & `left'
		quietly replace `fhi' = poisson(`mu', `llv') if `touse' & `left'
		quietly replace `flo' = poisson(`mu', `ulv' - 1) if `touse' & `right'
		quietly replace `fhi' = 1 if `touse' & `right'
	}
	else if "`fam'" == "genpoisson" {
		tempname delta onemdelta
		tempvar gp_sumlo gp_sumhi gp_term gp_den
		capture scalar `delta' = e(delta)
		if _rc | missing(`delta') {
			capture scalar `delta' = e(dispersion)
		}
		if _rc | missing(`delta') | `delta' <= -1 | `delta' >= 1 {
			display as err "gpoisson support requires st0279 e(delta) in (-1,1)"
			exit 459
		}
		scalar `onemdelta' = 1 - `delta'
		quietly predict double `mu' if `touse', n
		quietly count if `touse' & (`y' < 0 | `y' != floor(`y') | missing(`y'))
		if r(N) {
			display as err "generalized Poisson outcomes must be nonnegative integers"
			exit 459
		}
		quietly count if `touse' & (`mu' <= 0 | missing(`mu') | `onemdelta' <= 0)
		if r(N) {
			display as err "generalized Poisson fitted means and dispersion must be valid"
			exit 459
		}
		quietly generate double `gp_den' = `onemdelta' * `mu' + `delta' * `y' if `touse'
		quietly count if `touse' & (`gp_den' <= 0 | missing(`gp_den'))
		if r(N) {
			display as err "generalized Poisson support requires positive theta + delta*y for observed outcomes"
			exit 459
		}
		quietly generate double `gp_sumlo' = 0 if `touse'
		quietly generate double `gp_sumhi' = 0 if `touse'
		quietly generate double `gp_term' = . if `touse'
		quietly summarize `y' if `touse', meanonly
		local gp_ymax = floor(r(max))
		forvalues gp_k = 0/`gp_ymax' {
			quietly replace `gp_den' = `onemdelta' * `mu' + `delta' * `gp_k' if `touse'
			quietly replace `gp_term' = cond(`gp_den' > 0, exp(-`gp_den' + (`gp_k' - 1) * ln(`gp_den') + ln(`mu') + ln(`onemdelta') - lngamma(`gp_k' + 1)), 0) if `touse'
			quietly replace `gp_sumhi' = `gp_sumhi' + `gp_term' if `touse' & `y' >= `gp_k'
			quietly replace `gp_sumlo' = `gp_sumlo' + `gp_term' if `touse' & `y' > `gp_k'
		}
		quietly replace `flo' = `gp_sumlo' if `touse'
		quietly replace `fhi' = `gp_sumhi' if `touse'
	}
	else if "`fam'" == "hurdle_poisson" | "`fam'" == "hurdle_nb" {
		tempvar xb_zero xb_count p0 denom rawflo rawfhi fpluslo fplushi nb_mu_eval nb_size nb_prob
		tempname alpha
		quietly predict double `xb_zero' if `touse', xb equation(logit)
		if "`fam'" == "hurdle_poisson" {
			quietly predict double `xb_count' if `touse', xb equation(poisson)
			quietly generate double `mu' = exp(`xb_count') if `touse'
		}
		else {
			quietly predict double `xb_count' if `touse', xb equation(negbinomial)
			capture scalar `alpha' = exp(_b[/lnalpha])
			if _rc | missing(`alpha') | `alpha' <= 0 {
				display as err "hnblogit support requires positive /lnalpha ancillary parameter"
				exit 459
			}
			quietly generate double `mu' = exp(`xb_count') if `touse'
			quietly generate double `nb_mu_eval' = `mu' * `alpha' if `touse'
			quietly generate double `nb_size' = 1 / `alpha' if `touse'
			quietly generate double `nb_prob' = 1 / (1 + `nb_mu_eval') if `touse'
		}
		quietly generate double `p0' = invlogit(`xb_zero') if `touse'
		quietly count if `touse' & (`y' < 0 | `y' != floor(`y') | missing(`y') | `mu' <= 0 | missing(`mu') | `p0' < 0 | `p0' > 1 | missing(`p0'))
		if r(N) {
			display as err "hurdle count outcomes must be nonnegative integers with valid fitted zero and count components"
			exit 459
		}
		if "`fam'" == "hurdle_poisson" {
			quietly generate double `denom' = 1 - exp(-`mu') if `touse'
			quietly generate double `rawflo' = cond(`y' > 0, poisson(`mu', `y' - 1), 0) if `touse'
			quietly generate double `rawfhi' = poisson(`mu', `y') if `touse'
			quietly generate double `fpluslo' = cond(`y' <= 1, 0, (`rawflo' - exp(-`mu')) / `denom') if `touse'
			quietly generate double `fplushi' = cond(`y' == 0, 0, (`rawfhi' - exp(-`mu')) / `denom') if `touse'
		}
		else {
			quietly count if `touse' & (`nb_prob' <= 0 | `nb_prob' >= 1 | missing(`nb_prob', `nb_size', `nb_mu_eval'))
			if r(N) {
				display as err "hnblogit fitted negative-binomial parameters are invalid"
				exit 459
			}
			quietly generate double `denom' = 1 - nbinomial(`nb_size', 0, `nb_prob') if `touse'
			quietly generate double `rawflo' = cond(`y' > 0, nbinomial(`nb_size', `y' - 1, `nb_prob'), 0) if `touse'
			quietly generate double `rawfhi' = nbinomial(`nb_size', `y', `nb_prob') if `touse'
			quietly generate double `fpluslo' = cond(`y' <= 1, 0, (`rawflo' - nbinomial(`nb_size', 0, `nb_prob')) / `denom') if `touse'
			quietly generate double `fplushi' = cond(`y' == 0, 0, (`rawfhi' - nbinomial(`nb_size', 0, `nb_prob')) / `denom') if `touse'
		}
		quietly count if `touse' & (`denom' <= 0 | missing(`denom') | `fpluslo' < -1e-8 | `fplushi' > 1 + 1e-8 | `fplushi' + 1e-8 < `fpluslo')
		if r(N) {
			display as err "hurdle count positive-truncation CDF endpoints are invalid"
			exit 459
		}
		quietly replace `flo' = cond(`y' == 0, 0, `p0' + (1 - `p0') * `fpluslo') if `touse'
		quietly replace `fhi' = cond(`y' == 0, `p0', `p0' + (1 - `p0') * `fplushi') if `touse'
	}

	if "`fam'" == "poisson" | "`fam'" == "bernoulli" | "`fam'" == "grouped_binomial" | "`fam'" == "nbreg_mean" | "`fam'" == "nbreg_constant" | "`fam'" == "gnbreg" | "`fam'" == "glm_nb_fixed" | "`fam'" == "zip" | "`fam'" == "zinb" | "`fam'" == "trunc_poisson" | "`fam'" == "trunc_nbreg" | "`fam'" == "cens_poisson" | "`fam'" == "genpoisson" | "`fam'" == "hurdle_poisson" | "`fam'" == "hurdle_nb" {
		if "`uvar'" != "" {
			quietly count if `touse' & missing(`uvar')
			if r(N) {
				display as err "uvar() contains missing values in the estimation sample"
				exit 459
			}
			quietly count if `touse' & (`uvar' < 0 | `uvar' > 1)
			if r(N) {
				display as err "uvar() must be in [0,1]"
				exit 459
			}
			quietly replace `v' = `uvar' if `touse'
		}
		else {
			quietly replace `v' = runiform() if `touse'
		}
		quietly replace `u' = `flo' + `v' * (`fhi' - `flo') if `touse'
	}

	quietly count if `touse' & (`flo' < -1e-8 | `fhi' > 1 + 1e-8 | `fhi' + 1e-8 < `flo')
	if r(N) {
		display as err "invalid CDF endpoints"
		exit 459
	}
	quietly replace `flo' = max(0, min(1, `flo')) if `touse'
	quietly replace `fhi' = max(0, min(1, `fhi')) if `touse'
	quietly replace `u' = max(0, min(1, `u')) if `touse'

	quietly count if `touse' & `u' <= 1e-12
	local clipped_low = r(N)
	quietly count if `touse' & `u' >= 1 - 1e-12
	local clipped_high = r(N)
	quietly replace `uc' = min(1 - 1e-12, max(1e-12, `u')) if `touse'
	if "`fam'" != "gaussian" {
		quietly replace `resid' = invnormal(`uc') if `touse'
	}
	if "`rtype'" == "studentized" | "`rtype'" == "adjusted" {
		tempvar qhat
		capture quietly predict double `qhat' if `touse', hat
		if _rc {
			display as err "type(`rtype') requires predict, hat after regress or glm"
			exit 198
		}
		quietly count if `touse' & (missing(`qhat') | `qhat' < -1e-8 | `qhat' >= 1)
		if r(N) {
			display as err "type(`rtype') encountered invalid leverage values"
			exit 459
		}
		quietly replace `qhat' = max(0, `qhat') if `touse' & `qhat' < 0
		quietly replace `resid' = `resid' / sqrt(1 - `qhat') if `touse'
	}

	quietly generate double `varlist' = .
	quietly replace `varlist' = `resid' if `touse'
	if "`rtype'" == "studentized" | "`rtype'" == "adjusted" {
		label variable `varlist' "Adjusted quantile residuals"
	}
	else {
		label variable `varlist' "Quantile residuals"
	}

	if "`saveflo'" != "" {
		quietly generate double `saveflo' = .
		quietly replace `saveflo' = `flo' if `touse'
		label variable `saveflo' "qresid F_low"
	}
	if "`savefhi'" != "" {
		quietly generate double `savefhi' = .
		quietly replace `savefhi' = `fhi' if `touse'
		label variable `savefhi' "qresid F_high"
	}
	if "`saveu'" != "" {
		quietly generate double `saveu' = .
		quietly replace `saveu' = `u' if `touse'
		label variable `saveu' "qresid U"
	}
	if "`savev'" != "" {
		quietly generate double `savev' = .
		quietly replace `savev' = `v' if `touse'
		label variable `savev' "qresid V"
	}

	return local cmd "`cmd'"
	return local family "`fam'"
	return local type "`rtype'"
	return local weight_type "`wtype'"
	return local weight_status "`weight_status'"
	return local dispersion_source "`dispersion_source'"
	if "`dispersion'" != "" {
		return scalar dispersion = `dispersion_override'
	}
	if "`fam'" == "nbreg_mean" | "`fam'" == "glm_nb_fixed" | "`fam'" == "zinb" {
		return scalar alpha = `alpha'
		return scalar theta = `theta'
	}
	if "`fam'" == "nbreg_constant" {
		return scalar delta = `alpha'
	}
	if "`fam'" == "gamma" {
		return scalar phi = `phi'
	}
	if "`fam'" == "igaussian" {
		return scalar phi = `phi'
		return scalar lambda = `lambda'
	}
	if "`fam'" == "genpoisson" {
		return scalar delta = `delta'
	}
	if "`fam'" == "hurdle_nb" {
		return scalar alpha = `alpha'
		return scalar theta = 1 / `alpha'
	}
	return local depvar "`depvar'"
	return scalar N = `N'
	return scalar clipped_low = `clipped_low'
	return scalar clipped_high = `clipped_high'
	return local residual "`varlist'"
	return local saveflo "`saveflo'"
	return local savefhi "`savefhi'"
	return local saveu "`saveu'"
	return local savev "`savev'"
end
