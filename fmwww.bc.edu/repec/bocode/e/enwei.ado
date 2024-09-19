program enwei, rclass sortpreserve
   version 14.0


   syntax varlist(min=1) , Order(numlist)  [GENerate(string) DIMension(string) REPlace Biase(numlist) ] 


   local varN : word count `varlist'
   local numN : word count `order'
  

   if `varN' != `numN'{
       di ""
	   di as err "The number of variables is not equal the number of orders"
   }
   else{
       local N=`varN'
	   capture sum
	   local M=r(N)
   }
   
  

   	local missvar=""
	local varN : word count `varlist'
    forvalue i=1/`varN'{
	local Var:word `i' of `varlist'
	capture misstable summarize `Var' ,showzeros all 
	if r(N_eq_dot) != 0 | r(N_gt_dot) != 0{
       local missvar `missvar' `Var'
	}
	}
	local missvarN : word count `missvar'
	if `missvarN' >0{
		dis ""
		di as err "Warning: These variables have missing values "
		dis "`missvar'"
	}	
	

	mkmat `varlist' ,matrix(raw)


	if "`biase'" != ""{
	local bia=`biase'
	}
	else{
	local bia=1/(`M'*10000)
	}
	

	mat data_s=J(`M',1,.)
	
		
	forvalue i=1(1)`N'{
	local var:word `i' of `varlist'
	local k:word `i' of `order'
	
	mat v`i'=raw[1...,`i']
	mata:v = st_matrix("v`i'")
	
	if `k' != 0{
    mata:sv = (v - min(v)*J(rows(v), 1, 1)) / (max(v)-min(v)) + `bia'*J(rows(v), 1, 1)
	mata:st_matrix("sv", sv)
	mat `var'_s=sv
	}
	else{
    mata:sv = (max(v)*J(rows(v), 1, 1) - v) / (max(v)-min(v)) + `bia'*J(rows(v), 1, 1)
	mata:st_matrix("sv", sv)
	mat `var'_s=sv	
	}
	mat data_s=[data_s,`var'_s]
	
	}
	mat data_s=data_s[1...,2...]
 
    mata:data_s = st_matrix("data_s")



	mat p=J(`M',1,.)
	forvalue i=1(1)`N'{
	mat v`i'=data_s[1...,`i']
	mata:v = st_matrix("v`i'")
	mata:ps = v / colsum(v)
    mata:st_matrix("ps", ps)
	mat p=[p,ps]
	}
	mat p=p[1...,2...]


	mata:p = st_matrix("p")
    mata:p_lnp  = p :* ln(p)
		

	mata:E  = -1/ln(`M') * colsum(p_lnp)


	mata:D = J(1,`N', 1) - E
	

	mata:W = D/rowsum(D)
	

	mata:Index=data_s*W'
	

   matrix OrderM = J(1,`N',.)
   forvalues i=1/`N'{
   matrix OrderM[1,`i']=`: word `i' of `order''
   }	
	

	/*Display*/
	matrix colnames OrderM = `varlist'
	matrix rownames OrderM = "direction"
	
	mata:st_matrix("E", E)
	matrix colnames E = `varlist'
	matrix rownames E = "E"
	
	mata:st_matrix("D", D)
	matrix colnames D = `varlist'
	matrix rownames D = "D"
	
	mata:st_matrix("W", W)
	matrix colnames W = `varlist'
	matrix rownames W = "W"
	
	mata:st_matrix("Index", Index)
	
	dis ""
	dis as text "Order"
	dis as text "non-zero means Positive;0 means negative"	
	matlist OrderM
	dis ""
	dis "Entropy value"
	dis as text "E"
	matlist E ,format(%9.3f)
	dis ""
	dis "Information entropy redundancy"
	dis as text "D"
	matlist D ,format(%9.3f)	
	dis ""
	dis "weight"
	dis as text "W"
	matlist W ,format(%9.3f)	
	

	
	//generate variables
	if "`generate'" != ""{
	matrix colnames Index = "`generate'"
	if "`replace'" != "" {
	cap drop `generate'
	svmat Index ,names(col)
	label var `generate' "Score"
	}
	else{
	svmat Index ,names(col)
	label var `generate' "Score"
	}	
	}
	else{
	matrix colnames Index = "Entropy"
	if "`replace'" != "" {
	cap drop Entropy
	svmat Index ,names(col)
	label var Entropy "Score"
	}
	else{
	svmat Index ,names(col)
	label var Entropy "Score"
	}
	}
	
	
	
	
	if "`dimension'" != ""{
	mat DIM=J(`M',1,.)
	forvalue i=1(1)`N'{
	//scalar w`i'=W[1...,`i']
	mat D`i'=W[1...,`i'] * data_s[1...,`i']
	mat DIM=[DIM,D`i']
	}    
	mat DIM=DIM[1...,2...]

	local dname=""
	forvalue i=1(1)`N'{
	local var:word `i' of `varlist'

	local dname `dname' `dimension'_`var'
	}
	if "`replace'" != "" {
	cap drop `dname'
	}
	matrix colnames DIM = `dname'
	svmat DIM ,names(col)
	
	forvalue i=1(1)`N'{
	local var:word `i' of `varlist'
	label var `dimension'_`var' "score of `var'"
	}	
	
	}
	
	// store results in rclass
	return matrix OrderM = OrderM
    return matrix E = E
    return matrix D = D
	return matrix W = W
    return matrix Index = Index
	cap return matrix DIM = DIM
	
	
	
end




