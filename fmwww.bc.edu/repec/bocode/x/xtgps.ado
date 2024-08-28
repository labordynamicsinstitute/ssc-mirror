*! xtgps, version 2.5, Daniel Hoechle, 26aug2024
* 
* This program estimates variants of the GPS-model proposed by 
* Hoechle, Schmid, and Zimmermann (2024).
* 
* The dataset has to be -xtset- and the dataset should be a panel dataset.
* The dependent variable is typically the excess return of individual firms,
* mutual or hedge funds, or of private or institutional investors.
* 
* Syntax: xtgps depvar [subjectvars] [if] [in] [\aweight] [, TSVars(varlist] CONTrolvars(varlist)
*                                                            NOConstant ASE
*                                                            LAG(integer) Level(integer) ALPHAonly 
*                                                            VCEtype(string) RE FE
*																														 SPECtest NOTable]
* 
* The GPS-model implemented in the -xtgps- program contains up to four types
* of explanatory variables:
* 1) The "subjectvars" are subject specific characteristics that may or may not vary over time.
* 2) The "tsvars" comprise the variables of the performance measurement model. These are
*    market level variables that vary over time but not across the subjects.
* 3) The GPS-model includes a full set of interaction variables between the
*    "subjectvars" and the "tsvars".
* 4) Finally, one may also include "controlvars" in the regression. These control variables
*    are arbitrary variables which may vary over time and/or across subjects.
* 
* Option ALPHAonly just displays the coefficient estimates for the variables in the z-vector.
* If this option is not specified, then the coefficient estimates for all the variables of 
* of the Kronecker product of the z-vector and the x-vector plus the CONTrolvars
* are displayed.
*
* Option NOConstant suppresses a constant in the subjectvars. This is useful for estimating
* with the GPS-model a portfolio sort type of an analysis where the subjectvars contain 
* dummy variables for all subject groups.
* 
* The default for option VCEtype is "spatial". However, one can choose among the
* following vcetypes: Robust, BOOTstrap, JACKknife, MODel, CLuster, and SPATial. When "cluster"
* is specified, clustering is over the cross-sectional identifyer (obtained from tsset).
* 
* Option FE estimates the model by aid of the fixed effects estimator.
*
* Option RE estimates the model by aid of the random effects estimator.
*
* Option SPECtest performs the GPS-model specification test proposed in Hoechle, Schmid,
* and Zimmermann (2024).
*
* Option NOTable (requires option SPECtest to be set) omits the regression results upon
* which the GPS-model specification test is built.
*
* If neither option FE or RE is chosen, then the GPS-model is estimated with 
* pooled OLS/WLS.
*
* Option ASE returns asymptotic rather than small sample adjusted standard errors (only
* applies to VCEtype("spatial").
* 
* Note, in order for -xtgps- to work, my -xtscc- program has to be installed.
* 
* ==============================================================================
* Daniel Hoechle, FHNW School of Business
* 26. August 2024  (First version:  29. January 2017)
* ==============================================================================


capture program drop xtgps
program define xtgps , eclass sortpreserve byable(recall) prop(sw)
      
      version 9.2
      
   if !replay() {      
      ereturn clear
      
      syntax varlist(numeric) [if] [in] [aweight/]  ///
            [, TSVars(varlist) CONTrolvars(varlist) NOConstant ///
            LAG(integer 9999) Level(cilevel) ALL ALPHAonly   ///
            VCEtype(string) RE FE ASE SPECtest NOTable]
      marksample touse
      
      * Check if the dataset is tsset:
        qui tsset
        local panelvar "`r(panelvar)'"
        local timevar  "`r(timevar)'"

      * Return an error if "noconstant" is chosen together
        if "`re'"!="" & "`noconstant'"!="" {
          di as err "Option noconstant not allowed for RE estimation"
          exit 101
        }
        if "`fe'"!="" & "`noconstant'"!="" {
          di as err "Option noconstant not allowed for FE estimation"
          exit 101
        }
        if "`re'"=="re" & "`weight'"!="" & !("`vcetype'"=="" | substr("`vcetype'",1,4)=="spat") {
          di as err "Weights are not allowed for RE estimation unless vcetype(spatial) [default] is chosen"
          exit 101
        }


      * Make sure all coefficient estimates are returned if option ALPHAonly is not set
        if "`alphaonly'"=="" {
          local all "all"
        }

      * Split varlist into dependent and independent variables:
        tokenize `varlist'
        local lhsvar "`1'"
        macro shift 1
        local indepvars "`*'"
        local Eqs "`indepvars'"

      * Form the interaction variables:
        local intvars ""
        local intvarnames ""
        qui foreach s2var of local indepvars {
          if "`all'"=="all" {
             local intvars "`intvars' `s2var'"
             local intvarnames "`intvarnames' `s2var'"
          }
          qui foreach s1var of local tsvars {
            local intvar_name=substr("`s2var'",1,14)+"qxq"+substr("`s1var'",1,14)
            tempvar `intvar_name'
            gen ``intvar_name'' = `s2var'*`s1var' if `touse'
            * Gather the names of all interaction variables:
            local intvars "`intvars' ``intvar_name''"         // contains the names of the tempvars
            local intvarnames "`intvarnames' `intvar_name'"   // contains the string names
          }
        }

      * Create a local macro with the expression for the "weights":
        if "`weight'"!="" local Weights "[aweight=`exp']"
				
				
			* Option "spectest": Generation of subject specific time-series averages	
			  if "`spectest'"!="" {
				
				* Error handling in case of option "spectest" being chosen
					if "`fe'"!="" {
						di as err "Option FE is not allowed with option spectest"
						exit 101
					}
					if "`alphaonly'"!="" {
						di as err "Option alphaonly is not allowed with option spectest"
						exit 101
					}
					
				
				* Create a variable accounting for the observation weights
				  tempvar ObsWeight
					tempvar ti
					tempvar XSi
					if "`weight'"==""   qui gen double `ObsWeight' = 1          // perform equal weighted estimation
					else                qui gen double `ObsWeight' = `exp'      // perform weighted estimation
					qui {
						by `panelvar':    egen double `ti' = total(`ObsWeight') if `touse'
					}
					
				* Assemble a list of all control variables, subject characteristics, 
				* and interaction terms in the GPS-model and count the number of 
				* variables per category
					local AllVars "`controlvars' `intvars' `tsvars'"
					local NControlVars = wordcount("`controlvars'")
					local NIVars = wordcount("`intvars'")
					
					
				* Generate variables containing subject means if there is both
				* cross-sectional and temporal variation in the variable
					local tavgvars ""
					local tavgvars_names ""
					local k=0
					local ivar=0
					qui foreach v of local AllVars {
						
						local k = `k' + 1
						
						* Check whether there is temporal and cross-sectional variation
						xtsum `v'
						
						* If there is temporal and cross-sectional variation, then generate
						* a variable containing subject specific time averages
						if r(sd_b)>0 & r(sd_w)>0 {
							
							tempvar `v'_bar
							by `panelvar': egen double ``v'_bar' = total(`v'*`ObsWeight') if `touse'
							replace ``v'_bar' = ``v'_bar'/`ti'
							tempname TotMean
							sum ``v'_bar' if `touse' [aweight=`ObsWeight'], meanonly
							scalar `TotMean' = r(mean)
							replace ``v'_bar' = ``v'_bar' - `TotMean'                         // make variable `v'_bar centered (i.e. mean zero)						
														
							local tavgvars "`tavgvars' ``v'_bar'"                             // names of tempvars 
							
							if `k' > `NControlVars' & `k' <= (`NControlVars' + `NIVars') {
								 local ivar = `ivar' + 1
								 local ivarname =  word("`intvarnames'", `ivar')
								 local tavgvars_names "`tavgvars_names' `ivarname'_bar"         // string names of interaction terms
							}
							else {
								 local tavgvars_names "`tavgvars_names' `v'_bar"                // string names of control variables and factor variables
							}
							
						}						
					}
					
					local tavgvars_names = subinstr("`tavgvars_names'","qxq", "#", .)
					local controlvar_names "`controlvars' `tavgvars_names'"
					local controlvars "`controlvars' `tavgvars'"
					
				}
				

			* Specify temporary names for scalars used later on
							
				tempname corr df_a df_b g_max g_avg g_min sigma theta r2_b r2_o r2_w Chi2
				tempname rho sigma_u sigma_e rmse	df_r df_m lag_f nGroups nObs FV N_clust	
				tempname F_f r2 r2_a mss rss ll ll_0
			
				
