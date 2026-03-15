program define margins_dynxteprobit, eclass
version 16.0
syntax [if] [in], [DYDX(varname) DIFF(string) AT(string) POST]

********************************************************************************
*** Error Codes ****************************************************************
********************************************************************************
// Error if xteprobit is not estimation command
if  e(title) != "Extended probit regression"{
	di as error "Previous Estimator was not Extended probit regression, this command is a postestimation command only for Extended probit regression."
	error 499
}
// Error if both options are stated simultaneously
if ("`dydx'" != "" & "`diff'" != "") {
        di as error "Specify only one of dydx() or diff()."
        exit 198
    }
	
********************************************************************************
*** Parsing Syntax *************************************************************
********************************************************************************
preserve
capture noisily{
quietly ssc install indeplist
tempvar xb0 xb1 te F1 F3 F4 te1 te0 F1_1 F2 F2_0 F2_1 F3_1 F1_0 F3_0 F4_0 F4_1 xb0_num1 xb0_num2 xb1_num1 xb1_num2
tempname ytrue ate xteprobit Omega V1 V2 V2prime V3 V F F_0 F_1 Sig betak xtrue

quietly estimates store `xteprobit'
local dep : word 1 of `e(depvar)'
local id `e(ivar)'
scalar var = [/]_b[var(`dep'[`id'])]
local var var
local ldep 1L.`dep'
quietly indeplist
local xlist `r(X`dep')'
local first : word 1 of `xlist'
if "`first'" != "`ldep'"{
	display as error "First independent variable in xteprobit command should be lagged dependent variable with factor notation (l.i.depvar)."
	exit 198
}
local xlist : list xlist - ldep

if strpos("`xlist'", ".") > 0 {
    display as error "Command cannot accomodate factor notation other than the lagged dependent variable."
	exit 198
}

********************************************************************************
*** AT OPTION ******************************************************************
********************************************************************************
local atspec `"`at'"'

while trim("`atspec'") != "" {

    gettoken var atspec : atspec, parse("=")
    gettoken equal atspec : atspec, parse("=")
    gettoken value atspec : atspec, parse(" ")

    local var   = trim("`var'")
    local value = trim("`value'")

    confirm variable `var'
	capture confirm number `value'
	if _rc {
		di as error "at(): `value' must be numeric"
		exit 198
	}
	replace `var' = `value'
	local atlist = "`atlist'"+ " `var' = `value'" 
}

********************************************************************************
*** Obtaining Variance Matrix **************************************************
********************************************************************************
quietly estimates restore `xteprobit'
quietly estat vce
	mat `V1' = r(V)["`dep':","`dep':"]
	mat `V2' = r(V)["`dep':","/:var(`dep'[`id'])"]
	mat `V2prime' = (`V2')'
	mat `V3' = r(V)["/:var(`dep'[`id'])","/:var(`dep'[`id'])"]
	mat `V' = [`V1',`V2'\ `V2prime',`V3']
	
********************************************************************************
*** DIFF OPTION ****************************************************************
********************************************************************************
if ("`diff'" != "") {
        gettoken diff rest : diff, parse("=")
		local diff = subinstr("`diff'", " ", "", .)
		local rest = subinstr("`rest'", "=", "", .)
        local rest = subinstr("`rest'", "(", "", .)
        local rest = subinstr("`rest'", ")", "", .)
        tokenize `"`rest'"'
        local num1 `1'
        local num2 `2'

        capture {
		confirm number `num1'
        confirm number `num2'
		}
		if _rc!=0{
			display as error "Must specify two numbers for diff option. Syntax for this option is , diff(var = (num1 num2))"
		}

	local isin : list diff in xlist
    if (`isin' == 0) {
            di as error "Variable `diff' not found in varlist."
            exit 198
        }
	
	// Calculate predict xb when l.y = 1 and l.y = 0
	quietly replace `dep' = 0
	quietly replace `diff' = `num1'
	quietly predict `xb0_num1', xb
	quietly replace `diff' = `num2'
	quietly predict `xb0_num2', xb
	quietly replace `dep' = 1
	quietly predict `xb1_num2', xb
	quietly replace `diff' = `num1'
	quietly predict `xb1_num1', xb
	
	// APE for `diff'
	// When l.y = 0
	quietly gen `te0' = normal(`xb0_num2'/(1+`var')^.5) - normal(`xb0_num1'/(1+`var')^.5)
	quietly sum `te0' `if' `in'
	mat `ate' =  r(mean)
	quietly gen `te1' = normal(`xb1_num2'/(1+`var')^.5) - normal(`xb1_num1'/(1+`var')^.5)
	quietly sum `te1' `if' `in'
	mat `ate' = [`ate' , r(mean)]
	local N `r(N)'
	quietly snapshot save
	local snapshot = `r(snapshot)'
		collapse (mean) `te0' `te1' `if' `in', by(`id')
		quietly corr `te0' `te1', cov
		mat `Omega' = r(C)
	quietly snapshot restore `snapshot'
	// Calculate variance
	quietly gen `F1_0' = 0
	quietly sum `F1_0' `if' `in'
	mat `F_0' = r(mean)
	quietly gen `F1_1' = normalden(`xb1_num2'/(1+`var')^.5)*(1/(1+`var')^.5) - normalden(`xb1_num1'/(1+`var')^.5)*(1/(1+`var')^.5)
	quietly sum `F1_1' `if' `in'
	mat `F_1' = r(mean)
	foreach x of local xlist{
		if "`x'" == "`diff'"{
		quietly gen `F2_0' = normalden(`xb0_num2'/(1+`var')^.5)*(`num2'/(1+`var')^.5) - normalden(`xb0_num1'/(1+`var')^.5)*(`num1'/(1+`var')^.5)
		quietly gen `F2_1' = normalden(`xb1_num2'/(1+`var')^.5)*(`num2'/(1+`var')^.5) - normalden(`xb1_num1'/(1+`var')^.5)*(`num1'/(1+`var')^.5)
		} 
		if "`x'" != "`diff'"{
		quietly gen `F2_0' = normalden(`xb0_num2'/(1+`var')^.5)*(`x'/(1+`var')^.5) - normalden(`xb0_num1'/(1+`var')^.5)*(`x'/(1+`var')^.5)
		quietly gen `F2_1' = normalden(`xb1_num2'/(1+`var')^.5)*(`x'/(1+`var')^.5) - normalden(`xb1_num1'/(1+`var')^.5)*(`x'/(1+`var')^.5)
		}
		quietly sum `F2_0' `if' `in'
		mat `F_0' = [`F_0' \ r(mean)]	
		quietly sum `F2_1' `if' `in'
		mat `F_1' = [`F_1' \ r(mean)]
		drop `F2_0' `F2_1'
	}
	quietly gen `F3_0' = normalden(`xb0_num2'/(1+`var')^.5)*(1/(1+`var')^.5) - normalden(`xb0_num1'/(1+`var')^.5)*(1/(1+`var')^.5)
	quietly sum `F3_0' `if' `in'
	mat `F_0' = [`F_0' \ r(mean)]
	quietly gen `F3_1' = normalden(`xb1_num2'/(1+`var')^.5)*(1/(1+`var')^.5) - normalden(`xb1_num1'/(1+`var')^.5)*(1/(1+`var')^.5)
	quietly sum `F3_1' `if' `in'
	mat `F_1' = [`F_1' \ r(mean)]
	quietly gen `F4_0' =  -(1/2)*(normalden( `xb0_num2' /( 1+ `var' )^.5)*(`xb0_num2'/(1+`var')^1.5) - normalden(`xb0_num1'/(1+`var')^.5)*(`xb0_num1'/(1+`var')^1.5) )
	quietly sum `F4_0' `if' `in'
	mat `F_0' = [`F_0' \ r(mean)]
	quietly gen `F4_1' =  -(1/2)*(normalden( `xb1_num2' /( 1+ `var' )^.5)*(`xb1_num2'/(1+`var')^1.5) - normalden(`xb1_num1'/(1+`var')^.5)*(`xb1_num1'/(1+`var')^1.5) )
	quietly sum `F4_1' `if' `in'
	mat `F_1' = [`F_1' \ r(mean)]
	mat `F' = [`F_0' , `F_1']
	mat `Sig' = `Omega' + `F''*(`N'*`V')*`F'
	
	matrix b = `ate'
	mat coleq b = "`diff'" "`diff'"
	mat colnames b = "1._at" "2._at"
	matrix V = `Sig'/`N'
	mat coleq V = "`diff'" "`diff'"
	mat colnames V = "1._at" "2._at"
	mat roweq V = "`diff'" "`diff'"
	mat rownames V = "1._at" "2._at"
	ereturn post b V 
	ereturn scalar N = `N'
	ereturn local cmd "margins_dynxteprobit"
	ereturn local estimator "xteprobit"
	ereturn local vcetype "Delta-method"
	ereturn local title "Average marginal effects"
	
	di as text _newline(1) "Average marginal effects" ///
	  as text "		            Number of obs ="  as result %11.0gc `N'
	di as text " "
	di as text "Estimator:	{bf:xteprobit}"
	di as text "dydx wrt:	{bf:`diff'} (from `num1' to `num2')"
	di as text "1.at: `ldep' = 0`atlist'"
	di as text "2.at: `ldep' = 1`atlist'"
	di as text " "
	ereturn display
	di as text "Note: dy/dx for difference option is the discrete change from the first number listed to second number listed."
		
    }

