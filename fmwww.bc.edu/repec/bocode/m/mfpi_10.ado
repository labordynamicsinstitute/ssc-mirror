*! version 1.0.2 PR 09jun2010
program define mfpi_10, rclass
version 10.0
gettoken cmd 0: 0, parse(" ,")
frac_chk `cmd' 
if `s(bad)' { 
	di as err "invalid or unrecognised command, `cmd'"
	exit 198
}
global MFpdist `s(dist)'

* Disentangle
GetVL `0'
local 0 `s(nought)'

/*
	Construct RHS for mfp. `rhs' is actual variables in use,
	`RHS' may include brackets for joint selection in mfp.
*/
local yvar $MFP_dv
local rhs $MFP_cur
local RHS
forvalues i=1/$MFP_n {
	local v ${MFP_`i'}
	if wordcount("`v'")>1 {
		local RHS `RHS' (`v')
	}
	else local RHS `RHS' `v'
}
/*
	Hidden option `adjbin' adjusts for treatment variable
	in adjustment model. Won't make much difference in randomised controlled
	trials, but may be important in observational data. To be discussed.

	Flexibility (flex()): 1 = least (S & R 2004, mfpint/mfpi.ado),
	2 = intermediate (original version of paper, mfpint100.ado), 
	3 = intermediate (allow different powers for main effect from interaction),
	4 = most (allow different powers in each group and for main effect).
*/
syntax [if] [in] [aw fw pw iw] [, ///
  SELect(string) ADDpowers(string) ADJust(passthru) ALpha(string) CEnter(passthru) ///
  ADJBin ADJVars(varlist) ALL CEnter(varlist) DEAD(varname) DETail DF(string) ///
  FLex(int 1) FP1(varlist) FP2(varlist) GENF(string) GENDiff(string) LINear(string) ///
  OUTcome(string) POWers(string) noSCAling noSEdiff SHOwmodel TReatment(varname) ///
  WITH(varname) ZERo(string) MFPopts(string) TOPcoded * ]

