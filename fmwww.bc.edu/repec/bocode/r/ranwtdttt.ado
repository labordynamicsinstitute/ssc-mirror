*! 1.0 KBN, Jan 14, 2020
*! 1.1 KBN, Jan 28, 2020

program define ranwtdttt, rclass
version 14.1

syntax varlist(min=1 max=1) [if] [in], id(varname) ///
	samplestart(string) sampleend(string) ///
	[reverse ///
	conttime ///
	nsamp(integer 1) ///
	*] 

quietly {
if "`if'" != "" | "`in'" != "" {
	keep `if' `in'
	}

tokenize `varlist' 
local obstime `1' 

tempvar tstart tend delta

capture {
	* For analysis of discrete data
	if "`conttime'" == "" {
		local tstart = td(`samplestart')
		local tend = td(`sampleend')
	}
	* For analysis of continuous data 
	else {
		local tstart = `samplestart'
		local tend = `sampleend'
	}
}
if _rc == 198 {
	display as error "For discrete prescription data both -start()- and -end()- need to be specified as dates." ///
	_n "For continuous data use the option -conttime- and let -start()- and -end()- be given as numbers instead of dates."
	exit 198
}

local delta = `tend' - `tstart'
local dateformat : format `obstime'

tempvar	indda

forval i = 1/`nsamp' {
	preserve
	
bysort `id' (`obstime'): gen double `indda' = runiform(`tstart',`tend') if _n == 1

	bysort `id' (`obstime'): replace `indda' = `indda'[1]
	
	if "`reverse'" != "" {
		keep if `obstime' >= `indda' - `delta' & `obstime' <= `indda' 
		bysort `id' (`obstime'): keep if _n == _N
		gen double _rxshift = `obstime' + `tend' - `indda'
		label variable _rxshift "Last prescription redemption prior to index date (shifted)"
	}
	else {
		keep if `obstime' <= `indda' + `delta' & `obstime' >= `indda' 
		bysort `id' (`obstime'): keep if _n == 1
		gen double _rxshift = `obstime' - (`indda' - `tstart')
		label variable _rxshift "First prescription redemption subsequent to index date (shifted)"
	}	

	tempfile lastobs`i'
	sa `lastobs`i'', replace
	
	restore
}

forv i = 1/`nsamp' {
    if `i' == 1 {
        use `lastobs1', clear
    }
    else {
        append using `lastobs`i''
    }
}

format _rxshift `dateformat'

if "`reverse'" != "" {
	if "`conttime'" != "" {
		noisily wtdttt _rxshift, start(`samplestart') end(`sampleend') conttime reverse vce(cluster `id') `options' 
	}
	else {
		noisily wtdttt _rxshift, start(`samplestart') end(`sampleend') reverse vce(cluster `id') `options' 
	}
}
else {
	if "`conttime'" != "" {
		noisily wtdttt _rxshift, start(`samplestart') end(`sampleend') conttime vce(cluster `id') `options'
	}
	else {
		noisily wtdttt _rxshift, start(`samplestart') end(`sampleend') vce(cluster `id') `options'
	}
}

return scalar logtimeperc = r(logtimeperc)
return scalar timepercentile = r(timepercentile)
return scalar selogtimeperc = r(selogtimeperc)
return scalar setimepercentile = r(setimepercentile)
return scalar prevprop = r(prevprop)
return scalar seprev = r(seprev)
return local disttype = r(disttype)
return local reverse "`reverse'"
return scalar samplestart = `tstart'
return scalar sampleend = `tend'
return scalar delta = r(delta)

}
end

