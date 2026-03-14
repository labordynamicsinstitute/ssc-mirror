/********************************************
DRAFT Package: TEN-SPIDERS Medication Adherence
Version: 0.2 (beta - in development - shared in confidence)
Authors: Kuo E, Livori A, Morton J, Dalli LL
© Copyright Monash University 2025 
Correspondence: lachlan.dalli@monash.edu
*********************************************/ 



/// Move to the working directory
capture program drop tenspiders
program define tenspiders

	version 10
	
	//set trace on
	
	syntax [using/] [if] [,id(string) supply_date(string) event_date(string) death_date(string) days_supply(string) drug_id(string) drug_strength(string) threshold(real 0.8) elig_survival(real 0) elig_min(real 0) numerator_start_date(real 1) denominator_days(real 365) survival(real 1) presupply(real 60) inhospital_supply(real 0) dosing(real 0) early_refills(real 1) switching(real 0) hospital_data(string)]
	
	
	
	/**Display Command Settings**/
	di "	                  ("
	di "                      )"
	di "	              /\(o_o)/\"
	di "	             /  |   |  \"
	di "                /   |   |   \"
    di "=============== TEN-SPIDERS Setting ==============="
    di as text "{bf:Threshold}: `threshold'"
	di as text "{bf:Eligibility}: ""Excluded patients who died in `elig_survival' days"
	di as text "             Number of supplies included: `elig_min'"
	
	
	if `numerator_start_date' == 0 {
		di as text "{bf:Numerator}: ""Date of discharge is set as start date"	
	} 
	else {
		di as text "{bf:Numerator}: ""Date of first dispensing is set as start date"	
	}
	
	di as text "{bf:Denominator}: ""Follow-up period window: `denominator_days'"
	
	if `survival' == 1 {
		di as text "{bf:Survival}: ""End dates are adjusted to death date"	
	} 
	else {
		di as text "{bf:Survival}: ""End dates are set to include the full follow-up window"	
	}	
	
	di as text "{bf:Pre-supply}: ""`presupply' Look back days"
	
	if `inhospital_supply' == 0 {
		di as text "{bf:In-hospital supply}: ""No adjustment for periods of hospitalisation"	
	} 
	else if `inhospital_supply' == 1 {
		di as text "{bf:In-hospital supply}: ""Adjustment for periods of hospitalisation (assumed to be covered)"	
	}	
	else {
		di as text "{bf:In-hospital supply}: ""Exclude periods of hospitalisation from follow-up (numerator and denominator)"	
	}
	
	if `dosing' == 0 {
		di as text "{bf:Dosing}: ""No imputation of doses. Days supplied variable provided."	
	} 
	else {
		di as text "{bf:Dosing}: ""Imputation of doses. Days supply field derived based on percentile of fill dates"
	}
	
	if `early_refills' == 1 {
		di as text "{bf:Early Refills}: ""Adjustment for early refills"	
	} 
	else {
		di as text "{bf:Early Refills}: ""No adjustment for early refills"	
	}	
	
	if `switching' == 1 {
		di as text "{bf:Switching}: ""Adjustment for medication switching during follow-up"	
	} 
	else {
		di as text "{bf:Switching}: ""No adjustment for medication switching during follow-up"	
	}	

	
	if "`using'" != ""{
		noisily display " "
		noisily display " "
		noisily display "=========== Loading TEN-SPIDERS dataset ==========="
		noisily display "Dataset " `"`using'"' " loaded successfully"
	}
 	
	/**ERROR Messages**/	
	
	
	if "`id'" == ""{
	    noisily display as error "missing variable id (Patient ID)"
		exit 198
	}
	
	if "`supply_date'" == ""{
	    noisily display as error "missing variable supply_date (Supply Date)"
		exit 198
	}
	
	
	if `dosing' == 0 {
	    if "`days_supply'" == ""{
		    noisily display as error "Dosing is set to 0%. The variable days_supply (Days Supply) must be specified." _n "Otherwise specify the dosing percentage."
			exit 198
		}
	}
	
	
	if `dosing' > 0 {
	    if "`drug_id'" == ""{
		    noisily display as error "Dosing `dosing'% - missing variable drug_id (Drug Identifier)"
			exit 198
		}
	}
	
	if `dosing' > 0 {
	    if "`drug_strength'" == ""{
		    noisily display as error "Dosing `dosing'% - missing variable drug_strength (Drug Strength)"
			exit 198
		}
	}
	
	
	if `switching' == 1 {
	    if "`drug_id'" == ""{
		    noisily display as error "Switching is on - missing variable drug_id (Drug Identifier)""
			exit 198
		}
	}
	
	if  `numerator_start_date' == 0{
		if "`event_date'" == ""{
			noisily display as error "missing variable event_date (Event Date)"
			exit 198
		}
	}	
	
	if (`survival' == 1 | `elig_survival' > 0){
		if "`death_date'" == ""{
			noisily display as error "Data was set only up to the date of death, missing variable death_date (Death Date)"
			exit 198
		}	
	} 
	
	
	
	if (`threshold' < 0 | `threshold' > 1) {
        noisily display as error "Threshold must be between 0 and 1"
        exit 198
    }
	
	if (`numerator_start_date' != 0 & `numerator_start_date' != 1) {
        noisily display as error "start date must be 0 or 1. start_date = 0 will change start date to the date of discharge"
        exit 198
    }
	
	
	if (`survival' != 0 & `survival' != 1) {
        noisily display as error "end date must be 0 or 1. end_date = 0 includes the full follow-up window"
        exit 198
    }
	
	if (`early_refills' != 0 & `early_refills' != 1) {
        noisily display as error "Early Refills must be 0 or 1"
        exit 198
    }

	if (`switching' != 0 & `switching' != 1) {
        noisily display as error "Switching must be 0 or 1"
        exit 198
    }
	
	
	if (`inhospital_supply' != 0 & `inhospital_supply' != 1 & `inhospital_supply' != 2) {
        noisily display as error "end date must be 0, 1, or 2."
        exit 198
    }
	
	if (`inhospital_supply' != 0 ) {
		if ("`hospital_data'" == ""){
			noisily display as error "Missing hospital_data (hospitalisation data)"
			exit 198
		}
    }
	
	
	if ("`varlist'" != ""){
		summarize `varlist'
	}

	/** Main Code **/

	*Create output table
	
	di " "
	di as result "================== Calculating =================="
quietly {
	
	if "`using'" != "" {
		use `"`using'"', clear
	}
	
	if "`if'" != "" {
		keep `if'
	}
	
	if `dosing' == 0 {
	    rename `days_supply' dayssupply
	} 


	*Decision for start date and end date (study period)
	if `numerator_start_date' == 0 {
	gen startdate = `event_date'
	format startdate %td
	drop if `supply_date' <= startdate- `presupply' //Removes dispensings prior to the pre-specified start date with look back included
	noisily di "Start date based on separation date"
	}

	if `numerator_start_date' == 1 {
		
	capture gen minsupply = 1 if `supply_date' >= `event_date' //take first dispensing post-discharge if event_date variable specified
	capture gen minsupply = 1 
	sort `id' minsupply (`supply_date'), stable
	by `id' minsupply (`supply_date') : gen nghost = _n if minsupply==1
	sort `id' nghost, stable
	by `id' : egen startdate = min(`supply_date') if nghost == 1
	format startdate %td
	sort `id' startdate, stable
	by `id': replace startdate = startdate[_n-1] if startdate==.
	drop nghost
	noisily di "Start date based on first dispensing"
	}
	
	*Decision for inclusions
	if `elig_survival' == 0 {
	noisily di "Included individuals regardless of date of death"
	}
	if `elig_survival' > 0 {
	drop if `death_date' <= startdate + `elig_survival'
	noisily di "Included individuals who survived at least `elig_survival' days"
	}

	if `elig_min' == 0 {
	noisily di "Included individuals regardless of number of dispensings"
	}

	if `elig_min' > 0 { //Removes individuals with less than the pre-specfied number of dispensings required for inclusion
	quietly {
	sort `id', stable 
	by `id' : gen nghost = _N
	drop if nghost < `elig_min'	
	drop nghost
	}
	noisily di "Included individuals with at least `elig_min' number of dispensings"
	}


	*Generate end date based on duration of follow up from start date
	gen enddate = startdate + `denominator_days'
	format enddate %td
	drop if `supply_date' > startdate + (`denominator_days' + 1) //Drop dispensing after the study period


	*Correct study period end dates for participants who died prior to the follow up period. 
	if `survival' == 0 {
	noisily di "Did not truncate based on date of death"
	}

	if `survival' == 1 {
	noisily di "Truncated based on date of death"
	replace enddate = `death_date' if `death_date' <= enddate & `death_date' >= startdate
	drop if `supply_date' >= `death_date'
	}


	*Calculate number of days in the study period 
	gen study_days = enddate - startdate
	replace study_days = . if study_days == 0 //This will remove people who died at the start of the observation period and therefore would have no study days, therefore no denominator. If total cohort needs to be included, then consider merging people back in, and if no PDC is matched, then make it 0. 


	*Generate supply day duration of refills 

	if `dosing' == 0 { //No imputation required
	noisily di "No dose imputation used"
	}

	if `dosing' > 0 {
	noisily di "Dose imputation used"
	egen medgroup = group(`drug_id')
	ta medgroup
	sort `id' `drug_strength' (`supply_date'), stable 
	by `id' `drug_strength' (`supply_date') : gen nghost= _n
	by `id' `drug_strength' (`supply_date'): gen fill_diff = `supply_date'[_n+1] - `supply_date'
	sort medgroup, stable
	by medgroup : egen p`dosing'  = pctile(fill_diff), p(`dosing') //This value can be changed to a different percentile depending on your application
	ta p`dosing'
	gen dayssupply = p`dosing'
	drop nghost medgroup fill_diff p`dosing' 
	}


	*Look at number of dispensings across cohort for medication class

	sort `id' (`supply_date'), stable
	by `id' (`supply_date'): gen nghost=_n 
	su(nghost)
	global max = r(max) //This locks in the maximum number of dispensings completed for one individual to ensure the loop below captures all dispensings. 

	drop nghost



	*Look back to adjust for pre-supply

	if `presupply' == 0 {
	noisily di "No pre-supply considered"
	drop if `supply_date' < startdate
	}


	if `presupply' > 0 {
	noisily di "Pre-supply considered using a `presupply day' lookback"
	sort `id' (`supply_date'), stable
	gen pre_supply=1 if `supply_date'<startdate

	gen pre_supply_end= `supply_date'+dayssupply if pre_supply==1
	format pre_supply_end %td

	gen surplus= startdate - pre_supply_end
	drop if surplus>=0 & surplus!=.

	replace dayssupply = -(surplus) if pre_supply==1

	replace `supply_date'=startdate if pre_supply==1

	drop pre_supply pre_supply_end surplus
	}

	*Set up switching and early refills
	sort `id' (`supply_date'), stable
	by `id' (`supply_date') : gen covered = `supply_date'+dayssupply if _n == 1
	format covered %td


	*Early refill adjustment
	if `early_refills' == 0 {
	noisily di "No correction for early refills"
	gen mod_supplydate = .
	format mod_supplydate %td
	
	replace covered = `supply_date'+dayssupply
	}


	if `early_refills' == 1 {
	noisily di "Correction for early refills"
	gen mod_supplydate = .
	format mod_supplydate %td
	gen switch_flag=.
	
	quietly{
	quietly forval ii = 2/$max {
	sort `id' (`supply_date'), stable
	by `id' (`supply_date') : replace covered = max(covered[_n-1]+dayssupply,`supply_date'+dayssupply) if _n == `ii'


	if `switching' == 1 {
	sort `id' (`supply_date'), stable
	by `id': replace switch_flag = 1 if `drug_id'!=`drug_id'[_n-1] & `id'==`id'[_n-1]

	quietly di "Switching adjusted for"
	by `id': replace covered = `supply_date'[_n+1] if switch_flag[_n+1] == 1 & _n == `ii'
	}

	if `switching' == 0 {
	quietly di "Switching not adjusted for"
	}
	
	by `id' (`supply_date'): replace mod_supplydate = covered - dayssupply if _n == `ii'	
	
	}
	}
	}

	replace mod_supplydate = `supply_date' if mod_supplydate == .


	*Create tracking data for PDC
	global day_before = `denominator_days'-1
	noisily di "`day_before'"
	sort `id' mod_supplydate, stable 

	forval i = 1/`denominator_days' {
	quietly gen day`i' =.
	}

	gen script_count = $max

	gen new_start_date = mod_supplydate-startdate
	replace new_start_date= new_start_date+1
	gen new_end_date = new_start_date + dayssupply
	replace new_end_date= new_end_date

	*Flag start date for each supply with a 1
	quietly forval i = 1/`denominator_days' {
	quietly replace day`i'=1 if new_start_date==`i'
	}

	*Carry 1's forward
	quietly forval i = 1/$day_before {
	local nextday = `i'+1
	quietly replace day`nextday'=1 if day`i'==1
	}

	*Flag end date for each supply with a 0
	quietly forval i =  1/`denominator_days' {
	quietly replace day`i'=0 if new_end_date==`i'
	}

	*Carry 0's forward
	quietly forval i = 1/$day_before {
	local nextday = `i'+1
	quietly replace day`nextday'=0 if day`i'==0
	}

	*Carry over values
	quietly foreach var of varlist day* {
	sort `id' `var', stable
	quietly by `id': replace `var'= `var'[_n-1] if `var'==.
	}

	sort `id' (mod_supplydate), stable
	by `id' : keep if _n == _N 


	if `inhospital_supply' > 0 {
	*Include hospital admissions data

	preserve 
	quietly{
	use "`hospital_data'", clear
	sort `id' xadm xsep, stable
	by `id': gen adm_seq=_n

	egen total_adm = max(adm_seq)
	ta total_adm
	su(total_adm)
	global total_adm = r(max) 
	reshape wide xadm xsep, i(`id') j(adm_seq)
	save "hosp_data_wide", replace
	restore


	merge 1:1 `id' using "hosp_data_wide"
	drop if _merge==2
	drop _merge
	sort `id' (mod_supplydate)
	}

	quietly{
	forval i = 1/$total_adm { //This blanks out admissions that occur outside of the observation period
	replace xadm`i' = . if xadm`i' < startdate
	replace xsep`i' = . if xsep`i' > startdate & xadm`i' < startdate
	replace xsep`i' = enddate if xsep`i' > enddate 
	replace xadm`i' = . if xadm`i' > enddate & xadm`i' !=.
	replace xadm`i' =. if xsep`i' ==.
	replace xsep`i' =. if xadm`i' ==.
	}
	}

	quietly{
	forval i = 1/$total_adm {
	replace xadm`i'  = startdate if xadm`i' < startdate
	replace xsep`i' = enddate if xsep`i' > enddate & xsep`i' != .
	}
	}


	*Adjust for hospital admissions data
	local seq= 1
	quietly foreach var of varlist xadm* {
	gen adm_start_`seq'=`var'-startdate
	local ++seq 
	}

	quietly foreach i of num 1/`denominator_days' {
	quietly foreach var of varlist adm_start_*{
	quietly replace day`i'=8 if `var'==`i'
	}
	}

	local seq= 1
	quietly foreach var of varlist xsep* {
	gen adm_end_`seq'=`var'-startdate
	local ++seq 
	}

	quietly foreach i of num 1/`denominator_days' {
	quietly foreach var of varlist adm_end_*{
	quietly replace day`i'=9 if `var'==`i'
	}
	}

	quietly foreach i of num 1/$day_before {
	local nextday = `i'+1 //carry 8 through periods of hospitalisations
	quietly replace day`nextday'=8 if day`i'==8 & day`nextday'!=9
	}
	}

	if `inhospital_supply' == 1 {
	noisily di "Numerator extended to account for periods of hospitalisation (assumed to be covered)"
	quietly foreach var of varlist day* {
	replace `var'=1 if (`var'==9 | `var'==8) //assume patients adherent whilst admitted
	}
	}

	if `inhospital_supply' ==2 {
	noisily di "Periods of hospitalisation excluded from the numerator and denominator"
	quietly foreach var of varlist day* {
	replace `var'=. if (`var'==9 | `var'==8) //assume patients adherent whilst admitted
	}
	}

	if `survival' == 1 {
	quietly forval i = 1/`denominator_days' {
	quietly	replace day`i' = . if `i' > study_days
	}
	}

	egen days_covered= rsum(day1-day`denominator_days')

	*Calculate PDC

	count if days_covered < 0

	gen pdc = days_covered / study_days
	replace pdc = 1 if pdc > 1 & pdc !=.

	gen adherent = 0
	replace adherent = 1 if pdc > `threshold'

	keep `id' study_days pdc adherent days_covered study_days

	su(pdc)

	
	noisily di " "
	noisily di as result "================== PDC outcomes =================="
	noisily di "Total indivudals =" r(N)
	noisily di "Mean PDC =" r(mean)
	noisily di "Min  PDC =" r(min)
	noisily di "Max  PDC =" r(max)
	//noisily di "Mean PDC for `level' =" r(mean)
	//noisily di "Min  PDC for `level' =" r(min)
	//noisily di "Max  PDC for `level' =" r(max)

	noisily save pdc_outcomes, replace
	
	preserve 
	}
	
	
	noisily di " "
	noisily di as result "=============== TEN-SPIDERS Settings ================"
