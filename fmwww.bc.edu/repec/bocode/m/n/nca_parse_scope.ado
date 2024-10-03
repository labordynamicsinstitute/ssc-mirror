

pro def nca_parse_scope, rclass
syntax varlist [if] [in], [scope(numlist missingokay)]
tempname scopemat scopeX scopeY empirical_scopemat
if ("`scope'"=="") {
	quietly tabstat  `varlist', stat(min max)  save
	matrix `scopemat' =r(StatTotal)'
	matrix `empirical_scopemat' =`scopemat'
}
else {
	if (`:word count `scope''/2 !=`:word count `varlist'') {
	display as error "please check the option {bf: scope}: you specified {bf: `:word count `scope''} numbers but {bf: `=2*`:word count `varlist'''} are required"
	exit 144
	}	
	else {
		matrix `scopemat'=J(`:word count `varlist'',2,.)
		matrix `empirical_scopemat'=J(`:word count `varlist'',2,.)
		matrix rownames `scopemat'=`varlist'
		matrix colnames `scopemat'=Min Max
		matrix rownames `empirical_scopemat'=`varlist'
		matrix colnames `empirical_scopemat'=Min Max
		
		foreach v of local varlist {
			gettoken min scope : scope  
			gettoken max scope : scope
			if (`min'>`max') {
				di as error "theoretical minimum of `v' (`min') is greater than theoretical maximum (`max'), please check the option {bf: scope}"
				exit 144
			}
			
			sum `v' ,meanonly
			matrix `empirical_scopemat'[ rownumb(`empirical_scopemat',"`v'"),1]=r(min)
			matrix `empirical_scopemat'[ rownumb(`empirical_scopemat',"`v'"),2]=r(max)
			local min=min( `min', r(min))
			if missing(`max') local max=r(max)
			else local max=max( `max', r(max))
				
			
			matrix `scopemat'[ rownumb(`scopemat',"`v'"),1]=`min'
			matrix `scopemat'[ rownumb(`scopemat',"`v'"),2]=`max'
				}
	}

	
}
matrix `scopeX'=`scopemat'[1 .. (rowsof(`scopemat')-1) , 1..2]
matrix `scopeY'=`scopemat'[rowsof(`scopemat') , 1..2]
	return matrix scopeX=`scopeX'
	return matrix scopeY=`scopeY'
	return matrix scopematrix=`scopemat'
	return matrix empirical_scopematrix=`empirical_scopemat'

	

end
