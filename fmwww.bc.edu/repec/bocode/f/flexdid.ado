*! version 1.5  18oct2025
** version 1.0  10sep2025

program flexdid
	version 17.0
	Estimate `0'
	Aggregate
end

program Estimate, eclass sortpreserve
	syntax varlist(min=1 fv) [if] [in]		///
		[fweight pweight iweight],			///
		TX(varname numeric)					/// 
		TIme(varname numeric)				///
		GRoup(varname numeric)				///
		[									///
			SPECification(string)			/// 
			TXGRoup(varname numeric)		///
			USERCOhort(varname numeric)			///
			XINTeract(varlist fv)			///
			NOXINTeract						///
			VCE(string)						///
			VERbose							///
		* ]

	// parse Relay options
	_get_diopts diopts, `options'

	// drop permanent variables created and not dropped if the program ends in error
	capture drop _Tx _Grp _Chrt

	if "`specification'" == "" local specification "lagsonly" // specify lagsonly or lagsandleads.
	// If they gave weird strings as the specification
	if "`specification'"!="lagsonly" & "`specification'"!="lagsandleads" {
		display as error `"Value for {bf:specification()} must be "lagsonly" or "lagsandleads"."'
		exit 198
	}

	if "`noxinteract'"=="noxinteract" & "`xinteract'"!="" {
		display as error `"Noxinteract and xinteract cannot be specified together."'
		exit 198
	}

	// Get y and x vars
	gettoken yvar xvars : varlist
		
	// Weights
	if "`weight'" != "" {
			local wgt [`weight' `exp']
			tempvar wt
			quietly generate double `wt' `exp'
	}

	// VCE
	if "`vce'"=="" local vce "cluster `group'"
	if word("`vce'",1) != "cluster" & word("`vce'",1) != "robust" {
		display as error "vce must be either robust or cluster clustvar"
		exit 198
	}
	if word("`vce'",1) == "cluster" local clustvar `=word("`vce'",2)'
		
	// Marksample
	marksample touse
	markout `touse' `clustvar' `wt' `tx' `group' `time', strok

	// check that treatment variable is binary
	quietly summarize `tx' if `touse'
	local min = r(min)
	local max = r(max)
	quietly tabulate `tx' if `touse'
	local nvals = r(r)
	if (`min'!=0 | `max'!=1 | `nvals'!=2) {
		display as text "{p 0 6 0 78}"
		display as error "Invalid treatment variable - {bf:tx()} must be binary with 0 for control observations and 1 for treated observations"
		display as text "{p_end}"
		exit 450
	}

	// Check that time is equally spaced
	preserve
	quietly keep if `touse'
	quietly bysort `time': keep if _n==1
	quietly tsset `time'
	local gaps = r(gaps)
	restore
	if (`gaps'!=0 & "`usercohort'"=="") {
		display as text "{p 0 6 0 78}"
		display as error "Time variable has gaps. Specify {bf:usercohort()} to correctly assign cohorts to groups that were first treated at times coincident with gaps in the data."
		display as text "{p_end}"
		exit 451
	}

	if "`noxinteract'" == "" & "`xinteract'" == "" local xinteract "`xvars'"

	quietly local X "`xinteract' `xvars'"
	quietly local xvars: list uniq X

	// Define treatment groups
	if "`txgroup'" == "" local txgroup `group' // treatment group variable
	quietly egen int _Grp = min(`txgroup'/`tx') if `touse', by(`group')
	quietly replace _Grp = 0 if _Grp==. &  `touse'
	label variable _Grp "flexdid treated groups"
	
	// Define cohorts
	if "`usercohort'"=="" {
		quietly egen int _Chrt = min(`time'/`tx')  if `touse', by(`group')
		quietly replace _Chrt = 0 if _Chrt==. & `touse' 
	}
	else quietly generate _Chrt = `usercohort' if `touse'
	label variable _Chrt "flexdid treated cohorts"

	// Check for always treated units
	quietly sum `time' if `touse', meanonly
	local tmin = r(min)

	quietly sum _Chrt if _Chrt>0 & `touse', meanonly
	local cmin = r(min)
	if (`cmin'<=`tmin') {
		display as text "{p 0 6 0 78}"
		display as error "The first cohort is treated in or before the first time period ({it:`tmin'}) observed in the data. This implies there are always-treated units. Remove always-treated units before using {bf:flexdid}."
		display as text "{p_end}"
		exit 498
	}

	// Check for never treated units
	quietly sum _Chrt if `touse', meanonly
	local cmin = r(min)
	local cmax = r(max)
	if (`cmin'>0) {
		display as text "{p 0 6 0 78}"
		display as text "There are no never-treated units. {bf:flexdid} will define the last cohort as the never-treated group after dropping observations in all time periods in which the last cohort was treated ({it:`cmax'})."
		display as text "{p_end}" _n
		
		tempvar lc
		quietly generate `lc' = (`time'>=`cmax')
		quietly replace `lc' = . if `lc'==1
		markout `touse' `lc'
		quietly replace _Chrt = 0 if _Chrt == `cmax' & `touse'
	}


	// Define pretreatment indicators by cohort (cohort-1 time is base)
	quietly generate byte _Tx = `tx' if `touse'
	quietly levelsof _Chrt if `touse', local(clevels)
	foreach c of local clevels {
		quietly replace _Tx = 1 if _Chrt>0 & _Chrt == `c' & `time'<`=`c'-1' & `touse'
	}
	label variable _Tx "flexdid treatment lags & leads indicator"

	// Define exposure time
	tempvar eventtime ieventtime
	quietly generate int `eventtime' = `time' - _Chrt if _Chrt>0 & `touse'
	quietly replace `eventtime' = -1 if _Chrt==0 & `touse'

	quietly count if _Chrt>0 & `eventtime'>=0 & `touse'
	local cn = r(N)
	quietly count if _Tx==1 & `eventtime'>=0 & `touse'
	local tn = r(N)
	if `cn'!=`tn' {
		display as text "{p 0 6 0 78}"
		display as text "Note: treatment varies at within `group' and `time' Is this expected? Although parameters have been estimated, this is outside the formal scope of the standard model specification. Interpret results appropriately."
		display as text "{p_end}" _n
	}
	
	// Group-qtr treatment coefficients -- lags and leads
	foreach c of local clevels {
		quietly levelsof _Grp if _Chrt==`c' & `c'>0 & `touse', local(glevels)
		foreach g of local glevels {
			quietly levelsof `time' if `touse', local(tlevels)
			foreach t of local tlevels {
				if `t' >= `c' local TxGlags ///
					`"`TxGlags' `c'._Chrt#`g'._Grp#`t'.`time'#1._Tx"'
			}
		}
	}

	foreach c of local clevels {
		quietly levelsof _Grp if _Chrt==`c' & `c'>0 & `touse', local(glevels)
		foreach g of local glevels {
			quietly levelsof `time' if `touse', local(tlevels)
			foreach t of local tlevels {
				if `t' >= `c' local TxGlagsXX ///
					`"`TxGlagsXX' `c'._Chrt#`g'._Grp#`t'.`time'#1._Tx#(c.(`xinteract')) "'
			}
		}
	}
	
	foreach c of local clevels {
		quietly levelsof _Grp if _Chrt==`c' & `c'>0 & `touse', local(glevels)
		foreach g of local glevels {
			quietly levelsof `time' if `touse', local(tlevels)
			foreach t of local tlevels {
				if `t' <=`=`c'-2' local TxGleads ///
					`"`TxGleads' `c'._Chrt#`g'._Grp#`t'.`time'#1._Tx "'
			}
		}
	} 

	foreach c of local clevels {
		quietly levelsof _Grp if _Chrt==`c' & `c'>0 & `touse', local(glevels)
		foreach g of local glevels {
			quietly levelsof `time' if `touse', local(tlevels)
			foreach t of local tlevels {
				if `t' <=`=`c'-2' local TxGleadsXX ///
					`"`TxGleadsXX' `c'._Chrt#`g'._Grp#`t'.`time'#1._Tx#(c.(`xinteract')) "'
			}
		}
	}

	display as text "{p 0 6 0 78}"
	display as text "Note: Variables {bf:_Grp} containing group identifiers, {bf:_Chrt} containing cohort identifiers, and {bf:_Tx} containing lags and leads treatment indicators, were added to the dataset." 
	display as text "{p_end}" _n

	// Lags only specifications
	if "`specification'"=="lagsonly" {
		display as text "Estimating lags only regression parameters"
		if "`verbose'" == "verbose" regress `yvar' `TxGlags' `TxGlagsXX' `xvars' i.`group' i.`time' i.`group'#(c.(`xinteract')) i.`time'#(c.(`xinteract')) `wgt' if `touse', vce(`vce')
		else quietly regress `yvar' `TxGlags' `TxGlagsXX' `xvars' i.`group' i.`time' i.`group'#(c.(`xinteract')) i.`time'#(c.(`xinteract')) `wgt' if `touse', vce(`vce')

	quietly testparm `TxGlags' `TxGlagsXX' `xvars' i.`group' i.`time' i.`group'#(c.(`xinteract')) i.`time'#(c.(`xinteract')) 
	local F = r(F)
	}

	// Lags and leads specifications
	if "`specification'"=="lagsandleads" {
		display as text "Estimating lags and leads regression parameters"
		if "`verbose'" == "verbose" regress `yvar' `TxGlags' `TxGleads' `TxGlagsXX' `TxGleadsXX' `xvars' i.`group' i.`time' i.`group'#(c.(`xinteract')) i.`time'#(c.(`xinteract')) `wgt' if `touse', vce(`vce')
		else quietly regress `yvar' `TxGlags' `TxGleads' `TxGlagsXX' `TxGleadsXX' `xvars' i.`group' i.`time' i.`group'#(c.(`xinteract')) i.`time'#(c.(`xinteract')) `wgt' if `touse', vce(`vce')

	quietly testparm `TxGlags' `TxGleads' `TxGlagsXX' `TxGleadsXX' `xvars' i.`group' i.`time' i.`group'#(c.(`xinteract')) i.`time'#(c.(`xinteract')) 
	local F = r(F)
	}

	ereturn local cmd flexdid
	ereturn local estat_cmd flexdid_estat
	ereturn local group "`group'"
	ereturn local time "`time'"
	ereturn local tx "`tx'"
	ereturn local txgroup "`txgroup'"
	ereturn local usercohort "`usercohort'"
	ereturn local specification "`specification'"

	ereturn scalar F = `F'

end


program Aggregate, rclass sortpreserve

	display as text "Aggregating estimates"

	flexdid_atet, overall

	tempname beta Var nm 

	matrix `beta' = r(b)
	matrix `Var'  = r(V)
	tempname table 
	matrix `table' = r(table)
	return hidden local title "ATET over exposure time"
	return matrix table = `table'
	return matrix b     = `beta'
	return matrix V     = `Var'
	return local atettype "overall"
	return add

end