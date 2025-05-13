/*

This program is a version of cjive which uses Leverage and Mata for a faster runtime

syntax cjive y x (d = z), cluster(cluster)

where y is the dependent variable, 
x is a varlist of covariates, placed before and / or after the parenthesis
d is the treatment variable
z are the instruments
and cluster denotes which cluster each observation belongs to 

Created by Samuel McIntyre 
January 2024
spm42@byu.edu

*/

capture program drop cjive
program cjive, eclass 

	syntax anything(equalok) [if] [in], cluster(varname) [gen(string)]
	
	*Warn if gen is alrady specified
	cap confirm variable `gen'
	if _rc == 0{
		disp in red "Variable `gen' is already defined. Choose a new argument for gen()"
	}

	
	else{
		
	*Create dependent, exogenous, endogenous, instruments
    
	local pos1 = strpos("`anything'", "(")
	local pos2 = strpos("`anything'", "=")
	local pos3 = strpos("`anything'", ")")

	local exogenous1 = substr("`anything'", 1, `pos1' - 1)
	local endogenous = substr("`anything'", `pos1' + 1, `pos2' - `pos1' - 1)
	local instruments = substr("`anything'", `pos2' + 1, `pos3' - `pos2' - 1)
	local exogenous2 = substr("`anything'", `pos3' + 1, .)

	local pos4 = strpos("`exogenous1'", " ")
	local dependent = substr("`exogenous1'", 1, `pos4')
	local exogenous3 = substr("`exogenous1'", `pos4', .)
	local exogenous `exogenous3' `exogenous2'
	
	*Check that an appropriate number of gen names specified
	local num_gen : word count `gen'
	local num_leverage : word count `endogenous'
	if `num_gen' != `num_leverage' & "`gen'" != "" {
		di as err "Error: The number of gen variables must match the number of leverage variables."
		exit
	}

		
	*Partialling Out
	*Dependent
	tempvar yres y_hat
	qui reg `dependent' `exogenous'
	qui predict `yres', resid
	
	*Endogenous
	local d_reslist
	foreach var in `endogenous' {
		tempvar `var'_res
		qui reg `var' `exogenous'
		qui predict ``var'_res', resid
		local d_reslist `d_reslist' ``var'_res'
	}
	
	*Instruments
	* intialize instrument list
	local z_reslist
	foreach var of varlist `instruments' {
		tempvar `var'_res
		qui reg `var' `exogenous'
		qui predict ``var'_res', resid
		local z_reslist `z_reslist' ``var'_res'
	}
		
	*Index the clusters, get cluster sizes
	tempname clustervals Csize nrows
	tempvar ones
	
	preserve
	qui keep `cluster'
	qui gen `ones' = 1
	qui collapse (sum) `ones', by(`cluster')
	mata `clustervals' = st_data(., "`cluster'")
	mata `Csize' = st_data(., "`ones'")
	restore
	
	mata `nrows' = rows(`Csize')
	mata st_local("numclusters", strofreal(`nrows'))
	
	*Temporary Names
	tempname Z X ZTZ ZTZI Pi A B L
	
	*Create data matrices
	sort `cluster'
	mata: `Z' = st_data(., ("`z_reslist'") )
	mata: `X' = st_data(., ("`d_reslist'"))

	mata `ZTZ' = `Z'' * `Z'
	mata `ZTZI' = invsym(`ZTZ')
	
	
	*Count Endogenous Variables
	local d_count = 0
	foreach var in `d_reslist' {
		local d_count = `d_count' + 1
	}
	
	*Get the coefficients in Pi, one regression at a time
	local d_1 : word 1 of `d_reslist'
	qui reg `d_1' `z_reslist', nocons
	mata: `Pi' = st_matrix("e(b)")'	
	
	forvalues i = 2/`d_count' {
		tempname Pi_`i' d_`i'
		local d_`i' : word `i' of `d_reslist'
		qui reg `d_`i'' `z_reslist', nocons
		mata: `Pi_`i'' = st_matrix("e(b)")'
		mata: `Pi' = `Pi' , `Pi_`i''
	}
		
	
	*Create matrices used for Leverage Trick
	local index = 1
	forvalues i = 1/`numclusters'{
		tempname AZC`i' AXC`i' AHC`i'
		mata st_local("len", strofreal(`Csize'[`i']))

		mata `AZC`i'' = `Z'[`index' .. `index'+`len'-1, 1...]
		mata `AXC`i'' = `X'[`index'..`index'+`len'-1, 1...]	
		mata `AHC`i'' = `AZC`i'' * `ZTZI' * `AZC`i'''
		local index = `index' + `len'
	}
	
	*Leverage Trick
	forvalues i = 1/`numclusters'{
		tempname L`i'
		mata st_local("len", strofreal(`Csize'[`i']))
		
		mata `A' = `AZC`i'' * `Pi' - `AHC`i'' * `AXC`i''
		mata `B' = invsym(I(`len') - `AHC`i'')
		mata `L`i'' = `B'*`A'
	}

	*Create a matrix of all the Ls together
	mata `L' = `L1'
	forvalues i = 2/`numclusters'{
		mata `L' = `L' \ `L`i''
	}
	
	*Convert matrix L to data for use in IV regression
	local leverage ""
	forvalues i = 1/`d_count' {
		tempvar leverage_`i'
		qui gen `leverage_`i'' = .
		mata st_store(., "`leverage_`i''", `L'[., `i'])
		local leverage = "`leverage' `leverage_`i''"
	}
	
	
	*2SLS for the answer
	qui ivregress 2sls `yres' (`d_reslist' = `leverage'), noconstant vce(cluster `cluster')
	
	
	*Returned Values
	tempname b V N 
	mat `b' = e(b)
	mat `V' = e(V)
	scalar `N' = e(N)
	
	*Rename the columns
	local names
	foreach var in `endogenous' {
		local names `names' `var'
	}
	
	matrix rownames `b' = `dependent'
	matrix colnames `b' = `names'
	matrix colnames `V' = `names'
	matrix rownames `V' = `names'
	

	*Generate variables if gen
	if "`gen'" != "" {
		forvalues i = 1/`num_gen' {
			local gen_var : word `i' of `gen'
			local leverage_var : word `i' of `leverage'
			gen `gen_var' = `leverage_var'
		}
	}
	
	** ERETURN POST	
	ereturn post `b' `V', depname("`dependent'") obs(`e(N)') esample(`esample')

	ereturn scalar N = `N'
    ereturn local cmd "cjive"
	ereturn local title "CJIVE"
    ereturn local depvar "`dependent'"
	
	display "Cluster Jackknife Instrumental Variable Estimation"
	ereturn display

	}
end	

