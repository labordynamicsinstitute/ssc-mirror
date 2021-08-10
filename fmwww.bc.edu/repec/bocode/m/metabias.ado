*  version 2.1 of 5 January 2009
*  Modified regression test for funnel plot asymmetry in 2x2 tables
*  based on statistics of score test instead of Wald test.
*  Author: roger.harbord@bristol.ac.uk
*  Peters test (effect size on 1/N) added
*  updates added by Ross Harris

*! version 3.0  David Fisher  09jul2020
*! Previous versions by Ross Harris and Roger Harbord

// Release notes DF 2020:
// - Minimal changes to interface with updated -metan- v4.00
// - Also taken the opportunity to streamline / modernise the code structure in places.


program define metabias, rclass byable(onecall)
	version 9.2
	
	syntax varlist(min=2 max=4 numeric) [if] [in] ///
	  [, or rr EGGer BEGg PETers HARbord CC(passthru) noFit Graph * ]
	marksample touse
	
	// error traps for method and data combinations
	opts_exclusive `"`or' `rr'"' `""' 184
	local measure `or'`rr'
	opts_exclusive `"`egger' `begg' `harbord' `peters'"' `""' 184
	local test `egger'`begg'`harbord'`peters'

	// check variables given and assign data_type
	tokenize `varlist'
	if "`4'" == "" {
		if "`2'" == "" | "`3'" != "" {
			di as err `"Must specify variables as either {it:theta se_theta} or as binary data"'
			exit 198
		}
		args theta se_theta
		di ""
		di as text "Note: data input format " as res `"{it:theta se_theta}"' as text " assumed"

		if inlist("`test'", "peters", "harbord") {
			di as err `"Peters and Harbord tests cannot be used with data format {it:theta se_theta}"'
			di as err "Egger test is recommended"
			exit 198
		}
		else if "`test'"=="" {
			di as err `"Must specify test: {bf:egger} or {bf:begg}"'
			di as err `"(Peters and Harbord tests cannot be used with data format {it:theta se_theta})"'
			di as err "Egger test is recommended"
			exit 198
		}
	}
	
	// binary data
	else {
		args a b c d
		/* Args in same order as -metan-, i.e.:  */
		/* a = Treatment group, event */
		/* b = Treatment group, no event */
		/* c = Control group, event */
		/* d = Control group, no event */
		di ""
		di as text "Note: data input format " as res `"{it:tcases tnoncases ccases cnoncases}"' as text " assumed"

		if "`test'"=="" {
			di as err `"Must specify test: {bf:egger}, {bf:begg}, {bf:peters} or {bf:harbord}"'
			exit 198
		}

		// default effect measure
		if "`measure'"=="" {
			di as text "Note: " as res "Odds ratios" as text " assumed as effect estimate of interest"
			local measure or
		}
		else {
			if "`measure'"=="or" local meastext "Odds ratios"
			else local meastext "Relative risks"
			di as text "Note: " as res "`meastext'" as text " specified as effect estimate of interest"		
		}
		
		if inlist("`test'", "egger", "begg") {
			di as text "Note: Peters or Harbord tests generally recommended for binary data"
			
			// change to theta se_theta, accounting for zero cells if appropriate
			tempvar theta se_theta
			qui cap metan `a' `b' `c' `d' if `touse', `measure' nograph nooverall notable
			if _rc {
				di as error "User-written package -metan- required but not found -"
				di as error "Please install, e.g. by typing -ssc install metan-"
				exit 111  // something not found - a command in this case 
			}
			
			// if -metan- v3 or below
			if "`r(metan_version)'"=="" {
				if "`cc'"!="" {
					di as err `"option {bf:`cc'} cannot be used with {bf:metan} version 3 or below"'
					exit 198
				}			
				qui gen `theta' = ln(_ES) if `touse'
				qui gen `se_theta' = _selogES if `touse'
				qui drop _SS _ES _selogES _LCI _UCI _WT
			}
			
			// if -metan- v4 or above
			else {
				if "`cc'"!="" {		// if user-specified cc option
					qui metan `a' `b' `c' `d' if `touse', `measure' `cc' nograph nooverall notable
				}
				rename _ES `theta'
				rename _seES `se_theta'
				qui drop _LCI _UCI _WT _NN
			}
			
			local varlist `theta' `se_theta'
		}
	
		/// RJH
		// (this check is done by -metan- if Egger or Begg; see above)
		else {
			capture assert `a'>=0 & `b'>=0 & `c'>=0 & `d'>=0 if `touse'
			if _rc {
				di as error "All cell counts must be >=0"
				exit 459 // something that should be true of your data is not
			}
		}
			
		/* Added by RMH in v2.1 */
		qui count if  ( `a'+`c'==0 | `b'+`d'==0 | `a'+`b'==0 | `c'+`d'==0 ) & `touse'
		if r(N) {
			local ies ies
			if r(N) == 1 local ies y
			di as txt "Note: excluding " as res r(N) as text " non-informative stud`ies' with a zero marginal total"
		}
	}
	
	/* don't allow RR with Peters as unsure of weights */
	if "`rr'" != "" & "`peters'" != ""{
		di as error "Cannot use Peters test for risk ratios - appropriate weights not known"
		exit 198
	}

	if _by() {
		if "`graph'" != "" {
			di as err `"option {bf:graph} may not be combined with the {bf:by:} prefix"'
			exit 198
		}
		local by "by `_byvars' `_byrc0':"
	}
	
	if inlist("`test'", "egger", "harbord") {
		`by' egger_harbord `varlist' if `touse', test(`test') measure(`measure') `graph' `fit' `options'
	}
	else {
		local proper = strproper("`test'")
		if "`graph'"!="" {
			di as err `"option {bf:graph} cannot be used with `proper' test"'
			exit 198
		}
		if "`fit'"!="" {
			di as err `"option {bf:nofit} cannot be used with `proper' test"'
			exit 198
		}
	
		`by' `test' `varlist' if `touse', measure(`measure')
	}
	
	return add
	
end
	
	
	

*********** TESTS ***********

******************************************************
	// original Egger test, and modified Harbord test
******************************************************

// Note: David Fisher, Nov 2019
// These tests are very similar to each other

program define egger_harbord, rclass byable(recall)

	syntax varlist(min=2 max=4) [if] [in] [, TEST(name) MEASURE(name) LEVEL(real 95) z(name) v(name) noFit Graph * ]
	marksample touse
	
	tokenize `varlist'
	if "`3'"!="" {
		cap {
			assert "`4'"!=""
			assert "`test'"=="harbord"
		}
		if _rc exit 198
		args a b c d
 
		di as text _n "Harbord's modified test for small-study effects: "
		di as text   `"Regress {it:Z}{bf:/sqrt(}{it:V}{bf:)} on {bf:sqrt(}{it:V}{bf:)}, "' _c
		di as text   `"where {it:Z} is the efficient score and {it:V} is the score variance"' _n

		qui {
			tempvar n V Z
			gen `n' = `a' + `b' + `c' + `d' if `touse'

			// RJH added rr, use or as default (checked previously that not both)
			if "`measure'"=="rr" {
				gen `V' = ((`c'+`d')*(`a'+`b')*(`a'+`c')) / (`n'*(`b'+`d')) if `touse'
				gen `Z' = (`a'*`n' - (`a'+`c')*(`a'+`b')) /      (`b'+`d')  if `touse'
			}
			
			// Odds ratio
			else {
				gen `V' = (`a'+`b')*(`c'+`d')*(`a'+`c')*(`b'+`d') / ( (`n')^2 * (`n'-1) ) if `touse'
				gen `Z' = (`a'*`d' - `b'*`c') / `n' if `touse'
			}
			
			tempvar y x		// `ZoverrootV' `rootV'
			gen `x' = sqrt(`V') if `touse'
			gen `y' = `Z'/`x' if `touse'
			local yvarlab "Z / sqrt(V)"
			local xvarlab "sqrt(V)"
		}
		
		local beta "sqrt(V)"
		local cons bias	
		local mnames `beta' `cons'
		local depname "Z/sqrt(V)"
	}
	
	else {
		cap {
			assert "`2'"!=""
			assert "`test'"=="egger"
		}
		if _rc exit 198
		args theta se_theta

		di as text _n "Egger's test for small-study effects:"
		di as text    "Regress standard normal deviate of intervention"
		di as text    "  effect estimate against its standard error" _n

		qui {
			tempvar y x			// `snd' `prec'
			qui gen `y' = `theta' / `se_theta'
			qui gen `x' = 1 / `se_theta'
			local yvarlab "SND of effect estimate"
			local xvarlab "Precision"
		}
		
		local beta slope
		local cons bias	
		local mnames `beta' `cons'
		local depname Std_Eff		
	}
		
	tempname pbias rmse
	qui regress  `y' `x' if `touse', level(`level')
	scalar `pbias' = 2*ttail( e(df_r), abs(_b[_cons]/_se[_cons]) )
	scalar `rmse' = e(rmse)
	return scalar rmse = e(rmse)
	return scalar p_bias = `pbias'
	return scalar se_bias = _se[_cons]
	return scalar bias = _b[_cons]
	return scalar df_r = e(df_r)
	return scalar N = e(N)
	
	// Now rename row/colnames of e(b) and e(V) and use -ereturn post-
	tempname vcov b
	matrix define `vcov' = e(V)
	matrix define `b' = e(b)
	matrix colnames `vcov' = `mnames'
	matrix rownames `vcov' = `mnames'
	matrix colnames `b' = `mnames'
	
	ereturn post `b' `vcov', depname("`depname'") dof(`e(df_r)') obs(`e(N)')
	/* maybe prefer z-test?  In which case don't post dof. */
	
	nois disp e(rmse)
	di as txt "Number of studies = ", as res e(N) _c
	di as txt _col(55) " Root MSE      = ", as res %6.0g `rmse'
	ereturn display, level(`level')
	di as text _n  "Test of H0: no small-study effects" _col(45) "P = " as res %5.3f `pbias'
	
	if "`graph'" == "" {
		if "`options'" != "" {
			di as err `"option {bf:`options'} not allowed"'
			exit 198
		}
	}
	else {
		tempvar fitted lci uci
		tempname cihw
		scalar `cihw' = _se[`cons'] * invttail( e(df_r), (1-`level'/100)/2 )
		if "`fit'" != "nofit" {
			nobreak {
				quietly {
					preserve
						set obs `= _N + 1'
						replace `x' = 0 in l
						gen `lci' = _b[`cons'] - `cihw' in l
						gen `uci' = _b[`cons'] + `cihw' in l
						gen `fitted' = _b[`cons'] + _b[`beta']*`x' if `touse'
						
						twoway ( scatter `y' `x', ///
							ytitle(`"`yvarlab'"') xtitle(`"`xvarlab'"') ///
							yline(0, lc(fg)) yla(-2 0 2) `options' ) ///
							( line `fitted' `x', sort clsty(p2) ) ///
							( rcap `lci' `uci' `x', msize(*2) blsty(p2) ) ///
							, legend(label(1 "Study") label(2 "regression line") ///
							label(3 "`level'% CI for intercept") order(1 2  - " " 3))
					restore
				}
			}
		}
		else {  // nofit
			twoway scatter `y' `x', yline(0, lc(fg)) ///
				ytitle(`"`yvarlab'"') xtitle(`"`xvarlab'"') `options'
		}
	}
	
	/* output Z & V if requested */
	if "`test'"=="harbord" {
		if "`z'"!="" & _bylastcall() {
			rename `Z' `z'
			label variable `z' "Efficient score"
		}
		if "`v'"!="" & _bylastcall() {
			rename `V' `v'
			label variable `v' "Fisher's information"
		}
	}
	
end




*****************************************
	// RJH added- Peter's test
*****************************************

program define peters, rclass byable(recall)

	syntax varlist(min=4 max=4) [if] [in] [, MEASURE(string) LEVEL(real 95) noFit Graph ]
	marksample touse
	tokenize `varlist'
	args a b c d

	tempvar theta ovN wgt prec_lnodds
	if "`measure'"=="rr" {
		di as text "Note: test is formulated in terms of odds ratios" _n ///
			   "      but should give valid results for risk ratios"
		qui gen `theta' = ln( (`a'/(`a'+`b')) / (`c'/(`c'+`d')) ) if `touse'
	}
	else {
		qui gen `theta' = ln( (`a'/`b') / (`c'/`d') ) if `touse'
	}
	gen `ovN' = 1/(`a'+`b'+`c'+`d') if `touse'
	gen `wgt' = (`a'+`c')*(`b'+`d')/(`a'+`b'+`c'+`d')
	// from http://www.rss.org.uk/pdf/Jaime%20Peters%20Presentation.pdf
	// weight is the same- should weight be different for RR?
	*	gen `prec_lnodds'= 1/(1/(`se'+`sc') + 1/(`fe'+`fc'))

	di as text _n "Peter's test for small-study effects:"
	di as text `"Regress intervention effect estimate on {bf:1/}{it:Ntot}, with weights {it:S}{bf:×}{it:F}{bf:/}{it:Ntot}"' _n

	tempname pbias rmse
	qui regress `theta' `ovN' [aweight=`wgt'], noheader
	scalar `pbias' = 2*ttail( e(df_r), abs(_b[`ovN']/_se[`ovN']) )
	scalar `rmse' = e(rmse)
	return scalar rmse = e(rmse)
	return scalar p_bias = `pbias'
	return scalar se_bias = _se[`ovN']
	return scalar bias = _b[`ovN']
	return scalar df_r = e(df_r)
	return scalar N = e(N)

	tempname vcov b
	matrix define `vcov' = e(V)
	matrix define `b' = e(b)
	matrix colnames `b' = bias constant
	matrix rownames `vcov' = bias constant
	matrix colnames `vcov' = bias constant
	ereturn post `b' `vcov', depname(Std_Eff) dof(`e(df_r)') obs(`e(N)')
	
	di as txt "Number of studies = " as res e(N) _c
	di as txt _col(55) " Root MSE      = " as res %6.0g `rmse'
	ereturn display, level(`level')

	di as text _n  "Test of H0: no small-study effects" _col(45) "P = " as res %5.3f `pbias'
	
end




*****************************************
	// RJH added- Begg test
*****************************************

program define begg, rclass byable(recall)

	syntax varlist(min=2 max=2) [if] [in] [, LEVEL(real 95) noFit Graph ]
	marksample touse
	tokenize `varlist'
	args theta se_theta
	
	if "`graph'"!="" {
		di as err "option {bf:graph} cannot be used with Begg test"
		exit 198
	}
	if "`fit'"!="" {
		di as err "option {bf:nofit} cannot be used with Begg test"
		exit 198
	}

	quietly {
		tempvar var w
		gen  `var' = `se_theta'^2 if `touse'
		gen  `w'   = 1 / `var'    if `touse'

		tempvar vt wtheta
		tempname sw
		summ `w' if `touse', meanonly
		scalar `sw' = r(sum)
		gen  `vt'      = `var' - 1/`sw' if `touse'
		gen  `wtheta'  = `w' * `theta'  if `touse'

		tempvar Ts wl
		tempname oe
		summ `wtheta' if `touse', meanonly
		gen  `Ts' = (`theta' - `r(sum)'/`sw') / sqrt(`vt') if `touse'
		gen  `wl' = `w' * `theta' if `touse'		
		summ `wl' if `touse', meanonly
		scalar `oe' = r(sum) / `sw'

    } 	// end quietly
	
	capture ktau2 `var' `Ts' if `touse'
	if _rc & _rc != 2001 {
		di as err "error " _rc `" in call to {bf:ktau2}"'
		exit _rc
	}

    di _n as text "Begg's test for small-study effects:"
    di    as text "Rank correlation between standardized intervention effect and its standard error"
    di    as text " "
    di    as text "  adj. Kendall's Score (P-Q) = " as res %7.0f r(ks)
    di _c as text "          Std. Dev. of Score = " as res %7.2f r(se_ks)
    if r(c) == 1 { 
	di    as text " (corrected for ties)" 
	}
    else {
		di " "
	}
    di    as text "           Number of Studies = " as res %7.0f r(N)
    di    as text "                          z  = " as res %7.2f r(z)
    di    as text "                    Pr > |z| = " as res %7.3f r(p)
    di _c as text "                          z  = " as res %7.2f r(zcc)
    di    as text " (continuity corrected)"
    di _c as text "                    Pr > |z| = " as res %7.3f r(pcc)
    di    as text " (continuity corrected)"

	return scalar p_bias_ncc = r(p)
	return scalar p_bias   = r(pcc)
	return scalar score_sd = r(se_ks)
	return scalar score    = r(ks)
	return scalar N        = r(N)

end




****************************************************
* 	ktau program from original metabias -RJH	   *
****************************************************

*  version 4.1.0  26sep97 TJS
*  modification of ktau to allow N==2, un-continuity-corrected
*  z and p values, and to pass more parameters
program define ktau2, rclass sortpreserve
	version 9.0
	
	syntax varlist(min=2 max=2) [if] [in]
	marksample touse
	tokenize `varlist'
	args x y
	
	quietly count if `touse'
	local N = r(N)
	if `N' < 2 {
		exit 2001
	}

	quietly {
		replace `touse' = 1 - `touse'
		sort `touse'  /* put obs for computation first */
		replace `touse' = 1 - `touse'

		tempvar work
		gen double `work' = 0  /* using type double is fastest */
		local k = 2
		while (`k' <= `N') {
			local kk = `k' - 1
			replace `work' = `work' + sign((`x' - `x'[`k'])*(`y' - `y'[`k'])) in 1 / `kk'		/* using "in" is fastest */
			local ++k
		}
		replace `work' = sum(`work') if `touse'

		tempname ks
		scalar `ks' = `work'[`N']
		
		/* Calculate ties on `x' */
		tempvar nobs
		egen long `nobs' = count(`x') if `touse', by(`x')
		summ `nobs', meanonly
		local nobsxm = r(max)

		/* Calculate correction term for ties on `x' */
		tempname xt
		replace `work' = sum((`nobs' - 1)*(2*`nobs' + 5)) if `touse'
		scalar `xt' = `work'[`N']
		
		/* Calculate correction term for pairs of ties on `x' */
		tempname xt2
		replace `work' = sum(`nobs' - 1) if `touse'
		scalar `xt2' = `work'[`N']
		
		/* Calculate correction term for triplets of ties on `x' */
		tempname xt3
		replace `work' = sum((`nobs' - 1)*(`nobs' - 2)) if `touse'
		scalar `xt3' = `work'[`N']
		
		/* Calculate ties on `y' */
		drop `nobs' 
		egen long `nobs' = count(`y') if `touse', by(`y')
		summ `nobs', meanonly
		local nobsym = r(max)
		
		/* Calculate correction term for ties on `y' */
		tempname yt
		replace `work' = sum((`nobs' - 1)*(2*`nobs' + 5)) if `touse'
		scalar `yt' = `work'[`N']
		
		/* Calculate correction term for pairs of ties on `y' */
		tempname yt2
		replace `work' = sum(`nobs' - 1) if `touse'
		scalar `yt2' = `work'[`N']
		
		/* Calculate correction term for triplets of ties on `y' */
		tempname yt3
		replace `work' = sum((`nobs' - 1)*(`nobs' - 2)) if `touse'
		scalar `yt3' = `work'[`N']
	
	}	// end quietly
	
	/* Compute Kendall's tau-a, tau-b, s.e. of score, and pval */
	tempname NN tau_a tau_b se_ks
	scalar `NN'    = `N'*(`N' - 1)
	scalar `tau_a' = 2*`ks'/`NN'
	scalar `tau_b' = 2*`ks'/sqrt((`NN' - `xt2')*(`NN' - `yt2'))
	scalar `se_ks' = `NN'*(2*`N' + 5)
	
	if max(`nobsxm', `nobsym') > 1 {
		scalar `se_ks' = `se_ks' - (`xt' - `yt') + `xt3'*`yt3'/(9*`NN'*(`N' - 2)) + `xt2'*`yt2'/(2*`NN')
	}
	scalar `se_ks' = sqrt(`se_ks' / 18)

	tempname z zcc
	scalar `z' = `ks '/ `se_ks'
	scalar `zcc' = (abs(`ks') - 1) / `se_ks'
	
	tempname p pcc
	if `ks' == 0 {
		scalar `p' = 1
		scalar `pcc' = 1
	}
	else {
		scalar `p'   = 2*(1 - normal( abs(`ks')     / `se_ks'))
		scalar `pcc' = 2*(1 - normal((abs(`ks') - 1)/ `se_ks'))
	}
	
	/* Print results */
	di _n as text "  Number of obs = " as res  %7.0f `N'
	di    as text "Kendall's tau-a = " as res %12.4f `tau_a'
	di    as text "Kendall's tau-b = " as res %12.4f `tau_b'
	di    as text "Kendall's score = " as res  %7.0f `ks'
	di    as text "    SE of score = " as res %11.3f `se_ks' _c
	
	if `xt2' > 0 | `yt2' > 0 {
		di as text "   (corrected for ties)" _c
	}
	
	di _n(2) as text "Test of H0: `x' and `y' independent"
	di       as text "             z  = " as res %12.2f `z'
	di       as text "       Pr > |z| = " as res %12.4f = `p'
	di ""
	di as text "             z  = " as res %12.2f sign(`ks')*`zcc'
    di as text "       Pr > |z| = " as res %12.4f = `pcc' as text "  (continuity corrected)"

	local c = 0
	if `xt2' > 0 | `yt2' > 0 local c = 1

	return scalar N    = `N'
	return scalar tau_a = `tau_a'
	return scalar tau_b = `tau_b'
	return scalar ks   = `ks'
	return scalar se_ks = `se_ks'
	return scalar p = `p'
	return scalar z = `z'
	return scalar pcc = `pcc'
    return scalar zcc = `zcc'
	return scalar c   = `c'

end



