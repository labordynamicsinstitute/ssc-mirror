*! garbage_mixl 1.0.0 Jan 2024
*! author MF Jonker
program garbage_mixl
  version 9.2
  if replay() {
    if (`"`e(cmd)'"' != "garbage_mixl") error 301
    Replay `0'
  }
  else {
    Estimate `0'
  }
end

program Estimate, eclass
  syntax varlist(numeric max=1) [if] [in],  ///
         RAND(varlist)        ///
         ID(varname)          ///
         GROUP(varname)[      ///
         BURN(int 50000)      ///
         MCMC(int 50000)      ///
         BERNoulli(real 0.5)  ///
         DIAG                 ///
         INVWISHART           ///
         NOGARBAGE            ///
         NOLAPLACE            ///
         NOMALA               ///
  ]
  
  ** Check that optional inputs are within range **  
  if (`burn'<50000) {
    di as error "Error: The # of burn-in draws must be at least 50,000"
    exit
  }
  if (`mcmc'<50000) {
    di as error "Error: The # of monitored draws must be at least 50,000"
    exit
  } 
  if (`bernoulli'<=0 | `bernoulli'>=1) {
    di as error "Error: The MIXL class-memberhip probability must be between 0 and 1"
    exit
  }  
  
  
  ** Check that id and group variables are numeric **
  capture confirm numeric var `group'
  if _rc != 0 {
    di in r "The group variable must be numeric"
    exit 498
  }
  capture confirm numeric var `id'
  if _rc != 0 {
    di in r "The id variable must be numeric"
    exit 498
  }
  
  
  ** Select the estimation sample **
  marksample touse
  markout `touse' `rand' `id' `group' 
  preserve
    qui keep if `touse'
    
    ** place y in local variable
    gettoken lhs: varlist
        
    ** Check that the dependent variable only takes values 0-1 **
    capture assert `lhs' == 0 | `lhs' == 1
    if (_rc != 0) {
      di in red "The dependent variable must be a 0-1 variable indicating which alternatives are chosen"
      exit 450    
    }

    ** Check that each group has one chosen alternative **
    tempvar n_choices
    sort `group'
    qui by `group': egen `n_choices' = sum(`lhs')
    capture assert `n_choices' == 1
    if (_rc != 0) {
      di in red "At least one choice task does not have one (and only one) chosen alternative"
      exit 498
    }
    
    ** Check that each group has at least two alternatives **
    tempvar n_alts
    qui by `group': egen `n_alts' = count(`lhs')
    capture assert `n_alts' >= 2
     if (_rc != 0) {
      di in red "Each choice task should have at least two alternatives (without missing values)"
      exit 498    
    }
    
    ** Check that each group has an identical number of alternatives **
    capture assert `n_alts' == `n_alts'[1]
     if (_rc != 0) {
      di in red "Not all choice tasks have the same number of alternatives"
      exit 498
    }

    ** Check that each id has at least as many choices as independent variables **
    local n_betas : word count `rand'  
    tempvar n_tasks
    sort `id'
    qui bys `id': egen `n_tasks' = sum(`lhs')
    capture assert `n_tasks' >= `n_betas'
     if (_rc != 0) {
      di as txt "Warning: At least one individual has fewer choice tasks than random variables
      if ("`nogarbage'" == "") {
        di as txt "This is only permitted with the 'nogarbage' model estimation option"
        exit 498
      }
    }

    ** Check for multicollinearity in the random variables **
    qui _rmcoll `rand' 
    if ("`r(varlist)'" != "`rand'") {
      di in red "Some random variables are collinear - check your model specification"
      exit 498
    }
    
    ** Check that the random variables vary within groups **
    sort `group'
    foreach var of varlist `rand' {
      capture by `group': assert `var'==`var'[1]
      if (_rc == 0) {
        di in red "Variable `var' has no within-group variance"
        exit 459    
      }
    }
    
    ** Check for missing values in the random variables **
    foreach var of varlist `rand' {
      capture assert `var', nomissing
      if (_rc == 0) {
        di in red "Variable `var' has missing values"
        exit 459    
      }
    }
    
    
    ** Process data for C++
    display as text "The user interface will freeze during C++ model estimation; please do not close Stata!"
        
    sort `group' `lhs'    
    foreach var of varlist `rand' {  
      qui by `group': replace `var' = `var' - `var'[_N]
    }
    local obs_before = _N
    qui drop if `lhs'==1
    scalar nr_obs = `obs_before' - _N
    sort `id' `group'
    
    
    ** Transfer data to C++ plugin
    scalar nr_rowstask = `n_alts'[1] - 1
    scalar nr_betas = `n_betas'
    scalar nr_burn = `burn'
    scalar nr_mcmc = `mcmc'
    scalar bernoulli_prior = `bernoulli'
    scalar diagonal = 0
    if ("`diag'" != "") {
      scalar diagonal = 1
    }
    scalar inv_wishart = 0
    if ("`diag'" == "" & "`invwishart'" != "") {
      scalar inv_wishart = 1
    }    
    scalar no_garbage = 0
    if ("`nogarbage'" != "") {
      scalar no_garbage = 1
    }
    
    scalar no_laplace = 0
    if ("`nolaplace'" != "") {
      scalar no_laplace = 1
    }
    
    scalar no_mala = 0
    if ("`nomala'" != "") {
      scalar no_mala = 1
    }
    
    tempvar id2
    egen `id2' = group(`id')
    quietly summarize `id2'
    scalar nr_resp = r(max)
    
    quietly by `id': gen nr_rows = _N if _n==_N
    mkmat nr_rows, matrix(nr_rowsXresp) nomissing
    
    ** Specify return matrices for C++ plugin
    tempname MU SD COR GAR PR_GAR
    matrix `MU' = J(`n_betas', 6, .)
    matrix `SD' = J(`n_betas', 6, .)
    matrix `COR' = J(`n_betas'*(`n_betas'-1)/2 , 6, .)
    matrix `GAR' = J(1,6,.)
    quietly levelsof `id', matrow(resp_column)
    matrix `PR_GAR' = J(nr_resp,1,.), resp_column
    matrix colnames `PR_GAR' = "pr_gar" `id'

    ** Run Plugin and obtain results
    plugin call garbage_mixlogit `rand' , `MU' `SD' `COR' `GAR' `PR_GAR'
    
    ** Ereturn estimation results
    ereturn post
    ereturn local cmd "garbage_mixl"
    ereturn local rand `rand'
    
    ereturn scalar nr_resp = nr_resp
    ereturn scalar nr_obs = nr_obs
    ereturn scalar nr_burn = nr_burn
    ereturn scalar nr_mcmc = nr_mcmc
    ereturn scalar nr_betas = nr_betas
    ereturn scalar no_garbage = no_garbage
    ereturn scalar no_laplace = no_laplace
    ereturn scalar no_mala = no_mala
    ereturn scalar bernoulli = bernoulli_prior
    ereturn scalar diagonal = diagonal
    ereturn scalar invwishart = inv_wishart
    
    ereturn matrix mu = `MU'
    ereturn matrix sd = `SD'
    if ("`diag'" == "") {
      ereturn matrix cor = `COR'
    }
    if ("`nogarbage'" == "") {
      ereturn matrix gar = `GAR'
      ereturn matrix pr_gar = `PR_GAR'
    }
    
    ** Print estimation results
    Replay
    
  ** Restore data **
  restore

