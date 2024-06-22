**************************************************
** Sylvain Weber, Martin Péclat & August Warren **
**         This version: June 18, 2024          **
**************************************************

*! version 4.2 by Sylvain Weber, Martin Péclat & August Warren 18jun2024
/*
Revision history:
- version 1.1 (2nov2016):
	- Single loop over i to calculate both coordinates and distance instead of two loops in version 1.0.
	  Advantage: if the program fails before the end, what has already been geocoded is saved while
	  it was lost with previous version. 
	  Other advantage: there is now a single timer instead of three separate (startaddress, endaddress, 
	  distance) in previous version. The help file has been adapted accordingly.
	- Other minor changes: miles obtained as 1.609344*km instead of 1.6093, unused temporary variables 
	  dropped, url links created outside the loop and renamed.
- version 2.0 (24feb2017):
	- Check if HERE account is valid.
	- cit in route_url if !herepaid
	- Create a variable containing diagnostic codes (useful if distances cannot be computed).
- version 2.1 (20sep2017)
	- Option -pause- added
- version 2.2 (20oct2017):
	- Correction of a bug causing an error (no geocoding) if x,y coordinates 
	  in startxy() or endxy() were below 1 (in absolute value).
- version 2.3 (24oct2017):
	- Correction of a bug (introduced by the previous correction) 
	  causing an error (no geocoding) if x,y coordinates 
	  in startxy() or endxy() were above 100 (in absolute value).
	- Correction of a mistake in the diagnostic variable coding.
- version 2.4 (27oct2017):
	- Correction of a bug causing a minor error at the end of the process 
	  (no impact on geocoding and routing output) if georoute is used with 
	  startaddress() and/or endaddress() without the coordinates() option.
- version 3.0 (30jul2020)
	- Complete revision: many HERE features implemented as options + miscellanous improvements
- version 3.1 (02nov2020)
	- Part of condition in line 715 "!mi(``p'_address'[`i'])" was causing last calculated distance and 
	  time to be erroneously copied to next observation if no start/end address was recorded. 
	- Creation of temporary variables used for insheetjson moved out of the loop
	  (otherwise, new variables are created at each iteration, even though the name is the same)
- version 3.2 (17mar2021)
	- use geturi() to format addresses properly.
- version 4.0 (05jan2022)
	- HERE's routing API v7 service is deprecated and is planned to be discontinued. 
	  Transit API V8 used instead for transport modes "publicTransport" and 
	  "publicTransportTimeTable".
	- Possibility to use hereid(APP ID) and herecode(APP CODE) instead of 
	  herekey(API KEY) suppressed.
- version 4.1 (02aug2023)
	- Adjustments following HERE migration from https://developer.here.com to https://platform.here.com:
		- URL links for geocoding
		- Columns in JSON requests
		- Method for controlling HERE credentials
		- Query score [0-1] instead of match code [1,2,3,4]
- version 4.2 (18jun2024)
	- Integration of possibility to use "any" in dtime to specify a route without a specific departure time
*/


program georoute
version 10.0


*** Syntax ***
#d ;
syntax [if] [in],
		herekey(string)
	[
		STARTADdress(varlist) startxy(varlist min=2 max=2 numeric) 
		ENDADdress(varlist) endxy(varlist min=2 max=2 numeric) 
		DIstance(string) TIme(string) COordinates(string)
		DIAGnostic(string) 
		replace
		TMode(string)
		RType(string)
		DTime(string)
		AVoid(string)
		km
		herepaid
		timer pause OBServations NOSETtings
	]
;
#d cr

*** Mark sample to be used ***
marksample touse
tempvar touse0
qui: gen `touse0' = `touse'
qui: count if `touse'
local N0 = r(N)
local N = r(N)
local warnings = 0

*** Preliminary checks ***

*Packages insheetjson.ado and libjson.mlib must be installed
cap: which insheetjson.ado
if _rc==111 {
	di as err "insheetjson required; type {stata ssc install insheetjson}"
	exit 111
}
cap: which libjson.mlib
if _rc==111 {
	di as err "libjson required; type {stata ssc install libjson}"
	exit 111
}

*HERE credentials must be valid and internet connection is required
*Check HERE credentials using a (wrong) query
*local here_check = "https://geocoder.ls.hereapi.com/6.2/geocode.json?searchtext=outofearth&apiKey=`herekey'" // developer
local here_check = "https://geocode.search.hereapi.com/v1/geocode?q=paris&apiKey=`herekey'" // platform
tempvar checkok 
qui: gen str240 `checkok' = ""
*qui: insheetjson `checkok' using "`here_check'", columns("Response:MetaInfo:Timestamp") flatten replace // developer
qui: insheetjson `checkok' using "`here_check'", columns("items:1:address:countryCode") flatten replace // platform
*if `checkok'[1]=="" {
if `checkok'[1]!="FRA" {
	*Check internet connection
	preserve
	cap: webuse auto, clear
	if _rc {
		di as err "georoute requires an active internet connection. Please check your internet connection."
		exit 631
	}
	restore
	di as err `"There seems to be an issue with the credentials of your HERE application: {browse "https://developer.here.com"}."'
	exit 198
}

*One start address or start point and one end address or end point must be specified (one of each and only one)
foreach p in start end {
	if "``p'address'"=="" & "``p'xy'"=="" {
		di as err "`p'address() or `p'xy() is required."
		exit 198
	}
	if "``p'address'"!="" & "``p'xy'"!="" {
		di as err "`p'address() and `p'xy() may not be combined."
		exit 184
	}
}

