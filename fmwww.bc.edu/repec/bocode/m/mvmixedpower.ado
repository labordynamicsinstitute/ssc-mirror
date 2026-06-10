*! version 1.0	1.6.2026
*! Matthew Burnell


/*
DESCRIPTION
mvmixedpower is a power and sample size calculator routine for multivariate linear mixed models.
*/

program define mvmixedpower , rclass
	version 17.0 
	syntax,	SCHEDule(numlist ascending >=0 max=100)	/// schedule list of time incl. baseline
			TRTSPEC(string)							/// how treatment effect specified (slope, intercept or factorised (factor, factor0))
			[   									///
			TEST(string)  							/// direct test of parameter or a lincom test
			CONTSlope(string) 						/// the overall mean slope of the 'control' group
			EFFectiveness(string)  					/// proportionate effect on slope (not for other trtspec types)
			DIFFerence(string)   					/// the alternative hypothesis difference (numberlist for factor choice in trtspec)						
			ACTUALTRT(string)						/// calculate power for an incorrect treatment specification, by specifying the true treatment specification 
			ACTUALCont(string)						/// if you also want to indicate that the control specification is incorrect, hence give correct specification 
			Multi(numlist integer >=2 <=6 max=1) 	/// dimension (=m) for multivariate model
			WEIghting(string) 						/// weighting for m outcome variables incl. IVW in multivariate model
			Alpha(real 0.05) 						/// alpha level of test	
			TWOSided								/// request properly two-sided test
			POWer(string) 							/// required power 
			n(string) 								/// provided sample size
			ARAtio(numlist integer >0  max=2)	/// allocation ratio of controls:treatment FORMULA VERSION */
			ALLORatio(numlist integer >0 <=10 max=2) 	///	allocation ratio of controls:treatment MULTIMATRIX VERSION - to be hidden in help file 
 			DROPouts(numlist >=0 <=1))  			///	numlist values of p(making visit to k and no further) due to dropout
			DROP2(numlist >=0 <=1)					/// numlist values of p(making visit to k and no further) for Treatment Group if different to Control
			STRECruitment(numlist >=0 <=1) 			///	numlist values of p(making visit to k and no further) due to staggered recruitment
			COVariance(string) 						///	covariance matrix of random effect parameters
			ERRorvar(string) 						/// error term ( matrix for multivariate)
			AUTO									/// speedy variance input using mixed model in memory
			///COVHET(string) 								covariance matrix of random effect parameters for treatment group if different			
			SCAle(real 1)  							/// to specify schedule numlist in different scale to variance input
			NOSYNtax								/// prevent display of model syntax
			NOTABle									/// no table of counts
			NOHEADer								/// turn off header
			XMAT(numlist integer >=1 max=1)			/// return specific X matrix
			RMAT(numlist integer >=1 max=1)			/// return specific R matrix
			ZMAT(numlist integer >=1 max=1)			/// return specific Z matrix
			GMAT(numlist integer >=1 max=1)			/// return specific G matrix
			BVARN(numlist integer >=1 max=1)		/// return specific Beta covariance matrix
			FRAMES(string)							/// HIDDEN OPTION keep frames of generated X, R, Z and G matrices
			FRDROP									/// HIDDEN OTPION use to drop _mp frames from previous run of mixedpower when frames(keep) option used - might not (depending on _mp name) run otherwise unless manually dropped first. 
			IVW										/// HIDDEN OTPION to use IVW instead of inverse-covariance weighting for calculating cohort-combined Betas with X-misspecification   
			]


		
			
	local cframe=c(frame)	
	if strmatch("`cframe'","_mp_2level*" )==1 | strmatch("`cframe'","_mp_multi*" ) ==1 | strmatch("`cframe'","_mp_direct*" )==1 | strmatch("`cframe'","_mp_3level*" )==1 {
		di as error "You are running mixedpower whilst currently active with a mixedpower derived frame. You need to first change (back) to a different frame, likely 'default'. See {help frames}, including {help frame dir} and {help frame change}"
		exit 198
	}	
	else return local fr_current `cframe'
	
		*** see if previous command was trialcounts and return that cmdline
	local commandline `=r(cmdline)'
	gettoken command  : commandline
	if strmatch("`command'","trialcounts")==1 {
		return local trialcounts_cmd `commandline'
	}

**# required options

** Schedule list - inbuilt Stata syntax check is sufficient for parsing SCHEDule

	* Length of schedule list:
		local sched_length = 0
		foreach i of numlist `schedule' {
			local sched_length = `sched_length' + 1			
			}
		
	* Decant the schedule numlist into locals
		tempname schedmat
		mat `schedmat'=J(1,`sched_length',0)
		local j = 1 // counter - position number
		foreach i of numlist `schedule' {
			local sched`j' = `i'		
			mat `schedmat'[1,`j']=`sched`j''
			local j=`j'+1
		}


		* for inserting into prior code as model label
	local model multi
	
	
	


	if "`trtspec'"!="slope" {
			if "`trtspec'"!="intercept" {
				display as error "Currently only slope or intercept treatment effects allowed with mvmixedpower"  
					exit 198 
			}
		}
	  

	if "`altcont'"!="" {
				display as error "Currently altcont() not allowed with mvmixedpower" 
					exit 198 
		}
	  
				
							
	/*
				** And treatment specification type is chosen and correct - if not chosen then assume 
if strmatch("`trtspec'", "user(*)") local tusertext `trtspec' // to pass to 3level to parse again
if strmatch("`altcont'", "user(*)") local cusertext `trtspec'
			*/
			
			/* define trtspec type */

				
				foreach trtsp in slope intercept factor factor0 slint {
					if "`trtspec'"=="`trtsp'" {
						local tscheck yes
					}
				}
				if 	"`tscheck'"=="yes" local trtspec "`trtspec'"
				else if strmatch("`trtspec'", "lateslope *") { // lateslope with time value at separation
					local lslt =subinstr("`trtspec'", "lateslope ", "", 1)
					xslopecheck, xnum(`lslt') option(trtspec) spec(lateslope #)
					local trtspec "lateslope"
				}	
				else if strmatch("`trtspec'", "2slope *") { // 2slope with time value at changepoint
					local tslt =subinstr("`trtspec'", "2slope ", "", 1)
					xslopecheck, xnum(`tslt') option(trtspec) spec(2slope #)
					local trtspec "2slope"
				}
				else if strmatch("`trtspec'", "user(*)") { // user provided function
					local tuser =subinstr("`trtspec'", "user", "", 1)
					usercheck, func(`tuser') option(trtspec) xvalues(`schedule')
					local trtspec "user"
					local tuserf_n =`s(nfun)'
					local txfun_1 `s(xfun1)'
					local tfunc_1 `s(funct1)'
					if `tuserf_n'==2 {
						local txfun_2 `s(xfun2)'
						local trtspec "user2"
						local tfunc_2 `s(funct2)'
					}
				}
				else {
					display as error "trtspec() type must be one of 'slope', 'intercept', 'factor', 'factor0' (factorised including term at baseline), 'lateslope #' '2slope #', 'slint' (slope and intercept terms) or 'user(f1[; f2]"
					exit 198
				}
				
					/* define altcont type */
		if "`altcont'"==""	local altcont slint	
		
		foreach contsp in noslope noint factor slint  {
			if "`altcont'"=="`contsp'" {
				local cscheck yes
			}
		}
		if 	"`cscheck'"=="yes" local altcont "`altcont'"
				else if strmatch("`altcont'", "2slope *") { // 2slope with time value at changepoint
					local Ctslt =subinstr("`altcont'", "2slope ", "", 1)
					xslopecheck, xnum(`Ctslt') option(altcont) spec(2slope #)
					local altcont "2slope"
				}
				else if strmatch("`altcont'", "user(*)") { // user provided function
					local cuser =subinstr("`altcont'", "user", "", 1)
					usercheck, func(`cuser') option(altcont) xvalues(`schedule')
					local altcont "user"
					local cuserf_n =`s(nfun)'
					local cxfun_1 `s(xfun1)'
					local cfunc_1 `s(funct1)'
					if `cuserf_n'==2 {
						local cxfun_2 `s(xfun2)'
						local altcont "user2"
						local cfunc_2 `s(funct2)'
					}
					 
				}
				else {
					display as error "Alternative cont model - altcont() - types are one of 'noslope' (no slope i.e intercept only), 'noint' (no intercept i.e slope only), '2slope #', 'factor' or 'user(f1[; f2]. The default, not actively selected, is both slope and intercept terms"
					exit 198
				}
		
		
		** checking that if 2slope selected for both control and treatment - that changepoint is at same value of taken
		if "`trtspec'"=="2slope" & "`altcont'"=="2slope" {
				if `tslt'!=`Ctslt' {
					di as error "if '2slope' selected for both altcont() and trtpsec() then changepoint selected for both options must be the same"
					exit 198
			}
		}
	
	
	if "`actualtrt'"!="" {
		di as error "actualtrt() not allowed with mvmixedpower"
		exit 198
	}
	if "`actualcont'"!=""  {
		di as error "actualtrt() not allowed with mvmixedpower"
		exit 198
	}
	
					** Equivalent treatment and control checks for when actualtrt() and actualcont() specified 

				
			/* define actualtrt type */
			
				foreach atrtsp in slope intercept factor factor0 slint {
					if "`actualtrt'"=="`atrtsp'" {
						local atscheck yes
					}
				}
				if 	"`atscheck'"=="yes" local actualtrt "`actualtrt'"
				else if strmatch("`actualtrt'", "lateslope *") { // lateslope with time value at separation
					local alslt =subinstr("`actualtrt'", "lateslope ", "", 1)
					xslopecheck, xnum(`alslt') option(actualtrt) spec(lateslope #)
					local actualtrt "lateslope"
				}	
				else if strmatch("`actualtrt'", "2slope *") { // 2slope with time value at changepoint
					local atslt =subinstr("`actualtrt'", "2slope ", "", 1)
					xslopecheck, xnum(`atslt') option(actualtrt) spec(2slope #)
					local actualtrt "2slope"
				}
				else if strmatch("`actualtrt'", "user(*)") { // user provided function
					local atuser =subinstr("`actualtrt'", "user", "", 1)
					usercheck, func(`atuser') option(actualtrt) xvalues(`schedule')
					local actualtrt "user"
					local atuserf_n =`s(nfun)'
					local atxfun_1 `s(xfun1)'
					local atfunc_1 `s(funct1)'
					if `atuserf_n'==2 {
						local atxfun_2 `s(xfun2)'
						local actualtrt "user2"
						local atfunc_2 `s(funct2)'
					}
				}
				else if "`actualtrt'"=="" {
				}
				else {
					display as error "actualtrt() type must be one of 'slope', 'intercept', 'factor', 'factor0' (factorised including term at baseline), 'lateslope #' '2slope #', 'slint' (slope and intercept terms) or 'user(f1[; f2]"
					exit 198
				}
				
					/* define actualcont type */
		
		
		foreach acontsp in noslope noint factor slint  {
			if "`actualcont'"=="`acontsp'" {
				local acscheck yes
			}
		}
		if 	"`acscheck'"=="yes" local actualcont "`actualcont'"
				else if strmatch("`actualcont'", "2slope *") { // 2slope with time value at changepoint
					local aCtslt =subinstr("`actualcont'", "2slope ", "", 1)
					xslopecheck, xnum(`aCtslt') option(actualcont) spec(2slope #)
					local actualcont "2slope"
				}
					else if strmatch("`actualcont'", "user(*)") { // user provided function
					
					local acuser =subinstr("`actualcont'", "user", "", 1)
					usercheck, func(`acuser') option(actualcont) xvalues(`schedule')
					local actualcont "user"
					local acuserf_n =`s(nfun)'
					
					local acxfun_1 `s(xfun1)'
					local acfunc_1 `s(funct1)'
					if `acuserf_n'==2 {
						local acxfun_2 `s(xfun2)'
						local actualcont "user2"
						local acfunc_2 `s(funct2)'
					}
				}
				else if "`actualcont'"=="" {
				}
				else {
					display as error "Actual control model - actualcont - types are one of 'slint' (slope and intercept) 'noslope' (no slope i.e intercept only), 'noint' (no intercept i.e slope only), '2slope #', 'factor' or 'user(f1[; f2]. "
					exit 198
				}
		

		
			** Checking Test Options
	if "`trtspec'"=="slope" |  "`trtspec'"=="intercept" |  "`trtspec'"=="lateslope" | "`trtspec'"=="user"   {
		if "`test'"=="paired" {	// secret paired z-test
		}
		else if "`test'"!="" {
			dis as error  "test() is not specified when trtspec() is 'slope', 'intercept', 'lateslope' or 'user'"
					exit 198
		}
	}
	
	else if "`test'"!="ivw" & "`test'"!="factorslope" & "`test'"!="factorint" & strmatch("`test'","joint(*)")==0 { 
				testcheck,  tsp(`trtspec') schl(`sched_length') test(`test')
				qui numlist "`test'"     // in unlikely event someone uses numlist style entry of test!
				local test=r(numlist)
			}	
			
	if strmatch("`test'","joint(*)")==1 {
		local joint=subinstr("`test'", "joint(", "", 1)
		local joint=subinstr("`joint'", ")", "", 1)
		
		testcheck,  tsp(`trtspec') schl(`sched_length') test(`joint') xtra(joint())
		local jointlength : word count `joint'
	
			local df_jt=0
			forvalues jt=1/`jointlength' {
				local joint`jt' : word `jt' of `joint'
				 if `joint`jt''!=0 local df_jt=`df_jt'+1
			}	
	}

	
	  ** Making sure either errorvar is specified (when auto not used)

	  if "`auto'"=="" {
		  if "`errorvar'"==""  {
			dis as error "You must specify errorvar() if not using auto option"
						exit 198
		  }
	  }

		local errmethod errmethod
	  

				** Check either auto or (ERRorvar & COVariance) used
								
	if "`covariance'"!="" & "`auto'"!="" {
					dis as error "You cannot specify both covariance() (together with errorvar()) and auto"
					exit 198
				}
	if "`covariance'"=="" & "`auto'"=="" {
					dis as error "No covariance parameter specification: please specify either covariance() and errorvar() OR auto "
					exit 198
				}
				
				* check errorvar and auto not both specified
	if "`errorvar'"!="" & "`auto'"!="" {
					dis as error "You cannot specify both errorvar() (together with covariance()) and auto"
					exit 198
				} 
				* Check  error variance included if covariance used 
	if "`covariance'"!="" & "`errmethod'"=="" {
					dis as error "You must specify  errorvar() with covariance()"
					exit 198
				}
				* Check covariance included if errorvar used 
	if "`covariance'"=="" & "`errorvar'"!="" {
					dis as error "You must specify covariance() with errorvar()"
					exit 198
				}
			
	if "`auto'"!=""  & "`e(cmd)'"!="mixed" {
		di as error "there is no mixed model fitted by {helpb mixed} in memory"
		exit 198
	}
			

				** Check Covariance values
					
				* Check COVariance is correctly specified in matrix format
		if "`covariance'"!=""  {
					tempname cm
					capture mat `cm'=  `covariance' // first checking matrix supplied in correct format
						if  _rc!=0 {
									dis as error "entry for covariance() not in matrix format"
						exit 198
								}
					capture confirm matrix `cm'  // first checking matrix supplied in correct format
					if  _rc!=0 {
									dis as error "matrix entry for covariance() not correct format"
						exit 198
								}
					}
					
					
		else if "`auto'"!="" & "`=e(redim)'"=="0" { // RE CHECK
			di as error "mixed model in memory has no random effects"
			exit 198
		}
		else if "`auto'"!="" & `=e(k_r)'==1 {  // RE CHECK
			di as error "mixed model in memory has no random effects"
			exit 198
		}	
		
		
		if "`covhet'"!=""  {
			local covhet=strtrim("`covhet'")
			if strmatch("`covhet'", "auto") local chtype chauto
			else if strmatch("`covhet'", "input(*)") {  // checking the auto suboptions
				local chtype chinput
				local chmat=subinstr(`"`covhet'"', "input(", "", 1)
				local chmat=strtrim(subinstr("`chmat'", ")", "", 1))
				tempname chm
				capture mat `chm'=  `chmat' // first checking matrix supplied in correct format
					if  _rc!=0 {
								dis as error "entry for covhet() not in matrix format"
					exit 198
							}
				capture confirm matrix `chm'  // first checking matrix supplied in correct format
				if  _rc!=0 {
								dis as error "entry for covhet() not in matrix format"
					exit 198
							}
				}
			else { 
				di as error "covhet() must be specified as 2mx2m symmetric matrix using input() suboption or use auto-input of variance parameters with auto suboption"
			}	
		}
		 
			
			
** CHECKING CORRECT INPUTS FOR TRTSPEC CHOICE - 
				
* IF: trtspec=="slope" Check either used: Effectiveness + CONTSlope OR Difference 
			
		if "`trtspec'"=="slope" {
				* check effectiveness and edifference not both specified
					if "`effectiveness'"!="" & "`difference'"!="" {
					dis as error "You cannot specify both effectiveness() (together with contslope()) and difference()"
					exit 198
				}
				* check one of effectiveness and difference  specified
				if "`effectiveness'"=="" & "`difference'"=="" {
					dis as error "No target slope effect specification: please specify either effectiveness() and contslope() OR difference()"
					exit 198
				}
				
				* check contslope and difference not both specified
				if "`contslope'"!="" & "`difference'"!="" {
					dis as error "You cannot specify both contslope() (together with effectiveness()) and difference()"
					exit 198
				} 
				* check contslope and effectiveness both specified 
				if "`effectiveness'"!="" & "`contslope'"=="" {
					dis as error "You must specify both effectiveness() and contslope()"
					exit 198
				}
				* check contslope and effectiveness  both specified 
				if "`effectiveness'"=="" & "`contslope'"!="" {
					dis as error "You must specify both effectiveness() and contslope()"
					exit 198
				}
					
			}		
	
	
		if "`trtspec'"=="intercept" {	
			if  "`difference'"=="" {
					dis as error "You must specify difference() when trtspec() is 'intercept'"
					exit 198
			} 
			if  "`contslope'"!="" {
					dis as error "You must specify difference() ONLY when trtspec() is 'intercept'"
					exit 198
			}		
			if  "`effectiveness'"!="" {
					dis as error "You must specify difference() ONLY when trtspec() is 'intercept'"
					exit 198
			} 		
					
		}  
		
		if "`trtspec'"=="intercept" | "`trtspec'"=="factor" | "`trtspec'"=="factor0" | "`trtspec'"=="slint" | "`trtspec'"=="lateslope" | "`trtspec'"=="2slope" | "`trtspec'"=="user" | "`trtspec'"=="user2" {	
			if  "`difference'"=="" {
					dis as error "You must specify difference() when trtspec() is 'intercept'" //, 'factor', 'factor0', 'slint', 'lateslope', '2slope' or 'user'"
					exit 198
			} 
			if  "`contslope'"!="" {
					dis as error "You must specify difference() ONLY when trtspec() is 'intercept'" //, 'factor', 'factor0', 'slint', 'lateslope', '2slope' or 'user'"
					exit 198
			}		
			if  "`effectiveness'"!="" {
					dis as error "You must specify difference() ONLY when trtspec() is 'intercept'" //, 'factor', 'factor0', 'slint', 'lateslope', '2slope' or 'user'"
					exit 198
			} 			
					
		}  
		
		* Now check effectiveness is a number >0 and <= 1 or  if model==multi, then check contslope
					
		if "`effectiveness'"!="" { // Effectiveness is specified
			local meff_length = 0
			
			foreach i in `effectiveness' {
				capture confirm number `i'
					if _rc!=0 {
					dis as error "Each part of effectiveness() must be a number greater than 0 and less than or equal to 1"
					exit 198
				}
				* So eff is specified and it's a number
				if `i' > 1 {
					dis as error "Each part of effectiveness() must be less than or equal 1"
					exit 198
				}
				if `i' <=0 {
					dis as error "Each part of effectiveness() must be strictly greater than 0"
					exit 198
				}	
				local eff_length = `eff_length' + 1			
				}
				if `eff_length'==1 | `eff_length'==`multi' {
				}
				else {
					dis as error "effectiveness() must be single number (to be repeated for all m dimensions) or of length m"
					exit 198
				}
				if `eff_length'==1 {
					local mefx
					forvalues m=1/`multi' {
						local mefx "`mefx' `effectiveness'"
					}
				local effectiveness `mefx'
				}							
										
			* Now check contslope is a number - or numlist - not allowing name of variable from mixed model in memory
			if "`contslope'"!="" { // contslope is specified
				local mn_length = 0
				foreach i in `contslope' {
					capture confirm number `i'
						if _rc!=0 {
						dis as error "Each part of contslope() must be a number"
						exit 198
					}
		
					local mn_length = `mn_length' + 1			
					}
					if `mn_length'==1 | `mn_length'==`multi' {
					}
					else {
						dis as error "contslope() must be single number (to be repeated for all m dimensions) or of length m"
						exit 198
					}
					if `mn_length'==1 {
						local mnslope 
						forvalues mu=1/`multi' {
							local mnslope "`mnslope' `contslope'"
							
						}
					local contslope "`mnslope'"
					}	

				}  
						
		} // If statement "eff is specified" 
		
		 
	**Checking difference is correctly specified for various trtspec choices 
									
		*  check if using difference that it is a number or numlist if trtspec is slope 
		
		if "`trtspec'"=="slope" | "`trtspec'"=="intercept" {
			if "`difference'"!="" { // difference is specified
				local md_length = 0
					foreach i in `difference' {
						capture confirm number `i'
							if _rc!=0 {
							dis as error "Each part of difference() must be a number"
							exit 198
						}
			
						local md_length = `md_length' + 1			
						}
						if `md_length'==1 | `md_length'==`multi' {
						}
						else {
							dis as error "difference() under trtspec(intercept) or trtspec(intercept) must be single number (to be repeated for all m dimensions) or of length m"
							exit 198
						}
						if `md_length'==1 {
							local mdelta 
							forvalues m=1/`multi' {
								local mdelta "`mdelta' `difference'"
							}
						local difference "`mdelta'"	
						}
			}
			local altvarX=1
		}	
		
	
			
				* check difference  is a 1xn or mxn matrix if trtspec is factor (piecewise)  
		if "`trtspec'"=="factor0" {
			if "`difference'"!="" { // difference is specified
				tempname mdm
				capture mat `mdm'=  `difference' // first checking matrix supplied in correct format
				if  _rc!=0 {
								dis as error "matrix entry for difference() with trtspec(factor) choice not correct format"
					exit 198
							}
				capture confirm matrix `mdm'  // first checking matrix supplied in correct format
				if  _rc!=0 {
								dis as error "matrix entry for difference() with trtspec(factor) choice not correct format"
					exit 198
					}
					
				local mdcol=colsof(`difference')
				if `mdcol' != `sched_length' {
					dis as error _n "matrix of difference() effects under trtspec(factor0) must be same length as visit schedule or matrix of dimension m x n"
					exit 198
				}
				local mdrow=rowsof(`difference')
				if `mdrow'==1 | `mdrow'==`multi' {
						}
					else {
							dis as error "difference()  under trtspec(factor0) must be matrix of dimension 1 x n or m x n"
							exit 198
						}
				
			}	
				local altvarX=`sched_length'  // for later in picking out elements of 'test'
		}	
		
		// need to add factor, slint, lateslope, 2slope???

	
		**cbeta - Control beta if actualcont() specified
		if "`cbeta'"!="" & "`actualcont'"=="" {
			di as error "cbeta() cannot be specified without actualcont()"
			exit 198
		}
		if "`actualcont'"!="" {
			if "`cbeta'"=="" {
				di as error "actualcont() cannot be specified without cbeta()"
				exit 198
			}
			local actcontlength : word count  `cbeta'
				if "`actualcont'"=="slint" {
					if `actcontlength'!=2 {
						di as error "cbeta() must be of length 2 if actualcont() is 'slint'"
						exit 198					
					}
				}
				if "`actualcont'"=="noslope" {
					if `actcontlength'!=1 {
						di as error "cbeta() must be of length 1 if actualcont() is 'noslope'"
						exit 198					
					}
				}
				if "`actualcont'"=="noint" {
					if `actcontlength'!=1 {
						di as error "cbeta() must be of length 1 if actualcont() is 'noint'"
						exit 198					
					}
				}
				if "`actualcont'"=="factor" {
					if `actcontlength'!=`sched_length' {
						di as error "cbeta() must be equal to schedule() length if actualcont() is 'factor'"
						exit 198					
					}
				}	
				if "`actualcont'"=="2slope" {
					if `actcontlength'!=3 {
						di as error "cbeta() must be of length 3 if actualcont() is '2slope #'"
						exit 198					
					}	
				}	
				if "`actualcont'"=="user" {
					if `actcontlength'!=2 {
						di as error "cbeta() must be of length 2 if actualcont() is 'user' with one function"
						exit 198					
					}	
				}
				if "`actualcont'"=="user2" {
					if `actcontlength'!=3 {
						di as error "cbeta() must be of length 3 if actualcont() is 'user' with two functions"
						exit 198					
					}
				}	
		}
	
		
			
		
* ALPHA: Should be between 0 and 1 
				
	if `alpha'<=0 | `alpha'>1 {
					dis as error "Alpha() must be a number greater than 0 and less than 1"
					exit 198
				}
					
		* ALLORAtio - allocation ratio weightings MULTIMATRIX VERSION - inbuilt Stata syntax check is sufficient for parsing ALLORatio

		if "`alloratio'"!="" {
			local allratio `alloratio'
		}
		else {
			local allratio 1 1
		}
		local ar1: word 1 of `allratio' // for use in matrix creation
		local ar2: word 2 of `allratio' 
		local arsum=`ar1'+`ar2' // for use later in power/SS calculations to reweight for 'number' in trial
		
	
			* ARAtio - allocation ratio Sigma adjust VERSION - inbuilt Stata syntax check is sufficient for parsing ARAtio
		
		if "`alloratio'"!="" & "`aratio'"!="" {
			dis as error "You are using both the ALLORatio() option and the secret ARatio() option - don't!"
							exit 198
		}
		
		if "`aratio'"!="" {
			
			local ar1: word 1 of `aratio'
			local ar2: word 2 of `aratio' 
			local arsum=`ar1'+`ar2' // for use later in power/SS calculations to reweight for 'number' in trial
				
		}
		
		
*POWER AND N 	- TO BE CHANGED TO INCLUDE DETECTABLE DIFFERENCE??
				
	* Must specify one of power or N: 4 possible cases...
* 1. 1. Both power an n specified - error
					
	if "`power'"!="" & "`n'"!="" {
							display as error "Only one of power() and n() may be specified, not both"
							exit 198
							}
							
* 2. Power is specified, n is missing - okay - we'll calculate SAMPLE SIZE (N)

	if "`power'"!="" & "`n'"=="" {
							local given_power=real("`power'")
							if missing(`given_power') { // ...but power isn't a number
								dis as error "Power() must be a number greater than 0 and less than 1"
								exit 198
							}
							local power_or_n power
						}
						
* 3. Power is absent, n is specified - okay - we'll calculate POWER
						
	if "`power'"=="" & "`n'"!="" { // 
							local given_n=floor(real("`n'"))
							if missing(`given_n') { // ...but n isn't a number
								dis as error "n() must be a numerical value"
								exit 198
							}
	if `given_n' != `n' { // The floor of n must be the same as n... ie n cannot be fractional
								dis as error "n() must be a whole number greater than or equal to 2"
								exit 198
							}
	if `given_n' < 2 { // N must be at least 2
								dis as error "n() must be at least 2"
								exit 198
							}
							local n = ceil(`given_n')
							local power_or_n n
						}
						
* 4. Both power and n absent: okay, use default value for power - we'll calculate SAMPLE SIZE (N)
	if "`power'"=="" & "`n'"=="" {
							local given_power = 0.8 // Default power is 80%
							local power_or_n power
						}
				* Check values
	if "`power_or_n'"=="power" { // Power is specified - we already know it's a number.
						if `given_power'>=1 {
							dis as error "Power() must be a value strictly less than 1"
							exit 198
						}
						if `given_power'<=0 {
							dis as error "Power() must be a value greater than 0"
							exit 198
						}
					}
					if "`power_or_n'" == "n" { // N is specified - we already know it's a number
						* Make sure it's even, or round down
						local actual_n = `arsum'* floor(`given_n' / `arsum')
						if "`model'"=="3level" & "`crt'"=="" local actual_n = `given_n' 
						if `given_n'<`arsum' & "`model'"!="3level" & "`crt'"!="" {
							dis as error "n must be a number greater or equal to `arsum' - the allocation ratio sum"
							exit 198
						}
					}

	
* SCALE  
			
	if `scale' <= 0 {
						dis as error "Scale() must be a positive number"
						exit 198
					}
		
* FRAMES 

	* to keep or not
		if "`frames'"=="" {
			local frames "drop"
		}	
		else if "`frames'"=="keep" {
			local frames "keep"
		}
		else  {
				display as error "only acceptable entry for frames() is 'keep'"
					exit 198
		}
	
* DROPPING _MP FRAMES	
		if "`frdrop'"!="" {
			qui capture frame drop _mp*
		}

* DROPOUTS    
	* Is there a dropout list specified?
		local drop_yes = 0
		if "`dropouts'"!="" local drop_yes = 1
		
	* Drop matrix must be same length as Schedule matrix
			* Length of dropout list
		if `drop_yes'==1 {	
			local drop_length = 0
			foreach i of numlist `dropouts' {
				local drop_length = `drop_length ' + 1
			}
			* Is this equal to schedule matrix?
			if `sched_length' != `drop_length' {
				dis as error  "Dropouts() list must correspond in length (`drop_length') with visit schedule (`sched_length')"
				exit 198
			}
		}
		
	* Decant dropout numlist into locals and calculate people who attend all visits
		local dfrac_left = 1 // The proportion attending all visits - one unless dropouts specified
	
		if `drop_yes'==1 {
			local j = 1 // counter - position number
			foreach fr of numlist `dropouts' {
				local dfrac`j' = `fr'
				local j = `j' + 1
				local dfrac_left = `dfrac_left' - `fr'
				
					}
		* Check the drop matrix adds up = 1 (100%) (with tolerance allowed)
			if `dfrac_left' < -0.000001 | `dfrac_left' > 0.000001 {
				display as error  "Dropout probabilities must sum to 1: list sums to `=1-`dfrac_left''"
				exit 198
				}	
			}

		
		tempname drops
		mat `drops'=J(1,`sched_length',0)	
		if "`dropouts'"!="" {
			forvalues dr=1/`sched_length' {
				local drpo: word `dr' of `dropouts'
				mat `drops'[1,`dr']=`drpo'
			}
		}
	
		if "`dropouts'"=="" {
			mat `drops'[1,`sched_length']=1
		}
		 return mat dropouts=`drops'	
		
		* DROP2 - Different Treatment dropout rate   
	* Is there a 2nd dropout list specified?
		local drop2_yes = 0

		if "`drop2'"!="" local drop2_yes = 1
		
		if `drop2_yes'==1 & `drop_yes'==0 {
			di as error "Cannot specify drop2() if dropouts() not also selected"
			exit
		}
		
	* Drop2 matrix must be same length as Schedule matrix
			* Length of drop2 list
		if `drop2_yes'==1 {	
			local drop2_length = 0
			foreach i of numlist `drop2' {
				local drop2_length = `drop2_length ' + 1
			}
			* Is this equal to schedule matrix?
			if `sched_length' != `drop2_length' {
				dis as error  "Drop2() list must correspond in length (`drop2_length') with visit schedule (`sched_length')"
				exit 198
			}
		}
		
	* Decant dropout numlist into locals and calculate people who attend all visits
		local dfrac2_left = 1 // The proportion attending all visits - one unless dropouts specified
	
		if `drop2_yes'==1 {
			local j = 1 // counter - position number
			foreach fr of numlist `drop2' {
				local d2frac`j' = `fr'
				local j = `j' + 1
				local dfrac2_left = `dfrac2_left' - `fr'
				
					}
		* Check the drop matrix adds up = 1 (100%) (with tolerance allowed)
			if `dfrac2_left' < -0.00001 | `dfrac_left' > 0.00001 {
				display as error  "Dropout probabilities must sum to 1: list sums to `=1-`dfrac2_left''"
				exit 198
				}	
			}

		
		tempname drops drops2
		mat `drops'=J(1,`sched_length',0)
		if "`drop2'"!="" mat `drops2'=J(1,`sched_length',0)	
		if "`dropouts'"!="" {
			forvalues dr=1/`sched_length' {
				local drpo: word `dr' of `dropouts'
				mat `drops'[1,`dr']=`drpo'
			}
		}
		if "`drop2'"!="" {
			forvalues dr2=1/`sched_length' {
				local drpo2: word `dr2' of `drop2'
				mat `drops2'[1,`dr2']=`drpo2'
			}
		}
	
		if "`dropouts'"=="" {
			mat `drops'[1,`sched_length']=1
		}
		if "`drop2'"!="" return mat dropouts2=`drops2'	
		 return mat dropouts=`drops'	
		
