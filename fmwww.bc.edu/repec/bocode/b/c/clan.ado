
*!version 1.3.1 17Jan2023

/* -----------------------------------------------------------------------------
** PROGRAM NAME: clan
** VERSION: 1.3.1
** DATE: 17 Jan 2023
** -----------------------------------------------------------------------------
** CREATED BY: STEPHEN NASH, JENNIFER THOMPSON, BAPTISTE LEURENT
** -----------------------------------------------------------------------------
** PURPOSE: To conduct cluster level analysis of a cluster randomised trial
** -----------------------------------------------------------------------------
** UPDATES:
** v1.3.1: Renaming rater/rated to irr/rd, and scale() to per()
**
** v1.2.2
** Option to rescale of follow up time added
** Effect for mean difference renamed to meand from mean
** -----------------------------------------------------------------------------

*/

prog define clan , eclass
	version 14.2
	syntax varlist(min = 1 numeric fv) [if] [in], ///
		arm(varname numeric) CLUSter(varname numeric) EFFect(string) ///
		[Level(cilevel) STRata(varname numeric) FUPtime(string) ///
		SAVing(string) plot]


	qui {

	
	*************************************
	**
	** DATA SECTION
	**
	*************************************
	
	
		marksample touse
		preserve // We're going to change the data - drop rows and create new vars
		capture keep if `touse' // Get rid of un-needed obs now
		

		* Check no interactions
			if strmatch(`"`varlist'"' , "*#*") {
				dis as error "Interactions are not permitted"
				exit 101
			}
		
		** Drop any row with missing data for any covariate, outcome, arm or strata
			local vlist_no_i_dot = subinstr(`"`varlist'"' , "i." , "" , .)
			foreach v of varlist `vlist_no_i_dot' `arm' `strata' `cluster' {
				drop if missing(`v')
			}

		** Check that there are observations
			count
			if r(N) == 0 { 
				error 2000 
			}

			
	*************************************
	**
	** CHECK THE PARAMETERS and CREATE SOME LOCALS
	**
	*************************************

	
		* Check effect is valid
			if inlist(`"`effect'"', "rr", "rd", "irr", "ird", "meand") == 0 {
				dis as error "Unrecognised {bf:effect} option. Should be one of {bf:rr}, {bf:rd}, {bf:irr}, {bf:ird} or {bf:meand}"
				exit 198
			}

		*Check arm is valid
			* Is arm coded 0, 1?
			tab `arm'
			if r(r) != 2 {
				dis as error "There must be exactly two levels in variable {bf:arm}"
				exit 198
			}
			levelsof `arm' , local(arm_levs)
			if "`arm_levs'" != "0 1" {
				dis as error "{bf:arm} must be coded 0/1"
				exit 198
			}
			* Arm not constant within cluster
			tempname minarm maxarm
			bysort `cluster': egen `minarm' = min(`arm')
			bysort `cluster': egen `maxarm' = max(`arm')
			count if `minarm' != `maxarm' 
			if r(N) > 0 {
				dis as error "{bf:arm} variable should not vary within cluster"
				exit 198
			}				

		** Stratified analysis checks and macro creation
			local stratified = 1
			if "`strata'" == "" local stratified = 0
			else {
				local istrata i.`strata'	
				
				* Check strata var is a cluster-level covariate
				cap drop `minarm' `maxarm'
				bysort `cluster': egen `minarm' = min(`strata')
				bysort `cluster': egen `maxarm' = max(`strata')
				count if `minarm' != `maxarm'  
				if r(N) > 0 {
					dis as error "{bf:strata} variable should not vary within cluster"
					exit 198
				}
				
				* Check strata is not specified in the varlist as well
				*This would double count strata in penalising DF
				if `"`varlist'"' != subinword(`"`varlist'"', `"`strata'"', "", .) | ///
					`"`varlist'"' != subinword(`"`varlist'"', `"`istrata'"', "", .) {
					dis as error `"{bf:`strata'} cannot be specified in both varlist and strata"'
					exit 198
				}
			}
		
		** Is this an adjusted analysis?
			if wordcount(`"`varlist'"')>1 local adjusted = 1
			else local adjusted = 0
		
		**Create a macro with ratio of diff for eff text in output
			if inlist(`"`effect'"', "rr", "irr") ==1 local comptype "ratio"
			else local comptype "diff."
		
		** Calculate the upper tail area to use in the calculation of the CI
			local uppertail = 0.5 * (100 - `level') / 100


		** Saving dataset option
			tokenize "`saving'", parse(",")
			local savingfile `1'
			local savingreplace `3'	
		

	*************************************
	**
	** Check the options are correct for outcome
	**
	*************************************

	
		* Run subroutines for each type of outcome
			if inlist(`"`effect'"', "rd", "rr") == 1 {
				clanbin `0'
			}
			else if inlist(`"`effect'"', "ird", "irr") == 1 {
				clanrate `0'
				local fuptime `r(fuptime)'
				local scale `r(scale)'
			}
			else {
				clancts `0'
			}
			local efftype  "`r(efftype)'"
			local model  "`r(model)'"
		
		
	*************************************
	**
	** Calculate simple numbers: cluster, strata, DF
	**
	*************************************
	
	
		tempvar clussiz obs
		
		* Dummy variable so we can count observations
			gen byte `obs' = 1
		
		* Number of clusters
			tab `cluster' if `arm' == 0
				local c0 = r(r)
			tab `cluster' if `arm' == 1
				local c1 = r(r)
			local c = `c0' + `c1'
		
		* Number of observations and cluster size
			local num_obs = _N
			local clus_siz_avg = `num_obs' / `c'
			bysort `cluster': gen `clussiz' = _N
			sum `clussiz'
			local clus_siz_min = r(min)
			local clus_siz_max = r(max)
		
		* Number of strata
			if `stratified'==1 {
				tab `strata'
				local numstrata = r(r)
				local numstrat_minusone = `numstrata' - 1
				local name_cluster_covars `strata'
			}
			else {
				local numstrata = 0
				local numstrat_minusone = 0
			}

		* Count cluster level covariates
			local num_cluster_covars = 0
			* Get list of clusters
			levelsof `cluster' , local(cluster_levels)
			
			foreach v in `varlist' {
				
				if substr("`v'", 2,1) == "." { // If factor var
					local num_clv_this_fv = 0
					local simple_var = substr("`v'" , 3 , . )
					levelsof `simple_var' , local(var_levels)

					foreach j of local var_levels { // var levels
						local total_sd = 0
						
						foreach i of local cluster_levels { // clusters
							sum `j'.`simple_var' if `cluster' == `i'
							local total_sd = `total_sd' + r(Var)
						} // end i loop
						
						if `total_sd' == 0 { // We've found a cluster-level variable
							local num_cluster_covars = `num_cluster_covars' + 1
							local num_clv_this_fv = `num_clv_this_fv' + 1
						} // end if
						
					} // end j loop
					
					if `num_clv_this_fv' >= 2 local num_cluster_covars = `num_cluster_covars' - 1
					if `num_clv_this_fv' >= 1 local name_cluster_covars `name_cluster_covars' `v'			
				} // end Factor variable if substr
				
				else { // normal var
					local total_sd = 0
					
					foreach i of local cluster_levels {
						sum `v' if `cluster' == `i'
						local total_sd = `total_sd' + r(Var)
					} // end i loop
					
					if `total_sd' == 0 {
						local num_cluster_covars = `num_cluster_covars' + 1
						local name_cluster_covars `name_cluster_covars' `v'
					}
					
				} // end else
				
			} // end v for loop
			
		* Degrees of freedom
			local df = `c0' + `c1' - 2 - `num_cluster_covars' - `numstrat_minusone'
			local df_penal = (`num_cluster_covars' + `numstrat_minusone')  // To add note to output


	*************************************
	**
	** Create exposure variables
	**
	*************************************
	
	
			tempvar obs exposure
		
		* var to count observations
			gen `obs' = 1 

		*Variable to count exposure of each observation
			if inlist(`"`effect'"', "ird", "irr") == 1 {
				gen `exposure' = `fuptime' / `scale'
				local exposureoption `"exposure(`exposure')"'
			}
			else {
				gen `exposure' = 1
				local exposureoption = ""
			}

	
	*************************************
	**
	** Run adjusted model
	**
	*************************************

	
		tempvar expected 

		* If adjusted analysis, we need to get expected number from a 
		* regression WITHOUT the treatment arm BEFORE we collapse data
			if `adjusted' == 1 {
				`model' `varlist' `istrata' , `exposureoption'
				predict `expected' 
				/*The default for regress is lin predictor; logit is probability; poisson no of events in futime*/
			}
			else gen `expected' = .

	
	*************************************
	**
	** Collapse the data
	**
	*************************************


		*Collapse the data
			tempvar zero howmanyzeros cs csformodel actual_cs

			local outcome = word("`varlist'" , 1)

			collapse (sum) `outcome' `exposure' `obs' `expected', by(`cluster' `strata' `arm')
		
		* If we'll be taking logs, add 0.5 to all if one cluster prev is zero
		* Calculate residual
			if inlist(`"`effect'"', "rr", "irr") == 1 {
				gen byte `zero' = 1 if `outcome' == 0 // Marks cells with zero cases
				gen `howmanyzeros' = sum(`zero') // Makes a running total of number of cells with zero prev
				if `howmanyzeros'[_N] > 0.5  { // Look at just the end of the running total
					replace `outcome' = `outcome' + 0.5 
					noi dis as text "Warning: at least one cluster has zero prevalence, so 0.5 will be added to every cluster total" 
				}
				
				if `adjusted' == 0 gen double `cs' = `outcome' / `exposure'
				else gen double `cs' = `outcome' / `expected'
				
				gen double `csformodel' = log(`cs')
				
			} // end of ratio if 
			else {
				if `adjusted'==0 gen double `cs' = `outcome' / `exposure'
				else gen double `cs' = (`outcome' - `expected') / `exposure'	
				
				gen double `csformodel' = `cs'
			}
		
		* Calculate unadjusted arm means (geo for ratio, arith for diff)
			gen double `actual_cs' = `outcome' / `exposure' // For saving display
			forvalues i = 0/1{	
				ameans `actual_cs' if `arm' == `i'
					if inlist(`"`effect'"', "rr", "irr") == 1 local actual_cs`i' = r(mean_g)
					else local actual_cs`i' = r(mean)
			}
	
	
	*************************************
	**
	** Run second stage regression model
	**
	*************************************
	
	
		* Perform regression on the cluster summaries and extract results
			tempname A b V se beta ts pval beta_lci beta_uci
			regress `csformodel' i.`arm' `istrata'
				mat `A' = r(table)
				mat `b' = e(b)
				mat `V' = e(V)
				scalar `se' = `A'[2,2]
				scalar `beta' = `A'[1,2]
				scalar `ts' = (`beta' / (`se'))
				scalar `pval' = 2 * ttail(`df', abs(`ts'))
				scalar `beta_lci' = `beta' - invttail(`df', `uppertail') * `se'
				scalar `beta_uci' = `beta' + invttail(`df', `uppertail') * `se'
				
			if inlist(`"`effect'"', "rr", "irr") == 1 {
				scalar `beta' = exp(`beta')
				scalar `beta_lci' = exp(`beta_lci')
				scalar `beta_uci' = exp(`beta_uci')
			}
			
	
	*************************************
	**
	** Plot
	**
	*************************************

	
		* Plot of cluster prevelances
			if "`plot'" != "" dotplot `cs' , over(`arm') center nx(10) xtitle("") ///
				xlabel(0 "Arm 0" 1 "Arm 1") xtick( , notick) xmtick( , notick) ///
				ytitle("Cluster summaries") legend(off)
		
	
	*************************************
	**
	** Saving
	**
	*************************************

	
		* Saving cluster-level dataset				
			if "`saving'" != ""  {
				local savevars `cluster' `arm' `strata' `outcome'  `exposure' `obs' `actual_cs'
				if `adjusted' == 1  local savevars `savevars' `cs'
				if inlist(`"`effect'"', "rr", "irr") == 1 local savevars `savevars' `csformodel'
				keep `savevars'
				rename `obs' clustersize
				
				if inlist(`"`effect'"', "rr", "rd") == 1 {
					rename `actual_cs' prevalence
					drop `exposure'
				}
				else if  inlist(`"`effect'"', "irr", "ird") == 1 {
					rename `actual_cs' rate
					rename `exposure' fuptime
				}
				else { // continuous outcome if
					rename `actual_cs' mean
					rename `outcome' outcome_total
					drop `exposure'
				}
				
				cap: rename `cs' adj_clus_summ
				cap: rename `csformodel' log_clus_summ

				foreach var of varlist _all {
					label var `var' ""
				}
				label data ""
				compress
				
				save "`savingfile'", `savingreplace'
			}

			

		* Restore the users data
			restore	
	
	
	*************************************
	**
	** Return list
	**
	*************************************
	
	
		* Ereturns from analysis

			ereturn post `b' `V' , obs(`c') depname(`outcome') esample(`touse') dof(`df')
			ereturn local depvar "`outcome'"
			ereturn scalar p = `pval'
			ereturn scalar lb = `beta_lci'
			ereturn scalar ub = `beta_uci'
			ereturn scalar `effect' = `beta'
		
		* Common ereturns

			ereturn scalar level = `level'
			ereturn local cmdline `"`0'"'
			ereturn local cmd "clan"
	
				
	} // end quietly
	
			
	*************************************
	**
	** Display results
	**
	*************************************
			
			
		*Create local macros for names
			if `adjusted' == 1 | `stratified' == 1  local effabbrev "Adj. `comptype'"
			else local effabbrev = strproper("`comptype'")
			
		* Header of output table
		
			noi dis as text _n "Number of clusters (total): " as result `c'	_col(51) as text "Number of obs     = " as result %8.0gc `num_obs'
			noi dis as text "Number of clusters (arm 0): " as result `c0'	_col(51) as text "Obs per cluster:"                                
			noi dis as text "Number of clusters (arm 1): " as result `c1'	_col(65) as text "min = " as result %8.1gc `clus_siz_min'         
			noi dis as text 												_col(65) as text "avg = " as result %8.1gc `clus_siz_avg'          
			noi dis as text													_col(65	) as text "max = " as result %8.1gc `clus_siz_max'         			
		
		*Output table
		
			tempname Tab

			.`Tab' = ._tab.new, col(8) lmargin(0) 

			// column           1      2     3      4     5     6		7	  8
			.`Tab'.width       12    |11     11     8    5     8     11     11
			.`Tab'.titlefmt  %11s    %10s    %10s  %5s   %4s   .   %22s	    .
			.`Tab'.pad          .     1      0      0     0     0      1     1
			.`Tab'.numfmt       .  %9.0g   %9.0g  %6.3f %4.0f %7.4f  %10.0g %10.0g  

			.`Tab'.sep, top
			.`Tab'.titles  "" "Estimate" "Std. Err." "t" "df" "P>|t|"  `"[`level'% Conf. Interval]"' ""
			.`Tab'.sep, middle


			.`Tab'.row `"`efftype'"' /*
					*/ "" /*
					*/ "" /*
					*/ "" /*
					*/ "" /*
					*/ "" /*
					*/ ""/*
					*/ ""
			
			.`Tab'.row `"0"' /*
					*/ `actual_cs0' /*
					*/ "" /*
					*/ "" /*
					*/ "" /*
					*/ "" /*
					*/ ""/*
					*/ ""
					
			.`Tab'.row `"1"' /*
					*/ `actual_cs1' /*
					*/ "" /*
					*/ "" /*
					*/ "" /*
					*/ "" /*
					*/ ""/*
					*/ ""
					
			.`Tab'.sep, middle
			
			.`Tab'.row `"`effabbrev'"' /*
					*/ `beta' /*
					*/ `se' /*
					*/ `ts' /*
					*/`df' /*
					*/ `pval' /*
					*/ `beta_lci' /*
					*/ `beta_uci'  

			.`Tab'.sep, bottom
			
		*Footnotes
			if (`df_penal'>0)  noi dis as text "Note: Degrees of freedom adjusted " ///
				"for the cluster covariate(s): `name_cluster_covars'" 
			if  inlist(`"`effect'"', "irr", "ird") == 1 {
				if (`scale') != 1 noi dis as text "Note: Rates are per `scale'"	
				}		
			if "`saving'" != "" noi dis as text "Cluster level dataset saved in `savingfile'"
		
			
			
end


********************************************************************************
* Subroutines for differnt types of outcomes
********************************************************************************

program clanrate, rclass
	syntax varlist(numeric fv) [if] [in], ///
		arm(varname numeric) CLUSter(varname numeric) EFFect(string) FUPtime(string) ///
		[Level(cilevel) STRata(varname numeric)  ///
		SAVing(string) plot]
		
	* Check outcome is non-negative
		local outcome = word("`varlist'" , 1)

		summarize `outcome'

        if r(min) < 0 {
                di in red "`outcome' must be greater than or equal to zero"
                exit 459
        }
        if r(min) == r(max) & r(min) == 0 {
                di in red "`outcome' is zero for all observations"
                exit 498
        }
	
	tokenize `"`fuptime'"', parse(",")
	local expvar `1'
	local scaleopt `3'
	
	* first word is a numeric variable
		confirm numeric variable `expvar'
		summarize `expvar'

        if r(min) < 0 {
                di in red "`expvar' must be greater than or equal to zero"
                exit 459
        }
        if r(min) == r(max) & r(min) == 0 {
                di in red "`expvar' is zero for all observations"
                exit 498
        }
	
	* Check scale is correctly specified (per())
		if length(`"`scaleopt'"') > 0 {
			local scaleopt = subinstr(`"`scaleopt'"', " ","",.)
			
			if substr(`"`scaleopt'"',1,4) != "per(" {
				dis as error "Invalid option in {bf:fuptime}"
				exit 119
			}
			
			if substr(`"`scaleopt'"',- 1,1) != ")" {
				dis as error "Invalid option in {bf:fuptime}"
				exit 119
			}		
			
			local scale = substr(`"`scaleopt'"',5, length(`"`scaleopt'"') - 5)
			confirm number `scale'
			if `scale' <=0 {
				error 109
			}
		}
		else local scale 1
	
	*Return values
		return local model "poisson"
		return local efftype "Rate"
		return local fuptime "`expvar'"
		return local scale `scale'
end

********************************************************************************
* Binary program
********************************************************************************

program clanbin, rclass
	syntax varlist(numeric fv) [if] [in], ///
		arm(varname numeric) CLUSter(varname numeric) EFFect(string) ///
		[Level(cilevel) STRata(varname numeric)  ///
		SAVing(string) plot]
		
	* Check 2 levels for outcome var
		local outcome = word("`varlist'" , 1)
		levelsof `outcome' , local(out_levs)
		if "`out_levs'" != "0 1" {
			dis as error "Outcome must be 0/1 with `effect' option"
			exit 198
		}

	*Return values
	return local model "logit"
	return local efftype "Risk"
end

********************************************************************************
* Continuous program
********************************************************************************

program clancts, rclass
	syntax varlist(numeric fv) [if] [in], ///
		arm(varname numeric) CLUSter(varname numeric) EFFect(string) ///
		[Level(cilevel) STRata(varname numeric) SAVing(string) plot]
	
	*Return values
		return local model "regress"
		return local efftype "Mean"
end



