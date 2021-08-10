*! -glcurve5- is an outdated release of -glcurve- (for Stata 5 or Stata 6 users only!)
*! version 1 Stephen P. Jenkins - Philippe Van Kerm, Dec 1998
* Syntax: glcurve5 y [fw aw] [if in], [GLvar(x1) Pvar(x2) SOrtvar(svar)
*                 BY(gvar) SPlit GRaph REPLACE graph_options]

cap pr drop glcurve5
pr def glcurve5

	version 5.0

	local varlist "req ex max(1)"
	local if "opt"
	local in "opt"
	local options "GLvar(string) Pvar(string) SOrtvar(string)"
	local options "`options' BY(string) SPlit NOGRaph REPLACE"
	local options "`options' Symbol(string) Connect(string) *"
	local weight "aweight fweight"
	parse "`*'"
	parse "`varlist'", parse (" ")
	local inc "`1'"

	tempvar cumwy cumw maxw badinc touse wi gl p
	tempname byname

	if "`nograph'"~="" {loc graph ""}
	else {loc graph "graph"}

	if "`by'"~="" {
		confirm variable `by'
		local nvar : word count `by'
		if `nvar'~=1 {
			di in red "too many by()-variables specified"
			exit 103
			}
		capture confirm string variable `by'
		if _rc==0 {
			di in red "by()-variable must be numeric"
			exit 109
			}
		if "`graph'"~="" & "`split'"=="" {
			di in red "-split- must be used to combine -by()- with a graph." _c
      di in red " -nograph- option assumed."
			loc graph = ""
			}
		}
	else {
		if "`split'"~="" {
			di in red "Option -split- must be combined with -by()-." _c
			di in red " -split- ignored."
			loc split ""
			}
		}


	if "`replace'"~="" {
		if "`split'"~="" & "`by'"~="" {
			loc prefix = substr(trim("`glvar'"),1,4)
			cap drop `prefix'_*
			cap drop `pvar'
			}
		else {
			cap drop `glvar'
			cap drop `pvar'
			}
		}


	if "`sortvar'" ~= "" {confirm variable `sortvar' }
	if "`weight'" == "" {ge byte `wi' = 1}
	else {ge `wi' `exp'}

	mark `touse' `if' `in'
	markout `touse' `varlist' `sortvar' `by'

	if "`split'"==""{
		if "`glvar'" ~= "" {
			confirm new variable `glvar'
			di in blue "New variable " in ye "`glvar'" in blue " created."
			}
		else {tempvar glvar}
		}
	else {
		if "`glvar'" == "" {
			qui tab `by' `by' if  `touse', matrow(`byname')
			loc i = 1
			while `i' <= rowsof(`byname') {
				tempvar newvar`i'
				loc i = `i'+1
				}
			}
		else {
			qui tab `by' `by' if  `touse', matrow(`byname')
			loc prefix = substr(trim("`glvar'"),1,4)
			loc i = 1
			while `i' <= rowsof(`byname') {
				loc suffix = `byname'[`i',1]
				loc newvar`i' "`prefix'_`suffix'"
				confirm new variable `newvar`i''
   			di in blue "New variable " in ye "`newvar`i''" in blue " created."
				loc i = `i'+1
				}
			}
		}


	if "`pvar'" ~= "" {
		confirm new variable `pvar'
		di in blue "New variable " in ye "`pvar'" in blue " created."
		}
	else {tempvar pvar}


	quietly {

	count if `inc' < 0 & `touse'
	local ct = _result(1)
	if `ct' > 0 {
		noi di " "
		noi di in blue "Warning: `inc' has `ct' values < 0." _c
		noi di in blue " Used in calculations"
		}
	count if `inc' == 0 & `touse'
	local ct = _result(1)
	if `ct' > 0 {
		noi di " "
		noi di in blue "Warning: `inc' has `ct' values = 0." _c
		noi di in blue " Used in calculations"
		}

	tempvar placebo
	if "`by'"=="" {
		gen `placebo' = 1
		loc by = "`placebo'"
		}

	if "`sortvar'" == "" {gsort `by' `inc'}
	else {gsort `by' `sortvar'}
	by `by': ge double `cumwy' = sum(`wi'*`inc') if `touse'
	by `by': ge double `cumw' = sum(`wi') if `touse'
	egen `maxw' = max(`cumw') , by(`by')
	ge double `pvar' = `cumw'/`maxw' if `touse'
	label variable `pvar' "Cum. Pop. Prop."

	if "`split'"=="" {
				ge `glvar' = `cumwy'/`maxw' if `touse'
				label variable `glvar' "Cum. Dist. of `inc'/_N"
				if "`graph'"~="" {
					if "`symbol'"=="" {loc symbol "."}
					if "`connect'"=="" {loc connect "l"}
					graph `glvar' `pvar' if `touse', s(`symbol') c(`connect') `options'
					}
				}
	else {
		loc lname : value label `by'
		loc i = 1
		while "`newvar`i''"~="" {
			if "`sortvar'" == "" {gsort `by' `inc'}
			else {gsort `by' `sortvar'}
			by `by': ge `newvar`i'' = `cumwy'/`cumw'[_N]  /*
																					*/ if `touse' & `by'==`byname'[`i',1]
			if "`lname'"~="" {
				loc cl = `byname'[`i',1]
				loc lab : label `lname' `cl'
				label variable `newvar`i'' "`inc'[`lab']"
				}
			local listvar "`listvar' `newvar`i''"
			loc i = `i'+1
			}
		if "`graph'"~="" {
			if "`symbol'"=="" {loc symbol "..................."}
			if "`connect'"=="" {loc connect "llllllllllllllllll"}
			graph `listvar' `pvar' if `touse' , s(`symbol') c(`connect') `options'
			}
		}
	}

end


