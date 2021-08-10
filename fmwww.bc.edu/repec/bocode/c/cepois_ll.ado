*! version 2.0  6Aug2004  Joseph Hilbe
* CENSORED POISSON REGRESSION : LOG-LIKELIHOOD FUNCTION
program cepois_ll
  version 8.0
  args lnf theta1
  local censor = "$S_cen"
   
  if "$S_mloff" != "" {
      tempvar Io
      qui gen double `Io' = `theta1' + $S_mloff
  }
  else  local Io `theta1'

  qui replace `lnf' = cond(`censor'==1, /*
    */ -exp(`Io') + $ML_y1*`Io' - lngamma($ML_y1+1), /*
    */ ln(gammap($ML_y1,exp(`Io'))) )
 qui replace `lnf' = ln(1-gammap($ML_y1+1,exp(`Io'))) if `censor'==-1
end









  