* =============================================================================
* Perform the estimation
* =============================================================================

* Case 1: The vcetype has not be chosen or is set to vcetype(spatial). Then, the procedure is
*         estimated by aid of the -xtscc , pooled- program or, in case of option FE is chosen
*         the -xtscc , fe- program.
qui {

			if substr("`noconstant'", 1, 3)=="noc" & "`re'"=="" & "`fe'"=="" {
				 local tsvars ""
			}
			
			if "`all'"=="all" {
				 local indepvars ""
			}


			if ("`vcetype'"=="" | substr("`vcetype'",1,4)=="spat") {

					 xtscc `lhsvar' `controlvars' `indepvars' `intvars' `tsvars'      ///
								 if `touse'  `Weights',  lag(`lag') level(`level') `noconstant' `ase' `fe' `re'

			}
      
      
* Case 2/3: The vcetype is set to robust, bootstrap, jackknife, model, or cluster. Then,
*           the procedure is estimated by pooled OLS regression with Stata's official
*           -regress- command.
      else {
        
        if substr("`vcetype'",1,3)=="mod" & "`fe'"==""  & "`re'"=="" {       
          reg `lhsvar' `controlvars' `indepvars' `intvars' `tsvars' if `touse'     ///
                       `Weights',  level(`level') `noconstant'
        }
				else if substr("`vcetype'",1,3)=="mod" & ("`fe'"=="fe" | "`re'"=="re") {
          xtreg `lhsvar' `controlvars' `indepvars' `intvars' `tsvars' if `touse'   ///
                         `Weights',  level(`level') `fe' `re'
				}
        
        else if "`fe'"=="" & "`re'"=="" & (substr("`vcetype'",1,1)=="r" |          ///
				     substr("`vcetype'",1,4)=="jack" | substr("`vcetype'",1,4)=="boot") {
          reg `lhsvar' `controlvars' `indepvars' `intvars' `tsvars'   ///
                       if `touse'   `Weights', vce(`vcetype') level(`level') `noconstant'
        }
        else if ("`fe'"=="fe" | "`re'"=="re") & (substr("`vcetype'",1,1)=="r" |    ///
				     substr("`vcetype'",1,4)=="jack" | substr("`vcetype'",1,4)=="boot") {
          xtreg `lhsvar' `controlvars' `indepvars' `intvars' `tsvars'   ///
                       if `touse'   `Weights', vce(`vcetype') level(`level') `fe' `re'
        }
				
        else if substr("`vcetype'",1,2)=="cl" & "`fe'"=="" & "`re'"=="" {
          reg `lhsvar' `controlvars' `indepvars' `intvars' `tsvars'   ///
                       if `touse'   `Weights', level(`level') cluster(`panelvar') `noconstant'
        }
				else if substr("`vcetype'",1,2)=="cl" & ("`fe'"=="fe" | "`re'"=="re") {
          xtreg `lhsvar' `controlvars' `indepvars' `intvars' `tsvars'   ///
                       if `touse'   `Weights', level(`level') cluster(`panelvar') `fe' `re'
        }				
        
        else {
          di as err "Option vce() not allowed"
          exit 198
        }   
        
      }
}