local regoptions `options'
local options

if "`adjust'" != "" {
	if "`center'" != "" {
		di as err "cannot have both adjust() and center() - they are synonyms"
		exit 198
	}
	local center `adjust'
}
else local adjust `center'
if "`with'" != "" {
	if "`treatment'" != "" {
		di as err "cannot have both treatment() and with() - they are synonyms"
		exit 198
	}
	local treatment `with'
}
else local with `treatment'
if "`linear'`fp1'`fp2'"=="" {
	di as err "you must specify interaction term(s)"
	exit 198
}
if "`cmd'" == "mlogit" & "`genf'`gendiff'" != "" {
	if `"`outcome'"' == "" {
		noi di as err "you must specify outcome() with genf() and/or gendiff()"
		exit 198
	}
}

local adjopt `adjust' `scaling'

* Store original lists of variables for interaction analysis with linear, FP1, FP2 models
local Linear `linear'
local Fp1 `fp1'
local Fp2 `fp2'
if "`powers'"=="" local powers -2 -1 -0.5 0 0.5 1 2 3
tokenize `powers' `addpowers'
local i 1
while "``i''"!="" {
	local p`i' ``i''
	local ++i
}
local np = `i'-1
if "`detail'"!="" {
	local noi noi
}
local powers powers(`powers' `addpowers')
local items 0	/* overall number of interactions considered */
if "`linear'"!="" {
	* Sort out bound partners
	local lsep "("
	local rsep ")"
	tokenize `linear', parse(" `lsep'`rsep'")
	local linear
	local lparen 0
	local cat
	local ncat 0
	while "`1'"!="" {
		if "`1'"=="`lsep'" {
			if `lparen' {
				noi di as err "unexpected `lsep' in linear()"
				exit 198
			}
			local lparen 1
		}
		else if "`1'"=="`rsep'" {
			if `lparen'==0 {
				noi di as err "unexpected `rsep' in linear()"
				exit 198
			}
			local ++ncat
			unab iz`ncat': `cat'
			local linear `linear' `iz`ncat''
			local ifp`ncat' 0	/* ifp=0 indicates linear term */
			local cat
			local lparen 0
		}
		else {
			if `lparen'==0 {
				local ++ncat
				unab iz`ncat': `1'
				local linear `linear' `iz`ncat''
				local ifp`ncat' 0
			}
			else local cat `cat' `1'
		}
		mac shift
	}
	if `lparen' {
		noi di as err "unexpected `rsep' in linear()"
		exit 198
	}
	local items `ncat'
}
if "`fp1'"!="" {
	local nfp1: word count `fp1'
	forvalues i = 1/`nfp1' {
		local ++items
		local iz`items': word `i' of `fp1'
		local ifp`items' 1
	}
}
if "`fp2'"!="" {
	local nfp2: word count `fp2'
	forvalues i = 1/`nfp2' {
		local ++items
		local iz`items': word `i' of `fp2'
		local ifp`items' 2
	}
}
/*
if `dist'==7 {	/* stcox, streg */
	local xvars `varlist'
	local yvar
}
else gettoken yvar xvars: varlist
*/
local xvars `RHS'
quietly {
	marksample touse
	markout `touse' `yvar' `rhs' `dead' `with' `linear' `fp1' `fp2' `adjvars'
	frac_wgt "`exp'" `touse' "`weight'"
	local wgt `r(wgt)'				/* [`weight'`exp'] */
	if "`dead'"!="" {
		local regoptions "`regoptions' dead(`dead')"
	}
	if "`all'"=="" local ifuse if `touse'
	else local restrict restrict(if `touse')
	* Exclude `with' variable from xvars, if it was there
	local Xvars `xvars'
	local Xvars: list Xvars - with
	tempvar ic f tmp

	egen byte `ic' = group(`with') if `touse'
	* create dummies for levels of `ic'
	sum `ic' if `touse'
	local ndum = r(max)-1
	if `ndum'<1 {
		di as err "`with' must have at least two levels"
		exit 198
	}
	replace `ic' = `ic'-1	/* lowest level labelled 0 */
	if "`topcoded'"!="" replace `ic' = `ndum'-`ic'
	local Ic
	forvalues i=1/`ndum' {
		cap drop _Ic`i'
		gen byte _Ic`i' = (`ic'==`i') if `touse'
lab var _Ic`i' "1 for level `i' of `with', 0 otherwise"
		local Ic `Ic' _Ic`i'
	}
	count if `touse'
	local nobs = r(N)
	local nxvar: word count `Xvars'
	if `nxvar'==0 {
		if "`select'"!="" & "`adjvars'"!="" {
			noi di as txt "[select() ignored]"
		}
	}
	else {
		if "`select'"=="" {
			local select 1
		}
		* Find adjustment model for main covariates
		if "`alpha'"!="" {
			local Alpha alpha(`alpha')
		}
		* Force dummies from interaction variable into adjustment model
		if "`adjbin'"!="" {
			local adjbin `Ic'
			local select `select', `adjbin':1
		}
		if "`adjvars'"!="" {
			if "`df'"!="" 	local Df df(`df',`adjvars':1)
			else 		local Df df(`adjvars':1)
			local select `select', `adjvars':1
		}
		else {
			if "`df'"!="" 	local Df df(`df')
		}
		local Select select(`select')
		`noi' mfp `cmd' `yvar' `Xvars' `adjvars' `adjbin' `wgt' if `touse', /*
		 */ `Alpha' `Df' `Select' `powers' `regoptions' `mfpopts' `adjust' `scaling'
		if "`showmodel'"!="" {
			noi di as txt _n "Variables in adjustment model" _n "{hline 29}"
			if "`adjvars'"!="" noi di as txt "[`adjvars': linear]"
			if "`adjbin'"!="" noi di as txt "[`adjbin': `with']"
		}
		* Store details of model for selected variables and powers
		local nxf 0
		forvalues i = 1/`nxvar' {
			local p `e(fp_k`i')'
			local x `e(fp_x`i')'
			if "`showmodel'"!="" noi di as txt %10s "`x':" _cont
			if "`p'"!="." {
				if "`showmodel'"!="" noi di as txt " power(s) = " as res "`p'"
				local ++nxf
				local x`nxf' `x'
				local fp`nxf' `p'
				if "`p'"!="1" {
					fracgen `x' `p' `ifuse', replace name(_Ix`nxf') `restrict' `adjust' `scaling'
					local n`nxf' `r(names)'
				}
				else local n`nxf' `x'
				local fxvars `fxvars' `n`nxf''
			}
			else {
				if "`showmodel'"!="" noi di as txt " not selected"
			}
		}
	}
	local d3 79
	local flexmess = cond(`flex'==1, "(least flexible)", cond(`flex'==4, "(most flexible)", "(intermediate)"))
	noi di as txt _n "Interactions with `with' (" as res `nobs' ///
	 as txt " observations). Flex-`flex' model `flexmess'"
	noi di as txt _n "{hline `d3'}"
	noi di as txt "Var         Main        Interact     idf   Chi2     P     Deviance tdf   AIC"
	noi di as txt "{hline `d3'}"
	forvalues ni = 1/`items' {
		local z `iz`ni''
		local nz: word count `z'	/* `z' could be a varlist */
		local degree `ifp`ni''		/* 0, 1 or 2; 0=linear */
/*
	Remove members of z from adjustment model varlist
	(note that adjlin vars, if any, are not counted in nxvar)
*/
		local xvars
		if `nxvar'>0 {
			forvalues i = 1/`nz' {
				local zi: word `i' of `z'
				forvalues j = 1/`nxvar' {
					if "`zi'"!="`x`j''" local xvars `xvars' `n`j''
				}
			}
		}
/*
	Deal with FP case
*/
		if `degree'>0 {
			* Determine shift in z, if needed to avoid zeros.
			fracgen `z' 0 if `touse', nogen `scaling'
			local shift = r(shift)
			local scale = r(scale)
			cap drop _Iz
			gen _Iz = (`z'+`shift')/`scale' `ifuse'
			if `shift' == 0 {
				if `scale' == 1 lab var _Iz "`z'"
				else lab var _Iz "`z'/`scale'"
			}
			else {
				if `scale' == 1 lab var _Iz "`z'+`shift'"
				else lab var _Iz "(`z'+`shift')/`scale'"
			}
/*
	Create continuous z at each level, with 0 for other levels
*/
			local unvi	// names of untransformed z at each level
			forvalues i = 0/`ndum' {
				cap drop _Iz`i'
				gen _Iz`i' = cond(`ic'==`i', (`z'+`shift')/`scale', 0) `ifuse'
				lab var _Iz`i' "_Iz for level `i' of `with', 0 otherwise"
				local unvi `unvi' _Iz`i'
			}
/*
	Main-effects model.
	Determine powers for flex 1, 3 and 4 using fracpoly.
	Flex 2 uses powers from interaction model.
*/
			if `flex'==1 | `flex'==3 | `flex'==4 {
				fracpoly `cmd' `yvar' _Iz `xvars' `adjvars' `Ic' `wgt' if `touse', ///
				 degree(`degree') `powers' `regoptions' `adjust' `scaling'
				local powmain `e(fp_pwrs)'
				fracgen _Iz `powmain' `ifuse', replace noscaling `restrict' `adjust'
				local v `r(names)'
				local drop `r(names)'
			}
/*
	Interaction models
*/
			if `flex'==1 {
/*
	Fit model with powers from main effect at all levels
*/
				local powint `powmain'
				local vi	// names of FP-transformed vars at each level
				forvalues i = 0/`ndum' {
					if "`powint'"!="1" {
						fracgen _Iz`i' `powint' `ifuse', zero replace noscaling `restrict' `adjust'
						local v`i' `r(names)'
					}
					else local v`i' _Iz`i'
					local vi `vi' `v`i''
				}
			}
			else if `flex'==2 | `flex'==3 {
/*
	Determine interaction powers for flex 2 and 3.
	Force powers to be the same for all levels (= `powint').
*/
				local devbest 1e30
				forvalues j = 1/`np' {
					if `degree'==2 {
						forvalues j2 = `j'/`np' {
							local iint
							forvalues i = 0/`ndum' {
								fracgen _Iz`i' `p`j'' `p`j2'' if `touse', replace zero `adjust' `scaling'
								local iint `iint' `r(names)'
							}
							`cmd' `yvar' `xvars' `adjvars' `Ic' `iint' `wgt' if `touse', `regoptions'
							local devint = -2*e(ll)
							if `devint'<`devbest' {
								local devbest `devint'
								local powint `p`j'' `p`j2''
							}
						}
					}
					else {
						local iint
						forvalues i = 0/`ndum' {
							fracgen _Iz`i' `p`j'', replace zero `adjust' `scaling'
							local iint `iint' `r(names)'
						}
						`cmd' `yvar' `xvars' `adjvars' `Ic' `iint' `wgt' if `touse', `regoptions'
						local devint = -2*e(ll)
						if `devint'<`devbest' {
							local devbest `devint'
							local powint `p`j''
						}
					}
				}
				local vi	// names of FP-transformed vars at each level
				forvalues i=0/`ndum' {
					if "`powint'"!="1" {
						fracgen _Iz`i' `powint' `ifuse', zero replace noscaling `restrict' `adjust'
						local v`i' `r(names)'
					}
					else local v`i' _Iz`i'
					local vi `vi' `v`i''
				}
			}
			else if `flex'==4 {
