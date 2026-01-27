/******************************************************************************* 
Title: 			aetr, metr model ado file
Author: 		Andualem Mengistu & Shafik Hebous
Email:			amengistu2@imf.org
Date created: 	July 11, 2024
Date revised:	February 3, 2025
Date revised:	Nov 21, 2025
Description:	Master file for running the ETR simulation
Version:		0.1.1
*******************************************************************************/	
capture program drop etr 
program define etr
    version 15
*   set type double
	clear all
*	drop _all

syntax,   [system(string)				/// cit, cft, or ace
		   inflation(real 0.05) 		/// inflation rate (default 5%)
           realint(real 0.05) 			/// real interest rate (default 5%)
           p(real 0.2)					/// profit level (default 10%)
		   beta(real 0.4)				/// The coefficient on capital in a Cobb-Douglas production function
		   debt(real 0)					/// 1 if completely financed with debt. zero is the default. 
		   newequity(real 0)			/// 1 if completely financed with new equity. Zero is default. It can take values in the range of 0 to 1
		   deprtype(string)				/// d for declining balance, s for straightline depreciation method.
		   depreciation(real 0.25) 		/// the depreciation rate for tax purposes. default value is 25%
           delta(real 0.25) 			/// economic depreciation rate. Default value is 25%
           superdeduction(real 0)		/// The super deduction allows businesses to increase the acquisition cost of capital assets when calculating tax deductions. The default value is 0. It can take values between 0 and 1.5. 1.5 means the cost of acqusition is boosted by 150%.
		   inal(real 0)					/// Initial allowance. Relevant for cases where depreciaiton type is initialSL or initialDB
		   holiday(real 0)				/// the number of years of tax holiday. The default value is zero
		   qrtc(real 0) 				/// as a share of the book value of capital (the tax depreciated amount of capital). 0% is the defualt value. The bracket indicates that these are optional.
           nqrtc(real 0) 				/// as a share of capital (the tax depreciated amount of capital). 0% is the default value
		   credit(real 0)                ///Tax credit that is not multiplied by the tax rate.
		   taxcredit(real 0)			/// This is associated with the tax rate
		   minrate(real 0.15)			/// the minimum tax rate
		   minimumtax(string) 			/// "yes" if the user would like to calculate the metr inclusive of pillar two. the default is no minimum tax.
		   carveout(real 0.05)			/// The carevout parameter (currently the applied rates are 10% on payroll and 8% on tangible asset. Here, the default is the long run carveout of 5% on both payroll and tangible asset)
		   pitdiv(real 0)				/// The tax rate on dividend income in source country
		   pitint(real 0)				/// The tax rate on interest income in source country
		   pitcgain(real 0)				/// The tax rate on capital gains income in source country
		   qtil(real 0) 				///	QTI-L utilization in [0,1]			
		   qtik(real 0) 				/// QTI-K utilization in [0,1]	
		   sl(real 0.055) 				/// S_L (payroll coefficient cap)
		   sk(real 0.055) 				/// S_K (capital coefficient cap)
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
				

***Financing mix

if `debt'<0 | `debt'>1 {
	display "The specified debt financing ratio is out of the acceptable range. Acceptable range is 0 to 1 (i.e., between 0 and 100%)"
	exit 125
}

if `newequity'<0 | `newequity'>1 {
	display "The specified new equity financing ratio is out of the acceptable range. Acceptable range is 0 to 1 (i.e., between 0 and 100%)"
	exit 125
}

if `debt' + `newequity' > 1 {
    di as err "debt() + newequity() cannot exceed 1."
    exit 125
}


***Depreciations

if `depreciation'<0 | `depreciation'>1 {
	display "The specified depcreciation parameter is out of the acceptable range. Acceptable range is 0 to 1 (i.e., between 0 and 100%)"
	exit 125
}

if `delta'<0 | `delta'>1 {
	display "The specified economic depcreciation parameter is out of the acceptable range. Acceptable range is 0 to 1 (i.e., between 0 and 100%)"
	exit 125
}

if `superdeduction'<0 | `superdeduction'>1.5 {
	display "The specified depcreciation parameter is out of the acceptable range. Acceptable range is 0 to 1.5 (i.e., between 0 and 150%)"
	exit 125
}



***Pillar Two tax credits
*--------------------------------------------------
* Validate qtil()
*--------------------------------------------------
if ("`qtil'" != "") {
    if (`qtil' < 0 | `qtil' > 1) {
        di as err ///
        "Option qtil() must be in [0,1]. You set qtil(`qtil')."
        exit 198
    }
}

*--------------------------------------------------
* Validate qtik()
*--------------------------------------------------
if ("`qtik'" != "") {
    if (`qtik' < 0 | `qtik' > 1) {
        di as err ///
        "Option qtik() must be in [0,1]. You set qtik(`qtik')."
        exit 198
    }
}

*--------------------------------------------------
* Enforce mutual exclusivity
*--------------------------------------------------
if ("`qtil'" != "" & "`qtik'" != "") {
    if (`qtil' > 0 & `qtik' > 0) {
        di as err ///
        "Options qtil() and qtik() are mutually exclusive. " ///
        "Either qtil or qtik must be zero. You set " ///
        "qtil(`qtil') and qtik(`qtik')."
        exit 198
    }
}


***production function
if `beta' <= 0 | `beta' >= 1 {
    di as err "beta must lie in (0,1) for Cobb-Douglas."
    exit 125
}


****personal income taxes
foreach v in pitdiv pitint pitcgain {
    if ``v'' < 0 | ``v'' > 1 {
        di as err "`v' must lie between 0 and 1 (i.e., 0–100%)."
        exit 125
    }
}


***Systems

if "`system'" == "" {
        local system "cit"                						// default system is cit
    }
	
if !inlist("`system'","cit","cft","ace","") {
    di as err "system() must be one of: cit, cft, ace, or omitted."  // If anything other than cit,cf,ace, or omitted is supplied provide error message.
    exit 125
}
	

if "`minimumtax'" == "" {
        local minimumtax "no"                						// default value of minimumtax is "no"
    }

	
if "`deprtype'" == "" {
    local deprtype "db"											// Defualt value of depreciation is declining balance (if the user does not provide one)
}

	
* Allowed deprtypes depend on minimumtax
if "`minimumtax'" == "yes" {
    local allowed_deprtypes "sl db"
}
else {
    local allowed_deprtypes "sl db initialDB initialSL SLorDB"
}

* Validate
if !inlist("`deprtype'", "sl", "db", "initialDB", "initialSL", "SLorDB") {
    di as err "Invalid deprtype(`deprtype')."
    di as err "Allowed values: sl | db | initialDB | initialSL | SLorDB (or omit deprtype())."
    exit 198
}

* Enforce minimumtax restriction
if "`minimumtax'" == "yes" & !inlist("`deprtype'", "sl", "db") {
    di as err "Invalid deprtype(`deprtype') under minimumtax=yes."
    di as err "Allowed values under minimumtax=yes: sl | db (or omit deprtype())."
    exit 125
}

															

if `depreciation' == 0 {
	 di as err "The program does not accept zero as depreciation"
}																	
	
	
local profit=`p'
	
