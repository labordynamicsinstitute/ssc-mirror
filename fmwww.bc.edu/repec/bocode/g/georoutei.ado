**************************************************
** Sylvain Weber, Martin Péclat & August Warren **
**         This version: June 18, 2024          **
**************************************************

*! version 4.2 by Sylvain Weber, Martin Péclat & August Warren 18jun2024
/*
Revision history:
- version 1.1 (2nov2016):
	- Minor changes: miles obtained as 1.609344*km instead of 1.6093, unused temporary variables 
	  dropped, url links created outside the loop and renamed.
- version 2.0 (24feb2017):
	- Check if HERE account is valid
	- cit in route_url if !herepaid
	- Return diagnostic if distance cannot be returned
- version 2.1 (20sep2017):
	- Correction of a bug causing an error (no geocoding) if blank spaces were 
	  inserted between x,y coordinates in startxy() or endxy()
- version 2.2 (20oct2017):
	- Correction of a bug causing an error (no geocoding) if x,y coordinates 
	  in startxy() or endxy() were below 1 (in absolute value) and inserted
	  without leading 0.
- No versions 2.3-2.4, but next revision numbered 2.5 to be in line with georoute
- version 2.5 (30jan2020):
	- Because of a change in HERE accounts, APP ID and APP CODE cannot be created 
	  anymore. From now on, only accounts with API KEY can be created. A new option 
	  "herekey(API KEY)" is added and can be used instead of "hereid(APP ID) herecode(APP CODE)".
- version 3.0 (30jul2020)
	- Complete revision: many HERE features implemented as options + miscellanous improvements
- version 3.1 (02nov2020)
	- Creation of local `p'xy on line 367 without function string() which was causing an error
	  in case the content did not exist.
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
- version 4.2 (18jun2024)
	- Integration of possibility to use "any" in dtime to specify a route without a specific departure time
*/


program georoutei, rclass
version 10.0


*** Syntax ***
#d ;
syntax, 
		herekey(string)
	[
		STARTADdress(string) startxy(string) 
		ENDADdress(string) endxy(string) 
		TMode(string)
		RType(string)
		DTime(string)
		AVoid(string)
		km
		herepaid
		NOSETtings
	]
;
#d cr


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
	else {
	di as err `"There seems to be an issue with the credentials of your HERE application: {browse "https://developer.here.com"}."'
		exit 198
	}
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

*If specified, coordinates of start and end points must be provided as two numbers (x in [-90;90] and y in [-180;180]) separated by a comma
foreach p in start end {
	if "``p'xy'"!="" {
		if strpos("``p'xy'",",")==0 | strpos("``p'xy'",",")!=strrpos("``p'xy'",",") { // there is no comma or several
			di as err "option `p'xy() incorrectly specified"
			exit 198
		}
		local commapos = strpos("``p'xy'",",")-1
		local `p'x = substr("``p'xy'",1,`commapos')
		local `p'x = subinstr("``p'x'"," ","",.)
		if abs(``p'x')<1 {
			local dotpos = strpos("``p'x'",".")+1
			local l = length(substr("``p'x'",`dotpos',.))
			local `p'x: di %0`=`l'+2'.`l'f ``p'x'
		}
		cap: confirm number ``p'x'
		if _rc {
			di as err "option `p'xy() incorrectly specified"
			exit 198
		}
		local commapos = strpos("``p'xy'",",")+1
		local `p'y = substr("``p'xy'",`commapos',.)
		local `p'y = subinstr("``p'y'"," ","",.)
		if abs(``p'y')<1 {
			local dotpos = strpos("``p'y'",".")+1
			local l = length(substr("``p'y'",`dotpos',.))
			local `p'y: di %0`=`l'+2'.`l'f ``p'y'
		}
		cap: confirm number ``p'y'
		if _rc {
			di as err "option `p'xy() incorrectly specified"
			exit 198
		}
		if !inrange(``p'x',-90,90) {
			di as err "Latitudes must be between -90 and 90"
			exit 198
		}
		if !inrange(``p'y',-180,180) {
			di as err "Longitudes must be between -180 and 180"
			exit 198
		}
		*Re-construct xy coordinates:
		local `p'xy = `"``p'x',``p'y'"'
	}
}


