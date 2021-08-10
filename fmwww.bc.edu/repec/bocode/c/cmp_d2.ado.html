*! cmp 3.8.1 5 August 2011
*! David Roodman, Center for Global Development, Washington, DC, www.cgdev.org
*! Copyright David Roodman 2007-11. May be distributed free.

program define cmp_d2
	version 9.2

	forvalues l=1/$cmp_num_scores {
		local scargs `scargs' sc`l'
	}
	args todo b lnf g negH `scargs'
	tokenize `0'
	macro shift 5

	tempname t sig atanhrho cuts rc bb
	tempvar theta
	local ML_k = colsof(`b')
	mat `bb' = `b'[1, `ML_k'-$cmp_num_scores+1...]
	get_sig_rho `bb' `sig' `atanhrho'

	mat `cuts' = J($cmp_d, $cmp_max_cuts+2, .)
	if $cmp_tot_cuts {
		local l = $cmp_num_scores - $cmp_tot_cuts
		forvalues j=1/$cmp_d {
			if cmp_num_cuts[`j',1] {
				forvalues k=1/`=cmp_num_cuts[`j',1]' {
					mat `cuts'[`j',`k'+1] = `bb'[1,`++l']
				}
			}
		}
	}

	qui forvalues l=1/$cmp_d {
		mleval `theta' = `b', eq(`l')
		replace _cmp_e`l' = cond(inlist(_cmp_ind`l', 1, 2, 7, 8),           ///
							${cmp_y`l'} - `theta',                 ///
					  cond(_cmp_ind`l'==3,                            ///
							`theta' - ${cmp_y`l'},                 ///
					  cond(_cmp_ind`l'==4,                            ///
							cond(${cmp_y`l'}, `theta', -`theta'),  ///
					  cond(_cmp_ind`l'==5,                            ///
							`cuts'[`l', ${cmp_y`l'}+1] - `theta', ///
							-`theta')))) if _cmp_ind`l'
		if $cmp_max_cuts | ${cmp_intreg`l'}  | ${cmp_truncreg`l'} ///
				replace _cmp_f`l' = cond(_cmp_ind`l'==5, `cuts'[`l', ${cmp_y`l'}], ${cmp_y`l'_L}) - `theta' if inlist(_cmp_ind`l', 5, 7, 8)
		if ${cmp_truncreg`l'} replace _cmp_g`l' = ${cmp_y`l'_U} - `theta' if _cmp_ind`l'==8
		drop `theta'
	}

	if `todo' > 1 { // back up mprobit errors because cmp_lnL() overwrites them
		qui forvalues i=1/$cmp_num_mprobit_groups { 
			forvalues j=`=cmp_mprobit_group_inds[`i',1]'/`=cmp_mprobit_group_inds[`i',2]' {
				tempvar e`j'
				gen double `e`j'' = _cmp_e`j'
				local es `es' `e`j''
			}
		}
	}

	mata st_numscalar(st_local("rc"), cmp_lnL(`todo', "`sig'", "`atanhrho'", "", "`*'"))
	mlsum `lnf' = _cmp_lnfi

	if `rc' | `lnf'==0 {
		scalar `lnf' = .
		exit
	}

	if `todo' {
		tempname _g
		forvalues l=1/$cmp_d {
			mlvecsum `lnf' `t' = `sc`l'' if _cmp_ind`l', eq(`l')
			mat `_g' = nullmat(`_g'), `t'
		}
		forvalues l=`=$cmp_d+1'/$cmp_num_scores {
			mlsum `t' = `sc`l''
			mat `_g' = `_g', `t'
		}
		mat `g' = `_g'

		qui if `todo' > 1 {
			tempname bbi h v _v
			tempvar e f g

			forvalues l=1/$cmp_num_scores {
				tempvar sc`l'_0 sc`l'_1
				gen double `sc`l'_0' = `sc`l''
				gen double `sc`l'_1' = .
			}

			forvalues i=1/$cmp_d {
				restore_mprobit_es `es'
				gen double `e' = _cmp_e`i'
				sum `e' if _cmp_ind`i' & `e' < . [aw = $ML_w], meanonly
				scalar `h' = (abs(`r(mean)') + 1e-5) * 1e-5
				replace _cmp_e`i' = cond(_cmp_ind`i'==3 | (_cmp_ind`i'==4 & ${ML_y`i'}), `e' + `h', `e' - `h') if _cmp_ind`i'
				if $cmp_max_cuts | ${cmp_intreg`i'} | ${cmp_truncreg`i'} {
					gen double `f' = _cmp_f`i'
					replace _cmp_f`i' = `f' - `h' if inlist(_cmp_ind`i', 5, 7, 8)
				}
				if ${cmp_truncreg`i'} {
					gen double `g' = _cmp_g`i'
					replace _cmp_g`i' = `g' - `h' if _cmp_ind`i'==8
				}

				cap mata cmp_lnL(`todo', "`sig'", "`atanhrho'", "", "`*'")

				forvalues l=`i'/$cmp_num_scores {
					replace `sc`l'_1' = `sc`l''
				}

				restore_mprobit_es `es'
				
				replace _cmp_e`i' = cond(_cmp_ind`i'==3 | (_cmp_ind`i'==4 & ${ML_y`i'}), `e' - `h', `e' + `h') if _cmp_ind`i'
				if $cmp_max_cuts | ${cmp_intreg`i'} | ${cmp_truncreg`i'} replace _cmp_f`i' = `f' + `h' if inlist(_cmp_ind`i', 5, 7, 8)				
				if ${cmp_truncreg`i'} replace _cmp_g`i' = `g' + `h' if _cmp_ind`i'==8				

				cap mata cmp_lnL(`todo', "`sig'", "`atanhrho'", "", "`*'")

				forvalues l=`i'/$cmp_d {
					replace `sc`l'_1' = `sc`l'' - `sc`l'_1'
					mlmatsum `lnf' `t' = `sc`l'_1' if _cmp_ind`l' & _cmp_ind`i', eq(`l',`i')
					mat `_v' = nullmat(`_v') \ (`t' / (2*`h'))
				}
				forvalues l=`=$cmp_d+1'/$cmp_num_scores {
					replace `sc`l'_1' = `sc`l'' - `sc`l'_1'
					mlvecsum `lnf' `t' = `sc`l'_1' if _cmp_ind`i', eq(`i')
					mat `_v' = nullmat(`_v') \ (`t' / (2*`h'))
				}
				if rowsof(`_v') < `ML_k' mat `_v' = J(`ML_k' - rowsof(`_v'), colsof(`_v'), 0) \ `_v'
				mat `v' = nullmat(`v'), `_v'
				mat drop `_v'
				replace _cmp_e`i' = `e'
				drop `e'
				cap drop `f'
				cap drop `g'
			}

			forvalues i=`=$cmp_d+1'/`=$cmp_num_scores - $cmp_tot_cuts' {
				restore_mprobit_es `es'
				scalar `bbi' = `bb'[1, `i']
				scalar `h' = (abs(`bbi') + 1e-5) * 1e-5
				mat `bb'[1,`i'] = `bbi' + `h'
				get_sig_rho `bb' `sig' `atanhrho'
				cap mata cmp_lnL(`todo', "`sig'", "`atanhrho'", "", "`*'")

				forvalues l=`i'/$cmp_num_scores {
					replace `sc`l'_1' = `sc`l''
				}
				
				mat `bb'[1,`i'] = `bbi' - `h'
				get_sig_rho `bb' `sig' `atanhrho'
				restore_mprobit_es `es'
				cap mata cmp_lnL(`todo', "`sig'", "`atanhrho'", "", "`*'")

				forvalues l=`i'/$cmp_num_scores {
					replace `sc`l'_1' = `sc`l'' - `sc`l'_1'
					mlvecsum `lnf' `t' = `sc`l'_1', eq(`i')
					mat `_v' = nullmat(`_v') \ (`t' / (2*`h'))
				}

				if rowsof(`_v') < `ML_k' mat `_v' = J(`ML_k' - rowsof(`_v'), colsof(`_v'), 0) \ `_v'
				mat `v' = nullmat(`v'), `_v'
				mat drop `_v'
			}

			local i = $cmp_num_scores - $cmp_tot_cuts
			forvalues j=1/$cmp_d {
				if cmp_num_cuts[`j',1] {
					gen double `e' = _cmp_e`j'
					gen double `f' = _cmp_f`j'
					forvalues k=2/`=cmp_num_cuts[`j',1]+1' {
						restore_mprobit_es `es'
						scalar `h' = (abs(`cuts'[`j',`k']) + 1e-5) * 1e-5
						replace _cmp_e`j' = `e' + `h' if _cmp_ind`j'==5 & ${cmp_y`j'}==`=`k'-1'
						replace _cmp_f`j' = `f' + `h' if _cmp_ind`j'==5 & ${cmp_y`j'}==  `k'
						cap mata cmp_lnL(`todo', "`sig'", "`atanhrho'", "", "`*'")
						forvalues l=`++i'/$cmp_num_scores {
							replace `sc`l'_1' = `sc`l''
						}

						restore_mprobit_es `es'
						replace _cmp_e`j' = `e' - `h' if _cmp_ind`j'==5 & ${cmp_y`j'}==`=`k'-1'
						replace _cmp_f`j' = `f' - `h' if _cmp_ind`j'==5 & ${cmp_y`j'}==  `k'
						cap mata cmp_lnL(`todo', "`sig'", "`atanhrho'", "", "`*'")
						forvalues l=`i'/$cmp_num_scores {
							if 0 & `l'>`i'+1 & `l'<=`i'-`k'+cmp_num_cuts[`j',1]+1 mat `_v' = `_v' \ 0
							else {
								replace `sc`l'_1' = `sc`l'' - `sc`l'_1'
								mlvecsum `lnf' `t' = `sc`l'_1', eq(`i')
								mat `_v' = nullmat(`_v') \ (`t' / (2*`h'))
							}						
						}
						if rowsof(`_v') < `ML_k' mat `_v' = J(`ML_k' - rowsof(`_v'), colsof(`_v'), 0) \ `_v'
						mat `v' = nullmat(`v'), `_v'
						mat drop `_v'
					}
					replace _cmp_e`j' = `e'
					replace _cmp_f`j' = `f'
					drop `e' `f'
				}
			}

			mata st_matrix("`negH'", makesymmetric(st_matrix("`v'")))
			forvalues l=1/$cmp_num_scores {
				replace `sc`l'' = `sc`l'_0'
			}
		}
	}
end

program get_sig_rho
	version 9.2
	args bb sig atanhrho
	local l $cmp_d
	cap mat drop `sig'
	forvalues j=1/$cmp_d {
		if cmp_fixed_sigs[1,`j']==99 {
			mat `sig' = nullmat(`sig'), exp(`bb'[1,`++l'])
		}
		else {
			mat `sig' = nullmat(`sig'), cmp_fixed_sigs[1,`j']
		}
	}

	if $cmp_d > 1 {
		cap mat drop `atanhrho'
		forvalues j=1/$cmp_d {
			forvalues k=`=`j'+1'/$cmp_d {
				if cmp_nonbase_cases[1,`j'] & cmp_nonbase_cases[1,`k'] & cmp_fixed_rhos[`k',`j']==99 {
					mat `atanhrho' = nullmat(`atanhrho'), `bb'[1,`++l']
				}
				else {
					mat `atanhrho' = nullmat(`atanhrho'), 0
				}
			}
		}
	}
end

program define restore_mprobit_es
	version 9.2
	local l 1
	forvalues i=1/$cmp_num_mprobit_groups { 
		forvalues j=`=cmp_mprobit_group_inds[`i',1]'/`=cmp_mprobit_group_inds[`i',2]' {
			replace _cmp_e`j' = ``l++'' if _cmp_ind`j'
		}
	}
end
