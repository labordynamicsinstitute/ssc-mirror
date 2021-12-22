*! verion 1.1.0 03feb2020 MJC

program define exptorcs, eclass
	syntax [varlist(default=none)] , 	EVENT(string)			///
										EXPosure(string)		///
										YEAR(string)			///
										AGE(string)				///
										EXPDATA(string)					
										
	cap which rcsgen
	if _rc {
		di as error "You need to install the rcsgen package from SSC"
		exit 198
	}
	cap which merlin 
	if _rc {
		di as error "You need to install the merlin package from SSC"
		exit 198
	}
	
	//confirm dataset has been msset
	cap confirm variable _status
	if _rc {
		di as error "Dataset must contain _status variable from using -msset-"
		exit 198
	}
	
	
	preserve
	qui use `expdata', clear
	
	cap confirm variable `event'
	if _rc {
		di as error "`event' variable not found in expdata()"
		exit 198
	}
	cap confirm variable `exposure'
	if _rc {
		di as error "`exposure' variable not found in expdata()"
		exit 198
	}
	
	//==================================================================================================//
	
	local mainvars `varlist'
	
	//splines for year
	local 0 `year'
	syntax varlist(min=1 max=1) , 							///
									KNOTS(string) 			///
								[	 						///
									LOG 					///
									NOORTHOG				///
								]
		local yvar `varlist'
		local yknots `knots'
		local ylog `log'
		local ynoorthog `noorthog'
		
		//build temp year splines
		tempvar ycore
		qui gen double `ycore' = `yvar'
		
		if "`log'"!="" {
			qui replace `ycore' = log(`ycore')
		}
		if "`noorthog'"=="" {
			local yorthog orthog
		}
		tempname ysp
		qui rcsgen `ycore', knots(`knots') gen(`ysp') `yorthog'
		local yspvars `r(rcslist)'
	
	//splines for age
	local 0 `age'
	syntax varlist(min=1 max=1) , 							///
									KNOTS(string) 			///
								[	 						///
									LOG 					///
									NOORTHOG				///
								]
		local avar `varlist'
		local aknots `knots'
		local alog `log'
		local anoorthog `noorthog'
	
		//build temp age splines
			tempvar acore
			qui gen double `acore' = `avar'
			
			if "`log'"!="" {
				qui replace `acore' = log(`acore')
			}
			if "`noorthog'"=="" {
				local aorthog orthog
			}
			tempname asp
			qui rcsgen `acore', knots(`knots') gen(`asp') `aorthog'
			local aspvars `r(rcslist)'
	
	
	
	//fit poisson model
	qui poisson `event' `mainvars' `yspvars' `aspvars' , exposure(`exposure')
		
		tempname init
		matrix `init' = e(b)
	
	restore
	
	//merlin model
	
	di as result "Note; age is assumed to be the main timescale"
	di as result "      year is modelled as attained age with an offset of: "
	qui gen double _offset = `yvar'-`avar'
	di as result "-> gen double _offset = `yvar' - `avar'"
	di 
	
	di as result "Building merlin model:"
	merlin	(`avar' `mainvars' 														///
					rcs(`avar', knots(`yknots') `ylog' `ynoorthog' offset(_offset)) ///
					rcs(`avar', knots(`aknots') `alog' `anoorthog')			 		///
				, family(loghazard, failure(_status)) 								///
					timevar(`avar')) 												///
				, from(`init') iter(0)

end
