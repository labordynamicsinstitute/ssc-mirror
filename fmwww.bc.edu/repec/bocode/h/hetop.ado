*! version 2.0 04jan2017, Benjamin R. Shear and sean f. reardon

 capture program drop hetop
 program define hetop , eclass
	
	version 13.1
	
	qui capture which oglm
	if _rc {
		di as error "error: oglm version 2.3.0 or newer is required to run hetop"
		error 499
	}
	
	syntax namelist , 			/// arg1 is the group id variable; arg2 is the stem for the category counts variable
		NUMCATS(integer)		/// technically redundant but a good check that there are the expected number of categories
		[ 											///
			MODTYPE(string) 						/// "hetop" or "homop"
			IDENTIFY(string)						/// "sums" or "refgroup"
			SETREF(integer 0) 						/// group to use as reference group, if identify == refgroup
			PHOP(varname numeric)					/// 0/1 indicator; constrain groups with `phop'==1 to have a common SD
			PKVALS(varname numeric max=1) 			/// name of variable containing group proportions in population; default is to use observed group proportions
			STARTFRom(namelist max=1)				/// matrix with desired starting values
			KAPPA(integer 1)					 	/// use a specified value of kappa in calculations
			SAVE(string)							/// if specified, save estimates as new variables in sheet as mstar_STRING mstar_STRING_se, etc. if STRING="star" then values will just be mstar, sstar, mstar_se, sstar_se
			ADDCONStraints(string)					/// use pre-defined constraints
			MINSIZE(integer 1)						/// drop groups smaller than this
			INITVALS 								/// compute initial values
			GAPS 									/// return matrix of gaps and SEs of gaps
			NOIsily		 							/// display -oglm- output during estimation
			HOMOP									/// easier way to specify a homop model
			*										/// ML options
		]
	
	preserve
	
	local grpid `1'
	local catname `2'
	
	mlopts mlopts , `options'
	
	
	// set default options:
	
	if "`modtype'" == "" {
		if "`homop'" == "homop"	local modtype "homop"
		if "`homop'" == ""		local modtype "hetop"
	}
	if "`modtype'" == "hetop" & "`homop'" == "homop" {
		noi di in red "WARNING: modtype(hetop) and homop options are not " ///
		"consistent. homop model will be fit."
		local modtype "homop"
	}
	if `setref' > 0 & "`identify'" == ""	local identify "refgroup"
	if "`identify'" == ""					local identify "sums"

	
	// evaluate and parse syntax
	
	* verify that id variable uniquely identifies groups
	cap bys `grpid' : assert _N==1
	if _rc != 0 {
		noi di in red 	"ID variable `grpid' does not uniquely "///
						"identify observations"
		error 499
	}
	
	* require that id variable integer > 0
	qui capture assert `grpid' == int(`grpid')
	qui sum `grpid'
	if r(min) < 1 | _rc != 0 {
		noi di in red "ID variable must be positive integer values only"
		error 499
	}
	
	* can't do HETOP with fewer than 3 categories
	if "`modtype'" == "hetop" & `numcats' < 3 {
		noi di in red "ERROR: must have > 2 categories to fit HETOP model."
		error 499
	}
	
	* confirm @star variables do not already exist
	qui if "`save'" != "" {
		local savename _`save'
		if "`save'" == "star" local savename ""
		local newvarnames 	mstar`savename'	sstar`savename' ///
							mstar`savename'_se sstar`savename'_se
		foreach v in `newvarnames' {
			cap confirm variable `v'
			if _rc == 0 {
				noi di in red "variable `v' exists but SAVE option " ///
					"specified. please rename `v' or alter save(name) option."
				error 499
			}
		}
	}
	
	* confirm identification
	if "`identify'" != "sums" & "`identify'" != "refgroup" {
		noi di in red "ERROR: identify() option must be 'sums' or 'refgroup'."
		error 499
	}
	
	* confirm modeltype selection
	if "`modtype'" != "hetop" & "`modtype'" != "homop" {
		noi di in red "ERROR: modtype() must be 'hetop' or 'homop'."
		error 499
	}
	
	* update noisily accordingly
	if "`noisilyoglm'" != "" local noisilyoglm "noisily"

	* confirm phopvar is only 0 and 1 and not specified with homop option
	if "`phop'" != "" & "`modtype'" == "homop" {
		noi di in red "WARNING: phop option with homop model is redundant. " ///
			"Ignoring phop variable."
		local phop ""
	}
	if "`phop'" != "" {
		qui count if (`phop'!=0 & `phop'!=1)
		if r(N) > 0 {
			noi di in red "ERROR: phop variable can only contain 0 or 1."
			error 499			
		}	
	}
	
	* can't specify STARTFROM and INITVALS
	if "`startfrom'" != "" {
		if "`initvals'" != "" {
			noi di in red "ERROR: cannot specify both startfrom() and initvals."
			error 499
		}
		cap confirm matrix `startfrom'
		if _rc != 0 {
			noi di in red "ERROR: `startfrom' must be a matrix."
			exit _rc
		}
	}
		
	
	
	// check and clean frequency count data
	
	* replace any missing frequencies with 0s
	qui foreach var of varlist `catname'* {
		qui count if `var' == .
		if r(N) > 0 noi di in yellow ///
			"NOTE: replaced " r(N) " missing frequencies in `var' with 0."
		replace `var' = 0 if `var' == .
	}
	
	* verify category name & number of category variables match
	unab vars : `catname'*
	local numcatsfound = `: word count `vars''
	if `numcatsfound' != `numcats' {
		noi di in red 	"ERROR: Number of categories found does not match " ///
						"number supplied to numcats."
		error 499
	}
	local numcuts = `numcats' - 1
	
	
	
	// restrict sample and issue warnings about existence
	
	* generate group total Ns
	tempvar Nk
	egen `Nk' = rowtotal(`catname'*)	
	
	* drop groups with no observations or that are below `minsize' 
	qui count if `Nk' < `minsize'	// `minsize'=1 by default
	if r(N) > 0 noi di in red _n "WARNING: dropping " r(N) ///
		" groups with N<`minsize'"
	qui drop if `Nk' < `minsize'
	
	* now check for categories with no observations across entire sample
	foreach var of varlist `catname'* {
		qui sum `var'
		if r(sum) <= 0 | r(sum) == . {
			noi di in red "ERROR: `var' contains no observations (possibly" ///
			" after removing groups below the minsize() threshold."		///
			" All categories must have at least 1 observation"	///
			" in the total sample."
			error 499
		}
	}	
	
	* issue warning about groups with data in 2 cells for HETOP
	* estimates still may be defined with PHOP option and pattern of counts
	tempvar num0
	egen `num0' = anycount(`catname'*) , val(0)
	qui count if `num0' == (`numcats'-2)
	if "`modtype'" == "hetop" & r(N) > 0 {
		noi di in red "WARNING: some groups have data in only 2 " ///
		"categories and ML estimates may not be properly defined."
	}
	
	* now issue warnings/errors for groups with data in only 1 category
	qui count if `num0' == (`numcats'-1)
	
	* error for 1-count groups with only 2 categories and HOMOP
	if "`modtype'" == "homop" & r(N) > 0 & `numcats' == 2 {
		noi di in red "ERROR: cannot fit HOMOP model when some groups have " ///
			"data in only 1 category and numcats=2. There are " r(N) ///
			" such groups."
		error 499
	}
	
	* warning for 1-count groups
	if r(N) > 0 {
		noi di in red "WARNING: some groups have data in only 1 " ///
		"category and ML estimates may not be properly defined."
	}
		
		
		
		// !! sample is now finalized !!
	
	
	
	// create additional variables and subset to analytic sample
	
	* sort by grpid, restrict variables
	sort `grpid'
	qui sum `grpid'
	local K = r(N)		// number of groups
	keep `grpid' `catname'* `pkvals' `Nk' `phop'
	sort `grpid'	
	
	* create pk values if none are supplied
	if "`pkvals'" == "" {
		tempvar pk
		qui sum `Nk'
		gen double `pk' = `Nk' / r(sum)
		local pkvals "`pk'"
		noi di in yellow "NOTE: no pk values specified; " ///
			"using nk/N as proportions."
	}

	* create matrices for use below in standard error calculations
	* sort based on group id
	sort `grpid'
	
	tempname P nk nkHI
	mkmat `pkvals' , matrix(`P')		// used for sums constraints below
	matrix `P' = `P''
	mkmat `Nk' , matrix(`nk')
	matrix `nk' = `nk''
	matrix `nkHI' = J(1 , `K' , 0)
	forv i = 1/`K' {
		matrix `nkHI'[1,`i'] = 1/`nk'[1,`i']
	}
	
	
	
	// set up identifying constraints
	
	if "`identify'" == "refgroup" {
		* check specified ref group or automatically generate one
		if `setref' == 0 {			
			noi di in yellow "NOTE: no reference group (or 0) specified; " ///
				"automatic group will be specified."
			qui get_ref , refrank(1) catname(`catname') grpid(`grpid') ///
							numcats(`numcats')
			local ref_group = r(refid)
		}

		else {
			qui count if `grpid' == `setref'
			if r(N) != 1 {
				noi di "specified reference group `setref' not found"
				error 499
			}
			local ref_group = `setref'
			noi di in yellow "NOTE: user specified `setref' as reference group."
		}
	}
	else if "`identify'" == "sums" {
		local ref_group "n"
		noi di in yellow "NOTE: using constraint on sum of estimates " ///
			"to identify model."
		
		qui levelsof `grpid' , local(grpconstraints)

		local w1 `: word 1 of `grpconstraints''
		local mnconstraints "`=`P'[1,1]' * [y]:`w1'.`grpid'"
		local sdconstraints "`=`P'[1,1]' * [lnsigma]:`w1'.`grpid'"
		
		forv i = 2/`K' {
			
			local w1 `: word `i' of `grpconstraints''
			local mnconstraints "`mnconstraints' + `=`P'[1,`i']' * [y]:`w1'.`grpid'"
			local sdconstraints "`sdconstraints' + `=`P'[1,`i']' * [lnsigma]:`w1'.`grpid'"
		
		}

		local mnconstraints "`mnconstraints' = 0"
		local sdconstraints "`sdconstraints' = 0"

		constraint free
		local pmc = r(free)
		constraint `pmc' `mnconstraints'
		
		if "`modtype'" == "hetop" {
			constraint free
			local smc = r(free)
			constraint `smc' `sdconstraints'
		}
		
		local sumconstraints "`pmc' `smc'"
	}
	***
	
	* add phop constraints if phop indicator supplied
	
	if "`phop'" != "" & "`modtype'" == "hetop" {
		
		qui count if `phop' == 1
		if r(N) == _N {
			noi di in red "Constant `phop' means this is a HOMOP model " ///
				"and should be respecified."
			constraint drop `sumconstraints' `phopconstraints'
			error 499			
		}
		qui count if `phop' == 0
		if r(N) == _N {
			noi di in red "WARNING: `phop'=0 for all observations. Model is " ///
				"equivalent to HETOP and will ignore `phop'."
			local phop ""
		}
		
		if "`phop'" != "" {
			
			qui levelsof `grpid' if `phop' == 1 , local(grpconstraints)
			qui count if `phop' == 1
			local numconstraints = r(N) - 1
			local grpconstraints "`grpconstraints'"
			
			forv i = 1/`numconstraints' {
				
				local w1 `: word `i' of `grpconstraints''
				local w2 `: word `=`i'+1' of `grpconstraints''
				capture constraint free
				
					if _rc != 0 {
						noi di in red "ERROR: attempting to set too many " ///
							"constraints with the phop command. " ///
							"May need to use an alternative model."
						error _rc
						exit
					}
				
				local smc = r(free)
				constraint `smc' [lnsigma]:`w1'.`grpid' = [lnsigma]:`w2'.`grpid'
				local phopconstraints "`phopconstraints' `smc'"
				
			}				
		}		
	}
	*****
	
	
	
	// announce model and options being fit
	
	if "`modtype'" == "hetop" {
		
		if "`phop'" != "" noi di in yellow "NOTE: fitting heteroskedastic " ///
			"ordered probit model with constraints in `phop'."
		
		if "`phop'" == "" noi di in yellow "NOTE: fitting heteroskedastic " ///
			"ordered probit model."
		
		local scale_equation "hetero(ib`ref_group'.`grpid')"
	
	}
	
	else if "`modtype'" == "homop" {
		
		noi di in yellow "NOTE: fitting homoskedastic ordered probit model."
		local scale_equation ""
	
	}
			
	noi di in yellow "NOTE: user specified --`grpid'-- as group id variable."
	noi di in yellow "NOTE: user specified --`catname'*-- as category variables."
	noi di in yellow "NOTE: user specified `numcats' categories."
	if "`initvals'" != "" {
		noi di in yellow "NOTE: custom starting values will be used."
	}

	
	
	// reshape to long in prep for oglm
	
	qui reshape long `catname', i(`grpid') j(y)	
	sort y

	* replace any missing frequencies with 0
	* should be redundant
	qui count if `catname' == .
	if r(N) != 0 {
		local rplc = r(N)
		qui replace `catname' = 0 if `catname' == .
		noi di in yellow "NOTE: replaced `rplc' missing frequencies as 0."
	}
	
	
	
	// run oglm 
	
	sort `grpid' y

	ereturn clear
	
	noi di in yellow "running oglm ... "
		
	* set initial values with initvals
	if "`initvals'" != "" {
		cap noi get_initial_values , grpid(`grpid') refgroup(`ref_group') ///
			catname(`catname') numgrps(`K') modtype(`modtype') ///
			numcuts(`numcuts')
		
		if _rc==0 {
			tempname initvalsmat
			mat `initvalsmat' = r(initvalsmat)
			local startvalcall "startvals(`initvalsmat')"
		}
		else {
			noi di in red "WARNING: problem with initial value calculations." ///
				" Using default starting values."
			local initvals ""
			local startvalcall ""
		}
		
	}
	
	* set up starting values call with user-input matrix
	if "`startfrom'" != "" {
		noi di in yellow "NOTE: starting from initial values in matrix `startfrom'."
		local startvalcall "startvals(`startfrom')"
	}
	
	local allconstraints `sumconstraints' `phopconstraints' `addconstraints'
	if "`allconstraints'" != "" {
		local allconstraints "constraints(`allconstraints')"
	}

	cap `noisily' oglm y ib`ref_group'.`grpid' ///
		[fweight = `catname'] , ///
		`scale_equation' `startvalcall' `allconstraints' `mlopts' ///
		collinear link(probit) 
		
	********************
	
	
	
	// process and return results
	
	if _rc != 0 {
	
		* return with an error message
		noi di in red "WARNING: oglm error code _rc = " _rc
		constraint drop `sumconstraints' `phopconstraints'
		error 499
		
	}
	
	else if _rc == 0 {

		noi di in yellow "...oglm done."
	
		if e(converged) == 0 noi di in red "WARNING: model failed to converge."

		qui reshape wide `catname', i(`grpid') j(y) 
		sort `grpid'
		
		** attempt the SE calculations and dereferencing
		
		* create matrices and variables
		tempvar ninv1 ninv
		
		tempname Vfull Bfull P2 One PI n ntilde Q a ///
			Mprime Gprime Sprime Cprime ///
			Mprime_se Sprime_se Gprime_se Cprime_se ///
			Vprime Omegaprime Lambdaprime Wprime Zprime ///
			sigmaw sigmab sigmaprime ///
			Mstar Sstar Mstar_se Sstar_se Cstar Cstar_se ///
			icchatratio icchat R T varsigprime Vstar Wstar Zstar icchatvar ///
			S G Gvar1 ///
			Bprime Aprime Dprime Rc Bstar
			
		matrix `Vfull' = e(V)
		matrix `Bfull' = e(b)'
		
		matrix `P2' = hadamard(`P', `P')
		matrix `One' = J(`K' , 1 , 1)'
		matrix `PI' = I(`K') - `One''*`P'
		
		gen double `ninv1' = 1 / (`Nk' - 1)
		mkmat `ninv1' , mat(`ninv1')
		drop `ninv1'
		
		mkmat `Nk' , mat(`n')
		matrix `n' = `n''
		
		* adjust the "omega-hat-bar-G" (ohbg) term for model type
		
		qui if "`modtype'" == "hetop" {
			matrix `ntilde' = ( (1/`K') * (`One' * `ninv1') )
			matrix `ntilde' = invsym(`ntilde')
			local ohbg = 1 / (2*`ntilde'[1,1])
			mat drop `ntilde'
		}
		
		qui if "`modtype'" == "homop" {
			qui sum `Nk'
			local ohbg = 1 / (2 * (r(sum)-`K'))
		}
		
		qui if "`modtype'" == "hetop" & "`phop'" != "" {
			tempvar nt
			g double `nt' = `Nk' - 1
			qui sum `nt' if `phop' == 1
			replace `nt' = r(sum) if `phop' == 1
			replace `nt' = 1/(2*`nt')
			qui sum `nt'
			local ohbg = (1/`K')*r(sum)			
		}
		
		g double `ninv' = 1/`Nk'
		mkmat `ninv' , mat(`ninv')
		drop `ninv'
		
		matrix `Q' = (1/(1+(2*`ohbg'))) * hadamard( hadamard( `ninv'' , (`P' + `n' - `One') ) , `P' )

		/*
		
		create the following vectors/matrices.
		
		Mprime: estimated means in estimation metric.
		Vprime: estimated sampling variance/covariance of the Mprime vector
		Gprime: estimated ln(SD) in estimation metric.
		Omegaprime: estimated sampling variance/covariance of Gprime vector
		Lambdaprime: sampling covariances of Mprime and Gprime
		Cprime: estimated thresholds
		Bprime: sampling variance/covariance of thresholds
		Sprime: exp(Gprime)
		Wprime: estimated sampling variance/covariance of Sprime
		Zprime: estimated covariance of Mprime and Sprime		
		Aprime: sampling var/cov of means X cuts
		Dprime: sampling var/cov of gammas X cuts
		
		*/
		
		qui levelsof `grpid' , local(nameid)
		local mnames
		local snames
		forv i = 1/`K' {
			local j : word `i' of `nameid'
			local mnames	"`mnames' `j'.`grpid'"
			local snames 	"`snames' `j'.`grpid'"
		}

		matrix `Mprime' = `Bfull'[1 .. `K', 1]
		matrix `Vprime' = `Vfull'[1..`K',1..`K']
				
		if "`modtype'" == "hetop" {
			
			matrix `Gprime' = `Bfull'[`=`K'+1' .. `=`K'*2', 1]
			matrix `Omegaprime' = `Vfull'[`=`K'+1'..`=2*`K'',`=`K'+1'..`=2*`K'']
			matrix `Lambdaprime' = `Vfull'[1..`K',`=`K'+1'..`=2*`K'']
			matrix `Cprime' = `Bfull'[`=`K'*2+1' .. `=`K'*2+`numcuts'' , 1]
			matrix `Bprime' = `Vfull'[`=`K'*2+1' .. `=`K'*2+`numcuts'' , ///
				`=`K'*2+1' .. `=`K'*2+`numcuts'']
			matrix `Aprime' = `Vfull'[1..`K',`=`K'*2+1' .. `=`K'*2+`numcuts'']
			matrix `Dprime' = `Vfull'[`=`K'+1'..`=2*`K'', ///
				`=`K'*2+1' .. `=`K'*2+`numcuts'']
			
		}
		
		else {
			
			// else model is homop
			
			matrix `Gprime' = J(`K',1,0)
			matrix `Omegaprime' = J(`K',`K',0)
			matrix `Lambdaprime' = J(`K',`K',0)
			matrix `Cprime' = `Bfull'[`=`K'+1' .. `=`K'+`numcuts'' , 1]
			matrix `Bprime' = `Vfull'[`=`K'+1' .. `=`K'+`numcuts'' , ///
			                             `=`K'+1' .. `=`K'+`numcuts'']
			matrix `Aprime' = `Vfull'[1..`K',`=`K'+1' .. `=`K'+`numcuts'']
			matrix `Dprime' = J(`K',`numcuts',0)
			
		}
		
		if "`identify'" == "refgroup" {
			
			// convert from double-prime to single-prime metric if
			// a reference group was used
			tempname A OneK1 MprimeS
			matrix `A' = `P' * `Gprime'
			local a = `A'[1,1]

			local kap = 1
			if `kappa' == 2 {
				matrix `varPG' = `P' * `Omegaprime' * `P''
				local kap = (1 + (1/2) * `varPG'[1,1])
			}
			
			local delta = exp(`a')
			matrix `OneK1' = J(1,`numcuts',1)
			matrix `MprimeS' = (exp(`a')^-1) * ( `PI' * `Mprime' )	// single prime Mprime vector

			matrix `Cprime' = (`delta'^(-1))*(`Cprime' - `OneK1''*(`P'*`Mprime'))	// now single prime
			
			matrix `Bprime' = ///
				exp(-2*`a')* ///
				(`kap'^2 *(`Bprime'-(`Aprime''*`P'')*`OneK1'-`OneK1''*(`P'*`Aprime')+`OneK1''*(`P'*`Vprime'*`P'')*`OneK1') ///
				-(`delta'/`kap')*hadamard(`Cprime'*`OneK1',(`OneK1''*`P'*`Dprime'-`OneK1''*(`P'*`Lambdaprime'*`P'')*`OneK1')) ///
				-(`delta'/`kap')*hadamard(`OneK1''*`Cprime'',(`Dprime''*`P''*`OneK1'-`OneK1''*(`P'*`Lambdaprime'*`P'')*`OneK1')) ///
				+((`delta'^2)/(`kap'^4))*hadamard(hadamard((`Cprime'*`OneK1'),(`OneK1''*`Cprime'')),(`OneK1''*(`P'*`Omegaprime'*`P'')*`OneK1')))
			
			matrix `Aprime' = (1/`delta'^2) * (`kap'^2) * ///
				(`PI'*(`Aprime'-`Vprime'*`P''*`OneK1')) ///
				- (`delta'*`kap')^(-1)*hadamard(`MprimeS'*`OneK1',`One''*`P'*`Dprime'-`One''*(`P'*`Lambdaprime'*`P'')*`OneK1') ///
				- (`delta'*`kap')^(-1)*hadamard(`One''*`Cprime'', `PI'*`Lambdaprime'*`P''*`OneK1') ///
				+ (`kap')^(-4)*hadamard(hadamard(`MprimeS'*`OneK1', `One''*`Cprime''), `One''*(`P'*`Omegaprime'*`P'')*`OneK1')
			
			matrix `Dprime' = (`kap'/`delta') * ///
				(`PI'*(`Dprime'-`Lambdaprime''*`P''*`OneK1')) - ///
				`kap'*hadamard(`One''*`Cprime'', `PI'*(`Omegaprime''*`P''*`OneK1'))
			
			matrix `Vprime' = (exp(`a')^-2) * ( ///
											( `kap'^2 * `PI' * `Vprime' * `PI'' ) ///
											- (`kap'^(-1)) * (`PI' * `Mprime' * `P' * `Lambdaprime'' * `PI'' + `PI' * `Lambdaprime' * `P'' * `Mprime'' * `PI'' ) ///
											+ (`kap'^(-4)) * (`PI' * `Mprime' * `Mprime'' * `PI'' * ( `P' * `Omegaprime' * `P'') ) ///
											)

			matrix `Lambdaprime' = (exp(`a')^-1) * ( ( `kap' * `PI' * `Lambdaprime' * `PI'') - (`kap'^(-2)) * `PI' * `Mprime' * `P' * `Omegaprime' * `PI'' )
			
			matrix `Mprime' = (exp(`a')^-1) * ( `PI' * `Mprime' )
			matrix `Gprime' = `PI' * `Gprime'
			matrix `Omegaprime' = `PI' * `Omegaprime' * `PI''
		
		}

		* create Sprime, Wprime and Zprime
		
		matrix `Sprime' = `Gprime'
		forv k = 1/`K' {
			matrix `Sprime'[`k',1] = exp(`Sprime'[`k',1])
		}
				
		matrix roweq	`Mprime' = mean:
		matrix rownames `Mprime' = `mnames'
		matrix roweq	`Vprime' = mean:
		matrix coleq	`Vprime' = mean:
		matrix rownames `Vprime' = `mnames'
		matrix colnames `Vprime' = `mnames'
		
		matrix roweq	`Aprime' = mean:
		matrix rownames	`Aprime' = `mnames'
		
		matrix roweq	`Sprime' = sigma:
		matrix rownames	`Sprime' = `snames'
		
		matrix `Wprime' = diag(`Sprime') * `Omegaprime' * diag(`Sprime')
		matrix `Zprime' = `Lambdaprime' * diag(`Sprime')
				
		* --------------------------------- *
		* Mstar and Sstar
		* --------------------------------- *
		
		matrix `sigmaw' = (1/(1+(2*`ohbg'))) * (`P' * hadamard( `Sprime' , `Sprime' ))
		matrix `sigmab' = (`P' * hadamard( `Mprime' , `Mprime' )) + ( (1/(1+(2*`ohbg'))) * ( hadamard( `ninv'' , (`P2' - `P') ) * hadamard( `Sprime' , `Sprime' ) ) )
		
		matrix `sigmaprime' = cholesky( `P' * hadamard(`Mprime',`Mprime') + `Q' * hadamard(`Sprime', `Sprime') )
		
		matrix `Mstar' = invsym(`sigmaprime')*`Mprime'
		matrix `Sstar' = invsym(`sigmaprime')*`Sprime'
		matrix `Cstar' = invsym(`sigmaprime')*`Cprime'
		
		matrix `icchatratio' = `sigmab' * invsym(`sigmaw' + `sigmab')
		matrix `icchat' = 1 - ((1/(1+(2*`ohbg'))) * `P' * hadamard(`Sstar', `Sstar'))
		
		* --------------------------------- *
		* Vstar and Wstar and Zstar
		* --------------------------------- *

		capture {
			
			matrix `R' = `P' * diag(`Mstar') * `Vprime' + `Q' * diag(`Sstar') * `Zprime''
			matrix `T' = `P' * diag(`Mstar') * `Zprime' + `Q' * diag(`Sstar') * `Wprime'
			matrix `varsigprime' = invsym(hadamard(`sigmaprime', `sigmaprime')) * (`P' * diag(`Mprime') * `Vprime' * diag(`Mprime') * `P'' + `Q' * diag(`Sprime') * `Wprime' * diag(`Sprime') * `Q'' + 2 * `P' * diag(`Mprime') * `Zprime' * diag(`Sprime') * `Q'')
			matrix `Vstar' = invsym(hadamard(`sigmaprime', `sigmaprime')) * (`Vprime' - (`Mstar' * `R' + `R'' * `Mstar'') + `Mstar' * `Mstar'' * `varsigprime')
			matrix `Wstar' = invsym(hadamard(`sigmaprime', `sigmaprime')) * (`Wprime' - (`Sstar' * `T' + `T'' * `Sstar'') + `Sstar' * `Sstar'' * `varsigprime')				
			matrix `Zstar' = invsym(hadamard(`sigmaprime', `sigmaprime')) * (`Zprime' - (`Mstar' * `T' + `R'' * `Sstar'') + `Mstar' * `Sstar'' * `varsigprime')
			
			matrix `icchatvar' = 4*(1/(1+(2*`ohbg')))^2 * `P'*(diag(`Sstar')*`Wstar'*diag(`Sstar'))*`P''
			
			matrix `Rc' = `P'*diag(`Mstar')*`Aprime'+`Q'*diag(`Sstar')*`Dprime'

			matrix `Bstar' = invsym(hadamard(`sigmaprime', `sigmaprime'))*(`Bprime'-(`Cstar'*`Rc'+`Rc''*`Cstar'')+(`Cstar'*`Cstar'')*`varsigprime')
		}
		*****
	
		local varmatsRC = _rc		// did the SE calculation preps work?
				
		* preferred standard error formulas
		local mseRC = 0
		cap matrix `Mstar_se' = vecdiag(cholesky(diag(vecdiag(`Vstar'))))'		// these may not always work
		if _rc != 0 {
			matrix `Mstar_se' = J(`K' , 1 , .)
			local mseRC = _rc
		}

		local cseRC = 0
		cap matrix `Cstar_se' = vecdiag(cholesky(diag(vecdiag(`Bstar'))))'		// these may not always work
		if _rc != 0 {
			matrix `Cstar_se' = J(`numcuts' , 1 , .)
			local cseRC = _rc
		}
		
		local sseRC = 0
		cap matrix `Sstar_se' = vecdiag(cholesky(diag(vecdiag(`Wstar'))))'		// these may not always work
		if _rc != 0 {
			matrix `Sstar_se' = J(`K' , 1 , .)
			local sseRC = _rc
		}
		
		* --------------------------------- *
		* Gaps matrix G if requested
		* --------------------------------- *

		if "`gaps'" != "" {
		
			// gap matrix G
			matrix `S' = (1/2)*(hadamard(`Sstar'*`One', `Sstar'*`One')+hadamard(`One''*`Sstar'', `One''*`Sstar''))
			matrix `G' = J(`K',`K',0)
			forv i = 1/`K' {
				forv j = 1/`K' {
					
					mat `S'[`i',`j'] = `S'[`i',`j']^.5
					mat `G'[`i',`j'] = 1 / `S'[`i',`j']
					
				}
			}
			
			matrix `G' = hadamard( `Mstar' * `One' - `One'' * `Mstar'' , `G' )
			
			* sampling variances
			
			/*
			1. paper formula C3, complex SEs
			[note: will be formula B3 in online appendix B in the paper]
			*/
			
			forv i = 1/1 {
				matrix `Gvar`i'' = J(`K', `K', 0)
			}
			
			
			forv g = 1/`K' {
				forv h = 1/`K' {
					if `g' != `h' {
						
						local deltagh = (`Vstar'[`g',`g'] + `Vstar'[`h',`h'] - 2*`Vstar'[`g',`h'])
						local etagh = 1/(4*`S'[`g',`h']^2)*(`Sstar'[`g',1]^2*`Wstar'[`g',`g']+ `Sstar'[`h',1]^2*`Wstar'[`h',`h'] + 2*`Sstar'[`g',1]*`Sstar'[`h',1]*`Wstar'[`g',`h'])
						
						matrix `Gvar1'[`g',`h'] = `deltagh'/`S'[`g',`h']^2 * (1 + `G'[`g',`h']^2 * (`etagh'/`deltagh') - (`etagh'/`S'[`g',`h']^2))
						
					}
				}
			}
		}
			
	}  // conclude calculations done if -oglm- runs
	*****

	
	// returns
	
	* matrices
	
	ereturn matrix pk = `P'
	
	* return matrix with order of "best" reference groups
	tempname rr
	qui get_ref , refrank(1) catname(`catname') grpid(`grpid') numcats(`numcats')
	mat `rr' = r(refrank)
	ereturn matrix refrank = `rr'

	* return initial values if used
	if "`initvals'" == "" & "`startfrom'" == "" {
		tempname iv
		matrix `iv' = J(1,1,.)
		ereturn matrix initvalsmat	= `iv'
		ereturn scalar initvals		= 0
	}
	else if "`initvals'" != "" {
		ereturn matrix initvalsmat	= `initvalsmat'
		ereturn scalar initvals		= 1
	}
	else {
		ereturn matrix initvalsmat	= `startfrom'
		ereturn scalar initvals		= 1
	}
	
	
	* return gap estimates if requested
	if "`gaps'" != "" {
		ereturn matrix G = `G'
		ereturn matrix Gvar1 = `Gvar1'	// formula version 1
	}
	
	* return prime and star estimates
	matrix `Cprime_se' = vecdiag(cholesky(diag(vecdiag(`Bprime'))))'
	matrix `Mprime_se' = vecdiag(cholesky(diag(vecdiag(`Vprime'))))'
	
	if "`modtype'" == "hetop" {
		matrix `Gprime_se' = vecdiag(cholesky(diag(vecdiag(`Omegaprime'))))'
		matrix `Sprime_se' = vecdiag(cholesky(diag(vecdiag(`Wprime'))))'
	}
	else {
		matrix `Gprime_se' = J(`K',1,0)
		matrix `Sprime_se' = J(`K',1,0)
		matrix roweq `Gprime_se' = lnsigma:
		matrix roweq `Sprime_se' = sigma:
		matrix rownames `Sprime_se' = `snames'
		matrix rownames `Gprime_se' = `snames'
	}
	
	ereturn matrix cprime_se = `Cprime_se'
	ereturn matrix cprime = `Cprime'

	ereturn matrix gprime_se = `Gprime_se'
	ereturn matrix gprime = `Gprime'
	
	ereturn matrix sprime_se = `Sprime_se'
	ereturn matrix sprime = `Sprime'
	
	ereturn matrix mprime_se = `Mprime_se'
	ereturn matrix mprime = `Mprime'
		
	ereturn matrix cstar_se = `Cstar_se'
	ereturn matrix cstar = `Cstar'

	ereturn matrix sstar_se = `Sstar_se'
	ereturn matrix sstar = `Sstar'
	
	ereturn matrix mstar_se = `Mstar_se'
	ereturn matrix mstar = `Mstar'
		
	* scalars and strings
	ereturn scalar mseRC = `mseRC'
	ereturn scalar sseRC = `sseRC'
	ereturn scalar cseRC = `cseRC'
	ereturn scalar varmatsRC = `varmatsRC'
	
	if `mseRC' != 0 | `sseRC' != 0 | `cseRC' != 0 | `varmatsRC' != 0 {
		noi di in red "Warning: problem with de-referenced SEs. " ///
		"See mseRC, sseRC and/or varmatsRC."
	}
	
	* estimated icc and SE
	ereturn scalar icchat = `icchat'[1,1]
	ereturn scalar icchatratio = `icchatratio'[1,1]		// alternate formula: sigmab / (sigmab + sigmaw)
	ereturn scalar icchat_var  = `icchatvar'[1,1]
	
	* sigmaprime estimate
	ereturn scalar sigmaprime = `sigmaprime'[1,1]
	ereturn scalar sigmaw = `sigmaw'[1,1]
	ereturn scalar sigmab = `sigmab'[1,1]
	
	if "`identify'" == "sums" {
		ereturn scalar refgrp = 0
	}
	else {
		ereturn scalar refgrp = `ref_group'
	}
	
	ereturn local identify 	= "`identify'"			// "sums" or "refgroup"
	ereturn local modtype 	= "`modtype'"			// "hetop" or "homop"
	if "`phop'" == "" local phop "."
	ereturn local phop 		= "`phop'"				// phop constraint variable, blank if not used
	
	

	// cleanup
	
	constraint drop `phopconstraints' `sumconstraints'	
	
	
	
	*****************************************************************
	***** restore original file and save estimates if requested *****	
	
	qui if "`save'" != "" {
		sort `grpid'
		foreach m in mstar sstar {
			mat `m' = e(`m')
			svmat `m'
			rename `m'1 `m'`savename'
			mat `m' = e(`m'_se)
			svmat `m'
			rename `m'1 `m'`savename'_se
			mat drop `m'
		}
		keep `grpid' `newvarnames'
		tempfile results
		save "`results'"
	
	}
	
	restore
	
	qui if "`save'" != "" {
		tempvar curorder
		g `curorder' = _n
		merge 1:1 `grpid' using "`results'" , nogen
		sort `curorder'
	}
	
	end
	
*************************************************


*************************************************
* program to get the i-th best reference group

cap program drop get_ref
program define get_ref , rclass
	version 13.1
	syntax , ///
		[ ///
		REFRANK(integer 1) CATNAME(string) GRPID(string) NUMCATS(integer 0) ///
		]

	* limit to those with at least 3 non-zero cells
	* identify those above median size (of those with at least 3 cells)
	* then sort on proportion distance metric (binned)
	* then sort on sample size	
	
	preserve
	
		tempname refmat

		qui reshape long `catname', i(`grpid') j(y)	
		qui su y
			loc mincat = r(min)
			loc maxcat = r(max)
		reshape wide 

		egen Nk = rowtotal(`catname'*)

		qui su Nk , d
		local Ntot = r(sum)

		egen num0s = anycount(`catname'*) , val(0)
		gen has3 = 0
		replace has3 = 1 if (`numcats' - num0s) > 2

		qui sum Nk if has3 == 1 , detail
		local medN = r(p50)
		gen abvmed = 0
		replace abvmed = 1 if (Nk >= `medN')
		
		forval i = `mincat'/`maxcat' {		
			qui su `catname'`i'
			gen ptmp`i' = (( `catname'`i' / Nk ) / ( r(sum) / `Ntot' )) - 1
			gen abstmp`i' = abs(ptmp`i')
		}
		
		egen psum = rowtotal(abstmp*)
		gen psumrd = round(psum, .25)
		
		gen Nkrank = 1/Nk
		
		gsort -has3 -abvmed +psumrd +Nkrank +`grpid'
		g tmp_refgrp_rank = _n
		
		mkmat `grpid' , mat(`refmat')
		
		qui sum `grpid' if tmp_refgrp_rank == `refrank'
		local useid = r(mean)
	
	restore
	
	return matrix refrank = `refmat'
	return scalar refid = `useid'
	
