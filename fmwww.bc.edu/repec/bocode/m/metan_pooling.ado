// Stand-alone version of subroutine metan.PerformPoolingIV
// contains in-line Mata code for on-the-fly compiling
// for use with Stata versions prior to 16.1
// If version 16.1+, -metan- can use the pre-compiled Mata routines in lmetan.mlib

// Note:
// - Content of main routine metan_pooling is identical to that of subroutine metan.PerformPoolingIV
// - Content of subroutine metan_pooling.Heterogi is identical to that of subroutine metan.Heterogi
// - Content of Mata subroutines is identical to that of compiled Mata library lmetan.mlib

*! version 4.03  28apr2021
*! Current version by David Fisher
*! Previous versions by Ross Harris and Michael Bradburn


program define metan_pooling, rclass

	syntax varlist(numeric min=2 max=2) [if] [in], MODEL(name) ///
		[SUMMSTAT(name) TESTSTAT(name) QSTAT(passthru) TESTBased ISQParam ///
		OEVLIST(varlist numeric min=2 max=2) INVLIST(varlist numeric min=2 max=6) ///
		NPTS(varname numeric) WGT(varname numeric) WTVAR(varname numeric) ///
		HKsj KRoger BArtlett SKovgaard RObust LOGRank PRoportion TN(string) /*noTRUNCate*/ TRUNCate(string) EIM OIM ///
		ISQSA(real 80) TSQSA(real -99) QWT(varname numeric) INIT(name) OLevel(cilevel) HLevel(cilevel) RFLevel(cilevel) ///
		ITOL(real 1.0x-1a) MAXTausq(real -9) REPS(real 1000) MAXITer(real 1000) QUADPTS(real 100) DIFficult TECHnique(string) * ]

	// N.B. extra options should just be those allowed for PerformPoolingMH

	marksample touse			// note: *NO* "novarlist" option here
	local pvlist `varlist'		// for clarity
	
	// if no wtvar, gen as tempvar
	if `"`wtvar'"'==`""' {
		local wtvar
		tempvar wtvar
		qui gen `wtvar' = .
	}	
	
	// Firstly, check whether only one study
	//   if so, cancel random-effects and set to defaults: iv, cochranq, testbased
	// t-critval ==> es, se, lci, uci returned but nothing else
	tempname k	
	qui count if `touse'
	scalar `k' = r(N)
	if `k' == 1 {
		if "`model'"!="peto" {
			local model iv
			local isqparam
		}
		if "`teststat'"!="z" local teststat z
		local hksj
		c_local nsg = 1
	}

	
	** Chi-squared test (OR only; includes Peto OR) or logrank HR
	if "`oevlist'"!="" {
		tokenize `oevlist'
		args oe va

		tempname OE VA chi2
		summ `oe' if `touse', meanonly
		scalar `OE' = cond(r(N), r(sum), .)
		summ `va' if `touse', meanonly
		scalar `VA' = cond(r(N), r(sum), .)
		scalar `chi2' = (`OE'^2 )/`VA'

		if "`model'"=="peto" | "`logrank'"!="" {
			return scalar OE = `OE'
			return scalar V = `VA'
		}
	}


	*************************************
	* Standard inverse-variance methods *
	*************************************
	
	tokenize `pvlist'
	args _ES _seES
		
	tempname eff se_eff crit pvalue
	qui replace `wtvar' = 1/`_seES'^2 if `touse'
	summ `_ES' [aw=`wtvar'] if `touse', meanonly
	scalar `eff' = r(mean)
	scalar `se_eff' = 1/sqrt(r(sum_w))		// I-V common-effect SE

	// Derive Cochran's Q
	tempvar qhet
	qui gen double `qhet' = `wtvar'*((`_ES' - `eff')^2)
	summ `qhet' if `touse', meanonly

	tempname Q Qdf
	scalar `Q'   = cond(r(N), r(sum), .)
	scalar `Qdf' = cond(r(N), r(N)-1, .)
	
	// Derive sigmasq and tausq
	tempname c sigmasq tausq
	summ `wtvar' [aw=`wtvar'] if `touse', meanonly
	scalar `c' = r(sum_w) - r(mean)
	scalar `sigmasq' = `Qdf'/`c'						// [general note: can this be generalised to other (non-IV) methods?]
	scalar `tausq' = max(0, (`Q' - `Qdf')/`c')			// default: D+L estimator



	**********************************
	* Non-iterative tausq estimators *
	**********************************
	// (other than D+L, already derived above)
	
	** Setup two-stage estimators sj2s and dk2s
	// consider *initial* estimate of tsq
	if inlist("`model'", "sj2s", "dk2s") {
		local final `model'
		local model `"`init'"'
		
		if substr(trim(`"`model'"'), 1, 2)==`"sa"' {
			tempname tausq0
			scalar `tausq0' = `tausq'
		
			_parse comma model 0 : model
			syntax [, ISQ(string) TAUSQ(string)]
			
			if `"`tausq'"'!=`""' & `"`isq'"'==`""' {
				nois disp as err `"Only one of {bf:isq()} or {bf:tausq()} may be supplied as suboptions to {bf:sa()}"'
				exit 184
			}
		
			else if `"`tausq'"'!=`""' {
				cap confirm number `tausq'
				if _rc {
					nois disp as err `"Error in {bf:tausq()} suboption to {bf:sa()}; a single number was expected"'
					exit _rc
				}
				if `tausq' < 0 {
					nois disp as err `"tau{c 178} value for sensitivity analysis cannot be negative"'
					exit 198
				}
				local tsqsa = `tausq'
				local isqsa
			}
			else {
				if `"`isq'"'==`""' local isq = 80
				else {
					cap confirm number `isq'
					if _rc {
						nois disp as err `"Error in {bf:isq()} suboption to {bf:sa()}; a single number was expected"'
						exit _rc
					}
					if `isq'<0 | `isq'>=100 {
						nois disp as err `"I{c 178} value for sensitivity analysis must be at least 0% and less than 100%"'
						exit 198
					}
				}
				local isqsa = `isq'
				local tsqsa = -99
			}

			scalar `tausq' = `tausq0'
		}
	}
	
	** Hartung-Makambi estimator (>0)
	if "`model'"=="hm" {
		scalar `tausq' = `Q'^2 / (`c'*(`Q' + 2*`Qdf'))
	}
	
	** Non-iterative, making use of the sampling variance of _ES
	else if inlist("`model'", "ev", "he", "b0", "bp") {
		tempname var_eff meanv
		qui summ `_ES' if `touse'
		scalar `var_eff' = r(Var)

		tempvar v
		qui gen double `v' = `_seES'^2
		summ `v' if `touse', meanonly
		scalar `meanv' = r(mean)
		
		// empirical variance (>0)
		if "`model'"=="ev" {
			tempvar residsq
			qui gen double `residsq' = (`_ES' - r(mean))^2
			summ `residsq', meanonly
			scalar `tausq' = r(mean)
		}
		
		// Hedges aka "variance component" aka Cochran ANOVA-type estimator
		else if "`model'"=="he" {
			scalar `tausq' = `var_eff' - `meanv'
		}
		
		// Rukhin Bayes estimators
		else if inlist("`model'", "b0", "bp") {
			scalar `tausq' = `var_eff'*(`k' - 1)/(`k' + 1)
			if "`model'"=="b0" {
				summ `npts' if `touse', meanonly	
				scalar `tausq' = `tausq' - ( (`r(sum)' - `k')*`Qdf'*`meanv'/((`k' + 1)*(`r(sum)' - `k' + 2)) )
			}
		}
		scalar `tausq' = max(0, `tausq')			// truncate at zero
	}
	
	// Sensitivity analysis: use given Isq/tausq and sigmasq to generate tausq/Isq
	else if "`model'"=="sa" {
		if `tsqsa'==-99 scalar `tausq' = `isqsa'*`sigmasq'/(100 - `isqsa')
		else scalar `tausq' = `tsqsa'
	}



	******************************
	* Iterative tausq estimators *
	******************************
	
	// Check validity of iteropts
	cap assert (`maxtausq'>=0 & !missing(`maxtausq')) | `maxtausq'==-9
	if _rc {
		nois disp as err "maxtausq() cannot be negative"
		exit 198
	}			
	cap assert `itol'>=0 & !missing(`itol')
	if _rc {
		nois disp as err "itol() cannot be negative"
		exit 198
	}
	cap {
		assert (`maxiter'>0 & !missing(`maxiter'))
		assert round(`maxiter')==`maxiter'
	}
	if _rc {
		nois disp as err "maxiter() must be an integer greater than zero"
		exit 198
	}

	// maxtausq: use 10*`tausq' if not specified
	// (and 10 times that for uci -- done in Mata)
	local maxtausq = cond(`maxtausq'==-9, max(10*`tausq', 100), `maxtausq')
		
	// Iterative, using Mata
	if inlist("`model'", "dlb", "mp", "ml", "pl", "reml") {
	
		// Bootstrap D+L
		// (Kontopantelis PLoS ONE 2013)
		if "`model'"=="dlb" {
			cap {
				assert (`reps'>0 & !missing(`reps'))
				assert round(`reps')==`reps'
			}
			if _rc {
				nois disp as err "reps() must be an integer greater than zero"
				exit 198
			}
			cap nois mata: DLb("`_ES' `_seES'", "`touse'", `olevel', `reps')
		}
		
		// Mandel-Paule aka empirical Bayes
		// (DerSimonian and Kacker CCT 2007)
		// N.B. Mata routine also performs the Viechtbauer Q-profiling routine for tausq CI
		// (Viechtbauer Stat Med 2007; 26: 37-52)
		else if "`model'"=="mp" {
			cap nois mata: GenQ("`_ES' `_seES'", "`touse'", `hlevel', (`maxtausq', `itol', `maxiter'))
		}
		
		// REML
		// N.B. Mata routine also performs likelihood profiling to give tausq CI
		else if "`model'"=="reml" {
			local hmethod = cond("`difficult'"!="", "hybrid", "m-marquardt")	// default = m-marquardt
			if "`technique'"=="" local technique nr								// default = nr
			cap nois mata: REML("`_ES' `_seES'", "`touse'", `hlevel', (`maxtausq', `itol', `maxiter'), "`hmethod'", "`technique'")
			if `"`r(ll_negtsq)'"'!=`""' {
			    nois disp `"{error}tau-squared value from last iteration was negative, so has been set to zero"'
			}
			return scalar converged = r(converged)
			return scalar tsq_var = r(tsq_var)
			return scalar ll = r(ll)
		}
		
		// ML, including Profile Likelihood
		// with optional Bartlett's (Huizenga Br J Math Stat Psychol 2011) or Skovgaard's (Guolo Stat Med 2012) correction to the likelihood
		// N.B. Mata routine also performs likelihood profiling to give tausq CI
		else if inlist("`model'", "ml", "pl") {
			local mlpl `model'
			if "`bartlett'"!="" local mlpl plbart
			else if "`skovgaard'"!="" local mlpl plskov
			local hmethod = cond("`difficult'"!="", "hybrid", "m-marquardt")	// default = m-marquardt
			if "`technique'"=="" local technique nr								// default = nr
			cap nois mata: MLPL("`_ES' `_seES'", "`touse'", (`olevel', `hlevel'), (`maxtausq', `itol', `maxiter'), "`hmethod'", "`technique'", "`mlpl'")			
			if `"`r(ll_negtsq)'"'!=`""' {
			    nois disp `"{error}tau-squared value from last iteration was negative, so has been set to zero"'
			}
			return scalar converged = r(converged)
			return scalar tsq_var = r(tsq_var)
			return scalar ll = r(ll)

			if "`model'"=="pl" {
				return scalar eff_lci = r(eff_lci)
				return scalar eff_uci = r(eff_uci)
				return scalar rc_eff_lci = r(rc_eff_lci)
				return scalar rc_eff_uci = r(rc_eff_uci)
				
				// Need to store these as scalars, in order to calculate critical values
				tempname chi2 z
				scalar `chi2' = r(lr)			// Likelihood ratio test statistic
				scalar `z'    = r(sll)			// Signed log-likelihood test statistic

				if "`teststat'"=="chi2" return scalar chi2 = r(lr)		// Bartlett's correction to the likelihood
				else                    return scalar z    = r(sll)		// Skovgaard's correction to the likelihood
			}
		}
		
		if _rc {
			if _rc==1 exit _rc				// User break
			else if _rc==2000 exit _rc		// No studies found with sufficient data to be analysed
			else if _rc>=3000 {
				nois disp as err "Mata compile-time or run-time error"
				exit _rc
			}
			else if _rc disp `"{error}Error(s) detected during running of Mata code; please check output"'
		}

		scalar `tausq' = r(tausq)

		// check tausq limits and set to missing if necessary
		tempname tsq_lci tsq_uci
		scalar `tsq_lci' = r(tsq_lci)
		scalar `tsq_uci' = r(tsq_uci)
		if "`model'"!="dlb" {
			scalar `tsq_lci' = cond(r(rc_tsq_lci)>1 & r(tsq_lci)!=0, ., r(tsq_lci))
			scalar `tsq_uci' = cond(r(rc_tsq_uci)>1, ., r(tsq_uci))
		}
		
		// return extra scalars
		return scalar maxtausq = `maxtausq'
		return scalar tsq_lci  = `tsq_lci'
		return scalar tsq_uci  = `tsq_uci'
		return scalar rc_tausq   = r(rc_tausq)
		return scalar rc_tsq_lci = r(rc_tsq_lci)
		return scalar rc_tsq_uci = r(rc_tsq_uci)
		
	}	// end if inlist("`model'", "dlb", "mp", "ml", "pl", "reml")
		// [i.e. iterative tausq estimators]
	
	
	// SEP 2020: Remove this option.  If MP CI is desired, the entire MP model can be run.
	// (Doesn't affect forestplot, so why is it needed?  just makes options more complicated)
	/*
	// Viechtbauer Q-profiling routine for tausq CI, if *not* Mandel-Paule tsq estimator
	// (Viechtbauer Stat Med 2007; 26: 37-52)
	if "`hetci'"=="qprofile" & "`model'"!="mp" {
		cap nois mata: GenQ("`_ES' `_seES'", "`touse'", `hlevel', (`maxtausq', `itol', `maxiter'))
		
		if _rc {
			if _rc==1 exit _rc				// User break
			else if _rc==2000 exit _rc		// No studies found with sufficient data to be analysed
			else if _rc>=3000 {
				nois disp as err "Mata compile-time or run-time error"
				exit _rc
			}
			else if _rc disp `"{error}Error(s) detected during running of Mata code; please check output"'
		}				
	
		tempname tsq_lci tsq_uci
		scalar `tsq_lci' = cond(r(rc_tsq_lci)>1 & r(tsq_lci)!=0, ., r(tsq_lci))
		scalar `tsq_uci' = cond(r(rc_tsq_uci)>1, ., r(tsq_uci))
		
		// return extra scalars
		return scalar tsq_lci  = `tsq_lci'
		return scalar tsq_uci  = `tsq_uci'
		return scalar rc_tsq_lci = r(rc_tsq_lci)
		return scalar rc_tsq_uci = r(rc_tsq_uci)
	
	}
	*/
	// end of "Iterative, using Mata" section



	******************************************************
	* User-defined weights; finalise two-step estimators *
	******************************************************

	if `"`wgt'"'!=`""' {
		qui replace `wtvar' = `wgt' if `touse'
	}
	
	tempname Qr				// will also be used for post-hoc variance correction
	if "`final'"!="" {		
		qui replace `qhet' = ((`_ES' - `eff')^2)/((`_seES'^2) + `tausq')
		summ `qhet' if `touse', meanonly
		scalar `Qr' = r(sum)
		
		if "`final'"=="sj2s" {					// two-step Sidik-Jonkman
			// scalar `tausq' = cond(`tausq'==0, `sigmasq'/99, `tausq') * `Qr'/`Qdf'		// March 2018: if tsq=0, use Isq=1%
			scalar `tausq' = `tausq' * `Qr'/`Qdf'
			
			/*
			// Sidik-Jonkman's suggested confidence interval for tausq; not recommended for use
			tempname tsq_lci tsq_uci
			scalar `tsq_lci' = `tausq' * `Qdf' / invchi2(`Qdf', .5 - `hlevel'/200)
			scalar `tsq_uci' = `tausq' * `Qdf' / invchi2(`Qdf', .5 + `hlevel'/200)
			*/
		}
		else if "`final'"=="dk2s" {				// two-step DerSimonian-Kacker (MM only)
			tempname wi1 wi2 wis1 wis2 
			summ `wtvar' if `touse', meanonly
			scalar `wi1' = r(sum)				// sum of weights
			summ `wtvar' [aw=`wtvar'] if `touse', meanonly
			scalar `wi2' = r(sum)				// sum of squared weights				
			summ `wtvar' [aw=`_seES'^2] if `touse', meanonly
			scalar `wis1' = r(sum)				// sum of weight * variance
			summ `wtvar' [aw=`wtvar' * (`_seES'^2)] if `touse', meanonly
			scalar `wis2' = r(sum)				// sum of squared weight * variance
			
			scalar `tausq' = (`Qr' - (`wis1' - `wis2'/`wi1')) / (`wi1' - `wi2'/`wi1')
			scalar `tausq' = max(0, `tausq')	// truncate at zero
		}
		
		local model `final'		// switch back, so that `model' contains dk2s or sj2s again
	}	



	*********************************
	* Alternative weighting schemes *
	*********************************
	// (not user-defined)
	
	// Quality effects (QE) model (extension of IVhet to incorporate quality scores)
	// (Doi et al, Contemporary Clinical Trials 2015; 45: 123-9)
	if "`model'"=="qe" {
		tempvar newqe tauqe
		
		// re-scale scores relative to highest value
		confirm numeric variable `qwt'
		summ `qwt' if `touse', meanonly
		qui gen double `newqe' = `qwt'/r(max)

		// taui and tauhati
		qui gen double `tauqe' = (1 - `newqe')/(`_seES'*`_seES'*`Qdf')
		summ `tauqe' if `touse', meanonly
		local sumtauqe = r(sum)

		summ `newqe' if `touse', meanonly
		if r(min) < 1 {				// additional correction if any `newqe' are < 1, to avoid neg. weights
			tempvar newqe_adj
			qui gen double `newqe_adj' = `newqe' + r(sum)*`tauqe'/(`sumtauqe'*`Qdf')
			summ `newqe_adj' if `touse', meanonly
			qui replace `tauqe' = (`sumtauqe'*`k'*`newqe_adj'/r(sum)) - `tauqe'
		}
		else qui replace `tauqe' = (`sumtauqe'*`k'*`newqe'/r(sum)) - `tauqe'
		
		// Point estimate uses weights = qi/vi + tauhati
		qui replace `wtvar' = (`newqe'/(`_seES'^2)) + `tauqe' if `touse'
	}
	
	// Biggerstaff and Tweedie approximate Gamma-based weighting
	// (also derives a variance and confidence interval for tausq_DL)
	else if "`model'"=="bt" {
		cap nois mata: BTGamma("`_ES' `_seES'", "`touse'", "`wtvar'", `hlevel', (`maxtausq', `itol', `maxiter', `quadpts'))
		if _rc {
			if _rc==1 exit _rc
			else if _rc>=3000 {
				nois disp as err "Mata compile-time or run-time error"
				exit _rc
			}
			else if _rc disp `"{error}Error(s) detected during running of Mata code; please check output"'
		}
		
		// check tausq limits and set to missing if necessary
		tempname tsq_lci tsq_uci
		scalar `tsq_lci' = r(tsq_lci)
		scalar `tsq_uci' = r(tsq_uci)
		scalar `tsq_lci' = cond(r(rc_tsq_lci)>1 & `tsq_lci'!=0, ., `tsq_lci')
		scalar `tsq_uci' = cond(r(rc_tsq_uci)>1, ., `tsq_uci')
	
		// return extra scalars
		return scalar maxtausq = `maxtausq'
		return scalar rc_tausq = r(rc_tausq)
		return scalar tsq_var = r(tsq_var)
		
		return scalar tsq_lci  = `tsq_lci'
		return scalar tsq_uci  = `tsq_uci'
		return scalar rc_tsq_lci = r(rc_tsq_lci)
		return scalar rc_tsq_uci = r(rc_tsq_uci)
	}
	
	// Henmi and Copas method also belongs here
	//  (Henmi and Copas, Stat Med 2010; DOI: 10.1002/sim.4029)
	// Begins along the same lines as IVhet; that is, a RE model with inv-variance weighting
	//   but goes on to estimate the distribution of pivotal quantity U using a Gamma distribution (c.f. Biggerstaff & Tweedie).
	// `se_eff' is the same as IVhet, but conf. interval around `eff' is different.
	else if "`model'"=="hc" {
		cap nois mata: HC("`_ES' `_seES'", "`touse'", `olevel', (`itol', `maxiter', `quadpts'))
		if _rc {
			if _rc==1 exit _rc
			else if _rc>=3000 {
				nois disp as err "Mata compile-time or run-time error"
				exit _rc
			}
			else if _rc disp `"{error}Error(s) detected during running of Mata code; please check output"'
		}
		
		return scalar u = r(u)
		scalar `crit'   = r(crit)
		scalar `pvalue' = r(p)
	}

	// end of "Alternative weighting schemes" section



	**********************************
	* Generate pooled eff and se_eff *
	**********************************
	
	// Alternative or user-defined weighting
	if `"`wgt'"'!=`""' | inlist("`model'", "ivhet", "qe", "bt", "hc") {

		// Apply weighting
		summ `_ES' [aw=`wtvar'] if `touse', meanonly
		scalar `eff' = r(mean)
		
		// Specify underlying model: IV common-effect, or random-effects with additive heterogeneity
		// (N.B. if *multiplicative* heterogeneity, factor simply multiplies the final pooled variance)
		local vi = cond("`model'"=="iv", "`_seES'^2", "`_seES'^2 + `tausq'")
		
		tempvar wtvce
		summ `wtvar' if `touse', meanonly
		qui gen double `wtvce' = (`vi') * `wtvar'^2 / r(sum)^2
		summ `wtvce' if `touse', meanonly
		scalar `se_eff' = sqrt(r(sum))
		
		// May 2020:
		// Similarly to M-H and Peto methods, re-calculate Q based on standard variance weights
		// but with respect to the *weighted* pooled effect size
		if `"`wgt'"'!=`""' {
			qui replace `qhet' = ((`_ES' - `eff') / `_seES')^2
			summ `qhet' if `touse', meanonly
			scalar `Q' = cond(r(N), r(sum), .)
		}
	}
	
	// Standard weighting based on additive tau-squared
	// (N.B. if iv or mu, eff and se_eff have already been calculated)
	else if !inlist("`model'", "iv", "peto", "mu") {
		qui replace `wtvar' = 1/(`_seES'^2 + `tausq') if `touse'
		summ `_ES' [aw=`wtvar'] if `touse', meanonly
		scalar `eff' = r(mean)
		scalar `se_eff' = 1/sqrt(r(sum_w))
	}
	
	// Return weights for CumInfLoop
	summ `wtvar' if `touse', meanonly
	return scalar totwt = cond(r(N), r(sum), .)		// sum of (non-normalised) weights	


	*********************************
	* Post-hoc variance corrections *
	*********************************

	// First, calculate "generalised" (i.e. random-effects) version of Cochran's Q.
	// Note that the multiplier sqrt(`Q'/`Qdf') is equal to Higgins & Thompson's (Stat Med 2002) `H' statistic
	//  and that van Aert & Jackson (2019) use H* to refer to a "generalised/random-effects" H-statistic, similar to Qr.
	tempname Hstar
	scalar `Qr' = `Q'
	if !inlist("`model'", "iv", "peto", "mu") | "`wgt'"!="" {		// Note: if I-V common-effect (e.g. for "mu"), Qr = Q and Hstar = H
		qui replace `qhet' = `wtvar'*((`_ES' - `eff')^2)
		summ `qhet' if `touse', meanonly
		scalar `Qr' = cond(r(N), r(sum), .)
		return scalar Qr = `Qr'
	}
	scalar `Hstar' = sqrt(`Qr'/`Qdf')
	
	// Multiplicative heterogeneity (e.g. Thompson and Sharp, Stat Med 1999)
	// (equivalent to the "full variance" estimator suggested by Sandercock
	// (https://metasurv.wordpress.com/2013/04/26/
	//    fixed-or-random-effects-how-about-the-full-variance-model-resolving-a-decades-old-bunfight)

	// Hartung-Knapp-Sidik-Jonkman variance estimator
	// (Roever et al, BMC Med Res Methodol 2015; Jackson et al, Stat Med 2017; van Aert & Jackson, Stat Med 2019)

	if "`model'"=="mu" | "`hksj'"!="" {
		tempname tcrit zcrit
		scalar `zcrit' = invnormal(.5 + `olevel'/200)
		scalar `tcrit' = invttail(`Qdf', .5 - `olevel'/200)
		
		// van Aert & Jackson 2019: truncate at z/t
		if `"`truncate'"'==`"zovert"' scalar `Hstar' = max(`zcrit'/`tcrit', `Hstar')
		else {
			if "`hksj'"!="" & `Hstar' < `zcrit'/`tcrit' c_local nzt = 1		// setup error display for later
		
			// (e.g.) Roever 2015: truncate at 1
			// i.e. don't use if *under* dispersion present
			if inlist(`"`truncate'"', `"one"', `"1"') scalar `Hstar' = max(1, `Hstar')
			else if `"`truncate'"'!=`""' {
				nois disp as err `"invalid use of {bf:truncate()} option"'
				exit 184
			}
		}
		scalar `se_eff' = `se_eff' * `Hstar'
	}
	return scalar Hstar = `Hstar'

	// Sidik-Jonkman robust ("sandwich-like") variance estimator
	// (Sidik and Jonkman, Comp Stat Data Analysis 2006)
	// (N.B. HKSJ estimator also described in the same paper)
	else if "`robust'"!="" {
		tempname sumwi
		tempvar vr_part
		summ `wtvar' if `touse', meanonly
		scalar `sumwi' = r(sum)
		qui gen double `vr_part' = `wtvar' * `wtvar' * ((`_ES' - `eff')^2) / (1 - (`wtvar'/`sumwi'))
		summ `vr_part' if `touse', meanonly
		scalar `se_eff' = sqrt(r(sum))/`sumwi'
	}

	// Kenward-Roger variance inflation method
	// (Morris et al, Stat Med 2018)
	else if "`kroger'"!="" {
		tempname wi1 wi2 wi3 nwi2 nwi3
		summ `wtvar' if `touse', meanonly
		scalar `wi1' = r(sum)				// sum of weights
		summ `wtvar' [aw=`wtvar'] if `touse', meanonly
		scalar `wi2' = r(sum)				// sum of squared weights
		summ `wtvar' [aw=`wtvar'^2] if `touse', meanonly
		scalar `wi3' = r(sum)				// sum of cubed weights
		scalar `nwi2' = `wi2'/`wi1'			// "normalised" sum of squared weights [i.e. sum(wi:^2)/sum(wi)]
		scalar `nwi3' = `wi3'/`wi1'			// "normalised" sum of cubed weights [i.e. sum(wi:^3)/sum(wi)]		
		
		// expected information
		tempname I
		scalar `I' = `wi2'/2 - `nwi3' + (`nwi2'^2)/2
		
		// observed information
		if "`oim'"!="" {
			tempvar resid resid2
			tempname q2 q3
			
			qui gen double `resid' = `_ES' - `eff'
			summ `resid' [aw=`wtvar'^2] if `touse', meanonly
			scalar `q2' = r(sum)			// quadratic involving squared weights and residual
			
			qui gen double `resid2' = `resid'^2
			summ `resid2' [aw=`wtvar'^3] if `touse', meanonly
			scalar `q3' = r(sum)			// quadratic involving cubed weights and squared residual
			
			scalar `I' = max(0, (`q2'^2)/`wi1' + `q3' - `I')
		}
		
		// corrected se_eff [sqrt(Phi_A) in Kenward-Roger papers]
		tempname W V
		scalar `W' = 1/`I'		// approximation of var(tausq)
		scalar `V' = (1/`wi1') + 2*`W'*(`wi3' - (`wi2'^2)/`wi1')/(`wi1'^2)
		scalar `se_eff' = sqrt(`V')
		
		// denominator degrees of freedom
		tempname A df_kr
		scalar `A' = `W' * (`V'*`wi2')^2
		scalar `df_kr' = 2 / `A'
		// return scalar df_kr = `df_kr'
	}
	
	// check for successful pooling
	if missing(`eff', `se_eff') exit 2002



	**********************************************
	* Critical values, test statistics, p-values *
	**********************************************
	
	// Predictive intervals
	// (uses k-2 df, c.f. Higgins & Thompson 2009; but also see e.g. http://www.metafor-project.org/doku.php/faq#for_random-effects_models_fitt)
	if `k' < 3 c_local nrfd = 1		// setup error display for later
	else {
		tempname rfcritval rflci rfuci
		scalar `rfcritval' = invttail(`k'-2, .5 - `rflevel'/200)
		scalar `rflci' = `eff' - `rfcritval' * sqrt(`tausq' + `se_eff'^2)
		scalar `rfuci' = `eff' + `rfcritval' * sqrt(`tausq' + `se_eff'^2)
		
		return scalar rflci = `rflci'
		return scalar rfuci = `rfuci'
	}
	
	// Proportions
	if "`proportion'"!="" {
		tempname z eff_lci eff_uci
		scalar `z' = `eff'/`se_eff'
		scalar `crit' = invnormal(.5 + `olevel'/200)
		scalar `pvalue' = 2*normal(-abs(`z'))
		scalar `eff_lci' = `eff' - `crit' * `se_eff'
		scalar `eff_uci' = `eff' + `crit' * `se_eff'

		if "`summstat'"=="ftukey" {
			tokenize `invlist'
			args succ _NN
			
			tempname hmean mintes maxtes prop_eff prop_lci prop_uci
			qui ameans `_NN' if `touse'
			if      "`tn'"=="arithmetic" scalar `hmean' = r(mean)				// Arithmetic mean
			else if "`tn'"=="geometric"  scalar `hmean' = r(mean_g)				// Geometric mean
			else if inlist("`tn'", "", "harmonic") scalar `hmean' = r(mean_h)	// Harmonic mean (Miller 1978; default)
			else if "`tn'"=="ivariance"  scalar `hmean' = 1/`se_eff'^2			// Barendregt & Doi's suggestion: inverse of pooled variance
			else {
				confirm number `tn'
				scalar `hmean' = `tn'
			}
			
			// recall: transform is = asin(sqrt(`succ' / (`_NN' + 1 ))) + asin(sqrt((`succ' + 1 ) / (`_NN' + 1 )))
			// so to get our limits `mintes' and `maxtes', we subsitute `hmean' for `_NN', and let `succ' vary from 0 to `hmean'.
			scalar `mintes' = /*asin(sqrt(0      /(`hmean' + 1))) + */        asin(sqrt((0       + 1)/(`hmean' + 1 )))
			scalar `maxtes' =   asin(sqrt(`hmean'/(`hmean' + 1))) + asin(1) /*asin(sqrt((`hmean' + 1)/(`hmean' + 1 )))*/

			// Barendregt & Doi use s/v < 2 or (1-s)/v < 2
			// where s = sin(eff/2)^2 ~= d/n
			// and where v = se_eff ~= 1/n
			// ==> s/v ~= d;  (1-s)/v ~= n-d
			
			// ... in order to avoid "blow up" when sin(eff) is near zero
			// Personal communication:  "blow up" may result in confidence limits which do not include the point estimate
			// Therefore, test for this; and use simplified formula sin(eff)^2 in those cases

			if      `eff' < `mintes' scalar `prop_eff' = 0
			else if `eff' > `maxtes' scalar `prop_eff' = 1
			else scalar `prop_eff' = 0.5 * (1 - sign(cos(`eff')) * sqrt(1 - (sin(`eff') + (sin(`eff') - 1/sin(`eff')) / `hmean')^2 ) )
			
			if      `eff_lci' < `mintes' scalar `prop_lci' = 0
			else if `eff_lci' > `maxtes' scalar `prop_lci' = 1
			else scalar `prop_lci' = 0.5 * (1 - sign(cos(`eff_lci')) * sqrt(1 - (sin(`eff_lci') + (sin(`eff_lci') - 1/sin(`eff_lci')) / `hmean')^2 ) )

			if      `eff_uci' < `mintes' scalar `prop_uci' = 0
			else if `eff_uci' > `maxtes' scalar `prop_uci' = 1
			else scalar `prop_uci' = 0.5 * (1 - sign(cos(`eff_uci')) * sqrt(1 - (sin(`eff_uci') + (sin(`eff_uci') - 1/sin(`eff_uci')) / `hmean')^2 ) )
			
			cap {
			    assert `prop_lci' <= `prop_eff' & `prop_eff' <= `prop_uci'
				assert !missing(`prop_eff', `prop_lci', `prop_uci')
			}
			if _rc {
				scalar `prop_eff' = sin(`eff'    /2)^2
				scalar `prop_lci' = sin(`eff_lci'/2)^2
				scalar `prop_uci' = sin(`eff_uci'/2)^2
			}
			
			scalar `z' = 0
			if `eff' > `mintes' scalar `z' = abs(`eff' - `mintes') / `se_eff'
			
			return scalar prop_eff = `prop_eff'
			return scalar prop_lci = `prop_lci'
			return scalar prop_uci = `prop_uci'
			
			// Predictive intervals
			if `k' >= 3 {
				tempname prop_rflci prop_rfuci
				
				if      `rflci' < `mintes' scalar `prop_rflci' = 0
				else if `rflci' > `maxtes' scalar `prop_rflci' = 1
				else scalar `prop_rflci' = 0.5 * (1 - sign(cos(`rflci')) * sqrt(1 - (sin(`rflci') + (sin(`rflci') - 1/sin(`rflci')) / `hmean')^2 ) )

				if      `rfuci' < `mintes' scalar `prop_rfuci' = 0
				else if `rfuci' > `maxtes' scalar `prop_rfuci' = 1
				else scalar `prop_rfuci' = 0.5 * (1 - sign(cos(`rfuci')) * sqrt(1 - (sin(`rfuci') + (sin(`rfuci') - 1/sin(`rfuci')) / `hmean')^2 ) )

				if _rc {		// from earlier "cap assert"
					scalar `prop_rflci' = sin(`rflci'/2)^2
					scalar `prop_rfuci' = sin(`rfuci'/2)^2
				}
				
				return scalar prop_rflci = `prop_rflci'
				return scalar prop_rfuci = `prop_rfuci'
			}
		}
		else if "`summstat'"=="arcsine" {
			return scalar prop_eff = sin(`eff')^2
			return scalar prop_lci = sin(`eff_lci')^2
			return scalar prop_uci = sin(`eff_uci')^2
			
			// Predictive intervals
			if `k' >= 3 {
				return scalar prop_rflci = sin(`rflci')^2
				return scalar prop_rfuci = sin(`rfuci')^2
			}
		}
		else if "`summstat'"=="logit" {
			return scalar prop_eff = invlogit(`eff')
			return scalar prop_lci = invlogit(`eff_lci')
			return scalar prop_uci = invlogit(`eff_uci')
			
			// Predictive intervals
			if `k' >= 3 {
				return scalar prop_rflci = invlogit(`rflci')
				return scalar prop_rfuci = invlogit(`rfuci')
			}
		}
		else {
			return scalar prop_eff = `eff'
			return scalar prop_lci = `eff_lci'
			return scalar prop_uci = `eff_uci'
			
			// Predictive intervals
			if `k' >= 3 {			
				return scalar prop_rflci = `rflci'
				return scalar prop_rfuci = `rfuci'
			}
		}
		
		return scalar z = `z'
		return scalar eff_lci = `eff_lci'
		return scalar eff_uci = `eff_uci'
	}
	
	// All other data types
	else {
		if "`model'"=="pl" {				// N.B. PL confidence limits have already been calculated
			if "`teststat'"=="chi2" {
				scalar `crit' = invchi2(1, `olevel'/100)
				scalar `pvalue' = chi2tail(1, `chi2')
			}
			else {
				scalar `crit' = invnormal(.5 + `olevel'/200)
				scalar `pvalue' = 2*normal(-abs(`z'))
			}
		}
		else {
			if "`teststat'"=="chi2" { 
				scalar `crit' = invchi2(1, `olevel'/100)
				scalar `pvalue' = chi2tail(1, `chi2')
				return scalar chi2 = `chi2'
			}
			else if "`kroger'"!="" {
				tempname t
				scalar `crit' = invttail(`df_kr', .5 - `olevel'/200)
				scalar `t' = `eff'/`se_eff'
				scalar `pvalue' = 2*ttail(`df_kr', abs(`t'))
				return scalar t = `t'
			}
			else if "`teststat'"=="t" {
				tempname t
				scalar `crit' = invttail(`Qdf', .5 - `olevel'/200)
				scalar `t' = `eff'/`se_eff'
				scalar `pvalue' = 2*ttail(`Qdf', abs(`eff'/`se_eff'))
				return scalar t = `t'
			}
			else if "`model'"!="hc" {		// N.B. HC crit + p-value have already been calculated
				tempname z
				scalar `crit' = invnormal(.5 + `olevel'/200)
				scalar `z' = `eff'/`se_eff'
				scalar `pvalue' = 2*normal(-abs(`z'))
				return scalar z = `z'
			}
			
			// Confidence intervals
			if "`oevlist'"!="" {		// crit.value is chi2, but CI is based on z
				return scalar eff_lci = `eff' - invnormal(.5 + `olevel'/200) * `se_eff'
				return scalar eff_uci = `eff' + invnormal(.5 + `olevel'/200) * `se_eff'
			}
			else {						// else we can use crit.value (z or t, or u if HC)
				return scalar eff_lci = `eff' - `crit' * `se_eff'
				return scalar eff_uci = `eff' + `crit' * `se_eff'
			}
		}
	}	
	

	*****************************************
	* Derive other heterogeneity statistics *
	*****************************************
	// e.g. H, I-squared and (modified) H-squared; plus Q-based confidence intervals
	
	// Sensitivity analysis
	// (Note: tausq has already been established, whether `tsqsa' or `Isqsa')
	if "`model'"=="sa" {
		tempname H Isqval HsqM
		if `tsqsa' == -99 {
			scalar `H' = sqrt(100 / (100 - `isqsa'))
			scalar `Isqval' = `isqsa'
			scalar `HsqM' = `isqsa'/(100 - `isqsa')
			return scalar H = `H'
			return scalar Isq = `Isqval'
			return scalar HsqM = float(`HsqM')			// If user-defined I^2 is a round(ish) number, so should H^2 be
		}
		else {
			scalar `H' = sqrt((`tsqsa' + `sigmasq') / `sigmasq')
			scalar `Isqval' = 100*`tsqsa'/(`tsqsa' + `sigmasq')
			scalar `HsqM' = `tsqsa'/`sigmasq'
			return scalar H = `H'
			return scalar Isq = `Isqval'
			return scalar HsqM = `HsqM'
		}
		
		// [Sep 2020] Also save values in matrix `hetstats', same as if `isqparam' (see subroutine -heterogi- )
		local t2rownames tausq tsq_lci tsq_uci H H_lci H_uci Isq Isq_lci Isq_uci HsqM HsqM_lci HsqM_uci
		tempname hetstats
		local r : word count `t2rownames'
		matrix define `hetstats' = J(`r', 1, .)
		matrix rownames `hetstats' = `t2rownames'
		
		matrix `hetstats'[rownumb(`hetstats', "tausq"), 1] = `tausq'
		matrix `hetstats'[rownumb(`hetstats', "H"),     1] = `H'
		matrix `hetstats'[rownumb(`hetstats', "Isq"),   1] = `Isqval'
		matrix `hetstats'[rownumb(`hetstats', "HsqM"),  1] = `HsqM'
		
		return matrix hetstats = `hetstats'
	}
	
	else {
		if !inlist("`model'", "iv", "peto", "mu") {
			local tausqlist `tausq' `tsq_lci' `tsq_uci'
			cap assert "`tausqlist'"!="" if "`isqparam'"!=""
			if _rc {
				nois disp as err "Heterogeneity confidence interval not valid"
				exit 198
			}
		}
		
		cap nois Heterogi `Q' `Qdf' if `touse', `testbased' `isqparam' ///
			stderr(`_seES') tausqlist(`tausqlist') level(`hlevel')
		
		if _rc {
			if _rc==1 nois disp as err `"User break in {bf:metan.Heterogi}"'
			else nois disp as err `"Error in {bf:metan.Heterogi}"'
			c_local err noerr		// tell -metan- not to also report an "error in metan.PerformPoolingIV"
			exit _rc
		}
		
		return add
	}
	
	// Return scalars
	return scalar eff = `eff'
	return scalar se_eff = `se_eff'
	return scalar crit = `crit'
	return scalar pvalue = `pvalue'

	if "`kroger'"!="" return scalar df = `df_kr'
	else if "`teststat'"=="t" return scalar df = `Qdf'	
	
	return scalar k   = `k'				// k = number of studies (= count if `touse')
	return scalar Q   = `Q'				// Cochran's Q heterogeneity statistic
	return scalar Qdf = `Qdf'			// Q degrees of freedom (= `k' - 1)
	return scalar sigmasq = `sigmasq'	// "typical" within-study variance (Higgins & Thompson 2002)
	return scalar tausq = `tausq'		// between-study heterogeneity variance
	return scalar c = `c'				// scaling factor

end




// Based on heterogi.ado from SSC, with release notes:
// version 2.0 N.Orsini, I. Buchan, 25 Jan 06
// version 1.0 N.Orsini, J.Higgins, M.Bottai, 16 Feb 2005
// (c.f. Higgins & Thompson Stat Med 2002, "Quantifying heterogeneity")

program define Heterogi, rclass
	
	syntax anything [if] [in], [ TESTBased ISQParam ///
		STDERR(varname numeric) TAUSQLIST(namelist min=1 max=3) LEVEL(cilevel) ]

	marksample touse
	tokenize `anything'
	assert `"`3'"'==`""'
	args Q Qdf

	// setup W1, W2 for tausq if stderr available (e.g. not for M-H)
	if "`stderr'"!="" {
		tempvar wtvar
		qui gen double `wtvar' = 1/`stderr'^2

		tempname W1 W2
		summ `wtvar' if `touse', meanonly
		scalar `W1' = r(sum)				// sum of weights
		summ `wtvar' [aw=`wtvar'] if `touse', meanonly
		scalar `W2' = r(sum)				// sum of squared weights
		
		tempname sigmasq
		scalar `sigmasq' = (r(N) - 1) / (`W1' - `W2'/`W1')		
	}

	
	********************
	* Standard Q-based *
	********************

	tempname Q_lci Q_uci
	scalar `Q_lci' = .
	scalar `Q_uci' = .
	
	
	** Confidence intervals:

	// Test-based interval for ln(Q) [ or, equivalently, ln(H) ]
	// (Higgins & Thompson, Stats in Medicine 2002)
	if "`testbased'"!="" {
		tempname k selogQ
		scalar `k' = `Qdf' + 1
		
		// Formula 26.4.13 of Abramowitz and Stegun (1965):
		// Z = sqrt(2Q) - sqrt(2k - 3) is standard normal
		// Now, expected value of Q is k-1, so form a standard normal variate as follows (taking logs to reduce skew):
		// Z = [ ln(Q) - ln(k-1) ] / se[ ln(Q) ]
		// ==> se[ ln(Q) ] = [ ln(Q) - ln(k-1) ] / [ sqrt(2Q) - sqrt(2k - 3) ]
		scalar `selogQ' = (ln(`Q') - ln(`Qdf')) / ( sqrt(2*`Q') - sqrt(2*`k' - 3) )
		
		// Formula 26.4.36 of Abramowitz and Stegun (1965):
		// Var[ ln(Q/k-1) ] = [ 2/(k-2) ] * [ 1 - (1/ {3(k-2)^2} ) ]
		// (use if Q <= k)
		if `Q' <= `k' {
		    scalar `selogQ' = sqrt( ( 2/(`k'-2)) * (1 - 1/(3*(`k'-2)^2)) )
		}
		
		tempname Q_lci Q_uci
		scalar `Q_lci' = max(0, exp( ln(`Q') - invnormal(.5 + `level'/200) * `selogQ' ))
		scalar `Q_uci' =        exp( ln(`Q') + invnormal(.5 + `level'/200) * `selogQ' )
		
		/*
		// Original code from heterogi.ado
		// used confidence intervals for lnH rather than for lnQ, but these differ only by a constant:
		// If, as above, Var[ ln(Q/k-1) ] = [ 2/(k-2) ] * [ 1 - (1/ {3(k-2)^2} ) ]
		// then if ln(H) = .5 * ln(Q/k-1), then Var[ ln(H) ] = .25 * Var[ ln(Q/k-1) ] = [ 1/ 2(k-2) ] * [ 1 - (1/ {3(k-2)^2} ) ]
		
		scalar `selogH' = cond(`Q' > `k', ///
			.5*( (ln(`Q') - ln(`Qdf')) / ( sqrt(2*`Q') - sqrt(2*`k' - 3) ) ), ///
			sqrt( ( 1/(2*(`k'-2)) * (1 - 1/(3*(`k'-2)^2)) ) ))
		
		scalar `H_lci' = max(1, exp( ln(`H') - invnormal(.5 + `level'/200) * `selogH' ))
		scalar `H_uci' =        exp( ln(`H') + invnormal(.5 + `level'/200) * `selogH' )
		*/
	}

	// Q-based confidence intervals
	// using ncchi2 if fixed-effect; Gamma-based if random-effects (ref: Hedges & Pigott, 2001)
	// ncchi2 previously recommended by JPTH based on personal communications
	else {
		if "`tausqlist'"=="" {			// fixed (common) effect
			tempname nc
			scalar `nc' = max(0, `Q' - `Qdf')
 
			// If Q < df, no need to seek the lower bound
			tempname Q_lci Q_uci
			scalar `Q_lci' = cond(`nc'==0, 0, invnchi2(`Qdf', `nc', .5 - `level'/200))
			scalar `Q_uci' =                  invnchi2(`Qdf', `nc', .5 + `level'/200)
		}

		else {							// random-effects
			cap assert "`stderr'"!=""
			if _rc {
				nois disp as err "Heterogeneity confidence interval not valid"
				exit 198
			}
		
			tempname W3 tsq_dl
			summ `wtvar' [aw=`wtvar'^2] if `touse', meanonly
			scalar `W3' = r(sum)									// sum of cubed weights
			scalar `tsq_dl' = (`Q' - `Qdf') / (`W1' - `W2'/`W1')	// non-truncated tsq_DL
		
			tempname btVarQ
			scalar `btVarQ' = 2*`Qdf' + 4*`tsq_dl'*(`W1' - `W2'/`W1') + 2*(`tsq_dl'^2)*(`W2' - 2*`W3'/`W1' + (`W2'/`W1')^2)
			
			// If Q < df, no need to seek the lower bound
			tempname Q_lci Q_uci
			scalar `Q_lci' = cond(`Q' < `Qdf', 0, invgammap(`Q'^2 / `btVarQ', .5 - `level'/200) * `btVarQ' / `Q')
			scalar `Q_uci' =                      invgammap(`Q'^2 / `btVarQ', .5 + `level'/200) * `btVarQ' / `Q'
		}
	}

	// standard, transformed CIs for Isq, as outputted by heterogi.ado
	// Taken from heterogi.ado by N.Orsini, J.Higgins, M.Bottai, N.Buchan (2005-2006)
	return scalar Q_lci = `Q_lci'
	return scalar Q_uci = `Q_uci'

	return scalar H     = max(1, sqrt(`Q' / `Qdf'))
	return scalar H_lci = max(1, sqrt(`Q_lci' / `Qdf'))
	return scalar H_uci =        sqrt(`Q_uci' / `Qdf')			
		
	return scalar Isq     = 100* max(0, (`Q' - `Qdf') / `Q')
	return scalar Isq_lci = 100* max(0, (`Q_lci' - `Qdf') / `Q_lci')
	return scalar Isq_uci = 100* min(1, (`Q_uci' - `Qdf') / `Q_uci')
		
	return scalar HsqM     = max(0, (`Q'     - `Qdf') / `Qdf')
	return scalar HsqM_lci = max(0, (`Q_lci' - `Qdf') / `Qdf')
	return scalar HsqM_uci = max(0, (`Q_uci' - `Qdf') / `Qdf')
	
	

	*********************
	* Tau-squared based *
	*********************
	
	if "`isqparam'"!="" {
		tokenize `tausqlist'
		args tausq tsq_lci tsq_uci
		
		// Save values in matrix `hetstats'
		local t2rownames tausq tsq_lci tsq_uci H H_lci H_uci Isq Isq_lci Isq_uci HsqM HsqM_lci HsqM_uci
		tempname hetstats
		local r : word count `t2rownames'
		matrix define `hetstats' = J(`r', 1, .)
		matrix rownames `hetstats' = `t2rownames'
		
		if "`tausqlist'"!="" {
			matrix `hetstats'[rownumb(`hetstats', "tausq"), 1] = `tausq'
			matrix `hetstats'[rownumb(`hetstats', "H"), 1]     = sqrt((`tausq' + `sigmasq') / `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "Isq"), 1]   = 100* `tausq' / (`tausq' + `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "HsqM"), 1]  = `tausq' / `sigmasq'
		}
		
		// If `tausq' not defined for this model, store H, Isq and HsqM (& CIs) based on Q instead
		else {
			matrix `hetstats'[rownumb(`hetstats', "H"), 1]    = max(1, sqrt(`Q' / `Qdf'))
			matrix `hetstats'[rownumb(`hetstats', "Isq"), 1]  = 100* max(0, (`Q' - `Qdf') / `Q')
			matrix `hetstats'[rownumb(`hetstats', "HsqM"), 1] = max(0, (`Q' - `Qdf') / `Qdf')
			
			matrix `hetstats'[rownumb(`hetstats', "H_lci"), 1]    = max(1, sqrt(`Q_lci' / `Qdf'))
			matrix `hetstats'[rownumb(`hetstats', "Isq_lci"), 1]  = 100* max(0, (`Q_lci' - `Qdf') / `Q_lci')
			matrix `hetstats'[rownumb(`hetstats', "HsqM_lci"), 1] = max(0, (`Q_lci' - `Qdf') / `Qdf')

			matrix `hetstats'[rownumb(`hetstats', "H_uci"), 1]    = max(1, sqrt(`Q_uci' / `Qdf'))
			matrix `hetstats'[rownumb(`hetstats', "Isq_uci"), 1]  = 100* max(0, (`Q_uci' - `Qdf') / `Q_uci')
			matrix `hetstats'[rownumb(`hetstats', "HsqM_uci"), 1] = max(0, (`Q_uci' - `Qdf') / `Qdf')
		}
		
		// Confidence intervals, if appropriate
		if `"`tsq_lci'"'!=`""' {
			matrix `hetstats'[rownumb(`hetstats', "tsq_lci"), 1]  = `tsq_lci'
			matrix `hetstats'[rownumb(`hetstats', "H_lci"), 1]    = sqrt((`tsq_lci' + `sigmasq') / `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "Isq_lci"), 1]  = 100* `tsq_lci' / (`tsq_lci' + `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "HsqM_lci"), 1] = `tsq_lci' / `sigmasq'
			
			matrix `hetstats'[rownumb(`hetstats', "tsq_uci"), 1]  = `tsq_uci'
			matrix `hetstats'[rownumb(`hetstats', "H_uci"), 1]    = sqrt((`tsq_uci' + `sigmasq') / `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "Isq_uci"), 1]  = 100* `tsq_uci' / (`tsq_uci' + `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "HsqM_uci"), 1] = `tsq_uci' / `sigmasq'
		}
		
		return matrix hetstats = `hetstats'
	}

end





********************************************************************************

********************
* Mata subroutines *  (for iterative methods)
********************

version 11.0

mata:


/* Kontopantelis's bootstrap DerSimonian-Laird estimator */
// (PLoS ONE 2013; 8(7): e69930, and also implemented in metaan)
// N.B. using originally estimated ES within the re-samples, as in Kontopantelis's paper */
void DLb(string scalar varlist, string scalar touse, real scalar level, real scalar reps)
{
	// setup
	real colvector yi, se, vi, wi
	varlist = tokens(varlist)
	st_view(yi=., ., varlist[1], touse)
	if(length(yi)==0) exit(error(2000))
	st_view(se=., ., varlist[2], touse)
	vi = se:^2
	wi = 1:/vi

	// calculate I-V Common eff
	real scalar eff
	eff = mean(yi, wi)	

	// carry out bootstrap procedure
	transmorphic B, J
	real colvector report
	B = mm_bs(&ftausq(), (yi, vi), 1, reps, 0, 1, ., ., ., eff)
	J = mm_jk(&ftausq(), (yi, vi), 1, 1, ., ., ., ., ., eff)
	report = mm_bs_report(B, ("mean", "bca"), level, 0, J)

	// truncate at zero
	report = report:*(report:>0)
	
	// return tausq and confidence limits
	real scalar tausq
	tausq = report[1]
	st_numscalar("r(tausq)", tausq)
	st_numscalar("r(tsq_lci)", report[2])
	st_numscalar("r(tsq_uci)", report[3])
}

real scalar ftausq(real matrix coeffs, real colvector weight, real scalar eff) {
	real colvector yi, vi, wi
	real scalar k, Q, c, tausq
	yi = select(coeffs[,1], weight)
	vi = select(coeffs[,2], weight)
	k = length(yi)
	wi = 1:/vi
	Q = crossdev(yi, eff, wi, yi, eff)
	c = sum(wi) - mean(wi, wi)
	tausq = max((0, (Q-(k-1))/c))
	return(tausq)
}



/* "Generalised Q" methods */
void GenQ(string scalar varlist, string scalar touse, real scalar hlevel, real rowvector iteropts)
{
	// setup
	real colvector yi, se, vi, wi
	varlist = tokens(varlist)
	st_view(yi=., ., varlist[1], touse)
	if(length(yi)==0) exit(error(2000))
	st_view(se=., ., varlist[2], touse)
	vi = se:^2
	wi = 1:/vi

	real scalar maxtausq, itol, maxiter
	maxtausq = iteropts[1]
	itol = iteropts[2]
	maxiter = iteropts[3]
	
	real scalar k
	k = length(yi)
	
	/* Mandel-Paule estimator of tausq (J Res Natl Bur Stand 1982; 87: 377-85) */
	// (also DerSimonian & Kacker, Contemporary Clinical Trials 2007; 28: 105-114)
	// ... can be shown to be equivalent to the "empirical Bayes" estimator
	// (e.g. Sidik & Jonkman Stat Med 2007; 26: 1964-81)
	// and converges more quickly
	real scalar rc_tausq, tausq
	rc_tausq = mm_root(tausq=., &Q_crit(), 0, maxtausq, itol, maxiter, yi, vi, k, k-1)
	st_numscalar("r(tausq)", tausq)
	st_numscalar("r(rc_tausq)", rc_tausq)
	

	/* Confidence interval for tausq by generalised Q-profiling */
	// Viechtbauer Stat Med 2007; 26: 37-52
	// (N.B. most natural point estimate is Mandel-Paule, but any estimate will do)
	real scalar eff, Qmin, Qmax
	eff = mean(yi, wi)							// I-V common-effect estimate
	Qmin = crossdev(yi, eff, wi, yi, eff)		// Q(0) = standard Cochran's Q heterogeneity statistic (when tausq=0)
	wi = 1:/(vi:+maxtausq)
	eff = mean(yi, wi)
	Qmax = crossdev(yi, eff, wi, yi, eff)
	
	// estimate tausq confidence limits
	real scalar Q_crit_hi, Q_crit_lo, tsq_lci, rc_tsq_lci, tsq_uci, rc_tsq_uci
	Q_crit_hi = invchi2(k-1, .5 + hlevel/200)		// higher critical value (0.975) to compare GenQ against (for *lower* bound of tausq)
	Q_crit_lo = invchi2(k-1, .5 - hlevel/200)		//  lower critical value (0.025) to compare GenQ against (for *upper* bound of tausq)
	
	if (Qmin < Q_crit_lo) {			// if Q(0) is less the lower critical value, interval is set to null
		rc_tsq_lci = 2
		rc_tsq_uci = 2
		tsq_lci = 0
		tsq_uci = 0
	}	
	else {
		if (Qmax > Q_crit_lo) {		// If Q(maxtausq) is larger than the lower critical value...
			rc_tsq_uci = 2
			tsq_uci = maxtausq		// ...upper bound for tausq is tausqmax
		}
		else {
			rc_tsq_uci = mm_root(tsq_uci=., &Q_crit(), 0, maxtausq, itol, maxiter, yi, vi, k, Q_crit_lo)
		}
	}
	if (Qmax > Q_crit_hi) {			// If Q(maxtausq) is larger than the higher critical value, interval is set to null
		rc_tsq_lci = 2
		rc_tsq_uci = 2
		tsq_lci = maxtausq
		tsq_uci = maxtausq
	}
	else {
		if (Qmin < Q_crit_hi) {		// If Q(0) is less than the higher critical value...
			rc_tsq_lci = 2
			tsq_lci = 0				// ...lower bound for tausq is 0
		}		
		else {
			rc_tsq_lci = mm_root(tsq_lci=., &Q_crit(), 0, maxtausq, itol, maxiter, yi, vi, k, Q_crit_hi)
		}
	}
	
	// return confidence limits and rc codes
	st_numscalar("r(tsq_lci)", tsq_lci)
	st_numscalar("r(tsq_uci)", tsq_uci)
	st_numscalar("r(rc_tsq_lci)", rc_tsq_lci)
	st_numscalar("r(rc_tsq_uci)", rc_tsq_uci)
}

real scalar Q_crit(real scalar tausq, real colvector yi, real colvector vi, real scalar k, real scalar crit) {
	real colvector wi
	real scalar eff, newtausq
	wi = 1:/(vi:+tausq)
	eff = mean(yi, wi)
	newtausq = (k/crit)*crossdev(yi, eff, wi, yi, eff)/sum(wi) - mean(vi, wi)	// corrected June 2015
	return(tausq - newtausq)
}



/* ML + optional PL (for likelihood profiling for ES CI) */
// (N.B. pass wi back-and-forth as it needs to be calculated anyway for tausq likelihood profiling)
void MLPL(string scalar varlist, string scalar touse, real rowvector levels, real rowvector iteropts, string scalar hmethod, string scalar technique, string scalar model)
{		
	// setup
	real colvector yi, se, vi, wi
	varlist = tokens(varlist)
	st_view(yi=., ., varlist[1], touse)
	if(length(yi)==0) exit(error(111))
	st_view(se=., ., varlist[2], touse)
	vi = se:^2
	wi = 1:/vi

	// Initialize
	real scalar eff0, tausq, eff
	eff0 = mean(yi, wi)								// Effect size with zero tausq
	tausq = max((0, quadvariance(yi) - mean(vi)))	// Initialize tausq using Hedges estimator
	wi = 1:/(vi:+tausq)
	eff = mean(yi, wi)								// Initialize eff using Hedges estimator
	
	// Maximize log-likelihood for ML
	transmorphic S
	real rowvector p
	S = optimize_init()
	optimize_init_evaluator(S, &ML_est())
	optimize_init_evaluatortype(S, "d2")
	optimize_init_params(S, (eff, tausq))
	optimize_init_argument(S, 1, yi)
	optimize_init_argument(S, 2, vi)
	optimize_init_argument(S, 3, .)				// ML_est() can also estimate tausq with eff held constant; not relevant here
	optimize_init_technique(S, technique) 
	optimize_init_singularHmethod(S, hmethod)
	optimize_init_tracelevel(S, "none")
	p = optimize(S)
	
	real scalar rc
	rc = optimize_result_returncode(S)	
	if(rc) exit(error(rc))

	real scalar ll
	ll = optimize_result_value(S)
	eff = p[1]
	tausq = p[2]
	if(tausq < 0) {
		tausq = 0
		eff = eff0
		st_numscalar("r(ll_negtsq)", ll)		
		ll = sum(lnnormalden(yi, eff, sqrt(vi)))
	}
	wi = 1:/(vi:+tausq)
	st_numscalar("r(tausq)", tausq)
	st_numscalar("r(converged)", optimize_result_converged(S))
	st_numscalar("r(ll)", ll)

	// Variance of tausq (using inverse Fisher information)
	real scalar tsq_var
	tsq_var = optimize_result_V(S)[2,2]
	st_numscalar("r(tsq_var)", tsq_var)	

	// Confidence interval for tausq using likelihood profiling
	real scalar maxtausq, itol, maxiter
	maxtausq = iteropts[1]
	itol     = iteropts[2]
	maxiter  = iteropts[3]
	
	real scalar level, hlevel, crit
	level  = levels[1]
	hlevel = levels[2]
	crit = ll - invchi2(1, hlevel/100)/2
	
	real scalar tsq_lci, rc_tsq_lci, tsq_uci, rc_tsq_uci
	rc_tsq_lci = mm_root(tsq_lci=., &ML_profile_tausq(), 0, tausq - itol, itol, maxiter, yi, vi, crit)
	st_numscalar("r(tsq_lci)", tsq_lci)
	st_numscalar("r(rc_tsq_lci)", rc_tsq_lci)

	rc_tsq_uci = mm_root(tsq_uci=., &ML_profile_tausq(), tausq + itol, 10*maxtausq, itol, maxiter, yi, vi, crit)
	st_numscalar("r(tsq_uci)", tsq_uci)
	st_numscalar("r(rc_tsq_uci)", rc_tsq_uci)
	
	// Profile likelihood
	if (model!="ml") {
	
		// Bartlett's correction
		// (see e.g. Huizenga et al, Br J Math Stat Psychol 2011)
		real scalar BCFinv
		BCFinv = 1
		if (model=="plbart") {
			BCFinv = 1 + 2*mean(wi, wi:^2)/sum(wi) - 0.5*mean(wi, wi)/sum(wi)
			st_numscalar("r(BCF)", 1/BCFinv)
		}

		// Log-likelihood based test statistic
		// (evaluated at b = 0)
		crit = ll - invchi2(1, level/100)*BCFinv/2
		
		S = optimize_init()
		optimize_init_evaluator(S, &ML_est())
		optimize_init_evaluatortype(S, "d2")
		optimize_init_params(S, tausq)
		optimize_init_argument(S, 1, yi)
		optimize_init_argument(S, 2, vi)
		optimize_init_argument(S, 3, 0)				// estimate tausq with b held constant at zero
		optimize_init_technique(S, technique) 
		optimize_init_singularHmethod(S, hmethod)
		optimize_init_tracelevel(S, "none")
		
		real scalar tausq0, rc_ll0, ll0, lr
		tausq0 = optimize(S)
		rc_ll0  = optimize_result_returncode(S)
		if(rc_ll0) exit(error(rc_ll0))
		ll0 = optimize_result_value(S)		
		if(tausq0 < 0) {
			tausq0 = 0
			ll0 = sum(lnnormalden(yi, 0, sqrt(vi)))
		}
		if (abs(ll0 - ll) <= itol) lr = 0		// in case ll, ll_b are very close (within itol) and/or rounding error results in a negative value
		else lr = 2*(ll - ll0) / BCFinv
		
		// Signed log-likelihood statistic
		// (evaluated at b = 0)
		real scalar sll
		if (lr==0) sll = 0
		else sll = sign(eff)*sqrt(lr)
		
		// Confidence interval for ES using likelihood profiling
		// (use ten times the ML lci and uci for search limits)
		real scalar llim, ulim, eff_lci, eff_uci, rc_eff_lci, rc_eff_uci
		llim = eff - 19.6/sqrt(sum(wi))
		ulim = eff + 19.6/sqrt(sum(wi))
		
		// Skovgaard's correction to the signed likelihood statistic
		if (model=="plskov") {
		
			// Collect ML values of eff, tausq, ll to send to ML_skov()
			real rowvector params
			params = (eff, tausq, ll)
			
			// can't directly correct the critical value, due to the square root (i.e. expression is non-linear)
			// so instead need to pass the critical value to the iteration procedure, and correct afterwards
			crit = invnormal(.5 + level/200)
			sll = ML_skov(0, yi, vi, wi, params, crit, iteropts, hmethod, technique)	// find SLL for b fixed at zero
			sll = sll + crit															// ML_skov() returns sll-crit, so add crit back on
		
			rc_eff_lci = mm_root(eff_lci=., &ML_skov(), llim, eff-itol, itol, maxiter, yi, vi, wi, params,  crit, iteropts, hmethod, technique)
			rc_eff_uci = mm_root(eff_uci=., &ML_skov(), eff+itol, ulim, itol, maxiter, yi, vi, wi, params, -crit, iteropts, hmethod, technique)
			st_numscalar("r(eff_lci)", eff_lci)
			st_numscalar("r(eff_uci)", eff_uci)
			st_numscalar("r(rc_eff_lci)", rc_eff_lci)
			st_numscalar("r(rc_eff_uci)", rc_eff_uci)		
		}
		
		// Otherwise, use the (squared) likelihood statistic LR = SLL^2
		else {
			rc_eff_lci = mm_root(eff_lci=., &ML_profile_eff(), llim, eff, itol, maxiter, yi, vi, crit, tausq, iteropts, hmethod, technique)
			rc_eff_uci = mm_root(eff_uci=., &ML_profile_eff(), eff, ulim, itol, maxiter, yi, vi, crit, tausq, iteropts, hmethod, technique)
			st_numscalar("r(eff_lci)", eff_lci)
			st_numscalar("r(eff_uci)", eff_uci)
			st_numscalar("r(rc_eff_lci)", rc_eff_lci)
			st_numscalar("r(rc_eff_uci)", rc_eff_uci)
		}
		
		st_numscalar("r(ll)", ll)
		st_numscalar("r(lr)", lr)		
		st_numscalar("r(sll)", sll)
	}
}

void ML_est(todo, p, yi, vi, eff_cons, lnf, S, H) {
	real scalar eff, tausq
	real colvector wi
	if(cols(p)==2) {
		eff = p[1]
		tausq = max((0, p[2]))
		lnf = sum(lnnormalden(yi, eff, sqrt(vi:+tausq)))
		if(todo>=1) {
			wi = 1:/(vi:+tausq)
			S = J(1, 2, .)
			S[1] = quadcross(wi, yi:-eff)
			S[2] = -0.5*sum(wi) + 0.5*quadcrossdev(yi, eff, wi:^2, yi, eff)
			if(todo>=2) {
				H = J(2, 2, .)
				H[1, 1] = -sum(wi)
				H[2, 1] = -quadcross(wi:^2, yi:-eff)
				H[2, 2] = 0.5*quadcross(wi, wi) - quadcrossdev(yi, eff, wi:^3, yi, eff)
				_makesymmetric(H)
			}
		}
	}
	else {
		eff = eff_cons		// estimate tausq with eff held constant
		tausq = max((0, p))
		lnf = sum(lnnormalden(yi, eff, sqrt(vi:+tausq)))
		if(todo>=1) {
			wi = 1:/(vi:+tausq)
			S = -0.5*sum(wi) + 0.5*quadcrossdev(yi, eff, wi:^2, yi, eff)
			if(todo>=2) {
				H = 0.5*quadcross(wi, wi) - quadcrossdev(yi, eff, wi:^3, yi, eff)
			}
		}
	}
}

real scalar ML_profile_tausq(real scalar tausq, real colvector yi, real colvector vi, real scalar crit) {
	real colvector wi
	real scalar eff, ll
	wi = 1:/(vi:+tausq)
	eff = mean(yi, wi)
	ll = sum(lnnormalden(yi, eff, sqrt(vi:+tausq)))
	return(ll - crit)
}

real scalar ML_profile_eff(real scalar eff, real colvector yi, real colvector vi, real scalar crit, real scalar tausq_init, real rowvector iteropts, string scalar hmethod, string scalar technique) {
	real scalar maxtausq, itol, maxiter
	maxtausq = iteropts[1]
	itol = iteropts[2]
	maxiter = iteropts[3]

	transmorphic S
	S = optimize_init()
	optimize_init_evaluator(S, &ML_est())
	optimize_init_evaluatortype(S, "d2")
	optimize_init_params(S, tausq_init)
	optimize_init_argument(S, 1, yi)
	optimize_init_argument(S, 2, vi)
	optimize_init_argument(S, 3, eff)
	optimize_init_technique(S, technique) 
	optimize_init_singularHmethod(S, hmethod)
	optimize_init_tracelevel(S, "none")

	real scalar tausq_ll, rc, ll
	tausq_ll = optimize(S)
	rc = optimize_result_returncode(S)	
	if(rc) exit(error(rc))
	ll = optimize_result_value(S)
	if(tausq_ll < 0) ll = sum(lnnormalden(yi, eff, sqrt(vi)))

	return(ll - crit)
}

real scalar ML_skov(real scalar b, real colvector yi, real colvector vi, real colvector wi, real rowvector params, real scalar crit, real rowvector iteropts, string scalar hmethod, string scalar technique) {

	// unpack iteropts and params
	real scalar maxtausq, itol, maxiter
	maxtausq = iteropts[1]
	itol     = iteropts[2]
	maxiter  = iteropts[3]
	
	// unpack params (ML values of eff, tausq, ll)
	real scalar eff, tausq, ll
	eff   = params[1]
	tausq = params[2]
	ll    = params[3]
	
	// maximize LL for fixed b
	transmorphic S
	S = optimize_init()
	optimize_init_evaluator(S, &ML_est())
	optimize_init_evaluatortype(S, "d2")
	optimize_init_params(S, tausq)
	optimize_init_argument(S, 1, yi)
	optimize_init_argument(S, 2, vi)
	optimize_init_argument(S, 3, b)
	optimize_init_technique(S, technique) 
	optimize_init_singularHmethod(S, hmethod)
	optimize_init_tracelevel(S, "none")
	
	real scalar tausq_b, rc, ll_b
	tausq_b = optimize(S)
	rc = optimize_result_returncode(S)
	if(rc) exit(error(rc))
	ll_b = optimize_result_value(S)
	if(tausq_b < 0) {
		tausq_b = 0
		ll_b = sum(lnnormalden(yi, b, sqrt(vi)))
	}
	
	real colvector wi_b
	wi_b = 1:/(vi:+tausq_b)
	
	// (unsigned, positive) likelihood statistic at b
	real scalar sll
	if (abs(ll_b - ll) <= itol) sll = 0		// in case ll, ll_b are very close (within itol) and rounding results in a negative value
	else {
	    sll = sqrt(2*(ll - ll_b))

		// calculate u for Skovgaard correction (always positive)
		real scalar u
		u = U(yi, wi, wi_b, eff, b)

		// Improved (Skovgaard-corrected) signed likelihood statistic
		if (callersversion()>=16.0) {	// make use of ln1p, for possible improvement in numerical stability when u very close to sll
			sll = sll + (1/sll)*ln1p( (sll-u) / (-sll))
		}
		else sll = sll + (1/sll)*ln(u/sll)
	}
	
	sll = sign(eff - b)*sll
	return(sll - crit)
}

real scalar U(real colvector yi, real colvector wi, real colvector wi_b, real scalar eff, real scalar b) {

	// Expected (I) & observed (J) information, evaluated at ML estimate
	real matrix Imat, Jmat
	Imat = Jmat = J(2, 2, 0)
	Imat[1,1] = Jmat[1,1] = sum(wi)
	Imat[2,2] = .5*quadcross(wi, wi)
	
	Jmat[1,2] =  Jmat[2,1] = quadcross(wi, yi:-eff, wi)
	Jmat[2,2] = -Imat[2,2] + quadcrossdev(yi, eff, wi:^3, yi, eff)
	
	// Observed (J) information under constraint eff = b, corresponding to tausq
	real scalar Jtsq
	Jtsq = -.5*quadcross(wi_b, wi_b) + quadcrossdev(yi, b, wi_b:^3, yi, b)

	// S and q
	real matrix S, Sinvq
	real colvector q
	S = (sum(wi_b), (eff-b)*quadcross(wi_b, wi_b) \ 0, .5*quadcross(wi_b, wi_b))
	q = ((eff-b)*sum(wi_b) \ -.5*sum(wi - wi_b))
	Sinvq = luinv(S)*q
	
	real scalar u
	u = abs(Sinvq[1,1]) * sqrt(abs(det(Jmat))) * abs(det(S)) / (sqrt(abs(Jtsq)) * abs(det(Imat)))
	return(u)
}



/* REML */
void REML(string scalar varlist, string scalar touse, real scalar hlevel, real rowvector iteropts, string scalar hmethod, string scalar technique)
{
	// setup
	real colvector yi, se, vi, wi
	varlist = tokens(varlist)
	st_view(yi=., ., varlist[1], touse)
	if(length(yi)==0) exit(error(2000))
	st_view(se=., ., varlist[2], touse)
	vi = se:^2
	wi = 1:/vi
	
	// Initialize
	real scalar eff0, tausq
	eff0 = mean(yi, wi)								// effect size with zero tausq
	tausq = max((0, quadvariance(yi) - mean(vi)))	// Initialize tausq using Hedges estimator	
	
	// Iterative tau-squared using REML
	transmorphic S
	S = optimize_init()
	optimize_init_evaluator(S, &REML_est())
	optimize_init_evaluatortype(S, "d0")
	optimize_init_params(S, tausq)
	optimize_init_argument(S, 1, yi)
	optimize_init_argument(S, 2, vi)
	optimize_init_technique(S, technique) 
	optimize_init_singularHmethod(S, hmethod)
	optimize_init_tracelevel(S, "none")
	
	real scalar rc, ll
	tausq = optimize(S)
	rc = optimize_result_returncode(S)	
	if(rc) exit(error(rc))
	ll = optimize_result_value(S)
	if(tausq < 0) {
		tausq = 0
		st_numscalar("r(ll_negtsq)", ll)		
		ll = sum(lnnormalden(yi, eff0, sqrt(vi))) - 0.5*ln(sum(wi))
	}
	
	st_numscalar("r(tausq)", tausq)
	st_numscalar("r(converged)", optimize_result_converged(S))
	st_numscalar("r(ll)", ll)

	// Variance of tausq (using inverse Fisher information)
	real scalar tsq_var
	tsq_var = optimize_result_V(S)
	st_numscalar("r(tsq_var)", tsq_var)

	// Confidence interval for tausq using likelihood profiling
	real scalar maxtausq, itol, maxiter, crit
	maxtausq = iteropts[1]
	itol     = iteropts[2]
	maxiter  = iteropts[3]
	crit = ll - (invchi2(1, hlevel/100)/2)
	
	real scalar tsq_lci, rc_tsq_lci, tsq_uci, rc_tsq_uci
	rc_tsq_lci = mm_root(tsq_lci=., &REML_profile_tausq(), 0, tausq - itol, itol, maxiter, yi, vi, crit)
	st_numscalar("r(tsq_lci)", tsq_lci)
	st_numscalar("r(rc_tsq_lci)", rc_tsq_lci)

	rc_tsq_uci = mm_root(tsq_uci=., &REML_profile_tausq(), tausq + itol, 10*maxtausq, itol, maxiter, yi, vi, crit)
	st_numscalar("r(tsq_uci)", tsq_uci)
	st_numscalar("r(rc_tsq_uci)", rc_tsq_uci)
}

void REML_est(todo, tausq, yi, vi, lnf, S, H) {
	real colvector wi
	real scalar eff
	tausq = max((0, tausq))
	wi = 1:/(vi:+tausq)
	eff = mean(yi, wi)
	lnf = sum(lnnormalden(yi, eff, sqrt(vi:+tausq))) - 0.5*ln(sum(wi))
	
	// Note: using d2debug reveals discrepancy in the Hessian using my formulae below
	//  not sure if I've done it correctly, so using d0 instead (as do -metaan- and -metareg- to be fair)
	// if(todo>=1) {
	// 	S = -0.5*sum(wi) + 0.5*mean(wi, wi) + 0.5*quadcrossdev(yi, eff, wi:^2, yi, eff)
	// 	if(todo>=2) {
	// 		H = 0.5*quadcross(wi, wi) - mean(wi:^2, wi) + 0.5*(mean(wi, wi)^2) - quadcrossdev(yi, eff, wi:^3, yi, eff)
	// 	}
	// }
}

real scalar REML_profile_tausq(real scalar tausq, real colvector yi, real colvector vi, real scalar crit) {
	real colvector wi
	real scalar eff, ll
	tausq = max((0, tausq))
	wi = 1:/(vi:+tausq)
	eff = mean(yi, wi)
	ll = sum(lnnormalden(yi, eff, sqrt(vi:+tausq))) - 0.5*ln(sum(wi))
	return(ll - crit)
}


/* Confidence interval for tausq estimated using approximate Gamma distribution for Q */
/* based on paper by Biggerstaff and Tweedie (Stat Med 1997; 16: 753-768) */
// Point estimate of tausq is simply the D+L estimate
void BTGamma(string scalar varlist, string scalar touse, string scalar wtvec, real scalar hlevel, real rowvector iteropts)
{
	// Setup
	real colvector yi, se, vi, wi
	varlist = tokens(varlist)
	st_view(yi=., ., varlist[1], touse)
	if(length(yi)==0) exit(error(2000))
	st_view(se=., ., varlist[2], touse)
	vi = se:^2
	wi = 1:/vi

	real scalar maxtausq, itol, maxiter, quadpts
	maxtausq = iteropts[1]
	itol = iteropts[2]
	maxiter = iteropts[3]
	quadpts	= iteropts[4]

	// Estimate variance of tausq
	real scalar k, eff, Q, c, d, tausq_m, tausq, Q_var, tsq_var
	k = length(yi)
	eff = mean(yi, wi)					// I-V common-effect estimate
	Q = crossdev(yi, eff, wi, yi, eff)	// standard Q heterogeneity statistic
	c = sum(wi) - mean(wi,wi)			// c = S1 - (S2/S1)
	d = cross(wi,wi) - 2*mean(wi:^2,wi) + (mean(wi,wi)^2)
	tausq_m = (Q - (k-1))/c				// untruncated D+L tausq

	// Variance of Q and tausq (based on untruncated tausq)
	Q_var = 2*(k-1) + 4*c*tausq_m + 2*d*(tausq_m^2)
	tsq_var = Q_var/(c^2)
	st_numscalar("r(tsq_var)", tsq_var)

	// Find confidence limits for tausq
	real scalar tsq_lci, rc_tsq_lci, tsq_uci, rc_tsq_uci
	rc_tsq_lci = mm_root(tsq_lci=., &Gamma_crit(), 0, maxtausq, itol, maxiter, tausq_m, k, c, d, .5 + hlevel/200)
	st_numscalar("r(tsq_lci)", tsq_lci)
	st_numscalar("r(rc_tsq_lci)", rc_tsq_lci)

	rc_tsq_uci = mm_root(tsq_uci=., &Gamma_crit(), tsq_lci + itol, 10*maxtausq, itol, maxiter, tausq_m, k, c, d, .5 - hlevel/200)
	st_numscalar("r(tsq_uci)", tsq_uci)
	st_numscalar("r(rc_tsq_uci)", rc_tsq_uci)
		
	// Find and return new weights
	real scalar EQ, VQ, lambda, r, se_eff
	EQ = (k-1) + c*tausq_m
	VQ = 2*(k-1) + 4*c*tausq_m + 2*d*(tausq_m^2)
	lambda = EQ/VQ
	r = lambda*EQ
	
	real colvector wsi
	real rowvector params
	real scalar i
	wsi = wi
	for(i=1; i<=k; i++) {
		params = (vi[i], lambda, r, c, k)
		wsi[i] = integrate(&BTIntgrnd(), 0, ., quadpts, params)
	}
	wi = wi*gammap(r, lambda*(k-1)) :+ wsi								// update weights
	st_store(st_viewobs(yi), wtvec, wi)									// write new weights to Stata
}

real scalar Gamma_crit(real scalar tausq, real scalar tausq_m, real scalar k, real scalar c, real scalar d, real scalar crit) {
	real scalar lambda, r, limit, ans
	lambda = ((k-1) + c*tausq)/(2*(k-1) + 4*c*tausq + 2*d*(tausq^2))
	r = ((k-1) + c*tausq)*lambda
	limit = lambda*(c*tausq_m + (k-1))
	ans = gammap(r, limit) - crit
	return(ans)
}

real rowvector BTIntgrnd(real rowvector t, real rowvector params) {
	real scalar s, lambda, r, c, k, ans
	s = params[1,1]				// vi[i] > 0
	lambda = params[1,2]		// lambda = E(Q)/Var(Q) [N.B. the inverse of this is used in Henmi & Copas]
	r = params[1,3]				// r = [E(Q)^2]/Var(Q)
	c = params[1,4]				// c = f(weights)
	k = params[1,5]				// k = no. studies > 1
	ans = (c:/(s:+t)) :* gammaden(r, 1/lambda, 1-k, c*t)
	return(ans)
}


/* Henmi and Copas method */
// Point estimate of tausq is simply the D+L estimate
void HC(string scalar varlist, string scalar touse, real scalar level, real rowvector iteropts)
{
	// Setup
	real colvector yi, se, vi, wi
	varlist = tokens(varlist)
	st_view(yi=., ., varlist[1], touse)
	if(length(yi)==0) exit(error(2000))
	st_view(se=., ., varlist[2], touse)
	vi = se:^2

	real scalar itol, maxiter, quadpts
	itol = iteropts[1]
	maxiter = iteropts[2]
	quadpts = iteropts[3]

	real scalar k, eff, Q, W1, W2, W3, W4, tausq, VR, SDR
	k = length(yi)
	wi = 1:/vi
	eff = mean(yi, wi)							// I-V common-effect estimate
	Q = crossdev(yi, eff, wi, yi, eff)			// standard Q heterogeneity statistic
	W1 = sum(wi)
	W2 = mean(wi, wi)
	W3 = mean(wi:^2, wi)
	W4 = mean(wi:^3, wi)
	tausq = max((0, (Q - (k-1))/(W1 - W2)))		// truncated D+L
	VR = 1 + tausq*W2
	SDR = sqrt(VR)
	
	// Coefficients of 1 and (x^2) for the following functions:
	// EQ(x) = conditional mean of Q given R=x
	// VQ(x) = conditional variance of Q given R=x
	// finv(x) = inverse function of f(Q).
	// All three functions are linear combinations of 1 and (x^2),
	//   so all can be represented by a single function, f.
	real scalar aEQ, bEQ
	aEQ = (k - 1) + tausq*(W1 - W2) - (tausq^2)*(W3 - W2^2)/VR
	bEQ = (W3 - W2^2)*(tausq/VR)^2
	
	real scalar aVQ, bVQ
	aVQ = 2*(k - 1) + 4*tausq*(W1 - W2) + 2*(tausq^2)*(W1*W2 - 2*W3 + W2^2)
	aVQ = aVQ - 4*(tausq^2)*(W3 - W2^2)/VR
	aVQ = aVQ - 4*(tausq^3)*(W4 - 2*W2*W3 + W2^3)/VR
	aVQ = aVQ + 2*(tausq^4)*(1/VR^2)*(W3 - W2^2)^2
	
	bVQ = 4*(tausq^2)*((1/VR^2))*(W3 - W2^2)
	bVQ = bVQ + 4*(tausq^3)*(1/VR^2)*(W4 - 2*W2*W3 + W2^3)
	bVQ = bVQ - 2*(tausq^4)*2*(1/VR^3)*(W3 - W2^2)^2
	
	real scalar afinv, bfinv
	afinv = (k-1) - (W1/W2 - 1)
	bfinv = (W1/W2 - 1)

	real rowvector params
	params = (aEQ, bEQ, aVQ, bVQ, afinv, bfinv, SDR)
	
	// Find quantile of approximate distribution
	// (u_alpha/2 in Henmi & Copas)
	real scalar t, rc_t
	rc_t = mm_root(t=., &Eqn(), 0, 2, itol, maxiter, quadpts, level, params)
	if (rc_t > 0) exit(error(498))
	st_numscalar("r(crit)", SDR*t)
	
	// Find test statistic (u) and p-value
	real scalar u, p
	u = eff/sqrt((tausq*W2 + 1)/W1)
	p = 2*integrate(&HCIntgrnd(), abs(u)/SDR, 40, quadpts, (abs(u)/SDR, params))
	st_numscalar("r(p)", p)
	st_numscalar("r(u)", u)
}

// N.B. Integration should be from x to infinity,
//  but we only integrate up to 40 since the integrand's value is indistinguishable from zero at this point.
// To see this, note that the integrand is the product of a cumulative Gamma function ==> between 0 and 1
//  and a standard normal density which is indistinguishable from zero at ~40.
// (thanks to Ben Jann for pointing this out)
real scalar Eqn(real scalar x, real scalar quadpts, real scalar level, real rowvector params) {
	real scalar ans
	ans = integrate(&HCIntgrnd(), x, 40, quadpts, (x, params))
	return(ans - (.5 - level/200))
}

real rowvector HCIntgrnd(real rowvector r, real rowvector params) {
	real scalar t, aEQ, bEQ, aVQ, bVQ, afinv, bfinv, SDR
	t     = params[1]
	aEQ   = params[2]
	bEQ   = params[3]
	aVQ   = params[4]
	bVQ   = params[5]
	afinv = params[6]
	bfinv = params[7]
	SDR   = params[8]
	
	real rowvector ans
	ans = gammap((f(r*SDR, aEQ, bEQ):^2):/f(r*SDR, aVQ, bVQ), f(r/t, afinv, bfinv):/(f(r*SDR, aVQ, bVQ):/f(r*SDR, aEQ, bEQ))) :* normalden(r)
	if(t==0) ans = normalden(r)
	return(ans)
}

real rowvector f(real rowvector x, real scalar a, real scalar b) {
	return(a :+ b*(x:^2))
}

end




