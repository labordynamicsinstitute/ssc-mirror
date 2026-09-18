*! 1.00 Ariel Linden 06Sep2026 // Longitudinal MMWS for time-varying binary treatments

program mmwsl, rclass
version 11.0

	/* obtain settings */
	syntax varlist(min=1 max=1 numeric) [if] [in], 			///
	PANELvar(varname) 										/// panel (subject) identifier
	TIMEvar(varname numeric) 								/// wave identifier, common across panels
	COVariates(varlist fv) 									/// propensity-model predictors, same set every wave
	[ NOMinal												/// treatment has more than two nominal (unordered) levels
	NSTRata(numlist min=1 max=1 int) 						/// strata per subgroup (pstrata chooses if omitted)
	SMAX(integer 50) 										/// max strata to try when nstrata() is omitted (passed to pstrata)
	SMDlevel(real 0.25) 									/// max pairwise-SMD balance threshold when nstrata() is omitted
	NMIN(integer 1) 										/// min observations per stratum/level cell (passed to mmws's nmin())
	PRObit 													/// probit instead of logit for the ps models (binary treatments only)
	COMMon 													/// common support within each wave/history-subgroup cell
	IPTW 													/// also accumulate a longitudinal stabilized IPTW product
	GAPreport 												/// full detail on panelvar/timevar gaps (default: one summary line)
	EXclreport 												/// wave-by-wave detail on exclusions (default: one summary line)
	REPLace PREfix(str) ]

	gettoken treat : varlist

	local auto = ("`nstrata'" == "")
	if !`auto' {
		if `nstrata' < 1 {
			di as err "nstrata() must be a positive integer"
			exit 198
		}
	}
	if `nmin' < 1 {
		di as err "nmin() must be a positive integer"
		exit 198
	}
	if `smax' < 1 {
		di as err "smax() must be a positive integer"
		exit 198
	}
	if `smdlevel' <= 0 {
		di as err "smdlevel() must be a positive number"
		exit 198
	}
	if "`nominal'" != "" & "`probit'" != "" {
		di as err "probit not allowed with nominal (mprobit not implemented)"
		exit 198
	}

