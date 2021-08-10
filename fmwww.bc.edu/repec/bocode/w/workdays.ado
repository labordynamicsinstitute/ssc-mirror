*! version 1.0.2 February 11, 2021 @ 11:50:44
*! finds the number of workdays between date1 and date2
* v1.0.2: fixed embarrassing bug for spaces in file names
* v1.0.1: fixed bug for negative whole-week computations
*           and made computation less obscure-looking
*         updated to version 7 to get longer local macros
program define workdays
version 7.0
#delimit;
	syntax varlist (min=2 max=2 numeric)
	  [if] [in] [using/], GEN(str) [lazy] [holiday(str)];
#delimit cr
	if "`gen'"=="" {
		display in red "I need to generate a new variable!"
		exit 110
		}
	else {
		confirm new var `gen'
		}
	if `"`using'"'=="" {
		if "`holiday'"!="" {
			display in red "The holiday option can be used only if the using option is used!"
			exit 198
			}
		}
	else {
		if "`holiday'"=="" {
			display in red "The using option requires the holiday option!"
			exit 198
			}
      capture confirm file `"`using'"'
      if _rc {
         capture confirm file `"`using'.dta"'
         if _rc {
            display in red `"Neither file "`using'" nor "`using'.dta" found"'
            exit 601
            }
         }
		}

	tempvar useme
	marksample useme

	tokenize `varlist'
	local start  "`1'"
	local end "`2'"

	if `"`using'"'!=`""' {
		if "$S_HOLI"=="" | "`lazy'"=="" {
			// display in blue "about to get rid of sholi"
			global S_HOLI
			preserve
			use `"`using'"', clear
			quietly describe
			local cnt 1
			local max = _N
			while `cnt'<=`max' {
				local newdate = `holiday'[`cnt'] 
				global S_HOLI "$S_HOLI `newdate'"
				local cnt = `cnt' + 1
				}
			restore
			}
		}

	tempvar diff startsat startsun endsat endsun
   tempvar wkends
	quietly {
		gen byte `startsat' = dow(`start')==6
      gen byte `startsun' = dow(`start')==0
		gen byte `endsat' = dow(`end')==6
      gen byte `endsun' = dow(`end')==0
      // compute offsets with mondays as first day of the week
      local offset = mod(7-dow(0)+1,7)
      gen long `wkends' = floor((`end'-`offset')/7) - floor((`start'-`offset')/7)
		}
   
	gen long `diff' = `end'-`start'-2*`wkends' ///
     + cond(`end'>=`start',`startsat'+2*`startsun'-`endsat'-2*`endsun',`startsun'-`endsun') ///
	  if `useme'

	if "$S_HOLI"!="" {
		tokenize "$S_HOLI"
		local cnt 1
		while "``cnt''"!="" {
			if dow(``cnt'')!=0 & dow(``cnt'')!=6 {
				quietly replace `diff' = `diff' - ((``cnt''>`start') & (``cnt''<=`end')) if `useme'
				}
			local cnt = `cnt' + 1
			}
		}

	quietly compress `diff'
	label var `diff' "Work days between `start' and `end'"
	rename `diff' `gen'
					
end
