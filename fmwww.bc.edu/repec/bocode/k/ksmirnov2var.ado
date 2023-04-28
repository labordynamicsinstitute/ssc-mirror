* version 1 by Michael Makovi
* Take two variables, stack one variable on top, so that there is one variable with two groups.
* Then run ksmirnov on the two groups.
capture program drop ksmirnov2var
program define ksmirnov2var, nclass
	version 10.0
	syntax varlist(min=2 max=2 numeric) [if] [in], [Exact]
	
	tokenize `varlist'
	
	preserve
	
	stack `1' `2', into(variables) clear
	ksmirnov variables `if' `in', by(_stack) `exact'
	
	* As an alternative to stack, reshape
	/*
	keep `1' `2'
	capture rename `1' variable1
	capture rename `2' variable2
	generate obs_num = _n
	reshape long variable, i(obs_num) j(variable_number)
	rename variable variable_data 
	ksmirnov variable_data `if' `in', by(variable_number) `exact'
	*/
	
	restore
end

