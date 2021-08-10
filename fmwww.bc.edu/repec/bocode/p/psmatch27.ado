*! version 1.2.4 26jan2004 E. Leuven, B. Sianesi
program define psmatch27, sortpreserve rclass
	version 7.0
	#delimit ;
	syntax varlist(min=1) [if] [in] [,
	OUTcome(varlist)
	Pscore(varname)
	Neighbor(integer 1)
	TIES
	RADIUS
	CALiper(real 0)
	PCALiper(real 0)
	MAHALanobis(varlist)
	ADD
	KERNEL
	LLR
	Kerneltype(string)
	BWidth(string)
	COMmon
	TRIM(real 100)
	ODDS
	LOGIT
	INDEX
	QUIetly
	NOREPLacement
	DESCending
	NOWARNings
	ATE
	W(string)
	SPLINE
	NKnots(integer 0)
	];
	#delimit cr

	/* check weight */
	if ("`weight'" != "") {
		local wgt `"[aw `exp']"'
	}

	/* record sort order */
	tempvar order
	g long `order' = _n

	/* clean up data */
	cap label drop _treated
	cap label drop _support
	foreach v in _treated _support _weight _pscore _pdif _mdif _id _n1 _nn {
		cap drop `v'
	}
	if ("`outcome'"!="") {
		foreach v of varlist `outcome' {
			cap drop _`v'
		}
	}

	global OUTVAR `outcome'

	/* determine subset we work on */
	marksample touse
	capture markout `touse' `outcome' `control' `mahalanobis'

	/* separate treatment indicator from varlist */
	tokenize `varlist'
	local treat `1'
	macro shift
	local varlist "`*'"
	local k : word count `varlist'

	/* set caliper to missing (infinity) if not requested */
	if (`caliper'==0) {
		local caliper = .
	}
	if (`pcaliper'==0) {
		local pcaliper = .
	}

	/* determine matching metric */
	local nmvars : word count `mahalanobis'
	if (`nmvars'>0) {
		local metric = "mahalanobis"
	}
	else local metric = "pscore"

	if (`k'==0 & "`pscore'"=="" & "`metric'"=="pscore") {
		di as error "You should either specify a " as input "varlist" as error " or " as input "propensity score"
		exit 198
	}
	if (`k'>0 & "`pscore'"!="") {
		di as error "You cannot specify both a " as input "varlist" as error " AND a " as input "propensity score"
		exit 198
	}
	if (`k'==0 & "`pscore'"=="" & "`add'"!="") {
		di as error "Since you used option " as input "add" as error " you must provide the propensity score"
		exit 198
	}
	if ("`metric'"=="mahalanobis" & "`add'"=="" & (`k'>0 | "`pscore'"!="")) {
		local add "add"
		di as text "Propensity score is added to the Mahalanobis variable list"
	}

	/* check matching method */
	local method "neighbor"
	if ("`kernel'"!="") {
		local method "`kernel'"
	}
	if ("`llr'"!="") {
		local method "`llr'"
	}

	if ("`llr'"!="" & "`kernel'"!="") {
		di as error "You cannot do kernel and llr matching at the same time"
		exit 198
	}

	if ("`noreplacement'"!="" & ("`method'"!="neighbor" | `neighbor'>1 )) {
		di as error "Matching without replacement is only implemented with 1-to-1 matching"
		exit 198
	}
	if ("`descending'"!="" & "`noreplacement'"=="") {
		di as error "Option " as input "descending" as error " makes only sense when matching without replacement"
		exit 198
	}

	/* check kerneltype */
	if ("`method'"=="kernel" & "`kerneltype'"=="") {
		local kerneltype "epan"
	}
	if ("`method'"=="llr" & "`kerneltype'"=="") {
		local kerneltype "tricube"
	}
	if !("`kerneltype'"=="" | "`kerneltype'"=="normal" | "`kerneltype'"=="epan" | "`kerneltype'"=="biweight" | "`kerneltype'"=="uniform" | "`kerneltype'"=="tricube") {
		di as error "Kerneltype `kerneltype' not recognized"
		exit 198
	}

	/* radius matching is like kernel matching with uniform kernel */
	if ("`radius'"!="") {
		local method "kernel"
		local kerneltype "uniform"
		local bwidth = `caliper'
	}

	if ("`bwidth'"=="") {
		local bwidth "0.06"
	}

	/* estimate propensity score */
	if ("`varlist'"!="") {
		if ("`logit'"=="") {
			local logit "probit"
		}
		`quietly' `logit' `treat' `varlist' if `touse', nolog
		tempvar pscore
		qui predict double `pscore', `index'
		qui g double _pscore = `pscore'
		label var _pscore "psmatch2: Propensity Score"
	}
	else if ("`metric'"=="pscore" | ("`metric'"=="mahalanobis" & "`add'"!="")) {
		qui g double _pscore = `pscore'
		label var _pscore "psmatch2: Propensity Score"
	}
	capture markout `touse' _pscore

	/* match on log odds ratio if requested, only with logit? */
	if ("`odds'"!="") {
		qui replace _pscore = ln(_pscore/(1 - _pscore))
	}

	/* create treatment indicator variable */
	qui g byte _treated = `treat' if `touse'
	label variable _treated "psmatch2: Treatment assignment"
	label define _treated 0 "Untreated" 1 "Treated"
	label value _treated _treated

	/* common support if requested */
	if (("`common'"!="" | `trim'<100) & ("`varlist'"=="" & "`pscore'"=="")) {
		di as error "With option 'common' a propensity score is needed. Provide one"
		di as error "with option 'pscore()' or estimate one. See the help file for more details."
		exit 198
	}
	qui g byte _support = 1 if `touse'
	label variable _support "psmatch2: Common support"
	label define _support 0 "Off support" 1 "On support"
	label value _support _support
	if (("`common'"!="" | `trim'<100) & ("`varlist'"!="" | "`pscore'"!="")) {
		if !inrange(`trim',0,100) {
			di as error "Trim level out of range"
			exit 198
		}
		qui _Support_ `pscore', level(`trim') `ate'
	}

	/* nobs for convenience */
	qui count if _treated==0 & _support==1
	global N_control = r(N)
	qui count if _treated<=1 & _support==1
	global N_total = r(N)

	/* do nearest neighbor if llr with tricube */
	if ("`method'"=="llr" & "`kerneltype'"=="tricube" & "`metric'"=="pscore") {
		local method "neighbor"
		if ("`bwidth'"=="") {
			local bwidth "0.8"
		}
		global OUTVAR ""
		foreach v of varlist `outcome' {
			cap drop _s_`v'
			qui ksm `v' _pscore if _treated==0 & _support==1, lowess nograph gen(_s_`v') bw(`bwidth')
			if ("`ate'"!="") {
				tempvar s`v'
				qui ksm `v' _pscore if _treated==1 & _support==1, lowess nograph gen(`"s`v'"') bw(`bwidth')
				qui replace _s_`v' = `"s`v'"' if _treated==1 & _support==1
			}
			global OUTVAR $OUTVAR _s_`v'
			label var _s_`v' "psmatch2: smoothed outcome variable"
		}
	}

	/* spline */
	if ("`spline'"!="") {
		local method "neighbor"
		if ("`nknots'"=="0") {
			local nknots = int($N_control^0.25)
		}
		global OUTVAR ""
		foreach v of varlist `outcome' {
			cap drop _s_`v'
			qui spline `v' _pscore if _treated==0 & _support==1, gen(_s_`v') nknots(`nknots') nograph
			if ("`ate'"!="") {
				if ("`nknots'"=="0") {
					local nknots = int($N_treated^0.25)
				}
				tempvar s`v'
				qui spline `v' _pscore if _treated==1 & _support==1, gen(`"s`v'"') nknots(`nknots') nograph
				qui replace _s_`v' = `"s`v'"' if _treated==1 & _support==1
			}
			global OUTVAR $OUTVAR _s_`v'
			label var _s_`v' "psmatch2: smoothed outcome variable using -spline-"
		}
	}


	/* create vars we will need */
	qui g double _weight = _treated if _support==1
	if "`ate'"!="" {
		qui replace _weight = 0 if _treated==1 & _support==1
	}

	if ("`method'"=="neighbor") {
		qui g _n1 = .
		label var _n1 "psmatch2: ID of nearest neighbor"
		qui g _nn = 0 if _support==1
		label var _nn "psmatch2: # matched neighbors"
		label var _weight "psmatch2: # Matches per obs."
	}
	else label var _weight "psmatch2: weight of matched controls"

	/* outcome of matches */
	if ("`outcome'"!="") {
		foreach v of varlist `outcome'	 {
			if ("`ate'"=="") {
				qui g double _`v' = 0 if _support==1 & _treated==1
			}
			else qui g double _`v' = 0 if _support==1
			label var _`v' "psmatch2: value of `v' of match(es)"
		}
	}

	/* check for duplicate pscores */
	if ("`nowarnings'"=="" & "`metric'"=="pscore") {
		sort _treated _pscore
		cap by _treated _pscore: assert _N==1 if _treated==0 & _support==1
		if (!_rc & "`ate'"!="") {
			cap by _treated _pscore: assert _N==1 if _treated==1 & _support==1
		}
		if (_rc & "`method'"=="neighbor") {
			di as res "There are observations with identical propensity score values."
			di as res "The sort order of the data could affect your results."
			di as res "Make sure that the sort order is random before calling psmatch2."
		}
	}

	/* sort data on treatment status and pscore and create id */
	if ("`metric'"=="pscore" & "`method'"=="neighbor") {
		if ("`descending'"=="") {
			gsort - _support _treated _pscore `order'
		}
		else gsort - _support _treated - _pscore `order'
	}
	else gsort - _support _treated

	if ("`method'"=="neighbor") {
		g _id = _n
		label var _id "psmatch2: Identifier (ID)"
	}

	/* calculate within sample covariance matrix if necessary */
	if ("`metric'"=="mahalanobis") {
		if "`add'"!="" {
			local mahalanobis _pscore `mahalanobis'
		}
		if ("`w'"=="") {
			tempname XX0 XX1 w
			qui mat accum `XX0' = `mahalanobis' if _treated==0, dev noc
			qui mat accum `XX1' = `mahalanobis' if _treated==1, dev noc
			mat `w' = syminv((`XX0' + `XX1')/($N_total - 2))
		}
		local matchon `mahalanobis'
	}
	if ("`metric'"=="pscore") {
		local matchon `pscore'
	}

	if ("`method'"=="neighbor" & "`metric'"=="pscore") {
		char _weight[Type] "fweight"
		if ("`ate'"!="") {
			qui _Match_neighbor `pscore', atu out(`outcome') neighbor(`neighbor') caliper(`caliper') `noreplacement' `ties'
		}
		qui _Match_neighbor `pscore', out(`outcome') neighbor(`neighbor') caliper(`caliper') `noreplacement' `ties'
		/* difference pscore between treat obs and nearest match */
		qui g double _pdif = abs(_pscore - _pscore[_n1])
		label var _pdif "psmatch2: abs(pscore - pscore[nearest neighbor])"
	}
	if ("`method'"=="neighbor" & "`metric'"=="mahalanobis") {
		char _weight[Type] "fweight"
		qui _Match_mahalanobis `mahalanobis', out(`outcome') caliper(`caliper') pcaliper(`pcaliper') w(`w') `ate'
	}
	if ("`method'"=="kernel") {
		char _weight[Type] "aweight"
		qui _Match_kernel `matchon', out(`outcome') metric(`metric') kerneltype(`kerneltype') bw(`bwidth') w(`w') `ate'
	}
	if ("`method'"=="llr") {
		char _weight[Type] "iweight"
		qui _Match_llr `matchon', out(`outcome') metric(`metric') kerneltype(`kerneltype') bw(`bwidth') w(`w') `ate'
	}

	/* controls off support */
	qui replace _weight = . if _weight==0 | _support==0

	di as text "Matching Method = " as res "`method'" as text " Metric = " as res "`metric'"
	if ("`outcome'"!="") {
		/* create header output table */
		di as text "{hline 28}{c TT}{hline 37}"
		di as text "        Variable     Sample {c |}    Treated     Controls   Difference"
		di as text "{hline 28}{c +}{hline 37}"

		/* create body and return results */
		foreach v of varlist `outcome' {
			quietly {
				/* no matched outcome for obs off support */
				replace _`v' = . if _support==0

				tempname m1t m0t u0u u1u att dif0
				sum `v' if _treated==1, mean
				scalar `u1u' = r(mean)
				sum `v' if _treated==0, mean
				scalar `u0u' = r(mean)

				sum `v' if _treated==1 & _support==1, mean
				scalar `m1t' = r(mean)
				local n1 = r(N)
				sum _`v' if _treated==1 & _support==1, mean
				scalar `m0t' = r(mean)

				scalar `att' = `m1t' - `m0t'
				scalar `dif0' = `u1u' - `u0u'

				return scalar att = `att'
				return scalar att_`v' = `att'

				if "`ate'"!="" {
					tempname m0u m1u atu ate
					sum _`v' if _treated==0 & _support==1, mean
					scalar `m1u' = r(mean)
					sum `v' if _treated==0 & _support==1, mean
					scalar `m0u' = r(mean)
					local n0 = r(N)

					scalar `atu' = `m1u' - `m0u'
					scalar `ate' = `att'*`n1'/(`n0'+`n1') + `atu'*`n0'/(`n0'+`n1')

					return scalar atu = `atu'
					return scalar atu_`v' = `atu'
					return scalar ate = `ate'
					return scalar ate_`v' = `ate'
				}
			}

			di as text %16s abbrev("`v'",16) "  Unmatched {c |}" as result %11.0g `u1u' "  " %11.0g `u0u' "  " %11.0g `dif0'
			di as text              _col(17) "        ATT {c |}" as result %11.0g `m1t' "  " %11.0g `m0t' "  " %11.0g `att'
			if ("`ate'"!="") {
				di as text _col(17) "        ATU {c |}" as result %11.0g `m0u' "  " %11.0g `m1u' "  " %11.0g `atu'
				di as text _col(17) "        ATE {c |}" _col(56) as result %11.0g `ate'
			}
			di as text "{hline 28}{c +}{hline 37}"
		}
		tab _treated _support
	}

	/* get rid of evil globals */
	macro drop N_control N_total NN OUTVAR
end

/* update outcome vars */
program define varupdate
	syntax varlist(min=1), i(integer) j0(integer)
	foreach v1 of var `varlist' {
		foreach v2 of var $OUTVAR {
			replace _`v1' = _`v1' + `v2'[`j0'] in `i'
		}
	}
end


/* ONE-DIMENSIONAL NEAREST NEIGHBOR MATCHING */
program define _Match_neighbor
	syntax varname [, OUTcome(varlist) Neighbor(real 1) CALiper(string) NOREPLacement ATU TIES]
	tempname dif0 dif1 idlist

	/* this will contain the id's of the matches */
	g `idlist' = .
	/* nr of matches */
	global NN = 0
	/* when matching without replacement jump to next obs */
	if ("`noreplacement'"!="") {
		local next 1
	}
	else local next 0

	local i = $N_control + 1
	local i1 $N_total
	local j0 1
	local j1 $N_control
	if ("`atu'"!="") {
		/* match treated to controls */
		local i 1
		local i1 $N_control
		local j0 = $N_control + 1
		local j1 $N_total
	}

	/* define comparison range for controls */
	while (`i'<=`i1' & `j0'<=`j1' ) {
		/* define comparison range for treated if necessary */
		/* find nearest neighbor */
		local j `j0'
		scalar `dif1' = abs(`varlist'[`j'] - `varlist'[`i'])
		while (`j'<`j1') {
			local j = `j' + 1
			scalar `dif0' = `dif1'
			scalar `dif1' = abs(`varlist'[`j'] - `varlist'[`i'])
			if (`dif1'>`dif0') {
				local j `j1'
			}
			if (`dif1'<`dif0') {
				local j0 `j'
			}
		}
		/* update match and match-id variables */
		if (abs(_pscore[`i']-_pscore[`j0'])<`caliper') {
			replace _n1 = `j0' in `i'
			global NN = $NN + 1
			replace `idlist' = _id[`j0'] in $NN
			/* match ties */
			if ("`ties'"!="") {
				_Match_ties `varlist', obs(`i') j0(`j0') j1(`j1') outcome(`outcome') idlist(`idlist')
			}
			/* match remaining neighbors */
			if (`neighbor'>1) {
				_Match_neighbor_2 `varlist', obs(`i')  j0(`j0') j1(`j1') idlist(`idlist') neighbor(`neighbor') caliper(`caliper') outcome(`outcome') `ties'
			}
			forvalues k=1/$NN {
				local obs = `idlist'[`k']
				replace _weight = _weight + 1/$NN in `obs'
				cap varupdate `outcome', i(`i') j0(`obs')
			}
			replace _nn = $NN in `i'
			global NN 0
		}
		else qui replace _support = 0 in `i'
		/* when matching without replacement jump to next obs, but not beyond last control */
		local j0 = `j0' + `next'
		/* next treatment obs */
		local i = `i' + 1
	}
	/* move non-matched obs of support when doing matching without replacement */
	replace _support = 0 if _treated==("`atu'"!="atu") & _n1>=.
	/* create outcome var */
	if ("`outcome'"!="" & (`neighbor'>1 | "`ties'"!="")) {
		foreach v of varlist `outcome' {
			qui replace _`v' = _`v'/_nn if _treated==("`atu'"!="atu") & _support==1
		}
	}