*Addresses can be specified in a single or in several variables
foreach p in start end {
	if "``p'address'"!="" {
		tokenize ``p'address'
		tempvar `p'_address
		qui: gen ``p'_address' = `1'
		cap: tostring ``p'_address', replace
		local i 2
		while `"``i''"'!="" {
			tempvar str
			cap: confirm string variable ``i''
			if _rc qui: tostring ``i'', gen(`str')
			if !_rc qui: gen `str' = ``i''
			qui: replace ``p'_address' = ``p'_address' + ", " + `str'
			local ++i
		}
	}
}


*** Parse transport mode (tmode) ***
*If tmode is not specified, set it to default = 'car'
if "`tmode'"=="" {
	local tmode "car"
	local tmodedefault " (assigned by default)"
}
*Determine if tmode is hardcoded or variable
cap: confirm variable `tmode'
*If tmode is hardcoded
if _rc {
	local tmodevar = 0
	if !inlist("`tmode'","car","publicTransit","pedestrian","bicycle") {
		di as err _n(1) "The specified transport mode (" as input "`tmode'" as err `") is not allowed. Please use one of the following (see also {browse "https://developer.here.com/documentation/routing/topics/transport-modes.html":HERE documentation} for details):"'
		di as err _col(3) "- car"
		di as err _col(3) "- publicTransit"
		di as err _col(3) "- pedestrian"
		di as err _col(3) "- bicycle"
		exit 198
	}
}
*If tmode is a variable
else {
	local tmodevar = 1
	*Check that tmode is in string format
	cap: confirm string variable `tmode'
	if _rc {
		di as err "The format of " as input "`tmode'" as err " must be string."
		exit 107
	}
	*Set missing tmode to default (car)
	tempvar tmodetmp
	qui: gen `tmodetmp' = `tmode'
	qui: count if `touse0' & mi(`tmode')
	local N0mis_tmode = `r(N)'
	qui: count if `touse' & mi(`tmode')
	local Nmis_tmode = `r(N)'
	local Nexc_tmode = 0
	if `Nmis_tmode'>0 {
		if !`warnings' {
			di as err _n(1) "Warning(s):"
			local warnings = 1
		}
		di as err _col(3) "- Transport mode was set to " as input "'car'" as err " for " as input "`Nmis_tmode'" as err `" observation`=cond(`Nmis_tmode'>1,"s","")' with missing value in "' as input "`tmode'" as err "."
	}
	qui: replace `tmodetmp' = "car" if `touse' & mi(`tmode')
	*Check each level to verify it is in allowable list
	cap: levelsof `tmodetmp' if `touse', local(tmodes)
	foreach tm of local tmodes {
		if "`tm'"!="" & !inlist("`tm'","car","publicTransit","pedestrian","bicycle") {
			if !`warnings' {
				di as err _n(1) "Warning(s):"
				local warnings = 1
			}
			di as err _col(3) _c "- Transport mode " as input "`tm'" as err `" is not allowed (see also {browse "https://developer.here.com/documentation/routing/topics/transport-modes.html":HERE documentation} for details): car, publicTransit, pedestrian, bicycle."'
			qui: count if `touse' & `tmodetmp'=="`tm'"
			local Nexc_tmode = `r(N)'
			di as input "`Nexc_tmode'" as err `" observation`=cond(`Nexc_tmode'>1,"s","")' with "' as input "`tmode'==`tm'" as err " will be ignored."
			qui: replace `touse' = 0 if `tmodetmp'=="`tm'"
			cap: count if `touse'
			local N = r(N)
		}
	}
}


*** Parse route type (rtype) ***
*Default = 'fast'
if "`rtype'"=="" {
	local rtype "fast"
	local rtypedefault " (assigned by default)"
}
*Determine if rtype is hardcoded or variable
cap: confirm variable `rtype'
*If rtype is hardcoded
if _rc {
	local rtypevar = 0
	foreach rt in fast short {
		if regexm("`rt'","^`rtype'") { // search for a match at the beginning of the string -> Route types can be abbreviated to a minimum of 1 letter
			local rtype = "`rt'"
		}
	}
	if !inlist("`rtype'","fast","short") {
		di as err _n(1) "The specified routing type (" as input "`rtype'" as err `") is not allowed. Please use one of the following (see also {browse "https://developer.here.com/documentation/routing/dev_guide/topics/resource-param-type-routing-mode.html#type-routing-type":HERE documentation} for details):"'
		di as err _col(3) "- fast"
		di as err _col(3) "- short"
		di as err "Routing types can be abbreviated to a minimum of 1 letter: 'f' for fast, 's' for short."
		exit 198
	}
}
*If rtype is a variable
else {
	local rtypevar = 1
	*Check that rtype is in string format
	cap: confirm string variable `rtype'
	if _rc {
		di as err "The format of " as input "`rtype'" as err " must be string."
		exit 107
	}
	*Set missing rtype to default (balanced)
	tempvar rtypetmp rtypeshort
	qui: gen `rtypetmp' = `rtype'
	qui: count if `touse0' & mi(`rtype')
	local N0mis_rtype = `r(N)'
	qui: count if `touse' & mi(`rtype')
	local Nmis_rtype = `r(N)'
	local Nexc_rtype = 0
	if `Nmis_rtype'>0 {
		if !`warnings' {
			di as err _n(1) "Warning(s):"
			local warnings = 1
		}
		di as err _col(3) "- Route type was set to " as input "'fast'" as err " for " as input "`Nmis_rtype'" as err `" observation`=cond(`Nmis_rtype'>1,"s","")' with missing value in "' as input "`rtype'" as err "."
	}
	qui: replace `rtypetmp' = "fast" if `touse' & mi(`rtype')
	qui: gen `rtypeshort' = "^" + `rtype'
	foreach rt in fast short {
		qui: replace `rtypetmp' = "`rt'" if regexm("`rt'",`rtypeshort')
	}
	drop `rtypeshort'
	*Check each level to verify it is in allowable list
	cap: levelsof `rtypetmp' if `touse', local(rtypes)
	foreach rt of local rtypes {
		if !inlist("`rt'","fast","short") {
			if !`warnings' {
				di as err _n(1) "Warning(s):"
				local warnings = 1
			}
			di as err _col(3) _c "- Route type " as input "`rt'" as err `" is not allowed (see also {browse "https://developer.here.com/documentation/routing/topics/transport-modes.html":HERE documentation} for details): fast, short."'
			qui: count if `touse' & `rtypetmp'=="`rt'"
			local Nexc_rtype = `r(N)'
			di as input "`Nexc_rtype'" as err `" observation`=cond(`Nexc_rtype'>1,"s","")' with "' as input "`rtype'==`rt'" as err " will be ignored."
			qui: replace `touse' = 0 if `rtypetmp'=="`rt'"
			cap: count if `touse'
			local N = r(N)
		}
	}
}


*** Parse departure time (dtime) ***
*If dtime is not specified, set it to default = 'now'
if "`dtime'"=="" | "`dtime'"=="now" {
	local dtimeapi: di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'","DMYhms")
	local dtimedisp: di %tcDD_Mon_CCYY_HH:MM:SS clock("`c(current_date)' `c(current_time)'","DMYhms")
	if "`dtime'"=="now" local dtimedefault " (now)"
	if "`dtime'"=="" local dtimedefault " (now; assigned by default)"
}
*Determine if dtime is hardcoded or variable
cap: confirm variable `dtime'
*If dtime is hardcoded
if _rc {
   	local dtimevar = 0
	if "`dtime'"!="" & "`dtime'"!="now" & "`dtime'"!="any" {
		tokenize "`dtime'", parse(",")
		local date = "`1'"
		local mask = "`3'"
		if "`date'"=="" | "`mask'"=="" | ("`2'"!="" & "`2'"!=",") | "`4'"!="" {
			di as err _n(1) "Departure time incorrectly specified."
			di as err `"Please use dtime(datetime, mask), with datetime and mask defined such as in {helpb clock()}."'
			exit 198
		}
		if clock("`date'","`mask'")==. {
			di as err _n(1) "Departure time incorrectly specified."
			di as err `"Please use dtime(datetime, mask), with datetime and mask defined such as in {helpb clock()}."'
			di as err "In particular, check that datetime and mask are consistent with eachother."
			exit 198
		}
		if `=dofc(clock("`date'","`mask'"))' < mdy(1,1,2020) {
			local dtimewarn = "Warning: It seems that historical traffic data is not available from HERE API before January 2020."
		}
		local dtimeapi: di %tcCCYY-NN-DD!THH:MM:SS clock("`date'","`mask'")
		local dtimedisp: di %tcDD_Mon_CCYY_HH:MM:SS clock("`date'","`mask'")
	}
	if "`dtime'"=="any" {
		local dtimeapi = "any"
		local dtimedisp = "any"
	}
}

