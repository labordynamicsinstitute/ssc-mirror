*! version 1.0.1 PR 01oct2004.
program define mvis, rclass
version 7
preserve
syntax varlist(min=2 numeric) [if] [in] [aweight fweight pweight iweight] using/, /*
 */ m(int) [ REPLACE Seed(int 0) BOot DRaw * ]
* Must check if there are variables called boot and/or draw
if "`boot'"=="boot" {
	cap confirm var boot
	if _rc {
		local options `options' boot(`varlist')
	}
	else local options `options' boot(boot)
}
if "`draw'"=="draw" {
	cap confirm var draw
	if _rc {
		local options `options' draw(`varlist')
	}
	else local options `options' draw(draw)
}
if `m'<1 {
	di as err "number of imputations must be 1 or more"
	exit 198
}
if substr(`"`using'"',-4,.)!=".dta" {
	local using `using'.dta
}
if "`replace'"=="" {
	confirm new file `using'
}
if `seed'>0 {
	set seed `seed'
}

* Check and remove collinearities and duplicates
_rmcoll `varlist' `if' `in' `weight' `exp'
local varlist `r(varlist)'

tempname fn
di as text "imputing " _cont
forvalues i=1/`m' {
	di as text `i' ".."  _cont
	qui _mvis `varlist' `if' `in' `weight' `exp' using `fn'`i', `options'
}
mijoin `fn', clear m(`m')
save `using', `replace'
forvalues i=1/`m' {
	erase `fn'`i'.dta
}
end
