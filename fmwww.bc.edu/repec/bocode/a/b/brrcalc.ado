*! v 1.2.0 Nicholas Winter  15Nov2001
prog define brrcalc, rclass
	version 7

	syntax varlist [pweight iweight/] [if] , /*
		*/ BRRWeights(string) [ b(string) type(string) v(string)  /*
		*/ vsrs(string) by(varname) nby(integer 0) obs(string) npop(string) /*
		*/ dof(int -1) SRSSUBpop fay(real 0) ]

	if "`exp'"!="" {
		local wt "[aw=`exp']"
		local iwt "[iw=`exp']"
		local mainweight `exp'
	}

	local brrwspec "`brrweights'"
	unab brrw : `brrweights'
	local nbrrw : word count `brrw'	

	marksample touse
	tempname totb repb accumV 

	if "`type'"=="" { local type mean }
	if !("`type'"=="mean" | "`type'"=="total" | "`type'"=="ratio") { error 198 }

	local nvar : word count `varlist'
	if "`type'"=="ratio" {
		if mod(`nvar',2) { error 198 }		/* must have even number */
	}

	if "`by'"!="" {
		tempname byrows
		qui ta `by' , matrow(`byrows')
		forval r=1/`nby' {
			local curval = `byrows'[`r',1]
			local byvals "`byvals' `curval'"
		}
		local bycalc "by(`by') byvals(`byvals') nby(`nby')"
		local bysvy "by(`by') nby(`nby')"
	}
	if "`obs'"=="" {
		tempname obs
	}
	local obscalc "obs(`obs')"
	if "`npop'"=="" {
		tempname npop
	}
	local obscalc "`obscalc' npop(`npop')"


*DO FULL-SAMPLE ESTIMATE OF MEANS or TOTALS

	DoBrrCalc `varlist' `wt' , bmat(`totb') type(`type') touse(`touse') `bycalc' `obscalc'

	local size=colsof(`totb')
	matrix `accumV'=J(`size',`size',0)


* RUN THROUGH REPLICATIONS

	forval rep = 1/`nbrrw' {
		local curw : word `rep' of `brrw'
		DoBrrCalc `varlist' [aw=`curw'] , bmat(`repb') type(`type') touse(`touse')  `bycalc'

		matrix `repb' = `repb' - `totb'				/* turn into deviation */
		matrix `accumV' = `accumV' + (`repb'')*(`repb')		/* add this one:  (b_k - b_tot)'(b_k - b_tot)	*/
									/* this is OUTER product, because b is a row vector */
	}

	tempname scalefac
	scalar `scalefac' = 1 / (`nbrrw' * (1-`fay')^2 )
	matrix `accumV'=`accumV' * `scalefac'

	tempname N_pop N
	qui sum `mainweight' if `touse'
	scalar `N'=r(N)
	scalar `N_pop'=`r(sum)'