* =============================================================================
* Prepare the regression output 
* =============================================================================

* The following part is identical for all estimation methods considered.

  if "`spectest'"!="" {
		local controlvars "`controlvar_names'"
	}

  if "`all'"=="" {
    * Only the indepvars and the controlvars but not the tsvars and intvars
    * have to be displayed.

		* Start with some matrix manipulations in Mata
			scalar N_indctrl = wordcount("`controlvars' `indepvars'")
			mata: N_indctrl = st_numscalar("N_indctrl")
			mata: b=st_matrix("e(b)")
			mata: V=st_matrix("e(V)")
			mata: N_Vars = cols(b)
			if "`noconstant'"=="" | "`re'"=="re" |  "`fe'"=="fe" {
				mata: V=(V[1..N_indctrl,1..N_indctrl],V[1..N_indctrl,N_Vars]\V[N_Vars,1..N_indctrl],V[N_Vars,N_Vars])
				mata: b=(b[1..N_indctrl],b[N_Vars])
			}
			else {
				mata: V=(V[1..N_indctrl,1..N_indctrl])
				mata: b=(b[1..N_indctrl])    
			}
		* Write the matrices V and b back into Stata
			mata: st_matrix("b", b)
			mata: st_matrix("V", V)
		* Next, we have to label the rows and columns of the b and V matrices:
			if "`noconstant'"=="" | "`re'"=="re" |  "`fe'"=="fe" {
				matrix colnames b = `controlvars' `indepvars' _cons
				matrix rownames b = y1
				matrix rownames V = `controlvars' `indepvars' _cons
				matrix colnames V = `controlvars' `indepvars' _cons
			}
			else {
					matrix colnames b = `controlvars' `indepvars' 
					matrix rownames b = y1
					matrix rownames V = `controlvars' `indepvars' 
					matrix colnames V = `controlvars' `indepvars' 	
			}
	
  }
  else {
    * All the coefficient estimates including the interactions and the tsvars have
    * to be displayed.

		* First of all, we obtain the b and V matrices from the -xtscc- program.
			matrix b=e(b)
			matrix V=e(V)

		* Next, we have to label the rows and columns of the b and V matrices appropriately:
			if "`noconstant'"=="" | "`re'"=="re" |  "`fe'"=="fe" {
				matrix colnames b = `controlvars' `intvarnames' `tsvars' _cons
				matrix rownames b = y1
				matrix rownames V = `controlvars' `intvarnames' `tsvars' _cons
				matrix colnames V = `controlvars' `intvarnames' `tsvars' _cons
			}
			else {
					matrix colnames b = `controlvars' `intvarnames' `tsvars' 
					matrix rownames b = y1
					matrix rownames V = `controlvars' `intvarnames' `tsvars' 
					matrix colnames V = `controlvars' `intvarnames' `tsvars' 
			}
  }