* STAGGERED RECRUITMENT  
					
	* Is there a strec list specified?
		local strec_yes = 0
		if "`strecruitment'"!="" local strec_yes = 1
		
	* Strec numlist must same length as  Schedule numlist
		* Length of strec list
			if `strec_yes'==1 {
				local strec_length = 0
				foreach i of numlist `strecruitment' {
					local strec_length = `strec_length' + 1
				}
				* Is this equal to schedule numlist+1?
				if `sched_length' != `strec_length' {
					dis as error   "Staggered recruitment - strecruitment() - list must correspond in length (`strec_length') with visit schedule (`sched_length')"
					exit 198
				}
			}
	* Decant strec numlist into locals and calculate people who attend all visits
		local rfrac_left = 1 // The proportion attending all visits - one unless strec specified
			if `strec_yes'==1 {
				local j = 1 // counter - position number
				foreach rfr of numlist `strecruitment' {
					local rfrac`j' = `rfr'
					local j = `j' + 1
					local rfrac_left = `rfrac_left' - `rfr'   
				}
		* Check the strec matrix adds up to less than 100%
			if `rfrac_left' < -0.00001 {
				display as error  "Staggered recruitment - strecruitment() - list of probabilities cannot exceed 1: list sums to `=1-`rfrac_left''"
				exit 198
			}

		}
		
		tempname strcs
		mat `strcs'=J(1,`sched_length',0)
       if "`strecruitment'"!="" {
			forvalues sr=1/`sched_length' {
				local strc: word `sr' of `strecruitment'
				mat `strcs'[1,`sr']=`strc'
			}
	   }
		if "`strecruitment'"=="" {
			mat `strcs'[1,`sched_length']=1
		}
		 return mat st_rec=`strcs'	
		
** Now calculate weights integrating dropout and staggered recruitment
	if "`strecruitment'"!="" &  "`dropouts'"!="" {

		local count: word count `strecruitment'

		local finalwgts
		forval i = 1/`count' {
			local weight_`i'
			local w_inv = 1
			local w1: word `i' of `strecruitment'
	
			forval j = 1/`i' {
				local w2: word `j' of `dropouts'

				if `i' == `j' {
					local weight_`j' = `weight_`j'' + `w1'*`w_inv'
				}
				else {
					local weight_`j' = `weight_`j'' + `w1'*`w2'
				}
				
				local w_inv = `w_inv' - `w2'		
			}
		}
		
		forvalues i=1/`count' {
			local  finalwgts "`finalwgts' `weight_`i''"
		} 
						
	}
	
