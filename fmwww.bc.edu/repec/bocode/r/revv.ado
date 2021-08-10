*! version 1.1.2 21jul2011 Daniel Klein
* for history see end of file

prog revv
	vers 11.1
	
	syntax varlist(numeric) [if][in] ///
	[ ,PREfix(name) Generate(namelist) REPLACE ///
	Valid(numlist min = 2) ///
	DEFine(namelist) noLabel NUMlabel]
	
	/*check sample
	---------------*/
	marksample touse
	qui count if `touse'
	if r(N) == 0 err 2000

	/*check options
	----------------*/
	loc nvars : word count `varlist'
	if ("`replace'" != "") {
		foreach opt in prefix generate {
			if ("``opt''" != "") {
				di as err "replace not allowed with `opt'"
				e 198
			}
		}
	}
	else {
		if ("`generate'" != "") {
			loc dup : list dups generate
			if ("`dup'" != "") {
				di as err "generate : `dup' mentioned more than once"
				e 198
			}
			if (`nvars' != `: word count `generate'') {
				di as err "generate : " ///
				"number of names does not equal number of variables"
				e 198
			}
			foreach g of loc generate {
				conf new v `prefix'`g'
			}
		}
		else {
			if ("`prefix'" == "") local prefix rv_
			foreach v of local varlist {
				conf new var `prefix'`v'
			}
		}
	}

	if ("`define'" != "") {
		if ("`label'" != "") {
			di as err "define and nolabel not both allowed"
			exit 198
		}
		if (`nvars' != `: word count `define'') {
			di as err "define : too few or too many " ///
			"labelnames specified"
			exit 198
		}
	}
	
	if ("`valid'" != "") loc uservalid `valid'

	/*reverse values and value labels
	----------------------------------*/
	tempvar tmpv
	
	local cnt 0
	foreach var of local varlist {
		local ++cnt
		if ("`uservalid'" == "") {
			local vld 0
			qui levelsof `var' ,local(valid)
		}
		else local vld 1
		
		/*reverse values
		-----------------*/
		cap drop `tmpv'
		local nvld : list sizeof valid
		qui clonevar `tmpv' = `var' if `touse'
		cap as `var' == int(`var')
		if !(_rc) & !(`vld') {
			qui {
				su `var' if `touse' ,mean
				replace `tmpv' = (r(min) + r(max)) - `var' if `touse'
				replace `tmpv' = `var' if mi(`var')
			}
		}
		else {
			loc fp = cond("`: t `var''" == "double", "", "float")
			local stop = ceil(`nvld'/2)
			forval j = 1/`stop' {
				if (`j' == `nvld') continue ,br
				qui replace `tmpv' = `: word `j' of `valid'' ///
					if `var' == `fp'(`: word `nvld' of `valid'') /*
					*/ & `touse'
				qui replace `tmpv' = `: word `nvld' of `valid'' ///
					if `var' == `fp'(`: word `j' of `valid'') & `touse'
				local --nvld
			}
			qui replace `tmpv' = `var' if mi(`var')
		}
		
		/*generate new variable or replace old
		---------------------------------------*/
		if ("`generate'" == "") local newvar `prefix'`var'
		else local newvar `prefix'`: word `cnt' of `generate''
		
		if ("`replace'" != "") {
			nobreak {
				order `tmpv' ,b(`var')
				cap drop `var'
				rename `tmpv' `newvar'
			}
		}
		else qui clonevar `newvar' = `tmpv'
		
		/*reverse value label
		----------------------*/
		if ("`label'" != "") {
			lab val `newvar'
			continue
		}
		
		local lbl_nam : val lab `var'
		if ("`lbl_nam'" == "") continue
		if ("`numlabel'" != "") {
			qui numlabel `lbl_nam' ,r
			if ("`: di _rc'" != "0") local addnumlab 0
			else loc addnumlab 1
		}
		
		if ("`define'" != "") {
			local new_lbl_nam `: word `cnt' of `define''
		}
		else local new_lbl_nam `newvar'
		
		cap lab copy `lbl_nam' `new_lbl_nam' ,replace
		local nvld : list sizeof valid
		local stop = ceil(`nvld'/2)
		forval j = 1/`stop' {
			if (`j' == `nvld') continue ,br
			local lbl_txt1 : /*
			*/ lab `lbl_nam' `: word `j' of `valid'' ,strict
			local lbl_txt2 : /*
			*/ lab `lbl_nam' `: word `nvld' of `valid'' ,strict
			if ("`lbl_txt1'" != "" | "`lbl_txt2'" != "") {
				cap lab def `new_lbl_nam' ///
					`: word `j' of `valid'' "`lbl_txt2'" ,modify
				cap lab def `new_lbl_nam' ///
					`: word `nvld' of `valid'' "`lbl_txt1'" ,modify
			}	
			local --nvld
		}
		lab val `newvar' `new_lbl_nam'
		
		if ("`numlabel'" != "") {
			if (`addnumlab') {
				numlabel `lbl_nam' ,a
				numlabel `new_lbl_nam' ,a
			}
		}
	}
end
e


History

1.1.2	21jul2011	fix : no longer label values with no text
1.1.1	31may2011	no longer sort -valid- list
1.1.0		na		fix bug: double precision problem
1.0.9		na		add -replace-
					fix -valid- problem when varlist is used
					version no longer checked version is 11.1
					change internal version from 1.3.5 to 1.0.9
					other minor "make up"
			