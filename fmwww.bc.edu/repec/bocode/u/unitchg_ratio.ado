*! version 1.0.0 April 3, 2025 @ 17:09:07 UK

program unitchg_ratio, rclass
	syntax [ , mileage(string) speed(string)  to(string) ]

	if inlist("`speed'","kn","knot") {
		local speed "nmi/h"
	}
	if inlist("`to'","kn","knot") {
		local to "nmi/h"
	}
		
	local converter = cond("`mileage'"!="","mileage","speed")
	local VorT = cond("`mileage'"!="","volume","time")
		
	gettoken fromnominator rest: `converter', parse("/")
	gettoken rest fromdenominator: rest, parse("/")
	
	gettoken tonominator rest: to, parse("/")
	gettoken rest todenominator: rest, parse("/")

	capture mata unitchg("length","`fromnominator'","m")
	if !_rc local fromtyp length/`VorT'
	else  local fromtyp `VorT'/length
	
	capture mata unitchg("length","`tonominator'","m")
	if !_rc local totyp length/`VorT'
	else local totyp `VorT'/length
	
	
	if "`fromtyp'" == "length/`VorT'" & "`totyp'" == "length/`VorT'" {
		
		capture mata: unitchg("length","`fromnominator'","`tonominator'")
		if _rc {
			noisily display `"{err}Unit `fromnominator' or `tonominator' not available in converter length"'
			exit 198
		}
	
		
		local lengthrescale = unitchg_rescale
		local fromnominator  `fromname'
		local tonominator `toname'
		
		capture mata: unitchg("`VorT'","`fromdenominator'","`todenominator'")
		if _rc {
			noisily display `"{err}Unit `fromdenominator' or `todenominator' not available in converter `VorT'"'
			exit 198
		}
		local `VorT'rescale = unitchg_rescale
		local fromdenominator  `fromname'
		local todenominator  `toname'
		
		local formula X * `lengthrescale' * 1/``VorT'rescale'
	}
		
	else if "`fromtyp'" == "`VorT'/length" & "`totyp'" == "`VorT'/length" {
			
		capture mata: unitchg("length","`fromdenominator'","`todenominator'")
		if _rc {
			noisily display `"{err}Unit `fromdenominator' or `todenominator' not available in converter length"'
			exit 198
		}
		local lengthrescale = unitchg_rescale
		local fromdenominator  `fromname'
		local todenominator `toname'
		
		capture mata: unitchg("`VorT'","`fromnominator'","`tonominator'")
		if _rc {
			noisily display `"{err}Unit `fromnominator' or `tonominator' not available in converter `VorT'"'
			exit 198
		}
		
		local `VorT'rescale = unitchg_rescale
		local fromnominator  `fromname'
		local tonominator  `toname'
			
		local formula X * 1/`lengthrescale' * ``VorT'rescale' 
		}
		
		else if "`fromtyp'" == "length/`VorT'" & "`totyp'" == "`VorT'/length" {
			
		capture mata: unitchg("length","`fromnominator'","`todenominator'")
		if _rc {
			noisily display `"{err}Unit `fromnominator' or `todenominator' not available in converter length"'
			exit 198
		}
		
		local lengthrescale = unitchg_rescale
		local fromnominator  `fromname'
		local todenominator `toname'
		
		capture mata: unitchg("`VorT'","`fromdenominator'","`tonominator'")
		if _rc {
			noisily display `"{err}Unit `fromdenominator' or `tonominator' not available in converter `VorT'"'
			exit 198
		}
		local `VorT'rescale = unitchg_rescale
		local fromdenominator  `fromname'
		local tonominator  `toname'
		
		local formula 1/(X * `lengthrescale' * 1/``VorT'rescale') 
	}
		
		else if "`fromtyp'" == "`VorT'/length" ///
		  & "`totyp'" == "length/`VorT'" {
			
		capture mata: unitchg("length","`fromdenominator'","`tonominator'")
		if _rc {
			noisily display `"{err}Unit ``fromdenominator'' or `tonominator' not available in converter length"'
			exit 198
		}

		local lengthrescale = unitchg_rescale
		local fromdenominator  `fromname'
		local tonominator `toname'
		
		capture mata: unitchg("`VorT'","`fromnominator'","`todenominator'")
		if _rc {
			noisily display `"{err}Unit ``fromnominator'' or `todenominator' not available in converter `VorT'"'
			exit 198
		}

		local `VorT'rescale = unitchg_rescale
		local fromnominator  `fromname'
		local todenominator  `toname'
		
		local formula 1/(X * 1/`lengthrescale' * ``VorT'rescale') 
	}

	return local from `fromnominator' per `fromdenominator'
	return local to `tonominator' per `todenominator'
	return local formula `formula'
		
end

