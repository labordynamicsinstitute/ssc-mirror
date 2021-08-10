******************************************
**    Sylvain Weber & Martin Péclat     **
**        University of Neuchâtel       **
**    Institute of Economic Research    **
**    This version: October 31, 2016    **
******************************************

*! version 1.0 Sylvain Weber & Martin Péclat 31oct2016
program georoutei, rclass
version 11.0

*** Syntax ***
#d ;
syntax, 
	hereid(string) herecode(string) 
	[
		STARTADdress(string) startxy(string) 
		ENDADdress(string) endxy(string) 
		km
		herepaid
	]
;
#d cr


*** Checks ***
*insheetjson.ado and libjson.mlib must be installed
cap: which insheetjson.ado
if _rc==111 {
	di as error "insheetjson required; type {stata ssc install insheetjson}"
	exit 111
}
cap: which libjson.mlib
if _rc==111 {
	di as error "libjson required; type {stata ssc install libjson}"
	exit 111
}

*One of start_add or start_coord and one of end_add or end_coord must be specified (one of each and only one)
foreach p in start end {
	if "``p'address'"=="" & "``p'xy'"=="" {
		di as error "`p'address() or `p'xy() is required."
		error 198
	}
	if "``p'address'"!="" & "``p'xy'"!="" {
		di as error "`p'address() and `p'xy() may not be combined."
		error 184
	}
}

*Coordinates of starting and ending points must be specified as two numbers separated by a comma
foreach p in start end {
	if "``p'xy'"!="" {
		if strpos("``p'xy'",",")==0 | strpos("``p'xy'",",")!=strrpos("``p'xy'",",") { // there is no comma or several
			di as error "option `p'xy() incorrectly specified"
			error 198
		}
		local commapos = strpos("``p'xy'",",")-1
		local `p'_x = substr("``p'xy'",1,`commapos')
		cap: confirm number ``p'_x'
		if _rc {
			di as error "option `p'xy() incorrectly specified"
			error 198
		}
		local commapos = strpos("``p'xy'",",")+1
		local `p'_y = substr("``p'xy'",`commapos',.)
		cap: confirm number ``p'_y'
		if _rc {
			di as error "option `p'xy() incorrectly specified"
			error 198
		}
		if !inrange(``p'_x',-90,90) {
			di as error "Latitudes must be between -90 and 90"
			error 198
		}
		if !inrange(``p'_y',-180,180) {
			di as error "Longitudes must be between -180 and 180"
			error 198
		}
	}
}


*** Retrieve x (latitude) - y (longitude) coordinates if addresses are provided ***
foreach p in start end {
	if "``p'address'"!="" {
		tempvar temp_x temp_y temp_matchlevel
		qui: gen str240 `temp_x' = ""
		qui: gen str240 `temp_y' = ""
		local here_url = "http://geocoder.cit.api.here.com/6.2/geocode.json?searchtext="
		if "`herepaid'"=="herepaid" {
			local here_url = "http://geocoder.api.here.com/6.2/geocode.json?searchtext="
		}
		local here_key = "&app_id=" + "`hereid'" + "&app_code=" + "`herecode'"

		local coords = "``p'address'"
		local coords = subinstr("`coords'", ".", "", .)
		local here_request = "`here_url'" + "`coords'" + "`here_key'"
		local here_request = subinstr("`here_request'", " ", "%20", .)

		qui: insheetjson `temp_x' `temp_y' using "`here_request'", columns("Response:View:1:Result:1:Location:DisplayPosition:Latitude" "Response:View:1:Result:1:Location:DisplayPosition:Longitude") flatten replace

		local temp_xy = `temp_x'[1] + "," + `temp_y'[1]
		local `p'xy = "`temp_xy'"
	}
}


*** Calculate travel distance and time ***
local here_url = "http://route.api.here.com/routing/7.2/calculateroute.json?app_id=" + "`hereid'" + "&app_code=" + "`herecode'"
if "`km'"=="km" local options = "&outFormat='json'&narrativeType=none&unit=k"
if "`km'"=="" local options = "&outFormat='json'&narrativeType=none"

tempvar temp_time temp_distance temp_error
qui: gen str240 `temp_distance' = ""
qui: gen str240 `temp_time' = ""
local s = "`startxy'"
local e = "`endxy'"
local here_request = "`here_url'" + "&waypoint0=geo!" + "`s'" + "&waypoint1=geo!" + "`e'" +"&mode=fastest;car;&representation=overview"

qui: insheetjson `temp_distance' `temp_time' using "`here_request'", columns("response:route:1:summary:distance" "response:route:1:summary:travelTime") flatten replace

if "`km'"=="" {
	local distance: di %8.2f real(`temp_distance'[1])/1609.3
}
if "`km'"=="km" {
	local distance: di %8.2f real(`temp_distance'[1])/1000
}
local time: di %8.2f (1/60)*real(`temp_time'[1])


*** Display results ***
local dup = length("From: `=cond("`startaddress'"!="","`startaddress' (`startxy')","(`startxy')")'")
local dup = max(`dup',length("To:   `=cond("`endaddress'"!="","`endaddress' (`endxy')","(`endxy')")'"))
di as input _n(1) _dup(`dup') "-"
di as input "From: `=cond("`startaddress'"!="","`startaddress' (`startxy')","(`startxy')")'"
di as input "To:   `=cond("`endaddress'"!="","`endaddress' (`endxy')","(`endxy')")'"
di as input _dup(`dup') "-"

di as res "Travel distance:" _col(20) "`distance' `=cond("`km'"=="km","kilometers","miles")'"
di as res "Travel time:" _col(20) "`time' minutes"

return scalar time = `time'
return scalar dist = `distance'
return local end "(`endxy')"
return local start "(`startxy')"
end
