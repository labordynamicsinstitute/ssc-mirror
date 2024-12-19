/******************************************************************************* 
Title: 			AETR, METR model ado file
Author: 		Andualem Mengistu & Shafik Hebous
Email:			amengistu2@imf.org
Date created: 	July 11, 2024
Description:	Master file for running the ETR simulation
Version:		0.1.0
*******************************************************************************/	

capture program drop etr 
program define etr
    version 15
    set type double
	clear all
	drop _all

syntax,    [system(string)				/// cit, cft, or ace
		   inflation(real 0.05) 		/// inflation rate (default 5%)
           realint(real 0.05) 			/// real interest rate (default 5%)
           p(real 0.1)					/// profit level (default 10%)
		   debt(real 0)					/// 1 if completely financed with debt. zero is the default. 
		   newequity(real 0)			/// 1 if completely financed with new equity. Zero is default. It can take values in the range of 0 to 1
		   deprtype(string)				/// d for declining balance, s for straightline depreciation method.
		   depreciation(real 0.25) 		/// the depreciation rate for tax purposes. default value is 25%
           delta(real 0.25) 			/// economic depreciation rate. Default value is 25%
           holiday(real 0)				/// the number of years of tax holiday
		   qrtc(real 0) 				/// as a share of the book value of capital (the tax depreciated amount of capital). 0% is the defualt value. The bracket indicates that these are optional.
           nqrtc(real 0) 				/// as a share of capital (the tax depreciated amount of capital). 0% is the default value
           sbie(real 1.5) 				/// Substance based income exclusion (as a percentage of the book value of capital). 150% is the default value
		   minrate(real 0.15)			/// the minimum tax rate
		   minimumtax(string) 			/// "yes" if the user would like to calculate the METR inclusive of pillar two. the default is no minimum tax.
		   refund(string)				/// "yes" if the user would like to calculate the AETR and METR for a refundbale tax system. "no" if the system is not refundable
		   pitdiv(real 0)				/// The tax rate on dividend income in source country
		   pitint(real 0)				/// The tax rate on interest income in source country
		   pitcgain(real 0)				/// The tax rate on capital gains income in source country
		   ]

			
/***********************************************************************************************
************Making sure parameters are specified correctly*******************************************************************/			

if `inflation'<-0.1 | `inflation'>1 {
	display "The specified inflation value is out of the acceptable range. Acceptable range is -0.1 to 1 (i.e., between -10% and 100%)"
	exit 125
}
			
if `realint'<0 | `realint'>0.2 {
	display "The specified real interest value is out of the acceptable range. Acceptable range is 0 to 0.2 (i.e., between 0 and 20%)"
	exit 125
}

if `p'<0 | `p'>1 {
	display "The specified profitability value is out of the acceptable range. Acceptable range is 0 to 1 (i.e., between 0 and 100%)"
	exit 125
}
				

if `debt'<0 | `debt'>1 {
	display "The specified debt financing ratio is out of the acceptable range. Acceptable range is 0 to 1 (i.e., between 0 and 100%)"
	exit 125
}


if `depreciation'<0 | `depreciation'>1 {
	display "The specified depcreciation parameter is out of the acceptable range. Acceptable range is 0 to 1 (i.e., between 0 and 100%)"
	exit 125
}

if `delta'<0 | `delta'>1 {
	display "The specified economic depcreciation parameter is out of the acceptable range. Acceptable range is 0 to 0.1 (i.e., between 0 and 100%)"
	exit 125
}

if `qrtc'<0 | `qrtc'>0.1 {
	display "The specified QRTC parameter is out of the acceptable range. Acceptable range is 0 to 0.1 (i.e., between 0 and 10%)"
	exit 125
}

if `nqrtc'<0 | `nqrtc'>0.1 {
	display "The specified NQRTC parameter is out of the acceptable range. Acceptable range is 0 to 0.1 (i.e., between 0 and 10%)"
	exit 125
}


if `sbie'<0 | `sbie'>2{
	display "The specified sbie parameter is out of the acceptable range. Acceptable range is 0 to 2"    //0 represnets that all capital is intangible and there is no wage expense, 1 represents that production takes place using only capital, and 2 represnts that wage expense is equal to the book value of capital. if it is zero, all capital is intangible and there is no wage expense.
	exit 125
}

if "`system'" == "" {
        local system "cit"                						// default value of minimumtax is "no"
    }

if "`deprtype'"!="" & "`deprtype'"!="sl" & "`deprtype'"!="db" {
	display "deprtype only accepts sl, db, or empty. The specified option is not allowed."
	exit 125
}

if "`minimumtax'" == "" {
        local minimumtax "no"                						// default value of minimumtax is "no"
    }

if "`deprtype'" == "" {
        local deprtype "db"                								// default depreciation scheme is declining balance
    }

if "`refund'" == "" {
        local refund "yes"                						// default value of refund is "yes"
    }
			
local profit=`p'
	
/***********************************************************************************************
************************************Program code here*******************************************/
quietly {
	
	
// Set observations. This helps us calculate NPVs
	set 		obs 150   														// sets values from 1 to 150
	gen 		t=_n-1															// starts time from zero
 
 
	local i = `realint' + `inflation' + `realint' * `inflation'					// nominal interst rate

	***Parameters based on the intereaction of PIT and CIT
	local gamma=(1- `pitdiv')/(1-`pitcgain')									//((1-m_d))/((1-z)(1-c))=γ
	local rho=((1- `pitint')*`i')/(1-`pitcgain')								//(1-m_i )i/((1-z))=ρ

	
	local		A_decline=(`depreciation'*(1+`rho')/(`depreciation'+`rho'))*((1-`depreciation')/(1+`rho'))^(`holiday')	// present value of depreciation (declining balance), accounting for PIT

	local		A_straight=`depreciation'*((1+`rho')/`rho')*max(((1/(1+`rho'))^(`holiday')-(1/((1+`rho')^(1/`depreciation')))),0)		// present value of depreciation (straight line), accounting for PIT
	
	if "`deprtype'" == "db" {
		local npvdep=`A_decline'
		local acepdv=`i'*((1-`depreciation')/(`rho'+`depreciation'))*((1-`depreciation')/(1+`rho'))^`holiday'
	}
	
	if "`deprtype'" == "sl" {
		local npvdep=`A_straight'
*		local acepdv=`i'*((1-`depreciation')/(`rho'+`depreciation'))*((1-`depreciation')/(1+`rho'))^`holiday'

	}
	
	if "`system'"=="cft" {
		if `holiday'== 0 {
			local cftpdv=1  
			}
		else {
			local	cftpdv=0
			}
	}
	
	if "`deprtype'" == "db" {
        gen			double SBIE=0
		replace		SBIE=0.05*`sbie'*(1-`depreciation')^t  if t>=0										
		// Substance based income exclusion is 5% of capital and payroll. If missing, we use an assumption: payroll is half of tagible asst. Which means,  the tangible asset=150%*(tax depreciated value of the asset). 
		//5%*1.5*(1-phi)^t=7.5%*(1-`depreciation')^t        
		la var 		SBIE "Substance based income exclusion under declining balance depreciation"
	     } 
	

	if "`deprtype'" == "sl" {
        gen			double SBIE=0
		replace		SBIE=0.05*`sbie'*max((1-t*`depreciation'),0)  if t>=0									
		// Substance based income exclusion is 5% of capital and payroll. If missing, we use 150% as the tangible asset=tax depreciated value of the asset. 
		//payroll is half of tagible asst. 5%*1.5*(1-phi)^t=7.5%*(1-phi)^t        
		la var 		SBIE "Substance based income exclusion under straight line depreciation"
	    } 
	 
	// qualified refundable tax credit (it is considered income for GloBE purposes). Set it to zero if you want to calculate the AETR without qualified refundbale tax credit
		gen 		QRTC=0																
		replace		QRTC=`qrtc'*(1-`delta')^t   if t>=1								// The `qrtc' is expressed in decimal. example: 0.01 means 1%

	// Non-qualified refundable tax credit (it is considered a reduction in tax for GloBE purposes). Set it to zero if you want to calculate the AETR without non-qualified refundbale tax credit
		gen 		NQRTC=0																
		replace		NQRTC=`nqrtc'*(1-`delta')^t   if t>=1							// The `nqrtc' is expressed in decimal format. example: 0.01 means 1%
	
		tempfile 	generalparamter
		save 		`generalparamter',replace	

/*============================================================================================================
1. In this section, we generate the AETR, without a top-up, of a standard CIT, R-based cash flow tax, and ACE 
=============================================================================================================*/

/*================
Refundable System
=================*/

if "`refund'"=="yes" {

	 	gen 		double 		revenue=0 				 												
		replace			 		revenue=0	 													if t==0 	// revenue in period 0 
		replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
		gen  		double		revenue_time=revenue/((1 + `rho') ^ t)										// discounted value of revenue
		egen 		double 		revenue_NPV= total(revenue_time)											// NPV of revenue

***Standard CIT

if "`system'"=="cit" {
	preserve

		if "`deprtype'" == "db" {
		gen 		double 		profit_cit=0 													// place holder
		replace			 		profit_cit=-`depreciation'	 	if t==0 						// taxable income in period 0 (becasue of refundability)
		replace					profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1)     if t>0														// taxable income in periods after period 0
		}
		
		if "`deprtype'" == "sl" {
		gen 		double 		profit_cit=0												// place holder
		replace			 		profit_cit=-`depreciation'		if t==0						// taxable income in period 0 (becasue of refundability)
		replace					profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1)     if t>0 											// taxable income in periods after period 0
		}
		la var 					profit_cit  "profit under a refundable standard CIT."
		
		forval 	taxrate=0(1)50 {	
		gen  		double		Tax_cit`taxrate'=0
		replace					Tax_cit`taxrate' =(`taxrate'/100) * profit_cit -QRTC-min(max(`taxrate'*profit_cit/100,0),NQRTC)	if `holiday'==0		// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))
		replace					Tax_cit`taxrate' =-QRTC		if `holiday'>0 & t<=`holiday'		// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))		
		replace					Tax_cit`taxrate' =(`taxrate'/100) * profit_cit -QRTC-min(max(`taxrate'*profit_cit/100,0),NQRTC)	if `holiday'>0 & t>`holiday'		// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))
		
		gen  		double 		Tax_cit_time`taxrate' = Tax_cit`taxrate'/((1 + `rho') ^ t)			// The discounted value of each period's tax liability
		egen 		double 		Tax_cit_NPV`taxrate' = total(Tax_cit_time`taxrate')					// The NPV of taxes paid
		}
		
		tempfile 	cit_pregoble								// This will be used later to generate the AETR for the case where there is a top-up tax
		save 		`cit_pregoble'
		
		forval 	taxrate=0(1)50 {
		gen			double		econrent_cit`taxrate'=0
		replace 				econrent_cit`taxrate'=`gamma'*(revenue_NPV-1-Tax_cit_NPV`taxrate')+ `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation'))

		gen 		double 		AETR_CIT`taxrate'=100*((`p'-`realint')/(`realint'+`delta')-econrent_cit`taxrate')/(`p'/(`realint'+`delta'))
		}
	
		keep		AETR*
		duplicates  drop
		gen 		period=0
		reshape 	long  AETR_CIT   , i(period) 
		drop		period
		rename 		_j statutory_tax_rate

		la var AETR_CIT 		"AETR of a Standard CIT System (%)"
		la var 		statutory_tax_rate "tax rate in %"
		tempfile  	pre_globe
		save 	 	`pre_globe.dta', replace
restore
	
}



***R-based cashflow tax
	
