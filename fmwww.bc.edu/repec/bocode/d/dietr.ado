/******************************************************************************* 
Title: 			ETR model ado file
Author: 		Andualem Mengistu & Shafik Hebous
Email:			amengistu2@imf.org
Date created: 	October 11, 2024
Description:	Master file for running the METR and AETR simulation
Version:		0.1.0
*******************************************************************************/	
capture program drop dietr
program define dietr
version 15
    set type double

    // Declare the syntax to accept any type of variable (numeric or string) and fallback parameter values
    syntax , id(varlist) taxrate(varlist numeric) inflation(varlist numeric) ///
        depreciation(varlist numeric) delta(varlist numeric) deprtype(varlist string) ///
        [realint(varlist numeric) debt(varlist numeric) newequity(varlist numeric) holiday(varlist numeric)  ///
		pitdiv(varlist numeric)  pitint(varlist numeric)  pitcgain(varlist numeric) ///
		qrtc(real 0) nqrtc(real 0) sbie(real 1.5) minrate(real 0.15) p(real 0.1) ///
        system(string) minimumtax(string) refund(string)]
		
		
**Note
*The following varibales are required: id(varlist) taxrate(varlist numeric) inflation(varlist numeric) depreciation (varlist numeric) delta (varlist numeric) deprtyp(varlist numeric). One can assign any variable as id, any numerical variable as taxrate, etc. 
*The following are optional variables: realint(varlist numeric) debt(varlist numeric) newequity(varlist numeric) holiday(varlist numeric).
*The following are parameters:  qrtc(real 0) nqrtc(real 0) sbie(real 150) minrate(real 0.15) p(real 0.1) system(string) minimumtax(string) refund(string)


*======= Validate variables=========================
    // Check if the `id` variable exists in the dataset
    capture confirm variable `id'
    if _rc != 0 {
        display "Error: The specified variable `id' does not exist in the dataset."
        exit 1
    }

    // Determine the type of the variable `id`
    local type : type `id'

    // General handling for both string and numeric variables
    if regexm("`type'", "^str") {
        encode `id', gen(id_e)
        display "The string variable `id' has been encoded as 'id_e' from 1 to N."
    }
    else if regexm("`type'", "^(int|long|byte|float|double)$") {
        quietly egen id_e = group(`id')
        display "The numeric variable `id' has been encoded as 'id_e' from 1 to N."
    }
    else {
        display "Error: The variable `id' must be either string or numeric."
        exit 1
    }

*=========Assigning default values for optional variables (realint, debt, holiday)
    // Real interest rate
	if "`realint'" == "" {
        local r 0.05
        display "Optional variable 'realint' not provided; using default value: `realint'"
    }
    else {
        capture confirm variable `realint'
        if _rc == 0 {
            local r `realint'
            display "Using variable for r: `r'"
            if `r' < 0.01 | `r' > 0.2 {
                display "The specified real interest rate value is out of the acceptable range. Acceptable range is 0.01 to 0.2."
                exit 125
            }
        }
        else {
            local r 0.05
            display "Variable 'realint' does not exist; using default value: `r'"
        }
    }

    // Debt (Share of finance)
    if "`debt'" == "" {
        local debt_v 0
        display "Optional variable 'debt' not provided; using default value: `debt_v'"
    }
    else {
        capture confirm variable `debt'
        if _rc == 0 {
            local debt_v `debt'
            display "Using variable for debt: `debt'"
            if `debt_v' < 0 | `debt_v' > 1 {
                display "The specified debt financing ratio is out of the acceptable range. Acceptable range is 0 to 1."
                exit 125
            }
        }
        else {
            local debt_v 0
            display "Variable 'debt' does not exist; using default value: `debt_v'"
        }
    }

	
	// New Eqity (share of finance)
    if "`newequity'" == "" {
        local newequity_v 0
        display "Optional variable 'newequity' not provided; using default value: `newequity_v'"
    }
    else {
        capture confirm variable `newequity'
        if _rc == 0 {
            local newequity_v `newequity'
            display "Using variable for new equity: `newequity'"
            if `newequity_v' < 0 | `newequity_v' > 1 {
                display "The specified new equity financing ratio is out of the acceptable range. Acceptable range is 0 to 1."
                exit 125
            }
        }
        else {
            local newequity_v 0
            display "Variable 'newequity' does not exist; using default value: `newequity_v'"
        }
    }
	
**Limiting the total share of debt and equity finance	
	if  `newequity_v'+ `debt_v' >1 {
		display "The share of new equity and debt finance can not exceed 100%."
		exit 125
	}
	
	
    // Tax holiday
    if "`holiday'" == "" {
        local holiday_v 0
        display "Optional variable 'holiday' not provided; using default value: `holiday_v'"
    }
    else {
        capture confirm variable `holiday'
        if _rc == 0 {
            local holiday_v `holiday'
            display "Using variable for holiday: `holiday'"
            if `holiday_v' < 0 | `holiday_v'> 100 {
                display "The specified tax holiday period is out of the acceptable range. Acceptable range is 0 to 100."
                exit 125
            }
        }
        else {
            local holiday_v 0
            display "Variable 'holiday' does not exist; using default value: `holiday_v'"
        }
    }
	
// Witholding rate on dividends

foreach var in pitdiv pitint  pitcgain {

	if "`var'" == "" {
        local `var'_v 0
        display "Optional variable '`var'' not provided; using default value: ``var'_v'"
    }
    else {
        capture confirm variable `var'
        if _rc == 0 {
            local `var'_v `var'
            display "Using variable for `var': `var'"
        }
        else {
            local `var'_v 0
            display "Optional variable '`var'' does not exist; using default value: ``var'_v'"
        }
    }
}	
		

