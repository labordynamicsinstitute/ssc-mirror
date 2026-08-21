*! 4.0.0 Ariel Linden 12Aug2026 // added Cohen's f (omnibus) and pwcompare option to compute k-samples								  
*! 3.1.0 Ariel Linden 20Oct2025 // fixed bug in gettoken to deal with ","
								// added labels to table header (if value labels are available)
								// added reverse option to reverse sign of estimate (group order)
								// program now restores regression estimates so that user does not have to re-estimate regression
*! 3.0.1 Ariel Linden 20Mar2024 // added z-distribution option (default is t-distribution with noncentrality parameter)
*! 3.0.0 Ariel Linden 07Mar2024 // added Hedges g option
								// -esizereg- now uses variance produced by margins to compute pooled std. dev. 
*! 2.0.2 Ariel Linden 26Feb2024 // added -intreg-, -meintreg- and -metobit- models
*! 2.0.1 Ariel Linden 27Oct2021 // changed 'est' to a scalar to avoid issues with squaring negative values (which happens with local)
*! 2.0.0 Ariel Linden 29May2019 // made esizereg a postestimation command and converted version 1.0.0 to an immediate command (esizeregi)
*! 1.0.0 Ariel Linden 02Feb2019

								  

program define esizereg, rclass
version 11.0

			syntax varname, [COHensd HEDgesg Zdistribution LEVel(string) PWcompare]

			local treatvar `varlist'

			// if level() was typed, confirm it's numeric
			if "`level'" != "" {
				capture confirm number `level'
				if _rc {
					di as err "level() must be a number"
					exit 198
				}
			}

			// check for estimation results in memory
			if "`e(cmd)'" == "" {
				di as err "no estimation results found in memory"
				exit 301
			}

			// check that the model is a supported type
			local supported_display "regress tobit truncreg hetregress xtreg intreg meintreg metobit"
			capture local cmd2 "`e(cmd2)'"
			local ismeglm = ("`e(cmd)'" == "meglm") & inlist("`cmd2'", "meintreg", "metobit")
			if !inlist("`e(cmd)'", "regress", "tobit", "truncreg", "hetregress", "xtreg", "intreg") & !`ismeglm' {
				di as err "`e(cmd)' is not supported by {bf:esizereg}"
				di as err "supported estimation commands: `supported_display'"
				exit 198
			}
			qui estimates store esizereg_results

			// ---- default level() to the level actually used by the preceding model
			if "`level'" == "" {
				local level = c(level)
				local cmdline `"`e(cmdline)'"'
				if regexm(`"`cmdline'"', "[, ]level\(([0-9.]+)\)") {
					local level = regexs(1)
				}
			}

			local weightexp `e(wtype)' `e(wexp)'

			// group handling
			qui levelsof `treatvar' if e(sample), local(grp_vals)
			local num_groups : word count `grp_vals'

			if `num_groups' < 2 {
				di as err "{bf:`treatvar'} must have at least 2 distinct values"
				exit 420
			}

			local vallab : value label `treatvar'
			local i = 0
			foreach lv of local grp_vals {
				local ++i
				local grpval`i' "`lv'"
				local grouplabel`i' "`lv'"
				if "`vallab'" != "" {
					capture local lbl : label `vallab' `lv'
					if "`lbl'" != "" local grouplabel`i' "`lbl'"
				}
				qui count if `treatvar' == `lv' & e(sample)
				local n`i' = r(N)
			}

			tempname N
			scalar `N' = 0
			forvalues j = 1/`num_groups' {
				scalar `N' = `N' + `n`j''
			}

			// pooled/model SD via margins delta-method trick
			tempname V sdpooled
			if "`e(cmd)'" == "meglm" {
				qui margins, post predict(mu fixed)
			}
			else {
				qui margins, post
			}
			matrix `V' = r(V)
			scalar `V' = `V'[1,1]
			scalar `sdpooled' = sqrt(`V' * `N')

			// adjusted group means via margins
			qui estimates restore esizereg_results
			qui margins `treatvar', asobserved post
			tempname bmat grandmean
			matrix `bmat' = r(b)
			scalar `grandmean' = 0
			forvalues j = 1/`num_groups' {
				scalar `grandmean' = `grandmean' + (`n`j'' / `N') * `bmat'[1,`j']
			}

			// per-group d_j = (mean_j - grand mean) / pooled SD
			tempname alpha AlphaLower AlphaUpper CohenF
			scalar `alpha' = 1 - (`level'/100)
			scalar `AlphaLower' = `alpha'/2
			scalar `AlphaUpper' = 1 - (`alpha'/2)
			scalar `CohenF' = 0

			tempname m BiasCorrectionFactor
			scalar `m' = `N' - 2
			scalar `BiasCorrectionFactor' = exp(lngamma(`m'/2) - 1/2*ln(`m'/2) - lngamma((`m'-1)/2))

			forvalues j = 1/`num_groups' {
				tempname mean`j' d`j' se`j' lb`j' ub`j' g`j' glb`j' gub`j' nrest`j' ns`j'
				scalar `mean`j'' = `bmat'[1,`j']
				scalar `d`j'' = (`mean`j'' - `grandmean') / `sdpooled'
				scalar `CohenF' = `CohenF' + (`n`j''/`N') * `d`j''^2

				scalar `nrest`j'' = `N' - `n`j''
				scalar `se`j'' = sqrt(`N'/(`n`j''*`nrest`j'') + (`d`j''^2)/(2*`N'))

				if "`zdistribution'" != "" {
					tempname iz`j'
					scalar `iz`j'' = invnorm(1 - (1-`level'/100)/2)
					scalar `lb`j'' = `d`j'' - `iz`j''*`se`j''
					scalar `ub`j'' = `d`j'' + `iz`j''*`se`j''
				}
				else {
					tempname lolam`j' hilam`j'
					scalar `ns`j'' = sqrt((`n`j''*`nrest`j'')/`N')
					scalar `lolam`j'' = npnt(`m', `d`j''*`ns`j'', `AlphaUpper')
					scalar `hilam`j'' = npnt(`m', `d`j''*`ns`j'', `AlphaLower')
					scalar `lb`j'' = `lolam`j'' * sqrt(`N'/(`n`j''*`nrest`j''))
					scalar `ub`j'' = `hilam`j'' * sqrt(`N'/(`n`j''*`nrest`j''))
				}

				scalar `g`j'' = `d`j'' * `BiasCorrectionFactor'
				scalar `glb`j'' = `lb`j'' * `BiasCorrectionFactor'
				scalar `gub`j'' = `ub`j'' * `BiasCorrectionFactor'
			}
			scalar `CohenF' = sqrt(`CohenF')

			// display
			if "`cohensd'" == "" & "`hedgesg'" == "" {
				local cohensd cohensd
			}
			local esizelabel = cond("`hedgesg'" != "", "Hedges' g", "Cohen's d")

			if "`weightexp'" == "" {
				di _newline as text "K-group effect sizes based on adjusted group means (vs. pooled mean)"
				di "{hline 68}"
			}
			else {
				di _newline as text "{bf:Weighted} k-group effect sizes based on adjusted group means (vs. pooled mean)"
                di "{hline 78}"				
			}
			di as txt "Groups:  `treatvar'"
			forvalues j = 1/`num_groups' {
				di as txt "  `j'. `grouplabel`j''" _col(35) "N = " as res %6.0fc `n`j''
			}
			di "{hline 55}"				
			di as txt  "Cohen's {it:f} (omnibus)" _col(38) "= " as res %6.4f `CohenF'
			// equivalent eta-squared
			di as txt "Equivalent eta-squared (f^2/(1+f^2))" _col(38) "= " ///
				as res %6.4f (`CohenF'^2 / (1 + `CohenF'^2))
			di "{hline 55}"
			di ""
				
			tempname mytab
			.`mytab' = ._tab.new, col(5) lmargin(0)
			.`mytab'.width    20   |11  12  12    12
			.`mytab'.titlefmt  .     .   . %24s   .
			.`mytab'.pad       .     1   1  3     3
			.`mytab'.numfmt    . %9.0g %9.0g %9.0g %9.0g
			.`mytab'.strcolor result  .  .  .  .
			.`mytab'.strfmt    %19s  .  .  .  .
			.`mytab'.strcolor   text  .  .  .  .
			.`mytab'.sep, top
			.`mytab'.titles "Group vs pooled"						///
							"Estimate"								///
							"Std. Err."								///
							"[`level'% Conf. Interval]" ""
			.`mytab'.sep, middle
			.`mytab'.strfmt    %24s  .  .  .  .
			forvalues j = 1/`num_groups' {
				if "`cohensd'" != "" {
					.`mytab'.row    "`grouplabel`j'' ({it:d})"    ///
							`d`j''									///
							`se`j''									///
							`lb`j''									///
							`ub`j''
				}
				if "`hedgesg'" != "" {
					.`mytab'.row    "`grouplabel`j'' ({it:g})"    ///
							`g`j''									///
							`se`j''									///
							`glb`j''								///
							`gub`j''
				}
			}
			.`mytab'.sep, bottom

			// return results
			return scalar f = `CohenF'
			return scalar eta2 = (`CohenF'^2 / (1 + `CohenF'^2))
			return scalar sdpooled = `sdpooled'
			return scalar N = `N'
			return scalar k = `num_groups'
			forvalues j = 1/`num_groups' {
				return scalar n`j' = `n`j''
				return scalar d`j' = `d`j''
				return scalar lb_d`j' = `lb`j''
				return scalar ub_d`j' = `ub`j''
				return scalar g`j' = `g`j''
				return scalar lb_g`j' = `glb`j''
				return scalar ub_g`j' = `gub`j''
			}

			// pairwise d/g between all k(k-1)/2 group pairs
			if "`pwcompare'" != "" {
				local npairs = `num_groups' * (`num_groups'-1) / 2
				tempname PH
				matrix `PH' = J(`npairs', 4, .)

				local pr = 0
				local rownames ""
				forvalues a = 1/`=`num_groups'-1' {
					forvalues b = `=`a'+1'/`num_groups' {
						local ++pr
						tempname pest
						scalar `pest' = `bmat'[1,`a'] - `bmat'[1,`b']

						quietly esizeregi `=`pest'', sdp(`=`sdpooled'') n1(`n`a'') n2(`n`b'') `cohensd' `hedgesg' `zdistribution' level(`level')

						if "`hedgesg'" != "" {
							matrix `PH'[`pr',1] = r(g)
							matrix `PH'[`pr',3] = r(lb_g)
							matrix `PH'[`pr',4] = r(ub_g)
						}
						else {
							matrix `PH'[`pr',1] = r(d)
							matrix `PH'[`pr',3] = r(lb_d)
							matrix `PH'[`pr',4] = r(ub_d)
						}
						matrix `PH'[`pr',2] = r(se)
						local rn`pr' "`grouplabel`a'' vs `grouplabel`b''"
						local rownames `"`rownames' "`rn`pr''""'
					}
				}

				matrix colnames `PH' = Estimate SE LB UB
				matrix rownames `PH' = `rownames'

				local maxlen = strlen("Groups")
				forvalues pr = 1/`npairs' {
					local len = strlen("`rn`pr''")
					if `len' > `maxlen' local maxlen = `len'
				}
				local maxlen = `maxlen' + 2

				if `npairs' == 1 {
					di as txt _n "Pairwise comparisons (" as res `npairs' as txt " pair, `esizelabel')"
				}
				else {
					di as txt _n "Pairwise comparisons (" as res `npairs' as txt " pairs, `esizelabel')"					
				}

				tempname phtab
				.`phtab' = ._tab.new, col(5) lmargin(0)
				.`phtab'.width    `maxlen'   |11  12  12    12
				.`phtab'.titlefmt  .     .   . %24s   .
				.`phtab'.pad       .     1   1  3     3
				.`phtab'.numfmt    . %9.0g %9.0g %9.0g %9.0g
				.`phtab'.strcolor result  .  .  .  .
				.`phtab'.strfmt    %-`maxlen's  .  .  .  .
				.`phtab'.strcolor   text  .  .  .  .
				.`phtab'.sep, top
				.`phtab'.titles "Groups"							///
								"Estimate"							///
								"Std. Err."							///
								"[`level'% Conf. Interval]" ""
				.`phtab'.sep, middle
				.`phtab'.strfmt    %-`maxlen's  .  .  .  .
				forvalues pr = 1/`npairs' {
					.`phtab'.row    "`rn`pr''"    ///
							`PH'[`pr',1]			///
							`PH'[`pr',2]			///
							`PH'[`pr',3]			///
							`PH'[`pr',4]
				}
				.`phtab'.sep, bottom

				return matrix pairwise = `PH'
				return scalar npairs = `npairs'
			}

			// restore original estimates
			qui estimates restore esizereg_results
			qui estimates replay esizereg_results

end
