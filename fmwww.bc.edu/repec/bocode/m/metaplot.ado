program define metaplot
   version 10.0
   syntax varlist(min=2 max=6 default=none numeric) [if] [in] [, id(varname) `options' *]
   
   tokenize `varlist'

   preserve

   tempname df
   * Dealing with if and in options
   if ("`if'"!="") {
	qui keep `if'
   } 
   if ("`in'"!="") {
	qui keep `in'
   } 

   
   tempvar s Q K df2 H2 I2 SElnH LB_H_III UB_H_III  I22 levelci clvlci level pvalue
   tempvar LB_I2_HT UB_I2_HT varI2 lb_I2 ub_I2 lb_I22 ub_I22
   tempvar UB_NC LB_NC LB_H_H UB_H_H LB_I2_H UB_I2_H nc
   tempvar Q_ove I2_ove LI2_ove UI2_ove pvalue_ove K_ove
   qui {
   //gen `K_ove'=.
   gen `Q_ove'=.
   gen `I2_ove' =.
   gen `LI2_ove' =.
   gen `UI2_ove' =.
   gen `pvalue_ove'=.
   gen `LB_H_III'=.
   gen `UB_H_III'=.
   gen `pvalue'=.
   gen `I2'=.
   gen `I22'=.
   gen `level'= $S_level
   gen `levelci' = `level' * 0.005 + 0.50
   gen `clvlci' = 1- `levelci'
   gen `Q' =.
   gen `s'=_n
   	gen `LB_I2_H'=.
	gen `UB_I2_H'=.
	gen `LB_H_H'=.
	gen `UB_H_H'=.
	gen `LB_I2_HT'=.
	gen `UB_I2_HT'=.
	gen `lb_I2'=.
	gen `ub_I2'=.
	gen `H2'=.
	gen `SElnH'=.
	gen `varI2' =.
	gen `nc'=.
  
	* Overall estimates

   	
		metan `1' `2' `3' `4' `5' `6',`eform' noprint nograph
		if "`random'"=="random" {
		  replace `Q_ove'=$S_10
		  scalar `df'=$S_8
			gen `df2'=`df'-1
			gen `K' = `df2' + 1
			gen `K_ove'=`df'+1
	    }
	    else {
		  replace `Q_ove'=$S_7
		  scalar `df'=$S_8
		  gen `df2'=`df'-1
		  gen `K' = `df2' + 1
		  gen `K_ove'=`df'+1
	    }
	
	}
	replace `H2' = `Q_ove'/`df'
	replace `I2_ove' = max(0, (100*(`Q_ove' -`df')/(`Q_ove' )) )
	replace `pvalue_ove' = chiprob(`df', `Q_ove')
	replace `I22' = max(0, (`H2'-1)/`H2')
	

	if sqrt(`H2') < 1 scalar `H2' = 1

	* CI for H (Higgins & Thompson, Stats in Medicine 2002) 
	if `Q_ove' > `K_ove'  {
	 replace `SElnH' = .5*[  (log(`Q_ove')-ln(`df')) / ( sqrt(2*`Q_ove') - sqrt(2*`K_ove'-3) ) ]
	}
	else {
	 replace `SElnH' = sqrt( ( 1/(2*(`K_ove'-2) )*(1-1/(3*(`K_ove'-2)^2)) )  )
	}
	replace `LB_H_III' = exp( log(sqrt(`H2')) - invnorm(`levelci') * `SElnH' )
	replace `UB_H_III' = exp( log(sqrt(`H2')) + invnorm(`levelci') * `SElnH' )
	if  `LB_H_III' < 1 scalar  `LB_H_III' = 1

	* CI interval for I2 based var(logH), formula not indicated in (Higgins & Thompson, Stats in Medicine) 

	replace `varI2'  = 4*`SElnH'^2/exp(4*log(sqrt(`H2')))
	replace `lb_I2' = `I22'-invnorm(`levelci')*sqrt(`varI2')
	replace `ub_I2' = `I22'+invnorm(`levelci')*sqrt(`varI2')
	
	if  `lb_I2' < 0 {
	 replace  `lb_I2' = 0
	}
	if  `ub_I2' > 1 {
	 replace  `ub_I2' = 1
	}

	if `c(N)' < 10  qui set obs 10

	if "`ncchi2'" != "" {
	 * seek ci for non-centrality parameter (nc=q-df), thence for h and i-square
	 replace `nc' = max(0, `Q_ove' - `df2')
	 * check if q < df , in this case no need to seek the lower bound
	 if `Q_ove' < `df' {
	  gen `LB_NC' = 0
	 }
	 else {
	  gen `LB_NC' =  invnchi2(`df',`nc',`clvlci')
	 }
	 gen `UB_NC' =  invnchi2(`df',`nc',`levelci')
	 replace `LB_H_H' = max(1, sqrt(`LB_NC'/`df2') )
	 replace `LB_I2_H' = max(0, (`LB_H_H'^2 - 1)/`LB_H_H'^2 )
	 replace `UB_H_H' = sqrt(`UB_NC'/`df')  
	 replace `UB_I2_H' = (`UB_H_H'^2 - 1)/`UB_H_H'^2
	} // end option ncchi2
	

	replace `LI2_ove' = max(0,(`LB_H_III'^2-1)/`LB_H_III'^2)*100
	replace `UI2_ove' = ((`UB_H_III'^2-1)/`UB_H_III'^2)*100 
	

* end of Overall estimates	

* Meta-analysis estimate ommiting one study each step

   local i=1
   local n=_result(1)
   while (`i'<`n'){
    	qui {
		metan `1' `2' `3' `4' `5' `6' if `s'!=`i',`eform' noprint nograph
		if "`random'"=="random" {
		  replace `Q'=$S_10 in `i'
	    }
	    else {
		  replace `Q'=$S_7 in `i'
	    }
		
	replace `H2' = `Q'/`df2'
	replace `I2' = max(0, (100*(`Q' -`df2')/(`Q' )) ) in `i'
	replace `pvalue' = chiprob(`df2', `Q') in `i'
	replace `I22' = max(0, (`H2'-1)/`H2') in `i'

	if sqrt(`H2') < 1 scalar `H2' = 1

	* CI for H (Higgins & Thompson, Stats in Medicine 2002) 
	if `Q' > `K'  {
	 replace `SElnH' = .5*[  (log(`Q')-ln(`df2')) / ( sqrt(2*`Q') - sqrt(2*`K'-3) ) ]
	}
	else {
	 replace `SElnH' = sqrt( ( 1/(2*(`K'-2) )*(1-1/(3*(`K'-2)^2)) )  )
	}
	replace `LB_H_III' = exp( log(sqrt(`H2')) - invnorm(`levelci') * `SElnH' )
	replace `UB_H_III' = exp( log(sqrt(`H2')) + invnorm(`levelci') * `SElnH' )
	if  `LB_H_III' < 1 scalar  `LB_H_III' = 1

	* CI interval for I2 based var(logH), formula not indicated in (Higgins & Thompson, Stats in Medicine) 

	replace `varI2'  = 4*`SElnH'^2/exp(4*log(sqrt(`H2')))
	replace `lb_I2' = `I22'-invnorm(`levelci')*sqrt(`varI2') in `i'
	replace `ub_I2' = `I22'+invnorm(`levelci')*sqrt(`varI2') in `i'

	if  `lb_I2' < 0 {
	 replace  `lb_I2' = 0
	}
	if  `ub_I2' > 1 {
	 replace  `ub_I2' = 1
	}

	if `c(N)' < 10  qui set obs 10

	if "`ncchi2'" != "" {
	 * seek ci for non-centrality parameter (nc=q-df), thence for h and i-square
	 replace `nc' = max(0, `Q' - `df2')
	 * check if q < df , in this case no need to seek the lower bound
	 if `Q' < `df2' {
	  gen `LB_NC' = 0
	 }
	 else {
	  gen `LB_NC' =  invnchi2(`df2',`nc',`clvlci')
	 }
	 gen `UB_NC' =  invnchi2(`df2',`nc',`levelci')
	 replace `LB_H_H' = max(1, sqrt(`LB_NC'/`df2') )
	 replace `LB_I2_H' = max(0, (`LB_H_H'^2 - 1)/`LB_H_H'^2 ) in `i'
	 replace `UB_H_H' = sqrt(`UB_NC'/`df2')  
	 replace `UB_I2_H' = (`UB_H_H'^2 - 1)/`UB_H_H'^2  in `i'
	} // end option ncchi2
	

	replace `LB_I2_HT' = max(0,(`LB_H_III'^2-1)/`LB_H_III'^2)*100 in `i'
	replace `UB_I2_HT' = ((`UB_H_III'^2-1)/`UB_H_III'^2)*100 in `i'
	}
	local i=`i'+1
   }
   
