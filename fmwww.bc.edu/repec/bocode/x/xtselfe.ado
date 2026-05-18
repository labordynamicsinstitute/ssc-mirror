*! version 1.0.0 17jan2026

program define xtselfe, eclass
	version 16.1
	syntax varlist(numeric fv) [if] [in], SELect(string) [RHOtype(string)] [NOINTERact] [VCE(string asis)] [First] [NOLOG] [DEBUG]
	
	// cmdline
	local cmdline "`0'"
	
	// mark observations
	marksample touse, novarlist  // to allow missing values especially in depvar
	
	// variables of outcome equation
	fvexpand `varlist' if `touse'
	local fullvarlist `r(varlist)'
	gettoken depvar indepvars : fullvarlist
	if "`indepvars'" == "" {
		di as err "1 or more variables required"
		exit 102
	}
	
	// display option priority (first vs nolog)
	if "`first'" != "" & "`nolog'" != "" {
		di as txt "note. {res}`nolog'{txt} option ignored."
		local nolog ""
	}
	
	* ------------------------------------------------------------------
	* rhotype() option
	* ------------------------------------------------------------------
	
	tempname rhoopt
	if "`rhotype'" == "" {
		scalar `rhoopt' = 1
		local rhoname "stationary"
	}
	else {
		ParseRhotype , `rhotype'
		//sret li
		local rhoname = s(rhotype)
		if "`rhoname'" == "stationary" {
			scalar `rhoopt' = 1
		}
		else if "`rhoname'" == "unrestricted" {
			scalar `rhoopt' = 0
		}
		else if "`rhoname'" == "common" {
			scalar `rhoopt' = 2
		}
	}
	
	* ------------------------------------------------------------------
	* select() option
	* ------------------------------------------------------------------
	
	RephraseForSelectSpec "(m[A-Za-z0-9_]*)\(" "`select'"
	RephraseForSelectSpec "(c[A-Za-z0-9_]*)\(" "`r(text)'"
	ParseSelect `r(text)'
	//sret li
	local devname "`s(devtype)'"
	local selpool "`s(pool)'"
	local devvars "`s(devvars)'"
	local selvarlist "`s(varlist)'"
	
	// change devname to none if m() or c()
	if "`s(hasdevvars)'" == "true" & "`devvars'" == "" {
		local devname "none"
	}
	if "`devname'" == "chamberlain" & "`selpool'" != "" {
		di as err "'chamberlain' device type cannot be used together with 'pool'"
		exit 184
	}
	
	// variables of selection equation
	fvexpand `devvars' if `touse'
	local sel_devvars `r(varlist)'
	fvexpand `selvarlist' if `touse'
	local selvars `r(varlist)'
	gettoken seldep selind : selvars
	local selind = trim("`selind'")
	if "`selind'" == "" {
		di as err "2 or more variables in select() required"
		exit 102
	}
	
	// modify marker
	markout `touse' `indepvars' `seldep' `selind' `sel_devvars'
	
	// panel data validation
	tempname nn tt t_all
	capture qui xtset
	if _rc {
		di as err "panelvar and timevar must be specified"
		exit _rc
	}
	local pid = r(panelvar)
	local tid = r(timevar)
	qui levelsof `pid' if `touse'
	scalar `nn' = r(r)
	qui levelsof `tid' if `touse', local(tlevels)
	scalar `tt' = r(r)
	if `=`tt'' <= 1 {
		di as err "2 or more values for `tid' required"
		exit 451
	}
	qui levelsof `tid'
	scalar `t_all' = r(r)
	local tmin : word 1 of `tlevels'
	local tmax : word `=`tt'' of `tlevels'
	
	// verifying seldep as dummy
	qui levelsof `seldep' if `touse', local(seldepval)
	if "`seldepval'" != "0 1" {
		di as err "`seldep' for `tid' = `j' is not a 0/1 variable"
		exit 450
	}
	foreach j of local tlevels {
		qui levelsof `seldep' if `touse' & `tid' == `j', local(seldepval`j')
		if "`seldepval`j''" == "0" {
			di as err "`seldep' for `tid' = `j' contains 0 only"
			exit 450
		}
		else if "`seldepval`j''" == "1" {
			di as err "`seldep' for `tid' = `j' contains 1 only"
			exit 450
		}
	}
	
	// nointeract option
	tempname hetcorr
	scalar `hetcorr' = 1  // default
	local k_correct = `=`tt''
	if "`nointeract'" != "" {
		scalar `hetcorr' = 0
		local k_correct = 1
	}
	
	* ------------------------------------------------------------------
	* vce() option
	* ------------------------------------------------------------------
	
	tempname epsopt
	scalar `epsopt' = 0.0001  // default
	local vcid "`pid'"
	local vcetype ""
	if "`vce'" == "" {
		local vcecmd "robust"
	}
	else {
		ParseVceOpt `vce'
		*sret li
		* needed later: unadj ("" or "unadjusted"), vcid (panelvar or 'otherid'), epsopt (scalar)
		local unadj "`s(unadjusted)'"
		local vcetype "`s(vcetype)'"
		* 1) don't use cluster without unadjusted
		if "`unadj'" == "" & "`vcetype'" == "cluster" {
			di as err "'`vcetype'' can only be used with 'unadjusted'"
			exit 184
		}
		* 2) don't use unadjusted and delta together
		if "`unadj'" != "" & "`vcetype'" == "delta" {
			di as err "'`vcetype'' and '`unadj'' cannot be used together"
			exit 184
		}
		if "`unadj'" != "" {
			local vcecmd "`unadj' "
		}
		local vcecmd = "`vcecmd'`vcetype'"
		if "`vcetype'" == "delta" {
			scalar `epsopt' = `s(delta)'
			local vcecmd "`vcecmd' `=`epsopt''"
		}
		if "`vcetype'" == "cluster" {
			local vcid = "`s(clustvar)'"
			local vcecmd = "`vcecmd' `vcid'"
		}
	}
	*di "{txt}unadj = ({res}`unadj'{txt}), vcid = ({res}`vcid'{txt}), epsopt = ({res}`=`epsopt''{txt})"
	*di "{txt}vcecmd = ({res}`vcecmd'{txt})"
	
	// chamberlain-mundlak device
	if "`nolog'" == "" {
		di _n "{txt}Additional covariates for {res}`seldep'{txt}: {res}`devname'" _c
		if "`devname'" == "mundlak" {
			di as txt " (individual averages)"
		}
		else if "`devname'" == "chamberlain" {
			di as txt " (full histories)"
		}
		else if "`devname'" == "none" {
			di ""
		}
	}
	local ww0 ""
	local ww1 ""
	local wwname0 ""
	local wwname1 ""
	if "`sel_devvars'" != "" {
		foreach v of local sel_devvars {
			if strpos("`v'", ".") {  // fv in m() or c()
				tempvar fv
				qui gen `fv' = `v'
				local vv "`fv'"
			}
			else {
				local vv "`v'"
			}
			confirm variable `vv'
			qui xtsum `vv' if `touse'
			if r(sd_w) == 0 {  // time-invariant vars in m() or c()
				local ww0 "`ww0' `vv'"
				local wwname0 "`wwname0' `v'"
			}
			else {  // time-varying vars in m() or c()
				local ww1 "`ww1' `vv'"
				local wwname1 "`wwname1' `v'"
			}
		}
	}
	local zz0 ""
	local zz1 ""
	local needdev ""
	local zzname0 ""
	local zzname1 ""
	local needdevname ""
	foreach v of local selind {
		if strpos("`v'", ".") {  // fv in select()
			tempvar fv
			qui gen `fv' = `v'
			local vv "`fv'"
		}
		else {
			local vv "`v'"
		}
		confirm variable `vv'
		if "`devname'" == "none" {
			local zz0 "`zz0' `vv'"
			local zzname0 "`zzname0' `v'"
		}
		else {  // mundlak or chamberlain
			qui xtsum `vv' if `touse'
			if r(sd_w) == 0 {  // time-invariant vars in select()
				local zz0 "`zz0' `vv'"
				local zzname0 "`zzname0' `v'"
			}
			else {  // time-varying vars in select()
				if "`devname'" == "mundlak" {
					local zz0 "`zz0' `vv'"
					local zzname0 "`zzname0' `v'"
				}
				if "`sel_devvars'" == "" {
					local needdev "`needdev' `vv'"
					local needdevname "`needdevname' `v'"
				}
				else {
					if "`devname'" == "chamberlain" {
						tokenize `ww1'
						local novarin = 1
						while "`1'" != "" {
							capture qui assert `vv'==`1' if `touse'
							local novarin = `novarin'*`=_rc'
							macro shift
						}
						if `novarin' != 0 {
							local zz0 "`zz0' `vv'"
							local zzname0 "`zzname0' `v'"
						}
					}
				}
			}
		}
	}
	if "`sel_devvars'" != "" {
		local ii = 1
		foreach vv of local ww0 {
			tokenize `zz0'
			local novarin = 1
			while "`1'" != "" {
				capture qui assert `vv'==`1' if `touse'
				local novarin = `novarin'*`=_rc'
				macro shift
			}
			if `novarin' != 0 {
				local add : word `ii' of `wwname0'
				local zz0 "`zz0' `vv'"
				local zzname0 "`zzname0' `add'"
			}
			local ii = `ii'+1
		}
		local ii = 1
		foreach vv of local ww1 {
			local add : word `ii' of `wwname1'
			if "`devname'" == "mundlak" {
				tokenize `zz0'
				local novarin = 1
				while "`1'" != "" {
					capture qui assert `vv'==`1' if `touse'
					local novarin = `novarin'*`=_rc'
					macro shift
				}
				if `novarin' != 0 {
					local zz0 "`zz0' `vv'"
					local zzname0 "`zzname0' `add'"
				}
			}
			local needdev "`needdev' `vv'"
			local needdevname "`needdevname' `add'"
			local ii = `ii'+1
		}
	}
	local ii = 1
	foreach vv of local needdev {
		local v : word `ii' of `needdevname'
		if "`devname'" == "mundlak" {
			tempvar device_`vv'
			qui by `pid': egen `device_`vv'' = mean(`vv') if `touse'
			local zz1 "`zz1' `device_`vv''"
			local zzname1 "`zzname1' m_device:`v'"
		}
		else if "`devname'" == "chamberlain" {
			foreach j of local tlevels {
				tempvar device_`vv'_`j'
				qui by `pid': egen `device_`vv'_`j'' = total(`vv'/(`tid' == `j')) if `touse', missing
				local zz1 "`zz1' `device_`vv'_`j''"
				local zzname1 "`zzname1' c_device:`v'[`j']"
			}
		}
		local ii = `ii'+1
	}
	local zz "`zz0' `zz1'"
	local zznames "`zzname0' `zzname1' _cons"
	
	// step 1: probit
	tempvar seltouse zhs
	tempname pihs pihsih
	if "`selpool'" == "" {
		if "`nolog'" == "" & "`first'" == "" {
			di as res "Probit" as txt " regression for each of " as res "`tid'" as txt " =" _c
		}
		if "`first'" != "" {
			di ""
		}
		qui gen `seltouse' = 0
		qui gen `zhs' = .
		local obs = 0
		local ii = 1
		foreach j of local tlevels {
			if "`nolog'" == "" {
				if "`first'" == "" {
					di as txt " " as res "`j'" _c
				}
				else {
					di as txt "Probit regression for `tid' = " as res "`j'"
				}
			}
			capture qui probit `seldep' `zz' if `touse' & `tid' == `j'
			if _rc {
				if "`nolog'" == "" & "`first'" == "" {
					di ""
				}
				if "`debug'" == "" {
					di as err "error occurred in probit regression for `tid' = `j'."
					di as err "Use -debug- option for details."
				}
				else {
					di as err "error occurred in probit regression for `tid' = `j'"
					capture noi probit `seldep' `zz' if `touse' & `tid' == `j'
					di _n as txt "[VARIABLE NAME INFORMATION]"
					mata: s1 = tokens(st_local("zz1"))
					mata: s2 = tokens(st_local("zzname1"))
					//mata: s2 = subinstr(s2, "m_device:", "", .)
					//mata: s2 = subinstr(s2, "c_device:", "", .)
				mata: (s1', s2')
				}
				exit _rc
			}
			qui replace `seltouse' = `seltouse'+e(sample)
			tempvar zh
			qui predict `zh' if e(sample), xb
			qui replace `zhs' = `zh' if e(sample)
			drop `zh'
			if `ii' == 1 {
				mat `pihs' = e(b)
				mat `pihsih' = -e(V)
			}
			else {
				mat `pihs' = `pihs'\e(b)
				mat `pihsih' = `pihsih'\-e(V)
			}
			tempname N_p_`ii' k_p_`ii' b_p_`ii' V_p_`ii'
			scalar `N_p_`ii'' = e(N)
			scalar `k_p_`ii'' = e(k)
			mat `b_p_`ii'' = e(b)
			mat `V_p_`ii'' = e(V)
			mat colnames `b_p_`ii'' = _:
			mat colnames `V_p_`ii'' = _:
			mat rownames `V_p_`ii'' = _:
			mat colnames `b_p_`ii'' = `zznames'
			mat colnames `V_p_`ii'' = `zznames'
			mat rownames `V_p_`ii'' = `zznames'
			if "`first'" != "" {
				tempname btmp vtmp
				mat `btmp' = `b_p_`ii''
				mat `vtmp' = `V_p_`ii''
				ereturn post `btmp' `vtmp', depname(`seldep')
				di _n as txt "Number of obs = " as res strtrim(strofreal(`N_p_`ii'', "%10.0fc"))
				ereturn display, noemptycells
				di as txt ""
			}
			local obs = `obs'+`N_p_`ii''
			local ii = `ii'+1
		}
	}
	else {
		if "`nolog'" == "" & "`first'" == "" {
			di as txt "Pooled " as res "probit" as txt " regression using " as res "`tid'" as txt " = " as res "`tmin'" as txt "-" as res "`tmax'" _c
		}
		if "`first'" != "" {
			di ""
		}
		if "`nolog'" == "" & "`first'" != "" {
			di as txt "Pooled probit regression using `tid' = " as res "`tmin'" as txt "-" as res "`tmax'"
		}
		capture qui probit `seldep' `zz' if `touse'
		if _rc {
			if "`nolog'" == "" & "`first'" == "" {
				di ""
			}
			if "`debug'" == "" {
				di as err "error occurred in probit regression."
				di as err "Use -debug- option for details."
			}
			else {
				di as err "error occurred in probit regression"
				capture noi probit `seldep' `zz' if `touse'
				di _n as txt "[VARIABLE NAME INFORMATION]"
				mata: s1 = tokens(st_local("zz1"))
				mata: s2 = tokens(st_local("zzname1"))
				//mata: s2 = subinstr(s2, "m_device:", "", .)
				//mata: s2 = subinstr(s2, "c_device:", "", .)
				mata: (s1', s2')
			}
			exit _rc
		}
		qui gen `seltouse' = e(sample)
		qui predict `zhs' if e(sample), xb
		mat `pihs' = e(b)
		mat `pihsih' = -e(V)
		local obs = e(N)
		tempname N_p k_p b_p V_p
		scalar `N_p' = e(N)
		scalar `k_p' = e(k)
		mat `b_p' = e(b)
		mat `V_p' = e(V)
		mat colnames `b_p' = _:
		mat colnames `V_p' = _:
		mat rownames `V_p' = _:
		mat colnames `b_p' = `zznames'
		mat colnames `V_p' = `zznames'
		mat rownames `V_p' = `zznames'
		if "`first'" != "" {
			tempname btmp vtmp
			mat `btmp' = `b_p'
			mat `vtmp' = `V_p'
			ereturn post `btmp' `vtmp', depname(`seldep')
			di _n as txt "Number of obs = " as res strtrim(strofreal(`N_p', "%10.0fc"))
			ereturn display, noemptycells
			di as txt ""
		}
	}
	if "`nolog'" == "" & "`first'" == "" {
		di as txt ""
	}
	
	// two frames required
	local user_frame = c(frame)
	tempname balanced_frame pdreg_frame
	qui frame copy `user_frame' `balanced_frame', replace
	frame `balanced_frame' {
		qui tsfill, full
		qui frame copy `balanced_frame' `pdreg_frame', replace
	}
	
	// use pdreg_frame
	frame `pdreg_frame' {
		
		tempfile pdv_file
		mata: xtselfe_reg("`nn'", "`tt'", "`t_all'", "`tlevels'", "`seltouse'", ///
			"`seldep'", "`depvar'", "`indepvars'", "`zhs'", "`rhoopt'", "`hetcorr'", ///
			"`vcid'", "`pdv_file'")
		
		tempname N_g T N_selected comb b_r
		scalar `N_g' = e(N_g)
		scalar `T' = e(T)
		scalar `N_selected' = e(N_selected)
		mat `comb' = e(comb)
		mat `b_r' = e(b_r)
		
		// step 3: weighted least squares
		capture qui regress pdyv fxx* crt* [aweight = 1/pdwv] if pdsv==1, nocons vce(cluster fid1)  // pdwv = T_i
		if _rc {
			di as err "error occurred in weighted least squares regression"
			exit _rc
		}
		tempname N_pairs df_m b_b V_unadj
		scalar `N_pairs' = e(N)
		scalar `df_m' = e(df_m)
		mat `b_b' = e(b)
		mat `V_unadj' = e(V)
	}
	
	// use balanced_frame
	frame `balanced_frame' {
		
		// regression for _cons
		tempvar xb_u ue_u
		qui gen `xb_u' = 0
		local ii = 1
		foreach v of local indepvars {
			qui replace `xb_u' = `xb_u'+`v'*`b_b'[1,`ii'] if `touse' & `seltouse'
			local ii = `ii'+1
		}
		qui gen `ue_u' = `depvar'-`xb_u' if `touse' & `seltouse'
		capture qui regress `ue_u' if `touse' & `seltouse' & `seldep'==1, vce(cluster `vcid')
		if _rc {
			di as err "error occurred in regression for _cons"
			exit _rc
		}
		local bleng0 = colsof(`b_b')
		scalar `df_m' = `df_m'+1
		mat `b_b' = (`b_b',e(b))
		mat `V_unadj' = (`V_unadj',J(`bleng0',1,0))
		mat `V_unadj' = `V_unadj'\(J(1,`bleng0',0),e(V))
		
		// delta method
		if "`unadj'" == "" {
			if "`nolog'" == "" {
				/*
				di as txt "Computing " as res "cluster-robust" as txt " variance" ///
					as txt " adjusted for " as res "generated regressors" as txt "..." _n
				*/
				di as txt "Computing cluster variance with correction for generated regressors..."
			}
			
			mata: xtselfe_delta("`nn'", "`tt'", "`t_all'", "`seltouse'", "`seldep'", ///
				"`zhs'", "`hetcorr'", "`zz'", "`pihs'", "`pihsih'", "`b_r'", "`b_b'", ///
				"`ue_u'", "`epsopt'", "`pdv_file'")
			
			tempname V_delta
			mat `V_delta' = e(V_delta)
		}
	}
	qui frame drop `balanced_frame'
	qui frame drop `pdreg_frame'
	
	// N_clust
	if "`vcid'" == "`pid'" {
		local ncid = `N_g'
	}
	else {
		qui levelsof `vcid' if `touse' & `seltouse'
		local ncid = r(r)
	}
	
	// display & ereturn final regression
	local xxnames "`indepvars'"
	if "`nointeract'" == "" {
		foreach j of local tlevels {
			local xxnames "`xxnames' correction:`j'"
		}
	}
	else {
		local xxnames "`xxnames' correction:`tmin'-`tmax'"
	}
	local xxnames "`xxnames' _cons"
	tempname b V
	mat colnames `b_b' = _:
	mat colnames `b_b' = `xxnames'
	mat colnames `V_unadj' = _:
	mat rownames `V_unadj' = _:
	mat colnames `V_unadj' = `xxnames'
	mat rownames `V_unadj' = `xxnames'
	mat `b' = `b_b'
	if "`unadj'" == "" {
		mat `V' = `V_delta'
		mat colnames `V' = _:
		mat rownames `V' = _:
		mat colnames `V' = `xxnames'
		mat rownames `V' = `xxnames'
	}
	else {
		mat `V' = `V_unadj'
	}
	ereturn post `b' `V', depname(`depvar') obs(`obs') esample(`seltouse')
	ereturn scalar N_clust = `ncid'
	ereturn local clustvar "`vcid'"
	ereturn local vcetype "Robust"  // for display
	//------------------------------------------------------------------
	if "`unadj'" == "" | "`nolog'" != "" {
		di ""
	}
	di as txt "Fixed-effects estimation with sample selection correction"
	//------------------------------------------------------------------
	di _n as txt "Number of obs" _skip(6) as txt "= " as res %10.0fc `obs'
	di as txt "Number of selected = " as res %10.0fc `N_selected'
	di as txt "Number of groups" _skip(3) as txt "= " as res %10.0fc `N_g'
	di _n as txt "Group variable: " as res "`pid'"
	ereturn display, noemptycells
	if "`unadj'" == "" {
		di as txt "note. Standard errors are " as res "adjusted" as txt " for generated regressors."
	}
	else {
		di as txt "note. Standard errors are " as res "not adjusted" as txt " for generated regressors."
	}
	ereturn scalar N_selected = `N_selected'
	ereturn scalar N_g = `N_g'
	ereturn scalar N_pairs = `N_pairs'
	ereturn scalar T = `T'
	ereturn scalar df_m = `df_m'
	ereturn scalar k_correct = `k_correct'
	ereturn local vcetype "robust"
	ereturn local vce "`vcecmd'"
	ereturn local rhotype "`rhoname'"
	ereturn local device "`devname'"
	ereturn local seldep "`seldep'"
	ereturn local ivar "`pid'"
	ereturn local predict "xtselfe_p"
	ereturn local cmdline "`cmdline'"
	ereturn local cmd "xtselfe"
	ereturn mat V_unadj = `V_unadj'
	
	// ereturn rho
	ereturn scalar k_rho = colsof(`b_r')
	local rrnames ""
	if "`rhoname'" == "stationary" {
		local k = `tt'-1
		forv j = 1/`k' {
			local rrnames "`rrnames' lag`j'"
		}
	}
	else if "`rhoname'" == "unrestricted" {
		local tr = rowsof(`comb')
		forv j = 1/`tr' {
			local jj = `comb'[`j', 1]
			local kk = `comb'[`j', 2]
			local jj2 : word `jj' of `tlevels'
			local kk2 : word `kk' of `tlevels'
			local rrnames "`rrnames' pair:[`jj2',`kk2']"
		}
	}
	else if "`rhoname'" == "common" {
		local rrnames "common"
	}
	mat colnames `b_r' = `rrnames'
	mat colnames `b_r' = `rrnames'
	ereturn mat b_rho = `b_r'
	
	// ereturn probit
	if "`selpool'" == "" {
		local ii = 1
		foreach j of local tlevels {
			ereturn scalar n_probit_`j' = `N_p_`ii''
			ereturn scalar k_probit_`j' = `k_p_`ii''
			ereturn mat b_probit_`j' = `b_p_`ii''
			ereturn mat V_probit_`j' = `V_p_`ii''
			local ii = `ii'+1
		}
	}
	else {
		ereturn scalar n_probit = `N_p'
		ereturn scalar k_probit = `k_p'
		ereturn mat b_probit = `b_p'
		ereturn mat V_probit = `V_p'
	}
end

* ------------------------------------------------------------------
* Helper programs
* ------------------------------------------------------------------

program define IsAbbrev, rclass
	args abbrev target minlen
	local len = length("`abbrev'")
	if `len' < real("`minlen'") {
		return scalar match = 0
		exit
	}
	
	local abcheck = substr("`target'", 1, `len')
	if lower("`abbrev'") == lower("`abcheck'") {
		return scalar match = 1
	}
	else {
		return scalar match = 0
	}
