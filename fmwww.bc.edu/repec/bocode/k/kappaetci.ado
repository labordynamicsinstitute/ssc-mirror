*! version 1.1.0 06may2017 daniel klein
program kappaetci
	version 11.2
	
	syntax anything(id = "integer") 	///
	[ , 								///
		Tab 							///
		CATegories(numlist missingokay) ///
		FREquency 				/// ignored
		* 								///
	]
	
	kappaetci_opts_not_allowed , `options'
	
	preserve
	
	tempname rresults matrow matcol
	
	nobreak {
		_return hold `rresults'
		capture noisily break {
			quietly tabi `anything' , replace matrow(`matrow') matcol(`matcol')
			if ("`categories'" != "") {
				kappaetci_replace `matrow' `matcol' `categories'
				local options `options' categories(`categories')
			}
			if ("`tab'" != "") {
				tabulate row col [fweight = pop] , cell nokey missing
			}
			kappaetc row col [fweight = pop] , `options'
		}
		if (_rc) {
			local rc = _rc
			_return restore `rresults'
			exit `rc'
		}
	}
	
	capture _return drop `rresults'
	
	restore
end

program kappaetci_opts_not_allowed
	version 11.2
	
	syntax [ , FREquency CATegories(passthru) * ]
	local 0 , options `frequency' `categories'
	syntax , OPTIONS
end

program kappaetci_replace
	version 11.2
	
	gettoken matrow 0 : 0
	gettoken matcol 0 : 0
	
	mata : st_local("maxcat", ///
		strofreal(max(st_matrix("`matrow'")\ vec(st_matrix("`matcol'")))))
	
	local ncat : word count `0'
	if (`ncat' != `maxcat') {
		local rc = 122 + (`ncat' > `maxcat')
		display as err "option categories() invalid -- " _continue
		error `rc'
	}
	
	rename row row_o
	rename col col_o
	
	tokenize `0'
	
	quietly {
		generate double row = row_o
		generate double col = col_o
		forvalues j = 1/`ncat' {
			replace row = ``j'' if (row_o == `j')
			replace col = ``j'' if (col_o == `j')
		}
		drop row_o 
		drop col_o
	}
end
exit

1.1.0	06may2017	bug fix get maximum (number of) categories from data
					pass option categories() along to kappetc
					repeated options no longer allowed
1.0.0	17jan2017	first release