else{
quietly replace `dep' = 0
quietly predict `xb0', xb
quietly replace `dep' = 1
quietly predict `xb1', xb

********************************************************************************
*** DYDX OPTION ****************************************************************
********************************************************************************
if ("`dydx'" != "") {
	local isin : list dydx in xlist
    if (`isin' == 0) {
            di as error "variable `dydx' not found in varlist"
            exit 198
        }
	// APE for `dydx'
	scalar `betak' = _b[`dep':`dydx']  
	quietly gen `te0' = normalden(`xb0'/(1+`var')^.5)*`betak'/(1+`var')^.5
	quietly sum `te0' `if' `in' 
	mat `ate' =  r(mean)
	local N `r(N)'
	ereturn scalar N = `N'
	quietly gen `te1' = normalden(`xb1'/(1+`var')^.5)*`betak'/(1+`var')^.5
	quietly sum `te1' `if' `in' 
	mat `ate' = [`ate' , r(mean)]
	quietly snapshot save
	local snapshot = `r(snapshot)'
		collapse (mean) `te0' `te1' `if' `in' , by(`id')
		quietly corr `te0' `te1', cov
		mat `Omega' = r(C)
	quietly snapshot restore `snapshot'
	// Calculate variance
	quietly gen `F1_0' = 0
	quietly sum `F1_0' `if' `in' 
	mat `F_0' = r(mean)
	quietly gen `F1_1' = normalden(`xb1'/(1+`var')^.5)*(-(`xb1'/(1+`var')^.5)*(`betak'/(1+`var')^.5))*(1/(1+`var')^.5)
	quietly sum `F1_1' `if' `in' 
	mat `F_1' = r(mean)
	foreach x of local xlist{
		if "`x'" == "`dydx'"{
		quietly gen `F2_0' = normalden(`xb0' / (1+`var')^.5)*(1-(`xb0' / (1+`var')^.5)*(`betak'*`x'/(1+`var')^.5))*(1/(1+`var')^.5)
		quietly gen `F2_1' = normalden(`xb1' / (1+`var')^.5)*(1-(`xb1' / (1+`var')^.5)*(`betak'*`x'/(1+`var')^.5))*(1/(1+`var')^.5)
		} 
		if "`x'" != "`dydx'"{
		quietly gen `F2_0' = normalden(`xb0' / (1+`var')^.5)*(0-(`xb0' / (1+`var')^.5)*(`betak'*`x'/(1+`var')^.5))*(1/(1+`var')^.5)
		quietly gen `F2_1' = normalden(`xb1' / (1+`var')^.5)*(0-(`xb1' / (1+`var')^.5)*(`betak'*`x'/(1+`var')^.5))*(1/(1+`var')^.5)
		}
		quietly sum `F2_0' `if' `in' 
		mat `F_0' = [`F_0' \ r(mean)]	
		quietly sum `F2_1' `if' `in' 
		mat `F_1' = [`F_1' \ r(mean)]
		drop `F2_0' `F2_1'
	}
	quietly gen `F3_0' = normalden(`xb0' / (1+`var')^.5)*(0-(`xb0' / (1+`var')^.5)*(`betak'*1/(1+`var')^.5))*(1/(1+`var')^.5)
	quietly sum `F3_0' `if' `in' 
	mat `F_0' = [`F_0' \ r(mean)]
	quietly gen `F3_1' = normalden(`xb1' / (1+`var')^.5)*(0-(`xb1' / (1+`var')^.5)*(`betak'*1/(1+`var')^.5))*(1/(1+`var')^.5)
	quietly sum `F3_1' `if' `in' 
	mat `F_1' = [`F_1' \ r(mean)]
	quietly gen `F4_0' = normalden(`xb0' / (1+`var')^.5)*(1-(`xb0' / (1+`var')^.5)*(1/(1+`var')^.5))*(-`betak'/(2*(1+`var')^1.5))
	quietly sum `F4_0' `if' `in' 
	mat `F_0' = [`F_0' \ r(mean)]
	quietly gen `F4_1' = normalden(`xb1' / (1+`var')^.5)*(1-(`xb1' / (1+`var')^.5)*(1/(1+`var')^.5))*(-`betak'/(2*(1+`var')^1.5))
	quietly sum `F4_1' `if' `in' 
	mat `F_1' = [`F_1' \ r(mean)]
	mat `F' = [`F_0' , `F_1']
	mat `Sig' = `Omega' + `F''*(`N'*`V')*`F'
	matrix b = `ate'
	mat coleq b = "`dydx'" "`dydx'"
	mat colnames b = "1._at" "2._at"
	matrix V = `Sig'/`N'
	mat coleq V = "`dydx'" "`dydx'"
	mat colnames V = "1._at" "2._at"
	mat roweq V = "`dydx'" "`dydx'"
	mat rownames V = "1._at" "2._at"
	ereturn post b V 
	ereturn scalar N = `N'
	ereturn local cmd "margins_dynxteprobit"
	ereturn local estimator "xteprobit"
	ereturn local vcetype "Delta-method"
	ereturn local title "Average marginal effects"
	
	di as text _newline(1) "Average marginal effects" ///
	  as text "		            Number of obs ="  as result %11.0gc `N'
	di as text " "
	di as text "Estimator:	{bf:xteprobit}"
	di as text "dydx wrt:	{bf:`dydx'}"
	di as text "1.at: `ldep' = 0`atlist'"
	di as text "2.at: `ldep' = 1`atlist'"
	di as text " "
	ereturn display
	}
	