// Default values for string parameters
    if "`system'" == "" {
        local system "cit"
    }
    if "`minimumtax'" == "" {
        local minimumtax "no"
    }

    if "`refund'" == "" {
        local refund "yes"
    }

    local profit = `p'

    // Parameter validation
    if `p' < 0 | `p' > 1 {
        display "The specified profitability value is out of the acceptable range. Acceptable range is 0 to 1"
        exit 125
    }

    if `qrtc' < 0 | `qrtc' > 0.2 {
        display "The specified QRTC parameter is out of the acceptable range. Acceptable range is 0 to 0.2"
        exit 125
    }
    if `nqrtc' < 0 | `nqrtc' > 0.2 {
        display "The specified NQRTC parameter is out of the acceptable range. Acceptable range is 0 to 0.2"
        exit 125
    }
    if `sbie' < 0 | `sbie' > 2 {
        display "The specified SBIE parameter is out of the acceptable range. Acceptable range is 0 to 2"
        exit 125
    }

    local profit = `p'

    quietly {    
        // Create a temporary dataset to store results
        // Generate t (0 to 199) for 200 periods
        expand 100
        by id_e, sort: gen t = _n - 1

        // Calculate necessary variables
        gen i = `r' + `inflation' + `r' * `inflation'
        		
		// Parameters based on the intereaction of PIT and CIT
		gen 	gamma=(1- `pitdiv_v')/(1-`pitcgain_v')										//((1-m_d))/((1-z)(1-c))=γ
		gen 	rho=(1- `pitint_v')*i/(1-`pitcgain_v')										//(1-m_i )i/((1-z))=ρ

		gen		A_decline=`depreciation'*(1+rho)/(`depreciation'+ rho)								// present value of depreciation (declining balance), accounting for PIT
		gen		A_straight=`depreciation'*((1+rho)/rho)*(1-(1/((1+rho)^(1/`depreciation'))))		// present value of depreciation (straight line), accounting for PIT

		
		
        // Calculate SBIE based on depreciation method
        gen double SBIE = 0
        
		replace SBIE = 0.05 * (`sbie') * (1 - `depreciation')^t  if `deprtype'=="db"
		// Substance based income exclusion is 5% of capital and payroll. If missing, we use 150% as the tangible asset=tax depreciated value of the asset. 
		//payroll is half of tagible asst. 5%*1.5*(1-phi)^t=7.5%*(1-phi)^t        
		
        replace SBIE = 0.05 * (`sbie') * max((1 - t *`depreciation'), 0)  if `deprtype'=="sl"
		la var 		SBIE "Substance based income exclusion under declining balance depreciation"

        // Calculate QRTC and NQRTC
        gen			QRTC = 0
        replace		QRTC = (`qrtc' / 100) * (1 - `delta')^t if t >= 1
        gen			NQRTC = 0
        replace		NQRTC = (`nqrtc' / 100) * (1 - `delta')^t if t >= 1

        tempfile generalparameter
        save `generalparameter', replace


************************************************
        // Calculate profit and taxes
if "`refund'"=="yes" {
     
		gen 		double 		revenue=0 				 												
		by id_e, sort: replace	revenue=0	 													if t==0 	// revenue in period 0 
		by id_e, sort: replace	revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
		by id_e, sort: gen  	double		revenue_time=revenue/((1 + rho) ^ t)										// discounted value of revenue
		by id_e, sort: egen 	double 		revenue_NPV= total(revenue_time)											// NPV of revenue
		
***Standard CIT	

if "`system'"=="cit" {
       preserve
				gen double profit_cit = 0
				
				**Delclining balance
				by id_e, sort: replace profit_cit = -`depreciation' if t == 0  &  `deprtype'=="db" 
                by id_e, sort: replace profit_cit = (`p' + `delta') * ((1 + `inflation')^t) * (1 - `delta')^(t - 1) - `depreciation' * (1 - `depreciation')^t - `debt_v' * i * ((1 + `inflation') * (1 - `delta'))^(t - 1) if t > 0   &  `deprtype'=="db"
								
				 **Straight line
                by id_e, sort: replace profit_cit = -`depreciation' if t == 0 & `deprtype'=="sl"
                by id_e, sort: replace profit_cit = (`p' + `delta') * ((1 + `inflation')^t) * (1 - `delta')^(t - 1) - min(max(1 - t * `depreciation', 0), `depreciation') - `debt_v' * i * ((1 + `inflation') * (1 - `delta'))^(t - 1) if t > 0 &  `deprtype'=="sl"
                

            // Calculate tax and AETR
            gen double Tax_cit = 0
			by id_e, sort: replace 	Tax_cit = (`taxrate') * profit_cit - QRTC - min(max(`taxrate'*profit_cit, 0), NQRTC) if  `holiday_v'==0
            by id_e, sort: replace 	Tax_cit = -QRTC if t<=`holiday_v' &  `holiday_v'>0
            by id_e, sort: replace 	Tax_cit = (`taxrate') * profit_cit - QRTC - min(max(`taxrate'*profit_cit, 0), NQRTC) if t > `holiday_v' & `holiday_v'>0
          
			by id_e, sort: gen 		double Tax_cit_time = Tax_cit / ((1 + rho)^t)
            by id_e, sort: egen 	double Tax_cit_NPV = total(Tax_cit_time)
            
			tempfile 	cit_pregoble												// This will be used later to generate the AETR for the case where there is a top-up tax
			save 		`cit_pregoble'
	
			by id_e, sort: gen		econrent_cit=gamma*(revenue_NPV-1-Tax_cit_NPV)+ `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/( rho-`inflation'+`delta'*(1+`inflation')) 

			by id_e, sort: gen			double 		AETR_CIT=100*((`p'-`r')/(`r'+`delta')-econrent_cit)/(`p'/(`r'+`delta'))

					
            drop  t i gamma rho  SBIE A_decline A_straight NQRTC QRTC revenue revenue_*   profit_*  Tax_* econrent_*
		    duplicates drop 

            la var AETR_CIT "AETR of a standard CIT (%)"
            format AETR* %9.02f
            tempfile pre_globe
            save `pre_globe.dta', replace
			
	restore
        }

***R-based cashflow tax	
	
if "`system'"=="cft"  {

preserve
		gen double 				profit_cft = 0
		by id_e, sort: replace	profit_cft=-1	  														if t==0									// period 0 taxable income
		by id_e, sort: replace	profit_cft=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)			if t>=1
		la var 					profit_cft  "profit under a refundable cahsflow tax"
	
		gen  		double		Tax_cft=0
		replace					Tax_cft=(`taxrate') * profit_cft -QRTC-min(max(`taxrate'*profit_cft,0),NQRTC)	if `holiday_v'==0		
		// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))
		replace					Tax_cft=-QRTC	if t<=`holiday_v'	& `holiday_v'>0		
		replace					Tax_cft=(`taxrate') * profit_cft -QRTC-min(max(`taxrate'*profit_cft,0),NQRTC)	if t>`holiday_v' & `holiday_v'>0		
		
		by id_e, sort: gen  	double 		Tax_cft_time= Tax_cft/((1 + rho) ^ t)								// The discounted value of each peruiod's tax liability
		by id_e, sort: egen 	double		Tax_cft_NPV= total(Tax_cft_time)									// NPV of the the sum of taxes paid
	
		tempfile 	cft_pregoble												// This will be used later to generate the AETR for the case where there is a top-up tax
		save 		`cft_pregoble'
	
	
		by id_e, sort: gen		econrent_cft=gamma*(revenue_NPV-1-Tax_cft_NPV)+ `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/( rho-`inflation'+`delta'*(1+`inflation')) 

		by id_e, sort: gen			double 		AETR_CFT=100*((`p'-`r')/(`r'+`delta')-econrent_cft)/(`p'/(`r'+`delta'))
	
        drop t i gamma  rho  SBIE A_decline A_straight NQRTC QRTC revenue revenue_*  profit_*  Tax_* econrent_*
        duplicates drop 

		la var 		AETR_CFT 				"AETR of an R-based cash flow tax (%)"

		format 		AETR* %9.02f
		tempfile  	pre_globe
		save 	 	`pre_globe.dta', replace
	restore
 }		

 
***ACE
if "`system'"=="ace" 	{	

		preserve
		
			gen 		double		profit_ace=0
																							
**Declining balance
			by id_e, sort: replace	profit_ace=-`depreciation'			if t==0		& 	`deprtype'=="db" 																		//taxable income in period 0
			by id_e, sort: replace	profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-i*(1-`depreciation')^t   if t>0 & 	`deprtype'=="db" 

**Straight line
			by id_e, sort: replace	profit_ace=-`depreciation'				if t==0	& 	`deprtype'=="sl" 																			//taxable income in period 0
			by id_e, sort: replace	profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-i*max((1-t*`depreciation'),0)   if t>0 & 	`deprtype'=="sl" 
				
			la 			var 		profit_ace "profit under a refundable ACE"

		gen  		double		Tax_ace=0
		by id_e, sort: replace	Tax_ace=(`taxrate')*profit_ace -QRTC-min(max(`taxrate'*profit_ace,0),NQRTC)	if `holiday_v'==0		
		// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))
		by id_e, sort: replace	Tax_ace=-QRTC	if  t<=`holiday_v' & `holiday_v'>0		// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))
		by id_e, sort: replace	Tax_ace=(`taxrate') * profit_ace -QRTC-min(max(`taxrate'*profit_ace,0),NQRTC)	if t>`holiday_v' & `holiday_v'>0		
		
		by id_e, sort: gen  	double		Tax_ace_time= Tax_ace/((1 + rho) ^ t)									// The discounted value of each period's tax liability
		by id_e, sort: egen 	double		Tax_ace_NPV= total(Tax_ace_time)										// NPV of the the sum of taxes paid
		
		tempfile 	ace_pregoble												// This will be used later to generate the AETR for the case where there is a top-up tax
		save 		`ace_pregoble'
			
		by id_e, sort: gen		econrent_ace=gamma*(revenue_NPV-1-Tax_ace_NPV)+ `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/( rho-`inflation'+`delta'*(1+`inflation')) 

		by id_e, sort: gen			double 		AETR_ACE=100*((`p'-`r')/(`r'+`delta')-econrent_ace)/(`p'/(`r'+`delta'))
			
        drop  t i gamma rho  SBIE A_decline A_straight NQRTC QRTC revenue revenue_*   profit_*  Tax_* econrent_*
		duplicates drop 
		

		la var 		AETR_ACE 			"AETR of an ACE system (%)"
		format 		AETR* %9.02f
		tempfile  	pre_globe
		save 	 	`pre_globe.dta', replace
	restore	
 }		
}

  

if "`refund'" == "no" {
	
		gen 		double 		revenue=0 				 												
		by id_e, sort: replace	revenue=0	 													if t==0 	// revenue in period 0 
		by id_e, sort: replace	revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
		by id_e, sort: gen  	double		revenue_time=revenue/((1 + rho) ^ t)										// discounted value of revenue
		by id_e, sort: egen 	double 		revenue_NPV= total(revenue_time)	
	
	 if "`system'" == "cit" {
		preserve
		gen double profit_cit = 0

**Declining balance	
		by id_e, sort:	replace	 profit_cit=(`p'+`delta')*((1+`inflation'))-`depreciation'-`depreciation'*(1-`depreciation') -`debt_v'*i     if t==1 & 	`deprtype'=="db" 			// taxable income in period 1
		by id_e, sort:	replace	 profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit[_n-1])    if t>1		& 	`deprtype'=="db" 		// taxable income  after period 1
					
**Straight line					
        by id_e, sort: replace	profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt_v'*i		if t==1	& 	`deprtype'=="sl" 				
		// (including loss carryforward due to non-refundability)							
		by id_e, sort: replace	profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit[_n-1])    if t>1 	& 	`deprtype'=="sl" 	     // taxable income in periods after period 1
                					
		la var 					profit_cit  "profit under a refundable standard CIT."
		
        gen double Tax_cit = 0
        by id_e, sort: replace 		Tax_cit = (`taxrate') *max(profit_cit,0) - QRTC - min(max(`taxrate'*profit_cit, 0), NQRTC) if  `holiday_v'==0
        by id_e, sort: replace 		Tax_cit = -QRTC if  t <=`holiday_v' & `holiday_v'>0
        by id_e, sort: replace 		Tax_cit = (`taxrate') *max(profit_cit,0) - QRTC - min(max(`taxrate'*profit_cit, 0), NQRTC) if t >`holiday_v' & `holiday_v'>0
        by id_e, sort: gen 			double Tax_cit_time = Tax_cit / ((1 + rho)^t)
        by id_e, sort: egen 		double Tax_cit_NPV = total(Tax_cit_time)
       
	   	tempfile 	cit_pregoble												// This will be used later to generate the AETR for the case where there is a top-up tax
		save 		`cit_pregoble'
			
		by id_e, sort: gen		econrent_cit=gamma*(revenue_NPV-1-Tax_cit_NPV)+ `newequity_v'*(gamma-1)+ `debt_v'*gamma*(rho-i)/( rho-`inflation'+`delta'*(1+`inflation'))

		by id_e, sort: gen			double 		AETR_CIT=100*((`p'-`r')/(`r'+`delta')-econrent_cit)/(`p'/(`r'+`delta'))
	   
	    drop t i gamma  rho  SBIE A_decline A_straight NQRTC QRTC revenue revenue_*  profit_* Tax_*  econrent_*
		duplicates drop 

        la var AETR_CIT "AETR of a standard CIT (%)"
        format AETR* %9.02f
        tempfile pre_globe
        save `pre_globe.dta', replace
			
restore
}

***R-based cashflow tax	
if "`system'"=="cft"  {

preserve
		gen double profit_cft = 0
		by id_e, sort: replace	profit_cft=(`p'+`delta')*(1+`inflation')-1														if t==1
		by id_e, sort: replace	profit_cft=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1) +  min(0,profit_cft[_n-1])		if t>1
		la var 					profit_cft  "profit under a refundable cahsflow tax"
	
		gen  double				Tax_cft=0
		replace					Tax_cft=(`taxrate') * max(profit_cft,0) -QRTC-min(max(`taxrate'*profit_cft,0),NQRTC)	if `holiday_v'==0
		replace					Tax_cft=-QRTC	if  t<=`holiday_v' & `holiday_v'>0		
		replace					Tax_cft=(`taxrate') * max(profit_cft,0) -QRTC-min(max(`taxrate'*profit_cft,0),NQRTC)	if t>`holiday_v' & `holiday_v'>0		
		
		by id_e, sort: gen  	double 		Tax_cft_time= Tax_cft/((1 + rho) ^ t)								// The discounted value of each peruiod's tax liability
		by id_e, sort: egen 	double		Tax_cft_NPV= total(Tax_cft_time)									// NPV of the the sum of taxes paid
		
		tempfile 	cft_pregoble												// This will be used later to generate the AETR for the case where there is a top-up tax
		save 		`cft_pregoble'
		
		by id_e, sort: gen		econrent_cft=gamma*(revenue_NPV-1-Tax_cft_NPV)+ `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/( rho-`inflation'+`delta'*(1+`inflation'))

		by id_e, sort: gen			double 		AETR_CFT=100*((`p'-`r')/(`r'+`delta')-econrent_cft)/(`p'/(`r'+`delta'))
		
		
        drop t i gamma  rho  SBIE A_decline A_straight NQRTC QRTC revenue revenue_*  profit_* Tax_* econrent_*
 
		duplicates drop 
		

		la var 		AETR_CFT 				"AETR of an R-based cash flow tax (%)"

		format 		AETR* %9.02f
		tempfile  	pre_globe
		save 	 	`pre_globe.dta', replace
	restore
}		


***ACE
if "`system'"=="ace" 	{			
		preserve

		gen 		double		profit_ace=0																					
		
**Declining balance

		by id_e, sort: replace	profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-i*(1-`depreciation')^t  		if t==1	& 	`deprtype'=="db" 			//taxable income in period 1
		by id_e, sort: replace	profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-i*(1-`depreciation')^t +  min(0,profit_ace[_n-1])  if t>1 & 	`deprtype'=="db" 
		
**Straight line		
	by id_e, sort: replace	profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-i*(1-`depreciation')		if t==1	& 	`deprtype'=="sl" 							//taxable income in period 1
	by id_e, sort: replace	profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-i*max((1-t*`depreciation'),0) +  min(0,profit_ace[_n-1])    if t>1 & 	`deprtype'=="sl"  
	
		la 			var 		profit_ace "profit under a refundable ACE"
	 
		gen  		double		Tax_ace=0
		by id_e, sort: replace	Tax_ace=(`taxrate')*max(profit_ace,0) -QRTC-min((`taxrate')*max(profit_ace,0),NQRTC)	if `holiday_v'==0
		by id_e, sort: replace	Tax_ace=-QRTC	if  t<=`holiday_v' & `holiday_v'>0		
		by id_e, sort: replace	Tax_ace=(`taxrate')*max(profit_ace,0) -QRTC-min((`taxrate')*max(profit_ace,0),NQRTC)	if t>`holiday_v' & `holiday_v'>0
		
		by id_e, sort: gen  	double		Tax_ace_time= Tax_ace/((1 + rho) ^ t)									// The discounted value of each period's tax liability
		by id_e, sort: egen 	double		Tax_ace_NPV= total(Tax_ace_time)										// NPV of the the sum of taxes paid
		
		tempfile 	ace_pregoble												// This will be used later to generate the AETR for the case where there is a top-up tax
		save 		`ace_pregoble'
			
				
		by id_e, sort: gen		econrent_ace=gamma*(revenue_NPV-1-Tax_ace_NPV)+ `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/( rho-`inflation'+`delta'*(1+`inflation')) 

		by id_e, sort: gen		double 		AETR_ACE=100*((`p'-`r')/(`r'+`delta')-econrent_ace)/(`p'/(`r'+`delta'))
		
        drop t i gamma  rho  SBIE A_decline A_straight NQRTC QRTC revenue revenue_*  profit_* Tax_* econrent_*
		 
		duplicates drop 
		

		la var 		AETR_ACE 			"AETR of an ACE system (%)"
		format 		AETR* %9.02f
		tempfile  	pre_globe
		save 	 	`pre_globe.dta', replace
	restore
}		
		
}																				// closes the non-refundable routine

if "`minimumtax'"=="no" {
use  	`pre_globe.dta', clear
format 		AETR* %9.02f
tempfile	aetr
save		`aetr', replace
}																				



/*=========================================================================================================================================================
										Section 2: Adding the effect of the GloBE rules
										
	In this section, we calculate AETR when there is a top-up tax
===========================================================================================================================================================*/

if "`minimumtax'"=="yes" {	

if "`refund'"=="yes" | "`refund'"=="no" {
if "`system'"=="cit" 	{
	
********Standard CIT 

	*Covered income
		gen 		double profit_cit_tpt=0										//the basis for covered tax
		gen 		double cov_profit_cit=0										//Covered income

**Declining balance
		by id_e, sort: replace	profit_cit_tpt=(`p'+`delta')*(1+ `inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt_v'*i  if t==1	& 	`deprtype'=="db" 				
		by id_e, sort: replace	profit_cit_tpt=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit_tpt[_n-1])  if t>1 & 	`deprtype'=="db" 
												// covered profit considered for the top-up tax
		by id_e, sort: replace	cov_profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt_v'*i +QRTC    if t==1 & 	`deprtype'=="db" 
		by id_e, sort: replace	cov_profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) +QRTC+ min(0,cov_profit_cit[_n-1])  if t>1 & 	`deprtype'=="db" 
		la var 	cov_profit_cit  "covered income of a standard CIT"

**Straight line		
		by id_e, sort: replace		profit_cit_tpt=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation') -`debt_v'*i  if t==1	& 	`deprtype'=="sl" 				
		by id_e, sort: replace		profit_cit_tpt=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit_tpt[_n-1])  if t>1  & 	`deprtype'=="sl" 

		by id_e, sort: replace		cov_profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt_v'*i +QRTC    if t==1 & 	`deprtype'=="sl" 
		by id_e, sort: replace		cov_profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) +QRTC+ min(0,cov_profit_cit[_n-1])  if t>1 & 	`deprtype'=="sl" 
		la var 		cov_profit_cit  "covered income of a standard CIT"
		
		*top-up tax base
		gen			double exprofit_cit=max(0,cov_profit_cit-SBIE)
		la var 		exprofit_cit  "Excess profit under stndard CIT and declining balance depreciation"
		
		*The top-up tax rate is 15% minus the GloBE effetive tax rate (i.e., covered tax divided by covered income). Note that in the absence of qualified refundable tax credit, then the ETr is similar to the statutory tax rate. Therefore, the top-up rate can be calaucltes as max(0, 15%-statutory tax rate).
		
		gen double					covtax_cit=0										// covered tax
		by id_e, sort: replace 		covtax_cit=`taxrate'*max(0,profit_cit_tpt)-min((`taxrate')*max(0,profit_cit_tpt),NQRTC) if `holiday_v'==0
		by id_e, sort: replace 		covtax_cit=`taxrate'*max(0,profit_cit_tpt)-min((`taxrate')*max(0,profit_cit_tpt),NQRTC) if t>`holiday_v' & `holiday_v'>0
	
		gen							tpr_cit=0
		by id_e, sort: replace		tpr_cit=max(0,`minrate'-(covtax_cit)/cov_profit_cit)  if 	cov_profit_cit>0			//the top-up tax in each period 
		la var 		tpr_cit "Top up tax rate under stanadrd CIT"
			
		*top-up tax amount
		by id_e, sort: gen	double 	tpt_cit=tpr_cit*exprofit_cit/(1+rho)^t			// top-up tax (discounted value) 
		by id_e, sort: egen double 	total_tpt_cit=total(tpt_cit)					// The NPV of top-up taxes paid
		
		merge 1:1 id_e t using `cit_pregoble' 									// This merges the taxes paid before the top-up
		drop _merge 
		
		by id_e, sort: gen		econrent_cit=gamma*(revenue_NPV-1-Tax_cit_NPV-total_tpt_cit)+ `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/( rho-`inflation'+`delta'*(1+`inflation'))
		by id_e, sort: gen			double 		AETR_CIT=100*((`p'-`r')/(`r'+`delta')-econrent_cit)/(`p'/(`r'+`delta'))
	
		la var		tpt_cit "top-up tax (discounted value)"
		la var 		total_tpt_cit "NPV of all top-up taxes paid: under the standard CIT"
		la var 		AETR_CIT "The average effective tax rate under the standard CIT"
		
		drop 	t i SBIE gamma rho revenue revenue_* A_decline A_straight NQRTC QRTC profit_* covtax_* tpr_* tpt_* total_tpt_* exprofit_* cov_profit_* Tax_* econrent_*
		duplicates drop 
		
		la var 		AETR_CIT 			"AETR of a standard CIT (%)"

		format 		AETR* %9.02f
	
}																				// refundor non-refund closed
																				// CIT closed

if "`system'"=="cft" 	{
	
********** R-based cashflow tax
	*Covered income (involves deduction of iterest since interest deduction is allowed under the GloBE rules)
	*profit_cft_tpt (i.e., the tax base based on which domestic tax is calcualted) (doesn't involve interest deduction)
	*Note that although the firms receives immediate expensing, from a GloBE persepctive, it is a timing issue. Therefore, the taxbase is calculated similar to the taxbase for standard CIT.
	
	gen 		double profit_cft_tpt=0	
	gen 		double cov_profit_cft=0		
	
**declining balance															
		by id_e, sort: replace	profit_cft_tpt=(`p'+`delta')*(1+ `inflation')-`depreciation'-`depreciation'*(1-`depreciation')  if t==1	 & 	`deprtype'=="db" 				
		by id_e, sort: replace	profit_cft_tpt=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t + min(0,profit_cft_tpt[_n-1])  if t>1 & 	`deprtype'=="db" 
												// covered profit considered for the top-up tax
		by id_e, sort: replace	cov_profit_cft=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt_v'*i +QRTC    if t==1 & 	`deprtype'=="db" 
		by id_e, sort: replace	cov_profit_cft=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) +QRTC+ min(0,cov_profit_cft[_n-1])  if t>1 & 	`deprtype'=="db" 
		la var 		cov_profit_cft  "covered tax of a refundable R"
		

**straight line
		by id_e,sort: replace		profit_cft_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')  if t==1  & 	`deprtype'=="sl"    // accounting for loss carryforward from period 0
		by id_e,sort: replace		profit_cft_tpt=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') + min(0,profit_cft_tpt[_n-1])  if t>1  & 	`deprtype'=="sl"  
***	
	by id_e,sort: replace		cov_profit_cft=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt_v'*i +QRTC    if t==1 & 	`deprtype'=="sl"							
	by id_e,sort: replace		cov_profit_cft=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')-`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + QRTC+ min(0,cov_profit_cft[_n-1]) +QRTC  if t>1   & 	`deprtype'=="sl" 
	la var 		cov_profit_cft  "covered tax of a refundable R"

	*top-up tax base (excessl profit)
		gen			double exprofit_cft=max(0,cov_profit_cft-SBIE)
		la var 		exprofit_cft  "Excess profit under R based cash flow tax"
		
		*The top-up tax rate is 15% minus the GloBE effetive tax rate (i.e., covered tax divided by covered income). Note that in the absence of qualified refundable tax credit, then the ETr is similar to the statutory tax rate. Therefore, the top-up rate can be calaucltes as max(0, 15%-statutory tax rate).
		
		gen double					covtax_cft=0										// covered tax
		by id_e, sort: replace 		covtax_cft=(`taxrate')*max(0,profit_cft_tpt)-min((`taxrate')*max(0,profit_cft_tpt),NQRTC) if `holiday_v'==0
		by id_e, sort: replace 		covtax_cft=(`taxrate')*max(0,profit_cft_tpt)-min((`taxrate')*max(0,profit_cft_tpt),NQRTC) if t>`holiday_v' & `holiday_v'>0
	
		gen							tpr_cft=0
		by id_e, sort: replace		tpr_cft=max(0,`minrate'-(covtax_cft)/cov_profit_cft)  if 	cov_profit_cft>0			//the top-up tax in each period 
		la var 		tpr_cft "Top up tax rate under R based cashflow tax"
			
		*top-up tax amount
		by id_e, sort: gen	double 	tpt_cft=tpr_cft*exprofit_cft/(1+rho)^t			// top-up tax (discounted value) 
		by id_e, sort: egen double 	total_tpt_cft=total(tpt_cft)					// The NPV of top-up taxes paid
	
		merge 1:1 id_e t using `cft_pregoble' 									// This merges the taxes paid before the top-up
		drop _merge 
		
		by id_e, sort: gen		econrent_cft=gamma*(revenue_NPV-1-Tax_cft_NPV-total_tpt_cft)+ `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/( rho-`inflation'+`delta'*(1+`inflation'))

		by id_e, sort: gen			double 		AETR_CFT=100*((`p'-`r')/(`r'+`delta')-econrent_cft)/(`p'/(`r'+`delta'))
	
		la var		tpt_cft "top-up tax (discounted value)"
		la var 		total_tpt_cft "NPV of all top-up taxes paid: under the standard CIT"
		
		drop 	t i SBIE gamma rho revenue revenue_* A_decline A_straight NQRTC QRTC profit_* covtax_* tpr_* tpt_* total_tpt_* exprofit_* cov_profit_* Tax_* econrent_*
		duplicates drop 
		
		la var 		AETR_CFT 			"AETR of an R-based cash flow tax (%)"
		format 		AETR* %9.02f
		
}																				// CFT closed 					
}																				// refund or no refund closed

if "`refund'"=="yes" & "`system'"=="ace"  {

*****We assume that refundable ACE is a QRTC. Hence considered GloBE income.

	*The taxbase for covered tax involves calculting accounting profit excluding the ACE credit (since ACE credit is considered covered income for GloBE purposes).
	gen 		double profit_ace_tpt=0
	gen 		double cov_profit_ace=0

**Declining balance
	by id_e, sort:	replace 	profit_ace_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation')   if t==1 & 	`deprtype'=="db" 
	by id_e, sort:	replace		profit_ace_tpt=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t  + min(0,profit_ace_tpt[_n-1])  if t>1 & 	`deprtype'=="db" 
	
	by id_e, sort:	replace		cov_profit_ace=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation') - `debt_v'*i + (`taxrate')*i*(1-`depreciation') + QRTC  if t==1 & 	`deprtype'=="db" 
	by id_e, sort:	replace		cov_profit_ace=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t - `debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + (`taxrate')*i*(1-`depreciation')^t + QRTC + min(0,cov_profit_ace[_n-1])  if t>1 & 	`deprtype'=="db" 

	
**Straight line
	by id_e, sort:	replace	 	profit_ace_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')  if t==1 & 	`deprtype'=="sl"
	by id_e, sort:	replace		profit_ace_tpt=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')  + min(0,profit_ace[_n-1])   if t>1 & 	`deprtype'=="sl"

	by id_e, sort:	replace		cov_profit_ace=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation') - `debt_v'*i + (`taxrate')*i*(1-`depreciation') + QRTC  if t==1 & 	`deprtype'=="sl"
	by id_e, sort:	replace		cov_profit_ace=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') - `debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + (`taxrate')*i*max(1-t*`depreciation',0) + QRTC + min(0,cov_profit_ace[_n-1])   if t>1 & 	`deprtype'=="sl"


	gen			double exprofit_ace=max(0,cov_profit_ace-SBIE)		  // Excess profit is GloBe income minus susbtance based income exclusion	
	
		
	gen double 					covtax_ace=0
	by id_e, sort:	replace 	covtax_ace=(`taxrate')*max(0,profit_ace_tpt)-min((`taxrate')*max(0,profit_ace_tpt),NQRTC) if `holiday_v'==0
	by id_e, sort:	replace 	covtax_ace=(`taxrate')*max(0,profit_ace_tpt)-min((`taxrate')*max(0,profit_ace_tpt),NQRTC) if t>`holiday_v' & `holiday_v'>0

	gen double 					tpr_ace=0
	by id_e, sort:	replace		tpr_ace=max(0,`minrate'-(covtax_ace)/cov_profit_ace)		if cov_profit_ace>0
	 // Note that the difference between the nominator and denominator is that the denomintor includes the tax credit as an income					
							

		by id_e, sort: gen 		double tpt_ace=tpr_ace*exprofit_ace/(1+i)^t			// top-up tax (discounted value) 
		by id_e, sort: egen 	double total_tpt_ace=total(tpt_ace)
	
		merge 1:1 id_e t using `ace_pregoble' 									// This merges the taxes paid before the top-up
		drop _merge 
		
		by id_e, sort: gen		econrent_ace=gamma*(revenue_NPV-1-Tax_ace_NPV-total_tpt_ace)+ `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/( rho-`inflation'+`delta'*(1+`inflation'))

		by id_e, sort: gen			double 		AETR_ACE=100*((`p'-`r')/(`r'+`delta')-econrent_ace)/(`p'/(`r'+`delta'))
	
		la var		tpt_ace "top-up tax (discounted value)"
		la var 		total_tpt_ace "NPV of all top-up taxes paid: under the ACE"
		
		drop 	t i SBIE gamma rho revenue revenue_* A_decline A_straight NQRTC QRTC profit_* covtax_* tpr_* tpt_* total_tpt_* exprofit_* cov_profit_* Tax_* econrent_*
		duplicates drop 
		

	la var 		AETR_ACE 			"AETR of an ACE system (%)"
	format 		AETR* %9.02f
}																					// closes refundable ace

if "`refund'"=="no" & "`system'"=="ace"  {
	
*ACE
	**We assume that refundable ACE is a NQRTC. Hence considered GloBE income.
	*************************

	gen 		double profit_ace_tpt=0
	gen 		double cov_profit_ace=0													//This is the tax base from which SBIE is deducted

	*The taxbase for covered tax involves calculting accounting profit including the ACE credit (since non refundable ACE credit is considered a reduction in covered tax for GloBE purposes).
**Declining balance
	by id_e, sort: replace 	profit_ace_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation') -i*(1-`depreciation')  if t==1 & 	`deprtype'=="db"
	by id_e, sort: replace	profit_ace_tpt=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t-i*(1-`depreciation')^t  + min(0,profit_ace_tpt[_n-1])  if t>1 & 	`deprtype'=="db"

***
	by id_e, sort: replace	cov_profit_ace=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation') - `debt_v'*i + QRTC  if t==1 & 	`deprtype'=="db"
	by id_e, sort: replace	cov_profit_ace=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t - `debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + QRTC + min(0,cov_profit_ace[_n-1])  if t>1 & 	`deprtype'=="db"

	
**straight line
	by id_e, sort: replace 	profit_ace_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')- `i'*max(1-`depreciation',0)   if t==1 & 	`deprtype'=="sl"
	by id_e, sort: replace	profit_ace_tpt=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')- `i'*max(1-t*`depreciation',0) + min(0,profit_ace_tpt[_n-1])   if t>1 & 	`deprtype'=="sl" 

***
	replace		cov_profit_ace=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation') - `debt_v'*`i'  + QRTC  if t==1 & 	`deprtype'=="sl"
	replace		cov_profit_ace`taxrate'=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`phi',0),`phi') - `debt_v'*`i'*((1+`inflation')*(1-`delta'))^(t-1) + QRTC + min(0,cov_profit_ace[_n-1])   if t>1 & 	`deprtype'=="sl"
	
	gen double  			covtax_ace=0
	by id_e, sort: replace 	covtax_ace=(`taxrate')*max(0,profit_ace_tpt)-min((`taxrate')*max(0,profit_ace_tpt),NQRTC) if `holiday_v'==0
	by id_e, sort: replace 	covtax_ace=(`taxrate')*max(0,profit_ace_tpt)-min((`taxrate')*max(0,profit_ace_tpt),NQRTC) if t>`holiday_v' & `holiday_v'>0
	
	gen	double				tpr_ace=0	
	by id_e, sort: replace	tpr_ace=max(0,`minrate'-(covtax_ace)/cov_profit_ace)		if cov_profit_ace>0

	gen			double exprofit_ace=max(0,cov_profit_ace-SBIE)		  // Excess profit is GloBe income minus susbtance based income exclusion	
	
		by id_e, sort: gen 		double tpt_ace=tpr_ace*exprofit_ace/(1+i)^t			// top-up tax (discounted value) 
		by id_e, sort: egen 	double total_tpt_ace=total(tpt_ace)

		merge 1:1 id_e t using `ace_pregoble' 									// This merges the taxes paid before the top-up
		drop _merge 
		
		by id_e, sort: gen		econrent_ace=gamma*(revenue_NPV-1-Tax_ace_NPV-total_tpt_ace)+ `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/( rho-`inflation'+`delta'*(1+`inflation'))

		by id_e, sort: gen			double 		AETR_ACE=100*((`p'-`r')/(`r'+`delta')-econrent_ace)/(`p'/(`r'+`delta'))
	
		la var		tpt_ace "top-up tax (discounted value)"
		la var 		total_tpt_ace "NPV of all top-up taxes paid: under the ACE"
		
		drop 	t i SBIE gamma rho revenue revenue_* A_decline A_straight NQRTC QRTC profit_* covtax_* tpr_* tpt_* total_tpt_* exprofit_* cov_profit_* Tax_* econrent_*
		duplicates drop 
		

	la var 		AETR_ACE 			"AETR of an ACE system (%)"
	format 		AETR* %9.02f
}																						// closes norefund ace																				
	

	format 		AETR* %9.02f
	tempfile	aetr
	save		`aetr', replace
}																				// closes minimum tax==yes				


*=================================================================
*Marginal effective tax rate
*=================================================================
use  `generalparameter', clear


if "`minimumtax'"=="no" &  "`refund'"=="yes" {
tempfile metr_norefund
save `metr_norefund', replace
*the cost of capital is the economic return that will result in a zero post-tax economic rent.Hence, (p-r)/(r+delta)-Tax_R_NPV=0
**First, the case of a refundable system


***standard CIT
if "`system'"=="cit" {

* Create a temporary file to store the original data

* Initialize necessary variables globally
gen double coc_cit = .  // Initialize variable for the cost of capital of a refundable CIT

* Define local parameters
local tolerance = 0.0001  // How close to zero we need to get economic rent
local max_iter = 1000       // Maximum number of iterations

* Get unique IDs
levelsof id_e, local(id_list)

* Create a temporary file to store results
tempfile cit_results
save `cit_results', emptyok  // Start with an empty file for results

* Loop through each ID
foreach id in `id_list' {
    * Load the original data copy for each ID
    use `metr_norefund', clear
    
    * Restrict data to the current id
    quietly keep if id == `id'
    
    * Set initial values
    local p = `r'	   // Initial guess for cost of capital
    local iter = 0    // Iteration counter

    * Initialize ptilde_cit for this specific id
    gen double coc_cit = . 

    * Begin the iterative process
    while `iter' < `max_iter' {
        * Calculate the economic rent based on the current value of p
		 
		gen 		double 		revenue=0 				 												
		replace			 		revenue=0	 													if t==0 	// revenue in period 0 
		replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
		gen  		double		revenue_time=revenue/((1 + rho) ^ t)										// discounted value of revenue
		egen 		double 		revenue_NPV= total(revenue_time)	
		 
		gen double 	profit_cit =0
       
	  **Declining balance
            replace 	 profit_cit =- `depreciation' if t==0 & `deprtype'=="db"
            replace		 profit_cit = (`p' + `delta') * ((1 + `inflation') ^ t) * ((1 - `delta') ^ (t - 1)) - `depreciation'*(1 - `depreciation') ^ t - `debt_v' *i*((1 + `inflation') * (1 - `delta')) ^ (t - 1)  if t >= 1 & `deprtype'=="db"
        

       *Straight line
           replace 		profit_cit = - `depreciation' if t==0 & `deprtype'=="sl"
           replace 		profit_cit = (`p' + `delta') * ((1 + `inflation') ^ t) * ((1 - `delta') ^ (t - 1)) - min(max(1 - t *`depreciation', 0), `depreciation') - `debt_v' * i * ((1 + `inflation') * (1 - `delta')) ^ (t - 1) if t >= 1 & `deprtype'=="sl"
        
		gen  		double		Tax_cit=0
		replace					Tax_cit =(`taxrate') * profit_cit -QRTC-min(max(`taxrate'*profit_cit,0),NQRTC)	if `holiday_v'==0		
		// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))

		replace					Tax_cit=-QRTC	if  t<=`holiday_v' & `holiday_v'>0		
		replace					Tax_cit =(`taxrate') * profit_cit -QRTC-min(max(`taxrate'*profit_cit,0),NQRTC)	if t>`holiday_v' & `holiday_v'>0		
		
        gen 		double 		Tax_cit_time = Tax_cit / ((1 + rho) ^ t)
        egen 		double 		Tax_cit_NPV = total(Tax_cit_time)
     
	 											
		gen 		double 		econrent_cit=gamma*(revenue_NPV-1-Tax_cit_NPV)+  `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/(rho-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
			 
	 
		* Check if economic rent is close enough to zero
        if abs(econrent_cit) < `tolerance' {
            display "Converged for id=`id': p = " `p'
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
        drop revenue revenue_time revenue_NPV profit_cit Tax_cit Tax_cit_time Tax_cit_NPV econrent_cit
    }

    * Display results if maximum iterations reached without converging
    if `iter' == `max_iter' {
        local p_formatted: display %9.5f `p'
        display "Maximum iterations reached without convergence. Last p for id=`id' = " `p_formatted'
    }

    * Save the converged ptilde_cit for this id
    replace coc_cit = `p'

    * Calculate METR_CIT for this id
    by id, sort: gen METR_CIT = 100 *(coc_cit - `r') / coc_cit
    by id, sort: replace coc_cit = 100 * coc_cit

    * Append the results for this id to the temporary results file
    
	if id!=1{
	append using `cit_results'  // Append results for this id
	}
   	save `cit_results', replace  // Save the updated results
}
drop		t i gamma  rho A_decline A_straight SBIE QRTC NQRTC							// variables no longer needed
duplicates 	drop																// to keep only one observatio per ID
la var		coc_cit				"The cost of capital of a CIT"
la var		METR_CIT			"Marginal effective tax rate of a CIT"

*rename 		taxrate statutory_tax_rate
format 		METR* %9.03f
format 		coc* %9.03f

tempfile	cit_results															// keeping a local dataset containing the CIT METR
save		`cit_results', replace

}


****Cashflow tax

if "`system'"=="cft" {

* Create a temporary file to store the original data

gen double coc_cft = .  // Initialize variable for the cost of capital of a non-refundable CIT

* Define local parameters
local tolerance = 0.0001  // How close to zero we need to get economic rent
local max_iter = 1000       // Maximum number of iterations

* Get unique IDs
levelsof id_e, local(id_list)

* Create a temporary file to store results
tempfile cft_results
save `cft_results', emptyok  // Start with an empty file for results

* Loop through each ID
foreach id in `id_list' {
    * Load the original data copy for each ID
    use `metr_norefund', clear
    
    * Restrict data to the current id
    quietly keep if id == `id'
    
    * Set initial values
    local p = `r' 			   // Initial guess for cost of capital
    local iter = 0  		  // Iteration counter

    * Initialize ptilde_cit for this specific id
    gen double coc_cft = . 

while `iter' < `max_iter' {

    * Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + rho) ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	
   
	gen 		double 		profit_cft = -1		if t==0
    replace 	profit_cft = (`p' + `delta') * ((1 + `inflation') ^ t) * ((1 - `delta') ^ (t - 1))  if t >= 1

	gen  		double		Tax_cft=0
	replace					Tax_cft =(`taxrate') * profit_cft -QRTC-min(max(`taxrate'*profit_cft,0),NQRTC)	if `holiday_v'==0
	// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))
	replace					Tax_cft=-QRTC	if  t<=`holiday_v' & `holiday_v'>0		
	replace					Tax_cft =(`taxrate') * profit_cft -QRTC-min(max(`taxrate'*profit_cft,0),NQRTC)	if t>`holiday_v' & `holiday_v'>0	
	
    gen  		double		Tax_cft_time = Tax_cft/((1 + rho) ^ t)							// The discounted value of each peruiod's tax liability
    egen 		double 		Tax_cft_NPV = total(Tax_cft_time)								// NPV of the the sum of taxes paid
   
    											
	gen 		double 		econrent_cft=gamma*(revenue_NPV-1-Tax_cft_NPV)+  `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/(rho-`inflation'+`delta'*(1+`inflation')) 		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
			 
   
    * Check if economic rent is close enough to zero
    *summarize econ_rent, meanonly
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
    drop revenue revenue_time revenue_NPV profit_cft Tax_cft Tax_cft_time Tax_cft_NPV econrent_cft 				// to allow for the next iteration
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}

    replace coc_cft= `p'   


gen double METR_CFT= 100*(coc_cft-`r')/ coc_cft

replace coc_cft=100*coc_cft

if id!=1{
	append using `cft_results'  // Append results for this id
	}
    save `cft_results', replace  // Save the updated results
}
drop		t i gamma  rho A_decline A_straight SBIE QRTC NQRTC
duplicates 	drop
la var		coc_cft 				"The cost of capital of a cashflow tax"
la var		METR_CFT				"Marginal effective tax rate of a cashflow tax system"

*rename 		taxrate statutory_tax_rate
format 		METR* %9.03f
format 		coc* %9.03f
save		`cft_results', replace

}

****Allowance for equity
if "`system'"=="ace" {

* Create a temporary file to store the original data

gen double coc_ace = .  // Initialize variable for the cost of capital of a non-refundable CIT

* Define local parameters
local tolerance = 0.0001  // How close to zero we need to get economic rent
local max_iter = 1000       // Maximum number of iterations

* Get unique IDs
levelsof id_e, local(id_list)

* Create a temporary file to store results
tempfile ace_results
save `ace_results', emptyok  // Start with an empty file for results

* Loop through each ID
foreach id in `id_list' {
    * Load the original data copy for each ID
    use `metr_norefund', clear
    
    * Restrict data to the current id
    quietly keep if id == `id'
    
    * Set initial values
    local p = `r'					  // Initial guess for cost of capital
    local iter = 0   				 // Iteration counter

    * Initialize ptilde_cit for this specific id
    gen double coc_ace = . 

* Begin the iterative process
while `iter' < `max_iter' {

    * Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + rho) ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	
	
	gen 		double profit_ace=0

	**Declining balance	
	replace 	profit_ace=-`depreciation'  if t==0 & `deprtype'=="db"
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-i*(1-`depreciation')^t   if t>=1 & `deprtype'=="db"
	la 			var profit_ace "profit under refundable ACE"


**Straight line
	replace		profit_ace=-`depreciation'  if t==0 & `deprtype'=="sl"
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-i*max(1-t*`depreciation',0)   if t>=1 & `deprtype'=="sl"
	la 			var profit_ace "profit under non-refundable ACE"

	gen  		double		Tax_ace=0
	replace					Tax_ace=(`taxrate') * profit_ace -QRTC-min(max(`taxrate'*profit_ace,0),NQRTC)	if `holiday_v'==0
	// period by period tax liability (if taxable income is negative, then tax is also negative (i.e., refund))
	replace					Tax_ace=-QRTC	if  t<=`holiday_v'	& `holiday_v'>0
	replace					Tax_ace=(`taxrate') * profit_ace -QRTC-min(max(`taxrate'*profit_ace,0),NQRTC)	if t>`holiday_v' &	`holiday_v'>0
	
	gen		double 			Tax_ace_time= Tax_ace/((1 + i) ^ t)									// The discounted value of each peruiod's tax liability
	egen	double 			Tax_ace_NPV = total(Tax_ace_time)									// NPV of the the sum of taxes paid

	 											
	gen 		double 		econrent_ace=gamma*(revenue_NPV-1-Tax_ace_NPV)+  `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/(rho-`inflation'+`delta'*(1+`inflation')) 		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
			 
    *summarize econ_rent, meanonly
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
    drop revenue revenue_time revenue_NPV profit_ace Tax_ace Tax_ace_time Tax_ace_NPV econrent_ace 				// to allow for the next iteration
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}

	*replace taxrate_s = `taxrate' in `n'
    replace coc_ace = `p'   

	gen  	double 	METR_ACE= 100*(coc_ace-`r')/ coc_ace
	replace 		coc_ace=100*coc_ace


if id!=1{
	append using `ace_results'  // Append results for this id
	}
    save `ace_results', replace  // Save the updated results
}
drop		t i gamma  rho A_decline A_straight SBIE QRTC NQRTC
duplicates 	drop

la var 		coc_ace  			"The cost of capital of an ACE system"
la var 		METR_ACE	 		"Marginal tax rate of an ACE system"

format 		METR* %9.03f
format 		coc* %9.03f
save		`ace_results', replace
}
   
}																				// closes minimumtax==no & refund==yes



if "`minimumtax'"=="no" &  "`refund'"=="no" {

****standard CIT

* Create a temporary file to store the original data

if "`system'"=="cit" {
	
tempfile metr_norefund
save `metr_norefund', replace

* Initialize necessary variables globally
gen double coc_cit = .  // Initialize variable for the cost of capital of a non-refundable CIT

* Define local parameters
local tolerance = 0.0001  // How close to zero we need to get economic rent
local max_iter = 1000       // Maximum number of iterations

* Get unique IDs
levelsof id_e, local(id_list)

* Create a temporary file to store results
tempfile cit_results
save `cit_results', emptyok  // Start with an empty file for results

* Loop through each ID
foreach id in `id_list' {
    * Load the original data copy for each ID
    use `metr_norefund', clear
    
    * Restrict data to the current id
    quietly keep if id == `id'
    
    * Set initial values
    local p = `r'	   		// Initial guess for cost of capital
    local iter = 0    		// Iteration counter

    * Initialize ptilde_cit for this specific id
    gen double coc_cit = . 

    * Begin the iterative process
    while `iter' < `max_iter' {
        * Calculate the economic rent based on the current value of p
		gen 		double 		revenue=0 				 												
		replace			 		revenue=0	 													if t==0 	// revenue in period 0 
		replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
		gen  		double		revenue_time=revenue/((1 + rho) ^ t)										// discounted value of revenue
		egen 		double 		revenue_NPV= total(revenue_time)	
	   
	    gen double profit_cit = 0
**Declining balance
 
        replace profit_cit = (`p' + `delta') * (1 + `inflation') - `depreciation' - `depreciation' * (1 - `depreciation') - `debt_v' * i if t == 1 & `deprtype'=="db"
        replace profit_cit = (`p' + `delta') * ((1 + `inflation') ^ t) * ((1 - `delta') ^ (t - 1)) - `depreciation' * (1 - `depreciation') ^ t - `debt_v' * i * ((1 + `inflation') * (1 - `delta')) ^ (t - 1) + min(0, profit_cit[_n-1]) if t > 1 & `deprtype'=="db"
        

**Straight line
        replace profit_cit = (`p' + `delta') * (1 + `inflation') - `depreciation' - min(max(1 - `depreciation', 0), `depreciation') - `debt_v' * i if t == 1 & `deprtype'=="sl"
        replace profit_cit = (`p' + `delta') * ((1 + `inflation') ^ t) * ((1 - `delta') ^ (t - 1)) - min(max(1 - t * `depreciation', 0), `depreciation') - `debt_v'*i* ((1 + `inflation') * (1 - `delta')) ^ (t - 1) + min(0, profit_cit[_n-1]) if t > 1 & `deprtype'=="sl"
        

		gen			double		Tax_cit=0
		replace					Tax_cit =(`taxrate') * max(profit_cit,0) -QRTC-min(max(`taxrate'*profit_cit,0),NQRTC)	if `holiday_v'==0		
		// period by period tax liability (if taxable income is negative,  then tax is zero(i.e., no-refund))

		replace					Tax_cit=-QRTC	if  t<=`holiday_v' & `holiday_v'>0		
		replace					Tax_cit =(`taxrate') * max(profit_cit,0) -QRTC-min(max(`taxrate'*profit_cit,0),NQRTC)	if t>`holiday_v' & `holiday_v'>0

        gen			double 		Tax_cit_time = Tax_cit / ((1 + rho) ^ t)
        egen		double 		Tax_cit_NPV = total(Tax_cit_time)
 
  											
		gen 		double 		econrent_cit=gamma*(revenue_NPV-1-Tax_cit_NPV)+  `newequity_v'*(gamma-1)+ `debt_v'*gamma*(rho-i)/(rho-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
			 
 
        * Check if economic rent is close enough to zero
        if abs(econrent_cit) < `tolerance' {
            display "Converged for id=`id': p = " `p'
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
        drop revenue revenue_time revenue_NPV profit_cit Tax_cit Tax_cit_time Tax_cit_NPV econrent_cit
    }

    * Display results if maximum iterations reached without converging
    if `iter' == `max_iter' {
        local p_formatted: display %9.5f `p'
        display "Maximum iterations reached without convergence. Last p for id=`id' = " `p_formatted'
    }

    * Save the converged ptilde_cit for this id
    replace coc_cit = `p'

    * Calculate METR_CIT for this id
    by id, sort: gen METR_CIT = 100 * (coc_cit - `r') / coc_cit
    by id, sort: replace coc_cit = 100 * coc_cit

    * Append the results for this id to the temporary results file
    
	if id!=1{
	append using `cit_results'  // Append results for this id
	}
   	save `cit_results', replace  // Save the updated results
}

drop		t i gamma  rho A_decline A_straight SBIE QRTC NQRTC							// variables no longer needed
duplicates 	drop																// to keep only one observatio per ID
la var		coc_cit				"The cost of capital of a CIT"
la var		METR_CIT			"Marginal effective tax rate of a CIT"

*rename 		taxrate statutory_tax_rate
format 		METR* %9.03f
format 		coc* %9.03f

tempfile	cit_results															// keeping a local dataset containing the CIT METR
save		`cit_results', replace

}



****Cashflow tax

if "`system'"=="cft" {


tempfile metr_norefund
save `metr_norefund', replace

gen double coc_cft = .  // Initialize variable for the cost of capital of a non-refundable CIT

* Define local parameters
local tolerance = 0.0001 		 // How close to zero we need to get economic rent
local max_iter = 1000      		 // Maximum number of iterations

* Get unique IDs
levelsof id_e, local(id_list)

* Create a temporary file to store results
tempfile cft_results
save `cft_results', emptyok  // Start with an empty file for results

* Loop through each ID
foreach id in `id_list' {
    * Load the original data copy for each ID
    use `metr_norefund', clear
    
    * Restrict data to the current id
    quietly keep if id == `id'
    
    * Set initial values
    local p = `r'		  	 // Initial guess for cost of capital
    local iter = 0    		// Iteration counter

    * Initialize ptilde_cit for this specific id
    gen double coc_cft = . 

while `iter' < `max_iter' {
	
	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + rho) ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	

    * Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
    gen 		double profit_cft = 0
    replace 	profit_cft = (`p' + `delta') * (1 + `inflation') - 1 if t == 1					// -1 is to account for the loss carried forward from period 0
    replace 	profit_cft = (`p' + `delta') * ((1 + `inflation') ^ t) * ((1 - `delta') ^ (t - 1)) + min(0, profit_cft[_n-1]) if t > 1

    gen  		double		Tax_cft=0
	replace					Tax_cft =max(0, `taxrate' * profit_cft ) -QRTC-min(max(`taxrate'*profit_cft,0),NQRTC)	if `holiday_v'==0		
	// period by period tax liability (if taxable income is negative, then tax is zero(i.e., no-refund))
	replace					Tax_cft=-QRTC	if  t<=`holiday_v'	& `holiday_v'>0	
	replace					Tax_cft =max(0, `taxrate' * profit_cft ) -QRTC-min(max(`taxrate'*profit_cft,0),NQRTC)	if t>`holiday_v' & `holiday_v'>0
	
    gen  		double 		Tax_cft_time = Tax_cft/((1 + i) ^ t)							// The discounted value of each peruiod's tax liability
    egen 		double 		Tax_cft_NPV = total(Tax_cft_time)								// NPV of the the sum of taxes paid
  
   											
	gen 		double 		econrent_cft=gamma*(revenue_NPV-1-Tax_cft_NPV)+  `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/(rho-`inflation'+`delta'*(1+`inflation'))		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
			 
    *summarize econ_rent, meanonly
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
    drop revenue revenue_time revenue_NPV profit_cft Tax_cft Tax_cft_time Tax_cft_NPV econrent_cft 				// to allow for the next iteration
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}

    replace coc_cft= `p'   


gen double METR_CFT= 100*(coc_cft-`r')/ coc_cft

replace coc_cft=100*coc_cft

if id!=1{
	append using `cft_results'  // Append results for this id
	}
    save `cft_results', replace  // Save the updated results
}
drop		t i gamma  rho A_decline A_straight SBIE QRTC NQRTC
duplicates 	drop


la var		coc_cft 				"The cost of capital of a cashflow tax"
la var		METR_CFT				"Marginal effective tax rate of a cashflow tax system"


*rename 		taxrate statutory_tax_rate
format 		METR* %9.03f
format 		coc* %9.03f

tempfile 	cft_results
save		`cft_results', replace


}


****Allowance for equity
if "`system'"=="ace" {

tempfile metr_norefund
save `metr_norefund', replace

* Create a temporary file to store the original data
******************Allowance for equity
gen double coc_ace = .  // Initialize variable for the cost of capital of a non-refundable CIT

* Define local parameters
local tolerance = 0.0001  // How close to zero we need to get economic rent
local max_iter = 1000       // Maximum number of iterations

* Get unique IDs
levelsof id_e, local(id_list)

* Create a temporary file to store results
tempfile ace_results
save `ace_results', emptyok  // Start with an empty file for results

* Loop through each ID
foreach id in `id_list' {
    * Load the original data copy for each ID
    use `metr_norefund', clear
    
    * Restrict data to the current id
    quietly keep if id == `id'
    
    * Set initial values
    local p = `r'		  	 // Initial guess for cost of capital
    local iter = 0    		// Iteration counter

    * Initialize ptilde_cit for this specific id
    gen double coc_ace = . 

* Begin the iterative process
while `iter' < `max_iter' {

		gen 		double 		revenue=0 				 												
		replace			 		revenue=0	 													if t==0 	// revenue in period 0 
		replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
		gen  		double		revenue_time=revenue/((1 + rho) ^ t)										// discounted value of revenue
		egen 		double 		revenue_NPV= total(revenue_time)	
    * Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
	
	gen 		double profit_ace=0 
**Declining balance
	
	replace		profit_ace=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation')-i*(1-`depreciation')         if t==1    & `deprtype'=="db"
	// i*(1-phi) is the allowance for corporate equity
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-i*(1-`depreciation')^t + min(0,profit_ace[_n-1])  if t>1 & `deprtype'=="db"
	la 			var profit_ace "profit under non-refundable ACE and declining balance depreciation"


**Straight line
	replace		profit_ace=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-i*max(1-`depreciation',0)         if t==1  & `deprtype'=="sl"  
	// i*(1-phi) is the allowance for corporate equity
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-i*max(1-t*`depreciation',0) + min(0,profit_ace[_n-1])  if t>1 & `deprtype'=="sl"
	la 			var profit_ace "profit under non-refundable ACE and declining balance depreciation"

	gen  		double		Tax_ace=0
	replace					Tax_ace=max(0, `taxrate' * profit_ace ) -QRTC-min(max(`taxrate'*profit_ace,0),NQRTC)	if `holiday_v'==0		
	// period by period tax liability (if taxable income is negative, then tax is zero(i.e., no-refund))

	replace					Tax_ace=-QRTC	if  t<=`holiday_v' & `holiday_v'>0		
	replace					Tax_ace=max(0, `taxrate' * profit_ace ) -QRTC-min(max(`taxrate'*profit_ace,0),NQRTC)	if t>`holiday_v' & `holiday_v'>0		

	gen		double Tax_ace_time= Tax_ace/((1 + i) ^ t)								// The discounted value of each peruiod's tax liability
	egen	double Tax_ace_NPV = total(Tax_ace_time)									// NPV of the the sum of taxes paid

	 											
	gen 		double 		econrent_ace=gamma*(revenue_NPV-1-Tax_ace_NPV)+  `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/(rho-`inflation'+`delta'*(1+`inflation'))		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
			 
    * Check if economic rent is close enough to zero
    *summarize econ_rent, meanonly
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
    drop revenue revenue_time revenue_NPV profit_ace Tax_ace Tax_ace_time Tax_ace_NPV econrent_ace 				// to allow for the next iteration
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}

	*replace taxrate_s = `taxrate' in `n'
    replace coc_ace = `p'   

	gen  	double 	METR_ACE= 100*(coc_ace-`r')/ coc_ace
	replace 		coc_ace=100*coc_ace


if id!=1{
	append using `ace_results'  // Append results for this id
	}
    save `ace_results', replace  // Save the updated results
}
drop		t i gamma  rho A_decline A_straight SBIE QRTC NQRTC
duplicates 	drop

la var 		coc_ace  			"The cost of capital of an ACE system"
la var 		METR_ACE	 		"Marginal tax rate of an ACE system"

*rename 		taxrate statutory_tax_rate
format 		METR* %9.03f
format 		coc* %9.03f
save		`ace_results', replace
}
   
}						// closing the minimumtax==no and refund==no METR 

	
	

*===================================================================================
***Marginal Effective Tax rate including top-up.
*===================================================================================


if "`minimumtax'"=="yes" & "`refund'"=="yes" {

***Standard CIT

if "`system'"=="cit" {

* Create a temporary file to store the original data
	tempfile metr_norefund
	save `metr_norefund', replace

* Initialize necessary variables globally
	gen double coc_cit = .  // Initialize variable for the cost of capital of a non-refundable CIT

* Define local parameters
	local tolerance = 0.0001  		// How close to zero we need to get economic rent
	local max_iter = 1000       	// Maximum number of iterations

* Get unique IDs
	levelsof id_e, local(id_list)

* Create a temporary file to store results
	tempfile cit_results
	save `cit_results', emptyok  // Start with an empty file for results

* Loop through each ID
	foreach id in `id_list' {
    * Load the original data copy for each ID
    use `metr_norefund', clear
    
    * Restrict data to the current id
    quietly keep if id == `id'
    
    * Set initial values
    local p = `r' 		  	 // Initial guess for cost of capital
    local iter = 0    		// Iteration counter

    * Initialize ptilde_cit for this specific id
    gen double coc_cit = . 
* Begin the iterative process
	while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
/*=========================
First, the pre-topup tax (we use the same for debt and equity finance becasue they are equivalent)
=========================*/
	
		gen 		double 		revenue=0 				 												
		replace			 		revenue=0	 													if t==0 	// revenue in period 0 
		replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
		gen  		double		revenue_time=revenue/((1 + rho) ^ t)										// discounted value of revenue
		egen 		double 		revenue_NPV= total(revenue_time)	
	
		gen 		double 	profit_cit=-`depreciation' if t==0	  	//taxable income in period 0
		gen 		double 	profit_cit_tpt=0	if t==0															// accounting profit before tax credit
		gen 		double cov_profit_cit=0 	if t==0
		**Declining balance	
		replace				profit_cit=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1)   if t>0 & `deprtype'=="db"
		la 			var 	profit_cit "profit under a refundable CIT"
		
		replace		profit_cit_tpt=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt_v'*i   if t==1 & `deprtype'=="db"
		replace		profit_cit_tpt=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit_tpt[_n-1])  if t>1 & `deprtype'=="db"
	
	** Globe income (covered taxable income) is standard profit plus the tax credit

	replace		cov_profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt_v'*i + QRTC   if t==1 & `deprtype'=="db"
	replace		cov_profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1)  + min(0,cov_profit_cit[_n-1]) + QRTC  if t>1 & `deprtype'=="db"
	la var 		cov_profit_cit  "covered tax of a standard CIT"
	


**Straight line
	replace			profit_cit=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1)    if t>0 & `deprtype'=="sl"
	la 		var 	profit_cit "profit under a standard CIT"


****
	replace			profit_cit_tpt=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt_v'*i   if t==1 & `deprtype'=="sl"
	replace			profit_cit_tpt=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit_tpt[_n-1])  if t>1 & `deprtype'=="sl"
	
	** Globe income (covered taxable income) is standard profit plus the tax credit
	replace		cov_profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt_v'*i + QRTC  if t==1 & `deprtype'=="sl"
	replace		cov_profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')-`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1)  + min(0,cov_profit_cit[_n-1]) + QRTC if t>1 & `deprtype'=="sl"
	la var 		cov_profit_cit  "covered tax of a standard CIT"

	
*First, the domestic tax
	gen  	double		Tax_cit=0
	replace				Tax_cit=`taxrate' * profit_cit -QRTC-min(max(`taxrate'*profit_cit,0),NQRTC)	if `holiday_v'==0
	// period by period tax liability (if taxable income is negative, then tax is zero(i.e., refund))
	replace				Tax_cit=-QRTC	if  t<=`holiday_v' & `holiday_v'>0
	replace				Tax_cit=`taxrate' * profit_cit -QRTC-min(max(`taxrate'*profit_cit,0),NQRTC)	if t>`holiday_v'		
	
    gen  	double 		Tax_cit_time = Tax_cit/((1 + rho) ^ t)					// The discounted value of each period's tax liability
    egen 	double		Tax_cit_NPV = total(Tax_cit_time)						// NPV of the the sum of taxes paid


*Second, the top-up tax part	
	gen			double exprofit_cit=max(0,cov_profit_cit-SBIE)
	la var 		exprofit_cit  "Excess profit under standard CIT"

	gen 		covtax_cit=0										// covered tax
	replace 	covtax_cit=(`taxrate')*max(0,profit_cit_tpt)-min((`taxrate')*max(0,profit_cit_tpt),NQRTC) if `holiday_v'==0
	replace 	covtax_cit=(`taxrate')*max(0,profit_cit_tpt)-min((`taxrate')*max(0,profit_cit_tpt),NQRTC) if t>`holiday_v' & `holiday_v'>0
	
	gen	double	tpr_cit=max(0,`minrate'-(covtax_cit)/cov_profit_cit)	    if cov_profit_cit>0													//the top-up tax in each period for each value of the tax rate
	la var 		tpr_cit "Top up tax rate under stanadrd CIT"
	
	gen 		double tpt_cit=tpr_cit*exprofit_cit/((1+rho)^t)			// the discounted value of the top-up tax paid each period 
	egen 		total_tpt_cit=total(tpt_cit)

	gen 		double 		econrent_cit=gamma*(revenue_NPV-1-Tax_cit_NPV-total_tpt_cit)+  `newequity_v'*(gamma-1)+ `debt_v'*gamma*(rho-i)/(rho-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR
			 

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
    drop revenue revenue_time revenue_NPV profit_cit Tax_cit Tax_cit_time Tax_cit_NPV profit_cit_tpt cov_profit_cit exprofit_cit covtax_cit tpr_cit tpt_cit  total_tpt_cit econrent_cit			// to allow for the next iteration
	}																			// closing the iteration


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}

    replace		coc_cit= `p'    


	gen 		double METR_CIT= 100*(coc_cit-`r')/ coc_cit
	replace		coc_cit= 100*coc_cit  
if id!=1{
	append using `cit_results'  // Append results for this id
	}
   	save `cit_results', replace  // Save the updated results
}
drop		t i  gamma rho A_decline A_straight SBIE QRTC NQRTC			// variables no longer needed
duplicates 	drop																// to keep only one observatio per ID
tempfile	cit_results															// keeping a local dataset containing the CIT METR
save		`cit_results', replace

la var		coc_cit				"The cost of capital of a CIT"
la var		METR_CIT			"Marginal effective tax rate of a CIT"

*rename 		taxrate statutory_tax_rate
format 		METR* %9.03f
format 		coc* %9.03f
}


***cashflow tax

if "`system'"=="cft" {

tempfile metr_norefund
save `metr_norefund', replace

gen double coc_cft = .  // Initialize variable for the cost of capital of a non-refundable CIT

* Define local parameters
local tolerance = 0.0001 		 // How close to zero we need to get economic rent
local max_iter = 1000      		 // Maximum number of iterations

* Get unique IDs
levelsof id_e, local(id_list)

* Create a temporary file to store results
tempfile cft_results
save `cft_results', emptyok  // Start with an empty file for results

* Loop through each ID
foreach id in `id_list' {
    * Load the original data copy for each ID
    use `metr_norefund', clear
    
    * Restrict data to the current id
    quietly keep if id == `id'
    
    * Set initial values
    local p = `r'				  	 // Initial guess for cost of capital
    local iter = 0    				// Iteration counter

    * Initialize ptilde_cit for this specific id
    gen double coc_cft = . 

* Begin the iterative process
while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
/*=========================
First, the pre-topup tax
=========================*/	

	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + rho) ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	


	gen 		double profit_cft=0
	replace		profit_cft=-1	  															if t==0									// period 0 taxable income
	replace		profit_cft=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)				if t>=1
	la var 		profit_cft  "profit under a refundable cahsflow tax"
   
  
	gen  	double		Tax_cft=0
	replace				Tax_cft=`taxrate' * profit_cft -QRTC-min(max(`taxrate'*profit_cft,0),NQRTC)	if `holiday_v'==0		
	// period by period tax liability (if taxable income is negative, then tax is zero(i.e., refund))
	replace				Tax_cft=-QRTC	if  t<=`holiday_v' & `holiday_v'>0		
	replace				Tax_cft=`taxrate' * profit_cft -QRTC-min(max(`taxrate'*profit_cft,0),NQRTC)	if t>`holiday_v' & `holiday_v'>0		
	
    gen  	double		Tax_cft_time= Tax_cft/((1 + rho) ^ t)										// The discounted value of each peruiod's tax liability
    egen 	double 		Tax_cft_NPV= total(Tax_cft_time)											// NPV of the the sum of taxes paid


/*=========================
Second, the top-up tax
=========================*/
	gen 		double profit_cft_tpt=0		if t==0												// covered tax for GloBE purposes. Since immediate expensing is a timing issue, the covered tax and top-up rate look similar to the case of a standard CIT financed with equity

	gen 		double cov_profit_cft=0		if t==0														// covered tax for GloBE purposes. Since immediate expensing is a timing issue, the covered tax and top-up rate look similar to the case of a standard CIT financed with equity
	
	**declining balance
	
	replace		profit_cft_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation')    if t==1 & `deprtype'=="db"
	replace		profit_cft_tpt=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t  + min(0,profit_cft_tpt[_n-1])  if t>1  & `deprtype'=="db"
	la var 		profit_cft_tpt "the profit base for the covered tax"  
	
		
	replace		cov_profit_cft=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation')-`debt_v'*i + QRTC    if t==1 & `deprtype'=="db"
	replace		cov_profit_cft=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,cov_profit_cft[_n-1]) + QRTC if t>1 & `deprtype'=="db"
	la var 		cov_profit_cft  "covered tax of a cashflow tax under GlOBE: declining balance depreciation"


	
**Straight line	
	replace		profit_cft_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')    if t==1 & `deprtype'=="sl"
	replace		profit_cft_tpt=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')  + min(0,profit_cft_tpt[_n-1])  if t>1 & `deprtype'=="sl"
	la var 		profit_cft_tpt "the profit base for the covered tax"  
	
	
	replace		cov_profit_cft=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt_v'*i + QRTC   if t==1 & `deprtype'=="sl"
	replace		cov_profit_cft=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,cov_profit_cft[_n-1]) + QRTC if t>1 & `deprtype'=="sl"
	la var 		cov_profit_cft  "covered tax of a cashflow tax under GlOBE: declining balance depreciation"


	gen			double exprofit_cft=max(0,cov_profit_cft-SBIE)
	la var 		exprofit_cft  "Excess profit under refundable cashfolow tax: GloBE"
	
	gen 		covtax_cft=0										// covered tax
	replace 	covtax_cft=(`taxrate')*max(0,profit_cft_tpt)-min((`taxrate')*max(0,profit_cft_tpt),NQRTC) if `holiday_v'==0
	replace 	covtax_cft=(`taxrate')*max(0,profit_cft_tpt)-min((`taxrate')*max(0,profit_cft_tpt),NQRTC) if t>`holiday_v' & `holiday_v'>0
	
	gen	double	tpr_cft=max(0,`minrate'-(covtax_cft)/cov_profit_cft)	    if cov_profit_cft>0													//the top-up tax in each period for each value of the tax rate
	la var 		tpr_cft "Top up tax rate under R based cashflow tax"

	gen 		double tpt_cft=tpr_cft*exprofit_cft/((1+rho)^t)			// top-up tax (discounted value) 
	egen 		double total_tpt_cft=total(tpt_cft)


	gen 		double 		econrent_cft=gamma*(revenue_NPV-1-Tax_cft_NPV-total_tpt_cft) +  `newequity_v'*(gamma-1)+ `debt_v'*gamma*(rho-i)/(rho-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR

	

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
    drop revenue revenue_time revenue_NPV  profit_cft profit_cft_tpt Tax_cft Tax_cft_time Tax_cft_NPV cov_profit_cft exprofit_cft covtax_cft tpr_cft tpt_cft  total_tpt_cft econrent_cft			// to allow for the next iteration
	}																				// closing the iternation


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}

    replace coc_cft= `p'    

	gen double METR_CFT= 100*(coc_cft-`r')/ coc_cft
	replace coc_cft=100*coc_cft
	
	if id!=1{
	append using `cft_results'  // Append results for this id
	}
    save `cft_results', replace  // Save the updated results
}
drop		t i  gamma rho A_decline A_straight SBIE QRTC NQRTC
duplicates 	drop
save		`cft_results', replace

la var		coc_cft 				"The cost of capital of a cashflow tax"
la var		METR_CFT				"Marginal effective tax rate of a cashflow tax system"

*rename 		taxrate statutory_tax_rate
format 		METR* %9.03f
format 		coc* %9.03f

}



***ACE

if "`system'"=="ace" {


tempfile metr_norefund
save `metr_norefund', replace

gen double coc_ace = .  // Initialize variable for the cost of capital of a non-refundable CIT

* Define local parameters
local tolerance = 0.0001  // How close to zero we need to get economic rent
local max_iter = 1000       // Maximum number of iterations

* Get unique IDs
levelsof id_e, local(id_list)

* Create a temporary file to store results
tempfile ace_results
save `ace_results', emptyok  // Start with an empty file for results

* Loop through each ID
foreach id in `id_list' {
    * Load the original data copy for each ID
    use `metr_norefund', clear
    
    * Restrict data to the current id
    quietly keep if id == `id'
    
    * Set initial values
    local p = `r'			  	 // Initial guess for cost of capital
    local iter = 0    			// Iteration counter

    * Initialize ptilde_cit for this specific id
    gen double coc_ace = . 


* Begin the iterative process
while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
/*=========================
First, the pre-topup tax (we use the same for debt and equity finance becasue they are equivalent)
=========================*/
	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + rho) ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	

	gen 		double profit_ace=-`depreciation' if t==0		//taxable income in period 0
	gen 		double profit_ace_tpt=0	 if t==0																// accounting profit before tax credit

	gen 		double cov_profit_ace=0  if t==0
**Declining balance	
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-i*(1-`depreciation')^t   if t>=1 & `deprtype'=="db"
	la 			var profit_ace "profit under a refundable ACE: declining balance depreciation"

	
****
	replace		profit_ace_tpt=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt_v'*i   if t==1 & `deprtype'=="db"
	replace		profit_ace_tpt=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_ace_tpt[_n-1])  if t>1 & `deprtype'=="db"
	
	** Globe income (covered taxable income) is standard profit plus the tax credit
	replace		cov_profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt_v'*i +  (`taxrate')*i*(1-`depreciation') + QRTC  if t==1 & `deprtype'=="db"
	replace		cov_profit_ace=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + (`taxrate')*i*(1-`depreciation')^t + min(0,cov_profit_ace[_n-1]) + QRTC  if t>1 & `deprtype'=="db"
	la var 		cov_profit_ace  "covered tax of a refundable ACE: declining balance depreciation"
	


**Straight line	
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-i*max(1-t*`depreciation',0)   if t>0 & `deprtype'=="sl"
	la 			var profit_ace "profit under a refundable ACE: declining balance depreciation"

