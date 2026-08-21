* Version 1.0.0  Date: 13th August 2026

program drop _all
program define msrrd, rclass
    version 17.0

	* Syntax for the command
    syntax varname ///
        [ , subgroup(varname) subtype(string) ///
          rrdp(integer 4) rddpprop(integer 4) rddppct(integer 2) pdp(integer 4) pctdp(integer 1) vceuncond ]

	* Local macros
    local v        "`varlist'"
    local subgroup "`subgroup'"
    local subtype  = lower("`subtype'")
    local y        = e(depvar)
    local subtype_specified = ("`subtype'" != "")
	local vceuncond "`vceuncond'"
	
	* Default option for subtype is to present both RR and RD 
    if ("`subtype'" == "") local subtype "both"
	
	* --- VALIDATE SUBTYPE OPTION ---
	if !inlist("`subtype'", "rr", "rd", "both") {
		display as error "ERROR: subtype(`subtype') is invalid."
		display as error "ERROR: Valid subtype options are: rr, rd, or both."
		exit 198
	}
	
	* Default decimal places for percentage in n/N (%) is 1 dp
    if ("`pctdp'" == "") local pctdp = 1

    *********************************************************************************************************************************************************
    * MODEL CHECKS - The following will ensure command only works if a logit/logistic/melogit or a glm/meglm with family(binomial) and link(logit) was fitted  
    *********************************************************************************************************************************************************
    cap local model  = e(cmd)
    cap local model2 = e(cmd2)
    cap local family = lower(e(varfunct))
    cap local family2 = lower(e(family))
    cap local linkt  = lower(e(linkt))
    cap local link   = lower(e(link))

    local is_logit_family = ("`model'" == "logit" | "`model'" == "logistic" | "`model2'" == "melogit")
    local is_glm_binlogit = ("`model'" == "glm" & ("`family'" == "binomial" | "`family'" == "bernoulli") & "`linkt'" == "logit")
    local is_meglm_binlogit = ("`model2'" == "meglm" & ("`family2'" == "binomial" | "`family2'" == "bernoulli") & "`link'" == "logit")

    if !`is_logit_family' & !`is_glm_binlogit' & !`is_meglm_binlogit' {
        display as error "ERROR: msrrd requires a logistic model (logit/logistic/melogit) or a glm/meglm model fitted with family(binomial) and link(logit)."
		display as error "ERROR: Re-fit the model accordingly and re-run command."
        exit 198
    }

    *****************************************************************************************************************
    * VCE CHECK - This will display a warning prompting used that fitted model was without robust/cluster robust SE's 
    *****************************************************************************************************************
    local vce = e(vce)
    if ("`vce'" != "robust" & "`vce'" != "cluster") {
        display as error "WARNING: Fitted model did not include vce(robust) or vce(cluster) option."
        display as error "WARNING: When estimating RR/RD using marginal standardisation, it is recommended that the fitted model to have robust/cluster robust SE's."
    }

    ********************************************************************************************************************
    * CODING CHECKS - This ensures the command will only run if both outcome and intervention variables are coded as 0/1
    ********************************************************************************************************************
    quietly levelsof `y', local(outlevels)
    if "`outlevels'" != "0 1" {
        display as error "ERROR: Outcome must be coded 0/1."
        exit 198
    }

    quietly levelsof `v', local(trtlevels)
    if "`trtlevels'" != "0 1" {
        display as error "ERROR: For command {cmd:{it:mssrd}} to work, variabel {cmd:{it:`v'}} must be coded 0/1, where 0=Comparator group and 1=Intervention group."
        exit 198
    }
			
	**************************************************************************************************************
    * This will ensure if subtype option is selected without the subgroup option then an error message will appear
    **************************************************************************************************************
	if ("`subgroup'" == "") & `subtype_specified' {
		display as error "ERROR: subgroup option not selected."
		exit 198
	}

    *******************************************************************************************
    * STORE ORIGINAL MODEL - This will retain model estimates to be reused later on when needed
    *******************************************************************************************
    estimates store MSRRD_MODEL_ORIG

    
	*************************************************************************************************************************************************************
	
	
	****************************************************************************************************
    * OVERALL MARGINAL STANDARDISATION - This section of the code is for overall result without subgroup 
    ****************************************************************************************************
    if ("`subgroup'" == "") & ("`vceuncond'" != "") {
		display ""
        display in yellow "Running marginal standardisation with {cmd:{it:vce(unconditional)}} to estimate SEs allowing for sampling of covariates"
    }
	
	if ("`subgroup'" == "") & ("`vceuncond'" == "") {
		display ""
        display in yellow "Running marginal standardisation with {cmd:{it:vce(delta)}} estimate SEs using delta method"
    }

	* --- MARGINS VCE CONTROL ---
	if ("`vceuncond'" != "") {
		quietly margins `v', post vce(unconditional)
	}
		
	if ("`vceuncond'" == "") {
		quietly margins `v', post
	}
	
    *************************
    * EXTRACT MARGINS RESULTS
    *************************
    matrix M  = r(b)
    matrix VM = r(V)

    local p0 = M[1,1]
    local p1 = M[1,2]

    local var_p0   = VM[1,1]
    local var_p1   = VM[2,2]
    local cov_p1p0 = VM[2,1]

    ***********************************************************************
    * RR esimation using marginal standardisation and SE using delta method
    ***********************************************************************
    local rr = `p1'/`p0'
    local logrr = ln(`rr')
    local varlogrr = (`var_p1'/(`p1'^2)) + (`var_p0'/(`p0'^2)) - (2*`cov_p1p0'/(`p1'*`p0'))
    local rr_se = sqrt(`varlogrr')
	local log_rr_se = `rr'*`rr_se'
    local rr_lb = exp(`logrr' - invnorm(0.975)*`rr_se')
    local rr_ub = exp(`logrr' + invnorm(0.975)*`rr_se')
    local rr_z  = `logrr'/`rr_se'
    local rr_p  = 2*normal(-abs(`rr_z'))

    ***********************************************************************
    * RD esimation using marginal standardisation and SE using delta method
    ***********************************************************************
    local rd = `p1' - `p0'
    local vardiff = `var_p1' + `var_p0' - 2*`cov_p1p0'
    local rd_se = sqrt(`vardiff')
    local rd_lb = `rd' - invnorm(0.975)*`rd_se'
    local rd_ub = `rd' + invnorm(0.975)*`rd_se'
    local rd_z  = `rd'/`rd_se'
    local rd_p  = 2*normal(-abs(`rd_z'))

    *********
    * FORMATS
    *********
    local fmt_rr      "%0`=2+`rrdp''.`rrdp'f"
    local fmt_rd_prop "%0`=2+`rddpprop''.`rddpprop'f"
    local fmt_rd_pct  "%0`=2+`rddppct''.`rddppct'f"
    local fmt_p       "%0`=2+`pdp''.`pdp'f"
    local fmt_pct     "%0`=2+`pctdp''.`pctdp'f"

    **********************************************
    * OVERALL EVENT COUNTS (with pctdp formatting)
    **********************************************
    quietly count if `v'==0 & `y'!=.
    local N0 = r(N)
    quietly count if `v'==0 & `y'==1
    local n0 = r(N)

    quietly count if `v'==1 & `y'!=.
    local N1 = r(N)
    quietly count if `v'==1 & `y'==1
    local n1 = r(N)

    local pct0_raw = 100*`n0'/`N0'
    local pct1_raw = 100*`n1'/`N1'

    local pct0 : display `fmt_pct' `pct0_raw'
    local pct1 : display `fmt_pct' `pct1_raw'

    ************************
    * OVERALL COMBINED TABLE 
    ************************
    if ("`subgroup'" == "") {

		* Extract value labels for variable
        local lb1 : label (`v') 1
        local lb0 : label (`v') 0
		
		* Fallback if no labels exist
        if ("`lbl'" == "") local lbl "`v'=1"
        if ("`lb0'" == "") local lbl "`v'=0"
	
        local col1 = "`n1'/`N1' (" + "`pct1'" + "%)"
        local col0 = "`n0'/`N0' (" + "`pct0'" + "%)"

		display ""
        display "----------------------------------------------------------------------"
        display "{bf:FOR OUTCOME `y'}"
        display "----------------------------------------------------------------------"
        display %12s " " ///
                %25s "`v'=`lb1'" ///
                %25s "`v'=`lb0'"
        display "----------------------------------------------------------------------"

        display %12s "n/N (%)" ///
                %25s "`col1'" ///
                %25s "`col0'"

        display "----------------------------------------------------------------------"
        display ""
    }

    *******************************
    * ORIGINAL OVERALL RR/RD OUTPUT
    *******************************
    if ("`subgroup'" == "") {
		display "***************************"
		display "Direction of comparison is: {cmd:{it:`v'}}=`lb1'     versus     {cmd:{it:`v'}}=`lb0'"
		display "***************************"
		display ""
        display ///
            "Risk ratio (95% CI); [SE] = " ///
            `fmt_rr' `rr' " (" `fmt_rr' `rr_lb' ", " `fmt_rr' `rr_ub' "); [" `fmt_rr' `log_rr_se' "]" _n ///
            "P-value for RR = " `fmt_p' `rr_p' _n ///
            _n ///
            "Risk difference as percentage (95% CI); [SE] = " ///
                `fmt_rd_pct' (100*`rd') "% (" `fmt_rd_pct' (100*`rd_lb') "%, " `fmt_rd_pct' (100*`rd_ub') "%); [" ///
                `fmt_rd_pct' (100*`rd_se') "]" _n ///
            "Risk difference as proportion (95% CI); [SE] = " ///
                `fmt_rd_prop' `rd' " (" `fmt_rd_prop' `rd_lb' ", " `fmt_rd_prop' `rd_ub' "); [" ///
                `fmt_rd_prop' `rd_se' "]" _n ///
            "P-value for RD = " `fmt_p' `rd_p'

        capture estimates restore MSRRD_MODEL_ORIG
    }

    if ("`subgroup'" == "") & `subtype_specified' {
        display as error "ERROR: subgroup option not selected."
        capture estimates restore MSRRD_MODEL_ORIG
    }

    ************************
    * RETURN OVERALL RESULTS
    ************************
    return scalar rr    = `rr'
    return scalar rr_lb = `rr_lb'
    return scalar rr_ub = `rr_ub'
    return scalar rr_z  = `rr_z'
    return scalar rr_p  = `rr_p'
    return scalar rr_se = `rr_se'

    return scalar rd    = `rd'
    return scalar rd_lb = `rd_lb'
    return scalar rd_ub = `rd_ub'
    return scalar rd_z  = `rd_z'
    return scalar rd_p  = `rd_p'
    return scalar rd_se = `rd_se'

    if ("`subgroup'" == "") exit
	
	
	*************************************************************************************************************************************************************
	
	
	**********************************************************************
    * SUBGROUP ANALYSIS - This section of the code is for subgroup results
    **********************************************************************
    quietly levelsof `subgroup', local(levels)

	if ("`subgroup'" != "") & ("`vceuncond'" != "") {
		display in yellow ""
        display "Running marginal standardisation with {cmd:{it:vce(unconditional)}} to estimate SEs allowing for sampling of covariates"
    }
	
	if ("`subgroup'" != "") & ("`vceuncond'" == "") {
		display in yellow ""
        display "Running marginal standardisation with {cmd:{it:vce(delta)}} estimate SEs using delta method"
    }
	
    display in red _n "SUBGROUP ANALYSIS BY `subgroup' - {bf:For outcome `y'}"

    ****************************************************
    * RESTORE ORIGINAL MODEL BEFORE ANY POST-ESTIMATION
    ****************************************************
    capture estimates restore MSRRD_MODEL_ORIG

    *******************************************************************
    * Interaction test - This will display the Interaction test p-value
    *******************************************************************
    capture testparm i.`v'#i.`subgroup'
    if (_rc == 0) {
        display in red "Interaction test p-value for {cmd:{it:`v'}} by {cmd:{it:`subgroup':}}"
        display in red "Chi2(" r(df) ") = " %9.3f r(chi2) ",  P = " `fmt_p' r(p)
        display in yellow ""
    }

    ******************************************************************************************************************************
    * STRICT INTERACTION CHECK - This check will ensure the command will not work if interaction term not included in fitted model
    ******************************************************************************************************************************
    local has_interaction = 0
    foreach g2 of local levels {
        capture local test = _b[1.`v'#`g2'.`subgroup']
        if (!_rc) local has_interaction = 1
    }

    if (`has_interaction' == 0) {
        display as error "ERROR: The fitted model does NOT contain the interaction i.`v'#i.`subgroup' / i.`v'##i.`subgroup'."
        exit 198
    }

    ******************
    * SUBGROUP MARGINS
    ******************
    capture estimates restore MSRRD_MODEL_ORIG
	
	* --- SUBGROUP MARGINS VCE CONTROL ---
	if ("`vceuncond'" != "") {
		quietly margins `v'#`subgroup', post vce(unconditional)
	}
	
	if ("`vceuncond'" == "") {
		quietly margins `v'#`subgroup', post
	}
	
    matrix Mg  = r(b)
    matrix VMg = r(V)

    ***************************
    * LOOP OVER SUBGROUP LEVELS
    ***************************
    foreach g of local levels {

		display "______________________________________________________________________"
		display ""
        display "{bf:`subgroup' = `g' (`: label (`subgroup') `g'')}"

        local p0_g = Mg[1,"0.`v'#`g'.`subgroup'"]
        local p1_g = Mg[1,"1.`v'#`g'.`subgroup'"]

        local var_p0_g   = VMg["0.`v'#`g'.`subgroup'","0.`v'#`g'.`subgroup'"]
        local var_p1_g   = VMg["1.`v'#`g'.`subgroup'","1.`v'#`g'.`subgroup'"]
        local cov_p1p0_g = VMg["1.`v'#`g'.`subgroup'","0.`v'#`g'.`subgroup'"]

        ***********************************************************************
        * RR esimation using marginal standardisation and SE using delta method
        ***********************************************************************
        local rr_g       = `p1_g'/`p0_g'
        local logrr_g    = ln(`rr_g')
        local varlogrr_g = (`var_p1_g'/(`p1_g'^2)) + (`var_p0_g'/(`p0_g'^2)) - (2*`cov_p1p0_g'/(`p1_g'*`p0_g'))
        local rr_se_g    = sqrt(`varlogrr_g')
        local rr_lb_g    = exp(`logrr_g' - invnorm(0.975)*`rr_se_g')
        local rr_ub_g    = exp(`logrr_g' + invnorm(0.975)*`rr_se_g')
        local rr_z_g     = `logrr_g'/`rr_se_g'
        local rr_p_g     = 2*normal(-abs(`rr_z_g'))
		local log_rr_se_g = `rr_g'*`rr_se_g'

        ***********************************************************************
        * RD esimation using marginal standardisation and SE using delta method
        ***********************************************************************
        local rd_g      = `p1_g' - `p0_g'
        local vardiff_g = `var_p1_g' + `var_p0_g' - 2*`cov_p1p0_g'
        local rd_se_g   = sqrt(`vardiff_g')
        local rd_lb_g   = `rd_g' - invnorm(0.975)*`rd_se_g'
        local rd_ub_g   = `rd_g' + invnorm(0.975)*`rd_se_g'
        local rd_z_g    = `rd_g'/`rd_se_g'
        local rd_p_g    = 2*normal(-abs(`rd_z_g'))

        ***********************************************
        * SUBGROUP EVENT COUNTS (with pctdp formatting)
        ***********************************************
        quietly count if `subgroup'==`g' & `v'==0 & `y'!=.
        local N0_g = r(N)
        quietly count if `subgroup'==`g' & `v'==0 & `y'==1
        local n0_g = r(N)

        quietly count if `subgroup'==`g' & `v'==1 & `y'!=.
        local N1_g = r(N)
        quietly count if `subgroup'==`g' & `v'==1 & `y'==1
        local n1_g = r(N)

        local pct0_g_raw = 100*`n0_g'/`N0_g'
        local pct1_g_raw = 100*`n1_g'/`N1_g'

        local pct0_g : display `fmt_pct' `pct0_g_raw'
        local pct1_g : display `fmt_pct' `pct1_g_raw'

        *************************
        * SUBGROUP COMBINED TABLE 
        *************************
        
		* Extract value labels for variable
        local lb1 : label (`v') 1
        local lb0 : label (`v') 0
		
		* Fallback if no labels exist
        if ("`lbl'" == "") local lbl "`v'=1"
        if ("`lb0'" == "") local lbl "`v'=0"
		
		local col1_g = "`n1_g'/`N1_g' (" + "`pct1_g'" + "%)"
        local col0_g = "`n0_g'/`N0_g' (" + "`pct0_g'" + "%)"

        display "----------------------------------------------------------------------"
        display %12s " " ///
                %25s "`v'=`lb1'"  ///
                %25s "`v'=`lb0'" 
        display "----------------------------------------------------------------------"

        display %12s "n/N (%)" ///
                %25s "`col1_g'" ///
                %25s "`col0_g'"

        display "----------------------------------------------------------------------"
        display ""
		
        ********************************
        * ORIGINAL SUBGROUP RR/RD OUTPUT
        ********************************
        if ("`subtype'" == "rr" | "`subtype'" == "both") {
			display "***************************"
			display "Direction of comparison is: {cmd:{it:`v'}}=`lb1'     versus     {cmd:{it:`v'}}=`lb0'"
			display "***************************"
			display ""	
            display ///
                "Subgroup RR (95% CI); [SE] = " ///
                `fmt_rr' `rr_g' " (" `fmt_rr' `rr_lb_g' ", " `fmt_rr' `rr_ub_g' "); [" ///
                `fmt_rr' `log_rr_se_g' "]"

            *display "RR P-value for (`: label (`subgroup') `g'') subgroup = " `fmt_p' `rr_p_g'
            display ""
        }

        if ("`subtype'" == "rd" | "`subtype'" == "both") {

            display ///
                "Subgroup RD as percentage (95% CI); [SE] = " ///
                `fmt_rd_pct' (100*`rd_g') "% (" `fmt_rd_pct' (100*`rd_lb_g') "%, " ///
                `fmt_rd_pct' (100*`rd_ub_g') "%); [" `fmt_rd_pct' (100*`rd_se_g') "]"

            display ///
                "Subgroup RD as proportion (95% CI); [SE] = " ///
                `fmt_rd_prop' `rd_g' " (" `fmt_rd_prop' `rd_lb_g' ", " ///
                `fmt_rd_prop' `rd_ub_g' "); [" `fmt_rd_prop' `rd_se_g' "]"

            *display "RD P-value for (`: label (`subgroup') `g'') subgroup = " `fmt_p' `rd_p_g'
			display ""
			display "______________________________________________________________________"
        }
					
    }
	
    capture estimates restore MSRRD_MODEL_ORIG
	
	****************
    * END OF PROGRAM
    ****************
end


