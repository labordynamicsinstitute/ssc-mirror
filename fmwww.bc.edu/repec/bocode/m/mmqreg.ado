*! v2.4 Adds Decomposed Split-Panel Jackknife (jknife option) integrating
*!      the MM-QR-JK methodology. JK correction applied to scale g(.) and
*!      quantile Q(.) separately, then recombined as b + g_jk * Q_jk(tau).
*!      Also adds mmqregplot companion.
*! Authors: Fernando Rios-Avila (original, v1.0-v2.3)
*!          Dr Merwan Roudane (contributor, v2.4 extension)
*!          Contact: merwanroudane920@gmail.com
* v2.3 More Efficient rewritten. adds NOls
* v2.21 keep singletons
* v2.2  Simultaneous Q's for model simple
* v2.1  Corrects Bug Clustered SE and DF
* v2  Corrects Bug and Speeds up Clustered SE
* v1.8 adds Obs
* v1.7 corrects e(cmd_line) to cmdline and problems with "program drop"
* v1.6 Small improvements estimation efficiencies. I also allow for WEIGHTS!
* v1.5 August 2020 MMQREG by Fernando Rios-Avila
* Bug for simmultanous MMQREG fixed
* v1.4 July 2020 MMQREG by Fernando Rios-Avila
* v1.3 June 2020 MMQREG by Fernando Rios-Avila
* v1.2 June 2020 MMQREG by Fernando Rios-Avila
* v1.1 May 2020 MMQREG by Fernando Rios-Avila
* v1.0 MMQREG by Fernando Rios-Avila

/*===========================================================================
  mmqreg - Method of Moments Quantile Regression Estimator
  Implements Machado & Santos Silva (2019) MM-QR estimator.
  SPJ correction implements the split-panel Jackknife approach of
  Dhaene & Jochmans (2015) as applied in the xtqreg JK literature.
===========================================================================*/

** verifies nlist using own rules
program define mynlist, rclass
	syntax anything,
	numlist `anything',  range(>0 <100) sort
	loca j scalar(_pi)
	foreach i in  `r(numlist)' {
		if `i'!=`j' {
		    local numlist `numlist' `i'
		}
		local j=`i'
	}
	return local numlist `numlist'
end

** =========================================================
** Main entry point
** =========================================================
program define mmqreg, eclass

 if replay() {
	if "`e(cmd)'"=="mmqreg" {
	    display_mmqreg
		exit
	}
	else {
	    display in red "Last estimations not found"
		error 301
	}
 }

	syntax varlist(fv) [ pw aw iw fw] [in] [if]  ,  ///
						[Absorb(varlist) ///
						 Quantile(str)   ///
						denopt(str)      ///
						robust	 		 ///
						cluster(varname) ///
						dfadj            ///
						nowarning NOLS   ///
						JKnife           /// NEW v2.4: Split-Panel Jackknife SE
						 ]
    version 13
						 
	** verify absorb dependencies
	if "`absorb'"!="" {
		qui:capture which hdfe
		if _rc==111 {
			display in red "Absorb Option requires community-contributed command " as result "hdfe"
			display as text "You can install it using {stata ssc install hdfe}"
			exit 111
		}
		qui:capture which ftools
		if _rc==111 {
			display in red "Absorb Option requires community-contributed command " as result "ftools"
			display as text "You can install it using {stata ssc install ftools}"
			exit 111
		}
	}

	** JKnife requires panel structure
	if "`jknife'"!="" {
		qui: capture xtset
		if _rc!=0 {
			display in red "JKnife option requires panel data. Please xtset your data first."
			exit 459
		}
		if "`r(timevar)'"=="" {
			display in red "JKnife option requires both panel and time variables (xtset panelvar timevar)."
			exit 459
		}
	}

	** dispatch
	if "`absorb'"=="" {
		if "`jknife'"=="" {
			mmqreg1 `0'
		}
		else {
			mmqreg1_jk `0'
		}
	}
	else {
		if "`jknife'"=="" {
			mmqreg2 `0'
		}
		else {
			mmqreg2_jk `0'
		}
	}
	display_mmqreg
end


** =========================================================
** Display
** =========================================================
program define display_mmqreg
	display as text _n "{hline 60}"
	display as text "  MM-QR Estimator (Machado & Santos Silva 2019)"
	display as text "{hline 60}"
	display as text "  Number of obs    = " as result "`=e(N)'"
	if "`e(clustvar)'"!="" {
		display as text "  Number of clusters= " as result "`=e(N_clust)'"
		display as text "  Cluster variable  = " as result "`e(clustvar)'"
	}
	if "`e(fevlist)'"!="" {
		display as text "  Absorbed FE       = " as result "`e(fevlist)'"
	}
	if "`e(jk)'"!="" {
		display as text "  Std. Errors       = " as result "Split-Panel Jackknife"
	}
	else if "`e(vcetype)'"!="" {
		display as text "  Std. Errors       = " as result "`e(vcetype)'"
	}
	if rowsof(e(qth))==1 & colsof(e(qth))==1 {
	    local qqq=det(e(qth))*100
		display as text "  Quantile(s)       = " as result %3.2g `qqq'
	}
	else {
		local qlist=""
		local ncol=colsof(e(qth))
		forvalues i=1/`ncol' {
			local qval=e(qth)[1,`i']*100
			local qlist "`qlist'" %3.2g `qval' " "
		}
		display as text "  Quantile(s)       =" as result "`qlist'"
	}
	display as text "{hline 60}"
	ereturn display
end