* Next, we turn to the command specific tasks.
  if e(cmd)=="xtscc" & "`fe'"=="" & "`re'"=="" {

     * Obtain all matrices and scalars that are of interest from the xtscc-procedure:
        scalar `nObs' = e(N)
        scalar `nGroups' = e(N_g)
        scalar `df_m' = e(df_m)
        scalar `df_r' = e(df_r)
        scalar `FV' = e(F)
        scalar `lag_f' = e(lag)
        scalar `r2' = e(r2)
        scalar `rmse' = e(rmse)

      * Post the "cropped" matrices of the coefficient estimates and the covariance matrix:
        ereturn clear
        ereturn post b V, esample(`touse') depname("`lhsvar'")

      * Post the remaining scalars, macros, and matrices from the pooled OLS regression:
        ereturn scalar N = `nObs'
        ereturn scalar N_g = `nGroups'
        ereturn scalar df_m = `df_m'
        ereturn scalar df_r = `df_r'
        ereturn scalar F = `FV'
        ereturn scalar lag = `lag_f'
        ereturn scalar r2 = `r2'
        ereturn scalar rmse = `rmse'
        ereturn local title "GPS-model (Hoechle,Schmid,Zimmermann '24)"
        ereturn local vcetype "Drisc/Kraay"
				ereturn local method "Pooled OLS/WLS regression"
        ereturn local groupvar "`panelvar'"
        ereturn local predict "xtscc_p"
        if "`weight'"!="" {
            ereturn local wexp = "`exp'"
            ereturn local wtype = "aweight"
        }
        ereturn local cmd "xtgps"
        ereturn local EstCmd "xtscc"
	        
  }
  
	
  if e(cmd)=="xtscc" & "`fe'"=="fe" & "`re'"=="" {

     * Obtain all matrices and scalars that are of interest from the xtscc-procedure:
        scalar `nObs' = e(N)
        scalar `nGroups' = e(N_g)
        scalar `df_m' = e(df_m)
        scalar `df_r' = e(df_r)
        scalar `FV' = e(F)
        scalar `lag_f' = e(lag)
        scalar `r2_w' = e(r2_w)

      * Post the "cropped" matrices of the coefficient estimates and the covariance matrix:
        ereturn clear
        ereturn post b V, esample(`touse') depname("`lhsvar'")

      * Post the remaining scalars, macros, and matrices from the pooled OLS regression:
        ereturn scalar N = `nObs'
        ereturn scalar N_g = `nGroups'
        ereturn scalar df_m = `df_m'
        ereturn scalar df_r = `df_r'
        ereturn scalar F = `FV'
        ereturn scalar lag = `lag_f'
        ereturn scalar r2_w = `r2_w'
        ereturn local title "GPS-model (Hoechle,Schmid,Zimmermann '24)"
        ereturn local vcetype "Drisc/Kraay"
			  ereturn local method "FE (within) regression"
        ereturn local groupvar "`panelvar'"
        ereturn local predict "xtscc_p"
        if "`weight'"!="" {
            ereturn local wexp = "`exp'"
            ereturn local wtype = "aweight"
        }
        ereturn local cmd "xtgps"
        ereturn local EstCmd "xtscc"
	        
  }	
	

  if e(cmd)=="xtscc" & "`fe'"=="" & "`re'"=="re" {

     * Obtain all matrices and scalars that are of interest from the xtscc-procedure:
        scalar `nObs' = e(N)
        scalar `nGroups' = e(N_g)
        scalar `df_m' = e(df_m)
        scalar `df_r' = e(df_r)
        scalar `FV' = e(F)
        scalar `lag_f' = e(lag)
        scalar `r2_w' = e(r2_w)
        scalar `rmse' = e(rmse)
				scalar `sigma_e' = e(sigma_e)
				scalar `sigma_u' = e(sigma_u)
				scalar `rho' = e(rho)

      * Post the "cropped" matrices of the coefficient estimates and the covariance matrix:
        ereturn clear
        ereturn post b V, esample(`touse') depname("`lhsvar'")

      * Post the remaining scalars, macros, and matrices from the pooled OLS regression:
        ereturn scalar N = `nObs'
        ereturn scalar N_g = `nGroups'
        ereturn scalar df_m = `df_m'
        ereturn scalar df_r = `df_r'
        ereturn scalar F = `FV'
        ereturn scalar lag = `lag_f'
        ereturn scalar r2_w = `r2_w'
        ereturn scalar rmse = `rmse'
				ereturn scalar sigma_e = `sigma_e'
				ereturn scalar sigma_u = `sigma_u'
				ereturn scalar rho = `rho'
        ereturn local title "GPS-model (Hoechle,Schmid,Zimmermann '24)"
        ereturn local vcetype "Drisc/Kraay"
			  ereturn local method "RE GLS regression"
        ereturn local groupvar "`panelvar'"
        ereturn local predict "xtscc_p"
        ereturn local cmd "xtgps"
        ereturn local EstCmd "xtscc"
	        
  }	

	
  if e(cmd)=="regress" {
     * Obtain all matrices and scalars that are of interest from the xtscc-procedure:
        scalar `nObs' = e(N)
        scalar `N_clust' = e(N_clust)
        scalar `df_m' = e(df_m)
        scalar `df_r' = e(df_r)
        scalar `FV' = e(F)
        scalar `r2' = e(r2)
        scalar `r2_a' = e(r2_a)
        scalar `mss' = e(mss)
        scalar `rss' = e(rss)
        scalar `rmse' = e(rmse)
        scalar `ll' = e(ll)
        scalar `ll_0' = e(ll_0)
        if "`e(vcetype)'"=="" local vcetype "OLS"
        else                  local vcetype "`e(vcetype)'"
        local clustvar "`e(clustvar)'"
        
      * Count the number of groups:
        tempvar id
        sort `touse' `panelvar' `timevar'
        qui by `touse' `panelvar': gen long `id' = 1 if _n==1 & `touse'
        qui replace `id' = sum(`id')
        scalar `nGroups' = `id'[_N]

      * Post the "cropped" matrices of the coefficient estimates and the covariance matrix:
        ereturn clear
        ereturn post b V, esample(`touse') depname("`lhsvar'")

      * Post the remaining scalars, macros, and matrices from the pooled OLS regression:
        ereturn scalar N = `nObs'
        ereturn scalar N_clust = `N_clust'
        ereturn scalar N_g = `nGroups'
        ereturn scalar df_m = `df_m'
        ereturn scalar df_r = `df_r'
        ereturn scalar F = `FV'
        ereturn scalar r2 = `r2'
        ereturn scalar r2_a = `r2_a'
        ereturn scalar mss = `mss'
        ereturn scalar rss = `rss'
        ereturn scalar rmse = `rmse'
        ereturn scalar ll = `ll'
        ereturn scalar ll_0 = `ll_0'
        ereturn local title "GPS-model (Hoechle,Schmid,Zimmermann '24)"
        ereturn local vcetype "`vcetype'"
        ereturn local clustvar "`clustvar'"
        ereturn local depvar "`lhsvar'"
        ereturn local method "Pooled OLS/WLS regression"
        ereturn local predict "regress_p"
        ereturn local properties "b V"
        ereturn local model "ols"
        ereturn local estat_cmd "regress_estat"
        if "`weight'"!="" {
            ereturn local wexp = "`exp'"
            ereturn local wtype = "aweight"
        }
        ereturn local cmd "xtgps"
        ereturn local EstCmd "regress"
 
  }
  
  else if e(cmd)=="xtreg" {
     * Obtain all matrices and scalars that are of interest from the xtscc-procedure:
        scalar `nObs' = e(N)
        scalar `nGroups' = e(N_g)     // if not available, nGroups is empty.
        scalar `df_m' = e(df_m)
				if "`fe'"=="fe"  scalar `df_r' = e(df_r)
        if "`fe'"=="fe"  scalar `df_b' = e(df_b)
        if "`re'"=="re"  scalar `Chi2' = e(chi2)
				if "`fe'"=="fe"  scalar `FV' = e(F)
				if "`fe'"=="fe"  scalar `df_a' = e(df_a)
				if "`fe'"=="fe"  scalar `F_f' = e(F_f)
				if "`fe'"=="fe"  scalar `corr' = e(corr)
        scalar `r2_o' = e(r2_o)
        scalar `r2_b' = e(r2_b)
        scalar `r2_w' = e(r2_w)
        if "`re'"=="re"  scalar `theta' = e(thta_50)
        scalar `rmse' = e(rmse)
        scalar `rho' = e(rho)
        scalar `sigma_u' = e(sigma_u)
        scalar `sigma_e' = e(sigma_e)
        scalar `sigma' = e(sigma)
        scalar `g_min' = e(g_min)
        scalar `g_avg' = e(g_avg)
        scalar `g_max' = e(g_max)
        
				if "`e(vcetype)'"=="" & "`re'"=="re"       local vcetype "RE"
        else if "`e(vcetype)'"=="" & "`fe'"=="fe"  local vcetype "FE"
				else                                       local vcetype "`e(vcetype)'"
 				local clustvar "`e(clustvar)'"
				local epredict "`e(predict)'"
				local emodel   "`e(model)'"

				if "`fe'"==""   local EstMethod "RE GLS regression"
				else            local EstMethod "FE (within) regression"
				

      * Post the "cropped" matrices of the coefficient estimates and the covariance matrix:
        ereturn clear
        ereturn post b V, esample(`touse') depname("`lhsvar'")

      * Post the remaining scalars, macros, and matrices from the pooled OLS regression:
        ereturn scalar N = `nObs'
        ereturn scalar N_g = `nGroups'
        ereturn scalar df_m = `df_m'
				if "`fe'"=="fe"    ereturn scalar df_r = `df_r'
        if "`fe'"=="fe"    ereturn scalar df_b = `df_b'
        if "`re'"=="re"    ereturn scalar chi2 = `Chi2'
				if "`fe'"=="fe"    ereturn scalar F = `FV'
				if "`fe'"=="fe"    ereturn scalar df_a = `df_a'
				if "`fe'"=="fe"    ereturn scalar F_f = `F_f'
				if "`fe'"=="fe"    ereturn scalar corr = `corr'
        ereturn scalar r2_o = `r2_o'
        ereturn scalar r2_b = `r2_b'
        ereturn scalar r2_w = `r2_w'
        if "`re'"=="re"    ereturn scalar thta_50 = `theta'
        ereturn scalar rmse = `rmse'
        ereturn scalar rho = `rho'
        ereturn scalar sigma_u = `sigma_u'
        ereturn scalar sigma_e = `sigma_e'
        ereturn scalar sigma = `sigma'
        ereturn scalar g_min = `g_min'
        ereturn scalar g_avg = `g_avg'
        ereturn scalar g_max = `g_max'
        ereturn local title "GPS-regression (Hoechle,Schmid,Zimmermann '24)"
        ereturn local vcetype "`vcetype'"
        ereturn local method "`EstMethod'"
        ereturn local properties "b V"
        ereturn local predict "`epredict'"
        ereturn local model "`emodel'"
        if "`re'"=="re"    ereturn local chi2type "Wald"
        ereturn local vcetype "`vcetype'"
        ereturn local clustvar "`clustvar'"
        ereturn local cmd "xtgps"
        ereturn local EstCmd "xtreg"

  }
  
  
  scalar NControls = wordcount("`controlvars'")
  if "`all'"=="all" {
    * If option ALPHAonly is not chosen, then store the estimation results 
	* in various "equations"
	addeqnames NControls `Eqs'
  }
  
  }
  else {      // Replay of the estimation results
        if "`e(cmd)'"!="xtgps" error 301
        syntax [, Level(cilevel)]
  }


	
* =============================================================================
* Display the results 
* =============================================================================

if "`spectest'"=="" | "`notable'"=="" {

  if "`e(EstCmd)'"=="xtscc" & "`fe'"=="" & "`re'"=="" {
       
  * Display the results:
    #delimit ;
    disp _n
      in green `"`e(title)'"'
      _col(50) in green `"Number of obs     ="' in yellow %10.0f e(N) _n
      in green `"Estimation Method: "' in yellow "`e(method)'"
      _col(50) in green `"Number of groups  ="' in yellow %10.0f e(N_g) _n
      in green `"Group variable (i): "' in yellow abbrev(`"`panelvar'"',16)
      _col(50) in green `"F("' in yellow %3.0f e(df_m) in green `","' in yellow %6.0f e(df_r)
      in green `")"' _col(68) `"="' in yellow %10.2f e(F) _n
      in green `"maximum lag: "' in yellow e(lag)   
      _col(50) in green `"Prob > F          =    "' 
      in yellow %6.4f fprob(e(df_m),e(df_r),e(F)) _n
      in green `"vcetype: "' in yellow "Driscoll-Kraay" 
      _col(50) in green `"R-squared         =    "' in yellow %5.4f e(r2) _n
      _col(50) in green `"Root MSE          =  "' in yellow %8.3f e(rmse) _n
      ;
    #delimit cr

  * Estimation results
    ereturn display, level(`level')
    disp ""


  }
	

  if "`e(EstCmd)'"=="xtscc" & "`fe'"=="fe" & "`re'"=="" {
       
  * Display the results:
    #delimit ;
    disp _n
      in green `"`e(title)'"'
      _col(50) in green `"Number of obs     ="' in yellow %10.0f e(N) _n
      in green `"Estimation Method: "' in yellow "`e(method)'"
      _col(50) in green `"Number of groups  ="' in yellow %10.0f e(N_g) _n
      in green `"Group variable (i): "' in yellow abbrev(`"`panelvar'"',16)
      _col(50) in green `"F("' in yellow %3.0f e(df_m) in green `","' in yellow %6.0f e(df_r)
      in green `")"' _col(68) `"="' in yellow %10.2f e(F) _n
      in green `"maximum lag: "' in yellow e(lag)   
      _col(50) in green `"Prob > F          =    "' 
      in yellow %6.4f fprob(e(df_m),e(df_r),e(F)) _n
      in green `"vcetype: "' in yellow "Driscoll-Kraay" 
      _col(50) in green `"Within R-squared  =    "' in yellow %5.4f e(r2_w) _n
      ;
    #delimit cr

  * Estimation results
    ereturn display, level(`level')
    disp ""
		
  }
	

  if "`e(EstCmd)'"=="xtscc" & "`fe'"=="" & "`re'"=="re" {
       
  * Display the results:
    #delimit ;
    disp _n
      in green `"`e(title)'"'
      _col(50) in green `"Number of obs     ="' in yellow %10.0f e(N) _n
      in green `"Estimation Method: "' in yellow "`e(method)'"
      _col(50) in green `"Number of groups  ="' in yellow %10.0f e(N_g) _n
      in green `"Group variable (i): "' in yellow abbrev(`"`panelvar'"',16)
      _col(50) in green `"F("' in yellow %3.0f e(df_m) in green `","' in yellow %6.0f e(df_r)
      in green `")"' _col(68) `"="' in yellow %10.2f e(F) _n
      in green `"maximum lag: "' in yellow e(lag)   
      _col(50) in green `"Prob > F          =    "' 
      in yellow %6.4f fprob(e(df_m),e(df_r),e(F)) _n
      in green `"vcetype: "' in yellow "Driscoll-Kraay" 
      _col(50) in green `"Within R-squared  =    "' in yellow %5.4f e(r2_w) _n
			in green `"corr(u_i, Xb) = "' in yellow `"0 "' in green `"(assumed)"'
			_col(50) in green `"Root MSE          =  "' in yellow %8.4f e(rmse) _n
      ;
    #delimit cr

  * Estimation results
    ereturn display, level(`level') plus
		local c1 = `"`s(width_col1)'"'
		local w = `"`s(width)'"'
		if "`c1'"=="" {
			local c1 13
		}
		else {
			local c1 = int(`c1')
		}
		if "`w'"=="" {
			local w 78
		}
		else {
			local w = int(`w')
		}
		
		local c = `c1' - 1
		local rest = `w' - `c1' - 1
		local rho	: display %10.0g e(rho)
		local sigma_u	: display %10.0g e(sigma_u)
		local sigma_e	: display %10.0g e(sigma_e)
		di in smcl in gr %`c's "sigma_u" " {c |} " in ye %10s "`sigma_u'"
		di in smcl in gr %`c's "sigma_e" " {c |} " in ye %10s "`sigma_e'"
		di in smcl in gr %`c's "rho" " {c |} " in ye %10s "`rho'" /*
			*/ in gr "   (fraction of variance due to u_i)"
		di in smcl in gr "{hline `c1'}{c BT}{hline `rest'}"
    disp ""
		
  }
	
	
	
  
  else if "`e(EstCmd)'"=="regress" {
        
  * Display the results:
    #delimit ;
    disp _n
      in green `"`e(title)'"'
      _col(50) in green `"Number of obs     ="' in yellow %10.0f e(N) _n
      in green `"Method: "' in yellow "`e(method)'"
      _col(50) in green `"Number of groups  ="' in yellow %10.0f e(N_g) _n
      in green `"Group variable (i): "' in yellow abbrev(`"`panelvar'"',16)
      _col(50) in green `"F("' in yellow %3.0f e(df_m) in green `","' in yellow %6.0f e(df_r)
      in green `")"' _col(68) `"="' in yellow %10.2f e(F) _n
      in green `"vcetype: "' in yellow `"`e(vcetype)'"'   
      _col(50) in green `"Prob > F          =    "' 
      in yellow %6.4f fprob(e(df_m),e(df_r),e(F)) _n 
      _col(50) in green `"R-squared         =    "' in yellow %5.4f e(r2) _n
      _col(50) in green `"Adj R-squared     =    "' in yellow %5.4f e(r2_a) _n
      _col(50) in green `"Root MSE          =  "' in yellow %8.3f e(rmse) _n
      ;
    #delimit cr

  * Estimation results
    ereturn display, level(`level')
    disp ""


  }
  
  else if "`e(EstCmd)'"=="xtreg" & "`fe'"=="fe" {
 
  * Header
    #delimit ;
    disp _n
      in green `"`e(title)'"'
      _col(50) in green `"Number of obs     ="' in yellow %10.0f e(N) _n
      in green `"Method: "' in yellow "`e(method)'"
      _col(50) in green `"Number of groups  ="' in yellow %10.0f e(N_g) _n
      in green `"Group variable (i): "' in yellow abbrev(`"`panelvar'"',16)
      _col(50) in green `"F("' in yellow %3.0f e(df_b) in green `","' in yellow e(df_r) in green `")"'
      _col(68) `"="' in yellow %10.2f e(F) _n
      in green `"VCE-Type: "' in yellow `"`e(vcetype)'"'   
      _col(50) in green `"Prob > F          =    "' 
      in yellow %6.4f fprob(e(df_b),e(df_r),e(F)) _n
      `" "' _n
      in green `"R-sq:  within  = "' in yellow %6.4f e(r2_w)
      _col(50) in green `"Obs/group:    min ="' in yellow %10.0f e(g_min) _n
      in green `"       between = "' in yellow %6.4f e(r2_b)
      _col(50) in green `"              avg ="' in yellow %10.2f e(g_avg) _n
      in green `"       overall = "' in yellow %6.4f e(r2_o)
      _col(50) in green `"              max ="' in yellow %10.0f e(g_max) _n
      " " _n
      in green `"corr(u_i, X)   = "' in yellow %6.4f e(corr)   _n
      ;
    #delimit cr

    ereturn display, level(`level') plus
    disp in green "     sigma_u {c |} " in ye %10.0g e(sigma_u)
    disp in green "     sigma_e {c |} " in ye %10.0g e(sigma_e)
    disp in green "         rho {c |} " in ye %10.0g e(rho) ///
         in green "   (fraction of variance due to u_i)"
    disp in smcl in green "{hline 13}{c BT}{hline 64}"
		disp in green "F test that all u_i=0: F(" in yellow e(df_a) in green ", "   ///
		     in yellow e(df_r) in green ") = " in yellow %6.2f e(F_f)               ///
				 _col(62) in green "Prob > F = " in yellow %6.4f fprob(e(df_a),e(df_r),e(F))				 
    disp ""
    
  }
	
  else if "`e(EstCmd)'"=="xtreg" & "`re'"=="re" {
 
  * Header
    #delimit ;
    disp _n
      in green `"`e(title)'"'
      _col(50) in green `"Number of obs     ="' in yellow %10.0f e(N) _n
      in green `"Method: "' in yellow "`e(method)'"
      _col(50) in green `"Number of groups  ="' in yellow %10.0f e(N_g) _n
      in green `"Group variable (i): "' in yellow abbrev(`"`panelvar'"',16)
      _col(50) in green `"chi2("' in yellow %3.0f e(df_m) in green `")"'
      _col(68) `"="' in yellow %10.2f e(chi2) _n
      in green `"VCE-Type: "' in yellow `"`e(vcetype)'"'   
      _col(50) in green `"Prob > chi2       =    "' 
      in yellow %6.4f chiprob(e(df_m),e(chi2)) _n
      `" "' _n
      in green `"R-sq:  within  = "' in yellow %6.4f e(r2_w)
      _col(50) in green `"Obs/group:    min ="' in yellow %10.0f e(g_min) _n
      in green `"       between = "' in yellow %6.4f e(r2_b)
      _col(50) in green `"              avg ="' in yellow %10.2f e(g_avg) _n
      in green `"       overall = "' in yellow %6.4f e(r2_o)
      _col(50) in green `"              max ="' in yellow %10.0f e(g_max) _n
      " " _n
      in green `"corr(u_i, X) = "' in yellow `"0 "' in green `"(assumed)"' _n
      ;
    #delimit cr

    ereturn display, level(`level') plus
    disp in green "     sigma_u {c |} " in ye %10.0g e(sigma_u)
    disp in green "     sigma_e {c |} " in ye %10.0g e(sigma_e)
    disp in green "         rho {c |} " in ye %10.0g e(rho) ///
         in green "   (fraction of variance due to u_i)"
    disp in smcl in green "{hline 13}{c BT}{hline 64}"
    disp ""
		    
  }
	
}  


* =============================================================================
* Option spectest: Display the results of the Hausman specification test
* =============================================================================

  if "`spectest'"!="" {
	
    * Perform the Wald-test for evaluating the validity of the RE assumption
			disp in green "GPS-model: Specification test for the validity of the RE assumption" 		
			disp in green "(" in yellow "H0: RE assumption holds" in green ")"
			test `tavgvars_names'
			disp ""

		* Write the results from the Wald-test into the program's ereturn list:
			ereturn scalar SpecTest_F = r(F)
			ereturn scalar SpecTest_df = r(df)
			ereturn scalar SpecTest_df_r = r(df_r)
			ereturn scalar SpecTest_pval = r(p)
		
	}
	
          
end


* Program for storing the estimation results in various "equations" 

   capture program drop addeqnames
   prog addeqnames, eclass
        args NControls
        local eqnames ""
        local i 2
        while "``i''" != "" {
        local eqnames "`eqnames', ``i''"
        local ++i
        }
        
        tempname b
        matrix `b' = e(b)
        local oldnames: colnames `b'
        local newnames
        local Counter 1
        
        foreach coef of local oldnames {
                if `Counter'<=NControls {
                        local newnames "`newnames'Controls:`coef' "
                }
                else if "`eqnames'"=="" | "`coef'"=="_cons" {
                        local newnames "`newnames'_cons:`coef' "
                }
                else {
                    gettoken suffix rest: coef, parse("qxq")
                    if inlist(`suffix'`eqnames')==1 {
                        if "`rest'"=="" local rest _cons
                        else local rest = substr("`rest'",4,.)
                        local newnames "`newnames'`suffix':`rest' "
                    }
                    else {
                        local newnames "`newnames'_cons:`coef' "
                    }
                }
                local ++Counter
        }
        
        mat coln `b' = `newnames'
        _ereturnrepost
        ereturn repost b = `b', rename
            
   end
  

	
	
* This program is similar to official -ereturn repost- but also works
* with estimates that have not been posted using -ereturn post- and, 
* in addition, allows omitting the e(sample).

* Note: This program has kindly been made available to me by Ben Jann 
*       (program version: 01mar2007)

capture program drop _ereturnrepost
prog _ereturnrepost, eclass
	version 8.2
	syntax [, b(str) v(str) cmd(str) noEsample * ]
//backup existing e()'s
	if "`esample'"=="" {
		tempvar sample
		gen byte `sample' = e(sample)
	}
	local emacros: e(macros)
	foreach emacro of local emacros {
		local e_`emacro' `"`e(`emacro')'"'
	}
	local escalars: e(scalars)
	foreach escalar of local escalars {
		tempname e_`escalar'
		scalar `e_`escalar'' = e(`escalar')
	}
	local ematrices: e(matrices)
	if `"`b'"'=="" & `:list posof "b" in ematrices' {
		tempname b
		mat `b' = e(b)
	}
	if `"`v'"'=="" & `:list posof "V" in ematrices' {
		tempname v
		mat `v' = e(V)
	}
	local bV "b V"
	local ematrices: list ematrices - bV
	foreach ematrix of local ematrices {
		tempname e_`ematrix'
		matrix `e_`ematrix'' = e(`ematrix')
	}
// post results
	if "`esample'"=="" {
		eret post `b' `v', esample(`sample') `options'
	}
	else {
		eret post `b' `v', `options'
	}
	foreach emacro of local emacros {
		eret local `emacro' `"`e_`emacro''"'
	}
	if `"`cmd'"'!="" {
		eret local cmd `"`cmd'"'
	}
	foreach escalar of local escalars {
		eret scalar `escalar' = scalar(`e_`escalar'')
	}
	foreach ematrix of local ematrices {
		eret matrix `ematrix' = `e_`ematrix''
	}
end	


* end of ado-file.