** Same, if drop2 used

	if "`strecruitment'"!="" &  "`drop2'"!="" {

		local count: word count `strecruitment'

		local finalwgts2
		forval i = 1/`count' {
			local weight_`i'
			local w_inv = 1
			local w1: word `i' of `strecruitment'
	
			forval j = 1/`i' {
				local w2: word `j' of `drop2'

				if `i' == `j' {
					local weight_`j' = `weight_`j'' + `w1'*`w_inv'
				}
				else {
					local weight_`j' = `weight_`j'' + `w1'*`w2'
				}
				
				local w_inv = `w_inv' - `w2'		
			}
		}
		
		forvalues i=1/`count' {
			local  finalwgts2 "`finalwgts2' `weight_`i''"
		} 
						
	}	
					
** Choose which weights to use  - dropout only, strec only... or the integration of both version (above)
	
			local cohorts=0 // won't need separate cohorts i.e frames		
	if "`strecruitment'"!="" &  "`dropouts'"!="" {
			local	pwgts "`finalwgts'"
			local cohorts=1 // will need etc.
		}
	if "`strecruitment'"=="" &  "`dropouts'"!="" {				
			local	pwgts "`dropouts'"
			local cohorts=1
		}
	if "`strecruitment'"!="" &  "`dropouts'"=="" {
			local	pwgts "`strecruitment'"
			local cohorts=1
		}
	if "`strecruitment'"!="" &  "`drop2'"!="" {
			local	pwgts2 "`finalwgts2'"
		}
	if "`strecruitment'"=="" &  "`drop2'"!="" {				
			local	pwgts2 "`drop2'"
		}
		
			

		tempname prwt prwt2
		local fwlist2
		local fw2list2		
		local sumpwgts=0
		local sumpwgts2=0
		
		mat `prwt'=J(1,`sched_length',0)
		if `drop2_yes'==1 mat `prwt2'=J(1,`sched_length',0)
		if "`strecruitment'"=="" &  "`dropouts'"=="" {
			mat `prwt'[1,`sched_length']=1			
			forvalues i=1/`sched_length' { 
				local fw`i'=0
				if `i'==`sched_length' local fw`i'=1
				local fwlist2="`fwlist2' `fw`i''"
			}
			local pwgts "`fwlist2'"
			local sumpwgts=1
			local sumpwgts2=1
		}
		else {	
			forvalues i=1/`sched_length' {
				local fw`i': word `i' of `pwgts'
				local sumpwgts=`sumpwgts'+`fw`i''
				local sumpwgts_`i'=`sumpwgts'
				if `drop2_yes'==1 {
					local fwT`i': word `i' of `pwgts2'
					local sumpwgts2=`sumpwgts2'+`fwT`i''
					local sumpwgts2_`i'=`sumpwgts2'
				}
			}
			forvalues pw=1/`sched_length' {
				local pwt: word `pw' of `pwgts'	
				mat `prwt'[1,`pw']=`pwt'
				local fw`pw': word `pw' of `pwgts'
				local fw2`pw'=`fw`pw''*1/`sumpwgts'
				local fwlist2="`fwlist2' `fw2`pw''"
				if `drop2_yes'==1 {
					local pwt2: word `pw' of `pwgts2'
					mat `prwt2'[1,`pw']=`pwt2'
					local fwT`pw': word `pw' of `pwgts2'
					local fwT2`pw'=`fwT`pw''*1/`sumpwgts2'
					local fw2list2="`fw2list2' `fwT2`pw''"
				}

			}
		}
		
		if `drop2_yes'==0 local pwgts2 `pwgts' // will use for actual sigma rewighting, even though same as pwgts

		** `combined' weights - just to use to select non-zero cohorts
	
		local cwgts
		forvalues cw=1/`sched_length' {
			if  `drop2_yes'==1 local cwgt=(`fw`cw''+`fwT`cw'')/2
			else local cwgt=(`fw`cw'')
			local cwgts "`cwgts' `cwgt'"
		}
		

	
		** RETURN SOME STUFF incl. STREC and DROPOUTS, DROP" etc
		tempname crita scl dim
		
		if "`twosided'"!="" local tsided ts_yes
		else local tsided ts_no
		scalar `crita'=`alpha'
		scalar `scl'=`scale'
		scalar `dim'=`multi'
		return scalar alpha=`crita'
		return scalar scale=`scl'
		return scalar m_dim=`dim'	
		return local aratio `allratio'
		return local twosided `tsided'

		if "`actualtrt'"=="user2" return local acttrt_userfunc2 `atfunc_2'
		if "`actualtrt'"=="user" | "`actualtrt'"=="user2" return local acttrt_userfunc `atfunc_1'
		if "`actualcont'"=="user2" return local actcont_userfunc2 `acfunc_2'
		if "`actualcont'"=="user" | "`actualcont'"=="user2" return local actcont_userfunc `acfunc_1'
		return local trt_true `actualtrt'
		return local cont_true `actualcont'
		if "`trtspec'"=="user2" return local trt_userfunc2 `tfunc_2'
		if "`trtspec'"=="user" | "`trtspec'"=="user2" return local trt_userfunc `tfunc_1'
		if "`altcont'"=="user2" return local cont_userfunc2 `cfunc_2'
		if "`altcont'"=="user" | "`altcont'"=="user2" return local cont_userfunc `cfunc_1'

		return local trt_spec `trtspec' 
		if "`altcont'"!="" return local cont_spec `altcont'
		else return local cont_spec slint
		if `drop2_yes'==1 return mat cohort_wgts2=`prwt2'
		return mat cohort_wgts=`prwt'
		
		if `drop2_yes'==1 return local fw_rescale2 `"`fw2list2'"'
		return local fw_rescale `"`fwlist2'"'	
		if `drop2_yes'==1 return local final_wgts2 `"`pwgts2'"'
		return local final_wgts `"`pwgts'"'

