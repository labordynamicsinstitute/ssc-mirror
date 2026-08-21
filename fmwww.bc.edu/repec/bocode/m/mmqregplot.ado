*! mmqregplot v2.2  August 2026
*! Shipped with mmqreg v2.6 (SSC).
*! Authors: Fernando Rios-Avila (original mmqreg, friosa@gmail.com)
*!          Dr Merwan Roudane (mmqregplot companion, merwanroudane920@gmail.com)
*! Description: Beautiful coefficient plots for mmqreg
*!   v2.2: quantile paths are now read from the estimates in memory, so the
*!         plotted coefficients reproduce the mmqreg coefficient table exactly
*!         (this fixes the mismatch reported after mmqreg ..., jknife, where
*!         the internal re-estimation silently dropped the jackknife
*!         correction); re-estimation now happens only when the user asks for
*!         a different grid with quantile() or forces it with the new refit
*!         option, and in that case jknife is carried over; a single-panel
*!         figure is no longer dropped from memory (keepgraphs is no longer
*!         needed to keep one graph); returns r(bplot) with the plotted
*!         coefficients and confidence limits; name() and nodraw are now
*!         honoured for single-panel figures too (they used to be forwarded
*!         to graph combine only, so name() was silently ignored whenever a
*!         single variable was plotted); viridis RGB colours are quoted, so
*!         the scheme no longer falls back to Stata's defaults.
*!   v2.1: single-call multi-quantile design (replaces fragile per-quantile loop
*!         that produced r(503) conformability errors); new options showall,
*!         saving(prefix), gformat(), keepgraphs, nocombine; named graphs
*!         (mmqp1..., mmqloc, mmqsca, mmqfe, mmqcombined); fixes for
*!         location/scale name(...,replace) and feplot histogram normopts();
*!         absorb() rebuilt from e(fevlist) for FE-consistent paths; explicit
*!         "version 13" statement.
*!   v2.0: eqplot() for location/scale/all equations,
*!         colorscheme() presets, feplot for country/unit FE visualization
*!   v1.0: quantile coefficient paths with CI bands

/*===========================================================================
  mmqregplot - Visualization suite for mmqreg

  Syntax:
    mmqregplot [varlist] [, options]

  Core options:
    eqplot(qtile|location|scale|all)  which equation(s) to plot
    colorscheme(navy|viridis|autumn|warm|mono|teal)
    quantile(numlist)   re-estimate the path on this grid (default: plot the
                        quantiles that mmqreg actually estimated)
    refit               re-estimate on the default 10(5)90 grid
    ols olsopt(str)     OLS overlay
    feplot              fixed effects / country effects panel
    festyle(bar|hist|dot)   style for feplot (default bar)
    cons                include constant
    label               use variable labels
    mtitles(str)        explicit panel titles
    level(int 95)       CI level
    nozero              suppress y=0 reference line
    raopt/lnopt/twopt/grcopt   passthru twoway options
===========================================================================*/