****
	replace		profit_ace_tpt=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')    if t==1 & `deprtype'=="sl"
	replace		profit_ace_tpt=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')  + min(0,profit_ace_tpt[_n-1])  if t>1 & `deprtype'=="sl"
	
	** Globe income (covered taxable income) is standard profit plus the tax credit
	replace		cov_profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt_v'*i +  (`taxrate')*i*max(1-`depreciation',0) + QRTC   if t==1 & `deprtype'=="sl"
	replace	cov_profit_ace=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')-`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + (`taxrate')*i*max(1-t*`depreciation',0) + min(0,cov_profit_ace[_n-1]) + QRTC if t>1 & `deprtype'=="sl"
	la var 		cov_profit_ace  "covered tax of a refundable ACE: declining balance depreciation"

	
*First, the domestic tax

	gen  	double		Tax_ace=0
	replace				Tax_ace=`taxrate' * profit_ace -QRTC-min(max(`taxrate'*profit_ace,0),NQRTC)	if `holiday_v'==0		
	// period by period tax liability (if taxable income is negative, then tax is zero(i.e., refund))
	replace				Tax_ace=-QRTC	if  t<=`holiday_v' & `holiday_v'>0		
	replace				Tax_ace=`taxrate' * profit_ace -QRTC-min(max(`taxrate'*profit_ace,0),NQRTC)	if t>`holiday_v' & `holiday_v'>0	

    gen  	double 		Tax_ace_time= Tax_ace/((1 + rho) ^ t)								// The discounted value of each period's tax liability
    egen 	double		Tax_ace_NPV= total(Tax_ace_time)								// NPV of the the sum of taxes paid


*Second, the top-up tax part	
	gen			double exprofit_ace=max(0,cov_profit_ace-SBIE)
	la var 		exprofit_ace  "Excess profit under ACE"

	gen 		covtax_ace=0										// covered tax
	replace 	covtax_ace=(`taxrate')*max(0,profit_ace_tpt)-min((`taxrate')*max(0,profit_ace_tpt),NQRTC) if `holiday_v'==0
	replace 	covtax_ace=(`taxrate')*max(0,profit_ace_tpt)-min((`taxrate')*max(0,profit_ace_tpt),NQRTC) if t>`holiday_v' & `holiday_v'>0 
	
	gen	double	tpr_ace=max(0,`minrate'-(covtax_ace)/cov_profit_ace)	    if cov_profit_ace>0													//the top-up tax in each period for each value of the tax rate
	la var 		tpr_ace "Top up tax rate under ACE"
	
	gen 		double tpt_ace=tpr_ace*exprofit_ace/((1+rho)^t)			// the discounted value of the top-up tax paid each period 
	egen 		total_tpt_ace=total(tpt_ace)
	
		gen 		double 		econrent_ace=gamma*(revenue_NPV-1-Tax_ace_NPV-total_tpt_ace)+  `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/(rho-`inflation'+`delta'*(1+`inflation')) 		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR

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
    drop revenue revenue_time revenue_NPV profit_ace Tax_ace Tax_ace_time Tax_ace_NPV profit_ace_tpt cov_profit_ace exprofit_ace covtax_ace tpr_ace tpt_ace  total_tpt_ace econrent_ace			// to allow for the next iteration
	}																			// closing the iteration


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}

    replace		coc_ace= `p'    


	gen 		double METR_ACE= 100*(coc_ace-`r')/ coc_ace
	replace		coc_ace=100*coc_ace

	if id!=1{
	append using `ace_results'  // Append results for this id
	}
    save `ace_results', replace  // Save the updated results
}
drop		t i  gamma rho A_decline A_straight SBIE QRTC NQRTC
duplicates 	drop
format 		METR* %9.03f
format 		coc* %9.03f
save		`ace_results', replace

}
   
}							// closing the minimum tax==yes and refund=yes routine


***Standard CIT
if "`minimumtax'"=="yes" &  "`refund'"=="no" {

