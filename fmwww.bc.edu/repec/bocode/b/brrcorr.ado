*! version 1.2  16Nov2001
program define brrcorr, byable(recall) rclass

	version 7

	syntax [varlist(min=2)] [pweight/] [if] [in] [ ,			/*
				*/ BRRWeight(string) FAY(string) dof(int -1)	/*   brr options
				*/ pw 						/*   pairwise
				*/ Obs CI SIG Print(real -1) STar(real -1) 	/*   display options
				*/ SIDak Bonferroni Level(int $S_level) ]


*ADMINISTRATION FOR WEIGHTS, BRRWEIGHTS, FAY ADJUSTMENT, ETC...

	if "`weight'"=="" {
		local exp : char _dta[pweight]
		if "`exp'"=="" {
			di as error "Must specify pweight for overall analysis, or set it with {help svyset}"
			error 198
		}
	}
	local mainweight `exp'
	svyset pweight `exp'

	if "`brrweight'"=="" {
		local brrweight : char _dta[brrwspec]
		if "`brrweight'"=="" {
			di as error "Must specify BRR Weights with BRRWeight() option for first BRR command"
			error 198
		}
	}
	char define _dta[brrwspec] "`brrweight'"
	local brrwspec "`brrweight'"
	unab brrw : `brrweight'
	local nbrrw : word count `brrw'

	if "`fay'"=="" {
		local fay : char _dta[brrfay]
		if "`fay'"=="" {
			local fay 0
		}
	}
	cap confirm number `fay'
	if _rc {
		di in red "fay() must be a number in the range (0,1]"
		error 198
	}
	else if (`fay'<0) | (`fay'>=1) {
		di in red "fay() must be a number in the range (0,1]"
		error 198
	}
	char define _dta[brrfay] "`fay'"

	if `dof'==-1 {
		local dof `nbrrw'
	}

	tempvar touse

	if "`pw'"=="pw" {
		marksample touse, novarlist				/* pairwise calculations */
	}
	else {
		marksample touse
		qui count if `touse'
		local N=`r(N)'
	}

	tokenize `varlist'

	local i 1
	while "``i''" != "" { 
		capture confirm str var ``i''
		if _rc==0 { 
			di in gr "(``i'' ignored because string variable)"
			local `i' " "
		}
		local i = `i' + 1
	}
	local varlist `*'
	tokenize `varlist'
	local nvar : word count `varlist'
	if `nvar' < 2 { error 102 } 

	local ci_tval = invttail(`dof',(100-`level')/200)	/* crit t-value for conf interval */

	local weight "[aw=`exp']"

	local adj 1
	if "`bonferroni'"!="" | "`sidak'"!="" {
		if "`bonferroni'"!="" & "`sidak'"!="" { error 198 }
		local nrho=(`nvar'*(`nvar'-1))/2
		if "`bonferroni'"!="" { local adj `nrho' }
	}
	

	if (`star'>=1) {
		local star = `star'/100
		if `star'>=1 {
			di in red "star() out of range"
			exit 198
		}
	}
	if (`print'>=1) {
		local print = `print'/100
		if `print'>=1 {
			di in red "print() out of range"
			exit 198
		}

	}


	di
	di "{txt}Correlation estimates with BRR-based significance calculations"
	di
	di "{txt}Analysis weight:      `mainweight'"
	di "{txt}Replicate weights:    `brrwspec'"
	
	di "{txt}Number of replicates: `nbrrw'"
	di "{txt}Degrees of freedom:   `dof'"

	di "{txt}k (Fay's method):     " %4.3f `fay'
	

	tempname pvalue lastr lastn lastp
		
	local j0 1
	while (`j0'<=`nvar') {
		di
		local j1=min(`j0'+6,`nvar')
		local j `j0'
		di in smcl in gr _skip(13) "{c |}" _c
		while (`j'<=`j1') {
			di in gr %9s abbrev("``j''",8) _c
			local j=`j'+1
		}
		local l=9*(`j1'-`j0'+1)
		di in smcl in gr _n "{hline 13}{c +}{hline `l'}"

		local i `j0'
		while `i'<=`nvar' {
			di in smcl in gr %12s abbrev("``i''",12) " {c |} " _c
			local j `j0'
			while (`j'<=min(`j1',`i')) {
				cap corr ``i'' ``j'' if `touse' `weight'
				if _rc == 2000 {
					local c`j' = .
					local p`j' = .
					local n`j'=r(N)
				}
				else { 
					local n`j'=r(N)
					local c`j'=r(rho)
					GetP "``i''" "``j''" "`c`j''" "`touse'" "`brrw'" "`nbrrw'" "`fay'" "`dof'" "`pvalue'"
					local p`j'=min(`adj'*`pvalue',1)
					if `i'!=`j' {
						scalar `lastr' = `c`j''
						scalar `lastn' = `n`j''
						scalar `lastp' = `p`j''
					}
				}	       


				if "`sidak'"!="" {
					local p`j'=min(1,1-(1-`p`j'')^`nrho')
				}
				local j=`j'+1
			}
			local j `j0'
			while (`j'<=min(`j1',`i')) {
				if `p`j''<=`star' & `i'!=`j' { 
					local ast "*" 
				}
				else local ast " "
				if `p`j''<=`print' | `print'==-1 |`i'==`j' {
					di "{res} " %7.4f `c`j'' "`ast'" _c
				}
				else 	di _skip(9) _c
				local j=`j'+1
			}
			di
			if "`sig'"!="" {
				di in smcl in gr _skip(13) "{c |}" _c
				local j `j0'
				while (`j'<=min(`j1',`i'-1)) {
					if `p`j''<=`print' | `print'==-1 {
						di "{res}  " %7.4f `p`j'' _c
					}
					else	di _skip(9) _c
					local j=`j'+1
				}
				di
			}
			if "`obs'"!="" {
				di in smcl in gr _skip(13) "{c |}" _c
				local j `j0'
				while (`j'<=min(`j1',`i')) {
					if `p`j''<=`print' | `print'==-1 /*
					*/ |`i'==`j' {
						di "{res}  " %7.0g `n`j'' _c
					}
					else	di _skip(9) _c
					local j=`j'+1
				}
				di
			}
			if "`obs'"!="" | "`sig'"!="" {
				di in smcl in gr _skip(13) "{c |}" 
			}
			local i=`i'+1
		}
		local j0=`j0'+7
	}

	return scalar N   = `lastn'
	return scalar p   = `lastp'
	return scalar rho = `lastr'
end

program define GetP
	args i j corr touse brrw nbrrw fay dof pval 

	tempname r_rep z_rep se z_corr t_level
	
	scalar `z_corr'= 0.5*ln((1+(`corr'))/(1-(`corr')))			/* Fisher Z transformation */
	
	scalar `se'=0
	forval rep=1/`nbrrw' {
		local curw : word `rep' of `brrw'
		qui corr `i' `j' [aw=`curw'] if `touse'				/* repeated estimates */
		scalar `z_rep'= 0.5*ln((1+(`r(rho)'))/(1-(`r(rho)')))		/* Fisher Z transformation */
		scalar `se' = `se' + ((`z_rep')-(`z_corr'))^2
	}

	tempname scalefac
	scalar `scalefac' = 1 / (`nbrrw' * (1-`fay')^2 )
	
	scalar `se' = sqrt((`se') * `scalefac')
	
	scalar `t_level' = abs((`z_corr') / (`se'))			/* estimate / std error */
	scalar `pval' = ttail(`dof',`t_level')*2

end