if "`system'"=="cft" {
	preserve
		
		gen 		double 		profit_cft=0
		replace					profit_cft=-1	  														if t==0									// period 0 taxable income
		replace					profit_cft=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)			if t>=1
		la var 					profit_cft  "profit under a refundable cahsflow tax"
	
		forval 	taxrate=0(1)50 {	
		gen  		double		Tax_cft`taxrate'=0  			// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))
		replace					Tax_cft`taxrate' =(`taxrate'/100) * profit_cft -QRTC-min(max(`taxrate'*profit_cft/100,0),NQRTC)	if `holiday'==0		
		replace					Tax_cft`taxrate' =-QRTC		if `holiday'>0 & t<=`holiday'		
		replace					Tax_cft`taxrate' =(`taxrate'/100) * profit_cft -QRTC-min(max(`taxrate'*profit_cft/100,0),NQRTC)	if `holiday'>0	& t>`holiday'
		gen  		double 		Tax_cft_time`taxrate'= Tax_cft`taxrate'/((1 + `rho') ^ t)			// The discounted value of each period's tax liability
		egen 		double		Tax_cft_NPV`taxrate'= total(Tax_cft_time`taxrate')					// NPV of the the sum of taxes paid
		}
		
	
		tempfile 	cft_pregoble							// This will be used later to generate the AETR for the case where there is a top-up tax
		save 		`cft_pregoble'
		
		forval 	taxrate=0(1)50 {
		gen			double		econrent_cft`taxrate'=0
		replace 				econrent_cft`taxrate'=`gamma'*(revenue_NPV-1-Tax_cft_NPV`taxrate')+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation')) 
		gen 		double		AETR_CFT`taxrate'=100*((`p'-`realint')/(`realint'+`delta')-econrent_cft`taxrate')/(`p'/(`realint'+`delta'))
		}
	
		keep		AETR*
		duplicates  drop
		gen 		period=0
		reshape 	long  AETR_CFT   , i(period) 
		drop		period
		rename 		_j statutory_tax_rate

		la var 		AETR_CFT 		"AETR of an R-based Cash Flow Tax System (%)"
		la var 		statutory_tax_rate "tax rate in %"
		tempfile  	pre_globe
		save 	 	`pre_globe.dta', replace
	restore
	
}		


***ACE
if "`system'"=="ace" {	
	preserve
	
		if "`deprtype'" == "db" {
		gen 		double		profit_ace=0																										
		replace					profit_ace=-`depreciation'			if t==0																					//taxable income in period 0
		replace					profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-`i'*(1-`depreciation')^t   if t>0
		}
		
		if "`deprtype'" == "sl" {
		gen 		double		profit_ace`taxrate'=0																					//taxable income in period 0
		replace					profit_ace`taxrate'=-`depreciation'				if t==0																				//taxable income in period 0
		replace					profit_ace`taxrate'=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-`i'*max((1-t*`depreciation'),0)   if t>0 
		}
		
		la 			var 		profit_ace "profit under a refundable ACE"
	 
	 
		forval 	taxrate=0(1)50 {	
	
		gen  		double		Tax_ace`taxrate'=0  			// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))
		replace					Tax_ace`taxrate' =(`taxrate'/100) * profit_ace -QRTC-min(max(`taxrate'*profit_ace/100,0),NQRTC)	if `holiday'==0		
		replace					Tax_ace`taxrate' =-QRTC		if `holiday'>0 & t<=`holiday'		
		replace					Tax_ace`taxrate' =(`taxrate'/100) * profit_ace -QRTC-min(max(`taxrate'*profit_ace/100,0),NQRTC)	if `holiday'>0	& t>`holiday'
	
		gen  		double		Tax_ace_time`taxrate'= Tax_ace`taxrate'/((1 + `rho') ^ t)			// The discounted value of each period's tax liability
		egen 		double		Tax_ace_NPV`taxrate'= total(Tax_ace_time`taxrate')					// NPV of the the sum of taxes paid
		}
		
		tempfile 	ace_pregoble								// This will be used later to generate the AETR for the case where there is a top-up tax
		save 		`ace_pregoble'
		
		forval 	taxrate=0(1)50 {
		gen			double		econrent_ace`taxrate'=0
		replace 				econrent_ace`taxrate'=`gamma'*(revenue_NPV-1-Tax_ace_NPV`taxrate')+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation')) 
		gen 		double		AETR_ACE`taxrate'=100*((`p'-`realint')/(`realint'+`delta')-econrent_ace`taxrate')/(`p'/(`realint'+`delta'))	
		}
		
		keep		AETR*
		duplicates  drop
		gen 		period=0
		reshape 	long  AETR_ACE   , i(period) 
		drop		period
		rename 		_j statutory_tax_rate

		la var AETR_ACE 		"AETR of an ACE system (%)"
		la var 		statutory_tax_rate "tax rate in %"
		tempfile  	pre_globe
		save 	 	`pre_globe.dta', replace
	restore
}

}																						// closes refund==yes

/*================
A non-refundable System
=================*/

if "`refund'"=="no" {
		gen 		double 		revenue=0 				 												
		replace			 		revenue=0	 													if t==0 	// revenue in period 0 
		replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
		gen  		double		revenue_time=revenue/((1 + `rho') ^ t)										// discounted value of revenue
		egen 		double 		revenue_NPV= total(revenue_time)	
	

**Standard CIT
	if "`system'"=="cit" {
		preserve
		if "`deprtype'" == "db" {
		gen 		double 		profit_cit=0 				 									// taxable income in period 0 (becasue of refundability)
		replace					profit_cit=(`p'+`delta')*((1+`inflation'))-`depreciation'-`depreciation'*(1-`depreciation') -`debt'*`i'     if t==1			// taxable income in period 1
		replace					profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit[_n-1])    if t>1			
		// taxable income  after period 1
			}
		
		if "`deprtype'" == "sl" {
		gen 		double 		profit_cit=0												
		replace			 		profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt'*`i'	if t==1					
		// (including loss carryforward due to non-refundability)							
		replace					profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit[_n-1])    if t>1 		
		// taxable income in periods after period 1
		}
		
		la var 					profit_cit  "profit under a refundable standard CIT."
		
		forval 	taxrate=0(1)50 {
		gen  		double		Tax_cit`taxrate'=0
	
		replace					Tax_cit`taxrate' =(`taxrate'/100)*max(profit_cit,0) -QRTC-min((`taxrate'/100)*max(profit_cit,0),NQRTC)	if `holiday'==0		// period by period tax liability (if taxable income is negative, then tax is zero (i.e., no-refund))
	
		replace					Tax_cit`taxrate' =-QRTC			if t<= `holiday' & `holiday'>0		
		replace					Tax_cit`taxrate' =(`taxrate'/100)*max(profit_cit,0) -QRTC-min((`taxrate'/100)*max(profit_cit,0),NQRTC)	if t>`holiday' & `holiday'>0		
		gen  		double 		Tax_cit_time`taxrate' = Tax_cit`taxrate'/((1 + `rho') ^ t)			// The discounted value of each period's tax liability
		egen 		double 		Tax_cit_NPV`taxrate' = total(Tax_cit_time`taxrate')
		}
		
		tempfile 	cit_pregoble								// This will be used later to generate the AETR for the case where there is a top-up tax
		save 		`cit_pregoble'
		
		forval 	taxrate=0(1)50 {
		gen			double		econrent_cit`taxrate'=0
		replace 				econrent_cit`taxrate'=`gamma'*(revenue_NPV-1-Tax_cit_NPV`taxrate')+ `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation')) 

		gen 		double 		AETR_CIT`taxrate'=100*((`p'-`realint')/(`realint'+`delta')-econrent_cit`taxrate')/(`p'/(`realint'+`delta'))
		}
		
		keep		AETR*
		duplicates  drop
		gen 		period=0
		reshape 	long AETR_CIT , i(period) 
		drop		period
		rename 		_j statutory_tax_rate
		
		la var AETR_CIT 		"AETR of a standard CIT (%)"

		la var 		statutory_tax_rate "tax rate in %"
		tempfile  	pre_globe
		save 	 	`pre_globe.dta', replace
	restore
}


***R-based cashflow tax
if "`system'"=="cft" {

		preserve		
		gen 		double 		profit_cft=0
		replace					profit_cft=(`p'+`delta')*(1+`inflation')-1														if t==1
		replace					profit_cft=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1) +  min(0,profit_cft[_n-1])		if t>1
		la var 					profit_cft  "profit under a refundable cahsflow tax"
		
		forval 	taxrate=0(1)50 {
		gen  		double		Tax_cft`taxrate'=0
		replace					Tax_cft`taxrate' =(`taxrate'/100)*max(profit_cft,0) -QRTC-min((`taxrate'/100)*max(profit_cft,0),NQRTC)	if `holiday'==0		// period by period tax liability (if taxable income is negative, then tax is zero (i.e., no-refund))
		
		replace					Tax_cft`taxrate' =-QRTC			if `holiday'>0 & t<=`holiday'		
		replace					Tax_cft`taxrate' =(`taxrate'/100)*max(profit_cft,0) -QRTC-min((`taxrate'/100)*max(profit_cft,0),NQRTC)	if t>`holiday' & `holiday'>0		
		gen  		double 		Tax_cft_time`taxrate'= Tax_cft`taxrate'/((1 + `rho') ^ t)			// The discounted value of each peruiod's tax liability
		egen 		double		Tax_cft_NPV`taxrate'= total(Tax_cft_time`taxrate')					// NPV of the the sum of taxes paid
	    }
		
		tempfile 	cft_pregoble								// This will be used later to generate the AETR for the case where there is a top-up tax
		save 		`cft_pregoble'
	
	forval 	taxrate=0(1)50 {
		gen			double		econrent_cft`taxrate'=0
		replace 				econrent_cft`taxrate'=`gamma'*(revenue_NPV-1-Tax_cft_NPV`taxrate')+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation')) 
		gen 		double		AETR_CFT`taxrate'=100*((`p'-`realint')/(`realint'+`delta')-econrent_cft`taxrate')/(`p'/(`realint'+`delta'))
		}
	
	
		keep		AETR*
		duplicates  drop
		gen 		period=0
		reshape 	long  AETR_CFT , i(period) 
		drop		period
		rename 		_j statutory_tax_rate
		

		la var AETR_CFT 		"AETR of an R-based cash flow tax (%)"

		la var 		statutory_tax_rate "tax rate in %"
		tempfile  	pre_globe
		save 	 	`pre_globe.dta', replace
	restore
}

***ACE
if "`system'"=="ace" {

		preserve		
		if "`deprtype'" == "db" {
		gen 		double		profit_ace=0																					
		replace					profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`i'*(1-`depreciation')^t  if t==1				//taxable income in period 1
		replace					profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-`i'*(1-`depreciation')^t +  min(0,profit_ace[_n-1])  if t>1
		}
		
		if "`deprtype'" == "sl" {
		gen 		double		profit_ace=0																					
		replace					profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`i'*max(1-`depreciation',0)				if t==1								//taxable income in period 1
		replace					profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-`i'*max(1-t*`depreciation',0) +  min(0,profit_ace[_n-1])    if t>1 
		}
		
		la 			var 		profit_ace "profit under a refundable ACE"
	 
		forval 	taxrate=0(1)50 {
		gen  		double		Tax_ace`taxrate'=0
		replace					Tax_ace`taxrate' =(`taxrate'/100)*max(profit_ace,0) -QRTC-min((`taxrate'/100)*max(profit_ace,0),NQRTC)	if `holiday'==0		// period by period tax liability (if taxable income is negative, then tax is zero (i.e., no-refund))
		replace					Tax_ace`taxrate' =-QRTC	if t<=`holiday' & `holiday'>0		
		replace					Tax_ace`taxrate' =(`taxrate'/100)*max(profit_ace,0) -QRTC-min((`taxrate'/100)*max(profit_ace,0),NQRTC)	if t>`holiday' & `holiday'>0		

		gen  		double		Tax_ace_time`taxrate'= Tax_ace`taxrate'/((1 + `rho') ^ t)									// The discounted value of each period's tax liability
		egen 		double		Tax_ace_NPV`taxrate'= total(Tax_ace_time`taxrate')										// NPV of the the sum of taxes paid
		}
		
		tempfile 	ace_pregoble												// This will be used later to generate the AETR for the case where there is a top-up tax
		save 		`ace_pregoble'
		
		forval 	taxrate=0(1)50 {		
		gen			double		econrent_ace`taxrate'=0
		replace 				econrent_ace`taxrate'=`gamma'*(revenue_NPV-1-Tax_ace_NPV`taxrate')+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation')) 
		
		gen 		double		AETR_ACE`taxrate'=100*((`p'-`realint')/(`realint'+`delta')-econrent_ace`taxrate')/(`p'/(`realint'+`delta'))	
		}
		
		
		keep		AETR*
		duplicates  drop
		gen 		period=0
		reshape 	long AETR_ACE, i(period) 
		drop		period
		rename 		_j statutory_tax_rate
		

		la var 		AETR_ACE 		"AETR of an ACE system (%)"

		la var 		statutory_tax_rate "tax rate in %"
		tempfile  	pre_globe
		save 	 	`pre_globe.dta', replace
	restore
}
}																				// closes the no-refund system

if "`minimumtax'"=="no" {
use  	`pre_globe.dta', clear

keep 		if statutory_tax_rate<=40
keep 		statutory_tax_rate AETR*
format 		AETR* %9.02f
tempfile	aetr
save		`aetr', replace
}	
																			


