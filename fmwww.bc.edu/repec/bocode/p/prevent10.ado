*! 1.0.0 Ariel Linden 15Jun2024 

/* 	

Computes AHA 10-year risk for CVD, ASCVD, and HF, from:

Khan SS, Matsushita K, Sang Y, et al. Development and Validation of the American Heart Association 
Predicting Risk of Cardiovascular Disease EVENTs (PREVENT^TM) Equations. Circulation 2024;149:30–449.
	
*/

program prevent10, rclass
	version 13.0
	syntax [if] [in] ,  			///
		FEMale(varname numeric) 	/// integer 0 or 1
		AGE(varname numeric)    	/// 
		CHOL(varname numeric)   	///		
		HDL(varname numeric) 		///
		SBP(varname numeric)  		///
		BMI(varname numeric)  		///
		GFR(varname numeric)  		///
		ANTIhtn(varname numeric) 	/// integer 0 or 1
		STATin(varname numeric) 	/// integer 0 or 1
		SMoker(varname numeric) 	/// integer 0 or 1
		DIABetes(varname numeric) 	/// integer 0 or 1
		[INClude]
		
		
		marksample touse 
		markout `touse' `v' `female' `age' `chol' `hdl' `sbp' `bmi' `gfr' `antihtn' `statin' `smoker' `diabetes' 

		qui count if `touse' 
		if r(N) == 0 error 2000 

		/* check to ensure binary variables contain 0 or 1 */
		foreach v in `female' `antihtn' `statin' `smoker' `diabetes' {
			capture assert inlist(`v', 0, 1) if `touse' 
			if _rc { 
				di as err "`v' contains values other than 0 or 1" 
				exit 498 
			} 
		}
		
		/* drop variables that were generated in last run */
		local prevent10vars : char _dta[prevent10vars] 
		if "`prevent10vars'" != "" {
			foreach f of local prevent10vars { 
			capture drop `f' 
			}
		}

		quietly {
	
		
			********************
			* CVD - Female
			********************
			gen cvd10 = .															
			replace cvd10 = 														///
			(0.7939329 * (`age'- 55)/10)											/// centered age (Age-55)/10
			+ (0.0305239 * ((`chol' - `hdl') * 0.02586 - 3.5))						/// (TC – HDL-C) × 0.02586 (to convert to mmol/L) – 3.5			
			+ (-0.1606857 * ((`hdl' * 0.02586 - 1.3) / 0.3))						/// (HDL-C × 0.02586 (to convert to mmol/L)  – 1.3) /0.3 
			+ (-0.2394003 * (min(`sbp', 110) - 110)/20)								/// (min(SBP, 110) – 110) /20
			+ (0.3600781 * (max(`sbp', 110) - 130)/20)								/// (max(SBP, 110) – 130) /20
			+ (0.8667604 * `diabetes')												/// Diabetes (1=Yes, 0=No)
			+ (0.5360739 * `smoker')												/// Current Smoker (1=Yes, 0=No)
			+ (0.6045917 * (min(`gfr', 60) - 60) / - 15)							/// (min(eGFR, 60) – 60) / -15
			+ (0.0433769 * (max(`gfr', 60) - 90) / - 15)							/// (max(eGFR, 60)  – 90) / -15
			+ (0.3151672 * `antihtn')												/// Anti-hypertensive use
			+ (-0.1477655 * `statin')												/// statin use			
			+ (-0.0663612 * (max(`sbp', 110) - 130)/20) * `antihtn'					/// (max(SBP, 110) – 130) /20 × Antihtn
			+ (0.1197879 * ((`chol' - `hdl') * 0.02586 - 3.5)) * `statin'			/// ((TC – HDL-C) × 0.02586 – 3.5) × Statin
			+ (-0.0819715 * (`age'- 55)/10 * ((`chol' - `hdl') * 0.02586 - 3.5))	/// (age-55)/10 × ((TC – HDL-C) × 0.02586 – 3.5) 
			+ (0.0306769 * (`age'- 55)/10 * (`hdl' * 0.02586 - 1.3) / 0.3)			/// (age-55)/10 × (HDL-C × 0.02586 – 1.3) /0.3 			
			+ (-0.0946348 * (`age'- 55)/10 * (max(`sbp', 110) - 130)/20)			/// (age-55)/10 × (max(SBP, 110) – 130) /20			
			+ (-0.27057 * (`age'- 55)/10 * `diabetes')								/// (Age-55)/10 × Diabetes
			+ (-0.078715 * (`age'- 55)/10 * `smoker')								/// (Age-55)/10 × Cursmk
			+ (-0.1637806 * (`age'- 55)/10 * (min(`gfr', 60) - 60) / - 15)			/// (Age-55)/10 × (min(eGFR, 60) – 60) / -15
			+ (-3.307728 * 1)														/// constant
			if `female' == 1 & `touse'

			replace cvd10 = exp(cvd10) / (1 + exp(cvd10)) if `female' == 1 & `touse'
			replace cvd10 = round(cvd10 * 100, 0.01) if `female' == 1 & `touse'
			
			********************
			* CVD - Male
			********************	
			replace cvd10 = 														///
			(0.7688528 * (`age'- 55)/10)											/// centered age (Age-55)/10
			+ (0.0736174 * ((`chol' - `hdl') * 0.02586 - 3.5))						/// (TC – HDL-C) × 0.02586 (to convert to mmol/L) – 3.5			
			+ (-0.0954431 * ((`hdl' * 0.02586 - 1.3) / 0.3))						/// (HDL-C × 0.02586 (to convert to mmol/L)  – 1.3) /0.3 
			+ (-0.4347345 * (min(`sbp', 110) - 110)/20)								/// (min(SBP, 110) – 110) /20
			+ (0.3362658 * (max(`sbp', 110) - 130)/20)								/// (max(SBP, 110) – 130) /20
			+ (0.7692857 * `diabetes')												/// Diabetes (1=Yes, 0=No)
			+ (0.4386871 * `smoker')												/// Current Smoker (1=Yes, 0=No)
			+ (0.5378979 * (min(`gfr', 60) - 60) / - 15)							/// (min(eGFR, 60) – 60) / -15
			+ (0.0164827 * (max(`gfr', 60) - 90) / - 15)							/// (max(eGFR, 60)  – 90) / -15
			+ (0.288879 * `antihtn')												/// Anti-hypertensive use
			+ (-0.1337349 * `statin')												/// statin use	
			+ (-0.0475924 * (max(`sbp', 110) - 130)/20) * `antihtn'					/// (max(SBP, 110) – 130) /20 × Antihtn
			+ (0.150273 * ((`chol' - `hdl') * 0.02586 - 3.5)) * `statin'			/// ((TC – HDL-C) × 0.02586 – 3.5) × Statin
			+ (-0.0517874 * (`age'- 55)/10 * ((`chol' - `hdl') * 0.02586 - 3.5))	/// (age-55)/10 × ((TC – HDL-C) × 0.02586 – 3.5) 
			+ (0.0191169 * (`age'- 55)/10 * (`hdl' * 0.02586 - 1.3) / 0.3)			/// (age-55)/10 × (HDL-C × 0.02586 – 1.3) /0.3 			
			+ (-0.1049477 * (`age'- 55)/10 * (max(`sbp', 110) - 130)/20)			/// (age-55)/10 × (max(SBP, 110) – 130) /20			
			+ (-0.2251948 * (`age'- 55)/10 * `diabetes')							/// (Age-55)/10 × Diabetes
			+ (-0.0895067 * (`age'- 55)/10 * `smoker')								/// (Age-55)/10 × Cursmk
			+ (-0.1543702 * (`age'- 55)/10 * (min(`gfr', 60) - 60) / - 15)			/// (Age-55)/10 × (min(eGFR, 60) – 60) / -15
			+ (-3.031168 * 1)														/// constant
			if `female' == 0 & `touse'

			replace cvd10 = exp(cvd10) / (1 + exp(cvd10)) if `female' == 0 & `touse'
			replace cvd10 = round(cvd10 * 100, 0.01) if `female' == 0 & `touse'			
			
			
			********************
			* ASCVD - Female
			********************
			gen ascvd10 = .															
			replace ascvd10 = 														///
			(0.719883 * (`age'- 55)/10)												/// centered age (Age-55)/10
			+ (0.1176967 * ((`chol' - `hdl') * 0.02586 - 3.5))						/// (TC – HDL-C) × 0.02586 (to convert to mmol/L) – 3.5			
			+ (-0.151185 * ((`hdl' * 0.02586 - 1.3) / 0.3))							/// (HDL-C × 0.02586 (to convert to mmol/L)  – 1.3) /0.3 
			+ (-0.0835358 * (min(`sbp', 110) - 110)/20)								/// (min(SBP, 110) – 110) /20
			+ (0.3592852 * (max(`sbp', 110) - 130)/20)								/// (max(SBP, 110) – 130) /20
			+ (0.8348585 * `diabetes')												/// Diabetes (1=Yes, 0=No)
			+ (0.4831078 * `smoker')												/// Current Smoker (1=Yes, 0=No)
			+ (0.4864619 * (min(`gfr', 60) - 60) / - 15)							/// (min(eGFR, 60) – 60) / -15
			+ (0.0397779 * (max(`gfr', 60) - 90) / - 15)							/// (max(eGFR, 60)  – 90) / -15
			+ (0.2265309 * `antihtn')												/// Anti-hypertensive use
			+ (-0.0592374 * `statin')												/// statin use			
			+ (-0.0395762 * (max(`sbp', 110) - 130)/20) * `antihtn'					/// (max(SBP, 110) – 130) /20 × Antihtn
			+ (0.0844423 * ((`chol' - `hdl') * 0.02586 - 3.5)) * `statin'			/// ((TC – HDL-C) × 0.02586 – 3.5) × Statin
			+ (-0.0567839 * (`age'- 55)/10 * ((`chol' - `hdl') * 0.02586 - 3.5))	/// (age-55)/10 × ((TC – HDL-C) × 0.02586 – 3.5) 
			+ (0.0325692 * (`age'- 55)/10 * (`hdl' * 0.02586 - 1.3) / 0.3)			/// (age-55)/10 × (HDL-C × 0.02586 – 1.3) /0.3 	
			+ (-0.1035985 * (`age'- 55)/10 * (max(`sbp', 110) - 130)/20)			/// (age-55)/10 × (max(SBP, 110) – 130) /20			
			+ (-0.2417542 * (`age'- 55)/10 * `diabetes')								/// (Age-55)/10 × Diabetes
			+ (-0.0791142 * (`age'- 55)/10 * `smoker')								/// (Age-55)/10 × Cursmk
			+ (-0.1671492 * (`age'- 55)/10 * (min(`gfr', 60) - 60) / - 15)			/// (Age-55)/10 × (min(eGFR, 60) – 60) / -15
			+ (-3.819975 * 1)														/// constant
			if `female' == 1 & `touse'

			replace ascvd10 = exp(ascvd10) / (1 + exp(ascvd10)) if `female' == 1 & `touse'
			replace ascvd10 = round(ascvd10 * 100, 0.01) if `female' == 1 & `touse'		

			********************
			* ASCVD - Male
			********************
			replace ascvd10 = 														///
			(0.7099847 * (`age'- 55)/10)												/// centered age (Age-55)/10
			+ (0.1658663 * ((`chol' - `hdl') * 0.02586 - 3.5))						/// (TC – HDL-C) × 0.02586 (to convert to mmol/L) – 3.5			
			+ (-0.1144285 * ((`hdl' * 0.02586 - 1.3) / 0.3))							/// (HDL-C × 0.02586 (to convert to mmol/L)  – 1.3) /0.3 
			+ (-0.2837212 * (min(`sbp', 110) - 110)/20)								/// (min(SBP, 110) – 110) /20
			+ (0.3239977 * (max(`sbp', 110) - 130)/20)								/// (max(SBP, 110) – 130) /20
			+ (0.7189597 * `diabetes')												/// Diabetes (1=Yes, 0=No)
			+ (0.3956973 * `smoker')												/// Current Smoker (1=Yes, 0=No)
			+ (0.3690075 * (min(`gfr', 60) - 60) / - 15)							/// (min(eGFR, 60) – 60) / -15
			+ (0.0203619 * (max(`gfr', 60) - 90) / - 15)							/// (max(eGFR, 60)  – 90) / -15
			+ (0.2036522 * `antihtn')												/// Anti-hypertensive use
			+ (-0.0865581 * `statin')												/// statin use	
			+ (-0.0322916 * (max(`sbp', 110) - 130)/20) * `antihtn'					/// (max(SBP, 110) – 130) /20 × Antihtn
			+ (0.114563 * ((`chol' - `hdl') * 0.02586 - 3.5)) * `statin'			/// ((TC – HDL-C) × 0.02586 – 3.5) × Statin
			+ (-0.0300005 * (`age'- 55)/10 * ((`chol' - `hdl') * 0.02586 - 3.5))	/// (age-55)/10 × ((TC – HDL-C) × 0.02586 – 3.5) 
			+ (0.0232747 * (`age'- 55)/10 * (`hdl' * 0.02586 - 1.3) / 0.3)			/// (age-55)/10 × (HDL-C × 0.02586 – 1.3) /0.3 	
			+ (-0.0927024 * (`age'- 55)/10 * (max(`sbp', 110) - 130)/20)			/// (age-55)/10 × (max(SBP, 110) – 130) /20			
			+ (-0.2018525 * (`age'- 55)/10 * `diabetes')							/// (Age-55)/10 × Diabetes
			+ (-0.0970527 * (`age'- 55)/10 * `smoker')								/// (Age-55)/10 × Cursmk
			+ (-0.1217081 * (`age'- 55)/10 * (min(`gfr', 60) - 60) / - 15)			/// (Age-55)/10 × (min(eGFR, 60) – 60) / -15
			+ (-3.500655 * 1)														/// constant
			if `female' == 0 & `touse'

			replace ascvd10 = exp(ascvd10) / (1 + exp(ascvd10)) if `female' == 0 & `touse'
			replace ascvd10 = round(ascvd10 * 100, 0.01) if `female' == 0 & `touse'				
			
			
			********************
			* HF - Female
			********************
			gen hf10 = .															
			replace hf10 = 															///
			(0.8998235 * (`age'- 55)/10)											/// centered age (Age-55)/10
			+ (-0.4559771 * (min(`sbp', 110) - 110)/20)								/// (min(SBP, 110) – 110) /20
			+ (0.3576505 * (max(`sbp', 110) - 130)/20)								/// (max(SBP, 110) – 130) /20
			+ (1.038346 * `diabetes')												/// Diabetes (1=Yes, 0=No)
			+ (0.583916 * `smoker')													/// Current Smoker (1=Yes, 0=No)
			+ (-0.0072294 * (min(`bmi', 30) - 25) / 5)								/// (min(BMI, 30) – 25) /5
			+ (0.2997706 * (max(`bmi', 30) - 30)/5)									/// (max(BMI, 30) – 30) /5			
			+ (0.7451638 * (min(`gfr', 60) - 60) / - 15)							/// (min(eGFR, 60) – 60) / -15
			+ (0.0557087 * (max(`gfr', 60) - 90) / - 15)							/// (max(eGFR, 60)  – 90) / -15
			+ (0.3534442 * `antihtn')												/// Anti-hypertensive use
			+ (-0.0981511 * (max(`sbp', 110) - 130)/20) * `antihtn'					/// (max(SBP, 110) – 130) /20 × Antihtn
			+ (-0.0946663 * (`age'- 55)/10 * (max(`sbp', 110) - 130)/20)			/// (age-55)/10 × (max(SBP, 110) – 130) /20			
			+ (-0.3581041 * (`age'- 55)/10 * `diabetes')							/// (Age-55)/10 × Diabetes
			+ (-0.1159453 * (`age'- 55)/10 * `smoker')								/// (Age-55)/10 × Cursmk			
			+ (-0.003878 * (`age'- 55)/10 * (max(`bmi', 30) - 30)/5)				/// (Age-55)/10 × (max(BMI, 30) – 30) /5
			+ (-0.1884289 * (`age'- 55)/10 * (min(`gfr', 60) - 60) / - 15)			/// (Age-55)/10 × (min(eGFR, 60) – 60) / -15
			+ (-4.310409 * 1)														/// constant
			if `female' == 1 & `touse'
			
			replace hf10 = exp(hf10) / (1 + exp(hf10)) if `female' == 1 & `touse'
			replace hf10 = round(hf10 * 100, 0.01) if `female' == 1 & `touse'	
			

			********************
			* HF - Male
			********************
			replace hf10 = 															///
			(0.8972642 * (`age'- 55)/10)											/// centered age (Age-55)/10
			+ (-0.6811466 * (min(`sbp', 110) - 110)/20)								/// (min(SBP, 110) – 110) /20
			+ (0.3634461 * (max(`sbp', 110) - 130)/20)								/// (max(SBP, 110) – 130) /20
			+ (0.923776 * `diabetes')												/// Diabetes (1=Yes, 0=No)
			+ (0.5023736 * `smoker')												/// Current Smoker (1=Yes, 0=No)
			+ (-0.0485841 * (min(`bmi', 30) - 25) / 5)								/// (min(BMI, 30) – 25) /5
			+ (0.3726929 * (max(`bmi', 30) - 30)/5)									/// (max(BMI, 30) – 30) /5			
			+ (0.6926917 * (min(`gfr', 60) - 60) / - 15)							/// (min(eGFR, 60) – 60) / -15
			+ (0.0251827 * (max(`gfr', 60) - 90) / - 15)							/// (max(eGFR, 60)  – 90) / -15
			+ (0.2980922 * `antihtn')												/// Anti-hypertensive use
			+ (-0.0497731 * (max(`sbp', 110) - 130)/20) * `antihtn'					/// (max(SBP, 110) – 130) /20 × Antihtn
			+ (-0.1289201 * (`age'- 55)/10 * (max(`sbp', 110) - 130)/20)			/// (age-55)/10 × (max(SBP, 110) – 130) /20			
			+ (-0.3040924 * (`age'- 55)/10 * `diabetes')							/// (Age-55)/10 × Diabetes
			+ (-0.1401688 * (`age'- 55)/10 * `smoker')								/// (Age-55)/10 × Cursmk
			+ (0.0068126 * (`age'- 55)/10 * (max(`bmi', 30) - 30)/5)				/// (Age-55)/10 × (max(BMI, 30) – 30) /5
			+ (-0.1797778 * (`age'- 55)/10 * (min(`gfr', 60) - 60) / - 15)			/// (Age-55)/10 × (min(eGFR, 60) – 60) / -15
			+ (-3.946391 * 1)														/// constant
			if `female' == 0 & `touse'
			
			replace hf10 = exp(hf10) / (1 + exp(hf10)) if `female' == 0 & `touse'
			replace hf10 = round(hf10 * 100, 0.01) if `female' == 0 & `touse'	
			
			if "`include'" != "" {	
				gen include10 = inrange(`age',30,79) & inrange(`chol',130,320) & inrange(`hdl',20,100) & inrange(`sbp',90,200) ///
				& inrange(`bmi',18.5,39.99) & inrange(`gfr',15,150) if `touse'
				label var include10 "Patient values meet guidelines for inclusion"
				local incl include10
			}					
			
			local prevent10vars cvd10 ascvd10 hf10 `incl'
			char def _dta[prevent10vars] "`prevent10vars'" 				
			
		}	// end quietly
			
end			