end

program table_line
  args vname mean stdev mcse median 95LB 95UB
  display in smcl _col(3) as text %13s abbrev("`vname'",13) _col(17) "{c |}" _col(19) as result %8.0g `mean' _col(29) %8.0g `stdev' _col(39) %8.0g `mcse' _col(50) %8.0g `median' _col(61) %8.0g `95LB' _col(72) %8.0g `95UB'
end


program Replay
  syntax [, *]
  ** Display estimation results in Stata table format    
  di in smcl "{hline 80}"
  if e(no_garbage) == 0 {
    if e(diagonal) == 0 {
	    di in smcl " Bayesian garbage class mixed logit" _col(54) as text "number of resp" _col(68) " = " _col(71) "{ralign 9:  `: display e(nr_resp)'}"
    }
    else {
	    di in smcl " Bayesian (diagonal) garbage class mixed logit" _col(54) as text "number of resp" _col(68) " = " _col(71) "{ralign 9:  `: display e(nr_resp)'}" 
    }    
	}
  else {
    if e(diagonal) == 0 {
      di in smcl " Bayesian mixed logit" _col(54) as text "number of resp" _col(68) " = " _col(71) "{ralign 9:  `: display e(nr_resp)'}"
    }
    else {
      di in smcl " Bayesian (diagonal) mixed logit" _col(54) as text "number of resp" _col(68) " = " _col(71) "{ralign 9:  `: display e(nr_resp)'}"  
    }    
  }
  di in smcl _col(54) as text "number of obs" _col(68) " = " _col(71) "{ralign 9: `: display e(nr_obs)'}"
	di in smcl _col(54) as text "MCMC burn-in" _col(68) " = " _col(71) "{ralign 9:  `: display e(nr_burn)'}"
	di in smcl _col(54) as text "MCMC sample" _col(68) " = " _col(71) "{ralign 9:  `: display e(nr_mcmc)'}"
	
	di in smcl "{hline 16}{c TT}{hline 63}"
	** di in smcl _col(17) "{c |}" _col(65) "Equal-tailed"
	di in smcl _col(17) "{c |}" _col(18) "{ralign 9: Mean}"  _col(29) "{ralign 9: Std.Dev.}" _col(38) "{ralign 9: MCSE}"  _col(49) "{ralign 9: Median}"  _col(60) "{ralign 20: [95% Cred. Interval] }"
	
	di in smcl "{hline 16}{c +}{hline 63}"
	di in smcl "{bf: Mean}" _col(17) "{c |}"
    forval i = 1/`e(nr_betas)' {
      local varname = word("`e(rand)'", `i')
      table_line `varname' e(mu)[`i',1] e(mu)[`i',2] e(mu)[`i',3] e(mu)[`i',4] e(mu)[`i',5] e(mu)[`i',6]
    }
    
	di in smcl "{hline 16}{c +}{hline 63}"
	di in smcl "{bf: SD}" _col(17) "{c |}"
	  forval i = 1/`e(nr_betas)' {
      local varname = word("`e(rand)'", `i')
	    table_line `varname' e(sd)[`i',1] e(sd)[`i',2] e(sd)[`i',3] e(sd)[`i',4] e(sd)[`i',5] e(sd)[`i',6]
	  }
  
  if e(diagonal) == 0 {
	  di in smcl "{hline 16}{c +}{hline 63}"
	  di in smcl "{bf: Corr}" _col(17) "{c |}"
      local row = 0
      local end_i = `e(nr_betas)' -1
	    forval i = 1/`end_i'      {
        local begin_j = `i' + 1 
        forval j = `begin_j'/`e(nr_betas)' {
          local row = `row' + 1
          local varname = "β`i'-β`j'"
	        table_line `varname' e(cor)[`row',1] e(cor)[`row',2] e(cor)[`row',3] e(cor)[`row',4] e(cor)[`row',5] e(cor)[`row',6]
        }
	    }
  }
  
  if e(no_garbage) == 0 {
	  di in smcl "{hline 16}{c +}{hline 63}"
	  forval i = 1/1 {
	    table_line "garbage class" e(gar)[`i',1] e(gar)[`i',2] e(gar)[`i',3] e(gar)[`i',4] e(gar)[`i',5] e(gar)[`i',6]
    }
  } 
	
	di in smcl "{hline 16}{c BT}{hline 63}"
  if (e(bernoulli) != 0.5 & e(no_garbage) == 0) {
    di as text "Note: Bernoulli(0" as text e(bernoulli) ") priors are used for MIXL class selection parameters,"
    if e(invwishart) == 1 {
      di as text "      Inverse Wishart prior is used for covariance matrix parameters,"   
    }    
    di as text "      default priors are used for other model parameters"
  }
  else if e(invwishart) == 1 {
	  di as text "Note: Inverse Wishart prior is used for covariance matrix parameters,"
    di as text "      default priors are used for other model parameters"
  }
  else {
    di as text "Note: Default priors are used for model parameters"
  }
  
end

cap program drop garbage_mixlogit
program garbage_mixlogit, plugin using(garbage_mixlogit.plugin)