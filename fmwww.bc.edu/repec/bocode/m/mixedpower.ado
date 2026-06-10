*! version 1.0	1.6.2026
*! Matthew Burnell


/*
DESCRIPTION
mixedpower ia a power calculator for linear mixed models.

*/
**# PROGRAM

program define mixedpower , rclass
	version 17.0 
	
	local version 1.0
	local date 01June2026
	if _caller() >= 12 {
		local hidden hidden
	}
	return `hidden' local mixedpower_version "`version'"
	return `hidden' local mixedpower_date "`date'"
	if "`0'"=="which" exit
	
	syntax, SCHEDule(numlist ascending >=0 min=2 max=100)	/// schedule list of time incl. baseline
			TRTSPEC(string)							/// how treatment effect specified (slope, intercept, slope and intercept or piecewise (factor and factor0))
			[   									///
			LCTest(numlist)  						///  lincom test of trt paremeters
			JTTest(numlist integer >=0 <=1)			/// joint test of trt paremeters
			CONTSlope(string) 						/// the overall mean slope of the 'control' group
			EFFectiveness(string)  					/// proportionate effect on slope (not for other trtspec types)
			DIFFerence(numlist  min=1 max=100)   					/// the alternative hypothesis difference (numberlist for factor, intercept and slint choices in trtspec())					
			ALTCont(string)							/// if you want the cont (control) slope to be piecewise/time-factorised/ or specify no intercept or no slope (factor, noint, noslope - default is slope and intercept)
			ACTUALTRT(string)						/// calculate power for an incorrect treatment specification, by specifying the true treatment specification 
			ACTUALCont(string)						/// if you also want to indicate that the control specification is incorrect, hence give correct specification 
			CBETA(numlist min=1)					/// control beta values if using actualcont()
			Alpha(real 0.05) 						/// alpha level of test	
			TWOSided								/// request properly two-sided test
			POWer(string) 							/// required power 
			n(string) 								/// provided sample size
			ARAtio(numlist integer >0 min=2 max=2)	///  allocation ratio of controls:treatment adjustment version 
			ALLORatio(numlist integer >0 <=10 min=2 max=2) /// HIDDEN	allocation ratio version of controls:treatment MULTIMATRIX VERSION 
 			DROPouts(numlist >=0 <=1)	  			///	numlist values of p(making visit to k and no further) due to dropout (possibly for Control group only)
			DROP2(numlist >=0 <=1)	  				///	numlist values of p(making visit to k and no further) for Treatment Group if different to Control
			STRECruitment(numlist >=0 <=1) 			///	numlist values of p(making visit to k and no further) due to staggered recruitment
			COVariance(string) 						///	covariance matrix of random effect parameters
			ERRORvar(string) 						/// error term (or matrix for multivariate)
			AUTO 									/// speedy variance input using mixed model in memory
			MARGinal								/// specify marginal model - XT variance modelled by error structure patterns only - no random effects included
		    ERRHET(string)  						///  different error terms for treatment group
			ERRXT(string) 							/// matrix input for general or specific non-independent error types across repeated measures - usually for use with 'marginal'
			COVHET(string) 							///	covariance matrix of random effect parameters for treatment group if different			
			SCAle(real 1)  							/// to specify schedule numlist in different scale to variance input
			NOSYNtax								/// prevent display of model syntax
			XMAT(numlist integer >=1 max=1)			/// return specific X matrix
			RMAT(numlist integer >=1 max=1)			/// return specific R matrix
			ZMAT(numlist integer >=1 max=1)			/// return specific Z matrix
			GMAT(numlist integer >=1 max=1)			/// return specific G matrix
			BVARN(numlist integer >=1 max=1)		/// return specific Beta covariance matrix
			NOHEADer								/// turn off header
			NOTABle									/// turn of table of counts
			FRAMES(string)							/// HIDDEN OTPION keep frames of generated X, R, Z and G matrices
			FRDROP									/// HIDDEN OTPION use to drop _mp frames from previous run of mixedpower when frames(keep) option used - might not (depending on _mp name) run otherwise unless manually dropped first. 
			  /// /* following options for integrating uncertainty */ to be part of separate program?
			IVW										/// HIDDEN OTPION to use IVW instead of inverse-covariance weighting for calculating cohort-combined Betas with X-misspecification   
			]

	
			
**# PROLOGUE
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
	local model 2level

**# TRTSPEC
				** And treatment specification type is chosen and correct - if not chosen then assume 
if strmatch("`trtspec'", "user(*)") local tusertext `trtspec' // to pass to 3level to parse again
if strmatch("`altcont'", "user(*)") local cusertext `trtspec'
					
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
				
**# ALTCONT
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
	
	

	
					** Equivalent treatment and control checks for when actualtrt() and actualcont() specified 

				
**# ACTUALTRT
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
				
**# ACTUALCont
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
		

	
		