if "`system'"=="cit" {

	tempfile metr_norefund
	save `metr_norefund', replace

* Initialize necessary variables globally
	gen double coc_cit = .  // Initialize variable for the cost of capital of a non-refundable CIT

* Define local parameters
	local tolerance = 0.0001  				// How close to zero we need to get economic rent
	local max_iter = 1000      			 	// Maximum number of iterations

* Get unique IDs
	levelsof id_e, local(id_list)

* Create a temporary file to store results
	tempfile cit_results
	save `cit_results', emptyok  // Start with an empty file for results

* Loop through each ID
	foreach id in `id_list' {
    * Load the original data copy for each ID
    use `metr_norefund', clear
    
    * Restrict data to the current id
    quietly keep if id == `id'
    
    * Set initial values
    local p = `r'			  // Initial guess for cost of capital
    local iter = 0    		// Iteration counter

    * Initialize ptilde_cit for this specific id
    gen double coc_cit = . 
* Begin the iterative process
while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p
/*=========================
First, the pre-topup tax (we use the same for debt and equity finance becasue they are equivalent)
=========================*/
	
	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + rho) ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	

	gen 		double profit_cit=0	 		if t==0 		// accounting profit before tax credit
	gen 		double	profit_cit_tpt=0 	if t==0
	gen 		double 	cov_profit_cit=0 if t==0
	**Declining balance	

	replace		profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt_v'*i   if t==1 & `deprtype'=="db"
	replace		profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit[_n-1])  if t>1 & `deprtype'=="db"
	
****
	replace				profit_cit_tpt=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt_v'*i   if t==1 & `deprtype'=="db"
	replace				profit_cit_tpt=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit_tpt[_n-1])  if t>1 & `deprtype'=="db"
	
	** Globe income (covered taxable income) is standard profit plus the tax credit
	replace				cov_profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-`debt_v'*i + QRTC  if t==1 & `deprtype'=="db"
	replace				cov_profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1)  + min(0,cov_profit_cit[_n-1]) + QRTC  if t>1 & `deprtype'=="db"
	la var 				cov_profit_cit  "covered tax of a standard CIT"
	


**Straight line	
	replace		profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt_v'*i   if t==1 & `deprtype'=="sl"
	replace		profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit[_n-1])  if t>1 & `deprtype'=="sl"

****
	replace		profit_cit_tpt=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt_v'*i   if t==1 & `deprtype'=="sl"
	replace		profit_cit_tpt=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,profit_cit_tpt[_n-1])  if t>1 & `deprtype'=="sl"
	
	** Globe income (covered taxable income) is standard profit plus the tax credit
	replace		cov_profit_cit=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt_v'*i + QRTC  if t==1 & `deprtype'=="sl"
	replace		cov_profit_cit=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')-`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1)  + min(0,cov_profit_cit[_n-1]) + QRTC  if t>1 & `deprtype'=="sl"
	la var 		cov_profit_cit  "covered tax of a standard CIT"

	
