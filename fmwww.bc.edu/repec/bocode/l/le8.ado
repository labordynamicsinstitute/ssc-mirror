***Stata Program for Life's Essential 8
*! 1.0.0 Tilahun Haregu and Marnie Downes 15 August 2024 
/* Life’s Essential 8 (le8): Stata module for calculating cardiovascular health score based on the American Heart Association’s Life’s Essential 8 metrics, from:
Lloyd-Jones DM, Allen NB, Anderson CAM, Black T, Brewer LC, Foraker RE, Grandner MA, Lavretsky H, Perak AM, Sharma G, Rosamond W; American Heart Association. Life's Essential 8: Updating and Enhancing the American Heart Association's Construct of Cardiovascular Health: A Presidential Advisory From the American Heart Association. Circulation. 2022 Aug 2;146(5):e18-e43.  
see also: https://www.heart.org/en/healthy-living/healthy-lifestyle/lifes-essential-8 */

capture program drop le8
program define le8,  rclass byable(recall)
	version 16.0
	syntax [if] , ///
		diet(varname numeric)  	/// 
		diet_measure(varname numeric)  	/// 
		physical_activity(varname numeric)    /// 
		physical_activity_measure(varname numeric)    /// 
		nicotine(varname numeric)  	///
		active_smoker_athome(varname numeric)  	///integer 0 or 1
		sleep(varname numeric) 	/// 
		bmi(varname numeric) 	/// 
		total_cholesterol(varname numeric) 	/// 
		hdl(varname numeric) 	///
		lipids_treatment(varname numeric) 	///integer 0 or 1
		fpg(varname numeric) 	///
		hba1c(varname numeric) 	///
		diabetes(varname numeric) 	/// integer 0 or 1
		sbp(varname numeric) 	///
		dbp(varname numeric) 	///
		bp_treatment(varname numeric) 	/// integer 0 or 1
		[replace]

marksample touse 
qui keep if `touse' == 1 //implements if

markout `touse' `diet' `diet_measure' `physical_activity' `physical_activity_measure' `nicotine' `active_smoker_athome' `sleep' `bmi' `total_cholesterol' `hdl' `lipids_treatment' `fpg' `hba1c' `diabetes' `sbp' `dbp' `bp_treatment'  

	qui count if `touse' 
	if r(N) == 0 error 2000 
	
	/* check to ensure binary variables contain 0 or 1 or . */
	foreach y of varlist `active_smoker_athome' `lipids_treatment' `diabetes' `bp_treatment' {
     capture assert inlist(`y', 0, 1, .)
     if c(rc) != 0 {
          display as err `"`y' is not 0/1/."'
		  exit 999
     }
}

