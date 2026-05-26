*! 2.0 Ariel Linden 24May2026 	// added delta-method for computing results as default (bootstrap is now an option)
								// added non-bootstrap option for MTT (produces only coefficients)
*! 1.0 Ariel Linden 14Dec2016

program drmmws, eclass 

version 13 

	syntax varlist [if] [in] [,					///
			OVars(string)						/// covariates in outcome model
			PVars(string)						/// covariates in pscore model 
			NSTRata(integer 5) 					/// number of strata to generate, default 5
			COMMon								/// implement common support
			ATT									/// Estimate ATT rather than the default ATE
			Family(string)						/// family in GLM outcome model
			Link(string)						/// link in GLM outcome model
			MEDian								/// estimate median treatment effects
			Bootstrap							/// use bootstrap for SEs (default: margins-based)
			NODots								/// suppress bootstrap replication dots
			SEED(string)						/// seed for bootstrap
			REPS(integer 200)					/// reps in bootstrap
			Level(cilevel)]						// confidence level
		
	quietly {	
			local orig `0'
			tokenize `varlist'
			local outcome `1'
			macro shift
			local treat `1'
			macro shift
			local preds `*'
			
			marksample touse 
			count if `touse' 
			if r(N) == 0 error 2000
			local N = r(N) 
			replace `touse' = -`touse'
						

			 // type of treatment effect
			if "`att'" != "" & "`median'" != "" {
				local effect MTT
				}
			else if "`att'" != "" & "`median'" == "" {	
				local effect ATT
				}
			else if "`att'" == "" & "`median'" != "" {	
				local effect MTE
				}
			else {	
				local effect ATE
			}
			
			// title for output table
			if "`common'" != "" {
				local title "Estimation of `effect' with common support"
				}
			else {
				local title "Estimation of `effect'"
			}
			
	} // end quietly

	*****************
	*** BOOTSTRAP ***
	*****************
	if "`bootstrap'" != "" {
		bootstrap poms1=r(poms1) poms0=r(poms0) teffect=r(drmmws) , ///
			reps(`reps') title(`title') seed(`seed') nodrop level(`level') `nodots': ///
			drmmws2_bs `varlist' if `touse', ovars(`ovars') pvars(`pvars') ///
			nstrata(`nstrata') `att' `common' family(`family') link(`link') `median'
		exit
	}

	********************
	*** DELTA-METHOD ***
	********************
	quietly {

		// give values to options not set
		tokenize `varlist'
		local outcome `1'
		macro shift
		local treat `1'
		macro shift
		local preds `*'

		if "`ovars'" == "" {
			local ovars `preds'
		}
		if "`pvars'" == "" {
			local pvars `preds'
		}
		if "`family'" == "" {
			local family gaussian
		}
		if "`link'" == "" {
			local link   identity
		}

		// validate treatment variable
		tabulate `treat' if `touse' 
		if r(r) != 2 { 
			di as err "With a binary treatment, `treat' must have exactly two values (coded 0 or 1)."
			exit 420  
		} 
		capture assert inlist(`treat', 0, 1) if `touse' 
		if _rc { 
			di as err "With a binary treatment, `treat' must be coded as either 0 or 1."
			exit 450 
		}

		// fit propensity score model
		tempvar pscore
		logit `treat' `pvars' if `touse'
		predict `pscore' if `touse'

		// generate MMWS weights
		mmws `treat' if `touse', pscore(`pscore') nstrata(`nstrata') `att' `common' replace

		// fit outcome models and get marginal means via margins
		tempvar pom1 pom0 pomdiff

		if "`median'" != "" {
			// median treatment effects via qreg

			qreg `outcome' `ovars' [pw = _mmws] if `treat' == 1 & `touse'

			if "`common'" != "" { 
				predict `pom1' if _support==1 & `touse'
			}
			else {
				predict `pom1' if `touse'
			}
			sum `pom1', meanonly
			local b_poms1 = r(mean)
			local se_poms1 = .

			qreg `outcome' `ovars' [pw = _mmws] if `treat' == 0 & `touse'

			if "`common'" != "" { 
				predict `pom0' if _support==1 & `touse'
			}
			else {
				predict `pom0' if `touse'
			}
			sum `pom0', meanonly
			local b_poms0 = r(mean)
			local se_poms0 = .

			// difference
			gen `pomdiff' = `pom1' - `pom0'
			if "`att'" != "" {
				sum `pomdiff' if `treat' == 1, meanonly
			}
			else {
				sum `pomdiff', meanonly
			}
			local b_teffect = r(mean)
			local se_teffect = .

		}
		else {
			// average treatment effects via glm + margins

			// POM1
			if "`common'" != "" {
				glm `outcome' `ovars' [pw = _mmws] if `treat'==1 & _support==1 & `touse', ///
					link(`link') family(`family')
			}
			else {
				glm `outcome' `ovars' [pw = _mmws] if `treat'==1 & `touse', ///
					link(`link') family(`family')
			}
			margins, atmeans post
			local b_poms1  = _b[_cons]
			local se_poms1 = _se[_cons]

			// POM0
			if "`common'" != "" {
				glm `outcome' `ovars' [pw = _mmws] if `treat'==0 & _support==1 & `touse', ///
					link(`link') family(`family')
			}
			else {
				glm `outcome' `ovars' [pw = _mmws] if `treat'==0 & `touse', ///
					link(`link') family(`family')
			}
			margins, atmeans post
			local b_poms0  = _b[_cons]
			local se_poms0 = _se[_cons]

			// treatment effect via delta method
			local b_teffect = `b_poms1' - `b_poms0'

			// SE of difference: sqrt(se1^2 + se0^2)  (independent models)
			local se_teffect = sqrt(`se_poms1'^2 + `se_poms0'^2)
		}

	} // end quietly

	******************
	* Display results
	******************
	local alpha = 1 - `level'/100
	local zcrit  = invnormal(1 - `alpha'/2)

	// build result matrices
	matrix b = (`b_poms1', `b_poms0', `b_teffect')
	matrix colnames b = poms1 poms0 teffect

	if "`median'" == "" {
		matrix V = (`se_poms1'^2, 0, 0 \ ///
		             0, `se_poms0'^2, 0 \ ///
		             0, 0, `se_teffect'^2)
		matrix colnames V = poms1 poms0 teffect
		matrix rownames V = poms1 poms0 teffect

		ereturn post b V, obs(`N')
		ereturn local cmd     "drmmws"
		ereturn local vcetype "Delta-method"
		ereturn local title   "`title'"

		di ""
		di as text "`title'"
		ereturn display, level(`level')
	}
	else {
		// For median — post results using zero V (missing not allowed),
		// then manually render a table matching Stata's standard layout.
		matrix V = J(3,3,0)
		matrix colnames V = poms1 poms0 teffect
		matrix rownames V = poms1 poms0 teffect

		ereturn post b V, obs(`N')
		ereturn local cmd     "drmmws"
		ereturn local title   "`title'"

		di ""
		di as text "`title'"
		di as text "{hline 13}{c TT}{hline 13}"
		di as text %12s " " " {c |}" %13s "Coefficient"
		di as text "{hline 13}{c +}{hline 13}"
		di as text %12s "poms1"   " {c |}" as result %12.7g `b_poms1'
		di as text %12s "poms0"   " {c |}" as result %12.7g `b_poms0'
		di as text %12s "teffect" " {c |}" as result %12.7g `b_teffect'
		di as text "{hline 13}{c BT}{hline 13}"
		di as text "Note: SEs not available for median estimates without bootstrap."
	}

end