end

program define _Match_neighbor_2
	syntax varname, obs(real) j0(real) j1(real) idlist(varname) neighbor(real) CALiper(string) OUTcome(varlist) [TIES]
	tempname dif0 dif1 dif

	local k 1
	local pos0 = `j0' - 1
	local pos1 = `j0' + 1
	while (`k'<`neighbor') {
		scalar `dif0' = abs(`varlist'[`pos0'] - `varlist'[`obs'])
		scalar `dif1' = abs(`varlist'[`pos1'] - `varlist'[`obs'])
		if ((`dif0'<=`dif1' & `pos0'>=1) | (`pos0'>=1 & `pos1'>`j1')) {
			local j0 `pos0'
			local pos0 = `pos0' - 1
		}
		else if (`pos1'<=`j1') {
			local j0 `pos1'
			local pos1 = `pos1' + 1
		}
		else local k `neighbor'
		/* update match and match-id variables */
		if (abs(_pscore[`obs']-_pscore[`j0'])<`caliper' & `k'<`neighbor') {
			global NN = $NN + 1
			replace `idlist' = _id[`j0'] in $NN
			if ("`ties'"!="") {
				_Match_ties `varlist', obs(`obs') j0(`j0') j1(`j1') outcome(`outcome') idlist(`idlist')
			}
			local k = `k' + 1
		}
		else local k `neighbor'
	}