* Numeric format
   if "`format'" == "" {
	local format "%5.2f"
   }
  
 *Print option
	dis in gre "`lab'"
	dis in gr "------------------------------------------------------------------------------"
        dis in gr _col(2) "Study omitted" _col(20) "|" _col(30)  "I2" _col(35)  "[95% Conf. Interval]" _col(60) "Chi2"  _col(70) "P>|t|"
	dis in gr "-------------------+----------------------------------------------------------"
	local i=1
	while `i'<`n' {
   		if "`id'"==""  local a11=" "
	       else  local a11=`id' in `i'
	 	local a1=`s' in `i'
		local b1=`Q' in `i'
	 	local c1=`I2' in `i'
	 	local d1=`LB_I2_HT' in `i'
		local e1=`UB_I2_HT' in `i'
		local f1=`pvalue' in `i'
		display in ye _col(2) "`a1'"  _col(6) "`a11'"_col(20) %5.2f in gr "|" in ye _col(30) %5.2f `c1' _col(40) %5.2f `d1' _col(50) %5.2f `e1' _col(60) %5.2f `b1' _col(68) %7.3f `f1'
		local i=`i'+1
	}
	
	dis in gr "-------------------+----------------------------------------------------------"
   	dis _col(2) "Combined" _col(20) in gr "|" in ye _col(30) %5.2f `I2_ove'  _col(40) %5.2f `LI2_ove' _col(50) %5.2f `UI2_ove' _col(60)%5.2f `Q_ove'  _col(68) %7.3f `pvalue_ove'
   	dis in gr "------------------------------------------------------------------------------"

* Displaying  plot
	
	twoway (line `I2' `s', lcolor(purple) ytitle("I^2 statistics for Heterogeneity(%)") ytitle(, color(cyan))), /*
	*/ yline(50, lcolor(red))  /*
	*/ xtitle("Study omitted") xtitle(, color(cyan)) /*
	*/ yscale(lcolor(cyan)) ylabel(, labcolor(cyan) grid glcolor(cyan)) /*
	*/ xscale(lcolor(cyan)) xlabel(, labels labcolor(cyan)) /*
	*/ xlabel(#`n', valuelabel ticks grid) /*
	*/ ylabel(0(20)100, valuelabel ticks) /*
	*/ legend(off) scheme(s1rcolor)
	
 end