/* drop variables if option "replace" is chosen */
	if "`replace'" != "" {
		local le8vars : char _dta[le8vars] 
			if "`le8vars'" != "" {
				foreach f of local le8vars { 
				capture drop `f' 
				}
			}
		}
	
quietly {
//diet - could be in DASH or HEI-2015 score | MEPA score | WHO guideline of fruit and veg intake
tempvar hd
gen `hd'=`diet' 
recode `hd' (95/100=100) (75/94=80)(50/74=50) (25/49=25) (1/24=0) if `hd'!=.& `diet_measure'==1 //if DASH or HEI-2015 - in percentile
recode `hd' (15/16=100) (12/14=80)(8/11=50) (4/7=25) (0/3=0) if `hd'!=.& `diet_measure' ==2 //if MEPA score is used
recode `hd' (5/max=100) (4=80) (3=60)(2=40) (1=20) (0=0) if `hd'!=.& `diet_measure'==3 //if WHO recommendation is used. 

//Physical activity 
tempvar pa
gen `pa'=`physical_activity'
recode `pa' (150/max=100) (120/149=90) (90/119=80) (60/89=60) (30/59=40) (1/29=20) (0=0) if `pa'!=. & `physical_activity_measure'==1 //if physical activity is in MVPA minutes
recode `pa' (600/max=100) (480/599=90) (360/479=80) (240/359=60) (120/239=40) (1/119=20) (0=0) if `pa'!=. & `physical_activity_measure'==2 // if physical activity is in METs

//Nicotine exposure 
tempvar nicotine_use
gen `nicotine_use'=`nicotine'
/*label define nicotine_use 1 "Never smoker" 2 "Former smoker, quit ≥5 y" 3 "Former smoker, quit 1–<5 y" 4 "Smokeless" 5 "Current smoker"
label values `nicotine_use' nicotine_use */
recode `nicotine_use' (1=100) (2=75) (3=50) (4=25) (5=0)
tempvar nicotine2
gen `nicotine2'=.
replace `nicotine2'=`nicotine_use' if `active_smoker_athome'==0      
replace `nicotine2'=`nicotine_use'-20 if `active_smoker_athome'==1&`nicotine_use'!=0

//Sleep  
tempvar sleep_health
gen `sleep_health'=`sleep'
recode `sleep_health' (0/3.99=0) (4/4.99=20) (5/5.99=40) (10/24=40) (6/6.99=70) (9/9.99=90) (7/8.99=100)

//Body Mass Index  
tempvar body_mass_index
gen `body_mass_index'=`bmi'
recode `body_mass_index' (40/max=0) (35.0/39.99999=15) (30.0/34.99999=30) (25.0/29.99999=70) (min/24.999999=100)

//Blood lipids 
tempvar non_hdl
gen `non_hdl'=`total_cholesterol'- `hdl'
recode `non_hdl' (220/max=0) (190/219=20) (160/189=40) (130/159=60) (min/129.99=100)
tempvar non_hdl2
gen `non_hdl2'=.
replace `non_hdl2'=`non_hdl'      
replace `non_hdl2'=`non_hdl'-20 if `lipids_treatment'==1&`non_hdl'!=0 //*assumption for missing data on treatment*

//Blood glucose 
tempvar blood_glucose 
gen `blood_glucose'=.
recode `blood_glucose' (.=100) if `diabetes'==0 & (`fpg'<100 |`hba1c'<5.7)
recode `blood_glucose' (.=60) if `diabetes'==0 & (`fpg'>=100 & `fpg'<126) | (`hba1c'>5.7 & `hba1c'<6.5)
recode `blood_glucose' (.=40) if `diabetes'==1 & `hba1c'<7
recode `blood_glucose' (.=30) if `diabetes'==1 & (`hba1c'>=7 & `hba1c'<=7.9)
recode `blood_glucose' (.=20) if `diabetes'==1 & (`hba1c'>=8 & `hba1c'<=8.9)
recode `blood_glucose' (.=10) if `diabetes'==1 & (`hba1c'>=9 & `hba1c'<=9.9)
recode `blood_glucose' (.=0) if `diabetes'==1 & `hba1c'>=10

//Blood pressure  
tempvar blood_pressure
gen `blood_pressure'=.
recode `blood_pressure' (.=100) if `sbp'<120 | `dbp'<80 //optimal
recode `blood_pressure' (.=75) if (`sbp'>=120 & `sbp'<=129) | `dbp'<80 //elevated
recode `blood_pressure' (.=50) if (`sbp'>=130 & `sbp'<=139) | (`dbp'>=80 &`dbp'<=89) //stage 1 hypertension
recode `blood_pressure' (.=25) if (`sbp'>=140 & `sbp'<=159) | (`dbp'>=90 &`dbp'<=99) //stage 2 hypertension
recode `blood_pressure' (.=0) if `sbp'>=160 | `dbp'>=100 //stage 3 hypertension
tempvar blood_pressure2
gen `blood_pressure2'=.
replace `blood_pressure2'=`blood_pressure' if `sbp'!=. & `dbp'!=.     
replace `blood_pressure2'=`blood_pressure'-20 if `bp_treatment'==1 & `blood_pressure'!=0 // *assumption for missing data on treatment* 

tempvar miss_score
egen `miss_score'=rowmiss(`hd' `pa' `nicotine_use2' `sleep_health' `body_mass_index' `non_hdl2' `blood_glucose' `blood_pressure2')

gen le8_diet= `hd' 
gen le8_p_activity= `pa' 
gen le8_nicotine= `nicotine2' 
gen le8_sleep= `sleep_health' 
gen le8_bmi= `body_mass_index' 
gen le8_cholesterol= `non_hdl2' 
gen le8_glucose= `blood_glucose' 
gen le8_bp= `blood_pressure2'

label var le8_diet "Life's Essential 8 - Diet"  
label var le8_p_activity "Life's Essential 8 - Physical Activity"  
label var le8_nicotine "Life's Essential 8 - Nicotine Exposure"  
label var le8_sleep "Life's Essential 8 - Sleep" 
label var le8_bmi "Life's Essential 8 - Body Mass Index" 
label var le8_cholesterol "Life's Essential 8 - Cholesterol"  
label var le8_glucose "Life's Essential 8 - Blood Glucose"  
label var le8_bp "Life's Essential 8 - Blood pressure" 

egen le8_CVH =rowmean(`hd' `pa' `nicotine2' `sleep_health' `body_mass_index' `non_hdl2' `blood_glucose' `blood_pressure2')
replace le8_CVH=. if `miss_score'>2
label variable le8_CVH "Cardiovascular Health Score"
recode le8_CVH (80/100=1 "High") (50/79.9999=2 "Moderate") (25/49.9999=3 "Low") (0/24.9999=4 "Very low"), gen(le8_CVH_cat) label(le8_CVH_cat)
label variable le8_CVH_cat "Cardiovascular Health Score categories"
drop __000*
	local le8vars le8*
	char def _dta[le8vars] "`le8vars'"  
} // close quietly loop
end
