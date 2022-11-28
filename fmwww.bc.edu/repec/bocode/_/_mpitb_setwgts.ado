*! part of -mpitb- the MPI toolbox

cap program drop _mpitb_setwgts
program define _mpitb_setwgts , rclass
	syntax , [dimw(numlist) indw(numlist) STore genscalar] Wgtsname(string) Name(string)

	* syntax checks
	if ("`dimw'" != "" & "`indw'" != "") | ("`dimw'" == "" & "`indw'" == "") {
		di as err "please choose either dimw() or indw()!"
		e 197
	}
	else {
		loc w `dimw' `indw'
	}
	loc setrun : char _dta[MPITB_`name'_dep_vars]						// -mpi_set- was run?
	if "`setrun'" == "" {
		di in smcl as err "Deprivation indicators for {bf:`name'} not set. Please run {bf:mpitb set} first!"
		e 197
	}

	* retrieve infos from chars 
	loc dnames `_dta[MPITB_`name'_dim_names]'						// dimension names
	loc Ndim : word count `dnames'
	foreach d of loc dnames {
		loc MPIind`d' `_dta[MPITB_`name'_dim_`d'_vars]'			// local for each dimension's indicators
		loc MPIind `MPIind' `MPIind`d''
	}
	loc Nind : word count `MPIind'

	* check #dim / #depind == #wgt 
	loc Nw : word count `w'
	if (`Ndim' != `Nw' & "`dimw'" != "") { 
		di as err "#dimensions (`Ndim') and #weights (`Nw') don't match!"
		e 197
	}
	if (`Nind' != `Nw' & "`indw'" != "") {
		di as err "#indicators (`Nind') and #weights (`Nw') don't match!"
		e 197
	}

	* check for weights in range
	foreach wi of numlist `w' {
		cap assert inrange(`wi',0,1)
		if _rc != 0 {
			di as err "weight out of range: {bf:`wi'}"
			e 197
		}
	}

	if "`dimw'" != "" {
		foreach d of loc dnames {
			loc dp : list posof "`d'" in dnames
			loc dw : word `dp' of `w'
			loc w_`d' = `dw'					// store weight in local for each dimension
		}

		foreach d of loc dnames {
			confirm v `MPIind`d''					// deprivation indicator exist		(obsolete)
			loc chk = `chk' + `w_`d''				// summing up the weights
		}
	}
	if "`indw'" != "" {
		foreach d of loc MPIind {
			loc dp : list posof "`d'" in MPIind
			loc dw : word `dp' of `w'
			loc w_`d' = `dw'					// store weight in local for each dimension
		}

		* checks
		foreach d of loc MPIind {
			confirm v `d'						// deprivation indicator exist		(obsolete)
			loc chk = `chk' + `w_`d''				// summing up the weights
			qui count if !mi(`d') 
			if `r(N)' == 0 {
				di as err "{bf:`d'} contains only missings - not allowed with {bf:indw()}! Please use {helpb mpitb set} to update your MPI"
				e 197
			}
		}

	}

	if float(`chk') != 1 {
		di as err "weights do not sum up to 1, but `chk'!"
		e 197
	}

	if "`dimw'" != "" {
		* assign indicator weights equal-nested
		foreach d of loc dnames {
			loc actind_`d' `MPIind`d''					// actual indicators
			foreach i of loc MPIind`d' {					// loop over all indicators
				qui count if !mi(`i')
				if `r(N)' == 0 {					// missing indicator check
					loc actind_`d' : list actind_`d' - i
					loc misind_`d' `misind_`d'' `i'
				}
			}
			if "`actind_`d''" == "" {
				di as err "Dimension `d' has only missing indicators!"
				e 197
			}
			
			loc Nind`d' : word count `actind_`d''				// # of actual indicators in each dimension
			foreach i of loc actind_`d' {					// loop over remaining indicators in dimensions
				loc w_`i' = `w_`d'' / `Nind`d''				// all indicators in dim receive the same weight  (ASP: scalar)
			}
			loc misind `misind' `misind_`d''
		}

		* prepare output (locals)
		foreach d of loc dnames {
			foreach i of loc actind_`d' {
				loc allind `allind' `i'				// all indicator in one local
				loc allindwgts `allindwgts' `w_`i''		// all weights in one local
			}
		}
		loc alldimwgts `w'
	}
	
	if "`indw'" != "" {
		foreach d of loc dnames {
			loc actind_`d' `MPIind`d''		// set actual indicators in dimension = nominal indicators
			loc w_`d' 0				// for summing up
			foreach i of loc MPIind`d' {
				loc w_`d' = `w_`d'' + `w_`i''
				*loc actind_`d' `actind_`d'' `i'	// just needed for reporting back
		
			}
			loc Nind`d' : word count `actind_`d'' 			// just needed for reporting back
			loc dimw `dimw' `w_`d''					// NB: this line switches the next if-condition on
		}

			foreach d of loc MPIind {
				di "`d': `w_`d''"
			}
			loc allind `MPIind'
			loc allindwgts `indw'
			loc alldimwgts `dimw'
			*di as txt as txt "now we have: " as res "`dnames': `dimw'"
			*di as txt as txt "and " as res "`allind': `allindwgts''"
	}

	

	/* at this stage both dimensional weights and indicator weights have already been defined */

	* matrices 
	tempname depwgts dimwgts
	mat `dimwgts' = J(`Ndim',1,.) 
	forval i=1/`Ndim' {
		loc w`i' : word `i' of `dimw'
		mat `dimwgts'[`i',1] = `w`i''
	}
	mat rown `dimwgts' = `dnames'

	loc Nallind : word count `allind'
	mat `depwgts' = J(`Nallind',1,.)
	forval i=1/`Nallind' {
		loc w`i' : word `i' of `allindwgts'
		mat `depwgts'[`i',1] = `w`i''
	}
	mat rown `depwgts' = `allind'


	* report back