*First, the domestic tax
	gen  		double		Tax_cit=0
	replace					Tax_cit =(`taxrate')*max(profit_cit,0) -QRTC-min((`taxrate')*max(profit_cit,0),NQRTC)	if `holiday_v'==0
	// period by period tax liability (if taxable income is negative, then tax is zero (i.e., no-refund))   
  
	replace					Tax_cit =-QRTC	if  t<=`holiday_v' & `holiday_v'>0		
	replace					Tax_cit =(`taxrate')*max(profit_cit,0) -QRTC-min((`taxrate')*max(profit_cit,0),NQRTC)	if t>`holiday_v' & `holiday_v'>0	
  
    gen			double 		Tax_cit_time= Tax_cit/((1 + rho) ^ t)								// The discounted value of each period's tax liability
    egen 		double 		Tax_cit_NPV= total(Tax_cit_time)									// NPV of the the sum of taxes paid


*Second, the top-up tax part	
	gen			double 		exprofit_cit=max(0,cov_profit_cit-SBIE)
	la var 					exprofit_cit  "Excess profit under standard CIT"

	gen 		covtax_cit=0										// covered tax
	replace 	covtax_cit=(`taxrate')*max(0,profit_cit_tpt)-min((`taxrate')*max(0,profit_cit_tpt),NQRTC) if `holiday_v'==0
	replace 	covtax_cit=(`taxrate')*max(0,profit_cit_tpt)-min((`taxrate')*max(0,profit_cit_tpt),NQRTC) if t>`holiday_v' & `holiday_v'>0

	gen	double	tpr_cit=max(0,`minrate'-(covtax_cit)/cov_profit_cit)	    if cov_profit_cit>0													//the top-up tax in each period for each value of the tax rate
	la var 		tpr_cit "Top up tax rate under stanadrd CIT"

	gen 		double tpt_cit=tpr_cit*exprofit_cit/((1+rho)^t)			// the discounted value of the top-up tax paid each period 
	egen 		total_tpt_cit=total(tpt_cit)
	
		gen 		double 		econrent_cit=gamma*(revenue_NPV-1-Tax_cit_NPV-total_tpt_cit)+  `newequity_v'*(gamma-1)+ `debt_v'*gamma*(rho-i)/(rho-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR

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
    drop revenue revenue_time revenue_NPV profit_cit Tax_cit Tax_cit_time Tax_cit_NPV profit_cit_tpt cov_profit_cit exprofit_cit covtax_cit tpr_cit tpt_cit  total_tpt_cit econrent_cit			// to allow for the next iteration
	}																			// closing the iteration


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}

    replace		coc_cit= `p'    


	gen 		double METR_CIT= 100*(coc_cit-`r')/ coc_cit

	replace		coc_cit=100*coc_cit
	