*If dtime is a variable
else {
   	local dtimevar = 1
	*Check that dtime is in %tc or %tC format
	local dtimefmt: format `dtime'
	if !regexm("`dtimefmt'","^%tc") & !regexm("`dtimefmt'","^%tC") {
		di as err "The format of " as input "`dtime'" as err " must be %tc or %tC."
		exit 120
	}
	*Format dtime for API query
	tempvar dtimetmp
	if regexm("`dtimefmt'","^%tc")  {
		qui: gen `dtimetmp' = strofreal(`dtime', "%tcCCYY-NN-DD!THH:MM:SS") if !mi(`dtime')
	}
	if regexm("`dtimefmt'","^%tC")  {
		qui: gen `dtimetmp' = strofreal(`dtime', "%tCCCYY-NN-DD!THH:MM:SS") if !mi(`dtime')
	}
	*Set missing dtime to default (now)
	local now: di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'","DMYhms")
	qui: count if `touse0' & mi(`dtime')
	local N0mis_dtime = `r(N)'
	qui: count if `touse' & mi(`dtime')
	local Nmis_dtime = `r(N)'
	if `r(N)'>0 {
		if !`warnings' {
			di as err _n(1) "Warning(s):"
			local warnings = 1
		}
		di as err _col(3) "- Departure time was set to " as input "'now' (`now')" as err " for " as input "`r(N)'" as err `" observation`=cond(`r(N)'>1,"s","")' with missing value in "' as input "`dtime'" as err "."
	}
	qui: replace `dtimetmp' = "`now'" if `touse' & mi(`dtimetmp')
}