*** Parse transport mode (tmode) ***
*Default: 'car'
if "`tmode'"=="" {
	local tmode = "car"
	local tmodedefault = "(assigned by default)"
}
if !inlist("`tmode'","car","publicTransit","pedestrian","bicycle") {
	di as err _n(1) "The specified transport mode (" as input "`tmode'" as err `") is not allowed. Please use one of the following (see also {browse "https://developer.here.com/documentation/routing/topics/transport-modes.html":HERE documentation} for details):"'
	di as err _col(3) "- car"
	di as err _col(3) "- publicTransit"
	di as err _col(3) "- pedestrian"
	di as err _col(3) "- bicycle"
	exit 198
}


*** Parse route type (rtype) ***
*Default: 'fast'
if "`rtype'"=="" {
	local rtype = "fast"
	local rtypedefault = "(assigned by default)"
}
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


*** Parse departure time (dtime) ***
*Default: 'now'
if "`dtime'"=="" | "`dtime'"=="now" {
	local dtimeapi: di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'","DMYhms")
	local dtimedisp: di %tcDD_Mon_CCYY_HH:MM:SS clock("`c(current_date)' `c(current_time)'","DMYhms")
	if "`dtime'"=="now" local dtimedefault = "(now)"
	if "`dtime'"=="" local dtimedefault = "(now; assigned by default)"
}
if "`dtime'"!="" & "`dtime'"!="now" & "`dtime'"!="any" {
	tokenize "`dtime'", parse(",")
	local date = "`1'"
	local mask = "`3'"
	if "`date'"=="" | "`mask'"=="" | ("`2'"!="" & "`2'"!=",") | "`4'"!="" {
		di as err `"Please use dtime(datetime, mask), with datetime and mask defined such as in {helpb clock()}."'
		di as err _n(1) "Departure time incorrectly specified."
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

*** Parse routing features (avoid) ***
*Default: none (unused)
local featuresapi ""
if "`avoid'"!="" {
    local featuresapi "&avoid[features]="
	local avoid_feat ""
	tokenize `=subinstr("`avoid'",","," ",.)'
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
			di as err _n(1) "The specified routing feature (" as input "``i''" as err ") in " as input "avoid() " as err `"is not in allowed. Please use one of the following (see also {browse "https://developer.here.com/documentation/routing/dev_guide/topics/resource-param-type-routing-mode.html#type-routing-type":HERE documentation} for details):"'
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
local avoid_feat = regexr("`avoid_feat'",", $",".") // replace the last comma by a point


*** Flag irrelevant combinations of attributes ***
*(Without stopping route calculation)
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


*** Calculate travel distance and time ***
*Prepare url links
*local xy_url = "https://geocoder.ls.hereapi.com/6.2/geocode.json?responseattributes=matchCode&searchtext=" // developer
local xy_url = "https://geocode.search.hereapi.com/v1/geocode?q=" // platform
local here_key = "&apiKey=`herekey'"

*Addresses to xy-coordinates (only if addresses are provided, skipped if xy-coordinates are provided)
foreach p in start end {
	if "``p'address'"!="" {
		tempvar tmp_x tmp_y
		qui: gen str240 `tmp_x' = ""
		qui: gen str240 `tmp_y' = ""

		local coords = "``p'address'"
		local xy_request = "`xy_url'" + geturi("`coords'") + "`here_key'"
		#d ;
		qui: insheetjson `tmp_x' `tmp_y' using "`xy_request'", 
			/* 
			columns("Response:View:1:Result:1:Location:DisplayPosition:Latitude" 
					"Response:View:1:Result:1:Location:DisplayPosition:Longitude"
			) // developer
			*/
			columns("items:1:position:lat" 
					"items:1:position:lng"
			) // platform
			flatten replace
		;
		#d cr

		local `p'x = `tmp_x'[1]
		local `p'y = `tmp_y'[1]
		local `p'xy = "``p'x',``p'y'"
	}
}

*xy-coordinates to distance
tempvar tmp_time tmp_distance
qui: gen str240 `tmp_distance' = ""
qui: gen str240 `tmp_time' = ""
local s = "`startxy'"
local e = "`endxy'"

local route_url = "https://router.hereapi.com/v8/routes?apiKey=`herekey'"
local heresummary = "summary"
if inlist("`tmode'","publicTransit") {
	local route_url = "https://transit.router.hereapi.com/v8/routes?apiKey=`herekey'"
	local heresummary = "travelSummary"
}

if inlist("`tmode'","car") { 
	local route_request = "`route_url'" + "&origin=" + "`s'" + "&destination=" + "`e'" + "&transportMode=`tmode'&routingMode=`rtype'`featuresapi'&return=summary&departureTime=`dtimeapi'"
}
if inlist("`tmode'","pedestrian","bicycle") {
	local route_request = "`route_url'" + "&origin=" + "`s'" + "&destination=" + "`e'" + "&transportMode=`tmode'&return=summary"
}
if inlist("`tmode'","publicTransit") {
	local route_request = "`route_url'" + "&origin=" + "`s'" + "&destination=" + "`e'" + "&return=travelSummary&departureTime=`dtimeapi'"
}

local tmpd = 0
local tmpt = 0
local i = 0
while `tmp_distance'[1]!="[]" { // iterate until the last section of the route
	local ++i
	#d ;
	qui: insheetjson `tmp_distance' `tmp_time' using "`route_request'", 
		columns(
			"routes:1:sections:`i':`heresummary':length"
			"routes:1:sections:`i':`heresummary':duration" 
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
local distance: di %8.2f `tmpd'
local time: di %8.2f `tmpt'


*** Print inputs and outputs ***
*Print inputs
if "`nosettings'"!="nosettings" {
	di as input _n(1) "SETTINGS"
	di as input "{hline}"
	di as input "Start:" _col(12) as res cond(`"`startaddress'"'!="",`"`startaddress' (`startxy')"',"(`startxy')")
	di as input "End:" _col(12) as res cond("`endaddress'"!="","`endaddress' (`endxy')","(`endxy')")
	di as input "Mode:" _col(12) as res "`tmode' `tmodedefault'"
	di as input "Route:" _col(12) as res "`rtype' `rtypedefault'"
	if "`dtimedisp'"!="" di as input "Departure:" _col(12) as res "`dtimedisp' `dtimedefault'" 
	if "`dtimewarn'"!="" di as err _col(12) "`dtimewarn'"
	if "`avoid_feat'"!="" di as input "Avoid:" _col(12) as res "`avoid_feat'"
	di as input "{hline}"
}
*Print and save outputs
if `distance'!=. {
	di _n(1) as input "ROUTE CALCULATED"
	di as input "{hline}"
	di as input "Travel distance:" _col(20) as res "`distance' `=cond("`km'"=="km","kilometers","miles")'"
	di as input "Travel time:" _col(20) as res "`time' minutes"
	di as input "{hline}"

	return scalar endy = `endy'
	return scalar endx = `endx'
	return scalar starty = `starty'
	return scalar startx = `startx'
	return scalar time = `time'
	return scalar dist = `distance'
}
*Print error message and likely reason if not route calculated
if `distance'==. {
	di as err "Impossible to calculate a routing distance:"
	if "`startaddress'"!="" & "`startxy'"=="," {
		di as err _col(3) `"- "`startaddress'" could not be geocoded."'
	}
	if "`endaddress'"!="" & "`endxy'"=="," {
		di as err _col(3) `"- `endaddress' could not be geocoded."'
	}
	if "`startxy'"!="," & "`endxy'"!="," {
		di as err _col(3) `"- Check that the two addresses/geographical points you provided can actually be linked by road."'
		if "`tmode'"=="bicycle" {
			di as err _col(3) `"- Note also that the 'bicycle' mode is in beta mode. In case bicycle road cannot be calculated, try the 'pedestrian' mode instead. Travel distance should be close in both cases and travel time could be adjusted."'
		}
	}
}

end