/*
	Use mfp to determine possibly different powers (`powint`i'') at each level.
*/
				if `degree'==2 local mfpdf df(1, `unvi':4)
				else local mfpdf df(1, `unvi':2)
				mfp `cmd' `yvar' `unvi' `xvars' `adjvars' `Ic' `wgt' if `touse', ///
				 `mfpdf' alpha(1) select(1) zero(`unvi') `regoptions' `adjust' `scaling'
				local vi	// names of FP-transformed vars at each level
				forvalues i = 0/`ndum' {
					local i1 = `i'+1
					local powint`i' `e(fp_k`i1')'	// estimated power(s) at each level
					if "`powint`i''"!="1" {
						fracgen _Iz`i' `powint`i'' `ifuse', zero replace noscaling `restrict' `adjust'
						local v`i' `r(names)'
					}
					else local v`i' _Iz`i'
					local vi `vi' `v`i''
				}
			}
/* 
	Fit flex 2 main-effects model, using powers from interaction (in `powint')
*/
			if `flex'==2 {
				local powmain `powint'
				fracgen _Iz `powmain' `ifuse', replace noscaling `restrict' `adjust'
				local v `r(names)'
				local drop `r(names)'
			}
		}
		else {
/*
	Deal with linear case (includes binary and categoric).
*/
			local powmain Linear
			local powint Linear
			local vi
			forvalues i = 0/`ndum' {
				local v`i'
				forvalues j = 1/`nz' {
					local zj: word `j' of `z'
					cap drop _Iz`i'_`j'
					gen _Iz`i'_`j' = cond(`ic'==`i', `zj', 0) `ifuse'
					local v`i' `v`i'' _Iz`i'_`j'
				}
				local vi `vi' `v`i''
			}
			* Main-effect covariate(s)
			local v `z'
		}	/* end of linear case */
