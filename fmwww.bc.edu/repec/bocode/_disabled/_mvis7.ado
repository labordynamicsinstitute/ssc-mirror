*! version 1.0.0 PR 30sep2004.
program define _mvis7, rclass
version 7
syntax varlist(min=2 numeric) [if] [in] [aw fw pw iw] using/, /*
*/ [ BOot(varlist) CC(varlist) CMd(string) CYcles(int 10) noCONStant DRaw(varlist) /*
*/ First(int 0) Genmiss(string) Id(string) ON(varlist) REcycle(varlist) TRace ]

* Remove duplicate var names (_rmdups is essentially _mi_unique.ado)
_rmdups "`varlist'"
local varlist `r(unique)'

local nvar: word count `varlist'
if `first'<0 | `first'>`nvar' {
	di in red "invalid `first'"
	exit 198
}
if "`id'"!="" {
	confirm new var `id'
}
else local id _i
if "`trace'"!="" {
	local noi noisily
}
preserve
tempvar touse order
quietly {
	marksample touse, novarlist
	if "`cc'`on'"!="" {
		markout `touse' `cc' `on'
	}

* Record sort order
	gen long `order'=_n
	lab var `order' "obs. number"

* For standard operation (no `on' list), disregard any completely missing rows in varlist, among marked obs
	if "`on'"=="" {
		tempvar rmis
		egen int `rmis'=rmiss(`varlist') if `touse'==1
		count if `rmis'==0
		replace `touse'=0 if `rmis'==`nvar'
		drop `rmis'
	}
* Deal with weights
	frac_wgt `"`exp'"' `touse' `"`weight'"'
	local wgt `r(wgt)'

* Sort out cmds (not checking if each cmd is valid - any garbage may be entered)
	if "`cmd'"!="" {
		* local cmds "regress logistic logit ologit mlogit"
		frac_dis "`cmd'" cmd "`varlist'"
		forvalues i=1/`nvar' {
			if "${S_`i'}"!="" {
				local cmd`i' ${S_`i'}
			}
		}
	}

* Default for all uvis operations is nodraw, equivalent to match
	if "`draw'"!="" {
		tokenize `draw'
		while "`1'"!="" {
			ChkIn `1' "`varlist'"
			if `s(k)'>0 {
				local draw`s(k)' draw
			}
			mac shift
		}
	}

	if "`boot'"!="" {
		tokenize `boot'
		while "`1'"!="" {
			ChkIn `1' "`varlist'"
			if `s(k)'>0 {
				local boot`s(k)' boot
			}
			mac shift
		}
	}

* Copy relevant members of varlist to new vars which will contain imputations
	count if `touse'
	local n=r(N)
	if `first'==0 {
		local first `nvar'
	}
	local ivars1	/* list of first `first' vars */
	local ivars2	/* list of remaining vars */
	local to_imp 0	/* actual number of vars with missing values imputed */
	forvalues i=1/`nvar' {
		local xvar: word `i' of `varlist'
		if "`cmd`i''"=="" {
/*
	Assign default cmd for vars not so far accounted for.
	Use logit if 2 distinct values, mlogit if 3-5, otherwise regress.
*/
			quietly inspect `xvar' if `touse'
			local nuniq=r(N_unique)
			if `nuniq'==1 {
				noi di in red "only 1 distinct value of `xvar' found"
				exit 2000
			}
			if `nuniq'==2 {
				count if `xvar'==0 & `touse'==1
				if r(N)==0 {
					noi di in red "variable `xvar' unsuitable for imputation,"
					noi di in red "binary variables must include at least one 0 and one non-missing value"
					exit 198
				}
				local cmd`i' logit
			}
			else if `nuniq'<=5 {
				local cmd`i' mlogit
			}
			else local cmd`i' regress
		}
		count if `xvar'==. & `touse'==1
		local nimp`i'=r(N)
		if `nimp`i''>0 {
			local to_imp=`to_imp'+1
			if "`recycle'"=="" {
				* Create temporary variable with imputed variable
				tempvar ivar`i'
				if "`on'"=="" {
					* Initially fill missing obs cyclically with nonmissing obs
					sampmis `ivar`i''=`xvar'
					replace `ivar`i''=. if `touse'==0
				}
				else gen `ivar`i''=`xvar' if `touse'
				lab var `ivar`i'' "`xvar' imput.`suffix' (`nimp`i'' values)"
			}
			else /* recycle */ local ivar`i': word `to_imp' of `recycle'
			if `to_imp'==1 & "`fivar'"=="" {
				* record first imputed var for counting purposes later
				local fivar `ivar`i''
			}
			if "`genmiss'"!="" {
				tempvar mvar`i'
				gen byte `mvar`i''=missing(`xvar') if `touse'==1
				lab var `mvar`i'' "1 if `xvar' missing, 0 otherwise"
			}
		}
		else local ivar`i' `xvar'
		if `i'<=`first' {
			local ivars1 `ivars1' `ivar`i''
		}
		else local ivars2 `ivars2' `ivar`i''
	}
	local ivars `ivars1' `ivars2'
	if `to_imp'==0 {
		noi di as err _n "All relevant cases are complete, no imputation required."
		return scalar N=`n'
		return scalar imputed=0
		exit 2000
	}

	if `to_imp'==1 | "`on'"!="" {
		local cycles 1
	}
