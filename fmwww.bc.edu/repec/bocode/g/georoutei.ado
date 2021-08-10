**************************************************
** Martin Péclat, August Warren & Sylvain Weber **
**         This version: March 25, 2021         **
**************************************************

*! version 3.2 by Martin Péclat, August Warren & Sylvain Weber 25mar2021
/*
Revision history:
- version 1.1 (2nov2016):
	- Minor changes: miles obtained as 1.609344*km instead of 1.6093, unused temporary variables 
	  dropped, url links created outside the loop and renamed.
- version 2.0 (24feb2017):
	- Check if HERE account is valid
	- cit in route_url if !herepaid
	- Return diagnostic if distance cannot be returned
-version 2.1 (20sep2017):
	- Correction of a bug causing an error (no geocoding) if blank spaces were 
	  inserted between x,y coordinates in startxy() or endxy()
-version 2.2 (20oct2017):
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
*/


program georoutei, rclass
version 10.0


*** Syntax ***
#d ;
syntax, 
	[
		herekey(string) hereid(string) herecode(string)
		STARTADdress(string) startxy(string) 
		ENDADdress(string) endxy(string) 
		TMode(string)
		RType(string)
		TRAFfic(string)
		DTime(string)
		AVoid(string)
		SOFTexclude(string)
		STRICTexclude(string)
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

*HERE credentials must be specified either with API KEY (alone) or with both APP ID and APP CODE
if "`herekey'"=="" & ("`hereid'"=="" & "`herecode'"=="") {
	di as err "herekey() is compulsory. It provides the credentials of the HERE application to be used."
	exit 198
}
if "`herekey'"!="" & !("`hereid'"=="" & "`herecode'"=="") {
	di as err "If you are using a HERE application created before December 2019, the application credentials can be indicated either with herekey() alone, or with both hereid() and herecode()."
	exit 198
}
if ("`hereid'"!="" & "`herecode'"=="") | ("`hereid'"=="" & "`herecode'"!="") {
	di as err "If you are using a HERE application created before December 2019, the application credentials can be indicated either with herekey() alone, or with both hereid() and herecode()."
	exit 198
}

*HERE credentials must be valid and internet connection is required
*Check HERE credentials using a (wrong) query
if "`herekey'"!="" {
	local here_check = "https://geocoder.ls.hereapi.com/6.2/geocode.json?searchtext=outofearth&apiKey=`herekey'"
}
if ("`hereid'"!="" & "`herecode'"!="") {
	local here_check = "http://geocoder.cit.api.here.com/6.2/geocode.json?searchtext=outofearth&app_id=`hereid'&app_code=`herecode'"
	if ("`herepaid'"=="herepaid") local here_check = "http://geocoder.api.here.com/6.2/geocode.json?searchtext=outofearth&app_id=`hereid'&app_code=`herecode'"
}
tempvar checkok 
qui: gen str240 `checkok' = ""
qui: insheetjson `checkok' using "`here_check'", columns("Response:MetaInfo:Timestamp") flatten replace
if `checkok'[1]=="" {
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
if !inlist("`tmode'","car","pedestrian","carHOV","publicTransport","publicTransportTimeTable","truck","bicycle") {
	di as err _n(1) "The specified transport mode (" as input "`tmode'" as err `") is not in allowable list. Please use one of the following (see the {browse "https://developer.here.com/documentation/routing/topics/transport-modes.html":HERE documentation}):"'
	di as err _col(3) "- car"
	di as err _col(3) "- pedestrian"
	di as err _col(3) "- carHOV"
	di as err _col(3) "- publicTransport"
	di as err _col(3) "- publicTransportTimeTable"
	di as err _col(3) "- truck"
	di as err _col(3) "- bicycle"
	exit 198
}


*** Parse route type (rtype) ***
*Default: 'balanced'
if "`rtype'"=="" {
	local rtype = "balanced"
	local rtypedefault = "(assigned by default)"
}
foreach rt in fastest shortest balanced {
	if regexm("`rt'","^`rtype'") { // search for a match at the beginning of the string -> Route types can be abbreviated to a minimum of 1 letter
		local rtype = "`rt'"
	}
}
if !inlist("`rtype'","fastest","shortest","balanced") {
	di as err _n(1) "The specified routing type (" as input "`rtype'" as err `") is not in allowable list. Please use one of the following (see the {browse "https://developer.here.com/documentation/routing/dev_guide/topics/resource-param-type-routing-mode.html#type-routing-type":HERE documentation}):"'
	di as err _col(3) "- fastest"
	di as err _col(3) "- shortest"
	di as err _col(3) "- balanced"
	di as err "Routing types can be abbreviated to a minimum of 1 letter: 'f' for fastest, 's' for shortest, 'b' for balanced."
	exit 198
}


*** Parse traffic mode (traffic) ***
*Default: 'default'
if "`traffic'"=="" {
	local traffic = "default"
	local trafficdefault = "(assigned by default)"
}
foreach tr in enabled disabled default {
	if regexm("`tr'","^`traffic'") & length("`traffic'")>=2 { // search for a match at the beginning of the string -> Route types can be abbreviated to a minimum of 2 letters
		local traffic = "`tr'"
	}
}
if !inlist("`traffic'","enabled","disabled","default") {
	di as err _n(1) "The specified traffic mode (" as input "`traffic'" as err `") is not in allowable list. Please use one of the following (see the {browse "https://developer.here.com/documentation/routing/dev_guide/topics/resource-param-type-routing-mode.html#type-traffic-mode":HERE documentation}):"'
	di as err _col(3) "- enabled"
	di as err _col(3) "- disabled"
	di as err _col(3) "- default"
	di as err "Traffic modes can be abbreviated to a minimum of 2 letters: 'en' for enabled, 'di' for disabled, 'de' for default."
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
if "`dtime'"!="" & "`dtime'"!="now" {
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


*** Parse routing features and their weights ***
*Default: none (unused)

local featuresapi ""
local avoid_w = -1
local softexclude_w = -2
local strictexclude_w = -3

foreach wtype in strictexclude softexclude avoid { // in order of decreasing importance; in case the same feature is specified with several weights, only the first is considered
	if "``wtype''"!="" {
		local `wtype'_disp ""
		local `wtype'_feat ""
		tokenize `=subinstr("``wtype''",",","",.)'
		local i = 1
		while "``i''"!="" {
			local found = 0
			local l = length("``i''")
			foreach f in tollroad motorway boatFerry railFerry tunnel dirtRoad park {
				if regexm("`f'","^``i''") & `l'>=2 { // search for a match at the beginning of the string -> Routing features can be abbreviated to a minimum of 2 letters
					local found = 1
					if !regexm("`featuresapi'","`f'") { // If feature is already present, further apparitions are ignored
						local featuresapi `"`featuresapi'`f':``wtype'_w',"'
						if "``wtype'_disp'"=="" {
							if "`wtype'"=="avoid" local `wtype'_disp "Avoid: "
							if "`wtype'"=="softexclude" local `wtype'_disp "Softly exclude: "
							if "`wtype'"=="strictexclude" local `wtype'_disp "Strictly exclude: "
						}
						local `wtype'_feat `"``wtype'_feat' `f',"'
					}
				}
			}
			if !`found' {
				di as err _n(1) "The specified routing feature (" as input "``i''" as err ") in " as input "`wtype'() " as err `"is not in allowable list. Please use one of the following (see the {browse "https://developer.here.com/documentation/routing/dev_guide/topics/resource-param-type-routing-mode.html#type-routing-type":HERE documentation}):"'
				di as err _col(3) "- tollroad"
				di as err _col(3) "- motorway"
				di as err _col(3) "- boatFerry"
				di as err _col(3) "- railFerry"
				di as err _col(3) "- tunnel"
				di as err _col(3) "- dirtRoad"
				di as err _col(3) "- park"
				di as err "Routing features can be abbreviated to a minimum of 2 letters: 'to' for tollroad, 'mo' for motorway, 'bo' for boatFerry, 'ra' for railFerry, 'tu' for tunnel, 'di' for dirtRoad, 'pa' for park."
				exit 198
			}
			local ++i
		}
	}
	local `wtype'_feat = regexr("``wtype'_feat'",",$",".") // replace the last comma by a point
}
local featuresapi = regexr("`featuresapi'",",$","") // remove the last comma