**# TEST Check
			** Checking Test Options
	if "`jttest'"!="" & "`lctest'"!="" {
		dis as error  "cannot specify both jttest() and lctest"
					exit 198
	}		
		
			* first change lctest or jttest 
	if 	"`jttest'"!="" local test "joint(`jttest')"
	if 	"`lctest'"!="" local test "`lctest'"
			
			
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
				qui numlist "`test'"     
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

	
**# COVARIANCE/ERROR specification
	  ** Making sure either errorvar or errxt is specified (when auto not used)
	  	if "`errorvar'"!="" & "`errxt'"!="" {
	  	dis as error "You must specify only one of errorvar() or errxt()"
					exit 198
	  }
	  if "`auto'"=="" {
		  if "`errorvar'"=="" & "`errxt'"=="" {
			dis as error "You must specify either errorvar() or errxt() if not using auto option"
						exit 198
		  }
	  }
	  if "`errorvar'"=="" & "`errxt'"!="" {
		local errmethod errmethod
	  }
	  if "`errorvar'"!="" & "`errxt'"=="" {
		local errmethod errmethod
	  }

				** Check either auto or (ERRorvar & COVariance) used
	if  "`marginal'"=="" {								
	if "`covariance'"!="" & "`auto'"!="" {
					dis as error "You cannot specify both covariance() (together with errorvar()/errxt()) and auto"
					exit 198
				}
	if "`covariance'"=="" & "`auto'"=="" {
					dis as error "No covariance parameter specification: please specify either covariance() and errorvar()/errxt() OR auto OR marginal if intend no random effects"
					exit 198
				}
				
				* check errorvar and auto not both specified
	if "`errorvar'"!="" & "`auto'"!="" {
					dis as error "You cannot specify both errorvar() (together with covariance()) and auto"
					exit 198
				} 
				* Check  error variance included if covariance used 
	if "`covariance'"!="" & "`errmethod'"=="" {
					dis as error "You must specify either errorvar()/errxt() with covariance()"
					exit 198
				}
				* Check covariance included if errorvar used 
	if "`covariance'"=="" & "`errorvar'"!="" {
					dis as error "You must specify covariance() with errorvar()"
					exit 198
				}
	}		
	if "`auto'"!=""  & "`e(cmd)'"!="mixed" {
		di as error "there is no mixed model fitted by {helpb mixed} in memory"
		exit 198
	}
			
			* Check covariance/error commands not used with marginal option
	if  "`marginal'"!="" {
		if "`errorvar'"!=""  {
					dis as error "You cannot specify both errorvar() and marginal - for a marginal model the error terms (even 'identity' structure) are specified through errxt()"
					exit 198
				} 
		if "`covariance'"!=""  {
					dis as error "You cannot specify both covariance() and marginal"
					exit 198
				} 		
		if "`auto'"!=""  {
					dis as error "You cannot specify both auto and marginal"
					exit 198
				}
	}

				** Check Covariance values
	if  "`marginal'"=="" {				
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
			di as error "mixed model in memory has no random effects and marginal has not been specified"
			exit 198
		}
		else if "`auto'"!="" & `=e(k_r)'==1 {  // RE CHECK
			di as error "mixed model in memory has no random effects and marginal has not been specified"
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
				di as error "covhet() must be specified as 2x2 symmetric matrix using input() suboption or use auto-input of variance parameters with auto suboption"
			}	
		}
		 
	}			
	
**# ERRXT PARSING
			** Check ERRXT and ERRHET auto-options
			
	if  "`marginal'"!="" {		
		if "`errxt'"=="" {
			dis as error "if option marginal specified then must provide an xt error structure in errxt()"
					exit 198
		}
	}
	
	if 	"`errxt'"!=""  {
		local errxt=strtrim("`errxt'")
		if strmatch("`errxt'", "auto") {
			local restype resauto
			errxtmixcheck, residt(`=e(rstructlab)') hetcheck(`=e(resopt)') hety(no)  
			local resid `s(residt)'
			local rsh `s(rshort)'
			local rnumber=`s(rnum)'
			local `rsh'n=`rnumber'
			if "`resid'"=="unstructured" & e(k_rs)/e(nrgroups)<`sched_length' {
				di as error "not enough error terms in auto model in memory for schedule length" 
				exit 198
			}
		}
	
		else if strmatch("`errxt'", "input(*)") {  // checking the input suboptions
			local restype resinput
			local resid=subinstr(`"`errxt'"', "input(", "", 1)
			local resid=strtrim(subinstr("`resid'", ")", "", 1))
			
			local resabbrev: word 1 of `resid'
			capture extabcheck, `resabbrev'
			local resfull `s(exttype)'
			
			if "`s(exttype)'"=="" err198 You have not correctly specified the residual error structure name
			local resid: subinstr local resid "`resabbrev'" "`resfull'"
			
			if strmatch("`resid'", "ar *") { // if AR residuals
				local arn2=subinstr("`resid'", "ar ", "", 1)
				local arn2length : word count `arn2'
				if `arn2length'<2 | `arn2length'>3  { // WAS: if `arn2length'<2 | `arn2length'>`sched_length'
					dis as error  " list of AR parameters with 'input' suboption must be at least two and currently at most 3 (for AR 2)"
					exit 198
				}
				forvalues d=1/`arn2length' {
					local contents`d' : word `d' of `arn2'
					capture confirm number `contents`d''
						if _rc!=0 {
							dis as error "list of AR parameters must all be number values"
							exit 198
					}
				}	
					if  `arn2length'==2 & (`contents2'>=1 | `contents2' <=-1) {
						dis as error "AR autocorrelation parameter must be inside range {-1, 1}" // CHANGE!!!
							exit 198
					}
				
			}	
				
			else if strmatch("`resid'", "ma *") { // if MA residuals
				local man2=subinstr("`resid'", "ma ", "", 1)
				local man2length : word count `man2'
				if `man2length'<2 | `man2length'>3  { // currently max=2 if `man2length'<2 | `man2length'>`sched_length'
					dis as error  " list of MA parameters must be at least two and and currently at most 3 (for MA 2)"
					exit 198
				}
				forvalues d=1/`man2length' {
					local contents`d' : word `d' of `man2'
					capture confirm number `contents`d''
						if _rc!=0 {
							dis as error "list of MA parameters must all be number values"
							exit 198
					}
				}
			}
						// no input version of Banded residuals - use unstructured
						
			else if strmatch("`resid'", "toeplitz *") { // if Toeplitz residuals
				local ton2=subinstr("`resid'", "toeplitz ", "", 1)
				local ton2length : word count `ton2'
				if `ton2length'==0 | `ton2length'>`sched_length'  {
					dis as error  " list of Toeplitz parameters must be at least one and equal or less than schedule length"
					exit 198
				}
				forvalues d=1/`ton2length' {
					local contents`d' : word `d' of `ton2'
					capture confirm number `contents`d''
						if _rc!=0 {
							dis as error "list of Toeplitz parameters must all be number values"
							exit 198
					}
				}
			}
			else if strmatch("`resid'", "exponential *") { // if Exponential residuals i.e generalised AR 1
				local exn2 =subinstr("`resid'", "exponential ", "", 1)
				local exn2length : word count `exn2'
				if `exn2length'!=2  {
					dis as error  " list of exponential parameters must be 2"
					exit 198
				}
				forvalues d=1/`exn2length' {
					local contents`d' : word `d' of `exn2'
					capture confirm number `contents`d''
						if _rc!=0 {
							dis as error "list of exponential parameters must all be number values"
							exit 198
					}
				}
				if `contents2' <=-1 | `contents2'>=1 {
					dis as error "Exponential autocorrelation parameter must be inside range {-1, 1}"
					exit 198
				}	
			}
			else if strmatch("`resid'", "unstructured *") { // if unstructured
				
				local rm =subinstr("`resid'", "unstructured ", "", 1)
				local rm2length : word count `rm'
				if `rm2length'>1  {
					dis as error "suboption input(unstructured {it: matname}) must be supplied with single name of matrix"
					exit 198
				}
				tempname resid_mat
				capture mat `resid_mat'=  `rm' // first checking matrix supplied in correct format
					if  _rc!=0 {
								dis as error "matrix entry for input(unstructured {it: matname}) not correct format"
					exit 198
							}
				capture confirm matrix `resid_mat'  // first checking matrix supplied in correct format
				if  _rc!=0 {
								dis as error "matrix entry for input(unstructured {it: matname}) not correct format"
					exit 198
							}
				local col=colsof(`resid_mat')
				local sym= issymmetric(`resid_mat')
				if `sym' ==0 {
					mat li `resid_mat'
					dis as error "matrix entry for input(unstructured {it: matname}) must be symmetric"
					exit 198
				}
				
				if `col'!=`sched_length' {
								dis as error "matrix entry for input(unstructured {it: matname}) must be symmetric nxn, where n=number of measures supplied in schedule()"
					exit 198
				}
			
			}
			else if strmatch("`resid'", "exchangeable *") { // if exchangeable
				local ecn2 =subinstr("`resid'", "exchangeable ", "", 1)
				local ecn2length : word count `ecn2'
				if `ecn2length'!=2   {
					dis as error  " list of suboption input(exchangeable # #) parameters in errxt() must be of length 2"
					exit 198
				}
				forvalues d=1/`ecn2length' {
					local contents`d' : word `d' of `ecn2'
					capture confirm number `contents`d''
						if _rc!=0 {
							dis as error "list of suboption input(exchangeable # #) parameters in errxt() must both be number values"
							exit 198
					}
				}	
			}
			else if strmatch("`resid'", "independent *") { // if independent
				local inn2 =subinstr("`resid'", "independent ", "", 1)
				local inn2length : word count `inn2' 
				if `inn2length'!=1 & `inn2length'!=`sched_length'    {
					dis as error  " list of suboption input(independent # [#..]) parameters in errxt() must be of length 1 or length of schedule list"
					exit 198
				}
				forvalues d=1/`inn2length' {
					local contents`d' : word `d' of `inn2'
					capture confirm number `contents`d''
						if _rc!=0 {
							dis as error "list of suboption input(independent # [#..]) parameters in errxt() must all be number values"
							exit 198
					}
				}	
			}
			else {
				dis as error "error structure supplied with 'input' suboption in errxt() is not recognised. Must be one of independent, exchangeable, ar # [#..], ma # [#..], unstructured {it: matname}, toeplitz # [#..], or exponential # - for banded use unstructured"
				exit 198
			}
		}
		else  {
				dis as error "error structure in errxt() must use either auto or input() suboptions "
				exit 198
		}
	}	
   if "`restype'"=="resinput" local resfull `resid'

	gettoken resid : resid

**# ERRHET PARSING

	if 	"`errhet'"!=""  {
		local errhet=strtrim("`errhet'")	
		if strmatch("`errhet'", "auto") {
			local hrestype resauto
			errxtmixcheck, residt(`=e(rstructlab)') hetcheck(`=e(resopt)') hety(yes)  
			local hresid `s(residt)'
			local hrsh `s(rshort)'
			local hrnumber=`s(rnum)'
			local ehet `s(het)'
			local `ehet'`hrsh'n=`hrnumber'
			
			if "`resid'"=="unstructured" & e(k_rs)/e(nrgroups)<`sched_length' {
				di as error "not enough error terms in mixed model in memory for schedule length" 
				exit 198
			}
		}
		
		else if strmatch("`errhet'", "input(*)") {  // checking the input suboptions
			local hrestype resinput
			local hresid=subinstr(`"`errhet'"', "input(", "", 1)
			local hresid=strtrim(subinstr("`hresid'", ")", "", 1))
			
			local hresabbrev: word 1 of `hresid'
			capture extabcheck, `hresabbrev'
			local hresfull `s(exttype)'
			
			if "`s(exttype)'"=="" err198 You have not correctly specified the heteroschedastic residual error structure name
			local hresid: subinstr local hresid "`hresabbrev'" "`hresfull'"
				
		/*
		else if strmatch("`errhet'", "input(*)") {  // checking the input suboptions
			local hrestype resinput
			local hresid=subinstr(`"`errhet'"', "input(", "", 1)
			local hresid=strtrim(subinstr("`hresid'", ")", "", 1)) */
			
			if strmatch("`hresid'", "ar *") { // if AR residuals
				local harn2=subinstr("`hresid'", "ar ", "", 1)
				local harn2length : word count `harn2'
				if `harn2length'<2 | `harn2length'>3 { // 	if `harn2length'<2 | `harn2length'>`sched_length'
					dis as error  " list of input AR parameters for errhet() option with 'input' suboption must be at least two and at most 3 (for AR 2)"
					exit 198
				} // change to max of 2 AR terms i.e 3 values??
				forvalues d=1/`harn2length' {
					local hcontents`d' : word `d' of `harn2'
					capture confirm number `hcontents`d''
						if _rc!=0 {
							dis as error "list of AR parameters must all be number values"
							exit 198
					}
				}	
					if  `harn2length'==2 & (`hcontents2'>=1 | `hcontents2' <=-1) {
						dis as error "AR autocorrelation parameter must be inside range {-1, 1}" // CHANGE!!!
							exit 198
					}
				
			}	
				
			else if strmatch("`hresid'", "ma *") { // if MA residuals
				local hman2=subinstr("`hresid'", "ma ", "", 1)
				local hman2length : word count `hman2'
				if `hman2length'<2 | `hman2length'>3  { // currently max=2 if `hman2length'<2 | `hman2length'>`sched_length'
					dis as error  "list of input MA parameters must be at least two and and at most 3 (for MA 2)"
					exit 198
				}
				forvalues d=1/`hman2length' {
					local hcontents`d' : word `d' of `hman2'
					capture confirm number `hcontents`d''
						if _rc!=0 {
							dis as error "list of MA parameters must all be number values"
							exit 198
					}
				}
			}
						// no input version of Banded residuals - use unstructured
						
			else if strmatch("`hresid'", "toeplitz *") { // if Toeplitz residuals
				local hton2=subinstr("`hresid'", "toeplitz ", "", 1)
				local hton2length : word count `hton2'
				if `hton2length'==0 | `hton2length'>`sched_length'  {
					dis as error  "list of Toeplitz parameters must be at least one and equal or less than schedule length"
					exit 198
				}
				forvalues d=1/`hton2length' {
					local hcontents`d' : word `d' of `hton2'
					capture confirm number `hcontents`d''
						if _rc!=0 {
							dis as error "list of Toeplitz parameters must all be number values"
							exit 198
					}
				}
			}
			else if strmatch("`hresid'", "exponential *") { // if Exponential residuals i.e generalised AR 1
				local hexn2 =subinstr("`hresid'", "exponential ", "", 1)
				local hexn2length : word count `hexn2'
				if `hexn2length'!=2  {
					dis as error  " list of exponential parameters must be 2"
					exit 198
				}
				forvalues d=1/`hexn2length' {
					local hcontents`d' : word `d' of `hexn2'
					capture confirm number `hcontents`d''
						if _rc!=0 {
							dis as error "list of exponential parameters must all be number values"
							exit 198
					}
				}
				if `hcontents2' <=-1 | `hcontents2'>=1 {
					dis as error "exponential autocorrelation parameter must be inside range {-1, 1}"
					exit 198
				}	
			}
			else if strmatch("`hresid'", "unstructured *") { // if unstructured
				
				local hrm =subinstr("`hresid'", "unstructured ", "", 1)
				local hrm2length : word count `hrm'
				if `hrm2length'>1  {
					dis as error "suboption input(unstructured {it: matname}) must be supplied with single name of matrix"
					exit 198
				}
				tempname hresid_mat
				capture mat `hresid_mat'=  `hrm' // first checking matrix supplied in correct format
					if  _rc!=0 {
								dis as error "matrix entry for input(unstructured {it: matname}) not correct format"
					exit 198
							}
				capture confirm matrix `hresid_mat'  // first checking matrix supplied in correct format
				if  _rc!=0 {
								dis as error "matrix entry for input(unstructured {it: matname}) not correct format"
					exit 198
							}
				local col=colsof(`hresid_mat')
				local sym= issymmetric(`hresid_mat')
				if `sym' ==0 {
					dis as error "matrix entry for input(unstructured {it: matname}) must be symmetric"
				}
				
				if `col'!=`sched_length' {
								dis as error "matrix entry for input(unstructured {it: matname}) must be symmetric nxn, where n=number of measures supplied in schedule()"
					exit 198
				}
			
			}
			else if strmatch("`hresid'", "exchangeable *") { // if exchangeable
				local hecn2 =subinstr("`hresid'", "exchangeable ", "", 1)
				local hecn2length : word count `hecn2'
				if `hecn2length'!=2   {
					dis as error  " list of suboption input(exchangeable # #) parameters in errxt() must be of length 2"
					exit 198
				}
				forvalues d=1/`hecn2length' {
					local hcontents`d' : word `d' of `hecn2'
					capture confirm number `hcontents`d''
						if _rc!=0 {
							dis as error "list of suboption input(exchangeable # #) parameters in errxt() must both be number values"
							exit 198
					}
				}	
			}
			else if strmatch("`hresid'", "independent *") { // if independent
				local hinn2 =subinstr("`hresid'", "independent ", "", 1)
				local hinn2length : word count `hinn2' 
				if `hinn2length'!=1 & `hinn2length'!=`sched_length'    {
					dis as error  " list of suboption input(independent # [#..]) parameters in errxt() must be of length 1 or length of schedule list"
					exit 198
				}
				forvalues d=1/`hinn2length' {
					local hcontents`d' : word `d' of `hinn2'
					capture confirm number `hcontents`d''
						if _rc!=0 {
							dis as error "list of suboption input(independent # [#..]) parameters in errxt() must all be number values"
							exit 198
					}
				}	
			
			}
			else {
				dis as error "error structure supplied with 'input' suboption in errhet() is not recognised. Must be one of independent, exchangeable, ar # [#..], ma # [#..], unstructured {it: matname}, toeplitz # [#..], or exponential # - for banded use unstructured"
				exit 198
			}
		}
		else  {
				dis as error "error structure in errhet() must use (currently) only input() suboptions "
				exit 198
		}
	}	
	
	gettoken hresid : hresid
	

**# CHECKING CORRECT INPUTS FOR TRTSPEC CHOICE
				
* IF: trtspec=="slope" Check either used: Effectiveness + CONTSlope OR Difference 
	*if "`model'"!="multi" {			
		if "`trtspec'"=="slope" {
				* check effectiveness and difference not both specified
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
				* check contslope and both specified 
				if "`effectiveness'"=="" & "`contslope'"!="" {
					dis as error "You must specify both effectiveness() and contslope()"
					exit 198
				}
				if 	"`effectiveness'"!="" & "`actualtrt'"!="" {
					dis as error "You cannot specify effectiveness() when also specifying actualtrt()"
					exit 198

				}
			}	
	
	
		if "`trtspec'"=="intercept" | "`trtspec'"=="factor" | "`trtspec'"=="factor0" | "`trtspec'"=="slint" | "`trtspec'"=="lateslope" | "`trtspec'"=="2slope" | "`trtspec'"=="user" | "`trtspec'"=="user2" {	
			if  "`difference'"=="" {
					dis as error "You must specify difference() when trtspec() is 'intercept', 'factor', 'factor0', 'slint', 'lateslope', '2slope' or 'user'"
					exit 198
			} 
			if  "`contslope'"!="" {
					dis as error "You must specify difference() ONLY when trtspec() is 'intercept', 'factor', 'factor0', 'slint', 'lateslope', '2slope' or 'user'"
					exit 198
			}		
			if  "`effectiveness'"!="" {
					dis as error "You must specify difference() ONLY when trtspec() is 'intercept', 'factor', 'factor0', 'slint', 'lateslope', '2slope' or 'user'"
					exit 198
			} 		
					
		}  
		

		
		* Now check effectiveness is a number >0 and <= 1  if model!=multi, then check contslope
					
		if "`effectiveness'"!="" { // Effectiveness is specified
				capture confirm number `effectiveness'
				if _rc!=0 {
					dis as error "Effectiveness() must be a number greater than 0 and less than or equal to 1"
					exit 198
				}
				* So eff is specified and it's a number
				if `effectiveness' > 1 {
					dis as error "Effectiveness() must be less than or equal 1"
					exit 198
				}
				if `effectiveness' <=0 {
					dis as error "Effectiveness() must be strictly greater than 0"
					exit 198
				}  // if Model!=multi

											
							
		* Now check contslope is a number - or instead variable name for slope term in mixed model in memory
			if "`contslope'"!="" { // contslope is specified
					capture confirm number `contslope'
					if _rc==0 {
						local ns_num=1
							}
					if _rc!=0 {
						local ns_num=0
						 local b_name "`contslope'"	
						 tempname beta
						capture scalar `beta'=_b[`b_name'] // using the slope from mixed - doesn't always work if the variable isn't in the dataset! though can just create a fake variable  with that name...
				
						if "`contslope'"!="" & _rc==111 {
							dis as error "the overall (no treatment) contslope() must be a number or the name of the slope in a mixed model in memory"
							exit 198
						}
						
					}
				local difflength=1  // for presenting treatment effect in output
				
			} 
						
		} // If statement "eff is specified" 
		
		