/***********************************************************************************************
************************************Program code here*******************************************/
quietly {
	
	
// Set observations. This helps us calculate NPVs
	set 		obs 350   														// sets values from 1 to 150
	gen 		t=_n-1															// starts time from zero
 
 
	local i = `realint' + `inflation' + `realint' * `inflation'					// nominal interst rate
	

	***Parameters based on the intereaction of PIT and cit
	local gamma=(1- `pitdiv')/(1-`pitcgain')									//((1-m_d))/((1-z)(1-c))=γ
	local rho=((1- `pitint')*`i')/(1-`pitcgain')								//(1-m_i )i/((1-z))=ρ
	local	qrtc=`qrtc'*(`realint'+`delta')/(1+`delta')
	local	nqrtc=`nqrtc'*(`realint'+`delta')/(1+`delta')

	sort t

	tempfile 	generalparamter
	save 		`generalparamter',replace	

/*============================================================================================================
1. In this section, we generate the aetr, without a top-up, of a standard cit, R-based cash flow tax, and ace 
=============================================================================================================*/

/*================
Refundable System
=================*/
if "`minimumtax'"=="no" {

********************************************
***Standard cit
********************************************

if "`system'"=="cit" {
	
	keep 		if t<=50 
	gen 		tau=t/100
	
**NPV of deprecaition taking in to account personal income taxes and tax holiday
	local T =1/`depreciation'						// To determine the maximum number of years for straight line depreciation

* DB present value
	local Adep_db = (`depreciation'*(1+`rho')/(`depreciation'+`rho')) ///
                * (((1-`depreciation')/(1+`rho'))^`holiday') 		// superdeduction is usually claimed in the first period
		
* Initial DB present value
	local Adep_initialDB = ///
    (`inal')*( `holiday'==0 ) ///
    + (1-`inal')* ( (`depreciation'/(`depreciation'+`rho')) ///
                              * (((1-`depreciation')/(1+`rho'))^`holiday') )							//	( `holiday'==0 ) is a boolean, 1 if holiday=0 and o if holiday is above zero.
	
		
* SL present value with positive-part operator
	local Adep_sl =  `depreciation' * ((1+`rho')/`rho') ///
                * max((1/(1+`rho'))^`holiday' - (1/(1+`rho'))^`T', 0)   // superdeduction is usually claimed in the first period	 

* Initial straight line
	local Adep_initialSL = ///
		(`inal') * (`holiday'==0) ///
		+ (1-`inal') * (`depreciation'/`rho') ///
        * max((1/(1+`rho'))^`holiday' - (1/(1+`rho'))^`T', 0)	 						// This captures the czeckia system referred to as method1 in the IBFD summary (see 2022)

*If businesses are allowed to choose either SL or DB				

	local Adep_SLorDB =max((`depreciation'*(1+`rho')/(`depreciation'+`rho')) ///
                * (((1-`depreciation')/(1+`rho'))^`holiday') ,  `depreciation' * ((1+`rho')/`rho') ///
                * max((1/(1+`rho'))^`holiday' - (1/(1+`rho'))^`T', 0))			
				
				
* Unified selector
* ------------------------------------------------------------
local Adep .

if "`deprtype'"=="db"              local Adep `Adep_db'
else if "`deprtype'"=="sl"         local Adep `Adep_sl'
else if "`deprtype'"=="initialDB"  local Adep `Adep_initialDB'
else if "`deprtype'"=="initialSL"  local Adep `Adep_initialSL'
else if "`deprtype'"=="SLorDB"     local Adep `Adep_SLorDB'
 
*****tax credit taking into account personal income taxes			 

	gen  		NPVcredit=.
	replace  	NPVcredit=`credit'								// If the credit does not depend on the tax rate    // the NPV of tax credit (that is not affected by the tax rate)
	replace		NPVcredit=tau*`taxcredit' if `credit'==0		// If tax credit depends on the tax rate (NPV)

gen double econrent_cit=.	


 ****when holiday=0
 
replace econrent_cit = ///
    `gamma' * ( ///
        ( (1 + `inflation') * (`p' + `delta') * (1 - tau) ) ///
            / ( `rho' - `inflation' + `delta' * (1 + `inflation') ) ///
        - 1 ///
        + tau * (`Adep'+`superdeduction') ///
        + NPVcredit ///
        + `newequity'*(1 - tau*`depreciation') * ( (`gamma' - 1) / `gamma' ) ///
        + `debt' * (1 - tau*`depreciation') * ( ///
              ( `rho' - (1 - tau) * `i' ) ///
              / ( `rho' - `inflation' + `delta' * (1 + `inflation') ) ///
          )   )     if `holiday'==0
 

 
 
 ****when holiday>0
 
 replace econrent_cit = ///
    `gamma' * ( ///
        ( (1 + `inflation') * (`p' + `delta') * ///
          ( 1 - tau *((1 - `delta')*(1 + `inflation') / (1 + `rho') )^`holiday' ///
          ) ///
        ) / ( `rho' - `inflation' + `delta' * (1 + `inflation') ) ///
        - 1 ///
        + tau * `Adep' ///                        // A_holiday
        + `newequity' * ( (`gamma' - 1) / `gamma' )  /// new equity
        + `debt' * ( ///
              ( `rho' - `i' + tau * `i' * ///
                    ( (1 - `delta') * (1 + `inflation') / (1 + `rho') )^`holiday' ///
              ) ///
              / ( `rho' - `inflation' + `delta' * (1 + `inflation') ) ///
          ) )    if `holiday' > 0


	gen aetr_cit=.
	replace aetr_cit= 100*((`p'-`realint')/(`realint'+`delta')-econrent_cit)/((`p')/(`realint'+`delta'))
		

		
		
******************************************************		
***Cost of capital and the metr	

gen double coc_cit=.

**When tax holiday is zero
	
replace coc_cit =  (((1 - tau*(`Adep'+`superdeduction'))- NPVcredit ///
            + `newequity' * (1 - tau*`depreciation') * ( (1 - `gamma') / `gamma' ) ) ///
        * ( `rho' - `inflation' + `delta' * (1 + `inflation') ) ///
        - ///
        `debt' * (1 - tau*`depreciation') * ( `rho' - (1 - tau) * `i' ) ) ///
    / ( (1 + `inflation') * (1 - tau) ) ///
    - `delta'     if `holiday'==0
	

**When tax holiday is positive

 
replace coc_cit  = ( ((1 - tau * `Adep') + `newequity' * (1 - `gamma') / `gamma' ) ///
        * ( `rho' - `inflation' + `delta' * (1 + `inflation') ) ///
        - `debt' * ( `rho' - `i' ///
      + tau * `i' * ((1 - `delta') * (1 + `inflation') / (1 + `rho') )^`holiday') ) ///
    / ( (1 + `inflation') * (1 - tau*((1 - `delta') * (1 + `inflation') / (1 + `rho') )^`holiday'))  ///
    - `delta'      if `holiday'>0

	


gen 	metr_cit=100*(coc_cit-`realint')/abs(coc_cit)
gen 	metr2_cit=100*(coc_cit-`realint')/abs(`realint')
replace	coc_cit=100*coc_cit		

keep		t 			aetr_cit coc_cit metr_cit metr2_cit 
rename 		(t aetr_cit coc_cit metr_cit metr2_cit) ///
			(statutory_tax_rate  aetr coc metr metr2) 
			
foreach var in aetr coc metr metr2 {
	replace `var'=round(`var', 0.001)
}

format 		aetr coc metr metr2 	%9.3f
la var 		aetr 		"aetr of a Standard cit System (%)"
la var 		metr 		"metr of a Standard cit System (%)"
la var 		metr2 		"metr of a Standard cit System (%) with r as a denominator"
la var 		coc	 		"The cost of capital of a standard cit (%)"
la var 		statutory_tax_rate "tax rate in %"

order 		statutory_tax_rate coc metr metr2 aetr

tempfile  	pre_globe
save 	 	`pre_globe.dta', replace
	}



******************************************************
***R-based cashflow tax
******************************************************

if "`system'"=="cft" {
	
	keep 		if t<=50 
	gen 		tau=t/100

	
gen double econrent_cft = ///
    (1 - tau) * `gamma' * (((1 + `inflation') * `p' - `rho' + `inflation') ///
        / ( `rho' - `inflation' + `delta' * (1 + `inflation') ) ) ///
    + `newequity' * (1-tau)*( `gamma' - 1 ) ///
    + `debt' * (1 - tau) * `gamma' * ( ///
        ( `rho' - `i' ) ///
        / ( `rho' - `inflation' + `delta' * (1 + `inflation')))

		
gen 	aetr_cft=.
replace aetr_cft= 100*((`p'-`realint')/(`realint'+`delta')-econrent_cft)/(`p'/(`realint'+`delta'))


gen  	coc_cft= ///
      ( (`rho' - `inflation') / (1 + `inflation') ) ///
    - `debt' * ( (`rho' - `i') / (1 + `inflation') ) ///
    + `newequity' * ( ///
          ( (1/`gamma') - 1 ) * (`rho' - `inflation' + `delta'*(1 + `inflation')) ///
          / (1 + `inflation') )
		  
		  
gen 		metr_cft=100*(coc_cft-`realint')/abs(coc_cft)
gen 		metr2_cft=100*(coc_cft-`realint')/abs(`realint')
replace		coc_cft=100*coc_cft		

keep		t 			aetr_cft coc_cft metr_cft metr2_cft
rename		(t aetr_cft coc_cft metr_cft metr2_cft) ///
			(statutory_tax_rate aetr coc metr metr2)
			
foreach var in aetr coc metr metr2 {
	replace `var'=round(`var', 0.001)
}
format 		aetr coc metr metr2	%9.3f
la var 		aetr 		"aetr of a cft System (%)"
la var 		metr 		"metr of a cft System (%)"
la var 		metr2 		"metr of a cft System (%) with r as a denominator"
la var 		coc	 		"The cost of capital of a cft (%)"
la var 		statutory_tax_rate "tax rate in %"
order 		statutory_tax_rate coc metr metr2 aetr 
tempfile  	pre_globe
save 	 	`pre_globe.dta', replace

}		

*******************************************
***ace
******************************************

if "`system'"=="ace" {	
	
	keep 		if t<=50 
	gen 		tau=t/100
	
	 if 	"`deprtype'" == "db"  {
	local	Adep=(`depreciation'*(1+`rho')/(`depreciation'+`rho')) 
	 }
	 
	 if 	"`deprtype'" == "sl" { 
	
	local		Adep=`depreciation'*((1+`rho')/`rho')(1-(1/((1+`rho')^(1/`depreciation'))))	
   }
	
	
gen 		double econrent_ace=.
replace 	econrent_ace= ///
			`gamma' * ( ///
        ( (1 + `inflation') * (`p' + `delta') * (1 - tau) ) ///
            / ( `rho' - `inflation' + `delta' * (1 + `inflation') ) ///
        - 1 ///
        + tau * `Adep' ///
        + tau * ( `i' * (1 - `Adep') / `rho' ) ///
        + `newequity' * (1 - tau*`depreciation') * ( (`gamma' - 1) / `gamma' ) ///
        + `debt' * ((1 - tau*`depreciation') * (`rho' - `i') ///
              / ( `rho' - `inflation' + `delta' * (1 + `inflation') ) ///
          ) )

gen 	aetr_ace=.
replace aetr_ace= 100*((`p'-`realint')/(`realint'+`delta')-econrent_ace)/(`p'/(`realint'+`delta'))


gen double coc_ace=.
	
replace coc_ace = ( ( (1 - tau*`Adep') ///
            - (tau * `i' * (1 - `Adep') / `rho') ///
            + `newequity' * (1 - tau*`depreciation') * ( (1/`gamma') - 1 ) ///
        ) * ( `rho' - `inflation' + `delta' * (1 + `inflation') ) ///
        - ///
        `debt' * (1 - tau*`depreciation') * ( `rho' - `i' ) ) ///
    / ( (1 + `inflation') * (1 - tau) ) -`delta'

gen 		metr_ace=100*(coc_ace-`realint')/abs(coc_ace)
gen 		metr2_ace=100*(coc_ace-`realint')/abs(`realint')
replace		coc_ace=100*coc_ace		

keep		t 			aetr_ace coc_ace metr_ace metr2_ace 

rename		(t 	aetr_ace coc_ace metr_ace metr2_ace) ///
			(statutory_tax_rate aetr coc metr metr2)
			
format 		aetr coc metr metr2 	%9.3f


foreach var in aetr coc metr metr2 {
	replace `var'=round(`var', 0.001)
}

la var 		aetr 		"aetr of an ace System (%)"
la var 		metr 		"metr of an ace System (%)"
la var 		metr2		"metr of an ace  System (%) with r as a denominator"
la var 		coc 		"The cost of capital of an ace (%)"
la var 		statutory_tax_rate "tax rate in %"
order 		statutory_tax_rate coc metr metr2 aetr

tempfile  	pre_globe
save 	 	`pre_globe.dta', replace
	
		}  											// closes the ace system
												
} 										// closes the minimumtax=no system.	


/*=========================================================================================================================================================
										Section 2: aetr under pillar Two
										
The steps we follow: First, check whether the excess profit is positive under the assumed profitability. If so, use the topup formula. If the excess profit is negative or zero, 
use the formula for the domestic tax (without pillar two)
========================================================================================================================================================*/

if "`minimumtax'"=="yes" {
	

*******************************************************
*               aetr FOR STANDARD cit
*      (0–50% statutory rates, QRTC/NQRTC)
*******************************************************
preserve
if "`system'"=="cit" {

    ********************************************************
    * 1. Compute PV of depreciation allowances (Anpv)
    ********************************************************
    if "`deprtype'" == "db" {
   	local Anpv = `depreciation'*(1+`i')/(`depreciation'+`i')
   }
   
	if "`deprtype'" == "sl" {    
    local 	Anpv = (`depreciation'*(1+`i')/`i')*(1 - 1/((1+`i')^(1/`depreciation')))
	}

	********************************************************
    * 2. Create container for aetr results
    ********************************************************
    keep if t<=50
    gen statutory_tax_rate = _n - 1
    gen double aetr_cit = .
    gen byte binds = .

  ********************************************************
    * 3. Loop over tax rates 0 to 50%
    ********************************************************
    forvalues taxrate = 0/50 {

        local tau = `taxrate'/100

        ********************************************************
        * 3A. Incentive type (mutually exclusive by validation)
        ********************************************************
        local p2credit "none"
        if (`qtil' > 0) local p2credit "qtil"
        if (`qtik' > 0) local p2credit "qtik"

        ********************************************************
        * 3B. Baseline GloBE ETR test (QTI within cap excluded)
        ********************************************************
        local X0_base = (1+`inflation')*(`p'+`delta') ///
                      + `inflation' - (1+`inflation')*`delta' ///
                      - `debt'*`i'*(1-`tau'*`depreciation')

        local D0 = `X0_base'
        local globe_ETR0 = `tau'              // since xi0 = X0/D0 = 1

        ********************************************************
        * 3C. Pillar II binding?
        ********************************************************
        local bind  = (`globe_ETR0' < `minrate')
        local theta = max(`minrate' - `tau',0)

        ********************************************************
        * 3D. Wage bill per unit of capital (omega*lambda)
        *     Cobb-Douglas: (omega*lambda) = (1-beta)/(beta - wedge) * (p+delta)
        *
        *     NB Type-L wedge: sL*qtil/(1-tau)
        *     B  Type-L wedge: (theta*carveout + sL*qtil)/(1-minrate)
        *
        *     Type-K does not affect labor wedge; handled via credit subtraction.
        ********************************************************
        local wedge_NB = (`sl'*`qtil')/(1-`tau')
        local wedge_B  = (`theta'*`carveout' + `sl'*`qtil')/(1-`minrate')

        local den_NB = `beta' - `wedge_NB'
        local den_B  = `beta' - `wedge_B'

        * Guard against division by (near) zero
        if (abs(`den_NB')<1e-10 | abs(`den_B')<1e-10) {
            local aetr = .
            local n = `taxrate' + 1
            replace aetr_cit = `aetr' in `n'
            replace binds    = `bind' in `n'
            continue
        }

        local ZNB = (1-`beta')*(`p'+`delta')/`den_NB'
        local ZB  = (1-`beta')*(`p'+`delta')/`den_B'

        ********************************************************
        * 3E. Excess profit proxy EX (use regime-consistent Z)
        ********************************************************
        local Z_use = cond(`bind', `ZB', `ZNB')    // use ZB if GlOBE binds, otherwise use ZNB.

        local EX = (1+`inflation')*((`p'+`delta') - `ZB'*`carveout') ///
                 + `inflation' - (1+`inflation')*`delta' ///
                 - `debt'*`i'*(1 - `tau'*`depreciation') ///
                 - `carveout'

        ********************************************************
        * 3F. PV incentive terms (paid in period 1 -> /(1+inflation))
        ********************************************************
        local INC_PV_L_NB = (`sl'*`qtil'*`ZNB')
        local INC_PV_L_B  = (`sl'*`qtil'*`ZB')
        local INC_PV_K    = (`sk'*`qtik'*`delta')/(1+`inflation')

        ********************************************************
        * 3G. AETR depending on binding and incentive type
        ********************************************************
        if (`bind' == 0 | `EX' <= 0) {   // if the doemstic tax rate greater than or equal to 15%, or binding excess profit is not positive

		
	*Note: If `bind'==0, then (`globe_ETR0' >= `minrate')
            * AETR WITHOUT TOP-UP
            if "`p2credit'"=="qtil" {
                local aetr = 100*(1/`p')*( ///
                    (`tau')*( (`p'+`delta') ///
                    - (`realint'+`delta')*`Anpv' ///
                    - `debt'*`i'*(1-`tau'*`depreciation')/(1+`inflation') ///
                    ) - `INC_PV_L_NB' )
            }
            else if "`p2credit'"=="qtik" {
                local aetr = 100*(1/`p')*( ///
                    (`tau')*( (`p'+`delta') ///
                    - (`realint'+`delta')*`Anpv' ///
                    - `debt'*`i'*(1-`tau'*`depreciation')/(1+`inflation') ///
                    ) - `INC_PV_K' )
            }
            else {
                local aetr = 100*(1/`p')*( ///
                    (`tau')*( (`p'+`delta') ///
                    - (`realint'+`delta')*`Anpv' ///
                    - `debt'*`i'*(1-`tau'*`depreciation')/(1+`inflation') ///
                    ) )
            }
        }
        else {

            * AETR WITH TOP-UP (binding)
            if "`p2credit'"=="qtil" {
                local aetr = 100*(1/`p')*( ///
                    (`minrate')*(`p'+`delta') ///
                    - (`realint'+`delta')*`Anpv'*`tau' ///
                    - `tau'*`debt'*`i'*(1-`tau'*`depreciation')/(1+`inflation') ///
                    + `theta'*( `inflation'/(1+`inflation') ///
                               - `delta' ///
                               - `debt'*`i'*(1-`tau'*`depreciation')/(1+`inflation') ///
                               - `carveout'/(1+`inflation') ///
                               - `ZB'*`carveout' ///
                              ) ///
                    - `INC_PV_L_B' )
            }
            else if "`p2credit'"=="qtik" {
                local aetr = 100*(1/`p')*( ///
                    (`minrate')*(`p'+`delta') ///
                    - (`realint'+`delta')*`Anpv'*`tau' ///
                    - `tau'*`debt'*`i'*(1-`tau'*`depreciation')/(1+`inflation') ///
                    + `theta'*( `inflation'/(1+`inflation') ///
                               - `delta' ///
                               - `debt'*`i'*(1-`tau'*`depreciation')/(1+`inflation') ///
                               - `carveout'/(1+`inflation') ///
                               - `ZB'*`carveout' ///
                              ) ///
                    - `INC_PV_K' )
            }
            else {
                local aetr = 100*(1/`p')*( ///
                    (`minrate')*(`p'+`delta') ///
                    - (`realint'+`delta')*`Anpv'*`tau' ///
                    - `tau'*`debt'*`i'*(1-`tau'*`depreciation')/(1+`inflation') ///
                    + `theta'*( `inflation'/(1+`inflation') ///
                               - `delta' ///
                               - `debt'*`i'*(1-`tau'*`depreciation')/(1+`inflation') ///
                               - `carveout'/(1+`inflation') ///
                               - `ZB'*`carveout' ///
                              ) )
            }
        }

        ********************************************************
        * 3H. Store results
        ********************************************************
        local n = `taxrate' + 1
        replace aetr_cit = `aetr' in `n'
        replace binds    = `bind' in `n'
    }

    ********************************************************
    * 4. Output formatting
    ********************************************************
    format aetr_cit %9.3f
    replace aetr_cit = round(aetr_cit,0.001)
    label var aetr_cit           "aetr of a standard cit (%)"
    label var statutory_tax_rate "Tax rate (%)"
    label var binds              "1 = Pillar II binds"

    keep statutory_tax_rate aetr_cit binds

    tempfile aetr
    save `aetr', replace
}
restore

				
						/**************************************************************************************** CASH FLOW TAX
* CFT AETR block (cash-flow tax), structured mirrors the CIT block
* Key modelling convention here:
*   - Domestic CFT gives full expensing, so PV of allowances A = 1 (no Anpv object needed).
*   - Non-binding (no top-up) AETR collapses to tau*(p - realint), with optional incentive subtraction.
*   - Binding (top-up) uses the same SBIE/carveout structure used in the CIT block, but with:
*       • interest NOT deducted from the domestic CFT base (your X0_base)
*       • interest deducted for GloBE (D0_base)
*   - Incentive type is handled via p2credit = {none, qtil, qtik} (same as CIT).
****************************************************************************************/

preserve
if "`system'"=="cft" {

    ********************************************************
    * 0. Keep the grid size consistent
    ********************************************************
    keep if t<=50

    ********************************************************
    * 1. Create container for results
    ********************************************************
    gen statutory_tax_rate = _n - 1
    gen double aetr_cft = .
    gen byte   binds   = .

    ********************************************************
    * 2. Loop over statutory tax rates: 0 to 50%
    ********************************************************
    forvalues taxrate = 0/50 {

        local tau = `taxrate'/100

        ********************************************************
        * 2A. Incentive type (mutually exclusive by validation)
        ********************************************************
        local p2credit "none"
        if (`qtil' > 0) local p2credit "qtil"
        if (`qtik' > 0) local p2credit "qtik"

        ********************************************************
        * 2B. X, D, xi, and baseline GloBE ETR (CFT version)
        *     - X excludes interest (domestic CFT base, per your assumption)
        *     - D includes interest deduction for GloBE
        ********************************************************
        local X0_base = (1+`inflation')*(`p'+`delta') ///
                      + `inflation' - (1+`inflation')*`delta'

        local D0_base = (1+`inflation')*(`p'+`delta') ///
                      + `inflation' - (1+`inflation')*`delta' ///
                      - `debt'*`i'*(1 - `tau')

        local xi0       = `X0_base'/`D0_base'
        local globe_ETR0 = `tau'*`xi0'
	
        ********************************************************
        * 2C. Pillar II binding and top-up wedge
        ********************************************************
        local bind  = (`globe_ETR0' < `minrate')
        local theta = max(`minrate' - `tau'*`xi0',0)   // only meaningful if bind==1
		
        ********************************************************
        * 2D. Wage bill per unit of capital (omega*lambda), via Z
        *     Mirror your CIT logic (Type-L affects the wedge; Type-K does not)
        ********************************************************
        local wedge_NB = (`sl'*`qtil')/(1-`tau')
        local wedge_B  = (`theta'*`carveout' + `sl'*`qtil')/(1-`minrate')

        local den_NB = `beta' - `wedge_NB'
        local den_B  = `beta' - `wedge_B'

        * Guard against division by (near) zero
        if (abs(`den_NB')<1e-10 | abs(`den_B')<1e-10) {
            local aetr = .
            local n = `taxrate' + 1
            replace aetr_cft = `aetr' in `n'
            replace binds   = `bind' in `n'
            continue
        }

        local ZNB = (1-`beta')*(`p'+`delta')/`den_NB'
        local ZB  = (1-`beta')*(`p'+`delta')/`den_B'

        ********************************************************
        * 2E. Excess profit proxy EX (use regime-consistent Z)
        ********************************************************
        local Z_use = cond(`bind', `ZB', `ZNB')   // if bind=1, then the doemstic tax rate is less than the GloBE minimum. Hence, the binding Z is used (ZB).

        local EX = (1+`inflation')*((`p'+`delta') - `ZB'*`carveout') ///
                 + `inflation' - (1+`inflation')*`delta' ///
                 - `debt'*`i'*(1-`tau') ///
                 - `carveout'

        ********************************************************
        * 2F. PV incentive terms (same objects as your CIT block)
        ********************************************************
        local INC_PV_L_NB = (`sl'*`qtil'*`ZNB')
        local INC_PV_L_B  = (`sl'*`qtil'*`ZB')
        local INC_PV_K    = (`sk'*`qtik'*`delta')/(1+`inflation')

        ********************************************************
        * 2G. AETR: non-binding (or no excess profit) vs binding
        ********************************************************
        if (`bind' == 0 | `EX' <= 0) {  //i.e., if the globe etr>15%, or the binding excess profit is not positive.

            * AETR WITHOUT TOP-UP
            * CFT with expensing => domestic AETR collapses to tau*(p - realint)
            if "`p2credit'"=="qtil" {
                local aetr = 100*(1/`p')*( (`tau')*(`p' - `realint') - `INC_PV_L_NB' )
            }
            else if "`p2credit'"=="qtik" {
                local aetr = 100*(1/`p')*( (`tau')*(`p' - `realint') - `INC_PV_K' )
            }
            else {
                local aetr = 100*(1/`p')*( (`tau')*(`p' - `realint') )
            }

        }
        else {

            * AETR WITH TOP-UP (binding)
            * We keep the same structural components we used under CIT binding:
            *   - (minrate)*(p+delta) as the "effective" tax on covered income
            *   - subtract domestic tax value of the normal return piece under CFT expensing
            *   - add theta * (adjustments including carveout and interest term for GloBE)
            if "`p2credit'"=="qtil" {
                local aetr = 100*(1/`p')*( ///
                    (`minrate')*(`p'+`delta') ///
                    - (`tau')*(`realint'+`delta') ///   // expensing: A = 1
                    + `theta'*( `inflation'/(1+`inflation') ///
                              - `delta' ///
                              - `debt'*`i'*(1-`tau')/(1+`inflation') ///
                              - `carveout'/(1+`inflation') ///
                              - `ZB'*`carveout' ///
                             ) ///
                    - `INC_PV_L_B' ///
                )
            }
            else if "`p2credit'"=="qtik" {
                local aetr = 100*(1/`p')*( ///
                    (`minrate')*(`p'+`delta') ///
                    - (`tau')*(`realint'+`delta') ///
                    + `theta'*( `inflation'/(1+`inflation') ///
                              - `delta' ///
                              - `debt'*`i'*(1-`tau')/(1+`inflation') ///
                              - `carveout'/(1+`inflation') ///
                              - `ZB'*`carveout' ///
                             ) ///
                    - `INC_PV_K' ///
                )
            }
            else {
                local aetr = 100*(1/`p')*( ///
                    (`minrate')*(`p'+`delta') ///
                    - (`tau')*(`realint'+`delta') ///
                    + `theta'*( `inflation'/(1+`inflation') ///
                              - `delta' ///
                              - `debt'*`i'*(1-`tau')/(1+`inflation') ///
                              - `carveout'/(1+`inflation') ///
                              - `ZB'*`carveout' ///
                             ) ///
                )
            }
        }

        ********************************************************
        * 2H. Store results
        ********************************************************
        local n = `taxrate' + 1
        replace aetr_cft = `aetr' in `n'
        replace binds   = `bind' in `n'
    }

    ********************************************************
    * 3. Output formatting
    ********************************************************
    format aetr_cft %9.3f
    replace aetr_cft = round(aetr_cft, 0.001)

    label var statutory_tax_rate "Tax rate (%)"
    label var aetr_cft           "aetr of a cash-flow tax (%)"
    label var binds              "1 = Pillar II binds"

    keep statutory_tax_rate aetr_cft binds

    tempfile aetr
    save `aetr', replace
}
restore

*===========================================================
*                           ace
*    aetr with decision-rule + ace as QRTC or NQRTC
*===========================================================


if "`system'"=="ace" {
	preserve

    *******************************************************
    * 1. Compute NPV of tax depreciation
    *******************************************************
   
    
	if "`deprtype'"=="db" {
	local  Anpv = `depreciation'*(1+`i')/(`depreciation'+`i') 
	}
	
	if "`deprtype'"=="sl" {
    local Anpv = (`depreciation'*(1+`i')/`i')*(1 - 1/((1+`i')^(1/`depreciation'))) 
	}

    *******************************************************
    * 2. Set up container for 51 observations
    *******************************************************
    gen statutory_tax_rate = _n - 1

    gen double aetr_ace_qrtc  = .
    gen double aetr_ace_nqrtc = .
    gen byte binds_qrtc  = .
    gen byte binds_nqrtc = .

    *******************************************************
    * 3. Loop over τ = 0…50%
    *******************************************************
    forvalues taxrate = 0/50 {
        local tau = `taxrate'/100

        *******************************************************
        * ace uplift
        * U = τ * (1+π)*(r+δ)*(1-Anpv)
        *******************************************************
        local U = `tau'*(1+`inflation')*(`realint'+`delta')*(1- `Anpv')

        *******************************************************
        * 3A. ----- ace AS QRTC -----
        *******************************************************
        *
        * QRTC interpretation:
        *   X = pure base
        *   D = X + U
        *   ξ = X / (X+U)
        *
        *******************************************************

        * Base for X (same structure as metr/cit)
        local X0q = (1+`inflation')*(`p'+`delta') ///
                    + `inflation' - (1+`inflation')*`delta'

        * D includes ace uplift U and interest deduction
        local D0q = (1+`inflation')*(`p'+`delta') ///
                    + `inflation' - (1+`inflation')*`delta' ///
                    - `debt'*`i'*(1 - `tau'*`depreciation') ///
                    + `U'

        * ξ_q = X / D
        local xiq = `X0q'/`D0q'

        *******************************************************
        * Decision rule
        *******************************************************
        local globe_ETRq = `tau'*`xiq'                     // This is the GLobE effective rate for ace when considered QRTC.
        if (`globe_ETRq' < `minrate') local bindq = 1
        else                           local bindq = 0

        *******************************************************
        * Z for ace as QRTC
        *******************************************************
        local theta_q = `minrate' - `tau'*`xiq'						// This is the top-up rate for an ace considered QRTC
        local denomq  = 1 - `tau' - `theta_q'

        local Zden_q  = `beta' - (`theta_q'*`carveout')/`denomq'
        local Z_q     = (1-`beta')*(`p'+`delta')/`Zden_q'

        *******************************************************
        * Excess profit for ace-QRTC
        *******************************************************
        local EX_q = (1+`inflation')*((`p'+`delta') - `Z_q'*`carveout') ///
                     + `inflation' - (1+`inflation')*`delta' ///
                     - `debt'*`i'*(1 - `tau'*`depreciation') ///
                     - `carveout' ///
                     + `U'

        *******************************************************
        * aetr of ace as QRTC
        *******************************************************
        if (`bindq'==0 | `EX_q'<=0) {														// If the top-up rate is less than or equal to zero or if the excess profit is less than or equal to zero/
            * No top-up:
            local aetrq = 100*(1/`p')*(`tau')*(`p'-`realint') 
        }
        else {
            * With top-up:
            local theta_q = `theta_q'

            local aetrq = 100*(1/`p')*( ///
                (`tau' + `theta_q')*(`p'+`delta') ///
                - (`realint'+`delta')*`tau' ///
                + `theta_q'*(`tau'*(`realint'+`delta')*(1- `Anpv') ///
                              + `inflation'/(1+`inflation') ///
                              - `delta' ///
                              - `debt'*`i'*(1-`tau'*`depreciation')/(1+`inflation') ///
                              - `carveout'/(1+`inflation') ///
                              - `Z_q'*`carveout' ///
                ) )
        }

        *******************************************************
        * 3B. ----- ace AS NQRTC -----
        *******************************************************
        *
        * NQRTC interpretation:
        *   X = X - U
        *   D = base - interest deduction only
        *   ξ = (X-U)/D
        *
        *******************************************************

        * Base for X again
        local Xb = (1+`inflation')*(`p'+`delta') ///
                   + `inflation' - (1+`inflation')*`delta'

        local X0n = `Xb' 
        local D0n = `Xb' - `debt'*`i'*(1-`tau'*`depreciation')

        local xin = `X0n'/`D0n'  

        local globe_ETRn = `tau'*`xin'- `U'/`D0n'   
        if (`globe_ETRn' < `minrate') local bindn = 1
        else                           local bindn = 0

        * Z for ace as NQRTC
        local Zden_n = `beta' - ((`minrate' - `tau'*`xin')*`carveout')/(1-`tau'-(`minrate'-`tau'*`xin'))
        local Z_n    = (1-`beta')*(`p'+`delta')/`Zden_n'

        * Excess profit
        local EX_n = (1+`inflation')*((`p'+`delta') - `Z_n'*`carveout') ///
                     + `inflation' - (1+`inflation')*`delta' ///
                     - `debt'*`i'*(1 - `tau'*`depreciation') ///
                     - `carveout'

        * aetr
        if (`bindn'==0 | `EX_n'<=0) {
            local aetrn = 100*(1/`p')*(`tau')*(`p'-`realint')
                          
        }
        else {
            local theta_n = `minrate' - (`tau'*`xin'- `U'/`D0n')

            local aetrn = 100*(1/`p')*( ///
                (`tau'+`theta_n')*(`p'+`delta') ///
                - (`realint'+`delta')*`tau'   ///
                            + `theta_n'*( `inflation'/(1+`inflation') ///
                              - `delta' ///
                              - `debt'*`i'*(1-`tau'*`depreciation')/(1+`inflation') ///
                              - `carveout'/(1+`inflation') ///
                              - `Z_n'*`carveout') )
        }

        *******************************************************
        * 4. Store results
        *******************************************************
        local n = `taxrate' + 1
        replace aetr_ace_qrtc  = `aetrq' in `n'
        replace aetr_ace_nqrtc = `aetrn' in `n'
        replace binds_qrtc  = `bindq' in `n'
        replace binds_nqrtc = `bindn' in `n'

    } // End taxrate loop

    *******************************************************
    * 5. Formatting & reshape
    *******************************************************

    label var aetr_ace_qrtc  "ace treated as QRTC – aetr (%)"
    label var aetr_ace_nqrtc "ace treated as NQRTC – aetr (%)"
    label var statutory_tax_rate "Statutory rate (%)"
	
	keep 		if statutory_tax_rate<=50
	keep 		statutory_tax_rate aetr*
	format 		aetr_ace_qrtc aetr_ace_nqrtc	 %9.3f
	replace 	aetr_ace_qrtc=round(aetr_ace_qrtc,0.001)
	replace 	aetr_ace_nqrtc=round(aetr_ace_nqrtc,0.001)

	keep 		statutory_tax_rate  aetr_ace_qrtc aetr_ace_nqrtc 

	tempfile	aetr
	save		`aetr', replace

	restore

	}						// closes ace

}										// closes the minimum tax==yes	routine			

				
****************************************************************************************
*************************Marginal Effective Tax Rate************************************
****************************************************************************************

	
if "`minimumtax'"=="yes" {

**************************************************************
* COST OF CAPITAL — CIT 
**** CORPORATE INCOME TAX (CIT): Cost of Capital / METR with QTIs (within cap)
*
*  Conceptual treatment
*  --------------------
*  • QTIs are excluded from covered taxes and covered income when computing
*    the GloBE effective tax rate (ETR).
*  • QTIs nevertheless affect the domestic investment incentive:
*      – Type-L QTI (qtil) enters the labor wedge and therefore affects the
*        equilibrium wage bill Z and the cost of capital.
*      – Type-K QTI (qtik) enters directly as a subsidy to capital in the
*        cost-of-capital numerator, equal to sK·qtik·δ/(1+inflation).
*  • Tax depreciation allowances affect the user cost through the present
*    value of depreciation deductions A^npv, which is asset- and method-specific.
*
*  Algorithm
*  ---------
*  (1) Non-binding benchmark:
*      Compute the non-binding cost of capital p_NB in closed form. This
*      corresponds to the standard CIT user-cost formula augmented by QTIs:
*        • Type-L QTIs affect p_NB through the labor wedge multiplier
*          mNB = (1−β)/(β − sL·qtil/(1−τ)).
*        • Type-K QTIs enter as a discounted capital subsidy in the numerator.
*        • Depreciation allowances enter via A^npv in the standard way.
*
*  (2) Preliminary regime screening:
*      If the statutory CIT rate τ is greater than or equal to the minimum
*      rate τ_min, the GloBE minimum cannot bind and p_NB is selected.
*
*  (3) Binding candidate:
*      If τ < τ_min, compute a closed-form candidate binding cost of capital
*      p_B that incorporates:
*        • the top-up rate θ = τ_min − τ,
*        • the binding labor wedge (θ·g_L + sL·qtil)/(1−τ_min),
*        • depreciation allowances through A^npv,
*        • and the Type-K QTI as a discounted capital subsidy.
*
*  (4) Ex-post regime validation:
*      Evaluate excess profit EX(p_B) using the binding equilibrium wage bill
*      Z(p_B). The Pillar Two regime is binding if and only if:
*        EX(p_B) > 0.
*
*  (5) Regime selection:
*      • If EX(p_B) > 0, set CoC = p_B and mark the observation as binding.
*      • Otherwise, fall back to the non-binding closed-form p_NB.
*
*  This structure ensures that the Pillar Two regime is activated only when
*  it is economically relevant (i.e., when excess profit is positive and top-up rate is positive).

**************************************************************
if "`system'"=="cit" {

    gen double coc_cit   = .
    gen byte   binds_cit = .

    *------------------------------------------------------*
    * PV of tax depreciation allowances (A^npv)
    *------------------------------------------------------*
    if "`deprtype'" == "db" {
        local Anpv = `depreciation'*(1+`i')/(`depreciation'+`i')
    }
    else if "`deprtype'" == "sl" {
        local Anpv = (`depreciation'*(1+`i')/`i')*(1 - 1/((1+`i')^(1/`depreciation')))
    }
    else {
        di as err "This METR(QTI) block supports deprtype sl or db only."
        exit 125
    }

    * GloBE carve-out parameters
    local gK = `carveout'
    local gL = `carveout'

    forvalues taxrate = 0/50 {

        local tau = `taxrate'/100

        * Capital-type QTI (paid in period 1 -> discounted)
        local INC_K = (`sk'*`qtik'*`delta')/(1+`inflation')

        /****************************************************
        * 1) NON-BINDING CLOSED FORM (always computable)
        ****************************************************/
        local wedge_NB = (`sl'*`qtil')/(1-`tau')
        local den_NB   = `beta' - `wedge_NB'

        if (abs(`den_NB') < 1e-10) {
            replace coc_cit   = . in `= `taxrate'+1'
            replace binds_cit = . in `= `taxrate'+1'
            continue
        }

        local MNB = (1-`beta')/`den_NB'

        local P_kcredit = ///
            (`realint' + `delta')*(1 - `tau'*`Anpv') ///
            - `tau'*`debt'*`i'*(1 - `tau'*`depreciation')/(1+`inflation') ///
            - `INC_K'

        local p_NB = (`P_kcredit' / ((1-`tau') + (`sl'*`qtil'*`MNB'))) - `delta'


        /****************************************************
        * 2) Regime logic wrapper:
        *    - If tau >= tau_min  -> NB for sure
        *    - If tau <  tau_min  -> compute binding candidate p_B,
        *                            check EXB(p_B), else revert to NB
        ****************************************************/
        if (`tau' >= `minrate') {

            replace coc_cit   = `p_NB' in `= `taxrate'+1'
            replace binds_cit = 0      in `= `taxrate'+1'

        }
        else {

            * --- Binding candidate (tau < tau_min) ---
            local theta  = max(`minrate' - `tau',0)
            local denomB = 1 - `minrate'

            * Binding labor wedge and multiplier (ZB = MB*(p+delta))
            local wedge_B = (`theta'*`gL' + `sl'*`qtil')/`denomB'
            local den_B   = `beta' - `wedge_B'

            if (abs(`den_B') < 1e-10) {
                * fall back to NB if binding wedge invalid
                replace coc_cit   = `p_NB' in `= `taxrate'+1'
                replace binds_cit = 0      in `= `taxrate'+1'
                continue
            }

            local MB = (1-`beta')/`den_B'

            * Base term
            local base = ///
                (`realint' + `delta')*(1 - `tau'*`Anpv') ///
                - `tau'*`debt'*`i'*(1 - `tau'*`depreciation')/(1+`inflation')

            * Constant part inside theta*(...)
            local C0 = ///
                `inflation'/(1+`inflation') ///
                - `delta' ///
                - `debt'*`i'*(1 - `tau'*`depreciation')/(1+`inflation') ///
                - `gK'/(1+`inflation')

            * Closed-form binding CoC
            local numB = `base' - `INC_K' + `theta'*`C0'
            local denB = `denomB' + `MB'*((`sl'*`qtil') + `theta'*`gL')

            if (abs(`denB') < 1e-10) {
                replace coc_cit   = `p_NB' in `= `taxrate'+1'
                replace binds_cit = 0      in `= `taxrate'+1'
                continue
            }

            local p_B = (`numB'/`denB') - `delta'

            * Compute ZB and EX at p_B
            local ZB  = `MB'*(`p_B' + `delta')

            local EXB = ///
                (1+`inflation')*((`p_B'+`delta') - `ZB'*`carveout') ///
                + `inflation' - (1+`inflation')*`delta' ///
                - `debt'*`i'*(1 - `tau'*`depreciation') ///
                - `carveout'

            * Regime selection: binding iff EXB > 0
            if (`EXB' > 0) {
                replace coc_cit   = `p_B' in `= `taxrate'+1'
                replace binds_cit = 1     in `= `taxrate'+1'
            }
            else {
                replace coc_cit   = `p_NB' in `= `taxrate'+1'
                replace binds_cit = 0      in `= `taxrate'+1'
            }
        }

    } // end loop over taxrate

    /*****************************************************
    * Compute METR (percent) and CoC (percent)
    *****************************************************/
    gen double metr_cit  = 100*(coc_cit - `realint')/abs(coc_cit)
    gen double metr2_cit = 100*(coc_cit - `realint')/abs(`realint')

    replace coc_cit = 100 * coc_cit

    keep if t <= 50
    rename t statutory_tax_rate
    keep coc* statutory_tax_rate metr* binds_cit

    format coc* metr* %9.3f
    foreach var in coc_cit metr_cit metr2_cit {
        replace `var' = round(`var',0.001)
    }

    tempfile metr
    save `metr', replace
}




*******************************************************
**** CASH-FLOW TAX (CFT): Cost of Capital / METR with QTIs (within cap)
*
*  Conceptual treatment
*  --------------------
*  • QTIs are excluded from covered taxes and covered income when computing
*    the GloBE effective tax rate (ETR).
*  • QTIs nonetheless affect the domestic investment incentive:
*      – Type-L QTI (qtil) enters the labor wedge and therefore affects the
*        equilibrium wage bill Z and the cost of capital.
*      – Type-K QTI (qtik) enters directly as a subsidy to capital in the
*        cost-of-capital numerator, equal to sK·qtik·δ/(1+inflation).
*
*  Algorithm
*  ---------
*  (1) Non-binding benchmark:
*      Compute the non-binding cost of capital p_NB in closed form:
*        • For Type-L QTIs, p_NB^L uses the mNB multiplier derived from the
*          labor wedge sL·qtil/(1−τ).
*        • For Type-K QTIs, p_NB^K subtracts the discounted capital subsidy
*          directly from the numerator.
*
*  (2) Binding candidate:
*      Starting from p_NB, solve the binding cost of capital p_B by fixed-point
*      iteration. In this step:
*        • qtil affects the wedge and Z through the labor distortion;
*        • qtik enters the numerator as a discounted capital subsidy;
*        • the top-up rate θ(p) is determined endogenously from the GloBE ETR.
*
*  (3) Ex-post regime validation:
*      After convergence, evaluate θ(p_B) and excess profit EX(p_B).
*      The Pillar Two regime is binding if and only if:
*        θ(p_B) > 0   and   EX(p_B) > 0.
*
*  (4) Regime selection:
*      • If the binding conditions hold, set CoC = p_B.
*      • Otherwise, fall back to the non-binding closed-form p_NB.
*
*  This structure ensures that regime classification is based exclusively on
*  economically meaningful objects evaluated at the candidate binding solution,
*  and avoids circular or pre-screened regime selection.
*******************************************************

if "`system'"=="cft" {

    gen double coc_cft   = .
    gen byte   binds_cft = .

    local gK = `carveout'
    local gL = `carveout'

    forvalues taxrate = 0/50 {

        local tau = `taxrate'/100

        ************************************************************
        * 0. QTI TYPE (mutually exclusive)
        ************************************************************
        local qti "none"
        if (`qtil' > 0) local qti "qtil"
        if (`qtik' > 0) local qti "qtik"

        * Type-K subsidy (paid in t+1)
        local Kterm = (`sk'*`qtik'*`delta')/(1+`inflation')

        ************************************************************
        * 1. NON-BINDING COST OF CAPITAL (CLOSED FORM)
        ************************************************************
        local p_NB = `realint'

        * Type-L
        if ("`qti'"=="qtil") {
            local num_common = (`realint'+`delta')*(1-`tau')
            local wedgeNB = (`sl'*`qtil')/(1-`tau')
            local denNB   = `beta' - `wedgeNB'
            if abs(`denNB')<1e-10 {
                replace coc_cft   = . in `= `taxrate'+1'
                replace binds_cft = . in `= `taxrate'+1'
                continue
            }
            local mNB  = (1-`beta')/`denNB'
            local p_NB = (`num_common'/((1-`tau') + `sl'*`qtil'*`mNB')) - `delta'
        }

        * Type-K
        if ("`qti'"=="qtik") {
            local p_NB = ((`realint'+`delta')*(1-`tau') - `Kterm')/(1-`tau') - `delta'
        }

        ************************************************************
        * 2. BINDING FIXED-POINT ITERATION (candidate p_B)
        ************************************************************
        local p       = `p_NB'
        local p_prev  = `p_NB'
        local f_prev  = .
        local have_prev = 0
        local iter    = 0
        local maxiter = 500
        local stepcap = 0.5
        local conv    = 0
        local p_B     = .

        while (`iter' < `maxiter' & !`conv') {

            * X(p)
            local X = (1+`inflation')*(`p'+`delta') ///
                      + `inflation' - (1+`inflation')*`delta'

            * GloBE base
            local D = `X' - `debt'*`i'*(1-`tau')
            if (`D'<=0) break

            local xi     = `X'/`D'
            local theta  = max(`minrate' - `tau'*`xi',0)
            local denom1 = 1 - `tau' - `theta'
            if abs(`denom1')<1e-10 break

            * Z(p)
            local wedge = (`theta'*`gL' + `sl'*`qtil')/`denom1'
            local Zden  = `beta' - `wedge'
            if abs(`Zden')<1e-10 break
            local Z = (1-`beta')*(`p'+`delta')/`Zden'

            * QTI terms
            local Lterm = (`sl'*`qtil'*`Z')

            * Fixed-point map
            local Gnum = (`realint'+`delta')*(1-`tau') ///
                       - `Kterm' ///
                       - `Lterm' ///
                       + `theta'*( ///
                           `inflation'/(1+`inflation') ///
                         - `delta' ///
                         - `debt'*`i'*(1-`tau')/(1+`inflation') ///
                         - `gK'/(1+`inflation') ///
                         - `gL'*`Z' ///
                       )

            local RHS = `Gnum'/`denom1' - `delta'
            local f   = `RHS' - `p'

            if abs(`f')<1e-10 {
                local p_B = `p'
                local conv = 1
                break
            }

            * Secant + damping
            if `have_prev' {
                local denom = `f' - `f_prev'
                if abs(`denom')>1e-10 {
                    local p_new = `p' - `f'*(`p'-`p_prev')/`denom'
                }
                else local p_new = (`p'+`p_prev')/2
                if (`f'*`f_prev'<0) local p_new = (`p'+`p_prev')/2
            }
            else {
                local p_new = `p' - 0.1*`f'/(1+abs(`f'))
            }

            local scale = max(1e-10,max(abs(`p'),abs(`p_prev')))
            if abs(`p_new'-`p')>`stepcap'*`scale' {
                local p_new = `p'+sign(`p_new'-`p')*`stepcap'*`scale'
            }

            if `p_new'<-0.25 local p_new=-0.25
            if `p_new'> 0.50 local p_new= 0.50

            local p_prev = `p'
            local f_prev = `f'
            local p      = `p_new'
            local have_prev = 1
            local iter = `iter'+1
        }

        ************************************************************
        * 3. EX-POST VALIDATION OF BINDING
        ************************************************************
        local valid_bind = 0

        if (`conv') {

            local Xb = (1+`inflation')*(`p_B'+`delta') ///
                       + `inflation' - (1+`inflation')*`delta'
            local Db = `Xb' - `debt'*`i'*(1-`tau')

            if (`Db'>0) {
                local xib    = `Xb'/`Db'
                local thetab = max(`minrate' - `tau'*`xib',0)
                local denomB = 1 - `tau' - `thetab'
                if abs(`denomB')>1e-10 {
                    local ZdenB = `beta' - (`thetab'*`gL' + `sl'*`qtil')/`denomB'
                    if abs(`ZdenB')>1e-10 {
                        local Zb = (1-`beta')*(`p_B'+`delta')/`ZdenB'
                        local EXb = ///
                            (1+`inflation')*((`p_B'+`delta') - `Zb'*`gL') ///
                            + `inflation' - (1+`inflation')*`delta' ///
                            - `debt'*`i'*(1-`tau') ///
                            - `gL'
                        if (`thetab'>0 & `EXb'>0) local valid_bind=1
                    }
                }
            }
        }

        ************************************************************
        * 4. REGIME SELECTION
        ************************************************************
        if (`valid_bind') {
            replace coc_cft   = `p_B' in `= `taxrate'+1'
            replace binds_cft = 1     in `= `taxrate'+1'
        }
        else {
            replace coc_cft   = `p_NB' in `= `taxrate'+1'
            replace binds_cft = 0      in `= `taxrate'+1'
        }
    }

    ************************************************************
    * METR
    ************************************************************
    gen double metr_cft  = 100*(coc_cft - `realint')/abs(coc_cft)
    gen double metr2_cft = 100*(coc_cft - `realint')/abs(`realint')
    replace coc_cft = 100*coc_cft

    keep if t<=50
    rename t statutory_tax_rate
    keep coc* statutory_tax_rate metr* binds_cft

    format coc* metr* %9.3f
    tempfile metr
    save `metr', replace
}





*=============================
*** ace
*=============================

if "`system'"=="ace" {

    gen double coc_ace_qrtc   = .
    gen double coc_ace_nqrtc  = .
    gen byte   binds_ace_qrtc = .
    gen byte   binds_ace_nqrtc = .

    * Carve-out parameters (same for capital and labor here)
    local gK = `carveout'
    local gL = `carveout'

    ****************************************************
    * NPV of tax depreciation (Anpv)
    ****************************************************
    if "`deprtype'"=="db" {
		local  Anpv = `depreciation'*(1+`i')/(`depreciation'+`i')
	}

	if "`deprtype'"=="sl" {
    replace Anpv = (`depreciation'*(1+`i')/`i')*(1 - 1/((1+`i')^(1/`depreciation'))) 
    }

    forvalues taxrate = 0/50 {

        local tau = `taxrate'/100

        ****************************************************
        * 0. Base: no-top-up cost of capital under ace
        *    => p0 = real interest rate
        ****************************************************
        local p0 = `realint'							// This is the cost of capital (with no top-up) for ace as long as there are no addional tax credits on top of the ace. 

        ****************************************************
        * Common ace uplift (per unit of K), independent of p:
        * U = τ (1+π)(r+δ)(1 - Anpv)
        ****************************************************
        local U0 = `tau'*(1+`inflation')*(`realint'+`delta')*(1-`Anpv')

        ****************************************************
        * --------- ace TREATED AS QRTC ---------
        ****************************************************

        * 1. X0, D0, xi0, GloBE ETR at p0
        *    QRTC case: uplift enters D0 as +U0
        local X0q = (1+`inflation')*(`p0'+`delta') ///
                    + `inflation' - (1+`inflation')*`delta'

        local D0q = `X0q' - `debt'*`i'*(1-`tau'*`depreciation') + `U0'
        local xi0q = `X0q'/`D0q'

        * GloBE ETR and top-up at p0
        local globe_ETR0q = `tau'*max(`xi0q',0)
        local theta0q     = `minrate' - `tau'*max(`xi0q',0)
        local denom10q    = 1 - `tau' - `theta0q'

        * 2B. Z0_q(p0) — Cobb–Douglas labor–capital ratio
        local Zden0q = `beta' - ( `theta0q'*`gL' )/`denom10q'
        local Z0q    = (1-`beta')*(`p0'+`delta') / `Zden0q'

        * 3. Excess profit at p0 (EX0_q)
        local EX0q = ///
            (1+`inflation')*((`p0'+`delta') - `Z0q'*`carveout') ///
            + `inflation' - (1+`inflation')*`delta' ///
            - `debt'*`i'*(1-`tau'*`depreciation') ///
            - `carveout' ///
            + `U0'

        * 4. BINDING RULE (QRTC):
        *       (i) globe_ETR0q < minrate
        *      (ii) EX0q > 0
        if (`globe_ETR0q' >= `minrate' | `EX0q' <= 0) {
            replace coc_ace_qrtc   = `p0' in `= `taxrate'+1'
            replace binds_ace_qrtc = 0    in `= `taxrate'+1'
        }
        else {

            ************************************************
            * 5. BINDING CASE → ITERATIVE SOLUTION (QRTC)
            ************************************************
            local p        = `p0'
            local tol      = 1e-8
            local max_iter = 500
            local iter     = 0
            local have_prev = 0
            local p_prev   = `p'
            local f_prev   = .
            local step_cap = 0.5

            while (`iter' < `max_iter') {

                ********************************************
                * 5A. X, D, xi, theta, denom1  (QRTC)
                ********************************************
                local X = (1+`inflation')*(`p'+`delta') ///
                          + `inflation' - (1+`inflation')*`delta'

                local D = `X' - `debt'*`i'*(1-`tau'*`depreciation') + `U0'
                local xi = `X'/`D'
                local theta  = `minrate' - `tau'*max(`xi',0)
                local denom1 = 1 - `tau' - `theta'

                ********************************************
                * 5B. Z(p)  (QRTC)
                ********************************************
                local Zden = `beta' - (`theta'*`gL')/`denom1'
                local Z    = (1-`beta')*(`p'+`delta') / `Zden'

                ********************************************
                * 5D. G(p) for ace as QRTC
                *     from CoC formula:
                *     p = [ (r+δ)
                *            - τ i(1-τφ)/(1+π)
                *            + θ( τ(r+δ)(1-Anpv)
                *                  + π/(1+π)
                *                  - δ
                *                  - i(1-τφ)/(1+π)
                *                  - γK(1-φ)/(1+π)
                *                  - γL Z )
                *           ] / (1-τ-θ) - δ
                ********************************************
                local Gnum = (`realint' + `delta')*(1-`tau') ///
                              + `theta'*( ///
                                  `tau'*(`realint'+`delta')*(1-`Anpv') ///
                                + `inflation'/(1+`inflation') ///
                                - `delta' ///
                       - `debt'*`i'*(1-`tau'*`depreciation')/(1+`inflation') ///
                                - `gK'/(1+`inflation') ///
                                - `gL'*`Z' ///
                              )

                ********************************************
                * 5E. Fixed point: f(p) = RHS(p) − p
                ********************************************
                local RHS = (`Gnum'/`denom1') - `delta'
                local f   = `RHS' - `p'

                if abs(`f') < `tol' {
                    replace coc_ace_qrtc   = `p' in `= `taxrate'+1'
                    replace binds_ace_qrtc = 1   in `= `taxrate'+1'
                    continue, break
                }

                ********************************************
                * 5F. Secant + damping (QRTC)
                ********************************************
                if `have_prev' {
                    local denom_sec = `f' - `f_prev'
                    if abs(`denom_sec') > 1e-10 {
                        local p_new = `p' - `f'*(`p' - `p_prev')/`denom_sec'
                    }
                    else local p_new = (`p'+`p_prev')/2

                    if (`f'*`f_prev' < 0) local p_new = (`p'+`p_prev')/2
                }
                else {
                    local p_new = `p' - 0.1*`f'/(1+abs(`f'))
                }

                local scale = max(1e-6, max(abs(`p'), abs(`p_prev')))
                if abs(`p_new' - `p') > `step_cap'*`scale' {
                    local p_new = `p' + sign(`p_new' - `p')*`step_cap'*`scale'
                }

                if (`p_new'<-0.25) local p_new = -0.25
                if (`p_new'>0.50)  local p_new =  0.50

                local p_prev    = `p'
                local f_prev    = `f'
                local p         = `p_new'
                local have_prev = 1
                local iter      = `iter' + 1
            }

            if (`iter' == `max_iter') {
                di as error "WARNING: no convergence at tau=`taxrate'% (ace, QRTC)"
                replace coc_ace_qrtc   = `p' in `= `taxrate'+1'
                replace binds_ace_qrtc = 1   in `= `taxrate'+1'
            }
        }   // end binding QRTC case


        ****************************************************
        * --------- ace TREATED AS NQRTC ---------
        ****************************************************

        * 1. X0, D0, xi0, GloBE ETR at p0 (NQRTC)
        *    X0n = X0q - U0; D0n excludes uplift
        local X0n = `X0q' 
        local D0n =`X0q' - `debt'*`i'*(1-`tau'*`depreciation')

        local xi0n = `X0n'/`D0n'

        * For NQRTC: uplift acts like mu in the GloBE ETR:
        * globe_ETR0 = τ ξ0n - U0/D0n
        local globe_ETR0n = max(`tau'*`xi0n',0)- `U0'/`D0n'
        local theta0n     = `minrate' - max(`tau'*`xi0n',0) +  `U0'/`D0n' 
        local denom10n    = 1 - `tau' - `theta0n'

        * 2B. Z0_n(p0) — NQRTC Z does not depend on θ
        local Zden0n = `beta' - ( (`minrate' - `tau'*max(`xi0n',0))*`gL' )/(1-`tau'-(`minrate'-`tau'*max(`xi0n',0)))
        local Z0n    = (1-`beta')*(`p0'+`delta') / `Zden0n'

        * 3. Excess profit at p0 (NQRTC, no +U0 term)
        local EX0n = ///
            (1+`inflation')*((`p0'+`delta') - `Z0n'*`carveout') ///
            + `inflation' - (1+`inflation')*`delta' ///
            - `debt'*`i'*(1-`tau'*`depreciation') ///
            - `carveout'

        * 4. BINDING RULE (NQRTC)
        if (`globe_ETR0n' >= `minrate' | `EX0n' <= 0) {
            replace coc_ace_nqrtc   = `p0' in `= `taxrate'+1'
            replace binds_ace_nqrtc = 0    in `= `taxrate'+1'
        }
        else {

            ************************************************
            * 5. BINDING CASE → ITERATIVE SOLUTION (NQRTC)
            ************************************************
            local p        = `p0'
            local tol      = 1e-8
            local max_iter = 500
            local iter     = 0
            local have_prev = 0
            local p_prev   = `p'
            local f_prev   = .
            local step_cap = 0.5

            while (`iter' < `max_iter') {

                ********************************************
                * 5A. X, D, xi, theta, denom1 (NQRTC)
                ********************************************
                local Xb = (1+`inflation')*(`p'+`delta') ///
                           + `inflation' - (1+`inflation')*`delta'

                local X = `Xb' 
                local D = `Xb' - `debt'*`i'*(1-`tau'*`depreciation')

                local xi = `X'/`D'
                local theta  = `minrate' - `tau'*max(`xi',0) + `U0'/`D'
                local denom1 = 1 - `tau' - `theta'

                ********************************************
                * 5B. Z(p) (NQRTC)
                ********************************************
                local Zden = `beta' - ( (`minrate' - `tau'*max(`xi',0))*`gL' )/(1--`tau'-(`minrate'-`tau'*max(`xi',0)))
                local Z    = (1-`beta')*(`p'+`delta') / `Zden'

                ********************************************
                * 5D. G(p) for ace as NQRTC
                *     p = [ (r+δ)
                *            - τ i(1-τφ)/(1+π)
                *            + θ( π/(1+π)
                *                  - δ
                *                  - i(1-τφ)/(1+π)
                *                  - γK(1-φ)/(1+π)
                *                  - γL Z )
                *           ] / (1-τ-θ) - δ
                ********************************************
                local Gnum = (`realint' + `delta')*(1-`tau') ///
                              + `theta'*(`inflation'/(1+`inflation') ///
                                - `delta' ///
                       - `debt'*`i'*(1-`tau'*`depreciation')/(1+`inflation') ///
                       - `gK'/(1+`inflation') - `gL'*`Z' )

                ********************************************
                * 5E. Fixed point: f(p) = RHS(p) − p
                ********************************************
                local RHS = (`Gnum'/`denom1') - `delta'
                local f   = `RHS' - `p'

                if abs(`f') < `tol' {
                    replace coc_ace_nqrtc   = `p' in `= `taxrate'+1'
                    replace binds_ace_nqrtc = 1   in `= `taxrate'+1'
                    continue, break
                }

                ********************************************
                * 5F. Secant + damping (NQRTC)
                ********************************************
                if `have_prev' {
                    local denom_sec = `f' - `f_prev'
                    if abs(`denom_sec') > 1e-10 {
                        local p_new = `p' - `f'*(`p' - `p_prev')/`denom_sec'
                    }
                    else local p_new = (`p'+`p_prev')/2

                    if (`f'*`f_prev' < 0) local p_new = (`p'+`p_prev')/2
                }
                else {
                    local p_new = `p' - 0.1*`f'/(1+abs(`f'))
                }

                local scale = max(1e-6, max(abs(`p'), abs(`p_prev')))
                if abs(`p_new' - `p') > `step_cap'*`scale' {
                    local p_new = `p' + sign(`p_new' - `p')*`step_cap'*`scale'
                }

                if (`p_new'<-0.25) local p_new = -0.25
                if (`p_new'>0.50)  local p_new =  0.50

                local p_prev    = `p'
                local f_prev    = `f'
                local p         = `p_new'
                local have_prev = 1
                local iter      = `iter' + 1
            }

            if (`iter' == `max_iter') {
                di as error "WARNING: no convergence at tau=`taxrate'% (ace, NQRTC)"
                replace coc_ace_nqrtc   = `p' in `= `taxrate'+1'
                replace binds_ace_nqrtc = 1   in `= `taxrate'+1'
            }
        }   // end binding NQRTC case

    }   // end loop over taxrate

    ****************************************************
    * metrs under ace (QRTC and NQRTC)
    ****************************************************
    gen double metr_ace_qrtc   = 100*(coc_ace_qrtc- `realint')/abs(coc_ace_qrtc)
	gen double metr2_ace_qrtc   = 100*(coc_ace_qrtc- `realint')/abs(`realint')

    gen double metr_ace_nqrtc  = 100*(coc_ace_nqrtc - `realint')/abs(coc_ace_nqrtc)
    gen double metr2_ace_nqrtc  = 100*(coc_ace_nqrtc - `realint')/abs( `realint')

 
    replace coc_ace_qrtc = 100*coc_ace_qrtc
    replace coc_ace_nqrtc = 100*coc_ace_nqrtc

    keep if t<=50
    rename t statutory_tax_rate
    keep coc* statutory_tax_rate metr*

    format coc*  %9.3f
    format metr* %9.3f
	
	tempfile metr
	save `metr', replace
}


}																				// 

if "`minimumtax'"=="no" {
	use `pre_globe', clear
}

if "`minimumtax'"=="yes" {
	use `metr', clear
	merge 1:1 statutory_tax_rate using `aetr'
	drop	_m
	
	keep statutory_tax_rate aetr* metr* coc*
	
	if "`system'"=="cit"  {
		rename (aetr_cit coc_cit metr_cit metr2_cit)	(aetr coc metr metr2)
		
	}
	
	if "`system'"=="cft"  {
		rename (aetr_cft coc_cft metr_cft metr2_cft)	(aetr coc metr metr2)
		
	}
	
	if "`system'"=="ace"  {
	rename (aetr_ace_qrtc coc_ace_qrtc metr_ace_qrtc metr2_ace_qrtc aetr_ace_nqrtc coc_ace_nqrtc metr_ace_nqrtc metr2_ace_nqrtc )	(aetr_qrtc coc_qrtc metr_qrtc metr2_qrtc aetr_nqrtc coc_nqrtc metr_nqrtc metr2_nqrtc)
		
	}
	
}


}																				// closes the "quitely" bracket



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
matrix parameters[8, 1] = 100*`carveout'
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
							"Carveout (%)" "QRTC (%)" "NQRTC (%)" ///
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

tempfile paramtxt
qui {
esttab matrix(parameters) using "`paramtxt'", replace ///
    cells("b")  noabbrev varwidth(30) noobs nonumber ///
	eqlabels(none) mlabels(,none) collabels("Parameters") ///
	alignment(c) gaps nolines  nolines  ///
	addnotes("`depr_text'" "`refund_text'" "`minimumtax_text'") 
}

type "`paramtxt'"
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

tempfile paramtxt
qui {
	
esttab matrix(parameters) using "`paramtxt'", replace ///
    cells("b")  noabbrev varwidth(30) noobs nonumber ///
	eqlabels(none) mlabels(,none) collabels("Parameters") ///
	alignment(c) gaps nolines  nolines  ///
	addnotes("`depr_text'" "`refund_text'" "`minimumtax_text'") 
}

type "`paramtxt'"
}

end