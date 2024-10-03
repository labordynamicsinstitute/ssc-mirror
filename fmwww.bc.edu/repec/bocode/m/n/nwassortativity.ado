capture program drop nwassortativity
program nwassortativity, rclass
	version 13 
	syntax  ,NETwork(string)  Attribute(string)   [Nodes(varname) Discrete Continuous  ]
	
	if "`discrete'"=="" & "`continuous'"==""{
		noi di as error "Discrete or Continuous option should be indicated."
	}
	
capture putmata _I=`network'*
capture nwtomata `network',mat(_I)
capture mata _I=`network'


mata _I=_I-diag(_I)

if "`continuous'"!="" {
	quietly{
mata _N=(_I:>=1)
mata _od=rowsum(_N)
mata _id=colsum(_N)'
putmata _T=`attribute',replace

mata _NT=_N*_T /*average neighbors T value*/

mata _NTo=_NT:/_od
 mata _NTi=_NT:/_id

capt drop _AvNeiAt
getmata _AvNeiAt=_NTo

corr `attribute' _AvNeiAt
return list
local _assortcoeff=r(rho)

return scalar _assortcoeff=`_assortcoeff'
	}
noi di "Assortativity coefficient of attribute `attribute' is : `_assortcoeff'"


}

if "`discrete'"!="" {

quietly{

capture drop _typec
egen _typec=group(`attribute')
putmata _T=_typec,replace
tab _typec
return list
local nt=r(r)

forvalues t=1/`nt' {
mata _T`t'=mm_cond(_T:==`t',1,0)
}

forvalues i=1/`nt' {
	forvalues j=1/`nt' {
		mata _I_`i'_`j'=_I:*_T`i'*_T`j''
		mata _I_`i'_`j'=sum(_I_`i'_`j')

	}
}


forvalues i=1/`nt' {
	forvalues j=1/`nt' {
		if `j'==1{
			mata _E`i'=(_I_`i'_`j')
		}
		else{		
			mata _E`i'=(_E`i',_I_`i'_`j')
		}
	}
}

	forvalues j=1/`nt' {
		if `j'==1{
			mata _E=_E`j'
		}
		else {
		mata _E=(_E\_E`j')
	}
}
mata _E
mata _TE=sum(_E)
mata _e=_E:/_TE
mata sum(_e)

mata _a=colsum(_e)
mata _b=rowsum(_e)
mata _a
mata _b

mata _tre=trace(_e)
mata _sab=_a*_b

mata _r=(_tre-_sab)/(1-_sab)
mata _r
mata _rmin=-_sab/(1-_sab)
mata _rmin
mata st_local("_assortcoeff", strofreal(_r))
return scalar _assortcoeff=`_assortcoeff'

mata st_local("_mincoeff", strofreal(_rmin))
return scalar _mincoeff=`_mincoeff'
noi di "Assortativity coefficient of attribute `attribute' is : `_assortcoeff'"

}
	
}

			end