**# DIFF check
		**Checking Difference is correctly specified for various trtspec choices or for actualtrt instead is specified
									
		*  check if using difference that it is a number if trtspec is slope, intercept or lateslope 

		local treatsp `trtspec'
		if "`actualtrt'"!="" local treatsp `actualtrt'
		
		if "`treatsp'"=="slope" | "`treatsp'"=="intercept" | "`treatsp'"=="lateslope" | "`treatsp'"=="user"   {
			if "`difference'"!="" { // difference is specified
				local difflength : word count `difference' 
				if `difflength'!=1     {
					dis as error  "length of supplied values in difference() option when using 'slope', 'intercept', 'lateslope' or 1 'user' function must be one - check if actualtrt() specified"
					exit 198
				}
				forvalues d=1/`difflength' {
					local diff`d' : word `d' of `difference'
					capture confirm number `diff`d''
						if _rc!=0 {
							dis as error "list of supplied values in difference() option must all be numbers"
							exit 198
					}
					
				}
			}
			local altvarX=1
		}	
		

			
			* check difference  is 2 numbers if trtspec is slint (slope and intercept), user2  or 2slope
		if "`treatsp'"=="slint" | "`treatsp'"=="2slope" | "`treatsp'"=="user2"  {
			if "`difference'"!="" { // difference is specified
				local difflength : word count `difference'
				if `difflength' != 2 {
					dis as error  " list of difference() effects for 'slint', '2slope' or 2 'user' functions must be length 2 - check if actualtrt() specified"
					exit 198
				}
				forvalues d=1/`difflength' {
					local diff`d' : word `d' of `difference'
					capture confirm number `diff`d''
						if _rc!=0 {
							dis as error "all difference() elements must be specified as a number value"
							exit 198
					}
				
				}
			
			}		
			local altvarX=2  // for later in picking out elements of 'test'
		}	
		
				* check difference  is a number if trtspec is factor 
		if "`treatsp'"=="factor" {
			if "`difference'"!="" { // difference is specified
				local difflength : word count `difference'
				if `difflength' != `sched_length'-1 {
					dis as error  "piecewise list of difference() for factor effects must be of length one less than schedule() - check if actualtrt() specified"
					exit 198
				}
				forvalues d=1/`difflength' {
					local diff`d' : word `d' of `difference'
					capture confirm number `diff`d''
						if _rc!=0 {
							dis as error "all difference() elements must be specified as a number value"
							exit 198
					}
					
				}
			}		
			local altvarX=`sched_length'-1  // for later in picking out elements of 'tes
		}	
		
				* check difference  is a number if trtspec is factor0   
		if "`treatsp'"=="factor0" {
			if "`difference'"!="" { // difference is specified
				local difflength : word count  `difference'
				if `difflength' != `sched_length' {
					dis as error  "piecewise list of difference() effects in factor0 must be same length as schedule() - check if actualtrt() specified"
					exit 198
				}
				forvalues d=1/`difflength' {
					local diff`d' : word `d' of `difference'
					capture confirm number `diff`d''
						if _rc!=0 {
							dis as error "all difference() elements must be specified as a number value"
							exit 198
					}
				
				}
			
			}		
			local altvarX=`sched_length'  // for later in picking out elements of 'test'
		}	
			
	
**# CBETA
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
	
		
			
**# ALPHA and ARATIO
		
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
		
		/*
	* ARAtio - allocation ratio weightings FORMULA VERSION - inbuilt Stata syntax check is sufficient for parsing ARAtio
		
		if "`alloratio'"!="" & "`aratio'"!="" {
			dis as error "You are using both the ALLORatio() option and the secret ARatio() option - don't!"
							exit 198
		}
		
		if "`aratio'"!="" {
			
			local ar1: word 1 of `aratio'
			local ar2: word 2 of `aratio' 
			local arsum=`ar1'+`ar2' // for use later in power/SS calculations to reweight for 'number' in trial
			local k=(`ar1'/`ar2')
			local arfactor=(1+(`k'-1)^2/(4*`k')) // for use later in power/SS calculations to reweight for 'number' in trial				
		}	
		*/
		
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
		
		
**# POWER and SAMPLE SIZE
		
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
	/*			
* NPCLUSTER
	if "`model'"=="3level" {
				if "`npcluster'"=="" {
			di as error "option npcluster() required if model(3level)"
			exit 198
		}
	}
	else {
		if "`cov3l'"!="" {
			di as error "option cov3l() only required for model(3level)"
			exit 198
		}
		if "`npcluster'"!="" {
			di as error "option npcluster() only required for model(3level)"
			exit 198
		}
		if "`wpcluster'"!="" {
			di as error "option wpcluster() only required for model(3level)"
			exit 198
		}
	}
	*/
	
**# SCALE and FRAMES 
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

**# DROPUTS
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
		
**# STREC
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
					dis as error  "Staggered recruitment - strecruitment() - list must correspond in length (`strec_length') with visit schedule (`sched_length')"
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
					
**# SUMMARISING DROPOUTS and STREC
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
		
			
**# FIRST RETURNS

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
		if "`twosided'"!="" local tsided ts_yes
		else local tsided ts_no
		if "`jttest'"!="" local tsided ts_yes
		tempname crita scl dim
		scalar `crita'=`alpha'
		scalar `scl'=`scale'
		return scalar alpha=`crita'
		return scalar scale=`scl'
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
		
		
**# XMAT, RMAT etc parsing 

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
**# 2-LEVEL MODEL CALCULATIONS
********************************************************************************

*if "`model'" =="2level" {
		//qui tempname  covmat

** Check Covariance values
				
**# BASIC COVARIANCE INPUTS

* Check user-inputted COVariance is a 2x2 symmetric matrix assuming user/matrix input
	if "`covariance'"!=""  {
		tempname cov_mat
		mat `cov_mat'=`covariance'
		local col=colsof(`cov_mat')
		local sym= issymmetric(`cov_mat')

		if `sym' ==0 | `col'!=2 {
						dis as error "covariance() matrix must be symmetric 2x2"
			exit 198
					}
		}
		
*Check user-inputted random effect variances >=0 
					
	if "`covariance'"!="" { // version for if numbers entered directly as matrix
			local intvar= el(`cov_mat', 1, 1)  
								if `intvar' < 0 {
				dis as error "random intercept variance must be a positive number, unless intentially zero (random slope model only or standard linear regression if slope variance also =0)"
				exit 198
			}
			
			local slvar= el(`cov_mat', 2, 2)  
								if `slvar' <0 {
				dis as error "random slope variance must be a positive number, unless intentially zero (random intercept model only or standard linear regression if intercept variance also =0)"
				exit 198
			}
			
	}	
	 				
		
*Check user-inputted COVariance has implied correlation <=1 and >=-1
	 if "`covariance'"!=""  {
	 	tempname corr_mat
		local cov12=el(`cov_mat', 1,2)
		if `cov12'!=0 {
			mat `corr_mat'=corr(`cov_mat')
			local corr_slopeint= el(`corr_mat', 1, 2)
			if `corr_slopeint' >1 {
				dis as error "correlation of random effects is greater than 1 - check values"
				exit 198
			}
			if `corr_slopeint' <-1 {
				dis as error "correlation of random effects is less than -1 - check values"
				exit 198
			}
		}	
		else local corr_slopeint=0
	 }
	

	
* 'auto' auto-version
	if "`auto'"!="" {
		local rewc: word count `=e(redim)'
		local vtwc: word count `=e(vartypes)'
		
		forvalues re=1/`rewc' {
			local re`re' : word `re' of `=e(redim)'
			local vt`re' : word `re' of `e(vartypes)'
		}
	
		if `re1'==2 { // version for if using mixed model in memory
		
				capture local slvar=(exp(_b[lns1_1_1:_cons]))^2 
					if _rc!=0 {
						local slvar=0
					}
				capture local intvar=(exp(_b[lns1_1_2:_cons]))^2
					if _rc!=0 {
						local intvar=0
					}
				capture local corr_slopeint=tanh(_b[atr1_1_1_2:_cons]) // correlation of random effects 
					if _rc!=0 {
						local corr_slopeint=0
					}			
				capture local cov12=`corr_slopeint'*sqrt(`intvar')*sqrt(`slvar')				
				if _rc!=0 {
						local cov12=0
					}	
		}		
				if "`vt1'"=="Identity" & `re1'==1 & `rewc'==1 {
					if e(revars)=="_cons" {
						local slvar=0
						local intvar=(exp(_b[lns1_1_1:_cons]))^2
					}
					if e(revars)!="_cons" {
						local intvar=0
						local slvar=(exp(_b[lns1_1_1:_cons]))^2
					}
					local  cov12=0 				
				} 
				if "`vt1'"=="Identity" & `re1'==1 & `rewc'==2 {
					if strmatch("`=e(revars)'", "*0.*#*") {
						local intvar=0 
						local slvar=(exp(_b[lns1_1_1:_cons]))^2
					}
					else {
						local intvar=(exp(_b[lns1_1_1:_cons]))^2
						local slvar=0 
					}
					local  cov12=0 				
				}
		
	}
	
**# HET COVARIANCE INPUT

	** Check Covhet values - covariance matrix for treatment grp if covhet() specified
			
* Check user-inputted covhet is a 2x2 symmetric matrix assuming user/matrix input 
	if "`chtype'"=="chinput"  { 
	
		local col=colsof(`chm')
		local sym= issymmetric(`chm')

		if `sym' ==0 | `col'!=2 {
						dis as error "covhet() matrix must be symmetric 2x2"
			exit 198
					}
		}
		
*Check user-inputted random effect variances >0 
				
	if "`chtype'"=="chinput" { // version for if numbers entered directly as matrix

			local hintvar= el(`chm', 1, 1)  
								if `hintvar' < 0 {
				dis as error "random intercept variance for covhet() must be a positive number, unless intentially zero (random slope model only or standard linear regression if slope variance also =0)"
				exit 198
			}
			
			local hslvar= el(`chm', 2, 2)  
								if `hslvar' <0 {
				dis as error "random slope variance for covhet() must be a positive number, unless intentially zero (random intercept model only or standard linear regression if intercept variance also =0)"
				exit 198
			}
			
	}	

		
*Check user-inputted covhet has implied correlation <=1 and >=-1
	 if "`chtype'"=="chinput"  {
	  tempname hcorr_mat
		local hcov12=el(`chm', 1,2)
		if `hcov12'!=0 {
			mat `hcorr_mat'=corr(`chm')
			local hcorr_slopeint= el(`hcorr_mat', 1, 2)
			if `hcorr_slopeint' >1 {
				dis as error "correlation of treatment group-specific random effects is greater than 1 - check values"
				exit 198
			}
			if `hcorr_slopeint' <-1 {
				dis as error "correlation of treatment group-specific random effects is less than -1 - check values"
				exit 198
			}
		}	
		else local hcorr_slopeint=0
	 }
	
 

	
		if  "`chtype'"=="chauto"  { // version for if using mixed model in memory
				local rewc: word count `=e(redim)'
				local vtwc: word count `=e(vartypes)'
				
				forvalues re=1/`rewc' {
					local re`re' : word `re' of `=e(redim)'
					local vt`re' : word `re' of `e(vartypes)'
				}
			if `rewc'!=2 {
				di as error "heteroschedastic covariance model fitted incorrectly, see {help mixedpower}"
				exit 198
			}
			if `re2'==2  {
			capture local hslvar=(exp(_b[lns1_2_1:_cons]))^2 
				if _rc!=0 {
					local hslvar=0
				}
			capture local hintvar=(exp(_b[lns1_2_2:_cons]))^2 
				if _rc!=0 {
					local hintvar=0
				}			
			capture local hcorr_slopeint=tanh(_b[atr1_2_1_2:_cons]) // correlation of random effects 
				if _rc!=0 {
					local hcorr_slopeint=0
				}			
			capture local hcov12=`hcorr_slopeint'*sqrt(`hintvar')*sqrt(`hslvar')
				if _rc!=0 {
					local hcov12=0
				}
			}	
			if "`vt2'"=="Identity" & `re2'==1 {
					if strmatch("`=e(revars)'", "* 1.*#*") {
						local hintvar=0 
						local hslvar=(exp(_b[lns1_2_1:_cons]))^2
					}
					else {
						local hintvar=(exp(_b[lns1_2_1:_cons]))^2
						local hslvar=0 
					}
					local  hcov12=0 
				}
			
	}
		
	
	if "`marginal'"==""	{
	** Rescale the (CONTROL or ALL) variance terms that need rescaling (random intercept variance doesn't) - scale==1 if unspecified i.e no rescaling
		
			if `slvar'!=0 local var_slope=(`scale'*(sqrt(`slvar')))^2 // var. random slopes - rescaled if necessary 	
			else local var_slope=`slvar'
			local  var_int=`intvar' // Variance of random intercepts - no rescaling required
			if `var_int'!=0 & `var_slope'!=0 local cov_slopeint=`corr_slopeint'*sqrt(`var_int')*sqrt(`var_slope')  // 
			else local cov_slopeint=0
			
			** and put together...
			
			local covmat `var_int' `cov_slopeint' `cov_slopeint' `var_slope' // rescaled (if required) covariance matrix in numlist form
			
		** Rescale the (TREATMENT) variance terms that need rescaling (random intercept variance doesn't) - scale==1 if unspecified i.e no rescaling
		if "`covhet'"!="" { 
			if `hslvar'!=0 local hvar_slope=(`scale'*(sqrt(`hslvar')))^2 // var. random slopes - rescaled if necessary 	
			else local hvar_slope=`hslvar'
			local  hvar_int=`hintvar' // Variance of random intercepts - no rescaling required
			if `hvar_int'!=0 & `hvar_slope'!=0 local hcov_slopeint=`hcorr_slopeint'*sqrt(`hvar_int')*sqrt(`hvar_slope')  // 
			else local hcov_slopeint=0
			** and put together...
			
			local hcovmat `hvar_int' `hcov_slopeint' `hcov_slopeint' `hvar_slope' // rescaled (if required) covariance matrix in numlist form
		}
		if "`covhet'"=="" { 
			local hcovmat `covmat'
		}
	}

**# SIMPLE ERROR MATRIX INPUT 
	
	***** Error matrix *****
	
	tempname rescov
	mat `rescov'=J(`sched_length',`sched_length',0) 
	
	
** Error variances check - independent errors, no marginal modelling

* user-inputted version					
	if "`errorvar'"!="" { // version for if numbers entered directly
		capture confirm number `errorvar'
				if _rc!=0 {
					dis as error "error variance must be a number greater than 0"
					exit 198
				}
		if `errorvar' <-1 {
			dis as error "error variance must be a number greater than 0"
			exit 198
		}	
		local var_res=`errorvar'
		if "`errxt'"=="" local resid independent
	}					

	* 'auto' auto-version	
	if "`auto'"!="" & "`errxt'"=="" { // version for if using mixed model in memory
		local var_res=(exp(_b[lnsig_e:_cons]))^2
		local resid independent
	}
	
	* fill 'rescov' with IID errors
	if ("`auto'"!="" & "`errxt'"=="") | "`errorvar'"!="" {
		forvalues i=1/`sched_length' { 
		mat `rescov'[`i',`i'] =`var_res'
		}
	}
	
**# XT ERROR MATRIX INPUT
	
