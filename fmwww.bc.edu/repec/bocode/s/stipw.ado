*! Version 1.0.0 17Jan2022

/*
History
MH 17Jan2022: First release to SSC and Github
*/

program define stipw , eclass sortpreserve
	version 15.1
	preserve
	
	local cmdline : copy local 0
	
	
	** Parse the main command
	
	syntax [anything] [if] [in] , ///
			Distribution(string) ///				Distribution of survival model
			[ ///
			ANCILLARY ///							STREG: Model treatment on the ancillary parameter as well
			OCOEF ///								Displays coefficient table from outcome model, before variance is updated (if mest)
			OHEADer ///								Displays header from outcome model, before variance is updated (if mest)
			///
			BKnots(numlist ascending min=2 max=2) ///		STPM2: Boundary knots for baseline
			BKNOTSTVC(numlist ascending min=2 max=2) ///	STPM2: Boundary knots for time-dependent treatment/exposure
			DF(string) ///							STPM2: Degrees of freedom for baseline hazard function
			DFTvc(string) ///						STPM2: Degrees of freedom for treatment/exposure if time-dependent				
			FAILCONVLININIT ///						STPM2: Automatically try lininit option if convergence fails
			KNOTS(numlist ascending) ///			STPM2: Knot locations for baseline hazard
			KNOTSTvc(numlist ascending) ///			STPM2: Knot locations for treatment/exposure if time-dependent
			KNSCALE(string) ///						STPM2: Scale for user-defined knots (default scale is time)
			NOORTHog ///							STPM2: Do not use orthogonal transformation of splines variables
			///
			IPWtype(string) ///						Weight type - stabilised or unstabilised
			VCE(string)	 ///						Variance type
			GENWeight(string) ///					Generates the weights with name string
			GENFlag(string) ///						Generates the touse flag with name string
			STSETUpdate ///							Update the stset call 
			///
			NOHEADer ///							Suppress header from final coefficient table
			NOHR ///								STREG: Do not report hazard ratios
			TRatio ///								STREG: Report time ratios
			NOShow ///								STREG: Do not show st setting information from outcome model, before variance is updated (if mest)
			EForm ///								STPM2: Exponentiate coefficients
			ALLEQ ///								STPM2: Report all equations
			KEEPCons ///							STPM2: do not dro pconstraints used in ml routine. Stored in constrainsts directory
			SHOWCons ///							STPM2: List constraints in output
			///
			NOLOg ///								Supress log from outcome model, before variance is updated
			LINinit ///								STPM2: obtain initial values by first fitting a linear function of ln(time)
			* ///									ML and display options
			]					
	marksample touse
	mlopts out_mlopts options, `options'
	_get_diopts diopts, `options'
	local onolog : copy local nolog
	
	* Parse each model, separated by brackets, should just be one treatment model
	_parse expand trt_model op : anything
	
	* Extract out the logit part
	gettoken tcmd 0 : trt_model_1
	
	* Syntax for the treatment model
	syntax varlist(min=2 numeric) [ ,  ///
			NOCONStant ///						Do not specify constant term in the treatment model
			OFFset(varname numeric) ///			Include varname in model with coefficient constrained to 1
			TCOEF ///							Displays coefficient table from treatment/exposure model, default is not to
			NOLOg ///							Supress log from treatment/exposure model
			* ///								ML options
			]
	mlopts trt_mlopts, `options'
	
	* Parse the varlist to get treatment and confounders
	gettoken trt Z : varlist
	
	
	** Error checks: Treatment model
	
	* Check one treatment model is given and in brackets
	gettoken _ignore : anything, match(brackets)
	if ("`brackets'" != "(") {
		di as error "Treatment model needs to be enclosed in brackets"
		exit 198
	}
	if ("`trt_model_2'" != "") {
		di as error "Only one treatment model should be given. It should be enclosed in brackets."
		exit 198
	}
	
	* Check the first word is logit
	if ("`tcmd'" != "logit") {
		di as error "Logit needs to be specified first in the treatment model"
		exit 198
	}
	
	* Treatment variable should only have variables 0 or 1 (or missing)
	cap assert inlist(`trt',0,1,.)
	if (_rc != 0) {
		di as error "Treatment variable should be a binary variable with values 0 and 1."
		exit 198
	}
	
	* Treatment should have both 0 and 1
	cap assert inlist(`trt',0,.)
	if (_rc == 0) {
		di as error "Treatment variable should have both values 0 and 1, currently all values are 0 (or missing)."
		exit 198
	}
	cap
	cap assert inlist(`trt',1,.)
	if (_rc == 0) {
		di as error "Treatment variable should have both values 0 and 1, currently all values are 1 (or missing)."
		exit 198
	}
	cap
	
	* Logit only supported
	if ("`tdistribution'" != "logit" & "`tdistribution'" != "") {
		di as error "Only logit is currently supported for treatment model."
		exit 198
	}	
	
	
	** Error checks: Outcome model
	
	* Check data has been stset
	cap st_is 2 analysis
	if (_rc != 0) {
		di as error "Data must be stset"
		exit 198
	}
	
	* Check weights have not already been specified
	if `"`_dta[st_w]'"' != "" {
		di as error "Data should be stset without weights."
		exit 198
	}
	
	* Check st has not been set with id variable (multiple weights not allowed)
	if `"`_dta[st_id]'"' != "" {
		di as error "Data should be stset without id option: multiple-record-per-subject survival data are not supported."
		exit 198
	}
	
	
	** Error checks: Outcome model - streg
	
	* Check distribution is one that is currently supported
	local l = length("`distribution'")
	if substr("exponential",1,`l') != "`distribution'" & ///
		substr("weibull",1,`l') != "`distribution'" & ///
		substr("gompertz",1,max(3,`l')) != "`distribution'" & ///
		substr("lognormal",1,max(4,`l')) != "`distribution'" & ///
		substr("lnormal",1,max(2,`l')) != "`distribution'" & ///
		substr("loglogistic",1,max(4,`l')) != "`distribution'" & ///
		substr("llogistic",1,max(2,`l')) != "`distribution'" & ///
		"`distribution'" != "rp" {
			di as error "Currently exponential, Weibull, Gompertz, log-logistic, log-normal and rp survival models are supported."
			exit 198
	}
	
	* Check ancillary not specified with exponential model
	if (substr("exponential",1,`l') == "`distribution'" & "`ancillary'" != "") {
		di as error "Ancillary option not allowed with the exponential model"
		exit 198
	}
	
	* Check nohr only specified with Exp, Weib and Gompertz
	if ("`nohr'" != "" & substr("exponential",1,`l') != "`distribution'" & ///
		substr("weibull",1,`l') != "`distribution'" & ///
		substr("gompertz",1,max(3,`l')) != "`distribution'") {
		di as error "Option nohr only allowed with exponential, Weibull and Gompertz distributions"
		exit 198
	}
	
	* Check tratio only specified with Lognormal, Loglogistic, Weibull, exponential
	if ("`tratio'" != "" & substr("gompertz",1,max(3,`l')) == "`distribution'")  {
		di as error "Option tratio only allowed with exponential, Weibull, log-normal and log-logistic"
		exit 198
	}
	
	* Check only one of nohr and tratio is specified
	if ("`nohr'" != "" & "`tratio'" != "") {
		di as error "Only one of nohr and tratio is allowed"
		exit 198
	}	
	
	* Check stpm2 options are not specified with streg
	if ("`distribution'" != "rp" &  ("`bknots'" != "" | "`bknotstvc'" != "" | ///
		"`df'" != "" | "`dftvc'" != "" | "`failconvlininit'" != "" | "`knots'" != "" | ///
		"`knotstvc'" != "" | "`knscale'" != "" | "`noorthog'" != "" | "`eform'" != "" | ///
		"`alleq'" != "" | "`keepcons'" != "" | "`showcons'" != "" | "`lininit'" != "")) {
		di as error "The following options are not permitted with streg models:"
		di as error "bknots, bknotstvc, df, dftvc, failconvlininit, knots, knotstvc knscale, noorthorg, eform, alleq, keepcons, showcons, lininit"
		exit 198
	}		
	
	
	** Error checks: Outcome model - stpm2
	
	* Dftvc must be a number
	if ("`dftvc'" != "") {
		cap confirm integer number `dftvc'
		if _rc>0 {
			display as error "dftvc option must be an integer"
			exit 198
		}
	}
	
	* Bknotstvc can only be specified if dftvc or knotstvc is specified
	if ("`dftvc'" == "" & "`knotstvc'" == "" & "`bknotstvc'" != "") {
		di as error "bknotstvc can only be specified if dftvc or knotstvc is also specified"
		exit 198
	}

	* Check streg options not specified with stpm2
	if ("`distribution'" == "rp" & ("`ancillary'" != "" |  ///
		"`nohr'" != "" | "`tratio'" != "" |  "`noshow'" != "")) {
		di as error "The following options are not permitted with rp (stpm2) models:"
		di as error "ancillary, nohr, tratio, noshow"
		exit 198
	}
	

	** Other error checks
		
	* Check weight is only one of unstabilised or stabilised and set to stabilsied/unstabilised
	if "`ipwtype'" != "" {
		local lw = length("`ipwtype'")
		if substr("unstabilised",1,`lw') != "`ipwtype'" & substr("stabilised",1,`lw') != "`ipwtype'" {
			di as error "Only stabilised and unstabilised weights are allowed"
			exit 198
		}
		else {
			if substr("unstabilised",1,`lw') == "`ipwtype'" {
				local ipwtype = "unstabilised"
			}
			else {
				local ipwtype = "stabilised"
			}
		}
	}
	else {
		local ipwtype = "stabilised"
	}
		
	* Check weight variable not already defined
	cap confirm variable `genweight'
	if (_rc == 0 & "`genweight'" != "") {
		di as error "Variable `genweight' already exists."
		exit 198
	}
	cap
	
	* Check flag variable not already defined
	cap confirm variable `genflag'
	if (_rc == 0 & "`genflag'" != "") {
		di as error "Variable `genflag' already exists."
		exit 198
	}
	cap
	
	* Check variance one of Mestimation or robust. Assign to mestimation if missing
	if (!inlist("`vce'","","robust","mestimation")) {
		di as error "Variance type must be robust or mestimation"
		exit 198
	}
	if ("`vce'" == "") {
		local vce "mestimation"
	}
	
		
	** Missing data
	
	* Flag variable
	if ("`genflag'" == "") {
		cap drop _stipw_flag
		cap
		local genflag = "_stipw_flag"
	}
	
	tempname miss
	qui egen `miss' = rowmiss(`trt' `Z') if `touse'
	qui replace `miss' = `miss' + 1 if `touse' & _st == 0
	qui count if `miss' > 0 & `touse'
	if r(N) > 0 {
		di "`r(N)' observations have missing treatment and/or missing confounder values and/or _st = 0." 
		di "These observations are excluded from the analysis, see variable `genflag'"
		di ""
		qui replace `touse' = 0 if `miss' > 0 & `touse'
	}
	qui gen `genflag' = `touse'
	
	
	** Fit the models
	
	* Treatment model
	di "Fitting logistic regression to obtain denominator for weights"
	if ("`tcoef'" == "") {
		local tnocoef = "nocoef"
	}
	if ("`offset'" != "") {
		logit `trt' `Z' if `genflag', `noconstant' offset(`offset') `tnocoef' `nolog' `trt_mlopts' 
	} 
	else {
		logit `trt' `Z' if `genflag', `noconstant' `tnocoef' `nolog' `trt_mlopts'
	}
	tempname alphas 
	mat `alphas' = e(b)	
	local cmdline_logit = e(cmdline)
	local rc_logit = e(rc)
	local converged_logit = e(converged)
	
	
	* Weights for denominator
	tempvar ps
	qui predict `ps' if `genflag'
	
	
	* Stabilised weights only - second logit for numerator of weights
	if ("`ipwtype'" == "stabilised") {
		di "Fitting second logistic regression with no confounders to obtain numerator for stabilised weights"
		logit `trt' if `genflag', `tnocoef' `nolog'
		tempname alphas2
		mat `alphas2' = e(b)
		matrix coleq `alphas2' = "`trt'2"
		local cmdline_logit2 = e(cmdline)
		local rc_logit2 = e(rc)
		local converged_logit2 = e(converged)
	}
	
	
	* Weights
	if ("`genweight'" == "") {
		cap drop _stipw_weight
		cap
		local genweight = "_stipw_weight"
	}
	if ("`ipwtype'" == "stabilised") {
		tempvar prev
		qui predict `prev' if `genflag'
		qui gen double `genweight' = `trt'*`prev'/`ps' + (1-`trt')*(1-`prev')/(1-`ps') if `genflag'
	}
	else {
		qui gen double `genweight' = `trt'/`ps' + (1-`trt')/(1-`ps') if `genflag'
	}
	
	
	* Outcome model
	di ""
	di "Fitting weighted survival model to obtain point estimates"
	
	qui streset [pw = `genweight'] if `genflag'
	
	if ("`ancillary'" != "") {
		local anc = "ancillary(`trt')"
	}
	if ("`ocoef'" == "") {
		local onocoef = "nocoef"
	}
	if ("`oheader'" == "") {
		local onoheader = "noheader"
	}
	
	if ("`distribution'" == "rp") {
		foreach option in bknots knots knscale dftvc {
			if ("``option''" != "") {
				local `option'_ = "`option'(``option'')" 
			}
		}
		
		if ("`dftvc'" != "" | "`knotstvc'" != "") {
			local tvc = "tvc(`trt')"
			foreach option in bknotstvc knotstvc {
				if ("``option''" != "") {
					local `option'_ = "`option'(`trt' ``option'')" 
				}
			}
		}
		
		local cmd = "stpm2"
		stpm2 `trt' if `genflag', df(`df') scale(hazard) `bknots_' `knots_' `knscale_' `tvc' `dftvc_' `bknotstvc_' `knotstvc_' `onolog' `lininit' `failconvlininit' `noorthog' `onoheader' `onocoef' `keepcons' `out_mlopts'
		
		tempvar xb dxb
		qui predict `xb' if `genflag', xb
		qui predict `dxb' if `genflag', dxb	
		
		local rcs = e(rcsterms_base)
		local drcs = e(drcsterms_base)
		if ("`tvc'" != "") {
			local rcs_trt = e(rcsterms_`trt')
			local drcs_trt = e(drcsterms_`trt')
		}
		
		local del_entry = e(del_entry)
		if (`del_entry' == 1) {
			tempvar xb0
			qui predict `xb0' if `genflag', xb timevar(_t0)
			
			local dfbase = e(dfbase)
			local s0_rcs _s0_rcs1
			forvalues i = 2/`dfbase' {
				local s0_rcs `s0_rcs' _s0_rcs`i'
			}
			if ("`tvc'" != "") {
				local df_trt = e(df_`trt')
				local s0_rcs_trt _s0_rcs_`trt'1
				forvalues i=2/`df_`trt'' {
					local s0_rcs_trt `s0_rcs_trt' _s0_rcs_`trt'`i'
				}
			}
		}	
	}
	
	else {
		local cmd = "streg"
		streg `trt' if `genflag', d(`distribution') `anc' `onoheader' `onocoef' `onolog' `noshow' `out_mlopts'
	}
	
	local model = "`e(cmd)'"
	tempname betas betas_unique Vmodel
	mat `betas' = e(b)
	local rank = e(rank)
	matselrc `betas' `betas_unique' , c(1/`rank')
	if ("`ipwtype'" == "stabilised") {
		mat b_full = `alphas', `alphas2', `betas_unique'
	}
	else {
		mat b_full = `alphas', `betas_unique'
	}
	mat robust = e(V)
	mat `Vmodel' = e(V_modelbased)
	
	if ("`stsetupdate'" == "") {
		tempfile new_variables
		tempvar id
		qui gen `id' = _n
		qui save `new_variables'
	}
	
	
	** Get M-estimates for variance if needed
	
	if ("`vce'" == "mestimation") {	
		mata: stipw()
	}

	
	** Store results
	
	* Return codes and convergence
	ereturn scalar rc_logit = `rc_logit' 
	ereturn scalar converged_logit = `converged_logit'
	if "`ipwtype'" == "stabilised" {
		ereturn scalar rc_logit2 = `rc_logit2' 
		ereturn scalar converged_logit2 = `converged_logit2' 
	}
	
	* Treatment var and counts on and off treatment	
	ereturn local tvar = "`trt'" 
	qui count if `trt' == 0 & `genflag'
	ereturn scalar n0 = r(N) 
	qui count if `trt' == 1 & `genflag'
	ereturn scalar n1 = r(N) 
	
	* Command and command lines	
	ereturn local cmdline_`cmd' = strrtrim(stritrim(e(cmdline)))
	ereturn local cmdline = "stipw `cmdline'" 
	ereturn local cmdline_logit = strrtrim(stritrim("`cmdline_logit'")) 
	if "`ipwtype'" == "stabilised" {
		ereturn local cmdline_logit2 = strrtrim(stritrim("`cmdline_logit2'")) 
	}
	ereturn local cmd3 = "stipw"
	
	* Weight type
	ereturn local ipwtype = "`ipwtype'"
	
	* Offset for logit
	if ("`offset'" != "") {
		ereturn local offset_logit = "`offset'"
	}
	
	
	** Store results: M-estimation only
	if "`vce'" == "mestimation" {
	
		ereturn local vcetype = "M-estimation" 
		ereturn local vce = "mestimation" 
		
		local names = "`:colname b_full'"
		local eqs = "`:coleq b_full'"
		foreach matrix in var_full A B {
			matrix rownames `matrix'= `names'
			matrix colnames `matrix' = `names'
			matrix roweq `matrix' = `eqs'
			matrix coleq `matrix' = `eqs'
		}		
		
		ereturn repost V = var_out , esample(`touse')
		ereturn matrix V_B = B 
		ereturn matrix V_A = A 
		ereturn matrix V_robust = robust 
		ereturn matrix V_full = var_full 
		ereturn matrix b_full = b_full 
		
		if "`ancillary'" != "" {
			ereturn scalar df_m = 2 
		}
		
		* Redo Wald test
		qui testparm *`trt'*
		ereturn scalar chi2 = r(chi2) 
		ereturn scalar p = r(p) 
		ereturn local chi2type = "Wald"
	}
	
	
	** Display results
	
	di ""
	di "Displaying weighted survival model with `e(vcetype)' standard errors"
	
	if ("`nohr'" == "" & "`distribution'" != "rp") {
		local trans = "hr"
	}
	if ("`tratio'" != "") {
		local trans = "tratio"
	}
	if ("`alleq'" == "" & "`distribution'" == "rp") {
		local neq = "neq(1)"
	}
	if ("`showcons'" == "" & "`distribution'" == "rp") {
		local nocnsreport = "nocnsreport"
	}
	ml display	, `trans' `eform' `noheader' `neq' `nocnsreport' `diopts'
	
	
	** Save the weights and touse
	
	if ("`stsetupdate'" != "") {
		restore, not
		di ""
		di "Warning: stset has been updated with the weights" 
	}
	
	else {
		* Clear the data characteristics from the using data
		use `new_variables', replace
		local ilist: char _dta[]
        foreach i in `ilist' {
            char _dta[`i']
        }
		qui save `new_variables', replace
		
		* Clear any stipw/stpm2 variables that will be replaced
		restore	
		if ("`genweight'" == "_stipw_weight") {
			cap drop _stipw_weight
			cap
		}
		if ("`genflag'" == "_stipw_flag") {
			cap drop _stipw_flag
			cap
		}
		if ("`distribution'" == "rp") {			
			cap drop _rcs* 
			cap
			cap drop _d_rcs*  
			cap
			cap drop _s0_rcs*
			cap
		}
		
		* Merge new variables into the dataset
		qui gen `id' = _n
		qui merge 1:1 `id' using `new_variables' , noreport nogen ///
			keepusing(`id' `genweight' `genflag' `rcs' `drcs' `rcs_trt' `drcs_trt' `s0_rcs' `s0_rcs_trt')
		
		* Update e(sample)
		tempvar samp
		qui gen `samp' = `genflag'
		ereturn repost b = `betas', esample(`samp')		
	}
	
end


version 15.1
set matastrict on
mata:


//////////////////////////////////
// 		Define structure		//
//////////////////////////////////
 
struct stipw_info {

// Importing data
		real matrix 	touse,				// Marker for [in] and [if]
						t, 					// Survival time
						t0,					// Entry time
						d,					// Event indicator
						trt,				// Treatment indicator
						Z_,					// Covariates without intercept
						Z,					// Covariates with intercept
						offsetvar,			// Offset variable if specified
						rcs,				// Restricted cubic spline variables
						drcs,				// Differential of restricted cubic spline variables
						rcs_trt,			// Restricted cubic spline variables for trt
						drcs_trt, 			// Differential of restricted cubic spline variables for trt
						s0_rcs,				// Restricted cubic spline variables for delayed entry
						s0_rcs_trt,			// Restricted cubic spline variables for trt for delayed entry
						xb,					// Predicted xb from stpm2
						xb0,				// Predicted xb from stpm2 with timevar t0
						dxb					// Predicted dxb from stpm2
							
// Parameter estimates
		real matrix		alphas,				// Point estimates for the treatment model
						alphas2,			// Point estimate for the second treatment model, intercept for logit model for trt with no covariates
						betas,				// Point estimates for the outcome model
						thetas,				// All parameters
						Vmodel				// Model based variance matrix, used as part of A matrix (issue for Weibull, so done maually)

// Counts
		real scalar		stab,				// Indicator for stabilised weights 1 = stabilised, 0 = unstabilised
						nocons,				// Exclude constant term in treatment model 1 = Yes
						offset,				// Offset variable for treatment model 1 = Yes
						anc,				// Treatment modelled on ancillary parameter (streg) 1 = Yes
						tvc,				// Treatment modelled as tvc (stpm2) 1 = Yes
						del,				// Delayed entry (stpm2) 1 = Yes
						n,					// Number of patients
						nalphas,			// Number of treatment parameters
						nbetas,				// Number of outcome parameters
						nthetas				// Total number of parameters
						
// Outcome model options
		string scalar	model				// Type of outcome model
		
// Pointers
		pointer(real scalar function) matrix	score,				// score function (u function in M-estimation)
												hessian				// Hessian matrix - derivative of score/u function				
						
}	


//////////////////////////////////
// 		Fill in structure		//
//////////////////////////////////

function stipw_get_stuff() {
	struct stipw_info scalar S
	
	stipw_get_stuff_general(S)

	return(S)
}

function stipw_get_stuff_general(struct stipw_info scalar S) {

// Get details about command
	S.model						= st_local("model")	
	
// Read in data
	S.touse						= st_local("touse")
	S.stab						= st_local("ipwtype") == "stabilised"
	S.nocons					= st_local("noconstant") != ""
	S.offset					= st_local("offset") != ""
	S.anc						= st_local("ancillary") != ""
	S.tvc						= st_local("tvc") != ""
	S.del						= st_local("del_entry") == "1"
	
	S.t							= st_data(.,"_t",S.touse)
	S.t0						= st_data(.,"_t0",S.touse)
	S.d 						= st_data(.,"_d", S.touse)
	S.trt 						= st_data(.,st_local("trt"),S.touse)
	S.Z_ 						= st_data(.,st_local("Z"), S.touse)	
	if (S.offset) S.offsetvar	= st_data(.,st_local("offset"), S.touse)
	
	if (S.model == "stpm2") {
		S.rcs					= st_data(.,st_local("rcs"),S.touse)
		S.drcs					= st_data(.,st_local("drcs"),S.touse)
		S.xb					= st_data(.,st_local("xb"),S.touse)
		S.dxb					= st_data(.,st_local("dxb"),S.touse)
		if (S.tvc == 1) {
			S.rcs_trt			= st_data(.,st_local("rcs_trt"),S.touse)
			S.drcs_trt			= st_data(.,st_local("drcs_trt"),S.touse)
		}
		if (S.del == 1) {
			S.s0_rcs			= st_data(.,st_local("s0_rcs"),S.touse)
			if (S.tvc == 1) {
				S.s0_rcs_trt	= st_data(.,st_local("s0_rcs_trt"),S.touse)
			}
			S.xb0				= st_data(.,st_local("xb0"),S.touse)
		}
	}
	
	S.alphas					= st_matrix(st_local("alphas"))
	if (S.stab) S.alphas2 		= st_matrix(st_local("alphas2"))
	S.betas						= st_matrix(st_local("betas"))
	S.Vmodel					= st_matrix(st_local("Vmodel"))
	if (S.model == "stpm2") {
		if (S.del == 1) S.betas	= S.betas[1::(cols(S.betas)+2)/3]
		else S.betas			= S.betas[1::cols(S.betas)/2+1]
		S.Vmodel				= S.Vmodel[1::cols(S.betas), 1::cols(S.betas)]
	}	
	if (S.stab) S.thetas		= S.alphas, S.alphas2, S.betas
	else S.thetas 				= S.alphas, S.betas
	
	S.n							= rows(S.t)
	S.nthetas					= cols(S.thetas)
	S.nalphas					= cols(S.alphas)
	S.nbetas 					= cols(S.betas)
	
	if (S.nocons) S.Z			= S.Z_
	else S.Z					= S.Z_, J(S.n,1,1)
}


//////////////////////////////////
// 		Declare pointers		//
//////////////////////////////////

void function stipw_declare_pointers(struct stipw_info scalar S) 
{
	// Exponential
	if (S.model == "ereg") {
		S.score 					= &stipw_exp_score()
	}
		
	// Weibull
	if (S.model == "weibull") {
		if (S.anc) {
			S.score 				= &stipw_weibull_anc_score()
			S.hessian				= &stipw_weibull_anc_hessian()
		}
		else {
			S.score 				= &stipw_weibull_score()
			S.hessian				= &stipw_weibull_hessian()
		}
	}
	
	// Gompertz
	if (S.model == "gompertz") {
		if (S.anc) S.score			= &stipw_gompertz_anc_score()
		else S.score				= &stipw_gompertz_score()
	}
	
	// Log-logistic
	if (S.model == "llogistic") {
		if (S.anc) S.score			= &stipw_loglogistic_anc_score()
		else S.score				= &stipw_loglogistic_score()
	}
	
	// Log normal
	if (S.model == "lnormal") {
		if (S.anc) S.score			= &stipw_lognormal_anc_score()
		else S.score				= &stipw_lognormal_score()
	}
	
	// stpm2
	if (S.model == "stpm2") S.score = &stipw_stpm2_hazard_score()

}


//////////////////////////////////
// 			stipw				//
//////////////////////////////////

void function stipw()
{
	real matrix		lp,					// Confounders (z) multipled by alphas (a) with offset included
					ps,					// Estimated propensity score
					prev,				// Prevalence of treatment (stabilised weights)
					w,					// Estimated (unstabilised or stabilised) weight from PS
					diffw,				// Differential of the weights wrt to the alphas
					diffw2,				// Differential of the weights wrt to the alphas2
					uout,				// u (or score) function for the outcome model without weights
					u,					// u function for all paramaters (trt and out)
					H,					// Derivative of u (or Hessian) for the outcome model without weights
					A,					// A matrix of the sandwich estimator
					invA,				// Inverse of A
					B,					// B matrix of the sandwich estimator
					var_full,			// Variance from M-estimation
					var_out,			// Variance matrix of the survival model only	
					var_stpm			// Variance matrix with additional equations for stpm2
					
	real scalar		nstpm,				// Number of parameters in full stpm2 variance (no delayed entry) 
					nstpmd				// Number of parameters in full stpm2 variance (delayed entry)	
						
// Define structure
struct stipw_info scalar S


// Setting up
S = stipw_get_stuff()
stipw_declare_pointers(S)


// Create the weights
if (S.offset) lp	= (S.Z,S.offsetvar)*(S.alphas,1)'
else lp				= S.Z*S.alphas'
ps					= (1:+exp(-1:*lp)):^(-1)
if (S.stab) {
	prev			= (1+exp(-S.alphas2))^(-1)
	w				= S.trt :* prev :/ ps :+ (1 :- S.trt) :* (1 :- prev) :/ (1 :- ps)
}
else w				= S.trt :/ ps :+ (1 :- S.trt) :/ (1 :- ps)


// Get the u (for outcome) and Hessian
uout		= (*S.score)(S)
if (S.model == "weibull") {														// Issue with unweighted variance for Weibull, so done manually
	H		= rowshape((-1/S.n * quadcolsum(w :* (*S.hessian)(S))),S.nbetas)
}
else H 		= qrinv(S.n :* S.Vmodel)


// Matrix A
A = J(S.nthetas,S.nthetas,0)

// Matrix A for trt model
A[(1::S.nalphas),(1::S.nalphas)] = 1/S.n :* S.Z' * (S.Z :* exp(lp) :/ (exp(lp) :+ 1):^2)

// Matrix A for 2nd trt model (stabilised weights)
if (S.stab) {
	A[S.nalphas+1,S.nalphas+1] = exp(S.alphas2)/((exp(S.alphas2)+1)^2)
}

// Matrix A for out model
A[(S.nthetas-S.nbetas+1::S.nthetas),(S.nthetas-S.nbetas+1::S.nthetas)] = H

// Matrix A for trt model and 2nd trt model (stabilised weights): 0 matrix, independent
	
// Matrix A for trt and out model, lower left rectangle
if (S.stab) diffw 	= S.Z :* (exp(lp) :* (1 - prev) :- S.trt :* (exp(-1 :* lp) :* prev + exp(lp) :* (1 - prev)))
else		diffw	= S.Z :* (exp(lp) :- S.trt :* (exp(-1 :* lp) + exp(lp) ))			
A[(S.nthetas-S.nbetas+1::S.nthetas),(1::S.nalphas)] = -1/S.n * uout'*diffw

// Matrix A for 2nd trt and out model (stabilised weights)
if (S.stab) {
	diffw2 = S.trt :* exp(-S.alphas2) :/ ((1+exp(-S.alphas2))^2) :/ ps :- (1 :- S.trt) :* exp(S.alphas2) :/ ((1+exp(S.alphas2))^2) :/ (1 :- ps)
	A[(S.nthetas-S.nbetas+1::S.nthetas),S.nalphas+1] = -1/S.n * uout'*diffw2
}

st_matrix("A",A)


// Matrix B
if (S.stab) u		= S.Z:*(S.trt:-ps) , S.trt :- prev, w:*uout
else u 				= S.Z:*(S.trt:-ps) , w:*uout
B 					= 1/S.n :* u'*u
st_matrix("B",B)


// Get variance
invA		= qrinv(A)
var_full	= 1/S.n :* invA*B*(invA')
st_matrix("var_full",var_full)

var_out		= var_full[(S.nthetas-S.nbetas+1::S.nthetas),(S.nthetas-S.nbetas+1::S.nthetas)]
if (S.model == "stpm2") {
	
	nstpm			= S.nbetas*2-2
	var_stpm 		= J(nstpm, nstpm,.)
	if (S.del == 1) {
		nstpmd		= S.nbetas*3-2
		var_stpm 	= J(nstpmd, nstpmd,.)
	}
	
	var_stpm[(1::S.nbetas),(1::S.nbetas)] = var_out
	var_stpm[(1::S.nbetas),(S.nbetas+1::nstpm)] = var_out[,(2::S.nbetas-1)]
	var_stpm[(S.nbetas+1::nstpm),(1::S.nbetas)] = var_out[(2::S.nbetas-1),]
	var_stpm[(S.nbetas+1::nstpm),(S.nbetas+1::nstpm)] = var_out[(2::S.nbetas-1),(2::S.nbetas-1)]
	
	if (S.del == 1) {
		var_stpm[(2*S.nbetas-1)::nstpmd,(1::S.nbetas)] = var_out
		var_stpm[(1::S.nbetas),(2*S.nbetas-1)::nstpmd] = var_out
		var_stpm[(2*S.nbetas-1)::nstpmd,(2*S.nbetas-1)::nstpmd] = var_out
		var_stpm[(2*S.nbetas-1)::nstpmd,(S.nbetas+1::nstpm)] = var_out[,(2::S.nbetas-1)]
		var_stpm[(S.nbetas+1::nstpm),(2*S.nbetas-1)::nstpmd] = var_out[(2::S.nbetas-1),]
	}
	
	var_out = var_stpm
}
st_matrix("var_out",var_out)

}


//////////////////////////////////
// 		streg - Exponential		//
//////////////////////////////////

// Score function
function stipw_exp_score(struct stipw_info scalar S) 
{
	real scalar loghr, loglambda
	real matrix tlp, q, tlp0, A1, A2

	loghr 		= S.betas[1]
	loglambda 	= S.betas[2]
	
	tlp			= S.t :* exp(loglambda :+ loghr :* S.trt)		// t*exp(linear predictor)
	
	A1 = S.trt :* (S.d :- tlp) 
	A2 = S.d :- tlp
	
	q = selectindex(S.t0)	
	if (rows(q) > 0) {	
		tlp0		= S.t0 :* exp(loglambda :+ loghr :* S.trt)		// delayed entry
		
		A1[q] = A1[q] :+ S.trt[q] :* tlp0[q] 
		A2[q] = A2[q] :+ tlp0[q]
	}
	
	return(A1, A2)
}


//////////////////////////////////
// 		streg -  Weibull		//
//////////////////////////////////

// Score function: No ancillary parameter
function stipw_weibull_score(struct stipw_info scalar S) 
{
	real scalar loghr, loglambda, gamma
	real matrix tglp, lt, q, tglp0, lt0, A1, A2, A3

	loghr 		= S.betas[1]
	loglambda 	= S.betas[2]
	gamma		= exp(S.betas[3])
	
	tglp		= S.t :^ gamma :* exp(loglambda :+ loghr :* S.trt)
	lt			= log(S.t)

	A1 = S.trt :* (S.d :- tglp) 
	A2 = S.d :- tglp
	A3 = S.d :* (1 :+ gamma :* lt) :- gamma :* lt :* tglp
	
	q = selectindex(S.t0)	
	if (rows(q) > 0) {	
		tglp0		= S.t0 :^ gamma :* exp(loglambda :+ loghr :* S.trt)
		lt0			= log(S.t0)
		
		A1[q] = A1[q] :+ S.trt[q] :* tglp0[q]
		A2[q] = A2[q] :+ tglp0[q]
		A3[q] = A3[q] :+ gamma :* lt0[q] :* tglp0[q]
	}
	
	return(A1, A2, A3)
}


// Score function: Ancillary parameter
function stipw_weibull_anc_score(struct stipw_info scalar S) 
{
	real scalar loghr, loglambda, loganc, loggamma
	real matrix anc, tglp, lt, q, tglp0, lt0, A1, A2, A3, A4

	loghr 		= S.betas[1]
	loglambda 	= S.betas[2]
	loganc		= S.betas[3]
	loggamma	= S.betas[4]
	
	anc			= exp(loggamma :+ loganc :* S.trt)
	tglp		= S.t :^ anc :* exp(loglambda :+ loghr :* S.trt)
	lt			= log(S.t)

	A1 = S.trt :* (S.d :- tglp) 
	A2 = S.d :- tglp
	A3 = S.trt :* (S.d :* (1 :+ anc :* lt) :- anc :* lt :* tglp)
	A4 = S.d :* (1 :+ anc :* lt) :- anc :* lt :* tglp
	
	q = selectindex(S.t0)	
	if (rows(q) > 0) {	
		tglp0		= S.t0 :^ anc :* exp(loglambda :+ loghr :* S.trt)
		lt0			= log(S.t0)
		
		A1[q] = A1[q] :+ S.trt[q] :* tglp0[q]
		A2[q] = A2[q] :+ tglp0[q]
		A3[q] = A3[q] :+ S.trt[q] :* anc[q] :* lt0[q] :* tglp0[q]
		A4[q] = A4[q] :+ anc[q] :* lt0[q] :* tglp0[q]
	}
	
	return(A1, A2, A3, A4)
}


// Hessian function: No ancillary parameter
function stipw_weibull_hessian(struct stipw_info scalar S)
{
	real scalar loghr, loglambda, gamma
	real matrix tglp, lt, glt, gdiff, q, tglp0, lt0, glt0, gdiff0
	real matrix A11, A12, A13, A22, A23, A33

	loghr 		= S.betas[1]
	loglambda 	= S.betas[2]
	gamma		= exp(S.betas[3])
	
	tglp		= S.t :^ gamma :* exp(loglambda :+ loghr :* S.trt)
	lt			= log(S.t)
	glt			= gamma :* lt
	gdiff		= glt :* tglp

	A11 = -1 :* S.trt:^2 :* tglp
	A12 = -1 :* S.trt :* tglp
	A13 = -1 :* S.trt :* gdiff
	A22 = -1 :* tglp
	A23 = -1 :* gdiff
	A33 = S.d :* glt :- gdiff :* (glt :+ 1)
	
	q = selectindex(S.t0)	
	if (rows(q) > 0) {	
		tglp0		= S.t0 :^ gamma :* exp(loglambda :+ loghr :* S.trt)
		lt0			= log(S.t0)
		glt0		= gamma :* lt0
		gdiff0		= glt0 :* tglp0
		
		A11[q] = A11[q] :+ S.trt[q]:^2 :* tglp0[q]
		A12[q] = A12[q] :+ S.trt[q] :* tglp0[q]
		A13[q] = A13[q] :+ S.trt[q] :* gdiff0[q]
		A22[q] = A22[q] :+ tglp0[q]
		A23[q] = A23[q] :+ gdiff0[q]
		A33[q] = A33[q] :+ gdiff0[q] :* (glt0[q] :+ 1)
	}
	
	return(A11, A12, A13, A12, A22, A23, A13, A23, A33)
}


// Hessian function: Ancillary parameter
function stipw_weibull_anc_hessian(struct stipw_info scalar S)
{
	real scalar loghr, loglambda, loganc, loggamma
	real matrix anc, tglp, lt, glt, gdiff, q, tglp0, lt0, glt0, gdiff0
	real matrix A11, A12, A13, A14, A22, A23, A24, A33, A34, A44

	loghr 		= S.betas[1]
	loglambda 	= S.betas[2]
	loganc		= S.betas[3]
	loggamma	= S.betas[4]
	
	anc			= exp(loggamma :+ loganc :* S.trt)
	tglp		= S.t :^ anc :* exp(loglambda :+ loghr :* S.trt)
	lt			= log(S.t)
	glt			= anc :* lt
	gdiff		= glt :* tglp

	A11 = -1 :* S.trt:^2 :* tglp
	A12 = -1 :* S.trt :* tglp
	A13 = -1 :* S.trt:^2 :* gdiff
	A14 = -1 :* S.trt :* gdiff
	A22 = -1 :* tglp
	A23 = -1 :* S.trt :* gdiff
	A24 = -1 :* gdiff
	A33 = S.trt :^ 2 :* (S.d :* glt :- gdiff :* (glt :+ 1))
	A34 = S.trt :* (S.d :* glt :- gdiff :* (glt :+ 1))
	A44 = S.d :* glt :- gdiff :* (glt :+ 1)
	
	q = selectindex(S.t0)	
	if (rows(q) > 0) {	
		tglp0		= S.t0 :^ anc :* exp(loglambda :+ loghr :* S.trt)
		lt0			= log(S.t0)
		glt0		= anc :* lt0
		gdiff0		= glt0 :* tglp0
		
		A11[q] = A11[q] :+ S.trt[q]:^2 :* tglp0[q]
		A12[q] = A12[q] :+ S.trt[q] :* tglp0[q]
		A13[q] = A13[q] :+ S.trt[q]:^2 :* gdiff0[q]
		A14[q] = A14[q] :+ S.trt[q] :* gdiff0[q]
		A22[q] = A22[q] :+ tglp0[q]
		A23[q] = A23[q] :+ S.trt[q] :* gdiff0[q]
		A24[q] = A24[q] :+ gdiff0[q]
		A33[q] = A33[q] :+ S.trt[q]:^2 :* gdiff0[q] :* (glt0[q] :+ 1)
		A34[q] = A34[q] :+ S.trt[q] :* gdiff0[q] :* (glt0[q] :+ 1)
		A44[q] = A44[q] :+ gdiff0[q] :* (glt0[q] :+ 1)
	}
	
	return(A11, A12, A13, A14, A12, A22, A23, A24, A13, A23, A33, A34, A14, A24, A34, A44)
}


//////////////////////////////////
// 		streg - Gompertz		//
//////////////////////////////////

// Score function: No ancillary parameter
function stipw_gompertz_score(struct stipw_info scalar S) 
{
	real scalar loghr, loglambda, gamma
	real matrix lp, gt, gS, gSdiff, q, gt0, gS0, gSdiff0, A1, A2, A3

	loghr 		= S.betas[1]
	loglambda 	= S.betas[2]
	gamma		= S.betas[3]
	
	lp			= exp(loglambda :+ loghr :* S.trt)
	gt			= gamma :* S.t 
	gS			= lp :* gamma^(-1) :* (exp(gt) :- 1)
	gSdiff		= lp :* gamma^(-2) :* (exp(gt) :* (gt :- 1) :+ 1)
	
	A1 = S.trt :* (S.d :- gS) 
	A2 = S.d :- gS
	A3 = S.d:*S.t :- gSdiff
	
	q = selectindex(S.t0)	
	if (rows(q) > 0) {			
		gt0			= gamma :* S.t0 
		gS0			= lp :* gamma^(-1) :* (exp(gt0) :- 1)
		gSdiff0		= lp :* gamma^(-2) :* (exp(gt0) :* (gt0 :- 1) :+ 1)
		
		A1[q] = A1[q] :+ S.trt[q] :* gS0[q]
		A2[q] = A2[q] :+ gS0[q]
		A3[q] = A3[q] :+ gSdiff0[q]	
	}
	
	return(A1, A2, A3)	
}


// Score function: Ancillary parameter
function stipw_gompertz_anc_score(struct stipw_info scalar S) 
{
	real scalar loghr, loglambda, anc, gamma
	real matrix lp, ancp, apt, apS, apSdiff, q, apt0, apS0, apSdiff0, A1, A2, A3, A4

	loghr 		= S.betas[1]
	loglambda 	= S.betas[2]
	anc 		= S.betas[3]
	gamma		= S.betas[4]
	
	lp			= exp(loglambda :+ loghr :* S.trt)
	ancp		= gamma :+ S.trt :* anc
	apt			= ancp :* S.t 
	apS			= lp :* ancp:^(-1) :* (exp(apt) :- 1)
	apSdiff		= lp :* ancp:^(-2) :* (exp(apt) :* (apt :- 1) :+ 1)
	
	A1 = S.trt :* (S.d :- apS) 
	A2 = S.d :- apS
	A3 = S.trt :* (S.d :* S.t :- apSdiff)
	A4 = S.d:*S.t :- apSdiff
	
	q = selectindex(S.t0)	
	if (rows(q) > 0) {			
		apt0			= ancp :* S.t0 
		apS0			= lp :* ancp:^(-1) :* (exp(apt0) :- 1)
		apSdiff0		= lp :* ancp:^(-2) :* (exp(apt0) :* (apt0 :- 1) :+ 1)
		
		A1[q] = A1[q] :+ S.trt[q] :* apS0[q]
		A2[q] = A2[q] :+ apS0[q]
		A3[q] = A3[q] :+ S.trt[q] :* apSdiff0[q]
		A4[q] = A4[q] :+ apSdiff0[q]	
	}
	
	return(A1, A2, A3, A4)	
}


//////////////////////////////////
// 		streg - Log-logistic	//
//////////////////////////////////

// Score function: No ancillary
function stipw_loglogistic_score(struct stipw_info scalar S) 
{
	real scalar logtr, loglambda, eg
	real matrix lp, u, s, q, u0, s0, A1, A2, A3

	logtr 		= S.betas[1]
	loglambda 	= S.betas[2]
	eg			= exp(-S.betas[3])
	
	lp			= loglambda :+ logtr :* S.trt
	u			= exp(-eg :* lp) :* S.t :^ eg
	s			= (S.d :+ 1) :* eg :/ (1 :+ u :^ (-1))
	
	A1 = S.trt :* (-1 :* S.d :* eg :+ s)
	A2 = -1 :* S.d :* eg :+ s
	A3 = -1 :* S.d :* eg :* (-1 :* lp :+ log(S.t)) - S.d :+ s :* (-1 :* lp :+ log(S.t))
				
	q = selectindex(S.t0)	
	if (rows(q) > 0) {			
		u0			= exp(-eg :* lp) :* S.t0 :^ eg
		s0			= eg :/ (1 :+ u0 :^ (-1))
		
		A1[q] = A1[q] :- S.trt[q] :* s0[q]
		A2[q] = A2[q] :- s0[q] 
		A3[q] = A3[q] :- s0[q] :* (-1 :* lp[q] :+ log(S.t0[q]))
	}
	
	return(A1, A2, A3)
}


// Score function: Ancillary
function stipw_loglogistic_anc_score(struct stipw_info scalar S) 
{
	real scalar logtr, loglambda, loganc, loggamma
	real matrix lp, ancp, u, s, q, u0, s0, A1, A2, A3, A4

	logtr 		= S.betas[1]
	loglambda 	= S.betas[2]
	loganc		= S.betas[3]
	loggamma	= S.betas[4]
	
	lp			= loglambda :+ logtr :* S.trt
	ancp		= exp(-loggamma :- loganc :* S.trt)
	u			= exp(-ancp :* lp) :* S.t :^ ancp
	s			= (S.d :+ 1) :* ancp :/ (1 :+ u :^ (-1))
	
	A1 = S.trt :* (-1 :* S.d :* ancp :+ s)
	A2 = -1 :* S.d :* ancp :+ s
	A3 = S.trt :* (-1 :* S.d :* ancp :* (-1 :* lp :+ log(S.t)) - S.d :+ s :* (-1 :* lp :+ log(S.t)))
	A4 = -1 :* S.d :* ancp :* (-1 :* lp :+ log(S.t)) - S.d :+ s :* (-1 :* lp :+ log(S.t))
				
	q = selectindex(S.t0)	
	if (rows(q) > 0) {			
		u0			= exp(-ancp :* lp) :* S.t0 :^ ancp
		s0			= ancp :/ (1 :+ u0 :^ (-1))
		
		A1[q] = A1[q] :- S.trt[q] :* s0[q]
		A2[q] = A2[q] :- s0[q] 
		A3[q] = A3[q] :- S.trt[q] :* s0[q] :* (-1 :* lp[q] :+ log(S.t0[q]))
		A4[q] = A4[q] :- s0[q] :* (-1 :* lp[q] :+ log(S.t0[q]))
	}
	
	return(A1, A2, A3, A4)
}


//////////////////////////////////
// 		streg - Log normal		//
//////////////////////////////////

// Score function: No ancillary
function stipw_lognormal_score(struct stipw_info scalar S) 
{
	real scalar logtr, mu, sd
	real matrix lp, u, du, pu, f, s 
	real matrix q, lp0, u0, du0, pu0, s0
	real matrix A1, A2, A3

	logtr 	= S.betas[1]
	mu 		= S.betas[2]
	sd		= exp(S.betas[3])	
	
	lp		= log(S.t) :- mu :- logtr :* S.trt
	u		= lp :/ sd
	du		= normalden(u)
	pu		= normal(u)
	f 		= S.d :/ (sd^2) :* lp
	s		= (1 :- S.d) :* du :/ (sd :* (1 :- pu))
	
	A1 = S.trt :* (f :+ s)
	A2 = f :+ s
	A3 = -1 :* S.d :+ f :* lp :+ (1 :- S.d) :* du :* u :/ (1 :- pu) 
				
	q = selectindex(S.t0)	
	if (rows(q) > 0) {	
		lp0		= log(S.t0) :- mu :- logtr :* S.trt
		u0		= lp0 :/ sd
		du0		= normalden(u0)
		pu0		= normal(u0)
		s0		= du0 :/ (sd :* (1 :- pu0))
		
		A1[q] = A1[q] :- S.trt[q] :* s0[q]
		A2[q] = A2[q] :- s0[q]
		A3[q] = A3[q] :- du0[q] :* u0[q] :/ (1 :- pu0[q])
	}
	
	return(A1, A2, A3)	
}


// Score function: Ancillary
function stipw_lognormal_anc_score(struct stipw_info scalar S) 
{
	real scalar logtr, mu, sdcons, sdanc
	real matrix lp, sd, u, du, pu, f, s 
	real matrix q, lp0, u0, du0, pu0, s0
	real matrix A1, A2, A3, A4

	logtr 	= S.betas[1]
	mu 		= S.betas[2]
	sdanc	= S.betas[3]
	sdcons	= S.betas[4]	
	
	lp		= log(S.t) :- mu :- logtr :* S.trt
	sd		= exp(sdcons :+ sdanc :* S.trt)
	u		= lp :/ sd
	du		= normalden(u)
	pu		= normal(u)
	f 		= S.d :/ (sd:^2) :* lp
	s		= (1 :- S.d) :* du :/ (sd :* (1 :- pu))
	
	A1 = S.trt :* (f :+ s)
	A2 = f :+ s
	A3 = S.trt :* (-1 :* S.d :+ f :* lp :+ (1 :- S.d) :* du :* u :/ (1 :- pu)) 
	A4 = -1 :* S.d :+ f :* lp :+ (1 :- S.d) :* du :* u :/ (1 :- pu) 
				
	q = selectindex(S.t0)	
	if (rows(q) > 0) {	
		lp0		= log(S.t0) :- mu :- logtr :* S.trt
		u0		= lp0 :/ sd
		du0		= normalden(u0)
		pu0		= normal(u0)
		s0		= du0 :/ (sd :* (1 :- pu0))
		
		A1[q] = A1[q] :- S.trt[q] :* s0[q]
		A2[q] = A2[q] :- s0[q]
		A3[q] = A3[q] :- S.trt[q] :* du0[q] :* u0[q] :/ (1 :- pu0[q])
		A4[q] = A4[q] :- du0[q] :* u0[q] :/ (1 :- pu0[q])
	}
	
	return(A1, A2, A3, A4)	
}


//////////////////////////////////
// 		stpm2 - Hazard model	//
//////////////////////////////////

// Score function
function stipw_stpm2_hazard_score(struct stipw_info scalar S) 
{
	real matrix g1, g2, A, q

	g1 = S.d :- exp(S.xb)
	g2 = S.d :/ S.dxb
	
	if (S.tvc ==1) 	A = g1 :* (S.trt,S.rcs,S.rcs_trt,J(S.n,1,1)) + g2 :* (J(S.n,1,0),S.drcs,S.drcs_trt,J(S.n,1,0))
	else 			A = g1 :* (S.trt,S.rcs,J(S.n,1,1))+ g2 :* (J(S.n,1,0),S.drcs,J(S.n,1,0))
	
	q = selectindex(S.t0)
	if (rows(q) > 0) {															// delayed entry	
		if (S.tvc ==1) 	A[q,] = A[q,] :+ exp(S.xb0)[q] :* (S.trt[q],S.s0_rcs[q,],S.s0_rcs_trt[q,],J(rows(q),1,1))
		else			A[q,] = A[q,] :+ exp(S.xb0)[q] :* (S.trt[q],S.s0_rcs[q,],J(rows(q),1,1))
	}
	
	return(A)
}


end