********************************************************************************
*** DEFAULT (lagged dependent ATE) *********************************************
********************************************************************************
if ("`dydx'" == "" & "`diff'" =="") {    
	// ATE for L.1.Dependent
	quietly gen `te' = normal(`xb1'/(1+`var')^.5) - normal(`xb0'/(1+`var')^.5)
	quietly sum `te' `if' `in' 
	mat `ate' =  r(mean)
	local N `r(N)'
	quietly snapshot save
	local snapshot = `r(snapshot)'
		collapse (mean) `te' `if' `in' , by(`id')
		quietly sum `te'
		mat `Omega' = r(Var)
	quietly snapshot restore `snapshot'
	// Calculate variance
	quietly gen `F1' = normalden(`xb1'/(1+`var')^.5)*(1/(1+`var')^.5)
	quietly sum `F1' `if' `in' 
	mat `F' = r(mean)
	di "`xlist'"
	foreach x of local xlist{
		quietly gen `F2' = (normalden(`xb1' / (1+`var')^.5) - normalden(`xb0'/(1+`var')^.5))*`x'/(1+`var')^.5
		quietly sum `F2' `if' `in' 
		mat `F' = [`F' \ r(mean)]
		drop `F2'
	}
	quietly gen `F3' = (normalden(`xb1' / (1+`var')^.5) - normalden(`xb0'/(1+`var')^.5))*1/(1+`var')^.5
	quietly sum `F3' `if' `in' 
	mat `F' = [`F' \ r(mean)]
	quietly gen `F4' =  -(1/2)*(normalden( `xb1' /( 1+ `var' )^.5)*(`xb1'/(1+`var')^1.5) - normalden(`xb0'/(1+`var')^.5)*(`xb0'/(1+`var')^1.5) )
	quietly sum `F4' `if' `in' 
	mat `F' = [`F' \ r(mean)]
	mat `Sig' = `Omega' + `F''*(`N'*`V')*`F'
    
	matrix b = `ate'
	mat colnames b = "`ldep'"
	matrix V = `Sig'/`N'
	mat colnames V = "`ldep'"
	mat rownames V = "`ldep'"
	ereturn post b V 
	ereturn scalar N = `N'
	ereturn local cmd "margins_dynxteprobit"
	ereturn local estimator "xteprobit"
	ereturn local vcetype "Delta-method"
	ereturn local title "Average marginal effects"
	
	di as text _newline(1) "Average marginal effects" ///
	  as text "		            Number of obs ="  as result %11.0gc `N'
	di as text " "
	di as text "Estimator:	{bf:xteprobit}"
	di as text "dydx wrt:	{bf:`ldep'}"
	if "`at'" != ""{
	di as text "at:`atlist'"
	}
	di as text " "
	ereturn display
	di as text "Note: dy/dx for lagged dependent variable is the discrete change from 0 to 1."
	}
}
if "`post'" == "" {
    quietly estimates restore `xteprobit'
}
}
local rc = _rc
restore
exit `rc'

end