** XT errors inputting - replace  `rescov' error matrix with xt errors from errxt() option - lots of code to follow...
	if "`errxt'"!="" {
		mat `rescov'=J(`sched_length',`sched_length',0) // override any IID error matrix from errorvar()
		
			if "`resid'"=="ar" {  // autoregressive
				if "`restype'"=="resinput" {
					local arn=`arn2length'-1
					forvalues d=1/`arn2length' {
						local param`d' : word `d' of `arn2'
					}
					 
				}
				if `arn'==1 { //AR(1)
					if "`restype'"=="resauto" local rho1=tanh(_b[r_atr1:_cons])
					if "`restype'"=="resauto" local sige=exp(_b[ lnsig_e:_cons])^2
					if "`restype'"=="resinput" local rho1=`param2'
					if "`restype'"=="resinput" local sige=`param1'
					forvalues i=1/`sched_length' {
						forvalues j=1/`sched_length' {
							local rc`i'`j'=`sige'*`rho1'^`=abs(`i'-`j')'
							mat `rescov'[`i',`j'] =`rc`i'`j''
						}
					}
				}			
				if `arn'==2  { // AR(2)
					if "`restype'"=="resauto" local sige=exp(_b[ lnsig_e:_cons])^2
					if "`restype'"== "resauto" local phi1=_b[r_phi1_1:_cons]
					if "`restype'"== "resauto" local phi2=_b[r_phi1_2:_cons]
					if "`restype'"=="resinput" local phi1=`param2'
					if "`restype'"=="resinput" local phi2=`param3'
					if "`restype'"=="resinput" local sige=`param1'
					*local psi=(1+`phi2')((1-`phi2')^2-`phi1'^2)
					forvalues i=1/`sched_length' {
						local d=`i'-1
						if `d'==0 local rc`d'=`sige'
						if `d'==1 local rc`d'=`phi1'/(1-`phi2')*`sige'
						if `d'>=2 local rc`d'=`phi1'*`rc`=`d'-1''+`phi2'*`rc`=`d'-2''
					}	
					forvalues i=1/`sched_length' {	
						forvalues j=1/`sched_length' {
							local diff=abs(`i'-`j')
							forvalues dd=0/`=`sched_length'-1' {
								if `diff'==`dd' {
									local rc`i'`j'=`rc`dd''
								}	
							}								
							mat `rescov'[`i',`j'] =`rc`i'`j''
						}		
					}	
				}	
		}
		
			
	
		
			if "`resid'"=="ma" { // moving average
				if "`restype'"=="resinput" {
					local man=`man2length'-1
					forvalues d=1/`man2length' {
						local param`d' : word `d' of `man2'
					}
				}	
				if `man'==1 { // MA(1)
					if "`restype'"=="resauto" local theta1=tanh(_b[r_att1:_cons])
					if "`restype'"=="resauto" local sige=exp(_b[ lnsig_e:_cons])^2
					if "`restype'"=="resinput" local theta1=`param2'
					if "`restype'"=="resinput" local sige=`param1'
					forvalues i=1/`sched_length' {
						forvalues j=1/`sched_length' {
							if `i'==`j' {
								local rc`i'`j'=`sige'
								mat `rescov'[`i',`j'] =`rc`i'`j''
							} 
							if abs(`i'-`j')==1  {
								local rc`i'`j'=`sige'*`theta1'/(1+`theta1'^2)
								mat `rescov'[`i',`j'] =`rc`i'`j''
							} 										
						}
					}
				}			
				if `man'==2  { // MA(2)
					if "`restype'"=="resauto" local sige=exp(_b[ lnsig_e:_cons])^2
					if "`restype'"=="resauto" local theta1=_b[r_theta1_1:_cons]
					if "`restype'"=="resauto" local theta2=_b[r_theta1_2:_cons]
					if "`restype'"=="resinput" local theta1=`param2'
					if "`restype'"=="resinput" local theta2=`param3'
					if "`restype'"=="resinput" local sige=`param1'
					local sigv=(`sige')/(1+`theta1'^2+`theta2'^2)
					forvalues i=1/`sched_length' {	
						forvalues j=1/`sched_length' {
							if `i'==`j' {
								local rc`i'`j'=`sige'
								mat `rescov'[`i',`j'] =`rc`i'`j''
							} 
							if abs(`i'-`j')==1  {
								local rc`i'`j'=(`theta1'+`theta1'*`theta2')*`sigv'
								mat `rescov'[`i',`j'] =`rc`i'`j''
							}	
							if abs(`i'-`j')==2  {
								local rc`i'`j'=(`theta2')*`sigv'
								mat `rescov'[`i',`j'] =`rc`i'`j''	
							} 
						}		
					}	
				}	
			}	
		
		
		

			if "`resid'"=="banded" { //banded - no input version, use unstructured
				forvalues i=1/`sched_length' {
					if `i'==1 {
						if "`restype'"=="resauto" local sige1=exp(_b[lnsig_e:_cons])^2
					}
					else {
						if "`restype'"=="resauto" local sige`i'= exp(_b[lnsig_e:_cons]+_b[r_lns1_`i'ose:_cons])^2
					}
					local rc`i'`i'=`sige`i''
					mat `rescov'[`i',`i'] =`rc`i'`i''
				}
				forvalues i=1/`sched_length' {
						forvalues j=`=`i'+1'/`sched_length' {
							if abs(`i'-`j')<=`ban' & `i'!=`j' {
								if "`restype'"=="resauto" local rc`i'`j'=tanh(_b[r_atr1_`i'_`j':_cons])*`sige`i''^0.5*`sige`j''^0.5
								mat `rescov'[`i',`j'] =`rc`i'`j''
								mat `rescov'[`j',`i'] =`rc`i'`j''
							}
						}
				}
			}	
		
	
		

			if "`resid'"=="toeplitz" {  // toeplitz
				if "`restype'"=="resinput" {
					local ton=`ton2length'-1
					forvalues d=1/`ton2length' {
						local param`d' : word `d' of `ton2'
					}
				}	
				if "`restype'"=="resauto" local sige1=exp(_b[lnsig_e:_cons])^2
				if "`restype'"=="resinput" local sige1=`param1'
				forvalues i=1/`sched_length' {
					local rc`i'`i'=`sige1'
					mat `rescov'[`i',`i'] =`rc`i'`i''
				}
				forvalues i=1/`sched_length' {
						forvalues j=`=`i'+1'/`sched_length' {
							local diff= abs(`i'-`j')
							if `diff'<=`ton' {
								if "`restype'"=="resauto" local rc`i'`j'=tanh(_b[r_atr1_`diff':_cons])*`sige1'^0.5*`sige1'^0.5
								if "`restype'"=="resinput" local rc`i'`j'=`param`=`diff'+1''*`sige1'^0.5*`sige1'^0.5
								mat `rescov'[`i',`j'] =`rc`i'`j''
								mat `rescov'[`j',`i'] =`rc`i'`j''
							}
						}
				}
			}	
		
			
				

			if "`resid'"=="unstructured" { // unstructured
				if "`restype'"=="resinput"  {
					mat `rescov'=`resid_mat'
							}
				if "`restype'"=="resauto"  {			
					forvalues i=1/`sched_length' {
						if `i'==1 {
							 local sige1=exp(_b[lnsig_e:_cons])^2
						} 
						else {
							 local sige`i'= exp(_b[lnsig_e:_cons]+_b[r_lns1_`i'ose:_cons])^2
						}
						local rc`i'`i'=`sige`i''
						mat `rescov'[`i',`i'] =`rc`i'`i''
					}
					forvalues i=1/`sched_length' {
							forvalues j=`=`i'+1'/`sched_length' {
								local rc`i'`j'=tanh(_b[r_atr1_`i'_`j':_cons])*`sige`i''^0.5*`sige`j''^0.5
								mat `rescov'[`i',`j'] =`rc`i'`j''
								mat `rescov'[`j',`i'] =`rc`i'`j''
								
							}
					}
				}
			}	
		
	
		

			if "`resid'"=="exponential" { // exponential
				if "`restype'"=="resinput" {
					forvalues d=1/`exn2length' {
						local param`d' : word `d' of `exn2'
					}
				}	
				if "`restype'"=="resauto" local rho1=invlogit(_b[r_logitr1:_cons])
				if "`restype'"=="resauto" local sige=exp(_b[ lnsig_e:_cons])^2
				if "`restype'"=="resinput" local rho1=`param2'
				if "`restype'"=="resinput" local sige=`param1'
				forvalues i=1/`sched_length' {
					local it: word `i' of `schedule'
					forvalues j=1/`sched_length' {
						local jt: word `j' of `schedule'
						local rc`i'`j'=`sige'*`rho1'^`=abs(`it'-`jt')'
						mat `rescov'[`i',`j'] =`rc`i'`j''
					}
				}
			}		
		
	
			if "`resid'"=="exchangeable" { // exchangeable
				if "`restype'"=="resinput" {
					forvalues d=1/`ecn2length' {
						local param`d' : word `d' of `ecn2'
					}
				}	
				if "`restype'"=="resauto" local sige1=exp(_b[lnsig_e:_cons])^2
				if "`restype'"=="resinput" local sige1=`param1'
				forvalues i=1/`sched_length' {
					local rc`i'`i'=`sige1'
					mat `rescov'[`i',`i'] =`rc`i'`i''
				}
				forvalues i=1/`sched_length' {
						forvalues j=`=`i'+1'/`sched_length' {
								if "`restype'"=="resauto" local rc`i'`j'=tanh(_b[r_atr1:_cons])*`sige1'^0.5*`sige1'^0.5
								if "`restype'"=="resinput" local rc`i'`j'=`param2'*`sige1'^0.5*`sige1'^0.5
								mat `rescov'[`i',`j'] =`rc`i'`j''
								mat `rescov'[`j',`i'] =`rc`i'`j''
						}
				}
			}	
			
		

			if "`resid'"=="independent" {  // independent - IID as well as heterogeneous ID for input version
				if "`restype'"=="resinput" {
					forvalues d=1/`sched_length' {
						if `inn2length'==1 local param`d' : word 1 of `inn2'
						if `inn2length'>1 local param`d' : word `d' of `inn2'
						mat `rescov'[`d',`d'] =`param`d''
					}
				}	
				if "`restype'"=="resauto"  {
					forvalues i=1/`sched_length' {
						if `inn'==1 {
							 local rc`i'`i'=exp(_b[lnsig_e:_cons])^2
						}
						if `inn'==`sched_length' {
							 if `i'==1 local rc`i'`i'=exp(_b[lnsig_e:_cons])^2 
							
							else {
								local rc`i'`i'= exp(_b[lnsig_e:_cons]+_b[r_lns`i'ose:_cons])^2
							}	
						}
						mat `rescov'[`i',`i'] =`rc`i'`i''
					}
					local inn2length=`inn'  // for use in syntax code output
				}	
			}	
	}	
	*mat errxtcov=`rescov'
	*mat li errxtcov			
	
	