/*
	Fit main-effects model and interaction model (in that order).
	`v'  is varlist for main effect of covariate(s) z,
	`vi' is varlist for interaction and main effect of covariate(s) z,
	`Ic' is varlist for main effect of treatment.
*/
		`noi' `cmd' `yvar' `xvars' `adjvars' `Ic' `v' `wgt' if `touse', `regoptions'
		local devmain = -2*e(ll)
		`noi' `cmd' `yvar' `xvars' `adjvars' `Ic' `vi' `wgt' if `touse', `regoptions'
		// Record variables in final model fitted for later display
		local describe `xvars' `adjvars' `Ic' `vi'
		local devint = -2*e(ll)
/*
	Test interaction
*/
		local k = e(k_eq_model)
		if (`k' == 0) | missing(`k') local k 1
		if `degree' > 0 {	// FP
			local dfmain = `degree' + `k' * (`ndum' + `degree')
			local dfint = `k' * `ndum' * `degree' + (`flex'==4) * `ndum' * `degree'
		}
		else {	// linear
			local dfmain = `k' * (`ndum' + `nz' )
			local dfint = `k' * `ndum' * `nz'
		}
		local dftot = `dfmain' + `dfint'
		local totaldf`degree' `dftot'
		local chi = `devmain' - `devint'
		local P = chiprob(`dfint', `chi')
/*
		Store details of test statistic for this variable.
		(Note: only details of last variable in list will be finally stored.)
*/
		local dfd`degree' `dfint'
		local chi2`degree' `chi'
		local P`degree' `P'
		local dev`degree' `devint'
		local aic`degree' = `devint'+2*`totaldf`degree''

		if length("`z'")>10 local showz = abbrev("`z'",10)
		else local showz `z'
		if `degree'==0 {
			local term1 "Linear"
			local term2 "Linear"
		}
		else {
			local term1 "FP`degree'(`powmain')"
			if `flex'==4 {
				local starmess "* possibly more than one set of FP powers, shown only for 1st dummy variable"
				local term2 "FP`degree'(`powint0')*"
			}
			else local term2 "FP`degree'(`powint')"
		}
		noi di as txt %-12s "`showz'" %-12s "`term1'" %-12s "`term2'" as res /*
		 */ %3s "`dfint'" %8.2f `chi' %9.4f `P' %10.3f `devint' %3.0f `totaldf`degree'' %10.3f `aic`degree''
		if "`genf'`gendiff'"!="" {
/*
	Note that correct prediction depends on fitting
	interaction model last in the lines above this.
	Create full-sample versions of FP of z for prediction.
*/
			if "`cmd'" == "mlogit" {
				// Check for valid outcome category
				local eqn `"`e(eqnames)'"'
				if !`: list outcome in eqn' {
					noi di as err "`outcome' is not a valid outcome category for `yvar'"
					exit 198
				}
			}
			forvalues i=0/`ndum' {
				if `degree'>0 {
					if `flex'==4 local pwr `powint`i''
					else local pwr `powint'
					if "`pwr'"!="1" {
						fracgen _Iz `pwr' `ifuse', zero replace noscaling name(_Iz`i') `restrict' `adjust'
					}
					else replace _Iz`i' = _Iz
				}
				else {
					forvalues j = 1/`nz' {
						local zj: word `j' of `z'
						replace _Iz`i'_`j'=`zj'
					}
				}
			}
			if "`genf'"!="" {
				forvalues i = 0/`ndum' {
					*noi confirm new var `genf'`ni'_`i'
					* Predict function at this level
					cap drop `f'
					xpredict `f' `ifuse', with(`v`i'')
/*
					* (no longer) Centre function on level 0
					if `i'==0 {
						sum `f' if `ic'==0 & `touse'==1
						local f0mean=r(mean)
					}
					else replace `f'=`f'+_b[_Ic`i']
*/
					if `i'>0 replace `f' = `f'+_b[_Ic`i']
					cap drop `genf'`ni'_`i'
					rename `f' `genf'`ni'_`i'
					if `degree'==0 lab var `genf'`ni'_`i' "f(`z'), level `i'" 
					else lab var `genf'`ni'_`i' "FP`degree'(`z'), level `i'"
				}
				/* Following code used to work OK, but SEs depend on
				   centering of covariates, which is not handled.
				   Don't want to get into that issue here!
				if "`se'"!="" {
					drop `f0' `f1'
					xpredict `f0' if `touse', with(`v0') stdp
					xpredict `f1' if `touse', with(`v1' _Ic) stdp
					cap drop `genf's0
					cap drop `genf's1
					rename `f0' `genf's0
					rename `f1' `genf's1
					lab var `genf's0 "SE(FP`degree'(`z')), group 0"
					lab var `genf's1 "SE(FP`degree'(`z')), group 1"
				}
				*/
			}
			if "`gendiff'"!="" {
				local Z = -invnormal((100-c(level))/200)
				* Predict f`i'-f0 via suitable contrast, L
				if `degree'==2 {
					local L 1 1 1 -1 -1
				}
				else if `degree'==1 {
					local L 1 1 -1
				}
				else {
					local L1
					local L2
					forvalues j = 1/`nz' {
						local L1 `L1' 1
						local L2 `L2' -1
					}
					local L 1 `L1' `L2'
				}
				forvalues i = 1/`ndum' {
					* noi confirm new var `gendiff'`ni'_`i'
					rename _Ic`i' `tmp'
					gen byte _Ic`i' = 1 `ifuse'
					cap drop `f'
					xpredict `f' `ifuse', with(_Ic`i' `v`i'' `v0') a(`L')
					if `degree'==0 lab var `f' "Diff in f(`z'), level `i'-level 0"
					else lab var `f' "Diff in FP`degree'(`z'), level `i'-level 0"
					cap drop `gendiff'`ni'_`i'
					rename `f' `gendiff'`ni'_`i'
					* SE(diff) is independent of covariate centering
					if "`sediff'"!="nosediff" {
						xpredict `f' `ifuse', with(_Ic`i' `v`i'' `v0') a(`L') stdp
						if `degree'==0 {
							lab var `f' "SE(Diff in f(`z'), level `i'-level 0)"
						}
						else lab var `f' "SE(Diff in FP`degree'(`z'), level `i'-level 0)"
						cap drop `gendiff'`ni'lb_`i'
						cap drop `gendiff'`ni'ub_`i'
						gen `gendiff'`ni'lb_`i' = `gendiff'`ni'_`i'-`Z'*`f'
						gen `gendiff'`ni'ub_`i' = `gendiff'`ni'_`i'+`Z'*`f'
						cap drop `gendiff'`ni's_`i'
						rename `f' `gendiff'`ni's_`i'
					}
					drop _Ic`i'
					rename `tmp' _Ic`i'
				}
			}
		}
	}
	* Tidy up
	if !missing("`drop'") drop `drop'
	cap drop I_Ix*
	cap drop I_Iz*
}
di as txt "{hline `d3'}" ///
 _n "idf = interaction degrees of freedom; tdf = total model degrees of freedom"
