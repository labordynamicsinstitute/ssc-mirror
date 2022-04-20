*! version 1.1.0 , 18apr2022
*! Author: Mustafa Coban, Institute for Employment Research (Germany)
*! Website: mustafacoban.de
*! Support: mustafa.coban@iab.de


/****************************************************************/
/*    			 rbiprobit prediction							*/
/****************************************************************/


program define rbiprobit_p, eclass
	
	version 11
	syntax [anything] [if] [in] [, SCores *]
	
	if ("`e(cmd)'" != "rbiprobit"){
		error 301
		dis in red "rbiprobit was not the last command"
	}
	
	if `"`scores'"' != ""{
		ml score `0'	
		exit
	}
	
	local myopts P11 P10 P01 P00 PMARG1 PMARG2 XB1 XB2
	local myopts `myopts' PCOND1 PCOND2 PCOND10 PMARGCOND1 STDP1 STDP2
	local myopts `myopts' d1(string) d2(string)	
	
	_pred_se "`myopts'" `0'
	
	if (`s(done)') exit			
	local vtyp 	`s(typ)'			
	local varn 	`s(varn)'		
	local 0	`"`s(rest)'"'			
	

	*!	parse predict	
	syntax [if] [in] [, `myopts' noOFFset]
	
	local type `p11'`p10'`p01'`p00'`pmarg1'`pmarg2'`xb1'`xb2'
	local type `type' `pcond1'`pcond2'`pcond10'`pmargcond1'`stdp1'`stdp2'
	

	tokenize `e(depvar)'
	local dep1 `1'
	local dep2 `2'
	

	tsunab dep1: `dep1'
	tsunab dep2: `dep2'
				
	rmTS `dep1'
	confirm variable `r(rmTS)'
	local dep1n 	`r(rmTS)'
	
	rmTS `dep2'
	confirm variable `r(rmTS)'
	local dep2n 	`r(rmTS)'
	

	
	*!	linear index xb1
	if "`type'" == "xb1"{
		local pred "Linear Prediction of `dep1'"
		
		_predict `vtyp' `varn' `if' `in', eq(#1) `offset'
		label var `varn' "`pred'"
		
		exit
	}	
		
	*!	linear index xb2
	if "`type'" == "xb2"{
		local pred "Linear Prediction of `dep2'"
		
		_predict `vtyp' `varn' `if' `in', eq(#2) `offset'
		label var `varn' "`pred'"
		
		exit
	}	
	
	*!	standard error of linear index xb1
	if "`type'" == "stdp1"{
		local pred "S.E. of Linear Prediction of `dep1'"
		
		_predict `vtyp' `varn' `if' `in', stdp eq(#1) `offset'
		label var `varn' "`pred'"
		
		exit
	}	
		
	*!	standard error of linear index xb2
	if "`type'" == "stdp2"{
		local pred "S.E. of Linear Prediction of `dep2'"
		
		_predict `vtyp' `varn' `if' `in', stdp eq(#2) `offset'
		label var `varn' "`pred'"
		
		exit
	}	
	
	*!	correlation parameter	
	tempname arho rho
	
	if `:colnfreeparms e(b)' {
		scalar `arho' = _b[/atanrho]				//	Version 15.1 Solution
	}
	else {
		scalar `arho' = [atanrho]_b[_cons]		//	Anscheinend für frühere Versionen
	}	
	
	scalar `rho' = (exp(2*`arho')-1) / (1+exp(2*`arho'))
	
	
	*!	dr and d2dr
	if `"`d1'`d2'"' != ""{
		tempname dr d2dr
		scalar `dr' 	= 4*exp(2*`arho') / ( (1+exp(2*`arho'))*(1+exp(2*`arho')) )
		scalar `d2dr'	= 8*exp(2*`arho') * (1-exp(2*`arho')) ///
							/ ( (1+exp(2*`arho'))*(1+exp(2*`arho'))*(1+exp(2*`arho')) )
	}
	
	
	
	if !inlist("`type'","pmarg1","pmarg2","xb","zg","stdp1","stdp2"){
	
		*!	linear index for probabilities
		tempvar xb zg dep2orig
		
		qui{
			clonevar `dep2orig' = `dep2n'
		
			if inlist("`type'","","p11","p01","pcond1", "pcond2"){
				replace `dep2n' = 1
			}
			else if inlist("`type'","p10","p00","pcond10"){
				replace `dep2n' = 0
			}
			
			_predict double `xb' `if' `in', eq(#1) `offset'
			_predict double `zg' `if' `in', eq(#2) `offset'
			
			replace `dep2n' = `dep2orig'
		}
	
	
		*!	shortcuts
		tempname q1 q2
		
		if inlist("`type'","p11","pcond1","pcond2","pmargcond1"){
			scalar `q1' = 1
			scalar `q2' = 1
		}
		else if inlist("`type'","p10","pcond10"){
			scalar `q1' = 1
			scalar `q2' = -1
		}
		else if "`type'" == "p01"{
			scalar `q1' = -1
			scalar `q2' = 1
		}
		else if "`type'" == "p00"{
			scalar `q1' = -1
			scalar `q2' = -1	
		}
		
		tempname rhost etast
		
		scalar `rhost' = `q1'*`q2'*`rho'
		scalar `etast' = 1/sqrt(1-`rhost'*`rhost')
		
		local w1 	(`q1'*`xb')
		local w2 	(`q2'*`zg')
		local v1 	((`w2' - `rhost'*`w1')*`etast')
		local v2 	((`w1' - `rhost'*`w2')*`etast')
		local s1 	(normalden(`w1')*normal(`v1'))
		local s2 	(normalden(`w2')*normal(`v2'))
		local Phi2	(binormal(`w1',`w2',`rhost'))
		local phi2	(`etast'*normalden(`w1')*normalden(`v1'))
	}
	
	
	
	if `"`d1'`d2'"' == ""{
		
		*!	joint probabilities: p11,p10,p01,p00
		if inlist("`type'","","p11","p10","p01","p00"){
			if "`type'" == "" {
				local type "p11"
				di in gr "(option p11 assumed; Pr(`dep1'=1,`dep2'=1))"
			}	
		
			local val1 = substr("`type'",2,1)
			local val2 = substr("`type'",3,1)
			local pred "Pr(`dep1'=`val1',`dep2'=`val2')"
		
			gen `vtyp' `varn' = binormal(`w1',`w2',`rhost')	`if' `in'
			label var `varn' "`pred'"
			exit
		}
		
		
		*!	marginal probabilities
		if "`type'" == "pmarg1"{
			tempvar	xb
			
			_predict double `xb' `if' `in', eq(#1) `offset'
			
			gen `vtyp'	`varn' = normal(`xb')	`if' `in'
			label var	`varn' "Pr(`dep1'=1)"
			exit
		}	
		
		if "`type'" == "pmarg2"{
			tempvar	zg
			
			_predict double `zg' `if' `in', eq(#2) `offset'
			
			gen `vtyp'	`varn' = normal(`zg')	`if' `in'
			label var	`varn' "Pr(`dep2'=1)"
			exit
		}		
	
	
		*!	conditional probabilities
		if inlist("`type'","pcond1","pcond10"){
			if "`type'" == "pcond1"{
				local pred	"Pr(`dep1'=1|`dep2'=1)"
			}
			else{
				local pred	"Pr(`dep1'=1|`dep2'=0)"
			}
			
			gen `vtyp'	`varn' = binormal(`w1',`w2',`rhost') / normal(`w2')	`if' `in'
			label var	`varn' "`pred'"
			exit
		}	
	
		if "`type'" == "pcond2"{

			gen `vtyp'	`varn' = binormal(`w1',`w2',`rhost') / normal(`w1')	`if' `in'
			label var	`varn' "Pr(`dep2'=1|`dep1'=1)"			
			exit
		}	
	
		*!	conditional marginal probability for calculation of atec
		if "`type'" == "pmargcond1"{
				
			gen `vtyp'	`varn' = normal(`v2')	`if' `in'
			label var	`varn' "Pr(`dep1'=1|`dep2'=1): Conditional Marginal Probability"
			exit
		}			
	}
		

		
	*!	first and second derivatives
	if `"`d1'`d2'"' != ""{
	
		*!	joint probabilities: p11,p10,p01,p00
		if inlist("`type'","","p11","p10","p01","p00"){
			
			if "`type'" == "" {
				local type "p11"
			}	
		
			local val1 = substr("`type'",2,1)
			local val2 = substr("`type'",3,1)
			local pred "Pr(`dep1'=`val1',`dep2'=`val2')"
			
			
			*!	d1 and d2 (first derivatives)
			if inlist(`"`d1'"',"#1","#2","#3") & `"`d2'"' == ""{
				if `"`d1'"' == "#1"{
					gen `vtyp' 	`varn' = `s1' * `q1'		`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
				if `"`d1'"' == "#2"{
					gen `vtyp' 	`varn' = `s2' * `q2'		`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
				if `"`d1'"' == "#3"{
					gen `vtyp'	`varn' = `q1'*`q2'*`phi2'*`dr'		`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
			}
					
			*!	d1 and d2 (second derivatives)
			if inlist(`"`d1'"',"#1","#2","#3") & inlist(`"`d2'"',"#1","#2","#3"){
				if `"`d1'`d2'"' == "#1#1"{
					gen `vtyp' 	`varn' = -`w1'*`s1' - `phi2'*`rhost' 	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#1#2", "#2#1"){
					gen `vtyp'	`varn' = `q1'*`q2'*`phi2' 	`if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#1#3", "#3#1"){
					gen `vtyp' 	`varn' = -`v2'*`q2'*`etast'*`dr'*`phi2'		`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if `"`d1'`d2'"' == "#2#2"{
					gen `vtyp'	`varn' = -`w2'*`s2' - `phi2'*`rhost'	`if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#2#3", "#3#2"){
					gen `vtyp' 	`varn' = -`v1'*`q1'*`etast'*`dr'*`phi2'	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if `"`d1'`d2'"' == "#3#3"{
					// there are no predictors in this equation, so
					// -margins- will never need anything other than 0
					
					*gen `vtyp' `varn' = 0 	`if' `in'
					gen `vtyp'	`varn' = `q1'*`q2'*`phi2' * ///
										(`q1'*`q2'*`dr'*(`etast'*`etast'*`rhost' + `etast'*`etast'*`v1'*`v2') ///
										+ `d2dr') 	`if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
			}		
			exit		
		}
		
		
		*!	marginal probabilities
		if "`type'" == "pmarg1"{

			tempvar	xb
			_predict double `xb' `if' `in', eq(#1) `offset'
			local pred "Pr(`dep1'=1)"		

			
			*!	d1 and d2 (first derivatives)
			if inlist(`"`d1'"',"#1","#2","#3") & `"`d2'"' == ""{
				if `"`d1'"' == "#1"{
					gen `vtyp' 	`varn' = normalden(`xb')	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
				if `"`d1'"' == "#2"{
					gen `vtyp' 	`varn' = 0	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
				if `"`d1'"' == "#3"{
					gen `vtyp'	`varn' = 0	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
			}
			
			
			*!	d1 and d2 (second derivatives)
			if inlist(`"`d1'"',"#1","#2","#3") & inlist(`"`d2'"',"#1","#2","#3"){
				if `"`d1'`d2'"' == "#1#1"{
					gen `vtyp' 	`varn' =  -`xb'*normalden(`xb')		`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#1#2", "#2#1"){
					gen `vtyp'	`varn' = 0	`if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#1#3", "#3#1"){
					gen `vtyp' 	`varn' = 0	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if `"`d1'`d2'"' == "#2#2"{
					gen `vtyp'	`varn' = 0	`if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#2#3", "#3#2"){
					gen `vtyp' 	`varn' = 0	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if `"`d1'`d2'"' == "#3#3"{
					gen `vtyp'	`varn' = 0 `if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
			}
			exit
		}
		
		
		*!	marginal probabilities
		if "`type'" == "pmarg2"{

			tempvar	zg
			_predict double `zg' `if' `in', eq(#2) `offset'
			local pred "Pr(`dep2'=1)"
		
		
			*!	d1 and d2 (first derivatives)
			if inlist(`"`d1'"',"#1","#2","#3") & `"`d2'"' == ""{
				if `"`d1'"' == "#1"{
					gen `vtyp' 	`varn' = 0	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
				if `"`d1'"' == "#2"{
					gen `vtyp' 	`varn' = normalden(`zg')	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
				if `"`d1'"' == "#3"{
					gen `vtyp'	`varn' = 0		`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
			}
			
			
			*!	d1 and d2 (second derivatives)
			if inlist(`"`d1'"',"#1","#2","#3") & inlist(`"`d2'"',"#1","#2","#3"){
				if `"`d1'`d2'"' == "#1#1"{
					gen `vtyp' 	`varn' = 0	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#1#2", "#2#1"){
					gen `vtyp'	`varn' = 0	`if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#1#3", "#3#1"){
					gen `vtyp' 	`varn' = 0	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if `"`d1'`d2'"' == "#2#2"{
					gen `vtyp'	`varn' = -`zg'*normalden(`zg')	`if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#2#3", "#3#2"){
					gen `vtyp' 	`varn' = 0	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if `"`d1'`d2'"' == "#3#3"{
					gen `vtyp'	`varn' = 0 `if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
			}
			exit
		}
		

		*!	conditional probabilities
		if inlist("`type'","pcond1","`pcond10'"){

			if "`type'" == "pcond1"{
				local pred "Pr(`dep1'=1|`dep2'=1)"
			}
			else{
				local pred "Pr(`dep1'=1|`dep2'=0)"
			}
		
		
			*!	d1 and d2 (first derivatives)
			if inlist(`"`d1'"',"#1","#2","#3") & `"`d2'"' == ""{
				if `"`d1'"' == "#1"{
					gen `vtyp' 	`varn' = `q1'*(`s1'/normal(`w2'))		`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
				if `"`d1'"' == "#2"{
					gen `vtyp' 	`varn' = (`q2'/(normal(`w2')*normal(`w2'))) * ///
										(`s2'*normal(`w2') - `Phi2'*normalden(`w2'))	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
				if `"`d1'"' == "#3"{
					gen `vtyp'	`varn' = `q1'*`q2'*`dr'*(`phi2'/normal(`w2'))	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
			}
			
			
			*!	d1 and d2 (second derivatives)
			if inlist(`"`d1'"',"#1","#2","#3") & inlist(`"`d2'"',"#1","#2","#3"){
				if `"`d1'`d2'"' == "#1#1"{
					gen `vtyp' 	`varn' =  (1/normal(`w2')) * (-`w1'*`s1' - `rhost'*`phi2')	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#1#2", "#2#1"){
					gen `vtyp'	`varn' = (`q1'*`q2'/(normal(`w2')*normal(`w2'))) * ///
										(`phi2'*normal(`w2') - `s1'*normalden(`w2')) `if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#1#3", "#3#1"){
					gen `vtyp' 	`varn' = (-`q2'*`v2'/normal(`w2')) *`dr'*`etast'*`phi2'	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if `"`d1'`d2'"' == "#2#2"{
					gen `vtyp'	`varn' = (1/(normal(`w2')*normal(`w2')*normal(`w2')*normal(`w2'))) * ///
									( normal(`w2')*normal(`w2') * ( ///
										(-`w2'*`s2' - `rhost'*`phi2') * normal(`w2') + ///
										`s2'*normalden(`w2')) - ///
									2*normal(`w2')*normal(`w2')*normalden(`w2')*`s2' ///
									) - ///
									(1/(normal(`w2')*normal(`w2')*normal(`w2')*normal(`w2'))) * ///
									( normal(`w2')*normal(`w2') * ( ///
										`s2'*normalden(`w2') - `w2'*normalden(`w2')*`Phi2') - ///
									2*normalden(`w2')*normalden(`w2')*normal(`w2')*`Phi2' ///
									)	`if' `in'						 
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#2#3", "#3#2"){
					gen `vtyp' 	`varn' = (-`q1'/(normal(`w2')*normal(`w2'))) *`dr'*`phi2'* ///
										(`v1'*`etast'*normal(`w2') + normalden(`w2'))	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if `"`d1'`d2'"' == "#3#3"{
					gen `vtyp'	`varn' = (`q1'*`q2'/normal(`w2')) * (`d2dr'*`phi2' + ///
										`q1'*`q2'*`dr'*`dr'*`etast'*`etast'*`phi2' * ///
										(`rhost' + `v1'*`v2') )	`if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
			}
			exit
		}
		
		
		*!	conditional probabilities
		if "`type'" == "pcond2"{
			local pred "Pr(`dep2'=1|`dep1'=1)"
		
		
			*!	d1 and d2 (first derivatives)
			if inlist(`"`d1'"',"#1","#2","#3") & `"`d2'"' == ""{
				if `"`d1'"' == "#1"{
					gen `vtyp' 	`varn' = (`q1'/(normal(`w1')*normal(`w1'))) * ///
										(`s1'*normal(`w1') - `Phi2'*normalden(`w1'))	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
				if `"`d1'"' == "#2"{
					gen `vtyp' 	`varn' = `q2'*(`s2'/normal(`w1'))	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
				if `"`d1'"' == "#3"{
					gen `vtyp'	`varn' = `q1'*`q2'*`dr'*(`phi2'/normal(`w1'))	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
			}
			
			
			*!	d1 and d2 (second derivatives)
			if inlist(`"`d1'"',"#1","#2","#3") & inlist(`"`d2'"',"#1","#2","#3"){
				if `"`d1'`d2'"' == "#1#1"{
					gen `vtyp' 	`varn' =  (1/(normal(`w1')*normal(`w1')*normal(`w1')*normal(`w1'))) * ///
									( normal(`w1')*normal(`w1') * ( ///
										(-`w1'*`s1' - `rhost'*`phi2') * normal(`w1') + ///
										`s1'*normalden(`w1')) - ///
									2*normal(`w1')*normal(`w1')*normalden(`w1')*`s1' ///
									) - ///
									(1/(normal(`w1')*normal(`w1')*normal(`w1')*normal(`w1'))) * ///
									( normal(`w1')*normal(`w1') * ( ///
										`s1'*normalden(`w1') - `w1'*normalden(`w1')*`Phi2') - ///
									2*normalden(`w1')*normalden(`w1')*normal(`w1')*`Phi2' ///
									)	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#1#2", "#2#1"){
					gen `vtyp'	`varn' = (`q1'*`q2'/(normal(`w1')*normal(`w1'))) * ///
										(`phi2'*normal(`w1') - `s2'*normalden(`w1'))	`if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#1#3", "#3#1"){
					gen `vtyp' 	`varn' = (-`q2'/(normal(`w1')*normal(`w1'))) *`dr'*`phi2'* ///
										(`v2'*`etast'*normal(`w1') + normalden(`w1'))	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if `"`d1'`d2'"' == "#2#2"{
					gen `vtyp'	`varn' = (1/normal(`w1')) * (-`w2'*`s2' - `rhost'*`phi2')	`if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#2#3", "#3#2"){
					gen `vtyp' 	`varn' = (-`q1'*`v1'/normal(`w1')) *`dr'*`etast'*`phi2'	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if `"`d1'`d2'"' == "#3#3"{
					gen `vtyp'	`varn' = (`q1'*`q2'/normal(`w1')) * (`d2dr'*`phi2' + ///
										`q1'*`q2'*`dr'*`dr'*`etast'*`etast'*`phi2' * ///
										(`rhost' + `v1'*`v2') )	`if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
			}
			exit
		}
		
	
		*!	conditional marginal probabilities for computation of atec
		if "`type'" == "pmargcond1"{

			local pred "Pr(`dep1'=1|`dep2'=1): Conditional Marginal Probability"
		
		
			*!	d1 and d2 (first derivatives)
			if inlist(`"`d1'"',"#1","#2","#3") & `"`d2'"' == ""{
				if `"`d1'"' == "#1"{
					gen `vtyp' 	`varn' = `q1'*`etast'*normalden(`v2')	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
				if `"`d1'"' == "#2"{
					gen `vtyp' 	`varn' = -`q2'*`rhost'*`etast'*normalden(`v2')	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
				if `"`d1'"' == "#3"{
					gen `vtyp'	`varn' = -`q1'*`q2'*`dr'*`etast'*`w2'*normalden(`v2')	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1')"
				}
			}
			
			
			*!	d1 and d2 (second derivatives)
			if inlist(`"`d1'"',"#1","#2","#3") & inlist(`"`d2'"',"#1","#2","#3"){
				if `"`d1'`d2'"' == "#1#1"{
					gen `vtyp' 	`varn' = -`v2'*`etast'*`etast'*normalden(`v2') 	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#1#2", "#2#1"){
					gen `vtyp'	`varn' = `q1'*`q2'*`etast'*`etast'*`rhost'*`v2'*normalden(`v2')	`if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#1#3", "#3#1"){
					gen `vtyp' 	`varn' = `q2'*`etast'*`etast'*`dr'*normalden(`v2') * ///
										(`etast'*`rhost' + `v2'*`w2')	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if `"`d1'`d2'"' == "#2#2"{
					gen `vtyp'	`varn' = -`v2'*`rhost'*`rhost'*`etast'*`etast'*normalden(`v2')	`if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if inlist(`"`d1'`d2'"', "#2#3", "#3#2"){
					gen `vtyp' 	`varn' = -`q1'*`dr'*`etast'*normalden(`v2') * ///
										(1 + `etast'*`etast'*`rhost'*`rhost' + ///
											`v2'*`w2'*`rhost'*`etast')	`if' `in'
					label var 	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
				if `"`d1'`d2'"' == "#3#3"{
					gen `vtyp'	`varn' = -`q1'*`q2'*`w2'*`etast'*normalden(`v2') * ///
										( `d2dr' + `q1'*`q2'*`dr'*`etast' * ///
											(`etast'*`rhost' + `v2'*`w2') )	`if' `in'
					label var	`varn' "d `pred' / d xb(`d1') d xb(`d2')"
				}
			}
			exit
		}
	}
	
	error 198
end



program define rmTS, rclass
	
	local tsnm = cond( match("`0'", "*.*"),  		/*
			*/ bsubstr("`0'", 			/*
			*/	  (index("`0'",".")+1),.),     	/*
			*/ "`0'")

	return local rmTS `tsnm'
end