**# HET ERROR MATRIX INPUT
		
		
	tempname reshcov
	mat `reshcov'=`rescov'
	
	if "`errhet'"!="" {
		 
		mat `reshcov'=J(`sched_length',`sched_length',0)

		if "`hresid'"=="ar" {  // autoregressive
			if "`hrestype'"=="resinput" {
				local harn=`harn2length'-1
				forvalues d=1/`harn2length' {
					local param`d' : word `d' of `harn2'
				}
			}			
			if `harn'==1 { //AR(1)
				if "`hrestype'"=="resauto" local rho1=tanh(_b[r_atr2:_cons])
				if "`hrestype'"=="resauto" local sige=exp(_b[ lnsig_e:_cons]+ _b[r_lns2ose:_cons])^2
				if "`hrestype'"=="resinput" local rho1=`param2'
				if "`hrestype'"=="resinput" local sige=`param1'
				forvalues i=1/`sched_length' {
					forvalues j=1/`sched_length' {
						local rc`i'`j'=`sige'*`rho1'^`=abs(`i'-`j')'
						mat `reshcov'[`i',`j'] =`rc`i'`j''
					}
				}
			}	
			
			if `harn'==2  { // AR(2)
					if "`hrestype'"=="resauto" local sige=exp(_b[ lnsig_e:_cons]+_b[r_lns2ose:_cons])^2
					if "`hrestype'"== "resauto" local phi1=_b[r_phi2_1:_cons]
					if "`hrestype'"== "resauto" local phi2=_b[r_phi2_2:_cons]
					if "`hrestype'"=="resinput" local phi1=`param2'
					if "`hrestype'"=="resinput" local phi2=`param3'
					if "`hrestype'"=="resinput" local sige=`param1'
				*local psi=(1+`phi2')((1-`phi2')^2-`phi1'^2)
				forvalues i=1/`sched_length' {
					local d=`i'-1
					if `d'==0 local rc`d'=`sige'
					if `d'==1 local rc`d'=`phi1'/(1-`phi2')*`sige'
					if `d'>=2 local rc`d'=`phi1'*`rc`=`d'-1''+`phi2'*`rc`=`d'-2''
				}	
				forvalues i=1/`sched_length' {	
					forvalues j=1/`sched_length' {
						local diff=abs(`i'-`j')
						forvalues dd=0/`=`sched_length'-1' {
							if `diff'==`dd' {
								local rc`i'`j'=`rc`dd''
							}	
						}								
						mat `reshcov'[`i',`j'] =`rc`i'`j''
					}		
				}	
			}	
	}
	
		

	
		if "`hresid'"=="ma" { // moving average
			if "`hrestype'"=="resinput" {
				local hman=`hman2length'-1
				forvalues d=1/`hman2length' {
					local param`d' : word `d' of `hman2'
				}
			}	
			if `hman'==1 { // MA(1)
				if "`hrestype'"=="resauto" local theta1=tanh(_b[r_att2:_cons])
				if "`hrestype'"=="resauto" local sige=exp(_b[ lnsig_e:_cons]+_b[r_lns2ose:_cons])^2
				if "`hrestype'"=="resinput" local theta1=`param2'
				if "`hrestype'"=="resinput" local sige=`param1'
				forvalues i=1/`sched_length' {
					forvalues j=1/`sched_length' {
						if `i'==`j' {
							local rc`i'`j'=`sige'
							mat `reshcov'[`i',`j'] =`rc`i'`j''
						} 
						if abs(`i'-`j')==1  {
							local rc`i'`j'=`sige'*`theta1'/(1+`theta1'^2)
							mat `reshcov'[`i',`j'] =`rc`i'`j''
						} 										
					}
				}
			}			
			if `hman'==2  { // MA(2)
					if "`hrestype'"=="resauto" local sige=exp(_b[ lnsig_e:_cons]+_b[r_lns2ose:_cons])^2
					if "`hrestype'"=="resauto" local theta1=_b[r_theta2_1:_cons]
					if "`hrestype'"=="resauto" local theta2=_b[r_theta2_2:_cons]
					if "`hrestype'"=="resinput" local theta1=`param2'
					if "`hrestype'"=="resinput" local theta2=`param3'
					if "`hrestype'"=="resinput" local sige=`param1'
				local sigv=(`sige')/(1+`theta1'^2+`theta2'^2)
				forvalues i=1/`sched_length' {	
					forvalues j=1/`sched_length' {
						if `i'==`j' {
							local rc`i'`j'=`sige'
							mat `reshcov'[`i',`j'] =`rc`i'`j''
						} 
						if abs(`i'-`j')==1  {
							local rc`i'`j'=(`theta1'+`theta1'*`theta2')*`sigv'
							mat `reshcov'[`i',`j'] =`rc`i'`j''
						}	
						if abs(`i'-`j')==2  {
							local rc`i'`j'=(`theta2')*`sigv'
							mat `reshcov'[`i',`j'] =`rc`i'`j''	
						} 
					}		
				}	
			}	
		}	
	
		if "`hresid'"=="banded" { //banded - no input version, use unstructured
				forvalues i=1/`sched_length' {
					if `i'==1 {
						if "`hrestype'"=="resauto" local sige1=exp(_b[lnsig_e:_cons]+_b[r_lns2_1ose:_cons])^2
					}
					else {
						if "`hrestype'"=="resauto" local sige`i'= exp(_b[lnsig_e:_cons]+_b[r_lns2_`i'ose:_cons])^2
					}
					local rc`i'`i'=`sige`i''
					mat `reshcov'[`i',`i'] =`rc`i'`i''
				}
				forvalues i=1/`sched_length' {
						forvalues j=`=`i'+1'/`sched_length' {
							if abs(`i'-`j')<=`hban' & `i'!=`j' {
								if "`hrestype'"=="resauto" local rc`i'`j'=tanh(_b[r_atr2_`i'_`j':_cons])*`sige`i''^0.5*`sige`j''^0.5
								mat `reshcov'[`i',`j'] =`rc`i'`j''
								mat `reshcov'[`j',`i'] =`rc`i'`j''
							}
						}
				}
			}
		
		if "`hresid'"=="toeplitz" {  // toeplitz
			if "`hrestype'"=="resinput" {
				local hton=`hton2length'-1
				forvalues d=1/`hton2length' {
					local param`d' : word `d' of `hton2'
				}
			}
			if "`hrestype'"=="resauto" local sige1=exp(_b[lnsig_e:_cons]+_b[r_lns2ose:_cons])^2
			if "`hrestype'"=="resinput" local sige1=`param1'
			forvalues i=1/`sched_length' {
				local rc`i'`i'=`sige1'
				mat `reshcov'[`i',`i'] =`rc`i'`i''
			}
			forvalues i=1/`sched_length' {
					forvalues j=`=`i'+1'/`sched_length' {
						local diff= abs(`i'-`j')
						if `diff'<=`hton' {
							if "`hrestype'"=="resauto" local rc`i'`j'=tanh(_b[r_atr2_`diff':_cons])*`sige1'^0.5*`sige1'^0.5
							if "`hrestype'"=="resinput" local rc`i'`j'=`param`=`diff'+1''*`sige1'^0.5*`sige1'^0.5
							mat `reshcov'[`i',`j'] =`rc`i'`j''
							mat `reshcov'[`j',`i'] =`rc`i'`j''
						}
					}
			}
		}	
	
		
		if "`hresid'"=="unstructured" { // unstructured
					if "`hrestype'"=="resinput"  {
					mat `reshcov'=`hresid_mat'
							}
				if "`hrestype'"=="resauto"  {			
					forvalues i=1/`sched_length' {
						if `i'==1 {
							 local sige1=exp(_b[lnsig_e:_cons]+_b[r_lns2_1ose:_cons])^2
						} 
						else {
							 local sige`i'= exp(_b[lnsig_e:_cons]+_b[r_lns2_`i'ose:_cons])^2
						}
						local rc`i'`i'=`sige`i''
						mat `reshcov'[`i',`i'] =`rc`i'`i''
					}
					forvalues i=1/`sched_length' {
							forvalues j=`=`i'+1'/`sched_length' {
								local rc`i'`j'=tanh(_b[r_atr2_`i'_`j':_cons])*`sige`i''^0.5*`sige`j''^0.5
								mat `reshcov'[`i',`j'] =`rc`i'`j''
								mat `reshcov'[`j',`i'] =`rc`i'`j''
								
							}
					}
				}		
		}	
	
		if "`hresid'"=="exponential" { // exponential
			if "`hrestype'"=="resinput" {
				forvalues d=1/`hexn2length' {
					local param`d' : word `d' of `hexn2'
				}
			}
			if "`hrestype'"=="resauto" local rho1=invlogit(_b[r_logitr2:_cons])
			if "`hrestype'"=="resauto" local sige=exp(_b[ lnsig_e:_cons]+_b[r_lns2ose:_cons])^2
			if "`hrestype'"=="resinput" local rho1=`param2'
			if "`hrestype'"=="resinput" local sige=`param1'
			forvalues i=1/`sched_length' {
				local it: word `i' of `schedule'
				forvalues j=1/`sched_length' {
					local jt: word `j' of `schedule'
					local rc`i'`j'=`sige'*`rho1'^`=abs(`it'-`jt')'
					mat `reshcov'[`i',`j'] =`rc`i'`j''
				}
			}
		}		
	
		if "`hresid'"=="exchangeable" { // exchangeable
			if "`hrestype'"=="resinput" {
				forvalues d=1/`hecn2length' {
					local param`d' : word `d' of `hecn2'
				}
			}	
			if "`hrestype'"=="resauto" local sige1=exp(_b[lnsig_e:_cons]+_b[r_lns2ose:_cons])^2
			if "`hrestype'"=="resinput" local sige1=`param1'
			forvalues i=1/`sched_length' {
				local rc`i'`i'=`sige1'
				mat `reshcov'[`i',`i'] =`rc`i'`i''
			}
			forvalues i=1/`sched_length' {
					forvalues j=`=`i'+1'/`sched_length' {
							if "`hrestype'"=="resauto" local rc`i'`j'=tanh(_b[r_atr2:_cons])*`sige1'^0.5*`sige1'^0.5
							if "`hrestype'"=="resinput" local rc`i'`j'=`param2'*`sige1'^0.5*`sige1'^0.5
							mat `reshcov'[`i',`j'] =`rc`i'`j''
							mat `reshcov'[`j',`i'] =`rc`i'`j''
					}
			}
		}	
		

		if "`hresid'"=="independent" {  // independent - IID as well as heterogeneous ID for input version
			if "`hrestype'"=="resinput" {
				forvalues d=1/`sched_length' {
				
					if `hinn2length'==1 local param`d' : word 1 of `hinn2'
					if `hinn2length'>1 local param`d' : word `d' of `hinn2'
					mat `reshcov'[`d',`d'] =`param`d''
				}
			}
				if "`hrestype'"=="resauto"  {
					forvalues i=1/`sched_length' {
						if `hinn'==1 {
							 local rc`i'`i'=exp(_b[lnsig_e:_cons]+_b[r_lns2ose:_cons])^2
						}
						if `hinn'==`sched_length' {
							 if `i'==1 local rc`i'`i'=exp(_b[lnsig_e:_cons]+_b[r_lns2ose:_cons])^2 
							
							else {
								local rc`i'`i'= exp(_b[lnsig_e:_cons]+_b[r_lns`i'ose:_cons])^2
							}	
						}
						mat `reshcov'[`i',`i'] =`rc`i'`i''
					}
					local hinn2length=`hinn'  // for use in syntax code output
				}
		}	
		
	}
	
	if "`errhet'"=="" local hresid `resid'
	
 *mat li `reshcov'	
		
**# RESCALING
local scale1=1	
					
** Rescale contslope - changes with scale, so an x% effect means something different (i.e rescale TTE)

	if "`contslope'"!="" {					
		if `ns_num'==1 { // version if slope specified as number
			local diff1=`contslope'*`effectiveness'
		}
		if `ns_num'==0 { // version if slope value taken from mixed model slope (`beta')
			local diff1=`beta'*`effectiveness'
		}
		local difference=-1*(`diff1')
	}	
	
	

** Rescale Slope Difference parameter - only matters if trtspec=slope because it's an interaction parameter
	local trdiff `trtspec'
	if "`actualtrt'"!="" local trdiff `actualtrt'  // change to actualtrt spec.

	tempname tte cvalues
	mat `tte'=J(1,`altvarX',0)
	if "`cbeta'"!="" {
		mat `cvalues'=J(1,`actcontlength',0)
		forvalues cb=1/`actcontlength' {
			local cbeta`cb': word `cb' of `cbeta'
			mat `cvalues'[1,`cb']=`cbeta`cb''
		}
		*mat li `cvalues'
	}
	
	if "`trdiff'"=="slope" mat `tte'[1,1]=`diff1'*`scale1' // note scale1 is kept=1, not using scaling here now
	
	if "`trdiff'"=="intercept" mat `tte'[1,1]=`diff1'
	
	if "`trdiff'"=="lateslope" mat `tte'[1,1]=`diff1'*`scale1'
	
	if "`trdiff'"=="user" mat `tte'[1,1]=`diff1'*`scale1'
	
	if "`trdiff'"=="slint" {
		mat `tte'[1,1]=`diff1'
		mat `tte'[1,2]=`diff2'*`scale1'
	} 
	
	if "`trdiff'"=="2slope" {
		mat `tte'[1,1]=`diff1'*`scale1'
		mat `tte'[1,2]=`diff2'*`scale1'
	}
	
	if "`trdiff'"=="user2" {
		mat `tte'[1,1]=`diff1'*`scale1'
		mat `tte'[1,2]=`diff2'*`scale1'
	}
	
	if  "`trdiff'"=="factor0" | "`trdiff'"=="factor"   { 
		forvalues tst=1/`altvarX' {
			mat `tte'[1,`tst']=`diff`tst''
		}
	}
	
**# HEADER
	
	
	if "`noheader'"=="" {
		
		di _n "{it:mixedpower}" as text " - power and sample size calculator for linear mixed models (version 1.0): author M.Burnell"
		di as text "MRC Centre of Research Excellence in Clinical Trial Innovation, UCL, London WC1V 6LJ, UK" _n		
	}		

		
