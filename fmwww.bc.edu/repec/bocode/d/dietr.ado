/******************************************************************************* 
Title: 			ETR model ado file
Author: 		Andualem Mengistu & Shafik Hebous
Email:			amengistu2@imf.org
Date created: 	October 11, 2024
Description:	Master file for running the metr and AETR simulation
Version:		0.1.0
*******************************************************************************/	
capture program drop dietr											// To be able to run by country or group
program define dietr
version 15
    set type double

    // Declare the syntax to accept any type of variable (numeric or string) and fallback parameter values
    syntax , id(varlist) taxrate(varlist numeric) inflation(varlist numeric) depreciation(varlist numeric) delta(varlist numeric) deprtype(varlist string) ///
						[realint(varlist numeric) debt(varlist numeric) newequity(varlist numeric) holiday(varlist numeric) inal(varlist numeric) ///
						pitdiv(varlist numeric)  pitint(varlist numeric)  pitcgain(varlist numeric) ///
						qtil(real 0) qtik(real 0) sl(real 0.055) sk(real 0.055) credit(real 0)  taxcredit(real 0) carveout(real 0.05) minrate(real 0.15) ///
						p(real 0.2) superdeduction(real 0) beta(real 0.4) systemvar(varlist string) system(string) ///
						minimumtax(string)] 
	
		
		
**Note
*The following varibales are required: id(varlist) taxrate(varlist numeric) inflation(varlist numeric) depreciation (varlist numeric) delta (varlist numeric) deprtyp(varlist numeric). One can assign any variable as id, any numerical variable as taxrate, etc. 
*The following are optional variables: realint(varlist numeric) debt(varlist numeric) newequity(varlist numeric) holiday(varlist numeric) systemvar(varlist string). systemvar(varlist string) captures one system per ID (example for each country year combination)
*The following are parameters:  qrtc(real 0) nqrtc(real 0) sbie(real 150) minrate(real 0.15) p(real 0.1) system(string) minimumtax(string) refund(string)


*======= Validate variables=========================
    // Check if the `id` variable exists in the dataset
    capture confirm variable `id'
    if _rc != 0 {
        display "Error: The specified variable `id' does not exist in the dataset."
        exit 1
    }

	capture drop id_e
	capture label drop id_e 
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

	
// Tax system	

capture drop tax_system

* --- 1. If systemvar() is provided, it takes precedence ------------------------
if "`systemvar'" != "" {

    capture confirm variable `systemvar'
    if _rc {
        di as err "systemvar(`systemvar') not found."
        exit 111
    }

    gen str8 tax_system = lower(strtrim(`systemvar'))
}

* --- 2. Otherwise, use system() or default to cit ------------------------------
else {

    * Clean the system() option (if any)
    local sys_opt = lower(strtrim("`system'"))

    * If user did NOT provide system(), default to cit
    if "`sys_opt'" == "" {
        local sys_opt "cit"
    }
    else if !inlist("`sys_opt'", "cit", "cft", "ace") {
        di as err "system(`system') must be one of: cit, cft, ace."
        exit 198
    }

    * Generate constant tax_system from sys_opt
    gen str8 tax_system = "`sys_opt'"
}

label var tax_system "Tax system for this observation (cit/cft/ace)"

	
* ------------------------------------------------------------
* Checks for systemvar and deprtype (run these first)
* ------------------------------------------------------------

local haswarn 0

* ----------------------------
* 1) Hard check: systemvar and deprtype are string (if provided)
* ----------------------------
local necessary_str deprtype systemvar

foreach opt of local necessary_str {
    if "``opt''" != "" {
        foreach v of varlist ``opt'' {
            capture confirm string variable `v'
            if _rc {
                di as err "`opt' variable `v' must be string (e.g., systemvar: 'cit'/'cft'; deprtype: 'sl'/'db')."
                exit 459
            }
        }
    }
}

* ----------------------------
* 2) Hard check: systemvar has no missing values (if provided)
* ----------------------------
if "`systemvar'" != "" {
    foreach s of varlist `systemvar' {
        quietly count if missing(`s')
        if r(N) {
            di as err "systemvar variable `s' contains `r(N)' missing observation(s)."
            exit 459
        }
    }
}

* ----------------------------
* 3) Soft check: warn if deprtype missing where systemvar == "cit"
* ----------------------------
if "`systemvar'" != "" & "`deprtype'" != "" {
    foreach s of varlist `systemvar' {
        foreach v of varlist `deprtype' {
            quietly count if missing(`v') & lower(trim(`s')) == "cit"
            if r(N) {
                di as err ///
                "Warning: deprtype variable `v' has `r(N)' missing obs where `s'==""cit""."
                local haswarn 1
            }
        }
    }
}

* ----------------------------
* 3b) Hard check: deprtype values must be in allowed set (for CIT rows)
* ----------------------------
if "`deprtype'" != "" {
    foreach v of varlist `deprtype' {

        * Normalize: lower(trim())
        quietly count if tax_system=="cit" ///
            & !missing(`v') ///
            & !inlist(lower(trim(`v')), "sl", "db", "initialsl", "initialdb", "slordb")

        if r(N) {
            di as err "deprtype variable `v' has `r(N)' invalid value(s) for CIT observations."
            di as err "Allowed values: sl | db | initialSL | initialDB | SLorDB."
            exit 459
        }
    }
}


* ----------------------------
* 4) Hard check: if minimumtax=="yes", deprtype must be sl or db
* ----------------------------
if "`minimumtax'" == "yes" & "`deprtype'" != "" {

    foreach v of varlist `deprtype' {

        * (a) Optional: forbid missing deprtype under minimum tax
        quietly count if missing(`v')
        if r(N) {
            di as err "If minimumtax==yes, deprtype variable `v' cannot be missing (`r(N)' missing obs)."
            exit 459
        }

        * (b) Enforce allowed values sl/db (case-insensitive, trim whitespace)
        quietly count if !missing(`v') & !inlist(lower(trim(`v')), "sl", "db")
        if r(N) {
            di as err "If minimumtax==yes, deprtype variable `v' must be 'sl' or 'db' (found `r(N)' invalid obs)."
            exit 459
        }
    }
}

***Check for initialSL and initialDB
quietly count if "`minimumtax'" != "yes" ///
    & inlist(tax_system, "cit", "ace") ///
    & inlist(lower(trim(`deprtype')), "initialsl", "initialdb")

if r(N) & "`inal'" == "" {
    di as err "deprtype includes initialSL/initialDB for CIT or ACE rows, but inal() was not provided."
    exit 198
}

tempvar inal_v

gen double `inal_v' = 0

if "`inal'" != "" {
    capture confirm numeric variable `inal'
    if _rc {
        di as err "inal(): variable `inal' not found or not numeric."
        exit 459
    }
    replace `inal_v' = `inal'
}

* ------------------------------------------------------------
* Mandatory numeric varlists
* ------------------------------------------------------------
local necevars_num taxrate inflation depreciation delta

