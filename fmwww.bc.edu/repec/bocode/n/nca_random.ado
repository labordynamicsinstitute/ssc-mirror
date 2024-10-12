*! nca_random Version 1.0 11 Oct 2024
pro def nca_random  
syntax [namelist(min=2 max=2)], n(numlist min=1 max=1 integer >=1) Slopes(numlist) Intercepts(numlist) [ /// 
		XMean(numlist min=0 ) XSd(numlist min=0 >0) YMean(numlist min=0) YSd(numlist min=0 >0) /// 
		XDistribution(string) YDistribution(string) clear]
		version 15
		`clear'
		if ("`xdistribution'"=="") local xdistribution uniform
		if ("`ydistribution'"=="") local ydistribution uniform
		if ("`xdistribution'"!="normal" &  "`xdistribution'"!="uniform") {
			di as error "please specify {bf: normal} or {bf: uniform} in option {bf: xdistribution}"
			exit 144
		} 
		if ("`ydistribution'"!="normal" &  "`ydistribution'"!="uniform") {
			di as error "please specify {bf: normal} or {bf: uniform} in option {bf: ydistribution}"
			exit 144
		} 

		if (`:word count `slopes''>1 & `:word count `intercepts''==1) local intercepts=`:word count `slopes''*"`intercepts' "
		if (`:word count `slopes''==1 & `:word count `intercepts''>1) local slopes=`:word count `intercepts''*"`slopes' "
		if (`:word count `slopes''!=`:word count `intercepts'') {
			di as error "{bf: intercepts} and {bf: slopes} should have the same number of arguments"
			exit 144
		}
		if ("`xmean'"=="") local xmean=0.5 
		if ("`ymean'"=="") local ymean=0.5 
		if ("`xsd'"=="") local xsd=0.2 
		if ("`ysd'"=="") local ysd=0.2 
		if ("`namelist'"=="") local namelist x y
		
		if ("`xdistribution'"=="normal") local paramX (`xmean',`xsd')
		else local paramX (.,.)
		if ("`ydistribution'"=="normal") local paramY (`ymean',`ysd')
		else local paramY (.,.)
		
		quie mata:  _nca_random2(`n', 1,   ("`xdistribution'","`ydistribution'"), "`intercepts'", "`slopes'",  `paramX', `paramY' , "`namelist'")
		local vlist `:word 1 of `namelist''* `:word 2 of `namelist'' 
		foreach var of varlist `vnames' {
		cap assert !missing(`var')
		if _rc di as text "WARNING!  {bf:`var'} has values outside [0,1] , please check {bf: intercepts} and {bf: slopes}"
		}
		 
end