********** MODEL SYNTAX OUTPUT SECTION *****************************************
**# SYNTAX
	if "`nosyntax'"=="" {
		 di  "{hline}"
		* ctype 
		 if "`altcont'"=="factor" local ct1 i.
		 if "`altcont'"=="noint" | "`altcont'"=="slint" | "`altcont'"=="2slope" local ct1 c.
		if "`altcont'"=="factor" | "`altcont'"=="noint" | "`altcont'"=="slint" | "`altcont'"=="2slope" {
			local ct2 time
		}
		if "`altcont'"=="user" local cus1 f(t)_c1({it:time})
		if "`altcont'"=="user2" local cus2 f(t)_c1({it:time}) f(t)_c2({it:time})
		
		* ttype 
		 if "`trtspec'"=="factor" | "`trtspec'"=="factor0" {
			local tt1 i.
			local tt2 time
			local tt3 #1.
			local tt4 trt		
		 } 
		 if "`trtspec'"=="slope" | "`trtspec'"=="slint" | "`trtspec'"=="lateslope" | "`trtspec'"=="2slope" {
			local tt1 c.
			local tt2 time
			local tt3 #1.
			local tt4 trt
		 }
		 * tint
		 if "`trtspec'"=="slint" | "`trtspec'"=="intercept" local tint i.trt
		 * ls
		 if "`trtspec'"=="lateslope"  local ls _LS
		  * 2s
		  if "`altcont'"=="2slope"  local cts1 _2S_1
		 if "`altcont'"=="2slope"  local cts2a c.
		 if "`altcont'"=="2slope"  local cts2b time_2S_2

		 if "`trtspec'"=="2slope"  local ts1 _2S_1
		 if "`trtspec'"=="2slope"  local ts2a c.
		 if "`trtspec'"=="2slope"  local ts2b time_2S_2
		 if "`trtspec'"=="2slope"  local ts2c #1.
		 if "`trtspec'"=="2slope"  local ts2d trt
		 if "`trtspec'"=="user" local tus1 f_1({it:time})#1.trt
		 if "`trtspec'"=="user2" local tus2 f_1({it:time})#1.trt f_2({it:time})#1.trt
		 * nocons
		 if "`altcont'"=="noint" local nocons , nocons
		 * factortr
		 if "`trtspec'"=="factor" & "`altcont'"=="noint" local factortr  constraints(1)
		 if "`trtspec'"=="factor" & "`altcont'"!="noint" local factortr , constraints(1)
		 if "`marginal'"=="" {
			 * retime
			 if `var_slope'>0 local retime " {it:time}"
			 * cov
			 if `cov_slopeint'!=0 local cov " cov(unstr)"
			 if `cov_slopeint'==0 local cov " cov(independent)"
			 if `var_slope'==0 & `cov_slopeint'==0 local cov ""
			 * marg
			 if `var_int'==0 local marg nocons
			 local comma ","
		 }

		 * marg 
		 if "`marginal'"!="" local marg nocons
		 if "`marginal'"!="" local comma ","
		 * restype/resnum/torby
		 local restype independent
		 local torby t
		  if "`errxt'"!="" {
			local restype `resid'
			if "`resid'"=="ar" local resnum `arn'
			if "`resid'"=="ma" local resnum `man'
			if "`resid'"=="banded" local resnum `ban'
			if "`resid'"=="toeplitz" local resnum `ton'
			if "`resid'"=="independent" {
				if `inn2length'==1 local torby t
				if `inn2length'>1 local torby by
			} 
			else local torby t
		  }
		 * errxt
		 if "`errhet'"!="" local ext " by({it:trt})"
		 * covhet
		 if "`covhet'"!="" {
			if `intvar'!=0 local ch0int "0.{it:trt}"
			if `slvar'!=0 local ch0sl " c.{it:time}#0.{it:trt}"
			if `cov12'!=0 local ch0cov " cov(unstr)"
			if `slvar'!=0 & `cov12'==0 local ch0cov " cov(ind)"
			local retime " `ch0sl' `ch0int',`ch0cov' nocons"
			local cov
			if `hintvar'!=0 local ch1int "1.{it:trt}"
			if `hslvar'!=0 local ch1sl " c.{it:time}#1.{it:trt}"
			if `hcov12'!=0 local ch1cov "cov(unstr)"
			if `hslvar'!=0 & `hcov12'==0 local ch1cov " cov(ind)"
			local hretime "|| {it:id_level2}: `ch1sl' `ch1int', `ch1cov' nocons"
			local comma
		 }
		 
		di as text "Mixed model syntax:"
		if "`trtspec'"=="factor" {
			di as result "constraint 1 _b[0.{it:time}#1.{it:trt}]=0 "
		}
		di  as res "mixed{it: depvar} `ct1'{it:`ct2'}{it:`cts1'} `cts2a'{it:`cts2b'}`cus1'`cus2' {it:`tint'} `tt1'{it:`tt2'}{it:`ls'}{it:`ts1'}`tt3'{it:`tt4'} `ts2a'{it:`ts2b'}`ts2c'{it:`ts2d'}`tus1'`tus2' `nocons' `factortr' || {it:id_level2}:`retime' `hretime'`comma'`cov' `marg' resid(`restype' `resnum', `torby'({it:time})`ext') "	
		if "`resid'"!="`hresid'" & "`hresid'"!="" {
			di as error "note that error structure {it:type} for treatment group - errhet() - is different to {it:type} for control group - errxt() - which is not possible to specify with the mixed command"
		}
	}
	
	
	

***** MATRIX SECTIONS **********************************************************
**# MATRIX/FRAME SETTING UP

* do we need to consider weighting of different schedule cohorts i.e. create multiple frames?
	
	if "`strecruitment'"=="" & "`dropouts'"=="" { 
		local mframes=1  // either going to make just one frame - no pwgt cohorts
	}
	else {
		local mframes=`sched_length'  // ... or multiple frames (not necessarily sched_length amount, if any cwgts==0)
	}

	
* create new frame(s) with matrix contents and calculate variance of treatment effects 

	
	
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
**# 2-LEVEL - X matrix and identifier variables plus intitial frame(s) set up		
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
				**# 2level X matrix
				
			local k=`n' // number of visits from schedule to use for this (nth) frame	
			if `cohorts'==0 {
				local k=`sched_length' // no dropout/strec then will use all visits
			}
			local trwt1: word 1 of `allratio'
			local trwt2: word 2 of `allratio'
			local obsn=`sched_length'*(`trwt1'+`trwt2')
			
			set obs `=`obsn'+100'

			gen trt_cohort=.
			gen obs=.
			gen double time=.
			gen treat=.
			if "`actualtrt'"!="" & "`actualcont'"=="" local copyC yes
			if "`actualtrt'"=="" & "`actualcont'"!="" local copyT yes

			if "`altcont'"=="factor" local contvar=`sched_length'  // changed from `k', so creating X variables for all timepoints even if not reached by cohort (column of zeros), for purpose of matrix calculation of overall B_variance
			if "`actualcont'"=="factor"	local Acontvar=`sched_length'
			
			if "`altcont'"=="noint" 	local contvar=1
			if "`actualcont'"=="noint" 	local Acontvar=1
			
			if "`altcont'"=="noslope" 	local contvar=1
			if "`actualcont'"=="noslope" 	local Acontvar=1
			
			if "`altcont'"=="slint" 	local contvar=2
			if "`actualcont'"=="slint" 	local Acontvar=2
			
			if "`altcont'"=="2slope" 	local contvar=3
			if "`actualcont'"=="2slope" 	local Acontvar=3
			
			if "`altcont'"=="user" local contvar=2
			if "`actualcont'"=="user" local Acontvar=2

			if "`altcont'"=="user2" local contvar=3
			if "`actualcont'"=="user2" local Acontvar=3
			
			if "`trtspec'"=="factor0" local altvar=`sched_length' 
			if "`actualtrt'"=="factor0"  local Aaltvar=`sched_length' 
			
			
			if "`trtspec'"=="factor" local altvar=`sched_length'-1
			if "`actualtrt'"=="factor" local Aaltvar=`sched_length'-1
			
			
			if "`trtspec'"=="slope" local altvar=1
			if "`actualtrt'"=="slope" local Aaltvar=1
			
			
			if "`trtspec'"=="intercept" local altvar=1
			if "`actualtrt'"=="intercept" local Aaltvar=1
			
			
			if "`trtspec'"=="slint" local altvar=2
			if "`actualtrt'"=="slint" local Aaltvar=2
			
			
			if "`trtspec'"=="lateslope" local altvar=1
			if "`actualtrt'"=="lateslope" local Aaltvar=1
			
			
	 		if "`trtspec'"=="2slope" local altvar=2 
			if "`actualtrt'"=="2slope" local Aaltvar=2
			
			if "`trtspec'"=="user" local altvar=1
			if "`actualtrt'"=="user" local Aaltvar=1

			if "`trtspec'"=="user2" local altvar=2
			if "`actualtrt'"=="user2" local Aaltvar=2
			
			if "`copyC'"=="yes" local Acontvar=`contvar' // copy the C X vars into AX if required
			if "`copyT'"=="yes" local Aaltvar=`altvar' // copy the T X vars into AX
			
			local vlim=`contvar'+`altvar'
			forvalues v=1/`vlim' {
					gen double X`v'=0
				}
				
			if "`actualtrt'"!="" | "`actualcont'"!="" {
				local avlim=`Acontvar'+`Aaltvar'
				forvalues av=1/`avlim' {
						gen double AX`av'=0
						
					}
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
					forvalues j=1/`k'	{ // loop over visits upto `n' for that cohort for X values (for Xi+1 to Xsched_length will be left as zeros)  
					
						local t : word `j' of `schedule'
						if "`trtspec'"=="user" | "`trtspec'"=="user2" local tu1 : word `j' of `txfun_1'
						if "`trtspec'"=="user2" local tu2 : word `j' of `txfun_2'
						if "`actualtrt'"=="user" | "`actualtrt'"=="user2" local atu1 : word `j' of `atxfun_1'
						if "`actualtrt'"=="user2" local atu2 : word `j' of `atxfun_2'
						if "`altcont'"=="user" | "`altcont'"=="user2" local cu1 : word `j' of `cxfun_1'
						if "`altcont'"=="user2" local cu2 : word `j' of `cxfun_2'
						if "`actualcont'"=="user" | "`actualcont'"=="user2" local acu1 : word `j' of `acxfun_1'
						if "`actualcont'"=="user2"  local acu2 : word `j' of `acxfun_2'

						local in=`in'+1 
								
						if "`altcont'"=="factor" {
							qui replace X`j'=1 in `in'
						}
						if "`altcont'"=="noint" {
							qui replace X1=`t' in `in'
						}
						if "`altcont'"=="noslope" {
							qui replace X1=1 in `in'
						}
						if "`altcont'"=="slint" {
							qui replace X1=1 in `in'
							qui replace X2=`t' in `in'
						}
						if "`altcont'"=="2slope" {
							qui replace X1=1 in `in'
							qui replace X2=cond((`t'-`Ctslt')<0,`t',`Ctslt') in `in'
							qui replace X3=`t' in `in'
						}
						if "`altcont'"=="user" {
							qui replace X1=1 in `in'
							qui replace X2=`cu1' in `in'
						}
						if "`altcont'"=="user2" {
							qui replace X1=1 in `in'
							qui replace X2=`cu1' in `in'
							qui replace X3=`cu2' in `in'
						}
						if "`trtspec'"=="factor0" {
							local x=`contvar'+`j'
								*local xin=(`trt_coh'-1)*`k'+ `j' 
							qui replace X`x'=1*`g' in `in' 
						}
						if "`trtspec'"=="factor" {
							local x=`contvar'+`j'-1
								*local xin=(`trt_coh'-1)*`k'+ `j'
							if `j'>1 {
							qui replace X`x'=1*`g' in `in'
							}
						}
						if "`trtspec'"=="slope" {
							local x=`contvar'+1
							qui replace X`x'=`t'*`g' in `in'
						}
						if "`trtspec'"=="intercept" {
							local x=`contvar'+1
							qui replace X`x'=1*`g' in `in'
						}
						if "`trtspec'"=="slint" {
							local x=`contvar'+1
							local xx=`contvar'+2
							qui replace X`x'=1*`g' in `in'
							qui replace X`xx'=`t'*`g' in `in'
							  
						}
						if "`trtspec'"=="lateslope" {
							local x=`contvar'+1
							qui replace X`x'=cond((`t'-`lslt')>0,(`t'-`lslt'),0)*`g' in `in'
						}
						if "`trtspec'"=="2slope" {
							local x=`contvar'+1
							local xx=`contvar'+2
							qui replace X`x'=cond((`t'-`tslt')<0,`t',`tslt')*`g' in `in'
							qui replace X`xx'=`t'*`g' in `in'
						}
						if "`trtspec'"=="user" {
							*noi di "`contvar' `tu1'"
							local x=`contvar'+1
							qui replace X`x'=`tu1'*`g' in `in'
						}
						if "`trtspec'"=="user2" {
							local x=`contvar'+1
							local xx=`contvar'+2
							qui replace X`x'=`tu1'*`g' in `in'
							qui replace X`xx'=`tu2'*`g' in `in'
						}