end
*************************************************

*************************************************
* program to get starting values
cap program drop get_initial_values
program define get_initial_values , rclass
	version 13.1
	syntax , ///
	[ ///
		grpid(string) refgroup(string) catname(string) ///
		numgrps(integer 0) modtype(string) numcuts(integer 0) ///
	]
		
	// initial values; data will be in long form
	local K = `numgrps'
	if "`refgroup'" == "n" local refgroup = -1

	tempvar stmm stsd
	tempname bc IV

	mat `IV' = J(1,`=`K'*2',0)

	* cutscore starting values
	qui proportion y [fweight = `catname']
	mat `bc' = e(b)
	mat `bc' = `bc'[1,1..`numcuts']

	forval j = 2/`numcuts' {
		local i = `j' - 1
		mat `bc'[1,`j'] = `bc'[1,`j'] + `bc'[1,`i']
	}
	forv j = 1/`numcuts' {
		mat `bc'[1,`j'] = invnormal(`bc'[1,`j'])
	}
	forval i = 1/`numcuts' {
		local bcnames `bcnames' cut`i':_cons
	}
	matrix colnames `bc' = `bcnames'

	qui sum y [fweight=`catname']
	local gm = r(mean)
	local gs = r(sd)

	if `refgroup' > 0 {
		forv i = 1/`numcuts' {
			mat `bc'[1,`i'] = (`bc'[1,`i']*`gs')+`gm'
		}
		qui sum y if `grpid' == `refgroup' [fweight = `catname']
		local gm = r(mean)
		local gs = r(sd)
		forv i = 1/`numcuts' {
			mat `bc'[1,`i'] = (`bc'[1,`i']-`gm')/`gs'
		}
	}

	qui levelsof `grpid' , local(grplevels)

	qui forv k = 1/`K' {

		local j : word `k' of `grplevels'
		qui sum y if `grpid' == `j' [fweight=`catname']
		local tm = r(mean)
		local ts = r(sd)
		count if `grpid' == `j' & `catname' > 0	
		if r(N) < 2 {
			mat `IV'[1,`k'] = (`tm' - `gm')/`gs'
		}
		else {
			mat `IV'[1,`k'] = (`tm' - `gm')/`gs'
			mat `IV'[1,`=`K'+`k''] = log(`ts')-log(`gs')
		}
		
		local Minitcolumns `Minitcolumns' `j'.`grpid'
		local Sinitcolumns `Sinitcolumns' lnsigma:`j'.`grpid'

	}

	if "`modtype'" == "homop" {
		mat `IV' = `IV'[1,1..`K']
		matrix colnames `IV' = `Minitcolumns'
	}
	if "`modtype'" == "hetop" {
		matrix colnames `IV' = `Minitcolumns' `Sinitcolumns'
	}
	matrix `IV' = `IV', `bc'

	noi di in white "..initial values set.."

	return matrix initvalsmat = `IV'			
	
end

*************************************************