/*=========================================================================================================================================================
										Section 2: Adding the effect of the GloBE rules
										
In this section, we calculate the AETR of a system including a top-up under GloBE for each tax system we have anlyzed above. 
========================================================================================================================================================*/
if "`minimumtax'"=="yes" {
	
***Standard CIT 

if "`system'"=="cit" {
	
	if "`refund'"=="yes" | "`refund'"=="no" {


	if "`deprtype'" == "db" {
		gen 		double profit_tpt_cit=0								// The tax base for Pillar two													
		replace		profit_tpt_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt'*`i'  if t==1					
		replace		profit_tpt_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_tpt_cit[_n-1])  if t>1

		*Covered income
		gen 		double cov_profit_cit=0														// covered profit considered for the top-up tax
		replace		cov_profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt'*`i' +QRTC    if t==1
		replace		cov_profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) +QRTC+ min(0,cov_profit_cit[_n-1])  if t>1
		la var 		cov_profit_cit  "covered income of a standard CIT"
		}

		if "`deprtype'" == "sl" {
		gen 		double profit_tpt_cit=0																	
		replace		profit_tpt_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation') -`debt'*`i'  if t==1					
		replace		profit_tpt_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_tpt_cit[_n-1])  if t>1 

		*Covered income
		gen 		double cov_profit_cit=0														// covered profit considered for the top-up tax
		replace		cov_profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt'*`i' +QRTC    if t==1
		replace		cov_profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) +QRTC+ min(0,cov_profit_cit[_n-1])  if t>1 
		la var 		cov_profit_cit  "covered income of a standard CIT"
		}
		
		
		*top-up tax base
		gen			double exprofit_cit=max(0,cov_profit_cit-SBIE)
		la var 		exprofit_cit  "Excess profit under stndard CIT"
		
		*The top-up tax rate is 15% minus the GloBE effetive tax rate (i.e., covered tax divided by covered income). Note that in the absence of qualified refundable tax credit, the ETR is similar to the statutory tax rate. Therefore, the top-up rate can be calaucltes as max(0, 15%-statutory tax rate).
		
			
		forval 		taxrate=0(1)40 { 
		gen 		covtax_cit`taxrate'=0										// covered tax
		replace 	covtax_cit`taxrate'=(`taxrate'/100)*max(0,profit_tpt_cit)-min((`taxrate'/100)*max(0,profit_tpt_cit),NQRTC) if `holiday'==0
		replace 	covtax_cit`taxrate'=(`taxrate'/100)*max(0,profit_tpt_cit)-min((`taxrate'/100)*max(0,profit_tpt_cit),NQRTC) if t>`holiday' & `holiday'>0
		gen			tpr_cit`taxrate'=max(0,`minrate'-(covtax_cit`taxrate')/cov_profit_cit)													//the top-up tax in each period for each value of the tax rate
		la var 		tpr_cit`taxrate' "Top up tax rate under stanadrd CIT"
		}
		
		*top-up tax amount
		forval 		taxrate=0(1)40 { 
		gen 		double tpt_cit`taxrate'=tpr_cit`taxrate'*exprofit_cit/(1+`rho')^t			// top-up tax (discounted value) 
		egen 		double total_tpt_cit`taxrate'=total(tpt_cit`taxrate')						// The NPV of top-up taxes paid
		la var		tpt_cit`taxrate' 			"top-up tax (discounted value)"
		la var 		total_tpt_cit`taxrate' 		"NPV of all top-up taxes paid: under the standard CIT"
		}

		
		merge 1:1 t using `cit_pregoble' 									// This merges the taxes paid before the top-up
		
		forval 		taxrate=0(1)40 { 
		gen 		double		total_cit`taxrate'=total_tpt_cit`taxrate'+Tax_cit_NPV`taxrate'			// Domestic tax + top-up tax
	
		gen 		double 		econrent_cit`taxrate'=0
		
		replace 				econrent_cit`taxrate'=`gamma'*(revenue_NPV-1-total_cit`taxrate')+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation')) 
		
		gen 		double		AETR_CIT`taxrate'=100*((`p'-`realint')/(`realint'+`delta')-econrent_cit`taxrate')/(`p'/(`realint'+`delta'))	
		}
		
		keep		AETR_*

		duplicates  drop

		gen 		period=0
		reshape 	long AETR_CIT, i(period) 
		drop		period

		rename 		_j		statutory_tax_rate
		la			var		statutory_tax_rate 		"tax rate in %"
		la			var		AETR_CIT		  	"AETR of a standard CIT in (%)"
	}
}																					// closes cit

***Cash flow tax

if "`system'"=="cft" {
	
	if "`refund'"=="yes" | "`refund'"=="no" {

	*Covered income (involves deduction of iterest since interest deduction is allowed under the GloBE rules)
	
	if "`deprtype'" == "db" {
	 
	gen 		double cov_profit_cft=0														// covered profit considered for the top-up tax
	replace		cov_profit_cft=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation')-`debt'*`i' +QRTC    if t==1 										
	replace		cov_profit_cft=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + QRTC+ min(0,cov_profit_cft[_n-1])  if t>1  
	la var 		cov_profit_cft  "covered tax of a refundable cashflow tax"
		
	*The covered tax base (i.e., the tax base based on which domestic tax is calcualted) (doesn't involve interest deduction)
	*Note that although the firms receives immediate expensing, from a GloBE persepctive, it is a timing issue. Therefore, the taxbase is calculated similar to the taxbase for standard CIT.
	gen 		double profit_cft_tpt=0
	replace		profit_cft_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation')    if t==1    // accounting for loss carryforward from period 0
	replace		profit_cft_tpt=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t + min(0,profit_cft_tpt[_n-1])  if t>1
	}
	
	if "`deprtype'" == "sl" {

	gen 		double cov_profit_cft=0														// covered profit considered for the top-up tax
	replace		cov_profit_cft=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt'*`i' +QRTC    if t==1 										
	replace		cov_profit_cft=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')-`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + QRTC+ min(0,cov_profit_cft[_n-1])  if t>1   
	la var 		cov_profit_cft  "covered tax of a refundable R"
		
	*The covered tax base (i.e., the tax base based on which domestic tax is calcualted) (doesn't involve interest deduction)
	*Note that although the firms receives immediate expensing, from a GloBE persepctive, it is a timing issue. Therefore, the taxbase is calculated similar to the taxbase for standard CIT.
	gen 		double profit_cft_tpt=0
	replace		profit_cft_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')  if t==1    // accounting for loss carryforward from period 0
	replace		profit_cft_tpt=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') + min(0,profit_cft_tpt[_n-1])  if t>1  
	}
	
		
	*top-up tax base (excessl profit)

	gen	double 	exprofit_cft=max(0,cov_profit_cft-SBIE)
	la var		exprofit_cft  "Excess profit under refundable R"

	forval 		taxrate=0(1)40 {
	gen 		covtax_cft`taxrate'=0
	replace 	covtax_cft`taxrate'=(`taxrate'/100)*max(0,profit_cft_tpt)-min((`taxrate'/100)*max(0,profit_cft_tpt),NQRTC) if `holiday'==0
	replace 	covtax_cft`taxrate'=(`taxrate'/100)*max(0,profit_cft_tpt)-min((`taxrate'/100)*max(0,profit_cft_tpt),NQRTC) if t>`holiday' & `holiday'>0
	gen	double	tpr_cft`taxrate'=max(0,`minrate'-(covtax_cft`taxrate')/cov_profit_cft)		if 	cov_profit_cft>0	
		//the top-up rate in each period for each value of the tax rate
	la var 		tpr_cft`taxrate' "Top up tax rate under R-based cashflow tax"
	}

	*top-up tax amount
	forval 		taxrate=0(1)40 { 
	gen 		double tpt_cft`taxrate'=tpr_cft`taxrate'*exprofit_cft/(1+`rho')^t			// top-up tax (discounted value) 
	egen 		double total_tpt_cft`taxrate'=total(tpt_cft`taxrate')
	la var		tpt_cft`taxrate' 		"top-up tax (discounted value)"
	la var 		total_tpt_cft`taxrate' 	"NPV of all top-up taxes paid: under the R-based cashflow tax"
	}

	merge 1:1 t using `cft_pregoble' 									// This merges the taxes paid before the top-up

	forval 		taxrate=0(1)40 { 
	gen 		double		total_cft`taxrate'=total_tpt_cft`taxrate'+Tax_cft_NPV`taxrate'   // NPV of domestic tax + NPV of top-up tax
	
	gen 		double 		econrent_cft`taxrate'=0
		
	replace 				econrent_cft`taxrate'=`gamma'*(revenue_NPV-1-total_cft`taxrate')+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation')) 
		
	gen 		double		AETR_CFT`taxrate'=100*((`p'-`realint')/(`realint'+`delta')-econrent_cft`taxrate')/(`p'/(`realint'+`delta'))	
	}
			
	keep		AETR_*

	duplicates  drop

	gen 		period=0
	reshape 	long AETR_CFT, i(period) 
	drop		period

	rename 		_j		statutory_tax_rate
	la			var		statutory_tax_rate 		"statutory tax rate in %"
	la			var		AETR_CFT		  		"AETR of a cash flow tax system in (%)"
	}		
}																					// closes cft


***ACE
if "`system'"=="ace" {
	if "`refund'"=="yes" {

	**We assume that refundable ACE is a QRTC. Hence considered GloBE income.
	
	if "`deprtype'" == "db" {

	*The taxbase for covered tax involves calculting accounting profit excluding the ACE credit (since ACE credit is considered covered income for GloBE purposes).
	gen 		double profit_ace_tpt=0
	replace 	profit_ace_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation')   if t==1
	replace		profit_ace_tpt=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t  + min(0,profit_ace_tpt[_n-1])  if t>1

	forval 		taxrate=0(1)40 {
	gen double 	covtax_ace`taxrate'=0
	replace 	covtax_ace`taxrate'=(`taxrate'/100)*max(0,profit_ace_tpt)-min((`taxrate'/100)*max(0,profit_ace_tpt),NQRTC) if  `holiday'==0
	replace 	covtax_ace`taxrate'=(`taxrate'/100)*max(0,profit_ace_tpt)-min((`taxrate'/100)*max(0,profit_ace_tpt),NQRTC) if  `holiday'>0 & t>`holiday'
	}
	
	*GloBE income (since refundable ACE is considered similar to qualified refundable tax credit). If financed with equity, the covered income is production minus depreciation minus allowance.  If debt financed, the covered income is is production minus depreciaiton minus interest payment plus allowance.
	forval 		taxrate=0(1)40 { 
	gen 		double cov_profit_ace`taxrate'=0													//This is the tax base from which SBIE is deducted
	replace		cov_profit_ace`taxrate'=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation') - `debt'*`i' + (`taxrate'/100)*`i'*(1-`depreciation') + QRTC  if t==1
	replace		cov_profit_ace`taxrate'=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t - `debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + (`taxrate'/100)*`i'*(1-`depreciation')^t + QRTC + min(0,cov_profit_ace`taxrate'[_n-1])  if t>1
	
	
	gen	double	tpr_ace`taxrate'=max(0,`minrate'-(covtax_ace`taxrate')/cov_profit_ace`taxrate')		if cov_profit_ace`taxrate'>0

	gen			double exprofit_ace`taxrate'=max(0,cov_profit_ace`taxrate'-SBIE)		  // Excess profit is GloBe income minus susbtance based income exclusion	
													
	}
	}
	
	
	if "`deprtype'" == "sl" {
*The taxbase for covered tax involves calculting accounting profit excluding the ACE credit (since ACE credit is considered covered income for GloBE purposes).
	gen 		double profit_ace_tpt=0
	replace 	profit_ace_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')  if t==1
	replace		profit_ace_tpt=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')  + min(0,profit_ace_tpt[_n-1])   if t>1 
	
	forval 		taxrate=0(1)40 {
	gen double 	covtax_ace`taxrate'=0
	replace 	covtax_ace`taxrate'=(`taxrate'/100)*max(profit_ace_tpt,0)-min((`taxrate'/100)*max(profit_ace_tpt,0),NQRTC) if `holiday'==0
	replace 	covtax_ace`taxrate'=(`taxrate'/100)*max(profit_ace_tpt,0)-min((`taxrate'/100)*max(profit_ace_tpt,0),NQRTC) if t>`holiday' & `holiday'>0
	}
*GloBE income (since refundable ACE is considered similar to qualified refundable tax credit). If financed with equity, the covered income is production minus depreciation minus allowance.  If debt financed, the covered income is is production minus depreciaiton minus interest payment plus allowance.
	forval 		taxrate=0(1)40 { 
	gen 		double cov_profit_ace`taxrate'=0													//This is the tax base from which SBIE is deducted
	replace		cov_profit_ace`taxrate'=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation') - `debt'*`i' + (`taxrate'/100)*`i'*max((1-`depreciation'),0) + QRTC  if t==1
	replace		cov_profit_ace`taxrate'=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') - `debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + (`taxrate'/100)*`i'*max((1-t*`depreciation'),0) + QRTC + min(0,cov_profit_ace`taxrate'[_n-1])   if t>1
	
	gen	double	tpr_ace`taxrate'=max(0,`minrate'-(covtax_ace`taxrate')/cov_profit_ace`taxrate')		if cov_profit_ace`taxrate'>0
	 // Note that the difference between the nominator and denominator is that the denomintor includes the tax credit as an income
	gen			double exprofit_ace`taxrate'=max(0,cov_profit_ace`taxrate'-SBIE)		  // Excess profit
	}
	}
	
	forval 		taxrate=0(1)40 { 
	gen 		double tpt_ace`taxrate'=tpr_ace`taxrate'*exprofit_ace`taxrate'/(1+`rho')^t			// top-up tax (discounted value) 
	egen 		double total_tpt_ace`taxrate'=total(tpt_ace`taxrate')
*	gen 		double AETR_tpt_ACE`taxrate'=100*total_tpt_ace`taxrate'/(`p'/(`realint'+`delta'))
	}

	merge 1:1 t using `ace_pregoble' 									// This merges the taxes paid before the top-up

	forval 		taxrate=0(1)40 { 
	gen 		double		total_ace`taxrate'=total_tpt_ace`taxrate'+Tax_ace_NPV`taxrate'			// NPV of domestic tax + NPV of top-up tax
	
	gen 		double 		econrent_ace`taxrate'=0
		
	replace 				econrent_ace`taxrate'=`gamma'*(revenue_NPV-1-total_ace`taxrate')+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation')) 
		
	gen 		double		AETR_ACE`taxrate'=100*((`p'-`realint')/(`realint'+`delta')-econrent_ace`taxrate')/(`p'/(`realint'+`delta'))	
	}
	
	keep		AETR_*

	duplicates  drop

	gen 		period=0
	reshape 	long AETR_ACE   , i(period) 
	drop		period

	rename 		_j		statutory_tax_rate
	la			var		statutory_tax_rate 		"Statutory tax rate in %"
	la			var		AETR_ACE				"AETR of an ACE system in (%)"
	}																				// closes refundable ace
	