*** Flag irrelevant combinations of attributes ***
*(Without stopping route calculation)
if inlist("`tmode'","pedestrian","bicycle") {
	local traffic "(no impact with selected transport mode)"
	local trafficdefault ""
	local dtimedisp "(no impact with selected transport mode)"
	local dtimedefault ""
}
if regexm("`featuresapi'","park") & !inlist("`tmode'","pedestrian","bicycle") {
	local featureswarn "Warning: 'park' has no impact with selected transport mode."
}


*** Calculate travel distance and time ***
*Prepare url links
if "`herekey'"!="" {
	local xy_url = "https://geocoder.ls.hereapi.com/6.2/geocode.json?responseattributes=matchCode&searchtext="
	local here_key = "&apiKey=`herekey'"
}
if ("`hereid'"!="" & "`herecode'"!="") {
	local xy_url = "http://geocoder.cit.api.here.com/6.2/geocode.json?responseattributes=matchCode&searchtext="
	if ("`herepaid'"=="herepaid") local xy_url = "http://geocoder.api.here.com/6.2/geocode.json?responseattributes=matchCode&searchtext="
	local here_key = "&app_id=" + "`hereid'" + "&app_code=" + "`herecode'"
}

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
			columns("Response:View:1:Result:1:Location:DisplayPosition:Latitude" 
					"Response:View:1:Result:1:Location:DisplayPosition:Longitude"
			) 
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
if "`herekey'"!="" {
	local route_url = "https://route.ls.hereapi.com/routing/7.2/calculateroute.json?apiKey=`herekey'"
}
if ("`hereid'"!="" & "`herecode'"!="") {
	local route_url = "http://route.cit.api.here.com/routing/7.2/calculateroute.json?app_id=" + "`hereid'" + "&app_code=" + "`herecode'"
	if ("`herepaid'"=="herepaid") local route_url = "http://route.api.here.com/routing/7.2/calculateroute.json?app_id=" + "`hereid'" + "&app_code=" + "`herecode'"
}
if inlist("`tmode'","car","carHOV","truck","publicTransport","publicTransportTimeTable") { 
	local route_request = "`route_url'" + "&waypoint0=geo!" + "`s'" + "&waypoint1=geo!" + "`e'" +"&mode=`rtype';`tmode';traffic:`traffic';`featuresapi'&representation=overview&departure=`dtimeapi'"
}
if inlist("`tmode'","pedestrian","bicycle") { 
	local route_request = "`route_url'" + "&waypoint0=geo!" + "`s'" + "&waypoint1=geo!" + "`e'" +"&mode=`rtype';`tmode';&representation=overview&departure=`dtimeapi'"
}