quietly {

	marksample touse, novarlist
	markout `touse' `panelvar' `timevar'
	count if `touse'
	if r(N) == 0 error 2000

	if "`replace'" != "" {
		local mmwsl : char _dta[`prefix'_mmwsl]
		if "`mmwsl'" != "" {
			foreach v of local mmwsl {
				capture drop `v'
			}
		}
		capture drop `prefix'_mmws
		capture drop `prefix'_restart
		capture drop `prefix'_fallback
		capture drop `prefix'_nstrata
		capture drop `prefix'_iptw
		capture drop `prefix'_iptw_restart
	}

	tempvar dup
	duplicates tag `panelvar' `timevar' if `touse', gen(`dup')
	count if `touse' & `dup' > 0
	if r(N) > 0 {
		levelsof `panelvar' if `touse' & `dup' > 0, local(baddup)
		di as err "`panelvar'/`timevar' do not uniquely identify observations"
		di as err "affected `panelvar': `baddup'"
		exit 459
	}

	* Validate the treatment variable
	if "`nominal'" == "" {

		capture assert inlist(`treat', 0, 1) if `touse' & !missing(`treat')
		if _rc {
			di as err "`treat' must be 0/1; specify nominal for >2 levels"
			exit 450
		}
		local K = 2

	}
	else {

		qui count if (trunc(`treat') != `treat' | `treat' < 0) & `touse' & !missing(`treat')
		if r(N) > 0 {
			di as err "`treat' must contain nonnegative integers"
			exit 459
		}

		qui levelsof `treat' if `touse', local(alllevels)
		local K : word count `alllevels'

		if `K' < 2 {
			di as err "`treat' has only one level; not allowed"
			exit 459
		}
		if `K' > 20 {
			di as err "`treat' has `K' levels; maximum is 20"
			exit 459
		}

		tempvar treatrank
		egen `treatrank' = group(`treat') if `touse'
		replace `treatrank' = `treatrank' - 1

	}

	levelsof `timevar' if `touse', local(waves)
	local T : word count `waves'

	* Report how irregular the panel is
	preserve

	keep if `touse'
	fillin `panelvar' `timevar'

	count if _fillin
	local ngaprows = r(N)
	if `ngaprows' > 0 {
		tempvar anygap firstobsd
		bysort `panelvar' (`timevar'): gen byte `firstobsd' = _n==1
		bysort `panelvar': egen byte `anygap' = max(_fillin)
		count if `firstobsd'
		local npanels = r(N)
		count if `firstobsd' & `anygap'
		local ngappanels = r(N)

		if "`gapreport'" != "" {
			noisily di as txt _n "{hline 60}"
			noisily di as txt "`ngappanels'/`npanels' panels missing a wave of `timevar'"
			noisily di as txt "(`ngaprows' of `T' possible)"
			noisily di as txt "Gaps are not imputed; history/weight carry over the last observed wave."
			noisily di as txt "Dropout (missing `treat' at an observed wave) is handled separately."
			noisily di as txt "{hline 60}"
			noisily di as txt _n "Missing by `timevar':"
			noisily tab `timevar' if _fillin
			noisily di as txt _n "Affected combinations:"
			noisily list `panelvar' `timevar' if _fillin, sepby(`panelvar') noobs
		}
		else {
			noisily di as txt "`ngappanels'/`npanels' panels missing a wave of `timevar' (`ngaprows' gaps)"
			noisily di as txt "not treated as dropout. Specify gapreport for detail."
		}
	}

	restore

	tempvar misswave absorbwave stillin hist cum firstobs
	gen double `misswave' = `timevar' if `touse' & missing(`treat')
	bysort `panelvar': egen double `absorbwave' = min(`misswave')
	gen byte `stillin' = `touse' & (missing(`absorbwave') | `timevar' < `absorbwave')

	* hist must reflect each panel member's OWN realized treatment sequence through the prior wave
	bysort `panelvar' (`timevar'): gen double `hist' = 0 if `touse' & _n==1
	if "`nominal'" == "" {
		bysort `panelvar' (`timevar'): replace `hist' = ///
			`hist'[_n-1]*2 + `treat'[_n-1] if `touse' & _n>1
	}
	else {
		bysort `panelvar' (`timevar'): replace `hist' = ///
			`hist'[_n-1]*`K' + `treatrank'[_n-1] if `touse' & _n>1
	}
	gen double `cum' = .

	* Per-panel marker of each panel's own first observed row
	bysort `panelvar' (`timevar'): gen byte `firstobs' = (_n==1) if `touse'

	tempvar restart
	gen byte `restart' = .

	gen double `prefix'_mmws = .
	label var `prefix'_mmws "cumulative MMWS sequence weight through this wave"
	gen byte `prefix'_restart = .
	label var `prefix'_restart ///
		"1 if the MMWS chain restarted fresh this wave (prior weight was missing)"
	gen byte `prefix'_fallback = .
	label var `prefix'_fallback ///
		"1 if this wave's weight used marginal-rate substitution"
	gen int `prefix'_nstrata = .
	label var `prefix'_nstrata ///
		"strata used this wave/history-subgroup (nominal: mean across levels)"

	if "`iptw'" != "" {
		tempvar icum irestart
		gen double `icum' = .
		gen byte `irestart' = .
		gen double `prefix'_iptw = .
		label var `prefix'_iptw "cumulative stabilized IPTW sequence weight through this wave"
		gen byte `prefix'_iptw_restart = .
		label var `prefix'_iptw_restart ///
			"1 if the IPTW chain restarted fresh this wave (independent of `prefix'_restart)"
	}

	local totexcl = 0

	foreach t of local waves {

		tempvar keepw grp fb wavewt nstr
		gen byte `keepw' = `stillin' & `timevar'==`t'

		count if `keepw'
		if r(N) == 0 {
			continue
		}

		egen long `grp' = group(`hist') if `keepw'
		levelsof `grp' if `keepw', local(groups)

		if "`nominal'" == "" {
			tempvar ps
			gen double `ps' = .
		}
		else {
			local pslist ""
			forvalues k = 1/`K' {
				tempvar ps`k'
				gen double `ps`k'' = .
				local pslist "`pslist' `ps`k''"
			}
		}
		gen byte `fb' = .
		gen double `wavewt' = .
		gen int `nstr' = .
		if "`iptw'" != "" {
			tempvar waveiptw
			gen double `waveiptw' = .
		}

		foreach g of local groups {

			tempvar fitsamp
			gen byte `fitsamp' = `keepw' & `grp'==`g' & !missing(`treat')

			if "`nominal'" == "" {

				count if `fitsamp' & `treat'==1
				local n1 = r(N)
				count if `fitsamp' & `treat'==0
				local n0 = r(N)

				if `n1'==0 | `n0'==0 {
					local gexcl = `n1' + `n0'
					local totexcl = `totexcl' + `gexcl'
					if "`exclreport'" != "" {
						noisily di as txt "wave `t', group `g': `gexcl' excluded"
						noisily di as txt "-- no variation in `treat' (n1=`n1', n0=`n0')"
					}
					drop `fitsamp'
					continue
				}

				sum `treat' if `fitsamp', meanonly
				local pgrp = r(mean)

				if "`probit'" != "" {
					capture probit `treat' `covariates' if `fitsamp', iterate(100)
				}
				else {
					capture logit `treat' `covariates' if `fitsamp', iterate(100)
				}
				* capture here, before any other command can reset _rc
				local modelrc = _rc

				if `modelrc' {
					replace `ps' = `pgrp' if `keepw' & `grp'==`g'
					replace `fb' = 1 if `keepw' & `grp'==`g'
				}
				else {
					tempvar psg
					predict double `psg' if `keepw' & `grp'==`g', pr
					replace `ps' = `psg' if `keepw' & `grp'==`g'
					replace `fb' = 0 if `keepw' & `grp'==`g'

					count if `keepw' & `grp'==`g' & missing(`ps')
					if r(N) > 0 {
						replace `ps' = `pgrp' if `keepw' & `grp'==`g' & missing(`ps')
						replace `fb' = 1 if `keepw' & `grp'==`g' & missing(`ps')
					}
					drop `psg'
				}

				drop `fitsamp'

				if "`iptw'" != "" {
					replace `waveiptw' = cond(`treat'==1, `pgrp', 1-`pgrp') ///
						/ cond(`treat'==1, `ps', 1-`ps') if `keepw' & `grp'==`g'
				}

				if `modelrc' {
					* The propensity model failed to converge for this ENTIRE wave
					replace `wavewt' = 1 if `keepw' & `grp'==`g'
					replace `nstr' = 1 if `keepw' & `grp'==`g'
				}
				else {

					tempvar ip
					capture drop `ip'_mmws
					capture drop `ip'_strata
					capture drop `ip'_support
					capture drop `ip'strata1

					if `auto' {
						* pstrata auto-derives its own starting number of strata
						local pstrataopts pscore(`ps') smax(`smax') smdlevel(`smdlevel') prefix(`ip')
						if "`common'" != "" {
							local pstrataopts `pstrataopts' common
						}
						capture pstrata `treat' if `keepw' & `grp'==`g', `pstrataopts'
						if _rc {
							local pstrata_rc = _rc
							local gexcl = `n1' + `n0'
							local totexcl = `totexcl' + `gexcl'
							if "`exclreport'" != "" {
								noisily di as txt "wave `t', group `g' (n1=`n1', n0=`n0'): `gexcl' excluded"
								noisily di as txt "-- pstrata failed (error `pstrata_rc'); try nstrata()"
							}
							continue
						}
						local gnstrata = r(nstrata1)
						local mmwsopts pscore(`ps') strata(`ip'strata1) nmin(`nmin')
					}
					else {
						local gnstrata = `nstrata'
						local mmwsopts pscore(`ps') nstrata(`nstrata') nmin(`nmin')
					}
					if "`common'" != "" {
						local mmwsopts `mmwsopts' common
					}

					capture mmws `treat' if `keepw' & `grp'==`g', `mmwsopts' prefix(`ip')
					if _rc {
						local mmws_rc = _rc
						capture drop `ip'_mmws
						capture drop `ip'_strata
						capture drop `ip'_support
						capture drop `ip'strata1
						local gexcl = `n1' + `n0'
						local totexcl = `totexcl' + `gexcl'
						if "`exclreport'" != "" {
							noisily di as txt "wave `t', group `g' (n1=`n1', n0=`n0'): `gexcl' excluded"
							noisily di as txt "-- mmws failed with `gnstrata' strata (error `mmws_rc')"
						}
						continue
					}

					local gexcl = r(nexcluded)
					local totexcl = `totexcl' + `gexcl'
					if `gexcl' > 0 & "`exclreport'" != "" {
						noisily di as txt "wave `t', group `g' (n1=`n1', n0=`n0'): `gexcl' excluded"
						noisily di as txt "-- stratum lacked nmin() of both levels"
					}

					replace `wavewt' = `ip'_mmws if `keepw' & `grp'==`g'
					replace `nstr' = `gnstrata' if `keepw' & `grp'==`g'

					capture drop `ip'_mmws
					capture drop `ip'_strata
					capture drop `ip'_support
					capture drop `ip'strata1

				} // end else (modelrc)

			} // end binary
			else {

				* Nominal - same overall shape as the binary branch above
				count if `fitsamp'
				local nfit = r(N)

				levelsof `treat' if `fitsamp', local(glevels)
				local J : word count `glevels'

				if `J' < 2 {
					local gexcl = `nfit'
					local totexcl = `totexcl' + `gexcl'
					if "`exclreport'" != "" {
						noisily di as txt "wave `t', group `g': `gexcl' excluded"
						noisily di as txt "-- only `J' level(s) of `treat' present"
					}
					drop `fitsamp'
					continue
				}

				* Per-level marginal proportions within this subgroup
				foreach lv of local glevels {
					count if `fitsamp' & `treat'==`lv'
					local ngrp_`lv' = r(N)
					local pgrp_`lv' = `ngrp_`lv'' / `nfit'
				}

				capture mlogit `treat' `covariates' if `fitsamp', iterate(100)
				local modelrc = _rc

				* The ps`rank' variables
				local gpslist ""
				foreach lv of local glevels {
					local rank : list posof "`lv'" in alllevels
					local gpslist "`gpslist' `ps`rank''"
				}

				if `modelrc' {
					* Mirrors the binary fallback exactly
					foreach lv of local glevels {
						local rank : list posof "`lv'" in alllevels
						replace `ps`rank'' = `pgrp_`lv'' if `keepw' & `grp'==`g'
					}
					replace `fb' = 1 if `keepw' & `grp'==`g'
				}
				else {
					local predlist ""
					foreach lv of local glevels {
						tempvar pg`lv'
						local predlist "`predlist' `pg`lv''"
					}
					predict double `predlist' if `keepw' & `grp'==`g', pr

					forvalues i = 1/`J' {
						local lv : word `i' of `glevels'
						local pgi : word `i' of `predlist'
						local rank : list posof "`lv'" in alllevels
						replace `ps`rank'' = `pgi' if `keepw' & `grp'==`g'
					}
					replace `fb' = 0 if `keepw' & `grp'==`g'

					* A row whose OWN covariates are missing produces a missing prediction
					local lv1 : word 1 of `glevels'
					local rank1 : list posof "`lv1'" in alllevels
					count if `keepw' & `grp'==`g' & missing(`ps`rank1'')
					if r(N) > 0 {
						foreach lv of local glevels {
							local rank : list posof "`lv'" in alllevels
							replace `ps`rank'' = `pgrp_`lv'' ///
								if `keepw' & `grp'==`g' & missing(`ps`rank'')
						}
						replace `fb' = 1 if `keepw' & `grp'==`g' & missing(`ps`rank1'')
					}
					foreach v of local predlist {
						drop `v'
					}
				}

				drop `fitsamp'

				if "`iptw'" != "" {
					foreach lv of local glevels {
						local rank : list posof "`lv'" in alllevels
						replace `waveiptw' = `pgrp_`lv'' / `ps`rank'' ///
							if `keepw' & `grp'==`g' & `treat'==`lv''
					}
				}

				if `modelrc' {
					replace `wavewt' = 1 if `keepw' & `grp'==`g'
					replace `nstr' = 1 if `keepw' & `grp'==`g'
				}
				else {

					tempvar ip
					capture drop `ip'_mmws
					capture drop `ip'_support
					forvalues j = 1/`J' {
						capture drop `ip'strata`j'
						capture drop `ip'_strata`j'
					}

					if `auto' {
						local pstrataopts pscore(`gpslist') smax(`smax') smdlevel(`smdlevel') prefix(`ip')
						if "`common'" != "" {
							local pstrataopts `pstrataopts' common
						}
						capture pstrata `treat' if `keepw' & `grp'==`g', `pstrataopts'
						if _rc {
							local pstrata_rc = _rc
							* pstrata searches one pscore at a time
							forvalues j = 1/`J' {
								capture drop `ip'strata`j'
								capture drop `ip'_strata`j'
							}
							local gexcl = `nfit'
							local totexcl = `totexcl' + `gexcl'
							if "`exclreport'" != "" {
								noisily di as txt "wave `t', group `g' (`J' levels): `gexcl' excluded"
								noisily di as txt "-- pstrata failed (error `pstrata_rc'); try nstrata()"
							}
							continue
						}
						local gstratalist ""
						local gnstratatot = 0
						forvalues j = 1/`J' {
							local gstratalist "`gstratalist' `ip'strata`j'"
							local gnstratatot = `gnstratatot' + r(nstrata`j')
						}
						local gnstrata = round(`gnstratatot' / `J')
						local mmwsopts pscore(`gpslist') nominal strata(`gstratalist') nmin(`nmin')
					}
					else {
						local gnstrata = `nstrata'
						local gnstratalist ""
						forvalues j = 1/`J' {
							local gnstratalist "`gnstratalist' `nstrata'"
						}
						local mmwsopts pscore(`gpslist') nominal nstrata(`gnstratalist') nmin(`nmin')
					}
					if "`common'" != "" {
						local mmwsopts `mmwsopts' common
					}

					capture mmws `treat' if `keepw' & `grp'==`g', `mmwsopts' prefix(`ip')
					if _rc {
						local mmws_rc = _rc
						capture drop `ip'_mmws
						capture drop `ip'_support
						forvalues j = 1/`J' {
							capture drop `ip'strata`j'
							capture drop `ip'_strata`j'
						}
						local gexcl = `nfit'
						local totexcl = `totexcl' + `gexcl'
						if "`exclreport'" != "" {
							noisily di as txt "wave `t', group `g' (`J' levels): `gexcl' excluded"
							noisily di as txt "-- mmws failed with `gnstrata' strata (error `mmws_rc')"
						}
						continue
					}

					local gexcl = r(nexcluded)
					local totexcl = `totexcl' + `gexcl'
					if `gexcl' > 0 & "`exclreport'" != "" {
						noisily di as txt "wave `t', group `g' (`J' levels): `gexcl' excluded"
						noisily di as txt "-- stratum lacked nmin() of a required level"
					}

					replace `wavewt' = `ip'_mmws if `keepw' & `grp'==`g'
					replace `nstr' = `gnstrata' if `keepw' & `grp'==`g'

					capture drop `ip'_mmws
					capture drop `ip'_support
					forvalues j = 1/`J' {
						capture drop `ip'strata`j'
						capture drop `ip'_strata`j'
					}

				} // end else (modelrc, nominal)

			} // end nominal
		}

		* A panel member whose chain broke at an earlier wave is treated as newly entering the risk set
		replace `cum' = `wavewt' if `keepw' & `firstobs'
		replace `restart' = 0 if `keepw' & `firstobs'
		bysort `panelvar' (`timevar'): replace `restart' = ///
			missing(`cum'[_n-1]) if `keepw' & !`firstobs'
		bysort `panelvar' (`timevar'): replace `cum' = cond(`restart'==1, `wavewt', ///
			`cum'[_n-1] * `wavewt') if `keepw' & !`firstobs'
		replace `prefix'_mmws = `cum' if `keepw'
		replace `prefix'_restart = `restart' if `keepw'
		replace `prefix'_fallback = `fb' if `keepw'
		replace `prefix'_nstrata = `nstr' if `keepw'

		if "`iptw'" != "" {
			* IPTW's own chain restarts on ITS OWN missingness
			replace `icum' = `waveiptw' if `keepw' & `firstobs'
			replace `irestart' = 0 if `keepw' & `firstobs'
			bysort `panelvar' (`timevar'): replace `irestart' = ///
				missing(`icum'[_n-1]) if `keepw' & !`firstobs'
			bysort `panelvar' (`timevar'): replace `icum' = cond(`irestart'==1, `waveiptw', ///
				`icum'[_n-1] * `waveiptw') if `keepw' & !`firstobs'
			replace `prefix'_iptw = `icum' if `keepw'
			replace `prefix'_iptw_restart = `irestart' if `keepw'
		}

		if "`nominal'" == "" {
			drop `keepw' `grp' `ps' `fb' `wavewt' `nstr'
		}
		else {
			drop `keepw' `grp' `fb' `wavewt' `nstr'
			forvalues k = 1/`K' {
				drop `ps`k''
			}
		}
	}

	if `totexcl' > 0 {
		if "`exclreport'" == "" {
			noisily di as txt "`totexcl' observation(s) excluded for lack of a comparator (specify exclreport for detail)"
		}
		else {
			noisily di as txt "`totexcl' observation(s) excluded in total (see detail above)."
		}
	}

	local mmwsl `prefix'_mmws `prefix'_restart `prefix'_fallback `prefix'_nstrata ///
		`prefix'_iptw `prefix'_iptw_restart
	char def _dta[`prefix'_mmwsl] "`mmwsl'"

	ret scalar T = `T'
	ret scalar K = `K'
	ret scalar nexcluded = `totexcl'

} //end quietly

end
