*! cmp_ll 2.1.0 15 May 2008
*! David Roodman, Center for Global Development, Washington, DC, www.cgdev.org
*! Copyright David Roodman 2007-08. May be distributed free.

program define cmp_ll
	cap version 10

	forvalues l=1/$cmp_num_scores {
		local scargs `scargs' sc`l'
	}
	args todo b lnf g negH `scargs'
	cap confirm var _cmp_e1
	if _rc {
		di as err "{cmd:cmp} temporay variables missing. Did you run {cmd:cmp cleanup}?"
		scalar `lnf' = .
		exit
	}

	tempname t lnsig cuts rc
	mat `cuts' = J($cmp_d, $cmp_max_cuts+2, maxfloat())
	tempvar theta

	mat `lnsig' = J(1, $cmp_d, .)
	local l = $cmp_d
	forvalues j=1/$cmp_d {
		local ++l
		mleval `t' = `b', eq(`l') scalar
		mat `lnsig'[1,`j'] = `t'
	}

	if $cmp_d > 1 {
		tempname atanhrho
		mat `atanhrho' = J(1, $cmp_num_rhos, .)
		forvalues j=1/$cmp_num_rhos {
			local ++l
			mleval `t' = `b', eq(`l') scalar
			mat `atanhrho'[1,`j'] = `t'
		}
	}

	forvalues j=1/$cmp_d {
		if cmp_num_cuts[`j',1] {
			mat `cuts'[`j',1] = minfloat()
			forvalues k=1/`=cmp_num_cuts[`j',1]' {
				local ++l
				mleval `t' = `b', eq(`l') scalar
				mat `cuts'[`j',`k'+1] = `t' 
			}
		}
	}

	qui forvalues l=1/$cmp_d {
		mleval `theta' = `b', eq(`l')
		replace _cmp_e`l' = cond(_cmp_ind`l' <= 2, ///
							${ML_y`l'} - `theta', ///
					  cond(_cmp_ind`l'==3, ///
							`theta' - ${ML_y`l'}, ///
					  cond(_cmp_ind`l'==4, ///
							cond(${ML_y`l'}, `theta', -`theta'), ///
							`cuts'[`l', ${cmp_y`l'}+1] - `theta'))) if $ML_samp & _cmp_ind`l'
		replace _cmp_f`l' = `cuts'[`l', ${cmp_y`l'}] - `theta' if $ML_samp & _cmp_ind`l'==5
		drop `theta'
	}

	mata: st_numscalar(st_local("rc"), cmp_lnL("`lnsig'", "`atanhrho'"))

	if `rc' == . {
		scalar `lnf' = .
		exit
	}

	mlsum `lnf' = _cmp_lnfi if $ML_samp

	if `todo' {
		tempname _g
		forvalues l=1/$cmp_d {
			mlvecsum `lnf' `t' = `sc`l'' if $ML_samp & _cmp_ind`l', eq(`l')
			mat `_g' = nullmat(`_g'), `t'
		}
		forvalues l=`=$cmp_d+1'/$cmp_num_scores {
			mlsum `t' = `sc`l'' if $ML_samp
			mat `_g' = `_g', `t'
		}
		mat `g' = `_g'
	}
end