* --- Check numeric varlists ---
foreach var of local necevars_num {

    if "``var''" != "" {

        * Special case: depreciation can be missing outside CIT
        if "`var'" == "depreciation" {

            * If systemvar not provided, be conservative: treat missing depreciation as fatal
            if "`systemvar'" == "" {
                foreach v of varlist ``var'' {
                    quietly count if missing(`v')
                    if r(N) {
                        di as err "The `var' variable represented by `v' contains `r(N)' missing observation(s)."
                        exit 459
                    }
                }
            }
            else {
                foreach s of varlist `systemvar' {
                    foreach v of varlist ``var'' {
                        quietly count if missing(`v') & lower(trim(`s')) == "cit"
                        if r(N) {
                            di as err ///
                            "The `var' variable represented by `v' contains `r(N)' missing observation(s) where `s'==""cit""."
                            exit 459
                        }
                    }
                }
            }
        }

        * Default: all other mandatory numeric varlists cannot have missing values
        else {
            foreach v of varlist ``var'' {
                quietly count if missing(`v')
                if r(N) {
                    di as err "The `var' variable represented by `v' contains `r(N)' missing observation(s)."
                    exit 459
                }
            }
        }
    }
}

* Optional: single summary note
if `haswarn' {
    di as txt "Note: One or more deprtype variables are missing for CIT observations. Results may be incomplete for CIT rows."
}

	
	


			
*=========Assigning default values for optional variables (realint, debt, holiday)
    // Real interest rate

if "`realint'" == "" {
    local r = 0.05
    di as txt "Optional variable realint() not provided; using default r = `r'"
}
else {
    capture confirm numeric variable `realint'
    if _rc {
        // fallback (or exit with a clear error)
        local r = 0.05
        di as res "realint(): variable `realint' not found/nonnumeric; using default r = `r'"
    }
    *else {															
    *    count if `realint' < 0.0001 | `realint' > 0.20				// This part is useful if we want to impose restrictions on te rnage real interest can take (this is helpful to avoid cases such as when real interest rate is zero).
    *   if r(N) {
    *        di as err "realint(): contains observations outside [0.0001, 0.20]."
    *        exit 125
    *    }
        // Make `r' a varname holder so you can use `r' later
        local r `realint'
        di as txt "Using r = variable `r'"
    }



// Debt (Share of finance)
if "`debt'" == "" {
        local debt_v 0
        display "Optional variable 'debt' not provided; using default value: `debt_v'"
    }
	else {
    capture confirm numeric variable `debt'
	if _rc {
         //what happens if variable debt does not exist or it is not numeric
        local debt_v = 0
        di as res "debt(): Variable 'debt' does not exist or not numeric; using default value: `debt_v'""
    }
	
	else {
		//check the value of the debt variable if it exists to make sure it is in the range
		  count if `debt' < 0 | `debt' > 1 	
		  
		  if r(N) { 
		  	// If there is more than one value of debt variable outside the range
				di as err "debt(): contains observations outside the allowed range [0, 1]."
				exit 125
     }
        // Making `debt_v' a varname holder so we can use `debt_v' later
        local debt_v `debt'
        di as txt "Using debt_v = variable `debt_v'"
    }
}


capture confirm variable debt
if !_rc {
    local debt_source "var"
}
else {
    local debt_source "scalar"
}
	
	// New Eqity (share of finance)
	
if "`newequity'" == "" {
        local newequity_v 0
        display "Optional variable 'newequity' not provided; using default value: `newequity_v'"
                         }
    else {
        capture confirm numeric variable `newequity'
        if _rc  {
            local newequity_v 0
			di as res "newequity: Variable 'newequity' does not exist or not numeric; using default value: `newequity_v'""
			       }
        
        else {
			//check the value of the newequity variable if it exists to make sure it is in the range
		  count if `newequity' < 0 | `newequity' > 1 	
		  
		  if r(N) { 
		  	// If there is more than one value of debt variable outside the range
				di as err "newequity(): contains observations outside the allowed range [0, 1]."
				exit 125
		             }
			// Making `debt_v' a varname holder so we can use `debt_v' later
            local newequity_v `newequity'     
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
        capture confirm numeric variable `holiday'
        if _rc  {
			local holiday_v =0
						di as res "holiday: Variable 'holiday' does not exist or not numeric; using default value: `holiday_v'""
						}
            else {
				count if `holiday' < 0 | `holiday'> 100
				 
				 if r(N) { 
					// If there is more than one value of holiday variable outside the range
				di as err "holiday(): contains observations outside the allowed range [0, 100]."
				exit 125
							}
			
					local holiday_v `holiday'
			}	
	}
	

	



	
// Condition on: pitdiv(varlist numeric) pitint(varlist numeric) pitcgain(varlist numeric)

foreach opt in pitdiv pitint pitcgain {

    // Check if the user supplied this option
    if "``opt''" == "" {
        local `opt'_v 0
        di "Optional variable `opt' not provided; using default value: ``opt'_v''"
    }
    else {
        // Confirm the referenced variable exists
        capture confirm variable ``opt''
        if _rc == 0 {
            local `opt'_v ``opt''
            di "Using variable for `opt': ``opt''"
        }
        else {
            local `opt'_v 0
            di "Optional variable `opt' does not exist; using default value: ``opt'_v''"
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

    local profit = `p'

    // Parameter validation
    if `p' < 0 | `p' > 1 {
        display "The specified profitability value is out of the acceptable range. Acceptable range is 0 to 1"
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

 
	 if `superdeduction' < 0 | `superdeduction' > 1.5 {
        display "The specified superdeduction parameter is out of the acceptable range. Acceptable range is 0 to 1.5"
        exit 125
    }
	
	
	

    local profit = `p'

	

    quietly {    

        // Calculate necessary variables
        gen i = `r' + `inflation' + `r' * `inflation'
        		
		// Parameters based on the intereaction of PIT and CIT
		gen 		gamma=(1- `pitdiv_v')/(1-`pitcgain_v')										//((1-m_d))/((1-z)(1-c))=γ
		gen 		rho=(1- `pitint_v')*i/(1-`pitcgain_v')										//(1-m_i )i/((1-z))=ρ
		
		*replace 	`qrtc'=`qrtc'*(`r'+`delta')/(1+`r')
		*replace 	`nqrtc'=`nqrtc'(`r'+`delta')/(1+`r')

        tempfile generalparameter
        save `generalparameter', replace


************************************************
if "`minimumtax'"=="no" {	
 // Calculate profit and taxes
 
        
gen  		NPVcredit =0
replace 	NPVcredit=`credit' if `credit'>0
replace 	NPVcredit=`taxrate'*`taxcredit'	if `taxcredit'>0

 
duplicates drop id_e, force 						// Keeping only one instance per id


preserve 
 
 keep if tax_system == "cit"													// calculates the aetr for those countries with a standard cit system

    if _N  {	
 
***Calcualte the NPV of depreciation	
	
	gen Tdep = 0
	replace Tdep = 1/`depreciation' ///
    if (`deprtype'=="sl" | `deprtype'=="initialSL" | `deprtype'=="SLorDB") ///
    & `depreciation'>0 & `depreciation'<.

	gen Adep = .

* DB
	replace Adep = (`depreciation'*(1+rho)/(`depreciation'+rho)) * ///
					(((1-`depreciation')/(1+rho))^`holiday_v') ///
    if `deprtype'=="db"

* initialDB
	replace Adep = (`inal_v')*(`holiday_v'==0) ///
					+ (1-`inal_v') * ( ((`depreciation'*(1+rho)/(`depreciation'+rho)) * ///
                      (((1-`depreciation')/(1+rho))^`holiday_v')) /(1+rho) ) ///
    if `deprtype'=="initialDB"

* SL
	replace Adep = `depreciation' * ((1+rho)/rho) * ///
               max((1/(1+rho))^`holiday_v' - (1/(1+rho))^Tdep, 0) ///
			if `deprtype'=="sl"
	replace Adep = 0 if `deprtype'=="sl" & (`depreciation'==0 | missing(`depreciation'))

* initialSL
	replace Adep = (`inal_v')*(`holiday_v'==0) ///
    + (1-`inal_v') * (`depreciation'/rho) * ///
      max((1/(1+rho))^`holiday_v' - (1/(1+rho))^Tdep, 0) ///
    if `deprtype'=="initialSL"
	replace Adep = (`inal_v')*(`holiday_v'==0) if `deprtype'=="initialSL" & (`depreciation'==0 | missing(`depreciation'))

* SLorDB
	replace Adep = max((`depreciation'*(1+rho)/(`depreciation'+rho)) * (((1-`depreciation')/(1+rho))^`holiday_v'), ///
        `depreciation' * ((1+rho)/rho) * max((1/(1+rho))^`holiday_v' - (1/(1+rho))^Tdep, 0))		 if `deprtype'=="SLorDB"
	replace Adep = 0 if `deprtype'=="SLorDB" & (`depreciation'==0 | missing(`depreciation'))

	
	gen double econrent_cit=.	


 ****when holiday=0
 
	replace econrent_cit = ///
 	gamma * ( ///
        ( (1 + `inflation') * (`p' + `delta') * (1 - `taxrate') ) ///
            / ( rho - `inflation' + `delta' * (1 + `inflation') ) ///
        - 1 + `taxrate' * (Adep+ `superdeduction') ///
        + NPVcredit ///
        + `newequity_v'*(1 - `taxrate'*`depreciation') * ( (gamma - 1) / gamma ) ///
        + `debt_v' * (1 - `taxrate'*`depreciation') * ( ///
              ( rho - (1 - `taxrate') * i ) ///
              / ( rho - `inflation' + `delta' * (1 + `inflation') ) ///
          )   )     if `holiday_v'==0
	 
	 
 ****when holiday>0
 
 replace econrent_cit = ///
    gamma * ( ///
        ( (1 + `inflation') * (`p' + `delta') * ///
          ( 1 - `taxrate' *((1 - `delta')*(1 + `inflation') / (1 + rho) )^`holiday_v' ///
          ) ///
        ) / ( rho - `inflation' + `delta' * (1 + `inflation') ) ///
        - 1 ///
        + `taxrate' * Adep ///                        // A_holiday
        + `newequity_v' * ( (gamma - 1) / gamma )  /// new equity
        + `debt_v' * ( ///
              ( rho - i + `taxrate' * i * ///
                    ( (1 - `delta') * (1 + `inflation') / (1 + rho) )^`holiday_v' ///
              ) ///
              / ( rho - `inflation' + `delta' * (1 + `inflation') ) ///
          ) )    if `holiday_v' > 0


	gen aetr_cit=.
	replace aetr_cit= 100*((`p'-`r')/(`r'+`delta')-econrent_cit)/((`p')/(`r'+`delta'))

	
******************************************************		
***Cost of capital and the METR	

gen double coc_cit=.

**When tax holiday is zero
	
replace coc_cit = ( ( (1 - `taxrate'*(Adep+ `superdeduction'))- NPVcredit ///
            + `newequity_v' * (1 - `taxrate'*`depreciation') * ( (1 - gamma) / gamma ) )  ///
        * ( rho - `inflation' + `delta' * (1 + `inflation') ) ///
        - ///
        `debt_v' * (1 - `taxrate'*`depreciation') * ( rho - (1 - `taxrate') * i ) ) ///
    / ( (1 + `inflation') * (1 - `taxrate') ) ///
    - `delta'     if `holiday_v'==0
	

**When tax holiday is positive

 
replace coc_cit  = ( ((1 - `taxrate'* Adep) + `newequity_v' * (1 - gamma) / gamma ) ///
        * ( rho - `inflation' + `delta' * (1 + `inflation') ) ///
        - `debt_v' * ( rho - i ///
      + `taxrate' * i * ((1 - `delta') * (1 + `inflation') / (1 + rho) )^`holiday_v') ) ///
    / ( (1 + `inflation') * (1 - `taxrate'*((1 - `delta') * (1 + `inflation') / (1 + rho) )^`holiday_v'))  ///
    - `delta'      if `holiday_v'>0



gen 		metr_cit=100*(coc_cit-`r')/abs(coc_cit)
gen 		metr2_cit=100*(coc_cit-`r')/abs(`r')
replace		coc_cit=100*coc_cit		

drop 		Adep 	Tdep	i rho gamma NPVcredit	econrent_cit 	 
 
	
tempfile 	pre_globe_cit
save 		`pre_globe_cit', replace


}		
restore
 


***R-based cashflow tax	
	
preserve

keep if tax_system == "cft"

 if _N {

		gen double econrent_cft = ///
    (1 - `taxrate') * gamma * (((1 + `inflation') * `p' - rho + `inflation') ///
        / ( rho - `inflation' + `delta' * (1 + `inflation') ) ) ///
    + `newequity_v' * (1-`taxrate')*( gamma - 1 ) ///
    + `debt_v' * (1 - `taxrate') * gamma * ( ///
        ( rho - i ) ///
        / ( rho - `inflation' + `delta' * (1 + `inflation')))

		
gen 	aetr_cft=.
replace aetr_cft= 100*((`p'-`r')/(`r'+`delta')-econrent_cft)/(`p'/(`r'+`delta'))


gen  	coc_cft= ///
      ( (rho - `inflation') / (1 + `inflation') ) ///
    - `debt_v' * ( (rho - i) / (1 + `inflation') ) ///
    + `newequity_v' * ( ///
          ( (1/gamma) - 1 ) * (rho - `inflation' + `delta'*(1 + `inflation')) ///
          / (1 + `inflation') )
		  
		  
gen 		metr_cft=100*(coc_cft-`r')/abs(coc_cft)
gen 		metr2_cft=100*(coc_cft-`r')/abs(`r')
replace		coc_cft=100*coc_cft		

drop 		i rho gamma econrent_cft NPVcredit 		 
			

tempfile  	pre_globe_cft
save 	 	`pre_globe_cft.dta', replace

}		

restore
 		

 
***ACE
preserve

    keep if tax_system == "ace"
    if _N  {
        	
***Calcualte the NPV of depreciation	
	
gen Tdep_ace = .
replace Tdep_ace = 1/`depreciation' ///
    if inlist(`deprtype',"sl","initialSL","SLorDB") ///
    & `depreciation'>0 & `depreciation'<.

gen Adep_ace = .

* DB
replace Adep_ace = (`depreciation'*(1+rho)/(`depreciation'+rho)) ///
    if `deprtype'=="db"

* initialDB
replace Adep_ace = (`inal_v') + (1-`inal_v') * (`depreciation'/(`depreciation'+rho)) ///
    if `deprtype'=="initialDB"

* SL
replace Adep_ace = `depreciation' * ((1+rho)/rho) * max(1 - (1/(1+rho))^Tdep_ace, 0) ///
    if `deprtype'=="sl"
replace Adep_ace = 0 if `deprtype'=="sl" & (`depreciation'==0 | missing(`depreciation'))

* initialSL
replace Adep_ace = (`inal_v') + (1-`inal_v') * (`depreciation'/rho) * ///
    max(1 - (1/(1+rho))^Tdep_ace, 0) ///
    if `deprtype'=="initialSL"
replace Adep_ace = (`inal_v') if `deprtype'=="initialSL" & (`depreciation'==0 | missing(`depreciation'))

* SLorDB
replace Adep_ace = max( ///
        (`depreciation'*(1+rho)/(`depreciation'+rho)), ///
        `depreciation' * ((1+rho)/rho) * max(1 - (1/(1+rho))^Tdep_ace, 0) ///
    ) if `deprtype'=="SLorDB"
replace Adep_ace = 0 if `deprtype'=="SLorDB" & (`depreciation'==0 | missing(`depreciation'))

   
	
	
gen 		double econrent_ace=.
replace 	econrent_ace= ///
			gamma * ( ///
        ( (1 + `inflation') * (`p' + `delta') * (1 - `taxrate') ) ///
            / ( rho - `inflation' + `delta' * (1 + `inflation') ) ///
        - 1    + `taxrate' * Adep_ace ///
        +  `taxrate' * ( i * (1 - Adep_ace) / rho ) ///
        + `newequity_v' * (1 -  `taxrate'*`depreciation') * ( (gamma - 1) / gamma ) ///
        + `debt_v' * ((1 -  `taxrate'*`depreciation') * (rho - i) ///
              / ( rho - `inflation' + `delta' * (1 + `inflation') ) ///
          ) )

gen 	aetr_ace=.
replace aetr_ace= 100*((`p'-`r')/(`r'+`delta')-econrent_ace)/(`p'/(`r'+`delta'))


gen double coc_ace=.
	
replace coc_ace = ( ( (1 -  `taxrate'*Adep_ace) ///
            - ( `taxrate' * i * (1 - Adep_ace) / rho) ///
            + `newequity_v' * (1 - `taxrate'*`depreciation') * ( (1/gamma) - 1 ) ///
        ) * ( rho - `inflation' + `delta' * (1 + `inflation') ) ///
        - ///
        `debt_v' * (1 -  `taxrate'*`depreciation') * ( rho - i ) ) ///
    / ( (1 + `inflation') * (1 -  `taxrate') ) -`delta'

gen 		metr_ace=100*(coc_ace-`r')/abs(coc_ace)
gen 		metr2_ace=100*(coc_ace-`r')/abs(`r')
replace		coc_ace=100*coc_ace		


drop 		i rho gamma econrent_ace Tdep_ace Adep_ace NPVcredit  	 
			

tempfile  	pre_globe_ace
save 	 	`pre_globe_ace.dta', replace
	
}  											// closes the ace system
restore													
										// closes the minimumtax=no system.	

			
																						// closes the minimumtax==no, refund=yes part of aetr




* --- Merge results back into the full dataset ---
* ensure (id_e, t) uniquely identify rows
 
keep id_e																		// a dataset with only unique id_e
duplicates drop 

capture confirm file `pre_globe_cit'
if !_rc merge 1:1 id_e  using `pre_globe_cit', nogen

capture confirm file `pre_globe_cft'
if !_rc merge 1:1 id_e  using `pre_globe_cft', nogen 	update replace			// To make sure that the values of the cft system are retained rather than the missing values from the master data

capture confirm file `pre_globe_ace'
if !_rc merge 1:1 id_e  using `pre_globe_ace', nogen	update replace

gen double aetr	= .
gen double metr 	= .
gen double metr2 	= .
gen double coc 		= .

foreach var1 in coc metr metr2 aetr {
	foreach var2 in cit cft ace {
		capture confirm variable `var1'_`var2'
		if !_rc replace 	`var1' 	= `var1'_`var2' 		if tax_system=="`var2'"
	
	}
}

foreach var1 in coc metr metr2 aetr {
	foreach var2 in cit cft ace {
capture drop  `var1'_`var2'
	}
}

format 		aetr coc metr metr2 	%9.3f
la var 		aetr 	"AETR of the corresponding tax system (%)"
la var 		metr 	"METR of the corresponding tax system (%)"
la var 		metr2 	"METR of the corresponding tax system (%) with r as a denominator"
la var 		coc	 	"The cost of capital of the corresponding tax system (%)"

order 		id_e `taxrate' coc metr metr2 aetr


tempfile 	pre_globe
save		`pre_globe', replace
}																				



/*=========================================================================================================================================================
										Section 2: AETR under Pillar Two
===========================================================================================================================================================*/

if "`minimumtax'"=="yes" {	
 duplicates drop id_e, force
***************************************************************
***   ROWWISE — NEW AETR ENGINE FOR STANDARD CIT
***************************************************************

preserve
keep if tax_system == "cit"

if _N {

    ******************************************************************
    * 0. CREDIT TYPE — ROW BY ROW (panel-safe)
    *    Mutually exclusive by prior validation:
    *      - qtil>0 & qtik==0  => Type-L (payroll-based)
    *      - qtik>0 & qtil==0  => Type-K (depreciation/capital-based)
    *      - both zero         => none
    ******************************************************************
    gen byte credit_type = .
    replace credit_type = 0 if `qtil'==0 & `qtik'==0     // none
    replace credit_type = 1 if `qtil'>0  & `qtik'==0     // Type-L (qtil)
    replace credit_type = 2 if `qtik'>0  & `qtil'==0     // Type-K (qtik)

    ******************************************************************
    * 1. BASE PARAMETERS — ROW BY ROW
    ******************************************************************
    * Covered-income proxy (baseline, no QTI included)
    gen double X0_base = (1+`inflation')*(`p'+`delta') ///
                       + `inflation' ///
                       - (1+`inflation')*`delta' ///
                       - `debt_v'*i*(1 - `taxrate'*`depreciation')

    * PV of depreciation allowances (row-by-row)
    gen double Anpv = .
    replace Anpv = `depreciation'*(1+i)/(`depreciation'+i) if `deprtype'=="db"
    replace Anpv = (`depreciation'*(1+i)/i)*(1 - 1/((1+i)^(1/`depreciation'))) ///
        if `deprtype'=="sl" & `depreciation'>0
    replace Anpv = 0 if `deprtype'=="sl" & `depreciation'==0

    ******************************************************************
    * 2. BINDING TEST AND TOP-UP RATE — ROW BY ROW
    ******************************************************************
    * Baseline ETR test (QTI within cap excluded from ETR by construction here)
    gen double globe_ETR0 = `taxrate'    // since xi0 = X0/D0 = 1 when D0=X0_base
    gen byte   bind = (globe_ETR0 < `minrate')   // 1 if globe_ETR<`minrate' and 1 otherwise

    gen double theta = .
    replace theta = max(`minrate' - `taxrate', 0)

    ******************************************************************
    * 3. WAGE BILL PER UNIT OF CAPITAL (Z) AND EXCESS PROFIT (EX)
    *    Z differs depending on:
    *      - binding vs not binding
    *      - Type-L incentive enters via labor wedge in both regimes
    *      - Type-K does not affect labor wedge (handled as credit subtraction)
    *
    *    Wedges:
    *      NB: wedge_NB = (sl*qtil)/(1 - tau)
    *      B : wedge_B  = (theta*carveout + sl*qtil)/(1 - minrate)
    ******************************************************************
    gen double wedge_NB = .
    replace wedge_NB = (`sl'*`qtil')/(1-`taxrate') 	if credit_type==1
    replace wedge_NB = 0                            if credit_type!=1

    gen double wedge_B = .
    replace wedge_B = (theta*`carveout' + `sl'*`qtil')/(1-`minrate') if credit_type==1
    replace wedge_B = (theta*`carveout')/(1-`minrate')               if credit_type!=1

    gen double den_NB = `beta' - wedge_NB
    gen double den_B  = `beta' - wedge_B

    * Guard against near-zero denominators
    gen byte bad_den = (abs(den_NB)<1e-10 | abs(den_B)<1e-10)

    gen double ZNB = .
    replace ZNB = (1-`beta')*(`p'+`delta')/den_NB if !bad_den

    gen double ZB = .
    replace ZB  = (1-`beta')*(`p'+`delta')/den_B  if !bad_den

    * Use regime-consistent Z for EX and for Type-L PV term under binding/non-binding
    gen double Z_use = .
    replace Z_use = cond(bind==1, ZB, ZNB) if !bad_den

    gen double EX = .
    replace EX = (1+`inflation')*((`p'+`delta') - ZB*`carveout') ///
               + `inflation' - (1+`inflation')*`delta' ///
               - `debt_v'*i*(1 - `taxrate'*`depreciation') ///
               - `carveout' ///
               if !bad_den

    ******************************************************************
    * 4. PV OF INCENTIVES (paid in period 1 => /(1+inflation) only if needed)
    *
    * Type-L (payroll): INC_L = sl*qtil*Z   (Z differs NB vs B)
    * Type-K (capital/depr): INC_K = sk*qtik*delta /(1+inflation)
    ******************************************************************
    gen double INC_L_NB = .
    replace INC_L_NB = (`sl'*`qtil'*ZNB) if credit_type==1 & !bad_den

    gen double INC_L_B = .
    replace INC_L_B  = (`sl'*`qtil'*ZB)  if credit_type==1 & !bad_den

    gen double INC_K = .
    replace INC_K = (`sk'*`qtik'*`delta')/(1+`inflation') if credit_type==2

    ******************************************************************
    * 5. AETR — ROW BY ROW
    ******************************************************************
    gen double aetr_cit = .

    ******************************
    * 5A. NO TOP-UP (bind==0 OR EX<=0)
    ******************************
    replace aetr_cit = 100*(1/`p')*( ///
        (`taxrate')*( (`p'+`delta') ///
            - (`r'+`delta')*Anpv ///
            - `debt_v'*i*(1-`taxrate'*`depreciation')/(1+`inflation') ///
        ) ///
        - cond(credit_type==1, INC_L_NB, 0) ///
        - cond(credit_type==2, INC_K,    0) ///
    ) if !bad_den & (bind==0 | EX<=0)      // i.e., if the globe etr>15%, or the binding excess profit is not positive.

    ******************************
    * 5B. WITH TOP-UP (bind==1 AND EX>0)
    ******************************
    replace aetr_cit = 100*(1/`p')*( ///
        (`minrate')*(`p'+`delta') ///
        - (`r'+`delta')*Anpv*`taxrate' ///
        - `taxrate'*`debt_v'*i*(1-`taxrate'*`depreciation')/(1+`inflation') ///
        + theta*( ///
            `inflation'/(1+`inflation') ///
            - `delta' ///
            - `debt_v'*i*(1-`taxrate'*`depreciation')/(1+`inflation') ///
            - `carveout'/(1+`inflation') ///
            - ZB*`carveout' ///
        ) ///
        - cond(credit_type==1, INC_L_B, 0) ///
        - cond(credit_type==2, INC_K,   0) ///
    ) if !bad_den & bind==1 & EX>0

    label var aetr_cit "AETR under CIT (%)"
    label var bind     "1 = Pillar II binds"

    ******************************************************************
    * 6. CLEAN-UP
    ******************************************************************
    capture drop globe_ETR0 theta wedge_NB wedge_B den_NB den_B bad_den ///
                 ZNB ZB Z_use EX INC_L_NB INC_L_B INC_K X0_base credit_type Anpv rho gamma i bind

    format aetr* %9.3f

    tempfile globe_cit
    save `globe_cit', replace
}

restore


preserve
keep if tax_system == "cft"

if _N {

    ******************************************************************
    * 0. CREDIT TYPE — ROW BY ROW (panel-safe)
    *    Mutually exclusive by validation:
    *      - qtil>0 & qtik==0  => Type-L (payroll-based)
    *      - qtik>0 & qtil==0  => Type-K (depreciation/capital-based)
    *      - both zero         => none
    ******************************************************************
    gen byte credit_type = .
    replace credit_type = 0 if `qtil'==0 & `qtik'==0     // none
    replace credit_type = 1 if `qtil'>0  & `qtik'==0     // Type-L (qtil)
    replace credit_type = 2 if `qtik'>0  & `qtil'==0     // Type-K (qtik)

    ******************************************************************
    * 1. X, D, xi, baseline ETR, and top-up wedge — ROW BY ROW (CFT)
    *
    *   - Domestic CFT base X excludes interest (per your assumption)
    *   - GloBE denominator D includes interest deduction
    ******************************************************************
    gen double X0_base = (1+`inflation')*(`p'+`delta') ///
                       + `inflation' ///
                       - (1+`inflation')*`delta'

    gen double D0_base = X0_base ///
                       - `debt_v'*i*(1 - `taxrate')

    gen double xi0 = .
    replace xi0 = X0_base / D0_base if D0_base!=0

    gen double globe_ETR0 = .
    replace globe_ETR0 = `taxrate'*xi0 if !missing(xi0)

    gen byte bind = (globe_ETR0 < `minrate') if !missing(globe_ETR0)

    gen double theta = .
    replace theta = max(`minrate' - `taxrate'*xi0, 0) if !missing(xi0)

    ******************************************************************
    * 2. Wage bill per unit of capital (Z) and excess profit (EX)
    *    Mirror CIT logic:
    *      - Type-L affects labor wedge; Type-K does not
    *
    *   Wedges:
    *     NB: wedge_NB = (sl*qtil)/(1 - tau)
    *     B : wedge_B  = (theta*carveout + sl*qtil)/(1 - minrate)
    ******************************************************************
    gen double wedge_NB = .
    replace wedge_NB = (`sl'*`qtil')/(1-`taxrate') if credit_type==1
    replace wedge_NB = 0                            if credit_type!=1

    gen double wedge_B = .
    replace wedge_B  = (theta*`carveout' + `sl'*`qtil')/(1-`minrate') if credit_type==1
    replace wedge_B  = (theta*`carveout')/(1-`minrate')               if credit_type!=1

    gen double den_NB = `beta' - wedge_NB
    gen double den_B  = `beta' - wedge_B

    * Guard against division by (near) zero
    gen byte bad_den = (abs(den_NB)<1e-10 | abs(den_B)<1e-10)

    gen double ZNB = .
    replace ZNB = (1-`beta')*(`p'+`delta')/den_NB if !bad_den

    gen double ZB = .
    replace ZB  = (1-`beta')*(`p'+`delta')/den_B  if !bad_den

    * Regime-consistent Z for EX
    gen double Z_use = .
    replace Z_use = cond(bind==1, ZB, ZNB) if !bad_den & !missing(bind)

    gen double EX = .
    replace EX = (1+`inflation')*((`p'+`delta') - ZB*`carveout') ///
               + `inflation' - (1+`inflation')*`delta' ///
               - `debt_v'*i*(1-`taxrate') ///
               - `carveout' ///
               if !bad_den

    ******************************************************************
    * 3. PV incentive terms (same objects as your loop block)
    *
    * Type-L (payroll): INC_L = sl*qtil*Z   (Z differs NB vs B)
    * Type-K (capital/depr): INC_K = sk*qtik*delta /(1+inflation)
    ******************************************************************
    gen double INC_L_NB = .
    replace INC_L_NB = (`sl'*`qtil'*ZNB) if credit_type==1 & !bad_den

    gen double INC_L_B = .
    replace INC_L_B  = (`sl'*`qtil'*ZB)  if credit_type==1 & !bad_den

    gen double INC_K = .
    replace INC_K = (`sk'*`qtik'*`delta')/(1+`inflation') if credit_type==2

    ******************************************************************
    * 4. AETR — ROW BY ROW (CFT)
    *
    * Non-binding (or EX<=0): domestic CFT AETR collapses to tau*(p - r)
    * Binding: keep the structural components:
    *   - minrate*(p+delta)
    *   - subtract domestic tax value of normal return under expensing: tau*(r+delta)
    *   - add theta * (inflation/..., -delta, -interest term, -carveouts, -ZB*carveout)
    *   - subtract incentive PV terms
    ******************************************************************
    gen double aetr_cft = .

    **********************
    * 4A. NO TOP-UP (bind==0 OR EX<=0)
    **********************
    replace aetr_cft = 100*(1/`p')*( (`taxrate')*(`p' - `r') ///
        - cond(credit_type==1, INC_L_NB, 0) ///
        - cond(credit_type==2, INC_K,    0) ///
    ) if !bad_den & (bind==0 | EX<=0)   // i.e., if the globe etr>15%, or the binding excess profit is not positive.

    **********************
    * 4B. WITH TOP-UP (bind==1 AND EX>0)
    **********************
    replace aetr_cft = 100*(1/`p')*( ///
        (`minrate')*(`p'+`delta') ///
        - (`taxrate')*(`r'+`delta') ///
        + theta*( ///
            `inflation'/(1+`inflation') ///
            - `delta' ///
            - `debt_v'*i*(1-`taxrate')/(1+`inflation') ///
            - `carveout'/(1+`inflation') ///
            - ZB*`carveout' ///
        ) ///
        - cond(credit_type==1, INC_L_B, 0) ///
        - cond(credit_type==2, INC_K,   0) ///
    ) if !bad_den & bind==1 & EX>0

    label var aetr_cft "AETR under CFT (%)"
    label var bind     "1 = Pillar II binds"

    ******************************************************************
    * 5. CLEAN-UP
    ******************************************************************
    capture drop credit_type X0_base D0_base xi0 globe_ETR0 theta ///
                 wedge_NB wedge_B den_NB den_B bad_den ///
                 ZNB ZB Z_use EX INC_L_NB INC_L_B INC_K bind rho gamma i 

    format aetr* %9.3f

    tempfile globe_cft
    save `globe_cft', replace
}

restore




preserve
keep if tax_system == "ace"

if _N {

    **************************************************************
    * 0. NPV OF TAX DEPRECIATION (row-by-row)
    **************************************************************
    gen double Anpv = .
    replace Anpv = `depreciation'*(1+i)/(`depreciation'+i) ///
        if `deprtype'=="db"
    replace Anpv = (`depreciation'*(1+i)/i) * ///
        (1 - 1/((1+i)^(1/`depreciation'))) ///
        if `deprtype'=="sl"

    **************************************************************
    * 1. BASE OBJECTS: τ, X0, D_base, ACE UPLIFT U
    **************************************************************
    * statutory rate per row (e.g., taxrate variable in %)
*    gen double tau = `taxrate'

    * X0: "pure" base without interest deduction
    gen double X0 = (1+`inflation')*(`p'+`delta') ///
                    + `inflation' ///
                    - (1+`inflation')*`delta'

    * D_base: GloBE profit including interest deduction
    gen double D_base = X0 - `debt_v'*i*(1 - `taxrate'*`depreciation')

    * ACE uplift from domestic system: U = τ(1+π)(r+δ)(1−Anpv)
    gen double U = `taxrate'*(1+`inflation')*(`r'+`delta')*(1-Anpv)

    **************************************************************
    * 2. ACE TREATED AS QRTC 
    *    - ACE uplift U 
	*	-  We ignore external credit other than the ACE credit
    **************************************************************
    gen double D0_q       = .   // denominator
    gen double xi_q       = .
    gen double globe_ETR_q = .
    gen double theta_q    = .
    gen double denom_q    = .
    gen double Zden_q     = .
    gen double Z_q        = .
    gen double EX_q       = .

    * Denominator: base + ACE uplift + external QRTC
    replace D0_q = D_base + U 	if 		D_base<. 

    * ξ_q
    replace xi_q = X0 / D0_q 	if 		D0_q>0

    * GloBE ETR and θ_q
    replace globe_ETR_q = `taxrate'*xi_q 
    replace theta_q     = max(`minrate' - globe_ETR_q, 0) if D0_q>0

    * Z_q (QRTC-style)
    replace denom_q = 1 - `taxrate' - theta_q 	if D0_q>0
    replace Zden_q  = `beta' - (theta_q*`carveout')/denom_q ///
        if denom_q!=0
    replace Z_q     = (1-`beta')*(`p'+`delta')/Zden_q ///
        if Zden_q!=0

    * Excess profit EX_q: base + ACE uplift + external QRTC
    replace EX_q = (1+`inflation')*((`p'+`delta') - Z_q*`carveout') ///
                   + `inflation' - (1+`inflation')*`delta' ///
                   - `debt_v'*i*(1 - `taxrate'*`depreciation') ///
                   - `carveout' ///
                   + U                     if D0_q<.

    **************************************************************
    * 3. ACE TREATED AS NQRTC (variant 3 & 4)
    *    - ACE uplift U is NQRTC (reduces covered tax, not D)
    *    -No external qrtc or nqrtc other than the ACE credit.
    **************************************************************
    gen double D0_n        = .
    gen double xi_n        = .
    gen double globe_ETR_n = .
    gen double theta_n     = .
    gen double Zden_n      = .
    gen double Z_n         = .
    gen double EX_n        = .

    * Denominator: base + external QRTC only
    replace D0_n = D_base   if D_base<.

    * ξ_n
    replace xi_n = X0 / D0_n if D0_n>0

    * Covered tax: τ X0 − U − external NQRTC

    * GloBE ETR and θ_n
    replace globe_ETR_n = `taxrate'*xi_n-U/D0_n 	if 	D0_n>0
    replace theta_n     = max(`minrate' - globe_ETR_n, 0) if D0_n>0

    * 
    replace Zden_n = `beta' - ((`minrate' - `taxrate'*xi_n)*`carveout')/(1-`taxrate'-(`minrate'-`taxrate'*xi_n)) ///
        if D0_n<.
    replace Z_n    = (1-`beta')*(`p'+`delta')/Zden_n ///
        if Zden_n!=0

    * Excess profit EX_n: ACE uplift is NQRTC
    replace EX_n = (1+`inflation')*((`p'+`delta') - Z_n*`carveout') ///
                   + `inflation' - (1+`inflation')*`delta' ///
                   - `debt_v'*i*(1 - `taxrate'*`depreciation') ///
                   - `carveout' ///
                     if D0_n<.

    **************************************************************
    * 4. AETR: ACE AS QRTC AND ACE AS NQRTC (row-by-row)
    **************************************************************
    gen double aetr_ace_qrtc  = .
    gen double aetr_ace_nqrtc = .

    **********************
    * ACE as QRTC – no top-up
    **********************
    replace aetr_ace_qrtc = 100*(1/`p') * `taxrate'*(`p'-`r') ///
						   if (theta_q<=0 | EX_q<=0 | D0_q<=0)

    **********************
    * ACE as QRTC – with top-up
    **********************
    replace aetr_ace_qrtc = 100*(1/`p') * ( ///
        (`taxrate' + theta_q)*(`p'+`delta') ///
        - (`r'+`delta')*`taxrate' ///
        + theta_q*(`taxrate'*(`r'+`delta')*(1-Anpv) ///  ACE uplift effect
                    + `inflation'/(1+`inflation') ///
                    - `delta' ///
                    - `debt_v'*i*(1 -`taxrate'*`depreciation')/(1+`inflation') ///
                    - `carveout'/(1+`inflation')- Z_q*`carveout' ) ) ///
					if (theta_q>0 & EX_q>0 & D0_q>0)

    **********************
    * ACE as NQRTC – no top-up
    **********************
    replace aetr_ace_nqrtc = 100*(1/`p') *`taxrate'*(`p'-`r') ///
							if (theta_n<=0 | EX_n<=0 | D0_n<=0)

    **********************
    * ACE as NQRTC – with top-up
    **********************
    replace aetr_ace_nqrtc = 100*(1/`p') * ((`taxrate' + theta_n)*(`p'+`delta') ///
        - (`r'+`delta')*`taxrate' ///
        + theta_n*( `inflation'/(1+`inflation') ///
                    - `delta' ///
                    - `debt_v'*i*(1 - `taxrate'*`depreciation')/(1+`inflation') ///
                    - `carveout'/(1+`inflation')  - Z_n*`carveout')) ///
         if (theta_n>0 & EX_n>0 & D0_n>0)

    **************************************************************
    * 5. Final clean-up / output
    **************************************************************
    label var aetr_ace_qrtc  "ACE treated as QRTC – AETR (%)"
    label var aetr_ace_nqrtc "ACE treated as NQRTC – AETR (%)"


	drop EX_n Z_n Zden_n theta_n globe_ETR_n xi_n D0_n EX_q Z_q  ///
		Zden_q denom_q theta_q globe_ETR_q xi_q D0_q U D_base X0 ///
		Anpv rho gamma i 
    
	format aetr_* %9.3f

    tempfile globe_ace
    save `globe_ace', replace
}

restore


																																																// closes norefund ace				

* --- Merge results back into the full dataset ---
* ensure (id_e, t) uniquely identify rows

keep id_e																		// a dataset with only unique id_e
duplicates drop 

capture confirm file `globe_cit'
if !_rc merge 1:1 id_e  using `globe_cit', nogen

capture confirm file `globe_cft'
if !_rc merge 1:1 id_e  using `globe_cft', nogen 	update replace

capture confirm file `globe_ace'
if !_rc merge 1:1 id_e  using `globe_ace', nogen	update replace

/*
gen double AETR = .
capture confirm variable aetr_cit
if !_rc replace AETR = aetr_cit if tax_system=="cit"

capture confirm variable aetr_cft
if !_rc replace AETR = aetr_cft if tax_system=="cft"

capture confirm variable aetr_ace_qrtc
if !_rc replace AETR_qrtc = aetr_ace_qrtc if tax_system=="ace"

capture confirm variable aetr_ace_nqrtc
if !_rc replace AETR_nqrtc = aetr_ace_nqrtc if tax_system=="ace"

foreach v in aetr_cit aetr_cft aetr_ace_qrtc   {
    capture drop `v'
}

*/
tempfile	aetr
save		`aetr', replace
}																				


*===================================================================================
***Marginal Effective Tax rate including top-up.
*===================================================================================



if "`minimumtax'"=="yes"  {

use  `generalparameter', clear

duplicates drop id_e, force


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

preserve
keep if tax_system == "cit"

if _N {

    **************************************************************
    * 0. CREDIT TYPE — ROW BY ROW (qtil/qtik only; mutually exclusive)
    **************************************************************
    gen byte credit_type = .
    replace credit_type = 0 if `qtil'==0 & `qtik'==0     // none
    replace credit_type = 1 if `qtil'>0  & `qtik'==0     // Type-L (qtil)
    replace credit_type = 2 if `qtik'>0  & `qtil'==0     // Type-K (qtik)

    **************************************************************
    * 1. PV of tax depreciation allowances (Anpv) — ROW BY ROW
    **************************************************************
    gen double Anpv = .
    replace Anpv = `depreciation'*(1+i)/(`depreciation'+i) if `deprtype'=="db"
    replace Anpv = (`depreciation'*(1+i)/i) * ///
                   (1 - 1/((1+i)^(1/`depreciation'))) ///
                   if `deprtype'=="sl" & `depreciation'>0
    replace Anpv = 0 if `deprtype'=="sl" & `depreciation'==0

    **************************************************************
    * 2. Prepare temporary results file
    **************************************************************
    tempfile cit_slice
    save `cit_slice', replace

    use `cit_slice', clear
    keep id_e
    keep if 0
    gen double coc_cit    = .
    gen double metr_cit   = .
    gen double metr2_cit  = .
    gen byte   binds_cit  = .
    tempfile cit_results
    save `cit_results', replace

    **************************************************************
    * 3. Solve per-ID (panel-safe)
    **************************************************************
    use `cit_slice', clear
    levelsof id_e, local(id_list)

    foreach id of local id_list {

        use `cit_slice', clear
        keep if id_e == `id'

        * carve-out parameters (locals)
        local gL = `carveout'
        local gK = `carveout'

        **************************************************************
        * 3A. NON-BINDING CLOSED FORM (always computable)
        *     Implements the same closed form as your "inspiration" block:
        *       p_NB = P_kcredit / ((1-tau) + sl*qtil*MNB) - delta
        *     where Type-K enters as an additive PV credit INC_K.
        **************************************************************
        local tau = `taxrate'

        local wedge_NB = (`sl'*`qtil')/(1-`tau')
        local den_NB   = `beta' - `wedge_NB'

        if (abs(`den_NB') < 1e-10) {
            local p_NB = .
        }
        else {
            local MNB = (1-`beta')/`den_NB'

            * Type-K QTI (paid in period 1 -> discounted). Zero if qtik==0.
            local INC_K = (`sk'*`qtik'*`delta')/(1+`inflation')

            local P_kcredit = ///
                (`r' + `delta')*(1 - `tau'*Anpv) ///
                - `tau'*`debt_v'*i*(1 - `tau'*`depreciation')/(1+`inflation') ///
                - `INC_K'

            local p_NB = (`P_kcredit' / ((1-`tau') + (`sl'*`qtil'*`MNB'))) - `delta'
        }

        **************************************************************
        * 3B. Regime decision wrapper (as in inspiration):
        *     - If tau >= minrate => NB for sure
        *     - If tau <  minrate => compute binding candidate p_B, check EXB(p_B),
        *                           else revert to NB
        **************************************************************
        if (`tau' >= `minrate' | missing(`p_NB')) {

            local psol = `p_NB'
            local bind = 0

        }
        else {

            * --- Binding candidate (tau < tau_min) ---
            local theta  = max(`minrate' - `tau', 0)
            local denomB = 1 - `minrate'

            * Binding labor wedge (Type-L enters; Type-K does not)
            local wedge_B = (`theta'*`gL' + `sl'*`qtil')/`denomB'
            local den_B   = `beta' - `wedge_B'

            if (abs(`den_B') < 1e-10) {
                local psol = `p_NB'
                local bind = 0
            }
            else {
                local MB = (1-`beta')/`den_B'

                * Base term (same as NB but without Type-K and theta adjustment)
                local base = ///
                    (`r' + `delta')*(1 - `tau'*Anpv) ///
                    - `tau'*`debt_v'*i*(1 - `tau'*`depreciation')/(1+`inflation')

                * Constant part inside theta*(...)
                local C0 = ///
                    `inflation'/(1+`inflation') ///
                    - `delta' ///
                    - `debt_v'*i*(1 - `tau'*`depreciation')/(1+`inflation') ///
                    - `gK'/(1+`inflation')

                * Type-K PV credit (deducted regardless of binding, per your inspiration)
                local INC_K = (`sk'*`qtik'*`delta')/(1+`inflation')

                * Closed-form binding CoC
                local numB = `base' - `INC_K' + `theta'*`C0'
                local denB = `denomB' + `MB'*((`sl'*`qtil') + `theta'*`gL')

                if (abs(`denB') < 1e-10) {
                    local psol = `p_NB'
                    local bind = 0
                }
                else {
                    local p_B = (`numB'/`denB') - `delta'

                    * ZB and EX at p_B
                    local ZB  = `MB'*(`p_B' + `delta')

                    local EXB = ///
                        (1+`inflation')*((`p_B'+`delta') - `ZB'*`carveout') ///
                        + `inflation' - (1+`inflation')*`delta' ///
                        - `debt_v'*i*(1 - `tau'*`depreciation') ///
                        - `carveout'

                    * Regime selection: binding iff EXB > 0
                    if (`EXB' > 0) {
                        local psol = `p_B'
                        local bind = 1
                    }
                    else {
                        local psol = `p_NB'
                        local bind = 0
                    }
                }
            }
        }

        **************************************************************
        * 3C. Store result and append (one row per id_e)
        **************************************************************
        bysort id_e: keep if _n==1
        gen double coc_cit    = `psol'
        gen byte   binds_cit  = `bind'

        gen double metr_cit   = 100*(coc_cit - `r')/abs(coc_cit)
        gen double metr2_cit  = 100*(coc_cit - `r')/abs(`r')
        replace coc_cit = 100*coc_cit

        append using `cit_results'
        save `cit_results', replace
    }

    **************************************************************
    * 4. Load final results
    **************************************************************
    use `cit_results', clear
	drop i gamma rho credit_type Anpv binds_cit


    format coc_cit   %9.3f
    format metr_cit  %9.3f
    format metr2_cit %9.3f

    label var coc_cit    "Cost of capital – CIT (%)"
    label var metr_cit   "METR – CIT (%)"
    label var metr2_cit  "METR2 – CIT (%)"
    *label var binds_cit  "1 = Pillar II binds"

    save `cit_results', replace
}

restore


**************
preserve
keep if tax_system == "cft"

if _N {

    **************************************************************
    * 0. QTI TYPE (row-invariant within id)
    **************************************************************
    gen byte credit_type = .
    replace credit_type = 0 if `qtil'==0 & `qtik'==0     // none
    replace credit_type = 1 if `qtil'>0  & `qtik'==0     // Type-L
    replace credit_type = 2 if `qtik'>0  & `qtil'==0     // Type-K

    * CFT expensing
    gen double Anpv = 1

    tempfile cft_slice
    save `cft_slice', replace

    **************************************************************
    * 1. Prepare empty results file
    **************************************************************
    use `cft_slice', clear
    keep id_e
    keep if 0
    gen double coc_cft   = .
    gen double metr_cft  = .
    gen double metr2_cft = .
    gen byte   binds_cft = .
    tempfile cft_results
    save `cft_results', replace

    **************************************************************
    * 2. Loop over IDs (panel-safe)
    **************************************************************
    use `cft_slice', clear
    levelsof id_e, local(id_list)

    foreach id of local id_list {

        use `cft_slice', clear
        keep if id_e == `id'
        bysort id_e: keep if _n==1

        * carve-outs
        local gL = `carveout'
        local gK = `carveout'

        **************************************************************
        * 3. NON-BINDING COST OF CAPITAL (CFT, CLOSED FORM)
        **************************************************************
        local p_NB = `r'

        * Type-K subsidy (paid in t+1)
        local Kterm = (`sk'*`qtik'*`delta')/(1+`inflation')

        * Type-L non-binding adjustment
        if (`qtil' > 0) {

            local num_common = (`r'+`delta')*(1-`taxrate')
            local wedgeNB = (`sl'*`qtil')/(1-`taxrate')
            local denNB   = `beta' - `wedgeNB'

            if abs(`denNB') < 1e-10 {
                local p_NB = .
            }
            else {
                local mNB  = (1-`beta')/`denNB'
                local p_NB = (`num_common'/((1-`taxrate') + `sl'*`qtil'*`mNB')) - `delta'
            }
        }

        * Type-K only
        if (`qtik' > 0 & `qtil' == 0) {
            local p_NB = ((`r'+`delta')*(1-`taxrate') - `Kterm')/(1-`taxrate') - `delta'
        }

        **************************************************************
        * 4. BINDING FIXED-POINT ITERATION (candidate p_B)
        **************************************************************
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
            local D = `X' - `debt_v'*i*(1 - `taxrate')
            if (`D' <= 0) break

            local xi     = `X'/`D'
            local theta  = max(`minrate' - `taxrate'*`xi', 0)
            local denom1 = 1 - `taxrate' - `theta'
            if abs(`denom1') < 1e-10 break

            * Z(p)
            local wedge = (`theta'*`gL' + `sl'*`qtil')/`denom1'
            local Zden  = `beta' - `wedge'
            if abs(`Zden') < 1e-10 break

            local Z = (1-`beta')*(`p'+`delta')/`Zden'

            * QTI terms
            local Lterm = (`sl'*`qtil'*`Z')

            * Fixed-point map
            local Gnum = ///
                (`r'+`delta')*(1 - `taxrate') ///
                - `Kterm' ///
                - `Lterm' ///
                + `theta'*( ///
                      `inflation'/(1+`inflation') ///
                    - `delta' ///
                    - `debt_v'*i*(1 - `taxrate')/(1+`inflation') ///
                    - `gK'/(1+`inflation') ///
                    - `gL'*`Z' ///
                )

            local RHS = `Gnum'/`denom1' - `delta'
            local f   = `RHS' - `p'

            if abs(`f') < 1e-10 {
                local p_B = `p'
                local conv = 1
                break
            }

            * Secant + damping
            if `have_prev' {
                local denom = `f' - `f_prev'
                if abs(`denom') > 1e-10 {
                    local p_new = `p' - `f'*(`p' - `p_prev')/`denom'
                }
                else local p_new = (`p'+`p_prev')/2
                if (`f'*`f_prev'<0) local p_new = (`p'+`p_prev')/2
            }
            else {
                local p_new = `p' - 0.1*`f'/(1+abs(`f'))
            }

            local scale = max(1e-10, max(abs(`p'), abs(`p_prev')))
            if abs(`p_new' - `p') > `stepcap'*`scale' {
                local p_new = `p' + sign(`p_new'-`p')*`stepcap'*`scale'
            }

            if `p_new'< -2*`r' local p_new = -2*`r'
            if `p_new'>  2*`r' local p_new =  2*`r'

            local p_prev = `p'
            local f_prev = `f'
            local p      = `p_new'
            local have_prev = 1
            local iter = `iter' + 1
        }

        **************************************************************
        * 5. EX-POST VALIDATION OF BINDING
        **************************************************************
        local valid_bind = 0

        if (`conv') { // if the iteration has converged

            local Xb = (1+`inflation')*(`p_B'+`delta') ///
                       + `inflation' - (1+`inflation')*`delta'
            local Db = `Xb' - `debt_v'*i*(1 - `taxrate')

            if (`Db' > 0) {

                local xib    = `Xb'/`Db'
                local thetab = max(`minrate' - `taxrate'*`xib', 0)
                local denomB = 1 - `taxrate' - `thetab'

                if abs(`denomB') > 1e-10 {

                    local ZdenB = `beta' - (`thetab'*`gL' + `sl'*`qtil')/`denomB'
                    if abs(`ZdenB') > 1e-10 {

                        local Zb = (1-`beta')*(`p_B'+`delta')/`ZdenB'

                        local EXb = ///
                            (1+`inflation')*((`p_B'+`delta') - `Zb'*`gL') ///
                            + `inflation' - (1+`inflation')*`delta' ///
                            - `gL'

                        if (`thetab' > 0 & `EXb' > 0) local valid_bind = 1
                    }
                }
            }
        }

        **************************************************************
        * 6. REGIME SELECTION
        **************************************************************
        if (`valid_bind') {
            local psol = `p_B'     // If excess profit is positive and top-up rate is positive, then use the binding cost of cpaital
            local bind = 1
        }
        else {
            local psol = `p_NB'    // If either excess profit is negatvive(or zero) or the top-up rate is (negative or zero), then use the non-binding cost of cpaital
            local bind = 0
        }

        **************************************************************
        * 7. Store and append
        **************************************************************
        gen coc_cft   = `psol'
        gen binds_cft = `bind'
        gen metr_cft  = 100*(coc_cft - `r')/abs(coc_cft)
        gen metr2_cft = 100*(coc_cft - `r')/abs(`r')
        replace coc_cft = 100*coc_cft

        append using `cft_results'
        save `cft_results', replace
    }

    **************************************************************
    * 8. Final load
    **************************************************************
    use `cft_results', clear
    drop i gamma rho credit_type Anpv binds_cft

    format coc_cft metr_cft metr2_cft %9.3f
    label var coc_cft   "Cost of capital – CFT (%)"
    label var metr_cft  "METR – CFT (%)"
    label var metr2_cft "METR2 – CFT (%)"
    *label var binds_cft "1 = Pillar II binds"

    save `cft_results', replace
}

restore


**************************************************************
* COST OF CAPITAL — ACE 
**************************************************************

preserve
keep if tax_system == "ace"

if _N {

    **************************************************************
    * 0. Row-by-row building blocks
    **************************************************************
*    gen double tau = `taxrate'

    gen double Anpv = .
    replace Anpv = `depreciation'*(1+i)/(`depreciation'+i)                     if `deprtype'=="db"
    replace Anpv = (`depreciation'*(1+i)/i)*(1 - 1/((1+i)^(1/`depreciation'))) ///
                     if `deprtype'=="sl"

    * ACE uplift μ = τ (1+π)(r+δ)(1-Anpv)
    gen double U = `taxrate'*(1+`inflation')*(`r'+`delta')*(1 - Anpv)

    * classifying ACE as QRTC (cred=1) or NQRTC (cred=2)
*    gen byte credit_type = .
 *   replace credit_type = 1   // ACE always exists but may be treated differently
 *   tempvar one
 *   gen `one'=1
    * If ACE-like NQRTC interpretation: cred=2
 *   replace credit_type = 2 if `treat_as_nqrtc'==1   // you provide this flag upstream


    * scalar version (constant over ID slice)
    *local cred = cond(`treat_as_nqrtc'==1, 2, 1)

    tempfile ace_slice
    save `ace_slice', replace

    **************************************************************
    * 1. Prepare results file
    **************************************************************
    use `ace_slice', clear
    keep id_e
    keep if 0
    gen double coc_ace_qrtc  = .
    gen double coc_ace_nqrtc = .
    gen double metr_ace_qrtc = .
    gen double metr2_ace_qrtc= .
    gen double metr_ace_nqrtc= .
    gen double metr2_ace_nqrtc= .
    tempfile ace_results
    save `ace_results', replace

    **************************************************************
    * 2. Loop per-ID
    **************************************************************
    use `ace_slice', clear
    levelsof id_e, local(id_list)

    foreach id of local id_list {

        use `ace_slice', clear
        keep if id_e == `id'

        local gL = `carveout'
        local gK = `carveout'

        **************************************************************
        * 3. p0 candidates (ACE = r domestically)
        **************************************************************
        local p0_q = `r'
        local p0_n = `r'

        **************************************************************
        * 4. Compute X0, D0, ξ0, θ0, Z0, EX0 for both cases
        **************************************************************

        *****************************************
        * QRTC CASE (cred==1)
        *****************************************
        local X0_q = ///
            (1+`inflation')*(`p0_q'+`delta') + `inflation' ///
            - (1+`inflation')*`delta'

        local D0_q = `X0_q' - `debt_v'*i*(1 - `taxrate'*`depreciation') + U
        local xi0_q = `X0_q'/`D0_q'
        local theta0_q = max(`minrate' - `taxrate'*`xi0_q', 0)
        local denom0_q = 1 - `taxrate' - `theta0_q'

        local Zden0_q = `beta' - (`theta0_q'*`gL')/`denom0_q'
        local Z0_q    = (1-`beta')*(`p0_q'+`delta')/`Zden0_q'

        local EX0_q = ///
            (1+`inflation')*((`p0_q'+`delta') - `Z0_q'*`gL') ///
            + `inflation' - (1+`inflation')*`delta' ///
            - `debt_v'*i*(1 - `taxrate'*`depreciation') ///
            - `gL' ///
            + U

        local binds_q = ( `theta0_q'>0 & `EX0_q' > 0 )


        *****************************************
        * NQRTC CASE (cred==2)
        *****************************************
        local X0_n = ///
            (1+`inflation')*(`p0_n'+`delta') + `inflation' ///
            - (1+`inflation')*`delta'

        local D0_n = `X0_n' - `debt_v'*i*(1 - `taxrate'*`depreciation')
        local xi0_n = `X0_n'/`D0_n'
        local theta0_n = max(`minrate' - `taxrate'*`xi0_n' + U/`D0_n', 0)

        * NQRTC Z0 formula uses (minrate - tau)
        local Zden0_n = `beta' - ((`minrate'-`taxrate'*`xi0_n')*`gL')/(1-`taxrate'-(`minrate'-`taxrate'*`xi0_n'))
        local Z0_n    = (1-`beta')*(`p0_n'+`delta')/`Zden0_n'

        local EX0_n = ///
            (1+`inflation')*((`p0_n'+`delta') - `Z0_n'*`gL') ///
            + `inflation' - (1+`inflation')*`delta' ///
            - `debt_v'*i*(1 - `taxrate'*`depreciation') ///
            - `gL'

        local binds_n = ( `taxrate'*`xi0_n' - U/`D0_n' < `minrate' & `EX0_n' > 0 )


        **************************************************************
        * 5. Solve QRTC case (binding or not)
        **************************************************************
        local p_q = `p0_q'

        if !`binds_q' {
            local psol_q = `p0_q'
        }
        else {

            local maxiter = 500
            local stepcap = 0.5
            local p       = `p_q'
            local p_prev  = `p'
            local f_prev  = .
            local have_prev = 0
            local iter    = 0
            local conv    = 0

            while (`iter'<`maxiter' & !`conv') {

                * X(p)
                local Xq = ///
                    (1+`inflation')*(`p'+`delta') + `inflation' ///
                    - (1+`inflation')*`delta'

                * D, xi, theta
                local Dq = `Xq' - `debt_v'*i*(1 - `taxrate'*`depreciation') + U
                local xiq = `Xq'/`Dq'
                local thetaq = max(`minrate' - `taxrate'*`xiq', 0)
                local denomq = 1 - `taxrate' - `thetaq'

                * Z(p)
                local Zden_q = `beta' - (`thetaq'*`gL')/`denomq'
                local Zq = (1-`beta')*(`p'+`delta')/`Zden_q'

                * G(p)
                local Gq = ///
                    (`r'+`delta')*(1 - `taxrate'*Anpv) ///
                    - U/(1+`inflation') ///
               - `taxrate'*`debt_v'*i*(1 - `taxrate'*`depreciation')/(1+`inflation') ///
                    + `thetaq'*( ///
                        U/(1+`inflation') ///
                        + `inflation'/(1+`inflation') ///
                        - `delta' ///
                        - `debt_v'*i*(1 - `taxrate'*`depreciation')/(1+`inflation') ///
                        - `gK'/(1+`inflation') ///
                        - `gL'*`Zq' )

                local RHSq = `Gq'/`denomq' - `delta'
                local fq   = `RHSq' - `p'

                * convergence
                if abs(`fq') < 1e-10 {
                    local psol_q = `p'
                    local conv = 1
                    continue, break
                }

                * secant + fallback
                if `have_prev' {
                    local denom = (`fq' - `f_prev')
                    if abs(`denom')>1e-10 {
                        local p_new = `p' - `fq'*(`p' - `p_prev')/`denom'
                    }
                    else local p_new = (`p' + `p_prev')/2

                    if (`fq'*`f_prev' < 0) local p_new = (`p' + `p_prev')/2
                }
                else {
                    local p_new = `p' - 0.1*`fq'/(1+abs(`fq'))
                }

                * step limit
                local scale = max(1e-10, max(abs(`p'),abs(`p_prev')))
                if abs(`p_new'-`p') > `stepcap'*`scale' {
                    local p_new = `p' + sign(`p_new'-`p')*`stepcap'*`scale'
                }

                * bounds
                if `p_new'< -2*`r' local p_new=-2*`r'
                if `p_new'>  2*`r' local p_new= 2*`r'

                * shift
                local p_prev=`p'
                local f_prev=`fq'
                local p=`p_new'
                local have_prev=1
                local iter=`iter'+1
            }

            if !`conv' local psol_q = `p'
        }


        **************************************************************
        * 6. Solve NQRTC case
        **************************************************************
        local p_n = `p0_n'

        if !`binds_n' {
            local psol_n = `p0_n'
        }
        else {

            local maxiter = 500
            local stepcap = 0.5
            local p       = `p_n'
            local p_prev  = `p'
            local f_prev  = .
            local have_prev = 0
            local iter    = 0
            local conv    = 0

            while (`iter'<`maxiter' & !`conv') {

                * X(p)
                local Xn = ///
                    (1+`inflation')*(`p'+`delta') + `inflation' ///
                    - (1+`inflation')*`delta'

                * D, xi, theta
                local Dn = `Xn' - `debt_v'*i*(1 - `taxrate'*`depreciation')
                local xin = `Xn'/`Dn'
                local thetan = max(`minrate' - `taxrate'*`xin' + U/`Dn', 0)
                local denom_n = 1 - `taxrate' - `thetan'

                * Z(p)
                local Zden_n = `beta' - ((`minrate' - `taxrate'*`xin')*`gL')/(1--`taxrate'-(`minrate'-`taxrate'*`xin'))
                local Zn = (1-`beta')*(`p'+`delta')/`Zden_n'

                * G(p)
                local Gn = ///
                    (`r'+`delta')*(1 - `taxrate'*Anpv) ///
                    - U/(1+`inflation') ///
                    - `taxrate'*`debt_v'*i*(1 - `taxrate'*`depreciation')/(1+`inflation') ///
                    + `thetan'*( ///
                        `inflation'/(1+`inflation') ///
                        - `delta' ///
                        - `debt_v'*i*(1 -`taxrate'*`depreciation')/(1+`inflation') ///
                        - `gK'/(1+`inflation') ///
                        - `gL'*`Zn' ///
                    )

                local RHSn = `Gn'/`denom_n' - `delta'
                local fn   = `RHSn' - `p'

                * convergence
                if abs(`fn') < 1e-10 {
                    local psol_n = `p'
                    local conv=1
                    continue, break
                }

                * secant + fallback
                if `have_prev' {
                    local denom = (`fn' - `f_prev')
                    if abs(`denom')>1e-10 {
                        local p_new = `p' - `fn'*(`p' - `p_prev')/`denom'
                    }
                    else local p_new = (`p' + `p_prev')/2

                    if (`fn'*`f_prev' < 0) local p_new = (`p' + `p_prev')/2
                }
                else {
                    local p_new = `p' - 0.1*`fn'/(1+abs(`fn'))
                }

                * step limit
                local scale = max(1e-10, max(abs(`p'),abs(`p_prev')))
                if abs(`p_new'-`p') > `stepcap'*`scale' {
                    local p_new = `p' + sign(`p_new'-`p')*`stepcap'*`scale'
                }

                * bounds
                if `p_new'< -2*`r' local p_new=-2*`r'
                if `p_new'>  2*`r' local p_new= 2*`r'

                * shift
                local p_prev=`p'
                local f_prev=`fn'
                local p=`p_new'
                local have_prev=1
                local iter=`iter'+1
            }

            if !`conv' local psol_n = `p'
        }


        **************************************************************
        * 7. Save results
        **************************************************************
        bysort id_e: keep if _n==1

        gen coc_ace_qrtc  = `psol_q'
        gen coc_ace_nqrtc = `psol_n'

        gen metr_ace_qrtc  = 100*(coc_ace_qrtc-`r')/abs(coc_ace_qrtc)
        gen metr2_ace_qrtc = 100*(coc_ace_qrtc-`r')/abs(`r')

        gen metr_ace_nqrtc  = 100*(coc_ace_nqrtc-`r')/abs(coc_ace_nqrtc)
        gen metr2_ace_nqrtc = 100*(coc_ace_nqrtc-`r')/abs(`r')

        replace coc_ace_qrtc  = coc_ace_qrtc*100
        replace coc_ace_nqrtc = coc_ace_nqrtc*100

        append using `ace_results'
        save `ace_results', replace
    }

    **************************************************************
    * 8. Final load
    **************************************************************
    use `ace_results', clear
   	drop  i gamma rho Anpv U

	
    format coc_ace*       %9.3f
    format metr_ace*      %9.3f
	format metr2_ace*      %9.3f

    label var coc_ace_qrtc  "Cost of capital – ACE as QRTC (%)"
    label var coc_ace_nqrtc "Cost of capital – ACE as NQRTC (%)"
    save `ace_results', replace
}

restore




keep id_e																		// a dataset with only unique id_e
duplicates drop 

capture confirm file `cit_results'
if !_rc merge 1:1 id_e  using `cit_results', nogen

capture confirm file `cft_results'
if !_rc merge 1:1 id_e  using `cft_results', nogen 	update replace

capture confirm file  `ace_results'
if !_rc merge 1:1 id_e  using  `ace_results', nogen	update replace


tempfile	metr
save		`metr', replace

}																	// closing the minimumtax =yes bracket


if "`minimumtax'"=="no" {
	use `pre_globe', clear
}

if 		 "`minimumtax'"=="yes" {																
use `metr.dta', clear

merge 1:1 id_e using `aetr'

drop _m 




  }																				
}							// 	closing the quitely part



********************
if "`minimumtax'"=="yes" {
	
matrix parameters= J(7, 1,.)  // Create a 2x1 matrix
matrix parameters[1, 1] = 100*`profit'
matrix parameters[2, 1] = 100*`carveout'
matrix parameters[3, 1] = 100*`qtil'
matrix parameters[4, 1] = 100*`qtik'
matrix parameters[5, 1] = 100*`sl'
matrix parameters[6, 1] = 100*`sk'
matrix parameters[7, 1] = 100*`minrate'

matrix rownames parameters ="Profitability (%)" ///
					"Carevout (%)" "QTIL (%)" "QTIK (%)" ///
					"payroll incentive cap (%)" "Depreciation incentive cap (%)" /// 
					"The minimum tax rate (%)"

local minimumtax_text "Pillar two minimum tax applies"

tempfile paramtxt
qui {
esttab matrix(parameters)  using "`paramtxt'", replace ///
    cells("b")  noabbrev varwidth(30) noobs nonumber ///
	eqlabels(none) mlabels(,none) collabels("Parameters") ///
	alignment(c) gaps nolines  nolines  ///
	addnotes("`depr_text'" "`minimumtax_text'") 
}

type "`paramtxt'"
}


if "`minimumtax'"=="no" {

matrix parameters= J(1, 1,.)  // Create a 2x1 matrix
matrix parameters[1, 1] = 100*`profit'

matrix rownames parameters ="Profitability (%)" 

local taxparameters "Depreciation, tax rate, etc. vary by id_e"
							
local minimumtax_text "Pillar two minimum tax does not apply"

tempfile paramtxt
qui {
esttab matrix(parameters)  using "`paramtxt'", replace ///
    cells("b")  noabbrev varwidth(30) noobs nonumber ///
	eqlabels(none) mlabels(,none) collabels("Parameters") ///
	alignment(c) gaps nolines  nolines  ///
	addnotes("`depr_text'" "`taxparameters'" "`minimumtax_text'") 
}

type "`paramtxt'"
}



end