/*
	loc ri = c(linesize) - 79
	di in txt "{dlgtab 0 `ri':Specification}"
	di as txt _n "Indicators found with current data set:" 
	foreach d of loc dnames {
			di as txt "- in " as res "`d'" as txt ": " as res "`Nind`d''" as txt " (" as res "`actind_`d''" as txt ")"
	}
	if "`misind'" != "" {
		di as txt _n "Missing indicators found: " as res "`misind'" as txt "."
	}
	else {
		di as txt _n "No missing indicators found."
	}
	di as txt _n "Weights set according to weighting scheme" as res "`wgtsname'" as txt "."
	di as txt _n "Dimensonal weighs:"
	matlist `dimwgts' , names(row) border(t b)
	di as txt _n "Indicator weights"
	matlist `depwgts' , names(row) border(t b)
*/

	if "`store'" != "" {
		char _dta[MPITB_dep_vars_act] "`allind'"	
		char _dta[MPITB_wgts_dim] "`alldimwgts'"
		char _dta[MPITB_wgts_dep] "`allindwgts'"
		char _dta[MPITB_wgts_name] "`wgtsname'"
		char _dta[MPITB_misind] "`misind'"
	}
	/*					deprecate?
	if "`genscalar'" != "" {
		loc j 1
		foreach i in `allind' {
			loc ind`j' : word `j' of `allind'
			loc w_`j' : word `j' of `allindwgts'
			scalar w_`i' = `w_`j++''
		}
	}
	*/
	* return weighting scheme as vector (ASP)

	* return locals 
	ret loc cmd _mpitb_setwgts
	ret loc dim_names `dnames'
	ret loc wgts_dim `alldimwgts'
	ret loc dep_vars_act "`allind'"
	ret loc wgts_dep "`allindwgts'"
	ret loc misind "`misind'"
	ret loc wgts_name "`wgtsname'"
	ret mat wgts_dep_m = `depwgts'
	ret mat wgts_dim_m = `dimwgts'

end 

