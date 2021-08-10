 ******************************************
**    Sylvain Weber & Martin Péclat     **
**        University of Neuchâtel       **
**    Institute of Economic Research    **
**    This version: October 31, 2016    **
******************************************

*! version 1.0 Sylvain Weber & Martin Péclat 31oct2016
program georoute
version 11.0

*** Syntax ***
#d ;
syntax [if] [in], 
	hereid(string) herecode(string) 
	[
		STARTADdress(string) startxy(string) 
		ENDADdress(string) endxy(string) 
		km
		DIstance(string) TIme(string) COordinates(string) 
		timer 
		herepaid
		replace
	]
;
#d cr


*** Mark sample to be used ***
marksample touse
cap: count if `touse'
local N = r(N)


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

*One of start_address or start_coord and one of end_address or end_coord must be specified (one of each and only one)
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

*Coordinates of starting and ending points must be specified in two variables
foreach p in start end {
	if "``p'xy'"!="" {
		tokenize ``p'xy'
		if `"`2'"'=="" | `"`3'"'!="" {
			di as error "option `p'xy() incorrectly specified"
			error 198
		}
		confirm numeric variable `1'
		confirm numeric variable `2'
		cap: assert inrange(`1',-90,90) | mi(`1') if `touse'
		if _rc {
			di as error "`1' (latitude) must be between -90 and 90"
			error 198
		}
		cap: assert inrange(`2',-180,180) | mi(`2') if `touse'
		if _rc {
			di as error "`2' (longitude) must be between -180 and 180"
			error 198
		}
		tempvar `p'_xy
		qui: gen ``p'_xy' = string(`1') + "," + string(`2')
	}
}

*If specified, distance, time and coordinates must be new variables (unless replace is also specified)
if "`distance'"=="" local distance = "travel_distance"
if "`distance'"!="" {
	tokenize `distance'
	if `"`2'"'!="" {
		di as error "option distance() incorrectly specified"
		error 198
	}
}

if "`time'"=="" local time = "travel_time"
if "`time'"!="" {
	tokenize `time'
	if `"`2'"'!="" {
		di as error "option time() incorrectly specified"
		error 198
	}
}

if `"`replace'"'=="replace" {
	cap: drop `distance'
	cap: drop `time'
}
confirm new var `distance'
confirm new var `time'
cap: gen `distance' = .
cap: gen `time' = .

if "`coordinates'"!="" {
	tokenize `coordinates'
	if `"`2'"'=="" | `"`3'"'!="" {
		di as error "option coordinates() incorrectly specified"
		error 198
	}
	local start `1'
	local end `2'
	if `"`replace'"'=="replace" {
		if "`startxy'"=="" {
			cap: drop `start'_x
			cap: drop `start'_y
			cap: drop `start'_match
			confirm new var `start'_x `start'_y `start'_match
		}
		if "`endxy'"=="" {
			cap: drop `end'_x
			cap: drop `end'_y
			cap: drop `end'_match
			confirm new var `end'_x `end'_y `end'_match
		}
	}
}


*** Retrieve x (latitude) - y (longitude) coordinates if addresses are provided ***
foreach p in start end {
	if "``p'address'"!="" {
		tempvar `p'_xy `p'_match
		cap: gen str240 ``p'_xy' = ""
		cap: gen str240 ``p'_match' = ""
		tempvar temp_x temp_y temp_matchlevel
		qui: gen str240 `temp_x' = ""
		qui: gen str240 `temp_y' = ""
		qui: gen str240 `temp_matchlevel' = ""
		*query url with request for matchcode (accuracy)
		local here_url = "http://geocoder.cit.api.here.com/6.2/geocode.json?responseattributes=matchCode&searchtext=" // "responseattributes=matchCode" is added in the URL so that we get the accuracy level in the response 
		if "`herepaid'"=="herepaid" {
			local here_url = "http://geocoder.api.here.com/6.2/geocode.json?responseattributes=matchCode&searchtext="
		}
		local here_key = "&app_id=" + "`hereid'" + "&app_code=" + "`herecode'"

		local t 0
		forv i = 1/`=_N'{
			if `touse'[`i'] & !mi(``p'_address'[`i']) {
				*Add an optional timer
				if "`timer'"=="timer" {
					local ++t
					if `t'==1 {
						local dup = length("Geocoding addresses (`p')")
						di _n(1) _dup(`dup') as txt "-"
						di as txt "Geocoding addresses (`p')"
						di _dup(`dup') as txt "-"
					}
					if int(`t'/(`N'/10))>int((`t'-1)/(`N'/10)) di _continue as res " `=int(`t'/(`N'/10))*10'% "
					if int(`t'/(`N'/100))>int((`t'-1)/(`N'/100)) & int(`t'/(`N'/10))==int((`t'-1)/(`N'/10)) di _continue as res "."
				}
				local coords = ``p'_address'[`i']
				local coords = subinstr("`coords'", ".", "", .)
				local here_request = "`here_url'" + "`coords'" + "`here_key'"
				local here_request = subinstr("`here_request'", " ", "%20", .)

				qui: insheetjson `temp_x' `temp_y' `temp_matchlevel' using "`here_request'", columns("Response:View:1:Result:1:Location:DisplayPosition:Latitude" "Response:View:1:Result:1:Location:DisplayPosition:Longitude" "Response:View:1:Result:1:MatchCode") flatten replace

				local temp_xy = `temp_x'[1] + "," + `temp_y'[1]
				qui: replace ``p'_xy' = "`temp_xy'" in `i'
				qui: replace ``p'_match' = `temp_matchlevel'[1] in `i'
			}
		}
	}
}

