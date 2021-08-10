*! Swain V2, 27 August 2020 (includes F-test and empirical corrections)
*! Swain V1, 15 March 2013
*! Authors: John Antonakis & Nicolas Bastardoz, University of Lausanne
  
  program define swain, rclass
  version 16.1
  	
    if "`e(cmd)'"!="sem" {
	di in red "This command only works after sem"
	exit 198
	}
	
  *obtain residuals
  qui: estat residuals
  
  *save residuals as a matrix 
  mat r = r(res_cov)
  
  *count the rows of the matrix (to give number of variables)
  local no_vars = rowsof(r)
  
  *sample size of model
  local N = e(N) 
  
  *df of model
  local df = e(df_ms)
  
  *Chi-square of model
  local chi = e(chi2_ms)

  *calculate Swain q
  local swain_q = (sqrt(1+4*(`no_vars')*(`no_vars'+1)-8*`df')-1)/2
  
  *calculate Swain correction
  local swain = 1 - ((`no_vars')*(2*(`no_vars'^2) + 3*(`no_vars') - 1) - ///
                `swain_q'*(2*(`swain_q'^2)+3*(`swain_q')-1))/ ///
				(12*`df'*(`N'-1))
  
  *Calculate statistics and p-values
  local swain_chi = `swain'*`chi'
  local p_swain = chi2tail(`df',`swain_chi') 
  local f_test = `chi'/`df'
  local f_test_p = Ftail(`df',`N'-1,`f_test')
  local yuan_chi = (`N'-(2.381 + 0.367*`no_vars' + 0.003*((`no_vars'*(`no_vars'+1)/2)-`df'-2*`no_vars')))*`chi'/(`N'-1)
  local yuan_p = chi2tail(`df',`yuan_chi') 
  
  *stores saved results in r()
  return scalar swain_p = `p_swain'
  return scalar swain_chi = `swain_chi'
  return scalar swain_corr = `swain'   
  return scalar f_test = `f_test'
  return scalar f_test_p = `f_test_p'
  return scalar yuan_chi = `yuan_chi'
  return scalar yuan_p = `yuan_p'

  dis "" 
  dis in result "Swain correction statistics"
  dis in text "Swain correction factor = " `swain' 
  dis "Swain corrected chi-square = " `swain_chi' 
  dis "p-value of Swain corrected chi-square  = " `p_swain' 
  dis ""   
  dis in result"Empirical correction statistics"
  dis in text "Yuan-Tian-Yanagihara empirically corrected chi-square = " `yuan_chi'
  dis "p-value of Yuan-Tian-Yanagihara empirically corrected chi-square = " `yuan_p'
  dis ""   
  dis in result "F-test statistics"
  dis in text "F-test value = " `f_test'
  dis "p-value of the F-test = " `f_test_p'
  
  dis "" 
  
  end
  exit
