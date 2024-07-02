* lpdid program, version 1.0.1

* Authors: Alexander Busch (Massachusetts Institute of Technology, abusch@mit.edu) and Daniele Girardi (King's College London, daniele.girardi@kcl.ac.uk), in collaboration with Arin Dube, Oscar Jordà and Alan M. Taylor

* Implementing Local Projections Difference-in-Differences (LP-DiD) as described in Dube, Girardi, Jordà, and Taylor (2023) "A Local Projections Approach to Difference-in-Differences", NBER Working Paper 31184, DOI 10.3386/w31184

* Also see the Stata example files at the following repository
* https://github.com/danielegirardi/lpdid/

* Version 1.0.1 (July 2024): Added absorb() option for additional absorbed fixed effects. Now allows stata prefixes (including time-series operators) in the arguments of the controls() option. Now allows weights in the standard Stata format [pweight=weight]. 
* Version 1.0.0 (Nov 2023): First release.

********************
*** Main program ***
********************
cap prog drop lpdid 
program define lpdid, eclass

	version 13 // the packages require stata 13 (boottest)

	* CHECK : check dependency 
	foreach package in "boottest" "_gclsst" "reghdfe"{ // _gclsst as placeholder for egenmore, which is a wrapper for many ado files but has no ado file called "egenmore" which could be found via "which" 
		capture quietly which `package'
		if _rc{
			if "`package'"=="_gclsst" local package egenmore 
			di as error "Please install `package' from the scc as this is required for the lpdid package."
			error 198 
		}
	}
	
	if "`debug'"!="" di "Syntax"

	syntax varlist(max=1) [if] [in] [pweight/], 			/// dependent variable with optional [if] / [in] / [pweight] (the / after aweight ensures that the weightname `exp' is parsed as weight name only instead of "=weight_name")
			time(varname) 								/// time or time-equivalent in DiD
			unit(varname) 								/// DiD unit (also cluster unit for SEs, unless otherwise selected by the user)
			treat(varname) 								/// treatment indicator  
			[controls(string)]							/// control variables, may include Stata notation like "l.varname" or "varname##i.varname2" 
			[PRE_window(numlist min=1 max=1 >1)] 						/// pre-periods of event study 
			[POST_window(numlist min=1 max=1 >=0)] 						/// post-periods 
			[YLags(numlist >=1 int)] 					/// lags of dependent variable on RHS 
			[DYLags(numlist >=1 int)] 					/// lags of first-differenced dependent variable on RHS	
			[NONABSorbing(string)] 						/// non-absorbing treatment; string of the format "[L(integer)] , [notyet] [firsttreat]"; integer L states how many periods after treatment the effect is assumed to stabilise and is necessary; "notyet" suboption sets control group to only not-yet-treated; "firsttreat" suboption sets treatment group to only first time treatment
			[NEVERtreated] 								/// only use never treated observations as control units; default is to use all allowed observations
			[NOCOmp] 									/// rule out composition changes in treatment window; default is to use all allowed observations
			[Level(numlist min=1 max=1 >0 <100)] 		/// level for CI; default 95 (corresponds to p < 0.05)	
			[rw] 										/// if used, reweighting or regression adjustment is applied, to estimate an equally weighted ATE
			[pmd(string)] 								/// if used, the pre-mean-differenced (PMD) version of LP-DiD is estimated; the option argument indicates how many periods are used to compose the pre-treatment baseline; default is "max" if absorbing treatment; default is "L" = k if nonabsorbing treatment, unless firsttreat & (notyet | nevertreated) are selected; if instead of "max" an integer k is specified, pmd is interpreted as a moving average over [-k,-1]
			[NOgraph] 									/// no graphical output; default is to produce the graphical output 
			[BOOTstrap(numlist min=1 max=1 >0)] 		/// if used, wild bootstrap with `reps' reps; default not bootstrapped  
			[seed(numlist min=1 max=1)]					/// Set seed (relevant for wild bootstrap SEs); default no seed
			[post_pooled(numlist min=1 max=2 >=0)] 						/// interval to estimate pooled effect; if only one number, it is assumed to be the lower end of the interval; default is [0, post_window]
			[pre_pooled(numlist min=1 max=2 >1)] 						/// interval to estimate pooled pre-treatment "effect"; entered in reverse and without minus sign; for example [3 10] for the interval [-10,-3]; if only one number given it is assumed to be the upper end of the interval; default is [pre_window, -2] (as -1 is reference)
			[only_pooled] 								/// skip event study and only calculate pooled 
			[only_event] 								/// skip pooled spec and only calculate event study
			[cluster(varname)]							/// cluster for SEs (default is to use the variable indexing units)
			[absorb(string)] 							/// FE, always includes the time FE 
			[weights(varname)]							/// v100 way of specifying weight, keeping this to allow backward compatibility 			
			[debug] // debugging device, if turned on, display message at the start of a code section (helps localise errors)
	

	
	***	parse user input and check for illogical input 
	if "`debug'"!="" di "Parse user input"
	preserve 	
	
	* using auxiliary program defined below to parse sub-options of NONABSorbing()
	if "`nonabsorbing'"!=""{
		parse_nonabsorb `nonabsorbing' 
		if "`s(clean)'"!="" local L `s(clean)'
		local notyet `s(notyet)'			
		local firsttreat `s(firsttreat)'
	}

	* LHS variable, controls, and conditions 
	tempvar touse
	mark `touse' `if' `in'
	if (length("`if'")+length("`in'")>0){
		qui keep if `touse'
	}	
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
	if "`rw'"!="" local cmdline "`cmdline' rw"
	if "`pmd'"!="" local cmdline "`cmdline' pmd(`pmd')"
	if "`bootstrap'"!="" local cmdline "`cmdline' bootstrap(`bootstrap')"
	if "`controls'"!="" local cmdline "`cmdline' controls(`controls')"
	if "`seed'"!="" local cmdline "`cmdline' seed(`seed')"
	if "`post_pooled'"!="" local cmdline "`cmdline' post_pooled(`post_pooled')"
	if "`pre_pooled'"!="" local cmdline "`cmdline' pre_pooled(`pre_pooled')"
	if "`minobs'"!="" local cmdline "`cmdline' minobs(`minobs')"
	if "`level'"!="" local cmdline "`cmdline' level(`level')"
	if "`nograph'"!="" local cmdline "`cmdline' nograph"
	if "`only_pooled'"!="" local cmdline "`cmdline' only_pooled"
	if "`only_event'"!="" local cmdline "`cmdline' only_event"	
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
		di as error "It looks like your treatment variable is non-binary. It is indeed possible to apply the LP-DiD estimator to settings with non-binary treatment (see Dube, Girardi, Jorda' and Taylor, 2023). However, unfortunately, this version of this program only covers the case of a binary (absorbing or nonabsorbing) treatment. We suggest that you write your LP-DiD specification manually instead of using this program. We are sorry and we hope to accommodate non-binary treatment in a next version soon."
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
			di as error "Wrong input: With non-absorbing treatment, you need to specify the integer L, which indicates after how many periods treatment effects are assumed to stabilise, unless you specify the firsttreat option and either notyet or nevertreated."
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
	* Determine whether regression adjustment estimator must be used + CHECK : rw bootstrap 
	if "`rw'"!="" & ( ("`nonabsorbing'"!="" & ("`firsttreat'"=="" | ("`notyet'"=="" & "`nevertreated'"==""))) | "`controls'"!="" | "`ylags'"!="" | "`dylags'"!="" | "`fixed_effects'"!="`time'"){ // note that absorb is allowed if it only details the time variable 
		local rw_ra "true" // regression adjustment necessary 
		if "`bootstrap'"!=""{
			di as error "Regression adjustment with bootstrapped standard errors has not been implemented in this version yet - we are sorry and hope to include this option soon!"
			error 198 
		}
		else if "`absorb'"!="" {
			di "Your specification requires estimation through regression adjustment, which in the current version of the program uses a lot of computational power and hence may take a while. Note that regression adjustment is especially slow when including additional fixed effects. We are sorry and will update this in a new version to deliver a faster option soon!"		
		}
		else {
			di "Your specification requires estimation through regression adjustment, which in the current version of the program uses a lot of computational power and hence may take a while. We are sorry and will update this in a new version to deliver a faster option soon!"			
		}
		fvrevar `rhs', tsonly stub(op_var) substitute // if RA must be used, then time-series and factor variables should substituted with newly created variables
		local rhs `r(varlist)' 
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
			di as error "absorb() and bootstrap() specified at the same time: Since the user written command boottest this program relies on only allows one absorbed effect and the time fixed effects is already absorbed per default, you cannot use these two options at the same time. Please specify your additional fixed effects as control variables with the 'i.' prefix in the controls() option if you require bootstrapping. The results will be identical to using absorb(), but may take longer. "
			error 198 			
		}
		foreach fe in `absorb'{ // this gets triggers if ANY fe in absorb is the time fe (it does not get triggered if the time variable name is simply a part of another varname, e.g. time(time) and absorb(time2 L5.time) does not raise the error)
			if "`fe'"=="`time'" { 
				di as error "absorb() includes the time (or time-equivalent) variable `time'; please note that lpdid always absorbs time fixed effects (otherwise it would not be a DiD!). Including time effects in the absorb() option is not necessary and does not improve runtime. "
			}
		}
	}

	
	* CHECK : names 
	* no input variable should be identical in name to a program variable 
	local input_vars `depvar' `time' `unit' `treat' `rhs' `cluster' `weight_name' `absorb'
	
	if "`debug'"!="" di "input vars: `input_vars'"
	
	fvrevar `input_vars', list // get rid of stata operators while also avoiding duplicates in the list
	local input_vars ""
	foreach word in `r(varlist)' {
	if regexm("`input_vars'", "\b`word'\b") == 0 {
			local input_vars "`input_vars' `word'"
		}
	}
		
	local program_vars cumulative_y obs_n aveLY aveLY_help max_treat never_treated past_events status_entry_help status_entry reweight CCS_nocomp_event CCS_nocomp_pooled dtreat aveFY pooled_y cc0 max_cc0
	local program_vars_dynamic1 CCS_ CCS_m nyt_  group_h num_weights_ den_weights_ gweight_ 
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
	quietly keep `input_vars'
				
	* set time / unit structure  
	quietly xtset `unit' `time'	
		
	* Set seed if indicated by the user (relevant for boottest)
	if "`seed'"!="" set seed `seed' 

	* check whether panel balanced 
	quietly spbalance 
	if `r(balanced)'==0{
		if "`pmd'"==""{
			di "Warning: Your data is not strongly balanced. Please evaluate whether this is a problem in your application or not."		
		}
		else{
			di "Warning: You selected the PMD specification but your data is not strongly balanced. Please evaluate whether this is a problem in your application or not. Note that with unbalanced data, your PMD window length might possibly differ between observations within the same event. This can introduce bias."
		}
	}
	
	* significance level for confidence intervals 
	local p = 0.05
	if "`level'"!="" local p = (100 - `level')/100
	if "`level'"=="" local level 95
	local p2 = `p'/2
	
	
	
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
	
	* Non-absorbing treatment 
	if "`nonabsorbing'"!="" & !("`firsttreat'"!="" & ("`notyet'"!="" | "`nevertreated'"!="")){ // if treatment is nonabsorbing, check whether the unit is contaminated by previous/future switches (don't execute if "pseudo-absorbing" case)
		quietly gen CCS_0 = 0
		local string "(D.`treat'==1 | D.`treat'==0) & abs(L.D.`treat')!=1"
		forvalues k=2/`L'{ 
			local string = "`string' & abs(L`k'.D.`treat')!=1"
		}
		quietly replace CCS_0 = 1 if `string'		
		forvalues h = 1/`post_CCS'{ // clean window at least up until period t+h 
			quietly gen CCS_`h' = 0
			local i = `h' - 1		
			quietly replace CCS_`h' = 1 if CCS_`i'==1 & abs(F`h'.D.`treat')!=1
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
		quietly by `unit': gen past_events = sum(abs(D.`treat'))		
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


	
	*** If regression adjustment must be used, drop observations for time periods where there are no clean controls (otherwise the teffects ra command will not work properly)
	if "`rw'"!="" & "`rw_ra'"!="" {
		qui gen 	cc0=CCS_0 	if D.`treat'==0
		qui replace cc0=0 		if D.`treat'==1
		qui bysort `time': egen max_cc0= max(cc0)
		qui drop if max_cc0==0
		qui drop cc0 max_cc0
		qui xtset `unit' `time'	
	}
	
	
	
	*** Generate long differences to be used on the LHS of the LP-DiD regressions
	if "`debug'"!="" di "Generate long differences"
	
	if "`pmd'"=="" { // if PMD not selected, classical LP long difference  
		forval h = 0/`post_window' { 
			quietly gen D`h'y = F`h'.`depvar' - L.`depvar'
		}
		forval h = 2/`pre_window' {
			quietly gen Dm`h'y = L`h'.`depvar' - L.`depvar'
		}		
	}
	else if "`pmd'"=="max" { // if PMD selected with the max option, do PMD with all available pre-treatment observations
		quietly bysort `unit' (`time') : gen cumulative_y = sum(`depvar')
		quietly bysort `unit' (`time') : gen obs_n = _n
		quietly gen aveLY = L.cumulative_y/(obs_n-1)
		forval h = 0/`post_window' {
			quietly gen D`h'y = F`h'.`depvar' - aveLY
		}
		forval h = 2/`pre_window' {
			quietly gen Dm`h'y = L`h'.`depvar' - aveLY
		}		
		quietly drop obs_n		
	}
	else if "`pmd'"!="max" & "`pmd'"!=""{ // moving average of periods [-k,-1] 		
		qui egen aveLY =  filter(`depvar'), lags(`pmd'/1) normalize // requires egenmore
		if "`nonabsorbing'"!=""{ // set to missing if any of the MA values affected by previous treatment 
			local pmd_L = `pmd' + `L' - 1
			forvalues k=1/`pmd_L'{
				quietly by `unit': replace aveLY = . if abs(L`k'.D.`treat')!=1
			}
		}
		forval h = 0/`post_window' {
			quietly gen D`h'y = F`h'.`depvar' - aveLY
		}
		forval h = 2/`pre_window' {
			quietly gen Dm`h'y = L`h'.`depvar' - aveLY
		}		
	}
	
	

	*** Compute and store weights if appropriate
	if "`debug'"!="" di "Compute and store weights"
	
	local post_leads = max(`post_window',`post_pooled_end') // need weights for as many leads as specified
    if "`rw'"!="" & "`rw_ra'"=="" { // if rw selected and RA not necessary to do reweighting, compute weights (to be then used in weighted regression)
		if "`nocomp'"=="" {	// if we aren't ruling out composition effects, weights might be different across time horizons
			forval h = 0/`post_leads' {
				quietly gen group_h`h'=.
				quietly replace group_h`h'=`time' if CCS_`h'==1
				quietly reghdfe D.`treat' if CCS_`h'==1, absorb(`time') residuals(num_weights_`h')
				quietly replace num_weights_`h'=. if D.`treat'!=1
				quietly egen den_weights_`h' = total(num_weights_`h')
				quietly gen weight_`h' = num_weights_`h'/den_weights_`h'
				quietly bysort group_h`h': egen gweight_`h'=max(weight_`h')
				quietly replace weight_`h'=gweight_`h' if weight_`h'==.
				quietly replace weight_`h'=round(weight_`h',0.00000001)
				quietly gen reweight_`h'=1/weight_`h'
				quietly sort `unit' `time'
				if "`weight_name'"!="" quietly replace reweight_`h' = reweight_`h' * `weight_name'
			}
		}
		else if "`nocomp'"!="" { // if ruling out composition effects, weights are the same across all time horizons
			quietly gen group=.
			quietly replace group=`time' if CCS_nocomp_event==1
			quietly reghdfe D.`treat' if CCS_nocomp_event==1, absorb(`time') residuals(num_weights)
			quietly replace num_weights=. if D.`treat'!=1
			quietly egen den_weights = total(num_weights)
			quietly gen weight_num_den = num_weights/den_weights
			quietly bysort group: egen gweight=max(weight_num_den)
			quietly replace weight_num_den=gweight if weight_num_den==.
			quietly replace weight_num_den=round(weight_num_den,0.00000001)
			quietly gen reweight=1/weight_num_den
			if "`weight_name'"!="" quietly replace reweight = reweight * `weight_name'
			quietly sort `unit' `time'				
		}
	}
	else if "`rw'"=="" { // no weights, just assign an equal weight to each observation	
		if "`nocomp'"!="" {
			qui gen reweight = 1
			if "`weight_name'"!="" quietly replace reweight = `weight_name'
		}
		else if "`nocomp'"=="" {
			forvalues j=0/`post_leads'{
				quietly gen reweight_`j' = 1
				if "`weight_name'"!="" quietly replace reweight_`j' = `weight_name'
			}
		}
	}
	else if "`rw'"!="" & "`rw_ra'"!=""{ 		// variables for regression adjustment 
		quietly gen dtreat=D.`treat'
		quietly replace dtreat=. if dtreat==-1  // only matters with nonabsorbing treatment 
		local fe ""
		local addfe_n = 0
		foreach add_fe in `fixed_effects' {
			local addfe_n = `addfe_n' + 1 
			quietly tab `add_fe', gen(dum`addfe_n'_)
			quietly drop dum`addfe_n'_1
			local fe `fe' dum`addfe_n'_*
		}
		if "`weight_name'"!="" local `ra_reweight' "[pweight=`weight_name']"
	}
	
	
	
	*** Estimate LP-DiD regressions
	if "`debug'"!="" di "Estimate LP-DiD regressions"	
	
	if "`cluster'"=="" local cluster `unit'
	

	** Event study regressions
	if "`debug'"!="" di "Event study regressions"	

	if "`only_pooled'"=="" {
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
		matrix colnames J = "Coefficient" "SE" "t" "P>|t|" "[`level'% conf." "interval]" "obs"
		matrix rownames J = "`rows'"
		
		if "`no_pre'"!="" local pre_window = 1 // set to 1 to allow empty reference period = -1 in matrix 
				
		* run LP-DiD regressions
		local max_window = max(`post_window',`pre_window') 	
		forval h = 0/`max_window' {
			foreach horizon in `horizons'{
				if ("`horizon'"=="post" & `h'>`post_window') | ("`horizon'"=="pre" & (`h'<=1 | `h'>`pre_window')){
					continue 
				}
				if  "`nocomp'"!="" {
					local reweight "reweight"
					local ccc "CCS_nocomp_event" 
				}
				if "`nocomp'"=="" {
					if "`horizon'"=="pre" local reweight "reweight_0"		// Note: this is OK because if we use reweighting (rather than RA) to get the ATE, it means treatment is absorbing or pseudo-absorbing
					if "`horizon'"=="post" local reweight "reweight_`h'"
					if "`horizon'"=="post" local ccc CCS_`h'
					if "`horizon'"=="pre"  local ccc CCS_m`h'
				}
				if "`horizon'"=="pre"  local D "Dm"				
				if "`horizon'"=="post" local D "D"
				if "`horizon'"=="post" local i = `pre_window' + `h' + 1
				if "`horizon'"=="pre"  local i = `pre_window' - `h' + 1			
				if "`rw_ra'"=="" {
					quietly reghdfe `D'`h'y  								///
							D.`treat' `rhs'   			 					///   	treatment indicator + any covariates
							if `ccc'==1  									/// 	clean controls condition
							[pweight=`reweight'],	 						/// 	get equally-weighted ATT if specified
							absorb(`fixed_effects') vce(cluster `cluster')	// 		time indicators + any additional absorbed FEs
							
					mat J[`i',1] = _b[D.`treat']	
					mat J[`i',7] = e(N) 
					if "`bootstrap'"!=""{
						quietly boottest D.`treat', reps(`bootstrap') ///
								nograph bootcluster(`cluster') level(`level')
						mat J[`i',2] = .
						mat J[`i',3] = round(r(t),0.01)
						mat J[`i',4] = round(r(p),0.0001)
						mat J[`i',5] = r(CI)[1,1]
						mat J[`i',6] = r(CI)[1,2]
					}		
					else{ // compute confidence intervals   
						mat J[`i',2] = _se[D.`treat'] 
						mat J[`i',3] = round(_b[D.`treat'] / _se[D.`treat'],0.01)
						mat J[`i',4] = round((2 * ttail(e(df_r), abs(_b[D.`treat'] / _se[D.`treat']))),0.0001)
						mat J[`i',5] = _b[D.`treat'] + _se[D.`treat']*invt(e(df_r), `p2')
						mat J[`i',6] = _b[D.`treat'] - _se[D.`treat']*invt(e(df_r), `p2')
					}					
				}
				else if "`rw_ra'"!="" { // using regression adjustment 
					quietly cap teffects ra (`D'`h'y  `rhs' `fe') (dtreat)	///
							if `ccc'==1 `ra_reweight', atet iterate(0) vce(cluster `cluster')
					if _rc==0 {
						mat J[`i',1] = r(table)[1,1]
						mat J[`i',2] = r(table)[2,1]
						mat J[`i',3] = round(r(table)[3,1],0.01)
						mat J[`i',4] = round(r(table)[4,1],0.0001)
						mat J[`i',5] = r(table)[5,1]
						mat J[`i',6] = r(table)[6,1] 
						mat J[`i',7] = e(N) 						
					}
					else if _rc==459 & "`horizon'"=="pre" { // This is to accommodate situations where you are controlling for outcome lags, so first pre horizons are 0 by construction, producing collinearity & error message r(459)
						mat J[`i',1] = 0
						mat J[`i',2] = 0
						mat J[`i',3] = .
						mat J[`i',4] = .
						mat J[`i',5] = .
						mat J[`i',6] = .
						mat J[`i',7] = .					
					}
				}
			}
		}		

		local i = `pre_window'
		mat J[`i',1] = 0 
						
	} 
	
	
	** Pooled estimation 
	if "`debug'"!="" di "Pooled regressions"		
	
	if "`only_event'"==""{
	
		matrix P=J(2,7,.) 
		matrix colnames P = "Coefficient" "SE" "t" "P>|t|" "[`level'% conf." "interval]" "obs"
		matrix rownames P = "Pre" "Post"
		
		local i = 0
		foreach horizon in pre post{
			local i=`i'+1 
			if "`no_`horizon''"!="" & "``horizon'_pooled'"==""{
				mat P[`i',1] = 0
				mat P[`i',2] = 0
				mat P[`i',3] = .
				mat P[`i',4] = .
				mat P[`i',5] = .
				mat P[`i',6] = .
				mat P[`i',7] = .				
				continue 
			}			
			
			* leads are marked with a "-" in filter
			if "`horizon'"=="pre" local pooled_end = `pre_pooled_end'			
			if "`horizon'"=="post" local pooled_end = -`post_pooled_end' 
			if "`horizon'"=="pre" local pooled_start = `pre_pooled_start'			
			if "`horizon'"=="post" local pooled_start = -`post_pooled_start' 
			
			* generating pooled dependent variable 
			qui egen aveFY =  filter(`depvar'), lags(`pooled_end'/`pooled_start') normalize 
			if "`pmd'"=="" { // recall aveLY was created in the previous pmd section
				qui gen pooled_y = aveFY - L.`depvar'
			}
			if "`pmd'"!="" {
				qui gen pooled_y = aveFY - aveLY
			} 
			
			* weights 
			if "`horizon'"=="pre" local ccc "CCS_m`pre_pooled_end'"			
			if "`horizon'"=="post" local ccc "CCS_`post_pooled_end'"			
			if  "`nocomp'"!="" {
				local reweight "reweight"
				local ccc "CCS_nocomp_pooled"
			}
			if "`nocomp'"=="" & "`rw_ra'"=="" {
				if "`horizon'"=="pre" local reweight "reweight_0"
				if "`horizon'"=="post" local reweight "reweight_`post_pooled_end'"
			}
			
			if "`rw_ra'"=="" {
				quietly reghdfe pooled_y  								///
						D.`treat' `rhs'   			 					///   	treatment indicator + any covariates
						if `ccc'==1  									/// 	clean controls condition
						[pweight=`reweight'],	 						/// 	get equally-weighted ATT if specified
						absorb(`fixed_effects') vce(cluster `cluster')	// 		time indicators	+ any additional absorbed FEs
				mat P[`i',1] = _b[D.`treat']
				mat P[`i',7] = e(N) 				
				if "`bootstrap'"!=""{
					quietly boottest D.`treat', reps(`bootstrap') ///
							nograph bootcluster(`cluster') level(`level')
					mat P[`i',2] = .
					mat P[`i',3] = round(r(t),0.01)
					mat P[`i',4] = round(r(p),0.0001)
					mat P[`i',5] = r(CI)[1,1]
					mat P[`i',6] = r(CI)[1,2]
				}		
				else{ // compute confidence intervals   
					mat P[`i',2] = _se[D.`treat']
					mat P[`i',3] = round(_b[D.`treat'] / _se[D.`treat'],0.01)
					mat P[`i',4] = round(2 * ttail(e(df_r), abs(_b[D.`treat'] / _se[D.`treat'])),0.0001)
					mat P[`i',5] = _b[D.`treat'] + _se[D.`treat']*invt(e(df_r), `p2')
					mat P[`i',6] = _b[D.`treat'] - _se[D.`treat']*invt(e(df_r), `p2')
				}
			}
			else if "`rw_ra'"!="" { // using regression adjustment 
				quietly cap teffects ra (pooled_y `rhs' `fe') (dtreat)	///
						if `ccc'==1 `ra_reweight', atet iterate(0) vce(cluster `cluster')
				if _rc==0 {
					mat P[`i',1] = r(table)[1,1]
					mat P[`i',2] = r(table)[2,1]
					mat P[`i',3] = round(r(table)[3,1],0.01)
					mat P[`i',4] = round(r(table)[4,1],0.0001)
					mat P[`i',5] = r(table)[5,1]
					mat P[`i',6] = r(table)[6,1]
					mat P[`i',7] = e(N) 					
				}
				else if _rc==459 & "`horizon'"=="pre" { // This is to accommodate situations where you are controlling for outcome lags, so first pre horizons are 0 by construction, producing collinearity & error message r(459)
					mat P[`i',1] = 0
					mat P[`i',2] = 0
					mat P[`i',3] = .
					mat P[`i',4] = .
					mat P[`i',5] = .
					mat P[`i',6] = .
					mat P[`i',7] = .					
				}
			}			
			cap drop pooled_y aveFY 
		} // horizon 
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
	if "`only_event'"=="" matlist P, title(LP-DiD Pooled Estimates)
	
	ereturn clear 	
	if "`only_pooled'"=="" {
		matrix colnames J = coefficient se t p ci_low ci_high obs
		ereturn matrix results = J
	}
	if "`only_event'"=="" {
		matrix colnames P = coefficient se t p ci_low ci_high obs
		ereturn matrix pooled_results = P
	}

	* scalars
	ereturn local cmdline = "`cmdline'"
	ereturn local lpdid = "lpdid"
	ereturn local depvar = "`depvar'"
	if "`controls'"!="" 	ereturn local controls = "`controls'"
	if "`ylags'"!="" 		ereturn scalar ylags = `ylags'
	if "`absorb'"!="" 		ereturn local absorb = "`absorb'"
	if "`controls'"!="" 	ereturn local controls = "`controls'"	
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
	
	syntax [anything(id="integer")] , [NOTYet] [FIRSTtreat]
	
	* test input 
	if "`anything'"!="" {
		cap confirm integer number `anything'
		if _rc{ // integer test 
			di as error "L wrong input: L has to be an integer."
			error 198 
		}
	}
		
	* output 
	if "`anything'"!="" sreturn local clean `anything'
	sreturn local notyet `notyet'	
	sreturn local firsttreat `firsttreat'

end 