if id!=1{
	append using `cit_results'  // Append results for this id
	}
   	save `cit_results', replace  // Save the updated results
}
drop		t i gamma  rho A_decline A_straight SBIE QRTC NQRTC			// variables no longer needed
duplicates 	drop																// to keep only one observatio per ID
la var		coc_cit				"The cost of capital of a CIT"
la var		METR_CIT			"Marginal effective tax rate of a CIT"

format 		METR* %9.03f
format 		coc* %9.03f
tempfile	cit_results															// keeping a local dataset containing the CIT METR
save		`cit_results', replace	
}


***Cash-flow tax

if "`system'"=="cft" {

tempfile metr_norefund
save `metr_norefund', replace

	gen double coc_cft = .  // Initialize variable for the cost of capital of a non-refundable CIT

* Define local parameters
	local tolerance = 0.0001  				// How close to zero we need to get economic rent
	local max_iter = 1000      				 // Maximum number of iterations

* Get unique IDs
	levelsof id_e, local(id_list)

* Create a temporary file to store results
	tempfile cft_results
	save `cft_results', emptyok  // Start with an empty file for results

* Loop through each ID
foreach id in `id_list' {
    * Load the original data copy for each ID
    use `metr_norefund', clear
    
    * Restrict data to the current id
    quietly keep if id == `id'
    
    * Set initial values
    local p = `r'			  	 // Initial guess for cost of capital
    local iter = 0    			// Iteration counter

    * Initialize ptilde_cit for this specific id
    gen double coc_cft = . 

