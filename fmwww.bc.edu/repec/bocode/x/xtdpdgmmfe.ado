*! version 2.6.2  03aug2022
*! Sebastian Kripfganz, www.kripfganz.de

*==================================================*
****** GMM linear dynamic panel data fixed-effects estimation ******

program define xtdpdgmmfe, eclass prop(xt)
	version 13.0
	if replay() {
		xtdpdgmm `0'
	}
	else {
		syntax varlist(num ts fv) [if] [in] , [	LAgs(integer 1)								///
												EXOgenous(varlist num ts fv)				///
												PREdetermined(varlist num ts fv)			///
												ENDOgenous(varlist num ts fv)				///
												ORthogonal									///
												CURtail(numlist max=1 int miss >=0)			///
												SERial(integer 0)							///
												IID											///
												INITDev										///
												STAtionary									///
												NONL										///
												ONEstep										///
												TWOstep										///
												IGMM										///
												CUgmm										///
												noCMDline									///
												Collapse TEffects							/// passthru
												NL(passthru) Model(passthru) NOLEVel		/// not allowed
												*]
		gettoken depvar indepvars : varlist
		if `lags' < 0 {
			di as err "option lags() invalid"
			exit 198
		}
		else if `lags' > 0 {
			if `lags' > 1 {
				loc predetermined	"L(1/`lags').`depvar' `predetermined'"
			}
			else {
				loc predetermined	"L.`depvar' `predetermined'"
			}
			loc predetermined	: list retok predetermined
			loc depvarlags		"L(0/`lags').`depvar'"
		}
		else {
			loc depvarlags		"`depvar'"
			loc nonl			"nonl"
		}
		if `serial' < 0 {
			di as err "option serial() invalid"
			exit 198
		}
		else if `serial' > 0 {
			if "`orthogonal'" != "" {
				di as err "options orthogonal and serial() may not be combined"
				exit 184
			}
			if "`iid'" != "" {
				di as err "options iid and serial() may not be combined"
				exit 184
			}
		}
		if `"`nl'"' != "" {
			di as err `"`nl' invalid"'
			exit 198
		}
		if `"`model'"' != "" {
			di as err `"`model' invalid"'
			exit 198
		}
		if "`nolevel'" != "" {
			di as err "nolevel invalid"
			exit 198
		}
		loc ivvars			"`endogenous' `predetermined' `exogenous'"
		loc unclassified	: list indepvars - ivvars
		if "`unclassified'" != "" {
			di as txt "note: {bf:`unclassified'} not classified as endogenous, predetermined, or exogenous"
		}

		if "`curtail'" == "" {
			loc curtail			= .
		}
		if "`initdev'" != "" {
			loc initdev			= cond("`orthogonal'" == "", " difference", " bodev")
		}
		if "`orthogonal'" == "" {
			loc model			"model(difference)"
			if "`exogenous'" != "" {
				loc exoiv			"gmmiv(`exogenous', lagrange(0 .)`initdev')"
			}
			if "`predetermined'" != "" {
				if `curtail' < 1 + `serial' {
					di as err "option curtail() incorrectly specified -- outside of allowed range"
					exit 125
				}
				loc preiv			"gmmiv(`predetermined', lagrange(`=1+`serial'' .)`initdev')"
			}
			if "`endogenous'" != "" {
				if `curtail' < 2 + `serial' {
					di as err "option curtail() incorrectly specified -- outside of allowed range"
					exit 125
				}
				loc endoiv			"gmmiv(`endogenous', lagrange(`=2+`serial'' .)`initdev')"
			}
		}
		else {
			loc model			"model(fodev)"
			if `curtail' < . {
				loc --curtail
			}
			if "`exogenous'" != "" {
				if `curtail' > 0 {
					loc exoiv			"gmmiv(`exogenous', lagrange(0 0) model(mdev)) gmmiv(`exogenous', lagrange(0 .)`initdev')"
				}
				else if "`predetermined'`endogenous'" == "" {
					loc model			"model(mdev)"
					loc exoiv			"gmmiv(`exogenous', lagrange(0 0))"
				}
				else {
					loc exoiv			"gmmiv(`exogenous', lagrange(0 0) model(mdev))"
				}
			}
			if "`predetermined'" != "" {
				if `curtail' < 0 {
					di as err "option curtail() incorrectly specified -- outside of allowed range"
					exit 125
				}
				loc preiv			"gmmiv(`predetermined', lagrange(0 .)`initdev')"
			}
			if "`endogenous'" != "" {
				if `curtail' < 1 {
					di as err "option curtail() incorrectly specified -- outside of allowed range"
					exit 125
				}
				loc endoiv			"gmmiv(`endogenous', lagrange(1 .)`initdev')"
			}
		}
		if `curtail' < . {
			loc curtail			"curtail(`curtail')"
		}
		else {
			loc curtail			""
		}
		if "`iid'" != "" {
			if "`stationary'" != "" {
				di as err "options iid and stationary may not be combined"
				exit 184
			}
			if "`initdev'" == "" {
				loc nl				= cond("`nonl'" == "", "nl(iid)", "gmmiv(L.`depvar', iid)")
			}
			else if "`endogenous'" == "" {
				loc nl				"gmmiv(L.`depvar', difference iid)"
				loc nolevel			"nolevel"
			}
		}
		else if "`nonl'" == "" & "`stationary'" == "" {
			if "`initdev'" == "" {
				loc nl				= cond(`serial' == 0, "nl(noserial)", "nl(noserial, lag(`=1+`serial''))")
			}
			else if "`endogenous'" == "" & `serial' == 0 {
				loc nl				"nl(predetermined)"
				loc nolevel			"nolevel"
			}
		}
		else if "`stationary'" != "" {
			if "`exogenous'" != "" {
				loc exoiv			"`exoiv' gmmiv(`exogenous', lagrange(0 0) difference model(level))"
			}
			if "`predetermined'" != "" {
				loc preiv			"`preiv' gmmiv(`predetermined', lagrange(`serial' `serial') difference model(level))"
			}
			if "`endogenous'" != "" {
				loc endoiv			"`endoiv' gmmiv(`endogenous', lagrange(`=1+`serial'' `=1+`serial'') difference model(level))"
			}
		}
		else {
			loc nolevel			"nolevel"
		}
		if "`onestep'`twostep'`igmm'`cugmm'" == "" {
			loc igmm			"igmm"
		}

		loc cmd				`"xtdpdgmm `depvarlags' `indepvars' `if' `in' , `model' `exoiv' `preiv' `endoiv' `nl' `collapse' `curtail' `teffects' `nolevel' `onestep' `twostep' `igmm' `cugmm' `options'"'
		loc cmd				: list retok cmd
		if "`cmdline'" == "" {
			di as inp _n `"  `cmd'"'
		}
		`cmd'
	}
end
