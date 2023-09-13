*! Swain V2, 27 August 2020 (includes F-test and empirical corrections)
*! Swaini V1, 30 March 2013
*! Authors: John Antonakis & Nicolas Bastardoz, University of Lausanne
  program define swaini, rclass
  version 16.1
  args no_vars df N chi too_much
*too many arguments
  if "`too_much'" != "" {
  dis in red "You have entered more than four numbers; recheck your entries. " 
  dis in red "Please enter data after the command swaini as follows: vars df N chi"
  exit 198
  } 
*not enough arguments
  foreach v in no_vars df N chi {
  cap confirm number `=``v'''
  if _rc!=0 {
  dis in red "You have not entered four numbers; recheck your entries. " 
  dis in red "Please enter data after the command swaini as follows: vars df N chi"
  exit 498
  }
  }
*check integers
  foreach v in no_vars df N {
  capture confirm integer number `=``v'''
  if _rc {
  dis in red "Decimal places not allowed (for vars df N); you have to use positive integers. " 
  dis in red "Please enter data after the command swaini as follows: vars df N chi"
  exit 498
  }       
  }
*check positive integers
  if `no_vars'<0 | `df'<0 | `N'<0 | `chi'<0 {
  dis in red "You cannot use negative numbers; recheck your entries. " 
  dis in red "Please enter data after the command swaini as follows: vars df N chi""
  exit 498
  }

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
  
*store saved results in r()
  return scalar swain_p = `p_swain'
  return scalar swain_chi = `swain_chi'
  return scalar swain_corr = `swain'
  return scalar f_test = `f_test'
  return scalar f_test_p = `f_test_p'
  return scalar yuan_chi = `yuan_chi'
  return scalar yuan_p = `yuan_p'


  dis "" 
  dis "Recap of data entered"
  dis "Number of variables in model = "`no_vars'
  dis "Df of model = " `df'
  dis "N size of model = " `N'
  dis "Chi-square of model = " `chi'
  dis "p-value of chi-square of model = " chi2tail(`df',`chi')
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

  
  
  

