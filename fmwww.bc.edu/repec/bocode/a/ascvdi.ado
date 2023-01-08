*! 1.0.0 Ariel Linden 03jan2023 

/* 	

Computes 10-year risk for initial hard atherosclerotic cardiovascular disease (ASCVD) event 
(defined as first occurrence of non-fatal myocardial infarction, congestive heart disease death, or fatal or nonfatal stroke), from:

Goff Jr, D.C., Lloyd-Jones, D.M., Bennett, G., Coady, S., D'agostino, R.B., Gibbons, R., Greenland, P., Lackland, D.T., 
Levy, D., O'donnell, C.J. and J.G. Robinson. 2014. 2013 ACC/AHA guideline on the assessment of cardiovascular risk: 
a report of the American College of Cardiology/American Heart Association Task Force on Practice Guidelines. 
Circulation 129(25_suppl_2), S49-S73.
	
*/


program ascvdi, rclass
	version 13.0
	syntax ,  ///
		FEMale(integer)  			///
		BLAck(integer)  			///		
		AGE(numlist min=1 max=1)   	///
		CHOL(numlist min=1 max=1) 	///
		HDL(numlist min=1 max=1) 	///
		SBP(integer)  				///
		TRhtn(integer) 				///
		SMoker(integer) 			///
		DIABetes(integer) 			///
		[INClude]

	
		/* check to ensure binary variables contain 0 or 1 */
		if !inlist(`female',0,1)  {
			di as err "female must be coded as either 0 or 1"
			exit 498
		}
		if !inlist(`black',0,1)  {
			di as err "black must be coded as either 0 or 1"
			exit 498
		}
		if !inlist(`trhtn',0,1)  {
			di as err "trhtn must be coded as either 0 or 1"
			exit 498
		}
		if !inlist(`smoker',0,1)  {
			di as err "smoker must be coded as either 0 or 1"
			exit 498
		}
		if !inlist(`diabetes',0,1)  {
			di as err "diabetes must be coded as either 0 or 1"
			exit 498
		}
		
		tempname indrisk riskscore
	
		********************
		* Female and White
		********************
		if `female' == 1 & `black' == 0 { 
			if `trhtn' == 1 {
				local treatsbp = (2.019 * log(`sbp')) 
			}
			else if `trhtn' == 0 {
				local treatsbp = (1.957 * log(`sbp'))
			}	

			scalar `indrisk' = 							///
			(-29.799 * log(`age')) 						/// Ln Age (y)
			+ (4.884 * log(`age')^2) 					/// Ln Age, Squared
			+ (13.54 * log(`chol'))						/// Ln Total Cholesterol (mg/dL)	
			+ (-3.114 * log(`age') * log(`chol'))		/// Ln Age × Ln Total Cholesterol	
			+ (-13.578 * log(`hdl'))					/// Ln HDL-C (mg/dL)
			+ (3.149 * log(`age') * log(`hdl'))			/// Ln Age × Ln HDL-C
			+ `treatsbp'								/// 
			+ (7.574 * `smoker')						/// Current Smoker (1=Yes, 0=No)
			+ (-1.665 * log(`age') * `smoker') 			/// Ln Age × Current Smoker	
			+ (0.661 * `diabetes')						/// Diabetes (1=Yes, 0=No)	

			scalar `riskscore' = round((1 - (0.9665^exp(`indrisk' - -29.18))) * 100, 0.01)

		} // end female & white
	
		********************
		* Female and Black
		********************	
		if `female' == 1 & `black' == 1 { 
			if `trhtn' == 1 {
				local treatsbp = (29.291 * log(`sbp')) 
				local treatsbp_age = (-6.432 * log(`sbp') * log(`age'))
			}
			else if `trhtn' == 0 {
				local treatsbp = (27.82 * log(`sbp'))
				local treatsbp_age = (-6.087 * log(`sbp') * log(`age'))
			}	

			scalar `indrisk' = 							///
			(17.114 * log(`age')) 						/// Ln Age (y)
			+ (0.94 * log(`chol'))						/// Ln Total Cholesterol (mg/dL)	
			+ (-18.920 * log(`hdl'))					/// Ln HDL-C (mg/dL)
			+ (4.475 * log(`age') * log(`hdl'))			/// Ln Age × Ln HDL-C (mg/dL)	
			+ `treatsbp'								/// 
			+ `treatsbp_age'							/// 
			+ (0.691 * `smoker')						/// Current Smoker (1=Yes, 0=No)
			+ (0.874 * `diabetes')						/// Diabetes (1=Yes, 0=No)		

			scalar `riskscore' = round((1 - (0.9533^exp(`indrisk' - 86.61))) * 100, 0.01)

		} // end female & black	
		
		********************
		* Male and White
		********************			
		if `female' == 0 & `black' == 0 { 
			if `trhtn' == 1 {
				local treatsbp = (1.797 * log(`sbp')) 
			}
			else if `trhtn' == 0 {
				local treatsbp = (1.764 * log(`sbp'))
			}	

			scalar `indrisk' = 							///
			(12.344 * log(`age')) 						/// Ln Age (y)
			+ (11.853 * log(`chol'))					/// Ln Total Cholesterol (mg/dL)	
			+ (-2.664 * log(`age') * log(`chol'))		/// Ln Age × Ln Total Cholesterol	
			+ (-7.990 * log(`hdl'))						/// Ln HDL-C (mg/dL)
			+ (1.769 * log(`age') * log(`hdl'))			/// Ln Age × Ln HDL-C
			+ `treatsbp'								///
			+ (7.837 * `smoker')						/// Current Smoker (1=Yes, 0=No)
			+ (-1.795 * log(`age') * `smoker') 			/// Ln Age × Current Smoker	
			+ (0.658 * `diabetes')						/// Diabetes (1=Yes, 0=No)	

			scalar `riskscore' = round((1 - (0.9144^exp(`indrisk' - 61.18))) * 100, 0.01)

		} // end male & white		
	
		********************
		* Male and Black
		********************
		if `female' == 0 & `black' == 1 { 
			if `trhtn' == 1 {
				local treatsbp = (1.916 * log(`sbp')) 
			}
			else if `trhtn' == 0 {
				local treatsbp = (1.809 * log(`sbp'))
			}	

			scalar `indrisk' = 							///
			(2.469 * log(`age')) 						/// Ln Age (y)
			+ (0.302 * log(`chol'))						/// Ln Total Cholesterol (mg/dL)	
			+ (-0.307 * log(`hdl'))						/// Ln HDL-C (mg/dL)
			+ `treatsbp'								///
			+ (0.549 * `smoker')						/// Current Smoker (1=Yes, 0=No)
			+ (0.645 * `diabetes')						/// Diabetes (1=Yes, 0=No)	

			scalar `riskscore' = round((1 - (0.8954^exp(`indrisk' - 19.54))) * 100, 0.01)

		} // end male & black
		
		

		// display results
		di 
		di as txt "   10-Year ASCVD Risk Prediction: " as result %4.2f `riskscore' "%"
	
		if "`include'" != "" {	
			if inrange(`age',40,79) & inrange(`chol',130,320) & inrange(`hdl',20,100) & inrange(`sbp',90,200) {
				di as txt "   Patient values meet guidelines for inclusion"	
			}
			else {
				di as txt "   Patient values do not meet guidelines for inclusion"	
			}	
		} // end include	
		
		
		// return results
		return scalar ascvd10 = `riskscore'

end
	
