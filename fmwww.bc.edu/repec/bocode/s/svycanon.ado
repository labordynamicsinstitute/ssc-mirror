capture program drop svycanon  
program svycanon, rclass
    version 17
	syntax  [,  SVYSETCOM(string) HOWMANY(int 1) FIRSTDIM(int 0) SECDIM(int 2) FREQ(string)]
  * preserving user's data
    preserve
    tokenize `e(cmdline)', parse("()=]")
    scalar varcount1 = `:word count `3''
    scalar varcount2 = `:word count `6''
   
  /*Capturing all the variables names*/
   local names "`3' `6'"
   local originalX `3'
   local originalY `6'
   local finwgt    `10'

   /*The variable names has the values of the variables in the order that canon received them*/	
    tokenize "`names'" 
    local n=varcount1 + varcount2
    gen counter = _n
    forvalues i = 1/`n' {
    local v1 : word `i' of `names'
	*Dropping if observations that have missing values for variable i
	quietly drop if  `v1'==.
    }

	/*Reading the weights. If finwgt is missing is a classical case and hence weights do not exist*/
	if ( "`finwgt'"!=""){
	mkmat `finwgt',    matrix(W) 
	}
	
/*Getting rid of non-numeric variables*/
	quietly ds, has(type string)
	if "`r(varlist)'"!=""{
    drop `r(varlist)'
	}
	quietly destring , replace
	mkmat _all, matrix(All) 
  
 /*Reading making the X variables the longest set */  
   if varcount1 >= varcount2 {
       local X `originalX'
       local Y `originalY'
	   local totalvar= varcount2 +  1
	   matrix mycoef1 =e(stdcoef_var1)
	   matrix mycoef2 =e(stdcoef_var2)
	   
   }
  else {
       local X `originalY'
       local Y `originalX'
	   local totalvar= varcount1 + 1
	   matrix mycoef1 =e(stdcoef_var2)
	   matrix mycoef2 =e(stdcoef_var1)
   }
   
   if  ("`X'"==""){
   	display("Remeber to always run the command canon immediately before svycanon. You might have just ran svycanon before (re)running canon.")
   }
   mkmat `X', matrix(OgX) 
   mkmat `Y', matrix(OgY) 

   quietly gen varname = ""
   local names "`X' `Y'"
   local n=varcount1 + varcount2
   quietly replace counter = _n
   forvalues i = 1/`n' {
   	/*getting name i*/
    local v1 : word `i' of `names'
	/*assign name i to value i of the variable varname*/
    quietly replace varname="`v1'" if counter == `i'
   }
   
/*===============Graphs===============*/
 *capturing number of canonical correlations
 local n_cc  = e(n_cc)
 if "`firstdim'"!="" & "`firstdim'"!="0"{ 
	if  ("`secdim'"=="") |( `firstdim' > `n_cc') | (`firstdim' < 1 ) | (`secdim' > `n_cc') | (`secdim' < 1 ){
		display("You need to provide the second dimension for the variables plot. Both dimensions must be between 1 and a maximum equl to the number of variable in the data set with the smaller number of variables")
	}
 	else{
		  confirm integer number `firstdim'
          confirm integer number `secdim'
	   matrix stdU=  OgX * mycoef1
	   svmat double stdU
	   matrix mycoef1=mycoef1,J(rowsof(mycoef1),1,0) /*Adding a columns of zeros to aid with the painting of the markers*/
	   matrix stdV=  OgY * mycoef2
	   svmat double stdV
	   matrix mycoef2=mycoef2,J(rowsof(mycoef2),1,1) /*Adding a columns of ones to aid with the painting of the markers*/
	 
	/*=========Variables=================*/
	  mat graphcoef=mycoef1\mycoef2
	  svmat double graphcoef
	   quietly twoway scatter graphcoef`secdim' graphcoef`firstdim' if graphcoef`totalvar' == 0, mc(red)  ms(Oh) mlabel(varname) mlabcolor(red)   mlabsize(vsmall) yline(0) xline(0)  ysize(8) xsize(10) || ///
	         		  scatter graphcoef`secdim' graphcoef`firstdim' if graphcoef`totalvar' == 1, mc(blue) ms(+)  mlabel(varname) mlabcolor(blue)  mlabsize(vsmall) || ///
			  function y = sqrt(1 - (x)^2), range(-1 1) lwidth(thin) lcolor(black) || function y = -sqrt(1 - (x)^2), range(-1 1) lwidth(thin) lcolor(black) aspect(1) legend(off) ytitle("CC`secdim'") xtitle("CC`firstdim'") saving(variables,replace)  nodraw

	/*=========Units=================*/
		quietly scatter  stdV`firstdim' stdU`firstdim' , ytitle("V`firstdim'") xtitle("U`firstdim'") mlabel(counter) ysize(8) xsize(10) saving(units,replace) nodraw
		gr combine variables.gph units.gph
	}/*end ELSE that checks that secdim exists*/
 }/*end if graphs*/	
/*===============End Graphs===============*/
 if ("`svysetcom'"!="classic" & "`svysetcom'"!=""){
	/*Creating diagonal matrix with the survey Weights*/
     matrix diag_W = I(rowsof(OgX))
     local n_f =rowsof(OgX)
     forvalues i = 1/`n_f' {
   	 		 matrix diag_W [`i',`i']=  W[`i',1]
	 } /*end for i*/ 
	 
  }  /*end if*/
  else{ /*Creating a weight matrix with all weights equal to 1 for the classic case*/
   	       matrix W = J(rowsof(OgX),1,1) 
			matrix diag_W = I(rowsof(OgX))
            local n_f =rowsof(OgX)
            forvalues i = 1/`n_f' {
   	 		       matrix diag_W [`i',`i']=  1
	        } /*end for i*/
  }/*end else*/
	  
 *standarizing X variables
   clear
   capture svmat double OgX
   foreach var of varlist _all {
   	egen aux_`var'= std(`var')
    drop `var'
   }/*end for var*/
   mkmat  _all, matrix(X)

   *standarixing Y variables
   clear
   capture svmat double OgY
   foreach var of varlist _all {
   	egen aux_`var'= std(`var')
    drop `var'
   }
    mkmat  _all, matrix(Y)  

  clear
  *capturing number of canonical correlations
  local n_cc  = e(n_cc)
  *creating matrix where all new p-values will be stored
   matrix Results = J(7*(`n_cc'),6,.) 
  *----creating matrix the will use to return results----
  tempname WilksStat
  matrix `WilksStat'= J(`n_cc',1,.)
  tempname WilksDf1
  matrix `WilksDf1'= J(`n_cc',1,.)
  tempname WilksChiSq
  matrix `WilksChiSq'= J(`n_cc',1,.)
  tempname WilksPval
  matrix `WilksPval'= J(`n_cc',1,.)
  
  tempname PillaisStat
  matrix `PillaisStat'= J(`n_cc',1,.)
  tempname PillaisDf1
  matrix `PillaisDf1'= J(`n_cc',1,.)
  tempname PillaisChiSq
  matrix `PillaisChiSq'= J(`n_cc',1,.)
  tempname PillaisPval
  matrix `PillaisPval'= J(`n_cc',1,.)

  tempname HotellingStat
  matrix `HotellingStat'= J(`n_cc',1,.)
  tempname HotellingDf1
  matrix `HotellingDf1'= J(`n_cc',1,.)
  tempname HotellingChiSq
  matrix `HotellingChiSq'= J(`n_cc',1,.)
  tempname HotellingPval
  matrix `HotellingPval'= J(`n_cc',1,.)

  tempname RoysStat
  matrix `RoysStat'= J(`n_cc',1,.)
  tempname RoysDf1
  matrix `RoysDf1'= J(`n_cc',1,.)
  tempname RoysDf2
  matrix `RoysDf2'= J(`n_cc',1,.)
  tempname RoysChiSq
  matrix `RoysChiSq'= J(`n_cc',1,.)
  tempname RoysPval
  matrix `RoysPval'= J(`n_cc',1,.)

  tempname WtSCCStat
  matrix `WtSCCStat'= J(`n_cc',1,.)
  tempname WtSCCDf1
  matrix `WtSCCDf1'= J(`n_cc',1,.)
  tempname WtSCCDf2
  matrix `WtSCCDf2'= J(`n_cc',1,.)
  tempname WtSCCF
  matrix `WtSCCF'= J(`n_cc',1,.)
  tempname WtSCCPval
  matrix `WtSCCPval'= J(`n_cc',1,.)
  
  tempname CSCCStat
  matrix `CSCCStat'= J(`n_cc',1,.)
  tempname CSCCDf1
  matrix `CSCCDf1'= J(`n_cc',1,.)
  tempname CSCCDf2
  matrix `CSCCDf2'= J(`n_cc',1,.)
  tempname CSCCF
  matrix `CSCCF'= J(`n_cc',1,.)
  tempname CSCCPval
  matrix `CSCCPval'= J(`n_cc',1,.)
  
  *Running function that calculates existing methods p-values
   mata: calcpval("`freq'") 
   matrix colnames Results = "Statistic" "df1" "df2" "Chi-Sq/F" "p-val" "Index"
   capture svmat OGStataUVW
   capture svmat All, names(col) 
  *ereturn list
