*! xtbchpanel 2.0.0  12jul2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! github.com/merwanroudane
*! xtbchpanel: bias-corrected mean-group long-run estimators for dynamic
*!             heterogeneous panels (ARDL(p,q)), general-purpose.
*! Per-unit ARDL:  y(i,t) = a(i) + S phi(i,l) y(i,t-l) + S beta_k(i,l) x_k(i,t-l) + u
*!   long-run:     theta_k(i) = [S_l beta_k(i,l)] / [1 - S_l phi(i,l)]  for each regressor k
*! Estimators (rows): MG (Pesaran-Smith 1995), HPJ-MG (Chudik-Pesaran 2015),
*!   BC1 analytical (Kiviet-Phillips 1993 COLS), BC2 bootstrap (Pesaran-Zhao 1999
*!   via Autoregressive Wild Bootstrap, Smeekes-Urbain 2014), BC3 short-run
*!   jackknife, TMG (Trimmed Mean Group, Pesaran-Yang 2024), and pooled HPJ-FE
*!   (Chudik-Pesaran-Yang 2018, Prop.4 variance).
*! Options reproduce Centorrino et al. (2026) / Kahn et al. (2021) climate models:
*!   difference (growth), mavars()+ma() = (2/(m+1))|x-MA_m| deviation, cce world term.
*! Step->equation map: see  help xtbchpanel methods.

