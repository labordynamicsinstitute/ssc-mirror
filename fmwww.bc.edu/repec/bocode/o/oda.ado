*! 2.1.0 Ariel Linden 03sep2026 // renamed command from oda2 to oda
*! 2.0.0 Ariel Linden 03sep2026 // rewrote ODA to be a self-contained program, rather than calling oda.exe
*! 1.2.2 Ariel Linden 01apr2022 // fixed `touse' to ensure it is applied everywhere relevant
*! 1.2.1 Ariel Linden 09mar2020 // fixed bug in listing output when "gen" is specified
*! 1.2.0 Ariel Linden 30jan2020 // fixed bug in "if strpos( v1 , "IF ")"
								// added error checking of "store" pathname for spaces
								// added Sidak adjustment option
								// added return scalars for P values for permutation and LOO
								// fixed error checking in "direction"

*! 1.0.0 Ariel Linden 29nov2019 
program define odam_attrlabel, rclass
	args varname vallist
	local out ""
	foreach v of local vallist {
		local lv : label (`varname') `v'
		if "`out'" == "" local out "`lv'"
		else             local out "`out', `lv'"
	}
	return local list "`out'"
end

program define odam_parse_tiebreak, rclass
	args optname raw binary classname chigh genname

	if "`raw'" == "" exit 0
	gettoken kw val : raw
	local kw = lower("`kw'")
	local val = trim("`val'")

	if inlist("`kw'","distance","meansens","samplerep","balanced","maxsens","genmean","random") {
		if "`val'" != "" {
			di as err "`optname'(`raw') -- `kw' does not take a value"
			exit 198
		}
		return local crit "`kw'"
	}
	else if "`kw'" == "sens" {
		if "`val'" == "" {
			di as err "`optname'(sens) requires a value of `classname'"
			exit 198
		}
		qui count if `classname' == `val'
		if r(N) == 0 {
			di as err "`optname'(sens `val') -- `val' is not an observed value of `classname'"
			exit 198
		}
		if `binary' & `val' == `chigh' return local crit "sens_hi"
		else if `binary'               return local crit "sens_lo"
		else                            return local crit "sens"
	}
	else if "`kw'" == "gensens" {
		if "`genname'" == "" {
			di as err "`optname'(gensens) requires gen() to be specified"
			exit 198
		}
		if "`val'" == "" {
			di as err "`optname'(gensens) requires a value of `genname'"
			exit 198
		}
		qui count if `genname' == `val'
		if r(N) == 0 {
			di as err "`optname'(gensens `val') -- `val' is not an observed value of `genname'"
			exit 198
		}
		return local crit "gensens"
		return local val "`val'"
	}
	else {
		di as err "`optname'(`raw') is not a recognized tie-break option"
		exit 198
	}
end

program define oda, rclass
	version 14.0

	syntax varlist(min=2 max=2 numeric) [if] [in] , [ ///
		STOre(string) ///
		TRAINREPS(string) ///
		LOOREPS(string) ///
		DOTS ///
		SIDAK(numlist max=1 integer) ///
		LOO ///
		CAT ///
		WT(varname numeric) ///
		MISSing(numlist max=1 integer) ///
		DEGen ///
		DIRection(string) ///
		PRImary(string) ///
		SECondary(string) ///
		NOPRIORS ///
		SEED(string) ///
		NAME(string) ///
		GEN(varname numeric) ///
		CI ///
		CIREPS(string) ///
		CILEVEL(string) ///
		CROSS(string) ///
		]

	global oda_lastfit_ok 0

	qui {
		preserve
		tokenize `varlist'
		local class `1'
		local attr `2'

		if "`wt'" != "" & ("`wt'" == "`class'" | "`wt'" == "`attr'") {
			di as err "wt() cannot be the same variable as `class' or `attr'"
			exit 198
		}
		if "`sidak'" != "" & "`trainreps'" == "" {
			di as err "trainreps() must be specified with sidak()"
			exit 198
		}
		if "`looreps'" != "" & "`loo'" == "" {
			di as err "loo must be specified with looreps()"
			exit 198
		}

		marksample touse
		count if `touse'
		if r(N) == 0 error 2000
		keep if `touse'

		if "`missing'" != "" {
			local _misscond "`class' == `missing' | `attr' == `missing'"
			if "`wt'"  != "" local _misscond "`_misscond' | `wt' == `missing'"
			if "`gen'" != "" local _misscond "`_misscond' | `gen' == `missing'"
			drop if `_misscond'
		}

		local crossflag = 0
		local crosstrain = .
		if "`cross'" != "" {
			local crossflag = 1
			if "`gen'" != "" {
				di as err "gen() cannot be combined with cross()"
				exit 198
			}
			local crosstext = trim(`"`cross'"')
			tokenize `"`crosstext'"', parse(",")
			local crossvar = trim("`1'")
			local traintok ""
			local holdtok ""
			if "`2'" == "," {
				local traintok = trim("`3'")
				if "`4'" == "," {
					local holdtok = trim("`5'")
				}
			}
			capture confirm numeric variable `crossvar'
			if _rc {
				di as err "cross(): `crossvar' not found as a numeric variable"
				exit 111
			}
			if "`crossvar'" == "`class'" | "`crossvar'" == "`attr'" | ("`wt'" != "" & "`crossvar'" == "`wt'") {
				di as err "cross()'s sample-identifier variable cannot be the same as `class', `attr', or wt()"
				exit 198
			}
			qui levelsof `crossvar', local(crosslevels)
			if `: word count `crosslevels'' < 2 {
								di as err ///
					"cross(): `crossvar' has fewer than 2 distinct values in the estimation sample -- need at least one training id and one holdout id"
				exit 198
			}
			if "`traintok'" == "" local crosstrain = real(word("`crosslevels'",1))
			else {
				local crosstrain = real("`traintok'")
				if `crosstrain' == . {
					di as err "cross(): the training id must be a number"
					exit 198
				}
				local trainok = 0
				foreach v of local crosslevels {
					if `v' == `crosstrain' local trainok = 1
				}
				if !`trainok' {
					di as err "cross(): training id `crosstrain' does not appear in `crossvar'"
					exit 198
				}
			}
			if "`holdtok'" == "" {
				local crossholdlist ""
				foreach v of local crosslevels {
					if `v' != `crosstrain' local crossholdlist "`crossholdlist' `v'"
				}
				local crossholdlist = trim("`crossholdlist'")
			}
			else {
				qui numlist "`holdtok'"
				local crossholdlist = r(numlist)
				foreach v of local crossholdlist {
					local holdok = 0
					foreach u of local crosslevels {
						if `u' == `v' local holdok = 1
					}
					if !`holdok' {
						di as err "cross(): holdout id `v' does not appear in `crossvar'"
						exit 198
					}
					if `v' == `crosstrain' {
						di as err "cross(): holdout id `v' is the same as the training id"
						exit 198
					}
				}
			}
			if "`crossholdlist'" == "" {
				di as err "cross(): no holdout ids to evaluate"
				exit 198
			}
			local crosskeeplist "`crosstrain' `crossholdlist'"
			gen byte __crosskeep = 0
			foreach v of local crosskeeplist {
				qui replace __crosskeep = 1 if `crossvar' == `v'
			}
			qui keep if __crosskeep
			drop __crosskeep
			local gen "`crossvar'"
		}

		tab `class'
		local Klev = r(r)
		if `Klev' < 2 {
			di as err " `class' must have at least 2 levels"
			exit 198
		}
		local multiclass = (`Klev' > 2)

		if "`gen'" != "" & ("`gen'" == "`class'" | "`gen'" == "`attr'") {
			di as err "gen() cannot be the same variable as `class' or `attr'"
			exit 198
		}

		if `multiclass' {
			if "`direction'" != "" & "`cat'" != "" {
								di as err ///
					"direction() is not supported together with cat -- a categorical attribute has no ordering for a class sequence to run along"
				exit 198
			}
			if "`primary'" != "" | "`secondary'" != "" {
				if "`primary'" != "" {
					odam_parse_tiebreak primary "`primary'" 0 `class' 0 "`gen'"
					local primary "`r(crit)'"
				}
				if "`secondary'" != "" {
					odam_parse_tiebreak secondary "`secondary'" 0 `class' 0 "`gen'"
					local secondary "`r(crit)'"
				}
			}
		}
		if "`cat'" != "" {
			tab `attr'
			if r(r) < 2 {
				di as err " `attr' must have at least 2 categories when cat is specified"
				exit 198
			}
		}
		local primarygenval ""
		local secondarygenval ""
		if !`multiclass' {
			levelsof `class', local(clevs)
			local clow  : word 1 of `clevs'
			local chigh : word 2 of `clevs'

			if "`primary'" != "" {
				odam_parse_tiebreak primary "`primary'" 1 `class' `chigh' "`gen'"
				local primary "`r(crit)'"
				local primarygenval "`r(val)'"
			}
			if "`secondary'" != "" {
				odam_parse_tiebreak secondary "`secondary'" 1 `class' `chigh' "`gen'"
				local secondary "`r(crit)'"
				local secondarygenval "`r(val)'"
			}
		}

		if "`gen'" != "" & !`multiclass' {
			qui levelsof `gen', local(_genlevs)
			foreach _gv of local _genlevs {
				qui count if `gen' == `_gv' & `class' == `chigh'
				local _nhigh = r(N)
				qui count if `gen' == `_gv' & `class' == `clow'
				local _nlow = r(N)
				if `_nhigh' == 0 | `_nlow' == 0 {
					di as err "Each GEN group must contain at least one observation from each class"
					exit 198
				}
			}
		}

		local ordvals ""
		if `multiclass' & "`direction'" != "" {
			local dspacepos = strpos("`direction'"," ")
			if `dspacepos' == 0 {
								di as err ///
					"direction() for a multi-category classvar needs <, > or lt, gt followed by a space-separated list of all `Klev' class values, e.g. direction(< 2 3 1 4 -99 5)"
				exit 198
			}
			local dtag  = substr("`direction'",1,`dspacepos'-1)
			local drest = substr("`direction'",`dspacepos'+1,.)
			if !inlist("`dtag'","<","lt",">","gt") {
				di as err "direction() must start with <, >, lt, or gt"
				exit 198
			}
			local ordn : word count `drest'
			if `ordn' != `Klev' {
								di as err ///
					"direction()'s class list has `ordn' values but `class' has `Klev' levels -- it must list every level exactly once"
				exit 198
			}
			levelsof `class', local(kclevs)
			local ordvals `drest'
			local ordcheck `ordvals'
			foreach v of local kclevs {
				local hit = 0
				local remaining ""
				foreach o of local ordcheck {
					if !`hit' & real("`o'") == `v' {
						local hit = 1
					}
					else {
						local remaining `remaining' `o'
					}
				}
				if !`hit' {
										di as err ///
						"direction()'s class list is missing level `v' of `class' (or lists it more than once)"
					exit 198
				}
				local ordcheck `remaining'
			}
			if "`ordcheck'" != "" {
				local extra : word 1 of `ordcheck'
				di as err "direction()'s class list contains `extra', which is not a level of `class'"
				exit 198
			}
			if inlist("`dtag'",">","gt") {
				local revvals ""
				foreach v of local ordvals {
					local revvals `v' `revvals'
				}
				local ordvals `revvals'
			}
		}

		local dirconstraint 0
		if "`direction'" != "" & !`multiclass' {
			local dtag = substr("`direction'",1,strpos("`direction'"," ")-1)
			if inlist("`dtag'","<","lt") local dirconstraint = -1
			else if inlist("`dtag'",">","gt") local dirconstraint = 1
			else {
				di as err "direction() must start with <, >, lt, or gt"
				exit 198
			}
		}

		if "`primary'" == "" local primary "maxsens"
		if "`nopriors'" != "" & "`primary'" == "maxsens" local primary "meansens"
		if "`secondary'" == "" local secondary "samplerep"
		local priorsflag = ("`nopriors'" == "")
		local degenflag  = ("`degen'" != "")

		if "`seed'" != "" set seed `seed'

		if !`multiclass' gen double __class01 = (`class' == `chigh')
		gen double __classK = `class'
		gen double __attr   = `attr'
		if "`wt'" != "" gen double __wt = `wt'
		else gen double __wt = 1

		gen byte __istrain = 1
		if `crossflag' qui replace __istrain = (`crossvar' == `crosstrain')

		local predvar ""
		local genpredvar ""
		local genloopredvar ""
		if "`gen'" != "" {
			gen double __genpredtrain = .
			local predvar "__genpredtrain"
			local genpredvar "`predvar'"
			if "`loo'" != "" {
				gen double __genpredloo = .
				local genloopredvar "__genpredloo"
			}
		}

		local niter  = cond("`trainreps'"=="", 0, real("`trainreps'"))
		local nloo   = cond("`looreps'"=="",   0, real("`looreps'"))
		local dotsflag = ("`dots'" != "")

		local ciflag = ("`ci'" != "")
		if `ciflag' {

			local cireps = cond("`cireps'"=="", 200, real("`cireps'"))
			if `cireps'==. | `cireps' < 2 | `cireps' != int(`cireps') {
				di as err "cireps() must be a whole number of at least 2"
				exit 198
			}
			local cilevel = cond("`cilevel'"=="", 95, real("`cilevel'"))
			if `cilevel'==. | `cilevel' <= 0 | `cilevel' >= 100 {
				di as err "cilevel() must be strictly between 0 and 100"
				exit 198
			}
			local civaltxt = strtrim(string(`cilevel',"%9.4g"))
			local cihdr "[`civaltxt'% conf. interval]"
			local cihdrlen = length("`cihdr'")
			local cifieldw = max(22, `cihdrlen')
			local cihdrL = max(0, floor((`cifieldw'-`cihdrlen')/2))
			local cihdrR = max(0, `cifieldw'-`cihdrlen'-`cihdrL')
			local boothdrL = floor((`cifieldw'-9)/2)
			local boothdrR = `cifieldw'-9-`boothdrL'
			local cihdrLsp : display _dup(`cihdrL') " "
			local cihdrRsp : display _dup(`cihdrR') " "
			local boothdrLsp : display _dup(`boothdrL') " "
			local boothdrRsp : display _dup(`boothdrR') " "
			local cihdrdash : display _dup(`cihdrlen') "-"
			local cidataL = 2 + `cihdrL'
			local cimidpad = max(0, `cihdrlen' - 17)
			local cidataR = `cihdrR'
			local cidataLsp : display _dup(`cidataL') " "
			local cidataRsp : display _dup(`cidataR') " "
			local cimidpadsp : display _dup(`cimidpad') " "
			local citotalw_noloo = 24 + 8 + 2 + `cifieldw'
			local citotalw_loo   = `citotalw_noloo' + 2 + 8 + 2 + `cifieldw'
			local citotalw_loo3  = `citotalw_loo' + 2 + 8 + 2 + `cifieldw'
		}
		else {
			local cireps = 0
			local cilevel = 95
			local cihdr ""
			local cihdrL = 0
			local cihdrR = 0
			local boothdrL = 0
			local boothdrR = 0
			local cihdrLsp ""
			local cihdrRsp ""
			local boothdrLsp ""
			local boothdrRsp ""
			local cihdrdash ""
			local cidataL = 0
			local cimidpad = 0
			local cidataR = 0
			local cidataLsp ""
			local cidataRsp ""
			local cimidpadsp ""
			local citotalw_noloo = 0
			local citotalw_loo = 0
			local citotalw_loo3 = 0
		}
	}

	if !`multiclass' {
		local gvar_gen = cond(`crossflag', "", "`gen'")
		local primarygenvalnum = cond("`primarygenval'"=="",".","`primarygenval'")
		local secondarygenvalnum = cond("`secondarygenval'"=="",".","`secondarygenval'")
		mata: oda_driver("__class01","__attr","__wt","__istrain", ///
			`priorsflag', `degenflag', `dirconstraint', ///
			"`primary'", "`secondary'", `niter', ("`loo'"!=""), `nloo', ("`cat'"!=""), `dotsflag', ("`wt'"!=""), "`predvar'", "`genloopredvar'", ///
			"`gvar_gen'", `primarygenvalnum', `secondarygenvalnum')
	}
	else {
		mata: odaK_driver("__classK","__attr","__wt","__istrain", ///
			`priorsflag', `degenflag', `niter', ("`loo'"!=""), `nloo', `dotsflag', ("`cat'"!=""), "`ordvals'", "`predvar'", "`primary'", "`genloopredvar'", "`secondary'")
	}
	if `dotsflag' & (`niter'>0 | `nloo'>0 | "`loo'"!="") & !`ciflag' di _n

	local fitfailed = 0
	if `multiclass' {
		if r_K_nseg == 0 local fitfailed = 1
	}

	if "`gen'" != "" & !`fitfailed' {
		if !`multiclass' {
			qui mata: st_matrix("r_gen_breakdown", ///
				odam_gen_breakdown(st_data(.,"`gen'"), st_data(.,"__class01"), ///
					st_data(.,"`genpredvar'"), ///
					("`genloopredvar'"!="" ? st_data(.,"`genloopredvar'") : J(st_nobs(),1,.)), ///
					("`loo'"!=""), st_data(.,"__wt")))
			local ngen = rowsof(r_gen_breakdown)
		}
		else {
			qui mata: odamK_gen_breakdown(st_data(.,"`gen'"), st_data(.,"__classK"), ///
				st_matrix("r_K_cvals"), st_data(.,"`genpredvar'"), ///
				("`genloopredvar'"!="" ? st_data(.,"`genloopredvar'") : J(st_nobs(),1,.)), ///
				("`loo'"!=""), st_data(.,"__wt"))
			local ngen = rowsof(r_K_gen_breakdown)
		}
	}

	if `crossflag' & `niter' > 0 & !`fitfailed' {
		local crosssidak = 1 + `: word count `crossholdlist''
		if "`sidak'" != "" local crosssidak = `sidak'
		if !`multiclass' {
			mata: st_matrix("r_cross_sig", ///
				odam_cross_sigtest(st_data(.,"`gen'"), st_data(.,"__class01"), ///
					st_data(.,"`genpredvar'"), (0\1), `niter', `dotsflag'))
		}
		else {
			mata: st_matrix("r_cross_sig", ///
				odam_cross_sigtest(st_data(.,"`gen'"), st_data(.,"__classK"), ///
					st_data(.,"`genpredvar'"), st_matrix("r_K_cvals"), `niter', `dotsflag'))
		}
		local ncrosssig = rowsof(r_cross_sig)
	}

	if `ciflag' & !`fitfailed' {
		if !`multiclass' {
			mata: odam_ci_driver("__class01","__attr","__wt","__istrain", ///
				`priorsflag', `degenflag', `dirconstraint', ///
				"`primary'", "`secondary'", ("`wt'"!=""), `cireps', ("`loo'"!=""), `cilevel', `dotsflag', "`gen'", ("`cat'"!=""))
		}
		else {
			mata: odamK_ci_driver("__classK","__attr","__wt","__istrain", ///
				`priorsflag', `degenflag', `cireps', ("`loo'"!=""), "`ordvals'", "`primary'", `cilevel', `dotsflag', ("`cat'"!=""), "`gen'", "`secondary'")
		}
	}

	if !`fitfailed' {
		qui {
			global oda_lastfit_class "`class'"
			global oda_lastfit_attr  "`attr'"
			global oda_lastfit_multiclass = `multiclass'
			global oda_lastfit_cat = ("`cat'" != "")
			if !`multiclass' {
				global oda_lastfit_clow  = `clow'
				global oda_lastfit_chigh = `chigh'
			}
			global oda_lastfit_ok 1
		}
	}

	qui {
		return scalar N            = r_N
		return scalar K            = `Klev'
		return scalar ess_train    = r_ess_train
		return scalar overall_acc  = r_overall_acc
		return scalar ess_pv       = r_ess_pv
		return scalar ess_total    = r_ess_total
		if !`multiclass' {
			return scalar cutpoint = r_cutpoint
			return scalar direction = r_direction
			return scalar sens     = r_sens
			return scalar spec     = r_spec
			return scalar pv0      = r_pv0
			return scalar pv1      = r_pv1
			if "`wt'" != "" {
				return scalar ess_pac_wtd   = r_ess_pac_wtd
				return scalar overall_acc_wtd = r_overall_acc_wtd
				return scalar pac0_wtd      = r_pac0_wtd
				return scalar pac1_wtd      = r_pac1_wtd
				return scalar pv0_wtd       = r_pv0_wtd
				return scalar pv1_wtd       = r_pv1_wtd
				return scalar ess_pv_wtd    = r_ess_pv_wtd
				return scalar ess_total_wtd = r_ess_total_wtd
			}
		}
		else if "`wt'" != "" {
			return scalar ess_train_wtd   = r_ess_train_wtd
			return scalar overall_acc_wtd = r_overall_acc_wtd
			return scalar ess_pv_wtd      = r_ess_pv_wtd
			return scalar ess_total_wtd   = r_ess_total_wtd
		}
		if `niter' > 0 {
			return scalar est_P = r_est_P
			if "`sidak'" != "" {
				local adjP = 1-(1-r_est_P)^`sidak'
				return scalar est_adjP = `adjP'
			}
		}
		if "`loo'" != "" {
			return scalar ess_loo         = r_ess_loo
			return scalar overall_acc_loo = r_overall_acc_loo
			return scalar ess_pv_loo      = r_ess_pv_loo
			return scalar ess_total_loo   = r_ess_total_loo
			if !`multiclass' {
				return scalar sens_loo = r_sens_loo
				return scalar spec_loo = r_spec_loo
				return scalar pv0_loo  = r_pv0_loo
				return scalar pv1_loo  = r_pv1_loo
				return scalar est_P_LOO = r_est_P_LOO
				if "`sidak'" != "" {
					local adjLOO = 1-(1-r_est_P_LOO)^`sidak'
					return scalar est_adjP_LOO = `adjLOO'
				}
				if "`wt'" != "" {
					return scalar ess_pac_loo_wtd   = r_ess_pac_loo_wtd
					return scalar overall_acc_loo_wtd = r_overall_acc_loo_wtd
					return scalar pac0_loo_wtd      = r_pac0_loo_wtd
					return scalar pac1_loo_wtd      = r_pac1_loo_wtd
					return scalar pv0_loo_wtd       = r_pv0_loo_wtd
					return scalar pv1_loo_wtd       = r_pv1_loo_wtd
					return scalar ess_pv_loo_wtd    = r_ess_pv_loo_wtd
					return scalar ess_total_loo_wtd = r_ess_total_loo_wtd
				}
			}
			else {
				if "`wt'" != "" {
					return scalar ess_loo_wtd         = r_ess_loo_wtd
					return scalar overall_acc_loo_wtd = r_overall_acc_loo_wtd
					return scalar ess_pv_loo_wtd      = r_ess_pv_loo_wtd
					return scalar ess_total_loo_wtd   = r_ess_total_loo_wtd
				}
				if `nloo' > 0 {
					return scalar est_P_LOO = r_est_P_LOO
					if "`sidak'" != "" {
						local adjLOO = 1-(1-r_est_P_LOO)^`sidak'
						return scalar est_adjP_LOO = `adjLOO'
					}
				}
			}
		}
	}

	local CLASSU = upper("`class'")
	local ATTRU  = upper("`attr'")

	if `multiclass' {
		if r_K_nseg == 0 {
			di _n as err "No solution found for this problem"
			exit
		}
		local nseg = r_K_nseg
	}

	if !`multiclass' {
		local clow  : label (`class') `clow'
		local chigh : label (`class') `chigh'
	}

	if "`name'" != "" di _n as text "`name'"
	if "`store'" != "" {
		cap log close oda_store
		qui log using "`store'", text replace name(oda_store)
	}

	di _n as text "ODA model:"
	if !`multiclass' & "`cat'" == "" {
		local fcp = strtrim(string(r_cutpoint,"%12.6g"))
		local mhdr1 "`ATTRU' Range"
		local mhdr2 "Predicted `CLASSU'"
		local mrow1a "<= `fcp'"
		local mrow1b "> `fcp'"
		local mw1 = max(30, strlen("`mhdr1'"), strlen("`mrow1a'"), strlen("`mrow1b'"))
		local mw2 = max(18, strlen("`mhdr2'"), strlen("`clow'"), strlen("`chigh'"))
		local mtotw = `mw1' + 2 + `mw2'
		di as text "{hline `mtotw'}"
		di as text %-`mw1's "`mhdr1'" "  " %`mw2's "`mhdr2'"
		di as text "{hline `mtotw'}"
		if r_direction==1 {
			di as text %-`mw1's "`mrow1a'" "  " as result %`mw2's "`clow'"
			di as text %-`mw1's "`mrow1b'" "  " as result %`mw2's "`chigh'"
		}
		else {
			di as text %-`mw1's "`mrow1a'" "  " as result %`mw2's "`chigh'"
			di as text %-`mw1's "`mrow1b'" "  " as result %`mw2's "`clow'"
		}
		di as text "{hline `mtotw'}"
	}
	else if !`multiclass' & "`cat'" != "" {
		odam_attrlabel `attr' "$_oda_grp0"
		local grp0list "`r(list)'"
		odam_attrlabel `attr' "$_oda_grp1"
		local grp1list "`r(list)'"
		local mhdr1 "`ATTRU' Values"
		local mhdr2 "Predicted `CLASSU'"
		local mw1 = max(30, strlen("`mhdr1'"), strlen("`grp0list'"), strlen("`grp1list'"))
		local mw2 = max(18, strlen("`mhdr2'"), strlen("`clow'"), strlen("`chigh'"))
		local mtotw = `mw1' + 2 + `mw2'
		di as text "{hline `mtotw'}"
		di as text %-`mw1's "`mhdr1'" "  " %`mw2's "`mhdr2'"
		di as text "{hline `mtotw'}"
		di as text %-`mw1's "`grp0list'" "  " as result %`mw2's "`clow'"
		di as text %-`mw1's "`grp1list'" "  " as result %`mw2's "`chigh'"
		di as text "{hline `mtotw'}"
	}
	else if `multiclass' & "`cat'" == "" {
		local mhdr1 "`ATTRU' Range"
		local mhdr2 "Predicted `CLASSU'"
		local mw1 = max(30, strlen("`mhdr1'"))
		local mw2 = max(18, strlen("`mhdr2'"))
		forvalues s = 1/`nseg' {
			local labval = r_K_seglabels[`s',1]
			local lab`s' : label (`class') `labval'
			if `nseg' == 1 {
				local rng`s' = "all values"
			}
			else if `s' == 1 {
				local cp = strtrim(string(r_K_cps[1,1],"%12.6g"))
				local rng`s' = "<= `cp'"
			}
			else if `s' == `nseg' {
				local cp = strtrim(string(r_K_cps[`nseg'-1,1],"%12.6g"))
				local rng`s' = "> `cp'"
			}
			else {
				local cplo = strtrim(string(r_K_cps[`s'-1,1],"%12.6g"))
				local cphi = strtrim(string(r_K_cps[`s',1],"%12.6g"))
				local rng`s' = "(`cplo', `cphi']"
			}
			local mw1 = max(`mw1', strlen("`rng`s''"))
			local mw2 = max(`mw2', strlen("`lab`s''"))
		}
		local mtotw = `mw1' + 2 + `mw2'
		di as text "{hline `mtotw'}"
		di as text %-`mw1's "`mhdr1'" "  " %`mw2's "`mhdr2'"
		di as text "{hline `mtotw'}"
		forvalues s = 1/`nseg' {
			di as text %-`mw1's "`rng`s''" "  " as result %`mw2's "`lab`s''"
		}
		di as text "{hline `mtotw'}"
	}
	else {
		local mhdr1 "`ATTRU' Values"
		local mhdr2 "Predicted `CLASSU'"
		local mw1 = max(30, strlen("`mhdr1'"))
		local mw2 = max(18, strlen("`mhdr2'"))
		forvalues k = 1/`Klev' {
			local kkval = r_K_cvals[`k',1]
			local kk`k' : label (`class') `kkval'
			odam_attrlabel `attr' "${_oda_catgrpK`k'}"
			local glist`k' "`r(list)'"
			local mw1 = max(`mw1', strlen("`glist`k''"))
			local mw2 = max(`mw2', strlen("`kk`k''"))
		}
		local mtotw = `mw1' + 2 + `mw2'
		di as text "{hline `mtotw'}"
		di as text %-`mw1's "`mhdr1'" "  " %`mw2's "`mhdr2'"
		di as text "{hline `mtotw'}"
		forvalues k = 1/`Klev' {
			di as text %-`mw1's "`glist`k''" "  " as result %`mw2's "`kk`k''"
		}
		di as text "{hline `mtotw'}"
	}

	if !`crossflag' {
	di _n as text "Summary for Class `CLASSU'  Attribute `ATTRU'"

	if !`multiclass' {
		if "`loo'" != "" {
			if `ciflag' & !`fitfailed' {
				di as text "{hline `citotalw_loo'}"
								di as text %-24s "" %8s "" "  " "`boothdrLsp'" "Bootstrap" "`boothdrRsp'" "  " %8s "" "  " ///
					"`boothdrLsp'" "Bootstrap" "`boothdrRsp'"
								di as text %-24s "Performance Index" %8s "Train" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'" ///
					"  " %8s "LOO" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'"
				di as text "{hline `citotalw_loo'}"
			}
			else {
				di as text "{hline 42}"
				di as text %-24s "Performance Index" "   Train       LOO"
				di as text "{hline 42}"
			}
			if "`wt'" == "" {
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds[4,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[4,2] "%]" ///
						"`cidataRsp'" "  " %7.2f r_overall_acc_loo "%" "`cidataLsp'" "[" %6.2f r_ci_loo_bounds[4,1] ///
						"%" "`cimidpadsp'" " " %6.2f r_ci_loo_bounds[4,2] "%]" "`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f (r_spec*100) "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds[3,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[3,2] "%]" ///
						"`cidataRsp'" "  " %7.2f (r_spec_loo*100) "%" "`cidataLsp'" "[" %6.2f r_ci_loo_bounds[3,1] "%" ///
						"`cimidpadsp'" " " %6.2f r_ci_loo_bounds[3,2] "%]" "`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f (r_sens*100) "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds[2,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[2,2] "%]" ///
						"`cidataRsp'" "  " %7.2f (r_sens_loo*100) "%" "`cidataLsp'" "[" %6.2f r_ci_loo_bounds[2,1] "%" ///
						"`cimidpadsp'" " " %6.2f r_ci_loo_bounds[2,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_train "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds[1,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[1,2] "%]" ///
						"`cidataRsp'" "  " %7.2f r_ess_loo "%" "`cidataLsp'" "[" %6.2f r_ci_loo_bounds[1,1] "%" ///
						"`cimidpadsp'" " " %6.2f r_ci_loo_bounds[1,2] "%]" "`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f r_pv0 "%" "`cidataLsp'" "[" %6.2f ///
						r_ci_train_bounds[5,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[5,2] "%]" "`cidataRsp'" ///
						"  " %7.2f r_pv0_loo "%" "`cidataLsp'" "[" %6.2f r_ci_loo_bounds[5,1] "%" "`cimidpadsp'" " " ///
						%6.2f r_ci_loo_bounds[5,2] "%]" "`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f r_pv1 "%" "`cidataLsp'" "[" %6.2f ///
						r_ci_train_bounds[6,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[6,2] "%]" "`cidataRsp'" ///
						"  " %7.2f r_pv1_loo "%" "`cidataLsp'" "[" %6.2f r_ci_loo_bounds[6,1] "%" "`cimidpadsp'" " " ///
						%6.2f r_ci_loo_bounds[6,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds[7,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[7,2] "%]" ///
						"`cidataRsp'" "  " %7.2f r_ess_pv_loo "%" "`cidataLsp'" "[" %6.2f r_ci_loo_bounds[7,1] "%" ///
						"`cimidpadsp'" " " %6.2f r_ci_loo_bounds[7,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds[8,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[8,2] "%]" ///
						"`cidataRsp'" "  " %7.2f r_ess_total_loo "%" "`cidataLsp'" "[" %6.2f r_ci_loo_bounds[8,1] "%" ///
						"`cimidpadsp'" " " %6.2f r_ci_loo_bounds[8,2] "%]" "`cidataRsp'"
				}
				else {
										di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc "%  " %7.2f ///
						r_overall_acc_loo "%"
										di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f (r_spec*100) "%  " %7.2f ///
						(r_spec_loo*100) "%"
										di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f (r_sens*100) "%  " %7.2f ///
						(r_sens_loo*100) "%"
					di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_train "%  " %7.2f r_ess_loo "%"
					di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f r_pv0 "%  " %7.2f r_pv0_loo "%"
					di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f r_pv1 "%  " %7.2f r_pv1_loo "%"
					di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv "%  " %7.2f r_ess_pv_loo "%"
										di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total "%  " %7.2f ///
						r_ess_total_loo "%"
				}
			}
			else {
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc_wtd "%" ///
						"`cidataLsp'" "[" %6.2f r_ci_train_bounds_wtd[4,1] "%" "`cimidpadsp'" " " %6.2f ///
						r_ci_train_bounds_wtd[4,2] "%]" "`cidataRsp'" "  " %7.2f r_overall_acc_loo_wtd "%" ///
						"`cidataLsp'" "[" %6.2f r_ci_loo_bounds_wtd[4,1] "%" "`cimidpadsp'" " " %6.2f ///
						r_ci_loo_bounds_wtd[4,2] "%]" "`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f (r_pac0_wtd*100) "%" ///
						"`cidataLsp'" "[" %6.2f r_ci_train_bounds_wtd[3,1] "%" "`cimidpadsp'" " " %6.2f ///
						r_ci_train_bounds_wtd[3,2] "%]" "`cidataRsp'" "  " %7.2f (r_pac0_loo_wtd*100) "%" ///
						"`cidataLsp'" "[" %6.2f r_ci_loo_bounds_wtd[3,1] "%" "`cimidpadsp'" " " %6.2f ///
						r_ci_loo_bounds_wtd[3,2] "%]" "`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f (r_pac1_wtd*100) "%" ///
						"`cidataLsp'" "[" %6.2f r_ci_train_bounds_wtd[2,1] "%" "`cimidpadsp'" " " %6.2f ///
						r_ci_train_bounds_wtd[2,2] "%]" "`cidataRsp'" "  " %7.2f (r_pac1_loo_wtd*100) "%" ///
						"`cidataLsp'" "[" %6.2f r_ci_loo_bounds_wtd[2,1] "%" "`cimidpadsp'" " " %6.2f ///
						r_ci_loo_bounds_wtd[2,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_pac_wtd "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds_wtd[1,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[1,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_ess_pac_loo_wtd "%" "`cidataLsp'" "[" %6.2f ///
						r_ci_loo_bounds_wtd[1,1] "%" "`cimidpadsp'" " " %6.2f r_ci_loo_bounds_wtd[1,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f r_pv0_wtd "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds_wtd[5,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[5,2] "%]" ///
						"`cidataRsp'" "  " %7.2f r_pv0_loo_wtd "%" "`cidataLsp'" "[" %6.2f r_ci_loo_bounds_wtd[5,1] ///
						"%" "`cimidpadsp'" " " %6.2f r_ci_loo_bounds_wtd[5,2] "%]" "`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f r_pv1_wtd "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds_wtd[6,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[6,2] "%]" ///
						"`cidataRsp'" "  " %7.2f r_pv1_loo_wtd "%" "`cidataLsp'" "[" %6.2f r_ci_loo_bounds_wtd[6,1] ///
						"%" "`cimidpadsp'" " " %6.2f r_ci_loo_bounds_wtd[6,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv_wtd "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds_wtd[7,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[7,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_ess_pv_loo_wtd "%" "`cidataLsp'" "[" %6.2f ///
						r_ci_loo_bounds_wtd[7,1] "%" "`cimidpadsp'" " " %6.2f r_ci_loo_bounds_wtd[7,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total_wtd "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds_wtd[8,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[8,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_ess_total_loo_wtd "%" "`cidataLsp'" "[" %6.2f ///
						r_ci_loo_bounds_wtd[8,1] "%" "`cimidpadsp'" " " %6.2f r_ci_loo_bounds_wtd[8,2] "%]" ///
						"`cidataRsp'"
				}
				else {
										di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc_wtd "%  " %7.2f ///
						r_overall_acc_loo_wtd "%"
										di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f (r_pac0_wtd*100) "%  " %7.2f ///
						(r_pac0_loo_wtd*100) "%"
										di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f (r_pac1_wtd*100) "%  " %7.2f ///
						(r_pac1_loo_wtd*100) "%"
										di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_pac_wtd "%  " %7.2f ///
						r_ess_pac_loo_wtd "%"
										di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f r_pv0_wtd "%  " %7.2f ///
						r_pv0_loo_wtd "%"
										di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f r_pv1_wtd "%  " %7.2f ///
						r_pv1_loo_wtd "%"
										di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv_wtd "%  " %7.2f ///
						r_ess_pv_loo_wtd "%"
										di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total_wtd "%  " %7.2f ///
						r_ess_total_loo_wtd "%"
				}
			}
			if `ciflag' & !`fitfailed' {
			di as text "{hline `citotalw_loo'}"
			}
			else {
				di as text "{hline 42}"
			}
		}
		else {
			if `ciflag' & !`fitfailed' {
				di as text "{hline `citotalw_noloo'}"
				di as text %-24s "" %8s "" "  " "`boothdrLsp'" "Bootstrap" "`boothdrRsp'"
				di as text %-24s "Performance Index" %8s "Train" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'"
				di as text "{hline `citotalw_noloo'}"
			}
			else {
				di as text "{hline 32}"
				di as text %-24s "Performance Index" "   Train"
				di as text "{hline 32}"
			}
			if "`wt'" == "" {
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds[4,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[4,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f (r_spec*100) "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds[3,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[3,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f (r_sens*100) "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds[2,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[2,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_train "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds[1,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[1,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f r_pv0 "%" "`cidataLsp'" "[" %6.2f ///
						r_ci_train_bounds[5,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[5,2] "%]" "`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f r_pv1 "%" "`cidataLsp'" "[" %6.2f ///
						r_ci_train_bounds[6,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[6,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds[7,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[7,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds[8,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[8,2] "%]" ///
						"`cidataRsp'"
				}
				else {
					di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc "%"
					di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f (r_spec*100) "%"
					di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f (r_sens*100) "%"
					di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_train "%"
					di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f r_pv0 "%"
					di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f r_pv1 "%"
					di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv "%"
					di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total "%"
				}
			}
			else {
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc_wtd "%" ///
						"`cidataLsp'" "[" %6.2f r_ci_train_bounds_wtd[4,1] "%" "`cimidpadsp'" " " %6.2f ///
						r_ci_train_bounds_wtd[4,2] "%]" "`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f (r_pac0_wtd*100) "%" ///
						"`cidataLsp'" "[" %6.2f r_ci_train_bounds_wtd[3,1] "%" "`cimidpadsp'" " " %6.2f ///
						r_ci_train_bounds_wtd[3,2] "%]" "`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f (r_pac1_wtd*100) "%" ///
						"`cidataLsp'" "[" %6.2f r_ci_train_bounds_wtd[2,1] "%" "`cimidpadsp'" " " %6.2f ///
						r_ci_train_bounds_wtd[2,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_pac_wtd "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds_wtd[1,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[1,2] ///
						"%]" "`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f r_pv0_wtd "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds_wtd[5,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[5,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f r_pv1_wtd "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds_wtd[6,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[6,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv_wtd "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds_wtd[7,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[7,2] ///
						"%]" "`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total_wtd "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds_wtd[8,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[8,2] ///
						"%]" "`cidataRsp'"
				}
				else {
					di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc_wtd "%"
					di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f (r_pac0_wtd*100) "%"
					di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f (r_pac1_wtd*100) "%"
					di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_pac_wtd "%"
					di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f r_pv0_wtd "%"
					di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f r_pv1_wtd "%"
					di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv_wtd "%"
					di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total_wtd "%"
				}
			}
			if `ciflag' & !`fitfailed' {
			di as text "{hline `citotalw_noloo'}"
			}
			else {
				di as text "{hline 32}"
			}
		}
	}
	else {
		if "`loo'" != "" {
			if `ciflag' & !`fitfailed' {
				di as text "{hline `citotalw_loo'}"
								di as text %-24s "" %8s "" "  " "`boothdrLsp'" "Bootstrap" "`boothdrRsp'" "  " %8s "" "  " ///
					"`boothdrLsp'" "Bootstrap" "`boothdrRsp'"
								di as text %-24s "Performance Index" %8s "Train" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'" ///
					"  " %8s "LOO" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'"
				di as text "{hline `citotalw_loo'}"
			}
			else {
				di as text "{hline 42}"
				di as text %-24s "Performance Index" "   Train       LOO"
				di as text "{hline 42}"
			}
			if "`wt'" == "" {
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds[2,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[2,2] "%]" ///
						"`cidataRsp'" "  " %7.2f r_overall_acc_loo "%" "`cidataLsp'" "[" %6.2f r_ci_loo_bounds[2,1] ///
						"%" "`cimidpadsp'" " " %6.2f r_ci_loo_bounds[2,2] "%]" "`cidataRsp'"
				}
				else {
										di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc "%  " %7.2f ///
						r_overall_acc_loo "%"
				}
				forvalues k = 1/`Klev' {
					local kkval = r_K_cvals[`k',1]
					local kk : label (`class') `kkval'
					local pt = r_K_pac_train[`k',1]
					local pl = r_K_pac_loo[`k',1]
					if `ciflag' & !`fitfailed' {
												di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `pt' "%" "`cidataLsp'" "[" %6.2f ///
							r_ci_train_pac_bounds[`k',1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_pac_bounds[`k',2] "%]" ///
							"`cidataRsp'" "  " %7.2f `pl' "%" "`cidataLsp'" "[" %6.2f r_ci_loo_pac_bounds[`k',1] "%" ///
							"`cimidpadsp'" " " %6.2f r_ci_loo_pac_bounds[`k',2] "%]" "`cidataRsp'"
					}
					else {
						di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `pt' "%  " %7.2f `pl' "%"
					}
				}
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_train "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds[1,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[1,2] "%]" ///
						"`cidataRsp'" "  " %7.2f r_ess_loo "%" "`cidataLsp'" "[" %6.2f r_ci_loo_bounds[1,1] "%" ///
						"`cimidpadsp'" " " %6.2f r_ci_loo_bounds[1,2] "%]" "`cidataRsp'"
				}
				else {
					di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_train "%  " %7.2f r_ess_loo "%"
				}
				forvalues k = 1/`Klev' {
					local kkval = r_K_cvals[`k',1]
					local kk : label (`class') `kkval'
					local pt = r_K_pv_train[`k',1]
					local pl = r_K_pv_loo[`k',1]
					if `ciflag' & !`fitfailed' {
						if `pt' == . & `pl' == . {
							di as text %-24s "PV `CLASSU'=`kk'" as result %8s "---" "  " %8s "---"
						}
						else if `pl' == . {
														di as text %-24s "PV `CLASSU'=`kk'" as result %7.2f `pt' "%" "`cidataLsp'" "[" %6.2f ///
								r_ci_train_pv_bounds[`k',1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_pv_bounds[`k',2] "%]" ///
								"`cidataRsp'" "  " %8s "---"
						}
						else if `pt' == . {
														di as text %-24s "PV `CLASSU'=`kk'" as result %8s "---" "  " %7.2f `pl' "%" ///
								"`cidataLsp'" "[" %6.2f r_ci_loo_pv_bounds[`k',1] "%" "`cimidpadsp'" " " %6.2f ///
								r_ci_loo_pv_bounds[`k',2] "%]" "`cidataRsp'"
						}
						else {
														di as text %-24s "PV `CLASSU'=`kk'" as result %7.2f `pt' "%" "`cidataLsp'" "[" %6.2f ///
								r_ci_train_pv_bounds[`k',1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_pv_bounds[`k',2] "%]" ///
								"`cidataRsp'" "  " %7.2f `pl' "%" "`cidataLsp'" "[" %6.2f r_ci_loo_pv_bounds[`k',1] "%" ///
								"`cimidpadsp'" " " %6.2f r_ci_loo_pv_bounds[`k',2] "%]" "`cidataRsp'"
						}
					}
					else {
						if `pt' == . & `pl' == . {
							di as text %-24s "PV `CLASSU'=`kk'" as result %8s "---" "  " %8s "---"
						}
						else if `pl' == . {
							di as text %-24s "PV `CLASSU'=`kk'" as result %7.2f `pt' "%  " %8s "---"
						}
						else if `pt' == . {
							di as text %-24s "PV `CLASSU'=`kk'" as result %8s "---" "  " %7.2f `pl' "%"
						}
						else {
							di as text %-24s "PV `CLASSU'=`kk'" as result %7.2f `pt' "%  " %7.2f `pl' "%"
						}
					}
				}
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds[3,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[3,2] "%]" ///
						"`cidataRsp'" "  " %7.2f r_ess_pv_loo "%" "`cidataLsp'" "[" %6.2f r_ci_loo_bounds[3,1] "%" ///
						"`cimidpadsp'" " " %6.2f r_ci_loo_bounds[3,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds[4,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[4,2] "%]" ///
						"`cidataRsp'" "  " %7.2f r_ess_total_loo "%" "`cidataLsp'" "[" %6.2f r_ci_loo_bounds[4,1] "%" ///
						"`cimidpadsp'" " " %6.2f r_ci_loo_bounds[4,2] "%]" "`cidataRsp'"
				}
				else {
					di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv "%  " %7.2f r_ess_pv_loo "%"
										di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total "%  " %7.2f ///
						r_ess_total_loo "%"
				}
			}
			else {
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc_wtd "%" ///
						"`cidataLsp'" "[" %6.2f r_ci_train_bounds_wtd[2,1] "%" "`cimidpadsp'" " " %6.2f ///
						r_ci_train_bounds_wtd[2,2] "%]" "`cidataRsp'" "  " %7.2f r_overall_acc_loo_wtd "%" ///
						"`cidataLsp'" "[" %6.2f r_ci_loo_bounds_wtd[2,1] "%" "`cimidpadsp'" " " %6.2f ///
						r_ci_loo_bounds_wtd[2,2] "%]" "`cidataRsp'"
				}
				else {
										di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc_wtd "%  " %7.2f ///
						r_overall_acc_loo_wtd "%"
				}
				forvalues k = 1/`Klev' {
					local kkval = r_K_cvals[`k',1]
					local kk : label (`class') `kkval'
					local pt = r_K_pac_train_wtd[`k',1]
					local pl = r_K_pac_loo_wtd[`k',1]
					if `ciflag' & !`fitfailed' {
												di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `pt' "%" "`cidataLsp'" "[" %6.2f ///
							r_ci_train_pac_bounds_wtd[`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							r_ci_train_pac_bounds_wtd[`k',2] "%]" "`cidataRsp'" "  " %7.2f `pl' "%" "`cidataLsp'" "[" ///
							%6.2f r_ci_loo_pac_bounds_wtd[`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							r_ci_loo_pac_bounds_wtd[`k',2] "%]" "`cidataRsp'"
					}
					else {
						di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `pt' "%  " %7.2f `pl' "%"
					}
				}
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_train_wtd "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds_wtd[1,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[1,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_ess_loo_wtd "%" "`cidataLsp'" "[" %6.2f ///
						r_ci_loo_bounds_wtd[1,1] "%" "`cimidpadsp'" " " %6.2f r_ci_loo_bounds_wtd[1,2] "%]" ///
						"`cidataRsp'"
				}
				else {
										di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_train_wtd "%  " %7.2f ///
						r_ess_loo_wtd "%"
				}
				forvalues k = 1/`Klev' {
					local kkval = r_K_cvals[`k',1]
					local kk : label (`class') `kkval'
					local pt = r_K_pv_train_wtd[`k',1]
					local pl = r_K_pv_loo_wtd[`k',1]
					if `ciflag' & !`fitfailed' {
						if `pt' == . & `pl' == . {
							di as text %-24s "PV `CLASSU'=`kk'" as result %8s "---" "  " %8s "---"
						}
						else if `pl' == . {
														di as text %-24s "PV `CLASSU'=`kk'" as result %7.2f `pt' "%" "`cidataLsp'" "[" %6.2f ///
								r_ci_train_pv_bounds_wtd[`k',1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_pv_bounds_wtd[`k',2] ///
								"%]" "`cidataRsp'" "  " %8s "---"
						}
						else if `pt' == . {
														di as text %-24s "PV `CLASSU'=`kk'" as result %8s "---" "  " %7.2f `pl' "%" ///
								"`cidataLsp'" "[" %6.2f r_ci_loo_pv_bounds_wtd[`k',1] "%" "`cimidpadsp'" " " %6.2f ///
								r_ci_loo_pv_bounds_wtd[`k',2] "%]" "`cidataRsp'"
						}
						else {
														di as text %-24s "PV `CLASSU'=`kk'" as result %7.2f `pt' "%" "`cidataLsp'" "[" %6.2f ///
								r_ci_train_pv_bounds_wtd[`k',1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_pv_bounds_wtd[`k',2] ///
								"%]" "`cidataRsp'" "  " %7.2f `pl' "%" "`cidataLsp'" "[" %6.2f r_ci_loo_pv_bounds_wtd[`k',1] ///
								"%" "`cimidpadsp'" " " %6.2f r_ci_loo_pv_bounds_wtd[`k',2] "%]" "`cidataRsp'"
						}
					}
					else {
						if `pt' == . & `pl' == . {
							di as text %-24s "PV `CLASSU'=`kk'" as result %8s "---" "  " %8s "---"
						}
						else if `pl' == . {
							di as text %-24s "PV `CLASSU'=`kk'" as result %7.2f `pt' "%  " %8s "---"
						}
						else if `pt' == . {
							di as text %-24s "PV `CLASSU'=`kk'" as result %8s "---" "  " %7.2f `pl' "%"
						}
						else {
							di as text %-24s "PV `CLASSU'=`kk'" as result %7.2f `pt' "%  " %7.2f `pl' "%"
						}
					}
				}
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv_wtd "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds_wtd[3,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[3,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_ess_pv_loo_wtd "%" "`cidataLsp'" "[" %6.2f ///
						r_ci_loo_bounds_wtd[3,1] "%" "`cimidpadsp'" " " %6.2f r_ci_loo_bounds_wtd[3,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total_wtd "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds_wtd[4,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[4,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_ess_total_loo_wtd "%" "`cidataLsp'" "[" %6.2f ///
						r_ci_loo_bounds_wtd[4,1] "%" "`cimidpadsp'" " " %6.2f r_ci_loo_bounds_wtd[4,2] "%]" ///
						"`cidataRsp'"
				}
				else {
										di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv_wtd "%  " %7.2f ///
						r_ess_pv_loo_wtd "%"
										di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total_wtd "%  " %7.2f ///
						r_ess_total_loo_wtd "%"
				}
			}
			if `ciflag' & !`fitfailed' {
			di as text "{hline `citotalw_loo'}"
			}
			else {
				di as text "{hline 42}"
			}
		}
		else {
			if `ciflag' & !`fitfailed' {
				di as text "{hline `citotalw_noloo'}"
				di as text %-24s "" %8s "" "  " "`boothdrLsp'" "Bootstrap" "`boothdrRsp'"
				di as text %-24s "Performance Index" %8s "Train" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'"
				di as text "{hline `citotalw_noloo'}"
			}
			else {
				di as text "{hline 32}"
				di as text %-24s "Performance Index" "   Train"
				di as text "{hline 32}"
			}
			if "`wt'" == "" {
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds[2,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[2,2] "%]" ///
						"`cidataRsp'"
				}
				else {
					di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc "%"
				}
				forvalues k = 1/`Klev' {
					local kkval = r_K_cvals[`k',1]
					local kk : label (`class') `kkval'
					local pt = r_K_pac_train[`k',1]
					if `ciflag' & !`fitfailed' {
												di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `pt' "%" "`cidataLsp'" "[" %6.2f ///
							r_ci_train_pac_bounds[`k',1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_pac_bounds[`k',2] "%]" ///
							"`cidataRsp'"
					}
					else {
						di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `pt' "%"
					}
				}
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_train "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds[1,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[1,2] "%]" ///
						"`cidataRsp'"
				}
				else {
					di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_train "%"
				}
				forvalues k = 1/`Klev' {
					local kkval = r_K_cvals[`k',1]
					local kk : label (`class') `kkval'
					local pt = r_K_pv_train[`k',1]
					if `ciflag' & !`fitfailed' {
						if `pt' == . {
							di as text %-24s "PV `CLASSU'=`kk'" as result %8s "---"
						}
						else {
														di as text %-24s "PV `CLASSU'=`kk'" as result %7.2f `pt' "%" "`cidataLsp'" "[" %6.2f ///
								r_ci_train_pv_bounds[`k',1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_pv_bounds[`k',2] "%]" ///
								"`cidataRsp'"
						}
					}
					else {
						if `pt' == . {
							di as text %-24s "PV `CLASSU'=`kk'" as result %8s "---"
						}
						else {
							di as text %-24s "PV `CLASSU'=`kk'" as result %7.2f `pt' "%"
						}
					}
				}
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds[3,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[3,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total "%" "`cidataLsp'" "[" ///
						%6.2f r_ci_train_bounds[4,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds[4,2] "%]" ///
						"`cidataRsp'"
				}
				else {
					di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv "%"
					di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total "%"
				}
			}
			else {
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc_wtd "%" ///
						"`cidataLsp'" "[" %6.2f r_ci_train_bounds_wtd[2,1] "%" "`cimidpadsp'" " " %6.2f ///
						r_ci_train_bounds_wtd[2,2] "%]" "`cidataRsp'"
				}
				else {
					di as text %-24s "Overall Accuracy"      as result %7.2f r_overall_acc_wtd "%"
				}
				forvalues k = 1/`Klev' {
					local kkval = r_K_cvals[`k',1]
					local kk : label (`class') `kkval'
					local pt = r_K_pac_train_wtd[`k',1]
					if `ciflag' & !`fitfailed' {
												di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `pt' "%" "`cidataLsp'" "[" %6.2f ///
							r_ci_train_pac_bounds_wtd[`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							r_ci_train_pac_bounds_wtd[`k',2] "%]" "`cidataRsp'"
					}
					else {
						di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `pt' "%"
					}
				}
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_train_wtd "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds_wtd[1,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[1,2] ///
						"%]" "`cidataRsp'"
				}
				else {
					di as text %-24s "Effect Strength PAC"   as result %7.2f r_ess_train_wtd "%"
				}
				forvalues k = 1/`Klev' {
					local kkval = r_K_cvals[`k',1]
					local kk : label (`class') `kkval'
					local pt = r_K_pv_train_wtd[`k',1]
					if `ciflag' & !`fitfailed' {
						if `pt' == . {
							di as text %-24s "PV `CLASSU'=`kk'" as result %8s "---"
						}
						else {
														di as text %-24s "PV `CLASSU'=`kk'" as result %7.2f `pt' "%" "`cidataLsp'" "[" %6.2f ///
								r_ci_train_pv_bounds_wtd[`k',1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_pv_bounds_wtd[`k',2] ///
								"%]" "`cidataRsp'"
						}
					}
					else {
						if `pt' == . {
							di as text %-24s "PV `CLASSU'=`kk'" as result %8s "---"
						}
						else {
							di as text %-24s "PV `CLASSU'=`kk'" as result %7.2f `pt' "%"
						}
					}
				}
				if `ciflag' & !`fitfailed' {
										di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv_wtd "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds_wtd[3,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[3,2] ///
						"%]" "`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total_wtd "%" "`cidataLsp'" ///
						"[" %6.2f r_ci_train_bounds_wtd[4,1] "%" "`cimidpadsp'" " " %6.2f r_ci_train_bounds_wtd[4,2] ///
						"%]" "`cidataRsp'"
				}
				else {
					di as text %-24s "Effect Strength PV"    as result %7.2f r_ess_pv_wtd "%"
					di as text %-24s "Effect Strength Total" as result %7.2f r_ess_total_wtd "%"
				}
			}
			if `ciflag' & !`fitfailed' {
			di as text "{hline `citotalw_noloo'}"
			}
			else {
				di as text "{hline 32}"
			}
		}
	}
	}

	if `niter' > 0 {
		di _n as text "Monte Carlo summary (Fisher randomization):"
		di as text "{hline 43}"		
		di as text "Iterations:  " as result "`niter'"
		di as text "Estimated p: " as result %9.6f r_est_P
		if "`sidak'" != "" di as text "Sidak adjusted (`sidak') p: " as result %9.6f `adjP'
	}

	if "`loo'" != "" {
		di _n as text "Results of leave-one-out analysis:"
		di as text "{hline 34}"			
		di as text %9.0f r_N " observations"
		if `nloo' > 0 {
						di as text "LOO permutation test (`nloo' iter) classification table  p = " as result %9.6f ///
				r_est_P_LOO
			if "`sidak'" != "" di as text "Sidak adjusted LOO permutation p: " as result %9.6f `adjLOO'
		}
		else if !`multiclass' {
						di as text "Fisher's exact test (directional) classification table  p = " as result %9.6f ///
				r_est_P_LOO
			if "`sidak'" != "" di as text "Sidak adjusted LOO p: " as result %9.6f `adjLOO'
		}
		else {
						di as text ///
				"    (Specify {cmd:looreps()} to compute {it:P}-values multi-categorical class variables)"
		}
	}

	if "`gen'" != "" & !`fitfailed' & !`multiclass' {
		local GENU = upper("`gen'")
		if `crossflag' local gentitle "Cross-validation across samples (grouped by `GENU'):"
		else            local gentitle "Generalizability breakdown by `GENU':"
		di _n as text "`gentitle'"
		local genhlen = strlen("`gentitle'")
		di as text "{hline `genhlen'}"
		if "`wt'" != "" {
			local gwoff = 17
			local gtrainmat "r_ci_gen_train_bounds_wtd"
			local gloomat   "r_ci_gen_loo_bounds_wtd"
		}
		else {
			local gwoff = 0
			local gtrainmat "r_ci_gen_train_bounds"
			local gloomat   "r_ci_gen_loo_bounds"
		}
		local c_ess_pac   = 5  + `gwoff'
		local c_pac_chigh = 3  + `gwoff'
		local c_pac_clow  = 4  + `gwoff'
		local c_overall   = 6  + `gwoff'
		local c_pv_clow   = 7  + `gwoff'
		local c_pv_chigh  = 8  + `gwoff'
		local c_ess_pv    = 9  + `gwoff'
		local c_ess_total = 10 + `gwoff'
		local crossholdci = (`crossflag' & `ciflag')
		local traingrow = 0
		if `crossflag' {
			forvalues gg = 1/`ngen' {
				if r_gen_breakdown[`gg',1] == `crosstrain' local traingrow = `gg'
			}
		}
		local traingrbase = (`traingrow'-1)*8
		forvalues g = 1/`ngen' {
			local gvval = r_gen_breakdown[`g',1]
			local gv : label (`gen') `gvval'
			local gn = string(r_gen_breakdown[`g',2], "%9.0f")
			local grbase = (`g'-1)*8
			local crosstag ""
			local crossisholdout = 0
			if `crossflag' {
				if `gvval' == `crosstrain' local crosstag "  [TRAINING SAMPLE]"
				else {
					local crosstag "  [HOLDOUT]"
					local crossisholdout = 1
				}
			}
			di _n as text "Results for group `GENU'=`gv'  (`gn' observations)`crosstag'"
			if `crossisholdout' {
				if `crossholdci' & "`loo'" != "" {
					di as text "{hline `citotalw_loo3'}"
										di as text %-24s "" %8s "" "  " "`boothdrLsp'" "Bootstrap" "`boothdrRsp'" "  " %8s "" "  " ///
						"`boothdrLsp'" "Bootstrap" "`boothdrRsp'" "  " %8s "" "  " "`boothdrLsp'" "Bootstrap" ///
						"`boothdrRsp'"
										di as text %-24s "Performance Index" %8s "Train" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'" ///
						"  " %8s "LOO" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'" "  " %8s "Hold" "  " "`cihdrLsp'" ///
						"`cihdr'" "`cihdrRsp'"
					di as text "{hline `citotalw_loo3'}"
										di as text %-24s "Overall Accuracy"      as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_overall'] "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+4,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+4,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`traingrow',`c_overall'+8] "%" "`cidataLsp'" "[" ///
						%6.2f `gloomat'[`traingrbase'+4,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`traingrbase'+4,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_overall'] "%" "`cidataLsp'" "[" %6.2f ///
						`gloomat'[`grbase'+4,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+4,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f ///
						(r_gen_breakdown[`traingrow',`c_pac_clow']*100) "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+3,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+3,2] ///
						"%]" "`cidataRsp'" "  " %7.2f (r_gen_breakdown[`traingrow',`c_pac_clow'+8]*100) "%" ///
						"`cidataLsp'" "[" %6.2f `gloomat'[`traingrbase'+3,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gloomat'[`traingrbase'+3,2] "%]" "`cidataRsp'" "  " %7.2f ///
						(r_gen_breakdown[`g',`c_pac_clow']*100) "%" "`cidataLsp'" "[" %6.2f `gloomat'[`grbase'+3,1] ///
						"%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+3,2] "%]" "`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f ///
						(r_gen_breakdown[`traingrow',`c_pac_chigh']*100) "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+2,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+2,2] ///
						"%]" "`cidataRsp'" "  " %7.2f (r_gen_breakdown[`traingrow',`c_pac_chigh'+8]*100) "%" ///
						"`cidataLsp'" "[" %6.2f `gloomat'[`traingrbase'+2,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gloomat'[`traingrbase'+2,2] "%]" "`cidataRsp'" "  " %7.2f ///
						(r_gen_breakdown[`g',`c_pac_chigh']*100) "%" "`cidataLsp'" "[" %6.2f `gloomat'[`grbase'+2,1] ///
						"%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+2,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength PAC"   as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_ess_pac'] "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+1,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+1,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`traingrow',`c_ess_pac'+8] "%" "`cidataLsp'" "[" ///
						%6.2f `gloomat'[`traingrbase'+1,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`traingrbase'+1,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_ess_pac'] "%" "`cidataLsp'" "[" %6.2f ///
						`gloomat'[`grbase'+1,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+1,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_pv_clow'] "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+5,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+5,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`traingrow',`c_pv_clow'+8] "%" "`cidataLsp'" "[" ///
						%6.2f `gloomat'[`traingrbase'+5,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`traingrbase'+5,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_pv_clow'] "%" "`cidataLsp'" "[" %6.2f ///
						`gloomat'[`grbase'+5,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+5,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_pv_chigh'] "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+6,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+6,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`traingrow',`c_pv_chigh'+8] "%" "`cidataLsp'" ///
						"[" %6.2f `gloomat'[`traingrbase'+6,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gloomat'[`traingrbase'+6,2] "%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_pv_chigh'] ///
						"%" "`cidataLsp'" "[" %6.2f `gloomat'[`grbase'+6,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gloomat'[`grbase'+6,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength PV"    as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_ess_pv'] "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+7,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+7,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`traingrow',`c_ess_pv'+8] "%" "`cidataLsp'" "[" ///
						%6.2f `gloomat'[`traingrbase'+7,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`traingrbase'+7,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_ess_pv'] "%" "`cidataLsp'" "[" %6.2f ///
						`gloomat'[`grbase'+7,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+7,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_ess_total'] "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+8,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+8,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`traingrow',`c_ess_total'+8] "%" "`cidataLsp'" ///
						"[" %6.2f `gloomat'[`traingrbase'+8,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gloomat'[`traingrbase'+8,2] "%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_ess_total'] ///
						"%" "`cidataLsp'" "[" %6.2f `gloomat'[`grbase'+8,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gloomat'[`grbase'+8,2] "%]" "`cidataRsp'"
					di as text "{hline `citotalw_loo3'}"
				}
				else if `crossholdci' {
					di as text "{hline `citotalw_loo'}"
										di as text %-24s "" %8s "" "  " "`boothdrLsp'" "Bootstrap" "`boothdrRsp'" "  " %8s "" "  " ///
						"`boothdrLsp'" "Bootstrap" "`boothdrRsp'"
										di as text %-24s "Performance Index" %8s "Train" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'" ///
						"  " %8s "Hold" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'"
					di as text "{hline `citotalw_loo'}"
										di as text %-24s "Overall Accuracy"      as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_overall'] "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+4,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+4,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_overall'] "%" "`cidataLsp'" "[" %6.2f ///
						`gloomat'[`grbase'+4,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+4,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f ///
						(r_gen_breakdown[`traingrow',`c_pac_clow']*100) "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+3,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+3,2] ///
						"%]" "`cidataRsp'" "  " %7.2f (r_gen_breakdown[`g',`c_pac_clow']*100) "%" "`cidataLsp'" "[" ///
						%6.2f `gloomat'[`grbase'+3,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+3,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f ///
						(r_gen_breakdown[`traingrow',`c_pac_chigh']*100) "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+2,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+2,2] ///
						"%]" "`cidataRsp'" "  " %7.2f (r_gen_breakdown[`g',`c_pac_chigh']*100) "%" "`cidataLsp'" "[" ///
						%6.2f `gloomat'[`grbase'+2,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+2,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "Effect Strength PAC"   as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_ess_pac'] "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+1,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+1,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_ess_pac'] "%" "`cidataLsp'" "[" %6.2f ///
						`gloomat'[`grbase'+1,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+1,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_pv_clow'] "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+5,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+5,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_pv_clow'] "%" "`cidataLsp'" "[" %6.2f ///
						`gloomat'[`grbase'+5,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+5,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_pv_chigh'] "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+6,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+6,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_pv_chigh'] "%" "`cidataLsp'" "[" %6.2f ///
						`gloomat'[`grbase'+6,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+6,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "Effect Strength PV"    as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_ess_pv'] "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+7,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+7,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_ess_pv'] "%" "`cidataLsp'" "[" %6.2f ///
						`gloomat'[`grbase'+7,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+7,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_ess_total'] "%" "`cidataLsp'" "[" %6.2f ///
						`gtrainmat'[`traingrbase'+8,1] "%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`traingrbase'+8,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_ess_total'] "%" "`cidataLsp'" "[" %6.2f ///
						`gloomat'[`grbase'+8,1] "%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+8,2] "%]" ///
						"`cidataRsp'"
					di as text "{hline `citotalw_loo'}"
				}
				else if "`loo'" != "" {
					di as text "{hline 52}"
					di as text %-24s "Performance Index" "   Train       LOO      Hold"
					di as text "{hline 52}"
										di as text %-24s "Overall Accuracy"      as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_overall'] "%  " %7.2f ///
						r_gen_breakdown[`traingrow',`c_overall'+8] "%  " %7.2f r_gen_breakdown[`g',`c_overall'] "%"
										di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f ///
						(r_gen_breakdown[`traingrow',`c_pac_clow']*100) "%  " %7.2f ///
						(r_gen_breakdown[`traingrow',`c_pac_clow'+8]*100) "%  " %7.2f ///
						(r_gen_breakdown[`g',`c_pac_clow']*100) "%"
										di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f ///
						(r_gen_breakdown[`traingrow',`c_pac_chigh']*100) "%  " %7.2f ///
						(r_gen_breakdown[`traingrow',`c_pac_chigh'+8]*100) "%  " %7.2f ///
						(r_gen_breakdown[`g',`c_pac_chigh']*100) "%"
										di as text %-24s "Effect Strength PAC"   as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_ess_pac'] "%  " %7.2f ///
						r_gen_breakdown[`traingrow',`c_ess_pac'+8] "%  " %7.2f r_gen_breakdown[`g',`c_ess_pac'] "%"
										di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_pv_clow'] "%  " %7.2f ///
						r_gen_breakdown[`traingrow',`c_pv_clow'+8] "%  " %7.2f r_gen_breakdown[`g',`c_pv_clow'] "%"
										di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_pv_chigh'] "%  " %7.2f ///
						r_gen_breakdown[`traingrow',`c_pv_chigh'+8] "%  " %7.2f r_gen_breakdown[`g',`c_pv_chigh'] "%"
										di as text %-24s "Effect Strength PV"    as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_ess_pv'] "%  " %7.2f r_gen_breakdown[`traingrow',`c_ess_pv'+8] ///
						"%  " %7.2f r_gen_breakdown[`g',`c_ess_pv'] "%"
										di as text %-24s "Effect Strength Total" as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_ess_total'] "%  " %7.2f ///
						r_gen_breakdown[`traingrow',`c_ess_total'+8] "%  " %7.2f r_gen_breakdown[`g',`c_ess_total'] ///
						"%"
					di as text "{hline 52}"
				}
				else {
					di as text "{hline 42}"
					di as text %-24s "Performance Index" "   Train      Hold"
					di as text "{hline 42}"
										di as text %-24s "Overall Accuracy"      as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_overall'] "%  " %7.2f r_gen_breakdown[`g',`c_overall'] "%"
										di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f ///
						(r_gen_breakdown[`traingrow',`c_pac_clow']*100) "%  " %7.2f ///
						(r_gen_breakdown[`g',`c_pac_clow']*100) "%"
										di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f ///
						(r_gen_breakdown[`traingrow',`c_pac_chigh']*100) "%  " %7.2f ///
						(r_gen_breakdown[`g',`c_pac_chigh']*100) "%"
										di as text %-24s "Effect Strength PAC"   as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_ess_pac'] "%  " %7.2f r_gen_breakdown[`g',`c_ess_pac'] "%"
										di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_pv_clow'] "%  " %7.2f r_gen_breakdown[`g',`c_pv_clow'] "%"
										di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_pv_chigh'] "%  " %7.2f r_gen_breakdown[`g',`c_pv_chigh'] "%"
										di as text %-24s "Effect Strength PV"    as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_ess_pv'] "%  " %7.2f r_gen_breakdown[`g',`c_ess_pv'] "%"
										di as text %-24s "Effect Strength Total" as result %7.2f ///
						r_gen_breakdown[`traingrow',`c_ess_total'] "%  " %7.2f r_gen_breakdown[`g',`c_ess_total'] "%"
					di as text "{hline 42}"
				}
			}
			else if "`loo'" != "" {
				if `ciflag' & !`fitfailed' {
					di as text "{hline `citotalw_loo'}"
										di as text %-24s "" %8s "" "  " "`boothdrLsp'" "Bootstrap" "`boothdrRsp'" "  " %8s "" "  " ///
						"`boothdrLsp'" "Bootstrap" "`boothdrRsp'"
										di as text %-24s "Performance Index" %8s "Train" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'" ///
						"  " %8s "LOO" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'"
					di as text "{hline `citotalw_loo'}"
										di as text %-24s "Overall Accuracy"      as result %7.2f r_gen_breakdown[`g',`c_overall'] ///
						"%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+4,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gtrainmat'[`grbase'+4,2] "%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_overall'+8] "%" ///
						"`cidataLsp'" "[" %6.2f `gloomat'[`grbase'+4,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gloomat'[`grbase'+4,2] "%]" "`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f ///
						(r_gen_breakdown[`g',`c_pac_clow']*100) "%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+3,1] ///
						"%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`grbase'+3,2] "%]" "`cidataRsp'" "  " %7.2f ///
						(r_gen_breakdown[`g',`c_pac_clow'+8]*100) "%" "`cidataLsp'" "[" %6.2f `gloomat'[`grbase'+3,1] ///
						"%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+3,2] "%]" "`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f ///
						(r_gen_breakdown[`g',`c_pac_chigh']*100) "%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+2,1] ///
						"%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`grbase'+2,2] "%]" "`cidataRsp'" "  " %7.2f ///
						(r_gen_breakdown[`g',`c_pac_chigh'+8]*100) "%" "`cidataLsp'" "[" %6.2f `gloomat'[`grbase'+2,1] ///
						"%" "`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+2,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength PAC"   as result %7.2f r_gen_breakdown[`g',`c_ess_pac'] ///
						"%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+1,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gtrainmat'[`grbase'+1,2] "%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_ess_pac'+8] "%" ///
						"`cidataLsp'" "[" %6.2f `gloomat'[`grbase'+1,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gloomat'[`grbase'+1,2] "%]" "`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f r_gen_breakdown[`g',`c_pv_clow'] ///
						"%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+5,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gtrainmat'[`grbase'+5,2] "%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_pv_clow'+8] "%" ///
						"`cidataLsp'" "[" %6.2f `gloomat'[`grbase'+5,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gloomat'[`grbase'+5,2] "%]" "`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f r_gen_breakdown[`g',`c_pv_chigh'] ///
						"%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+6,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gtrainmat'[`grbase'+6,2] "%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_pv_chigh'+8] ///
						"%" "`cidataLsp'" "[" %6.2f `gloomat'[`grbase'+6,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gloomat'[`grbase'+6,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength PV"    as result %7.2f r_gen_breakdown[`g',`c_ess_pv'] ///
						"%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+7,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gtrainmat'[`grbase'+7,2] "%]" "`cidataRsp'" "  " %7.2f r_gen_breakdown[`g',`c_ess_pv'+8] "%" ///
						"`cidataLsp'" "[" %6.2f `gloomat'[`grbase'+7,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gloomat'[`grbase'+7,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f ///
						r_gen_breakdown[`g',`c_ess_total'] "%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+8,1] "%" ///
						"`cimidpadsp'" " " %6.2f `gtrainmat'[`grbase'+8,2] "%]" "`cidataRsp'" "  " %7.2f ///
						r_gen_breakdown[`g',`c_ess_total'+8] "%" "`cidataLsp'" "[" %6.2f `gloomat'[`grbase'+8,1] "%" ///
						"`cimidpadsp'" " " %6.2f `gloomat'[`grbase'+8,2] "%]" "`cidataRsp'"
					di as text "{hline `citotalw_loo'}"
				}
				else {
					di as text "{hline 42}"
					di as text %-24s "Performance Index" "   Train       LOO"
					di as text "{hline 42}"
										di as text %-24s "Overall Accuracy"      as result %7.2f r_gen_breakdown[`g',`c_overall'] ///
						"%  " %7.2f r_gen_breakdown[`g',`c_overall'+8] "%"
										di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f ///
						(r_gen_breakdown[`g',`c_pac_clow']*100) "%  " %7.2f (r_gen_breakdown[`g',`c_pac_clow'+8]*100) ///
						"%"
										di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f ///
						(r_gen_breakdown[`g',`c_pac_chigh']*100) "%  " %7.2f ///
						(r_gen_breakdown[`g',`c_pac_chigh'+8]*100) "%"
										di as text %-24s "Effect Strength PAC"   as result %7.2f r_gen_breakdown[`g',`c_ess_pac'] ///
						"%  " %7.2f r_gen_breakdown[`g',`c_ess_pac'+8] "%"
										di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f r_gen_breakdown[`g',`c_pv_clow'] ///
						"%  " %7.2f r_gen_breakdown[`g',`c_pv_clow'+8] "%"
										di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f r_gen_breakdown[`g',`c_pv_chigh'] ///
						"%  " %7.2f r_gen_breakdown[`g',`c_pv_chigh'+8] "%"
										di as text %-24s "Effect Strength PV"    as result %7.2f r_gen_breakdown[`g',`c_ess_pv'] ///
						"%  " %7.2f r_gen_breakdown[`g',`c_ess_pv'+8] "%"
										di as text %-24s "Effect Strength Total" as result %7.2f ///
						r_gen_breakdown[`g',`c_ess_total'] "%  " %7.2f r_gen_breakdown[`g',`c_ess_total'+8] "%"
					di as text "{hline 42}"
				}
								local gen_pval = .
				if "`gvar_gen'" != "" & `nloo' > 0 {
					forvalues k = 1/`=rowsof(r_gen_loo_pval)' {
						if r_gen_loo_pval[`k',1] == `gvval' local gen_pval = r_gen_loo_pval[`k',2]
					}
				}
				if "`gvar_gen'" != "" & `nloo' > 0 & `gen_pval' != . {
					di as text "LOO permutation test (`nloo' iter) classification table  p = " as result ///
						%9.6f `gen_pval'
				}
				else {
					di as text "Fisher's exact test (directional) classification table, LOO  p = " as result ///
						%9.6f r_gen_breakdown[`g',19]
				}
			}
			else {
				if `ciflag' & !`fitfailed' {
					di as text "{hline `citotalw_noloo'}"
					di as text %-24s "" %8s "" "  " "`boothdrLsp'" "Bootstrap" "`boothdrRsp'"
					di as text %-24s "Performance Index" %8s "Train" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'"
					di as text "{hline `citotalw_noloo'}"
										di as text %-24s "Overall Accuracy"      as result %7.2f r_gen_breakdown[`g',`c_overall'] ///
						"%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+4,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gtrainmat'[`grbase'+4,2] "%]" "`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f ///
						(r_gen_breakdown[`g',`c_pac_clow']*100) "%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+3,1] ///
						"%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`grbase'+3,2] "%]" "`cidataRsp'"
										di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f ///
						(r_gen_breakdown[`g',`c_pac_chigh']*100) "%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+2,1] ///
						"%" "`cimidpadsp'" " " %6.2f `gtrainmat'[`grbase'+2,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength PAC"   as result %7.2f r_gen_breakdown[`g',`c_ess_pac'] ///
						"%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+1,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gtrainmat'[`grbase'+1,2] "%]" "`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f r_gen_breakdown[`g',`c_pv_clow'] ///
						"%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+5,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gtrainmat'[`grbase'+5,2] "%]" "`cidataRsp'"
										di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f r_gen_breakdown[`g',`c_pv_chigh'] ///
						"%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+6,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gtrainmat'[`grbase'+6,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength PV"    as result %7.2f r_gen_breakdown[`g',`c_ess_pv'] ///
						"%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+7,1] "%" "`cimidpadsp'" " " %6.2f ///
						`gtrainmat'[`grbase'+7,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f ///
						r_gen_breakdown[`g',`c_ess_total'] "%" "`cidataLsp'" "[" %6.2f `gtrainmat'[`grbase'+8,1] "%" ///
						"`cimidpadsp'" " " %6.2f `gtrainmat'[`grbase'+8,2] "%]" "`cidataRsp'"
					di as text "{hline `citotalw_noloo'}"
				}
				else {
					di as text "{hline 32}"
					di as text %-24s "Performance Index" "   Train"
					di as text "{hline 32}"
					di as text %-24s "Overall Accuracy"      as result %7.2f r_gen_breakdown[`g',`c_overall'] "%"
										di as text %-24s "PAC `CLASSU'=`clow'"   as result %7.2f ///
						(r_gen_breakdown[`g',`c_pac_clow']*100) "%"
										di as text %-24s "PAC `CLASSU'=`chigh'"  as result %7.2f ///
						(r_gen_breakdown[`g',`c_pac_chigh']*100) "%"
					di as text %-24s "Effect Strength PAC"   as result %7.2f r_gen_breakdown[`g',`c_ess_pac'] "%"
					di as text %-24s "PV `CLASSU'=`clow'"    as result %7.2f r_gen_breakdown[`g',`c_pv_clow'] "%"
					di as text %-24s "PV `CLASSU'=`chigh'"   as result %7.2f r_gen_breakdown[`g',`c_pv_chigh'] "%"
					di as text %-24s "Effect Strength PV"    as result %7.2f r_gen_breakdown[`g',`c_ess_pv'] "%"
					di as text %-24s "Effect Strength Total" as result %7.2f r_gen_breakdown[`g',`c_ess_total'] "%"
					di as text "{hline 32}"
				}
			}
		}
		if `crossflag' & `niter' > 0 & !`fitfailed' {
						di _n as text ///
				"Cross-sample significance test (Monte Carlo, `niter' iterations, Sidak `crosssidak'):"
			forvalues g = 1/`ncrosssig' {
				local sgvval = r_cross_sig[`g',1]
				local sgv : label (`gen') `sgvval'
				local sgn = string(r_cross_sig[`g',2], "%9.0f")
				local srawp = r_cross_sig[`g',3]
				local sadjp = 1-(1-`srawp')^`crosssidak'
				local stag ""
				if `sgvval' == `crosstrain' local stag "[TRAINING SAMPLE]"
				else                         local stag "[HOLDOUT]"
								di as text "  `GENU'=`sgv' (N=`sgn') `stag'" _col(40) "raw p=" as result %9.6f `srawp' as ///
					text "   Sidak-adj p=" as result %9.6f `sadjp'
			}
		}
		else if `crossflag' {
			di _n as text "Note: a cross-sample significance test requires trainreps() to be specified."
		}
	}

	else if "`gen'" != "" & !`fitfailed' & `multiclass' {
		local GENU = upper("`gen'")
		if `crossflag' local gentitle "Cross-validation across samples (grouped by `GENU'):"
		else            local gentitle "Generalizability breakdown by `GENU':"
		di _n as text "`gentitle'"
		local genhlen = strlen("`gentitle'")
		di as text "{hline `genhlen'}"

		if "`wt'" != "" {
			local ggoff = 4
			local gpactr "r_K_gen_pac_train_wtd"
			local gpvtr  "r_K_gen_pv_train_wtd"
			local gpaclo "r_K_gen_pac_loo_wtd"
			local gpvlo  "r_K_gen_pv_loo_wtd"
			local ggtrainmat "r_K_ci_gen_train_bounds_wtd"
			local ggloomat   "r_K_ci_gen_loo_bounds_wtd"
			local ggtrainpacmat "r_K_ci_gen_train_pac_bounds_wtd"
			local ggtrainpvmat  "r_K_ci_gen_train_pv_bounds_wtd"
			local ggloopacmat   "r_K_ci_gen_loo_pac_bounds_wtd"
			local ggloopvmat    "r_K_ci_gen_loo_pv_bounds_wtd"
		}
		else {
			local ggoff = 0
			local gpactr "r_K_gen_pac_train"
			local gpvtr  "r_K_gen_pv_train"
			local gpaclo "r_K_gen_pac_loo"
			local gpvlo  "r_K_gen_pv_loo"
			local ggtrainmat "r_K_ci_gen_train_bounds"
			local ggloomat   "r_K_ci_gen_loo_bounds"
			local ggtrainpacmat "r_K_ci_gen_train_pac_bounds"
			local ggtrainpvmat  "r_K_ci_gen_train_pv_bounds"
			local ggloopacmat   "r_K_ci_gen_loo_pac_bounds"
			local ggloopvmat    "r_K_ci_gen_loo_pv_bounds"
		}
		local c_essp = 3 + `ggoff'
		local c_over = 4 + `ggoff'
		local c_essv = 5 + `ggoff'
		local c_esst = 6 + `ggoff'
		local crossholdci = (`crossflag' & `ciflag')
		local traingrow = 0
		if `crossflag' {
			forvalues gg = 1/`ngen' {
				if r_K_gen_breakdown[`gg',1] == `crosstrain' local traingrow = `gg'
			}
		}
		local traingrbase = (`traingrow'-1)*4
		local traingrbasek = (`traingrow'-1)*`Klev'
		forvalues g = 1/`ngen' {
			local gvval = r_K_gen_breakdown[`g',1]
			local gv : label (`gen') `gvval'
			local gn = string(r_K_gen_breakdown[`g',2], "%9.0f")
			local grbase = (`g'-1)*4
			local grbasek = (`g'-1)*`Klev'
			local crosstag ""
			local crossisholdout = 0
			if `crossflag' {
				if `gvval' == `crosstrain' local crosstag "  [TRAINING SAMPLE]"
				else {
					local crosstag "  [HOLDOUT]"
					local crossisholdout = 1
				}
			}
			di _n as text "Results for group `GENU'=`gv'  (`gn' observations)`crosstag'"
			if `crossisholdout' {
				if `crossholdci' & "`loo'" != "" {
					di as text "{hline `citotalw_loo3'}"
										di as text %-24s "" %8s "" "  " "`boothdrLsp'" "Bootstrap" "`boothdrRsp'" "  " %8s "" "  " ///
						"`boothdrLsp'" "Bootstrap" "`boothdrRsp'" "  " %8s "" "  " "`boothdrLsp'" "Bootstrap" ///
						"`boothdrRsp'"
										di as text %-24s "Performance Index" %8s "Train" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'" ///
						"  " %8s "LOO" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'" "  " %8s "Hold" "  " "`cihdrLsp'" ///
						"`cihdr'" "`cihdrRsp'"
					di as text "{hline `citotalw_loo3'}"
										di as text %-24s "Overall Accuracy" as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_over'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggtrainmat'[`traingrbase'+2,1] "%" "`cimidpadsp'" " " %6.2f `ggtrainmat'[`traingrbase'+2,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`traingrow',`c_over'+8] "%" "`cidataLsp'" "[" ///
						%6.2f `ggloomat'[`traingrbase'+2,1] "%" "`cimidpadsp'" " " %6.2f `ggloomat'[`traingrbase'+2,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`g',`c_over'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggloomat'[`grbase'+2,1] "%" "`cimidpadsp'" " " %6.2f `ggloomat'[`grbase'+2,2] "%]" ///
						"`cidataRsp'"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
												di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `gpactr'[`traingrow',`k'] "%" ///
							"`cidataLsp'" "[" %6.2f `ggtrainpacmat'[`traingrbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggtrainpacmat'[`traingrbasek'+`k',2] "%]" "`cidataRsp'" "  " %7.2f `gpaclo'[`traingrow',`k'] ///
							"%" "`cidataLsp'" "[" %6.2f `ggloopacmat'[`traingrbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggloopacmat'[`traingrbasek'+`k',2] "%]" "`cidataRsp'" "  " %7.2f `gpactr'[`g',`k'] "%" ///
							"`cidataLsp'" "[" %6.2f `ggloopacmat'[`grbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggloopacmat'[`grbasek'+`k',2] "%]" "`cidataRsp'"
					}
										di as text %-24s "Effect Strength PAC" as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_essp'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggtrainmat'[`traingrbase'+1,1] "%" "`cimidpadsp'" " " %6.2f `ggtrainmat'[`traingrbase'+1,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`traingrow',`c_essp'+8] "%" "`cidataLsp'" "[" ///
						%6.2f `ggloomat'[`traingrbase'+1,1] "%" "`cimidpadsp'" " " %6.2f `ggloomat'[`traingrbase'+1,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`g',`c_essp'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggloomat'[`grbase'+1,1] "%" "`cimidpadsp'" " " %6.2f `ggloomat'[`grbase'+1,2] "%]" ///
						"`cidataRsp'"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
												di as text %-24s "PV `CLASSU'=`kk'"  as result %7.2f `gpvtr'[`traingrow',`k'] "%" ///
							"`cidataLsp'" "[" %6.2f `ggtrainpvmat'[`traingrbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggtrainpvmat'[`traingrbasek'+`k',2] "%]" "`cidataRsp'" "  " %7.2f `gpvlo'[`traingrow',`k'] ///
							"%" "`cidataLsp'" "[" %6.2f `ggloopvmat'[`traingrbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggloopvmat'[`traingrbasek'+`k',2] "%]" "`cidataRsp'" "  " %7.2f `gpvtr'[`g',`k'] "%" ///
							"`cidataLsp'" "[" %6.2f `ggloopvmat'[`grbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggloopvmat'[`grbasek'+`k',2] "%]" "`cidataRsp'"
					}
										di as text %-24s "Effect Strength PV"    as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_essv'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggtrainmat'[`traingrbase'+3,1] "%" "`cimidpadsp'" " " %6.2f `ggtrainmat'[`traingrbase'+3,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`traingrow',`c_essv'+8] "%" "`cidataLsp'" "[" ///
						%6.2f `ggloomat'[`traingrbase'+3,1] "%" "`cimidpadsp'" " " %6.2f `ggloomat'[`traingrbase'+3,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`g',`c_essv'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggloomat'[`grbase'+3,1] "%" "`cimidpadsp'" " " %6.2f `ggloomat'[`grbase'+3,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_esst'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggtrainmat'[`traingrbase'+4,1] "%" "`cimidpadsp'" " " %6.2f `ggtrainmat'[`traingrbase'+4,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`traingrow',`c_esst'+8] "%" "`cidataLsp'" "[" ///
						%6.2f `ggloomat'[`traingrbase'+4,1] "%" "`cimidpadsp'" " " %6.2f `ggloomat'[`traingrbase'+4,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`g',`c_esst'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggloomat'[`grbase'+4,1] "%" "`cimidpadsp'" " " %6.2f `ggloomat'[`grbase'+4,2] "%]" ///
						"`cidataRsp'"
					di as text "{hline `citotalw_loo3'}"
				}
				else if `crossholdci' {
					di as text "{hline `citotalw_loo'}"
										di as text %-24s "" %8s "" "  " "`boothdrLsp'" "Bootstrap" "`boothdrRsp'" "  " %8s "" "  " ///
						"`boothdrLsp'" "Bootstrap" "`boothdrRsp'"
										di as text %-24s "Performance Index" %8s "Train" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'" ///
						"  " %8s "Hold" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'"
					di as text "{hline `citotalw_loo'}"
										di as text %-24s "Overall Accuracy" as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_over'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggtrainmat'[`traingrbase'+2,1] "%" "`cimidpadsp'" " " %6.2f `ggtrainmat'[`traingrbase'+2,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`g',`c_over'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggloomat'[`grbase'+2,1] "%" "`cimidpadsp'" " " %6.2f `ggloomat'[`grbase'+2,2] "%]" ///
						"`cidataRsp'"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
												di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `gpactr'[`traingrow',`k'] "%" ///
							"`cidataLsp'" "[" %6.2f `ggtrainpacmat'[`traingrbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggtrainpacmat'[`traingrbasek'+`k',2] "%]" "`cidataRsp'" "  " %7.2f `gpactr'[`g',`k'] "%" ///
							"`cidataLsp'" "[" %6.2f `ggloopacmat'[`grbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggloopacmat'[`grbasek'+`k',2] "%]" "`cidataRsp'"
					}
										di as text %-24s "Effect Strength PAC" as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_essp'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggtrainmat'[`traingrbase'+1,1] "%" "`cimidpadsp'" " " %6.2f `ggtrainmat'[`traingrbase'+1,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`g',`c_essp'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggloomat'[`grbase'+1,1] "%" "`cimidpadsp'" " " %6.2f `ggloomat'[`grbase'+1,2] "%]" ///
						"`cidataRsp'"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
												di as text %-24s "PV `CLASSU'=`kk'"  as result %7.2f `gpvtr'[`traingrow',`k'] "%" ///
							"`cidataLsp'" "[" %6.2f `ggtrainpvmat'[`traingrbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggtrainpvmat'[`traingrbasek'+`k',2] "%]" "`cidataRsp'" "  " %7.2f `gpvtr'[`g',`k'] "%" ///
							"`cidataLsp'" "[" %6.2f `ggloopvmat'[`grbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggloopvmat'[`grbasek'+`k',2] "%]" "`cidataRsp'"
					}
										di as text %-24s "Effect Strength PV"    as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_essv'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggtrainmat'[`traingrbase'+3,1] "%" "`cimidpadsp'" " " %6.2f `ggtrainmat'[`traingrbase'+3,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`g',`c_essv'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggloomat'[`grbase'+3,1] "%" "`cimidpadsp'" " " %6.2f `ggloomat'[`grbase'+3,2] "%]" ///
						"`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_esst'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggtrainmat'[`traingrbase'+4,1] "%" "`cimidpadsp'" " " %6.2f `ggtrainmat'[`traingrbase'+4,2] ///
						"%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`g',`c_esst'] "%" "`cidataLsp'" "[" %6.2f ///
						`ggloomat'[`grbase'+4,1] "%" "`cimidpadsp'" " " %6.2f `ggloomat'[`grbase'+4,2] "%]" ///
						"`cidataRsp'"
					di as text "{hline `citotalw_loo'}"
				}
				else if "`loo'" != "" {
					di as text "{hline 52}"
					di as text %-24s "Performance Index" "   Train       LOO      Hold"
					di as text "{hline 52}"
										di as text %-24s "Overall Accuracy" as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_over'] "%  " %7.2f r_K_gen_breakdown[`traingrow',`c_over'+8] ///
						"%  " %7.2f r_K_gen_breakdown[`g',`c_over'] "%"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
												di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `gpactr'[`traingrow',`k'] "%  " ///
							%7.2f `gpaclo'[`traingrow',`k'] "%  " %7.2f `gpactr'[`g',`k'] "%"
					}
										di as text %-24s "Effect Strength PAC" as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_essp'] "%  " %7.2f r_K_gen_breakdown[`traingrow',`c_essp'+8] ///
						"%  " %7.2f r_K_gen_breakdown[`g',`c_essp'] "%"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
												di as text %-24s "PV `CLASSU'=`kk'"  as result %7.2f `gpvtr'[`traingrow',`k'] "%  " ///
							%7.2f `gpvlo'[`traingrow',`k'] "%  " %7.2f `gpvtr'[`g',`k'] "%"
					}
										di as text %-24s "Effect Strength PV"    as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_essv'] "%  " %7.2f r_K_gen_breakdown[`traingrow',`c_essv'+8] ///
						"%  " %7.2f r_K_gen_breakdown[`g',`c_essv'] "%"
										di as text %-24s "Effect Strength Total" as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_esst'] "%  " %7.2f r_K_gen_breakdown[`traingrow',`c_esst'+8] ///
						"%  " %7.2f r_K_gen_breakdown[`g',`c_esst'] "%"
					di as text "{hline 52}"
				}
				else {
					di as text "{hline 42}"
					di as text %-24s "Performance Index" "   Train      Hold"
					di as text "{hline 42}"
										di as text %-24s "Overall Accuracy" as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_over'] "%  " %7.2f r_K_gen_breakdown[`g',`c_over'] "%"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
												di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `gpactr'[`traingrow',`k'] "%  " ///
							%7.2f `gpactr'[`g',`k'] "%"
					}
										di as text %-24s "Effect Strength PAC" as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_essp'] "%  " %7.2f r_K_gen_breakdown[`g',`c_essp'] "%"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
												di as text %-24s "PV `CLASSU'=`kk'"  as result %7.2f `gpvtr'[`traingrow',`k'] "%  " ///
							%7.2f `gpvtr'[`g',`k'] "%"
					}
										di as text %-24s "Effect Strength PV"    as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_essv'] "%  " %7.2f r_K_gen_breakdown[`g',`c_essv'] "%"
										di as text %-24s "Effect Strength Total" as result %7.2f ///
						r_K_gen_breakdown[`traingrow',`c_esst'] "%  " %7.2f r_K_gen_breakdown[`g',`c_esst'] "%"
					di as text "{hline 42}"
				}
			}
			else if "`loo'" != "" {
				if `ciflag' & !`fitfailed' {
					di as text "{hline `citotalw_loo'}"
										di as text %-24s "" %8s "" "  " "`boothdrLsp'" "Bootstrap" "`boothdrRsp'" "  " %8s "" "  " ///
						"`boothdrLsp'" "Bootstrap" "`boothdrRsp'"
										di as text %-24s "Performance Index" %8s "Train" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'" ///
						"  " %8s "LOO" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'"
					di as text "{hline `citotalw_loo'}"
										di as text %-24s "Overall Accuracy" as result %7.2f r_K_gen_breakdown[`g',`c_over'] "%" ///
						"`cidataLsp'" "[" %6.2f `ggtrainmat'[`grbase'+2,1] "%" "`cimidpadsp'" " " %6.2f ///
						`ggtrainmat'[`grbase'+2,2] "%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`g',`c_over'+8] "%" ///
						"`cidataLsp'" "[" %6.2f `ggloomat'[`grbase'+2,1] "%" "`cimidpadsp'" " " %6.2f ///
						`ggloomat'[`grbase'+2,2] "%]" "`cidataRsp'"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
												di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `gpactr'[`g',`k'] "%" "`cidataLsp'" ///
							"[" %6.2f `ggtrainpacmat'[`grbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggtrainpacmat'[`grbasek'+`k',2] "%]" "`cidataRsp'" "  " %7.2f `gpaclo'[`g',`k'] "%" ///
							"`cidataLsp'" "[" %6.2f `ggloopacmat'[`grbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggloopacmat'[`grbasek'+`k',2] "%]" "`cidataRsp'"
					}
										di as text %-24s "Effect Strength PAC" as result %7.2f r_K_gen_breakdown[`g',`c_essp'] "%" ///
						"`cidataLsp'" "[" %6.2f `ggtrainmat'[`grbase'+1,1] "%" "`cimidpadsp'" " " %6.2f ///
						`ggtrainmat'[`grbase'+1,2] "%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`g',`c_essp'+8] "%" ///
						"`cidataLsp'" "[" %6.2f `ggloomat'[`grbase'+1,1] "%" "`cimidpadsp'" " " %6.2f ///
						`ggloomat'[`grbase'+1,2] "%]" "`cidataRsp'"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
												di as text %-24s "PV `CLASSU'=`kk'"  as result %7.2f `gpvtr'[`g',`k'] "%" "`cidataLsp'" ///
							"[" %6.2f `ggtrainpvmat'[`grbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggtrainpvmat'[`grbasek'+`k',2] "%]" "`cidataRsp'" "  " %7.2f `gpvlo'[`g',`k'] "%" ///
							"`cidataLsp'" "[" %6.2f `ggloopvmat'[`grbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggloopvmat'[`grbasek'+`k',2] "%]" "`cidataRsp'"
					}
										di as text %-24s "Effect Strength PV"    as result %7.2f r_K_gen_breakdown[`g',`c_essv'] ///
						"%" "`cidataLsp'" "[" %6.2f `ggtrainmat'[`grbase'+3,1] "%" "`cimidpadsp'" " " %6.2f ///
						`ggtrainmat'[`grbase'+3,2] "%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`g',`c_essv'+8] "%" ///
						"`cidataLsp'" "[" %6.2f `ggloomat'[`grbase'+3,1] "%" "`cimidpadsp'" " " %6.2f ///
						`ggloomat'[`grbase'+3,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f r_K_gen_breakdown[`g',`c_esst'] ///
						"%" "`cidataLsp'" "[" %6.2f `ggtrainmat'[`grbase'+4,1] "%" "`cimidpadsp'" " " %6.2f ///
						`ggtrainmat'[`grbase'+4,2] "%]" "`cidataRsp'" "  " %7.2f r_K_gen_breakdown[`g',`c_esst'+8] "%" ///
						"`cidataLsp'" "[" %6.2f `ggloomat'[`grbase'+4,1] "%" "`cimidpadsp'" " " %6.2f ///
						`ggloomat'[`grbase'+4,2] "%]" "`cidataRsp'"
					di as text "{hline `citotalw_loo'}"
				}
				else {
					di as text "{hline 42}"
					di as text %-24s "Performance Index" "   Train       LOO"
					di as text "{hline 42}"
										di as text %-24s "Overall Accuracy" as result %7.2f r_K_gen_breakdown[`g',`c_over'] "%  " ///
						%7.2f r_K_gen_breakdown[`g',`c_over'+8] "%"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
												di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `gpactr'[`g',`k'] "%  " %7.2f ///
							`gpaclo'[`g',`k'] "%"
					}
										di as text %-24s "Effect Strength PAC" as result %7.2f r_K_gen_breakdown[`g',`c_essp'] ///
						"%  " %7.2f r_K_gen_breakdown[`g',`c_essp'+8] "%"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
												di as text %-24s "PV `CLASSU'=`kk'"  as result %7.2f `gpvtr'[`g',`k'] "%  " %7.2f ///
							`gpvlo'[`g',`k'] "%"
					}
										di as text %-24s "Effect Strength PV"    as result %7.2f r_K_gen_breakdown[`g',`c_essv'] ///
						"%  " %7.2f r_K_gen_breakdown[`g',`c_essv'+8] "%"
										di as text %-24s "Effect Strength Total" as result %7.2f r_K_gen_breakdown[`g',`c_esst'] ///
						"%  " %7.2f r_K_gen_breakdown[`g',`c_esst'+8] "%"
					di as text "{hline 42}"
				}
			}
			else {
				if `ciflag' & !`fitfailed' {
					di as text "{hline `citotalw_noloo'}"
					di as text %-24s "" %8s "" "  " "`boothdrLsp'" "Bootstrap" "`boothdrRsp'"
					di as text %-24s "Performance Index" %8s "Train" "  " "`cihdrLsp'" "`cihdr'" "`cihdrRsp'"
					di as text "{hline `citotalw_noloo'}"
										di as text %-24s "Overall Accuracy" as result %7.2f r_K_gen_breakdown[`g',`c_over'] "%" ///
						"`cidataLsp'" "[" %6.2f `ggtrainmat'[`grbase'+2,1] "%" "`cimidpadsp'" " " %6.2f ///
						`ggtrainmat'[`grbase'+2,2] "%]" "`cidataRsp'"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
												di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `gpactr'[`g',`k'] "%" "`cidataLsp'" ///
							"[" %6.2f `ggtrainpacmat'[`grbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggtrainpacmat'[`grbasek'+`k',2] "%]" "`cidataRsp'"
					}
										di as text %-24s "Effect Strength PAC" as result %7.2f r_K_gen_breakdown[`g',`c_essp'] "%" ///
						"`cidataLsp'" "[" %6.2f `ggtrainmat'[`grbase'+1,1] "%" "`cimidpadsp'" " " %6.2f ///
						`ggtrainmat'[`grbase'+1,2] "%]" "`cidataRsp'"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
												di as text %-24s "PV `CLASSU'=`kk'"  as result %7.2f `gpvtr'[`g',`k'] "%" "`cidataLsp'" ///
							"[" %6.2f `ggtrainpvmat'[`grbasek'+`k',1] "%" "`cimidpadsp'" " " %6.2f ///
							`ggtrainpvmat'[`grbasek'+`k',2] "%]" "`cidataRsp'"
					}
										di as text %-24s "Effect Strength PV"    as result %7.2f r_K_gen_breakdown[`g',`c_essv'] ///
						"%" "`cidataLsp'" "[" %6.2f `ggtrainmat'[`grbase'+3,1] "%" "`cimidpadsp'" " " %6.2f ///
						`ggtrainmat'[`grbase'+3,2] "%]" "`cidataRsp'"
										di as text %-24s "Effect Strength Total" as result %7.2f r_K_gen_breakdown[`g',`c_esst'] ///
						"%" "`cidataLsp'" "[" %6.2f `ggtrainmat'[`grbase'+4,1] "%" "`cimidpadsp'" " " %6.2f ///
						`ggtrainmat'[`grbase'+4,2] "%]" "`cidataRsp'"
					di as text "{hline `citotalw_noloo'}"
				}
				else {
					di as text "{hline 32}"
					di as text %-24s "Performance Index" "   Train"
					di as text "{hline 32}"
					di as text %-24s "Overall Accuracy" as result %7.2f r_K_gen_breakdown[`g',`c_over'] "%"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
						di as text %-24s "PAC `CLASSU'=`kk'" as result %7.2f `gpactr'[`g',`k'] "%"
					}
					di as text %-24s "Effect Strength PAC" as result %7.2f r_K_gen_breakdown[`g',`c_essp'] "%"
					forvalues k = 1/`Klev' {
						local kkval = r_K_cvals[`k',1]
						local kk : label (`class') `kkval'
						di as text %-24s "PV `CLASSU'=`kk'"  as result %7.2f `gpvtr'[`g',`k'] "%"
					}
					di as text %-24s "Effect Strength PV"    as result %7.2f r_K_gen_breakdown[`g',`c_essv'] "%"
					di as text %-24s "Effect Strength Total" as result %7.2f r_K_gen_breakdown[`g',`c_esst'] "%"
					di as text "{hline 32}"
				}
			}
		}
		if `crossflag' & `niter' > 0 & !`fitfailed' {
						di _n as text ///
				"Cross-sample significance test (Monte Carlo, `niter' iterations, Sidak `crosssidak'):"
			forvalues g = 1/`ncrosssig' {
				local sgvval = r_cross_sig[`g',1]
				local sgv : label (`gen') `sgvval'
				local sgn = string(r_cross_sig[`g',2], "%9.0f")
				local srawp = r_cross_sig[`g',3]
				local sadjp = 1-(1-`srawp')^`crosssidak'
				local stag ""
				if `sgvval' == `crosstrain' local stag "[TRAINING SAMPLE]"
				else                         local stag "[HOLDOUT]"
								di as text "  `GENU'=`sgv' (N=`sgn') `stag'" _col(40) "raw p=" as result %9.6f `srawp' as ///
					text "   Sidak-adj p=" as result %9.6f `sadjp'
			}
		}
		else if `crossflag' {
			di _n as text "Note: a cross-sample significance test requires trainreps() to be specified."
		}
	}

	if "`store'" != "" qui log close oda_store

end

version 14.0
mata:
mata clear

real colvector odam_candidates(real colvector a, real scalar degen)
{
	real scalar nu, i
	real colvector uvals, cps
	uvals = uniqrows(a)
	nu = rows(uvals)
	cps = J(0,1,.)
	for (i=1; i<=nu-1; i++) {
		cps = cps \ ((uvals[i]+uvals[i+1])/2)
	}
	if (degen & nu>0) {
		if (rows(cps)==0) cps = (uvals[1]-1) \ (uvals[nu]+1)
		else cps = (uvals[1]-1) \ cps \ (uvals[nu]+1)
	}
	return(cps)
}

real rowvector odam_eval(real colvector c1, real colvector a, real colvector w,
	real scalar cp, real scalar dirn, real scalar priors)
{
	real colvector pred
	real scalar W1, W0, TP, FN, TN, FP, sens, spec, macc, ess

	if (dirn==1) pred = (a :> cp)
	else         pred = (a :<= cp)

	W1 = sum(w :* (c1:==1))
	W0 = sum(w :* (c1:==0))
	if (W1==0 | W0==0) return(J(1,9,.))

	TP = sum(w :* (c1:==1) :* (pred:==1))
	FN = W1 - TP
	TN = sum(w :* (c1:==0) :* (pred:==0))
	FP = W0 - TN

	sens = TP/W1
	spec = TN/W0
	if (priors) macc = (sens+spec)/2*100
	else        macc = (TP+TN)/(W1+W0)*100
	ess = (macc-50)/50*100

	return((cp, dirn, ess, sens, spec, TP, FN, TN, FP))
}

real matrix odam_tiebreak(real matrix tied, string scalar crit,
	real colvector c1, real colvector a, real colvector w)
{
	real scalar i, W1, W0, actualprop, best, n
	real colvector metric, predprop, margin, p, as
	real matrix out

	n = rows(tied)
	if (n<=1) return(tied)

	if (crit=="maxsens" | crit=="meansens" | crit=="genmean" | crit=="balanced" |
	    crit=="samplerep" | crit=="distance" | crit=="gensens") {
		metric = J(n,1,0)
		for (i=1; i<=n; i++) {
			if (tied[i,2]==-1) {
				if (tied[i,6]+tied[i,9] > 0) metric[i] = tied[i,6] / (tied[i,6]+tied[i,9])
			}
			else {
				if (tied[i,8]+tied[i,7] > 0) metric[i] = tied[i,8] / (tied[i,8]+tied[i,7])
			}
		}
		best = max(metric)
		out = select(tied, abs(metric:-best):<1e-9)
		return(out)
	}
	if (crit=="sens_hi" | crit=="sens_lo") {
		if (crit=="sens_hi") metric = tied[.,4]
		else                 metric = tied[.,5]
		best = max(metric)
		out = select(tied, abs(metric:-best):<1e-9)
		return(out)
	}
	if (crit=="random") {
		i = ceil(uniform(1,1)*n)
		return(tied[i,.])
	}
	return(tied)
}

real rowvector odam_best(real colvector c1, real colvector a, real colvector w,
	real scalar priors, real scalar degen, real scalar dirconstraint,
	string scalar primary, string scalar secondary, real scalar wtdsearch)
{
	real colvector p, as, c1s, ws, cum1, cum0, cum1e, cum0e
	real colvector uvals, grpend, cps, idxs, c1v, c0v
	real colvector TP1,TN1,FN1,FP1,sens1,spec1,macc1,ess1
	real colvector TP2,TN2,FN2,FP2,sens2,spec2,macc2,ess2
	real matrix results, rows1, rows2, tied
	real scalar n, nu, k, pos, W1, W0, nc, maxess

	n = rows(a)
	W1 = sum(w :* (c1:==1))
	W0 = sum(w :* (c1:==0))
	if (W1==0 | W0==0 | n==0) return(J(1,9,.))

	p = order(a,1)
	as = a[p]; c1s = c1[p]; ws = w[p]
	cum1 = runningsum(ws :* (c1s:==1))
	cum0 = runningsum(ws :* (c1s:==0))
	cum1e = (0) \ cum1
	cum0e = (0) \ cum0

	uvals = uniqrows(as)
	nu = rows(uvals)

	grpend = J(nu,1,.)
	pos = 1
	for (k=1; k<=nu; k++) {
		while (pos<=n) {
			if (as[pos]!=uvals[k]) break
			pos++
		}
		grpend[k] = pos-1
	}

	cps  = J(0,1,.)
	idxs = J(0,1,.)
	for (k=1; k<=nu-1; k++) {
		cps  = cps  \ ((uvals[k]+uvals[k+1])/2)
		idxs = idxs \ grpend[k]
	}
	if (degen & nu>0) {
		if (rows(cps)==0) {
			cps  = (uvals[1]-1) \ (uvals[nu]+1)
			idxs = (0)          \ (n)
		}
		else {
			cps  = (uvals[1]-1) \ cps  \ (uvals[nu]+1)
			idxs = (0)          \ idxs \ (n)
		}
	}
	if (rows(cps)==0) return(J(1,9,.))
	nc = rows(cps)

	c1v = cum1e[idxs :+ 1]
	c0v = cum0e[idxs :+ 1]

	results = J(0,9,.)
	if (dirconstraint==0 | dirconstraint==1) {
		TP1 = J(nc,1,W1) :- c1v
		TN1 = c0v
		FN1 = c1v
		FP1 = J(nc,1,W0) :- c0v
		sens1 = TP1 :/ W1
		spec1 = TN1 :/ W0
		if (priors) macc1 = (sens1 :+ spec1) :/ 2 :* 100
		else         macc1 = (TP1 :+ TN1) :/ (W1+W0) :* 100
		ess1 = (macc1 :- 50) :/ 50 :* 100
		rows1 = (cps, J(nc,1,1), ess1, sens1, spec1, TP1, FN1, TN1, FP1)
		results = results \ rows1
	}
	if (dirconstraint==0 | dirconstraint==-1) {
		TP2 = c1v
		TN2 = J(nc,1,W0) :- c0v
		FN2 = J(nc,1,W1) :- c1v
		FP2 = c0v
		sens2 = TP2 :/ W1
		spec2 = TN2 :/ W0
		if (priors) macc2 = (sens2 :+ spec2) :/ 2 :* 100
		else         macc2 = (TP2 :+ TN2) :/ (W1+W0) :* 100
		ess2 = (macc2 :- 50) :/ 50 :* 100
		rows2 = (cps, J(nc,1,-1), ess2, sens2, spec2, TP2, FN2, TN2, FP2)
		results = results \ rows2
	}
	if (rows(results)==0) return(J(1,9,.))

	maxess = max(results[.,3])
	tied = select(results, abs(results[.,3]:-maxess):<1e-8)
	if (rows(tied)>1) {
		tied = odam_tiebreak(tied, primary, c1,a,w)
	}
	if (rows(tied)>1) {
		tied = odam_tiebreak(tied, secondary, c1,a,w)
	}
	return(tied[1,.])
}

void odam_dots_header(string scalar txt)
{
	stata("di _n as text " + char(34) + txt + char(34))
}

real scalar odam_permtest(real colvector c1, real colvector a, real colvector w,
	real scalar priors, real scalar degen, real scalar dirconstraint,
	string scalar primary, string scalar secondary,
	real scalar obsess, real scalar niter, real scalar dots, real scalar wtdsearch)
{
	real scalar r, cnt, n
	real colvector c1p
	real rowvector best

	n = rows(c1)
	cnt = 0
	if (dots) {
		odam_dots_header("Monte Carlo permutation test (" + strofreal(niter) + " iterations):")
		stata("_dots 0 0")
	}
	for (r=1; r<=niter; r++) {
		c1p = c1[jumble(1::n)]
		best = odam_best(c1p, a, w, priors, degen, dirconstraint, primary, secondary, wtdsearch)
		if (best[1,3]!=. & best[1,3] >= obsess) cnt++
		if (dots) stata("_dots " + strofreal(r) + " 0")
	}
	return(cnt/niter)
}

real scalar odam_fisher_onesided(real scalar TP, real scalar FN, real scalar FP, real scalar TN)
{
	real scalar N, n1, m1, kmax, k, p, logC, logterm
	N  = TP+FN+FP+TN
	n1 = TP+FN
	m1 = TP+FP
	kmax = min((n1,m1))
	logC = lngamma(N+1) - lngamma(n1+1) - lngamma(N-n1+1)
	p = 0
	for (k=TP; k<=kmax; k++) {
		logterm = (lngamma(m1+1) - lngamma(k+1) - lngamma(m1-k+1)
			+ lngamma(N-m1+1) - lngamma(n1-k+1) - lngamma(N-m1-n1+k+1)
			- logC)
		p = p + exp(logterm)
	}
	return(p)
}

void odam_cat_scoretable(real colvector cat, real colvector c1, real colvector w,
	real colvector catvals, real colvector scores)
{
	real scalar nu, i, n1, n0
	catvals = uniqrows(cat)
	nu = rows(catvals)
	scores = J(nu,1,.)
	for (i=1; i<=nu; i++) {
		n1 = sum(w :* (cat:==catvals[i]) :* (c1:==1))
		n0 = sum(w :* (cat:==catvals[i]) :* (c1:==0))
		if (n1+n0>0) scores[i] = n1/(n1+n0)
	}
}

real colvector odam_cat_map(real colvector cat, real colvector catvals, real colvector scores)
{
	real colvector out
	real scalar n, k, i, j
	n = rows(cat)
	k = rows(catvals)
	out = J(n,1,.)
	for (i=1; i<=n; i++) {
		for (j=1; j<=k; j++) {
			if (catvals[j]==cat[i]) {
				out[i] = scores[j]
				break
			}
		}
	}
	return(out)
}

real rowvector odam_best_cat(real colvector c1, real colvector cat, real colvector w,
	real scalar priors, real scalar degen, real scalar dirconstraint,
	string scalar primary, string scalar secondary, real scalar wtdsearch)
{
	real colvector catvals, scores, a
	odam_cat_scoretable(cat, c1, w, catvals, scores)
	a = odam_cat_map(cat, catvals, scores)
	return(odam_best(c1, a, w, priors, degen, dirconstraint, primary, secondary, wtdsearch))
}

real scalar odam_permtest_cat(real colvector c1, real colvector cat, real colvector w,
	real scalar priors, real scalar degen, real scalar dirconstraint,
	string scalar primary, string scalar secondary,
	real scalar obsess, real scalar niter, real scalar dots, real scalar wtdsearch)
{
	real scalar r, cnt, n
	real colvector c1p, catvals, scores, ap
	real rowvector best

	n = rows(c1)
	cnt = 0
	if (dots) {
		odam_dots_header("Monte Carlo permutation test (" + strofreal(niter) + " iterations):")
		stata("_dots 0 0")
	}
	for (r=1; r<=niter; r++) {
		c1p = c1[jumble(1::n)]
		odam_cat_scoretable(cat, c1p, w, catvals, scores)
		ap = odam_cat_map(cat, catvals, scores)
		best = odam_best(c1p, ap, w, priors, degen, dirconstraint, primary, secondary, wtdsearch)
		if (best[1,3]!=. & best[1,3] >= obsess) cnt++
		if (dots) stata("_dots " + strofreal(r) + " 0")
	}
	return(cnt/niter)
}

void odam_loo_cat(real colvector c1, real colvector cat, real colvector wsearch, real colvector wreport,
	real scalar priors, real scalar degen, real scalar dirconstraint,
	string scalar primary, string scalar secondary,
	real scalar ess_loo, real scalar sens_loo, real scalar spec_loo,
	real scalar TPl, real scalar FNl, real scalar TNl, real scalar FPl,
	real scalar ess_loo_wtd, real scalar sens_loo_wtd, real scalar spec_loo_wtd,
	real scalar TPlw, real scalar FNlw, real scalar TNlw, real scalar FPlw,
	real scalar dots, real scalar wtdsearch, real colvector loopred)
{
	real scalar n, i, j, k, pred, myscore
	real colvector idx, c1sub, catsub, wsub, asub, catvals, scores
	real rowvector best

	n = rows(c1)
	TPl=0; FNl=0; TNl=0; FPl=0
	TPlw=0; FNlw=0; TNlw=0; FPlw=0
	loopred = J(n,1,.)
	if (dots) {
		odam_dots_header("Leave-one-out cross-validation (" + strofreal(n) + " observations):")
		stata("_dots 0 0")
	}
	for (i=1; i<=n; i++) {
		idx = select(1::n, (1::n):!=i)
		c1sub = c1[idx]; catsub = cat[idx]
		if (wtdsearch) wsub = wreport[idx]
		else           wsub = wsearch[idx]
		odam_cat_scoretable(catsub, c1sub, wsub, catvals, scores)
		myscore = .
		k = rows(catvals)
		for (j=1; j<=k; j++) {
			if (catvals[j]==cat[i]) {
				myscore = scores[j]
				break
			}
		}
		if (myscore==.) {
			if (dots) stata("_dots " + strofreal(i) + " 0")
			continue
		}
		asub = odam_cat_map(catsub, catvals, scores)
		best = odam_best(c1sub, asub, wsub, priors, degen, dirconstraint, primary, secondary, wtdsearch)
		if (best[1,3]==.) {
			if (dots) stata("_dots " + strofreal(i) + " 0")
			continue
		}
		if (best[1,2]==1) pred = (myscore > best[1,1])
		else              pred = (myscore < best[1,1])
		loopred[i] = pred
		if (c1[i]==1 & pred==1) {
			TPl = TPl + 1
			TPlw = TPlw + wreport[i]
		}
		if (c1[i]==1 & pred==0) {
			FNl = FNl + 1
			FNlw = FNlw + wreport[i]
		}
		if (c1[i]==0 & pred==0) {
			TNl = TNl + 1
			TNlw = TNlw + wreport[i]
		}
		if (c1[i]==0 & pred==1) {
			FPl = FPl + 1
			FPlw = FPlw + wreport[i]
		}
		if (dots) stata("_dots " + strofreal(i) + " 0")
	}
	sens_loo = TPl/(TPl+FNl)
	spec_loo = TNl/(TNl+FPl)
	ess_loo = ((sens_loo+spec_loo)/2*100 - 50)/50*100
	sens_loo_wtd = TPlw/(TPlw+FNlw)
	spec_loo_wtd = TNlw/(TNlw+FPlw)
	ess_loo_wtd = ((sens_loo_wtd+spec_loo_wtd)/2*100 - 50)/50*100
}

real scalar odam_permtest_loo_cat(real colvector c1, real colvector cat, real colvector wsearch,
	real colvector wreport, real scalar priors, real scalar degen, real scalar dirconstraint,
	string scalar primary, string scalar secondary, real scalar wtdsearch,
	real scalar obsmacc, real scalar niter, real scalar dots)
{
	real scalar n, r, cnt, ntot, macc_p
	real scalar ess_p, sens_p, spec_p, TPl, FNl, TNl, FPl
	real scalar ess_pw, sens_pw, spec_pw, TPlw, FNlw, TNlw, FPlw
	real colvector c1p, loopred_p

	n = rows(c1)
	cnt = 0
	if (dots) {
		odam_dots_header("LOO permutation test (" + strofreal(niter) + " iterations, " + strofreal(n) + " LOO refits each):")
		stata("_dots 0 0")
	}
	for (r=1; r<=niter; r++) {
		c1p = c1[jumble(1::n)]
		odam_loo_cat(c1p, cat, wsearch, wreport, priors, degen, dirconstraint, primary, secondary,
			ess_p, sens_p, spec_p, TPl, FNl, TNl, FPl,
			ess_pw, sens_pw, spec_pw, TPlw, FNlw, TNlw, FPlw, 0, wtdsearch, loopred_p)
		ntot = TPl+FNl+TNl+FPl
		if (ntot>0) {
			macc_p = (priors ? (sens_p+spec_p)/2 : (TPl+TNl)/ntot)
			if (macc_p!=. & macc_p >= obsmacc) cnt++
		}
		if (dots) stata("_dots " + strofreal(r) + " 0")
	}
	return(cnt/niter)
}

string scalar odam_vec2str(real colvector v)
{
	string scalar s
	real scalar i
	s = ""
	for (i=1; i<=rows(v); i++) {
		if (i>1) s = s + " "
		s = s + strofreal(v[i])
	}
	return(s)
}

void odam_loo(real colvector c1, real colvector a, real colvector wsearch, real colvector wreport,
	real scalar priors, real scalar degen, real scalar dirconstraint,
	string scalar primary, string scalar secondary,
	real scalar ess_loo, real scalar sens_loo, real scalar spec_loo,
	real scalar TPl, real scalar FNl, real scalar TNl, real scalar FPl,
	real scalar ess_loo_wtd, real scalar sens_loo_wtd, real scalar spec_loo_wtd,
	real scalar TPlw, real scalar FNlw, real scalar TNlw, real scalar FPlw,
	real scalar dots, real scalar wtdsearch, real colvector loopred)
{
	real scalar n, i, pred
	real colvector idx, c1sub, asub, wsub
	real rowvector best

	n = rows(c1)
	TPl=0; FNl=0; TNl=0; FPl=0
	TPlw=0; FNlw=0; TNlw=0; FPlw=0
	loopred = J(n,1,.)
	if (dots) {
		odam_dots_header("Leave-one-out cross-validation (" + strofreal(n) + " observations):")
		stata("_dots 0 0")
	}
	for (i=1; i<=n; i++) {
		idx = select(1::n, (1::n):!=i)
		c1sub = c1[idx]; asub = a[idx]
		if (wtdsearch) wsub = wreport[idx]
		else           wsub = wsearch[idx]
		best = odam_best(c1sub, asub, wsub, priors, degen, dirconstraint, primary, secondary, wtdsearch)
		if (best[1,3]==.) {
			if (dots) stata("_dots " + strofreal(i) + " 0")
			continue
		}
		if (best[1,2]==1) pred = (a[i] > best[1,1])
		else              pred = (a[i] <= best[1,1])
		loopred[i] = pred
		if (c1[i]==1 & pred==1) {
			TPl = TPl + 1
			TPlw = TPlw + wreport[i]
		}
		if (c1[i]==1 & pred==0) {
			FNl = FNl + 1
			FNlw = FNlw + wreport[i]
		}
		if (c1[i]==0 & pred==0) {
			TNl = TNl + 1
			TNlw = TNlw + wreport[i]
		}
		if (c1[i]==0 & pred==1) {
			FPl = FPl + 1
			FPlw = FPlw + wreport[i]
		}
		if (dots) stata("_dots " + strofreal(i) + " 0")
	}
	sens_loo = TPl/(TPl+FNl)
	spec_loo = TNl/(TNl+FPl)
	sens_loo_wtd = TPlw/(TPlw+FNlw)
	spec_loo_wtd = TNlw/(TNlw+FPlw)
	ess_loo_wtd = ((sens_loo_wtd+spec_loo_wtd)/2*100 - 50)/50*100
	ess_loo = ((sens_loo+spec_loo)/2*100 - 50)/50*100
}

real scalar odam_permtest_loo(real colvector c1, real colvector a, real colvector wsearch,
	real colvector wreport, real scalar priors, real scalar degen, real scalar dirconstraint,
	string scalar primary, string scalar secondary, real scalar wtdsearch,
	real scalar obsmacc, real scalar niter, real scalar dots)
{
	real scalar n, r, cnt, ntot, macc_p
	real scalar ess_p, sens_p, spec_p, TPl, FNl, TNl, FPl
	real scalar ess_pw, sens_pw, spec_pw, TPlw, FNlw, TNlw, FPlw
	real colvector c1p, loopred_p

	n = rows(c1)
	cnt = 0
	if (dots) {
		odam_dots_header("LOO permutation test (" + strofreal(niter) + " iterations, " + strofreal(n) + " LOO refits each):")
		stata("_dots 0 0")
	}
	for (r=1; r<=niter; r++) {
		c1p = c1[jumble(1::n)]
		odam_loo(c1p, a, wsearch, wreport, priors, degen, dirconstraint, primary, secondary,
			ess_p, sens_p, spec_p, TPl, FNl, TNl, FPl,
			ess_pw, sens_pw, spec_pw, TPlw, FNlw, TNlw, FPlw, 0, wtdsearch, loopred_p)
		ntot = TPl+FNl+TNl+FPl
		if (ntot>0) {
			macc_p = (priors ? (sens_p+spec_p)/2 : (TPl+TNl)/ntot)
			if (macc_p!=. & macc_p >= obsmacc) cnt++
		}
		if (dots) stata("_dots " + strofreal(r) + " 0")
	}
	return(cnt/niter)
}

real matrix odam_permtest_loo_gen(real colvector c1, real colvector a, real colvector wsearch,
	real colvector wreport, real scalar priors, real scalar degen, real scalar dirconstraint,
	string scalar primary, string scalar secondary, real scalar wtdsearch,
	real colvector grp, real colvector grpvals, real colvector loopred,
	real scalar niter, real scalar dots)
{
	real scalar n, G, g, i, r, ntot, TPg, FNg, TNg, FPg, macc_p
	real scalar ess_p, sens_p, spec_p, TPl, FNl, TNl, FPl
	real scalar ess_pw, sens_pw, spec_pw, TPlw, FNlw, TNlw, FPlw
	real colvector c1p, loopred_p, cnt, obsmacc
	real matrix out

	n = rows(c1)
	G = rows(grpvals)
	cnt = J(G,1,0)
	obsmacc = J(G,1,.)
	for (g=1; g<=G; g++) {
		TPg=0; FNg=0; TNg=0; FPg=0
		for (i=1; i<=n; i++) {
			if (grp[i]!=grpvals[g] | loopred[i]==.) continue
			if (c1[i]==1 & loopred[i]==1) TPg++
			if (c1[i]==1 & loopred[i]==0) FNg++
			if (c1[i]==0 & loopred[i]==0) TNg++
			if (c1[i]==0 & loopred[i]==1) FPg++
		}
		ntot = TPg+FNg+TNg+FPg
		if (ntot>0) {
			if (priors & (TPg+FNg)>0 & (TNg+FPg)>0) obsmacc[g] = (TPg/(TPg+FNg) + TNg/(TNg+FPg))/2
			else if (!priors)                        obsmacc[g] = (TPg+TNg)/ntot
		}
	}
	if (dots) {
		odam_dots_header("Generalizability LOO permutation test (" + strofreal(niter) + " iterations, " + strofreal(n) + " LOO refits each):")
		stata("_dots 0 0")
	}
	for (r=1; r<=niter; r++) {
		c1p = c1[jumble(1::n)]
		odam_loo(c1p, a, wsearch, wreport, priors, degen, dirconstraint, primary, secondary,
			ess_p, sens_p, spec_p, TPl, FNl, TNl, FPl,
			ess_pw, sens_pw, spec_pw, TPlw, FNlw, TNlw, FPlw, 0, wtdsearch, loopred_p)
		for (g=1; g<=G; g++) {
			if (obsmacc[g]==.) continue
			TPg=0; FNg=0; TNg=0; FPg=0
			for (i=1; i<=n; i++) {
				if (grp[i]!=grpvals[g] | loopred_p[i]==.) continue
				if (c1p[i]==1 & loopred_p[i]==1) TPg++
				if (c1p[i]==1 & loopred_p[i]==0) FNg++
				if (c1p[i]==0 & loopred_p[i]==0) TNg++
				if (c1p[i]==0 & loopred_p[i]==1) FPg++
			}
			ntot = TPg+FNg+TNg+FPg
			if (ntot==0) continue
			if (priors) macc_p = ((TPg+FNg)>0 & (TNg+FPg)>0 ? (TPg/(TPg+FNg) + TNg/(TNg+FPg))/2 : .)
			else         macc_p = (TPg+TNg)/ntot
			if (macc_p!=. & macc_p >= obsmacc[g]) cnt[g] = cnt[g] + 1
		}
		if (dots) stata("_dots " + strofreal(r) + " 0")
	}
	out = J(G,2,.)
	out[.,1] = grpvals
	for (g=1; g<=G; g++) out[g,2] = (obsmacc[g]!=. ? cnt[g]/niter : .)
	return(out)
}

real matrix odam_permtest_loo_gen_cat(real colvector c1, real colvector cat, real colvector wsearch,
	real colvector wreport, real scalar priors, real scalar degen, real scalar dirconstraint,
	string scalar primary, string scalar secondary, real scalar wtdsearch,
	real colvector grp, real colvector grpvals, real colvector loopred,
	real scalar niter, real scalar dots)
{
	real scalar n, G, g, i, r, ntot, TPg, FNg, TNg, FPg, macc_p
	real scalar ess_p, sens_p, spec_p, TPl, FNl, TNl, FPl
	real scalar ess_pw, sens_pw, spec_pw, TPlw, FNlw, TNlw, FPlw
	real colvector c1p, loopred_p, cnt, obsmacc
	real matrix out

	n = rows(c1)
	G = rows(grpvals)
	cnt = J(G,1,0)
	obsmacc = J(G,1,.)
	for (g=1; g<=G; g++) {
		TPg=0; FNg=0; TNg=0; FPg=0
		for (i=1; i<=n; i++) {
			if (grp[i]!=grpvals[g] | loopred[i]==.) continue
			if (c1[i]==1 & loopred[i]==1) TPg++
			if (c1[i]==1 & loopred[i]==0) FNg++
			if (c1[i]==0 & loopred[i]==0) TNg++
			if (c1[i]==0 & loopred[i]==1) FPg++
		}
		ntot = TPg+FNg+TNg+FPg
		if (ntot>0) {
			if (priors & (TPg+FNg)>0 & (TNg+FPg)>0) obsmacc[g] = (TPg/(TPg+FNg) + TNg/(TNg+FPg))/2
			else if (!priors)                        obsmacc[g] = (TPg+TNg)/ntot
		}
	}
	if (dots) {
		odam_dots_header("Generalizability LOO permutation test (" + strofreal(niter) + " iterations, " + strofreal(n) + " LOO refits each):")
		stata("_dots 0 0")
	}
	for (r=1; r<=niter; r++) {
		c1p = c1[jumble(1::n)]
		odam_loo_cat(c1p, cat, wsearch, wreport, priors, degen, dirconstraint, primary, secondary,
			ess_p, sens_p, spec_p, TPl, FNl, TNl, FPl,
			ess_pw, sens_pw, spec_pw, TPlw, FNlw, TNlw, FPlw, 0, wtdsearch, loopred_p)
		for (g=1; g<=G; g++) {
			if (obsmacc[g]==.) continue
			TPg=0; FNg=0; TNg=0; FPg=0
			for (i=1; i<=n; i++) {
				if (grp[i]!=grpvals[g] | loopred_p[i]==.) continue
				if (c1p[i]==1 & loopred_p[i]==1) TPg++
				if (c1p[i]==1 & loopred_p[i]==0) FNg++
				if (c1p[i]==0 & loopred_p[i]==0) TNg++
				if (c1p[i]==0 & loopred_p[i]==1) FPg++
			}
			ntot = TPg+FNg+TNg+FPg
			if (ntot==0) continue
			if (priors) macc_p = ((TPg+FNg)>0 & (TNg+FPg)>0 ? (TPg/(TPg+FNg) + TNg/(TNg+FPg))/2 : .)
			else         macc_p = (TPg+TNg)/ntot
			if (macc_p!=. & macc_p >= obsmacc[g]) cnt[g] = cnt[g] + 1
		}
		if (dots) stata("_dots " + strofreal(r) + " 0")
	}
	out = J(G,2,.)
	out[.,1] = grpvals
	for (g=1; g<=G; g++) out[g,2] = (obsmacc[g]!=. ? cnt[g]/niter : .)
	return(out)
}

real rowvector odam_extra_metrics(real scalar TP, real scalar FN, real scalar TN,
	real scalar FP, real scalar ess_pac)
{
	real scalar N, overall, pv0, pv1, meanpv, ess_pv, ess_total
	N = TP+FN+TN+FP
	overall = (N>0 ? (TP+TN)/N*100 : .)
	pv0 = ((TN+FN)>0 ? TN/(TN+FN)*100 : .)
	pv1 = ((TP+FP)>0 ? TP/(TP+FP)*100 : .)
	if (pv0!=. & pv1!=.) {
		meanpv = (pv0+pv1)/2
		ess_pv = (meanpv-50)/50*100
	}
	else ess_pv = .
	ess_total = (ess_pac!=. & ess_pv!=. ? (ess_pac+ess_pv)/2 : .)
	return((overall, pv0, pv1, ess_pv, ess_total))
}

real scalar odam_boot_percentile(real colvector col, real scalar alpha)
{
	real colvector v
	real scalar m, pos, lo, hi, frac

	v = sort(select(col, col:!=.), 1)
	m = rows(v)
	if (m==0) return(.)
	if (m==1) return(v[1])

	pos = alpha*(m-1) + 1
	lo  = floor(pos)
	hi  = ceil(pos)
	frac = pos - lo
	if (lo<1) return(v[1])
	if (hi>m) return(v[m])
	return(v[lo] + frac*(v[hi]-v[lo]))
}

void odam_ci_driver(string scalar cvar, string scalar avar, string scalar wvar,
	string scalar istrainvar,
	real scalar priors, real scalar degen, real scalar dirconstraint,
	string scalar primary, string scalar secondary, real scalar wtdsearch,
	real scalar reps, real scalar doloo, real scalar cilevel, real scalar dots,
	string scalar gvar, real scalar iscat)
{
	real colvector c1, a, w, idx, isoob, c1b, ab, wb, wsb, c1oob, aoob, woob
	real rowvector best, roworig, extra, rowwtd, extrawtd, rowoob, extraoob, rowoobwtd, extraoobwtd
	real matrix trainboot, looboot, trainbootwtd, loobootwtd, boundstr, boundsloo, boundstrwtd, boundsloowtd
	real scalar n, r, i, j, alpha
	real colvector ist, trainidx, istoob, selidxtr
	real scalar ntrain
	real colvector catb, catvalsb, scoresb, aoobraw, validoob
	real colvector grp, gv, grpb, grpoob, selidx
	real scalar G, g, gengroups
	real matrix trainbootgen, trainbootgenwtd, loobootgen, loobootgenwtd
	real matrix boundstrgen, boundstrgenwtd, boundsloogen, boundsloogenwtd
	real rowvector rowg, extrag, rowgwtd, extragwtd, rowgoob, extragoob, rowgoobwtd, extragoobwtd
	real scalar docrossoob

	c1 = st_data(., cvar)
	a  = st_data(., avar)
	w  = st_data(., wvar)
	n  = rows(c1)
	ist = st_data(., istrainvar)
	trainidx = selectindex(ist:==1)
	ntrain = rows(trainidx)

	gengroups = (gvar!="")
	docrossoob = gengroups & (ntrain < n)
	if (gengroups) {
		grp = st_data(., gvar)
		gv  = uniqrows(grp)
		G   = rows(gv)
		trainbootgen    = J(reps, G*8, .)
		trainbootgenwtd = J(reps, G*8, .)
		loobootgen      = ((doloo | docrossoob) ? J(reps, G*8, .) : J(0, G*8, .))
		loobootgenwtd   = ((doloo | docrossoob) ? J(reps, G*8, .) : J(0, G*8, .))
	}

	trainboot    = J(reps,8,.)
	trainbootwtd = J(reps,8,.)
	looboot      = (doloo ? J(reps,8,.) : J(0,8,.))
	loobootwtd   = (doloo ? J(reps,8,.) : J(0,8,.))

	if (dots) {
		odam_dots_header("Bootstrap confidence intervals (" + strofreal(reps) + " replications):")
		stata("_dots 0 0")
	}
	for (r=1; r<=reps; r++) {
		idx = trainidx[ceil(uniform(ntrain,1)*ntrain)]
		c1b = c1[idx]
		wb  = w[idx]
		wsb = (wtdsearch ? wb : J(ntrain,1,1))

		if (iscat) {
			catb = a[idx]
			odam_cat_scoretable(catb, c1b, wsb, catvalsb, scoresb)
			ab = odam_cat_map(catb, catvalsb, scoresb)
		}
		else {
			ab = a[idx]
		}

		best = odam_best(c1b, ab, wsb, priors, degen, dirconstraint, primary, secondary, wtdsearch)
		if (best[1,3]==.) continue

		roworig = odam_eval(c1b, ab, J(ntrain,1,1), best[1,1], best[1,2], priors)
		if (roworig[1,3]!=.) {
			extra = odam_extra_metrics(roworig[1,6], roworig[1,7], roworig[1,8], roworig[1,9], roworig[1,3])
			trainboot[r,.] = (roworig[1,3], roworig[1,4]*100, roworig[1,5]*100, extra[1,1], extra[1,2], extra[1,3], extra[1,4], extra[1,5])
		}
		rowwtd = odam_eval(c1b, ab, wb, best[1,1], best[1,2], priors)
		if (rowwtd[1,3]!=.) {
			extrawtd = odam_extra_metrics(rowwtd[1,6], rowwtd[1,7], rowwtd[1,8], rowwtd[1,9], rowwtd[1,3])
			trainbootwtd[r,.] = (rowwtd[1,3], rowwtd[1,4]*100, rowwtd[1,5]*100, extrawtd[1,1], extrawtd[1,2], extrawtd[1,3], extrawtd[1,4], extrawtd[1,5])
		}

		if (gengroups) {
			grpb = grp[idx]
			for (g=1; g<=G; g++) {
				selidx = selectindex(grpb :== gv[g])
				if (rows(selidx)>0) {
					rowg = odam_eval(c1b[selidx], ab[selidx], J(rows(selidx),1,1), best[1,1], best[1,2], priors)
					if (rowg[1,3]!=.) {
						extrag = odam_extra_metrics(rowg[1,6], rowg[1,7], rowg[1,8], rowg[1,9], rowg[1,3])
						trainbootgen[r,(g-1)*8+1] = rowg[1,3]
						trainbootgen[r,(g-1)*8+2] = rowg[1,4]*100
						trainbootgen[r,(g-1)*8+3] = rowg[1,5]*100
						trainbootgen[r,(g-1)*8+4] = extrag[1,1]
						trainbootgen[r,(g-1)*8+5] = extrag[1,2]
						trainbootgen[r,(g-1)*8+6] = extrag[1,3]
						trainbootgen[r,(g-1)*8+7] = extrag[1,4]
						trainbootgen[r,(g-1)*8+8] = extrag[1,5]
					}
					rowgwtd = odam_eval(c1b[selidx], ab[selidx], wb[selidx], best[1,1], best[1,2], priors)
					if (rowgwtd[1,3]!=.) {
						extragwtd = odam_extra_metrics(rowgwtd[1,6], rowgwtd[1,7], rowgwtd[1,8], rowgwtd[1,9], rowgwtd[1,3])
						trainbootgenwtd[r,(g-1)*8+1] = rowgwtd[1,3]
						trainbootgenwtd[r,(g-1)*8+2] = rowgwtd[1,4]*100
						trainbootgenwtd[r,(g-1)*8+3] = rowgwtd[1,5]*100
						trainbootgenwtd[r,(g-1)*8+4] = extragwtd[1,1]
						trainbootgenwtd[r,(g-1)*8+5] = extragwtd[1,2]
						trainbootgenwtd[r,(g-1)*8+6] = extragwtd[1,3]
						trainbootgenwtd[r,(g-1)*8+7] = extragwtd[1,4]
						trainbootgenwtd[r,(g-1)*8+8] = extragwtd[1,5]
					}
				}
			}
		}

		if (doloo | docrossoob) {
			isoob = J(n,1,1)
			for (i=1; i<=ntrain; i++) isoob[idx[i]] = 0
			if (sum(isoob)>0) {
				c1oob = select(c1, isoob)
				woob  = select(w,  isoob)
				istoob = select(ist, isoob)
				if (gengroups) grpoob = select(grp, isoob)
				if (iscat) {
					aoobraw = select(a, isoob)
					aoob = odam_cat_map(aoobraw, catvalsb, scoresb)
					validoob = selectindex(aoob:!=.)
					if (rows(validoob) < rows(aoob)) {
						c1oob = c1oob[validoob]
						aoob  = aoob[validoob]
						woob  = woob[validoob]
						istoob = istoob[validoob]
						if (gengroups) grpoob = grpoob[validoob]
					}
				}
				else {
					aoob = select(a, isoob)
				}
				if (rows(c1oob)>0) {
				if (doloo) {
				selidxtr = selectindex(istoob:==1)
				if (rows(selidxtr)>0) {
				rowoob = odam_eval(c1oob[selidxtr], aoob[selidxtr], J(rows(selidxtr),1,1), best[1,1], best[1,2], priors)
				if (rowoob[1,3]!=.) {
					extraoob = odam_extra_metrics(rowoob[1,6], rowoob[1,7], rowoob[1,8], rowoob[1,9], rowoob[1,3])
					looboot[r,.] = (rowoob[1,3], rowoob[1,4]*100, rowoob[1,5]*100, extraoob[1,1], extraoob[1,2], extraoob[1,3], extraoob[1,4], extraoob[1,5])
				}
				rowoobwtd = odam_eval(c1oob[selidxtr], aoob[selidxtr], woob[selidxtr], best[1,1], best[1,2], priors)
				if (rowoobwtd[1,3]!=.) {
					extraoobwtd = odam_extra_metrics(rowoobwtd[1,6], rowoobwtd[1,7], rowoobwtd[1,8], rowoobwtd[1,9], rowoobwtd[1,3])
					loobootwtd[r,.] = (rowoobwtd[1,3], rowoobwtd[1,4]*100, rowoobwtd[1,5]*100, extraoobwtd[1,1], extraoobwtd[1,2], extraoobwtd[1,3], extraoobwtd[1,4], extraoobwtd[1,5])
				}
				}
				}

				if (gengroups) {
					for (g=1; g<=G; g++) {
						selidx = selectindex(grpoob :== gv[g])
						if (rows(selidx)>0) {
							rowgoob = odam_eval(c1oob[selidx], aoob[selidx], J(rows(selidx),1,1), best[1,1], best[1,2], priors)
							if (rowgoob[1,3]!=.) {
								extragoob = odam_extra_metrics(rowgoob[1,6], rowgoob[1,7], rowgoob[1,8], rowgoob[1,9], rowgoob[1,3])
								loobootgen[r,(g-1)*8+1] = rowgoob[1,3]
								loobootgen[r,(g-1)*8+2] = rowgoob[1,4]*100
								loobootgen[r,(g-1)*8+3] = rowgoob[1,5]*100
								loobootgen[r,(g-1)*8+4] = extragoob[1,1]
								loobootgen[r,(g-1)*8+5] = extragoob[1,2]
								loobootgen[r,(g-1)*8+6] = extragoob[1,3]
								loobootgen[r,(g-1)*8+7] = extragoob[1,4]
								loobootgen[r,(g-1)*8+8] = extragoob[1,5]
							}
							rowgoobwtd = odam_eval(c1oob[selidx], aoob[selidx], woob[selidx], best[1,1], best[1,2], priors)
							if (rowgoobwtd[1,3]!=.) {
								extragoobwtd = odam_extra_metrics(rowgoobwtd[1,6], rowgoobwtd[1,7], rowgoobwtd[1,8], rowgoobwtd[1,9], rowgoobwtd[1,3])
								loobootgenwtd[r,(g-1)*8+1] = rowgoobwtd[1,3]
								loobootgenwtd[r,(g-1)*8+2] = rowgoobwtd[1,4]*100
								loobootgenwtd[r,(g-1)*8+3] = rowgoobwtd[1,5]*100
								loobootgenwtd[r,(g-1)*8+4] = extragoobwtd[1,1]
								loobootgenwtd[r,(g-1)*8+5] = extragoobwtd[1,2]
								loobootgenwtd[r,(g-1)*8+6] = extragoobwtd[1,3]
								loobootgenwtd[r,(g-1)*8+7] = extragoobwtd[1,4]
								loobootgenwtd[r,(g-1)*8+8] = extragoobwtd[1,5]
							}
						}
					}
				}
				}
			}
		}
		if (dots) stata("_dots " + strofreal(r) + " 0")
	}

	alpha = (1-cilevel/100)/2
	boundstr = J(8,2,.)
	boundstrwtd = J(8,2,.)
	for (j=1; j<=8; j++) {
		boundstr[j,1] = odam_boot_percentile(trainboot[.,j], alpha)
		boundstr[j,2] = odam_boot_percentile(trainboot[.,j], 1-alpha)
		boundstrwtd[j,1] = odam_boot_percentile(trainbootwtd[.,j], alpha)
		boundstrwtd[j,2] = odam_boot_percentile(trainbootwtd[.,j], 1-alpha)
	}
	st_matrix("r_ci_train_bounds", boundstr)
	st_matrix("r_ci_train_bounds_wtd", boundstrwtd)

	if (doloo) {
		boundsloo = J(8,2,.)
		boundsloowtd = J(8,2,.)
		for (j=1; j<=8; j++) {
			boundsloo[j,1] = odam_boot_percentile(looboot[.,j], alpha)
			boundsloo[j,2] = odam_boot_percentile(looboot[.,j], 1-alpha)
			boundsloowtd[j,1] = odam_boot_percentile(loobootwtd[.,j], alpha)
			boundsloowtd[j,2] = odam_boot_percentile(loobootwtd[.,j], 1-alpha)
		}
		st_matrix("r_ci_loo_bounds", boundsloo)
		st_matrix("r_ci_loo_bounds_wtd", boundsloowtd)
	}

	if (gengroups) {
		boundstrgen = J(G*8,2,.)
		boundstrgenwtd = J(G*8,2,.)
		for (g=1; g<=G; g++) {
			for (j=1; j<=8; j++) {
				boundstrgen[(g-1)*8+j,1] = odam_boot_percentile(trainbootgen[.,(g-1)*8+j], alpha)
				boundstrgen[(g-1)*8+j,2] = odam_boot_percentile(trainbootgen[.,(g-1)*8+j], 1-alpha)
				boundstrgenwtd[(g-1)*8+j,1] = odam_boot_percentile(trainbootgenwtd[.,(g-1)*8+j], alpha)
				boundstrgenwtd[(g-1)*8+j,2] = odam_boot_percentile(trainbootgenwtd[.,(g-1)*8+j], 1-alpha)
			}
		}
		st_matrix("r_ci_gen_train_bounds", boundstrgen)
		st_matrix("r_ci_gen_train_bounds_wtd", boundstrgenwtd)

		if (doloo | docrossoob) {
			boundsloogen = J(G*8,2,.)
			boundsloogenwtd = J(G*8,2,.)
			for (g=1; g<=G; g++) {
				for (j=1; j<=8; j++) {
					boundsloogen[(g-1)*8+j,1] = odam_boot_percentile(loobootgen[.,(g-1)*8+j], alpha)
					boundsloogen[(g-1)*8+j,2] = odam_boot_percentile(loobootgen[.,(g-1)*8+j], 1-alpha)
					boundsloogenwtd[(g-1)*8+j,1] = odam_boot_percentile(loobootgenwtd[.,(g-1)*8+j], alpha)
					boundsloogenwtd[(g-1)*8+j,2] = odam_boot_percentile(loobootgenwtd[.,(g-1)*8+j], 1-alpha)
				}
			}
			st_matrix("r_ci_gen_loo_bounds", boundsloogen)
			st_matrix("r_ci_gen_loo_bounds_wtd", boundsloogenwtd)
		}
	}
}

real matrix odam_gen_breakdown(real colvector grp, real colvector c1,
	real colvector trainpred, real colvector loopred, real scalar doloo,
	real colvector w)
{
	real colvector gv
	real matrix out
	real scalar G, g, i, n, TP, FN, TN, FP, TPl, FNl, TNl, FPl
	real scalar TPw, FNw, TNw, FPw, TPlw, FNlw, TNlw, FPlw
	real scalar sens, spec, essp, sensl, specl, esspl
	real scalar sensw, specw, esspw, senslw, speclw, esspllw
	real rowvector extra, extral, extraw, extralw

	gv = uniqrows(grp)
	G = rows(gv)
	out = J(G,35,.)
	for (g=1; g<=G; g++) {
		TP=0; FN=0; TN=0; FP=0
		TPl=0; FNl=0; TNl=0; FPl=0
		TPw=0; FNw=0; TNw=0; FPw=0
		TPlw=0; FNlw=0; TNlw=0; FPlw=0
		n = 0
		for (i=1; i<=rows(grp); i++) {
			if (grp[i]!=gv[g]) continue
			n++
			if (c1[i]==1 & trainpred[i]==1) {
				TP++
				TPw = TPw + w[i]
			}
			if (c1[i]==1 & trainpred[i]==0) {
				FN++
				FNw = FNw + w[i]
			}
			if (c1[i]==0 & trainpred[i]==0) {
				TN++
				TNw = TNw + w[i]
			}
			if (c1[i]==0 & trainpred[i]==1) {
				FP++
				FPw = FPw + w[i]
			}
			if (doloo & loopred[i]!=.) {
				if (c1[i]==1 & loopred[i]==1) {
					TPl++
					TPlw = TPlw + w[i]
				}
				if (c1[i]==1 & loopred[i]==0) {
					FNl++
					FNlw = FNlw + w[i]
				}
				if (c1[i]==0 & loopred[i]==0) {
					TNl++
					TNlw = TNlw + w[i]
				}
				if (c1[i]==0 & loopred[i]==1) {
					FPl++
					FPlw = FPlw + w[i]
				}
			}
		}
		sens = ((TP+FN)>0 ? TP/(TP+FN) : .)
		spec = ((TN+FP)>0 ? TN/(TN+FP) : .)
		essp = (sens!=. & spec!=. ? ((sens+spec)/2*100-50)/50*100 : .)
		extra = odam_extra_metrics(TP,FN,TN,FP,essp)
		out[g,1]=gv[g]; out[g,2]=n
		out[g,3]=sens; out[g,4]=spec; out[g,5]=essp; out[g,6]=extra[1,1]
		out[g,7]=extra[1,2]; out[g,8]=extra[1,3]; out[g,9]=extra[1,4]; out[g,10]=extra[1,5]

		sensw = ((TPw+FNw)>0 ? TPw/(TPw+FNw) : .)
		specw = ((TNw+FPw)>0 ? TNw/(TNw+FPw) : .)
		esspw = (sensw!=. & specw!=. ? ((sensw+specw)/2*100-50)/50*100 : .)
		extraw = odam_extra_metrics(TPw,FNw,TNw,FPw,esspw)
		out[g,20]=sensw; out[g,21]=specw; out[g,22]=esspw; out[g,23]=extraw[1,1]
		out[g,24]=extraw[1,2]; out[g,25]=extraw[1,3]; out[g,26]=extraw[1,4]; out[g,27]=extraw[1,5]

		if (doloo) {
			sensl = ((TPl+FNl)>0 ? TPl/(TPl+FNl) : .)
			specl = ((TNl+FPl)>0 ? TNl/(TNl+FPl) : .)
			esspl = (sensl!=. & specl!=. ? ((sensl+specl)/2*100-50)/50*100 : .)
			extral = odam_extra_metrics(TPl,FNl,TNl,FPl,esspl)
			out[g,11]=sensl; out[g,12]=specl; out[g,13]=esspl; out[g,14]=extral[1,1]
			out[g,15]=extral[1,2]; out[g,16]=extral[1,3]; out[g,17]=extral[1,4]; out[g,18]=extral[1,5]
			out[g,19]=odam_fisher_onesided(TPl,FNl,FPl,TNl)

			senslw = ((TPlw+FNlw)>0 ? TPlw/(TPlw+FNlw) : .)
			speclw = ((TNlw+FPlw)>0 ? TNlw/(TNlw+FPlw) : .)
			esspllw = (senslw!=. & speclw!=. ? ((senslw+speclw)/2*100-50)/50*100 : .)
			extralw = odam_extra_metrics(TPlw,FNlw,TNlw,FPlw,esspllw)
			out[g,28]=senslw; out[g,29]=speclw; out[g,30]=esspllw; out[g,31]=extralw[1,1]
			out[g,32]=extralw[1,2]; out[g,33]=extralw[1,3]; out[g,34]=extralw[1,4]; out[g,35]=extralw[1,5]
		}
	}
	return(out)
}

real matrix odam_gen_tiebreak(real matrix tied, string scalar crit, real scalar genval,
	real colvector grpvals, real scalar meancol)
{
	real colvector metric
	real scalar best, gidx, g

	if (rows(tied)<=1) return(tied)

	if (crit=="gensens") {
		gidx = 0
		for (g=1; g<=rows(grpvals); g++) {
			if (grpvals[g]==genval) {
				gidx = g
				break
			}
		}
		if (gidx==0) metric = tied[.,meancol]
		else         metric = tied[.,meancol+gidx]
	}
	else metric = tied[.,meancol]

	best = max(metric)
	return(select(tied, abs(metric:-best):<1e-8))
}

real rowvector odam_best_gen(real colvector c1, real colvector a, real colvector w,
	real scalar priors, real scalar degen, real scalar dirconstraint,
	real colvector grp, real colvector grpvals,
	string scalar primary, string scalar secondary,
	real scalar primarygenval, real scalar secondarygenval)
{
	real colvector p, as, c1s, ws, grps
	real colvector uvals, grpend, cps, idxs
	real colvector cum1e, cum0e, c1v, c0v
	real colvector TP1,TN1,sens1,spec1,m1, TP2,TN2,sens2,spec2,m2
	real colvector minmacc1, minmacc2, summacc1, summacc2
	real colvector meanmacc1, meanmacc2
	real matrix results, tied, groupmacc1, groupmacc2
	real scalar n, nu, k, pos, nc, G, g, gv, W1, W0, maxobj, cnt1, cnt2

	n = rows(a)
	G = rows(grpvals)

	p = order(a,1)
	as = a[p]; c1s = c1[p]; ws = w[p]; grps = grp[p]

	uvals = uniqrows(as)
	nu = rows(uvals)

	grpend = J(nu,1,.)
	pos = 1
	for (k=1; k<=nu; k++) {
		while (pos<=n) {
			if (as[pos]!=uvals[k]) break
			pos++
		}
		grpend[k] = pos-1
	}

	cps  = J(0,1,.)
	idxs = J(0,1,.)
	for (k=1; k<=nu-1; k++) {
		cps  = cps  \ ((uvals[k]+uvals[k+1])/2)
		idxs = idxs \ grpend[k]
	}
	if (degen & nu>0) {
		if (rows(cps)==0) {
			cps  = (uvals[1]-1) \ (uvals[nu]+1)
			idxs = (0)          \ (n)
		}
		else {
			cps  = (uvals[1]-1) \ cps  \ (uvals[nu]+1)
			idxs = (0)          \ idxs \ (n)
		}
	}
	if (rows(cps)==0) return(J(1,9,.))
	nc = rows(cps)

	minmacc1 = J(nc,1,.); minmacc2 = J(nc,1,.)
	summacc1 = J(nc,1,0); summacc2 = J(nc,1,0)
	groupmacc1 = J(nc,G,.); groupmacc2 = J(nc,G,.)
	cnt1 = 0; cnt2 = 0

	for (g=1; g<=G; g++) {
		gv = grpvals[g]
		cum1e = (0) \ runningsum(ws :* (c1s:==1) :* (grps:==gv))
		cum0e = (0) \ runningsum(ws :* (c1s:==0) :* (grps:==gv))
		W1 = cum1e[n+1]
		W0 = cum0e[n+1]
		if (W1==0 | W0==0) continue
		c1v = cum1e[idxs :+ 1]
		c0v = cum0e[idxs :+ 1]
		if (dirconstraint==0 | dirconstraint==1) {
			TP1 = J(nc,1,W1) :- c1v
			TN1 = c0v
			sens1 = TP1 :/ W1
			spec1 = TN1 :/ W0
			if (priors) m1 = (sens1 :+ spec1) :/ 2 :* 100
			else         m1 = (TP1 :+ TN1) :/ (W1+W0) :* 100
			minmacc1 = (cnt1==0 ? m1 : rowmin((minmacc1,m1)))
			summacc1 = summacc1 :+ m1
			groupmacc1[.,g] = m1
			cnt1 = cnt1 + 1
		}
		if (dirconstraint==0 | dirconstraint==-1) {
			TP2 = c1v
			TN2 = J(nc,1,W0) :- c0v
			sens2 = TP2 :/ W1
			spec2 = TN2 :/ W0
			if (priors) m2 = (sens2 :+ spec2) :/ 2 :* 100
			else         m2 = (TP2 :+ TN2) :/ (W1+W0) :* 100
			minmacc2 = (cnt2==0 ? m2 : rowmin((minmacc2,m2)))
			summacc2 = summacc2 :+ m2
			groupmacc2[.,g] = m2
			cnt2 = cnt2 + 1
		}
	}

	results = J(0,4+G,.)
	if ((dirconstraint==0 | dirconstraint==1) & cnt1>1) {
		meanmacc1 = summacc1 :/ cnt1
		results = results \ (cps, J(nc,1,1), minmacc1, meanmacc1, groupmacc1)
	}
	if ((dirconstraint==0 | dirconstraint==-1) & cnt2>1) {
		meanmacc2 = summacc2 :/ cnt2
		results = results \ (cps, J(nc,1,-1), minmacc2, meanmacc2, groupmacc2)
	}
	if (rows(results)==0) return(J(1,9,.))

	maxobj = max(results[.,3])
	tied = select(results, abs(results[.,3]:-maxobj):<1e-8)
	tied = odam_gen_tiebreak(tied, primary, primarygenval, grpvals, 4)
	if (rows(tied)>1) tied = odam_gen_tiebreak(tied, secondary, secondarygenval, grpvals, 4)

	return((tied[1,1], tied[1,2], tied[1,3], ., ., ., ., ., .))
}

real rowvector odam_best_cat_gen(real colvector c1, real colvector cat, real colvector w,
	real scalar priors, real scalar degen, real scalar dirconstraint,
	real colvector grp, real colvector grpvals,
	string scalar primary, string scalar secondary,
	real scalar primarygenval, real scalar secondarygenval)
{
	real colvector catvals, scores, a
	odam_cat_scoretable(cat, c1, w, catvals, scores)
	a = odam_cat_map(cat, catvals, scores)
	return(odam_best_gen(c1, a, w, priors, degen, dirconstraint, grp, grpvals, primary, secondary, primarygenval, secondarygenval))
}

void oda_driver(string scalar cvar, string scalar avar, string scalar wvar,
	string scalar istrainvar,
	real scalar priors, real scalar degen, real scalar dirconstraint,
	string scalar primary, string scalar secondary, real scalar niter, real scalar doloo,
	real scalar nloo,
	real scalar iscat, real scalar dots, real scalar wtdsearch, string scalar predvar,
	string scalar loopredvar, string scalar gvar,
	real scalar primarygenval, real scalar secondarygenval)
{
	real colvector c1, a, w, w1, wsrch, ascore, ascoret, catvals, scores, grp0, grp1, pred01, loopred
	real colvector ist, c1t, at, w1t, wsrcht, wtr, grpt, grpvals
	real rowvector best, extra, rowwtd, extrawtd, roworig
	real scalar ess_loo, sens_loo, spec_loo, TPl, FNl, TNl, FPl, pval, obsmacc, pvalloo
	real scalar ess_loo_wtd, sens_loo_wtd, spec_loo_wtd, TPlw, FNlw, TNlw, FPlw

	c1 = st_data(., cvar)
	a  = st_data(., avar)
	w  = st_data(., wvar)
	w1 = J(rows(c1),1,1)
	if (wtdsearch) wsrch = w
	else           wsrch = w1

	ist    = st_data(., istrainvar)
	c1t    = select(c1, ist:==1)
	at     = select(a, ist:==1)
	w1t    = select(w1, ist:==1)
	wsrcht = select(wsrch, ist:==1)
	wtr    = select(w, ist:==1)

	st_numscalar("r_N", sum(ist))

	if (iscat & gvar != "") {
		grpt   = select(st_data(., gvar), ist:==1)
		grpvals = uniqrows(grpt)
		if (rows(grpvals)==2) best = odam_best_cat_gen(c1t, at, wsrcht, priors, degen, dirconstraint, grpt, grpvals, primary, secondary, primarygenval, secondarygenval)
		else                  best = odam_best_cat(c1t, at, wsrcht, priors, degen, dirconstraint, primary, secondary, wtdsearch)
	}
	else if (iscat) best = odam_best_cat(c1t, at, wsrcht, priors, degen, dirconstraint, primary, secondary, wtdsearch)
	else if (gvar != "") {
		grpt   = select(st_data(., gvar), ist:==1)
		grpvals = uniqrows(grpt)
		if (rows(grpvals)==2) best = odam_best_gen(c1t, at, wsrcht, priors, degen, dirconstraint, grpt, grpvals, primary, secondary, primarygenval, secondarygenval)
		else                  best = odam_best(c1t, at, wsrcht, priors, degen, dirconstraint, primary, secondary, wtdsearch)
	}
	else       best = odam_best(c1t, at, wsrcht, priors, degen, dirconstraint, primary, secondary, wtdsearch)

	st_numscalar("r_cutpoint",  best[1,1])
	st_numscalar("r_direction", best[1,2])

	ascore = a
	if (iscat & best[1,3]!=.) {
		odam_cat_scoretable(at, c1t, wsrcht, catvals, scores)
		if (best[1,2]==1) {
			grp1 = select(catvals, scores :> best[1,1])
			grp0 = select(catvals, scores :<= best[1,1])
		}
		else {
			grp1 = select(catvals, scores :< best[1,1])
			grp0 = select(catvals, scores :>= best[1,1])
		}
		st_global("_oda_grp0", odam_vec2str(grp0))
		st_global("_oda_grp1", odam_vec2str(grp1))
		ascore = odam_cat_map(a, catvals, scores)

		st_matrix("r_cat_vals",   catvals)
		st_matrix("r_cat_scores", scores)
	}

	if (predvar != "" & best[1,3]!=.) {
		if (best[1,2]==1) pred01 = (ascore :> best[1,1])
		else              pred01 = (ascore :<= best[1,1])
		st_store(., predvar, pred01)
	}

	ascoret = select(ascore, ist:==1)
	if (best[1,3]!=.) {
		roworig = odam_eval(c1t, ascoret, w1t, best[1,1], best[1,2], priors)
		st_numscalar("r_ess_train", roworig[1,3])
		st_numscalar("r_sens",      roworig[1,4])
		st_numscalar("r_spec",      roworig[1,5])
		extra = odam_extra_metrics(roworig[1,6], roworig[1,7], roworig[1,8], roworig[1,9], roworig[1,3])
	}
	else {
		st_numscalar("r_ess_train", .); st_numscalar("r_sens", .); st_numscalar("r_spec", .)
		extra = odam_extra_metrics(., ., ., ., .)
	}
	st_numscalar("r_overall_acc", extra[1,1])
	st_numscalar("r_pv0",         extra[1,2])
	st_numscalar("r_pv1",         extra[1,3])
	st_numscalar("r_ess_pv",      extra[1,4])
	st_numscalar("r_ess_total",   extra[1,5])

	if (best[1,3]!=.) {
		rowwtd = odam_eval(c1t, ascoret, wtr, best[1,1], best[1,2], priors)
		st_numscalar("r_ess_pac_wtd", rowwtd[1,3])
		st_numscalar("r_pac1_wtd",    rowwtd[1,4])
		st_numscalar("r_pac0_wtd",    rowwtd[1,5])
		extrawtd = odam_extra_metrics(rowwtd[1,6], rowwtd[1,7], rowwtd[1,8], rowwtd[1,9], rowwtd[1,3])
		st_numscalar("r_overall_acc_wtd", extrawtd[1,1])
		st_numscalar("r_pv0_wtd",         extrawtd[1,2])
		st_numscalar("r_pv1_wtd",         extrawtd[1,3])
		st_numscalar("r_ess_pv_wtd",      extrawtd[1,4])
		st_numscalar("r_ess_total_wtd",   extrawtd[1,5])
	}
	else {
		st_numscalar("r_ess_pac_wtd", .);      st_numscalar("r_pac1_wtd", .)
		st_numscalar("r_pac0_wtd", .);         st_numscalar("r_overall_acc_wtd", .)
		st_numscalar("r_pv0_wtd", .);          st_numscalar("r_pv1_wtd", .)
		st_numscalar("r_ess_pv_wtd", .);       st_numscalar("r_ess_total_wtd", .)
	}

	if (niter>0) {
		if (iscat) pval = odam_permtest_cat(c1t,at,wsrcht,priors,degen,dirconstraint,primary,secondary,best[1,3],niter,dots,wtdsearch)
		else       pval = odam_permtest(c1t,at,wsrcht,priors,degen,dirconstraint,primary,secondary,best[1,3],niter,dots,wtdsearch)
		st_numscalar("r_est_P", pval)
	}

	if (doloo) {
		if (iscat) odam_loo_cat(c1t,at,w1t,wtr,priors,degen,dirconstraint,primary,secondary,
				ess_loo, sens_loo, spec_loo, TPl, FNl, TNl, FPl,
				ess_loo_wtd, sens_loo_wtd, spec_loo_wtd, TPlw, FNlw, TNlw, FPlw, dots, wtdsearch, loopred)
		else       odam_loo(c1t,at,w1t,wtr,priors,degen,dirconstraint,primary,secondary,
				ess_loo, sens_loo, spec_loo, TPl, FNl, TNl, FPl,
				ess_loo_wtd, sens_loo_wtd, spec_loo_wtd, TPlw, FNlw, TNlw, FPlw, dots, wtdsearch, loopred)
		if (loopredvar != "") st_store(selectindex(ist:==1), loopredvar, loopred)
		st_numscalar("r_ess_loo",  ess_loo)
		st_numscalar("r_sens_loo", sens_loo)
		st_numscalar("r_spec_loo", spec_loo)
		st_matrix("r_loo_table", (TPl,FNl \ FPl,TNl))
		if (nloo>0) {
			obsmacc = (priors ? (sens_loo+spec_loo)/2 : (TPl+TNl)/(TPl+FNl+TNl+FPl))
			if (iscat) pvalloo = odam_permtest_loo_cat(c1t,at,w1t,wtr,priors,degen,dirconstraint,primary,secondary,wtdsearch,obsmacc,nloo,dots)
			else       pvalloo = odam_permtest_loo(c1t,at,w1t,wtr,priors,degen,dirconstraint,primary,secondary,wtdsearch,obsmacc,nloo,dots)
			st_numscalar("r_est_P_LOO", pvalloo)
			if (gvar != "") {
				if (iscat) st_matrix("r_gen_loo_pval", odam_permtest_loo_gen_cat(c1t,at,w1t,wtr,priors,degen,dirconstraint,primary,secondary,wtdsearch,grpt,grpvals,loopred,nloo,dots))
				else       st_matrix("r_gen_loo_pval", odam_permtest_loo_gen(c1t,at,w1t,wtr,priors,degen,dirconstraint,primary,secondary,wtdsearch,grpt,grpvals,loopred,nloo,dots))
			}
		}
		else st_numscalar("r_est_P_LOO", odam_fisher_onesided(TPl,FNl,FPl,TNl))

		extra = odam_extra_metrics(TPl, FNl, TNl, FPl, ess_loo)
		st_numscalar("r_overall_acc_loo", extra[1,1])
		st_numscalar("r_pv0_loo",         extra[1,2])
		st_numscalar("r_pv1_loo",         extra[1,3])
		st_numscalar("r_ess_pv_loo",      extra[1,4])
		st_numscalar("r_ess_total_loo",   extra[1,5])

		st_numscalar("r_ess_pac_loo_wtd", ess_loo_wtd)
		st_numscalar("r_pac1_loo_wtd",    sens_loo_wtd)
		st_numscalar("r_pac0_loo_wtd",    spec_loo_wtd)
		extrawtd = odam_extra_metrics(TPlw, FNlw, TNlw, FPlw, ess_loo_wtd)
		st_numscalar("r_overall_acc_loo_wtd", extrawtd[1,1])
		st_numscalar("r_pv0_loo_wtd",         extrawtd[1,2])
		st_numscalar("r_pv1_loo_wtd",         extrawtd[1,3])
		st_numscalar("r_ess_pv_loo_wtd",      extrawtd[1,4])
		st_numscalar("r_ess_total_loo_wtd",   extrawtd[1,5])
	}
}

real scalar odamK_fit(real colvector a, real colvector cls, real colvector w,
	real colvector cvals, real scalar priors, real scalar degen,
	real colvector cps, real colvector seglabels, string scalar primarycrit)
{
	real colvector uvals, effw, segEndIdx, segLabel
	real scalar nu, K, i, j, k, n, cntk, nsub, S, Sprev, bit, full
	real scalar bestval, bestj, bestell, val
	real matrix binwt, prefix, dp, dpj, dpl
	real scalar segIstart, b, lastRel, firstRel, israndom, ncand, pick

	uvals = uniqrows(a)
	nu = rows(uvals)
	K  = rows(cvals)
	n  = rows(a)
	israndom = (primarycrit=="random")

	if (nu < K) return(.)

	if (priors) {
		effw = J(n,1,0)
		for (k=1; k<=K; k++) {
			cntk = sum(cls:==cvals[k])
			if (cntk>0) effw = effw :+ (cls:==cvals[k]) :* (w :/ cntk)
		}
	}
	else effw = w

	binwt = J(nu,K,0)
	for (i=1; i<=nu; i++) {
		for (k=1; k<=K; k++) {
			binwt[i,k] = sum(effw :* (a:==uvals[i]) :* (cls:==cvals[k]))
		}
	}
	prefix = J(nu+1,K,0)
	for (i=1; i<=nu; i++) prefix[i+1,.] = prefix[i,.] + binwt[i,.]

	nsub = 2^K
	dp  = J(nu+1, nsub, .)
	dpj = J(nu+1, nsub, .)
	dpl = J(nu+1, nsub, .)
	dp[1,1] = 0

	for (i=1; i<=nu; i++) {
		for (S=0; S<=nsub-1; S++) {
			bestval = .
			bestj = .
			bestell = .
			for (k=1; k<=K; k++) {
				bit = 2^(k-1)
				if (mod(floor(S/bit),2)==0) continue
				Sprev = S - bit
				for (j=0; j<=i-1; j++) {
					if (dp[j+1,Sprev+1]==.) continue
					val = dp[j+1,Sprev+1] + (prefix[i+1,k]-prefix[j+1,k])
					if (bestval==. | val > bestval) {
						bestval = val
						bestj = j
						bestell = k
					}
				}
			}
			dp[i+1,S+1]  = bestval
			dpj[i+1,S+1] = bestj
			dpl[i+1,S+1] = bestell
		}
	}

	full = nsub - 1
	if (dp[nu+1,full+1]==.) return(.)

	segEndIdx = J(0,1,.)
	segLabel  = J(0,1,.)
	i = nu
	S = full
	while (S>0) {
		bestell = dpl[i+1,S+1]
		bestj   = dpj[i+1,S+1]
		segEndIdx = i \ segEndIdx
		segLabel  = bestell \ segLabel
		bit = 2^(bestell-1)
		S = S - bit
		i = bestj
	}

	cps = J(K-1,1,.)
	for (i=1; i<=K-1; i++) {
		segIstart = (i==1 ? 1 : segEndIdx[i-1]+1)
		lastRel = .
		for (b=segEndIdx[i]; b>=segIstart; b--) {
			if (binwt[b,segLabel[i]] > 0) {
				lastRel = b
				break
			}
		}
		if (lastRel==.) lastRel = segEndIdx[i]

		firstRel = .
		for (b=segEndIdx[i]+1; b<=segEndIdx[i+1]; b++) {
			if (binwt[b,segLabel[i+1]] > 0) {
				firstRel = b
				break
			}
		}
		if (firstRel==.) firstRel = segEndIdx[i]+1

		if (israndom) {
			ncand = firstRel - lastRel
			pick = lastRel - 1 + ceil(uniform(1,1)*ncand)
			cps[i] = (uvals[pick] + uvals[pick+1]) / 2
		}
		else {
			cps[i] = (uvals[lastRel] + uvals[firstRel]) / 2
		}
	}
	seglabels = J(K,1,.)
	for (i=1; i<=K; i++) seglabels[i] = cvals[segLabel[i]]

	return(dp[nu+1,full+1])
}

real matrix odam_permute(real colvector vals)
{
	real matrix out, sub
	real colvector rest
	real scalar n, i, r

	n = rows(vals)
	if (n==0) return(J(1,0,.))
	if (n==1) return(vals')
	out = J(0,n,.)
	for (i=1; i<=n; i++) {
		rest = select(vals, (1::n):!=i)
		sub = odam_permute(rest)
		for (r=1; r<=rows(sub); r++) {
			out = out \ (vals[i], sub[r,.])
		}
	}
	return(out)
}

real scalar odamK_fit_random_order(real colvector a, real colvector cls, real colvector w,
	real colvector cvals, real scalar priors, real scalar degen,
	real colvector cps, real colvector seglabels, string scalar primarycrit,
	string scalar secondarycrit)
{
	real scalar K, obj, val, best, nord, pick, p, MAXK, i
	real matrix perms, tied
	real colvector ordidx0r

	obj = odamK_fit(a, cls, w, cvals, priors, degen, cps, seglabels, primarycrit)
	if (!(primarycrit=="random" | secondarycrit=="random")) return(obj)
	if (obj==.) return(obj)

	K = rows(cvals)
	MAXK = 6
	if (K > MAXK) {
		printf("{txt}note: oda skips full class-order tie randomization for a classvar with more than %9.0g levels (cost grows factorially); primary(random)'s existing within-order randomization still applies\n", MAXK)
		return(obj)
	}

	perms = odam_permute(1::K)
	tied = J(0,K,.)
	best = .
	for (p=1; p<=rows(perms); p++) {
		ordidx0r = perms[p,.]'
		val = odamK_fit_ordered(a, cls, w, cvals, priors, ordidx0r, cps, "")
		if (val==.) continue
		if (best==. | val > best + 1e-8) {
			best = val
			tied = perms[p,.]
		}
		else if (abs(val-best) < 1e-8) {
			tied = tied \ perms[p,.]
		}
	}
	if (rows(tied)==0) return(obj)

	nord = rows(tied)
	pick = (nord>1 ? ceil(uniform(1,1)*nord) : 1)
	ordidx0r = tied[pick,.]'
	val = odamK_fit_ordered(a, cls, w, cvals, priors, ordidx0r, cps, primarycrit)
	seglabels = J(K,1,.)
	for (i=1; i<=K; i++) seglabels[i] = cvals[ordidx0r[i]]
	return(val)
}

real colvector odamK_predict(real colvector a, real colvector cps, real colvector seglabels)
{
	real colvector pred
	real scalar n, i, s, nseg
	n = rows(a)
	nseg = rows(seglabels)
	pred = J(n,1,.)
	for (i=1; i<=n; i++) {
		s = 1
		while (s<=nseg-1) {
			if (a[i] > cps[s]) s++
			else break
		}
		pred[i] = seglabels[s]
	}
	return(pred)
}

real matrix odamK_confusion(real colvector actual, real colvector pred,
	real colvector w, real colvector cvals)
{
	real scalar K, i, j
	real matrix conf
	K = rows(cvals)
	conf = J(K,K,0)
	for (i=1; i<=K; i++) {
		for (j=1; j<=K; j++) {
			conf[i,j] = sum(w :* (actual:==cvals[i]) :* (pred:==cvals[j]))
		}
	}
	return(conf)
}

void odamK_metrics(real matrix conf, real scalar overall, real scalar meanpac,
	real scalar meanpv, real colvector pac, real colvector pv)
{
	real scalar K, k, N, rowsum, colsum, npvdef, sumpv
	K = rows(conf)
	N = sum(conf)
	overall = (N>0 ? sum(diagonal(conf))/N*100 : .)

	pac = J(K,1,.)
	pv  = J(K,1,.)
	for (k=1; k<=K; k++) {
		rowsum = sum(conf[k,.])
		colsum = sum(conf[.,k])
		if (rowsum>0) pac[k] = conf[k,k]/rowsum*100
		if (colsum>0) pv[k]  = conf[k,k]/colsum*100
	}
	meanpac = (K>0 ? sum(pac)/K : .)

	npvdef = 0
	sumpv  = 0
	for (k=1; k<=K; k++) {
		if (pv[k]!=.) {
			sumpv = sumpv + pv[k]
			npvdef++
		}
	}
	meanpv = (npvdef>0 ? sumpv/npvdef : .)
}

real scalar odamK_ess(real scalar meanpct, real scalar K)
{
	real scalar base
	if (meanpct==. | K<2) return(.)
	base = 100/K
	return((meanpct-base)/(100-base)*100)
}

real scalar odamK_fit_cat(real colvector cat, real colvector cls, real colvector w,
	real colvector cvals, real scalar priors,
	real colvector catvals, real colvector catmodel,
	string scalar primarycrit, string scalar secondarycrit)
{
	real scalar nu, K, i, k, n, cntk, bestval, bestk, obj, israndomcat, ntied
	real colvector effw, tiedk
	real matrix catwt

	catvals = uniqrows(cat)
	nu = rows(catvals)
	K  = rows(cvals)
	n  = rows(cat)
	israndomcat = (primarycrit=="random" | secondarycrit=="random")

	if (priors) {
		effw = J(n,1,0)
		for (k=1; k<=K; k++) {
			cntk = sum(cls:==cvals[k])
			if (cntk>0) effw = effw :+ (cls:==cvals[k]) :* (w :/ cntk)
		}
	}
	else effw = w

	catwt = J(nu,K,0)
	for (i=1; i<=nu; i++) {
		for (k=1; k<=K; k++) {
			catwt[i,k] = sum(effw :* (cat:==catvals[i]) :* (cls:==cvals[k]))
		}
	}

	catmodel = J(nu,1,.)
	obj = 0
	for (i=1; i<=nu; i++) {
		bestval = .
		bestk = .
		for (k=1; k<=K; k++) {
			if (bestval==. | catwt[i,k] > bestval) {
				bestval = catwt[i,k]
				bestk = k
			}
		}
		if (israndomcat) {
			tiedk = selectindex(abs(catwt[i,.]:-bestval):<1e-8)
			ntied = rows(tiedk)
			if (ntied>1) bestk = tiedk[ceil(uniform(1,1)*ntied)]
		}
		catmodel[i] = cvals[bestk]
		obj = obj + bestval
	}
	return(obj)
}

real colvector odamK_predict_cat(real colvector cat, real colvector catvals, real colvector catmodel, real scalar deflt)
{
	real colvector pred
	real scalar n, nu, i, j, found
	n = rows(cat)
	nu = rows(catvals)
	pred = J(n,1,.)
	for (i=1; i<=n; i++) {
		found = 0
		for (j=1; j<=nu; j++) {
			if (catvals[j]==cat[i]) {
				pred[i] = catmodel[j]
				found = 1
				break
			}
		}
		if (!found) pred[i] = deflt
	}
	return(pred)
}

void odam_predict_apply(string scalar newvar, string scalar attrvar,
	string scalar touse, real scalar multiclass, real scalar iscat,
	real scalar clow, real scalar chigh)
{
	real colvector tv, aidx, a, ascore, predout, predK
	real colvector catvals, scores, cvals, cps, seglabels, catmodel
	real scalar cutpoint, direction, i

	tv = st_data(., touse)
	aidx = selectindex(tv:==1)
	if (rows(aidx)==0) return

	a = st_data(., attrvar)[aidx]

	if (!multiclass) {
		cutpoint  = st_numscalar("r_cutpoint")
		direction = st_numscalar("r_direction")
		if (iscat) {
			catvals = st_matrix("r_cat_vals")
			scores  = st_matrix("r_cat_scores")
			ascore  = odam_cat_map(a, catvals, scores)
		}
		else {
			ascore = a
		}
		predout = J(rows(aidx),1,.)
		for (i=1; i<=rows(aidx); i++) {
			if (ascore[i]==.) continue
			if (direction==1) predout[i] = (ascore[i] > cutpoint ? chigh : clow)
			else               predout[i] = (ascore[i] <= cutpoint ? chigh : clow)
		}
		st_store(aidx, newvar, predout)
	}
	else {
		cvals = st_matrix("r_K_cvals")
		if (iscat) {
			catvals  = st_matrix("r_K_catvals")
			catmodel = st_matrix("r_K_catmodel")
			predK = odamK_predict_cat(a, catvals, catmodel, cvals[1])
		}
		else {
			seglabels = st_matrix("r_K_seglabels")
			if (rows(seglabels)>1) cps = st_matrix("r_K_cps")
			else                   cps = J(0,1,.)
			predK = odamK_predict(a, cps, seglabels)
		}
		st_store(aidx, newvar, predK)
	}
}

real scalar odamK_permtest_cat(real colvector cat, real colvector cls, real colvector w,
	real colvector cvals, real scalar priors,
	real scalar obsobj, real scalar niter, real scalar dots)
{
	real scalar r, cnt, n, val
	real colvector clsp, catvals, catmodel

	n = rows(cls)
	cnt = 0
	if (dots) {
		odam_dots_header("Monte Carlo permutation test (" + strofreal(niter) + " iterations):")
		stata("_dots 0 0")
	}
	for (r=1; r<=niter; r++) {
		clsp = cls[jumble(1::n)]
		val = odamK_fit_cat(cat, clsp, w, cvals, priors, catvals, catmodel, "", "")
		if (val!=. & val >= obsobj) cnt++
		if (dots) stata("_dots " + strofreal(r) + " 0")
	}
	return(cnt/niter)
}

real matrix odam_cross_sigtest(real colvector grp, real colvector actual,
	real colvector pred, real colvector cvals, real scalar niter, real scalar dots)
{
	real colvector gv, selidx, agrp, pgrp, actp
	real matrix out
	real scalar G, g, n, r, obs, cnt

	gv = uniqrows(grp)
	G  = rows(gv)
	out = J(G,3,.)

	for (g=1; g<=G; g++) {
		out[g,1] = gv[g]
		selidx = selectindex(grp:==gv[g])
		n = rows(selidx)
		out[g,2] = n
		if (n==0 | niter<=0) continue
		agrp = actual[selidx]
		pgrp = pred[selidx]

		obs = sum(agrp:==pgrp)
		cnt = 0
		if (dots) {
			odam_dots_header("Cross-sample significance test -- group " + strofreal(gv[g]) + " (" + strofreal(niter) + " iterations):")
			stata("_dots 0 0")
		}
		for (r=1; r<=niter; r++) {
			actp = agrp[jumble(1::n)]
			if (sum(actp:==pgrp) >= obs) cnt++
			if (dots) stata("_dots " + strofreal(r) + " 0")
		}
		out[g,3] = cnt/niter
	}
	return(out)
}

void odamK_loo_cat(real colvector cat, real colvector cls, real colvector w,
	real colvector cvals, real scalar priors, real scalar dots,
	real matrix conf_unw, real matrix conf_wtd, real colvector loopred,
	string scalar primarycrit, string scalar secondarycrit)
{
	real scalar n, i, K, val
	real colvector idx, catsub, clssub, wsub, catvals, catmodel, pred1

	n = rows(cls)
	K = rows(cvals)
	conf_unw = J(K,K,0)
	conf_wtd = J(K,K,0)
	loopred = J(n,1,.)
	if (dots) {
		odam_dots_header("Leave-one-out cross-validation (" + strofreal(n) + " observations):")
		stata("_dots 0 0")
	}
	for (i=1; i<=n; i++) {
		idx = select(1::n, (1::n):!=i)
		catsub = cat[idx]; clssub = cls[idx]; wsub = w[idx]
		val = odamK_fit_cat(catsub, clssub, wsub, cvals, priors, catvals, catmodel, primarycrit, secondarycrit)
		pred1 = odamK_predict_cat(J(1,1,cat[i]), catvals, catmodel, cvals[1])
		loopred[i] = pred1[1]
		conf_unw = conf_unw + odamK_confusion(J(1,1,cls[i]), pred1, J(1,1,1), cvals)
		conf_wtd = conf_wtd + odamK_confusion(J(1,1,cls[i]), pred1, J(1,1,w[i]), cvals)
		if (dots) stata("_dots " + strofreal(i) + " 0")
	}
}

real scalar odamK_permtest(real colvector a, real colvector cls, real colvector w,
	real colvector cvals, real scalar priors, real scalar degen,
	real scalar obsobj, real scalar niter, real scalar dots)
{
	real scalar r, cnt, n, val
	real colvector clsp, cps, seglabels

	n = rows(cls)
	cnt = 0
	if (dots) {
		odam_dots_header("Monte Carlo permutation test (" + strofreal(niter) + " iterations):")
		stata("_dots 0 0")
	}
	for (r=1; r<=niter; r++) {
		clsp = cls[jumble(1::n)]
		val = odamK_fit(a, clsp, w, cvals, priors, degen, cps, seglabels, "")
		if (val!=. & val >= obsobj) cnt++
		if (dots) stata("_dots " + strofreal(r) + " 0")
	}
	return(cnt/niter)
}

real scalar odamK_permtest_ordered(real colvector a, real colvector cls, real colvector w,
	real colvector cvals, real scalar priors, real colvector ordidx0,
	real scalar obsobj, real scalar niter, real scalar dots)
{
	real scalar r, cnt, n, val
	real colvector clsp, cps

	n = rows(cls)
	cnt = 0
	if (dots) {
		odam_dots_header("Monte Carlo permutation test (" + strofreal(niter) + " iterations):")
		stata("_dots 0 0")
	}
	for (r=1; r<=niter; r++) {
		clsp = cls[jumble(1::n)]
		val = odamK_fit_ordered(a, clsp, w, cvals, priors, ordidx0, cps, "")
		if (val!=. & val >= obsobj) cnt++
		if (dots) stata("_dots " + strofreal(r) + " 0")
	}
	return(cnt/niter)
}

real colvector odam_ordidx_from_vals(real colvector ordvals, real colvector cvals)
{
	real scalar K, i, k, hit
	real colvector ordidx0

	K = rows(cvals)
	ordidx0 = J(K,1,.)
	for (i=1; i<=K; i++) {
		hit = 0
		for (k=1; k<=K; k++) {
			if (ordvals[i]==cvals[k]) {
				ordidx0[i] = k
				hit = 1
				break
			}
		}
		if (!hit) {
			errprintf("direction(): value %g is not a level of the classvar\n", ordvals[i])
			exit(198)
		}
	}
	return(ordidx0)
}

real scalar odamK_fit_ordered(real colvector a, real colvector cls, real colvector w,
	real colvector cvals, real scalar priors, real colvector ordidx,
	real colvector cps, string scalar primarycrit)
{
	real colvector uvals, effw, segEndIdx
	real scalar nu, K, i, j, k, n, cntk, bestval, bestj, val
	real matrix binwtOrd, prefix, dp, dpj
	real scalar segIstart, b, lastRel, firstRel, israndom, ncand, pick

	uvals = uniqrows(a)
	nu = rows(uvals)
	K  = rows(cvals)
	n  = rows(a)
	israndom = (primarycrit=="random")

	if (nu < K) return(.)

	if (priors) {
		effw = J(n,1,0)
		for (k=1; k<=K; k++) {
			cntk = sum(cls:==cvals[k])
			if (cntk>0) effw = effw :+ (cls:==cvals[k]) :* (w :/ cntk)
		}
	}
	else effw = w

	binwtOrd = J(nu,K,0)
	for (i=1; i<=nu; i++) {
		for (k=1; k<=K; k++) {
			binwtOrd[i,k] = sum(effw :* (a:==uvals[i]) :* (cls:==cvals[ordidx[k]]))
		}
	}
	prefix = J(nu+1,K,0)
	for (i=1; i<=nu; i++) prefix[i+1,.] = prefix[i,.] + binwtOrd[i,.]

	dp  = J(nu+1, K+1, .)
	dpj = J(nu+1, K+1, .)
	dp[1,1] = 0
	for (i=1; i<=nu; i++) {
		for (k=1; k<=K; k++) {
			bestval = .
			bestj = .
			for (j=0; j<=i-1; j++) {
				if (dp[j+1,k]==.) continue
				val = dp[j+1,k] + (prefix[i+1,k]-prefix[j+1,k])
				if (bestval==. | val > bestval) {
					bestval = val
					bestj = j
				}
			}
			dp[i+1,k+1]  = bestval
			dpj[i+1,k+1] = bestj
		}
	}

	if (dp[nu+1,K+1]==.) return(.)

	segEndIdx = J(K,1,.)
	i = nu
	k = K
	while (k>0) {
		segEndIdx[k] = i
		i = dpj[i+1,k+1]
		k--
	}

	cps = J(K-1,1,.)
	for (i=1; i<=K-1; i++) {
		segIstart = (i==1 ? 1 : segEndIdx[i-1]+1)
		lastRel = .
		for (b=segEndIdx[i]; b>=segIstart; b--) {
			if (binwtOrd[b,i] > 0) {
				lastRel = b
				break
			}
		}
		if (lastRel==.) lastRel = segEndIdx[i]

		firstRel = .
		for (b=segEndIdx[i]+1; b<=segEndIdx[i+1]; b++) {
			if (binwtOrd[b,i+1] > 0) {
				firstRel = b
				break
			}
		}
		if (firstRel==.) firstRel = segEndIdx[i]+1

		if (israndom) {
			ncand = firstRel - lastRel
			pick = lastRel - 1 + ceil(uniform(1,1)*ncand)
			cps[i] = (uvals[pick] + uvals[pick+1]) / 2
		}
		else {
			cps[i] = (uvals[lastRel] + uvals[firstRel]) / 2
		}
	}

	return(dp[nu+1,K+1])
}

void odamK_loo(real colvector a, real colvector cls, real colvector w,
	real colvector cvals, real scalar priors, real scalar degen,
	real colvector ordidx, real scalar dots, string scalar primarycrit,
	real matrix conf_unw, real matrix conf_wtd, real colvector loopred)
{
	real scalar n, i, k, K
	real colvector idx, asub, clssub, wsub, cps, segl, pred1
	real scalar val

	n = rows(cls)
	K = rows(cvals)
	segl = J(K,1,.)
	for (k=1; k<=K; k++) segl[k] = cvals[ordidx[k]]

	conf_unw = J(K,K,0)
	conf_wtd = J(K,K,0)
	loopred = J(n,1,.)
	if (dots) {
		odam_dots_header("Leave-one-out cross-validation (" + strofreal(n) + " observations):")
		stata("_dots 0 0")
	}
	for (i=1; i<=n; i++) {
		idx = select(1::n, (1::n):!=i)
		asub = a[idx]; clssub = cls[idx]; wsub = w[idx]
		val = odamK_fit_ordered(asub, clssub, wsub, cvals, priors, ordidx, cps, primarycrit)
		if (val==.) {
			if (dots) stata("_dots " + strofreal(i) + " 0")
			continue
		}
		pred1 = odamK_predict(J(1,1,a[i]), cps, segl)
		loopred[i] = pred1[1]
		conf_unw = conf_unw + odamK_confusion(J(1,1,cls[i]), pred1, J(1,1,1), cvals)
		conf_wtd = conf_wtd + odamK_confusion(J(1,1,cls[i]), pred1, J(1,1,w[i]), cvals)
		if (dots) stata("_dots " + strofreal(i) + " 0")
	}
}

void odamK_ci_driver(string scalar cvar, string scalar avar, string scalar wvar,
	string scalar istrainvar,
	real scalar priors, real scalar degen, real scalar reps, real scalar doloo,
	string scalar ordstr, string scalar primarycrit, real scalar cilevel, real scalar dots,
	real scalar iscat, string scalar gvar, string scalar secondarycrit)
{
	real colvector cls, a, w, cvals, idx, isoob, clsb, ab, wb, cpsb, seglabelsb
	real colvector clsoob, aoob, woob, predb, predoob, ordvals, ordidx0
	real colvector catvalsb, catmodelb
	real matrix conf, trainboot, looboot, trainbootwtd, loobootwtd, boundstr, boundsloo, boundstrwtd, boundsloowtd
	real matrix trainbootpac, trainbootpacwtd, trainbootpv, trainbootpvwtd
	real matrix loobootpac, loobootpacwtd, loobootpv, loobootpvwtd
	real matrix boundstrpac, boundstrpacwtd, boundstrpv, boundstrpvwtd
	real matrix boundsloopac, boundsloopacwtd, boundsloopv, boundsloopvwtd
	real scalar n, K, r, i, j, obj, fixedord, alpha
	real scalar overall, meanpac, meanpv, ess_pac, ess_pv, ess_total
	real colvector pac, pv
	real colvector ist, trainidx, istoob, selidxtr
	real scalar ntrain
	real colvector grp, gv, grpb, grpoob, selidx
	real scalar G, g, gengroups
	real matrix trainbootgen, trainbootgenwtd, loobootgen, loobootgenwtd
	real matrix boundstrgen, boundstrgenwtd, boundsloogen, boundsloogenwtd
	real matrix trainbootgenpac, trainbootgenpacwtd, trainbootgenpv, trainbootgenpvwtd
	real matrix loobootgenpac, loobootgenpacwtd, loobootgenpv, loobootgenpvwtd
	real matrix boundstrgenpac, boundstrgenpacwtd, boundstrgenpv, boundstrgenpvwtd
	real matrix boundsloogenpac, boundsloogenpacwtd, boundsloogenpv, boundsloogenpvwtd
	real matrix confg
	real scalar overallg, meanpacg, meanpvg, ess_pacg, ess_pvg, ess_totalg
	real colvector pacg, pvg
	real scalar docrossoob

	cls = st_data(., cvar)
	a   = st_data(., avar)
	w   = st_data(., wvar)
	n   = rows(cls)
	cvals = uniqrows(cls)
	K = rows(cvals)
	ist = st_data(., istrainvar)
	trainidx = selectindex(ist:==1)
	ntrain = rows(trainidx)

	gengroups = (gvar!="")
	docrossoob = gengroups & (ntrain < n)
	if (gengroups) {
		grp = st_data(., gvar)
		gv  = uniqrows(grp)
		G   = rows(gv)
		trainbootgen    = J(reps, G*4, .)
		trainbootgenwtd = J(reps, G*4, .)
		loobootgen      = ((doloo | docrossoob) ? J(reps, G*4, .) : J(0, G*4, .))
		loobootgenwtd   = ((doloo | docrossoob) ? J(reps, G*4, .) : J(0, G*4, .))
		trainbootgenpac    = J(reps, G*K, .)
		trainbootgenpacwtd = J(reps, G*K, .)
		trainbootgenpv     = J(reps, G*K, .)
		trainbootgenpvwtd  = J(reps, G*K, .)
		loobootgenpac       = ((doloo | docrossoob) ? J(reps, G*K, .) : J(0, G*K, .))
		loobootgenpacwtd    = ((doloo | docrossoob) ? J(reps, G*K, .) : J(0, G*K, .))
		loobootgenpv        = ((doloo | docrossoob) ? J(reps, G*K, .) : J(0, G*K, .))
		loobootgenpvwtd     = ((doloo | docrossoob) ? J(reps, G*K, .) : J(0, G*K, .))
	}

	fixedord = (!iscat) & (ordstr != "")
	if (fixedord) {
		ordvals = strtoreal(tokens(ordstr))'
		ordidx0 = odam_ordidx_from_vals(ordvals, cvals)
	}

	trainboot       = J(reps,4,.)
	trainbootwtd    = J(reps,4,.)
	looboot         = (doloo ? J(reps,4,.) : J(0,4,.))
	loobootwtd      = (doloo ? J(reps,4,.) : J(0,4,.))
	trainbootpac    = J(reps,K,.)
	trainbootpacwtd = J(reps,K,.)
	trainbootpv     = J(reps,K,.)
	trainbootpvwtd  = J(reps,K,.)
	loobootpac      = (doloo ? J(reps,K,.) : J(0,K,.))
	loobootpacwtd   = (doloo ? J(reps,K,.) : J(0,K,.))
	loobootpv       = (doloo ? J(reps,K,.) : J(0,K,.))
	loobootpvwtd    = (doloo ? J(reps,K,.) : J(0,K,.))

	if (dots) {
		odam_dots_header("Bootstrap confidence intervals (" + strofreal(reps) + " replications):")
		stata("_dots 0 0")
	}
	for (r=1; r<=reps; r++) {
		idx = trainidx[ceil(uniform(ntrain,1)*ntrain)]
		clsb = cls[idx]
		ab   = a[idx]
		wb   = w[idx]

		if (iscat)          obj = odamK_fit_cat(ab, clsb, wb, cvals, priors, catvalsb, catmodelb, primarycrit, secondarycrit)
		else if (fixedord)  obj = odamK_fit_ordered(ab, clsb, wb, cvals, priors, ordidx0, cpsb, primarycrit)
		else                obj = odamK_fit(ab, clsb, wb, cvals, priors, degen, cpsb, seglabelsb, primarycrit)
		if (obj==.) {
			if (dots) stata("_dots " + strofreal(r) + " 0")
			continue
		}

		if (fixedord) {
			seglabelsb = J(K,1,.)
			for (i=1; i<=K; i++) seglabelsb[i] = cvals[ordidx0[i]]
		}

		predb = (iscat ? odamK_predict_cat(ab, catvalsb, catmodelb, cvals[1]) : odamK_predict(ab, cpsb, seglabelsb))
		conf = odamK_confusion(clsb, predb, J(ntrain,1,1), cvals)
		odamK_metrics(conf, overall, meanpac, meanpv, pac, pv)
		ess_pac = odamK_ess(meanpac, K)
		ess_pv  = odamK_ess(meanpv, K)
		ess_total = (ess_pac!=. & ess_pv!=. ? (ess_pac+ess_pv)/2 : .)
		trainboot[r,.] = (ess_pac, overall, ess_pv, ess_total)
		trainbootpac[r,.] = pac'
		trainbootpv[r,.] = pv'

		conf = odamK_confusion(clsb, predb, wb, cvals)
		odamK_metrics(conf, overall, meanpac, meanpv, pac, pv)
		ess_pac = odamK_ess(meanpac, K)
		ess_pv  = odamK_ess(meanpv, K)
		ess_total = (ess_pac!=. & ess_pv!=. ? (ess_pac+ess_pv)/2 : .)
		trainbootwtd[r,.] = (ess_pac, overall, ess_pv, ess_total)
		trainbootpacwtd[r,.] = pac'
		trainbootpvwtd[r,.] = pv'

		if (gengroups) {
			grpb = grp[idx]
			for (g=1; g<=G; g++) {
				selidx = selectindex(grpb :== gv[g])
				if (rows(selidx)>0) {
					confg = odamK_confusion(clsb[selidx], predb[selidx], J(rows(selidx),1,1), cvals)
					odamK_metrics(confg, overallg, meanpacg, meanpvg, pacg, pvg)
					ess_pacg = odamK_ess(meanpacg, K)
					ess_pvg  = odamK_ess(meanpvg, K)
					ess_totalg = (ess_pacg!=. & ess_pvg!=. ? (ess_pacg+ess_pvg)/2 : .)
					trainbootgen[r,(g-1)*4+1] = ess_pacg
					trainbootgen[r,(g-1)*4+2] = overallg
					trainbootgen[r,(g-1)*4+3] = ess_pvg
					trainbootgen[r,(g-1)*4+4] = ess_totalg
					trainbootgenpac[|r,(g-1)*K+1 \ r,g*K|] = pacg'
					trainbootgenpv[|r,(g-1)*K+1 \ r,g*K|]  = pvg'

					confg = odamK_confusion(clsb[selidx], predb[selidx], wb[selidx], cvals)
					odamK_metrics(confg, overallg, meanpacg, meanpvg, pacg, pvg)
					ess_pacg = odamK_ess(meanpacg, K)
					ess_pvg  = odamK_ess(meanpvg, K)
					ess_totalg = (ess_pacg!=. & ess_pvg!=. ? (ess_pacg+ess_pvg)/2 : .)
					trainbootgenwtd[r,(g-1)*4+1] = ess_pacg
					trainbootgenwtd[r,(g-1)*4+2] = overallg
					trainbootgenwtd[r,(g-1)*4+3] = ess_pvg
					trainbootgenwtd[r,(g-1)*4+4] = ess_totalg
					trainbootgenpacwtd[|r,(g-1)*K+1 \ r,g*K|] = pacg'
					trainbootgenpvwtd[|r,(g-1)*K+1 \ r,g*K|]  = pvg'
				}
			}
		}

		if (doloo | docrossoob) {
			isoob = J(n,1,1)
			for (i=1; i<=ntrain; i++) isoob[idx[i]] = 0
			if (sum(isoob)>0) {
				clsoob = select(cls, isoob)
				aoob   = select(a,   isoob)
				woob   = select(w,   isoob)
				istoob = select(ist, isoob)
				predoob = (iscat ? odamK_predict_cat(aoob, catvalsb, catmodelb, cvals[1]) : odamK_predict(aoob, cpsb, seglabelsb))
				if (doloo) {
				selidxtr = selectindex(istoob:==1)
				if (rows(selidxtr)>0) {
				conf = odamK_confusion(clsoob[selidxtr], predoob[selidxtr], J(rows(selidxtr),1,1), cvals)
				odamK_metrics(conf, overall, meanpac, meanpv, pac, pv)
				ess_pac = odamK_ess(meanpac, K)
				ess_pv  = odamK_ess(meanpv, K)
				ess_total = (ess_pac!=. & ess_pv!=. ? (ess_pac+ess_pv)/2 : .)
				looboot[r,.] = (ess_pac, overall, ess_pv, ess_total)
				loobootpac[r,.] = pac'
				loobootpv[r,.] = pv'

				conf = odamK_confusion(clsoob[selidxtr], predoob[selidxtr], woob[selidxtr], cvals)
				odamK_metrics(conf, overall, meanpac, meanpv, pac, pv)
				ess_pac = odamK_ess(meanpac, K)
				ess_pv  = odamK_ess(meanpv, K)
				ess_total = (ess_pac!=. & ess_pv!=. ? (ess_pac+ess_pv)/2 : .)
				loobootwtd[r,.] = (ess_pac, overall, ess_pv, ess_total)
				loobootpacwtd[r,.] = pac'
				loobootpvwtd[r,.] = pv'
				}
				}

				if (gengroups) {
					grpoob = select(grp, isoob)
					for (g=1; g<=G; g++) {
						selidx = selectindex(grpoob :== gv[g])
						if (rows(selidx)>0) {
							confg = odamK_confusion(clsoob[selidx], predoob[selidx], J(rows(selidx),1,1), cvals)
							odamK_metrics(confg, overallg, meanpacg, meanpvg, pacg, pvg)
							ess_pacg = odamK_ess(meanpacg, K)
							ess_pvg  = odamK_ess(meanpvg, K)
							ess_totalg = (ess_pacg!=. & ess_pvg!=. ? (ess_pacg+ess_pvg)/2 : .)
							loobootgen[r,(g-1)*4+1] = ess_pacg
							loobootgen[r,(g-1)*4+2] = overallg
							loobootgen[r,(g-1)*4+3] = ess_pvg
							loobootgen[r,(g-1)*4+4] = ess_totalg
							loobootgenpac[|r,(g-1)*K+1 \ r,g*K|] = pacg'
							loobootgenpv[|r,(g-1)*K+1 \ r,g*K|]  = pvg'

							confg = odamK_confusion(clsoob[selidx], predoob[selidx], woob[selidx], cvals)
							odamK_metrics(confg, overallg, meanpacg, meanpvg, pacg, pvg)
							ess_pacg = odamK_ess(meanpacg, K)
							ess_pvg  = odamK_ess(meanpvg, K)
							ess_totalg = (ess_pacg!=. & ess_pvg!=. ? (ess_pacg+ess_pvg)/2 : .)
							loobootgenwtd[r,(g-1)*4+1] = ess_pacg
							loobootgenwtd[r,(g-1)*4+2] = overallg
							loobootgenwtd[r,(g-1)*4+3] = ess_pvg
							loobootgenwtd[r,(g-1)*4+4] = ess_totalg
							loobootgenpacwtd[|r,(g-1)*K+1 \ r,g*K|] = pacg'
							loobootgenpvwtd[|r,(g-1)*K+1 \ r,g*K|]  = pvg'
						}
					}
				}
			}
		}
		if (dots) stata("_dots " + strofreal(r) + " 0")
	}

	alpha = (1-cilevel/100)/2
	boundstr = J(4,2,.)
	boundstrwtd = J(4,2,.)
	for (j=1; j<=4; j++) {
		boundstr[j,1] = odam_boot_percentile(trainboot[.,j], alpha)
		boundstr[j,2] = odam_boot_percentile(trainboot[.,j], 1-alpha)
		boundstrwtd[j,1] = odam_boot_percentile(trainbootwtd[.,j], alpha)
		boundstrwtd[j,2] = odam_boot_percentile(trainbootwtd[.,j], 1-alpha)
	}
	st_matrix("r_ci_train_bounds", boundstr)
	st_matrix("r_ci_train_bounds_wtd", boundstrwtd)

	boundstrpac = J(K,2,.)
	boundstrpacwtd = J(K,2,.)
	boundstrpv = J(K,2,.)
	boundstrpvwtd = J(K,2,.)
	for (j=1; j<=K; j++) {
		boundstrpac[j,1] = odam_boot_percentile(trainbootpac[.,j], alpha)
		boundstrpac[j,2] = odam_boot_percentile(trainbootpac[.,j], 1-alpha)
		boundstrpacwtd[j,1] = odam_boot_percentile(trainbootpacwtd[.,j], alpha)
		boundstrpacwtd[j,2] = odam_boot_percentile(trainbootpacwtd[.,j], 1-alpha)
		boundstrpv[j,1] = odam_boot_percentile(trainbootpv[.,j], alpha)
		boundstrpv[j,2] = odam_boot_percentile(trainbootpv[.,j], 1-alpha)
		boundstrpvwtd[j,1] = odam_boot_percentile(trainbootpvwtd[.,j], alpha)
		boundstrpvwtd[j,2] = odam_boot_percentile(trainbootpvwtd[.,j], 1-alpha)
	}
	st_matrix("r_ci_train_pac_bounds", boundstrpac)
	st_matrix("r_ci_train_pac_bounds_wtd", boundstrpacwtd)
	st_matrix("r_ci_train_pv_bounds", boundstrpv)
	st_matrix("r_ci_train_pv_bounds_wtd", boundstrpvwtd)

	if (doloo) {
		boundsloo = J(4,2,.)
		boundsloowtd = J(4,2,.)
		for (j=1; j<=4; j++) {
			boundsloo[j,1] = odam_boot_percentile(looboot[.,j], alpha)
			boundsloo[j,2] = odam_boot_percentile(looboot[.,j], 1-alpha)
			boundsloowtd[j,1] = odam_boot_percentile(loobootwtd[.,j], alpha)
			boundsloowtd[j,2] = odam_boot_percentile(loobootwtd[.,j], 1-alpha)
		}
		st_matrix("r_ci_loo_bounds", boundsloo)
		st_matrix("r_ci_loo_bounds_wtd", boundsloowtd)

		boundsloopac = J(K,2,.)
		boundsloopacwtd = J(K,2,.)
		boundsloopv = J(K,2,.)
		boundsloopvwtd = J(K,2,.)
		for (j=1; j<=K; j++) {
			boundsloopac[j,1] = odam_boot_percentile(loobootpac[.,j], alpha)
			boundsloopac[j,2] = odam_boot_percentile(loobootpac[.,j], 1-alpha)
			boundsloopacwtd[j,1] = odam_boot_percentile(loobootpacwtd[.,j], alpha)
			boundsloopacwtd[j,2] = odam_boot_percentile(loobootpacwtd[.,j], 1-alpha)
			boundsloopv[j,1] = odam_boot_percentile(loobootpv[.,j], alpha)
			boundsloopv[j,2] = odam_boot_percentile(loobootpv[.,j], 1-alpha)
			boundsloopvwtd[j,1] = odam_boot_percentile(loobootpvwtd[.,j], alpha)
			boundsloopvwtd[j,2] = odam_boot_percentile(loobootpvwtd[.,j], 1-alpha)
		}
		st_matrix("r_ci_loo_pac_bounds", boundsloopac)
		st_matrix("r_ci_loo_pac_bounds_wtd", boundsloopacwtd)
		st_matrix("r_ci_loo_pv_bounds", boundsloopv)
		st_matrix("r_ci_loo_pv_bounds_wtd", boundsloopvwtd)
	}

	if (gengroups) {
		boundstrgen = J(G*4,2,.)
		boundstrgenwtd = J(G*4,2,.)
		for (g=1; g<=G; g++) {
			for (j=1; j<=4; j++) {
				boundstrgen[(g-1)*4+j,1] = odam_boot_percentile(trainbootgen[.,(g-1)*4+j], alpha)
				boundstrgen[(g-1)*4+j,2] = odam_boot_percentile(trainbootgen[.,(g-1)*4+j], 1-alpha)
				boundstrgenwtd[(g-1)*4+j,1] = odam_boot_percentile(trainbootgenwtd[.,(g-1)*4+j], alpha)
				boundstrgenwtd[(g-1)*4+j,2] = odam_boot_percentile(trainbootgenwtd[.,(g-1)*4+j], 1-alpha)
			}
		}
		st_matrix("r_K_ci_gen_train_bounds", boundstrgen)
		st_matrix("r_K_ci_gen_train_bounds_wtd", boundstrgenwtd)

		boundstrgenpac = J(G*K,2,.)
		boundstrgenpacwtd = J(G*K,2,.)
		boundstrgenpv = J(G*K,2,.)
		boundstrgenpvwtd = J(G*K,2,.)
		for (g=1; g<=G; g++) {
			for (j=1; j<=K; j++) {
				boundstrgenpac[(g-1)*K+j,1] = odam_boot_percentile(trainbootgenpac[.,(g-1)*K+j], alpha)
				boundstrgenpac[(g-1)*K+j,2] = odam_boot_percentile(trainbootgenpac[.,(g-1)*K+j], 1-alpha)
				boundstrgenpacwtd[(g-1)*K+j,1] = odam_boot_percentile(trainbootgenpacwtd[.,(g-1)*K+j], alpha)
				boundstrgenpacwtd[(g-1)*K+j,2] = odam_boot_percentile(trainbootgenpacwtd[.,(g-1)*K+j], 1-alpha)
				boundstrgenpv[(g-1)*K+j,1] = odam_boot_percentile(trainbootgenpv[.,(g-1)*K+j], alpha)
				boundstrgenpv[(g-1)*K+j,2] = odam_boot_percentile(trainbootgenpv[.,(g-1)*K+j], 1-alpha)
				boundstrgenpvwtd[(g-1)*K+j,1] = odam_boot_percentile(trainbootgenpvwtd[.,(g-1)*K+j], alpha)
				boundstrgenpvwtd[(g-1)*K+j,2] = odam_boot_percentile(trainbootgenpvwtd[.,(g-1)*K+j], 1-alpha)
			}
		}
		st_matrix("r_K_ci_gen_train_pac_bounds", boundstrgenpac)
		st_matrix("r_K_ci_gen_train_pac_bounds_wtd", boundstrgenpacwtd)
		st_matrix("r_K_ci_gen_train_pv_bounds", boundstrgenpv)
		st_matrix("r_K_ci_gen_train_pv_bounds_wtd", boundstrgenpvwtd)

		if (doloo | docrossoob) {
			boundsloogen = J(G*4,2,.)
			boundsloogenwtd = J(G*4,2,.)
			for (g=1; g<=G; g++) {
				for (j=1; j<=4; j++) {
					boundsloogen[(g-1)*4+j,1] = odam_boot_percentile(loobootgen[.,(g-1)*4+j], alpha)
					boundsloogen[(g-1)*4+j,2] = odam_boot_percentile(loobootgen[.,(g-1)*4+j], 1-alpha)
					boundsloogenwtd[(g-1)*4+j,1] = odam_boot_percentile(loobootgenwtd[.,(g-1)*4+j], alpha)
					boundsloogenwtd[(g-1)*4+j,2] = odam_boot_percentile(loobootgenwtd[.,(g-1)*4+j], 1-alpha)
				}
			}
			st_matrix("r_K_ci_gen_loo_bounds", boundsloogen)
			st_matrix("r_K_ci_gen_loo_bounds_wtd", boundsloogenwtd)

			boundsloogenpac = J(G*K,2,.)
			boundsloogenpacwtd = J(G*K,2,.)
			boundsloogenpv = J(G*K,2,.)
			boundsloogenpvwtd = J(G*K,2,.)
			for (g=1; g<=G; g++) {
				for (j=1; j<=K; j++) {
					boundsloogenpac[(g-1)*K+j,1] = odam_boot_percentile(loobootgenpac[.,(g-1)*K+j], alpha)
					boundsloogenpac[(g-1)*K+j,2] = odam_boot_percentile(loobootgenpac[.,(g-1)*K+j], 1-alpha)
					boundsloogenpacwtd[(g-1)*K+j,1] = odam_boot_percentile(loobootgenpacwtd[.,(g-1)*K+j], alpha)
					boundsloogenpacwtd[(g-1)*K+j,2] = odam_boot_percentile(loobootgenpacwtd[.,(g-1)*K+j], 1-alpha)
					boundsloogenpv[(g-1)*K+j,1] = odam_boot_percentile(loobootgenpv[.,(g-1)*K+j], alpha)
					boundsloogenpv[(g-1)*K+j,2] = odam_boot_percentile(loobootgenpv[.,(g-1)*K+j], 1-alpha)
					boundsloogenpvwtd[(g-1)*K+j,1] = odam_boot_percentile(loobootgenpvwtd[.,(g-1)*K+j], alpha)
					boundsloogenpvwtd[(g-1)*K+j,2] = odam_boot_percentile(loobootgenpvwtd[.,(g-1)*K+j], 1-alpha)
				}
			}
			st_matrix("r_K_ci_gen_loo_pac_bounds", boundsloogenpac)
			st_matrix("r_K_ci_gen_loo_pac_bounds_wtd", boundsloogenpacwtd)
			st_matrix("r_K_ci_gen_loo_pv_bounds", boundsloogenpv)
			st_matrix("r_K_ci_gen_loo_pv_bounds_wtd", boundsloogenpvwtd)
		}
	}
}

real scalar odamK_permtest_loo(real colvector a, real colvector cls, real colvector w,
	real colvector cvals, real scalar priors, real scalar degen,
	real scalar obsmeanpac, real scalar niter, real scalar dots,
	string scalar primarycrit)
{
	real scalar r, cnt, n, i, k, K, objp
	real colvector clsp, cpsp, seglabelsp, ordidxp, loopreddummy
	real matrix conf_unw, conf_wtd
	real scalar overall, meanpac, meanpv
	real colvector pac, pv

	n = rows(cls)
	K = rows(cvals)
	cnt = 0
	if (dots) {
		odam_dots_header("LOO permutation test (" + strofreal(niter) + " iterations, " + strofreal(n) + " LOO refits each):")
		stata("_dots 0 0")
	}
	for (r=1; r<=niter; r++) {
		clsp = cls[jumble(1::n)]
		objp = odamK_fit(a, clsp, w, cvals, priors, degen, cpsp, seglabelsp, primarycrit)
		if (objp!=.) {
			ordidxp = J(K,1,.)
			for (i=1; i<=K; i++) {
				for (k=1; k<=K; k++) {
					if (seglabelsp[i]==cvals[k]) {
						ordidxp[i] = k
						break
					}
				}
			}
			odamK_loo(a, clsp, w, cvals, priors, degen, ordidxp, 0, primarycrit, conf_unw, conf_wtd, loopreddummy)
			odamK_metrics(conf_wtd, overall, meanpac, meanpv, pac, pv)
			if (meanpac!=. & meanpac >= obsmeanpac) cnt++
		}
		if (dots) stata("_dots " + strofreal(r) + " 0")
	}
	return(cnt/niter)
}

real scalar odamK_permtest_loo_ordered(real colvector a, real colvector cls, real colvector w,
	real colvector cvals, real scalar priors, real scalar degen,
	real colvector ordidx0, real scalar obsmeanpac, real scalar niter,
	real scalar dots, string scalar primarycrit)
{
	real scalar r, cnt, n
	real colvector clsp, loopreddummy
	real matrix conf_unw, conf_wtd
	real scalar overall, meanpac, meanpv
	real colvector pac, pv

	n = rows(cls)
	cnt = 0
	if (dots) {
		odam_dots_header("LOO permutation test (" + strofreal(niter) + " iterations, " + strofreal(n) + " LOO refits each):")
		stata("_dots 0 0")
	}
	for (r=1; r<=niter; r++) {
		clsp = cls[jumble(1::n)]
		odamK_loo(a, clsp, w, cvals, priors, degen, ordidx0, 0, primarycrit, conf_unw, conf_wtd, loopreddummy)
		odamK_metrics(conf_wtd, overall, meanpac, meanpv, pac, pv)
		if (meanpac!=. & meanpac >= obsmeanpac) cnt++
		if (dots) stata("_dots " + strofreal(r) + " 0")
	}
	return(cnt/niter)
}

real scalar odamK_permtest_loo_cat(real colvector a, real colvector cls, real colvector w,
	real colvector cvals, real scalar priors, real scalar obsmeanpac,
	real scalar niter, real scalar dots, string scalar primarycrit,
	string scalar secondarycrit)
{
	real scalar r, cnt, n
	real colvector clsp, loopreddummy
	real matrix conf_unw, conf_wtd
	real scalar overall, meanpac, meanpv
	real colvector pac, pv

	n = rows(cls)
	cnt = 0
	if (dots) {
		odam_dots_header("LOO permutation test (" + strofreal(niter) + " iterations, " + strofreal(n) + " LOO refits each):")
		stata("_dots 0 0")
	}
	for (r=1; r<=niter; r++) {
		clsp = cls[jumble(1::n)]
		odamK_loo_cat(a, clsp, w, cvals, priors, 0, conf_unw, conf_wtd, loopreddummy, primarycrit, secondarycrit)
		odamK_metrics(conf_wtd, overall, meanpac, meanpv, pac, pv)
		if (meanpac!=. & meanpac >= obsmeanpac) cnt++
		if (dots) stata("_dots " + strofreal(r) + " 0")
	}
	return(cnt/niter)
}

void odamK_gen_breakdown(real colvector grp, real colvector cls, real colvector cvals,
	real colvector trainpred, real colvector loopred, real scalar doloo, real colvector w)
{
	real colvector gv, selidx, valididx, clsg, predg, wg, loopredg
	real matrix conf, outagg, outpac_tr, outpv_tr, outpac_trw, outpv_trw
	real matrix outpac_lo, outpv_lo, outpac_low, outpv_low
	real scalar G, K, g, n, nloo_g
	real scalar overall, meanpac, meanpv, ess_pac, ess_pv, ess_total
	real colvector pac, pv

	gv = uniqrows(grp)
	G = rows(gv)
	K = rows(cvals)
	outagg = J(G,18,.)
	outpac_tr  = J(G,K,.); outpv_tr  = J(G,K,.)
	outpac_trw = J(G,K,.); outpv_trw = J(G,K,.)
	outpac_lo  = J(G,K,.); outpv_lo  = J(G,K,.)
	outpac_low = J(G,K,.); outpv_low = J(G,K,.)

	for (g=1; g<=G; g++) {
		selidx = selectindex(grp:==gv[g])
		n = rows(selidx)
		clsg = cls[selidx]; predg = trainpred[selidx]; wg = w[selidx]
		outagg[g,1] = gv[g]
		outagg[g,2] = n

		conf = odamK_confusion(clsg, predg, J(n,1,1), cvals)
		odamK_metrics(conf, overall, meanpac, meanpv, pac, pv)
		ess_pac = odamK_ess(meanpac, K)
		ess_pv  = odamK_ess(meanpv, K)
		ess_total = (ess_pac!=. & ess_pv!=. ? (ess_pac+ess_pv)/2 : .)
		outagg[g,3]=ess_pac; outagg[g,4]=overall; outagg[g,5]=ess_pv; outagg[g,6]=ess_total
		outpac_tr[g,.] = pac'
		outpv_tr[g,.]  = pv'

		conf = odamK_confusion(clsg, predg, wg, cvals)
		odamK_metrics(conf, overall, meanpac, meanpv, pac, pv)
		ess_pac = odamK_ess(meanpac, K)
		ess_pv  = odamK_ess(meanpv, K)
		ess_total = (ess_pac!=. & ess_pv!=. ? (ess_pac+ess_pv)/2 : .)
		outagg[g,7]=ess_pac; outagg[g,8]=overall; outagg[g,9]=ess_pv; outagg[g,10]=ess_total
		outpac_trw[g,.] = pac'
		outpv_trw[g,.]  = pv'

		if (doloo) {
			loopredg = loopred[selidx]
			valididx = selectindex(loopredg:!=.)
			nloo_g = rows(valididx)
			if (nloo_g>0) {
				conf = odamK_confusion(clsg[valididx], loopredg[valididx], J(nloo_g,1,1), cvals)
				odamK_metrics(conf, overall, meanpac, meanpv, pac, pv)
				ess_pac = odamK_ess(meanpac, K)
				ess_pv  = odamK_ess(meanpv, K)
				ess_total = (ess_pac!=. & ess_pv!=. ? (ess_pac+ess_pv)/2 : .)
				outagg[g,11]=ess_pac; outagg[g,12]=overall; outagg[g,13]=ess_pv; outagg[g,14]=ess_total
				outpac_lo[g,.] = pac'
				outpv_lo[g,.]  = pv'

				conf = odamK_confusion(clsg[valididx], loopredg[valididx], wg[valididx], cvals)
				odamK_metrics(conf, overall, meanpac, meanpv, pac, pv)
				ess_pac = odamK_ess(meanpac, K)
				ess_pv  = odamK_ess(meanpv, K)
				ess_total = (ess_pac!=. & ess_pv!=. ? (ess_pac+ess_pv)/2 : .)
				outagg[g,15]=ess_pac; outagg[g,16]=overall; outagg[g,17]=ess_pv; outagg[g,18]=ess_total
				outpac_low[g,.] = pac'
				outpv_low[g,.]  = pv'
			}
		}
	}
	st_matrix("r_K_gen_breakdown",     outagg)
	st_matrix("r_K_gen_pac_train",     outpac_tr)
	st_matrix("r_K_gen_pv_train",      outpv_tr)
	st_matrix("r_K_gen_pac_train_wtd", outpac_trw)
	st_matrix("r_K_gen_pv_train_wtd",  outpv_trw)
	st_matrix("r_K_gen_pac_loo",       outpac_lo)
	st_matrix("r_K_gen_pv_loo",        outpv_lo)
	st_matrix("r_K_gen_pac_loo_wtd",   outpac_low)
	st_matrix("r_K_gen_pv_loo_wtd",    outpv_low)
}

void odaK_driver(string scalar cvar, string scalar avar, string scalar wvar,
	string scalar istrainvar,
	real scalar priors, real scalar degen, real scalar niter, real scalar doloo,
	real scalar nloo, real scalar dots, real scalar iscat, string scalar ordstr,
	string scalar predvar, string scalar primarycrit, string scalar loopredvar,
	string scalar secondarycrit)
{
	real colvector cls, a, w, w1, cvals, cps, seglabels, pred, ordidx, ordvals, ordidx0
	real colvector catvals, catmodel, grp, loopred
	real colvector ist, clst, at, w1t, wt
	real scalar obj, K, overall, meanpac, meanpv, ess_pac, ess_pv, ess_total
	real scalar overall_loo, meanpac_loo, meanpv_loo, ess_pac_loo, ess_pv_loo, ess_total_loo
	real colvector pac, pv, pac_loo, pv_loo
	real scalar overall_wtd, meanpac_wtd, meanpv_wtd, ess_pac_wtd, ess_pv_wtd, ess_total_wtd
	real scalar overall_loo_wtd, meanpac_loo_wtd, meanpv_loo_wtd, ess_pac_loo_wtd, ess_pv_loo_wtd, ess_total_loo_wtd
	real colvector pac_wtd, pv_wtd, pac_loo_wtd, pv_loo_wtd
	real matrix conf, conf_loo, conf_loo_wtd
	real scalar pval, i, k, nu, fixedord

	cls = st_data(., cvar)
	a   = st_data(., avar)
	w   = st_data(., wvar)
	w1  = J(rows(cls),1,1)
	cvals = uniqrows(cls)
	K = rows(cvals)

	ist  = st_data(., istrainvar)
	clst = select(cls, ist:==1)
	at   = select(a, ist:==1)
	w1t  = select(w1, ist:==1)
	wt   = select(w, ist:==1)

	st_numscalar("r_N", sum(ist))
	st_matrix("r_K_cvals", cvals)

	fixedord = (ordstr != "")
	if (fixedord) {
		ordvals = strtoreal(tokens(ordstr))'
		ordidx0 = odam_ordidx_from_vals(ordvals, cvals)
	}

	if (iscat) {
		obj = odamK_fit_cat(at, clst, wt, cvals, priors, catvals, catmodel, primarycrit, secondarycrit)
		nu = rows(catvals)
		st_numscalar("r_K_nseg", nu)
		st_matrix("r_K_catvals",  catvals)
		st_matrix("r_K_catmodel", catmodel)

		for (k=1; k<=K; k++) {
			grp = select(catvals, catmodel:==cvals[k])
			st_global("_oda_catgrpK" + strofreal(k), odam_vec2str(grp))
		}

		pred = odamK_predict_cat(a, catvals, catmodel, cvals[1])

		if (predvar != "") st_store(., predvar, pred)

		conf = odamK_confusion(select(cls,ist:==1), select(pred,ist:==1), w1t, cvals)
		odamK_metrics(conf, overall, meanpac, meanpv, pac, pv)
		ess_pac = odamK_ess(meanpac, K)
		ess_pv  = odamK_ess(meanpv, K)
		ess_total = (ess_pac!=. & ess_pv!=. ? (ess_pac+ess_pv)/2 : .)

		st_numscalar("r_ess_train",   ess_pac)
		st_numscalar("r_overall_acc", overall)
		st_numscalar("r_ess_pv",      ess_pv)
		st_numscalar("r_ess_total",   ess_total)
		st_matrix("r_K_pac_train", pac)
		st_matrix("r_K_pv_train",  pv)

		conf = odamK_confusion(select(cls,ist:==1), select(pred,ist:==1), wt, cvals)
		odamK_metrics(conf, overall_wtd, meanpac_wtd, meanpv_wtd, pac_wtd, pv_wtd)
		ess_pac_wtd = odamK_ess(meanpac_wtd, K)
		ess_pv_wtd  = odamK_ess(meanpv_wtd, K)
		ess_total_wtd = (ess_pac_wtd!=. & ess_pv_wtd!=. ? (ess_pac_wtd+ess_pv_wtd)/2 : .)

		st_numscalar("r_ess_train_wtd",   ess_pac_wtd)
		st_numscalar("r_overall_acc_wtd", overall_wtd)
		st_numscalar("r_ess_pv_wtd",      ess_pv_wtd)
		st_numscalar("r_ess_total_wtd",   ess_total_wtd)
		st_matrix("r_K_pac_train_wtd", pac_wtd)
		st_matrix("r_K_pv_train_wtd",  pv_wtd)

		if (niter>0) {
			pval = odamK_permtest_cat(at, clst, wt, cvals, priors, obj, niter, dots)
			st_numscalar("r_est_P", pval)
		}

		if (doloo) {
			odamK_loo_cat(at, clst, wt, cvals, priors, dots, conf_loo, conf_loo_wtd, loopred, primarycrit, secondarycrit)

			if (loopredvar != "") st_store(selectindex(ist:==1), loopredvar, loopred)

			odamK_metrics(conf_loo, overall_loo, meanpac_loo, meanpv_loo, pac_loo, pv_loo)
			ess_pac_loo = odamK_ess(meanpac_loo, K)
			ess_pv_loo  = odamK_ess(meanpv_loo, K)
			ess_total_loo = (ess_pac_loo!=. & ess_pv_loo!=. ? (ess_pac_loo+ess_pv_loo)/2 : .)

			st_numscalar("r_ess_loo",         ess_pac_loo)
			st_numscalar("r_overall_acc_loo", overall_loo)
			st_numscalar("r_ess_pv_loo",      ess_pv_loo)
			st_numscalar("r_ess_total_loo",   ess_total_loo)
			st_matrix("r_K_pac_loo", pac_loo)
			st_matrix("r_K_pv_loo",  pv_loo)

			odamK_metrics(conf_loo_wtd, overall_loo_wtd, meanpac_loo_wtd, meanpv_loo_wtd, pac_loo_wtd, pv_loo_wtd)
			ess_pac_loo_wtd = odamK_ess(meanpac_loo_wtd, K)
			ess_pv_loo_wtd  = odamK_ess(meanpv_loo_wtd, K)
			ess_total_loo_wtd = (ess_pac_loo_wtd!=. & ess_pv_loo_wtd!=. ? (ess_pac_loo_wtd+ess_pv_loo_wtd)/2 : .)

			st_numscalar("r_ess_loo_wtd",         ess_pac_loo_wtd)
			st_numscalar("r_overall_acc_loo_wtd", overall_loo_wtd)
			st_numscalar("r_ess_pv_loo_wtd",      ess_pv_loo_wtd)
			st_numscalar("r_ess_total_loo_wtd",   ess_total_loo_wtd)
			st_matrix("r_K_pac_loo_wtd", pac_loo_wtd)
			st_matrix("r_K_pv_loo_wtd",  pv_loo_wtd)
			if (nloo>0) {
				if (meanpac_loo_wtd!=.) {
					pval = odamK_permtest_loo_cat(at, clst, wt, cvals, priors, meanpac_loo_wtd, nloo, dots, primarycrit, secondarycrit)
					st_numscalar("r_est_P_LOO", pval)
				}
				else st_numscalar("r_est_P_LOO", .)
			}
		}
		return
	}

	if (fixedord) {
		obj = odamK_fit_ordered(at, clst, wt, cvals, priors, ordidx0, cps, primarycrit)
		if (obj!=.) {
			seglabels = J(K,1,.)
			for (i=1; i<=K; i++) seglabels[i] = cvals[ordidx0[i]]
		}
	}
	else obj = odamK_fit_random_order(at, clst, wt, cvals, priors, degen, cps, seglabels, primarycrit, secondarycrit)

	if (obj==.) {
		st_numscalar("r_K_nseg", 0)
		st_numscalar("r_ess_train",   .)
		st_numscalar("r_overall_acc", .)
		st_numscalar("r_ess_pv",      .)
		st_numscalar("r_ess_total",   .)
		st_matrix("r_K_pac_train", J(K,1,.))
		st_matrix("r_K_pv_train",  J(K,1,.))
		st_numscalar("r_ess_train_wtd",   .)
		st_numscalar("r_overall_acc_wtd", .)
		st_numscalar("r_ess_pv_wtd",      .)
		st_numscalar("r_ess_total_wtd",   .)
		st_matrix("r_K_pac_train_wtd", J(K,1,.))
		st_matrix("r_K_pv_train_wtd",  J(K,1,.))
		if (niter>0) st_numscalar("r_est_P", .)
		if (doloo) {
			st_numscalar("r_ess_loo",         .)
			st_numscalar("r_overall_acc_loo", .)
			st_numscalar("r_ess_pv_loo",      .)
			st_numscalar("r_ess_total_loo",   .)
			st_matrix("r_K_pac_loo", J(K,1,.))
			st_matrix("r_K_pv_loo",  J(K,1,.))
			st_numscalar("r_ess_loo_wtd",         .)
			st_numscalar("r_overall_acc_loo_wtd", .)
			st_numscalar("r_ess_pv_loo_wtd",      .)
			st_numscalar("r_ess_total_loo_wtd",   .)
			st_matrix("r_K_pac_loo_wtd", J(K,1,.))
			st_matrix("r_K_pv_loo_wtd",  J(K,1,.))
			if (nloo>0) st_numscalar("r_est_P_LOO", .)
		}
		return
	}

	st_numscalar("r_K_nseg", rows(seglabels))
	st_matrix("r_K_seglabels", seglabels)
	if (rows(seglabels)>1) st_matrix("r_K_cps", cps)

	pred = odamK_predict(a, cps, seglabels)

	if (predvar != "") st_store(., predvar, pred)

	conf = odamK_confusion(select(cls,ist:==1), select(pred,ist:==1), w1t, cvals)
	odamK_metrics(conf, overall, meanpac, meanpv, pac, pv)
	ess_pac = odamK_ess(meanpac, K)
	ess_pv  = odamK_ess(meanpv, K)
	ess_total = (ess_pac!=. & ess_pv!=. ? (ess_pac+ess_pv)/2 : .)

	st_numscalar("r_ess_train",   ess_pac)
	st_numscalar("r_overall_acc", overall)
	st_numscalar("r_ess_pv",      ess_pv)
	st_numscalar("r_ess_total",   ess_total)
	st_matrix("r_K_pac_train", pac)
	st_matrix("r_K_pv_train",  pv)

	conf = odamK_confusion(select(cls,ist:==1), select(pred,ist:==1), wt, cvals)
	odamK_metrics(conf, overall_wtd, meanpac_wtd, meanpv_wtd, pac_wtd, pv_wtd)
	ess_pac_wtd = odamK_ess(meanpac_wtd, K)
	ess_pv_wtd  = odamK_ess(meanpv_wtd, K)
	ess_total_wtd = (ess_pac_wtd!=. & ess_pv_wtd!=. ? (ess_pac_wtd+ess_pv_wtd)/2 : .)

	st_numscalar("r_ess_train_wtd",   ess_pac_wtd)
	st_numscalar("r_overall_acc_wtd", overall_wtd)
	st_numscalar("r_ess_pv_wtd",      ess_pv_wtd)
	st_numscalar("r_ess_total_wtd",   ess_total_wtd)
	st_matrix("r_K_pac_train_wtd", pac_wtd)
	st_matrix("r_K_pv_train_wtd",  pv_wtd)

	if (niter>0) {
		if (fixedord) pval = odamK_permtest_ordered(at, clst, wt, cvals, priors, ordidx0, obj, niter, dots)
		else          pval = odamK_permtest(at, clst, wt, cvals, priors, degen, obj, niter, dots)
		st_numscalar("r_est_P", pval)
	}

	if (doloo) {
		ordidx = J(K,1,.)
		for (i=1; i<=K; i++) {
			for (k=1; k<=K; k++) {
				if (seglabels[i]==cvals[k]) {
					ordidx[i] = k
					break
				}
			}
		}
		odamK_loo(at, clst, wt, cvals, priors, degen, ordidx, dots, primarycrit, conf_loo, conf_loo_wtd, loopred)

		if (loopredvar != "") st_store(selectindex(ist:==1), loopredvar, loopred)

		odamK_metrics(conf_loo, overall_loo, meanpac_loo, meanpv_loo, pac_loo, pv_loo)
		ess_pac_loo = odamK_ess(meanpac_loo, K)
		ess_pv_loo  = odamK_ess(meanpv_loo, K)
		ess_total_loo = (ess_pac_loo!=. & ess_pv_loo!=. ? (ess_pac_loo+ess_pv_loo)/2 : .)

		st_numscalar("r_ess_loo",         ess_pac_loo)
		st_numscalar("r_overall_acc_loo", overall_loo)
		st_numscalar("r_ess_pv_loo",      ess_pv_loo)
		st_numscalar("r_ess_total_loo",   ess_total_loo)
		st_matrix("r_K_pac_loo", pac_loo)
		st_matrix("r_K_pv_loo",  pv_loo)

		odamK_metrics(conf_loo_wtd, overall_loo_wtd, meanpac_loo_wtd, meanpv_loo_wtd, pac_loo_wtd, pv_loo_wtd)
		ess_pac_loo_wtd = odamK_ess(meanpac_loo_wtd, K)
		ess_pv_loo_wtd  = odamK_ess(meanpv_loo_wtd, K)
		ess_total_loo_wtd = (ess_pac_loo_wtd!=. & ess_pv_loo_wtd!=. ? (ess_pac_loo_wtd+ess_pv_loo_wtd)/2 : .)

		st_numscalar("r_ess_loo_wtd",         ess_pac_loo_wtd)
		st_numscalar("r_overall_acc_loo_wtd", overall_loo_wtd)
		st_numscalar("r_ess_pv_loo_wtd",      ess_pv_loo_wtd)
		st_numscalar("r_ess_total_loo_wtd",   ess_total_loo_wtd)
		st_matrix("r_K_pac_loo_wtd", pac_loo_wtd)
		st_matrix("r_K_pv_loo_wtd",  pv_loo_wtd)

		if (nloo>0) {
			if (meanpac_loo_wtd!=.) {
				if (fixedord) pval = odamK_permtest_loo_ordered(at, clst, wt, cvals, priors, degen, ordidx0, meanpac_loo_wtd, nloo, dots, primarycrit)
				else          pval = odamK_permtest_loo(at, clst, wt, cvals, priors, degen, meanpac_loo_wtd, nloo, dots, primarycrit)
				st_numscalar("r_est_P_LOO", pval)
			}
			else st_numscalar("r_est_P_LOO", .)
		}
	}
}

end