* RETURNED MATRICES	
		*XMAT
		
	if "`xmat'"!="" & `cohorts'==0 {	
		if `xmat'!=`sched_length' {
				dis as error "with no dropout() or strec(), xmat() must contain a number equal to the schedule() length"
					exit 198
			}
	}
	if "`xmat'"!="" & `cohorts'==1 { 
			if `xmat'>`sched_length' {
				dis as error "xmat() must contain a number not larger than the schedule() length"
					exit 198
			}
			forvalues xm=1/`sched_length' {
				local pw`xm': word `xm' of `pwgts' 
				if `pw`xm''==0 & `xm'==`xmat' { 
					dis as error "xmat() must contain a number that represents a present cohort i.e. a non-zero probability in strec() or dropout() list"
					exit 198
							}
			}
	}	
			*RMAT
	if "`rmat'"!="" & `cohorts'==0 {	
		if `rmat'!=`sched_length' {
				dis as error "with no dropout() or strec(), rmat() must contain a number equal to the schedule() length"
					exit 198
			}
	}
	if "`rmat'"!="" & `cohorts'==1 { 
			if `rmat'>`sched_length' {
				dis as error "rmat() must contain a number not larger than the schedule() length"
					exit 198
			}
			forvalues rm=1/`sched_length' {
				local pw`rm': word `rm' of `pwgts' 
				if `pw`rm''==0 & `rm'==`rmat'  { 
					dis as error "rmat() must contain a number that represents a present cohort i.e. a non-zero probability in strec() or dropout() list"
					exit 198
							}
			}
	}
	
			*ZMAT
	if "`zmat'"!="" & "`marginal'"!=""	{
		dis as error "cannot request zmat() if model is marginal"
					exit 198
	}
	if "`zmat'"!="" & `cohorts'==0 {	
		if `zmat'!=`sched_length' {
				dis as error "with no dropout() or strec(), zmat() must contain a number equal to the schedule() length"
					exit 198
			}
	}
	if "`zmat'"!="" & `cohorts'==1 { 
			if `zmat'>`sched_length' {
				dis as error "zmat() must contain a number not larger than the schedule() length"
					exit 198
			}
			forvalues zm=1/`sched_length' {
				local pw`zm': word `zm' of `pwgts' 
				if `pw`zm''==0  & `zm'==`zmat' { 
					dis as error "zmat() must contain a number that represents a present cohort i.e. a non-zero probability in strec() or dropout() list"
					exit 198
							}
			}
	}
	
			*GMAT
	if "`gmat'"!="" & "`marginal'"!=""	{
		dis as error "cannot request gmat() if model is marginal"
					exit 198
	}		
	if "`gmat'"!="" & `cohorts'==0 {	
		if `gmat'!=`sched_length' {
				dis as error "with no dropout() or strec(), gmat() must contain a number equal to the schedule() length"
					exit 198
			}
	}
	if "`gmat'"!="" & `cohorts'==1 { 
			if `gmat'>`sched_length' {
				dis as error "gmat() must contain a number not larger than the schedule() length"
					exit 198
			}
			forvalues gm=1/`sched_length' {
				local pw`gm': word `gm' of `pwgts' 
				if `pw`gm''==0 & `gm'==`gmat'  { 
					dis as error "gmat() must contain a number that represents a present cohort i.e. a non-zero probability in strec() or dropout() list"
					exit 198
							}
			}
	}
	
				*BVARN
	
	if "`bvarn'"!="" & `cohorts'==0   {	
		if `bvarn'<`sched_length' {
				dis as error "with no dropout() or strec(), bvarn() must be the number equal to the schedule() length"
					exit 198
		}			
	}
	if "`bvarn'"!="" & `cohorts'==1 { 
			if `bvarn'>`sched_length' {
				dis as error "bvarn() must contain a number not larger than the schedule() length"
					exit 198
			}
			forvalues bv=1/`sched_length' {
				local pw`bv': word `bv' of `pwgts' 
				if `pw`bv''==0 & `bv'==`bvarn'  { 
					dis as error "bvarn() must contain a number that represents a present cohort i.e. a non-zero probability in strec() or dropout() list"
					exit 198
							}
			}
	}
	 

********************************************************************************
**# MULTIVARIATE MODEL CALCULATIONS
********************************************************************************

		local m=`multi'

** Check Covariance values
				
* Check user-inputted COVariance is a 2mx2m symmetric matrix assuming user/matrix input
	if "`covariance'"!=""  {
		tempname cov_mat
		mat `cov_mat'=`covariance'
		local col=colsof(`cov_mat')
		local sym= issymmetric(`cov_mat')
		if `sym' ==0 {
			dis as error "covariance() matrix must be symmetric"
		}
		
		if `col'!=2*`m' {
						dis as error "covariance() matrix must be symmetric 2mx2m, where m=number of outcome variables specified in 'multi'"
			exit 198
					}
		}
		
*Check user-inputted random effect variances >0 
					
	if "`covariance'"!="" { // version for if numbers entered directly as matrix
			
		foreach mu of numlist 1/`m'	{
				local k=`mu'*2-1
				local intvar`k'= el(`cov_mat', `k', `k')  
									if `intvar`k'' < 0 {
					dis as error "random intercept variances must be a positive number, unless intentially zero (random slope model only or standard multivariate regression if slope variance also =0)"
					exit 198
				}
		}	

		foreach mu of numlist 1/`m'	{
				local k=`mu'*2
				local slvar`k'= el(`cov_mat', `k', `k')  
								if `slvar`k'' <0 {
					dis as error "random slope variances must be a positive number, unless intentially zero (random intercept model only or standard linear regression if intercept variance also =0)"
				exit 198
			}
		}
		
	 	
		** homemade "isdiagonal"
		
		local offd=0
		local imposs=0
		forvalues j=1/`=2*`m'' {
			forvalues k=`j'/`=2*`m'' {	
				if `j'==`k' {
					local d`j'=`cov_mat'[`j',`k']
				}
				if `j'!=`k' {
					if `cov_mat'[`j',`k']!=0 local offd=`offd'+1
					if `d`j''==0 & `cov_mat'[`j',`k']!=0 local imposs=`imposs'+1
				}

			}
		}
		
		if `imposs'>0 {
			dis as error "covariance of at least one pair of random terms is non-zero when  variance of at least one of the pair of random terms is zero - not possible"
						exit 198
		}
	
		local d0ct=diag0cnt(`cov_mat')
		 
		
	}
		
*Check user-inputted COVariance(s) has/have implied correlations <=1 and >=-1
	 if "`covariance'"!=""  {
	 	tempname corr_mat diag1
			if `offd'>0 & `d0ct'==0 {
				mat `corr_mat'=corr(`cov_mat') // checking correlations only when there are off-diagonal elements AND all diagonal elements are non-zero
				forvalues j=1/`=2*`m'' {
					forvalues k=`=`j'+1'/`=2*`m''  {
							local corr= el(`corr_mat', `j', `k')
						if `corr' >1 {
							dis as error "correlation of at least one pair of random effects is greater than 1 - check values"
							exit 198
						}
						if `corr' <-1 {
							dis as error "correlation of at least one pair of random effects is less than -1 - check values"
							exit 198
						}
					}
				}
			}
		if `offd'==0 {
			mat `diag1'=J(`=2*`m'',1,1)	
			mat `corr_mat'=diag(`diag1')
		}	
	 }
	
 
		