if "`refund'"=="no" {
	
*ACE
	**We assume that refundable ACE is a NQRTC. Hence considered a reduction in covered tax.
	*************************

	
	if "`deprtype'" == "db" {

	*The taxbase for covered tax involves calculting accounting profit, and deducting the ACE credit (since non-refundable ACE is considered a reduction n covered tax GloBE purposes).
	gen 		double profit_ace_tpt=0
	replace 	profit_ace_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation') -`i'*(1-`depreciation')  if t==1
	replace		profit_ace_tpt=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t-`i'*(1-`depreciation')^t  + min(0,profit_ace_tpt[_n-1])  if t>1

	*GloBE income: It is accounting profit. If financed with equity, the covered tax base is production minus depreciation. If debt financed, the covered tax base is production minus depreciaiton minus debt payment.
	
	forval 		taxrate=0(1)40 { 
	gen 		double cov_profit_ace`taxrate'=0													//This is the tax base from which SBIE is deducted
	replace		cov_profit_ace`taxrate'=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation') - `debt'*`i' + QRTC  if t==1
	replace		cov_profit_ace`taxrate'=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t - `debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + QRTC + min(0,cov_profit_ace`taxrate'[_n-1])  if t>1
	
	gen double 	covtax_ace`taxrate'=0
	replace 	covtax_ace`taxrate'=(`taxrate'/100)*max(0,profit_ace_tpt)-min((`taxrate'/100)*max(0,profit_ace_tpt),NQRTC) if t>`holiday'
	gen	double	tpr_ace`taxrate'=max(0,`minrate'-(covtax_ace`taxrate')/cov_profit_ace`taxrate')		if cov_profit_ace`taxrate'>0
	 // Note that the difference between the nominator and denominator is that the denomintor includes the tax credit as an income
	gen			double exprofit_ace`taxrate'=max(0,cov_profit_ace`taxrate'-SBIE)		  // Excess profit is GloBe income minus susbtance based income exclusion	
												
	}
	}
		
	if "`deprtype'" == "sl" {

	gen 		double profit_ace_tpt=0
	replace 	profit_ace_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')- `i'*max(1-`depreciation',0)   if t==1
	replace		profit_ace_tpt=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')- `i'*max(1-t*`depreciation',0) + min(0,profit_ace_tpt[_n-1])   if t>1 

	*GloBE income: It is accounting profit. If financed with equity, the covered tax base is production minus depreciation. If debt financed, the covered tax base is production minus depreciaiton minus debt payment.
	forval 		taxrate=0(1)40 { 
	gen 		double cov_profit_ace`taxrate'=0													//This is the tax base from which SBIE is deducted
	replace		cov_profit_ace`taxrate'=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation') - `debt'*`i'  + QRTC  if t==1
	replace		cov_profit_ace`taxrate'=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') - `debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + QRTC + min(0,cov_profit_ace`taxrate'[_n-1])   if t>1
	
	
	gen double 	covtax_ace`taxrate'=0
	replace 	covtax_ace`taxrate'=(`taxrate'/100)*max(profit_ace_tpt,0)-min((`taxrate'/100)*max(profit_ace_tpt,0),NQRTC) if `holiday'==0
	replace 	covtax_ace`taxrate'=(`taxrate'/100)*max(profit_ace_tpt,0)-min((`taxrate'/100)*max(profit_ace_tpt,0),NQRTC) if t>`holiday' & `holiday'>0
	gen	double	tpr_ace`taxrate'=max(0,`minrate'-(covtax_ace`taxrate')/cov_profit_ace`taxrate')		if cov_profit_ace`taxrate'>0
	 // Note that the difference between the nominator and denominator is that the denomintor includes the tax credit as an income
	gen			double exprofit_ace`taxrate'=max(0,cov_profit_ace`taxrate'-SBIE)		  // Excess profit
	}
	}
	
	forval 		taxrate=0(1)40 { 
	gen 		double tpt_ace`taxrate'=tpr_ace`taxrate'*exprofit_ace`taxrate'/(1+`rho')^t			// top-up tax (discounted value) 
	egen 		double total_tpt_ace`taxrate'=total(tpt_ace`taxrate')
	*gen 		double AETR_tpt_ACE`taxrate'=100*total_tpt_ace`taxrate'/(`p'/(`realint'+`delta'))
	}

	merge 1:1 t using `ace_pregoble' 									// This merges the taxes paid before the top-up

	forval 		taxrate=0(1)40 { 
	gen 		double		total_ace`taxrate'=total_tpt_ace`taxrate'+Tax_ace_NPV`taxrate'   // NPV of domestic tax + NPV of top-up tax
	
	gen 		double 		econrent_ace`taxrate'=0
		
	replace 				econrent_ace`taxrate'=`gamma'*(revenue_NPV-1-total_ace`taxrate')+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation')) 
		
	gen 		double		AETR_ACE`taxrate'=100*((`p'-`realint')/(`realint'+`delta')-econrent_ace`taxrate')/(`p'/(`realint'+`delta'))	
	}
	
	keep		AETR_*

	duplicates  drop

	gen 		period=0
	reshape 	long AETR_ACE   , i(period) 
	drop		period

	rename 		_j		statutory_tax_rate
	la			var		statutory_tax_rate 		"tax rate in %"
	la			var		AETR_ACE				"AETR of tan ACE system in (%)"
}																						// closes norefund ace																				
	
}																					// closes ace	

	keep 		if statutory_tax_rate<=40
	keep 		statutory_tax_rate AETR*
	format 		AETR* %9.02f
	tempfile	aetr
	save		`aetr', replace
}																					// closes the minimum tax==yes	routine			


							
****************************************************************************************************************
*****************************************Marginal Effective Tax Rate********************************************
****************************************************************************************************************

use		`generalparamter',clear														// use general parameters defined at the beginning of the ado file

