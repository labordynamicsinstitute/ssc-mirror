*! xtasym 1.0.0  09aug2026
*! Directional asymmetry with panel data: partial sums, diagnostics, graphics
*! Merwan Roudane <merwanroudane920@gmail.com>
*! https://github.com/merwanroudane
*
* Step -> equation map (full version in: help xtasym methods)
*   S1  first difference                 D.x = x(i,t) - x(i,t-1)
*   S2  thresholded decomposition        dpos, dneg with dead band [-c, c]
*   S3a Shin, Yu and Greenwood-Nimmo (2014) partial sums, eq. (14) of
*       Thombs, Huang and Fitzgerald (2022)
*   S3b Allison (2019, sec. 6) cumulated components Z+ and Z-
*   S4  directional frequency table      Table 1 of Thombs et al. (2022)
*   S5  within/between decomposition of the partial sums (xtsum)
*   S6  Pesaran (2015) CD test on the partial sums, Table 3 of Thombs et al.
*   S7  Pesaran (2007) CIPS on the partial sums, Table 3 of Thombs et al.

program define xtasym, rclass sortpreserve
	version 14.0

	syntax varlist(min=1 numeric) [if] [in] [ ,      ///
		Threshold(real 0)                            ///
		CONVention(string)                           ///
		Prefix(string)                               ///
		NOGENerate                                   ///
		FDM                                          ///
		Frequency                                    ///
		SUMmary                                      ///
		CSD                                          ///
		CSDOpt(string asis)                          ///
		CIPS(numlist integer min=2 max=2)            ///
		CIPSOpt(string asis)                         ///
		ALL                                          ///
		Graph                                        ///
		GRSum GRFre GRDist                           ///
		SCHeme(string)                               ///
		SAVing(string)                               ///
		NAme(string)                                 ///
		NODraw COMbine                               ///
		REPLACE ]

	*-------------------------------------------------------------------
	* 0.  environment
	*-------------------------------------------------------------------
	capture qui xtset
	local id   "`r(panelvar)'"
	local time "`r(timevar)'"
	if (_rc | "`id'"=="" | "`time'"=="") {
		di as error "the data must be {bf:xtset} with both a panel and a time variable"
		di as error "{p 4 4 2}type {bf:xtset panelvar timevar} first{p_end}"
		exit 459
	}

	marksample touse, novarlist
	markout `touse' `id' `time'
	qui count if `touse'
	if (r(N)==0) error 2000

	*-------------------------------------------------------------------
	* 1.  option reconciliation
	*-------------------------------------------------------------------
	local th = abs(`threshold')

	if ("`convention'"=="") local convention "shin"
	local convention = lower(trim("`convention'"))
	if !inlist("`convention'","shin","allison") {
		di as error "convention() must be {bf:shin} or {bf:allison}"
		exit 198
	}

	if ("`scheme'"=="") local scheme "parula"
	local scheme = lower(trim("`scheme'"))
	if !inlist("`scheme'","parula","viridis","journal","mono") {
		di as error "scheme() must be {bf:parula}, {bf:viridis}, {bf:journal} or {bf:mono}"
		exit 198
	}

	if ("`all'"!="") {
		local frequency "frequency"
		local summary   "summary"
		local csd       "csd"
		local graph     "graph"
	}
	if ("`graph'"!="") {
		local grsum  "grsum"
		local grfre  "grfre"
		local grdist "grdist"
	}

	if ("`nogenerate'"!="" & `th'!=0) {
		di as error "options {bf:nogenerate} and {bf:threshold()} may not be combined"
		di as error "{p 4 4 2}under nogenerate the series supplied are taken to be partial sums already{p_end}"
		exit 198
	}
	if ("`nogenerate'"!="" & "`fdm'"!="") {
		di as error "options {bf:nogenerate} and {bf:fdm} may not be combined"
		exit 198
	}
	if (`"`csdopt'"'!="" & "`csd'"=="") {
		di as error "option {bf:csdopt()} requires {bf:csd}"
		exit 198
	}
	if (`"`cipsopt'"'!="" & "`cips'"=="") {
		di as error "option {bf:cipsopt()} requires {bf:cips()}"
		exit 198
	}

	local nvar : word count `varlist'

	*-------------------------------------------------------------------
	* 2.  S1 - first differences (kept for the tables and the graphs)
	*-------------------------------------------------------------------
	sort `id' `time'
	local dlist ""
	forvalues i = 1/`nvar' {
		local v : word `i' of `varlist'
		tempvar d`i'
		qui gen double `d`i'' = D.`v' if `touse'
		local dlist "`dlist' `d`i''"
	}

	*-------------------------------------------------------------------
	* 3.  S2/S3 - decomposition and partial sums
	*-------------------------------------------------------------------
	local psvars ""
	local plist  ""
	local nlist  ""

	if ("`nogenerate'"=="") {
		forvalues i = 1/`nvar' {
			local v : word `i' of `varlist'
			local vp "`prefix'`v'_p"
			local vn "`prefix'`v'_n"
			_xtasym_newvar `vp' , `replace'
			_xtasym_newvar `vn' , `replace'

			tempvar dp dn
			qui gen double `dp' = 0
			qui gen double `dn' = 0
			qui replace `dp' = `d`i''  if `d`i'' >  `th' & !mi(`d`i'') & `touse'
			qui replace `dn' = `d`i''  if `d`i'' < -`th' & !mi(`d`i'') & `touse'
			if ("`convention'"=="allison") qui replace `dn' = -`dn'

			qui by `id': gen double `vp' = sum(`dp')
			qui by `id': gen double `vn' = sum(`dn')
			qui replace `vp' = . if !`touse' | mi(`v')
			qui replace `vn' = . if !`touse' | mi(`v')

			label variable `vp' "Positive partial sum of `v'"
			if ("`convention'"=="shin") {
				label variable `vn' "Negative partial sum of `v' (signed)"
			}
			else {
				label variable `vn' "Negative partial sum of `v' (absolute)"
			}

			local psvars "`psvars' `vp' `vn'"
			local plist  "`plist' `vp'"
			local nlist  "`nlist' `vn'"
			drop `dp' `dn'
		}
	}
	else {
		local psvars "`varlist'"
		local plist  "`varlist'"
	}

	*-------------------------------------------------------------------
	* 3b. S2 - first-difference-method components (Allison 2019, sec. 3)
	*-------------------------------------------------------------------
	local fdlist ""
	if ("`fdm'"!="") {
		forvalues i = 1/`nvar' {
			local v : word `i' of `varlist'
			local vp "`prefix'`v'_pfd"
			local vn "`prefix'`v'_nfd"
			_xtasym_newvar `vp' , `replace'
			_xtasym_newvar `vn' , `replace'
			qui gen double `vp' = 0 if `touse' & !mi(`d`i'')
			qui gen double `vn' = 0 if `touse' & !mi(`d`i'')
			qui replace `vp' = `d`i''  if `d`i'' >  `th' & !mi(`d`i'') & `touse'
			qui replace `vn' = `d`i''  if `d`i'' < -`th' & !mi(`d`i'') & `touse'
			if ("`convention'"=="allison") qui replace `vn' = -`vn'
			label variable `vp' "Positive change in `v' (first-difference method)"
			label variable `vn' "Negative change in `v' (first-difference method)"
			local fdlist "`fdlist' `vp' `vn'"
		}
	}

	*-------------------------------------------------------------------
	* 4.  header
	*-------------------------------------------------------------------
	_xtasym_header , th(`th') conv(`convention') nvar(`nvar')  ///
		id(`id') time(`time') touse(`touse')                   ///
		gen(`=cond("`nogenerate'"=="",1,0)')

	*-------------------------------------------------------------------
	* 5.  S4 - directional frequency table
	*-------------------------------------------------------------------
	if ("`frequency'"!="") {
		tempname FMAT
		matrix `FMAT' = J(`nvar',7,.)
		local rn ""
		di ""
		di as txt "{bf:Directional decomposition of the first differences}"
		di as txt "{hline 15}{c TT}{hline 62}"
		di as txt %14s "Variable" " {c |}" as txt %16s "Increases" %16s "Decreases" %16s "No change" %10s "Changes"
		di as txt %14s ""         " {c |}" as txt %16s "(> +c)" %16s "(< -c)" %16s "(inside band)" %10s "observed"
		di as txt "{hline 15}{c +}{hline 62}"
		forvalues i = 1/`nvar' {
			local v : word `i' of `varlist'
			qui count if `d`i'' >  `th' & !mi(`d`i'') & `touse'
			local np = r(N)
			qui count if `d`i'' < -`th' & !mi(`d`i'') & `touse'
			local nn = r(N)
			qui count if inrange(`d`i'',-`th',`th') & !mi(`d`i'') & `touse'
			local nz = r(N)
			local nt = `np' + `nn' + `nz'
			if (`nt'==0) {
				di as txt %14s abbrev("`v'",14) " {c |}" as err %20s "no usable changes"
				continue
			}
			local pp = 100*`np'/`nt'
			local pn = 100*`nn'/`nt'
			local pz = 100*`nz'/`nt'
			local s1 = string(`np',"%9.0fc") + " (" + string(`pp',"%4.1f") + "%)"
			local s2 = string(`nn',"%9.0fc") + " (" + string(`pn',"%4.1f") + "%)"
			local s3 = string(`nz',"%9.0fc") + " (" + string(`pz',"%4.1f") + "%)"
			local s4 = string(`nt',"%9.0fc")
			di as txt %14s abbrev("`v'",14) " {c |}" as res %16s "`s1'" %16s "`s2'" %16s "`s3'" %10s "`s4'"
			matrix `FMAT'[`i',1] = `np'
			matrix `FMAT'[`i',2] = `pp'
			matrix `FMAT'[`i',3] = `nn'
			matrix `FMAT'[`i',4] = `pn'
			matrix `FMAT'[`i',5] = `nz'
			matrix `FMAT'[`i',6] = `pz'
			matrix `FMAT'[`i',7] = `nt'
			local rn "`rn' `v'"
		}
		di as txt "{hline 15}{c BT}{hline 62}"
		di as txt "{p 0 4 2}c = " as res `th' as txt " is the threshold and [-c, c] is the dead band." ///
			" Percentages are shares of the changes actually observed; the first period of each"       ///
			" panel and any gap in the time variable contribute no change.{p_end}"
		if ("`rn'"!="") {
			matrix colnames `FMAT' = n_up pct_up n_down pct_down n_flat pct_flat n_total
			matrix rownames `FMAT' = `rn'
			return matrix frequency = `FMAT' , copy
		}
	}

	*-------------------------------------------------------------------
	* 6.  S5 - within / between summary of the partial sums
	*-------------------------------------------------------------------
	if ("`summary'"!="") {
		local nps : word count `psvars'
		if (`nps' > 0) {
			tempname SMAT
			matrix `SMAT' = J(`nps',7,.)
			local rn ""
			di ""
			di as txt "{bf:Summary statistics for the partial sums}"
			di as txt "{hline 15}{c TT}{hline 62}"
			di as txt %14s "Variable" " {c |}" as txt %10s "Mean" %11s "SD overall" ///
				%11s "SD within" %11s "SD between" %7s "N" %6s "n" %6s "T-bar"
			di as txt "{hline 15}{c +}{hline 62}"
			local k = 0
			foreach v of local psvars {
				local ++k
				capture qui xtsum `v' if `touse'
				if (_rc) {
					di as txt %14s abbrev("`v'",14) " {c |}" as err %14s "not available"
					continue
				}
				local mn = r(mean)
				local sd = r(sd)
				local sw = r(sd_w)
				local sb = r(sd_b)
				local nn = r(N)
				local ni = r(n)
				local tb = r(Tbar)
				di as txt %14s abbrev("`v'",14) " {c |}" as res %10.4f `mn' %11.4f `sd' ///
					%11.4f `sw' %11.4f `sb' %7.0f `nn' %6.0f `ni' %6.1f `tb'
				matrix `SMAT'[`k',1] = `mn'
				matrix `SMAT'[`k',2] = `sd'
				matrix `SMAT'[`k',3] = `sw'
				matrix `SMAT'[`k',4] = `sb'
				matrix `SMAT'[`k',5] = `nn'
				matrix `SMAT'[`k',6] = `ni'
				matrix `SMAT'[`k',7] = `tb'
				local rn "`rn' `v'"
			}
			di as txt "{hline 15}{c BT}{hline 62}"
			di as txt "{p 0 4 2}SD within is the dispersion of a partial sum around its own panel mean." ///
				" A partial sum with little within variation cannot identify a directional effect,"     ///
				" whatever the estimator; consider a larger threshold in that case.{p_end}"
			if ("`rn'"!="") {
				matrix colnames `SMAT' = mean sd_overall sd_within sd_between N n Tbar
				matrix rownames `SMAT' = `rn'
				return matrix summary = `SMAT' , copy
			}
		}
	}

	*-------------------------------------------------------------------
	* 7.  S6 - Pesaran (2015) CD test (self-contained; alpha via xtcse2)
	*-------------------------------------------------------------------
	if ("`csd'"!="") {
		local nps : word count `psvars'
		if (`nps' > 0) {
			tempname CMAT
			matrix `CMAT' = J(`nps',8,.)
			local rn ""
			capture which xtcse2
			local hasalpha = cond(_rc==0,1,0)
			di ""
			di as txt "{bf:Cross-sectional dependence of the partial sums}"
			di as txt "{hline 15}{c TT}{hline 62}"
			if (`hasalpha') {
				di as txt %14s "Variable" " {c |}" as txt %11s "CD" %9s "p-value" ///
					%11s "mean rho" %11s "mean |rho|" %7s "alpha" %6s "n" %6s "T-bar"
			}
			else {
				di as txt %14s "Variable" " {c |}" as txt %11s "CD" %9s "p-value" ///
					%11s "mean rho" %11s "mean |rho|" %7s "pairs" %6s "n" %6s "T-bar"
			}
			di as txt "{hline 15}{c +}{hline 62}"
			local k = 0
			foreach v of local psvars {
				local ++k
				capture scalar drop __xta_cd __xta_p __xta_r __xta_a __xta_np __xta_n __xta_t
				capture mata: _xtasym_cd("`v'","`id'","`time'","`touse'")
				if (_rc) {
					di as txt %14s abbrev("`v'",14) " {c |}" as err %14s "not computable"
					continue
				}
				local cd  = scalar(__xta_cd)
				local cdp = scalar(__xta_p)
				local mr  = scalar(__xta_r)
				local ma  = scalar(__xta_a)
				local npr = scalar(__xta_np)
				local nn  = scalar(__xta_n)
				local tb  = scalar(__xta_t)
				local a   = .
				if (`hasalpha') {
					capture qui xtcse2 `v' if `touse' , `csdopt'
					if (_rc==0) local a = r(alpha)
				}
				local st = ""
				if (`cdp' < .10) local st "*"
				if (`cdp' < .05) local st "**"
				if (`cdp' < .01) local st "***"
				local c1 = string(`cd',"%9.3f") + "`st'"
				local c5 = cond(`hasalpha',`a',`npr')
				di as txt %14s abbrev("`v'",14) " {c |}" as res %11s "`c1'" %9.3f `cdp' ///
					%11.3f `mr' %11.3f `ma' %7.3f `c5' %6.0f `nn' %6.1f `tb'
				matrix `CMAT'[`k',1] = `cd'
				matrix `CMAT'[`k',2] = `cdp'
				matrix `CMAT'[`k',3] = `mr'
				matrix `CMAT'[`k',4] = `ma'
				matrix `CMAT'[`k',5] = `a'
				matrix `CMAT'[`k',6] = `npr'
				matrix `CMAT'[`k',7] = `nn'
				matrix `CMAT'[`k',8] = `tb'
				local rn "`rn' `v'"
			}
			capture scalar drop __xta_cd __xta_p __xta_r __xta_a __xta_np __xta_n __xta_t
			di as txt "{hline 15}{c BT}{hline 62}"
			di as txt "{p 0 4 2}H0: weak cross-sectional dependence (Pesaran 2015). CD is standard normal" ///
				" under H0; stars are * 10%, ** 5%, *** 1%. Rejection is the case for a"                   ///
				" common-correlated-effects estimator rather than two-way fixed effects.{p_end}"
			if (`hasalpha') {
				di as txt "{p 0 4 2}alpha is the exponent of cross-sectional dependence (Bailey, Kapetanios" ///
					" and Pesaran 2016) taken from {help xtcse2}; 0.5 <= alpha < 1 means strong dependence.{p_end}"
			}
			else {
				di as txt "{p 0 4 2}Install {bf:xtdcce2}, which supplies {bf:xtcse2}, to add the exponent of" ///
					" cross-sectional dependence to this table.{p_end}"
			}
			if ("`rn'"!="") {
				matrix colnames `CMAT' = CD p_value rhobar abs_rhobar alpha pairs n Tbar
				matrix rownames `CMAT' = `rn'
				return matrix csd = `CMAT' , copy
			}
		}
	}

	*-------------------------------------------------------------------
	* 8.  S7 - Pesaran (2007) CIPS panel unit-root test (wraps xtcips)
	*-------------------------------------------------------------------
	if ("`cips'"!="") {
		capture which xtcips
		if (_rc) {
			di ""
			di as error "option {bf:cips()} requires the {bf:xtcips} command"
			di as error "{p 4 4 2}install it with: {stata ssc install xtcips}{p_end}"
			exit 199
		}
		tokenize `cips'
		local mlag "`1'"
		local blag "`2'"
		local nps : word count `psvars'
		if (`nps'==0) {
			di as error "no series available for the CIPS test"
			exit 198
		}
		tempname UMAT CV
		matrix `UMAT' = J(`nps',5,.)
		local rn ""
		di ""
		di as txt "{bf:Panel unit-root test for the partial sums (CIPS)}"
		di as txt "{hline 15}{c TT}{hline 62}"
		di as txt %14s "Variable" " {c |}" as txt %12s "CIPS" %12s "cv 10%" ///
			%12s "cv 5%" %12s "cv 1%" %13s "Verdict"
		di as txt "{hline 15}{c +}{hline 62}"
		local k = 0
		foreach v of local psvars {
			local ++k
			capture qui xtcips `v' if `touse' , maxlags(`mlag') bglags(`blag') `cipsopt'
			if (_rc) {
				di as txt %14s abbrev("`v'",14) " {c |}" as err %14s "not computable"
				continue
			}
			local cp = r(cips)
			local c10 = .
			local c05 = .
			local c01 = .
			capture matrix `CV' = r(cv)
			if (_rc==0) {
				local c10 = `CV'[1,1]
				local c05 = `CV'[1,2]
				local c01 = `CV'[1,3]
			}
			local verd "I(1)"
			if (`cp' < `c10' & !mi(`c10')) local verd "I(0) at 10%"
			if (`cp' < `c05' & !mi(`c05')) local verd "I(0) at 5%"
			if (`cp' < `c01' & !mi(`c01')) local verd "I(0) at 1%"
			di as txt %14s abbrev("`v'",14) " {c |}" as res %12.3f `cp' %12.2f `c10' ///
				%12.2f `c05' %12.2f `c01' as txt %13s "`verd'"
			matrix `UMAT'[`k',1] = `cp'
			matrix `UMAT'[`k',2] = `c10'
			matrix `UMAT'[`k',3] = `c05'
			matrix `UMAT'[`k',4] = `c01'
			matrix `UMAT'[`k',5] = cond("`verd'"=="I(1)",0,1)
			local rn "`rn' `v'"
		}
		di as txt "{hline 15}{c BT}{hline 62}"
		di as txt "{p 0 4 2}H0: homogeneous non-stationarity (Pesaran 2007). The test is left-tailed:" ///
			" reject when CIPS is more negative than the critical value. Critical values are"          ///
			" unreliable with unbalanced panels; see {help xtcips}.{p_end}"
		if ("`rn'"!="") {
			matrix colnames `UMAT' = CIPS cv10 cv5 cv1 stationary
			matrix rownames `UMAT' = `rn'
			return matrix cips = `UMAT' , copy
		}
	}

	*-------------------------------------------------------------------
	* 9.  graphics
	*-------------------------------------------------------------------
	local gnames ""
	if ("`grfre'"!="") {
		_xtasym_grfre `varlist' , dlist(`dlist') th(`th') touse(`touse') ///
			scheme(`scheme') saving(`saving') name(`name') `nodraw'
		local gnames "`gnames' `r(gnames)'"
	}
	if ("`grdist'"!="") {
		_xtasym_grdist `varlist' , dlist(`dlist') th(`th') touse(`touse') ///
			scheme(`scheme') saving(`saving') name(`name') `nodraw'
		local gnames "`gnames' `r(gnames)'"
	}
	if ("`grsum'"!="") {
		if ("`nogenerate'"=="") {
			_xtasym_grsum `varlist' , plist(`plist') nlist(`nlist') time(`time') ///
				touse(`touse') conv(`convention') scheme(`scheme')               ///
				saving(`saving') name(`name') `nodraw'
			local gnames "`gnames' `r(gnames)'"
		}
		else {
			di as txt "{p 0 4 2}note: {bf:grsum} draws the partial sums this command builds, so it is"  ///
				" skipped under {bf:nogenerate}.{p_end}"
		}
	}

	if ("`combine'"!="" & trim("`gnames'")!="") {
		local gn = cond("`name'"=="","xtasym","`name'")
		capture graph drop `gn'_all
		capture graph combine `gnames' , name(`gn'_all , replace)   ///
			graphregion(color(white)) plotregion(color(white)) `nodraw'
		if (_rc==0) local gnames "`gnames' `gn'_all"
	}

	*-------------------------------------------------------------------
	* 10. returns
	*-------------------------------------------------------------------
	return local graphs      "`gnames'"
	return local fdmvars     "`fdlist'"
	return local partialsums "`psvars'"
	return local varlist     "`varlist'"
	return local convention  "`convention'"
	return local panelvar    "`id'"
	return local timevar     "`time'"
	return scalar threshold  = `th'
	return scalar k          = `nvar'
end


*=====================================================================
* helper: refuse to clobber an existing variable unless replace
*=====================================================================
program define _xtasym_newvar
	version 14.0
	syntax anything(name=nm) [ , REPLACE ]
	if (strlen("`nm'") > 32) {
		di as error "generated name {bf:`nm'} exceeds 32 characters; shorten it with {bf:prefix()}"
		exit 198
	}
	capture confirm variable `nm'
	if (_rc==0) {
		if ("`replace'"=="") {
			di as error "variable {bf:`nm'} already exists"
			di as error "{p 4 4 2}specify {bf:replace} to overwrite it, or {bf:prefix()} to rename{p_end}"
			exit 110
		}
		drop `nm'
	}
end


*=====================================================================
* helper: run header
*=====================================================================
program define _xtasym_header
	version 14.0
	syntax [ , th(real 0) conv(string) nvar(integer 1) id(string) ///
		time(string) touse(string) gen(integer 1) ]

	qui su `time' if `touse' , meanonly
	local t1 = r(min)
	local t2 = r(max)
	qui count if `touse'
	local NT = r(N)
	tempvar tg
	qui egen byte `tg' = tag(`id') if `touse'
	qui count if `tg'==1
	local N = r(N)
	drop `tg'

	if ("`conv'"=="shin") {
		local cname "Shin, Yu and Greenwood-Nimmo (2014)"
		local sgn   "signed (negative-valued)"
		local wald  "b+ = b-"
	}
	else {
		local cname "Allison (2019)"
		local sgn   "absolute (non-negative)"
		local wald  "b+ = -b-"
	}

	di ""
	di as txt "{hline 78}"
	di as txt "{bf:xtasym}" _col(13) as txt "Directional asymmetry: partial sums for panel data"
	di as txt "{hline 78}"
	di as txt "Panel variable"    _col(24) "{c |} " as res "`id'"   as txt "   (n = " as res `N' as txt ")"
	di as txt "Time variable"     _col(24) "{c |} " as res "`time'" as txt "   (" as res `t1' as txt " to " as res `t2' as txt ")"
	di as txt "Observations used" _col(24) "{c |} " as res `NT'
	di as txt "Threshold c"       _col(24) "{c |} " as res %9.0g `th' as txt "   dead band [-c, c]"
	di as txt "Convention"        _col(24) "{c |} " as res "`cname'"
	di as txt "Negative arm"      _col(24) "{c |} " as res "`sgn'"
	di as txt "Symmetry test"     _col(24) "{c |} " as res "`wald'"
	if (`gen') {
		di as txt "Variables created"  _col(24) "{c |} " as res `=2*`nvar'' as txt "  (suffixes _p and _n)"
	}
	di as txt "{hline 78}"
end


*=====================================================================
* helper: colour palette -> r(c1) ... r(cN) as "R G B" triplets
*=====================================================================
program define _xtasym_pal, rclass
	version 14.0
	syntax [ , Scheme(string) N(integer 1) DUO ]

	*-- designed two-colour pairs: warm = increase, cool = decrease.
	*   Chosen for legibility on a white page rather than by position on
	*   the ramp, since the warm end of parula and viridis is too light.
	if ("`duo'"!="") {
		if ("`scheme'"=="parula") {
			return local pos "247 181 41"
			return local neg "62 38 168"
			return local zer "205 205 205"
		}
		else if ("`scheme'"=="viridis") {
			return local pos "53 183 121"
			return local neg "68 1 84"
			return local zer "205 205 205"
		}
		else if ("`scheme'"=="journal") {
			return local pos "213 94 0"
			return local neg "0 114 178"
			return local zer "190 190 190"
		}
		else {
			return local pos "45 45 45"
			return local neg "140 140 140"
			return local zer "215 215 215"
		}
		exit
	}

	if ("`scheme'"=="parula") {
		local na 8
		local a1 "62 38 168"
		local a2 "72 82 244"
		local a3 "46 135 247"
		local a4 "16 176 224"
		local a5 "56 194 164"
		local a6 "171 199 92"
		local a7 "254 195 55"
		local a8 "249 251 21"
	}
	else if ("`scheme'"=="viridis") {
		local na 9
		local a1 "68 1 84"
		local a2 "62 74 137"
		local a3 "49 104 142"
		local a4 "38 130 142"
		local a5 "31 158 137"
		local a6 "53 183 121"
		local a7 "109 205 89"
		local a8 "180 222 44"
		local a9 "253 231 37"
	}
	else if ("`scheme'"=="journal") {
		local na 8
		local a1 "0 114 178"
		local a2 "86 180 233"
		local a3 "0 158 115"
		local a4 "150 190 60"
		local a5 "230 159 0"
		local a6 "213 94 0"
		local a7 "204 121 167"
		local a8 "120 120 120"
	}
	else {
		local na 5
		local a1 "35 35 35"
		local a2 "85 85 85"
		local a3 "135 135 135"
		local a4 "185 185 185"
		local a5 "225 225 225"
	}

	if (`n' <= 0) local n 1
	forvalues i = 1/`n' {
		if (`n'==1) {
			local pos = 1
		}
		else {
			local pos = 1 + (`i'-1)*(`na'-1)/(`n'-1)
		}
		local lo = floor(`pos')
		if (`lo' < 1)      local lo = 1
		if (`lo' > `na'-1) local lo = `na'-1
		if (`lo' < 1)      local lo = 1
		local hi = min(`lo'+1,`na')
		local w  = `pos' - `lo'
		local out ""
		forvalues j = 1/3 {
			local cl : word `j' of `a`lo''
			local ch : word `j' of `a`hi''
			local cc = round((1-`w')*`cl' + `w'*`ch')
			if (`cc' < 0)   local cc 0
			if (`cc' > 255) local cc 255
			local out "`out' `cc'"
		}
		return local c`i' = trim("`out'")
	}
	return scalar n = `n'
end


*=====================================================================
* graph 1: directional composition bar
*=====================================================================
program define _xtasym_grfre, rclass
	version 14.0
	syntax varlist(numeric) [ , dlist(string) th(real 0) touse(string) ///
		scheme(string) saving(string) name(string) NODraw ]

	local nvar : word count `varlist'
	_xtasym_pal , scheme(`scheme') duo
	local cpos "`r(pos)'"
	local cneg "`r(neg)'"
	local czer "`r(zer)'"

	tempname M
	matrix `M' = J(`nvar',3,0)
	local lab ""
	local ok 0
	forvalues i = 1/`nvar' {
		local v : word `i' of `varlist'
		local d : word `i' of `dlist'
		qui count if `d' >  `th' & !mi(`d') & `touse'
		local np = r(N)
		qui count if `d' < -`th' & !mi(`d') & `touse'
		local nn = r(N)
		qui count if inrange(`d',-`th',`th') & !mi(`d') & `touse'
		local nz = r(N)
		local nt = `np'+`nn'+`nz'
		if (`nt'==0) local nt 1
		else local ok 1
		matrix `M'[`i',1] = 100*`np'/`nt'
		matrix `M'[`i',2] = 100*`nz'/`nt'
		matrix `M'[`i',3] = 100*`nn'/`nt'
		local sv = abbrev("`v'",14)
		local lab `"`lab' `i' "`sv'""'
	}
	if (`ok'==0) {
		return local gnames ""
		exit
	}

	local gn = cond("`name'"=="","xtasym_composition","`name'_composition")
	capture graph drop `gn'

	preserve
		clear
		qui set obs `nvar'
		qui svmat double `M' , name(_sh)
		qui gen int    _v  = _n
		qui gen double _a0 = 0
		qui gen double _a1 = _sh1
		qui gen double _a2 = _sh1 + _sh2
		qui gen double _a3 = 100
		twoway (rbar _a0 _a1 _v , horizontal barwidth(.60) color("`cpos'") lcolor(white) lwidth(vthin)) ///
		       (rbar _a1 _a2 _v , horizontal barwidth(.60) color("`czer'") lcolor(white) lwidth(vthin)) ///
		       (rbar _a2 _a3 _v , horizontal barwidth(.60) color("`cneg'") lcolor(white) lwidth(vthin)) ///
		       , legend(order(1 "Increases" 2 "No change" 3 "Decreases") rows(1) position(6) ring(1)    ///
		                region(lstyle(none)) size(*.85) symxsize(*.6))                                 ///
		         ylabel(`lab' , angle(0) labsize(*.85) notick nogrid)                                  ///
		         xlabel(0(20)100 , format(%3.0f) labsize(*.85) grid glcolor(gs14) glwidth(vthin))       ///
		         ytitle("") xtitle("Share of observed changes (%)" , size(*.9) margin(t=3))             ///
		         title("Directional composition of changes" , size(*1.05) color(black) margin(b=1))     ///
		         subtitle("threshold c = `th'" , size(*.8) color(gs7) margin(b=3))                      ///
		         yscale(reverse noline) xscale(noline)                                                  ///
		         graphregion(color(white) margin(l=3 r=6)) plotregion(color(white) lstyle(none))         ///
		         name(`gn' , replace) nodraw
	restore

	if ("`saving'"!="") capture qui graph save `gn' "`saving'_composition" , replace
	if ("`nodraw'"=="") graph display `gn'
	return local gnames "`gn'"
end


*=====================================================================
* graph 2: distribution of the first differences, split at the threshold
*=====================================================================
program define _xtasym_grdist, rclass
	version 14.0
	syntax varlist(numeric) [ , dlist(string) th(real 0) touse(string) ///
		scheme(string) saving(string) name(string) NODraw ]

	_xtasym_pal , scheme(`scheme') duo
	local cpos "`r(pos)'"
	local cneg "`r(neg)'"

	local nvar : word count `varlist'
	local gnames ""
	forvalues i = 1/`nvar' {
		local v : word `i' of `varlist'
		local d : word `i' of `dlist'
		qui count if !mi(`d') & `touse'
		if (r(N) < 10) continue

		*-- one common bin grid for both halves, so the two histograms
		*   are directly comparable and the counts add up
		qui su `d' if `touse' , meanonly
		local lo = r(min)
		local hi = r(max)
		if (`hi' <= `lo') continue
		local wd = (`hi' - `lo')/40

		local xl "xline(0 , lcolor(gs8) lpattern(dash) lwidth(thin))"
		if (`th' > 0) {
			local xl "xline(`=-`th'' `th' , lcolor(gs8) lpattern(dash) lwidth(thin))"
		}

		local gn = cond("`name'"=="","xtasym_dist_`v'","`name'_dist_`v'")
		capture graph drop `gn'
		capture noisily twoway                                                                        ///
		       (histogram `d' if `d' >  `th' & `touse' , frequency width(`wd') start(`lo')             ///
		                color("`cpos'") lcolor(white) lwidth(vvthin))                                  ///
		       (histogram `d' if `d' < -`th' & `touse' , frequency width(`wd') start(`lo')             ///
		                color("`cneg'") lcolor(white) lwidth(vvthin))                                  ///
		       , `xl'                                                                                  ///
		         legend(order(1 "Increases" 2 "Decreases") rows(1) position(6) ring(1)                 ///
		                region(lstyle(none)) size(*.85) symxsize(*.6))                                 ///
		         xtitle("First difference of `v'" , size(*.9) margin(t=3))                              ///
		         ytitle("Number of observations" , size(*.9) margin(r=3))                               ///
		         title("Distribution of changes: `v'" , size(*1.05) color(black) margin(b=3))           ///
		         ylabel(, angle(0) labsize(*.85) grid glcolor(gs14) glwidth(vthin))                     ///
		         xlabel(, labsize(*.85))                                                                ///
		         yscale(noline) xscale(noline)                                                          ///
		         graphregion(color(white) margin(l=3 r=5)) plotregion(color(white) lstyle(none))         ///
		         name(`gn' , replace) nodraw
		if (_rc) continue
		if ("`saving'"!="") capture qui graph save `gn' "`saving'_dist_`v'" , replace
		if ("`nodraw'"=="") graph display `gn'
		local gnames "`gnames' `gn'"
	}
	return local gnames "`gnames'"
end


*=====================================================================
* graph 3: partial-sum paths (cross-panel mean with interquartile band)
*=====================================================================
program define _xtasym_grsum, rclass
	version 14.0
	syntax varlist(numeric) [ , plist(string) nlist(string) time(string) ///
		touse(string) conv(string) scheme(string)                        ///
		saving(string) name(string) NODraw ]

	_xtasym_pal , scheme(`scheme') duo
	local cpos "`r(pos)'"
	local cneg "`r(neg)'"

	local nvar : word count `varlist'
	local gnames ""
	forvalues i = 1/`nvar' {
		local v  : word `i' of `varlist'
		local vp : word `i' of `plist'
		local vn : word `i' of `nlist'
		local gn = cond("`name'"=="","xtasym_path_`v'","`name'_path_`v'")
		capture graph drop `gn'

		if ("`conv'"=="shin") {
			local ynote "negative arm is signed, so the two paths open outwards under asymmetry"
		}
		else {
			local ynote "both arms are non-negative, so a gap between the paths signals asymmetry"
		}

		preserve
			qui keep if `touse'
			collapse (mean) _mp=`vp' _mn=`vn'   ///
			         (p25)  _lp=`vp' _ln=`vn'   ///
			         (p75)  _hp=`vp' _hn=`vn' , by(`time')
			capture noisily twoway                                                                  ///
			       (rarea _lp _hp `time' , color("`cpos'") fintensity(20) lwidth(none))              ///
			       (rarea _ln _hn `time' , color("`cneg'") fintensity(20) lwidth(none))              ///
			       (line  _mp `time'     , lcolor("`cpos'") lwidth(medthick))                        ///
			       (line  _mn `time'     , lcolor("`cneg'") lwidth(medthick))                        ///
			       , yline(0 , lcolor(gs9) lwidth(vthin))                                            ///
			         legend(order(3 "Positive partial sum" 4 "Negative partial sum") rows(1)         ///
			                position(6) ring(1) region(lstyle(none)) size(*.85) symxsize(*.6))       ///
			         xtitle("`time'" , size(*.9) margin(t=3))                                        ///
			         ytitle("Cumulated change in `v'" , size(*.9) margin(r=3))                       ///
			         title("Accumulated directional change: `v'" , size(*1.05) color(black) margin(b=1)) ///
			         subtitle("cross-panel mean, shaded interquartile range" , size(*.8) color(gs7) margin(b=3)) ///
			         note("`ynote'" , size(*.7) color(gs8))                                          ///
			         ylabel(, angle(0) labsize(*.85) grid glcolor(gs14) glwidth(vthin))              ///
			         xlabel(, labsize(*.85))                                                          ///
			         yscale(noline) xscale(noline)                                                    ///
			         graphregion(color(white) margin(l=3 r=5)) plotregion(color(white) lstyle(none))   ///
			         name(`gn' , replace) nodraw
			local grc = _rc
		restore

		if (`grc') continue
		if ("`saving'"!="") capture qui graph save `gn' "`saving'_path_`v'" , replace
		if ("`nodraw'"=="") graph display `gn'
		local gnames "`gnames' `gn'"
	}
	return local gnames "`gnames'"
end


*=====================================================================
* Mata: Pesaran (2015) CD statistic for one series over a panel
*   CD = sqrt( 2 / (N(N-1)) ) * sum_{i<j} sqrt(T_ij) * rho_ij
* Results are left in the Stata scalars __xta_cd __xta_p __xta_r
* __xta_a __xta_np __xta_n __xta_t
*=====================================================================
version 14.0
mata:

void _xtasym_cd(string scalar yv, string scalar idv, string scalar tv,
                string scalar tousev)
{
	real matrix    X, Y
	real colvector uid, ut, a, b, da, db, ok, yi, yj
	real scalar    n, N, T, i, j, k, r, c, m
	real scalar    sumr, npair, tij, rij, sa, sb, sumabs, sumrho, ttot, cd

	X = st_data(., (yv, idv, tv), tousev)
	X = select(X, (X[.,1] :!= .))
	n = rows(X)
	if (n < 4) {
		_error("too few observations for the CD statistic")
	}

	uid = uniqrows(X[.,2])
	ut  = uniqrows(X[.,3])
	N   = rows(uid)
	T   = rows(ut)
	if (N < 2) {
		_error("the CD statistic needs at least two panels")
	}
	if (N > 1000) {
		_error("the CD statistic is O(n^2) and is capped at 1000 panels")
	}

	Y = J(N, T, .)
	r = 1
	for (k = 1; k <= n; k++) {
		while (r < N) {
			if (X[k,2] == uid[r]) {
				break
			}
			r = r + 1
		}
		c = 0
		for (m = 1; m <= T; m++) {
			if (X[k,3] == ut[m]) {
				c = m
				m = T
			}
		}
		if (c > 0) {
			Y[r,c] = X[k,1]
		}
	}

	sumr   = 0
	sumrho = 0
	sumabs = 0
	npair  = 0
	ttot   = 0

	for (i = 1; i <= N-1; i++) {
		yi = Y[i,.]'
		for (j = i+1; j <= N; j++) {
			yj = Y[j,.]'
			ok = (yi :!= .) :* (yj :!= .)
			tij = sum(ok)
			if (tij >= 3) {
				a  = select(yi, ok)
				b  = select(yj, ok)
				da = a :- mean(a)
				db = b :- mean(b)
				sa = sqrt(sum(da :* da))
				sb = sqrt(sum(db :* db))
				if (sa > 0) {
					if (sb > 0) {
						rij    = sum(da :* db) / (sa * sb)
						sumr   = sumr   + sqrt(tij) * rij
						sumrho = sumrho + rij
						sumabs = sumabs + abs(rij)
						ttot   = ttot   + tij
						npair  = npair  + 1
					}
				}
			}
		}
	}

	if (npair < 1) {
		_error("no pair of panels has enough overlapping observations")
	}

	cd = sqrt(2 / (N * (N - 1))) * sumr

	st_numscalar("__xta_cd", cd)
	st_numscalar("__xta_p",  2 * normal(-abs(cd)))
	st_numscalar("__xta_r",  sumrho / npair)
	st_numscalar("__xta_a",  sumabs / npair)
	st_numscalar("__xta_np", npair)
	st_numscalar("__xta_n",  N)
	st_numscalar("__xta_t",  ttot / npair)
}

end