end

program define _Match_ties
	syntax varname, obs(real) j0(real) j1(real) idlist(varname) [OUTcome(varlist)]
	tempname dif
	local i = `j0' + 1
	scalar `dif' = abs(`varlist'[`j0'] - `varlist'[`i'])
	while (`dif'==0 & `i'<=`j1') {
		global NN = $NN + 1
		replace `idlist' = _id[`i'] in $NN
		local i = `i' + 1
		scalar `dif' = abs(`varlist'[`j0'] - `varlist'[`i'])
	}
end


/* MAHALANOBIS NEAREST NEIGHBOR MATCHING */
program define _Match_mahalanobis
	syntax varlist(min=1) [, OUTcome(varlist) PCALiper(string) CALiper(string) Neighbor(real 1) W(string) ATE]
	tempname dif pdif base

	_Dif_mbase `varlist', base(`base') w(`w')

	g _mdif = .
	label var _mdif "psmatch2: Difference with match on Mahalanobis metric"

	if ("`ate'"!="") {
		local start 1
	}
	else local start = $N_control + 1

	forvalues obs = `start'/$N_total {
		/* generate difference variable if we match within pscore caliper, otherwise cap */
		if ("`pcaliper'"!=".") {
			_Dif_pscore _pscore if _support==1 & _treated==(`obs'<=$N_control), obs(`obs') dif(`pdif')
			_Dif_mahalanobis `varlist' if _support==1 & _treated==(`obs'<=$N_control) & `pdif'<`pcaliper', obs(`obs') dif(`dif') base(`base') w(`w')
		}
		else _Dif_mahalanobis `varlist' if _support==1 & _treated==(`obs'<=$N_control), obs(`obs') dif(`dif') base(`base') w(`w')

		/* find nearest neighbor */
		sum `dif', mean
		if (r(min)<`caliper') {
			replace _mdif = r(min) in `obs'
			sum _id if `dif'==r(min), mean
			replace _weight = _weight + 1 in `r(min)'
			replace _n1 = r(min) in `obs'
		}
		else replace _support = 0 in `obs'

		drop `dif'
		cap drop `pdif'
	}

	if ("`outcome'"!="") {
		foreach v of varlist `outcome' {
			qui replace _`v' = `v'[_n1]
		}
	}