end

program define GetFirstChar, rclass
	return local first = lower(substr("`1'", 1, 1))
end

program define CheckVarname, rclass
	syntax varlist(max=1)
	return local varname = "`varlist'"
end

program RephraseForSelectSpec, rclass
	args regex text
	local sel_mat = regexm("`text'", "`regex'")
	if `sel_mat' {
		local sel_bef = regexs(1)
		local text = subinstr("`text'", "`sel_bef'" + "(", "`sel_bef'" + " _hasparen _devvars(", .)
	}
	return local text = "`text'"
end

* ------------------------------------------------------------------
* Parse select()
* ------------------------------------------------------------------

program define ParseSelect, sclass
	local lhsvar "`1'"
	macro shift 1
	if "`1'" == "=" {
		macro shift 1
	}
	sreturn clear
	ParseSelectHelper `lhsvar' `*'
end

program ParseSelectHelper, sclass
	capture noi syntax varlist(numeric fv) [, Mundlak Chamberlain None _HASPAREN _DEVVARS(string) Pool]
	if _rc {
		di as err "syntax error in select()"
		exit _rc
	}
	sreturn local varlist `varlist'
	local typ = "`chamberlain'`mundlak'`none'"
	if "`typ'" == "none" {
		sreturn local devtype "none"
	}
	else if "`typ'" == "" | "`typ'" == "mundlak" {
		sreturn local devtype "mundlak"
	}
	else if "`typ'" == "chamberlain" {
		sreturn local devtype "chamberlain"
	}
	else {
		di as err "use only one of 'mundlak', 'chamberlain', and 'none'"
		exit 198
	}
	if "`_hasparen'" == "" {
		sreturn local hasdevvars false
	}
	else {
		sreturn local hasdevvars true
	}
	sreturn local devvars "`_devvars'"
	sreturn local pool "`pool'"
