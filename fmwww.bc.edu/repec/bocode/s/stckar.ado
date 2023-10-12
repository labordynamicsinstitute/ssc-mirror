*! 10oct23 Jonathan Thiele v1.0
*! jonathan.thiele@fu-berlin.de
* written in Stata version:  16.1

**program definition
program define stckar
version 10.0

**syntax definiton
syntax varlist(min=2 max=11) [if] ///
	[, noTOTal noSORT noLABELS ///
	noDRAW ORDer ///
	noFIXEDCOLORS ///
	SCHEME(string) ///
	STATistics(string) ///
	GRAPHOPTions(string) ///
	AREAOPTions(string) ///
	LINEOPTions(string)]

**naming arguments
args v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11

**if condition
marksample touse
preserve
qui keep if `touse' == 1

**nodraw
if "`draw'" == "nodraw"{
	local graphoptions = "`graphoptions' nodraw"
}

**scheme option
if "`scheme'" != ""{
	gr_setscheme
	local oldscheme = "`.__SCHEME.scheme_name'"
	set scheme `scheme'
}
gr_setscheme

**1)
**checking number of variables
tokenize `varlist'
local nvars = 1 
while "``nvars''" != "" {
	local ++nvars
}
local --nvars

**setting the x variable
local varx = "``nvars''"
local drop var`nvars'
local --nvars

**2)
**sorting the variables
local varlist2
local varlist3

if "`statistics'" == ""{
	local statistics mean 
}

forvalues i = 1/`nvars'{
    local varlist2 = "`varlist2'`i'"
	local varlist3 = "`varlist3'v`i' "
	if `i' < `nvars'{
	    local varlist2 = "`varlist2',"
	}
	qui sum `v`i'' 
	local v`i'stat = r(`statistics')
}

if "`sort'" == "nosort"{
	local varlist2
	forvalues i = `nvars'(-1)1{
		local varlist2 = "`varlist2'`i'"
		if `i' > 1{
			local varlist2 = "`varlist2',"
		}
	}
}

tempname variables
matrix input variables = (`varlist2')

if "`sort'" != "nosort"{
	local bubble = `nvars'
	while `bubble' > 1{
		local temp = `bubble' - 1
		forvalues i = 1/`temp'{
			local j = `i' + 1
			local k = variables[1,`i']
			local p = variables[1,`j']
			if abs(`v`k'stat') > abs(`v`p'stat'){
				local temp = variables[1,`j']
				matrix variables[1,`j'] = variables[1,`i']
				matrix variables[1,`i'] = `temp'
			}
		}
		local --bubble
	}
}

**3)
**further preparation
local varnum = variables[1,1]
local smallervar = "`v`varnum''"
local smallervar2 = "v`varnum'"
local graphlist `smallervar2'
local graphlist2 (area `smallervar2' `varx', color(`.__SCHEME.color.p`varnum''))
tempvar ``smallervar2''
qui gen `smallervar2' = `smallervar'

tempvar pos neg
qui gen pos = 0
qui gen neg = 0
qui replace pos = ``smallervar2'' if ``smallervar2'' > 0 
qui replace neg = ``smallervar2'' if ``smallervar2'' < 0 

**4) 
**calculation of summed up values
local i = 2
while `i' <= `nvars'{
    local j = `i'-1
	local varnum = variables[1,`i']
	local largervar = "v`varnum'"
	tempvar `smallervar2'_`largervar'
	qui gen `smallervar2'_`largervar' = 0
	qui replace `smallervar2'_`largervar' = pos + ``largervar'' if ``largervar'' > 0
	qui replace `smallervar2'_`largervar' = neg + ``largervar'' if ``largervar'' < 0
	qui replace pos = `smallervar2'_`largervar' if ``largervar'' > 0
	qui replace neg = `smallervar2'_`largervar' if ``largervar'' < 0
	local ++i
	local smallervar = "`smallervar2'_`largervar'"
	local smallervar2 = "`smallervar'"
	local graphlist = "`smallervar2' `graphlist'"
	local graphlist2 = "(area `smallervar2' `varx', color(`.__SCHEME.color.p`varnum'')) `graphlist2'"
}

**total
if "`total'" != "nototal"{
	tempvar tot_effect
	qui gen tot_effect = 0
	forvalues i = 1(1)`nvars'{
		qui replace tot_effect = tot_effect + `v`i''
	}
}

**5)
**graphing and labeling
if  "`order'" == "order"{
	dis "Legend Order:"
}

local i = `nvars'
local j = 1
local labellist
while `i' > 0{
    local varnum = variables[1,`i']
	local labelvar = "v`varnum'"
	if "`labels'" == "nolabels"{
		local labellist = "`labellist'" + "label(`j' ``labelvar'') "
	}
	else{
		local label0: variable label ``labelvar'' 
		if "`label0'" == ""{
			local label0  = "``labelvar''"
		}
		local labellist = "`labellist'" + "label(`j' `label0') "
	}
	if  "`order'" == "order"{
		dis "`j': ``labelvar''"
	}
	local --i
	local ++j
}

local nvars = `nvars' + 1

if "`total'" == "nototal"{
	if "`fixedcolors'" == "nofixedcolors"{
		twoway (area `graphlist' `varx'), legend(`labellist') `areaoptions' `graphoptions'
	}
	else{
		twoway `graphlist2', legend(`labellist') `areaoptions' `graphoptions'
	}
	
}
else{
	if "`fixedcolors'" == "nofixedcolors"{
		twoway (area `graphlist' `varx' `areaoptions') (line tot_effect `varx', color(black) lpattern(dash) `lineoptions') ///
		, legend(`labellist' label(`nvars' total)) `graphoptions'
	}
	else{
		twoway `graphlist2' (line tot_effect `varx', color(black) lpattern(dash) `lineoptions') ///
		, legend(`labellist' label(`nvars' total)) `graphoptions'
	}
}

if "`scheme'" != ""{
	set scheme `oldscheme'
}

restore

end