* Impute sequentially `cycles' times by regression switching (van Buuren et al)
	tempvar imputed
	forvalues j=1/`cycles' {
		if "`trace'"!="" {
			noi di as text _n "Cycle `j'"
		}
		forvalues i=1/`nvar' {
			if `nimp`i''>0 {
				* Each var is reimputed based on imputed
				* values of other vars
				local y: word `i' of `varlist'
				if "`on'"=="" {
					strdel `ivar`i'' `ivars'
					local vars $S_1
				}
				else local vars `on'
				* uvis is derived from uvisamp4.ado
				uvis7 `cmd`i'' `y' `vars' `wgt' if `touse', /*
				 */ gen(`imputed') `boot`i'' `draw`i'' `constant'
				if "`trace'"!="" {
					sum `imputed' if missing(`y') & `touse'==1
					noi di as text %11s "`y'" %7.0g r(mean) _cont
					foreach v of var `ivars' {
						if "`v'"=="`ivar`i''" {
							noi di as result "       ." _cont
						}
						else noi di as result _skip(1) %7.0g _b[`v'] _cont
					}
					noi di
				}
				replace `ivar`i''=`imputed'
				drop `imputed'
			}
		}
		if `to_imp'==1 {
			noi di as text "[Only 1 variable to be imputed, therefore no cycling needed.]" _cont
		}
		if `to_imp'>1 & "`trace'"=="" {
			noi di as text "." _cont
		}
	}
}
forvalues i=1/`nvar' {
	return scalar ni`i'=`nimp`i''
}
* Save to file with cases in original order
quietly {
	local impvl	/* list of newvars containing imputations */
	sort `order'
	forvalues i=1/`nvar' {
		if `nimp`i''>0 {
			local x: word `i' of `varlist'
			replace `x'=`ivar`i'' if `touse'
			local impvl `impvl' `x'
			local lab: var label `ivar`i''
			lab var `x' "`lab'"
			drop `ivar`i''
			if "`genmiss'"!="" {
				cap drop `genmiss'`x'
				rename `mvar`i'' `genmiss'`x'
			}
		}
	}
	drop `touse'
	* Save list of imputed variables with imputations to char _dta[mi_ivar]
	char _dta[mi_ivar] `impvl'
	char _dta[mi_id] `id'
	rename `order' `id'
	save `"`using'"', replace
	noi di as text _n "File " as result `"`using'"' as text " created."
}
return local impvl `impvl'
return scalar imputed=`to_imp'
end

*! v 1.0.0 PR 01Jun2001.
program define sampmis
version 7
* Duplicates nonmissing obs of `exp' into missing ones, in random order.
* This routine always reproduces the same sort order among the missings.
* Note technique to avoid Stata creating arbitrary sort order for missing
* observations of `exp'; affects entire reproducibility of mvi sampling.
syntax newvarname =/exp
quietly {
	tempvar u
	* Sort non-missing data at random, sort missing data systematically
	gen double `u'=cond(missing(`exp'), _n, uniform())
	sort `u'
	count if !missing(`exp')
	local nonmis=r(N)
	drop `u'
	local type: type `exp'
	gen `type' `varlist'=`exp'
	local blocks=int((_N-1)/`nonmis')
	forvalues i=1/`blocks' {
		local j=`nonmis'*`i'
		local j1=`j'+1
		local j2=min(`j'+`nonmis',_N)
		replace `varlist'=`exp'[_n-`j'] in `j1'/`j2'
	}
}
end

*! v 1.2.0 PR 30Dec98.
program define strdel
version 5.0
if "`*'"=="" {
	error 198
}
local target "`1'"
mac shift
local rest "`*'"
local t: word count `target'
local i 1
while `i'<=`t' {
	local w: word `i' of `target'
	local lw=length("`w'")
	local wild=(substr("`w'",`lw',.)=="*")
	if `wild' {
		local w=substr("`w'",1,`lw'-1)
	}
	local new
	parse "`rest'", parse(" ")
	while "`1'"!="" {
		if `wild' {
			if substr("`1'",1,`lw'-1)!="`w'" {
				local new `new' `1
			}
		}
		else {
			if "`1'"!="`w'" {
				local new `new' `1'
			}
		}
		mac shift
	}
	local rest `new'
	local i=`i'+1
}
global S_1 `rest'
end

program define _rmdups, rclass
* based on Carlin's _mi_unique.ado
version 7
local res abc
local keep
tokenize `0'
local 0
while "`1'"!=""{
	local 0 `0' `1'
	mac shift
}
while "`res'"~="" {
	local res
	gettoken first rest: 0
	tokenize `rest'
	while "`1'"!="" {
		cap assert "`first'"=="`1'"
		if _rc {
			local res `res' `1'
		}
		mac shift
	}
	local keep `keep' `first'
	local 0 `res'
}
local N: word count `keep'
return local unique `keep'
return scalar N=`N'
end


program define ChkIn, sclass
version 7
* Returns s(k) = index # of target variable v in varlist, or 0 if not found.
args v varlist
sret clear
sret local k 0
tokenize `varlist'
local j 1
while "``j''"!="" {
	if "`v'"=="``j''" {
		sret local k `j'
		continue, break
	}
	local j=`j'+1
}
if `s(k)'==0 {
   	di as err "`v' is not a valid covariate"
   	exit 198
}
end
