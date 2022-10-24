*! TMPM2: v2.0 2020.05.20 Osler and Cook. //
*! Calculates Trauma Mortality Prediction Model values //
*!  for each observation using AIS, ICD-9-CM and ICD-10-CM Codes. //


*! Journal page 19. 2020.05.23
*! Requires marc2_table

// Scalar definitions:
// TMO indicator for 1p1v 
// ADC a subsequent scalar for 1p1v

*! 2021.11.22

program tmpm2, rclass
version 11.0

syntax [varlist] [,  i(varname) inj(string) ais icd9 icd10 ]

quietly {
	local directory "`c(pwd)'/"
	*- identify the user's original file 
	scalar userfile = c(filename)
	capture save "usrtemp1x.dta", replace
	sort `i' 
	// Userfile WIDE OR LONG ? //               // ok 2020.07.19
	quietly findfile "usrtemp1x.dta"
	use `"`r(fn)'"'
	renpfix `inj' dxx
	keep `i' dxx*
		capture confirm string variable `i'
		if !_rc {
			}
			else {
				capture tostring `i', replace u
				}
	foreach v of varlist dxx* {
		confirm string variable `v'
			if !_rc {
				}
				else {
					capture tostring dxx*, replace u
					}
		}
	tempvar filelong ord
	quietly ds dxx*
	local ndx : word count `r(varlist)'
	gen `filelong'=(`ndx'==1)
	if `filelong'==0 {                                                          // 0 = WIDE
		reshape long dxx, i(`i') j(ord)                                         // RESHAPE LONG  
		drop if dxx==""
		drop ord `filelong'
		}
	compress
	sort dxx
	drop if dxx==""
	capture save "usrtemp2.dta", replace	
	// IDENTIFY LEXICON IN USER'S DATA THEN PREP marc2_table.dta //             // ok 2020.07.19
	quietly findfile "usrtemp2.dta"
	use `"`r(fn)'"'
	////////////////
	// ICD-10-CM  //
	////////////////
	if "`icd10'"!="" {                                                          // The data are ICD-10 lex2==1
		preserve
		findfile "marc2_table.dta"
		use `"`r(fn)'"', clear
		keep if lex2==1
		capture save "marc2_table2.dta", replace
		clear
		restore
		scalar lex2=1
		}
		else {                                                                  // The data are NOT ICD-10
			}
	////////////////
	// ICD-9-CM   //
	////////////////
		if "`icd9'"!="" {                                                       // The data are ICD-9 lex2==2
			gen trauma1 = (dxx>"799.99" & dxx<"960")
			keep if trauma1==1
			drop trauma1
			preserve
			findfile "marc2_table.dta"
			use `"`r(fn)'"', clear
			keep if lex2==2 
			capture save "marc2_table2.dta", replace
			clear
			restore
			scalar lex2=2
			}
			else {                                                              // The data are NOT ICD-10 or ICD-9
				}
	////////////////
	// AIS        //
	////////////////
			if "`ais'"!="" {                                                    // The data are AIS lex2==3
				preserve
				findfile "marc2_table.dta"
				use `"`r(fn)'"', clear
				keep if lex2==3
				capture save "marc2_table2.dta", replace
				clear
				restore
				scalar lex2=3
				}
				else {
					}
	clear
    *- Load User's data -*                                                      // MERGE WITH MARC TABLE ok 2020.07.19
	quietly findfile "usrtemp2.dta"
	use `"`r(fn)'"'
	quietly findfile "marc2_table2.dta"
	merge m:1 dxx using `"`r(fn)'"'                                     // MERGE
	keep if _merge==3
	drop _merge
	drop if marc2==. | `i'==""
	capture save "temp1.dta", replace							                //temp1
//
quietly {
	*Deal with "same region"
	use "temp1.dta", clear
	gsort `i' -marc2
	by `i', sort: gen n=_n
	gen sr=(rs==rs[_n+1] & (`i'==`i'[_n+1] & n==1))
	replace sr=1 if (`i'==`i'[_n-1] & sr[_n-1]==1)
	sort `i'
	drop if n>5
	keep `i' sr marc2
	capture save "temp2.dta", replace
	clear
	use "temp2.dta", clear
	by `i', sort: gen N=_N                                                      // `i'
	by `i', sort: gen orig=_n
	expand 5 if N<5, gen(new)
	sort `i' new orig, stable
	replace marc2=0 if new==1
	bys `i': drop if _n>5 & new==1
	keep `i' marc2 sr
	bys `i': gen ord=_n
	reshape wide marc2, i(`i') j(ord)
	if lex2==1 {                                                                // Data are ICD-10
		foreach v of varlist marc21- marc25 {
			replace `v'=0 if `v'==.
			}
		gen Imarc=marc21*marc22                                                 // generate the interaction term
			replace Imarc=0 if Imarc==.
		gen xBeta=(0.48840329*marc21) + ///
			(0.50077127*marc22)       + ///
			(0.33604308*marc23)       + ///
			(0.30354563*marc24)       + ///
			(0.41945388*marc25)       + ///
			(-0.06767112*Imarc)       + ///
			(-0.04381364*sr)         + ///
			(-2.2846757)
		foreach v of varlist marc2* {
			replace `v'=0 if `v'==.
			}
		capture save "XBeta_checktemp.dta", replace
		gen pDeath=normal(xBeta)
		format pDeath %08.6f
		lab var pDeath "Prob Death ICD-10"
		keep `i' pDeath
		sort `i'
		compress
		capture save "id_pdeath.dta", replace
		clear
		}
		else {
			if lex2==2 {                                                        // Data are ICD-9
				foreach v of varlist marc2* {
					replace `v'=0 if `v'==.
					}
				gen Imarc=marc21*marc22                                         // generate the interaction term
					replace Imarc=0 if Imarc==.
				gen xBeta =	(1.406958*marc21) + ///
					(1.409992*marc22)         + ///
					(0.5205343*marc23)        + ///
					(0.4150946*marc24)        + ///
					(0.8883929*marc25)        + ///
					(-0.0890527*sr)          + ///
					(-0.7782696*Imarc)        + ///
					(-2.217565)
				foreach v of varlist marc2* {
					replace `v'=0 if `v'==.
					}
				gen pDeath=normal(xBeta)
				format pDeath %08.6f
				lab var pDeath "Prob Death ICD-9"
				order `i' pDeath
				keep `i' pDeath
				sort `i'
				compress
				capture save "id_pdeath.dta", replace
				clear
				}
				else {
					if lex2==3   {                                              // Data are AIS
					foreach v of varlist marc2* {
							replace `v'=0 if `v'==.
							}
					gen Imarc=marc21*marc22                                     // generate the interaction term
						replace Imarc=0 if Imarc==.
					gen xBeta=(1.3142935*marc21)  + ///
						(1.2505921*marc22)        + ///
						(0.62937847*marc23)       + ///
						(0.61438086*marc24)       + ///
						(0.97266839*marc25)       + ///
						(-0.06138731*sr)          + ///
						(-0.46506898*Imarc)       + ///
						(-2.5658983)
					foreach v of varlist marc2* {
						replace `v'=0 if `v'==.
						}
					gen pDeath =normal(xBeta)
					format pDeath %08.6f
					lab var pDeath "Prob Death AIS"
					order `i' pDeath
					keep `i' pDeath
					sort `i'
					capture save "id_pdeath.dta", replace
					clear
					}
				}
			}
	quietly findfile "usrtemp1x.dta"
	use `"`r(fn)'"', clear
	sort `i'
	merge m:1 `i' using "id_pdeath.dta", nogenerate norep
	scalar drop lex2
	erase "usrtemp1x.dta"
	erase "usrtemp2.dta"
	erase "marc2_table2.dta"
	erase "id_pdeath.dta"
	erase "temp1.dta"
	erase "temp2.dta"
	}
	}
end
exit
	
	
	
	
	
	
	
	
	
	
	
	
	

	
	
	
	
	
	
	
	
	
	
	
	
	
		
	


	




