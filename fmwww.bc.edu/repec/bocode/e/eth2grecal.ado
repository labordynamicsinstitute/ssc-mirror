*! eth_to_eth2grecal 1.1
*! Convert Ethiopian calendar dates to Gregorian calendar dates

program define eth2grecal
    version 16
    syntax [varlist], ///
        et_year(name) ///
        et_month(name) ///
        et_day(name)

    * Check if g_year, g_month, or g_day already exist in the data:
    capture confirm variable g_year
    if _rc == 0 {
        display "Error: Variable 'g_year' already exists in the dataset."
        exit 198
    }
    capture confirm variable g_month
    if _rc == 0 {
        display "Error: Variable 'g_month' already exists in the dataset."
        exit 198
    }
    capture confirm variable g_day
    if _rc == 0 {
        display "Error: Variable 'g_day' already exists in the dataset."
        exit 198
    }

    * Capture the variable names from the options
    local eth_year_var `et_year'
    local eth_month_var `et_month'
    local eth_day_var `et_day'

     * Check if these variables are numeric
     foreach var in `eth_year_var' `eth_month_var' `eth_day_var' {
     capture confirm numeric variable `var'
     if _rc != 0 {
     display as error "Error: Variable `var' must be numeric."
     exit 198
    	}
     }


	qui gen g_day = .	
	qui gen g_month = .	
	qui gen g_year = .
 
  
*************************************************************************************************
***CONVERT YEAR:
*************************************************************************************************
* IF NOT A LEAP YEAR IN ETHIOPIAN CALENDAR:	

	qui replace g_year = `eth_year_var' + 7 if inrange( `eth_month_var', 1, 3) & mod(`eth_year_var', 4) != 0 
	qui replace g_year = `eth_year_var' + 8 if inrange( `eth_month_var', 5, 13) & mod(`eth_year_var', 4) != 0 

* IF A LEAP YEAR IN ETHIOPIAN CALENDAR:	

	qui replace g_year = `eth_year_var' + 7 if inrange( `eth_month_var', 1, 3) & mod(`eth_year_var', 4) == 0 
	qui replace g_year = `eth_year_var' + 8 if inrange( `eth_month_var', 5, 13) & mod(`eth_year_var', 4) == 0 

*Exceptions for the 4th Ethiopian month (irrespective of whether a leap year or not):
	qui replace g_year = `eth_year_var' + 7 if inrange(`eth_day_var', 1, 21) &  `eth_month_var' == 4   
	qui replace g_year = `eth_year_var' + 8 if inrange(`eth_day_var', 23, 30) &  `eth_month_var' == 4   

