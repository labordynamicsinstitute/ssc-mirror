program define ras
	version 12
	// version 1.1
	// option z is not available for public currently
	syntax varlist(min=5), n(integer) [a r s z half]

	//check the number of iterations
	if (`n'<1){
		display in red "The number of iterations cannot be smaller than 1."
		exit
	}
	
	//default option
	if ("`a'"==""&"`r'"==""&"`s'"==""&"`z'"==""){
		local a="a"
	}
	
	//check data
	local ca=0
	local missing=0
	foreach var0 in `varlist'{
		local ca=`ca'+1
		local d`ca'="`var0'"
		quietly count if missing(`d`ca'')
		if (r(N)>0){
			local missing=1
		}
	}
	if (`missing'==1){
		display in red "The data has missing-values."
		exit
	}
	if (`ca'-3!=_N){
		display in red "You can only input a n*n matrix."
		exit
	}

	
	//Initialization of N
	local n0=_N
	local n1=_N+1
	local n2=_N+2
	local n3=_N+3
	
	//define namespace
	tempname A0 X0 RS0 SS0 r_one0 c_one0 R0 S0 ax0 sum0 weight0 A_end0 error0

	//Initialization of Matrices
	matrix `A0' =J(_N,_N,0)
	matrix `X0'=J(_N,1,0)
	matrix `RS0'=J(_N,1,0)
	matrix `SS0'=J(_N,1,0)
	matrix `r_one0'=J(1,_N,1)
	matrix `c_one0'=J(_N,1,1)
	matrix `R0' =diag(`r_one0')
	matrix `S0' =diag(`r_one0')
	matrix `weight0'=J(_N,1,1)
	matrix `error0'=J(_N,2,0)

	//Set Matrices
	forvalues i=1(1)`n0'{
		forvalues j=1(1)`n0'{
			matrix `A0'[`i',`j']=`d`j''[`i']
		}
	}
	forvalues i=1(1)`n0'{
		matrix `X0'[`i',1]=`d`n1''[`i']
	}
	forvalues i=1(1)`n0'{
		matrix `RS0'[`i',1]=`d`n2''[`i']
	}
	forvalues i=1(1)`n0'{
		matrix `SS0'[`i',1]=`d`n3''[`i']
	}
	matrix `ax0'=`A0'*diag(`X0')
	
	//RAS
	forvalues i=1(1)`n'{
		//R
		matrix `sum0'=`ax0'*`c_one0'
		forvalues j=1(1)`n0'{
			matrix `weight0'[`j',1]=`RS0'[`j',1]/`sum0'[`j',1]
		}
		matrix `R0'=diag(`weight0')*`R0'
		matrix `ax0'=diag(`weight0')*`ax0'
		//S	
		if (`i'!=`n'|"`half'"==""){
			matrix `sum0'=(`r_one0'*`ax0')'
			forvalues j=1(1)`n0'{
				matrix `weight0'[`j',1]=`SS0'[`j',1]/`sum0'[`j',1]
			}
			matrix `S0'=`S0'*diag(`weight0')
			matrix `ax0'=`ax0'*diag(`weight0')
		}
	}
	

	//Calculate error, A
	matrix `A_end0'=`ax0'*inv(diag(`X0'))
	if ("`half'"!=""){
		dis ""
		dis "  The last RAS iteration will be executed a half (only R)."
		matrix `sum0'=(`r_one0'*`ax0')'
		forvalues i=1(1)`n0'{
			matrix `error0'[`i',1]=`sum0'[`i',1]-`SS0'[`i',1]
			matrix `error0'[`i',2]=(`sum0'[`i',1]/`SS0'[`i',1]-1)*100
		}
	}
	else{
		matrix `sum0'=`ax0'*`c_one0'
		forvalues i=1(1)`n0'{
			matrix `error0'[`i',1]=`sum0'[`i',1]-`RS0'[`i',1]
			matrix `error0'[`i',2]=(`sum0'[`i',1]/`RS0'[`i',1]-1)*100
		}
	}
	

	//Store the result
	if ("`a'"!=""){
		forvalues i=1(1)`n0'{
			capture drop _ras_A`i'
			quietly gen _ras_A`i'=.
			forvalues j=1(1)`n0'{
				quietly replace _ras_A`i'= `A_end0'[`j',`i'] in `j'
			}
		}
	}
	if ("`r'"!=""){
		forvalues i=1(1)`n0'{
			capture drop _ras_R`i'
			quietly gen _ras_R`i'=.
			forvalues j=1(1)`n0'{
				quietly replace _ras_R`i'= `R0'[`j',`i'] in `j'
			}
		}
	}
	if ("`s'"!=""){
		forvalues i=1(1)`n0'{
			capture drop _ras_S`i'
			quietly gen _ras_S`i'=.
			forvalues j=1(1)`n0'{
				quietly replace _ras_S`i'= `S0'[`j',`i'] in `j'
			}
		}
	}
	if ("`z'"!=""){
		forvalues i=1(1)`n0'{
			capture drop _ras_Z`i'
			quietly gen _ras_Z`i'=.
			forvalues j=1(1)`n0'{
				quietly replace _ras_Z`i'= `ax0'[`j',`i'] in `j'
			}
		}
	}
	capture drop _ras_Error
	capture drop _ras_Error_rate
	quietly gen _ras_Error=0
	quietly gen _ras_Error_rate="%"
	local max_error=0
	local max_error_rate=0
	forvalues i=1(1)`n0'{
	    local e=`error0'[`i',1]
		if (abs(`e')>abs(`max_error')){
			local max_error=`e'
		}
		quietly replace _ras_Error= `e' in `i'
		local e=`error0'[`i',2]
		if (abs(`e')>abs(`max_error_rate')){
			local max_error_rate=`e'
		}
		quietly replace _ras_Error_rate= "`e'%" in `i'
	}
	
	
	//display the result
	dis ""
	dis "  Error & Error Rate:"
	list _ras_Error _ras_Error_rate, noobs noheader
	dis "  Error (Max Abs.): `max_error'"
	dis "  Error_rate (Max Abs.): `max_error_rate'%"
	
end