quietly {
	clear
	set obs 11
	gen A = . 
	quietly replace A = `threshold' *100 if _n == 1
	quietly replace A = `elig_survival' if _n == 2
	quietly replace A = `elig_min' if _n == 3
	quietly replace A = `numerator_start_date' if _n == 4
	quietly replace A = `denominator_days' if _n == 5
	quietly replace A = `survival' if _n == 6
	quietly replace A = `presupply' if _n == 7
	quietly replace A = `inhospital_supply' if _n == 8
	quietly replace A = `dosing' if _n == 9
	quietly replace A = `early_refills' if _n == 10
	quietly replace A = `switching' if _n == 11

	gen B = ""
	quietly replace B = "Threshold" if _n == 1
	quietly replace B = "Eligibility for inclusion (death)" if _n == 2
	quietly replace B = "Eligibility for inclusion (supply minimum)" if _n == 3
	quietly replace B = "Numerator" if _n == 4
	quietly replace B = "Denominator" if _n == 5
	quietly replace B = "Survival" if _n == 6
	quietly replace B = "Pre-supply" if _n == 7
	quietly replace B = "In-hospital supply" if _n == 8
	quietly replace B = "Dosing" if _n == 9
	quietly replace B = "Early refills" if _n == 10
	quietly replace B = "Switching" if _n == 11

	gen C = ""
	quietly replace C = string(A)

	gen D = ""
	quietly replace D = "Set to " + C + "%" if _n == 1
	quietly replace D = "All individuals included" if _n == 2 & A == 0
	quietly replace D = "Only individuals alive after " + C + " days included" if _n ==2 & A != 0
	quietly replace D = "No minimum number of supplies required for inclusion" if _n == 3 & A == 0
	quietly replace D = "A minumum of " + C + " supply required for inclusion" if _n == 3 & A == 1
	quietly replace D = "A minumum of " + C + " supplies required for inclusion" if _n == 3 & A > 1
	quietly replace D = "Start date from date of discharge" if _n == 4 & A == 0
	quietly replace D = "Start date from first dispensing" if _n == 4 & A == 1
	quietly replace D = "Follow up of " + C + " days" if _n == 5
	quietly replace D = "End of follow up not adjusted to date of death" if _n == 6 & A == 0 
	quietly replace D = "End of follow up adjusted to date of death" if _n == 6 & A == 1 
	quietly replace D = "No pre-supply accounted for" if _n == 7 & A == 0
	quietly replace D = "Pre-supply within " + C + " days of start date accounted for" if _n ==7 & A > 0
	quietly replace D = "In-hospital supply not accounted for" if _n == 8 & A == 0
	quietly replace D = "In-hospital supply assumed (in-hospital days included in numerator)" if _n == 8 & A == 1
	quietly replace D = "In-hospital time not included in numerator or denominator" if _n == 8 & A == 2
	quietly replace D = "Days supplied per refill pre-determined from dataset" if _n == 9 & A == 0
	quietly replace D = "Imputation of days supplied per refill calculated at `Dose_impute' th percentile of distribution" if _n == 9 & A > 0 
	quietly replace D = "Early refills not adjusted for (no carry-over)" if _n == 10 & A == 0
	quietly replace D = "Early refills adjusted for (carry-over included)" if _n == 10 & A == 1
	quietly replace D = "Switching within medication class assumes remaning supply completed before commencing new medication" if _n == 11 & A == 0
	quietly replace D = "Switching within medication class assumes remaning supply discarded on the day new medication supplied" if _n == 11 & A == 1

	drop A C
}
	save tenspiders_settings, replace
	
	export delimited "tenspiders_settings.csv", novar replace
	restore 
	//set trace off
end