program define mmqregplot, rclass
	version 13

	syntax [varlist(fv default=none)] , ///
		[EQplot(string)           /// qtile(def)|location|scale|all
		 Quantile(string asis)    /// quantile grid for qtile plots
		 COLORScheme(string)      /// navy(def)|viridis|autumn|warm|mono|teal
		 OLS                      /// overlay OLS on qtile plots
		 OLSOpt(string asis)      /// options for regress (OLS)
		 RAopt(string asis)       /// rarea options
		 LNopt(string asis)       /// line options
		 GRCopt(string asis)      /// graph combine options
		 TWOpt(string asis)       /// twoway options
		 MTitles(string asis)     /// quoted panel titles
		 label                    /// use variable labels
		 labelopt(string asis)    /// passed to short_local equivalent
		 cons                     /// include constant
		 level(integer 95)        /// CI level
		 FEplot                   /// show FE/country-effects panel
		 FEStyle(string)          /// bar(def)|hist|dot
		 NOZero                   /// suppress y=0 reference line
		 SAVing(string)           /// path prefix: saves each panel + combined as .gph
		 GFormat(string asis)     /// extra image formats: e.g. "png pdf"
		 KEEPgraphs               /// keep individual panels in memory after combine
		 SHOWall                  /// draw each panel directly (no nodraw); skip combine
		 NOCombine                /// skip the graph combine step
		 REFit                    /// force re-estimation on a finer grid
		 NAME(string asis)        /// name for the FINAL figure
		 NODRAW                   /// do not display the final figure
		 *]

	** ---- Validate ----
	if "`e(cmd)'"!="mmqreg" {
		display in red "mmqregplot must be run after mmqreg."
		display as text "Example: {stata mmqreg y x1 x2, q(10 25 50 75 90)}"
		error 301
	}

	** ---- Defaults ----
	if "`eqplot'"==""    local eqplot "qtile"
	if "`colorscheme'"=="" local colorscheme "navy"
	if "`festyle'"==""   local festyle "bar"

	** showall: each panel drawn directly, then combined at the end (combined = last graph).
	** Individuals are kept in memory so user can browse via Graph manager.
	if "`showall'"!="" {
		local keepgraphs "keepgraphs"
		local ndraw      ""
	}
	else local ndraw "nodraw"

	** ---- Final figure name (v2.2) ----
	** name() used to fall through to graph combine via the catch-all, so it
	** was ignored whenever the figure ended up with a single panel. It is now
	** parsed here and applied to whatever the final figure turns out to be.
	local gname
	local grepl
	if `"`name'"'!="" {
		local nm0 = subinstr(`"`name'"',","," ",1)
		gettoken gname nmrest: nm0
		if strpos(lower("`nmrest'"),"replace") local grepl "replace"
	}

	** ---- Save original estimates ----
	tempname lastreg
	capture: est store `lastreg'

	** ---- Set color palette ----
	mmqreg_colors, scheme(`colorscheme')
	local ci_color   "`r(ci_color)'"
	local ln_color   "`r(ln_color)'"
	local dot_color  "`r(dot_color)'"
	local ols_color  "`r(ols_color)'"
	local fe_pos     "`r(fe_pos)'"
	local fe_neg     "`r(fe_neg)'"
	local loc_color  "`r(loc_color)'"
	local sca_color  "`r(sca_color)'"

	** ---- Apply user overrides to defaults ----
	if `"`raopt'"'=="" local raopt `"color("`ci_color'") lwidth(none)"'
	if `"`lnopt'"'=="" local lnopt `"lcolor("`ln_color'") lwidth(medthick)"'
	if `"`twopt'"'=="" {
		local twopt "graphregion(color(white)) plotregion(margin(small)) bgcolor(white)"
	}

	** ---- Parse original command ----
	local cmdline `e(cmdline)'
	gettoken cmd rest: cmdline
	qui: mmqreg_stripper `rest'
	local yvar    `r(yvar)'
	local xvar    `r(xvar)'
	local oth     `r(oth)'
	local ifin    `r(ifin)'
	local wgt     `r(wgt)'
	local fevlist `e(fevlist)'

	** strip quantile() from oth
	local oth2
	foreach word of local oth {
		if !regexm("`word'","^(q|qu|qua|quan|quant|quanti|quantil|quantile)[(]") {
			local oth2 "`oth2' `word'"
		}
	}
	** v2.2: jknife is NO LONGER stripped. If the path has to be re-estimated
	** it must carry the same bias correction as the model in memory, otherwise
	** the plotted coefficients differ from the reported ones.
	local jkflag 0
	foreach word of local oth2 {
		if regexm("`word'","^(jk|jkn|jkni|jknif|jknife)$") local jkflag 1
	}

	** ---- Variable list for plotting ----
	ms_fvstrip `xvar', expand dropomit
	local xlist `r(varlist)'

	if "`varlist'"!="" {
		ms_fvstrip `varlist', expand dropomit
		local vlist `r(varlist)'
		local vlist2
		foreach v of local vlist {
			local found=0
			foreach x of local xlist {
				if "`v'"=="`x'" local found=1
			}
			if `found' local vlist2 `vlist2' `v'
			else display in red "Warning: `v' not in original model - skipped"
		}
		local vlist `vlist2'
	}
	else local vlist `xlist'

	if "`cons'"!="" local vlist `vlist' _cons

	** ---- Quantile list and estimation mode (v2.2) ----
	** Quantiles actually estimated by mmqreg, recovered from the equation
	** names of e(b) (qtile_10, qtile_25, ..., or plain qtile if only one).
	local qest
	local ceq0: coleq e(b)
	foreach e0 of local ceq0 {
		if substr("`e0'",1,6)=="qtile_" {
			local qv = subinstr(substr("`e0'",7,.),"_",".",.)
			local dup 0
			foreach q0 of local qest {
				if "`q0'"=="`qv'" local dup 1
			}
			if !`dup' local qest `qest' `qv'
		}
	}
	local nqest: word count `qest'

	** Default = plot what mmqreg estimated, so the figure matches the table.
	** Re-estimate only on explicit request, or when a path cannot be drawn
	** from a single estimated quantile.
	local usestored 0
	if "`quantile'"=="" & "`refit'"=="" & `nqest'>=2 local usestored 1

	if `usestored' {
		local qlist `qest'
	}
	else if "`quantile'"!="" {
		mmqreg_mynlist "`quantile'"
		local qlist `r(numlist)'
	}
	else {
		mmqreg_mynlist "10(5)90"
		local qlist `r(numlist)'
	}

	** ============================================================
	** Dispatch by eqplot
	** ============================================================
	local grcmb_all   // accumulate named graphs for final combine
	tempname qq bs ll ul bso llo ulo

	** ---- QTILE: quantile path plots ----
	if inlist("`eqplot'","qtile","all") {

		** Strip nols from oth2 (we add nols ourselves below; mmqreg rejects duplicates)
		local oth4
		foreach word of local oth2 {
			if "`word'"!="nols" & "`word'"!="NOls" & "`word'"!="NOLS" & "`word'"!="NOLs" {
				local oth4 "`oth4' `word'"
			}
		}
		local oth2 `oth4'

		** Rebuild absorb() from e(fevlist) so the path matches the user's model
		local fespec
		if "`fevlist'"!="" local fespec absorb(`fevlist')

		** ----- Coefficients to plot -----
		** v2.2: read the estimates in memory FIRST (before the OLS overlay
		** regression overwrites e()), so the plotted numbers are literally
		** the ones mmqreg reported, jknife correction included.
		tempname bigB bigV
		if `usestored' {
			matrix `bigB' = e(b)
			matrix `bigV' = e(V)
		}

		** OLS reference (single regress)
		if "`ols'"!="" {
			tempname olsaux
			qui: regress `yvar' `xvar' `ifin' `wgt', `olsopt'
			matrix `olsaux'=r(table)
			qui: est restore `lastreg'
		}

		if `usestored' {
			display as text _n "Plotting the stored mmqreg estimates at " ///
				as result "`nqest'" as text " quantile(s): " as result "`qlist'"
			if `jkflag' display as text ///
				"  (jackknife-corrected coefficients, exactly as reported by mmqreg)"
		}
		else {
			** ----- Single multi-quantile mmqreg call (v2.4 supports q(numlist)) -----
			local nqplot: word count `qlist'
			display as text _n "Re-estimating quantile paths over `nqplot' quantiles..."
			if `jkflag' display as text ///
				"  (jknife carried over from the model in memory; this needs 3 estimations)"
			qui: mmqreg `yvar' `xvar' `ifin' `wgt', q(`qlist') `fespec' `oth2' nols
			matrix `bigB' = e(b)
			matrix `bigV' = e(V)
			if `nqest'>1 {
				display as text "  note: this grid differs from the model in memory (estimated: `qest')."
				display as text "        Coefficients coincide at the shared quantiles; omit"
				display as text "        quantile()/refit to plot exactly the reported table."
			}
			qui: est restore `lastreg'
		}
		local cnms: colnames `bigB'
		local ceqs: coleq    `bigB'
		local K     = colsof(`bigB')
		local z     = invnormal((1+`level'/100)/2)

		** Build qq vector (Nq x 1)
		local nq: word count `qlist'
		matrix `qq' = J(`nq', 1, 0)
		local i = 0
		foreach q of local qlist {
			local i = `i' + 1
			matrix `qq'[`i', 1] = `q'
		}

		** ----- Build per-variable plot data -----
		local gcnt: word count `vlist'
		local cnt  = 0
		local nmtitle: word count `mtitles'
		tempname aux plotm
		local plotnms

		foreach v of local vlist {
			local cnt = `cnt' + 1

			** Per-variable matrix: Nq rows x 4 cols (q, b, ll, ul)
			matrix `aux' = J(`nq', 4, .)
			local i = 0
			local missing_any = 0
			foreach q of local qlist {
				local i = `i' + 1
				local strq = subinstr("`q'",".","_",.)
				if `nq'==1 local target_eq "qtile"
				else       local target_eq "qtile_`strq'"

				** Locate column whose (coleq, colname) matches (target_eq, v)
				local col = 0
				forvalues k = 1/`K' {
					local thiseq:  word `k' of `ceqs'
					local thisnm:  word `k' of `cnms'
					if "`thiseq'"=="`target_eq'" & "`thisnm'"=="`v'" & `col'==0 {
						local col = `k'
					}
				}
				if `col'==0 {
					local missing_any = 1
					continue
				}
				local bv  = `bigB'[1, `col']
				local sev = sqrt(max(0, `bigV'[`col', `col']))
				matrix `aux'[`i', 1] = `q'
				matrix `aux'[`i', 2] = `bv'
				matrix `aux'[`i', 3] = `bv' - `z' * `sev'
				matrix `aux'[`i', 4] = `bv' + `z' * `sev'
			}

			if `missing_any' {
				display in red "mmqregplot: some quantiles for `v' not found in e(b) - partial plot"
			}

			** accumulate the plotted numbers so they can be checked against
			** the coefficient table: r(bplot)
			if `cnt'==1 {
				matrix `plotm' = `aux'
				local plotnms "quantile `v'_b `v'_ll `v'_ul"
			}
			else {
				matrix `plotm' = `plotm', `aux'[1...,2..4]
				local plotnms "`plotnms' `v'_b `v'_ll `v'_ul"
			}

			svmat double `aux', names(__mmqp_)

			** OLS overlay (constant across quantiles)
			local olsci
			if "`ols'"!="" {
				local olscols: colnames `olsaux'
				local ovcol = 0
				local ci = 0
				foreach c of local olscols {
					local ci = `ci' + 1
					if "`c'"=="`v'" & `ovcol'==0 local ovcol `ci'
				}
				if `ovcol'>0 {
					local olsb  = `olsaux'[1, `ovcol']
					local olsll = `olsaux'[5, `ovcol']
					local olsul = `olsaux'[6, `ovcol']
					qui: gen double __mmqo_1 = `olsb'  in 1/`nq'
					qui: gen double __mmqo_2 = `olsll' in 1/`nq'
					qui: gen double __mmqo_3 = `olsul' in 1/`nq'
					local olsci (line __mmqo_1 __mmqp_1, lpattern(solid) lcolor("`ols_color'") lwidth(medthick)) ///
								(line __mmqo_2 __mmqp_1, lpattern(dash) lcolor("`ols_color'%60") lwidth(thin)) ///
								(line __mmqo_3 __mmqp_1, lpattern(dash) lcolor("`ols_color'%60") lwidth(thin))
				}
			}

			** Label
			if `cnt' <= `nmtitle' {
				local vlabx: word `cnt' of `mtitles'
			}
			else {
				if "`label'"!="" {
					capture: local vlabx: variable label `v'
					if "`vlabx'"=="" local vlabx "`v'"
				}
				else local vlabx "`v'"
				if "`v'"=="_cons" local vlabx "Constant"
			}

			** Zero ref
			if "`nozero'"=="" local yzero "yline(0, lcolor(gs11) lpattern(dash) lwidth(thin))"
			else              local yzero

			** Sequential graph name
			local pnm "mmqp`cnt'"

			twoway ///
				(rarea __mmqp_3 __mmqp_4 __mmqp_1, `raopt') ///
				(line __mmqp_2 __mmqp_1, `lnopt') ///
				`olsci' , ///
				`yzero' ///
				xtitle("Quantile", size(small)) ytitle("") ///
				xlabel(10(10)90, grid glcolor(gs15)) ///
				title(`"`vlabx'"', size(small) color(navy) margin(b=1)) ///
				legend(off) `ndraw' name(`pnm', replace) ///
				`twopt'

			local grcmb_all `grcmb_all' `pnm'
			qui: drop __mmqp_*
			capture: drop __mmqo_*
		}

		** Return
		capture: matrix colnames `plotm' = `plotnms'
		capture: return matrix bplot = `plotm'
		return local quantiles "`qlist'"
		return scalar usestored = `usestored'
		return matrix qq = `qq'
	}

	** ---- LOCATION: horizontal coefplot ----
	if inlist("`eqplot'","location","all") {

		qui: est restore `lastreg'   // need bls/vls from original estimation
		capture: confirm matrix e(bls)
		if _rc {
			display in red "Location/scale matrices not available. Re-run mmqreg without nols."
		}
		else {
			capture graph drop mmqloc
			mmqreg_coefgraph, eq(location)              ///
				level(`level') colorscheme(`colorscheme') ///
				twopt(`twopt') `label' `nozero'           ///
				title("Location equation: `yvar'")        ///
				name(mmqloc) `ndraw'
			local grcmb_all `grcmb_all' mmqloc
		}
	}

	** ---- SCALE: horizontal coefplot ----
	if inlist("`eqplot'","scale","all") {

		qui: est restore `lastreg'
		capture: confirm matrix e(bls)
		if _rc {
			display in red "Scale matrices not available. Re-run mmqreg without nols."
		}
		else {
			capture graph drop mmqsca
			mmqreg_coefgraph, eq(scale)                  ///
				level(`level') colorscheme(`colorscheme') ///
				twopt(`twopt') `label' `nozero'           ///
				title("Scale equation: `yvar'")           ///
				name(mmqsca) `ndraw'
			local grcmb_all `grcmb_all' mmqsca
		}
	}

	** ---- FEPLOT: fixed effects / country effects ----
	if "`feplot'"!="" {
		if "`fevlist'"=="" {
			display in red "feplot: no absorbed fixed effects found. Use absorb() in mmqreg."
		}
		else {
			local fe_var: word 1 of `fevlist'
			capture graph drop mmqfe
			mmqreg_feplot, yvar(`yvar') xvar(`xvar') fevar(`fe_var')  ///
				ifin(`ifin') wgt(`wgt')                                 ///
				festyle(`festyle') colorscheme(`colorscheme')           ///
				twopt(`twopt') `label'                                   ///
				name(mmqfe) `ndraw'
			local grcmb_all `grcmb_all' mmqfe
		}
	}

	** ---- Final combine ----
	local npanels: word count `grcmb_all'

	** ----- Save each individual panel (if requested) -----
	if "`saving'"!="" & `npanels' > 0 {
		foreach pnm of local grcmb_all {
			capture qui: graph save `pnm' "`saving'_`pnm'.gph", replace
			if "`gformat'"!="" {
				foreach fmt of local gformat {
					capture qui: graph export "`saving'_`pnm'.`fmt'", name(`pnm') replace
				}
			}
		}
		display as text "Saved `npanels' panel file(s) with prefix: " as result "`saving'_*"
	}

	if `npanels' == 0 {
		display in red "No plots were generated."
	}
	else if "`nocombine'"!="" {
		** Skip combine - show each panel individually
		foreach pnm of local grcmb_all {
			graph display `pnm'
		}
		display as text "Displayed `npanels' panel(s) individually: " as result "`grcmb_all'"
		display as text "  use {stata graph display NAME} to bring one to front (e.g. {stata graph display mmqp1})"
	}
	else if `npanels' == 1 {
		** Single panel - re-draw without the nodraw overlay.
		** v2.2: a lone panel IS the final figure, so it is always kept, and
		** name()/nodraw apply to it. keepgraphs only governs the individual
		** panels of a combined figure.
		local singpanel: word 1 of `grcmb_all'
		if "`gname'"!="" {
			capture: graph rename `singpanel' `gname', `grepl'
			if !_rc local singpanel `gname'
			else display in red ///
				"name(`gname') not applied: a graph of that name already exists (add , replace)"
		}
		if "`nodraw'"=="" graph display `singpanel'
		display as text "Graph kept in memory as: " as result "`singpanel'"
	}
	else {
		** Build clean title
		if "`eqplot'"=="all" {
			local grc_title "MM-QR Results - `yvar'"
		}
		else if "`eqplot'"=="qtile" {
			local grc_title "Quantile Coefficient Paths - `yvar'"
		}
		else {
			local grc_title "MM-QR `eqplot' Equation - `yvar'"
		}

		local combname mmqcombined
		if "`gname'"!="" local combname `gname'
		capture graph drop `combname'
		graph combine `grcmb_all',                              ///
			name(`combname', replace)                           ///
			title("`grc_title'", size(medsmall) color(navy))    ///
			graphregion(color(white)) imargin(tiny)             ///
			`nodraw' `grcopt' `options'

		** Save combined (if requested)
		if "`saving'"!="" {
			capture qui: graph save `combname' "`saving'.gph", replace
			if "`gformat'"!="" {
				foreach fmt of local gformat {
					capture qui: graph export "`saving'.`fmt'", name(`combname') replace
				}
			}
			display as text "Saved combined figure: " as result "`saving'.gph"
		}

		if "`keepgraphs'"=="" {
			capture: graph drop `grcmb_all'
		}
		else {
			display as text "Individual panels kept in memory: " as result "`grcmb_all'"
			display as text "  use {stata graph display NAME} to view, e.g. {stata graph display mmqp1}"
		}
	}

	** Restore
	qui: est restore `lastreg'

end


** =========================================================
** mmqreg_coefgraph - Horizontal coefplot for location/scale
** Uses e(bls) and e(vls) from current estimates
** =========================================================
program define mmqreg_coefgraph
	syntax , EQ(string) level(integer) colorscheme(string) ///
		[title(string asis) name(string) nodraw twopt(string) label nozero]

	** Get stored matrices
	tempname bls vls
	matrix `bls' = e(bls)
	matrix `vls' = e(vls)

	local nq  = colsof(e(qth))      // number of quantiles
	local K2  = colsof(`bls') - `nq'
	local K   = `K2' / 2            // vars including constant

	** Extract by equation
	local ceq: coleq `bls'
	local cnm: colnames `bls'

	** Find columns for requested equation
	local eq_cols
	local col_names
	local kk = 0
	forvalues i = 1/`=colsof(`bls')' {
		local ei: word `i' of `ceq'
		local ni: word `i' of `cnm'
		if "`ei'"=="`eq'" {
			local kk = `kk' + 1
			local eq_cols `eq_cols' `i'
			local col_names `col_names' `ni'
		}
	}

	if `kk'==0 {
		display in red "No columns found for equation '`eq'' in e(bls)"
		exit
	}

	** Colors
	mmqreg_colors, scheme(`colorscheme')
	if "`eq'"=="location" local pcolor "`r(loc_color)'"
	else                  local pcolor "`r(sca_color)'"
	local cicolor "`r(ci_color)'"

	** Critical value
	local z = invnormal((1 + `level'/100) / 2)

	** Build plot data: pos, b, ll, ul
	local plotrows = `kk'
	tempname pdata
	matrix `pdata' = J(`plotrows', 4, 0)   // pos | b | ll | ul

	local cnt = 0
	local ylabcmd
	foreach i of local eq_cols {
		local cnt = `cnt' + 1
		local bi  = `bls'[1, `i']
		local vii = `vls'[`i', `i']
		local sei = sqrt(max(0, `vii'))
		matrix `pdata'[`cnt', 1] = `cnt'
		matrix `pdata'[`cnt', 2] = `bi'
		matrix `pdata'[`cnt', 3] = `bi' - `z' * `sei'
		matrix `pdata'[`cnt', 4] = `bi' + `z' * `sei'

		** Variable label
		local ni: word `cnt' of `col_names'
		if "`label'"!="" {
			capture: local vlab: variable label `ni'
			if "`vlab'"=="" local vlab "`ni'"
		}
		else local vlab "`ni'"
		if "`ni'"=="_cons" local vlab "Constant"
		local ylabcmd `ylabcmd' `cnt' `"`vlab'"'
	}

	** svmat
	svmat double `pdata', names(__mmqc_)

	** zero line
	if "`nozero'"=="" local xzero "xline(0, lcolor(gs11) lpattern(dash) lwidth(thin))"
	else              local xzero

	** graph
	local gname
	if "`name'"!="" local gname name(`name', replace)
	if "`nodraw'"!="" local ndraw nodraw

	twoway ///
		(rspike __mmqc_3 __mmqc_4 __mmqc_1, horizontal ///
			lcolor("`pcolor'%50") lwidth(thick)) ///
		|| (scatter __mmqc_1 __mmqc_2, ///
			msymbol(circle) mcolor("`pcolor'") msize(medlarge)) , ///
		`xzero' ///
		ylabel(`ylabcmd', angle(0) nogrid labsize(small)) ///
		ytitle("") xtitle("Coefficient (`level'% CI)", size(small)) ///
		title(`"`title'"', size(small) color(navy) margin(b=1)) ///
		legend(off) `gname' `ndraw' ///
		graphregion(color(white)) plotregion(margin(small)) bgcolor(white) ///
		`twopt'

	qui: drop __mmqc_*
end


** =========================================================
** mmqreg_feplot - Fixed effects / country effects visualization
** Requires: areg available; single absorb variable
** =========================================================
program define mmqreg_feplot
	syntax , yvar(string) xvar(string) fevar(string) ///
		[ifin(string) wgt(string) festyle(string)     ///
		 colorscheme(string) twopt(string) label       ///
		 name(string) nodraw]

	if "`festyle'"==""    local festyle "bar"
	if "`colorscheme'"=="" local colorscheme "navy"

	mmqreg_colors, scheme(`colorscheme')
	local fe_pos "`r(fe_pos)'"
	local fe_neg "`r(fe_neg)'"

	** Get FE label
	if "`label'"!="" {
		capture: local felab: variable label `fevar'
		if "`felab'"=="" local felab "`fevar'"
	}
	else local felab "`fevar'"

	** Estimate FE via areg
	display as text _n "Computing fixed effects for `fevar'..."
	capture: qui areg `yvar' `xvar' if e(sample) `wgt', absorb(`fevar')
	if _rc {
		display in red "feplot: areg failed. Check that `fevar' is a valid absorb variable."
		exit
	}
	qui: predict double __fe_hat__, d    // d = deviation (FE estimate)

	** Collapse to unit level
	qui: bysort `fevar': egen __fe_mean__ = mean(__fe_hat__)
	qui: bysort `fevar':      gen __fe_id__   = _n==1

	tempname fedata
	tempvar fe_val fe_unit
	qui: gen double `fe_val'  = __fe_mean__ if __fe_id__==1
	qui: gen        `fe_unit' = `fevar'     if __fe_id__==1

	qui: count if __fe_id__==1
	local N_fe = r(N)

	** Sort ascending
	sort `fe_val'
	qui: gen __fe_pos__ = _n if __fe_id__==1

	** graph
	local gname
	if "`name'"!="" local gname name(`name', replace)
	if "`nodraw'"!="" local ndraw nodraw

	if "`festyle'"=="bar" {
		** Horizontal bar chart sorted by FE, colored pos/neg
		qui: gen __fe_color__ = (__fe_mean__ >= 0) if __fe_id__==1

		if `N_fe' <= 60 {
			** Show individual unit labels
			twoway ///
				(bar __fe_mean__ __fe_pos__ if __fe_color__==0 & __fe_id__==1, ///
					horizontal barw(0.7) color("`fe_neg'%80") lwidth(none)) ///
				|| (bar __fe_mean__ __fe_pos__ if __fe_color__==1 & __fe_id__==1, ///
					horizontal barw(0.7) color("`fe_pos'%80") lwidth(none)) , ///
				xline(0, lcolor(gs10) lpattern(dash)) ///
				ytitle("`felab'", size(small)) xtitle("Fixed effect", size(small)) ///
				title("Country/Unit Effects: `felab'", size(small) color(navy)) ///
				legend(off) `gname' `ndraw' ///
				graphregion(color(white)) plotregion(margin(small)) bgcolor(white) ///
				`twopt'
		}
		else {
			** Too many units - use histogram
			histogram __fe_mean__ if __fe_id__==1, ///
				kdensity frequency ///
				color("`fe_pos'%50") lcolor("`fe_pos'") ///
				kdenopts(lcolor("`fe_neg'") lwidth(medthick)) ///
				xtitle("Fixed Effect (unit mean deviation)", size(small)) ///
				ytitle("Frequency", size(small)) ///
				title("Distribution of `felab' Effects (N=`N_fe' units)", ///
					size(small) color(navy)) ///
				xline(0, lcolor(gs10) lpattern(dash)) ///
				graphregion(color(white)) plotregion(margin(small)) ///
				`gname' `ndraw' `twopt'
		}
	}

	else if "`festyle'"=="hist" {
		** Histogram with KDE overlay
		histogram __fe_mean__ if __fe_id__==1, ///
			kdensity frequency ///
			color("`fe_pos'%40") lcolor("`fe_pos'") ///
			kdenopts(lcolor("`fe_neg'") lwidth(medthick)) ///
			xtitle("Fixed Effect (unit mean deviation)", size(small)) ///
			ytitle("Frequency", size(small)) ///
			title("Distribution of `felab' Effects (N=`N_fe' units)", ///
				size(small) color(navy)) ///
			xline(0, lcolor(gs10) lpattern(dash)) ///
			normal normopts(lcolor(gs10) lpattern(longdash)) ///
			graphregion(color(white)) plotregion(margin(small)) ///
			`gname' `ndraw' `twopt'
	}

	else if "`festyle'"=="dot" {
		** Cleveland dot plot (sorted scatter)
		twoway ///
			(scatter __fe_pos__ __fe_mean__ if __fe_id__==1 & __fe_mean__<0, ///
				msymbol(circle) mcolor("`fe_neg'%80") msize(small)) ///
			|| (scatter __fe_pos__ __fe_mean__ if __fe_id__==1 & __fe_mean__>=0, ///
				msymbol(circle) mcolor("`fe_pos'%80") msize(small)) ///
			|| (dropline __fe_pos__ __fe_mean__ if __fe_id__==1, ///
				lcolor(gs12) lwidth(vthin) msymbol(none) horizontal) , ///
			xline(0, lcolor(gs10) lpattern(dash)) ///
			ylabel(none) ///
			ytitle("`felab' units", size(small)) xtitle("Fixed effect", size(small)) ///
			title("Country/Unit Effects: `felab' (N=`N_fe')", size(small) color(navy)) ///
			legend(off) `gname' `ndraw' ///
			graphregion(color(white)) plotregion(margin(small)) bgcolor(white) ///
			`twopt'
	}

	** Clean up
	qui: drop __fe_hat__ __fe_mean__ __fe_id__ __fe_pos__
	capture drop __fe_color__
end


** =========================================================
** mmqreg_colors - Color palette factory
** =========================================================
program define mmqreg_colors, rclass
	syntax, scheme(string)

	if "`scheme'"=="navy" {
		return local ci_color  "navy%25"
		return local ln_color  "navy"
		return local dot_color "navy"
		return local ols_color "cranberry"
		return local fe_pos    "navy"
		return local fe_neg    "cranberry"
		return local loc_color "navy"
		return local sca_color "midblue"
	}
	else if "`scheme'"=="viridis" {
		return local ci_color  "54 90 141%30"
		return local ln_color  "54 90 141"
		return local dot_color "54 90 141"
		return local ols_color "253 231 37"
		return local fe_pos    "33 145 140"
		return local fe_neg    "253 231 37"
		return local loc_color "54 90 141"
		return local sca_color "33 145 140"
	}
	else if "`scheme'"=="autumn" {
		return local ci_color  "maroon%25"
		return local ln_color  "maroon"
		return local dot_color "maroon"
		return local ols_color "dkorange"
		return local fe_pos    "maroon"
		return local fe_neg    "dkorange"
		return local loc_color "maroon"
		return local sca_color "dkorange"
	}
	else if "`scheme'"=="warm" {
		return local ci_color  "orange_red%25"
		return local ln_color  "orange_red"
		return local dot_color "dkorange"
		return local ols_color "navy"
		return local fe_pos    "orange_red"
		return local fe_neg    "navy"
		return local loc_color "orange_red"
		return local sca_color "orange"
	}
	else if "`scheme'"=="mono" {
		return local ci_color  "gs8%35"
		return local ln_color  "gs4"
		return local dot_color "black"
		return local ols_color "gs6"
		return local fe_pos    "gs4"
		return local fe_neg    "gs10"
		return local loc_color "gs4"
		return local sca_color "gs8"
	}
	else if "`scheme'"=="teal" {
		return local ci_color  "teal%25"
		return local ln_color  "teal"
		return local dot_color "teal"
		return local ols_color "orange"
		return local fe_pos    "teal"
		return local fe_neg    "orange"
		return local loc_color "teal"
		return local sca_color "orange"
	}
	else {
		** unknown -> fallback to navy
		return local ci_color  "navy%25"
		return local ln_color  "navy"
		return local dot_color "navy"
		return local ols_color "cranberry"
		return local fe_pos    "navy"
		return local fe_neg    "cranberry"
		return local loc_color "navy"
		return local sca_color "midblue"
	}
end


** =========================================================
** mmqreg_mynlist - numlist parser
** =========================================================
program define mmqreg_mynlist, rclass
	syntax anything,
	numlist `anything', range(>0 <100) sort
	local j = scalar(_pi)
	foreach i in `r(numlist)' {
		if `i' != `j' {
			local numlist `numlist' `i'
		}
		local j = `i'
	}
	return local numlist `numlist'
end


** =========================================================
** mmqreg_stripper - parse original command line
** =========================================================
program define mmqreg_stripper, rclass
	syntax anything [if] [in] [aw iw pw fw], ///
		[Quantile(string)] [ABSorb(varlist)] [cluster(varname)] [* ]
	gettoken yvar xvar: anything
	local oth  `options'
	local ifin `if' `in'
	if "`weight'`exp'"!="" local wgt [`weight'`exp']
	return local xvar `xvar'
	return local yvar `yvar'
	return local oth  `oth'
	return local ifin `ifin'
	return local wgt  `wgt'
end
