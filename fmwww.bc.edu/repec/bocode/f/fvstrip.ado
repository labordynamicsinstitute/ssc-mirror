*! fvstrip 1.01 ms 24march2015
// takes varlist with possible FVs and strips out b/n/o notation
// returns results in r(varlist)
// optionally also omits omittable FVs
// options:
//   expand calls fvexpand on full varlist
//   onebyone + expand calls fvexpand on elements of varlist
//   dropomit omits omitted variables from stripped r(varlist)
//   noisily displays the stripped r(varlist)
//
// _ms_parse_parts (notes):
// type = variable, error, factor, interaction, product
// k_names = #names if interaction or product, otherwise missing (=1)

program define fvstrip, rclass
	version 11
	syntax [anything] [if] , [ dropomit expand onebyone NOIsily ]
	if "`expand'"~="" {							//  force call to fvexpand
		if "`onebyone'"=="" {
			fvexpand `anything' `if'				//  single call to fvexpand
			local anything `r(varlist)'
		}
		else {
			foreach vn of local anything {
				fvexpand `vn' `if'				//  call fvexpand on items one-by-one
				local newlist	`newlist' `r(varlist)'
			}
			local anything	: list clean newlist
		}
	}
	foreach vn of local anything {						//  loop through varnames
		if "`dropomit'"~="" {						//  check & include only if
			_ms_parse_parts `vn'					//  not omitted (b. or o.)
			if ~`r(omit)' {
				local unstripped	`unstripped' `vn'	//  add to list only if not omitted
			}
		}
		else {								//  add varname to list even if
			local unstripped		`unstripped' `vn'	//  could be omitted (b. or o.)
		}
	}
// Now create list with b/n/o stripped out
	foreach vn of local unstripped {
		local svn ""							//  initialize
		_ms_parse_parts `vn'
		if "`r(type)'"=="variable" & "`r(op)'"=="" {			//  simplest case - no change
			local svn	`vn'
		}
		else if "`r(type)'"=="variable" & "`r(op)'"=="o" {		//  next simplest case - o.varname => varname
			local svn	`r(name)'
		}
		else if "`r(type)'"=="variable" {				//  has other operators so strip o but leave .
			local op	`r(op)'
			local op	: subinstr local op "o" "", all
			local svn	`op'.`r(name)'
		}
		else if "`r(type)'"=="factor" {					//  simple factor variable
			local op	`r(op)'
			local op	: subinstr local op "b" "", all
			local op	: subinstr local op "n" "", all
			local op	: subinstr local op "o" "", all
			local svn	`op'.`r(name)'				//  operator + . + varname
		}
		else if"`r(type)'"=="interaction" {				//  multiple variables
			forvalues i=1/`r(k_names)' {
				local op	`r(op`i')'
				local op	: subinstr local op "b" "", all
				local op	: subinstr local op "n" "", all
				local op	: subinstr local op "o" "", all
				local opv	`op'.`r(name`i')'		//  operator + . + varname
				if `i'==1 {
					local svn	`opv'
				}
				else {
					local svn	`svn'#`opv'
				}
			}
		}
		else if "`r(type)'"=="product" {
			di as err "fvstrip error - type=product for `vn'"
			exit 198
		}
		else if "`r(type)'"=="error" {
			di as err "fvstrip error - type=error for `vn'"
			exit 198
		}
		else {
			di as err "fvstrip error - unknown type for `vn'"
			exit 198
		}
		local stripped `stripped' `svn'
	}
	local stripped	: list retokenize stripped				//  clean any extra spaces
	
	if "`noisily'"~="" {							//  for debugging etc.
di as result "`stripped'"
	}

	return local varlist	`stripped'					//  return results in r(varnames)
end
