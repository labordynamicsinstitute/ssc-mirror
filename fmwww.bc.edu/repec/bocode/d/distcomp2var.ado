* version 1 by Michael Makovi
* Take two variables, stack one variable on top, so that there is one variable with two groups.
* Then run distcomp on the two groups.
capture program drop distcomp2var
program define distcomp2var, nclass
	version 11.0
	syntax varlist(min=2 max=2 numeric) [if] [in], [Alpha(real 0.10)] [Pvalue] [noplot]
	
	tokenize `varlist'
	
	preserve
	
	stack `1' `2', into(variables) clear
	distcomp variables `if' `in', by(_stack) alpha(`alpha') `pvalue' `noplot'
	
	* As an alternative to stack, reshape
	/*
	keep `1' `2'
	capture rename `1' variable1
	capture rename `2' variable2
	generate obs_num = _n
	reshape long variable, i(obs_num) j(variable_number)
	rename variable variable_data 
	distcomp variable_data `if' `in', by(variable_number) alpha(`alpha') `pvalue' `noplot'
	*/
	
	restore
end