#d ;
qui: insheetjson `tmp_distance' `tmp_time' using "`route_request'", 
	columns("response:route:1:summary:distance" 
			"response:route:1:summary:travelTime"
	) 
	flatten replace
;
#d cr
if "`km'"=="" {
	local distance: di %8.2f real(`tmp_distance'[1])/1609.344
}
if "`km'"=="km" {
	local distance: di %8.2f real(`tmp_distance'[1])/1000
}
local time: di %8.2f (1/60)*real(`tmp_time'[1])


*** Print inputs and outputs ***
*Print inputs
if "`nosettings'"!="nosettings" {
	di as input _n(1) "SETTINGS"
	di as input "{hline}"
	di as input "Start:" _col(12) as res cond(`"`startaddress'"'!="",`"`startaddress' (`startxy')"',"(`startxy')")
	di as input "End:" _col(12) as res cond("`endaddress'"!="","`endaddress' (`endxy')","(`endxy')")
	di as input "Mode:" _col(12) as res "`tmode' `tmodedefault'"
	di as input "Route:" _col(12) as res "`rtype' `rtypedefault'"
	di as input "Traffic:" _col(12) as res "`traffic' `trafficdefault'"
	di as input "Departure:" _col(12) as res "`dtimedisp' `dtimedefault'" 
	if "`dtimewarn'"!="" di as err _col(12) "`dtimewarn'"
	if "`avoid_disp'"!="" | "`softexclude_disp'"!="" | "`strictexclude_disp'"!="" {
		di as input "Restrictions:"
		if "`avoid_disp'"!="" di as input _col(12) "- `avoid_disp'" as res "`avoid_feat'"
		if "`softexclude_disp'"!="" di as input _col(12) "- `softexclude_disp'" as res "`softexclude_feat'"
		if "`strictexclude_disp'"!="" di as input _col(12) "- `strictexclude_disp'" as res "`strictexclude_feat'"
		if "`featureswarn'"!="" di as err _col(12) "`featureswarn'"
	}
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
		if "`tmode'"=="publicTransportTimeTable" {
			di as err _col(3) `"- Note also that 'PublicTransportTimeTable' can only be used for a relatively recent period of time."'
		}
	}
}
end