*** Calculate travel distance and time ***
local here_url = "http://route.api.here.com/routing/7.2/calculateroute.json?app_id=" + "`hereid'" + "&app_code=" + "`herecode'"
if "`km'"=="km" local options = "&outFormat='json'&narrativeType=none&unit=k"
if "`km'"=="" local options = "&outFormat='json'&narrativeType=none"

local t 0
forv i = 1/`=_N'{
	if `touse'[`i'] & `start_xy'[`i']!="," & `end_xy'[`i']!="," {
		*Add an optional timer
		if "`timer'"=="timer" {
			local ++t
			if `t'==1 {
				di _n(1) _dup(16) as txt "-"
				di as txt "Geocoding routes"
				di _dup(16) as txt "-"
			}
			if int(`t'/(`N'/10))>int((`t'-1)/(`N'/10)) di _continue as res " `=int(`t'/(`N'/10))*10'% "
			if int(`t'/(`N'/100))>int((`t'-1)/(`N'/100)) & int(`t'/(`N'/10))==int((`t'-1)/(`N'/10)) di _continue as res "."
		}
		tempvar temp_time temp_distance temp_error
		qui: gen str240 `temp_distance' = ""
		qui: gen str240 `temp_time' = ""
		local s = `start_xy'[`i']
		local e = `end_xy'[`i']
		local here_request = "`here_url'" + "&waypoint0=geo!" + "`s'" + "&waypoint1=geo!" + "`e'" +"&mode=fastest;car;&representation=overview"

		qui: insheetjson `temp_distance' `temp_time' using "`here_request'", columns("response:route:1:summary:distance" "response:route:1:summary:travelTime") flatten replace

		if "`km'"=="" {
			qui: replace `distance' = real(`temp_distance'[1])/1609.3 in `i'
		}
		if "`km'"=="km" {
			qui: replace `distance' = real(`temp_distance'[1])/1000 in `i'
		}
		qui: replace `time' = (1/60)*real(`temp_time'[1]) in `i'
	}
}

*** Save and label the variables ***
la var `distance' "Travel distance (`=cond("`km'"=="km","km","mi")')"
la var `time' "Travel time (minutes)"
if "`coordinates'"!="" {
	foreach p in start end {
		if "``p'address'"!="" {
			tempvar commapos
			qui: gen `commapos' = strpos(``p'_xy',",")-1
			qui: gen ``p''_x = substr(``p'_xy',1,`commapos')
			qui: destring ``p''_x, replace
			la var ``p''_x "x-coordinate of `=cond("`p'"=="start","starting","ending")' address"
			qui: replace `commapos' = strpos(``p'_xy',",")+1
			qui: gen ``p''_y = substr(``p'_xy',`commapos',.)
			qui: destring ``p''_y, replace
			la var ``p''_y "y-coordinate of `=cond("`p'"=="start","starting","ending")' address"
			qui: gen ``p''_match = ``p'_match'
			la var ``p''_match "Match code for `=cond("`p'"=="start","starting","ending")' address"
			qui: replace ``p''_match = "1" if ``p''_match=="exact"
			qui: replace ``p''_match = "2" if ``p''_match=="ambiguous"
			qui: replace ``p''_match = "3" if ``p''_match=="upHierarchy"
			qui: replace ``p''_match = "4" if ``p''_match=="ambiguousUpHierarchy"
			qui: destring ``p''_match, replace
			cap: la drop matchcode
			la def matchcode 1 "exact" 2 "ambiguous" 3 "upHierarchy" 4 "ambiguousUpHierarchy"
			la val ``p''_match matchcode
		}
	}
}
end