if "`starmess'" != "" di as txt "`starmess'"
if "`showmodel'" != "" & "`detail'" == "" {
	if "`yvar'" != "" local yvar4 " for `yvar'"
	local mess The last-fitted interaction model`yvar4' has the following covariates:
	di as txt _n "`mess'"
	describe `describe' _Iz
	`cmd'
}
return local if `if'
return local in `in'
return local varlist `varlist'
return local dead `dead'
return local treatment `treatment'
return local with `treatment'
/*
	Store details of interaction test(s) for final variable
	in each list (linear, fp1, fp2)
*/
if "`Linear'"!="" {
	return local Linear `Linear'
	return scalar chi2lin = `chi20'
	return scalar Plin = `P0'
	return scalar devlin = `dev0'
	return scalar aiclin = `aic0'
	return scalar totdflin = `totaldf0'
}
if "`Fp1'"!="" {
	return local Fp1 `Fp1'
	return scalar chi2fp1 = `chi21'
	return scalar Pfp1 = `P1'
	return scalar devfp1 = `dev1'
	return scalar aicfp1 = `aic1'
	return scalar totdffp1 = `totaldf1'
}
if "`Fp2'"!="" {
	return local Fp2 `Fp2'
	return scalar chi2fp2 = `chi22'
	return scalar Pfp2 = `P2'
	return scalar devfp2 = `dev2'
	return scalar aicfp2 = `aic2'
	return scalar totdffp2 = `totaldf2'
}
if "`gendiff'" != "" {
	char _dta[gendiff] `gendiff'
}
else char _dta[gendiff]
return local adjvars `adjvars'
return local z `z'
if "`z'"!="" {
	return local powmain `powmain'
	if `flex'==4 {
		forvalues i = 0/`ndum' {
			return local powint`i' `powint`i''
		}
	}
	else return local powint `powint'
}
return scalar nxvar = `nxvar'		
if `nxvar'>0 {
	* save FP adjustment model details
	forvalues i = 1/`nxf' {
		return local x`i' `x`i''
		return local power`i' `fp`i''
	}
	return scalar nxf = `nxf'
}
end

program define GetVL, sclass /* varlist [if|in|,|[weight]] */
macro drop MFP_*
if $MFpdist != 7 {
	if $MFpdist == 8 /* intreg */ gettoken tok1 0 : 0
	gettoken tok 0 : 0
	unabbrev `tok1' `tok'
	global MFP_dv "`s(varlist)'"
}