**# AX MATRIX
						*ACTUAL X creations
						if  "`actualcont'"!=""  {
							if "`actualcont'"=="factor" {
								qui replace AX`j'=1 in `in'
							}
							if "`actualcont'"=="noint" {
								qui replace AX1=`t' in `in'
							}
							if "`actualcont'"=="noslope" {
								qui replace AX1=1 in `in'
							}
							if "`actualcont'"=="slint" {
								qui replace AX1=1 in `in'
								qui replace AX2=`t' in `in'
							}
							if "`actualcont'"=="2slope" {
								qui replace AX1=1 in `in'
								qui replace AX2=cond((`t'-`aCtslt')<0,`t',`aCtslt') in `in'
								qui replace AX3=`t' in `in'
							}
							if "`actualcont'"=="user" {
								qui replace AX1=1 in `in'
								qui replace AX2=`acu1' in `in'
							}
							if "`actualcont'"=="user2" {
								qui replace AX1=1 in `in'
								qui replace AX2=`acu1' in `in'
								qui replace AX3=`acu2' in `in'
							}
						}
						if "`copyC'"=="yes" {
							foreach var of varlist X1-X`=`contvar'' {
								qui replace A`var'=`var'
							}
						}
						if  "`actualtrt'"!="" {
							if "`actualtrt'"=="factor0" {
								local ax=`Acontvar'+`j'
								qui replace AX`ax'=1*`g' in `in' 
							}
							if "`actualtrt'"=="factor" {
								local ax=`Acontvar'+`j'-1
								if `j'>1 {
								qui replace AX`ax'=1*`g' in `in'
								}
							}
							if "`actualtrt'"=="slope" {
								local ax=`Acontvar'+1
								qui replace AX`ax'=`t'*`g' in `in'
							}
							if "`actualtrt'"=="intercept" {
								local ax=`Acontvar'+1
								qui replace AX`ax'=1*`g' in `in'
							}
							if "`actualtrt'"=="slint" {
								local ax=`Acontvar'+1
								local axx=`Acontvar'+2
								qui replace AX`ax'=1*`g' in `in'
								qui replace AX`axx'=`t'*`g' in `in'
							}
							if "`actualtrt'"=="lateslope" {
								local ax=`Acontvar'+1
								qui replace AX`ax'=cond((`t'-`alslt')>0,(`t'-`alslt'),0)*`g' in `in'
							}
							if "`actualtrt'"=="2slope" {
								local ax=`Acontvar'+1
								local axx=`Acontvar'+2
								qui replace AX`ax'=cond((`t'-`atslt')<0,`t',`atslt')*`g' in `in'
								qui replace AX`axx'=`t'*`g' in `in'
							}
							if "`actualtrt'"=="user" {
								local ax=`Acontvar'+1
								qui replace AX`ax'=`atu1'*`g' in `in'
							}
							if "`actualtrt'"=="user2" {
								local ax=`Acontvar'+1
								local axx=`Acontvar'+2
								qui replace AX`ax'=`atu1'*`g' in `in'
								qui replace AX`axx'=`atu2'*`g' in `in'
							}
						}

						if "`copyT'"=="yes" {
							local aa=0
							foreach var of varlist X`=`contvar'+1'-X`=`contvar'+`altvar'' {
								
								local aa=`aa'+1
								local varA X`=`Acontvar'+`aa''
								qui replace A`varA'=`var'
							}
						}
						qui replace trt_cohort=`trt_coh' in `in'
						qui replace obs=`j' in `in'
						qui replace time=`t' in `in'
						qui replace treat=`trt' in `in'
					}	
				}	
			}	
			

			local in=`in'+1
			foreach var of varlist trt_cohort obs time treat  X1-X`vlim'    {
					qui replace `var'=. in `in'/l
				}
			if "`actualtrt'"!="" |  "`actualcont'"!="" {	
				foreach avar of varlist trt_cohort obs time treat  AX1-AX`avlim'    {
						qui replace `avar'=. in `in'/l
					}
			}	
			qui tostring treat, gen(trt_str)
			qui tostring trt_cohort, gen(ar_str)
			qui tostring obs, gen(vis_str)
			qui gen str15 rownames="t"+trt_str+"_"+"v"+vis_str
			qui replace rownames="" if treat==.
			qui replace trt_str="" if treat==.
			qui replace ar_str="" if treat==.
			qui replace vis_str="" if treat==.
			
			tempname X	Xm AX AXm Xmod
			mkmat X1-X`vlim', matrix(`X') nomissing rownames(rownames)
			if "`actualtrt'"!="" |  "`actualcont'"!="" mkmat AX1-AX`avlim', matrix(`AX') nomissing rownames(rownames)
			
			if "`xmat'"!="" {
				if `xmat'==`n' & `cohorts'==1 {
					mat `Xmod'=`X'					
					mat `Xm'=`X'
					return matrix xmat=`Xm'
					if "`actualtrt'"!="" |  "`actualcont'"!="" {
						mat `AXm'=`AX'
						return matrix actual_xmat=`AXm'
					}
				}
				if `cohorts'==0 {
					mat `Xmod'=`X'
					mat `Xm'=`X'				
					return matrix xmat=`Xm'
					if "`actualtrt'"!="" |  "`actualcont'"!="" {
						mat `AXm'=`AX'
						return matrix actual_xmat=`AXm'
					}
				}	
			}	
			
			
			
		**# 2level R matrix
			local arat=0
			local in=0
			local inxt=0
			
			forvalues g=0/1 { // loop over treatment
				local arat=`arat'+1
				local trwt: word `arat' of `allratio'
				forvalues ab=1/`trwt' { // loop over treatment#cohort weights
					forvalues r=1/`k'	{	// loop over visits upto `n'
								
						local in=`in'+1
						qui gen double R`in'=0
						if `r'==1 {
							local inxt=`in'
						}						
						forvalues c=1/`k' {
							local inr=`inxt'+`r'-1
							local inc=`inxt'+`c'-1
							if `g'==0 {
								qui replace R`inr'=`rescov'[`r',`c'] in `inc'
							}
							if `g'==1 {
								qui replace R`inr'=`reshcov'[`r',`c'] in `inc'
							}
							
						}
					
					}
				}
			}

			local inl=`in'+1
			foreach var of varlist R1-R`in' {
				qui replace `var'=. in `inl'/l
			}
			
			tempname R Rm
			mkmat R1-R`in', matrix(`R') nomissing rownames(rownames)
			
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
			
			
	if "`marginal'"=="" {	
		**# 2level Z matrix

			local in=0
			local nct=0
			local arat=0

			forvalues g=0/1 {
				
				local arat=`arat'+1
				local trwt: word `arat' of `allratio'
				forvalues ab=1/`trwt' {
							
					local nct=`nct'+1			
					local z1=(`nct'-1)*2+1
					local z2=(`nct'-1)*2+2

					gen double Z`z1'=0
					gen double Z`z2'=0

					forvalues j=1/`k'{
						local t : word `j' of `schedule'
						local in=`in'+1
										
						qui replace Z`z1'=1 in `in'  // creating Z design matrix in pairs - this one for random intercept
						qui replace Z`z2'=`t' in `in' // this one for random slope

											
					}
				}
			}
				
			local inl=`in'+1
			foreach var of varlist Z1-Z`z2' {
				qui replace `var'=. in `inl'/l
			}
			tempname Z Zm
			mkmat Z1-Z`z2', matrix(`Z') nomissing rownames(rownames)
			
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

		**# 2level G matrix
			
			local arat=0
			local in=0
			forvalues g=0/1 {
			
				local arat=`arat'+1
				local trwt: word `arat' of `allratio'
				forvalues ab=1/`trwt' {
													
					local in=`in'+1
					local g1=1+(`in'-1)*2  // for entering the cov parameters in pairs per row
					local g2=2+(`in'-1)*2

					qui gen double G`g1'=0
					qui gen double G`g2'=0
							
					local cell=0
					local rmax=2 // cov matrix is 2x2 - will be larger for multivariate version
					local cmax=2
					
					forvalues r=1/`rmax' {
						forvalues c=1/`cmax' {
							local cell=`cell'+1
							local value: word `cell' of `covmat'
							local hvalue: word `cell' of `hcovmat'
							local in`r'`c'=(`g1')+(`r'-1)
							local gc=`g1'+(`c'-1)					
							if `g'==0 qui replace G`gc'=`value' in `in`r'`c''
							if `g'==1 qui replace G`gc'=`hvalue' in `in`r'`c''
						}
					}
			
				}
			}


			local inl=`g2'+1
			foreach var of varlist G1-G`g2' {
				qui replace `var'=. in `inl'/l
			}
			tempname G Gm
			mkmat G1-G`g2', matrix(`G') nomissing	
		
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
		
		
	}
		

**# MATRIX ALGEBRA
	
			tempname sigma sigma0 B_var invsigma Abeta AY AYM EYM Mbeta MbetaT tteM sigma sigmaC sigmaT
			if "`marginal'"!="" {
				mat `sigma'=`R'
				mat `sigma0'=`sigma'
			}
			else {
				mat `sigma'=`R'+`Z'*`G'*`Z''  // note transpose ' - not an excess quote symbol!
				mat `sigma0'=`sigma'
			}

**# REWEIGHTING
			*** ARATIO plus pweights section ***
			if "`alloratio'"=="" {
			
				if `pwgt0_`n''>0 mat `sigmaC'=(1/`ar1')*(1/`pwgt0_`n'')*`sigma'[1..rowsof(`sigma'),1..`k']
				if `pwgt0_`n''==0 mat `sigmaC'=(1/`ar1')*(0)*`sigma'[1..rowsof(`sigma'),1..`k']				

				if `pwgt1_`n''>0 mat `sigmaT'=(1/`ar2')*(1/`pwgt1_`n'')*`sigma'[1..rowsof(`sigma'),`=1+`k''..`=2*`k'']		
				if `pwgt1_`n''==0 mat `sigmaT'=(1/`ar2')*(0)*`sigma'[1..rowsof(`sigma'),`=1+`k''..`=2*`k'']
				mat coljoin `sigma'=`sigmaC' `sigmaT'
				
			}
			
			*mat li `sigma'
			
			**********************
**# ACTUAL Matrix stuff
			** Calculate var(B) and if actualtrt/cont used, calculate model betas
			mat `invsigma'=invsym(`sigma')
			mat `B_var'=invsym(`X''*invsym(`sigma')*`X') // note transpose ' - not an excess quote symbol!
			if  "`actualtrt'"!="" | "`actualcont'"!="" {
			
				mat `Abeta'=J(1,`=`Acontvar'+`Aaltvar'',0) // actual beta vector
				if "`cbeta'"!="" {    // zeros for C unless cbeta and actualcont used
					forvalues ab=1/`Acontvar'{
						mat `Abeta'[1,`ab']=`cvalues'[1,`ab']
					}
				}
				if "`actualtrt'"!="" {  // add actual T betas
					forvalues ab=1/`Aaltvar'{
						mat `Abeta'[1,`=`Acontvar'+`ab'']=`tte'[1,`ab']
					}
				}
				if "`actualtrt'"=="" { // actual T betas will be same as model if only actualcont used
					forvalues ab=1/`Aaltvar'{
						mat `Abeta'[1,`=`Acontvar'+`ab'']=`tte'[1,`ab']
					}
				}
				*mat abs= `Abeta'
				*mat axi= `AX'
				mat `AY'=`AX'*`Abeta''  // actual Ys given actual B and actual X design
				mat `Mbeta'=`B_var'*`X''*`invsigma'*`AY' // model betas (for both C and T)
				mat `MbetaT'=`Mbeta'' 
				mat `tteM'= `MbetaT'[1,`=`contvar'+1'..`=`contvar'+`altvar''] // vector of just the T betas
				*mat AYs= `AY'
				*mat mbs= `Mbeta'
				*mat li `tteM'
				*mat li axi
				*mat li AYs
				*mat li mbs
			}
			 
			
			if `cohorts'==1 { // name Var(B) invsigma model betas and a diagonal version of Var(B) for each cohort
					tempname B_var`n' sigma`n' invsigma`n'    MbetaT`n' bvarD`n'
					mat `B_var`n''=`B_var'
					mat `sigma`n''=`sigma0'
					if  "`actualtrt'"!="" | "`actualcont'"!="" {
						mat `bvarD`n''=diag(vecdiag(`B_var`n''))
						mat `MbetaT`n''=`Mbeta''
						
					}											
			}
			
			tempname bvarin sigmain corrin iccn sigvec zgzvec  // return Var(B) for specified cohort
**# MATRIX RETURNS

			if "`marginal'"=="" & "`resid'"=="independent" & "`hresid'"=="independent" local icc yes  // if ICC to be reported
			if "`bvarn'"!=""  {
					if `cohorts'==1 & `bvarn'==`n' {
						mat `sigmain'=`sigma`n''
						mat `corrin'=corr(`sigma`n'')
						mat `bvarin'=`B_var`n''
						if "`icc'"=="yes" {
							mat `sigvec'=vecdiag(`sigma`n'')
							mat `zgzvec'=vecdiag(`sigma`n'')-vecdiag(`R')
							mata: st_matrix("`iccn'", st_matrix("`zgzvec'") :/ st_matrix("`sigvec'"))
							return matrix cond_icc_n=`iccn'
						} 
						return matrix bvar_n=`bvarin'
						return matrix sigma_n=`sigmain'
						return matrix wcorr_n=`corrin'
					}
					if `cohorts'==0 & `bvarn'==`sched_length' {
						mat `corrin'=corr(`sigma0')
						mat `sigmain'=`sigma0'
						mat `bvarin'=`B_var'
						if "`icc'"=="yes" {						
							mat `sigvec'=vecdiag(`sigma0')
							mat `zgzvec'=vecdiag(`sigma0')-vecdiag(`R')
							mata: st_matrix("`iccn'", st_matrix("`zgzvec'") :/ st_matrix("`sigvec'"))
							return matrix cond_icc_n=`iccn'
						}	
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
		else  // for the schedule points who don't have associated unique cohorts
		
	}	// end of mframes loop
	
	
**# OVERALL BVAR CALCULATIONS
			***** Perform  overall-calculation of X-covariance if needed *****
	if `cohorts'==1 {
		tempname B_var  // the overall X-covariance matrix
		tempname wgtsum Mbetawgt bvarD
		mat `wgtsum'=J(`vlim',`vlim',0) 
		foreach n of numlist `frlist' {
		
			*mat `wgtsum'=`wgtsum'+`pwgts_`n''*invsym(`B_var`n'')
			mat `wgtsum'=`wgtsum'+invsym(`B_var`n'')  
			
		}
		
		mat `B_var'=invsym(`wgtsum')
		
		
		if "`actualtrt'"!="" | "`actualcont'"!="" {  // calc model betas for each cohort and combine weighted by ICW or IVW
			mat `Mbetawgt'=J(1,`vlim',0)
			mat `bvarD'=diag(vecdiag(`B_var'))
			foreach n of numlist `frlist' {

				if "`ivw'"!="" mat `Mbetawgt'=`Mbetawgt'+`MbetaT`n''*invsym(`bvarD`n'')*`bvarD' 
				if "`ivw'"=="" mat `Mbetawgt'=`Mbetawgt'+`MbetaT`n''*invsym(`B_var`n'')*`B_var' 

			}
			
			mat `tteM'= `Mbetawgt'[1,`=`contvar'+1'..`=`contvar'+`altvar''] 
	
		}

		
	}
	
**# EFFECT SIZE RETURNS
	tempname bvar effsz tb tba mbw ab
	mat `bvar'=`B_var'	
	return mat beta_var=`bvar'
	
	mat `effsz'=J(1,1,0)
	if "`actualtrt'"=="" & "`actualcont'"=="" mat `tteM'=`tte'
	if "`actualtrt'"=="" & "`actualcont'"=="" {
		if "`xmat'"!="" {
			mat `Abeta'=J(1,`=`contvar'+`altvar'',0) 
			forvalues ab=1/`altvar'{
						mat `Abeta'[1,`=`contvar'+`ab'']=`tte'[1,`ab']
					}
			mat `AYM'=`Xmod'*`Abeta''
			return mat exp_y_true=`AYM'
		}
	} 
	
	mat `tb'=`tte'
	mat `tba'=`tteM'
	
	if  "`actualtrt'"!="" | "`actualcont'"!="" {
		mat `AYM'=`AY'
		
		mat `ab'=`Abeta'
		return mat betas_true=`ab'
		if `cohorts'==1 {
			mat `mbw'=`Mbetawgt'
			return mat betas_model=`mbw'
			return mat exp_y_true=`AYM'
			if "`xmat'"!="" {
				mat `EYM'=`Xmod'*`Mbetawgt''
				return mat exp_y_model=`EYM'
			}
			
		} 
		else {
			mat `mbw'=`MbetaT'
			return mat betas_model=`mbw'
			return mat exp_y_true=`AYM'
			if "`xmat'"!="" {
				mat `EYM'=`Xmod'*`MbetaT''
				return mat exp_y_model=`EYM'
			}
			
		}
	}
	
	return mat trtbeta_true=`tb'
	return mat trtbeta_model=`tba'
	
		
		if "`trtspec'"=="slope" | "`trtspec'"=="intercept" | "`trtspec'"=="lateslope" | "`trtspec'"=="user" {
			if "`test'"=="paired"  { // secret power option ("paired") for doing a paired z-test - just using the cont intercept variance
				local trtpos=`contvar'
				local b_var=`B_var'[`trtpos',`trtpos']
				mat `effsz'=`tteM'/sqrt(`b_var')
			}
			else {
				local trtpos=`contvar'+1
				local b_var=`B_var'[`trtpos',`trtpos']  
				if `b_var'!=0 mat `effsz'=`tteM'/sqrt(`b_var')
				mat `effsz'=`tteM'/sqrt(`b_var')
			}
			local trteff=`tteM'[1,1]
		}
		
		
**# LC TEST
		if "`trtspec'"=="slint" | "`trtspec'"=="2slope" | "`trtspec'"=="factor" | "`trtspec'"=="factor0" | "`trtspec'"=="user2" {
		
			
			 if strmatch("`test'","joint(*)")==0 {
	
				tempname testlc lincom  bvartr varlc
				mat `testlc'=J(1,`altvar',0)
				forvalues tst=1/`altvar' {
					local testlc`tst': word `tst' of `test'
					mat `testlc'[1,`tst']=`testlc`tst''
				}
				
				mat `lincom'=J(1,1,0)
				mat `lincom'=`testlc'*`tteM''

				mat `bvartr'=`B_var'[`=`contvar'+1'..`=`contvar'+`altvar'',`=`contvar'+1'..`=`contvar'+`altvar'']
				mat `varlc'=`testlc'*`bvartr'*`testlc''
				mat `effsz'=`lincom'*invsym(cholesky(`varlc'))
				local b_var=`varlc'[1,1]
				local trteff=`lincom'[1,1]
				return mat test_lc=`testlc'
			}
			
			
			local effsize=`effsz'[1,1]
			
**# JOINT TEST
		 if strmatch("`test'","joint(*)")==1 { // joint test chi2  statistic calculation
				tempname b_jt R_jt Rtrt W_jt	testjt wchi2 dfjt
				mat `b_jt'=J(`=`contvar'+`altvar'',1, 0) // create bx1 matrix of joint test difference values - included the control variables but have them always zero, so don't have to recreate variance matrix
				
				mat `R_jt'=J(`=`contvar'+`altvar'',`=`contvar'+`altvar'',0)
				forvalues jt=1/`altvar' {
					local testjt`jt': word `jt' of `joint'
					mat `b_jt'[`=`contvar'+`jt'',1]=`tteM'[1,`jt']
					mat `R_jt'[`=`contvar'+`jt'',`=`contvar'+`jt'']=`testjt`jt''
					
				}
			mat `W_jt'=(`R_jt'*`b_jt')'*invsym(`R_jt'*`B_var'*`R_jt'')*(`R_jt'*`b_jt')	
			mat `Rtrt'=vecdiag(`R_jt'[`=`contvar'+1'..`=`contvar'+`altvar'',`=`contvar'+1'..`=`contvar'+`altvar''])
			return mat test_jt=`Rtrt'
			scalar `wchi2'=`W_jt'[1,1]
			return scalar w_chi2=`wchi2'
			scalar `dfjt'=`df_jt'
			return scalar df_jt=`dfjt'
			}		
		
		} // end factor, factor0, slint, 2lsope loop
	
	 * just for non-test versions
			
			local effsize=`effsz'[1,1]
			
		*mat bmodel=(r(beta_var))*r(xmat)'*(invsym(r(rmat)+r(zmat)*r(gmat)*r(zmat)'))*r(actual_y)	// if want to check model beta
	
	****************************************************************************
