*! lpdid version 1.1.0  20sep2026

* Authors: Alexander Busch (Massachusetts Institute of Technology, abusch@mit.edu) and Daniele Girardi (King's College London, daniele.girardi@kcl.ac.uk), in collaboration with Arin Dube, Oscar Jordà and Alan M. Taylor. Versions 1.0.0 through 1.0.2 were written by both authors; versions 1.0.3 and 1.1.0 were written by Daniele Girardi.

* Implementing Local Projections Difference-in-Differences (LP-DiD) as described in Dube, Girardi, Jordà, and Taylor (2025) "A Local Projections Approach to Difference-in-Differences", Journal of Applied Econometrics (https://doi.org/10.1002/jae.70000).

* Also see the Stata example files at the following repository
* https://github.com/danielegirardi/lpdid/

* Version 1.1.0 (September 2026):
	* The pooled estimates are no longer reported by default; they now require the new pooled option. They are also implied by only_pooled, pre_pooled() and post_pooled().
	* New options: aggregate_average, pretrend_test, pooled, and untreated_before.
	* Under nonabsorbing(), the command no longer assumes no treatment events before the start of the panel (unless the new option untreated_before is selected) or in periods with missing values.
	* nocomp is now stricter in holding the estimation sample fixed across horizons.
	* Several bug fixes, a number of which concern panels with missing values.
	* Full changelog: https://github.com/danielegirardi/lpdid/blob/main/LPDID_CHANGELOG.md
* Version 1.0.3 (August 2026):
	* Bug fix: In prior versions of the program, the pmd(max) option could incorrectly compute the transformed outcome variable in panels with explicit missing values. This version solves the problem. 
	* Bug fix: In the previous version (1.0.2) of the program, when using pmd() in combination with the oneoff suboption of nonabsorbing(), a slightly too restrictive definition of the clean control sample was imposed, possibly resulting in a loss of statistical power. This version solves the problem.
	* Improved numerical precision of the PMD and pooled outcome transformations, which are now computed in double precision (instead of float).
* Version 1.0.2 (December 2025): 
	* The 'rw' option with covariates or non-absorbing treatment runs much faster relative to previous versions, and is now compatible with the bootstrap() option for wild bootstrap standard errors. This was achieved by (a) extending the set of cases in which a weighted regression is used; (b) using -listreg- to perform regression adjustment when wildcluster bootstrapping is not requested and (c) using -margins- to perform regression adjustment with wildcluster bootstrap. 
	* Introduced the 'oneoff' suboption within the 'nonabsorbing' option, which allows to deal with repeated oneoff treatments (see help file for details). 
	* Bug fix: Prior versions of the program which specified both PMD and NONABSORB had a wrong sample definition which resulted in most observations being dropped. 
	* Bug fix: Prior versions of the program which specified a control variable, rw, and a user-supplied weight produced a syntax error. 
* Version 1.0.1 (July 2024): Added absorb() option for additional absorbed fixed effects. Now allows stata prefixes (including time-series operators) in the arguments of the controls() option. Now allows weights in the standard Stata format [pweight=weight]. 
* Version 1.0.0 (Nov 2023): First release.

********************
*** Main program ***
********************
cap prog drop lpdid 
program define lpdid, eclass

	version 13 // the packages require stata 13 (boottest)

	* CHECK : check dependency 
	foreach package in "boottest" "reghdfe" "listreg"{
		capture quietly which `package'
		if _rc{
			di as error "Please install `package' from the scc as this is required for the lpdid package."
			error 198 
		}
	}

	syntax varlist(max=1) [if] [in] [pweight/], 			/// dependent variable with optional [if] / [in] / [pweight] (the / after aweight ensures that the weightname `exp' is parsed as weight name only instead of "=weight_name")
			time(varname) 								/// time or time-equivalent in DiD
			unit(varname) 								/// DiD unit (also cluster unit for SEs, unless otherwise selected by the user)
			treat(varname) 								/// treatment indicator  
			[controls(string)]							/// control variables, may include Stata notation like "l.varname" or "varname##i.varname2" 
			[PRE_window(numlist min=1 max=1 >1)] 						/// pre-periods of event study 
			[POST_window(numlist min=1 max=1 >=0)] 						/// post-periods 
			[YLags(numlist >=1 int)] 					/// lags of dependent variable on RHS 
			[DYLags(numlist >=1 int)] 					/// lags of first-differenced dependent variable on RHS	
			[NONABSorbing(string)] 						/// non-absorbing treatment; string of the format "[#(integer)] , [notyet] [firsttreat] [oneoff]"; integer # states how many periods after treatment the effect is assumed to stabilise and is necessary; "notyet" suboption sets control group to only not-yet-treated; "firsttreat" suboption sets treatment group to only first time treatment; "oneoff" states that the treatment is of a oneoff nature.
			[NEVERtreated] 								/// only use never treated observations as control units; default is to use all allowed observations
			[NOCOmp] 									/// rule out composition changes in treatment window; default is to use all allowed observations
			[Level(numlist min=1 max=1 >0 <100)] 		/// level for CI; default 95 (corresponds to p < 0.05)	
			[rw] 										/// if used, reweighting or regression adjustment is applied, to estimate an equally weighted ATE
			[pmd(string)] 								/// if used, the pre-mean-differenced (PMD) version of LP-DiD is estimated; the option argument indicates how many periods are used to compose the pre-treatment baseline; default is "max" if absorbing treatment; default is "L" = k if nonabsorbing treatment, unless firsttreat & (notyet | nevertreated) are selected; if instead of "max" an integer k is specified, pmd is interpreted as a moving average over [-k,-1]
			[NOgraph] 									/// no graphical output; default is to produce the graphical output 
			[BOOTstrap(numlist min=1 max=1 >0)] 		/// if used, wild bootstrap with `reps' reps; default not bootstrapped  
			[seed(numlist min=1 max=1)]					/// Set seed (relevant for wild bootstrap SEs); default no seed
			[post_pooled(numlist min=1 max=2 >=0)] 						/// interval to estimate pooled effect; if only one number, it is assumed to be the upper end of the interval; default is [0, post_window]
			[pre_pooled(numlist min=1 max=2 >1)] 						/// interval to estimate pooled pre-treatment "effect"; entered in reverse and without minus sign; for example [3 10] for the interval [-10,-3]; if only one number given it is assumed to be the upper end of the interval; default is [pre_window, -2] (as -1 is reference)
			[pooled] 									/// perform & report pooled LP-DiD estimates
			[only_pooled] 								/// skip event study and only calculate pooled 
			[only_event] 								/// for backward compatibility, although only event is now the default
			[AGGregate_average] 						/// observation-weighted average of the event study coefficients, over the post and pre windows
			[PRETREND_test] 							/// joint test that all pre-period coefficients are zero
			[cluster(varname)]							/// cluster for SEs (default is to use the variable indexing units)
			[absorb(string)] 							/// FE, always includes the time FE 
			[weights(varname)]							/// v100 way of specifying weight, keeping this to allow backward compatibility 			
			[UNTREATED_before]							/// assume no unit was treated before the first period of the panel; default is to require all the relevant treatment values to be observed
			[debug] // debugging device, if turned on, display message at the start of a code section (helps localise errors)

	if "`debug'"!="" di "Syntax"

	***	parse user input and check for illogical input 
	if "`debug'"!="" di "Parse user input"
	preserve 	
	
	* using auxiliary program defined below to parse sub-options of NONABSorbing()
	if "`nonabsorbing'"!=""{
		parse_nonabsorb `nonabsorbing' 
		if "`s(clean)'"!="" local L `s(clean)'
		local notyet `s(notyet)'			
		local firsttreat `s(firsttreat)'
		local oneoff `s(oneoff)'
	}

	* LHS variable, controls, and conditions 
	tempvar touse
	mark `touse' `if' `in'	
	gettoken depvar 0 : varlist // first var as dependent var 
	
	* parse weight option
	if "`weight'"!=""{
		local weight_name "`exp'" // pweight/ ensures that this is parsed as varname instead of "=varname"
		local weight_type "`weight'" // not used in code so far, as we only use aweight to begin with - but may be added at some later time once we allow for other weighting schemes 
	}
	if "`weights'"!=""{ // old v100 way of specifying weights 
		local weight_name "`weights'"
	}
	
	* preserve command as local for ereturn 
	local cmdline "lpdid `depvar'"
	if length("`if'")>0 local cmdline "`cmdline' if `if'"
	if length("`in'")>0 local cmdline "`cmdline' in `in'"
	if length("`weight'")>0 local cmdline "`cmdline' [`weight_type'=`weight_name']"
	local cmdline "`cmdline', unit(`unit') time(`time') treat(`treat')" 
	if "`pre_window'"!="" local cmdline "`cmdline' pre_window(`pre_window')"
	if "`post_window'"!="" local cmdline "`cmdline' post_window(`post_window')"
	if "`ylags'"!="" local cmdline "`cmdline' ylags(`ylags')"
	if "`dylags'"!="" local cmdline "`cmdline' dylags(`dylags')"
	if "`nonabsorbing'"!="" local cmdline "`cmdline' nonabsorbing(`nonabsorbing')"
	if "`nevertreated'"!="" local cmdline "`cmdline' nevertreated"
	if "`nocomp'"!="" local cmdline "`cmdline' nocomp"
	if "`untreated_before'"!="" local cmdline "`cmdline' untreated_before"
	if "`rw'"!="" local cmdline "`cmdline' rw"
	if "`pmd'"!="" local cmdline "`cmdline' pmd(`pmd')"
	if "`bootstrap'"!="" local cmdline "`cmdline' bootstrap(`bootstrap')"
	if "`controls'"!="" local cmdline "`cmdline' controls(`controls')"
	if "`seed'"!="" local cmdline "`cmdline' seed(`seed')"
	if "`post_pooled'"!="" local cmdline "`cmdline' post_pooled(`post_pooled')"
	if "`pre_pooled'"!="" local cmdline "`cmdline' pre_pooled(`pre_pooled')"
	if "`level'"!="" local cmdline "`cmdline' level(`level')"
	if "`nograph'"!="" local cmdline "`cmdline' nograph"
	if "`debug'"!="" local cmdline "`cmdline' debug"
	if "`pooled'"!="" local cmdline "`cmdline' pooled"
	if "`only_pooled'"!="" local cmdline "`cmdline' only_pooled"
	if "`only_event'"!="" local cmdline "`cmdline' only_event"	
	if "`aggregate_average'"!="" local cmdline "`cmdline' aggregate_average"
	if "`pretrend_test'"!="" local cmdline "`cmdline' pretrend_test"
	if "`cluster'"!="" local cmdline "`cmdline' cluster(`cluster')"	
	if "`absorb'"!="" local cmdline "`cmdline' absorb(`absorb')"	
	if "`weights'"!="" local cmdline "`cmdline' weights(`weights')"		
	di "`cmdline'"

	* set pre / post window to lowest value if not selected
	if "`pre_window'"=="" & "`post_window'"=="" & !("`only_pooled'"!="" & ("`pre_pooled'"!="" | "`post_pooled'"!="")) { // allow to set neither pre_window nor post_window if only_pooled and one pooled is set
		di as error "Please specify either post_window, pre_window, or both."
		error 198	
	}
	if "`pre_window'"==""{
		local pre_window = 2
		local no_pre "no_pre"
	}
	if "`post_window'"==""{
		local post_window = 0
		local no_post "no_post"
	}

	* CHECK: aggregate_average and pretrend_test need event study horizons
	if "`aggregate_average'"!="" & "`no_post'"!="" {
		di as error "aggregate_average: no post window was specified, so there are no event study horizons to average. Please specify post_window()."
		error 198
	}
	if "`pretrend_test'"!="" & "`no_pre'"!="" {
		di as error "pretrend_test: no pre window was specified, so there are no pre-period coefficients to test. Please specify pre_window()."
		error 198
	}

	* parse interval of pooled specification, default value is the event window
	local post_pooled_start = 0 
	local post_pooled_end "`post_window'"	
	local pre_pooled_start = 2
	local pre_pooled_end "`pre_window'"
	foreach horizon in pre post{ 
		if "``horizon'_pooled'"!="" {
			cap local test = 1 + ``horizon'_pooled' // test format, error if not 1 number (cannot set restriction to integer in the option because in future versions we plan to allow the "max" string) 
			if _rc{ // two integers
				tokenize ``horizon'_pooled'
				local `horizon'_pooled_start `1'
				local `horizon'_pooled_end `2' 
				* CHECK : pooled window 
				if "`3'"!=""{
					di as error "Wrong pooled event window: Your event window can only contain one or two elements. Remember that a pre window of the format [-10,-3] must be entered as [3 10]."
					error 198 
				}
				if ``horizon'_pooled_start' > ``horizon'_pooled_end' {
					di as error "Wrong pooled event window: the first element cannot exceed the second. Remember that a pre window of the format [-10,-3] must be entered as [3 10]."
					error 198 
				}
			}
			else{ // only one integer 
				tokenize ``horizon'_pooled'
				local `horizon'_pooled_end `1'
			}
		}
	}	

	* Determine the number of clean control indicators CCS_(m)h to be created. 
	foreach horizon in pre post{
		local `horizon'_CCS = max(``horizon'_pooled_end', ``horizon'_window')
	}
	if "`debug'"!="" di "Setting pre_CCS = `pre_CCS' and post_CCS=`post_CCS' "
	* build rhs of regression 
	local rhs ""
	if "`dylags'"!=""{
		forvalues i = 1/`dylags'{
			local rhs `rhs' L`i'.D.`depvar'
		}
	}		
	if "`ylags'"!=""{
		forvalues i = 1/`ylags'{
			local rhs `rhs' L`i'.`depvar'
		}
	}
	local rhs `rhs' `controls' // all rhs variables for regression (incl. operators)
	
	* Add additional fixed effects to absorb
	local fixed_effects `time'
	if "`absorb'"!=""{
		foreach fe in `absorb'{
			if "`fe'"!="`time'" local fixed_effects `fixed_effects' `fe' // skips time FE 
		}
	} 
	
	
	
	*** Test user input 
	if "`debug'"!="" di "Test user input"	
	
	* CHECK : binary treatment 
	capture assert missing(`treat') | inlist(`treat', 0, 1)
	if (_rc != 0) {
		di as error "It looks like your treatment variable is non-binary. This program only covers the case of a binary (absorbing or nonabsorbing) treatment. We suggest that you write your LP-DiD specification manually instead of using this program."
		error 198
	}
	* CHECK : pooled window 
	foreach horizon in pre post{
		foreach aggr in pooled_end window{
			if int(``horizon'_`aggr'')!=``horizon'_`aggr''{
				di as error "`horizon'_`aggr' wrong format: Specify an integer. "
				error 198
			}			
		}
	}	
	* pmd(max) assumes that there is no previous treatment, which is only generally true for the absorbing case or the nonabsorbing case with firsttreat & (notyet | nevertreated)
		* > if this is violated, set pmd to MA with k = L as default 
	if "`nonabsorbing'"!="" & "`pmd'"=="max" & !("`firsttreat'"!="" & ("`notyet'"!="" | "`nevertreated'"!="")){	
		local pmd = `L'
		di "pmd: You specified max, which is not correct in the nonabsorbing case with a time-window for clean controls. Instead, pmd is now specified as moving average over [-L= -`pmd',-1]. You can choose a different MA if you specify pmd(k) instead of pmd(max). "
	}	
	* CHECK : nonabsorbing L 	
	if "`nonabsorbing'"!="" & "`L'"=="" & !("`firsttreat'"!="" & ("`notyet'"!="" | "`nevertreated'"!="")){
		if "`L'"==""{
			di as error "Wrong input: With non-absorbing treatment, you need to specify an integer # in nonabsorbing(#, [subopts]), which indicates after how many periods treatment effects are assumed to stabilise. Only if you specify the firsttreat option and either notyet or nevertreated you can omit the integer #."
			error 198 
		}
		* CHECK : nonabsorbing integer
		if "`nonabsorbing'"!=""{
			if int(`L')!=`L'{ // integer test 
				di as error "nonabsorbing wrong input: L has to be an integer."
				error 198
			}		
		}
	}	
	* CHECK : nevertreated notyet 
	if "`nevertreated'"!="" & "`notyet'"!=""{
		di as error "nevertreated and notyet cannot be specified at the same time."
		error 198
	}	
	* CHECK : pmd 
	if "`pmd'"!="" & "`pmd'"!="max"{		
		cap confirm integer number `pmd'
		if _rc{ // integer test 
			di as error "pmd wrong input: pmd has to be an integer or max."
			error 198 
		}
	}	
	* Determine whether regression adjustment estimator must be used 
	if "`rw'"!="" & ("`controls'"!="" | "`ylags'"!="" | "`dylags'"!="" | "`fixed_effects'"!="`time'"){ 
		local rw_ra "true" // regression adjustment necessary 
		local rhs_fe "" // will collect FE vars
		local rhs_orig "`rhs'" // stores rhs as written, for use with margins
		fvrevar `rhs', tsonly stub(op_var) substitute // if RA must be used, then time-series and factor variables should substituted with newly created variables
		local rhs `r(varlist)' 
		
		foreach fe in `fixed_effects' { // if RA must be used, properly add additional FEs to the right-hand side
			capture confirm numeric variable `fe'
			if !_rc {
				local rhs `rhs' i.`fe'
				local rhs_fe `rhs_fe' i.`fe'
			}
			else {
				if !inlist(substr("`fe'", 1, 2),"i.","c.") {
					encode `fe', gen(`fe'num)
					local rhs `rhs' i.`fe'num
					local rhs_fe `rhs_fe' i.`fe'num
					}
				if inlist(substr("`fe'", 1, 2),"i.") {
					di as error "Variables in absorb(variables) should not use factor variable notation. Just include the name of the variable. The program will add the factor operator as needed."
					error 198
				}
				if inlist(substr("`fe'", 1, 2),"c.") {
					di as error "The c. operator is not allowed in the absorb() option."
					error 198
				}
			}
		}
		
		if "`debug'"!="" di "RHS for Regression Adjustment is `rhs'"
		
		if "`bootstrap'"!="" { // if margins must be used, also add the c. operator to any continuous variable
			* rhs_margins built from rhs_orig & rhs_fe, so factor notation survives
			local rhs_margins ""
			foreach var of local rhs_orig {
				local d = strpos("`var'", ".")
				local op = ""
				if `d'>0 local op = substr("`var'", 1, `d'-1)
				* factor notation needs no substitution, whatever operator it carries
				if lower(substr("`op'",1,1))=="i" | lower("`op'")=="c" | real("`op'")<. {
					local rhs_margins "`rhs_margins' `var'"
				}
				else {
					fvrevar `var', tsonly
					local rhs_margins "`rhs_margins' c.`r(varlist)'"
				}
			}
			local rhs_margins "`rhs_margins' `rhs_fe'"
			
			if "`debug'"!="" di "Given wild bootstrapping, RHS for Regression Adjustment is now `rhs_margins' for compatibility with margins"
		}
	}
	* CHECK: inconsistency in asking only event study but also specifying pooled horizon; continue execution, assuming no pooled estimates
	if ("`pre_pooled'"!=""|"`post_pooled'"!="") & "`only_event'"!="" {
		di as error "only_event: it looks like you have requested only event study estimates but also specified a time horizon for pooled events. The program will now run without pooled estimates. "
	}
	* CHECK : only_pooled only_event 
	if "`only_pooled'"!="" & "`only_event'"!=""{
		di as error "only_event and only_pooled both specified - please select only one of these options."
		error 198 
	}
	* CHECK: weights & weight
	if "`weights'"!="" & "`weight'"!=""{
		di as error "weights() and [pw=] specified at the same time: you can use either option to include weights, but please only use one at a time. Both options are identical in their effect and we keep the old weights() option for backwards compatibility. "
		error 198 		
	}
	* CHECK: absorb() and bootstrap 
	if "`absorb'"!="" {
		if "`absorb'"!="`time'" & "`bootstrap'"!=""{ // this does not get triggers if user specifies ONLY time fe
			di as error "absorb() and bootstrap() specified at the same time: Since the user written command boottest only allows one absorbed effect and the time fixed effects is already absorbed per default, you cannot use these two options at the same time. Please specify your additional fixed effects as control variables with the 'i.' prefix in the controls() option if you require bootstrapping. The results will be identical to using absorb(), but may take longer. "
			error 198 			
		}
		foreach fe in `absorb'{ // this gets triggers if ANY fe in absorb is the time fe (it does not get triggered if the time variable name is simply a part of another varname, e.g. time(time) and absorb(time2 L5.time) does not raise the error)
			if "`fe'"=="`time'" { 
				di as error "absorb() includes the time (or time-equivalent) variable `time'; please note that lpdid always absorbs time fixed effects (otherwise it would not be a DiD!). Including time effects in the absorb() option is not necessary and does not improve runtime. "
			}
		}
	}
	* Message about oneoff
	if "`oneoff'"!="" {
		dis "You indicated that treatment is non-absorbing and one-off: this means that a treatment lasts only for 1 period by construction, although its effects can still be dynamic and persistent. We have `treat'(i,t)=1 if unit i experiences a treatment event at time t, and `treat'(i,t)=0 in all other periods. If this is not the case, do not select the oneoff suboption."
	}

	
	* CHECK : names 
	* no input variable should be identical in name to a program variable 
	local input_vars `depvar' `time' `unit' `treat' `controls' `cluster' `weight_name' `absorb'
	
	if "`debug'"!="" di "input vars: `input_vars'"
	
	fvrevar `input_vars', list // get rid of stata operators while also avoiding duplicates in the list
	local input_vars ""
	foreach word in `r(varlist)' {
	if regexm("`input_vars'", "\b`word'\b") == 0 {
			local input_vars "`input_vars' `word'"
		}
	}
		
	local program_vars cumulative_y obs_n aveLY max_treat never_treated past_events status_entry_help status_entry reweight CCS_nocomp_event CCS_nocomp_pooled aveFY pooled_y reweight_pooled dtreat_rw
	if "`rw'"!="" & "`rw_ra'"!="" { // if RA will be used, add the variables that will be created for RA to the list of program variables
		local program_vars `program_vars' dtreat
		foreach fe in `absorb' {
			capture confirm numeric variable `fe' 
			if _rc & !inlist(substr("`fe'", 1, 2),"i.","c.") local program_vars `program_vars' `fe'num
		}
	}
	local program_vars_dynamic1 CCS_ CCS_m nyt_
	local program_vars_dynamic2 D Dm
	quietly su `time' , meanonly
	local maxtime = `r(max)'
	forvalues h=0/`maxtime'{ // dynamically created vars filled with max possible value 
		foreach var in `program_vars_dynamic1'{
			local program_vars `program_vars' `var'`h'
		}
		foreach var in `program_vars_dynamic2'{
			local program_vars `program_vars' `var'`h'y
		} 
	}
	if "`debug'"!="" display as text "The expected program variables are: `program_vars'"
	* double check whether any input is identical to a program variable 
	foreach input_var in `input_vars'{
		foreach program_var in `program_vars'{
			if "`input_var'"=="`program_var'"{
				di as error "One of your input variables has the same name as a variable dynamically created by the program; please rename this variable: `input_var'."
				error 198	
			}
		}
	}	
	
	* only keep variables which are required 
	fvrevar `rhs', list
	quietly keep `input_vars' `r(varlist)' `touse'
				
	* set time / unit structure  
	quietly xtset `unit' `time'	

	local raoknsets = 0
	if "`rw_ra'"!="" {
		* The cells RA conditions on, for use in raok
		* a term without an interaction is expanded, so a numlist operator yields one cell per variable
		local raokterms ""
		foreach term of local rhs_orig {
			local raokterm "`term'"
			if strpos(`"`term'"', "#")==0 {
				local rtd = strpos(`"`term'"', ".")
				local rtop ""
				if `rtd'>0 local rtop = substr(`"`term'"', 1, `rtd'-1)
				if lower(substr("`rtop'",1,1))!="i" {
					cap fvrevar `term', tsonly stub(op_var) substitute
					if _rc==0 {
						local rtv "`r(varlist)'"
						if "`rtv'"!="" local raokterm "`rtv'"
					}
				}
			}
			local raokterms `"`raokterms' `raokterm'"'
		}
		foreach term of local raokterms {
			local fset ""
			local t "`term'"
			while `"`t'"'!="" {
				gettoken piece t : t, parse("#")
				if `"`piece'"'!="#" {
					local d = strpos(`"`piece'"', ".")
					local vn = `"`piece'"'
					local op ""
					if `d'>0 {
						local op = substr(`"`piece'"', 1, `d'-1)
						local vn = substr(`"`piece'"', `d'+1, .)
					}
					if lower(substr("`op'",1,1))=="i" local fset `"`fset' `vn'"'
					else {
						* a binary control is the same model written as c., as i., or under a time-series operator
						cap fvrevar `piece', tsonly stub(op_var) substitute
						if _rc==0 {
							local gv "`r(varlist)'"
							cap confirm numeric variable `gv'
							if _rc==0 & wordcount("`gv'")==1 {
								qui summarize `gv' if `touse'
								local vmn = r(min)
								local vmx = r(max)
								if `vmn'<`vmx' {
									qui count if `touse' & !missing(`gv') & `gv'!=`vmn' & `gv'!=`vmx'
									if r(N)==0 local fset `"`fset' `gv'"'
								}
							}
						}
					}
				}
			}
			local fset : list uniq fset
			local fset : list sort fset
			if "`fset'"!="" {
				local dup = 0
				forvalues q = 1/`raoknsets' {
					if "`raokset`q''"=="`fset'" local dup = 1
				}
				if !`dup' {
					local raoknsets = `raoknsets' + 1
					local raokset`raoknsets' "`fset'"
				}
			}
		}
		forvalues i = 1/`raoknsets' {
			local raokdrop`i' = 0
			forvalues j = 1/`raoknsets' {
				if `i'!=`j' {
					local raokSi "`raokset`i''"
					local raokSj "`raokset`j''"
					local raoksub : list raokSi in raokSj
					if `raoksub' local raokdrop`i' = 1
				}
			}
		}
		local raokkeep = 0
		forvalues i = 1/`raoknsets' {
			if !`raokdrop`i'' {
				local raokkeep = `raokkeep' + 1
				local raoknew`raokkeep' "`raokset`i''"
			}
		}
		forvalues i = 1/`raokkeep' {
			local raokset`i' "`raoknew`i''"
		}
		local raoknsets = `raokkeep'
		if "`debug'"!="" {
			di "raok guards on `raoknsets' factor cell(s) beyond fixed_effects"
			forvalues q = 1/`raoknsets' {
				di "  by(`raokset`q'')"
			}
		}
	}

	local ylagctl = ("`ylags'"!="" | "`dylags'"!="") // whether Y, in any transformed form, is in X
	local ylagsrc = cond("`ylags'"!="", "ylags(`ylags')", "") // records how specifically Y enters X
	if "`dylags'"!="" local ylagsrc = trim("`ylagsrc' dylags(`dylags')")
	if !`ylagctl' & "`controls'"!="" {
		cap fvrevar `controls', list
		if _rc==0 {
			local basevars "`r(varlist)'"
			foreach v of local basevars {
				if "`v'"=="`depvar'" {
					local ylagctl = 1
					local ylagsrc "controls()"
				}
			}
		}
	}
	local neuttol = 1e-8

	* Whether the panel has gaps (to be used later)
	tempvar tgap
	quietly by `unit': gen double `tgap' = `time' - `time'[_n-1]
	quietly count if inrange(`tgap',2,.)
	local hasgaps = (r(N) > 0)

	* First period each unit is observed.
	tempvar tmin
	quietly egen `tmin' = min(`time') , by(`unit')

	* Create local indicating whether untreated_before is selected
	if "`untreated_before'"!="" local ub 1
	else                        local ub 0
		
	* Set seed if indicated by the user (relevant for boottest)
	if "`seed'"!="" set seed `seed' 

	* check the panel's completeness and issue appropriate warnings
	quietly summarize `tmin' , meanonly
	local ragged = (r(min) != r(max))
	quietly count if missing(`depvar') & `touse'
	local missy = (r(N) > 0)
	quietly count if missing(`treat') & `touse'
	local misstreat = (r(N) > 0)

	if "`pmd'"=="max" & (`ragged' | `hasgaps' | `missy') {
		di "Warning: You selected the PMD(max) specification but your data is not strongly balanced or has missing values for the outcome variable. Please evaluate whether this is a problem in your application or not. Note that with unbalanced data or missing outcome values, your PMD window length might possibly differ between observations within the same event. This can introduce bias or noise."
	}
	else if `ragged' | `hasgaps' {
		di "FYI: Your data is not strongly balanced. Please evaluate whether this is a problem in your application or not."
	}

	local classopts ""
	if "`nevertreated'"!="" local classopts "`classopts' nevertreated"
	if "`notyet'"!=""       local classopts "`classopts' notyet"
	if "`firsttreat'"!=""   local classopts "`classopts' firsttreat"
	if "`classopts'"!="" & (`misstreat' | `hasgaps') {
		di "You have selected:`classopts'. Note that `treat' is not fully observed in your panel (missing values or panel gaps), therefore units might have been classified using an incomplete treatment record. See the help file for more details."
	}
	
	* significance level for confidence intervals 
	local p = 0.05
	if "`level'"!="" local p = (100 - `level')/100
	if "`level'"=="" local level 95
	local p2 = `p'/2

	* If treatment is one-off and 'pseudo-absorbing', modify the treatment indicator to equal 1 in all post-treatment periods
	if "`oneoff'"!="" & ("`firsttreat'"!="" & ("`notyet'"!="" | "`nevertreated'"!="")) {
		by `unit': replace `treat' = 1 if sum(`treat') > 0
	}
	
	*** Identify clean control samples and create indicators
	if "`debug'"!="" di "Identify clean control samples"
	
	* Absorbing (or "pseudo-absorbing") treatment
	if "`nonabsorbing'"=="" | ("`firsttreat'"!="" & ("`notyet'"!="" | "`nevertreated'"!="")) {
		forvalues h = 0/`post_CCS' {
			quietly gen CCS_`h' = 0
			quietly replace CCS_`h' = 1 if (D.`treat'==1 | F`h'.`treat'==0)
		}
		forvalues h = 1/`pre_CCS' {
			quietly gen CCS_m`h' = CCS_0
		}
	}
	
	* Non-absorbing treatment (if not one-off and not "pseudo-absorbing")
	if "`nonabsorbing'"!="" & "`oneoff'"=="" & !("`firsttreat'"!="" & ("`notyet'"!="" | "`nevertreated'"!="")){ // check whether the unit is contaminated by previous/future switches
		quietly gen CCS_0 = 0
		local string "(D.`treat'==1 | D.`treat'==0) & (abs(L.D.`treat')==0 | (`ub' & `time'-2 < `tmin' & (`time'-1 < `tmin' | L.`treat'==0)))"
		forvalues k=2/`L'{ 
			local string = "`string' & (abs(L`k'.D.`treat')==0 | (`ub' & `time'-`k'-1 < `tmin' & (`time'-`k' < `tmin' | L`k'.`treat'==0)))"
		}
		quietly replace CCS_0 = 1 if `string'		
		forvalues h = 1/`post_CCS'{ // clean window at least up until period t+h 
			quietly gen CCS_`h' = 0
			local i = `h' - 1		
			quietly replace CCS_`h' = 1 if CCS_`i'==1 & abs(F`h'.D.`treat')==0
		}
		quietly gen CCS_m1 = CCS_0 		// generate backward-looking clean control condition for testing for pre-trends
		forvalues h = 2/`pre_CCS' {
			quietly gen CCS_m`h' = 0
			local i = `h'-1 
			quietly replace CCS_m`h' = 1 if CCS_m`i'==1 & L.CCS_m`i'==1
		}
	} 
	
	* Non-absorbing one-off treatment  (if not "pseudo-absorbing")
	if "`nonabsorbing'"!="" & "`oneoff'"!="" & !("`firsttreat'"!="" & ("`notyet'"!="" | "`nevertreated'"!="")){ // check whether the unit is contaminated by previous/future treatments
		quietly gen CCS_0 = 0
		local string "( (`treat'==1 & D.`treat'==1) | (`treat'==0 & D.`treat'==0)) & (L.`treat'==0 | (`ub' & `time'-1 < `tmin'))"
		forvalues k=2/`L'{ 
			local string = "`string' & (L`k'.`treat'==0 | (`ub' & `time'-`k' < `tmin'))"
		}
		quietly replace CCS_0 = 1 if `string'		
		forvalues h = 1/`post_CCS'{ // clean window at least up until period t+h 
			quietly gen CCS_`h' = 0
			local i = `h' - 1		
			quietly replace CCS_`h' = 1 if CCS_`i'==1 & abs(F`h'.`treat')==0
		}
		quietly gen CCS_m1 = CCS_0 		// generate backward-looking clean control condition for testing for pre-trends
		forvalues h = 2/`pre_CCS' {
			quietly gen CCS_m`h' = 0
			local i = `h'-1 
			quietly replace CCS_m`h' = 1 if CCS_m`i'==1 & L.CCS_m`i'==1
		}
	} 	
	
	* Only never treated in control group 
	if "`nevertreated'"!=""{ 
		quietly by `unit': egen max_treat = max(`treat') 
		quietly gen never_treated = 0
		quietly replace never_treated = 1 if max_treat==0
		forvalues h = 0/`post_CCS' {
			quietly replace CCS_`h'=0 if (D.`treat'==0 & never_treated==0)
		}
		forvalues h = 2/`pre_CCS' {
			quietly replace CCS_m`h'=0 if (D.`treat'==0 & never_treated==0)
		}
		drop max_treat
	}
	
	* Nonabsorbing treatment but only not-yet treated in the control group 
	if "`notyet'"!="" {
		quietly by `unit': gen past_events = sum(abs(D.`treat'))
		quietly by `unit': egen first_obs = min(`time') 
		quietly gen status_entry_help = `treat' if `time' == first_obs
		quietly by `unit': egen status_entry = max(status_entry_help)
		drop first_obs status_entry_help
		forval h = 0/`post_CCS' {
			quietly gen nyt_`h' = 0
			quietly replace nyt_`h' = 1 if F`h'.past_events==0 & status_entry==0
		}
		forvalues h = 0/`post_CCS' {
			quietly replace CCS_`h'=0 if (D.`treat'==0 & nyt_`h'==0)
		}
		forvalues h = 2/`pre_CCS' {
			quietly replace CCS_m`h'=0 if (D.`treat'==0 & nyt_0==0)
		}		
	} 
	
	* Nonabsorbing treatment, if user wants to estimate effect of entering treatment for the first time (ie, only consider first treatment event for each treated unit) and staying treated
	if "`firsttreat'"!=""{
		cap drop past_events
		* past_events counts previous treatment episodes, and observations with
		* more than one are dropped below. Which counter is correct depends on
		* whether the treatment indicator is persistent, one-off, or has been
		* made (pseudo-)absorbing: with persistent treatment, or with one-off
		* treatment that is pseudo-absorbing, we count changes in treatment
		* status; with one-off treatment that is not pseudo-absorbing, we count
		* treatment events.
		if "`oneoff'"!="" & "`notyet'"=="" & "`nevertreated'"=="" {
			quietly by `unit': gen past_events = sum(`treat')
		}
		else {
			quietly by `unit': gen past_events = sum(abs(D.`treat'))
		}
		forval h = 0/`post_CCS' {
			quietly replace CCS_`h' = 0 if F`h'.past_events>1 
		}
		forval h = 1/`pre_CCS' {
			quietly replace CCS_m`h' = 0 if past_events>1 
		}
	}	
	

	
	*** avoid composition effects 
	if "`nocomp'"!=""{ 
		foreach aggr in event pooled{
			if "`aggr'"=="event" local post = `post_window'
			if "`aggr'"=="event" local pre = `pre_window'
			if "`aggr'"=="pooled" local post = `post_pooled_end'
			if "`aggr'"=="pooled" local pre = `pre_pooled_end'
			
			local nocomp_rest "CCS_0==1"
			forval h = 1/`post' {
				local nocomp_rest "`nocomp_rest' & CCS_`h'==1"
			}
			forval h = 2/`pre' {
				local nocomp_rest "`nocomp_rest' & CCS_m`h'==1"
			}
			quietly gen CCS_nocomp_`aggr' = 0
			quietly replace CCS_nocomp_`aggr' = 1 if `nocomp_rest'
		}
	}	


	
	*** Generate long differences to be used on the LHS of the LP-DiD regressions
	if "`debug'"!="" di "Generate long differences"
	
	if "`pmd'"=="" { // if PMD not selected, classical LP long difference  
		forval h = 0/`post_window' { 
			quietly gen double D`h'y = F`h'.`depvar' - L.`depvar'
		}
		forval h = 2/`pre_window' {
			quietly gen double Dm`h'y = L`h'.`depvar' - L.`depvar'
		}		
	}
	else if "`pmd'"=="max" { // if PMD selected with the max option, do PMD with all available pre-treatment observations
		quietly bysort `unit' (`time') : gen double cumulative_y = sum(`depvar')
		quietly bysort `unit' (`time') : gen obs_n = sum(!missing(`depvar'))
		quietly gen double aveLY = L.cumulative_y/L.obs_n
		forval h = 0/`post_window' {
			quietly gen double D`h'y = F`h'.`depvar' - aveLY
		}
		forval h = 2/`pre_window' {
			quietly gen double Dm`h'y = L`h'.`depvar' - aveLY
		}		
		quietly drop obs_n		
	}
	else if "`pmd'"!="max" & "`pmd'"!=""{ // moving average of periods [-k,-1] 		
		* mean of the pmd lags. All of them are required: pmd(n) asks for an
		* average over n periods, so n must be available.
		local sumx "0"
		forvalues j = 1/`pmd' {
			local sumx "`sumx' + L`j'.`depvar'"
		}
		qui gen double aveLY = (`sumx')/`pmd'
		if "`nonabsorbing'"!=""{ // set to missing if any of the MA values affected by previous treatment 
			local pmd_L = `pmd' + `L' - 1
			forvalues k=1/`pmd_L'{
				if "`oneoff'" != "" {
					// For one-off, check if the LEVEL of the treatment is non-zero
					quietly by `unit': replace aveLY = . if !(L`k'.`treat'==0 | (`ub' & `time'-`k' < `tmin'))
				}
				else {
					// For persistent, check if the DIFFERENCE of the treatment is non-zero
					quietly by `unit': replace aveLY = . if !(abs(L`k'.D.`treat')==0 | (`ub' & `time'-`k'-1 < `tmin' & (`time'-`k' < `tmin' | L`k'.`treat'==0)))
				}
			}
		}
		forval h = 0/`post_window' {
			quietly gen double D`h'y = F`h'.`depvar' - aveLY
		}
		forval h = 2/`pre_window' {
			quietly gen double Dm`h'y = L`h'.`depvar' - aveLY
		}		
	}
	
	*** nocomp: also require the outcome at every horizon, so that every horizon
	*** is estimated on the same rows. Here rather than with the rest of the
	*** condition above, because it uses the long differences.
	if "`nocomp'"!="" {
		forval h = 0/`post_window' {
			quietly replace CCS_nocomp_event = 0 if missing(D`h'y)
		}
		forval h = 2/`pre_window' {
			quietly replace CCS_nocomp_event = 0 if missing(Dm`h'y)
		}
	}


	*** Compute and store weights if appropriate
	if "`debug'"!="" di "Compute and store weights"
	
	local post_leads = `post_window'
	local pre_lags  = `pre_window'
	* capture alone would suppress the debug report inside _lpdid_rw
	local rwcap "cap"
	if "`debug'"!="" local rwcap "cap noisily"
    if "`rw'"!="" & "`rw_ra'"=="" { // if rw selected and RA not necessary to do reweighting, compute weights (to be then used in weighted regression)
		quietly gen byte dtreat_rw = (D.`treat'==1)

		* each factor is built on the rows its own regression uses. Where it
		* cannot be built, the regression below fails and is reported.
		if "`nocomp'"=="" {	// if we aren't ruling out composition effects, weights might be different across time horizons
			forval h = 0/`post_leads' {
				`rwcap' _lpdid_rw , dtr(dtreat_rw) time(`time') touse(`touse') ///
					ccs(CCS_`h') outcome(D`h'y) generate(reweight_`h') ///
					wname(`weight_name') cluster(`cluster') `debug'
			}
			forval h = 2/`pre_lags' {
				* one factor per pre horizon: the pre horizons differ in which
				* outcomes they observe
				`rwcap' _lpdid_rw , dtr(dtreat_rw) time(`time') touse(`touse') ///
					ccs(CCS_m`h') outcome(Dm`h'y) generate(reweight_m`h') ///
					wname(`weight_name') cluster(`cluster') `debug'
			}
		}
		else if "`nocomp'"!="" { // if ruling out composition effects, weights are the same across all time horizons
			`rwcap' _lpdid_rw , dtr(dtreat_rw) time(`time') touse(`touse') ///
				ccs(CCS_nocomp_event) outcome(D0y) generate(reweight) ///
				wname(`weight_name') cluster(`cluster') `debug'
		}
	}
	else if "`rw'"=="" { // no weights, just assign an equal weight to each observation	
		if "`nocomp'"!="" {
			qui gen double reweight = 1
			if "`weight_name'"!="" quietly replace reweight = `weight_name'
		}
		else if "`nocomp'"=="" {
			forvalues j=0/`post_leads'{
				quietly gen double reweight_`j' = 1
				if "`weight_name'"!="" quietly replace reweight_`j' = `weight_name'
			}
			forvalues j=0/`pre_lags'{
				quietly gen double reweight_m`j' = 1
				if "`weight_name'"!="" quietly replace reweight_m`j' = `weight_name'
			}
		}
	}
	else if "`rw'"!="" & "`rw_ra'"!=""{ 		// variables for regression adjustment 
		quietly gen dtreat=D.`treat'
		quietly replace dtreat=. if dtreat==-1  // only matters with nonabsorbing treatment 
		if "`weight_name'"!="" local ra_reweight "[pweight=`weight_name']"
		if "`bootstrap'"=="" {
			* scale reference for judging a degenerate listreg estimate
			qui summarize `depvar' if `touse'
			local yscale = r(sd)
			* hold each regression-adjustment estimate and its variance
			tempname rab raV prtab
			tempvar rasamp // marks the rows listreg actually used
		}
	}

	
	
	*** Estimate LP-DiD regressions
	if "`debug'"!="" di "Estimate LP-DiD regressions"

	* tally of regressions that could and could not be run
	local nfit = 0
	local nofit ""
	local nodegen ""	// rows whose regression had rows but no variation to fit
	local noid ""		// horizons whose coefficient is not identified
	local neutlist ""	// horizons that are zero by construction
	local pneutlist ""	// pooled rows that are zero by construction

	if "`cluster'"=="" local cluster `unit'
	

	** Event study regressions
	if "`debug'"!="" di "Event study regressions"	

	* the event study horizons are also needed when only their aggregates are reported
	local run_es = ("`only_pooled'"=="" | "`aggregate_average'"!="" | "`pretrend_test'"!="")
	* the pooled estimates are reported only on request; naming a pooled window,
	* or asking for pooled only, counts as a request
	local want_pooled = ("`only_event'"=="" & ("`pooled'"!="" | "`only_pooled'"!="" | ///
		"`pre_pooled'"!="" | "`post_pooled'"!=""))
	* the influence functions are built only when something consumes them
	local want_if = ("`aggregate_average'"!="" | "`pretrend_test'"!="")
	local want_agg = ("`aggregate_average'"!="")
	* label for the aggregate average (either VWATT or ATT)
	local agglab = cond("`rw'"!="", "ATT", "VWATT")
	* regression adjustment without bootstrap() refers its p-value and interval
	* to the normal, so its statistic is a z; every other route reports t
	local statlab = cond("`rw_ra'"!="" & "`bootstrap'"=="", "z", "t")
	local want_pt = ("`pretrend_test'"!="")
	local ptdone = 0
	local ptP = 0
	* boottest enumerates the Rademacher universe when it is smaller than the
	* requested replications; r(reps) reports what it actually did
	local bsdraws ""
	local bsncall = 0
	local bsnwarn = 0
	local bsrepmin = .
	local bsrepmax = .
	tempname btci
	* debug check: IF-based SE vs regdhfe's own SE
	local want_ifchk = (`want_if' & "`debug'"!="")
	if `run_es' {
		* create matrix to store results 
		local horizons "" // local which determines horizons for LP-DiD Regressions 
		local rows "pre1" // row names
		local rows_n = 0 // number of rows 
		foreach horizon in pre post {
			if "`no_`horizon''"!=""{
				local `horizon'_window = 0 // set to 0 for max_window local 
			}
			else{
				local horizons `horizons' `horizon'
				if "`horizon'"=="pre"{
					forval h= 2/`pre_window' {
						local rows "pre`h'" "`rows'"  
					} 	
					local rows_n = `pre_window'
				} 
				if "`horizon'"=="post"{
					forval h= 0/`post_window' {
						local rows "`rows'" "tau`h'" 
					} 	
					local rows_n = `rows_n' + `post_window' + 1 // +1 accounts for 0
					if "`no_pre'"!="" local rows_n = `rows_n' + 1 // add row for reference period -1 if only post_window specified 
				} 
			}
		}
		matrix J=J(`rows_n',7,.)		
		if `want_ifchk' matrix IFCHK = J(`rows_n',2,.)
		matrix colnames J = "Coefficient" "SE" "`statlab'" "P>|`statlab'|" "[`level'% conf." "interval]" "obs"
		matrix rownames J = "`rows'"
		
		if "`no_pre'"!="" local pre_window = 1 // set to 1 to allow empty reference period = -1 in matrix 
				
		* Under nocomp the clean-control check below returns the same answer at
		* every horizon, so it is built once here. The outcome term of the
		* condition is omitted because CCS_nocomp_event is already 0 wherever any
		* horizon's outcome is missing.
		tempvar isctl raok hasctl
		if "`rw_ra'"!="" & "`nocomp'"!="" {
			qui gen byte `isctl' = (CCS_nocomp_event==1 & `touse' & dtreat==0)
			fvrevar `rhs', list
			qui markout `isctl' `r(varlist)' `weight_name' `cluster', strok
			qui gen byte `raok'  = 1
			foreach fe in `fixed_effects' {
				cap drop `hasctl'
				qui egen byte `hasctl' = max(`isctl'), by(`fe')
				qui replace `raok' = 0 if `hasctl'!=1
			}
			forvalues q = 1/`raoknsets' {
				cap drop `hasctl'
				qui egen byte `hasctl' = max(`isctl'), by(`raokset`q'')
				qui replace `raok' = 0 if `hasctl'!=1
			}
			cap drop `isctl' `hasctl'
		}

		* pieces from which each event study coefficient's influence function is built
		if `want_if' tempvar ifeh ifdt ifnum ifden ifpsi ifcnt

		* one column per pre horizon, kept separate for the joint test
		if `want_pt' {
			forvalues h = 2/`pre_window' {
				tempvar ptpsi`h'
			}
			tempvar ptinw
			qui gen byte `ptinw' = 0
			local ptvars ""
			local ptb ""
			local ptmiss ""
		}

		* running totals to compute agggrate average and its SE
		if `want_agg' {
			tempvar aggA_post aggB_post aggC_post aggA_pre aggB_pre aggC_pre aggpsi aggcnt aggnz aggd agginc agginw_post agginw_pre
			qui gen byte `aggd' = (D.`treat'==1)
			foreach hz in post pre {
				qui gen double `aggA_`hz'' = 0
				qui gen double `aggB_`hz'' = 0
				qui gen double `aggC_`hz'' = 0
				qui gen byte `agginw_`hz'' = 0
				local aggS_`hz' = 0
				local aggT_`hz' = 0
				local aggmiss_`hz' ""
			}
		}

		* under only_pooled the event study runs only to feed the aggregates, so
		* each half is estimated only if a requested option consumes it
		local skip_post = ("`only_pooled'"!="" & !`want_agg')
		local skip_pre  = ("`only_pooled'"!="" & "`pretrend_test'"=="" & !`want_agg')

		local bsraokneed = (`want_if' & `want_agg' & "`bootstrap'"!="" & "`rw_ra'"!="")

		* run LP-DiD regressions
		local max_window = max(`post_window',`pre_window')
		forval h = 0/`max_window' {
			foreach horizon in `horizons'{
				if ("`horizon'"=="post" & `h'>`post_window') | ("`horizon'"=="pre" & (`h'<=1 | `h'>`pre_window')){
					continue 
				}
				if `skip_`horizon'' continue
				if  "`nocomp'"!="" {
					local reweight "reweight"
					local ccc "CCS_nocomp_event" 
				}
				if "`nocomp'"=="" {
					if "`horizon'"=="pre" local reweight "reweight_m`h'"
					if "`horizon'"=="post" local reweight "reweight_`h'"
					if "`horizon'"=="post" local ccc CCS_`h'
					if "`horizon'"=="pre"  local ccc CCS_m`h'
				}
				if "`horizon'"=="pre"  local D "Dm"				
				if "`horizon'"=="post" local D "D"
				if "`horizon'"=="post" local i = `pre_window' + `h' + 1
				if "`horizon'"=="pre"  local i = `pre_window' - `h' + 1			
				* row label, used if the regression cannot be run
				if "`horizon'"=="post" local rlab "tau`h'"
				if "`horizon'"=="pre"  local rlab "pre`h'"

				local ifok = 0
				local ifvar = 0
				local bsok = 0
				local ifid = 1		// regression did not drop D.treat
				local ifneut = 0	// pre horizon zero by construction, from outcome lags
				local ifr2 = 0
				local ifscale = .
				if "`rw_ra'"=="" {
					if "`bootstrap'"!=""{
						cap quietly reghdfe `D'`h'y  						///
								D.`treat' `rhs'   			 					///   	treatment indicator + any covariates
								if `ccc'==1 & `touse' 							/// 	clean controls condition
								[pweight=`reweight'],	 						/// 	get equally-weighted ATT if specified
								absorb(`fixed_effects') vce(cluster `cluster')	// 		time indicators + any additional absorbed FEs
						if _rc!=0 {
							* a fit fails either for want of rows or for want of variation
							qui count if `ccc'==1 & `touse' & !missing(`D'`h'y)
							if r(N) > 0 local nodegen "`nodegen' `rlab'"
							else local nofit "`nofit' `rlab'"
						}
						else {
							local nfit = `nfit' + 1
							mat J[`i',1] = _b[D.`treat']
							mat J[`i',7] = e(N)

							* check whether reghdfe omitted the D.treat coefficient
							local ifid = 1
							if _b[D.`treat']==0 & _se[D.`treat']==0 {
								local ifid = 0
								foreach c in `: colnames e(b)' {
									if "`c'"=="D.`treat'" local ifid = 1
								}
							}
							local ifr2 = cond(missing(e(r2)), 0, e(r2))
							* spread of this horizon's regressand, the scale a coefficient is judged against
							local ifscale = sqrt(e(tss)/(e(N)-1))

							* the weight and coefficient this horizon contributes to the aggregate;
							* counted before boottest, which clears e()
							if `want_if' & `ifid' {
								local bsok = 1
								local ifvar = 1
								local bshlist_`horizon' "`bshlist_`horizon'' `h'"
								local bsb_`horizon'_`h' = _b[D.`treat']
								local bsrw_`horizon'_`h' "`reweight'"
								local bsccs_`horizon'_`h' "`ccc'"
								local bsdv_`horizon'_`h' "`D'`h'y"
								if `want_agg' {
									qui count if e(sample) & `aggd'==1
									local bsN_`horizon'_`h' = r(N)
									local aggS_`horizon' = `aggS_`horizon'' + r(N)
									local aggT_`horizon' = `aggT_`horizon'' + r(N)*`bsb_`horizon'_`h''
								}
							}

							if `ifid' {
								cap quietly boottest D.`treat', reps(`bootstrap') ///
										nograph bootcluster(`cluster') level(`level')
								if _rc==0 {
									mat J[`i',2] = .
									mat J[`i',3] = round(r(t),0.01)
									mat J[`i',4] = round(r(p),0.0001)
									cap matrix drop `btci'
									cap matrix `btci' = r(CI)
									if _rc==0 {
										if colsof(`btci')>=2 {
											mat J[`i',5] = `btci'[1,1]
											mat J[`i',6] = `btci'[1,2]
										}
									}
									local bsncall = `bsncall' + 1
									if r(reps) < `bootstrap' {
										local bsnwarn = `bsnwarn' + 1
										local bsdraws "`bsdraws' `rlab'(`=r(reps)' reps)"
										if r(reps) < `bsrepmin' local bsrepmin = r(reps)
										if r(reps) > `bsrepmax' | `bsrepmax'>=. local bsrepmax = r(reps)
									}
								}
							}

							* zero by construction: the controls alone span the outcome
							if `ylagctl' & "`horizon'"=="pre" & `ifid' & `ifr2' > 1 - `neuttol' & ///
								abs(J[`i',1]) < 1e-8*`ifscale' {
								cap quietly reghdfe `D'`h'y `rhs' if `ccc'==1 & `touse' ///
									[pweight=`reweight'], absorb(`fixed_effects') nosample
								if _rc==0 & !missing(e(r2)) local ifneut = (e(r2) > 1 - `neuttol')
							}
						}
					}
					else{ // compute confidence intervals
						local ifres ""
						if `want_if' {
							cap drop `ifeh'
							local ifres "residuals(`ifeh')"
						}
						cap quietly reghdfe `D'`h'y  						///
								D.`treat' `rhs'   			 					///   	treatment indicator + any covariates
								if `ccc'==1 & `touse' 							/// 	clean controls condition
								[pweight=`reweight'],	 						/// 	get equally-weighted ATT if specified
								absorb(`fixed_effects') vce(cluster `cluster')	/// 	time indicators + any additional absorbed FEs
								nosample `ifres'
						if _rc!=0 {
							* a fit fails either for want of rows or for want of variation
							qui count if `ccc'==1 & `touse' & !missing(`D'`h'y)
							if r(N) > 0 local nodegen "`nodegen' `rlab'"
							else local nofit "`nofit' `rlab'"
						}
						else {
							local nfit = `nfit' + 1
							mat J[`i',1] = _b[D.`treat']
							mat J[`i',7] = e(N)
							mat J[`i',2] = _se[D.`treat']
							mat J[`i',3] = round(_b[D.`treat'] / _se[D.`treat'],0.01)
							mat J[`i',4] = round((2 * ttail(e(df_r), abs(_b[D.`treat'] / _se[D.`treat']))),0.0001)
							mat J[`i',5] = _b[D.`treat'] + _se[D.`treat']*invt(e(df_r), `p2')
							mat J[`i',6] = _b[D.`treat'] - _se[D.`treat']*invt(e(df_r), `p2')

							* check whether reghdfe omitted the D.treat coefficient
							local ifid = 1
							if _b[D.`treat']==0 & _se[D.`treat']==0 {
								local ifid = 0
								foreach c in `: colnames e(b)' {
									if "`c'"=="D.`treat'" local ifid = 1
								}
							}
							local ifr2 = cond(missing(e(r2)), 0, e(r2))
							* spread of this horizon's regressand, the scale a coefficient is judged against
							local ifscale = sqrt(e(tss)/(e(N)-1))

							if `want_if' & `ifid' {
								* the residual marks the estimation sample; the treatment
								* indicator is residualised over the same rows
								local ifN = e(N)
								local ifb = _b[D.`treat']
								if `want_ifchk' {
									local ifse = _se[D.`treat']
									local ifq = (e(N_clust)/(e(N_clust)-1)) * ((e(N)-1)/(e(N)-e(df_m)-e(df_a)))
								}
								cap drop `ifdt' `ifnum' `ifden'
								cap quietly reghdfe D.`treat' `rhs'			///
										if !missing(`ifeh')					///
										[pweight=`reweight'],				///
										absorb(`fixed_effects') nosample residuals(`ifdt')
								if _rc==0 {
									qui count if !missing(`ifeh') & !missing(`ifdt')
									if r(N)==`ifN' {
										qui gen double `ifnum' = `reweight'*`ifdt'*`ifeh'
										qui gen double `ifden' = `reweight'*`ifdt'*`ifdt'
										qui summarize `ifden', meanonly
										* if the denominator is 0, this horizon's coefficient is not identified
										local ifvar = (r(sum) > 0)
										qui replace `ifnum' = `ifnum'/r(sum)
										if `want_ifchk' {
											* sum within cluster, then square; each cluster's squared
											* total is spread evenly over its own rows
											cap drop `ifpsi' `ifcnt'
											qui egen double `ifpsi' = total(`ifnum'), by(`cluster')
											qui egen long `ifcnt' = count(`ifpsi'), by(`cluster')
											qui replace `ifpsi' = `ifpsi'^2/`ifcnt'
											qui summarize `ifpsi', meanonly
											mat IFCHK[`i',1] = `ifse'
											mat IFCHK[`i',2] = sqrt(r(sum)*`ifq')
										}

										* this horizon has a usable influence function
										local ifok = 1
									}
								}
							}

							* zero by construction: the controls alone span the outcome
							if `ylagctl' & "`horizon'"=="pre" & `ifid' & `ifr2' > 1 - `neuttol' & ///
								abs(J[`i',1]) < 1e-8*`ifscale' {
								cap quietly reghdfe `D'`h'y `rhs' if `ccc'==1 & `touse' ///
									[pweight=`reweight'], absorb(`fixed_effects') nosample
								if _rc==0 & !missing(e(r2)) local ifneut = (e(r2) > 1 - `neuttol')
							}
						}
					}
				}
				else if "`rw_ra'"!="" { // using regression adjustment

					* Regression adjustment imputes a counterfactual for the treated
					* observations, so it needs a clean control in every cell it
					* conditions on. It can introduce a bug if cells without clean
					* controls are used in estimation, so we will detect any and
					* exclude it.
					if "`nocomp'"=="" {
						cap drop `raok'
						qui gen byte `isctl' = (`ccc'==1 & `touse' & !missing(`D'`h'y) & dtreat==0)
						fvrevar `rhs', list
						qui markout `isctl' `r(varlist)' `weight_name' `cluster', strok
						qui gen byte `raok'  = 1
						foreach fe in `fixed_effects' {
							cap drop `hasctl'
							qui egen byte `hasctl' = max(`isctl'), by(`fe')
							qui replace `raok' = 0 if `hasctl'!=1
						}
						forvalues q = 1/`raoknsets' {
							cap drop `hasctl'
							qui egen byte `hasctl' = max(`isctl'), by(`raokset`q'')
							qui replace `raok' = 0 if `hasctl'!=1
						}
						cap drop `isctl' `hasctl'
					}
					* the stack has to reproduce this regression, so its restriction is kept
					if `bsraokneed' {
						tempvar bsraok_`horizon'_`h'
						qui gen byte `bsraok_`horizon'_`h'' = `raok'
					}
					if "`bootstrap'"==""{
						local raN = .
						* listreg returns the influence function directly, already on the psi scale
						local ifgen ""
						if `want_if' {
							cap drop `ifnum'
							local ifgen "ifgenerate(`ifnum')"
						}
						cap quietly listreg `D'`h'y = dtreat if `ccc'==1 & `touse' & `raok'==1 `ra_reweight', controls(`rhs') normal vce(cluster `cluster') `ifgen'
						local rcra = _rc
						if `rcra'==0 {
							matrix `rab' = e(b)
							matrix `raV' = e(V)
							local raNobs = e(N)
							cap drop `rasamp'
							qui gen byte `rasamp' = e(sample)
						}

						local raprobe = (`rcra'!=0) // detect "degenerate" cases: failed estimation, or ~0 coeff and SE.
						* the matrices exist only where the estimation succeeded
						if `rcra'==0 {
							if abs(`rab'[1,1]) < 1e-8*`yscale' & sqrt(`raV'[1,1]) < 1e-8*`yscale' local raprobe = 1
						}
						if `raprobe' {
							local ifprb = .
							* listreg reports neither an omitted marker nor an r2, so one fit supplies both
							cap quietly reghdfe `D'`h'y dtreat `rhs' ///
								if `ccc'==1 & `touse' & `raok'==1 `ra_reweight', ///
								absorb(`fixed_effects') nosample
							if _rc==0 {
								local ifr2 = cond(missing(e(r2)), 0, e(r2))
								* spread of this horizon's regressand, the scale a coefficient is judged against
								local ifscale = sqrt(e(tss)/(e(N)-1))
								local ifprb = _b[dtreat]
								mat J[`i',7] = e(N)
								if _b[dtreat]==0 & _se[dtreat]==0 {
									local ifid = 0
									foreach c in `: colnames e(b)' {
										if "`c'"=="dtreat" local ifid = 1
									}
								}
							}

							* zero by construction: the controls alone span the outcome
							if `ylagctl' & "`horizon'"=="pre" & `ifid' & `ifr2' > 1 - `neuttol' & ///
								abs(`ifprb') < 1e-8*`ifscale' {
								cap quietly reghdfe `D'`h'y `rhs' ///
									if `ccc'==1 & `touse' & `raok'==1 `ra_reweight', ///
									absorb(`fixed_effects') nosample
								if _rc==0 & !missing(e(r2)) local ifneut = (e(r2) > 1 - `neuttol')
								* the coefficient is zero whether or not listreg could return it
								if `ifneut' {
									mat J[`i',1] = 0
									mat J[`i',2] = .
								}
							}
						}

						if `ifid' {
							if `rcra'==0 {
								* listreg reports normal critical values, applied here at the requested level
								local nfit = `nfit' + 1
								mat J[`i',1] = cond(`ifneut', 0, `rab'[1,1])
								mat J[`i',2] = sqrt(`raV'[1,1])
								mat J[`i',3] = round(`rab'[1,1]/sqrt(`raV'[1,1]),0.01)
								mat J[`i',4] = round(2*normal(-abs(`rab'[1,1]/sqrt(`raV'[1,1]))),0.0001)
								mat J[`i',5] = `rab'[1,1] + sqrt(`raV'[1,1])*invnormal(`p2')
								mat J[`i',6] = `rab'[1,1] - sqrt(`raV'[1,1])*invnormal(`p2')
								mat J[`i',7] = `raNobs'
								local raN = `raNobs'

								if `want_if' {
									local ifb = `rab'[1,1]
									local ifok = 1
									* a horizon whose influence function is all zeros carries no variation
									qui count if `ifnum'!=0 & !missing(`ifnum')
									local ifvar = (r(N) > 0)

									if `want_ifchk' {
										* listreg applies no finite-sample correction, so the raw sum matches
										cap drop `ifpsi' `ifcnt'
										qui egen double `ifpsi' = total(`ifnum'), by(`cluster')
										qui egen long `ifcnt' = count(`ifpsi'), by(`cluster')
										qui replace `ifpsi' = `ifpsi'^2/`ifcnt'
										qui summarize `ifpsi', meanonly
										mat IFCHK[`i',1] = sqrt(`raV'[1,1])
										mat IFCHK[`i',2] = sqrt(r(sum))
									}
								}
							}
							else if `rcra'==504 { // deterministic outcome: SE not obtainable, but point estimate is
								cap quietly listreg `D'`h'y = dtreat if `ccc'==1 & `touse' & `raok'==1 `ra_reweight', controls(`rhs') normal vce(cluster `cluster') nose 
								if _rc==0 {
									local nfit = `nfit' + 1
									mat J[`i',1] = cond(`ifneut', 0, r(table)[1,1])
									mat J[`i',2] = 0
									mat J[`i',3] = .
									mat J[`i',4] = .
									mat J[`i',5] = .
									mat J[`i',6] = .
									mat J[`i',7] = e(N) 
									local raN = e(N)
									cap drop `rasamp'
									qui gen byte `rasamp' = e(sample)
								}
							}
							else if !`ifneut' {
								* a fit fails either for want of rows or for want of variation
								qui count if `ccc'==1 & `touse' & `raok'==1 & !missing(`D'`h'y)
								if r(N) > 0 local nodegen "`nodegen' `rlab'"
								else local nofit "`nofit' `rlab'"
							}

							* a horizon that is zero by construction contributes its weight and a zero
							* coefficient to the aggregate, and an influence function of zero
							if `want_if' & `ifneut' & `raN'<. {
								cap drop `ifnum'
								qui gen double `ifnum' = 0 if `rasamp'==1
								local ifb = 0
								local ifok = 1
							}
						}
					}
					if "`bootstrap'"!=""{
						quietly cap reg `D'`h'y i.dtreat##(`rhs_margins') if `ccc'==1 & `touse' & `raok'==1 `ra_reweight', vce(cluster `cluster')
						* store treated count if aggregate_average applies (must be here, not after margins)
						local rcra = _rc
						local ifr2 = cond(`rcra'==0 & !missing(e(r2)), e(r2), 0)

						* the interacted fit drops the whole treated branch when it cannot
						* identify it; the level surviving under its own name is the test
						if `rcra'==0 {
							mat J[`i',7] = e(N)
							local ifid = 0
							foreach c in `: colnames e(b)' {
								if "`c'"=="1.dtreat" local ifid = 1
							}
						}
						if `rcra'==0 & `ifid' & `want_if' & `want_agg' {
							qui count if e(sample) & dtreat==1
							local bsNh = r(N)
						}
						local rcmg = 1
						local bsbh = .
						if `rcra'==0 & `ifid' {
							quietly cap margins r.dtreat if `ccc'==1 & `touse' & `raok'==1 `ra_reweight', subpop(dtreat)
							local rcmg = _rc
							if `rcmg'==0 local bsbh = r(table)[1,1]
						}
						* a contrast the estimator could not deliver is not an estimate of zero
						if `rcmg'==0 & !missing(`bsbh') {
							local nfit = `nfit' + 1
							mat J[`i',1] = `bsbh'
							cap quietly boottest, reps(`bootstrap') ///
								nograph bootcluster(`cluster') level(`level') ///
								margins
							local rcbt = _rc
							mat J[`i',2] = .
							* the point estimate stands whether or not the bootstrap ran
							if `rcbt'==0 {
								mat J[`i',3] = round(r(t),0.01)
								mat J[`i',4] = round(r(p),0.0001)
								local bsncall = `bsncall' + 1
								if r(reps) < `bootstrap' {
									local bsnwarn = `bsnwarn' + 1
									local bsdraws "`bsdraws' `rlab'(`=r(reps)' reps)"
									if r(reps) < `bsrepmin' local bsrepmin = r(reps)
									if r(reps) > `bsrepmax' | `bsrepmax'>=. local bsrepmax = r(reps)
								}
								cap matrix drop `btci'
								cap matrix `btci' = r(CI)
								if _rc==0 {
									if colsof(`btci')>=2 {
										mat J[`i',5] = `btci'[1,1]
										mat J[`i',6] = `btci'[1,2]
									}
								}
							}

							* record what this horizon contributes to the aggregate
							if `want_if' {
								local bsok = 1
								local ifvar = 1
								local bshlist_`horizon' "`bshlist_`horizon'' `h'"
								local bsb_`horizon'_`h' = `bsbh'
								local bsrw_`horizon'_`h' "`reweight'"
								local bsccs_`horizon'_`h' "`ccc'"
								local bsdv_`horizon'_`h' "`D'`h'y"
								if `want_agg' {
									local bsN_`horizon'_`h' = `bsNh'
									local aggS_`horizon' = `aggS_`horizon'' + `bsNh'
									local aggT_`horizon' = `aggT_`horizon'' + `bsNh'*`bsbh'
								}
							}
						}

						* zero by construction: the controls alone span the outcome
						if `ylagctl' & "`horizon'"=="pre" & `ifid' & `ifr2' > 1 - `neuttol' {
							local ifaux = .
							cap quietly reg `D'`h'y dtreat `rhs_margins' ///
								if `ccc'==1 & `touse' & `raok'==1 `ra_reweight'
							if _rc==0 {
								local ifaux = _b[dtreat]
								local ifscale = sqrt((e(mss)+e(rss))/(e(N)-1))
							}
							if abs(`ifaux') < 1e-8*`ifscale' {
								cap quietly reg `D'`h'y `rhs_margins' ///
									if `ccc'==1 & `touse' & `raok'==1 `ra_reweight'
								if _rc==0 & !missing(e(r2)) local ifneut = (e(r2) > 1 - `neuttol')
								* the coefficient is zero whether or not margins could return it
								if `ifneut' & (`rcmg'!=0 | missing(`bsbh')) {
									mat J[`i',1] = 0
									mat J[`i',2] = .
								}
							}
						}

						* a fit that produced no usable contrast, and is not zero by construction
						if (`rcmg'!=0 | missing(`bsbh')) & `ifid' & !`ifneut' {
							* a fit fails either for want of rows or for want of variation
							qui count if `ccc'==1 & `touse' & `raok'==1 & !missing(`D'`h'y)
							if r(N) > 0 local nodegen "`nodegen' `rlab'"
							else local nofit "`nofit' `rlab'"
						}
					}
				}
				* add this horizon to the running totals
				if `ifok' {
					if `want_agg' & `ifid' {
						qui count if !missing(`ifnum') & `aggd'==1
						local aggN = r(N)
						qui replace `aggA_`horizon'' = `aggA_`horizon'' + `aggN'*`ifnum' if !missing(`ifnum')
						qui replace `aggB_`horizon'' = `aggB_`horizon'' + `ifb' if !missing(`ifnum') & `aggd'==1
						qui replace `aggC_`horizon'' = `aggC_`horizon'' + 1 if !missing(`ifnum') & `aggd'==1
						qui replace `agginw_`horizon'' = 1 if !missing(`ifnum')
						local aggS_`horizon' = `aggS_`horizon'' + `aggN'
						local aggT_`horizon' = `aggT_`horizon'' + `aggN'*`ifb'
					}

					* keep this horizon's influence function for the joint test; a horizon that
					* is zero by construction carries no information and would make the
					* covariance matrix singular
					if `want_pt' & "`horizon'"=="pre" & `ifvar' & `ifid' & !`ifneut' {
						qui egen double `ptpsi`h'' = total(`ifnum'), by(`cluster')
						qui replace `ptinw' = 1 if !missing(`ifnum')
						local ptvars "`ptvars' `ptpsi`h''"
						local ptb "`ptb' `ifb'"
						local ptP = `ptP' + 1
					}
				}
				local hok = (`ifok' | `bsok')
				* an unidentified coefficient is not an estimate of anything, so it is
				* reported missing rather than as a zero measured without error
				if !`ifid' {
					forvalues jj = 1/6 {
						mat J[`i',`jj'] = .
					}
					local noid "`noid' `rlab'"
				}
				if `ifneut' local neutlist "`neutlist' `rlab'"
				if `want_agg' & (!`hok' | !`ifid') local aggmiss_`horizon' "`aggmiss_`horizon'' `rlab'"
				if `want_pt' & "`horizon'"=="pre" & !`ifneut' & (!`hok' | !`ifvar' | !`ifid') local ptmiss "`ptmiss' `rlab'"
			}
		}		

		* With bootstrap, aggregate_average and pretrend_test use stacked regression
		local bsagg_post = 0
		local bsagg_pre  = 0
		local bspt = 0
		local bsmismatch ""
		local bsnoest ""
		if `want_if' & "`bootstrap'"!="" & "`rw_ra'"=="" {
			local bsdo_post = 0
			local bsdo_pre  = 0
			if `want_agg' {
				local bsdo_post = ("`aggmiss_post'"=="" & `aggS_post'>0)
				local bsdo_pre  = ("`aggmiss_pre'"=="" & `aggS_pre'>0)
			}
			local bsdo_pt   = (`want_pt' & "`bshlist_pre'"!="")
			if `bsdo_post' | `bsdo_pre' | `bsdo_pt' {
				* interact rhs with horizon indicator + store stripped variable names
				local bsx ""			// stores interaction terms
				local bsrhs ""			// stores stripped variable names
				foreach v of local rhs {
					if inlist(substr("`v'",1,2),"i.","c.") {
						local bsx "`bsx' i._bshor#`v'"
						fvrevar `v', list
						local bsrhs "`bsrhs' `r(varlist)'"
					}
					else {
						fvrevar `v', tsonly
						local bsv "`r(varlist)'"
						local bsx "`bsx' i._bshor#c.`bsv'"
						local bsrhs "`bsrhs' `bsv'"
					}
				}
				tempvar bsdt
				qui gen double `bsdt' = D.`treat'
				tempfile bsbase bsacc
				qui save `bsbase', replace

				local bsk = 0
				foreach hz in post pre {
					foreach h of local bshlist_`hz' {
						local bsk = `bsk' + 1
						local bscode_`hz'_`h' = `bsk'
						qui use `bsbase', clear
						qui keep if `bsccs_`hz'_`h''==1 & `touse' & !missing(`bsdv_`hz'_`h'')
						qui gen double _bsy = `bsdv_`hz'_`h''
						qui gen double _bsw = `bsrw_`hz'_`h''
						qui gen int _bshor = `bsk'
						qui keep `time' `cluster' `bsdt' `bsrhs' _bsy _bsw _bshor
						qui drop if missing(_bsw)
						if `bsk'==1 qui save `bsacc', replace
						else {
							qui append using `bsacc'
							qui save `bsacc', replace
						}
					}
				}
				qui use `bsacc', clear
				tempvar bshortime
				qui egen long `bshortime' = group(_bshor `time')

				cap quietly reghdfe _bsy i._bshor#c.`bsdt' `bsx' [pweight=_bsw], ///
					absorb(`bshortime') vce(cluster `cluster')
				if _rc==0 {
					* map each horizon code to its coefficient name, from e(b) itself:
					* the base level is 0b. and dropped horizons carry o.
					tempname bsB bsCI
					matrix `bsB' = e(b)
					local bscn : colnames e(b)
					local bsj = 0
					foreach c of local bscn {
						local bsj = `bsj' + 1
						if strpos("`c'","_bshor")==0 continue
						if strpos("`c'","`bsdt'")==0 continue
						local bshead = substr("`c'", 1, strpos("`c'",".")-1)
						local bsom = (substr("`bshead'", -1, 1)=="o")
						local bsnum = real(subinstr(subinstr("`bshead'","b","",.),"o","",.))
						if `bsnum'>=. continue
						local bsname_`bsnum' "`c'"
						local bsomit_`bsnum' = `bsom'
						local bsval_`bsnum' = `bsB'[1,`bsj']
					}

					* the stacked coefficients must reproduce the per-horizon ones, or the
					* combination would be built on different quantities from those reported
					foreach hz in post pre {
						foreach h of local bshlist_`hz' {
							local bscd = `bscode_`hz'_`h''
							if "`bsname_`bscd''"=="" | `bsomit_`bscd'' continue
							if reldif(`bsb_`hz'_`h'', `bsval_`bscd'') > 1e-4 {
								if "`hz'"=="post" local bsmismatch "`bsmismatch' tau`h'"
								if "`hz'"=="pre"  local bsmismatch "`bsmismatch' pre`h'"
							}
						}
					}

					* the weighted combination, one window at a time
					foreach hz in post pre {
						if !`bsdo_`hz'' | "`bsmismatch'"!="" continue
						local bsgood = 1
						local bslc ""
						foreach h of local bshlist_`hz' {
							local bscd = `bscode_`hz'_`h''
							if "`bsname_`bscd''"=="" | `bsomit_`bscd'' {
								local bsgood = 0
								if "`hz'"=="post" local aggmiss_post "`aggmiss_post' tau`h'"
								if "`hz'"=="pre"  local aggmiss_pre "`aggmiss_pre' pre`h'"
							}
							else {
								local bsw = `bsN_`hz'_`h''/`aggS_`hz''
								local bslc "`bslc' + `bsw'*`bsname_`bscd''"
							}
						}
						if `bsgood' {
							local bslc = substr("`bslc'", 3, .)
							cap quietly boottest `bslc' = 0, reps(`bootstrap') ///
								nograph bootcluster(`cluster') level(`level')
							if _rc==0 {
								matrix `bsCI' = r(CI)
								local bsaggt_`hz' = r(t)
								local bsaggp_`hz' = r(p)
								local bsagglo_`hz' = `bsCI'[1,1]
								local bsagghi_`hz' = `bsCI'[1,2]
								local bsagg_`hz' = 1
								local bsncall = `bsncall' + 1
								if r(reps) < `bootstrap' {
									local bslab = cond("`hz'"=="post", "`agglab'", "Pre_avg")
									local bsnwarn = `bsnwarn' + 1
									local bsdraws "`bsdraws' `bslab'(`=r(reps)' reps)"
									if r(reps) < `bsrepmin' local bsrepmin = r(reps)
									if r(reps) > `bsrepmax' | `bsrepmax'>=. local bsrepmax = r(reps)
								}
							}
						}
					}

					* the joint test runs on whichever pre horizons survived
					if `bsdo_pt' & "`bsmismatch'"=="" {
						local bspar ""
						local bsptn = 0
						foreach h of local bshlist_pre {
							* a horizon that is zero by construction adds nothing to the statistic
							if strpos(" `neutlist' ", " pre`h' ") continue
							local bscd = `bscode_pre_`h''
							if "`bsname_`bscd''"!="" & !`bsomit_`bscd'' {
								local bspar "`bspar' (`bsname_`bscd'')"
								local bsptn = `bsptn' + 1
							}
							else local ptmiss "`ptmiss' pre`h'"
						}
						if `bsptn' > 0 {
							cap quietly boottest `bspar', reps(`bootstrap') ///
								nograph bootcluster(`cluster')
							if _rc==0 & r(NH0s)==1 & r(df)==`bsptn' {
								local bsptF = r(F)
								local bsptp = r(p)
								local bsptdf = `bsptn'
								local bspt = 1
								local bsncall = `bsncall' + 1
								if r(reps) < `bootstrap' {
									local bsnwarn = `bsnwarn' + 1
									local bsdraws "`bsdraws' Pre-trend test(`=r(reps)' reps)"
									if r(reps) < `bsrepmin' local bsrepmin = r(reps)
									if r(reps) > `bsrepmax' | `bsrepmax'>=. local bsrepmax = r(reps)
								}
							}
						}
					}
				}
				qui use `bsbase', clear
			}
		}

		* With bootstrap & RA, aggregate_average uses stacked regression + margins
		if `want_if' & "`bootstrap'"!="" & "`rw_ra'"!="" {
			local bsdo_post = 0
			local bsdo_pre  = 0
			if `want_agg' {
				local bsdo_post = ("`aggmiss_post'"=="" & `aggS_post'>0)
				local bsdo_pre  = ("`aggmiss_pre'"=="" & `aggS_pre'>0)
			}
			if `bsdo_post' | `bsdo_pre' {
				fvrevar `rhs_margins', list
				local bsrhs "`r(varlist)'"
				tempvar bsdt
				qui gen double `bsdt' = dtreat
				tempfile bsbase bsacc
				tempname bsB bsCI
				qui save `bsbase', replace

				foreach hz in post pre {
					if !`bsdo_`hz'' continue
					local bslab = cond("`hz'"=="post", "`agglab'", "Pre_avg")
					local bsk = 0
					foreach h of local bshlist_`hz' {
						local bsk = `bsk' + 1
						qui use `bsbase', clear
						qui keep if `bsccs_`hz'_`h''==1 & `touse' & !missing(`bsdv_`hz'_`h'') & `bsraok_`hz'_`h''==1
						qui gen double _bsy = `bsdv_`hz'_`h''
						if "`weight_name'"!="" qui gen double _bsw = `weight_name'
						if "`weight_name'"=="" qui gen double _bsw = 1
						qui gen int _bshor = `bsk'
						qui keep `time' `cluster' `bsdt' `bsrhs' _bsy _bsw _bshor
						qui drop if missing(_bsw)
						if `bsk'==1 qui save `bsacc', replace
						else {
							qui append using `bsacc'
							qui save `bsacc', replace
						}
					}
					qui use `bsacc', clear

					cap quietly reg _bsy i._bshor##i.`bsdt'##(`rhs_margins') ///
						i._bshor#i.`time' i.`bsdt'#i._bshor#i.`time' ///
						[pweight=_bsw], vce(cluster `cluster')
					if _rc==0 {
						cap quietly margins r.`bsdt', subpop(`bsdt')
						if _rc==0 {
							matrix `bsB' = r(b)
							local bsstk = `bsB'[1,1]
							* a contrast the estimator declined to form is not a failed consistency check
							if missing(`bsstk') {
								local bsnoest "`bsnoest' `bslab'"
							}
							* the stacked estimate must reproduce the loop's aggregate
							else if reldif(`aggT_`hz''/`aggS_`hz'', `bsstk') > 1e-4 {
								local bsmismatch "`bsmismatch' `bslab'"
							}
							else {
								cap quietly boottest, reps(`bootstrap') ///
									nograph bootcluster(`cluster') level(`level') margins
								if _rc==0 {
									matrix `bsCI' = r(CI)
									local bsaggt_`hz' = r(t)
									local bsaggp_`hz' = r(p)
									local bsagglo_`hz' = `bsCI'[1,1]
									local bsagghi_`hz' = `bsCI'[1,2]
									local bsagg_`hz' = 1
									local bsncall = `bsncall' + 1
									if r(reps) < `bootstrap' {
										local bsnwarn = `bsnwarn' + 1
										local bsdraws "`bsdraws' `bslab'(`=r(reps)' reps)"
										if r(reps) < `bsrepmin' local bsrepmin = r(reps)
										if r(reps) > `bsrepmax' | `bsrepmax'>=. local bsrepmax = r(reps)
									}
								}
							}
						}
					}
				}
				qui use `bsbase', clear
			}
		}

		* the observation-weighted average over each window, and its standard
		* error from the per-unit influence function of the average itself
		if `want_agg' {
			* a window contributes a row only if every one of its horizons was estimated
			local aggrows ""
			local aggnr = 0
			foreach hz in post pre {
				if `aggS_`hz''>0 & "`aggmiss_`hz''"=="" {
					local aggnr = `aggnr' + 1
					if "`hz'"=="post" local aggrows "`aggrows' `agglab'"
					if "`hz'"=="pre"  local aggrows "`aggrows' Pre_avg"
					local aggrow_`hz' = `aggnr'
				}
				else local aggrow_`hz' = 0
			}
			if `aggnr'==0 local aggskip "all"
			else {
				matrix AGG = J(`aggnr',7,.)
				matrix colnames AGG = "Coefficient" "SE" "t" "P>|t|" "[`level'% conf." "interval]" "obs"
				matrix rownames AGG = `aggrows'
				foreach hz in post pre {
					if `aggrow_`hz''==0 continue
					local rown = `aggrow_`hz''
					local aggth = `aggT_`hz''/`aggS_`hz''
					matrix AGG[`rown',1] = `aggth'
					matrix AGG[`rown',7] = `aggS_`hz''

					* under bootstrap() there is no standard error; the interval comes from
					* inverting the test on the stacked combination
					if "`bootstrap'"!="" {
						if `bsagg_`hz'' {
							matrix AGG[`rown',3] = round(`bsaggt_`hz'',0.01)
							matrix AGG[`rown',4] = round(`bsaggp_`hz'',0.0001)
							matrix AGG[`rown',5] = `bsagglo_`hz''
							matrix AGG[`rown',6] = `bsagghi_`hz''
						}
					}
					else {
						qui replace `aggA_`hz'' = (`aggA_`hz'' + `aggB_`hz'' - `aggth'*`aggC_`hz'')/`aggS_`hz''
						cap drop `aggpsi' `aggcnt' `aggnz' `agginc'
						qui egen double `aggpsi' = total(`aggA_`hz''), by(`cluster')
						qui egen long `aggcnt' = count(`aggpsi'), by(`cluster')
						* Count clusters in this window's estimation sample
						qui egen byte `agginc' = max(`agginw_`hz''), by(`cluster')
						qui gen double `aggnz' = `agginc'/`aggcnt'
						qui summarize `aggnz', meanonly
						local aggM = round(r(sum))
						qui replace `aggpsi' = `aggpsi'^2/`aggcnt'
						qui summarize `aggpsi', meanonly
						local aggse = sqrt(r(sum))
						matrix AGG[`rown',2] = `aggse'
						if `aggse'>0 & `aggM'>1 {
							matrix AGG[`rown',3] = round(`aggth'/`aggse',0.01)
							matrix AGG[`rown',4] = round(2*ttail(`aggM'-1,abs(`aggth'/`aggse')),0.0001)
							matrix AGG[`rown',5] = `aggth' - invttail(`aggM'-1,`p2')*`aggse'
							matrix AGG[`rown',6] = `aggth' + invttail(`aggM'-1,`p2')*`aggse'
						}
					}
				}
			}
		}

		* Test that all pre-treatment coefficients are zero
		if `want_pt' {
			tempvar ptcnt ptinc ptnz
			tempname ptF ptp
			local ptdf = .
			local ptM = .
			local ptrank ""
			* under bootstrap() the test was run on the stack, with no cluster count
			* and no reference distribution of our own
			if "`bootstrap'"!="" {
				if `bspt' {
					local ptdf = `bsptdf'
					scalar `ptF' = `bsptF'
					scalar `ptp' = `bsptp'
					local ptdone = 1
				}
			}
			else if `ptP' > 0 {
				local ptfirst : word 1 of `ptvars'
				cap drop `ptcnt' `ptinc' `ptnz'
				qui egen long `ptcnt' = count(`ptfirst'), by(`cluster')
				* Count clusters in the tested horizons' estimation sample
				qui egen byte `ptinc' = max(`ptinw'), by(`cluster')
				qui gen double `ptnz' = `ptinc'/`ptcnt'
				qui summarize `ptnz', meanonly
				mata: lpdid_pretrend("`ptvars'", "`ptcnt'", "`ptb'", `=round(r(sum))', "`ptF'", "`ptp'")
			}
		}

		local i = `pre_window'
		mat J[`i',1] = 0 
						
	} 
	
	
	** Pooled estimation 
	if "`debug'"!="" di "Pooled regressions"		
	
	if `want_pooled'{
	
		matrix P=J(2,7,.) 
		matrix colnames P = "Coefficient" "SE" "`statlab'" "P>|`statlab'|" "[`level'% conf." "interval]" "obs"
		matrix rownames P = "Pre" "Post"
		

		local i = 0
		foreach horizon in pre post{
			local i=`i'+1 
			* nothing requested on this side, so nothing estimated
			if "`no_`horizon''"!="" & "``horizon'_pooled'"==""{
				mat P[`i',1] = .
				mat P[`i',2] = .
				mat P[`i',3] = .
				mat P[`i',4] = .
				mat P[`i',5] = .
				mat P[`i',6] = .
				mat P[`i',7] = .				
				local nofit "`nofit' pooled_`horizon'"
				continue 
			}			
			
			* generating pooled dependent variable: the mean of the outcome over the
			* pooling window. The window is a set of lags on the pre side and of leads
			* on the post side, so the horizon fixes the time-series operator and the
			* endpoints are always entered as positive distances from t.
			if "`horizon'"=="pre" {
				local tsop "L"
				qui numlist "`pre_pooled_end'/`pre_pooled_start'"
				local wlist "`r(numlist)'"
			}
			if "`horizon'"=="post" {
				local tsop "F"
				qui numlist "`post_pooled_end'/`post_pooled_start'"
				local wlist "`r(numlist)'"
			}

			* every period in the window is required: a row missing any outcome in its
			* window drops out, as does a date whose window runs past the end of the panel
			local nwin : word count `wlist'
			local allx "0"
			foreach l of local wlist {
				local allx "`allx' + `tsop'`l'.`depvar'"
			}
			qui gen double aveFY = (`allx')/`nwin'
			if "`pmd'"=="" { // recall aveLY was created in the previous pmd section
				qui gen double pooled_y = aveFY - L.`depvar'
			}
			if "`pmd'"!="" {
				qui gen double pooled_y = aveFY - aveLY
			} 
			
			* the rows the pooled regression may use
			if "`horizon'"=="pre" local ccc "CCS_m`pre_pooled_end'"
			if "`horizon'"=="post" local ccc "CCS_`post_pooled_end'"
			if "`nocomp'"!="" local ccc "CCS_nocomp_pooled"
			* the regression adjustment path applies the user's weight unchanged
			local ra_reweight_pooled "`ra_reweight'"
			if "`rw'"!="" & "`rw_ra'"=="" {
				cap drop reweight_pooled
				`rwcap' _lpdid_rw , dtr(dtreat_rw) time(`time') touse(`touse') ///
					ccs(`ccc') outcome(pooled_y) generate(reweight_pooled) ///
					wname(`weight_name') cluster(`cluster') `debug'
				local reweight "reweight_pooled"
			}
			if "`rw'"=="" {
				cap drop reweight_pooled
				qui gen double reweight_pooled = 1
				if "`weight_name'"!="" qui replace reweight_pooled = `weight_name'
				local reweight "reweight_pooled"
			}
			
			local pid = 1
			local pneut = 0
			local pr2 = 0
			local pscale = .
			* row label, used if the regression cannot be run
			if "`horizon'"=="pre"  local rlab "pooled_pre"
			if "`horizon'"=="post" local rlab "pooled_post"

			if "`rw_ra'"=="" {
				if "`bootstrap'"!=""{
					cap quietly reghdfe pooled_y  						///
							D.`treat' `rhs'   			 					///   	treatment indicator + any covariates
							if `ccc'==1  & `touse'							/// 	clean controls condition
							[pweight=`reweight'],	 						/// 	get equally-weighted ATT if specified
							absorb(`fixed_effects') vce(cluster `cluster')	// 		time indicators	+ any additional absorbed FEs
					if _rc!=0 {
						* a fit fails either for want of rows or for want of variation
						qui count if `ccc'==1 & `touse' & !missing(pooled_y)
						if r(N) > 0 local nodegen "`nodegen' `rlab'"
						else local nofit "`nofit' `rlab'"
					}
					else {
						local nfit = `nfit' + 1
						mat P[`i',1] = _b[D.`treat']
						mat P[`i',7] = e(N)
						* check whether reghdfe omitted the D.treat coefficient
						local pid = 1
						if _b[D.`treat']==0 & _se[D.`treat']==0 {
							local pid = 0
							foreach c in `: colnames e(b)' {
								if "`c'"=="D.`treat'" local pid = 1
							}
						}
						local pr2 = cond(missing(e(r2)), 0, e(r2))
						* spread of this horizon's regressand, the scale a coefficient is judged against
						local pscale = sqrt(e(tss)/(e(N)-1))
						cap quietly boottest D.`treat', reps(`bootstrap') ///
								nograph bootcluster(`cluster') level(`level')
						if _rc==0 {
							mat P[`i',2] = .
							mat P[`i',3] = round(r(t),0.01)
							mat P[`i',4] = round(r(p),0.0001)
							cap matrix drop `btci'
							cap matrix `btci' = r(CI)
							if _rc==0 {
								if colsof(`btci')>=2 {
									mat P[`i',5] = `btci'[1,1]
									mat P[`i',6] = `btci'[1,2]
								}
							}
							local bsncall = `bsncall' + 1
							if r(reps) < `bootstrap' {
								local bslab = cond(`i'==1, "Pre", "Post")
								local bsnwarn = `bsnwarn' + 1
								local bsdraws "`bsdraws' `bslab'(`=r(reps)' reps)"
								if r(reps) < `bsrepmin' local bsrepmin = r(reps)
								if r(reps) > `bsrepmax' | `bsrepmax'>=. local bsrepmax = r(reps)
							}
						}
						* zero by construction: the controls alone span the pooled outcome
						if `ylagctl' & "`horizon'"=="pre" & `pid' & `pr2' > 1 - `neuttol' & ///
							abs(P[`i',1]) < 1e-8*`pscale' {
							cap quietly reghdfe pooled_y `rhs' if `ccc'==1 & `touse' ///
								[pweight=`reweight'], absorb(`fixed_effects') nosample
							if _rc==0 & !missing(e(r2)) local pneut = (e(r2) > 1 - `neuttol')
						}
					}
				}
				else{ // compute confidence intervals
					cap quietly reghdfe pooled_y  						///
							D.`treat' `rhs'   			 					///   	treatment indicator + any covariates
							if `ccc'==1 & `touse'  							/// 	clean controls condition
							[pweight=`reweight'],	 						/// 	get equally-weighted ATT if specified
							absorb(`fixed_effects') vce(cluster `cluster')	/// 	time indicators	+ any additional absorbed FEs
							nosample
					if _rc!=0 {
						* a fit fails either for want of rows or for want of variation
						qui count if `ccc'==1 & `touse' & !missing(pooled_y)
						if r(N) > 0 local nodegen "`nodegen' `rlab'"
						else local nofit "`nofit' `rlab'"
					}
					else {
						local nfit = `nfit' + 1
						mat P[`i',1] = _b[D.`treat']
						mat P[`i',7] = e(N)
						mat P[`i',2] = _se[D.`treat']
						mat P[`i',3] = round(_b[D.`treat'] / _se[D.`treat'],0.01)
						mat P[`i',4] = round(2 * ttail(e(df_r), abs(_b[D.`treat'] / _se[D.`treat'])),0.0001)
						mat P[`i',5] = _b[D.`treat'] + _se[D.`treat']*invt(e(df_r), `p2')
						mat P[`i',6] = _b[D.`treat'] - _se[D.`treat']*invt(e(df_r), `p2')
						* check whether reghdfe omitted the D.treat coefficient
						local pid = 1
						if _b[D.`treat']==0 & _se[D.`treat']==0 {
							local pid = 0
							foreach c in `: colnames e(b)' {
								if "`c'"=="D.`treat'" local pid = 1
							}
						}
						local pr2 = cond(missing(e(r2)), 0, e(r2))
						* spread of this horizon's regressand, the scale a coefficient is judged against
						local pscale = sqrt(e(tss)/(e(N)-1))
						* zero by construction: the controls alone span the pooled outcome
						if `ylagctl' & "`horizon'"=="pre" & `pid' & `pr2' > 1 - `neuttol' & ///
							abs(P[`i',1]) < 1e-8*`pscale' {
							cap quietly reghdfe pooled_y `rhs' if `ccc'==1 & `touse' ///
								[pweight=`reweight'], absorb(`fixed_effects') nosample
							if _rc==0 & !missing(e(r2)) local pneut = (e(r2) > 1 - `neuttol')
						}
					}
				}
			}
			else if "`rw_ra'"!="" { // using regression adjustment

				* as in the event study above: regression adjustment needs a clean
				* control in every cell it conditions on. Built here on the pooled
				* clean control condition and the pooled outcome.
				tempvar isctl raok hasctl
				qui gen byte `isctl' = (`ccc'==1 & `touse' & !missing(pooled_y) & dtreat==0)
				fvrevar `rhs', list
				qui markout `isctl' `r(varlist)' `weight_name' `cluster', strok
				qui gen byte `raok'  = 1
				foreach fe in `fixed_effects' {
					cap drop `hasctl'
					qui egen byte `hasctl' = max(`isctl'), by(`fe')
					qui replace `raok' = 0 if `hasctl'!=1
				}
				forvalues q = 1/`raoknsets' {
					cap drop `hasctl'
					qui egen byte `hasctl' = max(`isctl'), by(`raokset`q'')
					qui replace `raok' = 0 if `hasctl'!=1
				}
				cap drop `isctl' `hasctl'
				if "`bootstrap'"=="" {
					quietly cap listreg pooled_y = dtreat if `ccc'==1 & `touse' & `raok'==1 `ra_reweight_pooled', controls(`rhs') normal vce(cluster `cluster') level(`level')
					local rcra = _rc
					if `rcra'==0 {
						matrix `prtab' = r(table)
						local praNobs = e(N)
					}

					local praprobe = (`rcra'!=0) // detect "degenerate" cases: failed estimation, or ~0 coeff and SE.
					* the matrix exists only where the estimation succeeded
					if `rcra'==0 {
						if abs(`prtab'[1,1]) < 1e-8*`yscale' & `prtab'[2,1] < 1e-8*`yscale' local praprobe = 1
					}
					if `praprobe' {
						local pprb = .
						* listreg reports neither an omitted marker nor an r2, so one fit supplies both
						cap quietly reghdfe pooled_y dtreat `rhs' ///
							if `ccc'==1 & `touse' & `raok'==1 `ra_reweight_pooled', ///
							absorb(`fixed_effects') nosample
						if _rc==0 {
							local pr2 = cond(missing(e(r2)), 0, e(r2))
							* spread of this horizon's regressand, the scale a coefficient is judged against
							local pscale = sqrt(e(tss)/(e(N)-1))
							local pprb = _b[dtreat]
							mat P[`i',7] = e(N)
							if _b[dtreat]==0 & _se[dtreat]==0 {
								local pid = 0
								foreach c in `: colnames e(b)' {
									if "`c'"=="dtreat" local pid = 1
								}
							}
						}

						* zero by construction: the controls alone span the pooled outcome
						if `ylagctl' & "`horizon'"=="pre" & `pid' & `pr2' > 1 - `neuttol' & ///
							abs(`pprb') < 1e-8*`pscale' {
							cap quietly reghdfe pooled_y `rhs' ///
								if `ccc'==1 & `touse' & `raok'==1 `ra_reweight_pooled', ///
								absorb(`fixed_effects') nosample
							if _rc==0 & !missing(e(r2)) local pneut = (e(r2) > 1 - `neuttol')
							* the coefficient is zero whether or not listreg could return it
							if `pneut' {
								mat P[`i',1] = 0
								mat P[`i',2] = .
							}
						}
					}

					if `pid' {
						if `rcra'==0 {
							local nfit = `nfit' + 1
							mat P[`i',1] = cond(`pneut', 0, `prtab'[1,1])
							mat P[`i',2] = `prtab'[2,1]
							mat P[`i',3] = round(`prtab'[3,1],0.01)
							mat P[`i',4] = round(`prtab'[4,1],0.0001)
							mat P[`i',5] = `prtab'[5,1]
							mat P[`i',6] = `prtab'[6,1]
							mat P[`i',7] = `praNobs'
						}
						else if `rcra'==504 { // deterministic outcome: SE not obtainable, but point estimate is
							quietly cap listreg pooled_y = dtreat if `ccc'==1 & `touse' & `raok'==1 `ra_reweight_pooled', controls(`rhs') normal vce(cluster `cluster') nose
							if _rc==0 {
								local nfit = `nfit' + 1
								mat P[`i',1] = cond(`pneut', 0, r(table)[1,1])
								mat P[`i',2] = 0
								mat P[`i',3] = .
								mat P[`i',4] = .
								mat P[`i',5] = .
								mat P[`i',6] = .
								mat P[`i',7] = e(N)
							}
						}
						else if !`pneut' {
							* a fit fails either for want of rows or for want of variation
							qui count if `ccc'==1 & `touse' & `raok'==1 & !missing(pooled_y)
							if r(N) > 0 local nodegen "`nodegen' `rlab'"
							else local nofit "`nofit' `rlab'"
						}
					}
				}
				if "`bootstrap'"!="" {
					quietly cap reg pooled_y i.dtreat##(`rhs_margins') if `ccc'==1 & `touse' & `raok'==1 `ra_reweight_pooled', vce(cluster `cluster')
					local rcra = _rc
					local pr2 = cond(`rcra'==0 & !missing(e(r2)), e(r2), 0)

					* the interacted fit drops the whole treated branch when it cannot
					* identify it; the level surviving under its own name is the test
					if `rcra'==0 {
						mat P[`i',7] = e(N)
						local pid = 0
						foreach c in `: colnames e(b)' {
							if "`c'"=="1.dtreat" local pid = 1
						}
					}
					local rcmg = 1
					local pmgb = .
					if `rcra'==0 & `pid' {
						quietly cap margins r.dtreat if `ccc'==1 & `touse' & `raok'==1 `ra_reweight_pooled', subpop(dtreat)
						local rcmg = _rc
						if `rcmg'==0 local pmgb = r(table)[1,1]
					}
					* a contrast the estimator could not deliver is not an estimate of zero
					if `rcmg'==0 & !missing(`pmgb') {
						local nfit = `nfit' + 1
						mat P[`i',1] = `pmgb'
						cap quietly boottest, reps(`bootstrap') ///
							nograph bootcluster(`cluster') level(`level') ///
							margins
						local rcbt = _rc
						mat P[`i',2] = .
						* the point estimate stands whether or not the bootstrap ran
						if `rcbt'==0 {
							mat P[`i',3] = round(r(t),0.01)
							mat P[`i',4] = round(r(p),0.0001)
							local bslab = cond(`i'==1, "Pre", "Post")
							local bsncall = `bsncall' + 1
							if r(reps) < `bootstrap' {
								local bsnwarn = `bsnwarn' + 1
								local bsdraws "`bsdraws' `bslab'(`=r(reps)' reps)"
								if r(reps) < `bsrepmin' local bsrepmin = r(reps)
								if r(reps) > `bsrepmax' | `bsrepmax'>=. local bsrepmax = r(reps)
							}
							cap matrix drop `btci'
							cap matrix `btci' = r(CI)
							if _rc==0 {
								if colsof(`btci')>=2 {
									mat P[`i',5] = `btci'[1,1]
									mat P[`i',6] = `btci'[1,2]
								}
							}
						}
					}

					* zero by construction: the controls alone span the outcome
					if `ylagctl' & "`horizon'"=="pre" & `pid' & `pr2' > 1 - `neuttol' {
						local paux = .
						cap quietly reg pooled_y dtreat `rhs_margins' ///
							if `ccc'==1 & `touse' & `raok'==1 `ra_reweight_pooled'
						if _rc==0 {
							local paux = _b[dtreat]
							local pscale = sqrt((e(mss)+e(rss))/(e(N)-1))
						}
						if abs(`paux') < 1e-8*`pscale' {
							cap quietly reg pooled_y `rhs_margins' ///
								if `ccc'==1 & `touse' & `raok'==1 `ra_reweight_pooled'
							if _rc==0 & !missing(e(r2)) local pneut = (e(r2) > 1 - `neuttol')
							* the coefficient is zero whether or not margins could return it
							if `pneut' & (`rcmg'!=0 | missing(`pmgb')) {
								mat P[`i',1] = 0
								mat P[`i',2] = .
							}
						}
					}

					* a fit that produced no usable contrast, and is not zero by construction
					if (`rcmg'!=0 | missing(`pmgb')) & `pid' & !`pneut' {
						* a fit fails either for want of rows or for want of variation
						qui count if `ccc'==1 & `touse' & `raok'==1 & !missing(pooled_y)
						if r(N) > 0 local nodegen "`nodegen' `rlab'"
						else local nofit "`nofit' `rlab'"
					}
				}
			}

			* as in the event study: an unidentified coefficient is reported missing
			* rather than as a zero measured without error
			local plab = cond("`horizon'"=="pre", "Pre", "Post")
			if !`pid' {
				forvalues jj = 1/6 {
					mat P[`i',`jj'] = .
				}
				local noid "`noid' pooled_`plab'"
			}
			if `pneut' local pneutlist "`pneutlist' `plab'"

			* dropped one at a time: -drop- fails as a unit if any name is absent
			cap drop pooled_y
			cap drop aveFY
			cap drop reweight_pooled
		} // horizon 
	}		

	
	* stop if nothing at all could be estimated
	if `nfit'==0 & !("`rw_ra'"!="" & "`bootstrap'"!="") {
		di as error "None of the LP-DiD regressions could be estimated: no specification"
		di as error "had enough usable observations."

		* If the time variable never steps by 1, issue a diagnostic message
		sort `unit' `time'
		tempvar tgap
		quietly by `unit': gen double `tgap' = `time' - `time'[_n-1]
		quietly summarize `tgap' , meanonly
		if r(N) > 0 & r(min) > 1 {
			di as error "The time variable never changes by 1 between consecutive periods:"
			di as error "the smallest step found is " r(min) ". lpdid uses lags and leads of"
			di as error "one period, so every one of them is missing and no clean control"
			di as error "condition can be met."
			di as error "Recode time() to run in consecutive integers, for example with"
			di as error "  egen newtime = group(`time')"
		}
		else {
			di as error "This usually means the outcome is missing too often, or the requested"
			di as error "windows are too wide for the length of the panel."
			if "`nocomp'"=="" {
				di as error "Consider trying a shorter pre_window() or post_window()."
			}
			else {
				di as error "Consider trying a shorter pre_window() or post_window(), or"
				di as error "deselecting the nocomp option."
			}
			if "`rw_ra'"=="" {
				di as error "It can also mean that reghdfe is not working. Check by running"
				di as error "reghdfe directly on your data."
			}
			else {
				di as error "It can also mean that listreg is not working. Check by running"
				di as error "listreg directly on your data."
			}
		}
		exit 2001
	}

	** graphical output 
	if "`only_pooled'"=="" & "`nograph'"!="nograph"{
		if "`debug'"!="" di "Make event study graph"	
		clear
		quietly svmat J
		quietly gen time = _n - (`pre_window' + 1)
		quietly twoway  (scatter J1 time, mc(navy)) ///
				(rcap J5 J6 time, color(navy)) ///
				(connect J1 time, lc(maroon) lpattern(solid)), /// 
				xline(-0.5, lpattern(dash)) /// Add a dashed line at y=0
				ytitle("Coefficient")     /// Set the title for the y-axis
				xtitle("Time")            /// 
				legend(off)				///
				ylabel(#10,grid) xlabel(#10,grid) 
	}
	
	
	** return matrices and scalars in e()
	if "`debug'"!="" di "Return matrices and scalars in e()"	

	if "`only_pooled'"=="" matlist J, title(LP-DiD Event Study Estimates) rowtitle(E-time)
	if `want_pooled' matlist P, title(LP-DiD Pooled Estimates)
	if `want_agg' & "`aggskip'"=="" {
		* matlist's own title() carries a leading blank line, so the bootstrap
		* form reproduces it before adding the note
		if "`bootstrap'"=="" matlist AGG, title(LP-DiD Aggregate Estimates (`agglab' in the event window))
		else {
			di as text _n "LP-DiD Aggregate Estimates (`agglab' in the event window)"
			if "`bsmismatch'"=="" & "`bsnoest'"=="" di as text "t-statistics, p-value and confidence interval using wild bootstrap (`bootstrap' repetitions)"
			matlist AGG
		}
	}
	if `want_agg' & "`bsnoest'"!="" {
		di as text _n "Note: only the point estimate is reported for the aggregate average."
		di as text "      The stacked regression used for wild bootstrap inference could not form"
		di as text "      the contrast at:" as result "`bsnoest'"
		di as text "      It is not estimable in that specification, so no standard error, p-value"
		di as text "      or confidence interval is reported."
	}
	if `want_agg' & "`bsmismatch'"!="" {
		di as text _n "Note: only the point estimate is reported for the aggregate average."
		di as text "      An internal consistency check failed at these horizons:" as result "`bsmismatch'"
		di as text "      The stacked regression used for wild bootstrap inference did not"
		di as text "      reproduce their event study coefficients, so no standard error,"
		di as text "      p-value or confidence interval is reported."
	}
	if `want_agg' {
		foreach hz in post pre {
			if "`aggmiss_`hz''"!="" {
				di as text _n "Note: the `hz'-treatment aggregate average was not computed."
				di as text "      These horizons have no usable estimate:" as result "`aggmiss_`hz''"
				di as text "      Averaging over the rest would report a different quantity"
				di as text "      under the same name, so nothing is reported."
			}
		}
	}

	* horizons that are zero by construction stay in the pre-window average, but
	* the reader should know the average covers a window that includes them
	local aggneut = 0
	local neutsaid = 0	// whether another note already names the mechanical zeros
	if `want_agg' & "`neutlist'"!="" {
		if `aggrow_pre' > 0 local aggneut = 1
	}
	if `aggneut' {
		local neutsaid = 1
		di as text _n "Note: the pre-treatment aggregate average includes horizons whose coefficient is"
		di as text "      zero by construction because you specified " as result "`ylagsrc'" as text ":" as result "`neutlist'" as text "."
		di as text "      Including them rescales the estimate and its standard error by the same"
		di as text "      factor, so the t-statistic is unchanged."
		if "`pneutlist'"!="" {
			di as text "      The pooled" as result "`pneutlist'" as text " estimate is zero by construction for the same reason."
		}
	}
	if "`pneutlist'"!="" & !`aggneut' {
		di as text _n "Note: the pooled" as result "`pneutlist'" as text " estimate is zero by construction because you"
		di as text "      specified " as result "`ylagsrc'" as text ": every horizon in its window is mechanically zero."
	}

	if `want_pt' {
		local ptavail = cond("`bootstrap'"!="", `bspt', `ptP')
		if "`bootstrap'"!="" & "`rw_ra'"!="" {
			di as text _n "Note: the pre-trend test is not available for specifications that use bootstrap()"
			di as text "      for wild bootstrap in combination with rw and controls(), ylags() or"
			di as text "      dylags(). Given your specification, you could obtain a pre-trend test"
			di as text "      either through the analytical route (ie, dropping the bootstrap() option)"
			di as text "      or for a variance-weighted effect (ie, dropping the rw option), if that is"
			di as text "      appropriate in your setting."
		}
		else if "`bsnoest'"!="" {
			di as text _n "Note: the pre-trend test could not be computed."
			di as text "      The stacked regression used for wild bootstrap inference could not form"
			di as text "      the contrast at:" as result "`bsnoest'"
		}
		else if "`bsmismatch'"!="" {
			di as text _n "Note: the pre-trend test could not be computed."
			di as text "      An internal consistency check failed at these horizons:" as result "`bsmismatch'"
			di as text "      The stacked regression used for wild bootstrap inference did not"
			di as text "      reproduce their event study coefficients."
		}
		else if `ptavail'==0 & !`ptdone' {
			di as text _n "Note: the pre-trend test could not be computed: no pre-treatment horizon"
			di as text "      has a usable estimate."
		}
		else if "`ptrank'"!="" | !`ptdone' {
			di as text _n "Note: the pre-trend test could not be computed: the covariance matrix across"
			if `ptdf' >= `ptM' {
				di as text "      pre-treatment horizons is singular. The test needs more clusters than"
				di as text "      coefficients, and you have " as result `ptM' as text " clusters against " as result `ptdf' as text " coefficients."
			}
			else {
				di as text "      pre-treatment horizons is singular, so it cannot be inverted."
			}
		}
		else {
			di as text _n "Pre-trend test (H0: all pre-treatment coefficients are zero)"
			if "`bootstrap'"!="" {
				di as text "      wild bootstrap, " as result `bootstrap' as text " replications, " ///
					as result `ptdf' as text " restrictions" ///
					as text "     p-value = " as result %6.4f scalar(`ptp')
			}
			else {
				di as text "      F(" as result `ptdf' as text ", " as result `=`ptM'-1' as text ") = " as result %8.4f scalar(`ptF') ///
				   as text "     p-value = " as result %6.4f scalar(`ptp')
			}
			if "`ptmiss'"!="" {
				di as text "      Note: these horizons have no usable estimate and are excluded:" as result "`ptmiss'"
				di as text "      The test is therefore a joint test on the remaining horizons, not on"
				di as text "      the full pre window."
			}
			if "`neutlist'"!="" {
				local neutsaid = 1
				local neutverb = cond(`: word count `neutlist''==1, "is", "are")
				local neutpron = cond(`: word count `neutlist''==1, "it carries", "they carry")
				di as text "      Note:" as result "`neutlist'" as text " `neutverb' zero by construction because you specified"
				di as text "            " as result "`ylagsrc'" as text ", so `neutpron' no information and the test"
				di as text "            uses " as result `ptdf' as text " degrees of freedom."
			}
		}
	}

	* the mechanical zeros, where no other note has already named them
	if "`neutlist'"!="" & !`neutsaid' {
		local neutverb = cond(`: word count `neutlist''==1, "is", "are")
		di as text _n "Note:" as result "`neutlist'" as text " `neutverb' zero by construction because you specified"
		di as text "      " as result "`ylagsrc'" as text "."
	}

	* the wild bootstrap fell back on enumerating the whole Rademacher universe
	if `bsnwarn' > 0 {
		if `bsnwarn'==`bsncall' & `bsrepmin'==`bsrepmax' {
			di as text _n "Note: the wild bootstrap used " as result `bsrepmin' as text " replications, not the " ///
				as result `bootstrap' as text " requested. With this number of"
			di as text "      clusters the Rademacher weights admit only 2^" ///
				as result `=round(log(`bsrepmin')/log(2))' as text " = " as result `bsrepmin' ///
				as text " distinct draws, so all of them were"
			di as text "      enumerated. Every p-value above is a multiple of 1/" ///
				as result `bsrepmin' as text " = " as result %6.4f 1/`bsrepmin' as text ", and confidence"
			di as text "      intervals are correspondingly coarse."
		}
		else {
			di as text _n "Note: the wild bootstrap used fewer replications than the " ///
				as result `bootstrap' as text " requested at these"
			di as text "      estimates, because with this number of clusters the Rademacher"
			di as text "      weights admit fewer distinct draws:" as result "`bsdraws'"
			di as text "      Their p-values are multiples of 1 over the replications shown, and"
			di as text "      their confidence intervals are correspondingly coarse."
		}
	}

	* report coefficients the estimator could not identify
	if "`noid'"!="" {
		di as text _n "Note: these horizons have no identifying variation, so their coefficient is not"
		di as text "      estimable and is reported as missing:" as result "`noid'"
	}

	* report rows whose regression had observations but nothing to fit
	if "`nodegen'"!="" {
		di as text _n "Note: the following estimates could not be computed and are reported"
		di as text "      as missing above:" as result "`nodegen'"
		di as text "      Each is a regression that had usable observations but could not be"
		di as text "      fitted, because nothing was left to fit once the fixed effects and any"
		di as text "      controls were partialled out. This normally means the data carry no"
		di as text "      residual variation at that horizon."
	}

	* report anything that could not be estimated
	if "`nofit'"!="" {
		di as text _n "Note: the following estimates could not be computed and are reported"
		di as text "      as missing above:" as result "`nofit'"
		di as text "      Each is a regression that was left with no usable observations,"
		di as text "      because the horizon falls outside the panel or the outcome is too"
		di as text "      often missing over the window it requires."
		if `want_pooled' {
			di as text "      The pooled estimates are the most demanding, since they need an"
			di as text "      unbroken stretch of the outcome across the whole window."
			di as text "      Options: omit pooled, a narrower pre_pooled() or post_pooled(),"
			di as text "      or a shorter pre_window() or post_window()."
		}
		else {
			di as text "      Options: a shorter pre_window() or post_window()."
		}
	}


	ereturn clear 	
	if "`only_pooled'"=="" {
		matrix colnames J = coefficient se `statlab' p ci_low ci_high obs
		ereturn matrix results = J
	}
	if `want_pooled' {
		matrix colnames P = coefficient se `statlab' p ci_low ci_high obs
		ereturn matrix pooled_results = P
	}
	if `want_agg' & "`aggskip'"=="" {
		matrix colnames AGG = coefficient se t p ci_low ci_high obs
		ereturn matrix aggregate = AGG
	}

	if `want_pt' & `ptdone' {
		ereturn scalar pretrend_F    = scalar(`ptF')
		ereturn scalar pretrend_df   = `ptdf'
		ereturn scalar pretrend_df_r = `ptM'-1
		ereturn scalar pretrend_p    = scalar(`ptp')
	}

	* verification hook for the influence functions
	if `want_ifchk' {
		if "`rw_ra'"=="" matrix colnames IFCHK = reghdfe_se if_se
		if "`rw_ra'"!="" matrix colnames IFCHK = listreg_se if_se
		ereturn matrix if_check = IFCHK
	}

	* option and sample descriptors
	ereturn local cmdline = "`cmdline'"
	ereturn local lpdid = "lpdid"
	ereturn local depvar = "`depvar'"
	if "`controls'"!="" 	ereturn local controls = "`controls'"
	if "`ylags'"!="" 		ereturn scalar ylags = `ylags'
	if "`dylags'"!="" 		ereturn scalar dylags = `dylags'
	if "`absorb'"!="" 		ereturn local absorb = "`absorb'"
	if "`pre_window'"!="" 	ereturn scalar pre_window = `pre_window'
	if "`post_window'"!="" 	ereturn scalar post_window = `post_window'
	if "`nevertreated'"=="" & ("`nonabsorbing'"=="" | "`nonabsorbing'"!="" & "`notyet'"!="") ereturn local control_group = "Not yet treated units"
	if "`nevertreated'"!="" ereturn local control_group = "Never treated units"
	if "`nevertreated'"=="" & "`nonabsorbing'"!="" & "`notyet'"=="" ereturn local control_group "Units with no change in treatment status between t-`L' and t+h"
	if ("`nonabsorbing'"=="" | "`nonabsorbing'"!="" & "`firsttreat'"=="") ereturn local treated_group  = "Units entering treatment"
	if ("`nonabsorbing'"!="" & "`firsttreat'"!="") ereturn local treated_group  = "Units entering treatment for the first time"
	
	restore 	
	
end

*************************************************************************
*** 	Auxiliary program to parse suboptions of NONABSorbing() 	  ***
*************************************************************************
cap prog drop parse_nonabsorb
program parse_nonabsorb , sclass 
	version 13
	
	syntax [anything(id="integer")] , [NOTYet] [FIRSTtreat] [oneoff]
	
	* test input 
	if "`anything'"!="" {
		cap confirm integer number `anything'
		if _rc{ // integer test 
			di as error "wrong input in nonabsorbing(#): # has to be an integer."
			error 198 
		}
	}
		
	* output 
	if "`anything'"!="" sreturn local clean `anything'
	sreturn local notyet `notyet'	
	sreturn local firsttreat `firsttreat'
	sreturn local oneoff `oneoff'

end 

*************************************************************************
***     Auxiliary program to build the rw reweighting factor          ***
*************************************************************************
cap prog drop _lpdid_rw
program define _lpdid_rw
	version 13

	syntax , DTr(varname) Time(varname) TOUse(varname) ///
			 CCs(varname) OUTcome(varname) GENerate(name) ///
			 [Wname(varname) CLuster(varname) DEBug]

	tempvar samp wt sw_treated sw_untreated

	quietly gen byte `samp' = (`ccs'==1 & `touse' & !missing(`outcome'))
	quietly markout `samp' `cluster' `wname' , strok

	if "`wname'"=="" 	quietly gen double `wt' = 1 		if `samp'
	else 				quietly gen double `wt' = `wname' 	if `samp'

	* accumulated separately rather than one by subtraction from the other: each
	* is a sum of non-negative terms, so an empty side sums to exactly zero and
	* the tests below hold whatever order egen accumulates in
	quietly egen double `sw_treated'   = total(`wt'*`dtr')     if `samp', by(`time')
	quietly egen double `sw_untreated' = total(`wt'*(1-`dtr')) if `samp', by(`time')

	* a cell with no treated weight, or with no control, identifies nothing
	quietly gen double `generate' = `wt'*(`sw_treated'+`sw_untreated')/`sw_untreated' ///
		if `samp' & `sw_treated'>0 & `sw_untreated'>0

	if "`debug'"!="" {
		quietly su `generate' , meanonly
		di "  `generate': `r(N)' obs weighted, max weight `r(max)'"
	}

end


*************************************************************************
***     Auxiliary program to perform pretrend_test                    ***
*************************************************************************
capture mata: mata drop lpdid_pretrend()
mata:
void lpdid_pretrend(string scalar vars, string scalar cnt, string scalar bstr,
                    real scalar M, string scalar Fnm, string scalar pnm)
{
	real matrix X, Z, V
	real colvector cc, b
	real scalar P, W

	X = st_data(., tokens(vars))
	cc = st_data(., cnt)
	b  = strtoreal(tokens(bstr))'
	P  = cols(X)
	Z  = X :/ sqrt(cc)
	V  = quadcross(Z, Z)

	st_local("ptdf", strofreal(P, "%12.0f"))
	st_local("ptM",  strofreal(M, "%12.0f"))

	if (rank(V) < P | M < P+1) {
		st_local("ptrank", "singular")
		return
	}
	W = b' * invsym(V) * b
	st_numscalar(Fnm, W/P)
	st_numscalar(pnm, Ftail(P, M-1, W/P))
	st_local("ptdone", "1")
}
end
