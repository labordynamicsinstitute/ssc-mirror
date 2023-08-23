*! ivmediate 1.0.4  1 Dec 2020
*! authors Christian Dippel, Andreas Ferrara, Stephan Heblich

cap program drop ivmediate
program define ivmediate, eclass

	version 11.0
	
	* Program Syntax
	syntax varlist(numeric ts fv min=1 numeric) [if] [in], MEDiator(  varname min=1 max=1 numeric) 	///
														   TREATment( varname min=1 max=1 numeric) 	///
														   INSTrument(varlist min=1 max=1 numeric)	///
														   [Absorb(   varname min=1 max=1 numeric)] ///
														   [vce(string)]							///
														   [Full]									///
														   [Level(integer 95)]
	marksample touse
 	
	* mark the outcome variable
    gettoken depvar indepvars : varlist
    _fv_check_depvar `depvar'

	* mark the controls (if any)
    fvexpand `indepvars' 
	
	* mark the instrument(s)
	fvexpand `instrument'
 
	* mark estimation sample
	markout `touse' 
	
	// check that instrument(s) is/are not also in other lists
	foreach vlist in depvar indepvars treatment mediator {
		local checklist	: list instrument & `vlist'
		local checknum	: word count `checklist'
		if `checknum' {
			di as err "syntax error - cannot also use instrument `checklist' in `vlist'"
			exit 198
		}
	}
	
	// check that mediator is not also in other lists
	foreach vlist in depvar indepvars treatment {
		local checklist	: list mediator & `vlist'
		local checknum	: word count `checklist'
		if `checknum' {
			di as err "syntax error - cannot also use mediator `checklist' in `vlist'"
			exit 198
		}
	}
	
	// check that treatment variable is not also in other lists
	foreach vlist in depvar indepvars {
		local checklist	: list treatment & `vlist'
		local checknum	: word count `checklist'
		if `checknum' {
			di as err "syntax error - cannot also use treatment `checklist' in `vlist'"
			exit 198
		}
	}
	
	// check that level is specified correctly
	if `level'<10 | `level'>99 {
		di as err "level() must be between 10 and 99 inclusive"
		exit 198
	}
	
	* VCE options
	if ("`vce'"!="") {
		tempvar  `vce'
	}
	else {
		local vcetype "unadjusted"
	}
	
	_vce_parse `touse' , optlist(Robust) argoptlist(CLuster) : , vce(`vce')
    local vce        "`r(vce)'"
    local clustervar "`r(cluster)'"

	if "`vce'" == "robust" {
		tempvar clustervar
		gen `clustervar' = _n
		local vcetype "cl `clustervar'"
	}
	else if "`vce'" == "cluster" {
		local vcetype "cl `clustervar'"
	}
	
    if "`clustervar'" != "" {
		local fname "Kleibergen-Paap "
        capture confirm numeric variable `clustervar'
        if _rc {
            display in red "invalid vce() option"
            display in red "cluster variable {bf:`clustervar'} is " ///
                "string variable instead of a numeric variable"
            exit(198)
        }
        sort `clustervar'
    }
	
	*-----------------------------------------------------------------------------------------------------*
	* Apply FLW Theorem to partial out covariates
	
	* generate temp vars for each instrument
	forval z = 1(1)`: word count `instrument'' {
		tempvar zres`z'
		tempvar zres`z'YM
		local zreslist   `zreslist'   `zres`z''
		local zreslistYM `zreslistYM' `zres`z'YM'
	}
	
	* generate temp vars for outcome, treatment, mediator
	tempvar yres tres mres yresYM mresYM
	local outc   `depvar' `treatment' `instrument' `mediator'
	local tvar   `yres'   `tres'      `zreslist'   `mres'
	local tvarYM `yresYM' `tres'      `zreslistYM' `mresYM'
	
	* if no absorb var specified, set a = 1
	tempvar c
	if "`absorb'" != "" {
		gen `c' = `absorb'
	}
	else {
		gen `c' = 1
	}
	*-----------------------------------------------------------------------------------------------------*
	
	
	*-----------------------------------------------------------------------------------------------------*
	* partial out controls and absorb var
	* if no absorb var and controls are specified, partial out the intercept only
	
	tempvar treatres
	qui areg `treatment' `indepvars' if `touse', a(`c')
	qui predict double `treatres', res
	
	* param numbers for first stage F stat computation later
	local partialdof = e(N)-e(df_r)
	
	local n : word count `outc'
	qui forval i = 1(1)`n' {

		local y `: word `i' of `outc''
		local r `: word `i' of `tvar''

		* partial out controls and FE from i) outcome, ii) mediator, iii) instruments
		* also partial out T from i), ii), iii) separately for later use (marked YM)
		* this will be used in the TSLS reg of Y on M using Z as inst and controlling for T
		if `i'!=2 {
			areg `y' `indepvars' `treatres' if `touse', a(`c')

			local rYM `: word `i' of `tvarYM''
			
			predict double `rYM', res
			scalar btreat = _b[`treatres']
			
			* now add beta*Treat back in to get the residuals for the reg "areg `y' `indepvars' if `touse', a(`c')"
			* this speeds up the ado file because it avoids additional regressions
			gen `r' = `rYM' + btreat*`treatres'
		}
		
		* partial out controls and FE from the treatment variable
		else {
			areg `y' `indepvars' if `touse', a(`c')
			predict double `r', res
		}
	}
	*-----------------------------------------------------------------------------------------------------*
	
	
	*-----------------------------------------------------------------------------------------------------*
	* Run GMM command to estimate mediation effects
	qui gmm (`yres' - {xb1: `tres'}) 					///
			(`mres' - {xb2: `tres'}) 					///
			(`yres' - {xb3: `tres' `mres'}) if `touse', ///
			instruments(1: `zreslist'		) 			///
			instruments(2: `zreslist'		) 			///
			instruments(3: `zreslist' `tres') 			///
			winit(unadjusted, independent) 				///
			vce(`vcetype', independent)					///
			onestep										///
			deriv(1/xb1 = -1)							///
			deriv(2/xb2 = -1)							///
			deriv(3/xb3 = -1)
	
	local N = e(N)
	local N_clust = e(N_clust)
	*-----------------------------------------------------------------------------------------------------*
	
	*-----------------------------------------------------------------------------------------------------*
	* generate variable lengths for table alignments

	local lenD = length("`depvar'")
	local lenT = length("`treatment'")
	local lenM = length("`mediator'")
	
	local len = max(`lenD', `lenT', `lenM')
	
	
	if `len'>=15 {
	
		local addY = abs(`lenD'-`len')
		local deplen = "`depvar'"+`addY'*" "
	
		local addT = abs(`lenT'-`len')
		local treatlen = "`treatment'"+`addT'*" "
		
		local addM = abs(`lenM'-`len')
		local medlen = "`mediator'"+`addM'*" "
		
		local addTE = abs(length("total effect")-`len')
		local TElen = "total effect"+`addTE'*" "
		
		local addDE = abs(length("direct effect")-`len')
		local DElen = "direct effect"+`addDE'*" "
		
		local addIE = abs(length("indirect effect")-`len')
		local IElen = "indirect effect"+`addIE'*" "
	
	}
	
	else {
	
		local addY = abs(`lenD'-15)
		local deplen = "`depvar'"+`addY'*" "
		
		local addT = abs(`lenT'-15)
		local treatlen = "`treatment'"+`addT'*" "
		
		local addM = abs(`lenM'-15)
		local medlen = "`mediator'"+`addM'*" "
		
		local TElen = "total effect"+"   "
		local DElen = "direct effect"+"  "
		local IElen = "indirect effect"
	}
	*-----------------------------------------------------------------------------------------------------*
	
	
	*-----------------------------------------------------------------------------------------------------*
	* If full set of results is requested
	
	if "`full'"!="" {
	
		* results from y on T inst by Z			
		mat eB = e(b)
		mat eV = e(V)
		mat b1 = eB[1,1]
		mat colnames b1 = "`treatlen'"
		
		mat v1 = eV[1,1]
		mat rownames v1 = "`treatlen'"		
		mat colnames v1 = "`treatlen'"
		
		local depvar1 "`deplen'"
		
		
		* results from M on T inst by Z
		mat b2 = eB[1,2]
		mat colnames b2 = "`treatlen'"	
		
		mat v2 = eV[2,2]
		mat rownames v2 = "`treatlen'"		
		mat colnames v2 = "`treatlen'"	
	
		local depvar2 "`medlen'"
		
		
		* results from y on M (inst by Z) controlling for T
		mat b3 = J(1,2,.)	
		mat b3[1,1] = eB[1,3]
		mat b3[1,2] = eB[1,4]
		mat colnames b3 = "`treatlen'" "`medlen'"
		
		mat v3 = J(2,2,.)
		mat v3[1,1] = eV[3,3]
		mat v3[2,1] = eV[4,3]
		mat v3[1,2] = eV[4,3]
		mat v3[2,2] = eV[4,4]
		mat rownames v3 = "`treatlen'" "`medlen'"
		mat colnames v3 = "`treatlen'" "`medlen'"
		
		local depvar3 "`deplen'"
	
	}
	*-----------------------------------------------------------------------------------------------------*
	
	
	*-----------------------------------------------------------------------------------------------------*
	* Compute results for main table
	
	// mediation effect as % of total effect
	scalar ME = _b[xb2_`tres':_cons]*_b[xb3_`mres':_cons]/_b[xb1_`tres':_cons]*100
	*-----------------------------------------------------------------------------------------------------*
	
	
	*-----------------------------------------------------------------------------------------------------*
	* compute the two first stage F-statistics (inst endog with Z f-stat, and inst mediator with Z f-stat)
	
	* number of controls and FE
	local iv1_ct : word count `indepvars'
	local iv1_ct = `iv1_ct'
	
	* number of excl instruments
	local exex1_ct : word count `zreslist'
	
	
	// First stage F-stat T, inst with Z
	* rank test to compute F stats	
	qui ranktest (`tres') (`zreslist') if `touse', 	full wald				///
													cluster(`clustervar')
	local chi2_1 = r(chi2)
	

	// First stage F-stat, M inst with Z contr for T
	qui ranktest (`mres') (`zreslist') if `touse', 	full wald				///
													cluster(`clustervar')	///
													partial(`tres')
	local chi2_2 = r(chi2)
	
	* without clustering or robust s.e.
	if "`clustervar'" == "" {
		
		scalar fstat1 = `chi2_1'/`N'*(`N'-`partialdof'-`exex1_ct')/`exex1_ct'
		
		scalar fstat2 = `chi2_2'/`N'*(`N'-`partialdof'-`exex1_ct'-1)/`exex1_ct'
	}

	* if cluster or robust, compute Kleibergen-Paap F-stat
	if "`clustervar'" != "" {

		scalar fstat1 =	`chi2_1'/(`N'-1) * (`N'-`partialdof'-`exex1_ct') * (`N_clust'-1)/`N_clust' / `exex1_ct'

		scalar fstat2 =	`chi2_2'/(`N'-1) * (`N'-`partialdof'-`exex1_ct'-1) * (`N_clust'-1)/`N_clust' / `exex1_ct'
	}
	*-----------------------------------------------------------------------------------------------------*

	
	*-----------------------------------------------------------------------------------------------------*
	* Obtain total, direct, and indirect effects
	
	qui nlcom (_b[xb1_`tres':_cons])							///
			  (_b[xb3_`tres':_cons])							///
			  (_b[xb2_`tres':_cons]*_b[xb3_`mres':_cons]), post
	
	mat b = e(b)
	mat V = e(V)
	
	mat colnames b = "`TElen'" "`DElen'" "`IElen'"
	mat colnames V = "`TElen'" "`DElen'" "`IElen'"
	mat rownames V = "`TElen'" "`DElen'" "`IElen'"
	*-----------------------------------------------------------------------------------------------------*
	

	*-----------------------------------------------------------------------------------------------------*
	* display full set of results of requested
	
	if "`full'"!="" {	
		di in gr "Intermediate Output"
		di in smcl in gr "{hline 28}"
		di in gr "Effect of the treatment on the outcome"
		di in gr "IV regression of " in ye "`depvar'" in gr " on " in ye "`treatment'" in gr " (instrumented with " in ye "`instrument'" in gr ")"
		ereturn post b1 v1
		ereturn local depvar "`depvar1'"
		ereturn display, level(`level')
		di ""
		
		di in gr "Effect of the treatment on the mediator"
		di in gr "IV regression of " in ye "`mediator'" in gr " on " in ye "`treatment'" in gr " (instrumented with " in ye "`instrument'" in gr ")"
		ereturn post b2 v2
		ereturn local depvar "`depvar2'"
		ereturn display, level(`level')
		di ""
		
		di in gr "Effect of the mediator on the outcome, controlling for the treatment"
		di in gr "IV regression of " in ye "`depvar'" in gr " on " in ye "`mediator'" in gr " (instrumented with " in ye "`instrument'" in gr ") controlling for " in ye "`treatment'"
		ereturn post b3 v3
		ereturn local depvar "`depvar3'"
		ereturn display, level(`level')
		di in gr "Note: All other exogenous controls are partialled out."
		if "`vce'" == "cluster" {
			di in gr "      Standard errors clustered on `clustervar'"
		}
		if "`vce'" == "robust" {
			di in gr "      Standard errors robust to heteroscedasticity."
		}
		di ""
	}
	*-----------------------------------------------------------------------------------------------------*
	
	
	*-----------------------------------------------------------------------------------------------------*
	* report main results

	mat rownames V = _:
	mat colnames V = _:
	
	* right-align number of observations
	if `len'>=15 {
		local hl   = `len'-15+81
		local obsl = `len'-15+66-length("`N'")
		local dis  = `len'-15+58-length("`clustervar'")-length("`N_clust'")
	}
	else {
		local hl   = 81
		local obsl = 66-length("`N'")
		local dis  = 58-length("`clustervar'")-length("`N_clust'")
	}
	
	
	di in gr "Linear IV Mediation Analysis"
	di in smcl in gr "{hline 28}"
	di in gr "Outcome:" in ye _col(12) "`depvar'" _col(`obsl') in gr "Number of obs = " in ye `N'
	if "`vce'" == "cluster" {
		di in gr "Treatment:" in ye _col(12) "`treatment'" in gr _col(`dis') "Number of clusters (" "`clustervar'" ") = " in ye `N_clust'
	}
	else {
		di in gr "Treatment:" in ye _col(12) "`treatment'"
	}
	di in gr "Mediator:" in ye _col(12) "`mediator'"

	ereturn post b V, obs(`N')
	
	ereturn scalar fstat1  = fstat1
	ereturn scalar fstat2  = fstat2
	ereturn scalar mepct   = ME
	if "`vce'" == "cluster" {
		ereturn scalar N_clust = `N_clust'
		ereturn local clustvar "`clustervar'"
	}
	
	ereturn local vcetype "`vce'"
	ereturn local inst "`instrument'"
	ereturn local med "`mediator'"
	ereturn local treat "`treatment'"
	ereturn local depvar "`deplen'"
	
	ereturn display, level(`level')
	di in gr "Mediator " in ye "`mediator'" in gr " explains " in ye %3.2f e(mepct) "%" in gr " of the total effect." 
	di in gr "`fname'F-statistic for excluded instruments in"
	di in gr "- first stage one (T on Z):   " _col(31) in ye %6.3f fstat1
	di in gr "- first stage two (M on Z|T): " _col(31) in ye %6.3f fstat2
	di in gr "Excluded instruments: " in ye "`instrument'"
	if "`vce'" == "cluster" {
		di in gr "Standard errors clustered on `clustervar'"
	}
	if "`vce'" == "robust" {
		di in gr "Standard errors robust to heteroscedasticity."
	}
	di in smcl in gr "{hline `hl'}"
	ereturn local depvar "`depvar'"
	*-----------------------------------------------------------------------------------------------------*
end

/* Update Log:

	1.0.1 finalized first version of ado file (4 April 2019)
	1.0.2 changed displayed output quantities  (11 May 2019)
			- added direct effect
			- removed mediation effect as % of total effect
			- only display the % med effect of total as value above first stage F stats
	1.0.3 added FULL option to display full GMM output (30 Oct 2019)
		  improved display formatting of results
		  restricted use to only a single instrument
	1.0.4 changed how matrix elements are called under the "full" option to make syntax
		  compatible with versions prior to Stata 16
