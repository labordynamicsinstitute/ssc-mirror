*! 1.0.0 Ariel Linden 15Jun2024 

/* 	

Computes AHA 30-year risk for CVD, ASCVD, and HF, from:

Khan SS, Matsushita K, Sang Y, et al. Development and Validation of the American Heart Association 
Predicting Risk of Cardiovascular Disease EVENTs (PREVENT^TM) Equations. Circulation 2024;149:30–449.
	
*/

program prevent30, rclass
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
		local prevent30vars : char _dta[prevent30vars] 
		if "`prevent30vars'" != "" {
			foreach f of local prevent30vars { 
			capture drop `f' 
			}
		}

		quietly {
	
		
			********************
			* CVD - Female
			********************
			gen cvd30 = .															
			replace cvd30 = 														///
			(0.5503079 * (`age'- 55)/10)											/// centered age (Age-55)/10
			+ (-0.0928369 * ((`age'- 55)/10)^2)										/// centered age squared ((Age-55)/10)^2
			+ (0.0409794 * ((`chol' - `hdl') * 0.02586 - 3.5))						/// (TC – HDL-C) × 0.02586 (to convert to mmol/L) – 3.5
			+ (-0.1663306 * ((`hdl' * 0.02586 - 1.3) / 0.3))						/// (HDL-C × 0.02586 (to convert to mmol/L)  – 1.3) /0.3 
			+ (-0.1628654 * (min(`sbp', 110) - 110)/20)								/// (min(SBP, 110) – 110) /20
			+ (0.3299505 * (max(`sbp', 110) - 130)/20)								/// (max(SBP, 110) – 130) /20
			+ (0.6793894 * `diabetes')												/// Diabetes (1=Yes, 0=No)
			+ (0.3196112 * `smoker')												/// Current Smoker (1=Yes, 0=No)
			+ (0.1857101 * (min(`gfr', 60) - 60) / - 15)							/// (min(eGFR, 60) – 60) / -15
			+ (0.0553528 * (max(`gfr', 60) - 90) / - 15)							/// (max(eGFR, 60)  – 90) / -15
			+ (0.2894 * `antihtn')													/// Anti-hypertensive use
			+ (-0.075688 * `statin')												/// statin use
			+ (-0.056367 * (max(`sbp', 110) - 130)/20) * `antihtn'					/// (max(SBP, 110) – 130) /20 × Antihtn
			+ (0.1071019 * ((`chol' - `hdl') * 0.02586 - 3.5)) * `statin'			/// ((TC – HDL-C) × 0.02586 – 3.5) × Statin
			+ (-0.0751438 * (`age'- 55)/10 * ((`chol' - `hdl') * 0.02586 - 3.5))	/// (age-55)/10 × ((TC – HDL-C) × 0.02586 – 3.5) 
			+ (0.0301786 * (`age'- 55)/10 * (`hdl' * 0.02586 - 1.3) / 0.3)			/// (age-55)/10 × (HDL-C × 0.02586 – 1.3) /0.3 
			+ (-0.0998776 * (`age'- 55)/10 * (max(`sbp', 110) - 130)/20)			/// (age-55)/10 × (max(SBP, 110) – 130) /20
			+ (-0.3206166 * (`age'- 55)/10 * `diabetes')							/// (Age-55)/10 × Diabetes
			+ (-0.1607862 * (`age'- 55)/10 * `smoker')								/// (Age-55)/10 × Cursmk
			+ (-0.1450788 * (`age'- 55)/10 * (min(`gfr', 60) - 60) / - 15)			/// (Age-55)/10 × (min(eGFR, 60) – 60) / -15
			+ (-1.318827 * 1)														/// constant
			if `female' == 1 & `touse'
			
			replace cvd30 = exp(cvd30) / (1 + exp(cvd30)) if `female' == 1 & `touse'
			replace cvd30 = round(cvd30 * 100, 0.01) if `female' == 1 & `touse'

			
			********************
			* CVD - Male
			********************			
			replace cvd30 = 														///		
			(0.4627309 * (`age'- 55)/10)											/// centered age (Age-55)/10
			+ (-0.0984281 * ((`age'- 55)/10)^2)										/// centered age squared ((Age-55)/10)^2
			+ (0.0836088 * ((`chol' - `hdl') * 0.02586 - 3.5))						/// (TC – HDL-C) × 0.02586 (to convert to mmol/L) – 3.5
			+ (-0.1029824 * ((`hdl' * 0.02586 - 1.3) / 0.3))						/// (HDL-C × 0.02586 (to convert to mmol/L)  – 1.3) /0.3
			+ (-0.2140352 * (min(`sbp', 110) - 110)/20)								/// (min(SBP, 110) – 110) /20
			+ (0.2904325 * (max(`sbp', 110) - 130)/20)								/// (max(SBP, 110) – 130) /20
			+ (0.5331276 * `diabetes')												/// Diabetes (1=Yes, 0=No)
			+ (0.2141914 * `smoker')												/// Current Smoker (1=Yes, 0=No)
			+ (0.1155556 * (min(`gfr', 60) - 60) / - 15)							/// (min(eGFR, 60) – 60) / -15
			+ (0.0603775 * (max(`gfr', 60) - 90) / - 15)							/// (max(eGFR, 60)  – 90) / -15
			+ (0.232714 * `antihtn')												/// Anti-hypertensive use
			+ (-0.0272112 * `statin')												/// statin use
			+ (-0.0384488 * (max(`sbp', 110) - 130)/20) * `antihtn'					/// (max(SBP, 110) – 130) /20 × Antihtn
			+ (0.134192 * ((`chol' - `hdl') * 0.02586 - 3.5)) * `statin'			/// ((TC – HDL-C) × 0.02586 – 3.5) × Statin
			+ (-0.0511759 * (`age'- 55)/10 * ((`chol' - `hdl') * 0.02586 - 3.5))	/// (age-55)/10 × ((TC – HDL-C) × 0.02586 – 3.5)
			+ (0.0165865 * (`age'- 55)/10 * (`hdl' * 0.02586 - 1.3) / 0.3)			/// (age-55)/10 × (HDL-C × 0.02586 – 1.3) /0.3
			+ (-0.1101437 * (`age'- 55)/10 * (max(`sbp', 110) - 130)/20)			/// (age-55)/10 × (max(SBP, 110) – 130) /20
			+ (-0.2585943 * (`age'- 55)/10 * `diabetes')							/// (Age-55)/10 × Diabetes
			+ (-0.1566406 * (`age'- 55)/10 * `smoker')								/// (Age-55)/10 × Cursmk
			+ (-0.1166776 * (`age'- 55)/10 * (min(`gfr', 60) - 60) / - 15)			/// (Age-55)/10 × (min(eGFR, 60) – 60) / -15
			+ (-1.148204 * 1)														/// constant
			if `female' == 0 & `touse'
			
			replace cvd30 = exp(cvd30) / (1 + exp(cvd30)) if `female' == 0 & `touse'
			replace cvd30 = round(cvd30 * 100, 0.01) if `female' == 0 & `touse'			
			
			
			********************
			* ASCVD - Female
			********************
			gen ascvd30 = .															
			replace ascvd30 = 														///
			(0.4669202 * (`age'- 55)/10)											/// centered age (Age-55)/10
			+ (-0.0893118 * ((`age'- 55)/10)^2)										/// centered age squared ((Age-55)/10)^2
			+ (0.1256901 * ((`chol' - `hdl') * 0.02586 - 3.5))						/// (TC – HDL-C) × 0.02586 (to convert to mmol/L) – 3.5
			+ (-0.1542255 * ((`hdl' * 0.02586 - 1.3) / 0.3))						/// (HDL-C × 0.02586 (to convert to mmol/L)  – 1.3) /0.3 
			+ (-0.0018093 * (min(`sbp', 110) - 110)/20)								/// (min(SBP, 110) – 110) /20
			+ (0.322949 * (max(`sbp', 110) - 130)/20)								/// (max(SBP, 110) – 130) /20
			+ (0.6296707 * `diabetes')												/// Diabetes (1=Yes, 0=No)
			+ (0.268292 * `smoker')													/// Current Smoker (1=Yes, 0=No)
			+ (0.100106 * (min(`gfr', 60) - 60) / - 15)								/// (min(eGFR, 60) – 60) / -15
			+ (0.0499663 * (max(`gfr', 60) - 90) / - 15)							/// (max(eGFR, 60)  – 90) / -15
			+ (0.1875292 * `antihtn')												/// Anti-hypertensive use
			+ (0.0152476 * `statin')												/// statin use
			+ (-0.0276123 * (max(`sbp', 110) - 130)/20) * `antihtn'					/// (max(SBP, 110) – 130) /20 × Antihtn
			+ (0.0736147 * ((`chol' - `hdl') * 0.02586 - 3.5)) * `statin'			/// ((TC – HDL-C) × 0.02586 – 3.5) × Statin
			+ (-0.0521962 * (`age'- 55)/10 * ((`chol' - `hdl') * 0.02586 - 3.5))	/// (age-55)/10 × ((TC – HDL-C) × 0.02586 – 3.5) 
			+ (0.0316918 * (`age'- 55)/10 * (`hdl' * 0.02586 - 1.3) / 0.3)			/// (age-55)/10 × (HDL-C × 0.02586 – 1.3) /0.3 
			+ (-0.1046101 * (`age'- 55)/10 * (max(`sbp', 110) - 130)/20)			/// (age-55)/10 × (max(SBP, 110) – 130) /20
			+ (-0.2727793 * (`age'- 55)/10 * `diabetes')							/// (Age-55)/10 × Diabetes
			+ (-0.1530907 * (`age'- 55)/10 * `smoker')								/// (Age-55)/10 × Cursmk
			+ (-0.1299149 * (`age'- 55)/10 * (min(`gfr', 60) - 60) / - 15)			/// (Age-55)/10 × (min(eGFR, 60) – 60) / -15
			+ (-1.974074 * 1)														/// constant
			if `female' == 1 & `touse'
			
			replace ascvd30 = exp(ascvd30) / (1 + exp(ascvd30)) if `female' == 1 & `touse'
			replace ascvd30 = round(ascvd30 * 100, 0.01) if `female' == 1 & `touse'			
			
			
			********************
			* ASCVD - Male
			********************
			replace ascvd30 = 														///
			(0.3994099 * (`age'- 55)/10)											/// centered age (Age-55)/10
			+ (-0.0937484 * ((`age'- 55)/10)^2)										/// centered age squared ((Age-55)/10)^2
			+ (0.1744643 * ((`chol' - `hdl') * 0.02586 - 3.5))						/// (TC – HDL-C) × 0.02586 (to convert to mmol/L) – 3.5
			+ (-0.120203 * ((`hdl' * 0.02586 - 1.3) / 0.3))							/// (HDL-C × 0.02586 (to convert to mmol/L)  – 1.3) /0.3 
			+ (-0.0665117 * (min(`sbp', 110) - 110)/20)								/// (min(SBP, 110) – 110) /20
			+ (0.2753037 * (max(`sbp', 110) - 130)/20)								/// (max(SBP, 110) – 130) /20
			+ (0.4790257 * `diabetes')												/// Diabetes (1=Yes, 0=No)
			+ (0.1782635 * `smoker')												/// Current Smoker (1=Yes, 0=No)
			+ (-0.0218789 * (min(`gfr', 60) - 60) / - 15)							/// (min(eGFR, 60) – 60) / -15
			+ (0.0602553 * (max(`gfr', 60) - 90) / - 15)							/// (max(eGFR, 60)  – 90) / -15
			+ (0.1421182 * `antihtn')												/// Anti-hypertensive use
			+ (0.0135996 * `statin')												/// statin use
			+ (-0.0218265 * (max(`sbp', 110) - 130)/20) * `antihtn'					/// (max(SBP, 110) – 130) /20 × Antihtn
			+ (0.1013148 * ((`chol' - `hdl') * 0.02586 - 3.5)) * `statin'			/// ((TC – HDL-C) × 0.02586 – 3.5) × Statin
			+ (-0.0312619 * (`age'- 55)/10 * ((`chol' - `hdl') * 0.02586 - 3.5))	/// (age-55)/10 × ((TC – HDL-C) × 0.02586 – 3.5) 
			+ (0.020673 * (`age'- 55)/10 * (`hdl' * 0.02586 - 1.3) / 0.3)			/// (age-55)/10 × (HDL-C × 0.02586 – 1.3) /0.3 
			+ (-0.0920935 * (`age'- 55)/10 * (max(`sbp', 110) - 130)/20)			/// (age-55)/10 × (max(SBP, 110) – 130) /20
			+ (-0.2159947 * (`age'- 55)/10 * `diabetes')							/// (Age-55)/10 × Diabetes
			+ (-0.1548811 * (`age'- 55)/10 * `smoker')								/// (Age-55)/10 × Cursmk
			+ (-0.0712547 * (`age'- 55)/10 * (min(`gfr', 60) - 60) / - 15)			/// (Age-55)/10 × (min(eGFR, 60) – 60) / -15
			+ (-1.736444 * 1)														/// constant
			if `female' == 0 & `touse'
			
			replace ascvd30 = exp(ascvd30) / (1 + exp(ascvd30)) if `female' == 0 & `touse'
			replace ascvd30 = round(ascvd30 * 100, 0.01) if `female' == 0 & `touse'					
			
			
			********************
			* HF - Female
			********************
			gen hf30 = .															
			replace hf30 = 															///
			(0.6254374 * (`age'- 55)/10)											/// centered age (Age-55)/10
			+ (-0.0983038 * ((`age'- 55)/10)^2)										/// centered age squared ((Age-55)/10)^2
			+ (-0.3919241 * (min(`sbp', 110) - 110)/20)								/// (min(SBP, 110) – 110) /20
			+ (0.3142295 * (max(`sbp', 110) - 130)/20)								/// (max(SBP, 110) – 130) /20
			+ (0.8330787 * `diabetes')												/// Diabetes (1=Yes, 0=No)
			+ (0.3438651 * `smoker')												/// Current Smoker (1=Yes, 0=No)
			+ (0.0594874 * (min(`bmi', 30) - 25) / 5)								/// (min(BMI, 30) – 25) /5
			+ (0.2525536 * (max(`bmi', 30) - 30)/5)									/// (max(BMI, 30) – 30) /5
			+ (0.2981642 * (min(`gfr', 60) - 60) / - 15)							/// (min(eGFR, 60) – 60) / -15
			+ (0.0667159 * (max(`gfr', 60) - 90) / - 15)							/// (max(eGFR, 60)  – 90) / -15
			+ (0.333921 * `antihtn')												/// Anti-hypertensive use
			+ (-0.0893177 * (max(`sbp', 110) - 130)/20) * `antihtn'					/// (max(SBP, 110) – 130) /20 × Antihtn
			+ (-0.0974299 * (`age'- 55)/10 * (max(`sbp', 110) - 130)/20)			/// (age-55)/10 × (max(SBP, 110) – 130) /20
			+ (-0.404855 * (`age'- 55)/10 * `diabetes')								/// (Age-55)/10 × Diabetes
			+ (-0.1982991 * (`age'- 55)/10 * `smoker')								/// (Age-55)/10 × Cursmk
			+ (-0.0035619 * (`age'- 55)/10 * (max(`bmi', 30) - 30)/5)				/// (Age-55)/10 × (max(BMI, 30) – 30) /5
			+ (-0.1564215 * (`age'- 55)/10 * (min(`gfr', 60) - 60) / - 15)			/// (Age-55)/10 × (min(eGFR, 60) – 60) / -15
			+ (-2.205379 * 1)														/// constant
			if `female' == 1 & `touse'
			
			replace hf30 = exp(hf30) / (1 + exp(hf30)) if `female' == 1 & `touse'
			replace hf30 = round(hf30 * 100, 0.01) if `female' == 1 & `touse'			


			********************
			* HF - Male
			********************
			replace hf30 = 															///
			(0.5681541 * (`age'- 55)/10)											/// centered age (Age-55)/10
			+ (-0.1048388 * ((`age'- 55)/10)^2)										/// centered age squared ((Age-55)/10)^2
			+ (-0.4761564 * (min(`sbp', 110) - 110)/20)								/// (min(SBP, 110) – 110) /20
			+ (0.30324 * (max(`sbp', 110) - 130)/20)								/// (max(SBP, 110) – 130) /20
			+ (00.6840338 * `diabetes')												/// Diabetes (1=Yes, 0=No)
			+ (0.2656273 * `smoker')												/// Current Smoker (1=Yes, 0=No)
			+ (0.0833107 * (min(`bmi', 30) - 25) / 5)								/// (min(BMI, 30) – 25) /5
			+ (0.26999 * (max(`bmi', 30) - 30)/5)									/// (max(BMI, 30) – 30) /5
			+ (0.2541805 * (min(`gfr', 60) - 60) / - 15)							/// (min(eGFR, 60) – 60) / -15
			+ (0.0638923 * (max(`gfr', 60) - 90) / - 15)							/// (max(eGFR, 60)  – 90) / -15
			+ (0.2583631 * `antihtn')												/// Anti-hypertensive use
			+ (-0.0391938 * (max(`sbp', 110) - 130)/20) * `antihtn'					/// (max(SBP, 110) – 130) /20 × Antihtn
			+ (-0.1269124 * (`age'- 55)/10 * (max(`sbp', 110) - 130)/20)			/// (age-55)/10 × (max(SBP, 110) – 130) /20
			+ (-0.3273572 * (`age'- 55)/10 * `diabetes')							/// (Age-55)/10 × Diabetes
			+ (-0.2043019 * (`age'- 55)/10 * `smoker')								/// (Age-55)/10 × Cursmk
			+ (-0.0182831 * (`age'- 55)/10 * (max(`bmi', 30) - 30)/5)				/// (Age-55)/10 × (max(BMI, 30) – 30) /5
			+ (-0.1342618 * (`age'- 55)/10 * (min(`gfr', 60) - 60) / - 15)			/// (Age-55)/10 × (min(eGFR, 60) – 60) / -15
			+ (-1.95751 * 1)														/// constant
			if `female' == 0 & `touse'
			
			replace hf30 = exp(hf30) / (1 + exp(hf30)) if `female' == 0 & `touse'
			replace hf30 = round(hf30 * 100, 0.01) if `female' == 0 & `touse'			
			
			if "`include'" != "" {	
				gen include30 = inrange(`age',30,59) & inrange(`chol',130,320) & inrange(`hdl',20,100) & inrange(`sbp',90,200) ///
				& inrange(`bmi',18.5,39.99) & inrange(`gfr',15,150) if `touse'
				label var include30 "Patient values meet guidelines for inclusion"
				local incl include30
			}				
			
			local prevent30vars cvd30 ascvd30 hf30 `incl'
			char def _dta[prevent30vars] "`prevent30vars'" 			
			
		} // end quietly		
			
end