* CALCULATE VSRS if needed

	if "`vsrs'"!="" {
		tempname V_srs

		if "`by'"=="" {
			qui matrix accum `V_srs' = `varlist' `wt' if `touse' , dev nocons
			if "`type'"=="mean" {
				mat `V_srs' = `V_srs' / ((`r(N)'-1)*`r(N)')
			}
			else if "`type'"=="total" {
				mat `V_srs' = (`V_srs' / ((`r(N)'-1)*`r(N)')) * `N_pop'^2
			}
			else if "`type'"=="ratio" {
				_svy `varlist' `iwt' if `touse' , type(ratio) vsrs(`V_srs') `srssub'
			}
		}
		else {

			_svy `varlist' `iwt' if `touse' , type(`type') vsrs(`V_srs') `bysvy' `srssub'
		
			/*
			local i 1
			foreach val of local byvals {
				tempname mat`i'
				qui matrix accum `mat`i'' = `varlist' `wt' if `touse' & `by'==`val' , dev nocons
				if "`type'"=="mean" {
					matrix `mat`i'' = `mat`i'' / ((`r(N)'-1)*`r(N)')
				}
				else if "`type'"=="total" {
					matrix `mat`i'' = MatTotDiv(`mat`i'',`obs')
				}
				else if "`type'"=="ratio" {
					????
				}
					
				local addstr "`addstr' + `mat`i''"
				local i=`i'+1

			}
			local addstr=substr(`"`addstr'"',4,.)
			local end=(`nby'*`nvar')-1
			forval i=0/`end' {
				forval j=1/`nby' {
					local themod= mod(`i'+1,`nby')
					if `themod'==0 { local themod `nby' }
					if `themod' != `j' {
						MatAddRC `mat`j'' `i' `mat`j'' 
					}
				}
			}
			
			matrix `vsrs' = `addstr'
			*/
		
		}

	
	}


*POST MATRIX RESULTS

	if "`b'"!="" {
		matrix `b'=`totb'
	}
	if "`v'"!="" {
		matrix `v'=`accumV'
	}

	if "`vsrs'"!="" & "`vsrs'"!="*" {			/* These should be same answers provided by _svy */
		matrix `vsrs'=`V_srs'
	}


	if `dof'==-1 {
		local dof `nbrrw'
	}

	return scalar errcode = 0
	if `nvar'==1 & "`by'"=="" {
		if "`vsrs'"!="" {
			return scalar Var_srs = `V_srs'[1,1]
		}
		return scalar Var      = `accumV'[1,1]
		return scalar estimate = `totb'[1,1]
	}
	return scalar N_pop = `N_pop'
	return scalar N_psu = `dof'*2		/* kludge to get svy-based wrapper to work right */
	return scalar N_strata = `dof'
	return scalar N = `N'


end




program define DoBrrCalc

	syntax varlist [aw] , type(string) bmat(string) touse(string) 	/*
		*/ [ by(varname) byvals(string) nby(integer 0) 		/*
		*/   obs(string) npop(string) ]

	if "`obs'`npop'"!="" {
		local nv : word count `varlist'
		if "`type'"=="ratio" {
			local nv=`nv'/2
		}
		local nby = `nby'
		local dim=max(`nv'*`nby',1)
		if "`obs'"!="" {
			mat `obs'=J(1,`dim',0)
		}
		if "`npop'"!="" {
			mat `npop'=J(1,`dim',0)
		}

	}

	tempname omat pmat
	mat `bmat'=(0)						/* initialize the matrix */
	mat `omat'=(0)
	mat `pmat'=(0)
	if "`type'"!="ratio" {
		foreach var of local varlist {
			if !`nby' {
				sum `var' [`weight'`exp'] if `touse' , meanonly
				if "`type'"=="total" {
					mat `bmat'=`bmat',r(sum)
				}
				else { /* mean */
					mat `bmat'=`bmat',r(mean)
				}
				if "`obs'"!="" {
					mat `omat'=`omat',r(N)
				}
				if "`npop'"!="" {
					mat `pmat'=`pmat',r(sum_w)
				}
			}
			else {
				local i 1
				foreach val of local byvals {
					sum `var' [`weight'`exp'] if `touse' & `by'==`val', meanonly
					if "`type'"=="total" {
						mat `bmat'=`bmat',r(sum)
					}
					else { /* mean */
						mat `bmat'=`bmat',r(mean)
					}
					if "`obs'"!="" {
						mat `omat'=`omat',r(N)
					}
					if "`npop'"!="" {
						mat `pmat'=`pmat',r(sum_w)
					}
					local i=`i'+1
				}
			}
		}
	}



	else { /* type is ratio */
		tempname tot1
		tokenize `varlist'
		while "`1'"!="" {
			if !`nby' {
				sum `1' [`weight'`exp'] if `touse' , meanonly
				scalar `tot1'=r(sum)
				sum `2' [`weight'`exp'] if `touse' , meanonly
				mat `bmat'=`bmat',(`tot1'/r(sum))
			}
			else {
				local i 1
				foreach val of local byvals {
					sum `1' [`weight'`exp'] if `touse' & `by'==`val' , meanonly
					scalar `tot1'=r(sum)
					sum `2' [`weight'`exp'] if `touse' & `by'==`val' , meanonly
					mat `bmat'=`bmat',(`tot1'/r(sum))
					if "`obs'"!="" {
						mat `omat'=`omat',r(N)
					}
					if "`npop'"!="" {
						mat `pmat'=`pmat',r(sum_w)
					}
					local i=`i'+1
				}
			}
			mac shift 2
		}
	}

	mat `bmat'=`bmat'[1,2...]			/* drop initialized zero */
	if "`obs'"!="" {
		mat `obs'=`omat'[1,2...]
	}
	if "`npop'"!="" {
		mat `npop'=`pmat'[1,2...]
	}

end



prog define MatAddRC
	version 7
	args mat num newmat	/* insert row/col after existing r/c num */

	local nr=scalar(rowsof(`mat'))
	local nc=scalar(colsof(`mat'))
	if `nr'!=`nc' {
		di in red "must be square matrix"
		error 198
	}
	if `num'>(`nr') | `num'<0 {
		di in red "`num' out of range"
		error 198
	}
	tempname part1 part2 add

*ADD ROW*
	if `num'>0 {
		matrix `part1' = `mat'[1..`num',1...]
		local a "`part1' \"
	}

	if `num'<`nr' {
		matrix `part2' = `mat'[`num'+1...,1...]
		local b "\ `part2'"
	}

	matrix `add' = J(1,`nc',0)
	mat `newmat' = `a' `add' `b'

*ADD COLUMN*
	if `num'>0 {
		matrix `part1' = `newmat'[1... , 1..`num' ]
		local a "`part1' ,"
	}

	if `num'<`nr' {
		matrix `part2' = `newmat'[1... , `num'+1...]
		local b ", `part2'"
	}

	matrix `add' = J(`nc'+1,1,0)
	matrix `newmat' = `a' `add' `b'

*RELABEL
	local nr1=`nr'+1
	forval i=1/`nr1' {
		local cname "`cname' c`i'"
		local rname "`rname' r`i'"
	}
	matrix colnames `newmat' = `cname'
	matrix rownames `newmat' = `rname'

end
