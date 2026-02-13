*! version 2.0.1  12feb2026  Dr Merwan Roudane  merwanroudane920@gmail.com
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
		else Estimate `0'
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
	
	* Auto-trigger lag selection when maxlag is specified but lagsel is not
	if "`lagsel'" == "" & `maxlag' != 4 {
		local lagsel "aic"
		di in gr "Note: maxlag(`maxlag') specified without lagsel(); defaulting to lagsel(aic)"
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
	capture macro drop nocons LRy LRx SRy SRx
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

	if "`mg'"!=""{
		EstMG if `touse', level(`level') ec(`ec') `full' ///
			srtable(`srtable') halflife(`halflife') irf(`irf')
		exit
	}

	if "`dfe'"!=""{
		EstDFE if `touse', level(`level') ec(`ec')
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

	tempname b V 
	matrix `V'=syminv(`G')
	matrix `thV'=`V'[1..`kl',1..`kl']
	matrix `b'=nullmat(`theta'), `param' 
	matrix colnames `V'=`names'
	matrix rownames `V'=`names'
	matrix colnames `b'=`names'
	matrix rownames `sigs'=$iis
	matrix colnames `sigs'="Variance"	
	eret post `b' `V', esample(`touse')

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
	ereturn scalar ll=scalar(`ll')
	
	* Store ARDL order if lag selection was used
	if "$ARDL_display" != "" {
		ereturn local ardl_order "$ARDL_display"
	}
	
	* Store phis for half-life
	if "`lr'" != "" {
		ereturn matrix phi_i=`phis'
	}

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
	ereturn scalar ll=scalar(`ll')
	
	if "$ARDL_display" != "" {
		ereturn local ardl_order "$ARDL_display"
	}
	
	quie est store pmg, copy title("Summarized pmg estimates")

	if "`full'" !=""{
		quie est restore PMG
	}

	Display, level(`level')
	
	* =====================================================================
	* POST-ESTIMATION DIAGNOSTICS (new in 2.0.1)
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
	* GRAPH VISUALIZATIONS (new in 2.0.1)
	* =====================================================================
	
	if "`graph'" != "" {
		quie est restore PMG
		
		di
		di in smcl in gr "{hline 78}"
		di in gr "{bf:Generating Visualizations}" _col(49) in ye "XTPMG 2.0.1"
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
		SRTable(string) HALFlife(string) IRF(integer 0)] 
	marksample touse
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
		matrix colnames `b'=`names'
		foreach xx of local names{
			local newname "`newname' `_dta[iis]'_`i'`xx'"
		}
		matrix `b0'=nullmat(`b0'),`b'
		matrix `VV'[(`j'-1)*(`kk')+1,(`j'-1)*(`kk')+1]=`V'
		matrix `B'=nullmat(`B') \ `b'
		local j=`j'+1
	}

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
	
	if "$ARDL_display" != "" {
		ereturn local ardl_order "$ARDL_display"
	}
	
	quie est store MG, copy title("Full mg estimates")
	if "`full'"==""{
		quie est restore mg
	}
	Display, level(`level')
end

program define EstDFE, eclass
	syntax [if] [in], EC(string) [Level(integer `c(level)')] 
	marksample touse
	tempname nl names sigma
	quie xtreg $SRy $LRy $LRx $SRx if `touse', level(`level') fe $cluster
	quie est store rDFE, copy title("Reduced form dfe estimates")
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
	eret local model="fe"
	eret scalar sigma=`sigma' 
	
	if "$ARDL_display" != "" {
		eret local ardl_order "$ARDL_display"
	}
	
	quie est store DFE, title("Dynamic fixed effects estimates")
	Display, level(`level')
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
* NEW IN 2.0.1: SelectLags — Automatic lag selection via AIC/BIC
* Searches over ARDL(p, q1, ..., qk) and MODIFIES $SRx accordingly
* =========================================================================

program define SelectLags
	syntax [if] [in], MAXLag(integer) LAGSel(string) IVar(string) TVar(string)
	marksample touse
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Automatic Lag Selection}" _col(49) in ye "XTPMG 2.0.1"
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
				if `touse' & `ivar' == `i', $nocons
			
			if !_rc & e(N) > 0 {
				local k_params = e(rank)
				scalar `curr_aic' = -2 * e(ll) + 2 * `k_params'
				scalar `curr_bic' = -2 * e(ll) + `k_params' * ln(`ni')
				
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
		* ============================================================
		local xidx = 0
		foreach xvar of local unique_x {
			local xidx = `xidx' + 1
			
			scalar `best_aic' = .
			scalar `best_bic' = .
			local best_q_aic_i = 1
			local best_q_bic_i = 1
			
			forvalues q = 1/`maxlag' {
				* Build: d.x, Ld.x, L2d.x, ..., L(q-1)d.x
				local xlag "d.`xvar'"
				if `q' > 1 {
					forvalues lag = 1/`= `q' - 1' {
						local xlag "`xlag' L`lag'D.`xvar'"
					}
				}
				
				* Build the rest of the SR vars (other x's unchanged)
				local other_sr ""
				foreach ox of local unique_x {
					if "`ox'" != "`xvar'" {
						local other_sr "`other_sr' d.`ox'"
					}
				}
				
				capture quie regress $SRy $LRx `xlag' `other_sr' ///
					if `touse' & `ivar' == `i', $nocons
				
				if !_rc & e(N) > 0 {
					local k_params = e(rank)
					scalar `curr_aic' = -2 * e(ll) + 2 * `k_params'
					scalar `curr_bic' = -2 * e(ll) + `k_params' * ln(`ni')
					
					if scalar(`curr_aic') < scalar(`best_aic') {
						scalar `best_aic' = scalar(`curr_aic')
						local best_q_aic_i = `q'
					}
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
		local mode_q_aic = 1
		local mode_q_aic_cnt = 0
		forvalues q = 1/`maxlag' {
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
		
		local mode_q_bic = 1
		local mode_q_bic_cnt = 0
		forvalues q = 1/`maxlag' {
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
* NEW IN 2.0.1: DisplaySRTable — Per-panel short-run coefficients
* =========================================================================

program define DisplaySRTable
	syntax, IVar(string)
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Panel-Specific Short-Run Coefficients}" _col(49) in ye "XTPMG 2.0.1"
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
* NEW IN 2.0.1: DisplayHalfLife — Half-life of adjustment
* =========================================================================

program define DisplayHalfLife
	syntax, IVar(string) EC(string)
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Half-Life of Adjustment to Long-Run Equilibrium}" ///
		_col(49) in ye "XTPMG 2.0.1"
	di in gr "  Formula: half_life = ln(2) / |phi_i|"
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
	
	foreach i of global iis {
		local coefname "`ivar'_`i':`ec'"
		
		capture local phi = _b[`coefname']
		if _rc {
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
			local hl = ln(2) / abs(`phi')
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
* NEW IN 2.0.1: SimulateIRF — Impulse response simulation
* =========================================================================

program define SimulateIRF
	syntax, Periods(integer) IVar(string) EC(string)
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Impulse Response Function (Simulated)}" ///
		_col(49) in ye "XTPMG 2.0.1"
	di in gr "  Shock: One-unit deviation from long-run equilibrium at t=0"
	di in gr "  Tracing adjustment path via error-correction mechanism"
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
	
	foreach i of global iis {
		local coefname "`ivar'_`i':`ec'"
		capture local phi = _b[`coefname']
		if !_rc & `phi' < 0 {
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
	local half_life = ln(2) / abs(`mean_phi')
	local q90_life = ln(10) / abs(`mean_phi')
	
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
* ENHANCED DISPLAY (updated for 2.0.1)
* =========================================================================

program define Display
	syntax [,Level(integer `c(level)')]
	
	if "`e(model)'"=="pmg" | "`e(model)'"=="PMG"{
		#delimit ;
		di _n in smcl in gr "{hline 78}" ;
		di in gr "{bf:Pooled Mean Group Regression}"
		   _col(49) in ye "XTPMG v2.0.1" ;
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
	if "`e(model)'"=="fe"{
		quie est restore DFE
		if "$cluster"!=""{
			di _n in smcl in gr "{hline 78}"
			di in ye "Standard errors adjusted with " "$cluster" " option."
		}		
		#delimit ;
		di in smcl in gr "{hline 78}";
		di in gr "{bf:Dynamic Fixed Effects Regression:} " 
			in ye "Estimated Error Correction Form"
		   _col(49) "XTPMG v2.0.1" ;
		di in gr "(Estimate results saved as " in ye "DFE" in gr ")";
		di in smcl in gr "{hline 78}";

		#delimit cr
	}
	if "`e(model)'"=="mg" | "`e(model)'"=="MG"{
		#delimit ;	
		di _n in smcl in gr "{hline 78}";
		di in gr "{bf:Mean Group Estimation:} " in ye "Error Correction Form"
		   _col(49) "XTPMG v2.0.1" ;
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
* NEW IN 2.0.1: GRAPH VISUALIZATIONS
* Beautiful Stata graphs for panel ARDL diagnostics
* =========================================================================


* =========================================================================
* PlotIRF — Impulse Response Function graph
* =========================================================================

program define PlotIRF
	syntax, Periods(integer) IVar(string) EC(string)
	
	tempname fullb
	matrix `fullb' = e(b)
	
	* Compute mean ECT coefficient
	local sum_phi = 0
	local n_valid = 0
	
	foreach i of global iis {
		local coefname "`ivar'_`i':`ec'"
		capture local phi = _b[`coefname']
		if !_rc & `phi' < 0 {
			local sum_phi = `sum_phi' + `phi'
			local n_valid = `n_valid' + 1
		}
	}
	
	if `n_valid' == 0 {
		di in re "  Cannot plot IRF: no convergent panels."
		exit
	}
	
	local mean_phi = `sum_phi' / `n_valid'
	local half_life = ln(2) / abs(`mean_phi')
	
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
		title("{bf:Impulse Response Function}", 
			size(large) color(black))
		subtitle("Error Correction Adjustment Path — XTPMG 2.0.1", 
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
		capture local coef = _b[`coefname']
		if !_rc {
			capture local se = _se[`coefname']
			qui replace panel_id = "Panel `i'" in `idx'
			qui replace phi = `coef' in `idx'
			
			if !_rc & `se' > 0 {
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
			qui replace phi = 0 in `idx'
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
		subtitle("Speed of Adjustment Coefficients — XTPMG 2.0.1", 
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
		capture local phi = _b[`coefname']
		qui replace panel_id = "Panel `i'" in `idx'
		
		if !_rc & `phi' < 0 & `phi' > -2 {
			local hl = ln(2) / abs(`phi')
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
		subtitle("Time to Close 50% of Disequilibrium Gap — XTPMG 2.0.1", 
			size(medsmall) color(gs5))
		xtitle("Half-Life (periods)", size(medium))
		ytitle("Panel", size(medium))
		xlabel(, format(%4.1f) labsize(small)
			grid glcolor(gs14) glpattern(dot))
		ylabel(1/`n_panels', valuelabel labsize(vsmall) angle(0))
		xline(`mean_hl', lcolor("231 76 60") lwidth(medthin) lpattern(dash))
		legend(off)
		note("Mean half-life = `: di %4.2f `mean_hl'' periods (dashed red line)"
			 "Formula: half_life = ln(2) / |{&phi}{sub:i}|",
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
			subtitle("Heterogeneous SR dynamics across panels — XTPMG 2.0.1",
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