*22nd day of the fourth month:
	qui replace g_year = `eth_year_var'+7 if `eth_day_var' == 22 &  `eth_month_var' == 4 & mod(`eth_year_var', 4) != 0     
	qui replace g_year = `eth_year_var'+8 if `eth_day_var' == 22 &  `eth_month_var' == 4 & mod(`eth_year_var', 4) == 0     
		
************************************************************************************************* 
***CONVERT DAY:
*************************************************************************************************

* IF NOT A LEAP YEAR IN ETHIOPIAN CALENDAR:	
	qui replace g_day=	`eth_day_var'+9 if inrange(`eth_day_var',1,22) &  `eth_month_var'== 4 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'-22 if inrange(`eth_day_var',23,30) &  `eth_month_var'== 4 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'-21 if inrange(`eth_day_var',22,30) &  `eth_month_var'== 6 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'+8 if inrange(`eth_day_var',1,23) &  `eth_month_var'== 5 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'+9 if inrange(`eth_day_var',1,22) &  `eth_month_var'== 7 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'-22 if inrange(`eth_day_var',23,30) &  `eth_month_var'== 7 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'-23 if inrange(`eth_day_var',24,30) &  `eth_month_var'== 5 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'+7 if inrange(`eth_day_var',1,21) &  `eth_month_var'== 6 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'+8 if inrange(`eth_day_var',1,22) &  `eth_month_var'== 8 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'-22 if inrange(`eth_day_var',23,30) &  `eth_month_var'== 8 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'+8 if inrange(`eth_day_var',1,23) &  `eth_month_var'== 9 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'-23 if inrange(`eth_day_var',24,30) &  `eth_month_var'== 9 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'+7 if inrange(`eth_day_var',1,23) &  `eth_month_var'== 10 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'-23 if inrange(`eth_day_var',24,30) &  `eth_month_var'== 10 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'+7 if inrange(`eth_day_var',1,24) &  `eth_month_var'== 11 & mod(`eth_year_var', 4) != 0 
	qui replace g_day=	`eth_day_var'-24 if inrange(`eth_day_var',25,30) &  `eth_month_var'== 11 & mod(`eth_year_var', 4) != 0 
	qui replace g_day = `eth_day_var' + 6 if inrange(`eth_day_var', 1, 25) &  `eth_month_var' == 12 & mod(`eth_year_var', 4) != 0 
	qui replace g_day = `eth_day_var' - 25 if inrange(`eth_day_var', 26, 30) &  `eth_month_var' == 12 & mod(`eth_year_var', 4) != 0 
	qui replace g_day = `eth_day_var' + 5 if inrange(`eth_day_var', 1, 6) &  `eth_month_var' == 13 & mod(`eth_year_var', 4) != 0 
	qui replace g_day = `eth_day_var' + 10 if inrange(`eth_day_var', 1, 20) &  `eth_month_var' == 1 & mod(`eth_year_var', 4) != 0 
	qui replace g_day = `eth_day_var' + 10 if inrange(`eth_day_var', 1, 20) &  `eth_month_var' == 1 & mod(`eth_year_var', 4) != 0 
	qui replace g_day = `eth_day_var' - 20 if inrange(`eth_day_var', 21, 30) &  `eth_month_var' == 1 & mod(`eth_year_var', 4) != 0 
	qui replace g_day = `eth_day_var' + 10 if inrange(`eth_day_var', 1, 21) &  `eth_month_var' == 2 & mod(`eth_year_var', 4) != 0 
	qui replace g_day = `eth_day_var' - 21 if inrange(`eth_day_var', 22, 30) &  `eth_month_var' == 2 & mod(`eth_year_var', 4) != 0 
	qui replace g_day = `eth_day_var' + 9 if inrange(`eth_day_var', 1, 21) &  `eth_month_var' == 3 & mod(`eth_year_var', 4) != 0 
	qui replace g_day = `eth_day_var' - 21 if inrange(`eth_day_var', 22, 30) &  `eth_month_var' == 3 & mod(`eth_year_var', 4) != 0 

