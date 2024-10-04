*! nca_random Version 1.0 (Beta) 03 Oct 2023 
pro def nca_random  
syntax, [Nobs(integer 1000) Reps(integer 1) slope(real 1) intercept(real 0) /// 
		meanx(real 0) sdx(real 1) meany(real 0) sdy(real 1) scopex(numlist) /// 
		distrx(string) distry(string) miny(real 0)]
		version 15
		if ("`distrx'"=="") local distrx uniform
		if ("`distry'"=="") local distry uniform
		if ("`distrx'"!="normal" &  "`distrx'"!="uniform") {
			di as error "please specify {bf: normal} or {bf: uniform} in option {bf: distrx}"
			exit 144
		} 
		if ("`distry'"!="normal" &  "`distry'"!="uniform") {
			di as error "please specify {bf: normal} or {bf: uniform} in option {bf: distry}"
			exit 144
		} 
		if ("`distrx'"=="uniform") {
			if ("`scopex'"=="") local scopex 0 1 
			cap numlist "`scopex'", ascending min(2) max(2)
			if (_rc==122) di as error "invalid {bf: scopex()} option: it has too few elements"
			if (_rc==124) di as error "invalid {bf: scopex()} option: elements are not in ascending order"
			if _rc exit _rc
			local scopex= subinstr("`scopex'"," ",",",.) 
			local scopex (`scopex')
		}
		cap numlist "`nobs'", integer min(1) max(1)  range(>=1)
		if _rc {
			di as error "option {bf: nobs} incorrectly specified"
			exit _rc
		}
		cap numlist "`reps'", integer min(1) max(1)  range(>=1)
			if _rc {
			di as error "option {bf: reps} incorrectly specified"
			exit _rc
		}
		cap numlist "`sdx' `sdy'",  min(2) max(2)  range(>0)
		if _rc {
			di as error "{bf: sdx} and {bf: sdy}  must be positive real numbers"
			exit _rc
		}
		if ("`distrx'"=="normal") local paramX (`meanx',`sdx')
		else local paramX `scopex'
		if ("`distry'"=="normal") local paramY (`meany',`sdy')
		else local paramY (`miny',1)
		
		quie mata: _nca_random(`nobs', `reps', ("`distrx'","`distry'"), (`intercept',`slope'), `paramX', `paramY', 1)
		end