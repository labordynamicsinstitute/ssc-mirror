*! verion 1.0.0 16apr2019 MJC

program define exptorcs, eclass
	syntax varlist(default=empty) , 	EVENT(varname numeric)			///
										EXPosure(varname numeric)		///
										YEAR(string)					///
										AGE(string)						///
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
	
	//==================================================================================================//
	
	local mainvars `varlist'
	
	//splines for year
	local 0 `year'
	syntax varlist(min=1 max=1) , 							///
									KNOTS(string) 			///
								[	 						///
									LOG 					///
									OFFset(passthru)		///
									NOORTHOG				///
								]
		local yvar `varlist'
		local yknots `knots'
		local ylog `log'
		local yoffset `offset'
		local ynoorthog `noorthog'
	
	
	//splines for age
	local 0 `age'
	syntax varlist(min=1 max=1) , 							///
									KNOTS(string) 			///
								[	 						///
									LOG 					///
									OFFset(passthru)		///
									NOORTHOG				///
								]
		local avar `varlist'
		local aknots `knots'
		local alog `log'
		local aoffset `offset'
		local anoorthog `noorthog'
	
	
	//fit poisson model
	qui poisson `event' `varlist'   , exposure(`exposure')
		
		tempname init
		matrix `init' = e(b)
	
	restore
	
	//merlin model
	merlin	(`avar' `mainvars' 														///
					rcs(`avar', knots(`yknots') `ylog' `ynoorthog' `yoffset') 		///
					rcs(`avar', knots(`aknots') `alog' `anoorthog' `aoffset') 		///
				, family(loghazard, failure(_status)) 								///
					timevar(`avar')) 												///
				, from(`init') iter(0)

end
