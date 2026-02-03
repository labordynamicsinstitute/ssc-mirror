*! version 2.0.0  01Feb2026 Ariel Linden

/* 		-centile2- is a modification of official Stata's -centile- command,
		allowing the user to choose between 9 different definitions
		for computing the given quantile as described in: 
		Hyndman, R. J. and Fan, Y. (1996) Sample quantiles in statistical 
		packages, American Statistician 50, 361--365.

*/ 

program define centile2, rclass byable(recall) sort
	version 6, missing
	syntax [varlist] [if] [in] [, CCi /*
		*/ Centile(numlist >=0 <=100) /*
		*/ Level(cilevel) Meansd Normal /*
		*/ Type(integer 6) ]

	tempvar touse notuse
	mark `touse' `if' `in'
	qui gen byte `notuse' = .

	if "`centile'"=="" { 
		local centile 50 
	}

	* allow types 1–9
	if !inlist(`type',1,2,3,4,5,6,7,8,9) {
		di as err "type(#) must be an integer between 1 and 9"
		exit 198
	}

	* parse centiles
	local nc 0
	tokenize "`centile'"
	while "`1'" != "" {
		local nc = `nc' + 1
		local c`nc' `1'
		local cents "`cents' `1'"
		mac shift
	}

	* output header
	local tl1 "      Obs "
	local ttl "Percentile"
	if "`meansd'"=="" { 
		if "`normal'"=="" { 
			if "`cci'"~="" {
				di in smcl in gr _n _col(56) "   Binomial exact   "
			}
			else {
				di in smcl in gr _n _col(56) "   Binom. interp.   "
			}
		}
		else {
			di in smcl in gr _n _col(36) "{hline 2} Normal, based on observed centiles {hline 2}"
		}
	}
	else {
		di in smcl in gr _n _col(36) "{hline 2} Normal, based on mean and std. dev.{hline 2}"
	}
	local cil `=string(`level')'
	local cil `=length("`cil'")'
	local spaces ""
	if `cil' == 2 {
		local spaces "   "
	}
	else if `cil' == 4 {
		local spaces " " 
	}
	di in smcl in gr `"    Variable {c |} `tl1' `ttl'    Centile     `spaces'[`=strsubdp("`level'")'% conf. interval]"'
	di in smcl in gr "{hline 13}{c +}{hline 61}"

	local anymark 0
	local alpha2 = (100-`level')/200
	local zalpha2 = -invnorm(`alpha2')

	* process varlist
	tokenize `varlist'
	local vl
	while "`1'" != "" {
		capt conf str var `1'
		if _rc { 
			local vl "`vl' `1'"
		}
		mac shift 
	}

	tokenize `vl'
	while "`1'" ~= "" {
		local yvar "`1'"

		qui replace `notuse' = ~`touse'
		qui replace `notuse' = 1 if `yvar'>=.
		sort `notuse' `yvar'

		qui sum `yvar' if ~`notuse'
		local nobs = r(N)
		local mean = r(mean)
		local sd = sqrt(r(Var))

		local fmt : format `yvar'
		if bsubstr("`fmt'",-1,1)=="f" { 
			local ofmt="%9."+bsubstr("`fmt'",-2,2)
		}
		else if bsubstr("`fmt'",-2,2)=="fc" {
			local ofmt = "%9." + bsubstr("`fmt'",-3,3)
		}
		else local ofmt "%9.0g"

		* compute quantiles
		local j 1
		local s 7
		while `j' <= `nc' {
			local mark ""
			local cj "c`j'"
			local quant = ``cj''/100

			if "`meansd'" ~= "" & (`nobs' > 0) {
				* parametric normal estimates
				local z = invnorm(`quant')
				local centil = `mean' + `z' * `sd'
				local se = `sd' * sqrt(1/`nobs' + (`z')^2 / (2*(`nobs'-1)))
				local cLOWER = `centil' - `zalpha2' * `se'
				local cUPPER = `centil' + `zalpha2' * `se'
			}
			else if `nobs' > 0 {
				sort `yvar'
				local quant = ``cj''/100

				if inlist(`type',1,2,3) {
					* types 1–3: discontinuous definitions
					if `quant' <= 0 {
						local centil = `yvar'[1]
					}
					else if `quant' >= 1 {
						local centil = `yvar'[`nobs']
					}
					else {
						local k = `quant' * `nobs'
						local i1 = ceil(`k')
						local i2 = floor(`k')
						local g = `k' - `i2'

						if `type' == 1 {
							* Q1: inverse of EDF (ceil(p*n))
							local centil = `yvar'[`i1']
						}
						else if `type' == 2 {
							* Q2: average when g=0
							if `g' == 0 {
								local centil = (`yvar'[`i2'] + `yvar'[`i2'+1]) / 2
							}
							else {
								local centil = `yvar'[`i1']
							}
						}
						else if `type' == 3 {
							* Q3: nearest integer, even rule
							local k_round = round(`k')
							if `g' == 0 & mod(`k_round', 2) == 0 {
								* average of two middle values for even nearest
								local centil = (`yvar'[`k_round'] + `yvar'[`k_round'+1]) / 2
							}
							else {
								local centil = `yvar'[`k_round']
							}
						}
					}
				}
				else {
					* types 4–9: continuous definitions
					if `type' == 4 {
						local a = 0
						local b = 1
					}
					else if `type' == 5 {
						local a = 0.5
						local b = 0.5
					}
					else if `type' == 6 {
						local a = 0
						local b = 0
					}
					else if `type' == 7 {
						local a = 1
						local b = 1
					}
					else if `type' == 8 {
						local a = 1/3
						local b = 1/3
					}
					else if `type' == 9 {
						local a = 3/8
						local b = 3/8
					}

					local frac1 = `a' + `quant' * (`nobs' + 1 - `a' - `b')
					local i1 = int(`frac1')
					local frac1 = `frac1' - `i1'
					
					if `i1' >= `nobs' {
						local centil = `yvar'[`nobs']
					}
					else if `i1' < 1 {
						local centil = `yvar'[1]
					}
					else {
						local centil = `yvar'[`i1'] + `frac1' * (`yvar'[`i1'+1] - `yvar'[`i1'])
					}
				}

				* confidence intervals
				if "`normal'" == "" {
					local nq = `nobs' * `quant'
					local z = sqrt(`nq' * (1-`quant')) * `zalpha2'
					local rzLOW = int(.5 + `nq' - `z')
					local rzHIGH = 1 + int(.5 + `nq' + `z')
					local r1 `rzHIGH'
					if `r1' > `nobs'+1 { 
						local r1 = `nobs'+1
					}
					local r0 = `r1' - 1
					local p0 = Binomial(`nobs', `r0', `quant')
					local p1 = Binomial(`nobs', `r1', `quant')
					local done 0
					while ~`done' {
						if `p0' > `alpha2' {
							if `p1' <= `alpha2' {
								local done 1
							}
							else {
								local r0 = `r1'
								local p0 = `p1'
								local r1 = `r1' + 1
								local p1 = Binomial(`nobs', `r1', `quant')
							}
						}
						else if `p0' == `alpha2' {
							local r1 = `r0'
							local p1 = `p0'
							local done 1
						}
						else {
							local r1 = `r0'
							local p1 = `p0'
							local r0 = `r0' - 1
							local p0 = Binomial(`nobs', `r0', `quant')
						}
					}
					if `r0' >= `nobs' {
						local cUPPER = `yvar'[`nobs']
						local mark "*"
						local anymark 1
					}
					else if `r0' < 1 {
						local cUPPER = `yvar'[1]
						local mark "*"
						local anymark 1
					}
					else {
						if "`cci'" == "" {
							local cUPPER = `yvar'[`r0'] + ((`p0' - `alpha2') / (`p0' - `p1')) * (`yvar'[`r1'] - `yvar'[`r0'])
						}
						else {
							local cUPPER = `yvar'[`r1']
						}
					}
					local r1 `rzLOW'
					if `r1' < 0 {
						local r1 0
					}
					local r0 = `r1' - 1
					local p0 = 1 - Binomial(`nobs', `r0'+1, `quant')
					local p1 = 1 - Binomial(`nobs', `r1'+1, `quant')
					local done 0
					while ~`done' {
						if `p1' > `alpha2' {
							if `p0' <= `alpha2' {
								local done 1
							}
							else {
								local r1 = `r0'
								local p1 = `p0'
								local r0 = `r0' - 1
								local p0 = 1 - Binomial(`nobs', `r0'+1, `quant')
							}
						}
						else if `p0' == `alpha2' {
							local r0 = `r1'
							local p0 = `p1'
							local done 1
						}
						else {
							local r0 = `r1'
							local p0 = `p1'
							local r1 = `r1' + 1
							local p1 = 1 - Binomial(`nobs', `r1'+1, `quant')
						}
					}
					if `r1' >= `nobs' {
						local cLOWER = `yvar'[`nobs']
						local mark "*"
						local anymark 1
					}
					else if `r1' < 1 {
						local cLOWER = `yvar'[1]
						local mark "*"
						local anymark 1
					}
					else {
						if "`cci'" == "" {
							local cLOWER = `yvar'[`r1'] + ((`alpha2' - `p0') / (`p1' - `p0')) * (`yvar'[`r1'+1] - `yvar'[`r1'])
						}
						else {
							local cLOWER = `yvar'[`r1']
						}
					}
				}
				else {
					local dens = exp(-0.5*((`centil'-`mean')/`sd')^2)/(`sd'*sqrt(2*_pi))
					local se = sqrt(`quant'*(1-`quant')/`nobs')/`dens'
					local cLOWER = `centil' - `zalpha2' * `se'
					local cUPPER = `centil' + `zalpha2' * `se'
				}
			}

			* display results
			if (`j' == 1) & (`nobs' > 0) {
				di in smcl in gr %12s abbrev("`yvar'",12) " {c |}" _col(14) /*
				*/ in yel %10.0fc `nobs' _col(29) %7.0g ``cj'' _col(39) `ofmt' `centil' _col(55) `ofmt' `cLOWER' _col(67) `ofmt' `cUPPER' in gr "`mark'"
			}
			else if `nobs' > 0 {
				di in smcl in gr "             {c |}" in yel _col(29) %7.0g ``cj'' _col(39) `ofmt' `centil' _col(55) `ofmt' `cLOWER' _col(67) `ofmt' `cUPPER' in gr "`mark'"
			}
			else {
				if (`j' == 1) {
					di in smcl in gr %12s abbrev("`yvar'",12) " {c |}" _col(14) in yel %8.0f `nobs'
				}
				local centil .
				local cLOWER .
				local cUPPER .
			}

			* store results in return and global macros
			local tmp = `s' - 6
			ret scalar c_`tmp' = `centil'
			global S_`s' `centil'
			ret scalar lb_`tmp' = `cLOWER'
			ret scalar ub_`tmp' = `cUPPER'
			local j = `j' + 1
			local s = `s' + 1
		}
		mac shift
	}
	
	* add separator line below the table
	di in smcl in gr "{hline 13}{c BT}{hline 61}"	

	if "`anymark'" == "1" {
		di in gr _n "`mark' Lower (upper) confidence limit held at minimum (maximum) of sample"
	}

	* final return values
	ret scalar N = `nobs'
	ret scalar n_cent = `nc'
	ret local centiles `cents'
	ret scalar type = `type'

	global S_1 `nobs'
	global S_2 `nc'
	global S_3 ``cj''
	global S_4 `centil'
	global S_5 `cLOWER'
	global S_6 `cUPPER'
end