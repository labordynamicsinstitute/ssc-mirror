*! 3.0 Version of Google Geocode API
*! 2.3 build version of geocode3 
program geocode3
	version 12.0
	syntax, [address(string) zip state fulladdress quality reverse coord(string) number street ad1 ad2 ad3 sub]
	
	quietly {
		*check for insheetjson and libsjson
			cap which insheetjson
			if _rc == 111 noisily dis as text "Insheetjson.ado not found, please ssc install insheetjson"
			cap which libjson.mlib
			if _rc == 111 noisily dis as text "Libjson.mlib not found, please ssc install libjson"
			if _rc == 111 assert 1==2
			
			
			
			
	if "`address'" != "" {	
		*generate needed stuff
			tempfile txtfile
			cap drop geoid
			cap gen str16 g_lat = ""
			cap gen str16 g_lon = ""
			cap gen str24 g_status = ""
			cap gen geoid = _n
		*variables need to be string
			cap format g_lat g_lon %12.9f
			cap tostring g_lat g_lon g_zip, replace force
			
			cap replace geoid = 0 if g_status == "OK" & g_lat != "" & g_lon != ""
			
			sort geoid
			
		*make sure that there are no spaces or special characters in the addresses
			
			cap assert strpos(`address'," ") == 0
			if _rc == 9 {
			noi dis as text "Addresses may not contain blanks, replacing all blanks with plus signs."
			replace `address' = subinstr(`address', " ", "+",.)
			}
			
			
			if "`quality'" == "quality" {
			cap gen str24 g_quality = ""
			cap gen str24 g_partial = ""
			noisily dis as text "Quality option found, creating g_quality and g_partial"
			}
			
			if "`zip'" == "zip" {
			cap gen str24 g_zip = ""
			noisily dis as text "Zip option found, creating g_zip"
			}
			
			if "`state'" == "state" {
			cap gen str24 g_state = ""
			noisily dis as text "State option found, creating g_state"
			}

			
		if "`number'" == "number" {
			cap gen str240 g_number = ""
			noisily dis as text "Number option found, creating g_number"
			}
			
		if "`street'" == "street" {
			cap gen str240 g_street = ""
			noisily dis as text "street option found, creating g_street"
			}
			
		if "`ad1'" == "ad1" {
			cap gen str240 g_ad1 = ""
			noisily dis as text "ad1 option found, creating g_ad1"
			}
			
		if "`ad2'" == "ad2" {
			cap gen str240 g_ad2 = ""
			noisily dis as text "ad2 option found, creating g_ad2"
			}
			
		if "`ad3'" == "ad3" {
			cap gen str240 g_ad3 = ""
			noisily dis as text "ad3 option found, creating g_ad3"
			}

		if "`sub'" == "sub" {
			cap gen str240 g_sub = ""
			noisily dis as text "sub option found, creating g_sub"
			}			

		if "`fulladdress'" == "fulladdress" {
			cap gen str240 g_addr = ""
			noisily dis as text "Fulladdress option found, creating g_addr"
			}
						
		cap gen str64 control_type = ""
			
		local cnt = _N 
		
		*we start our loop and get the amount of observations and tell stata where the address is and in which line it shall write
		forval i = 1/`cnt' { 
			local addr = `address'[`i'] 
			local offset = `i'-1
			
			*sometimes if user "breaks" this is useful
				if g_lat[`i'] == "" & g_lon[`i'] == "" & g_status[`i'] == "OK" {
				noisily di as text "Google Geocoding `i' of `cnt' corrupted, resetting observation"
				replace g_status = "" in `i'
				}
			
			*if any other error code the obs is reset
				if g_lat[`i'] == "" & g_lon[`i'] == "" & g_status[`i'] != "" & g_status[`i'] != "OVER_QUERY_LIMIT" {
				noisily di as text "Google Geocoding `i' of `cnt' corrupted, resetting observation"
				replace g_status = "" in `i'
				}
			
			*we are done with these
				if g_status[`i']  == "OK" {
				noisily di as text "Skipping Google Geocoding `i' of `cnt': already done" 
				}
			
			*it was over query limit in a previous try and is now reset
				if g_status[`i']  == "OVER_QUERY_LIMIT" {
				noisily di as text "`i' of `cnt' over query limit, resetting g_status"
				replace g_status = "" in `i'
				}
			
				*the standard procedure
					if g_status[`i']  == "" {
			
					noisily di as text "Google Geocoding `i' of `cnt'" 
			
				*we get the address info from google into temp file
					capture copy "http://maps.googleapis.com/maps/api/geocode/json?address=`addr'&sensor=false" `txtfile'.json , replace
			
				*prevent google denying acces due to overflood
					sleep 500
			
				*use insheetjson to extract data from temp file
					capture: insheetjson g_lat g_lon using `txtfile'.json , table("results") col("geometry:location:lat" "geometry:location:lng") limit(1) offset(`offset') replace			
						
					capture: insheetjson g_status using `txtfile'.json , table("status") col("status") limit(1) offset(`offset') replace			
			
					if "`fulladdress'" == "fulladdress" capture: insheetjson g_addr using `txtfile'.json , table("results") col("formatted_address") limit(1) offset(`offset') replace			
					
					if "`quality'" == "quality" {
					capture: insheetjson g_quality using `txtfile'.json , table("results") col("geometry:location_type") limit(1) offset(`offset') replace			
					capture: insheetjson g_partial using `txtfile'.json , table("results") col("partial_match") limit(1) offset(`offset') replace			
					replace g_partial = "1" if g_partial == "true"
					replace g_partial = "0" if g_partial == ""
					}
					
					if "`zip'" == "zip" {
					*now some procedure to find the zip-code in the return table 
						local findzip = 1
						
						while (control_type[`i'] != "[postal_code]" & `findzip' <= 10) | `findzip' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findzip':types") limit(1) offset(`offset') replace
						local ++findzip
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[postal_code]" {
						local --findzip
						capture: insheetjson g_zip using `txtfile'.json , table("results") col("address_components:`findzip':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[postal_code]" {
						replace g_zip = "not_found" in `i'
						}
						*close if zip
						}
						
					if "`state'" == "state" {
					*now some procedure to find the state in the return table 
						local findstate = 1
						
						while (control_type[`i'] != "[country, political]" & `findstate' <= 10) | `findstate' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findstate':types") limit(1) offset(`offset') replace
						local ++findstate
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[country, political]" {
						local --findstate
						capture: insheetjson g_state using `txtfile'.json , table("results") col("address_components:`findstate':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[country, political]" {
						replace g_state = "not_found" in `i'
						}
						*close if state
						}
					
						
					if "`street'" == "street" {
					*now some procedure to find the street in the return table 
						local findstreet = 1
						
						while (control_type[`i'] != "[route]" & `findstreet' <= 10) | `findstreet' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findstreet':types") limit(1) offset(`offset') replace
						local ++findstreet
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[route]" {
						local --findstreet
						capture: insheetjson g_street using `txtfile'.json , table("results") col("address_components:`findstreet':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[route]" {
						replace g_street = "not_found" in `i'
						}
						*close if street
						}
				
					if "`number'" == "number" {
					*now some procedure to find the number in the return table 
						local findnumber = 1
						
						while (control_type[`i'] != "[street_number]" & `findnumber' <= 10) | `findnumber' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findnumber':types") limit(1) offset(`offset') replace
						local ++findnumber
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[street_number]" {
						local --findnumber
						capture: insheetjson g_number using `txtfile'.json , table("results") col("address_components:`findnumber':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[street_number]" {
						replace g_number = "not_found" in `i'
						}
						*close if number
						}
						
					if "`ad1'" == "ad1" {
					*now some procedure to find the ad1 in the return table 
						local findad1 = 1
						
						while (control_type[`i'] != "[administrative_area_level_1, political]" & `findad1' <= 10) | `findad1' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findad1':types") limit(1) offset(`offset') replace
						local ++findad1
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[administrative_area_level_1, political]" {
						local --findad1
						capture: insheetjson g_ad1 using `txtfile'.json , table("results") col("address_components:`findad1':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[administrative_area_level_1, political]" {
						replace g_ad1 = "not_found" in `i'
						}
						*close if ad1
						}
				
					if "`ad2'" == "ad2" {
					*now some procedure to find the ad2 in the return table 
						local findad2 = 1
						
						while (control_type[`i'] != "[administrative_area_level_2, political]" & `findad2' <= 10) | `findad2' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findad2':types") limit(1) offset(`offset') replace
						local ++findad2
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[administrative_area_level_2, political]" {
						local --findad2
						capture: insheetjson g_ad2 using `txtfile'.json , table("results") col("address_components:`findad2':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[administrative_area_level_2, political]" {
						replace g_ad2 = "not_found" in `i'
						}
						*close if ad2
						}
						
					if "`ad3'" == "ad3" {
					*now some procedure to find the ad3 in the return table 
						local findad3 = 1
						
						while (control_type[`i'] != "[administrative_area_level_3, political]" & `findad3' <= 10) | `findad3' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findad3':types") limit(1) offset(`offset') replace
						local ++findad3
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[administrative_area_level_3, political]" {
						local --findad3
						capture: insheetjson g_ad3 using `txtfile'.json , table("results") col("address_components:`findad3':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[administrative_area_level_3, political]" {
						replace g_ad3 = "not_found" in `i'
						}
						*close if ad3
						}
						
					if "`sub'" == "sub" {
					*now some procedure to find the sub in the return table 
						local findsub = 1
						
						while (control_type[`i'] != "[sublocality, political]" & `findsub' <= 10) | `findsub' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findsub':types") limit(1) offset(`offset') replace
						local ++findsub
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[sublocality, political]" {
						local --findsub
						capture: insheetjson g_sub using `txtfile'.json , table("results") col("address_components:`findsub':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[sublocality, political]" {
						replace g_sub = "not_found" in `i'
						}
						*close if sub
						}						
						
					
				*just an insta-debug notifier
					cap assert g_status == "OK" in `i'
					if _rc == 9 noisily di as text "Return code was not OK"		
						
				*reading the file returned over query limit
					if g_status[`i']  == "OVER_QUERY_LIMIT" | g_status[`i']  == "REQUEST_DENIED" { 
			
				*it tells the user to continue tomorrow or change the IP-address
					noisily di as text "Google Geocoding `i' of `cnt' failed due to daily query limit"			
					noisily di as text "aborting Geocoding, continue tomorrow or change IP"
					assert g_status[`i']  != "OVER_QUERY_LIMIT"
					assert g_status[`i']  != "REQUEST_DENIED"
			
			
					*close if g_status == "OVER_QUERY_LIMIT"
					}
			
					*close if g_status == ""
					}
						
				*close forval
				}
		
		*in the end we report if all observations went OK
			cap assert g_status == "OK"
			
			if _rc == 0 {
			noisily di as text "All observations geocoded successfully"
			foreach var in g_quality g_zip g_state g_number g_street g_ad1 g_ad2 g_ad3 g_sub g_addr {
			cap compress `var'
			}
			}
			if _rc == 9 {
			noisily di as text "Not all observations geocoded successfully"
			cap noisily assert g_status == "OK"
			}
			
			
			
			sort geoid
			cap drop control_type
			cap drop geoid
			cap destring g_lat , replace
			cap destring g_lon , replace
			cap destring g_zip , replace
			cap destring g_partial, replace
			cap format g_lat g_lon %12.9g
			
			*close normal geocoding
			}
			
			
			
			
			
			
			
			
		if "`coord'" != "" {		
			
			local fulladdress = "fulladdress"
			
		*generate needed stuff
			tempfile txtfile
			cap drop geoid
			cap gen str24 r_status = ""
			cap gen geoid = _n
			
			cap replace geoid = 0 if r_status == "OK" & r_country != ""
			
			sort geoid
			
		if "`quality'" == "quality" {
			cap gen str24 r_quality = ""
			noisily dis as text "Quality option found, creating r_quality"
			}
			
		if "`zip'" == "zip" {
			cap gen str24 r_zip = ""
			noisily dis as text "Zip option found, creating r_zip"
			}
			
		if "`state'" == "state" {
			cap gen str24 r_state = ""
			noisily dis as text "State option found, creating r_state"
			}
			
		if "`number'" == "number" {
			cap gen str240 r_number = ""
			noisily dis as text "Number option found, creating r_number"
			}
			
		if "`street'" == "street" {
			cap gen str240 r_street = ""
			noisily dis as text "street option found, creating r_street"
			}
			
		if "`ad1'" == "ad1" {
			cap gen str240 r_ad1 = ""
			noisily dis as text "ad1 option found, creating r_ad1"
			}
			
		if "`ad2'" == "ad2" {
			cap gen str240 r_ad2 = ""
			noisily dis as text "ad2 option found, creating r_ad2"
			}
			
		if "`ad3'" == "ad3" {
			cap gen str240 r_ad3 = ""
			noisily dis as text "ad3 option found, creating r_ad3"
			}

		if "`sub'" == "sub" {
			cap gen str240 r_sub = ""
			noisily dis as text "sub option found, creating r_sub"
			}			
			
		if "`fulladdress'" == "fulladdress" {
			cap gen str240 r_addr = ""
			noisily dis as text "Fulladdress option found, creating r_addr"
			}
			
		cap gen str64 control_type = ""

		local cnt = _N 
		
		
		
		
		
		*we start our loop and get the amount of observations and tell stata where the address is and in which line it shall write
		forval i = 1/`cnt' { 
			local latlon = `coord'[`i'] 
			local offset = `i'-1
			
			*sometimes if user "breaks" this is useful
				if r_addr[`i'] == "" & r_status[`i'] == "OK" {
				noisily di as text "Google reverse Geocoding `i' of `cnt' corrupted, resetting observation"
				replace r_status = "" in `i'
				}
			
			*if any other error code the obs is reset
				if r_addr[`i'] == "" & r_status[`i'] != "" & r_status[`i'] != "OVER_QUERY_LIMIT" {
				noisily di as text "Google reverse Geocoding `i' of `cnt' corrupted, resetting observation"
				replace r_status = "" in `i'
				}
			
			*we are done with these
				if r_status[`i']  == "OK" & r_addr[`i'] != "" {
				noisily di as text "Skipping Google reverse Geocoding `i' of `cnt': already done" 
				}
			
			*it was over query limit in a previous try and is now reset
				if r_status[`i']  == "OVER_QUERY_LIMIT" {
				noisily di as text "`i' of `cnt' over query limit, resetting r_status"
				replace r_status = "" in `i'
				}
				
				*the standard procedure
					if r_status[`i']  == "" {
			
					noisily di as text "Google reverse Geocoding `i' of `cnt'" 
			
				*we get the address info from google into temp file
					capture copy "http://maps.googleapis.com/maps/api/geocode/json?latlng=`latlon'&sensor=false" `txtfile'.json , replace
			
				*prevent google denying acces due to overflood
					sleep 500
			
				*use insheetjson to extract data from temp file
					
					capture: insheetjson r_status using `txtfile'.json , table("status") col("status") limit(1) offset(`offset') replace			
			
					capture: insheetjson r_addr using `txtfile'.json , table("results") col("formatted_address") limit(1) offset(`offset') replace			
					
					if "`quality'" == "quality" capture: insheetjson r_quality using `txtfile'.json , table("results") col("geometry:location_type") limit(1) offset(`offset') replace			

					if "`zip'" == "zip" {
					*now some procedure to find the zip-code in the return table 
						local findzip = 1
						
						while (control_type[`i'] != "[postal_code]" & `findzip' <= 10) | `findzip' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findzip':types") limit(1) offset(`offset') replace
						local ++findzip
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[postal_code]" {
						local --findzip
						capture: insheetjson r_zip using `txtfile'.json , table("results") col("address_components:`findzip':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[postal_code]" {
						replace r_zip = "not_found" in `i'
						}
						*close if zip
						}
						
					if "`state'" == "state" {
					*now some procedure to find the state in the return table 
						local findstate = 1
						
						while (control_type[`i'] != "[country, political]" & `findstate' <= 10) | `findstate' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findstate':types") limit(1) offset(`offset') replace
						local ++findstate
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[country, political]" {
						local --findstate
						capture: insheetjson r_state using `txtfile'.json , table("results") col("address_components:`findstate':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[country, political]" {
						replace r_state = "not_found" in `i'
						}
						*close if state
						}
						
					if "`street'" == "street" {
					*now some procedure to find the street in the return table 
						local findstreet = 1
						
						while (control_type[`i'] != "[route]" & `findstreet' <= 10) | `findstreet' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findstreet':types") limit(1) offset(`offset') replace
						local ++findstreet
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[route]" {
						local --findstreet
						capture: insheetjson r_street using `txtfile'.json , table("results") col("address_components:`findstreet':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[route]" {
						replace r_street = "not_found" in `i'
						}
						*close if street
						}
				
					if "`number'" == "number" {
					*now some procedure to find the number in the return table 
						local findnumber = 1
						
						while (control_type[`i'] != "[street_number]" & `findnumber' <= 10) | `findnumber' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findnumber':types") limit(1) offset(`offset') replace
						local ++findnumber
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[street_number]" {
						local --findnumber
						capture: insheetjson r_number using `txtfile'.json , table("results") col("address_components:`findnumber':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[street_number]" {
						replace r_number = "not_found" in `i'
						}
						*close if number
						}
						
					if "`ad1'" == "ad1" {
					*now some procedure to find the ad1 in the return table 
						local findad1 = 1
						
						while (control_type[`i'] != "[administrative_area_level_1, political]" & `findad1' <= 10) | `findad1' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findad1':types") limit(1) offset(`offset') replace
						local ++findad1
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[administrative_area_level_1, political]" {
						local --findad1
						capture: insheetjson r_ad1 using `txtfile'.json , table("results") col("address_components:`findad1':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[administrative_area_level_1, political]" {
						replace r_ad1 = "not_found" in `i'
						}
						*close if ad1
						}
				
					if "`ad2'" == "ad2" {
					*now some procedure to find the ad2 in the return table 
						local findad2 = 1
						
						while (control_type[`i'] != "[administrative_area_level_2, political]" & `findad2' <= 10) | `findad2' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findad2':types") limit(1) offset(`offset') replace
						local ++findad2
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[administrative_area_level_2, political]" {
						local --findad2
						capture: insheetjson r_ad2 using `txtfile'.json , table("results") col("address_components:`findad2':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[administrative_area_level_2, political]" {
						replace r_ad2 = "not_found" in `i'
						}
						*close if ad2
						}
						
					if "`ad3'" == "ad3" {
					*now some procedure to find the ad3 in the return table 
						local findad3 = 1
						
						while (control_type[`i'] != "[administrative_area_level_3, political]" & `findad3' <= 10) | `findad3' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findad3':types") limit(1) offset(`offset') replace
						local ++findad3
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[administrative_area_level_3, political]" {
						local --findad3
						capture: insheetjson r_ad3 using `txtfile'.json , table("results") col("address_components:`findad3':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[administrative_area_level_3, political]" {
						replace r_ad3 = "not_found" in `i'
						}
						*close if ad3
						}
						
					if "`sub'" == "sub" {
					*now some procedure to find the sub in the return table 
						local findsub = 1
						
						while (control_type[`i'] != "[sublocality, political]" & `findsub' <= 10) | `findsub' == 1 {			
			
						capture: insheetjson control_type using `txtfile'.json , table("results") col("address_components:`findsub':types") limit(1) offset(`offset') replace
						local ++findsub
						*close while findzip
						}
					*if we found the postal_code
						if control_type[`i'] == "[sublocality, political]" {
						local --findsub
						capture: insheetjson r_sub using `txtfile'.json , table("results") col("address_components:`findsub':long_name") limit(1) offset(`offset') replace				
						}
					*if we found no postal_code
						if control_type[`i'] != "[sublocality, political]" {
						replace r_sub = "not_found" in `i'
						}
						*close if sub
						}						
						
			*just an insta-debug notifier
				cap assert r_status == "OK" in `i'
				if _rc == 9 noisily di as text "Return code was not OK"		
						
						
			*reading the file returned over query limit,
					if r_status[`i']  == "OVER_QUERY_LIMIT" | r_status[`i']  == "REQUEST_DENIED" { 
			
				*it tells the user to continue tomorrow or change the IP-address
					noisily di as text "Google reverse Geocoding `i' of `cnt' failed due to daily query limit"			
					noisily di as text "aborting reverse Geocoding, continue tomorrow or change IP"
					assert r_status[`i']  != "OVER_QUERY_LIMIT"
					assert r_status[`i']  != "REQUEST_DENIED"
			
			
					*close if r_status == "OVER_QUERY_LIMIT"
					}
						
						
						
					*close if r_status == ""
					}
						
					*close forval
					}
		
		*in the end we report if all observations went OK
			cap assert r_status == "OK"
			
			if _rc == 0 {
			noisily di as text "All observations reverse geocoded successfully"
			foreach var in r_quality r_zip r_state r_number r_street r_ad1 r_ad2 r_ad3 r_sub r_addr {
			cap compress `var'
			}
			}
			if _rc == 9 {
			noisily di as text "Not all observations reverse geocoded successfully"
			cap noisily assert r_status == "OK"
			}
			
			
		
			sort geoid
			cap drop control_type
			cap drop geoid
			
			*close reverse geocoding
			}
						
	/*changelog:
	2.2 - added partial as quality indicator
	2.1 - increased compatibility, removes spaces from address input
	2.0 - added reverse geocoding
	1.5 - added quality indicators
	1.0 - added basic functionalities
    */
			

			*close quietly
			}
			
			
			
			end