* Begin the iterative process
while `iter' < `max_iter' {

	
		
	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + rho) ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	

	gen 		double profit_cft=0
	replace		profit_cft=(`p'+`delta')*(1+`inflation')-1			if t==1
	replace		profit_cft=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)+min(0,profit_cft[_n-1])			if t>1
	
	la var 		profit_cft  "profit under a refundable cahsflow tax"
    
	gen  		double		Tax_cft=0
	replace					Tax_cft =(`taxrate')*max(profit_cft,0) -QRTC-min((`taxrate')*max(profit_cft,0),NQRTC)	if `holiday_v'==0		
	// period by period tax liability (if taxable income is negative, then tax is zero (i.e., no-refund))   

	replace					Tax_cft =-QRTC	if  t<=`holiday_v'	& `holiday_v'>0	
	replace					Tax_cft =(`taxrate')*max(profit_cft,0) -QRTC-min((`taxrate')*max(profit_cft,0),NQRTC)	if t>`holiday_v' & `holiday_v'>0		

    gen  		double		Tax_cft_time= Tax_cft/((1 + rho) ^ t)										// The discounted value of each peruiod's tax liability
    egen 		double 		Tax_cft_NPV= total(Tax_cft_time)											// NPV of the the sum of taxes paid
   
/*=========================
Second, the top-up tax
=========================*/
	
	gen 		double profit_cft_tpt=0																// covered tax for GloBE purposes. Since immediate expensing is a timing issue, the covered tax and top-up rate look similar to the case of a standard CIT financed with equity
	gen 		double cov_profit_cft=0															// covered tax for GloBE purposes. Since immediate expensing is a timing issue, the covered tax and top-up rate look similar to the case of a standard CIT financed with equity
	
**Declining balance
	
	replace		profit_cft_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation')    if t==1 & `deprtype'=="db"
	replace		profit_cft_tpt=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t  + min(0,profit_cft_tpt[_n-1])  if t>1 & `deprtype'=="db"
	la var 		profit_cft_tpt "the profit base for the covered tax"  
	
	replace		cov_profit_cft=(1+`inflation')*(`p'+`delta')-`depreciation'-`depreciation'*(1-`depreciation')-`debt_v'*i + QRTC    if t==1 & `deprtype'=="db"
	replace		cov_profit_cft=(1+`inflation')^t*(`p'+`delta')*(1-`delta')^(t-1)-`depreciation'*(1-`depreciation')^t -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,cov_profit_cft[_n-1]) + QRTC if t>1 & `deprtype'=="db"
	la var 		cov_profit_cft  "covered tax of a cashflow tax under GlOBE: declining balance depreciation"

	
	
**Straight line	
	replace		profit_cft_tpt=(1+`inflation')*(`p'+`delta')-`depreciation'-min(max(1-`depreciation',0),`depreciation')    if t==1 & `deprtype'=="sl"
	replace		profit_cft_tpt=((1+`inflation')^t)*(`p'+`delta')*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation')  + min(0,profit_cft_tpt[_n-1])  if t>1 & `deprtype'=="sl"
	la var 		profit_cft_tpt "the profit base for the covered tax"  
	
	replace		cov_profit_cft=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')-`debt_v'*i + QRTC   if t==1 & `deprtype'=="sl"
	replace		cov_profit_cft=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)-min(max(1-t*`depreciation',0),`depreciation') -`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,cov_profit_cft[_n-1]) + QRTC if t>1 & `deprtype'=="sl"
	la var 		cov_profit_cft  "covered tax of a cashflow tax under GlOBE: declining balance depreciation"

	
	gen			double exprofit_cft=max(0,cov_profit_cft-SBIE)
	la var 		exprofit_cft  "Excess profit under refundable cashfolow tax: GloBE declining balance depreciation"
	
	gen 		covtax_cft=0										// covered tax
	replace 	covtax_cft=(`taxrate')*max(0,profit_cft_tpt)-min((`taxrate')*max(0,profit_cft_tpt),NQRTC) if `holiday_v'==0
	replace 	covtax_cft=(`taxrate')*max(0,profit_cft_tpt)-min((`taxrate')*max(0,profit_cft_tpt),NQRTC) if t>`holiday_v' & `holiday_v'>0
	
	gen	double	tpr_cft=max(0,`minrate'-(covtax_cft)/cov_profit_cft)	    if cov_profit_cft>0													
	la var 		tpr_cft "Top up tax rate under R based cashflow tax"

	gen 		double tpt_cft=tpr_cft*exprofit_cft/((1+rho)^t)			// top-up tax (discounted value) 
	egen 		double total_tpt_cft=total(tpt_cft)

	gen 		double 		econrent_cft=gamma*(revenue_NPV-1-Tax_cft_NPV-total_tpt_cft)+  `newequity_v'*(gamma-1)+ `debt_v'*gamma*( rho-i)/(rho-`inflation'+`delta'*(1+`inflation'))  		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR


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
    drop revenue revenue_time revenue_NPV profit_cft profit_cft_tpt Tax_cft Tax_cft_time Tax_cft_NPV cov_profit_cft exprofit_cft covtax_cft tpr_cft tpt_cft  total_tpt_cft econrent_cft			// to allow for the next iteration
	}																				// closing the iternation


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}

    replace coc_cft= `p'    

	gen double METR_CFT= 100*(coc_cft-`r')/ coc_cft

	replace	coc_cft=100*coc_cft

if id!=1{
	append using `cft_results'  // Append results for this id
	}
    save `cft_results', replace  // Save the updated results
}
drop		t i  gamma rho A_decline A_straight SBIE QRTC NQRTC
duplicates 	drop
la var		coc_cft 				"The cost of capital of a cashflow tax"
la var		METR_CFT				"Marginal effective tax rate of a cashflow tax system"

format 		METR* %9.03f
format 		coc* %9.03f
tempfile 	cft_results
save		`cft_results', replace
} 



***ACE

if  "`system'"=="ace" {
	

tempfile metr_norefund
save `metr_norefund', replace

gen double coc_ace = .  // Initialize variable for the cost of capital of a non-refundable CIT

* Define local parameters
local tolerance = 0.0001  // How close to zero we need to get economic rent
local max_iter = 1000       // Maximum number of iterations

* Get unique IDs
levelsof id, local(id_list)

* Create a temporary file to store results
tempfile ace_results
save `ace_results', emptyok  // Start with an empty file for results

* Loop through each ID
foreach id in `id_list' {
    * Load the original data copy for each ID
    use `metr_norefund', clear
    
    * Restrict data to the current id
    quietly keep if id == `id'
    
    * Set initial values
    local p = `r'			    // Initial guess for cost of capital
    local iter = 0    			// Iteration counter

    * Initialize ptilde_cit for this specific id
    gen double coc_ace = . 
* Begin the iterative process
while `iter' < `max_iter' {

* Calculate the economic rent (the difference between the pre-tax value and the tax paid) based on the current value of p

/*=====================
First, the pre-top-up tax (we use the same for debt and equity finance becasue they are equivalent)
======================*/
	
	gen 		double 		revenue=0 				 												
	replace			 		revenue=0	 													if t==0 	// revenue in period 0 
	replace					revenue=(`p'+`delta')*((1+`inflation')^t)*(1-`delta')^(t-1)     if t>0		// revenue in period t>0 	
	gen  		double		revenue_time=revenue/((1 + rho) ^ t)										// discounted value of revenue
	egen 		double 		revenue_NPV= total(revenue_time)	

	gen 		double profit_ace=0 
	gen 		double cov_profit_ace=0
**Declining balance

	replace		profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation')-i*(1-`depreciation')         if t==1  & `deprtype'=="db"      // i*(1-phi) is the allowance for corporate equity
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-i*(1-`depreciation')^t + min(0,profit_ace[_n-1])  if t>1 & `deprtype'=="db"
	la 			var profit_ace "profit under non-refundable ACE and declining balance depreciation"

	****for the top-up tax
	replace		cov_profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-`depreciation'*(1-`depreciation') -`debt_v'*i + QRTC      if t==1  & `deprtype'=="db"   
	replace		cov_profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-`depreciation'*(1-`depreciation')^t-`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,cov_profit_ace[_n-1]) + QRTC  if t>1 & `deprtype'=="db"
	la 			var cov_profit_ace "covered tax under non-refundable ACE"


**Straight line

	replace		profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation')- i*max(1-`depreciation',0)        if t==1 & `deprtype'=="sl"    // i*(1-phi) is the allowance for corporate equity
	replace		profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-i*max(1-t*`depreciation',0) + min(0,profit_ace[_n-1])  if t>1 & `deprtype'=="sl"
	la 			var profit_ace "profit under non-refundable ACE"

	****for the top-up tax
	replace		cov_profit_ace=(`p'+`delta')*(1+`inflation')-`depreciation'-min(max(1-`depreciation',0),`depreciation') -`debt_v'*i + QRTC      if t==1 & `deprtype'=="sl"    
	replace		cov_profit_ace=(`p'+`delta')*((1+`inflation')^t)*((1-`delta')^(t-1))-min(max(1-t*`depreciation',0),`depreciation')-`debt_v'*i*((1+`inflation')*(1-`delta'))^(t-1) + min(0,cov_profit_ace[_n-1]) + QRTC  if t>1 & `deprtype'=="sl"
	la 			var cov_profit_ace "covered tax under non-refundable ACE"

	gen  		double		Tax_ace=0
	replace					Tax_ace=(`taxrate')*max(profit_ace,0) -QRTC-min((`taxrate')*max(profit_ace,0),NQRTC)	if `holiday_v'==0		
	// period by period tax liability (if taxable income is negative, then tax is zero (i.e., no-refund))   
	
	replace					Tax_ace=-QRTC	if t<=`holiday_v' & `holiday_v'>0	
	replace					Tax_ace=(`taxrate')*max(profit_ace,0) -QRTC-min((`taxrate')*max(profit_ace,0),NQRTC)	if t>`holiday_v' & `holiday_v'>0		

	gen  		double		Tax_ace_time = Tax_ace/((1 + rho) ^ t)								// The discounted value of each peruiod's tax liability
	egen 		double 		Tax_ace_NPV = total(Tax_ace_time)									// NPV of the the sum of taxes paid

/*====================    
Second, the top-up tax
======================*/	
*Calculate the top-up tax base (note that the top-up tax base is the accounting profit (not including the tax credit) minus SBIE.)
	
	gen 		double exprofit_ace=max(0,cov_profit_ace-SBIE)

	gen 		covtax_ace=0										// covered tax
	replace 	covtax_ace=(`taxrate')*max(0,profit_ace)-min((`taxrate')*max(0,profit_ace),NQRTC) if `holiday_v'==0
	replace 	covtax_ace=(`taxrate')*max(0,profit_ace)-min((`taxrate')*max(0,profit_ace),NQRTC) if t>`holiday_v' & `holiday_v'>0
	
	gen	double	tpr_ace=0
	replace 	tpr_ace=max(0,`minrate'-(covtax_ace)/cov_profit_ace)	    if cov_profit_ace>0													//the top-up tax in each period for each value of the tax rate
	la var 		tpr_ace "Top up tax rate under a non-refundable ACE"

	gen 		double tpt_ace=tpr_ace*exprofit_ace/(1+rho)^t	  // top-up tax (discounted value) (nothe: the excess profit is similar to the excess profit value under the standard CIT)
	egen 		double total_tpt_ace=total(tpt_ace)	
	
	
	
/*=========================
Third, define economic rent and check if economic rent is close enough to zero 
=========================*/	
		gen 		double 		econrent_ace=gamma*(revenue_NPV-1-Tax_ace_NPV-total_tpt_ace)+  `newequity_v'*(gamma-1)+ `debt_v'*gamma*(rho-i)/(rho-`inflation'+`delta'*(1+`inflation')) 		// Econonmic rent. The economic retun that reuslts in zero economic rent is the basis for METR


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
    drop revenue revenue_time revenue_NPV profit_ace Tax_ace Tax_ace_time Tax_ace_NPV cov_profit_ace exprofit_ace covtax_ace tpr_ace tpt_ace total_tpt_ace econrent_ace 				// to allow for the next iteration
	}