end

* ------------------------------------------------------------------
* Parse rhotype()
* ------------------------------------------------------------------

program define ParseRhotype, sclass
	capture noi syntax , [Unrestricted Stationary Common EXChangeable]
	if _rc {
		di as err "syntax error in rhotype()"
		exit _rc
	}
	
	sret clear
	if "`exchangeable'" != "" {
		local common = "common"
	}
	local str = "`unrestricted'`stationary'`common'"
	if "`str'" == "stationary" {
		sreturn local rhotype = "`str'"
	}
	else if "`str'" == "unrestricted" {
		sreturn local rhotype = "`str'"
	}
	else if "`str'" == "`common'" {
		sreturn local rhotype = "`str'"
	}
	else {
		di as err "rhotype must be one of 'stationary', 'unrestricted', and 'common'"
		exit 198
	}
end

* ------------------------------------------------------------------
* Parse vce()
* ------------------------------------------------------------------

program define ParseVceOpt, sclass
	sret clear
	GetFirstChar "`1'"
	local x = r(first)
	if "`x'" == "u" {
		IsAbbrev "`1'" "unadjusted" 3
		if `r(match)' == 0 {
			di as err "invalid option '`1'' in vce()"
			exit 198
		}
		sret local unadjusted "unadjusted"
		macro shift
	}
	GetFirstChar "`1'"
	local x = r(first)
	if "`x'" == "r" {
		IsAbbrev "`1'" "robust" 1
		if `r(match)' == 0 {
			di as err "invalid option '`1'' in vce()"
			exit 198
		}
		sret local vcetype "robust"
		macro shift
		if "`1'" != "" {
			di as err "invalid option 'robust `*'' in vce()"
			exit 198
		}
	}
	else if "`x'" == "c" {
		IsAbbrev "`1'" "cluster" 2
		if `r(match)' == 0 {
			di as err "invalid option '`1'' in vce(r)"
			exit 198
		}
		sret local vcetype "cluster"
		macro shift
		if "`1'" == "" {
			di as err "'cluster' option in vce() requires a variable name"
			exit 198
		}
		if "`2'" != "" {
			di as err "'cluster' option in vce() accepts only one variable name"
			exit 198
		}
		capture noi CheckVarname `1'
		if _rc {
			di as err "'cluster' in vce() must be followed by a valid variable name"
			exit _rc
		}
		sret local clustvar = r(varname)
	}
	else if "`x'" == "d" {
		IsAbbrev "`1'" "delta" 1
		if `r(match)' == 0 {
			di as err "invalid option '`1'' in vce(r)"
			exit 198
		}
		sret local vcetype "delta"
		macro shift
		if "`1'" == "" | "`2'" != "" {
			di as err "'delta' option in vce() requires a real number"
			exit 198
		}
		capture noi local d = real("`1'")
		if _rc {
			di as err "syntax error in vce(delta `1')"
			exit _rc
		}
		sret local delta = `d'
	}
end

* ------------------------------------------------------------------
* mata
* ------------------------------------------------------------------

version 16.1
mata:
mata clear
mata set matastrict on

//------------------------------------------------------------------
// lnL for intertemporal correlation coefficient
//------------------------------------------------------------------

function loglik_rho(real scalar rho, real colvector q1x1, real colvector q2x2, real colvector q1q2) {
	real colvector pp
	pp = binormal(q1x1,q2x2,q1q2:*rho)
	return(sum(ln(pp)))
}

//------------------------------------------------------------------
// Brent's algorithm for minimization of univariate function
//------------------------------------------------------------------
/*
References:
1. Brent, R. P. 1973. Algorithms for Minimization without Derivatives. In Prentice-Hall Series in Automatic Computation, ed. G. Forsythe, chap. 4, 47--60. Englewood Cliﬀs, N.J.: Prentice-Hall.
2. https://github.com/SurajGupta/r-source/blob/master/src/library/stats/src/optimize.c#L94
*/

function fmin_rho_Brent(real scalar ax, real scalar bx, real colvector q1x1, real colvector q2x2, real colvector q1q2) {
	real scalar tol, c, eps, tol1, a, b, v, w, x, d, e, fx, fv, fw, tol3, iter, xm, t2, p, q, r, u, fu
	
	tol = 1e-12
	c = (3.0 - sqrt(5.0)) * 0.5
	eps = 5.0e-16
	tol1 = eps + 1.0
	eps = sqrt(eps)
	
	a = ax
	b = bx
	v = a + c*(b-a)
	w = v
	x = v
	
	d = 0.0
	e = 0.0
	fx = -loglik_rho(x, q1x1, q2x2, q1q2)
	fv = fx
	fw = fx
	tol3 = tol / 3.0
	
	// main loop
	for (iter=1; iter<=1000; iter++) {
		xm = (a + b)*0.5
		tol1 = eps * abs(x) + tol3
		t2 = tol1 * 2.0
		
		// check stopping criterion
		if (abs(x - xm) <= t2 - (b-a)*0.5) break
		p = 0.0
		q = 0.0
		r = 0.0
		if (abs(e) > tol1) {  // fit parabola
			r = (x-w)*(fx-fv)
			q = (x-v)*(fx-fw)
			p = (x-v)*q - (x-w)*r
			q = (q-r)*2.0
			if (q > 0) p = -p
			else q = -q
			r = e
			e = d
		}
		
		if (abs(p) >= abs(q*0.5*r) || p <= q*(a-x) || p >= q*(b-x)) {  // a golden-section step
			if (x < xm) e = b-x
			else e = a-x
			d = c*e
		} else {  // a parabolic-interpolation step
			d = p/q
			u = x+d
			
			// f must not be evaluated too close to ax or bx
			if (u-a < t2 || b-u < t2) {
				d = tol1
				if (x >= xm) d = -d
			}
		}
		
		// f must not be evaluated too close to x
		
		if (abs(d) >= tol1) u = x + d
		else if (d > 0.0) u = x + tol1
		else u = x - tol1
		
		fu = -loglik_rho(u, q1x1, q2x2, q1q2)
		
		// update a, b, v, w, and x
		if (fu <= fx) {
			if (u < x) b = x
			else a = x
			v = w
			w = x
			x = u
			fv = fw
			fw = fx
			fx = fu
		} else {
			if (u < x) a = u
			else b = u
			if (fu <= fw || w == x) {
				v = w
				fv = fw
				w = u
				fw = fu
			} else if (fu <= fv || v == x || v == w) {
				v = u
				fv = fu
			}
		}
	}
	return(x)
}

//------------------------------------------------------------------

function dff1(real matrix v, real scalar c) {
	real scalar t, s
	t = rows(v)
	s = t-c
	return(select(v, J(c,1,0)\J(s,1,1)))
}

function dff0(real matrix v, real scalar c) {
	real scalar t, s
	t = rows(v)
	s = t-c
	return(select(v, J(s,1,1)\J(c,1,0)))
}

function dff(real matrix v, real scalar c) {
	real matrix dff1, dff0
	dff1 = dff1(v,c)
	dff0 = dff0(v,c)
	return(dff1:-dff0)
}

function ind_dff(real matrix v, real scalar c) {
	real matrix dff1, dff0
	dff1 = dff1(v,c)
	dff0 = dff0(v,c)
	return(dff1:*dff0)
}

function gethh(real matrix aa0, real matrix bb0, real colvector rr0) {
	real colvector sd_r
	real matrix bb1, abcdf
	sd_r = sqrt(1:-rr0:^2)
	bb1 = (bb0:-rr0:*aa0):/sd_r
	abcdf = binormal(aa0,bb0,rr0)
	return((normalden(aa0):*normal(bb1)):/abcdf)
}

function getff(real colvector aa0, real colvector bb0, real colvector rr0) {
	real colvector sd_r, ff0a, ff0b, ff0c
	sd_r = sqrt(1:-rr0:^2)
	ff0a = aa0:^2:+bb0:^2:-(2:*rr0):*(aa0:*bb0)
	ff0b = exp((-1/2):*ff0a:/(sd_r:^2))
	ff0c = ff0b:/(2*pi():*sd_r)
	return(ff0c)
}

struct f_arg0 {
	real scalar t0, kxi0
	real colvector one_nv
	real matrix used4_mt, zhs_mt, eye_nttm, zero_ntm, zv0
}

struct f_arg1 {
	real scalar n0, kxi1
	real colvector one_tv
	real matrix zero_k1nm, s_mt
}

struct f_arg2 {
	real scalar t1, tr, kxi2, kxi12
	real matrix zero_rnm, i12_mt
}

struct f_arg3 {
	real scalar kxi30, kxi3, kxi130, kpsi
	real colvector one_rv, zero_rv
	real matrix pdy_mt, pdxv, psiv, ind_psi1, ind_psi2, pdw_mt, zero_k30nm
}

struct f_arg4 {
	real scalar kxi13
	real rowvector wt0, ue0
}

function stackdff(pointer f, real matrix v, struct f_arg2 scalar arg2) {
	real scalar j, k, jj, kk
	real matrix stackmat
	stackmat = arg2.zero_rnm
	for (j=1; j<=arg2.t1; j++) {
		k = j-1
		kk = k*(arg2.t1-(k-1)/2)
		jj = j*(arg2.t1-k/2)
		stackmat[kk+1::jj,.] = (*f)(v,j)
	}
	return(stackmat)
}

function comvec(real matrix vm, real matrix im) {
	return((vec(vm):*vec(im)))
}

function selvec(real matrix vm, real matrix im) {
	return(select(vec(vm),vec(im)))
}

function prerho(pointer f, real matrix sy1m, real matrix sy2m, real matrix sx1m, real matrix sx2m, real matrix indm) {
	real colvector sy1, sy2, sx1, sx2, q1, q2
	sy1 = (*f)(sy1m,indm)
	sy2 = (*f)(sy2m,indm)
	sx1 = (*f)(sx1m,indm)
	sx2 = (*f)(sx2m,indm)
	q1 = 2:*sy1:-1
	q2 = 2:*sy2:-1
	return((q1:*sx1,q2:*sx2,q1:*q2))
}

function estrho(pointer f, real matrix sy1m, real matrix sy2m, real matrix sx1m, real matrix sx2m, real matrix indm) {
	real scalar lb, ub, rh0
	real matrix premat
	lb = -1+1e-9
	ub = 1-1e-9
	premat = prerho(&selvec(),sy1m,sy2m,sx1m,sx2m,indm)
	rh0 = (*f)(lb,ub,premat[.,1],premat[.,2],premat[.,3])
	return(rh0)
}

function makezh(real colvector b, struct f_arg0 scalar arg0) {
	real scalar j
	real matrix zhs, est1, sx0
	if (rows(b)==arg0.kxi0) {  // "pool"
		zhs = (arg0.zv0,J(rows(arg0.zv0),1,1))*b
	}
	else {
		est1 = colshape(b,arg0.kxi0)'  // k*T
		zhs = arg0.zero_ntm
		for (j=1; j<=arg0.t0; j++) {
			sx0 = select(arg0.zv0,arg0.eye_nttm[.,j]:==1)
			zhs[.,j] = (sx0,arg0.one_nv)*est1[.,j]
		}
	}
	return(colshape(zhs,arg0.t0)':*arg0.used4_mt)  // T*n
}

function getzh(struct f_arg0 scalar arg0) {
	return(arg0.zhs_mt:*arg0.used4_mt)
}

function gg1(real colvector b, struct f_arg0 scalar arg0, struct f_arg1 scalar arg1) {
	real scalar j, j0, j1
	real matrix re_zhs_mt, ddh, pph, fg1_h, fg10, fg1, zvi, fg1i
	re_zhs_mt = getzh(arg0)
	ddh = normalden(re_zhs_mt)
	pph = normal(re_zhs_mt)
	fg1_h = ddh:/(pph:*(1:-pph))
	fg10 = fg1_h:*(arg1.s_mt:-pph):*arg0.used4_mt  // T*n
	fg1 = arg1.zero_k1nm
	if (rows(b)==arg0.kxi0) {  // "pool"
		for (j=1; j<=arg1.n0; j++) {
			j0 = (j-1)*arg0.t0+1
			j1 = j*arg0.t0
			zvi = (arg0.zv0[j0::j1,.],arg1.one_tv)
			fg1i = zvi:*fg10[.,j]
			fg1[.,j] = colsum(fg1i)'
		}
	}
	else {
		for (j=1; j<=arg1.n0; j++) {
			j0 = (j-1)*arg0.t0+1
			j1 = j*arg0.t0
			zvi = (arg0.zv0[j0::j1,.],arg1.one_tv)
			fg1i = zvi:*fg10[.,j]
			fg1[.,j] = vec(fg1i')
		}
	}
	return(editmissing(fg1,0))
}

function get_rho_sc(real colvector b, real matrix sy1m, real matrix sy2m, real matrix sx1m, real matrix sx2m, real matrix indm) {
	real colvector w1, w2, q1q2, rr, p2h, d2h, fg20
	real matrix premat
	premat = prerho(&comvec(),sy1m,sy2m,sx1m,sx2m,indm)
	w1 = premat[.,1]
	w2 = premat[.,2]
	q1q2 = premat[.,3]
	rr = q1q2:*b
	p2h = binormal(w1,w2,rr)
	d2h = getff(w1,w2,rr)
	fg20 = (q1q2:*d2h):/p2h
	return(fg20:*vec(indm))
}

function gg2(real colvector b, struct f_arg0 scalar arg0, struct f_arg1 scalar arg1, struct f_arg2 scalar arg2, struct f_arg3 scalar arg3) {
	real scalar j, k, jj, kk, rh
	real colvector est1, est2, fg2m
	real matrix re_zhs_mt, sy1_mt, sy2_mt, sx1_mt, sx2_mt, i12, fg2
	if (rows(b)==arg2.kxi2) {  // for V
		est2 = b
		re_zhs_mt = getzh(arg0)
	}
	else {  // for H
		est1 = b[1::arg1.kxi1,.]
		est2 = b[arg1.kxi1+1::arg2.kxi12,.]
		
		// step 1
		re_zhs_mt = makezh(est1,arg0)
	}
	sy1_mt = stackdff(&dff1(),arg1.s_mt,arg2)
	sy2_mt = stackdff(&dff0(),arg1.s_mt,arg2)
	sx1_mt = stackdff(&dff1(),re_zhs_mt,arg2)
	sx2_mt = stackdff(&dff0(),re_zhs_mt,arg2)
	if (arg2.kxi2==1) {  // "common" or "exchangeable"
		rh = est2
		i12 = arg2.i12_mt
		fg2m = get_rho_sc(rh,sy1_mt,sy2_mt,sx1_mt,sx2_mt,i12)
		fg2 = rowsum(colshape(fg2m,arg2.tr))
	}
	else if (arg2.kxi2==arg2.t1) {  // "stationary"
		fg2 = J(arg1.n0,arg2.t1,0)
		for (j=1; j<=arg2.t1; j++) {
			k = j-1
			kk = k*(arg2.t1-(k-1)/2)
			jj = j*(arg2.t1-k/2)
			rh = est2[j,.]
			i12 = arg2.i12_mt[kk+1::jj,.]
			fg2m = get_rho_sc(rh,sy1_mt[kk+1::jj,.],sy2_mt[kk+1::jj,.],sx1_mt[kk+1::jj,.],sx2_mt[kk+1::jj,.],i12)
			fg2[.,j] = rowsum(colshape(fg2m,arg0.t0-j))
		}
	}
	else if (arg2.kxi2==arg2.tr) {  // "unrestricted"
		fg2 = arg2.zero_rnm'
		for (j=1; j<=arg2.tr; j++) {
			rh = est2[j,.]
			i12 = arg2.i12_mt[j,.]
			fg2m = get_rho_sc(rh,sy1_mt[j,.],sy2_mt[j,.],sx1_mt[j,.],sx2_mt[j,.],i12)
			fg2[.,j] = fg2m
		}
	}
	return(editmissing(fg2',0))
}

function gg30(real colvector b, struct f_arg0 scalar arg0, struct f_arg1 scalar arg1, struct f_arg2 scalar arg2, struct f_arg3 scalar arg3) {
	real scalar j, k, jj, kk, j0, j1
	real colvector est1, est2, est3, rhv2, rh, pdwi, pdyi, fg3i
	real matrix re_psiv, re_zhs_mt, psi1_mt, psi2_mt, zh1, zh2, hh1, hh2, fg3, pdxi, psii, pdxxi
	if (rows(b)==arg3.kxi30) {  // for V
		est3 = b
		re_psiv = arg3.psiv
	}
	else {  // for H
		est1 = b[1::arg1.kxi1,.]
		est2 = b[arg1.kxi1+1::arg2.kxi12,.]
		est3 = b[arg2.kxi12+1::arg3.kxi130,.]
		
		// step 1
		re_zhs_mt = makezh(est1,arg0)
		
		// step 2
		if (arg2.kxi2==1) {  // "common" or "exchangeable"
			rhv2 = arg3.one_rv:*est2
		}
		else if (arg2.kxi2==arg2.t1) {  // "stationary"
			rhv2 = arg3.zero_rv
			for (j=1; j<=arg2.t1; j++) {
				k = j-1
				kk = k*(arg2.t1-(k-1)/2)
				jj = j*(arg2.t1-k/2)
				rhv2[kk+1::jj,.] = J(arg0.t0-j,1,1):*est2[j,.]
			}
		}
		else if (arg2.kxi2==arg2.tr) {  // "unrestricted"
			rhv2 = est2
		}
		
		// make pisv
		psi1_mt = arg2.zero_rnm
		psi2_mt = arg2.zero_rnm
		for (j=1; j<=arg2.t1; j++) {
			k = j-1
			kk = k*(arg2.t1-(k-1)/2)
			jj = j*(arg2.t1-k/2)
			rh = rhv2[kk+1::jj,.]
			zh1 = dff1(re_zhs_mt,j)
			zh2 = dff0(re_zhs_mt,j)
			hh1 = gethh(zh1,zh2,rh)
			hh2 = gethh(zh2,zh1,rh)
			psi1_mt[kk+1::jj,.] = hh1:+rh:*hh2
			psi2_mt[kk+1::jj,.] = hh2:+rh:*hh1
		}
		re_psiv = vec(psi1_mt):*arg3.ind_psi1:+vec(psi2_mt):*arg3.ind_psi2
	}
	fg3 = arg3.zero_k30nm
	for (j=1; j<=arg1.n0; j++) {
		j0 = (j-1)*arg2.tr+1
		j1 = j*arg2.tr
		pdwi = arg3.pdw_mt[.,j]
		pdyi = arg3.pdy_mt[.,j]:*pdwi
		pdxi = arg3.pdxv[j0::j1,.]
		psii = re_psiv[j0::j1,.]
		pdxxi = (pdxi,psii):*pdwi
		fg3i = cross(pdxxi,(pdyi:-pdxxi*est3))
		fg3[.,j] = fg3i
	}
	return(editmissing(fg3,0))
}

function gg31(real colvector b, struct f_arg4 scalar arg4) {
	real rowvector fg4
	fg4 = arg4.ue0:-arg4.wt0:*b
	return(editmissing(fg4,0))
}

function num_cov(real colvector b, struct f_arg0 scalar arg0, struct f_arg1 scalar arg1, struct f_arg2 scalar arg2, struct f_arg3 scalar arg3, struct f_arg4 scalar arg4) {
	real colvector xi1h, xi2h, xi3h, xi4h
	real matrix est_fg, est_c
	xi1h = b[1::arg1.kxi1,.]
	xi2h = b[arg1.kxi1+1::arg2.kxi12,.]
	xi3h = b[arg2.kxi12+1::arg3.kxi130,.]
	xi4h = b[arg4.kxi13,.]
	est_fg = gg1(xi1h,arg0,arg1)\gg2(xi2h,arg0,arg1,arg2,arg3)\gg30(xi3h,arg0,arg1,arg2,arg3)\gg31(xi4h,arg4)  // p*n
	est_c = est_fg*est_fg'
	return(est_c)
}

function num_dff(pointer f, real colvector b, real scalar endpoint, real matrix epsm, struct f_arg0 scalar arg0, struct f_arg1 scalar arg1, struct f_arg2 scalar arg2, struct f_arg3 scalar arg3) {
	real scalar j, k, epsab
	real colvector eps_a, eps_b, xiha, xihb
	real matrix eye_b, eps_m, eps_ma, eps_mb, est_d, gmat_a, gmat_b, gmat_d
	k = rows(b)
	eye_b = I(k)
	eps_m = epsm[1::k,.]
	eps_ma = eye_b:*eps_m[.,1]
	eps_mb = eye_b:*eps_m[.,2]
	est_d = J(k-endpoint,endpoint,0)
	for (j=1; j<=endpoint; j++) {
		eps_a = eps_ma[.,j]
		eps_b = eps_mb[.,j]
		epsab = sum(eps_a:+eps_b)
		xiha = b:-eps_a
		xihb = b:+eps_b
		gmat_a = (*f)(xiha,arg0,arg1,arg2,arg3)
		gmat_b = (*f)(xihb,arg0,arg1,arg2,arg3)
		gmat_d = (gmat_b:-gmat_a):/(epsab)
		est_d[.,j] = rowsum(gmat_d)
	}
	return(est_d)
}

function get_rho_he(real colvector b, real matrix sy1m, real matrix sy2m, real matrix sx1m, real matrix sx2m, real matrix indm) {
	real scalar isd_r2
	real colvector w1, w2, q1q2, rr, w1w2, dpr, fh20
	real matrix premat
	premat = prerho(&comvec(),sy1m,sy2m,sx1m,sx2m,indm)
	w1 = premat[.,1]
	w2 = premat[.,2]
	q1q2 = premat[.,3]
	rr = q1q2:*b
	isd_r2 = 1:/(1:-b:^2)
	w1w2 = w1:*w2
	dpr = getff(w1,w2,rr):/binormal(w1,w2,rr)
	fh20 = dpr:*(isd_r2:*rr:*(1:-isd_r2:*(w1:^2:+w2:^2:-2:*rr:*w1w2)):+isd_r2:*w1w2:-dpr)
	return(fh20:*vec(indm))
}

function get_rho_ih(real colvector b, real matrix zhm, struct f_arg1 scalar arg1, struct f_arg2 scalar arg2) {
	real scalar j, k, jj, kk, rh
	real colvector fh2
	real matrix sy1_mt, sy2_mt, sx1_mt, sx2_mt, i12, ifh2
	sy1_mt = stackdff(&dff1(),arg1.s_mt,arg2)
	sy2_mt = stackdff(&dff0(),arg1.s_mt,arg2)
	sx1_mt = stackdff(&dff1(),zhm,arg2)
	sx2_mt = stackdff(&dff0(),zhm,arg2)
	if (arg2.kxi2==1) {  // "common" or "exchangeable"
		rh = b
		i12 = arg2.i12_mt
		fh2 = get_rho_he(rh,sy1_mt,sy2_mt,sx1_mt,sx2_mt,i12)
		ifh2 = 1:/colsum(fh2)
	}
	else if (arg2.kxi2==arg2.t1) {  // "stationary"
		ifh2 = I(arg2.t1)
		for (j=1; j<=arg2.t1; j++) {
			k = j-1
			kk = k*(arg2.t1-(k-1)/2)
			jj = j*(arg2.t1-k/2)
			rh = b[j,.]
			i12 = arg2.i12_mt[kk+1::jj,.]
			fh2 = get_rho_he(rh,sy1_mt[kk+1::jj,.],sy2_mt[kk+1::jj,.],sx1_mt[kk+1::jj,.],sx2_mt[kk+1::jj,.],i12)
			ifh2[j,j] = 1:/colsum(fh2)
		}
	}
	else if (arg2.kxi2==arg2.tr) {  // "unrestricted"
		ifh2 = I(arg2.tr)
		for (j=1; j<=arg2.tr; j++) {
			rh = b[j,.]
			i12 = arg2.i12_mt[j,.]
			fh2 = get_rho_he(rh,sy1_mt[j,.],sy2_mt[j,.],sx1_mt[j,.],sx2_mt[j,.],i12)
			ifh2[j,j] = 1:/colsum(fh2)
		}
	}
	return(editmissing(ifh2,0))
}

function getvcov(pointer matrix bigh, pointer matrix bigv, real scalar step, real scalar kb) {
	real scalar j, k
	real matrix vcov, ih, vh, ih2
	vcov = J(kb,kb,0)
	for (j=1; j<=3; j++) {
		ih = *bigh[step,j]
		for (k=1; k<=3; k++) {
			vh = *bigv[j,k]
			ih2 = *bigh[step,k]
			vcov = vcov:+ih*vh*ih2'
		}
	}
	return(vcov)
}

void xtselfe_reg(string scalar nn, string scalar tt, string scalar t_all, string scalar t_val, ///
	string scalar stouse, string scalar sv, string scalar yv, string scalar xv, string scalar zhs, ///
	string scalar rhoopt, string scalar hetcorr, string scalar vcid, string scalar tmpfile) {
	
	// structures
	struct f_arg0 scalar arg0
	struct f_arg1 scalar arg1
	struct f_arg2 scalar arg2
	struct f_arg3 scalar arg3
	struct f_arg4 scalar arg4
	
	// declarations for coefficients
	real scalar i, j, k, ii, jj, kk, tall, kxv0, n0_up, t0_up, ssum, rh0
	real rowvector used2_n, wt
	real colvector used1, used2_t, used3, pdsv, pdyv, rhv, rhv2, rh, pdwv
	real matrix used1_mt, y_mt, xv0, zero_rtm, pds_mt, msx, tmpv_mt, pd_tmpv_mt, ///
		comb, ind_psi10, ind_psi20, sy1_mt, sy2_mt, sx1_mt, sx2_mt, psi1_mt, psi2_mt, ///
		zh1, zh2, hh1, hh2
	
	// declarations for transformed data
	string rowvector fids, fxxs, crts
	real scalar kcid
	real matrix cid0, cidv, cid_mt, cidind, datamat
	
	// declarations for output
	string scalar msg
	string rowvector tstr
	real scalar log_it, hopt, ropt, fh
	//------------------------------------------------------------------
	log_it = st_local("nolog") == ""
	//------------------------------------------------------------------
	
	// variable setup for coefficients
	arg1.n0 = st_numscalar(nn)
	arg0.t0 = st_numscalar(tt)
	tall = st_numscalar(t_all)
	used1 = editmissing(st_data(.,stouse),0)
	used1_mt = colshape(used1,tall)'
	used2_n = colsum(used1_mt):!=0
	n0_up = rowsum(used2_n)
	used2_t = rowsum(used1_mt):!=0
	t0_up = colsum(used2_t)
	used3 = used2_n'#used2_t
	arg0.used4_mt = select(select(used1_mt,used2_t),used2_n)
	arg1.s_mt = select(select(colshape(editmissing(st_data(.,sv),0):*used1,tall)',used2_t),used2_n)
	ssum = sum(arg1.s_mt)
	y_mt = select(select(colshape(editmissing(st_data(.,yv),0):*used1,tall)',used2_t),used2_n)
	arg0.zhs_mt = select(select(colshape(editmissing(st_data(.,zhs),0):*used1,tall)',used2_t),used2_n)
	xv0 = select(editmissing(st_data(.,xv),0):*used1,used3)
	kxv0 = cols(xv0)
	
	// update n and T
	if (arg1.n0!=n0_up) {
		arg1.n0 = n0_up
	}
	if (arg0.t0!=t0_up) {
		arg0.t0 = t0_up
	}
	arg2.t1 = arg0.t0-1
	arg2.tr = arg0.t0*arg2.t1/2
	arg0.one_nv = J(arg1.n0,1,1)
	arg3.one_rv = J(arg2.tr,1,1)
	arg3.zero_rv = J(arg2.tr,1,0)
	zero_rtm = J(arg2.tr,arg0.t0,0)
	arg2.zero_rnm = J(arg2.tr,arg1.n0,0)
	
	// pairwise-difference (pd)
	pds_mt = arg2.zero_rnm
	arg2.i12_mt = arg2.zero_rnm
	arg3.pdy_mt = arg2.zero_rnm
	for (j=1; j<=arg2.t1; j++) {
		k = j-1
		kk = k*(arg2.t1-(k-1)/2)
		jj = j*(arg2.t1-k/2)
		pds_mt[kk+1::jj,.] = ind_dff(arg1.s_mt,j)
		arg2.i12_mt[kk+1::jj,.] = ind_dff(arg0.used4_mt,j)
		arg3.pdy_mt[kk+1::jj,.] = dff(y_mt,j)
	}
	pdsv = vec(pds_mt)
	pdyv = vec(arg3.pdy_mt)
	arg3.pdxv = J(arg2.tr*arg1.n0,kxv0,0)
	msx = J(kxv0,arg1.n0,0)  // for _cons in delta
	for (i=1; i<=kxv0; i++) {
		tmpv_mt = colshape(xv0[.,i],arg0.t0)'
		msx[i,.] = colsum(tmpv_mt:*arg1.s_mt)
		pd_tmpv_mt = arg2.zero_rnm
		for (j=1; j<=arg2.t1; j++) {
			k = j-1
			kk = k*(arg2.t1-(k-1)/2)
			jj = j*(arg2.t1-k/2)
			pd_tmpv_mt[kk+1::jj,.] = dff(tmpv_mt,j)
		}
		arg3.pdxv[.,i] = vec(pd_tmpv_mt)
	}
	
	// indicators for pd
	hopt = st_numscalar(hetcorr)
	comb = J(arg2.tr,2,0)
	if (hopt==1) {  // default
		arg3.kpsi = arg0.t0
		ind_psi10 = zero_rtm
		ind_psi20 = zero_rtm
		ii = 1
		for (j=1; j<=arg2.t1; j++) {
			for (k=1; k<=arg0.t0-j; k++) {
				i = j+k
				ind_psi10[ii,i] = 1
				ind_psi20[ii,k] = -1
				comb[ii,.] = (i,k)
				ii = ii+1
			}
		}
	}
	else {
		arg3.kpsi = 1
		ind_psi10 = arg3.one_rv
		ind_psi20 = -arg3.one_rv
		ii = 1
		for (j=1; j<=arg2.t1; j++) {
			for (k=1; k<=arg0.t0-j; k++) {
				i = j+k
				comb[ii,.] = (i,k)
				ii = ii+1
			}
		}
	}
	arg3.ind_psi1 = arg0.one_nv#ind_psi10
	arg3.ind_psi2 = arg0.one_nv#ind_psi20
	
	// step 2: estimate rho
	//------------------------------------------------------------------
	if (log_it) printf("{txt}Serial correlation {res}rho{txt} in selection error ")
	//------------------------------------------------------------------
	tstr = tokens(t_val)
	ropt = st_numscalar(rhoopt)
	sy1_mt = stackdff(&dff1(),arg1.s_mt,arg2)
	sy2_mt = stackdff(&dff0(),arg1.s_mt,arg2)
	sx1_mt = stackdff(&dff1(),arg0.zhs_mt,arg2)
	sx2_mt = stackdff(&dff0(),arg0.zhs_mt,arg2)
	if (ropt==2) {  // "common" or "exchangeable"
		rh0 = estrho(&fmin_rho_Brent(),sy1_mt,sy2_mt,sx1_mt,sx2_mt,arg2.i12_mt)
		rhv = rh0
		rhv2 = arg3.one_rv:*rh0
		if (log_it) {
			printf("(common) = {res}%7.5f{txt}\n", rh0)
			displayflush()
		}
	}
	else if (ropt==1) {  // "stationary" is used by default
		if (log_it) printf("(stationarity assumed):\n\n")
		rhv = J(arg2.t1,1,0)
		rhv2 = arg3.zero_rv
		for (j=1; j<=arg2.t1; j++) {
			k = j-1
			kk = k*(arg2.t1-(k-1)/2)
			jj = j*(arg2.t1-k/2)
			rh0 = estrho(&fmin_rho_Brent(),sy1_mt[kk+1::jj,.],sy2_mt[kk+1::jj,.],sx1_mt[kk+1::jj,.],sx2_mt[kk+1::jj,.],arg2.i12_mt[kk+1::jj,.])
			rhv[j,.] = rh0
			rhv2[kk+1::jj,.] = J(arg0.t0-j,1,1):*rh0
			if (log_it) {
				printf("{txt}  {txt}lag({res}%2.0f{txt}) = {res}%7.5f\n", j, rh0)
				displayflush()
			}
		}
		if (log_it) display("")
	}
	else if (ropt==0) {  // "unrestricted"
		if (log_it) printf("(unrestricted):\n\n")
		rhv = arg3.zero_rv
		for (j=1; j<=arg2.tr; j++) {
			rh0 = estrho(&fmin_rho_Brent(),sy1_mt[j,.],sy2_mt[j,.],sx1_mt[j,.],sx2_mt[j,.],arg2.i12_mt[j,.])
			rhv[j,.] = rh0
			if (log_it) {
				jj = comb[j,1]
				kk = comb[j,2]
				msg = sprintf("  {txt}rho[{res}%s{txt},{res}%s{txt}] = {res}%7.5f", tstr[1,jj], tstr[1,kk], rh0)
				display(msg)
				displayflush()
			}
			rhv2 = rhv
		}
		if (log_it) display("")
	}
	
	// correction terms
	psi1_mt = arg2.zero_rnm
	psi2_mt = arg2.zero_rnm
	for (j=1; j<=arg2.t1; j++) {
		k = j-1
		kk = k*(arg2.t1-(k-1)/2)
		jj = j*(arg2.t1-k/2)
		rh = rhv2[kk+1::jj,.]
		zh1 = dff1(arg0.zhs_mt,j)
		zh2 = dff0(arg0.zhs_mt,j)
		hh1 = gethh(zh1,zh2,rh)
		hh2 = gethh(zh2,zh1,rh)
		psi1_mt[kk+1::jj,.] = hh1:+rh:*hh2
		psi2_mt[kk+1::jj,.] = hh2:+rh:*hh1
	}
	arg3.psiv = vec(psi1_mt):*arg3.ind_psi1:+vec(psi2_mt):*arg3.ind_psi2
	
	// weights
	arg4.wt0 = colsum(arg1.s_mt)
	wt = editmissing(1:/sqrt(arg4.wt0),0)
	arg3.pdw_mt = wt:*pds_mt
	pdwv = vec(arg4.wt0:*pds_mt)
	
	// export to file to save time; to be loaded in delta method part
	//------------------------------------------------------------------
	fh = fopen(tmpfile, "rw")
	fputmatrix(fh, (arg3.pdxv,arg3.psiv,arg3.ind_psi1,arg3.ind_psi2))
	fclose(fh)
	//------------------------------------------------------------------
	
	// mata to stata
	st_numscalar("e(N_g)",arg1.n0)
	st_numscalar("e(T)",arg0.t0)
	st_numscalar("e(N_selected)",ssum)
	st_matrix("e(comb)",comb)
	st_matrix("e(b_r)",rhv')
	st_matrix("i12_mt",arg2.i12_mt)
	st_matrix("pdy_mt",arg3.pdy_mt)
	st_matrix("pdw_mt",arg3.pdw_mt)
	st_matrix("msx",msx)
	
	// transformed data for step 3
	cid0 = select(editmissing(st_data(.,vcid),0):*used1,used3)
	kcid = cols(cid0)
	cidv = J(arg2.tr*arg1.n0,kcid,0)
	for (i=1; i<=kcid; i++) {
		cid_mt = colshape(cid0[.,i],arg0.t0)'
		cidind = (cid_mt:!=0):*(arg0.used4_mt)
		cidv[.,i] = vec(editmissing(colsum(cid_mt):/colsum(cidind),0)#arg3.one_rv)
	}
	datamat = (pdsv,pdwv,pdyv,arg3.pdxv,arg3.psiv,cidv)
	fids = J(1,kcid,"")
	for (i=1; i<=kcid; i++) {
		fids[i] = "fid" + strofreal(i)
	}
	fxxs = J(1,kxv0,"")
	for (i=1; i<=kxv0; i++) {
		fxxs[i] = "fxx" + strofreal(i)
	}
	crts = J(1,arg3.kpsi,"")
	for (j=1; j<=arg3.kpsi; j++) {
		crts[j] = "crt" + strofreal(j)
	}
	stata("qui clear")
	stata("qui set obs " + strofreal(arg1.n0*arg2.tr))
	(void) st_addvar("double",("pdsv","pdwv","pdyv",fxxs,crts,fids))
	st_store(.,("pdsv","pdwv","pdyv",fxxs,crts,fids),datamat)
}

void xtselfe_delta(string scalar nn, string scalar tt, string scalar t_all, string scalar stouse, ///
	string scalar sv, string scalar zhs, string scalar hetcorr, string scalar zz, string scalar pihs, ///
	string scalar pihsih, string scalar rhv, string scalar bhv, string scalar ue_u, string scalar epsopt, ///
	string scalar pdv_file) {
	
	// structures
	struct f_arg0 scalar arg0
	struct f_arg1 scalar arg1
	struct f_arg2 scalar arg2
	struct f_arg3 scalar arg3
	struct f_arg4 scalar arg4
	
	// declarations for variance-covariance matrix (vcm)
	pointer matrix makebigh, makebigv
	real scalar j, k, j0, j1, tall, kxv0, n0_up, t0_up, hopt, eps, lb, ub, low, high
	real rowvector used2_n
	real colvector used1, used2_t, used3, xi1, xi2, xi3, xi30, xi12, xi130, xi13, ///
		indxi130, pos, pdwv2, pdxid
	real matrix used1_mt, ue0_mt, msx, pi_ih, eye_t, eps_mt, h21, est_d30, h3a1, ///
		h3a2, h3ba, ih11, ih22, ih3aa, pdxx0, pdxx1, pdxx, theta_ih, ih3bb, ih21, ///
		ih3a2, ih3a1, ih3bc, ih3b1, ih3b2, ih3ba, ih31, ih32, ih33, est_c0, vh11, ///
		vh21, vh31, vh12, vh22, vh32, vh13, vh23, vh33, vc3
	
	// declarations for import
	real scalar fh
	real matrix pdv_mat
	
	// read from pdv_file
	//------------------------------------------------------------------
	fh = fopen(pdv_file, "r")
	pdv_mat = fgetmatrix(fh)
	fclose(fh)
	//------------------------------------------------------------------
	
	// variable setup for vcm
	arg1.n0 = st_numscalar(nn)
	arg0.t0 = st_numscalar(tt)
	tall = st_numscalar(t_all)
	used1 = editmissing(st_data(.,stouse),0)
	used1_mt = colshape(used1,tall)'
	used2_n = colsum(used1_mt):!=0
	n0_up = rowsum(used2_n)
	used2_t = rowsum(used1_mt):!=0
	t0_up = colsum(used2_t)
	used3 = used2_n'#used2_t
	arg0.used4_mt = select(select(used1_mt,used2_t),used2_n)
	arg1.s_mt = select(select(colshape(editmissing(st_data(.,sv),0):*used1,tall)',used2_t),used2_n)
	arg0.zv0 = select(editmissing(st_data(.,zz),0):*used1,used3)
	arg0.zhs_mt = select(select(colshape(editmissing(st_data(.,zhs),0):*used1,tall)',used2_t),used2_n)
	ue0_mt = select(select(colshape(editmissing(st_data(.,ue_u),0):*used1,tall)',used2_t),used2_n)
	arg4.ue0 = colsum(ue0_mt)
	eps = st_numscalar(epsopt)
	xi1 = vec(st_matrix(pihs)')
	xi2 = vec(st_matrix(rhv))
	xi3 = vec(st_matrix(bhv))
	arg3.kxi30 = rows(xi3)-1
	arg3.kxi3 = arg3.kxi30+1
	xi30 = xi3[1::arg3.kxi30,.]
	xi12 = xi1\xi2
	xi130 = xi12\xi30
	xi13 = xi12\xi3
	arg0.kxi0 = cols(arg0.zv0)+1
	arg1.kxi1 = rows(xi1)
	arg2.kxi2 = rows(xi2)
	arg2.kxi12 = arg1.kxi1+arg2.kxi2
	arg3.kxi130 = arg2.kxi12+arg3.kxi30
	arg4.kxi13 = arg3.kxi130+1
	indxi130 = 1:-(xi130:==0)
	arg2.i12_mt = st_matrix("i12_mt")
	arg3.pdy_mt = st_matrix("pdy_mt")
	arg3.pdw_mt = st_matrix("pdw_mt")
	arg4.wt0 = colsum(arg1.s_mt)
	msx = st_matrix("msx")
	pi_ih = st_matrix(pihsih)
	
	// df in x
	hopt = st_numscalar(hetcorr)
	if (hopt==1) {
		arg3.kpsi = arg0.t0
	}
	else {
		arg3.kpsi = 1
	}
	kxv0 = arg3.kxi30-arg3.kpsi
	arg3.pdxv = pdv_mat[.,1::kxv0]
	arg3.psiv = pdv_mat[.,kxv0+1::arg3.kxi30]
	arg3.ind_psi1 = pdv_mat[.,arg3.kxi3::arg3.kxi30+arg3.kpsi]
	arg3.ind_psi2 = pdv_mat[.,arg3.kxi30+arg3.kpsi+1::cols(pdv_mat)]
	
	// update n and T
	if (arg1.n0!=n0_up) {
		arg1.n0 = n0_up
	}
	if (arg0.t0!=t0_up) {
		arg0.t0 = t0_up
	}
	arg2.t1 = arg0.t0-1
	arg2.tr = arg0.t0*arg2.t1/2
	arg0.one_nv = J(arg1.n0,1,1)
	arg3.one_rv = J(arg2.tr,1,1)
	arg3.zero_rv = J(arg2.tr,1,0)
	arg2.zero_rnm = J(arg2.tr,arg1.n0,0)
	arg1.one_tv = J(arg0.t0,1,1)
	eye_t = I(arg0.t0)
	arg0.eye_nttm = arg0.one_nv#eye_t
	arg0.zero_ntm = J(arg1.n0,arg0.t0,0)
	arg1.zero_k1nm = J(arg1.kxi1,arg1.n0,0)
	arg3.zero_k30nm = J(arg3.kxi30,arg1.n0,0)
	
	// redefine eps
	lb = -1+1e-9
	ub = 1-1e-9
	eps_mt = J(arg3.kxi130,2,1):*eps
	for (j=arg1.kxi1+1; j<=arg2.kxi12; j++) {
		k = xi130[j,.]
		low = k-eps
		high = k+eps
		if (low<=-1) {
			eps_mt[j,1] = k-lb  // b - eps = lb
		}
		if (high>=1) {
			eps_mt[j,2] = ub-k  // b + eps = ub
		}
	}
	eps_mt = eps_mt:*indxi130  // 0 for omitted variables
	
	// numerical differentiation
	h21 = num_dff(&gg2(),xi12,arg1.kxi1,eps_mt,arg0,arg1,arg2,arg3)
	est_d30 = num_dff(&gg30(),xi130,arg2.kxi12,eps_mt,arg0,arg1,arg2,arg3)
	h3a1 = est_d30[.,1::arg1.kxi1]
	h3a2 = est_d30[.,arg1.kxi1+1::arg2.kxi12]
	
	// h3ba (for _cons; = h43)
	h3ba = (-rowsum(msx)',J(1,arg3.kpsi,0))
	
	// ih11
	if (arg1.kxi1==arg0.kxi0) {  // "pool"
		ih11 = pi_ih
	}
	else {
		ih11 = J(arg1.kxi1,arg1.kxi1,0)
		for (j=1; j<=arg0.t0; j++) {
			j0 = (j-1)*arg0.kxi0+1
			j1 = j*arg0.kxi0
			ih11[j0::j1,j0::j1] = pi_ih[j0::j1,.]
		}
	}
	
	// ih22
	ih22 = get_rho_ih(xi2,arg0.zhs_mt,arg1,arg2)
	
	// ih3aa (= ih33)
	pos = select((1::arg3.kxi30),indxi130[arg2.kxi12+1::arg3.kxi130]:==1)
	ih3aa = J(arg3.kxi30,arg3.kxi30,0)
	pdwv2 = vec(arg3.pdw_mt)  // pdwv2 = T^{-1/2}
	pdxx0 = (arg3.pdxv,arg3.psiv)
	pdxid = (pdwv2:>0):*rowsum(pdxx0:!=.)
	pdxx1 = select(pdxx0:*pdwv2,pdxid)
	pdxx = pdxx1[.,pos]
	theta_ih = -luinv(cross(pdxx,pdxx))
	ih3aa[pos,pos] = theta_ih
	
	// ih3bb (= ih44)
	ih3bb = -1/rowsum(arg4.wt0)
	
	// other inverse matrices of H
	ih21 = -ih22*h21*ih11
	ih3a2 = -ih3aa*h3a2*ih22
	ih3a1 = -ih3aa*(h3a1*ih11:+h3a2*ih21)
	ih3bc = -ih3bb*h3ba
	ih3b1 = ih3bc*ih3a1
	ih3b2 = ih3bc*ih3a2
	ih3ba = ih3bc*ih3aa
	
	// construct ih31, ih32, ih33 (including _cons)
	ih31 = ih3a1\ih3b1
	ih32 = ih3a2\ih3b2
	ih33 = (ih3aa,J(arg3.kxi30,1,0))\(ih3ba,ih3bb)
	
	// bread
	makebigh = J(arg4.kxi13,arg4.kxi13,NULL)
	makebigh[3,1] = &ih31
	makebigh[3,2] = &ih32
	makebigh[3,3] = &ih33
	
	// meat
	est_c0 = num_cov(xi13,arg0,arg1,arg2,arg3,arg4)
	vh11 = est_c0[1::arg1.kxi1,1::arg1.kxi1]
	vh21 = est_c0[arg1.kxi1+1::arg2.kxi12,1::arg1.kxi1]
	vh31 = est_c0[arg2.kxi12+1::arg4.kxi13,1::arg1.kxi1]
	vh12 = est_c0[1::arg1.kxi1,arg1.kxi1+1::arg2.kxi12]
	vh22 = est_c0[arg1.kxi1+1::arg2.kxi12,arg1.kxi1+1::arg2.kxi12]
	vh32 = est_c0[arg2.kxi12+1::arg4.kxi13,arg1.kxi1+1::arg2.kxi12]
	vh13 = est_c0[1::arg1.kxi1,arg2.kxi12+1::arg4.kxi13]
	vh23 = est_c0[arg1.kxi1+1::arg2.kxi12,arg2.kxi12+1::arg4.kxi13]
	vh33 = est_c0[arg2.kxi12+1::arg4.kxi13,arg2.kxi12+1::arg4.kxi13]
	
	makebigv = J(arg4.kxi13,arg4.kxi13,NULL)
	makebigv[1,1] = &vh11
	makebigv[2,1] = &vh21
	makebigv[3,1] = &vh31
	makebigv[1,2] = &vh12
	makebigv[2,2] = &vh22
	makebigv[3,2] = &vh32
	makebigv[1,3] = &vh13
	makebigv[2,3] = &vh23
	makebigv[3,3] = &vh33
	
	// vc3
	vc3 = getvcov(makebigh,makebigv,3,arg3.kxi3)
	st_matrix("e(V_delta)",vc3)
}

mata set matastrict off
end

exit