if "`minimumtax'"=="no" {

if "`refund'"=="yes" {


***Standard CIT
if "`system'"=="cit" {

*Set initial values
gen		double coc_cit=.														// the cost of capital of a CIT under GloBE
forval 	taxrate=0(1)40 {
local 	p = (1/((1+`inflation')*(1-(`taxrate'/100)*(((1-`delta')*(1+`inflation'))/(1+`rho'))^`holiday')))*((`rho'-`inflation'+ `delta'*(1+`inflation'))*(1-(`taxrate'/100)*`npvdep'-((`gamma'-1)/`gamma')*`newequity')-`debt'*(`rho'-`i')-`debt'*(`taxrate'/100)*`i'*(((1-`delta')*(1+`inflation'))/(1+`rho'))^`holiday'-(`qrtc'+`nqrtc'/2)*(`rho'-`inflation'+ `delta'*(1+`inflation'))*(1-`delta')/(`rho'+`delta'))-`delta'   // initial guess for coc 
													  
local 	tolerance = 0.0001  													// how close to zero we need to get econnomic rent
local 	max_iter = 1000 															// maximum number of iterations
local 	iter = 0  																// iteration counter

* Begin the iterative process
while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p

	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + `rho') ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	

if "`deprtype'"=="db" {
	gen 		 double profit_cit=0
	replace		 profit_cit=-`depreciation'  if t==0
	replace		 profit_cit=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1)   if t>=1
	la var 		 profit_cit  "profit under a non-refundable standard CIT with declining balance depreiciation method."
}

if "`deprtype'"=="sl" {
	
	gen 		 double profit_cit=0
	replace		 profit_cit=-`depreciation'  if t==0
	replace		 profit_cit=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation') -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1)   if t>=1
	la var 		 profit_cit  "profit under a non-refundable standard CIT with declining balance depreiciation method."
}
	gen  		double		Tax_cit=0
	replace					Tax_cit =(`taxrate'/100) * profit_cit -QRTC-min(max(`taxrate'*profit_cit/100,0),NQRTC)	if `holiday'==0		
	// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))
	replace					Tax_cit=-QRTC	if t<=`holiday' & `holiday'>0		// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))
	replace					Tax_cit =(`taxrate'/100)*profit_cit -QRTC-min(max(`taxrate'*profit_cit/100,0),NQRTC)	if t>`holiday' & `holiday'>0		
  
	gen  		double 		Tax_cit_time = Tax_cit/((1 + `rho') ^ t)					// The discounted value of each period's tax liability
    egen 		double 		Tax_cit_NPV = total(Tax_cit_time)								// NPV of the the sum of taxes paid
												
	gen 		double 		econrent_cit=`gamma'*(revenue_NPV-1-Tax_cit_NPV)+  `newequity'*(`gamma'-1) + `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
     
    if abs(econrent_cit) < `tolerance' {
        display "Converged: p`taxrate' = " `p'
        break
    }

    * Adjust p based on whether the sum is positive or negative (i.e., if the economic rent has not converged with in the tolernace margin)
   if abs(econrent_cit)>=0.1 {
    local p = `p' - econrent_cit/10	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
   }
   
   if abs(econrent_cit)<0.1  {
    local p = `p' - econrent_cit/5	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
   }
   
  

    * Increment the iteration counter
    local iter = `iter' + 1

    * Drop variables for the next iteration (otherwise, the iteration will stop since these variables are already defined)
    drop revenue revenue_time revenue_NPV profit_cit Tax_cit Tax_cit_time Tax_cit_NP econrent_cit			
	}

* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}
	local n=`taxrate'+1
    replace coc_cit = `p'    in `n'
}


gen double METR_CIT= 100*(coc_cit-`realint')/ abs(coc_cit)
replace		coc_cit=100*coc_cit

keep 		if t<=40
rename	 	t statutory_tax_rate
keep		coc* statutory_tax_rate METR*

format		METR* %9.02f
}



***Cashflow tax


if "`system'"=="cft" {
*Set initial values
gen		double coc_cft=.																	// the cost of capital of a non-refundable CIT with declining balance depreciation

forval 	taxrate=0(1)40 {
local 	p = (1/((1+`inflation')*(1-(`taxrate'/100)*(((1-`delta')*(1+`inflation'))/(1+`rho'))^`holiday')))*((`rho'-`inflation'+ `delta'*(1+`inflation'))*(1-(`taxrate'/100)*`cftdpv'-((`gamma'-1)/`gamma')*`newequity')-`debt'*(`rho'-`i')-(`qrtc'+`nqrtc'/2)*(`rho'-`inflation'+ `delta'*(1+`inflation'))*(1-`delta')/(`rho'+`delta'))-`delta'   // initial guess for coc 
local 	tolerance = 0.0001 							// how close to zero we need econnomic rent to get 
local 	max_iter = 1000 								// maximum number of iterations
local 	iter = 0  										// iteration counter

* Begin the iterative process
while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
/*=========================
First, the pre-topup tax
=========================*/	
if "`deprtype'"=="db" | "`deprtype'"=="sl" {


	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + `rho') ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	

	gen 		double profit_cft = 0
	replace 	profit_cft = - 1 	if t == 0					// -1 is to account for the loss carried forward from period 0
    replace 	profit_cft = (`p' + `delta') * ((1 + `inflation') ^ t) * ((1 - `delta') ^ (t - 1))  if t >=1

}    

	gen  		double		Tax_cft=0
	replace					Tax_cft =(`taxrate'/100) * profit_cft -QRTC-min(max(`taxrate'*profit_cft/100,0),NQRTC)	if `holiday'==0		
	// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))
	
	replace					Tax_cft=-QRTC	if t<=`holiday' & `holiday'>0		
	replace					Tax_cft =(`taxrate'/100) * profit_cft -QRTC-min(max(`taxrate'*profit_cft/100,0),NQRTC)	if t>`holiday' & `holiday'>0		

    gen  		double		Tax_cft_time= Tax_cft/((1 + `rho') ^ t)										// The discounted value of each peruiod's tax liability
    egen 		double		Tax_cft_NPV= total(Tax_cft_time)											// NPV of the the sum of taxes paid
  									
	gen 		double 	econrent_cft=`gamma'*(revenue_NPV-1-Tax_cft_NPV)+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
     

/*=========================
Third, define economic rent and check if economic rent is close enough to zero 
=========================*/	
    if abs(econrent_cft) < `tolerance' {
        display "Converged: p`taxrate' = " `p'
        break
    }

    * Adjust p based on whether the sum is positive or negative
   if abs(econrent_cft)>=0.1 {
    local p = `p' - econrent_cft/10	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
   }
   
   if abs(econrent_cft)<0.1  {
    local p = `p' - econrent_cft/5	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
   }

    * Increment the iteration counter
    local iter = `iter' + 1

    * Drop variables for the next iteration
    drop revenue revenue_time revenue_NPV profit_cft Tax_cft Tax_cft_time Tax_cft_NPV econrent_cft			// to allow for the next iteration
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}
	local n=`taxrate'+1
	*replace taxrate_s = `taxrate' in `n'
    replace coc_cft= `p'    in `n'
}

gen double METR_CFT= 100*(coc_cft-`realint')/ coc_cft

replace		coc_cft=100*coc_cft

keep 		if t<=40
rename	 	t statutory_tax_rate
keep		coc* statutory_tax_rate METR*

format		METR* %9.02f

}

		
*** ACE


if "`system'"=="ace" {

*Set initial values
gen		double coc_ace=.																	// the cost of capital of a non-refundable CIT with declining balance depreciation

forval 	taxrate=0(1)40 {
local 	p = (1/((1+`inflation')*(1-(`taxrate'/100)*(((1-`delta')*(1+`inflation'))/(1+`rho'))^`holiday')))*((`rho'-`inflation'+ `delta'*(1+`inflation'))*(1-(`taxrate'/100)*(`npvdep'+`acepdv')-((`gamma'-1)/`gamma')*`newequity')-(`qrtc'+`nqrtc'/2)*(`rho'-`inflation'+ `delta'*(1+`inflation'))*(1-`delta')/(`rho'+`delta'))-`delta'
local 	tolerance = 0.0001  										// how close to zero we need to get econnomic rent
local 	max_iter = 1000 											// maximum number of iterations
local 	iter = 0  													// iteration counter

* Begin the iterative process
while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
/*=========================
First, the pre-topup tax (we use the same for debt and equity finance becasue they are equivalent)
=========================*/

	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + `rho') ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)
	
if "`deprtype'"=="db" {	
	gen 		double profit_ace=0
	replace		profit_ace=-`depreciation'        								if t==0    
	// i*(1-phi) is the allowance for corporate equity
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-`i'*(1-`depreciation')^t   if t>=1
	la 			var profit_ace "profit under non-refundable ACE and declining balance depreciation"
}

if "`deprtype'"=="sl" {
	gen 		double profit_ace=0
	replace		profit_ace=-`depreciation'         if t==0    
	// i*(1-phi) is the allowance for corporate equity
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-`i'*max(1-t*`depreciation',0)   if t>=1
	la 			var profit_ace "profit under non-refundable ACE and declining balance depreciation"
}
	gen  		double		Tax_ace=0
	replace					Tax_ace =(`taxrate'/100) * profit_ace -QRTC-min(max(`taxrate'*profit_ace/100,0),NQRTC)	if `holiday'==0		
		// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))
	replace					Tax_ace=-QRTC	if t<=`holiday' & `holiday'>0		
	replace					Tax_ace =(`taxrate'/100) * profit_ace -QRTC-min(max(`taxrate'*profit_ace/100,0),NQRTC)	if t>`holiday' & `holiday'>0	

    gen			double 		Tax_ace_time= Tax_ace/((1 + `i') ^ t)								// The discounted value of each period's tax liability
    egen 		double 		Tax_ace_NPV= total(Tax_ace_time)									// NPV of the the sum of taxes paid

								
	gen 		double 	econrent_ace=`gamma'*(revenue_NPV-1-Tax_ace_NPV)+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
     
/*=========================
Third, define economic rent and check if economic rent is close enough to zero 
=========================*/

    if abs(econrent_ace) < `tolerance' {
        display "Converged: p`taxrate' = " `p'
        break
    }

    * Adjust p based on whether the sum is positive or negative
   if abs(econrent_ace)>=0.1 {
    local p = `p' - econrent_ace/10	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
   }
   
   if abs(econrent_ace)<0.1  {
    local p = `p' - econrent_ace/5	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
   }

    * Increment the iteration counter
    local iter = `iter' + 1

    * Drop variables for the next iteration
    drop revenue revenue_time revenue_NPV  profit_ace Tax_ace Tax_ace_time Tax_ace_NPV econrent_ace			// to allow for the next iteration
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}
	local n=`taxrate'+1
    replace		coc_ace= `p'    in `n'
}


gen double METR_ACE= 100*(coc_ace-`realint')/ coc_ace
replace		coc_ace=100*coc_ace
keep 		if t<=40
rename	 	t statutory_tax_rate
keep		coc* statutory_tax_rate METR*

format		METR* %9.02f
}															

}																				// closes the refun==yes routine.

if "`refund'"=="no" {

***Standard CIT
if "`system'"=="cit" {

*Set initial values
gen		double coc_cit=.						// the cost of capital of a CIT under GloBE
forval 	taxrate=0(1)40 {
local 	p =`realint'
local 	tolerance = 0.0001  					// how close to zero we need to get econnomic rent
local 	max_iter = 1000 						// maximum number of iterations
local 	iter = 0  								// iteration counter

* Begin the iterative process
while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + `rho') ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	

if "`deprtype'"=="db" {

		
	gen 		double profit_cit=0
	replace		profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt'*`i'    if t==1			// period 1 profit accounting for the loss carryforward from period 0
	replace		profit_cit=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit[_n-1])  if t>1
	la var 		profit_cit  "profit under a non-refundable standard CIT."
}

if "`deprtype'"=="sl" {
	
	gen 		double profit_cit=0
	replace		profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt'*`i'    if t==1			// period 1 profit accounting for the loss carryforward from period 0
	replace		profit_cit=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation') -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit[_n-1])  if t>1
	la var		profit_cit  "profit under a non-refundable standard CIT."
}
   	gen  		double		Tax_cit=0
	replace					Tax_cit =max(`taxrate' * profit_cit/100,0) -QRTC-min(max(`taxrate'*profit_cit/100,0),NQRTC)	if `holiday'==0		
	// period by period tax liability (if taxable income is negative, then tax is zero(i.e., no-refund))
	replace					Tax_cit=-QRTC	if t<=`holiday' & `holiday'>0		
	replace					Tax_cit =max(`taxrate' * profit_cit/100,0) -QRTC-min(max(`taxrate'*profit_cit/100,0),NQRTC)	if t>`holiday' & `holiday'>0
	
    gen  		double 		Tax_cit_time = Tax_cit/((1 + `rho') ^ t)					// The discounted value of each period's tax liability
    egen 		double 		Tax_cit_NPV = total(Tax_cit_time)								// NPV of the the sum of taxes paid
												
							
	gen 		double 	econrent_cit=`gamma'*(revenue_NPV-1-Tax_cit_NPV)+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
     
*====   
    if abs(econrent_cit) < `tolerance' {
        display "Converged: p`taxrate' = " `p'
        break
    }

    * Adjust p based on whether the sum is positive or negative (i.e., if the economic rent has not converged with in the tolernace margin)
	if abs(econrent_cit)>=0.1 {
		local p = `p' - econrent_cit/10	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
	}
   
   if abs(econrent_cit)<0.1  {
    local p = `p' - econrent_cit/5	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
   }
    * Increment the iteration counter
    local iter = `iter' + 1

    * Drop variables for the next iteration (otherwise, the iteration will stop since these variables are already defined)
    drop revenue revenue_time revenue_NPV profit_cit Tax_cit Tax_cit_time Tax_cit_NP econrent_cit			
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}
	local n=`taxrate'+1
    replace coc_cit = `p'    in `n'
}

gen double METR_CIT= 100*(coc_cit-`realint')/ coc_cit
replace		coc_cit=100*coc_cit

keep 		if t<=40
rename	 	t statutory_tax_rate
keep		coc* statutory_tax_rate METR*

format		METR* %9.02f
}


***Cashflow tax

if "`system'"=="cft" {

*Set initial values
gen		double coc_cft=.																	// the cost of capital of a non-refundable CIT with declining balance depreciation

forval 	taxrate=0(1)40 {
local 	p = `realint'
local 	tolerance = 0.0001 							// how close to zero we need econnomic rent to get 
local 	max_iter = 1000 							// maximum number of iterations
local 	iter = 0  									// iteration counter

* Begin the iterative process
while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
/*=========================
First, the pre-topup tax
=========================*/	
if "`deprtype'"=="db" | "`deprtype'"=="sl" {

	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + `rho') ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	

	gen 		double profit_cft = 0
    replace 	profit_cft = (`p' + `delta') * (1 + `inflation') - 1 if t == 1					// -1 is to account for the loss carried forward from period 0
    replace 	profit_cft = (`p' + `delta') * ((1 + `inflation') ^ t) * ((1 - `delta') ^ (t - 1)) + min(0, profit_cft[_n-1]) if t > 1

}    

   	gen  		double		Tax_cft=0
	replace					Tax_cft=max(`taxrate' * profit_cft/100,0) -QRTC-min(max(`taxrate'*profit_cft/100,0),NQRTC)	if `holiday'==0		
	replace					Tax_cft=-QRTC	if t<=`holiday' & `holiday'>0		
	replace					Tax_cft=max(`taxrate' * profit_cft/100,0) -QRTC-min(max(`taxrate'*profit_cft/100,0),NQRTC)	if t>`holiday' & `holiday'>0		
	// period by period tax liability (if taxable income is negative, then tax is zero(i.e., no-refund))
   
	gen  		double		Tax_cft_time= Tax_cft/((1 + `rho') ^ t)										// The discounted value of each peruiod's tax liability
    egen 		double 		Tax_cft_NPV= total(Tax_cft_time)											// NPV of the the sum of taxes paid
							
	gen 		double 	econrent_cft=`gamma'*(revenue_NPV-1-Tax_cft_NPV)+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
     

/*=========================
Third, define economic rent and check if economic rent is close enough to zero 
=========================*/	
    if abs(econrent_cft) < `tolerance' {
        display "Converged: p`taxrate' = " `p'
        break
    }

    * Adjust p based on whether the sum is positive or negative
	if abs(econrent_cft)>=0.1 {
		local p = `p' - econrent_cit/10	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
		}
   
   if abs(econrent_cft)<0.1  {
		local p = `p' - econrent_cft/5	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
	}
    * Increment the iteration counter
    local iter = `iter' + 1

    * Drop variables for the next iteration
    drop revenue revenue_time revenue_NPV profit_cft Tax_cft Tax_cft_time Tax_cft_NPV econrent_cft			// to allow for the next iteration
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}
	local n=`taxrate'+1
	*replace taxrate_s = `taxrate' in `n'
    replace coc_cft= `p'    in `n'
}

gen double METR_CFT= 100*(coc_cft-`realint')/ coc_cft

replace		coc_cft=100*coc_cft

keep 		if t<=40
rename	 	t statutory_tax_rate
keep		coc* statutory_tax_rate METR*

format		METR* %9.02f

}



***Allowance for equity

if "`system'"=="ace" {

*Set initial values
gen		double coc_ace=.																	// the cost of capital of a non-refundable CIT with declining balance depreciation

forval 	taxrate=0(1)40 {
local 	p =`realint'
local 	tolerance = 0.0001  					// how close to zero we need to get econnomic rent
local 	max_iter = 1000 						// maximum number of iterations
local 	iter = 0  								// iteration counter

* Begin the iterative process
while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
/*=========================
First, the pre-topup tax (we use the same for debt and equity finance becasue they are equivalent)
=========================*/
	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + `rho') ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	
	
if "`deprtype'"=="db" {	
	gen 		double profit_ace=0
	replace		profit_ace=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation')-`i'*(1-`depreciation')         if t==1    
	// i*(1-phi) is the allowance for corporate equity
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-`i'*(1-`depreciation')^t + min(0,profit_ace[_n-1])  if t>1
	la 			var profit_ace "profit under non-refundable ACE and declining balance depreciation"
}

if "`deprtype'"=="sl" {
	gen 		double profit_ace=0
	replace		profit_ace=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`i'*max(1-`depreciation',0)         if t==1    
	// i*(1-phi) is the allowance for corporate equity
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-`i'*max(1-t*`depreciation',0) + min(0,profit_ace[_n-1])  if t>1
	la 			var profit_ace "profit under non-refundable ACE and declining balance depreciation"
}

   	gen  	double		Tax_ace=0
	replace				Tax_ace =max(`taxrate' * profit_ace/100,0) -QRTC-min(max(`taxrate'*profit_ace/100,0),NQRTC)	if `holiday'==0		
	// period by period tax liability (if taxable income is negative, then tax is zero(i.e., no-refund))
	replace				Tax_ace=-QRTC	if t<=`holiday' & `holiday'>0		
	replace				Tax_ace =max(`taxrate' * profit_ace/100,0) -QRTC-min(max(`taxrate'*profit_ace/100,0),NQRTC)	if t>`holiday' & `holiday'>0		
	
    gen  	double		Tax_ace_time= Tax_ace/((1 + `rho') ^ t)								// The discounted value of each period's tax liability
    egen 	double		Tax_ace_NPV= total(Tax_ace_time)									// NPV of the the sum of taxes paid

							
	gen 		double 	econrent_ace=`gamma'*(revenue_NPV-1-Tax_ace_NPV)+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
     
/*=========================
Third, define economic rent and check if economic rent is close enough to zero 
=========================*/

    if abs(econrent_ace) < `tolerance' {
        display "Converged: p`taxrate' = " `p'
        break
    }

    * Adjust p based on whether the sum is positive or negative
	if abs(econrent_ace)>=0.1 {
		local p = `p' - econrent_ace/10	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
	}
   
   if abs(econrent_ace)<0.1  {
		local p = `p' - econrent_ace/5	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
	}

    * Increment the iteration counter
    local iter = `iter' + 1

    * Drop variables for the next iteration
    drop revenue revenue_time revenue_NPV profit_ace Tax_ace Tax_ace_time Tax_ace_NPV econrent_ace			// to allow for the next iteration
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}
	local n=`taxrate'+1
    replace		coc_ace= `p'    in `n'
}


gen double METR_ACE= 100*(coc_ace-`realint')/ coc_ace
replace		coc_ace=100*coc_ace
keep 		if t<=40
rename	 	t statutory_tax_rate
keep		coc* statutory_tax_rate METR*

format		METR* %9.02f
}

}																				// closes the no-refund-no min tax part
}																				// closes the no minimum tax part


	
if "`minimumtax'"=="yes" {

if "`refund'"=="yes" {

***Standard CIT
if "`system'"=="cit" {

*Set initial values
gen		double coc_cit=.										// the cost of capital of a CIT under GloBE
forval 	taxrate=0(1)40 {

local 	p = `realint'

// initial guess for coc (3 percentange point above the real interest rate)

local 	tolerance = 0.0001  									// how close to zero we need to get econnomic rent
local 	max_iter = 1000 										// maximum number of iterations
local 	iter = 0  												// iteration counter

* Begin the iterative process
while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p

	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + `rho') ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	
	

if "`deprtype'"=="db" {
	
	gen 		double profit_cit=-`depreciation'														// taxable income in period 0 (becasue of refundability)
	replace		profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1)     if t>0			// taxable income in periods after period 0
	la var 		profit_cit  "profit under a refundable standard CIT."
    
	****
	gen 		double profit_cit_tpt=0																	// accounting profit before tax credit
	replace		profit_cit_tpt=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt'*`i'   if t==1
	replace		profit_cit_tpt=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit_tpt[_n-1])  if t>1
	
	** Globe income (covered taxable income) is standard profit plus the tax credit
	gen 		double cov_profit_cit=0
	replace		cov_profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt'*`i' + QRTC  if t==1
	replace		cov_profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,cov_profit_cit[_n-1]) + QRTC  if t>1
	la var 		cov_profit_cit  "covered tax of a standard CIT"
	
}


if "`deprtype'"=="sl" {
	
	gen 		double profit_cit=-`depreciation'														// taxable income in period 0 (becasue of refundability)
	replace		profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1)     if t>=1			
	// taxable income in periods after period 0
	la var 		profit_cit  "profit under a refundable standard CIT."
    	
	****
	gen 		double profit_cit_tpt=0																	// accounting profit before tax credit
	replace		profit_cit_tpt=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt'*`i'   if t==1
	replace		profit_cit_tpt=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit_tpt[_n-1])  if t>1
	
	** Globe income (covered taxable income) is standard profit plus the tax credit
	gen 		double cov_profit_cit=0
	replace		cov_profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt'*`i' + QRTC  if t==1
	replace		cov_profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')-`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1)  + min(0,cov_profit_cit[_n-1]) + QRTC  if t>1
	la var 		cov_profit_cit  "covered tax of a standard CIT"

}

	gen  	double		Tax_cit=`taxrate' * profit_cit/100 -QRTC-min(max(`taxrate' * profit_cit/100,0),NQRTC)	if `holiday'==0
	// period by period tax liability (if taxable income is negative, then tax is zero(i.e., refund))
	
	replace				Tax_cit=-QRTC	if t<=`holiday' & `holiday'>0		// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))
	replace				Tax_cit=`taxrate'*profit_cit/100 -QRTC-min(max(`taxrate'*profit_cit/100,0),NQRTC)	if t>`holiday' & `holiday'>0		
	
    gen  	double		Tax_cit_time = Tax_cit/((1 + `rho') ^ t)					// The discounted value of each period's tax liability
    egen 	double		Tax_cit_NPV = total(Tax_cit_time)								// NPV of the the sum of taxes paid


/*=========================
Second, the top-up tax
=========================*/	

	
	gen			double exprofit_cit=max(0,cov_profit_cit-SBIE)
	la var 		exprofit_cit  "Excess profit under standard CIT"
	
	gen 		covtax_cit=0										// covered tax
	replace 	covtax_cit=(`taxrate'/100)*max(0,profit_cit_tpt)-min((`taxrate'/100)*max(0,profit_cit_tpt),NQRTC) if `holiday'==0
	replace 	covtax_cit=(`taxrate'/100)*max(0,profit_cit_tpt)-min((`taxrate'/100)*max(0,profit_cit_tpt),NQRTC) if t>`holiday' & `holiday'>0
	gen	double	tpr_cit=max(0,`minrate'-(covtax_cit)/cov_profit_cit)	    if cov_profit_cit>0		//the top-up tax in each period for each value of the tax rate
	la var 		tpr_cit "Top up tax rate under stanadrd CIT"
	
	gen 		double tpt_cit=tpr_cit*exprofit_cit/((1+`rho')^t)												// top-up tax (discounted value) 
	egen 		double total_tpt_cit=total(tpt_cit)															// NPV of the top-up tax paid 

	gen 		double 	econrent_cit=`gamma'*(revenue_NPV-1-Tax_cit_NPV-total_tpt_cit)+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
     
	

/*=========================
Third, define economic rent and check if economic rent is close enough to zero 
=========================*/	
     
    if abs(econrent_cit) < `tolerance' {
        display "Converged: p`taxrate' = " `p'
        break
    }

    * Adjust p based on whether the sum is positive or negative (i.e., if the economic rent has not converged with in the tolernace margin)
	if abs(econrent_cit)>=0.1 {
		local p = `p' - econrent_cit/10	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
	}
   
   if abs(econrent_cit)<0.1  {
		local p = `p' - econrent_cit/5	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
   }

    * Increment the iteration counter
    local iter = `iter' + 1

    * Drop variables for the next iteration (otherwise, the iteration will stop since these variables are already defined)
    drop revenue revenue_time revenue_NPV profit_cit profit_cit_tpt Tax_cit Tax_cit_time Tax_cit_NPV cov_profit_cit covtax_cit exprofit_cit tpr_cit tpt_cit  total_tpt_cit econrent_cit			
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}
	local n=`taxrate'+1
    replace coc_cit = `p'    in `n'
}

gen double METR_CIT= 100*(coc_cit-`realint')/ coc_cit
replace coc_cit=100*coc_cit

keep 		if t<=40
rename	 	t statutory_tax_rate
keep		coc* statutory_tax_rate METR*

format		coc*    %9.02f

format		METR* %9.02f
}																							// closes cit


***Cashflow tax

if "`system'"=="cft" {

*Set initial values
gen		double coc_cft=.																	// the cost of capital of a non-refundable CIT with declining balance depreciation

forval 	taxrate=0(1)40 {
local 	p = `realint'									 	// initial guess for coc (3 percentange point above the real interest rate)
local 	tolerance = 0.0001 									// how close to zero we need econnomic rent to get 
local 	max_iter = 1000 									// maximum number of iterations
local 	iter = 0  // iteration counter

* Begin the iterative process
while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
/*=========================
First, the pre-topup tax
=========================*/	
	
	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + `rho') ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	
	
	
	gen  		double	profit_cft=0
	replace				profit_cft=-1	  															if t==0									// period 0 taxable income
	replace				profit_cft=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)				if t>=1
	la var 				profit_cft  "profit under a refundable cahsflow tax"
  
  
	gen  	double		Tax_cft=0
	replace				Tax_cft=`taxrate' * profit_cft/100 -QRTC-min(max(`taxrate'*profit_cft/100,0),NQRTC)	if `holiday'==0		
	// period by period tax liability (if taxable income is negative, then tax is zero(i.e., refund))
	replace				Tax_cft=-QRTC	if t<=`holiday' & `holiday'>0		
	replace				Tax_cft=`taxrate' * profit_cft/100 -QRTC-min(max(`taxrate'*profit_cft/100,0),NQRTC)	if t>`holiday' & `holiday'>0		
	
    gen  	double		Tax_cft_time= Tax_cft/((1 + `rho') ^ t)										// The discounted value of each peruiod's tax liability
    egen 	double		Tax_cft_NPV= total(Tax_cft_time)											// NPV of the the sum of taxes paid

/*=========================
Second, the top-up tax
=========================*/

if "`deprtype'"=="db" {	
	gen 		double profit_cft_tpt=0																// covered tax for GloBE purposes. Since immediate expensing is a timing issue, the covered tax and top-up rate look similar to the case of a standard CIT financed with equity
	replace		profit_cft_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation')    if t==1
	replace		profit_cft_tpt=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t  + min(0,profit_cft_tpt[_n-1])  if t>1
	la var 		profit_cft_tpt "the profit base for the covered tax"  
	
	
	gen 		double cov_profit_cft=0																// covered tax for GloBE purposes. Since immediate expensing is a timing issue, the covered tax and top-up rate look similar to the case of a standard CIT financed with equity
	replace		cov_profit_cft=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation')-`debt'*`i' + QRTC   if t==1
	replace		cov_profit_cft=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,cov_profit_cft[_n-1]) +QRTC if t>1
	la var 		cov_profit_cft  "covered tax of a cashflow tax under GlOBE"
}

if "`deprtype'"=="sl" {	
	gen 		double profit_cft_tpt=0																// covered tax for GloBE purposes. Since immediate expensing is a timing issue, the covered tax and top-up rate look similar to the case of a standard CIT financed with equity
	replace		profit_cft_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')    if t==1
	replace		profit_cft_tpt=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')  + min(0,profit_cft_tpt[_n-1])  if t>1
	la var 		profit_cft_tpt "the profit base for the covered tax"  
	
	
	gen 		double cov_profit_cft=0																// covered tax for GloBE purposes. Since immediate expensing is a timing issue, the covered tax and top-up rate look similar to the case of a standard CIT financed with equity
	replace		cov_profit_cft=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt'*`i' +QRTC   if t==1
	replace		cov_profit_cft=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,cov_profit_cft[_n-1]) +QRTC if t>1
	la var 		cov_profit_cft  "covered tax of a cashflow tax under GlOBE"
}
	
	gen			double exprofit_cft=max(0,cov_profit_cft-SBIE)
	la var 		exprofit_cft  "Excess profit under refundable cashfolow tax: GloBE"

	gen 		covtax_cft=0										// covered tax
	replace 	covtax_cft=(`taxrate'/100)*max(0,profit_cft_tpt)-min((`taxrate'/100)*max(0,profit_cft_tpt),NQRTC) if `holiday'==0
	replace 	covtax_cft=(`taxrate'/100)*max(0,profit_cft_tpt)-min((`taxrate'/100)*max(0,profit_cft_tpt),NQRTC) if t>`holiday' & `holiday'>0
	
	gen	double	tpr_cft=max(0,`minrate'-(covtax_cft)/cov_profit_cft)	    if cov_profit_cft>0													//the top-up tax in each period for each value of the tax rate
	la var 		tpr_cft "Top up tax rate under an R based cashflow tax"
	
	gen 		double tpt_cft=tpr_cft*exprofit_cft/((1+`rho')^t)			// top-up tax (discounted value) 
	egen 		double total_tpt_cft=total(tpt_cft)

	gen 		double 	econrent_cft=`gamma'*(revenue_NPV-1-Tax_cft_NPV-total_tpt_cft)+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
     

/*=========================
Third, define economic rent and check if economic rent is close enough to zero 
=========================*/	
    if abs(econrent_cft) < `tolerance' {
        display "Converged: p`taxrate' = " `p'
        break
    }

    * Adjust p based on whether the sum is positive or negative
	if abs(econrent_cft)>=0.1 {
		local p = `p' - econrent_cft/10	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
	}
   
   if abs(econrent_cft)<0.1  {
		local p = `p' - econrent_cft/5	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
	}
    * Increment the iteration counter
    local iter = `iter' + 1

    * Drop variables for the next iteration
    drop revenue revenue_time revenue_NPV profit_cft profit_cft_tpt Tax_cft Tax_cft_time Tax_cft_NPV cov_profit_cft covtax_cft exprofit_cft tpr_cft tpt_cft  total_tpt_cft econrent_cft			// to allow for the next iteration
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}
	local n=`taxrate'+1
	*replace taxrate_s = `taxrate' in `n'
    replace coc_cft= `p'    in `n'
}

gen double METR_CFT= 100*(coc_cft-`realint')/ coc_cft
replace 	coc_cft=100*coc_cft

keep 		if t<=40
rename	 	t statutory_tax_rate
keep		coc* statutory_tax_rate METR*

format		coc*    %9.02f

format		METR* %9.02f

}																					// closes cft



***Allowance for equity

if "`system'"=="ace" {

*Set initial values
gen		double coc_ace=.																	// the cost of capital of a non-refundable CIT with declining balance depreciation

forval 	taxrate=0(1)40 {
local 	p = `realint' 								 	  // initial guess for coc (3 percentange point above the real interest rate)
local 	tolerance = 0.0001 							 // how close to zero we need to get econnomic rent
local 	max_iter = 1000 								// maximum number of iterations
local 	iter = 0  // iteration counter

* Begin the iterative process
while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
/*=========================
First, the pre-topup tax (we use the same for debt and equity finance becasue they are equivalent)
=========================*/
	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + `rho') ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	

if "`deprtype'"=="db" {
	
	gen 		double profit_ace=-`depreciation'																					//taxable income in period 0
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-`i'*(1-`depreciation')^t   if t>0
	la 			var profit_ace "profit under a refundable ACE: declining balance depreciation"
	
	
	****The top-up part
	gen 		double profit_ace_tpt=0																	// accounting profit before tax credit (and before interest deduction)
	replace		profit_ace_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation')   if t==1
	replace		profit_ace_tpt=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t  + min(0,profit_ace_tpt[_n-1])  if t>1
	
	** Globe income (covered taxable income) is standard profit plus the tax credit
	gen 		double cov_profit_ace=0
	replace		cov_profit_ace=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation') - `debt'*`i' + (`taxrate'/100)*`i'*(1-`depreciation') + QRTC  if t==1
	replace		cov_profit_ace=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t - `debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + (`taxrate'/100)*`i'*(1-`depreciation')^t + QRTC + min(0,cov_profit_ace[_n-1])  if t>1
	la var 		cov_profit_ace  "covered tax of a refundable ACE: declining balance depreciation"
}	



if "`deprtype'"=="sl" {
	
	gen 		double profit_ace=-`depreciation'																					//taxable income in period 0
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-`i'*max(1-t*`depreciation',0)   if t>0
	la 			var profit_ace "profit under a refundable ACE: declining balance depreciation"
	
	
	****The top-up part
	gen 		double profit_ace_tpt=0																	// accounting profit before tax credit
	replace		profit_ace_tpt=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')   if t==1
	replace		profit_ace_tpt=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') + min(0,profit_ace_tpt[_n-1])  if t>1
	
	** Globe income (covered taxable income) is standard profit plus the tax credit
	gen 		double cov_profit_ace=0
	replace		cov_profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt'*`i' +  (`taxrate'/100)*`i'*(1-`depreciation') + QRTC  if t==1
	replace		cov_profit_ace=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + (`taxrate'/100)*`i'*max(1-t*`depreciation',0) + min(0,cov_profit_ace[_n-1]) + QRTC if t>1
	la var 		cov_profit_ace  "covered tax of a refundable ACE: declining balance depreciation"
}	

	gen  	double		Tax_ace=0
	replace				Tax_ace=`taxrate' * profit_ace/100 -QRTC-min(max(`taxrate'*profit_ace/100,0),NQRTC)	if `holiday'==0		
	// period by period tax liability (if taxable income is negative, then tax is zero(i.e., refund))
	replace				Tax_ace=-QRTC	if t<=`holiday' & `holiday'>0		
	replace				Tax_ace=`taxrate' * profit_ace/100 -QRTC-min(max(`taxrate'*profit_ace/100,0),NQRTC)	if t>`holiday' & `holiday'>0	
  
	gen		double 		Tax_ace_time= Tax_ace/((1 + `rho') ^ t)								// The discounted value of each period's tax liability
    egen 	double 		Tax_ace_NPV= total(Tax_ace_time)									// NPV of the the sum of taxes paid

/*=========================
Second, the top-up tax  (debt finance has difference implication compared to equity finance)
=========================*/

	gen			double exprofit_ace=max(0,cov_profit_ace-SBIE)
	la var 		exprofit_ace  "Excess profit under ACE: GloBE"

	
	gen 		covtax_ace=0										// covered tax
	replace 	covtax_ace=(`taxrate'/100)*max(0,profit_ace_tpt)-min((`taxrate'/100)*max(0,profit_ace_tpt),NQRTC) if `holiday'==0
	replace 	covtax_ace=(`taxrate'/100)*max(0,profit_ace_tpt)-min((`taxrate'/100)*max(0,profit_ace_tpt),NQRTC) if t>`holiday' & `holiday'>0
	
	gen	double	tpr_ace=max(0,`minrate'-(covtax_ace)/cov_profit_ace)	    if cov_profit_ace>0													
	la var 		tpr_ace "Top up tax rate under ACE"
	
	gen 		double tpt_ace=tpr_ace*exprofit_ace/((1+`rho')^t)			// the discounted value of the top-up tax paid each period 
	egen 		total_tpt_ace=total(tpt_ace)
	
	
	gen 		double 	econrent_ace=`gamma'*(revenue_NPV-1-Tax_ace_NPV-total_tpt_ace)+  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
     
	

/*=========================
Third, define economic rent and check if economic rent is close enough to zero 
=========================*/

    if abs(econrent_ace) < `tolerance' {
        display "Converged: p`taxrate' = " `p'
        break
    }

    * Adjust p based on whether the sum is positive or negative
	if abs(econrent_ace)>=0.1 {
		local p = `p' - econrent_ace/10	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
	}
   
   if abs(econrent_ace)<0.1  {
		local p = `p' - econrent_ace/5	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
	}
    * Increment the iteration counter
    local iter = `iter' + 1

    * Drop variables for the next iteration
    drop revenue revenue_time revenue_NPV profit_ace Tax_ace Tax_ace_time Tax_ace_NPV profit_ace_tpt cov_profit_ace covtax_ace exprofit_ace tpr_ace tpt_ace  total_tpt_ace econrent_ace			// to allow for the next iteration
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}
	local n=`taxrate'+1
    replace		coc_ace= `p'    in `n'
}


gen double METR_ACE= 100*(coc_ace-`realint')/ coc_ace
replace  coc_ace=100* coc_ace


keep 		if t<=40
rename	 	t statutory_tax_rate
keep		coc* statutory_tax_rate METR*

format		coc*    %9.02f

format		METR* %9.02f

}																				// closes ace

}																				// closes the refundbale minim-tax routine


if "`refund'"=="no" {

***Standard CIT

if "`system'"=="cit" {

*Set initial values
gen		double coc_cit=.								// the cost of capital of a refundable CIT under GloBE, with declining balance depreciation
forval 	taxrate=0(1)40 {
local 	p = `realint'										// initial guess for coc (3 percentange point above the real interest rate)
local 	tolerance = 0.0001  								// how close to zero we need to get econnomic rent
local 	max_iter = 1000 									// maximum number of iterations
local 	iter = 0  											// iteration counter

* Begin the iterative process
while `iter' < `max_iter' {

*Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
/*=========================
First, the pre-topup tax
=========================*/	

	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + `rho') ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	

if "`deprtype'"=="db" {	

	gen 		double profit_cit=0																	// accounting profit before tax credit
	replace		profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt'*`i'   if t==1
	replace		profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit[_n-1])  if t>1
	
****
	gen 		double profit_cit_tpt=0																	// accounting profit before tax credit
	replace		profit_cit_tpt=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt'*`i'   if t==1
	replace		profit_cit_tpt=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit_tpt[_n-1])  if t>1
	
	** Globe income (covered taxable income) is standard profit plus the tax credit
	gen 		double cov_profit_cit=0
	replace		cov_profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt'*`i' + QRTC  if t==1
	replace		cov_profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1)  + min(0,cov_profit_cit[_n-1]) + QRTC  if t>1
	la var 		cov_profit_cit  "covered tax of a standard CIT"
	
}

if "`deprtype'"=="sl" {	
	gen 		double profit_cit=0																	// accounting profit before tax credit
	replace		profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt'*`i'   if t==1
	replace		profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit[_n-1])  if t>1


****
	gen 		double profit_cit_tpt=0																	// accounting profit before tax credit
	replace		profit_cit_tpt=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt'*`i'   if t==1
	replace		profit_cit_tpt=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit_tpt[_n-1])  if t>1
	
	** Globe income (covered taxable income) is standard profit plus the tax credit
	gen 		double cov_profit_cit=0
	replace		cov_profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt'*`i' + QRTC  if t==1
	replace		cov_profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')-`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1)  + min(0,cov_profit_cit[_n-1]) + QRTC  if t>1
	la var 		cov_profit_cit  "covered tax of a standard CIT"
}

	gen  		double		Tax_cit=0
	replace					Tax_cit =(`taxrate'/100)*max(profit_cit,0) -QRTC-min((`taxrate'/100)*max(profit_cit,0),NQRTC)	if `holiday'==0		
	// period by period tax liability (if taxable income is negative, then tax is zero (i.e., no-refund))   
	replace					Tax_cit =-QRTC	if t<=`holiday' & `holiday'>0		
	replace					Tax_cit =(`taxrate'/100)*max(profit_cit,0) -QRTC-min((`taxrate'/100)*max(profit_cit,0),NQRTC)	if t>`holiday' & `holiday'>0		
	
    gen  		double 		Tax_cit_time = Tax_cit/((1 + `rho') ^ t)									// The discounted value of each period's tax liability
    egen 		double 		Tax_cit_NPV = total(Tax_cit_time)											// NPV of the the sum of taxes paid
    

/*=========================
Second, the top-up tax
=========================*/	

	gen			double exprofit_cit=max(0,cov_profit_cit-SBIE)
	la var 		exprofit_cit  "Excess profit under standard CIT"
	
	gen 		covtax_cit=0										// covered tax
	replace 	covtax_cit=(`taxrate'/100)*max(0,profit_cit_tpt)-min((`taxrate'/100)*max(0,profit_cit_tpt),NQRTC) if t>=`holiday'
	gen	double	tpr_cit=max(0,`minrate'-(covtax_cit)/cov_profit_cit)	    if cov_profit_cit>0													//the top-up tax in each period for each value of the tax rate
	la var 		tpr_cit "Top up tax rate under stanadrd CIT"
		
	gen 		double tpt_cit=tpr_cit*exprofit_cit/((1+`rho')^t)			// the discounted value of the top-up tax paid each period 
	egen 		total_tpt_cit=total(tpt_cit)
	
	
	gen 		double 	econrent_cit=`gamma'*(revenue_NPV-1-Tax_cit_NPV-total_tpt_cit) +  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
     

/*=========================
Third, define economic rent and check if economic rent is close enough to zero 
=========================*/	
    if abs(econrent_cit) < `tolerance' {
        display "Converged: p`taxrate' = " `p'
        break
    }

    * Adjust p based on whether the sum is positive or negative
	if abs(econrent_cit)>=0.1 {
		local p = `p' - econrent_cit/10	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
	}
   
	if abs(econrent_cit)<0.1  {
		local p = `p' - econrent_cit/5	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
	}

    * Increment the iteration counter
    local iter = `iter' + 1

    * Drop variables for the next iteration
    drop revenue revenue_time revenue_NPV profit_cit profit_cit_tpt Tax_cit Tax_cit_time Tax_cit_NPV cov_profit_cit covtax_cit exprofit_cit tpr_cit tpt_cit  total_tpt_cit econrent_cit			// to allow for the next iteration
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}
	local n=`taxrate'+1
    replace coc_cit = `p'    in `n'
}

gen double METR_CIT= 100*(coc_cit-`realint')/ coc_cit
replace		coc_cit=100*coc_cit  
keep 		if t<=40
rename	 	t statutory_tax_rate
keep		coc* statutory_tax_rate METR*

format		coc*    %9.02f

format		METR* %9.02f
}																					// closes cit


***Cash flow tax
if "`system'"=="cft" {

*Set initial values
gen		double coc_cft=.																	// the cost of capital of a non-refundable CIT with declining balance depreciation
forval 	taxrate=0(1)40 {
local 	p = `realint'									 	// initial guess for coc (3 percentange point above the real interest rate)
local 	tolerance = 0.0001 								// how close to zero we need econnomic rent to get 
local 	max_iter = 1000 									// maximum number of iterations
local 	iter = 0  											// iteration counter

* Begin the iterative process
while `iter' < `max_iter' {

	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + `rho') ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	
	

	gen 		double profit_cft=0
	replace		profit_cft=(`p'+`delta')*(1+`inflation')-1			if t==1
	replace		profit_cft=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)+min(0,profit_cft[_n-1])			if t>1
	la var 		profit_cft  "profit under a refundable cahsflow tax"

	gen  		double		Tax_cft=0
	replace					Tax_cft =(`taxrate'/100)*max(profit_cft,0) -QRTC-min((`taxrate'/100)*max(profit_cft,0),NQRTC)	if `holiday'==0	
	// period by period tax liability (if taxable income is negative, then tax is zero (i.e., no-refund))   
	replace					Tax_cft =-QRTC	if  t<=`holiday' & `holiday'>0		
	replace					Tax_cft =(`taxrate'/100)*max(profit_cft,0) -QRTC-min((`taxrate'/100)*max(profit_cft,0),NQRTC)	if t>`holiday' & `holiday'>0		
	
    gen  		double 		Tax_cft_time= Tax_cft/((1 + `rho')^t)										// The discounted value of each peruiod's tax liability
    egen 		double 		Tax_cft_NPV= total(Tax_cft_time)											// NPV of the the sum of taxes paid
  

/*=========================
Second, the top-up tax
=========================*/
	
if "`deprtype'"=="db" {
	
	gen 		double profit_cft_tpt=0																// covered tax for GloBE purposes. Since immediate expensing is a timing issue, the covered tax and top-up rate look similar to the case of a standard CIT financed with equity
	replace		profit_cft_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation')    if t==1
	replace		profit_cft_tpt=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t  + min(0,profit_cft_tpt[_n-1])  if t>1
	la var 		profit_cft_tpt "the profit base for the covered tax"  
	
		
	gen 		double cov_profit_cft=0																// covered tax for GloBE purposes. Since immediate expensing is a timing issue, the covered tax and top-up rate look similar to the case of a standard CIT financed with equity
	replace		cov_profit_cft=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt'*`i' + QRTC    if t==1
	replace		cov_profit_cft=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,cov_profit_cft[_n-1]) + QRTC if t>1
	la var 		cov_profit_cft  "covered tax of a cashflow tax under GlOBE"
}
	
	
if "`deprtype'"=="sl" {	
	
	gen 		double profit_cft_tpt=0																// covered tax for GloBE purposes. Since immediate expensing is a timing issue, the covered tax and top-up rate look similar to the case of a standard CIT financed with equity
	replace		profit_cft_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')    if t==1
	replace		profit_cft_tpt=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')  + min(0,profit_cft_tpt[_n-1])  if t>1
	la var 		profit_cft_tpt "the profit base for the covered tax"  
	
	
	gen 		double cov_profit_cft=0																// covered tax for GloBE purposes. Since immediate expensing is a timing issue, the covered tax and top-up rate look similar to the case of a standard CIT financed with equity
	replace		cov_profit_cft=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt'*`i' + QRTC   if t==1
	replace		cov_profit_cft=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,cov_profit_cft[_n-1]) + QRTC if t>1
	la var 		cov_profit_cft  "covered tax of a cashflow tax under GlOBE"

}

	
	gen			double exprofit_cft=max(0,cov_profit_cft-SBIE)
	la var 		exprofit_cft  "Excess profit under refundable cashfolow tax: GloBE"
	
	gen 		covtax_cft=0										// covered tax
	replace 	covtax_cft=(`taxrate'/100)*max(0,profit_cft_tpt)-min((`taxrate'/100)*max(0,profit_cft_tpt),NQRTC) if `holiday'==0
	replace 	covtax_cft=(`taxrate'/100)*max(0,profit_cft_tpt)-min((`taxrate'/100)*max(0,profit_cft_tpt),NQRTC) if t>`holiday' & `holiday'>0
	
	gen	double	tpr_cft=max(0,`minrate'-(covtax_cft)/cov_profit_cft)	    if cov_profit_cft>0													//the top-up tax in each period for each value of the tax rate
	la var 		tpr_cft "Top up tax rate under R based cashflow tax"
		
	gen 		double tpt_cft=tpr_cft*exprofit_cft/((1+`rho')^t)			// top-up tax (discounted value) 
	egen 		double total_tpt_cft=total(tpt_cft)

	gen 		double 	econrent_cft=`gamma'*(revenue_NPV-1-Tax_cft_NPV-total_tpt_cft) +  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
     

/*=========================
Third, define economic rent and check if economic rent is close enough to zero 
=========================*/

    if abs(econrent_cft) < `tolerance' {
        display "Converged: p`taxrate' = " `p'
        break
    }

    * Adjust p based on whether the sum is positive or negative
  if abs(econrent_cft)>=0.1 {
    local p = `p' - econrent_cft/10	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
   }
   
   if abs(econrent_cft)<0.1  {
    local p = `p' - econrent_cft/5	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
   }
    * Increment the iteration counter
    local iter = `iter' + 1

    * Drop variables for the next iteration
    drop revenue revenue_time revenue_NPV profit_cft profit_cft_tpt Tax_cft Tax_cft_time Tax_cft_NPV cov_profit_cft covtax_cft exprofit_cft tpr_cft tpt_cft  total_tpt_cft econrent_cft			// to allow for the next iteration
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}
	local n=`taxrate'+1
    replace coc_cft= `p'    in `n'
}

gen double METR_CFT= 100*(coc_cft-`realint')/ coc_cft
replace		coc_cft=100*coc_cft  
keep 		if t<=40
rename	 	t statutory_tax_rate
keep		coc* statutory_tax_rate METR*

format		coc*    %9.02f

format		METR* %9.02f
}																					// closes cft

***Allowance for equity

if "`system'"=="ace" {

gen 		coc_ace=.											// the cost of capital of a non-refundable CIT with declining balance depreciation

forval taxrate=0(1)40 {
local 	p = `realint'										 	// initial guess for coc (3 percentange point above the real interest rate)
local tolerance = 0.0001  										// how close to zero we need to get econnomic rent
local max_iter = 1000 											// maximum number of iterations
local iter = 0  												// iteration counter

* Begin the iterative process
while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p

	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + `rho') ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	

if "`deprtype'"=="db" {

	gen 		double profit_ace=0
	replace		profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`i'*(1-`depreciation')         if t==1     // i*(1-phi) is the allowance for corporate equity
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-`i'*(1-`depreciation')^t + min(0,profit_ace[_n-1])  if t>1
	la 			var profit_ace "profit under non-refundable ACE"

****for the top-up tax
	gen 		double cov_profit_ace=0
	replace		cov_profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation') -`debt'*`i' + QRTC      if t==1    
	replace		cov_profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,cov_profit_ace[_n-1]) + QRTC  if t>1
	la 			var cov_profit_ace "covered tax under non-refundable ACE"
}

if "`deprtype'"=="sl" {

	gen 		double profit_ace=0
	replace		profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')- `i'*max(1-`depreciation',0)        if t==1     // i*(1-phi) is the allowance for corporate equity
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-`i'*max(1-t*`depreciation',0) + min(0,profit_ace[_n-1])  if t>1
	la 			var profit_ace"profit under non-refundable ACE"

****for the top-up tax
	gen 		double cov_profit_ace=0
	replace		cov_profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation') -`debt'*`i' + QRTC      if t==1    
	replace		cov_profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-`debt'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + min(0,cov_profit_ace[_n-1]) + QRTC  if t>1
	la 			var cov_profit_ace "covered tax under non-refundable ACE"
}

	gen  		double		Tax_ace=0
	replace					Tax_ace=(`taxrate'/100)*max(profit_ace,0) -QRTC-min((`taxrate'/100)*max(profit_ace,0),NQRTC)	if `holiday'==0
	// period by period tax liability (if taxable income is negative, then tax is zero (i.e., no-refund))   	
	replace					Tax_ace=-QRTC	if t<=`holiday' & `holiday'>0		
	replace					Tax_ace=(`taxrate'/100)*max(profit_ace,0) -QRTC-min((`taxrate'/100)*max(profit_ace,0),NQRTC)	if t>`holiday' & `holiday'>0	
	
	gen  		double 		Tax_ace_time = Tax_ace/((1 + `rho') ^ t)								// The discounted value of each peruiod's tax liability
	egen 		double		Tax_ace_NPV = total(Tax_ace_time)									// NPV of the the sum of taxes paid

/*====================    
Second, the top-up tax
======================*/	
*Calculate the top-up tax base (note that the top-up tax base is the accounting profit (not including the tax credit) minus SBIE.)
	gen 		double exprofit_ace=max(0,cov_profit_ace-SBIE)
	
	gen 		covtax_ace=0										// covered tax
	replace 	covtax_ace=(`taxrate'/100)*max(0,profit_ace)-min((`taxrate'/100)*max(0,profit_ace),NQRTC) if `holiday'==0
	replace 	covtax_ace=(`taxrate'/100)*max(0,profit_ace)-min((`taxrate'/100)*max(0,profit_ace),NQRTC) if t>`holiday' & `holiday'>0
	
	gen	double	tpr_ace=0
	replace 	tpr_ace=max(0,`minrate'-(covtax_ace)/cov_profit_ace)	    if cov_profit_ace>0													//the top-up tax in each period for each value of the tax rate
	la var 		tpr_ace "Top up tax rate under a non-refundable ACE"
	
	gen 		double tpt_ace=tpr_ace*exprofit_ace/(1+`rho')^t	  // top-up tax (discounted value) (nothe: the excess profit is similar to the excess profit value under the standard CIT)
	egen 		double total_tpt_ace=total(tpt_ace)	
	
/*=========================
Third, define economic rent and check if economic rent is close enough to zero 
=========================*/	
gen 		double 	econrent_ace=`gamma'*(revenue_NPV-1-Tax_ace_NPV-total_tpt_ace) +  `newequity'*(`gamma'-1)+ `debt'*`gamma'*( `rho'-`i')/( `rho'-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
     


    if abs(econrent_ace) < `tolerance' {
        display "Converged: p`taxrate' = " `p'
        break
    }

    * Adjust p based on whether the sum is positive or negative
	if abs(econrent_ace)>=0.1 {
		local p = `p' - econrent_ace/10	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
	}
   
	if abs(econrent_ace)<0.1  {
		local p = `p' - econrent_ace/5	 										// adjust p downwards if economic rent is positive and upwards if econ rent is negative
	}
    * Increment the iteration counter
    local iter = `iter' + 1

    * Drop variables for the next iteration
    drop revenue revenue_time revenue_NPV profit_ace Tax_ace Tax_ace_time Tax_ace_NPV cov_profit_ace covtax_ace exprofit_ace tpr_ace tpt_ace total_tpt_ace econrent_ace 				// to allow for the next iteration
	}



* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}
	local n=`taxrate'+1
	*replace taxrate_s = `taxrate' in `n'
    replace coc_ace = `p'    in `n'
}

gen METR_ACE= 100*( coc_ace-`realint')/  coc_ace
replace		coc_ace=100*coc_ace  

keep 		if t<=40
rename	 	t statutory_tax_rate
keep		coc* statutory_tax_rate METR*

format		coc*    %9.02f

format		METR* %9.02f
}
}																				// closes the no-refund but minimum tax routine
}																				// closes the minimim tax=yes routine


merge 1:1 statutory_tax_rate using `aetr'
drop	_m
}																				// closes the "quitely" bracket

**To get rid of the name of the system as an extention

rename		coc_*  		coc
rename		METR_*		METR
rename		AETR*		AETR 


********************
if "`minimumtax'"=="yes" {
	
matrix parameters= J(14, 1,.)  // Create a 2x1 matrix
matrix parameters[1, 1] = 100*`inflation'
matrix parameters[2, 1] = 100*`i'
matrix parameters[3, 1] = 100*`depreciation'
matrix parameters[4, 1] = 100*`delta'
matrix parameters[5, 1] = 100*`debt'
matrix parameters[6, 1] = 100*`newequity'
matrix parameters[7, 1] = 100*`profit'
matrix parameters[8, 1] = 100*`sbie'
matrix parameters[9, 1] = 100*`qrtc'
matrix parameters[10, 1] = 100*`nqrtc'
matrix parameters[11, 1] = `holiday'
matrix parameters[12, 1] = 100*`pitint'
matrix parameters[13, 1] = 100*`pitdiv'
matrix parameters[14,1] = 100*`pitcgain'

matrix rownames parameters ="Inflation(%)" "Nominal interest rate(%)" ///
					"Tax depreciation(%)" "Economic depreciation(%)"  ///
					"Share of debt financing(%)" "Share of new equity finance(%)" ///
							"Profitability(%)" ///
							"SBIE (%)" "QRTC (%)" "NQRTC (%)" ///
							 "Number of years of tax holiday" ///
				"tax rate on interest income(%)" "tax rate on dividend income(%)" ///
				"tax rate on capital gains(%)"
				
local depr_text
if "`deprtype'" == "db" {
    local depr_text "Depreciation method: Declining balance"
}
if "`deprtype'" == "sl" {
    local depr_text "Depreciation method: Straight line"
}

local refund_text
if "`refund'" == "yes" {
    local refund_text "Full loss offset: Yes"
}
else if "`refund'" == "no" {
    local refund_text "Full loss offset: No"
}

local minimumtax_text "Pillar two minimum tax applies"


qui {
esttab matrix(parameters) using parameters.txt, replace ///
    cells("b")  noabbrev varwidth(30) noobs nonumber ///
	eqlabels(none) mlabels(,none) collabels("Parameters") ///
	alignment(c) gaps nolines  nolines  ///
	addnotes("`depr_text'" "`refund_text'" "`minimumtax_text'") 
}

type parameters.txt	
}


if "`minimumtax'"=="no" {

matrix parameters= J(11, 1,.)  // Create a 2x1 matrix
matrix parameters[1, 1] = 100*`inflation'
matrix parameters[2, 1] = 100*`i'
matrix parameters[3, 1] = 100*`depreciation'
matrix parameters[4, 1] = 100*`delta'
matrix parameters[5, 1] = 100*`debt'
matrix parameters[6, 1] = 100*`newequity'
matrix parameters[7, 1] = 100*`profit'
matrix parameters[8, 1] = `holiday'
matrix parameters[9, 1] = 100*`pitint'
matrix parameters[10, 1] = 100*`pitdiv'
matrix parameters[11,1] = 100*`pitcgain'

matrix rownames parameters ="Inflation (%)" "Nominal interest rate (%)" ///
							"Tax depreciation (%)" "Economic depreciation (%)"  ///
				"Share of debt finance(%)" "Share of new equity finance(%)" ///
				"Profitability (%)" "Number of years of tax holiday" ///
				"tax rate on interest income(%)" "tax rate on dividend income(%)" ///
				"tax rate on capital gains(%)" 
		
local depr_text
if "`deprtype'" == "db" {
    local depr_text "Depreciation method: Declining balance"
}
if "`deprtype'" == "sl" {
    local depr_text "Depreciation method: Straight line"
}

local refund_text
if "`refund'" == "yes" {
    local refund_text "Full loss offset: Yes"
}
else if "`refund'" == "no" {
    local refund_text "Full loss offset: No"
}

local minimumtax_text "Pillar two minimum tax does not apply"


qui {
esttab matrix(parameters) using parameters.txt, replace ///
    cells("b")  noabbrev varwidth(30) noobs nonumber ///
	eqlabels(none) mlabels(,none) collabels("Parameters") ///
	alignment(c) gaps nolines  nolines  ///
	addnotes("`depr_text'" "`refund_text'" "`minimumtax_text'") 
}

type parameters.txt	
}

end