*! 1.0.0 Ariel Linden 31dec2022 

/* 	

Computes 10-year risk for initial hard atherosclerotic cardiovascular disease (ASCVD) event 
(defined as first occurrence of non-fatal myocardial infarction, congestive heart disease death, or fatal or nonfatal stroke), from:

Goff Jr, D.C., Lloyd-Jones, D.M., Bennett, G., Coady, S., D'agostino, R.B., Gibbons, R., Greenland, P., Lackland, D.T., 
Levy, D., O'donnell, C.J. and J.G. Robinson. 2014. 2013 ACC/AHA guideline on the assessment of cardiovascular risk: 
a report of the American College of Cardiology/American Heart Association Task Force on Practice Guidelines. 
Circulation 129(25_suppl_2), S49-S73.
	
*/

program ascvd, rclass
	version 13.0
	syntax [if] [in] ,  			///
		FEMale(varname numeric) 	/// integer 0 or 1
		BLAck(varname numeric)		/// integer 0 or 1
		AGE(varname numeric)    	/// 
		CHOL(varname numeric)   	///
		HDL(varname numeric) 		///
		SBP(varname numeric)  		///
		TRhtn(varname numeric) 		/// integer 0 or 1
		SMoker(varname numeric) 	/// integer 0 or 1
		DIABetes(varname numeric) 	/// integer 0 or 1
		[INClude]
		
		marksample touse 
		markout `touse' `v' `female' `black' `age' `chol' `hdl' `sbp' `trhtn' `smokee' `diabetes' 

		qui count if `touse' 
		if r(N) == 0 error 2000 

		/* check to ensure binary variables contain 0 or 1 */
		foreach v in `female' `black' `trhtn' `smoker' `diabetes' {
			capture assert inlist(`v', 0, 1) if `touse' 
			if _rc { 
				di as err "`v' contains values other than 0 or 1" 
				exit 498 
			} 
		}
		
		/* drop variables that were generated in last run */
		local ascvdvars : char _dta[ascvdvars] 
		if "`ascvdvars'" != "" {
			foreach f of local ascvdvars { 
			capture drop `f' 
			}
		}

	quietly {
	
		tempvar indrisk
		gen `indrisk' =.
		gen ascvd10 =.
	
		
		********************
		* Female and White
		********************
			/* if `trhtn' == 1 */
			replace `indrisk' = 						///
			(-29.799 * log(`age')) 						/// Ln Age (y)
			+ (4.884 * log(`age')^2) 					/// Ln Age, Squared
			+ (13.54 * log(`chol'))						/// Ln Total Cholesterol (mg/dL)	
			+ (-3.114 * log(`age') * log(`chol'))		/// Ln Age × Ln Total Cholesterol	
			+ (-13.578 * log(`hdl'))					/// Ln HDL-C (mg/dL)
			+ (3.149 * log(`age') * log(`hdl'))			/// Ln Age × Ln HDL-C
			+ (2.019 * log(`sbp'))						/// Ln Treated Systolic BP (mm Hg)
			+ (7.574 * `smoker')						/// Current Smoker (1=Yes, 0=No)
			+ (-1.665 * log(`age') * `smoker') 			/// Ln Age × Current Smoker	
			+ (0.661 * `diabetes')						/// Diabetes (1=Yes, 0=No)	
			if `female' == 1 & `black' == 0  & `trhtn' == 1 & `touse'
			/* if `trhtn' == 0 */
			replace `indrisk' = 						///
			(-29.799 * log(`age')) 						/// Ln Age (y)
			+ (4.884 * log(`age')^2) 					/// Ln Age, Squared
			+ (13.54 * log(`chol'))						/// Ln Total Cholesterol (mg/dL)	
			+ (-3.114 * log(`age') * log(`chol'))		/// Ln Age × Ln Total Cholesterol	
			+ (-13.578 * log(`hdl'))					/// Ln HDL-C (mg/dL)
			+ (3.149 * log(`age') * log(`hdl'))			/// Ln Age × Ln HDL-C
			+ (1.957 * log(`sbp'))						/// Ln Untreated Systolic BP (mm Hg)
			+ (7.574 * `smoker')						/// Current Smoker (1=Yes, 0=No)
			+ (-1.665 * log(`age') * `smoker') 			/// Ln Age × Current Smoker	
			+ (0.661 * `diabetes')						/// Diabetes (1=Yes, 0=No)	
			if `female' == 1 & `black' == 0  & `trhtn' == 0 & `touse'

			replace ascvd10 = round((1 - (0.9665^exp(`indrisk' - -29.18))) * 100, 0.01) if `female' == 1 & `black' == 0  & `touse'
			
		********************
		* Female and Black
		********************	
			/* if `trhtn' == 1 */
			replace `indrisk' = 						///
			(17.114 * log(`age')) 						/// Ln Age (y)
			+ (0.94 * log(`chol'))						/// Ln Total Cholesterol (mg/dL)	
			+ (-18.920 * log(`hdl'))					/// Ln HDL-C (mg/dL)
			+ (4.475 * log(`age') * log(`hdl'))			/// Ln Age × Ln HDL-C (mg/dL)	
			+ (29.291 * log(`sbp'))						/// Ln Treated Systolic BP (mm Hg)
			+ (-6.432 * log(`sbp') * log(`age'))		/// Ln Age × Ln Treated Systolic BP
			+ (0.691 * `smoker')						/// Current Smoker (1=Yes, 0=No)
			+ (0.874 * `diabetes')						/// Diabetes (1=Yes, 0=No)		
			if `female' == 1 & `black' == 1  & `trhtn' == 1 & `touse'	
			/* if `trhtn' == 0 */	
			replace `indrisk' = 						///
			(17.114 * log(`age')) 						/// Ln Age (y)
			+ (0.94 * log(`chol'))						/// Ln Total Cholesterol (mg/dL)	
			+ (-18.920 * log(`hdl'))					/// Ln HDL-C (mg/dL)
			+ (4.475 * log(`age') * log(`hdl'))			/// Ln Age × Ln HDL-C (mg/dL)	
			+ (27.82 * log(`sbp'))						/// Ln Untreated Systolic BP (mm Hg)
			+ (-6.087 * log(`sbp') * log(`age'))		/// Ln Age × Ln Untreated Systolic BP
			+ (0.691 * `smoker')						/// Current Smoker (1=Yes, 0=No)
			+ (0.874 * `diabetes')						/// Diabetes (1=Yes, 0=No)	
			if `female' == 1 & `black' == 1  & `trhtn' == 0 & `touse'	

			replace ascvd10 = round((1 - (0.9533^exp(`indrisk' - 86.61))) * 100, 0.01) if `female' == 1 & `black' == 1  & `touse'	
	
		********************
		* Male and White
		********************	
			/* if `trhtn' == 1 */
			replace `indrisk' = 							///
			(12.344 * log(`age')) 						/// Ln Age (y)
			+ (11.853 * log(`chol'))					/// Ln Total Cholesterol (mg/dL)	
			+ (-2.664 * log(`age') * log(`chol'))		/// Ln Age × Ln Total Cholesterol	
			+ (-7.990 * log(`hdl'))						/// Ln HDL-C (mg/dL)
			+ (1.769 * log(`age') * log(`hdl'))			/// Ln Age × Ln HDL-C
			+ (1.797 * log(`sbp')) 						/// Ln Treated Systolic BP (mm Hg)
			+ (7.837 * `smoker')						/// Current Smoker (1=Yes, 0=No)
			+ (-1.795 * log(`age') * `smoker') 			/// Ln Age × Current Smoker	
			+ (0.658 * `diabetes')						/// Diabetes (1=Yes, 0=No)	
			if `female' == 0 & `black' == 0  & `trhtn' == 1 & `touse'				
			/* if `trhtn' == 0 */	
			replace `indrisk' = 						///			
			(12.344 * log(`age')) 						/// Ln Age (y)
			+ (11.853 * log(`chol'))					/// Ln Total Cholesterol (mg/dL)	
			+ (-2.664 * log(`age') * log(`chol'))	/// Ln Age × Ln Total Cholesterol	
			+ (-7.990 * log(`hdl'))						/// Ln HDL-C (mg/dL)
			+ (1.769 * log(`age') * log(`hdl'))			/// Ln Age × Ln HDL-C
			+ (1.764 * log(`sbp'))						/// Ln Untreated Systolic BP (mm Hg)
			+ (7.837 * `smoker')						/// Current Smoker (1=Yes, 0=No)
			+ (-1.795 * log(`age') * `smoker') 			/// Ln Age × Current Smoker	
			+ (0.658 * `diabetes')						/// Diabetes (1=Yes, 0=No)	
			if `female' == 0 & `black' == 0  & `trhtn' == 0 & `touse'				
			
			replace ascvd10 = round((1 - (0.9144^exp(`indrisk' - 61.18))) * 100, 0.01)	if `female' == 0 & `black' == 0  & `touse'			

		********************
		* Male and Black
		********************	
			/* if `trhtn' == 1 */
			replace `indrisk' = 						///
			(2.469 * log(`age')) 						/// Ln Age (y)
			+ (0.302 * log(`chol'))						/// Ln Total Cholesterol (mg/dL)	
			+ (-0.307 * log(`hdl'))						/// Ln HDL-C (mg/dL)
			+ (1.916 * log(`sbp'))						/// Ln Treated Systolic BP (mm Hg)
			+ (0.549 * `smoker')						/// Current Smoker (1=Yes, 0=No)
			+ (0.645 * `diabetes')						/// Diabetes (1=Yes, 0=No)
			if `female' == 0 & `black' == 1  & `trhtn' == 1 & `touse'				
			/* if `trhtn' == 0 */	
			replace `indrisk' = 						///						
			(2.469 * log(`age')) 						/// Ln Age (y)
			+ (0.302 * log(`chol'))						/// Ln Total Cholesterol (mg/dL)	
			+ (-0.307 * log(`hdl'))						/// Ln HDL-C (mg/dL)
			+ (1.809 * log(`sbp'))						/// Ln Untreated Systolic BP (mm Hg)
			+ (0.549 * `smoker')						/// Current Smoker (1=Yes, 0=No)
			+ (0.645 * `diabetes')						/// Diabetes (1=Yes, 0=No)	
			if `female' == 0 & `black' == 1  & `trhtn' == 0 & `touse'			

			replace ascvd10 = round((1 - (0.8954^exp(`indrisk' - 19.54))) * 100, 0.01) if `female' == 0 & `black' == 1  & `touse'	
			label var ascvd10 "ACC/AHA 2013 ASCVD risk score"
			

		if "`include'" != "" {	
			gen include = inrange(`age',40,79) & inrange(`chol',130,320) & inrange(`hdl',20,100) & inrange(`sbp',90,200)
			label var include "Patient values meet guidelines for inclusion"
			local incl include
		}	
			
		local ascvdvars ascvd10 `incl'
		char def _dta[ascvdvars] "`ascvdvars'" 
	
	} // end quietly	
	
end
