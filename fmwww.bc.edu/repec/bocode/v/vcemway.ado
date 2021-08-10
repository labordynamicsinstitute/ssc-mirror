// Ariel Gu (ariel.gu@northumbria.ac.uk) and Hong Il Yoo (h.i.yoo@durham.ac.uk): 21 May 2020.
// M-Way Clustered Standard Errors
// v1.0.3 (21 May 2020) 
//  - the code is now compatible with commands that only allow for vce(cluster clustvar) instead of both vce(cluster clustvar) and cluster(clustvar)
// v1.0.2 (16 Feb 2020)
//	- in Stata 16 or above, some commands (e.g. probit & tobit)do not allow e(N_clust) to be local. when c(stata_version) > 15, we now set the ereturn object to missing to avoid an error message.
// v1.0.1 (22 Jun 2019)
//	- like cluster(varname), do not report standard errors when one of clustering variables is a constant 
// v1.0.0 (11 Jan 2019)
//	- allows for [if] [in] and [weight]
program vcemway
	version 13.1
	if replay() {
		if ("`e(vcemway)'" != "yes") error 301
		Replay `0'
	}
	else Estimate `0'
end

program define Estimate, eclass 
	version 13.1
	syntax anything(id="command line" name=command_line) [if] [in] [fweight  aweight  pweight  iweight], CLuster(varlist min=2) ///
																								    [VMCFACTOR(string) VMDFR(integer 0) *]  
	// Check for syntax errors
	if (`vmdfr' < 0) {
		di as red "Residual degrees of freedom for t tests and F tests, # in option -vmdfr(#)-, must be a positive integer."
		exit 197
	}
	if ("`vmcfactor'" == "") local vmcfactor default
	if ("`vmcfactor'" != "default" & "`vmcfactor'" != "minimum" & "`vmcfactor'" != "none") {
		di as red "The small-cluster correction type, str in option -vmcfactor(str)-, must be default or minimum or none."
		exit 197
	}
																									
	// Mark sample
	marksample touse
	markout `touse' `cluster', strok
	
	// Remove vcemway options from the rest 
	local remove vmcfactor(`vmcfactor') vmdfr(`vmdfr')
	local options : list options - remove
	
	// Set up weight options
	if ("`weight'" != "") local weight [`weight' `exp']		
	
	// Identify the total number of clustering dimensions (k_way)
	local k_way = wordcount("`cluster'")

	// Install user-written command -tuples- if not already available
	capture which tuples
	if (_rc != 0) ssc install tuples	
	
	// Identify tuples of cluster variables. Stored as locals tuple1, tuple2, and so on, where first k_way tuples are singletons.   
	tuples `cluster', varlist
	
	// Define temporary objects (note: local ntuples counts the total number of tuples of cluster variables, and has been generated by command -tuples-).
	forvalues i = 1/`ntuples' {
		tempname V`i'
	}	
	forvalues i = `=`k_way'+1'/`ntuples' {
		tempvar cluster`i'
	}
	tempname b V_oneway V_mway V_mway_raw rank
	tempvar uhat	

	// Define local macros for cluster variables
	forvalues i = 1/`k_way' {
		local cluster`i': word `i' of `cluster'
	}
	
	// Generate temporary variables to capture intersections of clusters
	forvalues i = `=`k_way'+1'/`ntuples' {
		qui egen double `cluster`i'' = group(`tuple`i'') if `touse' `in'
	}		
	
	quietly {
		//---------------------------------------
		// Step 1: one-way cluster on `cluster1' 
		//---------------------------------------
		capture	`command_line' `weight' if `touse' `in', cluster(`cluster1') `options'
		if (_rc != 0) `command_line' `weight' if `touse' `in', vce(cluster `cluster1') `options'
		matrix `b'        = e(b)
		matrix `V_oneway' = e(V)
		local N_clust1    = e(N_clust)
		local N_clustALL `N_clust1'
		
		//===================================================================
		// Step 1.A: check if the underlying command allows -predict, score-
		//===================================================================
		if (e(k_eq) == . | e(k_eq) == 1) {
			capture predict double `uhat' if e(sample), score	
			local step4 = _rc
			local scorevar `uhat'	
		}
		else {
			capture predict double `uhat'* if e(sample), scores
			local step4 = _rc
			local scorevar `uhat'*
		}
		
		//=============================================================================
		// Step 1.B: check if -_robust- can replicate one-way clustering on `cluster1' 
		//============================================================================= 
		if (`step4' == 0) {
			// use _robust to replicate e(V) to identify which minus() option to apply:
			//	some Stata commands (e.g. probit) use minus(1), others use minus(k) (e.g. regress) where k is # of model parameters.
			local minus = colsof(`b') 
			matrix `V1' = e(V_modelbased)
			_robust `scorevar' `weight' if e(sample), cluster(`cluster1') variance(`V1') minus(`minus') 
			capture assert `=mreldif(`V_oneway', `V1')' <= 1e-8	
			
			if (_rc != 0) {
				// if minus = k does not replicate e(V), try to replicate it using minus = 1
				local minus = 1 
				matrix `V1' = e(V_modelbased)
				_robust `scorevar' `weight' if e(sample), cluster(`cluster1') variance(`V1') minus(`minus') 
				capture assert `=mreldif(`V_oneway', `V1')' <= 1e-8
				
				// if minus = 1 doesn't work either, proceed to step 4
				if (_rc != 0) {
					local step4 = 1
				}
			}
		}
		
		// If both 1.A and 1.B go through successfully, complete Step 2 and Step 3.
		if (`step4' == 0) {
			//-------------------------------------------------------------------------------------
			// Step 2: Use -_robust- to achieve one-way clustering on other variables in cluster()
			//-------------------------------------------------------------------------------------
			forvalues i = 2/`k_way' {
				matrix `V`i'' = e(V_modelbased)
				_robust `scorevar' `weight' if e(sample), cluster(`cluster`i'') variance(`V`i'') minus(`minus') 
				local N_clust`i' = r(N_clust)
				local N_clustALL `N_clustALL', `N_clust`i''
			}
			
			//--------------------------------------------------------------------------------------------
			// Step 3: Use -_robust- to achieve one-way clustering on tuples of several cluster variables
			//--------------------------------------------------------------------------------------------
			forvalues i = `=`k_way'+1'/`ntuples' {
				matrix `V`i'' = e(V_modelbased)
				_robust `scorevar' `weight' if e(sample), cluster(`cluster`i'') variance(`V`i'') minus(`minus') 
				local N_clust`i' = r(N_clust)
			}
		}
		
		// If either 1.A or 1.B fails, complete Step 4 instead.    
		// Now, obtain `ntuples' one-way clustered matrices from `ntuples' separate estimation runs.
		if (`step4' != 0) {
			//-------------------------------------------------------------------------
			// Step 4. Obtain one-way clustered covariance matricies using a long way
			//-------------------------------------------------------------------------
			tempname output_cluster1
			matrix `V1' = `V_oneway'
			est store `output_cluster1'
			forvalues i = 2/`ntuples' {
				capture `command_line' `weight' if `touse' `in', cluster(`cluster`i'') `options'
				if (_rc != 0) `command_line' `weight' if `touse' `in', vce(cluster `cluster`i'') `options'
				matrix `V`i'' = e(V)
				local N_clust`i' = e(N_clust)
				if (`i' <= `k_way') local N_clustALL `N_clustALL', `N_clust`i''			
			}
			est restore `output_cluster1'
		}
		
		//-----------------------------------------------------------
		// Step 5: compute the multi-way clustered covariance matrix 
		//-----------------------------------------------------------
		if ("`vmcfactor'" == "minimum") {
			// use G/(G-1) as the common correction factor where G = minimum of `k_way' cluster sizes		
			forvalues i = 1/`ntuples' {
				matrix `V`i'' = min(`N_clustALL') / (min(`N_clustALL') - 1) * (`N_clust`i'' - 1) / (`N_clust`i'') * `V`i''
			}
		}
		if ("`vmcfactor'" == "none") {
			// cancel out Stata's default small-cluster correction factor		
			forvalues i = 1/`ntuples' {
				matrix `V`i'' = (`N_clust`i'' - 1) / (`N_clust`i'') * `V`i''
			}
		}			
		
		// continue using G/(G-1) * (N - 1)/(N - K) as the multiplication factor where G varies across `ntuples' matrices 
		matrix `V_mway' = `V1'
		forvalues i = 2/`ntuples' {
			// in case the tuple comprises an even number of clustering dimensions, subtract the covariance matrix:
			// see formula (2.13) in Cameron, Gelbach and Miller [2012]
			if (`=mod(wordcount("`tuple`i''"),2)' == 0) {
				matrix `V_mway' = `V_mway' - `V`i''
			}
			// otherwise, add the matrix
			else matrix `V_mway' = `V_mway' + `V`i''
		}
		
		//------------------------------------------------------------------------------------------
		// Step 6. check V_mway is p.s.d.; if not, replace eigenvalues with zeroes and resconstruct
		//------------------------------------------------------------------------------------------
		mata {
			V_mway = st_matrix(st_local("V_mway"))
			st_numscalar(st_local("rank"), rank(V_mway))
			symeigensystem(V_mway, EVEC = ., eval = .)
			if (min(eval) < 0) {
				eval = eval :* (eval :> 0) 
				st_matrix(st_local("V_mway_raw"), V_mway)
				st_matrix(st_local("V_mway"), EVEC*diag(eval)*EVEC')
				st_local("replace","yes")	
			}
		}

		//------------------------------------------------------------------------------------------
		// Step 7. like cluster(varname), set V_mway to 0s if any clustering variable is a constant
		//------------------------------------------------------------------------------------------		
		if (min(`N_clustALL') == 1) {
			mata: V_mway = st_matrix(st_local("V_mway"))
			mata: st_matrix(st_local("V_mway"), J(rows(V_mway), cols(V_mway), 0))											
			local rank = 0
		}
		
		//--------------------------------------------------------------------------------------------
		// Final Step: add extra items to ereturn list and post multi-way clustered covariance matrix
		//--------------------------------------------------------------------------------------------
		ereturn local vcemway "yes"
		ereturn local clustvar "`cluster'"
		forvalues i = 1/`k_way' {
			ereturn local clustvar`i' "`cluster`i''"
		}
	
		// see vcemway release note v1.0.2 for why next two command lines differ for version 16 or above vs others
		if (`=int(c(stata_version))' > 15) ereturn local N_clust = .
		else ereturn local N_clust "N_clust'i' reports the number of clusters in clustvar'i'"
		
		ereturn local vmcfactor "`vmcfactor'"

		forvalues i = 1/`k_way' {
			ereturn scalar N_clust`i' = `N_clust`i''
		}
		ereturn scalar rank	= `rank'
		if (e(df_r) != .) {
			if (`vmdfr' > 0) ereturn scalar df_r = `vmdfr'
			else ereturn scalar df_r = min(`N_clustALL') - 1 
		}
		if ("`replace'" == "yes") ereturn matrix V_raw = `V_mway_raw'
		ereturn repost V=`V_mway'
	}
	
	// Display results
	Replay
	if (e(df_r) == . & `vmdfr' > 0) {
		di as text ""
		di as text "	# residual degrees of freedom in vmdfr(#) is irrelevant: `e(cmd)' does not use t tests and F tests."
	}	
end

program define Replay	
	version 13.1
	
	// Display estimation results with two-way clustered standard errors
	if ("`e(cmd)'" != "") `e(cmd)'
	else estimates replay
	
	// Display any notes (NOTE: Replay and Estimate are separate programs. Locals N_clustALL and k_way must be regenerated).
	local k_way = wordcount("`e(clustvar)'")
	local N_clustALL e(N_clust1)

	di as text "Notes:"
	di as text "	Std. Err. adjusted for `k_way'-way clustering on `e(clustvar)'"	
	
	forvalues i = 1/`k_way' {
		di as text "	  Number of clusters in " as text %-12s abbrev("`e(clustvar`i')'",12) " = " as result `e(N_clust`i')'
		if (`i' > 1) local N_clustALL `N_clustALL', e(N_clust`i')
	}
	if ("`e(vmcfactor)'" == "default") {
		di as text ""
		di as text "    Stata's default small-cluster correction factors have been applied. See {helpb vcemway} for detail."
	}
	if ("`e(vmcfactor)'" == "minimum") {
		di as text ""
		di as text "    The small-cluster correction factor is G/(G-1) where G = " as result `=min(`N_clustALL')' as text ", the minimum of `k_way' cluster sizes."
	}	
	if ("`e(vmcfactor)'" == "none") {
		di as text ""
		di as text "    No small-cluster correction factor has been applied."
	}		
	
	if (e(df_r) != .) {
		di as text "" 
		di as text "	Residual degrees of freedom for t tests and F tests = " as result `e(df_r)' 	
	}	
	if (e(F) != .) {
		local stat F(,)
		local prob Prob > F
	}
	if (e(chi2) != .) {
		local stat chi2()
		local prob Prob > chi2
	}		
	if ("`e(chi2type)'" != "LR" & "`stat'" != "") {
		di as text ""
		di as text "    `stat' and `prob' above only account for one-way clustering on `e(clustvar1)'."       
		di as text "      Use {helpb test} to compute `stat' and `prob' that account for `k_way'-way clustering."		
	}
	if ("`replace'" == "yes") {
		di as text ""
		di as text "	The initial variance-covariance matrix, " as result "e(V_raw)" as text ", was not positive semi-definite." 
		di as text "	  The final matrix, " as result "e(V)" as text ", was computed by replacing negative eigenvalues with 0s."
	}
end 

exit