*** Parse routing features and their weights ***
*Default: none (unused)
local featuresapi ""
if "`avoid'"!="" {
    local featuresapi "&avoid[features]="
	local avoid_feat ""
	tokenize `=subinstr("`avoid'",",","",.)'
	local i = 1
	while "``i''"!="" {
		local found = 0
		local l = length("``i''")
		foreach f in tollRoad ferry tunnel dirtRoad {
			if regexm("`f'","^``i''") & `l'>=2 { // search for a match at the beginning of the string -> Routing features can be abbreviated to a minimum of 2 letters
				local found = 1
				if !regexm("`featuresapi'","`f'") { // If feature is already present, further apparitions are ignored
					local featuresapi `"`featuresapi'`f',"'
					local avoid_feat `"`avoid_feat'`f', "'
				}
			}
		}
		if !`found' {
			di as err _n(1) "The specified routing feature (" as input "``i''" as err ") in " as input "avoid() " as err `"is not allowed. Please use one of the following (see also {browse "https://developer.here.com/documentation/routing/dev_guide/topics/resource-param-type-routing-mode.html#type-routing-type":HERE documentation} for details):"'
			di as err _col(3) "- tollRoad"
			di as err _col(3) "- ferry"
			di as err _col(3) "- tunnel"
			di as err _col(3) "- dirtRoad"
			di as err "Routing features can be abbreviated to a minimum of 2 letters: 'to' for tollRoad, 'fe' for ferry, 'tu' for tunnel, 'di' for dirtRoad."
			exit 198
		}
		local ++i
	}
}
local featuresapi = regexr("`featuresapi'",",$","") // remove the last comma
local avoid_feat = regexr("``wtype'_feat'",", $",".") // replace the last comma by a point


*** Flag irrelevant combinations of attributes ***
*(Without stopping route calculation)
if `tmodevar' {
    *No warning if variables are used (too many possible combinations)...
}
if !`tmodevar' {
	if inlist("`tmode'","publicTransit","pedestrian","bicycle") {
		local rtype "(no impact with selected transport mode)"
		local rtypedefault ""
	}
	if inlist("`tmode'","pedestrian","bicycle") {
		local dtimedisp "(no impact with selected transport mode)"
		local dtimedefault ""
	}
	if inlist("`tmode'","publicTransit","pedestrian","bicycle") & "`avoid'"!="" {
		local avoid_feat "(no impact with selected transport mode)"
	}
}