end

/* KERNEL MATCHING */
program define _Match_kernel
	syntax varlist(min=1) [, OUTcome(varlist) Kerneltype(string) BWidth(real 0.06) CALiper(string) METric(string) W(string) ATE]
	tempname weight dif base
	tempvar out

	if ("`metric'"=="mahalanobis") {
		_Dif_mbase `varlist', base(`base') w(`w') 
	}

	if ("`ate'"!="") {
		local start 1
	}
	else local start = $N_control + 1

	forvalues obs = `start'/$N_total {
		_Dif_`metric' `varlist' if _support==1 & _treated==(`obs'<=$N_control), obs(`obs') dif(`dif') base(`base') w(`w')
		_Kernel_ `kerneltype' `weight' `dif' `bwidth'
		replace _weight = _weight + `weight' if `weight'!=.
	
		if ("`outcome'"!="") {
			foreach v of varlist `outcome' {
				sum `v' [aw=`weight'] if _support==1 & _treated==(`obs'<=$N_control), mean
				if r(mean)!=. {
					replace _`v' = r(mean) in `obs'
				}
			}
		}
		cap assert `weight'==.
		if (_rc==0) {
			 replace _support = 0 in `obs'
		}

		drop `weight' `dif'
	}
end

/* LLR MATCHING */
program define _Match_llr
	syntax varlist(min=1) [, OUTcome(varname) Kerneltype(string) BWidth(real 0.06) CALiper(string) METric(string) W(string) ATE]

	tempname weight dif V base
	tempvar out

	if ("`metric'"=="mahalanobis") {
		_Dif_mbase `varlist', base(`base') w(`w')
	}

	if ("`ate'"!="") {
		local start 1
	}
	else local start = $N_control + 1

	forvalues obs = `start'/$N_total {
		_Dif_`metric' `varlist' if _support==1 & _treated==(`obs'<=$N_control), obs(`obs') dif(`dif') base(`base') w(`w')
		_Kernel_ `kerneltype' `weight' `dif' `bwidth'
		sum `dif' [aw=`weight']
		scalar `V' = r(Var)*(r(N)-1)/r(N)
		replace _weight = _weight + `weight'*(`V' + r(sum)^2 - r(sum)*`dif')/`V' if `weight'!=.
		if ("`outcome'"!="") {
			foreach v of varlist `outcome' {
				cap reg `v' `dif' [aw=`weight'] if _support==1 & _treated==(`obs'<=$N_control)
				if (!_rc) {
					replace _`v' = _b[_cons] in `obs'
				}
				else replace _support = 0 in `obs'
			}
		}
		drop `weight' `dif'
	}
end


/* COMMON SUPPORT FUNCTIONS */
program define _Support_
	syntax varname [, level(real 100) untreated ate]
	if (`level'==100) {
		sum `varlist' if _treated==0, mean
		replace _support = 0 if (`varlist'<r(min) | `varlist'>r(max)) & _treated==1
		if ("`ate'"!="") {
			sum `varlist' if _treated==1, mean
			replace _support = 0 if (`varlist'<r(min) | `varlist'>r(max)) & _treated==0
		}
	}
	else {
		_Support_trim `varlist', level(`level')
		if ("`ate'"!="") {
			_Support_trim `varlist', level(`level') treated(0)
		}
	}
end


program define _Support_trim
	syntax varname [, level(real 100) treated(integer 1)]
	tempvar x0 y0
	kdensity `varlist' if _treated==(1-`treated'), nograph at(`varlist') gen(`x0' `y0')
	replace _support = 0 if `y0'==0 & _treated==`treated'
	if (`level'>0) {
		_pctile `y0' if _treated==`treated', p(`level')
		replace _support = 0 if `y0'<r(r1) & _treated==`treated'
	}
end


/* DIFFERENCING FUNCTIONS */
program define _Dif_pscore
	syntax varname [if], obs(int) dif(string) [base(string) W(string)]
	qui g double `dif' = abs(`varlist' - `varlist'[`obs']) `if'
end


program define _Dif_mahalanobis
	syntax varlist [if], obs(int) dif(string) base(string) W(string)
	tokenize `varlist'
	tempname b
	local k : word count `varlist'
	/* extract data row vector x[i] into b */
	mat `b' = J(1,`k',`1'[`obs'])
	mat colname `b' = `varlist'
	forvalues i = 2/`k' {
		mat `b'[1,`i'] = ``i''[`obs']
	}
	/* calculate W*x[i] */
	mat `b' = `b'*`w'
	/* scoring gives x'Wx[i] */
	mat score double `dif' = `b' `if'
	/* the following then gives (x-x[i])*W(x-x[i]) */
	replace `dif' = `base' - 2*`dif' + `base'[`obs'] `if'
end


/* calculates x'Wx used by mahalanobis metric, needs to be done only once */
program define _Dif_mbase
	syntax varlist , base(string) W(string)
	tokenize `varlist'
	g double `base' = 0
	local k = rowsof(`w')
	forvalues i = 1/`k' {
		forvalues j = `i'/`k' {
			replace `base' = `base' + (1 + (`i'!=`j'))*`w'[`i',`j']*(``i'')*(``j'')
		}
	}
end


/* VARIOUS KERNELS */
program define _Kernel_
	args kernel weight dif bwidth
	
	if ("`kernel'"=="epan") {
		qui g double `weight' = 1 - (`dif'/`bwidth')^2 if abs(`dif')<=`bwidth'
	}
	else if ("`kernel'"=="normal") {
		qui g double `weight' = normden(`dif'/`bwidth')
	}
	else if ("`kernel'"=="biweight") {
		qui g double `weight' = (1 - (`dif'/`bwidth')^2)^2 if abs(`dif')<=`bwidth'
	}
	else if ("`kernel'"=="uniform") {
		qui g double `weight' = 1 if abs(`dif')<=`bwidth'
	}
	else if ("`kernel'"=="tricube") {
		qui g double `weight' = (1-abs(`dif'/`bwidth')^3)^3 if abs(`dif')<=`bwidth'
	}
	/* normalize sum of weights to 1 */
	sum `weight', mean
	replace `weight' = `weight'/r(sum)
end