* IF A LEAP YEAR IN ETHIOPIAN CALENDAR:
	qui replace g_day =	`eth_day_var'+10 if inrange(`eth_day_var', 1, 21) &  `eth_month_var'== 4 & mod(`eth_year_var', 4) == 0 
	qui replace g_day =	`eth_day_var'-21 if inrange(`eth_day_var', 22, 30) &  `eth_month_var'==	4 & mod(`eth_year_var', 4) == 0 
	qui replace g_day =	`eth_day_var'+8	if inrange(`eth_day_var', 1, 23) &  `eth_month_var'==5 & mod(`eth_year_var', 4) == 0 
	qui replace g_day =	`eth_day_var'-23 if inrange(`eth_day_var', 24, 30) &  `eth_month_var'==5 & mod(`eth_year_var', 4) == 0 
	qui replace g_day = `eth_day_var' + 7 if inrange(`eth_day_var', 1, 21) &  `eth_month_var' == 6 & mod(`eth_year_var', 4) == 0 
	qui replace g_day = `eth_day_var' - 21 if inrange(`eth_day_var', 22, 30) &  `eth_month_var' == 6 & mod(`eth_year_var', 4) == 0 
	qui replace g_day = `eth_day_var' + 9 if inrange(`eth_day_var', 1, 22) &  `eth_month_var' == 7 & mod(`eth_year_var', 4) == 0 
	qui replace g_day = `eth_day_var' - 22 if inrange(`eth_day_var', 23, 30) &  `eth_month_var' == 7 & mod(`eth_year_var', 4) == 0 
	qui replace g_day = `eth_day_var' + 8 if inrange(`eth_day_var', 1, 22) &  `eth_month_var' == 8 & mod(`eth_year_var', 4) == 0 
	qui replace g_day = `eth_day_var' - 22 if inrange(`eth_day_var', 23, 30) &  `eth_month_var' == 8 & mod(`eth_year_var', 4) == 0 
	qui replace g_day =	`eth_day_var' + 8 if inrange(`eth_day_var', 1, 23) &  `eth_month_var'== 9	& mod(`eth_year_var', 4) == 0  
	qui replace g_day =	`eth_day_var' - 23 if inrange(`eth_day_var', 24, 30) &  `eth_month_var'== 9 & mod(`eth_year_var', 4) == 0  
	qui replace g_day = `eth_day_var' + 7 if inrange(`eth_day_var', 1, 23) &  `eth_month_var' == 10 & mod(`eth_year_var', 4) == 0 
	qui replace g_day = `eth_day_var' - 23 if inrange(`eth_day_var', 24, 30) &  `eth_month_var' == 10 & mod(`eth_year_var', 4) == 0 
	qui replace g_day = `eth_day_var' + 7 if inrange(`eth_day_var', 1, 24) &  `eth_month_var' == 11 & mod(`eth_year_var', 4) == 0 
	qui replace g_day = `eth_day_var' - 24 if inrange(`eth_day_var', 25, 30) &  `eth_month_var' == 11 & mod(`eth_year_var', 4) == 0 
	qui replace g_day = `eth_day_var' + 6 if inrange(`eth_day_var', 1, 25) &  `eth_month_var' == 12 & mod(`eth_year_var', 4) == 0 
	qui replace g_day = `eth_day_var' - 25 if inrange(`eth_day_var', 26, 30) &  `eth_month_var' == 12 & mod(`eth_year_var', 4) == 0 
	qui replace g_day = `eth_day_var' + 5 if inrange(`eth_day_var', 1, 5) &  `eth_month_var' == 13 & mod(`eth_year_var', 4) == 0 
	qui replace g_day =	`eth_day_var' + 11 if inrange(`eth_day_var', 1, 19) &  `eth_month_var'==	1 & mod(`eth_year_var', 4) == 0 
	qui replace g_day =	`eth_day_var' - 19 if inrange(`eth_day_var', 20, 30) &  `eth_month_var'==	1 & mod(`eth_year_var', 4) == 0 
	qui replace g_day =	`eth_day_var' + 11 if inrange(`eth_day_var', 1, 20) &  `eth_month_var'==	2 & mod(`eth_year_var', 4) == 0 
	qui replace g_day =	`eth_day_var' - 20 if inrange(`eth_day_var', 21, 30) &  `eth_month_var'==	2 & mod(`eth_year_var', 4) == 0 
	qui replace g_day =	`eth_day_var' + 10 if inrange(`eth_day_var', 1, 20) &  `eth_month_var'==	3 & mod(`eth_year_var', 4) == 0 
	qui replace g_day =	`eth_day_var' - 20 if inrange(`eth_day_var', 21, 30) &  `eth_month_var'==	3 & mod(`eth_year_var', 4) == 0 
	qui replace g_day = 11 if `eth_day_var' == 6 &  `eth_month_var' == 13 & mod(`eth_year_var', 4) == 0 

*Exceptions due to leap years in either calendar or if the previous Ethiopian year was a leap year:
	qui replace g_day = 1 if `eth_day_var'== 22 &  `eth_month_var'== 4 & mod(`eth_year_var', 4) != 0  & mod(`eth_year_var'-1, 4) != 0  & (mod(g_year, 4) == 0 & (mod(g_year, 100) != 0 | mod(g_year, 400) == 0))
	qui replace g_day =	`eth_day_var'+9 if inrange(`eth_day_var', 1,22) &  `eth_month_var'== 5 & mod(`eth_year_var', 4) == 0  & (mod(g_year, 4) == 0 & (mod(g_year, 100) != 0 | mod(g_year, 400) == 0))
	qui replace g_day = `eth_day_var'-22 if inrange(`eth_day_var', 23,30) &  `eth_month_var'== 5 & mod(`eth_year_var', 4) == 0  & (mod(g_year, 4) == 0 & (mod(g_year, 100) != 0 | mod(g_year, 400) == 0))
	qui replace g_day = `eth_day_var'+8 if inrange(`eth_day_var', 1,21) &  `eth_month_var'== 6 & mod(`eth_year_var', 4) == 0  & (mod(g_year, 4) == 0 & (mod(g_year, 100) != 0 | mod(g_year, 400) == 0))

*************************************************************************************************						
***CONVERT MONTH:
*************************************************************************************************						
* IF NOT A LEAP YEAR IN ETHIOPIAN CALENDAR:	

	qui replace g_month = 1 if inrange(`eth_day_var', 23, 30) &  `eth_month_var' == 4 & mod(`eth_year_var', 4) != 0 

	qui replace g_month = 1 if inrange(`eth_day_var', 1, 23) &  `eth_month_var' == 5 & mod(`eth_year_var', 4) != 0 
	qui replace g_month = 2 if inrange(`eth_day_var', 24, 30) &  `eth_month_var' == 5 & mod(`eth_year_var', 4) != 0 
	
	qui replace g_month = 2 if inrange(`eth_day_var', 1, 21) &  `eth_month_var' == 6 & mod(`eth_year_var', 4) != 0 
	qui replace g_month = 3 if inrange(`eth_day_var', 22, 30) &  `eth_month_var' == 6 & mod(`eth_year_var', 4) != 0 

 	qui replace g_month = 3 if inrange(`eth_day_var', 1, 22) &  `eth_month_var' == 7 & mod(`eth_year_var', 4) != 0 
	qui replace g_month = 4 if inrange(`eth_day_var', 23, 30) &  `eth_month_var' == 7 & mod(`eth_year_var', 4) != 0 	
	
 	qui replace g_month = 4 if inrange(`eth_day_var', 1, 22) &  `eth_month_var' == 8 & mod(`eth_year_var', 4) != 0 
	qui replace g_month = 5 if inrange(`eth_day_var', 23, 30) &  `eth_month_var' == 8 & mod(`eth_year_var', 4) != 0 	

  	qui replace g_month = 5 if inrange(`eth_day_var', 1, 23) &  `eth_month_var' == 9 & mod(`eth_year_var', 4) != 0 
	qui replace g_month = 6 if inrange(`eth_day_var', 24, 30) &  `eth_month_var' == 9 & mod(`eth_year_var', 4) != 0 		

  	qui replace g_month = 6 if inrange(`eth_day_var', 1, 23) &  `eth_month_var' == 10 & mod(`eth_year_var', 4) != 0 
	qui replace g_month = 7 if inrange(`eth_day_var', 24, 30) &  `eth_month_var' == 10 & mod(`eth_year_var', 4) != 0 			
	
  	qui replace g_month = 7 if inrange(`eth_day_var', 1, 24) &  `eth_month_var' == 11 & mod(`eth_year_var', 4) != 0 
	qui replace g_month = 8 if inrange(`eth_day_var', 25, 30) &  `eth_month_var' == 11 & mod(`eth_year_var', 4) != 0 		

  	qui replace g_month = 8 if inrange(`eth_day_var', 1, 25) &  `eth_month_var' == 12 & mod(`eth_year_var', 4) != 0 
	qui replace g_month = 9 if inrange(`eth_day_var', 26, 30) &  `eth_month_var' == 12 & mod(`eth_year_var', 4) != 0 		
 
	qui replace g_month = 9 if inrange(`eth_day_var', 1, 6) &  `eth_month_var' == 13 & mod(`eth_year_var', 4) != 0 		

  	qui replace g_month = 9 if inrange(`eth_day_var', 1, 20) &  `eth_month_var' == 1 & mod(`eth_year_var', 4) != 0 
	qui replace g_month = 10 if inrange(`eth_day_var', 21, 30) &  `eth_month_var' == 1 & mod(`eth_year_var', 4) != 0 		

  	qui replace g_month = 10 if inrange(`eth_day_var', 1, 21) &  `eth_month_var' == 2 & mod(`eth_year_var', 4) != 0 
	qui replace g_month = 11 if inrange(`eth_day_var', 22, 30) &  `eth_month_var' == 2 & mod(`eth_year_var', 4) != 0 		

  	qui replace g_month = 11 if inrange(`eth_day_var', 1, 21) &  `eth_month_var' == 3 & mod(`eth_year_var', 4) != 0 
	qui replace g_month = 12 if inrange(`eth_day_var', 22, 30) &  `eth_month_var' == 3 & mod(`eth_year_var', 4) != 0 		

  	qui replace g_month = 12 if inrange(`eth_day_var', 1, 22) &  `eth_month_var' == 4 & mod(`eth_year_var', 4) != 0 

 
*** IF A LEAP YEAR IN ETHIOPIAN CALENDAR

	qui replace g_month = 1 if inrange(`eth_day_var', 22, 30) &  `eth_month_var' == 4 & mod(`eth_year_var', 4) == 0 
	
	qui replace g_month = 1 if inrange(`eth_day_var', 1, 23) &  `eth_month_var' == 5 & mod(`eth_year_var', 4) == 0 
	qui replace g_month = 2 if inrange(`eth_day_var', 24, 30) &  `eth_month_var' == 5 & mod(`eth_year_var', 4) == 0 

	qui replace g_month = 2 if inrange(`eth_day_var', 1, 21) &  `eth_month_var' == 6 & mod(`eth_year_var', 4) == 0 
	qui replace g_month = 3 if inrange(`eth_day_var', 22, 30) &  `eth_month_var' == 6 & mod(`eth_year_var', 4) == 0 

	qui replace g_month = 3 if inrange(`eth_day_var', 1, 22) &  `eth_month_var' == 7 & mod(`eth_year_var', 4) == 0 
	qui replace g_month = 4 if inrange(`eth_day_var', 23, 30) &  `eth_month_var' == 7 & mod(`eth_year_var', 4) == 0 

	qui replace g_month = 4 if inrange(`eth_day_var', 1, 22) &  `eth_month_var' == 8 & mod(`eth_year_var', 4) == 0 
	qui replace g_month = 5 if inrange(`eth_day_var', 23, 30) &  `eth_month_var' == 8 & mod(`eth_year_var', 4) == 0 

	qui replace g_month = 5 if inrange(`eth_day_var', 1, 23) &  `eth_month_var' == 9 & mod(`eth_year_var', 4) == 0 
	qui replace g_month = 6 if inrange(`eth_day_var', 24, 30) &  `eth_month_var' == 9 & mod(`eth_year_var', 4) == 0 

	qui replace g_month = 6 if inrange(`eth_day_var', 1, 23) &  `eth_month_var' == 10 & mod(`eth_year_var', 4) == 0 
	qui replace g_month = 7 if inrange(`eth_day_var', 24, 30) &  `eth_month_var' == 10 & mod(`eth_year_var', 4) == 0 

	qui replace g_month = 7 if inrange(`eth_day_var', 1, 24) &  `eth_month_var' == 11 & mod(`eth_year_var', 4) == 0 
	qui replace g_month = 8 if inrange(`eth_day_var', 25, 30) &  `eth_month_var' == 11 & mod(`eth_year_var', 4) == 0 

	qui replace g_month = 8 if inrange(`eth_day_var', 1, 25) &  `eth_month_var' == 12 & mod(`eth_year_var', 4) == 0 
	qui replace g_month = 9 if inrange(`eth_day_var', 26, 30) &  `eth_month_var' == 12 & mod(`eth_year_var', 4) == 0 

	qui replace g_month = 9 if inrange(`eth_day_var', 1, 6) &  `eth_month_var' == 13 & mod(`eth_year_var', 4) == 0 
	
	qui replace g_month = 9 if inrange(`eth_day_var', 1, 20) &  `eth_month_var' == 1 & mod(`eth_year_var', 4) == 0 
	qui replace g_month = 10 if inrange(`eth_day_var', 21, 30) &  `eth_month_var' == 1 & mod(`eth_year_var', 4) == 0 
	
	qui replace g_month = 10 if inrange(`eth_day_var', 1, 21) &  `eth_month_var' == 2 & mod(`eth_year_var', 4) == 0 
	qui replace g_month = 11 if inrange(`eth_day_var', 22, 30) &  `eth_month_var' == 2 & mod(`eth_year_var', 4) == 0 
	
	qui replace g_month = 11 if inrange(`eth_day_var', 1, 21) &  `eth_month_var' == 3 & mod(`eth_year_var', 4) == 0 
	qui replace g_month = 12 if inrange(`eth_day_var', 22, 30) &  `eth_month_var' == 3 & mod(`eth_year_var', 4) == 0 
	
	qui replace g_month = 12 if inrange(`eth_day_var', 1, 21) &  `eth_month_var' == 4 & mod(`eth_year_var', 4) == 0 
	
	*Exceptions due to leap years in either calendar or if previous year in Ethiopian calendar was a leap year:
 	qui replace g_month = 10 if `eth_day_var' == 20 &   `eth_month_var' == 1 & mod(`eth_year_var', 4) == 0  & mod(`eth_year_var'-1, 4) != 0  & mod(g_year, 4) != 0
	qui replace g_month = 11 if `eth_day_var' == 21 &   `eth_month_var' == 2 & mod(`eth_year_var', 4) == 0  & mod(`eth_year_var'-1, 4) != 0  & mod(g_year, 4) != 0 
	qui replace g_month = 12 if `eth_day_var' == 21 &   `eth_month_var' == 3 & mod(`eth_year_var', 4) == 0  & mod(`eth_year_var'-1, 4) != 0  & mod(g_year, 4) != 0 
	qui replace g_month = 1 if `eth_day_var' == 22 &   `eth_month_var' == 4 & mod(`eth_year_var', 4) == 0  & mod(`eth_year_var'-1, 4) != 0  & mod(g_year, 4) != 0 
	qui replace g_month = 2 if `eth_day_var' == 23 &   `eth_month_var' == 5 & mod(`eth_year_var', 4) == 0  & mod(`eth_year_var'-1, 4) != 0  & (mod(g_year, 4) == 0 & (mod(g_year, 100) != 0 | mod(g_year, 400) == 0))
	qui replace g_month = 1 if `eth_day_var' == 23 &   `eth_month_var' == 5 & mod(`eth_year_var', 4) != 0  & mod(`eth_year_var'-1, 4) == 0  & mod(g_year, 4) != 0 

	
*************************************************************************************************						
***CHECKS AND VARIABLE LABELS:
*************************************************************************************************		
	
    	* Check if any of the original Ethiopian date observations are missing or have any oddities. If yes, set all Gregorian dates missing
	qui foreach var of varlist g_year g_month g_day {
    	replace `var' = . if missing(`eth_year_var') | missing(`eth_month_var') | missing(`eth_day_var')
	replace `var' = . if !inrange(`eth_day_var', 1, 30)
	replace `var' = . if !inrange(`eth_month_var', 1, 13)
	replace `var' = . if `eth_month_var'==13 & !inrange(`eth_day_var', 1, 6)

	}
 
	* Check if the year variable is outside the range 1901-2099 and display a warning if so
	if sum(g_year <= 1900 | g_year >= 2100) > 0 {
    	display as err "Warning: The Gregorian year variable contains values outside the range 1901-2099. These Gregorian calendar dates have been set missing."

    	* Check if any of the original Ethiopian date observations are missing. If yes, set all Gregorian dates missing
	qui foreach var of varlist g_year g_month g_day {
    	replace `var' = . if g_year <= 1900 | g_year >= 2100
	}

}
	* Label the variables that were created
	label var g_year "Gregorian calendar year"
	label var g_day "Gregorian calendar day"
	label var g_month "Gregorian calendar month"
	 
	 
     * End of program
end