*If specified, coordinates of start and end points must be specified in two numeric variables (x in [-90;90] and y in [-180;180])
foreach p in start end {
	if "``p'xy'"!="" {
		tokenize ``p'xy'
		if `"`2'"'=="" | `"`3'"'!="" {
			di as err "option `p'xy() incorrectly specified"
			exit 198
		}
		tempvar x y
		cap: gen `x' = `1'
		cap: gen `y' = `2'
		confirm numeric variable `x'
		confirm numeric variable `y'
		cap: assert inrange(`x',-90,90) | mi(`x') if `touse'
		if _rc {
			di as err "`x' (latitude) must be between -90 and 90"
			exit 198
		}
		cap: assert inrange(`y',-180,180) | mi(`y') if `touse'
		if _rc {
			di as err "`y' (longitude) must be between -180 and 180"
			exit 198
		}
		foreach c in x y {
			tempvar s`c' s`c'1 s`c'2 s`c'3 s`c'4 s`c'5 s`c'6
			qui: gen `s`c'1' = ``c'' if ``c''<=-100
			qui: gen `s`c'2' = ``c'' if ``c''>-100 & ``c''<=-10
			qui: gen `s`c'3' = ``c'' if ``c''>-10 & ``c''<0
			qui: gen `s`c'4' = ``c'' if ``c''>=0 & ``c''<10
			qui: gen `s`c'5' = ``c'' if ``c''>=10 & ``c''<100
			qui: gen `s`c'6' = ``c'' if ``c''>=100
			qui: gen `s`c'' = string(`s`c'1',"%020.15f") if !mi(`s`c'1')
			qui: replace `s`c'' = string(`s`c'2',"%019.15f") if !mi(`s`c'2')
			qui: replace `s`c'' = string(`s`c'3',"%018.15f") if !mi(`s`c'3')
			qui: replace `s`c'' = string(`s`c'4',"%017.15f") if !mi(`s`c'4')
			qui: replace `s`c'' = string(`s`c'5',"%018.15f") if !mi(`s`c'5')
			qui: replace `s`c'' = string(`s`c'6',"%019.15f") if !mi(`s`c'6')
		}
		tempvar `p'_xy
		qui: gen ``p'_xy' = `sx' + "," + `sy'
	}
}
*If specified, distance, time, coordinates, and diagnostic must be new variables (unless replace is also specified)
if "`distance'"=="" local distance = "travel_distance"
if "`distance'"!="" {
	tokenize `distance'
	if `"`2'"'!="" {
		di as err "option distance() incorrectly specified"
		exit 198
	}
}

if "`time'"=="" local time = "travel_time"
if "`time'"!="" {
	tokenize `time'
	if `"`2'"'!="" {
		di as err "option time() incorrectly specified"
		exit 198
	}
}

if "`diagnostic'"=="" local diagnostic = "georoute_diagnostic"
if "`diagnostic'"!="" {
	tokenize `diagnostic'
	if `"`2'"'!="" {
		di as err "option diagnostic() incorrectly specified"
		exit 198
	}
}

