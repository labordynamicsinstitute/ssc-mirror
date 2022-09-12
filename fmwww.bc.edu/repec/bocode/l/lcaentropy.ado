*!! lcaentropy.ado version 1.0.0
*!! RA Medeiros 8sep2022
program define lcaentropy, rclass
	version 15.0
	syntax  [, force] 
	preserve

	if e(cmd)!="gsem" {
		display as error "Last estimation command was not {bf:gsem}"
		error 321
	}
	if "`e(lclass)'"=="" {
		display as error "Last estimation command did not include latent classes"
		error 321
	}
	
	local k = 1
	tempname lclass_k_levels
	matrix `lclass_k_levels' = e(lclass_k_levels)
	forvalues j = 1/`=colsof(`lclass_k_levels')' {
		local k = `k' * `lclass_k_levels'[1,`j']
	}
	
	
	tempvar pr
	forvalues i=1/`k' {
		local a \`pr'_`i' 
		local prvars : list a | prvars
	}
	confirm new variable `prvars'
	while _rc!=0 {
		tempvar pr
		capture confirm new variable `prvars'
	}
	
	predict double `pr'_* if e(sample), classposteriorpr 
	unab prvars: `pr'_*
	
	foreach var in `prvars'	{
		quietly: count if ln(`var')==.
		if r(N)!=0 {
			display as error "`: variable label `var'' contains probabilities sufficiently close to 0" _n ///
				"to result in missing values of ln(pr) in " r(N) " cases." 
			if "`force'"=="" {
				error 416
			}
			else {
				display "Contribution to entropy for observation with missing contribution set to 0."
			}
		}
	}


	mata: lca_ent(`"`prvars'"', `e(N)', `k')
	display "Entropy = " as result %8.6g r(ent)
	return scalar entropy = r(ent)

	if colsof(`lclass_k_levels')>1 {
			tempname entlist
			local clist : colnames `lclass_k_levels'

			local icvars = 1
			foreach cvars of local clist {

				local kj = `lclass_k_levels'[1,`icvars++']
		
				local probs
				forvalues j = 1/`kj' {
					local rowlist_`j'_`cvars' 
					foreach var of varlist `prvars' {
						if strpos(`"`: variable label `var''"', "`j'.`cvars'")>0 {
							local rowlist_`j'_`cvars'  `rowlist_`j'_`cvars''  `var'
						}
					} 
					tempvar `cvars'_`j'
					egen double `cvars'_`j' = rowtotal(`rowlist_`j'_`cvars'') 
					local probs `probs' `cvars'_`j' 
				} 
					mata: lca_ent(`"`probs'"', `e(N)', `kj') 
					display "Entropy for latent class `cvars' = " as result %8.6g r(ent)
					drop `probs'
					
				capture confirm matrix `entlist'
				if _rc!=0 {
					matrix `entlist' = (r(ent))
				}
				else {
					matrix `entlist' = (`entlist',r(ent))
				}
			} 	
			matrix colnames `entlist' = `clist'
			return matrix class_entropy = `entlist'
	}

	restore 
end

version 15.0
mata: 
	void lca_ent(string scalar prvars, numeric scalar n, numeric scalar k) {
		d = st_data(., tokens(prvars))
		st_numscalar("r(ent)", 1 - colsum(rowsum(-1*d:*ln(d)))/(n*ln(k)))
	}
end

