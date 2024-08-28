*! xtpsort, version 1.5, Daniel Hoechle, 26aug2024
* 
* This program implements the portfolio sorts approach (also known as the Jensen
* alpha approach) which is routinely applied in empirical finance research.
* 
* 
* 
* Syntax:
* =======
* 
*   xtpsort depvar [indepvar] [if] [in] [, ONEgroup Groupvar(variable) LAG(nlags) 
*                                          ROBust ASE Level(cilevel) IPW(variable)]
*   xtpsort is byable.
* 
* Notes:
* ======
* 
* (1) The dataset has to be tsset.
* (2) It is assumed that the indepvars are identical for all subjects (e.g. firms or individual investors)
* (3) Option "ase" provides asymptotic standard errors
* (4) Option "ipw" contains the intra-period weight of the observations. This is particularly
*     useful if one wants to consider value-weighted portfolio returns. 
* 
* ==============================================================
* Daniel Hoechle, FHNW Business School
* 26. August 2024 (First version:  29. January 2017)
* ==============================================================

capture program drop xtpsort
program define xtpsort , eclass sortpreserve byable(recall)
  version 9.2

  if !replay() {
      tempname b V T N_p F r2 r2_a ll ll_0 df_m df_r lagz TotObs Tipw Depw
      tempvar lhsvar
      tempvar XRet
      ereturn clear
      syntax varlist(numeric) [if] [in] [, SINGLEgroup GROUPvar(varname) LAG(integer 9999) Level(cilevel) VCEtype(string) ROBust ASE IPW(varname)]
      marksample touse
      
      * Check if the dataset is tsset:
        qui tsset
        local panelvar "`r(panelvar)'"
        local timevar  "`r(timevar)'"
        
      * Split varlist into dependent and independent variables:
        tokenize `varlist'
        local depvar "`1'"
        macro shift 1
        local rhsvars "`*'"

      * preserve the dataset:
        preserve
        
      * Count the total number of observations:
        qui drop if mi(`groupvar') | `touse'==0
        qui count
        scalar `TotObs' = r(N)
        tempvar NPanels
        egen `NPanels' = tag(`panelvar')
        qui count if `NPanels'==1 & `touse'
        scalar `N_p' = r(N)

      * Collapse (and potentially reshape) the dataset:
        if "`ipw'"!="" {
            bys `timevar' `groupvar': egen double `Tipw' = total(`ipw') if `touse'
            gen double `Depw' = (`ipw'/`Tipw')*`depvar' if `touse'
						if "`rhsvars'"!="" {
							collapse (sum) `depvar'=`Depw' (max) `rhsvars' if `touse', by(`groupvar' `timevar')
						}
						else {
						  collapse (sum) `depvar'=`Depw' if `touse', by(`groupvar' `timevar')
						}
        }
        else {
						if "`rhsvars'"!="" {
							collapse (mean) `depvar' (max) `rhsvars' if `touse', by(`groupvar' `timevar')
						}
						else {
						  collapse (sum) `depvar'=`Depw' if `touse', by(`groupvar' `timevar')
						}
        }
      
        if "`groupvar'"!="" {
            qui reshape wide `depvar', i(`timevar') j(`groupvar')
            gen `lhsvar' = `depvar'1 - `depvar'0
        }
        else {
            gen `lhsvar' = `depvar'
        }
        qui tsset `timevar'
        
      * Perform the time-series regression of the second step of the portfolio
      * sorts approach:
      	if `lag'==9999 {      // Note: Option lag(#) overrules options robust and vcetype
            qui reg `lhsvar' `rhsvars' , vce(`vcetype'`robust')
            * Store the estimation results:
              matrix `b' = e(b)
              if "`vcetype'`robust'"==""                local vcetype "OLS"
              else if substr("`robust'",1,3)=="rob"     local vcetype "Robust"
              else     local vcetype "`vcetype'"                                  
              
              if "`ase'"!="" {
                  matrix `V' = e(V)
                  local nParam=colsof(`V')
  			             matrix `V' = (e(N)-`nParam')/e(N)*`V'
                  local vcetype "as. `vcetype'"
                  capture qui test `rhsvars', min   // Perform the F-Test
                  capture scalar `F' = r(F)
              }
              else {
                  matrix `V' = e(V)
                  scalar `F' = e(F)
              }
              
              scalar `T' = e(N)
              scalar `df_m' = e(df_m)
              scalar `df_r' = e(df_r)
              scalar `r2' = e(r2)
              scalar `r2_a' =  e(r2_a)
              scalar `ll' = e(ll)
              scalar `ll_0' =  e(ll_0)
      	}
      	else {
      		  qui newey `lhsvar' `rhsvars', lag(`lag')
            * Store the estimation results:
              matrix `b' = e(b)
            
              if "`ase'"!="" {
                  matrix `V' = e(V)
                  local nParam=colsof(`V')
  			             matrix `V' = (e(N)-`nParam')/e(N)*`V'
                  local vcetype "as. Newey-West"
                  capture qui test `rhsvars', min   // Perform the F-Test
                  capture scalar `F' = r(F)
              }
              else {
                  matrix `V' = e(V)
                  local vcetype "Newey-West"
                  scalar `F' = e(F)
              }
            
              scalar `T' = e(N)
              scalar `df_m' = e(df_m)
              scalar `df_r' = e(df_r)
              scalar `lagz' = e(lag)
            
            * Get the remaining stats from estimating an OLS regression:
              qui reg `lhsvar' `rhsvars'
              scalar `r2' = e(r2)
              scalar `r2_a' =  e(r2_a)
              scalar `ll' = e(ll)
              scalar `ll_0' =  e(ll_0)
      	}

      * restore the dataset: 
        restore
      
      * Post the results in e():
        ereturn clear
        ereturn post `b' `V', esample(`touse') depname("`depvar'")
        ereturn scalar N_tot = `TotObs'
        ereturn scalar N_p = `N_p'
        ereturn scalar N = `T'
        ereturn scalar df_m = `df_m'
        ereturn scalar df_r = `df_r'
        ereturn scalar F = `F'
        ereturn scalar r2 = `r2'
        ereturn scalar r2_a = `r2_a'
        ereturn scalar ll = `ll'
        ereturn scalar ll_0 = `ll_0'
        ereturn local title "Portfolio Sorts Approach"
        ereturn local vcetype "`vcetype'"
        if `lag'!=9999 ereturn scalar lag = `lagz'
        ereturn local method "CalTime procedure"
        ereturn local cmd "xtpsort"
  }
  else {      // Replay of the estimation results
        if "`e(cmd)'"!="xtpsort" error 301
        syntax [, Level(cilevel)]
  }
  
  * Display the results
              
  * Header
    #delimit ;
    disp _n
      in green `"`e(title)'"'
      _col(50) in green `"Num. obs (total)  ="' in yellow %10.0f e(N_tot) _n
      _col(50) in green `"Num. groups       ="' in yellow %10.0f e(N_p) _n
      _col(50) in green `"Num. time periods ="' in yellow %10.0f e(N) _n
      _col(50) in green `"F("' in yellow %3.0f e(df_m) in green `","' in yellow %6.0f e(df_r)
      in green `")"' _col(68) `"="' in yellow %10.2f e(F) _n
      _col(50) in green `"Prob > F          =    "' 
      in yellow %6.4f fprob(e(df_m),e(df_r),e(F)) _n
      in green `"#obs. in TS-regression of 2nd step: "' in yellow e(N)
      _col(50) in green `"R-squared         =    "' in yellow %5.4f e(r2)
      ;
    #delimit cr

  * Estimation results
    ereturn display, level(`level')
        
end