if `"`replace'"'=="replace" {
	cap: drop `distance'
	cap: drop `time'
	cap: drop `diagnostic'
}
confirm new var `distance'
confirm new var `time'
confirm new var `diagnostic'
qui: gen `distance' = .
qui: gen `time' = .
qui: gen `diagnostic' = .

if "`coordinates'"!="" {
	tokenize `coordinates'
	if `"`2'"'=="" | `"`3'"'!="" {
		di as err "option coordinates() incorrectly specified"
		exit 198
	}
	local start `1'
	local end `2'
	if `"`replace'"'=="replace" {
		if "`startxy'"=="" {
			cap: drop `start'_x
			cap: drop `start'_y
			cap: drop `start'_score
			confirm new var `start'_x `start'_y `start'_score
		}
		if "`endxy'"=="" {
			cap: drop `end'_x
			cap: drop `end'_y
			cap: drop `end'_score
			confirm new var `end'_x `end'_y `end'_score
		}
	}
	if "`startxy'"=="" {
		qui: gen `start'_x = ""
		qui: gen `start'_y = ""
		qui: gen `start'_score = ""
	}
	if "`endxy'"=="" {
		qui: gen `end'_x = ""
		qui: gen `end'_y = ""
		qui: gen `end'_score = ""
	}
	if ("`startxy'"!="" & "`endxy'"!="") {
		if !`warnings' {
			di as err _n(1) "Warning(s):"
			local warnings = 1
		}
	    noi: di as err _col(3) "- Specifying coordinates() without startaddress() or endaddress() is useless."
	}
}

if "`coordinates'"=="" {
	if "`startxy'"=="" {
		tempvar start_score
		qui: gen `start_score' = ""
	}
	if "`endxy'"=="" {
		tempvar end_score
		qui: gen `end_score' = ""
	}
}

*** Calculate travel distance and time ***

*Create temporary variables that will be used for insheetjson in following loop
tempvar tmp_x tmp_y tmp_scorelevel
qui: gen str240 `tmp_x' = ""
qui: gen str240 `tmp_y' = ""
qui: gen str240 `tmp_scorelevel' = ""
tempvar tmp_time tmp_distance
qui: gen str240 `tmp_distance' = ""
qui: gen str240 `tmp_time' = ""

local t 0
forv i = 1/`=_N' {
	if `touse'[`i'] {
		*Print a timer (option)
		if "`timer'"=="timer" {
			local ++t
			*Pause for 30 seconds every 100th geocoded observation
			if "`pause'"=="pause" & mod(`t',100)==0 sleep 30000
			if `t'==1 {
				di as txt _n(1) _dup(9) "-"
				di as txt "Geocoding"
				di as txt _dup(9) "-"
			}
			if int(`t'/(`N'/10))>int((`t'-1)/(`N'/10)) di _continue as res " `=int(`t'/(`N'/10))*10'% "
			if int(`t'/(`N'/100))>int((`t'-1)/(`N'/100)) & int(`t'/(`N'/10))==int((`t'-1)/(`N'/10)) di _continue as res "."
			if `=int(`t'/(`N'/10))*10'==100 di ""
		}

		if `tmodevar' local tmodeapi = `tmodetmp'[`i']
		if !`tmodevar' local tmodeapi = "`tmode'"
		
		if `rtypevar' local rtypeapi = `rtypetmp'[`i']
		if !`rtypevar' local rtypeapi = "`rtype'"
		
		if `dtimevar' local dtimeapi = `dtimetmp'[`i']
		if !`dtimevar' local dtimeapi = "`dtimeapi'"

		*Prepare url links
		*local xy_url = "https://geocoder.ls.hereapi.com/6.2/geocode.json?responseattributes=matchCode&searchtext=" // developer
		local xy_url = "https://geocode.search.hereapi.com/v1/geocode?q=" // platform
		local here_key = "&apiKey=`herekey'"
		local route_url = "https://router.hereapi.com/v8/routes?apiKey=`herekey'"
		local heresummary = "summary"
		if inlist("`tmodeapi'","publicTransit") {
			local route_url = "https://transit.router.hereapi.com/v8/routes?apiKey=`herekey'"
			local heresummary = "travelSummary"
		}
		
		*Addresses to xy-coordinates (only if addresses are provided, skipped if xy-coordinates are provided)
		foreach p in start end {
			if "``p'address'"!="" /*& !mi(``p'_address'[`i'])*/ {

				local coords = ``p'_address'[`i']
				local xy_request = "`xy_url'" + geturi("`coords'") + "`here_key'"
				#d ;
				qui: insheetjson `tmp_x' `tmp_y' `tmp_scorelevel' using "`xy_request'", 
					/*
					columns("Response:View:1:Result:1:Location:DisplayPosition:Latitude" 
							"Response:View:1:Result:1:Location:DisplayPosition:Longitude" 
							"Response:View:1:Result:1:MatchCode"
							) // developer
					*/
					columns("items:1:position:lat" 
							"items:1:position:lng"
							"items:1:scoring:queryScore"
					) // platform
					flatten replace
				;
				#d cr

				local `p'_coord = `tmp_x'[1] + "," + `tmp_y'[1]
				if "`coordinates'"!="" & "``p'xy'"=="" {
					qui: replace ``p''_x = `tmp_x'[1] in `i'
					qui: replace ``p''_y = `tmp_y'[1] in `i'
					qui: replace ``p''_score = `tmp_scorelevel'[1] in `i'
				}
				if "`coordinates'"=="" & "``p'xy'"=="" {											
					qui: replace ``p'_score' = `tmp_scorelevel'[1] in `i'
				}
				*Empty temporary variables before next loop
				qui: replace `tmp_x' = ""
				qui: replace `tmp_y' = ""
				qui: replace `tmp_scorelevel' = ""
			}
			if "``p'xy'"!="" {
				local `p'_coord = ``p'_xy'[`i']
			}
		}
		*xy-coordinates to distance
		if "`start_coord'"!="," & "`end_coord'"!="," {

			local s = "`start_coord'"
			local e = "`end_coord'"

			if inlist("`tmodeapi'","car") {
			    local route_request = "`route_url'" + "&origin=" + "`s'" + "&destination=" + "`e'" + "&transportMode=`tmodeapi'&routingMode=`rtypeapi'`featuresapi'&return=summary&departureTime=`dtimeapi'"
			}
			if inlist("`tmodeapi'","pedestrian","bicycle") {
				local route_request = "`route_url'" + "&origin=" + "`s'" + "&destination=" + "`e'" + "&transportMode=`tmodeapi'&return=summary"
			}
			if inlist("`tmodeapi'","publicTransit") {
				local route_request = "`route_url'" + "&origin=" + "`s'" + "&destination=" + "`e'" + "&return=travelSummary&departureTime=`dtimeapi'"
			}

			local tmpd = 0
			local tmpt = 0
			local j = 0
			while `tmp_distance'[1]!="[]" { // iterate until the last section of the route
				local ++j
				#d ;
				qui: insheetjson `tmp_distance' `tmp_time' using "`route_request'", 
					columns("routes:1:sections:`j':`heresummary':length" 
							"routes:1:sections:`j':`heresummary':duration"
					) 
					flatten replace
				;
				#d cr
				if `tmp_distance'[1]!="[]" {
					if "`km'"=="" local tmpd = `tmpd' + real(`tmp_distance'[1])/1609.344
					if "`km'"=="km" local tmpd = `tmpd' + real(`tmp_distance'[1])/1000
					local tmpt = `tmpt' + real(`tmp_time'[1])/60
				}
				if `tmp_distance'[1]=="" {
					local tmpd = .
					local tmpt = .
					qui: replace `tmp_distance' = "[]" in 1
				}
			}
			qui: replace `distance' = `tmpd' in `i'
			qui: replace `time' = `tmpt' in `i'
		}
		*Empty temporary variables before next loop
		qui: replace `tmp_distance' = ""
		qui: replace `tmp_time' = ""
	}
}