global MFP_cur		/* MFP_cur will contain full term list */
global MFP_n 0

gettoken tok : 0, parse(" ,[")
IfEndTrm "`tok'"
while `s(IsEndTrm)'==0 {
	gettoken tok 0 : 0, parse(" ,[")
	if substr("`tok'",1,1)=="(" {
		local list
		while substr("`tok'",-1,1)!=")" {
			if "`tok'"=="" {
				di in red "varlist invalid"
				exit 198
			}
			local list "`list' `tok'"
			gettoken tok 0 : 0, parse(" ,[")
		}
		local list "`list' `tok'"
		unabbrev `list'
		global MFP_n = $MFP_n + 1
		global MFP_$MFP_n "`s(varlist)'"
		global MFP_cur "$MFP_cur `s(varlist)'"
	}
	else {
		unabbrev `tok'
		local i 1
		local w : word 1 of `s(varlist)'
		while "`w'" != "" {
			global MFP_n = $MFP_n + 1
			global MFP_$MFP_n "`w'"
			local i = `i' + 1
			local w : word `i' of `s(varlist)'
		}
		global MFP_cur "$MFP_cur `s(varlist)'"
	}
	gettoken tok : 0, parse(" ,[")
	IfEndTrm "`tok'"
}
sret local nought `0'
end

program define IfEndTrm, sclass
sret local IsEndTrm 1
if "`1'"=="," | "`1'"=="in" | "`1'"=="if" | /*
*/ "`1'"=="" | "`1'"=="[" {
	exit
}
sret local IsEndTrm 0
end
exit

History
1.0.4  26oct2009  fix problems with determining primary equation name
1.0.3  04sep2009  Rename with() option to TReatment() and adjust() option to center()