* Display results if maximum iterations reached without converging
if `iter' == `max_iter' {
	local p_formatted: display %9.5f `p'
    display "Maximum iterations reached without convergence. Last p`taxrate' = " `p_formatted'
}

    replace 	coc_ace = `p'   
	gen			METR_ACE= 100*(coc_ace-`r')/coc_ace
	replace		coc_ace=100*coc_ace	

	if id!=1{
	append using `ace_results'  // Append results for this id
	}
    save `ace_results', replace  // Save the updated results
}
drop		t i  gamma rho A_decline A_straight SBIE QRTC NQRTC
duplicates 	drop
la var 		coc_ace  			"The cost of capital of an ACE system"
la var 		METR_ACE	 		"Marginal tax rate of an ACE system"

format 		METR* %9.03f
format 		coc* %9.03f
tempfile 	ace_results
save		`ace_results', replace

}
}																				// closing the minimum tax==yes and refund==no routine
																				


merge 1:1 id_e using `aetr'
drop	_m id_e
}																				// closing the quitely part





********************
if "`minimumtax'"=="yes" {
	
matrix parameters= J(5, 1,.)  // Create a 2x1 matrix
matrix parameters[1, 1] = 100*`profit'
matrix parameters[2, 1] = 100*`sbie'
matrix parameters[3, 1] = `qrtc'
matrix parameters[4, 1] = `nqrtc'
matrix parameters[5, 1] = 100*`minrate'

matrix rownames parameters ="Profitability (%)" ///
							"SBIE (%)" "QRTC (%)" "NQRTC (%)" ///
							"The minimum tax rate (%)"

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

matrix parameters= J(1, 1,.)  // Create a 2x1 matrix
matrix parameters[1, 1] = 100*`profit'

matrix rownames parameters ="Profitability (%)" 
							
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

