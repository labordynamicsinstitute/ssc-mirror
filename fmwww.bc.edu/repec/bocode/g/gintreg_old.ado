/*This ado file executes non-linear interval regressions where the error term is 
distributed in the GB2 or SGT family tree

Author--Jacob Orchard
v 1.4
Added repeat option 5/19/2017
Update--7/13/2016*/




program gintreg_old, eclass
version 13.0
	if replay() {
		display "Replay not implemented"
	}
	else {
		set more off
		syntax varlist(min=2 fv ts)  [aw fw pw iw] [if] [in] ///
		[, DISTribution(string) /// 
		sigma(varlist) ///
		lambda(varlist) ///
		p(varlist) ///
		q(varlist) ///
		b(varlist) ///
		beta(varlist)  ///
		INITial(numlist) ///
		vce(passthru)  ///
		eyx(string) ///
		Het(string) CONSTraints(passthru) DIFficult TECHnique(passthru) ITERate(passthru)  /// 
		nolog TRace GRADient showstep HESSian SHOWTOLerance TOLerance(passthru) NONRTOLerance ///
		LTOLerance(passthru) NRTOLerance(passthru) robust cluster(passthru) repeat(integer 1) NOCONStant ///
		svy SHOWConstonly FREQuency(varlist)] 
		
		*Defines Independent and Dependent Variables
		local depvar1: word 1 of `varlist'
		local depvar2: word 2 of `varlist'
		local tempregs: list varlist - depvar1 
		local regs: list tempregs - depvar2
				
		*Defines variables for other parameters
		if "`sigma;" != ""{
			local sigmavars `sigma'
			}
			
		if "`lambda;" != ""{
			local lambdavars `lambda'
			}
		if "`p;" != ""{
			local pvars `p'
			}
		if "`q;" != ""{
			local qvars `q'
			}
		
		if "`het'" != "" {
             ParseHet `het'
             local hetvar "`r(varlist)'"
             local hetnocns "`r(constant)'"		
			 }
		
		
		local nregs: word count `regs'
		local nsigma: word count `sigmavars'
		local nlambda: word count `lambdavars'
		local np: word count `pvars'
		local nq: word count `qvars'
		
		*Working with heteroskedasticity
		
		if "`het'" != "" {
		local sigmaeq `"(`hetvar')"'
		di as txt "`sigmaeq'"
		}
		
		*Displays error if using the wrong parameter with chosen distribution
		if  (`nlambda' > 0) & (("`distribution'" != "sgt") & ("`distribution'" != "sged")){
				di as err "Lambda is not a parameter of the chosen distribution"  
				exit 498 
			}
			
		if `np' > 0 & ("`distribution'" != "sgt" & "`distribution'" != "gb2" & "`distribution'" ///
								!= "gg" & "`distribution'" != "sged") {
					di as err "p is not a parameter of the chosen distribution"  
					exit 498
				}
		if  `nq' > 0 &  ("`distribution'" != "sgt" & "`distribution'" != "gb2") {

						di as err "q is not a parameter of the chosen distribution"
						exit 498 
				}
		*Displays error if depvar1 is greater than depvar2
		qui count if `depvar1' > `depvar2' & `depvar1' != .
		if r(N) >0{
			di as err "Dependent variable 1 is greater than dependent variable 2 for some observation"
			exit 198
		}
		
		*Defines titles used when running the program
	    local gb2title "Interval Regression with GB2 Distribution"
		local ggtitle "Interval Regression with Generalized Gamma Distribution"
	    local lntitle "Interval Regression with Log-Normal Distribution"
		local normaltitle "Interval Regression with Normal Distribution"
		local sgttitle "Interval Regression with SGT Distribution"
		local sgedtitle "Interval Regression with the SGED Distribution"
		local slaplacetitle "Interval Regression with the Skewed Laplace Distribution"
		
		*Decides which observations to use in analysis.
		
		marksample touse, nov
		
		foreach i in  `regs' `sigmavars' `pvars' `qvars'{
			qui replace `touse' = 0 if `i' ==.
			}
		qui replace `touse' = 0 if `depvar1' == `depvar2' == .
		
		*Gets rid of uncensored observations with a non-positive dependent
		*variable if user is using a positive distribution.
	
		if "`distribution'" == "lnormal" | "`distribution'" == "ln" | ///
		 "`distribution'" == "gg" | "`distribution'" == "gb2"{
			quietly{ 
			  count if `depvar1' < 0 & `touse' & `depvar1' == `depvar2'
			  local n =  r(N) 
			  if `n' > 0 {
				noi di " "
				if `n' == 1{
					noi di as txt " {res:`depvar1'} has `n' uncensored value < 0;" _c
					noi di as text " not used in calculations"
				}
				else{
					noi di as txt " {res:`depvar1'} has `n' uncensored values < 0;" _c
					noi di as text " not used in calculations"
					}
				}

			  count if `depvar1' == 0 & `touse' & `depvar1' == `depvar2'
			  local n =  r(N) 
			  if `n' > 0 {
				noi di " "
				noi di as txt " {res:`depvar1'} has `n' uncensored values = 0;" _c
				noi di as text " not used in calculations"
				}
				
			  count if `depvar1' <= 0 & `depvar2' <= 0 & `touse' & `depvar1' != `depvar2'
			  local n =  r(N) 
			  if `n' > 0 {
				noi di " "
				noi di as txt " {res:`depvar1'} has `n' intervals < 0;" _c
				noi di as text " not used in calculations"
				}
				
			count if `depvar1' == . & `depvar2' <= 0 & `touse' & `depvar1' != `depvar2'
			local n =  r(N) 
			  if `n' > 0 {
				noi di " "
				noi di as txt " {res:`depvar1'} has `n' left censored values <= 0;" _c
				noi di as text " not used in calculations"
				}
				
		  replace `touse' = 0 if  `depvar2' <= 0
		  
		  }
		}
		
		*Counts the number of each type of interval
		quietly{
			count
			local total = r(N)
			count if `depvar1' != . & `depvar2' != . & `depvar1' == `depvar2'  /// 
			& `touse' == 1
			local nuncensored = r(N)
			count if `depvar1' != . & `depvar2' != . & `depvar1' != `depvar2'  ///
			& `touse' == 1
			local ninterval = r(N)
			count if `depvar1' != . & `depvar2' == .  & `touse' == 1
			local nright = r(N)
			count if `depvar1' == . & `depvar2' != . & `touse' == 1
			local nleft = r(N)
			count if `depvar1' == . & `depvar2' ==. & `touse' == 1
			local nnoobs = r(N)
			
		}
		*Duplicates observations if group data
		if "`frequency'" != ""{
			
			tempvar tot per
			qui egen `tot' = sum(`frequency')
			qui gen `per' = `frequency'/`tot'
			global group_per `per'
		}
		
		*Evaluates model if nongroup data
if "`frequency'" == ""{	

		if "`distribution'" == "normal"{
		
			if "`noconstant'" != ""{
			
			local evaluator intllf_normal
			
			di " "
			di as txt "Fitting Full model with no constant:"
			
			
			if "`initial'" !=""{
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs',noconstant)  (lnsigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize /// 
			init(`initial',copy) `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance' `nonrtolerance' ///
			`tolerance' `ltolerance' `nrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			
			}
			
			else{
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs',noconstant)  (lnsigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize /// 
			 `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance' `nonrtolerance' ///
			`tolerance' `ltolerance' `nrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
			}
			
			else{
			local evaluator intllf_normal
			
			if "`initial'" !=""{
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')  (lnsigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize /// 
			init(`initial', copy) `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'   ///
			`tolerance' `ltolerance' `nrtolerance' `nonrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			
			}
			
			else{
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')  (lnsigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize /// 
			 `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'   ///
			`tolerance' `ltolerance' `nrtolerance' `nonrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display			
			}
			}
		}
		else if "`distribution'" == "lnormal" | "`distribution'" == "ln" {
			
			if "`noconstant'" != ""{
			
			local evaluator intllf_ln
			
			di " "
			di as txt "Fitting Full model with no constant:"
			
			if "`initial'" !=""{
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs',noconstant)  (lnsigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize /// 
			init(`initial',copy) `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance' `nonrtolerance' ///
			`tolerance' `ltolerance' `nrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			
			}
			
			else{
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs',noconstant)  (lnsigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize /// 
			initial(`initial') `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance' `nonrtolerance' ///
			`tolerance' `ltolerance' `nrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
			}
			
			else{
			local evaluator intllf_ln
			
			if "`initial'" !=""{
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')  (lnsigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize /// 
			init(`initial', copy) `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' `nonrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			
			}
			
			else{
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')  (lnsigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize /// 
			 `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'   ///
			`tolerance' `ltolerance' `nrtolerance' `nonrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display			
			}
			}
		}
		else if "`distribution'" == "sgt"{
			
			if "`noconstant'" != ""{
			
			local evaluator intllf_sgt_condition
			
			if "`initial'" != ""{
			
			*This portion here first evaluates the beta coefficients to get an estimate to pass it in later 
			* as start values
			
			qui ml model lf intllf_normal (mu: `depvar1' `depvar2'= `regs', noconstant)  (lnsigma: `sigmavars' ) [`weight'`exp'] ///
			if `touse' ==1,missing search(norescale) maximize `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' `nonrtolerance' `vce'  ///
			`robust' `cluster' 
			
			matrix coeff = e(b)
			
			if `nsigma' == 0{
				matrix coeff2 = coeff[1..., 1..`nregs']
			}
			
			else{
				matrix coeff2 = coeff
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs', noconstant)   ///
			(lnsigma: `sigmavars' ) (lambda: `lambdavars') (p: `pvars') (q:  ///
			`qvars') [`weight'`exp'] if `touse' ==1 , maximize continue missing search(norescale) init(coeff2 `initial',copy) ///
			`constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  `nonrtolerance' /// 
			 `tolerance' `ltolerance' `nrtolerance' title(`sgttitle') `vce'  ///  
			`robust' `cluster' `svy' repeat(`repeat') 
			
			ml display
			
			}
			
			else{
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs', noconstant)   ///
			 (lnsigma: `sigmavars' )(lambda: `lambdavars') (p: `pvars') (q:  ///
			`qvars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize  ///
			 `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `tolerance' `ltolerance' `nrtolerance' `nonrtolerance'   ///  
			`showtolerance' title(`sgttitle') `vce'  /// 
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
			
			}
			
			else{
			
			local evaluator intllf_sgt_condition
			
			if "`initial'" != ""{
			
			*This portion here first evaluates the beta coefficients to get an estimate to pass it in later 
			* as start values
			
			qui ml model lf intllf_normal (mu: `depvar1' `depvar2'= `regs')  (lnsigma: `sigmavars' ) [`weight'`exp'] ///
			if `touse' ==1,missing search(norescale) maximize `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' `nonrtolerance' `vce'  ///
			`robust' `cluster' 
			
			matrix coeff = e(b)
			
			if `nsigma' == 0{
				matrix coeff2 = coeff[1..., 1..`nregs']
			}
			
			else{
				matrix coeff2 = coeff
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')   ///
			(lnsigma: `sigmavars' ) (lambda: `lambdavars') (p: `pvars') (q:  ///
			`qvars') [`weight'`exp'] if `touse' ==1 , maximize continue missing search(norescale) init(coeff2 `initial',copy) ///
			`constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  `nonrtolerance' /// 
			 `tolerance' `ltolerance' `nrtolerance' title(`sgttitle') `vce'  ///  
			`robust' `cluster' `svy' repeat(`repeat') 
			
			ml display
			
			
			}
			
			else{
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')   ///
			(lnsigma: `sigmavars' ) (lambda: `lambdavars') (p: `pvars') (q:  ///
			`qvars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize ///
			 `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `tolerance' `ltolerance' `nrtolerance' `nonrtolerance'   ///  
			`showtolerance' title(`sgttitle') `vce'  /// 
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			
			}
			

			}
		}
		else if "`distribution'" == "sged"{
			
			if "`noconstant'" != ""{
			
			local evaluator intllf_sged
			
			if "`initial'" != ""{
			
			*This portion here first evaluates the beta coefficients to get an estimate to pass it in later 
			* as start values
			
			qui ml model lf intllf_normal (mu: `depvar1' `depvar2'= `regs', noconstant)  (lnsigma: `sigmavars' ) [`weight'`exp'] ///
			if `touse' ==1,missing search(norescale) maximize `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' `nonrtolerance' `vce'  ///
			`robust' `cluster' 
			
			matrix coeff = e(b)
			
			if `nsigma' == 0{
				matrix coeff2 = coeff[1..., 1..`nregs']
			}
			
			else{
				matrix coeff2 = coeff
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs', noconstant)   ///
			(lnsigma: `sigmavars' ) (lambda: `lambdavars')  (p: `pvars')  ///
			[`weight'`exp'] if `touse' ==1 , maximize continue missing search(norescale) init(coeff2 `initial',copy) ///
			`constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  `nonrtolerance' /// 
			 `tolerance' `ltolerance' `nrtolerance' title(`sgedtitle') `vce'  ///  
			`robust' `cluster' `svy' repeat(`repeat') 
			
			ml display
			
			}
			
			else{
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs', noconstant)   ///
			(lnsigma: `sigmavars' ) (lambda: `lambdavars')  (p: `pvars') ///
			[`weight'`exp'] if `touse' ==1 , missing search(on) maximize  ///
			 `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `tolerance' `ltolerance' `nrtolerance' `nonrtolerance'   ///  
			`showtolerance' title(`sgedtitle') `vce'  /// 
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
			
			}
			
			else{
			
			local evaluator intllf_sged
			
			if "`initial'" != ""{
			
			*This portion here first evaluates the beta coefficients to get an estimate to pass it in later 
			* as start values
			
			qui ml model lf intllf_normal (mu: `depvar1' `depvar2'= `regs')  (lnsigma: `sigmavars' ) [`weight'`exp'] ///
			if `touse' ==1,missing search(norescale) maximize `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' `nonrtolerance' `vce'  ///
			`robust' `cluster' 
			
			matrix coeff = e(b)
			
			if `nsigma' == 0{
				matrix coeff2 = coeff[1..., 1..`nregs']
			}
			
			else{
				matrix coeff2 = coeff
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')   ///
			(lnsigma: `sigmavars' ) (lambda: `lambdavars')  (p: `pvars') ///
			 [`weight'`exp'] if `touse' ==1 , maximize continue missing search(norescale) init(coeff2 `initial',copy) ///
			`constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  `nonrtolerance' /// 
			 `tolerance' `ltolerance' `nrtolerance' title(`sgedtitle') `vce'  ///  
			`robust' `cluster' `svy' repeat(`repeat') 
			
			ml display
			
			
			}
			
			else{
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')   ///
			(lnsigma: `sigmavars' ) (lambda: `lambdavars')  (p: `pvars') ///
			[`weight'`exp'] if `touse' ==1 , missing search(on) maximize///
			 `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `tolerance' `ltolerance' `nrtolerance' `nonrtolerance'   ///  
			`showtolerance' title(`sgedtitle') `vce'  /// 
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			
			}
			

			}
			
		}
		else if "`distribution'" == "gb2"{

			if "`noconstant'" != ""{
			
			local evaluator intllf_gb2exp
			
			if "`initial'" != ""{
			
			*This portion here first evaluates the beta coefficients to get an estimate to pass it in later 
			* as start values
			
			qui ml model lf intllf_ln (mu: `depvar1' `depvar2'= `regs', noconstant)  (lnsigma: `sigmavars' ) [`weight'`exp'] ///
			if `touse' ==1,missing search(norescale) maximize `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' `nonrtolerance' `vce'  ///
			`robust' `cluster' 
			
			matrix coeff = e(b)
			
			if `nsigma' == 0{
				matrix coeff2 = coeff[1..., 1..`nregs']
			}
			
			else{
				matrix coeff2 = coeff
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs', noconstant)   ///
			(lnsigma: `sigmavars' ) (p: `pvars') (q: `qvars')   ///
			[`weight'`exp'] if `touse' ==1 , maximize continue missing search(norescale) init(coeff2 `initial',copy) ///
			`constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  `nonrtolerance' /// 
			 `tolerance' `ltolerance' `nrtolerance' title(`gb2title') `vce'  ///  
			`robust' `cluster' `svy' repeat(`repeat') 
			
			ml display
			
			}
			
			else{
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs', noconstant)   ///
			(lnsigma: `sigmavars' ) (p: `pvars') (q: `qvars')  ///
			[`weight'`exp'] if `touse' ==1 , missing search(on) maximize  ///
			 `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `tolerance' `ltolerance' `nrtolerance' `nonrtolerance'   ///  
			`showtolerance' title(`gb2title') `vce'  /// 
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
			
			}
			
			else{
			
			local evaluator intllf_gb2exp
			
			if "`initial'" != ""{
			
			*This portion here first evaluates the beta coefficients to get an estimate to pass it in later 
			* as start values
			
			qui ml model lf intllf_ln (mu: `depvar1' `depvar2'= `regs')  (lnsigma: `sigmavars' ) [`weight'`exp'] ///
			if `touse' ==1,missing search(norescale) maximize `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' `nonrtolerance' `vce'  ///
			`robust' `cluster' 
			
			matrix coeff = e(b)
			
			if `nsigma' == 0{
				matrix coeff2 = coeff[1..., 1..`nregs']
			}
			
			else{
				matrix coeff2 = coeff
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')   ///
			(lnsigma: `sigmavars' ) (p: `pvars') (q: `qvars')  ///
			 [`weight'`exp'] if `touse' ==1 , maximize continue missing search(norescale) init(coeff2 `initial',copy) ///
			`constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  `nonrtolerance' /// 
			 `tolerance' `ltolerance' `nrtolerance' title(`gb2title') `vce'  ///  
			`robust' `cluster' `svy' repeat(`repeat') 
			
			ml display
			
			
			}

		}
			
			else{
			
			di " "
			di as txt "Fitting constant only model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2'=)  (lnsigma: ///
			) (p: ) (q: )  [`weight'`exp']  if `touse' ==1 , missing search(on)   maximize /// 
			initial(`initial') `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`gb2title') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')   ///
			(lnsigma: `sigmavars' ) (p: `pvars') (q: `qvars')  ///
			[`weight'`exp'] if `touse' ==1 , missing search(on) maximize continue ///
			 `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `tolerance' `ltolerance' `nrtolerance' `nonrtolerance'   ///  
			`showtolerance' title(`gb2title') `vce'  /// 
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			
				}
			}
		else if "`distribution'" == "gg"{
			
			if "`noconstant'" != ""{
			
			local evaluator intllf_ggsigma
			
			if "`initial'" != ""{
			
			*This portion here first evaluates the beta coefficients to get an estimate to pass it in later 
			* as start values
			
			qui ml model lf intllf_ln (mu: `depvar1' `depvar2'= `regs', noconstant)  (lnsigma: `sigmavars' ) [`weight'`exp'] ///
			if `touse' ==1,missing search(norescale) maximize `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' `nonrtolerance' `vce'  ///
			`robust' `cluster' 
			
			matrix coeff = e(b)
			
			if `nsigma' == 0{
				matrix coeff2 = coeff[1..., 1..`nregs']
			}
			
			else{
				matrix coeff2 = coeff
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs', noconstant)   ///
			(lnsigma: `sigmavars' ) (p: `pvars')  ///
			[`weight'`exp'] if `touse' ==1 , maximize continue missing search(norescale) init(coeff2 `initial',copy) ///
			`constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  `nonrtolerance' /// 
			 `tolerance' `ltolerance' `nrtolerance' title(`ggtitle') `vce'  ///  
			`robust' `cluster' `svy' repeat(`repeat') 
			
			ml display
			
			}
			
			else{
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs', noconstant)   ///
			(lnsigma: `sigmavars' ) (p: `pvars') ///
			[`weight'`exp'] if `touse' ==1 , missing search(on) maximize  ///
			 `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `tolerance' `ltolerance' `nrtolerance' `nonrtolerance'   ///  
			`showtolerance' title(`ggtitle') `vce'  /// 
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
			
			}
			
			else{
			
			local evaluator intllf_ggsigma
			
			if "`initial'" != ""{
			
			*This portion here first evaluates the beta coefficients to get an estimate to pass it in later 
			* as start values
			
			qui ml model lf intllf_ln (mu: `depvar1' `depvar2'= `regs')  (lnsigma: `sigmavars' ) [`weight'`exp'] ///
			if `touse' ==1,missing search(norescale) maximize `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' `nonrtolerance' `vce'  ///
			`robust' `cluster' 
			
			matrix coeff = e(b)
			
			if `nsigma' == 0{
				matrix coeff2 = coeff[1..., 1..`nregs']
			}
			
			else{
				matrix coeff2 = coeff
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')   ///
			(lnsigma: `sigmavars' ) (p: `pvars')  ///
			 [`weight'`exp'] if `touse' ==1 , maximize continue missing search(norescale) init(coeff2 `initial',copy) ///
			`constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  `nonrtolerance' /// 
			 `tolerance' `ltolerance' `nrtolerance' title(`ggtitle') `vce'  ///  
			`robust' `cluster' `svy' repeat(`repeat') 
			
			ml display
			
			
			}
			
			else{
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')   ///
			(lnsigma: `sigmavars' ) (p: `pvars')   ///
			[`weight'`exp'] if `touse' ==1 , missing search(on) maximize ///
			 `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `tolerance' `ltolerance' `nrtolerance' `nonrtolerance'   ///  
			`showtolerance' title(`ggtitle') `vce'  /// 
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
		}
		
		}
		}
		else{
			
			if "`noconstant'" != ""{
			
			local evaluator intllf_normal
			
			di " "
			di as txt "Fitting Full model with no constant:"
			
			
			if "`initial'" !=""{
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs',noconstant)  (lnsigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize /// 
			init(`initial',copy) `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance' `nonrtolerance' ///
			`tolerance' `ltolerance' `nrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			
			}
			
			else{
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs',noconstant)  (lnsigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize /// 
			 `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance' `nonrtolerance' ///
			`tolerance' `ltolerance' `nrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
			}
			
			else{
			local evaluator intllf_normal
			
			if "`initial'" !=""{
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')  (lnsigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize /// 
			init(`initial', copy) `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'   ///
			`tolerance' `ltolerance' `nrtolerance' `nonrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			
			}
			
			else{
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')  (lnsigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize /// 
			 `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'   ///
			`tolerance' `ltolerance' `nrtolerance' `nonrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display			
			}
			}
		}
}	
*Evaluates model if grouped data
else{	

		di as txt "OVER HERE"
		
		if "`distribution'" == "normal"{

			if "`noconstant'" != ""{
			
			local evaluator intllf_normal_group
			
			di " "
			di as txt "Fitting Full model with no constant:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs', noconstant)  (sigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize /// 
			initial(`initial') `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
			else{
		
			local evaluator intllf_normal_group
			
			di " "
			di as txt "Fitting constant only model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2'=)  (sigma: ///
			) [`weight'`exp'] if `touse' ==1 , missing search(on)   maximize /// 
			initial(`initial') `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat') 
			
			if "`showconstonly'" != ""{
				ml display, showeqns //Shows constant only model
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')  (sigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) continue  maximize /// 
			initial(`initial') `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
		}
		else if "`distribution'" == "lnormal" | "`distribution'" == "ln" {
			
			if "`noconstant'" != ""{
			local evaluator intllf_ln_group
			
			di " "
			di as txt "Fitting Full model with no constant:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs',noconstant)  /// 
			(sigma: `sigmavars' ) [`weight'`exp'] if `touse' ==1 , missing search(on) /// 
			maximize initial(`initial') `constraints' `technique'  `difficult'  ///
			`iterate' `log' `trace' `gradient' `showstep' `hessian'  ///
			`showtolerance' `tolerance' `ltolerance' `nrtolerance' title(`lntitle') ///
			`vce'  `robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
			
			else{
			local evaluator intllf_ln_group
			
			
			di " "
			di as txt "Fitting constant only model:"
				
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = )  /// 
			(sigma: ) [`weight'`exp'] if `touse' ==1 , missing search(on)  /// 
			maximize initial(`initial') `constraints' `technique'  `difficult'  ///
			`iterate' `log' `trace' `gradient' `showstep' `hessian'  ///
			`showtolerance' `tolerance' `ltolerance' `nrtolerance' title(`lntitle') ///
			`vce'  `robust' `cluster' `svy' repeat(`repeat')
			
			if "`showconstonly'" != ""{
				ml display, showeqns //Shows constant only model
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')  /// 
			(sigma: `sigmavars' ) [`weight'`exp'] if `touse' ==1 , missing search(on) continue /// 
			maximize initial(`initial') `constraints' `technique'  `difficult'  ///
			`iterate' `log' `trace' `gradient' `showstep' `hessian'  ///
			`showtolerance' `tolerance' `ltolerance' `nrtolerance' title(`lntitle') ///
			`vce'  `robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
		}
		else if "`distribution'" == "sgt"{
			
			if "`noconstant'" != ""{

			local evaluator intllf_sgt_group
			
			di " "
			di as txt "Fitting Full model with no constant:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs',noconstant)   ///
			(lambda: `lambdavars') (sigma: `sigmavars' ) (p: `pvars') (q:  ///
			`qvars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`sgttitle') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			
			}
			
			else{
			local evaluator intllf_sgt_group
			
			di " "
			di as txt "Fitting constant only model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = )   ///
			(lambda: ) (sigma:  ) (p: ) (q:  ///
			) [`weight'`exp'] if `touse' ==1 , missing search(on) maximize  ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`sgttitle') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			if "`showconstonly'" != ""{
				ml display, showeqns //Shows constant only model
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')   ///
			(lambda: `lambdavars') (sigma: `sigmavars' ) (p: `pvars') (q:  ///
			`qvars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize continue ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`sgttitle') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
		}
		else if "`distribution'" == "sged"{
			
			if "`noconstant'" != ""{
			
			local evaluator intllf_sged_group
			
			di " "
			di as txt "Fitting Full model with no constant:"
			
			ml model lf `evaluator' (m: `depvar1' `depvar2' = `regs', noconstant)   ///
			(lambda: `lambdavars') (sigma: `sigmavars' ) (p: `pvars') [`weight'`exp']   ///
			 if `touse' ==1 , missing search(on) maximize ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`sgttitle') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
			else{
			
			local evaluator intllf_sged_group
			
			di " "
			di as txt "Fitting constant only model:"
			
			ml model lf `evaluator' (m: `depvar1' `depvar2' = )   ///
			(lambda: ) (sigma:  ) (p: ) [`weight'`exp']  ///
			 if `touse' ==1 , missing search(on) maximize  ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`sgttitle') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			if "`showconstonly'" != ""{
				ml display, showeqns //Shows constant only model
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (m: `depvar1' `depvar2' = `regs')   ///
			(lambda: `lambdavars') (sigma: `sigmavars' ) (p: `pvars') [`weight'`exp']   ///
			 if `touse' ==1 , missing search(on) maximize continue ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`sgttitle') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
		}
		else if "`distribution'" == "gb2"{
			
			if "`noconstant'" != ""{
			
			local evaluator intllf_gb2_group
			
			di " "
			di as txt "Fitting Full model with no constant:"
			
			ml model lf `evaluator' (delta: `depvar1' `depvar2' = `regs', noconstant)   ///
			(sigma: `sigmavars') (p: `pvars') (q:  ///
			`qvars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`gb2title') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display, plus
			}
			
			else{
			local evaluator intllf_gb2_group
			
			di " "
			di as txt "Fitting constant only model:"
			
			ml model lf `evaluator' (delta: `depvar1' `depvar2' = )   ///
			(sigma:  ) (p: ) (q:  ///
			) [`weight'`exp'] if `touse' ==1 , missing search(on) maximize  ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`gb2title') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			if "`showconstonly'" != ""{
				ml display, showeqns //Shows constant only model
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (delta: `depvar1' `depvar2' = `regs')   ///
			(sigma: `sigmavars') (p: `pvars') (q:  ///
			`qvars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize continue ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`gb2title') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display, plus
			}
		}
		else if "`distribution'" == "gg"{
			
			if "`noconstant'" != ""{
			
			local evaluator intllf_ggsigma_group
			
			di " "
			di as txt "Fitting Full model with no constant:"
			
			ml model lf `evaluator' (delta: `depvar1' `depvar2' = `regs', noconstant)   ///
			(sigma: `sigmavars') (p: `pvars') [`weight'`exp']   ///
			 if `touse' ==1 , missing search(on) maximize ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`ggtitle') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			
			}
			
			else{
			local evaluator intllf_ggsigma_group
			
			di " "
			di as txt "Fitting constant only model:"
			
			ml model lf `evaluator' (delta: `depvar1' `depvar2' = )   ///
			(sigma: ) (p: ) [`weight'`exp']  ///
			 if `touse' ==1 , missing search(on) maximize  ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`ggtitle') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			if "`showconstonly'" != ""{
				ml display, showeqns //Shows constant only model
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (delta: `depvar1' `depvar2' = `regs')   ///
			(sigma: `sigmavars') (p: `pvars') [`weight'`exp']   ///
			 if `touse' ==1 , missing search(on) maximize continue ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`ggtitle') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
		}
		else{

			if "`noconstant'" != ""{
			
			local evaluator intllf_normal_group
			
			di " "
			di as txt "Fitting Full model with no constant:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs', noconstant)  (sigma: ///
			`sigmavars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize /// 
			initial(`initial') `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
			else{
		
			local evaluator intllf_normal_group
			
			di " "
			di as txt "Fitting constant only model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2'=)  (sigma: ///
			)  [`weight'`exp']  if `touse' ==1 , missing search(on)   maximize /// 
			initial(`initial') `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			if "`showconstonly'" != ""{
				ml display, showeqns //Shows constant only model
			}
			
			di " "
			di as txt "Fitting Full model:"
			
			ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')  (sigma: ///
			`sigmavars')  [`weight'`exp']  if `touse' ==1 , missing search(on) continue  maximize /// 
			initial(`initial') `constraints' `technique'  `difficult' `iterate' ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`normaltitle') `vce' ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			ml display
			}
		}
}	
	*******************************************************************************************************************
		
			if "`noconstant'" != ""{ 
			
			if "`distribution'" == "ln" | "`distribution'" == "lnormal" {
			
			local evaluator intllf_ln
			
			quietly ml model lf `evaluator' (mu: `depvar1' `depvar2' = )  /// 
			(sigma: ) [`weight'`exp'] if `touse' ==1 , missing search(on)  /// 
			maximize initial(`initial') `constraints' `technique'  `difficult'  ///
			`iterate' `log' `trace' `gradient' `showstep' `hessian'  ///
			`showtolerance' `tolerance' `ltolerance' `nrtolerance' title(`lntitle') ///
			`vce'  `robust' `cluster' `svy' repeat(`repeat')
			
			quietly ml model lf `evaluator' (mu: `depvar1' `depvar2' = `regs')  /// 
			(sigma: `sigmavars' ) [`weight'`exp'] if `touse' ==1 , missing search(on) continue /// 
			maximize initial(`initial') `constraints' `technique'  `difficult'  ///
			`iterate' `log' `trace' `gradient' `showstep' `hessian'  ///
			`showtolerance' `tolerance' `ltolerance' `nrtolerance' title(`lntitle') ///
			`vce'  `robust' `cluster' `svy' repeat(`repeat')
			
			}
			
			else if "`distribution'" == "gg" {
			
			local evaluator intllf_ggsigma
			
			quietly ml model lf `evaluator' (delta: `depvar1' `depvar2' = )   ///
			(sigma: ) (p: ) [`weight'`exp']  ///
			 if `touse' ==1 , missing search(on) maximize  ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`ggtitle') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			quietly ml model lf `evaluator' (delta: `depvar1' `depvar2' = `regs')   ///
			(sigma: `sigmavars') (p: `pvars') [`weight'`exp']   ///
			 if `touse' ==1 , missing search(on) maximize continue ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`ggtitle') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			}
			
			else if "`distribution'" =="sged"{
			
			local evaluator intllf_sged
			
			quietly ml model lf `evaluator' (m: `depvar1' `depvar2' = )   ///
			(lambda: ) (sigma:  ) (p: ) [`weight'`exp']  ///
			 if `touse' ==1 , missing search(on) maximize  ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`sgttitle') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			quietly ml model lf `evaluator' (m: `depvar1' `depvar2' = `regs')   ///
			(lambda: `lambdavars') (sigma: `sigmavars' ) (p: `pvars') [`weight'`exp']   ///
			 if `touse' ==1 , missing search(on) maximize continue ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`sgttitle') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			}
			
			else if "`distribution'" == "gb2"{

			local evaluator intllf_gb2exp
			
			quietly ml model lf `evaluator' (delta: `depvar1' `depvar2' = `regs', noconstant)   ///
			(sigma: `sigmavars') (p: `pvars') (q:  ///
			`qvars') [`weight'`exp'] if `touse' ==1 , missing search(on) maximize ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`gb2title') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			quietly ml model lf `evaluator' (delta: `depvar1' `depvar2' = )   ///
			(sigma:  ) (p: ) (q:  ///
			) [`weight'`exp'] if `touse' ==1 , missing search(on) maximize  ///
			initial(`initial') `constraints' `technique'  `difficult' `iterate'  ///
			`log' `trace' `gradient' `showstep' `hessian' `showtolerance'  ///
			`tolerance' `ltolerance' `nrtolerance' title(`gb2title') `vce'  ///
			`robust' `cluster' `svy' repeat(`repeat')
			
			}
			
			}
		
		mat betas = e(b) //coefficient matrix
		
		*Find the Conditional expected value at specified level
		if "`distribution'" == "gb2" | "`distribution'" == "gg" ///
		| "`distribution'" == "ln" | "`distribution'" == "lnormal" ///
		| "`distribution'" == "sgt" | "`distribution'" == "sged"{
			
			mat mid_Xs = 1
			if "`eyx'" == ""{
				local eyx "mean"
				di "{res:`eyx'}         {c |}"
			}
			else if "`eyx'" == "mean" {
			di "{res:`eyx'}         {c |}" 
			}
			else if "`eyx'" == "p50" | "`eyx'" == "p10" | "`eyx'" == "p25" | ///
			        "`eyx'" == "p75" | "`eyx'" == "p90" | "`eyx'" == "p95" | ///
					"`eyx'" == "p99" | "`eyx'" == "min" | "`eyx'" == "max" {		
			
					di "{res:`eyx'}          {c |}"
				}
			else if "`eyx'" == "p1" | "`eyx'" == "p5" {
				di "{res:`eyx'}           {c |}"
				}
			else{
				di as err "Not a valid option for eyx"
				exit 498
				}
			
			
			quietly foreach x in `regs' {
				sum `x', detail
				scalar mid_ = r(`eyx')
				mat mid_Xs = mid_Xs, mid_
			}
			mat sigma = betas[1,"sigma:_cons"]
			scalar sigma = sigma[1,1]
			
			if "`distribution'" == "gb2"{
			
				mat deltas = betas[1,"delta:"]
				mat deltas = deltas'
				mata: st_matrix("deltas", flipud(st_matrix("deltas"))) //flips matrix around
		                        									// to conform with Xs									
				mat p = betas[1,"p:_cons"]
				scalar p = p[1,1]
				mat q = betas[1,"q:_cons"]
				scalar q = q[1,1]
				mat xbeta = mid_Xs*deltas
				scalar xbeta = xbeta[1,1]
				mat expected = exp(xbeta)*( (exp(lngamma(p+sigma))*exp(lngamma(q-sigma)))/  ///
											( exp(lngamma(p))*exp(lngamma(q))))
			}
			
			if "`distribution'" == "sgt"{
			
				mat mu = betas[1,"mu:"]
				mat mu = mu'
				mata: st_matrix("mu", flipud(st_matrix("mu"))) //flips matrix around
																		// to conform with Xs										
				mat xbeta = mid_Xs*mu     																
				mat p = betas[1,"p:_cons"]
				scalar p = p[1,1]
				mat q = betas[1,"q:_cons"]
				scalar q = q[1,1]
				mat lambda = betas[1,"lambda:_cons"]
				scalar lambda = lambda[1,1]
				mat sigma = betas[1,"sigma:_cons"]
				scalar sigma = sigma[1,1]
				scalar xbeta = xbeta[1,1]
				mat expected = xbeta + 2*lambda*sigma*((q^(1/p))*(exp(lngamma(2/p) ///
				+lngamma(q-(1/p)) - lngamma((1/p)+q))/exp(lngamma(1/p) ///
				+lngamma(q)) - lngamma((1/p)+q)) ) 
			}
			
			if "`distribution'" == "sged"{
			
				mat mu = betas[1,"m:"]
				mat mu = mu'
				mata: st_matrix("mu", flipud(st_matrix("mu"))) //flips matrix around
																		// to conform with Xs										
				mat xbeta = mid_Xs*mu     																
				mat p = betas[1,"p:_cons"]
				scalar p = p[1,1]
				mat lambda = betas[1,"lambda:_cons"]
				scalar lambda = lambda[1,1]
				mat sigma = betas[1,"sigma:_cons"]
				scalar sigma = sigma[1,1]
				scalar xbeta = xbeta[1,1]
				mat expected = xbeta + 2*lambda*sigma*(q^(1/p))*(exp(lngamma(2/p)) ///
				/exp(lngamma(1/p))) 
				
			}
			
			if "`distribution'" == "gg"{
			
				mat deltas = betas[1,"delta:"]
				mat deltas = deltas'
				mata: st_matrix("deltas", flipud(st_matrix("deltas"))) //flips matrix around
																		// to conform with Xs										
				mat p = betas[1,"p:_cons"]
				scalar p = p[1,1]
				mat xbeta = mid_Xs*deltas
				scalar xbeta = xbeta[1,1]
				mat expected = exp(xbeta)*( (exp(lngamma(p+sigma)))/  ///
											( exp(lngamma(p))))
			}
			
			if "`distribution'" == "ln" | "`distribution'" == "lnormal" {
				
				mat mu = betas[1,"mu:"]
				mat mu = mu'
				mata: st_matrix("mu", flipud(st_matrix("mu"))) //flips matrix around
																		// to conform with Xs										
				mat xbeta = mid_Xs*mu
				scalar xbeta = xbeta[1,1]
				mat expected = exp(xbeta + (sigma^2/2))
			}
			
				scalar eyx = expected[1,1]
				table_line "E[Y|X]" eyx 
				di as text "{hline 13}{c BT}{hline 64}"
				ereturn scalar eyx = eyx
		}
		
		*Observation type count for interval regression
		if "`frequency'" == ""{
			noi di " "
			if `nleft' != 1{
				noi di as txt " {res:`nleft'} left-censored observations" 
			}
			if `nleft' == 1{
				noi di as txt " {res:`nleft'} left-censored observation" 
			}
			if `nuncensored' != 1{
				noi di as txt " {res: `nuncensored'} uncensored observations" 
			}
			if `nuncensored' == 1{
				noi di as txt " {res:`nuncensored'} uncensored observation" 
			}
			if `nright' != 1{
				noi di as txt " {res:`nright'} right-censored observations" 
			}
			if `nright' == 1{
				noi di as txt " {res:`nright'} right-censored observation" 
			}
			if `ninterval' != 1{
				noi di as txt " {res:`ninterval'} interval observations" 
			}
			if `ninterval' == 1{
				noi di as txt " {res:`ninterval'} interval observation" 
			}
		}
		*Observation type count for grouped regression
		if "`frequency'" ~= ""{
			
			noi di " "
			noi di as txt " {res: `total'} groups"
			if `nleft' != 1{
				noi di as txt " {res:`nleft'} left-censored groups" 
			}
			if `nleft' == 1{
				noi di as txt " {res:`nleft'} left-censored group" 
			}
			if `nuncensored' != 1{
				noi di as txt " {res: `nuncensored'} uncensored groups" 
			}
			if `nuncensored' == 1{
				noi di as txt " {res:`nuncensored'} uncensored group" 
			}
			if `nright' != 1{
				noi di as txt " {res:`nright'} right-censored groups" 
			}
			if `nright' == 1{
				noi di as txt " {res:`nright'} right-censored group" 
			}
			if `ninterval' != 1{
				noi di as txt " {res:`ninterval'} interval groups" 
			}
			if `ninterval' == 1{
				noi di as txt " {res:`ninterval'} interval group" 
			}
		}
		qui ereturn list
		
		}
	
end

*program drop table_line
program table_line
	args vname coef se z p 95l 95h
	if (c(linesize) >= 100){
		local abname = "`vname'"
		}
	else if (c(linesize) > 80){
	local abname = abbrev("`vname'", 12+(c(linesize)-80))
	}
	else{
	local abname = abbrev("`vname'", 12)
	}
	local abname = abbrev("`vname'",12)
	display as text %12s "`abname'" " { c |}" /*
	*/ as result /*
	*/ " " %8.0g `coef' " " /*
	*/ %9.0g `se' " " %9.0g `z' " " /*
	*/ %9.0g `p' "  " %9.0g `95l' "   " /*
	*/ %9.0g `95h'
end

program ParseHet, rclass
        syntax varlist(fv ts numeric) [, noCONStant]
        return local varlist "`varlist'"
        return local constant `constant'
end

version 13.0
mata:
matrix function flipud(matrix X)
{
return(rows(X)>1 ? X[rows(X)..1,.] : X)
}
end
