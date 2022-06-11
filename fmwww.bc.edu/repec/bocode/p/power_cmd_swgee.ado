*!version1.1 15APR2022

/* -----------------------------------------------------------------------------
** PROGRAM NAME: POWER_CMD_SWGEE
** VERSION: 1.1
** DATE: APR 15, 2022
** -----------------------------------------------------------------------------
** CREATED BY: JOHN GALLIS, XUEQI WANG, PAUL RATHOUZ, JOHN PREISSER, FAN LI, LIZ TURNER
** -----------------------------------------------------------------------------
** PURPOSE: THIS PROGRAM ALLOWS THE USER TO PERFORM POWER CALCULATIONS FOR GEE
**			ANALYSES OF STEPPED WEDGE CLUSTER RANDOMIZED TRIALS, FOR BOTH CLOSED
**			COHORT AND CROSS-SECTIONAL DESIGNS
** -----------------------------------------------------------------------------
** MODIFICATIONS: APR 15, 2022 - MINOR UPDATES TO OPTIONS REQUESTED BY STATA JOURNAL
							   - CORSTR OPTION CAN NOW BE ABBREVIATED
							   - DEFAULT FAMILY IS NOW GAUSSIAN
							   - NORMAL CAN BE SPECIFIED AS FAMILY INSTEAD OF GAUSSIAN
** -----------------------------------------------------------------------------
** OPTIONS: SEE HELP FILE
** -----------------------------------------------------------------------------
** -----------------------------------------------------------------------------
*/
program power_cmd_swgee, rclass
version 15.1         
	#delimit ;
   syntax, es(real) NCLUSTers(integer) NPERiods(integer) n(integer) tau0(real)
	[mu0(real 0.1) muT(real -99) mus(numlist) alpha(real 0.05) working_ind(integer 0) corstr(string) design(varlist) family(string) 
	link(string) phi(real 1) 
	tau1(real -99) tau2(real -99) 
	rho1(real -99) rho2(real -99)  df(real -99)]
	;
	#delimit cr
	
	/* CHECKING IF ALPHA IS VALID */
	if `alpha' <= 0 | `alpha' >= 1 {
	    di as error "Alpha (type I error) must be between 0 and 1"
		exit 198
	}
	
	/* DEFAULTS FOR FAMILY AND LINK */
	if "`family'" == "" local family "gaussian"
	if "`link'" == "" & "`family'"=="binomial"  local link "logit"
	if "`link'" == "" & "`family'"=="poisson" local link "log"
	if "`link'" == "" & "`family'"=="gaussian" local link "identity"
	if "`link'" == "" & "`family'"=="normal" local link "identity"

	/* DEFAULT IF DESIGN IS LEFT BLANK */
	if "`design'" == "" {
		local design = "0"
	}	
	
	/* DEFAULT CORRELATION STRUCTURE AND DEFAULT DEGREES OF FREEDOM */
	if "`corstr'" == "" local corstr "nested exchangeable"
	if `df'==-99 {
		local df=`nclusters'-2
	}
	
	/* CHECKING PROPER CORRELATION PARAMETERS ARE SPECIFIED */
	if (strpos("`corstr'","nested") > 0 | strpos("`corstr'","block") > 0) & (`rho1' != -99 | `rho2' != -99) {
	    di as error "Must specify tau (not rho) parameters for exchangeable correlation structure"
		exit 198
	}
	
	if (strpos("`corstr'","exponential") > 0 | strpos("`corstr'","proportional") > 0) & (`tau1' != -99 | `tau2' != -99) {
	    di as error "Must specify rho (not tau) parameters for decay correlation structure"
		exit 198	
	}
	
	if (strpos("`corstr'","nested") > 0 & `tau2' != -99) {
	    di as error "A nested exchangeable correlation structure should only have two correlation parameters specified (tau0 and tau1)"
	}
	
	if (strpos("`corstr'","exponential") > 0 & `rho2' != -99)  {
	    di as error "An exponential decay correlation structure should only have two correlation parameters specified (tau0 and rho1)"
		exit 198
	}
	
	/* PERIOD EFFECTS |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| */
	* if mu0 and muT are specified
	* mu0 default is 0.1
	if "`mus'" == "" {
		if "`link'" == "logit" {
		    *also for the case if the user specifies muT to be equal to mu0
			if (`muT' == -99) | (`muT'==`mu0') {
				local mus: di _dup(`nperiods') "`mu0' "
				local mus = trim("`mus'")
				local b0 = logit(`mu0')
				local betas: di _dup(`nperiods') "`b0' "
				local betas = trim("`betas'")
			}
			else if `muT' <= 1 & `muT' >= 0 {
				local bT = logit(`muT')
				local b0 = logit(`mu0')
				local bS = (`bT'-`b0')/(`nperiods'-1)
				local pS = (`muT'-`mu0')/(`nperiods'-1)
				numlist "`b0'(`bS')`bT'"
				local betas = "`r(numlist)'"
				numlist "`mu0'(`pS')`muT'"
				local mus = "`r(numlist)'"
			}
			else {
				di as err "Error: Prevalences must be between 0 and 1"
				exit 198
			}
		}
		else if "`link'" == "log" {
			if (`muT' == -99) | (`muT'==`mu0') {
				local mus: di _dup(`nperiods') "`mu0' "
				local mus = trim("`mus'")
				local b0 = log(`mu0')
				local betas: di _dup(`nperiods') "`b0' "
				local betas = trim("`betas'")
			}
			else if `muT' <= 1 & `muT' >= 0 {
				local bT = log(`muT')
				local b0 = log(`mu0')
				local bS = (`bT'-`b0')/(`nperiods'-1)
				local pS = (`muT'-`mu0')/(`nperiods'-1)
				numlist "`b0'(`bS')`bT'"
				local betas = "`r(numlist)'"
				numlist "`mu0'(`pS')`muT'"
				local mus = "`r(numlist)'"
			}
			else {
				di as err "Error: Prevalences must be between 0 and 1"
				exit 198
			}
		}
		else if "`link'" == "identity" {
			if (`muT' == -99) | (`muT'==`mu0') {
				local mus: di _dup(`nperiods') "`mu0' "
				local mus = trim("`mus'")
				local b0 = `mu0'
				local betas: di _dup(`nperiods') "`b0' "
				local betas = trim("`betas'")
			}
			else if `muT' <= 1 & `muT' >= 0 {
				local bT = `muT'
				local b0 = `mu0'
				local bS = (`bT'-`b0')/(`nperiods'-1)
				local pS = (`muT'-`mu0')/(`nperiods'-1)
				numlist "`b0'(`bS')`bT'"
				local betas = "`r(numlist)'"
				numlist "`mu0'(`pS')`muT'"
				local mus = "`r(numlist)'"
			}
			else {
				di as err "Error: Prevalences must be between 0 and 1"
				exit 198
			}
		}
		
		local betact: word count `betas'
		if `betact' != `nperiods' {
		    di as error "Number of period effects (betas) must equal the number of periods (J)"
			exit 198
		}
	}

	* individual probabilities specified
	else if "`mus'" != "" {
		local xyz = 1
		foreach ijk in `mus' {
			if `ijk' < 0 | `ijk' > 1 {
				di as err "Prevalences/rates must be between 0 and 1"
				exit 198
			}
			if "`link'" == "logit" {
				local _add = logit(`ijk')
			}
			else if "`link'" == "log" {
			    local _add = log(`ijk')
			}
			else if "`link'" == "identity" {
			    local _add = `ijk'
			}
			if `xyz' == 1 {
				local betas = `"`_add'"'
			}
			else {
				local betas = `"`betas' `_add'"'
			}
			local ++xyz
		}
		local betact: word count `betas'
		if `betact' != `nperiods' {
		    di as error "Number of period effects (betas) must equal the number of periods (J)"
			exit 198
		}
	}
	/* ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| */
	
	/* DEFAULTS FOR CORRELATION PARAMETERS */
	if strpos("`corstr'","nested") > 0 | strpos("`corstr'","block") > 0 {
		if `tau1' == -99 {
			local tau1 = `tau0'
		}
		if strpos("`corstr'","block") > 0 {
			if `tau2' == -99 {
				local tau2 = `tau1'
			}
		}
		else {
			local tau2 = .
		}
		local alpha0 = `tau0'
		local alpha1 = `tau1'
		local alpha2 = `tau2'
		
	}
	else {
		/* rho1 defaults to 1 if not specified */
		if `rho1' == -99 {
			local rho1 = 1
		}
		if strpos("`corstr'","proportional") > 0 {
			if `rho2' == -99 {
				local rho2 = `rho1'
			}
		}
		else {
			local rho2 = .
		}
		local alpha0 = `tau0'
		local alpha1 = `rho1'
		local alpha2 = `rho2'
	}

	
	/* VALIDITY CHECKS ON CORRELATION PARAMETERS */
	if strpos("`corstr'","nested") > 0 | strpos("`corstr'","block") > 0  {
		foreach i in tau0 tau1 tau2 {
			if ((``i'' > 1 | ``i'' < 0) & ``i'' != .) {
				di as error "`i' must be between 0 and 1"
				exit 198
			}
		}
	}
	else {
	    foreach i in tau0 rho1 rho2 {
			if ((``i'' > 1 | ``i'' < 0) & ``i'' != .) {
				di as error "`i' must be between 0 and 1"
				exit 198
			}
		}
	}
	
	/* RISK RATIO AND ODDS RATIO CHECKS */
	if ("`link'" == "logit" | "`link'" == "log") & `es' <= 0 {
		di as err "Invalid value for risk ratio or odds ratio; must be > 0"
		exit 198
	}
	if ("`link'" == "logit" | "`link'" == "log") & `es' < 0.5 & `es' > 0 {
		di as err "Risk ratio or odds ratio seems low; please make sure you have entered a risk ratio or odds ratio, and not a log-risk ratio or log-odds ratio"
	}
	local es2=`es'
	if "`link'" == "logit" | "`link'" == "log" {
		local es = ln(`es')
	}

	local betas: subinstr local betas " " ", ", all
	         
	mata: swpower(`es',"`design'",`nclusters',`nperiods',`n',`working_ind',"`corstr'","`family'","`link'",(`betas'),`alpha',`alpha0',`alpha1',`alpha2',`phi',`df')
	
	return scalar onesided=0
	return scalar z_power=z_power
	return scalar t_power=t1_power
	return scalar size=`alpha'
	return scalar nclust=`nclusters'
	return scalar nper=`nperiods'
	return scalar n=`n'
	return scalar es=`es2'
	return scalar phi=`phi'
	return scalar working_ind=`working_ind'
	return local corstr "`corstr'"
	return local family "`family'"
	return local link "`link'"
	
	if strpos("`corstr'","nested") > 0 | strpos("`corstr'","block") > 0  {
		return scalar tau0=`tau0'
		return scalar tau1=`tau1'
		return scalar tau2=`tau2'
	}
	else {
		return scalar tau0=`tau0'
		return scalar rho1=`rho1'
		return scalar rho2=`rho2'
	}
	return scalar posdeff=posdeff
	if ("`family'" == "gaussian" | "`family'" == "normal") & "`link'" == "identity" {
	    local betas = .
	}
	matrix betas = (`betas')
	return matrix betas=betas
	local mus: subinstr local mus " " ", ", all
	if ("`family'" == "gaussian" | "`family'" == "normal") & "`link'" == "identity" {
	    local mus = .
	}
	matrix mus = (`mus')
	return matrix mus=mus
	return matrix design=design
	
end 

capture mata: mata drop swpower()
mata:
matrix swpower(scalar delta, string scalar design, scalar I, scalar J, scalar K, scalar working_ind, ///
	string scalar corstr, string scalar family, string scalar link, real vector betas,scalar size, scalar alpha0, ///
	scalar alpha1, scalar alpha2,scalar phi,scalar df) {
	   
	 // DESIGN SPECIFIED BY I AND J  
	 if (design == "0") {
		if (mod(I,(J-1)) == 0) {
			trtSeq = J(I,J,0)
			trtSeqrep = J(I,J,1)
			div=I/(J-1)
			for (i=2; i<=J; i++) {
				div2=(i-1)*div
				trtSeq[1..div2,i]=trtSeqrep[1..div2,i]
			}
			itrt=I
			ctrt=1
		}
		else {
			printf("{err:Design specified with nclusters and nperiods must be such that nclusters is a multiple of the number of sequences because an equal number of clusters are assigned to each sequence. Note that the number of sequences is given by 'nperiods - 1' because all clusters start in the control condition and all end in the treatment condition.}\n")
			exit(198)
		}
	}
	
	// DESIGN ENTERED BY USER
	else if (design != "0") {
		design2 = st_data(.,tokens(design),0)
		if (rows(design2) == I & cols(design2)==J) {
			trtSeq=design2
			itrt=I
			ctrt=1
		}
		else {
			printf("{err:Design specified with nclusters and nperiods must be such that nclusters is a multiple of the number of sequences because an equal number of clusters are assigned to each sequence. Note that the number of sequences is given by 'nperiods - 1' because all clusters start in the control condition and all end in the treatment condition.}\n")
			exit(198)
		}
	}
	
	// TRUE CORRELATION MATRIX
	if (strpos(corstr,"nested") > 0) {
		alpha0=alpha0
		alpha1=alpha1
		R=diag(J(J,J,1))*((1+(K-1):*alpha0)/K-alpha1) + J(J,J,1)*alpha1
	}
	else if (strpos(corstr,"exponential")>0) {
	    tau=alpha0
		rho=alpha1
		decay=rho:^abs(J(J,1,range(0,J-1,1)'):-range(0,J-1,1))
		R = diag(J(J,J,1))*((1+(K-1):*tau)/K) + (decay-diag(J(J,J,1)))*tau
	
	}
	else if (strpos(corstr,"block")>0) {
		alpha0=alpha0
		alpha1=alpha1
		alpha2=alpha2
		R=diag(J(J,J,1))*((1+(K-1):*alpha0)/K-(alpha2+(K-1)*alpha1)/K) + J(J,J,1)*((alpha2+(K-1)*alpha1)/K)
	}
	else if (strpos(corstr,"proportional")>0) {
	    tau=alpha0
		rho0=alpha1
		rho1=alpha2
		decay1=rho1:^abs(J(J,1,range(0,J-1,1)'):-range(0,J-1,1))
		decay0=rho0:^abs(J(J,1,range(0,J-1,1)'):-range(0,J-1,1))
		R=diag(J(J,J,1))*((1+(K-1)*tau)/K) + (decay1-diag(J(J,J,1)))/K + (decay0-diag(J(J,J,1)))*((K-1)*tau/K)
	}
	else {
	   printf("{err:Correlation structure is misspecified}\n")
	   exit(198) 
	}
	
	if (min(symeigenvalues(R)')>0) {
		posdeff=1
		st_numscalar("posdeff",posdeff)
	}
	else {
		posdeff=0
		st_numscalar("posdeff",posdeff)
	}
	
	
	//Model-based variance
	invR=luinv(R)
	//Differences between R and Stata are minimal
	
	omega=J(J+1,J+1,0)
	period=(1..J)'
	
	// NO ROBUST VARIANCE
	if (working_ind==0) {
		for (i=1; i<=itrt; i++) {
			X=trtSeq[i,]'
			
			for (j=1; j<=J; j++) {
				X=X,(period:==j)
			}
			

			
			deltabeta=(delta,betas)'

			
			if (family=="gaussian" | family=="normal") {
				if (link=="identity") {
					mu=X*deltabeta
					W=invR
				}
				else if (link=="log") {
					gmu=X*deltabeta
					mu=exp(gmu)
					mu2=diag(mu)
					W=mu2*invR*mu2
				}
			}
			else if (family=="binomial") {
				if (link=="identity") {
					mu=X*deltabeta
					mu2=diag(sqrt(1:/(mu:*(1:-mu))))
					W=mu2*invR*mu2
				}
				else if (link=="logit") {
					gmu=X*deltabeta
					mu=invlogit(gmu)
					mu2=diag(sqrt(mu:*(1:-mu)))
					W=mu2*invR*mu2
				}
				else if (link=="log") {
					gmu=X*deltabeta
					mu=exp(gmu)
					mu2=diag(sqrt(mu:/(1:-mu)))
					W=mu2*invR*mu2
				}
			}
			else if (family=="poisson") {
				if (link=="identity") {
					mu=X*deltabeta
					mu2=diag(sqrt(1:/mu))
					W=mu2*invR*mu2
				}
				else if (link=="log") {
					gmu=X*deltabeta
					mu=exp(gmu)
					mu2=diag(sqrt(mu))
					W=mu2*invR*mu2
				}
			}
		omega=omega+ctrt:*(X'*W*X):/phi
		
		}
		
		omegaSolve=luinv(omega)
		vardelta=omegaSolve[1,1]
	}
	
	
	// ROBUST VARIANCE
		//use robust variance for independence structure (i.e., tau0=0)
	else if (working_ind==1) {
		invI=diag(J(J,J,1)):*K
		
		omega0=J(J+1,J+1,0)
		omega1=J(J+1,J+1,0)
		for (i=1; i<=itrt; i++) {
			X=trtSeq[i,]'
			
			for (j=1; j<=J; j++) {
				X=X,(period:==j)
			}
			
			deltabeta=(delta,betas)'
			
			if (family=="gaussian" | family=="normal") {
				if (link=="identity") {
					mu=X*deltabeta
					W=invI
					W1=W
					V=R
				}
				else if (link=="log") {
					gmu=X*deltabeta
					mu=exp(gmu)
					mu2=diag(mu)
					W=mu2*invI*mu2
					W1=mu2*invI
					V=R
				}
			}
			else if (family=="binomial") {
				if (link=="identity") {
					mu=X*deltabeta
					mu2=diag(sqrt(1:/(mu:*(1:-mu))))
					W=mu2*invI*mu2
					W1=W
					mu3=diag(sqrt(mu:*(1:-mu)))
					V=mu3*R*mu3
					
				}
				else if (link=="logit") {
					gmu=X*deltabeta
					mu=invlogit(gmu)
					mu2=diag(sqrt(mu:*(1:-mu)))
					W=mu2*invI*mu2
					W1=mu2*invI*diag(sqrt(1:/(mu:*(1:-mu))))
					V=mu2*R*mu2
				}
				else if (link=="log") {
					gmu=X*deltabeta
					mu=exp(gmu)
					mu2=diag(sqrt(mu:/(1:-mu)))
					W=mu2*invI*mu2
					W1=mu2*invI*diag(sqrt(1:/(mu:*(1:-mu))))
					V=diag(sqrt(mu:*(1:-mu)))*R*diag(sqrt(mu:*(1:-mu)))
				}
			}
			else if (family=="poisson") {
				if (link=="identity") {
					mu=X*deltabeta
					mu2=diag(sqrt(1:/mu))
					W=mu2*invI*mu2
					W1=W
					V=diag(sqrt(mu))*R*diag(sqrt(mu))
				}
				else if (link=="log") {
					gmu=X*deltabeta
					mu=exp(gmu)
					mu2=diag(sqrt(mu))
					W=mu2*invI*mu2
					W1=mu2*invI*diag(sqrt(1:/mu))
					V=mu2*R*mu2
				}
			}

		omega1=omega1+ctrt:*(X'*W*X):/phi
		omega0=omega0+ctrt:*(X'W1*V*W1'*X):/phi
		}
		
		invomega1=luinv(omega1)
		solveOmega=invomega1*omega0*invomega1
		vardelta=solveOmega[1,1]
	}
	else {
		printf("{err:Variance parameter is misspecified}\n")
		exit(198)
	}
	z_power=normal(invnormal(size/2)+abs(delta)/sqrt(vardelta))
	t1_power=t(df,invt(df,(size/2))+abs(delta)/sqrt(vardelta))
	
	st_numscalar("z_power", z_power)
	st_numscalar("t1_power", t1_power)
	st_matrix("design",trtSeq)

}
	
end

