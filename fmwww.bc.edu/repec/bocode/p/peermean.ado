*! Author: Yujun Lian, arlionn@163.com
*! Version: 1.3, 2025/4/3 1:13
*! Version: 1.2, 2021/1/2 11:50

cap program drop peermean
program define peermean
version 13

  syntax varlist(min=1 numeric ) [if] [in], by(varlist) [Suffix(string) SINGLEzero] 
	
	*local suffix "`gen'"
	if `"`suffix'"' == ""{
	   local suffix="_peer"   
	}
  
* Validate suffix
   foreach k of varlist `varlist' {
	 capture confirm variable `k'`suffix', exact
	 if _rc == 0 {
		di as error "Variable `k'`suffix' already existed, Change another Suffix instead of `suffix'."
		exit 111
	 }
   }	

   	marksample touse
	qui count if `touse'
	if r(N)==0{ 
	   error 2000 
	} 
* 
qui{
  foreach y of varlist `varlist'{
    tempvar ymean Ng w1 w2
	bysort `by':  gen `Ng' = _N if `touse'
	bysort `by': egen `ymean' = mean(`y') if `touse'
	gen double `w1' = . 
	gen double `w2' = .
	replace `w1' = `Ng'/(`Ng'-1) if `Ng'>1&`touse'
	replace `w2' =    1/(`Ng'-1) if `Ng'>1&`touse'
    if "`singlezero'" == ""{
        // When there is only one company in an industry, 
        // the Peer Mean cannot be calculated and is set to a missing value (.)
        replace `w1' = . if `Ng'==1&`touse'  // update 2025.4.3
    }
	else{
        replace `w1' = 0 if `Ng'==1&`touse'
        replace `w2' = 0 if `Ng'==1&`touse'
    }
    
	gen double `y'`suffix' = `w1'*`ymean' - `w2'*`y' if `touse'
	
	label var `y'`suffix' "Peer mean of `y'"
  }  
}
  
end 


*-formula
/*
               1
  y[peerx] = -----(y1+y2+...+y[i-1]+y[i+1]+...+y[N])
              N-1
			  
               1
           = -----(y1+y2+...+y[i-1]+y[i+1]+...+y[N] + y[i] - y[i])
              N-1	
			  
               N               1  
           = -----(y_mean) - ----- y[i]
              N-1			  N-1 
			  
		   = w1*y_mean - w2*y_i	  
*/