** =========================================================
** mmqreg1: No FE, Analytical SE
** =========================================================
program define mmqreg1, eclass sortpreserve
	qui:syntax varlist(fv) [in] [if] [ pw aw iw fw], ///
		[Quantile(str)  denopt(str) robust cluster(varname) dfadj nowarning NOLS JKnife]
	** start with sample checks
	capture drop ___zero___
	marksample touse
	markout `touse' `varlist' `absorb'
 	if "`quantile'"=="" local quantile 50
	capture mynlist "`quantile'"
	if _rc==125 {
		display in red "Quantile must be larger than 0 and smaller than 100"
		exit 125
	}
	local quantile  `r(numlist)'

	** Robust
	if "`robust'"!="" & "`cluster'"=="" local x x

	if "`exp'"!="" {
		tempvar mwgt
		qui:gen double `mwgt'`exp'
	}
	else {
		tempvar mwgt
		gen byte `mwgt' =1
	}

	** variable definitions
    tokenize `varlist'
    local y `1'
    macro shift
    local xvar `*'

	** location
	qui:reg `y' `xvar' if `touse' [`weight'`exp']
	tempname lfb
	matrix `lfb'=e(b)
	** residuals
	tempvar res ares
	qui:predict double `res' , res
	qui:gen     double `ares'=abs(`res')
	** scale
	tempvar ares_hat st_res
	qui:reg `ares' `xvar' if `touse' [`weight'`exp']
	tempname sfb sfV
	matrix `sfb'=e(b)
	qui:predict double `ares_hat'
	qui:sum `ares_hat' if `touse', meanonly
	if `r(min)'<=0 & "`warning'"=="" {
		qui:count  if `touse'	& `ares_hat'<0
	    display  "WARNING: some fitted values of the scale function are negative" ///
				_n "Consider using a different model specification" ///
				_n "`r(N)' Observations have negative predicted Scale values"
	}
	qui:gen double `st_res'=`res'/`ares_hat'
	tempname qval qth fden
	foreach q in `quantile' {
		if "`denopt'"!="" local denopt=",`denopt'"
		qui:qreg `st_res' if `touse' [iw=`mwgt'], q(`q') vce(iid `denopt')
		local denmethod `e(denmethod)'
		local bwmethod `e(bwmethod)'
		matrix `qval'=nullmat(`qval'),_b[_cons]
		matrix `fden'=nullmat(`fden'),`e(f_r)'
		matrix `qth' =nullmat(`qth') ,`e(q)'
	}

	** equation names
	local bnm: colnames `sfb'
	               local vce= 0
	if "`robust'"!=""  local vce= 1
	if "`cluster'"!="" local vce= 2

	if "`nols'"=="" local ls 0
	else            local ls 1

	if `vce'==0 {
		mata:mmqreg_vce1("`y'","`xvar' `cns'","`lfb'","`sfb'", ///
				 "`qval'","`qth'","`fden'", "`touse'","`dfadj'","`mwgt'",`ls')
	}
	else {
		if `vce'==2 sort `cluster'

		mata:mmqreg_vce1x("`y'","`xvar'","`lfb'","`sfb'", ///
					     "`qval'","`qth'","`fden'","`cluster' ", ///
						  "`touse'","`dfadj'","`mwgt'",`vce',`ls')
 	}

	if "`nols'"=="" local eqnm="location "*colsof(`sfb')+"scale "*colsof(`sfb')
		local extraeq="location "*colsof(`sfb')+"scale "*colsof(`sfb')+" qtile"
	local extracl="`bnm' "*2
	local nmb:word count `quantile'

	if `nmb'>1 {
		foreach q in `quantile' {
			local strq=subinstr("`q'",".",  "_",.)
			local eqnm="`eqnm'"+"qtile_`strq' "*colsof(`sfb')
			local extracl ="`extracl'"+"qtile_`strq' "
		}
	}
	else {
		local eqnm="`eqnm'"+"qtile "*colsof(`sfb')
		local extracl ="`extracl'"+"qtile"
	}

	if "`nols'"=="" local bnm2="`bnm' "*(2+colsof(`qval'))
	else            local bnm2="`bnm' "*(colsof(`qval'))

	matrix colname __vq = `bnm2'
	matrix rowname __vq = `bnm2'
	matrix colname __bq = `bnm2'
	matrix coleq __vq = `eqnm'
	matrix roweq __vq = `eqnm'
	matrix coleq __bq = `eqnm'

	matrix colname __vqq = `extracl'
	matrix rowname __vqq = `extracl'
	matrix colname __bqq = `extracl'
	matrix coleq __vqq = `extraeq'
	matrix roweq __vqq = `extraeq'
	matrix coleq __bqq = `extraeq'

	sum `touse', meanonly
	local nobs=r(sum)
	if "`cluster'"!="" {
		tempvar vals
		qui:bys `touse' `cluster': gen byte `vals' = (_n == 1)*`touse'
		su `vals' , meanonly
		local N_clust = `r(sum)'
	}

	ereturn post __bq __vq, esample(`touse') buildfvinfo findomitted  obs(`nobs')
	ereturn local cmd "mmqreg"
	ereturn local cmdline "mmqreg `0'"
	ereturn local vce "mmvce"
	ereturn matrix qth `qth'
	ereturn matrix qval `qval'
	ereturn matrix fden `fden'
	ereturn matrix bls __bqq
	ereturn matrix vls __vqq
	ereturn local fevlist `absorb'
	local 1:word 1 of `varlist'
	ereturn local depvar `1'
	ereturn	local denmethod `denmethod'
	ereturn	local bwmethod `bwmethod'

	if "`robust'`cluster'"!="" {
		ereturn local vcetype  "Robust"
		if "`cluster'"!="" {
    		ereturn local vce "cluster"
			ereturn scalar N_clust =`N_clust'
			ereturn local clustvar "`cluster'"
		}
	}

	if "`dfadj'"!= "" {
		ereturn scalar df_r = scalar(df_r)
	}

end


** =========================================================
** mmqreg2: FE (absorb), Analytical SE
** =========================================================
program define mmqreg2, eclass sortpreserve
	qui:syntax varlist(fv) [in] [if] [aw pw iw fw], ///
		[Quantile(str) Absorb(varlist) cluster(varname) denopt(str) dfadj robust nowarning NOLS JKnife]
	** start with sample checks
	capture drop _i_*
	capture drop ___zero___
	marksample touse
	markout `touse' `varlist' `absorb' `cluster'
 	if "`quantile'"=="" local quantile 50
	capture mynlist "`quantile'"
	if _rc==125 {
		display in red "Quantile must be larger than 0 and smaller than 100"
		exit 125
	}
	local quantile  `r(numlist)'

	if "`robust'"!="" & "`cluster'"=="" local x x

	if "`exp'"!="" {
		tempvar mwgt
		gen double `mwgt'`exp'
	}
	else {
		tempvar mwgt
		gen byte `mwgt' =1
	}

	qui:myhdfe `varlist' if `touse' [`weight'`exp'], abs(`absorb')
	local df_a= `r(df_a)'
	local bnm `r(fullvar)'
	gettoken gfn bnm:bnm
	local acxvar `r(finvar)'
	qui:gen byte ___zero___=0

	tokenize `acxvar'
    local y `1'
    macro shift
    local xvar `*'

	markout `touse'  `y'
	qui:reg `y' `xvar' if `touse' [`weight'`exp']
	tempname lfb
	matrix `lfb'=e(b)
	tempvar res ares
	qui:predict double `res' , res
	qui:gen     double `ares'=abs(`res')

	qui:myhdfe `ares' if `touse' [`weight'`exp'], abs(`absorb')
	tempvar ares_hat st_res
	qui:reg _i_`ares' `xvar' if `touse' [`weight'`exp']
	tempname sfb sfV
	matrix `sfb'=e(b)
	qui:predict double `ares_hat', res
	qui:replace `ares_hat'=`ares'-`ares_hat'
	qui:sum `ares_hat' if `touse'
	if `r(min)'<=0 & "`warning'"=="" {
		qui:count  if `touse'	& `ares_hat'<0
	    display  "WARNING: some fitted values of the scale function are negative" ///
				_n "Consider using a different model specification" ///
				_n "`r(N)' Observations have negative predicted Scale values"
	}
	qui:gen double `st_res'=`res'/`ares_hat'
	tempname qval qth fden
	foreach q in `quantile' {
		if "`denopt'"!="" local denopt=",`denopt'"
		qui:qreg `st_res' if `touse' [iw=`mwgt'], q(`q') vce(iid `denopt')
		local denmethod `e(denmethod)'
		local bwmethod `e(bwmethod)'
		matrix `qval'=nullmat(`qval'),_b[_cons]
		matrix `fden'=nullmat(`fden'),`e(f_r)'
		matrix `qth' =nullmat(`qth') ,`e(q)'
	}

		               local vce= 0
	if "`robust'"!=""  local vce= 1
	if "`cluster'"!="" local vce= 2

	if "`nols'"=="" local ls 0
	else            local ls 1

	if `vce'==0 {
		mata:mmqreg_vce2("`y'","`xvar' `cns'","`st_res'","`ares_hat'","`lfb'","`sfb'", ///
					 "`qval'","`qth'","`fden'", `df_a', "`touse'","`dfadj'","`mwgt'",`ls')
	}
	else {
		if `vce'==2 sort `cluster'
		mata:mmqreg_vce2x("`y'","`xvar' `cns'","`st_res'", ///
					     "`ares_hat'","`lfb'","`sfb'", ///
					     "`qval'","`qth'","`fden'", "`cluster' ", ///
					     `df_a', "`touse'","`dfadj'", "`mwgt'",`vce',`ls')
 	}

	if "`nols'"=="" local eqnm="location "*colsof(`sfb')+"scale "*colsof(`sfb')
		local extraeq="location "*colsof(`sfb')+"scale "*colsof(`sfb')+" qtile"
	local extracl="`bnm' "*2
	local nmb:word count `quantile'

	if `nmb'>1 {
		foreach q in `quantile' {
			local strq=subinstr("`q'",".","_",.)
			local eqnm="`eqnm'"+"qtile_`strq' "*colsof(`sfb')
			local extracl ="`extracl'"+"qtile_`strq' "
		}
	}
	else {
		local eqnm="`eqnm'"+"qtile "*colsof(`sfb')
		local extracl ="`extracl'"+"qtile"
	}

	if "`nols'"=="" local bnm2="`bnm' "*(2+colsof(`qval'))
	else            local bnm2="`bnm' "*(colsof(`qval'))

	matrix colname __vq = `bnm2'
	matrix rowname __vq = `bnm2'
	matrix colname __bq = `bnm2'
	matrix coleq __vq = `eqnm'
	matrix roweq __vq = `eqnm'
	matrix coleq __bq = `eqnm'

	matrix colname __vqq = `extracl'
	matrix rowname __vqq = `extracl'
	matrix colname __bqq = `extracl'
	matrix coleq __vqq = `extraeq'
	matrix roweq __vqq = `extraeq'
	matrix coleq __bqq = `extraeq'

	sum `touse', meanonly
	local nobs=r(sum)
	if "`cluster'"!="" {
		tempvar vals
		qui:bys `touse' `cluster': gen byte `vals' = (_n == 1)*`touse'
		su `vals' , meanonly
		local N_clust = `r(sum)'
	}

	ereturn post __bq __vq, esample(`touse') buildfvinfo findomitted  obs(`nobs')

	ereturn local cmd "mmqreg"
	ereturn local cmdline "mmqreg `0'"
	ereturn local vce "mm-vce"
	ereturn matrix qth `qth'
	ereturn matrix qval `qval'
	ereturn matrix fden `fden'
	ereturn matrix bls __bqq
	ereturn matrix vls __vqq
	ereturn local fevlist `absorb'
	local 1:word 1 of `varlist'
	ereturn local depvar `1'
	ereturn	local denmethod `denmethod'
	ereturn	local bwmethod `bwmethod'

	if "`robust'`cluster'"!="" {
		ereturn local vcetype  "Robust"
		if "`cluster'"!="" {
    		ereturn local vce "cluster"
			ereturn scalar N_clust =`N_clust'
			ereturn local clustvar "`cluster'"
		}
	}

	if "`dfadj'"!= "" {
		ereturn scalar df_r = scalar(df_r)
	}
	drop _i_* ___zero___
end


** =========================================================
** mmqreg1_jk: No-FE with Decomposed Split-Panel Jackknife
**   Implements the MM-QR-JK methodology:
**     g_jk    = 2*g  - (N0/N)*g0  - (N1/N)*g1
**     Q_jk(t) = 2*Q(t) - (N0/N)*Q0(t) - (N1/N)*Q1(t)
**     b_jk(t) = b_loc + g_jk * Q_jk(t)
** =========================================================
program define mmqreg1_jk, eclass sortpreserve
	syntax varlist(fv) [in] [if] [ pw aw iw fw], ///
		[Quantile(str) denopt(str) robust cluster(varname) dfadj nowarning NOLS JKnife]

	marksample touse
	markout `touse' `varlist'
	if "`quantile'"=="" local quantile 50
	capture mynlist "`quantile'"
	if _rc==125 {
		display in red "Quantile must be larger than 0 and smaller than 100"
		exit 125
	}
	local quantile `r(numlist)'

	qui: xtset
	local timevar "`r(timevar)'"

	** Sub-call options (no jknife to avoid recursion)
	local subopts
	if "`quantile'"!=""  local subopts `subopts' quantile(`quantile')
	if "`denopt'"!=""    local subopts `subopts' denopt(`denopt')
	if "`robust'"!=""    local subopts `subopts' robust
	if "`cluster'"!=""   local subopts `subopts' cluster(`cluster')
	if "`dfadj'"!=""     local subopts `subopts' dfadj
	if "`warning'"!=""   local subopts `subopts' nowarning
	if "`nols'"!=""      local subopts `subopts' nols
	if "`exp'"!=""       local wgtstr [`weight'`exp']

	tokenize `varlist'
	local y  `1'
	macro shift
	local xvars `*'

	** ---- Full-sample estimation ----
	qui: mmqreg1 `varlist' if `touse' `wgtstr', `subopts'
	local nobs = e(N)
	tempname b_full V_full qth_full qval_full fden_full bls_full vls_full
	matrix `b_full'    = e(b)
	matrix `V_full'    = e(V)
	matrix `qth_full'  = e(qth)
	matrix `qval_full' = e(qval)
	matrix `fden_full' = e(fden)
	matrix `bls_full'  = e(bls)
	capture: matrix `vls_full' = e(vls)
	local colnms_full:  colnames e(b)
	local eqnms_full:   coleq    e(b)
	scalar N_full = e(N)
	local nq = colsof(`qval_full')
	local nk = (colsof(`bls_full') - `nq') / 2

	** ---- Half-panel splits via time-variable parity ----
	tempvar s touse_h
	qui: gen byte `s' = 2*((`timevar'/2) - int(`timevar'/2)) if `touse'

	** Even half (s=0)
	qui: gen byte `touse_h' = (`touse'==1 & `s'==0)
	qui: mmqreg1 `varlist' if `touse_h' `wgtstr', `subopts'
	tempname bls_h0 qval_h0
	matrix `bls_h0'  = e(bls)
	matrix `qval_h0' = e(qval)
	scalar N_h0 = e(N)

	** Odd half (s=1)
	qui: replace `touse_h' = (`touse'==1 & `s'==1)
	qui: mmqreg1 `varlist' if `touse_h' `wgtstr', `subopts'
	tempname bls_h1 qval_h1
	matrix `bls_h1'  = e(bls)
	matrix `qval_h1' = e(qval)
	scalar N_h1 = e(N)

	** ---- Extract location & scale blocks (bls = [b_loc | g_scale | qvals]) ----
	tempname b_loc g_full g_h0 g_h1
	local k1 = `nk'
	local k2 = `nk' + 1
	local k3 = 2*`nk'
	matrix `b_loc'  = `bls_full'[1, 1..`k1']
	matrix `g_full' = `bls_full'[1, `k2'..`k3']
	matrix `g_h0'   = `bls_h0'[1,  `k2'..`k3']
	matrix `g_h1'   = `bls_h1'[1,  `k2'..`k3']

	** ---- Decomposed JK corrections ----
	tempname g_jk Q_jk
	matrix `g_jk' = 2*`g_full' - (N_h0/N_full)*`g_h0' - (N_h1/N_full)*`g_h1'
	matrix `Q_jk' = 2*`qval_full' - (N_h0/N_full)*`qval_h0' ///
	                              - (N_h1/N_full)*`qval_h1'

	** ---- Rebuild b_jk to mirror e(b) structure ----
	tempname b_new
	if "`nols'"=="" {
		matrix `b_new' = `b_loc', `g_jk'
	}
	forvalues j = 1/`nq' {
		local qj = `Q_jk'[1,`j']
		tempname bq_j
		matrix `bq_j' = `b_loc' + (`qj')*`g_jk'
		matrix `b_new' = nullmat(`b_new'), `bq_j'
	}

	matrix colnames `b_new' = `colnms_full'
	matrix coleq    `b_new' = `eqnms_full'
	matrix colnames `V_full' = `colnms_full'
	matrix rownames `V_full' = `colnms_full'
	matrix coleq    `V_full' = `eqnms_full'
	matrix roweq    `V_full' = `eqnms_full'

	** Updated bls with JK-corrected scale & quantile values
	tempname bls_new
	matrix `bls_new' = `b_loc', `g_jk', `Q_jk'
	local extracl ""
	forvalues i = 1/`nk' { local extracl `extracl' c`i' }
	** keep names from original
	local extracl_orig: colnames `bls_full'
	matrix colnames `bls_new' = `extracl_orig'
	local extraeq_orig: coleq `bls_full'
	matrix coleq    `bls_new' = `extraeq_orig'

	ereturn post `b_new' `V_full', esample(`touse') obs(`nobs')
	ereturn local cmd        "mmqreg"
	ereturn local cmdline    "mmqreg `0'"
	ereturn local vce        "jk"
	ereturn local jk         "Split-Panel Jackknife (decomposed)"
	ereturn local jk_formula "b_loc + g_jk * Q_jk(tau)"
	ereturn scalar N_h0      = N_h0
	ereturn scalar N_h1      = N_h1
	ereturn matrix qth       `qth_full'
	ereturn matrix qval      `Q_jk'
	ereturn matrix qval_full `qval_full'
	ereturn matrix fden      `fden_full'
	ereturn matrix bls       `bls_new'
	capture: ereturn matrix vls `vls_full'
	ereturn local fevlist
	ereturn local depvar     `y'
end



** =========================================================
** mmqreg2_jk: FE + Decomposed Split-Panel Jackknife
**   Same MM-QR-JK decomposition as mmqreg1_jk, on the within-
**   transformed (absorbed) model.
** =========================================================
program define mmqreg2_jk, eclass sortpreserve
	syntax varlist(fv) [in] [if] [aw pw iw fw], ///
		[Quantile(str) Absorb(varlist) cluster(varname) denopt(str) dfadj robust nowarning NOLS JKnife]

	marksample touse
	markout `touse' `varlist' `absorb' `cluster'
	if "`quantile'"=="" local quantile 50
	capture mynlist "`quantile'"
	if _rc==125 {
		display in red "Quantile must be larger than 0 and smaller than 100"
		exit 125
	}
	local quantile `r(numlist)'

	qui: xtset
	local timevar "`r(timevar)'"

	** Sub-call options
	local subopts
	if "`quantile'"!=""  local subopts `subopts' quantile(`quantile')
	if "`absorb'"!=""    local subopts `subopts' absorb(`absorb')
	if "`denopt'"!=""    local subopts `subopts' denopt(`denopt')
	if "`robust'"!=""    local subopts `subopts' robust
	if "`cluster'"!=""   local subopts `subopts' cluster(`cluster')
	if "`dfadj'"!=""     local subopts `subopts' dfadj
	if "`warning'"!=""   local subopts `subopts' nowarning
	if "`nols'"!=""      local subopts `subopts' nols
	if "`exp'"!=""       local wgtstr [`weight'`exp']

	tokenize `varlist'
	local y `1'
	macro shift
	local xvars `*'

	** ---- Full sample ----
	qui: mmqreg2 `varlist' if `touse' `wgtstr', `subopts'
	local nobs = e(N)
	tempname b_full V_full qth_full qval_full fden_full bls_full vls_full
	matrix `b_full'    = e(b)
	matrix `V_full'    = e(V)
	matrix `qth_full'  = e(qth)
	matrix `qval_full' = e(qval)
	matrix `fden_full' = e(fden)
	matrix `bls_full'  = e(bls)
	capture: matrix `vls_full' = e(vls)
	local colnms_full:  colnames e(b)
	local eqnms_full:   coleq    e(b)
	scalar N_full = e(N)
	local nq = colsof(`qval_full')
	local nk = (colsof(`bls_full') - `nq') / 2

	** ---- Half panels ----
	tempvar s touse_h
	qui: gen byte `s' = 2*((`timevar'/2) - int(`timevar'/2)) if `touse'

	qui: gen byte `touse_h' = (`touse'==1 & `s'==0)
	qui: mmqreg2 `varlist' if `touse_h' `wgtstr', `subopts'
	tempname bls_h0 qval_h0
	matrix `bls_h0'  = e(bls)
	matrix `qval_h0' = e(qval)
	scalar N_h0 = e(N)

	qui: replace `touse_h' = (`touse'==1 & `s'==1)
	qui: mmqreg2 `varlist' if `touse_h' `wgtstr', `subopts'
	tempname bls_h1 qval_h1
	matrix `bls_h1'  = e(bls)
	matrix `qval_h1' = e(qval)
	scalar N_h1 = e(N)

	** ---- Extract location & scale ----
	tempname b_loc g_full g_h0 g_h1
	local k1 = `nk'
	local k2 = `nk' + 1
	local k3 = 2*`nk'
	matrix `b_loc'  = `bls_full'[1, 1..`k1']
	matrix `g_full' = `bls_full'[1, `k2'..`k3']
	matrix `g_h0'   = `bls_h0'[1,  `k2'..`k3']
	matrix `g_h1'   = `bls_h1'[1,  `k2'..`k3']

	** ---- Decomposed JK ----
	tempname g_jk Q_jk
	matrix `g_jk' = 2*`g_full' - (N_h0/N_full)*`g_h0' - (N_h1/N_full)*`g_h1'
	matrix `Q_jk' = 2*`qval_full' - (N_h0/N_full)*`qval_h0' ///
	                              - (N_h1/N_full)*`qval_h1'

	** ---- Rebuild b_jk ----
	tempname b_new
	if "`nols'"=="" {
		matrix `b_new' = `b_loc', `g_jk'
	}
	forvalues j = 1/`nq' {
		local qj = `Q_jk'[1,`j']
		tempname bq_j
		matrix `bq_j' = `b_loc' + (`qj')*`g_jk'
		matrix `b_new' = nullmat(`b_new'), `bq_j'
	}

	matrix colnames `b_new'  = `colnms_full'
	matrix coleq    `b_new'  = `eqnms_full'
	matrix colnames `V_full' = `colnms_full'
	matrix rownames `V_full' = `colnms_full'
	matrix coleq    `V_full' = `eqnms_full'
	matrix roweq    `V_full' = `eqnms_full'

	tempname bls_new
	matrix `bls_new' = `b_loc', `g_jk', `Q_jk'
	local extracl_orig: colnames `bls_full'
	local extraeq_orig: coleq    `bls_full'
	matrix colnames `bls_new' = `extracl_orig'
	matrix coleq    `bls_new' = `extraeq_orig'

	ereturn post `b_new' `V_full', esample(`touse') obs(`nobs')
	ereturn local cmd        "mmqreg"
	ereturn local cmdline    "mmqreg `0'"
	ereturn local vce        "jk"
	ereturn local jk         "Split-Panel Jackknife (decomposed)"
	ereturn local jk_formula "b_loc + g_jk * Q_jk(tau)"
	ereturn scalar N_h0      = N_h0
	ereturn scalar N_h1      = N_h1
	ereturn matrix qth       `qth_full'
	ereturn matrix qval      `Q_jk'
	ereturn matrix qval_full `qval_full'
	ereturn matrix fden      `fden_full'
	ereturn matrix bls       `bls_new'
	capture: ereturn matrix vls `vls_full'
	ereturn local fevlist    `absorb'
	ereturn local depvar     `y'
end


** =========================================================
** myhdfe helper
** =========================================================
program define myhdfe, rclass
syntax varlist(fv) [if] [in] [aw pw iw fw], abs(varlist)
* step 1. Get list of variables
	marksample touse
	ms_fvstrip `varlist' if `touse', expand dropomit
	local fullxv  `r(fullvarlist)'
	local parxv   `r(varlist)'
	hdfe `varlist' if `touse' [`weight'`exp'], abs(`abs') gen(_i_)   keepsingletons
	local df_a `e(df_a)'
	local actxv   `r(varlist)'
	markout `touse' _i_*
	local wcnt=wordcount("`fullxv'")
	local ii=1
	forvalues i=1/`wcnt' {
		local 1:word `i'  of `fullxv'
		local 2:word `ii' of `parxv'
		local 3:word `ii' of `actxv'
		if "`1'"=="`2'" {
			local fvarxv `fvarxv' _i_`3'
			local ii=`ii'+1
			if "`weight'`exp'"!="" sum `1' if `touse' [`weight'`exp'], meanonly
			sum _i_`3' if `touse' , meanonly
			if r(max)<epsfloat() {
				qui:replace _i_`3'=0
			}
			else {
			    sum `1' if `touse' [`weight'`exp'], meanonly
			    replace _i_`3'=_i_`3'+r(mean)
			}
		}
		else {
			local fvarxv `fvarxv' ___zero___
		}
	}
	return local finvar `fvarxv'
	return local fullvar `fullxv' _cons
	return scalar df_a= `df_a'
end


** =========================================================
** Mata functions
** =========================================================
mata:

void mmqreg_vce1x(string scalar yvar_,  string scalar xvar_,
			 	  string scalar beta_,  string scalar gama_,
				  string scalar qval_,  string scalar qth_,
				  string scalar fden_,  string scalar cvar_,
				  string scalar touse,  string scalar dfadj,
				  string scalar wgt_ ,  real scalar vce, real scalar nls) {
		real matrix xvar, yvar, wgt, cvar
		real vector beta, gama , betaq
		real vector qval, qth, fden
		real matrix u_hat, u, v, w
		real matrix qxx, iqxx, xi, xi2, omg
		real scalar us1, nobs, i, qs, k , nn
		real matrix vcvq
		real matrix omgx

		st_view(yvar =.,.,yvar_ ,touse)
		xvar =st_data(.,xvar_ ,touse),J(rows(yvar),1,1)

		if (vce==2) {
			st_view(cvar =.,.,cvar_ ,touse)
			real matrix info
			real scalar nc
			info = panelsetup(cvar, 1)
			nc   = rows(info)
		}

		wgt=st_data(.,wgt_  ,touse)
		wgt=wgt:/mean(wgt)
		beta = st_matrix(beta_)'
		gama = st_matrix(gama_)'
		nobs = rows(xvar)
		k    = cols(xvar)
		qval = st_matrix(qval_)
		qth  = st_matrix(qth_)
		fden = st_matrix(fden_)
		qs  =cols(qth)
		u_hat=(xvar*gama)
		u    = (yvar-xvar*beta)
		v    = 2*u:*((u:>=0):-mean(u:>=0,wgt)):-u_hat

		qxx = quadcross(xvar,wgt,xvar)
	    iqxx = invsym(qxx)

		us1 = mean(u_hat,wgt)

		if1 = nobs*(xvar:*u)*iqxx
		if2 = nobs*(xvar:*v)*iqxx

		w=J(nobs,qs,0)

 		for(i=1;i<=qs;i++) {
			w[.,i]= 1/fden[i] * (qth[i]:-((u:-qval[i]*u_hat):<=0)) :* u_hat:/us1 - u:/us1 :-  qval[i]*v:/us1
		}

		if (nls==0) {
			xi2=( I(k)    , J(k,k+qs,0)      )  \
			( J(k,k,0), I(k) , J(k,qs,0) )  \
			J(qs,1,1)#I(k) , qval'#I(k) , I(qs) # (gama)
			betaq=beta', gama'
		}
		else {
			xi2= J(qs,1,1)#I(k) , qval'#I(k) , I(qs) # (gama)
			betaq=J(1,0,.)
		}

		real matrix xvar_uhat, omg_x
		omg_x     =(if1,if2,w):*wgt

		if (vce==1) {
			omg       =quadcross(omg_x,omg_x)/(nobs^2)
		}
		if (vce==2) {
 			omg_xx 	=panelsum(omg_x,info)
 			omg     =quadcross(omg_xx,omg_xx)/(nobs^2)
			real scalar ncone
			ncone=0
		}

		for(i=1;i<=qs;i++) {
			betaq=betaq,(beta+gama*qval[i])'
		}

		if (dfadj!="") {
			nn=nobs-(k-diag0cnt(qxx))
			ncone=1
		}
		else {
			nn=nobs
			if (vce==2) nn=nobs-1
		}

		if (vce==1) vcvq = xi2*omg*xi2'*(nobs/nn)
		if (vce==2) vcvq = xi2*omg*xi2'*(nobs-1)/nn*(nc/(nc-ncone))

		st_matrix("__bq",betaq)
		st_matrix("__vq",makesymmetric(vcvq) )
		st_numscalar("df_r", nn)
		st_matrix("__bqq",(beta', gama',qval))
		st_matrix("__vqq",makesymmetric(omg))
}

void mmqreg_vce1(string scalar yvar_, string scalar xvar_,
				 string scalar beta_,  string scalar gama_,
				 string scalar qval_,  string scalar qth_,
				 string scalar fden_,  string scalar touse,
				 string scalar dfadj, string scalar wgt_ , real scalar nls) {
		real matrix xvar, yvar, wgt
		real vector beta, gama , betaq
		real vector qval, qth, fden
		real matrix u_hat, u, v, w,  euv, euw , evw, ew2
		real matrix px, pxx , qxx, iqxx, xi, xi2, omg
		real scalar us1, us2, nn,nobs , i, qs, k, eu2, ev2
		real matrix vcvq

		st_view(yvar=.,.,yvar_,touse)
		xvar=st_data(.,xvar_,touse),J(rows(yvar),1,1)

		wgt =st_data( ., wgt_,touse)
		wgt = wgt:/mean(wgt)
		beta=st_matrix(beta_)'
		gama=st_matrix(gama_)'
		nobs=rows(xvar)
		k   =cols(xvar)
		qval=st_matrix(qval_)
		qth =st_matrix(qth_)
		fden=st_matrix(fden_)

		qs=cols(qth)

		u_hat=(xvar*gama)
		u    = (yvar-xvar*beta):/u_hat
		v    = 2*u:*((u:>=0):-mean(u:>=0,wgt)):-1

		qxx   = quadcross(xvar,wgt,xvar)
		iqxx  = invsym(qxx)

		us1 = mean(u_hat,wgt)
		if1 = nobs*(xvar:*u_hat)*iqxx
		if2 = nobs*(xvar:*u_hat)*iqxx
		ifw = u_hat

		eu2=mean(u:^2,wgt)
		ev2=mean(v:^2,wgt)
		euv=mean(u:*v,wgt)

 		pxx   = quadcross(if1,wgt,if1)
		px    = quadcross(if1,wgt,ifw)

		us1 = mean(u_hat,wgt)
		us2 = quadcross(u_hat,wgt,u_hat)

		w=J(nobs,qs,0)

		for(i=1;i<=qs;i++) {
			w[.,i]=1/fden[i]*(qth[i]:-((u:-qval[i]):<=0)):/us1 - u:/us1 :-  qval[i]*v:/us1
		}

		euw=mean(u:*w,wgt)
		evw=mean(v:*w,wgt)
		ew2=cross(w,wgt,w)/nobs

		if (nls==0) {
			xi2=( I(k)    , J(k,k+qs,0)      )  \
			( J(k,k,0), I(k) , J(k,qs,0) )  \
			J(qs,1,1)#I(k) , qval'#I(k) , I(qs) # (gama)
			betaq=beta', gama'
		}
		else {
			xi2= J(qs,1,1)#I(k) , qval'#I(k) , I(qs) # (gama)
			betaq=J(1,0,.)
		}

 		omg=(eu2*pxx , euv*pxx  , euw#px \  ///
             euv*pxx , ev2*pxx  , evw#px \   ///
	        (euw#px)', (evw#px)', ew2*us2)
 	    omg=omg/(nobs^2)

		for(i=1;i<=qs;i++) {
			betaq=betaq,(beta+gama*qval[i])'
		}
 		if (dfadj!="") {
			nn=nobs-(k-diag0cnt(qxx))
		}
		else {
			nn=nobs
		}
		vcvq = xi2*omg*xi2'*nobs/nn

		st_matrix("__bq",betaq)
		st_matrix("__vq",makesymmetric(vcvq) )
		st_matrix("__bqq",(beta', gama',qval))
		st_matrix("__vqq",makesymmetric(omg))
		st_numscalar("df_r", nn)
}


void mmqreg_vce2(string scalar yvar_, string scalar xvar_,
			  string scalar u_   , string scalar u_hat_,
			  string scalar beta_,  string scalar gama_,
			  string scalar qval_,  string scalar qth_,
			  string scalar fden_, real scalar df_a,
			  string scalar touse,  string scalar dfadj ,
			  string scalar wgt_ , real scalar nls) {
		real matrix xvar, yvar, wgt
		real vector beta, gama , betaq
		real vector qval, qth, fden
		real matrix u_hat, u, v, w,  euv, euw , evw, ew2
		real matrix px, pxx , qxx, iqxx, xi, xi2, omg
		real scalar us1, us2, nn, nobs , i, qs, k, eu2, ev2
		real matrix vcvq

		st_view(yvar=. ,.,yvar_ ,touse)
		xvar=st_data(.,xvar_,touse),J(rows(yvar),1,1)
 		st_view(u=.    ,.,u_    ,touse)
		st_view(u_hat=.,.,u_hat_,touse)
		u_hat=abs(u_hat)

		wgt = st_data(.,wgt_  ,touse)
		wgt=wgt:/mean(wgt)

		beta=st_matrix(beta_)'
		gama=st_matrix(gama_)'
		nobs=rows(xvar)
		k=cols(xvar)
		qval=st_matrix(qval_)
		qth =st_matrix(qth_)
		fden=st_matrix(fden_)

		qs=cols(qth)
		v=2*u:*((u:>=0):-mean(u:>=0,wgt)):-1

		qxx = quadcross(xvar,wgt,xvar)
		iqxx = invsym(qxx)

 		if1 = nobs*(xvar:*u_hat)*iqxx
		if2 = nobs*(xvar:*u_hat)*iqxx
		ifw = u_hat

		us1 = mean(u_hat,wgt)
		us2 = quadcross(u_hat,wgt,u_hat)
		eu2=mean(u:^2,wgt)
		ev2=mean(v:^2,wgt)
		euv=mean(u:*v,wgt)

 		pxx   = quadcross(if1,wgt,if1)
		px    = quadcross(if1,wgt,ifw)

		w=J(nobs,qs,0)

		for(i=1;i<=qs;i++) {
			w[.,i]= 1/fden[i]*(qth[i]:-((u:-qval[i]):<=0)):/us1 - u:/us1 :-  qval[i]*v:/us1
		}

		euw=mean(u:*w,wgt)
		evw=mean(v:*w,wgt)
		ew2=cross(w,wgt,w)/nobs

		if (nls==0) {
			xi2=( I(k)    , J(k,k+qs,0)      )  \
			( J(k,k,0), I(k) , J(k,qs,0) )  \
			J(qs,1,1)#I(k) , qval'#I(k) , I(qs) # (gama)
			betaq=beta', gama'
		}
		else {
			xi2= J(qs,1,1)#I(k) , qval'#I(k) , I(qs) # (gama)
			betaq=J(1,0,.)
		}

 		omg=(eu2*pxx , euv*pxx  , euw#px \  ///
             euv*pxx , ev2*pxx  , evw#px \   ///
	        (euw#px)', (evw#px)', ew2*us2)
 	    omg=omg/(nobs^2)

		for(i=1;i<=qs;i++) {
			betaq=betaq,(beta+gama*qval[i])'
		}

		if (dfadj!="") {
			nn=(nobs-(k-diag0cnt(qxx)+df_a-1))
		}
		else {
			nn=nobs
		}

		vcvq = xi2*omg*xi2'*nobs/nn
		st_matrix("__bq",betaq)
		st_matrix("__vq",makesymmetric(vcvq) )
		st_numscalar("df_r", nn)

		st_matrix("__bqq",(beta', gama',qval))
		st_matrix("__vqq",makesymmetric(omg))
}


void mmqreg_vce2x(string scalar yvar_, string scalar xvar_,
			  string scalar u_   , string scalar u_hat_,
			  string scalar beta_,  string scalar gama_,
			  string scalar qval_,  string scalar qth_,
			  string scalar fden_, string scalar cvar_,
			  real scalar df_a,  string scalar touse,
			  string scalar dfadj ,  string scalar wgt_,
			  real scalar vce, real scalar nls) {
		real matrix xvar, yvar,wgt
		real vector beta, gama , betaq
		real vector qval, qth, fden
		real matrix u_hat, u, v, w
		real matrix qxx, iqxx, xi, xi2, omg
		real scalar us1, nn,nobs, i, qs, k
		real matrix vcvq
		real matrix omgx

		st_view(yvar =.,.,yvar_ ,touse)
		xvar =st_data(.,xvar_ ,touse),J(rows(yvar),1,1)
		st_view(cvar =.,.,cvar_ ,touse)
 		st_view(u    =.,.,u_  ,touse)
		st_view(u_hat=.,.,u_hat_  ,touse)

		if (vce==2) {
			st_view(cvar =.,.,cvar_ ,touse)
			real matrix info
			real scalar nc
			info = panelsetup(cvar, 1)
			nc   = rows(info)
		}

		u_hat=abs(u_hat)
		wgt = st_data(.,wgt_  ,touse)
		wgt=wgt:/mean(wgt)

		beta=st_matrix(beta_)'
		gama=st_matrix(gama_)'
		nobs=rows(xvar)
		k=cols(xvar)
		qval=st_matrix(qval_)
		qth =st_matrix(qth_)
		fden=st_matrix(fden_)

		qs=cols(qth)
		u    =u:*u_hat
		v=2*u:*((u:>=0):-mean(u:>=0,wgt)):-u_hat

		qxx=quadcross(xvar,wgt,xvar)
	   iqxx=invsym(qxx)

		us1=mean(u_hat,wgt)
		if1 = nobs*(xvar:*u)*iqxx
		if2 = nobs*(xvar:*v)*iqxx

		w=J(nobs,qs,0)

		for(i=1;i<=qs;i++) {
			w[.,i]=1/fden[i]*(qth[i]:-((u:-qval[i]*u_hat):<=0)):*u_hat:/us1 - u:/us1 :-  qval[i]*v:/us1
		}

		if (nls==0) {
			xi2=( I(k)    , J(k,k+qs,0)      )  \
			( J(k,k,0), I(k) , J(k,qs,0) )  \
			J(qs,1,1)#I(k) , qval'#I(k) , I(qs) # (gama)
			betaq=beta', gama'
		}
		else {
			xi2= J(qs,1,1)#I(k) , qval'#I(k) , I(qs) # (gama)
			betaq=J(1,0,.)
		}

		real matrix xvar_uhat, omg_x
		omg_x     =(if1,if2,w):*wgt

		if (vce==1) {
			omg       =quadcross(omg_x,omg_x)/(nobs^2)
		}
		if (vce==2) {
 			omg_xx 	=panelsum(omg_x,info)
 			omg     =quadcross(omg_xx,omg_xx)/(nobs^2)
			real scalar ncone
			ncone=0
		}


		for(i=1;i<=qs;i++) {
			betaq=betaq,(beta+gama*qval[i])'
		}

		if (dfadj!="") {
			nn=nobs-(k-diag0cnt(qxx))
			ncone=1
		}
		else {
			nn=nobs
			if (vce==2) nn=nobs-1
		}

		if (vce==1) vcvq = xi2*omg*xi2'*(nobs/nn)
		if (vce==2) vcvq = xi2*omg*xi2'*(nobs-1)/nn*(nc/(nc-ncone))

		st_matrix("__bq",betaq)
		st_matrix("__vq",makesymmetric(vcvq) )
		st_numscalar("df_r", nn)
		st_matrix("__bqq",(beta', gama',qval))
		st_matrix("__vqq",makesymmetric(omg))

}

end
