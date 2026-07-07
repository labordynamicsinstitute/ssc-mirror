*! version 2.1.1  06jul2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! XTPMG: Enhanced panel ARDL with lag selection, short-run tables, half-life & IRF
*! Fix: predict eq() naming conflict causing r(110) in Stata 15.1+
*! Original: 1.1.1 Ed Blackburne -- Mark Frank, Sam Houston State University, 20 February 2007
*! Fit pooled-mean group, mean group, and dynamic fixed effects panel data models

capture program drop xtpmg
program define xtpmg
	version 15.1
		if replay() {
			if (`"`e(cmd)'"' !="xtpmg") error 301
			Display `0'
		}
		else {
			global xtpmg_cmdline `"xtpmg `0'"'
			Estimate `0'
		}
end

program define Estimate, eclass
	syntax varlist(ts) [if] [in] [,LR(varlist ts) EC(name)				///
      	         	CONSTraints(numlist) noCONStant Level(integer `c(level)')  	///
		     		CLUster(passthru) 							///
		           	TECHnique(passthru) DIFficult REPLACE FULL MG DFE PMG 	///
				MAXLag(integer 4) LAGSel(string) SRTable HALFlife IRF(integer 0) GRaph]

	if ("`mg'"!="")+("`dfe'"!="")+("`pmg'"!="")>1 { 
		di in red "choose only one of pmg, mg or dfe"
		exit 198 
	}

	if ("`full'"!="") & ("`dfe'"!=""){
		di
		di in ye "full option not meaningful with dfe"
		di in ye "ignoring option and continuing..."
	}

	if ("`cluster'"!="") & ("`dfe'"==""){
		di
		di in ye "cluster option only meaningful with dfe"
		di in ye "ignoring option and continuing..."

	} 
	
	* Validate lagsel option
	if "`lagsel'" != "" {
		if !inlist("`lagsel'", "aic", "bic", "both") {
			di as err "lagsel() must be one of: aic, bic, both"
			exit 198
		}
	}
	
	* Warn if maxlag is specified but lagsel is not
	if "`lagsel'" == "" & `maxlag' != 4 {
		di in ye "Note: maxlag(`maxlag') specified without lagsel(). Add lagsel(aic), lagsel(bic), or lagsel(both) to enable automatic lag selection."
	}
	
	* Validate maxlag
	if `maxlag' < 1 | `maxlag' > 8 {
		di as err "maxlag() must be between 1 and 8"
		exit 198
	}
	
	* Validate irf
	if `irf' < 0 | `irf' > 50 {
		di as err "irf() must be between 0 and 50"
		exit 198
	}

	if "`lr'"!=""{
		if "`ec'"==""{
      		local ec ECT
	      }
		if "`replace'"!=""{
			capture drop `ec'
		}

		capture confirm new variable `ec'
		if _rc!=0{
			di as err "Variable `ec' already exists."
			di as err "Either drop the variable, use the replace option, or specify another name in ec()."
			exit 110
		}

	}

	global constraints `constraints'
	marksample touse
	tempname T_i
	quie count if `touse'
	tempname N
	scalar `N'=r(N)
	qui tsset
	local ivar `r(panelvar)'
	local tvar `r(timevar)'
	capture macro drop nocons LRy LRx SRy SRx ARDL_display ARDL_order_p
	tokenize `varlist'
	global SRy `1'
	mac shift
	global SRx `*'
	global cluster "`cluster'"
	if "`lr'"!=""{
		tokenize `lr'
		global LRy `1'
      	mac shift
		global LRx `*'
	}

	quie levels `ivar' if `touse', local(ids)
	global iis "`ids'"

	global nocons "`constant'"
	
	* =====================================================================
	* AUTOMATIC LAG SELECTION (if lagsel specified)
	* =====================================================================
	
	if "`lagsel'" != "" & "`lr'" != "" {
		SelectLags if `touse', maxlag(`maxlag') lagsel(`lagsel') ivar(`ivar') tvar(`tvar')
		* Results stored in globals: $ARDL_order, $ARDL_display
	}
	else if "`lr'" != "" {
		* Infer ARDL order from the actual variables in the model
		InferARDLOrder
	}

	if "`mg'"!=""{
		EstMG if `touse', level(`level') ec(`ec') `full' ///
			srtable(`srtable') halflife(`halflife') irf(`irf') graph(`graph')
		exit
	}

	if "`dfe'"!=""{
		EstDFE if `touse', level(`level') ec(`ec') graph(`graph')
		exit
	}

	if "`lr'"!=""{	
		quie regress $LRy $LRx if `touse', noconstant
		tempname b0 theta xb thV
		matrix `b0'=e(b)
		ml model d0 xtpmg_ml ($LRy = $LRx, noconstant) if `touse', init(`b0') 	///
		`difficult' `technique' search(off) max
		matrix `theta'=e(b)
		matrix `thV'=e(V)
		quie predict double `xb' if `touse'
		quie gen double `ec'=$LRy-`xb' if `touse' 		
		matrix `thV'=J(1,colsof(e(b)),.) \ `thV'
		matrix `thV'=J(colsof(e(b))+1,1,.) , `thV'
	}
	

	quie count if `touse'
	tempname kl ks

	scalar `kl'=wordcount("$LRx")
	scalar `ks'=wordcount("$SRx")

	if "`constant'"==""{
		scalar `ks'=`ks'+1	
	}
	
	if "`lr'"!=""{
		scalar `ks'=`ks'+1
	}
	tempname n g1 g2 g3 
	local n=wordcount("$iis")
	scalar `g2'=r(N)/`n'
	scalar `g1'=r(N)
	scalar `g3'=0
	tempname param n_sig phi sig sigs xpx cpsr cplr B
	local names
	if "`lr'"!=""{
		foreach x in $LRx{
	 		local names `names' "`ec':`x'"
		}
	}

	local j=1
	tempname ll	
	scalar `ll'=0
	
	* Store per-panel SR coefficients for SRTable
	tempname SR_all PHI_all

// setup initial matrices
  
	tempname G
	matrix `G'=J(`n'*(`ks'),`n'*(`ks'),0)
	if "`lr'"!=""{
		tempname Grow Gxx phis phihat phi_se b_mg V_mg tmp
		matrix `Gxx'=J(`kl',`kl',0) 
	}
	tempname r
	quie gen double `r'=.

// Loop through all panels for regressions
// Also, we fix equation labels within this loop

	foreach i of global iis{
		tempvar `r'`i'
		if "`lr'"!=""{      	
			local names `names' "`ivar'_`i':`ec'"
		}
		foreach x in  $SRx{
           	local names `names' "`ivar'_`i':`x'"
		}
     		if "`constant'"==""{
     			local names `names' "`ivar'_`i':_cons"
		}
		quie count if `touse' & `ivar'==`i'
		scalar `g1'=cond(r(N)<scalar(`g1'),r(N),scalar(`g1'))
		scalar `g3'=cond(r(N)>scalar(`g3'),r(N),scalar(`g3'))
		quie regress $SRy `ec' $SRx if `touse' & `ivar'==`i', `constant'
		quie predict double `r'`i' if `touse' & `ivar'==`i', resid
		quie replace `r'=`r'`i' if `touse' & `ivar'==`i'
		matrix `B'=nullmat(`B') \ e(b)
		scalar `ll'=scalar(`ll')+e(ll)
		scalar `sig'=e(rss)/e(N)			
		matrix `sigs'=nullmat(`sigs') \ `sig'

		if "`lr'"!=""{
			scalar `phi'=_b[`ec']
			matrix `phis'=nullmat(`phis') \ `phi'
			quie matrix accum `xpx'=$LRx if `touse' & `ivar'==`i', nocons
			matrix `Gxx'=`Gxx'+`xpx'*(`phi'^2/`sig')		
			quie matrix accum `cplr'=$LRx `ec' $SRx if `touse' & `ivar'==`i', `constant'
			matrix `cplr'=`cplr'[1..`kl',`kl'+1...]
			matrix `Grow'=(nullmat(`Grow'), -(`phi'/`sig')*`cplr')
		}  

		matrix `param'=nullmat(`param') , e(b)
		quie matrix accum `cpsr'=`ec' $SRx if `touse' & `ivar'==`i', `constant'
		matrix `G'[(`j'-1)*(`ks')+1,(`j'-1)*(`ks')+1]=`cpsr'/(`sig')
		local j=`j'+1
	}

	if "`lr'"!=""{
		matrix `G'=`Grow' \ `G'
		matrix `G'=((`Gxx' \ `Grow''), `G')
	
	}

	tempname b V bicp seicp
	matrix `V'=syminv(`G')
	matrix `thV'=`V'[1..`kl',1..`kl']
	matrix `b'=nullmat(`theta'), `param' 
	matrix colnames `V'=`names'
	matrix rownames `V'=`names'
	matrix colnames `b'=`names'
	matrix rownames `sigs'=$iis
	matrix colnames `sigs'="Variance"	
	eret post `b' `V', esample(`touse')
	* --- per-panel coefficient/SE matrices for estat (2.1.1) ---
	capture mata: xtpmg_split("e(b)","e(V)", `=scalar(`kl')', `=scalar(`ks')', `n')
	local coef_i "`ec' $SRx"
	if "`constant'"=="" local coef_i "`coef_i' _cons"
	capture matrix rownames __xtpmg_bi = $iis
	capture matrix rownames __xtpmg_sei = $iis

// Handle any constraints. However, much like reg3, this will
// fail if the unconstrained model is not identified since these constraints
// are applied post estimation.
// Note: The displayed log-likelihood is from the UNrestricted model

	capture{
		if "$constraints"!=""{
			CalcConst $constraints
			di in gr _n "The following constraints have been applied to the system:"
			matrix dispCns
		}
	}
	
	matrix `b'=e(b)
	matrix `V'=e(V)

	CalcMGE `B' `V'

	tempname v0 v1 k0 k1
	
	matrix `B'=nullmat(`theta'), `B'
	local k0=colsof(`thV')
	local k1=colsof(`V')
	
	matrix `v0'=`thV', J(`k0',`k1',0)
	matrix `v1'=J(`k1',`k0',0),`V'
	matrix `V'=`v0' \ `v1'
	
	* --- Cross-sectional dependence test on residuals (Pesaran CD) ---
	tempvar _cdres
	quie gen double `_cdres'=`r' if e(sample)
	tempname cdstat cdp cdavg
	capture XtpmgCD `_cdres'
	scalar `cdstat'=r(CD)
	scalar `cdp'=r(pCD)
	scalar `cdavg'=r(CDavg)
	quie replace `r'=`r'^2
	quie sum `r' if e(sample)
	ereturn scalar sigma=r(mean)
	ereturn scalar N=`N'
	ereturn scalar n_g=`n'
	ereturn scalar g_min=`g1'
	ereturn scalar g_avg=`g2'
	ereturn scalar g_max=`g3'
	ereturn matrix sig2_i=`sigs'
	ereturn matrix MGE_b=`B'
	ereturn matrix MGE_V=`V'
	ereturn local depvar="$SRy"
	ereturn local ivar="`ivar'"
	ereturn local tvar="`tvar'"
	ereturn local cmd="xtpmg"
	ereturn local model="PMG"
	ereturn local estat_cmd "xtpmg_estat"
	ereturn local cmdline "$xtpmg_cmdline"
	ereturn scalar ll=scalar(`ll')
	ereturn scalar CD=`cdstat'
	ereturn scalar p_CD=`cdp'
	ereturn scalar CD_avg=`cdavg'
	
	* Store ARDL order if lag selection was used
	if "$ARDL_display" != "" {
		ereturn local ardl_order "$ARDL_display"
	}
	
	* Store phis for half-life
	if "`lr'" != "" {
		capture matrix rownames `phis'=$iis
		ereturn matrix phi_i=`phis'
	}
	capture matrix `bicp'=__xtpmg_bi
	capture ereturn matrix b_i=`bicp'
	capture matrix `seicp'=__xtpmg_sei
	capture ereturn matrix se_i=`seicp'
	ereturn local coef_i "`coef_i'"

	quie est store PMG, copy title("Full pmg estimates")
	matrix `b'=e(MGE_b)
	matrix `V'=e(MGE_V)

	local names
	foreach x of global LRx{
		local names `names' "`ec':`x'"
	}
	local names `names' "SR:`ec'"
	foreach x of global SRx{
		local names `names' "SR:`x'"
	}
	if "$nocons"==""{
		local names `names' "SR:_cons"
	}
	matrix colnames `b'=`names'
	matrix colnames `V'=`names'
	matrix rownames `V'=`names'

	quie gen byte `touse'=e(sample)
	eret post `b' `V', esample(`touse')
	capture{
		if "$constraints"!=""{
			CalcConst $constraints
			di in gr _n "The following constraints have been applied to the system:"
			matrix dispCns
		}
	}

	ereturn scalar sigma=r(mean)
	ereturn scalar N=`N'
	ereturn scalar n_g=`n'
	ereturn scalar g_min=`g1'
	ereturn scalar g_avg=`g2'
	ereturn scalar g_max=`g3'
	matrix `sigs'=e(sig2_i)
	ereturn matrix sig2_i=`sigs'
	ereturn local depvar="$SRy"
	ereturn local ivar="`ivar'"
	ereturn local tvar="`tvar'"
	ereturn local cmd="xtpmg"
	ereturn local model="pmg"
	ereturn local estat_cmd "xtpmg_estat"
	ereturn local cmdline "$xtpmg_cmdline"
	capture matrix `bicp'=__xtpmg_bi
	capture ereturn matrix b_i=`bicp'
	capture matrix `seicp'=__xtpmg_sei
	capture ereturn matrix se_i=`seicp'
	ereturn local coef_i "`coef_i'"
	ereturn scalar ll=scalar(`ll')
	ereturn scalar CD=`cdstat'
	ereturn scalar p_CD=`cdp'
	ereturn scalar CD_avg=`cdavg'
	
	if "$ARDL_display" != "" {
		ereturn local ardl_order "$ARDL_display"
	}
	
	quie est store pmg, copy title("Summarized pmg estimates")

	if "`full'" !=""{
		quie est restore PMG
	}

	Display, level(`level')
	capture noisily XtpmgShowCSD
	
	* =====================================================================
	* POST-ESTIMATION DIAGNOSTICS (new in 2.1.1)
	* =====================================================================
	
	* Short-run table for each panel
	if "`srtable'" != "" {
		quie est restore PMG
		DisplaySRTable, ivar(`ivar')
	}
	
	* Half-life computation
	if "`halflife'" != "" {
		quie est restore PMG
		DisplayHalfLife, ivar(`ivar') ec(`ec')
	}
	
	* Impulse response function
	if `irf' > 0 {
		quie est restore PMG
		SimulateIRF, periods(`irf') ivar(`ivar') ec(`ec')
	}
	
	* =====================================================================
	* GRAPH VISUALIZATIONS (new in 2.1.1)
	* =====================================================================
	
	if "`graph'" != "" {
		quie est restore PMG
		
		di
		di in smcl in gr "{hline 78}"
		di in gr "{bf:Generating Visualizations}" _col(49) in ye "XTPMG 2.1.1"
		di in smcl in gr "{hline 78}"
		
		* 1. ECT bar chart (always available with full or graph)
		PlotECT, ivar(`ivar') ec(`ec')
		
		* 2. Half-life chart
		PlotHalfLife, ivar(`ivar') ec(`ec')
		
		* 3. IRF plot (if irf periods specified)
		if `irf' > 0 {
			PlotIRF, periods(`irf') ivar(`ivar') ec(`ec')
		}
		
		* 4. Short-run coefficient plot (if full specified)
		if "`full'" != "" {
			PlotSRCoefs, ivar(`ivar') ec(`ec')
		}
		
		* 5. Long-run coefficient plot (dot-and-whisker)
		PlotLRCoefs, ec(`ec')
		
		* 6. Combined professional dashboard
		PlotDashboard, periods(`irf')
		
		di in smcl in gr "{hline 78}"
		di
	}
	
	* Restore the user's preferred model
	if "`full'" != "" {
		quie est restore PMG
	}
	else {
		quie est restore pmg
	}
end

program define EstMG, eclass
	syntax [if] [in], EC(string) [Level(integer `c(level)') FULL ///
		SRTable(string) HALFlife(string) IRF(integer 0) GRaph(string)] 
	marksample touse
	qui xtset
	local ivar "`r(panelvar)'"
	local tvar "`r(timevar)'"
	tempname nl N names
	quie count if `touse'
	local N=r(N)
	tempname n g1 g2 g3 
	local n=wordcount("$iis")
	scalar `g2'=r(N)/`n'
	scalar `g1'=r(N)
	scalar `g3'=0
	local nl
	local names
	foreach x of global LRx{
		local nl `nl' (-_b[`x']/_b[$LRy])	
		local names `names' "`ec':`x'"
	}
	local nl `nl' (_b[$LRy])
	local names `names' "SR:`ec'"
	foreach x of global SRx{
		local nl `nl' (_b[`x'])
		local names `names' "SR:`x'"
	}
	if "$nocons"==""{
		local nl `nl' (_b[_cons])
		local names `names' "SR:_cons"
	}

	tempname B V r ll sig2 xb r 
	scalar `ll'=0
	quie generate `r'=.
	tempname b0 v0 VV kk new_name

	local kk=wordcount("$LRy $LRx $SRx")

	if "$nocons"==""{
		local kk=`kk'+1
	}

	matrix `VV'=J(`kk'*`n',`kk'*`n',0)
	tempname phis phi_one phcopy1 phcopy2 bicp seicp
	local j=1
	
	foreach i of global iis{
		tempvar `r'`i'
		quie count if `touse' & `_dta[iis]'==`i'
		scalar `g1'=cond(r(N)<scalar(`g1'),r(N),scalar(`g1'))
		scalar `g3'=cond(r(N)>scalar(`g3'),r(N),scalar(`g3'))
		quie regress $SRy $LRy $LRx $SRx if `touse' & `_dta[iis]'==`i', $nocons
		quie predict double `r'`i' if `touse' & `_dta[iis]'==`i', resid
		quie replace `r'=`r'`i' if `touse' & `_dta[iis]'==`i'
		scalar `ll'=`ll'+e(ll)
		quie nlcom `nl', level(`level') post
		tempname b V
		matrix `b'=e(b)
		matrix `V'=e(V)
		scalar `phi_one'=`b'[1,`=wordcount("$LRx")'+1]
		matrix `phis'=nullmat(`phis') \ `phi_one'
		matrix colnames `b'=`names'
		foreach xx of local names{
			local newname "`newname' `_dta[iis]'_`i'`xx'"
		}
		matrix `b0'=nullmat(`b0'),`b'
		matrix `VV'[(`j'-1)*(`kk')+1,(`j'-1)*(`kk')+1]=`V'
		matrix `B'=nullmat(`B') \ `b'
		local j=`j'+1
	}

	capture matrix rownames `phis'=$iis
	* --- per-panel coefficient/SE matrices for estat (2.1.1) ---
	capture mata: xtpmg_split("`b0'","`VV'", 0, `kk', `n')
	local coef_i "$LRx `ec' $SRx"
	if "$nocons"=="" local coef_i "`coef_i' _cons"
	capture matrix rownames __xtpmg_bi = $iis
	capture matrix rownames __xtpmg_sei = $iis
	matrix colnames `VV'= `newname'
	matrix rownames `VV'= `newname'
	matrix colnames `b0'= `newname'
	CalcMGE `B' `V'
	eret post `B' `V', esample(`touse')
	if "$constraints"!=""{
		capture{
			CalcConst $constraints
			di in gr _n "The following constraints have been applied to the system:"
			matrix dispCns
		}
	}
	quie gen byte `touse'=e(sample)

	* --- Safe EC prediction (Stata 15+ compatible) ---
	* The original line was:
	*   quie predict double `ec' if `touse', eq(`ec')
	* This fails in Stata 15.1+ because _predict now errors when the
	* output variable name matches a variable in the estimation results.
	* Fix: predict into a temporary variable, then copy to requested name.
	tempvar ectmp
	quie predict double `ectmp' if `touse', eq(`ec')
	quie gen double `ec' = `ectmp' if `touse'

	quie replace `ec'=$LRy-`ec'
	tempvar _cdres
	quie gen double `_cdres'=`r' if `touse'
	tempname cdstat cdp cdavg
	capture XtpmgCD `_cdres'
	scalar `cdstat'=r(CD)
	scalar `cdp'=r(pCD)
	scalar `cdavg'=r(CDavg)
	quie replace `r'=`r'^2 if `touse'
	quie sum `r' if `touse'
	scalar `sig2'=r(mean)
	ereturn scalar sigma=`sig2'
	ereturn scalar ll=`ll'
	ereturn scalar N=`N'
	ereturn scalar n_g=`n'
	ereturn scalar g_min=`g1'
	ereturn scalar g_avg=`g2'
	ereturn scalar g_max=`g3'
	ereturn local depvar="$SRy"
	ereturn local ivar="`ivar'"
	ereturn local tvar="`tvar'"
	ereturn local cmd="xtpmg"	
	ereturn local model="mg"
	ereturn local estat_cmd "xtpmg_estat"
	ereturn local cmdline "$xtpmg_cmdline"
	ereturn scalar CD=`cdstat'
	ereturn scalar p_CD=`cdp'
	ereturn scalar CD_avg=`cdavg'
	capture matrix `phcopy1'=`phis'
	capture ereturn matrix phi_i=`phcopy1'
	capture matrix `bicp'=__xtpmg_bi
	capture ereturn matrix b_i=`bicp'
	capture matrix `seicp'=__xtpmg_sei
	capture ereturn matrix se_i=`seicp'
	ereturn local coef_i "`coef_i'"
	
	if "$ARDL_display" != "" {
		ereturn local ardl_order "$ARDL_display"
	}
	
	quie est store mg, copy	title("Summarized mg estimates")
	eret post `b0' `VV', esample(`touse')
	if "$constraints"!=""{
		capture{
			CalcConst $constraints
			di in gr _n "The following constraints have been applied to the system:"
			matrix dispCns
		}
	}
	ereturn scalar sigma=`sig2'
	ereturn scalar ll=`ll'
	ereturn scalar N=`N'
	ereturn scalar n_g=`n'
	ereturn scalar g_min=`g1'
	ereturn scalar g_avg=`g2'
	ereturn scalar g_max=`g3'
	ereturn local ivar="`ivar'"
	ereturn local depvar="$SRy"
	ereturn local tvar="`tvar'"
	ereturn local cmd="xtpmg"	
	ereturn local model="MG"
	ereturn local estat_cmd "xtpmg_estat"
	ereturn local cmdline "$xtpmg_cmdline"
	ereturn scalar CD=`cdstat'
	ereturn scalar p_CD=`cdp'
	ereturn scalar CD_avg=`cdavg'
	capture matrix `phcopy2'=`phis'
	capture ereturn matrix phi_i=`phcopy2'
	capture matrix `bicp'=__xtpmg_bi
	capture ereturn matrix b_i=`bicp'
	capture matrix `seicp'=__xtpmg_sei
	capture ereturn matrix se_i=`seicp'
	ereturn local coef_i "`coef_i'"
	
	if "$ARDL_display" != "" {
		ereturn local ardl_order "$ARDL_display"
	}
	
	quie est store MG, copy title("Full mg estimates")
	if "`full'"==""{
		quie est restore mg
	}
	Display, level(`level')
	capture noisily XtpmgShowCSD
	
	* --- Post-estimation diagnostics for MG (uses e(phi_i)) ---
	if "`halflife'" != "" {
		quie est restore mg
		DisplayHalfLife, ivar(`ivar') ec(`ec')
	}
	if `irf' > 0 {
		quie est restore mg
		SimulateIRF, periods(`irf') ivar(`ivar') ec(`ec')
	}
	if "`srtable'" != "" {
		di in ye "  Note: srtable (per-panel SR) is available for the pmg model only."
	}
	if "`graph'" != "" {
		quie est restore mg
		PlotECT, ivar(`ivar') ec(`ec')
		PlotHalfLife, ivar(`ivar') ec(`ec')
		PlotLRCoefs, ec(`ec')
		if `irf' > 0 {
			PlotIRF, periods(`irf') ivar(`ivar') ec(`ec')
		}
		PlotDashboard, periods(`irf')
	}
	if "`full'"!=""{
		quie est restore MG
	}
	else {
		quie est restore mg
	}
end

program define EstDFE, eclass
	syntax [if] [in], EC(string) [Level(integer `c(level)') GRaph(string)] 
	marksample touse
	qui xtset
	local ivar "`r(panelvar)'"
	local tvar "`r(timevar)'"
	tempname nl names sigma
	quie xtreg $SRy $LRy $LRx $SRx if `touse', level(`level') fe $cluster
	quie est store rDFE, copy title("Reduced form dfe estimates")
	tempvar _cdres
	capture predict double `_cdres' if `touse', e
	tempname cdstat cdp cdavg
	capture XtpmgCD `_cdres'
	scalar `cdstat'=r(CD)
	scalar `cdp'=r(pCD)
	scalar `cdavg'=r(CDavg)
	scalar `sigma'=e(sigma)
	local nl
	local names
	foreach x of global LRx{
		local nl `nl' (-_b[`x']/_b[$LRy])	
		local names `names' "`ec':`x'"
	}

	local nl `nl' (_b[$LRy])
	local names `names' "SR:`ec'"
	foreach x of global SRx{
		local nl `nl' (_b[`x'])
		local names `names' "SR:`x'"
	}
	if "$nocons"==""{
		local nl `nl' (_b[_cons])
		local names `names' "SR:_cons"
	}
	quie nlcom `nl', level(`level') post
	tempname b V
	matrix `b'=r(b)
	matrix `V'=r(V)
	matrix colnames `b'=`names'
	matrix colnames `V'=`names'
	matrix rownames `V'=`names'
	eret post `b' `V', esample(`touse')

// Handle any constraints. However, like reg3, this will
// fail if the unconstrained model is not identified since these constraints
// are applied post estimation.
// Note: The displayed log-likelihood is from the UNrestricted model
	
	if "$constraints"!=""{
		CalcConst $constraints
		di in gr _n "The following constraints have been applied to the system:"
		matrix dispCns
	}

	eret local cmd="xtpmg" 
	eret local model="dfe"
	eret local estat_cmd "xtpmg_estat"
	eret local cmdline "$xtpmg_cmdline"
	eret scalar sigma=`sigma' 
	eret scalar CD=`cdstat'
	eret scalar p_CD=`cdp'
	eret scalar CD_avg=`cdavg'
	
	if "$ARDL_display" != "" {
		eret local ardl_order "$ARDL_display"
	}
	
	quie est store DFE, title("Dynamic fixed effects estimates")
	Display, level(`level')
	capture noisily XtpmgShowCSD
	if "`graph'" != "" {
		PlotLRCoefs, ec(`ec')
	}
end


program define CalcConst
	args constraint
	tempname A bc C IAR j R Vc touse
	matrix makeCns `constraint'
	matrix `C' = get(Cns)
	local cdim = colsof(`C')
	local cdim1 = `cdim' - 1
	matrix `R' = `C'[1...,1..`cdim1']
	matrix `A' = syminv(`R'*get(VCE)*`R'')
	local a_size = rowsof(`A')
	scalar `j' = 1
	while `j' <= `a_size' {
		if `A'[`j',`j'] == 0 {
			error 412
		} 
		scalar `j' = `j' + 1
	}
	matrix `A' = get(VCE)*`R''*`A'
	matrix `IAR' = I(colsof(get(VCE))) - `A'*`R'
	matrix `bc' = get(_b) * `IAR'' + `C'[1...,`cdim']'*`A''
	matrix `Vc' = `IAR' * get(VCE) * `IAR''
	gen byte `touse' = e(sample)
	eret post `bc' `Vc' `C', esample(`touse')
end

program define CalcMGE
	args b V
	tempname n tmp names j touse rec_n 
	local n=rowsof(`b')
	local names: colfullnames `b'
	scalar `rec_n'=1/`n'
	matrix `tmp'=`b'-J(`n',1,1)#(J(1,`n',`rec_n')*`b')
	matrix coleq `tmp'=:
	matrix roweq `tmp'=:

// JASA 1999 paper has a typo - the correct variance is below

	matrix `V'=`tmp''*`tmp'/(`n'*(`n'-1))
	matrix `b'=J(1,`n',`rec_n')*`b'
	matrix rownames `b'="MGE"
	matrix colnames `b'=`names'
	matrix rownames `V'=`names'
	matrix colnames `V'=`names'	
end


* =========================================================================
* NEW IN 2.1.1: SelectLags — Automatic lag selection via AIC/BIC
* Searches over ARDL(p, q1, ..., qk) and MODIFIES $SRx accordingly
* =========================================================================

program define SelectLags
	syntax [if] [in], MAXLag(integer) LAGSel(string) IVar(string) TVar(string)
	marksample touse
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Automatic Lag Selection}" _col(49) in ye "XTPMG 2.1.1"
	di in smcl in gr "{hline 78}"
	di in gr "  Criterion:    " in ye upper("`lagsel'")
	di in gr "  Max lag:      " in ye "`maxlag'"
	di in gr "  Dep. var (y): " in ye "$SRy"
	di in gr "  SR vars (x):  " in ye "$SRx"
	di in gr "  LR vars:      " in ye "$LRx"
	di in smcl in gr "{hline 78}"
	di
	
	local nlr = wordcount("$LRx")
	
	* ---- Identify base names of SR x-variables (strip ts operators) ----
	local sr_base_names ""
	foreach sx of global SRx {
		local bname "`sx'"
		local bname = subinstr("`bname'", "D.", "", .)
		local bname = subinstr("`bname'", "d.", "", .)
		local bname = subinstr("`bname'", "D1.", "", .)
		local bname = subinstr("`bname'", "d1.", "", .)
		local bname = subinstr("`bname'", "L.", "", .)
		local bname = subinstr("`bname'", "l.", "", .)
		local bname = subinstr("`bname'", "L1.", "", .)
		local bname = subinstr("`bname'", "l1.", "", .)
		local sr_base_names "`sr_base_names' `bname'"
	}
	
	* Get unique base names for x variables
	local unique_x ""
	foreach bn of local sr_base_names {
		local found 0
		foreach ux of local unique_x {
			if "`ux'" == "`bn'" local found = 1
		}
		if `found' == 0 {
			local unique_x "`unique_x' `bn'"
		}
	}
	local n_xvars = wordcount("`unique_x'")
	
	* ---- Fix a COMMON estimation sample across all candidate lag orders ----
	* AIC/BIC are comparable only when every candidate uses the same obs.
	* Require the deepest lag terms (order maxlag) to be present.
	tempvar csample
	qui gen byte `csample' = `touse'
	local _deep = `maxlag' - 1
	capture qui replace `csample' = 0 if missing(L`_deep'.$SRy)
	foreach xvar of local unique_x {
		capture qui replace `csample' = 0 if missing(L`_deep'D.`xvar')
	}
	
	* ---- Storage for per-panel results ----
	tempname best_aic best_bic curr_aic curr_bic
	
	* For dependent variable lag (p): search over p = 1..maxlag
	local all_p_aic ""
	local all_p_bic ""
	
	* For each x variable lag (qi): search over qi = 1..maxlag
	* Store per-panel best qi for each x variable
	forvalues xidx = 1/`n_xvars' {
		local all_q`xidx'_aic ""
		local all_q`xidx'_bic ""
	}
	
	* ---- Display header ----
	di in smcl in gr "{hline 78}"
	di in gr "  Panel   " _col(12) "{c |}" ///
		_col(14) " Best p(AIC)" ///
		_col(28) "   AIC value" ///
		_col(43) " Best p(BIC)" ///
		_col(57) "   BIC value"
	di in smcl in gr "{hline 11}{c +}{hline 66}"
	
	* ---- Loop through each panel ----
	foreach i of global iis {
		
		* Count obs for this panel
		quie count if `touse' & `ivar' == `i'
		local ni = r(N)
		
		* ============================================================
		* STEP 1: Search over p (dep var lag) — fix q's at 1
		* ============================================================
		scalar `best_aic' = .
		scalar `best_bic' = .
		local best_p_aic_i = 1
		local best_p_bic_i = 1
		
		forvalues p = 1/`maxlag' {
			* Build lagged diffs of dependent: L.d.y, L2.d.y, ..., L(p-1).d.y
			local deplag ""
			if `p' > 1 {
				forvalues lag = 1/`= `p' - 1' {
					local deplag "`deplag' L`lag'.$SRy"
				}
			}
			
			* Estimate with this lag structure
			capture quie regress $SRy `deplag' $LRx $SRx ///
				if `csample' & `ivar' == `i', $nocons
			
			if !_rc & e(N) > 0 {
				local k_params = e(rank)
				scalar `curr_aic' = -2 * e(ll) + 2 * `k_params'
				scalar `curr_bic' = -2 * e(ll) + `k_params' * ln(e(N))
				
				if scalar(`curr_aic') < scalar(`best_aic') {
					scalar `best_aic' = scalar(`curr_aic')
					local best_p_aic_i = `p'
				}
				if scalar(`curr_bic') < scalar(`best_bic') {
					scalar `best_bic' = scalar(`curr_bic')
					local best_p_bic_i = `p'
				}
			}
		}
		
		local all_p_aic "`all_p_aic' `best_p_aic_i'"
		local all_p_bic "`all_p_bic' `best_p_bic_i'"
		
		* Display row
		di in gr %10s "`i'" _col(12) " {c |}" ///
			_col(20) in ye %5.0f `best_p_aic_i' ///
			_col(28) in ye %12.2f scalar(`best_aic') ///
			_col(49) in ye %5.0f `best_p_bic_i' ///
			_col(57) in ye %12.2f scalar(`best_bic')
		
		* ============================================================
		* STEP 2: Search over qi for each x variable
		*   Use the panel's best p from STEP 1 to build dep-var lags
		* ============================================================
		
		* Build dep-var lags from this panel's best p (AIC)
		local deplag_aic ""
		if `best_p_aic_i' > 1 {
			forvalues lag = 1/`= `best_p_aic_i' - 1' {
				local deplag_aic "`deplag_aic' L`lag'.$SRy"
			}
		}
		* Build dep-var lags from this panel's best p (BIC)
		local deplag_bic ""
		if `best_p_bic_i' > 1 {
			forvalues lag = 1/`= `best_p_bic_i' - 1' {
				local deplag_bic "`deplag_bic' L`lag'.$SRy"
			}
		}
		
		local xidx = 0
		foreach xvar of local unique_x {
			local xidx = `xidx' + 1
			
			scalar `best_aic' = .
			scalar `best_bic' = .
			local best_q_aic_i = 1
			local best_q_bic_i = 1
			
			forvalues q = 0/`maxlag' {
				* Build: d.x, Ld.x, L2d.x, ..., L(q-1)d.x
				* q=0 means NO contemporaneous diff (exclude this x from SR)
				local xlag ""
				if `q' > 0 {
					local xlag "d.`xvar'"
					if `q' > 1 {
						forvalues lag = 1/`= `q' - 1' {
							local xlag "`xlag' L`lag'D.`xvar'"
						}
					}
				}
				
				* Build the rest of the SR vars (other x's at contemporaneous only)
				local other_sr ""
				foreach ox of local unique_x {
					if "`ox'" != "`xvar'" {
						local other_sr "`other_sr' d.`ox'"
					}
				}
				
				* --- AIC search: use dep-var lags from AIC-optimal p ---
				capture quie regress $SRy `deplag_aic' $LRx `xlag' `other_sr' ///
					if `csample' & `ivar' == `i', $nocons
				
				if !_rc & e(N) > 0 {
					local k_params = e(rank)
					scalar `curr_aic' = -2 * e(ll) + 2 * `k_params'
					
					if scalar(`curr_aic') < scalar(`best_aic') {
						scalar `best_aic' = scalar(`curr_aic')
						local best_q_aic_i = `q'
					}
				}
				
				* --- BIC search: use dep-var lags from BIC-optimal p ---
				capture quie regress $SRy `deplag_bic' $LRx `xlag' `other_sr' ///
					if `csample' & `ivar' == `i', $nocons
				
				if !_rc & e(N) > 0 {
					local k_params = e(rank)
					scalar `curr_bic' = -2 * e(ll) + `k_params' * ln(e(N))
					
					if scalar(`curr_bic') < scalar(`best_bic') {
						scalar `best_bic' = scalar(`curr_bic')
						local best_q_bic_i = `q'
					}
				}
			}
			
			local all_q`xidx'_aic "`all_q`xidx'_aic' `best_q_aic_i'"
			local all_q`xidx'_bic "`all_q`xidx'_bic' `best_q_bic_i'"
		}
	}
	
	di in smcl in gr "{hline 11}{c +}{hline 66}"
	
	* ---- Find modal lag orders ----
	
	* Modal p (AIC)
	local mode_p_aic = 1
	local mode_p_aic_cnt = 0
	forvalues p = 1/`maxlag' {
		local cnt = 0
		foreach pp of local all_p_aic {
			if `pp' == `p' local cnt = `cnt' + 1
		}
		if `cnt' > `mode_p_aic_cnt' {
			local mode_p_aic = `p'
			local mode_p_aic_cnt = `cnt'
		}
	}
	
	* Modal p (BIC)
	local mode_p_bic = 1
	local mode_p_bic_cnt = 0
	forvalues p = 1/`maxlag' {
		local cnt = 0
		foreach pp of local all_p_bic {
			if `pp' == `p' local cnt = `cnt' + 1
		}
		if `cnt' > `mode_p_bic_cnt' {
			local mode_p_bic = `p'
			local mode_p_bic_cnt = `cnt'
		}
	}
	
	* Modal qi for each x (AIC and BIC)
	local q_aic_str ""
	local q_bic_str ""
	forvalues xidx = 1/`n_xvars' {
		local mode_q_aic = 0
		local mode_q_aic_cnt = 0
		forvalues q = 0/`maxlag' {
			local cnt = 0
			foreach qq of local all_q`xidx'_aic {
				if `qq' == `q' local cnt = `cnt' + 1
			}
			if `cnt' > `mode_q_aic_cnt' {
				local mode_q_aic = `q'
				local mode_q_aic_cnt = `cnt'
			}
		}
		local q_aic_str "`q_aic_str' `mode_q_aic'"
		
		local mode_q_bic = 0
		local mode_q_bic_cnt = 0
		forvalues q = 0/`maxlag' {
			local cnt = 0
			foreach qq of local all_q`xidx'_bic {
				if `qq' == `q' local cnt = `cnt' + 1
			}
			if `cnt' > `mode_q_bic_cnt' {
				local mode_q_bic = `q'
				local mode_q_bic_cnt = `cnt'
			}
		}
		local q_bic_str "`q_bic_str' `mode_q_bic'"
	}
	
	* ---- Choose which criterion to use ----
	if "`lagsel'" == "aic" | "`lagsel'" == "both" {
		local chosen_p = `mode_p_aic'
		local chosen_q "`q_aic_str'"
	}
	else {
		local chosen_p = `mode_p_bic'
		local chosen_q "`q_bic_str'"
	}
	
	* ---- Build ARDL(p, q1, q2, ...) notation ----
	local ardl_str "ARDL(`chosen_p'"
	foreach q of local chosen_q {
		local ardl_str "`ardl_str',`q'"
	}
	local ardl_str "`ardl_str')"
	
	* ============================================================
	* CRITICAL: Actually modify $SRx with the selected lags
	* ============================================================
	
	* Build new SRx with lagged differences of y (p-1 lags) 
	* and each x variable (qi lags)
	local new_srx ""
	
	* Add lagged differences of the dependent variable: L.d.y, L2.d.y, ...
	if `chosen_p' > 1 {
		forvalues lag = 1/`= `chosen_p' - 1' {
			local new_srx "`new_srx' L`lag'.$SRy"
		}
	}
	
	* Add each x variable with its optimal qi lags
	local xidx = 0
	foreach xvar of local unique_x {
		local xidx = `xidx' + 1
		local qi : word `xidx' of `chosen_q'
		
		* Skip this x variable if qi=0 (no SR component)
		if `qi' == 0 continue
		
		* Contemporaneous difference
		local new_srx "`new_srx' d.`xvar'"
		
		* Additional lags if qi > 1
		if `qi' > 1 {
			forvalues lag = 1/`= `qi' - 1' {
				local new_srx "`new_srx' L`lag'D.`xvar'"
			}
		}
	}
	
	* ---- Display results ----
	di
	di in gr "  {bf:Selected by AIC:} p = " in ye "`mode_p_aic'" ///
		in gr " (chosen by " in ye "`mode_p_aic_cnt'" in gr " panels)"
	di in gr "  {bf:Selected by BIC:} p = " in ye "`mode_p_bic'" ///
		in gr " (chosen by " in ye "`mode_p_bic_cnt'" in gr " panels)"
	
	* Display per-x-variable lag selection
	local xidx = 0
	foreach xvar of local unique_x {
		local xidx = `xidx' + 1
		local qi_aic : word `xidx' of `q_aic_str'
		local qi_bic : word `xidx' of `q_bic_str'
		di in gr "  {bf:Lag for `xvar':} AIC=" in ye "`qi_aic'" ///
			in gr "  BIC=" in ye "`qi_bic'"
	}
	
	di
	di in gr "  {bf:Model notation:} " in ye "`ardl_str'"
	di in gr "  {bf:Original SR:}    " in ye "$SRx"
	di in gr "  {bf:Updated SR:}     " in ye "`new_srx'"
	di in smcl in gr "{hline 78}"
	di
	
	* ---- Apply the new variable list ----
	global SRx "`new_srx'"
	global ARDL_display "`ardl_str'"
	global ARDL_order_p "`chosen_p'"
end


* =========================================================================
* InferARDLOrder — Deduce ARDL(p, q1, q2, ...) from current $SRy/$SRx/$LRx
* Called when no lagsel is active to display correct model order
* =========================================================================

program define InferARDLOrder
	* p = 1 + number of lagged dependent-variable difference terms in $SRx
	* The dependent var base name is extracted from $SRy (strip D. prefix)
	local dep_base "$SRy"
	local dep_base = subinstr("`dep_base'", "D.", "", .)
	local dep_base = subinstr("`dep_base'", "d.", "", .)
	
	* Count lagged dependent terms in $SRx (L1.D.y, L2.D.y, etc.)
	local p = 1
	foreach sx of global SRx {
		local sx_clean = upper("`sx'")
		local dep_upper = upper("`dep_base'")
		if strpos("`sx_clean'", "`dep_upper'") > 0 {
			* This is a lagged dep-var diff term — increment p
			local p = `p' + 1
		}
	}
	
	* Get unique x-variable base names from $LRx
	local unique_x ""
	foreach lrx of global LRx {
		local bname "`lrx'"
		local bname = subinstr("`bname'", "L.", "", .)
		local bname = subinstr("`bname'", "l.", "", .)
		local bname = subinstr("`bname'", "L1.", "", .)
		local bname = subinstr("`bname'", "l1.", "", .)
		local found 0
		foreach ux of local unique_x {
			if "`ux'" == "`bname'" local found = 1
		}
		if `found' == 0 {
			local unique_x "`unique_x' `bname'"
		}
	}
	
	* For each x variable, count how many terms appear in $SRx
	local ardl_str "ARDL(`p'"
	foreach xvar of local unique_x {
		local qi = 0
		local xvar_upper = upper("`xvar'")
		foreach sx of global SRx {
			local sx_upper = upper("`sx'")
			if strpos("`sx_upper'", "`xvar_upper'") > 0 {
				local qi = `qi' + 1
			}
		}
		local ardl_str "`ardl_str',`qi'"
	}
	local ardl_str "`ardl_str')"
	
	global ARDL_display "`ardl_str'"
end


* =========================================================================
* NEW IN 2.1.1: DisplaySRTable — Per-panel short-run coefficients
* =========================================================================

program define DisplaySRTable
	syntax, IVar(string)
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Panel-Specific Short-Run Coefficients}" _col(49) in ye "XTPMG 2.1.1"
	di in gr "  (In PMG, short-run coefficients are heterogeneous across panels)"
	di in smcl in gr "{hline 78}"
	di
	
	* Get the coefficient names from the full PMG estimation
	tempname fullb fullV
	matrix `fullb' = e(b)
	matrix `fullV' = e(V)
	
	local ncols = colsof(`fullb')
	local cnames : colfullnames `fullb'
	
	* Identify SR variable names (from the equation labels)
	local sr_varnames ""
	local nlr = wordcount("$LRx")
	
	* The first nlr columns are LR coefficients, rest are panel-specific SR
	* Panel-specific have equation label "ivar_id"
	
	* Get unique SR variable names from first panel
	local first_id : word 1 of $iis
	local sr_names ""
	foreach nm of local cnames {
		if strpos("`nm'", "`ivar'_`first_id':") > 0 {
			local vname = subinstr("`nm'", "`ivar'_`first_id':", "", 1)
			local sr_names "`sr_names' `vname'"
		}
	}
	
	local nsr = wordcount("`sr_names'")
	
	if `nsr' == 0 {
		di in ye "  No panel-specific short-run coefficients found."
		di in ye "  (This display requires the full PMG estimates)"
		exit
	}
	
	* Display header
	di in smcl in gr "{hline 11}{c TT}" _c
	foreach sn of local sr_names {
		local sn_short = abbrev("`sn'", 12)
		di in gr "{hline 14}" _c
	}
	di in gr "{hline 1}"
	
	di in gr %10s "Panel ID" " {c |}" _c
	foreach sn of local sr_names {
		local sn_short = abbrev("`sn'", 12)
		di in gr %14s "`sn_short'" _c
	}
	di
	
	di in smcl in gr "{hline 11}{c +}" _c
	foreach sn of local sr_names {
		di in gr "{hline 14}" _c
	}
	di in gr "{hline 1}"
	
	* Display each panel's coefficients
	foreach i of global iis {
		di in gr %10s "`i'" " {c |}" _c
		
		foreach sn of local sr_names {
			local coefname "`ivar'_`i':`sn'"
			
			* Find this coefficient
			capture local coef = _b[`coefname']
			if !_rc {
				capture local se = _se[`coefname']
				if !_rc & `se' > 0 {
					local tstat = `coef' / `se'
					local pval = 2 * ttail(e(df_r), abs(`tstat'))
					
					* Significance stars
					local star ""
					capture {
						if abs(`tstat') > 2.576 local star "***"
						else if abs(`tstat') > 1.960 local star "** "
						else if abs(`tstat') > 1.645 local star "*  "
						else local star "   "
					}
					
					if abs(`coef') < 0.001 {
						di in ye %11.4f `coef' "`star'" _c
					}
					else {
						di in ye %11.3f `coef' "`star'" _c
					}
				}
				else {
					di in ye %14.3f `coef' _c
				}
			}
			else {
				di in gr %14s "." _c
			}
		}
		di
	}
	
	di in smcl in gr "{hline 11}{c BT}" _c
	foreach sn of local sr_names {
		di in gr "{hline 14}" _c
	}
	di in gr "{hline 1}"
	
	di in gr "  Significance: " in ye "*** p<0.01, ** p<0.05, * p<0.10"
	di
end


* =========================================================================
* NEW IN 2.1.1: DisplayHalfLife — Half-life of adjustment
* =========================================================================

program define DisplayHalfLife
	syntax, IVar(string) EC(string)
	tempname _PHI
	capture matrix `_PHI'=e(phi_i)
	local _hasphi = (_rc==0)
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Half-Life of Adjustment to Long-Run Equilibrium}" ///
		_col(49) in ye "XTPMG 2.1.1"
	di in gr "  Formula: half_life = ln(2) / -ln(1+phi_i)  (discrete EC decay)"
	di in gr "  where phi_i is the error-correction (speed of adjustment) coefficient"
	di in smcl in gr "{hline 78}"
	di
	
	tempname fullb
	matrix `fullb' = e(b)
	local cnames : colfullnames `fullb'
	
	* Display header
	di in smcl in gr "{hline 11}{c TT}{hline 16}{c TT}{hline 16}{c TT}{hline 16}{c TT}{hline 14}"
	di in gr %10s "Panel ID" " {c |}" ///
		%15s "ECT (phi_i)" " {c |}" ///
		%15s "Half-Life" " {c |}" ///
		%15s "Adj. Speed" " {c |}" ///
		%13s "Convergent"
	di in smcl in gr "{hline 11}{c +}{hline 16}{c +}{hline 16}{c +}{hline 16}{c +}{hline 14}"
	
	local sum_hl = 0
	local sum_phi = 0
	local n_valid = 0
	local n_convergent = 0
	
	local _idx = 0
	foreach i of global iis {
		local _idx = `_idx' + 1
		local coefname "`ivar'_`i':`ec'"
		
		if `_hasphi' {
			local phi = `_PHI'[`_idx',1]
			local _prc = 0
		}
		else {
			capture local phi = _b[`coefname']
			local _prc = _rc
		}
		if `_prc' {
			di in gr %10s "`i'" " {c |}" ///
				%15s "." " {c |}" ///
				%15s "." " {c |}" ///
				%15s "." " {c |}" ///
				%13s "."
			continue
		}
		
		* Check convergence (phi should be negative for valid EC)
		local convergent "Yes"
		if `phi' >= 0 {
			local convergent "No"
		}
		else {
			local n_convergent = `n_convergent' + 1
		}
		
		* Half-life calculation
		if `phi' < 0 & `phi' > -2 {
			local _onep = abs(1 + `phi')
			if `_onep' > 0 & `_onep' < 1 {
				local hl = ln(2) / (-ln(`_onep'))
			}
			else {
				local hl = 0
			}
			local adj_speed = abs(`phi') * 100
			local sum_hl = `sum_hl' + `hl'
			local sum_phi = `sum_phi' + `phi'
			local n_valid = `n_valid' + 1
			
			di in gr %10s "`i'" " {c |}" ///
				in ye %15.4f `phi' in gr " {c |}" ///
				in ye %12.2f `hl' " pd" in gr " {c |}" ///
				in ye %12.1f `adj_speed' " %" in gr " {c |}" ///
				_col(67) in ye %10s "`convergent'"
		}
		else {
			di in gr %10s "`i'" " {c |}" ///
				in ye %15.4f `phi' in gr " {c |}" ///
				in ye %15s "Unstable" in gr " {c |}" ///
				in ye %15s "N/A" in gr " {c |}" ///
				_col(67) in re %10s "`convergent'"
		}
	}
	
	di in smcl in gr "{hline 11}{c +}{hline 16}{c +}{hline 16}{c +}{hline 16}{c +}{hline 14}"
	
	* Summary
	if `n_valid' > 0 {
		local mean_hl = `sum_hl' / `n_valid'
		local mean_phi = `sum_phi' / `n_valid'
		local mean_adj = abs(`mean_phi') * 100
		
		di in gr %10s "Mean" " {c |}" ///
			in ye %15.4f `mean_phi' in gr " {c |}" ///
			in ye %12.2f `mean_hl' " pd" in gr " {c |}" ///
			in ye %12.1f `mean_adj' " %" in gr " {c |}" ///
			_col(67) in ye %3.0f `n_convergent' "/" ///
			wordcount("$iis") ""
			
		di in smcl in gr "{hline 11}{c BT}{hline 16}{c BT}{hline 16}{c BT}{hline 16}{c BT}{hline 14}"
		
		di 
		di in gr "  {bf:Interpretation:}"
		di in gr "  - Mean speed of adjustment: " in ye %5.1f `mean_adj' "%" ///
			in gr " of disequilibrium corrected per period"
		di in gr "  - Mean half-life: " in ye %5.2f `mean_hl' ///
			in gr " periods to close half the gap to equilibrium"
		di in gr "  - Convergent panels: " in ye "`n_convergent'" in gr " out of " ///
			in ye wordcount("$iis") in gr " (phi < 0 required)"
	}
	else {
		di in smcl in gr "{hline 11}{c BT}{hline 16}{c BT}{hline 16}{c BT}{hline 16}{c BT}{hline 14}"
		di in re "  Warning: No valid (convergent) panels found."
	}
	di
end


* =========================================================================
* NEW IN 2.1.1: SimulateIRF — Impulse response simulation
* =========================================================================

program define SimulateIRF
	syntax, Periods(integer) IVar(string) EC(string)
	tempname _PHI
	capture matrix `_PHI'=e(phi_i)
	local _hasphi = (_rc==0)
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Error-Correction Adjustment Path (Simulated)}" ///
		_col(49) in ye "XTPMG 2.1.1"
	di in gr "  Shock: One-unit deviation from long-run equilibrium at t=0"
	di in gr "  Tracing adjustment path via error-correction mechanism"
	di in gr "  {bf:Assumption:} pure EC decay at the mean phi; short-run ARDL"
	di in gr "  lag dynamics are not propagated. Exact for ARDL(1,0,...,0);"
	di in gr "  an approximation to the full impulse response otherwise."
	di in gr "  Periods: `periods'"
	di in smcl in gr "{hline 78}"
	di
	
	tempname fullb
	matrix `fullb' = e(b)
	local cnames : colfullnames `fullb'
	
	* Collect ECT coefficients for each panel
	local n_panels = wordcount("$iis")
	
	* Initialize IRF storage
	tempname irf_mean
	matrix `irf_mean' = J(`periods' + 1, 4, 0)
	matrix colnames `irf_mean' = "Period" "MeanResponse" "CumAdjustment" "RemainingGap"
	
	* Compute mean ECT coefficient
	local sum_phi = 0
	local n_valid = 0
	
	local _idx = 0
	foreach i of global iis {
		local _idx = `_idx' + 1
		local coefname "`ivar'_`i':`ec'"
		if `_hasphi' {
			local phi = `_PHI'[`_idx',1]
			local _prc = 0
		}
		else {
			capture local phi = _b[`coefname']
			local _prc = _rc
		}
		if !`_prc' & `phi' < 0 {
			local sum_phi = `sum_phi' + `phi'
			local n_valid = `n_valid' + 1
		}
	}
	
	if `n_valid' == 0 {
		di in re "  Error: No valid convergent panels for IRF simulation."
		exit
	}
	
	local mean_phi = `sum_phi' / `n_valid'
	
	di in gr "  Mean ECT coefficient (phi): " in ye %8.4f `mean_phi'
	di in gr "  Based on " in ye "`n_valid'" in gr " convergent panels"
	di
	
	* Simulate the impulse response
	* Starting with a unit shock (gap = 1), trace the adjustment
	
	di in smcl in gr "{hline 10}{c TT}{hline 17}{c TT}{hline 17}{c TT}{hline 17}{c TT}{hline 14}"
	di in gr %9s "Period" " {c |}" ///
		%16s "Response" " {c |}" ///
		%16s "Cum. Adj. (%)" " {c |}" ///
		%16s "Remaining (%)" " {c |}" ///
		%13s "Visual"
	di in smcl in gr "{hline 10}{c +}{hline 17}{c +}{hline 17}{c +}{hline 17}{c +}{hline 14}"
	
	local gap = 1
	local cum_adj = 0
	
	forvalues t = 0/`periods' {
		if `t' == 0 {
			* Initial shock
			local response = 1
			local remaining = 100
			local cum_pct = 0
		}
		else {
			* Adjustment via error correction
			local adjustment = `mean_phi' * `gap'
			local gap = `gap' + `adjustment'
			local response = `gap'
			local remaining = `gap' * 100
			local cum_pct = (1 - `gap') * 100
		}
		
		* Store in matrix
		matrix `irf_mean'[`t'+1, 1] = `t'
		matrix `irf_mean'[`t'+1, 2] = `response'
		matrix `irf_mean'[`t'+1, 3] = `cum_pct'
		matrix `irf_mean'[`t'+1, 4] = `remaining'
		
		* Visual bar (scaled to 10 chars)
		local bar_len = round(`remaining' / 10)
		if `bar_len' < 0 local bar_len = 0
		if `bar_len' > 10 local bar_len = 10
		local bar ""
		forvalues b = 1/`bar_len' {
			local bar "`bar'{bf:#}"
		}
		
		* Color code based on remaining gap
		if `remaining' > 50 {
			di in gr %9.0f `t' " {c |}" ///
				in ye %16.4f `response' " {c |}" ///
				in ye %13.1f `cum_pct' " %  {c |}" ///
				in re %13.1f `remaining' " %  {c |}" ///
				" " in re "`bar'"
		}
		else if `remaining' > 10 {
			di in gr %9.0f `t' " {c |}" ///
				in ye %16.4f `response' " {c |}" ///
				in ye %13.1f `cum_pct' " %  {c |}" ///
				in ye %13.1f `remaining' " %  {c |}" ///
				" " in ye "`bar'"
		}
		else {
			di in gr %9.0f `t' " {c |}" ///
				in ye %16.4f `response' " {c |}" ///
				in gr %13.1f `cum_pct' " %  {c |}" ///
				in gr %13.1f `remaining' " %  {c |}" ///
				" " in gr "`bar'"
		}
	}
	
	di in smcl in gr "{hline 10}{c BT}{hline 17}{c BT}{hline 17}{c BT}{hline 17}{c BT}{hline 14}"
	
	* Summary
	local final_gap = `gap' * 100
	local _onep = abs(1 + `mean_phi')
	local half_life = ln(2) / (-ln(`_onep'))
	local q90_life = ln(10) / (-ln(`_onep'))
	
	di
	di in gr "  {bf:Summary:}"
	di in gr "  - Half-life (50% adjustment): " in ye %5.2f `half_life' in gr " periods"
	di in gr "  - 90% adjustment achieved in: " in ye %5.2f `q90_life' in gr " periods"
	di in gr "  - Remaining gap after " in ye "`periods'" in gr " periods: " ///
		in ye %5.2f `final_gap' "%"
	di
	
	* Store IRF matrix in global (SimulateIRF is not eclass)
	matrix XTPMG_IRF = `irf_mean'
end


* =========================================================================
* ENHANCED DISPLAY (updated for 2.1.1)
* =========================================================================

program define Display
	syntax [,Level(integer `c(level)')]
	
	if "`e(model)'"=="pmg" | "`e(model)'"=="PMG"{
		#delimit ;
		di _n in smcl in gr "{hline 78}" ;
		di in gr "{bf:Pooled Mean Group Regression}"
		   _col(49) in ye "XTPMG v2.1.1" ;
		di in gr "{it:Pesaran, Shin & Smith (1999)}" ;
		di in smcl in gr "{hline 78}" ;
		di in gr "(Estimate results saved as " in ye e(model) in gr ")" ;
      	di _n in gr "Panel Variable (i): " in ye abbrev(e(ivar),12)
                _col(49) in gr "Number of obs" _col(68) "="
                _col(70) in ye %9.0f e(N) ;
      	di in gr "Time Variable (t): " in ye abbrev(e(tvar),12) in gr
		_col(49) "Number of groups " _col(68) "="
                _col(70) in ye %9.0g e(n_g) ;
      	di in gr _col(49) in gr "Obs per group: min" _col(68) "="
                _col(70) in ye %9.0g e(g_min) ;
      	di in gr _col(64) in gr "avg" _col(68) "="
                _col(70) in ye %9.1f e(g_avg) ;
      	di in gr _col(64) in gr "max" _col(68) "="
                _col(70) in ye %9.0g e(g_max) _n ;
      	di in gr _col(49) "Log Likelihood" _col(68) "="
                _col(70) in ye %9.0g e(ll) ;
		#delimit cr
		
		* Display ARDL order if available
		if "`e(ardl_order)'" != "" {
			di in gr _col(49) "Model order" _col(68) "=" ///
				_col(70) in ye %9s "`e(ardl_order)'"
		}
		di in smcl in gr "{hline 78}"
	}
	if "`e(model)'"=="fe" | "`e(model)'"=="dfe"{
		quie est restore DFE
		if "$cluster"!=""{
			di _n in smcl in gr "{hline 78}"
			di in ye "Standard errors adjusted with " "$cluster" " option."
		}		
		#delimit ;
		di in smcl in gr "{hline 78}";
		di in gr "{bf:Dynamic Fixed Effects Regression:} " 
			in ye "Estimated Error Correction Form"
		   _col(49) "XTPMG v2.1.1" ;
		di in gr "(Estimate results saved as " in ye "DFE" in gr ")";
		di in smcl in gr "{hline 78}";

		#delimit cr
	}
	if "`e(model)'"=="mg" | "`e(model)'"=="MG"{
		#delimit ;	
		di _n in smcl in gr "{hline 78}";
		di in gr "{bf:Mean Group Estimation:} " in ye "Error Correction Form"
		   _col(49) "XTPMG v2.1.1" ;
		di in gr "(Estimate results saved as " in ye e(model) in gr ")";
		di in smcl in gr "{hline 78}";
		#delimit cr
		
		* Display ARDL order if available
		if "`e(ardl_order)'" != "" {
			di in gr " Model order: " in ye "`e(ardl_order)'"
		}
	}
	eret disp, level(`level')
end


* =========================================================================
* NEW IN 2.1.1: GRAPH VISUALIZATIONS
* Beautiful Stata graphs for panel ARDL diagnostics
* =========================================================================


* =========================================================================
* PlotIRF -- Error-correction adjustment path graph
* =========================================================================

program define PlotIRF
	syntax, Periods(integer) IVar(string) EC(string)
	tempname _PHI
	capture matrix `_PHI'=e(phi_i)
	local _hasphi = (_rc==0)
	
	tempname fullb
	matrix `fullb' = e(b)
	
	* Compute mean ECT coefficient
	local sum_phi = 0
	local n_valid = 0
	
	local _idx = 0
	foreach i of global iis {
		local _idx = `_idx' + 1
		local coefname "`ivar'_`i':`ec'"
		if `_hasphi' {
			local phi = `_PHI'[`_idx',1]
			local _prc = 0
		}
		else {
			capture local phi = _b[`coefname']
			local _prc = _rc
		}
		if !`_prc' & `phi' < 0 {
			local sum_phi = `sum_phi' + `phi'
			local n_valid = `n_valid' + 1
		}
	}
	
	if `n_valid' == 0 {
		di in re "  Cannot plot IRF: no convergent panels."
		exit
	}
	
	local mean_phi = `sum_phi' / `n_valid'
	local _onep = abs(1 + `mean_phi')
	local half_life = ln(2) / (-ln(`_onep'))
	
	* Create temporary dataset for plotting
	preserve
	clear
	qui set obs `= `periods' + 1'
	qui gen period = _n - 1
	qui gen response = .
	qui gen cum_adj = .
	qui gen remaining = .
	qui gen zero_line = 0
	qui gen one_line = 1
	
	local gap = 1
	forvalues t = 0/`periods' {
		if `t' == 0 {
			qui replace response = 1 in `= `t' + 1'
			qui replace cum_adj = 0 in `= `t' + 1'
			qui replace remaining = 100 in `= `t' + 1'
		}
		else {
			local adjustment = `mean_phi' * `gap'
			local gap = `gap' + `adjustment'
			qui replace response = `gap' in `= `t' + 1'
			qui replace cum_adj = (1 - `gap') * 100 in `= `t' + 1'
			qui replace remaining = `gap' * 100 in `= `t' + 1'
		}
	}
	
	* Beautiful IRF Plot
	local hl_int = round(`half_life', 0.1)
	
	#delimit ;
	twoway (area response period, 
			color("47 117 181%40") lcolor("47 117 181") lwidth(thin))
		   (line response period, 
		    lcolor("47 117 181") lwidth(medthick) lpattern(solid))
		   (line zero_line period, 
		    lcolor(gs10) lwidth(thin) lpattern(dash)),
		title("{bf:Error-Correction Adjustment Path}", 
			size(large) color(black))
		subtitle("Error Correction Adjustment Path — XTPMG 2.1.1", 
			size(medsmall) color(gs5))
		ytitle("Response to Unit Shock", size(medium))
		xtitle("Periods After Shock", size(medium))
		ylabel(0(0.2)1, format(%4.1f) angle(0) labsize(small) 
			grid glcolor(gs14) glpattern(dot))
		xlabel(, labsize(small))
		xline(`hl_int', lcolor("231 76 60") lwidth(medthin) lpattern(dash))
		legend(order(2 "Response" ) 
			position(1) ring(0) cols(1) size(small)
			region(lcolor(gs14) fcolor(white%90)))
		note("Mean ECT (phi) = `: di %6.4f `mean_phi''"
			 "Half-life = `: di %4.2f `half_life'' periods"
			 "Based on `n_valid' convergent panels",
			 size(vsmall) color(gs6))
		graphregion(fcolor(white) lcolor(white))
		plotregion(fcolor(white) lcolor(gs14) margin(small))
		scheme(s2color)
		name(xtpmg_irf, replace) ;
	#delimit cr
	
	di
	di in gr "  {bf:Graph saved:} " in ye "xtpmg_irf"
	
	restore
end


* =========================================================================
* PlotECT — ECT coefficients bar chart per panel  
* =========================================================================

program define PlotECT
	syntax, IVar(string) EC(string)
	tempname _PHI
	capture matrix `_PHI'=e(phi_i)
	local _hasphi = (_rc==0)
	
	tempname fullb
	matrix `fullb' = e(b)
	
	* Count panels
	local n_panels = wordcount("$iis")
	
	* Create temporary dataset
	preserve
	clear
	qui set obs `n_panels'
	qui gen panel_id = ""
	qui gen phi = .
	qui gen panel_num = _n
	qui gen sig = 0
	qui gen color_cat = .
	
	local idx = 0
	foreach i of global iis {
		local idx = `idx' + 1
		local coefname "`ivar'_`i':`ec'"
		if `_hasphi' {
			local coef = `_PHI'[`idx',1]
			local _prc = 0
		}
		else {
			capture local coef = _b[`coefname']
			local _prc = _rc
		}
		if !`_prc' {
			local se = .
			capture local se = _se[`coefname']
			qui replace panel_id = "Panel `i'" in `idx'
			qui replace phi = `coef' in `idx'
			
			if `se' < . & `se' > 0 {
				local tstat = abs(`coef' / `se')
				if `tstat' > 2.576 qui replace sig = 3 in `idx'
				else if `tstat' > 1.960 qui replace sig = 2 in `idx'
				else if `tstat' > 1.645 qui replace sig = 1 in `idx'
			}
			
			* Color category: negative = good (convergent), positive = bad
			if `coef' < -0.5 qui replace color_cat = 1 in `idx'
			else if `coef' < 0 qui replace color_cat = 2 in `idx'
			else qui replace color_cat = 3 in `idx'
		}
		else {
			qui replace panel_id = "Panel `i'" in `idx'
			* leave phi missing so the mean line excludes non-estimated panels
		}
	}
	
	* Compute mean
	qui sum phi
	local mean_phi = r(mean)
	
	* Beautiful bar chart
	#delimit ;
	twoway (bar phi panel_num if color_cat == 1, 
			color("39 174 96%80") lcolor("39 174 96") barwidth(0.7))
		   (bar phi panel_num if color_cat == 2, 
		    color("243 156 18%80") lcolor("243 156 18") barwidth(0.7))
		   (bar phi panel_num if color_cat == 3, 
		    color("231 76 60%80") lcolor("231 76 60") barwidth(0.7)),
		title("{bf:Error Correction Term (ECT) by Panel}", 
			size(large) color(black))
		subtitle("Speed of Adjustment Coefficients — XTPMG 2.1.1", 
			size(medsmall) color(gs5))
		ytitle("ECT Coefficient ({&phi}{sub:i})", size(medium))
		xtitle("Panel", size(medium))
		ylabel(, format(%5.2f) angle(0) labsize(small) 
			grid glcolor(gs14) glpattern(dot))
		xlabel(1/`n_panels', valuelabel labsize(vsmall) angle(45))
		yline(0, lcolor(gs8) lwidth(thin))
		yline(`mean_phi', lcolor("142 68 173") lwidth(medthin) lpattern(dash))
		legend(order(1 "Strong ({&phi} < -0.5)" 
					 2 "Moderate (-0.5 < {&phi} < 0)" 
					 3 "Non-convergent ({&phi} > 0)") 
			position(6) ring(1) rows(1) size(vsmall)
			region(lcolor(gs14) fcolor(white%90)))
		note("Mean {&phi} = `: di %6.4f `mean_phi'' (dashed purple line)"
			 "Negative values indicate convergence to long-run equilibrium",
			 size(vsmall) color(gs6))
		graphregion(fcolor(white) lcolor(white))
		plotregion(fcolor(white) lcolor(gs14) margin(small))
		name(xtpmg_ect, replace) ;
	#delimit cr
	
	di in gr "  {bf:Graph saved:} " in ye "xtpmg_ect"
	
	restore
end


* =========================================================================
* PlotHalfLife — Half-life horizontal bar chart
* =========================================================================

program define PlotHalfLife
	syntax, IVar(string) EC(string)
	tempname _PHI
	capture matrix `_PHI'=e(phi_i)
	local _hasphi = (_rc==0)
	
	tempname fullb
	matrix `fullb' = e(b)
	
	local n_panels = wordcount("$iis")
	
	preserve
	clear
	qui set obs `n_panels'
	qui gen panel_id = ""
	qui gen half_life = .
	qui gen adj_speed = .
	qui gen panel_num = _n
	
	local idx = 0
	foreach i of global iis {
		local idx = `idx' + 1
		local coefname "`ivar'_`i':`ec'"
		if `_hasphi' {
			local phi = `_PHI'[`idx',1]
			local _prc = 0
		}
		else {
			capture local phi = _b[`coefname']
			local _prc = _rc
		}
		qui replace panel_id = "Panel `i'" in `idx'
		
		if !`_prc' & `phi' < 0 & `phi' > -2 {
			local _onep = abs(1 + `phi')
			if `_onep' > 0 & `_onep' < 1 {
				local hl = ln(2) / (-ln(`_onep'))
			}
			else {
				local hl = 0
			}
			local adj = abs(`phi') * 100
			qui replace half_life = `hl' in `idx'
			qui replace adj_speed = `adj' in `idx'
		}
	}
	
	qui sum half_life
	local mean_hl = r(mean)
	
	* Beautiful half-life chart
	#delimit ;
	twoway (bar half_life panel_num, 
			horizontal color("52 152 219%80") lcolor("41 128 185") barwidth(0.65))
		   (scatter panel_num half_life, 
		    msymbol(circle) msize(medium) mcolor("41 128 185") mlcolor(white) mlwidth(thin)),
		title("{bf:Half-Life of Adjustment by Panel}", 
			size(large) color(black))
		subtitle("Time to Close 50% of Disequilibrium Gap — XTPMG 2.1.1", 
			size(medsmall) color(gs5))
		xtitle("Half-Life (periods)", size(medium))
		ytitle("Panel", size(medium))
		xlabel(, format(%4.1f) labsize(small)
			grid glcolor(gs14) glpattern(dot))
		ylabel(1/`n_panels', valuelabel labsize(vsmall) angle(0))
		xline(`mean_hl', lcolor("231 76 60") lwidth(medthin) lpattern(dash))
		legend(off)
		note("Mean half-life = `: di %4.2f `mean_hl'' periods (dashed red line)"
			 "Formula: half_life = ln(2) / -ln(1+{&phi}{sub:i})",
			 size(vsmall) color(gs6))
		graphregion(fcolor(white) lcolor(white))
		plotregion(fcolor(white) lcolor(gs14) margin(small))
		name(xtpmg_halflife, replace) ;
	#delimit cr
	
	di in gr "  {bf:Graph saved:} " in ye "xtpmg_halflife"
	
	restore
end


* =========================================================================
* PlotSRCoefs — Short-run coefficients comparison across panels
* =========================================================================

program define PlotSRCoefs
	syntax, IVar(string) EC(string)
	tempname _PHI
	capture matrix `_PHI'=e(phi_i)
	local _hasphi = (_rc==0)
	
	tempname fullb
	matrix `fullb' = e(b)
	local cnames : colfullnames `fullb'
	
	* Get SR variable names from first panel
	local first_id : word 1 of $iis
	local sr_names ""
	foreach nm of local cnames {
		if strpos("`nm'", "`ivar'_`first_id':") > 0 {
			local vname = subinstr("`nm'", "`ivar'_`first_id':", "", 1)
			local sr_names "`sr_names' `vname'"
		}
	}
	
	local nsr = wordcount("`sr_names'")
	local n_panels = wordcount("$iis")
	
	if `nsr' == 0 | `n_panels' == 0 {
		di in ye "  Cannot plot SR coefficients: insufficient data."
		exit
	}
	
	* Create a combined graph for each SR variable
	local graph_num = 0
	local combined_names ""
	
	foreach sn of local sr_names {
		local graph_num = `graph_num' + 1
		
		preserve
		clear
		qui set obs `n_panels'
		qui gen panel_num = _n
		qui gen panel_id = ""
		qui gen coef = .
		qui gen se = .
		qui gen ci_lo = .
		qui gen ci_hi = .
		
		local idx = 0
		foreach i of global iis {
			local idx = `idx' + 1
			local coefname "`ivar'_`i':`sn'"
			qui replace panel_id = "`i'" in `idx'
			
			capture local c = _b[`coefname']
			if !_rc {
				qui replace coef = `c' in `idx'
				capture local s = _se[`coefname']
				if !_rc & `s' > 0 {
					qui replace se = `s' in `idx'
					qui replace ci_lo = `c' - 1.96 * `s' in `idx'
					qui replace ci_hi = `c' + 1.96 * `s' in `idx'
				}
			}
		}
		
		qui sum coef
		local mean_c = r(mean)
		
		* Clean variable name for title
		local sn_clean = subinstr("`sn'", ".", " ", .)
		
		* Choose color based on variable  
		local bar_color "52 152 219"
		local cap_color "41 128 185"
		if `graph_num' == 1 {
			local bar_color "231 76 60"
			local cap_color "192 57 43"
		}
		else if `graph_num' == 2 {
			local bar_color "46 204 113"
			local cap_color "39 174 96"
		}
		else if `graph_num' == 3 {
			local bar_color "155 89 182"
			local cap_color "142 68 173"
		}
		else if `graph_num' == 4 {
			local bar_color "243 156 18"
			local cap_color "211 84 0"
		}
		
		local gname "xtpmg_sr`graph_num'"
		local combined_names "`combined_names' `gname'"
		
		#delimit ;
		twoway (bar coef panel_num, 
				color("`bar_color'%75") lcolor("`cap_color'") barwidth(0.6))
			   (rcap ci_lo ci_hi panel_num, 
			    lcolor(gs4) lwidth(medthin))
			   (scatter coef panel_num, 
			    msymbol(diamond) msize(medsmall) mcolor("`cap_color'") 
			    mlcolor(white) mlwidth(vthin)),
			title("{bf:`sn_clean'}", size(medium) color(black))
			ytitle("Coefficient", size(small))
			xtitle("Panel", size(small))
			ylabel(, format(%5.3f) angle(0) labsize(vsmall)
				grid glcolor(gs14) glpattern(dot))
			xlabel(1/`n_panels', labsize(vsmall) angle(45))
			yline(0, lcolor(gs10) lwidth(thin))
			yline(`mean_c', lcolor("`cap_color'") lwidth(thin) lpattern(dash))
			legend(off)
			graphregion(fcolor(white) lcolor(white))
			plotregion(fcolor(white) lcolor(gs14) margin(small))
			name(`gname', replace) nodraw ;
		#delimit cr
		
		restore
	}
	
	* Combine all SR coefficient plots into one
	if `graph_num' > 0 {
		#delimit ;
		graph combine `combined_names',
			title("{bf:Panel-Specific Short-Run Coefficients}", 
				size(large) color(black))
			subtitle("Heterogeneous SR dynamics across panels — XTPMG 2.1.1",
				size(medsmall) color(gs5))
			note("Bars = point estimates, whiskers = 95% CI, dashed line = mean across panels", 
				size(vsmall) color(gs6))
			graphregion(fcolor(white) lcolor(white))
			cols(2) iscale(0.7)
			name(xtpmg_sr_combined, replace) ;
		#delimit cr
		
		di in gr "  {bf:Graph saved:} " in ye "xtpmg_sr_combined"
	}
end


* =========================================================================
* NEW IN 2.1.1: Cross-sectional dependence test (Pesaran CD) + engine
* =========================================================================

program define XtpmgCD, rclass
	args resid
	qui xtset
	local pv "`r(panelvar)'"
	local tv "`r(timevar)'"
	capture scalar drop __xtpmg_CD __xtpmg_CDp __xtpmg_CDavg __xtpmg_np __xtpmg_N
	scalar __xtpmg_CD    = .
	scalar __xtpmg_CDp   = .
	scalar __xtpmg_CDavg = .
	scalar __xtpmg_np    = 0
	scalar __xtpmg_N     = 0
	capture mata: xtpmg_cd("`resid'", "`pv'", "`tv'")
	return scalar CD     = __xtpmg_CD
	return scalar pCD    = __xtpmg_CDp
	return scalar CDavg  = __xtpmg_CDavg
	return scalar npairs = __xtpmg_np
	return scalar Ncd    = __xtpmg_N
	capture scalar drop __xtpmg_CD __xtpmg_CDp __xtpmg_CDavg __xtpmg_np __xtpmg_N
end

program define XtpmgShowCSD
	if "`e(CD)'"=="" exit
	tempname cd p avg
	scalar `cd'  = e(CD)
	scalar `p'   = e(p_CD)
	scalar `avg' = e(CD_avg)
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Cross-Sectional Dependence Test (Residuals)}" _col(66) in ye "XTPMG 2.1.1"
	di in gr "  Pesaran (2004, 2015) CD test   H0: cross-sectional independence"
	di in smcl in gr "{hline 78}"
	if `cd' >= . {
		di in ye "  CD statistic unavailable (insufficient overlapping observations)."
		di in smcl in gr "{hline 78}"
		exit
	}
	local stars ""
	if `p' < 0.01      local stars "***"
	else if `p' < 0.05 local stars "** "
	else if `p' < 0.10 local stars "*  "
	di in gr "  CD statistic"                _col(34) "=" _col(40) in ye %9.4f `cd' "  `stars'"
	di in gr "  p-value"                     _col(34) "=" _col(40) in ye %9.4f `p'
	di in gr "  Mean |pairwise correlation|" _col(34) "=" _col(40) in ye %9.4f `avg'
	di in smcl in gr "{hline 78}"
	if `p' < 0.05 {
		di in gr "  {bf:Conclusion:} reject H0 at 5% - evidence of cross-sectional dependence."
		di in gr "  PMG/MG/DFE assume errors are independent across panels (Pesaran, Shin &"
		di in gr "  Smith 1999, Assumption 1). Consider CCE / common-factor models or"
		di in gr "  cross-sectional demeaning of the data."
	}
	else {
		di in gr "  {bf:Conclusion:} fail to reject H0 at 5% - no evidence of CSD."
	}
	di in gr "  Significance: *** p<.01, ** p<.05, * p<.10"
	di in smcl in gr "{hline 78}"
	di
end

* =========================================================================
* NEW IN 2.1.1: PlotLRCoefs - long-run coefficient dot-and-whisker plot
* =========================================================================

program define PlotLRCoefs
	syntax, EC(string)
	local nlr = wordcount("$LRx")
	if `nlr' == 0 {
		di in ye "  No long-run coefficients available to plot."
		exit
	}
	preserve
	clear
	qui set obs `nlr'
	qui gen vnum = _n
	qui gen str32 vname = ""
	qui gen coef = .
	qui gen se   = .
	qui gen lo   = .
	qui gen hi   = .
	local k = 0
	foreach x of global LRx {
		local k = `k' + 1
		qui replace vname = "`x'" in `k'
		capture local c = _b[`ec':`x']
		if !_rc {
			qui replace coef = `c' in `k'
			local sx = .
			capture local sx = _se[`ec':`x']
			if `sx' < . & `sx' > 0 {
				qui replace se = `sx' in `k'
				qui replace lo = `c' - 1.96*`sx' in `k'
				qui replace hi = `c' + 1.96*`sx' in `k'
			}
		}
	}
	forvalues i = 1/`nlr' {
		local nm "`=vname[`i']'"
		label define _lrvl `i' "`nm'", add
	}
	label values vnum _lrvl
	qui sum coef
	local mc = r(mean)
	#delimit ;
	twoway (rspike lo hi vnum, horizontal lcolor("41 128 185") lwidth(medthick))
	       (scatter vnum coef, msymbol(circle) msize(large)
	            mcolor("41 128 185") mlcolor(white) mlwidth(medthin)),
		title("{bf:Long-Run Coefficients}", size(large) color(black))
		subtitle("Pooled long-run estimates with 95% CI - XTPMG 2.1.1",
			size(medsmall) color(gs5))
		xtitle("Coefficient", size(medium))
		ytitle("")
		ylabel(1/`nlr', valuelabel angle(0) labsize(small))
		xlabel(, format(%5.2f) labsize(small) grid glcolor(gs14) glpattern(dot))
		xline(0, lcolor("231 76 60") lwidth(medthin) lpattern(dash))
		legend(off)
		note("Whiskers = 95% confidence interval; red dashed line = 0",
			size(vsmall) color(gs6))
		graphregion(fcolor(white) lcolor(white))
		plotregion(fcolor(white) lcolor(gs14) margin(medium))
		name(xtpmg_lrcoef, replace) ;
	#delimit cr
	di in gr "  {bf:Graph saved:} " in ye "xtpmg_lrcoef"
	restore
end

* =========================================================================
* NEW IN 2.1.1: PlotDashboard - combine key graphs into one figure
* =========================================================================

program define PlotDashboard
	syntax [, Periods(integer 0)]
	local glist ""
	foreach g in xtpmg_lrcoef xtpmg_ect xtpmg_halflife xtpmg_irf {
		capture graph describe `g'
		if _rc == 0 local glist "`glist' `g'"
	}
	local ng : word count `glist'
	if `ng' == 0 {
		di in ye "  Dashboard: no component graphs available."
		exit
	}
	#delimit ;
	graph combine `glist',
		title("{bf:XTPMG Model Dashboard}", size(large) color(black))
		subtitle("Long-run coefficients, error correction, half-life & adjustment path - XTPMG 2.1.1",
			size(small) color(gs5))
		note("XTPMG 2.1.1 - Dr Merwan Roudane", size(vsmall) color(gs8))
		graphregion(fcolor(white) lcolor(white))
		cols(2) iscale(0.65) imargin(small)
		name(xtpmg_dashboard, replace) ;
	#delimit cr
	di in gr "  {bf:Graph saved:} " in ye "xtpmg_dashboard"
end

* =========================================================================
* Mata: Pesaran (2004/2015) CD statistic from residual variable
* (unbalanced-panel safe, pairwise common samples)
* =========================================================================

mata:
void xtpmg_cd(string scalar rv, string scalar iv, string scalar tv)
{
	real matrix D, sel, E
	real colvector ids, tms, a, b, av, bv, ok, pos
	real scalar N, Tn, i, j, k, Tij, denom, rho, S, SR, np, sa, sb, cd

	D = st_data(., (rv, iv, tv))
	D = select(D, D[,1] :< .)
	if (rows(D) < 4) {
		st_numscalar("__xtpmg_CD", .)
		st_numscalar("__xtpmg_CDp", .)
		st_numscalar("__xtpmg_CDavg", .)
		st_numscalar("__xtpmg_np", 0)
		st_numscalar("__xtpmg_N", 0)
		return
	}
	ids = uniqrows(D[,2])
	tms = uniqrows(D[,3])
	N = rows(ids)
	Tn = rows(tms)
	E = J(Tn, N, .)
	for (i=1; i<=N; i++) {
		sel = D[selectindex(D[,2] :== ids[i]), (3,1)]
		for (k=1; k<=rows(sel); k++) {
			pos = selectindex(tms :== sel[k,1])
			if (rows(pos) >= 1) {
				E[pos[1], i] = sel[k,2]
			}
		}
	}
	S = 0
	SR = 0
	np = 0
	for (i=1; i<=N-1; i++) {
		for (j=i+1; j<=N; j++) {
			a = E[,i]
			b = E[,j]
			ok = selectindex((a :< .) :& (b :< .))
			Tij = rows(ok)
			if (Tij > 2) {
				av = a[ok]
				bv = b[ok]
				sa = sum(av)/Tij
				sb = sum(bv)/Tij
				av = av :- sa
				bv = bv :- sb
				denom = sqrt(sum(av:^2) * sum(bv:^2))
				if (denom > 0) {
					rho = sum(av :* bv)/denom
					S = S + sqrt(Tij)*rho
					SR = SR + abs(rho)
					np = np + 1
				}
			}
		}
	}
	if (N >= 2 & np > 0) {
		cd = sqrt(2/(N*(N-1))) * S
		st_numscalar("__xtpmg_CD", cd)
		st_numscalar("__xtpmg_CDp", 2*normal(-abs(cd)))
		st_numscalar("__xtpmg_CDavg", SR/np)
		st_numscalar("__xtpmg_np", np)
		st_numscalar("__xtpmg_N", N)
	}
	else {
		st_numscalar("__xtpmg_CD", .)
		st_numscalar("__xtpmg_CDp", .)
		st_numscalar("__xtpmg_CDavg", .)
		st_numscalar("__xtpmg_np", 0)
		st_numscalar("__xtpmg_N", N)
	}
}
end

mata:
void xtpmg_split(string scalar bn, string scalar Vn, real scalar off, real scalar blk, real scalar n)
{
	real matrix b, V, bi, sei
	real scalar i, j, c
	b = st_matrix(bn)
	V = st_matrix(Vn)
	bi = J(n, blk, .)
	sei = J(n, blk, .)
	for (i=1; i<=n; i++) {
		for (j=1; j<=blk; j++) {
			c = off + (i-1)*blk + j
			if (c <= cols(b)) {
				bi[i,j] = b[1,c]
				if (c <= cols(V)) {
					if (V[c,c] >= 0) {
						sei[i,j] = sqrt(V[c,c])
					}
				}
			}
		}
	}
	st_matrix("__xtpmg_bi", bi)
	st_matrix("__xtpmg_sei", sei)
}
end