** Rescale the variance terms that need rescaling (random intercept variance doesn't) - scale==1 if unspecified i.e no rescaling
		
* user-inputted version
	if "`covariance'"!="" {	
		foreach mu of numlist 1/`m'	{
			local k=`mu'*2-1
			local cov`k'`k'=`intvar`k'' // Variance of random intercepts - unchanged with rescaling
			}	

		foreach mu of numlist 1/`m'	{
			local k=`mu'*2
			if `slvar`k''==0 local cov`k'`k'=0 
			else local cov`k'`k'=(`scale'*(sqrt(`slvar`k'')))^2 // Variance of time (random slopes)  - rescaled if necessary 
			}
		
		forvalues j=1/`=2*`m'' {
			forvalues k=`=`j'+1'/`=2*`m''  {
				local corr`j'`k'=el(`corr_mat', `j', `k') // correlation of random effects 
				local corr`k'`j'=el(`corr_mat', `k', `j') // correlation of random effects
				if `cov`j'`j''!=0 &  `cov`k'`k''!=0 {
					local cov`j'`k'=`corr`j'`k''*sqrt(`cov`j'`j'')*sqrt(`cov`k'`k'')  // rescaled covariance, if necessary
					local cov`k'`j'=`corr`k'`j''*sqrt(`cov`k'`k'')*sqrt(`cov`j'`j'')  // rescaled covariance, if necessary
				}
				else {
					local cov`j'`k'=0
					local cov`k'`j'=0
				}
			}
		}
		local covmat
		forvalues j=1/`=2*`m'' {
			forvalues k=1/`=2*`m''  {
				local covmat "`covmat' `cov`j'`k''" // rescaled (if required) 2mx2m covariance matrix in numlist form
				}
			}	
		
	}
	
* 'auto' auto-version
	
	if "`auto'"!="" { // version for if using mixed model in memory
					//		dis "if you use option 'auto' with option 'model(multi)' it is the users responsibility to check the dimension of the outcome variable from the mixed model in memory matches dimension given in option 'multi', and otherwise may be the cause of a subsequent error"
		foreach mu of numlist 1/`m'	{
				local k=`mu'*2-1
				local cov`k'`k'=(exp(_b[lns1_1_`mu':_cons]))^2 // Variance of random intercepts - unchanged with rescaling
				}	

		foreach mu of numlist 1/`m'	{
				local k=`mu'*2
				capture local cov`k'`k'=(`scale'*(exp(_b[lns1_1_`=`mu'+`m'':_cons])))^2  // Variance of time (random slopes)  - rescaled if necessary
				if _rc!=0 {
					local cov`k'`k'=0
				}
			}	
		
		forvalues k=1/`=2*`m'-1' {  
			forvalues j=`=`k'+1'/`=2*`m''  {
				capture local p`j'`k'=tanh(_b[atr1_1_`k'_`j':_cons]) // correlation of random effects 
				capture local p`k'`j'=tanh(_b[atr1_1_`k'_`j':_cons])
				if _rc!=0 {
					local p`j'`k'=0
					local p`k'`j'=0
				}
			}	
		}		
		forvalues k=1/`=2*`m'-1' {
			forvalues j=`=`k'+1'/`=2*`m''  {
				local y=floor(`=`k'+1'/2)+`m'*((mod(`k',2)*-1)+1) // convert those return correlation e(b) numbering into required numbering
				local z=floor(`=`j'+1'/2)+`m'*((mod(`j',2)*-1)+1)
				local corr`j'`k'=`p`y'`z'' // get the correlations in the right order
				local corr`k'`j'=`p`z'`y'' 				
				local cov`j'`k'=`corr`j'`k''*sqrt(`cov`j'`j'')*sqrt(`cov`k'`k'')  // rescaled covariance, if necessary
				local cov`k'`j'=`corr`k'`j''*sqrt(`cov`k'`k'')*sqrt(`cov`j'`j'')  // rescaled covariance, if necessary
				}
			}
			
		local covmat
		forvalues j=1/`=2*`m'' {
			forvalues k=1/`=2*`m''  {
				local covmat "`covmat' `cov`j'`k''" // rescaled (if required) 2mx2m covariance matrix in numlist form
				}
			}
		
	}
	
	/* failed attempt to use isdiagonal in mata
		mata
			ecm=st_matrix("`errorvar'")
			id=isdiagonal(ecm)
			st_numscalar("isdiag", id)
		end mata
	*/
	
** Error variances check - No rescaling necessary (rescale only on timescale)
tempname err_mat errcorr_mat


* user-inputted version	
	if "`errorvar'"!="" { // version for if numbers entered directly

		
		capture mat `err_mat'=  `errorvar' // first checking matrix supplied in correct format
			if  _rc!=0 {
					dis as error "matrix entry for errorvar() with model(multi) not correct format"
				exit 198
						}
			capture confirm matrix `err_mat'  // first checking matrix supplied in correct format
			if  _rc!=0 {
					dis as error "matrix entry for errorvar() with model(multi) not correct format"
				exit 198
				}		
		local col=colsof(`err_mat')
		local sym= issymmetric(`err_mat')
		if `sym' ==0 | `col'!=`m' {
					dis as error "errorvar() matrix must be symmetric 2mx2m, where m=number of outcome variables"
			exit 198
					}	
		forvalues k=1/`m' {		
		local err`k'`k'= el(`err_mat', `k', `k')  
			if `err`k'`k'' < 0 {
					dis as error "error variances must be a positive number"	
			}
		}		
		
		mat `errcorr_mat'=corr(`err_mat')	
		local errmat
		forvalues j=1/`m' {
			forvalues k=1/`m'  {
				local err`j'`k'= el(`errcorr_mat', `j', `k')
				if `err`j'`k'' >1 {
					dis as error "correlation of at least one pair of error terms is greater than 1 - check values"
						exit 198
				}
				if `err`j'`k'' <-1 {
					dis as error "correlation of at least one pair of error terms is less than -1 - check values"
						exit 198
					}
				local err`j'`k'= el(`err_mat', `j', `k')	
				local errmat "`errmat' `err`j'`k''" 
				}
			}		
	}					

	* 'auto' auto-version	
	if "`auto'"!="" { // version for if using mixed model in memory
		forvalues k=1/`m'	{
			if `k'==1 {
				local err`k'`k'=(exp(_b[ lnsig_e:_cons]))^2 
			}
			else {
				capture local err`k'`k'=(exp(_b[r_lns1_`k'ose:_cons]+_b[ lnsig_e:_cons]))^2 
				if _rc!=0 local err`k'`k'=(exp(_b[r_lns`k'ose:_cons]+_b[ lnsig_e:_cons]))^2
			}
				}
		forvalues k=1/`=`m'-1' {
			forvalues j=`=`k'+1'/`m'  {
				capture local ecorr`j'`k'=tanh(_b[r_atr1_`k'_`j':_cons]) 
				if _rc!=0 local ecorr`j'`k'=0
			}	
		}	
				forvalues k=1/`=`m'-1' {
			forvalues j=`=`k'+1'/`m'  {
				local err`j'`k'=`ecorr`j'`k''*sqrt(`err`j'`j'')*sqrt(`err`k'`k'') 
				local err`k'`j'=`err`j'`k''
			}	
		}
			local errmat
		forvalues j=1/`m' {
			forvalues k=1/`m'  {
				local errmat "`errmat' `err`j'`k''" // rescaled (if required) 2mx2m covariance matrix in numlist form
				}
			}	
	}
				
					
** Rescale contslope - changes with scale, so an x% effect means something different (i.e rescale TTE)

	if "`contslope'"!="" {	
		local mcontsc
		local ttelist
		forvalues i=1/`m' { 
			local mn`i': word `i' of `contslope'
			local mefx`i': word `i' of `effectiveness'
			local mns_sc`i'=`mn`i''*`scale'
			local tte`i' =  -(`mns_sc`i'')*`mefx`i''
			local mcontsc "`mcontsc' `mns_sc`i''"
			local ttelist "`ttelist' `tte`i''"
		}
	}	

	

** Rescale Slope Difference parameters - only matters if trtspec=slope because it's an interaction parameter
	if "`difference'"!="" & "`trtspec'"=="slope" {
		local mdiffsc
		local ttelist
		forvalues i=1/`m' { 
			local md`i': word `i' of `difference'
			local mds_sc`i'=`md`i''*`scale'
			local tte`i' =  `mds_sc`i''
			local mdiffsc "`mdiffsc' `mds_sc`i'"
			local ttelist "`ttelist' `tte`i''"
		}
	}
	
	* if trtspec=intercept
	if "`difference'"!="" & "`trtspec'"=="intercept" {
		local mdiffsc
		local ttelist
		forvalues i=1/`m' { 
			local md`i': word `i' of `difference'
			local mds_sc`i'=`md`i'' // no scaling necessary
			local tte`i' =  `mds_sc`i''
			local mdiffsc "`mdiffsc' `mds_sc`i'"
			local ttelist "`ttelist' `tte`i''"
		}
	} 
	
	
	/* let's ignore for now
	* if trtspec=factor
	if "`difference'"!="" & "`trtspec'"=="factor" {
		// needs filling
		}
*/				

	* Check Weighting 
	
	if "`weighting'"!="" {
		if inlist("`weighting'","ivw","nivw","icw","nicw" )==0 {
			local wgt_length = 0
				foreach w in `weighting' {
					capture confirm number `w'
						if _rc!=0 {
						dis as error "Each part of weighting() must be a number, unless "ivw","nivw","icw" or "nicw" specified"
						exit 198
					}
		
					local wgt_length = `wgt_length' + 1			
				}
				if `wgt_length'!=`multi' {

						dis as error "number of elements of weighting() must be the same as number of dimensions (m) entered in option multi(), unless "ivw","nivw","icw" or "nicw" specified"
						exit 198
					}
		}
	}

	if "`weighting'"=="" {

		local weighting
		forvalues wm=1/`multi' {
			local w`wm'=1
			local weighting "`w`wm'' `weighting'"
		}
	}

	**** HEADER
	
	if "`noheader'"=="" {
		
		di _n "{it:mvmixedpower}" as text " - power and sample size calculator for multivariate linear mixed models (v1.0): author M.Burnell"
		di as text "MRC Centre of Research Excellence in Clinical Trial Innovation, UCL, London WC1V 6LJ, UK" _n		
	}
	
	