**# MAIN RESULTS
	*** CALCULATE THE MAIN RESULT: Either sample size or power
	* first for z tests with effect size then if chi2 joint test, no effsize
	qui tempname  sampfactor alpha_tail sampsize sampsize_C sampsize_T power z_power frac_ss frac_power

	
	if strmatch("`test'","joint(*)")==0 {
	
	
		if "`power_or_n'"=="power" { // Calc SAMPLE SIZE
			scalar `alpha_tail' = 1 - (0.5 * `alpha')
			scalar `sampfactor' = ( invnormal(`alpha_tail') + invnormal(`given_power'))^2
			scalar `sampsize' = 2*ceil( `sampfactor' / (`effsize')^2)*(`arsum'/2)
			scalar `frac_ss' = 2*(`sampfactor' / (`effsize')^2)*(`arsum'/2)
			/*
			if  "`aratio'"!="" {
				scalar `sampsize' = `arsum'*ceil( (`arfactor'*2)*(`sampfactor' / ((`effsize')^2)/`arsum')) 
				scalar `frac_ss' = 2*( (`arfactor')*(`sampfactor' / (`effsize')^2)) 
			}*/
			scalar `sampsize_C' =  ceil(`sampsize'*(`ar1'/`arsum'))
			scalar `sampsize_T' =  ceil(`sampsize'*(`ar2'/`arsum'))
			scalar `frac_power' = `given_power' // Transferring the local into the scalar...
			scalar `power' =normal(( abs(`effsize')*sqrt(`sampsize'/`arsum') ) - invnormal(1-`alpha'/2)) 
		}

		else { // Calc POWER
			// Calc the power here
			scalar `sampsize' = `actual_n' // As specified by the user; transferring to output scalar
			scalar `frac_ss' = `given_n'
			scalar `sampsize_C' = `actual_n'*(`ar1'/`arsum')
			scalar `sampsize_T' = `actual_n'*(`ar2'/`arsum')
			scalar `z_power' = ( abs(`effsize')*sqrt(`actual_n'/`arsum') ) - invnormal(1-`alpha'/2) 
			scalar `frac_power' = normal(( abs(`effsize')*sqrt(`given_n'/`arsum') ) - invnormal(1-`alpha'/2)) 
			/*if  "`aratio'"!="" {
				scalar `z_power' = ( abs(`effsize')*sqrt(`actual_n'/(`arfactor'*2)) ) - invnormal(1-`alpha'/2)
				scalar `frac_power' = normal((abs(`effsize')*sqrt(`given_n'/(`arfactor'*2)) ) - invnormal(1-`alpha'/2))
			}*/
			scalar `power' = normal(`z_power')
		} // (((delta[`i']*`slope')*sqrt(`size')/`B_var1')-invnormal(1-`alpha'))	
	}
	
	if strmatch("`test'","joint(*)")==1 | "`twosided'"!="" {
		if "`twosided'"!="" & "`jttest'"=="" {
			tempname W_jt
			mat `W_jt'=J(1,1,0)
			local df_jt=1
			local w11=`effsz'[1,1]*`effsz'[1,1]
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
			if `power'==. scalar `power'=1
			scalar `frac_power'=1-nchi2(`df_jt',`W_jt'[1,1]*`given_n'/`arsum',`alpha_jt')
			if `frac_power'==. scalar `frac_power'=1
			scalar `sampsize' = `actual_n'
			scalar `frac_ss' = `given_n'
			scalar `sampsize_C' = `actual_n'*(`ar1'/`arsum')
			scalar `sampsize_T' = `actual_n'*(`ar2'/`arsum')
		}			
	}

**# DISPLAY
***** DISPLAY OUTPUT SECTION ****************
			
			local schedrd
			forvalues t=1/`sched_length' {
				local schrd_`t': word `t' of `schedule'
				if mod(`schrd_`t'',0.1)!=0 local schrd_`t': di %3.2f `schrd_`t''
				else if mod(`schrd_`t'',1)!=0 local schrd_`t': di %2.1f `schrd_`t''
				local schedrd "`schedrd' `schrd_`t''"
			}
			local diffrd 
			forvalues d=1/`difflength' {
				local diffrd_`d': word `d' of `difference'
				if mod(`diffrd_`d'',0.1)!=0 local diffrd_`d': di %3.2f `diffrd_`d''
				else if mod(`diffrd_`d'',1)!=0 local diffrd_`d': di %2.1f `diffrd_`d''
				local diffrd "`diffrd' `diffrd_`d''"
			}
			
			if "`actualtrt'"!="" local attext " {it:but with actual} {hi:`actualtrt'} {it:treatment effect}"
			local offset 25
			di  "{hline}"
			if "`power_or_n'"=="n" local calc_PorN power
			if "`power_or_n'"=="power" local calc_PorN sample size
			di _n as text "Calculating {hi:`calc_PorN'} for a {hi:2-level} mixed model with {hi:`trtspec'} treatment effect parameterisation`attext':"
			di _s(2) as text "visit schedule" _col(`=`offset'-2') "="  _col(`=`offset'-1') as res "`schedrd'"
			di _s(2) as text "treatment effect(s)" _col(`=`offset'-2') "="  _col(`=`offset'-1') as res "`diffrd'"
			di _s(2) as text "alpha`star'" _col(`=`offset'-2') "="  _col(`offset') as res %4.3f `alpha'
			di _s(2) as text "total sample size"  _col(`=`offset'-2') "="  _col(`offset') as res `sampsize'
			di _s(2) as text "n in control arm"  _col(`=`offset'-2') "="  _col(`offset') as res `sampsize_C'
			di _s(2) as text "n in treatment arm"  _col(`=`offset'-2') "="  _col(`offset') as res `sampsize_T'
			di _s(2) as text "power"  _col(`=`offset'-2') "="  _col(`offset') as res %5.4f  `power'

		
			if "`strecruitment'"!="" local table yes
			if "`dropouts'"!="" local table yes

	
**# TABLE DISPLAY
			*if "`table'"=="yes" { // run through it anyway to get matrices
				
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
						if mod(`h`i'',1)!=0 local hrd`i': di %-2.1f `h`i''
						if mod(`h`i'',1)==0 local hrd`i': di %-1.0f `h`i''
						local hd2i`i' "time=`hrd`i''"
						if `sched_length'>12 local hd2i`i' "t=`hrd`i''"
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
	
**# FINAL RETURNS
	** back to RETURNS 

	return matrix trtrd_num=`TmatrdN'
	return matrix contrd_num=`CmatrdN'
	return matrix trt_num=`TmatN'
	return matrix cont_num=`CmatN'
	return matrix sched_list=`schedmat'
	
	
	tempname  var_eff eff teff setrial


	if strmatch("`test'","joint(*)")==0 {
		scalar `setrial'=sqrt(`b_var'/(`sampsize'/`arsum'))
		return scalar se_trial=`setrial'
		scalar `var_eff'=`b_var'
		return scalar var_trteff=`var_eff'	
		scalar `teff'=`trteff'
		return scalar trt_eff=`teff'
		scalar `eff'=`effsize'
		return scalar effectsize=`eff'
	}
	
	return local final_wgts `"`pwgts'"' 
	return scalar power=`power'
	return scalar fractional_power=`frac_power'
	return scalar samplesize=`sampsize'
	return scalar fractional_ss=`frac_ss'
	return local schedule "`schedule'"
	return local cmd mixedpower
	return local cmdline `"mixedpower `0'"'
	
	
	frame change `cframe'
	

	
end	

			
**# OTHER PROGRAMS

capture program drop err198
	prog def err198
	di as error `"`0'"'
	exit 198
	end
	
capture program drop extabcheck
	program extabcheck, sclass 
		version 17.0
		
		syntax, [INDependent EXChangeable ar ma  UNstructured BAnded TOeplitz EXPonential]
		sreturn clear
		foreach ext in independent exchangeable ar ma unstructured banded toeplitz exponential {
			if "``ext''"!="" local newext `ext'			
		}
		sreturn local exttype `newext'
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
			dis as error  "jttest() or lctest() must be specified when trtspec() is '`tsp''"
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

capture program drop errxtmixcheck
program errxtmixcheck, sclass 
	version 17.0
	
	syntax,   residt(string) hety(string) hetcheck(string) 
		sreturn clear
	if "`hety'"=="yes" {
		if  strmatch("`hetcheck'","* by(*)*") {
			local ehet h
		}
		else {
			di as error "mixed model in memory not fitted with separate error structure by group"
				exit 198	
		}
	}
	
	if  strmatch("`residt'","AR(*)") {
		local restype ar
		local rshort ar
		local nsub= subinstr("`residt'", "AR(", "", 1)
		local nsub= subinstr("`nsub'", ")", "", 1)
		local num=`nsub'
	}
	else if  strmatch("`residt'","MA(*)") {
		local restype ma
		local rshort ma
		local nsub= subinstr("`residt'", "MA(", "", 1)
		local nsub= subinstr("`nsub'", ")", "", 1)
		local num=`nsub'
	}
	else if  strmatch("`residt'","Banded(*)") {
		local restype banded
		local rshort ba
		local nsub= subinstr("`residt'", "Banded(", "", 1)
		local nsub= subinstr("`nsub'", ")", "", 1)
		local num=`nsub'
	}
	else if  strmatch("`residt'","Toeplitz(*)") {
		local restype toeplitz
		local rshort to
		local nsub= subinstr("`residt'", "Toeplitz(", "", 1)
		local nsub= subinstr("`nsub'", ")", "", 1)
		local num=`nsub'
	}
	else if  strmatch("`residt'","Unstructured") {
		local restype unstructured
		local rshort un
		local num=0
	}
	else if  strmatch("`residt'","Exponential") {
		local restype exponential
		local rshort exp
		local num=0
	}
	else if  strmatch("`residt'","Exchangeable") {
		local restype exchangeable
		local rshort ex
		local num=0
	}
	else if  strmatch("`residt'","Independent") {
		local restype independent
		local rshort in
		local num=1
	}
	else {
		di as error "Residual error type not recognised"
		exit 198	
	}  
	sreturn local residt `restype'
	sreturn local rshort `rshort'
	sreturn local rnum `num'
	sreturn local het `ehet'
	

end	
	