*=====Weighthed Simple Regression============ 
 local weightindex = (2*e(n_cc)) + 1 /*Reading the weiths as they where stored in this column in the mata function*/
  if ("`svysetcom'"!="classic" & "`svysetcom'"!=""){
   quietly svyset  [pweight= OGStataUVW`weightindex'],
   *Notice coefficients of the simple linear regression are equal to the canonical correlations because the variances of the canonical variates are equal to 1
   forval i = 1/`n_cc' { 
	local     secondindex = `i' + `n_cc'
    quietly svy: regress OGStataUVW`i'  OGStataUVW`secondindex'
	matrix p1 = e(p)
    quietly svy: regress OGStataUVW`secondindex' OGStataUVW`i' 
	matrix p2 = e(p)
	if (p1[1,1]>=p2[1,1]){
		quietly svy: regress OGStataUVW`i'  OGStataUVW`secondindex'
	    matrix Results[(7*(`i'-1))+6,1]= e(b)
        matrix Results[(7*(`i'-1))+6,2]= `e(df_m)'
	    matrix Results[(7*(`i'-1))+6,3]= `e(df_r)'
	    matrix Results[(7*(`i'-1))+6,4]= `e(F)'
	    matrix Results[(7*(`i'-1))+6,5]= `e(p)'
	    matrix Results[(7*(`i'-1))+6,6]= `i'
	}
	else{
		quietly svy: regress OGStataUVW`secondindex' OGStataUVW`i' 
	    matrix Results[(7*(`i'-1))+6,1]=  e(b)
	    matrix Results[(7*(`i'-1))+6,2]= `e(df_m)'
	    matrix Results[(7*(`i'-1))+6,3]= `e(df_r)'
	    matrix Results[(7*(`i'-1))+6,4]= `e(F)'
	    matrix Results[(7*(`i'-1))+6,5]= `e(p)'
	    matrix Results[(7*(`i'-1))+6,6]= `i'
	}/*end else p-values comparision*/
   } /*end for i*/
  } /*end if*/
  else{
  	/*For classic there is no need to check the p-values, they are the same*/
  	forval i = 1/`n_cc' { 
	local     secondindex = `i' + `n_cc'
	*summarize OGStataUVW`i'
    quietly regress OGStataUVW`i'  OGStataUVW`secondindex'
	matrix aux = e(b)
	matrix Results[(7*(`i'-1))+6,1]= aux[1,1]
	matrix Results[(7*(`i'-1))+6,2]= e(df_m)
	matrix Results[(7*(`i'-1))+6,3]= e(df_r)
	matrix Results[(7*(`i'-1))+6,4]= e(F)
	matrix Results[(7*(`i'-1))+6,5]= Ftail(e(df_m),e(df_r),e(F))
   }/*end for i*/
  }/*end else "classic"*/
 *=====End Weighthed Simple Regression============
 
 *=====Complex Survey Design Simple Regression============
* Simple linear regression this time using all the svyset factors
 if ("`svysetcom'"!="classic" & "`svysetcom'"!=""){
 quietly `svysetcom'
 forval i = 1/`n_cc' { 
	local     secondindex = `i' + `n_cc'
	quietly svy: regress OGStataUVW`i'  OGStataUVW`secondindex'
	matrix p1 = e(p)
    quietly svy: regress OGStataUVW`secondindex' OGStataUVW`i' 
	matrix p2 = e(p)
	if (p1[1,1]>=p2[1,1]){
		quietly svy: regress OGStataUVW`i'  OGStataUVW`secondindex'
	    matrix Results[(7*(`i'-1))+7,1]=  e(b)
	    matrix Results[(7*(`i'-1))+7,2]= `e(df_m)'
	    matrix Results[(7*(`i'-1))+7,3]= `e(df_r)'
	    matrix Results[(7*(`i'-1))+7,4]= `e(F)'
	    matrix Results[(7*(`i'-1))+7,5]= `e(p)'
	    matrix Results[(7*(`i'-1))+7,6]= `i'
	}
	else{
		quietly svy: regress OGStataUVW`secondindex' OGStataUVW`i' 
	    matrix Results[(7*(`i'-1))+7,1]= e(b)
	    matrix Results[(7*(`i'-1))+7,2]= `e(df_m)'
	    matrix Results[(7*(`i'-1))+7,3]= `e(df_r)'
	    matrix Results[(7*(`i'-1))+7,4]= `e(F)'
	    matrix Results[(7*(`i'-1))+7,5]= `e(p)'
	    matrix Results[(7*(`i'-1))+7,6]= `i'
	}/*end else p-values comparision*/
  }/*end for i*/ 
 }/*end if svyset*/
 *=====End Complex Survey Design Simple Regression============

 /*==================Present results from a matrix and return data ==================================*/
/*In case that this argument was not provided we display all canonical correlations*/
    if "`howmany'"==""{
	local	howmany=`n_cc'
	/*This part means that if a desired number of canonical correlations is selected then all of them are displayed*/
	}
	else if (`howmany' > `n_cc') | (`howmany' < 1 ){
		display("The number of canonical correlations that you can request the p-values of is between 1 and a maximum of `n_cc'")
	}
   else{  
   	 /*-------Code to display results-------*/
   	     confirm integer number `howmany'
          forval i = 1/`howmany' { 
	      /*Selecting rows in information for Canonical correlation i*/
	      matrix aux= Results[((7*(`i' -1))+6),1]
	      local mag  = round(aux[1,1], .0001)
	      mat ResultsAux =Results[((7*(`i' -1))+2)..((7*(`i' -1))+7),1..5]
	      matrix rownames ResultsAux = "Wilks' Lambda"  "Pillai's Trace"  "Hotelling-Lawley Trace" "Roy's Greatest Root" "Weighted Survey CC" "Complex Survey CC"
          matlist ResultsAux,title("Statistics for Canonical Correlation: "`i')  rowtitle( "Canonical Correlation="`mag')  cspec(o4& %30s | %10.4f & %5.0f & %5.0f & %10.4f & %10.4f o2&) rspec(--&&&&&-)
      } 
	 /*-------End Code to display results-------*/
 /*==========================Code to return results=================================*/
	 *matlist Results
	  forval i = 1/`n_cc' { 
		  matrix `WilksStat'[`i',1] =Results[(7*(`i' -1))+2,1]
		  matrix `WilksDf1'[`i',1]  =Results[(7*(`i' -1))+2,2]
		  matrix `WilksChiSq'[`i',1]=Results[(7*(`i' -1))+2,4]
		  matrix `WilksPval'[`i',1] =Results[(7*(`i' -1))+2,5]
		  
		  matrix `PillaisStat'[`i',1] =Results[(7*(`i' -1))+3,1]
		  matrix `PillaisDf1'[`i',1]  =Results[(7*(`i' -1))+3,2]
		  matrix `PillaisChiSq'[`i',1]=Results[(7*(`i' -1))+3,4]
		  matrix `PillaisPval'[`i',1] =Results[(7*(`i' -1))+3,5]
		  
		  matrix `HotellingStat'[`i',1] =Results[(7*(`i' -1))+4,1]
		  matrix `HotellingDf1'[`i',1]  =Results[(7*(`i' -1))+4,2]
		  matrix `HotellingChiSq'[`i',1]=Results[(7*(`i' -1))+4,4]
		  matrix `HotellingPval'[`i',1] =Results[(7*(`i' -1))+4,5]
		  
		  matrix `RoysStat'[`i',1] =Results[(7*(`i' -1))+5,1]
		  matrix `RoysDf1'[`i',1]  =Results[(7*(`i' -1))+5,2]
		  matrix `RoysDf2'[`i',1]  =Results[(7*(`i' -1))+5,3]
		  matrix `RoysChiSq'[`i',1]=Results[(7*(`i' -1))+5,4]
		  matrix `RoysPval'[`i',1] =Results[(7*(`i' -1))+5,5]
		  
		  matrix `WtSCCStat'[`i',1] =Results[(7*(`i' -1))+6,1]
		  matrix `WtSCCDf1'[`i',1]  =Results[(7*(`i' -1))+6,2]
		  matrix `WtSCCDf2'[`i',1]  =Results[(7*(`i' -1))+6,3]
		  matrix `WtSCCF'[`i',1]=Results[(7*(`i' -1))+6,4]
		  matrix `WtSCCPval'[`i',1] =Results[(7*(`i' -1))+6,5]
		  
		  matrix `CSCCStat'[`i',1] =Results[(7*(`i' -1))+7,1]
		  matrix `CSCCDf1'[`i',1]  =Results[(7*(`i' -1))+7,2]
		  matrix `CSCCDf2'[`i',1]  =Results[(7*(`i' -1))+7,3]
		  matrix `CSCCF'[`i',1]=Results[(7*(`i' -1))+7,4]
		  matrix `CSCCPval'[`i',1] =Results[(7*(`i' -1))+7,5]
      } 
	  /*----------------Wilks--------------'*/
	  matrix colnames `WilksStat'= "Wilks' Lambda Statistic"
	  matrix colnames `WilksDf1'= "Wilks' Lambda df1"  
	  matrix colnames `WilksChiSq'= "Wilks' Lambda Chi-Sq"  
	  matrix colnames `WilksPval'= "Wilks' Lambda p-val"  
	  if "`matrix'" !=""{
	  	matrix `matrix'=`WilksStat'
	  }
	  return matrix WilksStat=`WilksStat'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`WilksDf1'
	  }
	  return matrix WilksDf1=`WilksDf1'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`WilksChiSq'
	  }
	  return matrix WilksChiSq=`WilksChiSq'
	  	  if "`matrix'" !=""{
	  	matrix `matrix'=`WilksPval'
	  }
	  return matrix WilksPval=`WilksPval'
	  /*----------------End Wilks--------------'*/
	  /*----------------Pillai's--------------'*/
	  matrix colnames `PillaisStat'= "Pillai's Statistic"
	  matrix colnames `PillaisDf1'= "Pillai's df1"  
	  matrix colnames `PillaisChiSq'= "Pillai's Chi-Sq"  
	  matrix colnames `PillaisPval'= "Pillai's p-val"  
	  if "`matrix'" !=""{
	  	matrix `matrix'=`PillaisStat'
	  }
	  return matrix PillaisStat=`PillaisStat'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`PillaisDf1'
	  }
	  return matrix PillaisDf1=`PillaisDf1'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`PillaisChiSq'
	  }
	  return matrix PillaisChiSq=`PillaisChiSq'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`PillaisPval'
	  }
	  return matrix PillaisPval=`PillaisPval'
	  /*----------------End Pillai's--------------'*/
	  /*---------------- Hotelling-Lawley--------------'*/
	  matrix colnames `HotellingStat'= "HotellingLawley Statistic"
	  matrix colnames `HotellingDf1'= "HotellingLawley df1"  
	  matrix colnames `HotellingChiSq'= "HotellingLawley Chi-Sq"  
	  matrix colnames `HotellingPval'= "HotellingLawley p-val"  
	  if "`matrix'" !=""{
	  	matrix `matrix'=`HotellingStat'
	  }
	  return matrix HotellingStat=`HotellingStat'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`HotellingDf1'
	  }
	  return matrix HotellingDf1=`HotellingDf1'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`HotellingChiSq'
	  }
	  return matrix HotellingChiSq=`HotellingChiSq'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`HotellingPval'
	  }
	  return matrix HotellingPval=`HotellingPval'
	  /*----------------End Pillai's--------------'*/
	  /*----------------Roy's--------------'*/
	  matrix colnames `RoysStat'= "Roy's Statistic"
	  matrix colnames `RoysDf1'= "Roy's df1"  
	  matrix colnames `RoysDf2'= "Roy's df2"  
	  matrix colnames `RoysChiSq'= "Roy's Chi-Sq"  
	  matrix colnames `RoysPval'= "Roy's p-val"  
	  if "`matrix'" !=""{
	  	matrix `matrix'=`RoysStat'
	  }
	  return matrix RoysStat=`RoysStat'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`RoysDf1'
	  }
	  return matrix RoysDf1=`RoysDf1'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`RoysDf2'
	  }
	  return matrix RoysDf2=`RoysDf2'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`RoysChiSq'
	  }
	  return matrix RoysChiSq=`RoysChiSq'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`RoysPval'
	  }
	  return matrix RoysPval=`RoysPval'
	  /*----------------End Roy's--------------'*/
	  /*----------------Weighted Regression--------------'*/
	  matrix colnames `WtSCCStat'= "Weighted SCC Statistic"
	  matrix colnames `WtSCCDf1'= "Weighted SCC df1"  
	  matrix colnames `WtSCCDf2'= "Weighted SCC df2"  
	  matrix colnames `WtSCCF'= "Weighted SCC F"  
	  matrix colnames `WtSCCPval'= "Weighted SCC p-val"  
	  if "`matrix'" !=""{
	  	matrix `matrix'=`WtSCCStat'
	  }
	  return matrix WtSCCStat=`WtSCCStat'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`WtSCCDf1'
	  }
	  return matrix WtSCCDf1=`WtSCCDf1'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`WtSCCDf2'
	  }
	  return matrix WtSCCDf2=`WtSCCDf2'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`WtSCCF'
	  }
	  return matrix WtSCCF=`WtSCCF'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`WtSCCPval'
	  }
	  return matrix WtSCCPval=`WtSCCPval'
	  /*----------------End Weighted Regression--------------'*/
	  /*----------------Complex Survey Design Regression--------------'*/
	  matrix colnames `CSCCStat'= "Complex SCC Statistic"
	  matrix colnames `CSCCDf1'= "Complex SCC df1"  
	  matrix colnames `CSCCDf2'= "Complex SCC df2"  
	  matrix colnames `CSCCF'= "Complex SCC F"  
	  matrix colnames `CSCCPval'= "Complex SCC p-val"  
	  if "`matrix'" !=""{
	  	matrix `matrix'=`CSCCStat'
	  }
	  return matrix CSCCStat=`CSCCStat'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`CSCCDf1'
	  }
	  return matrix CSCCDf1=`CSCCDf1'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`CSCCDf2'
	  }
	  return matrix CSCCDf2=`CSCCDf2'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`CSCCF'
	  }
	  return matrix CSCCF=`CSCCF'
	  if "`matrix'" !=""{
	  	matrix `matrix'=`CSCCPval'
	  }
	  return matrix CSCCPval=`CSCCPval'
	  /*----------------End Complex Survey Design Regression--------------'*/
	}
 /*==================End Present results from a matrix and return data===================================*/	
 * restore user's data
 restore 
end 
/*====================end program==========================*/

/*============================================================================*/
/*=======================Start MATA Function===================================*/
version 17.0
mata:
void calcpval(string scalar freq)
{  
/*================Reading data from Stata==================*/		
    myX=st_matrix("X")
	myY=st_matrix("Y")
	myOgX=st_matrix("OgX")
	myOgY=st_matrix("OgY")
	mydiag_W=st_matrix("diag_W")
    myW=st_matrix("W")
    myccorr=st_matrix("e(ccorr)")
	myResults=st_matrix("Results")
	myrawcoef_var1=st_matrix("e(rawcoef_var1)")
	myrawcoef_var2=st_matrix("e(rawcoef_var2)")
	/*Inverting position of coefficients because the smallest data set was provided first*/
	if (rows(myrawcoef_var2)>rows(myrawcoef_var1)){
       aux=myrawcoef_var2
	   myrawcoef_var2=myrawcoef_var1
       myrawcoef_var1=aux
 	}
	U=myOgX*myrawcoef_var1
	V=myOgY*myrawcoef_var2	
	st_matrix("OGStataU", U)
	st_matrix("OGStataV", V)
	UV = U,V
	UVW=UV,myW
	st_matrix("OGStataUVW", UVW)
 /*================End Reading data from Stata==================*/
/*================Calculating Canonical Correlations==================*/	
	weighted_varU= 97* J(1, cols(U), 1)
	weighted_varV= 98*J(1, cols(V), 1)
	weighted_rho=  99*J(1, cols(U), 1)

	for (i=1; i<=cols(U); i++) {
		meanU=mean(U[,i])
		meanV=mean(V[,i])
		for (j=1; j<=rows(U); j++) {
			U[j,i]=U[j,i]-meanU
			V[j,i]=V[j,i]-meanV
		}/*end for j*/
   		meanU=mean(U[,i])
		meanV=mean(V[,i])
		weighted_varU[1,i]=(U'[i,])*mydiag_W*(U[,i])/trace(mydiag_W)
		weighted_varV[1,i]=(V'[i,])*mydiag_W*(V[,i])/trace(mydiag_W)
		weighted_rho[1,i]=((U'[i,])*mydiag_W*(V[,i])/trace(mydiag_W))/sqrt(weighted_varU[1,i]*weighted_varV[1,i])
		myResults[(7*(i-1))+1,1]=weighted_rho[1,i]    
		myResults[(7*(i-1))+1,2]=.                    
		myResults[(7*(i-1))+1,3]=.                    
		myResults[(7*(i-1))+1,4]=.                    
		myResults[(7*(i-1))+1,5]=.                   
	}/*end for loop*/
/*================End Calculating Canonical Correlations==================*/
/*====Finding sample size====*/	
 if (freq=="YES"){
	 samplesize=sum(trunc(myW))
 }
 else{
 	 samplesize=rows(myX)
 }
/*====End Finding sample size====*/	
 /*=======Lawley's approximation term========*/
 Lawley= J(1,cols(weighted_rho),0)
 for (j=1; j<=cols(weighted_rho); j++) {
 	for (i=1; i<=j; i++) {
	        Lawley[1,j]=Lawley[1,j]+(1/(weighted_rho[1,i]^2)) 
	}/*end for i loop*/
 }/*end j for loop*/
 /*=======End Lawley's approximation term========*/

 /*=================== Start Wilks' Lambda (Barlett approximation)================*/	
    Lambda= J(1,cols(weighted_rho),1)
	df= J(1,cols(weighted_rho),1)
	ChiSq_Wilks_Lambda=J(1,cols(weighted_rho),1)
	p_val_Wilks_Lambda=J(1,cols(weighted_rho),1)
	for (i=1; i<=cols(weighted_rho); i++) {
	   Lambda[1,i]=(1-(weighted_rho[1,i]^2))
       for (j=(i+1); j<=cols(weighted_rho); j++) {
			Lambda[1,i]=Lambda[1,i]*(1-(weighted_rho[1,j]^2)) 
		}/*end for j*/
	   df[1,i]=(cols(myX)+1-i)*(cols(myY)+1-i) 
	   ChiSq_Wilks_Lambda[1,i]=(((samplesize-1)  -.5*(cols(myX)+cols(myY)+1) + Lawley[1,i] -i)*ln(Lambda[1,i]))*-1 
	   p_val_Wilks_Lambda[1,i]=chi2tail(df[1,i], ChiSq_Wilks_Lambda[1,i])
	   myResults[(7*(i-1))+2,1]= Lambda[1,i]	        
	   myResults[(7*(i-1))+2,2]= df[1,i]	        
	   myResults[(7*(i-1))+2,3]=.	               
	   myResults[(7*(i-1))+2,4]= ChiSq_Wilks_Lambda[1,i]         
	   myResults[(7*(i-1))+2,5]= p_val_Wilks_Lambda[1,i]         
	}/*end for loop*/
/*=================== End Wilks' Lambda================*/	
	
/*===================Start Pillai's Trace =====================*/
    V=J(1,cols(weighted_rho),0)
	Pillais_Trace_stat = J(1,cols(weighted_rho),1)
	Pillais_Trace_p_value = J(1,cols(weighted_rho),1)
	for (j=1; j<=cols(weighted_rho); j++) { 
		for (i=j; i<=cols(weighted_rho); i++) { 
	        V[1,j]=V[1,j]+(weighted_rho[1,i]^2) 
	     }/*end for i loop*/
		Pillais_Trace_stat[1,j]=(samplesize-1-(2*j) + Lawley[1,j])*V[1,j]
	    Pillais_Trace_p_value[1,j]=chi2tail((cols(myX)+1-j)*(cols(myY)+1-j), Pillais_Trace_stat[1,j])
		myResults[(7*(j-1))+3,1]= V[1,j]	            
		myResults[(7*(j-1))+3,2]= (cols(myX)+1-j)*(cols(myY)+1-j)	
	    myResults[(7*(j-1))+3,3]= .	            
		myResults[(7*(j-1))+3,4]= Pillais_Trace_stat[1,j] 	      
		myResults[(7*(j-1))+3,5]= Pillais_Trace_p_value[1,j]	        
	}/*end for j*/
/*===================End Pillai's Trace=====================*/	

/*===================Start Hotelling-Lawley Trace =====================*/
	U=J(1,cols(weighted_rho),0)
	Hotelling_Lawley_Trace_stat = J(1,cols(weighted_rho),1)
	Hotelling_Lawley_Trace_p_value = J(1,cols(weighted_rho),1)
    for (j=1; j<=cols(weighted_rho); j++) {
		for (i=j; i<=cols(weighted_rho); i++) {
	           U[1,j]=U[1,j]+(weighted_rho[1,i]^2)/(1-(weighted_rho[1,i]^2)) 
        }/*end for i loop*/
		Hotelling_Lawley_Trace_stat[1,j]= (samplesize-cols(myX)-cols(myY)-2 + Lawley[1,j])*U[1,j] 
		Hotelling_Lawley_Trace_p_value[1,j]=chi2tail((cols(myX)+1-j)*(cols(myY)+1-j), Hotelling_Lawley_Trace_stat[1,j])
	    myResults[(7*(j-1))+4,1]= U[1,j]	           
	    myResults[(7*(j-1))+4,2]= (cols(myX)+1-j)*(cols(myY)+1-j)    
	    myResults[(7*(j-1))+4,3]= .	            
		myResults[(7*(j-1))+4,4]= Hotelling_Lawley_Trace_stat[1,j] 
		myResults[(7*(j-1))+4,5]= Hotelling_Lawley_Trace_p_value[1,j] 
	}/*end for j*/
/*==================End Hotelling-Lawley Trace=====================*/

/*===================Start Roy's Greatest Root================*/	
	p=cols(myX)
	q=cols(myY)
	pq=J(1,2,1)
	pq[1,1]=cols(myX)
	pq[1,2]=cols(myY)
	largest_root=J(1,cols(weighted_rho),1)
	v1=J(1,cols(weighted_rho),1)
	v2=J(1,cols(weighted_rho),1)
	Roys_Greatest_Root_stat = J(1,cols(weighted_rho),1)
	Roys_Greatest_Root_p_value = J(1,cols(weighted_rho),1)
  	Johnstone_p=q
	Johnstone_q=p
	for (s=0 ; s <= (length(weighted_rho) - 1); s++) {
		pq[1,1]=Johnstone_p
	    pq[1,2]=Johnstone_q - s
		par1 =min(pq)
		par2 = (abs(Johnstone_q - s -Johnstone_p)-1)/2
        par3 = ((samplesize + s - Johnstone_q - 1) - Johnstone_p - 1)/2
		v1[1,s + 1] = par1 + (2 * par2) + 1
		v2[1,s + 1] = par1 + (2 * par3) + 1
        largest_root[1,s + 1] = weighted_rho[1,1]^2  
		Roys_Greatest_Root_stat[1,s + 1] = (v2[1, s + 1] * largest_root[1, s + 1]) / (v1[1, s + 1] * (1.0 - largest_root[1, s + 1])) 
        Roys_Greatest_Root_p_value[s + 1] = Ftail( v1[1, s + 1], v2[1, s + 1], Roys_Greatest_Root_stat[1, s + 1])
        myResults[(7 * (s + 1 - 1)) + 5, 1] = largest_root[1, s + 1] 
        myResults[(7 * (s + 1 - 1)) + 5, 2] = v1[1, s + 1] 
        myResults[(7 * (s + 1 - 1)) + 5, 3] = v2[1, s + 1] 
        myResults[(7 * (s + 1 - 1)) + 5, 4] = Roys_Greatest_Root_stat[1, s + 1] 
        myResults[(7 * (s + 1 - 1)) + 5, 5] = Roys_Greatest_Root_p_value[1, s + 1]
    }
/*===================End Roy's Greatest Root================*/	
for (i=1;i<=cols(weighted_rho); i++ ){/*i will control the rows*/
     /*Row 1: CC, Row 2: Wilk's Lambda, Row 3: Pillai's Trace , Row 4: Hotelling Trace , Row 5:Roy's Greatest Root, Row 6: Wilk's Lambda FREQ , Row 7 Weighted Regression, Row 8: CSD Reg*/
	 /*Column 6: Just an index that keeps track of which correlation number each row belongs to*/
	 myResults[(7*(i-1))+1,6]= i        /*row 1, 9,... */
	 myResults[(7*(i-1))+2,6]= i        /*row 2, 10,... */
	 myResults[(7*(i-1))+3,6]= i        /*row 3, 11,... */
	 myResults[(7*(i-1))+4,6]= i        /*row 4, 12,... */
	 myResults[(7*(i-1))+5,6]= i        /*row 5, 13,... */
	 myResults[(7*(i-1))+6,6]= i        /*row 6, 14,... */
}/*end for i*/
st_matrix("Results", myResults)
}	
end
/*========== End MATA function ==========*/