********** MODEL SYNTAX OUTPUT SECTION *****************************************
	if "`nosyntax'"=="" {	 
		* ctype 
		di  "{hline}"
		local subscale
		local ctime
		forvalues mu=1/`m' {
			local subscale "`subscale' {it:subscale_`mu'}"	
			 if "`altcont'"=="factor" local ct1`mu' i.
			 if "`altcont'"=="noint" | "`altcont'"=="slint" local ct1`mu' c.
			if "`altcont'"=="factor" | "`altcont'"=="noint" | "`altcont'"=="slint" {
				local ct2`mu' time_`mu'
			}
			local ctime "`ctime' `ct1`mu''{it:`ct2`mu''} "
		}
		
		local constraint
		local ttime
		local rint
		local rslope
		local conlist
		* ttype 
		forvalues mu=1/`m' {
			 if "`trtspec'"=="factor" | "`trtspec'"=="factor0" {
				local tt1`mu' i.
				local tt2`mu' time_`mu'
				local tt3`mu' #1.
				local tt4`mu' trt		
			 } 
			 if "`trtspec'"=="slope" | "`trtspec'"=="slint" | "`trtspec'"=="lateslope"  {
				local tt1`mu' c.
				local tt2`mu' time_`mu'
				local tt3`mu' #1.
				local tt4`mu' trt
			 }
			 * tint
			 if "`trtspec'"=="slint" | "`trtspec'"=="intercept" local tint`mu' i.{it:trt_`mu'}
			 * ls
			 if "`trtspec'"=="lateslope"  local ls _1
			 * nocons
			  local nocons , nocons
			 * factortr
			 if "`trtspec'"=="factor" & "`altcont'"=="noint" {
				local conlist "`conlist' `mu'"
				local   contraints constraints(`conlist')
				local constraint "`constraint' constraint `mu' _b[1.{it:time_`mu'}#1.{it:trt}]=0"
			 } 
			
			local ttime "`ttime' `tt1`mu''{it:`tt2`mu''}{it:`ls'}`tt3`mu''{it:`tt4`mu''} `tint`mu''"
			
				 * retime
			local rint "`rint' {it:subscale_`mu'}" 
			local rslope "`rslope' {it:time_`mu'}"
			if "`auto'"=="" {
				if `offd'==0   local covtype cov(ind)
				else local covtype cov(unstr)
			}

		}
		
		local occ {it:visit}
		
		di as text  "Mixed model syntax:"
		if "`trtspec'"=="factor" {
			di as result "`constraint'"
		}
		di  as result "mixed{it: depvar} `subscale' `ctime' `ttime' `nocons' `constraints'|| {it:id_level2}:`rint' `rslope', `covtype' nocons || `occ': , nocons residuals(unstr, t({it:subscale})) "	
	}
	
************************** MATRIX SECTIONS *************************************


	if "`strecruitment'"=="" & "`dropouts'"=="" { 
		local mframes=1  // either going to make just one frame - no pwgt cohorts
	}
	else {
		local mframes=`sched_length'  // ... or multiple frames (not necessarily sched_length amount, if any pwgts==0)
	}

	
* create new frame(s) with matrix contents and calculate variance of treatment effects 

	local cframe=c(frame)
	
	local frlist // for creating numlist of frames to include when cohort==1 in following loop
	
	foreach n of numlist 1/`mframes' { // create a frame for each schedule cohort if necessary. Not going to use tempnames if frames(keep), otherwise frames will be dropped by program 
		
		local pwgts_`n': word `n' of `cwgts' // not needed anymore?...
		local pwgt0_`n': word `n' of `pwgts'
		local pwgt1_`n': word `n' of `pwgts2'
		if `cohorts'==0 {
			local pwgts_1=1 // not needed anymore?...
			local pwgt0_`n'=1
			local pwgt1_`n'=1
		}	

		
		
		if `pwgts_`n''>0  { 
			if `cohorts'==1 & `n'>0  { 
				local frlist "`frlist' `n'"
			}
**# multivariate - X matrix and identifier variables plus intitial frame(s) set up		
		 	if "`frames'"=="keep"	{
				tempname _mp_`model'_`trtspec'_coh`cohorts'_`n'
				frame create `_mp_`model'_`trtspec'_coh`cohorts'_`n''
				frame change `_mp_`model'_`trtspec'_coh`cohorts'_`n''
				notes: mixedpower dataframe
				notes: model type: `model' 
				notes: treatment specification: `trtspec'
				notes: cohort (0=represents full sample; 1=represents partial sample) : `cohorts'
				if `cohorts'==1 {
					notes: cohort schedule: up to visit `n' 
				}
				if `cohorts'==0 {
					notes: cohort schedule: up to visit `sched_length' only
				}
				notes: probability weight of cohort: `pwgts_`n''
			}
			if "`frames'"=="drop" & "`fr_created'"!="yes" {
				tempname _mp_`model'_`trtspec'
				frame create `_mp_`model'_`trtspec''
				frame change `_mp_`model'_`trtspec''
				local fr_created yes
			}
			
			
		qui {			
			local k=`n' // number of visits from schedule to use for this (nth) frame	
			if `cohorts'==0 {
				local k=`sched_length' // no dropout/strec then will use all visits
			}
			local trwt1: word 1 of `allratio'
			local trwt2: word 2 of `allratio'
			local obsn=`sched_length'*(`trwt1'+`trwt2')*`m' // max obs is number of cohorts*number of visits*number of dims. Number could be higher for G matrix?
			
			set obs `=`obsn'+100'
		
			gen trt_cohort=.
			gen obs=.
			gen double time=.
			gen m=.
			gen treat=.
			if "`altcont'"=="factor" {
				local contvar=`sched_length'
			}
			if "`altcont'"=="noint" {
				local contvar=1
			}
			if "`altcont'"=="noslope" {
				local contvar=1
			}
			if "`altcont'"=="slint" {
				local contvar=2
			}
				
			if "`trtspec'"=="factor0" {
			local altvar=`sched_length' 
			}
			if "`trtspec'"=="factor" {
			local altvar=`sched_length'-1
			}
			if "`trtspec'"=="slope" {
			local altvar=1
			}
			if "`trtspec'"=="intercept" {
			local altvar=1
			}
			if "`trtspec'"=="slint" {
			local altvar=2
			}
			if "`trtspec'"=="lateslope" {
			local altvar=1
			}
			local vl=`contvar'+`altvar'

			local vlim=(`contvar'+`altvar')*`m' // 3 X variables needed for 'slope' and 'intercept'
				forvalues v=1/`vlim' {
					gen double X`v'=0
				}
		}		
			local in=0 // local counter for inputting matrix values in appropriate row
			local trt_coh=0	// dataset marker identifying unique trt#cohorts based on ARAtio arguments
			local trt=-1 // identify trt and control groups (will be 0/1 values when inputted)
			
			local arat=0 // for picking which ARatio weight to use


			forvalues g=0/1 {  // loop over treatment
				local trt=`trt'+1
				local arat=`arat'+1
				local trwt: word `arat' of `allratio'
				forvalues ab=1/`trwt' { // loop over trt#cohort weights
					local trt_coh=`trt_coh'+1
					forvalues j=1/`k'	{ // loop over visits upto `n'
						local t : word `j' of `schedule'
						local in=`in'+1
						  forvalues mx=1/`m' {			  	 
							local in`mx'=`mx'+(`in'-1)*`m'
								forvalues xl=1/`vl' {
									local xlab`xl'=`xl'+(`mx'-1)*`vl'
								}
							
						if "`altcont'"=="factor" {
							qui replace X`xlab`j''=1 in `in`mx''
						}
						if "`altcont'"=="noint" {
							qui replace X`xlab1'=`t' in `in`mx''
						}
						if "`altcont'"=="noslope" {
							qui replace X`xlab1'=1 in `in`mx''
						}
						if "`altcont'"=="slint" {
							qui replace X`xlab1'=1 in `in`mx''
							qui replace X`xlab2'=`t' in `in`mx''
						}	
						
						if "`trtspec'"=="factor0" {
							local x=`contvar'+`j'
								*local xin=(`trt_coh'-1)*`k'+ `j' 
							qui replace X`xlab`x''=1*`g' in `in`mx'' 
						}
						if "`trtspec'"=="factor" {
							local x=`contvar'+`j'-1
								*local xin=(`trt_coh'-1)*`k'+ `j'
							if `j'>1 {
							qui replace X`xlab`x''=1*`g' in `in`mx''
							}
						}
						if "`trtspec'"=="slope" {
							local x=`contvar'+1
							qui replace X`xlab`x''=`t'*`g' in `in`mx''
						}
						if "`trtspec'"=="intercept" {
							local x=`contvar'+1
							qui replace X`xlab`x''=1*`g' in `in`mx''
						}
						if "`trtspec'"=="slint" {
							local x=`contvar'+1
							local xx=`contvar'+2
							qui replace X`xlab`x''=`t'*`g' in `in`mx''
							qui replace X`xlab`xx''=1*`g' in `in`mx'' // note: trt intercept is the 4th X variable!
						}
						if "`trtspec'"=="lateslope" {
							local x=`contvar'+1
							qui replace X`xlab`x''=cond((`t'-`lslt')>0,(`t'-`lslt'),0)*`g' in `in`mx''
						}

						qui replace trt_cohort=`trt_coh' in `in`mx''
						qui replace obs=`j' in `in`mx''
						qui replace time=`t' in `in`mx''
						qui replace treat=`trt' in `in`mx''
						qui replace m=`mx'  in `in`mx''
						local inmax=`in`mx''
							}
							
						}
					}

				
			}	

			local inl=`inmax'+1
			foreach var of varlist trt_cohort obs treat  X1-X`vlim'   {
					qui replace `var'=. in `inl'/l
				}
				
							
			qui tostring treat, gen(trt_str)
			qui tostring trt_cohort, gen(ar_str)
			qui tostring obs, gen(vis_str)
			qui tostring m, gen(m_str)
			qui gen str15 rownames="t"+trt_str+"_"+"v"+vis_str+"_m"+m_str
			qui replace rownames="" if treat==.
			qui replace trt_str="" if treat==.
			qui replace ar_str="" if treat==.
			qui replace vis_str="" if treat==.
			qui replace m_str="" if treat==.
			
			tempname X	Xm
			mkmat X1-X`vlim', matrix(`X') nomissing	rownames(rownames)
			
			if "`xmat'"!="" {
				if `xmat'==`n' & `cohorts'==1 {
					mat `Xm'=`X'
					return matrix xmat=`Xm'
				}
				if `cohorts'==0 {
					mat `Xm'=`X'
					return matrix xmat=`Xm'
				}	
			}
			
			
		**# multivariate R matrix
			local arat=0
			local in=0
			forvalues g=0/1 { // loop over treatment
				local arat=`arat'+1
				local trwt: word `arat' of `allratio'
				forvalues ab=1/`trwt' { // loop over treatment#cohort weights
					forvalues j=1/`k'	{	// loop over visits upto `n'	
						local in=`in'+1
						forvalues mr=1/`m' { // loop over dims of m
						
						local in`mr'=`mr'+(`in'-1)*`m'	
						qui gen double R`in`mr''=0
						local inmax=`in`mr''
						local rmax=`in`mr''
						}
					local cell=0
						forvalues r=1/`m' {
							forvalues c=1/`m' {
								local cell=`cell'+1
								local value: word `cell' of `errmat'
								local in`r'`c'=(`in1')+(`r'-1)
								local Rc=`in1'+(`c'-1)
								qui replace R`Rc'=`value' in `in`r'`c''
							}
						}
						
					}
				}
			}
			
			local inl=`inmax'+1
			foreach var of varlist R1-R`rmax' {
				qui replace `var'=. in `inl'/l
			}
			
			tempname R Rm
			mkmat R1-R`rmax', matrix(`R') nomissing	rownames(rownames)
			
			if "`rmat'"!="" {
				if `rmat'==`n' & `cohorts'==1 {
					mat `Rm'=`R'
					return matrix rmat=`Rm'
				}
				if `cohorts'==0 {
					mat `Rm'=`R'
					return matrix rmat=`Rm'
				}	
			}
			
			
		**# multivariate Z matrix

			local in=0
			local nct=0
			local arat=0

			forvalues g=0/1 {
				
				local arat=`arat'+1
				local trwt: word `arat' of `allratio'
				forvalues ab=1/`trwt' { // loop over treatment#cohort weights
					local nct=`nct'+1
						
					forvalues mz=1/`m'{  // for each 'person'/ID (nct) create Z numbering
							local z1=(`nct'-1)*2*`m'+1+(`mz'-1)*2
							local z2=(`nct'-1)*2*`m'+2+(`mz'-1)*2
								//	start n for ID + intercept/slope Z + start of m dim within	ID
							gen double Z`z1'=0 // the m pairs of Z.. variables per 'person'
							gen double Z`z2'=0

								}
					forvalues j=1/`k'{  // loop over visits upto `n'
						local t : word `j' of `schedule'

						local in=`in'+1
							forvalues mz=1/`m'{		
								local in`mz'=`mz'+(`in'-1)*`m' // for correct row number
								local z1=(`nct'-1)*2*`m'+1+(`mz'-1)*2
								local z2=(`nct'-1)*2*`m'+2+(`mz'-1)*2
								qui replace Z`z1'=1 in `in`mz''
								qui replace Z`z2'=`t' in `in`mz''
								local inmax=`in`mz''
								local zmax=`z2'
										}
									}

				}
			}
				
			local inl=`inmax'+1
			foreach var of varlist Z1-Z`zmax' {
				qui replace `var'=. in `inl'/l
			}
			tempname Z Zm
			mkmat Z1-Z`zmax', matrix(`Z') nomissing	rownames(rownames)
			
			if "`zmat'"!="" {
				if `zmat'==`n' & `cohorts'==1 {
					mat `Zm'=`Z'
					return matrix zmat=`Zm'
				}
				if `cohorts'==0 {
					mat `Zm'=`Z'
					return matrix zmat=`Zm'
				}	
			}

		**# multivariate G matrix
			
			local arat=0
			local in=0
			forvalues g=0/1 {
			
				local arat=`arat'+1
				local trwt: word `arat' of `allratio'
				forvalues ab=1/`trwt' {
																
				local in=`in'+1
				
				forvalues mg=1/`m'{
					local g1`mg'=1+(`mg'-1)*2+(`in'-1)*2*`m'
					local g2`mg'=2+(`mg'-1)*2+(`in'-1)*2*`m'
					
					qui gen double G`g1`mg''=0
					qui gen double G`g2`mg''=0
					local gmax=`g2`mg''
				}
						
						
				local cell=0
				local rmax=2*`m'
				local cmax=2*`m'
				local mg=1
					forvalues r=1/`rmax' {
						forvalues c=1/`cmax' {
							local cell=`cell'+1
							local value: word `cell' of `covmat'
							local in`r'`c'=(`g1`mg'')+(`r'-1)
							local gc=`g1`mg''+(`c'-1)
							qui replace G`gc'=`value' in `in`r'`c''
							local inmax=`in`r'`c''
						}
					}
				}
			}


			local inl=`inmax'+1
			foreach var of varlist G1-G`gmax' {
				qui replace `var'=. in `inl'/l
			}
			tempname G Gm
			
			mkmat G1-G`gmax', matrix(`G') nomissing		
		
					if "`gmat'"!="" {
				if `gmat'==`n' & `cohorts'==1 {
					mat `Gm'=`G'
					return matrix gmat=`Gm'
				}
				if `cohorts'==0 {
					mat `Gm'=`G'
					return matrix gmat=`Gm'
				}	
			}
			
	***** MATRIX CALCULATIONS		
			
			tempname sigma sigma0 B_var invsigma  sigmaC sigmaT
			mat `sigma'=`R'+`Z'*`G'*`Z''
			mat `sigma0'=`sigma'			
			
			*** ARATIO section ***
			if "`alloratio'"=="" {
				
				if `pwgt0_`n''>0 mat `sigmaC'=(1/`ar1')*(1/`pwgt0_`n'')*`sigma'[1..rowsof(`sigma'),1..`=`k'*`m'']
				if `pwgt0_`n''==0 mat `sigmaC'=(1/`ar1')*(0)*`sigma'[1..rowsof(`sigma'),1..`=`k'*`m'']
				if `pwgt1_`n''>0 mat `sigmaT'=(1/`ar2')*(1/`pwgt0_`n'')*`sigma'[1..rowsof(`sigma'),`=1+`k'*`m''..`=`k'*`m'*2']
				if `pwgt1_`n''==0 mat `sigmaT'=(1/`ar2')*(0)*`sigma'[1..rowsof(`sigma'),`=1+`k'*`m''..`=`k'*`m'*2']

				mat coljoin `sigma'=`sigmaC' `sigmaT'
				*mat li `sigma'
			}
			
			
			mat `B_var'=invsym(`X''*invsym(`sigma')*`X')
			
			
			if `cohorts'==1 {
					tempname B_var`n' sigma`n'
					mat `B_var`n''=`B_var'
					mat `sigma`n''=`sigma0'
			}

			tempname bvarin sigmain corrin
			if "`bvarn'"!=""  {
					if `cohorts'==1 & `bvarn'==`n' {
						mat `sigmain'=`sigma`n''
						mat `corrin'=corr(`sigma`n'')
						mat `bvarin'=`B_var`n''
						return matrix bvar_n=`bvarin'
						return matrix sigma_n=`sigmain'
						return matrix wcorr_n=`corrin'
					}
					if `cohorts'==0 & `bvarn'==`sched_length' {
						mat `corrin'=corr(`sigma0')
						mat `sigmain'=`sigma0'
						mat `bvarin'=`B_var'
						return matrix bvar_n=`bvarin'
						return matrix sigma_n=`sigmain'
						return matrix wcorr_n=`corrin'
					}									
				}
			
			tempname nmcount
			qui egen `nmcount' = rownonmiss(_all), strok
			qui drop if `nmcount' == 0
			qui drop `nmcount'
			 			
		
			if "`frames'"=="drop"  {
					drop _all
				}
			if "`frames'"=="keep"  {
				frame rename `_mp_`model'_`trtspec'_coh`cohorts'_`n'' _mp_`model'_`trtspec'_coh`cohorts'_`n'
				}
		}
		else // for the schedule points who don't have associated unique cohorts i.e pwgt=0
		
		
	}	

	
			***** Perform  back-calculation of X-covariance if needed *****
	if `cohorts'==1 {
		tempname B_var  // the overall back-calculated X-covariance matrix
		tempname wgtsum
		mat `wgtsum'=J(`vlim',`vlim',0) 
		foreach n of numlist `frlist' {
		
			mat `wgtsum'=`wgtsum'+invsym(`B_var`n'')
			*mat `wgtsum'=`wgtsum'+`pwgts_`n''*invsym(`B_var`n'')


		}
		mat `B_var'=invsym(`wgtsum')

	}	
		
	tempname bvar tteM betas wts wtsSTD vwts mwgts icweights   bvartrt  ones wgtstd
	mat `bvar'=`B_var'	
	return mat beta_var=`bvar'
	mat `tteM'=J(1,`m',0)
	mat `wts'=J(1,`m',0)
	mat `wtsSTD'=J(1,`m',0)
	mat `bvartrt'=J(`m',`m',0)
	mat `ones'=J(1,`m',1)
	local tv=`contvar'+`altvar'

	forvalues mu=1/`m' {
				local tte`mu': word `mu' of `ttelist'
				mat `tteM'[1,`mu']=`tte`mu''
	}
			
	forvalues mu=1/`m' { 
		forvalues nu=1/`m' {						
			mat `bvartrt'[`mu',`nu'] =`B_var'[`=`mu'*(`tv')',`=`nu'*(`tv')'] // just the slopes/intercepts cov matrix
		}
	}	
	mat `wgtstd'=invsym(`ones'*invsym(`bvartrt')*`ones'') //standardise ICW weights
	mat `icweights'=`wgtstd'[1,1]*invsym(`bvartrt')
				
	
		
		*** create combined effect size over each dim of m
			
			if "`weighting'"=="ivw" {
				forvalues mu=1/`m' {
					local wgt`mu'=1/`B_var'[`=`mu'*(`tv')',`=`mu'*(`tv')']
				}
			}
			else if "`weighting'"=="nivw" {
				forvalues mu=1/`m' {					
					local sign`mu'=sign(`tte`mu'')
					local wgt`mu'=`sign`mu''*1/`B_var'[`=`mu'*(`tv')',`=`mu'*(`tv')']
				}
			}
			else if "`weighting'"=="icw" {

				mat `wts'=`icweights'

			}
			else if "`weighting'"=="nicw" {
					forvalues mu=1/`m' { 
						forvalues nu=1/`m' {		
							if `mu'!=`nu' local sign`munu'=sign(`tte`mu'')*sign(`tte`nu'')
							if `mu'==`nu' local sign`munu'=sign(`tte`mu'')
							mat `icweights'[`mu',`nu'] =`sign`munu''*`icweights'[`mu',`nu'] 
						}
					}	
				mat `wts'=`icweights'
			}
			else if "`weighting'"!="" {
				forvalues mu=1/`m' {
					local wgt`mu': word `mu' of `weighting'
				}	
			}
			if "`weighting'"=="icw" | "`weighting'"=="nicw" {
				tempname wgttte icvartte
				mat `wgttte'=`ones'*`icweights'*`tteM''  // 1*invsigma*Yi, 
				mat `icvartte'=`ones'*`icweights''*`bvartrt'*`icweights''*`ones''
				local wtte=`wgttte'[1,1]
				local vartte=`icvartte'[1,1]
				*di "`wtte' `vartte'"
			}
			else {
				forvalues mu=1/`m' {
					mat `wts'[1,`mu']=`wgt`mu''
					mat `wtsSTD'[1,`mu']=abs(`wgt`mu'')
				}
				mat `wts'=invsym(`wtsSTD'*`ones'')*`wts' //standardised
				tempname wgttte var_tte
				mat `wgttte'=`wts'*`tteM''
				mat `var_tte'=`wts'*`bvartrt'*`wts''
				local wtte=`wgttte'[1,1]
				local vartte=`var_tte'[1,1]

			}
		
			
	
			local effsize=`wtte'/sqrt(`vartte')
			mat `betas'=`tteM'
			return mat trtbeta_true=`betas'
			mat `mwgts'=`wts'
			return mat m_weights=`mwgts'
	
*******************************************************************	
	
	* CALCULATE THE MAIN RESULT: Either sample size or power
	qui tempname  sampfactor alpha_tail sampsize sampsize_C sampsize_T power z_power frac_ss frac_power 
	if "`power_or_n'"=="power" { // Calc SAMPLE SIZE
		scalar `alpha_tail' = 1 - (0.5 * `alpha')
		scalar `sampfactor' = ( invnormal(`alpha_tail') + invnormal(`given_power'))^2
		scalar `sampsize' = 2*ceil( ( `sampfactor' / (`effsize')^2) )*(`arsum'/2)
		scalar `frac_ss' = 2*(`sampfactor' / (`effsize')^2)*(`arsum'/2)
		/*if  "`aratio'"!="" {
			scalar `sampsize' = `arsum'*ceil( (`arfactor'*2)*(`sampfactor' / ((`effsize')^2)/`arsum')) 
			scalar `frac_ss' = 2*( (`arfactor')*(`sampfactor' / (`effsize')^2)) 
		}*/
		scalar `sampsize_C' =  `sampsize'*(`ar1'/`arsum')
		scalar `sampsize_T' =  `sampsize'*(`ar2'/`arsum')
		scalar `power' = normal(( abs(`effsize')*sqrt(`sampsize'/`arsum') ) - invnormal(1-`alpha'/2)) 
		scalar `frac_power' = `given_power' // Transferring the local into the scalar...
	}
	else { // Calc POWER
		// Calc the power here
		scalar `sampsize' = `actual_n' // As specified by the user; transferring to output scalar
		scalar `frac_ss' = `given_n'
		scalar `sampsize_C' = `actual_n'*(`ar1'/`arsum')
		scalar `sampsize_T' = `actual_n'*(`ar2'/`arsum')
		scalar `z_power' = ( abs(`effsize')*sqrt(`actual_n'/`arsum') ) - invnormal(1-`alpha'/2) // 
		scalar `frac_power' = normal(( abs(`effsize')*sqrt(`given_n'/`arsum') ) - invnormal(1-`alpha'/2))
		/*if  "`aratio'"!="" {
			scalar `z_power' = ( abs(`effsize')*sqrt(`actual_n'/(`arfactor'*2)) ) - invnormal(1-`alpha'/2)
			scalar `frac_power' = normal((abs(`effsize')*sqrt(`given_n'/(`arfactor'*2)) ) - invnormal(1-`alpha'/2))
		}*/
		scalar `power' = normal(`z_power')
	} // 
	
	
	
	if strmatch("`test'","joint(*)")==1 | "`twosided'"!="" {
		if "`twosided'"!="" {
			tempname W_jt
			mat `W_jt'=J(1,1,0)
			local df_jt=1
			local w11=`effsize'*`effsize'
			mat `W_jt'[1,1]=`w11'
			local star *
		}	
		local alpha_jt= invchi2tail(`df_jt', `alpha')
		if "`power_or_n'"=="power" {
			scalar `sampsize'=`arsum'*ceil(npnchi2(`df_jt',`alpha_jt',`=1-`given_power'')/`W_jt'[1,1]-.000001) // might need a bit of tolerance adjustment!
			scalar `frac_ss' = `arsum'*(npnchi2(`df_jt',`alpha_jt',`=1-`given_power'')/`W_jt'[1,1]-.000001) 
			scalar `sampsize_C' =  ceil(`sampsize'*(`ar1'/`arsum'))
			scalar `sampsize_T' =  ceil(`sampsize'*(`ar2'/`arsum'))
			scalar `power' = 1-nchi2(`df_jt',`W_jt'[1,1]*`sampsize'/`arsum',`alpha_jt')
			scalar `frac_power' = `given_power'
		}
		else {
			scalar `power'=1-nchi2(`df_jt',`W_jt'[1,1]*`actual_n'/`arsum',`alpha_jt')
			scalar `frac_power'=1-nchi2(`df_jt',`W_jt'[1,1]*`given_n'/`arsum',`alpha_jt')
			scalar `sampsize' = `actual_n'
			scalar `frac_ss' = `given_n'
			scalar `sampsize_C' = `actual_n'*(`ar1'/`arsum')
			scalar `sampsize_T' = `actual_n'*(`ar2'/`arsum')
		}			
	}
	
***** DISPLAY OUTPUT SECTION ****************
		
			local schedrd
			forvalues t=1/`sched_length' {
				local schrd_`t': word `t' of `schedule'
				if mod(`schrd_`t'',0.1)!=0 local schrd_`t': di %3.2f `schrd_`t''
				else if mod(`schrd_`t'',1)!=0 local schrd_`t': di %2.1f `schrd_`t''
				local schedrd "`schedrd' `schrd_`t''"
			} 
			
			local diffrd
			local wgtrd
			forvalues d=1/`m' { // needs to be changed when/if adding more treamtent effect parameterisations
				local diffrd_`d': word `d' of `ttelist'
				if mod(`diffrd_`d'',1)!=0 local diffrd_`d': di %3.2f `diffrd_`d''
				if "`weighting'"=="icw" | "`weighting'"=="nicw" {
				}
				else {
					if mod(`wgt`d'',1)!=0 local wgt`d': di %3.2f `wgt`d''
				} 
				if `d'!=`m' local sc ";"
				else local sc
				local diffrd "`diffrd' `diffrd_`d''`sc'"
				local wgtrd "`wgtrd' `wgt`d''"
			}
			
			if "`actualtrt'"!="" local attext " {it:but with actual} {hi:`actualtrt'} {it:treatment effect}"
			local offset 25
			di  "{hline}"
			if "`power_or_n'"=="n" local calc_PorN power
			if "`power_or_n'"=="power" local calc_PorN sample size
			di _n as text "Calculating {hi:`calc_PorN'} for a {hi:multivariate} model with {hi:`trtspec'} treatment effect parameterisation`attext':"
			di _s(2) as text "visit schedule" _col(`=`offset'-2') "="  _col(`=`offset'-1') as res "`schedrd'"
			di _s(2) as text "n joint outcomes" _col(`=`offset'-2') "="  _col(`offset') as res `multi'
			di _s(2) as text "treatment effect(s)" _col(`=`offset'-2') "="  _col(`=`offset'-1') as res "`diffrd'"
			di _s(2) as text "outcome weighting" _col(`=`offset'-2') "="  _col(`=`offset'-1') as res " `weighting'"
			di _s(2) as text "alpha`star'" _col(`=`offset'-2') "="  _col(`offset') as res %4.3f `alpha'
			di _s(2) as text "total sample size"  _col(`=`offset'-2') "="  _col(`offset') as res `sampsize'
			di _s(2) as text "n in control arm"  _col(`=`offset'-2') "="  _col(`offset') as res `sampsize_C'
			di _s(2) as text "n in treatment arm"  _col(`=`offset'-2') "="  _col(`offset') as res `sampsize_T'
			di _s(2) as text "power"  _col(`=`offset'-2') "="  _col(`offset') as res %5.4f  `power'

		
			if "`strecruitment'"!="" local table yes
			if "`dropouts'"!="" local table yes

	
			*if "`table'"=="yes" {
				
					local Clist
					local Tlist
					local headlist1
					local headlist2
					local cwidth=9
					if `sched_length'>12	local cwidth=6
					tempname CmatN TmatN CmatrdN TmatrdN
					foreach mat in `CmatN' `TmatN' `CmatrdN' `TmatrdN' {
						mat `mat'=J(1,`sched_length',0)
					}
					forvalues i=1/`sched_length' {
						local start=15
						if `i'==1 local sumCN_`i'=`sumpwgts'*`sampsize_C'
						local pwgts_`i': word `i' of `pwgts'
						
						if `i'>1 local sumCN_`i'=`sumCN_`=`i'-1'' -`pwgts_`=`i'-1''*`sampsize_C'
						local sumCNrd_`i': di %-5.0f abs(`sumCN_`i'')					
						local pwgts2_`i': word `i' of `pwgts2'
						if `i'==1 & "`drop2'"!="" local sumTN_`i'=`sumpwgts2'*`sampsize_T'
						
						if `i'==1 & "`drop2'"=="" local sumTN_`i'=`sumpwgts'*`sampsize_T'
						
						if `i'>1 local sumTN_`i'=`sumTN_`=`i'-1'' -`pwgts2_`=`i'-1''*`sampsize_T'
						local sumTNrd_`i': di %-5.0f abs(`sumTN_`i'')			
						local hdi`i' "visit `i'"
						if `sched_length'>12 local hdi`i' "v_`i'"
						local headlist1 "`headlist1' " _col(`=`start'+`cwidth'*(`i'-1)') "`hdi`i''"
						
						local h`i': word `i' of `schedule'
						local hd2i`i' "time=`h`i''"
						if `sched_length'>12 local hd2i`i' "t=`i'"
						local headlist2 "`headlist2' " 	_col(`=`start'+`cwidth'*(`i'-1)') "`hd2i`i''"
						local Clist "`Clist' "  _col(`=`start'+`cwidth'*(`i'-1)') "`sumCNrd_`i''"
						local Tlist "`Tlist' " _col(`=`start'+`cwidth'*(`i'-1)') "`sumTNrd_`i''"
						mat `CmatN'[1,`i']=`sumCN_`i''
						mat `TmatN'[1,`i']=`sumTN_`i''
						mat `CmatrdN'[1,`i']=`sumCNrd_`i''
						mat `TmatrdN'[1,`i']=`sumCNrd_`i''
						
					}
				*}


	if "`notable'"=="" {
		if "`strecruitment'"!="" local table yes
		if "`dropouts'"!="" local table yes

		if `sched_length'<=20 {	
			if "`table'"=="yes" {
				local line =12
				di _n as text "Table of control and treatment group numbers (rounded) reaching each visit:"						
					di  _col(`line') "{c |}"	"`headlist1'"
					di  _col(`line') "{c |}"	"`headlist2'" 
					di  _dup(`=`line'-1') "{c -}" _col(`line') "{c +}"	_dup(`=`cwidth'*`=`sched_length'+1'-5') "{c -}" 
					di  "control " _col(`line') "{c |}" "`Clist'" 
					di  "treatment " _col(`line') "{c |}" "`Tlist'"  
				}
			}
	}
	
	** back to returns 
	

	return matrix trtrd_num=`TmatrdN'
	return matrix contrd_num=`CmatrdN'
	return matrix trt_num=`TmatN'
	return matrix cont_num=`CmatN'
	return matrix sched_list=`schedmat'
	return local final_wgts `"`pwgts'"'
	
	tempname   eff setrial 

	scalar `setrial'=sqrt(`vartte'/(`sampsize'/`arsum'))
	return scalar se_trial=`setrial'
	return scalar var_trteff=`vartte'
	return scalar wgt_trteff=`wtte'
	scalar `eff'=`effsize'
	return scalar effectsize=`eff'
	return scalar power=`power'
	return scalar fractional_power=`frac_power'
	return scalar samplesize=`sampsize'
	return scalar fractional_ss=`frac_ss'
	return local schedule "`schedule'"	
	return local cmd mixedpower
	return local cmdline `"mixedpower `0'"'

	
	frame change `cframe'
	/*
	if "`frames'"=="drop" {
		frame drop _mp_`model'_`trtspec'
	}	
	*/

		
end



capture program drop xslopecheck
program xslopecheck, sclass 
	version 17.0
	
	syntax, xnum(string) option(string) spec(string) 
	
					capture confirm number `xnum'
						if _rc!=0 {
							dis as error "time value supplied with `option'(`spec') option must be a real number"
							exit 198
					}
					capture assert `xnum'>=0
						if _rc!=0 {
							dis as error "time value supplied with `option'(`spec') option must be a real number >=0"
							exit 198
					}
					
end			

capture program drop testcheck
program testcheck, sclass 
	version 17.0
	
	syntax,  tsp(string) schl(numlist integer >=1 min=1 max=1) [test(string) xtra(string)]
	
	if "`test'"=="" {
			dis as error  "test() must be specified when trtspec() is '`tsp''"
			exit 198
	}
	numlist "`test'"
	local test=r(numlist)
	
	local contentslength : word count `test'
			if "`tsp'"=="factor0" {
								if `contentslength' != `schl' {
					dis as error  "content list length for test(`xtra')=`contentslength' when trtspec() is '`tsp'' must be same as visit schedule=`schl'"
					exit 198
				}
			}
			if "`tsp'"=="factor" {
								if `contentslength' != `schl'-1 {
					dis as error  "content list length for test(`xtra')=`contentslength' when trtspec() is '`tsp'' must be one less than for visit schedule=`schl'"
					exit 198
				}
			}
			if "`tsp'"=="slint" | "`trtspec'"=="2slope" | "`trtspec'"=="user2" {
								if `contentslength' != 2 {
					dis as error  "content list length for test(`xtra'=`contentslength') when trtspec() is '`tsp'' must be 2"
					exit 198
				}
			}

				forvalues d=1/`contentslength' {
					local contents`d' : word `d' of `test'
					capture confirm number `contents`d''
						if _rc!=0 {
							dis as error "content list for test() must be specified as number values"
							exit 198
					}
				}					
end	

capture program drop usercheck
program usercheck, sclass 
	version 17.0
	
	syntax,   func(string) option(string) xvalues(numlist)
		
		sreturn clear
		
		gettoken finit : func, parse("(") match(br)
		local numfunc=1
		if strmatch("`finit'", "*;*")	{
			local numfunc=2
			gettoken func1 finit: finit, parse(;)
			gettoken comma1 finit: finit, parse(;)
			if strmatch("`finit'", "*;*") {
				di as error "You have tried to specify (by use of semi-colon separation) too many user-defined functions in `option'"
				exit 198
			}
			else local func2 `finit'
		}
		else local func1 `finit'
		tempname _mp_userfunctionscheck
		frame create `_mp_userfunctionscheck'
		frame change `_mp_userfunctionscheck'
		
		local y1
		local y2
		local sl: word count `xvalues' 
		qui set obs `sl'
		qui gen double x=.
		qui gen double yvar1=.
		if `numfunc'==2 qui gen double yvar2=.
		forvalues sch=1/`sl' {
			local xv1`sch': word `sch' of `xvalues'
			*local fn1=subinstr("`func1'","x","`xv1`sch''",.)
			
			qui replace x=`xv1`sch'' in `sch'
			capture qui replace yvar1=`func1' in `sch'
			if _rc!=0 {
				di as error "user-function_1 provided cannot be evaluated for `option'"
				exit 198
			}
			
			local y1`sch'=yvar1[`sch']
			if   `y1`sch''==. local y1`sch'=0
			local y1 "`y1' `y1`sch''"
			if `numfunc'==2 {
				
				capture qui replace yvar2=`func2' in `sch'
				if _rc!=0 {
					di as error "user-function_2 provided cannot be evaluated for `option'"
					exit 198				
				}
				
				local y2`sch'=yvar2[`sch']
				if   `y2`sch''==. local y2`sch'=0
				local y2 "`y2' `y2`sch''"
			}


		}
		sreturn local nfun=`numfunc'
		sreturn local xfun1 "`y1'"
		sreturn local funct1 "`func1'"
		if `numfunc'==2 sreturn local xfun2 "`y2'"
		if `numfunc'==2 sreturn local funct2 "`func2'"
end	