*** Label the variables ***
la var `distance' "Travel distance (`=cond("`km'"=="km","km","mi")')"
la var `time' "Travel time (minutes)"
if "`coordinates'"!="" {
	foreach p in start end {
		if "``p'address'"!="" {
			qui: destring ``p''_x, replace
			la var ``p''_x "x-coordinate of `=cond("`p'"=="start","starting","ending")' address"
			qui: destring ``p''_y, replace
			la var ``p''_y "y-coordinate of `=cond("`p'"=="start","starting","ending")' address"
			/*
			la var ``p''_match "Match code for `=cond("`p'"=="start","starting","ending")' address"
			qui: replace ``p''_match = "1" if ``p''_match=="exact"
			qui: replace ``p''_match = "2" if ``p''_match=="ambiguous"
			qui: replace ``p''_match = "3" if ``p''_match=="upHierarchy"
			qui: replace ``p''_match = "4" if ``p''_match=="ambiguousUpHierarchy"
			qui: destring ``p''_match, replace
			cap: la drop matchcode
			la def matchcode 1 "exact" 2 "ambiguous" 3 "upHierarchy" 4 "ambiguousUpHierarchy"
			la val ``p''_match matchcode
			*/
			la var ``p''_score "Query score [0-1] for `=cond("`p'"=="start","starting","ending")' address"
		}
	}
}

la var `diagnostic' "Diagnostic code (georoute)"
qui: replace `diagnostic' = 0 if !mi(`distance')
if "`coordinates'"=="" {
	if "`startaddress'"!="" & "`endaddress'"!="" {
		qui: replace `diagnostic' = 1 if mi(`distance') & !mi(`start_score') & !mi(`end_score')
		qui: replace `diagnostic' = 2 if mi(`distance') & (mi(`start_score') | mi(`end_score'))
	}
	if "`startxy'"!="" & "`endaddress'"!="" {
		qui: replace `diagnostic' = 1 if mi(`distance') & `start_xy'!="," & !mi(`end_score')
		qui: replace `diagnostic' = 2 if mi(`distance') & mi(`end_score')
	}
	if "`startaddress'"!="" & "`endxy'"!="" {
		qui: replace `diagnostic' = 1 if mi(`distance') & !mi(`start_score') & `end_xy'!=","
		qui: replace `diagnostic' = 2 if mi(`distance') & mi(`start_score')
	}
}
if "`coordinates'"!="" {
	if "`startaddress'"!="" & "`endaddress'"!="" {
		qui: replace `diagnostic' = 1 if mi(`distance') & !mi(`start'_score) & !mi(`end'_score)
		qui: replace `diagnostic' = 2 if mi(`distance') & (mi(`start'_score) | mi(`end'_score))
	}
	if "`startxy'"!="" & "`endaddress'"!="" {
		qui: replace `diagnostic' = 1 if mi(`distance') & `start_xy'!="," & !mi(`end'_score)
		qui: replace `diagnostic' = 2 if mi(`distance') & mi(`end'_score)
	}
	if "`startaddress'"!="" & "`endxy'"!="" {
		qui: replace `diagnostic' = 1 if mi(`distance') & !mi(`start'_score) & `end_xy'!=","
		qui: replace `diagnostic' = 2 if mi(`distance') & mi(`start'_score)
	}
}
if "`startxy'"!="" & "`endxy'"!="" {
	qui: replace `diagnostic' = 1 if mi(`distance') & `start_xy'!="," & `end_xy'!=","
	qui: replace `diagnostic' = 3 if mi(`distance') & (`start_xy'=="," | `end_xy'==",")
}
qui: replace `diagnostic' = 4 if !`touse'

cap: la drop diagnosticlab
la def diagnosticlab 0 "OK" 1 "No route found" 2 "Start and/or end not geocoded" 3 "Start and/or end coordinates missing" 4 "No route searched"
la val `diagnostic' diagnosticlab


*** Print summary of settings ***
if "`nosettings'"!="nosettings" {
	qui: count if `diagnostic'==0
	di as input _n(1) "georoute has successfully calculated travel distance and travel time for " as res "`r(N)'" as input " observations based on the following settings:"
	di as input "{hline}"
	if "`startaddress'"!="" di as input "Start:" _col(12) "addresses in " as res "`startaddress'" as input " (variable)"
	if "`startxy'"!="" di as input "Start:" _col(12) "coordinates in " as res "`startxy'" as input " (variables)"
	if "`endaddress'"!="" di as input "End:" _col(12) "addresses in " as res "`endaddress'" as input " (variable)"
	if "`endxy'"!="" di as input "End:" _col(12) "coordinates in " as res "`endxy'" as input " (variables)"
	if `tmodevar' di as input "Mode:" _col(12) "transport modes in " as res "`tmode'" as input " (variable)"
	if !`tmodevar' di as input "Mode:" _col(12) as res "`tmode'`tmodedefault'" as input " for all observations (hard coded)"
	if `rtypevar' di as input "Route:" _col(12) "as indicated in " as res "`rtype'" as input " (variable)"
	if !`rtypevar' di as input "Route:" _col(12) as res "`rtype'`rtypedefault'" as input " for all observations (hard coded)"
	if `dtimevar' di as input "Departure:" _col(12) "times in " as res "`dtime'" as input " (variable)"
	if !`dtimevar' di as input "Departure:" _col(12) as res "`dtimedisp'`dtimedefault'" as input " for all observations (hard coded)"
	if "`dtimewarn'"!="" di as err _col(12) "`dtimewarn'"
	if "`avoid_feat'"!="" di as input "Avoid:" _col(12) as res "`avoid_feat'"
	di as input "{hline}"
}
*Optional: print detailed observation account
if "`observations'"=="observations" {
	di as input _n(1) "Detailed observation account:"
	di as input "{hline}"
	qui: count
	di as input "Total in database:" _col(40) as res as res %6.0g `r(N)'
	di as input "Total after if/in condition(s):" _col(40) as res as res %6.0g `N0'
	foreach opt in tmode rtype {
	    if "`opt'"=="tmode" local def car
		if "`opt'"=="rtype" local def fast
		if ``opt'var' {
			if `N0mis_`opt''>0 di as input "Missing " as res "``opt''" as input ":" _col(40) as res %6.0g `=`N0mis_`opt''' _col(50) "(set to default '`def'')"
			if `Nexc_`opt''>0 di as input "Unknown " as res "``opt''" as input ":" _col(40) as res %6.0g `=`Nexc_`opt''' _col(50) "(excluded)"
		}
	}
	if `dtimevar' {
	    if `N0mis_dtime'>0 di as input "Missing " as res "``dtime''" as input ":" _col(40) as res %6.0g `=`N0mis_dtime'' _col(50) "(set to default 'now': `now')"
	}
	di as input "Considered for geocoding:" _col(40) as res as res %6.0g `N'
	qui: count if `diagnostic'==0
	di as input "Successfully coded:" _col(40) as res as res %6.0g `r(N)'
	di as input "{hline}"
}
end