program define xtbchpanel, eclass sortpreserve
	version 15.1
	if replay() {
		if (`"`e(cmd)'"' != "xtbchpanel") error 301
		xtbch_display, level(`=cond("`e(level)'"=="", c(level), `e(level)')')
		exit
	}
	Estimate `0'
end


* =======================================================================
* ESTIMATION DRIVER
* =======================================================================
program define Estimate, eclass sortpreserve
	syntax varlist(numeric ts min=2) [if] [in] [,	///
		LAGs(numlist integer min=2 max=2 >=0)			///
		MAvars(varlist numeric)						///
		MA(numlist integer >0 sort)					///
		DIFFerence								///
		CCE									///
		WORLD(varname numeric)						///
		Methods(string)							///
		BY(varname)								///
		ALPHAtrim(real 0.3333333)					///
		REPS(integer 199)							///
		SEED(integer 12345)							///
		RHO(real 0.10)							///
		Level(cilevel)							///
		GRAPH GNAME(string) PLOTVar(varname numeric) PLOTMA(integer 0)	///
		NODOTS ]

	gettoken depvar indepvars : varlist
	local kx : word count `indepvars'

	* ---- ARDL lag orders p q ----------------------------------------------
	if "`lags'" == "" local lags "1 4"
	gettoken p q : lags
	local q : word 2 of `lags'
	local q1 = `q' + 1

	* ---- climate-deviation windows (optional) -----------------------------
	local hasma = ("`ma'" != "")
	if `hasma' == 0 local ma "."
	local nM : word count `ma'
	* which regressors get the deviation transform
	if "`mavars'" == "" & `hasma' local mavars "`indepvars'"

	* ---- methods ----------------------------------------------------------
	local methods = lower(strtrim("`methods'"))
	if "`methods'" == "" | "`methods'" == "all" ///
		local methods "mg hpjmg bc1 bc2 bc3 tmg hpjfe"
	local known "mg hpjmg bc1 bc2 bc3 tmg hpjfe"
	foreach m of local methods {
		local ok : list m in known
		if !`ok' {
			di as err "method '`m'' not recognized; valid: `known' (or all)"
			exit 198
		}
	}
	local doMG    : list posof "mg"    in methods
	local doHPJMG : list posof "hpjmg" in methods
	local doBC1   : list posof "bc1"   in methods
	local doBC2   : list posof "bc2"   in methods
	local doBC3   : list posof "bc3"   in methods
	local doTMG   : list posof "tmg"   in methods
	local doHPJFE : list posof "hpjfe" in methods

	* ---- panel / time -----------------------------------------------------
	qui xtset
	local ivar "`r(panelvar)'"
	local tvar "`r(timevar)'"
	if "`ivar'" == "" | "`tvar'" == "" {
		di as err "data not xtset; use {bf:xtset panelvar timevar} first"
		exit 459
	}

	marksample touse, novarlist
	markout `touse' `depvar' `indepvars'

	* ---- plotting defaults ------------------------------------------------
	if "`plotvar'" == "" local plotvar : word 1 of `indepvars'
	local plotk : list posof "`plotvar'" in indepvars
	if `plotk' == 0 local plotk 1
	if `plotma' == 0 {
		if `hasma' {
			local mid = ceil(`nM'/2)
			local plotma : word `mid' of `ma'
		}
		else local plotma "."
	}

	* =======================================================================
	* Dependent variable (optionally differenced) and its p lags; CCE term
	* =======================================================================
	tempvar dm
	if "`difference'" != "" qui gen double `dm' = D.`depvar' if `touse'
	else                    qui gen double `dm' = `depvar'   if `touse'

	local Lylist ""
	forvalues j = 1/`p' {
		tempvar Ly`j'
		qui gen double `Ly`j'' = L`j'.`dm' if `touse'
		local Lylist "`Lylist' `Ly`j''"
	}

	local ccevar ""
	if "`cce'" != "" | "`world'" != "" {
		tempvar cceraw
		if "`world'" != "" qui gen double `cceraw' = `world' if `touse'
		else qui bysort `tvar': egen double `cceraw' = mean(`dm') if `touse'
		sort `ivar' `tvar'
		tempvar ccev
		qui gen double `ccev' = L.`cceraw' if `touse'
		local ccevar "`ccev'"
	}
	local hascce = ("`ccevar'" != "")

	* ---- group handling ----------------------------------------------------
	local bylabs ""
	if "`by'" != "" {
		tempvar grp
		qui egen `grp' = group(`by') if `touse'
		qui levelsof `grp' if `touse', local(glevels)
		local nG : word count `glevels'
		qui levelsof `by' if `touse', local(bylabs)
	}
	else {
		local glevels "0"
		local nG 1
	}

	* ---- result containers (rows: group x method ; cols: regressor x window)
	local nmeth 6
	tempname RESB RESSE HFEB HFEPHI NG
	matrix `RESB'   = J(`nG'*`nmeth', `kx'*`nM', .)
	matrix `RESSE'  = J(`nG'*`nmeth', `kx'*`nM', .)
	matrix `HFEB'   = J(`nG', `kx'*`nM', .)
	tempname HFESE
	matrix `HFESE'  = J(`nG', `kx'*`nM', .)
	matrix `HFEPHI' = J(`nG', `nM', .)
	matrix `NG'     = J(`nG', `nM', .)

	tempname THETAI
	mata: xtbch_TI = J(0, 5, .)

	if "`nodots'" != "" local pdots 0
	else local pdots 1
	set seed `seed'
	sort `ivar' `tvar'

	* =======================================================================
	* Loop windows x groups ; build regressors ; call the Mata engine
	* =======================================================================
	local mi 0
	foreach m of local ma {
		local ++mi

		* --- build the q+1 lags of each (transformed) regressor ------------
		local betalist ""
		foreach x of local indepvars {
			local ismav : list posof "`x'" in mavars
			tempvar base
			if `hasma' & `ismav' {
				tempvar sm
				qui gen double `sm' = 0 if `touse'
				forvalues j = 1/`m' {
					qui replace `sm' = `sm' + L`j'.`x' if `touse'
				}
				qui gen double `base' = (2/(`m'+1))*abs(`x' - `sm'/`m') if `touse'
			}
			else qui gen double `base' = `x' if `touse'

			tempvar xk
			if "`difference'" != "" qui gen double `xk' = D.`base' if `touse'
			else                    qui gen double `xk' = `base'   if `touse'

			forvalues l = 0/`q' {
				tempvar b`x'`l'
				qui gen double `b`x'`l'' = L`l'.`xk' if `touse'
				local betalist "`betalist' `b`x'`l''"
			}
		}

		local design "`Lylist' `betalist' `ccevar'"

		local gi 0
		foreach g of local glevels {
			local ++gi
			tempvar use2
			qui gen byte `use2' = `touse'
			qui markout `use2' `dm' `design'
			if "`by'" != "" qui replace `use2' = 0 if `grp' != `g'

			local wantTheta = (`hasma'==0 | "`m'"=="`plotma'")

			tempname colB colSE hfeB hfeSE
			matrix `colB'  = J(`nmeth', `kx', .)
			matrix `colSE' = J(`nmeth', `kx', .)
			matrix `hfeB'  = J(1, `kx', .)
			matrix `hfeSE' = J(1, `kx', .)
			scalar _hfephi = .
			scalar _nvalid = .

			mata: xtbch_engine( 						///
				"`dm'", "`design'", "`ivar'", "`use2'",		///
				`p', `kx', `q1', `hascce',				///
				`doMG', `doHPJMG', `doBC1', `doBC2', `doBC3', `doTMG',	///
				`doHPJFE', `reps', `rho', `alphatrim',			///
				`wantTheta', `g', `plotk',				///
				"`colB'", "`colSE'", "`hfeB'", "`hfeSE'" )

			* place into the stacked containers
			local r0 = (`gi'-1)*`nmeth'
			forvalues rr = 1/`nmeth' {
				forvalues k = 1/`kx' {
					local cc = (`k'-1)*`nM' + `mi'
					matrix `RESB'[`r0'+`rr', `cc']  = `colB'[`rr',`k']
					matrix `RESSE'[`r0'+`rr', `cc'] = `colSE'[`rr',`k']
				}
			}
			forvalues k = 1/`kx' {
				local cc = (`k'-1)*`nM' + `mi'
				matrix `HFEB'[`gi', `cc']  = `hfeB'[1,`k']
				matrix `HFESE'[`gi', `cc'] = `hfeSE'[1,`k']
			}
			matrix `HFEPHI'[`gi', `mi'] = _hfephi
			matrix `NG'[`gi', `mi']     = _nvalid
		}
	}

	mata: xtbch_finish("`THETAI'")
	capture mata: mata drop xtbch_TI

	* =======================================================================
	* Column / row names and post
	* =======================================================================
	local cn ""
	foreach x of local indepvars {
		foreach m of local ma {
			if `hasma' local cn "`cn' `x'_ma`m'"
			else       local cn "`cn' `x'"
		}
	}
	matrix colnames `RESB'  = `cn'
	matrix colnames `RESSE' = `cn'
	matrix colnames `HFEB'  = `cn'
	matrix colnames `HFESE' = `cn'

	tempname b V
	if `hasma' {
		local wpos : list posof "`plotma'" in ma
		if `wpos' == 0 local wpos 1
	}
	else local wpos 1
	local pcol = (`plotk'-1)*`nM' + `wpos'
	local prow = cond(`doTMG', 6, 1)
	local pest = `RESB'[`prow', `pcol']
	local pse  = `RESSE'[`prow', `pcol']
	if `pest' == . {
		local pest = `RESB'[1, `pcol']
		local pse  = `RESSE'[1, `pcol']
	}
	if `pest' == . {
		local pest 0
		local pse  .
	}
	matrix `b' = `pest'
	matrix `V' = cond(`pse'==. | `pse'<=0, 0, `pse'^2)
	matrix colnames `b' = "`plotvar'"
	matrix colnames `V' = "`plotvar'"
	matrix rownames `V' = "`plotvar'"

	ereturn post `b' `V', depname(`depvar') esample(`touse')
	ereturn scalar level   = `level'
	ereturn scalar reps    = `reps'
	ereturn scalar p       = `p'
	ereturn scalar q       = `q'
	ereturn scalar kx      = `kx'
	ereturn scalar nma     = `nM'
	ereturn scalar hasma   = `hasma'
	ereturn scalar ngroups = `nG'
	ereturn scalar alphatrim = `alphatrim'
	ereturn local  difference "`difference'"
	ereturn local  plotvar "`plotvar'"
	ereturn local  ma      "`ma'"
	ereturn local  lrvars  "`indepvars'"
	ereturn local  mavars  "`mavars'"
	ereturn local  methods "`methods'"
	ereturn local  byvar   "`by'"
	ereturn local  depvar  "`depvar'"
	ereturn local  ivar    "`ivar'"
	ereturn local  tvar    "`tvar'"
	ereturn local  cmd     "xtbchpanel"
	ereturn local  title   "Bias-corrected heterogeneous dynamic panel (long-run effects)"
	ereturn matrix b_all   = `RESB'
	ereturn matrix se_all  = `RESSE'
	ereturn matrix hpjfe_b   = `HFEB'
	ereturn matrix hpjfe_se  = `HFESE'
	ereturn matrix hpjfe_phi = `HFEPHI'
	ereturn matrix N_g     = `NG'
	capture ereturn matrix theta_i = `THETAI'
	if "`by'" != "" ereturn local bylabels "`bylabs'"

	xtbch_display, level(`level')

	if "`graph'" != "" | "`gname'" != "" {
		capture noisily xtbch_graph, gname(`gname') level(`level') plotvar(`plotvar')
		if _rc di as err "  (graphs skipped, rc=" _rc ")"
	}
end


* =======================================================================
* DISPLAY
* =======================================================================
program define xtbch_display
	syntax [, Level(cilevel) ]

	tempname B SE HB HSE HPHI NG
	matrix `B'    = e(b_all)
	matrix `SE'   = e(se_all)
	matrix `HB'   = e(hpjfe_b)
	matrix `HSE'  = e(hpjfe_se)
	matrix `HPHI' = e(hpjfe_phi)
	matrix `NG'   = e(N_g)

	local ma      "`e(ma)'"
	local nM      = e(nma)
	local hasma   = e(hasma)
	local nG      = e(ngroups)
	local kx      = e(kx)
	local lrvars  "`e(lrvars)'"
	local z       = invnormal(1 - (100 - `level')/200)
	local byvar   "`e(byvar)'"
	local methods "`e(methods)'"
	local nmeth 6

	local mrows   "mg hpjmg bc1 bc2 bc3 tmg"
	local mpretty `""Mean Group (MG)" "HPJ Mean Group" "MG-BC1 (analytic)" "MG-BC2 (bootstrap)" "MG-BC3 (jackknife)" "Trimmed MG (TMG)""'
	if "`byvar'" != "" local bylabs "`e(bylabels)'"

	di _n in smcl in gr "{hline 79}"
	di in gr "{bf:Bias-corrected heterogeneous dynamic panel}" _col(69) in ye "xtbchpanel"
	di in gr "{it:Long-run mean-group effects, theta_k = (sum_l beta_kl)/(1 - sum_l phi_l)}"
	di in smcl in gr "{hline 79}"
	di in gr "Dependent: " in ye abbrev("`e(depvar)'",16) ///
		cond("`e(difference)'"!="", " (differenced)", "") ///
		_col(46) in gr "Panel: " in ye abbrev("`e(ivar)'",14)
	di in gr "ARDL (p,q): " in ye "(`e(p)',`e(q)')" ///
		_col(46) in gr "Regressors: " in ye `kx' in gr "  Groups: " in ye `nG'
	if `hasma' di in gr "Climate deviation on {bf:`e(mavars)'} via MA windows: " in ye "`ma'"

	* layout:  hasma -> windows as columns (one table per regressor)
	*          else   -> regressors as columns (one table per group)
	forvalues gg = 1/`nG' {
		local gname "All units"
		if "`byvar'" != "" {
			local gl : word `gg' of `bylabs'
			local gname "`byvar' = `gl'"
		}
		local nn = `NG'[`gg',1]
		local r0 = (`gg'-1)*`nmeth'

		if `hasma' {
			local k 0
			foreach v of local lrvars {
				local ++k
				di _n in gr "{bf:`gname'} {c |} " in ye "`v'" in gr "  (N=" in ye %4.0f `nn' in gr ")"
				di in smcl in gr "{hline 20}{c TT}{hline `=`nM'*13'}"
				local hdr in gr %19s "Estimator" " {c |}"
				local jj 0
				foreach m of local ma {
					local ++jj
					local hdr `"`hdr' in gr _col(`=21+(`jj'-1)*13') "MA `m'""'
				}
				di `hdr'
				di in smcl in gr "{hline 20}{c +}{hline `=`nM'*13'}"
				local ri 0
				foreach mm of local mrows {
					local ++ri
					local want : list posof "`mm'" in methods
					if !`want' continue
					local lbl : word `ri' of `mpretty'
					local line in gr %19s "`lbl'" " {c |}"
					local jj 0
					foreach m of local ma {
						local ++jj
						local col = (`k'-1)*`nM' + `jj'
						local bb = `B'[`=`r0'+`ri'',`col']
						local ss = `SE'[`=`r0'+`ri'',`col']
						local cell "."
						if `bb'!=. {
							local star ""
							if `ss'!=. & `ss'>0 {
								local pp = 2*normal(-abs(`bb'/`ss'))
								if `pp'<.01 local star "***"
								else if `pp'<.05 local star "**"
								else if `pp'<.1 local star "*"
							}
							local cell = strofreal(`bb',"%8.4f") + "`star'"
						}
						local line `"`line' in ye _col(`=21+(`jj'-1)*13') "`cell'""'
					}
					di `line'
					local line in gr _col(20) " {c |}"
					local jj 0
					foreach m of local ma {
						local ++jj
						local col = (`k'-1)*`nM' + `jj'
						local ss = `SE'[`=`r0'+`ri'',`col']
						local cell ""
						if `ss'!=. & `ss'>0 local cell = "(" + strofreal(`ss',"%7.4f") + ")"
						local line `"`line' in gr _col(`=21+(`jj'-1)*13') "`cell'""'
					}
					di `line'
				}
				di in smcl in gr "{hline 20}{c BT}{hline `=`nM'*13'}"
			}
			local wantfe : list posof "hpjfe" in methods
			if `wantfe' {
				di in gr "{bf:Pooled HPJ-FE benchmark} (`gname'):"
				local k 0
				foreach v of local lrvars {
					local ++k
					local line in gr %19s "`v'" " {c |}"
					local jj 0
					foreach m of local ma {
						local ++jj
						local col = (`k'-1)*`nM' + `jj'
						local bb = `HB'[`gg',`col']
						local ss = `HSE'[`gg',`col']
						local cell "."
						if `bb'!=. {
							local star ""
							if `ss'!=. & `ss'>0 & 2*normal(-abs(`bb'/`ss'))<.05 local star "*"
							local cell = strofreal(`bb',"%8.4f") + "`star'"
						}
						local line `"`line' in ye _col(`=21+(`jj'-1)*13') "`cell'""'
					}
					di `line'
				}
			}
		}
		else {
			di _n in gr "{bf:`gname'}  (N=" in ye %4.0f `nn' in gr " units)"
			di in smcl in gr "{hline 20}{c TT}{hline `=`kx'*13'}"
			local hdr in gr %19s "Estimator" " {c |}"
			local k 0
			foreach v of local lrvars {
				local ++k
				local hdr `"`hdr' in gr _col(`=21+(`k'-1)*13') "`=abbrev("`v'",11)'""'
			}
			di `hdr'
			di in smcl in gr "{hline 20}{c +}{hline `=`kx'*13'}"
			local ri 0
			foreach mm of local mrows {
				local ++ri
				local want : list posof "`mm'" in methods
				if !`want' continue
				local lbl : word `ri' of `mpretty'
				local line in gr %19s "`lbl'" " {c |}"
				local seln in gr _col(20) " {c |}"
				forvalues k = 1/`kx' {
					local bb = `B'[`=`r0'+`ri'',`k']
					local ss = `SE'[`=`r0'+`ri'',`k']
					local cell "."
					local scell ""
					if `bb'!=. {
						local star ""
						if `ss'!=. & `ss'>0 {
							local pp = 2*normal(-abs(`bb'/`ss'))
							if `pp'<.01 local star "***"
							else if `pp'<.05 local star "**"
							else if `pp'<.1 local star "*"
						}
						local cell = strofreal(`bb',"%8.4f") + "`star'"
						if `ss'!=. & `ss'>0 local scell = "(" + strofreal(`ss',"%7.4f") + ")"
					}
					local line `"`line' in ye _col(`=21+(`k'-1)*13') "`cell'""'
					local seln `"`seln' in gr _col(`=21+(`k'-1)*13') "`scell'""'
				}
				di `line'
				di `seln'
			}
			local wantfe : list posof "hpjfe" in methods
			if `wantfe' {
				local line in gr %19s "Pooled HPJ-FE" " {c |}"
				forvalues k = 1/`kx' {
					local bb = `HB'[`gg',`k']
					local ss = `HSE'[`gg',`k']
					local cell "."
					if `bb'!=. {
						local star ""
						if `ss'!=. & `ss'>0 & 2*normal(-abs(`bb'/`ss'))<.05 local star "*"
						local cell = strofreal(`bb',"%8.4f") + "`star'"
					}
					local line `"`line' in ye _col(`=21+(`k'-1)*13') "`cell'""'
				}
				di `line'
			}
			di in smcl in gr "{hline 20}{c BT}{hline `=`kx'*13'}"
		}
	}

	di in gr "  {it:Significance:} *** p<.01, ** p<.05, * p<.1.  SEs in parentheses."
	di in gr "  Preferred estimator: {bf:Trimmed MG (TMG)} (Pesaran & Yang 2024)."
	di in gr "  Full matrices in {bf:e(b_all)}, {bf:e(se_all)}, {bf:e(hpjfe_b)}."
end


* =======================================================================
* GRAPHS
* =======================================================================
program define xtbch_graph
	syntax [, GNAME(string) Level(cilevel) PLOTVar(string) ]
	if "`gname'" == "" local gname xtbch
	local z = invnormal(1 - (100 - `level')/200)
	local cMG "26 78 126"
	local cHPJ "39 174 96"
	local cTMG "192 57 43"
	local ccap "120 120 120"

	local gsave ""
	if "`c(mode)'" == "batch" {
		local gsave "`c(graphics)'"
		set graphics off
	}
	preserve

	* distribution of per-unit theta_i for the chosen regressor
	capture noisily {
		tempname TI
		matrix `TI' = e(theta_i)
		clear
		qui svmat double `TI', name(th)
		qui count
		if r(N) > 0 {
			qui sort th3
			qui gen long rank = _n
			qui summarize th3, meanonly
			local mgm = r(mean)
			qui summarize th5, meanonly
			local tmgm = r(mean)
			#delimit ;
			twoway
			  (scatter th3 rank, msymbol(oh) msize(small) mcolor("`cMG'%70"))
			  (scatter th4 rank, msymbol(dh) msize(small) mcolor("`cHPJ'%70"))
			  (scatter th5 rank, msymbol(x)  msize(small) mcolor("`cTMG'%85")),
				yline(`mgm', lcolor("`cMG'%60") lpattern(dash))
				yline(`tmgm', lcolor("`cTMG'%70") lpattern(shortdash))
				title("{bf:Distribution of unit-specific long-run effects}",
					size(medium) color(black))
				subtitle("regressor: `plotvar'; dashed = MG mean, short-dash = TMG mean",
					size(vsmall) color(gs6))
				ytitle("Long-run {&theta}{sub:i}", size(small))
				xtitle("Unit (sorted by raw {&theta}{sub:i})", size(small))
				ylabel(, angle(0) labsize(vsmall) format(%4.1f) grid glcolor(gs15))
				legend(order(1 "MG (raw)" 2 "HPJ-corrected" 3 "TMG (trimmed)")
					rows(1) size(vsmall) region(lcolor(gs14)) position(6))
				graphregion(fcolor(white) lcolor(white) margin(medsmall))
				plotregion(fcolor(white) lcolor(gs13))
				name(`gname'_dist, replace) ;
			#delimit cr
			di in gr "  Graph saved: " in ye "`gname'_dist"
		}
	}
	if _rc di in error "  (distribution plot skipped, rc=" _rc ")"

	* forest plot of estimators for the chosen regressor (first window)
	capture noisily {
		tempname B SE
		matrix `B'  = e(b_all)
		matrix `SE' = e(se_all)
		local nM = e(nma)
		local lrvars "`e(lrvars)'"
		local plotk : list posof "`plotvar'" in lrvars
		if `plotk'==0 local plotk 1
		local pcol = (`plotk'-1)*`nM' + 1
		local mrows "mg hpjmg bc1 bc2 bc3 tmg"
		local mpretty `""MG" "HPJ-MG" "BC1" "BC2" "BC3" "TMG""'
		local methods "`e(methods)'"
		clear
		qui set obs 6
		qui gen long ypos = _n
		qui gen double est = .
		qui gen double lo  = .
		qui gen double hi  = .
		local yl ""
		forvalues r = 1/6 {
			local mm : word `r' of `mrows'
			local want : list posof "`mm'" in methods
			local lbl : word `r' of `mpretty'
			local yl `"`yl' `r' "`lbl'""'
			if `want' {
				local bb = `B'[`r', `pcol']
				local ss = `SE'[`r', `pcol']
				qui replace est = `bb' in `r'
				if `ss'!=. & `ss'>0 {
					qui replace lo = `bb'-`z'*`ss' in `r'
					qui replace hi = `bb'+`z'*`ss' in `r'
				}
			}
		}
		#delimit ;
		twoway (rcap lo hi ypos, horizontal lcolor("`ccap'") lwidth(medthin))
		       (scatter ypos est, msymbol(O) msize(medium)
		        mcolor("`cMG'") mlcolor(white) mlwidth(vthin)),
			xline(0, lcolor(gs10) lpattern(dot))
			title("{bf:Long-run effect by estimator}", size(medium) color(black))
			subtitle("regressor: `plotvar'; `level'% CIs", size(vsmall) color(gs6))
			xtitle("Long-run coefficient", size(small)) ytitle("")
			ylabel(`yl', angle(0) labsize(small) nogrid)
			yscale(reverse range(0.5 6.5))
			xlabel(, labsize(vsmall) format(%4.1f) grid glcolor(gs15))
			legend(off)
			graphregion(fcolor(white) lcolor(white) margin(medsmall))
			plotregion(fcolor(white) lcolor(gs13))
			name(`gname'_forest, replace) ;
		#delimit cr
		di in gr "  Graph saved: " in ye "`gname'_forest"
	}
	if _rc di in error "  (forest plot skipped, rc=" _rc ")"

	restore
	if "`gsave'" != "" set graphics `gsave'
end


* =======================================================================
* MATA ENGINE
* =======================================================================
version 15.1
mata:

// ---------- OLS: returns b; fills V and s2 (by reference) ---------------
real colvector xtbch_ols(real matrix Z, real colvector y,
                         real matrix V, real scalar s2)
{
	real matrix  ZZi
	real colvector b, e
	real scalar  T, k
	T = rows(Z)
	k = cols(Z)
	ZZi = invsym(quadcross(Z, Z))
	b   = ZZi * quadcross(Z, y)
	e   = y - Z * b
	if (T - k > 0) {
		s2 = (e' * e) / (T - k)
	} else {
		s2 = (e' * e) / T
	}
	V = s2 * ZZi
	return (b)
}

// ---------- long-run theta vector: theta_k = sum(beta_k)/(1-sum(phi)) ---
real rowvector xtbch_thetavec(real colvector b, real scalar p,
                              real scalar kx, real scalar q1)
{
	real scalar den, k, cs
	real rowvector th
	th = J(1, kx, .)
	den = 1 - sum(b[|1 \ p|])
	if (den == 0) {
		return (th)
	}
	for (k = 1; k <= kx; k++) {
		cs = p + (k - 1) * q1 + 1
		th[k] = sum(b[|cs \ cs + q1 - 1|]) / den
	}
	return (th)
}

// ---------- Pesaran-Smith MG se of a column ----------------------------
real scalar xtbch_mgse(real colvector x)
{
	real scalar n, m
	n = rows(x)
	if (n < 2) {
		return (.)
	}
	m = sum(x) / n
	return (sqrt(sum((x :- m) :^ 2) / (n * (n - 1))))
}

// ---------- Autoregressive Wild Bootstrap multipliers ------------------
real colvector xtbch_awb(real scalar T, real scalar rho)
{
	real colvector z, xi
	real scalar t, sq
	z  = rnormal(T, 1, 0, 1)
	xi = J(T, 1, 0)
	xi[1] = z[1]
	sq = sqrt(1 - rho * rho)
	for (t = 2; t <= T; t++) {
		xi[t] = rho * xi[t - 1] + sq * z[t]
	}
	return (xi)
}

// ---------- Kiviet-Phillips (1993) COLS : returns corrected b ----------
real colvector xtbch_kp(real matrix Z, real colvector b, real scalar s2,
                        real scalar T, real scalar p)
{
	real scalar k, lam, t, s, trCtC, trCCtC
	real matrix  Cm, Zbar, Dh, Dinv, ZCZ, CCtC, X, M1
	real colvector F, yD, e1, term, bet, Ba

	k = cols(Z)
	if (p != 1) {
		return (b)                    // KP defined for a single lagged dep var
	}
	lam = b[1]
	if (abs(lam) >= 1) {
		return (b)
	}
	Cm = J(T, T, 0)
	for (s = 1; s <= T - 1; s++) {
		Cm[s + 1, s] = 1
		for (t = s + 2; t <= T; t++) {
			Cm[t, s] = lam * Cm[t - 1, s]
		}
	}
	F = J(T, 1, 0)
	F[1] = 1
	for (t = 2; t <= T; t++) {
		F[t] = lam * F[t - 1]
	}
	X   = Z[|1, 2 \ T, k|]
	bet = b[|2 \ k|]
	yD  = Z[1, 1] * F + Cm * (X * bet)
	Zbar = yD, X
	e1 = J(k, 1, 0)
	e1[1] = 1
	trCtC = trace(Cm' * Cm)
	Dh = quadcross(Zbar, Zbar)
	Dh[1, 1] = Dh[1, 1] + s2 * trCtC
	Dinv = invsym(makesymmetric(Dh))
	ZCZ  = Zbar' * Cm * Zbar
	CCtC = Cm * Cm' * Cm
	trCCtC = trace(CCtC)
	M1 = ZCZ * Dinv
	term = M1 * e1 + trace(M1) * e1 + 2 * s2 * Dinv[1, 1] * trCCtC * e1
	Ba = -s2 * Dinv * term
	return (b - Ba)
}

// ---------- pooled HPJ-FE : fills theta[1xkx], se[1xkx], phi -----------
void xtbch_hpjfe(real colvector y, real matrix X, real colvector lo,
	real colvector hi, real scalar N, real scalar p, real scalar kx,
	real scalar q1, real rowvector theta, real rowvector se, real scalar phi)
{
	real scalar i, Ti, mid, k, Nobs, s2, sphi, den, kk, cs
	real matrix Xd, Xda, Xdb, dstar, Q, R, Vb, Qi2, Xi, qf
	real colvector yd, yda, ydb, bhat, ba, bb, btil, u, cm, cma, cmb, yi, grad
	real scalar ma_y, mb_y, r0

	k = cols(X)
	Nobs = rows(y)
	Xd  = J(Nobs, k, 0); yd  = J(Nobs, 1, 0)
	Xda = J(Nobs, k, 0); yda = J(Nobs, 1, 0)
	Xdb = J(Nobs, k, 0); ydb = J(Nobs, 1, 0)
	dstar = J(Nobs, k, 0)
	for (i = 1; i <= N; i++) {
		Ti = hi[i] - lo[i] + 1
		if (Ti < k + 2) {
			continue
		}
		yi = y[|lo[i] \ hi[i]|]
		Xi = X[|lo[i], . \ hi[i], .|]
		cm = (colsum(Xi) :/ Ti)'
		mid = floor(Ti / 2)
		yd[|lo[i] \ hi[i]|]       = yi :- mean(yi)
		Xd[|lo[i], . \ hi[i], .|] = Xi :- (J(Ti, 1, 1) * cm')
		cma = (colsum(Xi[|1, . \ mid, .|]) :/ mid)'
		cmb = (colsum(Xi[|mid + 1, . \ Ti, .|]) :/ (Ti - mid))'
		ma_y = mean(yi[|1 \ mid|]); mb_y = mean(yi[|mid + 1 \ Ti|])
		r0 = lo[i]
		yda[|r0 \ r0 + mid - 1|]       = yi[|1 \ mid|] :- ma_y
		Xda[|r0, . \ r0 + mid - 1, .|] = Xi[|1, . \ mid, .|] :- (J(mid, 1, 1) * cma')
		ydb[|r0 + mid \ hi[i]|]       = yi[|mid + 1 \ Ti|] :- mb_y
		Xdb[|r0 + mid, . \ hi[i], .|] = Xi[|mid + 1, . \ Ti, .|] :- (J(Ti - mid, 1, 1) * cmb')
		dstar[|r0, . \ r0 + mid - 1, .|] = ///
			Xi[|1, . \ mid, .|] :- (J(mid, 1, 1) * (2 * cm - cma)')
		dstar[|r0 + mid, . \ hi[i], .|] = ///
			Xi[|mid + 1, . \ Ti, .|] :- (J(Ti - mid, 1, 1) * (2 * cm - cmb)')
	}
	s2 = 0; Q = J(k, k, 0)
	bhat = xtbch_ols(Xd, yd, Q, s2)
	real matrix Va, Vb2
	real scalar sa, sb
	Va = J(k, k, 0); Vb2 = J(k, k, 0); sa = 0; sb = 0
	ba = xtbch_ols(Xda, yda, Va, sa)
	bb = xtbch_ols(Xdb, ydb, Vb2, sb)
	btil = 2 * bhat - 0.5 * (ba + bb)
	Q = quadcross(Xd, Xd) :/ Nobs
	u = yd - Xd * btil
	R = J(k, k, 0)
	for (i = 1; i <= Nobs; i++) {
		R = R + (dstar[i, .]' * dstar[i, .]) * (u[i] * u[i])
	}
	R = R :/ Nobs
	Qi2 = invsym(Q)
	Vb = (Qi2 * R * Qi2) :/ Nobs
	sphi = sum(btil[|1 \ p|])
	phi = sphi
	den = 1 - sphi
	theta = J(1, kx, .)
	se    = J(1, kx, .)
	if (den == 0) {
		return
	}
	for (kk = 1; kk <= kx; kk++) {
		cs = p + (kk - 1) * q1 + 1
		theta[kk] = sum(btil[|cs \ cs + q1 - 1|]) / den
		grad = J(k, 1, 0)
		for (i = 1; i <= p; i++) {
			grad[i] = theta[kk] / den
		}
		for (i = cs; i <= cs + q1 - 1; i++) {
			grad[i] = 1 / den
		}
		qf = grad' * Vb * grad
		se[kk] = sqrt(qf[1, 1])
	}
}

// =======================================================================
// MAIN ENGINE : one window x one group
// =======================================================================
void xtbch_engine(
	string scalar dmv, string scalar designv, string scalar idv,
	string scalar tousev,
	real scalar p, real scalar kx, real scalar q1, real scalar hascce,
	real scalar doMG, real scalar doHPJMG, real scalar doBC1,
	real scalar doBC2, real scalar doBC3, real scalar doTMG,
	real scalar doHPJFE, real scalar reps, real scalar rho, real scalar alphatrim,
	real scalar wantTheta, real scalar gid, real scalar plotk,
	string scalar colB, string scalar colSE, string scalar hfeB, string scalar hfeSE)
{
	real colvector y, id, uid, lo, hi, DET, valid
	real matrix    X, Xnc, THI, THHPJ, THBC1, THBC3, THBC2, THTMG, B2C
	real scalar    N, k, Nobs, i, Ti, mid, nv, kk, cs
	external real matrix xtbch_TI

	y   = st_data(., dmv, tousev)
	Xnc = st_data(., designv, tousev)
	id  = st_data(., idv, tousev)
	Nobs = rows(y)
	uid = uniqrows(id)
	N   = rows(uid)
	lo = J(N, 1, 0); hi = J(N, 1, 0)
	for (i = 1; i <= N; i++) {
		real colvector cc
		cc = selectindex(id :== uid[i])
		lo[i] = cc[1]; hi[i] = cc[rows(cc)]
	}
	X = Xnc, J(Nobs, 1, 1)
	k = cols(X)

	THI   = J(N, kx, .); THHPJ = J(N, kx, .); THBC1 = J(N, kx, .)
	THBC3 = J(N, kx, .); THBC2 = J(N, kx, .); THTMG = J(N, kx, .)
	DET   = J(N, 1, .)
	B2C   = J(N, k, .)
	real colvector Tvec
	Tvec = J(N, 1, .)

	real matrix Vi
	real scalar s2i

	for (i = 1; i <= N; i++) {
		Ti = hi[i] - lo[i] + 1
		Tvec[i] = Ti
		if (Ti < k + 2) {
			continue
		}
		real matrix  Zi
		real colvector yi, b_i
		yi = y[|lo[i] \ hi[i]|]
		Zi = X[|lo[i], . \ hi[i], .|]
		Vi = J(k, k, 0); s2i = 0
		b_i = xtbch_ols(Zi, yi, Vi, s2i)
		THI[i, .] = xtbch_thetavec(b_i, p, kx, q1)
		DET[i] = det(quadcross(Zi, Zi))

		mid = floor(Ti / 2)
		if (mid >= k + 1 & (Ti - mid) >= k + 1) {
			real matrix Z1, Z2, V1, V2
			real colvector y1, y2, b1, b2, bshort
			real scalar s1, s2b
			y1 = yi[|1 \ mid|]; y2 = yi[|mid + 1 \ Ti|]
			Z1 = Zi[|1, . \ mid, .|]; Z2 = Zi[|mid + 1, . \ Ti, .|]
			V1 = J(k, k, 0); V2 = J(k, k, 0); s1 = 0; s2b = 0
			b1 = xtbch_ols(Z1, y1, V1, s1)
			b2 = xtbch_ols(Z2, y2, V2, s2b)
			THHPJ[i, .] = 2 * THI[i, .] - 0.5 * ///
				(xtbch_thetavec(b1, p, kx, q1) + xtbch_thetavec(b2, p, kx, q1))
			bshort = 2 * b_i - 0.5 * (b1 + b2)
			THBC3[i, .] = xtbch_thetavec(bshort, p, kx, q1)
		} else {
			THHPJ[i, .] = THI[i, .]
			THBC3[i, .] = THI[i, .]
		}

		if (doBC1) {
			real colvector bkp
			bkp = xtbch_kp(Zi, b_i, s2i, Ti, p)
			THBC1[i, .] = xtbch_thetavec(bkp, p, kx, q1)
		}

		if (doBC2) {
			real matrix bstar, Zstar
			real colvector e_i, fixedpart, estar, xi, ystar, bbstar, bmean, b2c
			real scalar rr, t, j, lagval, yhat, nvb, phistar
			real matrix Vs
			real scalar ss
			bstar = J(k, reps, .); nvb = 0
			e_i = yi - Zi * b_i; e_i = e_i :- mean(e_i)
			fixedpart = J(Ti, 1, 0)
			for (t = 1; t <= Ti; t++) {
				fixedpart[t] = Zi[t, (p + 1)..k] * b_i[(p + 1)..k]
			}
			for (rr = 1; rr <= reps; rr++) {
				xi = xtbch_awb(Ti, rho)
				estar = xi :* e_i
				ystar = J(Ti, 1, 0)
				for (t = 1; t <= Ti; t++) {
					yhat = fixedpart[t] + estar[t]
					for (j = 1; j <= p; j++) {
						if (t - j >= 1) {
							lagval = ystar[t - j]
						} else {
							lagval = Zi[t, j]
						}
						yhat = yhat + b_i[j] * lagval
					}
					ystar[t] = yhat
				}
				Zstar = Zi
				for (t = 1; t <= Ti; t++) {
					for (j = 1; j <= p; j++) {
						if (t - j >= 1) {
							Zstar[t, j] = ystar[t - j]
						}
					}
				}
				Vs = J(k, k, 0); ss = 0
				bbstar = xtbch_ols(Zstar, ystar, Vs, ss)
				phistar = sum(bbstar[|1 \ p|])
				if (abs(phistar) < 0.999) {
					nvb = nvb + 1
					bstar[, nvb] = bbstar
				}
			}
			if (nvb >= 1) {
				bmean = J(k, 1, 0)
				for (j = 1; j <= k; j++) {
					bmean[j] = mean(bstar[|j, 1 \ j, nvb|]')
				}
				b2c = 2 * b_i - bmean
			} else {
				b2c = b_i
			}
			B2C[i, .] = b2c'
			THBC2[i, .] = xtbch_thetavec(b2c, p, kx, q1)
		}
	}

	valid = selectindex(THI[, 1] :!= .)
	nv = rows(valid)

	real matrix R6, S6
	R6 = J(6, kx, .); S6 = J(6, kx, .)

	if (nv >= 2) {
		real colvector vDET
		vDET = DET[valid]
		for (kk = 1; kk <= kx; kk++) {
			if (doMG) {
				R6[1, kk] = mean(THI[valid, kk]); S6[1, kk] = xtbch_mgse(THI[valid, kk])
			}
			if (doHPJMG) {
				R6[2, kk] = mean(THHPJ[valid, kk]); S6[2, kk] = xtbch_mgse(THHPJ[valid, kk])
			}
			if (doBC1) {
				R6[3, kk] = mean(THBC1[valid, kk]); S6[3, kk] = xtbch_mgse(THBC1[valid, kk])
			}
			if (doBC3) {
				R6[5, kk] = mean(THBC3[valid, kk]); S6[5, kk] = xtbch_mgse(THBC3[valid, kk])
			}
		}
		if (doBC2) {
			real colvector bMG
			real scalar sphiB, den2
			real matrix Sig
			real colvector Jac, bb2, qf2
			bMG = (colsum(B2C[valid, .]) :/ nv)'
			sphiB = sum(bMG[|1 \ p|]); den2 = 1 - sphiB
			Sig = J(k, k, 0)
			for (i = 1; i <= nv; i++) {
				bb2 = B2C[valid[i], .]' - bMG
				Sig = Sig + bb2 * bb2'
			}
			Sig = Sig :/ ((nv - 1) * nv)
			if (den2 != 0) {
				for (kk = 1; kk <= kx; kk++) {
					cs = p + (kk - 1) * q1 + 1
					R6[4, kk] = sum(bMG[|cs \ cs + q1 - 1|]) / den2
					Jac = J(k, 1, 0)
					for (j2 = 1; j2 <= p; j2++) {
						Jac[j2] = R6[4, kk] / den2
					}
					for (j2 = cs; j2 <= cs + q1 - 1; j2++) {
						Jac[j2] = 1 / den2
					}
					qf2 = Jac' * Sig * Jac
					S6[4, kk] = sqrt(qf2[1, 1])
				}
			}
		}
		if (doTMG) {
			real scalar Cn, an, dbar, tmgest
			real colvector delta, onepd, thtmg
			Cn = mean(vDET); an = Cn * nv ^ (-alphatrim)
			delta = J(nv, 1, 0); onepd = J(nv, 1, 1)
			for (i = 1; i <= nv; i++) {
				if (vDET[i] <= an) {
					delta[i] = vDET[i] / an - 1
					onepd[i] = vDET[i] / an
				}
			}
			dbar = mean(delta)
			for (kk = 1; kk <= kx; kk++) {
				thtmg = onepd :* THI[valid, kk]
				tmgest = mean(thtmg) / (1 + dbar)
				R6[6, kk] = tmgest
				S6[6, kk] = sqrt(sum((thtmg :- tmgest) :^ 2) / (nv * nv))
				THTMG[valid, kk] = thtmg
			}
		}
	}
	st_matrix(colB, R6)
	st_matrix(colSE, S6)
	st_numscalar("_nvalid", nv)
	st_numscalar("_hfephi", .)

	if (doHPJFE) {
		real rowvector hth, hse
		real scalar hphi
		real matrix Xfe
		hth = J(1, kx, .); hse = J(1, kx, .); hphi = .
		Xfe = Xnc[|1, 1 \ Nobs, p + kx * q1|]
		xtbch_hpjfe(y, Xfe, lo, hi, N, p, kx, q1, hth, hse, hphi)
		st_matrix(hfeB, hth)
		st_matrix(hfeSE, hse)
		st_numscalar("_hfephi", hphi)
	}

	if (wantTheta & nv >= 1) {
		real matrix add
		real scalar r
		add = J(nv, 5, .)
		for (i = 1; i <= nv; i++) {
			r = valid[i]
			add[i, 1] = uid[r]; add[i, 2] = gid
			add[i, 3] = THI[r, plotk]
			add[i, 4] = THHPJ[r, plotk]
			add[i, 5] = THTMG[r, plotk]
		}
		xtbch_TI = xtbch_TI \ add
	}
}

void xtbch_finish(string scalar nm)
{
	external real matrix xtbch_TI
	if (rows(xtbch_TI) > 0) {
		st_matrix(nm, xtbch_TI)
	} else {
		st_matrix(nm, J(1, 5, .))
	}
}

end
